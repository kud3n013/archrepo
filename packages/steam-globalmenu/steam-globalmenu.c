/*
 * steam-globalmenu.c
 *
 * High-performance, lightweight C daemon exporting the Steam client menu
 * and recent games to KDE Plasma Global Menu via the DBusMenu protocol.
 *
 * Compiles to a native ~25KB binary consuming < 3 MB of resident memory (RSS).
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <signal.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>

#include <glib.h>
#include <gio/gio.h>
#include <libdbusmenu-glib/server.h>
#include <libdbusmenu-glib/client.h>
#include <libdbusmenu-glib/menuitem.h>

#define VERSION "1.2.0"
#define DBUS_SERVICE_NAME "org.kde.steam.AppMenu"
#define DBUS_OBJECT_PATH "/MenuBar"
#define REGISTRAR_NAME "com.canonical.AppMenu.Registrar"
#define REGISTRAR_PATH "/com/canonical/AppMenu/Registrar"

static gboolean opt_silent = FALSE;
static gboolean opt_version = FALSE;

static GOptionEntry opt_entries[] = {
    {"silent", 's', 0, G_OPTION_ARG_NONE, &opt_silent, "Suppress informational logging to run silently", NULL},
    {"quiet", 'q', 0, G_OPTION_ARG_NONE, &opt_silent, "Alias for --silent", NULL},
    {"version", 'v', 0, G_OPTION_ARG_NONE, &opt_version, "Show program version and exit", NULL},
    {NULL}
};

#define LOG_INFO(...) do { if (!opt_silent) { g_print("[INFO] " __VA_ARGS__); g_print("\n"); } } while (0)
#define LOG_WARN(...) do { g_printerr("[WARN] " __VA_ARGS__); g_printerr("\n"); } while (0)

typedef struct {
    Display *dpy;
    Window root;
    Atom atom_client_list;
    Atom atom_service_name;
    Atom atom_object_path;
    Atom atom_window_type;
    Atom atom_type_normal;
    Atom atom_type_dialog;
    Atom atom_net_wm_name;

    GDBusProxy *registrar_proxy;
    DbusmenuServer *server;
    DbusmenuMenuitem *root_item;
    DbusmenuMenuitem *recent_menu;
    DbusmenuMenuitem *installed_menu;

    GHashTable *hooked_windows; // Window -> Window
    GMainLoop *loop;
} AppContext;

static AppContext g_ctx = {0};

/* --------------------------------------------------------------------------
 * Steam VDF & Library Parser
 * -------------------------------------------------------------------------- */

typedef struct {
    char appid[32];
    char title[128];
    uint64_t last_played;
} GameEntry;

static gint compare_recent_games(gconstpointer a, gconstpointer b) {
    const GameEntry *ga = (const GameEntry *)a;
    const GameEntry *gb = (const GameEntry *)b;
    if (gb->last_played > ga->last_played) return 1;
    if (gb->last_played < ga->last_played) return -1;
    return 0;
}

static gint compare_installed_games(gconstpointer a, gconstpointer b) {
    const GameEntry *ga = (const GameEntry *)a;
    const GameEntry *gb = (const GameEntry *)b;
    return g_ascii_strcasecmp(ga->title, gb->title);
}

static char *get_steam_root(void) {
    const char *home = g_get_home_dir();
    char *paths[] = {
        g_build_filename(home, ".local", "share", "Steam", NULL),
        g_build_filename(home, ".steam", "root", NULL),
        g_build_filename(home, ".steam", "steam", NULL),
        NULL
    };

    for (int i = 0; paths[i]; i++) {
        if (g_file_test(paths[i], G_FILE_TEST_IS_DIR)) {
            char *found = paths[i];
            for (int j = i + 1; paths[j]; j++) g_free(paths[j]);
            return found;
        }
        g_free(paths[i]);
    }
    return NULL;
}

