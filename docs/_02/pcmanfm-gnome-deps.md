
## **DEPS**

```bash
# repos @gnome
git clone https://hub.nuaa.cf/GNOME/atk #3.29 MiB 1985> ATK_2_36_0 1943
git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf #177.02 MiB 6226> 2.42.8 6113
git clone https://hub.nuaa.cf/GNOME/gtk #644.58 MiB 78343> 2.24.33 21885
git checkout 2.24.33
# https://hub.nuaa.cf/genesi/gtk2
git clone https://hub.nuaa.cf/lxde/menu-cache #297 commits
```

- gtk-autotools-static OK

```bash
# GTK
config.status: executing default-1 commands
config.status: executing default-2 commands
config.status: executing gdk/gdkconfig.h commands
configuration:
        target: x11
Now type 'make' to compile Gtk+.
bash-5.1# ./autogen.sh

# bash-5.1# history |tail -15
  962  git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf
  963  git clone https://hub.nuaa.cf/GNOME/gtk
  964  cd gtk/
  965  git checkout 2.24.33
  966  ls
  967  ./autogen.sh 
  968  make
  969  echo $?
  970  make install
  971  echo $?
  972  find /usr/lib |grep gtk+ |grep "\.a$"
  974  find /usr/lib |grep gtk-x11
  975  find /usr/local/lib |grep gtk-x11

# 无静态库
# bash-5.1# find /usr/lib |grep gtk-x11
/usr/lib/libgtk-x11-2.0.so
/usr/lib/libgtk-x11-2.0.so.0
/usr/lib/libgtk-x11-2.0.so.0.2400.33
# bash-5.1# find /usr/local/lib |grep gtk-x11
/usr/local/lib/libgtk-x11-2.0.so
/usr/local/lib/libgtk-x11-2.0.so.0
/usr/local/lib/libgtk-x11-2.0.la
/usr/local/lib/libgtk-x11-2.0.so.0.2400.33
bash-5.1# pwd
/mnt2/_deps/_pcmanfm/gtk
# bash-5.1# find |grep gtk-x11
./gtk/libgtk-x11-2.0.la
./gtk/.libs/libgtk-x11-2.0.so
./gtk/.libs/libgtk-x11-2.0.lai
./gtk/.libs/libgtk-x11-2.0.exp
./gtk/.libs/libgtk-x11-2.0.so.0
./gtk/.libs/libgtk-x11-2.0.ver
./gtk/.libs/libgtk-x11-2.0.la
./gtk/.libs/libgtk-x11-2.0.so.0.2400.33T
./gtk/.libs/libgtk-x11-2.0.so.0.2400.33

# ./configure --enable-static >> 生成gtk-x11-2.0.a libgdk-x11-2.0.a
bash-5.1# history |tail -20
  982  ./configure --enable-static
  983  make clean
  984  make
  985  find |grep gtk-x11
bash-5.1# find |grep gtk-x11
./gtk/libgtk-x11-2.0.la
./gtk/.libs/libgtk-x11-2.0.so
./gtk/.libs/libgtk-x11-2.0.lai
./gtk/.libs/libgtk-x11-2.0.exp
./gtk/.libs/libgtk-x11-2.0.so.0
./gtk/.libs/libgtk-x11-2.0.ver
./gtk/.libs/libgtk-x11-2.0.la
./gtk/.libs/libgtk-x11-2.0.a
./gtk/.libs/libgtk-x11-2.0.so.0.2400.33
# bash-5.1# find |egrep "g.*k-x11.*\.a$"
./gtk/.libs/libgtk-x11-2.0.a
./gdk/.libs/libgdk-x11-2.0.a
./gdk/x11/.libs/libgdk-x11.a
# bash-5.1# find /usr/local/lib |egrep "g.*k-x11.*\.a$"
/usr/local/lib/libgtk-x11-2.0.a
/usr/local/lib/libgdk-x11-2.0.a
bash-5.1# ls -lh /usr/local/lib/libg*k-x11-2.0.a
-rw-r--r--    1 root     root        1.2M Nov 29 05:40 /usr/local/lib/libgdk-x11-2.0.a
-rw-r--r--    1 root     root        8.9M Nov 29 05:41 /usr/local/lib/libgtk-x11-2.0.a
# cp /usr/local/lib/libgdk-x11-2.0.a /usr/local/lib/libgtk-x11-2.0.a /usr/lib/
```

- atk-meson-static OK

