#!/bin/sh
set -e
source /src/common.sh

#
# Build geany
#
function geany(){
  log "Downloading GEANY..."
    rm -rf /tmp/geany; # mkdir -p /tmp/geany
    # down_catfile ${GEANY_URL} | tar -zx --strip 1 -C /tmp/geany
    branch="--branch=1.3.1"
    repo=$GITHUB/lxde/geany
    rm -rf /tmp/geany; git clone --depth=1 $branch $repo /tmp/geany #;
  log "Configuring GEANY..."
  cd /tmp/geany #&& ./bootstrap;
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    ./autogen.sh
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -lmenu-cache -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    LIBS="$LIBS0" ./configure --prefix=$TARGETPATH

  log "Compiling GEANY..."
    make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

  log "Install GEANY..."
    make install 2>&1 > /dev/null

  # view
  ls -lh $TARGETPATH/bin/geany
  xx-verify --static $TARGETPATH/bin/geany #/tmp/geany/src/geany
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    geany
    ;;
b_deps)
    # bash /src/openbox/build.sh apkdeps
    # bash /src/openbox/build.sh pango & ##needed by gtk
    # bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    # bash /src/xcompmgr/build.sh Xdamage &
    # wait
    # # 
    # bash /src/v-pcmanfm/build.sh apkdeps
    # bash /src/v-pcmanfm/build.sh atk & #needed by gtk
    # bash /src/v-pcmanfm/build.sh gdk-pixbuf & #needed by gtk
    # wait
    # bash /src/v-pcmanfm/build.sh gtk

    # view
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk|libfm|menu-cache" |grep "\.a$" |sort
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
