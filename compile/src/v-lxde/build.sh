#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-lxde #git clone;
LXAPPEARANCE_VER=0.8.4
LXAPPEARANCE_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

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

# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
test -z "$GITHUB" && GITHUB=https://github.com 

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
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/lxde-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
