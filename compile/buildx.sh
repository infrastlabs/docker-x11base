


source /etc/profile
export |grep DOCKER_REG
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo

repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub

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
    cimg="x11-base-cache:ubt-builder"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
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
    cimg="x11-base-cache:deb12-builder"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm" #
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/ubt/Dockerfile.deb12 . 
    test "0" == "$?" && build_rootfs || exit $err
    ;;
builder)
    repo=registry-1.docker.io
    img="x11-base:alpine-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:builder"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/Dockerfile.builder . 
    ;;
gtk224)
    repo=registry-1.docker.io
    img="x11-base:alpine-builder-gtk224"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:builder-gtk224"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64" #dbg
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/Dockerfile.builder.gtk224 . 
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
    img="x11-base:alpine-compile"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:compile"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64" #dbg
    
    compile="alpine-compile"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    args="--provenance=false"
    # full yes x9: 5h,9min,44s
    args="""
    --provenance=false 
    --build-arg COMPILE_IMG=$compile
    --build-arg COMPILE_TIGER=no
    --build-arg COMPILE_XRDP=no
    --build-arg COMPILE_SSH=no
    --build-arg COMPILE_PULSE=no
    --build-arg COMPILE_FLUX=no
    --build-arg COMPILE_OPENBOX=yes
    --build-arg COMPILE_TINT2=no
    --build-arg COMPILE_SUCKLESS=no
    --build-arg COMPILE_XCOMPMGR=yes
    --build-arg COMPILE_XLUNCH=yes
    --build-arg COMPILE_PCMANFM=no
    --build-arg COMPILE_LXDE=no
    --build-arg COMPILE_PERP=no
    """
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    docker buildx build $cache $plat $args --push -t $repo/$ns/$img -f src/Dockerfile . 
    # err=$?
    # test "0" == "$err" && build_rootfs || exit $err
    ;;          
esac