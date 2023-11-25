
## gcc

```bash
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


# https://github.com/ReMon-MVEE/ReMon/blob/a29fc6320052a4acefcc8177c6cfaa07df2e61a5/eurosys2022-artifact/bootstrap.sh#L24
git clone --depth 1 -b v14.2 git://anongit.freedesktop.org/pulseaudio/pulseaudio pulseaudio
    cd ./pulseaudio/
    NOCONFIGURE=1 ./bootstrap.sh


# headless @ barge in ~ |21:00:02  
$ pulseaudio --version
pulseaudio 13.99.1


# master 10245 @23.11.25
# 16.99.1 10234
# 15.99.1 10030
# 14.99.2 9430
# 13.99.3 9452 @Oct 31, 2020

```

- **v13.99.3** ubt2004-13.99.1

```bash
# bash-5.1# ./autogen.sh
checking for sys/capability.h... no
configure: error: *** sys/capability.h not found.  Use --without-caps to disable capabilities support.
bash-5.1# ./autogen.sh  --without-caps


# 
   30  git clone --depth=1 https://ghps.cc/https://github.com/pulseaudio/pulseaudio
   31  ls
   32  git clone  https://gitlab.freedesktop.org/pulseaudio/pulseaudio
   33  cd pulseaudio/
   34  meson build
   # 
   42  git checkout v13.99.3
   44  ./autogen.sh 
   45  ./autogen.sh  --without-caps
   48  apk add libsndfile-dev 
   50  find /usr/lib |grep libsndf
   51  ./autogen.sh  --without-caps


./configure --without-caps
./configure --prefix=/usr/local/static/pulseaudio --without-caps


# make
bash-5.1# ldd src/pa
pacat        pacmd        pactl        padsp        pasuspender  
bash-5.1# ldd src/pulseaudio 
/lib/ld-musl-x86_64.so.1: src/pulseaudio: Not a valid dynamic program
bash-5.1# ls -lh src/pulseaudio 
-rwxr-xr-x    1 root     root        8.4K Nov 25 13:18 src/pulseaudio

# bash-5.1# ./src/pulseaudio  --version
N: [lt-pulseaudio] daemon-conf.c: Detected that we are run from the build tree, fixing search path.
pulseaudio 13.99.3

# make install
bash-5.1# du -sh /usr/local/static/pulseaudio/
14.3M   /usr/local/static/pulseaudio/
bash-5.1# find /usr/local/static/pulseaudio/ |wc
      159       159      9921

# bash-5.1# ls -lh bin/
total 656K   
-rwxr-xr-x    1 root     root        2.5K Nov 25 13:22 esdcompat
-rwxr-xr-x    1 root     root        2.0K Nov 25 13:22 pa-info
-rwxr-xr-x    1 root     root      123.5K Nov 25 13:22 pacat
-rwxr-xr-x    1 root     root       44.7K Nov 25 13:22 pacmd
-rwxr-xr-x    1 root     root      189.9K Nov 25 13:22 pactl
-rwxr-xr-x    1 root     root        2.2K Nov 25 13:22 padsp
lrwxrwxrwx    1 root     root           5 Nov 25 13:22 pamon -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:22 paplay -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:22 parec -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:22 parecord -> pacat
-rwxr-xr-x    1 root     root       39.3K Nov 25 13:22 pasuspender
-rwxr-xr-x    1 root     root      238.4K Nov 25 13:22 pulseaudio
# bash-5.1# ldd bin/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7fcb8cf02000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fcb8ccb8000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fcb8cf02000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fcb8cd67000)
        libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7fcb8cd5c000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fcb8cb7c000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fcb8cb86000)
        libpulse.so.0 => /usr/local/static/pulseaudio/lib/libpulse.so.0 (0x7fcb8cdee000)
        libpulsecommon-13.99.so => /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.so (0x7fcb8cd74000)
        libpulsecore-13.99.so => /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecore-13.99.so (0x7fcb8ce42000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fcb8ccec000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fcb8cc90000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fcb8cbe6000)


# mods
# headless @ barge in .../lib/xrdp-pulseaudio-installer |21:29:43  
$ pwd
/var/lib/xrdp-pulseaudio-installer
$ ls
module-xrdp-sink.so  module-xrdp-source.so
$ ldd module-xrdp-sink.so 
	linux-vdso.so.1 (0x00007ffefe1e7000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fcc237b1000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fcc239b7000)
```

## **clang build**


