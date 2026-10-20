# archrepo 📦

[![Build & Publish Arch Packages](https://github.com/kud3n013/archrepo/actions/workflows/build.yml/badge.svg)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![Documentation](https://img.shields.io/badge/docs-package%20index-blue)](docs/README.md)
[![GitHub Pages](https://img.shields.io/badge/site-GitHub%20Pages-informational)](https://kud3n013.github.io/archrepo/)
[![GitHub Release](https://img.shields.io/github/v/release/kud3n013/archrepo?label=packages)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![Active Packages](https://img.shields.io/badge/packages-26%20active-success)](docs/README.md)

Automated, self-updating Arch Linux binary package repository. Packages are continuously built inside isolated `archlinux:base-devel` containers and published directly to pacman-compatible GitHub Release endpoints.

---

## 🚀 Quick Setup

Packages and the database are signed with the repository key
`CFB7 9154 3B4B 2D28 21E9  127A C012 A947 6C17 0A37` ([`keys/archrepo.asc`](keys/archrepo.asc)).

1. Import and locally sign the key:
   ```bash
   curl -sSfL -o /tmp/archrepo.asc https://github.com/kud3n013/archrepo/releases/download/packages/archrepo.asc
   sudo pacman-key --add /tmp/archrepo.asc
   sudo pacman-key --lsign-key CFB791543B4B2D2821E9127AC012A9476C170A37
   ```

2. Add the repository configuration to `/etc/pacman.conf`:
   ```ini
   [archrepo]
   SigLevel = Required
   Server = https://github.com/kud3n013/archrepo/releases/download/packages
   ```

3. Synchronize: `sudo pacman -Syy`

**Already using archrepo?** Import the key (step 1), then change `SigLevel = Optional TrustAll` to `SigLevel = Required` in your `[archrepo]` section.

---

## 📦 Packages

Each package entry below provides direct links to its dedicated documentation in [`docs/`](docs/README.md), real-time CI container build status, current packaged version, package type, and standalone installation command:

- **Build Status**: [![build: passing](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) Built & published in release &bull; [![build: failing](https://img.shields.io/badge/build-failing-red)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) Build failure / under remediation
- **Package Type**: [![type: modified](https://img.shields.io/badge/type-modified-orange)](#) Enhanced with custom patches, LD_PRELOAD libraries, or desktop integration fixes &bull; [![type: original](https://img.shields.io/badge/type-original-blue)](#) Pure upstream software packaging

### 🚀 Applications & Standalone Packages

- [**`beeper`**](docs/beeper.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-4.3.152--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/beeper.md) `sudo pacman -S beeper`
  - Unified multi-network messaging client with XDG desktop portal dark theme sync and Wayland auto-hinting. Upstream: [Automattic / Beeper](https://www.beeper.com/changelog)
- [**`claude-desktop`**](docs/claude-desktop.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.42304.2--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/claude-desktop.md) `sudo pacman -S claude-desktop`
  - Official Claude desktop app (Chat, Cowork and Claude Code) repackaged from Anthropic's Debian build, with a Wayland launcher, Cowork VM shims and the window manager's title bar in place of the app's frameless one. Upstream: [Anthropic](https://claude.ai/download)
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
- [**`kast`**](docs/kast.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-0.6.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/kast.md) `sudo pacman -S kast`
  - Arch/CachyOS setup TUI with an App Vault backup engine and Proton Drive backups. Upstream: [kud3n013/kast](https://github.com/kud3n013/kast)
- [**`millennium`**](docs/millennium.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-3.5.0--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/millennium.md) `sudo pacman -S millennium`
  - Steam Client modding framework for custom skins, themes, and community plugins. Upstream: [SteamClientHomebrew/Millennium](https://github.com/SteamClientHomebrew/Millennium)
- [**`obsidian`**](docs/obsidian.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.13.7--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/obsidian.md) `sudo pacman -S obsidian`
  - Powerful Markdown knowledge base patched with KDE Global Menu / AppMenu support and XDG portal dark/light theme switching. Upstream: [Obsidian](https://obsidian.md)
- [**`proton-drive-cli`**](docs/proton-drive-cli.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-0.9.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/proton-drive-cli.md) `sudo pacman -S proton-drive-cli`
  - Official Proton Drive command-line client for browsing, uploading, downloading and sharing files. Upstream: [Proton Drive CLI](https://proton.me/download/drive/cli/index.html)
- [**`searxng`**](docs/searxng.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-r9799.12f8b65--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/searxng.md) `sudo pacman -S searxng`
  - Privacy metasearch engine with systemd service unit, isolated venv, and auto-generated secret keys. Upstream: [searxng/searxng](https://searxng.github.io/searxng/)
- [**`sine`**](docs/sine.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.3.3--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/sine.md) `sudo pacman -S sine`
  - Mod and theme manager for Firefox-based browsers (Zen Browser, Floorp, LibreWolf, Firefox). Upstream: [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine)
- [**`steam-globalmenu`**](docs/steam-globalmenu.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.2.0--3-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/steam-globalmenu.md) `sudo pacman -S steam-globalmenu`
  - Steam client menu bar and recent games bridge exporting to KDE Plasma Global Menu via DBusMenu. Upstream: [kud3n013/steam-dbusmenu-export](https://github.com/kud3n013/steam-dbusmenu-export)
- [**`zed-globalmenu`**](docs/zed-globalmenu.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.21.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/zed-globalmenu.md) `sudo pacman -S zed-globalmenu`
  - High-performance code editor patched with KDE Plasma Global Menu export, server-side decorations, and in-app menu suppression. Upstream: [Zed](https://zed.dev)
- [**`zotero`**](docs/zotero.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-10.0.3--11-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-modified-orange)](docs/zotero.md) `sudo pacman -S zotero`
  - Reference manager with native title bar decorations, KDE Global Menu via LD_PRELOAD, and Hyprland/KDE auto-theming. Upstream: [Zotero](https://www.zotero.org)

---

### 🧩 Plugins & Add-ons

- [**`dbusmenu-shortcut-shim`**](docs/dbusmenu-shortcut-shim.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.0.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/dbusmenu-shortcut-shim.md) `sudo pacman -S dbusmenu-shortcut-shim`
  - Shared LD_PRELOAD shim used by `cursor`, `obsidian` and `zotero` that restores punctuation shortcut tips (e.g. `Ctrl+,`) in KDE Plasma's Global Menu. Upstream: [kud3n013/dbusmenu-shortcut-shim](https://github.com/kud3n013/dbusmenu-shortcut-shim)
- [**`freedownloadmanager-elephant`**](docs/freedownloadmanager-elephant.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-1.3.8--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/freedownloadmanager-elephant.md) `sudo pacman -S freedownloadmanager-elephant`
  - Free Download Manager add-on for downloading online videos powered by `yt-dlp`. Upstream: [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant)
- [**`kwin-effects-better-blur-dx`**](docs/kwin-effects-better-blur-dx.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-2.6.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/kwin-effects-better-blur-dx.md) `sudo pacman -S kwin-effects-better-blur-dx`
  - KWin Blur fork for Plasma 6 with force blur, refraction and rounded corners, rebuilt automatically for every new Arch `kwin`. Upstream: [xarblu/kwin-effects-better-blur-dx](https://github.com/xarblu/kwin-effects-better-blur-dx)
- [**`kwin-scripts-krohnkite`**](docs/kwin-scripts-krohnkite.md) [![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml) [![version](https://img.shields.io/badge/version-0.9.9.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) [![type](https://img.shields.io/badge/type-original-blue)](docs/kwin-scripts-krohnkite.md) `sudo pacman -S kwin-scripts-krohnkite`
  - Dynamic tiling extension for KWin (KDE Plasma 6) ported from Krohnkite. Upstream: [anametologin/krohnkite](https://codeberg.org/anametologin/krohnkite)
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
<summary><b>🗄️ Archived Packages (9)</b></summary>

The following packages have been retired from active distribution and their binary packages pruned from the database:

- [**`antigravity`**](docs/antigravity.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-2.22.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/antigravity/`](archive/antigravity/) &bull; Upstream: [Google Antigravity](https://antigravity.google) (Archived per maintainer request)
- [**`hyprmod`**](docs/hyprmod.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-0.4.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/hyprmod/`](archive/hyprmod/) &bull; Upstream: [BlueManCZ/hyprmod](https://github.com/BlueManCZ/hyprmod) (Retired per maintainer request)
- [**`proton-mail`**](docs/proton-mail.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-1.15.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/proton-mail/`](archive/proton-mail/) &bull; Upstream: [Proton Mail](https://proton.me/mail) (Archived per maintainer request)
- [**`proton-pass`**](docs/proton-pass.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-1.42.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/proton-pass/`](archive/proton-pass/) &bull; Upstream: [Proton Pass](https://proton.me/pass) (Archived per maintainer request)
- [**`proton-pass-cli`**](docs/proton-pass-cli.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-2.4.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/proton-pass-cli/`](archive/proton-pass-cli/) &bull; Upstream: [Proton Pass CLI](https://protonpass.github.io/pass-cli) (Archived per maintainer request)
- [**`stirling-pdf-desktop`**](docs/stirling-pdf-desktop.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-3.0.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/stirling-pdf-desktop/`](archive/stirling-pdf-desktop/) &bull; Upstream: [Stirling-Tools/Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF) (Archived per maintainer request)
- [**`zalo-for-linux`**](docs/zalo-for-linux.md) [![status](https://img.shields.io/badge/status-archived-lightgrey)](archive/README.md) [![version](https://img.shields.io/badge/version-26.10.11--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages) &bull; Location: [`archive/zalo-for-linux/`](archive/zalo-for-linux/) &bull; Upstream: [VN-Linux-Family/zalo-for-linux](https://github.com/VN-Linux-Family/zalo-for-linux) (Archived per maintainer request)
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
├── keys/              # Public repository signing key (archrepo.asc)
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
   `upstream.json` may also set `"rebuild_on": "kwin"` to rebuild the package whenever Arch's `kwin` version changes (for KWin plugins; the PKGBUILD then needs a literal `_kwinver=` line). The `kwin-watch` workflow dispatches those rebuilds.
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
- **Signed Packages:** Build jobs run with a read-only token and no secrets; the publish job signs every package and the database with the repository key (`ARCHREPO_SIGNING_KEY` secret).
- **Automatic Upstream Tracking:** A daily cron job (`0 4 * * *`) checks upstream GitHub/Codeberg releases and redirects, bumps versions and checksums (`updpkgsums`), and builds the update. Each update goes through a pull request on `bump/<pkg>`; a failed build leaves that pull request open until a later build succeeds.
- **KWin Rebuilds:** Packages marked `"rebuild_on": "kwin"` in `upstream.json` (KWin effects link against its private API) are rebuilt when Arch ships a new `kwin`. The `kwin-watch` workflow polls Arch's `extra` database every 30 minutes and dispatches a build of just those packages, which goes through the same `bump/<pkg>` pull request.
- **Release Pruning:** Release packages the database no longer references (superseded versions, archived packages) are pruned automatically.

---

## 📜 License

Packaging configurations, launchers, and automation scripts are released under the [MIT License](LICENSE). Packaged software is subject to its respective upstream licenses.
