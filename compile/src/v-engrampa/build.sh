#!/bin/sh
set -e
source /src/common.sh

#
# Build engrampa (MATE 压缩管理器, GTK2 最后一版 1.14.1)
#
# 依赖: gtk+-2.0/glib-2.0/gthread-2.0/gio-unix-2.0 (u-gtk 静态树已就位)
# 需 --disable-caja-actions (本项目无 caja/MATE 文件管理器, 否则 PKG_CHECK 报错)
# 参考 lxtask 静态链接 (LIBS0 含 rsvg/croco 供 gdk-pixbuf 内置 svg loader)
function engrampa(){
  ENGRAMPA_VER=1.14.1

  # autogen 硬性依赖 mate-autogen(mate-common)/yelp-build(yelp-tools)/itstool，缺则 ./autogen.sh 静默失败→无 configure
  # （2026-11-13 修复：构建环境须装；幂等，已装则 no-op）
  apk add mate-common yelp-tools itstool >/dev/null 2>&1
  which mate-autogen >/dev/null || { log "mate-autogen MISSING (apk add mate-common)"; exit 1; }

  log "Downloading ENGRAMPA..."
  if test -d /tmp/engrampa/.git; then
    log "engrampa source already present, skip clone"
  else
    rm -rf /tmp/engrampa
    branch="--branch=v$ENGRAMPA_VER"
    git clone --depth=1 $branch $GITHUB/mate-desktop/engrampa /tmp/engrampa
  fi

  # apply glib g_ptr_array_copy dead-code patch (系统 glib>=2.32 三参 API 与 engrampa 自带单参冲突)
  PATCH_DIR=$(dirname "$0")
  if grep -q "g_ptr_array_copy             (GPtrArray" /tmp/engrampa/src/glib-utils.h; then
    log "Apply glib-g_ptr_array_copy patch..."
    patch -p1 -d /tmp/engrampa < "$PATCH_DIR/engrampa-1.14.1-glib-g_ptr_array_copy.patch" || { log "PATCH FAILED"; exit 1; }
  else
    log "glib-g_ptr_array_copy patch already applied"
  fi

  # apply localedir patch: configure.ac 硬编码 LOCALEDIR=${prefix}/share/locale, 忽略 --localedir
  # 改 ${localedir} 使 --localedir=/usr/share/locale 生效 (静态版中文/多语言路径)
  if grep -q 'AC_DEFINE_UNQUOTED(LOCALEDIR, "${ac_default_prefix}/' /tmp/engrampa/configure.ac; then
    log "Apply localedir patch..."
    patch -p1 -d /tmp/engrampa < "$PATCH_DIR/engrampa-1.14.1-localedir.patch" || { log "LOCALEDIR PATCH FAILED"; exit 1; }
  else
    log "localedir patch already applied"
  fi

  # 去重复全局定义：main.c 重定义了 fr-init.h 已 extern 的 WindowList/ForceDirectoryCreation
  # （fr-init.c 已定义）→ 静态链 multiple definition；去掉定义即可免 --allow-multiple-definition。
  if grep -qE 'WindowList[[:space:]]*=[[:space:]]*NULL' /tmp/engrampa/src/main.c; then
    log "Apply dup-globals patch..."
    patch -p1 -d /tmp/engrampa < "$PATCH_DIR/engrampa-dup-globals.patch" || { log "DUP-GLOBALS PATCH FAILED"; exit 1; }
  else
    log "dup-globals patch already applied"
  fi

  log "Configuring ENGRAMPA..."
  cd /tmp/engrampa
  ./autogen.sh
  ./configure --prefix=$TARGETPATH \
    --enable-static --disable-shared \
    --disable-caja-actions \
    --disable-packagekit \
    --localedir=/usr/share/locale

  # ref pcmanfm/lxtask 式 GTK2 静态链
  OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
  ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
  ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
  LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  log "Make ENGRAMPA (objects + 辅助二进制)..."
  # FR_LIBS(pkg-config 非 static)在 LDADD 且 --start-group 之外, 会让 gtk 依赖链断;
  # 置空让 gtk/glib/X 全走下方 LIBS0 组。libtool 会把 --start-group 拆散(group 失效),
  # engrampa 主程序 libtool 链接必失败 → 容错继续(仅编译 objects + commands 二进制)。
  make LDFLAGS="$LDFLAGS" \
    FR_LIBS="" \
    LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group" 2>&1 \
    || log "make libtool link engrampa failed (expected), objects should be built"

  log "Static-link engrampa binary (direct, xx-clang -static)..."
  cd /tmp/engrampa/src
  mkdir -p $TARGETPATH/bin
  test -f ../copy-n-paste/.libs/libeggsmclient.a || { log "libeggsmclient.a MISSING"; exit 1; }
  xx-clang -static -Wl,--strip-all -o $TARGETPATH/bin/engrampa \
    actions.o dlg-add-files.o dlg-add-folder.o dlg-ask-password.o dlg-batch-add.o \
    dlg-delete.o dlg-extract.o dlg-new.o dlg-open-with.o dlg-package-installer.o \
    dlg-password.o dlg-prop.o dlg-update.o eggfileformatchooser.o eggtreemultidnd.o \
    file-data.o file-utils.o fr-archive.o fr-command.o fr-command-ace.o fr-command-alz.o \
    fr-command-ar.o fr-command-arj.o fr-command-cfile.o fr-command-cpio.o fr-command-dpkg.o \
    fr-command-iso.o fr-command-jar.o fr-command-lha.o fr-command-rar.o fr-command-rpm.o \
    fr-command-tar.o fr-command-unstuff.o fr-command-zip.o fr-command-lrzip.o fr-command-zoo.o \
    fr-command-7z.o fr-error.o fr-init.o fr-list-model.o fr-stock.o fr-proc-error.o \
    fr-process.o fr-window.o gio-utils.o glib-utils.o gtk-utils.o java-utils.o open-file.o \
    preferences.o rar-utils.o fr-marshal.o fr-enum-types.o main.o \
    ../copy-n-paste/.libs/libeggsmclient.a \
    -L/usr/local/lib -lm \
    -Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group \
    || { log "ENGRAMPA static-link FAILED"; exit 1; }

  log "Install ENGRAMPA data..."
  make install-data 2>&1 || log "make install-data warn (data not critical)"

  ls -lh $TARGETPATH/bin/engrampa
  xx-verify --static $TARGETPATH/bin/engrampa || { log "ENGRAMPA xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
*) #compile
    oneBuild $1
    ;;
esac
