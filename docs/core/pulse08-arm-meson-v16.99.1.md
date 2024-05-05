**src**

- v16.99.1 x10234 @23.7.18
- v15.99.1 x10030 @21.10.21
- v14.99.2 x9830 @21.5.30
- v13.99.3 x9452 @20.10.4

**refBuild**

- https://github.com/Kdockerfiles/pulseaudio-shared/blob/master/Dockerfile #v1.13.0@alpine:3.11 `link-libintl.patch`
- https://github.com/iglunix/iglunix/blob/main/snd/libpulse/build.sh #ver=16.1 `distro with no GNU`
- https://github.com/alpinelinux/aports/blob/master/community/pulseaudio/APKBUILD #`link-libintl.patch; remove-once-test.patch`
- 
- https://github.com/xiph?q=snd&type=all&language=&sort=stargazers #`opus,flac,vorbis` https://xiph.org/
- https://github.com/autotools-mirror/libtool/graphs/contributors #Mar 30, 1997+

**arm_err**

- arm64

```bash
# arm64| src/pulsecore/sconv_neon.c #49:27
  # * sconv: Use optimized conversion function for both directions @2014/8/5
  # * sconv: Cleanup ARM NEON code
  # * sconv: avoid multiply in ARM NEON s16->float conversion
  # * sconv: avoid multiply in ARM NEON float->s16 conversion
  # * sconv: Change/fix conversion to/from float32
  # * sconv: Fix NEON sconv rounding code
  # * core: Add ARM NEON optimized sample conversion code @2012/10/13
  # ####
  # arm64| src/pulsecore/cpu-arm.c
  #ifdef HAVE_NEON
      if (*flags & PA_CPU_ARM_NEON) {
          pa_convert_func_init_neon(*flags);
      }
  #endif
void pa_convert_func_init_neon(pa_cpu_arm_flag_t flags) {
    pa_log_info("Initialising ARM NEON optimized conversions.");
    pa_set_convert_from_float32ne_function(PA_SAMPLE_S16LE, (pa_convert_func_t) pa_sconv_s16le_from_f32ne_neon);
    pa_set_convert_to_float32ne_function(PA_SAMPLE_S16LE, (pa_convert_func_t) pa_sconv_s16le_to_f32ne_neon);
#ifndef WORDS_BIGENDIAN
    pa_set_convert_from_s16ne_function(PA_SAMPLE_FLOAT32LE, (pa_convert_func_t) pa_sconv_s16le_to_f32ne_neon);
    pa_set_convert_to_s16ne_function(PA_SAMPLE_FLOAT32LE, (pa_convert_func_t) pa_sconv_s16le_from_f32ne_neon);
#endif
}
static void pa_sconv_s16le_from_f32ne_neon(unsigned n, const float *src, int16_t *dst) {
    __asm__ __volatile__ (
        : "memory", "cc", "q0" /* clobber list */ #49:27
static void pa_sconv_s16le_to_f32ne_neon(unsigned n, const int16_t *src, float *dst) {
    __asm__ __volatile__ (
        : "memory", "cc", "q0" /* clobber list */ #79:27
```

- armv7

```bash
# armv7| src/pulsecore/mix_neon.c #179:9
  # * mix: Add special-case ARM NEON code for s16 mixing @2014/4/16
  # * mix: Add optimized mix code path for ARM NEON @2013/2/14
  # ####
  # armv7| src/pulsecore/cpu-arm.c
  #ifdef HAVE_NEON
      if (*flags & PA_CPU_ARM_NEON) {
          pa_convert_func_init_neon(*flags);
          pa_mix_func_init_neon(*flags);
          pa_remap_func_init_neon(*flags);
      }
  #endif
  void pa_mix_func_init_neon(pa_cpu_arm_flag_t flags) {
  static void pa_mix_s16ne_neon(pa_mix_info streams[], unsigned nstreams, unsigned nchannels, void *data, unsigned length) {
static void pa_mix2_ch4_s16ne_neon(pa_mix_info streams[], int16_t *data, unsigned length) {
    __asm__ __volatile__ (
        "vld1.s32 %h[sv0], [%[lin0]]         \n\t" #179:9

```


