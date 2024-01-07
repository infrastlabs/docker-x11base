

# **pcmanfm**

- pcmanfm `lxde, gtk`

```bash
# root@tenvm2:/mnt/_statics# ll -h
total 42M
drwxr-xr-x 2 root root 4.0K Nov 30 00:07 ./
drwxr-xr-x 6 root root 4.0K Nov 30 00:06 ../
-rwxr-xr-x 1 root root  38M Nov 30 00:06 pcmanfm*
# -rwxr-xr-x 1 root root 1.1M Nov 30 00:07 xcompmgr*
# -rwxr-xr-x 1 root root 3.5M Nov 30 00:07 xlunch*

# root@tenvm2:/mnt/_statics# ./pcmanfm  -h
(pcmanfm:301467): GModule-CRITICAL **: 00:08:29.947: g_module_symbol: assertion 'module != NULL' failed
(pcmanfm:301467): GModule-CRITICAL **: 00:08:29.947: g_module_close: assertion 'module != NULL' failed
Usage:
  pcmanfm [OPTION…] [FILE1, FILE2,...]  
Help Options:
  -h, --help                   Show help options
  --help-all                   Show all help options
  --help-gtk                   Show GTK+ Options

Application Options:
  -p, --profile=PROFILE        Name of configuration profile
  -d, --daemon-mode            Run PCManFM as a daemon
  --no-desktop                 No function. Just to be compatible with nautilus
  --desktop                    Launch desktop manager
  --desktop-off                Turn off desktop manager if it\'s running
  --desktop-pref               Open desktop preference dialog
  --one-screen                 Use --desktop option only for one screen
  -w, --set-wallpaper=FILE     Set desktop wallpaper from image FILE
  --wallpaper-mode=MODE        Set mode of desktop wallpaper. MODE=(color|stretch|fit|crop|center|tile|screen)
  --show-pref=N                Open Preferences dialog on the page N
  -n, --new-win                Open new window
  -f, --find-files             Open a Find Files window
  --role=ROLE                  Window role for usage by window manager
  --display=DISPLAY            X display to use
```

- 01

```bash
  161  git clone https://hub.nuaa.cf/invisikey/xcompmgr
  167  git clone https://hub.nuaa.cf/Tomas-M/xlunch
  169  ls
  168  git clone https://hub.nuaa.cf/lxde/pcmanfm
  170  cd pcmanfm/
  172  cat autogen.sh 
  173  ./autogen.sh 
  174  echo $?
  176  ./configure 


# v112
checking for strings.h... yes
checking for sys/stat.h... yes
checking for sys/types.h... yes
checking for unistd.h... yes
checking for grep that handles long lines and -e... /bin/grep
checking for egrep... /bin/grep -E
checking for library containing floor... none required
./configure: line 5653: syntax error: unexpected word (expecting ")")
bash-5.1# ls -lh configure
-rwxr-xr-x    1 root     root      236.0K Nov 25 14:44 configure
# bash-5.1# vi configure #注释5653: #IT_PROG_INTLTOOL(0.40.0)
bash-5.1# ./configure
checking for FM... no
configure: error: Package requirements (gthread-2.0 gio-unix-2.0 >= 2.18.0 glib-2.0 pango >= 1.20.0 libfm >= 1.0 gtk+-2.0 libfm-gtk >= 1.0.1) were not met:
Package 'pango', required by 'virtual:world', not found
Package 'gtk+-2.0', required by 'virtual:world', not found
Package 'libfm', required by 'virtual:world', not found
Package 'libfm-gtk', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.
Alternatively, you may set the environment variables FM_CFLAGS
and FM_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
bash-5.1# 

# deps
# https://pkgs.alpinelinux.org/packages?name=*gtk%2B*&branch=edge&repo=&arch=x86_64&maintainer=
  247  apk add pango-dev gtk+2.0-dev
  #pango,gtk无静态库
  246  find /usr/lib |grep pango
  248  find /usr/lib |grep gtk
  249  history |tail -9

# libfm: 有libfm-qt,无libfm-gtk
# https://pkgs.alpinelinux.org/packages?name=*libfm*&branch=edge&repo=&arch=x86_64&maintainer=
# https://hub.nuaa.cf/lxde/libfm


bash-5.1# apk add libfm-dev 
(1/24) Installing libexif (0.6.23-r0)
(2/24) Installing libfm-extra (1.3.1-r0)

# bash-5.1# ./configure
checking for GIO... yes
checking for FM... no
configure: error: Package requirements (gthread-2.0 gio-unix-2.0 >= 2.18.0 glib-2.0 pango >= 1.20.0 libfm >= 1.0 gtk+-2.0 libfm-gtk >= 1.0.1) were not met:
Package 'libfm-gtk', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.
Alternatively, you may set the environment variables FM_CFLAGS
and FM_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
bash-5.1# echo $?
1
bash-5.1# 
bash-5.1# apk add libfm-extra-dev
```

