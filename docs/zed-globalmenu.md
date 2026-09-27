# Zed (KDE Global Menu Edition) (`zed-globalmenu`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://zed.dev)

High-performance Zed code editor built from source with KDE Plasma Global Menu (AppMenu DBus) integration, server-side title bar decorations, and dynamic in-app menu suppression.

---

## 📥 Installation

```bash
sudo pacman -S zed-globalmenu
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zed-globalmenu` |
| **Current Version** | `1.21.0-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Zed Industries](https://zed.dev) |
| **Category** | Development / Code Editor |

---

### Overview
A custom build of the Zed editor compiled from source with deep KDE Plasma integration:
- **KDE Global Menu Export**: Implements the canonical DBusMenu (`com.canonical.dbusmenu`) and KDE KWin AppMenu (`org_kde_kwin_appmenu`) protocols into GPUI's Linux platform layer.
- **Server-Side Window Decorations**: Window decorations default to native system server-side decorations (`#[default] Server` in settings and wrapper script), adhering to the system window manager title bar and theme.
- **In-App Menu Suppression**: Automatically detects when a Global Menu registrar/daemon is active and suppresses the internal menu bar and hamburger menu button, preventing redundant duplicate menus.

---

## ⚙️ Configuration & Flags

Configuration files:
- System default: `/etc/zed-globalmenu-flags.conf`
- User overrides: `~/.config/zed-globalmenu-flags.conf` (or `~/.config/zed-flags.conf`)

Available environment variables:
```bash
# Force server-side (system) or client-side (CSD) decorations:
# ZED_WINDOW_DECORATIONS=server
# ZED_WINDOW_DECORATIONS=client

# Force Wayland or X11 backend:
# WAYLAND_DISPLAY=""
```

---

## 🔗 Related Links

- [Upstream Website](https://zed.dev)
- [Zed GitHub Repository](https://github.com/zed-industries/zed)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
