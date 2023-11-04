

## openbox

- pango
- libxrandr
- fontconfig #split@Dockerfile

```bash
 107 cd ../fk-docker-baseimage-gui/src/openbox/
 108 ls
 109 bash build.sh 
 110 ls -lh

#  115 ls
 116 cd /tmp/openbox
 117 ls
 118 cd -
 119 cd /tmp/openbox-install/
 120 ls
 121 find
 123 ./usr/bin/openbox --help
 126 xx-verify --static      /tmp/openbox-install/usr/bin/openbox #OK
 127 echo $? #0
```

## fluxbox@C++

- blackbox> fluxbox; github资料不如openbox
- 相比openbox: 配置项简洁; 自带panel;

```bash
# how build?

git clone https://ghproxy.com/https://github.com/fluxbox/fluxbox /mnt2/fluxbox
# hand
./autogen.sh
./configure 
# ./configure  --enable-static --prefix=/usr/local/static/dropbear
make

/mnt2/fluxbox # make
cmp: ./src/defaults.cc: No such file or directory
make  all-recursive
make[1]: Entering directory '/mnt2/fluxbox'
Making all in nls/C
make[2]: Entering directory '/mnt2/fluxbox/nls/C'
/bin/sh: fluxbox.cat: not found
make[2]: *** [Makefile:484: fluxbox.cat] Error 127
make[2]: Leaving directory '/mnt2/fluxbox/nls/C'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2

# https://github.com/kth5/archpower/blob/afb16bf6b3ca9654b981db1d8be51e4f249698fd/fluxbox/PKGBUILD#L17
_commit='9d8202f32338a3f08d3fa39057dc5eec5d97be4e'
source=("git+https://github.com/fluxbox/fluxbox.git#commit=${_commit}"
        'fluxbox.desktop')

autoreconf -fi
./configure \
    --prefix=/usr/local/static/fluxbox \
    --enable-imlib2 \
    --enable-nls \
    --enable-xft \
    --enable-xinerama

/mnt2/fluxbox # apk add imlib2
(1/1) Installing imlib2 (1.7.4-r0)
Executing busybox-1.34.1-r7.trigger
OK: 912 MiB in 364 packages
/mnt2/fluxbox # apk add imlib2-dev

make DESTDIR="${pkgdir}" install
```

### dyn build

- try01

```bash
# ./configure
config.status: creating nls/zh_CN/Makefile
config.status: creating nls/zh_TW/Makefile
config.status: creating config.h
config.status: executing depfiles commands
        fluxbox version 1.3.7 configured successfully.
Using:
        '/usr' for installation.
        '/usr/share/fluxbox/menu' for location menu file.
        '/usr/share/fluxbox/windowmenu' for location window menu file.
        '/usr/share/fluxbox/styles/bloe' by default style.
        '/usr/share/fluxbox/keys' for location keys file.
        '/usr/share/fluxbox/init' for location init file.
        '/usr/share/fluxbox/nls' for nls files.
        'xx-clang++' for C++ compiler.
Building with:
        '-I/usr/include/fribidi     -Os -fomit-frame-pointer ' for C++ compiler flags.
        ' -lfontconfig -lfreetype  -lfreetype  -lfribidi  -lImlib2  -lXrandr  -lXext  -lXft  -lXinerama   -lXrender -lX11 ' for linker flags.
Now build fluxbox with 'make'


# /mnt2/fluxbox # make
make  all-recursive
make[1]: Entering directory '/mnt2/fluxbox'
Making all in nls/C
make[2]: Entering directory '/mnt2/fluxbox/nls/C'
/bin/sh: fluxbox.cat: not found
make[2]: *** [Makefile:484: fluxbox.cat] Error 127
make[2]: Leaving directory '/mnt2/fluxbox/nls/C'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2
```

- try02: v137 with --disable-xx x4 >> masterBuild OK;