- ldd pcmanfm @ubt2004 apt-ins

```bash
# root@ten-vm1:/# ldd usr/bin/pcmanfm |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007f211ac76000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007f211aaf1000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007f21192d5000)
	libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007f2119795000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007f21192cd000)
	libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007f2119774000)
	libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007f2119a32000)
	libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007f21197af000)
	libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007f21197c1000)
	libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007f21197a2000)
	libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007f21197c6000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007f2119108000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2119dca000) ###
	libatk-1.0.so.0 => /lib/x86_64-linux-gnu/libatk-1.0.so.0 (0x00007f211a532000) ###
	libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007f2119789000) ###
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007f211920c000) ###
	libfm-gtk.so.4 => /lib/x86_64-linux-gnu/libfm-gtk.so.4 (0x00007f211aa85000) ###
	libfm.so.4 => /lib/x86_64-linux-gnu/libfm.so.4 (0x00007f211a34c000) ###
	libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007f211a40f000)
	libXcomposite.so.1 => /lib/x86_64-linux-gnu/libXcomposite.so.1 (0x00007f2119790000) ####
	libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007f21191b5000) ####
	libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007f211928a000) ####
	libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007f2119587000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007f2118ee5000)
	libdbus-glib-1.so.2 => /lib/x86_64-linux-gnu/libdbus-glib-1.so.2 (0x00007f211944b000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f2119d9a000)
	libexif.so.12 => /lib/x86_64-linux-gnu/libexif.so.12 (0x00007f2119403000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f211929f000)
	libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007f211934e000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007f21199d2000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007f211960e000)
	libgdk-x11-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0 (0x00007f211a570000)
	libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007f211a3e7000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007f2119fdf000)
	libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007f2119a3a000) ###
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007f211a109000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007f2118ec2000) ###
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007f211925d000) ###
	libgtk-x11-2.0.so.0 => /lib/x86_64-linux-gnu/libgtk-x11-2.0.so.0 (0x00007f211a62b000) ###
	libmenu-cache.so.3 => /lib/x86_64-linux-gnu/libmenu-cache.so.3 (0x00007f2119b8f000) ###
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007f211a55e000) ###
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f2119378000) ###
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007f2119059000) ###
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007f211957c000) ###
	libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007f2119478000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007f2119003000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f2119026000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f2119a40000)
	libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007f211a398000)
	libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007f2119a19000)
	libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007f211a16b000)####
	libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007f21193a3000) ####
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f21192db000) ####
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f2119122000)
	libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007f21196cd000) ####
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007f21195d6000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f2119fbc000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f211935c000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f211904f000)
	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f2119294000)
	libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007f21195c0000)
	libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007f21195cf000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007f2119da0000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f21195a4000)
	linux-vdso.so.1 (0x00007ffecac2a000)
```

- **libfm-gtk**

