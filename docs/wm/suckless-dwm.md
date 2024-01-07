
## dyn deps

```bash
bash-5.1# apk add dwm
(1/3) Installing dmenu (5.0-r0)
(2/3) Installing st (0.8.4-r0)
(3/3) Installing dwm (6.2-r0)
Executing busybox-1.34.1-r7.trigger
OK: 684 MiB in 211 packages
bash-5.1# which dwm
/usr/bin/dwm
bash-5.1# ldd /usr/bin/dwm |sort
	/lib/ld-musl-x86_64.so.1 (0x7f7dad6f1000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f7dad5c0000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f7dad436000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f7dad42e000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f7dad52e000)
	libXft.so.2 => /usr/lib/libXft.so.2 (0x7f7dad568000)
	libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7f7dad5bb000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f7dad43b000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f7dad391000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f7dad3c7000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f7dad3b4000)
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f7dad41f000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f7dad6f1000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f7dad450000)
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f7dad57e000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f7dad475000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f7dad385000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f7dad3ee000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f7dad447000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f7dad541000)
	libz.so.1 => /lib/libz.so.1 (0x7f7dad3d4000)


bash-5.1# ldd /usr/bin/dmenu |sort
	/lib/ld-musl-x86_64.so.1 (0x7f8a2bfdc000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f8a2beaf000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f8a2bd25000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f8a2bd1d000)
	libXext.so.6 => /usr/lib/libXext.so.6 (0x7f8a2be1d000)
	libXft.so.2 => /usr/lib/libXft.so.2 (0x7f8a2be57000)
	libXinerama.so.1 => /usr/lib/libXinerama.so.1 (0x7f8a2beaa000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f8a2bd2a000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f8a2bc80000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f8a2bcb6000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f8a2bca3000)
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f8a2bd0e000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f8a2bfdc000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f8a2bd3f000)
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f8a2be6d000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f8a2bd64000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f8a2bc74000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f8a2bcdd000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f8a2bd36000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f8a2be30000)
	libz.so.1 => /lib/libz.so.1 (0x7f8a2bcc3000)
bash-5.1# 
bash-5.1# ldd /usr/bin/st |sort
	/lib/ld-musl-x86_64.so.1 (0x7f237879f000)
	libX11.so.6 => /usr/lib/libX11.so.6 (0x7f2378667000)
	libXau.so.6 => /usr/lib/libXau.so.6 (0x7f23784f5000)
	libXdmcp.so.6 => /usr/lib/libXdmcp.so.6 (0x7f23784ed000)
	libXft.so.2 => /usr/lib/libXft.so.2 (0x7f2378651000)
	libXrender.so.1 => /usr/lib/libXrender.so.1 (0x7f2378528000)
	libbrotlicommon.so.1 => /usr/lib/libbrotlicommon.so.1 (0x7f2378450000)
	libbrotlidec.so.1 => /usr/lib/libbrotlidec.so.1 (0x7f2378486000)
	libbsd.so.0 => /usr/lib/libbsd.so.0 (0x7f2378473000)
	libbz2.so.1 => /usr/lib/libbz2.so.1 (0x7f23784de000)
	libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f237879f000)
	libexpat.so.1 => /usr/lib/libexpat.so.1 (0x7f2378503000)
	libfontconfig.so.1 => /usr/lib/libfontconfig.so.1 (0x7f2378614000)
	libfreetype.so.6 => /usr/lib/libfreetype.so.6 (0x7f2378534000)
	libmd.so.0 => /usr/lib/libmd.so.0 (0x7f2378444000)
	libpng16.so.16 => /usr/lib/libpng16.so.16 (0x7f23784ad000)
	libuuid.so.1 => /lib/libuuid.so.1 (0x7f23784fa000)
	libxcb.so.1 => /usr/lib/libxcb.so.1 (0x7f23785ed000)
	libz.so.1 => /lib/libz.so.1 (0x7f2378493000)
```


## src/suckless/build.sh

`st>  dmenu>dwm >> st`

`handBuild@oldBuilder_tmux2> gitacErr> handBuild02@newBuidler_tmux8`

- handBuild01@oldBuilder_quickTry_01

```bash
# err01:
# /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../lib/libXrender.a(Xrender.o):

# handBuild01@oldBuilder_quickTry_01:
# https://gitee.com/xiexie1993/dmenu ##libXinerama
# make LDFLAGS="$flags -lXinerama"
# https://github.com/hajimehoshi/ebiten/blob/2db10b1e9c4be0ae183418301682bad7f0fe4088/internal/glfw/build_linux.go#L6
# make LDFLAGS="$flags -lXinerama   -lX11 -lXrandr -lXxf86vm -lXi -lXcursor -lm -lXinerama -ldl -lrt"

# +-lXext>> OK;
# make LDFLAGS="$flags -lXinerama   -lX11 -lXrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext"
```

- gitac>> handBuild02@newBuilder_02

```bash
# # gitac>> handBuild02@newBuilder_02:
# fontconfig-static@apk>> -luuid 
# xrandr="-lXrandr"
make LDFLAGS="$flags -lXinerama   -lX11 $xrandr -lXxf86vm -lXcursor -lm -lXinerama -ldl -lrt -lXext -luuid"


# make install @hand02:
/mnt2/docker-x11base/compile/src/suckless # ls /opt/base/bin/ -lh
total 11M    
-rwxr-xr-x    1 root     root        3.5M Nov  4 14:59 dmenu
-rwxr-xr-x    1 root     root         240 Nov  4 14:59 dmenu_path
-rwxr-xr-x    1 root     root          58 Nov  4 14:59 dmenu_run
-rwxr-xr-x    1 root     root        3.6M Nov  4 14:56 dwm
-rwxr-xr-x    1 root     root        3.7M Nov  4 15:06 st
-rwxr-xr-x    1 root     root      266.6K Nov  4 14:59 stest
/mnt2/docker-x11base/compile/src/suckless #  

```