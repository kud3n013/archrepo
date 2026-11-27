# AB Download Manager (`ab-download-manager`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.11.4--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-GitHub-informational)](https://github.com/amir1376/ab-download-manager)

Open-source download manager with multi-connection acceleration, queues, speed limits and browser integration.

---

## 📥 Installation

```bash
sudo pacman -S ab-download-manager
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `ab-download-manager` |
| **Current Version** | `1.11.4-1` |
| **Package Type** | **Modified** |
| **Build Status** | `passing` |
| **Upstream Project** | [amir1376/ab-download-manager](https://github.com/amir1376/ab-download-manager) |
| **Category** | Core Application |

---

### Overview
AB Download Manager splits each download over several connections, resumes broken ones, and sorts files into categories and queues with per-download and global speed limits. Browser extensions for Firefox and Chromium-based browsers hand links to the app.

The package repackages upstream's Linux `tar.gz` release. It is a jpackage (Compose Desktop) app image with its own JetBrains Runtime, so it needs no system Java. The app lives in `/opt/ab-download-manager`.

### Modifications in `archrepo`
- **Software rendering by default.** OpenGL rendering shows a black window on many Wayland/XWayland and NVIDIA setups. The `/usr/bin/ab-download-manager` launcher sets `SKIKO_RENDER_API=SOFTWARE` unless the environment already sets it.
- **Flags file.** The launcher reads `~/.config/ab-download-manager-flags.conf`, or `/etc/ab-download-manager-flags.conf` when the user has none. `KEY=VALUE` lines are exported as environment variables (a variable already set wins), and other lines are passed to the app as arguments. Set `SKIKO_RENDER_API=OPENGL` there for GPU rendering.
- **Updates through pacman.** The in-app updater only runs when the installation folder is writable. `/opt/ab-download-manager` is owned by root, so the updater stays off.
- **CLI.** `/usr/bin/ab-download-manager-cli` links to upstream's `ABDownloadManagerCli`, which can add downloads from a terminal (`ab-download-manager-cli --help`).
- **Desktop entry.** The package ships its own entry with the app icon. Install, upgrade and removal delete the user copy that the app's "Create desktop entry" action writes to `~/.local/share/applications`, since that copy shadows the packaged one.

### Notes
- **Data** (settings, the download list, queues and categories) lives in `~/.abdm`.
- **Browser integration.** On start the app writes native messaging manifests for Firefox and Chromium-based browsers (`~/.mozilla/native-messaging-hosts`, `~/.config/<browser>/NativeMessagingHosts`). They point at `/opt/ab-download-manager/bin/ABDownloadManagerNativeMessagingHost`, so they keep working across upgrades. Install the extension from the [upstream website](https://abdownloadmanager.com).
- **Tray icon and notifications** use `libappindicator-gtk3` and `libnotify` when installed.
- **HiDPI.** If the desktop's scale is not picked up, set `_JAVA_OPTIONS=-Dsun.java2d.uiScale=2` in the flags file.

## 🔗 Related Links

- [amir1376/ab-download-manager](https://github.com/amir1376/ab-download-manager)
- [AB Download Manager website](https://abdownloadmanager.com)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
