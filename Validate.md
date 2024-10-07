
- distros
  - openwrt: hk1box-err
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


```bash
# Imlib2
feh, xlunch, tint2

# tint2
static: x64:ok; arm64@hk1box:runErr;
dyn: arm64@hk1box:runOK;

# xfce
xfwm4, thunar @gtk2;
```

