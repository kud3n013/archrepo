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

// Target snippet to match
const targetCode = `        titleBarStyle: 'hidden',
        titleBarOverlay: isMacOS()
            ? false
            : {
                color: backgroundColor,
                symbolColor: foregroundColor,
                height: 30,
            },`;

// Replacement code supporting environment variables and CLI arguments
const replacementCode = `        titleBarStyle: (process.env.ANTIGRAVITY_TITLEBAR === 'native' || (process.argv && process.argv.includes('--titlebar=native')))
            ? undefined
            : 'hidden',
        titleBarOverlay: (isMacOS() ||
            process.env.ANTIGRAVITY_TITLEBAR === 'hidden' ||
            process.env.ANTIGRAVITY_TITLEBAR === 'native' ||
            process.env.ANTIGRAVITY_NO_WCO === '1' ||
            (process.argv && (process.argv.includes('--titlebar=hidden') || process.argv.includes('--titlebar=native') || process.argv.includes('--no-window-controls'))))
            ? false
            : {
                color: backgroundColor,
                symbolColor: foregroundColor,
                height: 30,
            },`;

if (!content.includes(targetCode)) {
    const regex = /titleBarStyle:\s*'hidden',\s*titleBarOverlay:\s*isMacOS\(\)\s*\?\s*false\s*:\s*\{[\s\S]*?height:\s*30,\s*\},/;
    if (!regex.test(content)) {
        console.error('Error: Could not locate titleBarStyle/titleBarOverlay definition in utils.js');
        process.exit(1);
    }
    content = content.replace(regex, replacementCode.trim());
} else {
    content = content.replace(targetCode, replacementCode);
}

fs.writeFileSync(resolvedPath, content, 'utf8');
console.log(`Successfully patched window controls in ${resolvedPath}`);
