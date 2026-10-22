# PhotoCraft (`photocraft`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.13.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/photocraft)

PhotoCraft, an open-source layered image and photo editor (Photoshop alternative) from ArtCraft's Craft App Suite. Native Rust (egui and wgpu), no Electron or web view.

---

## 📥 Installation

```bash
sudo pacman -S photocraft
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `photocraft` |
| **Commands** | `photocraft`, `photocraft-cli` |
| **Current Version** | `0.13.0-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [storytold/photocraft](https://github.com/storytold/photocraft) ([getartcraft.com](https://getartcraft.com/apps/photocraft)) |
| **License** | MIT OR Apache-2.0 (bundled fonts OFL-1.1) |
| **Category** | Graphics |

---

### Overview
Repackages upstream's Linux release tarball unmodified, plus a small launcher that sets PhotoCraft's own preferences once so it fits a KDE Plasma desktop.

### Desktop integration

| Check | Result |
|---|---|
| **Title bar** | Upstream draws its own one-row title bar on Linux. The launcher turns on Preferences › Interface › System Title Bar once, so KWin draws the frame. Turning it off again in Preferences brings PhotoCraft's own bar back on the next start. |
| **Global menu** | Not available. The menus are drawn inside the window; upstream exports a native menu bar only on macOS. Neither DBusMenu nor `dbusmenu-shortcut-shim` can reach it, so KDE's Global Menu needs a Linux backend upstream. |
| **Light/dark theme** | Follows the desktop's light/dark setting live, through the XDG portal's `org.freedesktop.appearance` `color-scheme`. Upstream starts in a fixed theme; the launcher switches PhotoCraft to Appearance › Auto once. |

### Packaging Details
- **Source**: `photocraft-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/photocraft/releases), the same FHS tree (`bin/`, `share/`) upstream's own deb, rpm and AppImage are built from.
- **Dependencies**: the binaries link only glibc and libgcc; Wayland, X11, Vulkan/EGL and D-Bus are loaded at run time, so the PKGBUILD lists them explicitly. Without a Vulkan driver the app falls back to OpenGL or CPU rendering.
- **Layout**: the app binary lives in `/usr/lib/photocraft/bin/` with a `share` link back to `/usr/share`, so its exe-relative lookups still work. `/usr/bin/photocraft` is the launcher; `/usr/bin/photocraft-cli` is upstream's CLI as is.
- **First-run defaults**: the launcher sets Preferences › Interface › System Title Bar on, and Appearance set to Auto in `${XDG_CONFIG_HOME:-$HOME/.config}/photocraft/preferences.json`, then writes `~/.local/state/archrepo/photocraft-defaults` and never touches the file again. An existing settings file is merged with `jq`, keeping everything else. Set `PHOTOCRAFT_ARCHREPO_DEFAULTS=0` to skip it.
- **Updates**: the daily check follows the latest GitHub release of `storytold/photocraft`.
- **Replaces** the AUR package `photocraft-bin` and conflicts with `photocraft-git`. The AUR's source-built `photocraft` has the same name, so only one of the two can be installed.

### Notes
- Every Craft App can also be installed by ArtCraft's own launcher (`artcraft-launcher`). Don't mix the two: pacman owns this copy and its updates.
- The apps are early releases and change quickly. Upstream bugs go to [storytold/photocraft](https://github.com/storytold/photocraft/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/photocraft)
- [ArtCraft app page](https://getartcraft.com/apps/photocraft)
- AUR: [`photocraft-bin`](https://aur.archlinux.org/packages/photocraft-bin), [`photocraft`](https://aur.archlinux.org/packages/photocraft), [`photocraft-git`](https://aur.archlinux.org/packages/photocraft-git)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
