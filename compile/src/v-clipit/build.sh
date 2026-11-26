#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-clipit}"
source /src/common.sh

#
# Build clipit 1.4.5 (GTK2) 静态——剪贴板托盘
#
# 源码：github.com/CristianHenzel/ClipIt @ commit f35db54（2024-11-03，Fedora 1.4.5^20241103gitf35db54）
# 上游 git 弃更（last tag 1.4.5@2020-06，last commit 2024-11 C99 fix）；Debian/Ubuntu 标 deprecated，
# 但 Fedora 仍以 git snapshot 打包。取 commit 快照而非 tag（tag 旧、C99 构建修复在 commit 里）。
#
# GTK2 默认（configure.ac：PKG_CHECK_MODULES([GTK], [gtk+-2.0 >= 2.10])；--with-gtk3 可选，不用）。
# --disable-appindicator：静态栈无 ayatana-appindicator（auto 也会查到 no，显式禁更稳）。
# keybinder.c 用 XGrabKey（X11，GDK_WINDOW_XDISPLAY），仅需 -lX11（无 libXtst.a，不需）。
# 托盘图标 GtkStatusIcon + ICON="clipit-trayicon"（图标主题名）→ SVG 图标走 gdk-pixbuf 静态 SVG loader
#   （u-gtk 已把 libstaticpixbufloader-svg 并入 libgdk_pixbuf-2.0.a，librsvg-2.a 在 /usr/local/lib）。
# 运行时 xdotool（main.c:342 /bin/sh -c 'xdotool key ctrl+v'，自动粘贴）→ b_deps 静态建 xdotool。

CLIPIT_VER=1.4.5
CLIPIT_COMMIT=f35db540c9d3c57b13439d66597736e917e8c9a1

# 2026-11-25 方案二交叉: clipit 栈共用交叉环境(autotools configure + 手工 xx-clang 静态链)。
# 设 CROSS_HOST/XX_LIBS_PREFIX: configure 追加 --host、手工 xx-clang 静态链的 -L 前缀 sysroot。
# native(未设 XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
cl_cross(){
  CROSS_HOST=""; XX_LIBS_PREFIX=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    XX_LIBS_PREFIX="$XX_SYSROOT"
    log "clipit: CROSS ($XX_TRIPLE)"
  fi
}

