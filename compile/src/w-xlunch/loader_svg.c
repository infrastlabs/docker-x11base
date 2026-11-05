#include "loader_common.h"
#include <librsvg/rsvg.h>
#include <cairo.h>
#include <string.h>

int
load2(ImlibImage * im, int load_data)
{
   long                 sz;
   guint8              *buf;
   RsvgHandle          *h;
   RsvgDimensionData    dd;
   int                  w, hh;
   cairo_surface_t     *surf;
   cairo_t             *cr;
   unsigned char       *pix;
   GError              *err = NULL;

   fseek(im->fp, 0, SEEK_END);
   sz = ftell(im->fp);
   fseek(im->fp, 0, SEEK_SET);
   if (sz <= 0)
      return LOAD_FAIL;
   buf = malloc(sz);
   if (!buf)
      return LOAD_FAIL;
   if (fread(buf, 1, sz, im->fp) != (size_t) sz)
     {
        free(buf);
        return LOAD_FAIL;
     }

   h = rsvg_handle_new_from_data(buf, sz, &err);
   free(buf);
   if (!h)
      return LOAD_FAIL;

   rsvg_handle_get_dimensions(h, &dd);
   w = dd.width;
   hh = dd.height;
   if (w <= 0 || hh <= 0)
     {
        g_object_unref(h);
        return LOAD_FAIL;
     }

   im->w = w;
   im->h = hh;
   SET_FLAG(im->flags, F_HAS_ALPHA);

   if (!load_data)
     {
        g_object_unref(h);
        return LOAD_SUCCESS;
     }

   if (!__imlib_AllocateData(im))
     {
        g_object_unref(h);
        return LOAD_FAIL;
     }

   surf = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, hh);
   if (cairo_surface_status(surf) != CAIRO_STATUS_SUCCESS)
     {
        g_object_unref(h);
        return LOAD_FAIL;
     }
   cr = cairo_create(surf);
   cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
   rsvg_handle_render_cairo(h, cr);
   cairo_destroy(cr);
   pix = cairo_image_surface_get_data(surf);
   memcpy(im->data, pix, w * hh * 4);
   cairo_surface_destroy(surf);
   g_object_unref(h);
   return LOAD_SUCCESS;
}

void
formats(ImlibLoader * l)
{
   static const char  *const list_formats[] = { "svg" };
   __imlib_LoaderSetFormats(l, list_formats,
                            sizeof(list_formats) / sizeof(char *));
}
