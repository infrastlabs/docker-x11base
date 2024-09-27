
# tint2

- try1, err `Imlib is not built with X support`
- try2 **dyn ok; static** `dynOK:apk add imlib2-dev; static: cmake_static编译URL`
- try3 @23.12.21
  - try3.1 deps; librsvg-2.40.21, ibcroco-0.6.13.tar.xz
  - try3.2 **target_link_libraries** `target_link_libraries( tint2 ${X11_LIBRARIES} ##手动追加`
  - try3.3 ldd-tint2 `更新deps后,只余xcb-util; 源码补装后> err:static link of dynamic object`
  - try3.4 **cmake-static-deps** (`CMAKE_EXE_LINKER_FLAGS> 清理'-rdynamic'>> imlib2 err again`)
- try4 `rm -rf ./build/*`后，imlib2错（tmux19新容器构建）
  - try41.a: 找到新缺deps `动态库依赖(apk add xx-dev)>> cmake过>> make:ld未过(isvg改用1.40.xx:缺-lcroco-0.6; tint2:缺-lxcb-util -lcroco-0.6 -lrsvg-2)`
  - try41.b: 补deps `补充static-deps后:static link of dynamic object; > 清理../build/*; >> imlib2 -x11检测失败(三次复现); > 细看imlib2的配置||try:改xx-clang>> 待测(未设置?)`
  - 
  - try42a: **手动注释imlib2-x检查** `清./build后二次安装imlib2-dev(cmake过了)>>装xxx-dev|静编:xxx>> cmake还复现,手动注释imlib2-x的检查` 
  - try42b: **link of dynamic obj问题** `v-xlunch/build.sh imlib2>> gtk:@b_deps>> >>依旧static link of dynamic obj(试着移走so)`
  - try42c: **strnappend改方法名**, tint2过了: `重名方法改名:multiple definition of 'strnappend'; >> tint2过了`; tint2conf err(转下份文档)

## try1, err `Imlib is not built with X support`

```bash
# -- Checking for modules 'x11;xcomposite;xdamage;xinerama;xext;xrender;xrandr>=1.3'
bash-5.1# apk add xcomposite-dev
bash-5.1# apk add pango-dev
apk add librsvg-dev
apk add startup-notification-dev #startup-notification
bash-5.1# apk add gtk+2.0-dev

# IMLIB2_URL=https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
bash /src/v-xlunch/build.sh imlib2
# bash-5.1# cmake ..
-- Checking for module 'imlib2>=1.4.2'
--   Found imlib2, version 1.7.
-- Checking for module 'libstartup-notification-1.0>=0.12' ##
--   Package 'libstartup-notification-1.0', required by 'virtual:world', not found
notification

# ref openbox: --disable-startup-notification \
# apk add startup-notification startup-notification-dev
-- Checking for module 'libstartup-notification-1.0>=0.12'
--   Found libstartup-notification-1.0, version 0.12
CMake Error at CMakeLists.txt:94 (message):
  Imlib is not built with X support  ##



##################
# Optional Features:
  --disable-option-checking  ignore unrecognized --enable/--with options
  --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
  --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
  --enable-silent-rules   less verbose build output (undo: "make V=1")
  --disable-silent-rules  verbose build output (undo: "make V=0")
  --enable-dependency-tracking
                          do not reject slow dependency extractors
  --disable-dependency-tracking
                          speeds up one-time build
  --enable-shared[=PKGS]  build shared libraries [default=yes]
  --enable-static[=PKGS]  build static libraries [default=yes]
  --enable-fast-install[=PKGS]
                          optimize for fast installation [default=yes]
  --disable-libtool-lock  avoid locking (might break parallel builds)
  --enable-mmx            attempt compiling using x86 mmx assembly
                          [default=auto]
  --enable-amd64          attempt compiling using amd64 assembly
                          [default=auto]
  --enable-werror         treat compiler warnings as errors [default=no]
  --enable-visibility-hiding
                          enable visibility hiding [default=yes]
  --enable-gcc-asan       compile with ASAN support [default=no]

# Optional Packages:
  --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
  --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
  --with-pic[=PKGS]       try to use only PIC/non-PIC objects [default=use
                          both]
  --with-aix-soname=aix|svr4|both
                          shared library versioning (aka "SONAME") variant to
                          provide on AIX, [default=aix].
  --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
  --with-sysroot[=DIR]    Search for dependent libraries within DIR (or the
                          compiler\'s sysroot if not specified).
  --with-x                use the X Window System
  --without-x-shm-fd      Disable X11 MIT-SHM FD-passing support
  --without-jpeg          Disable JPEG image loader
  --without-png           Disable PNG image loader
  --without-webp          Disable WEBP image loader
  --without-tiff          Disable TIFF image loader
  --without-gif           Disable GIF image loader
  --without-zlib          Disable ZLIB loader
  --without-bzip2         Disable BZIP2 loader
  --without-id3           Disable ID3 loader


# Optional
--disable-option-checking
--disable-silent-rules
--disable-dependency-tracking
--disable-libtool-lock
--enable-static[=PKGS]
--enable-shared[=PKGS]
--enable-fast-install[=PKGS]
--enable-mmx
--enable-amd64
--enable-werror
--enable-visibility-hiding
--enable-gcc-asan
# Optional
--with-PACKAGE[=ARG]
--with-pic[=PKGS]
--with-sysroot[=DIR]
--with-aix-soname=aix|svr4|both
--with-gnu-ld
--with-x
--without-x-shm-fd
--without-jpeg
--without-png
--without-webp
--without-tiff
--without-gif
--without-zlib
--without-bzip2
--without-id3

# imlib2: hand re-build
# deps
  OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
  # -lmenu-cache 
  ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
  # -lXdamage注释也会用到;
  # -lfm -lfm-gtk 
  ex1="-lfontconfig -lgio-2.0 -lcairo    -lXdamage "
  LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

LIBS="$LIBS0" #./configure --prefix=$TARGETPATH
make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

cd /tmp/imlib2
  # export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
  LIBS="$LIBS0" ./configure --with-x ; 

# make
LIBS="$LIBS0" make #/usr/local/lib/imlib2/filters/bumpmap.a

# dyn deps
bash-5.1# find /usr/lib |grep imlib
bash-5.1# apk list |grep imlib
imlib2-1.7.4-r0 x86_64 {imlib2} (Imlib2)
imlib2-dev-1.7.4-r0 x86_64 {imlib2} (Imlib2)
bash-5.1# apk add imlib2-dev
(1/4) Installing giflib (5.2.1-r0)
(2/4) Installing libid3tag (0.15.1b-r8)
(3/4) Installing imlib2 (1.7.4-r0)
(4/4) Installing imlib2-dev (1.7.4-r0)
Executing busybox-1.34.1-r7.trigger
OK: 953 MiB in 336 packages
bash-5.1# find /usr/lib |grep imlib
/usr/lib/imlib2
/usr/lib/imlib2/filters
/usr/lib/imlib2/filters/bumpmap.so

  216  cmake ..
  217  pwd
  218  find
  219  ls
  220  rm -rf *
  221  cmake ..
  222  apk list |grep imlib
  223  apk add imlib2
  224  \cp -a /usr/local/lib/imlib2/ /usr/lib/ ##拷贝静态库
  225  cmake ..
# 错误依旧: Imlib is not built with X support

```

