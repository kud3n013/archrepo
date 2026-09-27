# Proton Mail & Calendar (`proton-mail`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.15.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/mail)

Official desktop client for Proton Mail and Proton Calendar with restored system tray, close-to-tray, and unconstrained resizing.

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
| **Current Version** | `1.15.0-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Mail](https://proton.me/mail) |
| **Category** | Core Application |

---

### Overview
The official desktop client for Proton's privacy-first email and calendar suite.

### Modifications in `archrepo`
- **System Tray & Close-to-Tray Patch (`patch-tray.js`)**: Modifies `.webpack/main/index.js` to inject system tray functionality, allowing the app to minimize to the notification tray on close rather than exiting.
- **Unconstrained Resizing**: Removes hardcoded minimum window sizes so the application can be freely resized in tiling window managers (Hyprland, Sway, i3).
- **Background Flashing Fix**: Sets dark background style on the blank initialization page to prevent white blinding flashes during startup in dark mode.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/proton-mail-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
```

## 🔗 Related Links

- [Upstream Repository / Website](https://proton.me/mail)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
