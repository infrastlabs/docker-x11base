## dyn

**try1**

```bash
/mnt2/docker-x11base/compile/src # 
# ref xlunch, tint2
bash /src/v-xlunch/build.sh imlib2
  bash /src/v-tint2/build.sh xcbutil & ##need?
    git://anongit.freedesktop.org/xcb/util-common-m4.git
  bash /src/v-tint2/build.sh libxi &  ##need?

/mnt2/docker-x11base/compile/fk-feh # 
# https://gitee.com/g-system/fk-feh
export DESTDIR=/tmp/feh PREFIX=/usr
export curl=false xinerama=0
make 

# err1: X11/Intrinsic.h: No such file or directory
apk add libxt-dev


# xcb_generate_id
/mnt2/docker-x11base/compile/fk-feh # make
make[1]: Entering directory '/mnt2/docker-x11base/compile/fk-feh/src'
cc  -g -O2 -Wall -Wextra -pedantic -std=c11 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_DARWIN_C_SOURCE -DHAVE_MKSTEMPS -DHAVE_STRVERSCMP -DPREFIX=\"/usr/local\" -DPACKAGE=\"feh\" -DVERSION=\"3.10.3-4-g70a7b06\" -o feh events.o feh_png.o filelist.o gib_hash.o gib_imlib.o gib_list.o gib_style.o imlib.o index.o keyevents.o list.o main.o md5.o menu.o multiwindow.o options.o signals.o slideshow.o thumbnail.o timers.o utils.o wallpaper.o winwidget.o -lm -lpng -lX11 -lImlib2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libX11.so: undefined reference to symbol 'xcb_generate_id'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/libxcb.so.1: error adding symbols: DSO missing from command line
collect2: error: ld returned 1 exit status
make[1]: *** [Makefile:45: feh] Error 1
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/src'
make: *** [Makefile:6: build-src] Error 2
/mnt2/docker-x11base/compile/fk-feh # find /usr/lib /usr/local/lib |grep libxcb

/mnt2/docker-x11base/compile/fk-feh # find /usr/lib /usr/local/lib |grep libX11
/usr/lib/libX11-xcb.so
/usr/lib/libX11-xcb.so.1
/usr/lib/libX11-xcb.a
/usr/lib/libX11-xcb.so.1.0.0
/usr/lib/libX11.so
/usr/lib/libX11.so.6.4.0
/usr/lib/libX11.so.6
/usr/lib/libX11.a
/mnt2/docker-x11base/compile/fk-feh # find /usr/lib /usr/local/lib |grep libpng
/usr/lib/pkgconfig/libpng.pc
/usr/lib/pkgconfig/libpng16.pc
/usr/lib/libpng16.so.16.37.0
/usr/lib/libpng16.so
/usr/lib/libpng16.so.16
/usr/lib/libpng.so
/usr/lib/libpng.a
/usr/lib/libpng16.a
/mnt2/docker-x11base/compile/fk-feh # apk add libpng-dev \
>     libpng-static
OK: 939 MiB in 322 packages
/mnt2/docker-x11base/compile/fk-feh # apk add libx11-dev  libx11-static
OK: 939 MiB in 322 packages


LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"
# v-tint2
ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd -lcroco-0.6 -lImlib2" # -lfm -lfm-gtk 

OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype \
          -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon \
          -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 \
          -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 

flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

/mnt2/docker-x11base/compile/fk-feh # make LDFLAGS="$flags $OB_LIBS -luuid"
```

**try2** (config.mk)

