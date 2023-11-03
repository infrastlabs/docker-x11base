#!/bin/sh
#
# Helper script that builds Openbox as a static binary.
#
# NOTE: This script is expected to be run under Alpine Linux.
#

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define software versions.
PANGO_VERSION=1.49.3
LIBXRANDR_VERSION=1.5.3
OPENBOX_VERSION=3.6.1
# Define software download URLs.
PANGO_URL=https://download.gnome.org/sources/pango/${PANGO_VERSION%.*}/pango-${PANGO_VERSION}.tar.xz
LIBXRANDR_URL=https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VERSION}.tar.xz
OPENBOX_URL=http://openbox.org/dist/openbox/openbox-${OPENBOX_VERSION}.tar.xz

# Define software versions.
FONTCONFIG_VERSION=2.14.0
# Define software download URLs.
FONTCONFIG_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.gz


# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# configure: error: C compiler cannot create executables
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

export CC=xx-clang
export CXX=xx-clang++
# export CC=xx-clang-wrapper
# export CXX=xx-clang++

# set -u; err if not exist
test -z "$TARGETPATH" && export TARGETPATH=/opt/base
test -z "$CONSOLE_LOG" && export CONSOLE_LOG=yes
ROOT_DEST_DIR="/" #/tmp/xx-install> /
INS_PREFIX=$TARGETPATH
#final: /tmp/fontconfig-install/usr/local/share/X11/xkb> /usr/local/static/tigervnc/usr/local/share/X11/xkb
FONTCONFIG_DEST_DIR="/tmp/fontconfig-install"
FONTCONFIG_INS_PREFIX=$TARGETPATH
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

#
# Install required packages.
#
# log "Installing required Alpine packages..."
# apk --no-cache add \
#     curl \
#     build-base \
#     clang \
#     meson \
#     pkgconfig \
#     patch \
#     glib-dev \

# xx-apk --no-cache --no-scripts add \
#     g++ \
#     glib-dev \
#     glib-static \
#     fribidi-dev \
#     fribidi-static \
#     harfbuzz-dev \
#     harfbuzz-static \
#     cairo-dev \
#     cairo-static \
#     libxft-dev \
#     libxml2-dev \
#     libx11-dev \
#     libx11-static \
#     libxcb-static \
#     libxdmcp-dev \
#     libxau-dev \
#     freetype-static \
#     expat-static \
#     libpng-dev \
#     libpng-static \
#     zlib-static \
#     bzip2-static \
#     pcre-dev \
#     libxrender-dev \
#     graphite2-static \
#     libffi-dev \
#     xz-dev \
#     brotli-static \


function pango_meson(){
export CC=xx-clang-wrapper
# Copy the xx-clang wrapper.  Openbox compilation uses libtool.  During the link
# phase, libtool re-orders all arguments from LDFLAGS.  Thus, libraries are no
# longer between the -Wl,--start-group and -Wl,--end-group arguments.  The
# wrapper detects this scenario and fixes arguments.
\cp -a "$SCRIPT_DIR"/xx-clang-wrapper /usr/bin/
chmod +x /usr/bin/xx-clang-wrapper

# Create the meson cross compile file.
echo "[binaries]
pkgconfig = '$(xx-info)-pkg-config'

[properties]
sys_root = '$(xx-info sysroot)'
pkg_config_libdir = '$(xx-info sysroot)/usr/lib/pkgconfig'

[host_machine]
system = 'linux'
cpu_family = '$(xx-info arch)'
cpu = '$(xx-info arch)'
endian = 'little'
" > /tmp/meson-cross.txt
}

#
# Build pango.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function pango(){
#     # g++ \
#     # glib-dev \
#     # glib-static \
# xx-apk --no-cache --no-scripts add \
#     fribidi-dev \
#     fribidi-static \
#     harfbuzz-dev \
#     harfbuzz-static \

