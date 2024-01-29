
- try01: **先让静态编译可过(无个别库so依赖), 即使不顾coreDumpErr**
- try02: tag-v13.99.3-dynBuild>> 调试default.la加载mods(xrdp-source/sink; 依赖项/Merge代码?)

```bash
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
# -lltdl 
dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
LIBS="$dep1" ./configure \
    --prefix=${CMAKE_BINARY_DIR} \
    $args
make clean
make LDFLAGS="-static --static $dep1"

# err01:
clang-12: error: no such file or directory: '@LIBLTDL@'
# bash-5.1# find |egrep Makefile$ |while read one; do echo -e "\n\n$one"; cat $one |grep "LIBLTDL" -n; done 
# ./src/Makefile
3835:LIBLTDL = @LIBLTDL@
4105:   libpulsecommon-13.99.la libpulse.la $(LIBLTDL) \
4644:libpulsecore_13.99_la_LIBADD = $(AM_LIBADD) $(LIBLTDL) \
4975:module_ladspa_sink_la_LIBADD = $(MODULE_LIBADD) $(LIBLTDL) \

# vi
# - src/Makefile 3849/13198 29%
# 改后 make; 编译过了; LIBLTDL = 
sed -i "s/LIBLTDL = @LIBLTDL@/LIBLTDL =/g" ./src/Makefile
```

**未指定-static时: 找不到so，则用a库**

- try-c1 `libFLAC> libsndfile/libogg > libvorbis/libvorbisenc`
  - libogg
    - libsndfile/libFLAC
    - libvorbis/libvorbisenc

```bash
bash-5.1# find /usr/lib /usr/local/lib |grep libFLAC
/usr/lib/libFLAC++.so
/usr/lib/libFLAC.so
/usr/lib/libFLAC++.so.6
/usr/lib/libFLAC++.so.6.3.0
/usr/lib/libFLAC.so.8
/usr/lib/libFLAC.so.8.3.0
/usr/local/lib/libFLAC++.la
/usr/local/lib/libFLAC.a
/usr/local/lib/libFLAC.la
/usr/local/lib/libFLAC++.a

# 未指定-static时: 找不到so，则用a库
# bash-5.1# mv /usr/lib/libFLAC.so /usr/lib/libFLAC.so-00
# ERR01:
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.so: undefined reference to symbol 'ogg_stream_reset'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libogg.so: error adding symbols: DSO missing from command line


# bash-5.1# mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.so-00
# bash-5.1# mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libogg.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libogg.so-00
# ERR02:
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libsndfile.a(ogg.c.o): undefined reference to symbol 'ogg_stream_reset'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/lib/libogg.so.0: error adding symbols: DSO missing from command line

# bash-5.1# mv /usr/lib/libogg.so.0 /usr/lib/libogg.so.0-00
  782  mv /usr/lib/libogg.so.0 /usr/lib/libogg.so.0-00
  #783  make clean; make
  785  mv /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libvorbis.so /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libvorbis.so-00
  788  mv /usr/lib/libvorbis.so.0 /usr/lib/libvorbis.so.0-00
  789  make
  790  mv  /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libvorbisenc.so  /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libvorbisenc.so-00


# a库src编译版; 瑟so-apk安装版内容不一致??
# 分法名经libltdl暴露? a库不能直接引用到??
```

## 01: deps本地src编译;

**deps x4+1** `-logg -lopus  -lFLAC -lvorbis/vorbisenc -lsndfile`

- ogg-v135 https://hub.yzuu.cf/xiph/ogg #324, Ogg media container `Sep 3, 2000+`
- vorbis/enc-v137 https://hub.yzuu.cf/xiph/vorbis #432, Ogg Vorbis audio format `Jul 11, 1999+`
- Flac-v134 https://hub.yzuu.cf/xiph/flac #1.4k, Free Lossless Audio Codec `Dec 10, 2000+ (2012+)`
- opus-v131 https://hub.yzuu.cf/xiph/opus #2k, audio compression `Nov 25, 2007+`
- libsndfile-v1.0.31 https://hub.yzuu.cf/libsndfile/libsndfile #1.3k, A C library for reading and writing sound files `Jan 18, 2004+`

