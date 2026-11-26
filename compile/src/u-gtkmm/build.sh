#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-u-gtkmm}"

#
# Build gtkmm 栈 2.4（7 组件 + mm-common）静态，GTK2
#
# 供 pavucontrol / gnome-system-monitor 复用。产出安装到 /usr/lib（--prefix=/usr）。
# 组件: libsigc++-2.0(2.10.8) glibmm/giomm(2.48.1) cairomm(1.12.0) pangomm(2.40.0)
#       atkmm(2.24.2) gdkmm+gtkmm(2.24.5, gdkmm 在 gtkmm 树 gdk/)  (+ mm-common 0.9.12 宏)
#
# 4 个坑（详见 docs/2026/11051633-v-pavucontrol.md §3.3）:
#   1. glibmm threads.h GPrivate: glib 2.70 中 GPrivate 为结构体, gobj() 需 return &gobject_  (glibmm-gprivate.patch)
#   2. pangomm attrlist.cc 需 #include <pango/pango-markup.h> (pango 1.49 不再自动暴露)  (pangomm-pango-markup.patch)
#   3. u-gtk 的 pc 缺版本后缀(pango.pc 非 pango-1.0.pc) -> 建 8 个符号链接别名才能 pkg-config 解析
#   4. libtool install-exec 不装 .a -> make install 后手动 cp .libs/*.a 到 /usr/lib
#   + sigc++ 需 --disable-documentation (doxygen/xsltproc 缺失)
#   + pangomm 2.40 需 glibmm>=2.48.0 (弃 2.46.4, 用 2.48.1)
#
# 并行化（2026-11-12 落地，见 docs/2026/11091127-ci-builder-gtk.md 三章4节 4.2）:
#   组件函数化 + doExec 组调度（A-E 阶段，C/D 两路 &）。依赖图（菱形）：
#   mm-common → libsigc++ → { glibmm ∥ cairomm } → { pangomm ∥ atkmm } → gtkmm
#   4 个并行坑处理: fetch name 改 local / cd 子 shell 隔离 / doExec_check 逐 rc / 只 2 路(gtkmm 单独)。

# 源 tarball 优先离线复用 /tmp/gtkmm-stack/*.tar.xz，否则 download.gnome.org
GNOME=https://download.gnome.org/sources
fetch(){
  # local：两路并行 fetch 互不覆盖 name（否则全局变量会串）
  local name=$1
  if [ -f /tmp/gtkmm-stack/$name.tar.xz ]; then
    tar xJf /tmp/gtkmm-stack/$name.tar.xz -C $WS/gtkmm-src
  else
    down_catfile $GNOME/$2/$3/$name.tar.xz | tar -xJ -C $WS/gtkmm-src
  fi
}

# release tarball 有 configure; box 的 git-archive 无 -> 缺则 autogen.sh (autoreconf) 生成
# 交叉(2026-11-24): autogen 内部 bootstrap ./configure 须带 --host(否则试跑交叉产物失败),
#   autogen.sh 透传 $@ -> 追加 $CROSS_HOST; native(CROSS_HOST 空) 传空参会被 configure 当多余参数拒,
#   -> 有值才传(条件传参, native 与原 `./autogen.sh` 零差)。
mkcfg(){ [ -f ./configure ] || { echo "no configure -> autogen"; if [ -n "$CROSS_HOST" ]; then ./autogen.sh $CROSS_HOST; else ./autogen.sh; fi; }; }

# 2026-11-24 方案二交叉: gtkmm 栈共用交叉环境(libsigc++→gtkmm 全链)。
# 设置 CROSS_HOST/XX_DESTDIR 供各函数 configure 追加 --host、make install 加 DESTDIR(装 sysroot)。
# native(未设 TARGETPLATFORM): 变量留空 → 原路径零影响。
mm_cross(){
  CROSS_HOST=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export CXX=xx-clang++
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    log "mm: CROSS ($XX_TRIPLE)"
  fi
}

# buildx 隔离/多阶段继承(CI): 自编库(pango/gtk/atk)头可能不在 /usr/include 标准位
# (装 xx sysroot 或前一构建阶段隔离路径, 即使 amd64) -> pangomm/gtkmm 的 <pango/pango-markup.h>
# 等找不到; native(docker run) 头在标准位不触发。检测任一缺失则 find 定位补 CPPFLAGS。
prep_cppflags(){
  if [ ! -f /usr/include/pango-1.0/pango/pango-markup.h ] || [ ! -f /usr/include/gtk-2.0/gtk/gtk.h ]; then
    NEW=""
    for pat in "pango-1.0/pango/pango-markup.h" "atk-1.0/atk/atk.h" "gtk-2.0/gtk/gtk.h"; do
      [ -f "/usr/include/$pat" ] && continue
      F=$(find / -name "$(basename "$pat")" -path "*/$(dirname "$pat")" 2>/dev/null | head -1)
      [ -n "$F" ] && NEW="-I$(dirname "$(dirname "$F")") $NEW"
    done
    [ -n "$NEW" ] && export CPPFLAGS="$NEW $CPPFLAGS"
    log "自编库头不在 /usr/include 标准位, 补 CPPFLAGS: ${NEW:-<未找到>}"
  fi
}

