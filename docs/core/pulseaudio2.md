
- cmds (args)
  - ref github's x2
  - view deps
  - try 11.0
- LIBS @v13.99.3
  - configure args
 - **try03** XXARGS=ABC ./configure

## cmds

- ref github's x2

```bash
#https://github.com/hchapman/pulseaudio-android-ndk/blob/80b6b09408e35c176a9731dc7e0f94385ad45d28/build.sh#L27
../pulseaudio/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --enable-static --disable-rpath --disable-nls --disable-x11 --disable-oss-wrapper --disable-alsa --disable-esound --disable-waveout --disable-glib2 --disable-gtk3 --disable-gconf --disable-avahi --disable-jack --disable-asyncns --disable-tcpwrap --disable-lirc --disable-dbus --disable-bluez4 --disable-bluez5 --disable-udev --disable-openssl --disable-xen --disable-systemd --disable-manpages --disable-samplerate --without-speex --with-database=simple --disable-orc --without-caps --without-fftw
# --enable-static-bins
make
make install


# https://github.com/LibreGamesArchive/planetblupi-dev/blob/35885302de0ebcbcf028783d02101d7f4a6ef9bc/CMakeLists.txt#L288
# URL https://freedesktop.org/software/pulseaudio/releases/pulseaudio-11.0.tar.xz
CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
./configure \
      --prefix=${CMAKE_BINARY_DIR} \
      --disable-shared \
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
      --disable-bluez4 \
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
      --enable-static-bins \
      --without-caps \
      --without-fftw \
      --without-speex \
      --without-soxr \
      --with-database=simple


# make @v13.99.3
# dyn:make直接过
  557  make clean
  558  make

# static:make
make LDFLAGS="-static --static -lltdl -logg -lopus -lsndfile -lintl"
# vorbis vorbisenc FLAC
make LDFLAGS="-static --static -logg -lopus -lsndfile "
# 一样ERR: ogg|opus|FLAC相关库找不到;

bash-5.1# find /usr/lib |egrep "opus|ogg|vorbis|vorbisenc|FLAC" |grep .a$ 
/usr/lib/libopus.a
/usr/lib/libogg.a
```

- view deps

```bash
#view @v13.99.3
-rwxr-xr-x    1 root     root      506.1K Nov 27 03:21 pacat
-rwxr-xr-x    1 root     root      481.9K Nov 27 03:21 pacmd
-rwxr-xr-x    1 root     root      578.1K Nov 27 03:21 pactl
-rw-r--r--    1 root     root        2.2K Nov 27 03:21 padsp
-rwxr-xr-x    1 root     root      529.9K Nov 27 03:21 pasuspender
drwxr-xr-x    3 root     root       12.0K Nov 27 03:21 pulse
-rwxr-xr-x    1 root     root        9.4M Nov 27 03:21 pulseaudio
drwxr-xr-x    6 root     root       24.0K Nov 27 03:20 pulsecore
-rwxr-xr-x    1 root     root        1.7K Nov 27 03:19 start-pulseaudio-x11
-rw-r--r--    1 root     root        1.9K Nov 27 03:19 system.pa
drwxr-xr-x    3 root     root        4.0K Nov 27 03:21 tests
drwxr-xr-x    3 root     root        4.0K Nov 27 03:21 utils
bash-5.1# ldd src/pulseaudio 
        /lib/ld-musl-x86_64.so.1 (0x7f7e24d7e000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f7e243ac000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f7e24d7e000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f7e24378000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f7e24350000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f7e242a6000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7f7e24246000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7f7e2423c000)
bash-5.1# ldd src/pactl 
        /lib/ld-musl-x86_64.so.1 (0x7f1a13935000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7f1a13833000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f1a13935000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7f1a137ff000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7f1a137d7000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7f1a1372d000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7f1a136cd000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7f1a136c3000)
```

- try 11.0

- stable-`1.x 2.x 3.x; 7.x 11.x 12.x 14.x 16.x`
- 16.99.1 10234commits, master 10245
- 13.99.3 9452commits @2020-10-30 `ogg opus sndfile` `FLAC vorbis vorbisenc`
- 11.0 8607commits @2017-09-05; static-11.x 8615commits