## try2 **dyn ok; static** `dynOK:apk add imlib2-dev; static: cmake_static编译URL`

```bash
# 23.12.14
# -- Checking for modules 'x11;xcomposite;xdamage;xinerama;xext;xrender;xrandr>=1.3'
# bash-5.1# apk add xcomposite-dev #none
      bash /src/xcompmgr/build.sh Xdamage; 
      bash /src/xcompmgr/build.sh xcompmgr;
bash-5.1# apk add pango-dev
# --   Package 'imlib2', required by 'virtual:world', not found
bash-5.1# apk add imlib2-dev

# 
apk add librsvg-dev
apk add startup-notification-dev #startup-notification
apk add gtk+2.0-dev
# imlib2 @/usr/local/lib; cmake检查通过(Imlib is not built with X support)

bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
# bash-5.1# cmake ..
-- Checking for module 'imlib2'
--   Found imlib2, version 1.7.4
-- Checking for module 'gtk+-x11-2.0'
--   Found gtk+-x11-2.0, version 2.24.33
-- Checking for module 'librsvg-2.0>=2.36.0'
--   Found librsvg-2.0, version 2.50.7
-- Found Gettext: /usr/bin/msgmerge (found version "0.21") 
-- gettext found languages: bs es fr hr pl ru sr 
-- Configuring done
-- Generating done
-- Build files have been written to: /mnt2/_misc2-2/tint2/build

# bash-5.1# make
[ 95%] Built target pofiles_1
[ 97%] Generating hr.gmo
[ 97%] Built target pofiles_4
[ 98%] Generating pl.gmo
[ 98%] Built target pofiles_5
[100%] Generating sr.gmo
[100%] Built target pofiles_7
bash-5.1# ls
CMakeCache.txt       Makefile             src                  tint2
CMakeFiles           cmake_install.cmake  themes               version.h
bash-5.1# ls -lh ./tint2 
-rwxr-xr-x    1 root     root      487.8K Dec 14 05:36 ./tint2


# STATIC
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++
make clean
make
bash-5.1# ls -lh tint2 
-rwxr-xr-x    1 root     root      487.8K Dec 14 05:40 tint2

# make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1
make LDFLAGS="-static " #还动态编译的


# STATIC @cmake
# https://gitlab.com/o9000/tint2/-/wikis/Development
#   cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON ..
# https://gitlab.com/o9000/tint2/-/wikis/Install
bash-5.1# cmake -L
CMake Warning:
  No source or binary directory provided.  Both will be assumed to be the
  same as the current working directory, but note that this warning will
  become a fatal error in future CMake releases.
CMake Error: The source directory "/mnt2/_misc2-2/tint2/build" does not appear to contain CMakeLists.txt.
Specify --help for usage, or press the help button on the CMake GUI.
-- Cache values
CMAKE_BUILD_TYPE:STRING=
CMAKE_INSTALL_PREFIX:PATH=/usr/local
ENABLE_ASAN:BOOL=OFF
ENABLE_BACKTRACE:BOOL=OFF
ENABLE_BACKTRACE_ON_SIGNAL:BOOL=OFF
ENABLE_BATTERY:BOOL=ON
ENABLE_EXTRA_THEMES:BOOL=ON
ENABLE_RSVG:BOOL=ON
ENABLE_SN:BOOL=ON
ENABLE_TINT2CONF:BOOL=ON
ENABLE_TRACING:BOOL=OFF
ENABLE_UEVENT:BOOL=ON
GETTEXT_MSGFMT_EXECUTABLE:FILEPATH=/usr/bin/msgfmt
GETTEXT_MSGMERGE_EXECUTABLE:FILEPATH=/usr/bin/msgmerge
RT_LIBRARY:FILEPATH=/usr/lib/librt.a


# TODO 改CMakeLists.txt (share> static)
# https://blog.csdn.net/weixin_45004203/article/details/125256367 #CMake 常用总结二：CMake 生成静态库与动态库
# https://blog.csdn.net/whatday/article/details/118071243 #cmake 静态编译 简介
#   set(CMAKE_EXE_LINKER_FLAGS "-static")

# bash-5.1# cat ../CMakeLists.txt |grep LINK
set_target_properties( tint2 PROPERTIES LINK_FLAGS "-static -pthread -fno-strict-aliasing ${ASAN_L_FLAGS} ${BACKTRACE_L_FLAGS}  ${TRACING_L_FLAGS}" )
# bash-5.1# make clean
# bash-5.1# make
[ 59%] Building C object CMakeFiles/tint2.dir/src/battery/linux.c.o
[ 60%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXdamage
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXrandr
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lpangocairo-1.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lpango-1.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgobject-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lharfbuzz
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcairo
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lpango-1.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgobject-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lharfbuzz
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcairo
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgobject-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lrsvg-2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgio-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgdk_pixbuf-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lgobject-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lglib-2.0
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcairo
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2


```

## try3 @23.12.21

- try3.1 `deps; librsvg-2.40.21, ibcroco-0.6.13.tar.xz`

