#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-tint2}"

# libcroco/librsvg 装 /usr/local，.pc 在 /usr/local/lib/pkgconfig；Alpine pkgconf 默认不含 → 前置，供本脚本 configure 找到新装 .pc。
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# 
# LIBCROCO_URL=https://mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz

# libcroco
# https://github.com/OpenMandrivaAssociation/libcroco0.6/blob/master/libcroco0.6.spec #ref url @gnome
# https://mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz
function libcroco(){
  # openbox 等纯静态消费方传 STATIC=yes：--disable-shared 只出 .a
  # （默认连 .so 一起装，pc 里 -lcroco-0.6 会优先链 .so，静态二进制直接带动态依赖）
  test "yes" = "$STATIC" || export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
  test "yes" = "$STATIC" && export DISABLE_SHARED=--disable-shared
  # STATIC 下 libxml2.a 的传递依赖(zlib/lzma/bzip2/m)不自动链接, 导致 csslint-0.6 工具链接失败
  # (undefined reference to deflateEnd/gzopen/lzma_code...) → make install 失败 → libcroco-0.6.pc 未装。
  test "yes" = "$STATIC" && export LIBS="${LIBS:-} -lz -llzma -lbz2 -lm"

  # 2026-11-24 方案二交叉: xx_cross_init 检测到 is-cross($XX_CROSS_FILE 非空)时设 autotools 交叉环境
  #   （强制宿主 pkg-config——xx 交叉 pkg-config 忽略 PKG_CONFIG_LIBDIR; --host 交叉; 装 sysroot; 纯静态强制）。
  LIBDIR=/usr/local/lib; CROSS_HOST=""
  if [ -n "$XX_CROSS_FILE" ]; then
    export STATIC=yes   # 交叉目标=纯静态(要.a)，消费方传 yes 时同值无害
    LIBDIR=$XX_SYSROOT/usr/local/lib
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    export DISABLE_SHARED=--disable-shared
    [ -z "$LIBS" ] && export LIBS="-lz -llzma -lbz2 -lm"
    log "libcroco: CROSS ($XX_TRIPLE)"
  fi

  mkdir -p $SRCROOT/libcroco
  log "Downloading libcroco..."
  # rm -rf $SRCROOT/libcroco; git clone --depth=1 $branch $repo $SRCROOT/libcroco
  # cd $SRCROOT/libcroco
  # down_catfile ${LIBCROCO_URL} | tar -Jx --strip 1 -C $SRCROOT/libcroco
  branch="--branch=0.6.13"
  rm -rf $SRCROOT/libcroco; gitclone https://gitee.com/g-system/fk-libcroco $SRCROOT/libcroco $branch
  cd $SRCROOT/libcroco
  # cd libcroco-0.6.13
  # NOCONFIGURE=1: GNOME autogen.sh 无参自动跑 configure（交叉下不带 --host 报 cannot run C compiled programs）
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 ./autogen.sh
  else
    ./autogen.sh
  fi
  ./configure --enable-static $DISABLE_SHARED $CROSS_HOST

  log "Compiling libcroco..."
  make
  log "Installing libcroco..."
  if [ -n "$XX_CROSS_FILE" ]; then
    make install DESTDIR=$XX_SYSROOT
  else
    make install
  fi
  # STATIC 模式清掉 .so（保留 .la 供 libtool 展开 dependency_libs）
  test "yes" = "$STATIC" && rm -f $LIBDIR/libcroco-0.6.so*
  # 2026-11-15: .la 修元数据——清 .so 记录(library_names/dlname)，libtool 链接走 old_library=.a
  #   （libtool 非-static 链接优先 shared，.la 记录 .so 时展开用 .so → 静态环境顺序错；同 librsvg）。
  sed -i "s|^library_names=.*|library_names=''|; s|^dlname=.*|dlname=''|" $LIBDIR/libcroco-0.6.la 2>/dev/null || true
  # find |grep croco; cp ./src/.libs/libcroco-0.6.a /usr/lib/
  find $LIBDIR |grep libcroco |grep "\.a$"
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
# https://gitlab.gnome.org/Archive/libcroco
# 
function librsvg(){
  # attempted static link of dynamic object `/usr/local/lib/libcroco-0.6.so'
  # openbox 等纯静态消费方传 STATIC=yes：--disable-shared 只出 .a
  # （默认连 .so 一起装，pc 里 -lrsvg-2 会优先链 .so，openbox 静态链接直接报 attempted static link）
  test "yes" = "$STATIC" || export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
  test "yes" = "$STATIC" && export DISABLE_SHARED=--disable-shared
  # STATIC 下链接 libcroco-0.6.a→libxml2.a 的传递依赖(zlib/lzma/bzip2/m)不自动链接, 需显式加。
  test "yes" = "$STATIC" && export LIBS="${LIBS:-} -lz -llzma -lbz2 -lm"

  # 2026-11-24 方案二交叉: xx_cross_init 检测到 is-cross($XX_CROSS_FILE 非空)时设 autotools 交叉环境
  #   （强制宿主 pkg-config——xx 交叉 pkg-config 忽略 PKG_CONFIG_LIBDIR; --host 交叉; 装 sysroot; 纯静态强制）。
  LIBDIR=/usr/local/lib; CROSS_HOST=""
  if [ -n "$XX_CROSS_FILE" ]; then
    export STATIC=yes   # 交叉目标=纯静态(要.a)，消费方传 yes 时同值无害
    LIBDIR=$XX_SYSROOT/usr/local/lib
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    export DISABLE_SHARED=--disable-shared
    [ -z "$LIBS" ] && export LIBS="-lz -llzma -lbz2 -lm"
    log "librsvg: CROSS ($XX_TRIPLE)"
  fi

  log "Downloading librsvg..."
  # git clone $GITHUB/GNOME/librsvg
  # git checkout 2.40.21 #2.50.7
  branch="--branch=2.40.21"
  rm -rf $SRCROOT/librsvg; gitclone https://gitee.com/g-system/fk-librsvg $SRCROOT/librsvg $branch
  cd $SRCROOT/librsvg
  # NOCONFIGURE=1: GNOME autogen.sh 无参自动跑 configure（交叉下不带 --host 报 cannot run C compiled programs）
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 ./autogen.sh
  else
    ./autogen.sh
  fi
  # STATIC 下 librsvg-2.a 的消费方(rsvg-convert/rsvg-loader/GISCAN 等可执行)均被 -static 强制静态链接,
  #   需 libgdk_pixbuf-2.0.a(Alpine 无 gdk-pixbuf-static 包)会失败; 故仅构建/安装 librsvg-2.a 库本体:
  #   --enable-introspection=no 跳过 GISCAN; 清空顶层 bin_PROGRAMS(rsvg-convert 等), 剔除 SUBDIRS 中 gdk-pixbuf-loader/tests/tools/doc。
  test "yes" = "$STATIC" && export CONFIGURE_INTRO=--enable-introspection=no
  ./configure --enable-static $DISABLE_SHARED $CONFIGURE_INTRO $CROSS_HOST
  test "yes" = "$STATIC" && sed -i 's/^bin_PROGRAMS = rsvg-convert.*/bin_PROGRAMS =/' Makefile
  test "yes" = "$STATIC" && sed -i 's/^SUBDIRS = \. gdk-pixbuf-loader tests tools doc build/SUBDIRS = . build/' Makefile
  log "Compiling librsvg..."
  # 2026-11-15: librsvg 2.40 用 libjpeg(embedded jpeg)但 configure 的 JPEG 依赖未进 .so/rsvg-convert 链接
  #   → CI tint2 b_deps 实测 `librsvg-2.so: undefined reference to jpeg_*`(rsvg-convert 同错)。
  #   make LIBS 补 -ljpeg(追加, 不覆盖 STATIC 路径的 -lz -llzma -lbz2 -lm)。
  make LIBS="${LIBS:-} -ljpeg"
  log "Installing librsvg..."
  if [ -n "$XX_CROSS_FILE" ]; then
    make install LIBS="${LIBS:-} -ljpeg" DESTDIR=$XX_SYSROOT
  else
    make install LIBS="${LIBS:-} -ljpeg"
  fi
  # STATIC 模式清掉 .so（保留 .la 供 libtool 展开 dependency_libs：pangocairo/cairo/gio…）
  test "yes" = "$STATIC" && rm -f $LIBDIR/librsvg-2.so*
  # 2026-11-15: .la 修元数据（libtool 消费方兼容，本次 u-gtkmm generate_extra_defs 踩）——
  #   ① 清 .so 记录(library_names/dlname)→libtool 走 old_library=.a（libtool 非-static 链接优先 shared，
  #      .la 记录 .so 时即便文件已删也按名引用→顺序错/文件缺失）；
  #   ② dependency_libs 去 -lgdk_pixbuf-2.0——librsvg 2.40 不依赖 gdk_pixbuf，该声明 + u-gtk ar 魔改
  #      (io-svg 塞进 libgdk_pixbuf-2.0.a 使 gdk_pixbuf 反向依赖 rsvg) 造成 rsvg↔gdk_pixbuf 循环依赖，
  #      libtool 无法排序→rsvg 排 gdk_pixbuf 前→rsvg_handle_* undefined。去除后单向排序。
  #      直链消费方(xx-clang -static)不读 .la，不受影响（详见 docs/2026/11091127-ci-builder-gtk.md 三章5.2）。
  sed -i "s|^library_names=.*|library_names=''|; s|^dlname=.*|dlname=''|; s|-lgdk_pixbuf-2.0||" $LIBDIR/librsvg-2.la 2>/dev/null || true
  # 2026-11-13: librsvg-2.0.pc Requires 缺 pangocairo/libxml-2.0/libcroco-0.6(实测 Only glib/gio/gdk-pixbuf/cairo, Requires.private 空)
  # → meson dependency('librsvg-2.0') 链接 librsvg-2.a 时 undefined xml*/pango_cairo_*/cr_*(librsvg 依赖链: libxml2+pangocairo+libcroco)
  # → gdk_pixbuf svg loader 编进 .a 时链接失败→SVG图标故障; 补全 Requires 供所有消费方(openbox/gdk_pixbuf/lxtask)解析带全依赖
  sed -i 's/^Requires: .*/Requires: glib-2.0 gio-2.0 gdk-pixbuf-2.0 cairo pangocairo libxml-2.0 libcroco-0.6/' $LIBDIR/pkgconfig/librsvg-2.0.pc 2>/dev/null || true
  grep -E "^Requires" $LIBDIR/pkgconfig/librsvg-2.0.pc 2>/dev/null
  # find |grep librsvg-
  # ./.libs/librsvg-2.a
  find $LIBDIR |grep librsvg |grep "\.a$"
}

# [xcb-util]
function xcbutil(){
  # 2026-11-25 方案二交叉: autotools 交叉环境(同 libcroco)——--host 交叉、强制宿主 pkg-config、装 sysroot。
  CROSS_HOST=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    log "xcbutil: CROSS ($XX_TRIPLE)"
  fi
  log "Downloading xcb_util..."
  rm -rf $SRCROOT/xcb-util; gitclone https://gitee.com/g-system/fk-xcb__util $SRCROOT/xcb-util $branch
  cd $SRCROOT/xcb-util
  # git clone $GITHUB/freedesktop-unofficial-mirror/xcb__util
  # cd xcb__util/
  apk add util-macros libtool automake autoconf #ubt: xorg-macros
  # 2026-11-13: m4 子模块改用 gitclone 预热(享受缓存链 GITCACHE>tar.gz>网络), 不再依赖 submodule update(git:// 常被禁/抖动)
  # gitee g-system/util-common-m4 镜像与宿主缓存 tarsrc-git/util-common-m4 同名(_repo=util-common-m4) → GITCACHE 命中;
  # CI 无 tarsrc-git 时回落 tar.gz 快照/网络 gitee 克隆, 不再 sed .gitmodules 指向不存在路径(cp can't stat 教训, 3.3.4/5.1)
  # autogen.sh 检查 `git submodule status|grep ^-`(父仓库 gitlink 与 gitclone 的 m4 独立克隆 HEAD 不一致→报 uninitialized→exit 1)
  # → 移除父仓库对 m4 的 submodule 跟踪(.gitmodules 删段; git rm --cached/.git/config 兜底), autogen 检查即过(实测生成 Makefile)
  rm -rf m4; gitclone https://gitee.com/g-system/util-common-m4 m4
  sed -i '/\[submodule "m4"\]/,/^$/d' .gitmodules 2>/dev/null || true
  git rm --cached m4 >/dev/null 2>&1 || true
  git config --remove-section submodule.m4 2>/dev/null || true
  test -f m4/xcb_util_common.m4 || { echo "!! m4 gitclone 未就位(autogen 将失败)"; }
  # 交叉下 autogen 自动 configure(不带 --host) 报 cannot run C compiled programs → NOCONFIGURE=1 + 显式 configure。
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 ./autogen.sh
    ./configure --enable-static --disable-shared $CROSS_HOST
  else
    ./autogen.sh
  fi
  #  
  # cd /mnt2/_deps/xcb__util/
  log "Compiling xcb_util..."
  make
  log "Installing xcb_util..."
  if [ -n "$XX_CROSS_FILE" ]; then
    make install DESTDIR=$XX_SYSROOT
    xx_la_fix   # 交叉 .la libdir 修正(仅 is-cross; native 零影响)
  else
    make install
  fi
  find |grep libxcb-util
  # ./src/.libs/libxcb-util.a
  # ./src/.libs/libxcb-util.so
  # 2026-11-28: 交叉下 .a 装 sysroot 非宿主 /usr——find 交叉感知($XX_SYSROOT), 否则空返 rc=1 假失败。native 零影响。
  find ${XX_SYSROOT:-}/usr/lib/ ${XX_SYSROOT:-}/usr/local/lib |grep libxcb-util |grep "\.a$"
}


# https://github.com/aleax/libxi
function libxi(){
  # 2026-11-25 方案二交叉: autotools 交叉环境(同 libcroco)——--host 交叉、强制宿主 pkg-config、装 sysroot。
  CROSS_HOST=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 2026-11-25: libxi 旧 configure 的 run-test 在交叉下报 cannot run C compiled programs /
    #   cannot run test program while cross compiling(ARM 测试二进制不能跑 x86)。
    #   缓存变量让 configure 跳过 run-test(同 xl_cross), 否则 configure 中止无 Makefile。
    #   注: libxi 的 malloc 检查用 X.Org 的 xorg_cv_malloc0_returns_null(非 AC_FUNC_MALLOC 的
    #   ac_cv_func_malloc_0_nonnull); musl malloc(0) 返回非 NULL → 设 no(-DMALLOC_0_RETURNS_NULL 无)。
    export ac_cv_prog_cc_cross=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export xorg_cv_malloc0_returns_null=no
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    log "libxi: CROSS ($XX_TRIPLE)"
  fi
  # git clone $GITHUB/aleax/libxi
  log "Downloading libxi..."
  rm -rf $SRCROOT/libxi; gitclone https://gitee.com/g-system/fk-libxi $SRCROOT/libxi $branch
  cd $SRCROOT/libxi
  # 交叉下 autogen 自动 configure(不带 --host) 报 cannot run C compiled programs → NOCONFIGURE=1 + 显式 configure。
  if [ -n "$XX_CROSS_FILE" ]; then
    NOCONFIGURE=1 ./autogen.sh
  else
    ./autogen.sh
  fi
  ./configure  --enable-static --disable-shared $CROSS_HOST #disable dyn;
  log "Compiling libxi..."
  make
  log "Installing libxi..."
  if [ -n "$XX_CROSS_FILE" ]; then
    make install DESTDIR=$XX_SYSROOT
    xx_la_fix   # 交叉 .la libdir 修正(仅 is-cross; native 零影响)
  else
    make install
  fi
  find ${XX_SYSROOT:-}/usr/lib ${XX_SYSROOT:-}/usr/local/lib |grep libXi.a
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
# bash /src/w-xlunch/build.sh imlib2
# # find-vscode: X_DISPLAY_MISSING @./Projects/_ee/_deps/imlib2-1.7.4
# xserver-xorg-dev @ubt
# apk add xorg-server-dev;

# 手动注释  #if( NOT IMLIB_BUILD_WITH_X )
  # # message( FATAL_ERROR "Imlib is not (跳过错误: Imlib not with X11)

###DEPS >> buidler-gtk224##############
# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# bash /src/w-tint2/build.sh b_deps #pango/xrand/xdamage>> atk/gdk >> gtk 
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
  set -e   # doExec 调入口子 shell 会 set +e, 重启用保函数内失败即终止(否则吞错)
  # 2026-11-25 交叉: tint2 用 cmake, 需 toolchain 文件(xx-clang + sysroot 根 + 只链 .a 静态)。
  #   toolchain 文件在下方 cmake 前按需生成; native(无 XX_CROSS_FILE) 不生成不传, 零影响。
  # xcomposite-dev gtk+2.0-dev
  # 公共库(pango/librsvg/libxcursor)已由 u-gtk 统一装(1.4.1)
  apk add startup-notification-dev
  # 
  # apk add imlib2-dev librsvg-dev gtk+2.0-dev  ##本地安装了，则会跳过install;


  log "Downloading TINT2..."
  rm -rf $SRCROOT/tint2; # mkdir -p $SRCROOT/tint2
  # down_catfile ${TINT2_URL} | tar -zx --strip 1 -C $SRCROOT/tint2
  branch="--branch=16.7"
  # repo=$GITHUB/o9000/tint2
  rm -rf $SRCROOT/tint2; gitclone https://gitee.com/g-system/fk-tint2 $SRCROOT/tint2 $branch #;
  log "Configuring TINT2..."
  cd $SRCROOT/tint2 #&& ./bootstrap;
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
      
      # # desc sort;
      # sed -i '2a SET(CMAKE_EXE_LINKER_FLAGS "-static")' ../CMakeLists.txt
      # sed -i '2a set(BUILD_SHARED_LIBRARIES OFF)' ../CMakeLists.txt
      # sed -i '2a set(CMAKE_FIND_LIBRARY_SUFFIXES .a)' ../CMakeLists.txt
      # # Configure will be re-run and you may have to reset some variables. ##re-run loop..
      #   # 注释如下两行，免cmake ..一直loop检查;  （手动编译: 不影响编译生成static的tint2）
      #   # sed -i '2a set(CMAKE_CXX_COMPILER "/usr/bin/xx-clang++")' ../CMakeLists.txt
      #   # sed -i '2a set(CMAKE_C_COMPILER "/usr/bin/xx-clang")' ../CMakeLists.txt
      # # 
      # # set_target_properties( tint2 PROPERTIES LINK_FLAGS "-static -pthread -fno-strict-aliasing ${ASAN_L_FLAGS} ${BACKTRACE_L_FLAGS}  ${TRACING_L_FLAGS}" )
      # # LINK_FLAGS \"-pthread
      # sed -i "s/LINK_FLAGS \"-pthread/LINK_FLAGS \"-static -pthread/g" ../CMakeLists.txt

      # # bash-5.1# cat ../CMakeLists.txt |grep rdynamic -n
      # # 清理如上6个 -rdynamic: 还是依旧(attempted static link of dynamic object);
      # sed -i "s/-rdynamic//g" ../CMakeLists.txt

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
    # 2026-11-25 交叉: 生成 toolchain 文件(xx-clang 编译器 + sysroot 根 + 只找 .a 静态库),
    #   强制 CMAKE_FIND_ROOT_PATH_MODE_* 只在 sysroot 找, 防误读 native 头/库。native 不生成。
    T2_TC=""
    if [ -n "$XX_CROSS_FILE" ]; then
      # 2026-11-25: cmake 的 pkg_check_modules 默认走 native pkg-config → 误读 x86-64 头/库
      #   (libstartup-notification 找不到 / Imlib2 链到 native .a 被 arm 链接器拒)。
      #   显式把 pkg-config 指到 sysroot(自建 /usr/local 优先), 否则依赖检查/链库全解析到 build 机。
      export PKG_CONFIG=/usr/bin/pkg-config
      export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
      export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
      unset PKG_CONFIG_PATH
      T2_TC=$SRCROOT/tint2/toolchain.cmake
      cat > $T2_TC <<EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ${XX_TRIPLE})
set(CMAKE_C_COMPILER /usr/bin/xx-clang)
set(CMAKE_CXX_COMPILER /usr/bin/xx-clang++)
set(CMAKE_FIND_ROOT_PATH ${XX_SYSROOT})
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
set(CMAKE_EXE_LINKER_FLAGS "-static")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
      T2_TC="-DCMAKE_TOOLCHAIN_FILE=$T2_TC"
      log "tint2: CROSS toolchain ($XX_TRIPLE)"
    fi
    cmake $T2_TC .. --install-prefix=$TARGETPATH

    # make
      # b1d491eb5ac5:$SRCROOT/tint2/build# cat Makefile  |wc
      #   1450      4108     48291
      # 重名方法改名 strnappend02;
      sed -i "s/strnappend/strnappend02/g" ../src/battery/battery.c 
      cat ../src/battery/battery.c |grep strnappend
      
      log "Compiling TINT2..."
      # 清动态库
      # 2026-11-16: 去 echo =$one——ldd.txt 黑名单改名(防动态链优先)静默执行; 原 echo 每行打印 =lib*.so 50 行调试残留, 日志脏
      # make 2>&1 |grep "\.so'$" |awk '{print $8}' |sed "s/\`//g" |sed "s/'//g" |while read one; do echo $one; mv $one ${one}-ex; done
      cat /src/w-tint2/ldd.txt |egrep -v "^#|^$" |while read one; do test -s $one && \cp -a $one ${one}-ex; test -s ${one}-ex && rm -f $one; done
      find /usr/lib /usr/local/lib |grep "so-ex$" |while read one; do n2=$(echo $one |sed "s/so-ex/so/g"); test -s $n2 && echo "still exist:$n2"; done #confirm
#       ############### 改用ldd手动检查>> 改xx-ex
#       # ldd tint2 |sort  |grep -v ld-linux |awk '{print $1}' |sed "s/\.so.*/\.so/g" |tr "\n" "|"
#       match1="libX11-xcb.so|libX11.so|libXau.so|libXdmcp.so|libXext.so|libXrender.so|libbsd.so|libcroco-0.6.so|libfr
# eetype.so|libglib-2.0.so|libintl.so|libmd.so|libpcre.so|libpixman-1.so|libpng16.so|libxcb-shm.so|libxcb.so|libz.so"
#       # find /usr/lib /usr/local/lib -type f |egrep "$match1"
#       find /usr/lib /usr/local/lib -type f |egrep "$match1" |while read one; do echo $one; mv $one ${one}-ex; done
#       # ex-revert: libbrotlicommon.so|libbrotlidec.so|liblzma.so|libbz2.so|libxml2.so
#       find /usr/lib /usr/local/lib -type f |egrep "\-ex$" |egrep "libbrotlicommon.so|libbrotlidec.so|liblzma.so|libbz2.so|libxml2.so" |while read one; do echo $one; dst=$(echo $one |sed "s/\-ex//g"); mv $one $dst; done

      # tint2-arm64-hk1box-staticOK:
      sed -i "s/\-rdynamic//g" CMakeFiles/tint2.dir/link.txt
      sed -i "s/dynamic/static/g" CMakeFiles/tint2.dir/link.txt

      # make
      make
      # find /usr/lib /usr/local/lib -type f |egrep "\-ex$"

      log "Install TINT2..."
      make install; # >> TODO prefix
      # 改回
      find /usr/lib /usr/local/lib |grep "so-ex$" |while read one; do echo $one; n2=$(echo $one |sed "s/so-ex/so/g"); \cp -a $one $n2; done
      


  # view
  ls -lh $SRCROOT/tint2/
  xx-verify --static $SRCROOT/tint2/build/tint2
  xx-verify --static $SRCROOT/tint2/build/src/tint2conf/tint2conf
}


