
## Debug

- x11-base:ubt-buidler
  - try1: deps
  - try2: 版本改一致(tiger,xorg)
  - try3: 细分cmds指令
  - try4: 注释sed操作,再make-Xvnc OK
- docker-headless:core-compile
  - try-b1: ubt's build-cmds OK
  - try-b2: linux/arm (missing: X11_X11_LIB),C++错

### x11-base:ubt-buidler

- **try1: deps**

```bash
   58  ll /tmp/tigervnc/unix/xserver/hw/vnc/
   59  apt install libxfont2-dev
   60  apt install libxfont2
   61  bash /build/build.sh  tigervnc
   62  cat tigervnc.log
   63  apt install xfont2-dev
   64  apt install libxfont2
   65  apt install libxfont-dev
   66  vi /build/build.sh 
   67  bash /build/build.sh  tigervnc
   68  apt install xserver-xorg-dev
   69  bash /build/build.sh  tigervnc
   70  apt install util-macros
   71  apt.sh       git autoconf libtool pkg-config gcc g++ make  libssl-dev libpam0g-dev       libjpeg-dev libx11-dev libxfixes-dev libxrandr-dev  flex bison libxml2-dev       intltool xsltproc xutils-dev python-libxml2 g++ xutils libfuse-dev       libmp3lame-dev nasm libpixman-1-dev xserver-xorg-dev
   72  libfdk-aac-dev libopus-dev
   73  apt.sh libfdk-aac-dev libopus-dev
   74  bash /build/build.sh  tigervnc
   75  find ../tigervnc-install/
   76  apt update
   77  apt install libbz2
   78  apt install libbz2*
   79  apt install lib
   80  apt install libbrotlidec-dev
   81  apt install libbrotlidec*
   82  apt install brotlidec*
   83  apt install libmd*
   84  apt install libmd-dev
   85  apt install brotlicommon*
   86  apt install libbrotlicommon*
   87  bash /build/build.sh  tigervnc
   88  vi /build/build.sh 
   89  bash /build/build.sh  tigervnc
   90  vi /build/build.sh 
   91  apt install libbrotli-dev libbz2-dev libmd-dev
   92  bash /build/build.sh  tigervnc
```

- **try2: 版本改一致后，依旧有错误**

```bash
# ref try2.log
root@bbe0437aff19:/# dpkg -l |grep libgnutls
ii  libgnutls-dane0:amd64          3.6.13-2ubuntu1.8                 amd64        GNU TLS library - DANE security support
ii  libgnutls-openssl27:amd64      3.6.13-2ubuntu1.8                 amd64        GNU TLS library - OpenSSL wrapper
ii  libgnutls28-dev:amd64          3.6.13-2ubuntu1.8                 amd64        GNU TLS library - development files
ii  libgnutls30:amd64              3.6.13-2ubuntu1.8                 amd64        GNU TLS library - main runtime library
ii  libgnutlsxx28:amd64            3.6.13-2ubuntu1.8                 amd64        GNU TLS library - C++ runtime library


# bash /build/build.sh tigervnc
```

- **try3: 细分cmds指令**

VER: 1.22.14> 1.20.7

