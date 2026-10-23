# Z-Library (`z-library`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-3.2.1--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#modifications-in-archrepo)
[![upstream](https://img.shields.io/badge/upstream-website-informational)](https://z-lib.fm)

The Z-Library desktop app, packaged from the official Linux x64 tarball with the window manager's title bar, a menu in the KDE Plasma Global Menu, and updates through pacman instead of the app's own updater.

---

## 📥 Installation

```bash
sudo pacman -S z-library
```

It replaces the AUR's `z-library-bin` and conflicts with `z-library-electron`.

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `z-library` |
| **Current Version** | `3.2.1-1` |
| **Package Type** | **Modified** |
| **Upstream Project** | [Z-Library](https://z-lib.fm) |
| **Install Path** | `/opt/z-library` |
| **Launcher** | `/usr/bin/z-library` |
| **Electron** | 30.5.1 (bundled) |

---

## Modifications in `archrepo`

No upstream file is edited. `patch-asar.js` adds `z-library-bootstrap.js` to `app.asar` as `archrepo-bootstrap.cjs` and points `package.json`'s `main` at it; the bootstrap then loads the original `dist-electron/main.js`. The app's main process is an ES module, which Electron hands the `electron` module through its own loader, so the bootstrap registers a module loader hook that gives it the patched `BrowserWindow` and `Menu`.

On Linux the bootstrap:

- **Title bar.** The main window gets the window manager's frame instead of upstream's frameless window. The loading window (a fixed-size splash) stays frameless, and the debug window already has a frame. Window titles stay "Z-Library" instead of the page's placeholder title.
- **Close button.** The frame's close button does what the app's own close button does: it offers to keep the open tabs, saves them and quits.
- **In-page window buttons.** Upstream's Close, Maximize and Minimize buttons at the right of the tab strip are hidden. Tools, settings, notifications, profile, Donate and the vertical tabs button stay.
- **Menu.** Upstream's menu (*Library*: Help; *Edit*: Copy, Paste, Cut, Select All; *Navigation*: Go back `Ctrl+Z`, Jump forward `Ctrl+Y`, Refresh `Ctrl+R`) is kept, with these added:
  - *Library*: Quit (`Ctrl+Q`, same as the close button)
  - *View*: Toggle Full Screen (`F11`)
  - *Window*: Minimize, Maximize
  - *Help*: About

  On KDE the menu appears in the Global Menu; elsewhere it is hidden and Alt shows it.
- **Updates.** The in-app updater (electron-updater, which would install a `.deb`) never reports an update; pacman updates the package.
- **Remote debugging.** Upstream always opens a Chrome DevTools port on `127.0.0.1:9222`, which lets any local process control the signed-in app. It is not opened. Passing `--remote-debugging-port=<port>` yourself still works.
- **Tray.** The app has no tray icon.
- **Theme.** Not changed. The app has its own light/dark switch and applies it to its pages and to Electron (`nativeTheme.themeSource`); it does not follow the desktop. The title bar follows the desktop theme.

The package also leaves out files the app never loads: the Windows builds of Tor, Xray and their transports, the Conjure transport, the bundled OpenSSL (Tor links the system's), and the development copies of Tor and Xray inside `app.asar`. This roughly halves the download.

The launcher (`z-library.sh`):

- reads flags from `~/.config/z-library-flags.conf`, or `/etc/z-library-flags.conf` if the user file is missing;
- on KDE Plasma Wayland runs under XWayland (`--ozone-platform=x11`), the only path where Electron's menu reaches the Global Menu; other Wayland desktops get native Wayland;
- under X11 on KDE, pins the GTK3 modules with `LD_PRELOAD` (Electron's `dlclose()` of GTK otherwise crashes);
- sets `CHROME_DESKTOP=z-library.desktop`, so the window matches its desktop entry.

---

## 🧅 Tor and Xray

To reach the library, the app tries a direct connection and, depending on its connection settings, starts the bundled Tor client (with the lyrebird bridges transport) or the bundled Xray client from `/opt/z-library/resources/proxies`. Both run as your user and keep their state in `~/.config/Z-Library` (`tor/`, `torrc_bridges`, `xray_config.json`). Tor uses the system `openssl` and `zlib` and the bundled `libevent`.

---

## ⚙️ Configuration

Flags file: `~/.config/z-library-flags.conf` (one flag per line).

```bash
# Force a display backend
--ozone-platform=wayland
# HiDPI scaling
--force-device-scale-factor=1.5
```

Environment variables:

| Variable | Effect |
|---|---|
| `Z_LIBRARY_CSD=1` | Keep upstream's frameless window, in-page window buttons and menu (the updater and port 9222 stay off) |
| `Z_LIBRARY_GLOBALMENU=0` | On KDE Wayland, run native Wayland (no Global Menu) |

---

## 🛠️ Troubleshooting

- **Signed out after every start.** The app encrypts the sign-in with the desktop keyring when one is available. Install `libsecret` with a Secret Service keyring (GNOME Keyring, KeePassXC) or use KWallet on Plasma. If a keyring appears after you signed in without one, the app asks you to sign in once more.
- **Stuck on "connecting".** In the app's connection settings, try another mode: automatic, direct (clearnet), Tor or Xray. Tor's first bootstrap through bridges can take a minute.
- **No menu in the Global Menu.** Check that the app runs under XWayland (`xprop` can click it) and that `Z_LIBRARY_GLOBALMENU` is not set to `0`.
- **Log.** Run `z-library` from a terminal; lines starting with `[archrepo]` show what the bootstrap changed.

---

## 🔗 Related Links

- [Upstream website](https://z-lib.fm)
- [archrepo Releases](https://github.com/kud3n013/archrepo/releases/tag/packages)
- [Back to archrepo README](../README.md)
