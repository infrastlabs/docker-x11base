#!/bin/sh
set -e
source /src/common.sh

# 
LIBCROCO_URL=https://mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz

# libcroco
# https://github.com/OpenMandrivaAssociation/libcroco0.6/blob/master/libcroco0.6.spec #ref url @gnome
# https://mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz
function libcroco(){
  # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
  export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"

  mkdir -p /tmp/libcroco
  log "Downloading libcroco..."
  # repo=
  # rm -rf /tmp/libcroco; git clone --depth=1 $branch $repo /tmp/libcroco
  # cd /tmp/libcroco
  down_catfile ${LIBCROCO_URL} | tar -Jx --strip 1 -C /tmp/libcroco
  cd /tmp/libcroco
  # cd libcroco-0.6.13
  ./autogen.sh 
  ./configure --enable-static

  log "Compiling libcroco..."
  make
  log "Installing libcroco..."
  make install
  # find |grep croco; cp ./src/.libs/libcroco-0.6.a /usr/lib/
  find /usr/local/lib |grep libcroco |grep "\.a$"
  # /usr/local/lib/libcroco-0.6.a
}

# _deps/_tint/libcroco, librsvg, xcb__util; make install x3;
# # isvg改用1.40.xx  ==> make 缺: -lcroco-0.6
# # tint2 make, ld缺: -lxcb-util -lcroco-0.6 -lrsvg-2
# 
# libart-2.0
# bash-5.1# git clone https://hub.yzuu.cf/Distrotech/libart #Mirror of git://git.gnome.org/libart_lgpl 
# bash-5.1# git checkout LIBART_LGPL_2_3_21
# bash-5.1# ./autogen.sh 
# 
# librsvg-2.50.7-r1 @alpine315
# librsvg-2.5.0.tar.gz @sourceforge
# https://sourceforge.net/projects/librsvg/files/librsvg/2.5.0/librsvg-2.5.0.tar.gz
# /mnt2/_deps/librsvg-2.5.0
# bash-5.1# ./configure
# 
# [librsvg]
# https://github.com/GNOME/librsvg #9298commits [rust 83.6%]
# https://github.com/GNOME/librsvg/tree/2.50.7 #6499commits
# https://github.com/GNOME/librsvg/tree/2.41.0/ #1845commits @2017.1.4 ./rust/Cargo.toml
# https://github.com/GNOME/librsvg/tree/2.40.21 #1718commits @2020.2.27
# https://github.com/GNOME/librsvg/tree/2.40.17 #1598commits @2017.4.8
# https://github.com/GNOME/librsvg/tree/2.35.0 #1258commits @2011.11.15
# https://github.com/loic/librsvg/tree/LIBRSVG_2_31_0 #1149commits
# Package 'libcroco-0.6', required by 'virtual:world', not found
# 
function librsvg(){
  # attempted static link of dynamic object `/usr/local/lib/libcroco-0.6.so'
  export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
  log "Downloading librsvg..."
  # git clone $GITHUB/GNOME/librsvg
  # git checkout 2.40.21 #2.50.7
  repo=$GITHUB/GNOME/librsvg
  branch="--branch=2.40.21"
  rm -rf /tmp/librsvg; git clone --depth=1 $branch $repo /tmp/librsvg
  cd /tmp/librsvg
  ./autogen.sh 
  ./configure --enable-static
  log "Compiling librsvg..."
  make 
  log "Installing librsvg..."
  make install
  # find |grep librsvg-
  # ./.libs/librsvg-2.a
  find /usr/local/lib |grep librsvg |grep "\.a$"
}

# [xcb-util]
function xcbutil(){
  log "Downloading xcb_util..."
  repo=$GITHUB/freedesktop-unofficial-mirror/xcb__util
  rm -rf /tmp/xcb-util; git clone --depth=1 $branch $repo /tmp/xcb-util
  cd /tmp/xcb-util
  # git clone $GITHUB/freedesktop-unofficial-mirror/xcb__util
  # cd xcb__util/
  apk add util-macros #ubt: xorg-macros
  sed -i "s^git://anongit.freedesktop.org/xcb/util-common-m4.git^https://gitee.com/g-system/util-common-m4.git^g" .gitmodules
  git submodule update --init
  ./autogen.sh 
  #  
  # cd /mnt2/_deps/xcb__util/
  log "Compiling xcb_util..."
  make
  log "Installing xcb_util..."
  make install
  find |grep libxcb-util
  # ./src/.libs/libxcb-util.a
  # ./src/.libs/libxcb-util.so
  find /usr/lib/ /usr/local/lib |grep libxcb-util |grep "\.a$"
}


