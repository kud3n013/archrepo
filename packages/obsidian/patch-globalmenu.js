const fs = require('fs');
const path = require('path');

const appAsarMain = process.argv[2];
const obsidianAsarMain = process.argv[3];

if (!appAsarMain || !fs.existsSync(appAsarMain)) {
    console.error('Usage: node patch-globalmenu.js <path-to-app-asar-main.js> [path-to-obsidian-asar-main.js]');
    process.exit(1);
}

// ---------------------------------------------------------------------------
// 1. Patch app.asar/main.js
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

    // Dynamic runtime patch for obsidian.asar (including in-app updates in user data)
    const _origJs = require.extensions['.js'];
    require.extensions['.js'] = function(_module, _filename) {
        if (_filename.includes('obsidian') && _filename.endsWith('main.js') && !_filename.includes('app.asar')) {
            try {
                let _code = fs.readFileSync(_filename, 'utf8');
                let _patched = false;
                if (_code.includes('if(!o||!W)return;let r=De(o);l.Menu.setApplicationMenu(r)')) {
                    _code = _code.replace('if(!o||!W)return;let r=De(o);l.Menu.setApplicationMenu(r)', 'if(!o)return;let r=De(o);l.Menu.setApplicationMenu(r)');
                    _patched = true;
                }
                if (_code.includes('show:!1,frame:Ae,titleBarStyle:Ue')) {
                    _code = _code.replaceAll('show:!1,frame:Ae,titleBarStyle:Ue', 'show:!1,autoHideMenuBar:!0,frame:Ae,titleBarStyle:Ue');
                    _patched = true;
                }
                if (_code.includes('g.menuBarVisible=!1')) {
                    _code = _code.replace('g.menuBarVisible=!1', 'g.setAutoHideMenuBar(!0),g.setMenuBarVisibility(!1)');
                    _patched = true;
                }
                if (_code.includes('r.menuBarVisible=!1')) {
                    _code = _code.replace('r.menuBarVisible=!1', 'r.setAutoHideMenuBar(!0),r.setMenuBarVisibility(!1)');
                    _patched = true;
                }
                if (_patched) {
                    return _module._compile(_code, _filename);
                }
            } catch (_) {}
        }
        return _origJs(_module, _filename);
    };
}
`;

    // Append to end of app.asar/main.js
    appContent += '\n' + globalMenuBridgeCode;
    fs.writeFileSync(appAsarMain, appContent, 'utf8');
    console.log(`Successfully patched ${appAsarMain} with KDE Global Menu runtime bridge`);
}

// ---------------------------------------------------------------------------
// 2. Patch obsidian.asar/main.js (if provided)
// ---------------------------------------------------------------------------
if (obsidianAsarMain) {
    if (!fs.existsSync(obsidianAsarMain)) {
        console.error(`Error: File not found: ${obsidianAsarMain}`);
        process.exit(1);
    }

    let obsContent = fs.readFileSync(obsidianAsarMain, 'utf8');
    let patchedCount = 0;

    // 1. autoHideMenuBar in window creation options
    const targetOptions = 'show:!1,frame:Ae,titleBarStyle:Ue';
    const replOptions = 'show:!1,autoHideMenuBar:!0,frame:Ae,titleBarStyle:Ue';
    if (obsContent.includes(targetOptions)) {
        obsContent = obsContent.replaceAll(targetOptions, replOptions);
        patchedCount++;
    }

    // 2. setAutoHideMenuBar and setMenuBarVisibility on window creation
    if (obsContent.includes('g.menuBarVisible=!1')) {
        obsContent = obsContent.replace('g.menuBarVisible=!1', 'g.setAutoHideMenuBar(!0),g.setMenuBarVisibility(!1)');
        patchedCount++;
    }
    if (obsContent.includes('r.menuBarVisible=!1')) {
        obsContent = obsContent.replace('r.menuBarVisible=!1', 'r.setAutoHideMenuBar(!0),r.setMenuBarVisibility(!1)');
        patchedCount++;
    }

    // 3. Export application menu on Linux in Le()
    const targetLe = 'if(!o||!W)return;let r=De(o);l.Menu.setApplicationMenu(r)';
    const replLe = 'if(!o)return;let r=De(o);l.Menu.setApplicationMenu(r)';
    if (obsContent.includes(targetLe)) {
        obsContent = obsContent.replace(targetLe, replLe);
        patchedCount++;
    }

    fs.writeFileSync(obsidianAsarMain, obsContent, 'utf8');
    console.log(`Successfully patched ${obsidianAsarMain} (${patchedCount} transformations applied)`);
}
