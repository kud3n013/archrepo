# Triggers Client (`triggers-client`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-4.7.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://saominecraft.com/us)

Official launcher for the Triggers Minecraft server by Triggers Studio: it installs and updates the game instances, signs in with a Microsoft account and starts the game. Repackaged from upstream's Debian package.

---

## 📥 Installation

```bash
sudo pacman -S triggers-client
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `triggers-client` |
| **Current Version** | `4.7.0-1` |
| **Package Type** | **Modified (repackaged upstream .deb, in-app updater disabled)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Triggers](https://saominecraft.com/us) ([releases](https://github.com/SAOFR-DEV/Triggers-Client-Releases)) |
| **Category** | Game Launcher |

---

### Overview
The package takes `Triggers.Client_<version>_amd64.deb` from [SAOFR-DEV/Triggers-Client-Releases](https://github.com/SAOFR-DEV/Triggers-Client-Releases). Triggers Client is a Tauri 2 app that uses the system WebKitGTK, so the 10 MB `.deb` is repackaged rather than the 99 MB AppImage, which bundles its own WebKitGTK and GTK. The binary goes to `/opt/triggers-client`. The launcher downloads the Java runtime it needs by itself, so no `jre` package is required.

### Changes from the upstream `.deb`
- **In-app updater disabled.** The Tauri bundler stamps the binary with the format it shipped in, and for a `.deb` the updater installs updates with `pkexec dpkg -i`, which would put files on the system that pacman does not track. `prepare()` changes that stamp to "unknown" (3 bytes). The updater then tries to replace its own binary, which fails because `/opt` is owned by root, so updates come only from pacman. The app's own auto-update setting can be turned off to skip the attempt.
- **Launcher** `/usr/bin/triggers-client` replaces upstream's binary there and reads the flags file.
- **Desktop entry** `triggers-client.desktop` is this repository's file: upstream's is named `Triggers Client.desktop` and has no category. This one is filed under Games.
- **Icons.** Upstream's 32, 128 and 256 px icons go into the hicolor theme. Upstream ships the 256 px one in a `256x256@2` directory, which is installed as `256x256`.

### Upstream check
The nightly check (`triggers-client-release`) lists the GitHub releases and takes the newest `vX.Y.Z` tag that has the x86_64 `.deb`. Upstream publishes staging builds (`v4.6.1-staging`) as ordinary releases, so `/releases/latest` alone could pick one up.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/triggers-client-flags.conf` (falls back to `/etc/triggers-client-flags.conf`). Triggers Client is not an Electron app, so Chromium switches such as `--ozone-platform` do nothing. `KEY=VALUE` lines are exported as environment variables; any other line is passed to the app as an argument.

```bash
# Blank or flickering window, mostly on NVIDIA under Wayland
# WEBKIT_DISABLE_DMABUF_RENDERER=1

# Run through XWayland instead of native Wayland
# GDK_BACKEND=x11
```

## 🔗 Related Links

- [Upstream Website](https://saominecraft.com/us)
- [Upstream Releases](https://github.com/SAOFR-DEV/Triggers-Client-Releases/releases)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
