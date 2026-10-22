// System tray, close-to-tray and live theme sync for Proton Mail on Linux.
//
// Upstream has no tray on Linux, and closing the window quits the app. This file
// runs before the app's entry point, from app.asar, and adds a tray icon. Closing
// the window then hides it to the tray, and the tray's Quit item quits.
// patch-tray.js writes it into app.asar and fills in the original entry point.
//
// It also loads archrepo-theme-sync.js (theme-sync.js in the package), which makes
// the app's "Auto" theme follow the desktop's light/dark setting live.
//
// It uses only Electron's public API and two menu item ids from upstream's View menu.
// Nothing here depends on names in the minified bundle, so a version bump cannot
// silently break it.
"use strict";

const path = require("path");
const fs = require("fs");
const { execFile } = require("child_process");
const Module = require("module");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// Upstream's minimum is 900px, which a tiling window manager cannot honour in a
// half-width column. Proton's web apps have narrow layouts, so 360px is usable.
const MIN_WIDTH = 360;

function log(message) {
  // process.stdout and process.stderr writes do not always reach the output from
  // the main process, so write to fd 2 directly.
  try {
    fs.writeSync(2, `[archrepo] ${message}\n`);
  } catch {}
}

let electron = null;
let mainWindow = null;
let tray = null;
let quitting = false;

// Close-to-tray is on only while a tray icon exists. Without a tray host, hiding
// the window would leave no way back except launching the app again.
function hideOnClose() {
  return tray !== null && !quitting;
}

function hideWindow(win) {
  if (win.isFullScreen()) {
    win.once("leave-full-screen", () => win.hide());
    win.setFullScreen(false);
  } else {
    win.hide();
  }
}

function showWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) {
    return;
  }
  if (mainWindow.isMinimized()) {
    mainWindow.restore();
  }
  mainWindow.show();
  mainWindow.focus();
}

// Upstream's View menu has "Switch to Proton Mail" and "Switch to Proton Calendar"
// with these ids. Upstream disables them while the account pages are showing
// (sign-in, account switch), so a disabled item only shows the window.
function switchTo(menuItemId) {
  showWindow();
  const item = electron.Menu.getApplicationMenu()?.getMenuItemById(menuItemId);
  if (item && item.enabled) {
    item.click();
  }
}

function patchElectron(loaded) {
  const Base = loaded.BrowserWindow;

  // A subclass, not a wrapper, so statics and instanceof keep working. It must be
  // named BrowserWindow: Electron's BrowserWindow.getAllWindows() keeps only
  // windows whose constructor.name is "BrowserWindow", and upstream's before-quit
  // handler uses it to destroy every window.
  class BrowserWindow extends Base {
    constructor(options = {}) {
      const isMain = !mainWindow && !options.parent && !options.modal;
      if (isMain && options.minWidth > MIN_WIDTH) {
        options = { ...options, minWidth: MIN_WIDTH };
      }
      super(options);
      if (!isMain) {
        return;
      }

      mainWindow = this;
      // super.on, so this listener is not skipped by archrepoGuardClose() below.
      super.on("close", (event) => {
        if (hideOnClose()) {
          event.preventDefault();
          hideWindow(this);
        }
      });
      super.on("closed", () => {
        if (mainWindow === this) {
          mainWindow = null;
        }
      });
    }

    // Upstream's own close handler hides the window and then quits the app on
    // Linux. Its listeners are skipped while the window hides to the tray, and run
    // as before when the app is quitting or there is no tray.
    on(event, listener) {
      return super.on(event, this.archrepoGuardClose(event, listener));
    }

    addListener(event, listener) {
      return super.addListener(event, this.archrepoGuardClose(event, listener));
    }

    archrepoGuardClose(event, listener) {
      if (event !== "close" || mainWindow !== this || typeof listener !== "function") {
        return listener;
      }
      return function (...args) {
        if (hideOnClose()) {
          return undefined;
        }
        return listener.apply(this, args);
      };
    }
  }

  return Object.create(loaded, {
    BrowserWindow: { value: BrowserWindow, enumerable: true },
  });
}

function trayIconPath() {
  return path.join(process.resourcesPath, "tray.png");
}

function createTray() {
  const icon = electron.nativeImage.createFromPath(trayIconPath());
  if (icon.isEmpty()) {
    log(`tray icon missing at ${trayIconPath()}, no tray`);
    return;
  }

  tray = new electron.Tray(icon);
  tray.setToolTip("Proton Mail");
  tray.setContextMenu(
    electron.Menu.buildFromTemplate([
      { label: "Open Proton Mail", click: () => switchTo("switch-to-mail") },
      { label: "Open Proton Calendar", click: () => switchTo("switch-to-calendar") },
      { type: "separator" },
      {
        label: "Quit",
        click: () => {
          quitting = true;
          electron.app.quit();
        },
      },
    ]),
  );

  // Left click toggles the window. On KDE Plasma this is the StatusNotifierItem
  // Activate call; hosts without one open the context menu instead. Focus is not
  // checked: on Wayland the click itself takes focus away from the window.
  tray.on("click", () => {
    if (mainWindow && mainWindow.isVisible()) {
      hideWindow(mainWindow);
    } else {
      showWindow();
    }
  });
  log("tray icon created, closing the window hides it to the tray");
}

// Electron's tray on Linux is a StatusNotifierItem over D-Bus. It needs a host
// (KDE Plasma, most panels, GNOME with the AppIndicator extension) that owns
// org.kde.StatusNotifierWatcher. If gdbus cannot answer, assume a host exists.
function hasTrayHost(callback) {
  execFile(
    "gdbus",
    [
      "call",
      "--session",
      "--dest",
      "org.freedesktop.DBus",
      "--object-path",
      "/org/freedesktop/DBus",
      "--method",
      "org.freedesktop.DBus.NameHasOwner",
      "org.kde.StatusNotifierWatcher",
    ],
    { timeout: 2000 },
    (error, stdout) => callback(error ? true : stdout.includes("true")),
  );
}

// PROTON_MAIL_TRAY=0 keeps upstream's behaviour: no tray, closing the window quits.
// PROTON_MAIL_THEME_SYNC=0 leaves the theme to Chromium.
const trayEnabled = process.env.PROTON_MAIL_TRAY !== "0";
const themeSync = process.env.PROTON_MAIL_THEME_SYNC !== "0";

if (process.platform === "linux" && themeSync) {
  try {
    require("./archrepo-theme-sync.js").install(require("electron"));
  } catch (error) {
    log(`theme sync failed to start: ${error}`);
  }
}

if (process.platform === "linux" && trayEnabled) {
  electron = require("electron");
  const patched = patchElectron(electron);

  const load = Module._load;
  Module._load = function (request) {
    const loaded = load.apply(this, arguments);
    return request === "electron" ? patched : loaded;
  };

  // Registered before upstream's own before-quit handler, so the window is
  // allowed to close by the time upstream destroys it. Covers the File menu's
  // Quit and Ctrl+Q as well as the tray.
  electron.app.on("before-quit", () => {
    quitting = true;
  });

  electron.app.whenReady().then(() => {
    hasTrayHost((available) => {
      if (available) {
        createTray();
      } else {
        log("no StatusNotifierItem host on the session bus, no tray");
      }
    });
  });
}

require(path.join(__dirname, ORIGINAL_MAIN));
