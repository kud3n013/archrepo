// patch-asar.js <extracted app.asar dir> <z-library-bootstrap.js>
//
// Adds the bootstrap to an extracted app.asar and points package.json "main" at it.
// It fails if the entry point is missing, the tree is already patched, or the
// template placeholder is not found exactly once. A version bump that changes the
// layout then breaks the build instead of shipping a window that silently misbehaves.
"use strict";

const fs = require("fs");
const path = require("path");

// The app's package.json sets "type": "module", so a .js file would load as an ES
// module. The bootstrap is CommonJS and has to run before the app's imports.
const BOOTSTRAP_NAME = "archrepo-bootstrap.cjs";
const PLACEHOLDER = '"__ORIGINAL_MAIN__"';

function fail(message) {
  console.error(`patch-asar: ${message}`);
  process.exit(1);
}

const [appDir, template] = process.argv.slice(2);
if (!appDir || !template) {
  fail("usage: patch-asar.js <app dir> <bootstrap template>");
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

console.log(`patch-asar: main ${original} -> ${BOOTSTRAP_NAME}`);
