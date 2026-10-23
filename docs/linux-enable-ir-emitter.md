# linux-enable-ir-emitter (`linux-enable-ir-emitter`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-7.0.0beta2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-github-informational)](https://github.com/EmixamPP/linux-enable-ir-emitter)

Turns on the infrared emitter of IR cameras that Linux recognises but leaves dark, so Howdy (or anything else using the IR camera) can see in the dark. This package tracks the **v7 beta**.

---

## 📥 Installation

```bash
sudo pacman -S linux-enable-ir-emitter
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `linux-enable-ir-emitter` |
| **Current Version** | `7.0.0beta2-1` (upstream `7.0.0-beta2`, release tag `7.0.0-beta`) |
| **Package Type** | **Original** |
| **Build Status** | `passing` |
| **Upstream Project** | [EmixamPP/linux-enable-ir-emitter](https://github.com/EmixamPP/linux-enable-ir-emitter) |
| **Category** | System Utility |

---

### Overview
Version 7 is a full Rust rewrite with a terminal UI for the configuration search, a camera preview while it runs, and fully rootless operation. OpenCV is no longer needed. The package installs upstream's prebuilt x86-64 release binary to `/usr/bin/linux-enable-ir-emitter`.

### Packaging notes
- **Beta channel**: the nightly upstream check reads every release, prereleases included, and takes the newest one that ships the x86-64 binary. Pacman versions drop the hyphen (`7.0.0-beta2` becomes `7.0.0beta2`) so a beta sorts before the final `7.0.0`, which the check will pick up when it is published.
- **Tag and version tracked apart**: upstream's `7.0.0-beta` tag ships a `7.0.0-beta2` binary, so the PKGBUILD keeps the tag in `_reltag` and the check updates both.
- **No v6 migration**: v7 cannot read v6 configurations. Upgrading from a v6 package prints a reminder to run `configure` again.

---

## ⚙️ Setup

1. In a large terminal, as your normal user:
   ```bash
   linux-enable-ir-emitter configure
   ```
   Choose **IR Enabler** and answer the prompts. The result is saved to `~/.config/linux-enable-ir-emitter.toml`, with logs in `~/.local/state/linux-enable-ir-emitter.log`. If the automatic search fails, retry with **Manual mode** enabled.
2. For Howdy (`howdy-next`), add this line **before** the howdy line in every file listed by `grep -rl howdy /etc/pam.d`, replacing `<USER>`:
   ```
   auth optional pam_exec.so /usr/bin/linux-enable-ir-emitter run --config /home/<USER>/.config/linux-enable-ir-emitter.toml
   ```
   PAM runs it as root, so the `--config` path is required.

> [!WARNING]
> Upstream warns that the configuration search can corrupt camera firmware. Use it at your own risk.

## 🔗 Related Links

- [Upstream Repository](https://github.com/EmixamPP/linux-enable-ir-emitter)
- [`howdy-next`](howdy-next.md)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
