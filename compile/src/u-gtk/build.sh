#!/bin/sh
set -e
source /src/common.sh

function atk(){ ##@meson
  # apk update; apk add gobject-introspection-dev

  log "Downloading atk..."
  branch="--branch=ATK_2_35_1" #ATK_2_36_0  [2.35.1@ubt2004; 2.36.0@alpine315]
  branch="--branch=ATK_2_36_0"
  repo=$GITHUB/GNOME/atk #nuaa> njuu
  rm -rf /tmp/atk; git clone --depth=1 $branch $repo /tmp/atk
  cd /tmp/atk
    # [44/53] Linking static target atk/libatk-1.0.a
    # [45/53] Linking target atk/libatk-1.0.so.0.23510.1 ##err attempted static link of dynamic object '/usr/lib/libglib-2.0.so'
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    # ./autogen.sh 
    # ./configure --enable-static; 
    # meson build
    # static>> undefined reference to 'png_destroy_write_struct'
    meson build  --default-library=both #both static

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
  # apk update; apk add shared-mime-info

  log "Downloading gdk-pixbuf..."
  branch="--branch=2.40.0" #2.42.8 [2.40.0@ubt2004; 2.42.8@alpine315]
  branch="--branch=2.42.8"
  repo=$GITHUB/GNOME/gdk-pixbuf
  rm -rf /tmp/gdk-pixbuf; git clone --depth=1 $branch $repo /tmp/gdk-pixbuf
  cd /tmp/gdk-pixbuf
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #同atk
    # ./autogen.sh 
    # ./configure; 
    # meson build
    meson build  --default-library=both #both static

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
  # apk update; apk add gtk-doc shared-mime-info

  log "Downloading gtk..."
  branch="--branch=2.24.32" #2.24.33  ##提示automake版本不符(过高)
  branch="--branch=2.24.33"
  # https://blog.csdn.net/weixin_46591962/article/details/132247425
  repo=$GITHUB/GNOME/gtk
  rm -rf /tmp/gtk; git clone --depth=1 $branch $repo /tmp/gtk
  cd /tmp/gtk
    args="--disable-option-checking \
      --disable-FEATURE  \
      --disable-silent-rules \
      --disable-dependency-tracking \
      --enable-fast-install=yes \
      --disable-libtool-lock  \
      --disable-largefile  \
      --disable-maintainer-mode \
      --enable-shm=no \
      --enable-xkb=yes \
      --enable-xinerama=no \
      --disable-rebuilds \
      --disable-visibility \
      --enable-explicit-deps=no \
      --disable-glibtest    \
      --disable-modules     \
      --disable-cups \
      --disable-papi \
      --enable-introspection=no \
      --enable-gtk-doc=no \
      --enable-gtk-doc-html=no \
      --enable-gtk-doc-pdf=no \
      --enable-man=no"
      # --enable-static=yes \
      # --enable-shared=no \
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    ./autogen.sh 
    # --enable-xkb=yes \ #no>yes
    ./configure --enable-static \
      $args1 #args1还是缺依赖;

  log "Compiling gtk..."
    # make -j$(nproc) #gtk全部构建>> build.sh pcmanfm>> 生成pcmanfm静态文件成功
    # 
    # retry2
    make -j$(nproc) -C gdk & #first
    make -j$(nproc) -C gtk &
    wait
    find |egrep "g.*k-x11.*\.a$"
    # ./gdk/.libs/libgdk-x11-2.0.a
    # ./gtk/.libs/libgtk-x11-2.0.a
    # ./gdk/x11/.libs/libgdk-x11.a
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a 
    # -rw-r--r--    1 root     root        5.0M Dec  1 17:12 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root       33.2M Dec  1 17:14 ./gtk/.libs/libgtk-x11-2.0.a
    # with args lite?
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a 
    # -rw-r--r--    1 root     root        1.1M Dec  1 17:52 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.6M Dec  1 17:56 ./gtk/.libs/libgtk-x11-2.0.a
    # without args
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a
    # -rw-r--r--    1 root     root        1.2M Dec  1 18:26 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.9M Dec  1 18:33 ./gtk/.libs/libgtk-x11-2.0.a
    # make -j$(nproc) #根目录下构建; >> build.sh pcmanfm>> 生成静态文件ok
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a
    # -rw-r--r--    1 root     root        1.2M Dec  1 18:56 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.9M Dec  1 19:05 ./gtk/.libs/libgtk-x11-2.0.a

  log "Installing gtk..."
    # make[3]: *** [/usr/share/gobject-introspection-1.0/Makefile.introspection:156: Gdk-2.0.gir] Error 1
    # make install  #make, make install err:>> 不影响静态库的生成 及安装到/usr/local/lib/libgdk_pixbuf-2.0.a
    # find /usr/local/lib |egrep "g.*k-x11.*\.a$"
    # cp /usr/local/lib/libgdk-x11-2.0.a /usr/local/lib/libgtk-x11-2.0.a /usr/lib/

    # ./gdk/x11/.libs/libgdk-x11.a 
    \cp -a ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a /usr/lib/
}


function apkdeps(){
  apk update; 
      # menu-cache-dev \
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      gtk+2.0-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    echo "emp";
    ;;
b_deps)
    bash /src/openbox/build.sh apkdeps
    bash /src/openbox/build.sh pango & ##needed by gtk
    bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    bash /src/xcompmgr/build.sh Xdamage &
    wait
    # 
    apkdeps
    bash /src/u-gtk/build.sh atk & #needed by gtk
    bash /src/u-gtk/build.sh gdk-pixbuf & #needed by gtk
    wait
    bash /src/u-gtk/build.sh gtk

    # view
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk" |grep "\.a$" |sort #|libfm|menu-cache
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
