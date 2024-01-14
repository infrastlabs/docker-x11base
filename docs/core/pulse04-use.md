
- use-run

```bash
bash-5.1# ls /usr/local/static/pulseaudio/var/lib/pulse
bash-5.1# chown pulse:pulse /usr/local/static/pulseaudio -R
# bash-5.1# ./src/pulseaudio --system --disallow-exit --disallow-module-loading
N: [pulseaudio] daemon-conf.c: Detected that we are run from the build tree, fixing search path.
N: [pulseaudio] main.c: Running in system mode, forcibly disabling SHM mode.
N: [pulseaudio] main.c: Running in system mode, forcibly disabling exit idle time.
W: [pulseaudio] main.c: Home directory of user 'pulse' is not '/usr/local/static/pulseaudio/var/run/pulse', ignoring.
W: [pulseaudio] caps.c: Normally all extra capabilities would be dropped now, but that\'s impossible because PulseAudio was built without capabilities support.
W: [pulseaudio] main.c: OK, so you are running PA in system mode. Please make sure that you actually do want to do that.
W: [pulseaudio] main.c: Please read http://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/WhatIsWrongWithSystemWide/ for an explanation why system mode is usually a bad idea.
E: [pulseaudio] main.c: Daemon startup without any loaded modules, refusing to work.
bash-5.1# history |tail -20
  578  make LDFLAGS=" $dep1"
  579  echo $?
  580  ls
  581  ls src/
  582  ls src/ -lh
  583  ldd src/pulseaudio 
  584  ldd src/pulseaudio |sort
  585  ./src/pulseaudio 
  586  ./src/pulseaudio --system
  587  ./src/pulseaudio --system --disallow-exit --disallow-module-loading
  588  adduser -m pulse
  589  adduser  pulse
  590  ./src/pulseaudio --system --disallow-exit --disallow-module-loading
  591  mkdir -p /usr/local/static/pulseaudio/var/lib/pulse
  592  ./src/pulseaudio --system --disallow-exit --disallow-module-loading
  593  ll /usr/local/static/pulseaudio/var/lib/pulse
  594  ls /usr/local/static/pulseaudio/var/lib/pulse
  595  chown pulse:pulse /usr/local/static/pulseaudio -R
  596  ./src/pulseaudio --system --disallow-exit --disallow-module-loading
  597  history |tail -20


# bash-5.1# ./pulseaudio --system  -n -F /usr/local/static/pulseaudio/etc/pulse/default.pa 
N: [pulseaudio] daemon-conf.c: Detected that we are run from the build tree, fixing search path.
W: [pulseaudio] main.c: Running in system mode, but --disallow-exit not set.
W: [pulseaudio] main.c: Running in system mode, but --disallow-module-loading not set.
N: [pulseaudio] main.c: Running in system mode, forcibly disabling SHM mode.
N: [pulseaudio] main.c: Running in system mode, forcibly disabling exit idle time.
W: [pulseaudio] main.c: Home directory of user 'pulse' is not '/usr/local/static/pulseaudio/var/run/pulse', ignoring.
W: [pulseaudio] caps.c: Normally all extra capabilities would be dropped now, but that\'s impossible because PulseAudio was built without capabilities support.
W: [pulseaudio] main.c: OK, so you are running PA in system mode. Please make sure that you actually do want to do that.
W: [pulseaudio] main.c: Please read http://www.freedesktop.org/wiki/Software/PulseAudio/Documentation/User/WhatIsWrongWithSystemWide/ for an explanation why system mode is usually a bad idea.
W: [pulseaudio] pid.c: Stale PID file, overwriting.
Segmentation fault (core dumped)
```

## reset build

```bash
  697  ./autogen.sh  --without-caps
  698  make clean
  699  make
  700  find |grep "\.so"
  701  make install
  702  pulseaudio #hand run ok;

# docker-headless
pa=/etc/pulse/default.pa
pulseaudio --exit-idle-time=-1 -nF $pa

.fail
    # Accept clients -- very important
    load-module module-native-protocol-unix
    #static 4700: can only with one VNC_LIMIT.
    #load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1;192.168.0.0/24 auth-anonymous=1 port=4700
load-module module-augment-properties
load-module module-always-sink
load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-sink.so
load-module /var/lib/xrdp-pulseaudio-installer/module-xrdp-source.so



# 9cb4d46fe30d:~$ ll /usr/local/bin/pulseaudio -h
-rwxr-xr-x    1 root     root       74.0K Jan 28 03:45 /usr/local/bin/pulseaudio
9cb4d46fe30d:~$ ldd /usr/local/bin/pulseaudio  |sort
        /lib/ld-musl-x86_64.so.1 (0x7ff3c9b0f000)
        libFLAC.so.8 => /usr/lib/libFLAC.so.8 (0x7ff3c98dc000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7ff3c9b0f000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7ff3c998b000)
        libltdl.so.7 => /usr/lib/libltdl.so.7 (0x7ff3c9980000)
        libogg.so.0 => /usr/lib/libogg.so.0 (0x7ff3c97a0000)
        libopus.so.0 => /usr/lib/libopus.so.0 (0x7ff3c97aa000)
        libpulse.so.0 => /usr/local/lib/libpulse.so.0 (0x7ff3c9a0c000)
        libpulsecommon-13.99.so => /usr/local/lib/pulseaudio/libpulsecommon-13.99.so (0x7ff3c9998000)
        libpulsecore-13.99.so => /usr/local/lib/pulseaudio/libpulsecore-13.99.so (0x7ff3c9a5d000)
        libsndfile.so.1 => /usr/lib/libsndfile.so.1 (0x7ff3c9910000)
        libvorbis.so.0 => /usr/lib/libvorbis.so.0 (0x7ff3c98b4000)
        libvorbisenc.so.2 => /usr/lib/libvorbisenc.so.2 (0x7ff3c980a000)
```

