// Archrepo integration for Zalo on Linux: the KDE Global Menu, the window manager's
// title bar and live light/dark switching.
//
// This file runs before upstream's shell main.js, from app.asar, and then requires it.
// It changes no upstream file. patch-bootstrap.js writes it into app.asar, fills in the
// original entry point and checks the upstream code each feature relies on.
// Each feature has an opt-out: ZALO_GLOBALMENU=0, ZALO_NATIVE_TITLEBAR=0, ZALO_THEME_SYNC=0.
"use strict";

const path = require("path");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// Hidden windows Zalo uses as background processes. Upstream's shell uses the same
// list, and the same rule for the main window: the first window that is not one of these.
const BACKGROUND_WINDOW_TITLES = ["Shared Worker", "SQLite"];

if (process.platform === "linux") {
  const electron = require("electron");

  // process.stdout and process.stderr writes do not always reach the output, so
  // write to fd 2 directly, the same as the claude-desktop bootstrap.
  const log = (message) => require("fs").writeSync(2, `[archrepo] ${message}\n`);

  // Registered before upstream's handler, so the main window is known by the time
  // upstream calls removeMenu() on it.
  let mainWindow = null;
  electron.app.on("browser-window-created", (_event, win) => {
    if (!mainWindow && !BACKGROUND_WINDOW_TITLES.includes(win.getTitle())) {
      mainWindow = win;
      win.once("closed", () => {
        mainWindow = null;
      });
    }
  });
  const context = { electron, log, isMainWindow: (win) => win === mainWindow };

  require("./archrepo-globalmenu").install({ ...context, enabled: process.env.ZALO_GLOBALMENU !== "0" });
  if (process.env.ZALO_NATIVE_TITLEBAR !== "0") {
    require("./archrepo-titlebar").install(context);
  }
  if (process.env.ZALO_THEME_SYNC !== "0") {
    require("./archrepo-theme").install(context);
  }
}

require(path.join(__dirname, ORIGINAL_MAIN));
