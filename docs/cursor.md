# Cursor (`cursor`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.22.7--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://www.cursor.com)

AI-first code editor built for pair programming with artificial intelligence, packaged from the official Debian x86_64 release with KDE Plasma Global Menu export, DBusMenu punctuation shortcut normalization, GTK3 crash prevention, and native Wayland flags support.

---

## 📥 Installation

```bash
sudo pacman -S cursor
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `cursor` |
| **Current Version** | `3.22.7-2` |
| **Package Type** | **Modified (KDE Global Menu Integration)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Cursor](https://www.cursor.com) |
| **Category** | Development / IDE |

---

### Overview
Cursor is an AI-powered code editor based on VS Code, engineered from the ground up for deep AI integration, intelligent autocomplete, conversational codebase indexing, and multi-file editing.

### Desktop Environment & KDE Global Menu Integration
- **KDE Plasma Global Menu Export**: Patched main process (`patch-globalmenu.js`) to un-gate `shouldDrawMenu` on Linux, cleanly exporting Cursor's native menus (`File`, `Edit`, `Selection`, `View`, `Go`, `Run`, `Terminal`, `Help`) to KDE Plasma's Global Menu widget over D-Bus (`com.canonical.dbusmenu`).
- **No Visual Duplication**: Automatically suppresses the in-window menubar (`autoHideMenuBar: true`) when Global Menu is active, while preserving toggle access via `Alt` or `F10`.
- **DBusMenu Punctuation Normalizer Shim**: Bundles and preloads `libcursor-globalmenu.so` to intercept DBusMenu accelerator exports and convert string names (`"comma"` -> `","`, `"period"` -> `"."`, etc.) so Qt's `QKeySequence` can parse them, restoring `Ctrl+,` (Settings) and punctuation shortcuts in the KDE Global Menu.
- **GTK3 Module Pinning (Crash Prevention)**: Pins all `/usr/lib/gtk-3.0/modules/*.so` via `LD_PRELOAD` under KDE Plasma to prevent `dlclose()` unmapping segfaults (Signal 11 `SEGV_ACCERR`) during dynamic theme switches.
- **Pure Native Wayland on Other Desktops**: On GNOME, Hyprland, and Sway, routes seamlessly via native Wayland (`--ozone-platform-hint=auto` and `--enable-wayland-ime`).
- **Intelligent CLI Routing**: Commands like `cursor --help`, `cursor --version`, and `cursor agent` bypass GUI/Ozone flags to prevent spurious Chromium warnings.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/cursor-flags.conf`

```bash
# Display server backend (Wayland / X11)
# Cursor launcher enables native Wayland automatically when WAYLAND_DISPLAY is present.
# On KDE Plasma, it routes via XWayland to enable Global Menu integration.
--ozone-platform-hint=auto
--enable-wayland-ime

# Optional: High-DPI UI scaling
# --force-device-scale-factor=1.5

# Optional: Password store backend (gnome-libsecret, kwallet5, kwallet6, basic)
# --password-store=basic
```

## 🔗 Related Links

- [Upstream Website](https://www.cursor.com)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
