/* ibus-panel.c — 方案 B：独立 GTK2 panel（org.freedesktop.IBus.Panel）
 *
 * 复用 ibus-x11 main.c 的 _panel_* GTK2 渲染代码（候选窗 + aux 窗 + GtkStatusIcon
 * 托盘语言栏 + 引擎切换菜单），改为由 IBusPanelService 的 DBus 信号驱动。
 * 所有客户端（GTK_IM_MODULE=ibus 的系统/静态应用、Qt）经 daemon 把候选/preedit/
 * 属性转发到本 panel 显示。
 */
#include <gtk/gtk.h>
#include <ibus.h>
#include <stdlib.h>

typedef struct {
    GtkWidget        *cand_win;
    GtkWidget        *cand_vbox;
    GtkWidget        *preedit_label;
    GtkWidget        *cand_box;
    GtkWidget        *aux_win;
    GtkWidget        *aux_label;
    GtkStatusIcon    *status_icon;
    IBusBus          *bus;
    gint              cur_x;
    gint              cur_y;
    gint              cur_h;
    gchar            *aux_text;
    gchar            *prop_text;
    gchar            *preedit_text;
    IBusLookupTable  *current_table;
} Panel;

static Panel _panel;

/* rounded corner radius for candidate/aux popups (px); overridable via
 * PANEL_ROUND env at runtime. Final choice: 2px (matching Greybird roundness). */
#define PANEL_ROUND 2.0

static gboolean
_panel_expose_round (GtkWidget *win, GdkEventExpose *event, gpointer data)
{
    const gchar *bg = (const gchar *) data;
    GdkColor color;
    GtkAllocation alloc;
    cairo_t *cr;
    const char *rs = getenv ("PANEL_ROUND");
    double w, h, r = rs ? atof (rs) : PANEL_ROUND, pi = 3.141592653589793;

    if (!gdk_color_parse (bg, &color))
        return FALSE;

    gtk_widget_get_allocation (win, &alloc);
    w = alloc.width;
    h = alloc.height;
    cr = gdk_cairo_create (gtk_widget_get_window (win));
    cairo_new_path (cr);
    if (r > 0 && w >= 2 * r && h >= 2 * r) {
        cairo_arc (cr, w - r, r,     r, -pi / 2, 0);
        cairo_arc (cr, w - r, h - r, r, 0,        pi / 2);
        cairo_arc (cr, r,     h - r, r, pi / 2,   pi);
        cairo_arc (cr, r,     r,     r, pi,       3 * pi / 2);
    } else {
        cairo_rectangle (cr, 0, 0, w, h);
    }
    cairo_close_path (cr);
    cairo_set_source_rgba (cr, color.red / 65535.0, color.green / 65535.0,
                           color.blue / 65535.0, 1.0);
    cairo_fill (cr);
    cairo_destroy (cr);
    return FALSE;
}

static GtkWidget *
_panel_make_popup (const gchar *bg)
{
    GtkWidget *win = gtk_window_new (GTK_WINDOW_POPUP);
    GdkScreen *screen;
    GdkVisual *visual;
    GdkColor   color;
    gtk_window_set_skip_taskbar_hint (GTK_WINDOW (win), TRUE);
    gtk_window_set_skip_pager_hint (GTK_WINDOW (win), TRUE);
    /* Rounded translucent window: ARGB visual + custom cairo round background.
     * Requires a compositor (xcompmgr) on the X server; falls back to a plain
     * opaque bg if no RGBA visual is available. */
    screen = gtk_widget_get_screen (win);
    visual = gdk_screen_get_rgba_visual (screen);
    if (visual != NULL) {
        gtk_widget_set_visual (win, visual);
        gtk_widget_set_app_paintable (win, TRUE);
        g_signal_connect (win, "expose-event",
                          G_CALLBACK (_panel_expose_round), (gpointer) bg);
    } else if (bg != NULL && gdk_color_parse (bg, &color)) {
        gtk_widget_modify_bg (win, GTK_STATE_NORMAL, &color);
    }
    return win;
}

static void
_panel_clear_box (GtkWidget *box)
{
    GList *kids = gtk_container_get_children (GTK_CONTAINER (box));
    GList *l;
    for (l = kids; l != NULL; l = l->next)
        gtk_widget_destroy (GTK_WIDGET (l->data));
    g_list_free (kids);
}

