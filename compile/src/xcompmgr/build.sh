#!/bin/sh
set -e
source /src/common.sh

function Xdamage(){
  # mkdir -p /tmp/Xdamage
  log "Downloading Xdamage..."
  # curl -# -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C /tmp/Xdamage
  # down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/Xdamage
  # repo=https://hub.nuaa.cf/cubanismo/libXdamage
  repo=https://gitee.com/g-system/fk-lib-xdamage
  git clone --depth=1 $branch $repo /tmp/Xdamage
  cd /tmp/Xdamage
    ./autogen.sh 
    ./configure; 
    # make; make install;

  log "Compiling Xdamage..."
  make

  log "Installing Xdamage..."
  make install

  ls -lh ./src/.libs/libXdamage.a
  cp ./src/.libs/libXdamage.a /usr/lib
}

#
# Build xcompmgr
#
function xcompmgr(){
  apk add libxcomposite-dev

  log "Downloading XCOMPMGR..."
  rm -rf /tmp/xcompmgr; # mkdir -p /tmp/xcompmgr
  # down_catfile ${XCOMPMGR_URL} | tar -zx --strip 1 -C /tmp/xcompmgr
  # branch="--branch=$XCOMPMGR_VER"
  repo=https://gitee.com/g-system/fk-xcompmgr
  git clone --depth=1 $branch $repo /tmp/xcompmgr #;
  log "Configuring XCOMPMGR..."
  cd /tmp/xcompmgr #&& ./bootstrap;
    bash autogen.sh
    #./configure  --enable-static --prefix=$TARGETPATH
    # make
    # ./configure
    XCOMPMGR_LIBS="-lXcomposite -L/usr/local/lib -lXdamage -lXfixes -lXrender -lX11 -lXext"
    # XCOMPMGR_LIBS="$XCOMPMGR_LIBS -lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure
    XCOMPMGR_LIBS="$XCOMPMGR_LIBS -lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure --enable-static --prefix=$TARGETPATH
    make

  log "Install XCOMPMGR..."
  # make;
  make install;

  # view
  ls -lh /tmp/xcompmgr/
  xx-verify --static /tmp/xcompmgr/xcompmgr
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    Xdamage
    xcompmgr
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
