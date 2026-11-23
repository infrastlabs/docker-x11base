#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-gpicview}"
source /src/common.sh

#
# Build GPicView 0.3.1 (LXDE 图片查看器, GTK2 最后支系) 静态
#
# 依赖（零新依赖，box 实测全部就位）：
#   gtk+-2.0 >= 2.12.0  (u-gtk 2.24.33, PKG_CHECK_MODULES)
#   x11                 (/usr/lib/libX11.a)
#   libjpeg             (/usr/lib/libjpeg.a + /usr/include/jpeglib.h,
#                        AC_CHECK_LIB(jpeg,jpeg_start_decompress) 必需——缺则 configure 硬停;
#                        -ljpeg 直接链不依赖 pkg-config)
#   gettext/glib-gettext (AM_GLIB_GNU_GETTEXT) + intltool >= 0.40.0 (IT_PROG_INTLTOOL)
#   autotools: automake/autoconf/libtool/intltool (git-tag tarball 无 configure，须 autogen.sh)
#
# 关键坑：
#   * 0.3.1 实际 GTK2-only（configure 默认 GTK2=--enable-gtk3 不传；src/ 零处 ENABLE_GTK3 使用、
#     main-win.c:1090 还有 GTK2 专属 widget->window——GTK3 反而编不过）。勿信"0.3.1 是 GTK3-only"。
#   * libjpeg 必需（缺则 configure 硬停）；intltool/gettext 构建时必需。
#   * gpicview_LDADD = $(X11_LIBS) $(GTK_LIBS) -lm（src/Makefile.am）；但 gpicview 用
#     LT_INIT(libtool) → make 链会拆散 -Wl,--start-group（libtool 把 -l 库挪到 end-group 之后，
#     --as-needed 丢 -lz → xmlIO gz* 未定义）。故对象用 make 编，最终 xx-clang -static 手动直链
#     （同 v-sysmonitor 套路），--start-group 包全部传递依赖 + X 扩展 + -ljpeg + librsvg 链。
#   * gdk_pixbuf 静态库的 io-svg.c.o 被静态模块注册强制拉入 → 需 -lrsvg-2 -lcroco-0.6 -lxml2。
#   * gdk-x11 需 X 扩展：-lXrandr -lXcomposite -lXdamage -lXfixes -lXcursor -lXinerama
#     （pkg-config --static --libs gtk+-2.0 不含，须在组内显式加）。
#   * main-win.c 曾有 gboolean 函数 `return;`（非 void）→ clang C 模式硬错误；0.3.1 已
#     upstream 修复 return FALSE（main-win.c:375），无需 patch。
#   * 静态 LDFLAGS（--static）会让 configure 的 pkg-config 测试程序（非静态 libs）失败 →
#     configure 阶段用非静态 LDFLAGS；对象编译/手动链用 ORIG_LDFLAGS（含 --static）。
#   * 网络坑：容器外网不可达 → 宿主 curl 下载 tarball + docker cp 到容器
#     /tmp/gpicview-<ver>.tar.gz；build.sh 优先用离线 tarball。主源转存 gitee
#     g-system/fk-lxde-gpicview（以 gitee 为准；vers.txt 同步）。
#   * 手装漏 pref-dlg.ui → 点 Preferences 崩：edit_preferences() 用 GtkBuilder 从
#     PACKAGE_DATA_DIR "/gpicview/ui/pref-dlg.ui"（= $prefix/share/gpicview/ui/）加载，
#     漏装则 gtk_builder_add_from_file 返回 0（未检查）→ dlg=NULL → 崩溃。
#     pref-dlg.ui 不嵌入二进制，必须随部署装（data/pref-dlg.ui，非 data/ui/）。
#
GPICVIEW_VER=0.3.1
GPICVIEW_URL="https://gitee.com/g-system/fk-lxde-gpicview/archive/refs/tags/$GPICVIEW_VER.tar.gz"

