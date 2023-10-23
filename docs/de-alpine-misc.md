
- **dropbear**

```bash
./configure
make
make install
# build ok;
/mnt2/dropbear # ls -lh dropbear
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:26 dropbear


# static-build
./configure  --enable-static --prefix=/usr/local/static/dropbear
make

/mnt2/dropbear # echo $?
0
/mnt2/dropbear # ls -lh dropbear
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:27 dropbear


# /mnt2/dropbear # make install
# validate01
/mnt2/dropbear # xx-verify --static /usr/local/static/dropbear/sbin/dropbear 
/mnt2/dropbear # echo $?
0
/mnt2/dropbear # ls -lh /usr/local/static/dropbear/sbin/dropbear 
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:28 /usr/local/static/dropbear/sbin/dropbear


# validate02
root@VM-12-9-ubuntu:~# cd /mnt/xrdp-static-alpine/
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ls
bin  dropbear  etc  include  lib  sbin  share  xrdp-chansrv
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./dropbear -h
Dropbear server v2022.83 https://matt.ucc.asn.au/dropbear/dropbear.html
Usage: ./dropbear [options]
```

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


- **thunar**

```bash
# relear tar
% tar xf thunar-<version>.tar.bz2
% cd thunar-<version>
% ./configure  --enable-static
% make
% make install


# from src
% cd thunar
% ./autogen.sh
% make
% make install



# 
 839 git clone --depth=1 --branch thunar-4.16.11 https://ghproxy.com/https://github.com/xfce-mirror/thunar thunar-4.16.11
 840 ls
 841 cd thunar-4.16.11/
 842 ls
 843 ./configure 
 844 cat autogen.sh 
 845 bash autogen.sh 
 846 apk add xfce4-dev-tools
 847 bash autogen.sh 
 848 apk add intltool
 849 bash autogen.sh 
 850 apk add gtk-doc
 851 bash autogen.sh 
 852 echo $?
 853 apk add exo-2
 854 apk add exo2
 855 apk add exo
 856 bash autogen.sh


# ERR01: exo-2
# /mnt2/thunar-4.16.11 # bash autogen.sh 
checking pkg-config is at least version 0.9.0... yes
checking for exo-2 >= 4.15.3... not found
*** The required package exo-2 was not found on your system.
*** Please install exo-2 (atleast version 4.15.3) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.


# https://github.com/clefebvre/thunar
# Thunar depends on the following packages:
 - perl 5.6 or above
 - GTK+ 2.24.0 or above
 - GLib 2.30.0 or above
 - exo 0.10.0 or above
 - intltool 0.30 or above
```


