
- dyn @24.1.14

```bash
#  1859  2024-01-14 16:49:43 docker run -it --rm --privileged -v /mnt:/mnt2 infrastlabs/x11-base:alpine-builder-gtk224 bash
#  docker run -it --rm --privileged -v /mnt:/mnt2 infrastlabs/x11-base:builder bash
    6  cd /mnt2/_misc2/fk-pulseaudio/
   11  apk add intltool
   12  ./autogen.sh 
   13  ./autogen.sh  --without-caps
   15  apk add libsndfile-dev 
   16  find /usr/lib |grep libsndf

# make, install
   39  ./autogen.sh  --without-caps
   40  make
   42  cat git-version-gen 
   46  make install
   47  find /usr/local/ |grep pulse
   49  find /usr/local/ |grep pulse |grep bin
   50  ldd /usr/local/bin/pulseaudio 

# bash-5.1# ldd /usr/local/bin/pulseaudio |sort
        /lib/ld-musl-x86_64.so.1 (0x7fb099548000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fb099548000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fb0993ad000)
        libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7fb0993a2000)
        # libpulse.so.0 => /usr/local/lib/libpulse.so.0 (0x7fb099434000)
        # libpulsecommon-13.99.so => /usr/local/lib/pulseaudio/libpulsecommon-13.99.so (0x7fb0993ba000)
        # libpulsecore-13.99.so => /usr/local/lib/pulseaudio/libpulsecore-13.99.so (0x7fb099488000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fb0991c2000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fb0991cc000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fb099332000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fb0992fe000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fb0992d6000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fb09922c000)
```

- static

```bash
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++


# apk add libltdl-static
./autogen.sh  --without-caps
make 

bash-5.1# ls src/pulseaudio -lh
-rwxr-xr-x    1 root     root       10.1M Jan 14 09:17 src/pulseaudio
bash-5.1# ldd src/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7f10d39b7000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f10d39b7000)
        # libintl.so.8 => /usr/lib/libintl.so.8 (0x7f10d2f86000)
        # libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7f10d2f0b000)
        # libogg.so.0 => /usr/lib/libogg.so.0 (0x7f10d2d9b000)
        # libopus.so.0 => /usr/lib/libopus.so.0 (0x7f10d2da5000)
        # libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f10d2f16000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f10d2ed7000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f10d2eaf000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f10d2e05000)

# bash-5.1# ls -lh src/pa*
-rwxr-xr-x    1 root     root      514.1K Jan 14 09:17 src/pacat
-rwxr-xr-x    1 root     root      485.9K Jan 14 09:17 src/pacmd
-rwxr-xr-x    1 root     root      582.1K Jan 14 09:17 src/pactl
-rw-r--r--    1 root     root        2.2K Jan 14 09:17 src/padsp
-rwxr-xr-x    1 root     root      533.9K Jan 14 09:17 src/pasuspender
# bash-5.1# ldd src/pactl |sort
        /lib/ld-musl-x86_64.so.1 (0x7f4df84d6000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f4df84d6000)
        # libintl.so.8 => /usr/lib/libintl.so.8 (0x7f4df8436000)
        # libogg.so.0 => /usr/lib/libogg.so.0 (0x7f4df8256000)
        # libopus.so.0 => /usr/lib/libopus.so.0 (0x7f4df8260000)
        # libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f4df83c6000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f4df8392000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f4df836a000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f4df82c0000)

# find /usr/lib |egrep "libintl|libltdl|sndfile|opus|ogg|vorbis|FLAC" |grep .a$ 
# bash-5.1# find /usr/lib |egrep "libintl|libltdl|sndfile|opus|ogg|vorbis|FLAC" |grep .a$ 
/usr/lib/libopus.a
/usr/lib/libogg.a
/usr/lib/libsndfile.a
/usr/lib/libltdl.a
/usr/lib/libintl.a
```

- ./configure args

