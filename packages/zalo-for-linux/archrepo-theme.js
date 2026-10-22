// Live light/dark switching, main-process half.
//
// Electron 22 (Chromium 108) does not read the portal's color-scheme setting. Under X11
// it only notices a change of GTK theme name, and Plasma keeps the name "Breeze" when
// the colour scheme changes, so the app never noticed. This module reads
// org.freedesktop.appearance color-scheme from the portal, watches SettingChanged with
// one `gdbus monitor` child, and sets nativeTheme.themeSource. That flips
// prefers-color-scheme in every page.
//
// Upstream's scripts/patches/patch-auto-theme.js injects a block into Zalo's main.js
// that does the same with blocking dbus-send calls, a 10 s poll and a gsettings
// monitor. Setting global.__zaloThemeSync first makes that block return early, and this
// module takes over its IPC contract so that upstream's preload half keeps working: it
// answers "zalo-linux-get-theme" and sends "zalo-linux-theme-change" to every window.
// archrepo-theme-preload.js applies the user's in-app choice in each page.
"use strict";

const { execFile, spawn } = require("child_process");
const path = require("path");

const PORTAL = ["--session", "--dest", "org.freedesktop.portal.Desktop", "--object-path", "/org/freedesktop/portal/desktop"];
// Only this key matters. Other keys (accent-color) and namespaces (KDE's own
// color-scheme key) arrive on the same signal and are ignored.
const CHANGED_RE = /org\.freedesktop\.portal\.Settings\.SettingChanged \('org\.freedesktop\.appearance', 'color-scheme', <uint32 (\d+)>\)/;
// Zalo's own window backgrounds (backgroundPrimary of its light and dark themes).
const BACKGROUND = { light: "#FFFFFF", dark: "#22262B" };
const MAX_RESTARTS = 5;
// `gdbus monitor` runs until it is killed, and it inherits Chromium's open sockets. In
// this shell a reader waits on a pipe from this process (stdin, kept as fd 3 because a
// background job gets /dev/null) and stops gdbus when the pipe closes. The pipe also
// closes when Zalo leaves through app.exit() or crashes, when 'will-quit' and the
// process 'exit' event do not fire. Seen in testing: a leftover monitor kept the
// DevTools port open after Zalo was gone. The shell itself waits for gdbus, so if gdbus
// exits on its own, the shell exits too and the monitor is restarted.
const MONITOR = 'exec 3<&0; gdbus monitor "$@" & g=$!; { read -r _ <&3; kill "$g"; } & r=$!; wait "$g"; kill "$r" 2>/dev/null';

// 1 is prefer dark, 2 prefer light, and 0 no preference, which the portal spec says to
// treat as light.
const schemeToTheme = (value) => (value === 1 ? "dark" : "light");

function run(command, args) {
  return new Promise((resolve) => {
    execFile(command, args, { timeout: 3000 }, (error, stdout) => resolve(error ? null : stdout));
  });
}

async function readPortal() {
  const output = await run("gdbus", ["call", ...PORTAL, "--method", "org.freedesktop.portal.Settings.Read", "org.freedesktop.appearance", "color-scheme"]);
  const match = output && /uint32 (\d+)/.exec(output);
  return match ? schemeToTheme(Number(match[1])) : null;
}

// Without a portal, Plasma's colour scheme is read once from kdeglobals: a dark window
// background means a dark scheme. Nothing is watched in that case.
async function readKdeglobals() {
  const output = await run("kreadconfig6", ["--file", "kdeglobals", "--group", "Colors:Window", "--key", "BackgroundNormal"]);
  const rgb = (output ?? "").trim().split(",").map(Number);
  if (rgb.length !== 3 || rgb.some(Number.isNaN)) {
    return null;
  }
  const [r, g, b] = rgb;
  return 0.2126 * r + 0.7152 * g + 0.0722 * b < 128 ? "dark" : "light";
}

