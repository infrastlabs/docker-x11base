#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-rofi}"
source /src/common.sh

#
# Build rofi (应用启动器/dmenu 替代, 2.0.0, xcb+cairo+pango 渲染, 无 GTK)
#
# 版本: 2.0.0 (2025-09-01), meson-only (弃 autotools), xcb 后端
#   上游: https://github.com/davatorium/rofi (tag 2.0.0)
# 依赖(xcb 后端, meson.build xcb_deps): glib-2.0(>=2.72)/gmodule-2.0/gio-unix-2.0,
#   cairo/cairo-xcb, pango/pangocairo, gdk-pixbuf-2.0, xkbcommon/xkbcommon-x11,
#   xcb, xcb-aux(xcb-util), xcb-ewmh/xcb-icccm(xcb-util-wm), xcb-randr, xcb-cursor,
#   xcb-xinerama, xcb-keysyms, libstartup-notification-1.0
#   (子项目 libgwater/libnkutils 为 git 子模块, github tarball 不含 -> 需单独取)
# 需补建(纯 C 静态, 装 /usr/local/lib): xcb-util 家族 + startup-notification
#   顺序: util -> image -> renderutil -> wm(icccm+ewmh)/keysyms/xrm -> cursor
#   (cursor 依赖 image/renderutil/util 的 .pc, 故最后)
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
# 注意(容器内实测): rofi 2.0.0 meson 要求 glib>=2.72, 而本容器(Alpine 3.15)
#   glib 为 2.70.5 且 apk 无网络升级 -> sed 降 glib_min_minor 至 70 (见 rofi())。
export TARGETPATH=${TARGETPATH:-/usr/local/static/rofi}

# 离线 tarball 兜底(/tmp 已有则跳过) + 多源回退
get_src(){
  local tarball=$1; shift
  if test -s /tmp/$tarball; then
    log "offline cache /tmp/$tarball"
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
    test -s /usr/local/lib/$l || { all_exist=0; break; }
  done
  if test "$all_exist" = "1"; then log "reuse existing $libs (skip build)"; return 0; fi
  get_src "$tarball" "$@" || return 1
  log "Building $libs (from $tarball) ..."
  rm -rf /tmp/build-$srcdir
  mkdir -p /tmp/build-$srcdir
  tar xzf /tmp/$tarball -C /tmp/build-$srcdir --strip-components=1
  cd /tmp/build-$srcdir
  test -x ./configure || { autoreconf -fi 2>&1 || { log "autoreconf FAILED: $srcdir"; return 1; }; }
  ./configure --enable-static --disable-shared --prefix=/usr/local 2>&1 \
    || { log "configure FAILED: $srcdir"; return 1; }
  # 测试程序链接缺 xcb 的传递静态依赖(Xau/Xdmcp) -> 经 LIBS 补齐(静态链模式)
  make -j$(nproc) LIBS="-lXau -lXdmcp" 2>&1 || { log "make FAILED: $srcdir"; return 1; }
  make install 2>&1 || { log "install FAILED: $srcdir"; return 1; }
  for l in $(echo "$libs" | tr ':' ' '); do
    test -s /usr/local/lib/$l || { log "MISSING /usr/local/lib/$l"; return 1; }
  done
  log "OK: $libs"
}

# 补建 xcb-util 家族 8 个 + startup-notification (全部纯 C autotools)
b_deps(){
  # xcb-util 核心 (提供 xcb-util.pc / xcb-aux.pc / xcb-atom.pc / xcb-event.pc)
  # 真正复用: 不再保留本包源码 URL, 统一用 w-tint2 的 xcbutil()(gitee fk-xcb__util)构建;
  # 若 /usr/local/lib/libxcb-util.a 已存在则直接用(不重编), 否则调 w-tint2。
  if ! test -s /usr/local/lib/libxcb-util.a; then
    log "xcb-util missing, build via w-tint2 xcbutil..."
    doExec bash /src/w-tint2/build.sh xcbutil || { log "b_deps FAILED: xcb-util (w-tint2 xcbutil)"; exit 1; }
  fi
  test -s /usr/local/lib/libxcb-util.a || { log "b_deps FAILED: libxcb-util.a missing"; exit 1; }
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
  log "b_deps all OK"
}

