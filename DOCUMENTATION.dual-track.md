<!-- Version: 26.10.20-19-34 · updated 26-10-20-19-34 -->
# Black Gorilla Theme — Technical & Dual-Track Documentation

> Pure black (#000000), high-contrast (16.75:1) GTK3 & GTK4/libadwaita theme with crisp 1px cyan borders on floating menus and optical-size typography.

---

## 🧸 Section A — Layman Track (What Changed & Why)

### 1. The Right-Click Menu Problem
When you set the desktop to a pure black background (#000000), floating menus (like right-clicking inside a folder or window) also have a black background.

In standard GNOME/libadwaita, menus do not have a solid border. Instead, they rely on a faint translucent grey shadow to separate them from the window underneath. On standard grey themes that shadow is visible, but **on a pure black background, the shadow vanishes**. The context menu becomes an invisible black floating shape over a black window, leaving only floating text without visible boundaries.

### 2. The Solution
We added a crisp **1-pixel solid cyan border** (#00FFFF) around every right-click context menu and popover dialog, and stripped the translucent grey shadow. 

Now, when you right-click anywhere on the desktop or inside a folder:
- The menu has a clear, razor-sharp cyan perimeter.
- The menu contents remain pure black with high-contrast text.
- Active items highlight as solid pink (#FFC0CB) with black text.

### 3. Renaming & Versioning
- **Name:** Officially branded as `black-gorilla-theme`.
- **Version:** Uses the standard Gorilla timestamp format: `26.10.20-19-34` (YY.MM.DD-HH-MM).
- **Package:** Generates a lightweight (~16 KB) click-to-install `.deb` package (`black-gorilla-theme_26.10.20-19-34_all.deb`).

---

## 💻 Section B — Developer Track (Architecture & Implementation)

### 1. The GTK4 / libadwaita Popover CSS Node Tree

In GTK4 and libadwaita, context menus are rendered through the following widget chain:
```
Right mouse click (Button 3)
       ↓
GtkGestureClick / GtkEventController
       ↓
GtkPopoverMenu (subclass of GtkPopover)
       ↓
CSS Node Tree:
popover.background.menu
├── arrow
╰── contents
    ╰── <menu child items (modelbutton)>
```

### 2. Why `@define-color borders` Failed to Style Menus

The theme originally specified:
```css
@define-color borders #00FFFF;
@define-color popover_bg_color #000000;
@define-color popover_fg_color #00FFFF;
```

**Root Cause:**
Libadwaita's internal stylesheet does not style `popover` borders using the `@borders` variable. Instead, libadwaita styles `popover > contents` with:
- `box-shadow: 0 2px 8px 2px rgba(0, 0, 0, 0.08), 0 3px 20px 10px rgba(0, 0, 0, 0.08);`
- `background-clip: padding-box;`

Over a pure black background (`#000000`), a semi-transparent black shadow produces zero contrast delta against the black container underneath.

### 3. The CSS Rule Fix

Added explicit selector rules to `install.sh`:

#### GTK4 / libadwaita (`~/.config/gtk-4.0/gtk.css`):
```css
/* Right-click context menus & popovers (GtkPopoverMenu -> GtkPopover -> contents).
 * libadwaita draws the popover edge as a translucent box-shadow that is
 * invisible on a black background. border not outline here because the
 * popover arrow reads border-bottom-width from contents to align its edge. */
popover > contents {
  border: 1px solid #00FFFF;
  box-shadow: none;
  background-color: #000000;
}
```

#### GTK3 (`~/.config/gtk-3.0/gtk.css`):
```css
/* GTK3 menus, context menus, and popovers: 1px cyan border */
menu, .menu, popover > contents {
  border: 1px solid #00FFFF;
  background-color: #000000;
}
```

### 4. Why `border` instead of `outline` for Popovers

For cards, rows, and entries, the theme uses `outline: 1px solid $FG; outline-offset: -1px; border: none;` to avoid triggering box reflow during layout changes.

However, for `GtkPopover`:
- The GTK rendering engine draws the `arrow` node dynamically to connect the popover to the parent widget.
- The arrow calculates its perimeter width by inspecting `border-bottom-width` of the `contents` CSS node.
- If `outline` were used with `border: none`, the arrow would have a 0px border, creating a visible discontinuity between the arrow and the popover body.
- Using `border: 1px solid $FG` ensures both the popover box and its anchor arrow receive identical 1px cyan edges.

---

## 🔍 Section C — Audit & Verification Evidence

### 1. Screenshot Analysis (Before Fix)
Inspected `/home/gorilla/Pictures/Screenshots/Screenshot From 2026-08-15 07-27-29.png` across the context menu boundaries (rows 108–190, columns 289–384):

| Boundary | Cyan Pixels (#00FFFF) | Observed Colors | Result |
|---|---|---|---|
| Top Edge (rows 106–112) | **0** | Black (#000000), faint grey (#2b2b2b, #6b6b6b) | Faded shadow |
| Left Edge (cols 286–292) | **0** | Dark cyan tint (#001515, #002626) | Faded shadow |
| Bottom Edge (rows 186–192) | **0** | Neutral grey (#575757, #6c6c6c) | Drop shadow only |
| Right Edge (cols 380–386) | **0** | Black & faint grey | Faded shadow |

**Conclusion:** Confirmed zero cyan pixels on any menu edge prior to applying the `popover > contents` selector rule.

### 2. Contrast Ratios (WCAG AA target: 4.5:1, AAA target: 7.0:1)

```python
# Formula: (L1 + 0.05) / (L2 + 0.05)
```
- **Primary Text:** Cyan (`#00FFFF`) on Black (`#000000`) = **16.75:1** (WCAG AAA)
- **Selection Highlight:** Black (`#000000`) on Pink (`#FFC0CB`) = **13.65:1** (WCAG AAA)
- **Secondary / Dim Text:** Dim Cyan (`#00B8B8`) on Black (`#000000`) = **8.55:1** (WCAG AAA)
- **Disabled Text:** Muted Cyan (`#00A0A0`) on Black (`#000000`) = **6.54:1** (WCAG AA+)
- *Adwaita-Dark secondary text baseline for comparison:* **5.17:1**

### 3. Packaging & Installation Verification

- Built `.deb` output: `dist/black-gorilla-theme_26.08.15-08-17_all.deb` (16,244 bytes).
- Installed locally with: `sudo apt-get install -y ./dist/black-gorilla-theme_26.08.15-08-17_all.deb`.
- Verified dpkg status: `ii black-gorilla-theme 26.08.15-08-17 all`.
- Verified binary presence: `/usr/bin/black-gorilla-theme` and symlink `/usr/bin/gtk-high-contrast-theme`.
- Verified active CSS: `~/.config/gtk-4.0/gtk.css` and `~/.config/gtk-3.0/gtk.css` both contain the active `/* BEGIN black-gorilla-theme */` rule set with `popover > contents` border styling.

---

## Section D: Unfocused windows (release 26.10.20-18-27)

### Layman track

**What you saw (stated in input).** Files looked right while you were using it.
Put another program on top, or Alt+Tab away, and the left-hand panel turned into
a light grey bar with pale text. The buttons and path bar at the top faded to
half strength. Click back into Files and it was black and bright again.

**Why.** A window you are not using is called "unfocused". The toolkit that
draws Files keeps a second list of colours just for unfocused windows, so it
can make them look quieter. The theme set the first list and never set the
second, so the toolkit filled the gaps with its own colours, which are
designed for a light desktop. On top of that, the toolkit deliberately makes
parts of an unfocused window see-through at 50%, which halves the contrast.

**What changed.** The theme now sets the unfocused colours to the same black
and cyan as the focused ones, and switches off the 50% fade. Older programs
(GTK3) had the same gap in a different shape, and so did newer programs that
do not use libadwaita. Both are fixed too.

**One more way the bug could have stayed.** If you installed the old package,
upgrading it would NOT have fixed your screen: the package only applied the
theme the first time. It now refreshes the theme on upgrade for anyone still
using it. Anyone who switched the theme off stays switched off.

### Developer track

**Cause, GTK4/libadwaita (measured on libadwaita 1.7.6, GTK 4.18.6).**
libadwaita's backdrop rules read `--sidebar-backdrop-color`,
`--headerbar-backdrop-color` and `--secondary-sidebar-backdrop-color`, defined
from `@sidebar_backdrop_color` etc. The block set the `_bg_color` names only.
With `color-scheme` = `default` the light values applied: `sidebar_backdrop_color
#f2f2f4`. Separately, these rules apply `filter: opacity(0.5)`:
`headerbar:backdrop > windowhandle`, `toolbarview > .top-bar:backdrop >
windowhandle` (and `.bottom-bar`), `searchbar > revealer > box:backdrop > *`,
`actionbar > revealer > box:backdrop > *`, `tabbar .box:backdrop >
{scrolledwindow,.start-action,.end-action}`, `banner > revealer >
widget:backdrop > {label,button}`. The list was extracted from the library's
embedded CSS (`strings libadwaita-1.so.0 | grep :backdrop`, 68 rules) and is
complete for that version.

**Cause, GTK4 built-in theme (non-libadwaita GTK4 apps).** 144 backdrop rules;
the visible ones are `headerbar:backdrop .title { filter: opacity(0.5) }` and
button text set to fixed `#919190`.

**Cause, GTK3 Adwaita (GTK 3.24.49).** 887 backdrop rules, all fixed literals
compiled from SCSS. The root is `.background:backdrop { color: #919190 }`,
inherited by every label. Also missing named colours:
`theme_unfocused_selected_bg_color`, `theme_unfocused_selected_fg_color`,
`unfocused_borders`, `unfocused_insensitive_color`, `wm_unfocused_title`.

**Fix.** Name the three GTK4 backdrop colours and the five GTK3 ones.
Cancel each libadwaita and GTK4 fade with `filter: none` on the same selectors.
Set GTK3 `.background:backdrop` to `$FG` and `color: inherit` on the elements
GTK3/GTK4 grey individually. Coloured buttons (`.suggested-action`,
`.destructive-action`, `.opaque`) and `:disabled` are excluded so they keep
their own colour. The selected, dim and disabled rules gained `:backdrop`
forms so they still win inside the user stylesheet. This works because GTK
ranks the user stylesheet (`~/.config/gtk-*/gtk.css`) above the theme
regardless of selector specificity.

**Judgement call (model inference).** Focused GTK3 Adwaita-dark text is a
fixed `#eeeeec`, because GTK3 Adwaita ignores the named colours. Unfocused
GTK3 text is now `$FG` (cyan), the theme's declared foreground, so GTK3 text
changes from near-white to cyan on Alt+Tab. That makes it readable rather
than identical to the focused state.

**Superseded 26.10.20-18-42 (owner's request, 2026-10-20):** focused GTK3 text is now cyan as well, so
GTK3 text no longer changes colour on Alt+Tab. See section E.

**Upgrade path.** `--apply-once` exited whenever the decided-stamp existed, and
`postinst` keeps the stamp on upgrade, so a packaged upgrade never rewrote the
CSS. It now re-applies when the stamp exists AND `~/.config/gtk-4.0/gtk.css`
still contains the `BEGIN black-gorilla-theme` marker. `--revert` strips the
marker, so reverted users are untouched. Re-applying writes only the two CSS
blocks: fonts and the revert state file are not touched.

### Verification evidence

- Fake-HOME test, three cases: fresh install writes the block (18 backdrop
  lines, stamp created); kept-then-upgraded goes from 0 to 18 backdrop lines,
  the user's own appended rule survives, one block only; reverted-then-upgraded
  stays at 0 blocks.
- Both generated stylesheets parsed with `Gtk.CssProvider` (GTK 4.0 and 3.0
  via PyGObject): 0 errors. The same check reports a deliberately broken rule
  under both versions, so it can fail.
- `.deb` payload `usr/bin/black-gorilla-theme` byte-identical to `install.sh`.
- Real upgrade on the build machine: `ii black-gorilla-theme 26.10.20-18-27`,
  and postinst rewrote `~/.config/gtk-4.0/gtk.css` (mtime 18:29:16, after
  the package install).
- NOT yet verified: the result on screen. Files must be restarted to read the
  new CSS, and the owner deferred that while a build ran.

---

## Section E: GTK3 text and window edges (release 26.10.20-18-42)

### Layman track

**What changed (stated in input: the owner asked for both).** Older programs (GTK3) used to show
near-white text while in use and cyan text when another window was on top. Their text is now cyan in
both cases. Every window also has a thin cyan line around its edge, the same line the path bar has,
so you can see where one window ends and the next begins on a black screen.

**Checked on screen (stated in input).** The owner Alt+Tabbed through several programs: the
unfocused Files window kept its colours, and the cyan edge showed around Files.

### Developer track

**GTK3 text.** GTK3 Adwaita sets text as fixed literals (`.background { color: #eeeeec }`,
`.view`, `entry`, `button`, `notebook > header tab`, `list`, `calendar`, `.keycap`), which named
colours never reach. The block now sets `$FG` on `.background`, `.background:backdrop` and the
text-bearing nodes, and `color: inherit` on buttons, tabs, menu items, places-sidebar rows,
switches and sliders, with no `:backdrop` qualifier so both states are the same. Coloured buttons
(`.suggested-action`, `.destructive-action`) and `:disabled` are excluded. A hovered GTK3 menu item
(GTK3's selection) is the solid pink block, per the settled selection spec.

**Window edges.** Per the settled theme spec (outline, never border; pure cyan; no box-shadow):
GTK4 `window.csd, window.solid-csd { outline: 1px solid $FG; outline-offset: -1px; }`; GTK3
`decoration, decoration:backdrop` the same. libadwaita's own edge is a box-shadow of currentColor at
`--border-opacity`, and GTK3's is `box-shadow: 0 0 0 1px rgba(0,0,0,0.75)`: both invisible on black.
Programs whose window frame is drawn by the compositor (Firefox, Electron apps) are not GTK CSD
windows and do not get this edge (model inference, not tested).

### Verification evidence

- Both stylesheets parse in GTK 4.18 and GTK 3.24 with 0 errors (the same check reports a broken rule).
- The edge was seen on screen by the owner, screenshot `screenshots/window-edge-1px-cyan.png` (18:41:12).
- Screenshots: `unfocused-before-26.08.15.png` (18:11:18, the bug), `unfocused-after-26.10.20.png`
  (18:37:57, the fix), unscaled 1600x890 originals from the owner's screen.
- Harness: `fieldkit gtk-theme check` (Fieldkit) now runs these checks deterministically, and
  `fieldkit build-harness symptom` points the owner's own words for this bug at it.

---

## Section F: GTK3 apps get a real theme (release 26.10.20-19-34)

### Layman track

**What you saw (stated in input).** After the unfocused-window fix, older programs still looked
wrong: the Terminal had a light grey title bar, and its menus and preferences did not match.

**Why.** Two families of programs draw this desktop. The newer one (Files, Settings) picks its
colours by name, and the theme renames them, which is why those programs were already right. The
older one (GTK3: Terminal, Disks, Document Viewer, Evolution and about 20 more) has its colours
baked in as fixed numbers when GTK3 is built. No settings file reaches those numbers; you can only
patch them one place at a time, and every program showed a new gap.

**What changed.** Those baked-in colours come from one recipe file in GTK3's own source. We took
that recipe for the exact GTK3 version on this computer, swapped in black, cyan and pink, and
rebuilt it. The result is a theme called Black-Gorilla that GTK3 programs use. Every widget comes
out in our colours at once, including ones nobody has looked at yet. It is chosen for you once,
and the undo command puts your old theme back.

**Window edges and dialogs (stated in input: the owner asked for them).** Every window and every
dialog drawn inside a window (like Settings, System Details) now has the thin cyan edge.

**What it does not cover.** The 6 Qt programs (Telegram, Wireshark and others) use a different
toolkit, and Volume Control is the one program on a third kind of GTK. Both keep their own look.

### Developer track

**Source and proof of match.** GTK 3.24.49 `gtk/theme/Adwaita` (`_common.scss`, `_drawing.scss`,
`_colors-public.scss`, `gtk-contained-dark.scss`), pinned by sha256 in `adwaita/SOURCES.sha256`, 66
assets in `adwaita/ASSETS.sha256`. Compiled stock with `sassc -a -M -t compact` (upstream's
`parse-sass.sh` options): 957 of 957 rules appear verbatim in the installed
`libgtk-3.so.0.2417.32` (measured), so the sources are the ones this machine runs.

**Build.** `adwaita/build-adwaita.sh` replaces `_colors.scss` with `adwaita/_colors.scss` (every
upstream variable kept, values from BG/FG/ACCENT/DIM/DISABLED, backdrop values equal to focused),
applies two string patches to `_common.scss` that refuse if the expected text count differs
(suggested-action text `white` to `$selected_fg_color`, 7 sites, white on pink was about 1.5:1;
tooltip text `white` to `$osd_text_color`), appends `_black-gorilla.scss`, compiles to
`theme/Black-Gorilla/gtk-3.0/gtk.css` (961 rules), and `gtk-dark.css` is a one-line import (saved
170 KB). `--check` rebuilds into a temp folder and fails on any difference; `build-deb.sh` refuses
to package on drift. Downloads retry 4 times; one transient asset failure during development was
refused, not shipped (measured).

**Window edge in GTK3: outline does not draw (found by the owner's screenshots).** GTK3 renders CSS
`outline` only for keyboard-focus rectangles, so the outline rule shipped in 26.10.20-18-42 never
drew on any GTK3 window. GTK3's frame is `decoration { box-shadow: 0 0 0 1px ... }`; Adwaita draws it
black at 75%. Now `box-shadow: 0 0 0 1px $FG`, plus `window.unified > decoration-overlay { box-shadow:
inset 0 0 0 1px $FG }` for libhandy windows, whose overlay node (from libhandy's own Adwaita.css,
read with `gresource extract`) paints over the decoration. A GTK3 exception to the settled
"outline, never box-shadow", whose reason is CPU reflow from borders: a box-shadow ring replacing a
box-shadow ring costs nothing extra (model inference).

**In-window dialogs (libadwaita AdwDialog).** `floating-sheet > sheet` and `bottom-sheet > sheet`
carry libadwaita's `outline: 1px solid RGB(255 255 255/7%)` (read from `base.css` via `gresource
extract`); the GTK4 block sets it to `$FG`.

**Install.** `install.sh` copies `theme/Black-Gorilla` to `~/.local/share/themes` (only when it
differs; the package ships `/usr/share/themes/Black-Gorilla` instead) and selects it via
`gsettings org.gnome.desktop.interface gtk-theme` ONCE, saving `OLD_THEME` in the state file;
`--revert` restores it and leaves the files in place. GTK3 apps switch theme live. Tested in a fake
HOME with `GSETTINGS_BACKEND=memory` so the test never touched the real setting (measured: real
value unchanged before and after).

**Coverage on this machine (measured by linking, 2026-10-20).** 20 libadwaita apps (CSS block),
25 GTK3 apps incl. 8 on libhandy (rebuilt theme), 1 plain GTK4 (Volume Control: not rebuilt, not
worth it for one app), 6 Qt (out of reach).

**Size.** Theme 456 KB on disk; the .deb grows from 17 KB to about 92 KB (measured at the first
package build), about 12 s at 8 KB/s (model inference from the size).

**Performance: NOT measured.** CPU, GPU and battery effects are reasoning only (fewer animation
frames, no blurred GTK3 window shadow; no saving from black on an LCD). Measuring needs an idle
machine: deferred until the Firefox build finishes.

### Verification evidence

- Owner's screenshots, unscaled originals: `gtk3-terminal.png` (19:37:12, header bar and edge),
  `gtk3-terminal-preferences.png` (19:26:23), `gtk3-disks.png` (19:36:57, edge). System Details
  with its new edge seen by the owner (19:39), not published: it shows hardware details.
- Both stylesheets and the theme parse in GTK 4.18 / 3.24 with 0 errors.
- `fieldkit gtk-theme check`: no missing backdrop names, fades or root greys.
