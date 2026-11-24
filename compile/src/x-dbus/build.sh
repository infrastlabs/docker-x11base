#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-dbus}"
source /src/common.sh

#
# Build dbus 1.12.26 static: libdbus-1.a + 静态 dbus-daemon（session bus runtime 依赖）。
#
# 组件目录 compile/src/x-dbus；构建容器 builder-obox（Alpine musl）。
# 版本 1.12.26（最后 1.12.x；1.14 起 meson 构建，1.12 是经典 autotools、静态链友好）。
# 网络坑：容器外网不可达，host 下载 tarball 放 /_ext/tmp/（docker mount 可见）或 /tmp/dbus-deps。
#
# 产物（/usr/local/static/dbus/）：
#   bin/dbus-daemon        静态（xx-clang -static，--version 可跑，session bus 实测通过）
#   bin/dbus-send          静态（xx-clang -static，--help 可跑；通知发送端 + dunstctl 运行期依赖，见 dbus_send()）
#   lib/libdbus-1.a        静态库（239 dbus_ 符号）
#   lib/libdbus-internal.a 内部库（dbus-daemon 静态链用，非公共 API）
#   lib/pkgconfig/dbus-1.pc
#   include/dbus-1.0/dbus/*.h（73 头）+ lib/dbus-1.0/include/dbus-arch-deps.h
#   share/dbus-1/session.conf + system.conf
#
# 静态链 dbus-daemon 要点：libtool 不认 LDFLAGS=-static（仍出动态二进制），须**手工** xx-clang -static
#   链 bus/*.o（daemon 20 对象 + main.o）+ libdbus-1.a + libdbus-internal.a + -lexpat -lpthread -ldl -lm。
#   对象清单取自 Makefile 的 dbus_daemon_OBJECTS（am__objects_2 + main.o）。
# 注意：configure 的 --disable-x11 无效（X11 autolaunch 仍开，config.h DBUS_ENABLE_X11_AUTOLAUNCH=1，
#   无害——box 有 libX11.a）；dbus-1.pc 的 Libs.private 为空，sed 补 -lexpat -lpthread -ldl -lm，
#   下游静态链 pkg-config --static --libs dbus-1 才完整。
#
DBUS_VER=1.12.26
DBUS_URL=https://dbus.freedesktop.org/releases/dbus/dbus-$DBUS_VER.tar.gz
DBUS_GLIB_VER=0.112
DBUS_GLIB_URL=https://dbus.freedesktop.org/releases/dbus-glib/dbus-glib-$DBUS_GLIB_VER.tar.gz

# 离线 tarball 优先 /tmp，否则 /_ext（docker mount），否则下载
fetch(){
  name=dbus-$DBUS_VER.tar.gz
  mkdir -p /tmp/dbus-deps
  for cand in /tmp/dbus-deps/$name /_ext/home/headless/xm-zs01/docker-x11base/.dbus-deps/$name \
             /_ext/tmp/$name; do
    if [ -f "$cand" ] && [ "$cand" != "/tmp/dbus-deps/$name" ]; then
      echo "use $cand"; cp "$cand" /tmp/dbus-deps/$name; break
    fi
  done
  if [ -f /tmp/dbus-deps/$name ]; then
    echo "unpack $name (offline)"
    tar xzf /tmp/dbus-deps/$name -C /tmp/dbus-build
  else
    echo "download $name"; down_catfile $DBUS_URL | tar xz -C /tmp/dbus-build
  fi
}

