
## **xlunch**

```bash
# 
apk add imlib2-dev

# bash-5.1# pwd
/mnt2/xlunch
# bash-5.1# apk add hicolor-icon-theme
(1/1) Installing hicolor-icon-theme (0.17-r1)
OK: 749 MiB in 261 packages
# bash-5.1# make
make: Nothing to be done for 'all'.
# bash-5.1# pwd
/mnt2/xlunch
# bash-5.1# ls
AUTHORS       LICENSE       Makefile      README.md     default.conf  docs          entries.dsv   extra         xlunch        xlunch.c
bash-5.1# make
make: Nothing to be done for 'all'.

# 非静态01
# bash-5.1# ldd xlunch
        /lib/ld-musl-x86_64.so.1 (0x7f6322c0f000)
        libImlib2.so.1 => /usr/lib/libImlib2.so.1 (0x7f6322ba0000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7f6322a7d000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f6322c0f000)
        libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f63229c4000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7f63229b1000)
        libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7f63229ac000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f6322985000)
        libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f6322980000)
        libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f6322971000)
        libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f6322940000)
        libz.so.1 => /lib/libz.so.1 (0x7f6322926000)
        libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f6322919000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7f6322914000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f632290c000)
        libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f63228e9000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f63228d6000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7f63228ca000)


# bash-5.1# ls -lh xlunch
-rwxr-xr-x    1 root     root       73.8K Nov 25 14:20 xlunch
# bash-5.1# ./xlunch  -v
xlunch graphical program launcher, version 4.7.5
# bash-5.1# env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=-static -Wl,--strip-all -Wl,--as-needed
CPPFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer
```

- try static

```bash
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

# bash-5.1# make LDFLAGS="-static --static "
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: xlunch.c:(.text.startup+0xd80): undefined reference to 'imlib_image_fill_rectangle'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: xlunch.c:(.text.startup+0xd87): undefined reference to 'imlib_context_set_blend'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: xlunch.c:(.text.startup+0xda1): undefined reference to 'imlib_updates_free'
collect2: error: ld returned 1 exit status
make: *** [Makefile:46: xlunch] Error 1

# imlib2: 无静态库
# bash-5.1# find /usr/lib |grep imlib
/usr/lib/imlib2
/usr/lib/imlib2/filters
/usr/lib/imlib2/filters/bumpmap.so
/usr/lib/imlib2/filters/colormod.so
/usr/lib/imlib2/filters/testfilter.so
/usr/lib/imlib2/loaders
/usr/lib/imlib2/loaders/zlib.so
/usr/lib/imlib2/loaders/tiff.so
/usr/lib/imlib2/loaders/lbm.so
/usr/lib/imlib2/loaders/png.so
/usr/lib/imlib2/loaders/id3.so
/usr/lib/imlib2/loaders/xpm.so
/usr/lib/imlib2/loaders/xbm.so
/usr/lib/imlib2/loaders/ico.so
/usr/lib/imlib2/loaders/webp.so
/usr/lib/imlib2/loaders/argb.so
/usr/lib/imlib2/loaders/tga.so
/usr/lib/imlib2/loaders/jpeg.so
/usr/lib/imlib2/loaders/gif.so
/usr/lib/imlib2/loaders/ff.so
/usr/lib/imlib2/loaders/pnm.so
/usr/lib/imlib2/loaders/bz2.so
/usr/lib/imlib2/loaders/bmp.so
/usr/lib/pkgconfig/imlib2.pc


# bash-5.1# apk list |grep imlib2
imlib2-1.7.4-r0 x86_64 {imlib2} (Imlib2) [installed]
imlib2-dev-1.7.4-r0 x86_64 {imlib2} (Imlib2) [installed]

# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
# ./configure; make; make install; >>> /usr/local/lib;
# 
https://github.com/kkoudev/imlib2 #v1.4.10
https://sourceforge.net/projects/enlightenment/files/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz/download
https://sourceforge.net/projects/enlightenment/files/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz/download

# bash-5.1# find /usr/local/lib |grep imlib |grep "\.a$" |sort
/usr/local/lib/imlib2/filters/bumpmap.a
/usr/local/lib/imlib2/filters/colormod.a
/usr/local/lib/imlib2/filters/testfilter.a
/usr/local/lib/imlib2/loaders/ani.a
/usr/local/lib/imlib2/loaders/argb.a
/usr/local/lib/imlib2/loaders/bmp.a
/usr/local/lib/imlib2/loaders/bz2.a
/usr/local/lib/imlib2/loaders/ff.a
/usr/local/lib/imlib2/loaders/ico.a
/usr/local/lib/imlib2/loaders/jpeg.a
/usr/local/lib/imlib2/loaders/lbm.a
/usr/local/lib/imlib2/loaders/png.a
/usr/local/lib/imlib2/loaders/pnm.a
/usr/local/lib/imlib2/loaders/tga.a
/usr/local/lib/imlib2/loaders/tiff.a
/usr/local/lib/imlib2/loaders/webp.a
/usr/local/lib/imlib2/loaders/xbm.a
/usr/local/lib/imlib2/loaders/xcf.a
/usr/local/lib/imlib2/loaders/xpm.a
/usr/local/lib/imlib2/loaders/zlib.a


# https://github.com/search?q=-limlib2+enable-static&type=code
bash-5.1# make LDFLAGS="-static --static " #
bash-5.1# make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib"
```

