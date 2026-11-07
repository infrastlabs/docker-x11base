#!/bin/sh
set -e
source /src/common.sh

#
# Build gnome-system-monitor 2.28.2 (GTK2/gtkmm-2.4) 静态
#
# 组装容器 = builder-awe（主题/图标库 murrine/pixmap/rsvg/svg 在此；gtkmm 栈 + pulse 栈已拷入）。
# gconf patch：gsm 2.28 依赖 gconf-2.0（CORBA 配置守护进程，静态链无 ORBit2）→ 打补丁去掉，
#   偏好改 GKeyFile 存 ~/.config/gnome-system-monitor/procman.ini（见 gsm-gconf-keyfile.patch
#   的 src/gconf-shim.h：gconf-2.0 API 子集的 GKeyFile 实现，含 get/set/notify/dir_exists/list）。
#   dbus-glib-1 也从 PKG_CHECK_MODULES 去掉——gsm 的单实例用 Unix socket（bacon-message-
#   connection.c），代码实际不用 dbus。
# 依赖静态库：libgtop-2.40.0 + libwnck-2.30.7（libwnck 无 Xres 时条件编译降级，configure 输出
#   "XRes support: no"）。
# 版本 2.28.2 = 最后 GTK2 版。CXXFLAGS 需 -std=c++11（glibmm-2.48 头要求；configure 默认 -std=c++98
#   会报 sigc++/glibmm "requires C++11"）。
# 网络坑（2026-11-05）：容器外网不可达，host 下载 tarball docker cp 到 /tmp（离线复用）；
#   /_ext mount 直接可见（._ext 下的 .gsm / .gsm-deps）。
#
# 静态链（xx-clang++ -static）需额外：-lstartup-notification-1 -lxcb-util -lX11-xcb
#   （libwnck → libstartup-notification → xcb-util/X11-xcb），其余同 v-pavucontrol 的 LIBS0。
#
GNOME=https://download.gnome.org/sources

# 离线 tarball 优先 /tmp，否则 /_ext（docker mount），否则下载
fetch(){
  name=$1; path=$2
  mkdir -p /tmp/gsm-deps
  for cand in /tmp/gsm-deps/$name /_ext/home/headless/xm-zs01/docker-x11base/.gsm-deps/$name \
             /_ext/home/headless/xm-zs01/docker-x11base/.gsm/$name; do
    if [ -f "$cand" ]; then echo "use $cand"; cp "$cand" /tmp/gsm-deps/$name; break; fi
  done
  if [ -f /tmp/gsm-deps/$name ]; then
    echo "unpack $name (offline)"; 
    case $name in *.xz) tar xJf /tmp/gsm-deps/$name -C /tmp/gsm-build;; *) tar xjf /tmp/gsm-deps/$name -C /tmp/gsm-build;; esac
  else
    echo "download $name"; down_catfile $path | tar -xJ -C /tmp/gsm-build 2>/dev/null || down_catfile $path | tar -xj -C /tmp/gsm-build
  fi
}

build_gtop(){
  log "Build libgtop-2.40.0 static..."
    mkdir -p /tmp/gsm-build; rm -rf /tmp/gsm-build/libgtop-2.40.0
    fetch libgtop-2.40.0.tar.xz $GNOME/libgtop/2.40/libgtop-2.40.0.tar.xz
    cd /tmp/gsm-build/libgtop-2.40.0
    ./configure --enable-static --disable-shared --prefix=/usr/local/static/gtop >/tmp/gtop-cfg.log 2>&1 || true
    make -j$(nproc) >/tmp/gtop-make.log 2>&1 || true   # gir/introspect 用静态 glib 缺 -lpcre，会失败但 .a 已产出
    test -f lib/.libs/libgtop-2.0.a || { log "libgtop-2.0.a MISSING"; exit 1; }
    mkdir -p /usr/local/static/gtop/lib/pkgconfig /usr/local/static/gtop/include/libgtop-2.0
    cp lib/.libs/libgtop-2.0.a /usr/local/static/gtop/lib/
    cp libgtop-2.0.pc /usr/local/static/gtop/lib/pkgconfig/
    cp libgtopconfig.h /usr/local/static/gtop/include/libgtop-2.0/
    cp -r include/glibtop /usr/local/static/gtop/include/libgtop-2.0/
    cp glibtop.h /usr/local/static/gtop/include/libgtop-2.0/
    ls -lh /usr/local/static/gtop/lib/libgtop-2.0.a
}

