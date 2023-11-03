#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-fluxbox #git clone;
FLUXBOX_VER=0.8.4
FLUXBOX_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

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
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/fluxbox-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
