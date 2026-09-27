# Google Antigravity (`antigravity`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.17.0--5-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://antigravity.google)

Google Antigravity 2.0 multi-agent orchestration platform with native Wayland support and configurable window controls.

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
| **Current Version** | `2.17.0-5` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Google Antigravity](https://antigravity.google) |
| **Category** | Core Application |

---

### Overview
Google Antigravity 2.0 is an advanced agentic development environment and multi-agent orchestration platform.

### Modifications in `archrepo`
This package contains specialized adaptations for modern Linux and Wayland desktop environments:
- **Window Controls Patch**: Executes `patch-window-controls.js` against upstream JavaScript assets (`dist/utils.js`, `dist/preload.js`, and `dist/menu.js`) to provide customizable window decorations and seamless window manager integration.
- **Smart Launcher Wrapper (`antigravity.sh`)**:
  - Automatically detects the active desktop environment.
  - On KDE Plasma (Wayland/X11), launches via X11/XWayland to allow full D-Bus menu export to the KDE Plasma Global Menu widget.
  - On tiling Wayland compositors (Hyprland, Sway) or GNOME, launches in native Wayland with `--ozone-platform-hint=auto` and `--enable-wayland-ime`.
  - Supports `--titlebar=native`, `--titlebar=hidden`, or `--titlebar=overlay`.
- **User Flags**: Configurable via `~/.config/antigravity-flags.conf` and `/etc/antigravity-flags.conf`.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/antigravity-flags.conf`

```bash
# Display backend (Wayland / X11)
--ozone-platform-hint=auto
--enable-wayland-ime

# Titlebar mode: native (system decorations), hidden (frameless / tiling WM), or overlay
--titlebar=native
```

## 🔗 Related Links

- [Upstream Repository / Website](https://antigravity.google)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
