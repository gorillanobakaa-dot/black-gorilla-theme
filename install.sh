#!/bin/bash
# Version: 26.10.20-18-27 · updated 26-10-20-18-27
# install.sh — Black Gorilla Theme: a pure black, high-contrast GTK theme that
# fixes secondary text, context menu borders, and uses optical-size typography
# when the fonts are available.
#
# WHAT IT DOES, IN ONE SENTENCE
#   Writes two small CSS files into your own config directory. No root, no
#   package, no theme to select anywhere, nothing outside your home folder.
#
# WHY IT EXISTS — the measured version
#   Adwaita-dark draws secondary text (every row subtitle, caption and help
#   paragraph) as white at 55% alpha over a #303030 card:
#
#     row title        #ffffff   13.20:1   fine
#     row SUBTITLE     #a2a2a2    5.17:1   scrapes past WCAG AA (4.5)
#     insensitive text #989898    4.58:1   0.08 above the legal minimum
#
#   WCAG AA is a floor for good eyes, a good screen and full brightness. It is
#   not a comfort target; AAA is 7:1. This theme measures:
#
#     cyan  #00FFFF on black #000000   16.75:1
#     pink  #FFC0CB on black           13.65:1
#     dim   #00B8B8 on black            8.55:1
#
# SCOPE — READ THIS BEFORE RUNNING
#   This is DESKTOP-WIDE. Every GTK3 and GTK4/libadwaita application changes,
#   not just one app. It is fully reversible: ./install.sh --revert
#
# USAGE
#   ./install.sh              apply the theme (colours only)
#   ./install.sh --fonts      also set the desktop font (see FONTS below)
#   ./install.sh --revert     remove everything this script did
#   ./install.sh --check      show what is applied, and the measured ratios
#   ./install.sh --apply-once apply ONLY if this user has never decided before
#                             (used by the .deb: at install time and at login,
#                             so a user who reverted is never overridden)
#
# WHY THERE IS NO SELECTABLE THEME TO INSTALL
#   Measured on GTK 4.18 / libadwaita 1.7.6 with strace: a libadwaita
#   application opens exactly ONE stylesheet path outside its own resources —
#   ~/.config/gtk-4.0/gtk.css. It never reads /usr/share/themes at all, so a
#   packaged theme there would change nothing in Files, Settings, or any modern
#   GNOME app. The per-user file is not a shortcut; it is the only mechanism
#   libadwaita honours.
set -u

GTK4="$HOME/.config/gtk-4.0/gtk.css"
GTK3="$HOME/.config/gtk-3.0/gtk.css"
BEGIN="/* BEGIN black-gorilla-theme */"
END="/* END black-gorilla-theme */"
STATE="$HOME/.config/black-gorilla-theme.state"
# Records that this user has made a choice — applied OR reverted. Its presence
# stops the package re-applying at every login over a deliberate revert.
STAMP="$HOME/.config/black-gorilla-theme.decided"

BG="#000000"; FG="#00FFFF"; ACCENT="#FFC0CB"; DIM="#00B8B8"; DISABLED="#00A0A0"

# ── fonts ──────────────────────────────────────────────────────────────────
# Segoe UI Variable ships THREE optical sizes, each drawn for a size range:
#   Static Small    captions        Static Text  body/UI        Static Display  headings
# Using the right one per role is most of what makes UI text look crisp.
#
# The fonts are Microsoft-licensed and are NOT redistributable, so this theme
# cannot ship them. It does not need to: CSS font-family is a fallback LIST, so
# the theme uses Segoe when the machine has it and falls back to good free
# faces when it does not. Nothing to detect, nothing to break.
FONT_TEXT='"Segoe UI Variable Static Text", "Segoe UI", Inter, Cantarell, "Noto Sans", "DejaVu Sans", sans-serif'
FONT_DISPLAY='"Segoe UI Variable Static Display", "Segoe UI Semibold", Inter, Cantarell, "Noto Sans", "DejaVu Sans", sans-serif'
FONT_SMALL='"Segoe UI Variable Static Small", "Segoe UI", Inter, Cantarell, "Noto Sans", "DejaVu Sans", sans-serif'