build_wnck(){
  log "Build libwnck-2.30.7 static (no Xres, conditional)..."
    mkdir -p /tmp/gsm-build; rm -rf /tmp/gsm-build/libwnck-2.30.7
    fetch libwnck-2.30.7.tar.xz $GNOME/libwnck/2.30/libwnck-2.30.7.tar.xz
    cd /tmp/gsm-build/libwnck-2.30.7
    ./configure --enable-static --disable-shared --disable-gtk-doc --prefix=/usr/local/static/wnck >/tmp/wnck-cfg.log 2>&1 || true
    ./config.status >/dev/null 2>&1 || true
    make -j$(nproc) >/tmp/wnck-make.log 2>&1 || true  # 测试程序缺 -ljpeg/-lxcb 等会失败，但 libwnck-1.a 已产出
    test -f libwnck/.libs/libwnck-1.a || { log "libwnck-1.a MISSING"; exit 1; }
    mkdir -p /usr/local/static/wnck/lib/pkgconfig /usr/local/static/wnck/include/libwnck-1.0/libwnck
    cp libwnck/.libs/libwnck-1.a /usr/local/static/wnck/lib/
    cp libwnck-1.0.pc /usr/local/static/wnck/lib/pkgconfig/
    cp libwnck/*.h /usr/local/static/wnck/include/libwnck-1.0/libwnck/
    ls -lh /usr/local/static/wnck/lib/libwnck-1.a
}

# gnome-icon-theme / gnome-doc-utils 是 data/构建工具，无 .a；pkg-config 检查需 .pc
stub_pc(){
  log "Create stub pc (gnome-icon-theme, gnome-doc-utils)..."
    printf "prefix=/usr\nexec_prefix=\${prefix}\ndatadir=\${prefix}/share\nName: GNOME Icon Theme\nDescription: GNOME Icon Theme data\nVersion: 2.15.3\n" > /usr/local/static/gtop/lib/pkgconfig/gnome-icon-theme.pc
    printf "prefix=/usr\nexec_prefix=\${prefix}\ndatadir=\${prefix}/share\nlibdir=\${exec_prefix}/lib\nincludedir=\${prefix}/include\nName: gnome-doc-utils\nDescription: GNOME documentation utilities\nVersion: 0.32.3\n" > /usr/local/static/gtop/lib/pkgconfig/gnome-doc-utils.pc
}

function gnome_system_monitor(){
  export TARGETPATH=${TARGETPATH:-/usr/local/static/gsm}
  export PKG_CONFIG_PATH="/usr/local/static/gtop/lib/pkgconfig:/usr/local/static/wnck/lib/pkgconfig:$PKG_CONFIG_PATH"
  # configure 测试程序用非 -static LDFLAGS（pavucontrol 式）；最终二进制手动 xx-clang++ -static
  export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

  stub_pc

  log "Download/unpack GSM (2.28.2 tarball)..."
    rm -rf /tmp/gsm-build/gsm; mkdir -p /tmp/gsm-build
    # gsm 源码已在 /_ext/.gsm/gnome-system-monitor-2.28.2（已打 gconf patch）
    if [ -d /_ext/home/headless/xm-zs01/docker-x11base/.gsm/gnome-system-monitor-2.28.2 ]; then
      cp -r /_ext/home/headless/xm-zs01/docker-x11base/.gsm/gnome-system-monitor-2.28.2 /tmp/gsm-build/gsm
    else
      mkdir -p /tmp/gsm-build/gsm
      down_catfile $GNOME/gnome-system-monitor/2.28/gnome-system-monitor-2.28.2.tar.bz2 \
        | tar -xj --strip 1 -C /tmp/gsm-build/gsm
      cd /tmp/gsm-build/gsm
      git apply /src/v-sysmonitor/gsm-gconf-keyfile.patch 2>/dev/null \
        || patch -p1 < /src/v-sysmonitor/gsm-gconf-keyfile.patch 2>/dev/null || true
    fi
    cd /tmp/gsm-build/gsm
    # 磁盘 tab 卡顿修复 patch（两分支统一应用；.gsm 源码亦不含，见 2026-11-08）
    git apply /src/v-sysmonitor/gsm-disk-icon-static.patch 2>/dev/null \
      || patch -p1 < /src/v-sysmonitor/gsm-disk-icon-static.patch 2>/dev/null || true

  log "Configuring GSM (GTK2, static only)..."
    ./configure --enable-static --disable-shared --prefix=/usr/local/static/gsm >/tmp/gsm-cfg.log 2>&1 || true
    test -f Makefile || ./config.status >/tmp/gsm-cs.log 2>&1
    test -f Makefile || { log "GSM configure FAILED"; tail -20 /tmp/gsm-cfg.log; exit 1; }
    # 2.28.2 旧 automake：configure 未替换 GCONF_SCHEMAS_INSTALL_TRUE/FALSE 条件
    # （src/Makefile 残留 @...@ 字面量 → make "missing separator"）。只编对象，剥掉条件前缀即可
    # （install-data-local 规则冗余但仅 install 用，不影响编译；/_ext/.gsm 预打源码已失，落回官方 tarball 触发）。
    # 同时修 Makefile.in(模板, config.status 会再生成 Makefile)与 Makefile; 剥掉未替换的条件前缀
    sed -i 's/^@GCONF_SCHEMAS_INSTALL_TRUE@//; s/^@GCONF_SCHEMAS_INSTALL_FALSE@//' src/Makefile.in src/Makefile

  log "Compiling GSM objects (-std=c++11; link step later)..."
    make -j$(nproc) CFLAGS="-Os -fomit-frame-pointer" CXXFLAGS="-Wall -std=c++11 -Os -fomit-frame-pointer" \
      >/tmp/gsm-make.log 2>&1 || true   # 链接会失败（静态链缺 lib），对象已产出
    test -f src/procman.o || { log "GSM objects MISSING"; exit 1; }

  log "Static-link GSM (direct, xx-clang++ -static)..."
    if [ ! -f /usr/lib/libgcc_s.a ]; then
      GCCDIR=$(dirname $(find /usr/lib/gcc -name libgcc.a | head -1)); cp $GCCDIR/libgcc.a /usr/lib/libgcc_s.a
    fi
    # GTK2 print 后端（file/lpr）由静态 libgtk 提供；gnome-system-monitor 不调用 gtk_print_*，
    # 这些 .o 不会被静态链自动拉取 → -Wl,-u 强制符号未定义从 libgtk.a 拉入真实后端
    # （替代早期 no-op 存根，同 v-pavucontrol，2026-11-08 gtk 重建后验证可链）。
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
    LIBS0="-lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    mkdir -p $TARGETPATH/bin
    cd /tmp/gsm-build/gsm/src
    xx-clang++ -static -Wl,--strip-all -o $TARGETPATH/bin/gnome-system-monitor \
      *.o \
      -Wl,-u,_gtk_print_backend_file_init -Wl,-u,_gtk_print_backend_file_exit -Wl,-u,_gtk_print_backend_file_create \
      -Wl,-u,_gtk_print_backend_lpr_init -Wl,-u,_gtk_print_backend_lpr_exit -Wl,-u,_gtk_print_backend_lpr_create \
      -Wl,--start-group \
      -lgtkmm-2.4 -latkmm-1.6 -lgdkmm-2.4 -lgiomm-2.4 -lpangomm-1.4 -lglibmm-2.4 -lcairomm-1.0 -lsigc-2.0 \
      -L/usr/local/static/gtop/lib -L/usr/local/static/wnck/lib \
      -lgtop-2.0 -lwnck-1 \
      -lstartup-notification-1 -L/tmp/xcb-util/src/.libs -lxcb-util -lX11-xcb \
      -lXinerama -lXrandr -lXfixes -lstdc++ -lsupc++ -lgcc -lgcc_eh -lgthread-2.0 \
      $LIBS0 \
      -Wl,--end-group \
      -lintl || { log "GSM static-link FAILED"; exit 1; }

  log "Install GSM data (desktop + pixmaps; make install 会重链失败，手装)..."
    mkdir -p $TARGETPATH/share/applications $TARGETPATH/share/pixmaps/gnome-system-monitor
    sed "s/^_Name=/Name=/;s/^_Comment=/Comment=/" /tmp/gsm-build/gsm/gnome-system-monitor.desktop.in \
      > $TARGETPATH/share/applications/gnome-system-monitor.desktop
    cp /tmp/gsm-build/gsm/pixmaps/side.png $TARGETPATH/share/pixmaps/gnome-system-monitor/
    cp /tmp/gsm-build/gsm/pixmaps/download.svg /tmp/gsm-build/gsm/pixmaps/upload.svg $TARGETPATH/share/pixmaps/gnome-system-monitor/ 2>/dev/null || true

  log "Verify GSM..."
    file $TARGETPATH/bin/gnome-system-monitor
    xx-verify --static $TARGETPATH/bin/gnome-system-monitor || { log "GSM xx-verify FAILED"; exit 1; }
    strings $TARGETPATH/bin/gnome-system-monitor | grep -q "procman.ini" && echo "strings: procman.ini OK (gconf-shim)"
    strings $TARGETPATH/bin/gnome-system-monitor | grep -q "utilities-system-monitor" && echo "strings: icon OK"
    strings $TARGETPATH/bin/gnome-system-monitor | grep -q "MurrineRcStyle" && echo "strings: murrine OK"
    ls -lh $TARGETPATH/bin/gnome-system-monitor
}

case "$1" in
cache)
    # down_catfile $GNOME/gnome-system-monitor/2.28/gnome-system-monitor-2.28.2.tar.bz2 > /dev/null
    # down_catfile $GNOME/libgtop/2.40/libgtop-2.40.0.tar.xz > /dev/null
    # down_catfile $GNOME/libwnck/2.30/libwnck-2.30.7.tar.xz > /dev/null
    ;;
full)
    build_gtop
    build_wnck
    gnome_system_monitor
    ;;
b_deps)
    # 静态库依赖检查
    echo "== gtop/wnck =="; ls /usr/local/static/gtop/lib/libgtop-2.0.a /usr/local/static/wnck/lib/libwnck-1.a 2>&1
    echo "== gtkmm stack =="; ls /usr/lib/libgtkmm-2.4.a /usr/lib/libglibmm-2.4.a 2>&1
    echo "== xcb-util (startup-notification 依赖) =="; ls /tmp/xcb-util/src/.libs/libxcb-util.a 2>&1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