```bash
# https://github.com/fluxbox/fluxbox #6207commits
# https://github.com/fluxbox/fluxbox/tree/Release-1_3_7 #5995commits last@Feb 8, 2015
/mnt2/fluxbox # apk add fluxbox
(1/3) Installing libxt (1.2.1-r0)
(2/3) Installing libxpm (3.5.15-r0)
(3/3) Installing fluxbox (1.3.7-r3)
Executing busybox-1.34.1-r7.trigger


# git clone --branch Release-1_3_7 --depth=1 https://ghps.cc/https://github.com/fluxbox/fluxbox fluxbox-v137
autoreconf -fi
./configure \
    --prefix=/usr/local/static/fluxbox \
    --disable-imlib2 \
    --disable-nls \
    --disable-xft \
    --disable-xinerama

config.status: executing depfiles commands
        fluxbox version 1.3.7 configured successfully.
Using:
        '/usr/local/static/fluxbox' for installation.
        '/usr/local/static/fluxbox/share/fluxbox/menu' for location menu file.
        '/usr/local/static/fluxbox/share/fluxbox/windowmenu' for location window menu file.
        '/usr/local/static/fluxbox/share/fluxbox/styles/bloe' by default style.
        '/usr/local/static/fluxbox/share/fluxbox/keys' for location keys file.
        '/usr/local/static/fluxbox/share/fluxbox/init' for location init file.
        '/usr/local/static/fluxbox/share/fluxbox/nls' for nls files.
        'xx-clang++' for C++ compiler.
Building with:
        '-I/usr/include/fribidi     -Os -fomit-frame-pointer ' for C++ compiler flags.
        '  -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 ' for linker flags.
Now build fluxbox with 'make'



/mnt2/fluxbox-v137 # make
util/fbsetroot.cc:227:5: warning: 'register' storage class specifier is deprecated and incompatible with C++17 [-Wdeprecated-register]
    register int i;
    ^~~~~~~~~
2 warnings generated.
mv -f util/.deps/fbsetroot-fbsetroot.Tpo util/.deps/fbsetroot-fbsetroot.Po
xx-clang++  -Os -fomit-frame-pointer    -o fbsetroot src/fbsetroot-FbAtoms.o src/fbsetroot-FbRootWindow.o util/fbsetroot-fbsetroot.o libFbTk.a  -lfribidi   -lXrender -lX11  -lX11   -lrt  -lm
xx-clang++ -DHAVE_CONFIG_H -I.  -include ./config.h -I./src/FbTk -Os -fomit-frame-pointer  -Os -fomit-frame-pointer  -MT util/fluxbox_remote-fluxbox-remote.o -MD -MP -MF util/.deps/fluxbox_remote-fluxbox-remote.Tpo -c -o util/fluxbox_remote-fluxbox-remote.o 'test -f 'util/fluxbox-remote.cc' || echo './'`util/fluxbox-remote.cc
util/fluxbox-remote.cc:76:32: error: ordered comparison between pointer and zero ('unsigned char *' and 'int')
            && text_prop.value > 0
               ~~~~~~~~~~~~~~~ ^ ~
