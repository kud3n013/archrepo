# Galaxy Buds Client (`galaxybudsclient`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-5.2.1--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/timschneeb/GalaxyBudsClient)

Unofficial desktop manager for Samsung Galaxy Buds (all models including Buds, Buds+, Live, Pro, Buds2, Buds2 Pro, FE, Buds3, Buds3 Pro).

---

## 📥 Installation

```bash
sudo pacman -S galaxybudsclient
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `galaxybudsclient` |
| **Current Version** | `5.2.1-3` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [timschneeb/GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient) |
| **Category** | Core Application |

---

### Overview
GalaxyBudsClient gives Linux users complete control over Samsung Galaxy Buds earbuds, including Active Noise Cancellation (ANC), ambient sound levels, equalizer presets, touch touchpad actions, and battery status.

### Modifications in `archrepo`
- **Dynamic Wayland HiDPI Auto-Scaling**: Avalonia UI applications running through XWayland frequently suffer from microscopic UI scaling on high-resolution displays. The launcher script `galaxybudsclient.sh` detects display scales dynamically across Hyprland (`hyprctl`), Sway (`swaymsg`), KDE Plasma (`kreadconfig6`), GDK/Qt variables, and `xrdb`, setting `AVALONIA_GLOBAL_SCALE_FACTOR` automatically.
- **Persistent Tray Menu Hook (`EnsureTrayMenu.cs`)**: Installs a C# hook script to ensure the tray icon always exposes functional 'Open' and 'Quit' actions under Linux system tray implementations.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/galaxybudsclient-flags.conf`

```bash
# Manual Avalonia UI scale factor override (if needed)
# AVALONIA_GLOBAL_SCALE_FACTOR=1.5
```

## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/timschneeb/GalaxyBudsClient)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
