

## tint2conf

- try51 `tmux19: tint2>>  -static> -shared; cmake ..; make>> tint2仍为static; tint2conf ERR依旧`

```bash
# [19] 0:docker*
# bash-5.1# make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
..
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgtk-x11-2.0.a(gtkthemes.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libharfbuzz.a(hb-graphite2.cc.o):


###### apk add tint2;  #alpine315 #######################################################
bash-5.1# apk list |grep tint2
tint2-17.0.1-r1 x86_64 {tint2} (GPL-2.0) [installed]
# ldd:
bash-5.1# ldd /usr/bin/tint2 |sort |wc
       52       206      3225
bash-5.1# ldd /usr/bin/tint2conf |sort |wc
       65       258      4035 #+13


# +deps tint2-17.0.1-r1 x86_64 {tint2} (GPL-2.0) [installed] @alpine315
-lXcursor -lXfixes -lXi -lxkbcommon -latk-1.0 -latk-bridge-2.0 -lcairo-gobject 
-latspi -ldbus -1epoxy 
-lgdk-3 -lgtk-3 -lwayland-client -lwayland-cursor -lwayland-egl 

# xkbcommon atk-bridge-2.0 atspi dbus
confdeps="-lXfixes -lXcursor -lXi -lxkbcommon -lcairo-gobject -latk-1.0 -latk-bridge-2.0 -latspi -ldbus -lepoxy"
grp1=$(echo $confdeps |sed "s/ -l/|/g" |sed "s/-l//g")
echo $grp1

# bash-5.1# find /usr/lib /usr/local/lib |egrep "$grp1" |grep "\.a$"
/usr/lib/libcairo-gobject.a
/usr/lib/libatk-1.0.a
/usr/lib/libXfixes.a
/usr/lib/libXinerama.a #ex
/usr/local/lib/libatk-1.0.a
--
/usr/lib/libXi.so.6.1.0
/usr/lib/libXi.so

# -lXcursor -lXi: ref suckless/build.sh
apk add libxcursor-dev

# xkbcomp: ref tigervnc/build.sh


# tmux19: tint2>>  -static> -shared; cmake ..; make>> tint2仍为static; tint2conf ERR依旧
```

- try52 `[tmux20] x11-base:alpine-builer-gtk224编译;` err: `undefined reference to symbol 'xcb_generate_id'`

```bash
# [tmux20] x11-base:alpine-builer-gtk224编译; 
# ...

###### tint2 16.1 dyn-build's deps #############################################
# [tmux19] x11-base:builer重置，动态编译>> 查看16.1版依赖;
23  ldd src/tint2conf/tint2conf  |sort > /mnt2/ldd-tint2conf-cpl.txt ##相比alpine315-apk安装的(tint2-17.0.1-r1)，无wayland, dbus, atspi等依赖;
25  ldd ./tint2  |sort > /mnt2/ldd-tint2-cpl.txt

# sort: ldd-tint2conf-cpl.txt
	libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7fa69a3e3000)
	libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7fa69a47a000)
	libXi.so.6 => /usr/lib/libXi.so.6 (0x7fa69a3ef000)
	libatk-1.0.so.0 => /usr/lib/libatk-1.0.so.0 (0x7fa69a454000)
	libgdk-x11-2.0.so.0 => /usr/lib/libgdk-x11-2.0.so.0 (0x7fa69b2c7000)
	libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7fa69b36c000)
	libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7fa699ff8000)
```


## builder-gtk224

**cmake区别** (dyn vs gtk224)

- tmux20 al-builder-gtk224

```bash
# bash-5.1# rm -rf ../build/*; cmake ..
-- The C compiler identification is GNU 10.3.1
-- The CXX compiler identification is GNU 10.3.1
-- Detecting C compiler ABI info
..
-- Found Gettext: /usr/bin/msgmerge (found version "0.21") 
-- gettext found languages: bs es fr hr pl ru sr 
-- Configuring done
-- Generating done
-- Build files have been written to: /mnt2/_misc2-2/tint2/build
```

- tmux19 dyn-make


```bash
# DIFF: xrandr, version 1.5.2 << static: 153
# bash-5.1# rm -rf ../build/*; cmake ..
-- The C compiler identification is GNU 10.3.1
-- The CXX compiler identification is GNU 10.3.1
-- Detecting C compiler ABI info
..
-- Build files have been written to: /mnt2/_misc2-2/tint2/build

```

**gtk224** (built tint2)

- `undefined reference to symbol 'xcb_generate_id'`，指定xx-clang编译过了

