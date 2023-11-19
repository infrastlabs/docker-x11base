#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-xcompmgr #git clone;
XCOMPMGR_VER=0.8.4
XCOMPMGR_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang

# set -u; err if not exist
test -z "$TARGETPATH" && export TARGETPATH=/opt/base
test -z "$CONSOLE_LOG" && export CONSOLE_LOG=yes
# rm -rf $LOGS; #avoid deleted @batch-mode
CACHE=$TARGETPATH/../.cache; LOGS=$TARGETPATH/../.logs; mkdir -p $CACHE $LOGS
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f $CACHE/$file || curl -# -k -fSL $url > $CACHE/$file
  cat $CACHE/$file
}
function print_time_cost(){
    local begin_time=$1
	gawk 'BEGIN{
		print "本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}' 2>&1 | tee -a $logfile
}
function log {
    echo -e "\n\n>>> $*"
}


# export CC=clang
# export CXX=clang++


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
  repo=${gh}https://hub.nuaa.cf/invisikey/xcompmgr
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
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/xcompmgr-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
