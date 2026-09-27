# Zed (KDE Global Menu Edition) (`zed-globalmenu`)

[![build](https://img.shields.io/badge/build-failing-red)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://zed.dev)

High-performance Zed code editor built from source with experimental KDE Plasma Global Menu (AppMenu DBus) patch.

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
| **Build Status** | `failing` |
| **Upstream Project** | [Zed Industries](https://zed.dev) |
| **Category** | Core Application |

---

### Overview
A custom build of the Zed editor compiled directly from source incorporating patches for the KDE Plasma Global Menu bar.

### Modifications in `archrepo`
- **KDE Global Menu Patch (`zed-globalmenu.patch`)**: Integrates the `org.kde.kmenu` D-Bus AppMenu protocol directly into Zed's GPUI window handling code, allowing the editor menu bar to export to KDE Plasma's panel widget.
- Note: This is a heavy compilation target built from source.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zed-globalmenu-flags.conf`

```bash
# Zed Global Menu flags
# ZED_WINDOW_DECORATIONS=server
```

## 🔗 Related Links

- [Upstream Repository / Website](https://zed.dev)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
