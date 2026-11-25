#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-geany}"
source /src/common.sh

#
# Build geany 1.37.1 (GTK2, Scintilla=C++) 静态
#
# 网络坑（2026-11-05）：builder 容器外网不可达（DNS 通、git/curl 全挂），ghfast.top 已失效。
# 实测 host 走 gh-proxy.com 可下载 tarball；本容器内已由 host 下载 + docker cp 到 /tmp/geany-1.37.1.tar.gz
# 并解包 /tmp/geany（离线复用）。正常网络环境走 $GITHUB/geany/geany git clone。
# 版本 1.37.1 = 最后一个支持 GTK2 的发布（1.38 起删 GTK2；2.0 起强制 GTK3.24）。

# 2026-11-25 方案二交叉: geany 栈(gtk2) 共用交叉环境(autotools configure + 手工 xx-clang++ 静态链)。
# 设 CROSS_HOST/XX_LIBS_PREFIX: configure 追加 --host、手工 xx-clang++ 静态链的 -L 前缀 sysroot。
# native(未设 XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
geany_cross(){
  CROSS_HOST=""; XX_LIBS_PREFIX=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export CXX=xx-clang++
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc/cc 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    XX_LIBS_PREFIX="$XX_SYSROOT"
    log "geany: CROSS ($XX_TRIPLE)"
  fi
}

