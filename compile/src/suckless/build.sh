#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-suckless}"
source /src/common.sh

# pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
# xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"

# 2026-11-25 方案一交叉: suckless(st/dwm/dmenu, make-only 无 configure) 走共享交叉环境(同 x-xbindkeys/v-engrampa)。
# make-only → 无 CROSS_HOST; config.mk 硬编码 "CC = cc"(Makefile 赋值压过 env) → 必须命令行 make $MAKE_CC 顶掉。
# make 命令行 LDFLAGS= 压过 common.sh export 的 env LDFLAGS → sysroot -L 需显式并进 LDFLAGS。
# XS 变量承载交叉专属链接前缀(sysroot -L); native(未设 XX_CROSS_FILE) 时 XS 空 → 原路径零影响。
#   交叉静态传递依赖(X11/xcb/Xau/Xdmcp/Xft/Xrender/freetype/fontconfig 互依赖)用 --start-group 解循环(同 w-scrot/x-xbindkeys)。
suck_cross(){
  MAKE_CC=""; XS=""
  if [ -n "$XX_CROSS_FILE" ]; then
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # sysroot 补静态库(幂等, 已装则 no-op): 顶层 apk add 已覆盖大半, 这里补 dwm/dmenu 额外用到的 X 扩展 .a。
    #   libxext/libxinerama/libxrandr/libxxf86vm/libxcursor 的 .a 随 *-dev 包; libxcb.a 不在 -dev → libxcb-static。
    # 公共库(X11链+font链+X扩展)已由 u-gtk b_deps 统一装(1.4.1); 此处仅留单次 libxxf86vm
    xx-apk add libxxf86vm-dev
    log "suckless: CROSS ($XX_TRIPLE)"
    # 交叉: sysroot -L 前缀(后接各函数原 LDFLAGS 串; 原生已用同一 -l 顺序链接成功, 交叉仅补 ARM .a 搜索路径)
    XS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib"
  fi
}

#
# Build st
#
# Makefile> config.mk
# 
# alpine-apk-st084
# master> v084
# try03, static-build-OK
function st(){
  suck_cross
  log "Downloading ST..."
  rm -rf $SRCROOT/st; # mkdir -p $SRCROOT/st
  # down_catfile ${ST_URL} | tar -zx --strip 1 -C $SRCROOT/st
  ST_VER=br-luke-st
  # https://dl.suckless.org/st/st-0.8.4.tar.gz
  # git://git.suckless.org/st
  gitclone https://gitee.com/g-system/fk-suckless-st $SRCROOT/st --branch=$ST_VER
  log "Configuring ST..."
  cd $SRCROOT/st #&& ./bootstrap;

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
  # $MAKE_CC 命令行顶掉 config.mk 硬编码 CC=cc; $XS 交叉 sysroot -L 前缀(native 空)。
  make $MAKE_CC LDFLAGS="$XS $flags $OB_LIBS -luuid"

  log "Install ST..."
  # make;
  # 2026-11-28: st 的 make install 内含 `tic -sx st.info`(生成 terminfo), 缺 tic 报
  #   "make: tic: No such file or directory" → Error 127(二进制已产出, 仅 terminfo 未装)。
  #   tic 属宿主工具 → 用 native apk(非 xx-apk, 后者按 target arch 装进 sysroot 会把 ARM 的 tic
  #   装到 sysroot/bin, 而 make install 从 PATH 取 native tic)。
  command -v tic >/dev/null 2>&1 || apk add ncurses
  make install;

  # view
  ls -lh $SRCROOT/st/
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/st/st | grep -qE "ARM.*statically linked" || { log "ST file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/st/st || { log "ST xx-verify FAILED"; exit 1; }
  fi
}


DWM_VER=6.2
# Makefile> config.mk
function dwm(){
  suck_cross
  log "Downloading DWM..."
  rm -rf $SRCROOT/dwm; # mkdir -p $SRCROOT/st
  gitclone git://git.suckless.org/dwm $SRCROOT/dwm --branch=$DWM_VER #;
  log "Configuring DWM..."
  cd $SRCROOT/dwm #&& ./bootstrap;

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
  # $MAKE_CC 命令行顶掉 config.mk 硬编码 CC=cc; $XS 交叉 sysroot -L 前缀(native 空)。
  make $MAKE_CC LDFLAGS="$XS $flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"



  log "Install DWM..."
  # make;
  make install;

  # view
  ls -lh $SRCROOT/dwm/
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/dwm/dwm | grep -qE "ARM.*statically linked" || { log "DWM file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/dwm/dwm || { log "DWM xx-verify FAILED"; exit 1; }
  fi
}


# http://git.suckless.org/dmenu/refs.html
# /mnt2/docker-x11base/compile/src/suckless # apk list |grep dmenu
# sxmo-dmenu-doc-5.0.11-r0 x86_64 {sxmo-dmenu} (MIT)
# dmenu-5.0-r0 x86_64 {dmenu} (MIT) [installed]
# dmenu-doc-5.0-r0 x86_64 {dmenu} (MIT)
DMENU_VER=5.0
# Makefile> config.mk
function dmenu(){
  suck_cross
  log "Downloading DMENU..."
  rm -rf $SRCROOT/dmenu; # mkdir -p $SRCROOT/st
  gitclone git://git.suckless.org/dmenu $SRCROOT/dmenu --branch=$DMENU_VER #;
  log "Configuring DMENU..."
  cd $SRCROOT/dmenu #&& ./bootstrap;

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
  # $MAKE_CC 命令行顶掉 config.mk 硬编码 CC=cc; $XS 交叉 sysroot -L 前缀(native 空)。
  make $MAKE_CC LDFLAGS="$XS $flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"

  log "Install DMENU..."
  # make;
  make install;

  # view
  ls -lh $SRCROOT/dmenu/
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/dmenu/dmenu | grep -qE "ARM.*statically linked" || { log "DMENU file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/dmenu/dmenu || { log "DMENU xx-verify FAILED"; exit 1; }
  fi
}



# apk update; apk add git
# fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
# FONTCONFIG_VERSION=2.14.0 @fontconfig/build
# fontconfig
#     glib-dev \
#     g++ \
#     freetype-dev \
#     expat-dev \

# ref: openbox/build
# 公共库(glib/fribidi/harfbuzz/cairo/X11链/font链等)已由 u-gtk b_deps 统一装(1.4.1); 此处仅留工具(g++)
xx-apk --no-cache --no-scripts add \
    g++ \
    || { [ -n "$XX_CROSS_FILE" ] && log "suckless: xx-apk 部分包 aarch64 不可用/冲突(所需 .a 已由 suck_cross 装入 sysroot), 容忍继续"; }

# 

# 
# util-linux-static #util-linux-dev apk-added@yad ##static>> 已并在dev内;

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    doExec st || exit 1
    doExec dwm || exit 1
    doExec dmenu || exit 1
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