```bash
# enable-static-bins
args="--disable-shared \
      --enable-static \
      --disable-alsa \
      --disable-nls \
      --disable-x11 \
      --disable-tests \
      --disable-esound \
      --disable-waveout \
      --disable-gconf \
      --disable-glib2 \
      --disable-gtk3 \
      --disable-jack \
      --disable-asyncns \
      --disable-avahi \
      --disable-openssl \
      --disable-tcpwrap \
      --disable-lirc \
      --disable-dbus \
      --disable-udev \
      --disable-bluez5 \
      --disable-hal-compat \
      --disable-ipv6 \
      --disable-webrtc-aec \
      --disable-systemd-daemon \
      --disable-systemd-login \
      --disable-systemd-journal \
      --disable-manpages \
      --disable-default-build-tests \
      --disable-legacy-database-entry-format \
      --enable-static-bins=yes \
      --without-caps \
      --without-fftw \
      --without-speex \
      --without-soxr \
      --with-database=simple"

./configure --without-caps #auto-gen.sh之后即OK (./git-version-gen文件)
./configure --without-caps $args
make clean;
make;

# 10.1M> 9.4M; deps:少了libintl
bash-5.1# ls -lh src/pulseaudio 
-rwxr-xr-x    1 root     root        9.4M Jan 14 09:46 src/pulseaudio
bash-5.1# ls -lh src/pa*
-rwxr-xr-x    1 root     root      506.1K Jan 14 09:46 src/pacat
-rwxr-xr-x    1 root     root      481.9K Jan 14 09:46 src/pacmd
-rwxr-xr-x    1 root     root      578.1K Jan 14 09:46 src/pactl
-rw-r--r--    1 root     root        2.2K Jan 14 09:46 src/padsp
-rwxr-xr-x    1 root     root      529.9K Jan 14 09:46 src/pasuspender
bash-5.1# ldd src/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7fb00bf36000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fb00bf36000)
        # libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7fb00b55d000)
        # libogg.so.0 => /usr/lib/libogg.so.0 (0x7fb00b3ed000)
        # libopus.so.0 => /usr/lib/libopus.so.0 (0x7fb00b3f7000)
        # libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fb00b568000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fb00b529000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fb00b501000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fb00b457000)
```

- try-b1

```bash
# -lltdl
CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
LIBS="-lltdl -logg -lopus -lsndfile " ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args

make clean
make LDFLAGS="-static --static"
# deps无变化


# libvorbis-1.3.5 (installed ver)
# https://github.com/xiph/vorbis #v137@2020.7.5
  111  git clone https://hub.yzuu.cf/pcwalton/vorbis #The Xiph.org Vorbis library; servo_v135;
  112  cd vorbis/
  114  ./autogen.sh 
  115  make
  117  make install
bash-5.1# find /usr/local/ |grep vorbis|grep "\.a$"
/usr/local/lib/libvorbisfile.a
/usr/local/lib/libvorbis.a
/usr/local/lib/libvorbisenc.a

# https://github.com/xiph/flac #v143@master
  127  git clone https://hub.yzuu.cf/xiph/flac
  128  cd flac/
  130  ./autogen.sh 
  132  ./configure 
  133  make
  134  make install
bash-5.1# find /usr/local/ |grep FLAC |grep "\.a$"
/usr/local/lib/libFLAC.a
/usr/local/lib/libFLAC++.a

# fk-pulseaudio
LIBS="-lltdl -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean; make

# bash-5.1# ls -lh src/pulseaudio 
-rwxr-xr-x    1 root     root        9.4M Jan 14 10:11 src/pulseaudio
# bash-5.1# ldd src/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7f4d544e8000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f4d544e8000)
        # libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7f4d53b7f000)
        # libogg.so.0 => /usr/lib/libogg.so.0 (0x7f4d5399f000)
        # libopus.so.0 => /usr/lib/libopus.so.0 (0x7f4d539a9000)
        # libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f4d53b0f000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f4d53adb000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f4d53ab3000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f4d53a09000)
# deps依旧
```

