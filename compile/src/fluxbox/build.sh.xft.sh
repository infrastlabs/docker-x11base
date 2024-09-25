#!/bin/sh
set -e
source /src/common.sh

#
# Build fluxbox
#
function fluxbox(){
  apk add libxml2-dev expat-static 

  log "Downloading FLUXBOX..."
  rm -rf /tmp/fluxbox; # mkdir -p /tmp/fluxbox
  # down_catfile ${FLUXBOX_URL} | tar -zx --strip 1 -C /tmp/fluxbox
  # https://dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz
  # branch="--branch=$FLUXBOX_VER"
  git clone --depth=1 $branch https://gitee.com/g-system/fk-fluxbox /tmp/fluxbox #;
  log "Configuring FLUXBOX..."
  cd /tmp/fluxbox #&& ./bootstrap;

  # ref: suckless/build.sh
  # OB_LIBS=""
  # flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  imlib="-lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm -luuid "
  EX_LIBS="$flags $OB_LIBS -lXinerama $imlib   -lX11 -lfontconfig -lfreetype -lXext -lXrandr" # -lrt

  # CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4
  # --disable-docs #https://github.com/BtbN/FFmpeg-Builds/blob/7b6432add41f4f8a47592f1e1de73ca182e4cc5c/scripts.d/35-fontconfig.sh#L3
  autoreconf -fi

  # --disable-remember \
  # Xinerama扩展的多屏显示
  # configure: WARNING: unrecognized options: --disable-docs, --enable-static, --disable-shared
  # ./configure \
  #   --prefix=$TARGETPATH \
  #   --enable-xmb \
  #   --enable-slit \
  #   --enable-toolbar \
  #   --enable-fribidi \
  #   \
  #   --enable-imlib2 \
  #   --disable-nls \
  #   --enable-xft \
  #   --enable-xinerama
  #   \
  #   --disable-docs \
  #   --enable-static \
  #   --disable-shared \
  #   LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS" #$EX_LIBS
  #   #LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"

  # ref: ./configure -h
  ./configure \
    --prefix=$TARGETPATH \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --enable-remember=yes \
    --enable-regexp=yes \
    --enable-slit=yes \
    --enable-systray=yes \
    --enable-toolbar=yes \
    --enable-ewmh=yes \
    --enable-debug=no \
    --enable-test=no \
    --enable-nls=no \
    --enable-timedcache=yes \
    --enable-xmb=yes \
    \
    --enable-imlib2 \
    --enable-freetype2 \
    --enable-xrender   \
    --enable-xft       \
    --enable-xpm       \
    --enable-xext      \
    --enable-xrandr    \
    --enable-fribidi   \
    --enable-xinerama=no
    

  make clean
  # make LDFLAGS="-static"
  make LDFLAGS="-static" LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"

  log "Install FLUXBOX..."
  # make;
  make install;

  # view
  ls -lh /tmp/fluxbox/
  xx-verify --static /tmp/fluxbox/fluxbox
}


# libxpm-dev: --enable-xpm; /usr/lib/libXpm.a
apk add fribidi-dev fribidi-static \
  libxpm-dev

# # dwm@ubt2004: 无fontconfig错误;
# # ref: suckless/build.sh
# # fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
# # FONTCONFIG_VERSION=2.14.0 @fontconfig/build
# apk add fontconfig-dev fontconfig-static

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    fluxbox
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0

# STEPS
docker run -it --rm -v /mnt:/mnt2  infrastlabs/x11-base:builder sh
apk add git gawk
cd /mnt2/docker-x11base/compile/src/
git pull

export TARGETPATH=/usr
bash _ex/fontconfig/build.sh 
# bash _ex/fontconfig/build.sh
cp /tmp/fontconfig-install/usr/lib/libfontconfig.a /usr/lib/
bash x-xrdp/build.sh libxrandr #不指定，内部即需要
bash fluxbox/build.sh.xft.sh fluxbox


# RUN
mkdir -p /usr/local/static
ln -s  /mnt2/usr-local-static-cp/tigervnc /usr/local/static/tigervnc
/usr/local/static/tigervnc/bin/Xvnc :21 &
export DISPLAY=:21

# 启动OK; 无font错 (fluxbox@alpine: 之前已装??:未装 @buidler)
# 之前的export TARGETPATH=/usr<< fontconfig; 导致直接装在usr下面了
/mnt2/docker-x11base/compile/src # ls -lh /tmp/fluxbox/fluxbox
-rwxr-xr-x    1 root     root       12.0M Nov  7 14:59 /tmp/fluxbox/fluxbox
/mnt2/docker-x11base/compile/src # /tmp/fluxbox/fluxbox
