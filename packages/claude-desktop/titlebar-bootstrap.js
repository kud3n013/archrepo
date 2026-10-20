// Native window frames for Claude Desktop on Linux.
//
// The app creates its windows frameless (titleBarStyle "hidden" or "hiddenInset")
// and draws its own title bar. This file runs before the app's entry point, from
// app.asar, and makes normal app windows use the window manager's frame instead.
// patch-titlebar.js writes it into app.asar and fills in the original entry point.
"use strict";

const path = require("path");
const Module = require("module");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// Upstream's Quick Entry, the 64px indicator and the Cowork glow are overlays: they
// set frame:false, transparent or alwaysOnTop. They stay as the app created them.
function isAppWindow(options) {
  return options.frame !== false && !options.transparent && !options.alwaysOnTop && !options.type;
}

function withNativeFrame(options) {
  const { titleBarStyle, titleBarOverlay, trafficLightPosition, ...rest } = options;
  return { ...rest, frame: true, autoHideMenuBar: true };
}

let patchedElectron = null;

// A subclass, not a wrapper, so statics such as getAllWindows() and instanceof keep working.
function patchElectron(electron) {
  if (patchedElectron) {
    return patchedElectron;
  }
  const { BrowserWindow } = electron;

  class FramedBrowserWindow extends BrowserWindow {
    constructor(options = {}) {
      if (isAppWindow(options)) {
        // process.stdout and process.stderr writes did not reach the output in testing,
        // so write to fd 2 directly.
        require("fs").writeSync(2, `[archrepo] native frame for window "${options.title ?? ""}"\n`);
        super(withNativeFrame(options));
      } else {
        super(options);
      }
    }

    // setTitleBarOverlay is Windows-only and throws on Linux. The app calls it on every
    // window and logs "Failed to set title bar overlay" when it fails.
    setTitleBarOverlay() {}
  }

  patchedElectron = Object.create(electron, {
    BrowserWindow: { value: FramedBrowserWindow, enumerable: true },
  });
  return patchedElectron;
}

// CLAUDE_DESKTOP_CSD=1 keeps upstream's frameless windows.
if (process.platform === "linux" && process.env.CLAUDE_DESKTOP_CSD !== "1") {
  const load = Module._load;
  Module._load = function (request, parent, isMain) {
    const loaded = load.apply(this, arguments);
    return request === "electron" ? patchElectron(loaded) : loaded;
  };
}

require(path.join(__dirname, ORIGINAL_MAIN));
