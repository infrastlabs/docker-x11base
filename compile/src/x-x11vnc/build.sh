#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-x11vnc}"
source /src/common.sh

# Define software download URLs.
gh=https://ghproxy.com/
gh=https://gh.api.99988866.xyz/
gh=https://ghps.cc/
gh=https://ghfast.top/


#
# Build libvncserver
#
function libvncserver(){
  # mkdir -p /tmp/libvncserver
  log "Downloading LIBVNCSERVER..."
  # down_catfile ${LIBVNCSERVER_URL} | tar -zx --strip 1 -C /tmp/libvncserver #| tar -xJ
  rm -rf /tmp/libvncserver
  gitclone https://gitee.com/g-system/fk-libvnc-libvncserver /tmp/libvncserver --branch=LibVNCServer-0.9.13
  log "Configuring LIBVNCSERVER..."
  cd /tmp/libvncserver
  # 交叉(aarch64/armv7): cmake 交叉编译出 ARM libvncserver.a/libvncclient.a → 手动装 sysroot。
  #   不整 make/make install——那会连带编 examples(client_examples/backchannel 等)+test/* 可执行,
  #   它们交叉 link 失败(host ld + ARM libpng.so "wrong format")。x11vnc 只需两个 .a + 头。
  #   → 只 make 库 target, 再手动 install .a + 头(native 走原 make install)。
  # native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
  if [ -n "$XX_CROSS_FILE" ]; then
    xx-apk add openssl-dev openssl-libs-static zlib-static zlib-dev lz4-static lz4-dev 2>/dev/null || true
    mkdir -p build && cd build
    cmake .. \
      -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=$(xx-info march) \
      -DCMAKE_C_COMPILER=xx-clang \
      -DCMAKE_FIND_ROOT_PATH=$XX_SYSROOT \
      -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
      -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
      -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON \
      -DWITH_X11=OFF -DWITH_GNUTLS=OFF -DWITH_OPENSSL=ON -DWITH_GCRYPT=OFF \
      -DWITH_ZLIB=ON -DWITH_LZ4=ON -DWITH_THREADS=ON \
      -DWITH_GTK=OFF -DWITH_SDL=OFF -DWITH_FFMPEG=OFF \
      -DBUILD_TESTS=OFF > /tmp/lv_cmake.log 2>&1 \
      || { log "LIBVNCSERVER cross cmake FAILED"; tail -20 /tmp/lv_cmake.log; exit 1; }
    log "Compiling LIBVNCSERVER libs (cross)..."
    # 只编两个库 target(跳过 examples/tests 可执行)
    make vncserver vncclient -j$(nproc) > /tmp/lv_make.log 2>&1 \
      || { log "LIBVNCSERVER cross make FAILED"; tail -20 /tmp/lv_make.log; exit 1; }
    log "Installing LIBVNCSERVER libs+headers (cross -> sysroot)..."
    for _a in libvncserver libvncclient; do
      _f=$(find . -name "$_a.a" | head -1)
      [ -n "$_f" ] && cp -av "$_f" "$XX_SYSROOT/usr/lib/"
    done
    # 头: 源码 rfb/ + 构建期生成的 rfb/rfbconfig.h(x11vnc 编译需 rfb/rfbconfig.h)
    cp -av ../rfb "$XX_SYSROOT/usr/include/" 2>/dev/null
    cp -av ./rfb/rfbconfig.h "$XX_SYSROOT/usr/include/rfb/" 2>/dev/null
    # .pc 文件(lib-only 装 .a 不含)→ pkg-config 需 libvncserver.pc/libvncclient.pc
    find . -name "*.pc" -exec cp -av {} "$XX_SYSROOT/usr/lib/pkgconfig/" \; 2>/dev/null
    xx_la_fix
    test -f "$XX_SYSROOT/usr/lib/libvncserver.a" || { log "LIBVNCSERVER: sysroot 缺 libvncserver.a"; exit 1; }
    find $XX_SYSROOT |egrep "libvnc.*\.a$"
    cd /tmp/libvncserver
    return 0
  fi
  # native: 装入构建容器 build-arch /usr
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
  # 2026-11-25 交叉: autotools 交叉环境(同 w-tint2 libxi/openbox)——--host 交叉、装 sysroot。
  # native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响(native 装 build-arch /usr)。
  CROSS_HOST=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    x11vnc_cross   # 共享交叉环境: PKG_CONFIG_LIBDIR 指 sysroot(否则 configure 找不到 xi/xtst.pc)
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    # 交叉下 autotools run-test 不能跑(ARM 测试二进制不能在 x86 跑)→ 缓存变量跳过(同 w-tint2 libxi)
    export ac_cv_prog_cc_cross=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export xorg_cv_malloc0_returns_null=no
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    log "libxtst: CROSS ($XX_TRIPLE)"
  fi
  # mkdir -p /tmp/libxtst
  log "Downloading LIBXTST..."
  rm -rf /tmp/libxtst
  # down_catfile ${LIBXTST_URL} | tar -zx --strip 1 -C /tmp/libxtst #| tar -xJ
  gitclone https://gitee.com/g-system/fk-xorg-libxtst /tmp/libxtst --branch=libXtst-1.2.3
  log "Configuring LIBXTST..."
  cd /tmp/libxtst && autoreconf -fiv && ./configure --enable-static $CROSS_HOST
  log "Compiling LIBXTST..."
  make
  log "Installing LIBXTST..."
  make install $XX_DESTDIR
  # view
  find /tmp/libxtst |egrep "\.a$"
  find /usr |egrep "libXtst\.a$"
}
#   sysroot 内的 ARM 静态库, 这里只补 apk 有包的部分; libvncserver.a 无 apk 静态包 → 见下 test。
x11vnc_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # sysroot 补 X11/ssl/zlib 静态库(幂等; apk 命中已装则 no-op)
    xx-apk add libx11-dev libx11-static libxext-dev libxrandr-dev libxdamage-dev \
      libxfixes-dev libxinerama-dev libxcursor-dev libxtst-dev libxi-dev xorgproto \
      zlib-static libxcb-dev libxcb-static 2>/dev/null || true
    # libXrandr.a: apk 无对应包 → 借 openbox 的 libxrandr()(cross-aware, 装到 sysroot)
    test -f "$XX_SYSROOT/usr/lib/libXrandr.a" || bash /src/openbox/build.sh libxrandr
    # libvncserver.a: apk 只有 .so 无静态包, 上面 libvncserver() native 装 build-arch /usr
    #   → 交叉下 sysroot 缺 ARM libvncserver.a, configure 的 libvncserver>=0.9.8 检测会失败。
    #   缺则用交叉环境重编 libvncserver 装入 sysroot(b_deps 已并行编过则这里 no-op)。
    test -f "$XX_SYSROOT/usr/lib/libvncserver.a" \
      || bash /src/x-x11vnc/build.sh libvncserver
    log "x11vnc: CROSS ($XX_TRIPLE)"
  fi
}

