#!/usr/bin/env python3
"""
Steam KDE Plasma Global Menu Bridge
Exports Steam client menus, navigation shortcuts, and recent games
to the KDE Plasma Global Menu widget via the DBusMenu protocol.
"""

import os
import sys
import re
import glob
import time
import signal
import logging
import subprocess
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple

import gi
gi.require_version('Dbusmenu', '0.4')
from gi.repository import Dbusmenu, GLib, Gio

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger("steam-globalmenu")

DBUS_SERVICE_NAME = "org.kde.steam.AppMenu"
DBUS_OBJECT_PATH = "/MenuBar"
REGISTRAR_SERVICE = "com.canonical.AppMenu.Registrar"
REGISTRAR_PATH = "/com/canonical/AppMenu/Registrar"


class SteamVDFReader:
    """Discovers and parses local Steam configuration, library paths, and games."""

    def __init__(self):
        self.steam_root = self._detect_steam_root()

    @staticmethod
    def _detect_steam_root() -> Optional[Path]:
        candidates = [
            Path.home() / ".local/share/Steam",
            Path.home() / ".steam/root",
            Path.home() / ".steam/steam",
        ]
        for p in candidates:
            if p.is_dir():
                return p
        return None

    def get_library_paths(self) -> List[Path]:
        if not self.steam_root:
            return []
        paths = [self.steam_root]
        lib_vdf = self.steam_root / "steamapps" / "libraryfolders.vdf"
        if lib_vdf.is_file():
            try:
                content = lib_vdf.read_text(encoding="utf-8", errors="ignore")
                matches = re.findall(r'\"path\"\s*\"([^\"]+)\"', content)
                for m in matches:
                    p = Path(m)
                    if p.is_dir() and p not in paths:
                        paths.append(p)
            except Exception as e:
                log.warning("Failed to read libraryfolders.vdf: %s", e)
        return paths

    def get_installed_games(self) -> Dict[str, str]:
        """Maps AppID -> Game Title for installed games."""
        games: Dict[str, str] = {}
        for lib in self.get_library_paths():
            steamapps = lib / "steamapps"
            if not steamapps.is_dir():
                continue
            for acf in steamapps.glob("appmanifest_*.acf"):
                try:
                    content = acf.read_text(encoding="utf-8", errors="ignore")
                    appid_m = re.search(r'\"appid\"\s*\"(\d+)\"', content)
                    name_m = re.search(r'\"name\"\s*\"([^\"]+)\"', content)
                    if appid_m and name_m:
                        appid = appid_m.group(1)
                        name = name_m.group(1)
                        # Filter out Steam common runtimes / Steamworks redistributables
                        if "Steamworks Shared" not in name and "Steam Linux Runtime" not in name:
                            games[appid] = name
                except Exception as e:
                    log.debug("Error reading %s: %s", acf, e)

        # Also check for non-Steam shortcuts if available
        if self.steam_root:
            for sc_file in self.steam_root.glob("userdata/*/config/shortcuts.vdf"):
                try:
                    data = sc_file.read_bytes()
                    # Binary VDF parsing for non-Steam shortcuts
                    chunks = data.split(b"\x01AppName\x00")
                    for chunk in chunks[1:]:
                        null_idx = chunk.find(b"\x00")
                        if null_idx > 0:
                            app_name = chunk[:null_idx].decode("utf-8", errors="ignore")
                            id_match = re.search(rb'\x02appid\x00(....)', chunk)
                            if id_match:
                                raw_id = int.from_bytes(id_match.group(1), byteorder="little", signed=True)
                                app_id = str(raw_id | 0x80000000)
                                games[app_id] = app_name
                except Exception as e:
                    log.debug("Error parsing %s: %s", sc_file, e)

        return games

    def get_recent_games(self, limit: int = 10) -> List[Tuple[str, str]]:
        """Returns list of (AppID, Game Title) sorted by LastPlayed timestamp."""
        if not self.steam_root:
            return []

        installed = self.get_installed_games()
        recent_played: Dict[str, int] = {}

        # Look in all user configs
        for cfg in self.steam_root.glob("userdata/*/config/localconfig.vdf"):
            try:
                content = cfg.read_text(encoding="utf-8", errors="ignore")
                matches = re.findall(r'\"(\d+)\"\s*\{\s*\"LastPlayed\"\s*\"(\d+)\"', content)
                for appid, ts in matches:
                    timestamp = int(ts)
                    if timestamp > recent_played.get(appid, 0):
                        recent_played[appid] = timestamp
            except Exception as e:
                log.warning("Failed to parse %s: %s", cfg, e)

        sorted_appids = sorted(recent_played.items(), key=lambda x: x[1], reverse=True)
        results: List[Tuple[str, str]] = []
        for appid, _ in sorted_appids:
            if appid in installed:
                results.append((appid, installed[appid]))
            if len(results) >= limit:
                break

        return results