```bash
# bash-5.1# cat config.mk
LDLIBS += -lm -lpng -lX11 -lImlib2     -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon      -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd

# bash-5.1# make clean; make
cc  -g -O2 -Wall -Wextra -pedantic -std=c11 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_DARWIN_C_SOURCE -DHAVE_MKSTEMPS -DHAVE_STRVERSCMP -DPREFIX=\"/usr\" -DPACKAGE=\"feh\" -DVERSION=\"3.10.3-4-g70a7b06-dirty\" -o feh events.o feh_png.o filelist.o gib_hash.o gib_imlib.o gib_list.o gib_style.o imlib.o index.o keyevents.o list.o main.o md5.o menu.o multiwindow.o options.o signals.o slideshow.o thumbnail.o timers.o utils.o wallpaper.o winwidget.o -lm -lpng -lX11 -lImlib2 -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon    -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(api.o): in function `imlib_create_scaled_image_from_drawable':
api.c:(.text+0x2e57): undefined reference to `XShapeGetRectangles'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(grab.o): in function `__imlib_GrabDrawableToRGBA':
grab.c:(.text+0x17df): undefined reference to `XShapeGetRectangles'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(rend.o): in function `__imlib_RenderImage':
rend.c:(.text+0xe76): undefined reference to `XShmPutImage'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: rend.c:(.text+0xede): undefined reference to `XShmPutImage'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(ximage.o): in function `__imlib_ShmGetXImage':
ximage.c:(.text+0x40): undefined reference to `XShmQueryExtension'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x62): undefined reference to `XShmQueryVersion'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x178): undefined reference to `XShmCreateImage'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x358): undefined reference to `XShmGetImage'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x373): undefined reference to `XShmAttach'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x395): undefined reference to `XShmGetImage'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(ximage.o): in function `__imlib_ShmDestroyXImage':
ximage.c:(.text+0x43d): undefined reference to `XShmDetach'
collect2: error: ld returned 1 exit status
make[1]: *** [Makefile:45: feh] Error 1
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/src'
make: *** [Makefile:6: build-src] Error 2

# XShm
bash /src/x-tigervnc/build.sh libxshmfence # 无用;


# https://gitee.com/g-system/fk-feh
# # Dependencies
  # libpng
  # libX11
  # libXt
  # Imlib2 #build
  # libcurl (disable with curl=0)
  # libXinerama (disable with xinerama=0)
# # Only when building with exif=1:
  # libexif-dev
  # libexif12
# # Only when building with magic=1:
  # libmagic


# ldd @x11-alpine-app;
/home/headless # pkgsize |grep feh
KiB|0312|feh-3.10.2-r0
/home/headless # which feh
/usr/bin/feh
/home/headless # ldd /usr/bin/feh |sort
	/lib/ld-musl-x86_64.so.1 (0x7f93fced3000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f93fced3000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f93fc424000)
	# 
	# libImlib2.so.1 => /usr/lib/libImlib2.so.1 (0x7f93fcc44000)
	# libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7f93fc61d000)
	# libX11.so.6 => /usr/lib/libX11.so.6 (0x7f93fccaa000)
	# libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f93fc618000)
	# libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f93fc6c6000)
	# libXau.so.6 => /usr/lib/libXau.so.6 (0x7f93fc452000)
	# libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f93fc44a000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f93fc6ed000)
	libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7f93fcdf5000)
	# libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f93fc457000)
	# libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f93fc718000)
	# 
	libssl.so.3 => /lib/libssl.so.3 (0x7f93fcb46000)
	libunistring.so.5 => /usr/lib/libunistring.so.5 (0x7f93fc47a000)
	# libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f93fc622000)
	# libmd.so.0 => /usr/lib/libmd.so.0 (0x7f93fc416000)
	# libz.so.1 => /lib/libz.so.1 (0x7f93fc6fe000)
	# libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f93fc437000)
	libcares.so.2 => /usr/lib/libcares.so.2 (0x7f93fcc21000)
	libcrypto.so.3 => /lib/libcrypto.so.3 (0x7f93fc727000)
	libidn2.so.0 => /usr/lib/libidn2.so.0 (0x7f93fcbcc000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f93fcdc6000)
	libcurl.so.4 => /usr/lib/libcurl.so.4 (0x7f93fce1b000)
	libmagic.so.1 => /usr/lib/libmagic.so.1 (0x7f93fcdfa000)
	libnghttp2.so.14 => /usr/lib/libnghttp2.so.14 (0x7f93fcbfd000)