- try-b2 `make LDFLAGS="-static --static $dep1"`

```bash
# make clean; make
dep1="-lltdl -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
make clean
make LDFLAGS="-static --static $dep1" 

# err1:
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object '/usr/lib/libltdl.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:7276: pulseaudio] Error 1
make[3]: Leaving directory '/mnt2/_misc2/fk-pulseaudio/src'


# baidu_libltdl: ltdl是用来加载运态库的库
# bash-5.1# mv /usr/lib/libltdl.so /usr/lib/libltdl.so-ex
clang-12: error: no such file or directory: '/usr/lib/libltdl.so'


# 改代码01：
# 改Mackefile.am>>  # $(LIBLTDL) x3; >>> 同样libltdl.so找不到错误;
# 改Configure.ac>> 注释LIBLTDL; Mackefile.am注释两行; pulsecore/module.h注释ltdl.h; >>> // lt_dlhandle dl; >>> module.c 10处引用;
# 
dep1="-lltdl -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1" 
#改引用后，so错误依旧:
# lang-12: error: no such file or directory: '/usr/lib/libltdl.so' 
 

# ref: xrdp>> libxvnc插件(动态加载> 直接在代码内调用)
# 
# 手动从dep1去除ltdl;>> ltdl.so错误过了;
# -lltdl 
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1" 


# vorbis func错;
# 改v137@https://github.com/xiph/vorbis
make LDFLAGS="-static --static $dep1" 
# 同样错：
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libvorbis.a(mapping0.o): in function 'mapping0_forward':
mapping0.c:(.text+0xb67): undefined reference to 'oggpack_write'
/usr/bin/x86_64-alpine-linux-musl-ld: mapping0.c:(.text+0xb7a): undefined reference to 'oggpack_write'
/usr/bin/x86_64-alpine-linux-musl-ld: mapping0.c:(.text+0xb92): undefined reference to 'oggpack_write'
/usr/bin/x86_64-alpine-linux-musl-ld: mapping0.c:(.text+0xba3): undefined reference to 'oggpack_write'


# bash-5.1# make LDFLAGS="-static --static $dep1"  2>&1 |egrep -v "warning|extern|void|\^"
make  all-recursive
make[1]: Entering directory '/mnt2/_misc2/fk-pulseaudio'
Making all in src
make[2]: Entering directory '/mnt2/_misc2/fk-pulseaudio/src'
make  all-am
make[3]: Entering directory '/mnt2/_misc2/fk-pulseaudio/src'
  CCLD     pulseaudio

# bash-5.1# make LDFLAGS="-static --static $dep1"  2>&1 |egrep -v "warning|extern|void|\^" |wc
      372      2096     38396
# bash-5.1# make LDFLAGS="-static --static $dep1"  2>&1 |egrep -v "warning|extern|void|\^" > /mnt2/temp1/pulse03-static-buildErr1.txt

# bash-5.1# apk list -I |egrep "ogg|opus|flac|vorbis|sndfile" |grep -v dev |sort
flac-1.3.4-r0 x86_64 {flac} (custom:Xiph LGPL GPL FDL) [installed]
opus-1.3.1-r1 x86_64 {opus} (BSD-3-Clause) [installed]
libogg-1.3.5-r0 x86_64 {libogg} (BSD-3-Clause) [installed]
libvorbis-1.3.7-r0 x86_64 {libvorbis} (BSD-3-Clause) [installed]
libsndfile-1.0.31-r1 x86_64 {libsndfile} (LGPL-2.0-or-later) [installed]

# bash-5.1# find /usr/lib /usr/local/lib |egrep "libintl|libltdl|sndfile|opus|ogg|vorbis|FLAC" |grep "\.a$"  |sort
# /usr/lib/libintl.a
# /usr/lib/libltdl.a
/usr/lib/libogg.a
/usr/lib/libopus.a
/usr/lib/libsndfile.a
# 
# /usr/local/lib/libogg.a
# /usr/local/lib/libopus.a
/usr/local/lib/libFLAC.a   ##v1.3.4-r0 @alpine315
/usr/local/lib/libFLAC++.a 
/usr/local/lib/libvorbis.a ##1.3.7-r0 @alpine315
/usr/local/lib/libvorbisenc.a
/usr/local/lib/libvorbisfile.a

# rm -f /usr/local/lib/libogg.a /usr/local/lib/libopus.a

# bash-5.1# apk add libsndfile-dev   ##dynOK; >> static src版本对齐
(6/11) Installing alsa-lib (1.2.5.1-r1)
(1/11) Installing libogg (1.3.5-r0)
(3/11) Installing opus (1.3.1-r1)
(5/11) Installing flac (1.3.4-r0)
(7/11) Installing libvorbis (1.3.7-r0)
(8/11) Installing libsndfile (1.0.31-r1)
# dev
(2/11) Installing libogg-dev (1.3.5-r0)
(4/11) Installing opus-dev (1.3.1-r1)
(9/11) Installing flac-dev (1.3.4-r0)
(10/11) Installing libvorbis-dev (1.3.7-r0)
(11/11) Installing libsndfile-dev (1.0.31-r1)
Executing busybox-1.34.1-r7.trigger

#  |grep musl/10 |awk '{print $2}' |sort -u
bash-5.1# make LDFLAGS="-static --static $dep1"  2>&1 |egrep -v "warning|extern|void|\^"  |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libcommon_la-ogg.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_opus.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_vorbis.o):
```

