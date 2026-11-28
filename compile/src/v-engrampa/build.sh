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
# 2026-11-25 方案二交叉: engrampa(GTK2/autotools/autogen) 共用交叉环境(同 w-xlunch/pavucontrol)。
# 设 CROSS_HOST/XX_CPPFLAGS: configure 追加 --host、CPPFLAGS 前缀 sysroot; LDFLAGS 全局前缀 sysroot -L。
# native(未设 XX_CROSS_FILE 空): 变量留空 → 原路径零影响。
eng_cross(){
  CROSS_HOST=""; XX_CPPFLAGS=""; XX_LINK_EXTRA=""; XX_MAKE_GSCHEMAS=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # 顶部 native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    # 交叉 configure run-test 缓存: mmap/realloc/malloc/cc_cross 在 cross 下不能 run → 显式 yes。
    export ac_cv_func_mmap_fixed_mapped=yes
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    # 头/库搜索前缀 sysroot（xx-clang 自带 sysroot, 但 configure 探测/静态 -L 需显式; 双保险）。
    # LDFLAGS 全局前缀(common.sh 已 export -static...; 追加 -L 供 configure link-test 找 sysroot .a)。
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    XX_CPPFLAGS="-I$XX_SYSROOT/usr/include"
    # LINK 串里 $(LDFLAGS) 是 shell 命令替换(空), 非 make 变量——native 靠默认库路径没暴露,
    #   交叉下 sysroot /usr/local/lib 不在默认路径 → 必须显式注入 -L(2026-11-25 实测 rpm2cpio -lrsvg-2 找不到)。
    XX_LINK_EXTRA="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib"
    # 2026-11-28: 交叉下 pkg-config 的 glib_compile_schemas 指向 sysroot 里的 ARM 二进制 →
    # make 的 %.gschema.valid 规则(/usr/share/aclocal/gsettings.m4:44)须经 qemu 跑它, 而 qemu 未带
    #   -L $XX_SYSROOT → 按字面路径找 /lib/ld-musl-<arch>.so.1 →
    #   "qemu-arm: Could not open '/lib/ld-musl-armhf.so.1': No such file or directory" → Error 255。
    # 旧 `xx-apk add musl` 只补 loader 文件, 不解决 qemu 的 -L 前缀 → 无效(commit 893c7021)。
    # 正解: 该规则只 `--strict --dry-run` 做 schema 校验(不生成二进制代码, 与架构无关) → 直接用
    #   native glib-compile-schemas, 彻底不走 qemu。GLIB_COMPILE_SCHEMAS 是 AC_SUBST 出的普通 make
    #   变量(非 override), 命令行覆盖即生效。
    # QEMU_LD_PREFIX 兜底: 等同 qemu -L $XX_SYSROOT, 保护 make 里其它可能经 qemu 的 ARM 子进程
    #   (如 gtk-update-icon-cache)。binfmt 若已带 -L 则命令行优先、本变量不生效(无害)。
    export QEMU_LD_PREFIX="$XX_SYSROOT"
    # loader 文件仍需就位(供带 -L 的 qemu 用); 去掉旧 >/dev/null 2>&1 || true 吞错——失败要可见。
    xx-apk add musl || log "WARN: xx-apk add musl 失败(loader 可能缺, 但本组件已不依赖 qemu 跑 schema)"
    apk add --no-cache glib >/dev/null 2>&1 || true
    XX_GSCHEMAS=$(command -v glib-compile-schemas || true)
    test -n "$XX_GSCHEMAS" || { log "glib-compile-schemas MISSING (apk add glib)"; exit 1; }
    XX_MAKE_GSCHEMAS="GLIB_COMPILE_SCHEMAS=$XX_GSCHEMAS"
    log "engrampa: CROSS ($XX_TRIPLE, schema 用 native $XX_GSCHEMAS)"
  fi
}

