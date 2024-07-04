#!/bin/sh
set -e
source /src/common.sh

# Define software download URLs.
LIBXRANDR_VERSION=1.5.3
LIBXRANDR_URL=https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VERSION}.tar.xz

gh=https://ghproxy.com/
gh=https://gh.api.99988866.xyz/
gh=https://ghps.cc/
# 
FDKAAC_VER=2.0.2
FDKAAC_URL=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${FDKAAC_VER}.tar.gz

#
# Build libXrandr.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxrandr(){
  mkdir /tmp/libxrandr
  log "Downloading libXrandr..."
  # curl -# -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libxrandr
  down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C /tmp/libxrandr
  log "Configuring libXrandr..."
  (
      cd /tmp/libxrandr && LDFLAGS= ./configure \
          --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
          --host=$(xx-clang --print-target-triple) \
          --prefix=/usr \
          --disable-shared \
          --enable-static \
          --enable-malloc0returnsnull \
  )
  log "Compiling libXrandr..."
  make -C /tmp/libxrandr -j$(nproc)
  log "Installing libXrandr..."
  make DESTDIR=$(xx-info sysroot) -C /tmp/libxrandr install
}

#
# Build xrdp
#
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err
function fdkaac(){
  # - fdkaac
  # ins fdk-aac:
  # tar -zxf fdk-aac-2.0.2.tar.gz 
  # cd fdk-aac-2.0.2/
  mkdir -p /tmp/fdkaac
  log "Downloading FDKAAC..."
  down_catfile ${FDKAAC_URL} | tar -zx --strip 1 -C /tmp/fdkaac #| tar -xJ
  log "Configuring FDKAAC..."
  cd /tmp/fdkaac && ./configure --enable-static
  make
  make install
}

#
# Build xrdp
#
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err
function xrdp(){
# ./configure
#  220 apk add pam-dev
apk add openssl-dev openssl-libs-static libxcb-static fuse-static 
apk add fuse-dev fdk-aac-dev opus-dev lame-dev;
apk add nasm

# tar -zxf $CACHE/xrdp-${XRDP_VER}.tar.gz -C /tmp;\
# cd /tmp/xrdp-${ver};\
rm -rf /tmp/xrdp; mkdir -p /tmp/xrdp
log "Downloading XRDP..."
# down_catfile ${XRDP_URL} | tar -zx --strip 1 -C /tmp/xrdp
rm -rf /tmp/xrdp;
git clone -b sam-custom --depth=1 https://gitee.com/g-system/fk-xrdp /tmp/xrdp

log "Configuring XRDP..."
cd /tmp/xrdp && ./bootstrap;

# fix code
# #define _GNU_SOURCE=Musl fixes by maxice8 · Pull Request #1673 · neutrinolabs/xrdp
# https://github.com/neutrinolabs/xrdp/pull/1673/files
sed -i "s^putpwent(spw, fd);^// putpwent(spw, fd);^g" ./sesman/verify_user.c

# before ./configure
# deps:
#23 222.8 make[2]: Entering directory '/tmp/xrdp/sesman/chansrv'
#23 222.8   CCLD     xrdp-chansrv
#23 223.0 /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lXrandr
#23 223.0 /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfuse
f=sesman/chansrv/Makefile.am
sed -i "s^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
cat $f |grep lX11 -n

f=sesman/tools/Makefile.am
sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
cat $f |grep lX11 -n

# genkeymap/Makefile.am 
f=genkeymap/Makefile.am 
sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
cat $f |grep lX11 -n

# --disable-pam \
# --disable-pam --enable-static===
# https://github.com/PWN-Term/pwn-packages/blob/df4740ecf3dc3433c869abd515964e60dea7dd0c/packages/xrdp/build.sh
# --disable-shared \ >> --enable-shared \ ##无lib/libvnc.so
# --enable-static \ >> --disable-static \ ##avoid xx.a 
# --enable-devel-all<debug,logging,streamCheck>
./configure \
  --prefix=$TARGETPATH \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --disable-pam \
  --enable-static \
  --enable-shared \
  --enable-devel-all 
  # LIBS="-lcommon" #c.compiler err
  # LIBS="-lrt -lcommon -lcrypto -lssl "
  # --enable-strict-locations
  #CFLAGS='-Wno-format';


# 手动注释行： putpwent;
  # # ERR01: 手动改code;
  # # verify_user.c:221:9: error: implicit declaration of function 'putpwent' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
  # #         putpwent(spw, fd);
  # # vi ./sesman/libsesman/verify_user.c
  # # vi ./sesman/verify_user.c
  # sed -i "s^putpwent(spw, fd);^// putpwent(spw, fd);^g" ./sesman/verify_user.c


# STATIC
  # export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"
  # export LDFLAGS="--static"
  # /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lssl
  # /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lcrypto
  # apk add openssl-libs-static

  # xcb-err:
  # https://pkgs.alpinelinux.org/packages?name=*xcb*&branch=edge&repo=&arch=x86_64&maintainer=
  #   libxcb-static #已装
  #   oth_已装; xcb-util-dev xcb-util已装; xcb-util-xx看着不相关;
  # apk add libxcb-static

# xrdp-chansrv
  # # 禁用fdkaac: --enable-fdkaac \>> --disable-fdkaac \

  # # - **sesman/chansrv/Makefile** [-lX11-xcb -lxcb]
  # # sesman/chansrv/Makefile.am ##foot
  # xrdp_chansrv_LDADD = \
  #   $(top_builddir)/common/libcommon.la \
  #   $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LIBS) \
  #   $(CHANSRV_EXTRA_LIBS)
  # # Makefile @421行
  # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
  # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LI

  # # 添加： -lX11-xcb -lxcb>> 错误少了
  # /mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
  # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
  # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb $(X_EXTRA_LIBS) \

  # # 添加：-lXdmcp -lXau ; >> 只余下sound错误;
  # /mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
  # /mnt2/xrdp-repo-v0.9.23-02 # make -C sesman/chansrv/

  # compile: fdk-aac
  # 添加：-lfdk-aac
  # root@VM-12-9-ubuntu:/mnt/xrdp-repo-v0.9.23-02# cat sesman/chansrv/Makefile |grep lX11 -n
  # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac  $(X_EXTRA_LIBS) \
  
  # # before ./configure
  # sed -i "s^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" sesman/chansrv/Makefile.am
  # cat sesman/chansrv/Makefile.am |grep lX11 -n


# sesman/tools/xrdp-con
  # -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac
  # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/tools/Makefile |grep lX11 -n
  # 411:  $(X_PRE_LIBS) -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac $(X_EXTRA_LIBS)


log "make XRDP..."
make;
log "install XRDP..."
make install;

# # libvnc.so
# cd $TARGETPATH/lib/xrdp
# gcc -shared -o libvnc.so libvnc.a 
}




case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    libxrandr
    fdkaac
    xrdp
    ;;
b_deps)
    bash /src/x-xrdp/build.sh libxrandr &
    bash /src/x-xrdp/build.sh fdkaac &
    wait
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
