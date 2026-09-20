#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const targetFile = process.argv[2];
if (!targetFile) {
    console.error('Usage: node patch-window-controls.js <path-to-dist/utils.js>');
    process.exit(1);
}

const resolvedPath = path.resolve(targetFile);
if (!fs.existsSync(resolvedPath)) {
    console.error(`Target file does not exist: ${resolvedPath}`);
    process.exit(1);
}

let content = fs.readFileSync(resolvedPath, 'utf8');

// Target snippet in original upstream Antigravity
const targetCode = `        titleBarStyle: 'hidden',
        titleBarOverlay: isMacOS()
            ? false
            : {
                color: backgroundColor,
                symbolColor: foregroundColor,
                height: 30,
            },
        backgroundColor,`;

// Replacement code supporting hidden in-window menu bar, native GTK/Qt/Global menu, and custom titlebars
const replacementCode = `        autoHideMenuBar: true,
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

const winCreationTarget = `devTools: !electron_1.app.isPackaged,
        },
    });`;

const winCreationReplacement = `devTools: !electron_1.app.isPackaged,
        },
    });
    if (typeof win.setAutoHideMenuBar === 'function') {
        win.setAutoHideMenuBar(true);
        win.setMenuBarVisibility(false);
    }`;

// Check if already patched
if (content.includes('autoHideMenuBar: true') && content.includes('titleBarOverlay: (!isMacOS()')) {
    console.log(`Window controls and menubar already patched in ${resolvedPath}`);
} else if (content.includes(targetCode)) {
    content = content.replace(targetCode, replacementCode);
} else {
    // Match upstream or previous patch variations (including leading whitespace)
    const titlebarRegex = /^[ \t]*(autoHideMenuBar:\s*true,\s*)?titleBarStyle:\s*[\s\S]*?titleBarOverlay:\s*[\s\S]*?(height:\s*30,\s*\},?\s*(:\s*false,?)?|false,\s*)\s*backgroundColor,/m;
    if (titlebarRegex.test(content)) {
        content = content.replace(titlebarRegex, replacementCode);
    } else {
        console.error('Error: Could not locate titleBarStyle/titleBarOverlay definition in utils.js');
        process.exit(1);
    }
}

if (!content.includes("win.setAutoHideMenuBar(true)")) {
    if (content.includes(winCreationTarget)) {
        content = content.replace(winCreationTarget, winCreationReplacement);
    } else {
        const regexWin = /devTools:\s*!electron_1\.app\.isPackaged,\s*\},?\s*\}\);/;
        if (regexWin.test(content)) {
            content = content.replace(regexWin, winCreationReplacement);
        }
    }
}

fs.writeFileSync(resolvedPath, content, 'utf8');
console.log(`Successfully patched window controls and menubar in ${resolvedPath}`);
