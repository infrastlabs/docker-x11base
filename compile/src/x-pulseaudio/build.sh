#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-pulseaudio}"
source /src/common.sh

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
# 2026-11-24 方案二交叉: pulse 栈共用交叉环境(ogg→flac→vorbis→opus→sndfile→pulseaudio 全链)。
# 设置 CROSS_HOST/XX_DESTDIR 供各函数 configure 追加 --host、make install 加 DESTDIR(装 sysroot)。
# native(未设 TARGETPLATFORM): 变量留空 → 原路径零影响。
px_cross(){
  CROSS_HOST=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export CXX=xx-clang++
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    log "px: CROSS ($XX_TRIPLE)"
  fi
}

function libogg(){
  px_cross
  log "Downloading libOgg..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libogg
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libogg
  branch="--branch=v1.3.5"
  repo=https://gitee.com/g-system/fk-xiph-ogg #$GITHUB/xiph/ogg
  rm -rf /tmp/libogg; gitclone $repo /tmp/libogg $branch
  log "Configuring libOgg..."
  (
      cd /tmp/libogg
      bash autogen.sh
      ./configure --enable-static --disable-shared $CROSS_HOST
  )
  log "Compiling libOgg..."
  make -C /tmp/libogg -j$(nproc)
  log "Installing libOgg..."
  make -C /tmp/libogg install ${XX_DESTDIR:-}
  cp "$(find /tmp/libogg -name 'libogg.a' 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true
  xx_la_fix
}

function libflac(){
  px_cross
  log "Downloading libFLAC..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libflac
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libflac
  branch="--branch=1.3.4"
  repo=https://gitee.com/g-system/fk-xiph-flac #$GITHUB/xiph/flac
  rm -rf /tmp/libflac; gitclone $repo /tmp/libflac $branch
  log "Configuring libFLAC..."
  (
      cd /tmp/libflac
      bash autogen.sh
      ./configure --enable-static --disable-shared $CROSS_HOST
  )
  log "Compiling libFLAC..."
  make -C /tmp/libflac -j$(nproc)
  log "Installing libFLAC..."
  make -C /tmp/libflac install ${XX_DESTDIR:-}
  cp "$(find /tmp/libflac -name 'libFLAC.a' 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true
  xx_la_fix
}

function libvorbis(){
  px_cross
  log "Downloading libVorbis..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libvorbis
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libvorbis
  branch="--branch=v1.3.7"
  repo=https://gitee.com/g-system/fk-xiph-vorbis #$GITHUB/xiph/vorbis
  rm -rf /tmp/libvorbis; gitclone $repo /tmp/libvorbis $branch
  log "Configuring libVorbis..."
  (
      cd /tmp/libvorbis
      bash autogen.sh
      ./configure --enable-static --disable-shared $CROSS_HOST
  )
  log "Compiling libVorbis..."
  make -C /tmp/libvorbis -j$(nproc)
  log "Installing libVorbis..."
  make -C /tmp/libvorbis install ${XX_DESTDIR:-}
  for _a in $(find /tmp/libvorbis -name 'libvorbis*.a' 2>/dev/null); do cp "$_a" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true; done
  xx_la_fix
}

function libopus(){
  px_cross
  log "Downloading libOpus..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libopus
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libopus
  branch="--branch=v1.3.1"
  repo=https://gitee.com/g-system/fk-xiph-opus #$GITHUB/xiph/opus
  rm -rf /tmp/libopus; gitclone $repo /tmp/libopus $branch
  log "Configuring libOpus..."
  (
      cd /tmp/libopus
      bash autogen.sh
      ./configure --enable-static --disable-shared $CROSS_HOST
  )
  log "Compiling libOpus..."
  make -C /tmp/libopus -j$(nproc)
  log "Installing libOpus..."
  make -C /tmp/libopus install ${XX_DESTDIR:-}
  cp "$(find /tmp/libopus -name 'libopus.a' 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true
  xx_la_fix
}



function libsndfile(){
  px_cross
  log "Downloading libSndfile..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libsndfile
  # down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libsndfile
  branch="--branch=1.0.31"
  repo=https://gitee.com/g-system/fk-libsndfile #$GITHUB/libsndfile/libsndfile
  rm -rf /tmp/libsndfile; gitclone $repo /tmp/libsndfile $branch
  log "Configuring libSndfile..."
  (
      cd /tmp/libsndfile
      sed -i "s/autogen --version/echo autogen --version/g" autogen.sh
      apk add python2 #
      bash autogen.sh
      #
      # 2026-11-24 交叉: --disable-full-suite 禁构建/安装 programs(sndfile-play/sndfile-info 等,
      #   交叉下链接失败致 make all/install 中断, .pc/.h 没落 sysroot); 只产 libsndfile.a 即可
      ./configure --enable-static --disable-shared --disable-full-suite $CROSS_HOST
      sed -i "s/autogen/echo autogen/g" Makefile #fix
  )
  log "Compiling libSndfile..."
  make -C /tmp/libsndfile -j$(nproc)
  log "Installing libSndfile..."
  make -C /tmp/libsndfile install ${XX_DESTDIR:-}
  cp "$(find /tmp/libsndfile -name 'libsndfile.a' 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true
  xx_la_fix
}

