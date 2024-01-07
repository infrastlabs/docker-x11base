
- xfwm4
- thunar
- xfdesktop
- xfce4-settings

**xfwm4**

```bash
# https://distrowatch.com/table.php?distribution=alpine
bash (5.2.21)
gcc (13.2.0)
gimp (2.10.36)
glibc (2.38)
gtk (4.12.4) ##
linux (6.6.8)
# 
lxpanel (0.10.1) ##
mate-desktop (1.26.2)
mesa (23.3.1)
nautilus (45.2.1)
openbox (3.6.1) ##
plasma-desktop (5.27.10)
xfdesktop (4.18.1) ##
xorg-server (21.1.10)
#### vers date
3.15.10  2023-08-07
3.13.12  2022-08-09
3.10.6   2021-02-23 ##alpine:3.10
3.6.2  	 2017-06-17 ##alpine:3.6
3.2.2    2015-07-14
2.7.8    2014-05-21
1.10.6   2010-06-16



# 3.6  1.6.11-r0
# 3.8  1.6.12-r0
# 3.9  1.8.4-r0
# 3.10 1.8.6-r0
# root@tenvm2:~# docker run -it --rm  alpine:3.6 sh
ver=v3.9 #3.8 #3.10 #3.6
export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/$ver/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/$ver/community" >> /etc/apk/repositories
/ # apk add thunar
(76/76) Installing thunar (1.6.11-r0)
Executing busybox-1.26.2-r11.trigger
Executing glib-2.52.1-r0.trigger
Executing desktop-file-utils-0.23-r0.trigger
Executing shared-mime-info-1.8-r0.trigger
Executing gdk-pixbuf-2.36.7-r0.trigger
Executing gtk-update-icon-cache-2.24.31-r0.trigger
OK: 56 MiB in 89 packages
/ # ldd /usr/bin/thunar  |wc
       59       234      3635 ##59 @1.6.11-r0


# root@tenvm2:~# docker run -it --rm  alpine:3.8 sh
(64/80) Installing gtk+3.0 (3.22.30-r1)
(65/80) Installing gtk+2.0 (2.24.31-r1)
(68/80) Installing libxfce4util (4.13.1-r0)
(69/80) Installing xfconf (4.12.1-r2)
(79/80) Installing xfce4-panel (4.12.2-r0)
(80/80) Installing thunar (1.6.12-r1)
OK: 59 MiB in 93 packages
/ # ldd /usr/bin/thunar |sort |wc
       59       234      3635 ##59 @1.6.12-r0
/ # ldd /usr/bin/thunar |sort |grep gtk
	libgtk-x11-2.0.so.0 => /usr/lib/libgtk-x11-2.0.so.0 (0x7fdbdc86b000)

# root@tenvm2:~# docker run -it --rm  alpine:3.9 sh
(65/81) Installing gtk+3.0 (3.24.1-r0)
(66/81) Installing gtk+2.0 (2.24.32-r1)
(69/81) Installing libxfce4util (4.13.2-r3)
(70/81) Installing xfconf (4.13.6-r0)
(71/81) Installing libxfce4ui-gtk3 (4.13.4-r2)
(72/81) Installing exo (0.12.4-r0)
(74/81) Installing libgudev (230-r2)
(80/81) Installing xfce4-panel (4.13.4-r0)
(81/81) Installing thunar (1.8.4-r0)
/ # 
/ # ldd /usr/bin/thunar |sort |wc
       68       270      4221
/ # ldd /usr/bin/thunar |sort |grep gtk
	libgtk-3.so.0 => /usr/lib/libgtk-3.so.0 (0x7fa31dbbe000)
/ # ldd /usr/bin/thunar |sort |grep wayland
	libwayland-client.so.0 => /usr/lib/libwayland-client.so.0 (0x7ff713d3b000)
	libwayland-cursor.so.0 => /usr/lib/libwayland-cursor.so.0 (0x7ff713d50000)
	libwayland-egl.so.1 => /usr/lib/libwayland-egl.so.1 (0x7ff713d4b000)

/ # apk add xfwm4
(2/2) Installing xfwm4 (4.13.1-r2)
/ # apk add xfwm4 xfce4-settins
ERROR: unsatisfiable constraints:
  xfce4-settins (missing):
    required by: world[xfce4-settins]
/ # apk add xfwm4 xfce4-settings
(7/7) Installing xfce4-settings (4.13.5-r0)
/ # ldd /usr/bin/xfwm4 |grep gtk
	libgtk-3.so.0 => /usr/lib/libgtk-3.so.0 (0x7f6f658d2000)
/ # ldd /usr/bin/xfce4-settings-manager  |grep gtk
	libgtk-3.so.0 => /usr/lib/libgtk-3.so.0 (0x7f81dd71b000)



# root@tenvm2:~# docker run -it --rm  alpine:3.10 sh
(81/81) Installing thunar (1.8.6-r0)
Executing thunar-1.8.6-r0.post-install
OK: 61 MiB in 95 packages
/ # ldd /usr/bin/thunar |grep gtk
	libgtk-3.so.0 => /usr/lib/libgtk-3.so.0 (0x7ff881db0000)



# tmux19 dyn-build-tint2: [xfwm 4.16]
bash-5.1# apk add xfwm4
(1/16) Installing libxres (1.2.1-r0)
(2/16) Installing libxpresent (1.0.0-r0)
(3/16) Installing libepoxy (1.5.9-r0)
(4/16) Installing at-spi2-core (2.42.0-r0)
(5/16) Installing at-spi2-atk (2.38.0-r0)
(6/16) Installing wayland-libs-cursor (1.19.0-r1)
(7/16) Installing wayland-libs-egl (1.19.0-r1)
(8/16) Installing xkeyboard-config (2.34-r0)
(9/16) Installing libxkbcommon (1.3.1-r0)
(10/16) Installing gtk+3.0 (3.24.30-r0)
Executing gtk+3.0-3.24.30-r0.post-install
(11/16) Installing libwnck3 (3.36.0-r0)
(12/16) Installing libgtop (2.40.0-r0)
(13/16) Installing libxfce4util (4.16.0-r1)
(14/16) Installing xfconf (4.16.0-r0)
(15/16) Installing libxfce4ui (4.16.1-r0)
(16/16) Installing xfwm4 (4.16.1-r0)
Executing busybox-1.34.1-r7.trigger
Executing glib-2.70.5-r0.trigger
Executing gtk-update-icon-cache-2.24.33-r0.trigger
OK: 845 MiB in 324 packages

bash-5.1# apk add xfdesktop
(1/10) Installing exo-libs (4.16.2-r0)
(2/10) Installing garcon (4.16.1-r1)
(3/10) Installing libnotify (0.7.9-r1)
(4/10) Installing desktop-file-utils (0.26-r0)
(5/10) Installing libexif (0.6.23-r0)
(6/10) Installing eudev-libs (3.2.11_pre1-r0)
(7/10) Installing libgudev (237-r0)
(8/10) Installing xfce4-panel (4.16.3-r0)
(9/10) Installing thunar (4.16.10-r0)
Executing thunar-4.16.10-r0.post-install ##已包含;
(10/10) Installing xfdesktop (4.16.0-r0)
Executing busybox-1.34.1-r7.trigger
Executing gtk-update-icon-cache-2.24.33-r0.trigger
Executing desktop-file-utils-0.26-r0.trigger
OK: 851 MiB in 334 packages


# tmux19 dyn-build-tint2:
bash-5.1# ldd /usr/bin/xfwm4 |sort |wc
       70       278      4369
bash-5.1# ldd /usr/bin/thunar |sort |wc
       72       286      4467 ##72 @4.16.10-r0
bash-5.1# ldd /usr/bin/xfdesktop |sort |wc
       74       294      4603


# bash-5.1# apk add xfce4-settings 
(1/3) Installing iso-codes (4.8.0-r0)
(2/3) Installing libxklavier (5.4-r5)
(3/3) Installing xfce4-settings (4.16.2-r0)
Executing busybox-1.34.1-r7.trigger
Executing gtk-update-icon-cache-2.24.33-r0.trigger
Executing desktop-file-utils-0.26-r0.trigger
OK: 857 MiB in 337 packages
# bash-5.1# ldd /usr/bin/xfce4-settings- |sort |wc
xfce4-settings-editor   xfce4-settings-manager  
bash-5.1# ldd /usr/bin/xfce4-settings-manager |sort |wc
       69       274      4287
```


