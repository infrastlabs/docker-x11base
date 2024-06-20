#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-pulseaudio #git clone;
PULSEAUDIO_VER=0.8.4
PULSEAUDIO_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

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
test -z "$GITHUB" && GITHUB=https://github.com 


# _xiph[ogg,flac,vorbis,opus],libsndfile
# v1.3.5@https://hub.yzuu.cf/xiph/ogg
# 1.3.4@https://hub.yzuu.cf/xiph/flac
# v1.3.7@https://hub.yzuu.cf/xiph/vorbis
# v1.3.1@https://hub.yzuu.cf/xiph/opus
# 1.0.31@https://hub.yzuu.cf/libsndfile/libsndfile


# tmux-1 @temvm2:
#   250  cd ../ogg-v135/
#   252  make clean
#   253  ./configure --enable-static --disable-shared
#   254  make
#   258  find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort |while read one; do echo $one; rm -f $one; done
#   260  find |grep libogg
#   #
#   269  cd ../flac-v134/
#   270  ./configure --enable-static --disable-shared
#   271  make clean; make
#   273  find |grep libFLAC.a
#   275  find |grep libFLAC |sort |grep libs
#   277  make install
#   #
#   278  cd ../vorbis-org-v137/
#   279  ls
#   280  ./configure --enable-static --disable-shared
#   281  make clean; make
#   283  find |grep libvorbis |sort |grep libs
#   #
#   286  cd ../opus-v14-v131/
#   287  ls
#   288  ./configure --enable-static --disable-shared
#   289  make clean; make
#   290  find |grep libopus |sort |grep libs
#   # 
#   295  cd libsndfile-v1.0.31/
#   296  ./configure --enable-static --disable-shared
#   300  ll |wc
#   301  cat Makefile |grep autogen
#   302  sed "s/autogen/echo autogen/g" Makefile
#   303  sed -i "s/autogen/echo autogen/g" Makefile
#   318  find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort |while read one; do echo $one; rm -f $one; done
#   319  find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort
function libogg(){
  log "Downloading libOgg..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libogg
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libogg
  branch="--branch=v1.3.5"
  repo=$GITHUB/xiph/ogg
  rm -rf /tmp/libogg; git clone --depth=1 $branch $repo /tmp/libogg
  log "Configuring libOgg..."
  (
      cd /tmp/libogg
      bash autogen.sh
      ./configure --enable-static --disable-shared
  )
  log "Compiling libOgg..."
  make -C /tmp/libogg -j$(nproc)
  log "Installing libOgg..."
  make -C /tmp/libogg install #DESTDIR=$(xx-info sysroot) 
}

function libflac(){
  log "Downloading libFLAC..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libflac
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libflac
  branch="--branch=1.3.4"
  repo=$GITHUB/xiph/flac
  rm -rf /tmp/libflac; git clone --depth=1 $branch $repo /tmp/libflac
  log "Configuring libFLAC..."
  (
      cd /tmp/libflac
      bash autogen.sh
      ./configure --enable-static --disable-shared
  )
  log "Compiling libFLAC..."
  make -C /tmp/libflac -j$(nproc)
  log "Installing libFLAC..."
  make -C /tmp/libflac install #DESTDIR=$(xx-info sysroot) 
}

function libvorbis(){
  log "Downloading libVorbis..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libvorbis
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libvorbis
  branch="--branch=v1.3.7"
  repo=$GITHUB/xiph/vorbis
  rm -rf /tmp/libvorbis; git clone --depth=1 $branch $repo /tmp/libvorbis
  log "Configuring libVorbis..."
  (
      cd /tmp/libvorbis
      bash autogen.sh
      ./configure --enable-static --disable-shared
  )
  log "Compiling libVorbis..."
  make -C /tmp/libvorbis -j$(nproc)
  log "Installing libVorbis..."
  make -C /tmp/libvorbis install #DESTDIR=$(xx-info sysroot) 
}

