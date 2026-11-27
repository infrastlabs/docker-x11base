#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-rofi}"
source /src/common.sh

#
# Build rofi (应用启动器/dmenu 替代, 2.1.1, xcb+cairo+pango 渲染, 无 GTK)
#
# 版本: 2.1.1 (bugfix 版, nkutils 更新/DMenu 行显示修复#2352), meson-only (弃 autotools), xcb 后端
#   上游: https://github.com/davatorium/rofi (tag 2.1.1)
# 依赖(xcb 后端, meson.build xcb_deps): glib-2.0(>=2.72)/gmodule-2.0/gio-unix-2.0,
#   cairo/cairo-xcb, pango/pangocairo, gdk-pixbuf-2.0, xkbcommon/xkbcommon-x11,
#   xcb, xcb-aux(xcb-util), xcb-ewmh/xcb-icccm(xcb-util-wm), xcb-randr, xcb-cursor,
#   xcb-xinerama, xcb-keysyms, libstartup-notification-1.0
#   (子项目 libgwater/libnkutils 为 git 子模块, github tarball 不含 -> 需单独取)
# 需补建(纯 C 静态, 装 /usr/local/lib): xcb-util 家族 + startup-notification + xcb-imdkit
#   顺序: util -> image -> renderutil -> wm(icccm+ewmh)/keysyms/xrm -> cursor
#   (cursor 依赖 image/renderutil/util 的 .pc, 故最后)
# 输入法: 2.1.1 与 2.0.0 同机制——imdkit (xcb-imdkit, XIM); 2026-11-23 开 imdkit=true,
#   需自建 fcitx/xcb-imdkit 1.0.9 静态库(Alpine 3.15 无包), 见 b_deps build_xcb_imdkit。
# 复用说明(2026-11-07 用户质疑「是否都重新拉源码编译」调查):
#   - apk 无 xcb-util 系列 .a(仅 libxcb-static 本体; xcb-util*-dev 只头/.so) → 无法 apk 复用
#   - w-tint2/build.sh 已有 xcbutil() 构建 xcb-util 本体(libxcb-util.a, gitee fk-xcb__util)
#     → xcb-util 本体真正复用 w-tint2(rofi 不再保留本包源码 URL); 已存在则直接用不重编
#   - 其余 image/renderutil/wm/keysyms/xrm/cursor/startup-notification 无现成脚本/apk 复用 → 必须源码编译
#     (但 build_dep 的「存在则跳过」会复用上次已建的 .a, 不重复重编)
# 静态链要点:
#   - meson 默认把 libs 包进 -Wl,--start-group/--end-group (解循环/顺序)
#   - pkg-config --static 包装器 (PKG_CONFIG=...) 让 meson 拿到 Libs.private 全链
#   - c_link_args 带 -static 强制只用 .a (忽略同路径 .so)
# 注意(容器内实测): rofi 2.0.0/2.1.1 meson 要求 glib>=2.72, 而本容器(Alpine 3.15)
#   glib 为 2.70.5 且 apk 无网络升级 -> sed 降 glib_min_minor 至 70 (见 rofi())。
export TARGETPATH=${TARGETPATH:-/usr/local/static/rofi}

