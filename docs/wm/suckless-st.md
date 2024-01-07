
- st simpleterminal

```bash
# ref g-dev1/fk-alpine-xfce4-xrdp/src/branch/sam-custom/gw/Dockerfile
    1  cd /mnt2/
    2  git clone https://ghproxy.com/https://github.com/LukeSmithxyz/st
    3  cd st/
    7  apt update
   10  apt install libharfbuzz-dev
   13  apt install libfontconfig-dev
   15  apt install libxft-dev
   16  make
   17  echo $?
   18  make install

# 动库：deb12编译后，ubt2004不可用>> deb12-glibc库比ubt2004新;
```

- flags

```bash
# try st-static
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

# root@b4efefabe635:/mnt2/st# rm -f st
# root@b4efefabe635:/mnt2/st# make
# st build options:
# CFLAGS  = -I/usr/X11R6/include  -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include  -DVERSION="0.8.5" -D_XOPEN_SOURCE=600 -Os -fomit-frame-pointer -Os -fomit-frame-pointer
# LDFLAGS = -L/usr/X11R6/lib -lm -lrt -lX11 -lutil -lXft -lXrender -lfontconfig -lfreetype   -lfreetype   -lharfbuzz  -Wl,--as-needed --static -static -Wl,--strip-all
# CC      = c99
c99 -o st st.o x.o boxdraw.o hb.o -L/usr/X11R6/lib -lm -lrt -lX11 -lutil -lXft -lXrender `pkg-config --libs fontconfig`  `pkg-config --libs freetype2`  `pkg-config --libs harfbuzz` -Wl,--as-needed --static -static -Wl,--strip-all
# /usr/bin/ld: cannot find -lharfbuzz: No such file or directory
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(CrGlCur.o): in function `_XNoticeCreateBitmap':
(.text+0x119): warning: Using 'dlopen' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/usr/bin/ld: st.o: in function `ttynew':
st.c:(.text+0x1fe7): warning: Using 'getpwuid' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xim_trans.o): in function `_XimXTransSocketINETConnect':
(.text+0xc92): warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
# collect2: error: ld returned 1 exit status
# make: *** [Makefile:29: st] Error 1
root@b4efefabe635:/mnt2/st# cat Makefile |grep lX11


# clang
cd /tmp/libxfont2 && ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=/usr
```

- config.mk

```bash
docker run -it --rm --platform=linux/amd64 -v /mnt:/mnt2  infrastlabs/x11-base:deb12-builder bash

root@da1249e51fa2:/# cd /mnt2/st/
cp config.mk  config.mk-bk1
vi config.mk #+ -static
root@8bfa59fadbfe:/mnt2/st# cat config.mk
# includes and libs
INCS = -I$(X11INC) \
       `$(PKG_CONFIG) --cflags fontconfig` \
       `$(PKG_CONFIG) --cflags freetype2` \
       `$(PKG_CONFIG) --cflags harfbuzz`
LIBS = -L$(X11LIB) -static -lm -lrt -lX11 -lutil -lXft -lXrender\
       `$(PKG_CONFIG) --libs fontconfig` \
       `$(PKG_CONFIG) --libs freetype2` \
       `$(PKG_CONFIG) --libs harfbuzz`

# /usr/bin/ld: cannot find -lharfbuzz: No such file or directory

# https://blog.csdn.net/wh617053508/article/details/133396789
cd /usr/lib/x86_64-linux-gnu/
ar -crv libharfbuzz.a libharfbuzz.so

