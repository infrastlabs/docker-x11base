#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.


# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-pcmanfm #git clone;
PCMANFM_VER=0.8.4
PCMANFM_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang

# set -u; err if not exist
test -z "$TARGETPATH" && export TARGETPATH=/opt/base
test -z "$CONSOLE_LOG" && export CONSOLE_LOG=yes
# rm -rf $LOGS; #avoid deleted @batch-mode
CACHE=$TARGETPATH/../.cache; LOGS=$TARGETPATH/../.logs; mkdir -p $CACHE $LOGS
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f $CACHE/$file || curl -# -k -fSL $url > $CACHE/$file
  cat $CACHE/$file
}
function print_time_cost(){
    local begin_time=$1
	gawk 'BEGIN{
		print "本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}' 2>&1 | tee -a $logfile
}
function log {
    echo -e "\n\n>>> $*"
}


# export CC=clang
# export CXX=clang++


# git clone https://hub.nuaa.cf/GNOME/atk #3.29 MiB 1985> ATK_2_36_0 1943
# git clone https://hub.nuaa.cf/GNOME/gtk #644.58 MiB 78343> 2.24.33 21885
# git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf #177.02 MiB 6226> 2.42.8 6113
# git clone https://hub.nuaa.cf/lxde/menu-cache #297 commits

function atk(){ ##@meson
  apk add gobject-introspection-dev

  log "Downloading atk..."
  branch="--branch=ATK_2_35_1" #ATK_2_36_0  [2.35.1@ubt2004; 2.36.0@alpine315]
  branch="--branch=ATK_2_36_0"
  repo=https://hub.njuu.cf/GNOME/atk #nuaa> njuu
  rm -rf /tmp/atk; git clone --depth=1 $branch $repo /tmp/atk
  cd /tmp/atk
    # [44/53] Linking static target atk/libatk-1.0.a
    # [45/53] Linking target atk/libatk-1.0.so.0.23510.1 ##err attempted static link of dynamic object '/usr/lib/libglib-2.0.so'
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    # ./autogen.sh 
    # ./configure --enable-static; 
    # meson build
    meson build  --default-library=both

  log "Compiling atk..."
    # make
    ninja -C build/

  log "Installing atk..."
    # make install
    ninja -C build/ install
  
  cp -a /usr/local/lib/libatk-1.0.a /usr/lib/
}

# meson build>> clone: gi-docgen [by meson_py slow..; meson两个文件未找到docgen信息]
function gdk-pixbuf(){ ##@meson
  apk add shared-mime-info

  log "Downloading gdk-pixbuf..."
  branch="--branch=2.40.0" #2.42.8 [2.40.0@ubt2004; 2.42.8@alpine315]
  branch="--branch=2.42.8"
  repo=https://hub.njuu.cf/GNOME/gdk-pixbuf
  rm -rf /tmp/gdk-pixbuf; git clone --depth=1 $branch $repo /tmp/gdk-pixbuf
  cd /tmp/gdk-pixbuf
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #同atk
    # ./autogen.sh 
    # ./configure; 
    # meson build
    meson build  --default-library=both

  log "Compiling gdk-pixbuf..."
    # 去除xsltproc;
    dst=/usr/bin/xsltproc
    mv $dst ${dst}00
    touch $dst; chmod +x $dst
    echo -e "!/bin/bash\n echo 123" > $dst

    # make
    ninja -C build

  log "Installing gdk-pixbuf..."
    touch build/docs/gdk-pixbuf-csource.1
    touch build/docs/gdk-pixbuf-query-loaders.1
    # make install
    ninja -C build install
  
  ls -lh /usr/local/lib/libgdk_pixbuf-2.0.a #hand: 1016.6K> build.sh_ver2.40.0_hand: 807.2K
  cp /usr/local/lib/libgdk_pixbuf-2.0.a /usr/lib/ #1016.4K @alpine's_ver_2.42.8
  # cp ./build/gdk-pixbuf/libgdk_pixbuf-2.0.a
}

# You must have automake 1.7.x, 1,10.x, 1.11.x, 1.12.x, 1.13.x, 1.14.x
# or 1.15.x installed to compile Gtk+.
# Install the appropriate package for your distribution,
# or get the source tarball at http://ftp.gnu.org/gnu/automake/
# bash-5.1# apk list |grep automake  ##版本过高?
# automake-1.16.4-r1 x86_64 {automake} (GPL-2.0-or-later MIT Public-Domain) [installed]

