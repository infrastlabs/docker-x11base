#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-fluxbox}"
source /src/common.sh

#
# Build fluxbox
#
# 2026-11-25 交叉: fluxbox(C++/autotools) 走共享交叉环境(同 x-xbindkeys/x-xrandr)。
# fluxbox 是 C++ → 除 CC 外还须 export CXX=xx-clang++ + ac_cv_prog_cxx_cross=yes(repo 惯例,
#   同 v-geany/v-pcmanfm/u-gtkmm; common.sh 顶部已 export CXX, 此处显式重申防被子脚本覆盖)。
# configure 已 --disable-imlib2 → 无需 imlib2 静态链; --enable-fribidi → 需 fribidi 静态;
#   fontconfig/freetype 需 .a; X11 静态栈(X11/Xext/Xrandr/Xrender)同 x-xrandr 来源。
#   libXrandr.a 无 apk 包 → 复用 openbox 源码构建(装 sysroot)。
# native(未设 XX_CROSS_FILE): CROSS_HOST/MAKE_CC 留空 → 原路径零影响。
fb_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export CXX=xx-clang++            # fluxbox=C++: 交叉须 C++ 编译器(repo 惯例 xx-clang++)
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: realloc/malloc/cc/cxx_cross 在 cross 下不能 run → 显式 yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    export ac_cv_prog_cxx_cross=yes   # C++ 交叉: configure cxx link-test 亦不能 run
    # 头/库搜索前缀 sysroot(双保险: xx-clang 自带 sysroot, configure link-test 需显式 -L)
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # sysroot 补 fribidi/fontconfig/freetype + X11 静态库(幂等; apk 命中已装则 no-op)
    xx-apk add fribidi-dev fribidi-static fontconfig-dev fontconfig-static freetype-dev \
      libx11-dev libx11-static libxext-dev libxrender-dev libxau-dev libxdmcp-dev libxcb-dev libxcb-static
    # libXrandr.a 无 apk 包 → 源码构建到 sysroot(同 x-xrandr/openbox/u-gtk); 幂等: 已有则跳过
    test -f "$XX_SYSROOT/usr/lib/libXrandr.a" || bash /src/openbox/build.sh libxrandr
    log "fluxbox: CROSS ($XX_TRIPLE)"
  fi
}

function fluxbox(){
  fb_cross
  log "Downloading FLUXBOX..."
  rm -rf /tmp/fluxbox; # mkdir -p /tmp/fluxbox
  # down_catfile ${FLUXBOX_URL} | tar -zx --strip 1 -C /tmp/fluxbox
  # https://dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz
  # branch="--branch=$FLUXBOX_VER"
  gitclone https://gitee.com/g-system/fk-fluxbox /tmp/fluxbox $branch #;
  log "Configuring FLUXBOX..."
  cd /tmp/fluxbox #&& ./bootstrap;

  # ref: suckless/build.sh
  # flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  # fontconfig-static@apk>> -luuid 

  # CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4
  # --disable-docs #https://github.com/BtbN/FFmpeg-Builds/blob/7b6432add41f4f8a47592f1e1de73ca182e4cc5c/scripts.d/35-fontconfig.sh#L3
  autoreconf -fi
  # --disable-remember \
  ./configure \
    --prefix=$TARGETPATH \
    --enable-xmb \
    --enable-slit \
    --enable-toolbar \
    --enable-fribidi \
    \
    --disable-imlib2 \
    --disable-nls \
    --disable-xft \
    --disable-xinerama \
    --disable-docs \
    \
    --enable-static \
    --disable-shared \
    LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid" \
    $CROSS_HOST
    #LIBS="-lxcb -lXdmcp -lXau -lpthread" #$EX_LIBS

  make clean
  if [ -n "$XX_CROSS_FILE" ]; then
    # 交叉: -static 全链 + 静态传递依赖 --start-group 解循环(X11/Xext/Xrandr/Xrender/xcb/Xau/Xdmcp
    #   /fribidi/fontconfig/freetype/expat/uuid/z/pthread/m)。不 clobber LDFLAGS(用 $LDFLAGS 追加 sysroot -L)。
    FB_LIBS="-Wl,--start-group -lX11 -lXext -lXrandr -lXrender -lxcb -lXau -lXdmcp \
      -lfribidi -lfontconfig -lfreetype -lexpat -luuid -lpthread -lz -lm -Wl,--end-group"
    make $MAKE_CC LDFLAGS="$LDFLAGS" LIBS="$FB_LIBS" || { log "FLUXBOX cross build FAILED"; exit 1; }
  else
    make LDFLAGS="-static"
  fi

  log "Install FLUXBOX..."
  # make;
  make install;

  # view
  ls -lh /tmp/fluxbox/
  # 交叉真验: xx-verify 按 build 架构校验, 交叉产物(ARM) 必报 mismatch → 用 file 判 static+目标架构;
  #   native 仍走 xx-verify(原路径)。产物= /tmp/fluxbox/fluxbox。
  if [ -n "$XX_CROSS_FILE" ]; then
    file /tmp/fluxbox/fluxbox | grep -qE "ARM.*statically linked" \
      || { log "FLUXBOX file 非 ARM static"; exit 1; }
  else
    xx-verify --static /tmp/fluxbox/fluxbox || { log "FLUXBOX xx-verify FAILED"; exit 1; }
  fi
}


apk add fribidi-dev fribidi-static

# dwm@ubt2004: 无fontconfig错误;
# ref: suckless/build.sh
# fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
# FONTCONFIG_VERSION=2.14.0 @fontconfig/build
apk add fontconfig-dev fontconfig-static

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec fluxbox || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