static void
_panel_rebuild_candidates (IBusLookupTable *table, gboolean show_cursor)
{
    guint page_size, ncandidates, cursor, cursor_in_page;
    guint page_start, page_end, i;
    GtkWidget *box = _panel.cand_box;

    _panel_clear_box (box);
    if (table == NULL)
        return;

    page_size = ibus_lookup_table_get_page_size (table);
    if (page_size == 0)
        page_size = 1;
    ncandidates = ibus_lookup_table_get_number_of_candidates (table);
    cursor = ibus_lookup_table_get_cursor_pos (table);
    cursor_in_page = ibus_lookup_table_get_cursor_in_page (table);
    page_start = (cursor / page_size) * page_size;
    page_end = MIN (page_start + page_size, ncandidates);

    for (i = page_start; i < page_end; i++) {
        IBusText  *cand = ibus_lookup_table_get_candidate (table, i);
        const gchar *ctext = (cand != NULL) ? ibus_text_get_text (cand) : "";
        IBusText  *label = ibus_lookup_table_get_label (table, i - page_start);
        const gchar *ltext = (label != NULL) ? ibus_text_get_text (label) : NULL;
        GtkWidget *row;
        gchar     *str;

        if (ltext != NULL && *ltext != '\0')
            str = g_strdup_printf ("%s  %s", ltext, ctext);
        else
            str = g_strdup_printf ("%d.  %s", i - page_start + 1, ctext);
        row = gtk_label_new (str);
        g_free (str);
        gtk_misc_set_alignment (GTK_MISC (row), 0.0, 0.5);
        /* dark theme: default candidate text is light, selected row is blue bg + white */
        GdkColor def_fg;
        if (gdk_color_parse ("#eeeeec", &def_fg))
            gtk_widget_modify_fg (row, GTK_STATE_NORMAL, &def_fg);
        if (show_cursor && (i - page_start) == cursor_in_page) {
            /* GtkLabel does not paint its background, so wrap the selected
             * row in a GtkEventBox to draw the blue highlight. fill=TRUE
             * makes the highlight span the full row width. */
            GtkWidget *eb = gtk_event_box_new ();
            GdkColor bg;
            if (gdk_color_parse ("#398ee7", &bg))
                gtk_widget_modify_bg (eb, GTK_STATE_NORMAL, &bg);
            gtk_widget_modify_fg (row, GTK_STATE_NORMAL,
                                  &(GdkColor){ 0xffff, 0xffff, 0xffff });
            gtk_container_add (GTK_CONTAINER (eb), row);
            gtk_box_pack_start (GTK_BOX (box), eb, FALSE, TRUE, 0);
        } else {
            gtk_box_pack_start (GTK_BOX (box), row, FALSE, FALSE, 0);
        }
    }
    gtk_widget_show_all (box);
}

static void
_panel_render_preedit (void)
{
    if (_panel.preedit_text != NULL && *_panel.preedit_text != '\0') {
        gtk_label_set_text (GTK_LABEL (_panel.preedit_label), _panel.preedit_text);
        gtk_widget_show (_panel.preedit_label);
    } else {
        gtk_widget_hide (_panel.preedit_label);
    }
}

static void
_panel_show_candidates (IBusLookupTable *table, gboolean visible)
{
    g_printerr ("DBG show_candidates: visible=%d cand=%p ncand=%d winvis=%d\n", visible, table, table?ibus_lookup_table_get_number_of_candidates(table):-1, gtk_widget_get_visible(_panel.cand_win));
    if (!visible || table == NULL ||
        ibus_lookup_table_get_number_of_candidates (table) == 0) {
        g_printerr ("DBG show_candidates: HIDING cand_win\n");
        gtk_widget_hide (_panel.cand_win);
        return;
    }
    if (_panel.current_table != table) {
        if (_panel.current_table != NULL)
            g_object_unref (_panel.current_table);
        _panel.current_table = IBUS_LOOKUP_TABLE (g_object_ref (table));
    }
    _panel_rebuild_candidates (table, ibus_lookup_table_is_cursor_visible (table));
    _panel_render_preedit ();
    gtk_window_move (GTK_WINDOW (_panel.cand_win),
                     _panel.cur_x, _panel.cur_y + _panel.cur_h + 4);
    /* cand_vbox is the parent of preedit_label/cand_box; without showing it
     * the children never get drawn in GTK2. */
    gtk_widget_show (_panel.cand_vbox);
    gtk_widget_show (_panel.cand_win);
    gtk_window_present (GTK_WINDOW (_panel.cand_win));
}

