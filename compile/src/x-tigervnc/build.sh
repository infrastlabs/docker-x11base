#!/bin/sh
# NOTE: This script is expected to be run under Alpine Linux.
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-tigervnc}"
source /src/common.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define software versions.
TIGERVNC_VERSION=1.13.1
XSERVER_VERSION=1.20.14
# @ubt2004
# TIGERVNC_VERSION=1.12.0
# XSERVER_VERSION=1.20.7


# root@10155d90a9ce:$SRCROOT/tigervnc/unix/xserver# dpkg -l |egrep "gnutls|xfont2|fontenc|tasn|shmf" |egrep "dev|shmf|xfont2"
# ii  libfontenc-dev:amd64            1:1.1.4-1                      amd64        X11 font encoding library (development headers)
# ii  libgnutls28-dev:amd64           3.7.9-2                        amd64        GNU TLS library - development files
# ii  libtasn1-6-dev:amd64            4.19.0-2                       amd64        Manage ASN.1 structures (development)
# ii  libxfont2:amd64                 1:2.0.6-1                      amd64        X11 font rasterisation library
# ii  libxshmfence1:amd64             1.3-1                          amd64        X shared memory fences - shared library

# Use the same versions has Alpine 3.15.
# deb12|ubt|alpine
# 3.6.13-2ubuntu1.8
GNUTLS_VERSION=3.7.1 #3.7.9|3.6.13|3.7.1
# 1:2.0.3-1 ##dpkg -l |egrep "font"
LIBXFONT2_VERSION=2.0.5 #2.0.6|2.0.3|2.0.5
# 1:1.1.4-0ubuntu1
LIBFONTENC_VERSION=1.1.4 #OK
# 4.16.0-2
LIBTASN1_VERSION=4.18.0 #4.19.0|4.16.0|4.18.0
# 1.3-1
LIBXSHMFENCE_VERSION=1.3 #OK

# If the XKeyboardConfig version is too recent compared to xorgproto/libX11,
# xkbcomp will complain with warnings like "Could not resolve keysym ...".  With
# Alpine 3.15, XKeyboardConfig version 2.32 is the latest version that doesn't
# produces these warnings.
XKEYBOARDCONFIG_VERSION=2.32
XKBCOMP_VERSION=1.4.5

# Define software download URLs.
# https://ghproxy.com/ @23.10.21
# https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1
# TIGERVNC_URL=https://ghfast.top/https://github.com/TigerVNC/tigervnc/archive/v${TIGERVNC_VERSION}.tar.gz
# XSERVER_URL=https://www.x.org/releases/individual/xserver/xorg-server-${XSERVER_VERSION}.tar.gz
TIGERVNC_URL=https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/tigervnc-${TIGERVNC_VERSION}.tar.gz #tigervnc-1.13.1.tar.gz 
XSERVER_URL=https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/xorg-server-${XSERVER_VERSION}.tar.gz

# https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1
GNUTLS_URL=https://www.gnupg.org/ftp/gcrypt/gnutls/v${GNUTLS_VERSION%.*}/gnutls-${GNUTLS_VERSION}.tar.xz
# LIBTASN1_URL=https://ftp.gnu.org/gnu/libtasn1/libtasn1-${LIBTASN1_VERSION}.tar.gz
LIBTASN1_URL=https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/libtasn1-${LIBTASN1_VERSION}.tar.gz
LIBXFONT2_URL=https://www.x.org/pub/individual/lib/libXfont2-${LIBXFONT2_VERSION}.tar.gz
# LIBFONTENC_URL=https://www.x.org/releases/individual/lib/libfontenc-${LIBFONTENC_VERSION}.tar.gz
LIBFONTENC_URL=https://gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/libfontenc-${LIBFONTENC_VERSION}.tar.gz
LIBXSHMFENCE_URL=https://www.x.org/releases/individual/lib/libxshmfence-${LIBXSHMFENCE_VERSION}.tar.gz