```bash
# libsndfile-dev-deps: libogg,opus,flac,libvorbis
bash-5.1# apk list -I |egrep "ogg|opus|flac|vorbis|sndfile" |grep -v dev |sort
libogg-1.3.5-r0 x86_64 {libogg} (BSD-3-Clause) [installed]
libvorbis-1.3.7-r0 x86_64 {libvorbis} (BSD-3-Clause) [installed]
flac-1.3.4-r0 x86_64 {flac} (custom:Xiph LGPL GPL FDL) [installed]
# 
opus-1.3.1-r1 x86_64 {opus} (BSD-3-Clause) [installed]
libsndfile-1.0.31-r1 x86_64 {libsndfile} (LGPL-2.0-or-later) [installed]

# 如下，可一次性清理了(/usr/lib/libxxx);
# bash-5.1# apk del libsndfile-dev
(1/11) Purging libsndfile-dev (1.0.31-r1)
(2/11) Purging libsndfile (1.0.31-r1)
(3/11) Purging libvorbis-dev (1.3.7-r0)
(4/11) Purging libvorbis (1.3.7-r0)
(5/11) Purging flac-dev (1.3.4-r0)
(6/11) Purging flac (1.3.4-r0)
(7/11) Purging libogg-dev (1.3.5-r0)
(8/11) Purging libogg (1.3.5-r0)
(9/11) Purging opus-dev (1.3.1-r1)
(10/11) Purging opus (1.3.1-r1)
(11/11) Purging alsa-lib (1.2.5.1-r1)
Executing busybox-1.34.1-r7.trigger
OK: 776 MiB in 260 packages
bash-5.1# apk list -I |egrep "ogg|opus|flac|vorbis|sndfile" 
logger-2.37.4-r0 x86_64 {util-linux} (GPL-3.0-or-later AND GPL-2.0-or-later AND GPL-2.0-only AND) [installed]
# bash-5.1# find /usr/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile"
/usr/lib/libogg.a00
/usr/lib/libsndfile.a-00
/usr/lib/libogg.a01
/usr/lib/libvorbis.so.0-00
/usr/lib/libogg.so.0-00
/usr/lib/libsndfile.so-00
/usr/lib/libvorbis.so-00
/usr/lib/libFLAC.so-00
/usr/lib/libvorbisenc.so-00
/usr/lib/libogg.so-00

# 清理usr/lib后，fk-pulseaudio再make, ERR:
make[3]: Entering directory '/mnt2/_misc2/fk-pulseaudio/src'
  CC       pulsecore/libpulsecore_13.99_la-sound-file-stream.lo
pulsecore/sound-file-stream.c:30:10: fatal error: 'sndfile.h' file not found
```

- /usr/local 源码版：