```bash

export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++

make clean
make

# 动态：一把过
# 静态：


# static
checking for lt_dladvise_init in -lltdl... no
configure: error: Unable to find libltdl version 2. Makes sure you have libtool 2.4 or later installed.
bash-5.1# ./configure --without-caps
# apk add libltdl-static

config.status: executing po-directories commands
config.status: creating po/POTFILES
config.status: creating po/Makefile
config.status: executing libtool commands

 ---{ pulseaudio 13.99.3 }---

    prefix:                        /usr/local
    sysconfdir:                    ${prefix}/etc
    localstatedir:                 ${prefix}/var
    modlibexecdir:                 ${exec_prefix}/lib/pulse-13.99/modules
    alsadatadir:                   ${datarootdir}/pulseaudio/alsa-mixer
    System Runtime Path:           /usr/local/var/run/pulse
    System State Path:             /usr/local/var/lib/pulse
    System Config Path:            /usr/local/var/lib/pulse
    Zsh completions directory:     ${datarootdir}/zsh/site-functions
    Bash completions directory:    ${datarootdir}/bash-completion/completions
    Compiler:                      xx-clang
    CFLAGS:                        -Os -fomit-frame-pointer -Wall -W -Wextra -pipe -Wno-long-long -Wno-overlength-strings -Wundef -Wformat=2 -Wsign-compare -Wformat-security -Wmissing-include-dirs -Wformat-nonliteral -Wold-style-definition -Wpointer-arith -Winit-self -Wdeclaration-after-statement -Wfloat-equal -Wmissing-prototypes -Wstrict-prototypes -Wredundant-decls -Wmissing-declarations -Wmissing-noreturn -Wshadow -Wendif-labels -Wcast-align -Wstrict-aliasing -Wwrite-strings -Wno-unused-parameter -fno-common -fdiagnostics-show-option -fdiagnostics-color=auto
    CPPFLAGS:                      -Os -fomit-frame-pointer -DFASTPATH -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2
    LIBS:                          

    Enable memfd shared memory:    yes
    Enable X11:                    no
    Enable OSS Output:             yes
    Enable OSS Wrapper:            yes
    Enable EsounD:                 yes
    Enable Alsa:                   no
    Enable CoreAudio:              no
    Enable Solaris:                no
    Enable WaveOut:                no
    Enable GLib 2.0:               yes
    Enable Gtk+ 3.0:               no
    Enable GConf:                  no
    Enable GSettings:              yes
    Enable Avahi:                  no
    Enable Jack:                   no
    Enable Async DNS:              no
    Enable LIRC:                   no
    Enable D-Bus:                  no
      Enable BlueZ 5:              no
        Enable ofono headsets:     no
        Enable native headsets:    no
    Enable udev:                   no
      Enable HAL->udev compat:     no
    Enable systemd
      Daemon (Socket Activation):  no
      Login (Session Tracking):    no
      Journal (Logging):           no
    Enable TCP Wrappers:           no
    Enable libsamplerate:          no
    Enable IPv6:                   yes
    Enable OpenSSL (for Airtunes): no
    Enable fftw:                   no
    Enable orc:                    no
    Enable Adrian echo canceller:  yes
    Enable speex (resampler, AEC): no
    Enable soxr (resampler):       no
    Enable WebRTC echo canceller:  no
    Enable GStreamer-based RTP:    no
    Enable gcov coverage:          no
    Enable unit tests:             no
    Database
      tdb:                         no
      gdbm:                        no
      simple database:             yes

    System User:                   pulse
    System Group:                  pulse
    Access Group:                  pulse-access
    Enable per-user EsounD socket: yes
    Force preopen:                 no
    Preopened modules:             all

    Legacy Database Entry Support: yes
    module-stream-restore:
      Clear old devices:           no

# 直接make OK;
bash-5.1# make
bash-5.1# echo $?
0
bash-5.1# ls -lh src/pulseaudio 
-rwxr-xr-x    1 root     root       10.1M Nov 25 13:46 src/pulseaudio


# make install
./configure --prefix=/usr/local/static/pulseaudio --without-caps
make
make install

# bash-5.1# make install
BEGIN failed--compilation aborted at ./xmltoman line 20.
 .././build-aux/install-sh -c -d '/usr/local/static/pulseaudio/share/man/man1'
 /usr/bin/install -c -m 644 ./pulseaudio.1 ./pax11publish.1 ./pacat.1 ./pacmd.1 ./pactl.1 ./pasuspender.1 ./padsp.1 ./start-pulseaudio-x11.1 ./esdcompat.1 '/usr/local/static/pulseaudio/share/man/man1'
install: can\'t stat './pulseaudio.1': No such file or directory
install: can\'t stat './pax11publish.1': No such file or directory
install: can\'t stat './pacat.1': No such file or directory
install: can\'t stat './pacmd.1': No such file or directory
install: can\'t stat './pactl.1': No such file or directory
install: can\'t stat './pasuspender.1': No such file or directory
install: can\'t stat './padsp.1': No such file or directory
install: can\'t stat './start-pulseaudio-x11.1': No such file or directory
install: can\'t stat './esdcompat.1': No such file or directory
make[3]: *** [Makefile:591: install-man1] Error 1
make[3]: Leaving directory '/mnt2/pulseaudio/man'
make[2]: *** [Makefile:727: install-am] Error 2
make[2]: Leaving directory '/mnt2/pulseaudio/man'
make[1]: *** [Makefile:834: install-recursive] Error 1
make[1]: Leaving directory '/mnt2/pulseaudio'
make: *** [Makefile:1141: install] Error 2
```

