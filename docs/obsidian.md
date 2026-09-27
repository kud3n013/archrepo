# Obsidian (`obsidian`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.13.7--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://obsidian.md)

Powerful knowledge base and Markdown note-taking app operating on local folders, enhanced with KDE Global Menu and XDG portal theme sync.

---

## 📥 Installation

```bash
sudo pacman -S obsidian
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `obsidian` |
| **Current Version** | `1.13.7-3` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Obsidian](https://obsidian.md) |
| **Category** | Core Application |

---

### Overview
Obsidian is a private, extensible Markdown-based knowledge base and second brain.

### Modifications in `archrepo`
This package provides premier desktop environment enhancements:
- **KDE Plasma Global Menu Integration**: Includes a custom compiled shared library (`obsidian-globalmenu.c`) loaded via LD_PRELOAD and JavaScript hooks (`patch-globalmenu.js`) that export Obsidian's menu bar directly to KDE Plasma's Global Menu / AppMenu widget over D-Bus.
- **XDG Desktop Portal Theme Auto-Switching (`patch-portal-theme.js`)**: Automatically syncs Obsidian's internal theme between light and dark according to the desktop portal's system color scheme preference.
- **Wayland Flags Loader**: Built-in support for Wayland flags via `~/.config/obsidian-flags.conf`.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/obsidian-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
# --force-device-scale-factor=1.5
```

## 🔗 Related Links

- [Upstream Repository / Website](https://obsidian.md)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
