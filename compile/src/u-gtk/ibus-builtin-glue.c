/* Glue: expose GTK2 builtin im-module entry points for the ibus module.
 * The ibus im module (ibusim.c) is compiled as a normal shared-style module
 * exporting im_module_init/exit/create/list; this glue re-exposes them as
 * _gtk_immodule_ibus_* so gtkimmodule.c do_builtin(ibus) can register it. */
#include <gtk/gtkimmodule.h>

void im_module_init (GTypeModule *type_module);
void im_module_exit (void);
GtkIMContext *im_module_create (const gchar *context_id);
void im_module_list (const GtkIMContextInfo ***contexts, gint *n_contexts);

void _gtk_immodule_ibus_init (GTypeModule *type_module)
{ im_module_init (type_module); }

void _gtk_immodule_ibus_exit (void)
{ im_module_exit (); }

GtkIMContext *_gtk_immodule_ibus_create (const gchar *context_id)
{ return im_module_create (context_id); }

void _gtk_immodule_ibus_list (const GtkIMContextInfo ***contexts, guint *n_contexts)
{ im_module_list (contexts, (gint *) n_contexts); }
