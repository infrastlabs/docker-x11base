#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-xlunch}"

# 脚本目录（绝对路径；imlib2() 内会 cd，须在函数外先算好）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# v1.12.7 @ 2026-08-28（12.x 最新；2026-11-23 升级）
IMLIB2_VER=1.12.7
IMLIB2_URL=https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/${IMLIB2_VER}/imlib2-${IMLIB2_VER}.tar.gz
# v1.12.2 tar -Jxf xx.tar.xz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz #xz,gz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2_loaders-1.12.2.tar.xz
# v1.7.4
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz #gz,bz2
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz

# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-xlunch #git clone;
XLUNCH_VER=v5.10.6
XLUNCH_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# 2026-11-25 方案二交叉: w-xlunch 栈共用交叉环境(imlib2 + xlunch 同链)。
# 设 CROSS_HOST/XX_DESTDIR/XX_LIBS_PREFIX + x 头库 sysroot 前缀 供 imlib2/xlunch 函数:
#   configure 追加 --host、make install 加 DESTDIR(装 sysroot)、手工 xx-clang 静态链的 -L 前缀 sysroot。
# native(未设 TARGETPLATFORM/XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
xl_cross(){
  CROSS_HOST=""; XX_DESTDIR=""; XX_LIBS_PREFIX=""
  XINC=/usr/include/X11; XLIB=/usr/lib/; IMLIB2_STATIC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    # imlib2 configure --x-includes/--x-libraries 是 native 绝对路径, 交叉下 xx-clang 会误读 build 机头/库
    #   → 前缀 sysroot; 纯静态目标 --disable-shared 防交叉下 -static 链共享 tool 失败。
    XINC="$XX_SYSROOT/usr/include/X11"; XLIB="$XX_SYSROOT/usr/lib/"
    IMLIB2_STATIC="--enable-static --disable-shared"
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    XX_LIBS_PREFIX="$XX_SYSROOT"
    log "xlunch: CROSS ($XX_TRIPLE)"
  fi
}

# 2026-11-25 交叉: imlib2 1.12.7 tarball 自带旧 config.sub 不识 aarch64/armv7-alpine-linux-musl
#   (configure: host system type Invalid configuration) → 用 automake 新版替换。
# 仅 is-cross 生效; native 零影响。须在 clone 后、configure 前于源码树根调用。
xx_config_sub_fix(){
  [ -n "$XX_CROSS_FILE" ] || return 0
  for f in config.sub config.guess; do
    cp /usr/share/automake-1.16/$f "$f" 2>/dev/null || cp /usr/share/autoconf/build-aux/$f "$f" 2>/dev/null || true
  done
}