# u-gtk 的 pc 缺版本后缀(pango.pc 非 pango-1.0.pc) -> 建 8 个符号链接别名才能 pkg-config 解析
pc_alias(){
  log "Prep: 建 u-gtk pc 符号链接别名 (8 个, pango/atk/gail 缺版本后缀)..."
  # pkg-config 需 pango-1.0.pc / pangocairo-1.0.pc / pangofc-1.0.pc / pangoft2-1.0.pc /
  #   pangoot-1.0.pc / pangoxft-1.0.pc / atk-1.0.pc / gail-1.0.pc (指向 u-gtk 的非版本化 .pc)
  for pair in "pango-1.0 pango" "pangocairo-1.0 pangocairo" "pangofc-1.0 pangofc" \
              "pangoft2-1.0 pangoft2" "pangoot-1.0 pangoot" "pangoxft-1.0 pangoxft" \
              "atk-1.0 atk" "gail-1.0 gail"; do
    set -- $pair; a=$1; b=$2
    [ -f /usr/lib/pkgconfig/$b.pc ] && [ ! -e /usr/lib/pkgconfig/$a.pc ] \
      && ln -s $b.pc /usr/lib/pkgconfig/$a.pc
  done
  ls -la /usr/lib/pkgconfig/ | grep "\->" | grep -E "pango|atk|gail"
}

# 每组件函数：独立子 shell（doExec 子 bash 重新 source common.sh 会重置 LDFLAGS），
# 故函数内重设 LDFLAGS（辅助工具须动态链）+ 每函数开头 set -e（doExec 子 shell 是 set +e）。
function c_mm_common(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  log "Build mm-common (0.9.12, 宏)..."
  fetch mm-common-0.9.12 mm-common 0.9
  cd $WS/gtkmm-src/mm-common-0.9.12
  ./configure --prefix=/usr; make -j${PARALLEL_JOBS:-$(nproc)}; make install
}

function c_libsigc(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build libsigc++-2.0 (2.10.8)..."
  fetch libsigc++-2.10.8 libsigc++ 2.10
  cd $WS/gtkmm-src/libsigc++-2.10.8
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  make -j${PARALLEL_JOBS:-$(nproc)}; make install ${XX_DESTDIR:-}
  # make install 已装 /usr/lib/libsigc-2.0.a(实测 libsigc++ 会装); 多余 cp 仅兜底, 路径因 tarball 布局而异(sigc++/.libs), 找不到不致命(|| true)
  cp .libs/libsigc-2.0.a ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || cp sigc++/.libs/libsigc-2.0.a ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || cp "$(find . -name libsigc-2.0.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/ 2>/dev/null || true
  xx_la_fix
}