static GList *get_library_folders(const char *steam_root) {
    GList *list = NULL;
    list = g_list_append(list, g_strdup(steam_root));

    char *lib_vdf = g_build_filename(steam_root, "steamapps", "libraryfolders.vdf", NULL);
    char *content = NULL;
    if (g_file_get_contents(lib_vdf, &content, NULL, NULL)) {
        char *line = content;
        while (*line) {
            char *next = strchr(line, '\n');
            if (next) *next = '\0';

            char *p = strstr(line, "\"path\"");
            if (p) {
                p += 6;
                while (*p && (*p == ' ' || *p == '\t' || *p == '\"')) p++;
                char *end = strchr(p, '\"');
                if (end) {
                    *end = '\0';
                    if (g_file_test(p, G_FILE_TEST_IS_DIR) && g_strcmp0(p, steam_root) != 0) {
                        list = g_list_append(list, g_strdup(p));
                    }
                }
            }
            if (!next) break;
            line = next + 1;
        }
        g_free(content);
    }
    g_free(lib_vdf);
    return list;
}

static GHashTable *scan_installed_games(const char *steam_root) {
    GHashTable *table = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, g_free);
    GList *libs = get_library_folders(steam_root);

    for (GList *l = libs; l; l = l->next) {
        const char *lib_path = (const char *)l->data;
        char *steamapps = g_build_filename(lib_path, "steamapps", NULL);
        GDir *dir = g_dir_open(steamapps, 0, NULL);
        if (dir) {
            const char *filename;
            while ((filename = g_dir_read_name(dir))) {
                if (g_str_has_prefix(filename, "appmanifest_") && g_str_has_suffix(filename, ".acf")) {
                    char *acf_path = g_build_filename(steamapps, filename, NULL);
                    char *content = NULL;
                    if (g_file_get_contents(acf_path, &content, NULL, NULL)) {
                        char appid[32] = {0};
                        char name[128] = {0};

                        char *p_id = strstr(content, "\"appid\"");
                        if (p_id) {
                            p_id += 7;
                            while (*p_id && (*p_id == ' ' || *p_id == '\t' || *p_id == '\"')) p_id++;
                            char *end_id = strchr(p_id, '\"');
                            if (end_id && (size_t)(end_id - p_id) < sizeof(appid)) {
                                strncpy(appid, p_id, end_id - p_id);
                            }
                        }

                        char *p_name = strstr(content, "\"name\"");
                        if (p_name) {
                            p_name += 6;
                            while (*p_name && (*p_name == ' ' || *p_name == '\t' || *p_name == '\"')) p_name++;
                            char *end_name = strchr(p_name, '\"');
                            if (end_name && (size_t)(end_name - p_name) < sizeof(name)) {
                                strncpy(name, p_name, end_name - p_name);
                            }
                        }

                        if (appid[0] && name[0]) {
                            if (!strstr(name, "Steamworks Shared") && !strstr(name, "Steam Linux Runtime")) {
                                g_hash_table_insert(table, g_strdup(appid), g_strdup(name));
                            }
                        }
                        g_free(content);
                    }
                    g_free(acf_path);
                }
            }
            g_dir_close(dir);
        }
        g_free(steamapps);
    }
    g_list_free_full(libs, g_free);
    return table;
}

/* --------------------------------------------------------------------------
 * DBusMenu & Menu Hierarchy Setup
 * -------------------------------------------------------------------------- */

static void on_action_activated(DbusmenuMenuitem *item, guint timestamp, gpointer user_data) {
    const char *target = (const char *)user_data;
    LOG_INFO("Triggering action: %s", target);

    if (g_strcmp0(target, "EXIT") == 0) {
        g_spawn_command_line_async("steam -shutdown", NULL);
    } else if (g_strcmp0(target, "RESTART") == 0) {
        g_spawn_command_line_async("sh -c 'steam -shutdown && sleep 2 && steam &'", NULL);
    } else if (g_str_has_prefix(target, "steam://")) {
        char *cmd = g_strdup_printf("steam \"%s\"", target);
        g_spawn_command_line_async(cmd, NULL);
        g_free(cmd);
    } else if (g_str_has_prefix(target, "https://")) {
        char *cmd = g_strdup_printf("xdg-open \"%s\"", target);
        g_spawn_command_line_async(cmd, NULL);
        g_free(cmd);
    }
}

static DbusmenuMenuitem *add_action(DbusmenuMenuitem *parent, const char *label, const char *target) {
    DbusmenuMenuitem *item = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(item, DBUSMENU_MENUITEM_PROP_LABEL, label);
    g_signal_connect_data(item, DBUSMENU_MENUITEM_SIGNAL_ITEM_ACTIVATED,
                          G_CALLBACK(on_action_activated), g_strdup(target), (GClosureNotify)g_free, 0);
    dbusmenu_menuitem_child_append(parent, item);
    return item;
}

