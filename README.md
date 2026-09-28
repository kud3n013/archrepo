# archrepo 📦

[![Build & Publish Arch Packages](https://github.com/kud3n013/archrepo/actions/workflows/build.yml/badge.svg)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![Documentation](https://img.shields.io/badge/docs-package%20index-blue)](docs/README.md)
[![GitHub Pages](https://img.shields.io/badge/site-GitHub%20Pages-informational)](https://kud3n013.github.io/archrepo/)
[![GitHub Release](https://img.shields.io/github/v/release/kud3n013/archrepo?label=packages)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![Active Packages](https://img.shields.io/badge/packages-23%20active-success)](docs/README.md)

Automated, self-updating Arch Linux binary package repository. Packages are continuously built inside isolated `archlinux:base-devel` containers and published directly to pacman-compatible GitHub Release endpoints.

---

## 🚀 Quick Setup

Add the repository configuration to `/etc/pacman.conf`:

```ini
[archrepo]
SigLevel = Optional TrustAll
Server = https://github.com/kud3n013/archrepo/releases/download/packages
```

**One-liner quick install:**
```bash
echo -e '\n[archrepo]\nSigLevel = Optional TrustAll\nServer = https://github.com/kud3n013/archrepo/releases/download/packages' | sudo tee -a /etc/pacman.conf && sudo pacman -Syy
```

---

## 📦 Packages

Each package entry below provides direct links to its dedicated documentation in [`docs/`](docs/README.md), real-time CI container build status, current packaged version, package type, and standalone installation command:

- **Build Status**: [![build: passing](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) Built & published in release &bull; [![build: failing](https://img.shields.io/badge/build-failing-red)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) Build failure / under remediation
- **Package Type**: [![type: modified](https://img.shields.io/badge/type-modified-orange)](#) Enhanced with custom patches, LD_PRELOAD libraries, or desktop integration fixes &bull; [![type: original](https://img.shields.io/badge/type-original-blue)](#) Pure upstream software packaging

### 🚀 Applications & Standalone Packages

- [**`antigravity`**](docs/antigravity.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.17.0--5-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/antigravity.md) `sudo pacman -S antigravity`
  - Google Antigravity 2.0 multi-agent orchestration platform with native Wayland window controls and KDE Plasma Global Menu export. Upstream: [Google Antigravity](https://antigravity.google)
- [**`beeper`**](docs/beeper.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-4.3.152--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/beeper.md) `sudo pacman -S beeper`
  - Unified multi-network messaging client with XDG desktop portal dark theme sync and Wayland auto-hinting. Upstream: [Automattic / Beeper](https://www.beeper.com/changelog)
- [**`cursor`**](docs/cursor.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-3.22.7--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/cursor.md) `sudo pacman -S cursor`
  - AI-first code editor with KDE Plasma Global Menu export, DBusMenu punctuation normalization, GTK3 crash prevention & Wayland flags loader. Upstream: [Cursor](https://www.cursor.com)
- [**`freedownloadmanager`**](docs/freedownloadmanager.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-6.34.4.6974--4-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/freedownloadmanager.md) `sudo pacman -S freedownloadmanager`
  - Modern download accelerator and BitTorrent client with injected LD_PRELOAD library for system dark mode detection via portal. Upstream: [Free Download Manager](https://www.freedownloadmanager.org/)
- [**`galaxybudsclient`**](docs/galaxybudsclient.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-5.2.1--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/galaxybudsclient.md) `sudo pacman -S galaxybudsclient`
  - Unofficial Samsung Galaxy Buds manager with dynamic Wayland HiDPI auto-scaling detection and persistent tray menu hook. Upstream: [timschneeb/GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient)
- [**`gdlauncher-carbon`**](docs/gdlauncher-carbon.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.0.40--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/gdlauncher-carbon.md) `sudo pacman -S gdlauncher-carbon`
  - Powerful Minecraft custom launcher with modern UI, Wayland support, and clean uninstallation scriptlet. Upstream: [GDLauncher](https://gdlauncher.com)
- [**`howdy-next`**](docs/howdy-next.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-3.4.1--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/howdy-next.md) `sudo pacman -S howdy-next`
  - C++ rewrite of Howdy facial-recognition authentication for Linux PAM, patched to eliminate OpenCV 5 DNN warning spam. Upstream: [nathawat/howdy-next](https://codeberg.org/nathawat/howdy-next)
- [**`millennium`**](docs/millennium.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-3.5.0__beta.3--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/millennium.md) `sudo pacman -S millennium`
  - Steam Client modding framework for custom skins, themes, and community plugins. Upstream: [SteamClientHomebrew/Millennium](https://github.com/SteamClientHomebrew/Millennium)
- [**`obsidian`**](docs/obsidian.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.13.7--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/obsidian.md) `sudo pacman -S obsidian`
  - Powerful Markdown knowledge base patched with KDE Global Menu / AppMenu support and XDG portal dark/light theme switching. Upstream: [Obsidian](https://obsidian.md)
- [**`proton-mail`**](docs/proton-mail.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.15.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/proton-mail.md) `sudo pacman -S proton-mail`
  - Proton Mail & Calendar desktop application with restored system tray, close-to-tray, and unconstrained resizing. Upstream: [Proton Mail](https://proton.me/mail)
- [**`proton-pass`**](docs/proton-pass.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.41.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/proton-pass.md) `sudo pacman -S proton-pass`
  - Proton Pass password manager patched for unconstrained window bounds and responsive auto-collapsing item views. Upstream: [Proton Pass](https://proton.me/pass)
- [**`proton-pass-cli`**](docs/proton-pass-cli.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.4.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/proton-pass-cli.md) `sudo pacman -S proton-pass-cli`
  - Proton Pass CLI with Freedesktop D-Bus Secret Service session persistence wrapper and shell completions. Upstream: [Proton Pass CLI](https://protonpass.github.io/pass-cli)
- [**`searxng`**](docs/searxng.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-r9799.12f8b65--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/searxng.md) `sudo pacman -S searxng`
  - Privacy metasearch engine with systemd service unit, isolated venv, and auto-generated secret keys. Upstream: [searxng/searxng](https://searxng.github.io/searxng/)
- [**`sine`**](docs/sine.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.3.3--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/sine.md) `sudo pacman -S sine`
  - Mod and theme manager for Firefox-based browsers (Zen Browser, Floorp, LibreWolf, Firefox). Upstream: [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine)
- [**`zalo-for-linux`**](docs/zalo-for-linux.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-26.9.10--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/zalo-for-linux.md) `sudo pacman -S zalo-for-linux`
  - Zalo desktop messaging client with patched async call deadlocks and Wayland auto-hinting. Upstream: [doandat943/zalo-for-linux](https://github.com/doandat943/zalo-for-linux)
- [**`zed-globalmenu`**](docs/zed-globalmenu.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/zed-globalmenu.md) `sudo pacman -S zed-globalmenu`
  - High-performance code editor patched with KDE Plasma Global Menu export, server-side decorations, and in-app menu suppression. Upstream: [Zed](https://zed.dev)
- [**`zotero`**](docs/zotero.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-10.0.3--11-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/zotero.md) `sudo pacman -S zotero`
  - Reference manager with native title bar decorations, KDE Global Menu via LD_PRELOAD, and Hyprland/KDE auto-theming. Upstream: [Zotero](https://www.zotero.org)

---

### 🧩 Plugins & Add-ons

- [**`freedownloadmanager-elephant`**](docs/freedownloadmanager-elephant.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.3.8--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/freedownloadmanager-elephant.md) `sudo pacman -S freedownloadmanager-elephant`
  - Free Download Manager add-on for downloading online videos powered by `yt-dlp`. Upstream: [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant)
- [**`zotero-better-bibtex`**](docs/zotero-better-bibtex.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-9.0.64--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotero-better-bibtex.md) `sudo pacman -S zotero-better-bibtex`
  - Better BibTeX LaTeX bibliography and citation key management extension for Zotero. Upstream: [retorquere/zotero-better-bibtex](https://github.com/retorquere/zotero-better-bibtex)
- [**`zotero-better-notes`**](docs/zotero-better-notes.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-3.3.3--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotero-better-notes.md) `sudo pacman -S zotero-better-notes`
  - Advanced note-taking and knowledge management extension for Zotero with markdown export. Upstream: [windingwind/zotero-better-notes](https://github.com/windingwind/zotero-better-notes)
- [**`zotero-mcp`**](docs/zotero-mcp.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-0.13.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotero-mcp.md) `sudo pacman -S zotero-mcp`
  - Model Context Protocol (MCP) server & standalone CLI connecting AI assistants and LLMs to Zotero libraries. Upstream: [54yyyu/zotero-mcp](https://github.com/54yyyu/zotero-mcp)
- [**`zotero-ocr`**](docs/zotero-ocr.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-0.9.6--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotero-ocr.md) `sudo pacman -S zotero-ocr`
  - PDF Optical Character Recognition plugin for Zotero configured with poppler and tesseract. Upstream: [UB-Mannheim/zotero-ocr](https://github.com/UB-Mannheim/zotero-ocr)
- [**`zotero-pdf-translate`**](docs/zotero-pdf-translate.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.4.7--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotero-pdf-translate.md) `sudo pacman -S zotero-pdf-translate`
  - In-app translation plugin for Zotero supporting PDFs, EPubs, metadata, and annotations via 20+ translation backends. Upstream: [windingwind/zotero-pdf-translate](https://github.com/windingwind/zotero-pdf-translate)
- [**`zotmoov`**](docs/zotmoov.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.2.32--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/zotmoov.md) `sudo pacman -S zotmoov`
  - Automatic attachment mover and folder organizer for Zotero based on collection or item rules. Upstream: [wileyyugioh/zotmoov](https://github.com/wileyyugioh/zotmoov)

---

<details>
<summary><b>🗄️ Archived Packages (4)</b></summary>

The following packages have been retired from active distribution and their binary packages pruned from the database:

- [**`hyprmod`**](docs/hyprmod.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-0.4.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/hyprmod/`](archive/hyprmod/) &bull; Upstream: [BlueManCZ/hyprmod](https://github.com/BlueManCZ/hyprmod) (Retired per maintainer request)
- [**`stirling-pdf-desktop`**](docs/stirling-pdf-desktop.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-3.0.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/stirling-pdf-desktop/`](archive/stirling-pdf-desktop/) &bull; Upstream: [Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF) (Archived per maintainer request)
- [**`zed`**](docs/zed.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/zed/`](archive/zed/) &bull; Upstream: [Zed](https://zed.dev) (Archived per maintainer request)
- [**`zen-browser`**](docs/zen-browser.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-1.22.2b--4-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/zen-browser/`](archive/zen-browser/) &bull; Upstream: [zen-browser/desktop](https://github.com/zen-browser/desktop) (Archived per maintainer request)

See [`archive/README.md`](archive/README.md) for instructions on restoring archived packages.

</details>

---

## 📁 Repository Structure

```text
archrepo/
├── docs/              # Comprehensive package documentation & customization guides
├── packages/          # Active package build recipes (PKGBUILD, scripts, flags)
├── archive/           # Retired package recipes (excluded from builds & database)
├── tools/             # Maintainer developer utilities (clean.sh, scaffold.sh)
├── templates/         # Package creation prompt template for AI assistants
└── .github/           # CI/CD workflows and automated release scripts
```

---

## 📖 Documentation & Flags System

All packages are documented with installation guides, architectural details, and configuration references in the [`docs/`](docs/README.md) directory.

### Intelligent Flags System
Many GUI and Electron packages in `archrepo` ship with an intelligent flags loader:
- **System Defaults**: `/etc/<package>-flags.conf`
- **User Overrides**: `~/.config/<package>-flags.conf`

Users can easily customize Wayland options, HiDPI scaling factors, and environment variables without needing root permissions or editing desktop files:
```bash
# Example ~/.config/obsidian-flags.conf
--ozone-platform-hint=auto
--enable-wayland-ime
--force-device-scale-factor=1.5
```

---

## 🛠️ Maintainer Guide

### Adding a Package
1. **Scaffold:**
   ```bash
   ./tools/scaffold.sh my-package owner/repo
   ```
2. **Configure:** Edit `packages/my-package/PKGBUILD` and optional `upstream.json`.
3. **Document:** Add `docs/my-package.md` and link it in `README.md` and `docs/README.md`.
4. **Commit & Push:**
   ```bash
   git add packages/my-package/ docs/my-package.md README.md docs/README.md
   git commit -m "feat(my-package): add package recipe and documentation"
   git push origin main
   ```
   The CI pipeline automatically detects the package, builds it in an Arch container, updates `archrepo.db`, and publishes to GitHub Releases.

### Helper Tools
- **Purge local build artifacts:** `./tools/clean.sh` (supports `--dry-run`, `--pkg <name>`, `--force`)
- **Manual CI build:** `gh workflow run build.yml -f package=<name> [-f force_rebuild=true]`

---

## ⚙️ Architecture

- **Dual-Tier Storage:** GitHub Releases (`packages` tag) stores `.pkg.tar.zst` binaries and databases (`archrepo.db`, `archrepo.files`), bypassing repository size limits. GitHub Pages hosts the web index.
- **Smart Build Caching:** If a target `${pkgver}-${pkgrel}` binary is already published in Releases, compilation is skipped.
- **Automatic Upstream Tracking:** A daily cron job (`0 4 * * *`) checks upstream GitHub/Codeberg releases and redirects, auto-bumps versions, updates checksums (`updpkgsums`), and triggers new builds.
- **Release Pruning:** Older superseded package archives are automatically pruned upon upgrade.

---

## 📜 License

Packaging configurations, launchers, and automation scripts are released under the [MIT License](LICENSE). Packaged software is subject to its respective upstream licenses.
