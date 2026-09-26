# archrepo 📦

[![Build & Publish Arch Packages](https://github.com/kud3n013/archrepo/actions/workflows/build.yml/badge.svg)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![GitHub Pages](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://kud3n013.github.io/archrepo/)
[![GitHub Release](https://img.shields.io/github/v/release/kud3n013/archrepo?label=packages)](https://github.com/kud3n013/archrepo/releases/tag/packages)

Automated, self-updating Arch Linux binary package repository. Packages are built in isolated `archlinux:base-devel` containers and published directly to pacman-compatible GitHub Release endpoints.

---

## 🚀 Quick Setup

Add to `/etc/pacman.conf`:

```ini
[archrepo]
SigLevel = Optional TrustAll
Server = https://github.com/kud3n013/archrepo/releases/download/packages
```

**One-liner:**
```bash
echo -e '\n[archrepo]\nSigLevel = Optional TrustAll\nServer = https://github.com/kud3n013/archrepo/releases/download/packages' | sudo tee -a /etc/pacman.conf && sudo pacman -Syy
```

---

## 📦 Packages

Install any package using `sudo pacman -S <package>`.

| Package | Description | Upstream |
|---|---|---|
| **`antigravity`** | Google Antigravity 2.0 multi-agent orchestration platform (native Wayland) | [Google Antigravity](https://antigravity.google) |
| **`beeper`** | Unified messaging client (Ozone auto-hinting, clean desktop integration) | [Automattic / Beeper](https://www.beeper.com/changelog) |
| **`freedownloadmanager`** | Download accelerator & organizer (desktop portal & dark mode detection) | [Free Download Manager](https://www.freedownloadmanager.org/) |
| **`freedownloadmanager-elephant`** | FDM add-on for video downloading powered by yt-dlp | [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant) |
| **`galaxybudsclient`** | Galaxy Buds manager for Linux (Wayland HiDPI auto-scaling, persistent tray) | [ThePBone/GalaxyBudsClient](https://github.com/ThePBone/GalaxyBudsClient) |
| **`gdlauncher-carbon`** | GDLauncher Carbon Minecraft launcher (Electron, Wayland-ready) | [GDLauncher](https://gdlauncher.com) |
| **`howdy-next`** | PAM facial-recognition authentication (suppresses OpenCV 5 DNN warnings) | [nathawat/howdy-next](https://codeberg.org/nathawat/howdy-next) |
| **`millennium`** | Steam Client modding framework for custom skins, themes, and plugins | [SteamClientHomebrew/Millennium](https://github.com/SteamClientHomebrew/Millennium) |
| **`proton-mail`** | Proton Mail/Calendar desktop (system tray, unconstrained resizing, responsive sidebar) | [Proton Mail](https://proton.me/mail) |
| **`proton-pass`** | Proton Pass desktop (unconstrained window resizing, auto-collapsing item view) | [Proton Pass](https://proton.me/pass) |
| **`proton-pass-cli`** | Proton Pass CLI (`pass-cli`, `proton-pass-cli`) with D-Bus secrets & completions | [Proton Pass CLI](https://protonpass.github.io/pass-cli) |
| **`searxng`** | Privacy-respecting metasearch engine with systemd service & Valkey integration | [searxng/searxng](https://searxng.github.io/searxng/) |
| **`sine`** | Mod & theme manager for Firefox-based browsers (Zen, Floorp, LibreWolf, Firefox) | [CosmoCreeper/Sine](https://github.com/CosmoCreeper/Sine) |
| **`zalo-for-linux`** | Zalo desktop client with Wayland / Hyprland scaling fixes and bundled logo | [doandat943/zalo-for-linux](https://github.com/doandat943/zalo-for-linux) |
| **`zed`** | High-performance, multiplayer code editor (native Wayland GPUI, Vulkan) | [Zed](https://zed.dev) |
| **`zotero`** | Reference manager with native title bar, KDE Global Menu, and Hyprland/KDE auto-theming | [Zotero](https://www.zotero.org) |
| **`zotero-better-bibtex`** | Better BibTeX LaTeX bibliography and citation management for Zotero | [retorquere/zotero-better-bibtex](https://github.com/retorquere/zotero-better-bibtex) |
| **`zotero-better-notes`** | Comprehensive note taking and knowledge management for Zotero | [windingwind/zotero-better-notes](https://github.com/windingwind/zotero-better-notes) |
| **`zotero-mcp`** | Model Context Protocol (MCP) server & standalone CLI for Zotero | [54yyyu/zotero-mcp](https://github.com/54yyyu/zotero-mcp) |
| **`zotero-ocr`** | PDF Optical Character Recognition (configured with Arch poppler/tesseract) | [UB-Mannheim/zotero-ocr](https://github.com/UB-Mannheim/zotero-ocr) |
| **`zotero-pdf-translate`** | Translate PDFs, EPubs, and annotations via 20+ translation services | [windingwind/zotero-pdf-translate](https://github.com/windingwind/zotero-pdf-translate) |
| **`zotmoov`** | Automatic attachment mover based on collection/item rules | [wileyyugioh/zotmoov](https://github.com/wileyyugioh/zotmoov) |

<details>
<summary><b>🗄️ Archived Packages (2)</b></summary>

| Package | Upstream | Location | Status |
|---|---|---|---|
| `hyprmod` | [BlueManCZ/hyprmod](https://github.com/BlueManCZ/hyprmod) | [`archive/hyprmod/`](archive/hyprmod/) | Retired per maintainer request |
| `zen-browser` | [zen-browser/desktop](https://github.com/zen-browser/desktop) | [`archive/zen-browser/`](archive/zen-browser/) | Archived per maintainer request |

</details>

---

## 📁 Repository Structure

```text
archrepo/
├── packages/          # Active package build recipes (PKGBUILD, scripts, flags)
├── archive/           # Retired package recipes (excluded from builds & database)
├── tools/             # Maintainer developer utilities (clean.sh, scaffold.sh)
├── templates/         # Package creation prompt template for AI assistants
└── .github/           # CI/CD workflows and automated release scripts
```

---

## 🛠️ Maintainer Guide

### Adding a Package
1. **Scaffold:**
   ```bash
   ./tools/scaffold.sh my-package owner/repo
   ```
2. **Configure:** Edit `packages/my-package/PKGBUILD` and optional `upstream.json`.
3. **Commit & Push:**
   ```bash
   git add packages/my-package/ && git commit -m "feat: add my-package" && git push
   ```
   The CI pipeline automatically detects the package, builds it in an Arch container, updates `archrepo.db`, and publishes to GitHub Releases.

### Helper Tools
- **Purge local build artifacts:** `./tools/clean.sh` (supports `--dry-run`, `--pkg <name>`, `--force`)
- **Manual CI build:** `gh workflow run build.yml -f package=<name> [-f force_rebuild=true]`

---

## ⚙️ Architecture

- **Dual-Tier Storage:** GitHub Releases (`packages` tag) stores `.pkg.tar.zst` binaries and databases (`archrepo.db`, `archrepo.files`), bypassing repo size limits. GitHub Pages hosts the web index.
- **Smart Build Caching:** If a target `${pkgver}-${pkgrel}` binary is already published in Releases, compilation is skipped.
- **Automatic Upstream Tracking:** A daily cron job (`0 4 * * *`) checks upstream GitHub/Codeberg releases and redirects, auto-bumps versions, updates checksums (`updpkgsums`), and triggers new builds.
- **Release Pruning:** Older superseded package archives are automatically pruned upon upgrade.

---

## 📜 License

Packaging configurations, launchers, and automation scripts are released under the [MIT License](LICENSE). Packaged software is subject to its respective upstream licenses.
