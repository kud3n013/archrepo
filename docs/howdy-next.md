# Howdy Next (`howdy-next`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.4.1--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://codeberg.org/nathawat/howdy-next)

Fast C++ rewrite of Howdy facial-recognition authentication for Linux PAM (patched to eliminate OpenCV 5 DNN warning spam).

---

## 📥 Installation

```bash
sudo pacman -S howdy-next
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `howdy-next` |
| **Current Version** | `3.4.1-3` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [nathawat/howdy-next](https://codeberg.org/nathawat/howdy-next) |
| **Category** | Core Application |

---

### Overview
Howdy Next brings Windows Hello-style infrared facial recognition to Linux, written in native C++ for rapid authentication speeds during `sudo`, lockscreen unlock, and Polkit prompts.

### Modifications in `archrepo`
- **OpenCV DNN Warning Suppression Patch (`0001-fix-opencv-suppress-noisy-dnn-warnings.patch`)**: Upstream Howdy-Next produces persistent `[WARN:0@...] ... dnn ...` log spam on modern OpenCV 5 libraries whenever an authentication prompt is triggered. This patch suppresses irrelevant internal OpenCV debugging messages, keeping terminal output and PAM prompts clean.
- Includes pre-configured Polkit agent helper configuration.

---

## ⚙️ Configuration & Flags

Configuration file: `/etc/howdy/config.ini`

```bash
# Edit /etc/howdy/config.ini to configure your IR camera device
# Example: device_path = /dev/v4l/by-path/...
```

## 🔗 Related Links

- [Upstream Repository / Website](https://codeberg.org/nathawat/howdy-next)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
