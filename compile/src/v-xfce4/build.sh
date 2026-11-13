#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-xfce4}"
source /src/common.sh

#
# v-xfce4 多模块静态构建（GTK2，模块参数调用：xfce4settings/thunar/ristretto）
#
# 依赖（静态库，需先就位）：
#   xfce 库栈：libxfce4util/xfconf/libxfce4ui/libxfce4kbd-private-2/exo-1/garcon（impl02 §3-4）
#   dbus/dbus-glib（impl02 §1-2）+ u-gtk GTK2 静态树 + xorg 栈
# 静态链：手动 xx-clang -static（impl02 §5.4 库集，--start-group 全组）
# 中文方案 A：make localedir=/usr/share/locale 命令行覆盖（Makefile.am 用 $(localedir)；
#             --localedir configure 无效——configure.ac 未 AC_SUBST(localedir)，impl02 §5.8）
# patch：xfce4settings-gtkbuilder-types.patch（gtk_builder 静态链类型注册坑，impl02 §5.6）
#        thunar/ristretto 用 GtkUIManager 内嵌 .xml（exo-csource→.ui.h），无 GtkBuilder，不需 patch
#
# 2026-11-06 重构：模块化。thunar 1.6.3 / ristretto 0.8.5 同为 GTK2 最后版，共享 xfce 库栈。
#   - thunar：libthunarx 内链；全插件 disable（tpa/uca/wallpaper/apr/sbr）；GtkUIManager 内嵌 UI
#   - ristretto：前置 libexif 静态库（Alpine 无 -static 包，源码自建）；UI 手写+UIManager 内嵌
#   - 两者均：disable 可选依赖（exif/notify/gudev/startup-notification），LOCALEDIR 方案 A
#
PKGCONF="/usr/local/static/xfce/lib/pkgconfig:/usr/local/static/exif/lib/pkgconfig:/usr/local/static/dbus/lib/pkgconfig:/usr/local/static/dbus-glib/lib/pkgconfig"

# 静态链库集（thunar/ristretto 共用；含 -lexif 对 thunar 无害——未引用不拉入）
static_gtk_libs() {
  LIBS="-L/usr/local/static/xfce/lib -L/usr/local/static/exif/lib -L/usr/local/static/dbus/lib -L/usr/local/static/dbus-glib/lib -L/usr/local/lib"
  LIBS="$LIBS -Wl,--start-group -lexo-1 -lxfce4ui-1 -lxfconf-0 -lxfce4util -lexif -ldbus-glib-1 -ldbus-1"
  LIBS="$LIBS -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0"
  LIBS="$LIBS -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lgthread-2.0 -lgmodule-2.0 -lcairo -lfontconfig -lfreetype"
  LIBS="$LIBS -lXrender -lX11 -lXft -lXrandr -lintl -lfribidi -lharfbuzz -lexpat -lpthread -ldl -lm"
  LIBS="$LIBS -lgraphite2 -lXext -lXfixes -lXdamage -lXcomposite -lxcb -lXau -lXdmcp -lz -lbz2 -lpng16 -lbrotlidec -lbrotlicommon"
  LIBS="$LIBS -lpcre -lpixman-1 -luuid -lffi -lmount -lblkid -lrsvg-2 -lcroco-0.6 -lxml2"
  LIBS="$LIBS -lXcursor -lXinerama -llzma -ljpeg -lbsd -lmd"
  LIBS="$LIBS -Wl,--end-group"
}

# 源码 tarball 获取（archive.xfce.org 文件名区分大小写；libexif 走 github releases——容器内 github
# 偶发不通，但 .a 已装则跳过下载）
fetch_src() { # name url
  local name=$1 url=$2
  if test -d /tmp/xfce-build/$name; then
    log "source present, skip download"
  else
    mkdir -p /tmp/xfce-build
    local TARBALL=$TARGETPATH/../.cache/$name.tar.bz2
    mkdir -p $(dirname "$TARBALL")
    test -s $TARBALL || down_catfile "$url" > $TARBALL
    tar xjf $TARBALL -C /tmp/xfce-build || { log "TARBALL EXTRACT FAILED: $name"; exit 1; }
  fi
}

