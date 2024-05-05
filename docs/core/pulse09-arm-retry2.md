

**arm64-23.2**

```bash
[root@arm-ky10-23-2 mnt]# docker run -it --rm -v /opt/mnt2:/mnt2 --privileged infrastlabs/x11-base:alpine-builder-gtk224 sh
# tmux1 @23.2
[root@arm-ky10-23-2 ~]# docker ps |grep gtk
d4e43ea58981        infrastlabs/x11-base:alpine-builder-gtk224                 "sh"                     6 weeks ago         Up 6 weeks           eager_shaw


# ref fk-pulseaudio//sam-build.sh
/tmp/pulseaudio # ./configure --without-caps
    ...
    Enable gcov coverage:          no
    Enable unit tests:             yes
    Database
      tdb:  yes
      gdbm: no
      simple database:             no

    System User:                   pulse
    System Group:                  pulse
    Access Group:                  pulse-access
    Enable per-user EsounD socket: yes
    Force preopen:                 no
    Preopened modules:             all

    Legacy Database Entry Support: yes
    module-stream-restore:
      Clear old devices:           no


===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====
You do not have D-Bus support enabled. It is strongly recommended
that you enable D-Bus support if your platform supports it.
Many parts of PulseAudio use D-Bus, from ConsoleKit interaction
to the Device Reservation Protocol to speak to JACK, Bluetooth
support and even a native control protocol for communicating and
controlling the PulseAudio daemon itself.
===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====


===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====
You do not have udev support enabled. It is strongly recommended
that you enable udev support if your platform supports it as it is
the primary method used to detect hardware audio devices (on Linux)
and is thus a critical part of PulseAudio on that platform.
===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====


===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====
You do not have speex support enabled. It is strongly recommended
that you enable speex support if your platform supports it as it is
the primary method used for audio resampling and is thus a critical
part of PulseAudio on that platform.
===== WARNING WARNING WARNING WARNING WARNING WARNING WARNING =====




# dyn build: libsndfile.a 不能用于dyn-build使用;
/tmp/pulseaudio # make
./pulsecore/mem.h:52:20: warning: old-style function definition [-Wold-style-definition]
  CC       pulsecore/libpulsecommon_13.99_la-x11prop.lo
  CC       pulsecore/libpulsecommon_13.99_la-mutex-posix.lo
  CC       pulsecore/libpulsecommon_13.99_la-thread-posix.lo
  CC       pulsecore/libpulsecommon_13.99_la-semaphore-posix.lo
  CCLD     libpulsecommon-13.99.la
gcc: error: /usr/local/lib/libsndfile.a: No such file or directory
make[3]: *** [Makefile:5658: libpulsecommon-13.99.la] Error 1
make[3]: Leaving directory '/tmp/pulseaudio/src'
make[2]: *** [Makefile:4952: all] Error 2
make[2]: Leaving directory '/tmp/pulseaudio/src'
make[1]: *** [Makefile:833: all-recursive] Error 1
make[1]: Leaving directory '/tmp/pulseaudio'
make: *** [Makefile:648: all] Error 2



# make clean; make LDFLAGS="-static --static $dep122"

# fk-pulseaudio>> static:
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
# export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"
export LDFLAGS="-static -Wl,--strip-all -Wl,--as-needed"
export CC=xx-clang
export CXX=xx-clang++
test -z "$CMAKE_BINARY_DIR" && CMAKE_BINARY_DIR=/usr/local/static/pulseaudio



/tmp/pulseaudio # #make clean; make LDFLAGS="-static --static $dep122"
/tmp/pulseaudio # git remote -v
origin  https://gitee.com/g-system/fk-pulseaudio (fetch)
origin  https://gitee.com/g-system/fk-pulseaudio (push)
./pulsecore/mem.h:52:20: warning: old-style function definition [-Wold-style-definition]
  CCLD     module-mmkbd-evdev.la
ar: `u' modifier ignored since `D' is the default (see 'U')
  CCLD     pulseaudio
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3018): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3008): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3028): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2ff8): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3218): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3208): warning: Module auto-loading no longer supported.
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: cannot find -ltdb
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: cannot find -lICE
/usr/lib/gcc/aarch64-alpine-linux-musl/10.3.1/../../../../aarch64-alpine-linux-musl/bin/ld: cannot find -lXtst
collect2: error: ld returned 1 exit status
make[3]: *** [Makefile:6571: pulseaudio] Error 1
make[3]: Leaving directory '/tmp/pulseaudio/src'
make[2]: *** [Makefile:4952: all] Error 2
make[2]: Leaving directory '/tmp/pulseaudio/src'
make[1]: *** [Makefile:833: all-recursive] Error 1
make[1]: Leaving directory '/tmp/pulseaudio'
make: *** [Makefile:648: all] Error 2
/tmp/pulseaudio # 



