#!/bin/sh
set -e
source /src/common.sh

# v-ibus: IBus 输入法栈静态构建（方案 B panel + 方案 A2 im 模块源）
# 产物（全静态，xx-clang，musl）:
#   librime 1.9.0        -> /usr/local/static/deps/lib/librime.a + share/rime-data
#   ibus 1.5.35          -> /usr/local/static/ibus/{bin,libexec,lib,include,share}
#                           (bin/ibus-daemon ibus-setup; libexec/ibus-x11 ibus-engine-simple;
#                            lib/libibus-1.0.a; client/gtk2/.libs/im_ibus_la-*.o 供 u-gtk A2 合并)
#   panel (方案 B, 自定义) -> /usr/local/static/ibus/libexec/ibus-panel
#   ibus-rime 1.6.1      -> /usr/local/static/ibus-rime/libexec/ibus-rime/ibus-engine-rime
# 依赖: x-dbus(静态 dbus/dbus-glib), u-gtk 基座 libgtk(供 panel 链), librime 数据。
# A2(把 ibus im 模块静态注册进 libgtk)由 u-gtk/build.sh 的 gtk_ibus_a2() 负责，本脚本只出 ibus 侧。

# ---- librime 依赖（源码构建到 /usr/local/static/deps）----
# librime 需要 glog/leveldb/yaml-cpp/marisa/opencc 静态库 + Boost(apk boost1.77-static)。
# 这些库原为手工源码构建（无仓库脚本），此处固化以保证可复现。
# libnotify 为 stub(非 librime 依赖)，不构建。
function deps_glog(){
  log "Downloading glog 0.6.0..."
  if [ ! -d /tmp/glog-0.6.0 ]; then
    git clone --depth=1 --branch=v0.6.0 $GITHUB/google/glog /tmp/glog-0.6.0
  fi
  cd /tmp/glog-0.6.0
  log "CMake glog (static)..."
  mkdir -p build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/static/deps \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF \
    -DCMAKE_C_COMPILER=xx-clang -DCMAKE_CXX_COMPILER=xx-clang++ \
    ..
  make -j$(nproc)
  make install
  [ -f /usr/local/static/deps/lib/libglog.a ] || { log "libglog.a MISSING"; exit 1; }
}