```bash
# libfm-gtk
bash-5.1# ./configure 
checking for valac... valac
configure: WARNING: Vala compiler not found or too old
configure: WARNING: you will not be able to compile Vala source files
configure: error: No Vala compiler found but it is required.

# vala
bash-5.1# apk add vala
checking for GTK... yes
checking for MENU_CACHE... no
configure: error: Package requirements (libmenu-cache >= 0.3.2) were not met:
Package 'libmenu-cache', required by 'virtual:world', not found
Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables MENU_CACHE_CFLAGS
and MENU_CACHE_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
bash-5.1# echo $?
1


bash-5.1# apk add menu-cache-dev
# bash-5.1# ./configure 
Libfm 1.3.2 Configuration Summary:
prefix:                                                 /usr/local
sysconfdir:                                             ${prefix}/etc
Enable compiler flags and other support for debugging:  no
Build udisks support (Linux only, experimental):        no
Build with libexif for faster thumbnail loading:        no
Build demo program src/demo/libfm-demo:                 no
Build old custom actions API (requires Vala):           yes
Large file support:                                     yes
GIO module for preferred apps (for glib < 2.28 only):   not required
Build libfm-gtk for Gtk+ version:                       2.0
Build API doc with gtk-doc (recommended for make dist): no
Warning: sysconfdir is not /etc.
Please consider passing --sysconfdir=/etc to configure.
Otherwise default config files will be installed to wrong place.
bash-5.1# 
bash-5.1# echo $?
0



# bash-5.1# make
make[4]: Entering directory '/mnt2/fk-libfm/src/modules'
  CC       vfs_menu_la-vfs-menu.lo
  CCLD     vfs-menu.la
/usr/bin/x86_64-alpine-linux-musl-ld: ../../src/.libs/libfm.a(libfm_la-fm-thumbnailer.o): warning: relocation against 'fm_thumbnailer_unref' in read-only section '.text'
/usr/bin/x86_64-alpine-linux-musl-ld: ../../src/.libs/libfm.a(libfm_la-fm-module.o): relocation R_X86_64_PC32 against symbol 'fm_modules_loaded' can not be used when making a shared object; recompile with -fPIC
/usr/bin/x86_64-alpine-linux-musl-ld: final link failed: bad value
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[4]: *** [Makefile:557: vfs-menu.la] Error 1
make[4]: Leaving directory '/mnt2/fk-libfm/src/modules'
make[3]: *** [Makefile:2899: all-recursive] Error 1
make[3]: Leaving directory '/mnt2/fk-libfm/src'
make[2]: *** [Makefile:1259: all] Error 2
make[2]: Leaving directory '/mnt2/fk-libfm/src'
make[1]: *** [Makefile:566: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fk-libfm'
make: *** [Makefile:468: all] Error 2
bash-5.1# 



# 改动态编译：OK
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
# export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++


# bash-5.1# make
make[3]: Entering directory '/mnt2/fk-libfm/data'
  ITMRG  libfm-pref-apps.desktop
  ITMRG  lxshortcut.desktop
make[3]: Leaving directory '/mnt2/fk-libfm/data'
make[2]: Leaving directory '/mnt2/fk-libfm/data'
make[2]: Entering directory '/mnt2/fk-libfm'
make[2]: Nothing to be done for 'all-am'.
make[2]: Leaving directory '/mnt2/fk-libfm'
make[1]: Leaving directory '/mnt2/fk-libfm'
bash-5.1# 
bash-5.1# 
bash-5.1# echo $?
0
```

- try02 /usr/local/lib/libfm-gtk.a

```bash
  885  find /usr/lib |grep libfm-gtk
  886  cd ../fk-libfm/
  895  env |grep FLAGS
  896  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
  898  ./configure 
  899  make
  900  make install
  
  901  find /usr/lib |grep libfm-gtk
  902  find /usr/lib |grep libfm
  903  find /usr/local/lib |grep libfm
  904  cp /usr/local/lib/libfm.a /usr/local/lib/libfm-gtk.a /usr/lib
  905  pwd
  
  906  cd ../pcmanfm/
  907  ./configure
  909  ls po/
  910  ls
  911  touch po/Makefile.in 
  913  touch po/Makefile.in.in
  914  ./configure

# bash-5.1# make
config.status: executing po/stamp-it commands
config.status: error: po/Makefile.in.in was not created by intltoolize.
make: *** [Makefile:345: Makefile] Error 1


# ubt2004: 1.3.1-1
bash-5.1# git remote -v
origin  https://hub.nuaa.cf/lxde/pcmanfm
* (HEAD detached at 1.3.2)

# dyn:make OK @v131
# 切换v131, autogen[生成po/Makefile.in.in]>> ./conf; make OK
  928  git checkout 1.3.1
  929  ls
  930  ls po
  931  cat po/Makefile.in.in 
  932  bash autogen.sh 
  933  ls
  934  cat po/Makefile.in.in 
  935  ./configure
  936  make
  937  ls
  938  ls src/
  939  ls -lh src/pcmanfm
  940  ldd src/pcmanfm
```

## static build