- try-b3: libsndfile源码编译静态库

```bash
# https://github.com/libsndfile/libsndfile/tree/1.0.31
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
# export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

make clean
make
# /usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/lib/libogg.so'
# libsndfile.a文件已生成;




# fk-pulseaudio:
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1"

# bash-5.1# make LDFLAGS="-static --static $dep1"  2>&1 |egrep -v "warning|extern|void|\^"  |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(ogg.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(ogg_opus.c.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(ogg_vorbis.c.o):


# ogg_v135 https://github.com/xiph/ogg; 有对应func:
# ogg.h:
  # extern long  oggpack_read(oggpack_buffer *b,int bits);
  # extern void  oggpack_write(oggpack_buffer *b,unsigned long value,int bits);

# bitwise.c:
  /* bits <= 32 */
  # long oggpack_read(oggpack_buffer *b,int bits){
  /* Takes only up to 32 bits. */
  # void oggpack_write(oggpack_buffer *b,unsigned long value,int bits){
  


# ref pulseaudio2, try XXX_LIBS: same err;
LIBS="$dep1" PREOPEN_LIBS="$dep1" NODELETE_LDFLAGS=" $dep1" \
make LDFLAGS="-static --static $dep1"

pulse03-static-buildErr1.txt分析:
libsndfile.a
local/FLAC.a
local/vorbis.a >> ogg/opus分法名依赖找不到..; `oggpack_read/oggpack_write/..`
# ogg/opus等库未能在LD时载入??

bash-5.1# find |grep Makefile$ |sort
./Makefile ##
./doxygen/Makefile
./man/Makefile
./po/Makefile
./src/Makefile
./src/daemon/Makefile ##
./src/modules/Makefile
./src/pulse/Makefile #
./src/pulsecore/Makefile
./src/tests/Makefile
./src/utils/Makefile
# bash-5.1# find |grep Makefile$ |sort |while read one; do echo $one; cat $one |grep ogg -n; done
./Makefile
399:LIBS = -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc
./doxygen/Makefile
264:LIBS = -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc
./man/Makefile
313:LIBS = -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc
./po/Makefile
./src/Makefile
3840:LIBS = -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc
./src/daemon/Makefile
./src/modules/Makefile
./src/pulse/Makefile
./src/pulsecore/Makefile
./src/tests/Makefile
./src/utils/Makefile

# bash-5.1# find |grep Makefile$ |sort |while read one; do echo -e "\n\n$one"; cat $one |egrep "\(LIBS|_LIBS33" -n; done   |wc
      233      1164     25381

# bash-5.1# ldd /usr/local/bin/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7fd58655a000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fd58655a000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fd5863bf000)
        libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7fd5863b4000)
        # libpulse.so.0 => /usr/local/lib/libpulse.so.0 (0x7fd586446000)
        # libpulsecommon-13.99.so => /usr/local/lib/pulseaudio/libpulsecommon-13.99.so (0x7fd5863cc000)
        # libpulsecore-13.99.so => /usr/local/lib/pulseaudio/libpulsecore-13.99.so (0x7fd58649a000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fd5861d4000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fd5861de000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fd586344000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fd586310000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fd5862e8000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fd58623e000)
```

