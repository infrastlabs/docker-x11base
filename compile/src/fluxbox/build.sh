#!/bin/sh
set -e
source /src/common.sh

#
# Build fluxbox
#
function fluxbox(){
log "Downloading FLUXBOX..."
rm -rf /tmp/fluxbox; # mkdir -p /tmp/fluxbox
# down_catfile ${FLUXBOX_URL} | tar -zx --strip 1 -C /tmp/fluxbox
# https://dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz
# branch="--branch=$FLUXBOX_VER"
git clone --depth=1 $branch https://gitee.com/g-system/fk-fluxbox /tmp/fluxbox #;
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
  LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"
  #LIBS="-lxcb -lXdmcp -lXau -lpthread" #$EX_LIBS

make clean
make LDFLAGS="-static"

log "Install FLUXBOX..."
# make;
make install;

# view
ls -lh /tmp/fluxbox/
xx-verify --static /tmp/fluxbox/fluxbox
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
    fluxbox
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