XKEYBOARDCONFIG_URL=https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-${XKEYBOARDCONFIG_VERSION}.tar.bz2
XKBCOMP_URL=https://www.x.org/releases/individual/app/xkbcomp-${XKBCOMP_VERSION}.tar.bz2


# set -u; err if not exist
test -z "$TARGETPATH" && export TARGETPATH=/opt/base
ROOT_DEST_DIR="/" #/tmp/xx-install> /
INS_PREFIX=$TARGETPATH
# 
XKB_DEST_DIR="$SRCROOT/xkb-install" #final: $SRCROOT/xkb-install/usr/local/share/X11/xkb> /usr/local/static/tigervnc/usr/local/share/X11/xkb
XKB_REF_PATH=$TARGETPATH

#
# Install required packages.
#
# log "Installing required Alpine packages..."
# apk --no-cache add \
#     curl \
#     build-base \
#     clang \
#     cmake \
#     autoconf \
#     automake \
#     libtool \
#     pkgconf \
#     meson \
#     util-macros \
#     font-util-dev \
#     xtrans \

# xx-apk --no-cache --no-scripts add \
#     g++ \
#     xcb-util-dev \
#     pixman-dev \
#     libx11-dev \
#     libgcrypt-dev \
#     libgcrypt-static \
#     libgpg-error-static \
#     libxkbfile-dev \
#     libxfont2-dev \
#     libjpeg-turbo-dev \
#     nettle-dev \
#     libunistring-dev \
#     gnutls-dev \
#     fltk-dev \
#     libxrandr-dev \
#     libxtst-dev \
#     freetype-dev \
#     libfontenc-dev \
#     zlib-dev \
#     libx11-static \
#     libxcb-static \
#     zlib-static \
#     pixman-static \
#     libjpeg-turbo-static \
#     freetype-static \
#     libpng-static \
#     bzip2-static \
#     brotli-static \
#     libunistring-static \
#     nettle-static \
#     gettext-static \
#     libunistring-dev \
#     libbsd-dev \

#
# Build GNU TLS.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function gnutls(){
  tigervnc_cross
  mkdir -p $SRCROOT/gnutls
  log "Downloading GNU TLS..."
  down_catfile ${GNUTLS_URL} | tar -xJ --strip 1 -C $SRCROOT/gnutls
  log "Configuring GNU TLS..."
  (
      cd $SRCROOT/gnutls && ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$(xx-info triple) \
          $CROSS_HOST \
          --disable-openssl-compatibility \
          --disable-rpath \
          --disable-guile \
          --disable-valgrind-tests \
          --disable-cxx \
          --without-p11-kit \
          --disable-tools \
          --disable-doc \
          --enable-static \
          --disable-shared \
  )
  log "Compiling GNU TLS..."
  make $MAKE_CC -C $SRCROOT/gnutls -j$(nproc)
  log "Installing GNU TLS..."
  make DESTDIR=$XX_SYSROOT -C $SRCROOT/gnutls install
}

#
# Build libXfont2
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxfont2(){
  tigervnc_cross
  mkdir -p $SRCROOT/libxfont2
  log "Downloading libXfont2..."
  down_catfile ${LIBXFONT2_URL} | tar -xz --strip 1 -C $SRCROOT/libxfont2
  log "Configuring libXfont2..."
  (
      cd $SRCROOT/libxfont2 && ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$(xx-info triple) \
          $CROSS_HOST \
          --without-fop \
          --without-xmlto \
          --disable-devel-docs \
          --enable-static \
          --disable-shared \
  )
  log "Compiling libXfont2..."
  sed 's/^noinst_PROGRAMS = /#noinst_PROGRAMS = /' -i $SRCROOT/libxfont2/Makefile.in
  make $MAKE_CC -C $SRCROOT/libxfont2 -j$(nproc)
  log "Installing libXfont2..."
  make DESTDIR=$XX_SYSROOT -C $SRCROOT/libxfont2 install
}

