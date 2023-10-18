#!/bin/sh
#
# Helper script that builds the TigerVNC server as a static binary.
#
# This also builds a customized version of XKeyboard config files and the
# compiler (xkbcomp).  By using a different instance/version of XKeyboard, we
# prevent version mismatch issues thay could occur by using packages from the
# distro of the baseimage.
#
# NOTE: This script is expected to be run under Alpine Linux.
#

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.

# Define software versions.
TIGERVNC_VERSION=1.13.1
XSERVER_VERSION=1.20.14
# @ubt2004
# TIGERVNC_VERSION=1.12.0
# XSERVER_VERSION=1.20.7


# root@10155d90a9ce:/tmp/tigervnc/unix/xserver# dpkg -l |egrep "gnutls|xfont2|fontenc|tasn|shmf" |egrep "dev|shmf|xfont2"
# ii  libfontenc-dev:amd64            1:1.1.4-1                      amd64        X11 font encoding library (development headers)
# ii  libgnutls28-dev:amd64           3.7.9-2                        amd64        GNU TLS library - development files
# ii  libtasn1-6-dev:amd64            4.19.0-2                       amd64        Manage ASN.1 structures (development)
# ii  libxfont2:amd64                 1:2.0.6-1                      amd64        X11 font rasterisation library
# ii  libxshmfence1:amd64             1.3-1                          amd64        X shared memory fences - shared library

# Use the same versions has Alpine 3.15.
# 3.6.13-2ubuntu1.8
GNUTLS_VERSION=3.7.9 #3.6.13 #3.7.1
# 1:2.0.3-1 ##dpkg -l |egrep "font"
LIBXFONT2_VERSION=2.0.6 #2.0.3 #2.0.5
# 1:1.1.4-0ubuntu1
LIBFONTENC_VERSION=1.1.4 #OK
# 4.16.0-2
LIBTASN1_VERSION=4.19.0 #4.16.0 #4.18.0
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
TIGERVNC_URL=https://github.com/TigerVNC/tigervnc/archive/v${TIGERVNC_VERSION}.tar.gz
XSERVER_URL=https://www.x.org/releases/individual/xserver/xorg-server-${XSERVER_VERSION}.tar.gz

GNUTLS_URL=https://www.gnupg.org/ftp/gcrypt/gnutls/v${GNUTLS_VERSION%.*}/gnutls-${GNUTLS_VERSION}.tar.xz
LIBTASN1_URL=https://ftp.gnu.org/gnu/libtasn1/libtasn1-${LIBTASN1_VERSION}.tar.gz
LIBXFONT2_URL=https://www.x.org/pub/individual/lib/libXfont2-${LIBXFONT2_VERSION}.tar.gz
LIBFONTENC_URL=https://www.x.org/releases/individual/lib/libfontenc-${LIBFONTENC_VERSION}.tar.gz
LIBXSHMFENCE_URL=https://www.x.org/releases/individual/lib/libxshmfence-${LIBXSHMFENCE_VERSION}.tar.gz

XKEYBOARDCONFIG_URL=https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-${XKEYBOARDCONFIG_VERSION}.tar.bz2
XKBCOMP_URL=https://www.x.org/releases/individual/app/xkbcomp-${XKBCOMP_VERSION}.tar.bz2

# set -u; err if not exist
test -z "$TARGETPATH" && export TARGETPATH=/opt/base
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f /mnt/$file || curl -# -k -fSL $url > /mnt/$file
  cat /mnt/$file
}

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

export CC=xx-clang

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

function log {
    echo ">>> $*"
}

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
mkdir -p /tmp/gnutls
log "Downloading GNU TLS..."
down_catfile ${GNUTLS_URL} | tar -xJ --strip 1 -C /tmp/gnutls
log "Configuring GNU TLS..."
(
    cd /tmp/gnutls && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
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
make -C /tmp/gnutls -j$(nproc)
log "Installing GNU TLS..."
make DESTDIR=$(xx-info sysroot) -C /tmp/gnutls install
}