#
# Build x11vnc
#
function x11vnc(){
  x11vnc_cross
  apk add lzo-dev #libvncserver-dev带入: lzo-dev openssl-dev ##缺依赖项时, LIBS="xx" ./configure报gcc错误
  apk add openssl-dev openssl-libs-static
  apk add xorg-server-dev
  # configure: error: Package requirements (libvncserver >= 0.9.8) were not met:
  apk add libvncserver-dev

  log "Downloading X11VNC..."
  rm -rf /tmp/x11vnc; mkdir -p /tmp/x11vnc
  # down_catfile ${X11VNC_URL} | tar -zx --strip 1 -C /tmp/x11vnc
  gitclone https://gitee.com/g-system/fk-libvnc-x11vnc /tmp/x11vnc --branch=fix-152

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
   # 交叉: LDFLAGS 前置 sysroot usr/lib+usr/local/lib 的 -L(含 libXtst.a/libvncserver.a 所在),
    #   否则 configure link-test 找不到 -lXtst → "C compiler cannot create executables"。native 不动。
    LDFLAGS="${XX_CROSS_FILE:+-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib }-static" LIBS="$LIBS2" ./configure \
    $CROSS_HOST \
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
  make $MAKE_CC; #直接make即可; 带static,带LIBS
  log "install X11VNC..."
  make $MAKE_CC install;

  # view
  ls -lh /tmp/x11vnc/src/x11vnc
  # 交叉真验: xx-verify 按构建架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判
  #   static + 目标架构; native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file /tmp/x11vnc/src/x11vnc | grep -qE "ARM.*statically linked" \
      || { log "X11VNC file 非 ARM static"; exit 1; }
  else
    xx-verify --static /tmp/x11vnc/src/x11vnc || { log "X11VNC xx-verify FAILED"; exit 1; }
  fi
}


case "$1" in
cache)
    # down_catfile ${X11VNC_URL} > /dev/null
    ;;
full)
    doExec libvncserver || exit 1
    doExec libxtst || exit 1
    doExec x11vnc || exit 1
    ;;
b_deps)
    doExec_mark "x-x11vnc b_deps grp"
    doExec bash /src/x-x11vnc/build.sh libvncserver &
    doExec bash /src/x-x11vnc/build.sh libxtst &
    doExec bash /src/w-tint2/build.sh libxi &
    wait
    doExec_check || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
