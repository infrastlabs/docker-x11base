
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
  - pulseaudio/pavucontrol/alsasound
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

**links**

- ~~upx~~ https://github.com/upx/upx/graphs/contributors #`May 14, 2000+` #下载二进制
- ~~xlunch~~ https://github.com/Tomas-M/xlunch/graphs/contributors #`Dec 4, 2016`
- ~~xcompmgr~~ https://github.com/invisikey/xcompmgr #`Nov 9, 2003 – May 16, 2015`
- pulseaudio https://github.com/pulseaudio/pulseaudio/graphs/contributors #`Jun 6, 2004+`
- pavucontrol https://github.com/pulseaudio/pavucontrol/graphs/contributors #`Apr 16, 2006`
- [**lxde**]
- gpicview/ristretto https://github.com/lxde/gpicview/graphs/contributors #`Sep 9, 2007`
- ~~lxtask~~ https://github.com/lxde/lxtask/graphs/contributors #`Apr 20, 2008`
- ~~lxappearance~~ https://github.com/lxde/lxappearance/graphs/contributors #`Mar 23, 2008`
- ~~pcmanfm~~ https://github.com/lxde/pcmanfm/graphs/contributors #`Dec 20, 2009`
- [**xfce4**] `xfce4.12/thunar1.6.18 => gtk2.24.0`
- xfwm4 https://github.com/xfce-mirror/xfwm4/graphs/contributors #`Apr 28, 2002`
- thunar https://github.com/xfce-mirror/thunar/graphs/contributors #`Feb 13, 2005`
- xfdesktop https://github.com/xfce-mirror/xfdesktop/graphs/contributors #`Jan 12, 2003`
- xfce4-settings https://github.com/xfce-mirror/xfce4-settings/graphs/contributors #`Jun 15, 2008`
- [**misc22**]
- jgmenu https://github.com/jgmenu/jgmenu/graphs/contributors #`Jan 25, 2015`
- ~~tint2~~ https://github.com/o9000/tint2/graphs/contributors #`Sep 28, 2008` `imlib2`
- ~rofi~ https://github.com/davatorium/rofi/graphs/contributors #`Jun 24, 2012` `xcb-ewmh/icccm/cursor`
- geany https://github.com/geany/geany #`Nov 20, 2005+`
- sakura https://github.com/dabisu/sakura/graphs/contributors #`vDec 30, 2007` `SAKURA_2_3_7:vte`
- chadwm/pdwm https://github.com/siduck/chadwm/graphs/contributors #`Jul 18, 2021` `FT-Labs/pdwm`

```bash
# 轻量级桌面 openbox + tint2 + conky + stalonetray + pcmanfm + xcompmgr #http://t.zoukankan.com/huapox-p-3516155.html #huapox
# docky> plank; 依赖大；容器下使用体验不好，延迟/卡顿(改用plank/xcompmgr)

# misc02-2:
#  geany,lxtask,lxappearance, ristretto/lx:gpicview, lxrandr
#  sv:~~perp,daemontools,runit,s6~~; logrotate/crond

# layer:
#  x: Xvnc, xrdp, noVnc; pulseaudio
#  box: fluxbox, openbox
#  suckless: tiling dwm, st;


# TODO 23.12
# 00: perl/asbru-cm
# 01: pulseaudio-plugs-static, pavucontrol
# 02: tint2/openbox
# 03: lxappearance,gpicview,lxtask, jgmenu
# 
- lxappearance `dyn:ok`
- gpicview `dyn:ok`
- lxtask `dyn:ok`
- jgmenu `dyn:ok`
- tint2 `imlib2`

# REMOTE-CONN
#  frpc/frps || chisel-poll
#  bind_uds: dropbear, xrdp, webhookd
# 
```

**vers**

```bash
# pulseaudio
stable-`1.x 2.x 3.x; 7.x 11.x 12.x 14.x 16.x`
master  10245 @23.11.25
16.99.1 10234
15.99.1 10030
14.99.2 9430
13.99.3 9452 @2020-10-30 `ogg opus sndfile` `FLAC vorbis vorbisenc`
11.0    8607 @2017-09-05; static-11.x 8615commits
# pavucontrol
master  659commits
v5.0    595 @21.8.16
v4.0    479 @19.3.5
v3.0    418 @15.3.24
v2.0    400 @13.3.8
v0.99.2 380 @11.7.15

# gnome/gtk  branch="--branch=2.24.33" @tint2-v16.1.md
# https://github.com/GNOME/gtk/tree/3.20.0
master 78453@23.12.21
4.13.3 78191
# ===gtk2 vs gtk3: 仅风格不一样?
3.99.5.1 67700 @2020.12.8
3.24.39  53229 @latest.up 23.12.21
3.20.0   46985 @2016.3.21
2.99.3   26115 @2011.2.2
2.32.2   20680 @2010.11.10
2.24.33  21855 @2020.12.21
2.24.32  21775 @2018.1.9

# geany
- master 10203commits @23.12.09 
- 1.38.0 9683 @2021.10.9
- 1.37
- 1.34.0 9206 @2018.12.16 `gtk2`
- 1.30
- 1.27.0 8429 @2016.3.13 
- 1.24.0 7041 @2014.4.14 
- 1.23
- 0.20.0 5239 @2011.1.6 

# sakura
master 940
SAKURA_3_5_0 758 @2017.7.14
SAKURA_3_2_1 630 @2015.7.24
SAKURA_3_0_2 476 @2012.3.7
SAKURA_2_3_7 315 @2010.3.4

```

