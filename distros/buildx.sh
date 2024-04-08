
source /etc/profile
export |grep DOCKER_REG
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo

repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub


function doBuildx(){
    local tag=$1
    local dockerfile=$2

    repo=registry-1.docker.io
    repo=registry.cn-shenzhen.aliyuncs.com
    img="x11-base:$tag"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:$tag"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64" #

    compile="alpine-compile"; flux=rootfs #fluxbox
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && flux="${flux}-dbg"
    args="""
    --provenance=false 
    --build-arg COMPILE_IMG=$compile
    --build-arg ROOTBOX_IMG=$flux
    """

    # cd flux
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    # alma:无armv7
    test "alma" == "$tag" && plat="--platform linux/amd64,linux/arm64"
    test "fedora" == "$tag" && plat="--platform linux/amd64,linux/arm64"

    if [ "openwrt" == "$tag" ]; then
        docker pull --platform=linux/amd64 openwrt/rootfs:x86_64-openwrt-23.05
        docker pull --platform=linux/aarch64_generic openwrt/rootfs:armsr-armv8-openwrt-23.05 #aarch64_generic-openwrt-23.05
        docker pull --platform=linux/arm_cortex-a15_neon-vfpv4   openwrt/rootfs:armsr-armv7-openwrt-23.05
        dst=infrastlabs/x11-base:openwrt-rootfs
        docker tag openwrt/rootfs:x86_64-openwrt-23.05 $dst-amd64; docker push $dst-amd64
        docker tag openwrt/rootfs:armsr-armv8-openwrt-23.05 $dst-arm64; docker push $dst-arm64
        docker tag openwrt/rootfs:armsr-armv7-openwrt-23.05 $dst-arm; docker push $dst-arm
    fi
    

    docker buildx build $cache $plat $args --push -t $repo/$ns/$img -f $dockerfile . 
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
*)
    doBuildx "core-$1" src/Dockerfile.*-$1
    ;;          
esac