# Zalo for Linux (`zalo-for-linux`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-26.9.10--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/VN-Linux-Family/zalo-for-linux)

Zalo messaging client for Linux with ZaDark dark mode, dynamic KDE Plasma light/dark theme synchronization, removed in-app top bar, and native KDE Global Menu export.

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
| **Current Version** | `26.9.10-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [VN-Linux-Family/zalo-for-linux](https://github.com/VN-Linux-Family/zalo-for-linux) |
| **Category** | Core Application |

---

### Overview
Zalo is one of the most widely used messaging applications in Southeast Asia. This package provides the desktop client adapted for Linux with community integration features.

### Modifications in `archrepo`
- **Dynamic KDE Light/Dark Theme Synchronization**: Automatically tracks KDE system color scheme in real time by monitoring `~/.config/kdeglobals`, portal appearance settings, and color luminance. Dynamically applies light or dark themes to both Zalo and ZaDark without requiring an application restart.
- **Removed In-App Top Bar**: Strips the redundant internal top bar that displays `"Zalo - {{user name}}"` and duplicate window buttons, reclaiming vertical screen real estate while letting the window manager handle decorations.
- **KDE Global Menu Export**: Restores and exports the complete application menu structure to KDE Plasma's Global Menu bar via standard DBusMenu (`com.canonical.dbusmenu` / `org.canonical.AppMenu.Registrar`).
- **Wayland Integration & User Flags**: Includes flags wrapper (`/usr/bin/zalo`) with support for user configuration at `~/.config/zalo-flags.conf` and high-resolution icons.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zalo-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime

# Optional: To export menu to KDE Global Menu under Wayland sessions (run via XWayland):
# --ozone-platform=x11

# Optional: Custom UI scaling for High-DPI screens (e.g. 2.8k display)
# --force-device-scale-factor=1.5

# Optional: Disable Wine call bridge completely (saves background CPU/RAM if calls are not needed)
# ZCALL_DISABLE=1
```

## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/VN-Linux-Family/zalo-for-linux)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