- try02: # +OB_LIBS +xcb-shm: OK

```bash
# 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
bash-5.1# make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u

/usr/local/lib/libImlib2.a(api.o):
/usr/local/lib/libImlib2.a(color.o):
/usr/local/lib/libImlib2.a(context.o):
/usr/local/lib/libImlib2.a(draw.o):
/usr/local/lib/libImlib2.a(font_draw.o):
/usr/local/lib/libImlib2.a(font_load.o):
/usr/local/lib/libImlib2.a(font_main.o):
/usr/local/lib/libImlib2.a(font_query.o):
/usr/local/lib/libImlib2.a(grab.o):
/usr/local/lib/libImlib2.a(image.o):
/usr/local/lib/libImlib2.a(rend.o):
/usr/local/lib/libImlib2.a(ximage.o):
api.c:(.text+0x2e19):
api.c:(.text+0x2e57):
api.c:(.text+0x2ec9):
api.c:(.text+0x2ee8):
api.c:(.text+0x2f0e):



# +OB_LIBS
# bash-5.1# make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb $OB_LIBS"
gcc xlunch.c -o xlunch -static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lX11 -lxcb -lXdmcp -lXau -lXext -lXft  -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz  -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi -Os -fomit-frame-pointer
In file included from xlunch.c:39:
/usr/include/sys/poll.h:1:2: warning: #warning redirecting incorrect #include <sys/poll.h> to <poll.h> [-Wcpp]
    1 | #warning redirecting incorrect #include <sys/poll.h> to <poll.h>
      |  ^~~~~~~
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(ximage.o): in function '__imlib_ShmGetXImage':
ximage.c:(.text+0x1e7): undefined reference to 'xcb_shm_create_segment'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x1f6): undefined reference to 'xcb_shm_create_segment_reply'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x217): undefined reference to 'xcb_shm_create_segment_reply_fds'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: ximage.c:(.text+0x309): undefined reference to 'xcb_shm_detach'
collect2: error: ld returned 1 exit status
make: *** 



# bash-5.1# find /usr/lib |grep xcb |grep shm
/usr/lib/pkgconfig/xcb-shm.pc
/usr/lib/pkgconfig/cairo-xcb-shm.pc
/usr/lib/libxcb-shm.so.0.0.0
/usr/lib/libxcb-shm.so.0
/usr/lib/libxcb-shm.a
/usr/lib/libxcb-shm.so

# +xcb-shm: OK
# bash-5.1# make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
bash-5.1# pwd
/mnt2/_misc2/xlunch
bash-5.1# ls -lh xlunch
-rwxr-xr-x    1 root     root        3.5M Nov 27 14:30 xlunch
bash-5.1# ldd xlunch
/lib/ld-musl-x86_64.so.1: xlunch: Not a valid dynamic program
```