have_font () { fc-list : family 2>/dev/null | tr ',' '\n' | grep -qxi "$1"; }

read -r -d '' GTK4_BLOCK <<CSS
$BEGIN
/* Named colours. Every GTK/libadwaita widget derives its colours from this
 * fixed vocabulary, so redefining the NAMES restyles widgets we never
 * addressed — including ones added by future versions. That is why this is
 * ~25 lines and has no gaps, where a selector-based theme always has both. */
@define-color window_bg_color $BG;
@define-color window_fg_color $FG;
@define-color view_bg_color $BG;
@define-color view_fg_color $FG;
@define-color headerbar_bg_color $BG;
@define-color headerbar_fg_color $FG;
@define-color headerbar_border_color $FG;
@define-color headerbar_shade_color transparent;
@define-color sidebar_bg_color $BG;
@define-color sidebar_fg_color $FG;
@define-color sidebar_border_color $FG;
@define-color secondary_sidebar_bg_color $BG;
@define-color secondary_sidebar_fg_color $FG;
@define-color card_bg_color $BG;
@define-color card_fg_color $FG;
@define-color dialog_bg_color $BG;
@define-color dialog_fg_color $FG;
@define-color popover_bg_color $BG;
@define-color popover_fg_color $FG;
@define-color accent_color $ACCENT;
@define-color accent_bg_color $ACCENT;
@define-color accent_fg_color $BG;
@define-color borders $FG;
/* Unfocused ("backdrop") windows. libadwaita 1.7 swaps to these names when a
 * window loses focus (Alt+Tab away). Left unset they fall back to the LIGHT
 * scheme's #f2f2f4, so the sidebar turned into a white bar the moment another
 * app was on top. Named, like the rest, so new widgets inherit them. */
@define-color headerbar_backdrop_color $BG;
@define-color sidebar_backdrop_color $BG;
@define-color secondary_sidebar_backdrop_color $BG;

/* Typography: optical sizes. Body text uses the face drawn for small sizes,
 * headings use the one drawn for large sizes. Falls back automatically. */
* { font-family: $FONT_TEXT; }
.title-1, .title-2, .title-3, .title-4, .large-title,
headerbar .title, window.dialog .title {
  font-family: $FONT_DISPLAY;
}
.caption, .caption-heading, .monospace ~ .caption { font-family: $FONT_SMALL; }

/* Edges are OUTLINES, never borders: a border changes box geometry and forces
 * a CPU reflow on every focus change; an outline is composited by the GPU. */
.card, list.boxed-list > row, row.activatable {
  outline: 1px solid $FG; outline-offset: -1px; border: none;
}

/* Right-click context menus & popovers (GtkPopoverMenu -> GtkPopover -> contents).
 * libadwaita draws the popover edge as a translucent box-shadow that is
 * invisible on a black background. border not outline here because the
 * popover arrow reads border-bottom-width from contents to align its edge. */
popover > contents {
  border: 1px solid $FG;
  box-shadow: none;
  background-color: $BG;
}

/* Entries: bright thin edge at rest, full-strength accent on focus.
 * libadwaita's stock focus ring is a translucent box-shadow, which is what
 * makes it look faded — it is removed, not tinted. */
entry, .entry, entry.search, searchbar entry {
  outline: 1px solid $FG; outline-offset: -1px;
  border: none; box-shadow: none;
  background-color: $BG; color: $FG;
}
entry:focus, entry:focus-within, .entry:focus-within, entry.search:focus-within {
  outline: 2px solid $ACCENT; outline-offset: -2px;
  border: none; box-shadow: none;
}
entry text, entry > text { background-color: transparent; color: $FG; }
entry placeholder, entry text placeholder { opacity: 1.0; color: $DIM; }

row.activatable:hover, button:hover, tab:hover {
  outline: 1px solid $FG; outline-offset: -1px; background-color: transparent;
}