```bash
# /usr/local/lib/libxxx现况
bash-5.1# find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort
/usr/local/lib/libFLAC++.a
/usr/local/lib/libFLAC++.la
/usr/local/lib/libFLAC.a
/usr/local/lib/libFLAC.la
/usr/local/lib/libogg.a
/usr/local/lib/libogg.la
/usr/local/lib/libogg.so
/usr/local/lib/libogg.so.0
/usr/local/lib/libogg.so.0.8.5
/usr/local/lib/libopus.a
/usr/local/lib/libopus.la
/usr/local/lib/libopus.so
/usr/local/lib/libopus.so.0
/usr/local/lib/libopus.so.0.8.0
/usr/local/lib/libvorbis.a
/usr/local/lib/libvorbis.la
/usr/local/lib/libvorbisenc.a
/usr/local/lib/libvorbisenc.la
/usr/local/lib/libvorbisfile.a
/usr/local/lib/libvorbisfile.la


# #重编译#######
# ogg-v135
bash-5.1# pwd
/mnt2/_misc2/_xiph/ogg-v135
bash-5.1# make clean; make; make install
bash-5.1# find /usr/local/lib /usr/lib |grep libogg
/usr/local/lib/libogg.so
/usr/local/lib/libogg.la
/usr/local/lib/libogg.a
/usr/local/lib/libogg.so.0.8.5
/usr/local/lib/libogg.so.0
/usr/lib/libogg.a00
/usr/lib/libogg.so.0-00
/usr/lib/libogg.a
/usr/lib/libogg.so.0.8.5
/usr/lib/libogg.so-00

bash-5.1# ll /usr/lib/libogg.a
-rw-r--r--    1 root     root        118842 Jan 14 15:50 /usr/lib/libogg.a
bash-5.1# ll /usr/local/lib/libogg.a 
-rw-r--r--    1 root     root        118842 Jan 29 08:36 /usr/local/lib/libogg.a
bash-5.1# md5sum  /usr/lib/libogg.a /usr/local/lib/libogg.a
fb44a8c94c457dd93556bb00a3d68741  /usr/lib/libogg.a
fb44a8c94c457dd93556bb00a3d68741  /usr/local/lib/libogg.a
# bash-5.1# find |grep libogg.a
./src/.libs/libogg.a
bash-5.1# md5sum ./src/.libs/libogg.a
fb44a8c94c457dd93556bb00a3d68741  ./src/.libs/libogg.a


# opus-v14>> opus-v14-v131 #切tag
bash-5.1# pwd
/mnt2/_misc2/_xiph/opus-v14-v131
bash-5.1# find |grep libopus
./libopus.la
./.libs/libopus.a
./.libs/libopus.so.0
./.libs/libopus.so
./.libs/libopus.la
./.libs/libopus.lai
./.libs/libopus.so.0.8.0

# bash-5.1# find /usr/local/lib /usr/lib |grep libopus
/usr/local/lib/libopus.la
/usr/lib/libopus.a
/usr/lib/libopus.so.0
/usr/lib/libopus.so
/usr/lib/libopus.so.0.8.0
# bash-5.1# make install
bash-5.1# find /usr/local/lib /usr/lib |grep libopus
/usr/local/lib/libopus.a
/usr/local/lib/libopus.so.0
/usr/local/lib/libopus.so
/usr/local/lib/libopus.la
/usr/local/lib/libopus.so.0.8.0
/usr/lib/libopus.a
/usr/lib/libopus.so.0
/usr/lib/libopus.so
/usr/lib/libopus.so.0.8.0

# flac-v134
bash-5.1# pwd
/mnt2/_misc2/_xiph/flac-v134
  105  make clean
  106  make 
  108  make install
bash-5.1# find |grep libFLAC.a
./src/libFLAC/.libs/libFLAC.a


# vorbis-v137
bash-5.1# pwd
/mnt2/_misc2/_xiph/vorbis-org-v137
bash-5.1# history |tail -6
  113  git branch
  114  make clean
  115  make
  make install
bash-5.1# find |grep libvorbis
./lib/.libs/libvorbis.a
./lib/.libs/libvorbisfile.a
./lib/.libs/libvorbisenc.a



# libsndfile-v1.0.31
  141  ./autogen.sh
  144  diff autogen.sh* #-bk1; die 1;
  149  ./configure
  151  make clean
bash-5.1# make
make  src/test_endswap.def
make[1]: Entering directory '/mnt2/_misc2/libsndfile-v1.0.31'
make[1]: 'src/test_endswap.def' is up to date.
make[1]: Leaving directory '/mnt2/_misc2/libsndfile-v1.0.31'
cd ./src && autogen --writable test_endswap.def
/bin/sh: autogen: not found
make: *** [Makefile:4170: src/test_endswap.c] Error 127

bash-5.1# cat Makefile |grep autogen -n
4167:# from calling autogen in tarball releases.
4170:   cd $(top_srcdir)/$(@D) && autogen --writable $(<F) ##注释这行;>> make

# make; 过了
bash-5.1# find |grep libsndfile
./src/.libs/libsndfile.a
# bash-5.1# make install
bash-5.1# echo $?
0
```

**再次fk-pulseaudio**

