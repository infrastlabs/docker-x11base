
- **LukeSmithxyz/st**  https://ghproxy.com/https://github.com/LukeSmithxyz/st

```bash
/mnt2/st # history 
   0 ls
   1 cd st
   2 cd /mnt2/st/
   3 ls
   4 make
   5 apk add harfbuzz
   6 make
   7 apk add harfbuzz-dev
   8 make
   9 cp config.mk config.mk-bk3
  10 vi config.mk
  11 make
  12 apk add harfbuzz-*
  13 apk add harfbuzz-static
  14 make
  15 history 

/mnt2/st # make
st build options:
CFLAGS  = -I/usr/X11R6/include  -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/uuid   -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include  -DVERSION="0.8.5" -D_XOPEN_SOURCE=600  -O1
LDFLAGS = -L/usr/X11R6/lib -static   -lm -lrt -lX11 -lX11-xcb -lutil -lXft -lXrender -lfontconfig -lfreetype   -lfreetype   -lharfbuzz  
CC      = c99
c99 -o st st.o x.o boxdraw.o hb.o -L/usr/X11R6/lib -static   -lm -lrt -lX11 -lX11-xcb -lutil -lXft -lXrender `pkg-config --libs fontconfig`  `pkg-config --libs freetype2`  `pkg-config --libs harfbuzz` 
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lfontconfig
collect2: error: ld returned 1 exit status
make: *** [Makefile:29: st] Error 1

# bash fontconfig/build.sh; #调改build.sh 免font/xx copy's err
  36 make
  37 find /usr/ |grep fontco
  38 find /tmp/fontconfig-install/
  39 ls /tmp/fontconfig/
  40 \cp -a /tmp/fontconfig-install/* /
  41 make
  # STATIC: 一堆错..;  libx11_xcb错也有;

# 去-static: make OK;
```

- **st-siduck** https://github.com/siduck/st

```bash
/mnt2/st-siduck # git clone https://ghproxy.com/https://github.com/siduck/st st-siduck
/mnt2/st-siduck # make
st build options:
CFLAGS  = -I/usr/X11R6/include  -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include   -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/freetype2 -I/usr/include/libpng16   -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include  -DVERSION="0.8.5" -DICON="/usr/local/share/pixmaps/st.png" -D_XOPEN_SOURCE=600  -O1
LDFLAGS = -L/usr/X11R6/lib -lm -lrt -lX11 -lutil -lXft -lgd  -lglib-2.0 -lintl   -lfontconfig -lfreetype   -lfreetype   -lharfbuzz  
CC      = c99
cp config.def.h config.h
c99 -I/usr/X11R6/include  `pkg-config --cflags glib-2.0`  `pkg-config --cflags fontconfig`  `pkg-config --cflags freetype2`  `pkg-config --cflags harfbuzz` -DVERSION=\"0.8.5\" -DICON=\"/usr/local/share/pixmaps/st.png\" -D_XOPEN_SOURCE=600  -O1 -c st.c
In file included from st.c:21:
st.h:6:10: fatal error: gd.h: No such file or directory
    6 | #include <gd.h>
      |          ^~~~~~
compilation terminated.
make: *** [Makefile:22: st.o] Error 1



  45 apk add  git
  46 git clone https://ghproxy.com/https://github.com/siduck/st st-siduck
  47 cd st-siduck/
  48 ls
  49 make
  50 cd st-siduck/
  51 apk add gd
  52 apk add gd-dev #>> make OK;
  53 apk add gd-static #not exist
  54 make
  55 echo $?
  56 ls
  57 ./st
  58 ./st -h
  59 ls -lh st


# -static
/mnt2/st-siduck # make
c99 -o st st.o x.o boxdraw.o hb.o -L/usr/X11R6/lib -static -lm -lrt -lX11 -lutil -lXft -lgd  `pkg-config --libs glib-2.0`  `pkg-config --libs fontconfig`  `pkg-config --libs freetype2`  `pkg-config --libs harfbuzz` 
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
collect2: error: ld returned 1 exit status
make: *** [Makefile:32: st] Error 1
```

- **st-2015-org's** https://github.com/daGrevis/suckless-st

```bash
# make ok
# -static: libx11, libxft错误;

export CC=clang
export CXX=clang++
# -static: libx11, libxft一样错误;
/mnt2/st-2015 # make 2>&1 |grep /usr/lib/lib
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `require_socket':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_event':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_response':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XSend':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XEventsQueued':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReadEvents':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XAllocIDs':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReply':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `OutOfMemory':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `XOpenDisplay':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_disp.o): in function `_XConnectXCB':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(ClDisplay.o): in function `XCloseDisplay':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcolor.o): in function `XftColorAllocName':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcolor.o): in function `XftColorAllocValue':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcolor.o): in function `XftColorFree':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `_XftDrawCorePrepare':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `_XftDrawRenderPrepare':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawBitsPerPixel':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawChange':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawDestroy':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawSrcPicture':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawRect':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawSetClip':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawSetClipRectangles':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdraw.o): in function `XftDrawSetSubwindowMode':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftfreetype.o): in function `XftFontDestroy':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftfreetype.o): in function `XftFontOpenInfo':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftglyphs.o): in function `XftFontLoadGlyphs':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftglyphs.o): in function `XftFontUnloadGlyphs':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftglyphs.o): in function `_XftFontUncacheGlyph':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftrender.o): in function `XftGlyphFontSpecRender.part.0':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftrender.o): in function `XftGlyphSpecRender.part.0':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftrender.o): in function `XftGlyphRender':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftrender.o): in function `_XftCompositeString.part.0':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftrender.o): in function `_XftCompositeText.part.0':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcore.o): in function `XftGlyphCore':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcore.o): in function `XftGlyphSpecCore':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftcore.o): in function `XftGlyphFontSpecCore':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdpy.o): in function `_XftDefaultInitDouble':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdpy.o): in function `_XftDefaultInitInteger':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdpy.o): in function `_XftDefaultInitBool':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdpy.o): in function `_XftDisplayInfoGet':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libXft.a(xftdpy.o): in function `XftDefaultSubstitute':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfontconfig.a(fcxml.o): in function `FcConfigParseAndLoadFromMemoryInternal':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfontconfig.a(fcxml.o): in function `FcConfigMessage':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(sfnt.o): in function `Load_SBit_Png':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(sfnt.o): in function `error_callback':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(sfnt.o): in function `read_data_from_FT_Stream':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(sfnt.o): in function `sfnt_open_font':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftgzip.o): in function `ft_gzip_file_fill_output':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftgzip.o): in function `ft_gzip_file_io':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftgzip.o): in function `ft_gzip_stream_close':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftgzip.o): in function `FT_Stream_OpenGzip':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftgzip.o): in function `FT_Gzip_Uncompress':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftbzip2.o): in function `ft_bzip2_stream_close':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftbzip2.o): in function `ft_bzip2_file_fill_output':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftbzip2.o): in function `ft_bzip2_stream_io':
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libfreetype.a(ftbzip2.o): in function `FT_Stream_OpenBzip2':
/mnt2/st-2015 # 
[2] 0:docker*                    
```
