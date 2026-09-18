#!/usr/bin/env python3
"""
patch-omni.py: Patches Zotero's app/omni.ja archive for kud3n013/archrepo
- Enables Global Menu on Wayland and X11 by default
- Restores OS native window title bar (Server-Side Decorations)
- Removes fake in-app CSD title bar buttons
- Restores native GTK menubar for Hyprland and KDE Global Menu export
"""

import os
import sys
import zipfile

def patch_omni(omni_path):
    if not os.path.isfile(omni_path):
        print(f"Error: {omni_path} not found", file=sys.stderr)
        sys.exit(1)

    print(f"Patching {omni_path}...")
    temp_path = omni_path + ".tmp"

    with zipfile.ZipFile(omni_path, "r") as zin, zipfile.ZipFile(
        temp_path, "w", compression=zipfile.ZIP_DEFLATED
    ) as zout:
        for item in zin.infolist():
            content = zin.read(item.filename)

            # 1. Patch default preferences
            if item.filename == "defaults/preferences/zotero.js":
                text = content.decode("utf-8", errors="ignore")
                extra_prefs = (
                    "\n// kud3n013/archrepo: Global Menu, Wayland & Native Title Bar\n"
                    'pref("widget.gtk.global-menu.enabled", true);\n'
                    'pref("widget.gtk.global-menu.wayland.enabled", true);\n'
                    'pref("browser.tabs.inTitlebar", 0);\n'
                    'pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);\n'
                )
                text += extra_prefs
                content = text.encode("utf-8")
                print("  -> Patched defaults/preferences/zotero.js")

            # 2. Patch titlebar.js
            elif item.filename == "chrome/content/zotero/titlebar.js":
                text = content.decode("utf-8", errors="ignore")
                target = 'let platforms = document.querySelector("window")?.getAttribute("drawintitlebar-platforms");'
                linux_code = """
if (Zotero.isLinux) {
	// archrepo: Restore native system title bar and adapt to desktop environment
	document.documentElement.removeAttribute('customtitlebar');
	document.documentElement.toggleAttribute("drawtitle", true);

	try {
		const env = Services.env;
		const desktopEnv = (env.get("ZOTERO_DESKTOP_ENV") || "").toLowerCase();
		const currentDesktop = (env.get("XDG_CURRENT_DESKTOP") || "").toLowerCase();
		const hideMenuBar = (env.get("ZOTERO_HIDE_MENUBAR") || "").toLowerCase();

		const isKDE = desktopEnv === "kde" || currentDesktop.includes("kde") || currentDesktop.includes("plasma");

		if (isKDE || hideMenuBar === "1" || hideMenuBar === "true") {
			document.documentElement.setAttribute('zotero-desktop', 'kde');
		} else {
			document.documentElement.setAttribute('zotero-desktop', 'gtk');
		}
	} catch (e) {
		Zotero.logError(e);
	}
	return;
}
"""
                if target in text:
                    text = text.replace(target, target + "\n" + linux_code, 1)
                    content = text.encode("utf-8")
                    print("  -> Patched chrome/content/zotero/titlebar.js")
                else:
                    print("  WARNING: target insertion point not found in titlebar.js", file=sys.stderr)

            # 3. Patch unix/zotero.css
            elif item.filename == "chrome/content/zotero-platform/unix/zotero.css":
                text = content.decode("utf-8", errors="ignore")
                css_mods = """
/* archrepo: Native Title Bar & Menu Theming (GTK for Hyprland, Qt for KDE) */
.titlebar-buttonbox,
.titlebar-icon-container {
    display: none !important;
}

#titlebar {
    height: auto !important;
    min-height: 24px !important;
    flex-direction: row !important;
    justify-content: flex-start !important;
    pointer-events: auto !important;
    -moz-appearance: menubar !important;
    background-color: -moz-Dialog !important;
    background: inherit !important;
    border: none !important;
    border-radius: 0 !important;
    -moz-window-dragging: no-drag !important;
}

#toolbar-menubar {
    display: flex !important;
    align-items: center !important;
    width: 100% !important;
    -moz-window-dragging: no-drag !important;
}

#main-menubar {
    -moz-appearance: menubar !important;
    display: flex !important;
    flex-direction: row !important;
    justify-content: flex-start !important;
    background: transparent !important;
}

#main-menubar > menu {
    -moz-appearance: menuitem !important;
    color: inherit !important;
    padding: 2px 6px !important;
}

/* On KDE: hide redundant in-window menu bar as it is exported to KDE Global Menu */
:root[zotero-desktop="kde"] #titlebar {
    height: 0 !important;
    min-height: 0 !important;
    max-height: 0 !important;
    overflow: hidden !important;
    opacity: 0 !important;
    pointer-events: none !important;
    margin: 0 !important;
    padding: 0 !important;
    border: none !important;
    visibility: collapse !important;
}
"""
                text += css_mods
                content = text.encode("utf-8")
                print("  -> Patched chrome/content/zotero-platform/unix/zotero.css")

            zout.writestr(item, content)

    os.replace(temp_path, omni_path)
    print("Done patching app/omni.ja.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path-to-app/omni.ja>", file=sys.stderr)
        sys.exit(1)
    patch_omni(sys.argv[1])
