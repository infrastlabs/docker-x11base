#!/bin/sh
set -e
source /src/common.sh

#
# Build su-exec > su_exec ##gitac: /src/u-misc/build.sh: line 32: syntax error: bad function name
function su_exec(){
  log "Downloading SU-EXEC..."
  rm -rf /tmp/su-exec; # mkdir -p /tmp/su-exec
  # branch="--branch=$XLUNCH_VER"
  repo=https://gitee.com/g-system/fk-su-exec
  git clone --depth=1 $branch $repo /tmp/su-exec #;
  log "Configuring SU-EXEC..."
  cd /tmp/su-exec #&& ./bootstrap;
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf

    # make
    make su-exec-static

  log "Install SU-EXEC..."
  # make install; #Makefile:无install定义;
  mkdir -p $TARGETPATH/bin/
  \cp -a su-exec-static $TARGETPATH/bin/su-exec
  
  # view
  ls -lh /tmp/su-exec/
  xx-verify --static /tmp/su-exec/su-exec-static
}

#
# Build lrzsz
# export TARGETPATH=/usr/local/static/misc
function lrzsz(){
  log "Downloading LRZSZ..."
  rm -rf /tmp/lrzsz; # mkdir -p /tmp/lrzsz
  # branch="--branch=$LRZSZ_VER"
  repo=https://gitee.com/g-system/fk-lrzsz
  git clone --depth=1 $branch $repo /tmp/lrzsz #;
  log "Configuring LRZSZ..."
  cd /tmp/lrzsz #&& ./bootstrap;
    autoconf 
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf
    ./configure --enable-static --disable-shared --without-libintl-prefix --prefix=$TARGETPATH #ref src/fluxbox/build.sh

    # make
    # make LDFLAGS="-static" #无效 依旧dyn
    make #OK

  log "Install LRZSZ..."
  # make;
  make install;
  rm -f $TARGETPATH/bin/{lrb,lrx,lsb,lsx} #lxb lxx: same with lrz/lsz

  # view
  ls -lh /tmp/lrzsz/
  # src/lrz src/lsz
  xx-verify --static /tmp/lrzsz/src/lrz
  xx-verify --static /tmp/lrzsz/src/lsz
}

#
# Build n2n
function n2n(){
  apk add zstd-static

  log "Downloading N2N..."
  rm -rf /tmp/n2n; # mkdir -p /tmp/n2n
  # branch="--branch=$N2N_VER"
  repo=https://gitee.com/g-system/fk-lucktu-n2n
  git clone --depth=1 $branch $repo /tmp/n2n #;
  log "Configuring N2N..."
  cd /tmp/n2n #&& ./bootstrap;
    bash autogen.sh 
    ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf

    # make
    make LDFLAGS="-static"

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
  xx-verify --static /tmp/n2n/edge
  xx-verify --static /tmp/n2n/supernode
}

#
# Build tinc
function tinc(){
  apk add lzo-dev openssl-dev texinfo openssl-libs-static

  log "Downloading TINC..."
  rm -rf /tmp/tinc; # mkdir -p /tmp/tinc
  # branch="--branch=$TINC_VER"
  repo=https://gitee.com/g-system/fk-tinc
  git clone --depth=1 $branch $repo /tmp/tinc #;
  log "Configuring TINC..."
  cd /tmp/tinc #&& ./bootstrap;
    autoreconf -if
    ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf

    # make
    make LDFLAGS="-static"

  log "Install TINC..."
  # make;
  make install;

  # view
  ls -lh /tmp/tinc/
  xx-verify --static /tmp/tinc/src/tincd
}



case "$1" in
cache)
    echo doCache;
    # down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    imlib2
    lrzsz
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