# 因： args 未关闭 相关配置项
# find @arm64-img
    /tmp/pulseaudio # find /usr/lib /usr/local/lib |grep Xtst
    /usr/lib/libXtst.so
    /usr/lib/libXtst.so.6
    /usr/lib/libXtst.so.6.1.0

    /tmp/pulseaudio # find /usr/lib /usr/local/lib |grep libtdb
    /usr/lib/libtdb.so.1
    /usr/lib/libtdb.so.1.4.5
    /usr/lib/libtdb.so

    /tmp/pulseaudio # find /usr/lib /usr/local/lib |grep ICE
    /usr/lib/python2.7/LICENSE.txt
    /usr/lib/libICE.so
    /usr/lib/libICE.so.6
    /usr/lib/libICE.so.6.3.0

    find /usr/lib /usr/local/lib |egrep "Xtst|libtdb|ICE"


    /tmp/pulseaudio # apk list |egrep "xtst|tdb-|libice" |sort
    libice-1.0.10-r0 aarch64 {libice} (X11) [installed]
    libice-dev-1.0.10-r0 aarch64 {libice} (X11) [installed]
    libice-doc-1.0.10-r0 aarch64 {libice} (X11)
    libice-static-1.0.10-r0 aarch64 {libice} (X11) ##static
    libxtst-1.2.3-r3 aarch64 {libxtst} (custom) [installed]
    libxtst-dev-1.2.3-r3 aarch64 {libxtst} (custom) [installed]
    libxtst-doc-1.2.3-r3 aarch64 {libxtst} (custom)
    py3-tdb-1.4.5-r0 aarch64 {tdb} (LGPL-3.0-or-later)
    tdb-1.4.5-r0 aarch64 {tdb} (LGPL-3.0-or-later) [installed]
    tdb-dev-1.4.5-r0 aarch64 {tdb} (LGPL-3.0-or-later) [installed]
    tdb-doc-1.4.5-r0 aarch64 {tdb} (LGPL-3.0-or-later)
    tdb-libs-1.4.5-r0 aarch64 {tdb} (LGPL-3.0-or-later) [installed]

# find x64-img
    root@tenvm2:~# docker run -it --rm -v /mnt:/mnt2 --privileged infrastlabs/x11-base:alpine-builder-gtk224 sh
    / # 
    / # 
    / # find /usr/lib /usr/local/lib |egrep "Xtst|libtdb|ICE"
    /usr/lib/libICE.so
    /usr/lib/libICE.so.6.3.0
    /usr/lib/libICE.so.6
    /usr/lib/libXtst.so.6
    /usr/lib/libXtst.so
    /usr/lib/libXtst.so.6.1.0

    / # apk list |egrep "xtst|tdb-|libice" |sort
    libice-1.0.10-r0 x86_64 {libice} (X11) [installed]
    libice-dev-1.0.10-r0 x86_64 {libice} (X11) [installed]
    libice-doc-1.0.10-r0 x86_64 {libice} (X11)
    libice-static-1.0.10-r0 x86_64 {libice} (X11)  ##static
    libxtst-1.2.3-r3 x86_64 {libxtst} (custom) [installed]
    libxtst-dev-1.2.3-r3 x86_64 {libxtst} (custom) [installed]
    libxtst-doc-1.2.3-r3 x86_64 {libxtst} (custom)
    py3-tdb-1.4.5-r0 x86_64 {tdb} (LGPL-3.0-or-later)
    tdb-1.4.5-r0 x86_64 {tdb} (LGPL-3.0-or-later)
    tdb-dev-1.4.5-r0 x86_64 {tdb} (LGPL-3.0-or-later)
    tdb-doc-1.4.5-r0 x86_64 {tdb} (LGPL-3.0-or-later)
    tdb-libs-1.4.5-r0 x86_64 {tdb} (LGPL-3.0-or-later)

    / # apk add libxtst-static
    fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
    fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
    ERROR: unable to select packages:
    libxtst-static (no such package):
        required by: world[libxtst-static]
    / # apk add tdb-static
    ERROR: unable to select packages:
    tdb-static (no such package):
        required by: world[tdb-static]