function deps_leveldb(){
  log "Downloading leveldb 1.20..."
  if [ ! -d /tmp/leveldb-1.20 ]; then
    git clone --depth=1 --branch=v1.20 $GITHUB/google/leveldb /tmp/leveldb-1.20
  fi
  cd /tmp/leveldb-1.20
  log "Make leveldb (static archive, xx-clang++)..."
  # 仅构建静态归档 out-static/libleveldb.a；默认 all 会链共享库+db_bench，被容器全局 -static LDFLAGS 打断
  make out-static/libleveldb.a CC=xx-clang CXX=xx-clang++ OPT="-O2 -DNDEBUG"
  mkdir -p /usr/local/static/deps/lib /usr/local/static/deps/include/leveldb
  cp out-static/libleveldb.a /usr/local/static/deps/lib/
  cp include/leveldb/*.h /usr/local/static/deps/include/leveldb/
  [ -f /usr/local/static/deps/lib/libleveldb.a ] || { log "libleveldb.a MISSING"; exit 1; }
}

function deps_yaml(){
  log "Downloading yaml-cpp 0.8.0..."
  if [ ! -d /tmp/yaml-cpp-0.8.0 ]; then
    git clone --depth=1 --branch=0.8.0 $GITHUB/jbeder/yaml-cpp /tmp/yaml-cpp-0.8.0
  fi
  cd /tmp/yaml-cpp-0.8.0
  log "CMake yaml-cpp (static)..."
  mkdir -p build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/static/deps \
    -DYAML_CPP_BUILD_CONTRIB=OFF -DYAML_CPP_BUILD_TESTS=OFF -DYAML_CPP_BUILD_TOOLS=OFF \
    -DCMAKE_CXX_COMPILER=xx-clang++ \
    ..
  make -j$(nproc)
  make install
  [ -f /usr/local/static/deps/lib/libyaml-cpp.a ] || { log "libyaml-cpp.a MISSING"; exit 1; }
}

function deps_marisa(){
  log "Downloading marisa-trie 0.2.6..."
  if [ ! -d /tmp/marisa-trie-0.2.6 ]; then
    git clone --depth=1 --branch=v0.2.6 $GITHUB/s-yata/marisa-trie /tmp/marisa-trie-0.2.6
  fi
  cd /tmp/marisa-trie-0.2.6
  log "Autoreconf + configure marisa..."
  autoreconf -i || true
  ./configure CC=xx-clang --prefix=/usr/local/static/deps
  make -j$(nproc)
  make install
  [ -f /usr/local/static/deps/lib/libmarisa.a ] || { log "libmarisa.a MISSING"; exit 1; }
}

function deps_opencc(){
  log "Downloading OpenCC 1.1.9..."
  if [ ! -d /tmp/OpenCC-ver.1.1.9 ]; then
    git clone --depth=1 --branch=ver.1.1.9 $GITHUB/BYVoid/OpenCC /tmp/OpenCC-ver.1.1.9
  fi
  cd /tmp/OpenCC-ver.1.1.9
  log "CMake OpenCC (static, 内含 marisa)..."
  mkdir -p build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/static/deps \
    -DBUILD_DOCUMENTATION=OFF -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_CXX_COMPILER=xx-clang++ \
    ..
  make -j$(nproc)
  make install
  [ -f /usr/local/static/deps/lib/libopencc.a ] || { log "libopencc.a MISSING"; exit 1; }
}

function deps(){
  # Boost 静态库为 librime 所需（filesystem/regex/system），apk boost1.77-static 已装
  apk info -e boost1.77-static >/dev/null 2>&1 || apk add boost1.77-static
  deps_glog
  deps_leveldb
  deps_yaml
  deps_marisa
  deps_opencc
}

# ---- librime 1.9.0（rime 引擎核心，C++；含 rime-data）----
function librime(){
  log "Downloading librime 1.9.0..."
  if [ ! -d /tmp/librime-1.9.0 ]; then
    git clone --depth=1 --branch=1.9.0 $GITHUB/rime/librime /tmp/librime-1.9.0
  fi
  cd /tmp/librime-1.9.0
  log "CMake librime (static, xx-clang)..."
  mkdir -p build && cd build
  cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/static/deps \
    -DRIME_DATA_DIR=/usr/local/static/deps/share/rime-data \
    -DBUILD_TEST=OFF -DENABLE_ASAN=OFF -DENABLE_LOGGING=ON \
    -DENABLE_THREADING=ON -DENABLE_EXTERNAL_PLUGINS=OFF \
    -DBUILD_STATIC=ON -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_PREFIX_PATH=/usr/local/static/deps \
    -DCMAKE_C_COMPILER=xx-clang -DCMAKE_CXX_COMPILER=xx-clang++ \
    ..
  make -j$(nproc)
  make install
  [ -f /usr/local/static/deps/lib/librime.a ] || { log "librime.a MISSING"; exit 1; }
  log "librime done: $(ls -la /usr/local/static/deps/lib/librime.a | awk '{print $5}') bytes"
}

# ---- ibus 1.5.35（daemon + libibus + gtk2 im 模块）----
function ibus(){
  log "Downloading ibus 1.5.35..."
  if [ ! -f /tmp/ibus/configure.ac ]; then
    if [ -f /src/v-ibus/ibus-1.5.35.tar.gz ]; then
      rm -rf /tmp/ibus; mkdir -p /tmp/ibus
      tar xzf /src/v-ibus/ibus-1.5.35.tar.gz -C /tmp/ibus --strip-components=1
    else
      git clone --depth=1 --branch=1.5.35 $GITHUB/ibus/ibus /tmp/ibus
    fi
  fi
  cd /tmp/ibus
  # main.c 自定义补丁（候选/aux/property/语言栏 + per-IC set_engine）；幂等：已打则跳过
  if ! grep -q '_context_update_lookup_table_cb' client/x11/main.c; then
    log "Patching ibus client/x11/main.c (候选/aux/property/语言栏 + per-IC set_engine)..."
    patch -p1 < /src/v-ibus/ibus-1.5.35-main-c.patch || { log "IBUS MAIN.C PATCH FAILED"; exit 1; }
  else
    log "main.c already patched, skip"
  fi
  # ibusim.c A2 守卫（防止 libgtk 合并 im 模块后 g_module_check_init 重复定义）；幂等
  if ! grep -q 'g_module_check_init' client/gtk2/ibusim.c; then
    log "Patching ibus client/gtk2/ibusim.c (INCLUDE_IM_ibus 守卫)..."
    patch -p1 < /src/u-gtk/ibus-ibusim-gmodule-check-init.patch || { log "IBUS IBUSIM.C PATCH FAILED"; exit 1; }
  else
    log "ibusim.c already patched, skip"
  fi
  log "Configuring ibus (gtk2 开, 其余关)..."
  # gtk2 必须开(client/gtk2 出 A2 用 im_ibus_la-*.o); gtk3/4/wayland/emoji-dict/unicode-dict 关。
  export PKG_CONFIG_PATH="/usr/local/static/dbus/lib/pkgconfig:/usr/local/static/dbus-glib/lib/pkgconfig"
  # autogen.sh 默认会跑一次 ./configure --enable-gtk-doc（无 --disable-gtk3），须 NOCONFIGURE 跳过
  NOCONFIGURE=1 ./autogen.sh
  ./configure --enable-gtk2 \
    --disable-gtk3 --disable-gtk4 --disable-libnotify --disable-introspection \
    --disable-vala --disable-appindicator --disable-systemd-services --disable-dconf \
    --disable-wayland --disable-emoji-dict --disable-unicode-dict --enable-xim \
    --prefix=/usr/local/static/ibus
  log "Compiling ibus..."
  # emoji/unicode-dict 关闭时 Makefile 仍引用 ibusemojigen.h/ibusunicodegen.h（生成规则被注释），建空占位
  [ -f src/ibusemojigen.h ] || echo '/* empty (emoji-dict disabled) */' > src/ibusemojigen.h
  [ -f src/ibusunicodegen.h ] || echo '/* empty (unicode-dict disabled) */' > src/ibusunicodegen.h
  # 静态链接需全部传递依赖；ibus 的 make 只捕获了非 --static 的 pkg-config 输出，且 libtool/.la+--as-needed
  # 会漏静态闭包。故用与 panel 相同的已验证静态 GTK2 全链路（start-group 处理循环依赖）+ xcb 注入 LIBS。
  # ⚠️已知限制: libtool 会吞 --start-group 且静态依赖闭包不全，导致 ibus-x11 的静态链不能由 make
  #   复现（此前误判为 libgdk 缺 gdk_drag_context_*；实测 libgdk 含全部拖拽符号）。
  #   daemon/engine-simple 可链；ibus-x11 需手工直链（见下方 x11() 函数）。
  IBUS_LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount -lblkid -lXcomposite -lcairo -lXdamage -Wl,--end-group"
  make -j$(nproc) LIBS="$IBUS_LIBS"
  log "Installing ibus..."
  make install
  [ -f /usr/local/static/ibus/lib/libibus-1.0.a ] || { log "libibus-1.0.a MISSING"; exit 1; }
  [ -f /tmp/ibus/client/gtk2/.libs/im_ibus_la-ibusim.o ] || { log "ibus gtk2 im module MISSING"; exit 1; }
  log "ibus done (libibus + daemon + gtk2 im module objects)"
}

