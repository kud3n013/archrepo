#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>

static void load_env_file(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return;
    char line[1024];
    while (fgets(line, sizeof(line), f)) {
        char *p = line;
        while (isspace((unsigned char)*p)) p++;
        if (*p == '#' || *p == '\0') continue;
        char *end = p + strlen(p) - 1;
        while (end > p && isspace((unsigned char)*end)) *end-- = '\0';
        char *eq = strchr(p, '=');
        if (eq) {
            *eq = '\0';
            setenv(p, eq + 1, 0);
        }
    }
    fclose(f);
}

__attribute__((constructor))
static void fdm_init_environment(void) {
    // Disable AppImage runtime desktop integration if any
    setenv("DESKTOPINTEGRATION", "0", 1);

    // Read user configuration if present, fallback to system configuration
    const char *xdg_config = getenv("XDG_CONFIG_HOME");
    char user_conf[1024];
    if (xdg_config && *xdg_config) {
        snprintf(user_conf, sizeof(user_conf), "%s/freedownloadmanager-flags.conf", xdg_config);
    } else {
        const char *home = getenv("HOME");
        if (home) {
            snprintf(user_conf, sizeof(user_conf), "%s/.config/freedownloadmanager-flags.conf", home);
        } else {
            user_conf[0] = '\0';
        }
    }

    if (user_conf[0] && access(user_conf, R_OK) == 0) {
        load_env_file(user_conf);
    } else {
        load_env_file("/etc/freedownloadmanager-flags.conf");
    }

    // Default Wayland flags if running under Wayland and not explicitly specified
    if (getenv("WAYLAND_DISPLAY") && !getenv("QT_QPA_PLATFORM")) {
        setenv("QT_QPA_PLATFORM", "wayland;xcb", 1);
    }

    // Free Download Manager bundles a private Qt6 runtime with only 'libqxdgdesktopportal.so'
    // and 'libqgtk3.so' in /opt/freedownloadmanager/plugins/platformthemes.
    // Desktop sessions frequently export QT_QPA_PLATFORMTHEME=kde, qt5ct, or qt6ct, which are missing
    // from FDM's bundle. When an unsupported theme is specified, Qt fails to load any platform theme plugin,
    // breaking FreeDesktop portal integration and causing dark mode detection to fail (always showing light theme).
    // Fallback to xdgdesktopportal if QT_QPA_PLATFORMTHEME is unset or not one of the bundled plugins.
    const char *theme = getenv("QT_QPA_PLATFORMTHEME");
    if (!theme || (strcmp(theme, "xdgdesktopportal") != 0 && strcmp(theme, "gtk3") != 0)) {
        setenv("QT_QPA_PLATFORMTHEME", "xdgdesktopportal", 1);
    }
}
