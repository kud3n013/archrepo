# Windows 11 Fonts (`ttf-ms-win11`)

[![status](https://img.shields.io/badge/status-build%20locally-lightgrey)](#-installation)
[![version](https://img.shields.io/badge/version-10.0.26200.9445--1-blue)](../local/ttf-ms-win11/PKGBUILD)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-AUR-informational)](https://aur.archlinux.org/packages/ttf-ms-win11)

Microsoft's Windows 11 TrueType fonts (Segoe UI, Calibri, Cambria, Consolas, Arial, Times New Roman, Yu Gothic, Microsoft YaHei and more), split into the same eight packages as the AUR.

> [!IMPORTANT]
> This package is **not** in the archrepo pacman repository and `sudo pacman -S ttf-ms-win11` will not find it. Microsoft's font license does not allow redistributing the fonts, so CI never builds it and no binary is published. You build it yourself, from your own copy of Windows 11.

---

## 📥 Installation

1. Get the fonts from one of:
   - the Windows 11 ISO, free from [microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11)
   - `sources/install.wim` or `sources/install.esd` from that ISO
   - an installed Windows 11 (a mounted Windows partition, or `C:\Windows\Fonts` copied over with `C:\Windows\System32\Licenses\neutral\_Default\Core\license.rtf` next to the fonts)

2. Extract them next to the PKGBUILD and build:
   ```bash
   sudo pacman -S --needed git base-devel 7zip wimlib
   git clone https://github.com/kud3n013/archrepo.git
   cd archrepo/local/ttf-ms-win11
   ./extract-fonts.sh ~/Downloads/Win11_25H2_English_x64.iso
   makepkg -si
   ```

   `makepkg -si` installs all eight packages. To install only some, build with `makepkg -s` and pick them:
   ```bash
   sudo pacman -U ttf-ms-win11-1*.pkg.tar.zst ttf-ms-win11-{japanese,zh_cn}-*.pkg.tar.zst
   ```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Names** | `ttf-ms-win11`, `-japanese`, `-korean`, `-sea`, `-thai`, `-zh_cn`, `-zh_tw`, `-other` |
| **Current Version** | `10.0.26200.9445-1` (Windows 11 25H2) |
| **Package Type** | **Original** |
| **Build Status** | Local build only, never published |
| **Upstream Project** | [AUR ttf-ms-win11](https://aur.archlinux.org/packages/ttf-ms-win11) |
| **License** | custom (Microsoft EULA, `license.rtf`) |
| **Category** | Fonts |

---

### Overview
The PKGBUILD is the AUR's, unchanged apart from its header, its missing-file message and a quoting fix in `DLAGENTS`: the same font lists, split packages, `provides`/`conflicts` and pinned SHA-256 sums. archrepo adds `extract-fonts.sh`, which fills the folder from an ISO, a WIM/ESD or a Windows folder so the AUR's manual `wimextract` step is not needed.

### Packaging Details
- **Location**: [`local/ttf-ms-win11/`](../local/ttf-ms-win11/). CI only builds `packages/*`, so nothing under `local/` is built or published. A `.gitignore` there keeps `*.ttf`, `*.ttc` and `license.rtf` out of git.
- **extract-fonts.sh** reads the font list from the PKGBUILD's arrays, unpacks `sources/install.wim` (or `.esd`) from the ISO with 7-Zip, pulls `Windows/Fonts/*.tt[fc]` and the edition's `license.rtf` from image 1 with `wimextract`, and copies only the files the PKGBUILD lists. An ISO needs about 5 GiB of free space in `$TMPDIR` while it runs.
- **Checksums** are pinned for build `10.0.26200.9445`. The script prints the build it found in the image; when it differs, build with `makepkg -si --skipchecksums` or run `updpkgsums` first.
- **Conflicts**: `ttf-ms-fonts`, `ttf-tahoma`, `ttf-vista-fonts` and the matching `ttf-ms-win8`/`ttf-ms-win10`/`ttf-win7-fonts` packages, as in the AUR. The main package also provides `emoji-font` (Segoe UI Emoji).
- **Installed path**: `/usr/share/fonts/TTF/`, license in `/usr/share/licenses/<pkgname>/license.rtf`.
- **Updates**: none automatic. Bump `pkgver` and the sums by hand (or follow the AUR) when you want fonts from a newer Windows build.

---

## 🔗 Related Links

- [AUR ttf-ms-win11](https://aur.archlinux.org/packages/ttf-ms-win11)
- [ArchWiki: Microsoft fonts](https://wiki.archlinux.org/title/Microsoft_fonts)
- [Back to archrepo README](../README.md)
