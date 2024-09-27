
## FF

- cmake:
  - 1.tigervnc
  - 2.tint2

```bash
# STATIC @cmake
  # https://gitlab.com/o9000/tint2/-/wikis/Development
  #   cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=OFF ..
  # https://gitlab.com/o9000/tint2/-/wikis/Install

# [o9000/tint2] v16.1
  # https://gitlab.com/o9000/tint2/-/wikis/Install #v0.12.2
  # https://gitlab.com/o9000/tint2/-/wikis/Install#dependencies
  sudo apt-get install libcairo2-dev libpango1.0-dev 
  # libglib2.0-dev libimlib2-dev libgtk-3-dev libxinerama-dev libx11-dev 
  libxdamage-dev libxcomposite-dev libxrender-dev libxrandr-dev librsvg2-dev libstartup-notification0-dev

  https://github.com/o9000/tint2 #1678commits @19.6.3
  https://github.com/o9000/tint2/tree/v16.1 #1594commits @17.12.30
  https://github.com/o9000/tint2/tree/v0.12.2 #771commits @15.8.11


# TODO 改CMakeLists.txt (share> static)
  https://blog.csdn.net/weixin_45004203/article/details/125256367 #CMake 常用总结二：CMake 生成静态库与动态库
  https://blog.csdn.net/whatday/article/details/118071243 #cmake 静态编译 简介
  set(CMAKE_EXE_LINKER_FLAGS "-static")

# https://blog.csdn.net/weixin_43376501/article/details/129792853 #使用find_library，find_path如何设置只寻找静态库而不是动态库
  set(CMAKE_FIND_LIBRARY_SUFFIXES .a)

# https://www.codenong.com/40618443/ #关于linux：使用CMAKE编译静态可执行文件
  SET(CMAKE_FIND_LIBRARY_SUFFIXES".a")
  SET(BUILD_SHARED_LIBRARIES OFF)
  SET(CMAKE_EXE_LINKER_FLAGS "-static") #hk1box@24.9.27: 手动加上后cmake > make; 默认静态无需xx.so.x-ex更名了;

```

## tint2 err@hk1box

- tenvm2/hk1box: 不同错误
  - tenvm2: `attempted static link of dynamic object`
  - hk1box: 无提示，编译后为dyn, 且./tint2无法执行