**deps** `ubt-pulseaudio` https://distrowatch.com/table.php?distribution=ubuntu

`v1.13.99 > v1:15.99.1 > v1:16.1`

- ubt2404-noble v1:16.1 `opus, sndfile新版`
  - ogg 1.3.5-0
  - opus 1.4-1
  - sndfile 1.2.2-1
  - vorbis 1.3.7-1 ##无FLAC
- ubt2204-jammy v1:15.99.1 `同ubt2004; 无FLAC`
  - ogg 1.3.5-0
  - opus 1.3.1-0 #1.4-1
  - sndfile 1.0.31-2 #1.2.2-1
  - vorbis 1.3.7-1 ##无FLAC
- ubt2004-focal v1.13.99
  - ogg v1.3.5 #1.3.5-0
  - opus v1.3.1 #1.3.1-0 #1.4-1
  - sndfile 1.0.31 #1.0.31-2 #1.2.2-1
  - vorbis v1.3.7 #1.3.7-1 
  - FLAC 1.3.4

```bash
# ref deb12-skip-gpg-check.md
apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install pulseaudio --no-install-recommends

# 2404 v1:16.1
# dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
root@a90d325350c9:/etc/apt/apt.conf.d# dpkg -l |egrep "pulseau|ogg|opus|sndfile|FLAC|vorbis"
ii  libogg0:amd64                        1.3.5-3build1                     amd64        Ogg bitstream library
ii  libopus0:amd64                       1.4-1build1                       amd64        Opus codec runtime library
ii  libsndfile1:amd64                    1.2.2-1ubuntu5                    amd64        Library for reading/writing audio files
ii  libvorbis0a:amd64                    1.3.7-1build3                     amd64        decoder library for Vorbis General Audio Compression Codec
ii  libvorbisenc2:amd64                  1.3.7-1build3                     amd64        encoder library for Vorbis General Audio Compression Codec
ii  pulseaudio                           1:16.1+dfsg1-2ubuntu10            amd64        PulseAudio sound server
ii  pulseaudio-utils                     1:16.1+dfsg1-2ubuntu10            amd64        Command line tools for the PulseAudio sound server

# 2204 v1:15.99.1
root@bf8a8d987d20:/etc/apt/apt.conf.d# dpkg -l |egrep "pulseau|ogg|opus|sndfile|FLAC|vorbis"
ii  libogg0:amd64                        1.3.5-0ubuntu3                          amd64        Ogg bitstream library
ii  libopus0:amd64                       1.3.1-0.1build2                         amd64        Opus codec runtime library
ii  libsndfile1:amd64                    1.0.31-2ubuntu0.1                       amd64        Library for reading/writing audio files
ii  libvorbis0a:amd64                    1.3.7-1build2                           amd64        decoder library for Vorbis General Audio Compression Codec
ii  libvorbisenc2:amd64                  1.3.7-1build2                           amd64        encoder library for Vorbis General Audio Compression Codec
ii  pulseaudio                           1:15.99.1+dfsg1-1ubuntu2.2              amd64        PulseAudio sound server
ii  pulseaudio-utils                     1:15.99.1+dfsg1-1ubuntu2.2              amd64        Command line tools for the PulseAudio sound server

```

**try1**

- v16.99.1

```bash
   8 cd /tmp/pulseaudio/
  10 ls -lh
  12 git checkout v16.99.1
  15 ./configure --without-caps
  16 make clean; make #无autoconf,make了;
  18 make clean
  19  autoreconf --force --install --verbose 2>&1
  
  #meson-deps
  apk add tdb tdb-dev check-dev doxygen
  meson build

/tmp/pulseaudio # meson  compile -C ./build
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function 'ogg_opus_write_out':
ogg_opus.c:(.text+0x2128): undefined reference to 'opus_multistream_encoder_ctl'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: ogg_opus.c:(.text+0x213c): undefined reference to 'opus_multistream_encode_float'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: ogg_opus.c:(.text+0x21d4): undefined reference to 'ogg_stream_flush_fill'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: ogg_opus.c:(.text+0x21e8): undefined reference to 'ogg_stream_pageout_fill'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: ogg_opus.c:(.text+0x222c): undefined reference to 'ogg_stream_packetin'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: ogg_opus.c:(.text+0x224c): undefined reference to 'opus_strerror'
collect2: error: ld returned 1 exit status
ninja: subcommand failed
```

