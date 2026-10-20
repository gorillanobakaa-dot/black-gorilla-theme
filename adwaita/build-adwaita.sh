#!/bin/bash
# Version: 26.10.20-19-34 · updated 26-10-20-19-34
# build-adwaita.sh: rebuild GTK3's Adwaita from its own sources with the Black Gorilla palette.
#
# WHY
#   GTK3 compiles Adwaita into libgtk-3 as FIXED colour values (#eeeeec text, #353535 background, light-grey header
#   bars). A user gtk.css that redefines the @named colours never reaches them, so every GTK3 app (Terminal, anything
#   on libhandy) showed its own grey gap and was patched one selector at a time. Adwaita is generated from ONE
#   palette file (_colors.scss); compiling it with our palette changes every widget at once, including ones nobody
#   has looked at. Owner's request 2026-10-20: "fix the problem at the source".
#
# WHAT IT DOES
#   1. fetches the Adwaita theme sources of the GTK version pinned below and checks each against SOURCES.sha256
#      (refuses on any mismatch: a silent upstream change must not ship)
#   2. replaces _colors.scss with ours, applies two checked patches to _common.scss (below), adds _black-gorilla.scss
#   3. compiles with sassc exactly as upstream does (-a -M -t compact) into ../theme/Black-Gorilla/gtk-3.0/
#   The compiled CSS is committed, so installing the theme needs neither sassc nor a download (directive 8).
#
#   ./build-adwaita.sh            build into ../theme
#   ./build-adwaita.sh --check    rebuild into a temp folder and fail if the committed CSS differs (drift)
set -euo pipefail
GTK_TAG="3.24.49"   # must match the installed libgtk-3 (verified 2026-10-20: 957 of 957 stock rules verbatim)
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../theme/Black-Gorilla"
RAW="https://gitlab.gnome.org/GNOME/gtk/-/raw/$GTK_TAG/gtk/theme/Adwaita"
SOURCES="_colors-public.scss _common.scss _drawing.scss gtk-contained-dark.scss"

command -v sassc >/dev/null || { echo "REFUSED: sassc is not installed (sudo apt install sassc)"; exit 2; }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/src/assets"
cd "$WORK/src"

# 1. pinned sources, verified
for f in $SOURCES; do curl -sfL --retry 4 --retry-delay 2 -o "$f" "$RAW/$f" || { echo "REFUSED: could not fetch $f ($GTK_TAG)"; exit 2; }; done
( cd "$WORK/src" && sha256sum -c --quiet "$HERE/SOURCES.sha256" ) \
  || { echo "REFUSED: upstream sources differ from SOURCES.sha256 (GTK $GTK_TAG). Review the change before updating the sums."; exit 2; }

# 2. palette, patches, overrides
cp "$HERE/_colors.scss" _colors.scss
cp "$HERE/_black-gorilla.scss" _black-gorilla.scss
python3 - <<'PY'
import sys
p = "_common.scss"; s = open(p).read()
def swap(old, new, count):
    global s
    n = s.count(old)
    if n != count:
        sys.exit(f"REFUSED: expected {count} x {old!r} in _common.scss, found {n}: upstream changed, review the patch")
    s = s.replace(old, new)
# (a) suggested-action text: upstream hard-codes white, which on our pink is about 1.5:1. Each button type now
#     carries its own text colour: black on pink, white on red as upstream.
swap("@each $b_type, $b_color in (suggested-action, $suggested_bg_color),\n                             (destructive-action, $destructive_color) {",
     "@each $b_type, $b_color, $b_fg in (suggested-action, $suggested_bg_color, $selected_fg_color),\n                             (destructive-action, $destructive_color, white) {", 1)
swap("$b_color, white)", "$b_color, $b_fg)", 7)
# (b) tooltip text: upstream forces white; ours is the OSD text colour (cyan on black, like everything else).
swap("    background-color: transparent;\n    color: white;\n  }\n}", "    background-color: transparent;\n    color: $osd_text_color;\n  }\n}", 1)
open(p, "w").write(s)
PY
printf "@import 'black-gorilla';\n" >> gtk-contained-dark.scss

# 3. compile, exactly as upstream's parse-sass.sh
DEST="$WORK/out/gtk-3.0"; mkdir -p "$DEST/assets"
sassc -a -M -t compact gtk-contained-dark.scss "$DEST/gtk.css"
printf '@import url("gtk.css");\n' > "$DEST/gtk-dark.css"   # same theme either way: one copy, not two (170 KB)
for a in $(grep -oE 'url\("assets/[^"]+"\)' "$DEST/gtk.css" | sed 's/url("assets\///; s/")//' | sort -u); do
  curl -sfL --retry 4 --retry-delay 2 -o "$DEST/assets/$a" "$RAW/assets/$a" || { echo "REFUSED: could not fetch asset $a"; exit 2; }
done
( cd "$DEST/assets" && sha256sum -c --quiet "$HERE/ASSETS.sha256" ) \
  || { echo "REFUSED: upstream assets differ from ASSETS.sha256 (GTK $GTK_TAG)"; exit 2; }

if [ "${1:-}" = "--check" ]; then
  diff -rq "$WORK/out/gtk-3.0" "$OUT/gtk-3.0" >/dev/null \
    && { echo "OK: committed theme matches what the sources build"; exit 0; } \
    || { echo "DRIFT: committed theme differs from a fresh build; run ./build-adwaita.sh"; exit 1; }
fi
rm -rf "$OUT/gtk-3.0"; mkdir -p "$OUT"
cp -r "$WORK/out/gtk-3.0" "$OUT/gtk-3.0"
echo "built: $OUT/gtk-3.0  ($(grep -c '{' "$OUT/gtk-3.0/gtk.css") rules, $(ls "$OUT/gtk-3.0/assets" | wc -l) assets, $(du -sk "$OUT/gtk-3.0" | cut -f1) KB)"