# https://github.com/aleax/libxi
function libxi(){
  # git clone https://hub.yzuu.cf/aleax/libxi
  log "Downloading libxi..."
  repo=$GITHUB/aleax/libxi
  rm -rf /tmp/libxi; git clone --depth=1 $branch $repo /tmp/libxi
  cd /tmp/libxi
  ./autogen.sh 
  ./configure  --enable-static --disable-shared #disable dyn;
  log "Compiling libxi..."
  make
  log "Installing libxi..."
  make install
  find /usr/lib /usr/local/lib |grep libXi.a
  # /usr/local/lib/libXi.a
}

#
# Build tint2
#
# export TARGETPATH=/usr/local/static/tint2
# https://github.com/o9000/tint2 #1678commits @19.6.3
# https://github.com/o9000/tint2/tree/v16.1 #1594commits @17.12.30
# https://github.com/o9000/tint2/tree/v0.12.2 #771commits @15.8.11

# ref: pcmanfm
# 	OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
#   ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite" 
#   # -lXdamage注释也会用到;
#   ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage   -lX11-xcb -lxcb-shm -lxcb-render -lxcb-util -lmd -lcroco-0.6 -lImlib2" # -lfm -lfm-gtk 
#   LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1" 
# LIBS="-lXinerama -lXfixes -lXrandr $LIBS0"
# echo $LIBS |sed "s/-l//g"
# # Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage
# Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2

###CMAKE###################
# https://www.codenong.com/40618443/
# SET(CMAKE_FIND_LIBRARY_SUFFIXES".a")
# SET(BUILD_SHARED_LIBRARIES OFF)
# SET(CMAKE_EXE_LINKER_FLAGS"-static")
# # 
# 将其添加到find命令上方的CMakeLists.txt中：
# set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
# 
# # bash-5.1# cat ../CMakeLists.txt |grep rdynamic -n
# 47:             set(BACKTRACE_L_FLAGS "-rdynamic")
# 54:                     set(BACKTRACE_L_FLAGS "-rdynamic")
# 239:  SET(ASAN_C_FLAGS " -O0 -g3 -fsanitize=address -fno-common -fno-omit-frame-pointer -rdynamic -Wshadow")
# 240:  SET(ASAN_L_FLAGS " -O0 -g3 -fsanitize=address -fno-common -fno-omit-frame-pointer -rdynamic -fuse-ld=gold ")
# 248:  SET(TRACING_C_FLAGS " -finstrument-functions -finstrument-functions-exclude-file-list=tracing.c -finstrument-functions-exclude-function-list=get_time,gettime -O0 -g3 -fno-common -fno-omit-frame-pointer -rdynamic")
# 249:  SET(TRACING_L_FLAGS " -O0 -g3 -fno-common -fno-omit-frame-pointer -rdynamic")
# # 清理如上6个 -rdynamic: 还是依旧(attempted static link of dynamic object);

###IMLIB2###################
# 清理../build/*; >> imlib2 -x11检测失败; 
# # 本地下载源码>> 细看imlib2的配置
# # [imlib_context_set_display]
# # bash /src/xcompmgr/build.sh Xdamage
# bash /src/v-xlunch/build.sh imlib2
# # find-vscode: X_DISPLAY_MISSING @./Projects/_ee/_deps/imlib2-1.7.4
# xserver-xorg-dev @ubt
# apk add xorg-server-dev;

# 手动注释  #if( NOT IMLIB_BUILD_WITH_X )
  # # message( FATAL_ERROR "Imlib is not (跳过错误: Imlib not with X11)

