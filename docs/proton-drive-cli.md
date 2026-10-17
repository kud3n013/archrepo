# Proton Drive CLI (`proton-drive-cli`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.9.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/download/drive/cli/index.html)

Official Proton Drive command-line client for browsing, uploading, downloading and sharing files.

---

## 📥 Installation

```bash
sudo pacman -S proton-drive-cli
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `proton-drive-cli` |
| **Current Version** | `0.9.0-1` |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [Proton Drive CLI](https://proton.me/download/drive/cli/index.html) |
| **License** | MIT |
| **Category** | CLI Tool |

---

### Overview
Repackages Proton's prebuilt `proton-drive` binary (x86_64, glibc) unmodified. The installed command is `proton-drive`; run `proton-drive auth login` to sign in.

### Packaging Details
- **Source**: the binary is downloaded from `proton.me/download/drive/cli/<ver>/linux-x64/` and verified with the SHA-512 checksums Proton publishes on its download page. The MIT license is taken from the matching `ProtonDriveApps/sdk` tag.
- **Secret Service required**: credentials are stored through libsecret. Without a provider such as `gnome-keyring`, `kwallet` or `keepassxc`, the CLI fails with `ERR_SECRETS_PLATFORM_ERROR`, so `org.freedesktop.secrets` is a hard dependency.
- **Replaces** the AUR package `proton-drive-cli-bin`.
- **Updates**: the daily check parses the version from Proton's download index page.

---

## 🔗 Related Links

- [Upstream Download Page](https://proton.me/download/drive/cli/index.html)
- [ProtonDriveApps/sdk](https://github.com/ProtonDriveApps/sdk)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
