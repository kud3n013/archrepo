# Steam Global Menu (`steam-globalmenu`)

[![build](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/kud3n013/archrepo/actions/workflows/build.yml)
[![version](https://img.shields.io/badge/version-1.0.0--1-blue)](https://github.com/kud3n013/archrepo/releases/tag/packages)
[![type](https://img.shields.io/badge/type-modified-orange)](#overview)
[![upstream](https://img.shields.io/badge/upstream-archrepo-informational)](https://github.com/kud3n013/archrepo)

Daemon bridge exporting the Steam client menu bar, navigation shortcuts, and dynamically parsed recent games to the KDE Plasma Global Menu widget via the DBusMenu protocol.

---

## 📥 Installation

```bash
sudo pacman -S steam-globalmenu
```

Enable and start the user service:

```bash
systemctl --user enable --now steam-globalmenu.service
```

---

## 🔍 Package Information

| Attribute | Value |
|---|---|
| **Package Name** | `steam-globalmenu` |
| **Current Version** | `1.0.0-1` |
| **Package Type** | **Modified (KDE Global Menu Bridge)** |
| **Build Status** | `passing` |
| **Upstream Project** | [kud3n013/archrepo](https://github.com/kud3n013/archrepo) |
| **Category** | Desktop Integration / Gaming |

---

### Overview
Because the modern Steam client uses a custom Chromium Embedded Framework (CEF) and React web interface, it does not natively export its application menu bar (`Steam`, `View`, `Friends`, `Games`, `Help`) to system-wide desktop panels. 

`steam-globalmenu` bridges this gap:
- **KDE Plasma Global Menu Export**: Runs a lightweight D-Bus daemon implementing `com.canonical.dbusmenu` (`org.kde.steam.AppMenu` on `/MenuBar`).
- **Automatic Window Binding**: Detects active Steam client windows via X11 / XWayland and dynamically attaches the `_KDE_NET_WM_APPMENU_SERVICE_NAME` and `_KDE_NET_WM_APPMENU_OBJECT_PATH` properties.
- **AppMenu Registrar Integration**: Automatically registers and unregisters window IDs with `com.canonical.AppMenu.Registrar` as Steam opens and closes.
- **Dynamic Recent Games Submenu**: Discovers local Steam library paths (`libraryfolders.vdf`) and user configs (`localconfig.vdf`) to populate a live **Recent Games** and **Installed Games** launcher submenu directly inside your KDE Plasma top panel.
- **Full Navigation Coverage**: Maps top-level menus to native Steam browser protocol commands (`steam://open/settings`, `steam://open/downloads`, `steam://open/friends`, `steam://open/activateproduct`, etc.) and clean CLI shutdown (`steam -shutdown`).

---

## 🎨 Aesthetic Integration (Millennium Quick CSS)

To hide the redundant horizontal in-window menu bar and native window controls inside Steam, use the companion Quick CSS snippet included in `/usr/share/doc/steam-globalmenu/quickcss.css`.

Open Steam, navigate to **Millennium → Quick CSS**, and paste:

```css
/* 1. Hide native window controls (Minimize, Maximize, Close) */
.title-area .title-bar-actions.window-controls,
.title-bar-actions.window-controls,
div.qP17eBPXkfezFfexZ4hC3 {
    display: none !important;
}

/* 2. Hide native horizontal menu bar (Steam, View, Friends, Games, Help) */
div._3s0lkohH8wU2do0K1il28Y,
div._2UyOBeiSdBayaFdRa39N2O,
div._39oUCO1OuizVPwcnnv88no > div:first-child:not([class*="DragArea"]) {
    display: none !important;
}

/* 3. Ensure header drag region remains responsive across the entire top bar */
div._30vB9DdsPK7VrZAbb5Q1Av {
    -webkit-app-region: drag !important;
    min-height: 38px !important;
}
```

---

## ⚙️ Service Management

The bridge runs as a systemd user unit:

```bash
# Check service status
systemctl --user status steam-globalmenu.service

# Restart service
systemctl --user restart steam-globalmenu.service

# View live daemon logs
journalctl --user -u steam-globalmenu.service -f
```
