# Proton Mail & Calendar (`proton-mail`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.15.1--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#system-tray)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/mail)

Official desktop app for Proton Mail and Proton Calendar, repackaged from Proton's Debian package, with a system tray icon, close-to-tray and live light/dark switching that follows the desktop.

---

## 📥 Installation

```bash
sudo pacman -S proton-mail
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `proton-mail` |
| **Current Version** | `1.15.1-3` |
| **Package Type** | **Modified (repackaged upstream .deb, system tray)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Mail](https://proton.me/mail) ([source](https://github.com/ProtonMail/WebClients/tree/main/applications/inbox-desktop)) |
| **Category** | Email / Calendar |
| **Electron Runtime** | 43 (bundled) |

---

### Overview
The package takes `ProtonMail-desktop-beta.deb` from `proton.me/download/mail/linux/<version>/`. Proton publishes only this "beta" build for Linux; the nightly upstream check reads `proton.me/download/mail/linux/version.json`. The application tree goes to `/opt/proton-mail`. The one change inside `app.asar` is a bootstrap that adds the tray and the live theme switching (see below).

### Changes from the upstream `.deb`
- **Launcher** `/usr/bin/proton-mail` replaces upstream's bare symlink. It selects native Wayland in a Wayland session, reads the flags file, and sets `CHROME_DESKTOP=proton-mail.desktop` so the Wayland window matches its desktop entry.
- **Desktop entry** `proton-mail.desktop` is this repository's file. The app looks for `/usr/share/applications/proton-mail.desktop` by that name when it checks whether it is the default mail app.
- **Icons.** The app icon (`proton-mail.png`) and the tray icon (`proton-mail-tray.svg`, from [homarr-labs/dashboard-icons](https://github.com/homarr-labs/dashboard-icons)) are kept in this repository. Upstream's scalable icon carries a "Beta" badge and is not installed, because icon themes prefer a scalable icon over the PNG. The window icon in `resources/icon.png` is replaced with the same PNG.
- **System tray** (`tray-bootstrap.js`, added to `app.asar`).
- **Live light/dark theme** (`theme-sync.js`, loaded by the bootstrap). See the section below.

### System tray
Upstream has no tray on Linux, and closing the window quits the app. The bootstrap runs before the app's own entry point and uses only Electron's public API, so it does not depend on names in the minified bundle:

- A tray icon with **Open Proton Mail**, **Open Proton Calendar** and **Quit**. Left click shows or hides the window.
- **Close-to-tray.** Closing the window hides it. Quit from the tray, File › Quit or Ctrl+Q quits.
- The two Open items use the app's own View menu entries (`switch-to-mail`, `switch-to-calendar`). While the account pages are showing (sign-in, account switch) the app disables those entries, and the tray item only shows the window.
- The tray is a StatusNotifierItem. KDE Plasma and most panels show it; GNOME needs the AppIndicator extension (`gnome-shell-extension-appindicator`). If no tray host is on the session bus at startup, no tray is created and closing the window quits, as upstream does.
- The window's minimum width is lowered from 900px to 360px so it fits a half-width tiling column.

Set `PROTON_MAIL_TRAY=0` in the environment to turn the tray and close-to-tray off.

### Light/dark theme
Proton's theme setting has three modes: Light, Dark and Auto. In Auto the app sets Electron's `nativeTheme.themeSource` to `system` and leaves the rest to Chromium, which does not always notice a change (under XWayland, or when the GTK theme name doesn't say "dark").

`theme-sync.js` reads `org.freedesktop.appearance color-scheme` from the XDG desktop portal and follows its `SettingChanged` signal with `gdbus monitor`. While the app is in Auto, it sets the real `themeSource` to `dark` or `light` to match, so Proton Mail, Calendar and the app's own pages switch the moment the desktop does. The app still reads back `system`, so its settings are not affected. Light and Dark mode are left alone. The window background used while a page loads is updated to Proton's Carbon (dark) or Snow (light) colour at the same time.

Without the portal's appearance setting, the initial scheme comes from KDE's `kdeglobals` or GNOME's `color-scheme` key. This is the same approach as `claude-desktop`'s `theme-sync.js`.

Set `PROTON_MAIL_THEME_SYNC=0` in the environment to turn it off.

### Desktop integration
- **Title bar.** Upstream already uses the window manager's frame on Linux.
- **Menu bar.** Upstream hides the menu bar until Alt is pressed. It is not exported to the KDE Global Menu on native Wayland.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/proton-mail-flags.conf` (falls back to `/etc/proton-mail-flags.conf`). One flag per line:

```bash
# --ozone-platform=x11
# --force-device-scale-factor=1.5
# --password-store=gnome-libsecret
```

Hardware acceleration is turned off in the app instead: File › Disable Hardware Acceleration.

## 🔗 Related Links

- [Proton Mail](https://proton.me/mail)
- [Upstream source (ProtonMail/WebClients, inbox-desktop)](https://github.com/ProtonMail/WebClients/tree/main/applications/inbox-desktop)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