# dbus-glib tarball 离线优先 /tmp / .gsm-deps / .dbus-deps，否则下载
fetch_glib(){
  name=dbus-glib-$DBUS_GLIB_VER.tar.gz
  mkdir -p /tmp/dbus-deps
  for cand in /tmp/dbus-deps/$name /_ext/home/headless/xm-zs01/docker-x11base/.gsm-deps/$name \
             /_ext/home/headless/xm-zs01/docker-x11base/.dbus-deps/$name; do
    if [ -f "$cand" ] && [ "$cand" != "/tmp/dbus-deps/$name" ]; then
      echo "use $cand"; cp "$cand" /tmp/dbus-deps/$name; break
    fi
  done
  if [ -f /tmp/dbus-deps/$name ]; then
    echo "unpack $name (offline)"
    tar xzf /tmp/dbus-deps/$name -C /tmp/dbus-build
  else
    echo "download $name"; down_catfile $DBUS_GLIB_URL | tar xz -C /tmp/dbus-build
  fi
}

# 2026-11-24 方案二交叉: dbus 栈共用交叉环境（仿 u-gtkmm mm_cross / v-pcmanfm fm_cross）。
# 设 CROSS_HOST/XX_DESTDIR/DBUS_PC_PATH 供各函数: configure 追加 --host、ninja/make install 加 DESTDIR（装 sysroot）、
#   dbus-glib configure 的 PKG_CONFIG_PATH 前缀 sysroot（dbus-1.pc 经 DESTDIR 落 sysroot，native 路径不可见）。
# native（未设 TARGETPLATFORM/XX_CROSS_FILE 空）: 变量留空 → 原路径零影响。
dbus_cross(){
  CROSS_HOST=""; XX_DESTDIR=""; DBUS_PC_PATH=""; XX_CROSS_ARGS=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    XX_CROSS_ARGS="--cross-file $XX_CROSS_FILE"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先（同 u-gtk 坑②）
    XX_DESTDIR="DESTDIR=$XX_SYSROOT"
    DBUS_PC_PATH="${XX_SYSROOT}/usr/local/static/dbus/lib/pkgconfig"
    log "dbus: CROSS ($XX_TRIPLE)"
  fi
}