LDLIBS += -lm -lpng -lX11 -lImlib2     -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon      -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd

# https://gitee.com/g-system/fk-feh
export DESTDIR=/tmp/feh PREFIX=/usr
export curl=false xinerama=0 exif=0 magic=0
make clean; make 


################################
# none: -lXcursor 
+++###  -lXext -lXinerama -lXfixes -lXrandr -lXi ##加上后，错误过了;

# ref tint2: cmake>> 
deps="Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2 Xcursor Xi"
# ref xlunch
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext  -lfreetype -lpng   -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS" xlunch

# ref jemenu,sakura.md:
# -lImlib2
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr -lXcursor -lXi -lImlib2 $LIBS0" 2>&1



# bash-5.1# make clean; make 
cc  -g -O2 -Wall -Wextra -pedantic -std=c11 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_DARWIN_C_SOURCE -DHAVE_MKSTEMPS -DHAVE_STRVERSCMP -DPREFIX=\"/usr\" -DPACKAGE=\"feh\" -DVERSION=\"3.10.3-4-g70a7b06-dirty\" -o feh events.o feh_png.o filelist.o gib_hash.o gib_imlib.o gib_list.o gib_style.o imlib.o index.o keyevents.o list.o main.o md5.o menu.o multiwindow.o options.o signals.o slideshow.o thumbnail.o timers.o utils.o wallpaper.o winwidget.o -lm -lpng -lX11 -lImlib2 -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon    -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd       -lXext -lXinerama -lXfixes -lXrandr -lXi
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/src'
make[1]: Entering directory '/mnt2/docker-x11base/compile/fk-feh/man'
sed \
-e 's/\$VERSION\$/3.10.3-4-g70a7b06-dirty/g' \
-e 's/\$DATE\$/July 04, 2024/g' \
-e 's/\$MAN_CURL\$/disabled/' \
-e 's/\$MAN_DEBUG\$/./' \
-e 's/\$MAN_EXIF\$/not available/' \
-e 's/\$MAN_INOTIFY\$/disabled/' \
-e 's/\$MAN_MAGIC\$/disabled/' \
-e 's/\$MAN_XINERAMA\$/disabled/' \
< feh.pre > feh.1
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/man'
make[1]: Entering directory '/mnt2/docker-x11base/compile/fk-feh/share/applications'
sed \
-e 's/\$VERSION\$/3.10.3-4-g70a7b06-dirty/g' \
-e 's/\$DATE\$/'"$(date '+%B %d, %Y')"/g \
-e 's/\$MAN_CURL\$/disabled/' \
-e 's/\$MAN_DEBUG\$/./' \
-e 's/\$MAN_EXIF\$/not available/' \
-e 's/\$MAN_XINERAMA\$/disabled/' \
-e 's:\$IMAGEDIR\$:/tmp/feh/usr/share/feh/images:' \
< feh.pre > feh.desktop
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/share/applications'

# bash-5.1# ldd src/feh |sort
        /lib/ld-musl-x86_64.so.1 (0x7f6379249000)
        libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7f6378f76000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7f637905b000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7f6378f3f000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f6378f37000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7f6378f5e000)
        libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f6378ee5000)
        libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f6378f1b000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f6378f08000)
        libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f6378f28000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f6379249000)
        libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f6378f7b000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7f6378ed9000)
        libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f637917e000)
        libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f6378f71000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f6379034000)
        libz.so.1 => /lib/libz.so.1 (0x7f6378f44000)
```

## static


```bash
export DESTDIR=/tmp/feh PREFIX=/usr
export curl=false xinerama=0 exif=0 magic=0
make clean; make LDFLAGS="-static "


