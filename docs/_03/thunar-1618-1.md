
## thunar-1.6.18

- try1 `exo> libxfce4ui > xfconf> dbus-glib dbus-1 xfce4util`

```bash

# https://github.com/xfce-mirror/thunar/tree/thunar-1.6.18
# Thunar depends on the following packages:
 - perl 5.6 or above
 - GTK+ 2.24.0 or above
 - GLib 2.30.0 or above
 - exo 0.10.0 or above
 - intltool 0.30 or above
# Thunar can optionally use the following packages:
 - D-Bus 0.34 or above (strongly suggested)
 - libstartup-notification 0.4 or above
 - xfce4-panel 4.10.0 or above (for the trash applet)
 - xfconf-query

bash-5.1# apk list |grep intlt
intltool-0.51.0-r4 x86_64 {intltool} (GPL-2.0) [installed]
bash-5.1# apk list |grep exo
exo-dev-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]
bash-5.1# apk list |grep glib-dev
glib-dev-2.70.5-r0 x86_64 {glib} (LGPL-2.1-or-later) [installed]
bash-5.1# apk list |grep perl-5
perl-5.34.2-r0 x86_64 {perl} (Artistic-Perl OR GPL-1.0-or-later) [installed]
perl-dev-5.34.2-r0 x86_64 {perl} (Artistic-Perl OR GPL-1.0-or-later)

  137  git clone https://hub.yzuu.cf/xfce-mirror/thunar
  138  cd thunar/
  141  git checkout thunar-1.6.18
  143  ./autogen.sh 
  145  apk add xfce4-dev-tools
  146  ./autogen.sh  #exo-1
  147  echo $?
  148  apk add exo-dev #4.18
  149  ./autogen.sh 
  150  history

# https://github.com/xfce-mirror/exo/tree/exo-0.10.0 #1381 2012.12.3
https://github.com/xfce-mirror/exo/tree/exo-0.12.11  #2466 2019.12.19
# master: 2851

  163  git clone https://hub.yzuu.cf/xfce-mirror/exo
  164  cd exo/
  165  git checkout exo-0.12.11
  166  ls
  167  ./autogen.sh 
bash-5.1# ./autogen.sh
checking for libxfce4ui-2 >= 4.12.0... not found
*** The required package libxfce4ui-2 was not found on your system.
*** Please install libxfce4ui-2 (atleast version 4.12.0) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.
# https://pkgs.alpinelinux.org/packages?name=*xfce4ui*&branch=edge&repo=&arch=x86_64&maintainer=  ##4.18


# https://github.com/xfce-mirror/libxfce4ui/tree/libxfce4ui-4.12.1
  173  git clone https://hub.yzuu.cf/xfce-mirror/libxfce4ui
  174  cd libxfce4ui/
  175  git checkout libxfce4ui-4.12.1
  176  ls
  177  ./autogen.sh 
bash-5.1# ./autogen.sh
checking for libxfconf-0 >= 4.12.0... not found
*** The required package libxfconf-0 was not found on your system.
*** Please install libxfconf-0 (atleast version 4.12.0) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.

# https://github.com/xfce-mirror/xfconf/tree/xfconf-4.12.1
bash-5.1# ./autogen.sh
checking for dbus-glib-1 >= 0.84... not found
*** The required package dbus-glib-1 was not found on your system.
*** Please install dbus-glib-1 (atleast version 0.84) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.

  180  git clone https://hub.yzuu.cf/xfce-mirror/xfconf
  181  cd xfconf/
  182  git checkout xfconf-4.12.1
  184  ./autogen.sh 
  185  apk add dbus-glib-dev
  186  ./autogen.sh 
  187  make
bash-5.1# make
10 warnings generated.
  CCLD     xfconfd
# make
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -ldbus-glib-1
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -ldbus-1
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lxfce4util
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:569: xfconfd] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[2]: *** [Makefile:484: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[1]: *** [Makefile:484: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf'
make: *** [Makefile:416: all] Error 2

# https://github.com/sailfishos-mirror/dbus-glib #@master
bash-5.1# make
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -ldbus-1
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:713: tests/test-30574] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus-glib/dbus-gmain'
make[1]: *** [Makefile:535: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus-glib'
make: *** [Makefile:435: all] Error 2


# https://github.com/sailfishos-mirror/dbus/tree/dbus-1.10.8 #4425 2016.3.8
bash-5.1# make 
In file included from ../dbus/dbus-sysdeps.h:56:
/usr/include/sys/poll.h:1:2: error: redirecting incorrect #include <sys/poll.h> to <poll.h> [-Werror,-W#warnings]
#warning redirecting incorrect #include <sys/poll.h> to <poll.h>
 ^
1 error generated.
make[3]: *** [Makefile:1120: dbus-test-main.o] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
make[2]: *** [Makefile:919: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
make[1]: *** [Makefile:633: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus'
make: *** [Makefile:529: all] Error 2

# https://github.com/sailfishos-mirror/dbus/tree/dbus-1.12.18 #5269 2020.6.2
# https://github.com/sailfishos-mirror/dbus/tree/dbus-1.11.16 #5032 1017.7.27
bash-5.1# ./autogen.sh 
autoconf failed - version 2.5x is probably required


# https://github.com/sailfishos-mirror/dbus/tree/dbus-1.10.32
bash-5.1# make
make  all-recursive
make[1]: Entering directory '/mnt2/_misc2-2/_xfce4/_deps/dbus'
Making all in dbus
make[2]: Entering directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
make  all-am
make[3]: Entering directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
  CC       dbus-test-main.o
error: unknown warning option '-Werror=cast-function-type'; did you mean '-Werror=bad-function-cast'? [-Werror,-Wunknown-warning-option]
error: unknown warning option '-Wno-cast-function-type'; did you mean '-Wno-bad-function-cast'? [-Werror,-Wunknown-warning-option]
make[3]: *** [Makefile:1120: dbus-test-main.o] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
make[2]: *** [Makefile:919: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus/dbus'
make[1]: *** [Makefile:633: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/dbus'
make: *** [Makefile:529: all] Error 2
# bash-5.1# env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
LDFLAGS=-Wl,--as-needed --static -static -Wl,--strip-all
CPPFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer


# dbus @master: meson build
bash-5.1# meson build
OSError: [Errno 8] Exec format error: '/usr/bin/xsltproc'

bash-5.1# apk add libxslt
OK: 985 MiB in 351 packages
bash-5.1# apk del libxslt
World updated, but the following packages are not removed due to:
  libxslt: glib-dev vala exo-dev xfce4-dev-tools gtk-doc gtk+2.0-dev librsvg-dev dbus-glib-dev gobject-introspection-dev cairo-dev
           harfbuzz-dev

bash-5.1# apk add dbus-dev   ##1.14.10-r0
OK: 985 MiB in 351 packages

# https://pkgs.alpinelinux.org/packages?name=*dbus-*&branch=edge&repo=&arch=x86_64&maintainer=
bash-5.1# apk add dbus-libs
OK: 985 MiB in 351 packages
bash-5.1# find /usr/lib |grep dbus
/usr/lib/libdbus-1.so
/usr/lib/libdbus-glib-1.so.2.3.5
/usr/lib/libdbus-glib-1.so
/usr/lib/dbus-1.0
/usr/lib/dbus-1.0/include
/usr/lib/dbus-1.0/include/dbus
/usr/lib/dbus-1.0/include/dbus/dbus-arch-deps.h
/usr/lib/libdbus-glib-1.so.2
/usr/lib/pkgconfig/dbus-glib-1.pc
/usr/lib/pkgconfig/dbus-1.pc
/usr/lib/libdbus-1.so.3.19.16
/usr/lib/libdbus-1.so.3


    Building XML docs         : NO
    Building launchd support  : NO
    Building dbus-daemon      : YES
    Building tools            : YES
    System bus socket         : /var/local/run/dbus/system_bus_socket
    System bus address        : "unix:path=/var/local/run/dbus/system_bus_socket"
    System bus PID file       : /var/local/run/dbus/pid
    Session bus listens on    : unix:tmpdir=/tmp
    Session clients connect to: "autolaunch:"
    System bus user           : messagebus
    Session bus services dir  : /usr/local/share/dbus-1/services
    Tests socket dir          : /tmp

bash-5.1# history |tail -16
  244  apk add libxslt
  246  apk del libxslt
  247  \cp -a /mnt2/xsltproc00 /usr/bin/xsltproc
  248  ls
  249  meson build
  250  echo $?
  251  history |tail -16
Found ninja-1.9 at /usr/bin/ninja
bash-5.1# echo $?
0


# bash-5.1# ninja -C build
ninja: job failed: xx-clang  -o test/test-sd-activation test/test-sd-activation.p/sd-activation.c.o -Wl,--as-needed -Wl,--no-undefined -Wl,--as-needed --static -static -Wl,--strip-all -Os -fomit-frame-pointer -Os -fomit-frame-pointer '-Wl,-rpath,$ORIGIN/../dbus' -Wl,-rpath-link,/mnt2/_misc2-2/_xfce4/_deps/dbus/build/dbus -Wl,--start-group test/libdbus-testutils.a dbus/libdbus-1.so.3.38.0 dbus/libdbus-internal.a /usr/lib/libglib-2.0.a /usr/lib/libintl.a /usr/lib/libgio-2.0.a /usr/lib/libgobject-2.0.a -Wl,--end-group -pthread
/usr/bin/x86_64-alpine-linux-musl-ld: cannot use executable file 'dbus/libdbus-1.so.3.38.0' as input to a link
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
ninja: subcommands failed
# bash-5.1# find |grep dbus-1
./build/dbus/libdbus-1.so
./build/dbus/libdbus-1.so.3.38.0
./build/dbus/libdbus-1.so.3
./build/meson-private/dbus-1.pc
./dbus-1.pc
./dbus-1.pc.in
bash-5.1# find |grep dbus-1.a
```