```

**x64-tenvm2**


```bash
# configure: error: C compiler cannot create executables  ##deps 有未装成功的;
/mnt2/docker-x11base/compile/src # git pull; bash x-pulseaudio/build.sh pulseaudio
checking for gcc... xx-clang
checking whether the C compiler works... no
configure: error: in '/tmp/pulseaudio':
configure: error: C compiler cannot create executables  ##deps 有未装成功的;
See `config.log' for more details
cat: can't open './src/Makefile': No such file or directory
        0         0         0
sed: ./src/Makefile: No such file or directory
make: *** No rule to make target 'clean'.  Stop.
make: *** No targets specified and no makefile found.  Stop.


>>> Install PULSEAUDIO...
make: *** No rule to make target 'install'.  Stop.
ls: /tmp/pulseaudio/src/pa*: No such file or directory
file not found: /tmp/pulseaudio/src/pulseaudio
file not found: /tmp/pulseaudio/src/pactl
err 0, pass
本操作从2024年06月17日03:10:38 开始 , 到2024年06月17日03:11:13 结束,  共历时35秒
pulseaudio, finished.


```

**try CFLAGS>> --enable-neon-opt=no** OK

```bash
# sam-build.sh @fk-pulseaudio:
export CFLAGS="-Os -fomit-frame-pointer -march=armv7-a" ##armv7-a armv8-a
export CFLAGS="$CFLAGS -mfpu=neon" #开/注释
# 试了: armv7-a armv8-a, #开/注释都一样错;


# https://www.cnblogs.com/plummithly/p/4444924.html
1.　error: unknown register name 'q0' in asm  
　　: "memory", "q0", "q1", "q2", "q3", "q8", "q9", "q10", "q11", "q12", "q13", "q14"
      解决方法：把#if defined(__ARM_NEON__)   改为 #if defined(_ARM_ARCH_7)
# src: ARM_NEON @configure.ac >> neon代码开关:
#### NEON optimisations ####
AC_ARG_ENABLE([neon-opt],
    AS_HELP_STRING([--enable-neon-opt], [Enable NEON optimisations on ARM CPUs that support it]))
AS_IF([test "x$enable_neon_opt" != "xno"],
    [save_CFLAGS="$CFLAGS"; CFLAGS="-mfpu=neon $CFLAGS"
     AC_COMPILE_IFELSE(
        [AC_LANG_PROGRAM([[#include <arm_neon.h>]], [])],


# --enable-neon-opt=yes/no
/tmp/pulseaudio # ./configure -h  |grep neon
  --enable-neon-opt       Enable NEON optimisations on ARM CPUs that support


# --enable-neon-opt=no  @sam-build.sh >> 23.2-arm64编译通过;
static 
utils/padsp.c:2703:7: warning: no previous prototype for function 'fopen64' [-Wmissing-prototypes]
FILE *fopen64(const char *__restrict filename, const char *__restrict mode) {
      ^
utils/padsp.c:2703:1: note: declare 'static' if the function is not intended to be used outside of this translation unit
FILE *fopen64(const char *__restrict filename, const char *__restrict mode) {
^
static 
7 warnings generated.
  CCLD     libpulsedsp.la
ar: `u' modifier ignored since 'D' is the default (see `U')
/bin/sed -e 's|@PULSEDSP_LOCATION[@]|/usr/local/static/pulseaudio/lib/pulseaudio|g' utils/padsp.in > padsp
make[3]: Leaving directory '/tmp/pulseaudio/src'
make[2]: Leaving directory '/tmp/pulseaudio/src'
Making all in doxygen
make[2]: Entering directory '/tmp/pulseaudio/doxygen'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/tmp/pulseaudio/doxygen'
Making all in man
make[2]: Entering directory '/tmp/pulseaudio/man'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/tmp/pulseaudio/man'
Making all in po
make[2]: Entering directory '/tmp/pulseaudio/po'
make[2]: Nothing to be done for 'all'.
make[2]: Leaving directory '/tmp/pulseaudio/po'
make[2]: Entering directory '/tmp/pulseaudio'
make[2]: Nothing to be done for 'all-am'.
make[2]: Leaving directory '/tmp/pulseaudio'
make[1]: Leaving directory '/tmp/pulseaudio'
/tmp/pulseaudio # 
/tmp/pulseaudio # 
/tmp/pulseaudio # bash sam-build.sh 