#
# Build libfontenc
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libfontenc(){
  tigervnc_cross
  mkdir -p $SRCROOT/libfontenc
  log "Downloading libfontenc..."
  down_catfile ${LIBFONTENC_URL} | tar -xz --strip 1 -C $SRCROOT/libfontenc
  log "Configuring libfontenc..."
  (
      cd $SRCROOT/libfontenc && ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$(xx-info triple) \
          $CROSS_HOST \
          --with-encodingsdir=/usr/share/fonts/encodings \
          --enable-static \
          --disable-shared \
  )
  log "Compiling libfontenc..."
  make $MAKE_CC -C $SRCROOT/libfontenc -j$(nproc)
  log "Installing libfontenc..."
  make DESTDIR=$XX_SYSROOT -C $SRCROOT/libfontenc install
}

#
# Build libtasn1
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libtasn1(){
  tigervnc_cross
  mkdir -p $SRCROOT/libtasn1
  log "Downloading libtasn1..."
  down_catfile ${LIBTASN1_URL} | tar -xz --strip 1 -C $SRCROOT/libtasn1
  log "Configuring libtasn1..."
  (
      cd $SRCROOT/libtasn1 && CFLAGS="$CFLAGS -Wno-error=inline" ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$(xx-info triple) \
          $CROSS_HOST \
          --enable-static \
          --disable-shared \
  )
  log "Compiling libtasn1..."
  make $MAKE_CC -C $SRCROOT/libtasn1 -j$(nproc)
  log "Installing libtasn1..."
  make DESTDIR=$XX_SYSROOT -C $SRCROOT/libtasn1 install
}

#
# Build libxshmfence
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxshmfence(){
  tigervnc_cross
  mkdir -p $SRCROOT/libxshmfence
  log "Downloading libxshmfence..."
  down_catfile ${LIBXSHMFENCE_URL} | tar -xz --strip 1 -C $SRCROOT/libxshmfence
  log "Configuring libxshmfence..."
  (
      cd $SRCROOT/libxshmfence && ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$(xx-info triple) \
          $CROSS_HOST \
          --enable-static \
          --disable-shared \
          --enable-futex \
  )
  log "Compiling libxshmfence..."
  make $MAKE_CC -C $SRCROOT/libxshmfence -j$(nproc)
  log "Installing libxshmfence..."
  make DESTDIR=$XX_SYSROOT -C $SRCROOT/libxshmfence install
}

# libxkbfile: 直接用 sysroot apk 包（libxkbfile-dev，无需源码建）

#