root@8bfa59fadbfe:/mnt2/st# make 2>&1 |grep gnu |sort
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(ClDisplay.o): in function `XCloseDisplay':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(CrGlCur.o): in function `_XNoticeCreateBitmap':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(OpenDis.o): in function `OutOfMemory':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(OpenDis.o): in function `XOpenDisplay':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_disp.o): in function `_XConnectXCB':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XAllocIDs':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XEventsQueued':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XFlush':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XNextRequest':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XReadEvents':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XReply':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `_XSend':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `poll_for_event':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xcb_io.o): in function `poll_for_response':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libX11.a(xim_trans.o): in function `_XimXTransSocketINETConnect':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcolor.o): in function `XftColorAllocName':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcolor.o): in function `XftColorAllocValue':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcolor.o): in function `XftColorFree':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcore.o): in function `XftGlyphCore':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcore.o): in function `XftGlyphFontSpecCore':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftcore.o): in function `XftGlyphSpecCore':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdpy.o): in function `_XftDefaultGet':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdpy.o): in function `_XftDefaultInitInteger':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdpy.o):(.text+0x62f): more undefined references to 'XGetDefault' follow
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdraw.o): in function `XftDrawBitsPerPixel':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdraw.o): in function `XftDrawDestroy':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdraw.o): in function `XftDrawSetClip':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdraw.o): in function `XftDrawSetClipRectangles':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftdraw.o): in function `_XftDrawCorePrepare':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libXft.a(xftglyphs.o): in function `XftFontLoadGlyphs':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfontconfig.a(fcxml.o): in function `FcConfigMessage':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfontconfig.a(fcxml.o): in function `FcConfigParseAndLoadFromMemoryInternal':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(ftgzip.o): in function `FT_Gzip_Uncompress':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(ftgzip.o): in function `FT_Stream_OpenGzip':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(ftgzip.o): in function `ft_gzip_file_fill_output':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(ftgzip.o): in function `ft_gzip_file_io':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(ftgzip.o): in function `ft_gzip_stream_close':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(sfnt.o): in function `Load_SBit_Png':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(sfnt.o): in function `error_callback':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(sfnt.o): in function `read_data_from_FT_Stream':
/usr/bin/ld: /usr/lib/gcc/x86_64-linux-gnu/12/../../../x86_64-linux-gnu/libfreetype.a(sfnt.o): in function `sfnt_init_face':
CFLAGS  = -I/usr/X11R6/include  -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include  -DVERSION="0.8.5" -D_XOPEN_SOURCE=600  -O1

# libX11 libXft libfontconfig libfreetype

root@fa7f3f203a3b:/# dpkg -l |egrep "x11|xft|freetype|fontconf" |grep "\-dev"
ii  libx11-dev:amd64                2:1.8.4-2+deb12u2              amd64        X11 client-side library (development headers)
ii  libxft-dev:amd64                2.3.6-1                        amd64        FreeType-based font drawing library for X (development files)
ii  libfontconfig-dev:amd64         2.14.1-4                       amd64        generic font configuration library - development
ii  libfreetype-dev:amd64           2.12.1+dfsg-5                  amd64        FreeType 2 font engine, development files

```

- deps

```bash
    5  dpkg -l |egrep "x11|xft|freetype|fontconf" |grep "\-dev"
    6  tarxf
    7  cd /mnt2/
    8  ll
    9  ls
   10  git clone https://gitee.com/infrastlabs/fk-docker-baseimage-gui
   11  cd fk-docker-baseimage-gui/
   12  ls
   13  bash st.sh 
   14  ll
   15  ll ../deps1/
   16  ls ../deps1/
   17  git pull; bash st.sh 
   18  ls ../deps1/
   19  cd ../deps1/libX11-1.8.4
   20  ls
   21  ./configure --prefix=/ --disable-shared --disable-loadable-xcursor
   22  make
   23  make install
   24  ls -l /usr/lib/x86_64-linux-gnu/ |grep libX11
   25  find libX11.a
   26  find -name libX11.a
   27  cp /usr/lib/x86_64-linux-gnu/libX11.a /usr/lib/x86_64-linux-gnu/libX11.a-bk1
   28  cat ./src/.libs/libX11.a > /usr/lib/x86_64-linux-gnu/libX11.a
   29  cd ../../st/
   30  make
   31  cd /usr/lib/x86_64-linux-gnu/
   32  ar -crv libharfbuzz.a libharfbuzz.so
   33  cd -
   34  make
   35  make 2>&1 |grep gnu |sort

# libX11
./configure --prefix=/usr --enable-static --disable-shared --disable-loadable-xcursor
make DESTDIR=$R install