```bash
# tiger/build.sh
TIGERVNC_VERSION=1.12.0
XSERVER_VERSION=1.20.7
TIGERVNC_URL=https://ghproxy.com/https://github.com/TigerVNC/tigervnc/archive/v${TIGERVNC_VERSION}.tar.gz
XSERVER_URL=https://www.x.org/releases/individual/xserver/xorg-server-${XSERVER_VERSION}.tar.gz

# test -z "$TARGETPATH" && export TARGETPATH=/opt/base
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f /mnt/$file || curl -# -k -fSL $url > /mnt/$file
  cat /mnt/$file
}
mkdir -p /tmp/tigervnc
down_catfile ${TIGERVNC_URL} | tar -xz --strip 1 -C /tmp/tigervnc
down_catfile ${XSERVER_URL} | tar -xz --strip 1 -C /tmp/tigervnc/unix/xserver

log "Patching TigerVNC..."
# Apply the TigerVNC patch against the X server.
patch -p1 -d /tmp/tigervnc/unix/xserver < /tmp/tigervnc/unix/xserver120.patch

SCRIPT_DIR=/build
# # Build a static binary of vncpasswd.
# patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/vncpasswd-static.patch
# # Disable PAM support.
# patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/disable-pam.patch
# # Fix static build.
# patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/static-build.patch
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/tigervnc-1.12.0-configuration_fixes-1.patch

# root@VM-12-9-ubuntu:~# docker run -it --rm infrastlabs/x11-base:ubt-builder bash

cd /tmp/tigervnc && cmake -G "Unix Makefiles" \
    $(xx-clang --print-cmake-defines) \
    -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    \
    -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_SYSTEMD_UNITS=OFF \
    -DBUILD_VIEWER=OFF \
    -DENABLE_NLS=OFF \
    -DENABLE_GNUTLS=ON \
    -DENABLE_NETTLE=ON 
# OK

cd /tmp/tigervnc
log "Compiling TigerVNC common libraries and tools..."
make -C /tmp/tigervnc/common -j$(nproc)
make -C /tmp/tigervnc/unix/common -j$(nproc)
make -C /tmp/tigervnc/unix/vncpasswd -j$(nproc)
#OK

# xserver
log "Configuring TigerVNC server..."
autoreconf -fiv /tmp/tigervnc/unix/xserver
cd /tmp/tigervnc/unix/xserver && CFLAGS="$CFLAGS -Wno-implicit-function-declaration" ./configure \
    --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
    --host=$(xx-clang --print-target-triple) \
    --prefix=/usr \
    --sysconfdir=/etc/X11 --localstatedir=/var \
    --with-xkb-path=${TARGETPATH}/share/X11/xkb \
    --with-xkb-output=/var/lib/xkb \
    --with-xkb-bin-directory=${TARGETPATH}/bin \
    --with-default-font-path=/usr/share/fonts/misc,/usr/share/fonts/100dpi:unscaled,/usr/share/fonts/75dpi:unscaled,/usr/share/fonts/TTF,/usr/share/fonts/Type1 \
    \
    --disable-docs \
    --disable-unit-tests \
    --without-dtrace \
    \
    --with-pic \
    --disable-static \
    --disable-shared \
    \
    --disable-listen-tcp --enable-listen-unix \
    --disable-listen-local --disable-dpms \
    \
    --disable-systemd-logind \
    --disable-config-hal \
    --disable-config-udev \
    --disable-xorg --disable-xvfb \
    --disable-glx --disable-dmx --disable-libdrm \
    --disable-dri --disable-dri2 --disable-dri3 \
    --disable-present --disable-xinerama --disable-record \
    --disable-xf86vidmode --disable-xnest \
    --disable-xquartz \
    --disable-xwayland --disable-xwayland-eglstream \
    --disable-standalone-xpbproxy \
    --disable-xwin --disable-glamor \
    --disable-kdrive --disable-xephyr 
# OK

###Remove all automatic dependencies.
# find /tmp/tigervnc -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'
# sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i /tmp/tigervnc/unix/xserver/hw/vnc/Makefile

log "Compiling TigerVNC server..."
make -C /tmp/tigervnc/unix/xserver -j$(nproc)

# log "Installing TigerVNC server..."
# make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/xserver install
# make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/vncpasswd install




# libz错误(with sed-static)
# root@e0dd2368ee99:/tmp/tigervnc/unix/xserver# dpkg -l |grep libz
ii  libz3-4:amd64                  4.8.7-4build1                     amd64        theorem prover from Microsoft Research - runtime libraries
ii  libz3-dev:amd64                4.8.7-4build1                     amd64        theorem prover from Microsoft Research - development files
ii  libzstd1:amd64                 1.4.4+dfsg-3ubuntu0.1             amd64        fast lossless compression algorithm
ii  libzvbi-common                 0.2.35-17                         all          Vertical Blanking Interval decoder (VBI) - common files
ii  libzvbi0:amd64                 0.2.35-17                         amd64        Vertical Blanking Interval decoder (VBI) - runtime files
root@e0dd2368ee99:/tmp/tigervnc/unix/xserver# 
```

- **try4: 注释sed操作,再make-Xvnc** OK

VER: 1.22.14> 1.20.7

```bash
# root@597833a80fd4:/tmp/tigervnc/unix/xserver# make -C /tmp/tigervnc/unix/xserver -j$(nproc)
cc1plus: warning: command line option '-Wdeclaration-after-statement' is valid for C/ObjC but not for C++
cc1plus: warning: '-Werror=' argument '-Werror=implicit' is not valid for C++
cc1plus: warning: '-Werror=' argument '-Werror=pointer-to-int-cast' is not valid for C++
  CC       libvnccommon_la-vncInput.lo
  CC       libvnccommon_la-vncInputXKB.lo
  CC       libvnccommon_la-qnum_to_xorgevdev.lo
  CC       libvnccommon_la-qnum_to_xorgkbd.lo
  CC       libvnc_la-vncModule.lo
  CXXLD    libvnccommon.la
  CXXLD    libvnc.la
  CXXLD    Xvnc
make[2]: Leaving directory '/tmp/tigervnc/unix/xserver/hw/vnc'
make[2]: Entering directory '/tmp/tigervnc/unix/xserver/hw'
make[2]: Nothing to be done for 'all-am'.
make[2]: Leaving directory '/tmp/tigervnc/unix/xserver/hw'
make[1]: Leaving directory '/tmp/tigervnc/unix/xserver/hw'
Making all in test
make[1]: Entering directory '/tmp/tigervnc/unix/xserver/test'
make  all-recursive
make[2]: Entering directory '/tmp/tigervnc/unix/xserver/test'
make[3]: Entering directory '/tmp/tigervnc/unix/xserver/test'
make[3]: Nothing to be done for 'all-am'.
make[3]: Leaving directory '/tmp/tigervnc/unix/xserver/test'
make[2]: Leaving directory '/tmp/tigervnc/unix/xserver/test'
make[1]: Leaving directory '/tmp/tigervnc/unix/xserver/test'
make[1]: Entering directory '/tmp/tigervnc/unix/xserver'
make[1]: Nothing to be done for 'all-am'.
make[1]: Leaving directory '/tmp/tigervnc/unix/xserver'
make: Leaving directory '/tmp/tigervnc/unix/xserver'
root@597833a80fd4:/tmp/tigervnc/unix/xserver# echo $?
0
# root@597833a80fd4:/tmp/tigervnc/unix/xserver# find hw/vnc/ |grep Xvnc
hw/vnc/Xvnc-fbcmap_mi.o
hw/vnc/Xvnc-xvnc.o
hw/vnc/.deps/Xvnc-fbcmap_mi.Po
hw/vnc/.deps/Xvnc-dummy.Po
hw/vnc/.deps/Xvnc-xvnc.Po
hw/vnc/.deps/Xvnc-buildtime.Po
hw/vnc/.deps/Xvnc-stubs.Po
hw/vnc/.deps/Xvnc-miinitext.Po
hw/vnc/Xvnc-stubs.o
hw/vnc/Xvnc-miinitext.o
hw/vnc/Xvnc
hw/vnc/Xvnc.man
hw/vnc/Xvnc-buildtime.o
# root@597833a80fd4:/tmp/tigervnc/unix/xserver# hw/vnc/Xvnc -version

Xvnc TigerVNC 1.12.0 - built Oct 20 2023 08:53:06
Copyright (C) 1999-2021 TigerVNC Team and many others (see README.rst)
See https://www.tigervnc.org for information on TigerVNC.
Underlying X server release 12007000, The X.Org Foundation
```

