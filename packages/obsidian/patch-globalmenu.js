const fs = require('fs');

const appAsarMain = process.argv[2];

if (!appAsarMain || !fs.existsSync(appAsarMain)) {
    console.error('Usage: node patch-globalmenu.js <path-to-app-asar-main.js>');
    process.exit(1);
}

// obsidian.asar needs no patching: on Linux its "set-menu" handler already
// gives each window its own menu with setMenu(), which Electron exports to the
// Global Menu (the !isMac guard in front of setApplicationMenu only skips the
// macOS app menu). Its main and help windows hide the menubar without
// auto-hide; the app-wide hook below adds auto-hide to every window, including
// those from an in-app updated obsidian.asar.

// ---------------------------------------------------------------------------
// Patch app.asar/main.js
// ---------------------------------------------------------------------------
let appContent = fs.readFileSync(appAsarMain, 'utf8');

if (appContent.includes('_globalApp.on(\'browser-window-created\'')) {
    console.log(`Global Menu integration already present in ${appAsarMain}`);
} else {
    const globalMenuBridgeCode = `
// ---------------------------------------------------------------------------
// KDE Plasma Global Menu & Window Menu Integration
// ---------------------------------------------------------------------------
if (process.platform === 'linux') {
    const { app: _globalApp } = require('electron');

    // Automatically enforce hidden in-window menubar for all BrowserWindows
    // so menus export cleanly to KDE Global Menu and toggle via Alt key
    _globalApp.on('browser-window-created', (_event, _win) => {
        try {
            if (typeof _win.setAutoHideMenuBar === 'function') {
                _win.setAutoHideMenuBar(true);
            }
            if (typeof _win.setMenuBarVisibility === 'function') {
                _win.setMenuBarVisibility(false);
            }
        } catch (_) {}
    });
}
`;

    // Append to end of app.asar/main.js
    appContent += '\n' + globalMenuBridgeCode;
    fs.writeFileSync(appAsarMain, appContent, 'utf8');
    console.log(`Successfully patched ${appAsarMain} with KDE Global Menu runtime bridge`);
}
