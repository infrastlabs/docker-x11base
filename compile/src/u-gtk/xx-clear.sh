#!/bin/sh
# xx-clear.sh — 交叉基础镜像专用清理工具（给 gtk224.xx / gtkmm224.xx Dockerfile 调用）
# 与 u-gtk/build.sh 同目录；独立于 build.sh，不改动 u-gtk/u-gtkmm 原构建逻辑。
#
# 用法:
#   xx-clear.sh intermediate <prefix>             # 清中间产物(.o/.lo/.libs/.deps//tmp源码树)，保留 .a/.pc/include/.la
#   xx-clear.sh staticlib <sysroot> [libname...]  # 清旧静态库(防串架构污染)；无 libname = 清 $sysroot/usr/lib/lib*.a
#
# 说明:
#   - intermediate: 交叉建完 gtk2/gtkmm 后调用，只保留最终产物(.a/.pc/include/.la)，砍镜像体积。
#   - staticlib: 每个架构交叉构建【前】调用，清掉该 sysroot 里上次(可能另一架构)残留的 .a，
#                否则 make DESTDIR 不删旧文件 → 串架构污染(libXrandr.a file format not recognized，实测踩过)。
#   - native(未设 XX_CROSS_FILE) 不受影响: 本脚本由新 Dockerfile 显式调用，native 流程不调它。

set -e

# 2026-11-26(3.1.2): 工作区根——与 common.sh 同法派生，供 intermediate 只清本 $WS 的源码树。
#   本脚本不 source common.sh(避免 CC/LDFLAGS 等副作用)；调用方(Dockerfile 并行分支)已 export WS=/tmp/ws-<链>-$tag。
# 2026-11-26(CI 二跑修复, 单一 $WS): 尊重已设 $WS 不覆盖; 未设(串行)才按 WS_BASE-$UGTK_NS 兜底。
if [ -z "$WS" ]; then
  UGTK_NS="${UGTK_NS:-native}"
  WS_BASE="${WS_BASE:-/tmp/ws}"
  WS="$WS_BASE-${UGTK_NS}"
fi
# 2026-11-27(4.1.3): 源码树根——与 common.sh 同法(在 WS 兜底前判定, 串行落 /tmp)。供 intermediate 清 $SRCROOT 树。
SRCROOT="${WS:+$WS/src}"
: "${SRCROOT:=/tmp}"

log() { echo ">>> [${UGTK_NS:-?}] xx-clear: $*"; }

cmd=${1:-}; shift || true