```bash
  576  cd ..
  577  ls
  578  git clone https://gitee.com/g-system/fk-pulseaudio
  579  cd fk-pulseaudio/
  580  ls
  582  git remote -v
  583  git checkout origin/v11.0 #>> v11.0
  584  git fetch
  586  git checkout origin/stable-11.x
  587  ls
  588  cat autogen.sh 
  589  ls
  590  NOCONFIGURE=1 ./bootstrap.sh

# bash-5.1# make
4 warnings generated.
  CC       pulsecore/libpulsecommon_11.1_la-shm.lo
In file included from pulsecore/shm.c:48:
./pulsecore/memfd-wrappers.h:36:19: error: static declaration of 'memfd_create' follows non-static declaration
static inline int memfd_create(const char *name, unsigned int flags) {
                  ^
/usr/include/sys/mman.h:131:5: note: previous declaration is here
int memfd_create (const char *, unsigned);
    ^
4 warnings and 1 error generated.
make[3]: *** [Makefile:8413: pulsecore/libpulsecommon_11.1_la-shm.lo] Error 1
make[3]: Leaving directory '/mnt2/fk-pulseaudio/src'
make[2]: *** [Makefile:5294: all] Error 2
make[2]: Leaving directory '/mnt2/fk-pulseaudio/src'
make[1]: *** [Makefile:810: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/fk-pulseaudio'
make: *** [Makefile:625: all] Error 2

# origin/stable-11.x>> 切换到tag:v11.0 一样错误
  600  git checkout v11.0
  601  make

```

## LIBS @v13.99.3

- configure args

```bash
# ss --enable-static-bins >> =yes
# --disable-bluez4 \ #configure: WARNING: unrecognized options: --disable-bluez4
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

# ./configure
CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
LIBS="-logg -lopus -lsndfile " ./configure \
      --prefix=${CMAKE_BINARY_DIR} \
      $args

# bash-5.1# cat Makefile |grep "LIBS ="
LIBS = -logg -lopus -lsndfile 
# bash-5.1# cat src/Makefile |grep "^LIBS ="
LIBS = -logg -lopus -lsndfile

make clean
make LDFLAGS="-static --static"


# 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
bash-5.1# make LDFLAGS="-static --static" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libcommon_la-ogg.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-flac.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_opus.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_vorbis.o):

# bash-5.1# find |grep Makefile$
./src/modules/Makefile
./src/Makefile
./src/daemon/Makefile
./src/pulsecore/Makefile
./src/utils/Makefile
./src/pulse/Makefile
./src/tests/Makefile
./Makefile
./build/meson-private/cmake_bash-completion/Makefile
./doxygen/Makefile
./po/Makefile
./man/Makefile



```

- **try03** XXARGS=ABC ./configure