- v15.99.1 (与v13.99.3同deps)

```bash
# 换 git checkout v15.99.1; 一样的错;
# ...

# try LIBS>> 无用;
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
export LIBS="$dep1" 
  52 rm -rf build;  meson build  --default-library=both
  53 meson  compile -C ./build

/tmp/pulseaudio # apk add libsndfile
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/aarch64/APKINDEX.tar.gz
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/aarch64/APKINDEX.tar.gz
(1/6) Installing libogg (1.3.5-r0)
(2/6) Installing flac (1.3.4-r0)
(3/6) Installing alsa-lib (1.2.5.1-r1)
(4/6) Installing opus (1.3.1-r1)
(5/6) Installing libvorbis (1.3.7-r0)
(6/6) Installing libsndfile (1.0.31-r1)


  55 apk add libsndfile
  57 meson  compile -C ./build 2>&1 |grep local
  58 mv /usr/local/lib/libsndfile.a /usr/local/lib/libsndfile.a00
  60 rm -rf build;  meson build  --default-library=both
  62 meson  compile -C ./build 2>&1 #找不到sndfile
# /usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: cannot find -lsndfile
# collect2: error: ld returned 1 exit status
# ninja: subcommand failed

# invalid choice: 'dynamic' (choose from 'shared', 'static', 'both')
  65 rm -rf build;  meson build  --default-library=shared
  66 meson  compile -C ./build 2>&1 
# /usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: cannot find -lsndfile
# collect2: error: ld returned 1 exit status
# ninja: subcommand failed
/tmp/pulseaudio # find /usr/lib |grep sndfile
/usr/lib/libsndfile.so.1
/usr/lib/libsndfile.so.1.0.31


# 软链 /usr/lib/libsndfile.so; >> 下1错(libintl)
/tmp/pulseaudio # #ln -s /usr/lib/libsndfile.so.1 /usr/lib/libsndfile.so
/tmp/pulseaudio # meson  compile -C ./build 2>&1
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: src/libpulsecommon-15.99.so.p/pulsecore_log.c.o: in function `pa_log_set_target':
/tmp/pulseaudio/build/../src/pulsecore/log.c:165: undefined reference to `libintl_dgettext'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: /tmp/pulseaudio/build/../src/pulsecore/log.c:188: undefined reference to `libintl_dgettext'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: src/libpulsecommon-15.99.so.p/pulsecore_log.c.o: in function `pa_log_parse_target':
/tmp/pulseaudio/build/../src/pulsecore/log.c:651: undefined reference to `libintl_dgettext'
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: src/libpulsecommon-15.99.so.p/pulse_client-conf-x11.c.o:/tmp/pulseaudio/build/../src/pulse/client-conf-x11.c:61: more undefined references to `libintl_dgettext' follow
collect2: error: ld returned 1 exit status
ninja: subcommand failed


##libintl错误############
# ubt2204
root@bf8a8d987d20:/etc/apt/apt.conf.d# dpkg -l |egrep "intl" #无包
root@bf8a8d987d20:/etc/apt/apt.conf.d# 

# alpine315 (已装; 版本不匹配??)
/tmp/pulseaudio # apk add libintl
OK: 1011 MiB in 328 packages   ##已装;
/tmp/pulseaudio # apk add libintl2
ERROR: unable to select packages:
  libintl2 (no such package):
    required by: world[libintl2]

/tmp/pulseaudio # find /usr/lib |grep intl
/usr/lib/libintl.so
/usr/lib/libintl.so.8
/usr/lib/libintl.so.8.2.0
/usr/lib/libintl.a
# ref pulse03.md(args)  >>   # 10.1M> 9.4M; deps:少了libintl

# https://gitee.com/g-system/fk-pulseaudio/blob/br-v13-99-3/sam-build.sh
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

  # -D= \; #
  # -D=disabled \
  # 1.ERROR: Option 'disable-systemd-journal' must have a value separated by equals sign.
  # 2.ERROR: Value disabled is not boolean (true or false).
  # 3.WARNING: Unknown options: "enable-static-bins, systemd-journal, with-database"


