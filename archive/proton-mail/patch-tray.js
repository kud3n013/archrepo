#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const targetFile = process.argv[2];
if (!targetFile) {
  console.error("Usage: node patch-tray.js <path-to-.webpack/main/index.js>");
  process.exit(1);
}

if (!fs.existsSync(targetFile)) {
  console.error(`Error: Target file not found: ${targetFile}`);
  process.exit(1);
}

let code = fs.readFileSync(targetFile, "utf8");

// Check idempotence
if (code.includes("/* PROTON_TRAY_PATCH_APPLIED */")) {
  console.log("Patch already applied. Skipping.");
  process.exit(0);
}

// 1. Patch minWidth: 900 -> 360 to allow free window tiling on Hyprland,
// and set dark background color (#16141c) in window/view options to eliminate white startup flash
if (code.includes("minWidth:900")) {
  code = code.replace("minWidth:900", 'minWidth:360,backgroundColor:"#16141c"');
  console.log("Successfully patched minWidth: 900 -> 360 with dark backgroundColor");
} else if (/minWidth:\s*900/.test(code)) {
  code = code.replace(/minWidth:\s*900/g, 'minWidth:360,backgroundColor:"#16141c"');
  console.log("Successfully patched minWidth via regex with dark backgroundColor");
} else {
  console.warn("Warning: minWidth:900 not found in index.js");
}