# ---- ibus-x11（XIM 模块，全静态直链：libtool 吞 --start-group 故绕开 make 手工链）----
function x11(){
  log "Building ibus-x11 (XIM, static direct-link)..."
  local SRC BUILD OUT
  SRC=/tmp/ibus
  if [ ! -f "$SRC/client/x11/main.c" ]; then
    log "ibus source missing at $SRC; unpacking pristine..."
    mkdir -p /tmp/ibx11
    tar xzf /tmp/ibus-pristine.tar.gz -C /tmp/ibx11
    SRC=/tmp/ibx11/ibus-1.5.35
  fi
  BUILD=/tmp/ibus-x11-build
  OUT=/usr/local/static/ibus/libexec/ibus-x11
  [ -f "$SRC/client/x11/main.c" ] || { log "NO ibus x11 source"; exit 1; }
  if ! grep -q "_context_update_lookup_table_cb" "$SRC/client/x11/main.c"; then
    patch -p1 -d "$SRC" < /src/v-ibus/ibus-1.5.35-main-c.patch
  fi
  rm -rf "$BUILD"; mkdir -p "$BUILD"
  cd "$SRC/util/IMdkit"
  for f in FrameMgr i18nAttr i18nClbk i18nIc i18nIMProto i18nMethod i18nOffsetCache \
           i18nPtHdr i18nUtil i18nX IMConn IMMethod IMValues; do
    xx-clang -c "$f.c" -o "$BUILD/$f.o" -I. -I"$SRC"
  done
  (cd "$BUILD" && ar rcs libIMdkit.a *.o)
  cat > "$BUILD/config.h" <<CFG
#define HAVE_XFIXES 1
#define HAVE_XKB 1
#define HAVE_X11_XKBLIB_H 1
#define ENABLE_SYNC_MODE 1
#define GETTEXT_PACKAGE "ibus"
#define PACKAGE "ibus"
#define PACKAGE_NAME "ibus"
#define PACKAGE_VERSION "1.5.35"
#define PACKAGE_STRING "ibus 1.5.35"
#define VERSION "1.5.35"
CFG
  GCFLAGS="-I$BUILD $(pkg-config --cflags gtk+-2.0) \
    $(PKG_CONFIG_PATH=/usr/local/static/ibus/lib/pkgconfig pkg-config --cflags ibus-1.0) \
    -I/usr/local/static/dbus/include/dbus-1.0 -I/usr/local/static/dbus/lib/dbus-1.0/include \
    -DDBUS_STATIC_BUILD -I$SRC/util/IMdkit -I$SRC/src -pthread"
  cd "$SRC/client/x11"
  xx-clang -c main.c -o "$BUILD/main.o" $GCFLAGS
  xx-clang -c gdk-private.c -o "$BUILD/gdk-private.o" $GCFLAGS
  xx-clang -static -Wl,--strip-all -o "$BUILD/ibus-x11" \
    "$BUILD/main.o" "$BUILD/gdk-private.o" "$BUILD/libIMdkit.a" \
    /usr/local/static/ibus/lib/libibus-1.0.a \
    -Wl,--start-group -lXinerama -lXfixes -lXrandr -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 \
    -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
    -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz \
    -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 \
    -lglib-2.0 -lpcre -lgraphite2 -lffi -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount \
    -lblkid -lXcomposite -lcairo -lXdamage -Wl,--end-group \
    || { log "IBUS-X11 link FAILED"; exit 1; }
  cp "$BUILD/ibus-x11" "$OUT"
  file "$OUT" | head -1
}

