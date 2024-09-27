
- su-exec
- n2n
- tinc

## su-exec

```bash
   3 cd /mnt2/
   5 mkdir _2409
   6 cd _2409/
   8 git clone https://gitee.com/g-system/fk-su-exec
  ################
  13 cd fk-su-exec/
  15 make
  16 ls -lh
  17 ldd su-exec
  18 ./su-exec
  19 ./su-exec root ls
  22 ./su-exec adf ls
  24 ./su-exec headless ls
  25 adduser headless
  28 ./su-exec headless ps -ef
  41 make clean
  42 make su-exec
  43 make su-exec-static #static
  44 ls -lh
  45 ldd su-exec-static 
  46 ./su-exec-static -h
```

## n2n,tinc

```bash
  10 git clone https://gitee.com/g-system/fk-lucktu-n2n
  11 git clone https://gitee.com/g-system/fk-tinc
  ################
  48 cd ..
  50 cd fk-lucktu-n2n/
  52 bash autogen.sh 
  53 make
  55 ldd edge
  57 ldd supernode
  58 ls -lh

  ################
  59 cd ../fk-tinc/
  61 cat ../fk-lucktu-n2n/autogen.sh 
  62 autoreconf -if
  64 ./configure
  69 apk add lzo-dev openssl-dev
  70 ./configure
  73 echo $?
  80 apk add texinfo
  81 make
  82 echo $?
  84 ls doc/
  85 ls src/
  86 ldd src/tincd
  87 ls -lh src/tincd
  89 src/tincd --help
  90 history
```

**n2n static**

```bash
# ref src/v-feh/build.sh:
# make clean; make LDFLAGS="-static"
  make -C tools
  make[1]: Entering directory '/mnt2/_2409/fk-lucktu-n2n/tools'
  Makefile:40: warning: ignoring prerequisites on suffix rule definition
  cc -I../include -g -O2 -g3 -O2  -Wall benchmark.c -static -lzstd ../libn2n.a -lzstd  -o n2n-benchmark
  make[1]: Leaving directory '/mnt2/_2409/fk-lucktu-n2n/tools'
/mnt2/_2409/fk-lucktu-n2n # echo $?
0

/mnt2/_2409/fk-lucktu-n2n # ls -lh edge supernode
  -rwxr-xr-x    1 root     root        2.3M Sep 13 03:26 edge
  -rwxr-xr-x    1 root     root      840.7K Sep 13 03:26 supernode
/mnt2/_2409/fk-lucktu-n2n # ldd edge supernode
/lib/ld-musl-x86_64.so.1: edge: Not a valid dynamic program
/mnt2/_2409/fk-lucktu-n2n # ldd supernode
/lib/ld-musl-x86_64.so.1: supernode: Not a valid dynamic program
/mnt2/_2409/fk-lucktu-n2n # history |tail -15
  92 cd -
  95 apk add zstd-static
  # 96 make clean; make LDFLAGS="-static -lzstd" #-lzstd 已自带
  93 make clean; make LDFLAGS="-static"
  97 echo $?
  99 ls -lh edge supernode
 100 ldd edge supernode
 101 ldd supernode
```

**tinc static**

```bash
# make clean; make LDFLAGS="-static"
    CCLD     tincd
  /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lcrypto

/mnt2/_2409/fk-tinc # history |tail -15
 104 cd ../fk-tinc/
 107 apk add openssl-libs-static ## ref docs/core/xrdp02.md
 108 make clean; make LDFLAGS="-static"
 109 ls -lh src/tincd
 110 ldd src/tincd

/mnt2/_2409/fk-tinc # make clean; make LDFLAGS="-static"
    CC       tincd.o
    CC       utils.o
    CC       linux/device.o
    CCLD     tincd
  make[2]: Leaving directory '/mnt2/_2409/fk-tinc/src'
  Making all in doc
  make[2]: Entering directory '/mnt2/_2409/fk-tinc/doc'
    GEN      tincinclude.texi
    MAKEINFO tinc.info
    GEN      tincd.8
    GEN      tinc.conf.5
  make[2]: Leaving directory '/mnt2/_2409/fk-tinc/doc'
  Making all in systemd
  make[2]: Entering directory '/mnt2/_2409/fk-tinc/systemd'
  make[2]: Nothing to be done for 'all'.
  make[2]: Leaving directory '/mnt2/_2409/fk-tinc/systemd'
  make[2]: Entering directory '/mnt2/_2409/fk-tinc'
  make[2]: Leaving directory '/mnt2/_2409/fk-tinc'
  make[1]: Leaving directory '/mnt2/_2409/fk-tinc'
/mnt2/_2409/fk-tinc # ls -lh src/tincd
  -rwxr-xr-x    1 root     root        9.9M Sep 13 03:33 src/tincd
/mnt2/_2409/fk-tinc # ldd src/tincd
  /lib/ld-musl-x86_64.so.1: src/tincd: Not a valid dynamic program

```

