#!/usr/bin/env python3
"""
patch-zalo.py: Modifies Zalo for Linux for kud3n013/archrepo
- Dynamic light/dark theme synchronization following KDE system mode
- Removes the in-app top bar showing "Zalo - {{user name}}"
- Exports application menu to KDE Plasma Global Menu via DBusMenu
"""

import os
import sys
import re
import struct
import json
import shutil
import subprocess

def unpack_asar(asar_file, dest_dir):
    # Try system asar first if available
    if shutil.which("asar"):
        res = subprocess.run(["asar", "extract", asar_file, dest_dir], capture_output=True)
        if res.returncode == 0:
            return

    # Self-contained pure Python ASAR unpacker
    with open(asar_file, "rb") as f:
        u1, u2, u3, json_len = struct.unpack("<IIII", f.read(16))
        header_json = f.read(json_len).decode("utf-8")
        header = json.loads(header_json)
        base_offset = 16 + ((json_len + 3) & ~3)

        def extract_node(node, current_path):
            if "files" in node:
                os.makedirs(current_path, exist_ok=True)
                for name, subnode in node["files"].items():
                    extract_node(subnode, os.path.join(current_path, name))
            elif "size" in node and "offset" in node:
                offset = base_offset + int(node["offset"])
                size = node["size"]
                f.seek(offset)
                data = f.read(size)
                os.makedirs(os.path.dirname(current_path), exist_ok=True)
                with open(current_path, "wb") as out:
                    out.write(data)
                if node.get("executable"):
                    os.chmod(current_path, 0o755)

        extract_node(header, dest_dir)

def pack_asar(src_dir, output_asar):
    # Try system asar first if available
    if shutil.which("asar"):
        res = subprocess.run(["asar", "pack", src_dir, output_asar], capture_output=True)
        if res.returncode == 0:
            return

    # Self-contained pure Python ASAR packer (Chromium Pickle aligned format)
    header = {"files": {}}
    files_to_write = []
    current_offset = 0

    def build_tree(current_dir, node):
        nonlocal current_offset
        entries = sorted(os.listdir(current_dir))
        for entry in entries:
            full_path = os.path.join(current_dir, entry)
            if os.path.islink(full_path):
                node[entry] = {"link": os.readlink(full_path)}
            elif os.path.isdir(full_path):
                subnode = {"files": {}}
                node[entry] = subnode
                build_tree(full_path, subnode["files"])
            else:
                size = os.path.getsize(full_path)
                file_info = {"size": size, "offset": str(current_offset)}
                if os.access(full_path, os.X_OK):
                    file_info["executable"] = True
                node[entry] = file_info
                files_to_write.append(full_path)
                current_offset += size

    build_tree(src_dir, header["files"])
    header_json = json.dumps(header, separators=(",", ":")).encode("utf-8")
    json_len = len(header_json)
    aligned_str_len = (json_len + 3) & ~3
    padding = b"\0" * (aligned_str_len - json_len)

    u1 = 4
    u4 = json_len
    u3 = aligned_str_len + 4
    u2 = u3 + 4

    tmp_asar = output_asar + ".tmp"
    with open(tmp_asar, "wb") as f:
        f.write(struct.pack("<IIII", u1, u2, u3, u4))
        f.write(header_json)
        f.write(padding)
        for filepath in files_to_write:
            with open(filepath, "rb") as in_f:
                while True:
                    chunk = in_f.read(65536)
                    if not chunk:
                        break
                    f.write(chunk)
    os.replace(tmp_asar, output_asar)

