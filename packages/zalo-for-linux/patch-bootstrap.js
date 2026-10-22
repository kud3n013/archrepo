// patch-bootstrap.js <extracted app.asar dir> <app dir> <archrepo source dir>
//
// Adds the archrepo bootstrap and its feature files to an extracted app.asar and
// points package.json "main" at the bootstrap. Upstream's code is not edited.
//
// The bootstrap relies on upstream code it does not change: the frame patch, the
// theme sync guard, the preload half of the theme sync, and Zalo's own application
// menu. Each anchor below must appear exactly once. The script also fails if the
// entry point is missing, the tree is already patched, or the template placeholder
// is not found exactly once. A version bump that changes any of these then breaks
// the build instead of shipping a window that silently misbehaves.
"use strict";

const fs = require("fs");
const path = require("path");

const BOOTSTRAP_NAME = "archrepo-bootstrap.js";
const FEATURE_FILES = ["archrepo-globalmenu.js", "archrepo-titlebar.js", "archrepo-theme.js", "archrepo-theme-preload.js"];
const PLACEHOLDER = '"__ORIGINAL_MAIN__"';

// [file relative to the app dir, exact text, what depends on it]
const ANCHORS = [
  ["main-dist/main.js", "frame:!global.__zaloNativeWayland", "native frame on X11 (scripts/patches/patch-titlebar.js)"],
  ["main-dist/main.js", 'if (process.platform !== "linux" || global.__zaloThemeSync) return;', "theme sync guard (scripts/patches/patch-auto-theme.js)"],
  ["main-dist/preload-render.js", 'ipcRenderer.on("zalo-linux-theme-change"', "preload half of the theme sync"],
  ["main-dist/preload-render.js", 'ipcRenderer.invoke("zalo-linux-get-theme")', "preload half of the theme sync"],
  ["main-dist/main.js", ".setApplicationMenu(", "Zalo's own application menu"],
  ["main-dist/main.js", 'send("preferences")', "Preferences item of Zalo's menu"],
];

function fail(message) {
  console.error(`patch-bootstrap: ${message}`);
  process.exit(1);
}

const [asarDir, appDir, sourceDir] = process.argv.slice(2);
if (!asarDir || !appDir || !sourceDir) {
  fail("usage: patch-bootstrap.js <app.asar dir> <app dir> <source dir>");
}

for (const [file, text, reason] of ANCHORS) {
  const count = fs.readFileSync(path.join(appDir, file), "utf8").split(text).length - 1;
  if (count !== 1) {
    fail(`${file}: expected 1 occurrence of ${JSON.stringify(text)} (${reason}), found ${count}`);
  }
}

const pkgPath = path.join(asarDir, "package.json");
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const original = pkg.main;

if (!original) {
  fail("package.json has no main entry");
}
if (original === BOOTSTRAP_NAME) {
  fail("app.asar is already patched");
}
if (!fs.existsSync(path.join(asarDir, original))) {
  fail(`main entry not found: ${original}`);
}

const source = fs.readFileSync(path.join(sourceDir, BOOTSTRAP_NAME), "utf8");
if (source.split(PLACEHOLDER).length !== 2) {
  fail("template placeholder must appear exactly once");
}

fs.writeFileSync(path.join(asarDir, BOOTSTRAP_NAME), source.replace(PLACEHOLDER, () => JSON.stringify(original)));
for (const name of FEATURE_FILES) {
  fs.copyFileSync(path.join(sourceDir, name), path.join(asarDir, name));
}
pkg.main = BOOTSTRAP_NAME;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");

console.log(`patch-bootstrap: main ${original} -> ${BOOTSTRAP_NAME}`);
