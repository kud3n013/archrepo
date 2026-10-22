// Title bar: the window manager's frame, without a second title bar in the page.
//
// Upstream's scripts/patches/patch-titlebar.js creates Zalo's main window with
// frame:!global.__zaloNativeWayland, so on X11/XWayland the window manager draws its
// title bar. Zalo's macOS bundle still renders its own 24px strip, #titleBar
// ("Zalo - {name}"), at the top of the main page. This hides it. Zalo hides the same
// strip itself in some states (.titlebar--display { display: none }), so the layout
// supports it.
//
// On native Wayland the main window stays frameless, and upstream's
// plugins/wayland-titlebar adds the window buttons to that strip, so it is left alone.
// Chat windows popped out of the main window are always frameless and keep their strip.
"use strict";

const IN_PAGE_TITLEBAR_CSS = "#titleBar { display: none !important; }";

function install({ electron, log, isMainWindow }) {
  electron.app.on("browser-window-created", (_event, win) => {
    // Upstream's plugins/wayland-titlebar sets the flag before Zalo creates its windows.
    if (!isMainWindow(win) || global.__zaloNativeWayland) {
      return;
    }
    log("native title bar: hiding the in-page title bar");
    // Navigation drops inserted CSS, so it is inserted again on every page load.
    win.webContents.on("dom-ready", () => {
      win.webContents.insertCSS(IN_PAGE_TITLEBAR_CSS).catch((error) => {
        log(`insertCSS failed: ${error}`);
      });
    });
  });
}

module.exports = { install };
