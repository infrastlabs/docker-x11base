#!/bin/bash
cur=$(cd "$(dirname "$0")"; pwd)

# ref fk-edgecore-indocker//bins2/tplat.sh
# : > $cur/down/.list.txt
function tplat(){
  TARGETPLATFORM=$1; URL=$2; F=$3
  dest=$(echo $URL |sed "s^https://^^g" |sed "s^%2B^+^g")
  # dest=$(echo $URL |sed "s^https://ghproxy.com/^^g" |sed "s^hub.yzuu.cf^github.com^g" \
  #   |sed "s^https://^^g" |sed "s^%2B^+^g") #%2B: +
  file=${dest##*/};dest=${dest%/*};
  test ! -z "$F" && file=$F; echo "destDir: $dest, file: $file"

  dst2=$ws/$TARGETPLATFORM/$dest; mkdir -p $dst2
  test -s $dst2/$file && echo "existed, skip" || curl -k -fSL -o $dst2/$file $URL
  test -s $dst2/$file && echo "existed, skip[wget]" || wget --no-check-certificate -O $dst2/$file $URL #126music: curl-403-err; wget-ok
  # echo $ws/$TARGETPLATFORM/$dest/$file >> $cur/down/.list.txt
}

function pkg2408(){
  ws=$cur/down/2408
  mkdir -p $ws; cd $ws 
  ##[2408]#####################
  # browser
  # https://www.firefox.com.cn/download/#product-desktop-esr
    # https://download-ssl.firefox.com.cn/releases/firefox/116.0/zh-CN/Firefox-latest-x86_64.tar.bz2
    tplat amd64 https://download-ssl.firefox.com.cn/releases/firefox/esr/115.1/zh-CN/Firefox-latest-x86_64.tar.bz2 Firefox-esr115.1-x86_64.tar.bz2
  # https://www.mozilla.org/zh-CN/firefox/all/#product-desktop-esr

  # DEV
    tplat common https://download.jetbrains.com/idea/ideaIC-2017.3.7-no-jdk.tar.gz
    # https://code.visualstudio.com/updates
    tplat amd64 https://update.code.visualstudio.com/1.92.2/linux-x64/stable vscode-1.92.2-linux-amd64.tar.gz
    tplat arm64 https://update.code.visualstudio.com/1.92.2/linux-arm64/stable vscode-1.92.2-linux-arm64.tar.gz
    # https://vscode.download.prss.microsoft.com/dbazure/download/stable/fee1edb8d6d72a0ddff41e5f71a671c23ed924b9/code-stable-x64-1723659430.tar.gz #v1.92

  # OFFICE (x64-only)
    tplat amd64 https://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb #24.8.20: 官网down链接已下架; curl-403-err; wget-ok
    tplat amd64 https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10161/wps-office_11.1.0.10161_amd64.deb
    # 24.8.20: org-deb,rpm >> nginx-403-err
    # https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/11723/wps-office_11.1.0.11723_amd64.deb
    # https://wps-linux-personal.wpscdn.cn/wps/download/ep/Linux2019/11723/wps-office-11.1.0.11723-1.x86_64.rpm
}

cmd=$1; test -z $cmd && cmd=pkg2408
$cmd


