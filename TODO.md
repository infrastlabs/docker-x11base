
BusyBox 是 GNU Coreutils 的绝佳替代品; 最初是由 Bruce Perens 在 1996 年为Debian GNU/Linux安装盘编写, 目标是在一张软盘上创建一个可引导的 GNU/Linux 系统

- apt.deb / apk.apk / yum.rpm
- glibc/musl `uclibc/dietlibc`
- gcc/clang `xx-clang/xx-clang++`
- 
- GNU Coreutils `go/rust impl`
- X11: https://www.freedesktop.org/wiki/Software/
- 

```bash
# alpine-musl: apk xx-static v1.10.6@2010-06-16
# static: wallet/void独立运行开源程序ref
# buildroot_musl: sabotage@2011

#TAG
# compile: alpine:3.15
# fluxbox: busybox:1.36.1
# alpine:
# ubuntu:
# debian:
# alma/fedora/opensuse:
# archlinux:

# musl-malloc
https://www.zhihu.com/question/550951106/answer/3199732385 #mimalloc,rpmalloc
https://www.forrestthewoods.com/blog/benchmarking-malloc-with-doom3/
https://github.com/12101111/musl-malloc #malloc换成了rpmalloc
https://github.com/GrapheneOS/hardened_malloc
https://github.com/mjansson/rpmalloc/graphs/contributors
https://github.com/microsoft/mimalloc/graphs/contributors
https://blog.51cto.com/u_16099164/6693747 #go.tidb; glibc提供的ptmalloc2,谷歌提供的tcmalloc,脸书提供的jemalloc

```

## TODO

- validate
  - ssh/sftp `openssh-sftp-server `
- static
  - ~~upx~~
  - ~~xlunch~~
  - ~~xcompmgr~~
  - ~~pulseaudio~~@24.6.20 /pavucontrol/alsasound
- distro
  - ~~alpine~~
  - ~~almalinux~~/fedora/opensuse
  - archlinux
- suckless
  - ~~st-patch~~ `Xresource/scroll`
  - ~~dwm~~ chadwm/pdwm
  - ~~xlunch~~/rofi/dmenu
- linux-static-apps `/usr/local/static/xx`
  - x11base `xserver/tigervnc, xrdp, pulseaudio`
  - wm `openbox, fluxbox`
  - tiling `dwm, st, bspwm, rofi`
  - util `upx, tint, gosu, perp, xcompmgr`
  - misc `lxde<pcmanfm,gpicview,lxtask,lxappearance,>, xfce<thunar,xfwm4,xfdesktop>, xlunch, jgmenu, geany, sakura`

```bash
- pulseaudio
  - ~~arm64,armv7: 1.13.99-err~~ Done.24.6.17;
  - ~~armv7 `// MARK03: ERR WITH armv7 @onecloud-gulin-home >>  [xrdp-sink] clock_gettime`~~ @24.6.20 [--enable-neon-opt=no]; ref docs/core/pulse09-arm-retry2.md
  - pnmixer不识别> 改用pavolume
- uds_conn
  - dropbear
  - xrdp
  - webhookd
- build.sh
  - ~~img-syncer to ali~~ @24.8.20
```

**24.6.19**

- compile
  - core: tigervnc, xrdp, pulse, dropbear; fluxbox/openbox/tint2/dwm; perp
  - misc: lxde, xlunch, xcompmgr, pcmanfm/thunar/geany/gpicview
  - tool: n2n, tinc, tun2socks
- rootfs
  - ~~flux>rootfs~~ @24.8.20
- distros <musl,ubt,opsuse, oth>
  - core: opbox+tint2, +dotfiles
  - app: staticApps, othApps.firefox
  - oth: busybox/opwrt, debian12, fedora39
- headless<ubt>
  - core?
  - custom: ibux,fcitx-sogou
  - desktop: gnome, plasma, mint<cinna,mate,xfce>

```bash
# TODO
1. de: fluxbox/openbox 配置<hotkeys,menu,autostart>; 三方theme
2. ~~内置xfce桌面 @app~~ @24.6.20 
3. 
```
