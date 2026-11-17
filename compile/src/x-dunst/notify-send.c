/* Minimal GDBus notify-send (static build, no libnotify).
 * Sends org.freedesktop.Notifications.Notify directly via GDBus (gio).
 * Why not libnotify: 0.8.9 hard-requires gio-unix-2.0.a which is absent from
 * the static stack (no glib source to build it); a direct GDBus call needs
 * only gio+glib (proven linkable) and avoids libnotify + gdk-pixbuf + gio-unix.
 *
 * Usage: notify-send [OPTIONS] SUMMARY [BODY]
 *   -a, --app-name=NAME   app name (default "notify-send")
 *   -i, --icon=ICON       app icon (name or path)
 *   -t, --expire-time=MS  timeout in ms (default 5000; 0 = default; <0 = never)
 *   -u, --urgency=LEVEL   low|normal|critical (hint)
 *   -h, --help
 *
 * Note: dbus-send (dbus CLI) cannot send this call — its type parser has no
 * "variant", so it can't express the a{sv} hints. GDBus builds a{sv} natively.
 */
#include <gio/gio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <libgen.h>

static const char *app_name = "notify-send";
static const char *icon = "";
static int timeout = 5000;
static int urgency = -1; /* -1 = unset */

static void usage(const char *argv0) {
    fprintf(stderr,
        "Usage: %s [OPTIONS] SUMMARY [BODY]\n"
        "  -a, --app-name=NAME     app name (default %s)\n"
        "  -i, --icon=ICON         app icon (name or path)\n"
        "  -t, --expire-time=MS    timeout in ms (default 5000; 0=default; <0=never)\n"
        "  -u, --urgency=LEVEL     low|normal|critical\n"
        "  -h, --help\n", argv0, app_name);
}

int main(int argc, char **argv) {
    const char *summary = NULL, *body = "";
    int i;

    for (i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (!strcmp(a, "-h") || !strcmp(a, "--help")) { usage(argv[0]); return 0; }
        else if (!strncmp(a, "-a", 2) && a[2]) app_name = a + 2;
        else if (!strcmp(a, "-a") || !strcmp(a, "--app-name")) {
            if (++i >= argc) { usage(argv[0]); return 2; } app_name = argv[i];
        }
        else if (!strncmp(a, "--app-name=", 11)) app_name = a + 11;
        else if (!strncmp(a, "-i", 2) && a[2]) icon = a + 2;
        else if (!strcmp(a, "-i") || !strcmp(a, "--icon")) {
            if (++i >= argc) { usage(argv[0]); return 2; } icon = argv[i];
        }
        else if (!strncmp(a, "--icon=", 7)) icon = a + 7;
        else if (!strncmp(a, "-t", 2) && a[2]) timeout = atoi(a + 2);
        else if (!strcmp(a, "-t") || !strcmp(a, "--expire-time")) {
            if (++i >= argc) { usage(argv[0]); return 2; } timeout = atoi(argv[i]);
        }
        else if (!strncmp(a, "--expire-time=", 14)) timeout = atoi(a + 14);
        else if (!strncmp(a, "-u", 2) && a[2]) {
            if (!strcmp(a + 2, "low")) urgency = 0;
            else if (!strcmp(a + 2, "normal")) urgency = 1;
            else if (!strcmp(a + 2, "critical")) urgency = 2;
        }
        else if (!strcmp(a, "-u") || !strcmp(a, "--urgency")) {
            if (++i >= argc) { usage(argv[0]); return 2; }
            if (!strcmp(argv[i], "low")) urgency = 0;
            else if (!strcmp(argv[i], "normal")) urgency = 1;
            else if (!strcmp(argv[i], "critical")) urgency = 2;
            else { fprintf(stderr, "Invalid urgency: %s\n", argv[i]); return 2; }
        }
        else if (!strncmp(a, "--urgency=", 10)) {
            const char *u = a + 10;
            if (!strcmp(u, "low")) urgency = 0;
            else if (!strcmp(u, "normal")) urgency = 1;
            else if (!strcmp(u, "critical")) urgency = 2;
            else { fprintf(stderr, "Invalid urgency: %s\n", u); return 2; }
        }
        else if (a[0] == '-') { fprintf(stderr, "Unknown option: %s\n", a); usage(argv[0]); return 2; }
        else if (!summary) summary = a;
        else if (!*body) body = a;
        else { /* extra positional args ignored */ }
    }

    if (!summary) { usage(argv[0]); return 2; }

    GDBusConnection *conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, NULL);
    if (!conn) {
        fprintf(stderr, "Cannot connect to session bus (is DBUS_SESSION_BUS_ADDRESS set?)\n");
        return 1;
    }

    GVariantBuilder params_b;
    g_variant_builder_init(&params_b, G_VARIANT_TYPE("(susssasa{sv}i)"));
    g_variant_builder_add(&params_b, "s", app_name);
    g_variant_builder_add(&params_b, "u", (guint32)0);
    g_variant_builder_add(&params_b, "s", icon);
    g_variant_builder_add(&params_b, "s", summary);
    g_variant_builder_add(&params_b, "s", body);

    /* as (actions) — empty */
    GVariantBuilder actions;
    g_variant_builder_init(&actions, G_VARIANT_TYPE("as"));
    g_variant_builder_add(&params_b, "@as", g_variant_builder_end(&actions));

    /* a{sv} (hints) — empty or urgency */
    GVariantBuilder hints;
    g_variant_builder_init(&hints, G_VARIANT_TYPE("a{sv}"));
    if (urgency >= 0)
        g_variant_builder_add(&hints, "{sv}", "urgency", g_variant_new_int32(urgency));
    g_variant_builder_add(&params_b, "@a{sv}", g_variant_builder_end(&hints));

    g_variant_builder_add(&params_b, "i", (gint32)timeout);
    GVariant *params = g_variant_builder_end(&params_b);

    GError *err = NULL;
    GVariant *reply = g_dbus_connection_call_sync(conn,
        "org.freedesktop.Notifications",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications",
        "Notify",
        params,
        G_VARIANT_TYPE("(u)"),
        G_DBUS_CALL_FLAGS_NONE,
        -1, NULL, &err);
    /* params floating ref was sunk by call_sync — do NOT unref */

    if (err) {
        fprintf(stderr, "Notify failed: %s\n", err->message);
        g_error_free(err);
        g_object_unref(conn);
        return 1;
    }
    if (reply) {
        guint32 id = 0;
        g_variant_get(reply, "(u)", &id);
        printf("%u\n", id);
        g_variant_unref(reply);
    }
    g_object_unref(conn);
    return 0;
}
