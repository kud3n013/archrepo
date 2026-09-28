# Krohnkite KWin Script (`kwin-scripts-krohnkite`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.9.9.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-codeberg-informational)](https://codeberg.org/anametologin/krohnkite)

A dynamic tiling extension for KWin (KDE Plasma 6) ported from the original Krohnkite script.

---

## 📥 Installation

```bash
sudo pacman -S kwin-scripts-krohnkite
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `kwin-scripts-krohnkite` |
| **Current Version** | `0.9.9.2-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [anametologin/krohnkite](https://codeberg.org/anametologin/krohnkite) |
| **Original Author** | [esjeon/krohnkite](https://github.com/esjeon/krohnkite) |
| **Category** | Plugin / Add-on (KWin Script) |

---

### Overview
Krohnkite is a dynamic window tiling script for KWin (similar to dwm, xmonad, or bspwm) that automates window placement in KDE Plasma. This package tracks the actively maintained KDE Plasma 6 fork by anametologin on Codeberg.

### Enabling the Script

#### Via Graphical Interface
1. Open **System Settings**.
2. Navigate to **Window Management** &rarr; **KWin Scripts**.
3. Check **Krohnkite** and click **Apply**.

#### Via Command Line
```bash
# Enable the plugin
kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true

# Reload KWin configuration
qdbus6 org.kde.KWin /KWin reconfigure
```

---

### Common Shortcuts

| Key Combination | Action |
|---|---|
| <kbd>Meta</kbd> + <kbd>J</kbd> / <kbd>K</kbd> / <kbd>H</kbd> / <kbd>L</kbd> | Focus Down / Up / Left / Right |
| <kbd>Meta</kbd> + <kbd>Shift</kbd> + <kbd>J</kbd> / <kbd>K</kbd> / <kbd>H</kbd> / <kbd>L</kbd> | Move Down / Up / Left / Right |
| <kbd>Meta</kbd> + <kbd>Return</kbd> | Set Active Window as Master |
| <kbd>Meta</kbd> + <kbd>F</kbd> | Toggle Floating Mode |
| <kbd>Meta</kbd> + <kbd>\</kbd> | Cycle Next Layout |
| <kbd>Meta</kbd> + <kbd>T</kbd> / <kbd>M</kbd> | Switch to Tile / Monocle Layout |

---

### Packaging Details
- Installs system-wide into `/usr/share/kwin/scripts/krohnkite/`.
- Directly packages the pre-built `.kwinscript` release artifact from Codeberg releases, completely avoiding build-time TypeScript compiler mismatches.
- Includes a clean post-installation scriptlet providing enablement and reconfiguration instructions.

---

## 🔗 Related Links

- [Upstream Repository (Codeberg)](https://codeberg.org/anametologin/krohnkite)
- [Original Krohnkite Repository (GitHub)](https://github.com/esjeon/krohnkite)
- [AUR Package](https://aur.archlinux.org/packages/kwin-scripts-krohnkite)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
