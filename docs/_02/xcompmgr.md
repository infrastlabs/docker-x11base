

## **xcompmgr**

- try01

```bash
  44 git clone https://ghps.cc/https://github.com/invisikey/xcompmgr
  45 cd xcompmgr/
  46 ls
  47 cat autogen.sh 
  48 bash autogen.sh 
checking if gcc supports -Werror... yes
checking if gcc supports -Werror=attributes... yes
checking whether make supports nested variables... (cached) yes
checking for XCOMPMGR... no
configure: error: Package requirements (xcomposite xfixes xdamage xrender xext) were not met:
Package 'xcomposite', required by 'virtual:world', not found
Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables XCOMPMGR_CFLAGS
and XCOMPMGR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
/mnt2/xcompmgr # ls


# deps
/mnt2/xcompmgr # apk add xcomposite xfixes xdamage xrender xext
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
ERROR: unable to select packages:
  xcomposite (no such package):
    required by: world[xcomposite]
  xdamage (no such package):
    required by: world[xdamage]
  xext (no such package):
    required by: world[xext]
  xfixes (no such package):
    required by: world[xfixes]
  xrender (no such package):
    required by: world[xrender]



# 
autoreconf -fi
/mnt2/xcompmgr # ./configure
checking whether make supports nested variables... (cached) yes
checking for XCOMPMGR... no
configure: error: Package requirements (xcomposite xfixes xdamage xrender xext) were not met:

Package 'xcomposite', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables XCOMPMGR_CFLAGS
and XCOMPMGR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

# deps02
/mnt2/xcompmgr # apk add libxcomposite-dev
/mnt2/xcompmgr # ./configure
checking that generated files are newer than configure... done
configure: creating ./config.status
config.status: creating Makefile
config.status: creating man/Makefile
config.status: creating config.h
config.status: executing depfiles commands

# make
/mnt2/xcompmgr # ls -lh
total 2M     
-rwxr-xr-x    1 root     root      136.2K Nov  8 01:11 xcompmgr
-rw-r--r--    1 root     root       55.9K Nov  8 00:55 xcompmgr.c
-rw-r--r--    1 root     root      193.2K Nov  8 01:11 xcompmgr.o
/mnt2/xcompmgr # ./xcompmgr -h
./xcompmgr: unrecognized option: h
./xcompmgr v1.1.6



# static
# libxdamage libxcomposite ##都无static库;
```


- try02: 

```bash
# bash-5.1# ./autogen.sh
checking whether make supports nested variables... (cached) yes
checking for XCOMPMGR... no
configure: error: Package requirements (xcomposite xfixes xdamage xrender xext) were not met:

Package 'xcomposite', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables XCOMPMGR_CFLAGS
and XCOMPMGR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
bash-5.1# 



# bash-5.1# apk add libxcomposite-dev
(1/2) Installing libxcomposite (0.4.5-r0)
(2/2) Installing libxcomposite-dev (0.4.5-r0)
OK: 749 MiB in 263 packages
bash-5.1# apk add libxcomposite-dev libxfixes-dev libxdamage-dev libxrender-dev libxext-dev
OK: 749 MiB in 263 packages


# bash-5.1# make
make[2]: Entering directory '/mnt2/xcompmgr'
  CCLD     xcompmgr
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lXdamage
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:452: xcompmgr] Error 1
make[2]: Leaving directory '/mnt2/xcompmgr'
make[1]: *** [Makefile:489: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xcompmgr'
make: *** [Makefile:355: all] Error 2
bash-5.1# 
# bash-5.1# env |grep LDFLAGS
LDFLAGS=-static -Wl,--strip-all -Wl,--as-needed

# make LDFLAGS="-lXdamage"
bash-5.1# make LDFLAGS="-lXdamage"
make[1]: Leaving directory '/mnt2/xcompmgr'
bash-5.1# ls -lh xcompmgr
-rwxr-xr-x    1 root     root       47.3K Nov 25 14:35 xcompmgr

# 非静态02
bash-5.1# ldd xcompmgr
        /lib/ld-musl-x86_64.so.1 (0x7fe0c1d7e000)
        libXdamage.so.1 => /usr/lib/libXdamage.so.1 (0x7fe0c1d6e000)
        libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7fe0c1d69000)
        libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7fe0c1d61000)
        libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7fe0c1d55000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7fe0c1c32000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7fe0c1c1f000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fe0c1d7e000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7fe0c1bf8000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7fe0c1bf3000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7fe0c1beb000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7fe0c1bd8000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7fe0c1bcc000)

```

- try static


