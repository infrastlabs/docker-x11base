
source /etc/profile
export |grep DOCKER_REG |grep -Ev "PASS|PW"
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo
repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub

function print_time_cost(){
    local item_name=$1
    local begin_time=$2
	gawk 'BEGIN{
		print "['$item_name']本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}'
}
PLAT0="--platform linux/amd64,linux/arm64,linux/arm"
test "$type" != "app" && PLAT0="--platform linux/amd64,linux/arm64" #app:none-armv7
function doBuildx(){
    local tag=$1
    local dockerfile=$2

    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:$tag"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="x11-base-cache:$tag"
    
    compile="alpine-compile"; flux=rootfs #fluxbox
    plat="$PLAT0" #,linux/arm
    test "fedora" == "$dist" && plat="--platform linux/amd64,linux/arm64" # alma/fedora:无armv7
    # plat="--platform linux/amd64" #dbg

    test "$plat" != "$PLAT0" && compile="${compile}-dbg"
    test "$plat" != "$PLAT0" && img="${img}-dbg"
    test "$plat" != "$PLAT0" && cimg="${cimg}-dbg"
    

    # 提前pull,转换tag格式
    if [ "openwrt" == "$dist" ]; then
        docker pull --platform=linux/amd64 openwrt/rootfs:x86_64-openwrt-23.05
        docker pull --platform=linux/aarch64_generic openwrt/rootfs:armsr-armv8-openwrt-23.05 #aarch64_generic-openwrt-23.05
        docker pull --platform=linux/arm_cortex-a15_neon-vfpv4   openwrt/rootfs:armsr-armv7-openwrt-23.05
        dst=infrastlabs/x11-base:openwrt-rootfs
        docker tag openwrt/rootfs:x86_64-openwrt-23.05 $dst-amd64; docker push $dst-amd64
        docker tag openwrt/rootfs:armsr-armv8-openwrt-23.05 $dst-arm64; docker push $dst-arm64
        docker tag openwrt/rootfs:armsr-armv7-openwrt-23.05 $dst-arm; docker push $dst-arm
    fi
    
    args="""
    --provenance=false 
    --build-arg COMPILE_IMG=$compile
    --build-arg REPO=$repo/
    --build-arg TYPE=$type
    --build-arg VER=$dver
    """
    cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    docker buildx build $cache $plat $args --push -t $repo/$ns/$img -f $dockerfile . 
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
type=$1
dist=$2
dver=$3
tag=$type-$dist
test ! -z "$dver" && tag=$type-$dist-$dver

:> /tmp/.timecost
begin_time="`gawk 'BEGIN{print systime()}'`"
case "$dist" in
alpine|ubuntu|opensuse)
    doBuildx "$tag" src/Dockerfile.*-$dist #core,app
    ;;  
*)
    doBuildx "$tag" src/oth/Dockerfile.*-$dist #core only
    ;;          
esac
print_time_cost "$tag" $begin_time >> /tmp/.timecost #tee -a
