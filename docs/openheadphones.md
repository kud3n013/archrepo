# OpenHeadphones (`openheadphones`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.3.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/edsuuu/OpenHeadphones)

Unofficial open-source tray app for JBL earbuds and headphones: battery, noise cancelling (ANC), ambient sound, equalizer with JBL's presets, touch gestures, find my buds and device settings, without the phone app. Not affiliated with JBL or Harman.

---

## 📥 Installation

```bash
sudo pacman -S openheadphones
sudo systemctl enable --now bluetooth.service
```

Start it from the app launcher (**OpenHeadphones**) or with `jbl-headphones` / `openheadphones`. It lives in the system tray; the launcher entry passes `--open` so the panel shows right away.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `openheadphones` |
| **Current Version** | `0.3.1-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [edsuuu/OpenHeadphones](https://github.com/edsuuu/OpenHeadphones) |
| **License** | MIT (product photos in `devices/` belong to Harman International) |
| **Category** | Core Application |

---

### Overview
Repackages upstream's prebuilt `jbl-headphones-linux-x64.tar.gz` release (a Rust binary plus its `devices/` model profiles and `locales/`). The program sits in `/usr/lib/openheadphones/` next to its data, which it finds through its real path, and `/usr/bin/jbl-headphones` and `/usr/bin/openheadphones` link to it. Profiles for 44 JBL models are included; the JBL Tune Flex 2 is the one upstream tests end to end.

### Modifications in `archrepo`
- **Font path fix**: upstream only looks for its UI font in Debian/Ubuntu paths (`/usr/share/fonts/truetype/{ubuntu,dejavu}/`) and panics with "No system font found" on Arch. `prepare()` rewrites the DejaVu directory in the binary to the same-length `/usr/lib/openheadphones/fonts/dj/`, which holds links to `ttf-dejavu`'s files in `/usr/share/fonts/TTF/`. The build fails if the upstream binary stops containing the expected path.
- **Desktop integration**: desktop entry and the upstream SVG logo as the `openheadphones` hicolor icon; the install scriptlet removes stale per-user copies of the desktop entry.

### Packaging Details
- **Dependencies**: `dbus` and `libgcc` (linked), the X11/xkbcommon/Wayland libraries `winit` loads at runtime, `bluez` for the Bluetooth link and `ttf-dejavu` for the UI font.
- **Optional dependencies**: `gnome-shell-extension-appindicator` to show the tray icon on GNOME; `curl` for the new-release notice.
- **Updates**: the built-in updater cannot write to `/usr/lib`, so it only reports new upstream versions; pacman installs them. The daily check follows the latest upstream GitHub release.
- **Conflicts / provides** `jbl-headphones`, the name of upstream's `.deb` package and binary.

---

## 🔗 Related Links

- [Upstream Repository](https://github.com/edsuuu/OpenHeadphones)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
