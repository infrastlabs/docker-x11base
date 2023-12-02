

## Openbox

- ff_built: 尝试Xvnc下启动(验证fontconfig)

```bash
# /mnt2/docker-x11base/compile/src # ls -lh /tmp/openbox/openbox/openbox
-rwxr-xr-x    1 root     root        6.3M Nov  6 05:43 /tmp/openbox/openbox/openbox
/mnt2/docker-x11base/compile/src # xx-verify --static /tmp/openbox/openbox/openbox
/mnt2/docker-x11base/compile/src # echo $?
0

# opbox @builder_tmux2
/tmp/openbox-install/usr/bin # ls -lh
total 10M    
-rwxr-xr-x    1 root     root      871.0K Oct 30 13:42 gdm-control
-rwxr-xr-x    1 root     root      992.2K Oct 30 13:42 gnome-panel-control
-rwxr-xr-x    1 root     root        1.8M Oct 30 13:42 obxprop
-rwxr-xr-x    1 root     root        6.3M Oct 30 13:42 openbox
-rwxr-xr-x    1 root     root        2.0K Oct 30 13:42 openbox-gnome-session
-rwxr-xr-x    1 root     root         476 Oct 30 13:42 openbox-kde-session
-rwxr-xr-x    1 root     root         585 Oct 30 13:42 openbox-session

# try-run @builder_tmux2
/tmp/openbox-install/usr/bin # ps -ef
PID   USER     TIME  COMMAND
    1 root      0:02 sh
474491 root      0:00 ./Xvnc :21
474527 root      0:00 ps -ef

# 需带配置项，不然启不来
/tmp/openbox-install/usr/bin # ./openbox 
Openbox-Message: Unable to find a valid config file, using some simple defaults
ObRender-Message: Unable to load the theme 'Clearlooks'
Openbox-Message: Unable to load a theme.

#openbox --config-file ./etc/xdg/openbox/rc.xml 
/mnt2/openbox-install-cp01/usr # ./bin/openbox --config-file ./etc/xdg/openbox/rc.xml 
Openbox-Message: Unable to find a valid config file, using some simple defaults
(openbox:516681): Pango-CRITICAL **: 15:35:07.570: pango_font_describe: assertion 'font != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_description_get_variant: assertion 'desc != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_describe: assertion 'font != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_description_get_variant: assertion 'desc != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_describe: assertion 'font != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_description_get_variant: assertion 'desc != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.571: pango_font_describe: assertion 'font != NULL' failed
(openbox:516681): Pango-CRITICAL **: 15:35:07.572: pango_font_description_get_variant: assertion 'desc != NULL' failed
Openbox-Message: Unable to find a valid menu file "menu.xml"
# ..Running.


# fontconfig-bins fc-xxx
root@VM-12-9-ubuntu:~# dpkg -l |grep fontcon
root@VM-12-9-ubuntu:~# docker run -it --rm  registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:fluxbox bash
root@c89a801f8a30:/# dpkg -l |grep font
ii  fontconfig-config             2.13.1-2ubuntu3                   all          generic font configuration library - configuration
ii  fonts-dejavu-core             2.37-1                            all          Vera font family derivate with additional characters
ii  libfontconfig1:amd64          2.13.1-2ubuntu3                   amd64        generic font configuration library - runtime
ii  libfreetype6:amd64            2.10.1-2ubuntu0.3                 amd64        FreeType 2 font engine, shared library files
ii  libxft2:amd64                 2.3.3-0ubuntu1                    amd64        FreeType-based font drawing library for X
root@c89a801f8a30:/#    
root@c89a801f8a30:/# exit
```


- err ./configure @builder_tmux8

```bash
# tmux2: hand正常>> 脚本make提示少依赖项;
/mnt2/docker-x11base/compile/src # env |egrep "clang|FLAGS"
CXXFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer
CXX=xx-clang++
CC=xx-clang


# tmux8: hand ./configure正常; 脚本: C compiler cannot create executables
configure: error: in '/tmp/openbox':
configure: error: C compiler cannot create executables
#手动
bash-5.1# env |egrep "clang|FLAGS"
bash-5.1# 
# 脚本
CXXFLAGS=-Os -fomit-frame-pointer
CFLAGS=-Os -fomit-frame-pointer
CPPFLAGS=-Os -fomit-frame-pointer
# LDFLAGS=-Wl,--as-needed --static -static -Wl,--strip-all
CXX=xx-clang++
CC=xx-clang


# 注释后，./configure正常
# export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

# make, make install: 非静态
bash-5.1# ls -lh /tmp/openbox/openbox/openbox
-rwxr-xr-x    1 root     root      924.4K Nov  6 10:36 /tmp/openbox/openbox/openbox
```