rofi(){
  ROFI_VER=2.0.0
  get_src rofi-$ROFI_VER.tar.gz \
    https://github.com/davatorium/rofi/archive/refs/tags/$ROFI_VER.tar.gz \
    || return 1
  log "Extracting rofi $ROFI_VER ..."
  rm -rf /tmp/rofi-$ROFI_VER /tmp/rofi-build
  mkdir -p /tmp/rofi-$ROFI_VER
  tar xzf /tmp/rofi-$ROFI_VER.tar.gz -C /tmp/rofi-$ROFI_VER --strip-components=1
  cd /tmp/rofi-$ROFI_VER

  # rofi github tarball 不含 git 子模块(subprojects/libgwater, libnkutils 为空)
  # -> 单独取子模块源码填回 (rofi 2.0.0 固定提交 d86f990/2f220a4)
  get_src libgwater.tar.gz https://github.com/sardemff7/libgwater/archive/refs/heads/master.tar.gz
  get_src libnkutils.tar.gz https://github.com/sardemff7/libnkutils/archive/refs/heads/master.tar.gz
  tar xzf /tmp/libgwater.tar.gz -C /tmp/rofi-$ROFI_VER/subprojects
  tar xzf /tmp/libnkutils.tar.gz -C /tmp/rofi-$ROFI_VER/subprojects
  # github 归档为 <repo>-master/ 结构, 离线 tarball 为 <repo>/ 结构 -> 统一为 <repo>/
  test -d subprojects/libgwater-master && mv subprojects/libgwater-master subprojects/libgwater
  test -d subprojects/libnkutils-master && mv subprojects/libnkutils-master subprojects/libnkutils

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
  cat > /tmp/pkgconfig-static <<'EOF'
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
      for d in /usr/local/lib /usr/lib /lib; do
        if test -f "$d/lib$name.a"; then found="$d/lib$name.a"; break; fi
      done
      if test -n "$found"; then echo "$found"; else echo "$tok"; fi
      ;;
    *) echo "$tok" ;;
  esac
done | tr '\n' ' '
# 安全网: 某些 .pc 缺声明传递静态依赖, 统一附加 (startup-notification 需
# XGetXCBConnection -> libX11-xcb.a). 重复附加无害(--start-group 内只拉一次).
printf ' /usr/lib/libX11-xcb.a'
EOF
  chmod +x /tmp/pkgconfig-static
  export PKG_CONFIG=/tmp/pkgconfig-static
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

  # 注意: meson 0.59 (feature 型 option) 只认 enabled/disabled/auto, 不认 true/false
  log "meson setup (wayland=disabled xcb=enabled imdkit=false check=disabled) ..."
  meson setup /tmp/rofi-build \
    -Dwayland=disabled -Dxcb=enabled -Dimdkit=false -Dcheck=disabled \
    -Dprefix=$TARGETPATH \
    -Dc_args="$CFLAGS" \
    -Dc_link_args="-Wl,--as-needed -static -Wl,--strip-all -L/usr/local/lib" 2>&1 \
    || { log "meson setup FAILED"; exit 1; }

  log "ninja ..."
  ninja -C /tmp/rofi-build 2>&1 || { log "ninja FAILED"; exit 1; }

  log "install ..."
  ninja -C /tmp/rofi-build install 2>&1 || { log "install FAILED"; exit 1; }

  log "Verify rofi ..."
  ls -lh $TARGETPATH/bin/rofi
  xx-verify --static $TARGETPATH/bin/rofi || { log "xx-verify FAILED"; exit 1; }
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
