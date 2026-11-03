# Ghidra (`ghidra`)

[![build](https://img.shields.io/badge/build-pending-lightgrey)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-12.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/NationalSecurityAgency/ghidra)

Ghidra, the software reverse engineering framework from the NSA: disassembly, decompilation, scripting (Java and Python 3 through PyGhidra), version tracking, BSim and a debugger, for binaries from many processors and formats. Interactive GUI, plus a headless analyzer for batch work.

---

## 📥 Installation

```bash
sudo pacman -S archrepo/ghidra
```

Arch's `extra` repository also has a `ghidra`, built from source and usually a release or two behind. Name the repository (`archrepo/ghidra`) so pacman installs this one. Updates come from the first repository in `/etc/pacman.conf` that has a package by that name, so keep `[archrepo]` above `[extra]` if you want this build's updates.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `ghidra` |
| **Commands** | `ghidra` (GUI), `ghidra-analyzeHeadless`, `pyghidra` |
| **Current Version** | `12.2-1` |
| **Package Type** | **Modified** |
| **Build Status** | `pending` |
| **Upstream Project** | [NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra) ([ghidra-sre.org](https://ghidra-sre.org)) |
| **License** | Apache-2.0 (bundled components under their own licenses, see `/usr/share/licenses/ghidra/licenses`) |
| **Category** | Development |

---

### Overview
Repackages upstream's official release zip, which already holds the Linux x86-64 native decompiler, sleigh and demangler, in `/opt/ghidra`, unmodified. `ghidra` is a small launcher in front of upstream's `ghidraRun` that reads a flags file and fixes two desktop problems Java has on its own: a tiny UI on HiDPI screens and blank windows on tiling window managers.

### Desktop integration

| Check | Result |
|---|---|
| **HiDPI** | Upstream pins the Java UI scale to 1, so Ghidra ignores the desktop's scale. The launcher sets the scale from `GDK_SCALE`, or from `Xft.dpi` (192 dpi and up, with `xorg-xrdb` installed), in whole steps: Java's Swing scaling on Linux is unreliable at fractions. Set `-Dsun.java2d.uiScale=` in the flags file to force one, or `-Dfont.size.override=` for bigger fonts alone. |
| **Tiling window managers** | Java draws blank or grey windows when the window manager doesn't reparent. The launcher sets `_JAVA_AWT_WM_NONREPARENTING=1` on Sway, Hyprland, niri, river, Wayfire, labwc, dwl, qtile, i3, bspwm, xmonad, dwm, herbstluftwm, leftwm and spectrwm. |
| **Wayland** | Runs through Xwayland. The JDK's native Wayland toolkit isn't in a released JDK yet. |
| **Title bar** | The window manager's own title bar. |
| **Global menu** | Not available. Swing menus aren't exported over DBusMenu. |
| **Light/dark theme** | Doesn't follow the desktop. Ghidra has its own themes (Edit → Theme), dark ones included. |
| **Desktop entry** | `ghidra.desktop` with Ghidra's own icons. `.gpr` project files get a MIME type (`application/x-ghidra-project`) and open in Ghidra. |

### Packaging Details
- **Source**: `ghidra_<version>_PUBLIC_<date>.zip` from the [GitHub release](https://github.com/NationalSecurityAgency/ghidra/releases). The date is kept in the PKGBUILD as `_build`.
- **Java**: Ghidra 12.2 needs a JDK 25 or newer (`java-environment>=25`); a JRE isn't enough. It also runs on the current `jdk-openjdk` (27). If your default Java (`archlinux-java status`) is older, Ghidra's launcher finds a newer JDK in `/usr/lib/jvm` by itself and remembers it in `~/.config/ghidra/`.
- **Optional dependencies**: `python` for PyGhidra (`pyghidra` sets up its own virtual environment under `~/.config/ghidra/` from the wheels Ghidra bundles, no download), `gdb` or `lldb` for the debugger, `xorg-xrdb` for HiDPI detection from `Xft.dpi`.
- **Updates**: the daily check follows the latest GitHub release of `NationalSecurityAgency/ghidra` and reads the build date from the release zip's name. A re-published zip with the same version but a new date bumps `pkgrel`.
- **Replaces** the AUR package `ghidra-bin` and conflicts with `ghidra-git` and `ghidra-desktop`.

### Configuration

The launcher reads `~/.config/ghidra-flags.conf`, or `/etc/ghidra-flags.conf` when you have none:

```bash
# Java options start with '-'; they are applied after Ghidra's launch.properties
-Dsun.java2d.uiScale=2
-Dfont.size.override=14
# NAME=value sets an environment variable (unless it is already set)
GHIDRA_GUI_MAXMEM=8G
_JAVA_AWT_WM_NONREPARENTING=1
```

Options can't contain spaces (`ghidraRun` splits them). Upstream's system-wide settings stay in `/opt/ghidra/support/launch.properties`; edits there are overwritten on upgrade, so put your options in the flags file.

### Notes
- Per-user settings, extensions and the PyGhidra environment live in `~/.config/ghidra/ghidra_<version>_PUBLIC/`, the cache and logs in `~/.cache/ghidra/`. A new version asks on first start whether to import the previous version's settings.
- Ghidra Server (`/opt/ghidra/server`) isn't set up as a service: it writes its configuration and repositories inside the install directory. Run a server from a copy of the release zip instead.
- `ghidra-analyzeHeadless` and `pyghidra` are upstream's `support/analyzeHeadless` and `support/pyghidraRun`, under the names Arch's own package uses. The other tools (`bsim`, `sleigh`, `ghidraDebug`, ...) are in `/opt/ghidra/support/`.
- Upstream bugs go to [NationalSecurityAgency/ghidra](https://github.com/NationalSecurityAgency/ghidra/issues).

---

## 🔗 Related Links

- [Upstream repository](https://github.com/NationalSecurityAgency/ghidra)
- [Ghidra website](https://ghidra-sre.org)
- [Getting Started](https://github.com/NationalSecurityAgency/ghidra/blob/master/GhidraDocs/GettingStarted.md)
- Arch: [`extra/ghidra`](https://archlinux.org/packages/extra/x86_64/ghidra/) · AUR: [`ghidra-bin`](https://aur.archlinux.org/packages/ghidra-bin)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
