// Linux desktop integration for the Z-Library desktop app.
//
// Upstream's main window is frameless and draws Close, Maximize ("dock") and
// Minimize ("remove") buttons at the end of its tab strip. Its main process is an
// ES module (dist-electron/main.js). This file runs before it, from app.asar, and
// on Linux:
//
//   1. turns off the in-app updater, so pacman owns updates,
//   2. drops the remote debugging port upstream always opens on 127.0.0.1:9222,
//   3. gives the main window the window manager's frame, and sends the frame's
//      close button through the app's own close flow (the "keep tabs?" prompt),
//   4. adds Quit, View, Window and Help to upstream's application menu, so the
//      KDE Global Menu (or the Alt menu bar elsewhere) has the usual entries,
//   5. hides the in-page window buttons, which the frame now replaces.
//
// No upstream file is modified. patch-asar.js writes this file into app.asar and
// fills in the original entry point.
"use strict";

const fs = require("fs");
const path = require("path");
const Module = require("module");
const { pathToFileURL } = require("url");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// The main window is the only one created with this preload. The loading window
// (a fixed-size, frameless splash) and the debug window (already framed) keep
// upstream's options.
const MAIN_WINDOW_PRELOAD = "mainWindowPreload.cjs";

// Upstream's window buttons are the first three entries of the tab strip's action
// group; the rest of the group (tools, settings, notifications, profile, donate,
// vertical tabs) is app UI and stays. Each button holds a single <img> whose alt
// names the action.
const WINDOW_BUTTONS = ["close", "dock", "remove"];
const WINDOW_BUTTONS_CSS =
  WINDOW_BUTTONS.map((alt) => `.top-bar__actions > .top-bar__actions-button:has(> img[alt="${alt}"])`).join(",\n") +
  " { display: none !important; }";

// Runs in the app's own pages. Resolves to the window buttons that are missing
// once the tab strip exists, so a renamed class or icon shows up in the log.
const CHECK_WINDOW_BUTTONS = `new Promise((resolve) => {
  const check = () => {
    const bar = document.querySelector(".top-bar__actions");
    if (!bar) return false;
    resolve(${JSON.stringify(WINDOW_BUTTONS)}.filter((alt) => !bar.querySelector(':scope > .top-bar__actions-button > img[alt="' + alt + '"]')));
    return true;
  };
  if (check()) return;
  const observer = new MutationObserver(() => check() && observer.disconnect());
  observer.observe(document.documentElement, { childList: true, subtree: true });
})`;

// The in-page close button calls this preload API: it asks whether to keep the
// open tabs (unless the user turned the prompt off), saves them and quits.
const CLOSE_LIKE_IN_PAGE = `(() => {
  const api = window.homeOverlayViewAPI;
  if (typeof api?.close !== "function") return false;
  api.close();
  return true;
})()`;

const ELECTRON_SHIM_URL = "archrepo:electron";
const ELECTRON_SHIM_KEY = "archrepo.electron";

function log(message) {
  // process.stderr writes are lost once Electron takes over stdio, so write to fd 2.
  try {
    fs.writeSync(2, `[archrepo] ${message}\n`);
  } catch {}
}

const appRequire = Module.createRequire(path.join(__dirname, ORIGINAL_MAIN));

// Upstream asks its API for an electron-updater feed and, as a .deb build, would
// install updates with dpkg. The update checks resolve to "no update" instead, so
// the update prompt never appears.
function disableUpdater() {
  try {
    const { AppUpdater, BaseUpdater } = appRequire("electron-updater");
    AppUpdater.prototype.checkForUpdates = async () => null;
    AppUpdater.prototype.checkForUpdatesAndNotify = async () => null;
    AppUpdater.prototype.downloadUpdate = async () => [];
    BaseUpdater.prototype.quitAndInstall = () => {};
    log("in-app updater disabled, pacman handles updates");
  } catch (error) {
    log(`could not disable the in-app updater: ${error}`);
  }
}

// Upstream appends --remote-debugging-port=9222 unconditionally, which lets any
// local process drive the signed-in app. A port passed on the command line still
// works.
function dropRemoteDebuggingPort(app) {
  const { commandLine } = app;
  const appendSwitch = commandLine.appendSwitch;
  commandLine.appendSwitch = function (name, ...rest) {
    if (String(name).replace(/^-+/, "") === "remote-debugging-port") {
      log("remote debugging port 9222 not opened");
      return;
    }
    return appendSwitch.call(this, name, ...rest);
  };
}

function isMainWindow(options) {
  const preload = options?.webPreferences?.preload;
  return typeof preload === "string" && path.basename(preload) === MAIN_WINDOW_PRELOAD;
}