# bash-5.1# make clean; make LDFLAGS="-static "
cc -static  -g -O2 -Wall -Wextra -pedantic -std=c11 -D_POSIX_C_SOURCE=200809L -D_XOPEN_SOURCE=700 -D_DARWIN_C_SOURCE -DHAVE_MKSTEMPS -DHAVE_STRVERSCMP -DPREFIX=\"/usr\" -DPACKAGE=\"feh\" -DVERSION=\"3.10.3-4-g70a7b06-dirty\" -o feh events.o feh_png.o filelist.o gib_hash.o gib_imlib.o gib_list.o gib_style.o imlib.o index.o keyevents.o list.o main.o md5.o menu.o multiwindow.o options.o signals.o slideshow.o thumbnail.o timers.o utils.o wallpaper.o winwidget.o -lm -lpng -lX11 -lImlib2 -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon    -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd       -lXext -lXinerama -lXfixes -lXrandr -lXi
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/src'
make[1]: Entering directory '/mnt2/docker-x11base/compile/fk-feh/man'
sed \
-e 's/\$VERSION\$/3.10.3-4-g70a7b06-dirty/g' \
-e 's/\$DATE\$/July 04, 2024/g' \
-e 's/\$MAN_CURL\$/disabled/' \
-e 's/\$MAN_DEBUG\$/./' \
-e 's/\$MAN_EXIF\$/not available/' \
-e 's/\$MAN_INOTIFY\$/disabled/' \
-e 's/\$MAN_MAGIC\$/disabled/' \
-e 's/\$MAN_XINERAMA\$/disabled/' \
< feh.pre > feh.1
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/man'
make[1]: Entering directory '/mnt2/docker-x11base/compile/fk-feh/share/applications'
sed \
-e 's/\$VERSION\$/3.10.3-4-g70a7b06-dirty/g' \
-e 's/\$DATE\$/'"$(date '+%B %d, %Y')"/g \
-e 's/\$MAN_CURL\$/disabled/' \
-e 's/\$MAN_DEBUG\$/./' \
-e 's/\$MAN_EXIF\$/not available/' \
-e 's/\$MAN_XINERAMA\$/disabled/' \
-e 's:\$IMAGEDIR\$:/tmp/feh/usr/share/feh/images:' \
< feh.pre > feh.desktop
make[1]: Leaving directory '/mnt2/docker-x11base/compile/fk-feh/share/applications'

# bash-5.1# ldd src/feh
/lib/ld-musl-x86_64.so.1: src/feh: Not a valid dynamic program
# bash-5.1# ls -lh src/feh ../feh-dyn 
-rwxr-xr-x    1 root     root        1.3M Jul  4 03:13 ../feh-dyn
-rwxr-xr-x    1 root     root        4.5M Jul  4 04:19 src/feh #static

bash-5.1# mv src/feh ../feh-static
bash-5.1# ../feh-static -v
feh version 3.10.3-4-g70a7b06-dirty
Compile-time switches: verscmp


#test@deb10;
# root @ deb1013 in .../docker-x11base/compile |00:21:35  |dev ?:3 ✗| 
$ ./feh-dyn -v
-bash: ./feh-dyn: No such file or directory
# root @ deb1013 in .../docker-x11base/compile |00:21:42  |dev ?:3 ✗| 
$ ./feh-static -v
feh version 3.10.3-4-g70a7b06-dirty
Compile-time switches: verscmp
```

## Run

```bash
# ERR: no imlib2 loader for that file format

bash /src/v-xlunch/build.sh imlib2 #imlib2-1.7.4.tar.g@sourceforge
v1.6.1-1ubuntu @ubt2004
v1.12.1-r0 @alpine3.19


# 少装了imlib2_loaders ??
# org: https://sourceforge.net/projects/enlightenment/files/imlib2-src/1.7.4/
# v1.12.2
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz #xz,gz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2_loaders-1.12.2.tar.xz
# v1.7.4
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz #gz,bz2
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz

```

## hsetroot

```bash
deps0="-lm -lpng -lX11 -lImlib2"
deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
deps2="-lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd"
deps3="-lXext -lXinerama -lXfixes -lXrandr -lXi"

# make clean; make LDFLAGS="-static $deps0 $deps1 $deps2 $deps3 "
make clean; make LDFLAGS="$deps0 $deps1 $deps2 $deps3 "
```