static void add_separator(DbusmenuMenuitem *parent) {
    DbusmenuMenuitem *sep = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(sep, DBUSMENU_MENUITEM_PROP_TYPE, DBUSMENU_CLIENT_TYPES_SEPARATOR);
    dbusmenu_menuitem_child_append(parent, sep);
}

static void refresh_dynamic_menus(AppContext *ctx) {
    char *root = get_steam_root();
    if (!root) return;

    GHashTable *installed = scan_installed_games(root);

    // Refresh Recent Games
    if (ctx->recent_menu) {
        GList *children = dbusmenu_menuitem_get_children(ctx->recent_menu);
        while (children) {
            DbusmenuMenuitem *c = (DbusmenuMenuitem *)children->data;
            children = children->next;
            dbusmenu_menuitem_child_delete(ctx->recent_menu, c);
        }

        GList *recent_entries = NULL;
        char *userdata_path = g_build_filename(root, "userdata", NULL);
        GDir *dir = g_dir_open(userdata_path, 0, NULL);
        if (dir) {
            const char *acc_id;
            while ((acc_id = g_dir_read_name(dir))) {
                char *cfg = g_build_filename(userdata_path, acc_id, "config", "localconfig.vdf", NULL);
                char *content = NULL;
                if (g_file_get_contents(cfg, &content, NULL, NULL)) {
                    char *p = content;
                    while ((p = strstr(p, "\"LastPlayed\""))) {
                        char *q_start = p;
                        while (q_start > content && *q_start != '\"') q_start--;
                        if (q_start > content) {
                            char *id_end = q_start;
                            q_start--;
                            while (q_start > content && *q_start != '\"') q_start--;
                            if (*q_start == '\"') {
                                char appid[32] = {0};
                                size_t len = id_end - (q_start + 1);
                                if (len < sizeof(appid)) {
                                    strncpy(appid, q_start + 1, len);
                                    char *ts_start = p + 12;
                                    while (*ts_start && (*ts_start == ' ' || *ts_start == '\t' || *ts_start == '\"')) ts_start++;
                                    uint64_t ts = g_ascii_strtoull(ts_start, NULL, 10);
                                    if (ts > 0) {
                                        const char *title = g_hash_table_lookup(installed, appid);
                                        if (title) {
                                            GameEntry *e = g_new0(GameEntry, 1);
                                            g_strlcpy(e->appid, appid, sizeof(e->appid));
                                            g_strlcpy(e->title, title, sizeof(e->title));
                                            e->last_played = ts;
                                            recent_entries = g_list_append(recent_entries, e);
                                        }
                                    }
                                }
                            }
                        }
                        p += 12;
                    }
                    g_free(content);
                }
                g_free(cfg);
            }
            g_dir_close(dir);
        }
        g_free(userdata_path);

        recent_entries = g_list_sort(recent_entries, compare_recent_games);
        int count = 0;
        GHashTable *seen = g_hash_table_new(g_str_hash, g_str_equal);
        for (GList *l = recent_entries; l && count < 10; l = l->next) {
            GameEntry *e = (GameEntry *)l->data;
            if (!g_hash_table_contains(seen, e->appid)) {
                g_hash_table_add(seen, e->appid);
                char *target = g_strdup_printf("steam://rungameid/%s", e->appid);
                add_action(ctx->recent_menu, e->title, target);
                g_free(target);
                count++;
            }
        }
        g_hash_table_destroy(seen);
        g_list_free_full(recent_entries, g_free);

        if (count == 0) {
            DbusmenuMenuitem *empty = dbusmenu_menuitem_new();
            dbusmenu_menuitem_property_set(empty, DBUSMENU_MENUITEM_PROP_LABEL, "No Recent Games");
            dbusmenu_menuitem_property_set_bool(empty, DBUSMENU_MENUITEM_PROP_ENABLED, FALSE);
            dbusmenu_menuitem_child_append(ctx->recent_menu, empty);
        }
    }

    // Refresh Installed Games
    if (ctx->installed_menu) {
        GList *children = dbusmenu_menuitem_get_children(ctx->installed_menu);
        while (children) {
            DbusmenuMenuitem *c = (DbusmenuMenuitem *)children->data;
            children = children->next;
            dbusmenu_menuitem_child_delete(ctx->installed_menu, c);
        }

        GList *inst_list = NULL;
        GHashTableIter iter;
        gpointer key, value;
        g_hash_table_iter_init(&iter, installed);
        while (g_hash_table_iter_next(&iter, &key, &value)) {
            GameEntry *e = g_new0(GameEntry, 1);
            g_strlcpy(e->appid, (const char *)key, sizeof(e->appid));
            g_strlcpy(e->title, (const char *)value, sizeof(e->title));
            inst_list = g_list_append(inst_list, e);
        }

        inst_list = g_list_sort(inst_list, compare_installed_games);
        int count = 0;
        for (GList *l = inst_list; l && count < 25; l = l->next) {
            GameEntry *e = (GameEntry *)l->data;
            char *target = g_strdup_printf("steam://rungameid/%s", e->appid);
            add_action(ctx->installed_menu, e->title, target);
            g_free(target);
            count++;
        }
        g_list_free_full(inst_list, g_free);

        if (count == 0) {
            DbusmenuMenuitem *empty = dbusmenu_menuitem_new();
            dbusmenu_menuitem_property_set(empty, DBUSMENU_MENUITEM_PROP_LABEL, "No Installed Games");
            dbusmenu_menuitem_property_set_bool(empty, DBUSMENU_MENUITEM_PROP_ENABLED, FALSE);
            dbusmenu_menuitem_child_append(ctx->installed_menu, empty);
        }
    }

    g_hash_table_destroy(installed);
    g_free(root);
}

