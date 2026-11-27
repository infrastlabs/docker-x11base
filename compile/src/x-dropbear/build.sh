#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-dropbear}"
source /src/common.sh

# 静态 libxcrypt：musl libc 的 crypt() 不支持 yescrypt（新版发行版默认），
# 静态链接 libxcrypt 内嵌 yescrypt/sha512 等，兼顾新旧发行版。
# 版本 v4.4.28（musl 上验证可用；INCLUDE_* 无默认值，须手动生成 crypt-hashes.h）。
LIBXCRYPT_VER=4.4.28
LIBXCRYPT_DIR=$SRCROOT/libxcrypt
LIBXCRYPT_ALL="yescrypt,gost_yescrypt,scrypt,bcrypt,bcrypt_y,bcrypt_a,bcrypt_x,sha512crypt,sha256crypt,sha1crypt,sunmd5,md5crypt,nt,bsdicrypt,bigcrypt,descrypt"

#
# Build libxcrypt static (yescrypt capable)
#
# 2026-11-25 方案一交叉: dropbear/libxcrypt(autotools) 走共享交叉环境(同 x-xbindkeys/v-engrampa)。
# db_cross: 设 CROSS_HOST(--host) + PKG_CONFIG 走 sysroot + LDFLAGS 前缀 sysroot -L。
#   关键: 下面 dropbear 的 `LDFLAGS="$LDFLAGS ..." ./configure` 与 `make LDFLAGS="$LDFLAGS ..."` 里的 $LDFLAGS
#   是 shell 展开(取 export 的 env)——db_cross 把 sysroot -L 并进 export LDFLAGS, 两处 $LDFLAGS 展开即带上,
#   make 命令行 LDFLAGS= 压过 env 但因引用了 $LDFLAGS 故仍含 sysroot -L; native 时未改 → 原路径零影响。
# dropbear 需 zlib(-lz) 静态 → xx-apk 补 zlib-static/dev 到 sysroot。
# native(未设 XX_CROSS_FILE): CROSS_HOST/XX_LIB Pre 空 → 原路径零影响。
db_cross(){
  CROSS_HOST=""; XX_LIB_PRE=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    # 头/库搜索前缀 sysroot(xx-clang 自带 sysroot, configure link-test/静态 -L 需显式; 双保险)
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    XX_LIB_PRE="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib"
    # 公共库(zlib)已由 u-gtk b_deps 统一装(1.4.1), 不再各自 xx-apk
    log "dropbear: CROSS ($XX_TRIPLE)"
  fi
}

function libxcrypt(){
  db_cross
  log "Downloading LIBXCRYPT..."
  rm -rf $LIBXCRYPT_DIR
  gitclone https://gitee.com/g-system/fk-libxcrypt $LIBXCRYPT_DIR --branch=v$LIBXCRYPT_VER
  cd $LIBXCRYPT_DIR
  # crypt-hashes.h 不在 git 源码树（INCLUDE_* 无默认值），须从 hashes.conf 生成
  perl build-aux/scripts/gen-crypt-hashes-h lib/hashes.conf "$LIBXCRYPT_ALL" > lib/crypt-hashes.h
  log "Autogen LIBXCRYPT (gitclone 源码树无 configure)..."
  ./autogen.sh 2>&1 || { log "LIBXCRYPT autogen FAIL"; exit 1; }
  log "Configuring LIBXCRYPT..."
  # --disable-werror：musl 的 gen-des-tables 有警告；只要静态; $CROSS_HOST 交叉时追加 --host(native 空)
  ./configure --disable-werror --disable-shared --enable-static --prefix=$TARGETPATH $CROSS_HOST
  make
  # crypt.o 须用上面生成的 crypt-hashes.h 重编，否则 hash_algorithms 表空、crypt() 返回 *0
  touch lib/crypt.c
  make
  ls -lh .libs/libcrypt.a
}

