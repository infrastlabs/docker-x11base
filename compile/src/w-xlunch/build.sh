#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-xlunch}"

# 脚本目录（绝对路径；imlib2() 内会 cd，须在函数外先算好）
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# v1.12.3 @ 	2024-02-03
# v1.7.4 @2021-09-17
IMLIB2_VER=1.7.4
IMLIB2_URL=https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/${IMLIB2_VER}/imlib2-${IMLIB2_VER}.tar.gz
# v1.12.2 tar -Jxf xx.tar.xz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz #xz,gz
# https://nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2_loaders-1.12.2.tar.xz
# v1.7.4
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz #gz,bz2
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz

# gh=https://ghps.cc/
# https://gitee.com/g-system/fk-suckless-xlunch #git clone;
XLUNCH_VER=0.8.4
XLUNCH_URL=${gh}https://github.com/neutrinolabs/xrdp/releases/download/v${XRDP_VER}/xrdp-${XRDP_VER}.tar.gz

# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz
# https://master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2_loaders-1.7.4.tar.gz
function imlib2(){
  set -e   # doExec 调入口子 shell 会 set +e, 重启用保函数内失败即终止(否则吞错)
  apk add xorg-server-dev

  # 
  mkdir -p /tmp/imlib2
  log "Downloading imlib2..."
  # curl -# -L -f ${IMLIB2_URL} | tar -xJ --strip 1 -C /tmp/imlib2
  down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/imlib2
  cd /tmp/imlib2
    # export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #去-static: 无a库生成
    export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
    # ./configure; 
    ./configure --with-x \
      --x-includes=/usr/include/X11 --x-libraries=/usr/lib/ ; 
    # make; make install;

  log "Compiling imlib2..."
  make

  log "Installing imlib2..."
  make install

  # 静态内置 loader：musl/静态下 dlopen 的外部 loader 全部失效
  # （含 PNG），故内嵌 png + svg 两个 loader 进 libImlib2.a
  log "Building builtin loaders (png+svg)..."
  cp -f "$SCRIPT_DIR/loader_svg.c" \
     /tmp/imlib2/src/modules/loaders/loader_svg.c
  python3 - <<'PYEOF'
p = "/tmp/imlib2/src/lib/loaders.c"
s = open(p).read()
if "jpeg_load2" in s:
    print("loaders.c already patched")
else:
    anchor = "   if (loaders)\n      return;\n"
    assert s.count(anchor) == 1, "anchor not unique"
    block = anchor + '''
  /* builtin static loaders (no dlopen; for static/musl builds) */
  {
      ImlibLoader        *bl, *bl2, *bl3;
      extern int          png_load2(ImlibImage * im, int load_data);
      extern char         png_save(ImlibImage * im, ImlibProgressFunction progress,
                                   char progress_granularity);
      extern void         png_formats(ImlibLoader * l);
      extern int          svg_load2(ImlibImage * im, int load_data);
      extern void         svg_formats(ImlibLoader * l);
      extern int          jpeg_load2(ImlibImage * im, int load_data);
      extern char         jpeg_save(ImlibImage * im, ImlibProgressFunction progress,
                                   char progress_granularity);
      extern void         jpeg_formats(ImlibLoader * l);

      bl = malloc(sizeof(ImlibLoader));
      bl->file = strdup("png");
      bl->num_formats = 0;
      bl->formats = NULL;
      bl->handle = NULL;
      bl->load = NULL;
      bl->save = png_save;
      bl->next = NULL;
      bl->load2 = png_load2;
      png_formats(bl);

      bl2 = malloc(sizeof(ImlibLoader));
      bl2->file = strdup("svg");
      bl2->num_formats = 0;
      bl2->formats = NULL;
      bl2->handle = NULL;
      bl2->load = NULL;
      bl2->save = NULL;
      bl2->next = NULL;
      bl2->load2 = svg_load2;
      svg_formats(bl2);

      bl3 = malloc(sizeof(ImlibLoader));
      bl3->file = strdup("jpeg");
      bl3->num_formats = 0;
      bl3->formats = NULL;
      bl3->handle = NULL;
      bl3->load = NULL;
      bl3->save = jpeg_save;
      bl3->next = NULL;
      bl3->load2 = jpeg_load2;
      jpeg_formats(bl3);

      bl2->next = bl3;
      bl->next = bl2;
      loaders = bl;
  }
'''
    s = s.replace(anchor, block)
    open(p, "w").write(s)
    print("loaders.c patched")
PYEOF
  INC="-I/tmp/imlib2 -I/tmp/imlib2/src/lib -I/tmp/imlib2/src/modules/loaders"
  RSVG_CFLAGS=$(pkg-config --cflags librsvg-2.0)
  mkdir -p /tmp/builtin
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -Dload2=png_load2 -Dsave=png_save -Dformats=png_formats \
    -c /tmp/imlib2/src/modules/loaders/loader_png.c -o /tmp/builtin/png.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC $RSVG_CFLAGS \
    -Dload2=svg_load2 -Dsave=svg_save -Dformats=svg_formats \
    -c /tmp/imlib2/src/modules/loaders/loader_svg.c -o /tmp/builtin/svg.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -Dload2=jpeg_load2 -Dsave=jpeg_save -Dformats=jpeg_formats \
    -c /tmp/imlib2/src/modules/loaders/loader_jpeg.c -o /tmp/builtin/jpeg.o
  xx-clang -Os -fomit-frame-pointer -DHAVE_CONFIG_H $INC \
    -c /tmp/imlib2/src/lib/loaders.c -o /tmp/builtin/loaders.o
  # 不再 ar r 直改系统 /usr/local/lib/libImlib2.a（魔改系统库，隐式影响其他 imlib2 链接者）；
  # 拷贝到私有归档再注入 loader，xlunch 链接 -L/tmp/builtin -lImlib2 优先取用（2026-11-08 整改）。
  cp /usr/local/lib/libImlib2.a /tmp/builtin/libImlib2.a
  ar r /tmp/builtin/libImlib2.a \
    /tmp/builtin/loaders.o /tmp/builtin/png.o /tmp/builtin/svg.o /tmp/builtin/jpeg.o
  ranlib /tmp/builtin/libImlib2.a
}

