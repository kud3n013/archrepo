# Katlendar (`katlendar`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-0.1.0beta.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-GitHub-informational)](https://github.com/kud3n013/katlendar)

Fast, local-first desktop calendar and task planner written in Rust, repackaged from upstream's prebuilt Linux tarball.

---

## 📥 Installation

```bash
sudo pacman -S katlendar
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `katlendar` |
| **Current Version** | `0.1.0beta.2-1` |
| **Package Type** | **Original (repackaged upstream binary)** |
| **Build Status** | `passing` |
| **Upstream Project** | [kud3n013/katlendar](https://github.com/kud3n013/katlendar) |
| **Category** | Office / Calendar |

---

### Overview
Katlendar is a calendar and task planner with time blocking, frames, an automatic planner, `.ics` subscriptions and two-way sync with Google, Microsoft 365, Nextcloud, CalDAV and Proton. Everything stays in one local JSON data file (`~/.local/share/katlendar/data.json`); no account is needed.

Each upstream release carries `katlendar-<version>-linux-x86_64.tar.gz`, which holds the binary, desktop entry, 512 px icon, README and license. This package installs them without changes. The UI is drawn with egui over OpenGL and runs natively on Wayland and X11.

Upstream is in beta and every release is a prerelease, so the `katlendar-prerelease` check in `check-upstream.sh` takes the newest release instead of `/releases/latest`. The tag `v0.1.0-beta.2` becomes `pkgver` `0.1.0beta.2`, so the final `0.1.0` sorts as newer. If the newest release lacks the Linux tarball, the check fails instead of falling back to an older one.

### Notes
- **Beta software.** Keep a copy of `~/.local/share/katlendar/` before relying on it.
- **Account passwords.** Sync accounts keep their passwords and tokens in the Secret Service, so install `gnome-keyring` or `kwallet` (`org.freedesktop.secrets`).
- **Links and sign-in.** Links and account sign-in pages open through `xdg-open` (`xdg-utils`).
- **Update notice.** The app can tell you when a newer release is out and links to its page. It never replaces itself; pacman installs the update once it is in archrepo.

## 🔗 Related Links

- [kud3n013/katlendar](https://github.com/kud3n013/katlendar)
- [Katlendar website](https://kud3n013.github.io/katlendar/)
- [Katlendar releases](https://github.com/kud3n013/katlendar/releases)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
