#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-feh}"
source /src/common.sh

FEH_VER=0.8.4
FEH_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

#
# Build feh
# export TARGETPATH=/usr/local/static/feh
function feh(){
  # ./wallpaper.h:31:10: fatal error: 'X11/Intrinsic.h' file not found
  apk add libxt-dev

  log "Downloading FEH..."
  rm -rf /tmp/fk-feh; # mkdir -p /tmp/fk-feh ##feh> fk-feh
  # down_catfile ${FEH_URL} | tar -zx --strip 1 -C /tmp/fk-feh
  # branch="--branch=$FEH_VER"
  # repo=https://hub.nuaa.cf/Tomas-M/feh
  git clone --depth=1 $branch https://gitee.com/g-system/fk-feh /tmp/fk-feh #;
  log "Configuring FEH..."
  cd /tmp/fk-feh #&& ./bootstrap;
    deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    deps2="-lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd"
    deps3="-lXext -lXinerama -lXfixes -lXrandr -lXi -ljpeg"
    # 内置 svg loader 需 librsvg/cairo/glib/pango；--start-group 解循环引用；
    # 过滤缺库的 -lzstd -ltiff（gdk-pixbuf 非必需 io）
    RSVG_LIBS=$(pkg-config --static --libs librsvg-2.0 cairo pangocairo | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')

    # ./configure
    sed -i "s^-lm -lpng -lX11 -lImlib2^-lm -lpng -lX11 -Wl,--start-group -lImlib2 $deps1 $deps2 $deps3 $RSVG_LIBS -lxml2 -lcroco-0.6 -Wl,--end-group^g" config.mk

    # make
    export DESTDIR= PREFIX=$TARGETPATH
    export curl=false exif=0 magic=0 #xinerama=0 
    make clean; make LDFLAGS="-static -L/usr/local/lib $deps1 $deps2 $deps3 "

    log "Install FEH..."
    # make-install
    make install;

  # view
  ls -lh /tmp/fk-feh/src/feh
  xx-verify --static /tmp/fk-feh/src/feh
}


case "$1" in
cache)
    # down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    doExec feh || exit 1
    ;;
b_deps)
    # jpeg 静态库+头（内置 jpeg loader 依赖）；先于 w-xlunch imlib2（其内置段编 jpeg.o 需 jpeglib.h）
    apk add libjpeg-turbo-static jpeg-dev
    doExec bash /src/w-xlunch/build.sh imlib2 || exit 1 #imlib2-1.7.4.tar.g@sourceforge
    doExec_mark "w-feh b_deps grp"
    doExec bash /src/w-tint2/build.sh xcbutil & ##need?
    doExec bash /src/w-tint2/build.sh libxi &
    wait
    doExec_check || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