# xdotool v3.20211022.1 静态化（运行时依赖：clipit 自动粘贴 shell 出 xdotool）
# 用最后 v3（autotools 静态构建成熟）；v4.20260303.1 是 2026-03 最新但构建系统/依赖未知，暂不用。
# 缺 libXtst.a（alpine 无 libxtst-static 包）→ 用 freedesktop 官方源码自建（xorg lib，小）。
XDO_VER=v3.20211022.1
XTST_VER=1.2.4
libxtst(){
  test -f /usr/lib/libXtst.a && { log "libXtst.a already present, skip"; return 0; }
  XTST_TGZ=$SRCROOT/libXtst-$XTST_VER.tar.gz
  cd /tmp && rm -rf libXtst-*
  # x.org 官方 tarball（上游在 gitlab.freedesktop.org，github 无镜像）；ghfast github 兜底
  test -s $XTST_TGZ || curl -fsSL https://www.x.org/releases/individual/lib/libXtst-$XTST_VER.tar.gz > $XTST_TGZ 2>/dev/null || true
  test -s $XTST_TGZ || curl -fsSL https://ghfast.top/$GITHUB/freedesktop/libXtst/archive/refs/tags/libXtst-$XTST_VER.tar.gz > $XTST_TGZ 2>/dev/null || true
  test -s $XTST_TGZ || { log "XTST download FAILED"; rm -f $XTST_TGZ; exit 1; }
  tar xzf $XTST_TGZ
  cd libXtst-*
  # x.org tarball 带 configure（无 autogen.sh 需要）；静态构建，--prefix=/usr 装 /usr/lib/libXtst.a
  test -f ./configure || sh autogen.sh --disable-shared --enable-static 2>&1 || true
  ./configure --prefix=/usr --disable-shared --enable-static 2>&1 || { log "XTST configure FAILED"; exit 1; }
  make -j$(nproc) 2>&1 || { log "XTST make FAILED"; exit 1; }
  make install 2>&1 | tail -3 || { log "XTST install FAILED"; exit 1; }
  test -f /usr/lib/libXtst.a || { log "XTST libXtst.a missing"; exit 1; }
  ls -lh /usr/lib/libXtst.a
  log "libXtst done"
}
xdotool(){
  test -x /usr/local/static/xdotool/bin/xdotool && { log "xdotool already present, skip"; return 0; }
  libxtst || exit 1
  XDO_TGZ=$SRCROOT/xdotool-$XDO_VER.tar.gz
  XDO_DIR=xdotool-$(echo $XDO_VER | sed 's/^v//')   # github archive 顶层无 v 前缀
  cd /tmp
  rm -rf $XDO_DIR
  test -s $XDO_TGZ || down_catfile $GITHUB/jordansissel/xdotool/archive/refs/tags/$XDO_VER.tar.gz > $XDO_TGZ 2>/dev/null || true
  # github 直连慢/不通 → ghfast 代理兜底（同 clipit）
  test -s $XDO_TGZ || curl -fsSL https://ghfast.top/$GITHUB/jordansissel/xdotool/archive/refs/tags/$XDO_VER.tar.gz > $XDO_TGZ 2>/dev/null || true
  test -s $XDO_TGZ || { log "XDO download FAILED"; rm -f $XDO_TGZ; exit 1; }
  tar xzf $XDO_TGZ
  cd $XDO_DIR
  log "Building xdotool static (make static)..."
  # xdotool Makefile 有 static 目标（xdotool.static）；显式静态全链（X11/Xtst/Xinerama/xkbcommon/Xi）
  make static CC="xx-clang" LDFLAGS="-static -no-pie -Wl,--strip-all" \
    XDOTOOL_LIBS="-lX11 -lXtst -lXinerama -lxkbcommon -lxkbcommon-x11 -lXext -lXdmcp -lXau -lXrender -lxcb -lxcb-render -lxcb-shm -lxcb-util" \
    LIBXDO_LIBS="-lXi -lX11 -lXtst -lXinerama -lxkbcommon -lXext -lXdmcp -lXau -lxcb -lxcb-render -lxcb-shm -lxcb-util" 2>&1 \
    || { log "XDO make static FAILED"; exit 1; }
  BIN=$(find . -name xdotool.static -type f | head -1)
  test -n "$BIN" || { log "XDO binary MISSING"; exit 1; }
  mkdir -p /usr/local/static/xdotool/bin
  cp -f "$BIN" /usr/local/static/xdotool/bin/xdotool
  xx-verify --static /usr/local/static/xdotool/bin/xdotool || { log "XDO xx-verify FAILED"; exit 1; }
  ls -lh /usr/local/static/xdotool/bin/xdotool
  log "xdotool done"
}

