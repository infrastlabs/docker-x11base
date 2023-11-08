
- 23.11.7号晚flux-xft-ok, 8号查看:fluxbox镜像明细(opbox非静态编)

**bin**

```bash
# headless@VM-12-9-ubuntu:~$ ll /bin/ |grep static
lrwxrwxrwx 1 root root        35 Nov  7 15:29 Xvnc -> /usr/local/static/tigervnc/bin/Xvnc*
lrwxrwxrwx 1 root root        39 Nov  7 15:29 dbclient -> /usr/local/static/dropbear/bin/dbclient*
lrwxrwxrwx 1 root root        36 Nov  7 15:29 dmenu -> /usr/local/static/suckless/bin/dmenu*
lrwxrwxrwx 1 root root        41 Nov  7 15:29 dmenu_path -> /usr/local/static/suckless/bin/dmenu_path*
lrwxrwxrwx 1 root root        40 Nov  7 15:29 dmenu_run -> /usr/local/static/suckless/bin/dmenu_run*
lrwxrwxrwx 1 root root        46 Nov  7 15:29 dropbearconvert -> /usr/local/static/dropbear/bin/dropbearconvert*
lrwxrwxrwx 1 root root        42 Nov  7 15:29 dropbearkey -> /usr/local/static/dropbear/bin/dropbearkey*
lrwxrwxrwx 1 root root        34 Nov  7 15:29 dwm -> /usr/local/static/suckless/bin/dwm*
lrwxrwxrwx 1 root root        35 Nov  7 15:29 fbrun -> /usr/local/static/fluxbox/bin/fbrun*
lrwxrwxrwx 1 root root        37 Nov  7 15:29 fbsetbg -> /usr/local/static/fluxbox/bin/fbsetbg*
lrwxrwxrwx 1 root root        39 Nov  7 15:29 fbsetroot -> /usr/local/static/fluxbox/bin/fbsetroot*
lrwxrwxrwx 1 root root        37 Nov  7 15:29 fluxbox -> /usr/local/static/fluxbox/bin/fluxbox*
lrwxrwxrwx 1 root root        51 Nov  7 15:29 fluxbox-generate_menu -> /usr/local/static/fluxbox/bin/fluxbox-generate_menu*
lrwxrwxrwx 1 root root        44 Nov  7 15:29 fluxbox-remote -> /usr/local/static/fluxbox/bin/fluxbox-remote*
lrwxrwxrwx 1 root root        52 Nov  7 15:29 fluxbox-update_configs -> /usr/local/static/fluxbox/bin/fluxbox-update_configs*
lrwxrwxrwx 1 root root        41 Nov  7 15:29 gdm-control -> /usr/local/static/openbox/bin/gdm-control*
lrwxrwxrwx 1 root root        49 Nov  7 15:29 gnome-panel-control -> /usr/local/static/openbox/bin/gnome-panel-control*
lrwxrwxrwx 1 root root        37 Nov  7 15:29 obxprop -> /usr/local/static/openbox/bin/obxprop*
lrwxrwxrwx 1 root root        37 Nov  7 15:29 openbox -> /usr/local/static/openbox/bin/openbox*
lrwxrwxrwx 1 root root        51 Nov  7 15:29 openbox-gnome-session -> /usr/local/static/openbox/bin/openbox-gnome-session*
lrwxrwxrwx 1 root root        49 Nov  7 15:29 openbox-kde-session -> /usr/local/static/openbox/bin/openbox-kde-session*
lrwxrwxrwx 1 root root        45 Nov  7 15:29 openbox-session -> /usr/local/static/openbox/bin/openbox-session*
lrwxrwxrwx 1 root root        33 Nov  7 15:29 st -> /usr/local/static/suckless/bin/st*
lrwxrwxrwx 1 root root        42 Nov  7 15:29 startfluxbox -> /usr/local/static/fluxbox/bin/startfluxbox*
lrwxrwxrwx 1 root root        36 Nov  7 15:29 stest -> /usr/local/static/suckless/bin/stest*
lrwxrwxrwx 1 root root        40 Nov  7 15:29 vncpasswd -> /usr/local/static/tigervnc/bin/vncpasswd*
lrwxrwxrwx 1 root root        38 Nov  7 15:29 xkbcomp -> /usr/local/static/tigervnc/bin/xkbcomp*
# headless@VM-12-9-ubuntu:~$ ll /sbin/ |grep static
lrwxrwxrwx 1 root root        40 Nov  7 15:29 dropbear -> /usr/local/static/dropbear/sbin/dropbear*
```

**tree**

