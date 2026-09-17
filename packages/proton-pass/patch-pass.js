#!/usr/bin/env node
/**
 * patch-pass.js
 * 
 * Modifies Proton Pass desktop application inside unpacked app.asar:
 * 1. Unlocks Electron window resizing constraints:
 *    - Reduces minWidth from 881 to 360
 *    - Reduces minHeight from 680 to 300
 *    - Ensures window configuration cannot override these minimum boundaries
 * 2. Injects responsive CSS rules in main_window.css:
 *    - Responsive sidebar sizing between 910px and 1100px (16rem instead of 22.5em)
 *    - Dynamic collapsing of items sub-sidebar to a compact 60px icon strip on <= 680px
 *    - Safety overflow and min-width rules for detail panes
 */

const fs = require('fs');
const path = require('path');

const targetArg = process.argv[2];
if (!targetArg) {
  console.error('Usage: node patch-pass.js <path-to-extracted-asar-or-main-index.js>');
  process.exit(1);
}

let baseDir;
let mainFile;
let cssFile;

if (fs.existsSync(targetArg) && fs.statSync(targetArg).isDirectory()) {
  baseDir = targetArg;
  mainFile = path.join(baseDir, '.webpack', 'main', 'index.js');
  cssFile = path.join(baseDir, '.webpack', 'renderer', 'styles', 'main_window.css');
} else if (fs.existsSync(targetArg) && fs.statSync(targetArg).isFile()) {
  mainFile = targetArg;
  baseDir = path.resolve(path.dirname(targetArg), '..', '..');
  cssFile = path.join(baseDir, '.webpack', 'renderer', 'styles', 'main_window.css');
} else {
  console.error(`Error: Target path "${targetArg}" does not exist.`);
  process.exit(1);
}

if (!fs.existsSync(mainFile)) {
  console.error(`Error: Main process file "${mainFile}" not found.`);
  process.exit(1);
}

if (!fs.existsSync(cssFile)) {
  console.error(`Error: CSS stylesheet "${cssFile}" not found.`);
  process.exit(1);
}

console.log('[patch-pass] Patching Proton Pass desktop files...');
console.log(`[patch-pass] Main process: ${mainFile}`);
console.log(`[patch-pass] Stylesheet:   ${cssFile}`);

// ── 1. Patch Electron Main Process (.webpack/main/index.js) ───────────
let mainContent = fs.readFileSync(mainFile, 'utf8');

// Replace DEFAULT_CONFIG
const origDefaultConfig = `const DEFAULT_CONFIG = {
    height: 680,
    maximized: false,
    minHeight: 680,
    minWidth: 881,
    width: 960,
    zoomLevel: 1,
};`;

const newDefaultConfig = `const DEFAULT_CONFIG = {
    height: 680,
    maximized: false,
    minHeight: 300,
    minWidth: 360,
    width: 960,
    zoomLevel: 1,
};`;

if (!mainContent.includes(origDefaultConfig)) {
  console.error('[patch-pass] Error: DEFAULT_CONFIG pattern not found in main index.js');
  process.exit(1);
}
mainContent = mainContent.replace(origDefaultConfig, newDefaultConfig);

// Enforce minHeight & minWidth in getWindowConfig so stored state cannot lock dimensions
const origGetWindowConfig = `    return {
        minHeight: DEFAULT_CONFIG.minHeight,
        minWidth: DEFAULT_CONFIG.minWidth,
        ...windowConfig,
        ...ensureWindowIsVisible(windowConfig),
    };`;

const newGetWindowConfig = `    return {
        ...windowConfig,
        ...ensureWindowIsVisible(windowConfig),
        minHeight: DEFAULT_CONFIG.minHeight,
        minWidth: DEFAULT_CONFIG.minWidth,
    };`;

if (!mainContent.includes(origGetWindowConfig)) {
  console.error('[patch-pass] Error: getWindowConfig pattern not found in main index.js');
  process.exit(1);
}
mainContent = mainContent.replace(origGetWindowConfig, newGetWindowConfig);

fs.writeFileSync(mainFile, mainContent, 'utf8');
console.log('[patch-pass] Successfully updated main process window constraints (minWidth: 360, minHeight: 300).');

// ── 2. Inject Responsive Stylesheet (.webpack/renderer/styles/main_window.css) ──
let cssContent = fs.readFileSync(cssFile, 'utf8');

const responsiveCSS = `
/* --- Antigravity Responsive Layout Enhancements for Proton Pass Desktop --- */

/* 1. Medium / Tiling screens (<= 1100px): compact sidebar to give ample space to items and details */
@media (max-width: 68.75em) {
  :root {
    --pass-sidebar-size: 16rem !important;
  }
}

/* 2. Narrow / Tiling / Split screens (<= 680px down to 360px) */
@media (max-width: 42.5em) {
  /* When an item is selected (#content has child elements):
     Collapse #pass-sub-sidebar into a compact 60px icon strip */
  #pass-sub-sidebar:has(+ #content:not(:empty)) {
    width: 60px !important;
    max-width: 60px !important;
    min-width: 60px !important;
    flex: 0 0 60px !important;
    overflow-x: hidden !important;
  }
  #pass-sub-sidebar:has(+ #content:not(:empty)) .pass-item-list--item {
    padding-left: 0.25rem !important;
    padding-right: 0.25rem !important;
    justify-content: center !important;
  }
  #pass-sub-sidebar:has(+ #content:not(:empty)) .pass-item-list--item .text-left,
  #pass-sub-sidebar:has(+ #content:not(:empty)) .pass-sub-sidebar--hidable,
  #pass-sub-sidebar:has(+ #content:not(:empty)) > div > div.flex-row {
    display: none !important;
  }
  #pass-sub-sidebar:has(+ #content:not(:empty)) .pass-item-list--item .pass-item-icon {
    margin: 0 auto !important;
  }
  #pass-sub-sidebar:has(+ #content:not(:empty)) .ReactVirtualized__Grid,
  #pass-sub-sidebar:has(+ #content:not(:empty)) .ReactVirtualized__List {
    width: 60px !important;
    max-width: 60px !important;
  }

  /* Detail view takes remaining full width */
  #pass-sub-sidebar:has(+ #content:not(:empty)) + #content:not(:empty) {
    width: calc(100% - 60px) !important;
    flex: 1 1 auto !important;
    min-width: 0 !important;
  }

  /* When no item is selected (or #content is empty), items list occupies 100% width */
  #pass-sub-sidebar:has(+ #content:empty) {
    width: 100% !important;
    max-width: 100% !important;
    flex: 1 1 100% !important;
  }
}

/* 3. Safety & Overflow handling */
#content,
.pass-panel,
.pass-panel--content {
  min-width: 0 !important;
}
`;

if (!cssContent.includes('Antigravity Responsive Layout Enhancements')) {
  cssContent += responsiveCSS;
  fs.writeFileSync(cssFile, cssContent, 'utf8');
  console.log('[patch-pass] Successfully appended responsive CSS rules to main_window.css.');
} else {
  console.log('[patch-pass] Responsive CSS rules already present in main_window.css.');
}

console.log('[patch-pass] All patches applied successfully.');