# 2026-11-25 方案二交叉: rofi 交叉环境初始化(同 pasystray ps_cross / tint2 toolchain 交叉模式)。
# native(XX_CROSS_FILE 空): 各 XX_*/CROSS_* 变量留空 -> 原路径零影响。
rofi_cross(){
  XX_LIBDIR=/usr/local/lib                        # 依赖 .a 落点(库)
  XX_INCDIR=/usr/local/include                    # 依赖头落点
  XX_DESTDIR=""                                   # make install 前缀(空=native 原路径)
  CROSS_HOST=""                                   # autotools --host(空=native)
  XX_TC=""                                        # cmake toolchain 参数(空=native)
  XX_ECM_ARG=""                                   # cmake ECM_DIR(空=native; 交叉需指宿主 ECM)
  XX_CROSS_ARGS=""                                # meson --cross-file(空=native)
  XX_LINK_LIBDIR="-L/usr/local/lib"               # c_link_args 的 -L
  XX_LIBDIRS="/usr/local/lib /usr/lib /lib"       # pkgconfig-static 包装器 .a 查找目录
  XX_EXTRA_LIBS="/usr/lib/libX11-xcb.a /usr/local/lib/librsvg-2.a /usr/local/lib/libcroco-0.6.a /usr/lib/libxml2.a"
  if [ -n "$XX_CROSS_FILE" ]; then
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    XX_LIBDIR="$XX_SYSROOT/usr/local/lib"
    XX_INCDIR="$XX_SYSROOT/usr/local/include"
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    CROSS_HOST="--host=$(xx-info triple)"
    XX_LINK_LIBDIR="-L$XX_SYSROOT/usr/local/lib"
    # 交叉: cmake toolchain MODE_PACKAGE=ONLY 会挡宿主 ECM(在 /usr/share/ECM) -> 显式指 ECM_DIR(ECM 仅配置期宏, 不交叉)。
    XX_ECM_ARG="-DECM_DIR=/usr/share/ECM/cmake"
    XX_LIBDIRS="$XX_SYSROOT/usr/local/lib $XX_SYSROOT/usr/lib $XX_SYSROOT/lib"
    XX_EXTRA_LIBS="$XX_SYSROOT/usr/lib/libX11-xcb.a $XX_SYSROOT/usr/local/lib/librsvg-2.a $XX_SYSROOT/usr/local/lib/libcroco-0.6.a $XX_SYSROOT/usr/lib/libxml2.a"
    # autotools cross configure run-test 缓存(mmap/realloc/malloc 不能 run)
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    log "rofi: CROSS ($XX_TRIPLE)"
  fi
}

# 离线 tarball 兜底(/tmp 已有则跳过) + 多源回退
get_src(){
  local tarball=$1; shift
  if test -s /tmp/$tarball; then
    log "offline cache /tmp/$tarball"
    return 0
  fi
  # 2026-11-15: tarsrc 缓存优先(离线/CI 免网络抖动; x-rofi 组件目录内源包)
  if test -s /src/../tarsrc/x-rofi/$tarball; then
    cp -f /src/../tarsrc/x-rofi/$tarball /tmp/$tarball
    log "tarsrc cache $tarball"
    return 0
  fi
  for u in "$@"; do
    log "downloading $tarball from $u ..."
    if curl -sSL --connect-timeout 20 -o /tmp/$tarball "$u"; then
      log "downloaded $tarball"
      return 0
    fi
  done
  log "download FAILED: $tarball"
  return 1
}

# 构建一个 autotools 静态 .a 库到 /usr/local
# build_dep <tarball> <srcdir> <libs(:分隔, 逐个验证)> <url...>
build_dep(){
  local tarball=$1 srcdir=$2 libs=$3; shift 3
  # 复用: 目标 .a 已在 /usr/local/lib(如 w-tint2 已建 xcb-util 本体/上次已建)则跳过源码编译
  local all_exist=1
  for l in $(echo "$libs" | tr ':' ' '); do
    test -s $XX_LIBDIR/$l || { all_exist=0; break; }
  done
  if test "$all_exist" = "1"; then log "reuse existing $libs (skip build)"; return 0; fi
  get_src "$tarball" "$@" || return 1
  log "Building $libs (from $tarball) ..."
  rm -rf $SRCROOT/build-$srcdir
  mkdir -p $SRCROOT/build-$srcdir
  tar xzf /tmp/$tarball -C $SRCROOT/build-$srcdir --strip-components=1
  cd $SRCROOT/build-$srcdir
  # 2026-11-27 修复: 老 config.sub 不认 *-alpine-linux-musl (startup-notification-0.12 arm64 挂) → 交叉换 automake 1.16 新版。
  # 新版向后兼容; native 无需替换. 作用于本函数所有依赖, 安全。
  if [ -n "$XX_CROSS_FILE" ]; then
    for f in config.sub config.guess; do
      test -f /usr/share/automake-1.16/$f && cp -f /usr/share/automake-1.16/$f ./$f
    done
  fi
  test -x ./configure || { autoreconf -fi 2>&1 || { log "autoreconf FAILED: $srcdir"; return 1; }; }
  # 2026-11-25 交叉: --host + DESTDIR 落 sysroot; native CROSS_HOST/XX_DESTDIR 空零影响.
  ./configure --enable-static --disable-shared --prefix=/usr/local $CROSS_HOST 2>&1 \
    || { log "configure FAILED: $srcdir"; return 1; }
  # 测试程序链接缺 xcb 的传递静态依赖(Xau/Xdmcp) -> 经 LIBS 补齐(静态链模式)
  make -j$(nproc) LIBS="-lXau -lXdmcp" 2>&1 || { log "make FAILED: $srcdir"; return 1; }
  # 2026-11-25 交叉: $XX_DESTDIR 作命令前缀不生效(POSIX 变量展开不算赋值) -> if 分支直接 DESTDIR(同 w-tint2 xcbutil)。
  if [ -n "$XX_CROSS_FILE" ]; then
    make install DESTDIR=$XX_SYSROOT 2>&1 || { log "install FAILED: $srcdir"; return 1; }
  else
    make install 2>&1 || { log "install FAILED: $srcdir"; return 1; }
  fi
  xx_la_fix   # 交叉 .la libdir 修正(仅 is-cross; native 零影响)
  for l in $(echo "$libs" | tr ':' ' '); do
    test -s $XX_LIBDIR/$l || { log "MISSING $XX_LIBDIR/$l"; return 1; }
  done
  log "OK: $libs"
}