# --disable-shared --enable-static
#       --disable-alsa \
#       --disable-nls \
#       --disable-x11 \
#       --disable-tests \
#       --disable-esound \
#       --disable-waveout \
#       --disable-gconf \
#       --disable-glib2 \
# WARNING: Unknown options: "default-build-tests, enable-static-bins, esound, gconf, glib2, gtk3, manpages, nls, systemd-daemon, systemd-journal, systemd-login, waveout, with-database, without-caps, without-fftw, without-soxr, without-speex"
meson configure build/ \
  -Dalsa=disabled \
  -Dnls=disabled \
  -Dx11=disabled \
  -Dtests=false \
  -Desound=disabled \
  -Dwaveout=disabled \
  -Dgconf=disabled \
  -Dglib2=disabled \
  -Dgtk3=disabled \
  -Djack=disabled \
  -Dasyncns=disabled \
  -Davahi=disabled \
  -Dopenssl=disabled \
  -Dtcpwrap=disabled \
  -Dlirc=disabled \
  -Ddbus=disabled \
  -Dudev=disabled \
  -Dbluez5=disabled \
  -Dhal-compat=false \
  -Dipv6=false \
  -Dwebrtc-aec=disabled \
  -Dsystemd-daemon=no \
  -Dsystemd-login=no \
  -Dsystemd-journal=no \
  -Dmanpages=disabled \
  -Ddefault-build-tests=disabled \
  -Dlegacy-database-entry-format=false \
  -Denable-static-bins=yes \
  -Dwithout-caps=disabled \
  -Dwithout-fftw=disabled \
  -Dwithout-speex=disabled \
  -Dwithout-soxr=disabled \
  -Dwith-database=simple 


# intl错误依旧
/tmp/pulseaudio # 
/tmp/pulseaudio # meson  compile -C ./build 2>&1
/tmp/pulseaudio/build/../src/pulsecore/log.c:651: undefined reference to 'libintl_dgettext'
collect2: error: ld returned 1 exit status
ninja: subcommand failed

# https://gitee.com/g-system/fk-pulseaudio/blob/v15.99.1/meson_options.txt
# https://github.com/KeithDHedger/LFSPkgBuilds/blob/4b96c51086eb01aeb49af0bdcae97a7c63e60836/LFSPkgBuildScripts/libs/pulseaudio/pulseaudio.LFSBuild#L12
# -Ddatabase=gdbm -Dbluez5=disabled -Ddoxygen=false
meson configure build/ \
  -Dalsa=disabled \
  -Dx11=disabled \
  -Dtests=false \
  -Ddatabase=simple -Dbluez5=disabled -Ddoxygen=false


/tmp/pulseaudio # meson  compile -C ./build 2>&1
Run-time dependency gtk+-3.0 found: NO (tried pkgconfig and cmake)
Library ltdl found: YES
../meson.build:657:4: ERROR: C shared or static library 'gdbm' not found
A full log can be found at /tmp/pulseaudio/build/meson-logs/meson-log.txt
ninja: job failed: /usr/bin/meson --internal regenerate /tmp/pulseaudio /tmp/pulseaudio/build --backend ninja
ninja: subcommand failed
# -Ddatabase=gdbm >> 改simple后，intl一样错;



# enabled|disabled ##https://github.com/buildroot/buildroot/blob/66ebbebdb4dc7bc56339e0a1f1cb8d2e8e30c2f2/package/pulseaudio/pulseaudio.mk#L50
# ref: meson_options.txt
  -Dsystem_user \
  -Dsystem_group \
  -Daccess_group \
  # Paths
  -Dpadsplibdir \
  -Dpulsedsp-location \
  -Dmodlibexecdir \
  -Dalsadatadir \
  -Dsystemduserunitdir \
  -Dudevrulesdir \
  -Dbashcompletiondir \
  -Dzshcompletiondir \

  # Optional features
  # Echo cancellation
