

- ~~lxappearance~~ `dyn:ok` @Lxde
- gpicview `dyn:ok` @Lxde
- ~~lxtask~~ `dyn:ok` @Lxde
- jgmenu `dyn:ok`
- 
- ~~tint2~~ `imlib2`
- rofi `xcb-ewmh/icccm/cursor`
- sakura `SAKURA_2_3_7:vte`

## Lxde Misc

```bash
# bash-5.1# history |tail -40
    1  cd /mnt2/_misc2-2/
   #29  cd lxappearance/
   30  ls
   31  ./autogen.sh 
   32  ls
   33  ./configure 
   34  make
   35  ls
   36  ls src/
   37  ldd src/lxappearance
   #38  cd ../lxtask/
   39  ls
   40  ./autogen.sh 
   41  ls
   42  ./configure 
   43  make
   44  ls
   45  ls src/
   46  ./src/lxtask 
   47  ldd ./src/lxtask 

  #  3  cd gpicview/
    4  ls
    5  ./autogen.sh 
    6  ./configure 
    7  ls
    8  make
    9  ls -lh
   10  ls src/
   11  ldd src/gpicview
   12  cd ..
   13  ls
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

```

- rofi

```bash
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

## static

### lxappearance, lxtask

```bash
    1  cd /mnt2/_misc2-2/_lxde/
    2  ll
    3  ls
    4  cd lxappearance/
    5  ls
    6  ./autogen.sh 
    7  echo $?
    8  ls
    9  make
   10  ls
   11  ls src/
   12  ls -lh src/lxappearance
   13  ldd src/lxappearance
   14  ld
   15  ./configure --enable-static
   16  make clean
   17  make

export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=clang++

# ref pcmanfm; gmodule-2.0已有;
  OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
  ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
  # -lXdamage注释也会用到;
  #  -lfm -lfm-gtk -lmenu-cache 
  ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage "
  LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1


# bash-5.1# make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1
make[2]: Entering directory '/mnt2/_misc2-2/_lxde/lxappearance/src'
  CCLD     lxappearance
make[2]: Leaving directory '/mnt2/_misc2-2/_lxde/lxappearance/src'
make[2]: Entering directory '/mnt2/_misc2-2/_lxde/lxappearance'
make[2]: Leaving directory '/mnt2/_misc2-2/_lxde/lxappearance'
make[1]: Leaving directory '/mnt2/_misc2-2/_lxde/lxappearance'
bash-5.1# ls -lh src/lxappearance
-rwxr-xr-x    1 root     root       36.4M Dec 30 04:00 src/lxappearance
bash-5.1# ldd src/lxappearance
/lib/ld-musl-x86_64.so.1: src/lxappearance: Not a valid dynamic program


# lxtask 相同； 不用./configrue --enable-static(无该选项)
  CCLD     lxtask
make[2]: Leaving directory '/mnt2/_misc2-2/_lxde/lxtask/src'
make[2]: Entering directory '/mnt2/_misc2-2/_lxde/lxtask'
make[2]: Leaving directory '/mnt2/_misc2-2/_lxde/lxtask'
make[1]: Leaving directory '/mnt2/_misc2-2/_lxde/lxtask'
bash-5.1# ls src/lxtask
src/lxtask
bash-5.1# ls src/lxtask -lh
-rwxr-xr-x    1 root     root       35.8M Dec 30 04:02 src/lxtask
bash-5.1# ldd src/lxtask
/lib/ld-musl-x86_64.so.1: src/lxtask: Not a valid dynamic program
```

- run: lxappearance, lxtask

```bash
# lxtask: OK

# lxappearance v063@master
# gmodule错误; x11-base错; docker-headless下一样错;
# https://github.com/lxde/lxappearance
master 678 @2023.9.18
063    647 @2017.1.25
056    597 @2014.7.20 ##run一样gmodule错
050    282 @2010.10.10

# @master
# bash-5.1# ./configure -h
'configure' configures lxappearance 0.6.3 to adapt to many kinds of systems.

# v056
static-build ok; #run一样gmodule错

# v050
bash-5.1# ./autogen.sh 
You must have automake > 1.10 or 1.11 installed to compile this program. 
```

### gpicview

```bash
   66  cd ../gpicview/
   68  ./autogen.sh 
   75  ldd src/gpicview
   76  ./configure --enable-static #gpicview有该指令;
   77  make clean
   78  make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1
   79  ls src/gpicview -lh
   80  ldd src/gpicview -lh
