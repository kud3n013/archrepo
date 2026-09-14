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

// 1. Patch minWidth: 900 -> 360 to allow free window tiling and responsive narrow views
if (code.includes("minWidth:900")) {
  code = code.replace("minWidth:900", "minWidth:360");
  console.log("Successfully patched minWidth: 900 -> 360");
} else if (/minWidth:\s*900/.test(code)) {
  code = code.replace(/minWidth:\s*900/g, "minWidth:360");
  console.log("Successfully patched minWidth via regex");
} else {
  console.warn("Warning: minWidth:900 not found in index.js");
}

// 2. Patch window close handler for close-to-tray
const targetCloseExact = 'Ba.on("close",e=>{rr||(e.preventDefault(),sn?(e=>{y(e),e.isFullScreen()?(Ns.info("close, isFullScreen on macOS"),e.setFullScreen(!1),e.on("leave-full-screen",()=>{Ns.info("close, leave-full-screen on macOS"),e.hide()})):e.hide()})(Ba):(e=>{e.hide(),e.isVisible()||(Ns.info("close, window not visible on Windows or Linux"),e.isDestroyed()||e.destroy(),an.setReason("windows-linux-exit-event"),r.app.quit())})(Ba))})';

const closeReplacement = 'Ba.on("close",e=>{if(r.app.isQuitting)return;e.preventDefault();y(Ba);Ba.isFullScreen()?(Ba.setFullScreen(!1),Ba.once("leave-full-screen",()=>Ba.hide())):Ba.hide()})';

let replacedClose = false;
if (code.includes(targetCloseExact)) {
  code = code.replace(targetCloseExact, closeReplacement);
  replacedClose = true;
} else {
  const closeRegex = /Ba\.on\("close",\s*e\s*=>\s*\{rr\|\|\(e\.preventDefault\(\),\s*sn\s*\?\s*\(e\s*=>\s*\{y\(e\)[^}]*\}\)\(Ba\)\s*:\s*\(e\s*=>\s*\{e\.hide\(\)[^}]*r\.app\.quit\(\)\}\)\(Ba\)\)\}\)/;
  if (closeRegex.test(code)) {
    code = code.replace(closeRegex, closeReplacement);
    replacedClose = true;
  }
}

if (!replacedClose) {
  console.error("Error: Could not locate window close handler to patch in index.js");
  process.exit(1);
}