**thunar** `1.6.18(4.12)> 1.8.17(4.13/4.14)> 4.15.0> 4.19.0`

- https://github.com/xfce-mirror/thunar/tree/thunar-1.8.17 #5232 2021.5.12  `gtk3.20`
- https://github.com/xfce-mirror/thunar/tree/thunar-1.8.0  #4308 2018.6.7   `gtk3.20`
- https://github.com/xfce-mirror/thunar/tree/thunar-1.7.0  #3983 2017.11.26 `gtk3.20`
- https://github.com/xfce-mirror/thunar/tree/thunar-1.6.18 #4029 2019.11.10 `gtk2.24` **thunar-1.6.18**
- https://github.com/xfce-mirror/thunar/tree/thunar-1.6.12 #3710 2017.7.1   `gtk2.24`
- https://github.com/xfce-mirror/thunar/tree/thunar-1.6.0  #2876 2012.12.3  `gtk2.14`
- 
- https://www.xfce.org/download/changelogs
- https://www.xfce.org/about/screenshots


```bash
# https://github.com/GNOME/gtk/tree/3.20.0
# ===gtk2 vs gtk3: 仅风格不一样?
master 78453@23.12.21
4.13.3 78191
3.20.0   46985 @2016.3.21
2.24.33  21855 @2020.12.21

# relear tar
% tar xf thunar-<version>.tar.bz2
% cd thunar-<version>
% ./configure  --enable-static
% make
% make install


# from src
% cd thunar
% ./autogen.sh
% make
% make install



# 
 839 git clone --depth=1 --branch thunar-4.16.11 https://ghproxy.com/https://github.com/xfce-mirror/thunar thunar-4.16.11
 840 ls
 841 cd thunar-4.16.11/
 842 ls
 843 ./configure 
 844 cat autogen.sh 
 845 bash autogen.sh 
 846 apk add xfce4-dev-tools
 847 bash autogen.sh 
 848 apk add intltool
 849 bash autogen.sh 
 850 apk add gtk-doc
 851 bash autogen.sh 
 852 echo $?
 853 apk add exo-2
 854 apk add exo2
 855 apk add exo
 856 bash autogen.sh


# ERR01: exo-2
# /mnt2/thunar-4.16.11 # bash autogen.sh 
checking pkg-config is at least version 0.9.0... yes
checking for exo-2 >= 4.15.3... not found
*** The required package exo-2 was not found on your system.
*** Please install exo-2 (atleast version 4.15.3) or adjust
*** the PKG_CONFIG_PATH environment variable if you
*** installed the package in a nonstandard prefix so that
*** pkg-config is able to find it.


# https://github.com/clefebvre/thunar
# Thunar depends on the following packages:
 - perl 5.6 or above
 - GTK+ 2.24.0 or above
 - GLib 2.30.0 or above
 - exo 0.10.0 or above
 - intltool 0.30 or above

# https://github.com/xfce-mirror/thunar/tree/thunar-1.6.18
# Thunar depends on the following packages:
 - perl 5.6 or above
 - GTK+ 2.24.0 or above
 - GLib 2.30.0 or above
 - exo 0.10.0 or above
 - intltool 0.30 or above
# Thunar can optionally use the following packages:
 - D-Bus 0.34 or above (strongly suggested)
 - libstartup-notification 0.4 or above
 - xfce4-panel 4.10.0 or above (for the trash applet)
 - xfconf-query
```