- try5: linux/arm (ubt2004:同core-compile, 一样不行)

```bash
# root@6db5c0361708:/tmp/tigervnc# cd /tmp/tigervnc && cmake -G "Unix Makefiles"     $(xx-clang --print-cmake-defines)     -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot)  ...
-- Check for working C compiler: /usr/local/bin/clang
-- Check for working C compiler: /usr/local/bin/clang -- works
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working CXX compiler: /usr/local/bin/clang++
-- Check for working CXX compiler: /usr/local/bin/clang++ -- works
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- CMAKE_BUILD_TYPE = Release
-- VERSION = 1.12.0
-- BUILD_TIMESTAMP = 2023-10-20 09:36
-- 32-bit build
CMake Error at /usr/share/cmake-3.16/Modules/FindPackageHandleStandardArgs.cmake:146 (message):
  Could NOT find X11 (missing: X11_X11_LIB)
Call Stack (most recent call first):
  /usr/share/cmake-3.16/Modules/FindPackageHandleStandardArgs.cmake:393 (_FPHSA_FAILURE_MESSAGE)
  /usr/share/cmake-3.16/Modules/FindX11.cmake:366 (find_package_handle_standard_args)
  CMakeLists.txt:144 (find_package)


-- Configuring incomplete, errors occurred!
See also "/tmp/tigervnc/CMakeFiles/CMakeOutput.log".
See also "/tmp/tigervnc/CMakeFiles/CMakeError.log".

# root@6db5c0361708:/tmp/tigervnc# cat /tmp/tigervnc/CMakeFiles/CMakeError.log

Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/local/bin/clang 
Build flags: 
Id flags: -c 

The output was:
1
CMakeCCompilerId.c:20:51: error: expected ';' after top level declarator
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
                                                  ^
                                                  ;
1 error generated.


Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/local/bin/clang 
Build flags: 
Id flags: -Aa 

The output was:
1
clang: warning: argument unused during compilation: '-Aa' [-Wunused-command-line-argument]
CMakeCCompilerId.c:20:51: error: expected ';' after top level declarator
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
                                                  ^
                                                  ;
1 error generated.


Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/local/bin/clang 
Build flags: 
Id flags: -D__CLASSIC_C__ 

The output was:
1
CMakeCCompilerId.c:20:51: error: expected ';' after top level declarator
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
                 
                                                  ;
1 error generated.


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/local/bin/clang++ 
Build flags: 
Id flags: -c 

The output was:
1
CMakeCXXCompilerId.cpp:14:51: error: expected ';' after top level declarator
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
                                                  ^
                                                  ;
1 error generated.


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/local/bin/clang++ 
Build flags: 
Id flags: --c++ 

The output was:
1
clang: error: unsupported option '--c++'


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/local/bin/clang++ 
Build flags: 
Id flags: --ec++ 

The output was:
1
clang: error: unsupported option '--ec++'


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/local/bin/clang++ 
Build flags: 
Id flags: --target=arm-arm-none-eabi;-mcpu=cortex-m3 

The output was:
1
CMakeCXXCompilerId.cpp:14:51: error: expected ';' after top level declarator
char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
                                                  ^
                                                  ;
1 error generated.


Checking whether the CXX compiler is IAR using "" did not match "IAR .+ Compiler":
clang: error: no input files
Checking whether the CXX compiler is IAR using "" did not match "IAR .+ Compiler":
clang: error: no input files
root@6db5c0361708:/tmp/tigervnc# 
```

### ubt's docker-headless:core-compile

- **try-b1: ubt's build-cmds** OK