```bash
Found CMake: /usr/bin/cmake (3.21.7)
Run-time dependency gobject-introspection-1.0 found: NO (tried pkgconfig and cmake)

atk/meson.build:138:2: ERROR: Dependency "gobject-introspection-1.0" not found, tried pkgconfig and cmake

A full log can be found at /mnt2/_deps/_pcmanfm/atk/build/meson-logs/meson-log.txt
bash-5.1# meson build
# apk add gobject-introspection-dev

 1010  cd ../atk/
 1012  git checkout ATK_2_36_0
 1013  ls
 1017  apk add gobject-introspection-dev
 1018  meson build
 1019  ls
 1020  ninja -C build/
 1021  echo $?
 1024  find |grep "atk.a$"
 1025  find /usr/lib |grep atk
 1026  find /usr/lib |grep atk |wc
 1027  find /usr/local/lib |grep atk |wc
 1028  ninja -C build/ install
 1029  find /usr/local/lib |grep atk |wc
 1030  find /usr/local/lib |grep atk


# 一把过，但无静态库
meson build
ninja -C build/
# bash-5.1# find /usr/local/lib |grep atk |wc
        4         4       131
# bash-5.1# find /usr/local/lib |grep atk 
/usr/local/lib/libatk-1.0.so.0.23609.1
/usr/local/lib/libatk-1.0.so.0
/usr/local/lib/pkgconfig/atk.pc
/usr/local/lib/libatk-1.0.so


# 静态库：--enable-static>> --default-library=both 
 1030  find /usr/local/lib |grep atk 
 1031  history |tail -25
 1032  meson build  --enable-static #ERR
 1033  meson build  -h
 1034  ninja -h
 1035  meson build  -h |grep static
 #1036  meson build  --default-library=both
 #1038  meson setup --wipe build
 1042  rm -rf build/
 1043  meson build  --default-library=both 
 1044  ninja -C build/
 1045  find build/ |grep atk 
 1046  find build/ |grep atk  |grep "\.a$"
# bash-5.1# find build/ |grep atk  |grep "\.a$"
build/atk/libatk-1.0.a


# atk INSTALL
bash-5.1# ninja -C build/ install
bash-5.1# find /usr/local/lib |grep atk  |grep "\.a$"
/usr/local/lib/libatk-1.0.a
bash-5.1# ls -lh /usr/local/lib/libatk-1.0.a
-rw-r--r--    1 root     root        1.1M Nov 29 06:23 /usr/local/lib/libatk-1.0.a
bash-5.1# cp -a /usr/local/lib/libatk-1.0.a /usr/lib/
```

- gdk-pixbuf--meson-static OK

```bash
# GDK-PIXBUF
  997  cd ../gdk-pixbuf/
  998  git checkout 2.42.8
  999  ls
 1000  meson build
 1001  echo $?
 1002  ls
 1003  ls build
 1004  ninja -C build

# meson build; #>> gi-docgen@git-pull
# ninja -C build
I/O error : Attempt to load network entity http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl
warning: failed to load external entity "http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl"
cannot parse http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl
ninja: subcommands failed




################# 去除xsltproc; dyn:build OK; 
 1116  mv /usr/bin/xsltproc /usr/bin/xsltproc00
 1128  rm /usr/bin/xsltproc
 1129  touch /usr/bin/xsltproc
 1130  chmod +x /usr/bin/xsltproc
 1131  vi /usr/bin/xsltproc ##  #!/bin/bash; echo 123
 1125  ls -lh /usr/bin/xsltproc*
 1132  xsltproc
 #
 1134  ninja -C build #meson compile -C build
 1138  find |grep pixbuf |grep "\.a$"
 
# install: 手动touch生成docs>> install; 无静态库
 1139  ninja -C build install
 1143  touch build/docs/gdk-pixbuf-csource.1
 1145  touch build/docs/gdk-pixbuf-query-loaders.1
 1146  ninja -C build install
 1149  find /usr/local |grep pixbuf |grep -v tests
# bash-5.1# find |grep pixbuf |grep "\.a$" ##src目录3个；/usr/local/lib无;
./build/gdk-pixbuf/libstaticpixbufloader-jpeg.a
./build/gdk-pixbuf/libstaticpixbufloader-png.a
./build/gdk-pixbuf/pixops/libpixops.a




################# 静态编译; ##src目录4个；/usr/local/lib 1个;
meson build  --default-library=both
bash-5.1# ninja -C build
# bash-5.1# find |grep pixbuf |grep "\.a$"
./build/gdk-pixbuf/libstaticpixbufloader-jpeg.a
./build/gdk-pixbuf/libstaticpixbufloader-png.a
./build/gdk-pixbuf/pixops/libpixops.a
./build/gdk-pixbuf/libgdk_pixbuf-2.0.a

# ninja -C build install
bash-5.1# find /usr/local/lib |grep pixbuf |grep -v tests
/usr/local/lib/libgdk_pixbuf-2.0.so.0.4200.8
/usr/local/lib/gdk-pixbuf-2.0
/usr/local/lib/gdk-pixbuf-2.0/2.10.0
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-icns.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-tiff.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-gif.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-xbm.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-bmp.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-xpm.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-ani.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-ico.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-tga.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-qtif.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-pnm.so
/usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
/usr/local/lib/libgdk_pixbuf-2.0.so
/usr/local/lib/libgdk_pixbuf-2.0.so.0
/usr/local/lib/pkgconfig/gdk-pixbuf-2.0.pc
/usr/local/lib/libgdk_pixbuf-2.0.a  ####

# bash-5.1# ls -lh /usr/local/lib/libgdk_pixbuf-2.0.a
-rw-r--r--    1 root     root     1016.6K Nov 29 13:39 /usr/local/lib/libgdk_pixbuf-2.0.a
bash-5.1# cp /usr/local/lib/libgdk_pixbuf-2.0.a /usr/lib/

```

- lxde/menu-cache--autotools-static OK

```bash
bash-5.1# find  |grep "\.a$"
./libmenu-cache/.libs/libmenu-cache.a
bash-5.1# history |tail -14
 1262  pwd #_misc/pcmanfm
 1263  cd ../../_deps/_pcmanfm/
 1265  git clone https://hub.nuaa.cf/lxde/menu-cache
 1266  cd menu-cache/
 1268  ./autogen.sh 
 1269  echo $?
 1271  ./configure --enable-static
 1272  make
 1274  find  |grep "\.a$"

# make install
bash-5.1# find /usr/local/lib |grep "menu-cache.*\.a$"
/usr/local/lib/libmenu-cache.a
bash-5.1# cp /usr/local/lib/libmenu-cache.a /usr/lib/

```