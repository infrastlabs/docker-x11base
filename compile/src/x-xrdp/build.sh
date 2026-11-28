#!/bin/sh
set -e
export DOEXEC_CALLER="${DOEXEC_CALLER:-x-xrdp}"
source /src/common.sh

# Define software download URLs.
LIBXRANDR_VERSION=1.5.3
LIBXRANDR_URL=https://www.x.org/releases/individual/lib/libXrandr-${LIBXRANDR_VERSION}.tar.xz

gh=https://ghproxy.com/
gh=https://gh.api.99988866.xyz/
gh=https://ghps.cc/
# 
FDKAAC_VER=2.0.2
FDKAAC_URL=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-${FDKAAC_VER}.tar.gz

#
# 交叉编译环境(arm64/armv7 via xx-clang)。native(未设 XX_CROSS_FILE): 变量留空 → 原路径零影响。
# 参考 x-xbindkeys/xbk_cross + v-engrampa/_cross 惯用法。
# xrdp=autotools: 主 server(xrdp/sesman/chansrv)+子组件 fdkaac 都走 ./configure, 须各补 --host。
# libXrandr.a 无 apk 包 → 由 libxrandr() 自编进 sysroot(b_deps/full 先跑)。
# 注: 本脚本不构建 xorgxrdp(Xorg 后端 driver), 故无 xorg 后端需接 --host。
xrdp_cross(){
  CROSS_HOST=""; MAKE_CC=""; XX_DESTDIR=""
  if [ -n "$XX_CROSS_FILE" ]; then
    CROSS_HOST="--host=$(xx-info triple)"
    MAKE_CC="CC=xx-clang"
    export CC=xx-clang
    export PKG_CONFIG=/usr/bin/pkg-config
    export PKG_CONFIG_LIBDIR="$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig"
    export PKG_CONFIG_SYSROOT_DIR="$XX_SYSROOT"
    unset PKG_CONFIG_PATH   # native /usr/local 旧 .pc 抢先(同 gtk 坑②)
    export ac_cv_func_realloc_0_nonnull=yes
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_prog_cc_cross=yes
    export LDFLAGS="-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib $LDFLAGS"
    # X11 静态传递依赖: configure 的 AC_PATH_XTRA 用 XrmInitialize() 做链接测试只链 -lX11;
    #   交叉下解析到静态 libX11.a → 其依赖 xcb_*(xcb_connect/disconnect/...) 在 libxcb.a 未链 → undefined
    #   → 误报 "please install libx11-dev"(native 用 .so 无此问题)。补 xcb/Xau/Xdmcp/X11-xcb 进 LIBS 供测试链。
    export LIBS="-lxcb -lXau -lXdmcp -lX11-xcb $LIBS"
    XX_DESTDIR="$(xx-info sysroot)"   # 子组件(fdkaac)装进 sysroot 供 configure/pkg-config 探测
    # sysroot 补 X11/静态库(幂等; 命中已装则 no-op)。包名均取自本脚本 native apk 行或实测 Alpine。
    # 公共库(X11链+openssl+fontconfig+freetype+pixman)已由 u-gtk 统一装(1.4.1); 此处仅留单次(fuse/fdk-aac/opus/lame)
    xx-apk add \
      fuse-dev fuse-static \
      fdk-aac-dev opus-dev lame-dev
    log "xrdp: CROSS ($XX_TRIPLE)"
  fi
}