def patch_app_asar(squashfs_root):
    asar_path = os.path.join(squashfs_root, "resources", "app.asar")
    if not os.path.isfile(asar_path):
        print(f"Error: {asar_path} not found", file=sys.stderr)
        sys.exit(1)

    extract_dir = os.path.join(squashfs_root, "resources", "app.asar.extracted")
    if os.path.exists(extract_dir):
        shutil.rmtree(extract_dir)

    print("==> Extracting resources/app.asar...")
    unpack_asar(asar_path, extract_dir)

    main_js_path = os.path.join(extract_dir, "main.js")
    with open(main_js_path, "r", encoding="utf-8") as f:
        main_js = f.read()

    print("==> Patching main.js: Adding KDE Global Menu support...")

    # 1. Provide KDE Global Menu template builder
    menu_builder_code = """
// ---------------------------------------------------------------------------
// KDE Global Menu / Application Menu (archrepo mod)
// ---------------------------------------------------------------------------
function buildZaloAppMenu(targetWin) {
  const getWin = () => targetWin && !targetWin.isDestroyed() ? targetWin : (BrowserWindow.getFocusedWindow() || mainWindow);
  const template = [
    {
      label: "Zalo",
      submenu: [
        {
          label: "Thông tin về Zalo (About)",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed() && w.webContents) w.webContents.send("about");
          }
        },
        {
          label: "Cài đặt (Preferences)…",
          accelerator: "CmdOrCtrl+,",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed() && w.webContents) w.webContents.send("preferences");
          }
        },
        {
          label: "Cài đặt gọi điện (ZCall)…",
          click: () => {
            zcallBridgePlugin.openSetupDialog({ userDataDir: app.getPath("userData") });
          }
        },
        { type: "separator" },
        {
          label: "Ẩn Zalo",
          accelerator: "CmdOrCtrl+H",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed()) w.hide();
          }
        },
        {
          label: "Thoát (Quit)",
          accelerator: "CmdOrCtrl+Q",
          click: () => {
            isAppQuitting = true;
            if (tray) {
              tray.destroy();
              tray = null;
            }
            app.quit();
          }
        }
      ]
    },
    {
      label: "Chỉnh sửa (Edit)",
      submenu: [
        { label: "Hoàn tác (Undo)", role: "undo" },
        { label: "Làm lại (Redo)", role: "redo" },
        { type: "separator" },
        { label: "Cắt (Cut)", role: "cut" },
        { label: "Sao chép (Copy)", role: "copy" },
        { label: "Dán (Paste)", role: "paste" },
        { label: "Chọn tất cả (Select All)", role: "selectAll" }
      ]
    },
    {
      label: "Xem (View)",
      submenu: [
        {
          label: "Tin nhắn (Messages)",
          accelerator: "Alt+1",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed() && w.webContents) w.webContents.send("switch_tab", 1);
          }
        },
        {
          label: "Danh bạ (Contacts)",
          accelerator: "Alt+2",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed() && w.webContents) w.webContents.send("switch_tab", 2);
          }
        },
        {
          label: "Nhóm tham gia (Groups)",
          accelerator: "Alt+3",
          click: () => {
            const w = getWin();
            if (w && !w.isDestroyed() && w.webContents) w.webContents.send("switch_tab", 3);
          }
        },
        { type: "separator" },
        { label: "Phóng to (Zoom In)", role: "zoomIn" },
        { label: "Thu nhỏ (Zoom Out)", role: "zoomOut" },
        { label: "Đặt lại cỡ chữ (Actual Size)", role: "resetZoom" },
        { type: "separator" },
        { label: "Toàn màn hình (Full Screen)", role: "togglefullscreen" },
        {
          label: "Toggle DevTools",
          accelerator: "Ctrl+Shift+I",
          click: toggleDevTools
        }
      ]
    },
    {
      label: "Cửa sổ (Window)",
      submenu: [
        { label: "Thu nhỏ cửa sổ", role: "minimize" },
        { label: "Đóng cửa sổ", accelerator: "CmdOrCtrl+W", role: "close" }
      ]
    },
    {
      label: "Trợ giúp (Help)",
      submenu: [
        {
          label: "Trung tâm trợ giúp Zalo",
          click: () => {
            require("electron").shell.openExternal("https://help.zalo.me");
          }
        },
        {
          label: "Báo cáo lỗi (GitHub)",
          click: () => {
            require("electron").shell.openExternal("https://github.com/VN-Linux-Family/zalo-for-linux/issues");
          }
        }
      ]
    }
  ];
  return Menu.buildFromTemplate(template);
}
"""
    anchor = "app.on('browser-window-created',"
    if anchor in main_js and "function buildZaloAppMenu" not in main_js:
        main_js = main_js.replace(anchor, menu_builder_code + "\n" + anchor)

    # 2. Retain menu for KDE Global Menu while auto-hiding the in-window bar
    win_menu_old = re.compile(
        r"win\.setMenuBarVisibility\(false\);\s*"
        r"if\s*\(win\.removeMenu\)\s*win\.removeMenu\(\);\s*"
        r"win\.autoHideMenuBar\s*=\s*true;",
        re.MULTILINE
    )
    win_menu_new = """win.autoHideMenuBar = true;
    try {
      const appMenu = buildZaloAppMenu(win);
      Menu.setApplicationMenu(appMenu);
      if (win.setMenu) win.setMenu(appMenu);
    } catch (_) {}"""
    if win_menu_old.search(main_js):
        main_js = win_menu_old.sub(win_menu_new, main_js, count=1)
    else:
        print("  WARNING: Window menu removal pattern not found in main.js")

    # 3. Export initial ApplicationMenu on ready
    ready_old = "try { Menu.setApplicationMenu(null); } catch (_) { }"
    ready_new = """try {
    const appMenu = buildZaloAppMenu(null);
    Menu.setApplicationMenu(appMenu);
  } catch (e) {
    console.error("Failed to initialize application menu:", e);
  }"""
    if ready_old in main_js:
        main_js = main_js.replace(ready_old, ready_new)
    else:
        print("  WARNING: Ready menu clear pattern not found in main.js")

    with open(main_js_path, "w", encoding="utf-8") as f:
        f.write(main_js)

    print("==> Repacking resources/app.asar...")
    pack_asar(extract_dir, asar_path)
    shutil.rmtree(extract_dir)

