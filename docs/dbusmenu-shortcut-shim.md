# dbusmenu-shortcut-shim (`dbusmenu-shortcut-shim`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.0.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/kud3n013/dbusmenu-shortcut-shim)

LD_PRELOAD shim that makes KDE Plasma's Global Menu show punctuation shortcuts such as `Ctrl+,`.

---

## 📥 Installation

```bash
sudo pacman -S dbusmenu-shortcut-shim
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `dbusmenu-shortcut-shim` |
| **Current Version** | `1.0.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [kud3n013/dbusmenu-shortcut-shim](https://github.com/kud3n013/dbusmenu-shortcut-shim) |
| **Category** | Library / Add-on |

---

### Overview
Chromium/Electron and Gecko export menu accelerators over DBusMenu using key names such as `comma`. KDE Plasma's Global Menu only understands literal characters, so shortcut tips like `Ctrl+,` go missing. This shim rewrites the key names to literal characters. It is the shared library used by the `antigravity`, `cursor`, `obsidian` and `zotero` packages.

### Packaging Details
- Built from the release tarball of [kud3n013/dbusmenu-shortcut-shim](https://github.com/kud3n013/dbusmenu-shortcut-shim).
- Installs `/usr/lib/dbusmenu-shortcut-shim/libdbusmenu-shortcut-shim.so`; it is meant to be loaded through `LD_PRELOAD` by the launcher scripts of the packages above.

---


## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/kud3n013/dbusmenu-shortcut-shim)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