#
# 2026-11-25 交叉(arm64/armv7 via xx-clang): 参 x-xbindkeys xbk_cross 共享环境。
# native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
# 注: gnutls/libxfont2/libfontenc/libtasn1/libxshmfence 子构建已自带
#   --host=$(xx-clang --print-target-triple)(native 也如此)→ 无需 CROSS_HOST。
# xkb 走 meson(需 --cross-file)本脚本未接 → 交叉下 xkb 保持原样(见 uncertainties)。
tigervnc_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    # xx-info sysroot 在 Alpine 里返回 / 而非真实 sysroot；
    # 直接从 cross-file 读 sys_root 更可靠（tigervnc_cross 被所有子构建复用）。
    XX_SYSROOT="${XX_SYSROOT:-$(grep "sys_root" "$XX_CROSS_FILE" 2>/dev/null | head -1 | sed "s/.*= *'\\([^']*\\)'.*/\\1/; s/\\/$//")}"
    export XX_SYSROOT
    # xx-clang/xx-info 认的是 TARGETPLATFORM(非 XX_CROSS_FILE)，必须在此 export，
    # 否则退回宿主 x86_64（vncpasswd/Xvnc 会被编成 x86-64）。
    _march="$(grep "^cpu_family" "$XX_CROSS_FILE" 2>/dev/null | head -1 | sed "s/.*= *'\\([^']*\\)'.*/\\1/")"
    case "$_march" in
      aarch64) _tpf="linux/arm64" ;;
      arm|armv7l) _tpf="linux/arm/v7" ;;
      *)       _tpf="linux/$_march" ;;
    esac
    TARGETPLATFORM="${TARGETPLATFORM:-$_tpf}"
    export TARGETPLATFORM
    XX_TRIPLE="$(xx-info triple 2>/dev/null)"
    [ -z "$XX_TRIPLE" ] && XX_TRIPLE="$(grep "^cpu" "$XX_CROSS_FILE" 2>/dev/null | head -1 | sed "s/.*= *'\\(.*\\)'/\\1/")"
    export XX_TRIPLE
    export XX_MARCH="${XX_MARCH:-$_march}"
    CROSS_HOST="--host=$XX_TRIPLE"
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
    # sysroot 补 X11/字体/压缩等静态库(幂等; apk 命中已装则 no-op)
    # 注意: libtasn1-static / brotli-static 在 sysroot APKINDEX 里不存在，
    # 但 libtasn1(.so)/libbrotli*.a 已随其他包装入，用 test 幂等跳过。
    # 公共库(X11链/font链/libpng/brotli/bzip2/zlib/libbsd/libmd/libjpeg/libxkbcommon/pixman)已由 u-gtk 统一装(1.4.1); 此处仅留单次(加密链/字体/驱动)
    xx-apk add \
      nettle-dev nettle-static libunistring-dev libunistring-static \
      libtasn1-dev libfontenc-dev libxshmfence-dev libxkbfile-dev 2>/dev/null || true
    # brotli-static 已由 u-gtk 统一装(1.4.1)
    # libXrandr.a: apk 无对应包 → 借 openbox 的 libxrandr()(cross-aware, 装到 sysroot)
    test -f "$XX_SYSROOT/usr/lib/libXrandr.a" || bash /src/openbox/build.sh libxrandr
    log "tigervnc: CROSS ($XX_TRIPLE)"
  fi
}

