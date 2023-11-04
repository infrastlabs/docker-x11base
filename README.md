# docker-x11base

**Features**

- package the system by your dotfiles with docker
- box/server side headless deploy
- multi remote entry: noVNC, Xrdp, SSH; Audio supported
- suckless misc, static built binary for any distritions
- multi arch, current suport: amd64, arm64, armv7

[![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/fluxbox)](https://hub.docker.com/r/infrastlabs/docker-x11base/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/infrastlabs/x11-base.svg)](https://hub.docker.com/r/infrastlabs/docker-x11base)
[![Last commit](https://img.shields.io/github/last-commit/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/graphs/contributors)
[![GitHub issues](https://img.shields.io/github/issues/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/issues)


**Run**

```bash
echo "TAG=fluxbox-dbg" > .env
dcp pull; dcp up -d
```
**Tags**

 TAG | Distro | Version | Arch | Initd | Image |Star |Description 
--- | --- | ---  | ---  | --- | --- | --- | ---
alpine-compile |Alpine| 3.15 | amd64,arm64,armv7  | perp/supervisor | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alpine-compile)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★|-
fluxbox  |Ubuntu| 20.94 | amd64,arm64,armv7 | perp/supervisor | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/fluxbox)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★|-
---|---|---|---|---|---|---
alpine   |Alpine| 3.13.12 | amd64,arm64,armv7 | perp/supervisor | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alpine)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★|-
alma   |AlmaLinux| 8.6 | amd64,arm64 | perp/supervisor | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alma)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★☆|-
deb12   |Debian| 12.0 | amd64,arm64,armv7 | perp/supervisor | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/deb12)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★|-

**dbg**

```bash
root@VM-12-9-ubuntu:~# docker run -it --rm -v /mnt:/mnt2  infrastlabs/x11-base:builder sh
/ # 
/ # apk add git gawk
/ # cd /mnt2/docker-x11base/compile/src/
/mnt2/docker-x11base/compile/src # git pull; bash fluxbox/build.sh fluxbox
```

**links**

- https://github.com/mRemoteNG/mRemoteNG/graphs/contributors
- https://gitee.com/infrastlabs/fk-webhookd `+wsvnc,bcs`
- https://gitee.com/g-golang/fk-supervisord `master's build @armv7`
