// Linux desktop integration for Google Antigravity.
//
// Upstream creates its windows frameless with a Window Controls Overlay and draws
// its own menu bar (Antigravity / File / View / Window) inside the page. This file
// runs before the app's entry point, from app.asar, and on Linux:
//
//   1. gives app windows the window manager's frame,
//   2. replaces Electron's default application menu with one that mirrors the
//      in-page menu bar, so the KDE Global Menu (or the Alt menu bar elsewhere)
//      shows the app's own commands,
//   3. hides the in-page menu bar, which the native menu now replaces,
//   4. keeps the window background in step with the system light/dark setting.
//
// No upstream file is modified. patch-asar.js writes this file into app.asar and
// fills in the original entry point.
"use strict";

const fs = require("fs");
const path = require("path");
const Module = require("module");

const ORIGINAL_MAIN = "__ORIGINAL_MAIN__";

// Colors upstream uses for the window background (dist/utils.js createWindow).
const BACKGROUND = { dark: "#131313", light: "#FAFAFA" };

// The in-page menu bar is a 35px row whose only child is [data-testid="title-menu-bar"].
// The row is hidden, not just the bar, so no empty strip is left above the header.
const IN_PAGE_MENU_CSS = `div:has(> [data-testid="title-menu-bar"]) { display: none !important; }`;

// The app's own shortcuts (see the keybindings in the web UI). The native menu shows
// them and, when an item is clicked, sends the same keystroke to the page. Items set
// registerAccelerator: false, so a real key press still goes straight to the page and
// behaves exactly as upstream. For the same reason the window items carry no
// accelerator: Electron's defaults (Ctrl+W, Ctrl+M) are the page's "close terminal
// tab" and "voice recording" keys.
const SHORTCUTS = {
  newConversation: "Ctrl+N",
  openWorkspace: "Ctrl+O",
  commandPalette: "Ctrl+Shift+P",
  searchConversations: "Ctrl+K",
  settings: "Ctrl+,",
  toggleSidebar: "Ctrl+B",
  toggleTerminal: "Ctrl+J",
  toggleAuxPane: "Ctrl+Alt+B",
  toggleFileViewer: "Ctrl+Shift+E",
  zoomIn: "Ctrl+=",
  zoomOut: "Ctrl+-",
  zoomReset: "Ctrl+0",
};

function log(message) {
  // process.stderr writes are lost once Electron takes over stdio, so write to fd 2.
  try {
    fs.writeSync(2, `[archrepo] ${message}\n`);
  } catch {}
}

function appModule(name) {
  return require(path.join(__dirname, path.dirname(ORIGINAL_MAIN), name));
}

// The page follows the desktop theme unless the user picked Light or Dark in the
// app's settings (no themeMode at all also means "follow the system"). Upstream's
// main process reads the same setting but treats a missing value as dark.
function followsSystemTheme() {
  let mode = "";
  try {
    const settingsPath = appModule("paths").getSettingsPbPath();
    mode = JSON.parse(fs.readFileSync(settingsPath, "utf8"))?.userSettings?.themeMode ?? "";
  } catch {}
  return !mode.includes("LIGHT") && !mode.includes("DARK");
}

function systemBackground(nativeTheme) {
  return nativeTheme.shouldUseDarkColors ? BACKGROUND.dark : BACKGROUND.light;
}

function sendShortcut(win, accelerator) {
  if (!win || win.isDestroyed()) {
    return;
  }
  const parts = accelerator.split("+");
  let keyCode = parts.pop();
  // An empty last part means the key itself is "+" (e.g. "Ctrl++").
  if (keyCode === "") {
    keyCode = "Plus";
  }
  const modifiers = parts.map((part) => ({ Ctrl: "control", Shift: "shift", Alt: "alt" })[part]);
  // Letters are sent in lower case: the page matches event.key, and an upper-case
  // key without Shift would not match.
  if (/^[A-Z]$/.test(keyCode) && !modifiers.includes("shift")) {
    keyCode = keyCode.toLowerCase();
  }
  win.focus();
  win.webContents.focus();
  win.webContents.sendInputEvent({ type: "keyDown", keyCode, modifiers });
  win.webContents.sendInputEvent({ type: "keyUp", keyCode, modifiers });
}

function shortcutItem(label, accelerator) {
  return {
    label,
    accelerator,
    registerAccelerator: false,
    click: (_item, win) => sendShortcut(win, accelerator),
  };
}

function clickInPage(win, selector) {
  if (!win || win.isDestroyed()) {
    return;
  }
  win.webContents
    .executeJavaScript(`document.querySelector(${JSON.stringify(selector)})?.click()`)
    .catch((error) => log(`menu action failed: ${error}`));
}

