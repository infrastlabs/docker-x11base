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

# 2026-11-25 方案一交叉: xrandr(autotools/纯 X11) 走共享交叉环境(同 v-engrampa)。
# CROSS_HOST 使 configure 交叉; PKG_CONFIG 走 sysroot。sysroot 须先有 X11 静态库——Alpine 的
#   libX11/libXext/libXrender 的 .a 随 *-dev 包, 但 libxcb 需 libxcb-static; **libXrandr.a 无 apk 包**
#   (libxrandr-static 不存在, libxrandr-dev 只装头+.so, 实测 apk 无 .a) → 复用 openbox 的源码构建
#   (交叉感知, 装 sysroot; 同 u-gtk b_deps `doExec /src/openbox/build.sh libxrandr`)。
# native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
xr_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: realloc/malloc/cc_cross 在 cross 下不能 run → 显式 yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    # 头/库搜索前缀 sysroot(双保险: xx-clang 自带 sysroot, configure link-test 需显式 -L)
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # 公共库(X11链+Xrender)已由 u-gtk b_deps 统一装(1.4.1), 不再各自 xx-apk
    # libXrandr.a 源码构建到 sysroot(同 openbox/u-gtk); 幂等: sysroot 已有则跳过(免重下源码)
    test -f "$XX_SYSROOT/usr/lib/libXrandr.a" || bash /src/openbox/build.sh libxrandr
    log "xrandr: CROSS ($XX_TRIPLE)"
  fi
}

xrandr(){
  xr_cross
  XRANDR_VER=1.5.4
  TARBALL=$SRCROOT/xrandr-$XRANDR_VER.tar.gz
  SRCDIR=$SRCROOT/xrandr

  log "Downloading XRANDR $XRANDR_VER..."
  if test -d $SRCDIR/.git || test -d $SRCDIR/configure; then
    log "xrandr source already present, skip download"
  else
    rm -rf $SRCDIR $TARBALL
    # 1. xorg 官网 tarball (最优先); 2. gitlab 归档 (兜底)
    if curl -s -k -fSL --connect-timeout 20 -o $TARBALL \
        https://www.x.org/releases/individual/app/xrandr-$XRANDR_VER.tar.gz; then
      log "downloaded from x.org"
    else
      log "x.org failed, fallback to gitlab..."
      curl -s -k -fSL --connect-timeout 20 -o $TARBALL \
        https://gitlab.freedesktop.org/xorg/app/xrandr/-/archive/xrandr-$XRANDR_VER/xrandr-$XRANDR_VER.tar.gz || { log "XRANDR download FAILED"; exit 1; }
      log "downloaded from gitlab"
    fi
    mkdir -p $SRCDIR
    tar xzf $TARBALL -C $SRCDIR --strip-components=1
  fi

  log "Configuring XRANDR..."
  cd $SRCDIR
  ./configure --prefix=$TARGETPATH $CROSS_HOST 2>&1 || { log "XRANDR configure FAILED"; exit 1; }

  # 静态链全链: pkg-config --static --libs xrandr (含 Xrandr/X11/Xext/Xrender + 传递 xcb/Xau/Xdmcp/pthread)
  # sort -u 去重(顺序无关, 在 --start-group 内); --start-group 解静态循环/顺序问题
  XRANDR_LIBS=$(pkg-config --static --libs xrandr | tr ' ' '\n' | sort -u | tr '\n' ' ')

  log "Make XRANDR..."
  make $MAKE_CC LDFLAGS="$LDFLAGS" \
    LIBS="-Wl,--start-group $XRANDR_LIBS -Wl,--end-group" 2>&1 \
    || { log "XRANDR build FAILED"; exit 1; }

  log "Install XRANDR..."
  make install 2>&1 || { log "XRANDR install FAILED"; exit 1; }

  log "Verify XRANDR..."
  ls -lh $TARGETPATH/bin/xrandr
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $TARGETPATH/bin/xrandr | grep -qE "ARM.*statically linked" \
      || { log "XRANDR file 非 ARM static"; exit 1; }
  else
    xx-verify --static $TARGETPATH/bin/xrandr || { log "XRANDR xx-verify FAILED"; exit 1; }
  fi
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
