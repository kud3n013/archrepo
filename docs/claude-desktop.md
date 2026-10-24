# Claude Desktop (`claude-desktop`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.6556.2--2-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#native-title-bar)
[![upstream](https://img.shields.io/badge/upstream-anthropic-informational)](https://claude.ai/download)

Official Claude desktop app from Anthropic (Chat, Cowork and Claude Code), repackaged for Arch from Anthropic's official amd64 Debian package. The launcher selects native Wayland (on KDE Plasma it uses XWayland for the Global Menu, see below), and the Cowork virtual machine stack is installed and wired up for Arch's file layout.

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
| **Current Version** | `3.6556.2-2` |
| **Package Type** | **Modified (repackaged upstream .deb, native window title bar, theme sync)** |
| **Build Status** | `passing` |
| **Upstream Project** | [Claude Desktop](https://claude.ai/download) |
| **Category** | Productivity / AI Assistant |
| **Electron Runtime** | 44.7.2 |

---

### Overview
The package takes the `amd64` `.deb` from `downloads.claude.ai/claude-desktop/apt/stable`, verified against the repository's signed index (SHA256 in the `Packages` stanza). It keeps the application tree and the Debian payload files it needs, and drops the Debian install scripts. The one change inside `app.asar` is a small bootstrap that asks for the window manager's title bar. See [Native title bar](#native-title-bar).

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
- **Native title bar** (`titlebar-bootstrap.js`, added to `app.asar`). See the section below.
- **Global Menu** on KDE Plasma: the launcher uses XWayland, and the bootstrap hides the in-page menu button. See the Global Menu section below.
- **Theme sync and tray icon** (`theme-sync.js`, added to `app.asar`): the app follows the desktop's light/dark setting live, and the tray icon contrasts with the panel. See the Theme sync section below.

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

### Native title bar
Upstream's Linux build creates its windows frameless (`titleBarStyle` `"hidden"` for the main window and `"hiddenInset"` for About) and draws its own title bar. The window manager's decoration theme, button layout and title bar actions therefore do not apply. This package changes that for the app's normal windows.

What the bootstrap does on Linux:
- `package.json` `main` points to `archrepo-bootstrap.js`, which runs first and then loads the app's original entry point. The patch is applied at build time by `patch-titlebar.js`, which fails the build if the entry point is missing or the tree is already patched.
- Normal app windows (main, About, popouts and dialogs) request the window manager's frame. `titleBarStyle`, `titleBarOverlay` and `trafficLightPosition` are removed for them, and `autoHideMenuBar` is set so no Electron menu bar appears under the frame.
- `setTitleBarOverlay()` becomes a no-op. It is a Windows-only call that the app makes on every window, and it throws on Linux.
- Quick Entry, the Cowork glow and the small indicator window stay frameless. They set `frame: false`, `transparent` or `alwaysOnTop`, so the rule above does not match them.
- Each framed window logs one line to stderr: `[archrepo] native frame for window "<title>"`.
- The claude.ai view is told the window is always fullscreen. claude.ai keeps the top right of its header free for the window buttons that `titleBarOverlay` draws (120 px on Linux) and gives that space back only in fullscreen. With the native frame those buttons are gone, so without this the header buttons stop 120 px short of the right edge, in a chat and on the new chat page. The bootstrap answers the page's `WindowState` `getFullscreen` call with `true` and rewrites its `fullscreenChanged` event to `true`. In this claude.ai build the page uses that state only for the window button space.

**Opt out:** start the app with `CLAUDE_DESKTOP_CSD=1` (for example `CLAUDE_DESKTOP_CSD=1 claude-desktop`) to get upstream's frameless window back.

**Desktop behaviour:**
- On KDE Plasma (Wayland or X11), the window manager draws the frame when the app requests one. This is the intended result, but it has not been checked on a live Plasma session.
- On compositors without server-side decorations (GNOME), Electron draws its own fallback frame.

**Upstream reports this addresses:**
- [anthropics/claude-code#81497](https://github.com/anthropics/claude-code/issues/81497): untitled orphan windows and the Linux `titleBarOverlay` call. The issue is closed upstream. The overlay call is now a no-op in this package.
- [anthropics/claude-code#90742](https://github.com/anthropics/claude-code/issues/90742): minimize bounces back on Plasma. Still open upstream. Not verified here: this package does not change how minimize is handled.
- [anthropics/claude-code#96913](https://github.com/anthropics/claude-code/issues/96913): the window menu from the in-page title bar freezes input on Cinnamon X11. Still open upstream. The in-page bar is still drawn, so this is not fixed by this package.

### Global Menu
On KDE Plasma the launcher runs the app under XWayland (`--ozone-platform=x11`), so the app menu appears in the Plasma Global Menu widget. Electron exports the menu over D-Bus on native Wayland too, but nothing binds it to the window there, so Plasma shows no menu. Upstream Electron PR [#54629](https://github.com/electron/electron/pull/54629) (fixes [#34335](https://github.com/electron/electron/issues/34335)) is open for that. Under XWayland the window has an X id that the Plasma registrar matches.

- The launcher pins the GTK3 modules with `LD_PRELOAD`, the same way the `antigravity` and `beeper` packages do. Without it Electron's `dlclose()` of GTK crashes under XWayland.
- The bootstrap injects a CSS rule that hides the in-page menu button (`aria-label="Menu"`, in claude.ai's top bar). It is injected only while the Global Menu path is active.
- **Opt out:** `CLAUDE_DESKTOP_GLOBALMENU=0` keeps native Wayland and the in-page menu button.
- **Trade-off:** XWayland is blurry on scaled displays. That is why native Wayland was the default before this change.

**Not verified:**
- The menu in the Plasma Global Menu widget on a live session. On a test instance on the real session, the Plasma registrar registered the window, and the exported menu returned File, Edit and the other top-level items over D-Bus. Seeing it in the widget itself was not checked.
- The in-page button is hidden on the claude.ai login page only. Signed-in pages were not checked.

**Electron fuses:** the package does not change any fuse. `EnableEmbeddedAsarIntegrityValidation` is on in this build. In a test on Linux (Electron 44.7.2), a repacked `app.asar` still started, so the bootstrap loads on this platform.

**Not verified:**
- The header layout after the fullscreen change was checked by reading the bundled claude.ai frontend and by checking, in a test run, that the claude.ai view gets `true` from `getFullscreen` and from `fullscreenChanged` while the window is not fullscreen. The signed-in header itself was not seen, because no account was available.
- Quick Entry staying frameless was checked by reading its window options, not by opening it.
- Upgrading over the AUR `claude-desktop` 2.42304.0-1 package was not tested.

### Theme sync and tray icon
`theme-sync.js` is added to `app.asar` as `archrepo-theme-sync.js` and loaded by the bootstrap. It does two things.

**Live light/dark.** It reads `org.freedesktop.appearance color-scheme` from the XDG portal and follows the portal's `SettingChanged` signal (a `gdbus monitor` child; `gdbus` comes with `glib2`). While the app's own theme choice is "system", the real `nativeTheme.themeSource` is set to `dark` or `light` to match. Chromium is meant to notice the change by itself, but under XWayland, which this package uses on KDE, it stops after the first change ([anthropics/claude-code#77171](https://github.com/anthropics/claude-code/issues/77171)).
- An in-app Light or Dark choice still wins. The app reads back the value it set, and only "system" follows the desktop.
- Colour scheme `0` ("no preference") counts as light, as the portal spec says.
- Without a portal answer, the start value comes from `kdeglobals` on KDE, then `gsettings`.

**Tray icon.** Upstream picks `TrayIconLinux.png` (dark glyph) or `TrayIconLinux-Dark.png` (light glyph) from the window colour scheme, so a light colour scheme with a dark panel gets a dark glyph on a dark panel ([anthropics/claude-code#77170](https://github.com/anthropics/claude-code/issues/77170)). On KDE Plasma (Breeze Twilight, or any dark Plasma style) the tray icon is now picked from the panel:
- The Plasma style comes from `~/.config/plasmarc`. A style with its own `colors` file (`breeze-dark`, `breeze-light`, most third-party styles) uses that file's window background. The default Breeze style follows the colour scheme in `kdeglobals`.
- `plasmarc` and `kdeglobals` are watched, so changing the Plasma style or colour scheme swaps the icon without a restart.
- Cinnamon uses `gsettings get org.cinnamon.theme name`. GNOME and other desktops keep upstream's choice (GNOME's top bar is always dark and upstream already handles it).
- **Override:** `CLAUDE_DESKTOP_TRAY_PANEL=dark` or `=light` names the panel colour yourself.
- The build fails if a version bump renames the two tray icons.

**GTK module pinning.** Under X11 or XWayland, GTK loads the modules named in XSETTINGS, and Electron's `dlclose()` of GTK leaves their callbacks registered, so a theme change crashes the app. The launcher pins `/usr/lib/gtk-3.0/modules/*.so` with `LD_PRELOAD` whenever the app runs on X11: the Global Menu path, an `--ozone-platform=x11` flag, or an X11 session. Native Wayland is left alone.

**Opt out:** `CLAUDE_DESKTOP_THEME_SYNC=0` leaves the theme and the tray icon to upstream.

**Logging:** one `[archrepo] theme sync: ...` line on start and on each change, and a `[archrepo] tray: panel is ...` line when the panel colour changes.

**Not verified:** the official `.deb` could not be downloaded where this was written, so the module was tested against a mock of Electron (`themeSource` accessor, a native-style `Tray`, a fake `gdbus` and fake Plasma config), not in the real app. Check on a live Plasma session:
- with Breeze Twilight (light windows, dark panel) the tray glyph is light;
- switching Breeze Light ↔ Breeze Dark in System Settings changes the app and the tray within a second, many times in a row, without a crash;
- the in-app theme choice still wins, and `CLAUDE_DESKTOP_THEME_SYNC=0` turns all of it off.

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