#
# Build TigerVNC
#
function tigervnc(){
  tigervnc_cross
  rm -rf $SRCROOT/tigervnc; mkdir -p $SRCROOT/tigervnc
  log "Downloading TigerVNC..."
  down_catfile ${TIGERVNC_URL} | tar -xz --strip 1 -C $SRCROOT/tigervnc
  log "Downloading Xorg server..."
  down_catfile ${XSERVER_URL} | tar -xz --strip 1 -C $SRCROOT/tigervnc/unix/xserver

  log "Patching TigerVNC..."
  # Apply the TigerVNC patch against the X server.
  patch -p1 -d $SRCROOT/tigervnc/unix/xserver < $SRCROOT/tigervnc/unix/xserver120.patch

  # Build a static binary of vncpasswd.
  patch -p1 -d $SRCROOT/tigervnc < "$SCRIPT_DIR"/vncpasswd-static.patch
  # Disable PAM support.
  patch -p1 -d $SRCROOT/tigervnc < "$SCRIPT_DIR"/disable-pam.patch
  # Fix static build.
  patch -p1 -d $SRCROOT/tigervnc < "$SCRIPT_DIR"/static-build.patch
  # patch -p1 -d $SRCROOT/tigervnc < "$SCRIPT_DIR"/tigervnc-1.12.0-configuration_fixes-1.patch

  log "Configuring TigerVNC..."
  (
      # https://github.com/TigerVNC/tigervnc/issues/998
      # -DENABLE_GNUTLS=ON \
      cd $SRCROOT/tigervnc && cmake -G "Unix Makefiles" \
          $(xx-clang --print-cmake-defines) \
          -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
          -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
          -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
          -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
          -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
          -DCMAKE_INSTALL_PREFIX=$INS_PREFIX \
          -DCMAKE_BUILD_TYPE=Release \
          -DINSTALL_SYSTEMD_UNITS=OFF \
          -DENABLE_NLS=OFF \
          -DENABLE_GNUTLS=OFF \
          -DENABLE_NETTLE=ON \
          -DBUILD_VIEWER=OFF \
  )

  log "Compiling TigerVNC common libraries and tools..."
  make $MAKE_CC -C $SRCROOT/tigervnc/common -j$(nproc)
  make $MAKE_CC -C $SRCROOT/tigervnc/unix/common -j$(nproc)
  make $MAKE_CC -C $SRCROOT/tigervnc/unix/vncpasswd -j$(nproc)

  log "Configuring TigerVNC server..."
  autoreconf -fiv $SRCROOT/tigervnc/unix/xserver
  (
      cd $SRCROOT/tigervnc/unix/xserver && CFLAGS="$CFLAGS -Wno-implicit-function-declaration" ./configure \
          --build=$(TARGETPLATFORM='' xx-info triple) \
          --host=$XX_TRIPLE \
          --prefix=$INS_PREFIX \
          $CROSS_HOST \
          --sysconfdir=/etc/X11 \
          --localstatedir=/var \
          --with-xkb-path=${XKB_REF_PATH}/share/X11/xkb \
          --with-xkb-output=/var/lib/xkb \
          --with-xkb-bin-directory=${XKB_REF_PATH}/bin \
          --with-default-font-path=/usr/share/fonts/misc,/usr/share/fonts/100dpi:unscaled,/usr/share/fonts/75dpi:unscaled,/usr/share/fonts/TTF,/usr/share/fonts/Type1 \
          --disable-docs \
          --disable-unit-tests \
          --without-dtrace \
          \
          --with-pic \
          --disable-static \
          --disable-shared \
          \
          --disable-listen-tcp \
          --enable-listen-unix \
          --disable-listen-local \
          \
          --disable-dpms \
          \
          --disable-systemd-logind \
          --disable-config-hal \
          --disable-config-udev \
          --disable-xorg \
          --disable-dmx \
          --disable-libdrm \
          --disable-dri \
          --disable-dri2 \
          --disable-dri3 \
          --disable-present \
          --disable-xvfb \
          --disable-glx \
          --disable-xinerama \
          --disable-record \
          --disable-xf86vidmode \
          --disable-xnest \
          --disable-xquartz \
          --disable-xwayland \
          --disable-xwayland-eglstream \
          --disable-standalone-xpbproxy \
          --disable-xwin \
          --disable-glamor \
          --disable-kdrive \
          --disable-xephyr \
  )

  # Remove all automatic dependencies on libraries and manually define them to
  # have the correct order.
  find $SRCROOT/tigervnc -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'
  # 交叉: sysroot 里 .la 的 libdir 是裸 /usr/local/lib(libtool 在依赖构建时被 DESTDIR 剥掉前缀)
  #   → xserver 链接经 libtool 解析 -lfontenc/-ltasn1 等时找裸 /usr/local/lib/*.a(clang 找不到)。
  #   给 sysroot 的 .la libdir 补 sysroot 前缀。native(XX_CROSS_FILE 空)跳过, .la 不动。
  if [ -n "$XX_CROSS_FILE" ]; then
    find "$XX_SYSROOT/usr/local/lib" "$XX_SYSROOT/usr/lib" -maxdepth 1 -name "*.la" \
      -exec sed -i "s|^libdir='|libdir='$XX_SYSROOT|" {} '+' 2>/dev/null
    log "tigervnc: sysroot .la libdir 加 sysroot 前缀($XX_SYSROOT)"
    # xserver configure 经 pkg-config 探测得到裸 -L/usr/local/lib(容器 amd64 真实目录，
    #   内有同名 .la/libXfont2 等 → libtool 优先命中并拼出裸 .a 路径)。
    #   交叉下换成 sysroot 的两个 -L，避免命中容器 amd64 库。
    find $SRCROOT/tigervnc/unix/xserver -name "Makefile" \
      -exec sed -i "s|-L/usr/local/lib|-L$XX_SYSROOT/usr/local/lib -L$XX_SYSROOT/usr/lib|g" {} '+'
    log "tigervnc: xserver Makefile 裸 -L/usr/local/lib → sysroot -L"
  fi
  # sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $SRCROOT/tigervnc/unix/xserver/hw/vnc/Makefile
  # 
  # #  -lbrotlidec -lbrotlicommon
  # sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $SRCROOT/tigervnc/unix/xserver/hw/vnc/Makefile
  # 
  # -lgnutls 
  # XSERVER_SYS_LIBS: 静态链接顺序敏感(freetype/fontenc/Xfont2/png/z 互依赖)，
  #   用 --start-group/--end-group 让 ld 反复解析。native 也用 group(无害)。
  #   libz.a 在 Alpine 位于 $XX_SYSROOT/lib(非 usr/lib)→ 交叉补 -L。native 走默认路径。
  if [ -n "$XX_CROSS_FILE" ]; then
    _SYSLIBS="-Wl,--start-group -lXau -lXdmcp -lpixman-1 -ljpeg -lxkbfile -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd -lxshmfence -Wl,--end-group"
    _XLL="-L$XX_SYSROOT/lib -L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib"
  else
    _SYSLIBS="-Wl,--start-group -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd -Wl,--end-group"
    _XLL=""
  fi
  sed "s|^XSERVER_SYS_LIBS = .*|XSERVER_SYS_LIBS = ${_XLL} ${_SYSLIBS}|" -i $SRCROOT/tigervnc/unix/xserver/hw/vnc/Makefile

  log "Compiling TigerVNC server..."
  make $MAKE_CC -C $SRCROOT/tigervnc/unix/xserver -j$(nproc)

  log "Installing TigerVNC server..."
  make $MAKE_CC DESTDIR=$ROOT_DEST_DIR -C $SRCROOT/tigervnc/unix/xserver install

  log "Installing TigerVNC vncpasswd tool..."
  make $MAKE_CC DESTDIR=$ROOT_DEST_DIR -C $SRCROOT/tigervnc/unix/vncpasswd install

  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判
  #   static + 目标架构; native 仍走 xx-verify(原路径)。产物 = Xvnc + vncpasswd。
  if [ -n "$XX_CROSS_FILE" ]; then
    for _b in $TARGETPATH/bin/Xvnc $TARGETPATH/bin/vncpasswd; do
      file $_b | grep -qE "ARM.*statically linked" \
        || { log "TIGERVNC file 非 ARM static: $_b"; exit 1; }
    done
  else
    xx-verify --static $TARGETPATH/bin/Xvnc || { log "TIGERVNC xx-verify FAILED(Xvnc)"; exit 1; }
    xx-verify --static $TARGETPATH/bin/vncpasswd || { log "TIGERVNC xx-verify FAILED(vncpasswd)"; exit 1; }
  fi
}