- try-b4 `cd src; make #dyn, fix src's ref`

```bash
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f98): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f88): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2fa8): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f78): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3198): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3188): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: daemon/pulseaudio-dumpmodules.o: in function 'pa_dump_modules':
dumpmodules.c:(.text+0x3c): undefined reference to 'pa_modinfo_get_by_name'
/usr/bin/x86_64-alpine-linux-musl-ld: daemon/pulseaudio-ltdl-bind-now.o: in function 'pa_ltdl_init':
ltdl-bind-now.c:(.text+0x4): undefined reference to 'lt_dlinit'
/usr/bin/x86_64-alpine-linux-musl-ld: daemon/pulseaudio-ltdl-bind-now.o: in function 'pa_ltdl_done':
ltdl-bind-now.c:(.text+0x55): undefined reference to 'lt_dlexit'
/usr/bin/x86_64-alpine-linux-musl-ld: daemon/pulseaudio-main.o: in function `main':
main.c:(.text+0x198): undefined reference to 'lt_dlsetsearchpath'
/usr/bin/x86_64-alpine-linux-musl-ld: ./.libs/module-ladspa-sink.a(module_ladspa_sink_la-module-ladspa-sink.o): in function `module_ladspa_sink_LTX_pa__init':
module-ladspa-sink.c:(.text+0x394): undefined reference to 'lt_dlgetsearchpath'
/usr/bin/x86_64-alpine-linux-musl-ld: module-ladspa-sink.c:(.text+0x3a9): undefined reference to 'lt_dlsetsearchpath'
/usr/bin/x86_64-alpine-linux-musl-ld: module-ladspa-sink.c:(.text+0x3b3): undefined reference to 'lt_dlsetsearchpath'
/usr/bin/x86_64-alpine-linux-musl-ld: /mnt2/_misc2/fk-pulseaudio/src/.libs/libpulsecore-13.99.a(libpulsecore_13.99_la-cli-command.o): in function 'pa_cli_command_describe':
cli-command.c:(.text+0x25c0): undefined reference to 'pa_modinfo_get_by_name'
/usr/bin/x86_64-alpine-linux-musl-ld: /mnt2/_misc2/fk-pulseaudio/src/.libs/libpulsecore-13.99.a(libpulsecore_13.99_la-module.o): in function 'pa_module_exists':
module.c:(.text+0x90): undefined reference to 'lt_dlgetsearchpath'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[1]: *** [Makefile:7278: pulseaudio] Error 1
make[1]: Leaving directory '/mnt2/_misc2/fk-pulseaudio/src'
make: *** [Makefile:5399: all] Error 2
bash-5.1# #make
bash-5.1# pwd
/mnt2/_misc2/fk-pulseaudio/src


# make
# dyn make 排除src移除`ldtl`后的ref-err


bash-5.1# ls -lh pulseaudio 
-rwxr-xr-x    1 root     root        9.0M Jan 15 13:01 pulseaudio
bash-5.1# ldd pulseaudio |sort
        /lib/ld-musl-x86_64.so.1 (0x7f832c462000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f832c462000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7f832b976000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7f832b980000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f832bae6000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f832bab2000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f832ba8a000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f832b9e0000)


make clean
make LDFLAGS="-static --static $dep1"


# 
bash-5.1# git pull; ./autogen.sh
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1"

```