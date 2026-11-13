


source /etc/profile
export |grep DOCKER_REG |grep -Ev "PASS|PW"
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo
repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub

# tarsrc 源码包仓库（gitee）：depth1 提前克隆到 compile/tarsrc/（=$(dirname $0)/tarsrc，与 down_catfile 默认 /src/../tarsrc 同址）。
# down_catfile（common.sh）会按需再 clone（幂等）；此处提前备好供容器 /src/../tarsrc 复用。
_TS=$(dirname "$0")/tarsrc
test -d "$_TS/.git" || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc "$_TS" 2>&1 | tail -1 || true

function build_rootfs(){
    dockerfile=/tmp/Dockefile.rootfs
    cat > $dockerfile<<EOF
FROM infrastlabs/x11-base:deb12-builder as compile
FROM alpine:3.15
COPY --link --from=compile /rootfs /rootfs
EOF
    repo=registry-1.docker.io
    img="x11-base:deb12-rootfs"
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    args="--provenance=false"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $plat $args --push -t $repo/$ns/$img -f $dockerfile . 
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
ubt-builder)
    repo=registry-1.docker.io
    img="x11-base:ubt-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/ubt/Dockerfile.builder . 
    ;;
deb12-builder)
    repo=registry-1.docker.io
    img="x11-base:deb12-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm" #
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/ubt/Dockerfile.deb12 . 
    test "0" == "$?" && build_rootfs || exit $err
    ;;
builder)
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-builder"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder . 
    ;;
gtk224)
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac REPO_TEN
    # repo=$REPO_TEN
    img="x11-base:alpine-builder-gtk224-2"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    plat="--platform linux/amd64" #dbg
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder.gtk224 . 
    ;;
gtkmm224) #gtk/gtkmm全串一起: 超过gitac.max:6h而fail!
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-builder-gtkmm224-2"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    plat="--platform linux/amd64" #dbg
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder.gtkmm224 . 
    ;;
*) #compile
    # TigerVNC 1.12.0 |10 Nov 2021
    # old=$(pwd); cd src/..
    #     # xrdp
    #     ver="0.9.16"
    #     file=xrdp-${ver}.tar.gz; test -s $file || curl -k -O -fSL https://github.com/neutrinolabs/xrdp/releases/download/v${ver}/$file
    #     # tiger
    #     file=xorg-server-1.20.7.tar.bz2; test -s $file || curl -k -O -fSL https://www.x.org/pub/individual/xserver/$file #6.1M
    #     file=tigervnc-1.12.0.tar.gz; test -s $file || curl -k -O -fSL https://github.com/TigerVNC/tigervnc/archive/v1.12.0/$file #1.5M
    #     # curl -O -fsSL https://www.linuxfromscratch.org/patches/blfs/svn/tigervnc-1.12.0-configuration_fixes-1.patch
    # cd $old;
    #  
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-compile-2"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm64" #pulse-arm-dbg
    plat="--platform linux/amd64" #dbg
    
    compile="alpine-compile-2"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    compile="alpine-compile" ########V2 TEST, AVOID DBG
    args="--provenance=false"
    # full yes x9: 5h,9min,44s
    # 11-04 后新增/调整项 CI 开关（默认不启用，需显式 --build-arg COMPILE_*=no/yes 才建）
    args="""
    --provenance=false 
    --build-arg REPO=$repo/
    --build-arg COMPILE_IMG=$compile
    --build-arg COMPILE_TIGER=no
    --build-arg COMPILE_XRDP=no
    --build-arg COMPILE_X11VNC=no
    --build-arg COMPILE_SSH=no
    --build-arg COMPILE_FLUX=no
    --build-arg COMPILE_OPENBOX=no
    --build-arg COMPILE_SUCKLESS=no
    --build-arg COMPILE_XCOMPMGR=no
    --build-arg COMPILE_PERP=no
    --build-arg COMPILE_MISC=no

    --build-arg COMPILE_FEH=no
    --build-arg COMPILE_HSETROOT=no
    --build-arg COMPILE_SCROT=no
    --build-arg COMPILE_TINT2=no
    --build-arg COMPILE_XLUNCH=no

    --build-arg COMPILE_XBINDKEYS=no
    --build-arg COMPILE_XRANDR=yes
    --build-arg COMPILE_DUNST=yes
    --build-arg COMPILE_ROFI=no
    --build-arg COMPILE_PULSE=no
    --build-arg COMPILE_PASYSTRAY=no
    --build-arg COMPILE_PAVUCONTROL=no
    --build-arg COMPILE_SYSMONITOR=no
    
    --build-arg COMPILE_LXDE=yes
    --build-arg COMPILE_PCMANFM=no
    --build-arg COMPILE_XFCE4=no
    --build-arg COMPILE_GEANY=yes
    --build-arg COMPILE_ENGRAMPA=no
    --build-arg COMPILE_GPICVIEW=no
    --build-arg COMPILE_DBUS=no
    --build-arg COMPILE_IBUS=no
    --build-arg BUILDDATE=$(date +%Y-%m-%d_%H:%M:%S)
    """
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"

    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/Dockerfile . 
    # err=$?
    # test "0" == "$err" && build_rootfs || exit $err
    ;;          
esac