```bash
# 23.12.21

# ld: cannot find -lpango-1.0
# ld: cannot find -lpangocairo-1.0
# ld: cannot find -lcairo
# ld: cannot find -lXrandr
# ld: cannot find -lXdamage
# ld: cannot find -lharfbuzz
# 
# ld: cannot find -lrsvg-2
# ld: cannot find -lgio-2.0
# ld: cannot find -lgdk_pixbuf-2.0
# ld: cannot find -lglib-2.0
# ld: cannot find -lgobject-2.0
# ref: pcman-fm's b_deps
# v-tint2/build.sh b_deps <Pango, Xrandr, Xdamage, atk, gtk>

# cannot find -lrsvg-2
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# make
[ 43%] Building C object CMakeFiles/tint2.dir/src/battery/linux.c.o
[ 44%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lrsvg-2
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2



# librsvg-2.50.7-r1 @alpine315
# librsvg-2.5.0.tar.gz @sourceforge
# https://sourceforge.net/projects/librsvg/files/librsvg/2.5.0/librsvg-2.5.0.tar.gz
# https://sourceforge.net/projects/librsvg/files/librsvg/2.5.0/
# bash-5.1# apk list -I |grep librsvg
librsvg-2.50.7-r1 x86_64 {librsvg} (LGPL-2.1-or-later) [installed]
librsvg-dev-2.50.7-r1 x86_64 {librsvg} (LGPL-2.1-or-later) [installed]

# bash-5.1# pwd
/mnt2/_deps/librsvg-2.5.0
bash-5.1# ./configure
checking for native Win32... no
# checking for    gdk-pixbuf-2.0 >= 1.3.7         glib-2.0 >= 2.0.0       libart-2.0 >= 2.3.10    libxml-2.0 >= 2.4.7     pangoft2 >= 1.2.0... 
Package libart-2.0 was not found in the pkg-config search path. 
Perhaps you should add the directory containing 'libart-2.0.pc' to the PKG_CONFIG_PATH environment variable Package 'libart-2.0', required by 'virtual:world', not found
configure: error: Library requirements (        gdk-pixbuf-2.0 >= 1.3.7         glib-2.0 >= 2.0.0       libart-2.0 >= 2.3.10    libxml-2.0 >= 2.4.7    pangoft2 >= 1.2.0) not met; consider adjusting the PKG_CONFIG_PATH environment variable if your libraries are in a nonstandard prefix so pkg-config can find them.
bash-5.1# echo $?
1

# libart-2.0
bash-5.1# git clone https://hub.yzuu.cf/Distrotech/libart #Mirror of git://git.gnome.org/libart_lgpl 
bash-5.1# git checkout LIBART_LGPL_2_3_21
bash-5.1# ./autogen.sh 
You need to install gnome-common from the GNOME CVS


# [librsvg]
# https://github.com/GNOME/librsvg #9298commits [rust 83.6%]
# https://github.com/GNOME/librsvg/tree/2.50.7 #6499commits
# https://github.com/GNOME/librsvg/tree/2.41.0/ #1845commits @2017.1.4 ./rust/Cargo.toml
# https://github.com/GNOME/librsvg/tree/2.40.21 #1718commits @2020.2.27
# https://github.com/GNOME/librsvg/tree/2.40.17 #1598commits @2017.4.8
# https://github.com/GNOME/librsvg/tree/2.35.0 #1258commits @2011.11.15
# https://github.com/loic/librsvg/tree/LIBRSVG_2_31_0 #1149commits
bash-5.1# git clone https://hub.yzuu.cf/GNOME/librsvg
bash-5.1# #git checkout 2.50.7
bash-5.1# ./autogen.sh 
checking for dlopen... yes
checking for cargo... no
configure: error: cargo is required.  Please install the Rust toolchain from https://www.rust-lang.org/

bash-5.1# #git checkout 2.40.17
bash-5.1# ./autogen.sh 
checking for native Win32... no
checking for LIBRSVG... no
configure: error: Package requirements (        gdk-pixbuf-2.0 >= 2.20  glib-2.0 >= 2.12.0      gio-2.0 >= 2.24.0       libxml-2.0 >= 2.7.0     pangocairo >= 1.32.6    cairo >= 1.2.0  cairo-png >= 1.2.0
        libcroco-0.6 >= 0.6.1) were not met:
Package 'libcroco-0.6', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.
Alternatively, you may set the environment variables LIBRSVG_CFLAGS
and LIBRSVG_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

# bash-5.1# git checkout 2.40.21
Package 'libcroco-0.6', required by 'virtual:world', not found
Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables LIBRSVG_CFLAGS
and LIBRSVG_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

# libcroco
https://github.com/OpenMandrivaAssociation/libcroco0.6/blob/master/libcroco0.6.spec #ref url @gnome
https://mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz
  173  cd libcroco-0.6.13
  174  ls
  175  ./autogen.sh 
  176  echo $?
  178  ./configure
  179  make 
  182  find |grep croco
  #183  ./configure -h
  184  ./configure --enable-static
  185  make
  186  find |grep croco
  187  cp ./src/.libs/libcroco-0.6.a /usr/lib/
bash-5.1# make install

bash-5.1# cd ../librsvg
bash-5.1# #./autogen.sh 
config.status: executing depfiles commands
config.status: executing libtool commands
librsvg-2.40.21
        prefix:                         /usr/local
        compiler:                       gcc
        Build introspectable bindings:  yes
        Build Vala bindings:            no
        Build GdkPixbuf loader:         yes
        GTK+ 3.10.0 or later:           no
        Build miscellaneous tools:      yes
bash-5.1# echo $?
0

  197  ./autogen.sh 
  198  echo $?
  199  #./autogen.sh 
  203  ./configure -h
  204  ./configure --enable-static
  205  make 
  206  make install
  207  find |grep librsvg-
bash-5.1# find |grep librsvg-
./.libs/librsvg-2.a



# [o9000/tint2] v16.1
# https://gitlab.com/o9000/tint2/-/wikis/Install #v0.12.2
# https://gitlab.com/o9000/tint2/-/wikis/Install#dependencies
sudo apt-get install libcairo2-dev libpango1.0-dev 
# libglib2.0-dev libimlib2-dev libgtk-3-dev libxinerama-dev libx11-dev 
libxdamage-dev libxcomposite-dev libxrender-dev libxrandr-dev librsvg2-dev libstartup-notification0-dev

https://github.com/o9000/tint2 #1678commits @19.6.3
https://github.com/o9000/tint2/tree/v16.1 #1594commits @17.12.30
https://github.com/o9000/tint2/tree/v0.12.2 #771commits @15.8.11


bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# make
sn-xmessages.c:(.text+0x43b): undefined reference to 'xcb_generate_id'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: sn-xmessages.c:(.text+0x473): undefined reference to 'xcb_create_window'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: sn-xmessages.c:(.text+0x4d8): undefined reference to 'xcb_send_event'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: sn-xmessages.c:(.text+0x4ea): undefined reference to 'xcb_destroy_window'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: sn-xmessages.c:(.text+0x4f2): undefined reference to 'xcb_flush'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
bash-5.1# 

# 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

bash-5.1# make  2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
      466       466     29490


# ref: pcmanfm
	OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
  ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite" #-lmenu-cache 
  # -lXdamage注释也会用到;
  ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd -lcroco-0.6 -lImlib2" # -lfm -lfm-gtk 
  LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1" 

	make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 ##

bash-5.1# make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
      466       466     29490

# +
# -lxcb-shm 
```

- try3.2 **target_link_libraries** `target_link_libraries( tint2 ${X11_LIBRARIES} ##手动追加`