1 error generated.
make[2]: *** [Makefile:4231: util/fluxbox_remote-fluxbox-remote.o] Error 1
make[2]: Leaving directory '/mnt2/fluxbox-v137'
make[1]: *** [Makefile:4855: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox-v137'
make: *** [Makefile:1748: all] Error 2

# >master
Building with:
        '-I/usr/include/fribidi     -Os -fomit-frame-pointer ' for C++ compiler flags.
        '  -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 ' for linker flags.
Now build fluxbox with 'make'

/mnt2/fluxbox # make
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/fluxbox.1.in > doc/fluxbox.1
./build-aux/install-sh -c -d doc
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/startfluxbox.1.in > doc/startfluxbox.1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: Leaving directory '/mnt2/fluxbox'
/mnt2/fluxbox # 
/mnt2/fluxbox # echo $?
0


# view
/mnt2/fluxbox # ls -lh
-rwxr-xr-x    1 root     root      206.7K Nov  5 11:49 fbrun
-rwxr-xr-x    1 root     root      203.7K Nov  5 11:48 fbsetroot
-rwxr-xr-x    1 root     root        1.5M Nov  5 11:48 fluxbox
-rwxr-xr-x    1 root     root       19.3K Nov  5 11:48 fluxbox-remote
-rwxr-xr-x    1 root     root      109.7K Nov  5 11:48 fluxbox-update_configs
-rw-r--r--    1 root     root        1.1M Nov  5 11:48 libFbTk.a
/mnt2/fluxbox # ./fluxbox -h
Fluxbox 1.3.7 : (c) 2001-2015 Fluxbox Team
Website: http://www.fluxbox.org/
-display <string>               use display connection.
-screen <all|int,int,int>       run on specified screens only.
-rc <string>                    use alternate resource file.
-no-slit                        do not provide a slit.
-no-toolbar                     do not provide a toolbar.
-version                        display version and exit.
-info                           display some useful information.
-list-commands                  list all valid key commands.
-sync                           synchronize with X server for debugging.
-log <filename>                 log output to file.
-help                           display this help text and exit.

/mnt2/fluxbox # xx-verify --static ./fluxbox
file ./fluxbox is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped
/mnt2/fluxbox # 
```

### static build

- try03: static with master '0f95d62b1b1add8ee7327305db7d372010fdb2f4`

```bash
# commit 0f95d62b1b1add8ee7327305db7d372010fdb2f4 (HEAD -> master, origin/master, origin/HEAD)
# Author: Philippe Crama <pcfeb0009@gmx.com>
# Date:   Sun Aug 6 14:14:48 2023 +0200
#     Fix name of ToggleToolbarVisible in documentation

autoreconf -fi
./configure \
    --prefix=/usr/local/static/fluxbox \
    --disable-imlib2 \
    --disable-nls \
    --disable-xft \
    --disable-xinerama \
    --enable-static \
    --disable-shared 

make clean
make

# make
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/startfluxbox.1.in > doc/startfluxbox.1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: Leaving directory '/mnt2/fluxbox'
/mnt2/fluxbox # 
/mnt2/fluxbox # echo $?
0
/mnt2/fluxbox # ls -lh fluxbox
-rwxr-xr-x    1 root     root        1.5M Nov  5 12:06 fluxbox
/mnt2/fluxbox # xx-verify --static ./fluxbox
file ./fluxbox is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped
/mnt2/fluxbox # ldd fluxbox |sort
        /lib/ld-musl-x86_64.so.1 (0x7f2ba6542000)
        libX11.so.6 => /usr/lib/libX11.so.6 (0x7f2ba620d000)
        libXau.so.6 => /usr/lib/libXau.so.6 (0x7f2ba5f9c000)
        libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f2ba5f94000)
        libXext.so.6 => /usr/lib/libXext.so.6 (0x7f2ba633c000)
        libXrandr.so.2 => /usr/lib/libXrandr.so.2 (0x7f2ba634f000) ###
        libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f2ba6330000)
        libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f2ba5fa1000)
        libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f2ba5feb000)
        libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f2ba5f81000) ###
        libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f2ba6043000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f2ba6542000)
        libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f2ba637a000)
        libfribidi.so.0 => /usr/lib/libfribidi.so.0 (0x7f2ba635b000) ###
        libgcc_s.so.1 => /usr/lib/libgcc_s.so.1 (0x7f2ba6052000) ###
        libmd.so.0 => /usr/lib/libmd.so.0 (0x7f2ba5f75000) ###
        libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f2ba6012000)
        libstdc++.so.6 => /usr/lib/libstdc++.so.6 (0x7f2ba606c000) ###
        libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f2ba5fc4000)
        libz.so.1 => /lib/libz.so.1 (0x7f2ba5ff8000)
# -lstdc++ -lmd -lgcc_s -lfribidi -lbsd -l Xrandr


/mnt2/fluxbox # env |grep FLAGS
CXXFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer

```

- try04: LDFALGS (ref suckless)


```bash

# with LDFALGS (ref suckless)
# pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
# xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make clean
make LDFLAGS="$flags $OB_LIBS -luuid"


# /mnt2/fluxbox # make LDFLAGS="$flags $OB_LIBS -luuid"
xcb_disp.c:(.text+0x153): undefined reference to 'xcb_parse_display'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x19b): undefined reference to 'xcb_connect_to_display_with_auth_info'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1a7): undefined reference to 'xcb_connect'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1c7): undefined reference to 'xcb_get_file_descriptor'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x1e3): undefined reference to 'xcb_generate_id'
/usr/bin/x86_64-alpine-linux-musl-ld: xcb_disp.c:(.text+0x25c): undefined reference to 'xcb_connection_has_error'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:2165: fluxbox] Error 1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2

/mnt2/fluxbox # make LDFLAGS="$flags $OB_LIBS -luuid" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):



# ref dmenu;
# +-lXext>> OK;
# make LDFLAGS="$flags -lXinerama   -lX11 -lXrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext"


# # gitac>> handBuild02@newBuilder_02:
# fontconfig-static@apk>> -luuid 
# xrandr="-lXrandr"
make LDFLAGS="$flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"

# $OB_LIBS -luuid
make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"

/mnt2/fluxbox # make LDFLAGS="$flags $OB_LIBS -luuid -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):

# detail
make[2]: Entering directory '/mnt2/fluxbox/nls/zh_TW'
make[2]: Leaving directory '/mnt2/fluxbox/nls/zh_TW'
make[2]: Entering directory '/mnt2/fluxbox'
xx-clang++  -Os -fomit-frame-pointer   

-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon -lX11 -lxcb -lXdmcp -lXau -lXext -lXft  -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz  -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi -lXinerama   -lX11  -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid 

-o fluxbox src/fluxbox-AlphaMenu.o src/fluxbox-ArrowButton.o src/fluxbox-AttentionNoticeHandler.o src/fluxbox-CascadePlacement.o src/fluxbox-ClientMenu.o src/fluxbox-ClientPattern.o src/fluxbox-ColSmartPlacement.o src/fluxbox-CommandDialog.o src/fluxbox-ConfigMenu.o src/fluxbox-CurrentWindowCmd.o src/fluxbox-FbAtoms.o src/fluxbox-FbCommands.o src/fluxbox-FbMenu.o src/fluxbox-FbMenuParser.o src/fluxbox-FbRootWindow.o src/fluxbox-FbWinFrame.o src/fluxbox-FbWinFrameTheme.o src/fluxbox-FocusControl.o src/fluxbox-FocusableList.o src/fluxbox-HeadArea.o src/fluxbox-IconButton.o src/fluxbox-IconbarTheme.o src/fluxbox-Keys.o src/fluxbox-LayerMenu.o src/fluxbox-MenuCreator.o src/fluxbox-MinOverlapPlacement.o src/fluxbox-OSDWindow.o src/fluxbox-Resources.o src/fluxbox-RootCmdMenuItem.o src/fluxbox-RootTheme.o src/fluxbox-RowSmartPlacement.o src/fluxbox-Screen.o src/fluxbox-ScreenPlacement.o src/fluxbox-ScreenResource.o src/fluxbox-SendToMenu.o src/fluxbox-ShortcutManager.o src/fluxbox-StyleMenuItem.o src/fluxbox-TextDialog.o src/fluxbox-TooltipWindow.o src/fluxbox-UnderMousePlacement.o src/fluxbox-WinButton.o src/fluxbox-WinButtonTheme.o src/fluxbox-WinClient.o src/fluxbox-Window.o src/fluxbox-WindowCmd.o src/fluxbox-WindowState.o src/fluxbox-Workspace.o src/fluxbox-WorkspaceCmd.o src/fluxbox-WorkspaceMenu.o src/fluxbox-Xutil.o src/fluxbox-fluxbox.o src/fluxbox-main.o src/fluxbox-cli_cfiles.o src/fluxbox-cli_options.o src/fluxbox-cli_info.o src/fluxbox-Ewmh.o src/fluxbox-Remember.o src/fluxbox-Slit.o src/fluxbox-SlitClient.o src/fluxbox-SlitTheme.o src/fluxbox-ButtonTheme.o src/fluxbox-ButtonTool.o src/fluxbox-ClockTool.o src/fluxbox-GenericTool.o src/fluxbox-IconbarTool.o src/fluxbox-SpacerTool.o src/fluxbox-ToolFactory.o src/fluxbox-ToolTheme.o src/fluxbox-Toolbar.o src/fluxbox-ToolbarItem.o src/fluxbox-ToolbarTheme.o src/fluxbox-WorkspaceNameTool.o src/fluxbox-SystemTray.o libFbTk.a src/defaults.o 

 -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11  -lX11   -lrt  -lm

```

- try05


```bash
# OB_LIBS: all open
pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

# ref
# >master
Building with:
        '-I/usr/include/fribidi     -Os -fomit-frame-pointer ' for C++ compiler flags.
        '  -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 ' for linker flags.
Now build fluxbox with 'make'




# -static 
flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

# 去-static, 编译正常;
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/startfluxbox.1.in > doc/startfluxbox.1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: Leaving directory '/mnt2/fluxbox'
/mnt2/fluxbox # 
/mnt2/fluxbox # xx-verify --static ./fluxbox
file ./fluxbox is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, with debug_info, not stripped




#  2>&1 |grep musl/10 |awk '{print $2}' |sort -u
# --static -static >> 一样X11> xcb_xx错误; 
flags="--static -static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

flux=" -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 "
# /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgcc_s
ext2="-lstdc++ -lmd -lfribidi -lbsd -l Xrandr" #-lgcc_s 
make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"




/mnt2/fluxbox # cat Makefile.am  |wc
       88       211      2420
/mnt2/fluxbox # cat Makefile |wc
     5805     29640    407185

# find /usr/lib |egrep "libmd|libstdc|libgcc_s|libbsd|libXrandr"
# /mnt2/fluxbox # find /usr/lib |egrep "libmd|libstdc|libgcc|libbsd|libXrandr" |grep "\.a$"
/usr/lib/libXrandr.a
/usr/lib/libbsd.a
/usr/lib/libmd.a
/usr/lib/libstdc++fs.a
/usr/lib/libstdc++.a
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/libgcc_eh.a
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/libgcc.a
```


- try06: src//./INSTALL

```bash
# src//./INSTALL
# === Cross-Compiler for Microsoft Windows:
# You'll want mingw-cross-env installed, with libX11 and mingw-catgets built.
# A configure line that works is:
$ ./configure \
  --prefix=/ \
  --host=i686-pc-mingw32 \
  --disable-imlib2 \
  --disable-xmb \
  --disable-slit \
  --disable-remember \
  --disable-toolbar \
  --disable-fribidi \
  --disable-nls \
  --disable-xft \
  LIBS="-lxcb -lXdmcp -lXau -lpthread -lws2_32"


  # --host=i686-pc-mingw32 \
  #  -lws2_32
./configure \
  --prefix=/usr/local/static/fluxbox \
  --disable-imlib2 \
  --disable-xmb \
  --disable-slit \
  --disable-remember \
  --disable-toolbar \
  --disable-fribidi \
  --disable-nls \
  --disable-xft \
  LIBS="-lxcb -lXdmcp -lXau -lpthread"

# ./configure
Building with:
        '    -Os -fomit-frame-pointer ' for C++ compiler flags.
        '  -lfreetype    -lXrandr  -lXext   -lXinerama   -lXrender -lX11 ' for linker flags.
Now build fluxbox with 'make'

/mnt2/fluxbox # env |grep clang
CXX=xx-clang++
CC=xx-clang


/mnt2/fluxbox # make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2
xx-clang++ -DHAVE_CONFIG_H -I.  -I/usr/include/freetype2 -I/usr/include/libpng16   -include ./config.h -I./src -I./src -I./nls -Os -fomit-frame-pointer  -Os -fomit-frame-pointer  -MT src/FbTk/libFbTk_a-XFontImp.o -MD -MP -MF src/FbTk/.deps/libFbTk_a-XFontImp.Tpo -c -o src/FbTk/libFbTk_a-XFontImp.o 'test -f 'src/FbTk/XFontImp.cc' || echo './''src/FbTk/XFontImp.cc
mv -f src/FbTk/.deps/libFbTk_a-XFontImp.Tpo src/FbTk/.deps/libFbTk_a-XFontImp.Po
rm -f libFbTk.a
ar cru libFbTk.a     src/FbTk/libFbTk_a-App.o src/FbTk/libFbTk_a-AutoReloadHelper.o src/FbTk/libFbTk_a-BorderTheme.o src/FbTk/libFbTk_a-Button.o src/FbTk/libFbTk_a-CachedPixmap.o src/FbTk/libFbTk_a-Color.o src/FbTk/libFbTk_a-ColorLUT.o src/FbTk/libFbTk_a-Container.o src/FbTk/libFbTk_a-EventManager.o src/FbTk/libFbTk_a-FbDrawable.o src/FbTk/libFbTk_a-FbPixmap.o src/FbTk/libFbTk_a-FbString.o src/FbTk/libFbTk_a-FbTime.o src/FbTk/libFbTk_a-FbWindow.o src/FbTk/libFbTk_a-FileUtil.o src/FbTk/libFbTk_a-Font.o src/FbTk/libFbTk_a-GContext.o src/FbTk/libFbTk_a-I18n.o src/FbTk/libFbTk_a-Image.o src/FbTk/libFbTk_a-ImageControl.o src/FbTk/libFbTk_a-KeyUtil.o src/FbTk/libFbTk_a-Layer.o src/FbTk/libFbTk_a-LayerItem.o src/FbTk/libFbTk_a-LogicCommands.o src/FbTk/libFbTk_a-MacroCommand.o src/FbTk/libFbTk_a-Menu.o src/FbTk/libFbTk_a-MenuItem.o src/FbTk/libFbTk_a-MenuSearch.o src/FbTk/libFbTk_a-MenuSeparator.o src/FbTk/libFbTk_a-MenuTheme.o src/FbTk/libFbTk_a-MultLayers.o src/FbTk/libFbTk_a-MultiButtonMenuItem.o src/FbTk/libFbTk_a-Parser.o src/FbTk/libFbTk_a-RegExp.o src/FbTk/libFbTk_a-RelCalcHelper.o src/FbTk/libFbTk_a-Resource.o src/FbTk/libFbTk_a-Shape.o src/FbTk/libFbTk_a-StringUtil.o src/FbTk/libFbTk_a-TextBox.o src/FbTk/libFbTk_a-TextButton.o src/FbTk/libFbTk_a-TextTheme.o src/FbTk/libFbTk_a-TextUtils.o src/FbTk/libFbTk_a-Texture.o src/FbTk/libFbTk_a-TextureRender.o src/FbTk/libFbTk_a-Theme.o src/FbTk/libFbTk_a-ThemeItems.o src/FbTk/libFbTk_a-Timer.o src/FbTk/libFbTk_a-Transparent.o src/FbTk/libFbTk_a-XFontImp.o 

ar: 'u' modifier ignored since 'D' is the default (see 'U')
ranlib libFbTk.a

xx-clang++  -Os -fomit-frame-pointer   --static -static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi -lXinerama   -lX11 -lXrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid  -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11  -lstdc++ -lmd -lfribidi -lbsd -l Xrandr -o fluxbox src/fluxbox-AlphaMenu.o src/fluxbox-ArrowButton.o src/fluxbox-AttentionNoticeHandler.o src/fluxbox-CascadePlacement.o src/fluxbox-ClientMenu.o src/fluxbox-ClientPattern.o src/fluxbox-ColSmartPlacement.o src/fluxbox-CommandDialog.o src/fluxbox-ConfigMenu.o src/fluxbox-CurrentWindowCmd.o src/fluxbox-FbAtoms.o src/fluxbox-FbCommands.o src/fluxbox-FbMenu.o src/fluxbox-FbMenuParser.o src/fluxbox-FbRootWindow.o src/fluxbox-FbWinFrame.o src/fluxbox-FbWinFrameTheme.o src/fluxbox-FocusControl.o src/fluxbox-FocusableList.o src/fluxbox-HeadArea.o src/fluxbox-IconButton.o src/fluxbox-IconbarTheme.o src/fluxbox-Keys.o src/fluxbox-LayerMenu.o src/fluxbox-MenuCreator.o src/fluxbox-MinOverlapPlacement.o src/fluxbox-OSDWindow.o src/fluxbox-Resources.o src/fluxbox-RootCmdMenuItem.o src/fluxbox-RootTheme.o src/fluxbox-RowSmartPlacement.o src/fluxbox-Screen.o src/fluxbox-ScreenPlacement.o src/fluxbox-ScreenResource.o src/fluxbox-SendToMenu.o src/fluxbox-ShortcutManager.o src/fluxbox-StyleMenuItem.o src/fluxbox-TextDialog.o src/fluxbox-TooltipWindow.o src/fluxbox-UnderMousePlacement.o src/fluxbox-WinButton.o src/fluxbox-WinButtonTheme.o src/fluxbox-WinClient.o src/fluxbox-Window.o src/fluxbox-WindowCmd.o src/fluxbox-WindowState.o src/fluxbox-Workspace.o src/fluxbox-WorkspaceCmd.o src/fluxbox-WorkspaceMenu.o src/fluxbox-Xutil.o src/fluxbox-fluxbox.o src/fluxbox-main.o src/fluxbox-cli_cfiles.o src/fluxbox-cli_options.o src/fluxbox-cli_info.o src/fluxbox-Ewmh.o   src/fluxbox-ButtonTheme.o src/fluxbox-ButtonTool.o src/fluxbox-ClockTool.o src/fluxbox-GenericTool.o src/fluxbox-IconbarTool.o src/fluxbox-SpacerTool.o src/fluxbox-ToolFactory.o src/fluxbox-ToolTheme.o src/fluxbox-Toolbar.o src/fluxbox-ToolbarItem.o src/fluxbox-ToolbarTheme.o src/fluxbox-WorkspaceNameTool.o src/fluxbox-SystemTray.o libFbTk.a src/defaults.o  -lfreetype    -lXrandr  -lXext   -lXinerama   -lXrender -lX11  -lX11   -lrt -lxcb -lXdmcp -lXau -lpthread -lm

/usr/bin/x86_64-alpine-linux-musl-ld: src/fluxbox-WinClient.o: in function 'WinClient::updateWMNormalHints()':
WinClient.cc:(.text+0x61f): undefined reference to 'Remember::s_instance'
/usr/bin/x86_64-alpine-linux-musl-ld: WinClient.cc:(.text+0x62f): undefined reference to 'Remember::isRemembered(WinClient&, Remember::Attribute)'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:2165: fluxbox] Error 1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2


```

- notes --disable-remember \ >> static buildOK

```bash
# OB_LIBS: all open
pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

#  2>&1 |grep musl/10 |awk '{print $2}' |sort -u
# --static -static >> 一样X11> xcb_xx错误; 
# --static -static ##ex
flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

flux=" -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 "
# /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgcc_s
ext2="-lstdc++ -lmd -lfribidi -lbsd -l Xrandr" #-lgcc_s 
make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"


EX_LIBS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"

  # --host=i686-pc-mingw32 \
  #  -lws2_32
./configure \
  --prefix=/usr/local/static/fluxbox \
  --disable-xmb \
  --disable-slit \
  --disable-remember \
  --disable-toolbar \
  --disable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --disable-xft \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"


# --static -static ##ex>> +: -static
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"


# 需要remember模块：
# /mnt2/fluxbox # make #LDFLAGS="$flags"
f86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid  -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11  -lstdc++ -lmd -lfribidi -lbsd -l Xrandr -lm
/usr/bin/x86_64-alpine-linux-musl-ld: src/fluxbox-WinClient.o: in function 'WinClient::updateWMNormalHints()':
WinClient.cc:(.text+0x61f): undefined reference to 'Remember::s_instance'
/usr/bin/x86_64-alpine-linux-musl-ld: WinClient.cc:(.text+0x62f): undefined reference to 'Remember::isRemembered(WinClient&, Remember::Attribute)'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[2]: *** [Makefile:2165: fluxbox] Error 1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fluxbox'
make: *** [Makefile:1760: all] Error 2


# FF_REF:
autoreconf -fi
./configure \
    --prefix=/usr/local/static/fluxbox \
    --disable-imlib2 \
    --disable-nls \
    --disable-xft \
    --disable-xinerama \
    --enable-static \
    --disable-shared 

# --disable-remember \ >> static buildOK!!
./configure \
  --prefix=/usr/local/static/fluxbox \
  --disable-xmb \
  --disable-slit \
  --disable-toolbar \
  --disable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --disable-xft \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"

/mnt2/fluxbox # make LDFLAGS="$flags"
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/fluxbox.1.in > doc/fluxbox.1
./build-aux/install-sh -c -d doc
sed -e "s,@pkgdatadir[@],/usr/local/static/fluxbox/share/fluxbox," doc/startfluxbox.1.in > doc/startfluxbox.1
make[2]: Leaving directory '/mnt2/fluxbox'
make[1]: Leaving directory '/mnt2/fluxbox'
/mnt2/fluxbox # 
/mnt2/fluxbox # echo $?
0
/mnt2/fluxbox # ls -lh fluxbox
-rwxr-xr-x    1 root     root       10.4M Nov  5 15:55 fluxbox
/mnt2/fluxbox # xx-verify --static fluxbox
/mnt2/fluxbox # ls -lh
-rwxr-xr-x    1 root     root        8.7M Nov  5 15:55 fbrun
-rwxr-xr-x    1 root     root        8.6M Nov  5 15:55 fbsetroot
-rwxr-xr-x    1 root     root       10.4M Nov  5 15:55 fluxbox
-rwxr-xr-x    1 root     root        3.1M Nov  5 15:55 fluxbox-remote
-rwxr-xr-x    1 root     root       10.4M Nov  5 16:03 fluxbox-static01
-rwxr-xr-x    1 root     root        8.3M Nov  5 15:55 fluxbox-update_configs
-rw-r--r--    1 root     root        1.0M Nov  5 15:55 libFbTk.a
/mnt2/fluxbox # xx-verify --static fbrun 
/mnt2/fluxbox # xx-verify --static fbsetroot 
/mnt2/fluxbox # xx-verify --static fluxbox-remote 
/mnt2/fluxbox # xx-verify --static fluxbox-update_configs 

/mnt2/fluxbox # ./fluxbox -h
Fluxbox 1.3.7 : (c) 2001-2015 Fluxbox Team
Website: http://www.fluxbox.org/
-display <string>               use display connection.
-screen <all|int,int,int>       run on specified screens only.
-rc <string>                    use alternate resource file.
-no-slit                        do not provide a slit.
-no-toolbar                     do not provide a toolbar.
-version                        display version and exit.
-info                           display some useful information.
-list-commands                  list all valid key commands.
-sync                           synchronize with X server for debugging.
-log <filename>                 log output to file.
-help                           display this help text and exit.

# validate02
root@VM-12-9-ubuntu:~# cd /mnt/xrdp-static-alpine/
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./fluxbox-static01 -h
Fluxbox 1.3.7 : (c) 2001-2015 Fluxbox Team
Website: http://www.fluxbox.org/
```

- **libs clear**

```bash
# OB_LIBS: all open
pango="-lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0"
xrandr="-lXrandr"
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft $xrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz $pango -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 
#
# flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

#  2>&1 |grep musl/10 |awk '{print $2}' |sort -u
# --static -static >> 一样X11> xcb_xx错误; 
# --static -static ##ex
flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"

flux=" -lfreetype  -lfribidi   -lXrandr  -lXext     -lXrender -lX11 "
# /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgcc_s
ext2="-lstdc++ -lmd -lfribidi -lbsd -l Xrandr" #-lgcc_s 
# make LDFLAGS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"


EX_LIBS="$flags $OB_LIBS -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid $flux $ext2"

autoreconf -fi
# merge
# --disable-remember \
./configure \
  --prefix=/usr/local/static/fluxbox \
  --disable-xmb \
  --disable-slit \
  --disable-toolbar \
  --disable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --disable-xft \
  --disable-xinerama \
  \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"

# make去flags>> OK;
# --static -static ##ex>> +: -static
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make LDFLAGS="$flags"
make LDFLAGS="-static" #OK;




# CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4
autoreconf -fi
# --disable-remember \
./configure \
  --prefix=/usr/local/static/fluxbox \
  --enable-xmb \
  --enable-slit \
  --enable-toolbar \
  --enable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --disable-xft \
  --disable-xinerama \
  \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread" #$EX_LIBS

make clean
make LDFLAGS="-static"

# /mnt2/fluxbox # ls -lh
-rwxr-xr-x    1 root     root        8.7M Nov  5 16:19 fbrun
-rwxr-xr-x    1 root     root        8.6M Nov  5 16:19 fbsetroot
-rwxr-xr-x    1 root     root       10.4M Nov  5 16:19 fluxbox
-rwxr-xr-x    1 root     root        3.1M Nov  5 16:19 fluxbox-remote
-rwxr-xr-x    1 root     root       10.4M Nov  5 16:03 fluxbox-static01
-rwxr-xr-x    1 root     root        8.3M Nov  5 16:19 fluxbox-update_configs
-rw-r--r--    1 root     root        1.0M Nov  5 16:19 libFbTk.a
/mnt2/fluxbox # xx-verify --static fluxbox
/mnt2/fluxbox # 

# configure: disable_x4> enable_x4
/mnt2/fluxbox # ls -lh
-rwxr-xr-x    1 root     root        8.8M Nov  5 16:26 fbrun
-rwxr-xr-x    1 root     root        8.7M Nov  5 16:26 fbsetroot
-rwxr-xr-x    1 root     root       10.5M Nov  5 16:26 fluxbox #10.4> 10.5M
-rwxr-xr-x    1 root     root        3.1M Nov  5 16:26 fluxbox-remote
-rwxr-xr-x    1 root     root       10.4M Nov  5 16:03 fluxbox-static01
-rwxr-xr-x    1 root     root        8.3M Nov  5 16:26 fluxbox-update_configs
-rw-r--r--    1 root     root        1.1M Nov  5 16:26 libFbTk.a
/mnt2/fluxbox # xx-verify --static fluxbox



# ubt2004 fluxbox v1.3.5
root@718db0a8cfb1:/rootfs/files1/usr/local/static/fluxbox/bin# ./fluxbox -v
Fluxbox 1.3.7 : (c) 2001-2015 Fluxbox Team 

root@718db0a8cfb1:/rootfs/files1/usr/local/static/fluxbox/bin# ./fluxbox -h
Fluxbox 1.3.7 : (c) 2001-2015 Fluxbox Team
Website: http://www.fluxbox.org/
-display <string>		use display connection.
-screen <all|int,int,int>	run on specified screens only.
-rc <string>			use alternate resource file.
-no-slit			do not provide a slit.
-no-toolbar			do not provide a toolbar.
-version			display version and exit.
-info				display some useful information.
-list-commands			list all valid key commands.
-sync				synchronize with X server for debugging.
-log <filename>			log output to file.
-help				display this help text and exit.

# root@718db0a8cfb1:/rootfs/files1/usr/local/static/fluxbox/bin# which fluxbox
/usr/bin/fluxbox
root@718db0a8cfb1:/rootfs/files1/usr/local/static/fluxbox/bin# ll /usr/bin/ |grep fluxbox
-rwxr-xr-x 1 root root   1509920 Mar 22  2020 fluxbox*
-rwxr-xr-x 1 root root     14488 Mar 22  2020 fluxbox-remote*
-rwxr-xr-x 1 root root    117056 Mar 22  2020 fluxbox-update_configs*
-rwxr-xr-x 1 root root      1531 Mar 22  2020 startfluxbox*
root@718db0a8cfb1:/rootfs/files1/usr/local/static/fluxbox/bin# /usr/bin/fluxbox -v
Fluxbox 1.3.5 : (c) 2001-2011 Fluxbox Team 
```

### flux-run @ubt2004

```bash
# root@VM-12-9-ubuntu:/var/log/supervisor# dpkg -l |grep fontconf
ii  fontconfig-config             2.13.1-2ubuntu3                   all          generic font configuration library - configuration
ii  libfontconfig1:amd64          2.13.1-2ubuntu3                   amd64        generic font configuration library - runtime


# root@VM-12-9-ubuntu:/var/log/supervisor# fluxbox
Failed to read: session.ignoreBorder
Setting default value
Failed to read: session.forcePseudoTransparency
Setting default value
Failed to read: session.colorsPerChannel
Setting default value
Failed to read: session.doubleClickInterval
Setting default value
Failed to read: session.tabPadding
Setting default value
Failed to read: session.styleOverlay
Setting default value
Failed to read: session.slitlistFile
Setting default value
Failed to read: session.appsFile
Setting default value
Failed to read: session.tabsAttachArea
Setting default value
Failed to read: session.menuSearch
Setting default value
Failed to read: session.cacheLife
Setting default value
Failed to read: session.cacheMax
Setting default value
Failed to read: session.autoRaiseDelay
Setting default value
Failed to read: session.ignoreBorder
Setting default value
Failed to read: session.forcePseudoTransparency
Setting default value
Failed to read: session.colorsPerChannel
Setting default value
Failed to read: session.doubleClickInterval
Setting default value
Failed to read: session.tabPadding
Setting default value
Failed to read: session.styleOverlay
Setting default value
Failed to read: session.slitlistFile
Setting default value
Failed to read: session.appsFile
Setting default value
Failed to read: session.tabsAttachArea
Setting default value
Failed to read: session.menuSearch
Setting default value
Failed to read: session.cacheLife
Setting default value
Failed to read: session.cacheMax
Setting default value
Failed to read: session.autoRaiseDelay
Setting default value
Couldn\'t initialize fonts. Check your fontconfig installation.
```

- ref src/_ex/fontconfig, openbox

```bash
# ref src/_ex/fontconfig, openbox
# Define software versions.
FONTCONFIG_VERSION=2.14.0
# Define software download URLs.
FONTCONFIG_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.gz

# Build fontconfig.
# The static library will be used by some baseimage programs.  We need to
# compile our own version to adjust different paths used by fontconfig.
cd /tmp/fontconfig && ./configure \
    --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
    --host=$(xx-clang --print-target-triple) \
    --prefix=/usr \
    --with-default-fonts=${TARGETPATH}/share/fonts \
    --with-baseconfigdir=${TARGETPATH}/share/fontconfig \
    --with-configdir=${TARGETPATH}/share/fontconfig/conf.d \
    --with-templatedir=${TARGETPATH}/share/fontconfig/conf.avail \
    --with-cache-dir=/config/xdg/cache/fontconfig \
    --disable-shared \
    --enable-static \
    --disable-docs \
    --disable-nls \
    --disable-cache-build

# openbox
# Fontconfig is already built by an earlier stage in Dockerfile.  The static
# library will be used by Openbox.  We need to compile our own version to adjust
# different paths used by fontconfig.
# 
# Note that the fontconfig cache generated by fc-cache is architecture
# dependent.  Thus, we won't generate one, but it's not a problem since
# we have very few fonts installed.
log "Installing fontconfig..."
cp -av /tmp/fontconfig-install/usr $(xx-info sysroot)

cd /tmp/openbox && \
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" \
    LDFLAGS="$LDFLAGS -Wl,--start-group $OB_LIBS -Wl,--end-group" LIBS="$LDFLAGS" ./configure \
    --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
    --host=$(xx-clang --print-target-triple) \
    --prefix=/usr \
    --datarootdir=/opt/base/share \
    --disable-shared \
    --enable-static \
    --disable-nls \
    --disable-startup-notification \
    --disable-xcursor \
    --disable-librsvg \
    --disable-session-management \
    --disable-xkb \
    --disable-xinerama


# dwm@ubt2004: 无fontconfig错误;
# ref: suckless/build.sh
# fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
# FONTCONFIG_VERSION=2.14.0 @fontconfig/build
apk add fontconfig-dev fontconfig-static




# 试着加入fontconfig-static; -lfountconfig库>> 带Xvnc运行验证: 也是不行.. (builder8_env)
# handBuilder_tmux8:
/mnt2/docker-x11base/compile/src # bash x-xrdp/build.sh libxrandr
/mnt2/docker-x11base/compile/src # git pull; bash fluxbox/build.sh fluxbox

# validate
/mnt2/docker-x11base/compile/src # history |tail -8
  25 git pull; bash fluxbox/build.sh fluxbox
  26 ln -s  /mnt2/usr-local-static-cp/tigervnc /usr/local/static/tigervnc
  27 mkdir -p /usr/local/static
  28 ln -s  /mnt2/usr-local-static-cp/tigervnc /usr/local/static/tigervnc
  29 /usr/local/static/tigervnc/bin/Xvnc :21 &
  30 export DISPLAY=:21
  31 /tmp/fluxbox/fluxbox
  32 history |tail -8
/mnt2/docker-x11base/compile/src # 
Failed to read: session.autoRaiseDelay
Setting default value
Couldn\'t initialize fonts. Check your fontconfig installation.

# /mnt2/docker-x11base/compile/src # apk list |grep fontconf
fontconfig-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
fontconfig-dev-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
fontconfig-doc-2.13.1-r4 x86_64 {fontconfig} (MIT)
fontconfig-static-2.13.1-r4 x86_64 {fontconfig} (MIT) [installed]
```

- ff_handBuilder2_dbg

```bash
# ff_handBuilder2_dbg:
1786 cd /mnt2/usr-local-static-cp/tigervnc/bin/
1789 ln -s  /mnt2/usr-local-static-cp/tigervnc /usr/local/static/tigervnc
1791 ./Xvnc :21 &
1797 export DISPLAY=:21
1798 ./fluxbox

# /usr/local/static/fluxbox/bin # ./fluxbox
Failed to read: session.cacheMax
Setting default value
Failed to read: session.autoRaiseDelay
Setting default value
Couldn\'t initialize fonts. Check your fontconfig installation.


```