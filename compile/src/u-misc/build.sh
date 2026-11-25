#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-u-misc}"
source /src/common.sh

#
# 2026-11-25 交叉: u-misc 四件套(su-exec/lrzsz/n2n/tinc, 均 C 非 C++、configure/make)共用交叉环境
#   (同 x-xbindkeys/x-xrandr)。u-misc 无 X11/GTK 依赖 → 不需 X 静态库; 仅 n2n 需 zstd、tinc 需 lzo/openssl。
#   这些静态库 native 靠函数内 `apk add` 装进根文件系统; 交叉须装进 sysroot → um_cross 里统一 xx-apk(幂等)。
# native(未设 XX_CROSS_FILE): CROSS_HOST/MAKE_CC 留空 → 原路径零影响。
um_cross(){
  CROSS_HOST=""; MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: realloc/malloc/cc_cross 在 cross 下不能 run → 显式 yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    # 头/库搜索前缀 sysroot(双保险: xx-clang 自带 sysroot, configure link-test 需显式 -L)
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # sysroot 补 n2n(zstd)/tinc(lzo/openssl) 静态库(幂等; apk 命中已装则 no-op)
    xx-apk add zstd-static lzo-dev openssl-dev openssl-libs-static
    log "u-misc: CROSS ($XX_TRIPLE)"
  fi
}

# um_verify <binary>...: 交叉用 file 判 static+目标架构, native 走 xx-verify(原路径)。
um_verify(){
  for _b in "$@"; do
    if [ -n "$XX_CROSS_FILE" ]; then
      file $_b | grep -qE "ARM.*statically linked" \
        || { log "u-misc file 非 ARM static: $_b"; exit 1; }
    else
      xx-verify --static $_b || { log "u-misc xx-verify FAILED: $_b"; exit 1; }
    fi
  done
}

#
# Build su-exec > su_exec ##gitac: /src/u-misc/build.sh: line 32: syntax error: bad function name
function su_exec(){
  um_cross
  log "Downloading SU-EXEC..."
  rm -rf /tmp/su-exec; # mkdir -p /tmp/su-exec
  # branch="--branch=$XLUNCH_VER"
  gitclone https://gitee.com/g-system/fk-su-exec /tmp/su-exec $branch #;
  log "Configuring SU-EXEC..."
  cd /tmp/su-exec #&& ./bootstrap;
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf

    # make
    make $MAKE_CC su-exec-static

  log "Install SU-EXEC..."
  # make install; #Makefile:无install定义;
  mkdir -p $TARGETPATH/bin/
  \cp -a su-exec-static $TARGETPATH/bin/su-exec
  
  # view
  ls -lh /tmp/su-exec/
  um_verify /tmp/su-exec/su-exec-static
}

#
# Build lrzsz
# export TARGETPATH=/usr/local/static/misc
function lrzsz(){
  um_cross
  log "Downloading LRZSZ..."
  rm -rf /tmp/lrzsz; # mkdir -p /tmp/lrzsz
  # branch="--branch=$LRZSZ_VER"
  gitclone https://gitee.com/g-system/fk-lrzsz /tmp/lrzsz $branch #;
  log "Configuring LRZSZ..."
  cd /tmp/lrzsz #&& ./bootstrap;
    autoconf 
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf
    ./configure --enable-static --disable-shared --without-libintl-prefix --prefix=$TARGETPATH $CROSS_HOST #ref src/fluxbox/build.sh

    # make
    # make LDFLAGS="-static" #无效 依旧dyn
    make $MAKE_CC #OK

  log "Install LRZSZ..."
  # make;
  make install;
  rm -f $TARGETPATH/bin/{lrb,lrx,lsb,lsx} #lxb lxx: same with lrz/lsz

  # view
  ls -lh /tmp/lrzsz/
  # src/lrz src/lsz
  um_verify /tmp/lrzsz/src/lrz /tmp/lrzsz/src/lsz
}