function libopus(){
  log "Downloading libOpus..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libopus
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libopus
  branch="--branch=v1.3.1"
  repo=$GITHUB/xiph/opus
  rm -rf /tmp/libopus; git clone --depth=1 $branch $repo /tmp/libopus
  log "Configuring libOpus..."
  (
      cd /tmp/libopus
      bash autogen.sh
      ./configure --enable-static --disable-shared
  )
  log "Compiling libOpus..."
  make -C /tmp/libopus -j$(nproc)
  log "Installing libOpus..."
  make -C /tmp/libopus install #DESTDIR=$(xx-info sysroot) 
}



function libsndfile(){
  log "Downloading libSndfile..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libsndfile
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libsndfile
  branch="--branch=1.0.31"
  repo=$GITHUB/libsndfile/libsndfile
  rm -rf /tmp/libsndfile; git clone --depth=1 $branch $repo /tmp/libsndfile
  log "Configuring libSndfile..."
  (
      cd /tmp/libsndfile
      sed -i "s/autogen --version/echo autogen --version/g" autogen.sh
      apk add python2 #
      bash autogen.sh
      #
      ./configure --enable-static --disable-shared
      sed -i "s/autogen/echo autogen/g" Makefile #fix
  )
  log "Compiling libSndfile..."
  make -C /tmp/libsndfile -j$(nproc)
  log "Installing libSndfile..."
  make -C /tmp/libsndfile install #DESTDIR=$(xx-info sysroot) 
}

#
# Build pulseaudio
#
function pulseaudio(){
log "Downloading PULSEAUDIO..."
rm -rf /tmp/pulseaudio; # mkdir -p /tmp/pulseaudio
# down_catfile ${PULSEAUDIO_URL} | tar -zx --strip 1 -C /tmp/pulseaudio
PULSEAUDIO_VER=br-v13-99-3 #v16.99.1  v15.99.1  v14.99.2
branch="--branch=$PULSEAUDIO_VER"
# --depth=1 ##./git-version-gen .tarball-version
git clone $branch https://gitee.com/g-system/fk-pulseaudio /tmp/pulseaudio #;
log "Configuring PULSEAUDIO..."
cd /tmp/pulseaudio #&& ./bootstrap;
# ./configure  --enable-static --prefix=$TARGETPATH
# make
export CMAKE_BINARY_DIR=$TARGETPATH
bash sam-build.sh

log "Install PULSEAUDIO..."
# make;
make install;

# view
ls -lh /tmp/pulseaudio/src/pa*
xx-verify --static /tmp/pulseaudio/src/pulseaudio
xx-verify --static /tmp/pulseaudio/src/pactl
}


# https://blog.csdn.net/Zxiuping/article/details/120764834
git config --global http.sslVerify false ##关闭SSL验证
case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    pulseaudio
    ;;
# dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
# 尝试重编译deps ogg> [opus]flac,vorbis> sndfile  (ref: docs/core/pulse05.md)
    # ogg-v135 https://hub.yzuu.cf/xiph/ogg #324, Ogg media container Sep 3, 2000+
    # opus-v131 https://hub.yzuu.cf/xiph/opus #2k, audio compression Nov 25, 2007+
    # Flac-v134 https://hub.yzuu.cf/xiph/flac #1.4k, Free Lossless Audio Codec Dec 10, 2000+ (2012+)
    # vorbis/enc-v137 https://hub.yzuu.cf/xiph/vorbis #432, Ogg Vorbis audio format Jul 11, 1999+
    # libsndfile-v1.0.31 https://hub.yzuu.cf/libsndfile/libsndfile #1.3k, A C library for reading and writing sound files Jan 18, 2004+
b_deps) #TODO1
    bash /src/x-pulseaudio/build.sh libogg &
    wait
    bash /src/x-pulseaudio/build.sh libopus &
    bash /src/x-pulseaudio/build.sh libflac &
    bash /src/x-pulseaudio/build.sh libvorbis &
    wait
    bash /src/x-pulseaudio/build.sh libsndfile &
    wait
    ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/pulseaudio-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