```bash
# -ex; tenvm2 @24.9.29
/mnt2/docker-x11base/compile/src # find /usr/lib /usr/local/lib |grep "\-ex$" |sort
/usr/lib/libX11-xcb.so-ex
/usr/lib/libX11.so-ex
/usr/lib/libXau.so-ex
/usr/lib/libXcomposite.so-ex
/usr/lib/libXcursor.so-ex
/usr/lib/libXdmcp.so-ex
/usr/lib/libXext.so-ex
/usr/lib/libXfixes.so-ex
/usr/lib/libXft.so-ex
/usr/lib/libXinerama.so-ex
/usr/lib/libXrandr.so-ex
/usr/lib/libXrender.so-ex
/usr/lib/libblkid.so-ex
/usr/lib/libbrotlicommon.so-ex
/usr/lib/libbrotlidec.so-ex
/usr/lib/libbz2.so-ex
/usr/lib/libc.so-ex
/usr/lib/libcairo.so-ex
/usr/lib/libexpat.so-ex
/usr/lib/libffi.so-ex
/usr/lib/libfontconfig.so-ex
/usr/lib/libfreetype.so-ex
/usr/lib/libfribidi.so-ex
/usr/lib/libgdk-x11-2.0.so-ex
/usr/lib/libgio-2.0.so-ex
/usr/lib/libglib-2.0.so-ex
/usr/lib/libgmodule-2.0.so-ex
/usr/lib/libgobject-2.0.so-ex
/usr/lib/libgpg-error.so-ex
/usr/lib/libgraphite2.so-ex
/usr/lib/libgtk-x11-2.0.so-ex
/usr/lib/libharfbuzz.so-ex
/usr/lib/libintl.so-ex
/usr/lib/libjpeg.so-ex
/usr/lib/liblzma.so-ex
/usr/lib/libmd.so-ex
/usr/lib/libmount.so-ex
/usr/lib/libpango-1.0.so-ex
/usr/lib/libpangocairo-1.0.so-ex
/usr/lib/libpangoft2-1.0.so-ex
/usr/lib/libpcre.so-ex
/usr/lib/libpixman-1.so-ex
/usr/lib/libpng.so-ex
/usr/lib/libstartup-notification-1.so-ex
/usr/lib/libuuid.so-ex
/usr/lib/libxcb-render.so-ex
/usr/lib/libxcb-shm.so-ex
/usr/lib/libxcb.so-ex
/usr/lib/libxml2.so-ex
/usr/local/lib/libatk-1.0.so-ex
/usr/local/lib/libcroco-0.6.so-ex
/usr/local/lib/libgdk_pixbuf-2.0.so-ex
/usr/local/lib/librsvg-2.so-ex


# tenvm2: attempted static link of dynamic object
[  2%] Building C object CMakeFiles/tint2.dir/src/init.c.o
[  4%] Linking C executable tint2
# /usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcomposite.so'

/tmp/tint2/build # make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11-xcb.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXau.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcomposite.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcursor.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXdmcp.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXext.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXfixes.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXinerama.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrandr.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrender.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libblkid.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbrotlicommon.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbrotlidec.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbz2.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libc.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libexpat.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libffi.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfribidi.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgdk-x11-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgmodule-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgobject-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgpg-error.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgraphite2.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgtk-x11-2.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libharfbuzz.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libintl.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libjpeg.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../liblzma.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmd.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmount.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpangocairo-1.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpangoft2-1.0.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpcre.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpixman-1.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libstartup-notification-1.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libuuid.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb-render.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb-shm.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb.so
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxml2.so
/usr/local/lib/libatk-1.0.so
/usr/local/lib/libcroco-0.6.so
/usr/local/lib/libgdk_pixbuf-2.0.so
/usr/local/lib/librsvg-2.so

# @hk1box
#  1.按ldd改ex,编译错
#  2.不改ex, 无attempted static link of dynamic object错误>> 编译后: 
#    tin2conf可用[静态的]
#    tint2不可用[ldd有一堆依赖];

# 原rootfs内: tint2@23.2-也不能执行(无回执, errCode:127) [ldd: Not a valid dynamic program]
```

- cmake -Dxxx=yy

```bash
# deps-imlib2
v-xlunch/build.sh>> imlib2 1.7.4; --with-x;

# HAND DBG
cd /tmp; #@hkbox-gtkbuilder
git clone https://gitee.com/g-system/fk-tint2
cd fk-tint2; mkdir build; cd build;


export TARGETPATH=/usr/local/static/tint2
# cmake .. --install-prefix=$TARGETPATH
cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=OFF .. --install-prefix=$TARGETPATH


# DTL:
b1d491eb5ac5:/tmp/fk-tint2/build# cmake -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=OFF .. --install-prefix=$TARGETPATH
b1d491eb5ac5:/tmp/fk-tint2/build# echo $?
0
b1d491eb5ac5:/tmp/fk-tint2/build# make
16.2-5-g1168c33
[  0%] Built target version
[  2%] Building C object CMakeFiles/tint2.dir/src/config.c.o
..
[ 97%] Building C object CMakeFiles/tint2.dir/src/util/window.c.o
[100%] Linking C executable tint2
[100%] Built target tint2
b1d491eb5ac5:/tmp/fk-tint2/build# ls
CMakeCache.txt       CMakeFiles           Makefile             cmake_install.cmake  tint2                version.h
b1d491eb5ac5:/tmp/fk-tint2/build# ls -lh tint2 
-rwxr-xr-x    1 root     root       14.2M Sep 29 05:58 tint2
b1d491eb5ac5:/tmp/fk-tint2/build# ldd tint2 
        /lib/ld-linux-aarch64.so.1 (0x7f9e08f000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7f9e06d000)
        libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f9e053000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7f9df1a000)
        libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f9de54000)
        libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7f9ddb5000)
        libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7f9dda3000)
        libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7f9dd90000)
        libc.musl-aarch64.so.1 => /lib/ld-linux-aarch64.so.1 (0x7f9e08f000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f9dd5a000)
        libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f9dd3d000)
        libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f9dcfd000)
        libz.so.1 => /lib/libz.so.1 (0x7f9dcd6000)
        libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f9dcbc000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7f9dca8000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f9dc92000)
        libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f9dc61000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f9dc3f000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7f9dc24000)
b1d491eb5ac5:/tmp/fk-tint2/build# ./tint2 
-ash: ./tint2: not found
```