function xfce4settings(){
  local VER=4.12.4
  local SRC=/tmp/xfce-build/xfce4-settings-$VER

  log "Download xfce4-settings..."
  if test -d $SRC; then
    log "source present, skip download"
  else
    mkdir -p /tmp/xfce-build
    TARBALL=$TARGETPATH/../.cache/xfce4-settings-$VER.tar.bz2
    mkdir -p $(dirname "$TARBALL")
    test -s $TARBALL || down_catfile https://archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-$VER.tar.bz2 > $TARBALL
    tar xjf $TARBALL -C /tmp/xfce-build
  fi

  # gtkbuilder 静态链类型注册 patch（force-register glade 用到的 GType，避免 -O2+gc-sections 弃值被优化）
  PATCH_DIR=$(dirname "$0")
  if grep -q "force-register types" $SRC/dialogs/accessibility-settings/main.c; then
    log "gtkbuilder types patch already applied"
  else
    log "Apply gtkbuilder types patch..."
    patch -p1 -d $SRC < "$PATCH_DIR/xfce4settings-gtkbuilder-types.patch" || { log "GTKBUILDER PATCH FAILED"; exit 1; }
  fi

  # xfconf-free 直接应用 patch：xfce4-display-settings 免 xfsettingsd/xfconf daemon 依赖
  # （xfce_randr_apply_native 直接 XRRSetCrtcConfig；无 daemon 时降级不崩溃，仅硬件应用）
  if grep -q "xfce_randr_apply_native" $SRC/dialogs/display-settings/xfce-randr.c; then
    log "xfconf-free patch already applied"
  else
    log "Apply xfconf-free patch..."
    patch -p1 -d $SRC < "$PATCH_DIR/xfce4settings-xfconf-free.patch" || { log "XFCONF-FREE PATCH FAILED"; exit 1; }
  fi

  log "Configure..."
  cd $SRC
  ./configure --prefix=$TARGETPATH --enable-static --disable-shared \
    --disable-nls --disable-gtk-doc --disable-libnotify \
    LDFLAGS="$LDFLAGS" \
    PKG_CONFIG_PATH="/usr/local/static/xfce/lib/pkgconfig:/usr/local/static/dbus/lib/pkgconfig:/usr/local/static/dbus-glib/lib/pkgconfig" \
    || { log "CONFIGURE FAILED"; exit 1; }

  log "Make (逐子目录 localedir=/usr/share/locale；CCLD 动态链 libICE.la 缺失可容错，只用 .o)..."
  # 其余 9 个二进制屏蔽（只留 xfce4-display-settings），注释保留不删——需要时取消注释并入 for 列表：
  # for d in xfsettingsd xfce4-settings-editor xfce4-settings-manager \
  #          dialogs/display-settings dialogs/appearance-settings dialogs/keyboard-settings \
  #          dialogs/mime-settings dialogs/mouse-settings dialogs/accessibility-settings; do
  for d in dialogs/display-settings; do
    make -C $d clean localedir=/usr/share/locale >/dev/null 2>&1 || true
    make -C $d localedir=/usr/share/locale 2>&1 || log "make $d CCLD failed (expected, objects built)"
  done

  log "Static-link 1 binary (xx-clang -static)..."
  mkdir -p $TARGETPATH/bin
  LIBS="-L/usr/local/static/xfce/lib -L/usr/local/static/dbus/lib -L/usr/local/static/dbus-glib/lib -L/usr/local/lib"
  LIBS="$LIBS -Wl,--start-group -lexo-1 -lgarcon-gtk2-1 -lgarcon-1 -lxfce4ui-1 -lxfce4kbd-private-2 -lxfconf-0 -lxfce4util -ldbus-glib-1 -ldbus-1"
  LIBS="$LIBS -lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0"
  LIBS="$LIBS -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lgthread-2.0 -lcairo -lfontconfig -lfreetype"
  LIBS="$LIBS -lXrender -lX11 -lXft -lXrandr -lintl -lfribidi -lharfbuzz -lexpat -lpthread -ldl -lm"
  LIBS="$LIBS -lgraphite2 -lXext -lXfixes -lXdamage -lXcomposite -lxcb -lXau -lXdmcp -lz -lbz2 -lpng16 -lbrotlidec -lbrotlicommon"
  LIBS="$LIBS -lpixman-1 -luuid -lpcre -lffi -lmount -lblkid -lgmodule-2.0 -lrsvg-2 -lcroco-0.6 -lxml2"
  LIBS="$LIBS -lXcursor -lXinerama -llzma -ljpeg -lbsd -lmd"
  LIBS="$LIBS -Wl,--end-group"

  link_bin() { # dir out objs...
    local dir=$1 out=$2; shift 2
    ( cd $SRC/$dir && xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/$out "$@" $LIBS ) \
      || { log "STATIC LINK FAILED: $out"; exit 1; }
    log "OK: $out"
  }

  link_bin dialogs/display-settings xfce4-display-settings \
    xfce4_display_settings-main.o xfce4_display_settings-display-name.o xfce4_display_settings-edid-parse.o \
    xfce4_display_settings-foo-marshal.o xfce4_display_settings-scrollarea.o xfce4_display_settings-xfce-randr.o
  # 其余 9 个二进制 link_bin 屏蔽（注释保留不删，需要时取消注释）：
  # link_bin xfsettingsd xfsettingsd \
  #   xfsettingsd-main.o xfsettingsd-accessibility.o xfsettingsd-debug.o xfsettingsd-clipboard-manager.o \
  #   xfsettingsd-gtk-decorations.o xfsettingsd-keyboards.o xfsettingsd-keyboard-shortcuts.o \
  #   xfsettingsd-keyboard-layout.o xfsettingsd-pointers.o xfsettingsd-workspaces.o xfsettingsd-xsettings.o \
  #   xfsettingsd-displays.o
  # link_bin xfce4-settings-editor xfce4-settings-editor \
  #   xfce4_settings_editor-main.o xfce4_settings_editor-xfce-settings-cell-renderer.o \
  #   xfce4_settings_editor-xfce-settings-editor-box.o xfce4_settings_editor-xfce-settings-marshal.o \
  #   xfce4_settings_editor-xfce-settings-prop-dialog.o
  # link_bin xfce4-settings-manager xfce4-settings-manager \
  #   xfce4_settings_manager-main.o xfce4_settings_manager-xfce-settings-manager-dialog.o \
  #   xfce4_settings_manager-xfce-text-renderer.o
  # link_bin dialogs/appearance-settings xfce4-appearance-settings xfce4_appearance_settings-main.o
  # link_bin dialogs/keyboard-settings xfce4-keyboard-settings \
  #   xfce4_keyboard_settings-main.o xfce4_keyboard_settings-command-dialog.o xfce4_keyboard_settings-xfce-keyboard-settings.o
  # link_bin dialogs/mime-settings xfce4-mime-settings \
  #   xfce4_mime_settings-main.o xfce4_mime_settings-xfce-mime-chooser.o xfce4_mime_settings-xfce-mime-window.o
  # link_bin dialogs/mouse-settings xfce4-mouse-settings xfce4_mouse_settings-main.o
  # link_bin dialogs/accessibility-settings xfce4-accessibility-settings xfce4_accessibility_settings-main.o
  # link_bin dialogs/accessibility-settings xfce4-find-cursor xfce4_find_cursor-find-cursor.o

  log "Verify (xx-verify --static)..."
  # 其余 9 个二进制 verify 屏蔽（注释保留不删，需要时取消注释）：
  # for b in xfsettingsd xfce4-settings-editor xfce4-settings-manager xfce4-display-settings \
  #          xfce4-appearance-settings xfce4-keyboard-settings xfce4-mime-settings xfce4-mouse-settings \
  #          xfce4-accessibility-settings xfce4-find-cursor; do
  for b in xfce4-display-settings; do
    xx-verify --static $TARGETPATH/bin/$b || { log "xx-verify FAILED: $b"; exit 1; }
  done
  log "All 1 binary static verified"
}

