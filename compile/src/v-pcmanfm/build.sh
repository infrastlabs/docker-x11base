#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-pcmanfm}"
source /src/common.sh

# git clone https://hub.nuaa.cf/GNOME/atk #3.29 MiB 1985> ATK_2_36_0 1943
# git clone https://hub.nuaa.cf/GNOME/gtk #644.58 MiB 78343> 2.24.33 21885
# git clone https://hub.nuaa.cf/GNOME/gdk-pixbuf #177.02 MiB 6226> 2.42.8 6113
# git clone https://hub.nuaa.cf/lxde/menu-cache #297 commits


# tmux-3
# bash-5.1# history |grep "apk add"
#   949  apk x gdk-pixbuf-dev pango-dev
#libatk-1.0
#libatk
#atk
#gobject-introspection
#gobject-introspection-dev
#fontconfig-static
#  1411  history |grep "apk add"
# 
# 
# bash-5.1# apk x gdk-pixbuf-dev #@tmux-8
# (1/10) Installing shared-mime-info (2.1-r2)
# (2/10) Installing libwebp (1.2.2-r2)
# (3/10) Installing tiff (4.4.0-r4)
# (4/10) Installing gdk-pixbuf (2.42.8-r0)
# (5/10) Installing libwebp-dev (1.2.2-r2)
# (6/10) Installing xz-dev (5.2.5-r1)
# (7/10) Installing zstd-dev (1.5.0-r0)
# (8/10) Installing libtiffxx (4.4.0-r4)
# (9/10) Installing tiff-dev (4.4.0-r4)
# (10/10) Installing gdk-pixbuf-dev (2.42.8-r0)
# 
# bash-5.1# apk x atk
# (1/1) Installing atk (2.36.0-r0)
# 
# bash-5.1# apk x gobject-introspection-dev
# (1/2) Installing gobject-introspection (1.70.0-r1)
# (2/2) Installing gobject-introspection-dev (1.70.0-r1)
# 
# bash-5.1# apk x fontconfig-static
# (1/1) Installing fontconfig-static (2.13.1-r4)

