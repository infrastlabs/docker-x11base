

## pulse-xrdp

ref: fk-pulseaudio//sam-custom.md

**就绪**

- module-native-protocol-unix/module-native-protocol-tcp; 加二层build-code开关,免重复
- 
- module-augment-properties
- module-always-sink
- module-x11-publish [ifexists]; autoconf:默认未带其静库

```bash
###验证
# 1）构建容器内: su sam; 启动pulseaudio; pactl info; OK;

# 2）手动到tenvm2-headless容器内: 停止原pulse; 起新; pactl info/pavucontrol可正常与新pulse同信;(pavucontol:无xrdp-sink/source输入输出 parec录音)
# headless @ tenvm2 in .../_misc2/fk-pulseaudio |10:19:49  |detached: ✓| 
$ pwd
/mnt/mnt/_misc2/fk-pulseaudio
$ ldd src/pulseaudio 
        # 不是动态可执行文件
$ ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/pulse.pa 2>&1 #|grep "=="
启动后

```

**TODO**

- /var/lib/xrdp-pulseaudio-installer/module-xrdp-[sink/source].so

**01: 原外部插件仓库build** (对应新src版本: v13.99.3)

```bash
# ref: docker-headless//ubt-core/src/Dockerfile.compile
RUN apt update && apt install -qy pulseaudio libpulse-dev \
  autoconf m4 intltool build-essential dpkg-dev
RUN apt update && apt build-dep -q -y pulseaudio && \
  cd /opt && apt source pulseaudio && \
  pulseaudio=$(pulseaudio --version | awk '{print $2}') && \
  cd /opt/pulseaudio-${pulseaudio} && ./configure
# RUN pulseaudio=$(pulseaudio --version); echo "pulseaudio: $pulseaudio"
# hand copy: /opt/pulseaudio-1.11/config.h +src/pulsecore
# https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
# https://gitee.com/g-system/pulseaudio-module-xrdp.git
RUN cd /opt && git clone --branch v0.5 https://gitee.com/g-system/pulseaudio-module-xrdp.git && \
  cd /opt/pulseaudio-module-xrdp ;\
  pulseaudio=$(pulseaudio --version | awk '{print $2}') && echo "pulseaudio ver: $pulseaudio" && \
  ./bootstrap && ./configure PULSE_DIR="/opt/pulseaudio-${pulseaudio}"; \
  cp -a /opt/pulseaudio-${pulseaudio}/config.h . && cp -a /opt/pulseaudio-${pulseaudio}/src/pulsecore/ .; \
  make && \
  cd /opt/pulseaudio-module-xrdp/src/.libs && \
  install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so;

# 
pulseaudio=v13.99.3
P=/mnt2/_misc2/fk-pulseaudio #/opt/pulseaudio-${pulseaudio}
./bootstrap && ./configure PULSE_DIR="$P"; 
cp -a $P/config.h . && cp -a $P/src/pulsecore/ .; 
make

# bash-5.1# make
make  all-recursive
make[1]: Entering directory '/mnt2/_misc2/pulseaudio-module-xrdp'
Making all in src
make[2]: Entering directory '/mnt2/_misc2/pulseaudio-module-xrdp/src'
  CC       module_xrdp_sink_la-module-xrdp-sink.lo
  CCLD     module-xrdp-sink.la
  CC       module_xrdp_source_la-module-xrdp-source.lo
  CCLD     module-xrdp-source.la
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio-module-xrdp/src'
make[2]: Entering directory '/mnt2/_misc2/pulseaudio-module-xrdp'
make[2]: Leaving directory '/mnt2/_misc2/pulseaudio-module-xrdp'
make[1]: Leaving directory '/mnt2/_misc2/pulseaudio-module-xrdp'
bash-5.1# pwd
/mnt2/_misc2/pulseaudio-module-xrdp
# bash-5.1# ls -lah src/.libs/
total 352K   
drwxr-xr-x    2 root     root        4.0K Mar  4 01:56 .
drwxr-xr-x    4 root     root        4.0K Mar  4 01:56 ..
lrwxrwxrwx    1 root     root          22 Mar  4 01:56 module-xrdp-sink.la -> ../module-xrdp-sink.la
-rw-r--r--    1 root     root         972 Mar  4 01:56 module-xrdp-sink.lai
-rwxr-xr-x    1 root     root       85.0K Mar  4 01:56 module-xrdp-sink.so ##
lrwxrwxrwx    1 root     root          24 Mar  4 01:56 module-xrdp-source.la -> ../module-xrdp-source.la
-rw-r--r--    1 root     root         984 Mar  4 01:56 module-xrdp-source.lai
-rwxr-xr-x    1 root     root       81.0K Mar  4 01:56 module-xrdp-source.so ##
-rw-r--r--    1 root     root       83.4K Mar  4 01:56 module_xrdp_sink_la-module-xrdp-sink.o
-rw-r--r--    1 root     root       79.1K Mar  4 01:56 module_xrdp_source_la-module-xrdp-source.o
```

