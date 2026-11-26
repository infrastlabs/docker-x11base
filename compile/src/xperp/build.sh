#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-xperp}"
source /src/common.sh

#
# Build perp
#
# 2026-11-25 方案一交叉: perp(纯 make, 无 configure, 无 X11) 走共享交叉环境(同 x-xbindkeys/suckless)。
# make-only → 无 CROSS_HOST; 顶层 fk-perp Makefile 经 $(MAKE) -C 递归到 lasagna/perp, CC 经环境/命令行传导。
# native(未设 XX_CROSS_FILE): MAKE_CC 留空 → make 原样(仅靠 common.sh export 的 CC/LDFLAGS) → 原路径零影响。
# perp 只依赖 libc(musl)+ 头, 无第三方 -l 库 → sysroot 无需额外 xx-apk 静态库。
perp_cross(){
  MAKE_CC=""
  if [ -n "$XX_CROSS_FILE" ]; then
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    # LDFLAGS(common.sh -static...) 加 sysroot -L 前缀, 供 xx-clang 递归 sub-make 找目标架构 libc/SCUDO 等
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    log "perp: CROSS ($XX_TRIPLE)"
  fi
}

function perp(){
  perp_cross
  log "Downloading perp..."
  gitclone https://gitee.com/infrastlabs/fk-perp $SRCROOT/fk-perp
  cd $SRCROOT/fk-perp

  log "Compiling perp..."
  # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
  # $MAKE_CC 命令行顶掉子 Makefile 可能硬编码的 CC(native 空 → 原样)
  # 交叉: outvec/mk_outvec 是 build 期宿主工具(运行时生成 outvec_STDOUT.h), 若随 CC=xx-clang 交叉编成
  #   aarch64 则 host(x86) 跑不起来 → "mk_outvec: syntax error" + 后续 perpd link 失败。
  #   故先用 native cc 预建 mk_outvec(已最新则 cross make 跳过重建, 只当 native 二进制运行生成头)。
  if [ -n "$XX_CROSS_FILE" ]; then
    # lasagna/ 下有多个 build 期宿主代码生成器(运行时生成 .c/.h), 若随 CC=xx-clang 交叉编成 aarch64
    #   则 host(x86) 跑不起来(mksysstr 实测编成 ARM ELF → "syntax error")→ 后续 perpd link 失败。
    #   故一律先用 native cc 预建(已最新则 cross make 跳过重建, 只当 native 二进制运行)。
    make CC=cc -C lasagna/ outvec/mk_outvec || { log "PERP mk_outvec native build FAILED"; exit 1; }
    make CC=cc -C lasagna/ rlimit/mk_rlimit || { log "PERP mk_rlimit native build FAILED"; exit 1; }
    make CC=cc -C lasagna/ sysstr/mksysstr || { log "PERP mksysstr native build FAILED"; exit 1; }
  fi
  make $MAKE_CC -C lasagna/
  make $MAKE_CC -C perp/
  #make -C runtools/

  log "Installing perp..."
  make $MAKE_CC -C perp/ install

  # view
  ls -lh $SRCROOT/fk-perp/perp
  # 交叉真验: xx-verify 按 build 架构(amd64)校验, 交叉产物(ARM)必 mismatch → 用 file; native 仍走 xx-verify。
  if [ -n "$XX_CROSS_FILE" ]; then
    for b in perpd perpctl perpls; do
      file $SRCROOT/fk-perp/perp/$b | grep -qE "ARM.*statically linked" \
        || { log "PERP $b file 非 ARM static"; exit 1; }
    done
  else
    xx-verify --static $SRCROOT/fk-perp/perp/perpd || { log "PERP perpd xx-verify FAILED"; exit 1; }
    xx-verify --static $SRCROOT/fk-perp/perp/perpctl || { log "PERP perpctl xx-verify FAILED"; exit 1; }
    xx-verify --static $SRCROOT/fk-perp/perp/perpls || { log "PERP perpls xx-verify FAILED"; exit 1; }
  fi
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec perp || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
