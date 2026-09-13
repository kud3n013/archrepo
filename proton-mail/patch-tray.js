#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const targetFile = process.argv[2];
if (!targetFile) {
  console.error('Usage: node patch-tray.js <path-to-.webpack/main/index.js>');
  process.exit(1);
}

if (!fs.existsSync(targetFile)) {
  console.error(`Error: Target file not found: ${targetFile}`);
  process.exit(1);
}

let code = fs.readFileSync(targetFile, 'utf8');

// Check idempotence
if (code.includes('/* PROTON_TRAY_PATCH_APPLIED */')) {
  console.log('Patch already applied. Skipping.');
  process.exit(0);
}

const targetCloseExact = 'Ba.on("close",e=>{rr||(e.preventDefault(),sn?(e=>{y(e),e.isFullScreen()?(Ns.info("close, isFullScreen on macOS"),e.setFullScreen(!1),e.on("leave-full-screen",()=>{Ns.info("close, leave-full-screen on macOS"),e.hide()})):e.hide()})(Ba):(e=>{e.hide(),e.isVisible()||(Ns.info("close, window not visible on Windows or Linux"),e.isDestroyed()||e.destroy(),an.setReason("windows-linux-exit-event"),r.app.quit())})(Ba))})';

const closeReplacement = 'Ba.on("close",e=>{if(r.app.isQuitting)return;e.preventDefault();y(Ba);Ba.isFullScreen()?(Ba.setFullScreen(!1),Ba.once("leave-full-screen",()=>Ba.hide())):Ba.hide()})';

let replacedClose = false;
if (code.includes(targetCloseExact)) {
  code = code.replace(targetCloseExact, closeReplacement);
  replacedClose = true;
} else {
  // Regex fallback matching the close handler
  const closeRegex = /Ba\.on\("close",\s*e\s*=>\s*\{rr\|\|\(e\.preventDefault\(\),\s*sn\s*\?\s*\(e\s*=>\s*\{y\(e\)[^}]*\}\)\(Ba\)\s*:\s*\(e\s*=>\s*\{e\.hide\(\)[^}]*r\.app\.quit\(\)\}\)\(Ba\)\)\}\)/;
  if (closeRegex.test(code)) {
    code = code.replace(closeRegex, closeReplacement);
    replacedClose = true;
  }
}

if (!replacedClose) {
  console.error('Error: Could not locate window close handler to patch in index.js');
  process.exit(1);
}

const insertTargetExact = 'T().maximized&&Ba.maximize(),Ba.on("closed",()=>{Ba=null});';
const trayCode = `/* PROTON_TRAY_PATCH_APPLIED */
;(()=>{
  let appTray = null;
  const initTray = () => {
    if (appTray) return;
    const path = require("path");
    const fs = require("fs");
    const trayIconPath = path.join(process.resourcesPath, "tray.png");
    const fallbackIconPath = path.join(process.resourcesPath, "icon.png");
    let trayImage = null;
    try {
      if (fs.existsSync(trayIconPath)) {
        trayImage = r.nativeImage.createFromPath(trayIconPath);
      } else if (fs.existsSync(fallbackIconPath)) {
        trayImage = r.nativeImage.createFromPath(fallbackIconPath).resize({ width: 24, height: 24 });
      }
    } catch (err) {
      Ns.error("Failed to load tray icon image:", err);
    }
    try {
      appTray = new r.Tray(trayImage || fallbackIconPath);
      appTray.setToolTip("Proton Mail");

      const openCalendar = async () => {
        try {
          bs();
          if (typeof Da !== "undefined" && Da && Da.calendar) {
            const curUrl = Da.calendar.webContents.getURL();
            if (!curUrl || curUrl === "about:blank" || curUrl === "") {
              const calUrl = await qa(qt().calendar);
              await rs("calendar", calUrl);
            }
            await Ja("calendar");
          }
        } catch (err) {
          Ns.error("Open calendar failed:", err);
        }
      };

      const openMail = async () => {
        try {
          bs();
          if (typeof Da !== "undefined" && Da && Da.mail) {
            const curUrl = Da.mail.webContents.getURL();
            if (!curUrl || curUrl === "about:blank" || curUrl === "") {
              const mailUrl = await qa(qt().mail);
              await rs("mail", mailUrl);
            }
            await Ja("mail");
          }
        } catch (err) {
          Ns.error("Open mail failed:", err);
        }
      };

      const trayMenu = r.Menu.buildFromTemplate([
        {
          label: "Open Proton Mail",
          click: () => { openMail(); }
        },
        {
          label: "Open Proton Calendar",
          click: () => { openCalendar(); }
        },
        { type: "separator" },
        {
          label: "Quit",
          click: () => {
            r.app.isQuitting = true;
            r.app.quit();
          }
        }
      ]);

      appTray.setContextMenu(trayMenu);

      appTray.on("click", () => {
        if (!_(Ba)) return;
        if (Ba.isVisible() && !Ba.isMinimized() && Ba.isFocused()) {
          Ba.hide();
        } else {
          bs();
        }
      });
    } catch (err) {
      Ns.error("Failed to initialize Proton Mail system tray:", err);
    }
  };

  r.app.on("before-quit", () => {
    r.app.isQuitting = true;
  });

  initTray();
})();
`;

let replacedInsert = false;
if (code.includes(insertTargetExact)) {
  code = code.replace(insertTargetExact, insertTargetExact + '\n' + trayCode);
  replacedInsert = true;
} else {
  const insertRegex = /T\(\)\.maximized&&Ba\.maximize\(\),Ba\.on\("closed",\s*\(\)\s*=>\s*\{Ba=null\}\);/;
  if (insertRegex.test(code)) {
    code = code.replace(insertRegex, match => match + '\n' + trayCode);
    replacedInsert = true;
  }
}

if (!replacedInsert) {
  console.error('Error: Could not locate tray injection point in index.js');
  process.exit(1);
}

// Validate syntax before writing
try {
  new vm.Script(code);
} catch (err) {
  console.error('Syntax error after patching:', err);
  process.exit(1);
}

fs.writeFileSync(targetFile, code, 'utf8');
console.log('Successfully patched Proton Mail with system tray and close-to-tray features.');
