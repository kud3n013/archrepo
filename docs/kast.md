# Kast (`kast`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.6.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/kud3n013/kast)

Kud3n's Arch Setup Tool: an Arch Linux / CachyOS fast-setup TUI with an embedded App Vault backup engine.

---

## 📥 Installation

```bash
sudo pacman -S kast
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `kast` |
| **Current Version** | `0.6.2-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [kud3n013/kast](https://github.com/kud3n013/kast) |
| **License** | GPL-3.0-or-later |
| **Category** | CLI / TUI Tool |

---

### Overview
Repackages the prebuilt static (musl) `kast` binary from the upstream GitHub release unmodified. Run `sudo kast` from your own user account to open the setup TUI.

### Packaging Details
- **Source**: the `kast-x86_64-unknown-linux-musl` release asset, verified with SHA-256 (matches the checksum upstream publishes). The license is taken from the matching upstream tag.
- **Dependencies**: only `sudo`, which kast uses to re-run itself as root. The binary is static, so it links no libraries.
- **Optional dependencies**: `proton-drive-cli` for Proton Drive backups, `snapper` for btrfs snapshots before upgrades and `curl` to refresh `packages.toml` online.
- **Conflicts** with the AUR package `kast-bin`, an unrelated video-casting tool that also provides `kast`. It is deliberately not replaced.
- **Installed path**: `/usr/bin/kast`. Upstream's `install.sh` uses `/usr/local/bin/kast`, which takes precedence in `PATH`; remove that copy after switching to the package.
- **Updates**: the daily check follows the latest upstream GitHub release.

---

## 🔗 Related Links

- [Upstream Repository](https://github.com/kud3n013/kast)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
