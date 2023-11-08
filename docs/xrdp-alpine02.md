
- cmds cp

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



# env |grep FLAGS
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

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
  --disable-pam \
  --enable-static \
  --enable-shared \
  --enable-devel-all 

make
make install

# libvnc.so
cd $TARGETPATH/lib/xrdp
gcc -shared -o libvnc.so libvnc.a 
```

- dyn,static

```bash
bash-5.1# ls -lh ./vnc/.libs/
total 364K   
-rw-r--r--    1 root     root      113.9K Nov 13 13:50 libvnc.a
lrwxrwxrwx    1 root     root          12 Nov 13 13:50 libvnc.la -> ../libvnc.la
-rw-r--r--    1 root     root         973 Nov 13 13:50 libvnc.lai
-rwxr-xr-x    1 root     root      131.5K Nov 13 13:50 libvnc.so
-rw-r--r--    1 root     root      110.5K Nov 13 13:50 vnc.o
bash-5.1# ldd ./vnc/.libs/libvnc.so 
        /lib/ld-musl-x86_64.so.1 (0x7f6ee361b000)
        libcommon.so.0 => /mnt2/_alpine/xrdp-0.9.16/common/.libs/libcommon.so.0 (0x7f6ee35f6000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f6ee361b000)
        libssl.so.1.1 => /lib/libssl.so.1.1 (0x7f6ee3575000)
        libcrypto.so.1.1 => /lib/libcrypto.so.1.1 (0x7f6ee32f2000)
bash-5.1# cp -a ./vnc/.libs ./vnc/.libs-bk1-dyn


# LDFLAGS="-static" make -C ./vnc
bash-5.1# ls vnc/ -lh
total 256K   
-rw-r--r--    1 root     root       20.9K Nov 13 13:41 Makefile
-rw-r--r--    1 1001     1001         453 Dec 28  2020 Makefile.am
-rw-r--r--    1 root     root       21.5K Nov 13 13:36 Makefile.in
-rw-r--r--    1 root     root        1.2K Nov 13 13:58 libvnc.la
-rw-r--r--    1 1001     1001       70.4K Apr 30  2021 vnc.c
-rw-r--r--    1 1001     1001        5.9K Apr 30  2021 vnc.h
-rw-r--r--    1 root     root         261 Nov 13 13:58 vnc.lo
-rw-r--r--    1 root     root      113.3K Nov 13 13:58 vnc.o
# bash-5.1# make -C ./vnc/ clean
make: Entering directory '/mnt2/_alpine/xrdp-0.9.16/vnc'
rm -rf .libs _libs
test -z "libvnc.la" || rm -f libvnc.la
rm -f ./so_locations
rm -f *.o
rm -f *.lo
make: Leaving directory '/mnt2/_alpine/xrdp-0.9.16/vnc'
# bash-5.1# LDFLAGS="-static" make -C ./vnc
make: Entering directory '/mnt2/_alpine/xrdp-0.9.16/vnc'
  CC       vnc.lo
  CCLD     libvnc.la
ar: 'u' modifier ignored since 'D' is the default (see 'U')
make: Leaving directory '/mnt2/_alpine/xrdp-0.9.16/vnc'
bash-5.1# ls -lh vnc/vnc.o 
-rw-r--r--    1 root     root      113.3K Nov 13 13:59 vnc/vnc.o
```

- gcc -shared -fPIC -Wl,--whole-archive

```bash
# bash-5.1# gcc -shared -fPIC  libvnc.a -o libvnc.so 2>&1 #生成15Kb
# bash-5.1# gcc -shared -fPIC -Wl,--whole-archive libvnc.a -o libvnc.so 2>&1 #一堆错
bash-5.1# 
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: libvnc.a(vnc.o): warning: relocation against 'lib_mod_event' in read-only section '.text'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: libvnc.a(vnc.o): relocation R_X86_64_PC32 against symbol 'lib_mod_connect' can not be used when making a shared object; recompile with -fPIC
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: final link failed: bad value
collect2: error: ld returned 1 exit status
bash-5.1# 


# https://zhuanlan.zhihu.com/p/202663666
# [Bazel]自定义规则实现将多个静态库合并为一个动态库或静态库
bash-5.1# gcc -shared -fPIC -Wl,--whole-archive libvnc.a  -Wl,--no-whole-archive  -Wl,-soname -o libcombined.so
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: libvnc.a(vnc.o): warning: relocation against 'lib_mod_event' in read-only section `.text'
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: libvnc.a(vnc.o): relocation R_X86_64_PC32 against symbol `lib_mod_connect' can not be used when making a shared object; recompile with -fPIC
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: final link failed: bad value
collect2: error: ld returned 1 exit status

# 
```
