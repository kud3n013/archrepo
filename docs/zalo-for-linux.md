# Zalo for Linux (`zalo-for-linux`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-26.9.10--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/doandat943/zalo-for-linux)

Zalo messaging client for Linux with Wayland support and patched async calling deadlock fix.

---

## 📥 Installation

```bash
sudo pacman -S zalo-for-linux
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zalo-for-linux` |
| **Current Version** | `26.9.10-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [doandat943/zalo-for-linux](https://github.com/doandat943/zalo-for-linux) |
| **Category** | Core Application |

---

### Overview
Zalo is one of the most widely used messaging applications in Southeast Asia. This package provides the desktop client adapted for Linux.

### Modifications in `archrepo`
- **Call Deadlock Patch (`fix-zcall-async.patch`)**: Resolves upstream voice/video call freezes and deadlocks occurring under modern Linux compositors by ensuring asynchronous handling of call status bridges.
- **Wayland Integration**: Includes flags wrapper for Wayland IME and scaling, plus bundled high-resolution application icons.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zalo-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
# ZCALL_DISABLE=1 # optional: disable call bridge to conserve CPU
```

## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/doandat943/zalo-for-linux)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
