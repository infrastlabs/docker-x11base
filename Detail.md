
alpine-compile

![](https://img.shields.io/docker/image-size/infrastlabs/x11-base/alpine-compile)

**Tags**

Tag | origin |core |app |Star 
---  | ---  | --- | --- | --- 
core-alpine-3.8 | ![pic](https://img.shields.io/docker/image-size/library/alpine/3.8) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-alpine-3.8)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-alpine-3.8)|★★★★★
core-alpine-3.19 | ![pic](https://img.shields.io/docker/image-size/library/alpine/3.19) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-alpine-3.19)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-alpine-3.19)|★★★★★
core-ubuntu-18.04 | ![pic](https://img.shields.io/docker/image-size/library/ubuntu/18.04) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-ubuntu-18.04)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-ubuntu-18.04)|★★★★★
core-ubuntu-20.04 | ![pic](https://img.shields.io/docker/image-size/library/ubuntu/20.04) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-ubuntu-20.04)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-ubuntu-20.04)|★★★★★
core-ubuntu-22.04 | ![pic](https://img.shields.io/docker/image-size/library/ubuntu/22.04) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-ubuntu-22.04)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-ubuntu-22.04)|★★★★☆
core-ubuntu-24.04 | ![pic](https://img.shields.io/docker/image-size/library/ubuntu/24.04) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-ubuntu-24.04)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-ubuntu-24.04)|★★★★☆
core-opensuse-15.0 | ![pic](https://img.shields.io/docker/image-size/opensuse/leap/15.0) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-opensuse-15.0)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-opensuse-15.0)|★★★★★
core-opensuse-15.5 | ![pic](https://img.shields.io/docker/image-size/opensuse/leap/15.5) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-opensuse-15.5)| ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/app-opensuse-15.5)|★★★★★
---  | ---  | --- | --- | --- 
core-busybox `1.36.1` | ![pic](https://img.shields.io/docker/image-size/library/busybox/1.36.1) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-busybox)|-| ★★★★☆
core-openwrt `23.05` | ![pic](https://img.shields.io/docker/image-size/openwrt/rootfs) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-openwrt)|-| ★★★★★
core-debian `12` | ![pic](https://img.shields.io/docker/image-size/library/debian/12) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-debian)|-| ★★★★★
core-fedora `39` | ![pic](https://img.shields.io/docker/image-size/library/fedora/39) | ![pic](https://img.shields.io/docker/image-size/infrastlabs/x11-base/core-fedora)|-| ★★★★☆(-armv7)

## 1) Alpine

- https://distrowatch.com/table.php?distribution=alpine `4.12.4@alpine_3.8`
- https://distrowatch.com/table.php?distribution=xubuntu `4.12.3@xbt_18.04`
- https://distrowatch.com/table.php?distribution=opensuse `4.12.4@opsuse_15.0`

`Compile> bins> conf`

```bash
# docker run -it --rm -v /mnt:/mnt2 infrastlabs/x11-base:builder sh
# @tenvm2-x64: 构建feels还快
# @gitac-multi-x3: long-cost


# WM
# https://github.com/siduck/chadwm #Jul 18, 2021+

```


## 2) Refs

- https://github.com/shimmerproject/Greybird
- https://github.com/adi1090x/rofi `style collection`
- https://github.com/axyl-os/axyl-iso `i3wm(c@2009), bspwm(c@2012), dwm(c@2008), xmonad(haskel@2007), qtile(py@2008) @Arch`
- chadwm/pdwm
  - https://github.com/siduck/chadwm/graphs/contributors `Jul 18, 2021` `FT-Labs/pdwm`
  - https://github.com/siduck/dotfiles `bspwm, fluxbox, openbox`
  - https://github.com/FT-Labs/phyOS-iso `pdwm @Arch`

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

# tiger:
# xorg-server https://github.com/XQuartz/xorg-server #https://gitlab.freedesktop.org/xorg/xserver
```

## 3) Items

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
```

**X11/Core**

```bash
3rd:  tini/gosu/upx/
util: xcompmgr, perp
core: x11, pulseaudio
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

**links**

- https://musl.libc.org/
- https://github.com/jlesage/docker-baseimage-gui `clang static build <TigerVNC, Openbox, noVNC>; Jan 8, 2017+ @Alpine 3.15`
- [**conn**]
- remote: `frp/chisel-poll`, `bind_uds:dropbear,xrdp,webhookd`
- ~~webhookd/noVNC~~ https://gitee.com/infrastlabs/fk-webhookd `+wsvnc,bcs`
- ~~mstsc/remoteNG~~ https://github.com/mRemoteNG/mRemoteNG/graphs/contributors `2010年1月3日`
- ~~go-supervisor~~ https://github.com/ochinchina/supervisord/graphs/contributors `v073@May 3, 2021;` `armv7 err binary.`
  - https://gitee.com/g-golang/fk-supervisord `master's build @armv7`
- [**cmisc**]
- ~~n2n~~ https://github.com/lucktu/cnn2n/graphs/contributors `2016年10月23日+`
- ~~tinc~~ https://github.com/gsliepen/tinc/graphs/contributors `2000年3月26日+`
- ~~lrzsz~~ https://github.com/UweOhse/lrzsz/graphs/contributors `2020年3月1日+; jnavila/lrzsz:2013年2月17日+`
- ~~su-exec~~ https://github.com/ncopa/su-exec/graphs/contributors `2015年12月6日+`
- [**x11**]
- ~~dropbear~~ https://github.com/mkj/dropbear/graphs/contributors `1,914 commits; May 30, 2004+`
- ~~xrdp~~ https://github.com/neutrinolabs/xrdp/graphs/contributors `4,522 commits; Oct 2, 2010+ ff:Jul 4, 2004+`
- ~~tigervnc/xorg-server~~  https://github.com/TigerVNC/tigervnc/graphs/contributors `4,793 commits; Jan 29, 2009+ ff:May 19, 2002+`
- ~~pulseaudio~~ https://github.com/pulseaudio/pulseaudio/graphs/contributors `Jun 6, 2004+`
- pavucontrol https://github.com/pulseaudio/pavucontrol/graphs/contributors `Apr 16, 2006`
- [**wm**]
- ~~openbox~~ https://github.com/codic12/openbox/graphs/contributors `7605commits, Apr 7, 2002+`
- ~~fluxbox~~ https://github.com/fluxbox/fluxbox/graphs/contributors `6207commits@23.11, Feb 8, 2007+; pre v0.9.11: Dec 9, 2001+` `base Blackbox 0.61.1`
- ~~suckless~~ https://suckless.org/ `st, dwm+dmenu+bar`
  - ~~st~~ https://github.com/siduck/st/graphs/contributors `0.8.4@alpine_315`
- [**Att**]
- ~~upx~~ https://github.com/upx/upx/graphs/contributors `May 14, 2000+` 下载二进制
- ~~perp~~ http://b0llix.net/perp/ https://github.com/infrastlabs/fk-perp/graphs/contributors `2010年1月10日+; perp-2.04> perp-2.07.tar.gz@2013.01.11`
- tmux https://github.com/tmux/tmux/graphs/contributors `2007年7月8日+`
- ~~fontconfig~~ https://github.com/behdad/fontconfig/graphs/contributors `Feb 10, 2002 – Nov 13, 2018`; just `fontconfig-dev(with static); +hand:/usr/share/fonts/xx`
- ~~xcompmgr~~, picom, compton https://github.com/invisikey/xcompmgr `Nov 9, 2003 – May 16, 2015` `github:rnz/xcompmgr`
  - git://anongit.freedesktop.org/git/xorg/app/xcompmgr
  - https://github.com/yshui/picom/graphs/contributors `Nov 9, 2003 – Nov 6, 2023`
  - https://github.com/chjj/compton/graphs/contributors `Nov 9, 2003 – Jun 5, 2017`
- [**lxde**]
- ~~lxtask~~ https://github.com/lxde/lxtask/graphs/contributors `Apr 20, 2008`
- ~~lxappearance~~ https://github.com/lxde/lxappearance/graphs/contributors `Mar 23, 2008+`
- ~~pcmanfm~~ https://github.com/lxde/pcmanfm/graphs/contributors `Dec 20, 2009`
- gpicview/ristretto https://github.com/lxde/gpicview/graphs/contributors `Sep 9, 2007`
  - ristretto https://github.com/xfce-mirror/ristretto/graphs/contributors `Nov 5, 2006+`
- [**xfce4**] `xfce4.12/thunar1.6.18 => gtk2.24.0`
- xfwm4 https://github.com/xfce-mirror/xfwm4/graphs/contributors `Apr 28, 2002`
- thunar https://github.com/xfce-mirror/thunar/graphs/contributors `9721commits, Feb 13, 2005+` `thunar-4.16.11/thunar-1.8.14@ubt2004`
- xfdesktop https://github.com/xfce-mirror/xfdesktop/graphs/contributors `Jan 12, 2003`
- xfce4-settings https://github.com/xfce-mirror/xfce4-settings/graphs/contributors `Jun 15, 2008`
- [**Misc**]
- sakura https://github.com/dabisu/sakura/graphs/contributors `Dec 30, 2007+` `SAKURA_2_3_7:vte` `GNOME/gtk` `GNOME/vte` `PCRE2Project/pcre2`
- ~~tint2~~ https://github.com/o9000/tint2/graphs/contributors `Sep 28, 2008` `Mar 18, 2015 – Mar 13, 2019` `imlib2`
- plank https://github.com/ricotz/plank/graphs/contributors `2011年1月16日+` `vala`
- jgmenu https://github.com/jgmenu/jgmenu/graphs/contributors `Jan 25, 2015+` `heavy-too[sakura]`
- ~rofi~ https://github.com/davatorium/rofi/graphs/contributors `Jun 24, 2012+` `xcb-ewmh/icccm/cursor`
- ~~xlunch~~ https://github.com/Tomas-M/xlunch/graphs/contributors `Dec 4, 2016`
- gimp https://github.com/GNOME/gimp/graphs/contributors `50969commits, Jan 18, 1998+`
- geany https://github.com/geany/geany/graphs/contributors `Nov 20, 2005+`
  - mousepad https://github.com/xfce-mirror/mousepad/graphs/contributors `2005年3月6日+; 3.6k; c`
  - leafpad https://github.com/stevenhoneyman/l3afpad/graphs/contributors `2011年12月11日+; x78; c`
- Gnome https://github.com/orgs/GNOME/repositories?type=all&q=lib
  - task-mgr https://github.com/GNOME/gnome-system-monitor/graphs/contributors `2001年6月24日+; cpp`
  - dconf https://github.com/GNOME/dconf/graphs/contributors `2009年3月15日+; 1.3k; c`
  - spi2 https://github.com/GNOME/at-spi2-core/graphs/contributors `2001年4月22日; c`
  - glib https://github.com/GNOME/glib/graphs/contributors `1998年6月7日+; 3.09w; c`
  - gtk https://github.com/GNOME/gtk/graphs/contributors `1998年3月15日+; 8.2w; c`
  - vte https://github.com/GNOME/vte/graphs/contributors `2002年2月24日+; cpp`
  - vala https://github.com/GNOME/vala/graphs/contributors `2006年4月16日; vala`
  - libwnck https://github.com/GNOME/libwnck/graphs/contributors `2001年9月30日+; 2.2k; c`
  - librsvg https://github.com/GNOME/librsvg/graphs/contributors `2001年3月25日+; 9.7k; rust`
  - libxml2 https://github.com/GNOME/libxml2/graphs/contributors `1998年7月19日+; 7.0k; c`
  - gdk-pixbuf https://github.com/GNOME/gdk-pixbuf/graphs/contributors `1997年11月23日+; 6.2k; c`
  - pango https://github.com/GNOME/pango/graphs/contributors `1996年12月29日+; 6.4k; c`
