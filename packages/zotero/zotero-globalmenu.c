/*
 * libzotero-globalmenu.so
 *
 * Architecture & Purpose:
 * When Gecko (NativeMenuGtk) exports menu item accelerators to DBusMenu
 * (com.canonical.dbusmenu), it converts GDK keyval 44 (GDK_KEY_comma) into the
 * string name "comma" via gdk_keyval_name() -> shortcut: [["Control", "comma"]].
 *
 * KDE Plasma's Global Menu widget (plasma-workspace applets/appmenu) reads the
 * DBusMenu shortcut, replaces "Control" -> "Ctrl", joins with "+" -> "Ctrl+comma",
 * and calls Qt's QKeySequence::fromString("Ctrl+comma").
 * Because Qt only recognizes the literal character ',' (not the word "comma"),
 * QKeySequence evaluates to Key_unknown (empty string) and KDE Plasma fails to display
 * the shortcut on the right side of the menu item.
 *
 * This shim intercepts DBusMenu shortcut exports and translates punctuation key names
 * ("comma" -> ",", "period" -> ".", etc.) so QKeySequence::fromString parses them
 * properly, restoring the "Ctrl+," shortcut tip in KDE Plasma's Global Menu.
 */

#define _GNU_SOURCE
#include <dlfcn.h>
#include <glib.h>
#include <string.h>

typedef void DbusmenuMenuitem;
typedef gboolean (*orig_set_variant_t)(DbusmenuMenuitem*, const gchar*, GVariant*);
typedef gboolean (*orig_set_shortcut_t)(DbusmenuMenuitem*, guint, guint);

static void* (*orig_dlsym)(void*, const char*) = NULL;
static orig_set_variant_t real_set_variant = NULL;
static orig_set_shortcut_t real_set_shortcut = NULL;

static void init_orig(void) {
    if (!orig_dlsym) {
        orig_dlsym = (void* (*)(void*, const char*))dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.2.5");
        if (!orig_dlsym) {
            orig_dlsym = (void* (*)(void*, const char*))dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.34");
        }
    }
    if (!real_set_variant && orig_dlsym) {
        real_set_variant = (orig_set_variant_t)orig_dlsym(RTLD_NEXT, "dbusmenu_menuitem_property_set_variant");
        if (!real_set_variant) {
            void* h = dlopen("libdbusmenu-glib.so.4", RTLD_LAZY);
            if (h) real_set_variant = (orig_set_variant_t)orig_dlsym(h, "dbusmenu_menuitem_property_set_variant");
        }
    }
    if (!real_set_shortcut && orig_dlsym) {
        real_set_shortcut = (orig_set_shortcut_t)orig_dlsym(RTLD_NEXT, "dbusmenu_menuitem_property_set_shortcut");
        if (!real_set_shortcut) {
            void* h = dlopen("libdbusmenu-gtk3.so.4", RTLD_LAZY);
            if (h) real_set_shortcut = (orig_set_shortcut_t)orig_dlsym(h, "dbusmenu_menuitem_property_set_shortcut");
        }
    }
}

