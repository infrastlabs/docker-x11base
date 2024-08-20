source /etc/profile
export |grep DOCKER_REG
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo

ns=infrastlabs
# cache="--no-cache"
# pull="--pull"

ver=v1 # latest
case "$1" in
*) #pkgs
    img="x11-base:pkgs-$ver"
    docker build $cache $pull -t $repo/$ns/$img -f src/Dockerfile . 
    docker push $repo/$ns/$img
    # view down 
    du -sh down/*; tree -h down/
    ;;
esac
