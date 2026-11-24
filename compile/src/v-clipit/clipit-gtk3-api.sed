# clipit 源码 GTK3-only API → GTK2 等价（上游 GTK3 适配泄漏到 GTK2 分支）
# gtk_box_new(orient, spacing) → gtk_vbox_new/gtk_hbox_new(homogeneous=FALSE, spacing)（GTK2 是 2 参）
# gtk_widget_render_icon_pixbuf(w, stock, size) → gtk_widget_render_icon(w, stock, size, NULL)
s/gtk_box_new(GTK_ORIENTATION_VERTICAL, /gtk_vbox_new(FALSE, /g
s/gtk_box_new(GTK_ORIENTATION_HORIZONTAL, /gtk_hbox_new(FALSE, /g
s/gtk_widget_render_icon_pixbuf(\(.*GTK_ICON_SIZE_MENU\))/gtk_widget_render_icon(\1, NULL)/g