```bash
# 直接make: >> 只余下ogg,opus,sndfile三个依赖 (flac,vorbis搞定)
bash-5.1# ls src/pulseaudio  -lh
-rwxr-xr-x    1 root     root        9.0M Jan 29 09:30 src/pulseaudio
bash-5.1# ldd src/pulseaudio |sort
        /lib/ld-musl-x86_64.so.1 (0x7f2d66952000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f2d66952000)
        libogg.so.0 => /usr/local/lib/libogg.so.0 (0x7f2d65e71000)
        libopus.so.0 => /usr/local/lib/libopus.so.0 (0x7f2d65e7c000)
        libsndfile.so.1 => /usr/local/lib/libsndfile.so.1 (0x7f2d65ed9000)


# 
make clean
make LDFLAGS="-static --static $dep1"
make LDFLAGS="--static $dep1" ##一样有-static效果
# 也是ogg错误; @/usr/local/lib/libvorbis.a,libFLAC.a,libsndfile.a

bash-5.1# find /usr/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile"
/usr/lib/libogg.a00
/usr/lib/libsndfile.a-00
/usr/lib/libogg.a01
/usr/lib/libvorbis.so.0-00
/usr/lib/libogg.so.0-00
/usr/lib/libsndfile.so-00
/usr/lib/libvorbis.so-00
/usr/lib/libFLAC.so-00
/usr/lib/libvorbisenc.so-00
/usr/lib/libogg.so-00
bash-5.1# find /usr/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |while read one; do rm -f $one; done
bash-5.1# find /usr/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile"


dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
dep1="-logg -lopus  -lFLAC -lvorbis -lvorbisenc -lsndfile" #sort


```

## 02: 尝试ogg静态(libogg.a>> Flac/vorbis>> sndfile)

TODO: modules<native-unix, xrdp-sink/source.so> 

- 直接嵌入代码?
- so动态加载[配置加载ltdl:用时加载]?(zeroDeps)


**尝试重编译deps** `ogg> [opus]flac,vorbis> sndfile`