- headless@ubt2004

```bash
root@tenvm2:~# docker run -it --rm infrastlabs/docker-headless bash
root@258f78ce4fad:/home/headless# cd /var/lib/xrdp-pulseaudio-installer/
root@258f78ce4fad:/var/lib/xrdp-pulseaudio-installer# ll
total 176
drwxr-xr-x 2 root root  4096 Nov 15  2022 ./
drwxr-xr-x 1 root root  4096 Nov 15  2022 ../
-rw-r--r-- 1 root root 84440 Nov 15  2022 module-xrdp-sink.so
-rw-r--r-- 1 root root 83408 Nov 15  2022 module-xrdp-source.so
root@258f78ce4fad:/var/lib/xrdp-pulseaudio-installer# ldd module-xrdp-sink.so 
	linux-vdso.so.1 (0x00007ffd356a4000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa10810c000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fa108310000)
root@258f78ce4fad:/var/lib/xrdp-pulseaudio-installer# ldd module-xrdp-source.so 
	linux-vdso.so.1 (0x00007ffc5b9df000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f39d6c2e000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f39d6e32000)


# root@258f78ce4fad:/usr# ls -lh bin/pulseaudio 
-rwxr-xr-x 1 root root 99K Nov 20  2021 bin/pulseaudio
# root@258f78ce4fad:/usr# ldd bin/pulseaudio  |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fe9c3618000)
	libFLAC.so.8 => /lib/x86_64-linux-gnu/libFLAC.so.8 (0x00007fe9c28e2000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007fe9c2e70000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007fe9c2d33000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007fe9c27b2000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007fe9c27aa000)
	libapparmor.so.1 => /lib/x86_64-linux-gnu/libapparmor.so.1 (0x00007fe9c2943000)
	libasyncns.so.0 => /lib/x86_64-linux-gnu/libasyncns.so.0 (0x00007fe9c2958000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007fe9c2755000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fe9c2fdd000)
	libcap.so.2 => /lib/x86_64-linux-gnu/libcap.so.2 (0x00007fe9c3353000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007fe9c335c000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fe9c3320000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007fe9c2e75000)
	libgomp.so.1 => /lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fe9c27b8000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007fe9c2920000)
	libltdl.so.7 => /lib/x86_64-linux-gnu/libltdl.so.7 (0x00007fe9c33af000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007fe9c2f93000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fe9c2fb4000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fe9c31d1000)
	libnsl.so.1 => /lib/x86_64-linux-gnu/libnsl.so.1 (0x00007fe9c278b000)
	libogg.so.0 => /lib/x86_64-linux-gnu/libogg.so.0 (0x00007fe9c28d3000)
	liborc-0.4.so.0 => /lib/x86_64-linux-gnu/liborc-0.4.so.0 (0x00007fe9c2c30000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fe9c3330000)
	libpulse.so.0 => /lib/x86_64-linux-gnu/libpulse.so.0 (0x00007fe9c33ba000)
	libpulsecommon-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecommon-13.99.so (0x00007fe9c340f000)
	libpulsecore-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecore-13.99.so (0x00007fe9c3491000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fe9c276f000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fe9c3326000)
	libsndfile.so.1 => /lib/x86_64-linux-gnu/libsndfile.so.1 (0x00007fe9c2cb3000)
	libsoxr.so.0 => /lib/x86_64-linux-gnu/libsoxr.so.0 (0x00007fe9c2b96000)
	libspeexdsp.so.1 => /lib/x86_64-linux-gnu/libspeexdsp.so.1 (0x00007fe9c2c01000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007fe9c3544000)
	libtdb.so.1 => /lib/x86_64-linux-gnu/libtdb.so.1 (0x00007fe9c2c16000)
	libvorbis.so.0 => /lib/x86_64-linux-gnu/libvorbis.so.0 (0x00007fe9c28a5000)
	libvorbisenc.so.2 => /lib/x86_64-linux-gnu/libvorbisenc.so.2 (0x00007fe9c27fa000)
	libwrap.so.0 => /lib/x86_64-linux-gnu/libwrap.so.0 (0x00007fe9c2b5e000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007fe9c2b6c000)
	linux-vdso.so.1 (0x00007ffc07ddb000)

### pulse-13.99.1/modules
# root@258f78ce4fad:/usr# ldd ./lib/pulse-13.99.1/modules/module-x11-publish.so |sort
	/lib64/ld-linux-x86-64.so.2 (0x00007fbe2a3fc000)
	libFLAC.so.8 => /lib/x86_64-linux-gnu/libFLAC.so.8 (0x00007fbe29837000)
	libX11-xcb.so.1 => /lib/x86_64-linux-gnu/libX11-xcb.so.1 (0x00007fbe2a047000)
	libX11.so.6 => /lib/x86_64-linux-gnu/libX11.so.6 (0x00007fbe29f0a000)
	libXau.so.6 => /lib/x86_64-linux-gnu/libXau.so.6 (0x00007fbe2987d000)
	libXdmcp.so.6 => /lib/x86_64-linux-gnu/libXdmcp.so.6 (0x00007fbe29875000)
	libapparmor.so.1 => /lib/x86_64-linux-gnu/libapparmor.so.1 (0x00007fbe29895000)
	libasyncns.so.0 => /lib/x86_64-linux-gnu/libasyncns.so.0 (0x00007fbe298aa000)
	libbsd.so.0 => /lib/x86_64-linux-gnu/libbsd.so.0 (0x00007fbe29550000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fbe2a04c000)
	libdbus-1.so.3 => /lib/x86_64-linux-gnu/libdbus-1.so.3 (0x00007fbe29d56000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007fbe29885000)
	libgcrypt.so.20 => /lib/x86_64-linux-gnu/libgcrypt.so.20 (0x00007fbe295a5000)
	libgomp.so.1 => /lib/x86_64-linux-gnu/libgomp.so.1 (0x00007fbe2970d000)
	libgpg-error.so.0 => /lib/x86_64-linux-gnu/libgpg-error.so.0 (0x00007fbe2952d000)
	libltdl.so.7 => /lib/x86_64-linux-gnu/libltdl.so.7 (0x00007fbe29eff000)
	liblz4.so.1 => /lib/x86_64-linux-gnu/liblz4.so.1 (0x00007fbe296c3000)
	liblzma.so.5 => /lib/x86_64-linux-gnu/liblzma.so.5 (0x00007fbe296e4000)
	libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fbe29b6d000)
	libnsl.so.1 => /lib/x86_64-linux-gnu/libnsl.so.1 (0x00007fbe29588000)
	libogg.so.0 => /lib/x86_64-linux-gnu/libogg.so.0 (0x00007fbe2982a000)
	liborc-0.4.so.0 => /lib/x86_64-linux-gnu/liborc-0.4.so.0 (0x00007fbe29da7000)
	libprotocol-native.so => /usr/lib/pulse-13.99.1/modules/libprotocol-native.so (0x00007fbe2a296000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007fbe2a240000)
	libpulse.so.0 => /lib/x86_64-linux-gnu/libpulse.so.0 (0x00007fbe29e2c000)
	libpulsecommon-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecommon-13.99.so (0x00007fbe2a2bf000)
	libpulsecore-13.99.so => /usr/lib/x86_64-linux-gnu/pulseaudio/libpulsecore-13.99.so (0x00007fbe2a341000)
	libresolv.so.2 => /lib/x86_64-linux-gnu/libresolv.so.2 (0x00007fbe2956a000)
	librt.so.1 => /lib/x86_64-linux-gnu/librt.so.1 (0x00007fbe2988b000)
	libsndfile.so.1 => /lib/x86_64-linux-gnu/libsndfile.so.1 (0x00007fbe29e81000)
	libsoxr.so.0 => /lib/x86_64-linux-gnu/libsoxr.so.0 (0x00007fbe29cbc000)
	libspeexdsp.so.1 => /lib/x86_64-linux-gnu/libspeexdsp.so.1 (0x00007fbe29d27000)
	libsystemd.so.0 => /lib/x86_64-linux-gnu/libsystemd.so.0 (0x00007fbe29abc000)
	libtdb.so.1 => /lib/x86_64-linux-gnu/libtdb.so.1 (0x00007fbe29d3c000)
	libvorbis.so.0 => /lib/x86_64-linux-gnu/libvorbis.so.0 (0x00007fbe297fc000)
	libvorbisenc.so.2 => /lib/x86_64-linux-gnu/libvorbisenc.so.2 (0x00007fbe29751000)
	libwrap.so.0 => /lib/x86_64-linux-gnu/libwrap.so.0 (0x00007fbe29ab0000)
	libxcb.so.1 => /lib/x86_64-linux-gnu/libxcb.so.1 (0x00007fbe2a263000)
	linux-vdso.so.1 (0x00007fffedb76000)
root@258f78ce4fad:/usr# ldd ./lib/pulse-13.99.1/modules/module-x11-publish.so |sort |wc
     39     152    2944
root@258f78ce4fad:/usr# ldd ./lib/pulse-13.99.1/modules/module-tunnel-sink.so |sort |wc
     38     148    2844
```

