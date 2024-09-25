#!/bin/sh
set -e
source /src/common.sh

# v1.12.3 @ 	2024-02-03
# v1.7.4 @2021-09-17
IMLIB2_VER=1.7.4
IMLIB2_URL=https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/${IMLIB2_VER}/imlib2-${IMLIB2_VER}.tar.gz
# v1.12.2 tar -Jxf xx.tar.xz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz #xz,gz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2_loaders-1.12.2.tar.xz
# v1.7.4
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz #gz,bz2
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz

# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-xlunch #git clone;
XLUNCH_VER=0.8.4
XLUNCH_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz
function imlib2(){
  apk add xorg-server-dev

  # 
  mkdir -p /tmp/imlib2
  log "Downloading imlib2..."
  # curl -# -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C /tmp/imlib2
  down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/imlib2
  cd /tmp/imlib2
    # export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #去-static: 无a库生成
    export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
    # ./configure; 
    ./configure --with-x \
      --x-includes=/usr/include/X11 --x-libraries=/usr/lib/ ; 
    # make; make install;

  log "Compiling imlib2..."
  make

  log "Installing imlib2..."
  make install
}

#
# Build xlunch
# export TARGETPATH=/usr/local/static/xlunch
function xlunch(){
  apk add hicolor-icon-theme #need hicolor
  # ref: xcompmgr
  apk add cairo-static expat-static fribidi-static glib-static graphite2-static harfbuzz-static
  apk add libxml2-dev ##>> -lxml2 -llzma 

  log "Downloading XLUNCH..."
  rm -rf /tmp/xlunch; # mkdir -p /tmp/xlunch
  # down_catfile ${XLUNCH_URL} | tar -zx --strip 1 -C /tmp/xlunch
  # branch="--branch=$XLUNCH_VER"
  # repo=https://hub.nuaa.cf/Tomas-M/xlunch
  repo=https://gitee.com/g-system/fk-xlunch
  git clone --depth=1 $branch $repo /tmp/xlunch #;
  log "Configuring XLUNCH..."
  cd /tmp/xlunch #&& ./bootstrap;
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf
    test -s ./Makefile-bk1 || cat Makefile > Makefile-bk1
    cat Makefile-bk1 |sed "s^DESTDIR)/usr^DESTDIR)$TARGETPATH^g" > Makefile
    sed -i "s^bash extra/genentries^#bash extra/genentries^g" Makefile

    # make
    # OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
    # make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
    
    # drop1: -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
    # drop2: -lXft -lXrender -llzma 
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext  -lfreetype -lpng   -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS" xlunch #default>> all: xlunch entries.dsv

  log "Install XLUNCH..."
  # make;
  make install; #不用install? need

  # view
  ls -lh /tmp/xlunch/
  xx-verify --static /tmp/xlunch/xlunch
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    imlib2
    xlunch
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
