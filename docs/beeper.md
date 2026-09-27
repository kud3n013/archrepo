# Beeper (`beeper`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-4.3.152--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.beeper.com/changelog)

Unified messaging client integrating WhatsApp, Telegram, Signal, Matrix, and more into a single desktop application.

---

## 📥 Installation

```bash
sudo pacman -S beeper
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `beeper` |
| **Current Version** | `4.3.152-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Automattic / Beeper](https://www.beeper.com/changelog) |
| **Category** | Core Application |

---

### Overview
Beeper is a universal chat app bringing your conversations together across numerous messaging networks.

### Modifications in `archrepo`
- **Asar Theme Synchronization Patch**: Patches `app.asar` (`linuxConfig.js`) to prevent conflict with system configurations and synchronize light/dark theme with the Freedesktop XDG Desktop Portal.
- **Wayland Auto-Hinting**: The launcher wrapper auto-detects Wayland and passes `--ozone-platform-hint=auto` and `--enable-wayland-ime`.
- **Clean Desktop Integration**: Disables AppImage runtime desktop integration (`DESKTOPINTEGRATION=0`) and removes user-level duplicate `.desktop` entries during installation and launch.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/beeper-flags.conf`

```bash
--ozone-platform-hint=auto
--enable-wayland-ime
# --force-device-scale-factor=1.5
```

## 🔗 Related Links

- [Upstream Repository / Website](https://www.beeper.com/changelog)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