```bash
2 warnings generated.
mv -f .deps/pcmanfm-connect-server.Tpo .deps/pcmanfm-connect-server.Po
xx-clang  -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/gio-unix-2.0 -I/usr/include/libmount -I/usr/include/blkid -I/usr/include/pango-1.0 -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/fribidi -I/usr/include/uuid -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/local/include -I/usr/include/gtk-2.0 -I/usr/lib/gtk-2.0/include -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 -pthread  -DG_DISABLE_CAST_CHECKS -Wall -Werror-implicit-function-declaration  -Os -fomit-frame-pointer  -Wl,--strip-all -Wl,--as-needed -o pcmanfm pcmanfm-pcmanfm.o pcmanfm-app-config.o pcmanfm-main-win.o pcmanfm-tab-page.o pcmanfm-desktop.o pcmanfm-volume-manager.o pcmanfm-pref.o pcmanfm-single-inst.o pcmanfm-connect-server.o  -lX11  -lglib-2.0 -L/usr/local/lib -lglib-2.0 -lfm-gtk -lgtk-x11-2.0 -lgdk-x11-2.0 -lpangocairo-1.0 -latk-1.0 -lcairo -lgdk_pixbuf-2.0 -lpangoft2-1.0 -lpango-1.0 -lharfbuzz -lfontconfig -lfreetype -lglib-2.0 -lfm -lgthread-2.0 -pthread -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lintl   
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/src'
Making all in po
make[2]: Entering directory '/mnt2/_misc2/pcmanfm/po'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/po'
Making all in data
make[2]: Entering directory '/mnt2/_misc2/pcmanfm/data'
Making all in ui
make[3]: Entering directory '/mnt2/_misc2/pcmanfm/data/ui'
sed 's/<!--.*-->//' < about.glade | sed ':a;N;$!ba;s/ *\n *</</g' > about.ui
make[3]: Leaving directory '/mnt2/_misc2/pcmanfm/data/ui'
make[3]: Entering directory '/mnt2/_misc2/pcmanfm/data'
make[3]: Nothing to be done for 'all-am'.
make[3]: Leaving directory '/mnt2/_misc2/pcmanfm/data'
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/data'
make[2]: Entering directory '/mnt2/_misc2/pcmanfm'
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm'
make[1]: Leaving directory '/mnt2/_misc2/pcmanfm'
bash-5.1# ls -lh src/pcmanfm
-rwxr-xr-x    1 root     root      227.0K Nov 28 21:42 src/pcmanfm
bash-5.1# make LDFALGS="-static " ##LDFLAGS


2 warnings generated.
mv -f .deps/pcmanfm-connect-server.Tpo .deps/pcmanfm-connect-server.Po
xx-clang  -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/gio-unix-2.0 -I/usr/include/libmount -I/usr/include/blkid -I/usr/include/pango-1.0 -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/fribidi -I/usr/include/uuid -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/local/include -I/usr/include/gtk-2.0 -I/usr/lib/gtk-2.0/include -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 -pthread  -DG_DISABLE_CAST_CHECKS -Wall -Werror-implicit-function-declaration  -Os -fomit-frame-pointer  -static  -o pcmanfm pcmanfm-pcmanfm.o pcmanfm-app-config.o pcmanfm-main-win.o pcmanfm-tab-page.o pcmanfm-desktop.o pcmanfm-volume-manager.o pcmanfm-pref.o pcmanfm-single-inst.o pcmanfm-connect-server.o  -lX11  -lglib-2.0 -L/usr/local/lib -lglib-2.0 -lfm-gtk -lgtk-x11-2.0 -lgdk-x11-2.0 -lpangocairo-1.0 -latk-1.0 -lcairo -lgdk_pixbuf-2.0 -lpangoft2-1.0 -lpango-1.0 -lharfbuzz -lfontconfig -lfreetype -lglib-2.0 -lfm -lgthread-2.0 -pthread -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lintl   
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgtk-x11-2.0 #gtk+2.0-dev 无static
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgdk-x11-2.0 #gtk+2.0-dev
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -latk-1.0 #atk 无static
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgdk_pixbuf-2.0 #gdk-pixbuf-dev 无static
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpangocairo-1.0 # 	pango-dev 无static
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpangoft2-1.0 #
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpango-1.0 #
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfontconfig
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:466: pcmanfm] Error 1
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/src'
make[1]: *** [Makefile:397: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/pcmanfm'
make: *** [Makefile:338: all] Error 2
bash-5.1# make LDFLAGS="-static "


# 已装
# atk: libatk-1.0
# apk add gdk-pixbuf-dev pango-dev atk

# bash-5.1# apk list |egrep atk
atkmm2.36-dev-2.36.1-r0 x86_64 {atkmm2.36} (LGPL-2.0-or-later)
atkmm-2.28.0-r1 x86_64 {atkmm} (LGPL-2.0-or-later)
atk-dev-2.36.0-r0 x86_64 {atk} (LGPL-2.0-or-later) [installed]
# bash-5.1# apk list |grep gdk-pixbuf
gdk-pixbuf-dev-2.42.8-r0 x86_64 
# bash-5.1# apk list |grep gtk+2.0
gtk+2.0-2.24.33-r0 x86_64 {gtk+2.0} (LGPL-2.0-or-later) [installed]
gtk+2.0-dev-2.24.33-r0

# repos @gnome
git clone https://hub.nuaa.cf/GNOME/atk #3.29 MiB 1985> ATK_2_36_0 1943
git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf #177.02 MiB 6226> 2.42.8 6113
git clone https://hub.nuaa.cf/GNOME/gtk #644.58 MiB 78343> 2.24.33 21885
git checkout 2.24.33
# https://hub.nuaa.cf/genesi/gtk2
git clone https://hub.nuaa.cf/lxde/menu-cache #297 commits

```

