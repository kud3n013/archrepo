# Proton Pass Desktop (`proton-pass`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.41.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/pass)

Official desktop client for Proton Pass password and identity manager, patched for responsive layout and unconstrained resizing.

---

## 📥 Installation

```bash
sudo pacman -S proton-pass
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `proton-pass` |
| **Current Version** | `1.41.1-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Pass](https://proton.me/pass) |
| **Category** | Core Application |

---

### Overview
Proton Pass is an end-to-end encrypted password and identity manager protecting your logins, credit cards, notes, and aliases.

### Modifications in `archrepo`
- **Responsive Layout & Resizing Patch (`patch-pass.js`)**: Upstream Electron builds enforce restrictive minimum window boundaries. This patch removes artificial window bounds and enables responsive item view collapsing, allowing Proton Pass to fit neatly in compact sidebars and split-tiled layouts under Wayland compositors.
- **Wayland Auto-Hinting**: Launcher wrapper automatically passes Wayland flags.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/proton-pass-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
```

## 🔗 Related Links

- [Upstream Repository / Website](https://proton.me/pass)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
