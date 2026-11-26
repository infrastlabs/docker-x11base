#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-xcompmgr}"

function Xdamage(){
  # mkdir -p $SRCROOT/Xdamage
  log "Downloading Xdamage..."
  # curl -s -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C $SRCROOT/Xdamage
  # down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C $SRCROOT/Xdamage
  # repo=https://hub.nuaa.cf/cubanismo/libXdamage
  gitclone https://gitee.com/g-system/fk-lib-xdamage $SRCROOT/Xdamage $branch
  cd $SRCROOT/Xdamage
  # 2026-11-24 方案二交叉: --host 进 autogen(其恒跑 configure --enable-maintainer-mode "$@") + 装 sysroot
  CROSS_HOST=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    log "Xdamage: CROSS ($XX_TRIPLE)"
  fi
    ./autogen.sh $CROSS_HOST
    ./configure $CROSS_HOST
    # make; make install;

  log "Compiling Xdamage..."
  make

  log "Installing Xdamage..."
  make install ${XX_CROSS_FILE:+DESTDIR=$XX_SYSROOT}

  ls -lh ./src/.libs/libXdamage.a
  cp ./src/.libs/libXdamage.a ${XX_SYSROOT:-}/usr/lib
}

#
# Build xcompmgr
#
# 2026-11-25 方案一交叉: xcompmgr(autogen/configure/纯 X11) 走共享交叉环境(同 x-xbindkeys)。
# Xdamage() 已交叉感知(装 sysroot); xcompmgr 本体此前无交叉环境 → 补 CC=xx-clang/CROSS_HOST/PKG_CONFIG 走 sysroot。
# native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
xcompmgr_cross(){
  CROSS_HOST=""; MAKE_CC=""; XS=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    XS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib "
    # sysroot 补 X11 静态库(Xcomposite/Xfixes/Xrender 的 .a 随 -dev; libxcb 仅 -static; Xdamage 由 Xdamage() 建入 sysroot)
    xx-apk add libxcomposite-dev libx11-dev libx11-static libxext-dev libxfixes-dev libxrender-dev libxcb-dev libxcb-static libxau-dev libxdmcp-dev
    log "xcompmgr: CROSS ($XX_TRIPLE)"
  fi
}

function xcompmgr(){
  xcompmgr_cross
  apk add libxcomposite-dev

  log "Downloading XCOMPMGR..."
  rm -rf $SRCROOT/xcompmgr; # mkdir -p $SRCROOT/xcompmgr
  # down_catfile ${XCOMPMGR_URL} | tar -zx --strip 1 -C $SRCROOT/xcompmgr
  # branch="--branch=$XCOMPMGR_VER"
  gitclone https://gitee.com/g-system/fk-xcompmgr $SRCROOT/xcompmgr $branch #;
  log "Configuring XCOMPMGR..."
  cd $SRCROOT/xcompmgr #&& ./bootstrap;
    bash autogen.sh
    #./configure  --enable-static --prefix=$TARGETPATH
    # make
    # ./configure
    XCOMPMGR_LIBS="$XS-lXcomposite -L/usr/local/lib -lXdamage -lXfixes -lXrender -lX11 -lXext"
    # XCOMPMGR_LIBS="$XCOMPMGR_LIBS -lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure
    XCOMPMGR_LIBS="$XCOMPMGR_LIBS -lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure --enable-static --prefix=$TARGETPATH $CROSS_HOST
    make $MAKE_CC

  log "Install XCOMPMGR..."
  # make;
  make install;

  # view
  ls -lh $SRCROOT/xcompmgr/
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch → 用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/xcompmgr/xcompmgr | grep -qE "ARM.*statically linked" \
      || { log "XCOMPMGR file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/xcompmgr/xcompmgr
  fi
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec Xdamage || exit 1
    doExec xcompmgr || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
