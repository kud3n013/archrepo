#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

let utilsPath = null;
let preloadPath = null;

const arg1 = process.argv[2];
const arg2 = process.argv[3];

if (!arg1) {
    console.error('Usage: node patch-window-controls.js <path-to-dist/utils.js | dir> [path-to-dist/preload.js]');
    process.exit(1);
}

const resolvedArg1 = path.resolve(arg1);
if (fs.existsSync(resolvedArg1) && fs.statSync(resolvedArg1).isDirectory()) {
    utilsPath = path.join(resolvedArg1, 'dist', 'utils.js');
    if (!fs.existsSync(utilsPath)) {
        utilsPath = path.join(resolvedArg1, 'utils.js');
    }
    preloadPath = path.join(resolvedArg1, 'dist', 'preload.js');
    if (!fs.existsSync(preloadPath)) {
        preloadPath = path.join(resolvedArg1, 'preload.js');
    }
} else {
    utilsPath = resolvedArg1;
    if (arg2) {
        preloadPath = path.resolve(arg2);
    } else {
        preloadPath = path.join(path.dirname(utilsPath), 'preload.js');
    }
}

if (!fs.existsSync(utilsPath)) {
    console.error(`Error: utils.js not found at ${utilsPath}`);
    process.exit(1);
}

// ---------------------------------------------------------------------------
// 1. Patch dist/utils.js
// ---------------------------------------------------------------------------
let utilsContent = fs.readFileSync(utilsPath, 'utf8');

// Replacement code supporting hidden in-window menu bar, native GTK/Qt/Global menu, and custom titlebars
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

// Regex matching upstream titlebar configuration
const titlebarRegex = /^[ \t]*(autoHideMenuBar:\s*true,\s*)?titleBarStyle:\s*[\s\S]*?titleBarOverlay:\s*[\s\S]*?(height:\s*30,\s*\},?\s*(:\s*false,?)?|false,\s*)\s*backgroundColor,/m;

if (titlebarRegex.test(utilsContent)) {
    utilsContent = utilsContent.replace(titlebarRegex, replacementTitlebar);
} else {
    console.error('Error: Could not locate titleBarStyle/titleBarOverlay definition in utils.js');
    process.exit(1);
}

// Helper to ensure hostVariant=gemini-app
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

// Intercept win.loadURL and set menu bar autohide
const winCreationTargetRegex = /(webPreferences:\s*\{[\s\S]*?devTools:\s*!electron_1\.app\.isPackaged,\s*\},?\s*\}\);)/;
const winCreationAddition = `$1
    const origLoadURL = win.loadURL.bind(win);
    win.loadURL = (targetUrl, options) => origLoadURL(ensureHostVariant(targetUrl), options);
    if (typeof win.setAutoHideMenuBar === 'function') {
        win.setAutoHideMenuBar(true);
        win.setMenuBarVisibility(false);
    }`;

if (!utilsContent.includes('const origLoadURL = win.loadURL.bind(win);')) {
    // If it already had setAutoHideMenuBar from earlier patch, remove it first
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
// 2. Patch dist/preload.js (if present)
// ---------------------------------------------------------------------------
if (preloadPath && fs.existsSync(preloadPath)) {
    let preloadContent = fs.readFileSync(preloadPath, 'utf8');
    const preloadMarker = '/* antigravity-host-variant-patch */';
    if (!preloadContent.includes(preloadMarker)) {
        const preloadPatch = `${preloadMarker}
try {
    const currentUrl = new URL(window.location.href);
    if (currentUrl.protocol.startsWith('http') && currentUrl.searchParams.get('hostVariant') !== 'gemini-app') {
        currentUrl.searchParams.set('hostVariant', 'gemini-app');
        window.history.replaceState(null, '', currentUrl.toString());
    }
} catch (_e) {}
`;
        preloadContent = preloadPatch + preloadContent;
        fs.writeFileSync(preloadPath, preloadContent, 'utf8');
        console.log(`Successfully patched ${preloadPath}`);
    } else {
        console.log(`Preload already patched in ${preloadPath}`);
    }
}
