# Horizon (`horizon-rust`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.2.81--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-GitHub-informational)](https://github.com/horizon-rust/horizon)

Launcher for Horizon, Minecraft: Java Edition rewritten from scratch in Rust, from upstream's prebuilt Linux release.

---

## 📥 Installation

```bash
sudo pacman -S horizon-rust
```

Then start **Horizon** from the applications menu, or run `horizon-launcher`. You need your own copy of Minecraft: Java Edition: Horizon ships no Minecraft files and builds them from the game you own.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `horizon-rust` |
| **Command** | `horizon-launcher` |
| **Current Version** | `0.2.81-1` |
| **Package Type** | **Original (upstream prebuilt binary)** |
| **Build Status** | `passing` |
| **Upstream Project** | [horizon-rust/horizon](https://github.com/horizon-rust/horizon) ([playhorizon.dev](https://playhorizon.dev)) |
| **Category** | Game / Launcher |

---

### Overview
The package takes `horizon-launcher-linux-x86_64.tar.gz` from upstream's `launcher@<version>` GitHub release and installs the binary unmodified at `/usr/lib/horizon-rust/horizon-launcher`. The tarball holds only the binary, so the desktop entries, icons and licenses are downloaded from the repository at the same tag.

The launcher is what is packaged. It signs in, prepares the game files from your Minecraft installation, and installs and updates Horizon's game builds (the Nightlies) in your home directory, as on any other distribution. Those game builds are not pacman packages.

The nightly upstream check lists the repository's `launcher@*` tags with `git ls-remote`. Launcher releases are never marked latest on GitHub, and the older `launcher-v*` tags (up to `launcher-v0.9.0`) are ignored because they sort above the current `0.2.x` series.

### Changes from upstream
- **Wrapper** `/usr/bin/horizon-launcher` sets `HORIZON_LAUNCHER_NO_SELF_UPDATE=1`, so the launcher never tries to replace the binary pacman owns. The launcher also sees that it runs from `/usr` and tells you to update it with your package manager. This matches upstream's Nix package.
- **Menu entry.** The launcher writes its own `~/.local/share/applications/horizon-launcher.desktop` on start. The wrapper sets `HORIZON_LAUNCHER_DESKTOP_EXEC=/usr/bin/horizon-launcher`, so that entry starts the wrapper. Removing the package deletes those per-user entries when they point at this package.
- Upstream's `horizon-launcher.desktop`, `horizon.desktop` (hidden; the game window's icon on Wayland) and hicolor icons are installed system-wide.

### Dependencies
The binary links `libxcb` and `libxkbcommon`, and loads Vulkan, Wayland and EGL at run time. The game builds the launcher installs also load ALSA, udev and X11 libraries, so those are dependencies too. A Vulkan driver (`vulkan-radeon`, `vulkan-intel`, `nvidia-utils`, ...) is needed to play. `gamemode`, `base-devel` (native mods) and `libxtst` (Mojang's Java runtime) are optional.

---

## 🔗 Related Links

- [Horizon](https://playhorizon.dev) · [Install guide](https://playhorizon.dev/docs/install)
- [Upstream repository](https://github.com/horizon-rust/horizon)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
