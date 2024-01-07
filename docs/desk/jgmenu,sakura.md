
- ~~tint2~~ `imlib2`
- jgmenu `dyn:ok`
- rofi `xcb-ewmh/icccm/cursor`
- sakura `SAKURA_2_3_7:vte`


```bash
   #14  cd jgmenu/
   15  ls
   16  ./configure 
   17  apk add librsvg
   18  apk add librsvg-dev
   19  ./configure 
   20  make
   21  ls
   22  ls -lh jgmenu
   23  ldd jgmenu

# rofi #autoreconf -v --install
bash-5.1# history |tail -50
   91  cd rofi/
   93  autoreconf -v --install
  100  cp .gitmodules  .gitmodules-bk1
  101  sed -i "s^github.com^hub.njuu.cf^g" .gitmodules
  102  cat .gitmodules
  104  git submodule update
  106  ls subprojects/libgwater/
  107  ls subprojects/libnkutils/
  109  autoreconf -v --install
  111  ./configure
  112  apk add bison-dev
  113  apk add bison
  115  apk add flex
  116  apk add flex-dev
  117  ./configure
  118  apk add xkbcommon ##no pkg
  122  apk add libxkbcommon
  123  apk add libxkbcommon-dev
Package 'xcb-ewmh', required by 'virtual:world', not found
Package 'xcb-icccm', required by 'virtual:world', not found
Package 'xcb-cursor', required by 'virtual:world', not found

# tint2 https://github.com/o9000/tint2/tree/v16.1
# --   Package 'imlib2', required by 'virtual:world', not found
bash-5.1# history |tail -10
  135  cd tint2/
  137  git checkout 16.1
  139  mkdir build
  140  cd build
  141  cmake ..
# make -j4

# sakura https://github.com/dabisu/sakura/tree/SAKURA_2_3_7
master 940 # --   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_3_5_0 758 @2017.7.14 # -- Checking for module 'gtk+-3.0>=3.12' ERR
SAKURA_3_2_1 630 @2015.7.24 #'glib-2.0>=2.20'ok; #--   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_3_0_2 476 @2012.3.7 #--   Package 'gtk+-3.0', required by 'virtual:world', not found
SAKURA_2_3_7 315 @2010.3.4 #'gtk+-2.0>=2.10'ok; --   Package 'vte', required by 'virtual:world', not found
```

## jgmenu, sakura


- **jgmenu**

```bash
 988 git clone https://ghproxy.com/https://github.com/jgmenu/jgmenu
 989 cd jgmenu/
 990 ls
 991 ./configure 
 992 make
 993 echo $?
 994 ls
 995 ./jgmenu -h



# export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
./configure --enable-static --prefix=/usr/local/static/jgmenu
make



# static
/mnt2/jgmenu # history |tail -8
 997 ./configure --enable-static --prefix=/usr/local/static/jgmenu
 998 export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"
 999 make
1000 echo $?
1001 ls
1002 rm -f *.o
1003 make
# 
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngwutil.o): in function `png_text_compress.constprop.0':
pngwutil.c:(.text+0x527): undefined reference to 'deflate'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngwutil.o): in function `png_compress_IDAT':
pngwutil.c:(.text+0x210d): undefined reference to 'deflate'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make: *** [Makefile:73: jgmenu] Error 1



/mnt2/jgmenu # make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrandr.a(Xrandr.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrandr.a(XrrCrtc.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrandr.a(XrrCrtc.o):XrrCrtc.c:(.text+0x82e):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-ft-font.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2015:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2700:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-mask-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-matrix.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-region.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-display.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-render-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-screen.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface-shm.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-visual.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgobject-2.0.a(gclosure.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libharfbuzz.a(hb-graphite2.cc.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.a(fonts.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.a(pango-bidi-type.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.a(pango-fontmap.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpangocairo-1.0.a(pangocairo-fcfont.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpangocairo-1.0.a(pangocairo-fcfontmap.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(png.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngread.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngrutil.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngwrite.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.a(pngwutil.o):
```



### jgmenu

```bash
  118  cd jgmenu/
  119  ls #直接./conf
  121  ./configure #--enable-static --disable-shared ##无配置项
  122  make ##static deps err;
  126  make clean
  127  make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr -lXcursor -lXi $LIBS0" 2>&1

make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr -lXcursor -lXi $LIBS0" 2>&1

# ref tint2
deps="Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2 Xcursor Xi"

# -lImlib2
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr -lXcursor -lXi -lImlib2 $LIBS0" 2>&1
# 错误依旧，LIBS设定无效;
```

