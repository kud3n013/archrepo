// archrepo additions for Zalo for Linux.
//
// This file runs before upstream's entry point, from app.asar. patch-bootstrap.js
// writes it into app.asar and fills in the original entry point. Upstream already
// gives the main window a native frame on X11 and exports Zalo's own menu, so this
// only covers what upstream doesn't do yet:
//
// - Theme sync that follows the portal's SettingChanged signal. Zalo runs on
//   Electron 22 (Chromium 108), which doesn't read the portal's color-scheme by
//   itself. Upstream's sync polls every 10 seconds with blocking dbus-send calls;
//   this one takes over its IPC contract and switches as soon as the setting changes.
// - Hiding Zalo's in-page title bar ("Zalo - name") when KWin already draws one.
"use strict";

const fs = require("fs");
const path = require("path");
const { execFile, spawn } = require("child_process");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// process.stdout and process.stderr writes do not always reach the output, so
// write to fd 2 directly, the same as the claude-desktop bootstrap.
function log(message) {
  try {
    fs.writeSync(2, `[archrepo] ${message}\n`);
  } catch (_) {}
}

// ---------------------------------------------------------------------------
// Theme sync
// ---------------------------------------------------------------------------

const PORTAL = ["--session", "--dest", "org.freedesktop.portal.Desktop", "--object-path", "/org/freedesktop/portal/desktop"];
// gdbus monitor prints one line per signal, for example:
// /org/freedesktop/portal/desktop: org.freedesktop.portal.Settings.SettingChanged ('org.freedesktop.appearance', 'color-scheme', <uint32 1>)
const PORTAL_CHANGED = /SettingChanged \('org\.freedesktop\.appearance', 'color-scheme', <+uint32 (\d+)>/;
const MAX_MONITOR_FAILURES = 5;

// Portal color-scheme: 1 is dark, 2 is light, 0 is "no preference", which the
// portal spec says to treat as light.
function fromPortal(value) {
  return value === 1 ? "dark" : "light";
}

function fromGsettings(text) {
  return text.includes("prefer-dark") ? "dark" : "light";
}

function run(command, args) {
  return new Promise((resolve, reject) => {
    execFile(command, args, { timeout: 3000 }, (error, stdout) => (error ? reject(error) : resolve(stdout)));
  });
}

// Reads the scheme from the portal, or from GSettings when no portal answers.
// Returns the source that answered, so the monitor watches the same one.
async function readScheme() {
  try {
    const out = await run("gdbus", ["call", ...PORTAL, "--method", "org.freedesktop.portal.Settings.Read", "org.freedesktop.appearance", "color-scheme"]);
    const match = /uint32 (\d+)/.exec(out);
    if (match) {
      return { source: "portal", mode: fromPortal(Number(match[1])) };
    }
  } catch (_) {}
  try {
    const out = await run("gsettings", ["get", "org.gnome.desktop.interface", "color-scheme"]);
    return { source: "gsettings", mode: fromGsettings(out) };
  } catch (_) {}
  return { source: null, mode: null };
}

function startThemeSync(electron) {
  const { app, ipcMain, nativeTheme, BrowserWindow } = electron;
  let current = null;
  let monitor = null;
  let quitting = false;
  let failures = 0;

  function apply(mode, why) {
    if (!mode || mode === current) {
      return;
    }
    current = mode;
    nativeTheme.themeSource = mode;
    // Upstream's preload (patch-auto-theme) listens for this and updates Zalo's
    // own theme. ZaDark follows prefers-color-scheme when its theme is "Auto".
    for (const win of BrowserWindow.getAllWindows()) {
      if (!win.isDestroyed()) {
        win.webContents.send("zalo-linux-theme-change", mode);
      }
    }
    log(`theme ${mode} (${why})`);
  }

  function watch(source) {
    const [command, args, parse] =
      source === "portal"
        ? ["gdbus", ["monitor", ...PORTAL], (line) => {
            const match = PORTAL_CHANGED.exec(line);
            return match ? fromPortal(Number(match[1])) : null;
          }]
        : ["gsettings", ["monitor", "org.gnome.desktop.interface", "color-scheme"], (line) =>
            line.startsWith("color-scheme:") ? fromGsettings(line) : null];

    monitor = spawn(command, args, { stdio: ["ignore", "pipe", "ignore"] });
    let pending = "";
    monitor.stdout.on("data", (chunk) => {
      const lines = (pending + chunk).split("\n");
      pending = lines.pop();
      for (const line of lines) {
        apply(parse(line), `${source} changed`);
      }
    });
    let ended = false;
    const restart = () => {
      // A failed spawn can emit both "error" and "exit".
      if (ended) {
        return;
      }
      ended = true;
      monitor = null;
      if (quitting) {
        return;
      }
      failures += 1;
      if (failures > MAX_MONITOR_FAILURES) {
        log(`${command} monitor keeps exiting, live theme sync stopped`);
        return;
      }
      setTimeout(() => watch(source), 1000 * 2 ** failures);
    };
    monitor.on("error", restart);
    monitor.on("exit", restart);
  }

  const initial = readScheme().then(({ source, mode }) => {
    if (!source) {
      log("no portal or GSettings answered, theme sync is off");
      return;
    }
    apply(mode, `${source} at start`);
    watch(source);
  });

  // The same channel as upstream's main-process block, which now returns early.
  // Windows that ask before the first read finishes get the answer when it does.
  ipcMain.handle("zalo-linux-get-theme", async () => {
    await initial;
    return current ?? (nativeTheme.shouldUseDarkColors ? "dark" : "light");
  });

  app.on("will-quit", () => {
    quitting = true;
    if (monitor) {
      monitor.kill();
    }
  });
}

// ---------------------------------------------------------------------------
// In-page title bar
// ---------------------------------------------------------------------------

// Zalo's macOS UI draws its own title bar (#titleBar, "Zalo - name"). Upstream's
// patch-titlebar gives the main window a native frame except on native Wayland,
// so there the in-page bar is a second title bar. Child windows (popped-out
// conversations) stay frameless and keep theirs, so only the main and login
// pages are touched.
const IN_PAGE_TITLEBAR_CSS =
  "#titleBar,.titlebar:not(.debugger-mini-profile-monitor__titlebar){display:none!important;height:0!important;min-height:0!important;max-height:0!important;padding:0!important;margin:0!important;border:none!important;overflow:hidden!important}";

function isMainPage(url) {
  try {
    const { protocol, pathname } = new URL(url);
    return protocol === "file:" && /\/pc-dist\/(index|login)\.html$/.test(pathname);
  } catch (_) {
    return false;
  }
}

function hideInPageTitlebar(electron) {
  electron.app.on("web-contents-created", (_event, contents) => {
    // Navigation drops inserted CSS, so it is inserted again on every load.
    contents.on("dom-ready", () => {
      if (global.__zaloNativeWayland === true || !isMainPage(contents.getURL())) {
        return;
      }
      contents.insertCSS(IN_PAGE_TITLEBAR_CSS).catch((error) => log(`insertCSS failed: ${error}`));
    });
  });
}

if (process.platform === "linux") {
  const electron = require("electron");
  if (process.env.ZALO_THEME_SYNC !== "0") {
    // Upstream's injected theme block checks this flag and returns early.
    global.__zaloThemeSync = true;
    startThemeSync(electron);
  }
  if (process.env.ZALO_INPAGE_TITLEBAR !== "1") {
    hideInPageTitlebar(electron);
  }
}

require(path.join(__dirname, ORIGINAL_MAIN));
