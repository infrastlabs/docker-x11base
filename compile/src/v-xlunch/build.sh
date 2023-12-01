#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


IMLIB2_URL=https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-xlunch #git clone;
XLUNCH_VER=0.8.4
XLUNCH_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

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


# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz
function imlib2(){
  mkdir -p /tmp/imlib2
  log "Downloading imlib2..."
  # curl -# -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C /tmp/imlib2
  down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/imlib2
  cd /tmp/imlib2
    # export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #去-static: 无a库生成
    export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
    ./configure; 
    # ./configure --with-x ; 
    # make; make install;

  log "Compiling imlib2..."
  make

  log "Installing imlib2..."
  make install
}

#
# Build xlunch
#
# export TARGETPATH=/usr/local/static/xlunch
function xlunch(){

apk add hicolor-icon-theme #need hicolor
# ref: xcompmgr
apk add cairo-static expat-static fribidi-static glib-static graphite2-static harfbuzz-static
apk add libxml2-dev ##>> -lxml2 -llzma 

  log "Downloading XLUNCH..."
  rm -rf /tmp/xlunch; # mkdir -p /tmp/xlunch
  # down_catfile ${XLUNCH_URL} | tar -zx --strip 1 -C /tmp/xlunch
  # branch="--branch=$XLUNCH_VER"
  # repo=https://hub.nuaa.cf/Tomas-M/xlunch
  repo=https://gitee.com/g-system/fk-xlunch
  git clone --depth=1 $branch $repo /tmp/xlunch #;
  log "Configuring XLUNCH..."
  cd /tmp/xlunch #&& ./bootstrap;
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf
    test -s ./Makefile-bk1 || cat Makefile > Makefile-bk1
    cat Makefile-bk1 |sed "s^DESTDIR)/usr^DESTDIR)$TARGETPATH^g" > Makefile
    sed -i "s^bash extra/genentries^#bash extra/genentries^g" Makefile

    # make
    # OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
    # make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
    
    # drop1: -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
    # drop2: -lXft -lXrender -llzma 
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext  -lfreetype -lpng   -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS" xlunch #default>> all: xlunch entries.dsv

  log "Install XLUNCH..."
  # make;
  make install; #不用install? need

  # view
  ls -lh /tmp/xlunch/
  xx-verify --static /tmp/xlunch/xlunch
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    imlib2
    xlunch
    ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/xlunch-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
