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
function dropbear(){
  log "Downloading DROPBEAR..."
  rm -rf /tmp/dropbear; # mkdir -p /tmp/dropbear
  # down_catfile ${DROPBEAR_URL} | tar -zx --strip 1 -C /tmp/dropbear
  branch="--branch=DROPBEAR_2024.86"
  # https://github.com/mkj/dropbear
  #  master 2037
  #  DROPBEAR_2024.86 2031
  #  DROPBEAR_2022.83 1863
  gitclone https://gitee.com/g-system/fk-dropbear /tmp/dropbear $branch #;
  log "Configuring DROPBEAR..."
  cd /tmp/dropbear #&& ./bootstrap;
  # configure 检测 crypt 需要 libcrypt.a 可见（放 LDFLAGS 实测可过）；
  # --allow-multiple-definition：musl libc.a 自带 crypt，需允许多重定义
  LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition $LIBXCRYPT_DIR/.libs/libcrypt.a" \
    ./configure --enable-static --prefix=$TARGETPATH
  # 关键：libcrypt.a 必须放 LIBS（对象之后）才能被 ar 拉入；
  # 放 LDFLAGS（对象之前）时无未定义符号，不会被链入，crypt() 退回 musl（无 yescrypt）。
  make LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition" \
    LIBS="-lz $LIBXCRYPT_DIR/.libs/libcrypt.a"

  log "Install DROPBEAR..."
  # make;
  make install;

  # view
  ls -lh /tmp/dropbear/
  xx-verify --static /tmp/dropbear/dropbear
  # 兜底：确认真链入 libxcrypt 的 yescrypt（musl 的 crypt 无此符号）。
  # 产物被 --strip-all 剥符号表，nm 看不到；用 strings 查 hash_algorithms 表 "$y$" 前缀。
  strings -n 3 /tmp/dropbear/dropbear | grep -qx '\$y\$' \
    || { echo "!! dropbear 未含 yescrypt（libxcrypt 失败）"; exit 1; }
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec libxcrypt || exit 1
    doExec dropbear || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