- make > `attempted static link of dynamic object`; try with XXFLAGS:同结果

```bash
/tmp/fk-tint2/build # make
16.2-5-g1168c33
[  0%] Built target version
[  2%] Building C object CMakeFiles/tint2.dir/src/config.c.o
..
[ 97%] Building C object CMakeFiles/tint2.dir/src/util/window.c.o
[100%] Linking C executable tint2
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcomposite.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXfixes.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXinerama.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXext.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrender.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXrandr.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgdk-x11-2.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgtk-x11-2.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/local/lib/libatk-1.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/local/lib/libgdk_pixbuf-2.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpangoft2-1.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXdmcp.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXau.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpng.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libexpat.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxml2.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbz2.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../liblzma.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbrotlidec.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libbrotlicommon.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfribidi.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpcre.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgraphite2.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libffi.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgmodule-2.0.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgpg-error.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpixman-1.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libjpeg.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libuuid.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmount.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libblkid.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11-xcb.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb-shm.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb-render.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libmd.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/local/lib/libcroco-0.6.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcursor.so'
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libc.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/tint2.dir/build.make:707: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:85: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2

##try with XXFLAGS#########################################################################
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++
make clean; make; #同结果

b1d491eb5ac5:/tmp/fk-tint2/build# ./tint2 
-ash: ./tint2: not found
b1d491eb5ac5:/tmp/fk-tint2/build# echo $?
127
b1d491eb5ac5:/tmp/fk-tint2/build# ls -lh tint2 
-rwxr-xr-x    1 root     root       14.2M Sep 29 08:26 tint2


# build-tenvm2-out1.tar.gz #xx-clang的编译
# build-hk1box-out1.tar    #cc的编译
# build-hk1box-out2.tar    #xx-clang的编译
########################################
# hk1box换xx-clang的编译后： cmake> make:也是一把过了,生成文件仍旧不可用; (bcompare参数一致: build-tenvm2-out1 vs build-hk1box-out2)

```

- dyn@hk1box 构建后能运行

