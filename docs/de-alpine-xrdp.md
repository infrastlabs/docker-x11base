

- **xrdp** @C
  - gitsubmodule:libpainter
  - gitsubmodule:librfxcodec

**configure deps**

```bash
$RUN test "yes" != "$COMPILE_XRDP" && exit 0 || echo doMake; \
tar -zxf /src/arm/xrdp-${ver}.tar.gz;\
cd xrdp-${ver};\
./bootstrap;\

# --disable-pam \
# --disable-pam --enable-static===
# https://github.com/PWN-Term/pwn-packages/blob/df4740ecf3dc3433c869abd515964e60dea7dd0c/packages/xrdp/build.sh
./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --disable-pam \
  CFLAGS='-Wno-format';

make;\
make install;



# ./configure
 208 apk add openssl-dev
 apk add openssl-libs-static
#  220 apk add pam-dev
 231 apk add fuse-dev
 245 apk add fdk-aac-dev
 257 apk add opus-dev
#  
 268 apk add lamemp3-dev
 269 apk add mp3lame-dev
 270 apk add libmp3lame-dev
 271 apk add lamemp3*
 apk add lame-dev; #ok
 apk add nasm


# https://pkgs.alpinelinux.org/packages?name=lame&branch=edge&repo=&arch=&maintainer=
# https://pkgs.alpinelinux.org/packages?name=nasm&branch=edge&repo=&arch=&maintainer=
# /mnt2/xrdp-org-repo # 
checking for nasmw... no
checking for yasm... no
configure: error: no nasm (Netwide Assembler) found
configure: error: ./configure failed for librfxcodec
apk add nasm;
# ./cofigure; OK
```

- **make src@master**

```bash
# ====make:
# ERR01:
/mnt2/xrdp-org-repo # make
make[4]: Leaving directory '/mnt2/xrdp-org-repo/librfxcodec'
make[3]: Leaving directory '/mnt2/xrdp-org-repo/librfxcodec'
make[2]: Leaving directory '/mnt2/xrdp-org-repo/librfxcodec'
Making all in sesman
make[2]: Entering directory '/mnt2/xrdp-org-repo/sesman'
Making all in libsesman
make[3]: Entering directory '/mnt2/xrdp-org-repo/sesman/libsesman'
  CC       sesman_access.lo
  CC       sesman_config.lo
  CC       sesman_clip_restrict.lo
  CC       verify_user.lo
verify_user.c:289:9: error: implicit declaration of function 'putpwent' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
        putpwent(spw, fd);
        ^
1 error generated.
make[3]: *** [Makefile:555: verify_user.lo] Error 1
make[3]: Leaving directory '/mnt2/xrdp-org-repo/sesman/libsesman'
make[2]: *** [Makefile:689: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/xrdp-org-repo/sesman'
make[1]: *** [Makefile:504: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xrdp-org-repo'
make: *** [Makefile:436: all] Error 2

# --disable-sesman \ #无用
# ./sesman更名; ./configure.ac注释sesman/xx/Makefile;
# 手动注释行： putpwent;
./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --disable-pam \
  CFLAGS='-Wno-format';

make;


# ERR02: # ./waitforx: Commits on Feb 12, 2023
make[2]: Leaving directory '/mnt2/xrdp-org-repo/keygen'
Making all in waitforx
make[2]: Entering directory '/mnt2/xrdp-org-repo/waitforx'
  CC       waitforx.o
In file included from waitforx.c:5:
/usr/include/sys/signal.h:1:2: error: redirecting incorrect #include <sys/signal.h> to <signal.h> [-Werror,-W#warnings]
#warning redirecting incorrect #include <sys/signal.h> to <signal.h>
 ^
1 error generated.
make[2]: *** [Makefile:457: waitforx.o] Error 1
make[2]: Leaving directory '/mnt2/xrdp-org-repo/waitforx'
make[1]: *** [Makefile:504: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xrdp-org-repo'
make: *** [Makefile:436: all] Error 2
```

- **try: master>> v0.9.23**;

```bash
# try: master>> v0.9.23;
# ref-deb12:
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err


# ERR01: 手动改code;
verify_user.c:221:9: error: implicit declaration of function 'putpwent' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
        putpwent(spw, fd);

/mnt2/xrdp-repo-v0.9.23-02 # vi ./sesman/libsesman/verify_user.c
/mnt2/xrdp-repo-v0.9.23-02 # vi ./sesman/verify_user.c
# make OK; 



# /mnt2/xrdp-repo-v0.9.23-02 # 
/mnt2/xrdp-repo-v0.9.23-02 # ls -lh ./xrdp/xrdp
-rwxr-xr-x    1 root     root        7.9K Oct 30 15:52 ./xrdp/xrdp
/mnt2/xrdp-repo-v0.9.23-02 # ./xrdp/xrdp -h
xrdp 0.9.23
  A Remote Desktop Protocol Server.
  Copyright (C) 2004-2020 Jay Sorg, Neutrino Labs, and all contributors.
  See https://github.com/neutrinolabs/xrdp for more information.

  Configure options:
      --prefix=/usr/local/xrdp
      --enable-vsock
      --enable-fdkaac
      --enable-opus
      --enable-fuse
      --enable-mp3lame
      --enable-pixman
      --disable-pam
      CFLAGS=-Wno-format
      CC=clang

  Compiled with OpenSSL 1.1.1w  11 Sep 2023

Usage: xrdp [options]
   -k, --kill        shut down xrdp
   -h, --help        show help
   -v, --version     show version
   -n, --nodaemon    don\'t fork into background
   -p, --port        tcp listen port
   -f, --fork        fork on new connection
   -c, --config      specify new path to xrdp.ini
       --dump-config display config on stdout on startup
```