meson configure build/ \
  -Ddaemon=true \
  -Dclient=true \
  -Ddoxygen=false \
  -Dgcov=false \
  -Dman=false \
  -Dtests=false \
  \
  -Ddatabase=simple \
  -Dlegacy-database-entry-format=false \
  -Dstream-restore-clear-old-devices=false \
  -Drunning-from-build-tree=false \
  -Datomic-arm-linux-helpers=false \
  -Datomic-arm-memory-barrier=false \
  \
  -Dalsa=disabled \
  -Dasyncns=disabled \
  -Davahi=disabled \
  -Dbluez5=disabled \
  -Dbluez5-gstreamer=disabled \
  -Dbluez5-native-headset=false \
  -Dbluez5-ofono-headset=false \
  -Ddbus=disabled \
  -Delogind=disabled \
  -Dfftw=disabled \
  -Dglib=disabled \
  -Dgsettings=disabled \
  -Dgstreamer=disabled \
  -Dgtk=disabled \
  -Dhal-compat=false \
  -Dipv6=false \
  -Djack=disabled \
  -Dlirc=disabled \
  -Dopenssl=disabled \
  -Dorc=disabled \
  -Doss-output=disabled \
  -Dsamplerate=disabled \
  -Dsoxr=disabled \
  -Dspeex=disabled \
  -Dsystemd=disabled \
  -Dtcpwrap=disabled \
  -Dudev=disabled \
  -Dvalgrind=disabled \
  -Dx11=disabled \
  -Denable-smoother-2=false \
  \
  -Dadrian-aec=true \
  -Dwebrtc-aec=disabled

/tmp/pulseaudio # meson  compile -C ./build 2>&1
../meson.build:1025:2: ERROR: Problem encountered: At least one echo canceller implementation must be available!
A full log can be found at /tmp/pulseaudio/build/meson-logs/meson-log.txt
ninja: job failed: /usr/bin/meson --internal regenerate /tmp/pulseaudio /tmp/pulseaudio/build --backend ninja
ninja: subcommand failed

/tmp/pulseaudio # meson  compile -C ./build 2>&1
../meson.build:720:2: ERROR: Dependency "webrtc-audio-processing" not found, tried pkgconfig and cmake

/tmp/pulseaudio # meson  compile -C ./build 2>&1
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: src/libpulsecommon-15.99.so.p/pulsecore_log.c.o: in function 'pa_log_parse_target':
/tmp/pulseaudio/build/../src/pulsecore/log.c:651: undefined reference to 'libintl_dgettext'
collect2: error: ld returned 1 exit status
ninja: subcommand failed

# libtool版本过低? (2.4.6>2.4; 满足)
# https://www.freedesktop.org/wiki/Software/PulseAudio/Download/ ##deps: libtool (>= 2.4)
/tmp/pulseaudio # apk list |grep intl
php7-intl-7.4.33-r1 aarch64 {php7} (PHP-3.01 BSD-3-Clause LGPL-2.0-or-later MIT Zend-2.0)
intltool-0.51.0-r4 aarch64 {intltool} (GPL-2.0) [installed]
libintl-0.21-r0 aarch64 {gettext} (LGPL-2.1-or-later) [installed]
php8-intl-8.0.25-r0 aarch64 {php8} (PHP-3.01 BSD-3-Clause LGPL-2.0-or-later MIT Zend-2.0)
intltool-doc-0.51.0-r4 aarch64 {intltool} (GPL-2.0)
musl-libintl-1.2.2-r9 aarch64 {musl} (MIT)
# libtool-2.4.6-r7
/tmp/pulseaudio # apk list |grep libtool
slibtool-0.5.34-r1 aarch64 {slibtool} (MIT)
libltdl-2.4.6-r7 aarch64 {libtool} (LGPL-2.0+) [installed]
libltdl-static-2.4.6-r7 aarch64 {libtool} (LGPL-2.0+)
libtool-doc-2.4.6-r7 aarch64 {libtool} (LGPL-2.0+)
libtool-2.4.6-r7 aarch64 {libtool} (LGPL-2.0+) [installed]

# baidu@ai: + -lintl
dep1="-lintl -logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
export LIBS="$dep1" 
  52 rm -rf build;  meson build  --default-library=both
  53 meson  compile -C ./build