# 交叉真验: file 判目标架构(static); native 走 xx-verify(原路径)。
# xrdp configure 同时 --enable-static + --enable-shared, 产物可能动态链 libcommon——
#   故交叉下 arch 必判(硬失败), static 仅记录(不硬失败)。bin/ 与 sbin/ 两处都查(版本安装位置不一)。
# 注: xorgxrdp 后端非本脚本构建, 故不在此校验。
xrdp_verify(){
  local b d p
  # fk-xrdp sam-custom 分支顶层 SUBDIRS 已注释 sesman(不构建), 故只验 xrdp / xrdp-chansrv。
  for b in xrdp xrdp-chansrv; do
    p=""
    for d in $TARGETPATH/sbin $TARGETPATH/bin; do
      test -x "$d/$b" && { p="$d/$b"; break; }
    done
    if [ -z "$p" ]; then
      log "XRDP verify: $b NOT FOUND (bin/sbin), skip"; continue
    fi
    if [ -n "$XX_CROSS_FILE" ]; then
      file "$p" | grep -qE "ARM|aarch64" \
        || { log "XRDP $b file 非 ARM/目标架构"; exit 1; }
      log "XRDP verify OK(cross): $p ($(file -b "$p" | cut -d, -f1-2))"
    else
      xx-verify --static "$p" || { log "XRDP $b xx-verify FAILED"; exit 1; }
    fi
  done
}

#
# Build libXrandr.
# The static library is not provided by Alpine repository, so we need to build
# it ourself.
#
function libxrandr(){
  # rm -rf: 复用上一次(可能 arm64)遗留的 $SRCROOT/libxrandr(其 .o/configure 为旧架构)会让 armv7 也编成 aarch64
  #   (8s 太快=没真重编)。先清场再解包, 确保 --host=$(xx-clang triple) 生效。
  rm -rf $SRCROOT/libxrandr; mkdir $SRCROOT/libxrandr
  log "Downloading libXrandr..."
  # curl -s -L -f ${LIBXRANDR_URL} | tar -xJ --strip 1 -C $SRCROOT/libxrandr
  down_catfile ${LIBXRANDR_URL} | tar -xJ --strip 1 -C $SRCROOT/libxrandr
  log "Configuring libXrandr..."
  (
      cd $SRCROOT/libxrandr && LDFLAGS= ./configure \
          --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
          --host=$(xx-clang --print-target-triple) \
          --prefix=/usr \
          --disable-shared \
          --enable-static \
          --enable-malloc0returnsnull \
  )
  log "Compiling libXrandr..."
  make -C $SRCROOT/libxrandr -j$(nproc)
  log "Installing libXrandr..."
  make DESTDIR=$(xx-info sysroot) -C $SRCROOT/libxrandr install
  xx_la_fix   # 交叉: 修 sysroot .la libdir(防下游按名解析到 native 错架构 .a); native no-op
}

#
# Build xrdp
#
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err
function fdkaac(){
  xrdp_cross
  # - fdkaac
  # 2026-11-25: 源 sourceforge(opencore-amr)整站不可达(超时/DNS), github 无 2.0.2 release tarball。
  #   改 git clone 指定 tag——优先 gitee fk-fdk-aac(可达/快), tag 为 v2.0.2(带 v 前缀)。
  #   git 源码无预生成 configure → 须先 ./autogen.sh(autoreconf)生成。
  # 原下载方式(留档, 现不用):
  #   down_catfile ${FDKAAC_URL} | tar -zx --strip 1 -C $SRCROOT/fdkaac
  rm -rf $SRCROOT/fdkaac
  log "Cloning FDKAAC (gitee fk-fdk-aac v2.0.2)..."
  gitclone https://gitee.com/g-system/fk-fdk-aac $SRCROOT/fdkaac --branch=v2.0.2
  log "autogen FDKAAC..."
  cd $SRCROOT/fdkaac && ./autogen.sh
  log "Configuring FDKAAC..."
  ./configure --enable-static $CROSS_HOST
  make $MAKE_CC
  make DESTDIR=$XX_DESTDIR install
  xx_la_fix   # 交叉: 修 sysroot .la libdir; native(XX_DESTDIR 空)装 /usr/local 原路径
}

