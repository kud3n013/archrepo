# SoundCraft (`soundcraft`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.12.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/soundcraft)

SoundCraft, an open-source digital audio workstation (Pro Tools alternative) from ArtCraft's Craft App Suite. Native Rust (egui and wgpu), no Electron or web view.

---

## 📥 Installation

```bash
sudo pacman -S soundcraft
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `soundcraft` |
| **Commands** | `soundcraft`, `soundcraft-cli` |
| **Current Version** | `0.12.1-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [storytold/soundcraft](https://github.com/storytold/soundcraft) ([getartcraft.com](https://getartcraft.com/apps/soundcraft)) |
| **License** | MIT OR Apache-2.0 |
| **Category** | Audio & Video |

---

### Overview
Repackages upstream's Linux release tarball unmodified. SoundCraft already uses the desktop's title bar on KDE, so nothing is patched.

### Desktop integration

| Check | Result |
|---|---|
| **Title bar** | Uses the desktop's frame. The Craft apps only draw their own title bar where the compositor leaves decorations to the app (GNOME on Wayland); KDE, Sway, Hyprland and X11 keep the system one. |
| **Global menu** | Not available. The menus are drawn inside the window; upstream exports a native menu bar only on macOS. Neither DBusMenu nor `dbusmenu-shortcut-shim` can reach it, so KDE's Global Menu needs a Linux backend upstream. |
| **Light/dark theme** | Has a "system" theme option, but it asks winit, which reports no theme on Linux, so it never changes. Pick Light or Dark in the app. Needs an upstream fix (read the portal, as PhotoCraft does). |

### Packaging Details
- **Source**: `soundcraft-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/soundcraft/releases), the same FHS tree (`bin/`, `share/`) upstream's own deb, rpm and AppImage are built from.
- **Dependencies**: the binaries link only glibc and libgcc and alsa-lib; Wayland, X11, Vulkan/EGL and D-Bus are loaded at run time, so the PKGBUILD lists them explicitly. Without a Vulkan driver the app falls back to OpenGL or CPU rendering.
- **Updates**: the daily check follows the latest GitHub release of `storytold/soundcraft`.
- **Replaces** the AUR package `soundcraft-bin` and conflicts with `soundcraft-git`. The AUR's source-built `soundcraft` has the same name, so only one of the two can be installed.

### Notes
- Every Craft App can also be installed by ArtCraft's own launcher (`artcraft-launcher`). Don't mix the two: pacman owns this copy and its updates.
- The apps are early releases and change quickly. Upstream bugs go to [storytold/soundcraft](https://github.com/storytold/soundcraft/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/soundcraft)
- [ArtCraft app page](https://getartcraft.com/apps/soundcraft)
- AUR: [`soundcraft-bin`](https://aur.archlinux.org/packages/soundcraft-bin), [`soundcraft`](https://aur.archlinux.org/packages/soundcraft), [`soundcraft-git`](https://aur.archlinux.org/packages/soundcraft-git)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