```bash
# headless@VM-12-9-ubuntu:/usr/local/static$ du -sh *
1.1M	dropbear
46M 	fluxbox
2.0M	openbox
12M 	suckless
6.2M	tigervnc
12M 	xrdp
# headless@VM-12-9-ubuntu:/usr/local/static$ tree -L 3 -h
.
|-- [4.0K]  dropbear
|   |-- [4.0K]  bin
|   |   |-- [331K]  dbclient
|   |   |-- [190K]  dropbearconvert
|   |   `-- [182K]  dropbearkey
|   |-- [4.0K]  sbin
|   |   `-- [367K]  dropbear
|   `-- [4.0K]  share
|-- [4.0K]  fluxbox
|   |-- [4.0K]  bin
|   |   |-- [ 10M]  fbrun
|   |   |-- [ 17K]  fbsetbg
|   |   |-- [ 10M]  fbsetroot
|   |   |-- [ 12M]  fluxbox
|   |   |-- [ 66K]  fluxbox-generate_menu
|   |   |-- [3.0M]  fluxbox-remote
|   |   |-- [8.3M]  fluxbox-update_configs
|   |   `-- [1.3K]  startfluxbox
|   `-- [4.0K]  share
|       `-- [4.0K]  fluxbox
|-- [4.0K]  openbox
|   |-- [4.0K]  bin
|   |   |-- [ 19K]  gdm-control
|   |   |-- [ 18K]  gnome-panel-control
|   |   |-- [ 19K]  obxprop
|   |   |-- [915K]  openbox
|   |   |-- [2.0K]  openbox-gnome-session
|   |   |-- [ 497]  openbox-kde-session
|   |   `-- [ 648]  openbox-session
|   |-- [4.0K]  etc
|   |   `-- [4.0K]  xdg
|   |-- [4.0K]  include
|   |   `-- [4.0K]  openbox
|   |-- [4.0K]  lib
|   |   |-- [130K]  libobrender.a
|   |   |-- [1.2K]  libobrender.la
|   |   |-- [105K]  libobt.a
|   |   |-- [1.1K]  libobt.la
|   |   `-- [4.0K]  pkgconfig
|   |-- [4.0K]  libexec
|   |   |-- [ 976]  openbox-autostart
|   |   `-- [6.4K]  openbox-xdg-autostart
|   `-- [4.0K]  share
|       |-- [4.0K]  applications
|       |-- [4.0K]  doc
|       |-- [4.0K]  gnome
|       |-- [4.0K]  gnome-session
|       |-- [4.0K]  pixmaps
|       |-- [4.0K]  themes
|       `-- [4.0K]  xsessions
|-- [4.0K]  suckless
|   |-- [4.0K]  bin
|   |   |-- [3.5M]  dmenu
|   |   |-- [ 240]  dmenu_path
|   |   |-- [  58]  dmenu_run
|   |   |-- [3.6M]  dwm
|   |   |-- [3.7M]  st
|   |   `-- [267K]  stest
|   `-- [4.0K]  man1
|       |-- [3.1K]  dmenu.1
|       |-- [4.9K]  dwm.1
|       |-- [3.5K]  st.1
|       `-- [1.5K]  stest.1
|-- [4.0K]  tigervnc
|   |-- [4.0K]  bin
|   |   |-- [4.1M]  Xvnc
|   |   |-- [154K]  vncpasswd
|   |   `-- [1.2M]  xkbcomp
|   |-- [4.0K]  lib
|   |   |-- [4.0K]  pkgconfig
|   |   `-- [4.0K]  xorg
|   `-- [4.0K]  share
|       `-- [4.0K]  X11
`-- [4.0K]  xrdp
    |-- [4.0K]  bin
    |   |-- [122K]  xrdp-dis
    |   |-- [997K]  xrdp-genkeymap
    |   |-- [2.4M]  xrdp-keygen
    |   |-- [134K]  xrdp-sesadmin
    |   `-- [134K]  xrdp-sesrun
    |-- [4.0K]  etc
    |   |-- [4.0K]  default
    |   |-- [4.0K]  init.d
    |   `-- [4.0K]  xrdp
    |-- [4.0K]  include
    |   |-- [1.3K]  ms-erref.h
    |   |-- [1.9K]  ms-fscc.h
    |   |-- [ 22K]  ms-rdpbcgr.h
    |   |-- [1018]  ms-rdpedisp.h
    |   |-- [4.5K]  ms-rdpefs.h
    |   |-- [2.1K]  ms-rdpegdi.h
    |   |-- [1.4K]  ms-rdpele.h
    |   |-- [1.0K]  ms-rdperp.h
    |   |-- [2.8K]  ms-smb2.h
    |   |-- [3.9K]  painter.h
    |   |-- [1.2K]  rfxcodec_common.h
    |   |-- [1.0K]  rfxcodec_decode.h
    |   |-- [4.1K]  rfxcodec_encode.h
    |   |-- [5.1K]  xrdp_client_info.h
    |   |-- [8.9K]  xrdp_constants.h
    |   |-- [4.6K]  xrdp_rail.h
    |   `-- [1.6K]  xrdp_sockets.h
    |-- [4.0K]  sbin
    |   |-- [1.6M]  xrdp
    |   |-- [2.4M]  xrdp-chansrv
    |   `-- [2.5M]  xrdp-sesman
    |-- [4.0K]  share
    |   `-- [4.0K]  xrdp
    `-- [4.0K]  var
        `-- [4.0K]  run

47 directories, 63 files
```