#
# Build xrdp
#
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err
function xrdp(){
  xrdp_cross
  # ./configure
  #  220 apk add pam-dev
  apk add fuse-static
  apk add fuse-dev fdk-aac-dev opus-dev lame-dev;
  apk add nasm
  # TODO2611(临时, 本地应用层补): 公共库(u-gtk)那边还有问题——openssl 未统一装齐 dev+静态,
  #   xrdp configure 需 libssl-dev(openssl-dev 头), 静态链需 libcrypto.a/libssl.a(openssl-libs-static)。
  apk add openssl-dev openssl-libs-static >/dev/null 2>&1 || log "WARN: openssl 补装失败(configure 需 libssl-dev)"

  # tar -zxf $CACHE/xrdp-${XRDP_VER}.tar.gz -C /tmp;\
  # cd $SRCROOT/xrdp-${ver};\
  rm -rf $SRCROOT/xrdp; mkdir -p $SRCROOT/xrdp
  log "Downloading XRDP..."
  # down_catfile ${XRDP_URL} | tar -zx --strip 1 -C $SRCROOT/xrdp
  rm -rf $SRCROOT/xrdp;
  gitclone https://gitee.com/g-system/fk-xrdp $SRCROOT/xrdp --branch=sam-custom

  # 2026-11-25: fk-xrdp 子模块(libpainter/librfxcodec)的 .gitmodules 硬编 ghps.cc 已失效
  #   (redirection 失败→子模块拉不到→bootstrap/configure 连锁失败)。改写为 ghfast.top(实测可达);
  #   submodule sync 把新 URL 同步进 .git/config, 随后 ./bootstrap 的 submodule init 才拉得到。
  sed -i 's|https://ghps.cc/|https://ghfast.top/|g' $SRCROOT/xrdp/.gitmodules
  git -C $SRCROOT/xrdp submodule sync

  log "Configuring XRDP..."
  cd $SRCROOT/xrdp && ./bootstrap;

  # fix code
  # #define _GNU_SOURCE=Musl fixes by maxice8 · Pull Request #1673 · neutrinolabs/xrdp
  # https://github.com/neutrinolabs/xrdp/pull/1673/files
  sed -i "s^putpwent(spw, fd);^// putpwent(spw, fd);^g" ./sesman/verify_user.c

  # before ./configure
  # deps:
  #23 222.8 make[2]: Entering directory '$SRCROOT/xrdp/sesman/chansrv'
  #23 222.8   CCLD     xrdp-chansrv
  #23 223.0 /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lXrandr
  #23 223.0 /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lfuse
  f=sesman/chansrv/Makefile.am
  # 静态传递依赖: -lXrandr(静态.a) 依赖 Xext(XMissingExtension/XextRemoveDisplay) 与 Xrender
  #   (XRenderSetSubpixelOrder), 不链则 chansrv link undefined。补 -lXext -lXrender。
  sed -i "s^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11^\$(X_PRE_LIBS) -lXfixes -lXrandr -lXext -lXrender -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
  cat $f |grep lX11 -n

  f=sesman/tools/Makefile.am
  sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
  cat $f |grep lX11 -n

  # genkeymap/Makefile.am 
  f=genkeymap/Makefile.am 
  sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
  cat $f |grep lX11 -n

  # 交叉: keygen 的 install-data-hook 运行 ./xrdp-keygen(已被交叉编成目标架构)在宿主生成 rsakeys.ini
  #   → ARM/aarch64 二进制 x86 宿主跑不起(syntax error)→ make install 中断。rsakeys.ini 属目标机运行时产物,
  #   构建期跳过: 中性化 keygen/Makefile.am 的 keygen 调用(cross 下生效; native 无 XX_CROSS_FILE 不动)。
  if [ -n "$XX_CROSS_FILE" ]; then
    sed -i "s|^\(\s*\)\./xrdp-keygen |\1true # cross: skip target-arch keygen |" keygen/Makefile.am
  fi

  # --disable-pam \
  # --disable-pam --enable-static===
  # https://github.com/PWN-Term/pwn-packages/blob/df4740ecf3dc3433c869abd515964e60dea7dd0c/packages/xrdp/build.sh
  # --disable-shared \ >> --enable-shared \ ##无lib/libvnc.so
  # --enable-static \ >> --disable-static \ ##avoid xx.a 
  # --enable-devel-all<debug,logging,streamCheck>
  ./configure \
    --prefix=$TARGETPATH \
    --enable-vsock \
    --enable-fdkaac \
    --enable-opus \
    --enable-fuse \
    --enable-mp3lame \
    --enable-pixman \
    --disable-pam \
    --enable-static \
    --enable-shared \
    --enable-devel-all \
    $CROSS_HOST
    # LIBS="-lcommon" #c.compiler err
    # LIBS="-lrt -lcommon -lcrypto -lssl "
    # --enable-strict-locations
    #CFLAGS='-Wno-format';


  # 手动注释行： putpwent;
    # # ERR01: 手动改code;
    # # verify_user.c:221:9: error: implicit declaration of function 'putpwent' is invalid in C99 [-Werror,-Wimplicit-function-declaration]
    # #         putpwent(spw, fd);
    # # vi ./sesman/libsesman/verify_user.c
    # # vi ./sesman/verify_user.c
    # sed -i "s^putpwent(spw, fd);^// putpwent(spw, fd);^g" ./sesman/verify_user.c


  # STATIC
    # export LDFLAGS="--static -static -Wl,--strip-all -Wl,--as-needed"
    # export LDFLAGS="--static"
    # /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lssl
    # /usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lcrypto
    # apk add openssl-libs-static

    # xcb-err:
    # https://pkgs.alpinelinux.org/packages?name=*xcb*&branch=edge&repo=&arch=x86_64&maintainer=
    #   libxcb-static #已装
    #   oth_已装; xcb-util-dev xcb-util已装; xcb-util-xx看着不相关;
    # apk add libxcb-static

  # xrdp-chansrv
    # # 禁用fdkaac: --enable-fdkaac \>> --disable-fdkaac \

    # # - **sesman/chansrv/Makefile** [-lX11-xcb -lxcb]
    # # sesman/chansrv/Makefile.am ##foot
    # xrdp_chansrv_LDADD = \
    #   $(top_builddir)/common/libcommon.la \
    #   $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LIBS) \
    #   $(CHANSRV_EXTRA_LIBS)
    # # Makefile @421行
    # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
    # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 $(X_EXTRA_LI

    # # 添加： -lX11-xcb -lxcb>> 错误少了
    # /mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
    # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/chansrv/Makefile |grep lX11 -n
    # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb $(X_EXTRA_LIBS) \

    # # 添加：-lXdmcp -lXau ; >> 只余下sound错误;
    # /mnt2/xrdp-repo-v0.9.23-02 # vi sesman/chansrv/Makefile
    # /mnt2/xrdp-repo-v0.9.23-02 # make -C sesman/chansrv/

    # compile: fdk-aac
    # 添加：-lfdk-aac
    # root@VM-12-9-ubuntu:/mnt/xrdp-repo-v0.9.23-02# cat sesman/chansrv/Makefile |grep lX11 -n
    # 421:  $(X_PRE_LIBS) -lXfixes -lXrandr -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac  $(X_EXTRA_LIBS) \
    
    # # before ./configure
    # sed -i "s^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" sesman/chansrv/Makefile.am
    # cat sesman/chansrv/Makefile.am |grep lX11 -n


  # sesman/tools/xrdp-con
    # -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac
    # /mnt2/xrdp-repo-v0.9.23-02 # cat sesman/tools/Makefile |grep lX11 -n
    # 411:  $(X_PRE_LIBS) -lX11 -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac $(X_EXTRA_LIBS)


  log "make XRDP..."
  make $MAKE_CC;
  log "install XRDP..."
  make install;
  xrdp_verify

  # # libvnc.so
  # cd $TARGETPATH/lib/xrdp
  # gcc -shared -o libvnc.so libvnc.a 
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    doExec libxrandr || exit 1
    doExec fdkaac || exit 1
    doExec xrdp || exit 1
    ;;
b_deps)
    doExec_mark "x-xrdp b_deps grp"
    doExec bash /src/x-xrdp/build.sh libxrandr &
    doExec bash /src/x-xrdp/build.sh fdkaac &
    wait
    doExec_check || exit 1
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