###DEPS >> buidler-gtk224##############
# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# bash /src/v-tint2/build.sh b_deps #pango/xrand/xdamage>> atk/gdk >> gtk 
# # err link: 老样子: attempted static link of dynamic object `xxxx.so`
# # 试着移走so>> 全改名;
# 
# # 重名方法改名 strnappend02;
# find .. |grep battery.c
# cat ../src/battery/battery.c |grep strnappend
# sed -i "s/strnappend/strnappend02/g" ../src/battery/battery.c 
# cat ../src/battery/battery.c |grep strnappend
# # 重名方法改名>> tint2过了; tint2conf err:
function tint2(){
  # xcomposite-dev gtk+2.0-dev
  apk add pango-dev librsvg-dev
  apk add startup-notification-dev
  apk add libxcursor-dev
  # 
  # apk add imlib2-dev librsvg-dev gtk+2.0-dev  ##本地安装了，则会跳过install;


  log "Downloading TINT2..."
  rm -rf /tmp/tint2; # mkdir -p /tmp/tint2
  # down_catfile ${TINT2_URL} | tar -zx --strip 1 -C /tmp/tint2
  branch="--branch=16.1"
  repo=$GITHUB/o9000/tint2
  rm -rf /tmp/tint2; git clone --depth=1 $branch $repo /tmp/tint2 #;
  log "Configuring TINT2..."
  cd /tmp/tint2 #&& ./bootstrap;
    # sed -i "s^bash extra/genentries^#bash extra/genentries^g" Makefile
    
    mkdir -p build; cd build
      # message( FATAL_ERROR "Imlib is not (跳过错误: Imlib not with X11)
      #   96:  #message( FATAL_ERROR "Imlib is not built with X support" )
      test -s ../CMakeLists.txt-bk0 || cat ../CMakeLists.txt > ../CMakeLists.txt-bk0
      sed -i 's/^  message( FATAL_ERROR "Imlib is not/  #message( FATAL_ERROR "Imlib is not/g' ../CMakeLists.txt
      

      ###CMAKE alter###################
      # https://www.codenong.com/40618443/ #关于linux：使用CMAKE编译静态可执行文件
      # SET(CMAKE_FIND_LIBRARY_SUFFIXES".a")
      # SET(BUILD_SHARED_LIBRARIES OFF)
      # SET(CMAKE_EXE_LINKER_FLAGS "-static")
      # # 
      # 将其添加到find命令上方的CMakeLists.txt中：
      # set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
      # 
      # [view CMakeLists.txt]
      # set(CMAKE_C_COMPILER "/usr/bin/xx-clang")
      # set(CMAKE_CXX_COMPILER "/usr/bin/xx-clang++")
      # set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
      # # 
      # set_target_properties( tint2 PROPERTIES LINK_FLAGS "-static -pthread -fno-strict-aliasing ${ASAN_L_FLAGS} ${BACKTRACE_L_FLAGS}  ${TRACING_L_FLAGS}" )
      # set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
      # set(BUILD_SHARED_LIBRARIES OFF)
      # desc sort;
      sed -i '2a SET(CMAKE_EXE_LINKER_FLAGS "-static")' ../CMakeLists.txt
      sed -i '2a set(BUILD_SHARED_LIBRARIES OFF)' ../CMakeLists.txt
      sed -i '2a set(CMAKE_FIND_LIBRARY_SUFFIXES .a)' ../CMakeLists.txt
      # Configure will be re-run and you may have to reset some variables. ##re-run loop..
        # 注释如下两行，免cmake ..一直loop检查;  （手动编译: 不影响编译生成static的tint2）
        # sed -i '2a set(CMAKE_CXX_COMPILER "/usr/bin/xx-clang++")' ../CMakeLists.txt
        # sed -i '2a set(CMAKE_C_COMPILER "/usr/bin/xx-clang")' ../CMakeLists.txt
      # 
      # set_target_properties( tint2 PROPERTIES LINK_FLAGS "-static -pthread -fno-strict-aliasing ${ASAN_L_FLAGS} ${BACKTRACE_L_FLAGS}  ${TRACING_L_FLAGS}" )
      # LINK_FLAGS \"-pthread
      sed -i "s/LINK_FLAGS \"-pthread/LINK_FLAGS \"-static -pthread/g" ../CMakeLists.txt

      # bash-5.1# cat ../CMakeLists.txt |grep rdynamic -n
      # 清理如上6个 -rdynamic: 还是依旧(attempted static link of dynamic object);
      sed -i "s/-rdynamic//g" ../CMakeLists.txt

      # 改CMakeLists.txt (share> static)
      deps="Xinerama Xfixes Xrandr gdk-x11-2.0 gtk-x11-2.0 atk-1.0 gdk_pixbuf-2.0 pangocairo-1.0 pangoft2-1.0 pango-1.0 fontconfig X11 xcb Xdmcp Xau Xext Xft freetype png Xrender expat xml2 z bz2 lzma brotlidec brotlicommon intl fribidi harfbuzz gio-2.0 gobject-2.0 glib-2.0 pcre graphite2 ffi gmodule-2.0 gobject-2.0 gpg-error graphite2 pixman-1 jpeg uuid mount pcre blkid Xcomposite fontconfig gio-2.0 cairo Xdamage X11-xcb xcb-shm xcb-render xcb-util md croco-0.6 Imlib2 Xcursor Xi"
      # bash-5.1# cat ../CMakeLists.txt |grep Xi -n
      # 270:target_link_libraries( tint2 ${X11_LIBRARIES}
      sed -i "s/tint2 \${X11_LIBRARIES}.*/tint2 \${X11_LIBRARIES} $deps/g" ../CMakeLists.txt

      # tint2conf
      # target_link_libraries( tint2conf ${X11_T2C_LIBRARIES}
      sed -i "s/tint2conf \${X11_T2C_LIBRARIES}.*/tint2conf \${X11_T2C_LIBRARIES} $deps/g" ../src/tint2conf/CMakeLists.txt
    # cmake
    # cmake -h |grep pref
    cmake .. --install-prefix=$TARGETPATH

    # make
      # b1d491eb5ac5:/tmp/tint2/build# cat Makefile  |wc
      #   1450      4108     48291
      # 重名方法改名 strnappend02;
      sed -i "s/strnappend/strnappend02/g" ../src/battery/battery.c 
      cat ../src/battery/battery.c |grep strnappend
      
      log "Compiling TINT2..."
      # 清动态库
      # make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
#       ############### 改用ldd手动检查>> 改xx-ex
#       # ldd tint2 |sort  |grep -v ld-linux |awk '{print $1}' |sed "s/\.so.*/\.so/g" |tr "\n" "|"
#       match1="libX11-xcb.so|libX11.so|libXau.so|libXdmcp.so|libXext.so|libXrender.so|libbsd.so|libcroco-0.6.so|libfr
# eetype.so|libglib-2.0.so|libintl.so|libmd.so|libpcre.so|libpixman-1.so|libpng16.so|libxcb-shm.so|libxcb.so|libz.so"
#       # find /usr/lib /usr/local/lib -type f |egrep "$match1"
#       find /usr/lib /usr/local/lib -type f |egrep "$match1" |while read one; do echo $one; mv $one ${one}-ex; done
#       # ex-revert: libbrotlicommon.so|libbrotlidec.so|liblzma.so|libbz2.so|libxml2.so
#       find /usr/lib /usr/local/lib -type f |egrep "\-ex$" |egrep "libbrotlicommon.so|libbrotlidec.so|liblzma.so|libbz2.so|libxml2.so" |while read one; do echo $one; dst=$(echo $one |sed "s/\-ex//g"); mv $one $dst; done

      # make
      make
      # find /usr/lib /usr/local/lib -type f |egrep "\-ex$"

      log "Install TINT2..."
      make install; # >> TODO prefix
      # 改回
      find /usr/lib /usr/local/lib |grep "so-ex$" |while read one; do echo $one; n2=$(echo $one |sed "s/so-ex/so/g"); \cp -a $one $n2; done
      


  # view
  ls -lh /tmp/tint2/
  xx-verify --static /tmp/tint2/build/tint2
  xx-verify --static /tmp/tint2/build/src/tint2conf/tint2conf
}


case "$1" in
cache)
    down_catfile ${LIBCROCO_URL} > /dev/null
    ;;
full)
    # imlib2
    tint2
    ;;
b_deps)
    # bash /src/xcompmgr/build.sh Xdamage
    apk add xorg-server-dev;
    bash /src/v-xlunch/build.sh imlib2
    # 
    bash /src/v-tint2/build.sh libcroco # libcroco >deps: imlib2
    bash /src/v-tint2/build.sh librsvg & #librsvg> libcroco >deps: imlib2
    bash /src/v-tint2/build.sh xcbutil &
    bash /src/v-tint2/build.sh libxi &
    wait 

    # view x8; +libgdk
    # lost: Xrandr, atk, gtk
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk" |grep "\.a$" |sort 
    find /usr/local/lib |egrep "librsvg|libXi|libcroco" |grep "\.a$" |sort
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0


# dbg
rm -rf /src; ln -s /mnt2/docker-x11base/compile/src /src
export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu  ##DBG
bash /src/v-tint2/build.sh b_deps
