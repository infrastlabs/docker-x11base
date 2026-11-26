#!/bin/sh
# analyze.sh — 静态产物分析 + 报告（单架构, 事后快照）
# 与 xx-clear.sh 同目录；给 Dockerfile.builder.gtk224.xx 构建后调用，判定该架构产物成败。
#
# 用法:
#   analyze.sh <chain> <arch>            # 输出到 stdout; Dockerfile 重定向 /report/u-gtk-$tag.txt
#     chain: gtk224 (关键产物 libgtk-x11-2.0.a) / gtkmm224 (libgtkmm-2.4.a)
#     arch:  amd64 | arm64 | arm/v7      # tag 自动映射 amd64/arm64/arm-v7(除斜杠)
#
# 设计(2026-11-26, multiarch-buildSpeed 3.4.3):
#   - 关键产物存在性 + archcheck(xx-clear.sh archcheck) 决定本架构成败, 不依赖中途 .rc(产物=唯一真相)。
#   - 枚举 .a 清单(产物); 失败时定位 FAIL_MODULE(doExec _exec_result.txt 末条 rc!=0) + FAIL_LOG(对应 doExec 日志)。
#   - 容错: 分析不因单步失败中断(仅记录); 关闭 set -e(common.sh 内开启)。
#   - 调用方(Dockerfile)已 export WS=/tmp/ws-<链>-$tag + WS_LOCK=1, 本脚本尊重不覆盖。

chain=${1:?usage: analyze.sh <chain> <arch>}
arch=${2:?usage: analyze.sh <chain> <arch>}
SRC=$(dirname "$0")

case "$chain" in
  gtk224)   keylib=libgtk-x11-2.0.a ;;
  gtkmm224) keylib=libgtkmm-2.4.a ;;
  *) echo "unknown chain: $chain" >&2; exit 1 ;;
esac
case "$arch" in
  amd64)  want=x86-64;   tag=amd64 ;;
  arm64)  want=aarch64;  tag=arm64 ;;
  arm/v7) want=EABI;     tag=arm-v7 ;;
  *) echo "unknown arch: $arch" >&2; exit 1 ;;
esac

# 交叉环境初始化得 XX_SYSROOT/UGTK_NS(WS 由调用方 export, 尊重不覆盖)
unset XX_SYSROOT XX_CROSS_FILE XX_TRIPLE XX_MARCH
export TARGETPLATFORM=linux/$arch
. "$SRC/../common.sh" 2>/dev/null || true
xx_cross_init 2>/dev/null || true
set +e   # 分析容错: 关闭 set -e(common.sh 内开启)

ROOT="/usr"; [ -n "${XX_SYSROOT:-}" ] && ROOT="${XX_SYSROOT%/}/usr"
KEY="$ROOT/lib/$keylib"

echo "=== $chain 静态产物分析 ($arch) ==="
echo "date: $(date '+%Y-%m-%d %H:%M')   tag: $tag   target: linux/$arch   sysroot: ${XX_SYSROOT:-native}"

ok=0
if [ -f "$KEY" ]; then
  ac=$(sh "$SRC/xx-clear.sh" archcheck "$KEY" "$want" 2>&1)
  if [ $? -eq 0 ]; then
    ok=1; echo "KEY  $KEY  OK (archcheck $want)"
  else
    echo "KEY  $KEY  ARCHBAD ($want): $(echo "$ac" | grep -E 'archcheck FAIL' | head -1)"
  fi
else
  echo "KEY  $KEY  MISSING"
fi

echo "STATIC_LIBS ($(find "$ROOT/lib" "$ROOT/local/lib" -maxdepth 1 -name '*.a' 2>/dev/null | wc -l)):"
find "$ROOT/lib" "$ROOT/local/lib" -maxdepth 1 -name '*.a' 2>/dev/null | sort -u | while read -r a; do
  printf "  %-44s %s\n" "$a" "$(du -h "$a" 2>/dev/null | cut -f1)"
done

if [ "$ok" != 1 ]; then
  LOGS="${LOGS:-$TARGETPATH/../.logs/${UGTK_NS:-native}}"
  ERF="$LOGS/doExec/u-gtk/_exec_result.txt"
  echo "FAIL_LOCATE:"
  if [ -f "$ERF" ]; then
    # 末条 rc!=0 记录 → 失败模块(同 common.sh doExec 的 sanitize 推 doExec 日志名)
    lastbad=$(grep -nE '^[1-9][0-9]*\|' "$ERF" | tail -1)
    if [ -n "$lastbad" ]; then
      rest=${lastbad#*:}; rc=${rest%%|*}; cmd=${rest#*|}
      slog=$(printf '%s' "$cmd" | sed 's/[^A-Za-z0-9_.-]/_/g; s/__*/_/g; s/^_//; s/_$//' | cut -c1-120).log
      echo "FAIL_MODULE  $cmd (rc=$rc)"
      echo "FAIL_LOG     $LOGS/doExec/u-gtk/$slog"
    else
      echo "FAIL_MODULE  (no rc!=0 in _exec_result.txt; 见 b_deps log)"
    fi
  else
    echo "FAIL_MODULE  (no _exec_result.txt: $ERF)"
  fi
  BLOG="$WS/logs/$tag.log"
  [ -f "$BLOG" ] && echo "FAIL_LOG2    $BLOG"
  [ -f "$WS/logs/$tag.rc" ] && echo "FAIL_RC      $(cat "$WS/logs/$tag.rc" 2>/dev/null)"
fi

echo "---"
echo "CONCLUSION: $([ "$ok" = 1 ] && echo SUCCESS || echo FAILED)"
