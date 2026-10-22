# Google Antigravity (`antigravity`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.22.0--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#modifications-in-archrepo)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://antigravity.google)

Google's agentic development platform, packaged from the official Linux x64 tarball with the window manager's title bar, the app's menu in the KDE Plasma Global Menu, and a light/dark theme that follows the desktop.

---

## 📥 Installation

```bash
sudo pacman -S antigravity
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `antigravity` |
| **Current Version** | `2.22.0-2` |
| **Package Type** | **Modified** |
| **Upstream Project** | [Google Antigravity](https://antigravity.google) |
| **Install Path** | `/opt/antigravity` |
| **Launcher** | `/usr/bin/antigravity` |

---

## Modifications in `archrepo`

No upstream file is edited. `patch-asar.js` adds `antigravity-bootstrap.js` to `app.asar` and points `package.json`'s `main` at it; the bootstrap then loads the original `dist/main.js`. The build fails if the entry point moves or if `app.asar.unpacked` comes out different from upstream's.

On Linux the bootstrap:

- **Title bar.** App windows get the window manager's frame instead of upstream's frameless window with Chromium's overlay buttons.
- **Menu.** Electron's default menu is replaced with one that mirrors the app's in-page menu bar and adds Edit, View and Help items:
  - *File*: New Conversation, New Window, Create Project, Open Workspace, Command Palette, Search Conversations, Settings, Close Window, Quit
  - *Edit*: Undo, Redo, Cut, Copy, Paste, Select All
  - *View*: Toggle Sidebar, Terminal, Auxiliary Pane, File Viewer, Zoom In/Out/Reset, Full Screen
  - *Window*: Minimize, Maximize, Close
  - *Help*: Docs, About

  Each item shows the app's own shortcut. Clicking it sends that keystroke to the page; pressing the shortcut goes straight to the page as upstream, because the menu does not register the accelerators itself. On KDE the menu appears in the Global Menu; elsewhere it is hidden and Alt shows it.
- **In-page menu bar.** The page's own menu row (`data-testid="title-menu-bar"`) is hidden, since the native menu replaces it.
- **Theme.** The page already follows the desktop: Electron 44 reads the XDG portal's `color-scheme` and updates `prefers-color-scheme` live. When the app's theme is set to follow the system (the default), the window background is kept in step too, so resizing shows no wrong-colored strip.

The launcher (`antigravity.sh`):

- reads flags from `~/.config/antigravity-flags.conf`, or `/etc/antigravity-flags.conf` if the user file is missing;
- on KDE Plasma Wayland runs under XWayland (`--ozone-platform=x11`), the only path where Electron's menu reaches the Global Menu; other Wayland desktops get native Wayland;
- under X11 on KDE, pins the GTK3 modules with `LD_PRELOAD` (Electron's `dlclose()` of GTK otherwise crashes) and preloads [`dbusmenu-shortcut-shim`](dbusmenu-shortcut-shim.md) so `Ctrl+,`, `Ctrl+=` and `Ctrl+-` show in the Global Menu;
- sets `CHROME_DESKTOP=antigravity.desktop`, which also makes the packaged entry the `antigravity://` sign-in handler.

---

## ⚙️ Configuration

Flags file: `~/.config/antigravity-flags.conf` (one flag per line).

```bash
# Force a display backend
--ozone-platform=wayland
# HiDPI scaling
--force-device-scale-factor=1.5
```

Environment variables:

| Variable | Effect |
|---|---|
| `ANTIGRAVITY_CSD=1` | Keep upstream's frameless window and in-page menu bar |
| `ANTIGRAVITY_GLOBALMENU=0` | On KDE Wayland, run native Wayland (no Global Menu) |

---

## 🔗 Related Links

- [Upstream website](https://antigravity.google)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