#
# Build n2n
function n2n(){
  um_cross
  apk add zstd-static

  log "Downloading N2N..."
  rm -rf /tmp/n2n; # mkdir -p /tmp/n2n
  # branch="--branch=$N2N_VER"
  gitclone https://gitee.com/g-system/fk-lucktu-n2n /tmp/n2n $branch #;
  log "Configuring N2N..."
  cd /tmp/n2n #&& ./bootstrap;
    bash autogen.sh 
    ./configure  --enable-static --prefix=$TARGETPATH $CROSS_HOST ##无./configure|autoconf

    # make
    # 交叉不 clobber LDFLAGS: 用 $LDFLAGS(common.sh -static... + sysroot -L); native 仍 "-static"。
    if [ -n "$XX_CROSS_FILE" ]; then
      make $MAKE_CC LDFLAGS="$LDFLAGS"
    else
      make LDFLAGS="-static"
    fi

  log "Install N2N..."
  # make;
  # make install; #--prefix不生效;
    # /tmp/n2n # make install
    # echo "MANDIR=/usr/share/man"
    # MANDIR=/usr/share/man
    # mkdir -p /usr/sbin /usr/share/man/man1 /usr/share/man/man7 /usr/share/man/man8
    # install -m755 supernode /usr/sbin/
    # install -m755 edge /usr/sbin/
    # install -m644 edge.8.gz /usr/share/man/man8/
    # install -m644 supernode.1.gz /usr/share/man/man1/
    # install -m644 n2n.7.gz /usr/share/man/man7/
    # make -C tools install
    # make[1]: Entering directory '/tmp/n2n/tools'
    # Makefile:40: warning: ignoring prerequisites on suffix rule definition
    # install -m755 n2n-benchmark /usr/sbin/
    # make[1]: Leaving directory '/tmp/n2n/tools'  
  mkdir -p $TARGETPATH/sbin/ $TARGETPATH/share/man/{man1,man7,man8}/
  # \cp -a /tmp/n2n/edge /tmp/n2n/supernode $TARGETPATH/sbin/
    install -m755 supernode $TARGETPATH/sbin/
    install -m755 edge $TARGETPATH/sbin/
    install -m644 supernode.1.gz $TARGETPATH/share/man/man1/
    install -m644 n2n.7.gz $TARGETPATH/share/man/man7/
    install -m644 edge.8.gz $TARGETPATH/share/man/man8/
    install -m755 tools/n2n-benchmark $TARGETPATH/sbin/

  # view
  ls -lh /tmp/n2n/
  um_verify /tmp/n2n/edge /tmp/n2n/supernode
}

#
# Build tinc
function tinc(){
  um_cross
  apk add lzo-dev openssl-dev texinfo openssl-libs-static

  log "Downloading TINC..."
  rm -rf /tmp/tinc; # mkdir -p /tmp/tinc
  # branch="--branch=$TINC_VER"
  gitclone https://gitee.com/g-system/fk-tinc /tmp/tinc $branch #;
  log "Configuring TINC..."
  cd /tmp/tinc #&& ./bootstrap;
    autoreconf -if
    ./configure  --enable-static --prefix=$TARGETPATH $CROSS_HOST ##无./configure|autoconf

    # make
    # 交叉不 clobber LDFLAGS: 用 $LDFLAGS; native 仍 "-static"。
    if [ -n "$XX_CROSS_FILE" ]; then
      make $MAKE_CC LDFLAGS="$LDFLAGS"
    else
      make LDFLAGS="-static"
    fi

  log "Install TINC..."
  make install;

  # view
  ls -lh /tmp/tinc/
  um_verify /tmp/tinc/src/tincd
}



case "$1" in
cache)
    echo doCache;
    # down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    doExec su_exec || exit 1
    doExec lrzsz || exit 1
    doExec n2n || exit 1
    doExec tinc || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