function gpicview(){
  # 不硬编码: Dockerfile stage 已设 TARGETPATH=/usr/local/static/gpicview; 回退仅兜底(common.sh 默认 static_temp1, 独立构建须显式 TARGETPATH)
  export TARGETPATH=${TARGETPATH:-/usr/local/static/gpicview}
  # configure 测试程序须能链上（非静态）gtk；最终 make 用 ORIG_LDFLAGS（--static）
  ORIG_LDFLAGS="$LDFLAGS"
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

  log "Fetch gpicview $GPICVIEW_VER source (offline tarball 优先)..."
    rm -rf /tmp/gpicview; mkdir -p /tmp/gpicview
    if [ -f /tmp/gpicview-$GPICVIEW_VER.tar.gz ]; then
      tar xzf /tmp/gpicview-$GPICVIEW_VER.tar.gz -C /tmp/gpicview
    else
      down_catfile $GPICVIEW_URL | tar xz -C /tmp/gpicview
    fi
    SRCDIR=/tmp/gpicview/gpicview-$GPICVIEW_VER
    [ -d "$SRCDIR" ] || SRCDIR=/tmp/gpicview/fk-lxde-gpicview-$GPICVIEW_VER
    test -d "$SRCDIR" || { log "source MISSING"; exit 1; }
    cd "$SRCDIR"

  log "Check main-win.c (0.3.1 已 upstream 修复 return FALSE，无需 patch)..."
    grep -q "return FALSE" src/main-win.c || { log "return FALSE missing"; exit 1; }

  log "Bootstrap (autogen.sh, git-tag tarball 无 configure)..."
    ./autogen.sh >/tmp/gpv-autogen.log 2>&1 \
      || { log "autogen FAILED"; tail -20 /tmp/gpv-autogen.log; exit 1; }
    test -x configure || { log "configure script missing"; exit 1; }

  log "Configure (GTK2 默认; --enable-gtk3 不传=no)..."
    ./configure --prefix=$TARGETPATH >/tmp/gpv-cfg.log 2>&1 \
      || { log "configure FAILED"; tail -25 /tmp/gpv-cfg.log; exit 1; }

  log "Compile objects (make -C src 只编目标文件，不触 libtool 链)..."
    # 注意：gpicview 用 LT_INIT(libtool)，make 链会把它传的 -Wl,--start-group 拆散
    #   （libtool 把 -l 库挪到 end-group 之后，--as-needed 丢 -lz → xmlIO gz* 未定义）。
    #   故对象用 make 编译，最终二进制手动 xx-clang -static 直链（同 v-sysmonitor 套路）。
    make -C src -j$(nproc) LDFLAGS="$ORIG_LDFLAGS" CFLAGS="$CFLAGS" \
      gpicview-gpicview.o gpicview-image-list.o gpicview-main-win.o gpicview-image-view.o \
      gpicview-working-area.o gpicview-ptk-menu.o gpicview-file-dlgs.o gpicview-jpeg-tran.o \
      gpicview-tran-supp.o gpicview-pref.o gpicview-jhead.o gpicview-exif.o gpicview-jpgfile.o \
      >/tmp/gpv-make.log 2>&1 \
      || { log "objects build FAILED"; tail -20 /tmp/gpv-make.log; exit 1; }
    test -f src/gpicview-main-win.o || { log "objects MISSING"; exit 1; }

  log "Static-link gpicview (manual xx-clang -static + --start-group, 绕过 libtool)..."
    cd src
    # gtk 静态链全传递依赖 + X 扩展（gdk-x11 需 Xrandr/Xcomposite/Xdamage/Xfixes/Xcursor/Xinerama）
    # + libjpeg(configure 必需) + librsvg/croco/xml2(gdk_pixbuf 静态 io-svg.c.o 强制拉入)
    # 过滤缺库的 -lzstd -ltiff（gdk-pixbuf 非必需 io；同 w-feh 套路，避免 cannot find -lzstd）
    GTK_LIBS=$(pkg-config --static --libs gtk+-2.0 | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')
    xx-clang -static -Wl,--strip-all -o gpicview \
      gpicview-gpicview.o gpicview-image-list.o gpicview-main-win.o gpicview-image-view.o \
      gpicview-working-area.o gpicview-ptk-menu.o gpicview-file-dlgs.o gpicview-jpeg-tran.o \
      gpicview-tran-supp.o gpicview-pref.o gpicview-jhead.o gpicview-exif.o gpicview-jpgfile.o \
      -Wl,--start-group \
      $GTK_LIBS \
      -lXrandr -lXcomposite -lXdamage -lXfixes -lXcursor -lXinerama \
      -ljpeg -lrsvg-2 -lcroco-0.6 -lxml2 -llzma \
      -Wl,--end-group >/tmp/gpv-link.log 2>&1 \
      || { log "static-link FAILED"; tail -20 /tmp/gpv-link.log; exit 1; }
    test -f gpicview || { log "gpicview binary MISSING"; exit 1; }

  log "Install (binary + desktop + icon; make install 会重链失败，手装)..."
    cd ..
    mkdir -p $TARGETPATH/bin $TARGETPATH/share/applications $TARGETPATH/share/pixmaps
    cp src/gpicview $TARGETPATH/bin/
    sed "s/^_Name=/Name=/;s/^_GenericName=/GenericName=/;s/^_Comment=/Comment=/" \
      gpicview.desktop.in > $TARGETPATH/share/applications/gpicview.desktop
    cp gpicview.png $TARGETPATH/share/pixmaps/
    cp -r data/pixmaps $TARGETPATH/share/gpicview/ 2>/dev/null || true
    # pref-dlg.ui 必须手装：edit_preferences() 用 GtkBuilder 从
    # PACKAGE_DATA_DIR "/gpicview/ui/pref-dlg.ui"（= $prefix/share/gpicview/ui/）加载，
    # 漏装则点 Preferences 直接崩（gtk_builder_add_from_file 返回 0 未检查 → dlg=NULL）。
    mkdir -p $TARGETPATH/share/gpicview/ui
    cp data/pref-dlg.ui $TARGETPATH/share/gpicview/ui/

  log "Install GPICVIEW locale (静态 LOCALEDIR=$TARGETPATH/share/locale；src/Makefile.am PACKAGE_LOCALE_DIR=\$(prefix)/share/locale，po/ 各 .po 由 msgfmt 转 .mo——make 默认只产 .o，po 未生成 .mo，手装才带中文)..."
    if [ -d po ]; then
      for p in po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/gpicview.mo 2>/dev/null \
          || log "msgfmt warn: $lang"
      done
      log "locales installed: $(ls po/*.po | wc -l) langs"
    fi

    test -f $TARGETPATH/bin/gpicview || { log "installed binary MISSING"; exit 1; }

  log "Verify..."
    file $TARGETPATH/bin/gpicview
    xx-verify --static $TARGETPATH/bin/gpicview || { log "xx-verify FAILED"; exit 1; }
    grep -c "undefined reference\|attempted static link" /tmp/gpv-link.log | grep -qx 0 \
      || { log "undef count != 0"; exit 1; }
    ls -lh $TARGETPATH/bin/gpicview
}

case "$1" in
cache)
    # down_catfile $GPICVIEW_URL > /dev/null
    ;;
full)
    doExec gpicview || exit 1
    ;;
b_deps)
    echo "== gtk2/jpeg/x11 =="
    ls -l /usr/lib/libgtk-x11-2.0.a /usr/lib/libgdk-x11-2.0.a /usr/lib/libjpeg.a \
          /usr/lib/libX11.a /usr/include/jpeglib.h 2>&1
    echo "== pc =="
    pkg-config --exists gtk+-2.0 && echo gtk2-pc-ok
    pkg-config --exists x11 && echo x11-pc-ok
    pkg-config --exists libjpeg && echo jpeg-pc-ok
    ;;
*) #compile
    oneBuild $1
    ;;
esac