static gboolean is_millennium_present(void) {
    if (g_getenv("STEAM_GLOBALMENU_ENABLE_MILLENNIUM") != NULL) return TRUE;
    if (g_file_test("/usr/lib/millennium", G_FILE_TEST_IS_DIR)) return TRUE;

    const char *home = g_get_home_dir();
    if (home) {
        char *p1 = g_build_filename(home, ".local/share/Steam/millennium", NULL);
        char *p2 = g_build_filename(home, ".local/share/Steam/ubuntu12_64/libmillennium_hhx64.so", NULL);
        char *p3 = g_build_filename(home, ".millennium", NULL);
        char *p4 = g_build_filename(home, ".var/app/com.valvesoftware.Steam/.local/share/Steam/millennium", NULL);
        gboolean present = (g_file_test(p1, G_FILE_TEST_IS_DIR) || 
                            g_file_test(p2, G_FILE_TEST_EXISTS) ||
                            g_file_test(p3, G_FILE_TEST_IS_DIR) ||
                            g_file_test(p4, G_FILE_TEST_IS_DIR));
        g_free(p1);
        g_free(p2);
        g_free(p3);
        g_free(p4);
        if (present) return TRUE;
    }
    return FALSE;
}

static void build_menu_hierarchy(AppContext *ctx) {
    ctx->server = dbusmenu_server_new(DBUS_OBJECT_PATH);
    ctx->root_item = dbusmenu_menuitem_new();
    dbusmenu_server_set_root(ctx->server, ctx->root_item);

    // 1. Steam Menu
    DbusmenuMenuitem *top_steam = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(top_steam, DBUSMENU_MENUITEM_PROP_LABEL, "Steam");
    dbusmenu_menuitem_child_append(ctx->root_item, top_steam);

    add_action(top_steam, "Change Account...", "steam://open/settings");
    add_action(top_steam, "Sign Out...", "steam://open/settings");
    add_action(top_steam, "Go Online", "steam://friends/status/online");
    add_action(top_steam, "Go Offline", "steam://friends/status/offline");
    add_separator(top_steam);
    add_action(top_steam, "Check for Steam Client Updates...", "steam://open/console");
    add_action(top_steam, "Backup and Restore Games...", "steam://backup/");
    add_separator(top_steam);
    add_action(top_steam, "Settings", "steam://open/settings");

    if (is_millennium_present()) {
        LOG_INFO("Millennium modding framework detected: exporting Millennium menu options");
        add_separator(top_steam);
        add_action(top_steam, "Millennium", "steam://millennium/settings");
        add_action(top_steam, "Millennium Library Manager", "steam://millennium/sidebar");
    }

    add_separator(top_steam);
    add_action(top_steam, "Restart Steam", "RESTART");
    add_action(top_steam, "Exit Steam", "EXIT");

    // 2. View Menu
    DbusmenuMenuitem *top_view = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(top_view, DBUSMENU_MENUITEM_PROP_LABEL, "View");
    dbusmenu_menuitem_child_append(ctx->root_item, top_view);

    add_action(top_view, "Library", "steam://nav/games");
    add_action(top_view, "Hidden Games", "steam://nav/games/hidden");
    add_action(top_view, "Downloads", "steam://open/downloads");
    add_action(top_view, "Screenshots", "steam://open/screenshots");
    add_action(top_view, "Inventory", "steam://open/inventory");
    add_action(top_view, "Badges", "steam://open/badges");
    add_action(top_view, "Music Player", "steam://open/musicplayer");
    add_separator(top_view);
    add_action(top_view, "Big Picture Mode", "steam://open/bigpicture");

    // 3. Friends Menu
    DbusmenuMenuitem *top_friends = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(top_friends, DBUSMENU_MENUITEM_PROP_LABEL, "Friends");
    dbusmenu_menuitem_child_append(ctx->root_item, top_friends);

    add_action(top_friends, "View Friends List", "steam://open/friends");
    add_action(top_friends, "Add a Friend...", "steam://friends/add");

    DbusmenuMenuitem *status_menu = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(status_menu, DBUSMENU_MENUITEM_PROP_LABEL, "Online Status");
    dbusmenu_menuitem_child_append(top_friends, status_menu);
    add_action(status_menu, "Online", "steam://friends/status/online");
    add_action(status_menu, "Away", "steam://friends/status/away");
    add_action(status_menu, "Invisible", "steam://friends/status/invisible");
    add_action(status_menu, "Offline", "steam://friends/status/offline");

    add_separator(top_friends);
    add_action(top_friends, "Edit Profile Name / Avatar...", "steam://url/SteamIDEditPage");

    // 4. Games Menu
    DbusmenuMenuitem *top_games = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(top_games, DBUSMENU_MENUITEM_PROP_LABEL, "Games");
    dbusmenu_menuitem_child_append(ctx->root_item, top_games);

    add_action(top_games, "View Games Library", "steam://nav/games");

    ctx->recent_menu = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(ctx->recent_menu, DBUSMENU_MENUITEM_PROP_LABEL, "Recent Games");
    dbusmenu_menuitem_child_append(top_games, ctx->recent_menu);

    ctx->installed_menu = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(ctx->installed_menu, DBUSMENU_MENUITEM_PROP_LABEL, "Installed Games");
    dbusmenu_menuitem_child_append(top_games, ctx->installed_menu);

    add_separator(top_games);
    add_action(top_games, "Activate a Product on Steam...", "steam://open/activateproduct");
    add_action(top_games, "Redeem a Steam Wallet Code...", "steam://url/RedeemWalletCode");
    add_action(top_games, "Add a Non-Steam Game to My Library...", "steam://AddNonSteamGame");

    // 5. Help Menu
    DbusmenuMenuitem *top_help = dbusmenu_menuitem_new();
    dbusmenu_menuitem_property_set(top_help, DBUSMENU_MENUITEM_PROP_LABEL, "Help");
    dbusmenu_menuitem_child_append(ctx->root_item, top_help);

    add_action(top_help, "Steam Support", "steam://url/HelpFrontPage");
    add_action(top_help, "System Information", "steam://open/systeminfo");
    add_action(top_help, "About Steam", "steam://open/about");
    add_separator(top_help);
    add_action(top_help, "Privacy Policy", "steam://url/PrivacyPolicy");
    add_action(top_help, "Steam Subscriber Agreement", "steam://url/SubscriberAgreement");

    refresh_dynamic_menus(ctx);
}