function clipit(){
  cl_cross
  log "Downloading CLIPIT ($CLIPIT_COMMIT tarball)..."
  cd /tmp
  rm -rf ClipIt
  mkdir -p ClipIt
  # ① tarsrc 缓存（gitee x11base-tarsrc *clipit/）② github commit tarball 兜底
  if [ -f $SRCROOT/clipit.tar.gz ]; then
    tar xzf $SRCROOT/clipit.tar.gz -C /tmp
    rm -rf $SRCROOT/ClipIt
    mv $SRCROOT/ClipIt-f35db540c9d3c57b13439d66597736e917e8c9a1 $SRCROOT/ClipIt
  else
    down_catfile $GITHUB/CristianHenzel/ClipIt/archive/$CLIPIT_COMMIT.tar.gz 2>/dev/null \
      | tar xz --strip 1 -C $SRCROOT/ClipIt || true
    test -s $SRCROOT/ClipIt/configure.ac || { \
      log "CLIPIT download/extract FAILED, retry ghfast proxy..."; \
      curl -fsSL https://ghfast.top/$GITHUB/CristianHenzel/ClipIt/archive/$CLIPIT_COMMIT.tar.gz \
        | tar xz --strip 1 -C $SRCROOT/ClipIt 2>/dev/null || { log "CLIPIT FAILED"; exit 1; }; }
  fi
  test -s $SRCROOT/ClipIt/configure.ac || { log "CLIPIT source MISSING"; exit 1; }
  cd $SRCROOT/ClipIt

  log "Autogen (autopoint/intltoolize/aclocal/autoconf/autoheader/automake)..."
  # 交叉下 autogen 若自动跑 configure(不带 --host) 报 cannot run C compiled programs → NOCONFIGURE=1,
  #   再显式 configure --host。native 原路径不变。
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 sh autogen.sh 2>&1 || { log "CLIPIT autogen FAILED"; exit 1; }
  else
    sh autogen.sh 2>&1 || { log "CLIPIT autogen FAILED"; exit 1; }
  fi

  log "Applying GTK2 seat patch (GdkSeat 是 GTK3-only 类型，上游泄漏到 GTK2 分支)..."
  patch -p1 -N < /src/v-clipit/clipit-gtk2-seat.patch 2>/dev/null || { log "CLIPIT seat patch FAILED"; exit 1; }
  grep -qE 'GdkSeat \*seat|gdk_display_get_default_seat' src/main.c && { log "CLIPIT seat patch NOT applied"; exit 1; } || true

  log "Applying GTK3-only API -> GTK2 兼容 sed (gtk_box_new/gtk_widget_render_icon_pixbuf)..."
  sed -i -f /src/v-clipit/clipit-gtk3-api.sed src/*.c || { log "CLIPIT gtk3-api sed FAILED"; exit 1; }
  grep -qE 'gtk_box_new|gtk_widget_render_icon_pixbuf' src/*.c && { log "CLIPIT gtk3-api NOT applied"; exit 1; } || true

  log "Configuring CLIPIT (GTK2, static only)..."
  # 交叉: -L 前缀 sysroot 的 /usr/lib /usr/local/lib（native XX_LIBS_PREFIX 空 = 原路径无 -L）。
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed${XX_LIBS_PREFIX:+ -L$XX_LIBS_PREFIX/usr/lib -L$XX_LIBS_PREFIX/usr/local/lib}"
  ./configure --prefix=$TARGETPATH --disable-appindicator $CROSS_HOST 2>&1 || { log "CLIPIT configure FAILED"; exit 1; }

  log "Compiling CLIPIT + 直链链接..."
  # 覆盖 LINK 去 LIBTOOL + 清 clipit_LDADD（含动态 GTK_LIBS，会优先 .so → 动态链），LIBS 补全 gtk2/X11/glib 静态全链
  CLI_LIBS="-Wl,--start-group"
  # 交叉: -L 前缀 sysroot 的 /usr/lib /usr/local/lib（native XX_LIBS_PREFIX 空 = 原路径无 -L）。
  [ -n "$XX_LIBS_PREFIX" ] && CLI_LIBS="$CLI_LIBS -L$XX_LIBS_PREFIX/usr/lib -L$XX_LIBS_PREFIX/usr/local/lib"
  CLI_LIBS="$CLI_LIBS \
    -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 \
    -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
    -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lcairo \
    -lXinerama -lXrandr -lXfixes \
    -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz \
    -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi \
    -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount -lblkid -lXcomposite -lXdamage \
    -lgthread-2.0 -lm \
    -Wl,--end-group"
  # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补 libgcc_s.a（同 pasystray）
  if [ ! -f /usr/lib/libgcc_s.a ]; then
    GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1))
    cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
  fi
  make -j$(nproc) LINK="xx-clang -static -no-pie -Wl,--strip-all -Wall -O2 -Os -o \$@" \
    clipit_LDADD="" LIBS="$CLI_LIBS" 2>&1 || { log "CLIPIT make LINK FAILED"; exit 1; }
  mkdir -p $TARGETPATH/bin
  BIN=$(find $SRCROOT/ClipIt -name clipit -type f -perm -u+x 2>/dev/null | head -1)
  test -n "$BIN" || { log "CLIPIT binary MISSING"; exit 1; }
  cp -f "$BIN" $TARGETPATH/bin/clipit

  log "Install CLIPIT data (desktop + SVG tray icons + autostart)..."
  mkdir -p $TARGETPATH/share/applications $TARGETPATH/share/icons/hicolor/scalable/apps $TARGETPATH/share/clipit
  # desktop：configure/intltool 已生成 data/*.desktop（.desktop.in → .desktop）
  for f in clipit.desktop clipit-startup.desktop; do
    src=$(find $SRCROOT/ClipIt/data -name "$f" 2>/dev/null | head -1)
    test -n "$src" && cp -f "$src" $TARGETPATH/share/applications/ 2>/dev/null || true
  done
  cp -f $SRCROOT/ClipIt/data/clipit-trayicon.svg $SRCROOT/ClipIt/data/clipit-trayicon-offline.svg \
    $TARGETPATH/share/icons/hicolor/scalable/apps/

  log "Install CLIPIT zh_CN locale (.mo via msgfmt)..."
  if [ -f $SRCROOT/ClipIt/po/zh_CN.po ]; then
    mkdir -p $TARGETPATH/share/locale/zh_CN/LC_MESSAGES
    msgfmt -o $TARGETPATH/share/locale/zh_CN/LC_MESSAGES/clipit.mo $SRCROOT/ClipIt/po/zh_CN.po \
      || { log "CLIPIT msgfmt FAILED"; exit 1; }
    ls -lh $TARGETPATH/share/locale/zh_CN/LC_MESSAGES/clipit.mo
  fi

  log "Verify CLIPIT..."
  file $TARGETPATH/bin/clipit
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $TARGETPATH/bin/clipit | grep -qE "ARM.*statically linked" \
      || { log "CLIPIT file 非 ARM static"; exit 1; }
  else
    xx-verify --static $TARGETPATH/bin/clipit || { log "CLIPIT xx-verify FAILED"; exit 1; }
  fi
  strings $TARGETPATH/bin/clipit | grep -q "GTK_ICON_THEME" && echo "strings: GTK_ICON_THEME OK"
  strings $TARGETPATH/bin/clipit | grep -q "rsvg" && echo "strings: rsvg OK"
  # 托盘图标 SVG loader 验证：gdk_pixbuf 静态 SVG 支持
  strings $TARGETPATH/bin/clipit | grep -qi "clipit-trayicon" && echo "strings: trayicon OK"
  strings $TARGETPATH/bin/clipit | grep -q "xdotool" && echo "strings: xdotool OK"
  ls -lh $TARGETPATH/bin/clipit
}

case "$1" in
cache)
    down_catfile $GITHUB/CristianHenzel/ClipIt/archive/$CLIPIT_COMMIT.tar.gz > /dev/null 2>&1 || true
    ;;
full)
    doExec clipit || exit 1
    ;;
b_deps)
    echo "== gtk2 stack =="; ls /usr/lib/libgtk-x11-2.0.a /usr/lib/libgdk-x11-2.0.a /usr/local/lib/librsvg-2.a 2>&1
    echo "== xdotool (runtime) =="; xdotool || exit 1
    ;;
*) #compile
    oneBuild $1
    exit $?
    ;;
esac
exit 0
