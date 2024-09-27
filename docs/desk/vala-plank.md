

- ubt2004

```bash
# https://gitee.com/g-system/fk-plank #latestTag: 0.11.89; autogen.sh/configure.ac/Makefile.am;
# https://github.com/ricotz/plank/graphs/contributors
# https://github.com/GNOME/vala/graphs/contributors

headless@host-21-60:~$
headless@host-21-60:~$ pkgsize |grep plank
0.38 Mbs        libplank-common
0.77 Mbs        libplank1
0.46 Mbs        plank
headless@host-21-60:~$ dpkg -l |grep plank
ii  libplank-common                  0.11.89-1                         all          Library to build an elegant, simple, clean dock (shared files)
ii  libplank1:amd64                  0.11.89-1                         amd64        Library to build an elegant, simple, clean dock
ii  plank                            0.11.89-1                         amd64        Elegant, simple, clean dock


# headless@host-21-60:~$ ls -lh /usr/bin/plank
-rwxr-xr-x 1 root root 15K Aug 20  2019 /usr/bin/plank
headless@host-21-60:~$ ldd /usr/bin/plank |sort |wc
     78     308    6100
headless@host-21-60:~$ ldd /usr/bin/plank |sort
        /lib64/ld-linux-x86-64.so.2 (0x00007fe36407f000)
        libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007fe361f7b000)
        libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007fe3634ff000)
        libXRes.so.1 => /lib/x86_64-linux-gnu/libXRes.so.1 (0x00007fe362719000)
        libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007fe361f75000)
        libXcomposite.so.1 => /lib/x86_64-linux-gnu/libXcomposite.so.1 (0x00007fe3622fc000)
        libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007fe362301000)
        libXdamage.so.1 => /lib/x86_64-linux-gnu/libXdamage.so.1 (0x00007fe3622f7000)
        libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007fe361f6d000)
        libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007fe3626da000)
        libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007fe3634e5000)
        libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007fe3634ed000)
        libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007fe36231b000)
        libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007fe36230e000)
        libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007fe362756000)
        libatk-1.0.so.0 => /lib/x86_64-linux-gnu/libatk-1.0.so.0 (0x00007fe36272c000)
        libatk-bridge-2.0.so.0 => /lib/x86_64-linux-gnu/libatk-bridge-2.0.so.0 (0x00007fe362697000)
        libatspi.so.0 => /lib/x86_64-linux-gnu/libatspi.so.0 (0x00007fe361ee5000)
        libbamf3.so.2 => /lib/x86_64-linux-gnu/libbamf3.so.2 (0x00007fe363683000)
        libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007fe3629f1000)
        libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007fe361e5b000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe363a50000)
        libcairo-gobject.so.2 => /lib/x86_64-linux-gnu/libcairo-gobject.so.2 (0x00007fe3626ce000)
        libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007fe362a72000)
        libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007fe361e75000)
        libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007fe361f1c000)
        libdbusmenu-glib.so.4 => /lib/x86_64-linux-gnu/libdbusmenu-glib.so.4 (0x00007fe3634ae000)
        libdbusmenu-gtk3.so.4 => /lib/x86_64-linux-gnu/libdbusmenu-gtk3.so.4 (0x00007fe3634ce000)
        libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fe363a26000)
        libepoxy.so.0 => /lib/x86_64-linux-gnu/libepoxy.so.0 (0x00007fe362562000)
        libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007fe361e88000)
        libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007fe36394e000)
        libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007fe3623e1000)
        libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007fe362322000)
        libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007fe362545000)
        libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007fe361c42000)
        libgdk-3.so.0 => /lib/x86_64-linux-gnu/libgdk-3.so.0 (0x00007fe362bf6000)
        libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007fe362a4a000)
        libgee-0.8.so.2 => /lib/x86_64-linux-gnu/libgee-0.8.so.2 (0x00007fe3636bb000)
        libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007fe363e8e000)
        libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007fe363d04000)
        libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007fe363a4a000)
        libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007fe363e2e000)
        libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007fe361c1f000)
        libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007fe361eb6000)
        libgtk-3.so.0 => /lib/x86_64-linux-gnu/libgtk-3.so.0 (0x00007fe362cfd000)
        libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007fe362428000)
        liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007fe361d60000)
        liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fe361d81000)
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fe36378c000)
        libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007fe3639c6000)
        libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007fe362b95000)
        libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007fe362be4000)
        libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007fe36252c000)
        libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007fe3638db000)
        libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fe362960000)
        libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007fe3621d4000)
        libplank.so.1 => /lib/x86_64-linux-gnu/libplank.so.1 (0x00007fe363c42000)
        libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007fe36219c000)
        libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fe36395c000)
        libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fe36397f000)
        librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fe362288000)
        libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007fe36399b000)
        libstartup-notification-1.so.0 => /lib/x86_64-linux-gnu/libstartup-notification-1.so.0 (0x00007fe362721000)
        libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007fe361daa000)
        libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007fe36227d000)
        libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007fe361e7f000)
        libwayland-client.so.0 => /lib/x86_64-linux-gnu/libwayland-client.so.0 (0x00007fe362292000)
        libwayland-cursor.so.0 => /lib/x86_64-linux-gnu/libwayland-cursor.so.0 (0x00007fe3622a8000)
        libwayland-egl.so.1 => /lib/x86_64-linux-gnu/libwayland-egl.so.1 (0x00007fe3622a3000)
        libwnck-3.so.0 => /lib/x86_64-linux-gnu/libwnck-3.so.0 (0x00007fe36363e000)
        libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007fe362188000)
        libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007fe362197000)
        libxcb-util.so.1 => /lib/x86_64-linux-gnu/libxcb-util.so.1 (0x00007fe361f82000)
        libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007fe3626ef000)
        libxkbcommon.so.0 => /lib/x86_64-linux-gnu/libxkbcommon.so.0 (0x00007fe3622b3000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fe363a2c000)
        linux-vdso.so.1 (0x00007ffe1ddf9000)
headless@host-21-60:~$


# vala-static:
https://github.com/kamanashisroy/aroop #bin/aroopc-0.1.0 --static-link hello_world.vala
https://github.com/mesonbuild/meson/issues/1715 #meson: executable.link_args: ['-static']

```