#
# Build XKeyboardConfig.
#
function xkb(){
  mkdir -p $SRCROOT/xkb
  log "Downloading XKeyboardConfig..."
  down_catfile ${XKEYBOARDCONFIG_URL} | tar -xj --strip 1 -C $SRCROOT/xkb
  log "Configuring XKeyboardConfig..."
  (
      # cd $SRCROOT/xkb && abuild-meson . build
      cd $SRCROOT/xkb && meson . build
  )
  log "Compiling XKeyboardConfig..."
  meson compile -C $SRCROOT/xkb/build
  log "Installing XKeyboardConfig..."
  DESTDIR="$XKB_DEST_DIR" meson install --no-rebuild -C $SRCROOT/xkb/build

  log "Stripping XKeyboardConfig..."
  # We keep only the files needed by Xvnc.
  TO_KEEP="
      geometry/pc
      symbols/pc
      symbols/us
      symbols/srvr_ctrl
      symbols/keypad
      symbols/altwin
      symbols/inet
      compat/accessx
      compat/basic
      compat/caps
      compat/complete
      compat/iso9995
      compat/ledcaps
      compat/lednum
      compat/ledscroll
      compat/level5
      compat/misc
      compat/mousekeys
      compat/xfree86
      keycodes/evdev
      keycodes/aliases
      types/basic
      types/complete
      types/extra
      types/iso9995
      types/level5
      types/mousekeys
      types/numpad
      types/pc
      rules/evdev
  "

  # alpine: Installing $SRCROOT/xkb/types/README to $SRCROOT/xkb-install/usr/local/share/X11/xkb/types
  xkbDir=/usr/local/share/X11/xkb
  find $XKB_DEST_DIR$xkbDir -mindepth 2 -maxdepth 2 -type d -print -exec rm -r {} ';'
  find $XKB_DEST_DIR$xkbDir -mindepth 1 ! -type d $(printf "! -wholename $XKB_DEST_DIR$xkbDir/%s " $(echo "$TO_KEEP")) -print -delete
  # +
  mkdir -p ${XKB_REF_PATH}/share/X11;
  \cp -a $XKB_DEST_DIR$xkbDir ${XKB_REF_PATH}/share/X11/xkb
}

