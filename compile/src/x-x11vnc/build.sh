#!/bin/sh
set -e
source /src/common.sh

# Define software download URLs.
gh=https://ghproxy.com/
gh=https://gh.api.99988866.xyz/
gh=https://ghps.cc/
gh=https://ghfast.top/
# 
FDKAAC_VER=2.0.2
FDKAAC_URL=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${FDKAAC_VER}.tar.gz


#
# Build x11vnc
#
function fdkaac(){
  # - fdkaac
  # ins fdk-aac:
  # tar -zxf fdk-aac-2.0.2.tar.gz 
  # cd fdk-aac-2.0.2/
  mkdir -p /tmp/fdkaac
  log "Downloading FDKAAC..."
  down_catfile ${FDKAAC_URL} | tar -zx --strip 1 -C /tmp/fdkaac #| tar -xJ
  log "Configuring FDKAAC..."
  cd /tmp/fdkaac && ./configure --enable-static
  make
  make install
}

#
# Build x11vnc
#
function x11vnc(){
  apk add nasm

  # tar -zxf $CACHE/x11vnc-${X11VNC_VER}.tar.gz -C /tmp;\
  # cd /tmp/x11vnc-${ver};\
  rm -rf /tmp/x11vnc; mkdir -p /tmp/x11vnc
  log "Downloading X11VNC..."
  # down_catfile ${X11VNC_URL} | tar -zx --strip 1 -C /tmp/x11vnc
  rm -rf /tmp/x11vnc;
  git clone -b sam-custom --depth=1 https://gitee.com/g-system/fk-x11vnc /tmp/x11vnc

  log "Configuring X11VNC..."
  cd /tmp/x11vnc && ./bootstrap;


  ./configure 

  log "make X11VNC..."
  make;
  log "install X11VNC..."
  make install;

  # # libvnc.so
  # cd $TARGETPATH/lib/x11vnc
  # gcc -shared -o libvnc.so libvnc.a 
}


case "$1" in
cache)
    # down_catfile ${X11VNC_URL} > /dev/null
    ;;
full)
    fdkaac
    x11vnc
    ;;
b_deps)
    bash /src/x-x11vnc/build.sh libxrandr &
    bash /src/x-x11vnc/build.sh fdkaac &
    wait
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
