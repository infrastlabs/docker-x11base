#!/bin/sh
set -e
source /src/common.sh

#
# Build geany 1.34.0 (GTK2, Scintilla=C++) 静态
#
# 网络坑（2026-11-05）：builder 容器外网不可达（DNS 通、git/curl 全挂），ghfast.top 已失效。
# 实测 host 走 gh-proxy.com 可下载 tarball；本容器内已由 host 下载 + docker cp 到 /tmp/geany-1.34.0.tar.gz
# 并解包 /tmp/geany（离线复用）。正常网络环境走 $GITHUB/geany/geany git clone。
# 版本 1.34.0 = 最后几个 GTK2 之一（1.38 起删 GTK2；2.0 起强制 GTK3.24）。

function geany(){
  log "Downloading GEANY..."
    if [ ! -f /tmp/geany/configure.ac ]; then
      # 离线：host 下载 + docker cp 的 tarball 已解包 /tmp/geany；否则 git clone
      if [ -f /tmp/geany-1.34.0.tar.gz ]; then
        rm -rf /tmp/geany; mkdir -p /tmp/geany
        tar xzf /tmp/geany-1.34.0.tar.gz -C /tmp --strip-components=1
      else
        rm -rf /tmp/geany
        git clone --depth=1 --branch=1.34.0 $GITHUB/geany/geany /tmp/geany
      fi
    fi
    cd /tmp/geany

  log "Configuring GEANY (static only, no shared)..."
    # 关键：LT_INIT([disable-static]) 默认只出 .so；--enable-static 覆盖之，--disable-shared 强制纯静态。
    # --disable-vte：VTE 是 GTK2 终端组件，非必需；--disable-*-docs 跳过文档。
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    ./autogen.sh
    ./configure --enable-static --disable-shared \
      --disable-vte \
      --disable-html-docs --disable-pdf-docs --disable-api-docs \
      --prefix=$TARGETPATH

  log "Compiling GEANY (objects + libgeany.a)..."
    # pcmanfm 式 GTK2 静态链（含 rsvg/croco 供 gdk-pixbuf 内置 svg loader 解析）
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
    LIBS0="-lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    # 注意：geany 主程序用 --tag=CC 链接（src/Makefile.am geany_LINK），libtool 的 -static 只选 .a
    # 不转发给驱动 → 产物仍是动态。故 make 只负责出 objects + libgeany.a，geany 二进制作直接静态链接。
    make -j$(nproc) \
      GTK_LIBS="" GTHREAD_LIBS="" \
      LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr -lstdc++ -lsupc++ -lgcc -lgcc_eh -lgthread-2.0 $LIBS0 -Wl,--end-group" \
      || { log "GEANY build FAILED"; exit 1; }

  log "Install GEANY (data + lib)..."
    make install 2>&1 > /dev/null || { log "GEANY install FAILED"; exit 1; }

  log "Static-link geany binary (direct, xx-clang++ -static)..."
    # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补一个 libgcc_s.a（copy libgcc.a）兜底。
    if [ ! -f /usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1))
      cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
    fi
    cd /tmp/geany/src
    xx-clang++ -static -Wl,--strip-all -o $TARGETPATH/bin/geany main.o .libs/libgeany.a \
      -Wl,--start-group -lXinerama -lXfixes -lXrandr -lstdc++ -lsupc++ -lgcc -lgcc_eh -lgthread-2.0 $LIBS0 -Wl,--end-group \
      -lintl || { log "GEANY static-link FAILED"; exit 1; }

  log "Verify GEANY..."
    file $TARGETPATH/bin/geany
    xx-verify --static $TARGETPATH/bin/geany || { log "GEANY xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    geany
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