async function readInitial() {
  const fromPortal = await readPortal();
  if (fromPortal) {
    return { theme: fromPortal, source: "portal" };
  }
  const fromKdeglobals = await readKdeglobals();
  return fromKdeglobals ? { theme: fromKdeglobals, source: "kdeglobals" } : { theme: "light", source: "default" };
}

function install({ electron, log, isMainWindow }) {
  const { app, ipcMain, nativeTheme, BrowserWindow } = electron;

  // Upstream's injected block checks this flag and returns before doing anything.
  global.__zaloThemeSync = true;

  let theme = null;
  let monitor = null;
  let restarts = 0;
  let quitting = false;
  const initial = readInitial();

  // Until the first read completes the reply waits for it, so the first page never
  // applies a guessed theme.
  ipcMain.handle("zalo-linux-get-theme", async () => theme ?? (await initial).theme);

  // The preload reports the theme it applied, which already accounts for the user's
  // in-app choice. Transparent and background windows keep their own colour.
  ipcMain.on("archrepo-theme-applied", (event, dark) => {
    const win = BrowserWindow.fromWebContents(event.sender);
    if (win && !win.isDestroyed() && isMainWindow(win)) {
      win.setBackgroundColor(dark ? BACKGROUND.dark : BACKGROUND.light);
    }
  });

  app.on("session-created", (session) => {
    session.setPreloads([...session.getPreloads(), path.join(__dirname, "archrepo-theme-preload.js")]);
  });

  function apply(next, reason) {
    if (next === theme) {
      return;
    }
    theme = next;
    log(`theme ${next} (${reason})`);
    // This emits nativeTheme 'updated'. Nothing here listens to it, and themeSource is
    // only set when the theme changes, so there is no loop.
    nativeTheme.themeSource = next;
    for (const win of BrowserWindow.getAllWindows()) {
      if (!win.isDestroyed() && !win.webContents.isDestroyed()) {
        win.webContents.send("zalo-linux-theme-change", next);
      }
    }
  }

  function watch() {
    const started = Date.now();
    const child = spawn("sh", ["-c", MONITOR, "sh", ...PORTAL], { stdio: ["pipe", "pipe", "ignore"] });
    monitor = child;

    let pending = "";
    child.stdout.setEncoding("utf8");
    child.stdout.on("data", (chunk) => {
      const lines = (pending + chunk).split("\n");
      pending = lines.pop();
      for (const line of lines) {
        const match = CHANGED_RE.exec(line);
        if (match) {
          apply(schemeToTheme(Number(match[1])), "portal SettingChanged");
        }
      }
    });

    // 'error' and 'exit' can both fire for one child. A missing gdbus makes the shell exit.
    // A restart is reported, so a monitor that keeps dying shows up in the log.
    const restart = () => {
      if (monitor !== child) {
        return;
      }
      monitor = null;
      if (quitting) {
        return;
      }
      restarts = Date.now() - started > 60000 ? 1 : restarts + 1;
      if (restarts > MAX_RESTARTS) {
        log("portal monitor keeps exiting, live theme switching stopped");
        return;
      }
      log(`portal monitor exited, restarting (${restarts}/${MAX_RESTARTS})`);
      setTimeout(() => {
        watch();
        // A change while the monitor was down would otherwise be missed.
        readPortal().then((value) => value && apply(value, "portal"));
      }, 1000 * 2 ** (restarts - 1)).unref();
    };
    child.on("error", restart);
    child.on("exit", restart);
  }

  // Closing the pipe makes the shell stop gdbus (see MONITOR).
  const stop = () => {
    quitting = true;
    monitor?.stdin.end();
  };
  app.on("will-quit", stop);
  process.on("exit", stop);

  Promise.all([initial, app.whenReady()]).then(([{ theme: value, source }]) => {
    apply(value, `startup, ${source}`);
    if (source === "portal") {
      watch();
    }
  });
}

module.exports = { install };
