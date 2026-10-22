# Antigravity CLI (`antigravity-cli`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.4.4--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://antigravity.google/product/antigravity-cli)

Google Antigravity CLI (`agy`), a terminal coding agent that shares an account and settings with the Antigravity desktop app.

---

## 📥 Installation

```bash
sudo pacman -S antigravity-cli
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `antigravity-cli` |
| **Command** | `agy` |
| **Current Version** | `1.4.4-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [Google Antigravity CLI](https://antigravity.google/product/antigravity-cli) |
| **License** | Proprietary (Google) |
| **Category** | CLI Tool |

---

### Overview
Repackages Google's prebuilt Linux x64 binary unmodified. The only addition is a small `/usr/bin/agy` launcher that turns off the CLI's built-in self-updater, so pacman alone decides which version is installed.

### Packaging Details
- **Source**: `cli_linux_x64.tar.gz` from `storage.googleapis.com/antigravity-public/antigravity-cli/<version>-<build>/linux-x64/`, the same file Google's `install.sh` downloads. It holds one Go binary that only links glibc.
- **Layout**: the binary is installed as `/usr/lib/antigravity-cli/agy`. Upstream names it `antigravity`, but that name belongs to the desktop app, so only `agy` is put on `PATH`.
- **Self-updater disabled**: the launcher exports `AGY_CLI_DISABLE_AUTO_UPDATE=true` unless you already set it. Without it, every start spawns a background updater that cannot write to `/usr/lib` and leaves "Update failed, please install from website" in its status file. Upstream ignores the value `1`; only `true` works. `agy update` is likewise meaningless here, use `pacman -Syu`.
- **Replaces** the AUR package `antigravity-cli-bin` and provides `agy`.
- **Updates**: the daily check reads the CLI's own updater manifest (`manifests/linux_amd64.json`) and takes the version and build id from its download URL. A new build of the same version bumps `pkgrel`.

### Notes
- If you previously ran `curl -fsSL https://antigravity.google/cli/install.sh | bash`, remove `~/.local/bin/agy`; it comes before `/usr/bin` on most `PATH`s and would shadow this package.
- `agy install` only edits shell profiles to add `~/.local/bin` to `PATH`, which this package does not need.
- Sign-in, settings, MCP servers and conversations live under `~/.gemini/antigravity-cli/`.

---

## 🔗 Related Links

- [Upstream product page](https://antigravity.google/product/antigravity-cli)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
