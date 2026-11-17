# Lumo (`lumo-desktop`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.5.9--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://proton.me/lumo)

Official desktop app for Lumo, Proton's private AI assistant, repackaged from Proton's Debian package.

---

## 📥 Installation

```bash
sudo pacman -S lumo-desktop
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `lumo-desktop` |
| **Current Version** | `0.5.9-1` |
| **Package Type** | **Original (repackaged upstream .deb)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Lumo](https://proton.me/lumo) |
| **Category** | AI Assistant |

---

### Overview
The package takes `Lumo_<version>_amd64.deb` from `proton.me/download/lumo/linux/`. The nightly upstream check reads the app's own updater manifest, `lumo.protondownload.com/desktop/linux/latest.json`, so a new release reaches the repository within a day. Nothing in the `.deb` is modified.

Lumo is a Tauri application: one native binary that renders through the system WebKitGTK. There is no bundled Chromium, so there is no flags file or Wayland launcher as in the Electron-based Proton packages. The app needs `webkit2gtk-4.1` and `libayatana-appindicator` from the Arch repositories.

### Changes from the upstream `.deb`
- The 256 px icon, which the `.deb` files under the invalid `256x256@2` directory, is installed in `hicolor/256x256`.
- Upstream's `lumo.desktop` is installed as is. It registers the `proton-lumo://` handler used by the browser sign-in flow.

### Notes
- **Tray.** GNOME needs the AppIndicator extension (`gnome-shell-extension-appindicator`).
- **Sign-in storage.** Credentials are kept in the Secret Service (gnome-keyring or kwallet).
- **Rendering problems.** If the window is blank or glitchy with some GPU drivers, start it with `WEBKIT_DISABLE_DMABUF_RENDERER=1 lumo-desktop`.
- **License.** Proton ships no license text with the package; it is listed as `custom:Commercial`.

## 🔗 Related Links

- [Lumo](https://proton.me/lumo)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