- view LDFALGS="-static ..">> 非静编

```bash
# bash-5.1# du -sh /usr/local/static/pulseaudio*
18.2M   /usr/local/static/pulseaudio
14.3M   /usr/local/static/pulseaudio01
# bash-5.1# ls -lh /usr/local/static/pulseaudio/bin/
total 12M    
-rwxr-xr-x    1 root     root        2.5K Nov 25 13:54 esdcompat
-rwxr-xr-x    1 root     root        2.0K Nov 25 13:54 pa-info
-rwxr-xr-x    1 root     root      514.1K Nov 25 13:54 pacat
-rwxr-xr-x    1 root     root      485.9K Nov 25 13:54 pacmd
-rwxr-xr-x    1 root     root      582.1K Nov 25 13:54 pactl
-rwxr-xr-x    1 root     root        2.2K Nov 25 13:54 padsp
lrwxrwxrwx    1 root     root           5 Nov 25 13:54 pamon -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:54 paplay -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:54 parec -> pacat
lrwxrwxrwx    1 root     root           5 Nov 25 13:54 parecord -> pacat
-rwxr-xr-x    1 root     root      533.9K Nov 25 13:54 pasuspender
-rwxr-xr-x    1 root     root       10.1M Nov 25 13:54 pulseaudio

# bash-5.1# ldd /usr/local/static/pulseaudio/bin/pactl 
        /lib/ld-musl-x86_64.so.1 (0x7fde71d9a000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fde71cfa000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fde71c8a000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fde71d9a000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fde71c56000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fde71c2e000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fde71b84000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fde71b24000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fde71b1a000)
# bash-5.1# ldd /usr/local/static/pulseaudio/bin/pulseaudio 
        /lib/ld-musl-x86_64.so.1 (0x7fc6849f8000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7fc683fc7000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7fc683f57000)
        libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7fc683f4c000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7fc6849f8000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7fc683f18000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7fc683ef0000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7fc683e46000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7fc683de6000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7fc683ddc000)

# lib
/usr/local/static/pulseaudio/lib
/usr/local/static/pulseaudio/lib/libpulse-mainloop-glib.a
/usr/local/static/pulseaudio/lib/libpulse.la
/usr/local/static/pulseaudio/lib/libpulse-mainloop-glib.la
/usr/local/static/pulseaudio/lib/libpulse-simple.la
/usr/local/static/pulseaudio/lib/pulseaudio
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.la
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecore-13.99.la
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecore-13.99.a
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.a
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsedsp.a
/usr/local/static/pulseaudio/lib/pulseaudio/libpulsedsp.la
/usr/local/static/pulseaudio/lib/libpulse-simple.a
/usr/local/static/pulseaudio/lib/libpulse.a
/usr/local/static/pulseaudio/lib/pulse-13.99
/usr/local/static/pulseaudio/lib/pulse-13.99/modules
/usr/local/static/pulseaudio/lib/pulse-13.99/modules/module-tunnel-sink-new.a
/usr/local/static/pulseaudio/lib/pulse-13.99/modules/module-default-device-restore.a
```

- **try02** ref OpenELEC `PKG_CONFIGURE_OPTS_TARGET`

