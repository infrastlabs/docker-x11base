#!/bin/sh
set -e
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

function dbus(){
  # 调用方须预置 TARGETPATH=/usr/local/static/dbus（同 v-sysmonitor 套路）；否则回落 static_temp1
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

# dbus-glib-0.112：GLib 绑定（libdbus-glib-1.a），供 gsm/ristretto/xfce4-settings 静态链。
# 依赖 libdbus-1.a（/usr/local/static/dbus）+ glib/gobject/gio>=2.40（u-gtk 静态树）。
# configure PKG_CHECK_MODULES(DBUS) 用 pkg-config --libs dbus-1（非 --static）→ 需 dbus-1.pc 的
#   Libs 行已补 -lexpat -lpthread -ldl -lm（见 dbus() 的 sed），否则链接测试失败。
function dbus_glib(){
  # 调用方须预置 TARGETPATH=/usr/local/static/dbus-glib
  export TARGETPATH=${TARGETPATH:-/usr/local/static/dbus-glib}
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
  export PKG_CONFIG_PATH="/usr/local/static/dbus/lib/pkgconfig:$PKG_CONFIG_PATH"

  log "Download/unpack dbus-glib-$DBUS_GLIB_VER..."
    mkdir -p /tmp/dbus-build; rm -rf /tmp/dbus-build/dbus-glib-$DBUS_GLIB_VER
    fetch_glib
    cd /tmp/dbus-build/dbus-glib-$DBUS_GLIB_VER

  log "Configuring dbus-glib (static only)..."
    ./configure --enable-static --disable-shared --prefix=$TARGETPATH \
      >/tmp/dbusglib-cfg.log 2>&1 || true
    test -f Makefile || { log "dbus-glib configure FAILED"; tail -20 /tmp/dbusglib-cfg.log; exit 1; }

  log "Compiling dbus-glib (libdbus-glib-1.a)..."
    make -j$(nproc) >/tmp/dbusglib-make.log 2>&1 || true
    test -f dbus/.libs/libdbus-glib-1.a || { log "libdbus-glib-1.a MISSING"; tail -20 /tmp/dbusglib-make.log; exit 1; }

  log "Install dbus-glib static (manual, 免 make install 重链失败)..."
    # 头文件装到 $(includedir)/dbus-1.0/dbus/（= libdbus_glibdir，与 dbus 自身头同目录），
    #   dbus-glib.h 内部 #include <dbus/dbus-gtype-specialized.h> 等用 <dbus/...> 形式，pc Cflags
    #   -I${includedir}/dbus-1.0 即可解析；消费者 #include <dbus/dbus-glib.h>。
    mkdir -p $TARGETPATH/lib/pkgconfig $TARGETPATH/include/dbus-1.0/dbus $TARGETPATH/bin
    cp dbus/.libs/libdbus-glib-1.a $TARGETPATH/lib/
    cp dbus-glib-1.pc $TARGETPATH/lib/pkgconfig/ 2>/dev/null || cp dbus/dbus-glib-1.pc $TARGETPATH/lib/pkgconfig/ 2>/dev/null || true
    # 上游 pc Requires 漏 gio-2.0（configure 却检测 gio>=2.40），libdbus-glib-1.a 引用 g_dbus_is_member_name
    #   （gio 提供）；静态链需 gio 在链接行 → Requires 补 gio-2.0。
    sed -i "s/^Requires: .*/& gio-2.0/" $TARGETPATH/lib/pkgconfig/dbus-glib-1.pc 2>/dev/null || true
    cp dbus/*.h $TARGETPATH/include/dbus-1.0/dbus/ 2>/dev/null || true
    # dbus-glib-tool / dbus-binding-tool（构建时生成，供下游 glib 绑定 + 运行调试）
    [ -f dbus/dbus-glib-tool ] && cp dbus/dbus-glib-tool $TARGETPATH/bin/ 2>/dev/null || true
    [ -f dbus/dbus-binding-tool ] && cp dbus/dbus-binding-tool $TARGETPATH/bin/ 2>/dev/null || true

  log "Verify dbus-glib..."
    nm $TARGETPATH/lib/libdbus-glib-1.a 2>/dev/null | grep -q "T dbus_g_bus_get" && echo "nm: dbus_g_bus_get OK"
    ls -lh $TARGETPATH/lib/libdbus-glib-1.a
}

case "$1" in
cache)
    down_catfile $DBUS_URL > /dev/null
    ;;
full)
    dbus
    ;;
full-glib)
    dbus_glib
    ;;
b_deps)
    # 静态库依赖检查
    echo "== dbus =="; ls /usr/local/static/dbus/lib/libdbus-1.a /usr/local/static/dbus/bin/dbus-daemon 2>&1
    echo "== libexpat (daemon 静态链依赖) =="; ls /usr/lib/libexpat.a 2>&1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