function buildMenuTemplate(electron) {
  const { app, shell, dialog, BrowserWindow } = electron;
  const name = app.getName();

  const newWindow = (_item, win) => {
    const target = win ?? BrowserWindow.getAllWindows()[0];
    if (!target) {
      return;
    }
    const origin = new URL(target.webContents.getURL()).origin;
    appModule("utils").createWindow(`${origin}/`);
  };

  // Ctrl+Q goes through upstream's own key handler, which asks before quitting.
  // The menu item does the same.
  const quit = () => {
    appModule("utils").setShowQuitConfirmation(true);
    app.quit();
  };

  const closeWindow = (_item, win) => win?.close();

  const about = (_item, win) => {
    dialog.showMessageBox(win ?? undefined, {
      type: "info",
      title: `About ${name}`,
      message: name,
      detail: `Version ${app.getVersion()}\nElectron ${process.versions.electron}\nChromium ${process.versions.chrome}`,
      buttons: ["OK"],
    });
  };

  return [
    {
      label: "&File",
      submenu: [
        shortcutItem("New Conversation", SHORTCUTS.newConversation),
        { label: "New Window", accelerator: "Ctrl+Shift+N", registerAccelerator: false, click: newWindow },
        { label: "Create Project…", click: (_item, win) => clickInPage(win, '[data-testid="sidebar-add-project-button"]') },
        shortcutItem("Open Workspace…", SHORTCUTS.openWorkspace),
        { type: "separator" },
        shortcutItem("Command Palette…", SHORTCUTS.commandPalette),
        shortcutItem("Search Conversations…", SHORTCUTS.searchConversations),
        { type: "separator" },
        shortcutItem("Settings", SHORTCUTS.settings),
        { type: "separator" },
        { label: "Close Window", click: closeWindow },
        { label: "Quit", accelerator: "Ctrl+Q", registerAccelerator: false, click: quit },
      ],
    },
    {
      label: "&Edit",
      submenu: [
        { role: "undo" },
        { role: "redo" },
        { type: "separator" },
        { role: "cut" },
        { role: "copy" },
        { role: "paste" },
        { role: "selectAll" },
      ],
    },
    {
      label: "&View",
      submenu: [
        shortcutItem("Toggle Sidebar", SHORTCUTS.toggleSidebar),
        shortcutItem("Toggle Terminal", SHORTCUTS.toggleTerminal),
        shortcutItem("Toggle Auxiliary Pane", SHORTCUTS.toggleAuxPane),
        shortcutItem("Toggle File Viewer", SHORTCUTS.toggleFileViewer),
        { type: "separator" },
        shortcutItem("Zoom In", SHORTCUTS.zoomIn),
        shortcutItem("Zoom Out", SHORTCUTS.zoomOut),
        shortcutItem("Reset Zoom", SHORTCUTS.zoomReset),
        { type: "separator" },
        { role: "togglefullscreen" },
      ],
    },
    {
      label: "&Window",
      submenu: [
        { label: "Minimize", click: (_item, win) => win?.minimize() },
        {
          label: "Maximize",
          click: (_item, win) => (win?.isMaximized() ? win.unmaximize() : win?.maximize()),
        },
        { type: "separator" },
        { label: "Close", click: closeWindow },
      ],
    },
    {
      label: "&Help",
      submenu: [
        { label: "Docs", click: () => shell.openExternal("https://antigravity.google/docs") },
        { type: "separator" },
        { label: `About ${name}`, click: about },
      ],
    },
  ];
}

// Upstream's native frame is Windows-only through titleBarOverlay; on Linux the page
// would otherwise draw a frameless window with Chromium's overlay controls.
function withNativeFrame(options, nativeTheme) {
  const { titleBarStyle, titleBarOverlay, trafficLightPosition, ...rest } = options;
  const framed = { ...rest, frame: true, autoHideMenuBar: true };
  if (followsSystemTheme()) {
    framed.backgroundColor = systemBackground(nativeTheme);
  }
  return framed;
}

let patchedElectron = null;

function patchElectron(electron) {
  if (patchedElectron) {
    return patchedElectron;
  }
  const { BrowserWindow, Menu, nativeTheme, app } = electron;

  // A subclass, not a wrapper, so statics and instanceof keep working.
  class FramedBrowserWindow extends BrowserWindow {
    constructor(options = {}) {
      super(options.frame === false ? options : withNativeFrame(options, nativeTheme));
    }

    // Only meaningful with a Window Controls Overlay.
    setTitleBarOverlay() {}
  }
  // Electron's getAllWindows() and getFocusedWindow() keep only windows whose
  // constructor is named "BrowserWindow". Without this they return nothing, and
  // upstream's tray "Open" and IPC handlers stop finding the window.
  Object.defineProperty(FramedBrowserWindow, "name", { value: "BrowserWindow" });

  // Upstream edits Electron's default menu (File / Edit / View / Window / Help) and
  // sets it once the language server is up. The Linux menu is put in its place.
  class LinuxMenu extends Menu {
    static setApplicationMenu(menu) {
      if (menu === null) {
        return Menu.setApplicationMenu(null);
      }
      return Menu.setApplicationMenu(Menu.buildFromTemplate(buildMenuTemplate(electron)));
    }
  }

  // Navigation drops inserted CSS, so it is inserted again on every page load.
  app.on("web-contents-created", (_event, contents) => {
    contents.on("dom-ready", () => {
      if (contents.getType() !== "window") {
        return;
      }
      contents.insertCSS(IN_PAGE_MENU_CSS).catch((error) => log(`insertCSS failed: ${error}`));
    });
  });

  // The page follows the desktop theme by itself: Chromium reads the XDG portal's
  // color-scheme and updates prefers-color-scheme live. The window background is
  // only set at creation, so it is kept in step here to avoid a wrong-colored flash
  // behind the page on resize.
  nativeTheme.on("updated", () => {
    if (!followsSystemTheme()) {
      return;
    }
    for (const win of BrowserWindow.getAllWindows()) {
      win.setBackgroundColor(systemBackground(nativeTheme));
    }
  });

  patchedElectron = Object.create(electron, {
    BrowserWindow: { value: FramedBrowserWindow, enumerable: true },
    Menu: { value: LinuxMenu, enumerable: true },
  });
  return patchedElectron;
}

// ANTIGRAVITY_CSD=1 keeps upstream's frameless window and in-page menu bar.
if (process.platform === "linux" && process.env.ANTIGRAVITY_CSD !== "1") {
  const load = Module._load;
  Module._load = function (request, parent, isMain) {
    const loaded = load.apply(this, arguments);
    return request === "electron" ? patchElectron(loaded) : loaded;
  };
}

require(path.join(__dirname, ORIGINAL_MAIN));