function geany(){
  geany_cross
  log "Downloading GEANY..."
    if [ ! -f /tmp/geany/configure.ac ]; then
      # 离线：host 下载 + docker cp 的 tarball 已解包 /tmp/geany；否则 git clone
      if [ -f /tmp/geany-1.37.1.tar.gz ]; then
        rm -rf /tmp/geany; mkdir -p /tmp/geany
        tar xzf /tmp/geany-1.37.1.tar.gz -C /tmp/geany --strip-components=1
      else
        rm -rf /tmp/geany
        gitclone https://gitee.com/g-system/fk-geany /tmp/geany --branch=1.37.1
      fi
    fi
    cd /tmp/geany

  log "Configuring GEANY (static only, no shared)..."
    # 关键：LT_INIT([disable-static]) 默认只出 .so；--enable-static 覆盖之，--disable-shared 强制纯静态。
    # --disable-vte：VTE 是 GTK2 终端组件，非必需；--disable-*-docs 跳过文档。
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    # 交叉: 头/库搜索前缀 sysroot(仅 is-cross; native 空=原路径零影响)
    if [ -n "$XX_CROSS_FILE" ]; then
      export CPPFLAGS="-I$XX_SYSROOT/usr/local/include -I$XX_SYSROOT/usr/include $CPPFLAGS"
      export LDFLAGS="-L$XX_SYSROOT/usr/local/lib -L$XX_SYSROOT/usr/lib $LDFLAGS"
    fi
    # autogen.sh 末尾会自带跑 configure "$@"(见 autogen.sh:99)——native 该次默认 gtk3 能过
    # (builder 有 gtk3)；交叉 sysroot 只有 gtk2 → 该次 configure 报 gtk+-3.0 未满足必败。
    # 交叉用 NOCONFIGURE=1 跳过 autogen 内置 configure(autotools 照常生成), 由下方显式
    #   ./configure --enable-gtk2 --host=... 接管(仅 is-cross; native 原路径零影响)。
    if [ -n "$XX_CROSS_FILE" ]; then
      NOCONFIGURE=1 ./autogen.sh
    else
      ./autogen.sh
    fi
    ./configure --enable-static --disable-shared \
      --enable-gtk2 \
      --disable-vte \
      --disable-html-docs --disable-pdf-docs --disable-api-docs \
      --prefix=$TARGETPATH $CROSS_HOST

  log "Compiling GEANY (objects + libgeany.a)..."
    # pcmanfm 式 GTK2 静态链（含 rsvg/croco 供 gdk-pixbuf 内置 svg loader 解析）
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
    LIBS0="-lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    # 注意：geany 主程序用 --tag=CC 链接（src/Makefile.am geany_LINK），libtool 的 -static 只选 .a
    # 不转发给驱动 → 产物仍是动态。故 make 只负责出 objects + libgeany.a，geany 二进制作直接静态链接。
    # 2026-11-14 再修: make 默认 all 会用 geany_LINK(libtool) 链 geany 二进制, libtool 处理 LIBS 里
    #   -lrsvg-2(有 .la) 时展开/重排破坏 --start-group 循环 → rsvg_handle_* undefined(#36 geany CI 踩)。
    #   改 make 只编 main.o(geany_SOURCES=main.c)+libgeany.la 不链二进制(geany_OBJECTS 是变量名非目标),
    #   geany 二进制由下方 xx-clang++ -static 直接链(已验证成功)。
    # CI 干净树: libgeany.la 依赖 ../scintilla/libscintilla.la + src/tagmanager/libtagmanager.la,
    #   libtagmanager.la 又依赖 ../ctags/libctags.la——必须按 ctags→scintilla→tagmanager→src 顺序先编子目录
    #   (make -C src 单独跑在干净树报 "No rule to make target '.../libscintilla.la'"/'tagmanager/libtagmanager.la'/'ctags/libctags.la', 见 5.1①)。
    make -j$(nproc) -C ctags libctags.la \
      || { log "GEANY ctags build FAILED"; exit 1; }
    make -j$(nproc) -C scintilla libscintilla.la \
      || { log "GEANY scintilla build FAILED"; exit 1; }
    make -j$(nproc) -C src/tagmanager libtagmanager.la \
      || { log "GEANY tagmanager build FAILED"; exit 1; }
    make -j$(nproc) -C src main.o libgeany.la \
      GTK_LIBS="" GTHREAD_LIBS="" \
      || { log "GEANY build FAILED"; exit 1; }

  log "Install GEANY (data + lib)..."
    # 2026-11-14: make install 默认依赖 all(含 geany 二进制), libtool geany_LINK 链 bin 仍踩 loader undefined;
    #   改 install-data 只装数据/库(不装 bin_PROGRAMS), geany 二进制由下方 xx-clang++ -static 手动链。
    make install-data 2>&1 > /dev/null || { log "GEANY install FAILED"; exit 1; }
    xx_la_fix   # 交叉 .la libdir 修正(仅 is-cross; native 零影响)

  log "Static-link geany binary (direct, xx-clang++ -static)..."
    # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补一个 libgcc_s.a（copy libgcc.a）兜底。
    # 交叉: libgcc.a 在 sysroot gcc 目录, libgcc_s.a 落 sysroot(仅 is-cross; native 原路径零影响)。
    if [ ! -f ${XX_SYSROOT:-}/usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find ${XX_SYSROOT:-}/usr/lib/gcc -name libgcc.a | head -1))
      cp $GCCDIR/libgcc.a ${XX_SYSROOT:-}/usr/lib/libgcc_s.a
    fi
    cd /tmp/geany/src
    mkdir -p $TARGETPATH/bin
    # 交叉: 静态链 -L 前缀 sysroot(仅 is-cross; native 空=原路径零影响)
    XX_LINK_L=""; [ -n "$XX_CROSS_FILE" ] && XX_LINK_L="-L$XX_SYSROOT/usr/local/lib -L$XX_SYSROOT/usr/lib"
    xx-clang++ -static -Wl,--strip-all -o $TARGETPATH/bin/geany main.o .libs/libgeany.a \
      $XX_LINK_L \
      -Wl,--start-group -lXinerama -lXfixes -lXrandr -lstdc++ -lsupc++ -lgcc -lgcc_eh -lgthread-2.0 $LIBS0 -Wl,--end-group \
      -lintl || { log "GEANY static-link FAILED"; exit 1; }

  log "Verify GEANY..."
    file $TARGETPATH/bin/geany
    # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
    #   native 仍走 xx-verify(原路径)。
    if [ -n "$XX_CROSS_FILE" ]; then
      file $TARGETPATH/bin/geany | grep -qE "ARM.*statically linked" \
        || { log "GEANY file 非 ARM static"; exit 1; }
    else
      xx-verify --static $TARGETPATH/bin/geany || { log "GEANY xx-verify FAILED"; exit 1; }
    fi
}

case "$1" in
cache)
    ;;
full)
    doExec geany || exit 1
    ;;
b_deps)
    # GTK2 静态库已在 builder（builder-obox，alpine-builder-gtk224-2）齐备（见 u-gtk/v-pcmanfm b_deps）
    # geany 额外需要：libstdc++.a / libsupc++.a（apk g++ 自带）——已装
    find /usr/lib |egrep "libstdc|libsupc|libgcc|libgthread|libgtk|libgdk|pango|libatk|pixbuf|libX" |grep "\.a$" |sort
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
