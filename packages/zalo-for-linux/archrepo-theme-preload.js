// Live light/dark switching, renderer half. archrepo-theme.js adds this preload to
// every session, so it runs in every page before the page's own preload.
//
// Zalo and ZaDark ignore the system theme unless the user picked "system" in them:
// - Zalo stores {theme, theme_setting} in localStorage "za_theme". theme_setting is
//   0 Light, 1 Dark, 2 System or 3 Custom, and its stylesheets key off body.dark. Zalo
//   evaluates System once, when it is picked, and does not follow later changes.
// - ZaDark stores "light", "dark" or "auto" in "@ZaDark:THEME". In "auto" it follows
//   prefers-color-scheme by itself. An unset key means "dark".
//
// Upstream's preload half (in preload-render.js) toggles the dark class on every system
// change, whatever the user picked in Zalo. This script keeps the class in line with
// Zalo's own setting instead: the system theme while the setting is System (or unset,
// which upstream turns into System), otherwise the theme the user picked. Custom
// themes are left to Zalo.
"use strict";

const { ipcRenderer } = require("electron");

const DARK_QUERY = "(prefers-color-scheme: dark)";
const THEME_SETTING = { SYSTEM: 2, CUSTOM: 3 };
// Zalo's own colours for each theme, stored with the theme ("color" in za_theme).
const ZALO_COLORS = {
  light: { backgroundPrimary: "#FFFFFF", colorPrimary: "#081B3A" },
  dark: { backgroundPrimary: "#22262B", colorPrimary: "#DFE2E7" },
};

let reported = null;

function readZaloTheme() {
  try {
    return JSON.parse(localStorage.getItem("za_theme"));
  } catch {
    return null;
  }
}

// Returns whether the page should be dark, or null to leave it alone.
function wantDark() {
  const conf = readZaloTheme();
  if (conf?.theme_setting === THEME_SETTING.CUSTOM) {
    return null;
  }
  if (conf && conf.theme_setting !== undefined && conf.theme_setting !== THEME_SETTING.SYSTEM) {
    return conf.theme === "dark";
  }
  const dark = matchMedia(DARK_QUERY).matches;
  const theme = dark ? "dark" : "light";
  // Zalo reads the stored theme on its next start, so it is kept in step.
  if (conf && (conf.theme !== theme || conf.color?.backgroundPrimary !== ZALO_COLORS[theme].backgroundPrimary)) {
    localStorage.setItem("za_theme", JSON.stringify({ ...conf, theme, color: ZALO_COLORS[theme] }));
  }
  return dark;
}

function sync() {
  const dark = wantDark();
  if (dark === null) {
    return;
  }
  for (const element of [document.documentElement, document.body]) {
    if (element && element.classList.contains("dark") !== dark) {
      element.classList.toggle("dark", dark);
    }
  }
  if (dark !== reported) {
    reported = dark;
    ipcRenderer.send("archrepo-theme-applied", dark);
  }
}

// Zalo pages only. Remote pages (the QR login widget) have their own styles.
if (location.protocol === "file:") {
  // The same default as Zalo's: follow the system until the user picks a theme.
  try {
    if (localStorage.getItem("@ZaDark:THEME") === null) {
      localStorage.setItem("@ZaDark:THEME", "auto");
    }
  } catch {}

  matchMedia(DARK_QUERY).addEventListener("change", sync);

  // A MutationObserver callback runs after the code that changed the class, so this
  // has the last word over upstream's preload and still runs before the next paint.
  // Zalo's own changes agree with what it stored, so they are left as they are.
  window.addEventListener("DOMContentLoaded", () => {
    const observer = new MutationObserver(sync);
    for (const element of [document.documentElement, document.body]) {
      observer.observe(element, { attributes: true, attributeFilter: ["class"] });
    }
    sync();
  });
}
