// Live light/dark switching for Proton Mail on Linux.
//
// The bootstrap loads this file from app.asar (as archrepo-theme-sync.js) and calls
// install() with the real electron module, before upstream's code runs.
//
// The desktop's color-scheme is read from the XDG portal and followed through its
// SettingChanged signal. While the app's theme mode is "Auto" (upstream sets
// nativeTheme.themeSource to "system"), the real themeSource is set to "dark" or
// "light" to match, so a change applies without Chromium having to notice it.
// Chromium's own detection misses changes under XWayland and on desktops whose GTK
// theme name does not say "dark". The Light and Dark modes are left alone.
//
// This is the same approach as claude-desktop's theme-sync.js, without the tray
// glyph swap: Proton's tray icon is coloured and reads on light and dark panels.
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFile, spawn } = require("child_process");

const PORTAL = ["--dest", "org.freedesktop.portal.Desktop", "--object-path", "/org/freedesktop/portal/desktop"];
const SETTING_CHANGED =
  /org\.freedesktop\.portal\.Settings\.SettingChanged \('org\.freedesktop\.appearance', 'color-scheme', <(?:uint32 )?(\d+)>\)/;

// Upstream's backgrounds for its Carbon (dark) and Snow (light) themes. Upstream
// sets them on the window and its views only when the theme setting changes, so
// they are set again here when the desktop switches. They show while a view loads.
const BACKGROUND = { dark: "#16141c", light: "#ffffff" };

function log(message) {
  // Same as tray-bootstrap.js: process.stderr writes do not always reach the output.
  try {
    fs.writeSync(2, `[archrepo] ${message}\n`);
  } catch {}
}

// The portal's color-scheme: 1 is dark, 2 is light, 0 is "no preference",
// which the spec says to treat as light.
function schemeName(value) {
  return Number(value) === 1 ? "dark" : "light";
}

function run(file, args) {
  return new Promise((resolve) => {
    execFile(file, args, { timeout: 3000, encoding: "utf8" }, (error, stdout) => resolve(error ? null : stdout));
  });
}

const configHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
const desktop = (process.env.XDG_CURRENT_DESKTOP ?? "").toLowerCase();
const isKde = /kde|plasma/.test(desktop) || process.env.KDE_FULL_SESSION === "true";

// Window background of the KDE colour scheme in kdeglobals, as "dark" or "light".
function kdeScheme() {
  let text;
  try {
    text = fs.readFileSync(path.join(configHome, "kdeglobals"), "utf8");
  } catch {
    return null;
  }
  const group = text.split(/^\[/m).find((part) => part.startsWith("Colors:Window]"));
  const match = /^BackgroundNormal=(\d+),(\d+),(\d+)/m.exec(group ?? "");
  if (!match) {
    return null;
  }
  const [r, g, b] = match.slice(1).map(Number);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b < 128 ? "dark" : "light";
}

// Fallbacks for a desktop without the portal's appearance namespace.
async function readScheme() {
  const portal = await run("gdbus", [
    "call", "--session", ...PORTAL,
    "--method", "org.freedesktop.portal.Settings.Read", "org.freedesktop.appearance", "color-scheme",
  ]);
  const match = /uint32 (\d+)/.exec(portal ?? "");
  if (match) {
    return schemeName(match[1]);
  }
  if (isKde) {
    const scheme = kdeScheme();
    if (scheme) {
      return scheme;
    }
  }
  const gnome = await run("gsettings", ["get", "org.gnome.desktop.interface", "color-scheme"]);
  if (gnome?.includes("prefer-dark")) return "dark";
  if (gnome?.includes("prefer-light") || gnome?.includes("default")) return "light";
  return null;
}

function install(electron) {
  const { app, nativeTheme, BrowserWindow } = electron;

  let systemScheme = null; // "dark" | "light" | null while unknown
  let appChoice = "system"; // what the app last assigned to themeSource
  let quitting = false;

  // themeSource: the app sees its own choice when it reads the property back, and
  // the real value follows the desktop while that choice is "system". The accessor
  // lives on a prototype of the nativeTheme object.
  let source = nativeTheme;
  let descriptor;
  while (source && !(descriptor = Object.getOwnPropertyDescriptor(source, "themeSource"))) {
    source = Object.getPrototypeOf(source);
  }
  if (!descriptor?.set || !descriptor?.get) {
    log("theme sync: nativeTheme.themeSource is not an accessor, leaving the theme to Chromium");
    return;
  }
  const setReal = (value) => descriptor.set.call(nativeTheme, value);
  appChoice = descriptor.get.call(nativeTheme);
  Object.defineProperty(nativeTheme, "themeSource", {
    configurable: true,
    enumerable: descriptor.enumerable,
    get: () => appChoice,
    set: (value) => {
      appChoice = value;
      applyTheme();
    },
  });

  function applyTheme() {
    setReal(appChoice === "system" && systemScheme ? systemScheme : appChoice);
  }

  // Only the window and the view it shows; the other views get upstream's colour
  // the next time the app's theme setting changes, and are covered by their page.
  function updateBackgrounds() {
    const color = BACKGROUND[nativeTheme.shouldUseDarkColors ? "dark" : "light"];
    for (const win of BrowserWindow.getAllWindows()) {
      if (win.isDestroyed()) continue;
      win.setBackgroundColor(color);
      win.contentView?.setBackgroundColor?.(color);
    }
  }

  function setScheme(scheme, why) {
    if (!scheme || scheme === systemScheme) return;
    systemScheme = scheme;
    log(`theme sync: ${why} color-scheme is ${scheme}${appChoice === "system" ? "" : `, app keeps "${appChoice}"`}`);
    applyTheme();
    if (appChoice === "system" && app.isReady()) {
      updateBackgrounds();
    }
  }

  // SettingChanged watcher. gdbus comes with glib2. Respawn with a growing delay and
  // give up after a few failures in a row, so a missing gdbus can't spin.
  let monitor = null;
  let failures = 0;
  function startMonitor() {
    if (quitting) return;
    const started = Date.now();
    monitor = spawn("gdbus", ["monitor", "--session", ...PORTAL], { stdio: ["ignore", "pipe", "ignore"] });
    let buffered = "";
    monitor.stdout.setEncoding("utf8");
    monitor.stdout.on("data", (chunk) => {
      const lines = (buffered + chunk).split("\n");
      buffered = lines.pop();
      for (const line of lines) {
        const match = SETTING_CHANGED.exec(line);
        if (match) setScheme(schemeName(match[1]), "portal");
      }
    });
    monitor.on("error", () => {});
    monitor.on("close", () => {
      monitor = null;
      if (quitting) return;
      failures = Date.now() - started > 60000 ? 1 : failures + 1;
      if (failures > 5) {
        log("theme sync: gdbus monitor keeps exiting, live switching is off");
        return;
      }
      setTimeout(startMonitor, 1000 * 2 ** failures);
    });
  }

  function stop() {
    quitting = true;
    monitor?.kill();
  }
  app.on("will-quit", stop);
  process.on("exit", stop);

  log("theme sync: on (PROTON_MAIL_THEME_SYNC=0 turns it off)");
  // A SettingChanged that arrives first is newer than this read, so it wins.
  readScheme().then((scheme) => {
    if (systemScheme === null) setScheme(scheme, "desktop");
  });
  startMonitor();
}

module.exports = { install };