```bash
# err libnetwork.la
# root@VM-12-9-ubuntu:/opt/working/_ee/ubt-armv7/ubt-core# docker run -it --rm -v $(pwd)/src/arm:/src/arm infrastlabs/docker-headless:core-compile
# cd /tmp/tigervnc

apt update; apt install -y \
  cmake libfltk1.3-dev libxi-dev libxshmfence-dev \
  libxcb-dri3-0 \
  libdrm-dev libxfont-dev mesa-common-dev \
  libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev

# pre
cd /src/arm
  mkdir -p /build; \
  tar -zxf tigervnc-1.12.0.tar.gz -C /build/; \
  tar -jxf xorg-server-1.20.7.tar.bz2 --strip-components=1 -C /build/tigervnc-1.12.0/unix/xserver/; \
  \cp -a tigervnc-1.12.0-configuration_fixes-1.patch /build/;

cd /build/tigervnc-1.12.0 
  patch -Np1 -i ../tigervnc-1.12.0-configuration_fixes-1.patch; \
  cd unix/xserver && patch -Np1 -i ../xserver120.patch;

# build01
cd /build/tigervnc-1.12.0
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr \
    -DBUILD_VIEWER=false \
    -DCMAKE_BUILD_TYPE=Release -DINSTALL_SYSTEMD_UNITS=OFF -Wno-dev .

# make
make -C /build/tigervnc-1.12.0/common -j$(nproc)
make -C /build/tigervnc-1.12.0/unix/common -j$(nproc)
make -C /build/tigervnc-1.12.0/unix/vncpasswd -j$(nproc)


# build02
cd  /build/tigervnc-1.12.0/unix/xserver; \
autoreconf -fiv; \
CPPFLAGS="-I/usr/include/drm"       \
./configure $XORG_CONFIG            \
    --prefix=/usr/local/tigervnc \
    \
    --sysconfdir=/etc/X11 \
    --localstatedir=/var \
    --with-xkb-path=/usr/share/X11/xkb \
    --with-xkb-output=/var/lib/xkb \
    --with-xkb-bin-directory=/usr/bin \
    \
    --disable-xwayland                         --disable-dmx         \
    --disable-xorg        --disable-xnest      --disable-xvfb        \
    --disable-xwin        --disable-xephyr     --disable-kdrive      \
    --disable-devel-docs  --disable-config-hal --disable-config-udev \
    --disable-unit-tests  --disable-selective-werror                 \
    --disable-dri         --disable-dri3       --enable-dri2         \
    --with-pic \
    --without-dtrace

# make
# log "Compiling TigerVNC server..."
make -C /build/tigervnc-1.12.0/unix/xserver -j$(nproc)



###TRY2: Remove all automatic dependencies.
find /build/tigervnc-1.12.0 -name "*.la" |sort
find /build/tigervnc-1.12.0 -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'

mkfile=/build/tigervnc-1.12.0/unix/xserver/hw/vnc/Makefile
test -s ${mkfile}_bk1 && echo skip_bk || cat $mkfile > ${mkfile}_bk1
sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $mkfile

make -C /build/tigervnc-1.12.0/unix/xserver -j$(nproc)
# make[2]: Entering directory '/build/tigervnc-1.12.0/unix/xserver/hw/vnc'
#   CXXLD    Xvnc
# /usr/bin/ld: cannot find -lbrotlidec
# /usr/bin/ld: cannot find -lbrotlicommon
# /usr/bin/ld: cannot find -lbz2
# /usr/bin/ld: cannot find -lgnutls
# /usr/bin/ld: cannot find -lhogweed
# /usr/bin/ld: cannot find -lgmp
# /usr/bin/ld: cannot find -lnettle
# /usr/bin/ld: cannot find -lunistring
# /usr/bin/ld: cannot find -ltasn1
# /usr/bin/ld: cannot find -lbsd
# /usr/bin/ld: cannot find -lmd
# collect2: error: ld returned 1 exit status
```

- **try-b2: linux/arm** (missing: X11_X11_LIB),C++错误

```bash
# binfmt
docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d
  ls -al /proc/sys/fs/binfmt_misc/
  cat /proc/sys/fs/binfmt_misc/qemu-aarch64
# root@VM-12-9-ubuntu:/opt/working/_ee/ubt-armv7/ubt-core# docker run -it --rm --platform=linux/arm -v $(pwd)/src/arm:/src/arm infrastlabs/docker-headless:core-compile

# build01:
# linux/arm:
# CMake Error at /usr/share/cmake-3.16/Modules/FindPackageHandleStandardArgs.cmake:146 (message):
#   Could NOT find X11 (missing: X11_X11_LIB)

# ref deb12:
# armv7l
export CMAKE_LIBRARY_ARCHITECTURE=x86_64-linux-gnu;
export CMAKE_LIBRARY_ARCHITECTURE=armv7l-linux-gnu;


# deb12: Could NOT find X11 (missing: X11_X11_LIB)
#  X11_X11_LIB: +xorg-dev ##依旧不行

```