# 2026-11-25 交叉: xkbcommon(dev+static) 从 Alpine armv7 仓库解包到 sysroot。
# rofi meson 需 dependency('xkbcommon') + dependency('xkbcommon-x11')(头/.pc/.a 在 dev/static 包内)。
# native 走 b_deps 的 apk add(不经此), 故本函数仅 is-cross 调用。
build_xkbcommon_cross(){
  local S="${XX_SYSROOT%/}"
  # 复用: sysroot 已有则跳过
  if test -s "$S/usr/lib/libxkbcommon.a" && test -s "$S/usr/lib/pkgconfig/xkbcommon-x11.pc"; then
    log "reuse existing xkbcommon (cross, skip)"; return 0
  fi
  local BASE="https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.15/main/$XX_MARCH"
  log "xkbcommon cross: fetch dev+static from $BASE"
  curl -sSL --connect-timeout 20 -o $SRCROOT/xx-xkbcommon-APKINDEX.tar.gz "$BASE/APKINDEX.tar.gz" \
    || { log "xkbcommon: APKINDEX dl fail"; return 1; }
  tar xzf $SRCROOT/xx-xkbcommon-APKINDEX.tar.gz -O APKINDEX > $SRCROOT/xx-xkbcommon-APKINDEX 2>/dev/null \
    || { log "xkbcommon: APKINDEX extract fail"; return 1; }
  for p in libxkbcommon-dev libxkbcommon-static; do
    local V=$(grep -A1 "^P:$p$" $SRCROOT/xx-xkbcommon-APKINDEX 2>/dev/null | grep "^V:" | head -1 | sed 's/^V://')
    test -n "$V" || { log "xkbcommon: $p version not found"; return 1; }
    local apkf=$SRCROOT/xx-$p-$V.apk
    curl -sSL --connect-timeout 20 -o "$apkf" "$BASE/$p-$V.apk" || { log "xkbcommon: $p dl fail"; return 1; }
    tar xzf "$apkf" -C "$S" 2>/dev/null || { log "xkbcommon: $p extract fail"; return 1; }
  done
  test -s "$S/usr/lib/libxkbcommon.a" || { log "xkbcommon: libxkbcommon.a missing"; return 1; }
  test -s "$S/usr/lib/pkgconfig/xkbcommon-x11.pc" || { log "xkbcommon: xkbcommon-x11.pc missing"; return 1; }
  log "xkbcommon cross OK"
}

