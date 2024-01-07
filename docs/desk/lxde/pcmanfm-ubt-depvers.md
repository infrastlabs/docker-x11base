
- 手动构建拷贝到ubt2004
  - xlunch正常
  - xcompmgr正常
  - pcmanfm: 不能打开子框; 右键执行??>> err to menu-cached:退出

```bash
# try换ubt版: 如pixbuf>> 2.40.0 #2.42.8 [2.40.0@ubt2004; 2.42.8@alpine315]
root@tenvm2:/# dpkg -l |egrep "libatk|libgtk|libgdk|pixbuf|libfm|menu-cache"
ii  libatk-bridge2.0-0:amd64       2.34.2-0ubuntu2~20.04.1           amd64        AT-SPI 2 toolkit bridge - shared library
ii  libatk1.0-0:amd64              2.35.1-1ubuntu2                   amd64        ATK accessibility toolkit
ii  libatk1.0-data                 2.35.1-1ubuntu2                   all          Common files for the ATK accessibility toolkit
ii  libatkmm-1.6-1v5:amd64         2.28.0-2build1                    amd64        C++ wrappers for ATK accessibility toolkit (shared libraries)
ii  libfm-data                     1.3.1-1                           all          file management support (common data)
ii  libfm-extra4:amd64             1.3.1-1                           amd64        file management support (extra library)
ii  libfm-gtk-data                 1.3.1-1                           all          file management support (GTK+ library common data)
ii  libfm-gtk4:amd64               1.3.1-1                           amd64        file management support (GTK+ 2.0 GUI library)
ii  libfm4:amd64                   1.3.1-1                           amd64        file management support (core library)
ii  libgdk-pixbuf2.0-0:amd64       2.40.0+dfsg-3ubuntu0.4            amd64        GDK Pixbuf library
ii  libgdk-pixbuf2.0-common        2.40.0+dfsg-3ubuntu0.4            all          GDK Pixbuf library - data files
ii  libgtk-3-0:amd64               3.24.20-0ubuntu1.1                amd64        GTK graphical user interface library
ii  libgtk-3-common                3.24.20-0ubuntu1.1                all          common files for the GTK graphical user interface library
ii  libgtk2.0-0:amd64              2.24.32-4ubuntu4                  amd64        GTK graphical user interface library - old version
ii  libgtk2.0-common               2.24.32-4ubuntu4                  all          common files for the GTK graphical user interface library
ii  libgtkmm-3.0-1v5:amd64         3.24.2-1build1                    amd64        C++ wrappers for GTK+ (shared libraries)
ii  libmenu-cache-bin              1.1.0-1                           amd64        LXDE implementation of the freedesktop Menu\'s cache (libexec)
ii  libmenu-cache3:amd64           1.1.0-1                           amd64        LXDE implementation of the freedesktop Menu\'s cache


root@tenvm2:/# ldd /usr/bin/pcmanfm |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007f9defe01000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007f9defc7c000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007f9dee460000)
	libXcomposite.so.1 => /lib/x86_64-linux-gnu/libXcomposite.so.1 (0x00007f9dee91b000)
	libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007f9dee920000)
	libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007f9dee914000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007f9dee458000)
	libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007f9dee8ff000)
	libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007f9deebbd000)
	libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007f9dee93a000)
	libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007f9dee94c000)
	libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007f9dee92d000)
	libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007f9dee951000)
	libatk-1.0.so.0 => /lib/x86_64-linux-gnu/libatk-1.0.so.0 (0x00007f9def6bf000)
	libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007f9dee340000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007f9dee293000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f9deef55000)
	libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007f9def59a000)
	libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007f9dee415000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007f9dee397000)
	libdbus-glib-1.so.2 => /lib/x86_64-linux-gnu/libdbus-glib-1.so.2 (0x00007f9dee5d6000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f9deef25000)
	libexif.so.12 => /lib/x86_64-linux-gnu/libexif.so.12 (0x00007f9dee58e000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007f9dee42a000)
	libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007f9dee4d9000)
	libfm-gtk.so.4 => /lib/x86_64-linux-gnu/libfm-gtk.so.4 (0x00007f9defc10000)
	libfm.so.4 => /lib/x86_64-linux-gnu/libfm.so.4 (0x00007f9def4d7000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007f9deeb5d000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007f9dee799000)
	libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007f9dee712000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007f9dee070000)
	libgdk-x11-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0 (0x00007f9def6fb000)
	libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007f9def572000)
	libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007f9def2f6000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007f9def16a000)
	libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007f9deebc5000)
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007f9def296000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007f9dee04d000)
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007f9dee3e8000)
	libgtk-x11-2.0.so.0 => /lib/x86_64-linux-gnu/libgtk-x11-2.0.so.0 (0x00007f9def7b6000)
	libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007f9dee603000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007f9dee18e000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007f9dee1b1000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f9deebcb000)
	libmenu-cache.so.3 => /lib/x86_64-linux-gnu/libmenu-cache.so.3 (0x00007f9deed1c000)
	libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007f9dee52e000)
	libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007f9def523000)
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007f9def6e9000)
	libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007f9deeba4000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f9dee466000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007f9dee2ad000)
	libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007f9dee858000)
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007f9dee761000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f9def147000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007f9dee4e7000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007f9dee1da000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f9dee503000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007f9dee1e4000)
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007f9dee707000)
	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007f9dee41f000)
	libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007f9dee74b000)
	libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007f9dee75a000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007f9deef2b000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f9dee72f000)
	linux-vdso.so.1 (0x00007ffc96b8e000)



```


- automake old_ver


```bash

# You must have automake 1.7.x, 1,10.x, 1.11.x, 1.12.x, 1.13.x, 1.14.x
# or 1.15.x installed to compile Gtk+.
# Install the appropriate package for your distribution,
# or get the source tarball at http://ftp.gnu.org/gnu/automake/
# bash-5.1# apk list |grep automake  ##版本过高?
# automake-1.16.4-r1 x86_64 {automake} (GPL-2.0-or-later MIT Public-Domain) [installed]

# 
bash-5.1# apk add automake-1.16.4-r1
ERROR: unable to select packages:
  automake-1.16.4-r1 (no such package):
    required by: world[automake-1.16.4-r1]
bash-5.1# apk add automake=1.16.4-r1
OK: 802 MiB in 255 packages
bash-5.1# apk add automake=1.15.4-r1
ERROR: unable to select packages:
  automake-1.16.4-r1:
    breaks: world[automake=1.15.4-r1]

# bash-5.1# apk del automake
(1/1) Purging automake (1.16.4-r1)
Executing busybox-1.34.1-r7.trigger
OK: 801 MiB in 254 packages
bash-5.1# apk add automake=1.15.4-r1
ERROR: unable to select packages:
  automake-1.16.4-r1:
    breaks: world[automake=1.15.4-r1]


# src automake @shell
# automake-1.1.15安装 qq_38772519 于 2022-12-18 14:25:11 发布
原文链接：https://blog.csdn.net/qq_38772519/article/details/128362076
```