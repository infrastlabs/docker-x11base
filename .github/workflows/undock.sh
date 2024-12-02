#!/bin/bash
cur=$(cd "$(dirname "$0")"; pwd)
cd $cur
set +e
logfile=$cur/oneBuild-syncer.log
dpkg=$cur/.ws/down_pkg
dbin=$cur/.ws/down_bin; mkdir -p $dpkg $dbin
vers=$cur/../../compile/src/vers.txt
function print_time_cost(){
    local item_name=$1
    local begin_time=$2
	gawk 'BEGIN{
		print "['$item_name']本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}' 2>&1 | tee -a $logfile
}

# https://github.com/crazy-max/undock/releases/download/v0.8.0/undock_0.8.0_linux_amd64.tar.gz
# https://github.com/crazy-max/undock/releases/download/v0.8.0/undock_0.8.0_linux_arm64.tar.gz
# https://gitee.com/g-golang/fk-undock/releases/download/v24.12/undock_0.8.0_linux_amd64.tar.gz
function loadBins(){
  file=undock_0.8.0_linux_amd64.tar.gz; URL=https://gitee.com/g-golang/fk-undock/releases/download/v24.12/$file
  curl -o- -k -fSL $URL > $dpkg/$file; 
  # AUTH=root:root; curl -o- -u $AUTH http://172.25.23.203/repository1/platform/2024/$file > $dpkg/$file
  # view
  # echo "cur: $cur"; pwd; 
  ls -lh $dpkg/

  tar -zxf $dpkg/$file -C $dbin/
  ls -lh $dbin/
}
loadBins

# authConf

export LOG_NOCOLOR=true
lognocolor="--log-nocolor"
function doUndock(){
  src=$1; dst=$2
  # test "$dst" == "$src" && return #skip

  # begin_time="`awk 'BEGIN{print systime()}'`"
  # ./image-syncer --proc=3 --force --auth=./conf/auth.yaml --images=./conf/images.yaml --retries=3
  # print_time_cost "sync-ali[$src>$dst]" $begin_time >> /tmp/.timecost #tee -a
  
  rootfs=.ws/rootfs; rm -rf $rootfs
  # echo xxx |docker login $REPO1 --username=admin --password-stdin
  # rmdist="--rm-dist"
  $dbin/undock $lognocolor --include=/rootfs/files1/usr/local/static --insecure $rmdist --all $REPO1/infrastlabs/x11-base:rootfs $rootfs/
  # exit 0
  # view
  # find $rootfs* -type f -name .wh..wh..opq |xargs rm -rf #清理冗余文件(undock's bug?)
  find $rootfs* -type f |sort |wc


  # docker-x11base/.github/workflows/.ws/rootfs/linux_amd64
  # docker-x11base/.github/workflows/.ws/rootfs/linux_amd64/rootfs/files1/usr/local/static/3rd
  # TODO: echo $one|$ver >>rootfs/files1/usr/local/static/vers.txt
  vers2=$(cat $vers |egrep -v "^#|^$" |cut -d'|' -f1-2); #echo "$vers2"
  archs=(amd64 arm64 armv7); pkgs=$cur/.ws/pkgs; mkdir -p $pkgs
  for arch in ${archs[@]}; do 
    echo "arch: $arch";
    files1=$cur/.ws/rootfs/linux_$arch/rootfs/files1; cd $files1
    ls $files1/usr/local/static/|while read one; do
      local ver=latest
      match01=$(echo "$vers2" |grep "$one|")
      test ! -z "$match01" && ver=$(echo "$vers2" |grep "$one|" |cut -d'|' -f2)
      tar -zcf $pkgs/$one-$ver-$arch.tar.gz usr/local/static/$one
    done
    ls -lhS $pkgs/*.tar.gz
  done; 
  # exit 0

}

# REPO1=registry-1.docker.io
REPO1=registry.cn-shenzhen.aliyuncs.com
doUndock
# wait

# lst.txt
cd $cur/../../
find .github/workflows/.ws/pkgs/ -name *.tar.gz |sort > .github/workflows/.ws/pkgs/_lst.txt

exit 0
# headless @ barge in .../.github/workflows |11:32:30  |dev U:1 ?:6 ✗| 
# $ ./undock  -h
# Usage: undock <source> <dist> [flags]
# Extract contents of a container image in a local folder. More info: https://github.com/crazy-max/undock
# Arguments:
#   <source>    Source image. (eg. alpine:latest)
#   <dist>      Dist folder. (eg. ./dist)
# Flags:
#   -h, --help                   Show context-sensitive help.
#       --version
#       --log-level="info"       Set log level ($LOG_LEVEL).
#       --log-json               Enable JSON logging output ($LOG_JSON).
#       --log-caller             Add file:line of the caller to log output ($LOG_CALLER).
#       --log-nocolor            Disable colorized output ($LOG_NOCOLOR).
#       --cachedir=STRING        Set cache path. (eg. ~/.local/share/undock/cache) ($UNDOCK_CACHE_DIR)
#       --platform=STRING        Enforce platform for source image. (eg. linux/amd64)
#       --all                    Extract all architectures if source is a manifest list.
#       --include=INCLUDE,...    Include a subset of files/dirs from the source image.
#       --insecure               Allow contacting the registry or docker daemon over HTTP, or HTTPS with failed TLS verification.
#       --rm-dist                Removes dist folder.
#       --wrap                   For a manifest list, merge output in dist folder.