```bash
# args
# bash-5.1# ./configure -h
# https://github.com/OpenELEC/OpenELEC.tv/blob/1465181e999753dde395ff5d4d67edf3d8a72fb2/packages/audio/pulseaudio/package.mk#L76
# package specific configure options
# enable> --disable-alsa \
# --with-soxr \
# 
# --enable_static_bins=yes \>> enable-static-bins
PKG_CONFIGURE_OPTS_TARGET="--disable-silent-rules \
    --disable-nls \
    --disable-largefile \
    --disable-rpath \
    $PULSEAUDIO_NEON \
    --disable-x11 \
    --disable-tests \
    --disable-samplerate \
    --disable-oss-output \
    --disable-oss-wrapper \
    --disable-coreaudio-output \
    --disable-alsa \
    --disable-esound \
    --disable-solaris \
    --disable-waveout \
    --disable-glib2 \
    --disable-gtk3 \
    --disable-gconf \
    $PULSEAUDIO_AVAHI \
    --disable-jack \
    --disable-asyncns \
    --disable-tcpwrap \
    --disable-lirc \
    --disable-dbus \
    --disable-bluez4 \
    $PULSEAUDIO_BLUETOOTH \
    --disable-bluez5-ofono-headset \
    --disable-bluez5-native-headset \
    --disable-udev \
    --with-udev-rules-dir=/usr/lib/udev/rules.d
    --disable-hal-compat \
    --disable-ipv6 \
    --disable-openssl \
    --disable-xen \
    --disable-orc \
    --disable-manpages \
    --disable-per-user-esound-socket \
    --disable-default-build-tests \
    --disable-legacy-database-entry-format \
    --with-system-user=root \
    --with-system-group=root \
    --with-access-group=root \
    --without-caps \
    --without-fftw \
    --without-speex \
    --enable-static-bins \
    --with-module-dir=/usr/lib/pulse"

./configure --prefix=/usr/local/static/pulseaudio --without-caps $PKG_CONFIGURE_OPTS_TARGET


# bash-5.1# 
bash-5.1# make LDFLAGS="-static --static -lltdl"
bs/module-gsettings.a /mnt2/pulseaudio/src/.libs/libpulsecore-13.99.a ./.libs/libpulsecore-13.99.a /mnt2/pulseaudio/src/.libs/libpulse.a ./.libs/libpulsecommon-13.99.a ./.libs/libpulse.a /mnt2/pulseaudio/src/.libs/libpulsecommon-13.99.a -lsndfile /usr/lib/libltdl.so
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3448): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3438): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3458): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3428): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3648): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3638): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object '/usr/lib/libltdl.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
libtool: link: rm -f ".libs/pulseaudioS.o"
make[3]: *** [Makefile:7276: pulseaudio] Error 1
make[3]: Leaving directory '/mnt2/pulseaudio/src'
make[2]: *** [Makefile:5397: all] Error 2
make[2]: Leaving directory '/mnt2/pulseaudio/src'
make[1]: *** [Makefile:834: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/pulseaudio'
make: *** [Makefile:649: all] Error 2

# libltdl.so链接指向libltdl.a库
  484  pwd
  485  find |grep Makefile.am
  486  make LDFLAGS="-static --static -lltdl"
  487  ls -lh /usr/lib |grep libltd
  488  cd /usr/lib
  489  mv libltdl.so.7.3.1 libltdl.so.7.3.1-drop1
  490  cd -
  491  make LDFLAGS="-static --static -lltdl"
  492  cd -
  493  ls
  494  ll |grep libltd
  495  ls -lh |grep libltd
  496  ln -s libltdl.a libltdl.so.7.3.1
  497  ls -lh |grep libltd

# nextErr: ogg|opus|FLAC相关库找不到;
  498  cd -
  499  make LDFLAGS="-static --static -lltdl"
  500  find /usr/lib |egrep "ogg|opus"
  501  make LDFLAGS="-static --static -lltdl -logg -lopus"
  502  find /usr/lib |egrep "sndfile|intl"
  503  find /usr/lib |egrep "vorbis|FLAC"
  504  #find /usr/lib |egrep "sndfile|intl"
  505  make LDFLAGS="-static --static -lltdl -logg -lopus -lsndfile -lintl"
```

- configure.ac>> enable_static_bins

```bash
# configure.ac>> enable_static_bins
bash-5.1# ./configure -h |grep static
  --enable-static[=PKGS]  build static libraries [default=no]
  --enable-static-bins    Statically link executables.


# ./configure 添加--enable-static-bins,再编译：
#  一样Err: ogg|opus|FLAC相关库找不到;
```