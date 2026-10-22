// Live light/dark switching and a panel-aware tray icon for Claude Desktop on Linux.
//
// The bootstrap loads this file from app.asar (as archrepo-theme-sync.js) and calls
// install() with the real electron module. install() returns the properties that
// replace electron's own (Tray, nativeImage) in the module the app sees.
//
// Theme: the desktop's color-scheme is read from the XDG portal and followed through
// its SettingChanged signal. While the app's own theme choice is "system", the real
// nativeTheme.themeSource is set to "dark" or "light" to match, so a change applies
// without Chromium having to notice it (under XWayland it stops noticing after the
// first change, anthropics/claude-code#77171).
//
// Tray: upstream picks TrayIconLinux.png (dark glyph) or TrayIconLinux-Dark.png
// (light glyph) from the window color scheme, so a dark panel with light windows
// (Breeze Twilight, or any dark Plasma style) gets a dark glyph on a dark panel
// (anthropics/claude-code#77170). The tray image is swapped for the variant that
// contrasts with the panel, and swapped again when the panel changes.
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFile, spawn } = require("child_process");

const PORTAL = ["--dest", "org.freedesktop.portal.Desktop", "--object-path", "/org/freedesktop/portal/desktop"];
const SETTING_CHANGED =
  /org\.freedesktop\.portal\.Settings\.SettingChanged \('org\.freedesktop\.appearance', 'color-scheme', <(?:uint32 )?(\d+)>\)/;
const TRAY_ICON = /^TrayIconLinux(-Dark)?\.png$/;

function log(message) {
  // Same as titlebar-bootstrap.js: process.stderr writes did not reach the output.
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

// --- KDE config ---------------------------------------------------------------

const configHome = process.env.XDG_CONFIG_HOME || path.join(os.homedir(), ".config");
const dataDirs = [
  process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local/share"),
  ...(process.env.XDG_DATA_DIRS || "/usr/local/share:/usr/share").split(":"),
].filter(Boolean);

// Returns the value of key in [group] of a KConfig file, or null.
function readKConfig(file, group, key) {
  let text;
  try {
    text = fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
  let inGroup = false;
  for (const raw of text.split("\n")) {
    const line = raw.trim();
    if (line.startsWith("[")) {
      inGroup = line === `[${group}]`;
    } else if (inGroup) {
      const eq = line.indexOf("=");
      // Keys can carry [$e] or [$i] flags, which are not part of the name.
      if (eq > 0 && line.slice(0, eq).replace(/\[\$.*\]$/, "").trim() === key) {
        return line.slice(eq + 1).trim();
      }
    }
  }
  return null;
}

// "r,g,b" -> true when the colour is dark.
function isDarkRgb(value) {
  const rgb = (value ?? "").split(",").map(Number);
  if (rgb.length < 3 || rgb.some((n) => !Number.isFinite(n))) {
    return null;
  }
  return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2] < 128;
}

// The Plasma style draws the panel. A style with its own colors file (breeze-dark,
// breeze-light, most third-party styles) uses those colours. One without (the default
// Breeze style) follows the system colour scheme in kdeglobals.
function kdePanelIsDark() {
  const style = readKConfig(path.join(configHome, "plasmarc"), "Theme", "name") || "default";
  for (const dir of dataDirs) {
    const themeDir = path.join(dir, "plasma/desktoptheme", style);
    if (fs.existsSync(themeDir)) {
      const colors = path.join(themeDir, "colors");
      if (fs.existsSync(colors)) {
        return isDarkRgb(readKConfig(colors, "Colors:Window", "BackgroundNormal"));
      }
      break;
    }
  }
  const dark = isDarkRgb(readKConfig(path.join(configHome, "kdeglobals"), "Colors:Window", "BackgroundNormal"));
  // A fresh profile has no colours in kdeglobals, which means stock Breeze: light.
  return dark ?? false;
}

// --- Desktop ------------------------------------------------------------------

const desktop = (process.env.XDG_CURRENT_DESKTOP ?? "").toLowerCase();
const isKde = /kde|plasma/.test(desktop) || process.env.KDE_FULL_SESSION === "true";

// true: dark panel, false: light panel, null: unknown (upstream's choice stands).
async function panelIsDark() {
  const forced = (process.env.CLAUDE_DESKTOP_TRAY_PANEL ?? "").toLowerCase();
  if (forced === "dark" || forced === "light") {
    return forced === "dark";
  }
  if (isKde) {
    return kdePanelIsDark();
  }
  if (desktop.includes("cinnamon")) {
    const theme = await run("gsettings", ["get", "org.cinnamon.theme", "name"]);
    return theme === null ? null : /dark/i.test(theme);
  }
  // GNOME's top bar is always dark and upstream already special-cases it. Elsewhere
  // there is no panel signal to read, so the colour scheme decides, as upstream does.
  return null;
}

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
    const dark = isDarkRgb(readKConfig(path.join(configHome, "kdeglobals"), "Colors:Window", "BackgroundNormal"));
    if (dark !== null) {
      return dark ? "dark" : "light";
    }
  }
  const gnome = await run("gsettings", ["get", "org.gnome.desktop.interface", "color-scheme"]);
  if (gnome?.includes("prefer-dark")) return "dark";
  if (gnome?.includes("prefer-light") || gnome?.includes("default")) return "light";
  return null;
}

// --- install ------------------------------------------------------------------

