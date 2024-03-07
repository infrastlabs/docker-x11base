# docker-x11base

**Features**

- package the system by your dotfiles with docker
- box/server side headless deploy
- multi remote entry: noVNC, Xrdp, SSH; Audio supported
- suckless misc, static built binary for any distribution
- multi arch, current suport: amd64, arm64, armv7

[![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/fluxbox)](https://hub.docker.com/r/infrastlabs/docker-x11base/tags)
[![Docker Pulls](https://img.shields.io/docker/pulls/infrastlabs/x11-base.svg)](https://hub.docker.com/r/infrastlabs/docker-x11base)
[![Last commit](https://img.shields.io/github/last-commit/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/graphs/contributors)
[![GitHub issues](https://img.shields.io/github/issues/infrastlabs/docker-x11base.svg)](https://www.github.com/infrastlabs/docker-x11base/issues)

**Run**

```bash
# cmd: [novnc:10081, ssh:10022, xrdp:10089]; -e INIT=perpd
docker run -it --rm --net=host -e VNC_OFFSET=21 infrastlabs/x11-base:fluxbox #fluxbox-dbg

# dcp
echo "TAG=fluxbox-dbg" > .env
dcp pull; dcp up -d
```

**Tags**

 TAG | Distro | Version | Arch | Initd | Image |Star 
--- | --- | ---  | ---  | --- | --- | --- 
alpine   |Alpine| 3.13.12 | amd64,arm64,armv7 | perp/sv | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alpine)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★
fluxbox  |Ubuntu| 20.04 | amd64,arm64,armv7 | perp/sv | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/fluxbox)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★
deb12   |Debian| 12.0 | amd64,arm64,armv7 | perp/sv | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/deb12)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★
alma   |AlmaLinux| 8.6 | amd64,arm64 | perp/sv | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alma)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★☆
---|---|---|---|---|---|---
alpine-compile |Alpine| 3.15 | amd64,arm64,armv7  | perp/sv | [![Docker Image Size](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alpine-compile)](https://hub.docker.com/r/infrastlabs/x11-base/tags)|★★★★★

**X11/Core**

```bash
3rd:  tini/gosu/upx/
util: xcompmgr, perp
core: x11, pulseaudio
entry: frp/chisel-poll
bind-uds: dropbear, xorg, webhookd
```

**Distro**

```bash
deb: debian12, ubt2004 #free
rpm: alma/fedora/opensuse #comm
busybox, alpine, archlinux #musl,wiki
desktop: mate, gnome, plasma #DE, Server/Experience
```

**Box/Misc**

```bash
box:  fluxbox/openbox, suckless/chadwm/bspwm, .dots
apps: vscode, wps, firefox/chrome, asbru (pavucontrol, xf-display-settings)
misc: st, xlunch, tint2, jgmenu, rofi, geany (sakura, plank, engrammpa)
lxde: pcmanfm, lxtask, lxappearance, gpicview (dbus, err)
xfce: thunar, xfwm4, xfdesktop, xfce4-settings, ristretto, mousepad (4.12-gtk224)
# server/device
device-static: arm64/armv7 busybox/alpine315/glibc (core, box/suckless, scripts/dev) "[shell/perl/lua/py/php]"
server-shared: amd64 debian12/ubt2004 (core, xfce4) "[vscode, wps]"
```

**CompileDbg**

```bash
# infrastlabs/x11-base:builder ##alpine-builder-gtk224
# --privileged>> make: /bin/sh: Operation not permitted
root@VM-12-9-ubuntu:~# docker run -it --rm -v /mnt:/mnt2 --privileged infrastlabs/x11-base:alpine-builder-gtk224 sh
# apk add git gawk
export GITHUB=https://hub.yzuu.cf
cd /mnt2/docker-x11base/compile/src/
# /mnt2/docker-x11base/compile/src # 
rm -rf /src; ln -s $(pwd) /src
git pull; bash x-pulseaudio/build.sh libogg #b_deps
git pull; bash fluxbox/build.sh fluxbox
```

**links**

- https://github.com/mRemoteNG/mRemoteNG/graphs/contributors
- https://gitee.com/infrastlabs/fk-webhookd `+wsvnc,bcs`
- https://gitee.com/g-golang/fk-supervisord `master's build @armv7`
