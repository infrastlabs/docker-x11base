#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-pasystray}"
source /src/common.sh

#
# Build pasystray 0.8.2 (GTK2) 静态
#
# 组装容器 = builder-awe（GTK2 静态栈 + pulse 栈已拷入；librsvg/murrine/pixmap 主题库在此）。
# 版本 0.8.2 = 最后稳定版；configure 用 --with-gtk=2 走 GTK2 分支（注意：不是 --without-gtk3）。
# 可选组件全禁：avahi/notify/appindicator（静态链无对应库；x11 保留做托盘/热键）。
#
# 网络坑（2026-11-06）：容器外网 github 已通；若不通 host 下 tarball docker cp 到
#   /tmp/pasystray-0.8.2.tar.gz 离线复用（正常走 $GITHUB/christophgysin/pasystray/.../0.8.2.tar.gz）。
#
# 关键坑（实测 2026-11-06，见 docs/2026/11051633-v-pavucontrol.md §三）：
#   1. make 链接必然失败：Makefile 的 PULSEAUDIO_LIBS 缺 -lpulsecommon-13.0
#      （pa_log_level_meta/pa_init_i18n/pa_snprintf/pa_loop_write 未定义）→ 只取 .o 手动静态链。
#   2. 静态链缺 -lcairo / -lXinerama -lXrandr -lXfixes（pkg-config gtk+-2.0 末尾有 -lcairo，
#      但 X 扩展库须显式加）→ 漏掉会 2350 个 undefined（cairo_*/XFixes*/XRR*/Xinerama*）。
#   3. glade 类型注册崩溃：GtkBuilder 用 g_type_from_name() 解析 glade object class，静态链下
#      widget .o 被代码引用拉进、但 get_type() 从不在运行时被调 → "Invalid object type `GtkMessageDialog'"
#      SIGTRAP。补丁 ui.c 用 volatile 强制调 gtk_*_get_type()（裸调用会被 gcc 当 pure/const 折叠掉）。

function pasystray(){
  log "Downloading PASYSTRAY (v0.8.2 tarball)..."
    if [ ! -f /tmp/pasystray/configure.ac ]; then
      if [ -f /tmp/pasystray-0.8.2.tar.gz ]; then
        rm -rf /tmp/pasystray; mkdir -p /tmp/pasystray
        tar xzf /tmp/pasystray-0.8.2.tar.gz -C /tmp
        rm -rf /tmp/pasystray; mv /tmp/pasystray-0.8.2 /tmp/pasystray
      else
        rm -rf /tmp/pasystray; mkdir -p /tmp/pasystray
        down_catfile $GITHUB/christophgysin/pasystray/archive/refs/tags/0.8.2.tar.gz \
          | tar -xz --strip 1 -C /tmp/pasystray
      fi
    fi
    cd /tmp/pasystray

  log "Applying glade type-registration patch (static GTK2 GtkBuilder)..."
    patch -p1 -N < /src/v-pasystray/pasystray-glade-types.patch 2>/dev/null || true

  log "Applying i18n patch (zh_CN gettext init + _() wrap; 需在 glade-types 之后)..."
    patch -p1 -N < /src/v-pasystray/pasystray-i18n.patch 2>/dev/null || true

  log "Autogen (aclocal/autoconf/autoheader/automake --add-missing)..."
    aclocal && autoconf && autoheader && automake --add-missing

  log "Configuring PASYSTRAY (GTK2, static only)..."
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    PKG_CONFIG_PATH="/usr/local/static/pulseaudio/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
      ./configure --with-gtk=2 --disable-avahi --disable-notify --disable-appindicator \
      --prefix=$TARGETPATH

  log "Compiling PASYSTRAY (13 objects)..."
    # make 默认目标会尝试链接（Makefile 的 PULSEAUDIO_LIBS 缺 -lpulsecommon-13.0，链接失败）；
    # 只取它产出的 .o，最终二进制由下方手动 xx-clang -static 静态链。
    make -j$(nproc) 2>&1 || log "make link step expected to fail (PULSEAUDIO_LIBS lacks libpulsecommon); objects produced"
    test -f src/pasystray-ui.o || { log "PASYSTRAY objects MISSING"; exit 1; }

  log "Static-link PASYSTRAY (direct, xx-clang -static)..."
    # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补一个 libgcc_s.a（copy libgcc.a）兜底。
    if [ ! -f /usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1))
      cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
    fi
    mkdir -p $TARGETPATH/bin
    cd /tmp/pasystray/src
    xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/pasystray \
      *.o \
      -Wl,--start-group \
      -L/usr/local/static/pulseaudio/lib -L/usr/local/static/pulseaudio/lib/pulseaudio \
      -lpulse-mainloop-glib -lpulse -lpulsecommon-13.99 \
      -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 \
      -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
      -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lcairo \
      -lXinerama -lXrandr -lXfixes \
      -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz \
      -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi \
      -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount -lblkid -lXcomposite -lXdamage \
      -lgthread-2.0 -lm \
      -Wl,--end-group \
      || { log "PASYSTRAY static-link FAILED"; exit 1; }

  log "Install PASYSTRAY data (glade + desktop; make install 会重链失败，手装)..."
    mkdir -p $TARGETPATH/share/pasystray $TARGETPATH/share/applications
    cp /tmp/pasystray/src/pasystray.gtk2.glade $TARGETPATH/share/pasystray/
    cp /tmp/pasystray/data/pasystray.desktop $TARGETPATH/share/applications/

  log "Install PASYSTRAY zh_CN locale (.mo via msgfmt)..."
    mkdir -p $TARGETPATH/share/locale/zh_CN/LC_MESSAGES
    msgfmt -o $TARGETPATH/share/locale/zh_CN/LC_MESSAGES/pasystray.mo /src/v-pasystray/zh_CN.po \
      || { log "PASYSTRAY msgfmt FAILED"; exit 1; }
    ls -lh $TARGETPATH/share/locale/zh_CN/LC_MESSAGES/pasystray.mo

  log "Verify PASYSTRAY..."
    file $TARGETPATH/bin/pasystray
    xx-verify --static $TARGETPATH/bin/pasystray || { log "PASYSTRAY xx-verify FAILED"; exit 1; }
    strings $TARGETPATH/bin/pasystray | grep -q "GTK_ICON_THEME" && echo "strings: GTK_ICON_THEME OK"
    strings $TARGETPATH/bin/pasystray | grep -q "MurrineRcStyle" && echo "strings: murrine OK"
    strings $TARGETPATH/bin/pasystray | grep -q "rsvg" && echo "strings: rsvg OK"
    ls -lh $TARGETPATH/bin/pasystray
}

case "$1" in
cache)
    # down_catfile $GITHUB/christophgysin/pasystray/archive/refs/tags/0.8.2.tar.gz > /dev/null
    ;;
full)
    doExec pasystray || exit 1
    ;;
b_deps)
    # GTK2 静态库 + pulse 栈已在 builder-awe 就位（见 u-gtk / v-pavucontrol §3.3/3.4）
    echo "== gtk2 stack =="; ls /usr/lib/libgtk-x11-2.0.a /usr/lib/libgdk-x11-2.0.a 2>&1
    echo "== pulse stack =="; ls /usr/local/static/pulseaudio/lib/libpulse.a /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.a 2>&1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
