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

# libnotify 0.8.9 静态化：给 pasystray 用（去掉 --disable-notify 后 notify() 走 libnotify，3.1 方案）。
# 坑（2.1.6/3.1）：main lib 硬编码 shared_library（meson.build:58）→ patch 成 static_library；
#   gio-unix 仅 meson 声明（gio-unix-2.0.pc 无 Libs，仅 Requires gio-2.0；libnotify 代码不用 g_unix 符号）
#   → 符号在 libgio-2.0.a 里，无需独立 gio-unix.a。依赖 gio/glib/gobject/gdk-pixbuf（静态栈已就位）。
# 产物：/usr/lib/libnotify.a + /usr/lib/pkgconfig/libnotify.pc + /usr/include/libnotify/*.h
LIBNOTIFY_VER=0.8.9

# 2026-11-25 方案二交叉: pasystray 栈(gtk2 + pulse) 共用交叉环境(autotools configure + meson libnotify)。
# 设 CROSS_HOST/XX_LIBS_PREFIX/PULSE_PC/XX_CROSS_ARGS: configure 追加 --host、手工 xx-clang 静态链的
#   -L 前缀 sysroot、pulse pkgconfig 前缀 sysroot、libnotify meson --cross-file。
# native(未设 XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
ps_cross(){
  CROSS_HOST=""; XX_LIBS_PREFIX=""; XX_CROSS_ARGS=""
  PULSE_PC="/usr/local/static/pulseaudio/lib/pkgconfig"
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/static/pulseaudio/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    XX_LIBS_PREFIX="$XX_SYSROOT"
    XX_CROSS_ARGS="--cross-file=$XX_CROSS_FILE"
    PULSE_PC="$XX_SYSROOT/usr/local/static/pulseaudio/lib/pkgconfig"
    log "pasystray: CROSS ($XX_TRIPLE)"
  fi
}