static void
_panel_render_aux (void)
{
    gchar *full;

    if (_panel.aux_text == NULL || *_panel.aux_text == '\0') {
        gtk_widget_hide (_panel.aux_win);
        return;
    }
    if (_panel.prop_text != NULL && *_panel.prop_text != '\0')
        full = g_strdup_printf ("%s  %s", _panel.aux_text, _panel.prop_text);
    else
        full = g_strdup (_panel.aux_text);
    gtk_label_set_text (GTK_LABEL (_panel.aux_label), full);
    g_free (full);
    gtk_window_move (GTK_WINDOW (_panel.aux_win),
                     _panel.cur_x, _panel.cur_y + _panel.cur_h + 4);
    gtk_widget_show (_panel.aux_win);
    gtk_window_present (GTK_WINDOW (_panel.aux_win));
}

static void
_panel_switch_engine (GtkWidget *item, gpointer data)
{
    gchar *name = (gchar *) data;
    if (name != NULL) {
        ibus_bus_set_global_engine (_panel.bus, name);
        g_free (name);
    }
}

static void
_panel_status_popup (GtkStatusIcon *si,
                     guint          button,
                     guint          activate_time,
                     gpointer       user_data)
{
    GtkWidget *menu = gtk_menu_new ();
    GList     *engines = ibus_bus_list_engines (_panel.bus);
    g_printerr ("DBG status_popup: list_engines n=%d\n", engines ? g_list_length (engines) : 0);
    IBusEngineDesc *cur_desc = ibus_bus_get_global_engine (_panel.bus);
    /* 单引擎（rime 直拉）场景 daemon 未 set_global_engine → get_global_engine 为 NULL；
     * 主动 set_global_engine("rime") 建立全局引擎再重查，使菜单能显示当前引擎名。 */
    if (cur_desc == NULL) {
        g_printerr ("DBG status_popup: no global engine, set_global_engine(rime)\n");
        ibus_bus_set_global_engine (_panel.bus, "rime");
        gint i;
        for (i = 0; i < 10 && cur_desc == NULL; i++) {
            while (g_main_context_iteration (NULL, FALSE)) {}
            g_usleep (100 * 1000);
            cur_desc = ibus_bus_get_global_engine (_panel.bus);
        }
    }
    const gchar *cur = (cur_desc != NULL) ? ibus_engine_desc_get_name (cur_desc) : NULL;
    GList     *l;
    gboolean   have_item = FALSE;

    /* 引擎列表（对标 apt：列出输入法引擎可切换、勾选当前；过滤 xkb 键盘布局，
     * 避免菜单被 885 个键盘布局占满）。 */
    for (l = engines; l != NULL; l = l->next) {
        IBusEngineDesc *desc = IBUS_ENGINE_DESC (l->data);
        const gchar *ename = ibus_engine_desc_get_name (desc);
        const gchar *lname = ibus_engine_desc_get_longname (desc);
        GtkWidget *item;
        if (ename == NULL || g_str_has_prefix (ename, "xkb:"))
            continue;   /* 跳过键盘布局（非输入法引擎） */
        item = gtk_check_menu_item_new_with_label (
                   (lname != NULL && *lname != '\0') ? lname : ename);
        if (cur != NULL && g_strcmp0 (cur, ename) == 0)
            gtk_check_menu_item_set_active (GTK_CHECK_MENU_ITEM (item), TRUE);
        g_signal_connect_data (item, "activate",
                               G_CALLBACK (_panel_switch_engine),
                               g_strdup (ename), (GClosureNotify) g_free, 0);
        gtk_menu_shell_append (GTK_MENU_SHELL (menu), item);
        have_item = TRUE;
    }

    /* fallback：无可用输入法引擎 → 只读"当前引擎"（避免空菜单白条） */
    if (!have_item) {
        GtkWidget *item = gtk_menu_item_new_with_label (
                              cur != NULL ? cur : "当前引擎: 无");
        gtk_widget_set_sensitive (item, FALSE);
        gtk_menu_shell_append (GTK_MENU_SHELL (menu), item);
    }

    /* 分隔线 + 退出（对标 apt 菜单尾部的 Quit 项） */
    gtk_menu_shell_append (GTK_MENU_SHELL (menu),
                           gtk_separator_menu_item_new ());
    {
        GtkWidget *quit = gtk_menu_item_new_with_label ("退出");
        g_signal_connect_data (quit, "activate",
                               G_CALLBACK (gtk_main_quit), NULL, NULL, 0);
        gtk_menu_shell_append (GTK_MENU_SHELL (menu), quit);
    }

    g_list_free_full (engines, g_object_unref);
    if (cur_desc != NULL)
        g_object_unref (cur_desc);
    gtk_widget_show_all (menu);
    gtk_menu_popup (GTK_MENU (menu), NULL, NULL, NULL, NULL, button, activate_time);
}