```bash
# 
LIBS="-lXinerama -lXfixes -lXrandr $LIBS0"
echo $LIBS |sed "s/-l//g"
# Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage
Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2

# bash-5.1# cat ../CMakeLists.txt |grep link_libraries -n
263:target_link_libraries( tint2 ${X11_LIBRARIES} ##手动追加

# bash-5.1# cmake ..
CMake Deprecation Warning at CMakeLists.txt:2 (cmake_minimum_required):
  Compatibility with CMake < 2.8.12 will be removed from a future version of
  CMake.
  Update the VERSION argument <min> value or use a ...<max> suffix to tell
  CMake that the project does not need compatibility with older versions.
-- Checking for module 'imlib2>=1.4.2'
--   Found imlib2, version 1.7.4
-- Checking for module 'librsvg-2.0>=2.14.0'
--   Found librsvg-2.0, version 2.40.21
CMake Deprecation Warning at src/tint2conf/CMakeLists.txt:2 (cmake_minimum_required):
  Compatibility with CMake < 2.8.12 will be removed from a future version of
  CMake.

  Update the VERSION argument <min> value or use a ...<max> suffix to tell
  CMake that the project does not need compatibility with older versions.
-- Checking for module 'imlib2'
--   Found imlib2, version 1.7.4
-- Checking for module 'librsvg-2.0>=2.36.0' ###
--   Found librsvg-2.0, version 2.40.21
-- gettext found languages: bs es fr hr pl ru sr 
-- Configuring done
-- Generating done
-- Build files have been written to: /mnt2/_misc2-2/tint2/build
bash-5.1# echo $?
0

# make
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /mnt2/_deps/librsvg/rsvg-styles.c:1198: undefined reference to 'cr_parser_destroy'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /mnt2/_deps/librsvg/rsvg-styles.c:1188: undefined reference to 'cr_doc_handler_unref'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/librsvg-2.a(librsvg_2_la-rsvg-styles.o): in function 'ccss_import_style':
/mnt2/_deps/librsvg/rsvg-styles.c:1215: undefined reference to 'cr_string_peek_raw_str'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libstartup-notification-1.a(sn-common.o): in function `sn_xcb_display_new':
sn-common.c:(.text+0xf0): undefined reference to 'xcb_aux_get_screen'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libstartup-notification-1.a(sn-common.o): in function `sn_display_new':
sn-common.c:(.text+0x1a0): undefined reference to 'XGetXCBConnection'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
bash-5.1# 
# bash-5.1# make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
       20        20       946

# bash-5.1# make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u 
/mnt2/_deps/imlib2-1.7.4/src/lib/ximage.c:137:
/mnt2/_deps/imlib2-1.7.4/src/lib/ximage.c:138:
/mnt2/_deps/imlib2-1.7.4/src/lib/ximage.c:144:
/mnt2/_deps/imlib2-1.7.4/src/lib/ximage.c:155:
/mnt2/_deps/librsvg/rsvg-styles.c:1108:
/mnt2/_deps/librsvg/rsvg-styles.c:1109:
/mnt2/_deps/librsvg/rsvg-styles.c:1111:
/mnt2/_deps/librsvg/rsvg-styles.c:1186:
/mnt2/_deps/librsvg/rsvg-styles.c:1188:
/mnt2/_deps/librsvg/rsvg-styles.c:1192:
/mnt2/_deps/librsvg/rsvg-styles.c:1193:
/mnt2/_deps/librsvg/rsvg-styles.c:1195:
/mnt2/_deps/librsvg/rsvg-styles.c:1196:
/mnt2/_deps/librsvg/rsvg-styles.c:1198:
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libmount.a(libcommon_la-strutils.o):
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libstartup-notification-1.a(sn-common.o):
/usr/local/lib/libImlib2.a(ximage.o):
/usr/local/lib/librsvg-2.a(librsvg_2_la-rsvg-css.o):
/usr/local/lib/librsvg-2.a(librsvg_2_la-rsvg-styles.o):
attempted
bash-5.1#

# /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: attempted static link of dynamic object '/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libuuid.so' ##新加的一堆..全指向so库; 如libxml2:
# bash-5.1# find /usr/lib |grep libxml
/usr/lib/libxml2.so
/usr/lib/libxml2.a


# https://blog.csdn.net/weixin_43376501/article/details/129792853 #使用find_library，find_path如何设置只寻找静态库而不是动态库
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
cmake ..
make #一样
make clean
make #还是之前static with 动态库提示


```

- try3.3 ldd-tint2 `更新deps后,只余xcb-util; 源码补装后> err:static link of dynamic object`

```bash
# root@tenvm2:/mnt/_misc2-2/tint2/build# cat ldd-links.txt 
	/lib/ld-musl-x86_64.so.1 (0x7f4a35576000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f4a35576000)
	libImlib2.so.1 => /usr/local/lib/libImlib2.so.1 (0x7f4a35097000) ##
	libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7f4a34b0c000) ##
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f4a353bb000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f4a3490c000)
	libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7f4a35502000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f4a34904000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f4a354ea000)
	libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7f4a354fd000)
	libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f4a353af000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f4a354de000)
	libblkid.so.1 => /lib/libblkid.so.1 (0x7f4a347c7000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f4a347a4000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f4a34847000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f4a34811000) ##
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f4a34854000)
  # 
	libcairo.so.2 => /usr/lib/libcairo.so.2 (0x7f4a35111000)
	libcroco-0.6.so.3 => /usr/local/lib/libcroco-0.6.so.3 (0x7f4a34acf000) ##
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f4a348df000)
	libffi.so.8 => /usr/lib/libffi.so.8 (0x7f4a34d28000)
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f4a34fad000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f4a34b70000)
	libfribidi.so.0 => /usr/lib/libfribidi.so.0 (0x7f4a34dde000)
	libgdk_pixbuf-2.0.so.0 => /usr/local/lib/libgdk_pixbuf-2.0.so.0 (0x7f4a35032000)
	libgio-2.0.so.0 => /usr/lib/libgio-2.0.so.0 (0x7f4a34dfd000)
	libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7f4a35201000)
	libgmodule-2.0.so.0 => /usr/lib/libgmodule-2.0.so.0 (0x7f4a349a0000)
	libgobject-2.0.so.0 => /usr/lib/libgobject-2.0.so.0 (0x7f4a3530c000)
	libgraphite2.so.3 => /usr/lib/libgraphite2.so.3 (0x7f4a34863000)
	libharfbuzz.so.0 => /usr/lib/libharfbuzz.so.0 (0x7f4a34d35000)
	libintl.so.8 => /usr/lib/libintl.so.8 (0x7f4a34cbf000)
	libjpeg.so.8 => /usr/lib/libjpeg.so.8 (0x7f4a34919000)
	liblzma.so.5 => /usr/lib/liblzma.so.5 (0x7f4a34824000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f4a34798000) ##
	libmount.so.1 => /lib/libmount.so.1 (0x7f4a34883000)
  # 
	libpango-1.0.so.0 => /usr/lib/libpango-1.0.so.0 (0x7f4a35359000)
	libpangocairo-1.0.so.0 => /usr/lib/libpangocairo-1.0.so.0 (0x7f4a3539f000)
	libpangoft2-1.0.so.0 => /usr/lib/libpangoft2-1.0.so.0 (0x7f4a34fea000)
	libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7f4a34ccc000)
	libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7f4a34c29000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f4a34b3f000)
	librsvg-2.so.2 => /usr/local/lib/librsvg-2.so.2 (0x7f4a3505c000)
	libstartup-notification-1.so.0 => /usr/lib/libstartup-notification-1.so.0 (0x7f4a35028000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f4a348d6000)
	libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f4a34b3a000)
	libxcb-render.so.0 => /usr/lib/libxcb-render.so.0 (0x7f4a34b2b000) ##
	libxcb-util.so.1 => /usr/lib/libxcb-util.so.1 (0x7f4a34911000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f4a35001000)
	libxml2.so.2 => /usr/lib/libxml2.so.2 (0x7f4a349a5000)
	libz.so.1 => /lib/libz.so.1 (0x7f4a34b11000)
# bash-5.1# ldd usr-local-static/tint2 2>&1 |wc
      120       835      9833

# bash-5.1# find /usr/lib /usr/local/lib |grep libstartup-notification
/usr/lib/libstartup-notification-1.so
/usr/lib/libstartup-notification-1.a

# 更新deps后, cmake ..; make:
[ 57%] Building C object CMakeFiles/tint2.dir/src/battery/battery.c.o
[ 59%] Building C object CMakeFiles/tint2.dir/src/battery/linux.c.o
[ 60%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libmount.a(libcommon_la-strutils.o): in function 'strnappend':
strutils.c:(.text+0x1542): multiple definition of 'strnappend'; CMakeFiles/tint2.dir/src/battery/battery.c.o:battery.c:(.text+0x332): first defined here
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lxcb-util
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
# bash-5.1# find /usr/lib |grep xcb-util
/usr/lib/pkgconfig/xcb-util.pc
/usr/lib/libxcb-util.so.1
/usr/lib/libxcb-util.so
/usr/lib/libxcb-util.so.1.0.0

# bash-5.1# apk list |grep xcb-util
xcb-util-0.4.0-r3 x86_64 {xcb-util} (MIT) [installed]
xcb-util-dev-0.4.0-r3 x86_64 {xcb-util} (MIT) [installed]



# [xcb-util]
 1521  2023-12-21 20:45:16 git clone https://hub.yzuu.cf/freedesktop-unofficial-mirror/xcb__util
 1522  2023-12-21 20:45:26 cd xcb__util/
 1523  2023-12-21 20:45:27 ls
 1524  2023-12-21 20:45:30 ./autogen.sh 
 1525  2023-12-21 20:45:47 git submodule update --init
 1526  2023-12-21 20:45:58 ./autogen.sh 
 1527  2023-12-21 20:46:30 apk add xorg-macros
 1528  2023-12-21 20:46:51 docker ps
 1529  2023-12-21 20:46:57 docker exec -it ac bash


  211  cd /mnt2/_deps/xcb__util/
  212  ls
  213  ./autogen.sh 
  214  echo $?
  215  make
  216  find |grep libxcb-util
bash-5.1# find |grep libxcb-util
./src/.libs/libxcb-util.a
./src/.libs/libxcb-util.so


# static link of dynamic object
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# make
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: attempted static link of dynamic object '/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libstartup-notification-1.so'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: attempted static link of dynamic object '/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libc.so'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
```