#
# Build libXfont2
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxfont2(){
mkdir -p /tmp/libxfont2
log "Downloading libXfont2..."
down_catfile ${LIBXFONT2_URL} | tar -xz --strip 1 -C /tmp/libxfont2
log "Configuring libXfont2..."
(
    cd /tmp/libxfont2 && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --without-fop \
        --without-xmlto \
        --disable-devel-docs \
        --enable-static \
        --disable-shared \
)
log "Compiling libXfont2..."
sed 's/^noinst_PROGRAMS = /#noinst_PROGRAMS = /' -i /tmp/libxfont2/Makefile.in
make -C /tmp/libxfont2 -j$(nproc)
log "Installing libXfont2..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libxfont2 install
}

#
# Build libfontenc
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libfontenc(){
mkdir -p /tmp/libfontenc
log "Downloading libfontenc..."
down_catfile ${LIBFONTENC_URL} | tar -xz --strip 1 -C /tmp/libfontenc
log "Configuring libfontenc..."
(
    cd /tmp/libfontenc && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --with-encodingsdir=/usr/share/fonts/encodings \
        --enable-static \
        --disable-shared \
)
log "Compiling libfontenc..."
make -C /tmp/libfontenc -j$(nproc)
log "Installing libfontenc..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libfontenc install
}

#
# Build libtasn1
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libtasn1(){
mkdir -p /tmp/libtasn1
log "Downloading libtasn1..."
down_catfile ${LIBTASN1_URL} | tar -xz --strip 1 -C /tmp/libtasn1
log "Configuring libtasn1..."
(
    cd /tmp/libtasn1 && CFLAGS="$CFLAGS -Wno-error=inline" ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
)
log "Compiling libtasn1..."
make -C /tmp/libtasn1 -j$(nproc)
log "Installing libtasn1..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libtasn1 install
}

#
# Build libxshmfence
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxshmfence(){
mkdir -p /tmp/libxshmfence
log "Downloading libxshmfence..."
down_catfile ${LIBXSHMFENCE_URL} | tar -xz --strip 1 -C /tmp/libxshmfence
log "Configuring libxshmfence..."
(
    cd /tmp/libxshmfence && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --enable-static \
        --disable-shared \
        --enable-futex \
)
log "Compiling libxshmfence..."
make -C /tmp/libxshmfence -j$(nproc)
log "Installing libxshmfence..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libxshmfence install
}