/* Selection is a SOLID BLOCK, never a tint. libadwaita draws sidebar and list
 * selection as a translucent overlay of the foreground colour; over a black
 * background that lands at near-invisible dark grey, so a selected bookmark
 * looks identical to an unselected one. Same failure as the stock focus ring
 * above — the fix is to replace it, not to lighten it.
 * Solid $ACCENT with $BG text is the settled spec: it is what the Firefox
 * theme has drawn the active tab with since 151. Black on pink = 13.65:1. */
row:selected, row.activatable:selected, .navigation-sidebar row:selected,
listview > row:selected, columnview > listview > row:selected,
gridview child:selected, flowbox > flowboxchild:selected,
menuitem:selected, modelbutton:selected, .view:selected, treeview.view:selected {
  background-color: $ACCENT; background-image: none; color: $BG;
  border: none; outline: none; box-shadow: none;
}
/* Everything nested inside a selected row turns black too: labels, symbolic
 * icons (which paint with the CSS color property, not fill), and subtitles that
 * the dim-label rule below would otherwise leave cyan on pink: 1.23:1. */
row:selected label, row:selected image,
.navigation-sidebar row:selected label, .navigation-sidebar row:selected image,
listview > row:selected label, listview > row:selected image,
gridview child:selected label, gridview child:selected image,
menuitem:selected label, modelbutton:selected label,
row:selected .dim-label, row:selected .subtitle, row:selected .caption {
  color: $BG; opacity: 1.0;
}
/* Selected AND keyboard-focused: keep the block, add a cyan outline so the
 * caret position stays visible against the pink. */
row:selected:focus-visible, .navigation-sidebar row:selected:focus-visible,
listview > row:selected:focus-visible {
  outline: 2px solid $FG; outline-offset: -2px;
}
/* Highlighted text in entries and labels. */
selection, entry selection, text selection, label selection {
  background-color: $ACCENT; color: $BG;
}

/* Secondary text: a dimmed hue, not transparency. 8.55:1 instead of 5.17:1. */
.dim-label, .subtitle, .caption, label.dim-label { opacity: 1.0; color: $DIM; }

/* "Greyed out" must not mean "invisible". libadwaita menus use modelbutton,
 * which a generic label:disabled rule never reaches. $DISABLED = 6.54:1. */
*:disabled, label:disabled,
modelbutton:disabled, modelbutton:disabled label,
menuitem:disabled, menuitem:disabled label,
button:disabled label, row:disabled label { opacity: 1.0; color: $DISABLED; }

/* Unfocused windows keep full contrast. libadwaita fades the header bar,
 * search bar, action bar and tab bar to filter: opacity(0.5) on backdrop, which
 * halves every contrast ratio above. Same selectors as libadwaita 1.7, so the
 * user stylesheet wins on priority alone. */
headerbar:backdrop > windowhandle,
toolbarview > .top-bar:backdrop > windowhandle,
toolbarview > .bottom-bar:backdrop > windowhandle,
searchbar > revealer > box:backdrop > *,
actionbar > revealer > box:backdrop > *,
tabbar .box:backdrop > scrolledwindow,
tabbar .box:backdrop > .start-action, tabbar .box:backdrop > .end-action,
banner > revealer > widget:backdrop > label,
banner > revealer > widget:backdrop > button { filter: none; }
/* GTK4 apps WITHOUT libadwaita load GTK's built-in theme instead, which fades
 * the window title and greys button text (#919190) on backdrop. inherit takes
 * the colour the button had when focused; coloured buttons keep their own. */
headerbar:backdrop .title, .titlebar:backdrop:not(headerbar) .title { filter: none; }
button:backdrop:not(:disabled):not(.suggested-action):not(.destructive-action):not(.opaque),
notebook > header > tabs > arrow:backdrop:not(:disabled) { color: inherit; }

/* Cost the GPU nothing: no fade work, no battery spent animating. */
* { transition-duration: 0.01ms; animation-duration: 0.01ms; }
$END
CSS

