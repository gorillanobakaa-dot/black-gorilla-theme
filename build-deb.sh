#!/bin/bash
# Version: 26.10.20-18-42 · updated 26-10-20-18-42
# build-deb.sh — package Black Gorilla Theme as a click-to-install .deb
#
# WHY THIS EXISTS
#   "Download it, click it, it's installed" is the requirement. That rules out
#   a tarball with instructions, and it rules out the obvious packaging choice
#   too: a theme in /usr/share/themes.
#
#   MEASURED, not assumed (strace, GTK 4.18.6 + libadwaita 1.7.6, 2026-08-13):
#     plain GTK4 app  opens ~/.config/gtk-4.0/gtk.css AND
#                           /usr/share/themes/<Name>/gtk-4.18/gtk.css
#     libadwaita app  opens ~/.config/gtk-4.0/gtk.css and NOTHING ELSE.
#                           It never stats /usr/share/themes at all.
#   Files, Settings, Epiphany and every modern GNOME app are libadwaita. So a
#   packaged theme under /usr/share/themes would install cleanly, appear in
#   tweak tools, and change nothing the user actually looks at. This package
#   therefore installs the per-user override, which is the only mechanism
#   libadwaita honours, and drives it from maintainer scripts + a login hook.
#
#   Consequence, stated plainly because it is unusual: this package writes into
#   users' home directories. Debian policy discourages that for good reasons.
#   It is done deliberately here because the file IS the product, and it is
#   bounded — only homes carrying our own stamp file are ever touched, and
#   removing the package strips exactly the block it added.
#
# USAGE
#   ./build-deb.sh            build ./dist/black-gorilla-theme_<ver>_all.deb
#   ./build-deb.sh --install  build, then install it with apt
set -euo pipefail
# 0775/0664 otherwise leaks in from the build user's umask.
umask 022

VERSION="26.10.20-18-42"
PKG="black-gorilla-theme"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/build/${PKG}_${VERSION}_all"
DIST="$HERE/dist"

rm -rf "$ROOT"
mkdir -p "$ROOT"/{DEBIAN,usr/bin,usr/share/$PKG,usr/share/doc/$PKG,usr/share/man/man1,etc/xdg/autostart}
mkdir -p "$DIST"

# ── payload ────────────────────────────────────────────────────────────────
install -m 0755 "$HERE/install.sh"             "$ROOT/usr/bin/$PKG"
# Compatibility symlink for legacy commands
ln -sf "$PKG"                                  "$ROOT/usr/bin/gtk-high-contrast-theme"
install -m 0755 "$HERE/get-microsoft-fonts.sh" "$ROOT/usr/share/$PKG/get-microsoft-fonts.sh"
install -m 0644 "$HERE/README.md"              "$ROOT/usr/share/doc/$PKG/README.md"

# The login hook. Runs for every user, exits instantly once that user has
# decided (applied or reverted), so it never fights a deliberate revert.
cat > "$ROOT/etc/xdg/autostart/$PKG.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Black Gorilla Theme
Comment=Apply Black Gorilla GTK theme for users who have not chosen otherwise
Exec=/usr/bin/black-gorilla-theme --apply-once
NoDisplay=true
X-GNOME-Autostart-Phase=Initialization
EOF
chmod 0644 "$ROOT/etc/xdg/autostart/$PKG.desktop"

cat > "$ROOT/usr/share/doc/$PKG/copyright" <<'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: black-gorilla-theme

Files: *
Copyright: 2026 Gorilla Unleashed
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

Comment:
 No font files are distributed with this package. Microsoft's Segoe UI Variable
 is licensed for use, not redistribution, so the theme names it in a CSS
 fallback list and falls back to free faces when it is absent. A helper to
 fetch it from Microsoft's own free Windows evaluation image is shipped in
 /usr/share/black-gorilla-theme/get-microsoft-fonts.sh; it downloads on the
 user's machine and ships nothing.
EOF

cat > "$ROOT/usr/share/doc/$PKG/changelog.Debian" <<EOF
$PKG ($VERSION) unstable; urgency=low

  * Renamed to Black Gorilla Theme.
  * Versioned with YY-MM-DD-HH-MM timestamp scheme.
  * Added 1px crisp cyan border and background to right-click context menus
    and popovers (popover > contents in GTK4, menu / popover in GTK3).
  * Pure black background with cyan text: 16.75:1 contrast.
  * Selection drawn as a solid pink block with black text (13.65:1).
  * Transitions and animations neutralised to 0.01ms.

 -- Gorilla Unleashed Team <gorilla@unleashed.local>  Sat, 15 Aug 2026 08:17:00 +0100