```bash
# root@5cbc626acfff:/build/tigervnc-1.12.0# cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr \
>     -DBUILD_VIEWER=false \
>     -DCMAKE_BUILD_TYPE=Release -DINSTALL_SYSTEMD_UNITS=OFF -Wno-dev .
-- CMAKE_BUILD_TYPE = Release
-- VERSION = 1.12.0
-- BUILD_TIMESTAMP = 2023-10-20 08:22
-- 32-bit build
CMake Error at /usr/share/cmake-3.16/Modules/FindPackageHandleStandardArgs.cmake:146 (message):
  Could NOT find X11 (missing: X11_X11_LIB)
Call Stack (most recent call first):
  /usr/share/cmake-3.16/Modules/FindPackageHandleStandardArgs.cmake:393 (_FPHSA_FAILURE_MESSAGE)
  /usr/share/cmake-3.16/Modules/FindX11.cmake:366 (find_package_handle_standard_args)
  CMakeLists.txt:144 (find_package)


-- Configuring incomplete, errors occurred!
See also "/build/tigervnc-1.12.0/CMakeFiles/CMakeOutput.log".
See also "/build/tigervnc-1.12.0/CMakeFiles/CMakeError.log".
root@5cbc626acfff:/build/tigervnc-1.12.0# 
# root@5cbc626acfff:/build/tigervnc-1.12.0# cat /build/tigervnc-1.12.0/CMakeFiles/CMakeError.log
Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/bin/cc 
Build flags: 
Id flags:  

The output was:
1
CMakeCCompilerId.c:20:52: error: expected ',' or ';' before 'COMPILER_ID'
   20 | char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
      |                                                    ^~~~~~~~~~~


Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/bin/cc 
Build flags: 
Id flags: -c 

The output was:
1
CMakeCCompilerId.c:20:52: error: expected ',' or ';' before 'COMPILER_ID'
   20 | char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
      |                                                    ^~~~~~~~~~~


Compiling the C compiler identification source file "CMakeCCompilerId.c" failed.
Compiler: /usr/bin/cc 
Build flags: 
Id flags: -Aa 

The output was:
1
<command-line>: error: missing '(' after predicate
CMakeCCompilerId.c:20:52: error: expected ',' or ';' before 'COMPILER_ID'
   20 | char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
Compiler: /usr/bin/c++ 
Build flags: 
Id flags:  

The output was:
1
CMakeCXXCompilerId.cpp:14:52: error: expected ',' or ';' before 'COMPILER_ID'
   14 | char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
      |                                                    ^~~~~~~~~~~


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: -c 

The output was:
1
CMakeCXXCompilerId.cpp:14:52: error: expected ',' or ';' before 'COMPILER_ID'
   14 | char const* info_compiler = "INFO" ":" "compiler[" COMPILER_ID "]";
      |                                                    ^~~~~~~~~~~


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: --c++ 

The output was:
1
c++: error: unrecognized command line option '--c++'


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: --ec++ 

The output 


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: --c++ 

The output was:
1
c++: error: unrecognized command line option '--c++'


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: --ec++ 

The output was:
1
c++: error: unrecognized command line option '--ec++'; did you mean '-Weffc++'?


Compiling the CXX compiler identification source file "CMakeCXXCompilerId.cpp" failed.
Compiler: /usr/bin/c++ 
Build flags: 
Id flags: --target=arm-arm-none-eabi;-mcpu=cortex-m3 

The output was:
1
c++: error: unrecognized command line option '--target=arm-arm-none-eabi'


Checking whether the CXX compiler is IAR using "" did not match "IAR .+ Compiler":
c++: fatal error: no input files
compilation terminated.
Checking whether the CXX compiler is IAR using "" did not match "IAR .+ Compiler":
c++: fatal error: no input files
compilation terminated.
# root@5cbc626acfff:/build/tigervnc-1.12.0# /usr/bin/c++ -h
c++: error: missing argument to '-h'
c++: fatal error: no input files
compilation terminated.
# root@5cbc626acfff:/build/tigervnc-1.12.0# dpkg -l |grep gcc
ii  gcc                                  4:9.3.0-1ubuntu2                  armhf        GNU C compiler
ii  gcc-10-base:armhf                    10.5.0-1ubuntu1~20.04             armhf        GCC, the GNU Compiler Collection (base package)
ii  gcc-9                                9.4.0-1ubuntu1~20.04.2            armhf        GNU C compiler
ii  gcc-9-base:armhf                     9.4.0-1ubuntu1~20.04.2            armhf        GCC, the GNU Compiler Collection (base package)
ii  libgcc-9-dev:armhf                   9.4.0-1ubuntu1~20.04.2            armhf        GCC support library (development files)
ii  libgcc-s1:armhf                      10.5.0-1ubuntu1~20.04             armhf        GCC support library
root@5cbc626acfff:/build/tigervnc-1.12.0# dpkg -l |grep g++
ii  g++                                  4:9.3.0-1ubuntu2                  armhf        GNU C++ compiler
ii  g++-9                                9.4.0-1ubuntu1~20.04.2            armhf        GNU C++ compiler
```

## deb12's compile

- **try-c1: linux/arm @deb12** (headless:deb12-compile)