pango_meson #call
mkdir -p /tmp/pango
log "Downloading pango..."
# curl -# -L -f ${PANGO_URL} | tar -xJ --strip 1 -C /tmp/pango
down_catfile ${PANGO_URL} | tar -xJ --strip 1 -C /tmp/pango

log "Configuring pango..."
(
    cd /tmp/pango && LDFLAGS= abuild-meson \
        -Ddefault_library=static \
        -Dintrospection=disabled \
        -Dgtk_doc=false \
        --cross-file /tmp/meson-cross.txt \
        build \
)

log "Compiling pango..."
meson compile -C /tmp/pango/build

log "Installing pango..."
DESTDIR=$(xx-info sysroot) meson install --no-rebuild -C /tmp/pango/build
}

#
# Build libXrandr.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxrandr(){
mkdir -p /tmp/libxrandr
log "Downloading libXrandr..."
# curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libxrandr
down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libxrandr

log "Configuring libXrandr..."
(
    cd /tmp/libxrandr && LDFLAGS= ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --disable-shared \
        --enable-static \
        --enable-malloc0returnsnull \
)

log "Compiling libXrandr..."
make -C /tmp/libxrandr -j$(nproc)

log "Installing libXrandr..."
make DESTDIR=$(xx-info sysroot) -C /tmp/libxrandr install
}

#
# Build fontconfig.
#
# Fontconfig is already built by an earlier stage in Dockerfile.  The static
# library will be used by Openbox.  We need to compile our own version to adjust
# different paths used by fontconfig.
# Note that the fontconfig cache generated by fc-cache is architecture
# dependent.  Thus, we won't generate one, but it's not a problem since
# we have very few fonts installed.
#
function fontconfig(){
# log "Installing required Alpine packages..."
# repeatd<< @builder;
# xx-apk --no-cache add \
#     curl \
#     build-base \
#     clang \
#     pkgconfig \
#     gperf \
#     python3 \
#     font-croscore \
#     \
#     glib-dev \
#     g++ \
#     freetype-dev \
#     expat-dev expat-static
apk add expat-static


#
# Install Noto fonts.
# Only the fonts used by JWM are installed.
#
# log "Installing Noto fonts..."
# mkdir -p /tmp/fontconfig-install${TARGETPATH}/share/fonts
# for FONT in Arimo-Regular Arimo-Bold
# do
#     \cp -v /usr/share/fonts/noto/$FONT.ttf /tmp/fontconfig-install${TARGETPATH}/share/fonts/
# done

#
# Build fontconfig.
# The static library will be used by some baseimage programs.  We need to
# compile our own version to adjust different paths used by fontconfig.
# Note that the fontconfig cache generated by fc-cache is architecture
# dependent.  Thus, we won't generate one, but it's not a problem since
# we have very few fonts installed.
#
mkdir -p /tmp/fontconfig
log "Downloading fontconfig..."
down_catfile ${FONTCONFIG_URL} | tar -xz --strip 1 -C /tmp/fontconfig

log "Configuring FONTCONFIG..."
(
    cd /tmp/fontconfig && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr \
        --with-default-fonts=${FONTCONFIG_INS_PREFIX}/share/fonts \
        --with-baseconfigdir=${FONTCONFIG_INS_PREFIX}/share/fontconfig \
        --with-configdir=${FONTCONFIG_INS_PREFIX}/share/fontconfig/conf.d \
        --with-templatedir=${FONTCONFIG_INS_PREFIX}/share/fontconfig/conf.avail \
        --with-cache-dir=/config/xdg/cache/fontconfig \
        --disable-shared \
        --enable-static \
        --disable-docs \
        --disable-nls \
        --disable-cache-build \
)

log "Compiling FONTCONFIG..."
# make -C /tmp/fontconfig -j$(nproc)
# -lfontconfig  -lXft -lX11 -lxcb -lXau    -lXrender -lXdmcp   -lbrotlidec -lbrotlicommon
flags="-static -lfreetype -lpng -lexpat -lxml2 -lz -lbz2"
make LDFLAGS="$flags" -C  /tmp/fontconfig -j$(nproc)

# /tmp/fontconfig-install/usr/share/xml/fontconfig
log "Installing FONTCONFIG..."
make DESTDIR=$FONTCONFIG_DEST_DIR -C /tmp/fontconfig install



# log "Installing fontconfig..."
# cp -av /tmp/fontconfig-install/usr $(xx-info sysroot)
}