function dbus(){
  # 调用方须预置 TARGETPATH=/usr/local/static/dbus（同 v-sysmonitor 套路）；否则回落 static_temp1
  dbus_cross
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus}
  # configure 测试程序用非 -static LDFLAGS（pavucontrol 式，避免 AC_* 失败）；最终 daemon 手工 -static
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

  log "Download/unpack dbus-$DBUS_VER..."
    mkdir -p /tmp/dbus-build; rm -rf /tmp/dbus-build/dbus-$DBUS_VER
    fetch
    cd /tmp/dbus-build/dbus-$DBUS_VER

  log "Configuring dbus (static only, minimal)..."
    ./configure --enable-static --disable-shared \
      --disable-systemd --disable-selinux --disable-elogind \
      --disable-glib --disable-tests --disable-docs --disable-man \
      --prefix=$TARGETPATH >/tmp/dbus-cfg.log 2>&1 || true
    test -f Makefile || { log "dbus configure FAILED"; tail -20 /tmp/dbus-cfg.log; exit 1; }

  log "Compiling dbus (libdbus-1.a + daemon objects)..."
    make -j$(nproc) >/tmp/dbus-make.log 2>&1 || true   # daemon 仍动态，静态靠后面手工链
    test -f dbus/.libs/libdbus-1.a || { log "libdbus-1.a MISSING"; exit 1; }

  log "Install dbus static (manual, 免 make install 重链失败)..."
    mkdir -p $TARGETPATH/bin $TARGETPATH/lib/pkgconfig \
      $TARGETPATH/include/dbus-1.0/dbus $TARGETPATH/lib/dbus-1.0/include \
      $TARGETPATH/share/dbus-1/services $TARGETPATH/share/dbus-1/system-services
    cp dbus/.libs/libdbus-1.a dbus/.libs/libdbus-internal.a $TARGETPATH/lib/
    cp dbus-1.pc $TARGETPATH/lib/pkgconfig/
    # 静态库私有依赖补进 Libs（dbus-glib 等 configure 的 PKG_CHECK_MODULES 用 pkg-config --libs 非 --static，
    #   只有 -ldbus-1 会链不上 libdbus-1.a 的 expat/pthread 符号）；Libs.private 一并补
    sed -i "s/^Libs: .*/& -lexpat -lpthread -ldl -lm/" $TARGETPATH/lib/pkgconfig/dbus-1.pc
    sed -i "s/^Libs.private:.*/Libs.private: -lexpat -lpthread -ldl -lm/" $TARGETPATH/lib/pkgconfig/dbus-1.pc
    cp dbus/*.h $TARGETPATH/include/dbus-1.0/dbus/ 2>/dev/null || true
    cp dbus/dbus-arch-deps.h $TARGETPATH/lib/dbus-1.0/include/ 2>/dev/null || true
    cp bus/session.conf bus/system.conf $TARGETPATH/share/dbus-1/ 2>/dev/null || true

  log "Static-link dbus-daemon (xx-clang -static, 手工)..."
    xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/dbus-daemon \
      bus/activation.o bus/apparmor.o bus/audit.o bus/bus.o bus/config-loader-expat.o \
      bus/config-parser.o bus/config-parser-common.o bus/connection.o bus/desktop-file.o \
      bus/dir-watch-inotify.o bus/dispatch.o bus/driver.o bus/expirelist.o bus/policy.o \
      bus/selinux.o bus/services.o bus/signals.o bus/stats.o bus/test.o bus/utils.o bus/main.o \
      dbus/.libs/libdbus-1.a dbus/.libs/libdbus-internal.a -lexpat -lpthread -ldl -lm \
      || { log "dbus-daemon static-link FAILED"; exit 1; }

  log "Verify dbus..."
    file $TARGETPATH/bin/dbus-daemon | grep -q "statically linked" || { log "dbus-daemon not static"; exit 1; }
    xx-verify --static $TARGETPATH/bin/dbus-daemon || { log "dbus-daemon xx-verify FAILED"; exit 1; }
    $TARGETPATH/bin/dbus-daemon --version >/dev/null 2>&1 || { log "dbus-daemon run FAILED"; exit 1; }
    nm $TARGETPATH/lib/libdbus-1.a 2>/dev/null | grep -q "T dbus_bus_get" && echo "nm: dbus_bus_get OK"
    ls -lh $TARGETPATH/bin/dbus-daemon $TARGETPATH/lib/libdbus-1.a
}

# dbus-send：dbus 自带 CLI 发送工具（tools/dbus-send.c），静态链 libdbus-1.a。
# 用途：① 通知发送端（发 org.freedesktop.Notifications.Notify）；② 解锁 dunstctl——其是 shell 脚本，
#   运行期 command -v dbus-send 硬依赖（无则 die）。产物 bin/dbus-send。
# 依赖 dbus() 先跑（/tmp/dbus-build/dbus-$DBUS_VER + libdbus-1.a 就位）。
# 链接对象：tools/dbus-print-message.o + dbus-send.o + tool-common.o（tools/Makefile am_dbus_send_OBJECTS）；
#   静态链要点同 dbus-daemon——xx-clang -static 手工链（libtool 不认 LDFLAGS=-static）。
#   私有依赖同 libdbus-1.a：-lexpat -lpthread -ldl -lm（dbus-1.pc Libs.private 已补，见 dbus()）。
function dbus_send(){
  # 调用方须预置 TARGETPATH=/usr/local/static/dbus（同 dbus()）
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus}
  cd /tmp/dbus-build/dbus-$DBUS_VER 2>/dev/null || { log "dbus source not built, run dbus() first"; exit 1; }
  test -f dbus/.libs/libdbus-1.a || { log "libdbus-1.a missing, run dbus() first"; exit 1; }

  log "Build dbus-send objects (tools/*.o)..."
    make -j$(nproc) tools/dbus-print-message.o tools/dbus-send.o tools/tool-common.o \
     >/tmp/dbus-send-make.log 2>&1 || true
    test -f tools/dbus-send.o && test -f tools/dbus-print-message.o && test -f tools/tool-common.o \
     || { log "dbus-send objects MISSING"; tail -20 /tmp/dbus-send-make.log; exit 1; }

  log "Static-link dbus-send (xx-clang -static, 手工)..."
    mkdir -p $TARGETPATH/bin
    xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/dbus-send \
     tools/dbus-print-message.o tools/dbus-send.o tools/tool-common.o \
     dbus/.libs/libdbus-1.a -lexpat -lpthread -ldl -lm \
     || { log "dbus-send static-link FAILED"; exit 1; }

  log "Verify dbus-send..."
    file $TARGETPATH/bin/dbus-send | grep -q "statically linked" || { log "dbus-send not static"; exit 1; }
    xx-verify --static $TARGETPATH/bin/dbus-send || { log "dbus-send xx-verify FAILED"; exit 1; }
    $TARGETPATH/bin/dbus-send --help >/dev/null 2>&1 || { log "dbus-send run FAILED"; exit 1; }
    ls -lh $TARGETPATH/bin/dbus-send
}

# dbus-launch：dbus 自带 bus 启动辅助（tools/dbus-launch.c，C 程序非脚本），
# 用途：启动 dbus-daemon 并输出 DBUS_SESSION_BUS_ADDRESS（`eval $(dbus-launch --sh-syntax)`），
#   会话/脚本/调试常用（entry.sh 亦引用 dbus-launch）。产物 bin/dbus-launch。
# 依赖 dbus() 先跑（/tmp/dbus-build/dbus-$DBUS_VER + libdbus-1.a 就位）。
# 链接对象：tools/dbus-launch.o（tools/Makefile am_dbus_launch_OBJECTS）；静态链同 dbus-daemon——
#   xx-clang -static 手工链，私有依赖 -lexpat -lpthread -ldl -lm。
function dbus_launch(){
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus}
  cd /tmp/dbus-build/dbus-$DBUS_VER 2>/dev/null || { log "dbus source not built, run dbus() first"; exit 1; }
  test -f dbus/.libs/libdbus-1.a || { log "libdbus-1.a missing, run dbus() first"; exit 1; }

  log "Build dbus-launch objects (tools/*.o)..."
    make -j$(nproc) tools/dbus_launch-dbus-launch.o tools/dbus_launch-dbus-launch-x11.o tools/dbus_launch-tool-common.o \
     >/tmp/dbus-launch-make.log 2>&1 || true
    test -f tools/dbus_launch-dbus-launch.o \
     || { log "dbus_launch-dbus-launch.o MISSING"; tail -20 /tmp/dbus-launch-make.log; exit 1; }

  log "Static-link dbus-launch (xx-clang -static, 手工)..."
    mkdir -p $TARGETPATH/bin
    xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/dbus-launch \
      tools/dbus_launch-dbus-launch.o tools/dbus_launch-dbus-launch-x11.o tools/dbus_launch-tool-common.o \
      dbus/.libs/libdbus-1.a -lX11 -lxcb -lXau -lXdmcp -lexpat -lpthread -ldl -lm \
      || { log "dbus-launch static-link FAILED"; exit 1; }

  log "Verify dbus-launch..."
    file $TARGETPATH/bin/dbus-launch | grep -q "statically linked" || { log "dbus-launch not static"; exit 1; }
    xx-verify --static $TARGETPATH/bin/dbus-launch || { log "dbus-launch xx-verify FAILED"; exit 1; }
    $TARGETPATH/bin/dbus-launch --version >/dev/null 2>&1 || { log "dbus-launch run FAILED"; exit 1; }
    ls -lh $TARGETPATH/bin/dbus-launch
}

# dbus-glib-0.112：GLib 绑定（libdbus-glib-1.a），供 gsm/ristretto/xfce4-settings 静态链。
# 依赖 libdbus-1.a（/usr/local/static/dbus）+ glib/gobject/gio>=2.40（u-gtk 静态树）。
# configure PKG_CHECK_MODULES(DBUS) 用 pkg-config --libs dbus-1（非 --static）→ 需 dbus-1.pc 的
#   Libs 行已补 -lexpat -lpthread -ldl -lm（见 dbus() 的 sed），否则链接测试失败。
function dbus_glib(){
  # 调用方须预置 TARGETPATH=/usr/local/static/dbus-glib
  dbus_cross
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus-glib}
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
  # 交叉: dbus-1.pc 经 DESTDIR 落 sysroot /usr/local/static/dbus → PKG_CONFIG_PATH 前缀 sysroot（native 原路径不变）
  export PKG_CONFIG_PATH="${DBUS_PC_PATH:-/usr/local/static/dbus/lib/pkgconfig}:$PKG_CONFIG_PATH"

  log "Download/unpack dbus-glib-$DBUS_GLIB_VER..."
    mkdir -p /tmp/dbus-build; rm -rf /tmp/dbus-build/dbus-glib-$DBUS_GLIB_VER
    fetch_glib
    cd /tmp/dbus-build/dbus-glib-$DBUS_GLIB_VER

  log "Configuring dbus-glib (static only)..."
    ./configure --enable-static --disable-shared --prefix=$TARGETPATH $CROSS_HOST \
      >/tmp/dbusglib-cfg.log 2>&1 || true
    test -f Makefile || { log "dbus-glib configure FAILED"; tail -20 /tmp/dbusglib-cfg.log; exit 1; }

  log "Compiling dbus-glib (libdbus-glib-1.a)..."
    make -j$(nproc) >/tmp/dbusglib-make.log 2>&1 || true
    test -f dbus/.libs/libdbus-glib-1.a || { log "libdbus-glib-1.a MISSING"; tail -20 /tmp/dbusglib-make.log; exit 1; }

  log "Install dbus-glib static (manual, 免 make install 重链失败)..."
    # 头文件装到 $(includedir)/dbus-1.0/dbus/（= libdbus_glibdir，与 dbus 自身头同目录），
    #   dbus-glib.h 内部 #include <dbus/dbus-gtype-specialized.h> 等用 <dbus/...> 形式，pc Cflags
    #   -I${includedir}/dbus-1.0 即可解析；消费者 #include <dbus/dbus-glib.h>。
    mkdir -p ${XX_SYSROOT:-}$TARGETPATH/lib/pkgconfig ${XX_SYSROOT:-}$TARGETPATH/include/dbus-1.0/dbus ${XX_SYSROOT:-}$TARGETPATH/bin
    cp dbus/.libs/libdbus-glib-1.a ${XX_SYSROOT:-}$TARGETPATH/lib/
    cp dbus-glib-1.pc ${XX_SYSROOT:-}$TARGETPATH/lib/pkgconfig/ 2>/dev/null || cp dbus/dbus-glib-1.pc ${XX_SYSROOT:-}$TARGETPATH/lib/pkgconfig/ 2>/dev/null || true
    # 上游 pc Requires 漏 gio-2.0（configure 却检测 gio>=2.40），libdbus-glib-1.a 引用 g_dbus_is_member_name
    #   （gio 提供）；静态链需 gio 在链接行 → Requires 补 gio-2.0。
    sed -i "s/^Requires: .*/& gio-2.0/" ${XX_SYSROOT:-}$TARGETPATH/lib/pkgconfig/dbus-glib-1.pc 2>/dev/null || true
    cp dbus/*.h ${XX_SYSROOT:-}$TARGETPATH/include/dbus-1.0/dbus/ 2>/dev/null || true
    # dbus-glib-tool / dbus-binding-tool（构建时生成，供下游 glib 绑定 + 运行调试）
    [ -f dbus/dbus-glib-tool ] && cp dbus/dbus-glib-tool ${XX_SYSROOT:-}$TARGETPATH/bin/ 2>/dev/null || true
    [ -f dbus/dbus-binding-tool ] && cp dbus/dbus-binding-tool ${XX_SYSROOT:-}$TARGETPATH/bin/ 2>/dev/null || true

  log "Verify dbus-glib..."
    nm ${XX_SYSROOT:-}$TARGETPATH/lib/libdbus-glib-1.a 2>/dev/null | grep -q "T dbus_g_bus_get" && echo "nm: dbus_g_bus_get OK"
    ls -lh ${XX_SYSROOT:-}$TARGETPATH/lib/libdbus-glib-1.a
}

# 新方法（2026-11-23，方案C 升最新）：dbus 1.16.4 Meson 静态构建。
# 1.16 起 Autotools 移除（tarball 无 configure），须 Meson（容器已有 meson/ninja/python3）。
# 选项名见 meson_options.txt：x11_autolaunch（可正确关 X11，旧 configure --disable-x11 无效）、
#   default_library 是 Meson 内建（meson_options 不列），-Dc_link_args=-static 令 daemon/tools 全静态链。
# 产物：libdbus-1.a + bin/{dbus-daemon,dbus-send,dbus-launch}（tools=true 一次全建）+ dbus-1.pc + conf。
function dbus_1_16_4(){
  set -e
  dbus_cross
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus}
  DBUS_VER_NEW=1.16.4
  log "Download/unpack dbus-$DBUS_VER_NEW (meson)..."
    name=dbus-$DBUS_VER_NEW.tar.xz
    mkdir -p /tmp/dbus-deps /tmp/dbus-build
    rm -rf /tmp/dbus-build/dbus-$DBUS_VER_NEW
    for cand in /tmp/dbus-deps/$name /_ext/tmp/$name; do
      if [ -f "$cand" ] && [ "$cand" != "/tmp/dbus-deps/$name" ]; then
        echo "use $cand"; cp "$cand" /tmp/dbus-deps/$name; break
      fi
    done
    if [ -f /tmp/dbus-deps/$name ]; then
      echo "unpack $name (offline)"
      tar xJf /tmp/dbus-deps/$name -C /tmp/dbus-build
    else
      echo "download $name"
      down_catfile https://dbus.freedesktop.org/releases/dbus/$name | tar xJ -C /tmp/dbus-build
    fi
    cd /tmp/dbus-build/dbus-$DBUS_VER_NEW

  log "Patch meson.build: expat 强制静态（libexpat.a，否则 Meson 用 libexpat.so 与 -static 冲突）..."
    sed -i "s/        'expat',/        'expat',\n        static: true,/" meson.build
    grep -n "static: true" meson.build | head -2 || { log "expat static patch FAILED"; exit 1; }

  log "Meson setup dbus 1.16.4 (static only)..."
    meson setup build \
      -Ddefault_library=static \
      -Dc_link_args='-static -Wl,--strip-all' \
      -Dsystemd=disabled -Dselinux=disabled -Dapparmor=disabled -Dlibaudit=disabled \
      -Dx11_autolaunch=disabled -Dlaunchd=disabled \
      -Dtools=true -Dmessage_bus=true -Dtraditional_activation=true \
      -Duser_session=false \
      -Dmodular_tests=disabled -Dinstalled_tests=false -Dintrusive_tests=false \
      -Dxml_docs=disabled -Ddoxygen_docs=disabled -Dducktype_docs=disabled \
      -Dasserts=false -Dchecks=true \
      $XX_CROSS_ARGS --prefix=$TARGETPATH >/tmp/dbus164-meson.log 2>&1 \
      || { log "dbus 1.16.4 meson setup FAILED"; tail -25 /tmp/dbus164-meson.log; exit 1; }

  log "Ninja build dbus 1.16.4 (仅产品 target，避测试程序链动态库)..."
    ninja -C build bus/dbus-daemon tools/dbus-send tools/dbus-launch dbus/libdbus-1.a >/tmp/dbus164-ninja.log 2>&1 \
      || { log "dbus 1.16.4 ninja FAILED"; tail -30 /tmp/dbus164-ninja.log; exit 1; }

  log "Install dbus 1.16.4 (ninja install, ${XX_SYSROOT:-native}...)"
    env ${XX_DESTDIR:-} ninja -C build install >/tmp/dbus164-inst.log 2>&1 \
      || { log "dbus 1.16.4 install FAILED"; tail -20 /tmp/dbus164-inst.log; exit 1; }

  log "Patch dbus-1.pc Libs.private (expat/pthread/dl/m)..."
    PC=${XX_SYSROOT:-}$TARGETPATH/lib/pkgconfig/dbus-1.pc
    if [ -f "$PC" ]; then
      sed -i "s/^Libs: .*/& -lexpat -lpthread -ldl -lm/" "$PC"
      sed -i "s/^Libs.private:.*/Libs.private: -lexpat -lpthread -ldl -lm/" "$PC"
    fi

  log "Verify dbus 1.16.4..."
    file ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-daemon | grep -q "statically linked" || { log "dbus-daemon not static"; exit 1; }
    xx-verify --static ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-daemon || { log "dbus-daemon xx-verify FAILED"; exit 1; }
    # 交叉: target 二进制不能在 build 宿主跑（无 qemu-user）→ 跳过 run 测试（file/xx-verify 已证静态+arch）
    if [ -z "$XX_CROSS_FILE" ]; then
      ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-daemon --version >/dev/null 2>&1 || { log "dbus-daemon run FAILED"; exit 1; }
    else
      log "dbus-daemon run SKIP (cross)"
    fi
    xx-verify --static ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-send 2>/dev/null && echo "dbus-send static OK" || echo "!! dbus-send not static"
    xx-verify --static ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-launch 2>/dev/null && echo "dbus-launch static OK" || echo "!! dbus-launch not static"
    nm ${XX_SYSROOT:-}$TARGETPATH/lib/libdbus-1.a 2>/dev/null | grep -q "T dbus_bus_get" && echo "nm: dbus_bus_get OK"
    strings ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-daemon | grep -q "1.16.4" && echo "strings: version 1.16.4 OK"
    ls -lh ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-daemon ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-send ${XX_SYSROOT:-}$TARGETPATH/bin/dbus-launch ${XX_SYSROOT:-}$TARGETPATH/lib/libdbus-1.a
}