- **try static**

```bash
# try static;
# --disable-pam --enable-static===
# https://github.com/PWN-Term/pwn-packages/blob/df4740ecf3dc3433c869abd515964e60dea7dd0c/packages/xrdp/build.sh
##
TERMUX_PKG_VERSION=0.9.16
TERMUX_PKG_SRCURL=https://github.com/neutrinolabs/xrdp/releases/download/v${TERMUX_PKG_VERSION}/xrdp-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=72a86bf3bb8ca3a41905bfa84f500ad73cd23615753f34db7e36278a33c19916
TERMUX_PKG_DEPENDS="libandroid-shmem, libcrypt, libice, libsm, libuuid, libx11, libxau, libxcb, libxfixes, libxdmcp, libxrandr, openssl, procps, tigervnc"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--disable-pam
--enable-static
--with-socketdir=$TERMUX_PREFIX/tmp/.xrdp
"

# https://github.com/PWN-Term/pwn-packages/tree/master/packages/xrdp
# build.sh; +patch x7:
disable-lpthread-link.patch
dont-run-keygen.patch
fix-configs.patch
fix-tmpdir.patch
no-getlogin_r.patch
no-strict-locations.patch
termux-dont-have-shadow.patch

# 
./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --enable-static \
  --disable-pam \
  CFLAGS='-Wno-format';

make;


# --enable-static; ./configure>> make 一把过
# /mnt2/xrdp-repo-v0.9.23-02 # 
/mnt2/xrdp-repo-v0.9.23-02 # echo $?
0
/mnt2/xrdp-repo-v0.9.23-02 # ls -lh ./xrdp/xrdp
-rwxr-xr-x    1 root     root        7.9K Oct 30 15:55 ./xrdp/xrdp
/mnt2/xrdp-repo-v0.9.23-02 # make install
Making install in common
make[1]: Entering directory '/mnt2/xrdp-repo-v0.9.23-02/common'
make[2]: Entering directory '/mnt2/xrdp-repo-v0.9.23-02/common'

/mnt2/xrdp-repo-v0.9.23-02 # ls -lh /usr/local/xrdp/sbin/
total 508K   
-rwxr-xr-x    1 root     root      250.8K Oct 30 15:55 xrdp
-rwxr-xr-x    1 root     root      180.4K Oct 30 15:55 xrdp-chansrv
-rwxr-xr-x    1 root     root       69.3K Oct 30 15:55 xrdp-sesman


# 非static:
# xx-verify --static  /usr/local/xrdp/sbin/xrdp
/mnt2/xrdp-repo-v0.9.23-02 # xx-verify --static  /usr/local/xrdp/sbin/xrdp
file /usr/local/xrdp/sbin/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped


/mnt2/xrdp-repo-v0.9.23-02 # find /usr/local/xrdp/
/usr/local/xrdp/lib/xrdp/libcommon.so.0
/usr/local/xrdp/lib/xrdp/libxrdp.a
/usr/local/xrdp/lib/xrdp/libvnc.la
/usr/local/xrdp/lib/xrdp/libvnc.so
/usr/local/xrdp/lib/libpainter.la
/usr/local/xrdp/lib/pkgconfig
/usr/local/xrdp/lib/pkgconfig/rfxcodec.pc
/usr/local/xrdp/lib/pkgconfig/libpainter.pc
/usr/local/xrdp/lib/pkgconfig/xrdp.pc
/usr/local/xrdp/lib/librfxencode.a
/usr/local/xrdp/lib/librfxencode.la
/usr/local/xrdp/sbin
/usr/local/xrdp/sbin/xrdp-chansrv
/usr/local/xrdp/sbin/xrdp-sesman
/usr/local/xrdp/sbin/xrdp
/usr/local/xrdp/share
/usr/local/xrdp/share/xrdp
/usr/local/xrdp/share/xrdp/xrdp_logo.bmp
/usr/local/xrdp/share/xrdp/xrdp24b.bmp
/usr/local/xrdp/share/xrdp/cursor1.cur
/usr/local/xrdp/share/xrdp/cursor0.cur
/usr/local/xrdp/share/xrdp/ad256.bmp
/usr/local/xrdp/share/xrdp/ad24b.bmp
/usr/local/xrdp/share/xrdp/xrdp256.bmp
/usr/local/xrdp/share/xrdp/sans-10.fv1
/usr/local/xrdp/share/man
/usr/local/xrdp/share/man/man1
/usr/local/xrdp/share/man/man1/xrdp-dis.1
/usr/local/xrdp/share/man/man8
/usr/local/xrdp/share/man/man8/xrdp.8
/usr/local/xrdp/share/man/man8/xrdp-chansrv.8
/usr/local/xrdp/share/man/man8/xrdp-keygen.8
/usr/local/xrdp/share/man/man8/xrdp-genkeymap.8
/usr/local/xrdp/share/man/man8/xrdp-sesrun.8
/usr/local/xrdp/share/man/man8/xrdp-sesman.8
/usr/local/xrdp/share/man/man8/xrdp-sesadmin.8
/usr/local/xrdp/share/man/man5
/usr/local/xrdp/share/man/man5/xrdp.ini.5
/usr/local/xrdp/share/man/man5/sesman.ini.5


# ref-xdpy
CPPFLAGS = -MMD
CFLAGS = -Wall -Werror -std=gnu11 -Os -fomit-frame-pointer
LDFLAGS = -static -Wl,--strip-all


# ref-openbox
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

export CC=xx-clang-wrapper
export CXX=xx-clang++

# ref-fontconfig
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++
```