# ---- ibus-setup（GTK2 静态重写：引擎管理，原版 Python->C）----
function setup(){
  log "Building ibus-setup (GTK2 static)..."
  cd /tmp
  rm -rf /tmp/ibus-setup-build && mkdir -p /tmp/ibus-setup-build
  GCFLAGS="$(pkg-config --cflags gtk+-2.0) \
    $(PKG_CONFIG_PATH=/usr/local/static/ibus/lib/pkgconfig pkg-config --cflags ibus-1.0) \
    -I/usr/local/static/dbus/include/dbus-1.0 -I/usr/local/static/dbus/lib/dbus-1.0/include \
    -DDBUS_STATIC_BUILD -pthread"
  xx-clang -c /src/v-ibus/ibus-setup-gtk2.c -o /tmp/ibus-setup-build/setup.o $GCFLAGS \
    || { log "SETUP compile FAILED"; exit 1; }
  xx-clang -static -Wl,--strip-all -o /usr/local/static/ibus/bin/ibus-setup \
    /tmp/ibus-setup-build/setup.o /usr/local/static/ibus/lib/libibus-1.0.a \
    -Wl,--start-group -lXinerama -lXfixes -lXrandr -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 \
    -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
    -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz \
    -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 \
    -lglib-2.0 -lpcre -lgraphite2 -lffi -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount \
    -lblkid -lXcomposite -lcairo -lXdamage -Wl,--end-group \
    || { log "SETUP link FAILED"; exit 1; }
  file /usr/local/static/ibus/bin/ibus-setup | head -1
}

