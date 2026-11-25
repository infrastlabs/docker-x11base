#!/bin/sh
set -e
source /src/common.sh

#
# Build fluxbox
#

# 2026-11-25 交叉: fluxbox(C++/autotools) 走共享交叉环境(同 x-xbindkeys/x-xrandr/openbox)。
# 本脚本(build.sh.xft.sh)是 Dockerfile 实调的(--enable-imlib2); imlib2 静态库两 sysroot 已有(ARM)。
# fluxbox=C++ → 除 CC 外还须 CXX=xx-clang++ + ac_cv_prog_cxx_cross=yes。
# libtool 链接会经 sysroot .la 的 dependency_libs/libdir 拖入原生 .a(x86) → 须清洗(同 openbox 4.7.1)。
# native(未设 XX_CROSS_FILE): CROSS_HOST/MAKE_CC 留空 → 原路径零影响。
fb_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export CXX=xx-clang++            # fluxbox=C++: 交叉须 C++ 编译器
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    export ac_cv_prog_cxx_cross=yes   # C++ 交叉: configure cxx link-test 亦不能 run
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # armv7: Ewmh.cc 等 C++11 narrowing(unsigned int→long)被 clang 当 error → 交叉下关掉该诊断
    #   (arm64 不触发; 仅 cross 生效, native 零影响)。
    export CXXFLAGS="-Wno-c++11-narrowing $CXXFLAGS"
    # sysroot 补 fribidi/xpm/xml2/X11 静态库(幂等)
    xx-apk add fribidi-dev fribidi-static libxpm-dev libxml2-dev expat-static \
      fontconfig-dev fontconfig-static freetype-dev \
      libx11-dev libx11-static libxext-dev libxrender-dev libxau-dev libxdmcp-dev libxcb-dev libxcb-static \
      libxrandr-dev libxinerama-dev 2>/dev/null || true
    # libXrandr.a 无 apk 包 → 源码构建到 sysroot(同 x-xrandr/openbox); 幂等
    test -f "$XX_SYSROOT/usr/lib/libXrandr.a" || bash /src/openbox/build.sh libxrandr
    # 清洗 sysroot .la(防 libtool 拖原生 .a): 注释 dependency_libs + 裸 libdir 补 sysroot 前缀(幂等)
    find "$XX_SYSROOT/usr/lib" "$XX_SYSROOT/usr/local/lib" -maxdepth 1 -name "*.la" 2>/dev/null | while read -r _la; do
      sed -i 's/^dependency_libs=/#dependency_libs=/' "$_la"
      sed -i "s|^libdir='/usr/|libdir='$XX_SYSROOT/usr/|" "$_la"
      sed -i "s|^libdir='/lib/|libdir='$XX_SYSROOT/lib/|" "$_la"
    done
    log "fluxbox: CROSS ($XX_TRIPLE)"
  fi
}

function fluxbox(){
  fb_cross
  apk add libxml2-dev expat-static 

  log "Downloading FLUXBOX..."
  rm -rf /tmp/fluxbox; # mkdir -p /tmp/fluxbox
  # down_catfile ${FLUXBOX_URL} | tar -zx --strip 1 -C /tmp/fluxbox
  # https://dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz
  # branch="--branch=$FLUXBOX_VER"
  gitclone https://gitee.com/g-system/fk-fluxbox /tmp/fluxbox $branch #;
  log "Configuring FLUXBOX..."
  cd /tmp/fluxbox #&& ./bootstrap;

  # ref: suckless/build.sh
  # OB_LIBS=""
  # flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  imlib="-lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm -luuid "
  EX_LIBS="$flags $OB_LIBS -lXinerama $imlib   -lX11 -lfontconfig -lfreetype -lXext -lXrandr" # -lrt

  # CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4
  # --disable-docs #https://github.com/BtbN/FFmpeg-Builds/blob/7b6432add41f4f8a47592f1e1de73ca182e4cc5c/scripts.d/35-fontconfig.sh#L3
  autoreconf -fi

  # --disable-remember \
  # Xinerama扩展的多屏显示
  # configure: WARNING: unrecognized options: --disable-docs, --enable-static, --disable-shared
  # ./configure \
  #   --prefix=$TARGETPATH \
  #   --enable-xmb \
  #   --enable-slit \
  #   --enable-toolbar \
  #   --enable-fribidi \
  #   \
  #   --enable-imlib2 \
  #   --disable-nls \
  #   --enable-xft \
  #   --enable-xinerama
  #   \
  #   --disable-docs \
  #   --enable-static \
  #   --disable-shared \
  #   LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS" #$EX_LIBS
  #   #LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"

  # ref: ./configure -h
  ./configure \
    --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
    --host=$(xx-info triple) \
    --prefix=$TARGETPATH \
    --disable-dependency-tracking \
    --disable-silent-rules \
    --enable-remember=yes \
    --enable-regexp=yes \
    --enable-slit=yes \
    --enable-systray=yes \
    --enable-toolbar=yes \
    --enable-ewmh=yes \
    --enable-debug=no \
    --enable-test=no \
    --enable-nls=no \
    --enable-timedcache=yes \
    --enable-xmb=yes \
    \
    --enable-imlib2 \
    --enable-freetype2 \
    --enable-xrender   \
    --enable-xft       \
    --enable-xpm       \
    --enable-xext      \
    --enable-xrandr    \
    --enable-fribidi   \
    --enable-xinerama=no
    

  make clean
  if [ -n "$XX_CROSS_FILE" ]; then
    # 交叉: 静态传递依赖 --start-group 解循环; 不 clobber LDFLAGS(用 $LDFLAGS 追加 sysroot -L)。
    FB_LIBS="-Wl,--start-group -lX11 -lXext -lXrandr -lXrender -lxcb -lXau -lXdmcp -lXinerama \
      -lImlib2 -lX11-xcb -lxcb-shm -lfribidi -lfontconfig -lfreetype -lXft -lXpm \
      -lexpat -lxml2 -luuid -lpng -lz -lbz2 -lbrotlidec -lbrotlicommon -lpthread -lm -Wl,--end-group"
    make $MAKE_CC LDFLAGS="$LDFLAGS -static" LIBS="$FB_LIBS" \
      || { log "FLUXBOX cross build FAILED"; exit 1; }
  else
    make LDFLAGS="-static" LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"
  fi

  log "Install FLUXBOX..."
  # make;
  make install;

  # view
  ls -lh /tmp/fluxbox/
  if [ -n "$XX_CROSS_FILE" ]; then
    file /tmp/fluxbox/fluxbox | grep -qE "ARM.*statically linked" \
      || { log "FLUXBOX file 非 ARM static"; exit 1; }
  else
    xx-verify --static /tmp/fluxbox/fluxbox || { log "FLUXBOX xx-verify FAILED"; exit 1; }
  fi
}


# libxpm-dev: --enable-xpm; /usr/lib/libXpm.a
apk add fribidi-dev fribidi-static \
  libxpm-dev

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
    oneBuild $1
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
