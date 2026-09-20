#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

let utilsPath = null;
let preloadPath = null;
let menuPath = null;

const arg1 = process.argv[2];
const arg2 = process.argv[3];
const arg3 = process.argv[4];

if (!arg1) {
    console.error('Usage: node patch-window-controls.js <path-to-dist/utils.js | dir> [path-to-dist/preload.js] [path-to-dist/menu.js]');
    process.exit(1);
}

const resolvedArg1 = path.resolve(arg1);
if (fs.existsSync(resolvedArg1) && fs.statSync(resolvedArg1).isDirectory()) {
    utilsPath = path.join(resolvedArg1, 'dist', 'utils.js');
    if (!fs.existsSync(utilsPath)) utilsPath = path.join(resolvedArg1, 'utils.js');
    preloadPath = path.join(resolvedArg1, 'dist', 'preload.js');
    if (!fs.existsSync(preloadPath)) preloadPath = path.join(resolvedArg1, 'preload.js');
    menuPath = path.join(resolvedArg1, 'dist', 'menu.js');
    if (!fs.existsSync(menuPath)) menuPath = path.join(resolvedArg1, 'menu.js');
} else {
    utilsPath = resolvedArg1;
    const baseDir = path.dirname(utilsPath);
    preloadPath = arg2 ? path.resolve(arg2) : path.join(baseDir, 'preload.js');
    menuPath = arg3 ? path.resolve(arg3) : path.join(baseDir, 'menu.js');
}

if (!fs.existsSync(utilsPath)) {
    console.error(`Error: utils.js not found at ${utilsPath}`);
    process.exit(1);
}

// ---------------------------------------------------------------------------
// 1. Patch dist/utils.js
// ---------------------------------------------------------------------------
let utilsContent = fs.readFileSync(utilsPath, 'utf8');

const replacementTitlebar = `        autoHideMenuBar: true,
        titleBarStyle: (isMacOS() ||
            process.env.ANTIGRAVITY_TITLEBAR === 'hidden' ||
            (process.argv && process.argv.includes('--titlebar=hidden')) ||
            process.env.ANTIGRAVITY_TITLEBAR === 'overlay' ||
            (process.argv && process.argv.includes('--titlebar=overlay')))
            ? 'hidden'
            : undefined,
        titleBarOverlay: (!isMacOS() && (
            process.env.ANTIGRAVITY_TITLEBAR === 'overlay' ||
            (process.argv && process.argv.includes('--titlebar=overlay'))))
            ? {
                color: backgroundColor,
                symbolColor: foregroundColor,
                height: 30,
            }
            : false,
        backgroundColor,`;

const titlebarRegex = /^[ \t]*(autoHideMenuBar:\s*true,\s*)?titleBarStyle:\s*[\s\S]*?titleBarOverlay:\s*[\s\S]*?(height:\s*30,\s*\},?\s*(:\s*false,?)?|false,\s*)\s*backgroundColor,/m;

if (titlebarRegex.test(utilsContent)) {
    utilsContent = utilsContent.replace(titlebarRegex, replacementTitlebar);
} else {
    console.error('Error: Could not locate titleBarStyle/titleBarOverlay definition in utils.js');
    process.exit(1);
}

const ensureHostVariantSnippet = `
function ensureHostVariant(rawUrl) {
    if (!rawUrl || typeof rawUrl !== 'string') return rawUrl;
    try {
        const u = new URL(rawUrl);
        if (!u.searchParams.has('hostVariant')) {
            u.searchParams.set('hostVariant', 'gemini-app');
            return u.toString();
        }
    } catch {
        if (!rawUrl.includes('hostVariant=gemini-app')) {
            const sep = rawUrl.includes('?') ? '&' : '?';
            return rawUrl + sep + 'hostVariant=gemini-app';
        }
    }
    return rawUrl;
}
`;

if (!utilsContent.includes('function ensureHostVariant(')) {
    utilsContent = utilsContent.replace('function createWindow(url, storageManager) {', ensureHostVariantSnippet + 'function createWindow(url, storageManager) {\n    url = ensureHostVariant(url);');
}