# 补建 xcb-util 家族 8 个 + startup-notification (全部纯 C autotools)
b_deps(){
  rofi_cross   # 交叉环境(XX_* 变量); native 全空零影响
  # 2026-11-25 交叉: xkbcommon 走 Alpine armv7 仓库解包到 sysroot; native 保持 apk add 原路径。
  if [ -n "$XX_CROSS_FILE" ]; then
    build_xkbcommon_cross || { log "b_deps FAILED: xkbcommon (cross)"; exit 1; }
  else
    # 临时补装(2026-11-27 19:50): native 缺 libxkbcommon → libnkutils disabler → meson 静默丢 rofi 目标(四章2.2)。
    #   根因=方案B 公共库 native/cross 差异: u-gtk native apkdeps 未装 libxkbcommon(仅 cross xx-apk 装)。
    #   TEMP(专题): 公共库 native/cross 对称处理后再移除本补装, 恢复 ": # 公共库统一装" 原逻辑。
    apk add --no-cache libxkbcommon-dev libxkbcommon-static
  fi
  # xcb-util 核心 (提供 xcb-util.pc / xcb-aux.pc / xcb-atom.pc / xcb-event.pc)
  # 真正复用: 不再保留本包源码 URL, 统一用 w-tint2 的 xcbutil()(gitee fk-xcb__util)构建;
  # 若 $XX_LIBDIR/libxcb-util.a 已存在则直接用(不重编), 否则调 w-tint2(xcbutil 自身交叉感知)。
  if ! test -s $XX_LIBDIR/libxcb-util.a; then
    log "xcb-util missing, build via w-tint2 xcbutil..."
    doExec bash /src/w-tint2/build.sh xcbutil || { log "b_deps FAILED: xcb-util (w-tint2 xcbutil)"; exit 1; }
  fi
  test -s $XX_LIBDIR/libxcb-util.a || { log "b_deps FAILED: libxcb-util.a missing"; exit 1; }
  # xcb-util-image (依赖 xcb-util, 提供 xcb-image.pc)
  doExec build_dep xcb-util-image-0.4.1.tar.gz xcb-util-image-0.4.1 libxcb-image.a \
    https://xorg.freedesktop.org/archive/individual/lib/xcb-util-image-0.4.1.tar.gz \
    || { log "b_deps FAILED: xcb-util-image"; exit 1; }
  # xcb-util-renderutil (提供 xcb-renderutil.pc)
  doExec build_dep xcb-util-renderutil-0.3.10.tar.gz xcb-util-renderutil-0.3.10 libxcb-render-util.a \
    https://xorg.freedesktop.org/archive/individual/lib/xcb-util-renderutil-0.3.10.tar.gz \
    || { log "b_deps FAILED: xcb-util-renderutil"; exit 1; }
  # xcb-util-wm (一个包出 icccm+ewmh 两个库, 提供 xcb-icccm.pc / xcb-ewmh.pc)
  doExec build_dep xcb-util-wm-0.4.2.tar.gz xcb-util-wm-0.4.2 libxcb-icccm.a:libxcb-ewmh.a \
    https://xorg.freedesktop.org/archive/individual/lib/xcb-util-wm-0.4.2.tar.gz \
    || { log "b_deps FAILED: xcb-util-wm"; exit 1; }
  # xcb-util-keysyms (提供 xcb-keysyms.pc)
  doExec build_dep xcb-util-keysyms-0.4.1.tar.gz xcb-util-keysyms-0.4.1 libxcb-keysyms.a \
    https://xorg.freedesktop.org/archive/individual/lib/xcb-util-keysyms-0.4.1.tar.gz \
    || { log "b_deps FAILED: xcb-util-keysyms"; exit 1; }
  # xcb-util-xrm (Airblader 维护, 提供 xcb-xrm.pc)
  doExec build_dep xcb-util-xrm-1.0.tar.gz xcb-util-xrm-1.0 libxcb-xrm.a \
    https://github.com/Airblader/xcb-util-xrm/releases/download/v1.0/xcb-util-xrm-1.0.tar.gz \
    || { log "b_deps FAILED: xcb-util-xrm"; exit 1; }
  # xcb-util-cursor (依赖 image/renderutil/util 的 .pc, 最后建; 提供 xcb-cursor.pc)
  doExec build_dep xcb-util-cursor-0.1.6.tar.gz xcb-util-cursor-0.1.6 libxcb-cursor.a \
    https://xorg.freedesktop.org/archive/individual/lib/xcb-util-cursor-0.1.6.tar.gz \
    || { log "b_deps FAILED: xcb-util-cursor"; exit 1; }
  # startup-notification (提供 libstartup-notification-1.0.pc)
  doExec build_dep startup-notification-0.12.tar.gz startup-notification-0.12 libstartup-notification-1.a \
    https://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz \
    || { log "b_deps FAILED: startup-notification"; exit 1; }
  # xcb-imdkit (rofi xim 输入法, fcitx; CMake + ECM 构建, 生成 xcb-imdkit.pc 供 rofi meson 用)
  # 2026-11-23: Alpine 3.15 无 xcb-imdkit 包 -> 自建静态 .a; 依赖 xcb + xcb-util + KEYSYMS(已有)。
  #   需 ECM(extra-cmake-modules) + 内置 uthash(USE_SYSTEM_UTHASH=Off; Alpine uthash 包是空包)。
  doExec build_xcb_imdkit || { log "b_deps FAILED: xcb-imdkit"; exit 1; }
  log "b_deps all OK"
}

