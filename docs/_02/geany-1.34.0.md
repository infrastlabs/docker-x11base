

```bash
# 
bash-5.1# 
bash-5.1# find |grep geany$
./src/geany
./src/.libs/geany
# bash-5.1# ldd src/.libs/geany 
	/lib/ld-musl-x86_64.so.1 (0x7f84c1458000)
Error loading shared library libgeany.so.0: No such file or directory (needed by src/.libs/geany)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f84c1458000)
Error relocating src/.libs/geany: main_lib: symbol not found
# bash-5.1# ldd src/.libs/libgeany.so |sort
	/lib/ld-musl-x86_64.so.1 (0x7f15d9057000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f15d8181000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f15d7ca4000)
	libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7f15d80f0000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f15d7c9c000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f15d80d3000)
	libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7f15d8179000)
	libXi.so.6 => /usr/lib/libXi.so.6 (0x7f15d8108000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f15d8119000)
	libblkid.so.1 => /lib/libblkid.so.1 (0x7f15d7c32000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f15d7c0f000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f15d7ca9000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f15d7bfc000)
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f15d7cb6000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f15d9057000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f15d7cce000)
	libffi.so.8 => /usr/lib/libffi.so.8 (0x7f15d7d4f000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f15d7f84000)
	libfribidi.so.0 => /usr/lib/libfribidi.so.0 (0x7f15d7e58000)
	libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7f15d82a4000)
	libgio-2.0.so.0 => /usr/lib/libgio-2.0.so.0 (0x7f15d85c9000)
	libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7f15d846c000)
	libgmodule-2.0.so.0 => /usr/lib/libgmodule-2.0.so.0 (0x7f15d8577000)
	libgobject-2.0.so.0 => /usr/lib/libgobject-2.0.so.0 (0x7f15d857c000)
	libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7f15d89b3000)
	libharfbuzz.so.0 => /usr/lib/libharfbuzz.so.0 (0x7f15d7daf000)
	libintl.so.8 => /usr/lib/libintl.so.8 (0x7f15d845f000)
	libjpeg.so.8 => /usr/lib/libjpeg.so.8 (0x7f15d7e77000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f15d7bf0000)
	libmount.so.1 => /lib/libmount.so.1 (0x7f15d7d5c000)
	# 
	libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7f15d80eb000)
	libXdamage.so.1 => /usr/lib/libXdamage.so.1 (0x7f15d80e6000) ##
	libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f15d80fc000)
	libcairo.so.2 => /usr/lib/libcairo.so.2 (0x7f15d87e8000) ##
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f15d8125000)
	libatk-1.0.so.0 => /usr/lib/libatk-1.0.so.0 (0x7f15d88d8000)
	libgdk-x11-2.0.so.0 => /usr/lib/libgdk-x11-2.0.so.0 (0x7f15d890e000) ##
	libgdk_pixbuf-2.0.so.0 => /usr/lib/libgdk_pixbuf-2.0.so.0 (0x7f15d87bf000)
	libgraphite2.so.3 => /usr/lib/libgraphite2.so.3 (0x7f15d7c7c000)
	libpango-1.0.so.0 => /usr/lib/libpango-1.0.so.0 (0x7f15d8779000) ##
	libpangocairo-1.0.so.0 => /usr/lib/libpangocairo-1.0.so.0 (0x7f15d88fe000)
	libpangoft2-1.0.so.0 => /usr/lib/libpangoft2-1.0.so.0 (0x7f15d8162000)
	libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7f15d7cf3000)
	libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7f15d803d000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f15d7f53000)
	libstdc++.so.6 => /usr/lib/libstdc++.so.6 (0x7f15d82be000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f15d7cc5000)
	libxcb-render.so.0 => /usr/lib/libxcb-render.so.0 (0x7f15d7f18000)
	libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f15d7f4e000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f15d7f27000)
	libz.so.1 => /lib/libz.so.1 (0x7f15d7efe000)
bash-5.1# 
# bash-5.1# history |tail -45
  159  cd ../_misc2/
  161  git clone https://hub.njuu.cf/geany/geany
  164  cd geany/
  165  git checkout 1.34.0
  168  apk add intltool
  173  apk add gtk+2.0-dev
  174  ./autogen.sh 
  176  ./configure
  178  make
  179  apk add rst2html
  182  ./configure -h 2>&1 |grep doc
  183  ./configure --enable-html-docs=no --enable-api-docs=no --enable-pdf-docs=no --enable-gtkdoc-docs=no
  184  make
  186  ls src/
  187  ls -lh src/geany
  188  ldd src/geany
  190  find |grep geany$
  191  ldd src/.libs/geany 
  192  ldd src/.libs/libgeany.so
bash-5.1# 
```

**static**

- master 10197 @23.11.23
- 1.38.0 9683 @2021.10.9
- 1.34.0 9206 @2018.12.16 `gtk2`

