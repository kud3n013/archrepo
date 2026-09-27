# Sine (`sine`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.3.3--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/CosmoCreeper/Sine)

The ultimate mod, theme, and CSS manager for Firefox-based browsers (Zen, Floorp, LibreWolf, Firefox).

---

## 📥 Installation

```bash
sudo pacman -S sine
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `sine` |
| **Current Version** | `2.3.3-2` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine) |
| **Category** | Core Application |

---

### Overview
Sine is a dedicated customization manager for Firefox and modern Firefox forks (especially Zen Browser and Floorp), enabling one-click discovery and installation of userChrome themes and extensions.

### Packaging Details
- Pure upstream binary packaging installed into `/opt/sine/`.
- Includes launcher wrapper supporting Wayland flags and user configuration.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/sine-flags.conf`

```bash
--ozone-platform-hint=auto
```

## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/CosmoCreeper/Sine)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
