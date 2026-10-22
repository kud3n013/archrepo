// patch-titlebar.js <extracted app.asar dir> <titlebar-bootstrap.js> <theme-sync.js>
//
// Adds the bootstrap and the theme sync module it loads to an extracted app.asar,
// and points package.json "main" at the bootstrap.
// It fails if the entry point is missing, the tree is already patched, or the
// template placeholder is not found exactly once. A version bump that changes the
// layout then breaks the build instead of shipping a window that silently misbehaves.
"use strict";

const fs = require("fs");
const path = require("path");

const BOOTSTRAP_NAME = "archrepo-bootstrap.js";
const THEME_SYNC_NAME = "archrepo-theme-sync.js";
const PLACEHOLDER = '"__ORIGINAL_MAIN__"';

function fail(message) {
  console.error(`patch-titlebar: ${message}`);
  process.exit(1);
}

const [appDir, template, themeSync] = process.argv.slice(2);
if (!appDir || !template || !themeSync) {
  fail("usage: patch-titlebar.js <app dir> <bootstrap template> <theme sync module>");
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
if (fs.existsSync(path.join(appDir, THEME_SYNC_NAME))) {
  fail(`${THEME_SYNC_NAME} already exists`);
}
if (!fs.existsSync(path.join(appDir, original))) {
  fail(`main entry not found: ${original}`);
}

const source = fs.readFileSync(template, "utf8");
if (source.split(PLACEHOLDER).length !== 2) {
  fail("template placeholder must appear exactly once");
}

fs.writeFileSync(path.join(appDir, BOOTSTRAP_NAME), source.replace(PLACEHOLDER, () => JSON.stringify(original)));
fs.copyFileSync(themeSync, path.join(appDir, THEME_SYNC_NAME));
pkg.main = BOOTSTRAP_NAME;
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");

console.log(`patch-titlebar: main ${original} -> ${BOOTSTRAP_NAME}`);