case "$cmd" in
  intermediate)
    prefix=${1:?usage: xx-clear.sh intermediate <prefix>}
    # 1) 构建中间产物
    # 2026-11-26 订正: 保留 *crt*.o——crt1/crti/crtn(musl) + crtbegin*/crtend*/crtfastmath(gcc) + Scrt1/rcrt1
    #   是链静态可执行必需(Scrt1.o/crti.o/crtbeginS.o/libgcc), 全删则 C++ 交叉 configure 报
    #   "C++ compiler cannot create executables"(linux-arm64-ld: cannot find Scrt1.o/crti.o/crtbeginS.o/-lgcc);
    #   C 静态链不依赖 crtbeginS.o 故 gtk2 能过, gtkmm(C++) 就挂。只清真正中间 .o(源码树在 /tmp, 此处为 sysroot 杂散 .o)。
    find "$prefix" -name "*.o" ! -name "*crt*.o" -delete 2>/dev/null || true
    find "$prefix" -name "*.lo" -delete 2>/dev/null || true
    find "$prefix" -name "*.la.bak" -delete 2>/dev/null || true
    find "$prefix" -name ".libs"  -type d -exec rm -rf {} + 2>/dev/null || true
    find "$prefix" -name ".deps"  -type d -exec rm -rf {} + 2>/dev/null || true
    # 2) 工作区源码树(2026-11-27 4.1.3 收进 $SRCROOT, 并行隔离)。只清本 $SRCROOT, 不碰别的分支。
    #    native-only 树(/tmp/gtk gtkmm imlib2...)不在 cross 路径清理(交叉一次成形不留, 无需);
    #    串行(无 WS) SRCROOT=/tmp, 但 intermediate 仅在并行分支调用(见 Dockerfile .xx)故串行不触发。
    set -f   # 关 glob: $SRCROOT 无匹配时不展开字面量, 避免误删
    rm -rf "$SRCROOT"/gtk "$SRCROOT"/murrine "$SRCROOT"/gtkmm-src "$SRCROOT"/gtkmm \
           "$SRCROOT"/imlib2 "$SRCROOT"/libxrandr "$SRCROOT"/libcroco "$SRCROOT"/pango "$SRCROOT"/atk \
           "$SRCROOT"/gdk-pixbuf "$SRCROOT"/librsvg "$SRCROOT"/cairo \
           "$WS"/gtk-cross "$WS"/murrine-cross 2>/dev/null || true
    set +f
    # 2026-11-26 订正(3.1.2): 旧版在此 rm -rf /tmp/gtk-cross 与 /tmp/murrine-cross——并行下会删掉
    #   其它分支正在编译的树(根因 C), 现已收进 $WS, 上面只清本 $WS 副本即可。
    # 3) apk 缓存 / 坏下载缓存(同原 gtkmm224 尾部清理)
    #    2026-11-26(3.1.2 缺陷 B): 删掉旧 `rm -f /tmp/*.log /tmp/*.out`——并行下会删掉其它分支的日志/.rc,
    #    导致 cat .rc 报 No such file 且失败无法定位。日志现收口 $WS/logs/, 各分支只读写自己的。
    rm -rf /var/cache/apk/* /root/.cache 2>/dev/null || true
    # 保留: *.a  *.pc  include/  *.la(已 xx_la_fix)
    log "intermediate cleaned ($prefix)"
    ;;
  staticlib)
    sysroot=${1:?usage: xx-clear.sh staticlib <sysroot> [libname...]}
    if [ -n "$1" ]; then
      for l in "$@"; do rm -f "$sysroot"/usr/lib/"$l" "$sysroot"/usr/local/lib/"$l" 2>/dev/null || true; done
    else
      rm -f "$sysroot"/usr/lib/lib*.a "$sysroot"/usr/local/lib/lib*.a 2>/dev/null || true
    fi
    log "staticlib cleaned ($sysroot)"
    ;;
  archcheck)
    # 2026-11-26: 产库检查点加【架构校验】——test -f 只看存在性, 抓不住串架构污染
    # (armv7 libgtk 里混进 4 个 aarch64 成员; 静态链按需取成员故不报错, 属潜伏)。
    # 用法: xx-clear.sh archcheck <archive> <want-substr>
    #   want: amd64=x86-64 / arm64=aarch64 / armv7=EABI  (file -b 输出子串)
    a=${1:?usage: xx-clear.sh archcheck <archive> <want-substr>}
    want=${2:?usage: xx-clear.sh archcheck <archive> <want-substr>}
    [ -f "$a" ] || { echo "archcheck: $a missing" >&2; exit 1; }
    d=$(mktemp -d /tmp/archcheck.XXXXXX)
    ( cd "$d" && ar x "$a" ) 2>/dev/null || true
    bad=0; total=0
    for o in "$d"/*.o; do
      [ -f "$o" ] || continue
      total=$((total+1))
      h=$(file -b "$o" 2>/dev/null)
      case "$h" in
        *"$want"*) : ;;
        *) echo "  ARCHBAD $o -> $h" >&2; bad=$((bad+1)) ;;
      esac
    done
    rm -rf "$d"
    if [ "$bad" -gt 0 ]; then
      echo "archcheck FAIL: $a $bad/$total members not $want" >&2; exit 1
    fi
    log "archcheck OK: $a $total/$total members $want"
    ;;
  *)
    echo "usage: $0 {intermediate <prefix>|staticlib <sysroot> [libname...]|archcheck <archive> <want-substr>}" >&2
    exit 1
    ;;
esac
