# VectorCraft (`vectorcraft`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.15.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/vectorcraft)

VectorCraft, an open-source vector illustration editor (Illustrator alternative) from ArtCraft's Craft App Suite. Native Rust (egui and wgpu), no Electron or web view.

---

## 📥 Installation

```bash
sudo pacman -S vectorcraft
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `vectorcraft` |
| **Commands** | `vectorcraft`, `vectorcraft-cli` |
| **Current Version** | `0.15.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [storytold/vectorcraft](https://github.com/storytold/vectorcraft) ([getartcraft.com](https://getartcraft.com/apps/vectorcraft)) |
| **License** | MIT OR Apache-2.0 (bundled fonts OFL-1.1) |
| **Category** | Graphics |

---

### Overview
Repackages upstream's Linux release tarball unmodified. VectorCraft already uses the desktop's title bar on KDE, so nothing is patched.

### Desktop integration

| Check | Result |
|---|---|
| **Title bar** | Uses the desktop's frame. The Craft apps only draw their own title bar where the compositor leaves decorations to the app (GNOME on Wayland); KDE, Sway, Hyprland and X11 keep the system one. |
| **Global menu** | Not available. The menus are drawn inside the window; upstream exports a native menu bar only on macOS. Neither DBusMenu nor `dbusmenu-shortcut-shim` can reach it, so KDE's Global Menu needs a Linux backend upstream. |
| **Light/dark theme** | No follow-the-system option: VectorCraft has fixed themes only. Pick one in the app. Needs an upstream change. |

### Packaging Details
- **Source**: `vectorcraft-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/vectorcraft/releases), the same FHS tree (`bin/`, `share/`) upstream's own deb, rpm and AppImage are built from.
- **Dependencies**: the binaries link only glibc and libgcc; Wayland, X11, Vulkan/EGL and D-Bus are loaded at run time, so the PKGBUILD lists them explicitly. Without a Vulkan driver the app falls back to OpenGL or CPU rendering.
- **Updates**: the daily check follows the latest GitHub release of `storytold/vectorcraft`.
- **Replaces** the AUR package `vectorcraft-bin` and conflicts with `vectorcraft-git`. The AUR's source-built `vectorcraft` has the same name, so only one of the two can be installed.

### Notes
- Every Craft App can also be installed by ArtCraft's own launcher (`artcraft-launcher`). Don't mix the two: pacman owns this copy and its updates.
- The apps are early releases and change quickly. Upstream bugs go to [storytold/vectorcraft](https://github.com/storytold/vectorcraft/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/vectorcraft)
- [ArtCraft app page](https://getartcraft.com/apps/vectorcraft)
- AUR: [`vectorcraft-bin`](https://aur.archlinux.org/packages/vectorcraft-bin), [`vectorcraft`](https://aur.archlinux.org/packages/vectorcraft), [`vectorcraft-git`](https://aur.archlinux.org/packages/vectorcraft-git)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
