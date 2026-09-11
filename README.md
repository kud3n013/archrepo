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
sudo pacman -S zalo-for-linux-bin
sudo pacman -S proton-mail-bin
sudo pacman -S proton-pass-bin
sudo pacman -S beeper-bin
sudo pacman -S freedownloadmanager-bin
sudo pacman -S freedownloadmanager-elephant-bin
sudo pacman -S howdy-next-bin
```

---

## 📦 Available Packages

| Package | Upstream | Description | Installation |
|---|---|---|---|
| **`zalo-for-linux-bin`** | [doandat943/zalo-for-linux](https://github.com/doandat943/zalo-for-linux) | Unofficial Zalo desktop client for Linux with **Wayland / Hyprland scaling fixes** and bundled AUR logo. | `sudo pacman -S zalo-for-linux-bin` |
| **`proton-mail-bin`** | [Proton Mail Linux Beta](https://proton.me/mail) | Official desktop application for Proton Mail and Proton Calendar, integrated with system Electron. | `sudo pacman -S proton-mail-bin` |
| **`proton-pass-bin`** | [Proton Pass Linux](https://proton.me/pass) | Official desktop application for Proton Pass: end-to-end encrypted password and identity manager. | `sudo pacman -S proton-pass-bin` |
| **`beeper-bin`** | [Automattic / Beeper](https://www.beeper.com/changelog) | The ultimate messaging app (formerly Beeper v4) with Wayland Ozone auto-hinting and clean desktop integration. | `sudo pacman -S beeper-bin` |
| **`freedownloadmanager-bin`** | [Free Download Manager](https://www.freedownloadmanager.org/) | Fast and powerful modern download accelerator and organizer with Qt6 Wayland/X11 support and BitTorrent integration. | `sudo pacman -S freedownloadmanager-bin` |
| **`freedownloadmanager-elephant-bin`** | [meowcateatrat/elephant](https://github.com/meowcateatrat/elephant) | Free Download Manager add-on for downloading videos from various sites (powered by yt-dlp). | `sudo pacman -S freedownloadmanager-elephant-bin` |
| **`howdy-next-bin`** | [howdy-next](https://codeberg.org/nathawat/howdy-next) | C++ facial-recognition authentication for Linux (PAM). Patched build: suppresses noisy OpenCV 5 DNN warnings. | `sudo pacman -S howdy-next-bin` |

---

## ⚙️ Architecture & Features

### 1. Dual-Tier Storage Architecture
- **GitHub Releases (`packages` tag):** Stores binary packages (`.pkg.tar.zst`) and pacman databases (`archrepo.db`, `archrepo.files`). This bypasses GitHub's 100 MB repository limit and supports packages up to 2 GB (such as `zalo-for-linux-bin` at ~260 MB).
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
gh workflow run build.yml -f package=zalo-for-linux-bin

# Force a clean rebuild even if the binary already exists
gh workflow run build.yml -f package=zalo-for-linux-bin -f force_rebuild=true
```

---

## 📜 License

The packaging scripts, automation workflows, and repository configurations are released under the [MIT License](LICENSE). Packaged software is subject to its respective upstream licenses.