- **try04** static build with `static-deps`


```bash
bash-5.1# pwd
/mnt2/_misc2/pcmanfm
# bash-5.1# make LDFLAGS="-static "
make[2]: Entering directory '/mnt2/_misc2/pcmanfm/src'
xx-clang  -I/usr/include/glib-2.0 -I/usr/lib/glib-2.0/include -I/usr/include/gio-unix-2.0 -I/usr/include/libmount -I/usr/include/blkid -I/usr/include/pango-1.0 -I/usr/include/harfbuzz -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/fribidi -I/usr/include/uuid -I/usr/include/cairo -I/usr/include/pixman-1 -I/usr/local/include -I/usr/include/gtk-2.0 -I/usr/lib/gtk-2.0/include -I/usr/include/gdk-pixbuf-2.0 -I/usr/include/atk-1.0 -pthread  -DG_DISABLE_CAST_CHECKS -Wall -Werror-implicit-function-declaration  -Os -fomit-frame-pointer  -static  -o pcmanfm pcmanfm-pcmanfm.o pcmanfm-app-config.o pcmanfm-main-win.o pcmanfm-tab-page.o pcmanfm-desktop.o pcmanfm-volume-manager.o pcmanfm-pref.o pcmanfm-single-inst.o pcmanfm-connect-server.o  -lX11  -lglib-2.0 -L/usr/local/lib -lglib-2.0 -lfm-gtk -lgtk-x11-2.0 -lgdk-x11-2.0 -lpangocairo-1.0 -latk-1.0 -lcairo -lgdk_pixbuf-2.0 -lpangoft2-1.0 -lpango-1.0 -lharfbuzz -lfontconfig -lfreetype -lglib-2.0 -lfm -lgthread-2.0 -pthread -lglib-2.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lintl   
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpangocairo-1.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpangoft2-1.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lpango-1.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfontconfig
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:466: pcmanfm] Error 1
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/src'
make[1]: *** [Makefile:397: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/pcmanfm'
make: *** [Makefile:338: all] Error 2



# 补充pango, fontconfig-static两组依赖;
# bash-5.1# ln -s /mnt2/docker-x11base/compile/src /src
bash-5.1# bash /src/openbox/build.sh pango
bash-5.1# find /usr/lib |grep pango |grep "\.a$"
/usr/lib/libpangoxft-1.0.a
/usr/lib/libpango-1.0.a
/usr/lib/libpangocairo-1.0.a
/usr/lib/libpangoft2-1.0.


bash-5.1# find /usr/lib |grep fontconfig
/usr/lib/girepository-1.0/fontconfig-2.0.typelib
/usr/lib/pkgconfig/fontconfig.pc
/usr/lib/libfontconfig.so.1.12.0
/usr/lib/libfontconfig.so
/usr/lib/libfontconfig.so.1
# bash-5.1# apk add fontconfig-static
  fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
  fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
  (1/1) Installing fontconfig-static (2.13.1-r4)
  OK: 984 MiB in 362 packages
bash-5.1# find /usr/lib |grep fontconfig
/usr/lib/girepository-1.0/fontconfig-2.0.typelib
/usr/lib/pkgconfig/fontconfig.pc
/usr/lib/libfontconfig.a ##
/usr/lib/libfontconfig.so.1.12.0
/usr/lib/libfontconfig.so
/usr/lib/libfontconfig.so.1

# 再编译
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:1081: undefined reference to 'pcre_get_stringnumber'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:466: pcmanfm] Error 1
make[2]: Leaving directory '/mnt2/_misc2/pcmanfm/src'
make[1]: *** [Makefile:397: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/pcmanfm'
make: *** [Makefile:338: all] Error 2
bash-5.1# pwd
/mnt2/_misc2/pcmanfm
bash-5.1# make LDFLAGS="-static "

###
# make LDFLAGS="-static -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS"
# 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
bash-5.1# make LDFLAGS="-static -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-ft-font.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2015:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2700:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-mask-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-matrix.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-region.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-core-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-display.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-render-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-screen.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface-shm.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-visual.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fccache.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fchash.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fcxml.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftgzip.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(giomodule.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gunixmounts.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gzlibdecompressor.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgobject-2.0.a(gclosure.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libharfbuzz.a(hb-graphite2.cc.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libpango-1.0.a(pango-bidi-type.c.o):



# 
LIBS=" -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS" ./configure
make LDFLAGS="-static "


# libxrandr
bash /src/openbox/build.sh libxrandr
bash-5.1# find /usr/lib |grep Xrandr
/usr/lib/libXrandr.a ##
/usr/lib/libXrandr.la ##
/usr/lib/libXrandr.so.2.2.0
/usr/lib/libXrandr.so
/usr/lib/libXrandr.so.2

# bash-5.1# echo $OB_LIBS 
-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
# bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-ft-font.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2015:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2700:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-mask-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-matrix.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-region.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-render-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface-shm.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fccache.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fchash.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(giomodule.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gunixmounts.c.o):
```