function c_glibmm(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build glibmm/giomm (2.48.1)..."
  fetch glibmm-2.48.1 glibmm 2.48
  cd $WS/gtkmm-src/glibmm-2.48.1
  git apply /src/u-gtkmm/glibmm-gprivate.patch 2>/dev/null || patch -p1 < /src/u-gtkmm/glibmm-gprivate.patch 2>/dev/null || true
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  make -j${PARALLEL_JOBS:-$(nproc)}; make install ${XX_DESTDIR:-}
  [ -f ${XX_SYSROOT:-}/usr/lib/libglibmm-2.4.a ] || cp "$(find . -name libglibmm-2.4.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  [ -f ${XX_SYSROOT:-}/usr/lib/libgiomm-2.4.a ] || cp "$(find . -name libgiomm-2.4.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  xx_la_fix
}

function c_cairomm(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build cairomm-1.0 (1.12.0)..."
  fetch cairomm-1.12.0 cairomm 1.12
  cd $WS/gtkmm-src/cairomm-1.12.0
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  make -j${PARALLEL_JOBS:-$(nproc)}; make install ${XX_DESTDIR:-}
  [ -f ${XX_SYSROOT:-}/usr/lib/libcairomm-1.0.a ] || cp "$(find . -name libcairomm-1.0.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  xx_la_fix
}

function c_pangomm(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build pangomm-1.4 (2.40.0)..."
  fetch pangomm-2.40.0 pangomm 2.40
  cd $WS/gtkmm-src/pangomm-2.40.0
  git apply /src/u-gtkmm/pangomm-pango-markup.patch 2>/dev/null || patch -p1 < /src/u-gtkmm/pangomm-pango-markup.patch 2>/dev/null || true
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  make -j${PARALLEL_JOBS:-$(nproc)}; make install ${XX_DESTDIR:-}
  [ -f ${XX_SYSROOT:-}/usr/lib/libpangomm-1.4.a ] || cp "$(find . -name libpangomm-1.4.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  xx_la_fix
}

function c_atkmm(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build atkmm-1.6 (2.24.2)..."
  fetch atkmm-2.24.2 atkmm 2.24
  cd $WS/gtkmm-src/atkmm-2.24.2
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  make -j${PARALLEL_JOBS:-$(nproc)}; make install ${XX_DESTDIR:-}
  [ -f ${XX_SYSROOT:-}/usr/lib/libatkmm-1.6.a ] || cp "$(find . -name libatkmm-1.6.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  xx_la_fix
}

function c_gtkmm(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Build gtkmm-2.4/gdkmm-2.4 (2.24.5)..."
  fetch gtkmm-2.24.5 gtkmm 2.24
  cd $WS/gtkmm-src/gtkmm-2.24.5
  mkcfg
  ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr $CROSS_HOST
  # 2026-11-15: 方案 A(u-gtk 库层 png/jpeg/svg loader 编入 libgdk_pixbuf-2.0.a)后,
  #   gdkmm 构建期工具 tools/extra_defs_gen/generate_extra_defs 链接 $(GTKMM_LIBS)
  #   (configure 取 pkg-config 非 static, 不展开 Requires.private → 缺 loader 依赖)
  #   → 链 libgdk_pixbuf-2.0.a 时 io-png/io-jpeg/io-svg 整链拉入
  #   → undefined png_read_end/jpeg_*/rsvg_* (CI gtkmm224 buildx 实测, 报 png_read_end@@PNG16_0)。
  #   make 覆盖 GTKMM_LIBS: 保留 configure 同款模块集(非 static), 追加 loader 依赖
  #   (-lpng16/-ljpeg/-lrsvg-2 等, 顺序在 -lgdk_pixbuf-2.0 之后, 提供方在后)
  #   → generate_extra_defs 链接齐依赖; 同时 libgtkmm-2.4.la dependency_libs 也带(下游 gtk2 应用有益)。
  #   注: 不用整包 pkg-config --static(会展开出无 .a 的库如 cups/Xi → cannot find -l)。
  #   2026-11-16: -ljpeg 改绝对路径 /usr/lib/libjpeg.a——generate_extra_defs 是动态链模式(LDFLAGS 无 -static),
  #     ld -ljpeg 优先 libjpeg.so(带版本符号 @@LIBJPEG_8.0), CI 实测 io-jpeg.c.o undefined jpeg_input_complete@@LIBJPEG_8.0;
  #     .a 无版本符号天然规避(本地 libtool -v 模拟 RC=0; 后面 librsvg.la 展开的 -ljpeg 会被 --as-needed 丢弃)。
  local GTKMM_LIBS_BASE="$(pkg-config --libs atkmm-1.6 giomm-2.4 pangomm-1.4 gtk+-2.0 gtk+-unix-print-2.0)"
  local GTKMM_LIBS_EXTRA="-lpng16 ${XX_SYSROOT:-}/usr/lib/libjpeg.a -lz -llzma -lzstd -lgmodule-2.0 -L${XX_SYSROOT:-}/usr/local/lib -lrsvg-2 -lcroco-0.6 -lxml2"
  make -j${PARALLEL_JOBS:-$(nproc)} GTKMM_LIBS="$GTKMM_LIBS_BASE $GTKMM_LIBS_EXTRA"
  make install GTKMM_LIBS="$GTKMM_LIBS_BASE $GTKMM_LIBS_EXTRA" ${XX_DESTDIR:-}
  [ -f ${XX_SYSROOT:-}/usr/lib/libgtkmm-2.4.a ] || cp "$(find . -name libgtkmm-2.4.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  [ -f ${XX_SYSROOT:-}/usr/lib/libgdkmm-2.4.a ] || cp "$(find . -name libgdkmm-2.4.a 2>/dev/null | head -1)" ${XX_SYSROOT:-}/usr/lib/
  xx_la_fix
}

function c_verify(){
  set -e; export LDFLAGS="-Wl,--as-needed"
  mm_cross
  log "Verify gtkmm stack..."
  local D=${XX_SYSROOT:-}/usr/lib
  ls -lh $D/libsigc-2.0.a $D/libglibmm-2.4.a $D/libgiomm-2.4.a \
    $D/libcairomm-1.0.a $D/libpangomm-1.4.a $D/libatkmm-1.6.a \
    $D/libgdkmm-2.4.a $D/libgtkmm-2.4.a
  pkg-config --exists gtkmm-2.4 && echo "pkg-config gtkmm-2.4 OK: $(pkg-config --modversion gtkmm-2.4)"
}

function gtkmm(){
  # 调路口 doExec 子 shell 会 set +e(保命令继续+rcfile 捕获), 此处重启用 set -e 保函数内失败即终止(否则失败被吞, 最终 rc 误报 0)。
  set -e
  # common.sh 的 LDFLAGS="-static" 会让构建辅助工具(如 glibmm 的 generate_defs_glib)静态链接失败
  # -> gtkmm 库的 .a 由 --enable-static --disable-shared 控制, 不需要 -static LDFLAGS; 辅助工具须动态链
  export LDFLAGS="-Wl,--as-needed"

  prep_cppflags
  pc_alias

  log "Prep: gtkmm 源目录..."
    rm -rf $WS/gtkmm-src; mkdir -p $WS/gtkmm-src

  # 并行化调度（A-E 阶段，依赖尊重，最多 2 路）：
  #   A/B 串行（轻量小件）→ C 两路（glibmm∥cairomm）→ D 两路（pangomm∥atkmm）→ E gtkmm（最重，单独）
  # 错误传播：doExec 捕获真实 rc 到 _exec_result.txt，doExec_mark 写组边界，wait 后 doExec_check 只读本组。
  # 并行收益取决于核数：nproc>=4 才并行（2 路各 -j(nproc/2)，总 nproc 线程不超载）；
  #   nproc<4（如 2 核）并行无收益甚至更慢（每组件分得核数减半），自动退串行。
  #   FORCE_PARALLEL=1 可强制并行（验证调度逻辑用）。
  local NPROC=$(nproc)
  local DO_PAR=0
  [ "$NPROC" -ge 4 ] && DO_PAR=1
  [ "${FORCE_PARALLEL:-0}" = "1" ] && DO_PAR=1
  export PARALLEL_JOBS=$NPROC
  if [ "$DO_PAR" = 1 ]; then
    export PARALLEL_JOBS=$(( NPROC / 2 ))   # 2 路各半线程，总 NPROC 不超载
    log "Schedule: A/B (mm-common libsigc++)..."
    c_mm_common
    c_libsigc
    log "Schedule: C 两路 (glibmm ∥ cairomm)..."
    doExec_mark "C: glibmm cairomm"
    doExec /src/u-gtkmm/build.sh glibmm &
    doExec /src/u-gtkmm/build.sh cairomm &
    wait
    doExec_check || exit 1
    log "Schedule: D 两路 (pangomm ∥ atkmm)..."
    doExec_mark "D: pangomm atkmm"
    doExec /src/u-gtkmm/build.sh pangomm &
    doExec /src/u-gtkmm/build.sh atkmm &
    wait
    doExec_check || exit 1
    log "Schedule: E (gtkmm)..."
    export PARALLEL_JOBS=$NPROC   # E 最重单独，恢复全核
    c_gtkmm
    c_verify
  else
    log "Schedule: 串行 (nproc=$NPROC < 4, 并行无收益)..."
    c_mm_common; c_libsigc; c_glibmm; c_cairomm; c_pangomm; c_atkmm; c_gtkmm; c_verify
  fi
}

case "$1" in
cache)
    # down_catfile $GNOME/gtkmm/2.24/gtkmm-2.24.5.tar.xz > /dev/null
    ;;
mm_common) c_mm_common;;
libsigc)  c_libsigc;;
glibmm)   c_glibmm;;
cairomm)  c_cairomm;;
pangomm)  c_pangomm;;
atkmm)    c_atkmm;;
gtkmm_comp) c_gtkmm;;
verify)   c_verify;;
full)
    doExec gtkmm   # 调路口 doExec 包装整个 gtkmm() 方法块(全量落日志+白名单回显+错误码); 函数内 set -e 保失败终止
    ;;
b_deps)
    # GTK2 静态库(u-gtk)已在 base; 此栈额外需: 源码 tarball 可在 /tmp/gtkmm-stack 或走 down_catfile
    echo "base GTK2:"; ls /usr/lib/libgtk-x11-2.0.a 2>&1
    echo "u-gtk pc (非版本化, 需别名):"; ls /usr/lib/pkgconfig/pango.pc /usr/lib/pkgconfig/atk.pc 2>&1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