libnotify(){
  ps_cross
  if test -f ${XX_SYSROOT:-}/usr/lib/libnotify.a; then
    log "libnotify.a already present, skip"
    return 0
  fi
  LN_TGZ=/tmp/libnotify-$LIBNOTIFY_VER.tar.gz
  log "Building libnotify (static) $LIBNOTIFY_VER..."
  cd /tmp
  rm -rf libnotify-$LIBNOTIFY_VER
  # 1. 离线预置 tarball(/tmp, 宿主 cp)优先; 2. down_catfile 查 tarsrc 缓存(2026-11-18 补, github archive 下载 code=000 失败) + github 兜底
  test -s $LN_TGZ || { \
    log "no staged libnotify tarball, try tarsrc/github ..."; \
    down_catfile https://github.com/GNOME/libnotify/archive/refs/tags/$LIBNOTIFY_VER.tar.gz > $LN_TGZ 2>/dev/null; }
  test -s $LN_TGZ || { log "LIBNOTIFY download FAILED"; rm -f $LN_TGZ; exit 1; }
  tar xzf $LN_TGZ
  cd libnotify-$LIBNOTIFY_VER
  # 2. patch: shared_library -> static_library（静态栈无 .so，且 --default-library=static 对硬编码 shared 无效）
  #   static_library 不接受 version/soversion（shared 才有）→ 一并删（grep -v 子串, sed regex 对 @0@ 匹配不稳）
  #   + 删 subdir('tools')/subdir('docs')：meson 自带 notify-send 工具链 .so 静态失败(attempted static link of
  #     dynamic object), docs 需 docbook——都不要, 只编主库 libnotify.a
  sed -i 's/^libnotify_lib = shared_library(LIBNAME,/libnotify_lib = static_library(LIBNAME,/' libnotify/meson.build
  grep -v "version: '@0@.@1@.@2@'" libnotify/meson.build | grep -v "soversion: LT_CURRENT" > .tmp && mv .tmp libnotify/meson.build
  grep -v "subdir('tools')" meson.build | grep -v "subdir('docs')" > .tmp && mv .tmp meson.build
  #   + meson 版本坑（2026-11-18 CI 复现）：CI 基镜像 meson 0.59.3，libnotify 0.8.9 要求 >=0.64.0
  #     → meson setup ERROR "project requires >= 0.64.0"；libnotify 0.8.9 未用 0.60+ 特有特性，
  #     仅把版本门降回 <=0.59（与其它 patch 一致，静态栈可编）。
  sed -i "s/meson_version: '>= 0.64.0'/meson_version: '>= 0.59.0'/" meson.build
  grep -q ">= 0.59.0" meson.build || { log "LIBNOTIFY meson_version patch FAILED"; exit 1; }
  grep -q "static_library(LIBNAME" libnotify/meson.build || { log "LIBNOTIFY patch FAILED"; exit 1; }
  test -z "$(grep soversion libnotify/meson.build)" || { log "LIBNOTIFY soversion not removed"; exit 1; }
  test -z "$(grep "subdir('tools')" meson.build)" || { log "LIBNOTIFY tools subdir not removed"; exit 1; }
  # 3. meson 静态构建（disable 可选: tests/introspection/man/gtk_doc/docbook_docs）
  # 交叉: --cross-file + install DESTDIR=sysroot + xx_meson_crossfix 重映射 native -I/-L 到 sysroot。
  meson setup build --prefix=/usr --default-library=static $XX_CROSS_ARGS \
    -Dintrospection=disabled -Dtests=false -Dman=false -Dgtk_doc=false -Ddocbook_docs=disabled \
    2>&1 || { log "LIBNOTIFY meson setup FAILED"; exit 1; }
  [ -n "$XX_CROSS_FILE" ] && xx_meson_crossfix build
  meson compile -C build 2>&1 || { log "LIBNOTIFY meson compile FAILED"; exit 1; }
  DESTDIR=${XX_SYSROOT:-} meson install -C build 2>&1 || { log "LIBNOTIFY meson install FAILED"; exit 1; }
  xx_la_fix   # 交叉 .la libdir 修正(仅 is-cross; native 零影响)
  # 4. 验证
  test -f ${XX_SYSROOT:-}/usr/lib/libnotify.a || { log "LIBNOTIFY libnotify.a missing"; exit 1; }
  ls -lh ${XX_SYSROOT:-}/usr/lib/libnotify.a ${XX_SYSROOT:-}/usr/lib/pkgconfig/libnotify.pc
  PKG_CONFIG_PATH="$PULSE_PC" PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT" pkg-config --exists libnotify \
    || { log "LIBNOTIFY pkgconfig not found"; exit 1; }
  log "libnotify done"
}

function pasystray(){
  ps_cross
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

   log "Applying no-icon-tooltip fix patch (-t/--no-icon-tooltip 原本无效，见下)..."
    patch -p1 -N < /src/v-pasystray/pasystray-no-icon-tooltip.patch 2>/dev/null || true

  log "Autogen (aclocal/autoconf/autoheader/automake --add-missing)..."
    aclocal && autoconf && autoheader && automake --add-missing

  log "Configuring PASYSTRAY (GTK2, static only)..."
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    PKG_CONFIG_PATH="$PULSE_PC${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}" \
      ./configure --with-gtk=2 --disable-avahi --disable-appindicator \
      --prefix=$TARGETPATH $CROSS_HOST

  log "Compiling PASYSTRAY (13 objects) + 直链链接..."
    # 2026-11-16: 源头修(同 engrampa, 见 11120827-ci-builder-gtk-app-rootfs.md 6.1)——make 链接走 automake $(LINK)(libtool),
    #   PULSEAUDIO_LIBS 缺 -lpulsecommon + libtool 拆 group → 必然失败(旧靠 || log 容错+下方手链=屏蔽);
    #   覆盖 LINK 去 LIBTOOL 直链 + LIBS 补全 pulse/gtk/X 全链, make 期即出二进制, undefined 清零。
    # 静态 libgcc：-lgcc_s 只有 .so，-static 下需 libgcc.a；补 libgcc_s.a（copy libgcc.a）兜底。
    if [ ! -f /usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1))
      cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
    fi
    # pulsecommon 版本动态获取（源码内部 PA_MAJOR.PA_MINOR=13.13，非分支名 13.99；用已装 .a glob 取）
    # 交叉: pulse 栈 .a 落 sysroot ${XX_LIBS_PREFIX:-} 前缀（native 前缀空=原路径）。
    PULSECOMMON=$(basename $(ls ${XX_LIBS_PREFIX:-}/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-*.a 2>/dev/null | head -1) | sed 's/libpulsecommon-//;s/\.a//')
    test -n "$PULSECOMMON" || { log "PULSECOMMON not found"; exit 1; }
    log "PULSECOMMON=$PULSECOMMON"
    # 完整静态链（pulse + gtk + X + glib，start-group 循环；与旧手链同源）
    PST_LIBS="-Wl,--start-group \
      -L${XX_LIBS_PREFIX:-}/usr/local/static/pulseaudio/lib -L${XX_LIBS_PREFIX:-}/usr/local/static/pulseaudio/lib/pulseaudio \
      -L${XX_LIBS_PREFIX:-}/usr/local/lib \
      -lpulse-mainloop-glib -lpulse -lpulsecommon-$PULSECOMMON \
      -lnotify \
      -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 \
      -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
      -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lcairo \
      -lXinerama -lXrandr -lXfixes \
      -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz \
      -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi \
      -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount -lblkid -lXcomposite -lXdamage \
      -lgthread-2.0 -lm \
      -Wl,--end-group"
    make -j$(nproc) pasystray_LINK="xx-clang -static -no-pie -Wl,--strip-all -Wall -O2 -Os -o \$@" \
      LIBS="$PST_LIBS" 2>&1 || { log "PASYSTRAY make LINK FAILED"; exit 1; }
    mkdir -p $TARGETPATH/bin
    BIN=$(find /tmp/pasystray -name pasystray -type f -perm -u+x 2>/dev/null | head -1)
    test -n "$BIN" || { log "PASYSTRAY binary MISSING"; exit 1; }
    cp -f "$BIN" $TARGETPATH/bin/pasystray

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
    # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
    #   native 仍走 xx-verify(原路径)。
    if [ -n "$XX_CROSS_FILE" ]; then
      file $TARGETPATH/bin/pasystray | grep -qE "ARM.*statically linked" \
        || { log "PASYSTRAY file 非 ARM static"; exit 1; }
    else
      xx-verify --static $TARGETPATH/bin/pasystray || { log "PASYSTRAY xx-verify FAILED"; exit 1; }
    fi
    strings $TARGETPATH/bin/pasystray | grep -q "GTK_ICON_THEME" && echo "strings: GTK_ICON_THEME OK"
    strings $TARGETPATH/bin/pasystray | grep -q "MurrineRcStyle" && echo "strings: murrine OK"
    strings $TARGETPATH/bin/pasystray | grep -q "rsvg" && echo "strings: rsvg OK"
    # 2026-11-18: libnotify 符号验证——CI 曾"构建成功"但产物无 notify 实现（5.7M 部分链接），
    #   oneBuild 吞错假成功；此检查让缺 libnotify 直接报错（不假成功）。
    strings $TARGETPATH/bin/pasystray | grep -q "notify_notification_show\|notify_init" \
      && echo "strings: libnotify OK" \
      || { log "PASYSTRAY libnotify MISSING (HAVE_NOTIFY=0? no dunst notification)"; exit 1; }
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
    echo "== pulse stack =="; ls /usr/local/static/pulseaudio/lib/libpulse.a /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-*.a 2>&1
    echo "== libnotify =="; libnotify || exit 1
    ;;
*) #compile
    oneBuild $1
    exit $?
    ;;
esac
exit 0