```

## REF

```bash
# ref u-gtk
meson build  --default-library=both #both static shared
meson build  --default-library=shared

# ref x-tigervnc
meson . build
meson install --no-rebuild -C /tmp/xkb/build

# ref docs/pulseaudio.md
# https://github.com/slyfox1186/ffmpeg-build-script/blob/b0cd7deaa088cb2e665d43aae63ced5d59006649/build-ffmpeg#L2032
    download_git 'https://gitlab.freedesktop.org/pulseaudio/pulseaudio.git' "libpulse-${g_ver}.tar.gz"
    extracmds=('-D'{daemon,doxygen,ipv6,man,tests}'=false')
    execute meson setup build --prefix="${workspace}"  \
                              --buildtype=release      \
                              --default-library=static \
                              --strip                  \
                               "${extracmds[@]}"
    execute ninja "-j${cpu_threads}" -C build
    execute sudo ninja "-j${cpu_threads}" -C build install
    libpulse_fix_libs_fn
    build_done 'libpulse' "${g_ver}"

# ref docs/xfce/thunar-1618-1.md
  271  meson  configure -h
  272* meson configure build/ 
  273  meson configure build/ 2>&1
  274  meson configure build/ 2>&1 |grep test
  275  meson configure build/ -Dchecks=false -Dmodular_tests=disabled
```

- args help


```bash
/tmp/pulseaudio # 
/tmp/pulseaudio # meson  configure -h |wc
      101       386      6392
/tmp/pulseaudio # meson  configure -h

                       [--libdir LIBDIR] [--libexecdir LIBEXECDIR] [--localedir LOCALEDIR] [--localstatedir LOCALSTATEDIR] [--mandir MANDIR]
                       [--sbindir SBINDIR] [--sharedstatedir SHAREDSTATEDIR] [--sysconfdir SYSCONFDIR]
                       [--auto-features {enabled,disabled,auto}] [--backend {ninja,vs,vs2010,vs2012,vs2013,vs2015,vs2017,vs2019,xcode}]
                       [--buildtype {plain,debug,debugoptimized,release,minsize,custom}] [--debug] [--default-library {shared,static,both}]
                       [--errorlogs] [--install-umask INSTALL_UMASK] [--layout {mirror,flat}] [--optimization {0,g,1,2,3,s}] [--stdsplit]
                       [--strip] [--unity {on,off,subprojects}] [--unity-size UNITY_SIZE] [--warnlevel {0,1,2,3}] [--werror]
                       [--wrap-mode {default,nofallback,nodownload,forcefallback,nopromote}] [--force-fallback-for FORCE_FALLBACK_FOR]
                       [--pkg-config-path PKG_CONFIG_PATH] [--build.pkg-config-path BUILD.PKG_CONFIG_PATH]
                       [--cmake-prefix-path CMAKE_PREFIX_PATH] [--build.cmake-prefix-path BUILD.CMAKE_PREFIX_PATH] [-D option] [--clearcache]
                       [builddir]

positional arguments:
  builddir