```bash
# ss

/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_opus.o): in function 'ogg_opus_open':
ogg_opus.c:(.text+0x1c09): undefined reference to 'opus_get_version_string'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2270): undefined reference to 'opus_multistream_encoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x227f): undefined reference to 'opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x22fd): undefined reference to 'ogg_packet_clear'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2348): undefined reference to 'ogg_stream_init'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:7276: pulseaudio] Error 1
make[3]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
make[2]: *** [Makefile:5397: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
make[1]: *** [Makefile:834: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/pulseaudio'
make: *** [Makefile:649: all] Error 2
bash-5.1# 
# bash-5.1# make LDFLAGS="-static --static"  AM_LDFLAGS="-static --static -lltdl -logg -lopus -lsndfile -lintl"

# make LDFLAGS="-static --static"  LIBS=" -logg -lopus -lsndfile -lintl"
# make LDFLAGS="-static --static"  PREOPEN_LIBS=" -logg -lopus -lsndfile -lintl"

# bash-5.1# find /usr/lib |egrep "ogg|opus" |grep "\.a$" |sort
/usr/lib/libogg.a
/usr/lib/libopus.a


# 
LDFLAGS="-static --static"  PREOPEN_LIBS=" -logg -lopus -lsndfile -lintl" ./configure \
      --prefix=${CMAKE_BINARY_DIR} $args

bash-5.1# make
ogg_opus.c:(.text+0x1c09): undefined reference to 'opus_get_version_string'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2243): undefined reference to 'opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2270): undefined reference to 'opus_multistream_encoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x227f): undefined reference to 'opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x22fd): undefined reference to 'ogg_packet_clear'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2348): undefined reference to 'ogg_stream_init'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:7276: pulseaudio] Error 1
make[3]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
make[2]: *** [Makefile:5397: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
make[1]: *** [Makefile:834: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/pulseaudio'
make: *** [Makefile:649: all] Error 


# 一样
LIBS="-logg -lopus -lsndfile" LDFLAGS="-static --static -logg -lopus -lsndfile"  PREOPEN_LIBS=" -logg -lopus -lsndfile -lintl" ./configure \
      --prefix=${CMAKE_BINARY_DIR} $args


# 去LDFLAGS; 去-static: OK
CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
LIBS="-logg -lopus -lsndfile" ./configure \
      --prefix=${CMAKE_BINARY_DIR} $args

# bash-5.1# make
7 warnings generated.
  CCLD     libpulsedsp.la
ar: 'u' modifier ignored since 'D' is the default (see 'U')
/bin/sed -e 's|@PULSEDSP_LOCATION[@]|/usr/local/static/pulseaudio/lib/pulseaudio|g' utils/padsp.in > padsp
  GEN      modules/gsettings/org.freedesktop.pulseaudio.gschema.valid
make[3]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/src'
Making all in doxygen
make[2]: Entering directory '/mnt2/_misc2/pulseaudio/doxygen'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/doxygen'
Making all in man
make[2]: Entering directory '/mnt2/_misc2/pulseaudio/man'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/man'
Making all in po
make[2]: Entering directory '/mnt2/_misc2/pulseaudio/po'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio/po'
make[2]: Entering directory '/mnt2/_misc2/pulseaudio'
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio'
make[1]: Leaving directory '/mnt2/_misc2/pulseaudio'

# ls -lh ./src
drwxr-xr-x   15 root     root       16.0K Nov 28 13:29 modules
-rwxr-xr-x    1 root     root      506.1K Nov 28 13:29 pacat
-rwxr-xr-x    1 root     root      481.9K Nov 28 13:29 pacmd
-rwxr-xr-x    1 root     root      578.1K Nov 28 13:29 pactl
-rw-r--r--    1 root     root        2.2K Nov 28 13:29 padsp
-rwxr-xr-x    1 root     root      529.9K Nov 28 13:29 pasuspender
drwxr-xr-x    3 root     root       12.0K Nov 28 13:29 pulse
-rwxr-xr-x    1 root     root        9.4M Nov 28 13:29 pulseaudio
drwxr-xr-x    6 root     root       24.0K Nov 28 13:28 pulsecore
-rwxr-xr-x    1 root     root        1.7K Nov 28 13:27 start-pulseaudio-x11
-rw-r--r--    1 root     root        1.9K Nov 28 13:27 system.pa
drwxr-xr-x    3 root     root        4.0K Nov 28 13:29 tests
drwxr-xr-x    3 root     root        4.0K Nov 28 13:29 utils
# bash-5.1# ldd src/pulseaudio 
        /lib/ld-musl-x86_64.so.1 (0x7fcba7d2c000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fcba735a000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fcba7d2c000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fcba7326000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fcba72fe000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fcba7254000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fcba71f4000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fcba71ea000)
bash-5.1# 


# NODELETE_LDFLAGS
CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
dep1="-logg -lopus -lsndfile"
LIBS="$dep1" LDFLAGS="-static --static" NODELETE_LDFLAGS=" $dep1"  PREOPEN_LIBS=" $dep1" ./configure \
      --prefix=${CMAKE_BINARY_DIR} $args
make clean
make LDFLAGS="-static --static $dep1" 

# bash-5.1# make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u 
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libcommon_la-ogg.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-flac.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_opus.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(libsndfile_la-ogg_vorbis.o):
```