read -r -d '' GTK3_BLOCK <<CSS
$BEGIN
@define-color theme_bg_color $BG;
@define-color theme_fg_color $FG;
@define-color theme_base_color $BG;
@define-color theme_text_color $FG;
@define-color theme_selected_bg_color $ACCENT;
@define-color theme_selected_fg_color $BG;
@define-color insensitive_bg_color $BG;
@define-color insensitive_fg_color $DIM;
@define-color borders $FG;
@define-color theme_unfocused_bg_color $BG;
@define-color theme_unfocused_fg_color $FG;
@define-color theme_unfocused_base_color $BG;
@define-color theme_unfocused_text_color $FG;
/* The rest of GTK3's unfocused set. Unset, an unfocused window's selection
 * fell back to Adwaita blue, its borders and title to grey. */
@define-color theme_unfocused_selected_bg_color $ACCENT;
@define-color theme_unfocused_selected_fg_color $BG;
@define-color unfocused_borders $FG;
@define-color unfocused_insensitive_color $BG;
@define-color wm_unfocused_title $FG;
/* yelp and other help viewers take page link colours from the theme.
 * GTK's default blue on black is 5.57:1; cyan is 16.75:1. */
@define-color link_color $FG;
@define-color visited_link_color $ACCENT;
@define-color success_color $FG;
@define-color warning_color $ACCENT;

* { font-family: $FONT_TEXT; }

/* GTK3 menus, context menus, and popovers: 1px cyan border */
menu, .menu, popover > contents {
  border: 1px solid $FG;
  background-color: $BG;
}

/* The named colours above cover most GTK3 selection, but list rows and menu
 * items still blend a translucent overlay. Same solid block as GTK4. */
row:selected, list row:selected, menuitem:selected,
.view:selected, treeview.view:selected, iconview:selected, selection {
  background-color: $ACCENT; background-image: none; color: $BG;
  border: none; outline: none; box-shadow: none;
}
row:selected label, menuitem:selected label,
.view:selected label, row:selected .dim-label { color: $BG; opacity: 1.0; }
/* Unfocused windows keep full contrast. GTK3's Adwaita writes its backdrop
 * colours as fixed greys (#919190 text), not names, so the named colours above
 * never reach them: the whole window's text greyed out on Alt+Tab. These are
 * the elements it greys; the user stylesheet wins on priority alone. */
.background:backdrop { color: $FG; }
button:backdrop:not(:disabled):not(.suggested-action):not(.destructive-action),
notebook > header > tabs > arrow:backdrop:not(:disabled),
menu menuitem:backdrop, .menu menuitem:backdrop, .context-menu menuitem:backdrop,
placessidebar row:backdrop, notebook > header tab:backdrop,
.inline-toolbar toolbutton > button:backdrop,
switch:backdrop, scale slider:backdrop, spinner:backdrop, .keycap:backdrop { color: inherit; }
button.sidebar-button:backdrop > image { opacity: 1.0; }
row:selected:backdrop, row:selected:backdrop label, row:selected:backdrop button,
.view:selected:backdrop, menuitem:selected:backdrop label { color: $BG; }
.dim-label, label.dim-label, .dim-label:backdrop { opacity: 1.0; color: $DIM; }
*:disabled, label:disabled, *:disabled:backdrop { opacity: 1.0; color: $DISABLED; }
* { transition-duration: 0.01ms; animation-duration: 0.01ms; }
$END
CSS

# Do NOT escape $1 here — "$1" assigns the literal string, not the argument,
# which silently turns this into a no-op and makes the installer append a new
# copy of the block on every run.
strip () {
    local f="$1"
    [ -f "$f" ] || return 0
    # Strip both current and legacy markers
    awk '
        /\/\* BEGIN (black-gorilla-theme|high-contrast-theme) \*\//{skip=1}
        !skip{print}
        /\/\* END (black-gorilla-theme|high-contrast-theme) \*\//{skip=0}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    grep -q '[^[:space:]]' "$f" 2>/dev/null || rm -f "$f"
}

