# Sine, kud3n's Fork (`sine-fork`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.3.4.1.r1331.g79e4674--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/kud3n013/Sine)

The ultimate mod, theme, and CSS manager for Firefox-based browsers (Zen, Floorp, LibreWolf, Firefox), built from kud3n's fork.

---

## 📥 Installation

```bash
sudo pacman -S sine-fork
```

This package provides and conflicts with `sine`, so installing it replaces the release build (and the other way round). Both install the same `sine` command, desktop entry and `/etc/sine-flags.conf`.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `sine-fork` |
| **Current Version** | `2.3.4.1.r1331.g79e4674-1` |
| **Package Type** | **Modified (kud3n's fork, engine bundled)** |
| **Build Status** | `passing` |
| **Upstream Project** | [kud3n013/Sine](https://github.com/kud3n013/Sine), branch `main` |
| **Forked From** | [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine) |
| **Installer** | [sineorg/installer](https://github.com/sineorg/installer), built from source |
| **Category** | Core Application |

---

### Overview
The `sine` command is an installer GUI: it copies Sine's engine into a browser profile and installs the bootloader into the browser. Upstream's installer always downloads the engine (`engine.zip`) from CosmoCreeper's GitHub releases, so the release binary cannot install a fork. This package therefore builds both halves from source:

- **Engine:** `engine.zip` is packaged from kud3n013/Sine's `main` with the fork's own `scripts/package.py` and installed to `/opt/sine/engine.zip`.
- **Installer:** built from sineorg/installer against Arch's `glfw` and `curl`, and patched to run the updater script from `/opt/sine/updater.sh`, which installs the bundled engine (`file:///opt/sine`) instead of downloading upstream's. The bootloader (`program.zip`, `profile.zip`) is still downloaded from sineorg/bootloader, as upstream does.

### Packaging Details
- Version: the fork has no tags, so `pkgver` is the engine version from `engine.json` (cosine's `c` suffix dropped), the commit count and the short hash, for example `2.3.4.1.r1331.g79e4674`.
- Updates: `check-upstream.sh` (`github-branch`) follows the head of the fork's `main` and moves `_commithash` there. The installer commit is pinned in `_installercommit` and moved by hand.
- **Sine's own updater is turned off.** Upstream's in-browser updater checks CosmoCreeper's `engine.json` and would replace the fork's engine with CosmoCreeper's release. The bundled engine reports itself as up to date instead. To update the engine in a profile, upgrade the package and run `sine` again.
- Installer build fix: `ImGui::Text(variable)` calls are switched to `ImGui::TextUnformatted`, which Arch's `-Werror=format-security` requires.
- The launcher wrapper, flags file, desktop entry and icon are the same as the `sine` package's.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/sine-flags.conf` (system default `/etc/sine-flags.conf`). See the [`sine` package](sine.md) for the options.

## 🔗 Related Links

- [kud3n013/Sine](https://github.com/kud3n013/Sine)
- [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine)
- [`sine` package](sine.md)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
