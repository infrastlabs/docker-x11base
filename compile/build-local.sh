#!/bin/bash
# build-local.sh — 本地构建交叉 gtk224-3 / gtkmm224-3 基础镜像(无 buildx, 单架构, 不 push)
# 与 buildx.sh 的 gtk224/gtkmm224 case 对应, 但:
#   - 不用 buildx(本地无 buildx 也能做), 用普通 docker build
#   - 单架构(默认 arm64, 可传参), 先 arm64 e2e 跑通再扩展
#   - 不 push(只在本地)
#
# 用法:
#   bash build-local.sh gtk224 [arm64|arm/v7]     # 交叉建 gtk2 栈(默认 arm64)
#   bash build-local.sh gtkmm224 [arm64|arm/v7]   # 交叉建 gtkmm 栈(需 gtk224-3 已建)
#
# 镜像 tag 与 CI 正式一致(gtk224-3 / gtkmm224-3), 但本地不 push。
set -e
cd "$(dirname "$0")"   # compile/

REPO=${REPO:-registry.cn-shenzhen.aliyuncs.com}    # gitac 源头指定的 aliyun 地址(同 CI 实际值); 基础镜像 alpine-builder 也在 aliyun
NS=infrastlabs
ARCH=${2:-arm64}                                   # 提示用(实际两架构都建, arm64 先跑); 构建平台恒 amd64
PLATFORM="linux/amd64"                             # 构建平台=amd64(同 buildx.sh L191 交叉模式); 交叉目标由 Dockerfile 循环 xx-clang 决定
PARALLEL_BUILD=${PARALLEL_BUILD:-0}                # 0=串行(默认, 本机 1.9Gi 红线安全); 1=3 路并行(仅 CI/大内存, 见 2.4.9.2 风险)
builddate=$(date +%Y-%m-%d_%H:%M:%S)

case "$1" in
  gtk224)
    img="x11-base:alpine-builder-gtk224-3"         # 与 buildx.sh gtk224 case 一致(-3=xx-cross)
    df="src/../builder/Dockerfile.builder.gtk224.xx"
    ;;
  gtkmm224)
    img="x11-base:alpine-builder-gtkmm224-3"
    df="src/../builder/Dockerfile.builder.gtkmm224.xx"
    ;;
  *) echo "usage: $0 {gtk224|gtkmm224} [arm64|arm/v7]"; exit 1;;
esac

echo ">>> 本地构建: $REPO/$NS/$img  platform=$PLATFORM  (不 push)"
echo ">>> df=$df  context=. (compile/)"
# 本地无 buildx: 不传 --provenance/--sbom(buildx 专有 flag, 普通 docker build 不认); CI buildx 才用
docker build \
  --network host \
  --build-arg REPO=$REPO/ \
  --build-arg NOCACHE=$builddate \
  --build-arg PARALLEL_BUILD=$PARALLEL_BUILD \
  --platform $PLATFORM \
  -t "$REPO/$NS/$img" \
  -f "$df" . 

echo ">>> DONE: $REPO/$NS/$img ($PLATFORM)"
docker images "$REPO/$NS/$img"