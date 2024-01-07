

## openbox

- pango
- libxrandr
- fontconfig #split@Dockerfile

```bash
 107 cd ../fk-docker-baseimage-gui/src/openbox/
 108 ls
 109 bash build.sh 
 110 ls -lh

#  115 ls
 116 cd /tmp/openbox
 117 ls
 118 cd -
 119 cd /tmp/openbox-install/
 120 ls
 121 find
 123 ./usr/bin/openbox --help
 126 xx-verify --static      /tmp/openbox-install/usr/bin/openbox #OK
 127 echo $? #0
```

```bash
# ubt2004@fluxbox-dbg
root@tenvm2:/# ldd /usr/bin/openbox |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fe9f1152000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007fe9f06d4000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007fe9f0e45000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007fe9ef994000)
	libXcursor.so.1 => /lib/x86_64-linux-gnu/libXcursor.so.1 (0x00007fe9f0e21000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007fe9ef98c000)
	libXext.so.6 => /lib/x86_64-linux-gnu/libXext.so.6 (0x00007fe9f0e2e000)
	libXfixes.so.3 => /lib/x86_64-linux-gnu/libXfixes.so.3 (0x00007fe9f08df000)
	libXft.so.2 => /lib/x86_64-linux-gnu/libXft.so.2 (0x00007fe9f065e000)
	libXi.so.6 => /lib/x86_64-linux-gnu/libXi.so.6 (0x00007fe9f0e04000)
	libXinerama.so.1 => /lib/x86_64-linux-gnu/libXinerama.so.1 (0x00007fe9f10e2000)
	libXrender.so.1 => /lib/x86_64-linux-gnu/libXrender.so.1 (0x00007fe9f09d2000)
	libblkid.so.1 => /lib/x86_64-linux-gnu/libblkid.so.1 (0x00007fe9ed26e000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007fe9f0919000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe9f0bdc000)
	libICE.so.6 => /lib/x86_64-linux-gnu/libICE.so.6 (0x00007fe9f0f82000) ##
	libImlib2.so.1 => /lib/x86_64-linux-gnu/libImlib2.so.1 (0x00007fe9f05f6000)
	libSM.so.6 => /lib/x86_64-linux-gnu/libSM.so.6 (0x00007fe9f0fa0000)
	libXrandr.so.2 => /lib/x86_64-linux-gnu/libXrandr.so.2 (0x00007fe9f10d5000)
	libcairo-gobject.so.2 => /lib/x86_64-linux-gnu/libcairo-gobject.so.2 (0x00007fe9ef5dd000) ##
	libcairo.so.2 => /lib/x86_64-linux-gnu/libcairo.so.2 (0x00007fe9efb56000)
	libdatrie.so.1 => /lib/x86_64-linux-gnu/libdatrie.so.1 (0x00007fe9ef046000)
	libfontconfig.so.1 => /lib/x86_64-linux-gnu/libfontconfig.so.1 (0x00007fe9ef7db000)
	libfribidi.so.0 => /lib/x86_64-linux-gnu/libfribidi.so.0 (0x00007fe9ef7be000)
    # 
	libgdk_pixbuf-2.0.so.0 => /lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 (0x00007fe9ef5b5000)
	libgmodule-2.0.so.0 => /lib/x86_64-linux-gnu/libgmodule-2.0.so.0 (0x00007fe9ef013000)
	libgobject-2.0.so.0 => /lib/x86_64-linux-gnu/libgobject-2.0.so.0 (0x00007fe9efc79000)
	libgraphite2.so.3 => /lib/x86_64-linux-gnu/libgraphite2.so.3 (0x00007fe9ef019000)
	libharfbuzz.so.0 => /lib/x86_64-linux-gnu/libharfbuzz.so.0 (0x00007fe9ef6af000)
	libicudata.so.66 => /lib/x86_64-linux-gnu/libicudata.so.66 (0x00007fe9ed4a9000)
	libicuuc.so.66 => /lib/x86_64-linux-gnu/libicuuc.so.66 (0x00007fe9ef0a9000)
	libobrender.so.32 => /lib/x86_64-linux-gnu/libobrender.so.32 (0x00007fe9f0de8000)
	libobt.so.2 => /lib/x86_64-linux-gnu/libobt.so.2 (0x00007fe9f0dd0000)
	libpango-1.0.so.0 => /lib/x86_64-linux-gnu/libpango-1.0.so.0 (0x00007fe9f0677000)
	libpangocairo-1.0.so.0 => /lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 (0x00007fe9ef3c2000)
	libpangoft2-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 (0x00007fe9ef973000)
	libpangoxft-1.0.so.0 => /lib/x86_64-linux-gnu/libpangoxft-1.0.so.0 (0x00007fe9f06c8000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007fe9f095f000)
	libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fe9ed1dd000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007fe9eef86000)
	# libstartup-notification-1.so.0 => /lib/x86_64-linux-gnu/libstartup-notification-1.so.0 (0x00007fe9f0e16000)
	# 
    libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fe9f08e7000)
	libexpat.so.1 => /lib/x86_64-linux-gnu/libexpat.so.1 (0x00007fe9ef050000)
	libffi.so.7 => /lib/x86_64-linux-gnu/libffi.so.7 (0x00007fe9ef399000)
	libfreetype.so.6 => /lib/x86_64-linux-gnu/libfreetype.so.6 (0x00007fe9ef5f0000)
	libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fe9ef3a7000)
	libgio-2.0.so.0 => /lib/x86_64-linux-gnu/libgio-2.0.so.0 (0x00007fe9ef3d4000)
	libglib-2.0.so.0 => /lib/x86_64-linux-gnu/libglib-2.0.so.0 (0x00007fe9f0fab000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fe9ef07e000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fe9ef824000)
	libmount.so.1 => /lib/x86_64-linux-gnu/libmount.so.1 (0x00007fe9eefb1000)
	libpixman-1.so.0 => /lib/x86_64-linux-gnu/libpixman-1.so.0 (0x00007fe9ef2f2000)
	libpng16.so.16 => /lib/x86_64-linux-gnu/libpng16.so.16 (0x00007fe9ef2ba000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fe9f093c000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fe9eef6a000)
	librsvg-2.so.2 => /lib/x86_64-linux-gnu/librsvg-2.so.2 (0x00007fe9efcd9000)
	libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fe9ed2c7000)
	libthai.so.0 => /lib/x86_64-linux-gnu/libthai.so.0 (0x00007fe9ef7b3000)
	libuuid.so.1 => /lib/x86_64-linux-gnu/libuuid.so.1 (0x00007fe9f0933000)
	libxcb-render.so.0 => /lib/x86_64-linux-gnu/libxcb-render.so.0 (0x00007fe9ef2ab000)
	libxcb-shm.so.0 => /lib/x86_64-linux-gnu/libxcb-shm.so.0 (0x00007fe9ef5e9000)
	libxcb-util.so.1 => /lib/x86_64-linux-gnu/libxcb-util.so.1 (0x00007fe9f06d9000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007fe9f08ed000)
	libxml2.so.2 => /lib/x86_64-linux-gnu/libxml2.so.2 (0x00007fe9ef99a000)
	libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fe9ef28f000)
	linux-vdso.so.1 (0x00007ffdb37c7000)


# apk add 
    glib-static \
    fribidi-dev \
    fribidi-static \
    harfbuzz-dev \
    harfbuzz-static \
    cairo-dev \
    cairo-static \
    libxft-dev \
    libxml2-dev \
    libx11-dev \
    libx11-static \
    libxcb-static \
    libxdmcp-dev \
    libxau-dev \
    freetype-static \
    expat-static \
    libpng-dev \
    libpng-static \
    zlib-static \
    bzip2-static \
    pcre-dev \
    libxrender-dev \
    graphite2-static \
    libffi-dev \
    xz-dev \
    brotli-static


        OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
        # OB_LIBS="$OB_LIBS -luuid"
        LDFLAGS="$LDFLAGS -Wl,--start-group $OB_LIBS -Wl,--end-group" LIBS="$LDFLAGS" ./configure \
        --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
        --host=$(xx-clang --print-target-triple) \
        --prefix=$INS_PREFIX \
        --datarootdir=$INS_PREFIX/share \
        --enable-static \
        --disable-shared \
        --disable-nls \
        --disable-startup-notification \
        --disable-session-management \
        --disable-xcursor \
        --disable-librsvg \
        --disable-xkb \
        --disable-xinerama 
```