EOF
gzip -9n "$ROOT/usr/share/doc/$PKG/changelog.Debian"

cat > "$ROOT/usr/share/man/man1/$PKG.1" <<'EOF'
.TH BLACK-GORILLA-THEME 1 "2026-10-20" "26.10.20-18-42" "User Commands"
.SH NAME
black\-gorilla\-theme \- pure black, high contrast theme for GTK3 and GTK4/libadwaita
.SH SYNOPSIS
.B black\-gorilla\-theme
[\fB\-\-fonts\fR | \fB\-\-revert\fR | \fB\-\-check\fR | \fB\-\-apply\-once\fR]
.SH DESCRIPTION
Writes a block of CSS into the calling user's
.I ~/.config/gtk\-4.0/gtk.css
and
.I ~/.config/gtk\-3.0/gtk.css
so that every GTK3 and GTK4/libadwaita application on the desktop is drawn with
a pure black background, bright cyan text, and crisp cyan borders on context menus.
.PP
This is the only mechanism that works. A libadwaita application reads no
stylesheet from
.I /usr/share/themes
whatsoever, so a conventionally packaged theme would change nothing in Files,
Settings, or any modern GNOME application.
.SH OPTIONS
.TP
.B (no argument)
Apply the theme. Colours only; the desktop font is left alone.
.TP
.B \-\-fonts
Also set the desktop font, saving the previous value for \fB\-\-revert\fR.
.TP
.B \-\-revert
Remove everything the tool did and restore the previous font settings.
.TP
.B \-\-check
Report what is applied and print the measured contrast ratios.
.TP
.B \-\-apply\-once
Apply only if this user has never applied or reverted before. Used by the
package at install time and at login, so a deliberate revert is never undone.
.SH FILES
.TP
.I ~/.config/gtk\-4.0/gtk.css
.TP
.I ~/.config/gtk\-3.0/gtk.css
Theme block, delimited by \fB/* BEGIN black-gorilla-theme */\fR markers. Any
other content in these files is preserved.
.TP
.I ~/.config/black\-gorilla\-theme.decided
Marks that this user has made a choice, so the login hook stays quiet.
.SH CONTRAST
Measured against WCAG (AA is 4.5:1, AAA is 7:1):
cyan #00FFFF on black 16.75:1;
pink #FFC0CB on black 13.65:1;
dimmed #00B8B8 on black 8.55:1.
Adwaita\-dark's secondary text, for comparison, is 5.17:1.
.SH NOTES
No font files are distributed. Segoe UI Variable is named in a CSS fallback
list and used only if already present; free faces are used otherwise.
EOF
gzip -9n "$ROOT/usr/share/man/man1/$PKG.1"
ln -sf "$PKG.1.gz" "$ROOT/usr/share/man/man1/gtk-high-contrast-theme.1.gz"

# ── maintainer scripts ─────────────────────────────────────────────────────
# Shared helper: which real human is installing this? sudo and pkexec both say
# so; graphical installers (gdebi, eddy) say neither, in which case a machine
# with exactly one normal user is unambiguous. If it stays ambiguous we do
# nothing and let the login hook handle it.
cat > "$ROOT/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e

invoking_user () {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != root ]; then
        echo "$SUDO_USER"; return
    fi
    if [ -n "${PKEXEC_UID:-}" ]; then
        getent passwd "$PKEXEC_UID" | cut -d: -f1; return
    fi
    n=$(getent passwd | awk -F: '$3>=1000 && $3<65534 {print $1}' | head -3 | wc -l)
    [ "$n" = 1 ] && getent passwd | awk -F: '$3>=1000 && $3<65534 {print $1}'
}

case "$1" in
  configure)
    u=$(invoking_user || true)
    if [ -n "$u" ]; then
        h=$(getent passwd "$u" | cut -d: -f6)
        if [ -n "$h" ] && [ -d "$h" ]; then
            # A first install is a fresh decision: clear any stale stamp so the
            # theme actually applies. An upgrade ($2 non-empty) must not.
            [ -z "${2:-}" ] && rm -f "$h/.config/black-gorilla-theme.decided" "$h/.config/high-contrast-theme.decided"
            runuser -u "$u" -- env HOME="$h" \
                black-gorilla-theme --apply-once >/dev/null 2>&1 || true
            echo "Black Gorilla Theme applied for $u. Log out and back in, or"
            echo "restart an application, to see it. Undo with:"
            echo "  black-gorilla-theme --revert"
        fi
    fi
    ;;
