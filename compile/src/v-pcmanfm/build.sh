#!/bin/sh
set -e
source /src/common.sh

# git clone https://hub.nuaa.cf/GNOME/atk #3.29 MiB 1985> ATK_2_36_0 1943
# git clone https://hub.nuaa.cf/GNOME/gtk #644.58 MiB 78343> 2.24.33 21885
# git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf #177.02 MiB 6226> 2.42.8 6113
# git clone https://hub.nuaa.cf/lxde/menu-cache #297 commits


# tmux-3
# bash-5.1# history |grep "apk add"
#   949  apk x gdk-pixbuf-dev pango-dev
#libatk-1.0
#libatk
#atk
#gobject-introspection
#gobject-introspection-dev
#fontconfig-static
#  1411  history |grep "apk add"
# 
# 
# bash-5.1# apk x gdk-pixbuf-dev #@tmux-8
# (1/10) Installing shared-mime-info (2.1-r2)
# (2/10) Installing libwebp (1.2.2-r2)
# (3/10) Installing tiff (4.4.0-r4)
# (4/10) Installing gdk-pixbuf (2.42.8-r0)
# (5/10) Installing libwebp-dev (1.2.2-r2)
# (6/10) Installing xz-dev (5.2.5-r1)
# (7/10) Installing zstd-dev (1.5.0-r0)
# (8/10) Installing libtiffxx (4.4.0-r4)
# (9/10) Installing tiff-dev (4.4.0-r4)
# (10/10) Installing gdk-pixbuf-dev (2.42.8-r0)
# 
# bash-5.1# apk x atk
# (1/1) Installing atk (2.36.0-r0)
# 
# bash-5.1# apk x gobject-introspection-dev
# (1/2) Installing gobject-introspection (1.70.0-r1)
# (2/2) Installing gobject-introspection-dev (1.70.0-r1)
# 
# bash-5.1# apk x fontconfig-static
# (1/1) Installing fontconfig-static (2.13.1-r4)

# libfm
function libfm(){
  # intltool #builder装过了？？ (调试img:没得)
  # apk update; apk add gtk-doc intltool vala \
  #  menu-cache-dev gtk+2.0-dev menu-cache-dev #1.1.0-r0


  log "Downloading libfm..."
  # down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/libfm
  branch="--branch=1.3.1" #1.3.2
  branch="--branch=1.3.2" # #ok with automake @alpine315 
  repo=https://gitee.com/g-system/fk-libfm
  rm -rf /tmp/libfm; git clone --depth=1 $branch $repo /tmp/libfm
  cd /tmp/libfm
    # attempted static link of dynamic object `/usr/lib/libmenu-cache.so'
    #ref_pcmanfm.md>> # 改动态编译：OK
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    # export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

    # 
    ##./autogen.sh: line 45: intltoolize: not found  ##1.3.2也不行
    # ./autogen.sh 
    bash autogen.sh #错误同上
    ./configure; 

  log "Compiling libfm..."
  make

  log "Installing libfm..."
  make install

  \cp -a /usr/local/lib/libfm.a /usr/local/lib/libfm-gtk.a /usr/lib/ ##拷贝两个静态库到/usr/lib
}

# lxde/menu-cache
# 
# /usr/bin/x86_64-alpine-linux-musl-ld: menu-compose.o:(.bss+0x30): multiple definition of `verbose'; main.o:(.bss+0x10): first defined here
# clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
# 
# try: 先编译>> atk gdk-pixbuf gtk (错误依旧)
# openbox两个依赖项 (错误依旧) >> 改master (编译OK)
# pango:
# (1/7) Installing cairo-static (1.16.0-r5)
# (2/7) Installing expat-static (2.5.0-r0)
# (3/7) Installing fribidi-static (1.0.11-r0)
# (4/7) Installing glib-static (2.70.5-r0)
# (5/7) Installing graphite2-static (1.3.14-r0)
# (6/7) Installing harfbuzz-static (3.0.0-r2)
# (7/7) Installing libxml2-dev (2.9.14-r2)
# 
function menu-cache(){ ##依赖libfm-extra @libfm
  # apk update; apk add gtk-doc
  # apk x libfm-extra-dev ##可过./configure检查; 但ld -lfm-extra静态库错误

  log "Downloading menu-cache..."
  # branch="--branch=1.1.0" #default master [1.1.0:294commits@ubt2004; master:297commits@ff]
  # repo=$GITHUB/lxde/menu-cache
  repo=https://gitee.com/g-system/fk-menu-cache
  rm -rf /tmp/menu-cache; git clone --depth=1 $branch $repo /tmp/menu-cache
  cd /tmp/menu-cache
    # attempted static link of dynamic object `/usr/local/lib/libfm-extra.so'
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    ./autogen.sh 
    ./configure --enable-static; 

  log "Compiling menu-cache..."
  make

  log "Installing menu-cache..."
  make install

  find /usr/local/lib |grep "menu-cache.*\.a$"
  cp /usr/local/lib/libmenu-cache.a /usr/lib/
}