# 构建 xcb-imdkit (CMake 静态 .a + xcb-imdkit.pc -> /usr/local)
build_xcb_imdkit(){
  # 复用: 已建则跳过(交叉: 查 sysroot)
  if test -s $XX_LIBDIR/libxcb-imdkit.a && test -s $XX_LIBDIR/pkgconfig/xcb-imdkit.pc; then
    log "reuse existing xcb-imdkit (skip build)"; return 0
  fi
  # ECM (Extra CMake Modules, find_package(ECM)必需)
  command -v cmake >/dev/null 2>&1 || { log "cmake missing"; return 1; }
  test -f /usr/share/ECM/cmake/ECMConfig.cmake || apk add --no-cache extra-cmake-modules >/dev/null 2>&1 || true
  test -f /usr/share/ECM/cmake/ECMConfig.cmake || { log "ECM missing (extra-cmake-modules)"; return 1; }
  get_src xcb-imdkit-1.0.9.tar.gz \
    https://github.com/fcitx/xcb-imdkit/archive/refs/tags/1.0.9.tar.gz || return 1
  log "Building xcb-imdkit 1.0.9 ..."
  rm -rf $SRCROOT/build-xcb-imdkit
  mkdir -p $SRCROOT/build-xcb-imdkit
  tar xzf $SRCROOT/xcb-imdkit-1.0.9.tar.gz -C $SRCROOT/build-xcb-imdkit --strip-components=1
  cd $SRCROOT/build-xcb-imdkit
  rm -rf build && mkdir build && cd build
  # 静态构建: 源码 add_library(xcb-imdkit SHARED ...) 硬编码 SHARED, BUILD_SHARED_LIBS=OFF 无效
  #   -> sed 改 STATIC(在源码 src/CMakeLists.txt); USE_SYSTEM_UTHASH=Off 用内置 uthash/
  #   注意: 必须先 rm -rf build 清 CMakeCache, 否则旧 SHARED 缓存残留.
  sed -i 's/add_library(xcb-imdkit SHARED/add_library(xcb-imdkit STATIC/' ../src/CMakeLists.txt
  # 2026-11-25 交叉: cmake toolchain 文件(xx-clang + sysroot + 只找 .a; native 不生成不传, 零影响).
  XX_TC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    cat > $SRCROOT/xcb-imdkit-toolchain.cmake <<EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR $XX_TRIPLE)