```bash
# root@VM-12-9-ubuntu:/opt/working/_ee/ubt-armv7/ubt-core# docker run -it --rm --platform=linux/arm -v $(pwd)/src/arm:/src/arm infrastlabs/docker-headless:deb12-compile
Unable to find image 'infrastlabs/docker-headless:deb12-compile' locally
deb12-compile: Pulling from infrastlabs/docker-headless

apt update; apt install -y \
  cmake libfltk1.3-dev libxi-dev libxshmfence-dev \
  libxcb-dri3-0 \
  libdrm-dev libxfont-dev mesa-common-dev \
  libx11-dev libxext-dev libxrender-dev libxtst-dev libxt-dev

# pre
cd /src/arm
  mkdir -p /build; \
  tar -zxf tigervnc-1.12.0.tar.gz -C /build/; \
  tar -jxf xorg-server-1.20.7.tar.bz2 --strip-components=1 -C /build/tigervnc-1.12.0/unix/xserver/; \
  \cp -a tigervnc-1.12.0-configuration_fixes-1.patch /build/;

cd /build/tigervnc-1.12.0 
  patch -Np1 -i ../tigervnc-1.12.0-configuration_fixes-1.patch; \
  cd unix/xserver && patch -Np1 -i ../xserver120.patch;

# build01
# root@661d805f3814:/build/tigervnc-1.12.0# cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr     -DBUILD_VIEWER=false     -DCMAKE_BUILD_TYPE=Release -DINSTALL_SYSTEMD_UNITS=OFF -Wno-dev .
- Creating static libtool control file for target os
-- Creating static libtool control file for target rdr
-- Creating static libtool control file for target network
-- Creating static libtool control file for target rfb
-- Creating static libtool control file for target unixcommon
CMake Warning at unix/x0vncserver/CMakeLists.txt:36 (message):
  No DAMAGE extension.  x0vncserver will have to use the slower polling
  method.


-- Configuring done
-- Generating done
-- Build files have been written to: /build/tigervnc-1.12.0
root@661d805f3814:/build/tigervnc-1.12.0# 
root@661d805f3814:/build/tigervnc-1.12.0# echo $?
0
# OK

# make
make -C /build/tigervnc-1.12.0/common -j$(nproc)
make -C /build/tigervnc-1.12.0/unix/common -j$(nproc)
make -C /build/tigervnc-1.12.0/unix/vncpasswd -j$(nproc)
# OK

# build02
cd  /build/tigervnc-1.12.0/unix/xserver; \
autoreconf -fiv; \
CPPFLAGS="-I/usr/include/drm"       \
./configure $XORG_CONFIG            \
    --prefix=/usr/local/tigervnc \
    \
    --sysconfdir=/etc/X11 \
    --localstatedir=/var \
    --with-xkb-path=/usr/share/X11/xkb \
    --with-xkb-output=/var/lib/xkb \
    --with-xkb-bin-directory=/usr/bin \
    \
    --disable-xwayland                         --disable-dmx         \
    --disable-xorg        --disable-xnest      --disable-xvfb        \
    --disable-xwin        --disable-xephyr     --disable-kdrive      \
    --disable-devel-docs  --disable-config-hal --disable-config-udev \
    --disable-unit-tests  --disable-selective-werror                 \
    --disable-dri         --disable-dri3       --enable-dri2         \
    --with-pic \
    --without-dtrace
# OK

# make
# log "Compiling TigerVNC server..."
make -C /build/tigervnc-1.12.0/unix/xserver -j$(nproc)

```

- **try-c2: deb12-clang-build** (x11-base:deb12-builder)

VER: 1.22.14> 1.20.7

1.20.7 ok|> 1.22.14(try_staitc)

