#!/bin/sh
set -e
source /src/common.sh

#
# Build pavucontrol 3.0 (GTK2/gtkmm-2.4) 静态
#
# 组装容器 = builder-awe（主题/图标库 murrine/pixmap/rsvg/svg 在此；gtkmm 栈 + pulse 栈已拷入）。
# canberra patch：pavucontrol 用 libcanberra-gtk 做音量反馈音；静态链无 libcanberra，
#   且 configure 硬查 libcanberra-gtk 会失败 → 打补丁去掉（4 处，见 pavucontrol-canberra.patch）。
# 版本 3.0 = 最后 GTK2 版（--disable-gtk3 走 gtkmm-2.4 分支）。
#
# 网络坑（2026-11-05）：容器外网不可达（ghfast.top 失效），host 走 gh-proxy.com 下 tarball
#   docker cp 到 /tmp/pavucontrol-3.0.tar.gz 并解包 /tmp/pavucontrol（离线复用）。
#   正常网络环境走 $GITHUB/pulseaudio/pavucontrol/archive/refs/tags/v3.0.tar.gz（down_catfile）。

function pavucontrol(){
  log "Downloading PAVUCONTROL (v3.0 tarball)..."
    if [ ! -f /tmp/pavucontrol/configure.ac ]; then
      if [ -f /tmp/pavucontrol-3.0.tar.gz ]; then
        rm -rf /tmp/pavucontrol; mkdir -p /tmp/pavucontrol
        tar xzf /tmp/pavucontrol-3.0.tar.gz -C /tmp
        rm -rf /tmp/pavucontrol; mv /tmp/pavucontrol-3.0 /tmp/pavucontrol
      else
        rm -rf /tmp/pavucontrol; mkdir -p /tmp/pavucontrol
        down_catfile $GITHUB/pulseaudio/pavucontrol/archive/refs/tags/v3.0.tar.gz \
          | tar -xz --strip 1 -C /tmp/pavucontrol
      fi
    fi
    cd /tmp/pavucontrol

  log "Applying canberra patch (drop libcanberra-gtk, 4 places)..."
    git apply /src/v-pavucontrol/pavucontrol-canberra.patch 2>/dev/null \
      || patch -p1 < /src/v-pavucontrol/pavucontrol-canberra.patch 2>/dev/null \
      || true

  log "Autogen (tarball has no generated configure)..."
    ./autogen.sh

  log "Configuring PAVUCONTROL (GTK2, static only)..."
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
    LIBS0="-lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    LIBS="$LIBS0" PKG_CONFIG_PATH="/usr/local/static/pulseaudio/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
      ./configure --disable-gtk3 --enable-static --disable-shared \
      --prefix=$TARGETPATH

  log "Compiling PAVUCONTROL (12 objects)..."
    # make 默认目标会尝试链接（Makefile 的 PULSE_LIBS 缺 -lpulsecommon-13.0，链接失败）；
    # 只取它产出的 .o，最终二进制由下方手动 xx-clang++ -static 静态链（geany 式）。
    make -j$(nproc) 2>&1 || log "make link step expected to fail (PULSE_LIBS lacks libpulsecommon); objects produced"
    test -f src/pavucontrol-pavucontrol.o || { log "PAVUCONTROL objects MISSING"; exit 1; }

  log "Static-link PAVUCONTROL (direct, xx-clang++ -static)..."
    # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补一个 libgcc_s.a（copy libgcc.a）兜底。
    if [ ! -f /usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1))
      cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
    fi
    # GTK2 print 后端（file/lpr）由静态 libgtk 提供（-DGTK_PRINT_BACKENDS="file,lpr"，
    # gtkprintbackendfile.o/gtkprintbackendlpr.o）。但 pavucontrol 不调用任何 gtk_print_* →
    # 这些 .o 不会被静态链自动拉取 → 用 -Wl,-u 强制对应符号未定义，从 libgtk.a 拉入真实后端
    # （替代早期 no-op 存根，2026-11-08 gtk 重建后验证可链）。
    mkdir -p $TARGETPATH/bin
    cd /tmp/pavucontrol/src
    xx-clang++ -static -Wl,--strip-all -o $TARGETPATH/bin/pavucontrol \
      *.o \
      -Wl,-u,_gtk_print_backend_file_init -Wl,-u,_gtk_print_backend_file_exit -Wl,-u,_gtk_print_backend_file_create \
      -Wl,-u,_gtk_print_backend_lpr_init -Wl,-u,_gtk_print_backend_lpr_exit -Wl,-u,_gtk_print_backend_lpr_create \
      -Wl,--start-group \
      -lgtkmm-2.4 -latkmm-1.6 -lgdkmm-2.4 -lgiomm-2.4 -lpangomm-1.4 -lglibmm-2.4 -lcairomm-1.0 -lsigc-2.0 \
      -L/usr/local/lib \
      -L/usr/local/static/pulseaudio/lib -L/usr/local/static/pulseaudio/lib/pulseaudio \
      -lpulse-mainloop-glib -lpulse -lpulsecommon-13.0 \
      -lXinerama -lXrandr -lXfixes -lstdc++ -lsupc++ -lgcc -lgcc_eh -lgthread-2.0 \
      $LIBS0 \
      -Wl,--end-group \
      -lintl || { log "PAVUCONTROL static-link FAILED"; exit 1; }

  log "Install PAVUCONTROL data (glade + desktop; make install 会重链失败，手装)..."
    mkdir -p $TARGETPATH/share/pavucontrol $TARGETPATH/share/applications
    cp /tmp/pavucontrol/src/pavucontrol.glade $TARGETPATH/share/pavucontrol/
    cp /tmp/pavucontrol/src/pavucontrol.desktop $TARGETPATH/share/applications/

  log "Install PAVUCONTROL locale (静态 LOCALEDIR=$TARGETPATH/share/locale；po/ 各 .po 由 msgfmt 转 .mo——make 默认只产 .o，po 未生成 .mo，手装才带中文)..."
    if [ -d /tmp/pavucontrol/po ]; then
      for p in /tmp/pavucontrol/po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/pavucontrol.mo 2>/dev/null \
          || log "msgfmt warn: $lang"
      done
      log "locales installed: $(ls /tmp/pavucontrol/po/*.po | wc -l) langs"
    fi

  log "Verify PAVUCONTROL..."
    file $TARGETPATH/bin/pavucontrol
    xx-verify --static $TARGETPATH/bin/pavucontrol || { log "PAVUCONTROL xx-verify FAILED"; exit 1; }
    strings $TARGETPATH/bin/pavucontrol | grep -q "GTK_ICON_THEME" && echo "strings: GTK_ICON_THEME OK"
    strings $TARGETPATH/bin/pavucontrol | grep -q "MurrineRcStyle" && echo "strings: murrine OK"
    strings $TARGETPATH/bin/pavucontrol | grep -q "rsvg" && echo "strings: rsvg OK"
    ls -lh $TARGETPATH/bin/pavucontrol
}

case "$1" in
cache)
    # down_catfile $GITHUB/pulseaudio/pavucontrol/archive/refs/tags/v3.0.tar.gz > /dev/null
    ;;
full)
    pavucontrol
    ;;
b_deps)
    # GTK2 静态库 + gtkmm 栈 + pulse 栈已在 builder-awe 就位（见 u-gtk / v-pavucontrol §3.3/3.4）
    echo "== gtkmm stack =="; ls /usr/lib/libgtkmm-2.4.a /usr/lib/libglibmm-2.4.a /usr/lib/libgiomm-2.4.a 2>&1
    echo "== pulse stack =="; ls /usr/local/static/pulseaudio/lib/libpulse.a /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.0.a 2>&1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