static void
_panel_init (void)
{
    _panel.cand_win = _panel_make_popup ("#2d2e30");
    _panel.cand_vbox = gtk_vbox_new (FALSE, 0);
    gtk_container_set_border_width (GTK_CONTAINER (_panel.cand_vbox), 4);
    _panel.preedit_label = gtk_label_new (NULL);
    gtk_misc_set_alignment (GTK_MISC (_panel.preedit_label), 0.0, 0.5);
    gtk_widget_modify_fg (_panel.preedit_label, GTK_STATE_NORMAL,
                          &(GdkColor){ 0xeeee, 0xeeee, 0xeeec });
    gtk_box_pack_start (GTK_BOX (_panel.cand_vbox), _panel.preedit_label,
                        FALSE, FALSE, 0);
    _panel.cand_box = gtk_vbox_new (FALSE, 0);
    gtk_box_pack_start (GTK_BOX (_panel.cand_vbox), _panel.cand_box, FALSE, FALSE, 0);
    gtk_container_add (GTK_CONTAINER (_panel.cand_win), _panel.cand_vbox);

    _panel.aux_win = _panel_make_popup ("#1d1f1f");
    _panel.aux_label = gtk_label_new (NULL);
    gtk_misc_set_alignment (GTK_MISC (_panel.aux_label), 0.0, 0.5);
    gtk_misc_set_padding (GTK_MISC (_panel.aux_label), 4, 4);
    gtk_widget_modify_fg (_panel.aux_label, GTK_STATE_NORMAL,
                          &(GdkColor){ 0xeeee, 0xeeee, 0xeeec });
    gtk_container_add (GTK_CONTAINER (_panel.aux_win), _panel.aux_label);

    /* language bar (tint2 systray via XEmbed) */
    _panel.status_icon = gtk_status_icon_new ();
    gtk_status_icon_set_from_icon_name (_panel.status_icon, "input-keyboard");
    {
        const gchar *icon_paths[] = {
            "/usr/local/static/ibus-rime/share/ibus-rime/icons/rime.png",
            "/usr/share/ibus-rime/icons/rime.png",
            NULL
        };
        gint i;
        for (i = 0; icon_paths[i] != NULL; i++) {
            GdkPixbuf *pb = gdk_pixbuf_new_from_file (icon_paths[i], NULL);
            if (pb != NULL) {
                GdkPixbuf *sized = gdk_pixbuf_scale_simple (pb, 16, 16,
                                                           GDK_INTERP_BILINEAR);
                gtk_status_icon_set_from_pixbuf (_panel.status_icon, sized);
                if (sized != NULL) g_object_unref (sized);
                g_object_unref (pb);
                break;
            }
        }
    }
    gtk_status_icon_set_tooltip_text (_panel.status_icon, "IBus");
    g_signal_connect (_panel.status_icon, "popup-menu",
                      G_CALLBACK (_panel_status_popup), NULL);
    g_signal_connect (_panel.status_icon, "activate",
                      G_CALLBACK (_panel_status_popup), NULL);
}

/* ==== PanelService 信号回调（daemon → panel）==== */

static void
on_update_lookup_table (IBusPanelService *service,
                        IBusLookupTable  *table,
                        gboolean          visible)
{
    _panel_show_candidates (table, visible);
}

static void
on_show_lookup_table (IBusPanelService *service)
{
    _panel_show_candidates (_panel.current_table, TRUE);
}

static void
on_hide_lookup_table (IBusPanelService *service)
{
    g_printerr ("DBG HideLookupTable: cand_win=%p winvis=%d\n", _panel.cand_win, gtk_widget_get_visible(_panel.cand_win));
    gtk_widget_hide (_panel.cand_win);
}

static void
on_update_auxiliary_text (IBusPanelService *service,
                          IBusText         *text,
                          gboolean          visible)
{
    if (_panel.aux_text != NULL)
        g_free (_panel.aux_text);
    _panel.aux_text = g_strdup (text != NULL ? ibus_text_get_text (text) : "");
    if (visible)
        _panel_render_aux ();
    else
        gtk_widget_hide (_panel.aux_win);
}

static void
on_show_auxiliary_text (IBusPanelService *service)
{
    _panel_render_aux ();
}

static void
on_hide_auxiliary_text (IBusPanelService *service)
{
    gtk_widget_hide (_panel.aux_win);
}