# make -static>> dyn
  # +Xcursor, Xi
	libXi.so.6 => /usr/lib/libXi.so.6 (0x7f3c945d3000)
	libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7f3c945bb000)
	libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f3c945c7000)
	libXdamage.so.1 => /usr/lib/libXdamage.so.1 (0x7f3c945b6000)


apk add libxcursor-dev
rm -rf /src; ln -s /mnt2/docker-x11base/compile/src /src
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu  ##DBG
bash /src/v-tint2/build.sh b_deps
# -Xcursor -Xi
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr -lXcursor -lXi $LIBS0" 2>&1

# 
bash-5.1# ldd src/gpicview |sort
	/lib/ld-musl-x86_64.so.1 (0x7f3c4b709000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f3c4a5dd000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f3c4b172000)
	libXdamage.so.1 => /usr/lib/libXdamage.so.1 (0x7f3c4a5bb000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f3c4b177000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f3c4b15f000)
	libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7f3c4a700000)
	libXft.so.2 => /usr/lib/libXft.so.2 (0x7f3c4b149000)
	libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7f3c4b6e7000)
	libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f3c4a5c0000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f3c4b053000)
	libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7f3c4b6db000) ##a
	libXi.so.6 => /usr/lib/libXi.so.6 (0x7f3c4a5cc000) ##a
	libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7f3c4a9e5000) ##a  如下已在LIBS内
	libgpg-error.so.0 => /usr/lib/libgpg-error.so.0 (0x7f3c4ac29000) ##a
	libgraphite2.so.3 => /usr/lib/libgraphite2.so.3 (0x7f3c4ac09000) ##a
	libintl.so.8 => /usr/lib/libintl.so.8 (0x7f3c4ae7b000) ##a
  # 
	libatk-1.0.so.0 => /usr/local/lib/libatk-1.0.so.0 (0x7f3c4b23d000)
	libblkid.so.1 => /lib/libblkid.so.1 (0x7f3c4a9ea000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f3c4ae88000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f3c4aeab000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f3c4a5a8000)
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f3c4aedb000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f3c4b709000)
	libcairo.so.2 => /usr/lib/libcairo.so.2 (0x7f3c4a708000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f3c4b02e000)
	libffi.so.8 => /usr/lib/libffi.so.8 (0x7f3c4ac9b000)
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f3c4a9a8000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f3c4b090000)
	libfribidi.so.0 => /usr/lib/libfribidi.so.0 (0x7f3c4ae5c000)
	libgdk-x11-2.0.so.0 => /usr/lib/libgdk-x11-2.0.so.0 (0x7f3c4b636000)
	libgdk_pixbuf-2.0.so.0 => /usr/local/lib/libgdk_pixbuf-2.0.so.0 (0x7f3c4b213000)
	libgio-2.0.so.0 => /usr/lib/libgio-2.0.so.0 (0x7f3c4a7f8000)
	libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7f3c4aca8000)
	libgmodule-2.0.so.0 => /usr/lib/libgmodule-2.0.so.0 (0x7f3c4ac96000)
	libgobject-2.0.so.0 => /usr/lib/libgobject-2.0.so.0 (0x7f3c4ac49000)
	libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7f3c4b266000)
	libharfbuzz.so.0 => /usr/lib/libharfbuzz.so.0 (0x7f3c4adb3000)
	libjpeg.so.8 => /usr/lib/libjpeg.so.8 (0x7f3c4aaec000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f3c4b05f000)
	liblzma.so.5 => /usr/lib/liblzma.so.5 (0x7f3c4aeb8000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f3c4a588000)
	libmount.so.1 => /lib/libmount.so.1 (0x7f3c4aa90000)
	libpango-1.0.so.0 => /usr/lib/libpango-1.0.so.0 (0x7f3c4b1a6000)
	libpangocairo-1.0.so.0 => /usr/lib/libpangocairo-1.0.so.0 (0x7f3c4b203000)
	libpangoft2-1.0.so.0 => /usr/lib/libpangoft2-1.0.so.0 (0x7f3c4b1ec000)
	libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7f3c4aa34000)
	libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7f3c4ab73000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f3c4aae3000)
	libxcb-render.so.0 => /usr/lib/libxcb-render.so.0 (0x7f3c4a594000)
	libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f3c4a5a3000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f3c4b17f000)
	libxml2.so.2 => /usr/lib/libxml2.so.2 (0x7f3c4af04000)
	libz.so.1 => /lib/libz.so.1 (0x7f3c4aeea000)
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