optional arguments:
  -h, --help                                                           show this help message and exit
  --prefix PREFIX                                                      Installation prefix (default: /usr/local).
  --bindir BINDIR                                                      Executable directory (default: bin).
  --datadir DATADIR                                                    Data file directory (default: share).
  --includedir INCLUDEDIR                                              Header file directory (default: include).
  --infodir INFODIR                                                    Info page directory (default: share/info).
  --libdir LIBDIR                                                      Library directory (default: lib).
  --libexecdir LIBEXECDIR                                              Library executable directory (default: libexec).
  --localedir LOCALEDIR                                                Locale data directory (default: share/locale).
  --localstatedir LOCALSTATEDIR                                        Localstate data directory (default: var).
  --mandir MANDIR                                                      Manual page directory (default: share/man).
  --sbindir SBINDIR                                                    System executable directory (default: sbin).
  --sharedstatedir SHAREDSTATEDIR                                      Architecture-independent data directory (default: com).
  --sysconfdir SYSCONFDIR                                              Sysconf data directory (default: etc).
  --auto-features {enabled,disabled,auto}                              Override value of all 'auto' features (default: auto).
  --backend {ninja,vs,vs2010,vs2012,vs2013,vs2015,vs2017,vs2019,xcode}
                                                                       Backend to use (default: ninja).
  --buildtype {plain,debug,debugoptimized,release,minsize,custom}      Build type to use (default: debug).
  --debug                                                              Debug
  --default-library {shared,static,both}                               Default library type (default: shared).
  --errorlogs                                                          Whether to print the logs from failing tests
  --install-umask INSTALL_UMASK                                        Default umask to apply on permissions of installed files (default: 022).
  --layout {mirror,flat}                                               Build directory layout (default: mirror).
  --optimization {0,g,1,2,3,s}                                         Optimization level (default: 0).
  --stdsplit                                                           Split stdout and stderr in test logs
  --strip                                                              Strip targets on install
  --unity {on,off,subprojects}                                         Unity build (default: off).
  --unity-size UNITY_SIZE                                              Unity block size (default: (2, None, 4)).
  --warnlevel {0,1,2,3}                                                Compiler warning level to use (default: 1).
  --werror                                                             Treat warnings as errors
  --wrap-mode {default,nofallback,nodownload,forcefallback,nopromote}  Wrap mode (default: default).
  --force-fallback-for FORCE_FALLBACK_FOR                              Force fallback for those subprojects (default: []).
  --pkg-config-path PKG_CONFIG_PATH                                    List of additional paths for pkg-config to search (default: []). (just
                                                                       for host machine)
  --build.pkg-config-path BUILD.PKG_CONFIG_PATH                        List of additional paths for pkg-config to search (default: []). (just
                                                                       for build machine)
  --cmake-prefix-path CMAKE_PREFIX_PATH                                List of additional prefixes for cmake to search (default: []). (just for
                                                                       host machine)
  --build.cmake-prefix-path BUILD.CMAKE_PREFIX_PATH                    List of additional prefixes for cmake to search (default: []). (just for
                                                                       build machine)
  -D option                                                            Set the value of an option, can be used several times to set multiple
                                                                       options.
  --clearcache                                                         Clear cached state (e.g. found dependencies)


[root@arm-ky10-23-2 mnt2]# cat meson-build-help.txt |wc
    115     468    7368
[root@arm-ky10-23-2 ~]# cd /opt/mnt2/
[root@arm-ky10-23-2 mnt2]# ls
docker-x11base  meson-build-help.txt
[root@arm-ky10-23-2 mnt2]# cat meson-build-help.txt 
usage: meson setup [-h] [--prefix PREFIX] [--bindir BINDIR] [--datadir DATADIR]
                   [--includedir INCLUDEDIR] [--infodir INFODIR]
                   [--libdir LIBDIR] [--libexecdir LIBEXECDIR]
                   [--localedir LOCALEDIR] [--localstatedir LOCALSTATEDIR]
                   [--mandir MANDIR] [--sbindir SBINDIR]
                   [--sharedstatedir SHAREDSTATEDIR] [--sysconfdir SYSCONFDIR]
                   [--auto-features {enabled,disabled,auto}]
                   [--backend {ninja,vs,vs2010,vs2012,vs2013,vs2015,vs2017,vs2019,xcode}]
                   [--buildtype {plain,debug,debugoptimized,release,minsize,custom}]
                   [--debug] [--default-library {shared,static,both}]
                   [--errorlogs] [--install-umask INSTALL_UMASK]
                   [--layout {mirror,flat}] [--optimization {0,g,1,2,3,s}]
                   [--stdsplit] [--strip] [--unity {on,off,subprojects}]
                   [--unity-size UNITY_SIZE] [--warnlevel {0,1,2,3}] [--werror]
                   [--wrap-mode {default,nofallback,nodownload,forcefallback,nopromote}]
                   [--force-fallback-for FORCE_FALLBACK_FOR]
                   [--pkg-config-path PKG_CONFIG_PATH]
                   [--build.pkg-config-path BUILD.PKG_CONFIG_PATH]
                   [--cmake-prefix-path CMAKE_PREFIX_PATH]
                   [--build.cmake-prefix-path BUILD.CMAKE_PREFIX_PATH]
                   [-D option] [--native-file NATIVE_FILE]
                   [--cross-file CROSS_FILE] [-v] [--fatal-meson-warnings]
                   [--reconfigure] [--wipe]
                   [builddir] [sourcedir]

