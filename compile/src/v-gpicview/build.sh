#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-gpicview}"
source /src/common.sh

#
# Build GPicView 0.2.5 (LXDE 图片查看器, GTK2 最后一版) 静态
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
#   * 0.2.6/0.3.1 已 GTK3-only；0.2.5 默认 GTK2（--enable-gtk3 默认 no，勿误开）。
#   * libjpeg 必需（缺则 configure 硬停）；intltool/gettext 构建时必需。
#   * gpicview_LDADD = $(X11_LIBS) $(GTK_LIBS) -lm（src/Makefile.am）；但 gpicview 用
#     LT_INIT(libtool) → make 链会拆散 -Wl,--start-group（libtool 把 -l 库挪到 end-group 之后，
#     --as-needed 丢 -lz → xmlIO gz* 未定义）。故对象用 make 编，最终 xx-clang -static 手动直链
#     （同 v-sysmonitor 套路），--start-group 包全部传递依赖 + X 扩展 + -ljpeg + librsvg 链。
#   * gdk_pixbuf 静态库的 io-svg.c.o 被静态模块注册强制拉入 → 需 -lrsvg-2 -lcroco-0.6 -lxml2。
#   * gdk-x11 需 X 扩展：-lXrandr -lXcomposite -lXdamage -lXfixes -lXcursor -lXinerama
#     （pkg-config --static --libs gtk+-2.0 不含，须在组内显式加）。
#   * main-win.c main_win_open() 声明 gboolean 却 `return;`（非 void 函数）→ clang C 模式
#     硬错误，打 gpicview-mainwin-return.patch（return FALSE）。
#   * 静态 LDFLAGS（--static）会让 configure 的 pkg-config 测试程序（非静态 libs）失败 →
#     configure 阶段用非静态 LDFLAGS；对象编译/手动链用 ORIG_LDFLAGS（含 --static）。
#   * 网络坑：容器外网不可达（github/gitee 均挂死）→ 宿主 curl（codeload.github.com 通）
#     下载 tarball + docker cp 到容器 /tmp/gpicview-0.2.5.tar.gz；build.sh 优先用离线 tarball。
#     实际成功源 = codeload.github.com/lxde/gpicview/tar.gz/refs/tags/0.2.5（github 镜像 codeload）。
#
GPICVIEW_VER=0.2.5
GPICVIEW_URL="https://codeload.github.com/lxde/gpicview/tar.gz/refs/tags/$GPICVIEW_VER"

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
    test -d /tmp/gpicview/gpicview-$GPICVIEW_VER || { log "source MISSING"; exit 1; }
    cd /tmp/gpicview/gpicview-$GPICVIEW_VER

  log "Patch main-win.c (clang C 模式把非 void 函数 return; 当硬错误)..."
    patch -p0 -N < /src/v-gpicview/gpicview-mainwin-return.patch >/tmp/gpv-patch.log 2>&1 \
      || { log "patch FAILED"; tail -10 /tmp/gpv-patch.log; exit 1; }
    grep -q "return FALSE" src/main-win.c || { log "patch NOT applied"; exit 1; }

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