def patch_main_dist(squashfs_root):
    main_js_path = os.path.join(squashfs_root, "app", "main-dist", "main.js")
    if not os.path.isfile(main_js_path):
        print(f"Error: {main_js_path} not found", file=sys.stderr)
        sys.exit(1)

    print("==> Patching app/main-dist/main.js: Adding KDE system mode dark/light theme sync...")
    with open(main_js_path, "r", encoding="utf-8") as f:
        content = f.read()

    theme_block_re = re.compile(
        r"// --- Zalo Linux Auto Dark/Light Theme Sync ---\n\(function\(\)\{[\s\S]*?\n\}\)\(\);\n?"
    )

    kde_theme_main = """// --- Zalo Linux Auto Dark/Light Theme Sync (with KDE Support) ---
(function(){
  if (process.platform !== "linux" || global.__zaloThemeSync) return;
  global.__zaloThemeSync = true;
  const { app: _app, ipcMain: _ipc, BrowserWindow: _bw, nativeTheme: _nt } = require("electron");
  const fs = require("fs");
  const path = require("path");

  function isKdeDark() {
    try {
      const kfile = path.join(process.env.HOME || "", ".config", "kdeglobals");
      if (!fs.existsSync(kfile)) return null;
      const content = fs.readFileSync(kfile, "utf8");
      const mBg = content.match(/\\[Colors:Window\\][^\\[]*\\bBackgroundNormal\\s*=\\s*(\\d+)\\s*,\\s*(\\d+)\\s*,\\s*(\\d+)/s);
      if (mBg) {
        const r = parseInt(mBg[1], 10), g = parseInt(mBg[2], 10), b = parseInt(mBg[3], 10);
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        return lum < 128;
      }
      const mScheme = content.match(/\\b(?:ColorScheme|LookAndFeelPackage)\\s*=\\s*([^\\r\\n]+)/i);
      if (mScheme) {
        const val = mScheme[1].toLowerCase();
        if (val.includes("dark")) return true;
        if (val.includes("light")) return false;
      }
    } catch (_) {}
    return null;
  }

  function isLinuxDark() {
    const isKde = /KDE/i.test(process.env.XDG_CURRENT_DESKTOP || "") || process.env.KDE_FULL_SESSION === "true";
    if (isKde) {
      const kde = isKdeDark();
      if (kde !== null) return kde;
    }
    const { execSync: _es } = require("child_process");
    try {
      const o = _es('dbus-send --session --print-reply=literal --dest=org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings.Read string:"org.freedesktop.appearance" string:"color-scheme" 2>/dev/null', { timeout: 1000 }).toString();
      if (o.includes("uint32 1")) return true;
      if (o.includes("uint32 2")) return false;
    } catch (_) {}
    const kde = isKdeDark();
    if (kde !== null) return kde;
    try {
      const o = _es("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null", { timeout: 1000 }).toString();
      if (o.includes("prefer-dark")) return true;
      if (o.includes("default") || o.includes("prefer-light")) return false;
    } catch (_) {}
    try {
      const o = _es("gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null", { timeout: 1000 }).toString().toLowerCase();
      if (o.includes("dark")) return true;
    } catch (_) {}
    return false;
  }

  _ipc.removeHandler("zalo-linux-get-theme");
  _ipc.handle("zalo-linux-get-theme", () => isLinuxDark() ? "dark" : "light");

  let _lastDark = null;
  function syncTheme() {
    const d = isLinuxDark();
    if (d !== _lastDark) {
      _lastDark = d;
      _nt.themeSource = d ? "dark" : "light";
      _bw.getAllWindows().forEach((w) => {
        try {
          if (w && !w.isDestroyed() && w.webContents) {
            w.webContents.send("zalo-linux-theme-change", d ? "dark" : "light");
          }
        } catch (_) {}
      });
    }
  }

  syncTheme();

  const kfile = path.join(process.env.HOME || "", ".config", "kdeglobals");
  let _kdeWatcher = null;
  function watchKde() {
    try {
      if (fs.existsSync(kfile)) {
        if (_kdeWatcher) try { _kdeWatcher.close(); } catch (_) {}
        _kdeWatcher = fs.watch(kfile, (evt) => {
          syncTheme();
          if (evt === "rename") setTimeout(watchKde, 200);
        });
        _kdeWatcher.on("error", () => {});
      }
    } catch (_) {}
  }
  watchKde();
  try {
    if (fs.existsSync(kfile)) {
      fs.watchFile(kfile, { interval: 1000 }, () => syncTheme());
    }
  } catch (_) {}

  const _poll = setInterval(syncTheme, 4000);

  let _quitting = false;
  try {
    const { spawn: _sp } = require("child_process");
    const _w = _sp("gsettings", ["monitor", "org.gnome.desktop.interface", "color-scheme"], { stdio: ["ignore", "pipe", "ignore"] });
    _w.stdout.on("data", () => syncTheme());
    const _stop = () => {
      _quitting = true;
      clearInterval(_poll);
      if (_kdeWatcher) try { _kdeWatcher.close(); } catch (_) {}
      try { _w.kill(); } catch (_) {}
    };
    _app.on("will-quit", _stop);
    process.on("exit", _stop);
  } catch (_) {}
})();
"""
    if theme_block_re.search(content):
        content = theme_block_re.sub(lambda _: kde_theme_main, content)
    else:
        content += "\n" + kde_theme_main + "\n"

    with open(main_js_path, "w", encoding="utf-8") as f:
        f.write(content)