function libexif(){
  local VER=0.6.23
  local SRC=/tmp/xfce-build/libexif-$VER
  local PREFIX=/usr/local/static/exif
  if test -f $PREFIX/lib/libexif.a; then
    log "libexif.a present, skip"
    return
  fi
  log "Download libexif..."
  fetch_src libexif-$VER "https://github.com/libexif/libexif/releases/download/v$VER/libexif-$VER.tar.bz2"
  log "Configure libexif (xx-clang static)..."
  cd $SRC
  CC=xx-clang CFLAGS="$CFLAGS" ./configure --prefix=$PREFIX --enable-static --disable-shared --disable-nls \
    || { log "LIBEXIF CONFIGURE FAILED"; exit 1; }
  make 2>&1 || { log "LIBEXIF BUILD FAILED"; exit 1; }
  make install 2>&1 || { log "LIBEXIF INSTALL FAILED"; exit 1; }
  test -f $PREFIX/lib/libexif.a || { log "libexif.a not produced"; exit 1; }
  log "libexif static installed"
}

function thunar(){
  local VER=1.6.3
  local SRC=/tmp/xfce-build/Thunar-$VER
  local PREFIX=/usr/local/static/thunar

  log "Download Thunar (文件名大写 T)..."
  fetch_src Thunar-$VER "https://archive.xfce.org/src/xfce/thunar/1.6/Thunar-$VER.tar.bz2"

  PATCH_DIR=$(dirname "$0")
  log "Apply static patches (D-Bus 名隔离 + UCA 内置注册)..."
  if grep -q "org.xfce.Thunar.static" $SRC/thunar/thunar-dbus-service.c; then
    log "thunar-static-dbus.patch already applied"
  else
    patch -p1 -d $SRC < "$PATCH_DIR/thunar-static-dbus.patch" || { log "THUNAR DBUS PATCH FAILED"; exit 1; }
  fi
  if grep -q "THUNARX_STATIC_UCA" $SRC/thunarx/thunarx-provider-factory.c; then
    log "thunar-static-uca.patch already applied"
  else
    patch -p1 -d $SRC < "$PATCH_DIR/thunar-static-uca.patch" || { log "THUNAR UCA PATCH FAILED"; exit 1; }
  fi

  log "Configure (disable 可选依赖；UCA 插件启用并内置静态注册；GTK2 最后一版，GtkUIManager 内嵌 .xml)..."
  cd $SRC
  ./configure --prefix=$PREFIX --enable-static --disable-shared \
    --disable-exif --disable-notifications --disable-gudev --disable-startup-notification \
    --disable-tpa-plugin --disable-wallpaper-plugin --disable-apr-plugin --disable-sbr-plugin \
    --disable-gtk-doc \
    CFLAGS="$CFLAGS -DTHUNARX_STATIC_UCA" \
    LDFLAGS="$LDFLAGS" PKG_CONFIG_PATH="$PKGCONF" \
    || { log "THUNAR CONFIGURE FAILED"; exit 1; }

  log "Build libthunarx..."
  make -C thunarx 2>&1 || { log "THUNARX BUILD FAILED"; exit 1; }

  log "Make thunar (localedir=/usr/share/locale；CCLD 动态链 libICE.la 缺失可容错，只用 .o)..."
  make -C thunar clean localedir=/usr/share/locale >/dev/null 2>&1 || true
  make -C thunar localedir=/usr/share/locale 2>&1 || log "make thunar CCLD failed (expected, objects built)"

  log "Build UCA plugin objects (static 内链)..."
  UCA_OBJS=""
  UCA_CFLAGS="-DHAVE_CONFIG_H -DTHUNARX_STATIC_UCA -I$SRC -I$SRC/plugins \
    -DBINDIR=\"/usr/bin\" -DPACKAGE_LOCALE_DIR=\"/usr/share/locale\" -DDATADIR=\"/usr/share\" \
    $(PKG_CONFIG_PATH="$PKGCONF" pkg-config --cflags exo-1 libxfce4ui-1 libxfce4util-1.0)"
  mkdir -p /tmp/thunar-uca-obj
  for f in $SRC/plugins/thunar-uca/*.c; do
    b=$(basename $f .c)
    xx-clang -c $f -o /tmp/thunar-uca-obj/$b.o $UCA_CFLAGS || { log "UCA OBJ FAILED: $b"; exit 1; }
    UCA_OBJS="$UCA_OBJS /tmp/thunar-uca-obj/$b.o"
  done

  log "Static-link thunar (libthunarx + UCA 内链；UCA 对象放 --start-group 内解决跨库符号顺序)..."
  mkdir -p $PREFIX/bin
  static_gtk_libs
  ( cd $SRC/thunar && xx-clang -static -Wl,--strip-all -o $PREFIX/bin/thunar \
      *.o -Wl,--start-group $UCA_OBJS ../thunarx/.libs/libthunarx-2.a -Wl,--end-group $LIBS ) \
    || { log "THUNAR STATIC LINK FAILED"; exit 1; }

  log "Install data (desktop/pixmaps/thunar-settings script, best-effort)..."
  make -C $SRC/thunar install-data >/dev/null 2>&1 || log "thunar install-data warn"

  log "Verify..."
  xx-verify --static $PREFIX/bin/thunar || { log "THUNAR xx-verify FAILED"; exit 1; }
  log "thunar 1.6.3 static verified"
}

function ristretto(){
  local VER=0.8.5
  local SRC=/tmp/xfce-build/ristretto-$VER
  local PREFIX=/usr/local/static/ristretto

  libexif   # 前置：ristretto 必需 libexif>=0.6.0

  log "Download ristretto..."
  fetch_src ristretto-$VER "https://archive.xfce.org/src/apps/ristretto/0.8/ristretto-$VER.tar.bz2"

  # xfconf-free patch：xfconf_init 判返回值 + channel 判有效（无 xfconf daemon 时降级内存默认值不段错误；
  # 有 xfconf 时保留持久化）。另含 gio-dbus 保护：thumbnailer/filemanager proxy 判空（无 dbus 会话总线时
  # 缩略图/属性对话框降级不崩）。文件：main/settings/xfce_wallpaper_manager/thumbnailer/main_window + util.h extern xfconf_ok
  PATCH_DIR=$(dirname "$0")
  if grep -q "xfconf_ok" $SRC/src/main.c; then
    log "ristretto xfconf-free patch already applied"
  else
    log "Apply ristretto xfconf-free patch..."
    patch -p1 -d $SRC < "$PATCH_DIR/ristretto-xfconf-dbus-free.patch" || { log "RISTRETTO XFCONF-FREE PATCH FAILED"; exit 1; }
  fi

  log "Configure ristretto (UI 手写+UIManager 内嵌 .xml，无 GtkBuilder；nls 保留)..."
  cd $SRC
  ./configure --prefix=$PREFIX LDFLAGS="$LDFLAGS" PKG_CONFIG_PATH="$PKGCONF" \
    || { log "RISTRETTO CONFIGURE FAILED"; exit 1; }

  log "Make src (localedir=/usr/share/locale；链接失败可容错——pixman/pcre 手工链才给，只用 .o)..."
  make -C src clean localedir=/usr/share/locale >/dev/null 2>&1 || true
  make -C src localedir=/usr/share/locale 2>&1 || log "make src CCLD failed (expected, objects built)"

  log "Static-link ristretto..."
  mkdir -p $PREFIX/bin
  static_gtk_libs
  ( cd $SRC/src && xx-clang -static -Wl,--strip-all -o $PREFIX/bin/ristretto *.o $LIBS ) \
    || { log "RISTRETTO STATIC LINK FAILED"; exit 1; }

  log "Install data (desktop/icons, best-effort)..."
  make -C $SRC install-data >/dev/null 2>&1 || log "ristretto install-data warn"

  log "Verify..."
  xx-verify --static $PREFIX/bin/ristretto || { log "RISTRETTO xx-verify FAILED"; exit 1; }
  log "ristretto 0.8.5 static verified"
}

# 构建单个 xfce 库到 /usr/local/static/xfce（参考 libexif 模式；xfce 库栈 util→conf→ui→exo→garcon 依赖序）。
# $1=name-ver $2=url $3=检查相对 lib/ 的 .a $4..=configure 额外参数。
function xfce_lib(){
  local NV=$1 URL=$2 CHECK=$3; shift 3
  local PREFIX=/usr/local/static/xfce
  if test -f $PREFIX/lib/$CHECK; then log "xfce $NV present, skip"; return; fi
  log "Fetch xfce $NV..."
  fetch_src $NV "$URL"
  local SRC=/tmp/xfce-build/$NV
  log "Configure xfce $NV (xx-clang static)..."
  cd $SRC
  CC=xx-clang CFLAGS="$CFLAGS" ./configure --prefix=$PREFIX --enable-static --disable-shared "$@" \
    || { log "XFCE CONFIGURE FAILED: $NV"; exit 1; }
  # make/install 允许失败：xfce 包常含 daemon（如 xfconfd），其链接需 pcre/ffi，
  # thunar/ristretto 只需库本身。真正的闸门是下方 $CHECK 存在性检查。
  make -j$(nproc) >/dev/null 2>&1 || log "XFCE MAKE WARN: $NV (daemon/subtarget 失败，继续)"
  make install >/dev/null 2>&1 || log "XFCE INSTALL WARN: $NV"
  test -f $PREFIX/lib/$CHECK || { log "XFCE CHECK FAILED: $NV ($CHECK)"; exit 1; }
  log "xfce $NV installed"
}

case "$1" in
cache)
    ;;
b_deps)
    # gtk2 静态库：确保最新（base 镜像 builder-gtk224 可能旧，u-gtk 有更新则重编）。
    doExec ensure_gtk_libs || exit 1
    # dbus / dbus-glib（xfce 库栈与 app 静态链依赖，x-dbus 建到 /usr/local/static/dbus[/-glib]）。
    # 注意：x-dbus 的 ${TARGETPATH:-...} 回退会被 common.sh 默认(static_temp1)/调用方污染——必须显式传对。
    # 注意：TARGETPATH=... doExec func 不生效(dash 函数前缀 env 不传到子进程)，故经 env 显式传（env 前缀在 doExec 内仍会 word-split，但 TARGETPATH=... 无空格，安全）。
    if ! test -f /usr/local/static/dbus/lib/libdbus-1.a; then
      doExec env TARGETPATH=/usr/local/static/dbus sh /src/x-dbus/build.sh dbus || exit 1
    fi
    if ! test -f /usr/local/static/dbus-glib/lib/libdbus-glib-1.a; then
      doExec env TARGETPATH=/usr/local/static/dbus-glib sh /src/x-dbus/build.sh dbus_glib || exit 1
    fi
    # xfce 库栈（依赖序；xfconf 起需 pc 链：xfce + dbus + dbus-glib）。
    export PKG_CONFIG_PATH="/usr/local/static/xfce/lib/pkgconfig:/usr/local/static/dbus/lib/pkgconfig:/usr/local/static/dbus-glib/lib/pkgconfig"
    doExec xfce_lib libxfce4util-4.12.1 "https://archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2" libxfce4util.a --disable-nls --disable-gtk-doc || exit 1
    doExec xfce_lib xfconf-4.12.1 "https://archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2" libxfconf-0.a --disable-nls --disable-perl-bindings || exit 1
    doExec xfce_lib libxfce4ui-4.12.1 "https://archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2" libxfce4ui-1.a --disable-nls --disable-gtk3 --disable-startup-notification --disable-gladeui || exit 1
    doExec xfce_lib exo-0.10.6 "https://archive.xfce.org/src/xfce/exo/0.10/exo-0.10.6.tar.bz2" libexo-1.a --disable-nls || exit 1
    doExec xfce_lib garcon-0.4.0 "https://archive.xfce.org/src/xfce/garcon/0.4/garcon-0.4.0.tar.bz2" libgarcon-1.a --disable-nls || exit 1
    # libexif（thunar/ristretto 需要）。
    doExec libexif || exit 1
    ;;
full)
    ;;
*) #compile
    oneBuild $1
    ;;
esac