- ldd deps `23.199 ubt-headless: thunar 1.8.14[wayland,gtk3]`

```bash
# headless @ mac23-199 in ~ |20:34:54  
$ thunar -V
thunar: Failed to initialize Xfconf: Cannot autolaunch D-Bus without X11 $DISPLAY
thunar 1.8.14 (Xfce 4.14)
Copyright (c) 2004-2019
	The Thunar development team. All rights reserved.

# headless @ mac23-199 in ~ |20:33:55  
$ ldd /usr/bin/thunar |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007f0dd36a0000)
	libICE.so.6 => /lib/x86_64-linux-gnu/libICE.so.6 (0x00007f0dd3529000)
	libSM.so.6 => /lib/x86_64-linux-gnu/libSM.so.6 (0x00007f0dd3547000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007f0dd16d1000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007f0dd21fd000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007f0dd15e6000)
	libXcomposite.so.1 => /lib/x86_64-linux-gnu/libXcomposite.so.1 (0x00007f0dd1de6000)
	libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007f0dd1deb000)
	libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007f0dd1de1000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007f0dd15de000)
	libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007f0dd1d67000)
	libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007f0dd21c4000)
	libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007f0dd21ce000)
	libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007f0dd1e07000)
	libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007f0dd1dfa000)
	libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007f0dd1a33000)
    # 
	libatk-1.0.so.0 => /lib/x86_64-linux-gnu/libatk-1.0.so.0 (0x00007f0dd2c2e000)
	libatk-bridge-2.0.so.0 => /lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 (0x00007f0dd2181000)
	libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007f0dd157d000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007f0dd233a000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f0dd2504000)
	libcairo-gobject.so.2 => /lib/x86_64-linux-gnu/libcairo-gobject.so.2 (0x00007f0dd21b8000)
	libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007f0dd2b0b000)
	libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007f0dd15d4000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f0dd1a04000)
	libepoxy.so.0 => /lib/x86_64-linux-gnu/libepoxy.so.0 (0x00007f0dd204e000)
	libexo-2.so.0 => /lib/x86_64-linux-gnu/libexo-2.so.0 (0x00007f0dd356a000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f0dd15ec000)
	libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007f0dd1951000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007f0dd1ecb000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007f0dd1e0c000)
	libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007f0dd2031000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007f0dd12d4000)
	libgdk-3.so.0 => /lib/x86_64-linux-gnu/libgdk-3.so.0 (0x00007f0dd2c58000)
	libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007f0dd2ae3000)
	libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007f0dd2881000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007f0dd26f8000)
	libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007f0dd24fe000)
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007f0dd2821000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007f0dd12af000)
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007f0dd161c000)
	libgtk-3.so.0 => /lib/x86_64-linux-gnu/libgtk-3.so.0 (0x00007f0dd2d5d000)
	libgudev-1.0.so.0 => /lib/x86_64-linux-gnu/libgudev-1.0.so.0 (0x00007f0dd355d000)
	libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007f0dd1f12000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007f0dd13f2000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f0dd1413000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f0dd23af000)
	libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007f0dd19a4000)
	libatspi.so.0 => /lib/x86_64-linux-gnu/libatspi.so.0 (0x00007f0dd1649000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007f0dd1680000)
    # 
	libnotify.so.4 => /lib/x86_64-linux-gnu/libnotify.so.4 (0x00007f0dd3552000)
	libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007f0dd2a62000)
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007f0dd21e0000)
	libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007f0dd2018000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f0dd18de000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f0dd14eb000)
	libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007f0dd1cb5000)
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007f0dd1c7d000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f0dd238c000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f0dd195d000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f0dd1d5c000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f0dd1979000)
	libstartup-notification-1.so.0 => /lib/x86_64-linux-gnu/libstartup-notification-1.so.0 (0x00007f0dd21f2000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007f0dd143c000)
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007f0dd1a0c000)
	libudev.so.1 => /lib/x86_64-linux-gnu/libudev.so.1 (0x00007f0dd235f000)
	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f0dd2354000)
	# 
	libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007f0dd1c3d000)
	libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007f0dd1c78000)
	libxcb-util.so.1 => /lib/x86_64-linux-gnu/libxcb-util.so.1 (0x00007f0dd16d6000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007f0dd1c4c000)
	libxkbcommon.so.0 => /lib/x86_64-linux-gnu/libxkbcommon.so.0 (0x00007f0dd1d9f000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f0dd1a17000)
	linux-vdso.so.1 (0x00007fff8b5ab000) ##
	libthunarx-3.so.0 => /lib/x86_64-linux-gnu/libthunarx-3.so.0 (0x00007f0dd35a7000)
	libxfconf-0.so.3 => /lib/x86_64-linux-gnu/libxfconf-0.so.3 (0x00007f0dd2ab1000)
	libxfce4ui-2.so.0 => /lib/x86_64-linux-gnu/libxfce4ui-2.so.0 (0x00007f0dd350e000)
	libxfce4util.so.7 => /lib/x86_64-linux-gnu/libxfce4util.so.7 (0x00007f0dd2acf000)
    # 
    libwayland-client.so.0 => /lib/x86_64-linux-gnu/libwayland-client.so.0 (0x00007f0dd1d7e000)
	libwayland-cursor.so.0 => /lib/x86_64-linux-gnu/libwayland-cursor.so.0 (0x00007f0dd1d94000)
	libwayland-egl.so.1 => /lib/x86_64-linux-gnu/libwayland-egl.so.1 (0x00007f0dd1d8f000)
```
