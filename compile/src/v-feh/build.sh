#!/bin/sh
set -e
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
  repo=https://gitee.com/g-system/fk-feh
  git clone --depth=1 $branch $repo /tmp/fk-feh #;
  log "Configuring FEH..."
  cd /tmp/fk-feh #&& ./bootstrap;
    deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    deps2="-lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd"
    deps3="-lXext -lXinerama -lXfixes -lXrandr -lXi"

    # ./configure
    sed -i "s^-lm -lpng -lX11 -lImlib2^-lm -lpng -lX11 -lImlib2 $deps1 $deps2 $deps3^g" config.mk

    # make
    export DESTDIR= PREFIX=$TARGETPATH
    export curl=false exif=0 magic=0 #xinerama=0 
    make clean; make LDFLAGS="-static $deps1 $deps2 $deps3 "

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
    # imlib2
    feh
    ;;
b_deps)
    bash /src/v-xlunch/build.sh imlib2 #imlib2-1.7.4.tar.g@sourceforge
    # 
    bash /src/v-tint2/build.sh xcbutil & ##need?
    bash /src/v-tint2/build.sh libxi &
    wait
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