function imlib2(){
  set -e   # doExec 调入口子 shell 会 set +e, 重启用保函数内失败即终止(否则吞错)
  xl_cross
  apk add xorg-server-dev

  # 
  # 2026-11-25: 交叉下清 $SRCROOT/imlib2——旧树(他 arch 的 .o)被 make 复用会产出 mixed-arch libImlib2.a
  #   (arm64 实测 33/46 armv7 成员→feh/xlunch link "file in wrong format"; CI 容器 /tmp 全新无此患,
  #   本地同容器换架构重建会踩; 交叉限定不改 native)。tarball 走 down_catfile 缓存, 重下不费网络。
  [ -n "$XX_CROSS_FILE" ] && rm -rf $SRCROOT/imlib2
  mkdir -p $SRCROOT/imlib2
  log "Downloading imlib2..."
  # curl -s -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C $SRCROOT/imlib2
  down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C $SRCROOT/imlib2
  cd $SRCROOT/imlib2
    # export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #去-static: 无a库生成
    export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
    # ./configure;
    xx_config_sub_fix   # 旧 config.sub 不识 aarch64/armv7-alpine-linux-musl(仅 is-cross)
    ./configure --with-x \
      --x-includes=$XINC --x-libraries=$XLIB \
      --without-heif --without-jxl $IMLIB2_STATIC $CROSS_HOST ; 
    # make; make install;

  log "Compiling imlib2..."
  make

  log "Installing imlib2..."
  make install $XX_DESTDIR
  xx_la_fix   # 交叉下 .la libdir 修正为 sysroot 相对(仅 is-cross; native 零影响)

  # 静态内置 loader：musl/静态下 dlopen 的外部 loader 全部失效
  # （含 PNG），故内嵌 png + svg 两个 loader 进 libImlib2.a
  log "Building builtin loaders (png+svg)..."
  cp -f "$SCRIPT_DIR/loader_svg.c" \
     $SRCROOT/imlib2/src/modules/loaders/loader_svg.c
  python3 - <<'PYEOF'
p = "$SRCROOT/imlib2/src/lib/loaders.c"
s = open(p).read()
if "png_loader" in s:
    print("loaders.c already patched")
else:
    # 1.12.7 锚点：__imlib_LoadAllLoaders 内 __imlib_ModulesList 之后、early return 之前
    anchor = "    list = __imlib_ModulesList(__imlib_PathToLoaders(), &num);\n"
    assert s.count(anchor) == 1, "anchor not unique"
    block = anchor + '''  /* builtin static loaders (no dlopen; for static/musl builds) */
  {
      ImlibLoader        *bl, *bl2, *bl3;
      extern ImlibLoaderModule png_loader, svg_loader, jpeg_loader;

      bl = malloc(sizeof(ImlibLoader));
      bl->file = strdup("png");
      bl->handle = NULL;
      bl->module = &png_loader;
      bl->next = NULL;
      bl->name = png_loader.formats[0];

      bl2 = malloc(sizeof(ImlibLoader));
      bl2->file = strdup("svg");
      bl2->handle = NULL;
      bl2->module = &svg_loader;
      bl2->next = NULL;
      bl2->name = svg_loader.formats[0];

      bl3 = malloc(sizeof(ImlibLoader));
      bl3->file = strdup("jpeg");
      bl3->handle = NULL;
      bl3->module = &jpeg_loader;
      bl3->next = NULL;
      bl3->name = jpeg_loader.formats[0];

      if (png_loader.inex) png_loader.inex(1);
      if (svg_loader.inex) svg_loader.inex(1);
      if (jpeg_loader.inex) jpeg_loader.inex(1);

      bl2->next = bl3;
      bl->next = bl2;
      loaders = bl;
  }
'''
    s = s.replace(anchor, block)
    open(p, "w").write(s)
    print("loaders.c patched")
PYEOF
  INC="-I$SRCROOT/imlib2 -I$SRCROOT/imlib2/src/lib -I$SRCROOT/imlib2/src/modules/loaders"
  RSVG_CFLAGS=$(pkg-config --cflags librsvg-2.0)
  mkdir -p $SRCROOT/builtin
  # 1.12.7: loader 源尾部导出全局符号 `loader`(ImlibLoaderModule)，三 loader 同链会符号冲突；
  #   -Dloader=xxx 重命名导出符号（等价 1.7.4 的 -Dload2=png_load2 手法）。
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -Dloader=png_loader \
    -c $SRCROOT/imlib2/src/modules/loaders/loader_png.c -o $SRCROOT/builtin/png.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC $RSVG_CFLAGS \
    -Dloader=svg_loader \
    -c $SRCROOT/imlib2/src/modules/loaders/loader_svg.c -o $SRCROOT/builtin/svg.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -Dloader=jpeg_loader \
    -c $SRCROOT/imlib2/src/modules/loaders/loader_jpeg.c -o $SRCROOT/builtin/jpeg.o
  # 1.12.7 新增：loader 模块辅助源（非主库）——ldrs_util.c 定义 get_saver_params
  #   （loader_png/jpeg save 引用）、exif.c 定义 exif_parse（loader_jpeg 引用）。
  #   不编入则 builtin loader 链出 undefined reference（2026-11-23 实测）。
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -c $SRCROOT/imlib2/src/modules/loaders/ldrs_util.c -o $SRCROOT/builtin/ldrs_util.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -c $SRCROOT/imlib2/src/modules/loaders/exif.c -o $SRCROOT/builtin/exif.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -c $SRCROOT/imlib2/src/lib/loaders.c -o $SRCROOT/builtin/loaders.o
  # 不再 ar r 直改系统 /usr/local/lib/libImlib2.a（魔改系统库，隐式影响其他 imlib2 链接者）；
  # 拷贝到私有归档再注入 loader，xlunch 链接 -L$SRCROOT/builtin -lImlib2 优先取用（2026-11-08 整改）。
  cp ${XX_SYSROOT:-}/usr/local/lib/libImlib2.a $SRCROOT/builtin/libImlib2.a
  ar r $SRCROOT/builtin/libImlib2.a \
    $SRCROOT/builtin/loaders.o $SRCROOT/builtin/png.o $SRCROOT/builtin/svg.o $SRCROOT/builtin/jpeg.o \
    $SRCROOT/builtin/ldrs_util.o $SRCROOT/builtin/exif.o
  ranlib $SRCROOT/builtin/libImlib2.a
  # 2026-11-15: 注入版再覆盖 /usr/local/lib——base 烘焙后 5 个 w-xxx 裸 -lImlib2 即取注入库
  #   （本容器内 imlib2 链接者仅 w-xxx，无"其他链接者"；与二章 1.5-2"覆盖系统库"方案一致，
  #   免去逐 app 改 -L$SRCROOT/builtin 与 -L 顺序坑）。
  cp -f $SRCROOT/builtin/libImlib2.a ${XX_SYSROOT:-}/usr/local/lib/libImlib2.a
}

