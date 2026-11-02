const fs = require('fs');

const appAsarMain = process.argv[2];
const obsidianAsarMain = process.argv[3];

if (!appAsarMain || !obsidianAsarMain || !fs.existsSync(appAsarMain) || !fs.existsSync(obsidianAsarMain)) {
    console.error('Usage: node patch-cli-register.js <path-to-app-asar-main.js> <path-to-obsidian-asar-main.js>');
    process.exit(1);
}

// On Linux, "Register CLI" copies obsidian-cli over ~/.local/bin/obsidian when
// obsidian-cli sits next to the app binary. That copy hides /usr/bin/obsidian
// in PATH and cannot start the app. This package already ships /usr/bin/obsidian
// (opens the app, forwards CLI commands) and /usr/bin/obsidian-cli, so make
// registration a no-op whenever the packaged launcher is present.
const MARKER = '/usr/bin/obsidian opens Obsidian and runs CLI commands';

function patchCliRegister(code) {
    const re = /if\(([\w$]+)\.existsSync\(([\w$]+)\)\)\{(\1\.existsSync\([\w$]+\)\|\|\1\.mkdirSync\([\w$]+,\{recursive:!0\}\);try\{\1\.unlinkSync\(([\w$]+)\)\}catch\([\w$]+\)\{\}return \1\.copyFileSync\(\2,\4\))/;
    return code.replace(re, 'if($1.existsSync($2)){if($1.existsSync("/usr/bin/obsidian"))return{success:!0,message:"Already registered in PATH: /usr/bin/obsidian opens Obsidian and runs CLI commands."};$3');
}

// ---------------------------------------------------------------------------
// 1. Patch obsidian.asar/main.js
// ---------------------------------------------------------------------------
const obsContent = fs.readFileSync(obsidianAsarMain, 'utf8');

if (obsContent.includes(MARKER)) {
    console.log(`CLI registration patch already present in ${obsidianAsarMain}`);
} else {
    const patched = patchCliRegister(obsContent);
    if (patched === obsContent) {
        console.error(`Error: Linux CLI registration code not found in ${obsidianAsarMain}`);
        process.exit(1);
    }
    fs.writeFileSync(obsidianAsarMain, patched, 'utf8');
    console.log(`Successfully patched CLI registration in ${obsidianAsarMain}`);
}

// ---------------------------------------------------------------------------
// 2. Patch app.asar/main.js with a runtime hook for in-app updated obsidian.asar
// ---------------------------------------------------------------------------
let appContent = fs.readFileSync(appAsarMain, 'utf8');

if (appContent.includes('_patchCliRegister')) {
    console.log(`CLI registration runtime hook already present in ${appAsarMain}`);
} else {
    const runtimeHookCode = `
// ---------------------------------------------------------------------------
// Keep "Register CLI" from replacing ~/.local/bin/obsidian with obsidian-cli
// ---------------------------------------------------------------------------
if (process.platform === 'linux') {
    const _patchCliRegister = ${patchCliRegister.toString()};

    // Wrap _compile so this composes with the other require hooks
    const _prevCliJs = require.extensions['.js'];
    require.extensions['.js'] = function(_module, _filename) {
        if (_filename.includes('obsidian') && _filename.endsWith('main.js') && !_filename.includes('app.asar')) {
            const _origCompile = _module._compile;
            _module._compile = function(_code, ..._rest) {
                try {
                    _code = _patchCliRegister(_code);
                } catch (_) {}
                return _origCompile.call(this, _code, ..._rest);
            };
        }
        return _prevCliJs(_module, _filename);
    };
}
`;

    appContent += '\n' + runtimeHookCode;
    fs.writeFileSync(appAsarMain, appContent, 'utf8');
    console.log(`Successfully patched ${appAsarMain} with CLI registration runtime hook`);
}
