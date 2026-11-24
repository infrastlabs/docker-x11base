#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-xcompmgr}"

function Xdamage(){
  # mkdir -p /tmp/Xdamage
  log "Downloading Xdamage..."
  # curl -# -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C /tmp/Xdamage
  # down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/Xdamage
  # repo=https://hub.nuaa.cf/cubanismo/libXdamage
  gitclone https://gitee.com/g-system/fk-lib-xdamage /tmp/Xdamage $branch
  cd /tmp/Xdamage
  # 2026-11-24 方案二交叉: --host 进 autogen(其恒跑 configure --enable-maintainer-mode "$@") + 装 sysroot
  CROSS_HOST=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    log "Xdamage: CROSS ($XX_TRIPLE)"
  fi
    ./autogen.sh $CROSS_HOST
    ./configure $CROSS_HOST
    # make; make install;

  log "Compiling Xdamage..."
  make

  log "Installing Xdamage..."
  make install ${XX_CROSS_FILE:+DESTDIR=$XX_SYSROOT}

  ls -lh ./src/.libs/libXdamage.a
  cp ./src/.libs/libXdamage.a ${XX_SYSROOT:-}/usr/lib
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
  gitclone https://gitee.com/g-system/fk-xcompmgr /tmp/xcompmgr $branch #;
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
    doExec Xdamage || exit 1
    doExec xcompmgr || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