```bash
# tiger/build.sh
# TIGERVNC_VERSION=1.12.0
# XSERVER_VERSION=1.20.7
TIGERVNC_VERSION=1.13.1
XSERVER_VERSION=1.20.14
TIGERVNC_URL=https://ghproxy.com/https://github.com/TigerVNC/tigervnc/archive/v${TIGERVNC_VERSION}.tar.gz
XSERVER_URL=https://www.x.org/releases/individual/xserver/xorg-server-${XSERVER_VERSION}.tar.gz

# test -z "$TARGETPATH" && export TARGETPATH=/opt/base
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f /mnt/$file || curl -# -k -fSL $url > /mnt/$file
  cat /mnt/$file
}
mkdir -p /tmp/tigervnc
down_catfile ${TIGERVNC_URL} | tar -xz --strip 1 -C /tmp/tigervnc
down_catfile ${XSERVER_URL} | tar -xz --strip 1 -C /tmp/tigervnc/unix/xserver

log "Patching TigerVNC..."
# Apply the TigerVNC patch against the X server.
patch -p1 -d /tmp/tigervnc/unix/xserver < /tmp/tigervnc/unix/xserver120.patch

SCRIPT_DIR=/build
# Build a static binary of vncpasswd.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/vncpasswd-static.patch
# Disable PAM support.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/disable-pam.patch
# Fix static build.
f1=/tmp/tigervnc/CMakeLists.txt
test -s ${f1}_bk1 || cat $f1 > ${f1}_bk1
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/static-build.patch
# patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/tigervnc-1.12.0-configuration_fixes-1.patch

# root@VM-12-9-ubuntu:~# docker run -it --rm infrastlabs/x11-base:ubt-builder bash

cd /tmp/tigervnc && cmake -G "Unix Makefiles" \
    $(xx-clang --print-cmake-defines) \
    -DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot) \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
    -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
    \
    -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release \
    -DINSTALL_SYSTEMD_UNITS=OFF \
    -DBUILD_VIEWER=OFF \
    -DENABLE_NLS=OFF \
    -DENABLE_GNUTLS=OFF \
    -DENABLE_NETTLE=ON 
   #  -DENABLE_GNUTLS=ON \
   #  -DENABLE_NETTLE=ON  #librfb must ON
# OK

cd /tmp/tigervnc
# log "Compiling TigerVNC common libraries and tools..."
make -C /tmp/tigervnc/common -j$(nproc)
make -C /tmp/tigervnc/unix/common -j$(nproc)
make -C /tmp/tigervnc/unix/vncpasswd -j$(nproc)
#OK

# xserver
# log "Configuring TigerVNC server..."
autoreconf -fiv /tmp/tigervnc/unix/xserver
cd /tmp/tigervnc/unix/xserver && CFLAGS="$CFLAGS -Wno-implicit-function-declaration" ./configure \
    --build=$(TARGETPLATFORM= xx-clang --print-target-triple) \
    --host=$(xx-clang --print-target-triple) \
    --prefix=/usr \
    --sysconfdir=/etc/X11 --localstatedir=/var \
    --with-xkb-path=${TARGETPATH}/share/X11/xkb \
    --with-xkb-output=/var/lib/xkb \
    --with-xkb-bin-directory=${TARGETPATH}/bin \
    --with-default-font-path=/usr/share/fonts/misc,/usr/share/fonts/100dpi:unscaled,/usr/share/fonts/75dpi:unscaled,/usr/share/fonts/TTF,/usr/share/fonts/Type1 \
    \
    --disable-docs \
    --disable-unit-tests \
    --without-dtrace \
    \
    --with-pic \
    --disable-static \
    --disable-shared \
    \
    --disable-listen-tcp --enable-listen-unix \
    --disable-listen-local --disable-dpms \
    \
    --disable-systemd-logind \
    --disable-config-hal \
    --disable-config-udev \
    --disable-xorg --disable-xvfb \
    --disable-glx --disable-dmx --disable-libdrm \
    --disable-dri --disable-dri2 --disable-dri3 \
    --disable-present --disable-xinerama --disable-record \
    --disable-xf86vidmode --disable-xnest \
    --disable-xquartz \
    --disable-xwayland --disable-xwayland-eglstream \
    --disable-standalone-xpbproxy \
    --disable-xwin --disable-glamor \
    --disable-kdrive --disable-xephyr 
# OK

###Remove all automatic dependencies.
find /tmp/tigervnc -name "*.la" |sort
find /tmp/tigervnc -name "*.la" |while read one; do echo -n "${one##*/}| "; cat $one |grep "^dependency_libs"; done |grep -v "=' -l"
find /tmp/tigervnc -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'


mkfile=/tmp/tigervnc/unix/xserver/hw/vnc/Makefile
test -s ${mkfile}_bk1 && echo skip_bk || cat $mkfile > ${mkfile}_bk1
cat $mkfile  |grep XSERVER_SYS_LIBS
# XSERVER_SYS_LIBS = -lpixman-1 -lXfont2 -lXau -lXdmcp    -lm -lbsd 
# XSERVER_SYS_LIBS = -lpixman-1 -lXfont2 -lXau -lXdmcp    -lm -lbsd #1.20.14 same
sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $mkfile
# -lbrotlidec -lbrotlicommon 
sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $mkfile


# log "Compiling TigerVNC server..."
make -C /tmp/tigervnc/unix/xserver -j$(nproc)

# log "Installing TigerVNC server..."
# make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/xserver install
# make DESTDIR=/tmp/tigervnc-install -C /tmp/tigervnc/unix/vncpasswd install


```

- staticTry2@deb12