# 旧方法别名（1.12.26 Autotools，保留可调；默认入口走 dbus_1_16_4）
function dbus_1_12_26(){ dbus; }
function dbus_send_1_12_26(){ dbus_send; }
function dbus_launch_1_12_26(){ dbus_launch; }

case "$1" in
cache)
    down_catfile $DBUS_URL > /dev/null
    ;;
full)
    doExec dbus_1_16_4 || exit 1
    ;;
full-send)
    doExec dbus_1_16_4 || exit 1
    ;;
dbus|dbus-send|dbus-launch)
    # 默认走新 1.16.4（Meson 全建 daemon/send/launch/lib）；旧 1.12.26 方法保留可调（dbus_1_12_26）
    oneBuild dbus_1_16_4
    ;;
full-glib)
    doExec dbus_glib || exit 1
    ;;
b_deps)
    # 静态库依赖检查
    echo "== dbus =="; ls /usr/local/static/dbus/lib/libdbus-1.a /usr/local/static/dbus/bin/dbus-daemon 2>&1
    echo "== libexpat (daemon 静态链依赖) =="; ls /usr/lib/libexpat.a 2>&1
    ;;
*) #compile：dbus_glib / dbus_1_12_26 / dbus_send_1_12_26 等按名
    oneBuild $1
    ;;
esac
exit 0
