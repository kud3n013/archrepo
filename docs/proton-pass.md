# Proton Pass (`proton-pass`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.42.0--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/pass)

Official desktop app for Proton Pass, the end-to-end encrypted password and identity manager, repackaged from Proton's Debian package.

---

## 📥 Installation

```bash
sudo pacman -S proton-pass
```

CachyOS also ships a `proton-pass` package. pacman takes a package from the first repository in `pacman.conf` that has it, so either keep `[archrepo]` above the CachyOS repositories or install it explicitly with `sudo pacman -S archrepo/proton-pass`.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `proton-pass` |
| **Current Version** | `1.42.0-2` |
| **Package Type** | **Original (repackaged upstream .deb)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Pass](https://proton.me/pass) ([source](https://github.com/ProtonMail/WebClients/tree/main/applications/pass-desktop)) |
| **Category** | Password Manager |

---

### Overview
The package takes `proton-pass_<version>_amd64.deb` from `proton.me/download/pass/linux/`. The nightly upstream check reads `proton.me/download/pass/linux/version.json`, so a new release reaches the repository within a day instead of waiting for a distribution repository. The application tree goes to `/opt/proton-pass`. `app.asar` is not modified.

### Changes from the upstream `.deb`
- **Launcher** `/usr/bin/proton-pass` replaces upstream's bare symlink. It selects native Wayland in a Wayland session, reads the flags file, and sets `CHROME_DESKTOP=proton-pass.desktop` so the Wayland window matches its desktop entry.
- **Desktop entry** `proton-pass.desktop` is this repository's file. It registers the `protonpass://` handler the app uses for its browser sign-in flow.
- **Icons.** Upstream's own `resources/assets/icon.png` and `logo.svg` are installed into the hicolor theme under the `proton-pass` name, so the launcher icon matches the app's window icon.

### Desktop integration
- **Title bar.** Upstream already uses the window manager's frame on Linux.
- **Light/dark theme.** The app's theme setting defaults to following the system, and Electron follows the desktop's color scheme through the XDG portal, so no theme bridge is added.
- **Tray.** Upstream has its own tray icon. GNOME needs the AppIndicator extension (`gnome-shell-extension-appindicator`).
- **Menu bar.** Upstream hides the menu bar until Alt is pressed. It is not exported to the KDE Global Menu on native Wayland.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/proton-pass-flags.conf` (falls back to `/etc/proton-pass-flags.conf`). One flag per line:

```bash
# --ozone-platform=x11
# --force-device-scale-factor=1.5
# --password-store=gnome-libsecret
```

## 🔗 Related Links

- [Proton Pass](https://proton.me/pass)
- [Upstream source (ProtonMail/WebClients, pass-desktop)](https://github.com/ProtonMail/WebClients/tree/main/applications/pass-desktop)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