```bash
# headless @ mac23-199 in ~ |20:34:54  
$ thunar -V
thunar: Failed to initialize Xfconf: Cannot autolaunch D-Bus without X11 $DISPLAY
thunar 1.8.14 (Xfce 4.14)
Copyright (c) 2004-2019
	The Thunar development team. All rights reserved.

# headless @ mac23-199 in ~ |20:33:55  
$ ldd /usr/bin/thunar |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007f0dd36a0000)
	libICE.so.6 => /lib/x86_64-linux-gnu/libICE.so.6 (0x00007f0dd3529000)
	libSM.so.6 => /lib/x86_64-linux-gnu/libSM.so.6 (0x00007f0dd3547000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007f0dd16d1000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007f0dd21fd000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007f0dd15e6000)
	libXcomposite.so.1 => /lib/x86_64-linux-gnu/libXcomposite.so.1 (0x00007f0dd1de6000)
	libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007f0dd1deb000)
	libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007f0dd1de1000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007f0dd15de000)
	libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007f0dd1d67000)
	libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007f0dd21c4000)
	libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007f0dd21ce000)
	libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007f0dd1e07000)
	libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007f0dd1dfa000)
	libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007f0dd1a33000)
	libatk-1.0.so.0 => /lib/x86_64-linux-gnu/libatk-1.0.so.0 (0x00007f0dd2c2e000)
	libatk-bridge-2.0.so.0 => /lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 (0x00007f0dd2181000)
	libatspi.so.0 => /lib/x86_64-linux-gnu/libatspi.so.0 (0x00007f0dd1649000)
	libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007f0dd157d000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007f0dd233a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0dd2504000)
	libcairo-gobject.so.2 => /lib/x86_64-linux-gnu/libcairo-gobject.so.2 (0x00007f0dd21b8000)
	libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007f0dd2b0b000)
	libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007f0dd15d4000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007f0dd1680000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f0dd1a04000)
	libepoxy.so.0 => /lib/x86_64-linux-gnu/libepoxy.so.0 (0x00007f0dd204e000)
	libexo-2.so.0 => /lib/x86_64-linux-gnu/libexo-2.so.0 (0x00007f0dd356a000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f0dd15ec000)
	libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007f0dd1951000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007f0dd1ecb000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007f0dd1e0c000)
	libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007f0dd2031000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007f0dd12d4000)
	libgdk-3.so.0 => /lib/x86_64-linux-gnu/libgdk-3.so.0 (0x00007f0dd2c58000)
	libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007f0dd2ae3000)
	libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007f0dd2881000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007f0dd26f8000)
	libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007f0dd24fe000)
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007f0dd2821000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007f0dd12af000)
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007f0dd161c000)
	libgtk-3.so.0 => /lib/x86_64-linux-gnu/libgtk-3.so.0 (0x00007f0dd2d5d000)
	libgudev-1.0.so.0 => /lib/x86_64-linux-gnu/libgudev-1.0.so.0 (0x00007f0dd355d000)
	libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007f0dd1f12000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007f0dd13f2000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f0dd1413000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f0dd23af000)
	libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007f0dd19a4000)
	libnotify.so.4 => /lib/x86_64-linux-gnu/libnotify.so.4 (0x00007f0dd3552000)
	libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007f0dd2a62000)
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007f0dd21e0000)
	libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007f0dd2018000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f0dd18de000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f0dd14eb000)
	libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007f0dd1cb5000)
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007f0dd1c7d000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f0dd238c000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f0dd195d000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f0dd1d5c000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f0dd1979000)
	libstartup-notification-1.so.0 => /lib/x86_64-linux-gnu/libstartup-notification-1.so.0 (0x00007f0dd21f2000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007f0dd143c000)
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007f0dd1a0c000)
	libthunarx-3.so.0 => /lib/x86_64-linux-gnu/libthunarx-3.so.0 (0x00007f0dd35a7000)
	libudev.so.1 => /lib/x86_64-linux-gnu/libudev.so.1 (0x00007f0dd235f000)
	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f0dd2354000)
	libwayland-client.so.0 => /lib/x86_64-linux-gnu/libwayland-client.so.0 (0x00007f0dd1d7e000)
	libwayland-cursor.so.0 => /lib/x86_64-linux-gnu/libwayland-cursor.so.0 (0x00007f0dd1d94000)
	libwayland-egl.so.1 => /lib/x86_64-linux-gnu/libwayland-egl.so.1 (0x00007f0dd1d8f000)
	libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007f0dd1c3d000)
	libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007f0dd1c78000)
	libxcb-util.so.1 => /lib/x86_64-linux-gnu/libxcb-util.so.1 (0x00007f0dd16d6000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007f0dd1c4c000)
	libxfce4ui-2.so.0 => /lib/x86_64-linux-gnu/libxfce4ui-2.so.0 (0x00007f0dd350e000)
	libxfce4util.so.7 => /lib/x86_64-linux-gnu/libxfce4util.so.7 (0x00007f0dd2acf000)
	libxfconf-0.so.3 => /lib/x86_64-linux-gnu/libxfconf-0.so.3 (0x00007f0dd2ab1000)
	libxkbcommon.so.0 => /lib/x86_64-linux-gnu/libxkbcommon.so.0 (0x00007f0dd1d9f000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f0dd1a17000)
	linux-vdso.so.1 (0x00007fff8b5ab000)
```