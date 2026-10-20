<!-- Version: 26.10.20-18-27 · updated 26-10-20-18-27 -->
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
- **Version:** Uses the standard Gorilla timestamp format: `26.10.20-18-27` (YY.MM.DD-HH-MM).
- **Package:** Generates a lightweight (~16 KB) click-to-install `.deb` package (`black-gorilla-theme_26.10.20-18-27_all.deb`).

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