```bash
rm -rf /src; ln -s /mnt2/docker-x11base/compile/src /src
# message( FATAL_ERROR "Imlib is not
sed -i 's/^  message( FATAL_ERROR "Imlib is not/^  #message( FATAL_ERROR "Imlib is not/g' ../CMakeLists.txt

apk add librsvg-dev
apk add startup-notification-dev

# cmake ..; make err:
[ 60%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libX11.so: undefined reference to symbol 'xcb_generate_id'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/libxcb.so.1: error adding symbols: DSO missing from command line


###尝试apk安装依赖库 #############################################
# bash-5.1# apk add imlib2-dev
(1/4) Installing giflib (5.2.1-r0)
(2/4) Installing libid3tag (0.15.1b-r8)
(3/4) Installing imlib2 (1.7.4-r0)
(4/4) Installing imlib2-dev (1.7.4-r0)


# apk add startup-notification-dev #startup-notification
apk add librsvg-dev
apk add gtk+2.0-dev  ##本地安装了，则会跳过install;

# find /usr/lib |grep xcb ##tmux20 与tmux19-dyn-build 两边是一样个数;
bash-5.1# find /usr/lib |grep xcb |wc
      158       158      5283


#####################
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# 
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++


# 用bk5替换后，指定xx-clang编译过了;
bash-5.1# cat CMakeLists.txt-bk5-tint2OK > CMakeLists.txt
bash-5.1# #rm -rf ../build/*; cmake ..
[ 56%] Building C object CMakeFiles/tint2.dir/src/util/window.c.o
[ 57%] Building C object CMakeFiles/tint2.dir/src/battery/battery.c.o
[ 59%] Building C object CMakeFiles/tint2.dir/src/battery/linux.c.o
[ 60%] Linking C executable tint2
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lxcb-util
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lcroco-0.6
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lrsvg-2
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lcroco-0.6
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2

# _deps/_tint/libcroco, librsvg, xcb__util; make install x3;
```

- Xcursor Xi

```bash
# 清动态库
make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
# 改回
find /usr/lib /usr/local/lib |grep "so-ex$" |while read one; do echo $one; n2=$(echo $one |sed "s/so-ex/so/g"); \cp -a $one $n2; done


# 依赖项 ###################
--
/usr/lib/libXi.so.6.1.0
/usr/lib/libXi.so
######## sort: ldd-tint2conf-cpl.txt
libXcursor.so.1 => /usr/lib/libXcursor.so.1 (0x7fa69a3e3000)
libXfixes.so.3 => /usr/lib/libXfixes.so.3 (0x7fa69a47a000) #已在../CMakeLists.txt
libXi.so.6 => /usr/lib/libXi.so.6 (0x7fa69a3ef000)
# 
libatk-1.0.so.0 => /usr/lib/libatk-1.0.so.0 (0x7fa69a454000) #已在
libgdk-x11-2.0.so.0 => /usr/lib/libgdk-x11-2.0.so.0 (0x7fa69b2c7000)
libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7fa69b36c000)
# libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7fa699ff8000)


# -lXcursor -lXi: ref suckless/build.sh
apk add libxcursor-dev


# bash-5.1# cat ../CMakeLists.txt |grep Xi -n
270:target_link_libraries( tint2 ${X11_LIBRARIES}  Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2  ###>> Xcursor Xi

# 找不到Xi
[ 60%] Linking C executable tint2
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lXi
# https://github.com/aleax/libxi

bash-5.1# history |tail -18
   14  cd .. #/mnt2/_deps/_tint2
   16  git clone https://hub.yzuu.cf/aleax/libxi
   17  cd libxi/
   19  ./autogen.sh 
   20  make #err;
   21  ./configure  -h
   22  ./configure  --enable-static --disable-shared #disable dyn;
   23  make
   24  find |grep libXi.a
   25  make install
   27  find /usr/lib /usr/local/lib |grep libXi.a
bash-5.1# find |grep libXi.a
./src/.libs/libXi.a
bash-5.1# find /usr/lib /usr/local/lib |grep libXi.a
/usr/local/lib/libXi.a

# libXcursor.so-ex
bash-5.1# mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcursor.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXcursor.so-ex

```

- tint2conf static-deps err

