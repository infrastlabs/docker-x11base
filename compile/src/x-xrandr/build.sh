#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-xrandr}"
source /src/common.sh

#
# Build xrandr (X11 RandR 显示/分辨率/多屏配置 CLI, 1.5.4, 纯 X11 无 GTK)
#
# 版本: 1.5.4 (2026-04-25), 上游 gitlab.freedesktop.org/xorg/app/xrandr (xorg-app)
# 依赖(pkg-config xrandr): libXrandr.a + libX11.a + libXext.a + libXrender.a
#   + 传递: xcb/Xau/Xdmcp/pthread (全部静态 .a, /usr/lib)
# 注意: configure 生成的 XRANDR_LIBS 仅 "-lXrandr -lXrender -lX11",
#   缺 Xext/xcb/Xau/Xdmcp/pthread 传递静态依赖 → 静态链必失败(实测 32 处
#   undefined reference: xcb_* / XMissingExtension 等)。
#   故 make 时用 pkg-config --static --libs xrandr 全链 + --start-group 兜底。
#   参考 w-scrot/w-feh imlib2 静态链模式(--start-group 解循环/顺序)。
export TARGETPATH=${TARGETPATH:-/usr/local/static/xrandr}

xrandr(){
  XRANDR_VER=1.5.4
  TARBALL=/tmp/xrandr-$XRANDR_VER.tar.gz
  SRCDIR=/tmp/xrandr

  log "Downloading XRANDR $XRANDR_VER..."
  if test -d $SRCDIR/.git || test -d $SRCDIR/configure; then
    log "xrandr source already present, skip download"
  else
    rm -rf $SRCDIR $TARBALL
    # 1. xorg 官网 tarball (最优先); 2. gitlab 归档 (兜底)
    if curl -# -k -fSL --connect-timeout 20 -o $TARBALL \
        https://www.x.org/releases/individual/app/xrandr-$XRANDR_VER.tar.gz; then
      log "downloaded from x.org"
    else
      log "x.org failed, fallback to gitlab..."
      curl -# -k -fSL --connect-timeout 20 -o $TARBALL \
        https://gitlab.freedesktop.org/xorg/app/xrandr/-/archive/xrandr-$XRANDR_VER/xrandr-$XRANDR_VER.tar.gz || { log "XRANDR download FAILED"; exit 1; }
      log "downloaded from gitlab"
    fi
    mkdir -p $SRCDIR
    tar xzf $TARBALL -C $SRCDIR --strip-components=1
  fi

  log "Configuring XRANDR..."
  cd $SRCDIR
  ./configure --prefix=$TARGETPATH 2>&1 || { log "XRANDR configure FAILED"; exit 1; }

  # 静态链全链: pkg-config --static --libs xrandr (含 Xrandr/X11/Xext/Xrender + 传递 xcb/Xau/Xdmcp/pthread)
  # sort -u 去重(顺序无关, 在 --start-group 内); --start-group 解静态循环/顺序问题
  XRANDR_LIBS=$(pkg-config --static --libs xrandr | tr ' ' '\n' | sort -u | tr '\n' ' ')

  log "Make XRANDR..."
  make LDFLAGS="$LDFLAGS" \
    LIBS="-Wl,--start-group $XRANDR_LIBS -Wl,--end-group" 2>&1 \
    || { log "XRANDR build FAILED"; exit 1; }

  log "Install XRANDR..."
  make install 2>&1 || { log "XRANDR install FAILED"; exit 1; }

  log "Verify XRANDR..."
  ls -lh $TARGETPATH/bin/xrandr
  xx-verify --static $TARGETPATH/bin/xrandr || { log "XRANDR xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 依赖 libXrandr.a/libXrender.a 等已随 gtk2 静态栈就位(/usr/lib), 无需单独构建
    ;;
*) #compile
    oneBuild $1
    ;;
esac
