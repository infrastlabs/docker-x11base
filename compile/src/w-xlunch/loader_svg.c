#include "config.h"
#include "Imlib2_Loader.h"
#include <librsvg/rsvg.h>
#include <cairo.h>
#include <string.h>

#define DBG_PFX "LDR-svg"

static const char *const _formats[] = { "svg", "svgz" };

static void
_handle_error(GError *error)
{
   g_error_free(error);
}

/*
 * 2026-11-23 改写（1.12.7 适配）：
 * 1.12.7 官方 loader_svg.c 硬依赖 librsvg >= 2.46（rsvg_handle_get_intrinsic_dimensions
 *   / rsvg_handle_render_document 全在 #if LIBRSVG_CHECK_VERSION(2,46,0) 内），项目容器
 *   librsvg 2.40.21 不满足 → 官方 _load 尺寸判定失败（SVG 失效）。
 * 本文件保留项目 2.40 兼容逻辑（rsvg_handle_get_dimensions + rsvg_handle_render_cairo，
 *   旧 1.7.4 loader_svg.c 同款），仅接口改写为 1.12.7 ImlibLoaderModule（load/save/inex
 *   + IMLIB_LOADER_KEEP 宏），数据源 im->fp/fseek 改 im->fi->fdata/im->fi->fsize。
 */
static int
_load(ImlibImage *im, int load_data)
{
   RsvgHandle     *rsvg;
   RsvgDimensionData dd;
   GError         *error = NULL;
   cairo_surface_t *surf;
   cairo_t        *cr;
   int             w, hh;

   rsvg = rsvg_handle_new_from_data(im->fi->fdata, im->fi->fsize, &error);
   if (!rsvg)
      goto quit;

   rsvg_handle_get_dimensions(rsvg, &dd);
   w = dd.width;
   hh = dd.height;
   if (w <= 0 || hh <= 0)
      goto quit;

   im->w = w;
   im->h = hh;
   im->has_alpha = LDR_ALPHA_CHECK;

   if (!load_data)
   {
      g_object_unref(rsvg);
      return LOAD_SUCCESS;
   }

   if (!__imlib_AllocateData(im))
   {
      g_object_unref(rsvg);
      return LOAD_OOM;
   }

   memset(im->data, 0, im->w * im->h * sizeof(uint32_t));
   surf = cairo_image_surface_create_for_data((void *)im->data,
               CAIRO_FORMAT_ARGB32, im->w, im->h, im->w * sizeof(uint32_t));
   if (!surf)
   {
      g_object_unref(rsvg);
      return LOAD_OOM;
   }

   cr = cairo_create(surf);
   if (!cr)
   {
      cairo_surface_destroy(surf);
      g_object_unref(rsvg);
      return LOAD_OOM;
   }

   cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
   rsvg_handle_render_cairo(rsvg, cr);
   cairo_destroy(cr);
   cairo_surface_destroy(surf);
   g_object_unref(rsvg);
   return LOAD_SUCCESS;

 quit:
   if (error)
      _handle_error(error);
   if (rsvg)
      g_object_unref(rsvg);
   return LOAD_FAIL;
}

IMLIB_LOADER_KEEP(_formats, _load, NULL);