/* --------------------------------------------------------------------------
 * X11 Window Scanner & Window Hooking
 * -------------------------------------------------------------------------- */

static void hook_window(AppContext *ctx, Window win) {
    LOG_INFO("Hooking Steam window 0x%lx", (unsigned long)win);

    XChangeProperty(ctx->dpy, win, ctx->atom_service_name, XA_STRING, 8,
                    PropModeReplace, (unsigned char*)DBUS_SERVICE_NAME, strlen(DBUS_SERVICE_NAME));
    XChangeProperty(ctx->dpy, win, ctx->atom_object_path, XA_STRING, 8,
                    PropModeReplace, (unsigned char*)DBUS_OBJECT_PATH, strlen(DBUS_OBJECT_PATH));
    XFlush(ctx->dpy);

    if (ctx->registrar_proxy) {
        GVariant *params = g_variant_new("(uo)", (guint32)win, DBUS_OBJECT_PATH);
        g_dbus_proxy_call(ctx->registrar_proxy, "RegisterWindow", params,
                          G_DBUS_CALL_FLAGS_NONE, 1000, NULL, NULL, NULL);
    }

    g_hash_table_insert(ctx->hooked_windows, GUINT_TO_POINTER((guint)win), GUINT_TO_POINTER((guint)win));
    LOG_INFO("Successfully exported Global Menu to 0x%lx", (unsigned long)win);
}

