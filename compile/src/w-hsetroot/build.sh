#!/bin/sh
set -e
export TARGETPATH=${TARGETPATH:-/usr/local/static/hsetroot}
source /src/common.sh

#
# Build hsetroot (X11 壁纸设置工具, 1.0.5, imlib2-based, 无 GTK)
#
# 依赖: imlib2(1.7.4, /usr/local/lib 自建, 内嵌 png/jpeg loader) + libxinerama + libX11
# 参考 w-scrot/w-feh imlib2 静态链(--start-group 解循环传递依赖)
# 注意: 简单 Makefile(非 autotools, 无 configure/autogen), 需 pkg-config + GNU make;
#       ①C99 编译(hsr-outputs.c/hsetroot.c 有 for 循环初始声明) ②1.0.5 用 xinerama 处理多屏
function hsetroot(){
  HSR_VER=1.0.5
  HSR_SRC=/tmp/hsetroot

  log "Downloading hsetroot..."
  if [ -d $HSR_SRC ] && [ -f $HSR_SRC/Makefile ]; then
    log "hsetroot source already present, skip download"
  elif [ -f /tmp/hsetroot-1.0.5.tar.gz ]; then
    rm -rf $HSR_SRC; mkdir -p $HSR_SRC
    tar xzf /tmp/hsetroot-1.0.5.tar.gz --strip 1 -C $HSR_SRC
  else
    rm -rf $HSR_SRC
    # github tag 在此环境挂死; 用 gitee 镜像(g-system/fk-hsetroot, master = himdel 1.0.5 代码, 含 -root)
    git clone --depth=1 https://gitee.com/g-system/fk-hsetroot $HSR_SRC \
      || { log "hsetroot source download FAILED"; exit 1; }
  fi

  log "Building hsetroot (CFLAGS=$CFLAGS)..."
  cd $HSR_SRC

  # imlib2 传递依赖(自建 /usr/local/lib 内嵌 png/jpeg/svg loader); --start-group 解循环引用
  deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  deps2="-lXdamage -lX11-xcb -lxcb-shm -lxcb-render -lmd"
  deps3="-lXext -lXinerama -lXfixes -lXrandr -ljpeg -lXcomposite"
  # 自建 imlib2 内嵌 svg loader → 需 librsvg/cairo/glib/pango 静态链(同 w-feh/w-scrot);
  # 过滤缺库的 -lzstd -ltiff
  RSVG_LIBS=$(pkg-config --static --libs librsvg-2.0 cairo pangocairo | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')

  # C99: for 循环初始声明; 经环境 CFLAGS 传入(勿覆盖, 保 pkg-config 头文件 include)
  export CFLAGS="$CFLAGS -std=c99"

  make clean 2>/dev/null
  # 注意: hsetroot 用 make 内置隐式规则(无自定义 link rule), libs 必须放 LDLIBS(在 hsetroot.o 之后),
  # 放 LDFLAGS 会出现在 .o 之前 → 静态库不拉取 → imlib2/X11 undefined。LDFLAGS 勿覆盖。
  make LDFLAGS="$LDFLAGS" \
    LDLIBS="-L/usr/local/lib -Wl,--start-group -lImlib2 $deps1 $deps2 $deps3 $RSVG_LIBS -lxml2 -lcroco-0.6 -Wl,--end-group" \
    || { log "hsetroot make FAILED"; exit 1; }

  log "Install hsetroot..."
  make install PREFIX=$TARGETPATH || { log "hsetroot install FAILED"; exit 1; }

  ls -lh $TARGETPATH/bin/hsetroot $TARGETPATH/bin/hsr-outputs
  xx-verify --static $TARGETPATH/bin/hsetroot || { log "hsetroot xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 零新依赖; 自建 imlib2(内嵌 png/jpeg loader) 已就位(/usr/local/lib/libImlib2.a)
    ;;
*) #compile
    oneBuild $1
    ;;
esac
