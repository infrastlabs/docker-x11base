

```bash
  44 git clone https://ghps.cc/https://github.com/invisikey/xcompmgr
  45 cd xcompmgr/
  46 ls
  47 cat autogen.sh 
  48 bash autogen.sh 
checking if gcc supports -Werror... yes
checking if gcc supports -Werror=attributes... yes
checking whether make supports nested variables... (cached) yes
checking for XCOMPMGR... no
configure: error: Package requirements (xcomposite xfixes xdamage xrender xext) were not met:
Package 'xcomposite', required by 'virtual:world', not found
Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables XCOMPMGR_CFLAGS
and XCOMPMGR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.
/mnt2/xcompmgr # ls


# deps
/mnt2/xcompmgr # apk add xcomposite xfixes xdamage xrender xext
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
ERROR: unable to select packages:
  xcomposite (no such package):
    required by: world[xcomposite]
  xdamage (no such package):
    required by: world[xdamage]
  xext (no such package):
    required by: world[xext]
  xfixes (no such package):
    required by: world[xfixes]
  xrender (no such package):
    required by: world[xrender]



# 
autoreconf -fi
/mnt2/xcompmgr # ./configure
checking whether make supports nested variables... (cached) yes
checking for XCOMPMGR... no
configure: error: Package requirements (xcomposite xfixes xdamage xrender xext) were not met:

Package 'xcomposite', required by 'virtual:world', not found

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

Alternatively, you may set the environment variables XCOMPMGR_CFLAGS
and XCOMPMGR_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.

# deps02
/mnt2/xcompmgr # apk add libxcomposite-dev
/mnt2/xcompmgr # ./configure
checking that generated files are newer than configure... done
configure: creating ./config.status
config.status: creating Makefile
config.status: creating man/Makefile
config.status: creating config.h
config.status: executing depfiles commands

# make
/mnt2/xcompmgr # ls -lh
total 2M     
-rwxr-xr-x    1 root     root      136.2K Nov  8 01:11 xcompmgr
-rw-r--r--    1 root     root       55.9K Nov  8 00:55 xcompmgr.c
-rw-r--r--    1 root     root      193.2K Nov  8 01:11 xcompmgr.o
/mnt2/xcompmgr # ./xcompmgr -h
./xcompmgr: unrecognized option: h
./xcompmgr v1.1.6
```

- static build

```bash

# ./configure --help
make clean
make LDFLAGS="-static -lxcomposite"

/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lxcomposite
/usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: cannot find -lXdamage
collect2: error: ld returned 1 exit status
make[2]: *** [Makefile:452: xcompmgr] Error 1

# libxdamage libxcomposite ##都无static库;
```