# libfm
function libfm(){
  export TARGETPATH=${TARGETPATH:-/usr/local/static/pcmanfm}
  # intltool #builder装过了？？ (调试img:没得)
  # apk update; apk add gtk-doc intltool vala \
  #  menu-cache-dev gtk+2.0-dev menu-cache-dev #1.1.0-r0


  log "Downloading libfm..."
  # down_catfile ${IMLIB2_URL} | tar -zx --strip 1 -C /tmp/libfm
  branch="--branch=1.3.1" #1.3.2
  branch="--branch=1.4.1" # #ok with automake @alpine315; 2026-11-23 升级(配套 pcmanfm 1.4.0)
  rm -rf /tmp/libfm; gitclone https://gitee.com/g-system/fk-libfm /tmp/libfm $branch
  cd /tmp/libfm
    # FIX: 默认 quick_exec=TRUE（desktop/可执行文件直接执行不弹确认框，2026-11-08）
    git apply /src/v-pcmanfm/libfm-quickexec.patch
    # 2026-11-23 项目场景: 屏蔽 cdrom/usb 侧栏设备（当下及项目用不着，按名称/挂载点过滤）
    git apply /src/v-pcmanfm/libfm-hide-cdrom-usb.patch
    # attempted static link of dynamic object `/usr/lib/libmenu-cache.so'
    #ref_pcmanfm.md>> # 改动态编译：OK
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    # export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

    #
    ##./autogen.sh: line 45: intltoolize: not found  ##1.3.2也不行
    # ./autogen.sh
    bash autogen.sh #错误同上
    # 2026-11-14: --disable-shared --enable-static——libtool 链 libfm-gtk.so 时报
    #   undefined reference to g_module_open: 方案A 后 gdk_pixbuf 的 loader(io-png/jpeg/svg)整链拉入需 g_module_*,
    #   但 gdk-pixbuf-2.0.la 不存在(meson 只产 .a), libtool 无法从 .la 的 dependency_libs 拿到 gmodule
    #   → make LIBS 补的 -lgmodule-2.0 只对 automake 主链接行生效, 不进 libtool .so 的 $deplibs → .so 必 undefined。
    #   库只被静态消费(pcmanfm cp libfm.a/libfm-gtk.a), 直接不产 .so 从源头消掉该链接阶段;
    #   make LIBS 补库仍保留(libfm-pref-apps 等可执行文件链接仍需要)。
    # 2026-11-23: --prefix=$TARGETPATH——PACKAGE_UI_DIR=$(datadir)/libfm/ui、PACKAGE_LOCALE_DIR=$(prefix)/locale
    #   默认编入 /usr/local（builder 路径），部署后 UI/locale 找不到 → 属性框/chooser 崩、菜单英文。
    #   库/头/.pc 仍手动装 /usr/local（build.sh 后段），prefix 只影响 UI/LOCALE 宏编入路径。
    ./configure --disable-shared --enable-static --prefix=$TARGETPATH;

  log "Compiling libfm..."
  # 2026-11-14: 方案A(自动注册)后 gdk_pixbuf loader(io-png/jpeg/svg + gdk-pixbuf-io 的 g_module_*)整链拉入,
  #   libfm-gtk 链接报 undefined(g_module_*/jpeg_*/png_*/rsvg_*)——make LIBS 补依赖(libfm 取 libs 非 --static 不展开 pc private);
  #   CI pcmanfm stage 已踩; 选 b(用户拍板): libfm 链接单点补。
  #   (2026-11-14 再修: --disable-shared 后 make 不再链 libfm-gtk.so, 但 libfm-pref-apps 等 bin_PROGRAMS
  #   动态链 libgtk-x11-2.0.so(apk menu-cache-dev 只有 .so) 仍报 g_module_open——非核心工具, -k 容忍;
  #   库已产出在 .libs/, make install 会因工具失败中断, 改手动 cp .a 到 /usr/local/lib。)
  make -k LDFLAGS="$LDFLAGS" LIBS=" -lgmodule-2.0 -ljpeg -lpng -lrsvg-2 -lcroco-0.6 -lxml2 -llzma" \
    bin_PROGRAMS= pkglib_LTLIBRARIES= 2>&1 \
    || log "make libfm warn (非核心工具 libfm-pref-apps 失败可容忍, 静态库已产出)"

  log "Installing libfm..."
  # make install 因 libfm-pref-apps(工具)失败会中断 src/ 段 → .a 未装; 手动从 .libs/ 拷(静态库已生成)
  cp -a src/.libs/libfm.a src/.libs/libfm-gtk.a src/.libs/libfm-extra.a /usr/local/lib/ \
    || log "manual libfm .a copy warn"
  make install bin_PROGRAMS= >/dev/null 2>&1 || log "make install warn (工具失败可容忍, .a 已手动装)"
  # 2026-11-15 补: make install 因 bin_PROGRAMS(libfm-pref-apps/lxshortcut)失败中断 → 头文件只装了 fm-actions.h;
  #   手动平铺拷全部源码头文件到 /usr/local/include/libfm-1.0/(libfm 头互 include 为平铺式 "fm-xxx.h", 无子目录路径)。
  mkdir -p /usr/local/include/libfm-1.0
  find /tmp/libfm/src -name "*.h" -exec cp -f {} /usr/local/include/libfm-1.0/ \; \
    || log "manual libfm headers copy warn (平铺拷贝)"
  # 2026-11-15 补: make install 中断 → pkg-config .pc 也没装(menu_cache/pcmanfm 的 configure 需 libfm-extra.pc/libfm.pc)——手动拷(prefix=/usr/local 与落点一致)
  mkdir -p /usr/local/lib/pkgconfig
  cp -f /tmp/libfm/libfm.pc /tmp/libfm/libfm-extra.pc /tmp/libfm/libfm-gtk.pc /usr/local/lib/pkgconfig/ \
    || log "manual libfm .pc copy warn"

  \cp -a /usr/local/lib/libfm.a /usr/local/lib/libfm-gtk.a /usr/lib/ ##拷贝两个静态库到/usr/lib

  # 2026-11-23: libfm .pc 是 --prefix=$TARGETPATH 生成的（libdir=$TARGETPATH/lib），但库实际在 /usr/local/lib、
  #   头在 /usr/local/include——pcmanfm configure 用 libfm.pc 会找不到库；sed 修正 prefix 回 /usr/local。
  sed -i "s|$TARGETPATH|/usr/local|g" /usr/local/lib/pkgconfig/libfm.pc /usr/local/lib/pkgconfig/libfm-extra.pc /usr/local/lib/pkgconfig/libfm-gtk.pc 2>/dev/null || true

  log "Install libfm UI (GtkBuilder file-prop.ui/app-chooser.ui 等，PACKAGE_UI_DIR=$TARGETPATH/share/libfm/ui；漏装则属性框/openwith 崩)..."
    mkdir -p $TARGETPATH/share/libfm/ui
    cp -f /tmp/libfm/data/ui/*.ui $TARGETPATH/share/libfm/ui/ 2>/dev/null \
      || log "manual libfm ui copy warn"
    ls $TARGETPATH/share/libfm/ui/ 2>/dev/null | head

  log "Install libfm locale (静态 LOCALEDIR=$TARGETPATH/share/locale；libfm 域=libfm，右键菜单由 libfm 构建，漏装则菜单英文)..."
    if [ -d /tmp/libfm/po ]; then
      for p in /tmp/libfm/po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/libfm.mo 2>/dev/null \
          || log "libfm msgfmt warn: $lang"
      done
      log "libfm locales installed: $(ls /tmp/libfm/po/*.po | wc -l) langs"
    fi

  # 2026-11-14: menu_cache 段编不过——menu-tags.h:22 include <libfm/fm-extra.h>;
  #   libfm 头文件平铺在 /usr/local/include/libfm-1.0/(libfm-extra.pc Cflags=-I/usr/local/include),
  #   无 libfm/ 子目录; 建软链让 libfm/fm-extra.h 可解析(否则 menu_cache 编译 fatal error)。
  #   依赖: libfm 头文件必须先就位(install-pkgincludeHEADERS 由 make install 或手动)。
  mkdir -p /usr/include && ln -sfn /usr/local/include/libfm-1.0 /usr/include/libfm
  ls -la /usr/include/libfm/fm-extra.h /usr/include/libfm/fm-version.h /usr/include/libfm/fm-xml-file.h
}

# lxde/menu-cache
# 
# /usr/bin/x86_64-alpine-linux-musl-ld: menu-compose.o:(.bss+0x30): multiple definition of `verbose'; main.o:(.bss+0x10): first defined here
# clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
# 
# try: 先编译>> atk gdk-pixbuf gtk (错误依旧)
# openbox两个依赖项 (错误依旧) >> 改master (编译OK)
# pango:
# (1/7) Installing cairo-static (1.16.0-r5)
# (2/7) Installing expat-static (2.5.0-r0)
# (3/7) Installing fribidi-static (1.0.11-r0)
# (4/7) Installing glib-static (2.70.5-r0)
# (5/7) Installing graphite2-static (1.3.14-r0)
# (6/7) Installing harfbuzz-static (3.0.0-r2)
# (7/7) Installing libxml2-dev (2.9.14-r2)
# 
function menu_cache(){ ##依赖libfm-extra @libfm
  # apk update; apk add gtk-doc
  # apk x libfm-extra-dev ##可过./configure检查; 但ld -lfm-extra静态库错误

  log "Downloading menu-cache..."
  # branch="--branch=1.1.0" #default master [1.1.0:294commits@ubt2004; master:297commits@ff]
  # repo=$GITHUB/lxde/menu-cache
  branch="--branch=1.1.1" #2026-11-23 升级
  rm -rf /tmp/menu-cache; gitclone https://gitee.com/g-system/fk-menu-cache /tmp/menu-cache $branch
  cd /tmp/menu-cache
    # attempted static link of dynamic object `/usr/local/lib/libfm-extra.so'
    export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    ./autogen.sh 
    ./configure --enable-static; 

  log "Compiling menu-cache..."
  make

  log "Installing menu-cache..."
  make install

  find /usr/local/lib |grep "menu-cache.*\.a$"
  cp /usr/local/lib/libmenu-cache.a /usr/lib/
}

#
# Build pcmanfm
#
# 
# checking whether the C compiler works... no
# configure: error: in `/tmp/pcmanfm':
# configure: error: C compiler cannot create executables
# See `config.log' for more details
# 
# export TARGETPATH=/usr/local/static/pcmanfm
# LDFLAGS去 -static （一样错误）
# 
# 检查静态库;
# bash-5.1# find /usr/lib |grep pango |grep "\.a$"
# /usr/lib/libpangoxft-1.0.a
# /usr/lib/libpango-1.0.a
# /usr/lib/libpangocairo-1.0.a
# /usr/lib/libpangoft2-1.0.a
# 
# bash-5.1# find /usr/lib |egrep "g.*bject-2.0.a"
# /usr/lib/libgobject-2.0.a #少了gmodule-2.0
# 
# bash-5.1# find /usr/lib |grep Xcomposite
# /usr/lib/libXcomposite.so.1  #无静态库
# /usr/lib/libXcomposite.so.1.0.0
# # bash-5.1# apk x libxcomposite-dev
# (1/1) Installing libxcomposite-dev (0.4.5-r0)
# OK: 935 MiB in 321 packages
# bash-5.1# find /usr/lib |grep Xcomposite
# /usr/lib/libXcomposite.a
# 
function pcmanfm(){
  # libxcomposite-dev ##装后，手动configure:  C compiler cannot create executables错误过了;
  # apk update; apk add fontconfig-static libxcomposite-dev

  log "Downloading PCMANFM..."
  rm -rf /tmp/pcmanfm; # mkdir -p /tmp/pcmanfm
  # down_catfile ${PCMANFM_URL} | tar -zx --strip 1 -C /tmp/pcmanfm
  branch="--branch=1.4.0" #2026-11-23 升级
  rm -rf /tmp/pcmanfm; gitclone https://gitee.com/g-system/fk-pcmanfm /tmp/pcmanfm $branch #;
  log "Configuring PCMANFM..."
  cd /tmp/pcmanfm #&& ./bootstrap;
    # FIX: 静态链接修复 (2026-11-05): 信号pipe读端非阻塞(问题3 SIGTERM不杀) + GTK类型强制注册(问题1+2 GtkBuilder加载失败)
    git apply /src/v-pcmanfm/pcmanfm-staticfix.patch
    # FIX: 中文 localedir (2026-11-06): Makefile.am 硬编码 PACKAGE_LOCALE_DIR=$(prefix)/share/locale, 忽略 --localedir
    git apply /src/v-pcmanfm/pcmanfm-localedir.patch
    # 正式出包默认 strip；调试时 PCMANFM_DEBUG=1 跳过 strip 保留符号（便于 gdb 验证）(2026-11-05)
    if test -n "$PCMANFM_DEBUG"; then
      export LDFLAGS="-Wl,--as-needed"
    else
      export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
    fi
    ./autogen.sh
    # ./configure  --enable-static --prefix=$TARGETPATH
    # make
    # make LDFLAGS="-static --static -lImlib2 -L/usr/local/lib -lX11-xcb -lxcb-shm $OB_LIBS"
    # 
    # --enable-static --prefix=$TARGETPATH
    #  --enable-static
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -lmenu-cache -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    ex1="-lfontconfig -lgio-2.0 -lcairo    -lfm -lfm-gtk -lXdamage "
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"
    LIBS="$LIBS0" ./configure --prefix=$TARGETPATH --localedir=$TARGETPATH/share/locale

  log "Compiling PCMANFM..."
    # # x86_64-alpine-linux-musl/bin/ld: cannot find -lXdamage
    # make LDFLAGS="-static " 2>&1
    # # build.sh>> 手动make @tmux-8 OK;
    # # bash-5.1# ls src/pcmanfm -lh
    # # -rwxr-xr-x    1 root     root       37.6M Dec  1 04:16 src/pcmanfm
    # 
    # 正式出包默认 strip；调试时 PCMANFM_DEBUG=1 跳过 strip 保留符号（便于 gdb 验证）(2026-11-05)
    if test -n "$PCMANFM_DEBUG"; then
      log "PCMANFM DEBUG build (keep symbols for gdb)"
      LDFLAGS_MK="-static"
    else
      log "PCMANFM release build (strip)"
      LDFLAGS_MK="-static -Wl,--strip-all"
    fi
    make LDFLAGS="$LDFLAGS_MK" \
      LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -Wl,--end-group" 2>&1 \
      || { log "PCMANFM build FAILED"; exit 1; }

  log "Install PCMANFM..."
    # make;
    make install 2>&1 > /dev/null

  log "Install PCMANFM locale (静态 LOCALEDIR=$TARGETPATH/share/locale；po/ 各 .po 由 msgfmt 转 .mo——make 默认只产 .o，po 未生成 .mo，手装才带中文)..."
    if [ -d /tmp/pcmanfm/po ]; then
      for p in /tmp/pcmanfm/po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/pcmanfm.mo 2>/dev/null \
          || log "msgfmt warn: $lang"
      done
      log "locales installed: $(ls /tmp/pcmanfm/po/*.po | wc -l) langs"
    fi

  # view
  ls -lh $TARGETPATH/bin/pcmanfm
  # FIX: 产包需含UI(问题1+2): make install已装到TARGETPATH/share/pcmanfm/ui; 打包时须整体拷贝TARGETPATH(含share)
  ls $TARGETPATH/share/pcmanfm/ui/
  xx-verify --static $TARGETPATH/bin/pcmanfm #/tmp/pcmanfm/src/pcmanfm
}

function apkdeps(){
  apk update; 
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      menu-cache-dev gtk+2.0-dev menu-cache-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec atk || exit 1
    doExec gdk-pixbuf || exit 1
    doExec gtk || exit 1 ##long-cost: 共历时766秒 (比首次手动长??)
    doExec libfm || exit 1
    doExec menu_cache || exit 1
    doExec pcmanfm || exit 1
    ;;
b_deps)
    # bash /src/openbox/build.sh apkdeps
    # bash /src/openbox/build.sh pango & ##needed by gtk
    # bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    # bash /src/xcompmgr/build.sh Xdamage &
    # wait
    # # 
    apkdeps
    # bash /src/v-pcmanfm/build.sh atk & #needed by gtk
    # bash /src/v-pcmanfm/build.sh gdk-pixbuf & #needed by gtk
    # wait
    # bash /src/v-pcmanfm/build.sh gtk
    doExec bash /src/v-pcmanfm/build.sh libfm || exit 1
    doExec bash /src/v-pcmanfm/build.sh menu_cache || exit 1 #在libfm之后

    # view x8; +libgdk
    # lost: Xrandr, atk, gtk
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk|libfm|menu-cache" |grep "\.a$" |sort
    # /usr/lib/libXdamage.a
    # /usr/lib/libXrandr.a
    # /usr/lib/libatk-1.0.a
    # /usr/lib/libfm-gtk.a
    # /usr/lib/libfm.a
    # /usr/lib/libgdk_pixbuf-2.0.a
    # /usr/lib/libgtk-x11-2.0.a
    # /usr/lib/libmenu-cache.a
    # /usr/lib/libpango-1.0.a
    # /usr/lib/libpangocairo-1.0.a
    # /usr/lib/libpangoft2-1.0.a
    # /usr/lib/libpangoxft-1.0.a
    ;;
*) #compile
    oneBuild $1
    ;;          
esac

# dbg:
# # root@tenvm2:~# docker run -it --rm --privileged -v /mnt:/mnt2 infrastlabs/x11-base:builder bash
# apk add gawk git
# cd /mnt2/docker-x11base/compile/
# ln -s $(pwd)/src /src
# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
# git pull; bash src/v-pcmanfm/build.sh b_deps
# export TARGETPATH=${TARGETPATH:-/usr/local/static/pcmanfm}
# bash src/v-pcmanfm/build.sh pcmanfm

# # #gtk全部构建>> build.sh pcmanfm>> 生成pcmanfm静态文件成功
# # >>> Install PCMANFM...
# -rwxr-xr-x    1 root     root       37.1M Dec  1 19:23 /opt/base/bin/pcmanfm

# # 单独再重试，pcmanfm又出现依赖错: 
# # gdkscreen-x11.c:(.text+0xd69): undefined reference to `XineramaQueryScreens'
# # libgdk-x11-2.0.a(gdkscreen-x11.o): in function `_gdk_x11_screen_size_changed'