// 3. Inject system tray, close-to-tray, and responsive layout enhancements
const responsiveCss = `
  @media (min-width: 681px) and (max-width: 1050px) {
    .sidebar:not([data-expanded="true"]) {
      inline-size: 3.75rem !important;
      width: 3.75rem !important;
      min-width: 3.75rem !important;
      max-width: 3.75rem !important;
    }
    .sidebar:not([data-expanded="true"]) .logo-container {
      inline-size: auto !important;
      block-size: auto !important;
      padding-inline: 0 !important;
      flex-direction: column !important;
    }
    .sidebar:not([data-expanded="true"]) .apps-dropdown-button {
      margin-inline: auto !important;
    }
    .sidebar:not([data-expanded="true"]) .sidebar-header {
      padding-inline: 0.25rem !important;
      flex-direction: column !important;
      align-items: center !important;
      gap: 0.5rem !important;
    }
    .sidebar:not([data-expanded="true"]) .sidebar-header [data-testid="sidebar:compose"] {
      padding-inline: 0 !important;
      width: 2.5rem !important;
      min-width: 2.5rem !important;
      display: flex !important;
      justify-content: center !important;
      align-items: center !important;
    }
    .sidebar:not([data-expanded="true"]) .sidebar-header [data-testid="sidebar:compose"] span:not(.icon):not(.sr-only) {
      display: none !important;
    }
    .sidebar:not([data-expanded="true"]) .navigation-link,
    .sidebar:not([data-expanded="true"]) .navigation-link-header-group-link {
      padding-inline: 0 !important;
      justify-content: center !important;
    }
    .sidebar:not([data-expanded="true"]) .navigation-link .flex-1,
    .sidebar:not([data-expanded="true"]) .navigation-link-header-group-link .flex-1,
    .sidebar:not([data-expanded="true"]) .navigation-title,
    .sidebar:not([data-expanded="true"]) .sidebar-nav-title {
      display: none !important;
    }
    .sidebar:not([data-expanded="true"]) .navigation-counter-item {
      position: absolute !important;
      top: 0.35em !important;
      right: 0.35em !important;
      transform: translateX(50%) translateY(-50%) !important;
      width: 0.5rem !important;
      height: 0.5rem !important;
      overflow: hidden !important;
      color: transparent !important;
      background: var(--navigation-item-count-background-color, #6d4aff) !important;
      border-radius: 50% !important;
    }
    .sidebar:not([data-expanded="true"]) [data-testid="sidebar:storage-meter"],
    .sidebar:not([data-expanded="true"]) .sidebar-storage-upsell,
    .sidebar:not([data-expanded="true"]) .sidebar-version {
      display: none !important;
    }
  }

  .sidebar.desktop-force-collapsed {
    inline-size: 3.75rem !important;
    width: 3.75rem !important;
    min-width: 3.75rem !important;
    max-width: 3.75rem !important;
  }
  .sidebar.desktop-force-collapsed .logo-container {
    inline-size: auto !important;
    block-size: auto !important;
    padding-inline: 0 !important;
    flex-direction: column !important;
  }
  .sidebar.desktop-force-collapsed .apps-dropdown-button {
    margin-inline: auto !important;
  }
  .sidebar.desktop-force-collapsed .sidebar-header {
    padding-inline: 0.25rem !important;
    flex-direction: column !important;
    align-items: center !important;
    gap: 0.5rem !important;
  }
  .sidebar.desktop-force-collapsed .sidebar-header [data-testid="sidebar:compose"] {
    padding-inline: 0 !important;
    width: 2.5rem !important;
    min-width: 2.5rem !important;
    display: flex !important;
    justify-content: center !important;
    align-items: center !important;
  }
  .sidebar.desktop-force-collapsed .sidebar-header [data-testid="sidebar:compose"] span:not(.icon):not(.sr-only) {
    display: none !important;
  }
  .sidebar.desktop-force-collapsed .navigation-link,
  .sidebar.desktop-force-collapsed .navigation-link-header-group-link {
    padding-inline: 0 !important;
    justify-content: center !important;
  }
  .sidebar.desktop-force-collapsed .navigation-link .flex-1,
  .sidebar.desktop-force-collapsed .navigation-link-header-group-link .flex-1,
  .sidebar.desktop-force-collapsed .navigation-title,
  .sidebar.desktop-force-collapsed .sidebar-nav-title {
    display: none !important;
  }
  .sidebar.desktop-force-collapsed .navigation-counter-item {
    position: absolute !important;
    top: 0.35em !important;
    right: 0.35em !important;
    transform: translateX(50%) translateY(-50%) !important;
    width: 0.5rem !important;
    height: 0.5rem !important;
    overflow: hidden !important;
    color: transparent !important;
    background: var(--navigation-item-count-background-color, #6d4aff) !important;
    border-radius: 50% !important;
  }
  .sidebar.desktop-force-collapsed [data-testid="sidebar:storage-meter"],
  .sidebar.desktop-force-collapsed .sidebar-storage-upsell,
  .sidebar.desktop-force-collapsed .sidebar-version,
  .sidebar.desktop-force-collapsed .minicalendar-container,
  .sidebar.desktop-force-collapsed [data-testid="calendar-sidebar:calendars-list"] span:not(.icon) {
    display: none !important;
  }

  #proton-desktop-collapse-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    position: absolute;
    bottom: 0.75rem;
    right: 0.5rem;
    width: 1.75rem;
    height: 1.75rem;
    border-radius: 0.375rem;
    background: var(--interaction-weak, rgba(255,255,255,0.08));
    border: none;
    color: var(--text-weak, #a0a0a0);
    cursor: pointer;
    z-index: 100;
    transition: all 0.2s ease;
  }
  #proton-desktop-collapse-btn:hover {
    background: var(--interaction-default-hover, rgba(255,255,255,0.18));
    color: var(--text-norm, #ffffff);
  }
  .sidebar.desktop-force-collapsed #proton-desktop-collapse-btn,
  @media (min-width: 681px) and (max-width: 1050px) {
    .sidebar:not([data-expanded="true"]) #proton-desktop-collapse-btn {
      right: auto !important;
      left: 50% !important;
      transform: translateX(-50%) !important;
    }
  }
  .sidebar.desktop-force-collapsed #proton-desktop-collapse-btn svg,
  @media (min-width: 681px) and (max-width: 1050px) {
    .sidebar:not([data-expanded="true"]) #proton-desktop-collapse-btn svg {
      transform: rotate(180deg) !important;
    }
  }
  @media (max-width: 680px) {
    #proton-desktop-collapse-btn {
      display: none !important;
    }
  }

  /* Reading pane and content safety */
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

  const initResponsive = () => {
    const responsiveCss = ${JSON.stringify(responsiveCss)};

    const injectScript = \`(()=>{
      if (window.__protonDesktopResponsiveInjected) return;
      window.__protonDesktopResponsiveInjected = true;

      const styleId = "proton-desktop-responsive-custom-css";
      if (!document.getElementById(styleId)) {
        const style = document.createElement("style");
        style.id = styleId;
        style.textContent = \${JSON.stringify(responsiveCss)};
        (document.head || document.documentElement).appendChild(style);
      }

      function setupCollapseBtn() {
        const sidebar = document.querySelector(".sidebar");
        if (!sidebar) return;
        if (document.getElementById("proton-desktop-collapse-btn")) return;

        const btn = document.createElement("button");
        btn.id = "proton-desktop-collapse-btn";
        btn.title = "Toggle navigation bar (Ctrl+[)";
        btn.setAttribute("aria-label", "Toggle navigation bar");
        btn.innerHTML = '<svg viewBox="0 0 16 16" width="16" height="16" fill="currentColor"><path d="M10.354 3.646a.5.5 0 0 1 0 .708L6.707 8l3.647 3.646a.5.5 0 0 1-.708.708l-4-4a.5.5 0 0 1 0-.708l4-4a.5.5 0 0 1 .708 0z"/></svg>';
        btn.className = "sidebar-desktop-toggle-btn";

        const saved = localStorage.getItem("proton-desktop-sidebar-collapsed");
        if (saved === "true") {
          sidebar.classList.add("desktop-force-collapsed");
        }

        btn.onclick = (e) => {
          e.stopPropagation();
          const isCollapsed = sidebar.classList.toggle("desktop-force-collapsed");
          localStorage.setItem("proton-desktop-sidebar-collapsed", isCollapsed ? "true" : "false");
        };

        sidebar.appendChild(btn);
      }

      window.addEventListener("keydown", (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === "[") {
          const sidebar = document.querySelector(".sidebar");
          if (sidebar) {
            const isCollapsed = sidebar.classList.toggle("desktop-force-collapsed");
            localStorage.setItem("proton-desktop-sidebar-collapsed", isCollapsed ? "true" : "false");
          }
        }
      });

      const observer = new MutationObserver(() => setupCollapseBtn());
      observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
      setupCollapseBtn();
    })();\`;

    const attachToView = (view) => {
      if (!view || !view.webContents) return;
      const inject = async () => {
        try {
          await view.webContents.insertCSS(responsiveCss);
          await view.webContents.executeJavaScript(injectScript);
        } catch (e) {
          Ns.debug("Responsive injection notice:", e);
        }
      };
      view.webContents.on("did-finish-load", inject);
      view.webContents.on("dom-ready", inject);
      if (!view.webContents.isLoading()) {
        inject();
      }
    };

    if (typeof Da !== "undefined" && Da) {
      attachToView(Da.mail);
      attachToView(Da.calendar);
      attachToView(Da.account);
    }
  };

  r.app.on("before-quit", () => {
    r.app.isQuitting = true;
  });

  initTray();
  initResponsive();
})();
`;

let replacedInsert = false;
if (code.includes(insertTargetExact)) {
  code = code.replace(insertTargetExact, insertTargetExact + "\n" + trayCode);
  replacedInsert = true;
} else {
  const insertRegex = /T\(\)\.maximized&&Ba\.maximize\(\),Ba\.on\("closed",\s*\(\)\s*=>\s*\{Ba=null\}\);/;
  if (insertRegex.test(code)) {
    code = code.replace(insertRegex, match => match + "\n" + trayCode);
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
  console.error("Syntax error after patching:", err);
  process.exit(1);
}

fs.writeFileSync(targetFile, code, "utf8");
console.log("Successfully patched Proton Mail with system tray, close-to-tray, and responsive layout features.");