class SteamGlobalMenuBridge:
    """DBusMenu server and X11 window hook for Steam."""

    def __init__(self):
        self.vdf_reader = SteamVDFReader()
        self.bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        self.server = Dbusmenu.Server.new(DBUS_OBJECT_PATH)
        self.root_item = Dbusmenu.Menuitem.new()
        self.server.set_root(self.root_item)

        self.hooked_windows: Set[int] = set()
        self.recent_games_menu: Optional[Dbusmenu.Menuitem] = None
        self.installed_games_menu: Optional[Dbusmenu.Menuitem] = None

        self._build_static_menus()
        self._refresh_dynamic_menus()

        # Claim the bus name
        Gio.bus_own_name(
            Gio.BusType.SESSION,
            DBUS_SERVICE_NAME,
            Gio.BusNameOwnerFlags.NONE,
            self._on_bus_acquired,
            self._on_name_acquired,
            self._on_name_lost
        )

        # Set up AppMenu registrar proxy
        self.registrar_proxy = None
        try:
            self.registrar_proxy = Gio.DBusProxy.new_sync(
                self.bus,
                Gio.DBusProxyFlags.NONE,
                None,
                REGISTRAR_SERVICE,
                REGISTRAR_PATH,
                REGISTRAR_SERVICE,
                None
            )
        except Exception as e:
            log.warning("Could not connect to AppMenu Registrar: %s", e)

    def _on_bus_acquired(self, connection, name):
        log.info("D-Bus connection acquired for %s", name)

    def _on_name_acquired(self, connection, name):
        log.info("Successfully acquired D-Bus name: %s", name)

    def _on_name_lost(self, connection, name):
        log.warning("Lost or failed to acquire D-Bus name: %s", name)

    def _add_action(self, parent: Dbusmenu.Menuitem, label: str, target: str) -> Dbusmenu.Menuitem:
        item = Dbusmenu.Menuitem.new()
        item.property_set("label", label)
        item.connect("item-activated", self._on_item_activated, target)
        parent.child_append(item)
        return item

    def _add_separator(self, parent: Dbusmenu.Menuitem):
        sep = Dbusmenu.Menuitem.new()
        sep.property_set("type", "separator")
        parent.child_append(sep)

    def _on_item_activated(self, menuitem, timestamp, target: str):
        log.info("Menu item activated: %s", target)
        try:
            if target == "EXIT":
                subprocess.Popen(["steam", "-shutdown"])
            elif target == "RESTART":
                subprocess.Popen(["sh", "-c", "steam -shutdown && sleep 2 && steam &"])
            elif target.startswith("steam://"):
                subprocess.Popen(["steam", target])
            elif target.startswith("https://"):
                subprocess.Popen(["xdg-open", target])
        except Exception as e:
            log.error("Failed to execute action %s: %s", target, e)

    def _build_static_menus(self):
        # 1. Steam Menu
        top_steam = Dbusmenu.Menuitem.new()
        top_steam.property_set("label", "Steam")
        self.root_item.child_append(top_steam)

        self._add_action(top_steam, "Settings", "steam://open/settings")
        self._add_action(top_steam, "Check for Steam Client Updates...", "steam://open/console")
        self._add_action(top_steam, "Backup and Restore Games...", "steam://backup/")
        self._add_separator(top_steam)
        self._add_action(top_steam, "Go Online", "steam://friends/status/online")
        self._add_action(top_steam, "Go Offline", "steam://friends/status/offline")
        self._add_separator(top_steam)
        self._add_action(top_steam, "Restart Steam", "RESTART")
        self._add_action(top_steam, "Exit Steam", "EXIT")

        # 2. View Menu
        top_view = Dbusmenu.Menuitem.new()
        top_view.property_set("label", "View")
        self.root_item.child_append(top_view)

        self._add_action(top_view, "Library", "steam://nav/games")
        self._add_action(top_view, "Hidden Games", "steam://nav/games/hidden")
        self._add_action(top_view, "Downloads", "steam://open/downloads")
        self._add_action(top_view, "Screenshots", "steam://open/screenshots")
        self._add_action(top_view, "Inventory", "steam://open/inventory")
        self._add_action(top_view, "Badges", "steam://open/badges")
        self._add_action(top_view, "Music Player", "steam://open/musicplayer")
        self._add_separator(top_view)
        self._add_action(top_view, "Big Picture Mode", "steam://open/bigpicture")

        # 3. Friends Menu
        top_friends = Dbusmenu.Menuitem.new()
        top_friends.property_set("label", "Friends")
        self.root_item.child_append(top_friends)

        self._add_action(top_friends, "View Friends List", "steam://open/friends")
        self._add_action(top_friends, "Add a Friend...", "steam://friends/add")

        status_menu = Dbusmenu.Menuitem.new()
        status_menu.property_set("label", "Online Status")
        top_friends.child_append(status_menu)
        self._add_action(status_menu, "Online", "steam://friends/status/online")
        self._add_action(status_menu, "Away", "steam://friends/status/away")
        self._add_action(status_menu, "Invisible", "steam://friends/status/invisible")
        self._add_action(status_menu, "Offline", "steam://friends/status/offline")

        self._add_separator(top_friends)
        self._add_action(top_friends, "Edit Profile Name / Avatar...", "steam://url/SteamIDEditPage")

        # 4. Games Menu
        top_games = Dbusmenu.Menuitem.new()
        top_games.property_set("label", "Games")
        self.root_item.child_append(top_games)

        self._add_action(top_games, "View Games Library", "steam://nav/games")

        # Dynamic submenus
        self.recent_games_menu = Dbusmenu.Menuitem.new()
        self.recent_games_menu.property_set("label", "Recent Games")
        top_games.child_append(self.recent_games_menu)

        self.installed_games_menu = Dbusmenu.Menuitem.new()
        self.installed_games_menu.property_set("label", "Installed Games")
        top_games.child_append(self.installed_games_menu)

        self._add_separator(top_games)
        self._add_action(top_games, "Activate a Product on Steam...", "steam://open/activateproduct")
        self._add_action(top_games, "Redeem a Steam Wallet Code...", "steam://url/RedeemWalletCode")
        self._add_action(top_games, "Add a Non-Steam Game to My Library...", "steam://AddNonSteamGame")

        # 5. Help Menu
        top_help = Dbusmenu.Menuitem.new()
        top_help.property_set("label", "Help")
        self.root_item.child_append(top_help)

        self._add_action(top_help, "Steam Support", "steam://url/HelpFrontPage")
        self._add_action(top_help, "System Information", "steam://open/systeminfo")
        self._add_action(top_help, "About Steam", "steam://open/about")
        self._add_separator(top_help)
        self._add_action(top_help, "Privacy Policy", "steam://url/PrivacyPolicy")
        self._add_action(top_help, "Steam Subscriber Agreement", "steam://url/SubscriberAgreement")

    def _refresh_dynamic_menus(self):
        """Populates Recent Games and Installed Games submenus from VDF files."""
        # Refresh Recent Games
        if self.recent_games_menu:
            for child in list(self.recent_games_menu.get_children()):
                self.recent_games_menu.child_delete(child)

            recent = self.vdf_reader.get_recent_games(limit=10)
            if recent:
                for appid, title in recent:
                    self._add_action(self.recent_games_menu, title, f"steam://rungameid/{appid}")
            else:
                dummy = Dbusmenu.Menuitem.new()
                dummy.property_set("label", "No Recent Games")
                dummy.property_set_bool("enabled", False)
                self.recent_games_menu.child_append(dummy)

        # Refresh Installed Games
        if self.installed_games_menu:
            for child in list(self.installed_games_menu.get_children()):
                self.installed_games_menu.child_delete(child)

            installed = self.vdf_reader.get_installed_games()
            if installed:
                for appid, title in sorted(installed.items(), key=lambda x: x[1].lower())[:25]:
                    self._add_action(self.installed_games_menu, title, f"steam://rungameid/{appid}")
            else:
                dummy = Dbusmenu.Menuitem.new()
                dummy.property_set("label", "No Installed Games")
                dummy.property_set_bool("enabled", False)
                self.installed_games_menu.child_append(dummy)

    def scan_windows(self):
        """Scans _NET_CLIENT_LIST for Steam windows and applies DBusMenu properties."""
        try:
            out = subprocess.check_output(
                ["xprop", "-root", "_NET_CLIENT_LIST"],
                text=True,
                stderr=subprocess.DEVNULL
            )
        except Exception:
            return True

        current_wids: Set[int] = set()
        matches = re.findall(r'0x[0-9a-fA-F]+', out)
        for wid_str in matches:
            try:
                wid = int(wid_str, 16)
                current_wids.add(wid)
            except ValueError:
                continue

        # Check each active window
        for wid in current_wids:
            if wid in self.hooked_windows:
                continue

            wid_hex = hex(wid)
            try:
                prop_out = subprocess.check_output(
                    ["xprop", "-id", wid_hex, "WM_CLASS", "WM_NAME", "_NET_WM_WINDOW_TYPE"],
                    text=True,
                    stderr=subprocess.DEVNULL
                )
            except Exception:
                continue

            # Check WM_CLASS specifically to avoid matching other apps with 'steam' in title
            wm_class_m = re.search(r'WM_CLASS\(STRING\)\s*=\s*(.*)', prop_out)
            if not wm_class_m:
                continue
            wm_class_val = wm_class_m.group(1).lower()
            if not ('"steam"' in wm_class_val or '"steamwebhelper"' in wm_class_val):
                continue

            # Must be a normal or dialog window (exclude tooltips, popups, notification toasts)
            is_normal = (
                "_NET_WM_WINDOW_TYPE_NORMAL" in prop_out
                or "_NET_WM_WINDOW_TYPE_DIALOG" in prop_out
                or 'WM_NAME(UTF8_STRING) = "Steam"' in prop_out
                or 'WM_NAME(UTF-8) = "Steam"' in prop_out
            )

            if is_normal:
                self._hook_window(wid, wid_hex)

        # Clean up windows that no longer exist
        dead_windows = self.hooked_windows - current_wids
        for dead_wid in dead_windows:
            self._unhook_window(dead_wid)

        return True

    def _hook_window(self, wid: int, wid_hex: str):
        log.info("Hooking Steam window %s (0x%x)", wid_hex, wid)
        try:
            subprocess.run(
                ["xprop", "-id", wid_hex, "-f", "_KDE_NET_WM_APPMENU_SERVICE_NAME", "8s", "-set", "_KDE_NET_WM_APPMENU_SERVICE_NAME", DBUS_SERVICE_NAME],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            subprocess.run(
                ["xprop", "-id", wid_hex, "-f", "_KDE_NET_WM_APPMENU_OBJECT_PATH", "8s", "-set", "_KDE_NET_WM_APPMENU_OBJECT_PATH", DBUS_OBJECT_PATH],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )

            if self.registrar_proxy:
                try:
                    self.registrar_proxy.RegisterWindow('(uo)', wid, DBUS_OBJECT_PATH)
                except Exception as e:
                    log.debug("AppMenu Registrar call failed: %s", e)

            self.hooked_windows.add(wid)
            log.info("Successfully exported Global Menu to window %s", wid_hex)
        except Exception as e:
            log.warning("Failed to hook window %s: %s", wid_hex, e)

    def _unhook_window(self, wid: int):
        log.info("Unhooking closed Steam window 0x%x", wid)
        self.hooked_windows.discard(wid)
        if self.registrar_proxy:
            try:
                self.registrar_proxy.UnregisterWindow('(u)', wid)
            except Exception as e:
                log.debug("Error unregistering window: %s", e)

    def cleanup(self):
        log.info("Cleaning up hooked windows...")
        for wid in list(self.hooked_windows):
            self._unhook_window(wid)


def main():
    bridge = SteamGlobalMenuBridge()

    def handle_signal(sig, frame):
        log.info("Received termination signal %s", sig)
        bridge.cleanup()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    # Poll for windows every 1.5 seconds (0% CPU impact)
    GLib.timeout_add(1500, bridge.scan_windows)
    # Refresh dynamic games menu every 60 seconds
    GLib.timeout_add_seconds(60, lambda: (bridge._refresh_dynamic_menus(), True)[1])

    # Initial scan
    bridge.scan_windows()

    log.info("Steam KDE Plasma Global Menu Bridge daemon is running.")
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        bridge.cleanup()


if __name__ == "__main__":
    main()