- **static-try02**

```bash
# static-try02:
export CC=xx-clang
export CXX=xx-clang++
/mnt2/xrdp-repo-v0.9.23-02 # xx-verify --static ./xrdp/.libs/xrdp 
file ./xrdp/.libs/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped


/mnt2/xrdp-repo-v0.9.23-02 # env |grep FLAGS
/mnt2/xrdp-repo-v0.9.23-02 # export CFLAGS="-Os -fomit-frame-pointer"
/mnt2/xrdp-repo-v0.9.23-02 # export CXXFLAGS="$CFLAGS"
/mnt2/xrdp-repo-v0.9.23-02 # export CPPFLAGS="$CFLAGS"
/mnt2/xrdp-repo-v0.9.23-02 # export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
/mnt2/xrdp-repo-v0.9.23-02 # env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=-Wl,--strip-all -Wl,--as-needed
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer
# xx-verify --static ./xrdp/.libs/xrdp #还是动态库依赖

/mnt2/xrdp-repo-v0.9.23-02 # export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
# xx-verify --static ./xrdp/.libs/xrdp #还是动态库依赖


# 
./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --enable-static \
  --disable-shared \
  --enable-strict-locations \
  --disable-pam \
  CFLAGS='-Wno-format';

make;


# xrdp will be compiled with:
  mp3lame                 yes
  opus                    yes
  fdkaac                  yes
  jpeg                    no
  turbo jpeg              no
  rfxcodec                yes
  painter                 yes
  pixman                  yes
  fuse                    yes
  ipv6                    no
  ipv6only                no
  vsock                   yes
  auth mechanism          Builtin
  rdpsndaudin             no
  with imlib2             no
  development logging     no
  development streamcheck no
  strict_locations        no
  unit tests performable  no
  prefix                  /usr/local/xrdp
  exec_prefix             ${prefix}
  libdir                  ${exec_prefix}/lib
  bindir                  ${exec_prefix}/bin
  sysconfdir              /etc
  pamconfdir              /etc/pam.d

  CFLAGS = -Wno-format -Wall -Wwrite-strings -Werror -O2
  LDFLAGS = -static -Wl,--strip-all -Wl,--as-needed

# /mnt2/xrdp-repo-v0.9.23-02 # xx-verify --static ./xrdp/.libs/xrdp 
file ./xrdp/.libs/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped



# 重clone, 再编译; >> 还是动态库依赖
 461 git clone --branch v0.9.23 https://ghproxy.com/https://github.com/neutrinolabs/xrdp xrdp-repo-v0.9.23
 462 cd xrdp-repo-v0.9.23
 463 vi ./sesman/verify_user.c
 475 ./bootstrap 
 464 ./configure \

# --enable-strict-locations \
# --disable-shared
/mnt2/xrdp-repo-v0.9.23 # make install
/mnt2/xrdp-repo-v0.9.23 # xx-verify --static  /usr/local/xrdp/sbin/xrdp
file /usr/local/xrdp/sbin/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped

# info01:
/mnt2/xrdp-repo-v0.9.23 # du -sh * |grep M
28.0K   Makefile
4.0K    Makefile.am
28.0K   Makefile.in
8.0K    README.md
2.5M    autom4te.cache
1.2M    common
4.2M    libpainter
5.1M    librfxcodec
1.7M    libxrdp
3.5M    sesman
2.4M    xrdp


/mnt2/xrdp-repo-v0.9.23 # ls xrdp/xrdp -lh
-rwxr-xr-x    1 root     root      422.3K Oct 30 16:37 xrdp/xrdp
/mnt2/xrdp-repo-v0.9.23 # xx-verify --static xrdp/xrdp
file xrdp/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped

/mnt2/xrdp-repo-v0.9.23 # ./xrdp/xrdp -h
xrdp 0.9.23
  A Remote Desktop Protocol Server.
  Copyright (C) 2004-2020 Jay Sorg, Neutrino Labs, and all contributors.
  See https://github.com/neutrinolabs/xrdp for more information.
  Configure options:
      --prefix=/usr/local/xrdp
      --enable-vsock
      --enable-fdkaac
      --enable-opus
      --enable-fuse
      --enable-mp3lame
      --enable-pixman
      --enable-static
      --disable-shared
      --enable-strict-locations
      --disable-pam
      CFLAGS=-Wno-format
      CC=xx-clang
      LDFLAGS=-static -Wl,--strip-all -Wl,--as-needed
      CPPFLAGS=-Os -fomit-frame-pointer
  Compiled with OpenSSL 1.1.1w  11 Sep 2023

Usage: xrdp [options]
   -k, --kill        shut down xrdp
   -h, --help        show help
   -v, --version     show version
   -n, --nodaemon    don\'t fork into background
   -p, --port        tcp listen port
   -f, --fork        fork on new connection
   -c, --config      specify new path to xrdp.ini
       --dump-config display config on stdout on startup

/mnt2/xrdp-repo-v0.9.23 # export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"

# ./configure
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/sesman/chansrv'
make[3]: Entering directory '/mnt2/xrdp-repo-v0.9.23/sesman'
  CC       sesman.o
  CCLD     xrdp-sesman
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lssl
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lcrypto
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:595: xrdp-sesman] Error 1
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/sesman'
make[2]: *** [Makefile:716: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/sesman'
make[1]: *** [Makefile:483: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xrdp-repo-v0.9.23'
make: *** [Makefile:415: all] Error 2
```