- try3.4 **cmake-static-deps** (`CMAKE_EXE_LINKER_FLAGS> 清理'-rdynamic'>> imlib2 err again`)

```bash
# bash-5.1# env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=-static -Wl,--strip-all -Wl,--as-needed
CPPFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer
bash-5.1# 
[14] 0:docker* ####


bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
# bash-5.1# find |grep Makefi |while read one; do echo $one; cat $one |grep FLAGS; done |sort
./CMakeFiles/Makefile.cmake
./CMakeFiles/Makefile2
./Makefile
./src/tint2conf/Makefile
./src/tint2conf/po/Makefile
./themes/Makefile


# https://www.codenong.com/40618443/ #关于linux：使用CMAKE编译静态可执行文件
SET(CMAKE_FIND_LIBRARY_SUFFIXES".a")
SET(BUILD_SHARED_LIBRARIES OFF)
SET(CMAKE_EXE_LINKER_FLAGS "-static")

将其添加到find命令上方的CMakeLists.txt中：
set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
提醒您清除cmake缓存，以使其不会挂在libGLU.so上。


# bash-5.1# cmake -h
  -Wdev                        = Enable developer warnings.
  -Wno-dev                     = Suppress developer warnings.
  -Werror=dev                  = Make developer warnings errors.
  -Wno-error=dev               = Make developer warnings not errors.
  -Wdeprecated                 = Enable deprecation warnings.
  -Wno-deprecated              = Suppress deprecation warnings.
  -Werror=deprecated           = Make deprecated macro and function warnings
                                 errors.
  -Wno-error=deprecated        = Make deprecated macro and function warnings
                                 not errors.
  --preset <preset>,--preset=<preset>
                               = Specify a configure preset.
  --list-presets               = List available presets.
  -E                           = CMake command mode.
  -L[A][H]                     = List non-advanced cached variables.
  --build <dir>                = Build a CMake-generated project binary tree.
  --install <dir>              = Install a CMake-generated project binary
                                 tree.
  --open <dir>                 = Open generated project in the associated
                                 application.
  -N                           = View mode only.
  -P <file>                    = Process script mode.
  --find-package               = Legacy pkg-config like mode.  Do not use.
  --graphviz=[file]            = Generate graphviz of dependencies, see
                                 CMakeGraphVizOptions.cmake for more.
  --system-information [file]  = Dump information about this system.
  --log-level=<ERROR|WARNING|NOTICE|STATUS|VERBOSE|DEBUG|TRACE>
                               = Set the verbosity of messages from CMake
                                 files.  --loglevel is also accepted for
                                 backward compatibility reasons.
  --log-context                = Prepend log messages with context, if given
  --debug-trycompile           = Do not delete the try_compile build tree.
                                 Only useful on one try_compile at a time.
  --debug-output               = Put cmake in a debug mode.
  --debug-find                 = Put cmake find in a debug mode.
  --trace                      = Put cmake in trace mode.
  --trace-expand               = Put cmake in trace mode with variable
                                 expansion.
  --trace-format=<human|json-v1>


# bash-5.1# cat ../CMakeLists.txt |grep rdynamic -n
47:             set(BACKTRACE_L_FLAGS "-rdynamic")
54:                     set(BACKTRACE_L_FLAGS "-rdynamic")
239:  SET(ASAN_C_FLAGS " -O0 -g3 -fsanitize=address -fno-common -fno-omit-frame-pointer -rdynamic -Wshadow")
240:  SET(ASAN_L_FLAGS " -O0 -g3 -fsanitize=address -fno-common -fno-omit-frame-pointer -rdynamic -fuse-ld=gold ")
248:  SET(TRACING_C_FLAGS " -finstrument-functions -finstrument-functions-exclude-file-list=tracing.c -finstrument-functions-exclude-function-list=get_time,gettime -O0 -g3 -fno-common -fno-omit-frame-pointer -rdynamic")
249:  SET(TRACING_L_FLAGS " -O0 -g3 -fno-common -fno-omit-frame-pointer -rdynamic")
# 清理如上6个 -rdynamic: 还是依旧;



# 提醒您清除cmake缓存，以使其不会挂在libGLU.so上
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# rm -rf *
bash-5.1# #cmake ..; make clean
-- Checking for module 'libstartup-notification-1.0>=0.12'
--   Found libstartup-notification-1.0, version 0.12
-- Looking for imlib_context_set_display in Imlib2
-- Looking for imlib_context_set_display in Imlib2 - not found
CMake Error at CMakeLists.txt:98 (message):
  Imlib is not built with X support  ##复现问题;
-- Configuring incomplete, errors occurred!
See also "/mnt2/_misc2-2/tint2/build/CMakeFiles/CMakeOutput.log".
See also "/mnt2/_misc2-2/tint2/build/CMakeFiles/CMakeError.log".
make: *** No rule to make target 'clean'.  Stop.


# bash-5.1# find /usr/lib /usr/local/lib |grep imlib2
/usr/local/lib/imlib2
/usr/local/lib/imlib2/filters
/usr/local/lib/imlib2/filters/bumpmap.so
/usr/local/lib/imlib2/filters/colormod.so
/usr/local/lib/imlib2/filters/colormod.la
/usr/local/lib/imlib2/filters/testfilter.so
/usr/local/lib/imlib2/filters/testfilter.la
/usr/local/lib/imlib2/filters/bumpmap.la
/usr/local/lib/imlib2/loaders
/usr/local/lib/imlib2/loaders/zlib.so
...
/usr/local/lib/imlib2/loaders/tga.la
/usr/local/lib/imlib2/loaders/ico.la
/usr/local/lib/pkgconfig/imlib2.pc
# bash-5.1# find /usr/lib /usr/local/lib |grep imlib2 |grep "\.a$"

# bash /src/v-xlunch/build.sh imlib2
# bash-5.1# find /usr/lib /usr/local/lib |grep imlib2 |grep "\.a$"
/usr/local/lib/imlib2/filters/colormod.a
/usr/local/lib/imlib2/filters/testfilter.a
/usr/local/lib/imlib2/filters/bumpmap.a
/usr/local/lib/imlib2/loaders/argb.a
/usr/local/lib/imlib2/loaders/jpeg.a
/usr/local/lib/imlib2/loaders/zlib.a
/usr/local/lib/imlib2/loaders/ico.a
/usr/local/lib/imlib2/loaders/pnm.a
/usr/local/lib/imlib2/loaders/tiff.a
/usr/local/lib/imlib2/loaders/png.a
/usr/local/lib/imlib2/loaders/tga.a
/usr/local/lib/imlib2/loaders/lbm.a
/usr/local/lib/imlib2/loaders/ff.a
/usr/local/lib/imlib2/loaders/xpm.a
/usr/local/lib/imlib2/loaders/webp.a
/usr/local/lib/imlib2/loaders/xbm.a
/usr/local/lib/imlib2/loaders/bmp.a
/usr/local/lib/imlib2/loaders/bz2.a



# bash-5.1# apk list |grep imlib2
imlib2-1.7.4-r0 x86_64 {imlib2} (Imlib2)
imlib2-dev-1.7.4-r0 x86_64 {imlib2} (Imlib2)
# bash-5.1# apk add imlib2-dev
(1/4) Installing giflib (5.2.1-r0)
(2/4) Installing libid3tag (0.15.1b-r8)
(3/4) Installing imlib2 (1.7.4-r0)
(4/4) Installing imlib2-dev (1.7.4-r0)
Executing busybox-1.34.1-r7.trigger
OK: 996 MiB in 375 packages
bash-5.1# 

# [/usr/lib]
# bash-5.1# find /usr/lib/imlib2/
/usr/lib/imlib2/
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
```

