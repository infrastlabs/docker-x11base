


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
    docker buildx build $plat $args --push -t $ns/$img -f $dockerfile . 
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
builder)
    repo=registry-1.docker.io
    img="x11-base:builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:builder"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $ns/$img -f src/../Dockerfile.builder . 
    ;;
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
    docker buildx build $cache $plat --push -t $ns/$img -f src/../ubt/Dockerfile.builder . 
    ;;
deb12-builder)
    repo=registry-1.docker.io
    img="x11-base:deb12-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:deb12-builder"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $ns/$img -f src/../ubt/Dockerfile.deb12 . 
    test "0" == "$?" && build_rootfs || exit $err
    ;;
flux)
    # repo=registry-1.docker.io
    repo=registry.cn-shenzhen.aliyuncs.com
    img="x11-base:fluxbox"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:fluxbox"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64"
    cd flux
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/Dockerfile . 
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
    img="x11-base:compile"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:compile"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm" #
    # plat="--platform linux/amd64" #6m
    args="--provenance=false"
    args="""
    --provenance=false 
    --build-arg COMPILE_XRDP=yes
    --build-arg COMPILE_PULSE=yes
    --build-arg COMPILE_TIGER=yes
    """
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat $args --push -t $ns/$img -f src/../Dockerfile . 
    err=$?
    test "0" == "$err" && build_rootfs || exit $err
    ;;          
esac