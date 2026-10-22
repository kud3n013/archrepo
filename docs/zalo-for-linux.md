# Zalo for Linux (`zalo-for-linux`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-26.10.11--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#changes-from-upstream)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/VN-Linux-Family/zalo-for-linux)

Zalo messaging client for Linux, repackaged from the community port's ZaDark AppImage. On KDE Plasma it uses KWin's title bar, shows Zalo's menu in the Global Menu, and follows the system light/dark setting without a restart.

---

## 📥 Installation

```bash
sudo pacman -S zalo-for-linux
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zalo-for-linux` |
| **Current Version** | `26.10.11-2` |
| **Package Type** | **Modified (repackaged AppImage, bootstrap in `app.asar`)** |
| **Build Status** | `passing` |
| **Upstream Project** | [VN-Linux-Family/zalo-for-linux](https://github.com/VN-Linux-Family/zalo-for-linux) |
| **Category** | Communication |
| **Electron Runtime** | 22.3.27 (Chromium 108), bundled by upstream |

---

### Overview
Upstream ports Zalo's macOS app to Linux and ships it as an AppImage in two variants. This package uses the ZaDark one (`Zalo-<ver>+ZaDark-<zadark>-<commit>-x86_64.AppImage`), never the `-Original-` one.

The AppImage is a uruntime executable with a DwarFS image appended. No DwarFS tool is in the Arch repos, so `prepare()` uses the runtime's own `--appimage-extract`. The runtime is statically linked and needs no FUSE. Inside is a plain electron-builder AppDir, not a sharun one: the Electron binary uses the system dynamic loader.

### Changes from upstream
- **Runs against the system libraries.** The application tree goes to `/opt/zalo-for-linux` without upstream's `usr/` folder. That folder holds GTK2 `libappindicator`/`libindicator`, `gconf`, and copies of `libnotify`, `libXss` and `libXtst`, and nothing in this Electron version loads them. Electron's tray uses StatusNotifierItem over D-Bus. The launcher sets no `LD_LIBRARY_PATH` or `GSETTINGS_SCHEMA_DIR`.
- **Launcher** `/usr/bin/zalo` reads the flags file, picks the display backend (see [Why XWayland on KDE](#why-xwayland-on-kde)) and preloads `dbusmenu-shortcut-shim` on KDE.
- **Bootstrap in `app.asar`.** `archrepo-bootstrap.js` becomes the entry point, runs before upstream's shell `main.js`, and then requires it. No upstream file is edited. It adds the three features below, each in its own small file.
- **Build-time checks.** `patch-bootstrap.js` fails the build unless each piece of upstream code the bootstrap relies on is found exactly once: the frame patch, the theme sync guard, the preload half of the theme sync, and Zalo's own menu with its Preferences item. `prepare()` also checks that the repacked `app.asar` differs from upstream only by the archrepo files, and that Electron still links GTK directly (see [GTK modules](#gtk-modules)).
- **Icon** from the AppImage (512 px, the same image as `pc-dist/favicon-512x512.png`).

### Title bar
Upstream's own patch creates the main window with a native frame on X11 (`frame:!global.__zaloNativeWayland`), so KWin draws the title bar: Breeze decorations, your button layout, and double-click and right-click actions. Zalo's macOS bundle still draws its own 24 px strip at the top of the page ("Zalo - {name}"). The bootstrap hides that strip (`#titleBar`) on the main window with CSS, inserted again on every page load. Zalo hides the same strip itself in some states, so the layout supports it.

On native Wayland the window stays frameless, and upstream's `plugins/wayland-titlebar` draws window buttons into that strip, so it is left alone there. Chat windows popped out of the main window are frameless and keep their strip.

### Global Menu
Zalo's macOS bundle already builds a full application menu and sets it on Linux too:
- **zalo:** About, Preferences (`Ctrl+,`), Close, Quit
- **Edit**
- **View:** Messages, Contacts and Joined Groups (`Alt+1`–`Alt+3`), Full screen
- **Window**

The items send Zalo's own IPC messages. Upstream's shell tries to remove menus, and Electron put the menu on every window, including Zalo's hidden background windows. The bootstrap keeps Zalo's menu on the main window only. No menu is hand-written.

Under XWayland, Electron exports the menu over DBusMenu and Plasma shows it in the Global Menu. Where no Global Menu is available, Alt shows the menu bar in the window. The launcher also preloads `dbusmenu-shortcut-shim`. Electron 22 already exports `Ctrl+,` correctly, so the shim only matters if a future upstream release moves to a newer Electron, which exports `Ctrl+comma`.

### Theme sync
Electron 22 (Chromium 108) does not read the desktop portal's `color-scheme`. Under X11 it only reacts when the GTK theme *name* changes, and Plasma keeps the name "Breeze" when you switch between Breeze Light and Breeze Dark. Without help, Zalo never noticed the change.

- **Main process** (`archrepo-theme.js`):
  - Reads `org.freedesktop.appearance color-scheme` from the portal with an asynchronous `gdbus call`.
  - Watches `SettingChanged` for that key only, with one `gdbus monitor`.
  - Sets Electron's `nativeTheme.themeSource`, which flips `prefers-color-scheme` in every page.
  - If no portal answers, it reads Plasma's colours from `kdeglobals` once at start and does not watch them.
  - Upstream ships its own theme sync, which uses blocking `dbus-send` calls and a 10-second poll. The bootstrap disables it and keeps its IPC contract (`zalo-linux-get-theme`, `zalo-linux-theme-change`), so upstream's page-side code keeps working.
  - The monitor stops when Zalo exits, including after a crash.
- **Pages** (`archrepo-theme-preload.js`): Zalo and ZaDark only follow the system while their own setting says so, and the bootstrap respects that.
  - **Zalo:** Settings → Theme → *System* follows the system. *Light* and *Dark* always win.
  - **ZaDark:** its theme menu → *Auto* follows the system. *Light* and *Dark* always win. ZaDark starts in *Auto* when you have never picked a theme.

> **After upgrading from the old package:** it wrote `light` or `dark` into ZaDark's setting on every switch, which now reads as your own choice. Pick *Auto* in ZaDark once to make it follow the system again.

### Why XWayland on KDE
Zalo bundles Electron 22. On native Wayland that version draws no window decorations (upstream adds buttons into the page instead), and its Global Menu export is X11-only. So on KDE Plasma the launcher uses `--ozone-platform=x11`. On other Wayland compositors it uses native Wayland with upstream's in-page buttons. A `--ozone-platform…` flag in `zalo-flags.conf` or on the command line always wins.

### GTK modules
Unlike the `claude-desktop` and `obsidian` launchers, this one does not pin GTK modules with `LD_PRELOAD`. That workaround is for Electron versions that load GTK with `dlopen()` and unload it again. Electron 22 links GTK directly and never unloads it, and the build fails if that changes. In testing, Zalo survived 60 Plasma-style theme switches without the pin, with `colorreload-gtk-module`, `window-decorations-gtk-module` and `libcanberra-gtk3-module` loaded. `appmenu-gtk-module` was not installed for that test. If Zalo ever crashes on a theme switch, add the modules back, for example:

```bash
LD_PRELOAD=/usr/lib/gtk-3.0/modules/libcolorreload-gtk-module.so zalo
```

### Not shipped from upstream
- `usr/` from the AppImage (see above), `AppRun`, and the AppImage's own desktop file.
- Old optional dependencies for the Wine call bridge and the screen-sharing bridge (`wine`, `v4l-utils`, `v4l2loopback-dkms`, `xorg-server-xvfb`, `xdotool`, GStreamer). Upstream now uses a native call engine.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zalo-flags.conf` (wins over `/etc/zalo-flags.conf`). One flag per line.

```bash
# Force a display backend:
# --ozone-platform=wayland
# --ozone-platform=x11

# High-DPI scaling:
# --force-device-scale-factor=1.5
```

### Opt-outs
Set these in the environment to turn off one change at a time:

| Variable | Effect |
|---|---|
| `ZALO_GLOBALMENU=0` | No application menu, so nothing appears in the Global Menu and the menu shortcuts are off. This is what upstream's shell intends. |
| `ZALO_NATIVE_TITLEBAR=0` | Shows Zalo's own title bar strip again. KWin's title bar stays, because it comes from upstream's patch. |
| `ZALO_THEME_SYNC=0` | Turns off the archrepo theme sync. Upstream's own sync takes over: blocking portal reads and a 10-second poll. |

### Optional dependencies
- **Voice and video calls:** `python`, `opus`, `libpulse` (`pactl`, `pacat`, `parec`)
- **Pasting images:** `wl-clipboard`, `xclip`
- **Screenshots:** `spectacle`, `flameshot`, `gnome-screenshot`. Without any of them, Zalo uses the screenshot portal.

### Testing notes
Zalo keeps its data in `$XDG_CONFIG_HOME/ZaloData`, outside Electron's `--user-data-dir`. So a test instance needs its own `XDG_CONFIG_HOME` as well, or it shares data with your real profile.

**Not verified** (they need a signed-in account; only the QR login page was tested):
- `#titleBar` hidden in the signed-in view
- the full menu (Preferences, View)
- sending an image, a call, screenshots

---

## 🔗 Related Links

- [Upstream Repository](https://github.com/VN-Linux-Family/zalo-for-linux)
- [dbusmenu-shortcut-shim](dbusmenu-shortcut-shim.md)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
