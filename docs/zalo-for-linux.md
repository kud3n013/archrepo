# Zalo for Linux (`zalo-for-linux`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-26.10.11--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#changes-from-the-upstream-appimage)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/VN-Linux-Family/zalo-for-linux)

Unofficial Zalo client for Linux, with ZaDark. On KDE Plasma it uses the KWin title bar, shows its menu in the Global Menu, and follows the system light/dark setting live.

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
| **Current Version** | `26.10.11-1` |
| **Package Type** | **Modified (repackaged upstream AppImage, small app.asar bootstrap)** |
| **Build Status** | `passing` |
| **Upstream Project** | [VN-Linux-Family/zalo-for-linux](https://github.com/VN-Linux-Family/zalo-for-linux) |
| **Category** | Communication |
| **Electron Runtime** | 22.3.27 (Chromium 108) |

---

### Overview
Upstream takes the macOS Zalo app, swaps its native addons for Linux builds and wraps it in Electron 22, with ZaDark built in. This package takes upstream's ZaDark AppImage and installs its application tree to `/opt/zalo-for-linux`.

### Changes from the upstream AppImage
- **System libraries.** The tree runs on Arch's libraries. The AppImage runtime, `AppRun` and the libraries electron-builder bundles in `usr/lib` (libappindicator, libgconf, libnotify, ...) are not installed. `resources/app-update.yml` is removed, because updates come from pacman.
- **Launcher** `/usr/bin/zalo` reads `~/.config/zalo-flags.conf` (or `/etc/zalo-flags.conf`) and chooses the display server (see below).
- **Bootstrap** `archrepo-bootstrap.js`, added to `app.asar` as the new entry point. It runs before upstream's code and adds the theme sync and title bar changes below. Nothing else inside the app changes. The build fails if upstream's entry point, or one of the two upstream patches the bootstrap relies on, is missing after a version bump.

### Title bar
Upstream already gives the main window a native frame on X11. On native Wayland it doesn't, because Electron 22 draws no decorations there. Zalo's own macOS-style bar ("Zalo - name") then sits under the KWin title bar, so the bootstrap hides it on the main window. Popped-out conversation windows are frameless and keep their bar.

### Global Menu
The menu is Zalo's own (About, Preferences `Ctrl+,`, Edit, View with `Alt+1`–`Alt+3`, Window), which Electron exports over DBusMenu. Electron 22 exports it only on X11, so on KDE Plasma the launcher runs Zalo under XWayland. The launcher also preloads [`dbusmenu-shortcut-shim`](dbusmenu-shortcut-shim.md), so Plasma shows `Ctrl+,` instead of no shortcut. Alt still shows the in-window menu bar.

### Theme sync
Electron 22 (Chromium 108) doesn't read the desktop portal's `color-scheme` by itself. Upstream's sync polls it every 10 seconds with blocking `dbus-send` calls. The bootstrap replaces it:
- it reads `org.freedesktop.appearance color-scheme` from the portal once at start, without blocking;
- it listens for `SettingChanged`, so a change in System Settings → Colors applies within about a second;
- it falls back to GSettings when no portal answers;
- it sets `nativeTheme.themeSource` and sends upstream's own `zalo-linux-theme-change` message, so Zalo's UI follows while its theme setting is "System".

ZaDark follows when its theme is set to **Auto** in ZaDark's settings. Its Light and Dark choices are kept as you set them.

The launcher pins the installed GTK3 modules into memory, the same as the other Electron packages here. This stops a crash on theme change under X11, where Electron unloads GTK while modules such as `colorreload-gtk-module` still have callbacks registered.

---

## ⚙️ Configuration

Flags go in `~/.config/zalo-flags.conf`, one per line:

```bash
# Native Wayland on KDE too (no KWin title bar, no Global Menu)
# --ozone-platform=wayland
# --enable-wayland-ime

# UI scaling for high-DPI screens
# --force-device-scale-factor=1.5
```

Environment variables:

| Variable | Effect |
|---|---|
| `ZALO_THEME_SYNC=0` | Turns off the live theme sync. Upstream's 10-second poll takes over. |
| `ZALO_INPAGE_TITLEBAR=1` | Keeps Zalo's own "Zalo - name" bar under the KWin title bar. |

Voice and video calls use upstream's native engine and need `python`, `opus` and `libpulse` (optional dependencies).

## 🔗 Related Links

- [Upstream Repository](https://github.com/VN-Linux-Family/zalo-for-linux)
- [ZaDark](https://zadark.com)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
