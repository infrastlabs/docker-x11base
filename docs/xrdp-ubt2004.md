
- cmds

```bash
# ref: compile2 @ubt2004
ver="0.9.16"
tar -zxf /src/arm/xrdp-${ver}.tar.gz;\
cd xrdp-${ver};
./bootstrap;
./configure \
    --prefix=/usr/local/xrdp \
    --enable-vsock \
    --enable-fdkaac \
    --enable-opus \
    --enable-fuse \
    --enable-mp3lame \
    --enable-pixman \
    CFLAGS='-Wno-format';
make;
make install;
```

```bash
# ##############
# ref x-xrdp/build.sh @alpine315
b_deps)
    /src/x-xrdp/build.sh libxrandr &
    /src/x-xrdp/build.sh fdkaac &
    wait
#  220 apk add pam-dev
apk add openssl-dev openssl-libs-static libxcb-static fuse-static 
apk add fuse-dev fdk-aac-dev opus-dev lame-dev;
apk add nasm
# 
rm -rf /tmp/xrdp; mkdir -p /tmp/xrdp
log "Downloading XRDP..."
down_catfile ${XRDP_URL} | tar -zx --strip 1 -C /tmp/xrdp
log "Configuring XRDP..."
cd /tmp/xrdp && ./bootstrap;

# fix code
sed -i "s^putpwent(spw, fd);^// putpwent(spw, fd);^g" ./sesman/verify_user.c

f=sesman/chansrv/Makefile.am
sed -i "s^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11^\$(X_PRE_LIBS) -lXfixes -lXrandr -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
f=sesman/tools/Makefile.am
sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f
f=genkeymap/Makefile.am 
sed -i "s^\$(X_PRE_LIBS) -lX11^\$(X_PRE_LIBS) -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac^g" $f

./configure \
  --prefix=$TARGETPATH \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  --disable-pam \
  --disable-static \
  --enable-shared \
  --enable-devel-all 

make
make install

# libvnc.so
cd $TARGETPATH/lib/xrdp
gcc -shared -o libvnc.so libvnc.a 
```

## try1

```bash
# export LDFLAGS="-static"
export TARGETPATH=/usr/local/xrdp
./configure \
  --prefix=$TARGETPATH \
  --enable-vsock \
  --enable-fdkaac \
  --enable-opus \
  --enable-fuse \
  --enable-mp3lame \
  --enable-pixman \
  \
  --disable-pam \
  --enable-static \
  --enable-shared \
  --enable-devel-all 

make clean
make
make install
```

- ubt2004's build

```bash
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# ls vnc/
Makefile  Makefile.am  Makefile.in  libvnc.la  vnc.c  vnc.h  vnc.lo  vnc.o
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# find |grep libvnc
./vnc/.libs/libvnc.a
./vnc/.libs/libvnc.lai
./vnc/.libs/libvnc.la
./vnc/.libs/libvnc.so
./vnc/libvnc.la
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# cp -a ./vnc/.libs ./vnc/.libs-bk1
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# ls -lh ./vnc/.libs
total 140K
-rw-r--r-- 1 root root 44K Nov 13 05:59 libvnc.a
lrwxrwxrwx 1 root root  12 Nov 13 05:59 libvnc.la -> ../libvnc.la
-rw-r--r-- 1 root root 994 Nov 13 05:59 libvnc.lai
-rwxr-xr-x 1 root root 48K Nov 13 05:59 libvnc.so ##
-rw-r--r-- 1 root root 43K Nov 13 05:59 vnc.o
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# ls -lh xrdp/xrdp
-rwxr-xr-x 1 root root 6.2K Nov 13 05:59 xrdp/xrdp

# +args
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# ls -lh ./vnc/.libs
total 308K
lrwxrwxrwx 1 root root   12 Nov 13 06:08 libvnc.la -> ../libvnc.la
-rw-r--r-- 1 root root  986 Nov 13 06:08 libvnc.lai
-rwxr-xr-x 1 root root 131K Nov 13 06:08 libvnc.so ##
-rw-r--r-- 1 root root 169K Nov 13 06:08 vnc.o

# --enable-static \
root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16# ls -lh ./vnc/.libs
total 480K
-rw-r--r-- 1 root root 171K Nov 13 06:13 libvnc.a
lrwxrwxrwx 1 root root   12 Nov 13 06:13 libvnc.la -> ../libvnc.la
-rw-r--r-- 1 root root  994 Nov 13 06:13 libvnc.lai
-rwxr-xr-x 1 root root 131K Nov 13 06:13 libvnc.so ##
-rw-r--r-- 1 root root 169K Nov 13 06:13 vnc.o
# root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16/xrdp# cp xrdp xrdp-bk3-enableStatic
# root@446ef34d2a6f:/mnt2/_ubt/xrdp-0.9.16/xrdp# ls -lh xrdp-bk3-enableStatic 
-rwxr-xr-x 1 root root 6.2K Nov 13 06:16 xrdp-bk3-enableStatic
```

- static@ubt-gcc

```bash
# static
# static-config
export LDFLAGS="-static"
unset LDFLAGS
# configure: error: please install libx11-dev or libX11-devel

# static-make
export LDFLAGS="-static "
export LDFLAGS="-static -lX11    -lX11-xcb -lxcb -lXdmcp -lXau  -lfdk-aac"
make
# 仍为非static模式;
```