## lrzsz

**lrzsz static**

```bash
 116 git clone https://gitee.com/g-system/fk-lrzsz
 118 cd fk-lrzsz/
 121 autoconf 
 122 echo $?
 124 ./configure
 125 echo $?
 126 make
 129 ls -lh src/lrz src/lsz
 130 ldd src/lrz
 # 
 131 make clean; make LDFLAGS="-static" ######无效，依旧为动态的
 132 ls -lh src/lrz src/lsz
 133 ldd src/lrz

/mnt2/_2409/fk-lrzsz # #make clean; make LDFLAGS="-static"
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz/po'
  Making all in man
  make[2]: Entering directory '/mnt2/_2409/fk-lrzsz/man'
  make[2]: Nothing to be done for 'all'.
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz/man'
  make[2]: Entering directory '/mnt2/_2409/fk-lrzsz'
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz'
  make[1]: Leaving directory '/mnt2/_2409/fk-lrzsz'
/mnt2/_2409/fk-lrzsz # ls -lh src/lrz src/lsz
  -rwxr-xr-x    1 root     root      199.6K Sep 13 05:48 src/lrz
  -rwxr-xr-x    1 root     root      196.6K Sep 13 05:48 src/lsz
/mnt2/_2409/fk-lrzsz # ldd src/lrz
        /lib/ld-musl-x86_64.so.1 (0x7f1447119000)
        libintl.so.8 => /usr/lib/libintl.so.8 (0x7f14470fc000)
        libc.musl-x86_64.so.1 => /lib/ld-musl-x86_64.so.1 (0x7f1447119000)
/mnt2/_2409/fk-lrzsz # 


# static try2
/mnt2/_2409/fk-lrzsz # #make clean; make
  mv -f .deps/lsz.Tpo .deps/lsz.Po
  /bin/sh ../libtool  --tag=CC   --mode=link xx-clang -Os -fomit-frame-pointer -Os -fomit-frame-pointer  -Wl,--as-needed --static -static -Wl,--strip-all -o lsz lsz.o iomode.o baudrate.o check_stderr.o utils.o close_and_update_meta.o log.o canit.o protname.o zm.o rbsb.o timing.o zreadline.o crctab.o ../lib/libzmodem.a  -lintl 
  libtool: link: xx-clang -Os -fomit-frame-pointer -Os -fomit-frame-pointer -Wl,--as-needed --static -Wl,--strip-all -o lsz lsz.o iomode.o baudrate.o check_stderr.o utils.o close_and_update_meta.o log.o canit.o protname.o zm.o rbsb.o timing.o zreadline.o crctab.o  ../lib/libzmodem.a -lintl
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz/src'
  Making all in po
  make[2]: Entering directory '/mnt2/_2409/fk-lrzsz/po'
  Makefile:199: warning: ignoring prerequisites on suffix rule definition
  make[2]: Nothing to be done for 'all'.
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz/po'
  Making all in man
  make[2]: Entering directory '/mnt2/_2409/fk-lrzsz/man'
  make[2]: Nothing to be done for 'all'.
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz/man'
  make[2]: Entering directory '/mnt2/_2409/fk-lrzsz'
  make[2]: Leaving directory '/mnt2/_2409/fk-lrzsz'
  make[1]: Leaving directory '/mnt2/_2409/fk-lrzsz'
/mnt2/_2409/fk-lrzsz # ldd src/lrz
  /lib/ld-musl-x86_64.so.1: src/lrz: Not a valid dynamic program
/mnt2/_2409/fk-lrzsz # ls -lh src/lrz src/lsz
  -rwxr-xr-x    1 root     root      272.3K Sep 13 06:01 src/lrz
  -rwxr-xr-x    1 root     root      264.6K Sep 13 06:01 src/lsz

 144 ./configure -h
 145 LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all -Wl,--start-group" ./configure --enable-static --disable-shared --without-libintl-prefix 

 #ref src/fluxbox/build.sh
 146 export CFLAGS="-Os -fomit-frame-pointer"
 147 export CXXFLAGS="$CFLAGS"
 148 export CPPFLAGS="$CFLAGS"
 149 export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
 150 # 
 151 export CC=xx-clang
 
 152 ./configure --enable-static --disable-shared --without-libintl-prefix 
 153 make clean; make LDFLAGS="-static" #无效 依旧dyn
 154 ldd src/lrz
 155 make clean; make #OK
 156 ldd src/lrz
 157 ls -lh src/lrz src/lsz
```