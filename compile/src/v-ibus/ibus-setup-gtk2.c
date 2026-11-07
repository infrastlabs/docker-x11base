/* ibus-setup-gtk2.c — 方案 B/C：静态 GTK2 版 ibus-setup（引擎管理）
 *
 * 原版 ibus 1.5.35 的 ibus-setup 是 Python(GTK3)，无法静态打包。此处用
 * GTK2 + ibus C API 重写最小可用版，聚焦输入法引擎管理：
 *   - 列出已启用引擎（config general/preload_engines）
 *   - 从可用引擎添加 / 移除已启用引擎
 *   - 将选中引擎设为全局引擎（ibus_bus_set_global_engine）
 *
 * 运行：IBUS_ADDRESS 或 session bus 上有 ibus-daemon；GTK2 静态链。
 */
#include <gtk/gtk.h>
#include <ibus.h>
#include <string.h>

typedef struct {
    IBusBus   *bus;
    IBusConfig *config;
    GtkWidget *tree;
    GtkWidget *combo;
    GtkWidget *global_label;
    GtkListStore *store;   /* preload engine list: col0 name, col1 longname */
    GtkListStore *combo_store; /* available engines: col0 name, col1 longname */
} Setup;

static Setup S;

/* read config general/preload_engines -> newly-allocated gchar** (caller g_strfreev) */
static gchar **
_get_preload (gsize *n)
{
    GVariant *v;
    gchar **arr = NULL;
    *n = 0;
    if (S.config == NULL)
        return NULL;
    v = ibus_config_get_value (S.config, "general", "preload_engines");
    if (v == NULL || !g_variant_is_of_type (v, G_VARIANT_TYPE ("as"))) {
        if (v != NULL) g_variant_unref (v);
        return NULL;
    }
    arr = g_variant_get_strv (v, n);
    g_variant_unref (v);
    return arr;
}

static void
_set_preload (gchar **arr, gsize n)
{
    GVariant *v;
    if (S.config == NULL)
        return;
    v = g_variant_new_strv ((const gchar * const *) arr, n);
    ibus_config_set_value (S.config, "general", "preload_engines", v);
}

static void
_refresh_preload (void)
{
    gchar **arr;
    gsize n, i;
    gtk_list_store_clear (S.store);
    arr = _get_preload (&n);
    for (i = 0; arr != NULL && i < n; i++) {
        GtkTreeIter it;
        gtk_list_store_append (S.store, &it);
        gtk_list_store_set (S.store, &it, 0, arr[i], 1, arr[i], -1);
    }
    g_strfreev (arr);
}

static void
_refresh_global (void)
{
    IBusEngineDesc *desc;
    desc = ibus_bus_get_global_engine (S.bus);
    if (desc != NULL) {
        const gchar *nm = ibus_engine_desc_get_name (desc);
        gchar *msg = g_strdup_printf ("全局引擎: %s", nm ? nm : "(?)");
        gtk_label_set_text (GTK_LABEL (S.global_label), msg);
        g_free (msg);
        g_object_unref (desc);
    } else {
        gtk_label_set_text (GTK_LABEL (S.global_label), "全局引擎: (未设置)");
    }
}

static void
_refresh_all (void)
{
    _refresh_preload ();
    _refresh_global ();
}

static void
_on_add (GtkButton *btn, gpointer data)
{
    gchar **arr, **newarr;
    gsize n, i, k = 0;
    gchar *name;
    GtkTreeIter it;

    (void) btn;
    if (!gtk_combo_box_get_active_iter (GTK_COMBO_BOX (S.combo), &it))
        return;
    gtk_tree_model_get (GTK_TREE_MODEL (S.combo_store), &it, 0, &name, -1);
    if (name == NULL)
        return;

    arr = _get_preload (&n);
    newarr = g_new0 (gchar *, n + 2);
    for (i = 0; i < n; i++) {
        if (g_strcmp0 (arr[i], name) == 0)
            { newarr[k++] = g_strdup (arr[i]); }
        else
            newarr[k++] = g_strdup (arr[i]);
    }
    /* append if not present */
    {
        gboolean found = FALSE;
        for (i = 0; i < k; i++)
            if (g_strcmp0 (newarr[i], name) == 0) { found = TRUE; break; }
        if (!found)
            newarr[k++] = g_strdup (name);
    }
    _set_preload (newarr, k);
    for (i = 0; i < k; i++) g_free (newarr[i]);
    g_free (newarr);
    g_strfreev (arr);
    g_free (name);
    _refresh_preload ();
}

static void
_on_remove (GtkButton *btn, gpointer data)
{
    gchar **arr, **newarr;
    gsize n, i, k = 0;
    gchar *name;
    GtkTreeIter it;
    GtkTreeModel *model;

    (void) btn;
    model = gtk_tree_view_get_model (GTK_TREE_VIEW (S.tree));
    if (!gtk_tree_model_get_iter (model, &it,
            gtk_tree_view_get_selection (GTK_TREE_VIEW (S.tree))))
        return;
    gtk_tree_model_get (model, &it, 0, &name, -1);
    if (name == NULL)
        return;

    arr = _get_preload (&n);
    newarr = g_new0 (gchar *, n + 1);
    for (i = 0; i < n; i++) {
        if (g_strcmp0 (arr[i], name) != 0)
            newarr[k++] = g_strdup (arr[i]);
    }
    _set_preload (newarr, k);
    for (i = 0; i < k; i++) g_free (newarr[i]);
    g_free (newarr);
    g_strfreev (arr);
    g_free (name);
    _refresh_preload ();
}

