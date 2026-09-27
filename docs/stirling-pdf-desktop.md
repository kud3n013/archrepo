# Stirling-PDF Desktop (`stirling-pdf-desktop`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.0.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/Stirling-Tools/Stirling-PDF)

Locally hosted, web-based PDF manipulation tool packaged as an official Tauri desktop application with KDE Plasma Qt title bar integration, Wayland / X11 compatibility, and crash mitigations.

---

## 📥 Installation

```bash
sudo pacman -S stirling-pdf-desktop
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `stirling-pdf-desktop` |
| **Current Version** | `3.0.1-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF) |
| **Category** | Office / Graphics / Utility |

---

### Overview
Stirling-PDF Desktop is the official Tauri v2 desktop application wrapping the locally running Stirling-PDF Java backend and modern web frontend.

This package provides enhanced Linux desktop integration:
- **KDE Plasma Qt Title Bar Integration**: Out of the box under Wayland, GTK3 renders Client-Side Decorations (CSD) with GNOME/GTK styling. In KDE Plasma sessions, the launcher wrapper automatically routes window management to provide native KWin Server-Side Decorations (SSD) styled with the user's active KDE Qt window decoration (Breeze, Oxygen, Klassy), complete with native buttons, title fonts, and right-click window menus.
- **Wayland Breeze GTK Synchronization**: If running natively on Wayland (`GDK_BACKEND=wayland`), the launcher automatically detects system dark/light mode and loads the Breeze GTK theme along with `window-decorations-gtk-module` so GTK CSD matches the KDE Qt appearance.
- **NVIDIA & Explicit Sync Crash Prevention**: Includes proactive workarounds for Wayland crashes on NVIDIA systems (`__NV_DISABLE_EXPLICIT_SYNC=1`) and WebKitGTK DMA-BUF renderer issues (`WEBKIT_DISABLE_DMABUF_RENDERER=1`).
- **Clean FreeDesktop Integration**: Standard `.desktop` entry with MIME type associations for `application/pdf`, high-resolution icons (up to 512x512), and `.install` scriptlets to prevent rogue shortcut duplication.

---

## ⚙️ Configuration & Flags

Configuration files:
- System default: `/etc/stirling-pdf-desktop-flags.conf`
- User overrides: `~/.config/stirling-pdf-desktop-flags.conf`

Available settings:
```bash
# --- Titlebar & Window Decoration Theme (KDE Plasma) ---
# Use native KDE Qt titlebars (Server-Side Decorations via KWin Breeze/Oxygen/Klassy):
GDK_BACKEND=x11

# Run natively under Wayland with Breeze GTK theme matching:
# GDK_BACKEND=wayland
# GTK_THEME=Breeze
# (or for dark mode)
# GTK_THEME=Breeze-Dark

# --- HiDPI Display Scaling ---
# GDK_SCALE=1
# GDK_DPI_SCALE=1

# --- Hardware Acceleration & Stability Workarounds ---
WEBKIT_DISABLE_DMABUF_RENDERER=1
__NV_DISABLE_EXPLICIT_SYNC=1
```

---

## 🔗 Related Links

- [Upstream Repository](https://github.com/Stirling-Tools/Stirling-PDF)
- [Official Releases](https://github.com/Stirling-Tools/Stirling-PDF/releases)
- [AUR Package: stirling-pdf-desktop](https://aur.archlinux.org/packages/stirling-pdf-desktop)