case "$1" in
cache)
    # down_catfile ${LIBCROCO_URL} > /dev/null
    ;;
full)
    doExec tint2 || exit 1
    ;;
b_deps)
    # bash /src/xcompmgr/build.sh Xdamage
    # 公共库(xorg-server)已由 u-gtk 统一装(1.4.1)
    # doExec bash /src/w-xlunch/build.sh imlib2 || exit 1
    # doExec bash /src/w-tint2/build.sh libcroco || exit 1
    doExec_mark "w-tint2 b_deps grp"
    # doExec bash /src/w-tint2/build.sh librsvg & #librsvg> libcroco >deps: imlib2
    doExec bash /src/w-tint2/build.sh xcbutil &
    doExec bash /src/w-tint2/build.sh libxi &
    wait
    doExec_check || exit 1

    # view x8; +libgdk
    # lost: Xrandr, atk, gtk
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk" |grep "\.a$" |sort 
    find /usr/local/lib |egrep "librsvg|libXi|libcroco|xcb|imlib" |grep "\.a$" |sort
    ;;
*) #compile
    oneBuild $1
    ;;          
esac


# dbg
# rm -rf /src; ln -s /mnt2/docker-x11base/compile/src /src
# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu  ##DBG
# bash /src/w-tint2/build.sh b_deps