```bash
# bash-5.1# find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort
/usr/local/lib/libFLAC++.a
/usr/local/lib/libFLAC++.la
/usr/local/lib/libFLAC.a
/usr/local/lib/libFLAC.la
/usr/local/lib/libogg.a
/usr/local/lib/libogg.la
/usr/local/lib/libogg.so
/usr/local/lib/libogg.so.0
/usr/local/lib/libogg.so.0.8.5
/usr/local/lib/libopus.a
/usr/local/lib/libopus.la
/usr/local/lib/libopus.so
/usr/local/lib/libopus.so.0
/usr/local/lib/libopus.so.0.8.0
/usr/local/lib/libsndfile.a
/usr/local/lib/libsndfile.la
/usr/local/lib/libsndfile.so
/usr/local/lib/libsndfile.so.1
/usr/local/lib/libsndfile.so.1.0.31
/usr/local/lib/libvorbis.a
/usr/local/lib/libvorbis.la
/usr/local/lib/libvorbisenc.a
/usr/local/lib/libvorbisenc.la
/usr/local/lib/libvorbisfile.a
/usr/local/lib/libvorbisfile.la
bash-5.1# mv /usr/local/lib/libogg.so /usr/local/lib/libogg.so-00
bash-5.1# mv /usr/local/lib/libogg.so.0 /usr/local/lib/libogg.so.0-00


# 移除libogg.so后，原build依赖情况
bash-5.1# ldd src/pulseaudio 
        /lib/ld-musl-x86_64.so.1 (0x7f886c225000)
Error loading shared library libogg.so.0: No such file or directory (needed by src/pulseaudio)
        libopus.so.0 => /usr/local/lib/libopus.so.0 (0x7f886b8bc000)
        libsndfile.so.1 => /usr/local/lib/libsndfile.so.1 (0x7f886b74f000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f886c225000)
Error loading shared library libogg.so.0: No such file or directory (needed by /usr/local/lib/libsndfile.so.1)
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_pagein: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_wrote: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_reset: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_granulepos: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_writetrunc: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_reset: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_pageseek: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_pageout_fill: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_reset_serialno: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_writeinit: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_clear: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_look: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_packetin: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_packetout: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_eos: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_init: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_bytes: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_writeclear: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_adv: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_packetpeek: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_packets: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_init: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_checksum_set: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_get_buffer: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_pageout: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_clear: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_bos: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_readinit: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_page_serialno: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_flush_fill: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_read: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_buffer: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_packet_clear: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_stream_flush: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: ogg_sync_pageout: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_reset: symbol not found
Error relocating /usr/local/lib/libsndfile.so.1: oggpack_write: symbol not found


# 静库时,opus错误情况： (libsndfile_la-ogg_opus.o)
# bash-5.1# make clean; make LDFLAGS="-static --static  -lFLAC -lvorbisenc -lvorbis -logg -lopus" 2>&1 |grep opus
make[1]: Leaving directory '/mnt2/_misc2/fk-pulseaudio'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_setup_decoder':
ogg_opus.c:(.text+0x265): undefined reference to `opus_multistream_decoder_create'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x287): undefined reference to `opus_multistream_decoder_destroy'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2c4): undefined reference to `opus_multistream_decoder_ctl'

/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x774): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_write_header':
ogg_opus.c:(.text+0xd55): undefined reference to `ogg_stream_reset_serialno'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0xe49): undefined reference to `ogg_stream_packetin'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0xe73): undefined reference to `ogg_stream_flush'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0xe7c): undefined reference to `opus_get_version_string'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0xeab): undefined reference to `ogg_stream_packetin'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0xedb): undefined reference to `ogg_stream_flush'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_close':
ogg_opus.c:(.text+0x114a): undefined reference to `opus_multistream_encode_float'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x118d): undefined reference to `ogg_stream_packetin'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x11aa): undefined reference to `ogg_stream_pageout'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x11d2): undefined reference to `opus_multistream_decoder_destroy'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x11eb): undefined reference to `ogg_packet_clear'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x1201): undefined reference to `opus_multistream_encoder_destroy'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x1222): undefined reference to `ogg_stream_flush'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x123a): undefined reference to `opus_multistream_encode_float'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x12b1): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_unpack_next_page':
ogg_opus.c:(.text+0x139d): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_byterate':
ogg_opus.c:(.text+0x150b): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_seek_manual':
ogg_opus.c:(.text+0x15d6): undefined reference to `ogg_stream_reset'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x1201): undefined reference to `opus_multistream_encoder_destroy'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x1222): undefined reference to `ogg_stream_flush'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x123a): undefined reference to `opus_multistream_encode_float'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x12b1): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_unpack_next_page':
ogg_opus.c:(.text+0x139d): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_byterate':
ogg_opus.c:(.text+0x150b): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_seek_manual':
ogg_opus.c:(.text+0x15d6): undefined reference to `ogg_stream_reset'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x160d): undefined reference to `opus_multistream_decoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_read_refill':
ogg_opus.c:(.text+0x1674): undefined reference to `opus_multistream_decode_float'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x174f): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x17d5): undefined reference to `opus_multistream_decode_float'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x17ec): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x1820): undefined reference to `ogg_page_eos'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_seek':
ogg_opus.c:(.text+0x1b95): undefined reference to `opus_multistream_decoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: /usr/local/lib/libsndfile.a(libsndfile_la-ogg_opus.o): in function `ogg_opus_open':
ogg_opus.c:(.text+0x2193): undefined reference to `opus_get_version_string'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x224f): undefined reference to `ogg_page_packets'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2260): undefined reference to `ogg_page_bos'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2270): undefined reference to `ogg_page_serialno'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x23ab): undefined reference to `ogg_stream_packetout'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x24ad): undefined reference to `opus_packet_get_nb_samples'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x24e8): undefined reference to `ogg_page_eos'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2671): undefined reference to `opus_multistream_surround_encoder_create'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x26ae): undefined reference to `opus_multistream_encoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x26dd): undefined reference to `opus_multistream_encoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2701): undefined reference to `opus_multistream_encoder_ctl'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2773): undefined reference to `ogg_packet_clear'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x27b9): undefined reference to `ogg_stream_init'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x289b): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x28c3): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x28e1): undefined reference to `opus_strerror'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x293c): undefined reference to `opus_multistream_encoder_create'
/usr/bin/x86_64-alpine-linux-musl-ld: ogg_opus.c:(.text+0x2988): undefined reference to `ogg_page_eos'
```

- 移除libogg.so(deps: 尝试libogg.a依赖)

```bash
# 移除libogg.so
# 1.清理opus-all
# 2.Flac,vorbis编译ins
# 3.opus再编译安装; TODO>>4.sndfile

# try1
#  未重编译sndfile时: 其so有ogg.so的依赖(找不到而出错)

# try2
# 4.sndfile makeErr: (需要动态库?)
  CCLD     src/libcommon.la
