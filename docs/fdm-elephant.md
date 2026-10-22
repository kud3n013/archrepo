# FDM Elephant Add-on (`fdm-elephant`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.3.9--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://github.com/meowcateatrat/elephant)

Free Download Manager add-on for downloading videos from YouTube, Vimeo, and 1000+ sites powered by yt-dlp.

---

## 📥 Installation

```bash
sudo pacman -S fdm-elephant
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `fdm-elephant` (formerly `freedownloadmanager-elephant`) |
| **Current Version** | `1.3.9-3` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant) |
| **Category** | Plugin / Add-on |

---

### Overview
Elephant is the official open-source video download add-on for Free Download Manager. It harnesses `yt-dlp` to parse and stream online video and audio downloads directly inside FDM.

### Packaging Details
- Pure upstream packaging installed directly to the FDM add-on extension directory.
- Requires [`fdm`](fdm.md) to function.
- Installs that still have `freedownloadmanager-elephant` are moved to `fdm-elephant` by `pacman -Syu`.

---


## 🔗 Related Links

- [Upstream Repository / Website](https://github.com/meowcateatrat/elephant)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