## Fluxbox

```bash
# fontconfig ./configure参数查看;
  106  cd /tmp/openbox
  107  ./configure  --help
  108  pwd
  109  ls
  110  ls ..
  111  cd ../libxrandr/
  112  ./configure  --help
  113  cd ../fontconfig
  114  ./configure  --help

# builder_tmux8
root@VM-12-9-ubuntu:~# docker run -it --rm -v /mnt:/mnt2  infrastlabs/x11-base:builder bash
bash-5.1# 
bash-5.1# apk add git gawk
bash-5.1# cd /mnt2/docker-x11base/compile/src/
bash-5.1# git pull
# 
bash-5.1# export TARGETPATH=/usr
bash-5.1# bash _ex/fontconfig/build.sh 

# VIEW
bash-5.1# pwd
/tmp/fontconfig-install
bash-5.1# ls
config  usr
bash-5.1# find config/
config/
config/xdg
config/xdg/cache
config/xdg/cache/fontconfig
# bash-5.1# find usr/ -type d -maxdepth 3
usr/
usr/bin
usr/include
usr/include/fontconfig
usr/lib
usr/lib/pkgconfig
usr/share
usr/share/fontconfig
usr/share/fontconfig/conf.avail
usr/share/fontconfig/conf.d
usr/share/gettext
usr/share/gettext/its
usr/share/fonts
usr/share/xml
usr/share/xml/fontconfig


bash x-xrdp/build.sh libxrandr; 
bash fluxbox/build.sh fluxbox;
# openbox/build.sh出现(手动执行./configure正常); gitac_purex64_同样错误;
# configure: error: C compiler cannot create executables ##Fluxbox下出现.
```


```bash
# hand> fluxbox
cd /tmp/fluxbox
autoreconf -fi
export TARGETPATH=/usr/local/static/fluxbox
./configure \
  --prefix=$TARGETPATH \
  --enable-xmb \
  --enable-slit \
  --enable-toolbar \
  --enable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --disable-xft \
  --disable-xinerama \
  --disable-docs \
  \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread    -lfontconfig -lfreetype -luuid"

# make
make clean
make LDFLAGS="-static"

/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lfontconfig
collect2: error: ld returned 1 exit status
make[2]: *** [Makefile:2165: fluxbox] Error 1
make[2]: Leaving directory '/tmp/fluxbox'
make[1]: *** [Makefile:4901: all-recursive] Error 1
make[1]: Leaving directory '/tmp/fluxbox'
make: *** [Makefile:1760: all] Error 2
# bash-5.1# find /usr/lib |grep fontconf
/usr/lib/pkgconfig/fontconfig.pc
/usr/lib/libfontconfig.so.1.12.0
/usr/lib/libfontconfig.so
/usr/lib/libfontconfig.so.1
# bash-5.1# cp /tmp/fontconfig-install/usr/lib/
libfontconfig.a   libfontconfig.la  pkgconfig/        
# bash-5.1# cp /tmp/fontconfig-install/usr/lib/* /usr/lib/
cp: omitting directory '/tmp/fontconfig-install/usr/lib/pkgconfig'
# bash-5.1# cp /tmp/fontconfig-install/usr/lib/libfontconfig.a /usr/lib/
# makeOK;

make install

# 47.0M??
bash-5.1# cd /usr/local/static/fluxbox/bin/
bash-5.1# ls -lh
total 83M    
-rwxr-xr-x    1 root     root       11.3M Nov  7 09:27 fbrun
-rwxr-xr-x    1 root     root       17.3K Nov  7 09:27 fbsetbg
-rwxr-xr-x    1 root     root       11.2M Nov  7 09:27 fbsetroot
-rwxr-xr-x    1 root     root       47.0M Nov  7 09:27 fluxbox
-rwxr-xr-x    1 root     root       65.8K Nov  7 09:27 fluxbox-generate_menu
-rwxr-xr-x    1 root     root        3.1M Nov  7 09:27 fluxbox-remote
-rwxr-xr-x    1 root     root       10.2M Nov  7 09:27 fluxbox-update_configs
-rwxr-xr-x    1 root     root        1.3K Nov  7 09:27 startfluxbox
```

- **flux try run**

