#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-xbindkeys}"
source /src/common.sh

#
# Build xbindkeys (X11 键位绑定守护, 1.8.7, 纯 Xlib 无 GTK)
#
# 依赖: libX11.a + libXext.a (已就位 /usr/lib, 零新依赖)
# 上游: https://www.nongnu.org/xbindkeys/xbindkeys-1.8.7.tar.gz
# 注意: 容器内 curl 下载 nongnu.org tarball 会截断/挂死(实测 48K~125K 截断),
#       故下载优先用离线预置 tarball(/tmp, 宿主 curl 下载后 docker cp 或
#       Dockerfile COPY), 无则 down_catfile nongnu 兜底(校验 177532)。
# 2026-11-25 方案一交叉: xbindkeys(autotools/纯 Xlib) 走共享交叉环境(同 v-engrampa)。
# CROSS_HOST 使 configure 交叉; PKG_CONFIG 走 sysroot; sysroot 须先有 X11 静态库——Alpine 的
#   libX11/libXext/libXau/libXdmcp 的 .a 随 *-dev 包, 但 libxcb 需 libxcb-static(实测 apk 无 .a)。
# native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
xbk_cross(){
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
    # sysroot 补 X11 静态库(幂等; apk 命中已装则 no-op)
    xx-apk add libx11-dev libx11-static libxext-dev libxau-dev libxdmcp-dev libxcb-dev libxcb-static
    log "xbindkeys: CROSS ($XX_TRIPLE)"
  fi
}

export TARGETPATH=${TARGETPATH:-/usr/local/static/xbindkeys}
function xbindkeys(){
  xbk_cross
  XBK_VER=1.8.7
  SRC=$SRCROOT/xbindkeys-$XBK_VER
  TGZ=$SRCROOT/xbindkeys-$XBK_VER.tar.gz

  log "Downloading XBINDKEYS..."
  if test -d $SRC; then
    log "xbindkeys source dir present (tarball extracted), skip"
  else
    # 1. 离线预置 tarball 优先 (宿主 cp / Dockerfile COPY); 2. nongnu 官网 down_catfile 兜底
    test -s $TGZ || { \
      log "no staged tarball, try nongnu.org ..."; \
      curl -s -k -fSL --connect-timeout 10 --max-time 120 -o $TGZ \
        https://www.nongnu.org/xbindkeys/xbindkeys-$XBK_VER.tar.gz \
        || { log "XBINDKEYS download FAILED"; rm -f $TGZ; exit 1; }; \
    }
    # 官方 tarball 大小=177532, 校验防截断/损坏 (nongnu 容器内会截断到 48K~125K)
    test "$(stat -c%s $TGZ)" = "177532" || { \
      log "tarball size mismatch: $(stat -c%s $TGZ) != 177532 (截断/损坏, 请宿主 curl 下载后 docker cp 进 /tmp/)"; \
      rm -f $TGZ; exit 1; }
    cd /tmp
    tar xf $TGZ
  fi

  log "Configuring XBINDKEYS..."
  cd $SRC
  # 纯文本 .xbindkeysrc 足够; guile/tk 可选均禁用
  ./configure --prefix=$TARGETPATH --disable-guile --disable-tk $CROSS_HOST 2>&1 \
    || { log "XBINDKEYS configure FAILED"; exit 1; }

  # libX11.a/libXext.a 静态传递依赖: xcb/Xau/Xdmcp/xcb-shm
  # 必须 --start-group 解循环(参考 w-scrot)
  LIBS="-Wl,--start-group -lX11 -lXext -lxcb -lXau -lXdmcp -lxcb-shm -Wl,--end-group"

  log "Make XBINDKEYS..."
  make $MAKE_CC LDFLAGS="$LDFLAGS" LIBS="$LIBS" 2>&1 \
    || { log "XBINDKEYS build FAILED"; exit 1; }

  log "Install XBINDKEYS..."
  make install || { log "XBINDKEYS install FAILED"; exit 1; }

  # 配置示例: 上游 make install 不装 xbindkeysrc(仅 EXTRA_DIST), 源码目录有文本版示例
  log "Install example config..."
  mkdir -p $TARGETPATH/share/xbindkeys
  cp $SRC/xbindkeysrc $TARGETPATH/share/xbindkeys/xbindkeysrc

  ls -lh $TARGETPATH/bin/xbindkeys
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $TARGETPATH/bin/xbindkeys | grep -qE "ARM.*statically linked" \
      || { log "XBINDKEYS file 非 ARM static"; exit 1; }
  else
    xx-verify --static $TARGETPATH/bin/xbindkeys || { log "XBINDKEYS xx-verify FAILED"; exit 1; }
  fi
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 零新依赖: libX11.a/libXext.a 已就位
    ;;
*) #compile
    oneBuild $1
    ;;
esac
