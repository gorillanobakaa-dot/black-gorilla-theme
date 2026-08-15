<!-- Version: 26.08.15-08-17 · updated 26-08-15-08-17 -->
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
- **Version:** Uses the standard Gorilla timestamp format: `26.08.15-08-17` (YY.MM.DD-HH-MM).
- **Package:** Generates a lightweight (~16 KB) click-to-install `.deb` package (`black-gorilla-theme_26.08.15-08-17_all.deb`).

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
