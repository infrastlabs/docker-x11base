
- distros
  - ~~openwrt: hk1box-err~~ Done.@24.10.8
- compile
  - perp, perl, 
  - core `tigervnc, xrdp, pulse; dropbear`
  - wm `fluxbox, openbox, suckless, xcompmgr`
  - desk
    - feh, xlunch, tint2
    - geany, jgmenu, sakura
    - pcmanfm, lxtask, gpicview
    - thunar, xfwm4, xfdesktop
- rootfs-dotfiles
  - fluxbox `slax:theme,xlunch,archiver,pcmanfm`
  - openbox
    - ~~theme, keys~~
    - tint2
    - conky, plank
  - xfwm4, thunar, greybird


**TODO2410**

- Gtk2应用的配置与编译
  - **thunar,pcmanfm; ldd@alpine_38,ubt1804,opsuse150**;
  - **flux/openbox ~~gtk-icon-theme~~,keys**; dotfiles_using;
  - **dotfiles: ~~外挂调试~~/.gitac外挂编译**;
  - tint2, plank.vala
  - ~~a/xrandr, pnmixer/pasystray~~;
  - portExisted校验:fluxbox.st频繁跳出OOM;
- 控制台应用细化
  - dropbear,sftp,bash,git,ohmybash-font
  - st,**pac,perl**
  - lua,php,py
- 上层特定应用/主桌面
  - firefox,vscode,wps,163music
  - gnome,plasma,mate  

**24.11.4**

- gtk2
  - gtk:~~docs.staticUsage~~ @gitlab.issue
  - builder.alpine31
  - lxtask: icon.theme; pcmanfm
  - mousepad/geany,xfwm4,xfdesktop; thunar
- first.opbox
  - tint2
  - vala.plank
  - pasystray,pavucontrol
  - ibus,rime
- apps
  - console.perl.pac
  - apps.vscode.wps.163music

```bash
# Imlib2
feh, xlunch, tint2

# tint2
static: x64:ok; arm64@hk1box:runErr;
dyn: arm64@hk1box:runOK;

# xfce
xfwm4, thunar @gtk2;



# gtk-icon-theme-name="Papirus-Bunsen-bluegrey" ##fix: Paper> Papirus;
# alpine-thunar,pcmanfm
  3.1@2014-12-10 op-session[4.10-1.6.3]正常/pcmanfm-123正常, xf-session正常 `unable to locate theme enging in module_path:murrine`; gtk2: .gtk-bookmarks
  3.2@2015-05-26 op-session[4.12-1.6.10]正常/pcmanfm-123正常, xf-session正常
  # 
  3.3@2015-12-18 op-session[4.12-1.6.10]无icon/pcmanfm-123无icon; 
  3.4@2016-05-31 op-session[4.12-1.6.10]无icon/pcmanfm-124无icon; 
  3.5@2016-12-22 op-session[4.12-1.6.10]无icon/pcmanfm-125无icon, xf-session也无icon/theme
  3.6@2017-05-24 op-session[4.12-1.6.11]无icon/pcmanfm-125无icon; `v3.6: +armv8,v7`
  3.8@2018-06-26 op-session[4.12-1.6.12]无icon/pcmanfm-125无icon, xf-session也无icon/theme `装gtk-murrine-engine仍不行; 有对应themes,icons`
  3.10@2019-06-19 op-session[4.12-1.8.6]无icon/pcmanfm-131无icon, xf-session: `两套conf冲突?xfwm4退出`
  # 
  3.11@2019-12-29 op-session[4.14-1.8.11]正常/pcmanfm-131正常
  3.12@2020-05-29 op-session[4.14-1.8.15]正常/pcmanfm-131正常
  3.13@2021-01-14 op-session[4.16-4.16.2]正常/pcmanfm-131正常, xf-session[4.16]`两套conf冲突?xfwm4退出`
  3.19@2023-12-07 op-session[4.18]正常/pcmanfm-未装, xf-session正常

# ubuntu-thunar,pcmanfm
  1404 op-session[4.11-1.6.3]正常/pcmanfm-未装, xf-session正常 `无对应的:icons,themes`
  1604 op-session[4.12-1.6.11]正常/pcmanfm-未装, xf-session正常 `无对应的:icons,themes`
  1804 op-session[4.12-1.6.15]正常/pcmanfm-未装, xf-session正常
  # 
  2004 op-session[4.14-1.8.14]正常/pcmanfm-未装, xf-session正常
  2204 op-session[4.16-4.16.10]正常/pcmanfm-未装, xf-session正常 `glibErr: --privileged`
  2404 op-session[4.18-4.18.8]正常/pcmanfm-未装, xf-session正常 `glibErr: --privileged`

# opensuse-thunar,pcmanfm
  150 op-session[4.12-1.6.14]正常/pcmanfm-未装

# LXDE+distrowatch
  # LXLE: pcmanfm可直接按类型打开app; mimes
  # wattOS: 打开app:跳出选择; 同LXLE款volume(点击mouse中键调音量 但点击后不遮挡desk)
  # lubuntu: apps:直接打开; xx.sh:跳窗(执行|open编辑); volume:横向/app未知
  # rescuzilla: apps:直接打开; xx.sh:直接执行; volume:volume icon;

```

