#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-v-lxde}"
source /src/common.sh

#
# Build lxappearance
#
# export TARGETPATH=/usr/local/static/lxappearance
function lxappearance(){
# apk add hicolor-icon-theme #need hicolor

  log "Downloading LXAPPEARANCE..."
  rm -rf $SRCROOT/lxappearance; # mkdir -p $SRCROOT/lxappearance
  # down_catfile ${LXAPPEARANCE_URL} | tar -zx --strip 1 -C $SRCROOT/lxappearance
  # branch="--branch=$LXAPPEARANCE_VER"
  gitclone https://gitee.com/g-system/fk-lxappearance $SRCROOT/lxappearance $branch #;
  log "Configuring LXAPPEARANCE..."
  cd $SRCROOT/lxappearance #&& ./bootstrap;
  ./autogen.sh
  ./configure --prefix=$TARGETPATH \
  --enable-man=no \
  --enable-more-warnings=yes \
  --enable-gtk3=no \
  --enable-dbus=yes \
  --enable-debug=yes 

  # ENABLE_DBUS err
  # 4  vi src/lxappearance.c
  # 5  vi $SRCROOT/lxappearance/src/lxappearance.c ##注释后，编译过了;
  # >> 手动拷贝>> 运行 GModule-Critical错误依旧(assertion 'module'!='NULL')2条

  # ref pcmanfm
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    #  -lfm -lfm-gtk -lmenu-cache 
    ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage "
    # 2026-11-14: lxappearance 补 -lrsvg-2 -lcroco-0.6（图标预览走 gdk_pixbuf 内置 svg loader，缺则 svg 图标解码失败；u-gtk 方案A 库层根治后无需 -u）
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  make LDFLAGS="$LDFLAGS" \
    LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -Wl,--end-group" 2>&1 \
    || { log "LXAPPEARANCE build FAILED"; exit 1; }

  log "Install LXAPPEARANCE..."
  # make;
  make install; #不用install? need

  # view
  ls -lh $SRCROOT/lxappearance/
  xx-verify --static $SRCROOT/lxappearance/src/lxappearance
}

function lxtask(){
  log "Downloading LXTASK..."
  rm -rf $SRCROOT/lxtask; # mkdir -p $SRCROOT/lxtask
  # down_catfile ${LXAPPEARANCE_URL} | tar -zx --strip 1 -C $SRCROOT/lxtask
  LXTASK_VER=0.1.12   # 2026-11-23 改用 tag（原 master 分支）；0.1.12 是上游最新 GTK2 tag
  branch="--branch=$LXTASK_VER"
  gitclone https://gitee.com/g-system/fk-lxtask $SRCROOT/lxtask $branch #;
  log "Configuring LXTASK..."
  cd $SRCROOT/lxtask #&& ./bootstrap;
  # 2026-11-24 方案二交叉: 强制宿主 pkg-config(同 gtk 坑①) + --host 交叉 + LDFLAGS 补 -L sysroot/usr/local(librsvg/libcroco 装 /usr/local)
  CROSS_HOST=""; X_LIBDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    X_LIBDIR="-L$XX_SYSROOT/usr/local/lib"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    log "lxtask: CROSS ($XX_TRIPLE)"
  fi
  ./autogen.sh
  ./configure --prefix=$TARGETPATH --localedir=$TARGETPATH/share/locale $CROSS_HOST
  # ref pcmanfm
    OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" #ref tmux-3
    ex0="-lgmodule-2.0 -lgobject-2.0 -lgpg-error -lgraphite2 -lpixman-1 -ljpeg -luuid -lmount -lpcre -lblkid -lXcomposite"
    # -lXdamage注释也会用到;
    #  -lfm -lfm-gtk -lmenu-cache 
    ex1="-lfontconfig -lgio-2.0 -lcairo   -lXdamage "
    # 2026-11-14: 静态链接按需拉取问题——svg loader(io-svg.c.o) 编入库但注册方 gdk-pixbuf-io.c.o 未被引用就不拉入→SVG 图标"Unrecognized image file format"(打叉)。
    #   初版用双 -u(强制拉入 _gdk_pixbuf__svg_fill_vtable + gdk_pixbuf_new_from_file) 应用层补救, 验证通过;
    #   后 u-gtk 库层根治(方案A: 注册函数导出 + get_type 必然调用, 见 u-gtk/build.sh gdk_pixbuf 内联 python)——lxtask 恢复原 LIBS0 无需 -u, svg loader 自动注册。
    LIBS0=" -lgdk-x11-2.0 -lgtk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig $OB_LIBS $ex0 $ex1"

  make LDFLAGS="$X_LIBDIR $LDFLAGS" \
    LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -Wl,--end-group" 2>&1 \
    || { log "LXTASK build FAILED"; exit 1; }

  log "Install LXTASK..."
  make install || { log "LXTASK install FAILED"; exit 1; }

  log "Install LXTASK locale (静态 LOCALEDIR=$TARGETPATH/share/locale；po/ 各 .po 由 msgfmt 转 .mo——make 默认只产 .o，po 未生成 .mo，手装才带中文)..."
    if [ -d $SRCROOT/lxtask/po ]; then
      for p in $SRCROOT/lxtask/po/*.po; do
        lang=$(basename "$p" .po)
        mkdir -p $TARGETPATH/share/locale/$lang/LC_MESSAGES
        msgfmt "$p" -o $TARGETPATH/share/locale/$lang/LC_MESSAGES/lxtask.mo 2>/dev/null \
          || log "msgfmt warn: $lang"
      done
      log "locales installed: $(ls $SRCROOT/lxtask/po/*.po | wc -l) langs"
    fi

  # view
  ls -lh $SRCROOT/lxtask/
  ls -lh $TARGETPATH/bin/lxtask
  xx-verify --static $TARGETPATH/bin/lxtask || { log "LXTASK xx-verify FAILED"; exit 1; }
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    # lxde
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
