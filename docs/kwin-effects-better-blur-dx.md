# Better Blur DX KWin Effect (`kwin-effects-better-blur-dx`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.6.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/xarblu/kwin-effects-better-blur-dx)

A fork of KWin's Blur effect for KDE Plasma 6 with force blur, refraction, rounded corners and more, built from source and rebuilt automatically for every new Arch `kwin`.

---

## 📥 Installation

```bash
sudo pacman -S kwin-effects-better-blur-dx
```

Log out and back in afterwards so KWin loads the effect.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `kwin-effects-better-blur-dx` |
| **Current Version** | `2.6.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [xarblu/kwin-effects-better-blur-dx](https://github.com/xarblu/kwin-effects-better-blur-dx) |
| **Category** | Plugin / Add-on (KWin Effect) |
| **Built Against** | Arch `kwin` `6.8.0-1` (tracked by `_kwinver` in the PKGBUILD) |

---

### Overview
Better Blur DX replaces the stock Blur desktop effect (Wayland session) and adds window-class force blur, refraction, rounded-corner masking and blur cache options. This package builds the Wayland variant only.

### Enabling the Effect
1. Open **System Settings** &rarr; **Window Management** &rarr; **Desktop Effects**.
2. Disable the stock **Blur** effect (and any other blur fork).
3. Enable **Better Blur DX** and click **Apply**.

---

### Automatic KWin Rebuilds
The effect is a compiled plugin that links against KWin's **private** C++ API, which has no stable ABI. It only works with the exact KWin build it was compiled for, so every new Arch `kwin` (including a pkgrel-only rebuild) needs a matching rebuild of this package.

- **Watcher**: the [`kwin-watch`](../.github/workflows/kwin-watch.yml) workflow polls Arch's `extra` database every 30 minutes. When `kwin` differs from the `_kwinver` recorded in the PKGBUILD, it dispatches a build of this package only.
- **Rebuild**: the build bumps `pkgrel`, rewrites `_kwinver`, builds against the new `kwin` and publishes the signed package through the usual `bump/kwin-effects-better-blur-dx` pull request. Details are in [`upstream.json`](../packages/kwin-effects-better-blur-dx/upstream.json) (`rebuild_on: kwin`).
- **No version pin**: the package depends on plain `kwin`, so `pacman -Syu` is never blocked while a rebuild is pending.
- **Remaining window**: between Arch shipping a new `kwin` and the rebuilt package appearing (watcher poll plus build time, usually under an hour) the installed effect does not match your `kwin`. KWin may then fail to load it or misbehave until you update and log back in; disable the effect if the desktop acts up. A rebuild is also held back if a build for that `kwin` already failed (for example because upstream does not support a new Plasma minor release yet); it is retried every few hours.
- **After the update**: **log out and back in** so KWin loads the rebuilt effect. Do not restart KWin from a running session.

---

### Packaging Details
- Source build with CMake from the upstream release tarball; Wayland variant (`-DBBDX_X11=OFF`).
- Installs `better_blur_dx.so` into `/usr/lib/qt6/plugins/kwin/effects/plugins/` and its settings module into `.../kwin/effects/configs/`.
- `prepare()` aborts when the installed `kwin` is not the one `_kwinver` names, so a stale mirror can never produce a mismatched binary.
- License: upstream ships the GPLv3 text and SPDX headers of `GPL-2.0-or-later`; the package is declared `GPL-3.0-only`.

---

## 🔗 Related Links

- [Upstream Repository](https://github.com/xarblu/kwin-effects-better-blur-dx)
- [AUR Package](https://aur.archlinux.org/packages/kwin-effects-better-blur-dx)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