```bash
# run
mkdir -p /usr/local/static
ln -s  /mnt2/usr-local-static-cp/tigervnc /usr/local/static/tigervnc
/usr/local/static/tigervnc/bin/Xvnc :21 &
export DISPLAY=:21


# bash-5.1# ./fluxbox
Setting default value
Couldn\'t initialize fonts. Check your fontconfig installation.
bash-5.1# 
# bash-5.1# \cp -a /tmp/fontconfig-install/config/ /
# bash-5.1# find /tmp/fontconfig-install/usr/ -type d -maxdepth 3
/tmp/fontconfig-install/usr/
/tmp/fontconfig-install/usr/bin
/tmp/fontconfig-install/usr/include
/tmp/fontconfig-install/usr/include/fontconfig
/tmp/fontconfig-install/usr/lib
/tmp/fontconfig-install/usr/lib/pkgconfig
/tmp/fontconfig-install/usr/share
/tmp/fontconfig-install/usr/share/fontconfig
/tmp/fontconfig-install/usr/share/fontconfig/conf.avail
/tmp/fontconfig-install/usr/share/fontconfig/conf.d
/tmp/fontconfig-install/usr/share/gettext
/tmp/fontconfig-install/usr/share/gettext/its
/tmp/fontconfig-install/usr/share/fonts
/tmp/fontconfig-install/usr/share/xml
/tmp/fontconfig-install/usr/share/xml/fontconfig
# bash-5.1# \cp -a /tmp/fontconfig-install/usr/share/* /usr/share/
# bash-5.1# \cp -a /tmp/fontconfig-install/usr/* /usr/


# bash-5.1# ./fluxbox -h
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

# bash-5.1# ./fluxbox -info
Fluxbox version: 1.3.7
GIT Revision: 0f95d62b1b1add8ee7327305db7d372010fdb2f4
Compiled: Nov  7 2023 09:22:19
Compiler: GCC
Compiler version: 10.3.1 20211027
Defaults: 
       menu: /usr/local/static/fluxbox/share/fluxbox/menu
 windowmenu: /usr/local/static/fluxbox/share/fluxbox/windowmenu
      style: /usr/local/static/fluxbox/share/fluxbox/styles/bloe
       keys: /usr/local/static/fluxbox/share/fluxbox/keys
       init: /usr/local/static/fluxbox/share/fluxbox/init
Compiled options (- => disabled): 
BIDI
-DEBUG
EWMH
-IMLIB2
-NLS
REMEMBER
RENDER
SHAPE
SLIT
SYSTEMTRAY
TOOLBAR
RANDR
-XFT
-XINERAMA
XMB
-XPM

# bash-5.1# ./fluxbox -list-commands


# apk add font-wqy-zenhei@edge
# apk add font-noto-cjk
# 错误依旧
```

- enable-xft

```bash
# std::cerr << "Couldn't initialize fonts. Check your fontconfig installation.\n";
# @Font.cc XFT>> XMB
# --enable-xft \

    # libx11-dev \
    # libx11-static \
    # libxcb-static \
    # libxdmcp-dev \
    # libxau-dev \
    # freetype-static \
apk add libxml2-dev expat-static 

# 加上后，依旧err_deps; ./configure LIBS=XX; >> tmux8_c.compile错误，tmux2_OK;
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make LDFLAGS="$flags"

# run:
/tmp/fluxbox # #./fluxbox
Setting default value
Couldn\'t initialize fonts. Check your fontconfig installation. ##ERR
/tmp/fluxbox # ls fluxbox -lh
-rwxr-xr-x    1 root     root       12.1M Nov  7 12:11 fluxbox


# runtime deps>> 已装，也不行;
/tmp/fluxbox # apk add fluxbox
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
OK: 915 MiB in 370 packages


# src查看; try改/font错误
# 安装任一font即可?

```


- cp2 [**libs clear**], `--disable-xmb`

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
# disable-nls: /bin/sh: fluxbox.cat: not found (native language support)
# imlib2: 无static
./configure \
  --prefix=/usr/local/static/fluxbox \
  --disable-xmb \
  --enable-slit \
  --enable-toolbar \
  --enable-fribidi \
  \
  --disable-imlib2 \
  --disable-nls \
  --enable-xft \
  --enable-xinerama \
  \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"

# make去flags>> OK;
# --static -static ##ex>> +: -static
flags="-static -lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
make LDFLAGS="$flags"

make clean
make LDFLAGS="-static" #OK;


# --disable-xmb \ >> 也不行
```

- 之后安装font即可？(ubt默认有; alpine:`ttf-dejavu`)

