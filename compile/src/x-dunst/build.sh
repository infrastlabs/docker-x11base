#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-dunst}"
source /src/common.sh

#
# Build dunst (X11 notification daemon, 1.13.2, X11+cairo+pango+glib+gio, 无 GTK)
#
# 版本: 1.13.2 (2026-03-18), 上游 github.com/dunst-project/dunst
# 依赖(pkg-config): gio-2.0 gdk-pixbuf-2.0 glib-2.0 pangocairo \
#                   x11 xinerama xext xrandr xscrnsaver
#   - D-Bus 走 GDBus(glib/gio 内置), 不直接链 libdbus-1
#   - XDG 路径走 glib 自带(g_getenv/g_build_filename), 不链 libxdg-basedir
#   - gdk-pixbuf 图标: 静态下 PNG/JPEG loader 是 dlopen 的, 链接不需 -rdynamic
#     (运行期图标空白属已知坑, 见 AGENTS 一、gdk-pixbuf 图标坑)
#   - 缺 xscrnsaver(libXss.a + scrnsaver.h + xscrnsaver.pc), 需先自建 → libxscrnsaver()
# 注意: dunst Makefile 第36行把 LIBS(pkg-config --libs, 非 static) 追加进 LDFLAGS,
#   且用 := 直接赋值; 故 make 时须命令行覆写 LDFLAGS(含完整 --static 库组) —
#   命令行变量优先于 Makefile := 赋值(无 override), line36 被跳过, 静态链全链生效。
#   --start-group 解静态传递/循环依赖(AGENTS 坑)。
export TARGETPATH=${TARGETPATH:-/usr/local/static/dunst}

XSS_VER=1.2.4
DUNST_VER=1.13.2

# libxscrnsaver: 自建 libXss.a(libXScrnSaver, X11 屏幕保护扩展, dunst 硬依赖)
# 安装: libXss.a→/usr/local/lib, scrnsaver.h→/usr/local/include/X11/extensions,
#       xscrnsaver.pc→/usr/local/lib/pkgconfig
libxscrnsaver(){
  if test -f /usr/local/lib/libXss.a && test -f /usr/local/lib/pkgconfig/xscrnsaver.pc; then
    log "libXss.a/xscrnsaver.pc already present, skip"
    return 0
  fi
  XSS_TGZ=/tmp/libXScrnSaver-$XSS_VER.tar.gz
  log "Building libxscrnsaver (libXss) $XSS_VER..."
  cd /tmp
  rm -rf libXScrnSaver-$XSS_VER
  # 1. 离线预置 tarball(/tmp, 宿主 cp)优先; 2. x.org 官网兜底
  test -s $XSS_TGZ || { \
    log "no staged xscrnsaver tarball, try x.org ..."; \
    curl -# -k -fSL --connect-timeout 20 --max-time 180 -o $XSS_TGZ \
      https://www.x.org/releases/individual/lib/libXScrnSaver-$XSS_VER.tar.gz \
      || { log "XSS download FAILED"; rm -f $XSS_TGZ; exit 1; }; }
  tar xzf $XSS_TGZ
  cd libXScrnSaver-$XSS_VER
  ./configure --prefix=/usr/local 2>&1 || { log "XSS configure FAILED"; exit 1; }
  make 2>&1 || { log "XSS make FAILED"; exit 1; }
  make install 2>&1 || { log "XSS install FAILED"; exit 1; }
  test -f /usr/local/lib/libXss.a || { log "XSS libXss.a missing"; exit 1; }
  log "libxscrnsaver done"
}

dunst(){
  # 依赖守卫: 缺 libXss 先自建
  libxscrnsaver

  DUNST_TGZ=/tmp/dunst-$DUNST_VER.tar.gz
  SRCDIR=/tmp/dunst

  log "Downloading DUNST $DUNST_VER..."
  if test -d $SRCDIR/.git || test -f $SRCDIR/Makefile; then
    log "dunst source already present, skip download"
  else
    rm -rf $SRCDIR
    # 1. 离线预置 tarball(/tmp, 宿主 cp)优先; 2. github 归档; 3. gitee 镜像兜底
    if test -s $DUNST_TGZ; then
      log "using staged tarball /tmp/dunst-$DUNST_VER.tar.gz"
    elif curl -# -k -fSL --connect-timeout 20 --max-time 240 -o $DUNST_TGZ \
        https://github.com/dunst-project/dunst/archive/refs/tags/v$DUNST_VER.tar.gz; then
      log "downloaded from github"
    else
      log "github failed, fallback to gitee..."
      curl -# -k -fSL --connect-timeout 20 --max-time 240 -o $DUNST_TGZ \
        https://gitee.com/g-system/fk-dunst/archive/refs/tags/v$DUNST_VER.tar.gz \
        || { log "DUNST download FAILED"; rm -f $DUNST_TGZ; exit 1; }
      log "downloaded from gitee"
    fi
    mkdir -p $SRCDIR
    tar xzf $DUNST_TGZ -C $SRCDIR --strip-components=1
  fi

  log "Configuring/Make DUNST..."
  cd $SRCDIR
  # 完整静态库组: pkg-config --static --libs 全链(含传递 xcb/Xau/Xdmcp/pixman/freetype...)
  # librsvg-2.0: gdk-pixbuf 静态包里 io-svg.c.o 引用 rsvg_*(SVG loader), 必须链 librsvg
  # sort -u 去重(顺序无关, 在 --start-group 内); --start-group 解静态循环/顺序问题
  DUNST_LIBS=$(pkg-config --static --libs \
    gio-2.0 gdk-pixbuf-2.0 glib-2.0 pangocairo x11 xinerama xext xrandr xscrnsaver \
    librsvg-2.0 libcroco-0.6 \
    | tr ' ' '\n' | sort -u | tr '\n' ' ')
  # 覆写 LDFLAGS: 命令行优先于 Makefile line36 (:=), 故 line36 被跳过, 完整静态链生效
  # DEFAULT_LDFLAGS(-lm -lrt) + -ldl 一并带上(line36 被跳过后不再自动追加)
  # WAYLAND=0: config.mk 默认开 Wayland(wayland-client/cursor 不在容器), 显式禁用以纯 X11
  # DUNSTIFY=0: 不建 dunstify(需 libnotify, 不在静态栈), 只出 dunst
  make WAYLAND=0 DUNSTIFY=0 \
    LDFLAGS="$LDFLAGS -lm -lrt -ldl -Wl,--start-group $DUNST_LIBS -Wl,--end-group" \
    2>&1 || { log "DUNST build FAILED"; exit 1; }

  log "Install DUNST..."
  make install WAYLAND=0 DUNSTIFY=0 PREFIX=$TARGETPATH 2>&1 || { log "DUNST install FAILED"; exit 1; }

  log "Verify DUNST..."
  ls -lh $TARGETPATH/bin/dunst
  xx-verify --static $TARGETPATH/bin/dunst || { log "DUNST xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 依赖 xscrnsaver(libXss.a) 缺失需自建; pango/cairo/glib/gdk-pixbuf/X11 已随 gtk2 静态栈就位
    doExec libxscrnsaver || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