esac
exit 0
EOF

cat > "$ROOT/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
# On removal, strip our block from every home that carries our stamp — and only
# those. Done with the same awk the tool uses, so unrelated CSS in the same
# file survives. An upgrade must not touch anything.
case "$1" in
  remove|deconfigure)
    getent passwd | awk -F: '$3>=1000 && $3<65534 {print $6}' | sort -u | while read -r h; do
        [ -d "$h" ] || continue
        if [ -e "$h/.config/black-gorilla-theme.decided" ] || [ -e "$h/.config/high-contrast-theme.decided" ]; then
            for f in "$h/.config/gtk-4.0/gtk.css" "$h/.config/gtk-3.0/gtk.css"; do
                [ -f "$f" ] || continue
                awk '/\/\* BEGIN (black-gorilla-theme|high-contrast-theme) \*\//{skip=1}
                     !skip{print}
                     /\/\* END (black-gorilla-theme|high-contrast-theme) \*\//{skip=0}' "$f" > "$f.tmp" 2>/dev/null || continue
                if grep -q '[^[:space:]]' "$f.tmp" 2>/dev/null; then
                    chown --reference="$f" "$f.tmp" 2>/dev/null || true
                    mv "$f.tmp" "$f"
                else
                    rm -f "$f.tmp" "$f"
                fi
            done
            rm -f "$h/.config/black-gorilla-theme.decided" \
                  "$h/.config/black-gorilla-theme.state" \
                  "$h/.config/high-contrast-theme.decided" \
                  "$h/.config/high-contrast-theme.state"
        fi
    done
    ;;
esac
exit 0
EOF

chmod 0755 "$ROOT/DEBIAN/postinst" "$ROOT/DEBIAN/prerm"
echo "/etc/xdg/autostart/$PKG.desktop" > "$ROOT/DEBIAN/conffiles"

find "$ROOT" -type d -exec chmod 0755 {} +
find "$ROOT/usr/share" "$ROOT/etc" -type f -exec chmod 0644 {} +
chmod 0755 "$ROOT/usr/bin/$PKG" "$ROOT/usr/share/$PKG/get-microsoft-fonts.sh"
SIZE=$(du -ks "$ROOT" | cut -f1)
cat > "$ROOT/DEBIAN/control" <<EOF
Package: $PKG
Version: $VERSION
Section: gnome
Priority: optional
Architecture: all
Provides: gtk-high-contrast-theme
Replaces: gtk-high-contrast-theme
Conflicts: gtk-high-contrast-theme (<< 26.0)
Depends: bash (>= 4.0), gawk | mawk
Recommends: libglib2.0-bin, fontconfig
Maintainer: Gorilla Unleashed Team <gorilla@unleashed.local>
Installed-Size: $SIZE
Description: Black Gorilla Theme: pure black high-contrast theme for GTK3 and GTK4/libadwaita
 A desktop-wide theme for people reading a dim, old laptop panel: pure black
 background, bright cyan text at a measured 16.75:1 contrast, against the
 5.17:1 that Adwaita-dark gives secondary text. Right-click context menus and
 popovers have a crisp 1px cyan border so menus are clearly delineated.
 Selection is a solid pink block rather than a translucent overlay, which on
 a black background is close to invisible. Edges are drawn with outline rather
 than border, so focus changes cost no CPU reflow, and transitions are
 neutralised to 0.01ms.
 .
 Installing applies it immediately for the installing user, and at first login
 for anyone else. It is fully reversible with "black-gorilla-theme --revert",
 and removing the package strips it from every account it touched.
 .
 No fonts are distributed. Segoe UI Variable is named in a CSS fallback list
 and used only when already installed; free faces are used otherwise.
EOF

( cd "$ROOT" && find usr etc -type f -print0 | xargs -0 md5sum > DEBIAN/md5sums )

OUT="$DIST/${PKG}_${VERSION}_all.deb"
dpkg-deb --root-owner-group --build "$ROOT" "$OUT" >/dev/null
echo "built: $OUT  ($(du -h "$OUT" | cut -f1))"

if command -v lintian >/dev/null 2>&1; then
    echo "--- lintian ---"
    lintian --tag-display-limit 0 "$OUT" 2>&1 | head -30 || true
fi

[ "${1:-}" = "--install" ] && sudo apt-get install -y "$OUT"
exit 0