# ---- 方案 B panel（自定义 GTK2 候选窗，静态链）----
function panel(){
  log "Building ibus panel (custom GTK2, static)..."
  cd /tmp
  rm -rf /tmp/ibus-panel-build && mkdir -p /tmp/ibus-panel-build
  # CFLAGS: gtk2 + dbus 静态 + ibus 头（用安装产物 pkg-config，不依赖构建树）
  GCFLAGS="$(pkg-config --cflags gtk+-2.0) \
    $(PKG_CONFIG_PATH=/usr/local/static/ibus/lib/pkgconfig pkg-config --cflags ibus-1.0) \
    -I/usr/local/static/dbus/include/dbus-1.0 -I/usr/local/static/dbus/lib/dbus-1.0/include \
    -DDBUS_STATIC_BUILD -pthread"
  xx-clang -c /src/v-ibus/panel-gtk2-ibus-panel.c -o /tmp/ibus-panel-build/panel.o $GCFLAGS \
    || { log "PANEL compile FAILED"; exit 1; }
  # 链: libibus-1.0.a + u-gtk 静态库集（与 gtkibustest 同套路）
  xx-clang -static -Wl,--strip-all -o /usr/local/static/ibus/libexec/ibus-panel \
    /tmp/ibus-panel-build/panel.o /usr/local/static/ibus/lib/libibus-1.0.a \
    -Wl,--start-group -lXinerama -lXfixes -lXrandr -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 \
    -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig \
    -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz \
    -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 \
    -lglib-2.0 -lpcre -lgraphite2 -lffi -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount \
    -lblkid -lXcomposite -lcairo -lXdamage -Wl,--end-group \
    || { log "PANEL link FAILED"; exit 1; }
  file /usr/local/static/ibus/libexec/ibus-panel | head -1
}