- **libcrypto,libssl** @openssl-libs-static

```bash
# ./sesman/ ssl,cripto库错误;>> ./configure.ac 移除sesman/Makefile不管用
#   ./Makefile.am内SUBDIRS = sesman \整个目录移除()
/mnt2/xrdp-repo-v0.9.23 # ls -F sesman/ |grep "/$"
chansrv/
libscp/
tools/


# 
apk add pam? #pam@Alpine 没得包
# https://pkgs.alpinelinux.org/contents?file=pam&path=&name=&branch=edge
  # --disable-pam \
  # CFLAGS='-Wno-format';
./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --enable-static \
  --disable-shared \
  --enable-strict-locations \
  --disable-pam 
make;

# openssl-libs-static
# https://pkgs.alpinelinux.org/packages?name=*ssl*&branch=edge&repo=&arch=&maintainer=
/mnt2/xrdp-repo-v0.9.23 # apk add openssl-libs-static
/mnt2/xrdp-repo-v0.9.23 # find /usr/lib |grep cryp
/usr/lib/libcrypto.so.1.1
/usr/lib/libcrypto.so
/usr/lib/libcrypto.so.3
/usr/lib/libcrypto.a
/usr/lib/libgcrypt.so.20.3.4
/usr/lib/libgcrypt.so.20
/usr/lib/libgcrypt.so
/usr/lib/libgcrypt.a
/usr/lib/libcrypt.a
/mnt2/xrdp-repo-v0.9.23 # find /usr/lib |grep ssl.a
/usr/lib/libssl.a


# 生成OK;
/mnt2/xrdp-repo-v0.9.23 # make
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/tools/devel'
make[3]: Entering directory '/mnt2/xrdp-repo-v0.9.23/tools'
make[3]: Nothing to be done for 'all-am'.
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/tools'
make[2]: Leaving directory '/mnt2/xrdp-repo-v0.9.23/tools'
make[2]: Entering directory '/mnt2/xrdp-repo-v0.9.23'
make[2]: Leaving directory '/mnt2/xrdp-repo-v0.9.23'
make[1]: Leaving directory '/mnt2/xrdp-repo-v0.9.23'
/mnt2/xrdp-repo-v0.9.23 # echo $?
0

# 静态文件;
/mnt2/xrdp-repo-v0.9.23 # ls -lh xrdp/xrdp
-rwxr-xr-x    1 root     root        3.3M Oct 31 06:56 xrdp/xrdp
/mnt2/xrdp-repo-v0.9.23 # xx-verify --static xrdp/xrdp
/mnt2/xrdp-repo-v0.9.23 # echo $?
0
```

- full-build @xrdp-repo-v0.9.23-02

