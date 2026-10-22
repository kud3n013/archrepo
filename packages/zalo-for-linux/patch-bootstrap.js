// patch-bootstrap.js <extracted app.asar dir> <archrepo-bootstrap.js> <app/main-dist dir>
//
// Adds the bootstrap to an extracted app.asar and points package.json "main" at it.
// It fails if the entry point is missing, the tree is already patched, the template
// placeholder is not found exactly once, or Zalo's bundle no longer contains the two
// upstream patches the bootstrap relies on. A version bump that changes any of these
// then breaks the build instead of shipping a window that silently misbehaves.
"use strict";

const fs = require("fs");
const path = require("path");

const BOOTSTRAP_NAME = "archrepo-bootstrap.js";
const PLACEHOLDER = '"__ORIGINAL_MAIN__"';

// Upstream patches inside app/main-dist/main.js (scripts/patches in upstream's repo):
// patch-auto-theme's block returns early when global.__zaloThemeSync is set, and
// patch-titlebar gives the main window a native frame except on native Wayland.
const REQUIRED_IN_BUNDLE = [
  'if (process.platform !== "linux" || global.__zaloThemeSync) return;',
  "frame:!global.__zaloNativeWayland",
];

function fail(message) {
  console.error(`patch-bootstrap: ${message}`);
  process.exit(1);
}

const [appDir, template, mainDist] = process.argv.slice(2);
if (!appDir || !template || !mainDist) {
  fail("usage: patch-bootstrap.js <app dir> <bootstrap template> <main-dist dir>");
}

const bundle = fs.readFileSync(path.join(mainDist, "main.js"), "utf8");
for (const needle of REQUIRED_IN_BUNDLE) {
  if (!bundle.includes(needle)) {
    fail(`app/main-dist/main.js no longer contains: ${needle}`);
  }
}

const pkgPath = path.join(appDir, "package.json");
const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf8"));
const original = pkg.main;

if (!original) {
  fail("package.json has no main entry");
}
if (original === BOOTSTRAP_NAME) {
  fail("app.asar is already patched");
}
if (!fs.existsSync(path.join(appDir, original))) {
  fail(`main entry not found: ${original}`);
}

const source = fs.readFileSync(template, "utf8");
if (source.split(PLACEHOLDER).length !== 2) {
  fail("template placeholder must appear exactly once");
}

fs.writeFileSync(path.join(appDir, BOOTSTRAP_NAME), source.replace(PLACEHOLDER, () => JSON.stringify(original)));
pkg.main = BOOTSTRAP_NAME;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");

console.log(`patch-bootstrap: main ${original} -> ${BOOTSTRAP_NAME}`);