#
# Build dropbear
#
# 旧版本方法块（2024.86，独立；SHA-1 默认开，Xshell 4 直接兼容；gitee fk-dropbear 源）
function dropbear_2024_86(){
  db_cross
  log "Downloading DROPBEAR (2024.86)..."
  rm -rf $SRCROOT/dropbear
  gitclone https://gitee.com/g-system/fk-dropbear $SRCROOT/dropbear --branch=DROPBEAR_2024.86
  log "Configuring DROPBEAR (2024.86)..."
  cd $SRCROOT/dropbear
  # libcrypt.a 前置 whole-archive 到 LDFLAGS——crypt 定义在对象之前, ld 绑定 libxcrypt 的 crypt（yescrypt）
  #   --allow-multiple-definition：musl libc.a 自带 crypt，需允许多重定义
  LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition $LIBXCRYPT_DIR/.libs/libcrypt.a" \
    ./configure --enable-static --prefix=$TARGETPATH $CROSS_HOST
  # XX_LIB_PRE: 交叉 sysroot -L(已含在 export LDFLAGS, make 命令行 LDFLAGS= 引用 $LDFLAGS 故带上; native 空)
  make LDFLAGS="$XX_LIB_PRE $LDFLAGS -Wl,--allow-multiple-definition -Wl,--whole-archive $LIBXCRYPT_DIR/.libs/libcrypt.a -Wl,--no-whole-archive" \
    LIBS="-lz"
  log "Install DROPBEAR (2024.86)..."
  make install
  ls -lh $SRCROOT/dropbear/
  # 交叉真验: xx-verify 按 build 架构(amd64)校验, 交叉产物(ARM)必 mismatch → 用 file; native 仍走 xx-verify。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/dropbear/dropbear | grep -qE "ARM.*statically linked" \
      || { log "DROPBEAR file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/dropbear/dropbear || { log "DROPBEAR xx-verify FAILED"; exit 1; }
  fi
  # 兜底：确认真链入 libxcrypt 的 yescrypt（musl 的 crypt 无此符号；产物被 --strip-all 剥符号表，用 strings 查 "$y$"）。
  strings -n 3 $SRCROOT/dropbear/dropbear | grep -qx '\$y\$' \
    || { echo "!! dropbear 未含 yescrypt（libxcrypt 失败）"; exit 1; }
}

# 新版本方法块（2026.94，独立；含 SHA-1 保留 + 后量子 KEX + 各 CVE 修复；官方 GitHub 源）
function dropbear_2026_94(){
  db_cross
  log "Downloading DROPBEAR (2026.94)..."
  rm -rf $SRCROOT/dropbear
  gitclone https://github.com/mkj/dropbear $SRCROOT/dropbear --branch=DROPBEAR_2026.94
  log "Configuring DROPBEAR (2026.94)..."
  cd $SRCROOT/dropbear
  # 2025.87+ 默认禁 SHA-1（hmac-sha1/ssh-rsa/group14-sha1）→ Xshell 4 断连；localoptions.h 显式保留三件套。
  log "Preserve SHA-1 trio (Xshell 4 compat) for 2026.94..."
  printf "#ifndef DROPBEAR_LOCALOPTIONS_H\n#define DROPBEAR_LOCALOPTIONS_H\n#define DROPBEAR_SHA1_HMAC 1\n#define DROPBEAR_RSA_SHA1 1\n#define DROPBEAR_DH_GROUP14_SHA1 1\n#endif\n" > localoptions.h
  # libcrypt.a 前置 whole-archive 到 LDFLAGS——crypt 定义在对象之前, ld 绑定 libxcrypt 的 crypt（yescrypt）
  #   --allow-multiple-definition：musl libc.a 自带 crypt，需允许多重定义
  LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition $LIBXCRYPT_DIR/.libs/libcrypt.a" \
    ./configure --enable-static --prefix=$TARGETPATH $CROSS_HOST
  # XX_LIB_PRE: 交叉 sysroot -L(已含在 export LDFLAGS, make 命令行 LDFLAGS= 引用 $LDFLAGS 故带上; native 空)
  make LDFLAGS="$XX_LIB_PRE $LDFLAGS -Wl,--allow-multiple-definition -Wl,--whole-archive $LIBXCRYPT_DIR/.libs/libcrypt.a -Wl,--no-whole-archive" \
    LIBS="-lz"
  log "Install DROPBEAR (2026.94)..."
  make install
  ls -lh $SRCROOT/dropbear/
  # 交叉真验: xx-verify 按 build 架构(amd64)校验, 交叉产物(ARM)必 mismatch → 用 file; native 仍走 xx-verify。
  if [ -n "$XX_CROSS_FILE" ]; then
    file $SRCROOT/dropbear/dropbear | grep -qE "ARM.*statically linked" \
      || { log "DROPBEAR file 非 ARM static"; exit 1; }
  else
    xx-verify --static $SRCROOT/dropbear/dropbear || { log "DROPBEAR xx-verify FAILED"; exit 1; }
  fi
  # 兜底：确认真链入 libxcrypt 的 yescrypt（musl 的 crypt 无此符号；产物被 --strip-all 剥符号表，用 strings 查 "$y$"）。
  strings -n 3 $SRCROOT/dropbear/dropbear | grep -qx '\$y\$' \
    || { echo "!! dropbear 未含 yescrypt（libxcrypt 失败）"; exit 1; }
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
# 默认入口：Dockerfile 调新版本方法块（dropbear_2026_94）；build.sh dropbear 兜底兼容→新版本
# dropbear_2024_86 / dropbear_2026_94 走 *） oneBuild 按名调函数，无需显式分支
dropbear) oneBuild dropbear_2026_94 ;;
full)
    doExec libxcrypt || exit 1
    doExec dropbear_2026_94 || exit 1
    ;;
b_deps)
    # 2026-11-16: libxcrypt 前置另放 b_deps——Dockerfile dropbear stage 先调 b_deps 再 dropbear
    #   （原只调 dropbear 单组件，未建 $SRCROOT/libxcrypt/.libs/libcrypt.a → 无 yescrypt，登录 authFail）
    doExec libxcrypt || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
