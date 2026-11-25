#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-scrot}"
source /src/common.sh

#
# Build scrot (X 截图工具, 1.12.1 匹配现有 imlib2 1.7.4)
#
# 依赖(deps.pc): imlib2 + x11 + xcomposite + xext + xfixes + xinerama
# 参考 w-feh imlib2 静态链(--start-group 解循环)

# 2026-11-25 方案二交叉: scrot 栈共用交叉环境(autotools)。
# 设 CROSS_HOST/XX_LIBS_PREFIX: configure 追加 --host、手工 xx-clang 静态链的 -L 前缀 sysroot。
# native(未设 XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
scrot_cross(){
  CROSS_HOST=""; XX_LIBS_PREFIX=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    XX_LIBS_PREFIX="$XX_SYSROOT"
    log "scrot: CROSS ($XX_TRIPLE)"
  fi
}

# 2026-11-25 交叉: autogen 生成的旧 config.sub 不识 aarch64/armv7-alpine-linux-musl → 用新版替换。
# 仅 is-cross 生效; native 零影响。须在 configure 前于源码树根调用。
xx_config_sub_fix(){
  [ -n "$XX_CROSS_FILE" ] || return 0
  for f in config.sub config.guess; do
    cp /usr/share/automake-1.16/$f "$f" 2>/dev/null || cp /usr/share/autoconf/build-aux/$f "$f" 2>/dev/null || true
  done
}

function scrot(){
  SCROT_VER=1.12.1
  scrot_cross

  log "Downloading SCROT..."
  if test -d /tmp/scrot/.git; then
    log "scrot source already present, skip clone"
  else
    rm -rf /tmp/scrot
    branch="--branch=$SCROT_VER"
    gitclone https://gitee.com/g-system/fk-scrot /tmp/scrot $branch
  fi

  log "Configuring SCROT..."
  cd /tmp/scrot
  # 交叉下 autogen 若自动跑 configure(不带 --host) 报 cannot run C compiled programs → NOCONFIGURE=1,
  #   再显式 configure --host + config.sub 新版替换。native 原路径不变。
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 ./autogen.sh 2>&1 || { log "SCROT autogen FAILED"; exit 1; }
    xx_config_sub_fix
  else
    ./autogen.sh 2>&1 || { log "SCROT autogen FAILED"; exit 1; }
  fi
  ./configure --prefix=$TARGETPATH $CROSS_HOST

  # 参考 w-feh imlib2 静态链 (deps1/2/3 为 imlib2 全部传递依赖; deps3 补 -lXcomposite 供 scrot)
  # 注意：必须用自建 imlib2(/usr/local/lib, 内嵌 png/jpeg/svg loader)，否则链 Alpine 系统
  # libImlib2.a(/usr/lib) 无 format handler → 运行时 "failed to save image"。
  # svg loader 需 librsvg/cairo/glib/pango 静态链(同 feh)，故加 $RSVG_LIBS -lxml2 -lcroco-0.6。
  deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  deps2="-lXdamage -lX11-xcb -lxcb-shm -lxcb-render -lmd"
  deps3="-lXext -lXinerama -lXfixes -lXrandr -ljpeg -lXcomposite"
  RSVG_LIBS=$(pkg-config --static --libs librsvg-2.0 cairo pangocairo | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')

  log "Make SCROT..."
  make LDFLAGS="$LDFLAGS -L${XX_LIBS_PREFIX:-}/usr/local/lib" \
    LIBS="-Wl,--start-group -lImlib2 $deps1 $deps2 $deps3 $RSVG_LIBS -lxml2 -lcroco-0.6 -Wl,--end-group" 2>&1 \
    || { log "SCROT build FAILED"; exit 1; }

  log "Install SCROT..."
  make install || { log "SCROT install FAILED"; exit 1; }

  ls -lh $TARGETPATH/bin/scrot
  xx-verify --static $TARGETPATH/bin/scrot || { log "SCROT xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 先建自建 imlib2（内嵌 png/jpeg/svg loader 到 /usr/local/lib/libImlib2.a）；jpeg loader 需 jpeglib.h
    # scrot autogen 需 autoconf-archive（AX_ 宏，configure.ac:25/28 报 not present）
    apk add autoconf-archive
    apk add libjpeg-turbo-static jpeg-dev
    # doExec bash /src/w-xlunch/build.sh imlib2 || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