function isAppPage(contents) {
  return !contents.isDestroyed() && contents.getURL().startsWith("file://");
}

// Runs the in-page close action in the topmost of the window's views that has it.
// Resolves to false if none does (for example before the UI has loaded).
async function closeLikeInPage(win) {
  const views = [...(win.contentView?.children ?? [])].reverse();
  for (const view of views) {
    const contents = view.webContents;
    if (!contents || !isAppPage(contents)) {
      continue;
    }
    try {
      if (await contents.executeJavaScript(CLOSE_LIKE_IN_PAGE)) {
        return true;
      }
    } catch {}
  }
  return false;
}

let quitting = false;

function mainWindow(BrowserWindow) {
  return BrowserWindow.getAllWindows().find((win) => win.archrepoMainWindow && !win.isDestroyed());
}

async function quit(electron) {
  const win = mainWindow(electron.BrowserWindow);
  if (!win || !(await closeLikeInPage(win))) {
    electron.app.quit();
  }
}

// Upstream's menu items, rebuilt as a template so items can be added to them.
function toTemplate(item) {
  const template = {};
  for (const key of ["label", "type", "role", "accelerator", "enabled", "visible", "checked", "registerAccelerator"]) {
    if (item[key] !== undefined && item[key] !== null) {
      template[key] = item[key];
    }
  }
  if (item.submenu) {
    template.submenu = item.submenu.items.map(toTemplate);
  } else if (!item.role) {
    template.click = (...args) => item.click(...args);
  }
  return template;
}

// Upstream's menu (Library, Edit, Navigation) is kept as it is, with its items and
// shortcuts. Before upstream sets it, during the loading window, only the added
// entries are shown.
function linuxMenuTemplate(electron, upstreamMenu) {
  const { app, dialog } = electron;
  const name = app.getName();
  const template = (upstreamMenu?.items ?? []).map(toTemplate);

  const quitItem = { label: "Quit", accelerator: "Ctrl+Q", click: () => quit(electron) };
  const library = template.find((item) => item.label === "Library" && Array.isArray(item.submenu));
  if (library) {
    library.submenu.push({ type: "separator" }, quitItem);
  } else {
    if (upstreamMenu) {
      log("upstream menu has no Library entry; Quit added on its own");
    }
    template.unshift({ label: "&Library", submenu: [quitItem] });
  }

  const about = (_item, win) => {
    dialog.showMessageBox(win ?? undefined, {
      type: "info",
      title: `About ${name}`,
      message: name,
      detail: `Version ${app.getVersion()}\nElectron ${process.versions.electron}\nChromium ${process.versions.chrome}`,
      buttons: ["OK"],
    });
  };

  template.push(
    { label: "&View", submenu: [{ role: "togglefullscreen" }] },
    {
      label: "&Window",
      submenu: [
        { label: "Minimize", click: (_item, win) => win?.minimize() },
        { label: "Maximize", click: (_item, win) => (win?.isMaximized() ? win.unmaximize() : win?.maximize()) },
      ],
    },
    { label: "&Help", submenu: [{ label: `About ${name}`, click: about }] },
  );
  return template;
}

