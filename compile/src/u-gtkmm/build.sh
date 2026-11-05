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

# 源 tarball 优先离线复用 /tmp/gtkmm-stack/*.tar.xz，否则 download.gnome.org
GNOME=https://download.gnome.org/sources
fetch(){
  name=$1
  if [ -f /tmp/gtkmm-stack/$name.tar.xz ]; then
    tar xJf /tmp/gtkmm-stack/$name.tar.xz -C /tmp/gtkmm-src
  else
    down_catfile $GNOME/$2/$3/$name.tar.xz | tar -xJ -C /tmp/gtkmm-src
  fi
}

function gtkmm(){
  # 调路口 doExec 子 shell 会 set +e(保命令继续+rcfile 捕获), 此处重启用 set -e 保函数内失败即终止(否则失败被吞, 最终 rc 误报 0)。
  set -e
  # common.sh 的 LDFLAGS="-static" 会让构建辅助工具(如 glibmm 的 generate_defs_glib)静态链接失败
  # -> gtkmm 库的 .a 由 --enable-static --disable-shared 控制, 不需要 -static LDFLAGS; 辅助工具须动态链
  export LDFLAGS="-Wl,--as-needed"
  # release tarball 有 configure; box 的 git-archive 无 -> 缺则 autogen.sh (autoreconf) 生成
  mkcfg(){ [ -f ./configure ] || { echo "no configure -> autogen"; ./autogen.sh; }; }

  # buildx 隔离/多阶段继承(CI): 自编库(pango/gtk/atk)头可能不在 /usr/include 标准位
  # (装 xx sysroot 或前一构建阶段隔离路径, 即使 amd64) -> pangomm/gtkmm 的 <pango/pango-markup.h>
  # 等找不到; native(docker run) 头在标准位不触发。检测任一缺失则 find 定位补 CPPFLAGS。
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

  log "Prep: gtkmm 源目录..."
    rm -rf /tmp/gtkmm-src; mkdir -p /tmp/gtkmm-src

  log "Build mm-common (0.9.12, 宏)..."
    fetch mm-common-0.9.12 mm-common 0.9
    cd /tmp/gtkmm-src/mm-common-0.9.12
    ./configure --prefix=/usr; make -j$(nproc); make install

  log "Build libsigc++-2.0 (2.10.8)..."
    fetch libsigc++-2.10.8 libsigc++ 2.10
    cd /tmp/gtkmm-src/libsigc++-2.10.8
    mkcfg
    ./configure --enable-static --disable-shared --disable-documentation --prefix=/usr
    make -j$(nproc); make install
    # make install 已装 /usr/lib/libsigc-2.0.a(实测 libsigc++ 会装); 多余 cp 仅兜底, 路径因 tarball 布局而异(sigc++/.libs), 找不到不致命(|| true)
    cp .libs/libsigc-2.0.a /usr/lib/ 2>/dev/null || cp sigc++/.libs/libsigc-2.0.a /usr/lib/ 2>/dev/null || cp "$(find . -name libsigc-2.0.a 2>/dev/null | head -1)" /usr/lib/ 2>/dev/null || true

  log "Build glibmm/giomm (2.48.1)..."
    fetch glibmm-2.48.1 glibmm 2.48
    cd /tmp/gtkmm-src/glibmm-2.48.1
    git apply /src/u-gtkmm/glibmm-gprivate.patch 2>/dev/null || patch -p1 < /src/u-gtkmm/glibmm-gprivate.patch 2>/dev/null || true
    mkcfg
    ./configure --enable-static --disable-shared --prefix=/usr
    make -j$(nproc); make install
    [ -f /usr/lib/libglibmm-2.4.a ] || cp "$(find . -name libglibmm-2.4.a 2>/dev/null | head -1)" /usr/lib/
    [ -f /usr/lib/libgiomm-2.4.a ] || cp "$(find . -name libgiomm-2.4.a 2>/dev/null | head -1)" /usr/lib/

  log "Build cairomm-1.0 (1.12.0)..."
    fetch cairomm-1.12.0 cairomm 1.12
    cd /tmp/gtkmm-src/cairomm-1.12.0
    mkcfg
    ./configure --enable-static --disable-shared --prefix=/usr
    make -j$(nproc); make install
    [ -f /usr/lib/libcairomm-1.0.a ] || cp "$(find . -name libcairomm-1.0.a 2>/dev/null | head -1)" /usr/lib/

  log "Build pangomm-1.4 (2.40.0)..."
    fetch pangomm-2.40.0 pangomm 2.40
    cd /tmp/gtkmm-src/pangomm-2.40.0
    git apply /src/u-gtkmm/pangomm-pango-markup.patch 2>/dev/null || patch -p1 < /src/u-gtkmm/pangomm-pango-markup.patch 2>/dev/null || true
    mkcfg
    ./configure --enable-static --disable-shared --prefix=/usr
    make -j$(nproc); make install
    [ -f /usr/lib/libpangomm-1.4.a ] || cp "$(find . -name libpangomm-1.4.a 2>/dev/null | head -1)" /usr/lib/

  log "Build atkmm-1.6 (2.24.2)..."
    fetch atkmm-2.24.2 atkmm 2.24
    cd /tmp/gtkmm-src/atkmm-2.24.2
    mkcfg
    ./configure --enable-static --disable-shared --prefix=/usr
    make -j$(nproc); make install
    [ -f /usr/lib/libatkmm-1.6.a ] || cp "$(find . -name libatkmm-1.6.a 2>/dev/null | head -1)" /usr/lib/

  log "Build gtkmm-2.4/gdkmm-2.4 (2.24.5)..."
    fetch gtkmm-2.24.5 gtkmm 2.24
    cd /tmp/gtkmm-src/gtkmm-2.24.5
    mkcfg
    ./configure --enable-static --disable-shared --prefix=/usr
    make -j$(nproc); make install
    [ -f /usr/lib/libgtkmm-2.4.a ] || cp "$(find . -name libgtkmm-2.4.a 2>/dev/null | head -1)" /usr/lib/
    [ -f /usr/lib/libgdkmm-2.4.a ] || cp "$(find . -name libgdkmm-2.4.a 2>/dev/null | head -1)" /usr/lib/

  log "Verify gtkmm stack..."
    ls -lh /usr/lib/libsigc-2.0.a /usr/lib/libglibmm-2.4.a /usr/lib/libgiomm-2.4.a \
      /usr/lib/libcairomm-1.0.a /usr/lib/libpangomm-1.4.a /usr/lib/libatkmm-1.6.a \
      /usr/lib/libgdkmm-2.4.a /usr/lib/libgtkmm-2.4.a
    pkg-config --exists gtkmm-2.4 && echo "pkg-config gtkmm-2.4 OK: $(pkg-config --modversion gtkmm-2.4)"
}

case "$1" in
cache)
    # down_catfile $GNOME/gtkmm/2.24/gtkmm-2.24.5.tar.xz > /dev/null
    ;;
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
