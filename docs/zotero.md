# Zotero (`zotero`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-10.0.3--11-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.zotero.org)

Premier reference manager with native title bar decorations, KDE Global Menu, and Hyprland/KDE theme auto-switching.

---

## 📥 Installation

```bash
sudo pacman -S zotero
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zotero` |
| **Current Version** | `10.0.3-11` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Zotero](https://www.zotero.org) |
| **Category** | Core Application |

---

### Overview
Zotero is a free, open-source tool for collecting, organizing, annotating, citing, and sharing research sources and bibliographies.

### Modifications in `archrepo`
- **Native Title Bar & Theming Patch (`patch-omni.py`)**: Patches `omni.ja` inside Zotero to enable native window decorations, fixing blurry or missing title bars on Wayland compositors (Hyprland, Sway), and dynamically adapts to system themes.
- **KDE Plasma Global Menu (`zotero-globalmenu.c`)**: Injects a custom LD_PRELOAD helper to expose Zotero's Mozilla-based menu hierarchy to KDE Plasma's Global Menu panel widget via D-Bus.
- **Wayland Integration**: Defaults to `MOZ_ENABLE_WAYLAND=1`.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zotero-flags.conf`

```bash
MOZ_ENABLE_WAYLAND=1
MOZ_APP_REMOTINGNAME=zotero
# ZOTERO_DESKTOP_ENV=kde
# ZOTERO_DESKTOP_ENV=hyprland
```

## 🔗 Related Links

- [Upstream Repository / Website](https://www.zotero.org)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
