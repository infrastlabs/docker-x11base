
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
    - theme, keys
    - tint2
    - conky, plank
  - xfwm4, thunar, greybird


**TODO2410**

- Gtk2应用的配置与编译
  - **thunar,pcmanfm; ldd@alpine_38,ubt1804,opsuse150**;
  - **flux/openbox ~~gtk-icon-theme~~,keys**; dotfiles_using;
  - **dotfiles: ~~外挂调试~~/.gitac外挂编译**;
  - tint2, plank.vala
  - a/xrandr, pnmixer/pavolume;
  - portExisted校验:fluxbox.st频繁跳出OOM;
- 控制台应用细化
  - dropbear,sftp,bash,git,ohmybash-font
  - st,**pac,perl**
  - lua,php,py
- 上层特定应用/主桌面
  - firefox,vscode,wps,163music
  - gnome,plasma,mate  

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
3.1  xf-session正常, op-session正常`4.10`/pcmanfm正常 `unable to locate theme enging in module_path:murrine`
3.2  xf-session正常, op-session正常`4.12`/pcmanfm正常
# 
3.5  xf-session也无icon/theme, op-session无icon/pcmanfm-无icon
3.8  xf-session也无icon/theme, op-session无icon/pcmanfm-无icon [装gtk-murrine-engine仍不行; 有对应themes,icons]
3.10 xf-session`两套conf冲突?xfwm4退出`, op-session无icon/pcmanfm-无icon
3.13 xf-session`两套conf冲突?xfwm4退出`, op-session正常`4.16`/pcmanfm-131正常
3.18 xf-session正常, op-session正常`4.18`/pcmanfm-未装

# ubuntu-thunar,pcmanfm
1404  xf-session无icon, op-session无icon/pcmanfm-无icon [无对应的:icons,themes]
1604  xf-session无icon, op-session无icon/pcmanfm-无icon [无对应的:icons,themes]
# 
1804  xf-session正常, op-session正常/pcmanfm正常
2004  xf-session正常, op-session正常/pcmanfm-未装
2204  xf-session正常, op-session正常/pcmanfm-未装 `glibErr: --privileged`
2404  xf-session正常, op-session正常/pcmanfm-未装 `glibErr: --privileged`
```

