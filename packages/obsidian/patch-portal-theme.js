const fs = require('fs');
const path = require('path');

const targetFile = process.argv[2];
if (!targetFile || !fs.existsSync(targetFile)) {
    console.error('Usage: node patch-portal-theme.js <path-to-main.js>');
    process.exit(1);
}

let content = fs.readFileSync(targetFile, 'utf8');

if (content.includes('_portalSyncInitialized')) {
    console.log(`Theme synchronization bridge already present in ${targetFile}`);
    process.exit(0);
}

const targetAnchor = 'remote.initialize();';
if (!content.includes(targetAnchor)) {
    console.error(`Error: Could not locate "${targetAnchor}" in ${targetFile}`);
    process.exit(1);
}

const portalBridgeCode = `
// ---------------------------------------------------------------------------
// Linux XDG Desktop Portal Real-Time Theme Synchronization Bridge
// ---------------------------------------------------------------------------
let _portalTheme = 'dark';
let _targetThemeSource = 'system';
let _portalSyncInitialized = false;
let _isAppQuitting = false;

function _readPortalThemeSync() {
    if (process.platform !== 'linux') {
        return require('electron').nativeTheme.shouldUseDarkColors ? 'dark' : 'light';
    }
    const cp = require('node:child_process');
    try {
        const out = cp.execFileSync('gdbus', [
            'call', '--session', '--dest', 'org.freedesktop.portal.Desktop',
            '--object-path', '/org/freedesktop/portal/desktop',
            '--method', 'org.freedesktop.portal.Settings.Read',
            'org.freedesktop.appearance', 'color-scheme'
        ], { timeout: 1500, encoding: 'utf8' });
        if (out.includes('uint32 1')) return 'dark';
        if (out.includes('uint32 2')) return 'light';
    } catch (_) {}

    try {
        const out2 = cp.execFileSync('dbus-send', [
            '--session', '--print-reply=literal',
            '--dest=org.freedesktop.portal.Desktop',
            '/org/freedesktop/portal/desktop',
            'org.freedesktop.portal.Settings.Read',
            'string:org.freedesktop.appearance', 'string:color-scheme'
        ], { timeout: 1500, encoding: 'utf8' });
        if (out2.includes('uint32 1')) return 'dark';
        if (out2.includes('uint32 2')) return 'light';
    } catch (_) {}

    try {
        const kde = cp.execFileSync('kreadconfig6', ['--group', 'General', '--key', 'ColorScheme'], { timeout: 500, encoding: 'utf8' }).trim();
        if (kde.toLowerCase().includes('dark')) return 'dark';
        if (kde) return 'light';
    } catch (_) {}

    try {
        const gs = cp.execFileSync('gsettings', ['get', 'org.gnome.desktop.interface', 'color-scheme'], { timeout: 500, encoding: 'utf8' });
        if (gs.includes('prefer-dark')) return 'dark';
        if (gs.includes('prefer-light')) return 'light';
    } catch (_) {}

    return require('electron').nativeTheme.shouldUseDarkColors ? 'dark' : 'light';
}

function _applyPortalTheme() {
    const newTheme = _targetThemeSource === 'system' ? _portalTheme : _targetThemeSource;
    require('electron').nativeTheme.themeSource = newTheme;
}

function _startPortalMonitor() {
    if (process.platform !== 'linux' || _isAppQuitting) return;
    const cp = require('node:child_process');
    try {
        const mon = cp.spawn('gdbus', [
            'monitor', '--session',
            '--dest', 'org.freedesktop.portal.Desktop',
            '--object-path', '/org/freedesktop/portal/desktop'
        ], { stdio: ['ignore', 'pipe', 'ignore'] });

        mon.stdout.on('data', (data) => {
            const s = data.toString();
            for (const line of s.split('\\n')) {
                if (line.includes('org.freedesktop.appearance') && line.includes('color-scheme')) {
                    if (line.includes('uint32 1') || /color-scheme['"],\\s*<[a-z0-9@_]*\\s*1\\s*>/i.test(line)) {
                        _portalTheme = 'dark';
                        _applyPortalTheme();
                    } else if (line.includes('uint32 2') || /color-scheme['"],\\s*<[a-z0-9@_]*\\s*2\\s*>/i.test(line)) {
                        _portalTheme = 'light';
                        _applyPortalTheme();
                    }
                }
            }
        });

        mon.on('error', () => {});
        mon.on('close', () => {
            if (!_isAppQuitting) setTimeout(_startPortalMonitor, 2000);
        });

        process.on('exit', () => {
            _isAppQuitting = true;
            try { mon.kill(); } catch (_) {}
        });
    } catch (_) {}
}

function _initPortalThemeSync() {
    if (_portalSyncInitialized || process.platform !== 'linux') return;
    _portalSyncInitialized = true;
    _portalTheme = _readPortalThemeSync();
    _applyPortalTheme();
    _startPortalMonitor();

    // Keep window backgrounds and titlebar overlays in sync
    const { nativeTheme, BrowserWindow } = require('electron');
    nativeTheme.on('updated', () => {
        const isDark = nativeTheme.shouldUseDarkColors;
        const bg = isDark ? '#131313' : '#FAFAFA';
        const fg = isDark ? '#FAFAFA' : '#383A42';
        for (const win of BrowserWindow.getAllWindows()) {
            try {
                win.setBackgroundColor(bg);
                if (typeof win.setTitleBarOverlay === 'function') {
                    win.setTitleBarOverlay({ color: bg, symbolColor: fg, height: 30 });
                }
            } catch (_) {}
        }
    });
}

_initPortalThemeSync();
`;

content = content.replace(targetAnchor, `${targetAnchor}\n${portalBridgeCode}`);
fs.writeFileSync(targetFile, content, 'utf8');
console.log(`Successfully patched ${targetFile} with XDG portal theme sync bridge`);