#
# Build TigerVNC
#
function tigervnc(){
mkdir -p /tmp/tigervnc
log "Downloading TigerVNC..."
down_catfile ${TIGERVNC_URL} | tar -xz --strip 1 -C /tmp/tigervnc
log "Downloading Xorg server..."
down_catfile ${XSERVER_URL} | tar -xz --strip 1 -C /tmp/tigervnc/unix/xserver

log "Patching TigerVNC..."
# Apply the TigerVNC patch against the X server.
patch -p1 -d /tmp/tigervnc/unix/xserver < /tmp/tigervnc/unix/xserver120.patch

# Build a static binary of vncpasswd.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/vncpasswd-static.patch
# Disable PAM support.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/disable-pam.patch
# Fix static build.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/static-build.patch
# patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/tigervnc-1.12.0-configuration_fixes-1.patch

log "Configuring TigerVNC..."
(
    # https://github.com/TigerVNC/tigervnc/issues/998
    # -DENABLE_GNUTLS=ON \
    cd /tmp/tigervnc && cmake -G "Unix Makefiles" \
        $(xx-clang --print-cmake-defines) \
        -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DINSTALL_SYSTEMD_UNITS=OFF \
        -DENABLE_NLS=OFF \
        -DENABLE_GNUTLS=OFF \
        -DENABLE_NETTLE=ON \
        -DBUILD_VIEWER=OFF \
)

log "Compiling TigerVNC common libraries and tools..."
make -C /tmp/tigervnc/common -j$(nproc)
make -C /tmp/tigervnc/unix/common -j$(nproc)
make -C /tmp/tigervnc/unix/vncpasswd -j$(nproc)

log "Configuring TigerVNC server..."
autoreconf -fiv /tmp/tigervnc/unix/xserver
(
    cd /tmp/tigervnc/unix/xserver && CFLAGS="$CFLAGS -Wno-implicit-function-declaration" ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --sysconfdir=/etc/X11 \
        --localstatedir=/var \
        --with-xkb-path=${TARGETPATH}/share/X11/xkb \
        --with-xkb-output=/var/lib/xkb \
        --with-xkb-bin-directory=${TARGETPATH}/bin \
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
find /tmp/tigervnc -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'
sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i /tmp/tigervnc/unix/xserver/hw/vnc/Makefile
# #  -lbrotlidec -lbrotlicommon
# sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i /tmp/tigervnc/unix/xserver/hw/vnc/Makefile

log "Compiling TigerVNC server..."
make -C /tmp/tigervnc/unix/xserver -j$(nproc)

log "Installing TigerVNC server..."
make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/xserver install

log "Installing TigerVNC vncpasswd tool..."
make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/vncpasswd install
}

#
# Build XKeyboardConfig.
#
function xkb(){
mkdir -p /tmp/xkb
log "Downloading XKeyboardConfig..."
down_catfile ${XKEYBOARDCONFIG_URL} | tar -xj --strip 1 -C /tmp/xkb
log "Configuring XKeyboardConfig..."
(
    # cd /tmp/xkb && abuild-meson . build
    cd /tmp/xkb && meson . build
)
log "Compiling XKeyboardConfig..."
meson compile -C /tmp/xkb/build
log "Installing XKeyboardConfig..."
DESTDIR="/tmp/xkb-install" meson install --no-rebuild -C /tmp/xkb/build

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
find /tmp/xkb-install/usr/share/X11/xkb -mindepth 2 -maxdepth 2 -type d -print -exec rm -r {} ';'
find /tmp/xkb-install/usr/share/X11/xkb -mindepth 1 ! -type d $(printf "! -wholename /tmp/xkb-install/usr/share/X11/xkb/%s " $(echo "$TO_KEEP")) -print -delete
}

#
# Build xkbcomp.
#
function xkbcomp(){
mkdir -p /tmp/xkbcomp
log "Downloading xkbcomp..."
down_catfile ${XKBCOMP_URL} | tar -xj --strip 1 -C /tmp/xkbcomp

log "Configuring xkbcomp..."
(
    LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all -Wl,--start-group -lX11 -lxcb -lXdmcp -lXau -Wl,--end-group" && \
    cd /tmp/xkbcomp && \
    LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all -Wl,--start-group -lX11 -lxcb -lXdmcp -lXau -Wl,--end-group" LIBS="$LDFLAGS" ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
)

log "Compiling xkbcomp..."
make -C /tmp/xkbcomp -j$(nproc)

log "Installing xkbcomp..."
make DESTDIR=/tmp/xkbcomp-install -C /tmp/xkbcomp install
}

function cache(){
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
}


function print_time_cost(){
    local begin_time=$1
	gawk 'BEGIN{
		print "本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}' 2>&1 | tee -a $logfile
}

# rm -rf /tmp/logs; #avoid deleted @batch-mode
mkdir -p /tmp/logs
case "$1" in
full)
    gnutls
    libxfont2
    libfontenc
    libtasn1
    libxshmfence
    # 
    tigervnc
    xkb
    xkbcomp
    ;;
cache)
    cache
    ;;
b_deps)
    # /build/build.sh gnutls &
    /build/build.sh libxfont2 &
    /build/build.sh libfontenc &
    /build/build.sh libtasn1 &
    /build/build.sh libxshmfence &
    wait
    ;;
b_tiger)
    /build/build.sh tigervnc &
    /build/build.sh xkb &
    /build/build.sh xkbcomp &
    wait
    ;;
*) #compile
    # $1 |tee /tmp/logs/$1.log
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=/tmp/logs/$1.log
    $1 #> $logfile 2>&1;
    
    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