```bash
# ENV
/mnt2/xrdp-repo-v0.9.23-02 # env |egrep "CC|CXX|FLAGS"
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=--static -static -Wl,--strip-all -Wl,--as-needed
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer
CXX=xx-clang++
CC=xx-clang

# full build(with sesman)
# ./configure xx
/mnt2/xrdp-repo-v0.9.23-02 # make
/mnt2/xrdp-repo-v0.9.23-02 # make install
/mnt2/xrdp-repo-v0.9.23-02 # ls /usr/local/xrdp/bin/ -lh
total 5M     
-rwxr-xr-x    1 root     root       18.0K Oct 31 07:07 xrdp-dis
-rwxr-xr-x    1 root     root       18.9K Oct 31 07:07 xrdp-genkeymap
-rwxr-xr-x    1 root     root       19.6K Oct 31 07:07 xrdp-keygen
-rwxr-xr-x    1 root     root        2.4M Oct 31 07:07 xrdp-sesadmin
-rwxr-xr-x    1 root     root        2.4M Oct 31 07:07 xrdp-sesrun
/mnt2/xrdp-repo-v0.9.23-02 # ls /usr/local/xrdp/sbin/ -lh
total 6M     
-rwxr-xr-x    1 root     root        3.3M Oct 31 07:07 xrdp
-rwxr-xr-x    1 root     root      180.4K Oct 31 07:07 xrdp-chansrv
-rwxr-xr-x    1 root     root        2.5M Oct 31 07:07 xrdp-sesman
/mnt2/xrdp-repo-v0.9.23-02 # cp -a /usr/local/xrdp/ /mnt2/xrdp-static-alpine



# validate01: tenVM2-ubt2004>> ./xrdp-chansrv: No such file or directory
# root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine/sbin# ll
total 6100
drwxr-xr-x 2 root root    4096 Oct 31 15:07 ./
drwxr-xr-x 8 root root    4096 Oct 31 00:38 ../
-rwxr-xr-x 1 root root 3435264 Oct 31 15:07 xrdp*
-rwxr-xr-x 1 root root  184712 Oct 31 15:07 xrdp-chansrv*
-rwxr-xr-x 1 root root 2611696 Oct 31 15:07 xrdp-sesman*
# root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine/sbin# ./xrdp -h
xrdp 0.9.23
  A Remote Desktop Protocol Server.
  Copyright (C) 2004-2020 Jay Sorg, Neutrino Labs, and all contributors.
  See https://github.com/neutrinolabs/xrdp for more information.
  Configure options:
      --prefix=/usr/local/xrdp
      --enable-vsock
      --enable-fdkaac
      --enable-opus
      --enable-fuse
      --enable-mp3lame
      --enable-pixman
      --enable-static
      --disable-shared
      --enable-strict-locations
      --disable-pam
      CC=xx-clang
      CFLAGS=-Os -fomit-frame-pointer
      LDFLAGS=--static -static -Wl,--strip-all -Wl,--as-needed
      CPPFLAGS=-Os -fomit-frame-pointer
  Compiled with OpenSSL 1.1.1w  11 Sep 2023
Usage: xrdp [options]
   -k, --kill        shut down xrdp
   -h, --help        show help
   -v, --version     show version
   -n, --nodaemon    don\'t fork into background
   -p, --port        tcp listen port
   -f, --fork        fork on new connection
   -c, --config      specify new path to xrdp.ini
       --dump-config display config on stdout on startup
# root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine/sbin# ./xrdp-sesman  -h
Usage: xrdp-sesman [options]
   -k, --kill        shut down xrdp-sesman
   -h, --help        show help
   -v, --version     show version
   -n, --nodaemon    don\'t fork into background
   -c, --config      specify new path to sesman.ini
       --dump-config display config on stdout on startup
# root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine/sbin# 
# root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine/sbin# ./xrdp-chansrv 
-bash: ./xrdp-chansrv: No such file or directory

# validate02: xrdp-chansrv 非静态编译;
/mnt2/xrdp-repo-v0.9.23-02 # cd /usr/local/xrdp/sbin/
/usr/local/xrdp/sbin # ls
xrdp          xrdp-chansrv  xrdp-sesman
/usr/local/xrdp/sbin # xx-verify --static xrdp
/usr/local/xrdp/sbin # xx-verify --static xrdp-sesman 
/usr/local/xrdp/sbin # xx-verify --static xrdp-chansrv 
file xrdp-chansrv is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped
/usr/local/xrdp/sbin # 
```

## xrdp-chansrv staticBuild

