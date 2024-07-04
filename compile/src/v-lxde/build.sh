#!/bin/sh
set -e
source /src/common.sh

#
# Build lxappearance
#
# export TARGETPATH=/usr/local/static/lxappearance
function lxappearance(){
# apk add hicolor-icon-theme #need hicolor

  log "Downloading LXAPPEARANCE..."
  rm -rf /tmp/lxappearance; # mkdir -p /tmp/lxappearance
  # down_catfile ${LXAPPEARANCE_URL} | tar -zx --strip 1 -C /tmp/lxappearance
  repo=$GITHUB/lxde/lxappearance
  # branch="--branch=$LXAPPEARANCE_VER"
  git clone --depth=1 $branch $repo /tmp/lxappearance #;
  log "Configuring LXAPPEARANCE..."
  cd /tmp/lxappearance #&& ./bootstrap;
  ./autogen.sh
  ./configure --prefix=$TARGETPATH \
  --enable-man=no \
  --enable-more-warnings=yes \
  --enable-gtk3=no \
  --enable-dbus=yes \
  --enable-debug=yes 

  # ENABLE_DBUS err
  # 4  vi src/lxappearance.c
  # 5  vi /tmp/lxappearance/src/lxappearance.c ##注释后，编译过了;
  # >> 手动拷贝>> 运行 GModule-Critical错误依旧(assertion 'module'!='NULL')2条

  # ref pcmanfm
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    #  -lfm -lfm-gtk -lmenu-cache 
    ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

  log "Install LXAPPEARANCE..."
  # make;
  make install; #不用install? need

  # view
  ls -lh /tmp/lxappearance/
  xx-verify --static /tmp/lxappearance/src/lxappearance
}

function lxtask(){
  log "Downloading LXTASK..."
  rm -rf /tmp/lxtask; # mkdir -p /tmp/lxtask
  # down_catfile ${LXAPPEARANCE_URL} | tar -zx --strip 1 -C /tmp/lxtask
  repo=$GITHUB/lxde/lxtask
  # branch="--branch=$LXAPPEARANCE_VER"
  git clone --depth=1 $branch $repo /tmp/lxtask #;
  log "Configuring LXTASK..."
  cd /tmp/lxtask #&& ./bootstrap;
  ./autogen.sh
  ./configure --prefix=$TARGETPATH
  # ref pcmanfm
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    #  -lfm -lfm-gtk -lmenu-cache 
    ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

  log "Install LXTASK..."
  # make;
  make install; #不用install? need

  # view
  ls -lh /tmp/lxtask/
  xx-verify --static /tmp/lxtask/src/lxtask
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    lxde
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