```bash
# 01
make -C /tmp/tigervnc/unix/xserver -j$(nproc) #一堆..gnutls> 找不到func

# 02
bash /build/build.sh b_deps
make -C /tmp/tigervnc/unix/xserver -j$(nproc) #一堆..gnutls> 找不到func(同样问题)

# ..delay

root@2a850dc0eca8:/# find /tmp -name "*.la" |sort
/tmp/gnutls/gl/.libs/libgnu.la
/tmp/gnutls/gl/libgnu.la
/tmp/gnutls/lib/.libs/libgnutls.la
/tmp/gnutls/lib/accelerated/.libs/libaccelerated.la
/tmp/gnutls/lib/accelerated/libaccelerated.la
/tmp/gnutls/lib/accelerated/x86/.libs/libx86.la
/tmp/gnutls/lib/accelerated/x86/libx86.la
/tmp/gnutls/lib/algorithms/.libs/libgnutls_alg.la
/tmp/gnutls/lib/algorithms/libgnutls_alg.la
/tmp/gnutls/lib/auth/.libs/libgnutls_auth.la
/tmp/gnutls/lib/auth/libgnutls_auth.la
/tmp/gnutls/lib/ext/.libs/libgnutls_ext.la
/tmp/gnutls/lib/ext/libgnutls_ext.la
/tmp/gnutls/lib/extras/.libs/libgnutls_extras.la
/tmp/gnutls/lib/extras/libgnutls_extras.la
/tmp/gnutls/lib/libgnutls.la
/tmp/gnutls/lib/nettle/.libs/libcrypto.la
/tmp/gnutls/lib/nettle/libcrypto.la
/tmp/gnutls/lib/x509/.libs/libgnutls_x509.la
/tmp/gnutls/lib/x509/libgnutls_x509.la
/tmp/gnutls/src/gl/.libs/libgnu_gpl.la
/tmp/gnutls/src/gl/libgnu_gpl.la
/tmp/libfontenc/src/.libs/libfontenc.la
/tmp/libfontenc/src/libfontenc.la
/tmp/libtasn1/lib/.libs/libtasn1.la
/tmp/libtasn1/lib/gl/.libs/libgnu.la
/tmp/libtasn1/lib/gl/libgnu.la
/tmp/libtasn1/lib/libtasn1.la
/tmp/libtasn1/src/gl/.libs/libsgl.la
/tmp/libtasn1/src/gl/libsgl.la
/tmp/libxfont2/.libs/libXfont2.la
/tmp/libxfont2/libXfont2.la
/tmp/libxshmfence/src/.libs/libxshmfence.la
/tmp/libxshmfence/src/libxshmfence.la


# v1.13.1:
# without static patch: build ok;
# with patch: same gnutls-func-err; (ubt2004一样, static_src包不对??)


# try031(static-build.patch):
# /tmp/tigervnc; cmake ...
    -DENABLE_GNUTLS=OFF \
    -DENABLE_NETTLE=ON


# 
find /tmp/tigervnc -name "*.la" -exec sed 's/^dependency_libs/#dependency_libs/' -i {} ';'
# root@8079dd943b72:/tmp/tigervnc/unix/xserver# make -C /tmp/tigervnc/unix/xserver -j$(nproc)
make[2]: Entering directory '/tmp/tigervnc/unix/xserver/hw/vnc'
  CXXLD    Xvnc
/usr/bin/ld: ../../../../common/rdr/.libs/librdr.a(ZlibInStream.cxx.o): undefined reference to symbol 'inflateEnd'
/usr/bin/ld: /lib/x86_64-linux-gnu/libz.so.1: error adding symbols: DSO missing from command line
collect2: error: ld returned 1 exit status
make[2]: *** [Makefile:852: Xvnc] Error 1
make[2]: Leaving directory '/tmp/tigervnc/unix/xserver/hw/vnc'
make[1]: *** [Makefile:627: all-recursive] Error 1
make[1]: Leaving directory '/tmp/tigervnc/unix/xserver/hw'
make: *** [Makefile:829: all-recursive] Error 1
make: Leaving directory '/tmp/tigervnc/unix/xserver'


#
# -lbrotlidec -lbrotlicommon 
sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i $mkfile
# root@8079dd943b72:/tmp/tigervnc/unix/xserver# make -C /tmp/tigervnc/unix/xserver -j$(nproc)
make[2]: Entering directory '/tmp/tigervnc/unix/xserver/hw/vnc'
  CXXLD    Xvnc
/usr/bin/ld: ../../../../common/rfb/.libs/librfb.a(pam.c.o): in function `do_pam_auth':
pam.c:(.text+0x39): undefined reference to `pam_start'
/usr/bin/ld: pam.c:(.text+0x4b): undefined reference to `pam_authenticate'
/usr/bin/ld: pam.c:(.text+0x5d): undefined reference to `pam_acct_mgmt'
/usr/bin/ld: pam.c:(.text+0x6b): undefined reference to `pam_end'
collect2: error: ld returned 1 exit status
make[2]: *** [Makefile:852: Xvnc] Error 1
make[2]: Leaving directory '/tmp/tigervnc/unix/xserver/hw/vnc'
make[1]: *** [Makefile:627: all-recursive] Error 1
make[1]: Leaving directory '/tmp/tigervnc/unix/xserver/hw'
make: *** [Makefile:829: all-recursive] Error 1
make: Leaving directory '/tmp/tigervnc/unix/xserver'


# try032(disable-pam.patch):
SCRIPT_DIR=/build
# Disable PAM support.
patch -p1 -d /tmp/tigervnc < "$SCRIPT_DIR"/disable-pam.patch

# disable-pam后: static 生成OK
# mark: +patch,改cmake参; make unix/xserver 可利用上之前构建文件|提速

```

- xkb fix build

```bash
# xkb;
XKEYBOARDCONFIG_VERSION=2.32
XKBCOMP_VERSION=1.4.5

XKEYBOARDCONFIG_URL=https://www.x.org/archive/individual/data/xkeyboard-config/xkeyboard-config-${XKEYBOARDCONFIG_VERSION}.tar.bz2
XKBCOMP_URL=https://www.x.org/releases/individual/app/xkbcomp-${XKBCOMP_VERSION}.tar.bz2
function down_catfile(){
  url=$1
  file=${url##*/}
  #curl -# -L -f 
  test -f /mnt/$file || curl -# -k -fSL $url > /mnt/$file
  cat /mnt/$file
}

mkdir -p /tmp/xkb
log "Downloading XKeyboardConfig..."
down_catfile ${XKEYBOARDCONFIG_URL} | tar -xj --strip 1 -C /tmp/xkb
log "Configuring XKeyboardConfig..."
(
    cd /tmp/xkb && abuild-meson . build
)
log "Compiling XKeyboardConfig..."
meson compile -C /tmp/xkb/build
log "Installing XKeyboardConfig..."
DESTDIR="/tmp/xkb-install" meson install --no-rebuild -C /tmp/xkb/build

```