ar: 'u' modifier ignored since `D' is the default (see `U')
  CCLD     src/libsndfile.la
gcc: error: /usr/local/lib/libopus.so: No such file or directory
gcc: error: /usr/local/lib/libogg.so: No such file or directory
make[2]: *** [Makefile:1916: src/libsndfile.la] Error 1
make[2]: Leaving directory '/mnt2/_misc2/libsndfile-v1.0.31'

# static; 只编译出libvorbis.a即可; (so为dyn/其它用例需要)
  237  make LDFLAGS="-static --static $dep1"
  238  echo $dep1 
  239  make clean; make LDFLAGS="-static --static -logg -lopus -lFLAC -lvorbis -lvorbisenc"
  # 240  cd ../_xiph/vorbis-org-v137
  241  make clean; make LDFLAGS="-static --static -logg -lopus "
  242  find |grep libsndfi
  243  find |grep libvorbis
  244  \cp -a ./lib/.libs/libvorbis.a /usr/local/lib/
  246  make clean; make LDFLAGS="-static --static -logg "


# 清理了Flac, vorbis, sndfile的动态库后： pulseMake: 一样oggpack_write/read找不到错误;
# 1.下载fk-ogg仓，查看vers(非频变更)，ogg.h有暴露方法头
extern void  oggpack_write(oggpack_buffer *b,unsigned long value,int bits);
extern long  oggpack_read(oggpack_buffer *b,int bits);

```

**deps尝试纯静态编译** `src/pulseaudio 静态编译成功!`

```bash
  # 258  find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort |while read one; do echo $one; rm -f $one; done


# [ogg]
  253  ./configure --enable-static --disable-shared
  254  make clean; make
  255  find |grep libogg
  261  make install
bash-5.1# find |grep libogg
./src/.libs/libogg.lai
./src/.libs/libogg.la
./src/.libs/libogg.a
# bash-5.1# find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort |while read one; do echo $one; rm -f $one; done
/usr/local/lib/libogg.a
/usr/local/lib/libogg.la


# [Flac]
  270  ./configure --enable-static --disable-shared
  271  make clean; make
  275  find |grep libFLAC |sort |grep libs
bash-5.1# make install
bash-5.1# find |grep libFLAC |sort |grep libs
./src/libFLAC++/.libs
./src/libFLAC++/.libs/libFLAC++-static.a
./src/libFLAC++/.libs/libFLAC++-static.la
./src/libFLAC++/.libs/libFLAC++.a
./src/libFLAC++/.libs/libFLAC++.la
./src/libFLAC++/.libs/libFLAC++.lai
./src/libFLAC/.libs
./src/libFLAC/.libs/libFLAC-static.a
./src/libFLAC/.libs/libFLAC-static.la
./src/libFLAC/.libs/libFLAC.a
./src/libFLAC/.libs/libFLAC.la
./src/libFLAC/.libs/libFLAC.lai


# [vorbis]
  280  ./configure --enable-static --disable-shared
  281  make clean; make; make ins; 
  283  find |grep libvorbis |sort |grep libs
bash-5.1# find |grep libvorbis |sort |grep libs
./lib/.libs/libvorbis.a
./lib/.libs/libvorbis.la
./lib/.libs/libvorbis.lai
./lib/.libs/libvorbisenc.a
./lib/.libs/libvorbisenc.la
./lib/.libs/libvorbisenc.lai
./lib/.libs/libvorbisfile.a
./lib/.libs/libvorbisfile.la
./lib/.libs/libvorbisfile.lai


# [opus]
bash-5.1# history |tail -9
  286  cd ../opus-v14-v131/
  287  ls
  288  ./configure --enable-static --disable-shared
  289  make clean; make; make ins;
bash-5.1# find |grep libopus |sort |grep libs
./.libs/libopus.a
./.libs/libopus.la
./.libs/libopus.lai


# [libsndfile]
  295  cd libsndfile-v1.0.31/
  296  ./configure --enable-static --disable-shared
  301  cat Makefile |grep autogen
  303  sed -i "s/autogen/echo autogen/g" Makefile
  304  make clean; make
  305  echo $? #ret 0; 这次sndfile直接编译过了;
  # make install;
