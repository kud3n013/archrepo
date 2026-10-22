// KDE Global Menu: Zalo's own application menu, on the main window only.
//
// Zalo's macOS bundle builds a full application menu (About, Preferences Ctrl+,, Close,
// Quit, Edit, View with Alt+1..3, Window) and sets it with Menu.setApplicationMenu() on
// Linux too, after loading the login or the main page. Its items send Zalo's own IPC
// ("about", "preferences", "switch_tab"), so no menu is written here.
//
// Upstream's shell removes menus: Menu.setApplicationMenu(null) on 'ready' and
// removeMenu() on every new window. On Linux, Electron applies the application menu to
// every open window, so Zalo's hidden background windows (Shared Worker, SQLite, the
// notification window) each exported a menu as well. This keeps the menu on the main
// window and removes it from every other window.
//
// Under X11/XWayland Electron exports the menu over DBusMenu and the Plasma registrar
// binds it to the window. Electron 22 exports punctuation shortcuts as "Ctrl+,";
// zalo.sh also preloads dbusmenu-shortcut-shim, which keeps them that way on newer
// Electron versions that export "Ctrl+comma".
"use strict";

function install({ electron, log, isMainWindow, enabled }) {
  const { Menu, BrowserWindow } = electron;
  const setApplicationMenu = Menu.setApplicationMenu;
  const removeMenu = BrowserWindow.prototype.removeMenu;

  // ZALO_GLOBALMENU=0: no application menu at all, which is what upstream's shell intends.
  if (!enabled) {
    Menu.setApplicationMenu = function () {
      return setApplicationMenu.call(this, null);
    };
    log("global menu disabled (ZALO_GLOBALMENU=0)");
    return;
  }

  Menu.setApplicationMenu = function (menu) {
    // Upstream's null on 'ready' would remove Zalo's menu if Zalo ever set it first.
    if (menu === null) {
      return;
    }
    setApplicationMenu.call(this, menu);
    for (const win of BrowserWindow.getAllWindows()) {
      if (!win.isDestroyed() && !isMainWindow(win)) {
        removeMenu.call(win);
      }
    }
    log("application menu set on the main window");
  };

  // Electron gives every new window the application menu, and upstream then calls
  // removeMenu() on it. The main window keeps its menu with the in-window bar hidden.
  // Where no Global Menu is available, Alt shows the bar.
  BrowserWindow.prototype.removeMenu = function () {
    if (!isMainWindow(this)) {
      return removeMenu.call(this);
    }
    this.setAutoHideMenuBar(true);
    this.setMenuBarVisibility(false);
  };
}

module.exports = { install };