## try4 `rm -rf ./build/*`后，imlib2错（tmux19新容器构建）

- try41.a: 找到新缺deps `动态库依赖(apk add xx-dev)>> cmake过>> make:ld未过(isvg改用1.40.xx:缺-lcroco-0.6; tint2:缺-lxcb-util -lcroco-0.6 -lrsvg-2)`

```bash
# try41: 动态库依赖(apk add xx-dev)>> cmake过>> static构建ld未过
      ln -s /mnt2/docker-x11base/compile/src /src
      apk add git gawk

      # bash-5.1# apk add xcomposite-dev #none
            bash /src/xcompmgr/build.sh Xdamage; 
            bash /src/xcompmgr/build.sh xcompmgr;
      bash-5.1# apk add pango-dev
      # --   Package 'imlib2', required by 'virtual:world', not found
      bash-5.1# apk add imlib2-dev

      apk add librsvg-dev
      apk add startup-notification-dev #startup-notification
      apk add gtk+2.0-dev
      # imlib2 @/usr/local/lib; cmake检查通过(Imlib is not built with X support)
      # cmake ..; #通过




# isvg改用1.40.xx  ==> make 缺: -lcroco-0.6
[ 59%] Building C object CMakeFiles/tint2.dir/src/battery/linux.c.o
[ 60%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXrandr
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXrandr
....
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lxml2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcroco-0.6
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
bash-5.1# 


# tint2 make, ld缺: -lxcb-util -lcroco-0.6 -lrsvg-2
[ 44%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libmount.a(libcommon_la-strutils.o): in function 'strnappend':
strutils.c:(.text+0x1542): multiple definition of 'strnappend'; CMakeFiles/tint2.dir/src/battery/battery.c.o:battery.c:(.text+0x332): first defined here
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lxcb-util
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcroco-0.6
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lrsvg-2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcroco-0.6
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2
```

- try41.b: 补deps `补充static-deps后:static link of dynamic object; > 清理../build/*; >> imlib2 -x11检测失败(三次复现); > 细看imlib2的配置||try:改xx-clang>> 待测(未设置?)`

```bash
# 补充static-deps后>>  dynLink ERR;
#  错误依旧 static link of dynamic object
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# make
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: attempted static link of dynamic object '/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libstartup-notification-1.so'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: attempted static link of dynamic object '/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libc.so'
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2



# 清理../build/*; >> imlib2 -x11检测失败(三次复现); 

# [19] 0:docker*
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
# bash-5.1# cmake ..; make clean;
-- Checking for module 'librsvg-2.0>=2.14.0'
--   Found librsvg-2.0, version 2.40.21
-- Checking for module 'libstartup-notification-1.0>=0.12'
--   Found libstartup-notification-1.0, version 0.12
-- Looking for imlib_context_set_display in Imlib2
-- Looking for imlib_context_set_display in Imlib2 - not found
CMake Error at CMakeLists.txt:101 (message):
  Imlib is not built with X support ##错误三次复现
-- Configuring incomplete, errors occurred!
See also "/mnt2/_misc2-2/tint2/build/CMakeFiles/CMakeOutput.log".
See also "/mnt2/_misc2-2/tint2/build/CMakeFiles/CMakeError.log".
# bash-5.1# history |grep imlib
   15  find /usr/lib /usr/local/lib/ |grep imlib
   37  apk add imlib2-dev
   79  history |grep imlib
bash-5.1# 


####################################################
# 本地下载源码>> 细看imlib2的配置
# [imlib_context_set_display]
# bash /src/xcompmgr/build.sh Xdamage
bash /src/v-xlunch/build.sh imlib2


# [imlib2]
# bash-5.1# ./configure  -h
'configure' configures imlib2 1.7.4 to adapt to many kinds of systems.
X features:
  --x-includes=DIR    X include files are in DIR
  --x-libraries=DIR   X library files are in DIR

Optional Features:
  --enable-shared[=PKGS]  build shared libraries [default=yes]
  --enable-static[=PKGS]  build static libraries [default=yes]

Optional Packages:
  --with-x                use the X Window System
  --without-x-shm-fd      Disable X11 MIT-SHM FD-passing support
  --without-jpeg          Disable JPEG image loader
  --without-png           Disable PNG image loader
  --without-webp          Disable WEBP image loader
  --without-tiff          Disable TIFF image loader
  --without-gif           Disable GIF image loader
  --without-zlib          Disable ZLIB loader
  --without-bzip2         Disable BZIP2 loader
  --without-id3           Disable ID3 loader

# bash-5.1# ./configure  --with-x --x-includes=yes --x-libraries=yes
# https://github.com/fink/fink-distributions/blob/f3bb948e527b41ec1a465bdcb7952d301ee51967/10.4/stable/main/finkinfo/editors/texmacs.info#L11
# --x-includes=/usr/X11R6/include --x-libraries=/usr/X11R6/lib

# https://github.com/jameshilliard/openwrtubicom/blob/086a70c9d1b3d488d314242bbee0ebb6e84b5d0a/feeds_src/packages/Xorg/lib/imlib2/Makefile#L31
# bash-5.1# ./configure  --with-x --x-includes=/usr/include/X11 --x-libraries=/usr/lib/


# find-vscode: X_DISPLAY_MISSING @./Projects/_ee/_deps/imlib2-1.7.4
xserver-xorg-dev @ubt
apk add xorg-server-dev;


####################################################
# try:改xx-clang>> 待测(未设置?)
# https://blog.csdn.net/SHH_1064994894/article/details/129164636 ##CMake基础(9)使用Clang编译
set(CMAKE_C_COMPILER "clang")
set(CMAKE_CXX_COMPILER "clang++")
# xx-clang
set(CMAKE_C_COMPILER "xx-clang")
set(CMAKE_CXX_COMPILER "xx-clang++")
set(CMAKE_C_COMPILER "/usr/bin/xx-clang")
set(CMAKE_CXX_COMPILER "/usr/bin/xx-clang++")
```