def patch_preload(squashfs_root):
    preload_path = os.path.join(squashfs_root, "app", "main-dist", "preload-render.js")
    if not os.path.isfile(preload_path):
        print(f"Error: {preload_path} not found", file=sys.stderr)
        sys.exit(1)

    print("==> Patching app/main-dist/preload-render.js: Theme application & Top Bar removal...")
    with open(preload_path, "r", encoding="utf-8") as f:
        content = f.read()

    theme_block_re = re.compile(
        r"// --- Zalo Linux Auto Dark/Light Theme Sync ---\n\(function\(\)\{[\s\S]*?\n\}\)\(\);\n?"
    )

    kde_preload = """// --- Zalo Linux Auto Dark/Light Theme Sync & Top Bar Removal ---
(function() {
  if (process.platform !== "linux") return;
  const { ipcRenderer } = require("electron");

  function applyTheme(isDark) {
    const mode = isDark ? "dark" : "light";
    try {
      document.documentElement.setAttribute("data-zadark-theme", mode);
      localStorage.setItem("@ZaDark:THEME", mode);
    } catch (_) {}
    if (isDark) {
      document.documentElement.classList.add("dark");
      if (document.body) document.body.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
      if (document.body) document.body.classList.remove("dark");
    }
    try {
      const confStr = localStorage.getItem("za_theme");
      let conf = confStr ? JSON.parse(confStr) : {};
      conf.theme = mode;
      conf.theme_setting = 2;
      localStorage.setItem("za_theme", JSON.stringify(conf));
    } catch (_) {}
  }

  ipcRenderer.on("zalo-linux-theme-change", (e, mode) => {
    applyTheme(mode === "dark");
  });

  try {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    mq.addEventListener("change", (e) => applyTheme(e.matches));
    applyTheme(mq.matches);
  } catch (_) {}

  ipcRenderer.invoke("zalo-linux-get-theme").then((mode) => {
    applyTheme(mode === "dark");
  }).catch(() => {});

  function removeTopBar() {
    const css = "#titleBar,.titlebar:not(.debugger-mini-profile-monitor__titlebar){display:none!important;height:0!important;min-height:0!important;max-height:0!important;padding:0!important;margin:0!important;border:none!important;visibility:hidden!important;overflow:hidden!important}";
    function addStyle() {
      if (document.getElementById("zalo-remove-topbar")) return;
      const s = document.createElement("style");
      s.id = "zalo-remove-topbar";
      s.textContent = css;
      if (document.head || document.documentElement) {
        (document.head || document.documentElement).appendChild(s);
      }
    }
    addStyle();
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", addStyle);
    }
  }
  removeTopBar();
})();
"""
    if theme_block_re.search(content):
        content = theme_block_re.sub(lambda _: kde_preload, content)
    else:
        content += "\n" + kde_preload + "\n"

    with open(preload_path, "w", encoding="utf-8") as f:
        f.write(content)