**02:拷贝src代码sink/source x4** （尝试在同一pulse仓库; 关联静库 集成编译）

- ref build

```bash
# 1)build
bash-5.1# pwd
/mnt2/_misc2/fk-pulseaudio
bash-5.1# git pull; make LDFLAGS="--static -static"
# 2)validate
# headless @ tenvm2 in .../_misc2/fk-pulseaudio |10:19:49  |detached: ✓| 
$ pwd
/mnt/mnt/_misc2/fk-pulseaudio
$ ldd src/pulseaudio 
        # 不是动态可执行文件

# 3)build-cmd ref: top@pulse05.md
# dyn
  697  ./autogen.sh  --without-caps
  698  make clean
  699  make
  700  find |grep "\.so"
  701  make install
  702  pulseaudio #hand run ok;

# fk-pulseaudio>> static:
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
export CC=xx-clang
export CXX=xx-clang++

CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
# args="--disable-shared \ ##ref pulse03.md
bash-5.1# echo $args
--disable-shared --enable-static --disable-alsa --disable-nls --disable-x11 --disable-tests --disable-esound --disable-waveout --disable-gconf --disable-glib2 --disable-gtk3 --disable-jack --disable-asyncns --disable-avahi --disable-openssl --disable-tcpwrap --disable-lirc --disable-dbus --disable-udev --disable-bluez5 --disable-hal-compat --disable-ipv6 --disable-webrtc-aec --disable-systemd-daemon --disable-systemd-login --disable-systemd-journal --disable-manpages --disable-default-build-tests --disable-legacy-database-entry-format --enable-static-bins=yes --without-caps --without-fftw --without-speex --without-soxr --with-database=simple
# -lltdl 
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1"
```

- reBuild

```bash
# try1: 原build ok;  ##sed fix
# 不重configure: xrdp加在src/Makefile.am后，不会被make识别到?;
./autogen.sh  --without-caps
# clang-12: error: no such file or directory: '@LIBLTDL@' #直接autogen+内置./configure;
# 如上：LIBS="$dep1" ./configure --prefix=${CMAKE_BINARY_DIR} $args; 错误依旧

# ref pulse05.md
# vi
# - src/Makefile 3849/13198 29%
# 改后 make; 编译过了; LIBLTDL = 
sed -i "s/LIBLTDL = @LIBLTDL@/LIBLTDL =/g" ./src/Makefile


# try2: module-xrdp的生成;
bash-5.1# git pull; NOCONFIGURE=1 ./bootstrap.sh 2>&1 |grep error ##有错误;
bash-5.1# git pull; LIBS="$dep1" ./configure     --prefix=${CMAKE_BINARY_DIR}     $args ##conf
bash-5.1# cat ./src/Makefile  |grep xrdp
#空


bash-5.1# ll ./configure*
-rwxr-xr-x    1 root     root       1016718 Mar  4 12:36 ./configure ##./bootstrap.sh err仍可生成?
-rw-r--r--    1 root     root         68382 Jan 29 06:23 ./configure.ac
-rwxr-xr-x    1 root     root       1016728 Mar  4 12:32 ./configure~
bash-5.1# date
Mon Mar  4 12:39:12 UTC 2024


# try3
# bash-5.1# git pull; NOCONFIGURE=1 ./bootstrap.sh 2>&1 |grep error
src/Makefile.am:171: error: pulseaudio_SOURCES must be set with '=' before using '+='
src/Makefile.am:1066: error: libpulsecore_@PA_MAJORMINOR@_la_SOURCES must be set with '=' before using '+='
src/Makefile.am:1073: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1079: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1087: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1093: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1099: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1103: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1109: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1115: error: cannot apply '+=' because 'libpulsecore_@PA_MAJORMINOR@_la_SOURCES' is not defined in
src/Makefile.am:1300: error: 'module-xrdp-sink.la' is not a standard libtool library name
src/Makefile.am:1300: error: 'module-xrdp-source.la' is not a standard libtool library name
autoreconf: error: automake failed with exit status: 1

```