# view
/tmp/pulseaudio # ls src/pulseaudio -lh
-rwxr-xr-x    1 root     root        6.1M Jun 17 06:19 src/pulseaudio
/tmp/pulseaudio # ldd src/pulseaudio 
/lib/ld-musl-aarch64.so.1: src/pulseaudio: Not a valid dynamic program

# testRun01: Segmentation fault
/tmp/pulseaudio # ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/pulse.pa 2>&1
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()] .nofail
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   load-module module-augment-properties
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:437 pa_cli_command_load()] module-augment-properties
(   0.001|   0.000) I: [pulseaudio][pulsecore/module.c:296 pa_module_load()] Loaded "module-augment-properties" (index: #1; argument: "").
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   load-module module-always-sink
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:437 pa_cli_command_load()] module-always-sink
(   0.001|   0.000) I: [pulseaudio][pulsecore/module.c:296 pa_module_load()] Loaded "module-always-sink" (index: #2; argument: "").
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   # Publish to X11 so the clients know how to connect to Pulse. Will clear itself on unload.
(   0.001|   0.000) I: [pulseaudio][pulsecore/cli-command.c:2183 pa_cli_command_execute_file_stream()]   .ifexists module-x11-publish.so
Segmentation fault


# test空跑: exited
/tmp/pulseaudio # ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -n 2>&1
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1135 main()] A036
(   0.001|   0.000) E: [pulseaudio][daemon/main.c:1137 main()] Daemon startup without any loaded modules, refusing to work.
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1218 main()] Daemon terminated.


# _t1/p2.pa: >> 正常运行
/tmp/pulseaudio # ./src/pulseaudio --log-meta=true --log-time=true --log-level=4  --exit-idle-time=-1 -nF ./_t1/p2.pa 2>&1
(  13.501|   0.059) D: [xrdp-sink][modules/module-xrdp-sink.c:359 process_render()] process_render: u->block_usec 30000
(  13.561|   0.060) D: [xrdp-sink][modules/module-xrdp-sink.c:359 process_render()] process_render: u->block_usec 30000
(  13.621|   0.060) D: [xrdp-sink][modules/module-xrdp-sink.c:359 process_render()] process_render: u->block_usec 30000
^C(  13.649|   0.028) I: [pulseaudio][daemon/main.c:126 signal_callback()] Got signal SIGINT.
(  13.649|   0.000) I: [pulseaudio][daemon/main.c:153 signal_callback()] Exiting.
(  13.649|   0.000) I: [pulseaudio][daemon/main.c:1188 main()] Daemon shutdown initiated.
(  13.649|   0.000) I: [pulseaudio][pulsecore/module.c:355 pa_module_free()] Unloading "module-xrdp-sink" (index: #0).
(  13.649|   0.000) I: [pulseaudio][pulsecore/module.c:382 pa_module_free()] Unloaded "module-xrdp-sink" (index: #0).
(  13.649|   0.000) E: [pulseaudio][pulsecore/core.c:187 core_free()] Assertion 'pa_idxset_isempty(c->sinks)' failed at pulsecore/core.c:187, function void core_free(pa_object *)(). Aborting.
Aborted

# _t1/p2.pa:
  # ERR: Segmentation fault
  #.ifexists module-x11-publish.so
  #    load-module module-x11-publish
  #.endif
```



