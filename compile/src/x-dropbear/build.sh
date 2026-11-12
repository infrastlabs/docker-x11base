#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-dropbear}"
source /src/common.sh

# 静态 libxcrypt：musl libc 的 crypt() 不支持 yescrypt（新版发行版默认），
# 静态链接 libxcrypt 内嵌 yescrypt/sha512 等，兼顾新旧发行版。
# 版本 v4.4.28（musl 上验证可用；INCLUDE_* 无默认值，须手动生成 crypt-hashes.h）。
LIBXCRYPT_VER=4.4.28
LIBXCRYPT_DIR=/tmp/libxcrypt
LIBXCRYPT_ALL="yescrypt,gost_yescrypt,scrypt,bcrypt,bcrypt_y,bcrypt_a,bcrypt_x,sha512crypt,sha256crypt,sha1crypt,sunmd5,md5crypt,nt,bsdicrypt,bigcrypt,descrypt"

#
# Build libxcrypt static (yescrypt capable)
#
function libxcrypt(){
  log "Downloading LIBXCRYPT..."
  rm -rf $LIBXCRYPT_DIR
  gitclone https://gitee.com/g-system/fk-libxcrypt $LIBXCRYPT_DIR --branch=v$LIBXCRYPT_VER
  cd $LIBXCRYPT_DIR
  # crypt-hashes.h 不在 git 源码树（INCLUDE_* 无默认值），须从 hashes.conf 生成
  perl build-aux/scripts/gen-crypt-hashes-h lib/hashes.conf "$LIBXCRYPT_ALL" > lib/crypt-hashes.h
  log "Autogen LIBXCRYPT (gitclone 源码树无 configure)..."
  ./autogen.sh 2>&1 || { log "LIBXCRYPT autogen FAIL"; exit 1; }
  log "Configuring LIBXCRYPT..."
  # --disable-werror：musl 的 gen-des-tables 有警告；只要静态
  ./configure --disable-werror --disable-shared --enable-static --prefix=$TARGETPATH
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
  log "Downloading DROPBEAR (2024.86)..."
  rm -rf /tmp/dropbear
  gitclone https://gitee.com/g-system/fk-dropbear /tmp/dropbear --branch=DROPBEAR_2024.86
  log "Configuring DROPBEAR (2024.86)..."
  cd /tmp/dropbear
  # libcrypt.a 前置 whole-archive 到 LDFLAGS——crypt 定义在对象之前, ld 绑定 libxcrypt 的 crypt（yescrypt）
  #   --allow-multiple-definition：musl libc.a 自带 crypt，需允许多重定义
  LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition $LIBXCRYPT_DIR/.libs/libcrypt.a" \
    ./configure --enable-static --prefix=$TARGETPATH
  make LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition -Wl,--whole-archive $LIBXCRYPT_DIR/.libs/libcrypt.a -Wl,--no-whole-archive" \
    LIBS="-lz"
  log "Install DROPBEAR (2024.86)..."
  make install
  ls -lh /tmp/dropbear/
  xx-verify --static /tmp/dropbear/dropbear
  # 兜底：确认真链入 libxcrypt 的 yescrypt（musl 的 crypt 无此符号；产物被 --strip-all 剥符号表，用 strings 查 "$y$"）。
  strings -n 3 /tmp/dropbear/dropbear | grep -qx '\$y\$' \
    || { echo "!! dropbear 未含 yescrypt（libxcrypt 失败）"; exit 1; }
}

# 新版本方法块（2026.94，独立；含 SHA-1 保留 + 后量子 KEX + 各 CVE 修复；官方 GitHub 源）
function dropbear_2026_94(){
  log "Downloading DROPBEAR (2026.94)..."
  rm -rf /tmp/dropbear
  gitclone https://github.com/mkj/dropbear /tmp/dropbear --branch=DROPBEAR_2026.94
  log "Configuring DROPBEAR (2026.94)..."
  cd /tmp/dropbear
  # 2025.87+ 默认禁 SHA-1（hmac-sha1/ssh-rsa/group14-sha1）→ Xshell 4 断连；localoptions.h 显式保留三件套。
  log "Preserve SHA-1 trio (Xshell 4 compat) for 2026.94..."
  printf "#ifndef DROPBEAR_LOCALOPTIONS_H\n#define DROPBEAR_LOCALOPTIONS_H\n#define DROPBEAR_SHA1_HMAC 1\n#define DROPBEAR_RSA_SHA1 1\n#define DROPBEAR_DH_GROUP14_SHA1 1\n#endif\n" > localoptions.h
  # libcrypt.a 前置 whole-archive 到 LDFLAGS——crypt 定义在对象之前, ld 绑定 libxcrypt 的 crypt（yescrypt）
  #   --allow-multiple-definition：musl libc.a 自带 crypt，需允许多重定义
  LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition $LIBXCRYPT_DIR/.libs/libcrypt.a" \
    ./configure --enable-static --prefix=$TARGETPATH
  make LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition -Wl,--whole-archive $LIBXCRYPT_DIR/.libs/libcrypt.a -Wl,--no-whole-archive" \
    LIBS="-lz"
  log "Install DROPBEAR (2026.94)..."
  make install
  ls -lh /tmp/dropbear/
  xx-verify --static /tmp/dropbear/dropbear
  # 兜底：确认真链入 libxcrypt 的 yescrypt（musl 的 crypt 无此符号；产物被 --strip-all 剥符号表，用 strings 查 "$y$"）。
  strings -n 3 /tmp/dropbear/dropbear | grep -qx '\$y\$' \
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
    #   （原只调 dropbear 单组件，未建 /tmp/libxcrypt/.libs/libcrypt.a → 无 yescrypt，登录 authFail）
    doExec libxcrypt || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;
esac
exit 0