#
# Build Openbox.
#
function openbox(){
pango_meson #call
env |egrep "FLAGS|clang"
rm -rf /tmp/openbox; mkdir -p /tmp/openbox
log "Downloading Openbox..."
# curl -# -L -f ${OPENBOX_URL} | tar -xJ --strip 1 -C /tmp/openbox
down_catfile ${OPENBOX_URL} | tar -xJ --strip 1 -C /tmp/openbox

log "Patching Openbox..."
patch -p1 -d /tmp/openbox < "$SCRIPT_DIR"/disable-x-locale.patch
patch -p1 -d /tmp/openbox < "$SCRIPT_DIR"/menu-file-order.patch

# The config.sub provided with Openbox is too old.  Get a recent one from
# https://github.com/gcc-mirror/gcc/blob/master/config.sub
cp -v "$SCRIPT_DIR"/config.sub /tmp/openbox

log "Configuring Openbox..."
(
    #cd /tmp/openbox && LIBS="$LDFLAGS" ./configure \

    cd /tmp/openbox && \
        OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" \
        # OB_LIBS="$OB_LIBS -luuid"
        LDFLAGS="$LDFLAGS -Wl,--start-group $OB_LIBS -Wl,--end-group" LIBS="$LDFLAGS" ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=$INS_PREFIX \
        --datarootdir=$INS_PREFIX/share \
        --disable-shared \
        --enable-static \
        --disable-nls \
        --disable-startup-notification \
        --disable-xcursor \
        --disable-librsvg \
        --disable-session-management \
        --disable-xkb \
        --disable-xinerama \
)

log "Compiling Openbox..."
#sed -i 's|--silent|--verbose|' /tmp/openbox/Makefile
make V=1 -C /tmp/openbox -j$(nproc)
# make LDFLAGS="-static" V=1 -C /tmp/openbox -j$(nproc) ##still dyn

log "Installing Openbox..."
make DESTDIR=$ROOT_DEST_DIR -C /tmp/openbox install

# static-verify
# $RUN xx-verify --static \
#     $ROOT_DEST_DIR${INS_PREFIX}/bin/openbox \
#     $ROOT_DEST_DIR${INS_PREFIX}/bin/obxprop
# $RUN upx $ROOT_DEST_DIR${INS_PREFIX}/bin/openbox
# $RUN upx $ROOT_DEST_DIR${INS_PREFIX}/bin/obxprop
xx-verify --static $ROOT_DEST_DIR${INS_PREFIX}/bin/openbox
}


# apk add fribidi-dev fribidi-static ##@each
log "Installing required Alpine packages..."
apk --no-cache add \
    curl \
    build-base \
    clang \
    meson \
    pkgconfig \
    patch \
    glib-dev
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
    brotli-static

case "$1" in
cache)
    down_catfile ${PANGO_URL} > /dev/null
    down_catfile ${LIBXRAND_URL} > /dev/null
    down_catfile ${FONTCONFIG_URL} > /dev/null
    down_catfile ${OPENBOX_URL} > /dev/null
    ;;
full)
    pango
    libxrandr
    fontconfig
    openbox
    ;;
b_deps)
    /src/openbox/build.sh pango &
    /src/openbox/build.sh libxrandr &
    /src/openbox/build.sh fontconfig &
    wait
    ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/fluxbox-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    # test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
