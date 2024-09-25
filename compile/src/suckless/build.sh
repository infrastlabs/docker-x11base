#!/bin/sh
set -e
source /src/common.sh

# pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
# xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 

#
# Build st
#
# Makefile> config.mk
# 
# alpine-apk-st084
# master> v084
# try03, static-build-OK
function st(){
  log "Downloading ST..."
  rm -rf /tmp/st; # mkdir -p /tmp/st
  # down_catfile ${ST_URL} | tar -zx --strip 1 -C /tmp/st
  ST_VER=br-luke-st
  # https://dl.suckless.org/st/st-0.8.4.tar.gz
  # git clone --depth=1 --branch=$ST_VER git://git.suckless.org/st /tmp/st #;
  git clone --depth=1 --branch=$ST_VER https://gitee.com/g-system/fk-suckless-st /tmp/st
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
# Makefile> config.mk
function dwm(){
  log "Downloading DWM..."
  rm -rf /tmp/dwm; # mkdir -p /tmp/st
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
# Makefile> config.mk
function dmenu(){
  log "Downloading DMENU..."
  rm -rf /tmp/dmenu; # mkdir -p /tmp/st
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
    ;;
full)
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
    oneBuild $1
    ;;          
esac
exit 0