# 改2.24.33;
# checking for gdk-pixbuf-csource... /usr/local/bin/gdk-pixbuf-csource
# checking for XOpenDisplay... no
# configure: error: *** libX11 not found. Check 'config.log' for more details.
# 
# xcompmgr>> # ref: opbox>> deps: 已全装
# 试着改回: meson的两个; （一样错：libX11 not found）
function gtk(){
  apk add gtk-doc

  log "Downloading gtk..."
  branch="--branch=2.24.32" #2.24.33  ##提示automake版本不符(过高)
  branch="--branch=2.24.33"
  # nuaa, yzuu, njuu
  # https://blog.csdn.net/weixin_46591962/article/details/132247425
  repo=https://hub.yzuu.cf/GNOME/gtk
  rm -rf /tmp/gtk; git clone --depth=1 $branch $repo /tmp/gtk
  cd /tmp/gtk
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    ./autogen.sh 
    ./configure --enable-static; 

  log "Compiling gtk..."
  make

  log "Installing gtk..."
  # make[3]: *** [/usr/share/gobject-introspection-1.0/Makefile.introspection:156: Gdk-2.0.gir] Error 1
  make install  #make, make install err:>> 不影响静态库的生成 及安装到/usr/local/lib/libgdk_pixbuf-2.0.a

  find /usr/local/lib |egrep "g.*k-x11.*\.a$"
  cp /usr/local/lib/libgdk-x11-2.0.a /usr/local/lib/libgtk-x11-2.0.a /usr/lib/
}



# tmux-3
# bash-5.1# history |grep "apk add"
#   949  apk add gdk-pixbuf-dev pango-dev
#   950  apk add libatk-1.0
#   951  apk add libatk
#   952  apk add atk
#  1015  apk add gobject-introspection
#  1017  apk add gobject-introspection-dev
#  1184  apk add fontconfig-static
#  1411  history |grep "apk add"
# 
# 
# bash-5.1# apk add gdk-pixbuf-dev #@tmux-8
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
# bash-5.1# apk add atk
# (1/1) Installing atk (2.36.0-r0)
# 
# bash-5.1# apk add gobject-introspection-dev
# (1/2) Installing gobject-introspection (1.70.0-r1)
# (2/2) Installing gobject-introspection-dev (1.70.0-r1)
# 
# bash-5.1# apk add fontconfig-static
# (1/1) Installing fontconfig-static (2.13.1-r4)

# libfm
function libfm(){
  apk add gtk-doc
  apk add intltool #builder装过了？？ (调试img:没得)
  apk add vala
  # 
  apk add menu-cache-dev
  apk add gtk+2.0-dev #gtk+
  apk add menu-cache-dev #1.1.0-r0


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
  apk add gtk-doc
  # apk add libfm-extra-dev ##可过./configure检查; 但ld -lfm-extra静态库错误

  log "Downloading menu-cache..."
  # branch="--branch=1.1.0" #default master [1.1.0:294commits@ubt2004; master:297commits@ff]
  # repo=https://hub.nuaa.cf/lxde/menu-cache
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
# # bash-5.1# apk add libxcomposite-dev
# (1/1) Installing libxcomposite-dev (0.4.5-r0)
# OK: 935 MiB in 321 packages
# bash-5.1# find /usr/lib |grep Xcomposite
# /usr/lib/libXcomposite.a
# 
function pcmanfm(){
  apk add fontconfig-static
  apk add libxcomposite-dev

  log "Downloading PCMANFM..."
  rm -rf /tmp/pcmanfm; # mkdir -p /tmp/pcmanfm
  # down_catfile ${PCMANFM_URL} | tar -zx --strip 1 -C /tmp/pcmanfm
  branch="--branch=1.3.1"
  # nuaa, yzuu, njuu
  repo=https://hub.yzuu.cf/lxde/pcmanfm
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
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
    LIBS=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1" \
     ./configure --prefix=$TARGETPATH

  log "Compiling menu-cache..."
    make LDFLAGS="-static " 2>&1

  log "Install PCMANFM..."
    # make;
    make install;

  # view
  ls -lh /tmp/pcmanfm/
  xx-verify --static /tmp/pcmanfm/pcmanfm
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
    bash /src/openbox/build.sh pango & ##needed by gtk
    bash /src/openbox/build.sh libxrandr &
    /src/v-pcmanfm/build.sh atk & #needed by gtk
    wait
    # 
    /src/v-pcmanfm/build.sh gdk-pixbuf &
    /src/v-pcmanfm/build.sh gtk &
    wait
    /src/v-pcmanfm/build.sh libfm
    /src/v-pcmanfm/build.sh menu-cache #在libfm之后
    ;;
*) #compile
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    set +e
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/pcmanfm-$1.log
    test "yes" == "$CONSOLE_LOG" && echo yes || echo no
    test "yes" == "$CONSOLE_LOG" && $1 |tee $logfile || $1 > $logfile 2>&1;
    # $1 > $logfile 2>&1;

    test "0" !=  "$?" && tail -200 $logfile || echo "err 0, pass"
    print_time_cost $begin_time; echo "$1, finished."
    ;;          
esac
exit 0