positional arguments:
  builddir
  sourcedir

optional arguments:
  -h, --help                            show this help message and exit
  --prefix PREFIX                       Installation prefix (default:
                                        /usr/local).
  --bindir BINDIR                       Executable directory (default: bin).
  --datadir DATADIR                     Data file directory (default: share).
  --includedir INCLUDEDIR               Header file directory (default:
                                        include).
  --infodir INFODIR                     Info page directory (default:
                                        share/info).
  --libdir LIBDIR                       Library directory (default: lib).
  --libexecdir LIBEXECDIR               Library executable directory (default:
                                        libexec).
  --localedir LOCALEDIR                 Locale data directory (default:
                                        share/locale).
  --localstatedir LOCALSTATEDIR         Localstate data directory (default:
                                        var).
  --mandir MANDIR                       Manual page directory (default:
                                        share/man).
  --sbindir SBINDIR                     System executable directory (default:
                                        sbin).
  --sharedstatedir SHAREDSTATEDIR       Architecture-independent data directory
                                        (default: com).
  --sysconfdir SYSCONFDIR               Sysconf data directory (default: etc).
  --auto-features {enabled,disabled,auto}
                                        Override value of all 'auto' features
                                        (default: auto).
  --backend {ninja,vs,vs2010,vs2012,vs2013,vs2015,vs2017,vs2019,xcode}
                                        Backend to use (default: ninja).
  --buildtype {plain,debug,debugoptimized,release,minsize,custom}
                                        Build type to use (default: debug).
  --debug                               Debug
  --default-library {shared,static,both}
                                        Default library type (default: shared).
  --errorlogs                           Whether to print the logs from failing
                                        tests
  --install-umask INSTALL_UMASK         Default umask to apply on permissions of
                                        installed files (default: 022).
  --layout {mirror,flat}                Build directory layout (default:
                                        mirror).
  --optimization {0,g,1,2,3,s}          Optimization level (default: 0).
  --stdsplit                            Split stdout and stderr in test logs
  --strip                               Strip targets on install
  --unity {on,off,subprojects}          Unity build (default: off).
  --unity-size UNITY_SIZE               Unity block size (default: (2, None,
                                        4)).
  --warnlevel {0,1,2,3}                 Compiler warning level to use (default:
                                        1).
  --werror                              Treat warnings as errors
  --wrap-mode {default,nofallback,nodownload,forcefallback,nopromote}
                                        Wrap mode (default: default).
  --force-fallback-for FORCE_FALLBACK_FOR
                                        Force fallback for those subprojects
                                        (default: []).
  --pkg-config-path PKG_CONFIG_PATH     List of additional paths for pkg-config
                                        to search (default: []). (just for host
                                        machine)
  --build.pkg-config-path BUILD.PKG_CONFIG_PATH
                                        List of additional paths for pkg-config
                                        to search (default: []). (just for build
                                        machine)
  --cmake-prefix-path CMAKE_PREFIX_PATH
                                        List of additional prefixes for cmake to
                                        search (default: []). (just for host
                                        machine)
  --build.cmake-prefix-path BUILD.CMAKE_PREFIX_PATH
                                        List of additional prefixes for cmake to
                                        search (default: []). (just for build
                                        machine)
  -D option                             Set the value of an option, can be used
                                        several times to set multiple options.
  --native-file NATIVE_FILE             File containing overrides for native
                                        compilation environment.
  --cross-file CROSS_FILE               File describing cross compilation
                                        environment.
  -v, --version                         show program\'s version number and exit
  --fatal-meson-warnings                Make all Meson warnings fatal
  --reconfigure                         Set options and reconfigure the project.
                                        Useful when new options have been added
                                        to the project and the default value is
                                        not working.
  --wipe                                Wipe build directory and reconfigure
                                        using previous command line options.
                                        Useful when build directory got
                                        corrupted, or when rebuilding with a
                                        newer version of meson.
```
