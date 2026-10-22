# Free Download Manager (`fdm`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-6.34.4.6974--5-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.freedownloadmanager.org/)

Fast and powerful modern download accelerator, BitTorrent client, and organizer built on Qt6.

---

## 📥 Installation

```bash
sudo pacman -S archrepo/fdm
```

> [!NOTE]
> This package was called `freedownloadmanager` until 6.34.4.6974-5. `pacman -Syu` replaces the old package with `fdm` (and `freedownloadmanager-elephant` with `fdm-elephant`); settings and downloads are kept.
>
> Arch's `extra` repository has an unrelated `fdm` (a mail fetcher). Use the `archrepo/` prefix when installing, and keep `[archrepo]` above `[extra]` in `/etc/pacman.conf` (`kast repo` puts it there), or pacman will update `fdm` from `extra` instead.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `fdm` (formerly `freedownloadmanager`) |
| **Current Version** | `6.34.4.6974-5` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Free Download Manager](https://www.freedownloadmanager.org/) |
| **Category** | Core Application |

---

### Overview
Free Download Manager (FDM) is an all-in-one download manager supporting HTTP, HTTPS, FTP, and BitTorrent protocols with multi-threaded acceleration.

### Modifications in `archrepo`
- **Dynamic Dark Mode & Theme Detection (`fdm-theme-fix.c`)**: Upstream FDM bundles Qt6 libraries that default to a blinding white light theme even when the system dark mode is active. This package compiles a lightweight shared library (`libfdm-theme-fix.so`) and injects it into the executable using `patchelf --add-needed`, ensuring `QT_QPA_PLATFORMTHEME=xdgdesktopportal` automatically follows system dark/light preference across modern Wayland and X11 desktops.
- **KDE Plasma Global Menu (`fdm-globalmenu.cpp`, `GlobalMenuBar.qml`)**: FDM ships a native menu bar but only uses it on macOS. `libfdm-globalmenu.so` is added to the binary the same way as the theme fix; once the main window exists it loads `/usr/share/fdm/GlobalMenuBar.qml` into the window's QML context, and FDM's bundled Qt exports it to the Global Menu on both X11 and Wayland. The menu mirrors the in-app main menu and toolbar:
  - **File**: add a download, paste URLs from the clipboard or a file, export/import downloads, connect to a remote FDM, quit
  - **Downloads**: start/pause all, start/pause/restart selected, move, remove from list, delete, select all
  - **Settings**: preferences, add-ons, export/import settings, auto shutdown (sleep / shutdown)
  - **Help**: contact support, submit a bug report, about

  Labels come from FDM's own translations. Menu items carry no shortcuts, because a native menu shortcut would collide with FDM's own Ctrl+N / Ctrl+V / Ctrl+A. Set `FDM_GLOBALMENU=0` to turn the menu off, or `FDM_GLOBALMENU_QML=/path/to/menu.qml` to load your own.
- **Wayland Platform Selection**: The wrapper allows switching between `wayland` and `xcb` seamlessly.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/freedownloadmanager-flags.conf`

```bash
# Desktop portal dark theme detection
QT_QPA_PLATFORMTHEME=xdgdesktopportal

# Backend selection: auto, wayland, or xcb
# QT_QPA_PLATFORM=wayland;xcb

# Turn off the Global Menu export
# FDM_GLOBALMENU=0
```

## 🔗 Related Links

- [Upstream Repository / Website](https://www.freedownloadmanager.org/)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
