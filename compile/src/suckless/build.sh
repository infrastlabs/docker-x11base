#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


# Define software download URLs.
LIBXRANDR_VERSION=1.5.3
LIBXRANDR_URL=https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VERSION}.tar.xz

gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-st #git clone;
ST_VER=0.8.4
ST_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz
FDKAAC_VER=2.0.2
FDKAAC_URL=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${FDKAAC_VER}.tar.gz

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
# Build libXrandr.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxrandr(){
    echo emp
}


# pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
# xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
# Build st
#
function st(){
# Makefile> config.mk

# alpine-apk-st084
# master> v084
# try03, static-build-OK

# tar -zxf $CACHE/xrdp-${XRDP_VER}.tar.gz -C /tmp;\
# cd /tmp/st-${ver};\
log "Downloading ST..."
rm -rf /tmp/st; # mkdir -p /tmp/st
# down_catfile ${ST_URL} | tar -zx --strip 1 -C /tmp/st
# git clone --depth=1 --branch=$ST_VER https://gitee.com/g-system/fk-suckless-st.git /tmp/st #502err @gitee
# https://dl.suckless.org/st/st-0.8.4.tar.gz
git clone --depth=1 --branch=$ST_VER git://git.suckless.org/st /tmp/st #;
log "Configuring ST..."
cd /tmp/st #&& ./bootstrap;

# PREFIX
sed -i "s^PREFIX =.*^PREFIX = $TARGETPATH^g" config.mk

# OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#  -lXdmcp>> xcb_auth错误没有了; libXft错误没有了; 
#  -lexpat -lxml2 -lz -lbz2 -llzma >> 只剩libfreetype.a(sfnt.o)错误;
#  ref_openbox OB_LIBS全拷贝(冗余)>> 编译过了!!
# /mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp    -lexpat -lxml2 -lz -lbz2 -llzma     -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u


# args-cut
#  /mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o          \
#   -static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
# make LDFLAGS="$flags" \
#   2>&1 |grep musl/10 |awk '{print $2}' |sort -u


# fontconfig-static@apk>> -luuid
# -lXXX预备库变多，并不会增加bin体积;
make LDFLAGS="$flags $OB_LIBS -luuid"

log "Install ST..."
# make;
make install;

# view
ls -lh /tmp/st/
xx-verify --static /tmp/st/st
}


DWM_VER=6.2
function dwm(){
# Makefile> config.mk
# tar -zxf $CACHE/xrdp-${XRDP_VER}.tar.gz -C /tmp;\
# cd /tmp/st-${ver};\
log "Downloading DWM..."
rm -rf /tmp/dwm; # mkdir -p /tmp/st
# down_catfile ${ST_URL} | tar -zx --strip 1 -C /tmp/st
git clone --depth=1 --branch=$DWM_VER git://git.suckless.org/dwm /tmp/dwm #;
log "Configuring DWM..."
cd /tmp/dwm #&& ./bootstrap;

# PREFIX
sed -i "s^PREFIX =.*^PREFIX = $TARGETPATH^g" config.mk

# args-cut
#  /mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o          \
#   -static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
# make LDFLAGS="$flags" 
  #2>&1 |grep musl/10 |awk '{print $2}' |sort -u


# err01:
# /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libXrender.a(Xrender.o):

# xrandr="-lXrandr"
make LDFLAGS="$flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"



log "Install DWM..."
# make;
make install;

# view
ls -lh /tmp/dwm/
xx-verify --static /tmp/dwm/dwm
}


# http://git.suckless.org/dmenu/refs.html
# /mnt2/docker-x11base/compile/src/suckless # apk list |grep dmenu
# sxmo-dmenu-doc-5.0.11-r0 x86_64 {sxmo-dmenu} (MIT)
# dmenu-5.0-r0 x86_64 {dmenu} (MIT) [installed]
# dmenu-doc-5.0-r0 x86_64 {dmenu} (MIT)
DMENU_VER=5.0
function dmenu(){
# Makefile> config.mk
# tar -zxf $CACHE/xrdp-${XRDP_VER}.tar.gz -C /tmp;\
# cd /tmp/st-${ver};\
log "Downloading DMENU..."
rm -rf /tmp/dmenu; # mkdir -p /tmp/st
# down_catfile ${ST_URL} | tar -zx --strip 1 -C /tmp/st
git clone --depth=1 --branch=$DMENU_VER git://git.suckless.org/dmenu /tmp/dmenu #;
log "Configuring DMENU..."
cd /tmp/dmenu #&& ./bootstrap;

# PREFIX
sed -i "s^PREFIX =.*^PREFIX = $TARGETPATH^g" config.mk

# args-cut
#  /mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o          \
#   -static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
# flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon $OB_LIBS"
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
# make LDFLAGS="$flags" 
  #2>&1 |grep musl/10 |awk '{print $2}' |sort -u


# err01:
# /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libXrender.a(Xrender.o):

# handBuild01@oldBuilder_quickTry_01:
# https://gitee.com/xiexie1993/dmenu ##libXinerama
# make LDFLAGS="$flags -lXinerama"
# https://github.com/hajimehoshi/ebiten/blob/2db10b1e9c4be0ae183418301682bad7f0fe4088/internal/glfw/build_linux.go#L6
# make LDFLAGS="$flags -lXinerama   -lX11 -lXrandr -lXxf86vm -lXi -lXcursor -lm -lXinerama -ldl -lrt"

# +-lXext>> OK;
# make LDFLAGS="$flags -lXinerama   -lX11 -lXrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext"


# # gitac>> handBuild02@newBuilder_02:
# fontconfig-static@apk>> -luuid 
# xrandr="-lXrandr"
make LDFLAGS="$flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"

log "Install DMENU..."
# make;
make install;

# view
ls -lh /tmp/dmenu/
xx-verify --static /tmp/dmenu/dmenu
}



# apk update; apk add git
# fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
# FONTCONFIG_VERSION=2.14.0 @fontconfig/build
apk add fontconfig-dev fontconfig-static
# fontconfig
#     glib-dev \
#     g++ \
#     freetype-dev \
#     expat-dev \

# ref: openbox/build
xx-apk --no-cache --no-scripts add \
    g++ \
    glib-dev \
    glib-static \
    fribidi-dev \
    fribidi-static \
    harfbuzz-dev \
    harfbuzz-static \
    cairo-dev \
    cairo-static \
    libxft-dev \
    libxml2-dev \
    libx11-dev \
    libx11-static \
    libxcb-static \
    libxdmcp-dev \
    libxau-dev \
    freetype-static \
    expat-static \
    libpng-dev \
    libpng-static \
    zlib-static \
    bzip2-static \
    pcre-dev \
    libxrender-dev \
    graphite2-static \
    libffi-dev \
    xz-dev \
    brotli-static \

# 
apk add libxcursor-dev #Xrandr@xrdp;

# 
apk add util-linux-dev 
# util-linux-static #util-linux-dev apk-added@yad ##static>> 已并在dev内;

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    # libxrandr
    # fdkaac
    st
    dwm
    dmenu
    ;;
# b_deps)
#     /src/xrdp/build.sh libxrandr &
#     /src/xrdp/build.sh fdkaac &
#     wait
#     ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/suckless-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