static void
on_update_preedit_text (IBusPanelService *service,
                        IBusText         *text,
                        guint             cursor_pos,
                        gboolean          visible)
{
    if (_panel.preedit_text != NULL)
        g_free (_panel.preedit_text);
    _panel.preedit_text = g_strdup (text != NULL ? ibus_text_get_text (text) : "");
    if (visible && _panel.current_table != NULL) {
        _panel_render_preedit ();
        gtk_widget_show (_panel.cand_win);
    }
}

static void
on_show_preedit_text (IBusPanelService *service)
{
    _panel_render_preedit ();
}

static void
on_hide_preedit_text (IBusPanelService *service)
{
    gtk_widget_hide (_panel.preedit_label);
}

static void
on_set_cursor_location (IBusPanelService *service,
                        gint x, gint y, gint w, gint h)
{
    _panel.cur_x = x;
    _panel.cur_y = y;
    _panel.cur_h = h;
}

static void
on_update_property (IBusPanelService *service, IBusProperty *prop)
{
    /* 语言栏 tooltip 显示当前引擎/状态 */
    IBusText *text = ibus_property_get_label (prop);
    const gchar *label = (text != NULL) ? ibus_text_get_text (text) : NULL;
    if (label != NULL && *label != '\0')
        gtk_status_icon_set_tooltip_text (_panel.status_icon, label);
}

static void
on_focus_in (IBusPanelService *service, const gchar *input_context_path)
{
}

static void
on_focus_out (IBusPanelService *service, const gchar *input_context_path)
{
    g_printerr ("DBG FocusOut: hiding cand_win\n");
    gtk_widget_hide (_panel.cand_win);
    gtk_widget_hide (_panel.aux_win);
}

static void
on_destroy_context (IBusPanelService *service, const gchar *input_context_path)
{
    gtk_widget_hide (_panel.cand_win);
    gtk_widget_hide (_panel.aux_win);
}

static void
_connect_service (IBusPanelService *service)
{
    g_signal_connect (service, "update-lookup-table",
                      G_CALLBACK (on_update_lookup_table), NULL);
    g_signal_connect (service, "show-lookup-table",
                      G_CALLBACK (on_show_lookup_table), NULL);
    g_signal_connect (service, "hide-lookup-table",
                      G_CALLBACK (on_hide_lookup_table), NULL);
    g_signal_connect (service, "update-auxiliary-text",
                      G_CALLBACK (on_update_auxiliary_text), NULL);
    g_signal_connect (service, "show-auxiliary-text",
                      G_CALLBACK (on_show_auxiliary_text), NULL);
    g_signal_connect (service, "hide-auxiliary-text",
                      G_CALLBACK (on_hide_auxiliary_text), NULL);
    g_signal_connect (service, "update-preedit-text",
                      G_CALLBACK (on_update_preedit_text), NULL);
    g_signal_connect (service, "show-preedit-text",
                      G_CALLBACK (on_show_preedit_text), NULL);
    g_signal_connect (service, "hide-preedit-text",
                      G_CALLBACK (on_hide_preedit_text), NULL);
    g_signal_connect (service, "set-cursor-location",
                      G_CALLBACK (on_set_cursor_location), NULL);
    g_signal_connect (service, "update-property",
                      G_CALLBACK (on_update_property), NULL);
    g_signal_connect (service, "focus-in", G_CALLBACK (on_focus_in), NULL);
    g_signal_connect (service, "focus-out", G_CALLBACK (on_focus_out), NULL);
    g_signal_connect (service, "destroy-context",
                      G_CALLBACK (on_destroy_context), NULL);
}

int
main (int argc, char **argv)
{
    IBusBus          *bus;
    GDBusConnection  *conn;
    IBusPanelService *service;

    gtk_init (&argc, &argv);
    /* 注册 IBus 类型（IBusEngineDesc 等）→ get_global_engine 才能反序列化返回对象 */
    ibus_init ();

    bus = ibus_bus_new ();
    if (!ibus_bus_is_connected (bus)) {
        g_printerr ("ibus-panel: cannot connect to ibus-daemon (set IBUS_ADDRESS)\n");
        return 1;
    }
    _panel.bus = bus;
    conn = ibus_bus_get_connection (bus);

    service = ibus_panel_service_new (conn);
    _connect_service (service);
    g_object_unref (service);  /* service keeps itself via DBus registration */

    _panel_init ();

    /* register as the IBus panel service */
    ibus_bus_request_name (bus, IBUS_SERVICE_PANEL, 0);

    gtk_main ();
    return 0;
}