set(CMAKE_C_COMPILER /usr/bin/xx-clang)
set(CMAKE_FIND_ROOT_PATH $XX_SYSROOT)
set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
set(CMAKE_EXE_LINKER_FLAGS "-static")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
    XX_TC="-DCMAKE_TOOLCHAIN_FILE=$SRCROOT/xcb-imdkit-toolchain.cmake"
    log "xcb-imdkit: CROSS toolchain ($XX_TRIPLE)"
  fi
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DUSE_SYSTEM_UTHASH=OFF \
    -DCMAKE_C_FLAGS="-fPIC" $XX_TC $XX_ECM_ARG >/dev/null 2>&1 \
    || { log "cmake configure FAILED: xcb-imdkit"; return 1; }
  # 只构建主库目标(make xcb-imdkit), 不构建 test(链接需 xcb 传递静态库, 缺参会 linker 失败);
  # 主库 libxcb-imdkit.a 已可产出, test 非部署所需.
  make -j$(nproc) xcb-imdkit >/dev/null 2>&1 || { log "make FAILED: xcb-imdkit"; return 1; }
  # install 触发 all(含 test)会再链接失败 -> 手动拷贝产物到 /usr/local
  # 当前在 build/ 目录: .a/.pc/生成头在 src/, 源码头在 ../src/
  install -d $XX_LIBDIR $XX_LIBDIR/pkgconfig $XX_INCDIR/xcb-imdkit
  install -m644 src/libxcb-imdkit.a $XX_LIBDIR/
  install -m644 src/xcb-imdkit.pc $XX_LIBDIR/pkgconfig/
  cp ../src/*.h $XX_INCDIR/xcb-imdkit/ 2>/dev/null || true
  cp src/*.h $XX_INCDIR/xcb-imdkit/ 2>/dev/null || true
  test -s $XX_LIBDIR/libxcb-imdkit.a || { log "MISSING $XX_LIBDIR/libxcb-imdkit.a"; return 1; }
  test -s $XX_LIBDIR/pkgconfig/xcb-imdkit.pc || { log "MISSING xcb-imdkit.pc"; return 1; }
  log "OK: xcb-imdkit"
}

rofi(){
  rofi_cross   # 交叉环境(XX_* 变量); native 全空零影响
  ROFI_VER=2.1.1
  # 依赖库(xcb-util 家族/startup-notification/xcb-imdkit)就位——有复用跳过, 缺则自建
  doExec b_deps || { log "rofi FAILED: b_deps"; exit 1; }
  get_src rofi-$ROFI_VER.tar.gz \
    https://github.com/davatorium/rofi/archive/refs/tags/$ROFI_VER.tar.gz \
    || return 1
  log "Extracting rofi $ROFI_VER ..."
  rm -rf $SRCROOT/rofi-$ROFI_VER $SRCROOT/rofi-build
  mkdir -p $SRCROOT/rofi-$ROFI_VER
  tar xzf $SRCROOT/rofi-$ROFI_VER.tar.gz -C $SRCROOT/rofi-$ROFI_VER --strip-components=1
  cd $SRCROOT/rofi-$ROFI_VER

  # rofi github tarball 不含 git 子模块(subprojects/libgwater, libnkutils 为空)
  # -> 单独取子模块源码填回 (rofi 2.1.1: libgwater d86f990(同2.0.0)/libnkutils d436ee7(2.1.1 更新, asan 修复);
  #    文档 11051758 九章原法; 2026-11-15 改: master 版会让 meson 0.59 丢 rofi 目标, 须用固定提交版)
  get_src libgwater.tar.gz https://github.com/sardemff7/libgwater/archive/d86f990.tar.gz
  get_src libnkutils.tar.gz https://github.com/sardemff7/libnkutils/archive/d436ee7.tar.gz
  tar xzf $SRCROOT/libgwater.tar.gz -C $SRCROOT/rofi-$ROFI_VER/subprojects
  tar xzf $SRCROOT/libnkutils.tar.gz -C $SRCROOT/rofi-$ROFI_VER/subprojects
  # github 归档为 <repo>-<suffix>/ 结构(master 或固定提交 SHA, 如 libgwater-d86f990),
  # 离线/自制 tarball 为 <repo>/ 结构 -> 统一为 <repo>/
  # 2026-11-15 修复(两处): rofi tarball 自带空占位子目录(git 子模块占位) → 直接 mv 会因目标存在而压入内部,
  #   变成 subprojects/libgwater/libgwater-XXX 嵌套 → meson 报 "Subproject exists but has no meson.build"。
  #   先 rm 占位再 mv; 后缀不定(-master / -d86f990 / -2f220a4), 用通配定位。
  for _sp in libgwater libnkutils; do
    _src=$(ls -d subprojects/$_sp-* 2>/dev/null | head -1)
    test -n "$_src" && { rm -rf subprojects/$_sp; mv "$_src" subprojects/$_sp; }
  done

  # rofi 需 flex+bison 生成 lexer/theme-{lexer,parser} (容器缺则 apk 装; 离线需预装)
  command -v flex >/dev/null 2>&1 || apk add --no-cache flex bison >/dev/null 2>&1 || true
  command -v bison >/dev/null 2>&1 || apk add --no-cache flex bison >/dev/null 2>&1 || true

  # 容器 glib 2.70.5 < rofi 要求的 2.72 (Alpine 3.15, apk 无网络升级):
  # 降最低版本要求, 让 meson setup 通过 (代码是否用 2.72+ API 由编译实证).
  sed -i 's/glib_min_minor=72/glib_min_minor=70/' meson.build

  # pkg-config --static 包装器: 让 meson 的 dependency() 解析出 Libs.private
  # (pcre/ffi/intl/png... 传递静态依赖), 否则静态链必 undefined reference.
  # 关键: meson 默认把 -lfoo 解析成 .so 全路径(即使 pkg-config --static),
  # 故把 --libs 输出里的 -lfoo 一律换成存在的 .a 绝对路径, 强制静态链。
  cat > $SRCROOT/pkgconfig-static.tpl <<'EOF'
#!/bin/sh
out=$(/usr/bin/pkg-config --static "$@")
case " $* " in
  *" --libs "*) ;;
  *" --libs-only-l "*) ;;
  *) echo "$out"; exit 0 ;;
esac
echo "$out" | tr ' ' '\n' | while IFS= read -r tok; do
  case "$tok" in
    -l*)
      name=${tok#-l}
      found=""
      for d in @@LIBDIRS@@; do
        if test -f "$d/lib$name.a"; then found="$d/lib$name.a"; break; fi
      done
      if test -n "$found"; then echo "$found"; fi
      # 2026-11-15: 无 .a 的 -l 直接丢弃(不再 echo -lxxx)——-static 下 echo 只会拉到
      #   动态 .so 报 "attempted static link of dynamic object"(如 gtk224-2 无 libzstd.a→webp 链 -lzstd;
      #   musl -lm 并入 libc 也可丢)。缺 .a 若真需要则链接 undefined 会暴露, 再补建。
      ;;
    *) echo "$tok" ;;
  esac
done | tr '\n' ' '
# 安全网: 某些 .pc 缺声明传递静态依赖, 统一附加 (startup-notification 需
# XGetXCBConnection -> libX11-xcb.a). 重复附加无害(--start-group 内只拉一次).
# 2026-11-15 追加: gdk-pixbuf svg loader(io-svg.c)引 rsvg_handle_* — gdk-pixbuf-2.0.pc 静态链不扩散
#   librsvg(同 libfm/geany 先例) → 附加 librsvg/croco/xml2(lxtask LIBS0 同款)。
printf ' @@EXTRA@@'
EOF
  # 2026-11-25 交叉: XX_LIBDIRS/XX_EXTRA_LIBS 由 rofi_cross 注入 sysroot 路径(native 原路径零影响)。
  sed -e "s|@@LIBDIRS@@|$XX_LIBDIRS|" -e "s|@@EXTRA@@|$XX_EXTRA_LIBS|" $SRCROOT/pkgconfig-static.tpl > $SRCROOT/pkgconfig-static
  chmod +x $SRCROOT/pkgconfig-static
  export PKG_CONFIG=$SRCROOT/pkgconfig-static
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

  # 2026-11-25 交叉: meson 0.59 HOST pkg-config 只认 cross-file [binaries] pkgconfig(env PKG_CONFIG 无效,
  #   find_external_program allow_default_for_cross=False) -> 本组件 cross-file 覆盖 pkgconfig 指静态包装器,
  #   否则 Libs.private 不解析, 静态链必 undefined。native 走 env PKG_CONFIG(原路径), 不生成。
  XX_CROSS_ARGS=""
  if [ -n "$XX_CROSS_FILE" ]; then
    ROFI_CROSS=$SRCROOT/xx-cross-rofi.ini
    sed "s|pkgconfig = '/usr/bin/pkg-config'|pkgconfig = '$SRCROOT/pkgconfig-static'|" "$XX_CROSS_FILE" > "$ROFI_CROSS"
    XX_CROSS_ARGS="--cross-file=$ROFI_CROSS"
  fi

  # 注意: meson 0.59 (feature 型 option) 只认 enabled/disabled/auto, 不认 true/false
  # 2026-11-23: imdkit=true 开 xim 输入法(xcb-imdkit, 已自建); 容器缺 gio-unix 的 xim 相关
  #   (libgwater/gio) 已由 b_deps 提供, 无新增 xcb 依赖。
  # 2026-11-25 功能开关全开(用户拍板): xcb 后端 + drun/window 模式 + imdkit 输入法 + giolaunch;
  #   dmenu/run/combi/ssh/script/filebrowser 无条件编入(非选项); wayland(非 xcb 后端)/check(测试) 不适用禁用。
  log "meson setup (xcb=enabled wayland=disabled imdkit=true drun=true window=true giolaunch=true check=disabled) ..."
  meson setup $SRCROOT/rofi-build $XX_CROSS_ARGS \
    -Dwayland=disabled -Dxcb=enabled -Dimdkit=true -Dcheck=disabled \
    -Ddrun=true -Dwindow=true -Dgiolaunch=true \
    -Dprefix=$TARGETPATH \
    -Dc_args="$CFLAGS" \
    -Dc_link_args="-Wl,--as-needed -static -Wl,--strip-all $XX_LINK_LIBDIR" 2>&1 \
    || { log "meson setup FAILED"; exit 1; }

  # 交叉: 重映射 native /usr(/usr/local) 头/库到 sysroot(armv7 ILP32 gdk_pixbuf 阻塞根因, 方案二)。
  if [ -n "$XX_CROSS_FILE" ]; then
    xx_meson_crossfix $SRCROOT/rofi-build
    # libnkutils nk-git-version-native 是 native:true 目标(在 build 机跑), xx_meson_crossfix 把其 -I/-L
    #   也重映射到 sysroot -> native cc 链 ARM .so (file in wrong format)。恢复该 native 目标 /usr 路径。
    #   编译/build 行含目标名 → sed 直接恢复; LINK_ARGS 行紧随 build 行但不带目标名 → awk 联动恢复。
    sed -i '/nk-git-version-native/ s|'"${XX_SYSROOT%/}"'/usr/|/usr/|g' $SRCROOT/rofi-build/build.ninja
    awk -v S="${XX_SYSROOT%/}" '
      /nk-git-version-native: c_LINKER_FOR_BUILD/ { nxt=1 }
      nxt && /LINK_ARGS/ { gsub(S "/usr/", "/usr/"); nxt=0 }
      { print }
    ' $SRCROOT/rofi-build/build.ninja > $SRCROOT/rofi-build/build.ninja.tmp \
      && mv $SRCROOT/rofi-build/build.ninja.tmp $SRCROOT/rofi-build/build.ninja
  fi

  log "ninja ..."
  ninja -C $SRCROOT/rofi-build 2>&1 || { log "ninja FAILED"; exit 1; }

  log "install ..."
  ninja -C $SRCROOT/rofi-build install 2>&1 || { log "install FAILED"; exit 1; }

  log "Verify rofi ..."
  ls -lh $TARGETPATH/bin/rofi
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $TARGETPATH/bin/rofi | grep -qE "ARM.*statically linked" \
      || { log "rofi file 非 ARM static"; exit 1; }
  else
    xx-verify --static $TARGETPATH/bin/rofi || { log "xx-verify FAILED"; exit 1; }
  fi
}

case "$1" in
cache)
    ;;
full)
    ;;
*) #compile (含 b_deps 一并走 oneBuild, 由各自函数内部校验兜底)
    oneBuild $1
    ;;
esac