#
# Build pulseaudio
#
function pulseaudio(){
  px_cross
  log "Downloading PULSEAUDIO..."
  rm -rf /tmp/pulseaudio; # mkdir -p /tmp/pulseaudio
  # down_catfile ${PULSEAUDIO_URL} | tar -zx --strip 1 -C /tmp/pulseaudio
  PULSEAUDIO_VER=br-v13-99-3 #v16.99.1  v15.99.1  v14.99.2
  branch="--branch=$PULSEAUDIO_VER"
  # --depth=1 ##./git-version-gen .tarball-version
  gitclone https://gitee.com/g-system/fk-pulseaudio /tmp/pulseaudio $branch #;
  log "Configuring PULSEAUDIO..."
  cd /tmp/pulseaudio #&& ./bootstrap;
  # 2026-11-16: CI 干净环境 git-version-gen failed 根因——gitclone 快照恢复的 .git 无 version tag
  # (git describe 失败) 且无 .tarball-version; configure.ac:24 用 m4_esyscmd(./git-version-gen .tarball-version),
  # 只要存在 .tarball-version(内容数字开头) 即读它、不依赖 git describe。此处显式生成绕过。
  # PULSEAUDIO_VER=br-v13-99-3 → 版本 13.99.3 (去 br-v 前缀; git-version-gen 只接受数字开头, v 前缀判 damaged)
  echo "${PULSEAUDIO_VER#br-v}" > .tarball-version
  log "wrote .tarball-version=$(cat .tarball-version)"
  # 去 --disable-glib2（sam-build.sh 原禁 glib mainloop → 无 libpulse-mainloop-glib.a；
  #   pavucontrol 需要。只动构建开关，不碰 fk 定制源码，不影响原有静态库）。
  sed -i '/--disable-glib2/d' sam-build.sh
  # 装到 /usr/local/static/pulseaudio（外部可指定 CMAKE_BINARY_DIR；未指定默认 TARGETPATH）
  export CMAKE_BINARY_DIR="${CMAKE_BINARY_DIR:-$TARGETPATH}"
  # 2026-11-24 交叉: sam-build.sh 第2行 `args="--disable-shared ... --with-database=simple"` 重置 args,
  # 且第60行 `./configure ... $args` 完全忽略 $@/$1(传 --host 作位置参数被丢) -> 交叉必须在 gitclone 后
  # sed 把 $CROSS_HOST 注入 args 赋值尾部(此处在 pulseaudio() 同 shell, $CROSS_HOST 由 px_cross 已设),
  # native(CROSS_HOST 空) sed 追加空串=原样。
  [ -n "$CROSS_HOST" ] && sed -i "s|--with-database=simple\"|--with-database=simple $CROSS_HOST\"|" sam-build.sh
  # 2026-11-24 交叉: libtool 默认搜 native /usr/local/lib 优先于 -L$XX_SYSROOT/usr/local/lib,
  #   -lFLAC/-logg 等解析到 native x86 .a -> wrong format. 把 sysroot(arm64) deps .a/.la 拷到
  #   native /usr/local/lib 覆盖 x86(本容器交叉构建器, native deps 不再用; native 重编自覆)。
  #   deps: FLAC/ogg/opus/sndfile/vorbis*/vorbisfile。仅 is-cross 生效。
  if [ -n "$XX_SYSROOT" ]; then
    for _f in libFLAC libogg libopus libsndfile libvorbis libvorbisenc libvorbisfile; do
      for _e in a la; do
        [ -f "$XX_SYSROOT/usr/local/lib/$_f.$_e" ] && cp "$XX_SYSROOT/usr/local/lib/$_f.$_e" /usr/local/lib/$_f.$_e
      done
    done
    log "px: deps arm64 .a/.la 拷 native /usr/local/lib (libtool 优先 native 搜索)"
  fi
  bash sam-build.sh $CROSS_HOST

  log "Install PULSEAUDIO..."
  # make;
  make install ${XX_DESTDIR:-};
  for _a in $(find /tmp/pulseaudio/src -name 'libpulse*.a' 2>/dev/null); do cp "$_a" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true; done
  xx_la_fix

  # view
  ls -lh /tmp/pulseaudio/src/pa*
  xx-verify --static /tmp/pulseaudio/src/pulseaudio
  xx-verify --static /tmp/pulseaudio/src/pactl
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec pulseaudio || exit 1
    ;;
    # dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
    # 尝试重编译deps ogg> [opus]flac,vorbis> sndfile  (ref: docs/core/pulse05.md)
      # ogg-v135 https://hub.yzuu.cf/xiph/ogg #324, Ogg media container Sep 3, 2000+
      # opus-v131 https://hub.yzuu.cf/xiph/opus #2k, audio compression Nov 25, 2007+
      # Flac-v134 https://hub.yzuu.cf/xiph/flac #1.4k, Free Lossless Audio Codec Dec 10, 2000+ (2012+)
      # vorbis/enc-v137 https://hub.yzuu.cf/xiph/vorbis #432, Ogg Vorbis audio format Jul 11, 1999+
      # libsndfile-v1.0.31 https://hub.yzuu.cf/libsndfile/libsndfile #1.3k, A C library for reading and writing sound files Jan 18, 2004+
b_deps) #TODO1
    doExec_mark "x-pulseaudio b_deps grp1"
    doExec bash /src/x-pulseaudio/build.sh libogg &
    wait
    doExec_check || exit 1
    doExec_mark "x-pulseaudio b_deps grp2"
    doExec bash /src/x-pulseaudio/build.sh libopus &
    doExec bash /src/x-pulseaudio/build.sh libflac &
    doExec bash /src/x-pulseaudio/build.sh libvorbis &
    wait
    doExec_check || exit 1
    doExec_mark "x-pulseaudio b_deps grp3"
    doExec bash /src/x-pulseaudio/build.sh libsndfile &
    wait
    doExec_check || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