bash-5.1# find |grep libsndfile |sort |grep "\.libs"
./src/.libs/libsndfile.a
./src/.libs/libsndfile.la
./src/.libs/libsndfile.lai

# view
# .a文件（静态库文件） .la文件(libtool archive) https://www.cnblogs.com/findumars/p/5421910.html
bash-5.1# find /usr/local/lib |egrep "libogg|libopus|libFLAC|libvorbis|libsndfile" |sort
/usr/local/lib/libFLAC++.a
/usr/local/lib/libFLAC++.la
/usr/local/lib/libFLAC.a
/usr/local/lib/libFLAC.la
/usr/local/lib/libogg.a
/usr/local/lib/libogg.la
/usr/local/lib/libopus.a
/usr/local/lib/libopus.la
/usr/local/lib/libsndfile.a
/usr/local/lib/libsndfile.la
/usr/local/lib/libvorbis.a
/usr/local/lib/libvorbis.la
/usr/local/lib/libvorbisenc.a
/usr/local/lib/libvorbisenc.la
/usr/local/lib/libvorbisfile.a
/usr/local/lib/libvorbisfile.la
```

- fk-pulseaudio>> 静态编译成功！！！

```bash
  # 832  make clean; make LDFLAGS="-static --static  -lFLAC -lvorbisenc -lvorbis -logg -lopus" 2>&1 
  833  ls -lh src/pulseaudio 
  834  ldd src/pulseaudio 
  835  ./src/pulseaudio  -h
  836  ./src/pulseaudio  
  837  cp ./src/pulseaudio  /mnt2/usr-local-static/
  838  ls -lh src/pa*
  839  ldd src/pactl 
  840  ./src/pactl -h

# fk-pulseaudio>> 静态编译成功！！！
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f98): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f88): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2fa8): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x2f78): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3198): warning: Module auto-loading no longer supported.
/usr/bin/x86_64-alpine-linux-musl-ld: .libs/pulseaudioS.o:(.data.rel.ro+0x3188): warning: Module auto-loading no longer supported.
  CC       utils/pacat-pacat.o
  CCLD     pacat
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
  CC       utils/pactl-pactl.o
  CCLD     pactl
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
  CC       utils/pasuspender-pasuspender.o
  CCLD     pasuspender
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
  CC       utils/pacmd-pacmd.o
  CCLD     pacmd
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
  CC       modules/gsettings/gsettings_helper-gsettings-helper.o
  CCLD     gsettings-helper
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgio-2.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lgobject-2.0
/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lglib-2.0
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:7101: gsettings-helper] Error 1
make[3]: Leaving directory '/mnt2/_misc2/fk-pulseaudio/src'
make[2]: *** [Makefile:5398: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2/fk-pulseaudio/src'
make[1]: *** [Makefile:833: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/fk-pulseaudio'
make: *** [Makefile:648: all] Error 2

# view: src/pulseaudio 
bash-5.1# ls -lh src/pulseaudio 
-rwxr-xr-x    1 root     root        5.6M Jan 30 07:23 src/pulseaudio
bash-5.1# ldd src/pulseaudio 
/lib/ld-musl-x86_64.so.1: src/pulseaudio: Not a valid dynamic program
# cmds:
bash-5.1# ls -lh src/pa*
-rwxr-xr-x    1 root     root        2.3M Jan 30 07:23 src/pacat
-rwxr-xr-x    1 root     root        1.8M Jan 30 07:23 src/pacmd
-rwxr-xr-x    1 root     root        2.4M Jan 30 07:23 src/pactl
-rwxr-xr-x    1 root     root        1.9M Jan 30 07:23 src/pasuspender
bash-5.1# ldd src/pactl 
/lib/ld-musl-x86_64.so.1: src/pactl: Not a valid dynamic program

# run: (alpine_with_conf, core dumped)
bash-5.1# ./src/pulseaudio  -h
bash-5.1# ./src/pulseaudio  
N: [pulseaudio] daemon-conf.c: Detected that we are run from the build tree, fixing search path.
W: [pulseaudio] main.c: This program is not intended to be run as root (unless --system is specified).
Segmentation fault (core dumped)

# tenvm-ubt2004:
# root@tenvm2:/mnt/usr-local-static# ./pulseaudio -h
STARTUP SCRIPT:
  -L, --load="MODULE ARGUMENTS"         Load the specified plugin module with
                                        the specified argument
  -F, --file=FILENAME                   Run the specified script
  -C                                    Open a command line on the running TTY
                                        after startup

  -n                                    Don\'t load default script file
# root@tenvm2:/mnt/usr-local-static# ./pulseaudio 
W: [pulseaudio] main.c: This program is not intended to be run as root (unless --system is specified).
E: [pulseaudio] main.c: Daemon startup without any loaded modules, refusing to work.



# alpine_with_conf, user.sam, codeDBG:
# /mnt2/_misc2/fk-pulseaudio $ ./src/pulseaudio --log-meta=true --log-time=true --log-level=4
(   0.001|   0.000) I: [pulseaudio][pulsecore/sconv_sse.c:167 pa_convert_func_init_sse()] Initialising SSE2 optimized conversions.
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1092 main()] A03
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1108 main()] A032
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1150 main()] A04
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1177 main()] Daemon startup complete.
(   0.001|   0.000) I: [pulseaudio][daemon/main.c:1182 main()] A05


