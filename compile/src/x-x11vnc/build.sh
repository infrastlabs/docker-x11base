#!/bin/sh
set -e
source /src/common.sh

# Define software download URLs.
gh=https://ghproxy.com/
gh=https://gh.api.99988866.xyz/
gh=https://ghps.cc/
gh=https://ghfast.top/
# 
LIBXTST_VER=2.0.2
LIBXTST_URL=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${LIBXTST_VER}.tar.gz


#
# Build libvncserver
#
function libvncserver(){
  # mkdir -p /tmp/libvncserver
  log "Downloading LIBVNCSERVER..."
  # down_catfile ${LIBVNCSERVER_URL} | tar -zx --strip 1 -C /tmp/libvncserver #| tar -xJ
  git clone --depth=1 --branch=LibVNCServer-0.9.13 https://gitee.com/g-system/fk-libvnc-libvncserver libvncserver
  log "Configuring LIBVNCSERVER..."
  cd /tmp/libvncserver
  # https://metaso.cn/search-v2/8706590420608032769
  mkdir build && cd build
  cmake .. \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_GNUTLS=OFF \
    -DWITH_OPENSSL=ON \
    -DWITH_GCRYPT=OFF \
    -DWITH_ZLIB=ON \
    -DWITH_LZ4=ON \
    -DWITH_THREADS=ON
  log "Compiling LIBVNCSERVER..."
  make -j$(nproc)
  log "Installing LIBVNCSERVER..."
  make install
}


#
# Build libxtst
#
function libxtst(){
  # mkdir -p /tmp/libxtst
  log "Downloading LIBXTST..."
  # down_catfile ${LIBXTST_URL} | tar -zx --strip 1 -C /tmp/libxtst #| tar -xJ
  git clone --depth=1 --branch=libXtst-1.2.3 https://gitee.com/g-system/fk-xorg-libxtst libxtst
  log "Configuring LIBXTST..."
  cd /tmp/libxtst && autoreconf -fiv && ./configure --enable-static
  log "Compiling LIBXTST..."
  make
  log "Installing LIBXTST..."
  make install
}

#
# Build x11vnc
#
function x11vnc(){
  apk add openssl-dev openssl-libs-static
  apk add xorg-server-dev

  log "Downloading X11VNC..."
  rm -rf /tmp/x11vnc; mkdir -p /tmp/x11vnc
  # down_catfile ${X11VNC_URL} | tar -zx --strip 1 -C /tmp/x11vnc
  git clone -b sam-custom --depth=1 https://gitee.com/g-system/fk-x11vnc /tmp/x11vnc

  log "Configuring X11VNC..."
  cd /tmp/x11vnc && ./bootstrap;


    flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    EX_LIBS="$flags $OB_LIBS -lXinerama $imlib   -lX11 -lfontconfig -lfreetype -lXext -lXrandr"
    # LIBS="-lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2   ..."
    # -lgnutls -lnettle -lfontconfig -lfreetype -lexpat -lxml2 -lbz2 -lbrotlidec -lbrotlicommon 
    LIBS2="-ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread -lXft -lX11 -lXrender -lz -lXinerama    -lX11 -lXext -lXrandr"

    # --enable-static --disable-shared \
    # --disable-libdrm \
  # echo>> -lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon  -lXinerama    -lX11 -lfontconfig -lfreetype -lXext -lXrandr
  # LDFLAGS="-static" LIBS="-lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread $EX_LIBS" ./configure \
  LDFLAGS="-static" LIBS="$LIBS2" ./configure \
    --prefix=$TARGETPATH \
    --with-x \
    --x-includes=/usr/include/X11 --x-libraries=/usr/lib/ \
    --with-xkeyboard \
    --with-xinerama  \
    --with-xrandr    \
    --with-xfixes    \
    --with-xdamage   \
    --with-xcomposite \
    --with-xtrap      \
    --with-xrecord    \
    --with-fbpm       \
    --with-dpms       \
    --with-v4l        \
    --with-fbdev      \
    --with-uinput     \
    --with-macosx-native \
    --with-colormultipointer \
    --with-avahi
  
  log "make X11VNC..."
  # make clean
  # make LDFLAGS="-static" LIBS="-lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread $EX_LIBS"
  make; #直接make即可; 带static,带LIBS
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
    libvncserver
    libxtst
    x11vnc
    ;;
b_deps)
    bash /src/x-x11vnc/build.sh libvncserver &
    bash /src/x-x11vnc/build.sh libxtst &
    wait
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