function engrampa(){
  eng_cross
  ENGRAMPA_VER=1.14.1

  # autogen 硬性依赖 mate-autogen(mate-common)/yelp-build(yelp-tools)/itstool，缺则 ./autogen.sh 静默失败→无 configure
  # （2026-11-13 修复：构建环境须装；幂等，已装则 no-op）
  apk add mate-common yelp-tools itstool >/dev/null 2>&1
  which mate-autogen >/dev/null || { log "mate-autogen MISSING (apk add mate-common)"; exit 1; }

  log "Downloading ENGRAMPA..."
  if test -d $SRCROOT/engrampa/.git; then
    log "engrampa source already present, skip clone"
  else
    rm -rf $SRCROOT/engrampa
    branch="--branch=v$ENGRAMPA_VER"
    gitclone https://gitee.com/g-system/fk-engrampa $SRCROOT/engrampa $branch
  fi

  # apply glib g_ptr_array_copy dead-code patch (系统 glib>=2.32 三参 API 与 engrampa 自带单参冲突)
  PATCH_DIR=$(dirname "$0")
  if grep -q "g_ptr_array_copy             (GPtrArray" $SRCROOT/engrampa/src/glib-utils.h; then
    log "Apply glib-g_ptr_array_copy patch..."
    patch -p1 -d $SRCROOT/engrampa < "$PATCH_DIR/engrampa-1.14.1-glib-g_ptr_array_copy.patch" || { log "PATCH FAILED"; exit 1; }
  else
    log "glib-g_ptr_array_copy patch already applied"
  fi

  # apply localedir patch: configure.ac 硬编码 LOCALEDIR=${prefix}/share/locale, 忽略 --localedir
  # 改 ${localedir} 使 --localedir=/usr/share/locale 生效 (静态版中文/多语言路径)
  if grep -q 'AC_DEFINE_UNQUOTED(LOCALEDIR, "${ac_default_prefix}/' $SRCROOT/engrampa/configure.ac; then
    log "Apply localedir patch..."
    patch -p1 -d $SRCROOT/engrampa < "$PATCH_DIR/engrampa-1.14.1-localedir.patch" || { log "LOCALEDIR PATCH FAILED"; exit 1; }
  else
    log "localedir patch already applied"
  fi

  # 去重复全局定义：main.c 重定义了 fr-init.h 已 extern 的 WindowList/ForceDirectoryCreation
  # （fr-init.c 已定义）→ 静态链 multiple definition；去掉定义即可免 --allow-multiple-definition。
  if grep -qE 'WindowList[[:space:]]*=[[:space:]]*NULL' $SRCROOT/engrampa/src/main.c; then
    log "Apply dup-globals patch..."
    patch -p1 -d $SRCROOT/engrampa < "$PATCH_DIR/engrampa-dup-globals.patch" || { log "DUP-GLOBALS PATCH FAILED"; exit 1; }
  else
    log "dup-globals patch already applied"
  fi

  # apply eng-settings-schema patch: GSettings schema 目录编译期编入(2026-11-14, 用户拍板选2)
  # g_settings_new → eng_settings_new(helper: g_settings_new_full + 自定义 schema source),
  # 运行时免 XDG_DATA_DIRS/GSETTINGS_SCHEMA_DIR; 产物随 $TARGETPATH 整体可迁移。
  # 详见 docs/2026/11110827-ci-builder-gtk-app.md 5.3.3.1(API 签名/20 调用点/只读目录已验)。
  if grep -q "^eng_settings_new (const char \*schema)" $SRCROOT/engrampa/src/fr-init.c; then
    log "eng-settings-schema patch already applied"
  else
    log "Apply eng-settings-schema patch..."
    patch -p1 -d $SRCROOT/engrampa < "$PATCH_DIR/engrampa-eng-settings-schema.patch" || { log "ENG-SETTINGS-SCHEMA PATCH FAILED"; exit 1; }
  fi

  # apply null-schema-source patch: fr-window.c 直接 g_settings_schema_source_get_default()+lookup() 在
  #   无 XDG_DATA_DIRS(默认源 NULL) 时断言崩溃——这是绕过 eng_settings_new 的唯一漏网点(2026-11-20 实跑发现)。
  #   守卫: schema_source NULL → caja_schema=NULL, 跳过 Caja 集成(settings_caja 后续均有 if 守卫);
  #   产物仍自足 $TARGETPATH 内 schema(可迁移), 无需装系统默认路径。
  if grep -q "schema_source ? g_settings_schema_source_lookup" $SRCROOT/engrampa/src/fr-window.c; then
    log "null-schema-source patch already applied"
  else
    log "Apply null-schema-source patch..."
    patch -p1 -d $SRCROOT/engrampa < "$PATCH_DIR/engrampa-null-schema-source.patch" || { log "NULL-SCHEMA-SOURCE PATCH FAILED"; exit 1; }
  fi

  log "Configuring ENGRAMPA..."
  cd $SRCROOT/engrampa
  # 交叉下 autogen 若自动跑 configure(不带 --host) 报 cannot run C compiled programs → NOCONFIGURE=1,
  #   再显式 configure --host。native 原路径不变。
  [ -n "$XX_CROSS_FILE" ] && NOCONFIGURE=1 ./autogen.sh || ./autogen.sh
  # CPPFLAGS 编入 schema 目录(与 --prefix 编 PKGDATADIR 同法); 由 fr-init.c 的 helper 读取。
  # ENG_SCHEMA_DIR 未定义时 helper 回落 /usr/share/glib-2.0/schemas(健壮兜底)。
  # 2026-11-15: 不用 -DENG_SCHEMA_DIR=\"...\"——make recipe shell 会剥掉引号→编译器得裸 /usr/...→
  #   fr-init.c:682 "use of undeclared identifier 'usr'"（LIBTOOL=true 掩盖的潜伏 bug，CI 干净树复现）。
  #   改 -include 头文件：头文件内容写带引号的字符串字面量，无 shell 引号剥离问题（-include 是简单路径参数）。
  mkdir -p $SRCROOT/engrampa
  cat > $SRCROOT/engrampa/eng_schema_dir.h <<EOF
#define ENG_SCHEMA_DIR "$TARGETPATH/share/glib-2.0/schemas"
EOF
  ./configure --prefix=$TARGETPATH \
    --enable-static --disable-shared \
    --disable-caja-actions \
    --disable-packagekit \
    --localedir=$TARGETPATH/share/locale \
    $CROSS_HOST \
    CPPFLAGS="$XX_CPPFLAGS -include $SRCROOT/engrampa/eng_schema_dir.h"

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
  sed -i 's#copy-n-paste/libeggsmclient\.la#copy-n-paste/.libs/libeggsmclient.a#' $SRCROOT/engrampa/src/Makefile 2>/dev/null || true
  # $XX_MAKE_GSCHEMAS: 交叉下命令行覆盖 GLIB_COMPILE_SCHEMAS(native glib-compile-schemas, 见 eng_cross),
  #   使 %.gschema.valid 规则不走 qemu;  native 时该变量为空, 展开后无参。
  make LDFLAGS="$LDFLAGS" FR_LIBS="" \
    LINK="xx-clang -static -Wl,--strip-all -Wall -O2 $XX_LINK_EXTRA $(CFLAGS) $(LDFLAGS) -o \$@" \
    LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group" \
    $XX_MAKE_GSCHEMAS 2>&1 \
    || { log "ENGRAMPA make LINK FAILED"; exit 1; }

  log "Install ENGRAMPA binary (make 产物, 不再手动直链)..."
  # 交叉: engrampa 为自足应用(无系统库安装), 产物+数据随 $TARGETPATH 整体迁移, 无 $XX_SYSROOT 可装项。
  mkdir -p $TARGETPATH/bin
  BIN=$(find $SRCROOT/engrampa/src $SRCROOT/engrampa -maxdepth 2 -name engrampa -type f 2>/dev/null | head -1)
  test -n "$BIN" || { log "ENGRAMPA binary MISSING"; exit 1; }
  cp -f "$BIN" $TARGETPATH/bin/engrampa

  log "Install ENGRAMPA data..."
    # 2026-11-14: 补装 GSettings schema（make install-data 未装→运行时 org.mate.engrampa.listing 缺失崩溃）。
    #   可迁移原则(用户拍板): 产物以 /usr/local/static/<comp> 为基准整体拷走——schema 指定在 $TARGETPATH/share 下
    #   (与安装目录同体, 装系统 /usr/share 不可迁移已撤)。glib-compile-schemas 生成 gschemas.compiled(xml+compiled
    #   同目录自足可迁移; GLib 优先读 compiled 加速)。运行时由部署层统一 XDG_DATA_DIRS 覆盖该目录(一次指定全部组件)。
    mkdir -p $TARGETPATH/share/glib-2.0/schemas
    cp -f $SRCROOT/engrampa/data/org.mate.engrampa.gschema.xml $TARGETPATH/share/glib-2.0/schemas/ 2>/dev/null || log "schema copy warn"
    glib-compile-schemas $TARGETPATH/share/glib-2.0/schemas 2>/dev/null || log "glib-compile-schemas warn"

  log "Install ENGRAMPA locale (静态 LOCALEDIR=$TARGETPATH/share/locale；po/ 各 .po 由 msgfmt 转 .mo——make 默认只产 .o，po 未生成 .mo，手装才带中文)..."
    if [ -d $SRCROOT/engrampa/po ]; then
      for p in $SRCROOT/engrampa/po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/engrampa.mo 2>/dev/null \
          || log "msgfmt warn: $lang"
      done
      log "locales installed: $(ls $SRCROOT/engrampa/po/*.po | wc -l) langs"
    fi

  ls -lh $TARGETPATH/bin/engrampa
  # 交叉真验: xx-verify 按 build 架构(amd64) 校验, 交叉产物(ARM) 必报 mismatch——用 file 判 static + 目标架构;
  #   native 仍走 xx-verify(原路径)。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $TARGETPATH/bin/engrampa | grep -qE "ARM.*statically linked" \
      || { log "ENGRAMPA file 非 ARM static"; exit 1; }
  else
    xx-verify --static $TARGETPATH/bin/engrampa || { log "ENGRAMPA xx-verify FAILED"; exit 1; }
  fi
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