// Convert "comma" -> "," in shortcut GVariant so Qt/KDE Plasma can parse it with QKeySequence
static GVariant* fix_shortcut_variant(GVariant* value) {
    if (!value) return NULL;
    if (!g_variant_is_of_type(value, G_VARIANT_TYPE("aas"))) {
        return value;
    }

    gboolean modified = FALSE;
    GVariantBuilder outer;
    g_variant_builder_init(&outer, G_VARIANT_TYPE("aas"));

    GVariantIter outer_iter;
    g_variant_iter_init(&outer_iter, value);
    GVariant* inner_val = NULL;

    while ((inner_val = g_variant_iter_next_value(&outer_iter)) != NULL) {
        GVariantBuilder inner;
        g_variant_builder_init(&inner, G_VARIANT_TYPE("as"));

        GVariantIter inner_iter;
        g_variant_iter_init(&inner_iter, inner_val);
        const gchar* str = NULL;

        while (g_variant_iter_next(&inner_iter, "&s", &str)) {
            // Qt QKeySequence::fromString() only recognizes literal ASCII punctuation characters,
            // not X11/GDK key names like "comma", "period", "semicolon", "slash", etc.
            if (g_strcmp0(str, "comma") == 0) {
                g_variant_builder_add(&inner, "s", ",");
                modified = TRUE;
            } else if (g_strcmp0(str, "period") == 0) {
                g_variant_builder_add(&inner, "s", ".");
                modified = TRUE;
            } else if (g_strcmp0(str, "semicolon") == 0) {
                g_variant_builder_add(&inner, "s", ";");
                modified = TRUE;
            } else if (g_strcmp0(str, "slash") == 0) {
                g_variant_builder_add(&inner, "s", "/");
                modified = TRUE;
            } else if (g_strcmp0(str, "minus") == 0) {
                g_variant_builder_add(&inner, "s", "-");
                modified = TRUE;
            } else if (g_strcmp0(str, "plus") == 0) {
                g_variant_builder_add(&inner, "s", "+");
                modified = TRUE;
            } else if (g_strcmp0(str, "equal") == 0) {
                g_variant_builder_add(&inner, "s", "=");
                modified = TRUE;
            } else if (g_strcmp0(str, "bracketleft") == 0) {
                g_variant_builder_add(&inner, "s", "[");
                modified = TRUE;
            } else if (g_strcmp0(str, "bracketright") == 0) {
                g_variant_builder_add(&inner, "s", "]");
                modified = TRUE;
            } else if (g_strcmp0(str, "backslash") == 0) {
                g_variant_builder_add(&inner, "s", "\\");
                modified = TRUE;
            } else if (g_strcmp0(str, "grave") == 0) {
                g_variant_builder_add(&inner, "s", "`");
                modified = TRUE;
            } else if (g_strcmp0(str, "apostrophe") == 0) {
                g_variant_builder_add(&inner, "s", "'");
                modified = TRUE;
            } else {
                g_variant_builder_add(&inner, "s", str);
            }
        }
        g_variant_builder_add_value(&outer, g_variant_builder_end(&inner));
        g_variant_unref(inner_val);
    }

    if (modified) {
        return g_variant_builder_end(&outer);
    } else {
        g_variant_builder_clear(&outer);
        return value;
    }
}

gboolean dbusmenu_menuitem_property_set_variant(DbusmenuMenuitem* item, const gchar* property, GVariant* value) {
    init_orig();
    if (property && strcmp(property, "shortcut") == 0 && value) {
        value = fix_shortcut_variant(value);
    }
    if (real_set_variant) {
        return real_set_variant(item, property, value);
    }
    return FALSE;
}

gboolean dbusmenu_menuitem_property_set_shortcut(DbusmenuMenuitem* item, guint key, guint modifier) {
    init_orig();
    if (key == 44 /* comma */) {
        GVariantBuilder inner;
        g_variant_builder_init(&inner, G_VARIANT_TYPE("as"));
        if (modifier & 4) g_variant_builder_add(&inner, "s", "Control");
        if (modifier & 1) g_variant_builder_add(&inner, "s", "Shift");
        if (modifier & 8) g_variant_builder_add(&inner, "s", "Alt");
        if (modifier & 0x4000000) g_variant_builder_add(&inner, "s", "Super");
        g_variant_builder_add(&inner, "s", ",");

        GVariantBuilder outer;
        g_variant_builder_init(&outer, G_VARIANT_TYPE("aas"));
        g_variant_builder_add_value(&outer, g_variant_builder_end(&inner));

        return dbusmenu_menuitem_property_set_variant(item, "shortcut", g_variant_builder_end(&outer));
    }
    if (real_set_shortcut) {
        return real_set_shortcut(item, key, modifier);
    }
    return FALSE;
}

void* dlsym(void* handle, const char* symbol) {
    init_orig();
    if (symbol) {
        if (strcmp(symbol, "dbusmenu_menuitem_property_set_shortcut") == 0) {
            return (void*)dbusmenu_menuitem_property_set_shortcut;
        }
        if (strcmp(symbol, "dbusmenu_menuitem_property_set_variant") == 0) {
            return (void*)dbusmenu_menuitem_property_set_variant;
        }
    }

    if (orig_dlsym) {
        return orig_dlsym(handle, symbol);
    }
    return NULL;
}
