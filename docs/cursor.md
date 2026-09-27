# Cursor (`cursor`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.22.7--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.cursor.com)

AI-first code editor built for pair programming with artificial intelligence, packaged from the official Debian x86_64 release with native Wayland auto-hinting, CLI routing, and flags support.

---

## 📥 Installation

```bash
sudo pacman -S cursor
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `cursor` |
| **Current Version** | `3.22.7-1` |
| **Package Type** | **Official Binary Repackage** |
| **Build Status** | `passing` |
| **Upstream Project** | [Cursor](https://www.cursor.com) |
| **Category** | Development / IDE |

---

### Overview
Cursor is an AI-powered code editor based on VS Code, engineered from the ground up for deep AI integration, intelligent autocomplete, conversational codebase indexing, and multi-file editing.

### Desktop Environment & Wayland Integration
- **Native Wayland & IME Support**: Launches with `--ozone-platform-hint=auto` and `--enable-wayland-ime` on Wayland sessions (KDE Plasma 6, GNOME, Hyprland, Sway).
- **Intelligent CLI Routing**: Running `cursor --help`, `cursor --version`, or `cursor agent` routes directly to the Cursor CLI without spurious Chromium flag warnings, while launching workspace folders (`cursor .`) or files leverages full desktop integration.
- **Dynamic User Configuration**: Allows user flags override via `~/.config/cursor-flags.conf` and system-wide `/etc/cursor-flags.conf`.
- **Clean Ghost Shortcut Handling**: Scriptlet cleans up legacy unmanaged shortcuts from `~/.local/share/applications/` on install/upgrade/remove.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/cursor-flags.conf`

```bash
# Display server backend (Wayland / X11)
--ozone-platform-hint=auto
--enable-wayland-ime

# Optional: High-DPI UI scaling
# --force-device-scale-factor=1.5

# Optional: Password store backend (gnome-libsecret, kwallet5, kwallet6, basic)
# --password-store=basic
```

## 🔗 Related Links

- [Upstream Website](https://www.cursor.com)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
