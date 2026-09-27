# GDLauncher Carbon (`gdlauncher-carbon`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.0.40--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://gdlauncher.com)

GDLauncher Carbon — a powerful, modern Minecraft custom launcher with CurseForge, Modrinth, and FTB integration.

---

## 📥 Installation

```bash
sudo pacman -S gdlauncher-carbon
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `gdlauncher-carbon` |
| **Current Version** | `2.0.40-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [GDLauncher](https://gdlauncher.com) |
| **Category** | Core Application |

---

### Overview
GDLauncher Carbon is a next-generation Minecraft launcher designed with an emphasis on performance, modpack management, and an intuitive user interface.

### Packaging Details
- Repackaged from official upstream AppImage to run without requiring `fuse2`.
- Custom launcher wrapper provides Wayland auto-hinting (`--ozone-platform-hint=auto`) and flags configuration.
- Post-install scriptlet prevents rogue user desktop files.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/gdlauncher-carbon-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
```

## 🔗 Related Links

- [Upstream Repository / Website](https://gdlauncher.com)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
