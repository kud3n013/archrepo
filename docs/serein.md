# Serein (`serein`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.0.0pre.nightly.20261121.100--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-GitHub-informational)](https://github.com/ViceVerse-cz/Serein)

Unofficial native Discord client written in Rust, repackaged from upstream's own nightly Arch build.

---

## 📥 Installation

```bash
sudo pacman -S serein
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `serein` |
| **Current Version** | `1.0.0pre.nightly.20261121.100-1` |
| **Package Type** | **Original (repackaged upstream Arch package)** |
| **Build Status** | `passing` |
| **Upstream Project** | [ViceVerse-cz/Serein](https://github.com/ViceVerse-cz/Serein) |
| **Category** | Chat / Instant Messaging |

---

### Overview
Serein publishes only nightly prereleases (`v1.0.0-nightly.<date>.<n>`). Each one carries an x86_64 Arch package, `serein-<tag>-Linux-arch-serein-<pkgver>-<rel>-x86_64.pkg.tar.zst`, which this package unpacks without changes. The `pkgver` uses upstream's Arch form, `1.0.0pre.nightly.<date>.<n>`, so the eventual `1.0.0` release sorts as newer.

The nightly upstream check (`serein-nightly` in `check-upstream.sh`) takes the newest release that has the Arch asset and reads the version and upstream pkgrel from the asset name, so a new nightly reaches the repository within a day.

The app draws its UI with egui and uses WebKitGTK 6 (`webkitgtk-6.0`) for embedded web content, GStreamer and PulseAudio for voice, and the XDG portal plus PipeWire for screen sharing.

### Changes from upstream's Arch package
- The dependency list is the set of libraries the binary links or loads at runtime, plus the GStreamer plugins and portal it needs. Upstream's list pins about 130 transitive libraries to the versions on its build host.
- `LICENSE-MIT` and `LICENSE-APACHE` are also installed in `/usr/share/licenses/serein/`. The third-party notices stay in `/usr/share/doc/serein/`.
- `provides`/`conflicts` `serein-bin`, and conflicts with `serein-git`.

### Notes
- **Nightly software.** Upstream calls the client experimental, and every build is a nightly.
- **Account risk.** Serein logs in to your normal Discord account through Discord's gateway and REST API. Upstream's README warns that this is outside Discord's Terms of Service and can get the account terminated.
- **Saved logins.** Credentials go to the Secret Service (gnome-keyring or kwallet).
- **Optional media.** `gst-plugins-bad` enables hardware screen encoding and `gst-libav` inline video.
- **Rendering problems.** If embedded web content is blank with some GPU drivers, start it with `WEBKIT_DISABLE_DMABUF_RENDERER=1 serein`.

## 🔗 Related Links

- [ViceVerse-cz/Serein](https://github.com/ViceVerse-cz/Serein)
- [Serein releases](https://github.com/ViceVerse-cz/Serein/releases)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