// 2. Patch window close handler for close-to-tray
// Matches both 1.14.x (Ba, rr, sn, y) and 1.15.x (qs, lr, dn, L) patterns dynamically
const closeRegex = /([a-zA-Z0-9_$]+)\.on\("close",\s*([a-zA-Z0-9_$]+)\s*=>\s*\{[a-zA-Z0-9_$]+\|\|\(\2\.preventDefault\(\),\s*([a-zA-Z0-9_$]+)\s*\?\s*\(\2\s*=>\s*\{([a-zA-Z0-9_$]+)\(\2\)[\s\S]*?windows-linux-exit-event[\s\S]*?\)\(\1\)\)\}\)/;
const closeMatch = code.match(closeRegex);

let winVar = "Ba";
if (closeMatch) {
  const [fullCloseMatch, matchedWinVar, eventVar, _isMacVar, saveBoundsVar] = closeMatch;
  winVar = matchedWinVar;
  const closeReplacement = `${winVar}.on("close",${eventVar}=>{const _el=(typeof o==="function"?o():(typeof r!=="undefined"?r:null));if(_el?.app?.isQuitting)return;${eventVar}.preventDefault();${saveBoundsVar}(${winVar});${winVar}.isFullScreen()?(${winVar}.setFullScreen(!1),${winVar}.once("leave-full-screen",()=>${winVar}.hide())):${winVar}.hide()})`;
  code = code.replace(fullCloseMatch, closeReplacement);
} else {
  const targetCloseExact = 'Ba.on("close",e=>{rr||(e.preventDefault(),sn?(e=>{y(e),e.isFullScreen()?(Ns.info("close, isFullScreen on macOS"),e.setFullScreen(!1),e.on("leave-full-screen",()=>{Ns.info("close, leave-full-screen on macOS"),e.hide()})):e.hide()})(Ba):(e=>{e.hide(),e.isVisible()||(Ns.info("close, window not visible on Windows or Linux"),e.isDestroyed()||e.destroy(),an.setReason("windows-linux-exit-event"),r.app.quit())})(Ba))})';
  const closeReplacement = 'Ba.on("close",e=>{if(r.app.isQuitting)return;e.preventDefault();y(Ba);Ba.isFullScreen()?(Ba.setFullScreen(!1),Ba.once("leave-full-screen",()=>Ba.hide())):Ba.hide()})';
  if (code.includes(targetCloseExact)) {
    code = code.replace(targetCloseExact, closeReplacement);
  } else {
    console.error("Error: Could not locate window close handler to patch in index.js");
    process.exit(1);
  }
}

// 3. System tray, close-to-tray, and dark theme / reading safety integration
const safeReadingCss = `
  /* Dark background safety to prevent any white flash during view load */
  html, body {
    background-color: #16141c !important;
  }
  /* Reading pane and message content safety */
  .main, .content-container, .message-container {
    min-width: 0 !important;
  }
  .message-content {
    overflow-x: auto !important;
  }
  [data-testid="message-view"] {
    max-width: 100% !important;
  }
`;

const trayCode = `/* PROTON_TRAY_PATCH_APPLIED */
;(()=>{
  let appTray = null;
  const _getElectron = () => (typeof o === "function" ? o() : (typeof r !== "undefined" ? r : require("electron")));
  const _getLogger = () => (typeof Fa !== "undefined" ? Fa : (typeof Ns !== "undefined" ? Ns : console));

  // Set dark background on main window to prevent white flash
  try {
    if (typeof ${winVar} !== "undefined" && ${winVar} && ${winVar}.setBackgroundColor) {
      ${winVar}.setBackgroundColor("#16141c");
    }
  } catch (err) {}

  const initTray = () => {
    if (appTray) return;
    const path = require("path");
    const fs = require("fs");
    const _el = _getElectron();
    const _log = _getLogger();
    const trayIconPath = path.join(process.resourcesPath, "tray.png");
    const fallbackIconPath = path.join(process.resourcesPath, "icon.png");
    let trayImage = null;

    try {
      if (fs.existsSync(trayIconPath)) {
        trayImage = _el.nativeImage.createFromPath(trayIconPath);
      } else if (fs.existsSync(fallbackIconPath)) {
        trayImage = _el.nativeImage.createFromPath(fallbackIconPath);
      }
    } catch (e) {
      _log.error("Failed to load tray icon image:", e);
    }

    if (!trayImage || trayImage.isEmpty()) {
      _log.warn("Tray image is empty, system tray skipped.");
      return;
    }

    try {
      appTray = new _el.Tray(trayImage);
      appTray.setToolTip("Proton Mail");

      const contextMenu = _el.Menu.buildFromTemplate([
        {
          label: "Open Proton Mail",
          click: async () => {
            try {
              if (${winVar}) {
                if (!${winVar}.isVisible()) {
                  ${winVar}.show();
                }
                ${winVar}.focus();
                if (typeof ha === "function") {
                  ha();
                } else if (typeof Ja === "function") {
                  if (typeof qa === "function" && typeof qt === "function") {
                    const mailUrl = await qa(qt().mail);
                    await rs("mail", mailUrl);
                  }
                  await Ja("mail");
                }
              }
            } catch (err) {
              _log.error("Open mail failed:", err);
            }
          }
        },
        {
          label: "Open Proton Calendar",
          click: async () => {
            try {
              if (${winVar}) {
                if (!${winVar}.isVisible()) {
                  ${winVar}.show();
                }
                ${winVar}.focus();
                if (typeof ga === "function") {
                  ga();
                } else if (typeof Ja === "function") {
                  if (typeof qa === "function" && typeof qt === "function") {
                    const calUrl = await qa(qt().calendar);
                    await rs("calendar", calUrl);
                  }
                  await Ja("calendar");
                }
              }
            } catch (err) {
              _log.error("Open calendar failed:", err);
            }
          }
        },
        { type: "separator" },
        {
          label: "Quit",
          click: () => {
            const el = _getElectron();
            el.app.isQuitting = true;
            if (${winVar} && !${winVar}.isDestroyed()) {
              ${winVar}.destroy();
            }
            el.app.quit();
          }
        }
      ]);

      appTray.setContextMenu(contextMenu);

      appTray.on("click", () => {
        if (!${winVar}) return;
        if (${winVar}.isVisible()) {
          ${winVar}.hide();
        } else {
          if (typeof ka === "function") {
            ka();
          } else if (typeof bs === "function") {
            bs();
          } else {
            ${winVar}.show();
            ${winVar}.focus();
          }
        }
      });
    } catch (err) {
      _log.error("Failed to initialize Proton Mail system tray:", err);
    }
  };

  const initWebViews = () => {
    const safeCss = ${JSON.stringify(safeReadingCss)};
    const _log = _getLogger();

    const attachToView = (view) => {
      if (!view || !view.webContents) return;
      try {
        if (view.setBackgroundColor) {
          view.setBackgroundColor("#16141c");
        }
      } catch (e) {}

      const inject = async () => {
        try {
          await view.webContents.insertCSS(safeCss);
        } catch (e) {
          _log.debug("CSS injection notice:", e);
        }
      };
      view.webContents.on("did-finish-load", inject);
      view.webContents.on("dom-ready", inject);
      if (!view.webContents.isLoading()) {
        inject();
      }
    };

    const _views = (typeof Ys !== "undefined" && Ys) ? Ys : ((typeof Da !== "undefined" && Da) ? Da : null);
    if (_views) {
      attachToView(_views.mail);
      attachToView(_views.calendar);
      attachToView(_views.account);
    }
  };

  const _el = _getElectron();
  if (_el?.app) {
    _el.app.on("before-quit", () => {
      _el.app.isQuitting = true;
    });
  }

  initTray();
  initWebViews();
})();
`;

// Matches both 1.14.x (T().maximized&&Ba.maximize()...) and 1.15.x (M().maximized&&qs.maximize()...)
const insertRegex = /([a-zA-Z0-9_$]+)\(\)\.maximized\s*&&\s*([a-zA-Z0-9_$]+)\.maximize\(\),\s*\2\.on\("closed",\s*\(\)\s*=>\s*\{\s*\2\s*=\s*null\s*\}\);/;
const insertMatch = code.match(insertRegex);

let replacedInsert = false;
if (insertMatch) {
  code = code.replace(insertMatch[0], insertMatch[0] + "\n" + trayCode);
  replacedInsert = true;
} else {
  const insertTargetExact = 'T().maximized&&Ba.maximize(),Ba.on("closed",()=>{Ba=null});';
  if (code.includes(insertTargetExact)) {
    code = code.replace(insertTargetExact, insertTargetExact + "\n" + trayCode);
    replacedInsert = true;
  }
}

if (!replacedInsert) {
  console.error("Error: Could not locate tray injection point in index.js");
  process.exit(1);
}

// Validate syntax before writing
try {
  new vm.Script(code);
} catch (err) {
  console.error("Syntax validation failed for patched code:", err);
  process.exit(1);
}

fs.writeFileSync(targetFile, code, "utf8");
console.log("Successfully patched Proton Mail with system tray, close-to-tray, dark startup background, and unconstrained desktop layout.");