# ---- ibus-rime 1.6.1（rime 引擎接入 ibus，静态链 librime+libibus）----
function ibus-rime(){
  log "Downloading ibus-rime 1.6.1..."
  if [ ! -d /tmp/ibus-rime-1.6.1 ]; then
    git clone --depth=1 --branch=1.6.1 $GITHUB/rime/ibus-rime /tmp/ibus-rime-1.6.1
  fi
  cd /tmp/ibus-rime-1.6.1

  # ---- 条件2: boost_signals 空桩（构建前注入）----
  # librime 1.9.0 用 boost::signals2（header-only，不需真实符号），Alpine 3.15 boost1.77
  # 无 libboost_signals.a；但 ibus-rime CMakeLists 原 RIME_DEPS 引用 libboost_signals.a →
  # 注入空桩归档，防链接时找不到该库/未定义。桩放 /tmp（不进源目录，避免 aux_source_directory 误编）。
  local STUBDIR=/tmp/ibus-rime-build
  rm -rf "$STUBDIR"; mkdir -p "$STUBDIR/lib"
  cat > "$STUBDIR/boost_signals_stub.c" <<'EOF'
/* boost_signals 空桩：Alpine 3.15 boost1.77 无此库（signals2 为 header-only）。
 * 哨兵符号仅保证归档非空可链；librime 不引用真实 boost::signals 符号。
 * 适用前提：仅当 librime 仍用 header-only signals2（无真实 boost::signals 依赖）时有效；
 * 若将来改用真实 boost::signals，此空桩会掩盖缺失符号导致运行时未定义行为，须移除或改真实库。 */
int rime_boost_signals_stub(void){ return 0; }
EOF
  xx-clang -c "$STUBDIR/boost_signals_stub.c" -o "$STUBDIR/boost_signals_stub.o" \
    || { log "BOOST_SIGNALS stub compile FAILED"; exit 1; }
  ar rcs "$STUBDIR/lib/libboost_signals.a" "$STUBDIR/boost_signals_stub.o" \
    || { log "BOOST_SIGNALS stub archive FAILED"; exit 1; }

  # ---- 条件4: glib 静态闭包 + 全 .a 绝对路径（与 x11()/panel() 同套路 start-group）----
  # ibus-rime CMakeLists 的 target_link_libraries 走 pkg-config -l 名（会解析到 .so），且
  # RIME_DEPS 引相对名 .a（link_directories 指向不存在的 lib/）→ 链接失败/漏闭包。用已验证的
  # 全 .a 绝对路径闭包替换该行，单处 --start-group 处理 boost/icu/glib 循环依赖（对应 §6.2/§6.3）。
  local STATIC_LIBS="\
/usr/local/static/ibus/lib/libibus-1.0.a \
/usr/local/static/deps/lib/librime.a \
$STUBDIR/lib/libboost_signals.a \
/usr/lib/libicuuc.a /usr/lib/libicui18n.a \
/usr/lib/libboost_filesystem.a /usr/lib/libboost_locale.a /usr/lib/libboost_regex.a \
/usr/lib/libboost_system.a /usr/lib/libboost_thread.a \
/usr/local/static/deps/lib/libglog.a /usr/local/static/deps/lib/libgflags.a \
/usr/local/static/deps/lib/libnotify.a /usr/local/static/deps/lib/libleveldb.a \
/usr/local/static/deps/lib/libmarisa.a /usr/local/static/deps/lib/libopencc.a \
/usr/local/static/deps/lib/libyaml-cpp.a \
/usr/lib/libglib-2.0.a /usr/lib/libgobject-2.0.a /usr/lib/libgio-2.0.a \
/usr/lib/libgdk_pixbuf-2.0.a /usr/lib/libintl.a \
/usr/lib/libgmodule-2.0.a /usr/lib/libpcre.a /lib/libz.a /usr/lib/libmount.a \
/usr/lib/libblkid.a /usr/lib/libffi.a \
-lm -lstdc++ -lpthread"
  if ! grep -q 'target_link_libraries(ibus-engine-rime.*--start-group' CMakeLists.txt; then
    sed -i "s|^target_link_libraries(ibus-engine-rime .*|target_link_libraries(ibus-engine-rime -Wl,--start-group ${STATIC_LIBS} -Wl,--end-group)|" CMakeLists.txt
    log "ibus-rime CMakeLists: target_link_libraries 替换为全 .a 静态闭包（--start-group）"
  fi

  log "CMake ibus-rime (static librime + libibus)..."
  mkdir -p build && cd build
  export PKG_CONFIG_PATH="/usr/local/static/ibus/lib/pkgconfig:/usr/local/static/deps/lib/pkgconfig:/usr/local/static/dbus/lib/pkgconfig"
  # 条件1: Rime_DIR 指向 librime 安装前缀 /usr/local/static/deps 下的 cmake 包目录（RimeConfig.cmake）
  # 条件3: ICU 强制 .a（禁用动态，指定静态 .a 路径）；-static 全静态链（§6.3 LINK_FLAGS）
  cmake -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local/static/ibus-rime \
    -DRIME_DATA_DIR=/usr/local/static/deps/share/rime-data \
    -DBUILD_STATIC=ON \
    -DRime_DIR=/usr/local/static/deps/share/cmake/rime \
    -DCMAKE_PREFIX_PATH=/usr/local/static/deps \
    -DICU_ROOT=/usr -DICU_INCLUDE_DIR=/usr/include \
    -DICU_UC_LIBRARY=/usr/lib/libicuuc.a \
    -DICU_I18N_LIBRARY=/usr/lib/libicui18n.a \
    -DICU_DATA_LIBRARY=/usr/lib/libicudata.a \
    -DCMAKE_EXE_LINKER_FLAGS="-static -static-libstdc++ -static-libgcc" \
    -DCMAKE_C_COMPILER=xx-clang -DCMAKE_CXX_COMPILER=xx-clang++ \
    ..
  make -j$(nproc)
  make install
  [ -f /usr/local/static/ibus-rime/libexec/ibus-rime/ibus-engine-rime ] || { log "ibus-engine-rime MISSING"; exit 1; }
  log "ibus-rime done: $(file /usr/local/static/ibus-rime/libexec/ibus-rime/ibus-engine-rime | head -1)"
}

case "$1" in
cache)
  # 离线源：host 预下载 ibus 源到 .ibus-deps -> 拷入容器 /src/v-ibus/
  ;;
full)
  deps
  librime
  ibus
  panel
  x11
  ibus-rime
  setup
  ;;
ibus)
  ibus
  ;;
panel)
  panel
  ;;
x11)
  x11
  ;;
setup)
  setup
  ;;
ibus-rime)
  ibus-rime
  ;;
b_deps)
  # 依赖盘点：dbus/dbus-glib/gtk2 静态库 + cmake/git 工具
  find /usr/lib /usr/local/static/dbus /usr/local/static/dbus-glib | egrep "libdbus|libgtk|libgdk|pango|libatk|libpixbuf|\.a$" | sort | head -40
  which cmake git xx-clang xx-clang++ pkg-config patch
  ;;
*) #compile
  oneBuild $1
  ;;
esac
exit 0