#
# Build xlunch
# export TARGETPATH=/usr/local/static/xlunch
function xlunch(){
  set -e   # doExec 调入口子 shell 会 set +e, 重启用保函数内失败即终止(否则吞错)
  xl_cross
  apk add hicolor-icon-theme #need hicolor
  # ref: xcompmgr
  apk add cairo-static expat-static fribidi-static glib-static graphite2-static harfbuzz-static
  apk add libxml2-dev ##>> -lxml2 -llzma 

  log "Downloading XLUNCH..."
  rm -rf $SRCROOT/xlunch; # mkdir -p $SRCROOT/xlunch
  # down_catfile ${XLUNCH_URL} | tar -zx --strip 1 -C $SRCROOT/xlunch
  # branch="--branch=$XLUNCH_VER"
  # repo=https://hub.nuaa.cf/Tomas-M/xlunch
  gitclone https://gitee.com/g-system/fk-xlunch $SRCROOT/xlunch --branch=$XLUNCH_VER #;
  log "Configuring XLUNCH..."
  cd $SRCROOT/xlunch #&& ./bootstrap;
    # ./configure  --enable-static --prefix=$TARGETPATH ##无./configure|autoconf
    test -s ./Makefile-bk1 || cat Makefile > Makefile-bk1
    cat Makefile-bk1 |sed "s^DESTDIR)/usr^DESTDIR)$TARGETPATH^g" > Makefile
    sed -i "s^bash extra/genentries^#bash extra/genentries^g" Makefile

    # make
    # OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
    # make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
    
    # drop1: -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi
    # drop2: -lXft -lXrender -llzma 
    # 内置 svg loader 需 librsvg/cairo/glib/pango；--start-group 解循环引用；
    # 过滤缺库的 -lzstd -ltiff（gdk-pixbuf 非必需 io）
    RSVG_LIBS=$(pkg-config --static --libs librsvg-2.0 cairo pangocairo | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext  -lfreetype -lpng   -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
    # 2026-11-25: xlunch Makefile 硬编码 CC = gcc（make 中 Makefile 变量赋值优先于环境变量，
    #   xl_cross 里 export CC=xx-clang 覆盖不到）→ 交叉须命令行覆盖（优先级最高）。
    #   native 不加（Makefile CC=gcc 原路径零影响）。
    MAKE_CC=""; [ -n "$XX_CROSS_FILE" ] && MAKE_CC="CC=xx-clang"
    make $MAKE_CC LDFLAGS="-static --static -Wl,--strip-all -Wl,--start-group -L$SRCROOT/builtin -lImlib2 -L${XX_LIBS_PREFIX:-}/usr/local/lib $RSVG_LIBS -lxml2 -lcroco-0.6 $OB_LIBS -lX11-xcb -lxcb-shm -Wl,--end-group" xlunch #default>> all: xlunch entries.dsv

  log "Install XLUNCH..."
  # make;
  make install; #不用install? need

  # view
  ls -lh $SRCROOT/xlunch/
  xx-verify --static $SRCROOT/xlunch/xlunch
}


function b_deps(){
  # 新引入依赖（imlib2 内置 svg loader 链）：librsvg/cairo/pango/xz
  # apk 包（cairo/pango/xz 的 .a 由 apk 提供）；但 librsvg-2.a 无 apk
  # 静态子包，必须本地编译（w-tint2 librsvg，STATIC=yes 只出 .a，
  # librsvg 前置依赖 libcroco）。已存在则跳过编译。
  apk update
  apk add librsvg-dev cairo-dev pango-dev xz-dev
  test -s /usr/local/lib/librsvg-2.a || {
    doExec env STATIC=yes bash /src/w-tint2/build.sh libcroco || exit 1
    doExec env STATIC=yes bash /src/w-tint2/build.sh librsvg || exit 1
  }
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    doExec imlib2 || exit 1
    doExec xlunch || exit 1
    ;;
b_deps)
    doExec b_deps || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