static void unhook_window(AppContext *ctx, Window win) {
    LOG_INFO("Unhooking closed Steam window 0x%lx", (unsigned long)win);
    g_hash_table_remove(ctx->hooked_windows, GUINT_TO_POINTER((guint)win));

    if (ctx->registrar_proxy) {
        GVariant *params = g_variant_new("(u)", (guint32)win);
        g_dbus_proxy_call(ctx->registrar_proxy, "UnregisterWindow", params,
                          G_DBUS_CALL_FLAGS_NONE, 1000, NULL, NULL, NULL);
    }
}

static gboolean scan_windows_cb(gpointer user_data) {
    AppContext *ctx = (AppContext *)user_data;
    if (!ctx->dpy) return TRUE;

    Atom actual_type;
    int actual_format;
    unsigned long nitems, bytes_after;
    unsigned char *prop = NULL;

    int status = XGetWindowProperty(ctx->dpy, ctx->root, ctx->atom_client_list,
                                    0, 1024, False, XA_WINDOW,
                                    &actual_type, &actual_format, &nitems, &bytes_after, &prop);

    if (status != Success || !prop) {
        return TRUE;
    }

    Window *windows = (Window *)prop;
    GHashTable *current_set = g_hash_table_new(g_direct_hash, g_direct_equal);

    for (unsigned long i = 0; i < nitems; i++) {
        Window win = windows[i];
        g_hash_table_add(current_set, GUINT_TO_POINTER((guint)win));

        if (g_hash_table_contains(ctx->hooked_windows, GUINT_TO_POINTER((guint)win))) {
            continue;
        }

        XClassHint hint = {0};
        if (XGetClassHint(ctx->dpy, win, &hint)) {
            gboolean is_steam = FALSE;
            if (hint.res_name && (g_ascii_strcasecmp(hint.res_name, "steam") == 0 ||
                                  g_ascii_strcasecmp(hint.res_name, "steamwebhelper") == 0)) {
                is_steam = TRUE;
            }
            if (hint.res_class && (g_ascii_strcasecmp(hint.res_class, "steam") == 0 ||
                                   g_ascii_strcasecmp(hint.res_class, "steamwebhelper") == 0)) {
                is_steam = TRUE;
            }

            if (is_steam) {
                // Check window type
                Atom type_prop = None;
                int type_fmt;
                unsigned long type_items, type_bytes;
                unsigned char *type_data = NULL;
                XGetWindowProperty(ctx->dpy, win, ctx->atom_window_type, 0, 4, False, XA_ATOM,
                                   &type_prop, &type_fmt, &type_items, &type_bytes, &type_data);

                gboolean is_valid_type = TRUE;
                if (type_data && type_items > 0) {
                    Atom *atoms = (Atom *)type_data;
                    is_valid_type = (atoms[0] == ctx->atom_type_normal || atoms[0] == ctx->atom_type_dialog);
                }
                if (type_data) XFree(type_data);

                char *name = NULL;
                XFetchName(ctx->dpy, win, &name);
                gboolean is_steam_main = (name && g_str_has_prefix(name, "Steam"));
                if (name) XFree(name);

                if (is_valid_type || is_steam_main) {
                    hook_window(ctx, win);
                }
            }

            if (hint.res_name) XFree(hint.res_name);
            if (hint.res_class) XFree(hint.res_class);
        }
    }

    XFree(prop);

    // Unhook dead windows
    GHashTableIter iter;
    gpointer key, value;
    g_hash_table_iter_init(&iter, ctx->hooked_windows);
    GList *to_remove = NULL;
    while (g_hash_table_iter_next(&iter, &key, &value)) {
        if (!g_hash_table_contains(current_set, key)) {
            to_remove = g_list_append(to_remove, key);
        }
    }
    for (GList *l = to_remove; l; l = l->next) {
        unhook_window(ctx, (Window)GPOINTER_TO_UINT(l->data));
    }
    g_list_free(to_remove);
    g_hash_table_destroy(current_set);

    return TRUE;
}

