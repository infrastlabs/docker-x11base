#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-w-scrot}"
source /src/common.sh

#
# Build scrot (X 截图工具, 1.12.1 匹配现有 imlib2 1.7.4)
#
# 依赖(deps.pc): imlib2 + x11 + xcomposite + xext + xfixes + xinerama
# 参考 w-feh imlib2 静态链(--start-group 解循环)
function scrot(){
  SCROT_VER=1.12.1

  log "Downloading SCROT..."
  if test -d /tmp/scrot/.git; then
    log "scrot source already present, skip clone"
  else
    rm -rf /tmp/scrot
    branch="--branch=$SCROT_VER"
    git clone --depth=1 $branch https://ghfast.top/https://github.com/resurrecting-open-source-projects/scrot /tmp/scrot
  fi

  log "Configuring SCROT..."
  cd /tmp/scrot
  ./autogen.sh 2>&1 || { log "SCROT autogen FAILED"; exit 1; }
  ./configure --prefix=$TARGETPATH

  # 参考 w-feh imlib2 静态链 (deps1/2/3 为 imlib2 全部传递依赖; deps3 补 -lXcomposite 供 scrot)
  # 注意：必须用自建 imlib2(/usr/local/lib, 内嵌 png/jpeg/svg loader)，否则链 Alpine 系统
  # libImlib2.a(/usr/lib) 无 format handler → 运行时 "failed to save image"。
  # svg loader 需 librsvg/cairo/glib/pango 静态链(同 feh)，故加 $RSVG_LIBS -lxml2 -lcroco-0.6。
  deps1="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
  deps2="-lXdamage -lX11-xcb -lxcb-shm -lxcb-render -lmd"
  deps3="-lXext -lXinerama -lXfixes -lXrandr -ljpeg -lXcomposite"
  RSVG_LIBS=$(pkg-config --static --libs librsvg-2.0 cairo pangocairo | tr ' ' '\n' | grep -vE '^-l(zstd|tiff)$' | tr '\n' ' ')

  log "Make SCROT..."
  make LDFLAGS="$LDFLAGS -L/usr/local/lib" \
    LIBS="-Wl,--start-group -lImlib2 $deps1 $deps2 $deps3 $RSVG_LIBS -lxml2 -lcroco-0.6 -Wl,--end-group" 2>&1 \
    || { log "SCROT build FAILED"; exit 1; }

  log "Install SCROT..."
  make install || { log "SCROT install FAILED"; exit 1; }

  ls -lh $TARGETPATH/bin/scrot
  xx-verify --static $TARGETPATH/bin/scrot || { log "SCROT xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 先建自建 imlib2（内嵌 png/jpeg/svg loader 到 /usr/local/lib/libImlib2.a）；jpeg loader 需 jpeglib.h
    # scrot autogen 需 autoconf-archive（AX_ 宏，configure.ac:25/28 报 not present）
    apk add autoconf-archive
    apk add libjpeg-turbo-static jpeg-dev
    doExec bash /src/w-xlunch/build.sh imlib2 || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