#
# Build xlunch
# export TARGETPATH=/usr/local/static/xlunch
function xlunch(){
  set -e   # doExec 调入口子 shell 会 set +e, 重启用保函数内失败即终止(否则吞错)
  apk add hicolor-icon-theme #need hicolor
  # ref: xcompmgr
  apk add cairo-static expat-static fribidi-static glib-static graphite2-static harfbuzz-static
  apk add libxml2-dev ##>> -lxml2 -llzma 

  log "Downloading XLUNCH..."
  rm -rf /tmp/xlunch; # mkdir -p /tmp/xlunch
  # down_catfile ${XLUNCH_URL} | tar -zx --strip 1 -C /tmp/xlunch
  # branch="--branch=$XLUNCH_VER"
  # repo=https://hub.nuaa.cf/Tomas-M/xlunch
  git clone --depth=1 $branch https://gitee.com/g-system/fk-xlunch /tmp/xlunch #;
  log "Configuring XLUNCH..."
  cd /tmp/xlunch #&& ./bootstrap;
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
    make LDFLAGS="-static --static -Wl,--start-group -L/tmp/builtin -lImlib2 -L/usr/local/lib $RSVG_LIBS -lxml2 -lcroco-0.6 $OB_LIBS -lX11-xcb -lxcb-shm -Wl,--end-group" xlunch #default>> all: xlunch entries.dsv

  log "Install XLUNCH..."
  # make;
  make install; #不用install? need

  # view
  ls -lh /tmp/xlunch/
  xx-verify --static /tmp/xlunch/xlunch
}


function b_deps(){
  # 新引入依赖（imlib2 内置 svg loader 链）：librsvg/cairo/pango/xz
  # apk 包（cairo/pango/xz 的 .a 由 apk 提供）；但 librsvg-2.a 无 apk
  # 静态子包，必须本地编译（w-tint2 librsvg，STATIC=yes 只出 .a，
  # librsvg 前置依赖 libcroco）。已存在则跳过编译。
  apk update
  apk add librsvg-dev cairo-dev pango-dev xz-dev
  test -s /usr/local/lib/librsvg-2.a || {
    STATIC=yes bash /src/w-tint2/build.sh libcroco
    STATIC=yes bash /src/w-tint2/build.sh librsvg
  }
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    down_catfile ${IMLIB2_URL} > /dev/null
    ;;
full)
    doExec imlib2
    doExec xlunch
    ;;
b_deps)
    b_deps
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