- try42a: **手动注释imlib2-x检查** `清./build后二次安装imlib2-dev(cmake过了)>>装xxx-dev|静编:xxx>> cmake还复现,手动注释imlib2-x的检查` 

```bash
bash-5.1# cd build/
bash-5.1# ls
CMakeCache.txt  CMakeFiles
bash-5.1# rm -rf *
bash-5.1# ls
bash-5.1# find /usr/lib /usr/local/lib/ |grep imlib
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build


##装imlib2-dev>> cmake过了############################################
ln -s /mnt2/docker-x11base/compile/src /src
apk add git gawk

# bash-5.1# apk add xcomposite-dev #none
      bash /src/xcompmgr/build.sh Xdamage; 
      bash /src/xcompmgr/build.sh xcompmgr;
bash-5.1# apk add pango-dev
# --   Package 'imlib2', required by 'virtual:world', not found
bash-5.1# apk add imlib2-dev  ##清./build后二次安装: try41的错误过了;

# 检测过了: imlib_context_set_display in Imlib2 - found
      # bash-5.1# pwd
      /mnt2/_misc2-2/tint2/build
      # bash-5.1# rm -rf ../build/*; cmake ..
      -- Performing Test HAS_GENERIC
      -- Performing Test HAS_GENERIC - Success
      -- Checking for module 'librsvg-2.0>=2.14.0'
      --   Package 'librsvg-2.0', required by 'virtual:world', not found
      -- Checking for module 'libstartup-notification-1.0>=0.12'
      --   Package 'libstartup-notification-1.0', required by 'virtual:world', not found
      -- Looking for imlib_context_set_display in Imlib2
      -- Looking for imlib_context_set_display in Imlib2 - found
      CMake Error at CMakeLists.txt:199 (message):
        SVG support enabled yet dependency not fulfilled: librsvg-2.0

##装xxx-dev############################################
apk add startup-notification-dev #startup-notification
# apk add librsvg-dev #改用静态 libcroco-0.6.13 >> librsvg
# apk add gtk+2.0-dev
# imlib2 @/usr/local/lib; cmake检查通过(Imlib is not built with X support)
# cmake ..; #通过

# apk add dtl:
OK: 783 MiB in 265 packages
# bash-5.1#  apk add librsvg-dev #改用静态 libcroco-0.6.13 >> librsvg
(1/10) Installing shared-mime-info (2.1-r2)
(2/10) Installing gdk-pixbuf (2.42.8-r0)
(3/10) Installing librsvg (2.50.7-r1)
(4/10) Installing libwebp-dev (1.2.2-r2)
(5/10) Installing xz-dev (5.2.5-r1)
(6/10) Installing zstd-dev (1.5.0-r0)
(7/10) Installing libtiffxx (4.4.0-r4)
(8/10) Installing tiff-dev (4.4.0-r4)
(9/10) Installing gdk-pixbuf-dev (2.42.8-r0)
(10/10) Installing librsvg-dev (2.50.7-r1)
Executing busybox-1.34.1-r7.trigger
Executing shared-mime-info-2.1-r2.trigger
Executing gdk-pixbuf-2.42.8-r0.trigger
OK: 798 MiB in 275 packages
# bash-5.1# apk add gtk+2.0-dev
(1/33) Installing atk (2.36.0-r0)
(2/33) Installing atk-dev (2.36.0-r0)
(3/33) Installing perl-http-date (6.05-r1)
..
(24/33) Installing perl-xml-parser (2.46-r2)
(25/33) Installing intltool (0.51.0-r4)
(26/33) Installing hicolor-icon-theme (0.17-r1)
(27/33) Installing gtk-update-icon-cache (2.24.33-r0)
(28/33) Installing libxcursor (1.2.0-r0)
(29/33) Installing dbus-libs (1.12.26-r0)
(30/33) Installing avahi-libs (0.8-r5)
(31/33) Installing cups-libs (2.3.3-r8)
(32/33) Installing gtk+2.0 (2.24.33-r0)
Executing gtk+2.0-2.24.33-r0.post-install


##静编:libcroco,gdk-pixbuf,xcb_util############################################
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# 
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++


# bash-5.1# pwd
/mnt2/_deps/_tint/libcroco-0.6.13
bash-5.1# apk add libxml2-dev
    8  cd _tint/
   10  cd libcroco-0.6.13
   17  make
   18  make install
   19  find /usr/local/lib |grep libcro

  #  gdk-pixbuf
  apk add shared-mime-info
  bash /src/v-pcmanfm/build.sh gdk-pixbuf #'gi-docgen'... @where? no-.gitsubmodule
   22  cd ..
   24  cd librsvg
   27  make install
   30  git branch -a
   32  cd ..
   34  cd xcb__util/
   37  make install


##cmake还复现,手动注释imlib2-x的检查##################################
# [19] 0:docker*
# bash-5.1# rm -rf ../build/*; cmake ..
-- Performing Test HAS_GENERIC - Success
-- Checking for module 'librsvg-2.0>=2.14.0'
--   Found librsvg-2.0, version 2.40.21
-- Checking for module 'libstartup-notification-1.0>=0.12'
--   Found libstartup-notification-1.0, version 0.12
-- Looking for imlib_context_set_display in Imlib2
-- Looking for imlib_context_set_display in Imlib2 - not found
CMake Error at CMakeLists.txt:101 (message): ############line 101
  Imlib is not built with X support

# 手动注释  #if( NOT IMLIB_BUILD_WITH_X )
# bash-5.1# cat ../CMakeLists.txt |grep IMLIB_BUILD_WITH_X
check_library_exists( "${IMLIB2_LIBRARIES}" "imlib_context_set_display" "${IMLIB2_LIBRARY_DIRS}" IMLIB_BUILD_WITH_X )
#if( NOT IMLIB_BUILD_WITH_X )
#endif( NOT IMLIB_BUILD_WITH_X )
```