function install(electron) {
  const { app, nativeTheme, nativeImage, Tray } = electron;

  let systemScheme = null; // "dark" | "light" | null while unknown
  let appChoice = "system"; // what the app last assigned to themeSource
  let darkPanel = null;
  let quitting = false;

  // themeSource: the app sees its own choice when it reads the property back, and
  // the real value follows the desktop while that choice is "system".
  let source = nativeTheme;
  let descriptor;
  while (source && !(descriptor = Object.getOwnPropertyDescriptor(source, "themeSource"))) {
    source = Object.getPrototypeOf(source);
  }
  const setReal = descriptor?.set ? (value) => descriptor.set.call(nativeTheme, value) : null;
  if (setReal) {
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
  } else {
    log("theme sync: nativeTheme.themeSource is not an accessor, leaving the theme to Chromium");
  }

  function applyTheme() {
    if (!setReal) return;
    setReal(appChoice === "system" && systemScheme ? systemScheme : appChoice);
  }

  // Tray. A tray image that is a dark or light glyph is swapped for the variant that
  // contrasts with the panel. The glyph's tone comes from its file name when the
  // image was made from a path, and from its opaque pixels otherwise.
  const imagePaths = new WeakMap();
  const trays = new Set();
  let missingLogged = false;

  const patchedImage = Object.create(nativeImage, {
    createFromPath: {
      enumerable: true,
      value(file) {
        const image = nativeImage.createFromPath(file);
        imagePaths.set(image, file);
        return image;
      },
    },
  });

  function glyphIsLight(image, file) {
    const named = TRAY_ICON.exec(path.basename(file ?? ""));
    if (named) {
      return Boolean(named[1]);
    }
    const native = typeof image === "string" ? nativeImage.createFromPath(image) : image;
    if (!native || typeof native.toBitmap !== "function" || native.isEmpty()) {
      return null;
    }
    // BGRA. Mean luminance of the opaque pixels: a glyph is close to 0 or 255.
    const bitmap = native.toBitmap();
    let sum = 0;
    let count = 0;
    for (let i = 0; i + 3 < bitmap.length; i += 4) {
      if (bitmap[i + 3] > 128) {
        sum += 0.0722 * bitmap[i] + 0.7152 * bitmap[i + 1] + 0.2126 * bitmap[i + 2];
        count++;
      }
    }
    const mean = count ? sum / count : 128;
    return mean > 192 ? true : mean < 64 ? false : null;
  }

  function pickImage(image) {
    if (darkPanel === null || !image) {
      return image;
    }
    const file = typeof image === "string" ? image : imagePaths.get(image);
    const light = glyphIsLight(image, file);
    if (light === null || light === darkPanel) {
      return image;
    }
    const name = darkPanel ? "TrayIconLinux-Dark.png" : "TrayIconLinux.png";
    const dirs = [file && path.dirname(file), process.resourcesPath].filter(Boolean);
    const wanted = dirs.map((dir) => path.join(dir, name)).find((candidate) => fs.existsSync(candidate));
    if (!wanted) {
      if (!missingLogged) log(`tray: ${name} not found, keeping upstream's icon`);
      missingLogged = true;
      return image;
    }
    return typeof image === "string" ? wanted : patchedImage.createFromPath(wanted);
  }

  // A function rather than a subclass: Tray is a native wrapper whose constructor
  // returns its own object, so a subclass's methods would not end up on the tray.
  function PanelAwareTray(image, ...rest) {
    const tray = new Tray(pickImage(image), ...rest);
    const setImage = tray.setImage;
    tray._archrepoImage = image;
    Object.defineProperty(tray, "setImage", {
      configurable: true,
      writable: true,
      value(next) {
        tray._archrepoImage = next;
        return setImage.call(tray, pickImage(next));
      },
    });
    tray._archrepoSetImage = setImage;
    trays.add(tray);
    return tray;
  }
  PanelAwareTray.prototype = Tray.prototype;
  Object.setPrototypeOf(PanelAwareTray, Tray);

  async function refreshPanel() {
    const dark = await panelIsDark();
    if (dark === darkPanel) return;
    darkPanel = dark;
    log(`tray: panel is ${dark === null ? "unknown, keeping upstream's icon" : dark ? "dark" : "light"}`);
    for (const tray of trays) {
      if (tray.isDestroyed()) {
        trays.delete(tray);
      } else {
        tray._archrepoSetImage.call(tray, pickImage(tray._archrepoImage));
      }
    }
  }

  function setScheme(scheme, why) {
    if (!scheme || scheme === systemScheme) return;
    systemScheme = scheme;
    log(`theme sync: ${why} color-scheme is ${scheme}${appChoice === "system" ? "" : `, app keeps "${appChoice}"`}`);
    applyTheme();
    refreshPanel();
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

  // Plasma writes plasmarc and kdeglobals by renaming a new file over the old one,
  // so the directory is watched rather than the files.
  function watchKdeConfig() {
    let timer = null;
    try {
      fs.watch(configHome, { persistent: false }, (_event, name) => {
        if (name !== "plasmarc" && name !== "kdeglobals") return;
        clearTimeout(timer);
        timer = setTimeout(refreshPanel, 300);
      }).on("error", () => {});
    } catch (error) {
      log(`tray: cannot watch ${configHome}: ${error.message}`);
    }
  }

  function stop() {
    quitting = true;
    monitor?.kill();
  }
  app.on("will-quit", stop);
  process.on("exit", stop);

  log("theme sync: on (CLAUDE_DESKTOP_THEME_SYNC=0 turns it off)");
  refreshPanel();
  readScheme().then((scheme) => setScheme(scheme, "desktop"));
  startMonitor();
  if (isKde) watchKdeConfig();

  return { Tray: PanelAwareTray, nativeImage: patchedImage };
}

module.exports = { install };
