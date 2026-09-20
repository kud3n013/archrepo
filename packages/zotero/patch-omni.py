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
                    "\n// kud3n013/archrepo: Native Title Bar, Theme Integration & KDE Global Menu\n"
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
		let desktopEnv = "";
		let currentDesktop = "";
		let hideMenuBar = "";
		let menuBarConfig = "";
		let enableGlobalMenu = true;
		try {
			const env = (typeof Services !== "undefined" && Services.env) ? Services.env :
			            (typeof Components !== "undefined" ? Components.classes["@mozilla.org/process/environment;1"]?.getService(Components.interfaces.nsIEnvironment) : null);
			if (env) {
				desktopEnv = (env.get("ZOTERO_DESKTOP_ENV") || "").toLowerCase();
				currentDesktop = (env.get("XDG_CURRENT_DESKTOP") || "").toLowerCase();
				hideMenuBar = (env.get("ZOTERO_HIDE_MENUBAR") || "").toLowerCase();
				menuBarConfig = (env.get("ZOTERO_MENUBAR") || "").toLowerCase();
				const gm = (env.get("ZOTERO_GLOBAL_MENU") || "").toLowerCase();
				if (gm === "0" || gm === "false" || gm === "off") {
					enableGlobalMenu = false;
				}
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

		// archrepo: Throttle popupshowing on menubar popups to break KDE Plasma D-Bus LayoutUpdated runaway loop
		const _lastPopupShowingTimes = new WeakMap();
		window.addEventListener("popupshowing", (event) => {
			let popup = event.target;
			if (!popup || !popup.id) return;
			if (!popup.closest || !popup.closest("#main-menubar")) return;
			let now = Date.now();
			let last = _lastPopupShowingTimes.get(popup) || 0;
			// Suppress rapid re-queries within 800ms triggered by D-Bus LayoutUpdated storm
			if (now - last < 800) {
				event.stopImmediatePropagation();
				return;
			}
			_lastPopupShowingTimes.set(popup, now);
		}, true);

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

				// Open Settings / Preferences with Ctrl+, / Cmd+,
				if ((e.ctrlKey || e.metaKey) && !e.shiftKey && !e.altKey && e.key === ",") {
					e.preventDefault();
					try {
						Zotero.Utilities.Internal.openPreferences();
					} catch (err) {}
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

/* Collapsed when in autohide mode and inactive, or when explicitly hidden */
:root[zotero-menubar="autohide"] #titlebar:not([menuparent-active="true"]),
:root[zotero-menubar="hidden"] #titlebar {
    display: none !important;
    height: 0px !important;
    min-height: 0px !important;
    max-height: 0px !important;
    padding: 0 !important;
    margin: 0 !important;
    border: none !important;
    overflow: hidden !important;
}

/* Revealed when active or set to permanently visible */
:root[zotero-menubar="visible"] #titlebar,
#titlebar[menuparent-active="true"] {
    display: flex !important;
    flex-direction: row !important;
    align-items: center !important;
    height: 30px !important;
    min-height: 30px !important;
    max-height: 30px !important;
    padding: 0 6px !important;
    margin: 0 !important;
    border: none !important;
    border-bottom: 1px solid var(--material-border, rgba(127, 127, 127, 0.2)) !important;
    background: var(--material-tabbar, -moz-Dialog) !important;
    color: var(--fill-primary, -moz-DialogText) !important;
    overflow: visible !important;
    opacity: 1 !important;
    pointer-events: auto !important;
    -moz-window-dragging: no-drag !important;
}

#toolbar-menubar {
    display: flex !important;
    align-items: center !important;
    flex: 1 !important;
    height: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
    background: transparent !important;
    pointer-events: auto !important;
    -moz-window-dragging: no-drag !important;
}

#toolbar-menubar #menubar-items {
    display: flex !important;
    align-items: center !important;
    height: 100% !important;
}

#main-menubar {
    height: 100% !important;
    background: transparent !important;
    border: none !important;
    padding: 0 !important;
    margin: 0 !important;
    pointer-events: auto !important;
}

#main-menubar > menu {
    color: inherit !important;
    height: 24px !important;
    line-height: 24px !important;
    padding: 2px 8px !important;
    margin: 1px 2px !important;
    border-radius: 4px !important;
    cursor: default !important;
    font-size: 13px !important;
}

#main-menubar > menu[_moz-menuactive="true"],
#main-menubar > menu:hover {
    background-color: var(--fill-quinary, rgba(127, 127, 127, 0.2)) !important;
    color: inherit !important;
}

#main-menubar > menu[open="true"] {
    background-color: var(--fill-quaternary, rgba(127, 127, 127, 0.3)) !important;
}
"""
                text += css_mods
                content = text.encode("utf-8")
                print("  -> Patched chrome/content/zotero-platform/unix/zotero.css")

            # 4. Patch standalone.js to prevent D-Bus LayoutUpdated storm
            elif item.filename == "chrome/content/zotero/standalone/standalone.js":
                text = content.decode("utf-8", errors="ignore")
                target = "while (addMenu.hasChildNodes()) addMenu.removeChild(addMenu.firstChild);"
                replacement = "// archrepo: Prevent D-Bus LayoutUpdated storm in KDE Global Menu\n    if (addMenu.hasChildNodes()) return;\n    " + target
                if target in text:
                    text = text.replace(target, replacement, 1)
                    content = text.encode("utf-8")
                    print("  -> Patched chrome/content/zotero/standalone/standalone.js (prevent D-Bus storm)")
                else:
                    print("  WARNING: target buildNewItemMenu wipe not found in standalone.js", file=sys.stderr)

            # 5. Patch itemTreeMenuBar.js to prevent D-Bus LayoutUpdated storm
            elif item.filename == "chrome/content/zotero/elements/itemTreeMenuBar.js":
                text = content.decode("utf-8", errors="ignore")
                target = "menu.menupopup.replaceChildren();"
                replacement = "// archrepo: Prevent D-Bus LayoutUpdated storm in KDE Global Menu\n    if (menu.menupopup.hasChildNodes()) return;\n    " + target
                if target in text:
                    text = text.replace(target, replacement, 1)
                    content = text.encode("utf-8")
                    print("  -> Patched chrome/content/zotero/elements/itemTreeMenuBar.js (prevent D-Bus storm)")
                else:
                    print("  WARNING: target replaceChildren not found in itemTreeMenuBar.js", file=sys.stderr)

            # 6. Patch zoteroPane.xhtml to add Ctrl+, shortcut to mainKeyset and menu_EditPreferencesItem
            elif item.filename == "chrome/content/zotero/zoteroPane.xhtml":
                text = content.decode("utf-8", errors="ignore")
                target_keyset = '<keyset id="mainKeyset">'
                replacement_keyset = '<keyset id="mainKeyset">\n\t\t<key id="key_preferences" key="," modifiers="accel" oncommand="Zotero.Utilities.Internal.openPreferences()"/>'
                if target_keyset in text:
                    text = text.replace(target_keyset, replacement_keyset, 1)

                target_item = '<menuitem id="menu_EditPreferencesItem"'
                replacement_item = '<menuitem id="menu_EditPreferencesItem" key="key_preferences"'
                if target_item in text:
                    text = text.replace(target_item, replacement_item, 1)

                content = text.encode("utf-8")
                print("  -> Patched chrome/content/zotero/zoteroPane.xhtml (Ctrl+, Settings shortcut)")

            zout.writestr(item, content)

    os.replace(temp_path, omni_path)
    print("Done patching app/omni.ja.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <path-to-app/omni.ja>", file=sys.stderr)
        sys.exit(1)
    patch_omni(sys.argv[1])
