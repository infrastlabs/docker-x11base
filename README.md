# docker-x11base

**Features**

- package the system by your dotfiles with docker
- box/server side headless deploy
- multi remote entry: noVNC, Xrdp, SSH; Audio supported
- suckless misc, static built binary for any distribution
- multi arch, current suport: amd64, arm64, armv7

[![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/rootfs)](https://hub.docker.com/r/infrastlabs/docker-x11base/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/infrastlabs/x11-base.svg)](https://hub.docker.com/r/infrastlabs/docker-x11base)
[![Last commit](https://img.shields.io/github/last-commit/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/graphs/contributors)
[![GitHub issues](https://img.shields.io/github/issues/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/issues)

**Run**

```bash
# cmd: [port novnc:10081, ssh:10022, xrdp:10089]
docker run -it --rm --net=host -e VNC_OFFSET=21 infrastlabs/x11-base:core-alpine #app-alpine
REPO=registry.cn-shenzhen.aliyuncs.com/ #ccr.ccs.tencentyun.com/  dockerhub.qingcloud.com/ registry-1.docker.io/
docker run -it --rm --net=host -e START_SESSION2=xfce4-session ${REPO}infrastlabs/x11-base:app-ubuntu

# app [dcp docker-compose]
REPO=registry.cn-shenzhen.aliyuncs.com/ #ccr.ccs.tencentyun.com/  dockerhub.qingcloud.com/ registry-1.docker.io/
DESK=xfce4-session #startfluxbox openbox-session xfce4-session
echo -e "REPO=$REPO\nDESK=$DESK\n"> .env

curl -k -fSL -O https://gitee.com/infrastlabs/docker-x11base/raw/dev/docker-compose.yml
dcp pull; dcp up -d

# core [distros: rootfs alpine ubuntu opensuse busybox openwrt debian fedora]
curl -k -fSL -o docker-compose.yml https://gitee.com/infrastlabs/docker-x11base/raw/dev/docker-compose-core.yml
dist=rootfs;   dcp pull $dist; dcp up -d $dist
dist=alpine;   dcp pull $dist; dcp up -d $dist
dist=ubuntu;   dcp pull $dist; dcp up -d $dist
dist=opensuse; dcp pull $dist; dcp up -d $dist
dist=busybox;  dcp pull $dist; dcp up -d $dist
dist=openwrt;  dcp pull $dist; dcp up -d $dist
dist=debian;   dcp pull $dist; dcp up -d $dist
dist=fedora;   dcp pull $dist; dcp up -d $dist
```

**Distros**

- musl
  - [nil-busybox](https://www.busybox.net/) `Replace of GNU Coreutils`
  - [**apk-alpine**](https://alpinelinux.org/releases/) `LTS:the last 4 version, Norway`
  - [opkg-openwrt](https://openwrt.org/zh/about/history) `Embedded Device`
- deb
  - [apt-debian](https://wiki.debian.org/LTS) `2Years, LTS 5Years, Global`
  - [**apt-ubuntu**](https://ubuntu.com/about/release-cycle) `2Years, LTS 10Years, Isle of Man`
- rpm
  - [yum-fedora](https://distrowatch.com/table.php?distribution=fedora) `0.5Year, USA`
  - [**zyp-opensuse**](https://en.opensuse.org/Portal:Leap) `3Years, Germany`


**Tags**

Tag | origin |core |app |Star 
---  | ---  | --- | --- | --- 
core-alpine | ![pic](https://img.shields.io/docker/image-size/library/alpine/3.19) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-alpine)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-alpine)|★★★★★
core-ubuntu | ![pic](https://img.shields.io/docker/image-size/library/ubuntu/24.04) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-ubuntu)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-ubuntu)|★★★★★
core-opensuse | ![pic](https://img.shields.io/docker/image-size/opensuse/leap/15.5) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-opensuse)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-opensuse)|★★★★★
---  | ---  | --- | --- | --- 
core-busybox `1.36.1` | ![pic](https://img.shields.io/docker/image-size/library/busybox/1.36.1) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-busybox)|-| ★★★★☆
core-openwrt `23.05` | ![pic](https://img.shields.io/docker/image-size/openwrt/rootfs) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-openwrt)|-| ★★★★★
core-debian `12` | ![pic](https://img.shields.io/docker/image-size/library/debian/12) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-debian)|-| ★★★★★
core-fedora `39` | ![pic](https://img.shields.io/docker/image-size/library/fedora/39) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-fedora)|-| ★★★★☆(-armv7)


**CompileDbg**

```bash
# infrastlabs/x11-base:builder ##alpine-builder-gtk224
# --privileged>> make: /bin/sh: Operation not permitted
REPO=registry.cn-shenzhen.aliyuncs.com/ #ccr.ccs.tencentyun.com/  dockerhub.qingcloud.com/ registry-1.docker.io/
root@VM-12-9-ubuntu:~# docker run -it --rm -v /mnt:/mnt2 --privileged ${REPO}infrastlabs/x11-base:alpine-builder-gtk224 sh
# apk add git gawk
export GITHUB=https://hub.yzuu.cf
cd /mnt2/docker-x11base/compile/src/
# /mnt2/docker-x11base/compile/src # 
rm -rf /src; ln -s $(pwd) /src

# export TARGETPATH=/usr/local/static/misc #/usr/local/static_temp1
git pull; bash x-pulseaudio/build.sh b_deps #libogg
find /usr/lib /usr/local/lib |egrep "ogg|opus|sndfile|FLAC|vorbis" |egrep "\.a$" |sort
git pull; bash x-pulseaudio/build.sh libopus
git pull; bash x-pulseaudio/build.sh libflac
git pull; bash x-pulseaudio/build.sh pulseaudio
# git pull; bash fluxbox/build.sh fluxbox
```