```bash
# 24.10.8  ref dyn@tint2-v16.1.md
cd /tmp
git clone --branch v16.2 https://gitee.com/g-system/fk-tint2
apk add pango-dev imlib2-dev librsvg-dev startup-notification-dev gtk+2.0-dev
  14 cd /tmp/fk-tint2/
  15 mkdir build
  16 cd build/
  17 cmake ..
  18 make
  19 echo $?
  23 ./tint2 
  24 ldd tint2 |sort


7e8e01c56ca3:/tmp/fk-tint2/build# ./tint2 
tint2: could not open display!
7e8e01c56ca3:/tmp/fk-tint2/build# ldd tint2 |sort
        /lib/ld-musl-aarch64.so.1 (0x7fb3152000)
        libImlib2.so.1 => /usr/lib/libImlib2.so.1 (0x7fb2bb6000)
        libX11-xcb.so.1 => /usr/lib/libX11-xcb.so.1 (0x7fb1ca4000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7fb2f34000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7fb1a8f000)
        libXcomposite.so.1 => /usr/lib/libXcomposite.so.1 (0x7fb30bc000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7fb1a79000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7fb3087000)
        libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7fb30a9000)
        libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7fb2f19000)
        libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7fb306d000)
        libblkid.so.1 => /lib/libblkid.so.1 (0x7fb18b2000)
        libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7fb1881000)
        libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7fb1964000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7fb1910000)
        libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7fb197e000)
        libc.musl-aarch64.so.1 => /lib/ld-musl-aarch64.so.1 (0x7fb3152000)
        libcairo-gobject.so.2 => /usr/lib/libcairo-gobject.so.2 (0x7fb1c8b000)
        libcairo.so.2 => /usr/lib/libcairo.so.2 (0x7fb2c1b000)
        libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7fb1a46000)
        libffi.so.8 => /usr/lib/libffi.so.8 (0x7fb1f30000)
        libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7fb2211000)
        libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7fb1d4d000)
        libfribidi.so.0 => /usr/lib/libfribidi.so.0 (0x7fb200d000)
        libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7fb1b22000)
        libgdk_pixbuf-2.0.so.0 => /usr/local/lib/libgdk_pixbuf-2.0.so.0 (0x7fb22d5000)
        libgio-2.0.so.0 => /usr/lib/libgio-2.0.so.0 (0x7fb2039000)
        libglib-2.0.so.0 => /usr/lib/libglib-2.0.so.0 (0x7fb2d1d000)
        libgmodule-2.0.so.0 => /usr/lib/libgmodule-2.0.so.0 (0x7fb1b0e000)
        libgobject-2.0.so.0 => /usr/lib/libgobject-2.0.so.0 (0x7fb2e43000)
        libgraphite2.so.3 => /usr/lib/libgraphite2.so.3 (0x7fb199b000)
        libharfbuzz.so.0 => /usr/lib/libharfbuzz.so.0 (0x7fb1f4a000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fb1eb2000)
        libjpeg.so.8 => /usr/lib/libjpeg.so.8 (0x7fb1ab9000)
        liblzma.so.5 => /usr/lib/liblzma.so.5 (0x7fb1932000)
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7fb1866000)
        libmount.so.1 => /lib/libmount.so.1 (0x7fb19c8000)
        libpango-1.0.so.0 => /usr/lib/libpango-1.0.so.0 (0x7fb2ea4000)
        libpangocairo-1.0.so.0 => /usr/lib/libpangocairo-1.0.so.0 (0x7fb2efc000)
        libpangoft2-1.0.so.0 => /usr/lib/libpangoft2-1.0.so.0 (0x7fb225f000)
        libpcre.so.1 => /usr/lib/libpcre.so.1 (0x7fb1ecd000)
        libpixman-1.so.0 => /usr/lib/libpixman-1.so.0 (0x7fb1e13000)
        libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7fb1d0d000)
        librsvg-2.so.2 => /usr/lib/librsvg-2.so.2 (0x7fb230b000)
        libstartup-notification-1.so.0 => /usr/lib/libstartup-notification-1.so.0 (0x7fb22bb000)
        libuuid.so.1 => /lib/libuuid.so.1 (0x7fb1a2f000)
        libxcb-render.so.0 => /usr/lib/libxcb-render.so.0 (0x7fb1cdd000)
        libxcb-shm.so.0 => /usr/lib/libxcb-shm.so.0 (0x7fb1cfa000)
        libxcb-util.so.1 => /usr/lib/libxcb-util.so.1 (0x7fb1aa3000)
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7fb2285000)
        libxml2.so.2 => /usr/lib/libxml2.so.2 (0x7fb1b47000)
        libz.so.1 => /lib/libz.so.1 (0x7fb1cb6000)
```