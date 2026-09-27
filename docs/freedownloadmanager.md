# Free Download Manager (`freedownloadmanager`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-6.34.4.6974--4-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.freedownloadmanager.org/)

Fast and powerful modern download accelerator, BitTorrent client, and organizer built on Qt6.

---

## 📥 Installation

```bash
sudo pacman -S freedownloadmanager
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `freedownloadmanager` |
| **Current Version** | `6.34.4.6974-4` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Free Download Manager](https://www.freedownloadmanager.org/) |
| **Category** | Core Application |

---

### Overview
Free Download Manager (FDM) is an all-in-one download manager supporting HTTP, HTTPS, FTP, and BitTorrent protocols with multi-threaded acceleration.

### Modifications in `archrepo`
- **Dynamic Dark Mode & Theme Detection (`fdm-theme-fix.c`)**: Upstream FDM bundles Qt6 libraries that default to a blinding white light theme even when the system dark mode is active. This package compiles a lightweight shared library (`libfdm-theme-fix.so`) and injects it into the executable using `patchelf --add-needed`, ensuring `QT_QPA_PLATFORMTHEME=xdgdesktopportal` automatically follows system dark/light preference across modern Wayland and X11 desktops.
- **Wayland Platform Selection**: The wrapper allows switching between `wayland` and `xcb` seamlessly.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/freedownloadmanager-flags.conf`

```bash
# Desktop portal dark theme detection
QT_QPA_PLATFORMTHEME=xdgdesktopportal

# Backend selection: auto, wayland, or xcb
# QT_QPA_PLATFORM=wayland;xcb
```

## 🔗 Related Links

- [Upstream Repository / Website](https://www.freedownloadmanager.org/)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
