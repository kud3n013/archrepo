#!/usr/bin/env python3
"""
patch-omni.py: Patches Zotero's app/omni.ja archive for kud3n013/archrepo
- Enables Global Menu on Wayland and X11 by default
- Restores OS native window title bar (Server-Side Decorations)
- Removes fake in-app CSD title bar buttons
- Supports Alt key & F10 to reveal/toggle menubar on Hyprland (plus Ctrl+M permanent toggle)
- Automatically hides in-window menubar on KDE Plasma in favor of KDE Global Menu
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
                    "\n// kud3n013/archrepo: Native Title Bar & Wayland Integration\n"
                    'pref("widget.gtk.global-menu.enabled", false);\n'
                    'pref("widget.gtk.global-menu.wayland.enabled", false);\n'
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
		let desktopEnv = "";
		let currentDesktop = "";
		let hideMenuBar = "";
		let menuBarConfig = "";
		let enableGlobalMenu = false;
		try {
			const env = (typeof Services !== "undefined" && Services.env) ? Services.env :
			            (typeof Components !== "undefined" ? Components.classes["@mozilla.org/process/environment;1"]?.getService(Components.interfaces.nsIEnvironment) : null);
			if (env) {
				desktopEnv = (env.get("ZOTERO_DESKTOP_ENV") || "").toLowerCase();
				currentDesktop = (env.get("XDG_CURRENT_DESKTOP") || "").toLowerCase();
				hideMenuBar = (env.get("ZOTERO_HIDE_MENUBAR") || "").toLowerCase();
				menuBarConfig = (env.get("ZOTERO_MENUBAR") || "").toLowerCase();
				const gm = (env.get("ZOTERO_GLOBAL_MENU") || "").toLowerCase();
				enableGlobalMenu = (gm === "1" || gm === "true");
			}
		} catch (e) {}

		if (typeof Services !== "undefined" && Services.prefs) {
			Services.prefs.setBoolPref("widget.gtk.global-menu.enabled", enableGlobalMenu);
			Services.prefs.setBoolPref("widget.gtk.global-menu.wayland.enabled", enableGlobalMenu);
		}

		const isKDE = desktopEnv === "kde" || currentDesktop.includes("kde") || currentDesktop.includes("plasma");
		document.documentElement.setAttribute('zotero-desktop', isKDE ? 'kde' : 'gtk');

		let menubarMode = "autohide";
		if (hideMenuBar === "1" || hideMenuBar === "true" || menuBarConfig === "hidden") {
			menubarMode = "hidden";
		} else if (menuBarConfig === "visible") {
			menubarMode = "visible";
		}
		document.documentElement.setAttribute('zotero-menubar', menubarMode);

		// Setup Alt key, F10, and Ctrl+M menubar toggling on all desktop environments (KDE, Hyprland, etc.)
		const initMenubarToggle = () => {
			const titlebar = document.getElementById("titlebar");
			const menubar = document.getElementById("main-menubar");
			if (!titlebar || !menubar) return;

			let isVisible = () => titlebar.getAttribute("menuparent-active") === "true";
			let showMenu = (focusFirst = true) => {
				titlebar.setAttribute("menuparent-active", "true");
				if (focusFirst) {
					let firstMenu = menubar.querySelector("menu");
					if (firstMenu) {
						firstMenu.focus();
					}
				}
			};
			let hideMenu = () => {
				titlebar.removeAttribute("menuparent-active");
			};

			let altPressedOnly = false;

			window.addEventListener("blur", () => {
				altPressedOnly = false;
			});

			window.addEventListener("keydown", (e) => {
				// Toggle permanent visibility with Ctrl+M (standard Linux shortcut)
				if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "m") {
					e.preventDefault();
					let current = document.documentElement.getAttribute("zotero-menubar");
					let next = (current === "visible") ? "autohide" : "visible";
					document.documentElement.setAttribute("zotero-menubar", next);
					return;
				}

				// F10 key focuses menubar (standard GTK / Linux behaviour)
				if (e.key === "F10") {
					e.preventDefault();
					if (isVisible()) {
						hideMenu();
					} else {
						showMenu(true);
					}
					return;
				}

				// Solitary Alt key down
				if (e.key === "Alt" && !e.ctrlKey && !e.shiftKey && !e.metaKey) {
					altPressedOnly = true;
					return;
				}

				// Alt + Access key (e.g. Alt+F, Alt+E, Alt+V, Alt+T, Alt+H)
				if (e.altKey && !e.ctrlKey && !e.metaKey) {
					altPressedOnly = false;
					let key = e.key.toLowerCase();
					let targetMenu = menubar.querySelector(`menu[accesskey="${key}"]`) ||
					                 menubar.querySelector(`menu[label^="${e.key.toUpperCase()}"]`);
					if (targetMenu) {
						e.preventDefault();
						showMenu(false);
						targetMenu.open = true;
						let popup = targetMenu.querySelector("menupopup");
						if (popup && typeof popup.openPopup === "function") {
							try { popup.openPopup(targetMenu, "after_start", 0, 0, false, false); } catch(err) {}
						}
						return;
					}
				}

				if (e.key !== "Alt") {
					altPressedOnly = false;
				}

				// Escape key closes menu
				if (e.key === "Escape" && isVisible()) {
					hideMenu();
				}
			}, true);

			window.addEventListener("keyup", (e) => {
				if (e.key === "Alt" && altPressedOnly) {
					altPressedOnly = false;
					if (isVisible()) {
						hideMenu();
					} else {
						showMenu(true);
					}
				}
			}, true);

			// Hide when clicking outside menubar
			window.addEventListener("click", (e) => {
				if (isVisible() && !titlebar.contains(e.target)) {
					let openPopup = menubar.querySelector("menupopup[open='true']");
					if (!openPopup) {
						hideMenu();
					}
				}
			}, true);

			// Listen for popup closing
			menubar.addEventListener("popuphidden", () => {
				setTimeout(() => {
					let active = menubar.querySelector("menu[_moz-menuactive='true']") ||
					             menubar.querySelector("menu:focus");
					if (!active && document.documentElement.getAttribute("zotero-menubar") === "autohide") {
						hideMenu();
					}
				}, 150);
			});
		};

		if (document.readyState === "complete" || document.readyState === "interactive") {
			initMenubarToggle();
		} else {
			window.addEventListener("DOMContentLoaded", initMenubarToggle, { once: true });
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
    min-height: 0 !important;
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

/* Unified Menubar Visibility (KDE Plasma, Hyprland, etc.) */

/* Auto-hide mode (default): hidden in-window until revealed by Alt or F10 */
:root[zotero-menubar="autohide"] #titlebar {
    display: none !important;
}

:root[zotero-menubar="autohide"] #titlebar[menuparent-active="true"] {
    display: flex !important;
}

/* Permanently visible mode (via Ctrl+M toggle or ZOTERO_MENUBAR=visible) */
:root[zotero-menubar="visible"] #titlebar {
    display: flex !important;
}

/* Permanently hidden mode (e.g. ZOTERO_HIDE_MENUBAR=1 or ZOTERO_MENUBAR=hidden) */
:root[zotero-menubar="hidden"] #titlebar {
    display: none !important;
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