- try42b: **link of dynamic obj问题** `v-xlunch/build.sh imlib2>> gtk:@b_deps>> >>依旧static link of dynamic obj(试着移走so)`

```bash
# [imlib_context_set_display]
# bash /src/xcompmgr/build.sh Xdamage ##[  @xcompmgr]
bash /src/v-xlunch/build.sh imlib2


##gtk:@b_deps######################################
# deps: gtk+-x11-2.0
#   #gdk-pixbuf #'gi-docgen'... @where? no-.gitsubmodule
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
bash /src/v-tint2/build.sh b_deps #pango/xrand/xdamage>> atk/gdk >> gtk 

# gnome/gtk  branch="--branch=2.24.33"
https://github.com/GNOME/gtk/graphs/contributors
# master 78453@23.12.21
# 4.13.3 78191
# ===gtk2 vs gtk3: 仅风格不一样?
# 3.99.5.1 67700 @2020.12.8
# 3.24.39 53229 @latest.up 23.12.21
# 2.99.3 26115 @2011.2.2
# 2.32.2 20680 @2010.11.10
# 2.24.33 21855 @2020.12.21
# 2.24.32 21775 @2018.1.9


# bash-5.1# bash /src/v-tint2/build.sh b_deps
本操作从2023年12月22日15:34:30 开始 , 到2023年12月22日15:45:41 结束,  共历时671秒
gtk, finished.
/usr/lib/libXdamage.a
/usr/lib/libXrandr.a
/usr/lib/libatk-1.0.a
/usr/lib/libgdk-x11-2.0.a
/usr/lib/libgdk_pixbuf-2.0.a
/usr/lib/libgtk-x11-2.0.a
/usr/lib/libpango-1.0.a
/usr/lib/libpangocairo-1.0.a
/usr/lib/libpangoft2-1.0.a
/usr/lib/libpangoxft-1.0.a


##tint2:make>>依旧static link of dynamic object>>移走so######################################
# err link: 老样子
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
# bash-5.1# make
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/local/lib/libcroco-0.6.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/local/lib/librsvg-2.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libstartup-notification-1.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libc.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2

# 找出依赖的so文件列表;
bash-5.1# make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g"
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcomposite.so
..
/usr/local/lib/librsvg-2.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libstartup-notification-1.so

# 试着移走so>> 全改名;
   64  mv /usr/local/lib/libcroco-0.6.so /usr/local/lib/libcroco-0.6.so-ex
   #65  make
   66  mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmd.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmd.so-ex
   67  mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libc.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libc.so-ex
# bash-5.1# make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
```

- try42c: **strnappend改方法名**, tint2过了: `重名方法改名:multiple definition of 'strnappend'; >> tint2过了`; tint2conf err(转下份文档)

```bash
##tint2:make代码错误######################################
# err mark1:
# /usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmount.a(libcommon_la-strutils.o): in function 'strnappend':
# strutils.c:(.text+0x1542): multiple definition of 'strnappend'; CMakeFiles/tint2.dir/src/battery/battery.c.o:battery.c:(.text+0x1d0): first defined here

# make>>  multiple definition of 'strnappend'
bash-5.1# make 2>&1 #|grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
16.1-dirty
[  0%] Built target version
Consolidate compiler generated dependencies of target tint2
[  1%] Building C object CMakeFiles/tint2.dir/src/main.c.o
[  2%] Building C object CMakeFiles/tint2.dir/src/init.c.o
[  4%] Linking C executable tint2
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmount.a(libcommon_la-strutils.o): in function 'strnappend':
strutils.c:(.text+0x1542): multiple definition of 'strnappend'; CMakeFiles/tint2.dir/src/battery/battery.c.o:battery.c:(.text+0x1d0): first defined here
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2


# 重名方法改名;
   80  find |grep battery.c
   82  cat CMakeFiles/tint2.dir/src/battery/battery.c.o |grep strnappend -n
   83  cat CMakeFiles/tint2.dir/src/battery/battery.c.o |wc
   84  cat CMakeFiles/tint2.dir/src/battery/battery.c.o 
   86  find |grep "\.c$"
   88  find .. |grep battery.c
bash-5.1# cat ../src/battery/battery.c |grep strnappend
char *strnappend(char *dest, const char *addendum, size_t limit)
                strnappend(dest,
                strnappend(dest, buf, BATTERY_BUF_SIZE);
                strnappend(dest, buf, BATTERY_BUF_SIZE);
                strnappend(dest, buf, BATTERY_BUF_SIZE);
                    strnappend(dest, buf, BATTERY_BUF_SIZE);
                    strnappend(dest, buf, BATTERY_BUF_SIZE);
                strnappend(dest, "%", BATTERY_BUF_SIZE);
                strnappend(dest, buf, BATTERY_BUF_SIZE);
            strnappend(dest, buf, BATTERY_BUF_SIZE);
bash-5.1# sed -i "s/strnappend/strnappend02/g" ../src/battery/battery.c 
bash-5.1# cat ../src/battery/battery.c |grep strnappend
char *strnappend02(char *dest, const char *addendum, size_t limit)
                strnappend02(dest,
                strnappend02(dest, buf, BATTERY_BUF_SIZE);
                strnappend02(dest, buf, BATTERY_BUF_SIZE);
                strnappend02(dest, buf, BATTERY_BUF_SIZE);
                    strnappend02(dest, buf, BATTERY_BUF_SIZE);
                    strnappend02(dest, buf, BATTERY_BUF_SIZE);
                strnappend02(dest, "%", BATTERY_BUF_SIZE);
                strnappend02(dest, buf, BATTERY_BUF_SIZE);
            strnappend02(dest, buf, BATTERY_BUF_SIZE);


# 重名方法改名>> tint2过了, tint2conf err(转下份文档):
/usr/bin/x86_64-alpine-linux-musl-ld: /mnt2/_deps/_tint/librsvg/rsvg-styles.c:1111: undefined reference to 'cr_term_to_string'
...
XrrMonitor.c:(.text+0x4a7): undefined reference to 'XMissingExtension'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [src/tint2conf/CMakeFiles/tint2conf.dir/build.make:385: src/tint2conf/tint2conf] Error 1
make[1]: *** [CMakeFiles/Makefile2:202: src/tint2conf/CMakeFiles/tint2conf.dir/all] Error 2
make: *** [Makefile:136: all] Error 2

# bash-5.1# ls -lh tint2 
-rwxr-xr-x    1 root     root       10.1M Dec 22 16:34 tint2
bash-5.1# ldd tint2 
/lib/ld-musl-x86_64.so.1: tint2: Not a valid dynamic program
```
