#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-engrampa}"
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
    gitclone https://gitee.com/g-system/fk-engrampa /tmp/engrampa $branch
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

  # apply eng-settings-schema patch: GSettings schema 目录编译期编入(2026-11-14, 用户拍板选2)
  # g_settings_new → eng_settings_new(helper: g_settings_new_full + 自定义 schema source),
  # 运行时免 XDG_DATA_DIRS/GSETTINGS_SCHEMA_DIR; 产物随 $TARGETPATH 整体可迁移。
  # 详见 docs/2026/11110827-ci-builder-gtk-app.md 5.3.3.1(API 签名/20 调用点/只读目录已验)。
  if grep -q "^eng_settings_new (const char \*schema)" /tmp/engrampa/src/fr-init.c; then
    log "eng-settings-schema patch already applied"
  else
    log "Apply eng-settings-schema patch..."
    patch -p1 -d /tmp/engrampa < "$PATCH_DIR/engrampa-eng-settings-schema.patch" || { log "ENG-SETTINGS-SCHEMA PATCH FAILED"; exit 1; }
  fi

  log "Configuring ENGRAMPA..."
  cd /tmp/engrampa
  ./autogen.sh
  # CPPFLAGS 编入 schema 目录(与 --prefix 编 PKGDATADIR 同法); 由 fr-init.c 的 helper 读取。
  # ENG_SCHEMA_DIR 未定义时 helper 回落 /usr/share/glib-2.0/schemas(健壮兜底)。
  # 2026-11-15: 不用 -DENG_SCHEMA_DIR=\"...\"——make recipe shell 会剥掉引号→编译器得裸 /usr/...→
  #   fr-init.c:682 "use of undeclared identifier 'usr'"（LIBTOOL=true 掩盖的潜伏 bug，CI 干净树复现）。
  #   改 -include 头文件：头文件内容写带引号的字符串字面量，无 shell 引号剥离问题（-include 是简单路径参数）。
  mkdir -p /tmp/engrampa
  cat > /tmp/engrampa/eng_schema_dir.h <<EOF
#define ENG_SCHEMA_DIR "$TARGETPATH/share/glib-2.0/schemas"
EOF
  ./configure --prefix=$TARGETPATH \
    --enable-static --disable-shared \
    --disable-caja-actions \
    --disable-packagekit \
    --localedir=/usr/share/locale \
    CPPFLAGS="-include /tmp/engrampa/eng_schema_dir.h"

  # ref pcmanfm/lxtask 式 GTK2 静态链
  OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
  ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
  ex1="-lfontconfig -lgio-2.0 -lcairo -lXdamage"
  LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  log "Make ENGRAMPA (objects + 直链链接)..."
  # FR_LIBS(pkg-config 非 static)在 LDADD 且 --start-group 之外, 会让 gtk 依赖链断; 置空让 gtk/glib/X 全走下方 LIBS0 组。
  # 2026-11-16: 源头修(见 11120827-ci-builder-gtk-app-rootfs.md 五章6.1)——automake engrampa 链接用 $(LINK)(默认
  #   LIBTOOL: 拆 --start-group+按 .la 重排→海量 undefined, 旧靠 || log warn 容错+手动 xx-clang 直链 = 屏蔽);
  #   覆盖 LINK 去 LIBTOOL 直链 + LDADD 的 libeggsmclient.la 换 .libs/.a(clang 不认识 .la 格式), make 期即链接成功。
  #   (engrampa_LINK 变量不存在, 程序链接走通用 $(LINK)——曾错覆盖 engrampa_LINK 无效, 改 LINK 后才生效)
  sed -i 's#copy-n-paste/libeggsmclient\.la#copy-n-paste/.libs/libeggsmclient.a#' /tmp/engrampa/src/Makefile 2>/dev/null || true
  make LDFLAGS="$LDFLAGS" FR_LIBS="" \
    LINK="xx-clang -static -Wl,--strip-all -Wall -O2 $(CFLAGS) $(LDFLAGS) -o \$@" \
    LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group" 2>&1 \
    || { log "ENGRAMPA make LINK FAILED"; exit 1; }

  log "Install ENGRAMPA binary (make 产物, 不再手动直链)..."
  mkdir -p $TARGETPATH/bin
  BIN=$(find /tmp/engrampa/src /tmp/engrampa -maxdepth 2 -name engrampa -type f 2>/dev/null | head -1)
  test -n "$BIN" || { log "ENGRAMPA binary MISSING"; exit 1; }
  cp -f "$BIN" $TARGETPATH/bin/engrampa

  log "Install ENGRAMPA data..."
    # 2026-11-14: 补装 GSettings schema（make install-data 未装→运行时 org.mate.engrampa.listing 缺失崩溃）。
    #   可迁移原则(用户拍板): 产物以 /usr/local/static/<comp> 为基准整体拷走——schema 指定在 $TARGETPATH/share 下
    #   (与安装目录同体, 装系统 /usr/share 不可迁移已撤)。glib-compile-schemas 生成 gschemas.compiled(xml+compiled
    #   同目录自足可迁移; GLib 优先读 compiled 加速)。运行时由部署层统一 XDG_DATA_DIRS 覆盖该目录(一次指定全部组件)。
    mkdir -p $TARGETPATH/share/glib-2.0/schemas
    cp -f /tmp/engrampa/data/org.mate.engrampa.gschema.xml $TARGETPATH/share/glib-2.0/schemas/ 2>/dev/null || log "schema copy warn"
    glib-compile-schemas $TARGETPATH/share/glib-2.0/schemas 2>/dev/null || log "glib-compile-schemas warn"

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
