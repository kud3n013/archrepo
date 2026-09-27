# Zed (`zed`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://zed.dev)

High-performance, multiplayer code editor written in Rust with native Wayland GPUI hardware acceleration.

---

## 📥 Installation

```bash
sudo pacman -S zed
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `zed` |
| **Current Version** | `1.21.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [Zed Industries](https://zed.dev) |
| **Category** | Core Application |

---

### Overview
Zed is a lightning-fast code editor engineered by the creators of Atom and Tree-sitter. It leverages Rust and Vulkan GPUI for instant startup and silky 120 FPS rendering.

### Packaging Details
- Upstream pre-compiled binary release packaged with launcher wrapper.
- Supports system and user flags in `~/.config/zed-flags.conf`.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/zed-flags.conf`

```bash
# Custom Zed flags
# --foreground
# --wait
```

## 🔗 Related Links

- [Upstream Repository / Website](https://zed.dev)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