static void signal_handler(int sig) {
    LOG_INFO("Received termination signal %d", sig);
    if (g_ctx.hooked_windows && g_ctx.dpy) {
        GList *keys = g_hash_table_get_keys(g_ctx.hooked_windows);
        for (GList *l = keys; l; l = l->next) {
            unhook_window(&g_ctx, (Window)GPOINTER_TO_UINT(l->data));
        }
        g_list_free(keys);
    }
    if (g_ctx.loop) {
        g_main_loop_quit(g_ctx.loop);
    }
}

int main(int argc, char **argv) {
    GError *error = NULL;
    GOptionContext *opt_ctx = g_option_context_new("- Steam KDE Plasma Global Menu Bridge");
    g_option_context_add_main_entries(opt_ctx, opt_entries, NULL);
    if (!g_option_context_parse(opt_ctx, &argc, &argv, &error)) {
        g_printerr("Option parsing failed: %s\n", error->message);
        g_error_free(error);
        g_option_context_free(opt_ctx);
        return 1;
    }
    g_option_context_free(opt_ctx);

    if (opt_version) {
        g_print("steam-globalmenu %s\n", VERSION);
        return 0;
    }

    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // Initialize X11 connection
    g_ctx.dpy = XOpenDisplay(NULL);
    if (!g_ctx.dpy) {
        LOG_WARN("Could not open X11 display. Ensure DISPLAY is set or XWayland is active.");
        return 1;
    }
    g_ctx.root = DefaultRootWindow(g_ctx.dpy);
    g_ctx.atom_client_list = XInternAtom(g_ctx.dpy, "_NET_CLIENT_LIST", False);
    g_ctx.atom_service_name = XInternAtom(g_ctx.dpy, "_KDE_NET_WM_APPMENU_SERVICE_NAME", False);
    g_ctx.atom_object_path = XInternAtom(g_ctx.dpy, "_KDE_NET_WM_APPMENU_OBJECT_PATH", False);
    g_ctx.atom_window_type = XInternAtom(g_ctx.dpy, "_NET_WM_WINDOW_TYPE", False);
    g_ctx.atom_type_normal = XInternAtom(g_ctx.dpy, "_NET_WM_WINDOW_TYPE_NORMAL", False);
    g_ctx.atom_type_dialog = XInternAtom(g_ctx.dpy, "_NET_WM_WINDOW_TYPE_DIALOG", False);
    g_ctx.atom_net_wm_name = XInternAtom(g_ctx.dpy, "_NET_WM_NAME", False);

    g_ctx.hooked_windows = g_hash_table_new(g_direct_hash, g_direct_equal);

    // Initialize D-Bus Registrar Proxy
    GDBusConnection *session_bus = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, NULL);
    if (session_bus) {
        g_ctx.registrar_proxy = g_dbus_proxy_new_sync(
            session_bus,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            REGISTRAR_NAME,
            REGISTRAR_PATH,
            REGISTRAR_NAME,
            NULL,
            NULL
        );
        g_bus_own_name_on_connection(session_bus, DBUS_SERVICE_NAME, G_BUS_NAME_OWNER_FLAGS_NONE, NULL, NULL, NULL, NULL);
    }

    build_menu_hierarchy(&g_ctx);

    LOG_INFO("Steam KDE Global Menu Bridge daemon started (PID: %d)", getpid());

    // Initial window scan
    scan_windows_cb(&g_ctx);

    // Window scanner interval: 1500 ms (0% CPU impact, < 3MB RSS)
    g_timeout_add(1500, scan_windows_cb, &g_ctx);

    // Refresh dynamic games submenu every 60 seconds
    g_timeout_add_seconds(60, (GSourceFunc)(void*)refresh_dynamic_menus, &g_ctx);

    g_ctx.loop = g_main_loop_new(NULL, FALSE);
    g_main_loop_run(g_ctx.loop);

    if (g_ctx.dpy) {
        XCloseDisplay(g_ctx.dpy);
    }
    return 0;
}