```bash
# -lmenu-cache 无静态库
ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
LIBS=" -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex1" ./configure
make LDFLAGS="-static "
# bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-ft-font.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2015:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-compositor.o):/home/buildozer/aports/main/cairo/src/cairo-1.16.0/src/cairo-image-compositor.c:2700:
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-source.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-image-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-mask-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-matrix.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-region.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-render-compositor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface-shm.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-xlib-surface.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fccache.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fchash.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(giomodule.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gunixmounts.c.o):
# bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
       16        16      1682


# LDD-DEPS
# menu-cache
ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -lmenu-cache -luuid -lmount -lpcre -lblkid -lXcomposite"
ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
LIBS=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1" ./configure
# make LDFLAGS="-static "
  # Xdamage, dbus, fm-gtk, fm
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f2119dca000) ###
	libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007f2119789000) ###
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007f211920c000) ###
	libfm-gtk.so.4 => /lib/x86_64-linux-gnu/libfm-gtk.so.4 (0x00007f211aa85000) ###
	libfm.so.4 => /lib/x86_64-linux-gnu/libfm.so.4 (0x00007f211a34c000) ###
  # gmodule-2.0, gobject-2.0, gpg-error, graphite2, gtk-x11-2.0, menu-cache, pangocairo-1.0, selinux, systemd, thai
  libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007f2119a3a000) ###
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007f211a109000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007f2118ec2000) ###
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007f211925d000) ###
	libgtk-x11-2.0.so.0 => /lib/x86_64-linux-gnu/libgtk-x11-2.0.so.0 (0x00007f211a62b000) ###
	libmenu-cache.so.3 => /lib/x86_64-linux-gnu/libmenu-cache.so.3 (0x00007f2119b8f000) ###
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007f211a55e000) ###
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f2119378000) ###
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007f2119059000) ###
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007f211957c000) ###

# err-list 少了一项;
bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
       15        15      1592
# -lpixman-1
bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
        3         3       269
bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fccache.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fchash.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gunixmounts.c.o):

# 
# + -ljpeg
# + -lmenu-cache -luuid
bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u |wc
        1         1        92
bash-5.1# make LDFLAGS="-static " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libgio-2.0.a(gunixmounts.c.o):

# 
# -lmount -lpcre
# -lblkid -lXcomposite


# 静态编译OK;
# make
bash-5.1# echo $?
0
bash-5.1# ls -lh src/pcmanfm
-rwxr-xr-x    1 root     root       37.1M Nov 29 15:41 src/pcmanfm
bash-5.1# ldd src/pcmanfm
/lib/ld-musl-x86_64.so.1: src/pcmanfm: Not a valid dynamic program

```

- build.sh执行> err手动调试

```bash
# gtk编译后; >> pcmanfm构建出错
# ff
# 如下make内改LIBS可影响err;
bash-5.1# make LDFLAGS="-static -lXinerama" LIBS="-LXinerama -lpcre" 2>&1

# try2
	OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -lmenu-cache -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1" 

	make LDFLAGS="-static " LIBS="-lXinerama $LIBS0" 2>&1
	make LDFLAGS="-static " LIBS="-lXinerama -lXfixes $LIBS0" 2>&1
	# https://forum.lazarus.freepascal.org/index.php?topic=34814.0
	# undefined reference to 'XRRFreeMonitors'
	make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1 ##过了


```