const winCreationTargetRegex = /(webPreferences:\s*\{[\s\S]*?devTools:\s*!electron_1\.app\.isPackaged,\s*\},?\s*\}\);)/;
const winCreationAddition = `$1
    const origLoadURL = win.loadURL.bind(win);
    win.loadURL = (targetUrl, options) => origLoadURL(ensureHostVariant(targetUrl), options);
    if (typeof win.setAutoHideMenuBar === 'function') {
        win.setAutoHideMenuBar(true);
        win.setMenuBarVisibility(false);
    }`;

if (!utilsContent.includes('const origLoadURL = win.loadURL.bind(win);')) {
    utilsContent = utilsContent.replace(/\s*if\s*\(typeof win\.setAutoHideMenuBar === 'function'\)\s*\{\s*win\.setAutoHideMenuBar\(true\);\s*win\.setMenuBarVisibility\(false\);\s*\}/g, '');
    if (winCreationTargetRegex.test(utilsContent)) {
        utilsContent = utilsContent.replace(winCreationTargetRegex, winCreationAddition);
    } else {
        console.error('Error: Could not locate BrowserWindow creation in utils.js');
        process.exit(1);
    }
}

fs.writeFileSync(utilsPath, utilsContent, 'utf8');
console.log(`Successfully patched ${utilsPath}`);

// ---------------------------------------------------------------------------
// 2. Patch dist/preload.js
// ---------------------------------------------------------------------------
if (preloadPath && fs.existsSync(preloadPath)) {
    let preloadContent = fs.readFileSync(preloadPath, 'utf8');
    const preloadMarker = '/* antigravity-runtime-patch */';
    if (!preloadContent.includes(preloadMarker)) {
        // Strip previous patch marker if present
        preloadContent = preloadContent.replace(/\/\* antigravity-host-variant-patch \*\/[\s\S]*?\} catch \(_e\) \{\}\s*\n/, '');
        const preloadPatch = `${preloadMarker}
try {
    const currentUrl = new URL(window.location.href);
    if (currentUrl.protocol.startsWith('http') && currentUrl.searchParams.get('hostVariant') !== 'gemini-app') {
        currentUrl.searchParams.set('hostVariant', 'gemini-app');
        window.history.replaceState(null, '', currentUrl.toString());
    }
} catch (_e) {}

try {
    const { ipcRenderer } = require('electron');
    ipcRenderer.on('antigravity:menu-action', (_event, action) => {
        try {
            switch (action) {
                case 'new-conversation': {
                    const btn = document.querySelector('[data-testid="new-conversation-button"]');
                    if (btn) {
                        btn.click();
                    } else {
                        const event = new KeyboardEvent('keydown', { key: 'n', code: 'KeyN', ctrlKey: true, bubbles: true });
                        window.dispatchEvent(event);
                    }
                    break;
                }
                case 'create-project': {
                    const btn = document.querySelector('[data-testid="sidebar-add-project-button"]');
                    if (btn) btn.click();
                    break;
                }
                case 'command-palette': {
                    const event = new KeyboardEvent('keydown', { key: 'P', code: 'KeyP', ctrlKey: true, shiftKey: true, bubbles: true });
                    window.dispatchEvent(event);
                    break;
                }
                case 'settings': {
                    const btn = document.querySelector('[data-testid="settings-button"]');
                    if (btn) btn.click();
                    break;
                }
                case 'toggle-sidebar': {
                    const btn = document.querySelector('[data-testid="sidebar-toggle"]');
                    if (btn) {
                        btn.click();
                    } else {
                        const event = new KeyboardEvent('keydown', { key: 'b', code: 'KeyB', ctrlKey: true, bubbles: true });
                        window.dispatchEvent(event);
                    }
                    break;
                }
                case 'toggle-terminal': {
                    const btn = Array.from(document.querySelectorAll('button')).find(b => b.textContent && (b.textContent.includes('Terminal') || b.getAttribute('aria-label')?.includes('Terminal')));
                    if (btn) {
                        btn.click();
                    } else {
                        const event = new KeyboardEvent('keydown', { key: '\`', code: 'Backquote', ctrlKey: true, bubbles: true });
                        window.dispatchEvent(event);
                    }
                    break;
                }
                case 'toggle-aux': {
                    const btn = document.querySelector('[data-testid="toggle-aux-sidebar"]');
                    if (btn) btn.click();
                    break;
                }
            }
        } catch (err) {
            console.error('Error handling menu action:', action, err);
        }
    });
} catch (_e) {}
`;
        preloadContent = preloadPatch + preloadContent;
        fs.writeFileSync(preloadPath, preloadContent, 'utf8');
        console.log(`Successfully patched ${preloadPath}`);
    } else {
        console.log(`Preload already patched in ${preloadPath}`);
    }
}