static void
_on_global (GtkButton *btn, gpointer data)
{
    gchar *name;
    GtkTreeIter it;
    GtkTreeModel *model;

    (void) btn;
    model = gtk_tree_view_get_model (GTK_TREE_VIEW (S.tree));
    if (!gtk_tree_model_get_iter (model, &it,
            gtk_tree_view_get_selection (GTK_TREE_VIEW (S.tree))))
        return;
    gtk_tree_model_get (model, &it, 0, &name, -1);
    if (name == NULL)
        return;
    ibus_bus_set_global_engine (S.bus, name);
    g_free (name);
    _refresh_global ();
}

/* fill available-engines combo from ibus_bus_list_engines */
static void
_fill_combobox (void)
{
    GList *engines, *l;
    gtk_list_store_clear (S.combo_store);
    engines = ibus_bus_list_engines (S.bus);
    for (l = engines; l != NULL; l = l->next) {
        IBusEngineDesc *desc = IBUS_ENGINE_DESC (l->data);
        const gchar *nm = ibus_engine_desc_get_name (desc);
        const gchar *ln = ibus_engine_desc_get_longname (desc);
        GtkTreeIter it;
        gtk_list_store_append (S.combo_store, &it);
        gtk_list_store_set (S.combo_store, &it, 0, nm, 1, ln ? ln : nm, -1);
    }
    g_list_free (engines);
}

int
main (int argc, char **argv)
{
    GtkWidget *win, *vbox, *hbox, *scrolled, *btn_add, *btn_rm, *btn_gl;
    GtkCellRenderer *ren;
    GtkWidget *frame;
    GtkCellRenderer *combo_ren;
    GtkTreeIter it;

    ibus_init ();
    gtk_init (&argc, &argv);

    S.bus = ibus_bus_new ();
    S.config = ibus_bus_get_config (S.bus);

    win = gtk_window_new (GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title (GTK_WINDOW (win), "IBus Setup");
    gtk_window_set_default_size (GTK_WINDOW (win), 420, 360);
    g_signal_connect (win, "destroy", G_CALLBACK (gtk_main_quit), NULL);

    vbox = gtk_vbox_new (FALSE, 6);
    gtk_container_set_border_width (GTK_CONTAINER (vbox), 8);
    gtk_container_add (GTK_CONTAINER (win), vbox);

    /* global engine label */
    S.global_label = gtk_label_new ("全局引擎: ...");
    gtk_misc_set_alignment (GTK_MISC (S.global_label), 0.0, 0.5);
    gtk_box_pack_start (GTK_BOX (vbox), S.global_label, FALSE, FALSE, 0);

    /* preload engine tree */
    frame = gtk_frame_new ("已启用引擎 (preload_engines)");
    S.store = gtk_list_store_new (2, G_TYPE_STRING, G_TYPE_STRING);
    S.tree = gtk_tree_view_new_with_model (GTK_TREE_MODEL (S.store));
    ren = gtk_cell_renderer_text_new ();
    gtk_tree_view_append_column (GTK_TREE_VIEW (S.tree),
                                 gtk_tree_view_column_new_with_attributes ("引擎", ren, "text", 0, NULL));
    gtk_tree_view_append_column (GTK_TREE_VIEW (S.tree),
                                 gtk_tree_view_column_new_with_attributes ("名称", ren, "text", 1, NULL));
    scrolled = gtk_scrolled_window_new (NULL, NULL);
    gtk_scrolled_window_set_policy (GTK_SCROLLED_WINDOW (scrolled),
                                    GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    gtk_container_add (GTK_CONTAINER (scrolled), S.tree);
    gtk_container_add (GTK_CONTAINER (frame), scrolled);
    gtk_box_pack_start (GTK_BOX (vbox), frame, TRUE, TRUE, 0);

    /* available engine combo + buttons */
    hbox = gtk_hbox_new (FALSE, 6);
    S.combo_store = gtk_list_store_new (2, G_TYPE_STRING, G_TYPE_STRING);
    S.combo = gtk_combo_box_new_with_model (GTK_TREE_MODEL (S.combo_store));
    combo_ren = gtk_cell_renderer_text_new ();
    gtk_cell_layout_pack_start (GTK_CELL_LAYOUT (S.combo), combo_ren, TRUE);
    gtk_cell_layout_set_attributes (GTK_CELL_LAYOUT (S.combo), combo_ren, "text", 1, NULL);
    gtk_box_pack_start (GTK_BOX (hbox), S.combo, TRUE, TRUE, 0);
    btn_add = gtk_button_new_with_label ("添加");
    btn_rm = gtk_button_new_with_label ("移除");
    btn_gl = gtk_button_new_with_label ("设为全局");
    g_signal_connect (btn_add, "clicked", G_CALLBACK (_on_add), NULL);
    g_signal_connect (btn_rm, "clicked", G_CALLBACK (_on_remove), NULL);
    g_signal_connect (btn_gl, "clicked", G_CALLBACK (_on_global), NULL);
    gtk_box_pack_start (GTK_BOX (hbox), btn_add, FALSE, FALSE, 0);
    gtk_box_pack_start (GTK_BOX (hbox), btn_rm, FALSE, FALSE, 0);
    gtk_box_pack_start (GTK_BOX (hbox), btn_gl, FALSE, FALSE, 0);
    gtk_box_pack_start (GTK_BOX (vbox), hbox, FALSE, FALSE, 0);

    _fill_combobox ();
    if (gtk_tree_model_get_iter_first (GTK_TREE_MODEL (S.combo_store), &it))
        gtk_combo_box_set_active_iter (GTK_COMBO_BOX (S.combo), &it);
    _refresh_all ();

    gtk_widget_show_all (win);
    gtk_main ();
    return 0;
}
