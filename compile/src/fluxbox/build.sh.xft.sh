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
# flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
# fontconfig-static@apk>> -luuid 


# OB_LIBS: all open
# pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
# xrandr="-lXrandr"
# EX: -llzma   -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
# OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
# flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

#  2>&1 |grep musl/10 |awk '{print $2}' |sort -u
# --static -static >> 一样X11> xcb_xx错误; 
# --static -static ##ex
flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

# flux=" -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 "
# /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgcc_s
# ext2="-lstdc++ -lmd -lfribidi -lbsd -lXrandr" #-lgcc_s 
# make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"

# ex: -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid
# EX_LIBS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"
EX_LIBS="$flags $OB_LIBS -lXinerama   -lX11 -lfontconfig -lfreetype -lXext -lXrandr"

# CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4
# --disable-docs #https://github.com/BtbN/FFmpeg-Builds/blob/7b6432add41f4f8a47592f1e1de73ca182e4cc5c/scripts.d/35-fontconfig.sh#L3
autoreconf -fi
# --disable-remember \
# Xinerama扩展的多屏显示
./configure \
  --prefix=$TARGETPATH \
  --enable-xmb \
  --enable-slit \
  --enable-toolbar \
  --enable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --enable-xft \
  --enable-xinerama \
  --disable-docs \
  \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS" #$EX_LIBS
  #LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"

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
