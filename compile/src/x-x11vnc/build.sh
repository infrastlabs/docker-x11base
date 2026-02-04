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
  rm -rf /tmp/libvncserver
  git clone --depth=1 --branch=LibVNCServer-0.9.13 https://gitee.com/g-system/fk-libvnc-libvncserver /tmp/libvncserver
  log "Configuring LIBVNCSERVER..."
  cd /tmp/libvncserver
  # https://metaso.cn/search-v2/8706590420608032769
  mkdir build && cd build
  # #common.sh预设static,导致example依赖的libz.so过不了(无libz.a)
  # cmake .. \
  LDFLAGS=" " cmake .. \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_GNUTLS=OFF \
    -DWITH_OPENSSL=ON \
    -DWITH_GCRYPT=OFF \
    -DWITH_ZLIB=ON \
    -DWITH_LZ4=ON \
    -DWITH_THREADS=ON
  log "Compiling LIBVNCSERVER..."
  make -j$(nproc) #LDFLAGS=" " ##加到这无效, 改在cmake前:OK
  log "Installing LIBVNCSERVER..."
  make install
  # view
  find /tmp/libvncserver |egrep "\.a$"
  find /usr |egrep "libvnc.*\.a$"
}


#
# Build libxtst
#
function libxtst(){
  # mkdir -p /tmp/libxtst
  log "Downloading LIBXTST..."
  rm -rf /tmp/libxtst
  # down_catfile ${LIBXTST_URL} | tar -zx --strip 1 -C /tmp/libxtst #| tar -xJ
  git clone --depth=1 --branch=libXtst-1.2.3 https://gitee.com/g-system/fk-xorg-libxtst /tmp/libxtst
  log "Configuring LIBXTST..."
  cd /tmp/libxtst && autoreconf -fiv && ./configure --enable-static
  log "Compiling LIBXTST..."
  make
  log "Installing LIBXTST..."
  make install
  # view
  find /tmp/libxtst |egrep "\.a$"
  find /usr |egrep "libXtst\.a$"
}

#
# Build x11vnc
#
function x11vnc(){
  apk add lzo-dev #libvncserver-dev带入: lzo-dev openssl-dev ##缺依赖项时, LIBS="xx" ./configure报gcc错误 
  apk add openssl-dev openssl-libs-static
  apk add xorg-server-dev
  # configure: error: Package requirements (libvncserver >= 0.9.8) were not met:
  apk add libvncserver-dev

  log "Downloading X11VNC..."
  rm -rf /tmp/x11vnc; mkdir -p /tmp/x11vnc
  # down_catfile ${X11VNC_URL} | tar -zx --strip 1 -C /tmp/x11vnc
  git clone --depth=1 --branch=fix-152 https://gitee.com/g-system/fk-libvnc-x11vnc /tmp/x11vnc

  log "Configuring X11VNC..."
  cd /tmp/x11vnc;
    autoreconf -fiv

    flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    EX_LIBS="$flags $OB_LIBS -lXinerama $imlib   -lX11 -lfontconfig -lfreetype -lXext -lXrandr"
    # LIBS="-lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2   ..."
    # -lgnutls -lnettle -lfontconfig -lfreetype -lexpat -lxml2 -lbz2 -lbrotlidec -lbrotlicommon 
    # +: -llzo2 -lz 
    LIBS2=" -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread -lXft -lX11 -lXrender -lz -lXinerama    -lXext -lXrandr"

    # --enable-static --disable-shared \
    # --disable-libdrm \
  # echo>> -lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon  -lXinerama    -lX11 -lfontconfig -lfreetype -lXext -lXrandr
    # --x-includes=/usr/include/X11 --x-libraries=/usr/lib/ \
  # LDFLAGS="-static" LIBS="-lgnutls -lnettle -ljpeg -lpng -lcrypto -llzo2 -lXtst   -lxcb -lXdmcp -lXau -lpthread $EX_LIBS" ./configure \
  LDFLAGS="-static" LIBS="$LIBS2" ./configure \
    --prefix=$TARGETPATH \
    --with-x \
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

  # view
  ls -lh /tmp/x11vnc/src/x11vnc
  xx-verify --static /tmp/x11vnc/src/x11vnc
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
    bash /src/v-tint2/build.sh libxi &
    wait
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
