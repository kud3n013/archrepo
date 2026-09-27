# Proton Pass CLI (`proton-pass-cli`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.4.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://protonpass.github.io/pass-cli)

Command-line interface for Proton Pass with Freedesktop D-Bus Secret Service integration and shell completions.

---

## 📥 Installation

```bash
sudo pacman -S proton-pass-cli
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `proton-pass-cli` |
| **Current Version** | `2.4.1-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Pass CLI](https://protonpass.github.io/pass-cli) |
| **Category** | Core Application |

---

### Overview
`proton-pass-cli` (`pass-cli`) allows searching, reading, creating, and automating secrets and credentials from Proton Pass directly in shell scripts and terminal sessions.

### Packaging Details
- Bundles upstream pre-compiled binary.
- Includes launcher wrapper script `proton-pass-cli.sh` that detects active Freedesktop D-Bus Secret Service (GNOME Keyring, KWallet, KeePassXC) to ensure session keys persist across system reboots instead of relying only on volatile kernel keyrings.
- Provides `/etc/proton-pass-cli.conf` for user configuration.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/proton-pass-cli.conf`

```bash
# Keyring backend (dbus or kernel)
PROTON_PASS_LINUX_KEYRING=dbus
```

## 🔗 Related Links

- [Upstream Repository / Website](https://protonpass.github.io/pass-cli)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