```bash
# ldd xrdp-chansrv
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # xx-verify --static /usr/local/xrdp/sbin/xrdp-chansrv 
file /usr/local/xrdp/sbin/xrdp-chansrv is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # ldd /usr/local/xrdp/sbin/xrdp-chansrv 
        /lib/ld-musl-x86_64.so.1 (0x7f4a2acf4000)
        libcommon.so.0 => /usr/local/xrdp/lib/xrdp/libcommon.so.0 (0x7f4a2aca9000)
        libssl.so.1.1 => /lib/libssl.so.1.1 (0x7f4a2ac28000)
        libcrypto.so.1.1 => /lib/libcrypto.so.1.1 (0x7f4a2a9a5000)
        libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7f4a2a99d000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7f4a2a98a000)
        libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f4a2a97e000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7f4a2a85b000)
        libfuse.so.2 => /usr/lib/libfuse.so.2 (0x7f4a2a820000)
        libfdk-aac.so.2 => /usr/lib/libfdk-aac.so.2 (0x7f4a2a72d000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7f4a2a6cd000)
        libmp3lame.so.0 => /usr/lib/libmp3lame.so.0 (0x7f4a2a661000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f4a2acf4000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f4a2a63a000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7f4a2a635000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f4a2a62d000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f4a2a61a000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7f4a2a60e000)

# try01 清理so, 重构建; (上一把无错: 之前未加LDFLAGS=--static -static生成的*.o?)
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # rm -f *.o
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # make
  CC       chansrv.o
  CC       chansrv_common.o
  CC       chansrv_config.o
  CC       chansrv_fuse.o
  CC       chansrv_xfs.o
  CC       clipboard.o
  CC       clipboard_file.o
  CC       devredir.o
  CC       fifo.o
  CC       irp.o
  CC       rail.o
  CC       smartcard.o
  CC       smartcard_pcsc.o
  CC       sound.o
  CC       xcommon.o
  CC       audin.o
  CCLD     xrdp-chansrv
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfuse
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfdk-aac
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [Makefile:509: xrdp-chansrv] Error 1


# apk add fuse-static
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # find /usr/lib |grep fuse
/usr/lib/libfuse.so
/usr/lib/libfuse.a
/usr/lib/pkgconfig/fuse.pc
/usr/lib/libfuse.so.2.9.9
/usr/lib/libfuse.so.2
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # find /usr/lib |grep fdk
/usr/lib/libfdk-aac.so
/usr/lib/libfdk-aac.so.2
/usr/lib/pkgconfig/fdk-aac.pc
/usr/lib/libfdk-aac.so.2.0.2

# https://pkgs.alpinelinux.org/contents?file=libfdk-aac.a&path=&name=&branch=edge #无
# https://pkgs.alpinelinux.org/contents?file=libfuse.a&path=&name=&branch=edge #有
# 禁用fdkaac: --enable-fdkaac \>> --disable-fdkaac \


./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --disable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --enable-static \
  --disable-shared \
  --enable-strict-locations \
  --disable-pam 
make;


# 禁用fdkaac: libx11> xcb_xxx未定义;
# /mnt2/xrdp-repo-v0.9.23-02 #
make[3]: Nothing to be done for 'all'.
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/tools'
Making all in chansrv
make[3]: Entering directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
  CCLD     xrdp-chansrv
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `require_socket':
xcb_io.c:(.text+0x54a): undefined reference to `xcb_take_socket'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_event':
xcb_io.c:(.text+0x60b): undefined reference to `xcb_poll_for_queued_event'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_io.c:(.text+0x612): undefined reference to `xcb_poll_for_event'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_response':
xcb_io.c:(.text+0x7aa): undefined reference to `xcb_poll_for_reply64'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XSend':
xcb_io.c:(.text+0x9db): undefined reference to `xcb_writev'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XEventsQueued':
xcb_io.c:(.text+0xab5): undefined reference to `xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReadEvents':
xcb_io.c:(.text+0xbc5): undefined reference to `xcb_wait_for_event'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_io.c:(.text+0xca5): undefined reference to `xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XAllocIDs':
xcb_io.c:(.text+0xd88): undefined reference to `xcb_generate_id'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReply':
xcb_io.c:(.text+0xf37): undefined reference to `xcb_wait_for_reply64'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x11fe): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13aa): undefined reference to 'aacEncOpen'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13c8): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13de): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13f4): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x140a): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x1420): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o:sound.c:(.text+0x1433): more undefined references to 'aacEncoder_SetParam' follow
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x145e): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x14a5): undefined reference to 'aacEncInfo'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `OutOfMemory':
OpenDis.c:(.text+0x316): undefined reference to `xcb_disconnect'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `XOpenDisplay':
OpenDis.c:(.text+0x784): undefined reference to `xcb_get_setup'
/usr/bin/x86_64-alpine-linux-musl-ld: OpenDis.c:(.text+0xc1b): undefined reference to `xcb_get_maximum_request_length'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_disp.o): in function `_XConnectXCB':
xcb_disp.c:(.text+0x153): undefined reference to `xcb_parse_display'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x19b): undefined reference to `xcb_connect_to_display_with_auth_info'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1a7): undefined reference to `xcb_connect'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1c7): undefined reference to `xcb_get_file_descriptor'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1e3): undefined reference to `xcb_generate_id'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x25c): undefined reference to `xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(ClDisplay.o): in function `XCloseDisplay':
ClDisplay.c:(.text+0xbb): undefined reference to 'xcb_disconnect'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:509: xrdp-chansrv] Error 1
make[3]: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
make[2]: *** [Makefile:716: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman'
make[1]: *** [Makefile:483: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02'
make: *** [Makefile:415: all] Error 2

# libx11-static
/mnt2/xrdp-repo-v0.9.23-02 # apk list |grep static |grep x11
libx11-static-1.7.3.1-r1 x86_64 {libx11} (custom:XFREE86) [installed]

# https://pkgs.alpinelinux.org/packages?name=*xcb*&branch=edge&repo=&arch=x86_64&maintainer=
#   libxcb-static #已装
#   oth_已装; xcb-util-dev xcb-util已装; xcb-util-xx看着不相关;
/mnt2/xrdp-repo-v0.9.23-02 # apk add libxcb-static
/mnt2/xrdp-repo-v0.9.23-02 # make -C sesman/chansrv/
ClDisplay.c:(.text+0xbb): undefined reference to `xcb_disconnect'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [Makefile:509: xrdp-chansrv] Error 1
make: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'

```

- **sesman/chansrv/Makefile** [-lX11-xcb -lxcb]

```bash
# sesman/chansrv/Makefile.am ##foot
xrdp_chansrv_LDADD = \
  $(top_builddir)/common/libcommon.la \
  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LIBS) \
  $(CHANSRV_EXTRA_LIBS)

# Makefile @421行
/mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LIBS) \



# view-xcb*.a
/mnt2/xrdp-repo-v0.9.23-02 # find /usr/lib |grep  xcb |egrep ".a$" |sort
/usr/lib/libX11-xcb.a
/usr/lib/libxcb-composite.a
/usr/lib/libxcb-damage.a
/usr/lib/libxcb-dpms.a
/usr/lib/libxcb-dri2.a
/usr/lib/libxcb-dri3.a
/usr/lib/libxcb-glx.a
/usr/lib/libxcb-present.a
/usr/lib/libxcb-randr.a
/usr/lib/libxcb-record.a
/usr/lib/libxcb-render.a
/usr/lib/libxcb-res.a
/usr/lib/libxcb-screensaver.a
/usr/lib/libxcb-shape.a
/usr/lib/libxcb-shm.a
/usr/lib/libxcb-sync.a
/usr/lib/libxcb-xf86dri.a
/usr/lib/libxcb-xfixes.a
/usr/lib/libxcb-xinerama.a
/usr/lib/libxcb-xinput.a
/usr/lib/libxcb-xkb.a
/usr/lib/libxcb-xtest.a
/usr/lib/libxcb-xv.a
/usr/lib/libxcb-xvmc.a
/usr/lib/libxcb.a

# 添加： -lX11-xcb -lxcb
/mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
/mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb $(X_EXTRA_LIBS) \

# 错误少了:
/mnt2/xrdp-repo-v0.9.23-02 # make -C sesman/chansrv/
make: Entering directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
  CCLD     xrdp-chansrv
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x11fe): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13aa): undefined reference to 'aacEncOpen'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13c8): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13de): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13f4): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x140a): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x1420): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o:sound.c:(.text+0x1433): more undefined references to 'aacEncoder_SetParam' follow
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x145e): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x14a5): undefined reference to 'aacEncInfo'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libxcb.a(xcb_auth.o): in function `get_authptr':
xcb_auth.c:(.text+0x157): undefined reference to `XauGetBestAuthByAddr'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libxcb.a(xcb_auth.o): in function '_xcb_get_auth_info':
xcb_auth.c:(.text+0x5eb): undefined reference to `XdmcpWrap'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_auth.c:(.text+0x608): undefined reference to `XauDisposeAuth'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_auth.c:(.text+0x62d): undefined reference to `XauDisposeAuth'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [Makefile:509: xrdp-chansrv] Error 1
make: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
```

- [-lXdmcp -lXau]

```bash
# ref src/yad/build.sh
apk add \
    libxdmcp-dev \
    libxau-dev  #已装;

# 添加：-lXdmcp -lXau ; >> 只余下sound错误;
/mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
/mnt2/xrdp-repo-v0.9.23-02 # make -C sesman/chansrv/
make: Entering directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
  CCLD     xrdp-chansrv
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x11fe): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13aa): undefined reference to 'aacEncOpen'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13c8): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13de): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x13f4): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x140a): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x1420): undefined reference to 'aacEncoder_SetParam'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o:sound.c:(.text+0x1433): more undefined references to 'aacEncoder_SetParam' follow
/usr/bin/x86_64-alpine-linux-musl-ld: sound.o: in function `sound_send_wave_data_chunk':
sound.c:(.text+0x145e): undefined reference to 'aacEncEncode'
/usr/bin/x86_64-alpine-linux-musl-ld: sound.c:(.text+0x14a5): undefined reference to 'aacEncInfo'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [Makefile:509: xrdp-chansrv] Error 1
make: Leaving directory '/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv'
```


- fdkaac

```bash
# aacEncoder_SetParam
# https://pkgs.alpinelinux.org/packages?name=*aac*&branch=edge&repo=&arch=x86_64&maintainer=
/mnt2/xrdp-repo-v0.9.23-02 # apk list |grep aacenc
vo-aacenc-dev-0.1.3-r0 x86_64 {vo-aacenc} (Apache-2.0)
vo-aacenc-0.1.3-r0 x86_64 {vo-aacenc} (Apache-2.0)
vo-aacenc-static-0.1.3-r0 x86_64 {vo-aacenc} (Apache-2.0)



./configure \
  --prefix=/usr/local/xrdp \
  --enable-vsock \
  --disable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --enable-static \
  --disable-shared \
  --enable-strict-locations \
  --disable-pam 
make;

/mnt2/xrdp-repo-v0.9.23-02 # apk add fdkaac
(1/1) Installing fdkaac (1.0.2-r0)
Executing busybox-1.34.1-r7.trigger
OK: 844 MiB in 275 packages
# make; 一样错;


##### [-lX11-xcb -lxcb -lXdmcp -lXau]
/mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  $(X_EXTRA_LIBS) \

/mnt2/xrdp-repo-v0.9.23-02 # find sesman/chansrv/ |grep sound
sesman/chansrv/.deps/sound.Po
sesman/chansrv/sound.h
sesman/chansrv/sound.c
sesman/chansrv/sound.o
```

- **fdk-aac**> chansrv static build ok;

```bash
/mnt2/xrdp-repo-v0.9.23-02 # apk list |grep fdk-aa
fdk-aac-2.0.2-r0 x86_64 {fdk-aac} (custom) [installed]
fdk-aac-doc-2.0.2-r0 x86_64 {fdk-aac} (custom)
fdk-aac-dev-2.0.2-r0 x86_64 {fdk-aac} (custom) [installed]

# https://github.com/chromebrew/chromebrew/blob/e83157f836f73ae6942945ea735854f0bd835fbc/packages/libfdk_aac.rb#L9
# https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-2.0.2.tar.gz

# v013 @2013
# https://github.com/felixonmars/aur3-mirror/blob/7ccd4e91fc0c4dcc0ad0faa7f411fbba36d19be4/libfdk-aac/PKGBUILD#L15


# ins fdk-aac:
 808 cd ..
 809 mkdir _handDown
 810 cd _handDown/
 814 curl -k -fSL -O https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-2.0.2.tar.gz
 816 tar -zxf fdk-aac-2.0.2.tar.gz 
 817 cd fdk-aac-2.0.2/
 819 ./configure --enable-static
 820 echo $?
 821 make
 822 echo $?
 823 make install
#  
 824 cd /mnt2/xrdp-repo-v0.9.23-02/
 825 ls
 826 cd sesman/chansrv/
 827 vi Makefile
 828 make
 829 ls -lh
 830 ls -lh xrdp-chansrv

# last Makefile edited
root@VM-12-9-ubuntu:/mnt/xrdp-repo-v0.9.23-02# cat sesman/chansrv/Makefile |grep lX11 -n
421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac  $(X_EXTRA_LIBS) \

/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # ls -lh xrdp-chansrv 
-rwxr-xr-x    1 root     root        4.6M Oct 31 10:54 xrdp-chansrv

# validate01:
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # xx-verify --static ./xrdp-chansrv 
/mnt2/xrdp-repo-v0.9.23-02/sesman/chansrv # echo $?
0
# validate02:
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./xrdp-chansrv  -h
DISPLAY is not set
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./xrdp-chansrv  --help
DISPLAY is not set
```

## sesman/tools/xrdp-xcon staticBuild

```bash
/mnt2/docker-x11base/compile/src/xrdp # ls /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-* -lh
-rwxr-xr-x    1 root     root        7.3K Oct 30 15:49 /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-dis
-rwxr-xr-x    1 root     root        2.4M Oct 31 07:07 /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-sesadmin
-rwxr-xr-x    1 root     root        2.4M Oct 31 07:07 /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-sesrun
-rwxr-xr-x    1 root     root        2.4M Oct 31 07:07 /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-sestest
-rwxr-xr-x    1 root     root       17.9K Oct 30 15:49 /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-xcon
/mnt2/docker-x11base/compile/src/xrdp # xx-verify --static /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-xcon
file /mnt2/xrdp-repo-v0.9.23-02/sesman/tools/xrdp-xcon is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped


/mnt2/xrdp-repo-v0.9.23-02 # cat sesman/tools/Makefile.am  |grep lX11 -n
60:  $(X_PRE_LIBS) -lX11 $(X_EXTRA_LIBS)
/mnt2/xrdp-repo-v0.9.23-02/sesman/tools # cat Makefile |grep lX11 -n
411:  $(X_PRE_LIBS) -lX11 $(X_EXTRA_LIBS)
# -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac
/mnt2/xrdp-repo-v0.9.23-02 # cat sesman/tools/Makefile |grep lX11 -n
411:  $(X_PRE_LIBS) -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac $(X_EXTRA_LIBS)


/mnt2/xrdp-repo-v0.9.23-02 # ls -lh sesman/tools/xrdp-*
-rwxr-xr-x    1 root     root      121.9K Nov  4 03:19 sesman/tools/xrdp-dis
-rwxr-xr-x    1 root     root        2.4M Nov  4 03:19 sesman/tools/xrdp-sesadmin
-rwxr-xr-x    1 root     root        2.4M Nov  4 03:19 sesman/tools/xrdp-sesrun
-rwxr-xr-x    1 root     root        2.4M Nov  4 03:19 sesman/tools/xrdp-sestest
-rwxr-xr-x    1 root     root      992.2K Nov  4 03:19 sesman/tools/xrdp-xcon
/mnt2/xrdp-repo-v0.9.23-02 # xx-verify --static ./sesman/tools/xrdp-xcon 
```


## genkeymap/Makefile.am 

```bash
# genkeymap/Makefile.am 
f=genkeymap/Makefile.am 
sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
cat $f |grep lX11 -n

# src/xrdp/build.sh>> make install:
/mnt2/docker-x11base/compile/src/xrdp # du -sh  /usr/local/static/xrdp/bin/*
124.0K  /usr/local/static/xrdp/bin/xrdp-dis
1000.0K /usr/local/static/xrdp/bin/xrdp-genkeymap
2.4M    /usr/local/static/xrdp/bin/xrdp-keygen
136.0K  /usr/local/static/xrdp/bin/xrdp-sesadmin
136.0K  /usr/local/static/xrdp/bin/xrdp-sesrun
/mnt2/docker-x11base/compile/src/xrdp # du -sh  /usr/local/static/xrdp/sbin/*
3.2M    /usr/local/static/xrdp/sbin/xrdp
4.6M    /usr/local/static/xrdp/sbin/xrdp-chansrv
2.5M    /usr/local/static/xrdp/sbin/xrdp-sesman
/mnt2/docker-x11base/compile/src/xrdp # 
```

