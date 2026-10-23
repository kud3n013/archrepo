# LightCraft (`lightcraft`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.12.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/lightcraft)

LightCraft, an open-source photo library and raw developer (Lightroom alternative) from ArtCraft's Craft App Suite. Native Rust (egui and wgpu), no Electron or web view.

---

## 📥 Installation

```bash
sudo pacman -S lightcraft
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `lightcraft` |
| **Commands** | `lightcraft`, `lightcraft-cli` |
| **Current Version** | `0.12.0-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [storytold/lightcraft](https://github.com/storytold/lightcraft) ([getartcraft.com](https://getartcraft.com/apps/lightcraft)) |
| **License** | MIT OR Apache-2.0 (bundled fonts OFL-1.1) |
| **Category** | Graphics |

---

### Overview
Repackages upstream's Linux release tarball unmodified, plus a small launcher that sets LightCraft's own preferences once so it fits a KDE Plasma desktop.

### Desktop integration

| Check | Result |
|---|---|
| **Title bar** | Uses the desktop's frame. The Craft apps only draw their own title bar where the compositor leaves decorations to the app (GNOME on Wayland); KDE, Sway, Hyprland and X11 keep the system one. |
| **Global menu** | Not available. The menus are drawn inside the window; upstream exports a native menu bar only on macOS. Neither DBusMenu nor `dbusmenu-shortcut-shim` can reach it, so KDE's Global Menu needs a Linux backend upstream. |
| **Light/dark theme** | Follows the desktop's light/dark setting live, through the XDG portal's `org.freedesktop.appearance` `color-scheme`. Upstream starts in a fixed theme; the launcher switches LightCraft to Settings › Interface › Appearance set to Auto once. |

### Packaging Details
- **Source**: `lightcraft-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/lightcraft/releases), the same FHS tree (`bin/`, `share/`) upstream's own deb, rpm and AppImage are built from.
- **Dependencies**: the binaries link only glibc and libgcc; Wayland, X11, Vulkan/EGL and D-Bus are loaded at run time, so the PKGBUILD lists them explicitly. Without a Vulkan driver the app falls back to OpenGL or CPU rendering.
- **Layout**: the app binary lives in `/usr/lib/lightcraft/bin/` with a `share` link back to `/usr/share`, so its exe-relative lookups still work. `/usr/bin/lightcraft` is the launcher; `/usr/bin/lightcraft-cli` is upstream's CLI as is.
- **First-run defaults**: the launcher sets Settings › Interface › Appearance set to Auto in `${LIGHTCRAFT_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/lightcraft}/ui.json`, then writes `~/.local/state/archrepo/lightcraft-defaults` and never touches the file again. An existing settings file is merged with `jq`, keeping everything else. Set `LIGHTCRAFT_ARCHREPO_DEFAULTS=0` to skip it.
- **Updates**: the daily check follows the latest GitHub release of `storytold/lightcraft`.
- **Replaces** the AUR package `lightcraft-bin` and conflicts with `lightcraft-git`. The AUR's source-built `lightcraft` has the same name, so only one of the two can be installed.

### Notes
- Every Craft App can also be installed by ArtCraft's own launcher (`artcraft-launcher`). Don't mix the two: pacman owns this copy and its updates.
- The apps are early releases and change quickly. Upstream bugs go to [storytold/lightcraft](https://github.com/storytold/lightcraft/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/lightcraft)
- [ArtCraft app page](https://getartcraft.com/apps/lightcraft)
- AUR: [`lightcraft-bin`](https://aur.archlinux.org/packages/lightcraft-bin), [`lightcraft`](https://aur.archlinux.org/packages/lightcraft), [`lightcraft-git`](https://aur.archlinux.org/packages/lightcraft-git)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