```bash
# dbg:
# root@tenvm2:~# docker run -it --rm --privileged -v /mnt:/mnt2 infrastlabs/x11-base:builder bash
apk add gawk git
cd /mnt2/docker-x11base/compile/
ln -s $(pwd)/src /src
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# git pull; bash src/v-geany/build.sh b_deps
# export TARGETPATH=/usr/local/static/v-geany
# bash src/v-geany/build.sh v-geany


bash /src/openbox/build.sh apkdeps
bash /src/openbox/build.sh pango & ##needed by gtk
bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
bash /src/xcompmgr/build.sh Xdamage &
wait
# 
bash /src/v-pcmanfm/build.sh apkdeps
bash /src/v-pcmanfm/build.sh atk & #needed by gtk
bash /src/v-pcmanfm/build.sh gdk-pixbuf & #needed by gtk
wait
bash /src/v-pcmanfm/build.sh gtk

# geany
apk add gtk-doc shared-mime-info \
 intltool vala \
 menu-cache-dev 
apk add \
  gobject-introspection-dev \
  gtk+2.0-dev \
  fontconfig-static libxcomposite-dev

./autogen.sh 

# deps
	export TARGETPATH=/usr/local/static/geany
	OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
	# -lmenu-cache 
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
	# -lfm -lfm-gtk 
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

LIBS="$LIBS0" ./configure --prefix=$TARGETPATH
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

# bash-5.1# ./configure -h 2>&1 |grep docs
#   --enable-html-docs \
#   --enable-pdf-docs \
#   --enable-api-docs
LIBS="$LIBS0" ./configure --prefix=$TARGETPATH \
  --disable-html-docs \
  --disable-pdf-docs \
  --disable-api-docs

#  2>&1 |grep musl/10 |awk '{print $2}' |sort -u
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u


export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++


# re-build
make clean
LIBS="$LIBS0" ./configure --prefix=$TARGETPATH
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u #无匹配项
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 

# /usr/bin/x86_64-alpine-linux-musl-ld: ./.libs/libgeany.a(RunStyles.o): in function 'std::__uniq_ptr_impl<Scintilla::SplitVector<char>, std::default_delete<Scintilla::SplitVector<char> > >::reset(Scintilla::SplitVector<char>*)':
RunStyles.cxx:(.text._ZNSt15__uniq_ptr_implIN9Scintilla11SplitVectorIcEESt14default_deleteIS2_EE5resetEPS2_[_ZNSt15__uniq_ptr_implIN9Scintilla11SplitVectorIcEESt14default_deleteIS2_EE5resetEPS2_]+0x15): undefined reference to 'operator delete(void*)'
/usr/bin/x86_64-alpine-linux-musl-ld: RunStyles.cxx:(.text._ZNSt15__uniq_ptr_implIN9Scintilla11SplitVectorIcEESt14default_deleteIS2_EE5resetEPS2_[_ZNSt15__uniq_ptr_implIN9Scintilla11SplitVectorIcEESt14default_deleteIS2_EE5resetEPS2_]+0x1e): undefined reference to 'operator delete(void*)'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:803: geany] Error 1
make[3]: Leaving directory '/mnt2/_misc2/geany/src'
make[2]: *** [Makefile:1265: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/_misc2/geany/src'
make[1]: *** [Makefile:599: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/geany'
make: *** [Makefile:483: all] Error 2

# src: * (HEAD detached at 1.34.0)

```


**try2**

- master @23.12.09 10203commits 
- 1.37
- 1.34.0 @2018.12.16 9206commits
- 1.30
- 1.27.0 @2016.3.13 8429commits
- 1.24.0 @2014.4.14 7041commits
- 1.23
- 0.20.0 @2011.1.6 5239commits


```bash
./autogen.sh 
# 
# -lxcb-render -lxcb-shm
export TARGETPATH=/usr/local/static/geany
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
# -lmenu-cache 
ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
# -lXdamage注释也会用到;
# -lfm -lfm-gtk 
ex1="-lfontconfig -lgio-2.0 -lcairo    -lXdamage "
LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1 -lxcb-render -lxcb-shm"

# LIBS="$LIBS0" ./configure --prefix=$TARGETPATH
LIBS="$LIBS0" ./configure --prefix=$TARGETPATH \
  --disable-html-docs \
  --disable-pdf-docs \
  --disable-api-docs
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1


# bash-5.1# git checkout 1.27.0
# 一样; dyn: xcb_xx错误; static: src_错误;

# bash-5.1# git checkout 0.20.0
/usr/include/glib-2.0/glib/glib-autocleanups.h:48:1: error: use of undeclared identifier 'unused'


# bash-5.1# git checkout 1.24.0
# make clean
# bash-5.1# ./autogen.sh 
# make
gtk/ScintillaGTK.cxx:1558:33: error: ordered comparison between pointer and zero ('GdkAtom' (aka '_GdkAtom *') and 'int')
                if (TypeOfGSD(selection_data) > 0) {
6 warnings and 1 error generated.
make[3]: *** [Makefile:958: gtk/ScintillaGTK.o] Error 1
make[3]: Leaving directory '/mnt2/_misc2/geany/scintilla'
make[2]: *** [Makefile:994: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/_misc2/geany/scintilla'
make[1]: *** [Makefile:587: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/geany'
make: *** [Makefile:473: all] Error 2

# bash-5.1# git checkout 1.23.0
# make clean
# bash-5.1# ./autogen.sh 
# make
gtk/ScintillaGTK.cxx:1619:33: error: ordered comparison between pointer and zero ('GdkAtom' (aka '_GdkAtom *') and 'int')
                if (TypeOfGSD(selection_data) > 0) { #与1.24.0一样错;

```
