# Craft Anything (`craft-anything`)

[![build](https://img.shields.io/badge/build-pending-lightgrey)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.3.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/storytold/craft-anything)

Craft Anything, from ArtCraft's Craft App Suite: point it at a website, app or game, say what you want, and it studies the original with real inspection tools, has a coding agent build your own version, then checks the result against the original and refines it. Native Rust (egui and wgpu), no Electron or web view. A CLI and an MCP server expose the same 300+ engine tools.

---

## 📥 Installation

```bash
sudo pacman -S craft-anything
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `craft-anything` |
| **Commands** | `craft-anything`, `craft-anything-cli` |
| **Current Version** | `0.3.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `pending` |
| **Upstream Project** | [storytold/craft-anything](https://github.com/storytold/craft-anything) ([getartcraft.com](https://getartcraft.com/apps/craft-anything)) |
| **License** | MIT OR Apache-2.0 (bundled fonts OFL-1.1) |
| **Category** | Development |

---

### Overview
Repackages upstream's Linux release tarball unmodified. Upstream calls the app early alpha.

### Desktop integration

| Check | Result |
|---|---|
| **Title bar** | Always draws its own title bar: the window is created without decorations on every desktop, KDE included. Unlike PhotoCraft there is no setting for the system frame, so a launcher can't turn it on. Needs an upstream change. |
| **Global menu** | Not available. The menus are drawn inside the window, so neither DBusMenu nor `dbusmenu-shortcut-shim` can reach them. |
| **Light/dark theme** | Doesn't follow the desktop. The app has two themes, Studio (dark, the default) and Studio Light, picked in its own settings; there is no "system" option to follow the portal. |

### Packaging Details
- **Source**: `craft-anything-<version>-linux-x86_64.tar.gz` from the [GitHub release](https://github.com/storytold/craft-anything/releases), the same FHS tree (`bin/`, `share/`) upstream's own deb, rpm and AppImage are built from.
- **Dependencies**: the binaries link only glibc and libgcc; Wayland, X11, Vulkan/EGL and D-Bus are loaded at run time, so the PKGBUILD lists them explicitly. Without a Vulkan driver the app falls back to OpenGL or CPU rendering.
- **Optional tools**: Craft Anything runs programs you already have rather than bundling them. Building needs a coding agent: Claude Code is the one upstream supports first (`claude-code` from the AUR, or Anthropic's installer). Codex (`openai-codex`), Gemini CLI (`gemini-cli`) and opencode (`opencode`) also work. Studying a website needs a Chromium-based browser (Chromium, Chrome, Edge or Brave). Deep mode uses Ghidra's decompiler when `ghidra` is installed. `android-tools` (adb) lets it study apps on a connected phone, and `jadx` decompiles Android apps.
- **Updates**: the daily check follows the latest GitHub release of `storytold/craft-anything`.
- **Replaces** the AUR package `craft-anything-bin` and conflicts with `craft-anything-git`.

### Notes
- Every Craft App can also be installed by ArtCraft's own launcher (`artcraft-launcher`). Don't mix the two: pacman owns this copy and its updates.
- Clean room mode (the default) only uses tools that don't touch the target's code; Deep mode (Settings, or `--deep` on the CLI) uses all of them.
- The app is an early release and changes quickly. Upstream bugs go to [storytold/craft-anything](https://github.com/storytold/craft-anything/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/storytold/craft-anything)
- [ArtCraft app page](https://getartcraft.com/apps/craft-anything)
- AUR: [`craft-anything-bin`](https://aur.archlinux.org/packages/craft-anything-bin)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