## Alpine

`Compile> bins> conf`

- X11
  - ~~tigervnc/xorg-server~~  https://github.com/TigerVNC/tigervnc #`4,793 commits; Jan 29, 2009+ ff:May 19, 2002+`
  - ~~xrdp~~ https://github.com/neutrinolabs/xrdp #`4,522 commits; Oct 2, 2010+ ff:Jul 4, 2004+`
  - ~~dropbear~~ https://github.com/mkj/dropbear #`1,914 commits; May 30, 2004+`
- WM
  - ~~openbox~~ https://github.com/codic12/openbox/graphs/contributors #`7605commits, Apr 7, 2002+`
  - ~~fluxbox~~ https://github.com/fluxbox/fluxbox/graphs/contributors #`6207commits@23.11, Feb 8, 2007+; pre v0.9.11: Dec 9, 2001+` `base Blackbox 0.61.1` `single bin other-than-suckless: dwm+dmenu+bar`
  - ~~suckless~~ https://suckless.org/ #`st, dwm, dmenu`
- Att
  - ~~fontconfig~~ https://github.com/behdad/fontconfig/graphs/contributors #`Feb 10, 2002 – Nov 13, 2018`; just `fontconfig-dev(with static); +hand:/usr/share/fonts/xx`
  - ~~xcompmgr~~ https://github.com/invisikey/xcompmgr #github`rnz/xcompmgr`; xcompmgr, picom, compton
    - git://anongit.freedesktop.org/git/xorg/app/xcompmgr
    - https://github.com/yshui/picom/graphs/contributors #`Nov 9, 2003 – Nov 6, 2023`
    - https://github.com/chjj/compton/graphs/contributors #`Nov 9, 2003 – Jun 5, 2017`
  - jgmenu https://github.com/jgmenu/jgmenu #`heavy-too[sakura], Jan 25, 2015+`
  - ~~tint2~~ https://github.com/o9000/tint2 #`Mar 18, 2015 – Mar 13, 2019`
  - ~rofi~ https://github.com/davatorium/rofi/graphs/contributors #`Jun 24, 2012+`
- Misc
  - ~~st~~ https://github.com/siduck/st #`0.8.4`@alpine_315
  - sakura https://github.com/dabisu/sakura #`GNOME/gtk` `GNOME/vte` `PCRE2Project/pcre2`
  - geany https://github.com/geany/geany #`Nov 20, 2005+`
  - gimp https://github.com/GNOME/gimp #`50969commits, Jan 18, 1998+`
  - thunar https://github.com/xfce-mirror/thunar #`thunar-4.16.11/thunar-1.8.14@ubt2004; 9721commits, Feb 13, 2005+`
  - ristretto https://github.com/xfce-mirror/ristretto #`Nov 5, 2006+`
  - ~~lxappearance~~ https://github.com/lxde/lxappearance #`Mar 23, 2008+`
- Entry
  - remote: `frps/frpc, chisel-poll`, `uds<dropbear, xrdp, webhookd>`
  - ~~go-supervisor~~ https://github.com/ochinchina/supervisord #`v073@May 3, 2021;` `armv7 err binary.`
  - ~~webhookd/noVNC~~ https://gitee.com/infrastlabs/fk-webhookd #`+/static; +/bcs`

```bash
# docker run -it --rm -v /mnt:/mnt2 infrastlabs/x11-base:builder sh
# @tenvm2-x64: 构建feels还快
# @gitac-multi-x3: long-cost


# WM
# https://github.com/siduck/chadwm #Jul 18, 2021+

```


## Refs

- https://musl.libc.org/
- https://github.com/jlesage/docker-baseimage-gui #`clang static build <TigerVNC, Openbox, noVNC>; Jan 8, 2017+ @Alpine 3.15`
- 
- https://github.com/siduck/dotfiles #`bspwm, fluxbox, openbox`
- https://github.com/adi1090x/rofi #`style collection`
- https://github.com/FT-Labs/phyOS-iso #`pdwm @Arch`
- https://github.com/axyl-os/axyl-iso #`i3wm(c@2009), bspwm(c@2012), dwm(c@2008), xmonad(haskel@2007), qtile(py@2008) @Arch`

```bash
# env: alpine315> ubt2004(armv7_gcc_err)> deb12
- tigervnc
  - tiger-static `-DENABLE_GNUTLS=OFF`@deb12/ubt2004
  - xkb
  - xkbcomp
- de
  - openbox
  - dwm
  - fluxbox TODO
- _ex 
  - fontconfig
  - xdpyprobe
  - yad
  - nginx/novnc

# deb12-static: 
#  -DENABLE_GNUTLS=OFF
#  sed:deps/Makefile不变;
#  fix:abuild-mesion . build; > meson . build;


# tiger:
# xorg-server https://github.com/XQuartz/xorg-server #https://gitlab.freedesktop.org/xorg/xserver
# deb12_glibc环境/clang编译, +pam/static.patch `-DENABLE_GNUTLS=OFF`
```
