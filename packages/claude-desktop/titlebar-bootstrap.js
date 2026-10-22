// Native window frames and theme sync for Claude Desktop on Linux.
//
// The app creates its windows frameless (titleBarStyle "hidden" or "hiddenInset")
// and draws its own title bar. This file runs before the app's entry point, from
// app.asar, and makes normal app windows use the window manager's frame instead.
// patch-titlebar.js writes it into app.asar and fills in the original entry point.
// It also loads archrepo-theme-sync.js (theme-sync.js in the package), which makes
// the app follow the desktop's light/dark setting live and picks a tray icon that
// contrasts with the panel.
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

// The in-page menu button (aria-label "Menu") opens the same menu that the KDE Global
// Menu now shows, so it is hidden while the Global Menu is active. The button is part of
// claude.ai's own top bar, not app.asar. The signed-in page puts it in a different
// container and its aria-label is translated, so the selector uses the button's test id.
// The aria-label form covers the login page's top bar if the test id ever changes.
const IN_PAGE_MENU_CSS = `[data-testid="topbar-windows-menu"], div.draggable.fixed.top-0 button[aria-label="Menu"] { display: none !important; }`;

// The launcher (claude-desktop.sh) runs the app under XWayland on KDE, which is the
// only path where Electron exports the menu to the Plasma Global Menu.
function globalMenuActive(electron) {
  return (
    process.env.CLAUDE_DESKTOP_GLOBALMENU !== "0" &&
    /kde|plasma/i.test(process.env.XDG_CURRENT_DESKTOP ?? "") &&
    electron.app.commandLine.getSwitchValue("ozone-platform") === "x11"
  );
}

const nativeFrames = process.env.CLAUDE_DESKTOP_CSD !== "1";
const themeSync = process.env.CLAUDE_DESKTOP_THEME_SYNC !== "0";

let patchedElectron = null;

function framedWindowClass(electron) {
  const { BrowserWindow } = electron;

  // A subclass, not a wrapper, so statics such as getAllWindows() and instanceof keep working.
  return class FramedBrowserWindow extends BrowserWindow {
    constructor(options = {}) {
      const appWindow = isAppWindow(options);
      if (appWindow) {
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
  };
}

function patchElectron(electron) {
  if (patchedElectron) {
    return patchedElectron;
  }
  const overrides = {};

  if (nativeFrames) {
    overrides.BrowserWindow = framedWindowClass(electron);

    // The in-page title bar is a separate web contents (a view hosted by the window), so
    // the CSS goes into every web contents, not only the window's own page. Navigation
    // drops inserted CSS, so it is inserted again on every page load.
    if (globalMenuActive(electron)) {
      electron.app.on("web-contents-created", (_event, contents) => {
        contents.on("dom-ready", () => {
          contents.insertCSS(IN_PAGE_MENU_CSS).catch((error) => {
            require("fs").writeSync(2, `[archrepo] insertCSS failed: ${error}\n`);
          });
        });
      });
    }
  }

  // CLAUDE_DESKTOP_THEME_SYNC=0 leaves the theme and the tray icon to upstream.
  if (themeSync) {
    try {
      Object.assign(overrides, require("./archrepo-theme-sync.js").install(electron));
    } catch (error) {
      require("fs").writeSync(2, `[archrepo] theme sync failed to start: ${error}\n`);
    }
  }

  const descriptors = {};
  for (const [name, value] of Object.entries(overrides)) {
    descriptors[name] = { value, enumerable: true };
  }
  patchedElectron = Object.create(electron, descriptors);
  return patchedElectron;
}

// CLAUDE_DESKTOP_CSD=1 keeps upstream's frameless windows. With that and
// CLAUDE_DESKTOP_THEME_SYNC=0 both set, electron is not touched at all.
if (process.platform === "linux" && (nativeFrames || themeSync)) {
  const load = Module._load;
  Module._load = function (request, parent, isMain) {
    const loaded = load.apply(this, arguments);
    return request === "electron" ? patchElectron(loaded) : loaded;
  };
}

require(path.join(__dirname, ORIGINAL_MAIN));
