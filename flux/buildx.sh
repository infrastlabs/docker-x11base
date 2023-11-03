
source /etc/profile
export |grep DOCKER_REG
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo

repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub


ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
flux)
    # repo=registry-1.docker.io
    repo=registry.cn-shenzhen.aliyuncs.com
    img="x11-base:fluxbox"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:fluxbox"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    plat="--platform linux/amd64" #

    compile="alpine-compile"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    args="""
    --provenance=false 
    --build-arg COMPILE_IMG=$compile
    """

    # cd flux
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    docker buildx build $cache $plat $args --push -t $repo/$ns/$img -f src/Dockerfile . 
    ;;
*)
    ;;          
esac