#
# Build pcmanfm
#
# 
# checking whether the C compiler works... no
# configure: error: in `/tmp/pcmanfm':
# configure: error: C compiler cannot create executables
# See `config.log' for more details
# 
# export TARGETPATH=/usr/local/static/pcmanfm
# LDFLAGS去 -static （一样错误）
# 
# 检查静态库;
# bash-5.1# find /usr/lib |grep pango |grep "\.a$"
# /usr/lib/libpangoxft-1.0.a
# /usr/lib/libpango-1.0.a
# /usr/lib/libpangocairo-1.0.a
# /usr/lib/libpangoft2-1.0.a
# 
# bash-5.1# find /usr/lib |egrep "g.*bject-2.0.a"
# /usr/lib/libgobject-2.0.a #少了gmodule-2.0
# 
# bash-5.1# find /usr/lib |grep Xcomposite
# /usr/lib/libXcomposite.so.1  #无静态库
# /usr/lib/libXcomposite.so.1.0.0
# # bash-5.1# apk x libxcomposite-dev
# (1/1) Installing libxcomposite-dev (0.4.5-r0)
# OK: 935 MiB in 321 packages
# bash-5.1# find /usr/lib |grep Xcomposite
# /usr/lib/libXcomposite.a
# 
function pcmanfm(){
  # libxcomposite-dev ##装后，手动configure:  C compiler cannot create executables错误过了;
  # apk update; apk add fontconfig-static libxcomposite-dev

  log "Downloading PCMANFM..."
  rm -rf /tmp/pcmanfm; # mkdir -p /tmp/pcmanfm
  # down_catfile ${PCMANFM_URL} | tar -zx --strip 1 -C /tmp/pcmanfm
  branch="--branch=1.3.1"
  repo=$GITHUB/lxde/pcmanfm
  rm -rf /tmp/pcmanfm; git clone --depth=1 $branch $repo /tmp/pcmanfm #;
  log "Configuring PCMANFM..."
  cd /tmp/pcmanfm #&& ./bootstrap;
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    ./autogen.sh
    # ./configure  --enable-static --prefix=$TARGETPATH
    # make
    # make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
    # 
    # --enable-static --prefix=$TARGETPATH
    #  --enable-static
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -lmenu-cache -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    LIBS="$LIBS0" ./configure --prefix=$TARGETPATH

  log "Compiling PCMANFM..."
    # # x86_64-alpine-linux-musl/bin/ld: cannot find -lXdamage
    # make LDFLAGS="-static " 2>&1
    # # build.sh>> 手动make @tmux-8 OK;
    # # bash-5.1# ls src/pcmanfm -lh
    # # -rwxr-xr-x    1 root     root       37.6M Dec  1 04:16 src/pcmanfm
    # 
    make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0" 2>&1

  log "Install PCMANFM..."
    # make;
    make install 2>&1 > /dev/null

  # view
  ls -lh $TARGETPATH/bin/pcmanfm
  xx-verify --static $TARGETPATH/bin/pcmanfm #/tmp/pcmanfm/src/pcmanfm
}

function apkdeps(){
  apk update; 
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      menu-cache-dev gtk+2.0-dev menu-cache-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    atk
    gdk-pixbuf
    gtk ##long-cost: 共历时766秒 (比首次手动长??)
    libfm
    menu-cache
    pcmanfm
    ;;
b_deps)
    # bash /src/openbox/build.sh apkdeps
    # bash /src/openbox/build.sh pango & ##needed by gtk
    # bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    # bash /src/xcompmgr/build.sh Xdamage &
    # wait
    # # 
    apkdeps
    # bash /src/v-pcmanfm/build.sh atk & #needed by gtk
    # bash /src/v-pcmanfm/build.sh gdk-pixbuf & #needed by gtk
    # wait
    # bash /src/v-pcmanfm/build.sh gtk
    bash /src/v-pcmanfm/build.sh libfm
    bash /src/v-pcmanfm/build.sh menu-cache #在libfm之后

    # view x8; +libgdk
    # lost: Xrandr, atk, gtk
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk|libfm|menu-cache" |grep "\.a$" |sort
    # /usr/lib/libXdamage.a
    # /usr/lib/libXrandr.a
    # /usr/lib/libatk-1.0.a
    # /usr/lib/libfm-gtk.a
    # /usr/lib/libfm.a
    # /usr/lib/libgdk_pixbuf-2.0.a
    # /usr/lib/libgtk-x11-2.0.a
    # /usr/lib/libmenu-cache.a
    # /usr/lib/libpango-1.0.a
    # /usr/lib/libpangocairo-1.0.a
    # /usr/lib/libpangoft2-1.0.a
    # /usr/lib/libpangoxft-1.0.a
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0

# dbg:
# root@tenvm2:~# docker run -it --rm --privileged -v /mnt:/mnt2 infrastlabs/x11-base:builder bash
apk add gawk git
cd /mnt2/docker-x11base/compile/
ln -s $(pwd)/src /src
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
git pull; bash src/v-pcmanfm/build.sh b_deps
export TARGETPATH=/usr/local/static/pcmanfm
bash src/v-pcmanfm/build.sh pcmanfm

# #gtk全部构建>> build.sh pcmanfm>> 生成pcmanfm静态文件成功
>>> Install PCMANFM...
-rwxr-xr-x    1 root     root       37.1M Dec  1 19:23 /opt/base/bin/pcmanfm


# 单独再重试，pcmanfm又出现依赖错: 
# gdkscreen-x11.c:(.text+0xd69): undefined reference to `XineramaQueryScreens'
# libgdk-x11-2.0.a(gdkscreen-x11.o): in function `_gdk_x11_screen_size_changed'