def patch_zadark_css(squashfs_root):
    zadark_css_path = os.path.join(squashfs_root, "app", "pc-dist", "zadark", "css", "zadark.min.css")
    if not os.path.isfile(zadark_css_path):
        print(f"Warning: {zadark_css_path} not found, skipping CSS injection", file=sys.stderr)
        return

    print("==> Patching pc-dist/zadark/css/zadark.min.css: Inlining Top Bar removal rule...")
    with open(zadark_css_path, "r", encoding="utf-8") as f:
        css = f.read()

    hide_topbar_rule = "\n#titleBar,.titlebar:not(.debugger-mini-profile-monitor__titlebar){display:none!important;height:0!important;min-height:0!important;max-height:0!important;padding:0!important;margin:0!important;border:none!important;visibility:hidden!important;overflow:hidden!important}\n"
    if hide_topbar_rule not in css:
        css += hide_topbar_rule
        with open(zadark_css_path, "w", encoding="utf-8") as f:
            f.write(css)

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path-to-squashfs-root>", file=sys.stderr)
        sys.exit(1)

    squashfs_root = os.path.abspath(sys.argv[1])
    if not os.path.isdir(squashfs_root):
        print(f"Error: {squashfs_root} is not a directory", file=sys.stderr)
        sys.exit(1)

    print(f"Applying KDE mods to {squashfs_root}...")
    patch_app_asar(squashfs_root)
    patch_main_dist(squashfs_root)
    patch_preload(squashfs_root)
    patch_zadark_css(squashfs_root)
    print("Done applying all KDE mods successfully.")

if __name__ == "__main__":
    main()