function patchElectron(electron) {
  const { app, BrowserWindow, Menu } = electron;

  // A subclass, not a wrapper, so statics and instanceof keep working.
  class FramedBrowserWindow extends BrowserWindow {
    constructor(options = {}) {
      const main = isMainWindow(options);
      super(main ? { ...options, frame: true, autoHideMenuBar: true } : options);

      // The app's pages are titled "Vite + React + TS", which would show in the
      // title bar and task manager. Windows keep the app name (or upstream's title).
      this.on("page-title-updated", (event) => event.preventDefault());

      if (!main) {
        return;
      }
      this.archrepoMainWindow = true;
      log("main window: native frame");

      // Closing the main window quits the app. Upstream's own close button first
      // offers to keep the open tabs and saves them; the frame's button does the same.
      let closeNow = false;
      this.on("close", (event) => {
        if (closeNow || quitting) {
          return;
        }
        event.preventDefault();
        closeLikeInPage(this).then((handled) => {
          if (!handled && !this.isDestroyed()) {
            closeNow = true;
            this.close();
          }
        });
      });
    }
  }
  // Electron's getAllWindows() and getFocusedWindow() keep only windows whose
  // constructor is named "BrowserWindow".
  Object.defineProperty(FramedBrowserWindow, "name", { value: "BrowserWindow" });

  // Menu is a native class, so it is wrapped rather than subclassed: `new Menu()`
  // and the other statics go to Electron's Menu unchanged.
  const setApplicationMenu = (menu) => {
    if (menu === null) {
      return Menu.setApplicationMenu(null);
    }
    log(menu ? "application menu: upstream menu plus Quit, View, Window, Help" : "application menu: initial");
    return Menu.setApplicationMenu(Menu.buildFromTemplate(linuxMenuTemplate(patchedElectron, menu)));
  };
  const LinuxMenu = new Proxy(Menu, {
    get(target, property, receiver) {
      return property === "setApplicationMenu" ? setApplicationMenu : Reflect.get(target, property, receiver);
    },
  });

  app.on("before-quit", () => {
    quitting = true;
  });

  // Electron sets its default menu (with Reload and Developer Tools) when the app
  // is ready; it is replaced until upstream sets its own after sign-in.
  app.whenReady().then(() => setApplicationMenu(undefined));

  // Navigation drops inserted CSS, so it is inserted again on every page load. Only
  // the app's own pages get it, not the library's web pages shown in tabs.
  app.on("web-contents-created", (_event, contents) => {
    contents.on("dom-ready", () => {
      if (!isAppPage(contents)) {
        return;
      }
      contents.insertCSS(WINDOW_BUTTONS_CSS).catch((error) => log(`insertCSS failed: ${error}`));
    });
    contents.once("did-finish-load", () => {
      if (!isAppPage(contents)) {
        return;
      }
      contents
        .executeJavaScript(CHECK_WINDOW_BUTTONS)
        .then((missing) => {
          if (missing.length > 0) {
            log(`in-page window buttons not found (${missing.join(", ")}); upstream may have changed its markup`);
          } else {
            log("in-page window buttons hidden");
          }
        })
        .catch(() => {});
    });
  });

  // Every export as an own property (the ES module shim below lists them), with
  // BrowserWindow and Menu replaced.
  const patchedElectron = {};
  for (const key of Object.keys(electron)) {
    Object.defineProperty(patchedElectron, key, { enumerable: true, configurable: true, get: () => electron[key] });
  }
  Object.defineProperty(patchedElectron, "BrowserWindow", { enumerable: true, value: FramedBrowserWindow });
  Object.defineProperty(patchedElectron, "Menu", { enumerable: true, value: LinuxMenu });
  return patchedElectron;
}

// Electron gives ES modules the electron module through its own loader, which
// neither Module._load nor the CommonJS cache reach. A module loader hook sends
// `import ... from "electron"` (and "electron/main", "electron/common") to a shim
// module that re-exports the patched object. CommonJS requires are covered too.
function hookElectron(electron) {
  const patched = patchElectron(electron);
  globalThis[Symbol.for(ELECTRON_SHIM_KEY)] = patched;

  const names = Object.keys(patched).filter((name) => /^[A-Za-z_$][\w$]*$/.test(name));
  const shim = [
    `const electron = globalThis[Symbol.for(${JSON.stringify(ELECTRON_SHIM_KEY)})];`,
    "export default electron;",
    ...names.map((name) => `export const ${name} = electron.${name};`),
  ].join("\n");
  const hooks = `
const SHIM_URL = ${JSON.stringify(ELECTRON_SHIM_URL)};
const SOURCE = ${JSON.stringify(shim)};
export async function resolve(specifier, context, nextResolve) {
  if (specifier === "electron" || specifier.startsWith("electron/")) {
    return { url: SHIM_URL, shortCircuit: true };
  }
  return nextResolve(specifier, context);
}
export async function load(url, context, nextLoad) {
  if (url === SHIM_URL) {
    return { format: "module", source: SOURCE, shortCircuit: true };
  }
  return nextLoad(url, context);
}
`;
  try {
    Module.register(`data:text/javascript,${encodeURIComponent(hooks)}`);
  } catch (error) {
    log(`could not hook the electron module, keeping upstream's window: ${error}`);
    return;
  }

  const load = Module._load;
  Module._load = function (request) {
    const loaded = load.apply(this, arguments);
    return request === "electron" || request.startsWith("electron/") ? patched : loaded;
  };
}

if (process.platform === "linux") {
  const electron = require("electron");
  disableUpdater();
  dropRemoteDebuggingPort(electron.app);
  // Z_LIBRARY_CSD=1 keeps upstream's frameless window, in-page buttons and menu.
  if (process.env.Z_LIBRARY_CSD !== "1") {
    hookElectron(electron);
  }
}

import(pathToFileURL(path.join(__dirname, ORIGINAL_MAIN)).href).catch((error) => {
  log(`could not load ${ORIGINAL_MAIN}`);
  throw error;
});
