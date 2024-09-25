
source /etc/profile
export |grep DOCKER_REG |grep -Ev "PASS|PW"
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo
repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub


function doBuildx(){
    local tag=$1
    local dockerfile=$2

    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:$tag"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64" #

    compile="alpine-compile"; builddate=$(date +%Y-%m-%d_%H:%M:%S)
    # test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    # --build-arg REPO=$repo/ #temp notes, just use dockerHub's
    args="""
    --provenance=false 
    --build-arg REPO=$repo/
    --build-arg COMPILE_IMG=$compile
    --build-arg NOCACHE=$builddate
    --build-arg BUILDDATE=$builddate
    """

    # cd flux
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    
    # ref :3000/sam/quickstart-dockerfile >> mode=max
    #  oci-mediatypes=true,image-manifest=true,:ali-403-forbidden
      # export REPO_ALI=registry.cn-shenzhen.aliyuncs.com
      # export REPO_TEN=ccr.ccs.tencentyun.com
      # export REPO_TEN_HK=hkccr.ccs.tencentyun.com #/infrastlabs/repo1
      # export REPO_QING=dockerhub.qingcloud.com #无Area.zone分区
      ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    # --output type=image,name=$repo/base/env-system:alpine313-$ver-bc,push=true,oci-mediatypes=true,registry.insecure=true,annotation.author=sam
    # ----------
    # docker buildx build -h
    # --push                          Shorthand for "--output=type=registry"
    # --load                          Shorthand for "--output=type=docker"
    # -o, --output stringArray            Output destination (format: "type=local,dest=path")
    
    # # alma:无armv7
    # test "alma" == "$tag" && plat="--platform linux/amd64,linux/arm64"
    # output="--push -t $repo/$ns/$img"
    # registry.insecure=true,
    # ERROR: "docker buildx build" requires exactly 1 argument.
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f $dockerfile . 

    # ref :3000/sam/quickstart-dockerfile//README
    # buildctl build \
    #     --frontend=dockerfile.v0 \
    #     --local context=./env-system/ \
    #     --local dockerfile=./env-system/ \
    #     --opt filename=./Dockerfile.alpine313 \
    #     --opt platform=linux/amd64,linux/arm64 \
    #     \
    #     --import-cache type=registry,ref=$repo/base/env-system:alpine313-$ver-bccache \
    #     --export-cache type=registry,ref=$repo/base/env-system:alpine313-$ver-bccache,oci-mediatypes=true,image-manifest=true \
    #     --output type=image,name=$repo/base/env-system:alpine313-$ver-bc,push=true,oci-mediatypes=true,registry.insecure=true,annotation.author=sam
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