(  20.019|  20.018) I: [pulseaudio][pulsecore/core.c:454 exit_callback()] We are idle, quitting...
(  20.019|   0.000) I: [pulseaudio][daemon/main.c:1188 main()] Daemon shutdown initiated.
(  20.019|   0.000) I: [pulseaudio][daemon/main.c:1218 main()] Daemon terminated.
/mnt2/_misc2/fk-pulseaudio $ 

# headless @ deb1013 in ~ |10:43:23  
$ ps -ef |grep pulse
headless   135     1  0 09:34 ?        00:00:00 pulseaudio --exit-idle-time=-1 -nF /tmp/.headless/pulse-4711.pa
```

## 03: tag-v13.99.3 `drop-mods-coreDumpErr>> 未改版`

```bash
  842  cd ../fk-pulseaudio-v13-99-3-tag-dyn-build-run/
  845  echo $args
  846  dep1="-logg -lopus -lsndfile  -lFLAC -lvorbis -lvorbisenc"
  847  LIBS="$dep1" ./configure     --prefix=${CMAKE_BINARY_DIR}     $args
  # 849  make clean; make LDFLAGS="-static --static  -lFLAC -lvorbisenc -lvorbis -logg -lopus" 2>&
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object '/usr/lib/libltdl.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
make[3]: *** [Makefile:7276: pulseaudio] Error 1

# bash-5.1# find /usr/lib /usr/local/lib |grep libltdl
/usr/lib/libltdl.so
/usr/lib/libltdl.a
/usr/lib/libltdl.so.7
/usr/lib/libltdl.so.7.3.1
/usr/lib/libltdl.la


# -static-libtool-libs #https://www.bilibili.com/read/cv9972588/
# bash-5.1# make LDFLAGS="-static --static -static-libtool-libs -lFLAC -lvorbisenc -lvorbis -logg -lopus" 2>&1
3347 warnings generated.
clang-12: error: no such file or directory: '/usr/lib/libltdl.so'
clang-12: warning: '-fuse-ld=' taking a path is deprecated. Use '--ld-path=' instead [-Wfuse-ld-path]
make[3]: *** [Makefile:7276: pulseaudio] Error 1
make[3]: Leaving directory '/mnt2/_misc2/fk-pulseaudio-v13-99-3-tag-dyn-build-run/src'
make[2]: *** [Makefile:5397: all] Error 2
make[2]: Leaving directory '/mnt2/_misc2/fk-pulseaudio-v13-99-3-tag-dyn-build-run/src'
make[1]: *** [Makefile:834: all-recursive] Error 1
make[1]: Leaving directory '/mnt2/_misc2/fk-pulseaudio-v13-99-3-tag-dyn-build-run'
make: *** [Makefile:649: all] Error 2

# 恢复libltdl.so
bash-5.1# mv /usr/lib/libltdl.so.7-00 /usr/lib/libltdl.so.7
bash-5.1# mv /usr/lib/libltdl.so-00 /usr/lib/libltdl.so
/usr/bin/x86_64-alpine-linux-musl-ld: attempted static link of dynamic object `/usr/lib/libltdl.so'
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)

```