- try2: dbus, dbus-glib `不管错误，.a库已生成`; `exo> libxfce4ui > xfconf`

```bash
# dbus @master>> meson build; [meson/cmake]

# ref gdk-pixbuf
  # 去除xsltproc;
  dst=/usr/bin/xsltproc
  mv $dst ${dst}00
  touch $dst; chmod +x $dst
  echo -e "!/bin/bash\n echo 123" > $dst

# 手动拷贝/usr/bin/xsltproc00 替换回去



# [meson args]
# https://github.com/sailfishos-mirror/dbus/blob/master/INSTALL  
bash-5.1# history |tail -20
  269  meson compile -C dbus/
  270  cd ..
  271  meson  configure -h
  272* meson configure build/ 
  273  meson configure build/ 2>&1
  274  meson configure build/ 2>&1 |grep test
  275  meson configure build/ -Dchecks=false -Dmodular_tests=disabled
  276  ninja  -C build
  277  meson configure build/ 2>&1 |grep static
  278  meson configure build/ -Dchecks=false -Dmodular_tests=disabled -Ddefault_library=both
  279  ninja  -C build
  280  find |grep dbus-1
  281  find |grep dbus-1.a
  282  ls -lh ./build/dbus/libdbus-1.a.p
  283  ls -lh ./build/dbus/libdbus-1.a

  # -Ddefault_library=static  
  284  meson configure build/ -Dchecks=false -Dmodular_tests=disabled -Ddefault_library=static  ##-Ddefault_library=static
  285  ninja  -C build
  286  find ../ |grep CMakeLists.txt
  287  ls -lh ./build/dbus/libdbus-1.a ##生成了;
  288  history |tail -20


# bash-5.1# ninja  -C build
[172/172] Linking target bus/dbus-daemon
ninja: job failed: xx-clang  -o tools/dbus-launch tools/dbus-launch.p/dbus-launch.c.o tools/dbus-launch.p/dbus-launch-x11.c.o tools/dbus-launch.p/tool-common.c.o -Wl,--as-needed -Wl,--no-undefined -Wl,--as-needed --static -static -Wl,--strip-all -Os -fomit-frame-pointer -Os -fomit-frame-pointer -Wl,--start-group dbus/libdbus-1.a /usr/lib/libX11.a -Wl,--end-group -pthread
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `require_socket':
xcb_io.c:(.text+0x54a): undefined reference to 'xcb_take_socket'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_event':
xcb_io.c:(.text+0x60b): undefined reference to 'xcb_poll_for_queued_event'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_io.c:(.text+0x612): undefined reference to 'xcb_poll_for_event'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `poll_for_response':
xcb_io.c:(.text+0x7aa): undefined reference to 'xcb_poll_for_reply64'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XSend':
xcb_io.c:(.text+0x9db): undefined reference to 'xcb_writev'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XEventsQueued':
xcb_io.c:(.text+0xab5): undefined reference to 'xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReadEvents':
xcb_io.c:(.text+0xbc5): undefined reference to 'xcb_wait_for_event'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_io.c:(.text+0xca5): undefined reference to 'xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XAllocIDs':
xcb_io.c:(.text+0xd88): undefined reference to 'xcb_generate_id'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_io.o): in function `_XReply':
xcb_io.c:(.text+0xf37): undefined reference to 'xcb_wait_for_reply64'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `OutOfMemory':
OpenDis.c:(.text+0x316): undefined reference to 'xcb_disconnect'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(OpenDis.o): in function `XOpenDisplay':
OpenDis.c:(.text+0x784): undefined reference to 'xcb_get_setup'
/usr/bin/x86_64-alpine-linux-musl-ld: OpenDis.c:(.text+0xc1b): undefined reference to 'xcb_get_maximum_request_length'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(xcb_disp.o): in function `_XConnectXCB':
xcb_disp.c:(.text+0x153): undefined reference to 'xcb_parse_display'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x19b): undefined reference to 'xcb_connect_to_display_with_auth_info'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1a7): undefined reference to 'xcb_connect'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1c7): undefined reference to 'xcb_get_file_descriptor'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1e3): undefined reference to 'xcb_generate_id'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x25c): undefined reference to 'xcb_connection_has_error'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libX11.a(ClDisplay.o): in function 'XCloseDisplay':
ClDisplay.c:(.text+0xbb): undefined reference to 'xcb_disconnect'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
ninja: subcommand failed
# bash-5.1# ls -lh ./build/dbus/libdbus-1.a
-rw-r--r--    1 root     root        1.8M Dec 24 06:54 ./build/dbus/libdbus-1.a

# bash-5.1# \cp -a ./build/dbus/libdbus-1.a /usr/lib/
bash-5.1# find |grep dbus-glib
./dbus/.libs/libdbus-glib-1.la
./dbus/.libs/libdbus-glib-1.lai
./dbus/.libs/dbus-glib.o
./dbus/.libs/libdbus-glib-1.a ##
bash-5.1# history |tail -20
  288  history |tail -20
  289  \cp -a ./build/dbus/libdbus-1.a /usr/lib/
  290  pwd
  291  cd ..
  292  ls
  293  cd dbus-glib/
  294  ls
  295  make 
  296  apk list |grep glib
  297  apk list |grep glib-dev
  298  apk list |grep glib- |grep static
  299  apk list |grep pcre
  300  apt install pcre2-dev
  301  apk add pcre2-dev
  302  make 
  303  apk add pcre-dev
  304  make 
  305  ls
  306  find |grep dbus-glib
  307  history |tail -20
bash-5.1# 

bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/xfconf
bash-5.1# make
make[3]: Entering directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
  CCLD     xfconfd
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lxfce4util
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:569: xfconfd] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[2]: *** [Makefile:484: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[1]: *** [Makefile:484: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf'
make: *** [Makefile:416: all] Error 2


# https://github.com/xfce-mirror/libxfce4util/tree/libxfce4util-4.12.1 #641 @2015.3.1
bash-5.1# find /usr/lib /usr/local/lib |grep libxfce4util
/usr/lib/libxfce4util.so.7
/usr/lib/libxfce4util.so.7.0.0
/usr/lib/pkgconfig/libxfce4util-1.0.pc
/usr/lib/libxfce4util.so
/usr/local/lib/libxfce4util.a
/usr/local/lib/pkgconfig/libxfce4util-1.0.pc
/usr/local/lib/libxfce4util.la
bash-5.1# 
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/libxfce4util
bash-5.1# history |tail -20
  323  git clone https://hub.yzuu.cf/xfce-mirror/libxfce4util
  324  cd libxfce4util/
  326  git checkout libxfce4util-4.12.1
  328  ./autogen.sh 
  329  make
  330  echo $?
  331  make install
  332  find /usr/lib /usr/local/lib |grep libxfce4util


# make xfconf:
make[3]: Entering directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
  CCLD     xfconfd
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libdbus-glib-1.a(dbus-gobject.o): in function `dbus_g_connection_register_g_object':
...
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:1963: undefined reference to 'pcre_dfa_exec'
/usr/bin/x86_64-alpine-linux-musl-ld: /home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:1994: undefined reference to 'pcre_free'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o): in function `g_regex_get_string_number':
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:2033: undefined reference to 'pcre_get_stringnumber'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o): in function `get_matched_substring_number':
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:1081: undefined reference to 'pcre_get_stringnumber'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:569: xfconfd] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[2]: *** [Makefile:484: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf/xfconfd'
make[1]: *** [Makefile:484: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/xfconf'
make: *** [Makefile:416: all] Error 2
bash-5.1# find /usr/lib /usr/local/lib |grep libpcre

bash-5.1# find |grep xfconf |grep "\.a$"
./xfconf/.libs/libxfconf-0.a
./common/.libs/libxfconf-common.a
./common/.libs/libxfconf-gvaluefuncs.a

# try直接手动拷贝到lib;
bash-5.1# cp -a ./xfconf/.libs/libxfconf-0.a /usr/lib/


# [libxfce4ui]
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/libxfce4ui
bash-5.1# ./autogen.sh
checking pkg-config is at least version 0.9.0... yes
checking for libxfconf-0 >= 4.12.0... not found
*** The required package libxfconf-0 was not found on your system.   ##libxfconf-0 (atleast version 4.12.0)
*** Please install libxfconf-0 (atleast version 4.12.0) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.

# apk add: xfconf-dev-4.16
bash-5.1# apk list |grep xfconf
xfconf-doc-4.16.0-r0 x86_64 {xfconf} (GPL-2.0-only)
xfconf-dev-4.16.0-r0 x86_64 {xfconf} (GPL-2.0-only)
xfconf-4.16.0-r0 x86_64 {xfconf} (GPL-2.0-only)
xfconf-lang-4.16.0-r0 x86_64 {xfconf} (GPL-2.0-only)
bash-5.1# apk add xfconf-dev
(1/2) Installing xfconf (4.16.0-r0)
(2/2) Installing xfconf-dev (4.16.0-r0)


# libxfce4ui: autogen.sh过了;
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/libxfce4ui
# bash-5.1# ./autogen.sh 
config.status: executing default-1 commands
config.status: executing po/stamp-it commands
Build Configuration:
* Glade Interface Designer:  no
* Keyboard library support:  yes
* Startup notification:      yes
* X11 session management:    no
* Debug support:             minimum
* GNU Visibility:            yes
* Vendor:                    none
* Manual website:            http://docs.xfce.org/help.php
Now type "make" to compile.
# bash-5.1# echo $?
0

# make
# make install; ERR:
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/libxfce4ui
bash-5.1# make install
ftbzip2.c:(.text+0x1fe): undefined reference to 'BZ2_bzDecompressEnd'
/usr/bin/x86_64-alpine-linux-musl-ld: ftbzip2.c:(.text+0x24b): undefined reference to 'BZ2_bzDecompressInit'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o): in function `FT_Stream_OpenBzip2':
ftbzip2.c:(.text+0x48d): undefined reference to 'BZ2_bzDecompressInit'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:555: xfce4-about] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/libxfce4ui/xfce4-about'
make[1]: *** [Makefile:726: install] Error 2
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/libxfce4ui/xfce4-about'
make: *** [Makefile:520: install-recursive] Error 1
bash-5.1# ls
AUTHORS              THANKS               config.h.in          depcomp              intltool-update.in   stamp-h1
COPYING              TODO                 config.log           docs                 libtool              test-driver
INSTALL              aclocal.m4           config.status        glade                libxfce4kbd-private  xfce4-about
Makefile             autogen.sh           config.sub           gtk-doc.make         libxfce4ui
Makefile.am          autom4te.cache       configure            icons                ltmain.sh
Makefile.in          compile              configure.ac         install-sh           m4
NEWS                 config.guess         configure.ac.in      intltool-extract.in  missing
README               config.h             configure~           intltool-merge.in    po

# bash-5.1# find |grep libxfce4ui |grep "\.a$"
./libxfce4ui/.libs/libxfce4ui-1.a
./libxfce4ui/.libs/libxfce4ui-2.a
bash-5.1# cp ./libxfce4ui/.libs/libxfce4ui-1.a /usr/lib/


# [exo] autogen.sh过了
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/exo
bash-5.1# ./autogen.sh
config.status: executing libtool commands
config.status: executing default-1 commands
config.status: executing po/stamp-it commands
Build Configuration:
* Debug Support:        minimum
* GNU Visibility:       yes
* GTK+ 2 Support:       yes
Now type "make" to compile.


bash-5.1# make
  CCLD     exo-desktop-item-edit
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgtk-3 ##
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgdk-3
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:537: exo-desktop-item-edit] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/exo-desktop-item-edit'
make[1]: *** [Makefile:531: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo'
make: *** [Makefile:463: all] Error 2



# exo-0.10.0
bash-5.1# history |tail -15
  372  cd exo/
  374  ./autogen.sh 
  377  make
  378  git branch
  #
  379  git checkout exo-0.10.0
  381  make clean
  382  ./autogen.sh 
  383  make
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o): in function `g_regex_get_string_number':
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:2033: undefined reference to 'pcre_get_stringnumber'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libglib-2.0.a(gregex.c.o): in function `get_matched_substring_number':
/home/buildozer/aports/main/glib/src/glib-2.70.5/output/../glib/gregex.c:1081: undefined reference to 'pcre_get_stringnumber'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:529: exo-desktop-item-edit] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/exo-desktop-item-edit'
make[1]: *** [Makefile:527: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo'
make: *** [Makefile:459: all] Error 2


bash-5.1# find |grep exo |grep "\.a$"
./exo/.libs/libexo-2.a
./exo/.libs/libexo-1.a

# bash-5.1# cp ./exo/.libs/libexo-1.a /usr/lib/



# [thunar]
bash-5.1# pwd
/mnt2/_misc2-2/_xfce4/thunar
# bash-5.1# ./autogen.sh
checking pkg-config is at least version 0.9.0... yes
checking for exo-1 >= 0.10.0... not found
*** The required package exo-1 was not found on your system.
*** Please install exo-1 (atleast version 0.10.0) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.


# bash-5.1# apk list |grep exo
exo-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) ##
exo-doc-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later)
exo-libs-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]
exo-lang-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later)
exo-dev-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]
# bash-5.1# apk add exo
(1/3) Installing libgtop (2.40.0-r0)
(2/3) Installing libxfce4ui (4.16.1-r0)
(3/3) Installing exo (4.16.2-r0)
Executing busybox-1.34.1-r7.trigger
Executing gtk-update-icon-cache-2.24.33-r0.trigger
OK: 990 MiB in 362 packages

# bash-5.1# ./autogen.sh  ##apk装后，还是找不到;
checking for exo-1 >= 0.10.0... not found
*** The required package exo-1 was not found on your system.
*** Please install exo-1 (atleast version 0.10.0) or adjust
```

- try3: LDFLAGS drop `--static`

```bash
# STATIC
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++


50 warnings generated.
  CCLD     libexo-1.la
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libcairo.a(cairo-rectangular-scan-converter.o): relocation R_X86_64_TPOFF32 against 'sweep_line.1' can not be used when making a shared object; recompile with -fPIC
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:865: libexo-1.la] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/exo'
make[2]: *** [Makefile:791: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/exo'
make[1]: *** [Makefile:527: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo'
make: *** [Makefile:459: all] Error 2
bash-5.1# history |tail -12
  395  apk list |grep exo
  396  apk add exo
  397  ./autogen.sh 
  398  cd -
  399  cd exo/
  400  export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
  401  make
  402  make clean
  403  ls
  404  ./autogen.sh 
  405  make


# so-ex 改回;
find /usr/lib /usr/local/lib |grep "so-ex$" |while read one; do echo $one; n2=$(echo $one |sed "s/so-ex/so/g"); \cp -a $one $n2; done


bash-5.1# echo $?
2
# make
Making all in docs
make[2]: Entering directory '/mnt2/_misc2-2/_xfce4/exo/docs'
Making all in reference
make[3]: Entering directory '/mnt2/_misc2-2/_xfce4/exo/docs/reference'
xsltproc -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl exo-csource.xml
I/O error : Attempt to load network entity http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl
warning: failed to load external entity "http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl"
cannot parse http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl
make[3]: *** [Makefile:984: exo-csource.1] Error 4
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/docs/reference'
make[2]: *** [Makefile:439: all-recursive] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/docs'
make[1]: *** [Makefile:527: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo'
make: *** [Makefile:459: all] Error 2
bash-5.1# 

# ref gdk-pixbuf
  # 去除xsltproc;
  dst=/usr/bin/xsltproc
  mv $dst ${dst}00
  touch $dst; chmod +x $dst
  echo -e "!/bin/bash\n echo 123" > $dst

# make 过了; 
# make install err;
make[3]: Nothing to be done for 'install-exec-am'.
Nothing to install
xsltproc -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl exo-csource.xml
123
xsltproc -nonet http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl exo-open.xml
123
 ../.././install-sh -c -d '/usr/local/share/man/man1'
 /usr/bin/install -c -m 644 ./exo-csource.1 ./exo-open.1 '/usr/local/share/man/man1'
install: can't stat './exo-csource.1': No such file or directory
install: can't stat './exo-open.1': No such file or directory
make[3]: *** [Makefile:577: install-man1] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/docs/reference'
make[2]: *** [Makefile:674: install-am] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/docs/reference'
make[1]: *** [Makefile:439: install-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/exo/docs'
make: *** [Makefile:527: install-recursive] Error 1
bash-5.1# echo $?
2

bash-5.1# apk list -I |grep exo
exo-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]
exo-libs-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]
exo-dev-4.16.2-r0 x86_64 {exo} (GPL-2.0-or-later AND LGPL-2.1-or-later) [installed]


# thunar: autogen.sh过了;
bash-5.1# ./autogen.sh
config.status: executing default-1 commands
config.status: executing po/stamp-it commands
Build Configuration:
* D-BUS support:                      yes
* GIO UNIX features:                  yes
* GUDev (required for thunar-volman): no
* Mount notification support:         no
* Debug Support:                      minimum
Additional Plugins:
* Advanced Properties:                yes
* Simple Builtin Renamers:            yes
* Trash Panel Applet:                 no
* User Customizable Actions:          yes
* Wallpaper support:                  yes
Now type "make" to compile.


# bash-5.1# make
/usr/include/glib-2.0/glib/gmacros.h:1112:44: note: expanded from macro 'G_DEPRECATED_FOR'
#define G_DEPRECATED_FOR(f) __attribute__((__deprecated__("Use '" #f "' instead")))
2 warnings generated.
  CCLD     thunar
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libexo-1.so: undefined reference to symbol 'XFree'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.so: error adding symbols: DSO missing from command line
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:1083: thunar] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[2]: *** [Makefile:998: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[1]: *** [Makefile:761: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar'
make: *** [Makefile:574: all] Error 2



# exo-0.11.5 > thunar:
bash-5.1# history |tail -15
  430  cd ../exo/
  431  git checkout exo-0.11.5
  432  ls
  433  make clean
  434  ./autogen.sh 
  435  make
  436  make install
  437  cd -
  438  make
# make
2 warnings generated.
  CCLD     thunar
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libexo-1.so: undefined reference to symbol 'XFree'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.so: error adding symbols: DSO missing from command line
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:1083: thunar] Error 1
make[3]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[2]: *** [Makefile:998: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar/thunar'
make[1]: *** [Makefile:761: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/thunar'
make: *** [Makefile:574: all] Error 2

```

## xfwm4

```bash
# bash-5.1# history |tail -25
  464  pwd
  465  cd ..
  466  git clone https://hub.yzuu.cf/xfce-mirror/xfwm4
  467  cd xfwm4/
  469  git checkout xfwm4-4.12.5
  471  ./autogen.sh 
  472  apk add libwnck3-dev
  473  ./autogen.sh 
  #475  cd ../_deps/
  479  git clone https://hub.yzuu.cf/GNOME/libwnck
  480  cd libwnck/
  482  git checkout LIBWNCK_2_30_7
  484  ./autogen.sh 
  485  apk add gnome-common
  486  ./autogen.sh 
  487  make

# make
In file included from wnckprop.c:47:
../libwnck/libwnck.h:39:10: fatal error: 'libwnck/wnck-enum-types.h' file not found
#include <libwnck/wnck-enum-types.h>
         ^~~~~~~~~~~~~~~~~~~~~~~~~~~
3 warnings and 1 error generated.
make[2]: *** [Makefile:796: wnckprop.o] Error 1
make[2]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/libwnck/libwnck'
make[1]: *** [Makefile:557: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2-2/_xfce4/_deps/libwnck'
make: *** [Makefile:464: all] Error 2

```