#
# Build xkbcomp.
#
function xkbcomp(){
  mkdir -p $SRCROOT/xkbcomp
  log "Downloading xkbcomp..."
  down_catfile ${XKBCOMP_URL} | tar -xj --strip 1 -C $SRCROOT/xkbcomp

  log "Configuring xkbcomp..."
  (
      LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all -Wl,--start-group -lX11 -lxcb -lXdmcp -lXau -Wl,--end-group" && \
      cd $SRCROOT/xkbcomp && \
      LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all -Wl,--start-group -lX11 -lxcb -lXdmcp -lXau -Wl,--end-group" LIBS="$LDFLAGS" ./configure \
          --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
          --host=$(xx-clang --print-target-triple) \
          --prefix=$INS_PREFIX \
          $CROSS_HOST \
  )

  log "Compiling xkbcomp..."
  make $MAKE_CC -C $SRCROOT/xkbcomp -j$(nproc)

  log "Installing xkbcomp..."
  make DESTDIR=$ROOT_DEST_DIR -C $SRCROOT/xkbcomp install
}


case "$1" in
cache)
    down_catfile ${GNUTLS_URL} > /dev/null
    down_catfile ${LIBXFONT2_URL} > /dev/null
    down_catfile ${LIBFONTENC_URL} > /dev/null
    down_catfile ${LIBTASN1_URL} > /dev/null
    down_catfile ${LIBXSHMFENCE_URL} > /dev/null
    # 
    down_catfile ${TIGERVNC_URL} > /dev/null
    down_catfile ${XSERVER_URL} > /dev/null
    down_catfile ${XKEYBOARDCONFIG_URL} > /dev/null
    down_catfile ${XKBCOMP_URL} > /dev/null
    ;;
full)
    doExec gnutls || exit 1
    doExec libxfont2 || exit 1
    doExec libfontenc || exit 1
    doExec libtasn1 || exit 1
    doExec libxshmfence || exit 1
    doExec tigervnc || exit 1
    doExec xkb || exit 1
    doExec xkbcomp || exit 1
    ;;
b_deps)
    # /src/x-tigervnc/build.sh gnutls &
    doExec_mark "x-tigervnc b_deps grp"
    doExec bash /src/x-tigervnc/build.sh libxfont2 &
    doExec bash /src/x-tigervnc/build.sh libfontenc &
    doExec bash /src/x-tigervnc/build.sh libtasn1 &
    doExec bash /src/x-tigervnc/build.sh libxshmfence &
    wait
    doExec_check || exit 1
    ;;
b_tiger)
    doExec_mark "x-tigervnc b_tiger grp"
    doExec bash /src/x-tigervnc/build.sh tigervnc &
    doExec bash /src/x-tigervnc/build.sh xkb &
    doExec bash /src/x-tigervnc/build.sh xkbcomp &
    wait
    doExec_check || exit 1
    ;;
*) #compile
    # POSIX sh: 函数不跨 subshell 继承。doExec 调 bash /src/...build.sh <func> 时，
    # 子进程里函数定义在脚本顶层已就位，直接调即可（避免 doExec→oneBuild→doExec 循环）。
    if type "$1" 2>/dev/null | grep -q function; then
      "$1"
    else
      oneBuild $1
    fi
    ;;          
esac
exit 0