```bash
# tint2过了, tint2conf err:
bash-5.1# make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
...
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.a(pango-bidi-type.c.o):
# bash-5.1# make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
       67        67      6438


bash-5.1# find ../ |grep CMakeLists.txt
../src/tint2conf/CMakeLists.txt ##
../src/tint2conf/po/CMakeLists.txt
../CMakeLists.txt-bk5-tint2OK
../CMakeLists.txt-bk3
../CMakeLists.txt-bk4
../CMakeLists.txt-bk1
../CMakeLists.txt-bk2
../CMakeLists.txt ##
../themes/CMakeLists.txt


# 改../src/tint2conf/CMakeLists.txt; (只改link_lib， 其它的从上层继承??)
Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2 Xcursor Xi
# root@tenvm2:/mnt/_misc2-2/tint2/src/tint2conf# cat CMakeLists.txt |grep png
target_link_libraries( tint2conf ${X11_T2C_LIBRARIES} Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2 Xcursor Xi

# 改../src/tint2conf/CMakeLists.txt>>  cmake ..; make -C src/tint2conf/; 一把过
bash-5.1# pwd
/mnt2/_misc2-2/tint2/build
bash-5.1# rm -rf ../build/*; cmake ..
bash-5.1# #make -C src/tint2conf/
make[2]: Entering directory '/mnt2/_misc2-2/tint2/build'
[100%] Generating sr.gmo
make[2]: Leaving directory '/mnt2/_misc2-2/tint2/build'
[100%] Built target pofiles_7
make[1]: Leaving directory '/mnt2/_misc2-2/tint2/build'
make: Leaving directory '/mnt2/_misc2-2/tint2/build/src/tint2conf'
bash-5.1# 

# view
bash-5.1# ls -lh src/tint2conf/tint2conf 
-rwxr-xr-x    1 root     root       13.4M Dec 23 15:05 src/tint2conf/tint2conf
bash-5.1# ldd src/tint2conf/tint2conf 
/lib/ld-musl-x86_64.so.1: src/tint2conf/tint2conf: Not a valid dynamic program
```

## v-tint2/build.sh @23.12.29


```bash
# build.sh tint2
-- Checking for modules 'x11;xcomposite;xdamage;xinerama;xrender;xrandr>=1.3'
..
-- Configuring done
You have changed variables that require your cache to be deleted.
Configure will be re-run and you may have to reset some variables. ##re-run loop..
The following variables have changed:
CMAKE_C_COMPILER= /usr/bin/cc
CMAKE_CXX_COMPILER= /usr/bin/c++


# 拷贝最初手动版也不行>> 手动注释C,CXX_COMPILER两行
bash-5.1# pwd
/tmp/tint2/build
# bash-5.1# cat /mnt2/_misc2-2/tint2/CMakeLists.txt > ../CMakeLists.txt
bash-5.1# cat ../CMakeLists.txt |head -7
project( tint2 )
cmake_minimum_required( VERSION 2.8.5 )
#set(CMAKE_C_COMPILER "/usr/bin/xx-clang")
#set(CMAKE_CXX_COMPILER "/usr/bin/xx-clang++")
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)



# apk add libxcursor-dev ##已有;
bash-5.1# find /usr/lib /usr/local/lib |grep libXcur
/usr/lib/libXcursor.a
/usr/lib/libXcursor.so
/usr/lib/libXcursor.so.1.0.2
/usr/lib/libXcursor.so.1

# -lxcb-util -lXi
# bash-5.1# make
[ 60%] Linking C executable tint2
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libmount.a(libcommon_la-strutils.o): in function 'strnappend':
strutils.c:(.text+0x1542): multiple definition of 'strnappend'; CMakeFiles/tint2.dir/src/battery/battery.c.o:battery.c:(.text+0x332): first defined here
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lxcb-util
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXi
collect2: error: ld returned 1 exit status
make[2]: *** [CMakeFiles/tint2.dir/build.make:739: tint2] Error 1
make[1]: *** [CMakeFiles/Makefile2:150: CMakeFiles/tint2.dir/all] Error 2
make: *** [Makefile:136: all] Error 2



# 补装libXi后，static link of xx.so ERR; >> 改ex后 tint2 tint2conf静态编译OK;
bash-5.1# ls
CMakeCache.txt       Makefile             src                  tint2
CMakeFiles           cmake_install.cmake  themes               version.h
bash-5.1# ls -lh tint2 
-rwxr-xr-x    1 root     root       37.2M Dec 29 07:46 tint2
bash-5.1# ls -lh src/tint2conf/tint2conf 
-rwxr-xr-x    1 root     root       43.0M Dec 29 07:46 src/tint2conf/tint2conf
bash-5.1# history |tail -28
  153  apk add libxcursor-dev
  154  find /usr/lib |grep xcursor
  155  find /usr/lib /usr/local/lib |grep xcursor
  156  pwd
  157  cd -
  158  git pull; bash /src/v-tint2/build.sh libxi
  159  env |grep GITHUB
  160  export GITHUB=https://hub.njuu.cf
  161  git pull; bash /src/v-tint2/build.sh libxi
  162  find /usr/lib /usr/local/lib |grep libXcur
  163  cd -
  164  make
  165  history 
  166  cd -
  167  git pull
  168  git pull; bash /src/v-tint2/build.sh xcbutil
  169  find /usr/lib/ /usr/local/lib |grep libxcb-util |grep "\.a$"
  170  pwd
  171  cd -
  172  make
  173  make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
  174  make
  175  sed -i "s/strnappend/strnappend02/g" ../src/battery/battery.c 
  176  make
  177  ls
  178  ls -lh tint2 
  179  ls -lh src/tint2conf/tint2conf 
  180  history |tail -28
```