#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-geany #git clone;
GEANY_VER=0.8.4
GEANY_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

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


# export CC=clang
# export CXX=clang++

# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
test -z "$GITHUB" && GITHUB=https://github.com 

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
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/geany-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