```bash
# Xdamage无静态库
  366  make LDFLAGS="-static -lXdamage -lXcomposite -lXfixes -lXrender -lX11 -lXext -lxcb -lXau -lXdmcp -lbsd -lmd"
  367  find /usr/lib |grep Xdamage
  368  apk add libxdamage-dev
  369  find /usr/lib |grep Xdamage


  380  git clone https://hub.nuaa.cf/cubanismo/libXdamage
  381  cd libXdamage/
  382  ls
  383  ./autogen.sh 
  384  echo $?
  385  ./configure 
  386  ls
  387  make
  388  make install
  389  find /usr/lib |grep Xdamage
  390  find |grep damage
  391  ls -lh ./src/.libs/libXdamage.a
  392  cp ./src/.libs/libXdamage.a /usr/lib
  393  pwd
  394  cd ../xcompmgr/

# Xdamage过了，xcb错误
make LDFLAGS="-static -lXdamage -lXcomposite -lXfixes -lXrender -lX11 -lXext -lxcb -lXau -lXdmcp -lbsd -lmd"

# +oblibs
# -lfontconfig 
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 

# ref: opbox
xx-apk --no-cache --no-scripts add \
    g++ \
    glib-dev \
    glib-static \
    fribidi-dev \
    fribidi-static \
    harfbuzz-dev \
    harfbuzz-static \
    cairo-dev \
    cairo-static \
    libxft-dev \
    libxml2-dev \
    libx11-dev \
    libx11-static \
    libxcb-static \
    libxdmcp-dev \
    libxau-dev \
    freetype-static \
    expat-static \
    libpng-dev \
    libpng-static \
    zlib-static \
    bzip2-static \
    pcre-dev \
    libxrender-dev \
    graphite2-static \
    libffi-dev \
    xz-dev \
    brotli-static
(1/6) Installing cairo-static (1.16.0-r5)
(2/6) Installing expat-static (2.5.0-r0)
(3/6) Installing fribidi-static (1.0.11-r0)
(4/6) Installing glib-static (2.70.5-r0)
(5/6) Installing graphite2-static (1.3.14-r0)
(6/6) Installing harfbuzz-static (3.0.0-r2)


# -lX11-xcb
# bash-5.1# make LDFLAGS="-static -lXdamage -lXcomposite -lXfixes -lXrender -lX11 -lX11-xcb -lXext -lxcb -lXau -lXdmcp -lbsd -lmd $OB_LIBS"
bash-5.1# 
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x25c): undefined reference to 'xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o): in function 'XCloseDisplay':
ClDisplay.c:(.text+0xbb): undefined reference to 'xcb_disconnect'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:452: xcompmgr] Error 1
make[2]: Leaving directory '/mnt2/xcompmgr'
make[1]: *** [Makefile:489: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/xcompmgr'
make: *** [Makefile:355: all] Error 2
bash-5.1# 

# +OB_LIBS: 错误依旧
# 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
bash-5.1# make LDFLAGS="-static -lXdamage $OB_LIBS" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):


```

- 03 XCOMPMGR_LIBS OK

```bash
# 0a: 手动替换;
# vi Makefile #@line 297
# -lxcb -lXau -lXdmcp -lbsd -lmd -lX11 -lxcb -lXdmcp -lXau -lXext -lXft  -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz  -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
XCOMPMGR_LIBS = -lXcomposite -L/usr/local/lib -lXdamage -lXfixes -lXrender -lX11 -lXext ###+libs


# make OK
bash-5.1# make
make  all-recursive
make[1]: Entering directory '/mnt2/xcompmgr'
Making all in man
make[2]: Entering directory '/mnt2/xcompmgr/man'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt2/xcompmgr/man'
make[2]: Entering directory '/mnt2/xcompmgr'
  CCLD     xcompmgr
make[2]: Leaving directory '/mnt2/xcompmgr'
make[1]: Leaving directory '/mnt2/xcompmgr'
# bash-5.1# ls -lh xcompmgr
-rwxr-xr-x    1 root     root        1.0M Nov 27 12:09 xcompmgr
# bash-5.1# ldd xcompmgr
/lib/ld-musl-x86_64.so.1: xcompmgr: Not a valid dynamic program




# 0b: XCOMPMGR_LIBS=xx ./configure
# XCOMPMGR_LIBS="-lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure
bash-5.1# 
bash-5.1# cat Makefile.am  |grep XCOMPMGR_LIBS
xcompmgr_LDADD = $(XCOMPMGR_LIBS) -lm
bash-5.1# cat Makefile |grep MGR_LIBS -n
297:XCOMPMGR_LIBS = -lX11-xcb -lXext -lxcb -lXau -lXdmcp
352:xcompmgr_LDADD = $(XCOMPMGR_LIBS) -lm

# ./configure
XCOMPMGR_LIBS="-lXcomposite -L/usr/local/lib -lXdamage -lXfixes -lXrender -lX11 -lXext"
XCOMPMGR_LIBS="$XCOMPMGR_LIBS -lX11-xcb -lXext -lxcb -lXau -lXdmcp" ./configure

# make
5 warnings generated.
  CCLD     xcompmgr
make[2]: Leaving directory '/mnt2/xcompmgr'
make[1]: Leaving directory '/mnt2/xcompmgr'
bash-5.1# ldd xcompmgr
/lib/ld-musl-x86_64.so.1: xcompmgr: Not a valid dynamic program
bash-5.1# ls -lh xcompmgr
-rwxr-xr-x    1 root     root        1.0M Nov 27 12:28 xcompmgr
```


