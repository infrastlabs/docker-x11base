#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-perp #git clone;
XCOMPMGR_VER=0.8.4
XCOMPMGR_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++

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

#
# Build perp
#
function perp(){
  log "Downloading perp..."
  git clone https://gitee.com/infrastlabs/fk-perp /tmp/fk-perp
  cd /tmp/fk-perp

  log "Compiling perp..."
  # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
  make -C lasagna/
  make -C perp/
  #make -C runtools/

  log "Installing perp..."
  make -C perp/ install

  # view
  ls -lh /tmp/fk-perp/perp
  xx-verify --static /tmp/fk-perp/perp/perpd
  xx-verify --static /tmp/fk-perp/perp/perpctl
  xx-verify --static /tmp/fk-perp/perp/perpls
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    perp
    ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/perp-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
