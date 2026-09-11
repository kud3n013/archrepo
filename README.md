# archrepo 📦

[![Build & Publish Arch Packages](https://github.com/kud3n013/archrepo/actions/workflows/build.yml/badge.svg)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![GitHub Pages](https://img.shields.io/badge/docs-GitHub%20Pages-blue)](https://kud3n013.github.io/archrepo/)
[![GitHub Release](https://img.shields.io/github/v/release/kud3n013/archrepo?label=packages)](https://github.com/kud3n013/archrepo/releases/tag/packages)

A fully automated, self-updating Arch Linux binary package repository hosted on GitHub. Packages are built in isolated `archlinux:base-devel` containers, verified, and published directly to pacman-compatible endpoints.

---

## 🚀 Quick Setup

Add this repository to your system's `/etc/pacman.conf`:

```ini
[archrepo]
SigLevel = Optional TrustAll
Server = https://github.com/kud3n013/archrepo/releases/download/packages
```

### One-liner:

```bash
echo -e '\n[archrepo]\nSigLevel = Optional TrustAll\nServer = https://github.com/kud3n013/archrepo/releases/download/packages' | sudo tee -a /etc/pacman.conf
```

Synchronize the package databases:

```bash
sudo pacman -Syy
```

Now you can install any package using standard `pacman`:

```bash
sudo pacman -S zalo-for-linux
sudo pacman -S beeper
sudo pacman -S antigravity
sudo pacman -S freedownloadmanager-elephant
sudo pacman -S howdy-next
sudo pacman -S zotero-better-bibtex
sudo pacman -S zotmoov
sudo pacman -S zotero-better-notes
sudo pacman -S zotero-ocr
sudo pacman -S zotero-pdf-translate
sudo pacman -S zotero-mcp
sudo pacman -S gdlauncher-carbon
sudo pacman -S searxng
```

---

## 📦 Available Packages

| Package | Upstream | Description | Installation |
|---|---|---|---|
| **`zalo-for-linux`** | [doandat943/zalo-for-linux](https://github.com/doandat943/zalo-for-linux) | Unofficial Zalo desktop client for Linux with **Wayland / Hyprland scaling fixes** and bundled AUR logo. | `sudo pacman -S zalo-for-linux` |
| **`beeper`** | [Automattic / Beeper](https://www.beeper.com/changelog) | The ultimate messaging app (formerly Beeper v4) with Wayland Ozone auto-hinting and clean desktop integration. | `sudo pacman -S beeper` |
| **`antigravity`** | [Google Antigravity](https://antigravity.google) | Google Antigravity 2.0 multi-agent orchestration platform with native Wayland support and configurable flags. | `sudo pacman -S antigravity` |
| **`freedownloadmanager-elephant`** | [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant) | Free Download Manager add-on for downloading videos from various sites (powered by yt-dlp). | `sudo pacman -S freedownloadmanager-elephant` |
| **`howdy-next`** | [howdy-next](https://codeberg.org/nathawat/howdy-next) | C++ facial-recognition authentication for Linux (PAM). Patched build: suppresses noisy OpenCV 5 DNN warnings. | `sudo pacman -S howdy-next` |
| **`zotero-better-bibtex`** | [retorquere/zotero-better-bibtex](https://github.com/retorquere/zotero-better-bibtex) | Better BibTeX for Zotero - LaTeX bibliography and citation management. Auto-installed via distribution extensions. | `sudo pacman -S zotero-better-bibtex` |
| **`zotmoov`** | [wileyyugioh/zotmoov](https://github.com/wileyyugioh/zotmoov) | ZotMoov - moves attachments to directories based on collection/item rules. Auto-installed via distribution extensions. | `sudo pacman -S zotmoov` |
| **`zotero-better-notes`** | [windingwind/zotero-better-notes](https://github.com/windingwind/zotero-better-notes) | Better Notes for Zotero - comprehensive note taking and management. Auto-installed via distribution extensions. | `sudo pacman -S zotero-better-notes` |
| **`zotero-ocr`** | [UB-Mannheim/zotero-ocr](https://github.com/UB-Mannheim/zotero-ocr) | Optical Character Recognition for Zotero PDFs (patched with default Arch tesseract/poppler paths). | `sudo pacman -S zotero-ocr` |
| **`zotero-pdf-translate`** | [windingwind/zotero-pdf-translate](https://github.com/windingwind/zotero-pdf-translate) | Translate for Zotero - translates PDFs, EPubs, webpages, and annotations via 20+ translation services. | `sudo pacman -S zotero-pdf-translate` |
| **`zotero-mcp`** | [54yyyu/zotero-mcp](https://github.com/54yyyu/zotero-mcp) | Model Context Protocol (MCP) server & standalone CLI (`zotero-mcp`, `zotero-cli`) for Zotero. | `sudo pacman -S zotero-mcp` |
| **`gdlauncher-carbon`** | [GDLauncher](https://gdlauncher.com) | GDLauncher Carbon: powerful Minecraft custom launcher (Electron, Wayland-ready) with ozone auto-hinting and clean uninstallation. | `sudo pacman -S gdlauncher-carbon` |
| **`searxng`** | [searxng/searxng](https://searxng.github.io/searxng/) | A privacy-respecting, hackable metasearch engine with systemd service and Valkey integration. | `sudo pacman -S searxng` |


---

## 🗄️ Archived Packages

The following packages have been retired from the active repository and are no longer installable via `pacman`. Their packaging recipes and configurations are preserved in [`archive/`](archive/):

| Package | Upstream | Location | Status |
|---|---|---|---|
| **`freedownloadmanager`** | [Free Download Manager](https://www.freedownloadmanager.org/) | [`archive/freedownloadmanager`](archive/freedownloadmanager/) | Archived |
| **`proton-mail`** | [Proton Mail Linux Beta](https://proton.me/mail) | [`archive/proton-mail`](archive/proton-mail/) | Archived |
| **`proton-pass`** | [Proton Pass Linux](https://proton.me/pass) | [`archive/proton-pass`](archive/proton-pass/) | Archived |

---

## ⚙️ Architecture & Features

### 1. Dual-Tier Storage Architecture
- **GitHub Releases (`packages` tag):** Stores binary packages (`.pkg.tar.zst`) and pacman databases (`archrepo.db`, `archrepo.files`). This bypasses GitHub's 100 MB repository limit and supports packages up to 2 GB (such as `zalo-for-linux` at ~260 MB).
- **GitHub Pages:** Hosts the repository landing page and documentation at [kud3n013.github.io/archrepo](https://kud3n013.github.io/archrepo/).

### 2. Smart Build Caching & Skip Logic
- Before compiling any package, the workflow queries the latest release assets.
- If the exact target package `${pkgname}-${pkgver}-${pkgrel}-x86_64.pkg.tar.zst` is already published, `makepkg` is **skipped** and the prebuilt binary is reused in seconds.
- Only newly added packages or packages with upstream version updates are compiled.

### 3. Automatic Upstream Tracking
- A daily cron job (`0 4 * * *`) checks upstream release channels:
  - GitHub releases (via GitHub API)
  - Codeberg releases (via Gitea API)
  - HTTP redirects (via redirect headers)
- When a new version is detected, the workflow automatically:
  1. Updates `pkgver` and commit hashes in `PKGBUILD`.
  2. Regenerates checksums (`updpkgsums`) and `.SRCINFO`.
  3. Commits changes back to `main`.
  4. Compiles and publishes the updated package.

### 4. Automatic Release Pruning
- Whenever a package version is bumped, older superseded `.pkg.tar.zst` files are automatically removed from the release to keep storage clean and avoid duplicate assets.

---

## 🛠️ Adding a New Package

1. Create a new directory for the package on the `main` branch:
   ```bash
   mkdir my-package
   ```

2. Add your `PKGBUILD` and any launcher scripts, patches, or desktop files:
   ```bash
   touch my-package/PKGBUILD
   ```

3. Register the package in [`.github/workflows/build.yml`](.github/workflows/build.yml) under `matrix.package`:
   ```yaml
   matrix:
     package:
       - name: my-package
         upstream_repo: "owner/repo"           # if tracking GitHub releases
         upstream_check: "github-release"      # or custom check
   ```

4. Commit and push:
   ```bash
   git add my-package/ .github/workflows/build.yml
   git commit -m "feat: add my-package"
   git push origin main
   ```

The pipeline will automatically build the package in an Arch Linux container, update the database, and publish it to the repository.

---

## 🎯 Manual Triggers & Selective Builds

You can trigger builds manually with fine-grained control via **GitHub Actions** → **Build & Publish Arch Packages** → **Run workflow**, or via the `gh` CLI:

```bash
# Build only a single package without touching others
gh workflow run build.yml -f package=zalo-for-linux

# Force a clean rebuild even if the binary already exists
gh workflow run build.yml -f package=zalo-for-linux -f force_rebuild=true
```

---

## 📜 License

The packaging scripts, automation workflows, and repository configurations are released under the [MIT License](LICENSE). Packaged software is subject to its respective upstream licenses.
