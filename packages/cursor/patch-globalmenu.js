#!/usr/bin/env node

/**
 * patch-globalmenu.js
 *
 * Patches Cursor's main process (out/main.js) to enable proper menu export to
 * KDE Plasma's Global Menu (com.canonical.dbusmenu / KWin) and auto-hide the
 * in-window menubar when CURSOR_EXPORT_GLOBAL_MENU is set.
 */

const fs = require('fs');

const mainJsPath = process.argv[2];
if (!mainJsPath || !fs.existsSync(mainJsPath)) {
    console.error(`Usage: node patch-globalmenu.js <path-to-main.js>`);
    process.exit(1);
}

let code = fs.readFileSync(mainJsPath, 'utf8');
let modified = false;

// 1. Un-gate shouldDrawMenu on Linux when CURSOR_EXPORT_GLOBAL_MENU is active
const t1 = "shouldDrawMenu(e){if(!K&&!Yo(this.configurationService))return!1;";
const r1 = "shouldDrawMenu(e){if(!K&&!Yo(this.configurationService)&&!process.env.CURSOR_EXPORT_GLOBAL_MENU)return!1;";

if (code.includes(t1)) {
    code = code.replace(t1, r1);
    console.log("Patched shouldDrawMenu to allow Global Menu export on Linux.");
    modified = true;
} else if (code.includes(r1)) {
    console.log("shouldDrawMenu already patched.");
} else {
    console.warn("Target pattern for shouldDrawMenu not found!");
}

// 2. Suppress in-window menubar on window instance when Global Menu is active
const t2 = "setWin(t,n){this._win=t,";
const r2 = "setWin(t,n){if(process.env.CURSOR_EXPORT_GLOBAL_MENU){try{t.setAutoHideMenuBar(true);t.setMenuBarVisibility(false);}catch(e){}}this._win=t,";

if (code.includes(t2)) {
    code = code.replace(t2, r2);
    console.log("Patched setWin to autoHide in-window menubar.");
    modified = true;
} else if (code.includes(r2)) {
    console.log("setWin already patched.");
} else {
    console.warn("Target pattern for setWin not found!");
}

// 3. Default menuBarVisibility to 'toggle' when Global Menu is active (Alt/F10 still reveals)
const t3 = "getMenuBarVisibility(){let e=$Oe(this.configurationService);return[\"visible\",\"toggle\",\"hidden\"].indexOf(e)<0&&(e=\"classic\"),e}";
const r3 = "getMenuBarVisibility(){let e=$Oe(this.configurationService);if(process.env.CURSOR_EXPORT_GLOBAL_MENU&&(e===\"classic\"||!e))e=\"toggle\";return[\"visible\",\"toggle\",\"hidden\"].indexOf(e)<0&&(e=\"classic\"),e}";

if (code.includes(t3)) {
    code = code.replace(t3, r3);
    console.log("Patched getMenuBarVisibility for Global Menu.");
    modified = true;
} else if (code.includes(r3)) {
    console.log("getMenuBarVisibility already patched.");
} else {
    console.warn("Target pattern for getMenuBarVisibility not found!");
}

if (modified) {
    fs.writeFileSync(mainJsPath, code, 'utf8');
    console.log(`Successfully applied Global Menu patches to ${mainJsPath}`);
} else {
    console.log("No modifications were necessary or files already patched.");
}
