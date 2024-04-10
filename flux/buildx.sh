
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
    # repo=registry.cn-shenzhen.aliyuncs.com
    img="x11-base:$tag"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:$tag"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64" #

    compile="alpine-compile";
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    args="""
    --provenance=false 
    --build-arg COMPILE_IMG=$compile
    """

    # cd flux
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    # # alma:无armv7
    # test "alma" == "$tag" && plat="--platform linux/amd64,linux/arm64"
    docker buildx build $cache $plat $args --push -t $repo/$ns/$img -f $dockerfile . 
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
rootfs)
    doBuildx rootfs src/Dockerfile
    ;;
*)
    # doBuildx $1 src/Dockerfile.$1
    echo "emp params"
    ;;          
esac