cat ./src/.libs/libX11.a > /usr/lib/x86_64-linux-gnu/libX11.
root@fa7f3f203a3b:/mnt2/deps1/libX11-1.8.4# ls src/.libs/ -lh
total 31M
-rw-r--r-- 1 root root 68K Oct 28 01:09 libX11-xcb.a
lrwxrwxrwx 1 root root  16 Oct 28 01:09 libX11-xcb.la -> ../libX11-xcb.la
-rw-r--r-- 1 root root 864 Oct 28 01:09 libX11-xcb.lai
-rw-r--r-- 1 root root 31M Oct 28 01:28 libX11.a
lrwxrwxrwx 1 root root  12 Oct 28 01:28 libX11.la -> ../libX11.la
-rw-r--r-- 1 root root 872 Oct 28 01:28 libX11.lai
root@fa7f3f203a3b:/mnt2/deps1/libX11-1.8.4# ls -lh /usr/lib/
X11/              cmake/            git-core/         libX11-xcb.a      lsb/              python3.11/       tmpfiles.d/
apt/              compat-ld/        gnupg/            libX11-xcb.la     mime/             sasl2/            udev/
bfd-plugins/      cpp               gnupg2/           libX11.a          openssh/          ssl/              valgrind/
binfmt-support/   dpkg/             gold-ld/          libX11.la         os-release        sysctl.d/         x86_64-linux-gnu/
binfmt.d/         file/             init/             llvm-14/          pkgconfig/        systemd/          
clang/            gcc/              ld-linux.so.2     locale/           python3/          terminfo/         
root@fa7f3f203a3b:/mnt2/deps1/libX11-1.8.4# ls -lh /usr/lib/x86_64-linux-gnu/libX11.a*
-rw-r--r-- 1 root root  31M Oct 28 01:12 /usr/lib/x86_64-linux-gnu/libX11.a
-rw-r--r-- 1 root root 2.1M Oct 28 01:12 /usr/lib/x86_64-linux-gnu/libX11.a-bk1
root@fa7f3f203a3b:/mnt2/deps1/libX11-1.8.4# cat ./src/.libs/libX11.a > /usr/lib/x86_64-linux-gnu/libX11.a
```

- gcc/g++>> clang/clang++
  - conig.mk/configure.ac
  - cmake/make; ./configure
  - make; make install


```bash
  109  export CC=clang
  114  export CXX=clang++
  110  make
  111  dpkg -l |grep clang
  112  dpkg -l |grep libxi
  113  dpkg -l |grep libx1
  115  make

# LIBDEPS="$LIBDEPS \
#  libX11.a \
#  libxcb.a \
#  libXau.a \
#  libXdmcp.a \
#  "
#https://github.com/x42/silan/blob/7bdd8c04579321b5353c6acea09b8a36b5c09c64/x-static.sh#L39
  116  cat config.mk
  117  cat config.mk |grep DEP
  118  LS
  119  ls
  120  find /usr/lib/x86_64-linux-gnu/|grep libxft
  121  find /usr/lib/x86_64-linux-gnu/|grep libXft
  122  ls
  123  cp config.mk config.mk-bk2
  124  vi config.mk #+/usr/lib/x86_64-linux-gnu/libX11.a /usr/lib/x86_64-linux-gnu/libXft.a
  135  cat config.mk
  136  make
  137  make 2>&1 |grep gnu |sort
  138  /usr/lib/x86_64-linux-gnu/libX11.a
  139  find /usr/lib/x86_64-linux-gnu/|grep libX11
  140  ls -l /usr/lib/x86_64-linux-gnu/libX11.a*
  145  make 2>&1 |grep gnu 

# libXft: 找不到函数错误>> 错误消失;
# libX11: 错误依旧/换libX11.a-bk1一样;
```

## refs

- https://github.com/x42/silan/blob/7bdd8c04579321b5353c6acea09b8a36b5c09c64/configure.ac #`LIBDEPS="$LIBDEPS \#  libX11.a \`
- full-deps https://github.com/5l1v3r1/coyim/blob/dbdd2309aef4f9367562f092c1407915107825e1/memory_analysis/Dockerfile#L16
- https://github.com/swap-dev/swap-gui/blob/5d7c23675d45b288320463c3dd20205cf21d0042/Dockerfile#L11 #`xcbproto, libxcb, libX11` @`monero-project/monero-gui`
- 
- libXft.deps https://github.com/CRKatri/Procursus/blob/6f6bf04832c5a68da7d8f070d24267f3ad1d282b/build_info/libxft-dev.control#L5 #`Depends: libxft2 (= @DEB_LIBXFT_V@), libfontconfig-dev, libfreetype-dev, libx11-dev, libxrender-dev`
- libX11.deps https://github.com/CRKatri/Procursus/blob/6f6bf04832c5a68da7d8f070d24267f3ad1d282b/build_info/libx11-dev.control #`Depends: libx11-6 (= @DEB_LIBX11_V@), libxcb1-dev, libxdmcp-dev, libxau-dev, x11proto-dev, xtrans-dev`
- 
- `export CC=clang` https://github.com/moparisthebest/static-curl/blob/master/build.sh
- https://github.com/erebe/greenclip/blob/b98bb1d3487cc192a5771579d21674ca9480a9b3/Dockerfile#L3 #`greenclip@haskel: alpine_v316> libx11-static`
- --enable-static与--disable-shared #https://qa.1r1g.com/sf/ask/3481347411/

```bash
# https://github.com/moparisthebest/static-curl/blob/master/build.sh
# gcc is apparantly incapable of building a static binary, even gcc -static helloworld.c ends up linked to libc, instead of solving, use clang
export CC=clang

# libX11_deps_func_err..:
# try1:
root@fa7f3f203a3b:/mnt2/st# apt install libxcb1-dev libxdmcp-dev libxau-dev x11proto-dev xtrans-dev #全已装.

```