case "${1:-apply}" in
  --check)
      for f in "$GTK4" "$GTK3"; do
          if [ -f "$f" ] && grep -qE 'black-gorilla-theme|high-contrast-theme' "$f"; then
              n=$(grep -cE 'BEGIN (black-gorilla-theme|high-contrast-theme)' "$f")
              echo "  applied ($n block) $f"
          else
              echo "  not applied      $f"
          fi
      done
      echo
      have_font "Segoe UI Variable Static Text" \
        && echo "  fonts: Segoe UI Variable found — optical sizes in use" \
        || echo "  fonts: Segoe not installed — falling back to Inter/Cantarell/Noto/DejaVu"
      cat <<'INFO'

  Measured contrast (WCAG AA needs 4.5, AAA needs 7.0):
    cyan  #00FFFF on black   16.75:1
    pink  #FFC0CB on black   13.65:1
    dim   #00B8B8 on black    8.55:1
    (Adwaita-dark secondary text, for comparison:  5.17:1)
INFO
      exit 0 ;;
  --revert)
      strip "$GTK4"; strip "$GTK3"
      for st in "$STATE" "$HOME/.config/high-contrast-theme.state"; do
          if [ -f "$st" ]; then
              # shellcheck disable=SC1090
              . "$st"
              [ -n "${OLD_FONT:-}" ] && gsettings set org.gnome.desktop.interface font-name "$OLD_FONT"
              [ -n "${OLD_SCALE:-}" ] && gsettings set org.gnome.desktop.interface text-scaling-factor "$OLD_SCALE"
              rm -f "$st"
              echo "  restored previous font settings"
          fi
      done
      # Deliberately KEPT: a revert is a decision, and the stamp is what stops
      # the login hook putting the theme straight back.
      mkdir -p "$(dirname "$STAMP")" && : > "$STAMP"
      rm -f "$HOME/.config/high-contrast-theme.decided"
      echo "Reverted. Restart apps (or log out) to see stock appearance."
      exit 0 ;;
  --apply-once)
      if [ -e "$STAMP" ] || [ -e "$HOME/.config/high-contrast-theme.decided" ]; then
          # Already decided. A user who KEPT the theme still has our block, so
          # refresh it: otherwise a package upgrade never reaches them and they
          # keep the old CSS (how the 26.08.15 unfocused-window bug would have
          # survived every upgrade). A user who reverted has no block: untouched.
          grep -qF "$BEGIN" "$GTK4" 2>/dev/null || exit 0
      else
          mkdir -p "$(dirname "$STAMP")" && : > "$STAMP"
      fi
      QUIET=1 ;;
  apply|--fonts) ;;
  # Print the header block as usage. The range is DERIVED, not hardcoded: a
  # version stamp inserted at the top used to silently shift it out of line.
  *) awk 'NR>1 && /^#/ {print} NR>1 && !/^#/ {exit}' "$0"; exit 2 ;;
esac

say () { [ "${QUIET:-0}" = 1 ] || echo "$@"; }

say "Black Gorilla Theme: changes EVERY GTK application on this desktop."
say "Reversible at any time with: $0 --revert"
say

mkdir -p "$(dirname "$GTK4")" "$(dirname "$GTK3")"
strip "$GTK4"; strip "$GTK3"
printf '%s\n' "$GTK4_BLOCK" >> "$GTK4"
printf '%s\n' "$GTK3_BLOCK" >> "$GTK3"
say "  wrote $GTK4"
say "  wrote $GTK3"

if [ "${1:-}" = "--fonts" ]; then
    if command -v gsettings >/dev/null; then
        [ -f "$STATE" ] || cat > "$STATE" <<EOF
OLD_FONT='$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")'
OLD_SCALE='$(gsettings get org.gnome.desktop.interface text-scaling-factor)'
EOF
        if have_font "Segoe UI Variable Static Text"; then
            gsettings set org.gnome.desktop.interface font-name 'Segoe UI Variable Static Text 11'
        elif have_font "Inter"; then
            gsettings set org.gnome.desktop.interface font-name 'Inter 11'
        else
            gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
        fi
        gsettings set org.gnome.desktop.interface text-scaling-factor 1.0
        echo "  desktop font -> $(gsettings get org.gnome.desktop.interface font-name), scale 1.0"
        echo "  (previous values saved in $STATE for --revert)"
    fi
fi

say
have_font "Segoe UI Variable Static Text" \
  || say "  note: Segoe UI Variable not installed — using free fallbacks (this is fine)"
say "Restart an app to see it, e.g.:  pkill -x epiphany"
