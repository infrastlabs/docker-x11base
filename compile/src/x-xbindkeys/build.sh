#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-xbindkeys}"
source /src/common.sh

#
# Build xbindkeys (X11 键位绑定守护, 1.8.7, 纯 Xlib 无 GTK)
#
# 依赖: libX11.a + libXext.a (已就位 /usr/lib, 零新依赖)
# 上游: https://www.nongnu.org/xbindkeys/xbindkeys-1.8.7.tar.gz
# 注意: 容器内 curl 下载 nongnu.org tarball 会截断/挂死(实测 48K~125K 截断),
#       故下载优先用离线预置 tarball(/tmp, 宿主 curl 下载后 docker cp 或
#       Dockerfile COPY), 无则 down_catfile nongnu 兜底(校验 177532)。
export TARGETPATH=${TARGETPATH:-/usr/local/static/xbindkeys}
function xbindkeys(){
  XBK_VER=1.8.7
  SRC=/tmp/xbindkeys-$XBK_VER
  TGZ=/tmp/xbindkeys-$XBK_VER.tar.gz

  log "Downloading XBINDKEYS..."
  if test -d $SRC; then
    log "xbindkeys source dir present (tarball extracted), skip"
  else
    # 1. 离线预置 tarball 优先 (宿主 cp / Dockerfile COPY); 2. nongnu 官网 down_catfile 兜底
    test -s $TGZ || { \
      log "no staged tarball, try nongnu.org ..."; \
      curl -# -k -fSL --connect-timeout 10 --max-time 120 -o $TGZ \
        https://www.nongnu.org/xbindkeys/xbindkeys-$XBK_VER.tar.gz \
        || { log "XBINDKEYS download FAILED"; rm -f $TGZ; exit 1; }; \
    }
    # 官方 tarball 大小=177532, 校验防截断/损坏 (nongnu 容器内会截断到 48K~125K)
    test "$(stat -c%s $TGZ)" = "177532" || { \
      log "tarball size mismatch: $(stat -c%s $TGZ) != 177532 (截断/损坏, 请宿主 curl 下载后 docker cp 进 /tmp/)"; \
      rm -f $TGZ; exit 1; }
    cd /tmp
    tar xf $TGZ
  fi

  log "Configuring XBINDKEYS..."
  cd $SRC
  # 纯文本 .xbindkeysrc 足够; guile/tk 可选均禁用
  ./configure --prefix=$TARGETPATH --disable-guile --disable-tk 2>&1 \
    || { log "XBINDKEYS configure FAILED"; exit 1; }

  # libX11.a/libXext.a 静态传递依赖: xcb/Xau/Xdmcp/xcb-shm
  # 必须 --start-group 解循环(参考 w-scrot)
  LIBS="-Wl,--start-group -lX11 -lXext -lxcb -lXau -lXdmcp -lxcb-shm -Wl,--end-group"

  log "Make XBINDKEYS..."
  make LDFLAGS="$LDFLAGS" LIBS="$LIBS" 2>&1 \
    || { log "XBINDKEYS build FAILED"; exit 1; }

  log "Install XBINDKEYS..."
  make install || { log "XBINDKEYS install FAILED"; exit 1; }

  # 配置示例: 上游 make install 不装 xbindkeysrc(仅 EXTRA_DIST), 源码目录有文本版示例
  log "Install example config..."
  mkdir -p $TARGETPATH/share/xbindkeys
  cp $SRC/xbindkeysrc $TARGETPATH/share/xbindkeys/xbindkeysrc

  ls -lh $TARGETPATH/bin/xbindkeys
  xx-verify --static $TARGETPATH/bin/xbindkeys || { log "XBINDKEYS xx-verify FAILED"; exit 1; }
}

case "$1" in
cache)
    ;;
full)
    ;;
b_deps)
    # 零新依赖: libX11.a/libXext.a 已就位
    ;;
*) #compile
    oneBuild $1
    ;;
esac