### Sakura

- **sakura**
  - gtk+3.0-dev https://github.com/GNOME/gtk #`c, per862, commits78095` 3.0.12@`commits-26752@2011.7.28`
  - vte3-dev https://github.com/GNOME/vte #`cxx, per211, commits5329`
  - pcre2-dev https://github.com/PCRE2Project/pcre2 #`c, per33, commits1628`


```bash
$ cmake .
$ make
$ sudo make install

/mnt2/sakura # history |tail -8
 931 apk add gtk+3.0-dev
 934 apk add vte3-dev
 935 cmake .

/mnt2/sakura # cmake .
-- Checking for module 'vte-2.91>=0.50'
--   Found vte-2.91, version 0.66.1
-- Checking for module 'x11'
--   Found x11, version 1.7.3.1
pod2man executable is/usr/bin/pod2man
-- Configuring done
-- Generating done
-- Build files have been written to: /mnt2/sakura


# deps
 931 apk add gtk+3.0-dev #无static
 934 apk add vte3-dev    #无static
 940 apk add pcre2-dev   #无static
```

- deps detail

```bash
# https://github.com/GNOME/gtk
  # Building and installing
  # In order to build GTK you will need:
    a C99 compatible compiler
    Python 3
    Meson
    Ninja
  # You will also need various dependencies, based on the platform you are building for:
    GLib
    GdkPixbuf
    GObject-Introspection
    Cairo
    Pango
    Epoxy
    Graphene
    Xkb-common


# https://github.com/GNOME/vte
$ git clone https://gitlab.gnome.org/GNOME/vte  # Get the source code of VTE
$ cd vte                                        # Change to the toplevel directory
$ meson _build                                  # Run the configure script
$ ninja -C _build                               # Build VTE
[ Optional ]
$ ninja -C _build install                       # Install VTE to default `/usr/local`


# https://github.com/PCRE2Project/pcre2


```

- make (-static)

```bash
### LDFLAGS=--static -static
/mnt2/sakura # env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=--static -static -Wl,--strip-all -Wl,--as-needed
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer


# apk add pcre2-dev
/mnt2/sakura # make   ##make 2>&1|sort -u
[  0%] Built target man
[ 50%] Building C object CMakeFiles/sakura.dir/src/sakura.c.o
[100%] Linking C executable src/sakura
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -latk-1.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgdk-3
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgdk_pixbuf-2.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgtk-3
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lvte-2.91
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/sakura.dir/build.make:97: src/sakura] Error 1
make[1]: *** [CMakeFiles/Makefile2:155: CMakeFiles/sakura.dir/all] Error 2
make: *** [Makefile:136: all] Error 2

/mnt2/sakura # find /usr/lib |egrep "libgtk|libvte|libgdk|libatk" |sort
/usr/lib/gtk-2.0/modules/libatk-bridge.so
/usr/lib/libatk-1.0.so
/usr/lib/libatk-1.0.so.0
/usr/lib/libatk-1.0.so.0.23609.1
/usr/lib/libatk-bridge-2.0.so
/usr/lib/libatk-bridge-2.0.so.0
/usr/lib/libatk-bridge-2.0.so.0.0.0
/usr/lib/libgdk-3.so
/usr/lib/libgdk-3.so.0
/usr/lib/libgdk-3.so.0.2404.26
/usr/lib/libgdk_pixbuf-2.0.so
/usr/lib/libgdk_pixbuf-2.0.so.0
/usr/lib/libgdk_pixbuf-2.0.so.0.4200.8
/usr/lib/libgtk-3.so
/usr/lib/libgtk-3.so.0
/usr/lib/libgtk-3.so.0.2404.26
/usr/lib/libvte-2.91.so
/usr/lib/libvte-2.91.so.0
/usr/lib/libvte-2.91.so.0.6600.1
```

- 改动态编译 OK

```bash
# export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

# 清理后，动态编译生效，一把OK
 969 git remote -v
 972 rm -rf *
 975 git branch
 976 git reset --hard origin/master
 
# MAKE
 979 cmake .
 980 make 
 982 find |grep sakura
 983 ./src/sakura -h


# VIEW
/mnt2/sakura # ls -lh src/sakura
-rwxr-xr-x    1 root     root       87.1K Oct 31 15:17 src/sakura
/mnt2/sakura # ./src/sakura -h
Unable to init server: Could not connect: Connection refused
Cannot open display: 
```