// ---------------------------------------------------------------------------
// 3. Patch dist/menu.js (Antigravity Application Menu & KDE Global Menu)
// ---------------------------------------------------------------------------
if (menuPath && fs.existsSync(menuPath)) {
    const fullMenuContent = `"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setupApplicationMenu = setupApplicationMenu;
exports.addItemToSubmenu = addItemToSubmenu;
const electron_1 = require("electron");
const utils_1 = require("./utils");
const updater_1 = require("./updater");

function getActiveWindow(win) {
    return win || electron_1.BrowserWindow.getFocusedWindow() || electron_1.BrowserWindow.getAllWindows()[0];
}

function setupApplicationMenu(url) {
    const isMac = (0, utils_1.isMacOS)();
    const appName = electron_1.app.getName() || 'Antigravity';
    const appVersion = electron_1.app.getVersion();

    const template = [
        ...(isMac ? [{
            label: appName,
            submenu: [
                {
                    label: \`About \${appName}\`,
                    role: 'about'
                },
                {
                    label: \`Version \${appVersion}\`,
                    enabled: false
                },
                {
                    id: 'check-for-updates',
                    label: updater_1.MenuUpdateStep.CheckForUpdates,
                    click: (menuItem) => {
                        const action = updater_1.updateActions[menuItem.label];
                        if (typeof action === 'function') action();
                        else (0, updater_1.checkForUpdates)(true);
                    }
                },
                { type: 'separator' },
                {
                    label: 'Preferences...',
                    accelerator: 'Cmd+,',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'settings');
                    }
                },
                { type: 'separator' },
                { role: 'services' },
                { type: 'separator' },
                { role: 'hide' },
                { role: 'hideOthers' },
                { role: 'unhide' },
                { type: 'separator' },
                { role: 'quit' }
            ]
        }] : []),

        // File Menu
        {
            label: 'File',
            submenu: [
                {
                    label: 'New Conversation',
                    accelerator: 'CmdOrCtrl+N',
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        if (targetWin) {
                            targetWin.webContents.send('antigravity:menu-action', 'new-conversation');
                            targetWin.webContents.sendInputEvent({ type: 'keyDown', keyCode: 'n', modifiers: ['control'] });
                            targetWin.webContents.sendInputEvent({ type: 'keyUp', keyCode: 'n', modifiers: ['control'] });
                        }
                    }
                },
                {
                    label: 'New Window',
                    accelerator: 'CmdOrCtrl+Shift+N',
                    click: () => {
                        (0, utils_1.createWindow)(url);
                    }
                },
                {
                    label: 'Create Project...',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'create-project');
                    }
                },
                {
                    label: 'Open Workspace...',
                    accelerator: 'CmdOrCtrl+O',
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        if (targetWin) {
                            targetWin.webContents.sendInputEvent({ type: 'keyDown', keyCode: 'o', modifiers: ['control'] });
                            targetWin.webContents.sendInputEvent({ type: 'keyUp', keyCode: 'o', modifiers: ['control'] });
                        }
                    }
                },
                { type: 'separator' },
                {
                    label: 'Command Palette...',
                    accelerator: 'CmdOrCtrl+Shift+P',
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        if (targetWin) {
                            targetWin.webContents.send('antigravity:menu-action', 'command-palette');
                            targetWin.webContents.sendInputEvent({ type: 'keyDown', keyCode: 'P', modifiers: ['control', 'shift'] });
                            targetWin.webContents.sendInputEvent({ type: 'keyUp', keyCode: 'P', modifiers: ['control', 'shift'] });
                        }
                    }
                },
                ...(!isMac ? [
                    { type: 'separator' },
                    {
                        label: 'Settings',
                        accelerator: 'CmdOrCtrl+,',
                        click: (_item, win) => {
                            getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'settings');
                        }
                    }
                ] : []),
                { type: 'separator' },
                { role: 'close', label: 'Close Window', accelerator: 'CmdOrCtrl+W' },
                ...(!isMac ? [{ role: 'quit', label: 'Quit', accelerator: 'CmdOrCtrl+Q' }] : [])
            ]
        },

        // Edit Menu
        {
            label: 'Edit',
            submenu: [
                { role: 'undo' },
                { role: 'redo' },
                { type: 'separator' },
                { role: 'cut' },
                { role: 'copy' },
                { role: 'paste' },
                { role: 'delete' },
                { role: 'selectAll' }
            ]
        },

        // View Menu
        {
            label: 'View',
            submenu: [
                { role: 'togglefullscreen', label: 'Toggle Full Screen', accelerator: 'F11' },
                { type: 'separator' },
                {
                    label: 'Zoom In',
                    accelerator: 'CmdOrCtrl+Plus',
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        if (targetWin) {
                            const newLevel = targetWin.webContents.getZoomLevel() + 0.5;
                            targetWin.webContents.setZoomLevel(newLevel);
                        }
                    }
                },
                {
                    label: 'Zoom Out',
                    accelerator: 'CmdOrCtrl+-',
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        if (targetWin) {
                            const newLevel = targetWin.webContents.getZoomLevel() - 0.5;
                            targetWin.webContents.setZoomLevel(newLevel);
                        }
                    }
                },
                {
                    label: 'Reset Zoom',
                    accelerator: 'CmdOrCtrl+0',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.setZoomLevel(0);
                    }
                },
                { type: 'separator' },
                {
                    label: 'Toggle Sidebar',
                    accelerator: 'CmdOrCtrl+B',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'toggle-sidebar');
                    }
                },
                {
                    label: 'Toggle Terminal',
                    accelerator: 'CmdOrCtrl+\`',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'toggle-terminal');
                    }
                },
                {
                    label: 'Toggle Auxiliary Pane',
                    accelerator: 'CmdOrCtrl+Alt+B',
                    click: (_item, win) => {
                        getActiveWindow(win)?.webContents.send('antigravity:menu-action', 'toggle-aux');
                    }
                },
                { type: 'separator' },
                { role: 'reload' },
                { role: 'forceReload' },
                { role: 'toggleDevTools', accelerator: 'Ctrl+Shift+I' }
            ]
        },

        // Window Menu
        {
            label: 'Window',
            submenu: [
                { role: 'minimize' },
                { role: 'zoom', label: 'Maximize' },
                { type: 'separator' },
                { role: 'close' }
            ]
        },

        // Help Menu
        {
            label: 'Help',
            submenu: [
                {
                    label: 'Docs',
                    click: async () => {
                        await electron_1.shell.openExternal('https://antigravity.google/docs');
                    }
                },
                {
                    id: 'check-for-updates',
                    label: updater_1.MenuUpdateStep.CheckForUpdates,
                    click: (menuItem) => {
                        const action = updater_1.updateActions[menuItem.label];
                        if (typeof action === 'function') action();
                        else (0, updater_1.checkForUpdates)(true);
                    }
                },
                { type: 'separator' },
                {
                    label: \`Version \${appVersion}\`,
                    enabled: false
                },
                {
                    label: \`About \${appName}\`,
                    click: (_item, win) => {
                        const targetWin = getActiveWindow(win);
                        electron_1.dialog.showMessageBox(targetWin || null, {
                            type: 'info',
                            title: \`About \${appName}\`,
                            message: appName,
                            detail: \`Version: \${appVersion}\\nGoogle Antigravity 2.0 multi-agent orchestration platform\`,
                            buttons: ['OK']
                        });
                    }
                }
            ]
        }
    ];

    const menu = electron_1.Menu.buildFromTemplate(template);
    electron_1.Menu.setApplicationMenu(menu);
}

function addItemToSubmenu(appMenu, submenuLabel, position, item) {
    const submenuItem = appMenu.items.find((item) => item.label === submenuLabel);
    if (!submenuItem?.submenu) return;
    submenuItem.submenu.insert(position, item);
}
`;
    fs.writeFileSync(menuPath, fullMenuContent, 'utf8');
    console.log(`Successfully patched ${menuPath}`);
}
