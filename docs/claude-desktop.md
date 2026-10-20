# Claude Desktop (`claude-desktop`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-2.42304.2--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-original-blue)](#overview)
[![upstream](https://img.shields.io/badge/upstream-anthropic-informational)](https://claude.ai/download)

Official Claude desktop app from Anthropic (Chat, Cowork and Claude Code), repackaged for Arch from Anthropic's official amd64 Debian package. The launcher selects native Wayland, and the Cowork virtual machine stack is installed and wired up for Arch's file layout.

> **Unofficial packaging.** Anthropic publishes this app as a `.deb` in its own apt repository and does not ship an Arch package. Its Linux docs cover Ubuntu 22.04+ and Debian 12+ and tell Arch users to run the CLI instead. This is an unsupported repackaging of that `.deb`.

---

## 📥 Installation

```bash
sudo pacman -S claude-desktop
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `claude-desktop` |
| **Current Version** | `2.42304.2-1` |
| **Package Type** | **Original (repackaged upstream .deb)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Claude Desktop](https://claude.ai/download) |
| **Category** | Productivity / AI Assistant |
| **Electron Runtime** | 44.7.2 |

---

### Overview
The package takes the `amd64` `.deb` from `downloads.claude.ai/claude-desktop/apt/stable`, verified against the repository's signed index (SHA256 in the `Packages` stanza). It keeps the application tree and the Debian payload files it needs, and drops the Debian install scripts. Nothing inside `app.asar` is patched.

Upstream's Linux app does not update itself. Anthropic's docs say updates arrive through the system package manager, which is why this package has a nightly upstream check against the apt index.

### Changes from the upstream `.deb`
- **Application tree** is installed to `/opt/claude-desktop`, with a compatibility symlink at `/usr/lib/claude-desktop`. The GNOME search-provider D-Bus service refers to that path.
- **Launcher** `/usr/bin/claude-desktop` replaces upstream's bare symlink. It selects native Wayland and reads the flags file (see below).
- **Desktop entry** `com.anthropic.Claude.desktop` is upstream's file, unchanged. Its `StartupWMClass` and `claude://` handler are already correct.
- **Cowork shims**. The app probes fixed Debian paths for the Cowork VM stack. This package adds the links it looks for:
  - `/usr/bin/virtiofsd` → `/usr/lib/virtiofsd` (from the `virtiofsd` package)
  - `/usr/share/edk2/OVMF_CODE_4M.fd` and `OVMF_VARS_4M.fd` → the `x64/*.4m.fd` firmware files from `edk2-ovmf`. The app reaches these through `/usr/share/OVMF`, which is a compat symlink owned by `edk2-ovmf`.
- **GNOME search provider** and **MIME types** for `.mcpb`, `.dxt` and `.skill` are installed as package files. Upstream's `postinst` copies the same files into `/usr/share` on install.
- **Licenses** are installed to `/usr/share/licenses/claude-desktop/`.

### Not shipped from the `.deb`
- **Maintainer scripts** (`control.tar.xz`) are not used:
  - **apt repository registration.** Arch users get updates through `pacman`, so no `/etc/apt` source, keyring or unattended-upgrades snippet is written.
  - **AppArmor profile** in `/etc/apparmor.d/`. Arch does not enable the Ubuntu user-namespace restriction it works around.
  - **`/usr/bin/ccd` link.** This build does not include the `ccd` launcher, so there is nothing to link.
- **`/usr/share/lintian`** overrides.
- **Upstream's `/usr/bin/claude-desktop` symlink**, replaced by the launcher.

### Desktop Environment Notes
- **Wayland**: the launcher adds `--ozone-platform-hint=auto --enable-wayland-ime` in a Wayland session, unless a `--ozone-platform` flag is already set. Quick Entry's GlobalShortcuts portal is enabled by the app itself at startup.
- **Application menu**: the app builds an Electron application menu, but it hides the menu bar in each window. A KDE Global Menu export would be a separate change. It is not part of this package.
- **App launcher entries**: the app copies its desktop entry to `~/.local/share/applications/` at startup, marked `X-Claude-Generated=true`. Uninstalling or upgrading the package removes only those marked copies. The app writes a fresh one on the next start.

---

## ⚠️ Linux beta limitations

These are the limits Anthropic documents for the Linux beta:

- **Computer Use** is not available on Linux.
- **Dictation** is not available on Linux.
- **Quick Entry** (global hotkey) works on X11. On native Wayland it needs the desktop's GlobalShortcuts portal, which KDE Plasma 5.27+ and GNOME 43+ provide.

---

## 🖥️ Cowork (virtual machine) setup

Cowork runs a QEMU/KVM virtual machine. The package depends on `qemu-system-x86`, `edk2-ovmf` and `virtiofsd`. Your system also needs:

1. **Virtualization enabled in firmware** (Intel VT-x or AMD-V). `/dev/kvm` must exist.
2. **Your user in the `kvm` group**, then log out and back in:
   ```bash
   sudo usermod -aG kvm "$USER"
   ```
3. **The `vhost_vsock` kernel module**, which provides `/dev/vhost-vsock` for the host-to-VM channel. If Cowork reports it missing, load it now:
   ```bash
   sudo modprobe vhost_vsock
   ```
   To load it on every boot:
   ```bash
   echo vhost_vsock | sudo tee /etc/modules-load.d/vhost_vsock.conf
   ```

The package does not change groups or kernel modules itself. The post-install message repeats these steps.

Anthropic's Linux docs do not list disk or RAM requirements for Cowork, so check your own headroom before enabling it.

---

## 🔐 Sign-in keyring

Sign-in is stored through the Secret Service API. Install one keyring and keep only that one running:

- **GNOME**: `gnome-keyring`
- **KDE Plasma**: `kwallet`

Having both on KDE Plasma can stop sign-in from being saved. The app selects `kwallet` on KDE Plasma unless `--password-store` is set.

---

## ⚙️ Configuration & Flags

Configuration file: `~/.config/claude-desktop-flags.conf` (falls back to `/etc/claude-desktop-flags.conf`). One flag per line, `#` starts a comment, and whitespace around each line is trimmed.

```bash
# Display backend. Native Wayland is the default in a Wayland session.
# --ozone-platform=x11

# High-DPI UI scaling factor
# --force-device-scale-factor=1.5

# Password store backend (gnome-libsecret, kwallet6, basic)
# --password-store=basic
```

The launcher runs `/opt/claude-desktop/claude-desktop` with these flags, followed by any command-line arguments, so `claude://` links from desktop actions pass straight through.

---

## 🔗 Related Links

- [Upstream: Claude Desktop download](https://claude.ai/download)
- [Upstream: Linux desktop documentation](https://code.claude.com/docs/en/desktop-linux)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
