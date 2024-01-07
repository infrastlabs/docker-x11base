

```bash
# xrdp
ver="0.9.23" #0.9.16
file=xrdp-${ver}.tar.gz; test -s $file || curl -k -O -fSL https://github.com/neutrinolabs/xrdp/releases/download/v${ver}/$file

# tiger
file=xorg-server-1.20.7.tar.bz2; test -s $file || curl -k -O -fSL https://www.x.org/pub/individual/xserver/$file #6.1M
file=tigervnc-1.12.0.tar.gz; test -s $file || curl -k -O -fSL https://github.com/TigerVNC/tigervnc/archive/v1.12.0/$file #1.5M
# curl -O -fsSL https://www.linuxfromscratch.org/patches/blfs/svn/tigervnc-1.12.0-configuration_fixes-1.patch
```

```dockerfile
###xrdp, xorgxrdp###############################################
FROM stage-base as stage-xrdp
ARG COMPILE_XRDP="yes"
#0.9.5 > 0.9.16 > 0.9.19(thunar@gemmi-deb11卡死)
# 0.9.16 > 0.9.23 #0.9.16@deb12: cc1-openssl3-warn-as-err
ENV ver="0.9.23"
# https://hub.fastgit.org/neutrinolabs/xrdp/wiki/Building-on-Debian-8
# configure: error: please install libfdk-aac-dev or fdk-aac-devel
    # --enable-tjpeg \
# ./configure --prefix=/usr/local/xrdp --enable-fuse --enable-mp3lame --enable-pixman;\
ADD src/arm /src/arm
# RUN wget https://github.com/neutrinolabs/xrdp/releases/download/v${ver}/xrdp-${ver}.tar.gz; \
RUN mkdir -p /usr/local/xrdp
RUN test "yes" != "$COMPILE_XRDP" && exit 0 || echo doMake; \
tar -zxf /src/arm/xrdp-${ver}.tar.gz;\
cd xrdp-${ver};\
./bootstrap;\
./configure \
    --prefix=/usr/local/xrdp \
    --enable-vsock \
    --enable-fdkaac \
    --enable-opus \
    --enable-fuse \
    --enable-mp3lame \
    --enable-pixman \
    CFLAGS='-Wno-format';\
make;\
make install;

#####git clone; xorgxrdp with xrdp --prefix, testOK;
# # gitee.com/g-system/xorgxrdp
# RUN git clone --branch br-0214 https://gitee.com/g-system/xorgxrdp;\
# cd xorgxrdp;\
# ./bootstrap;\
# CPPFLAGS="-I/usr/local/xrdp/include"  LDFLAGS="-L/usr/local/xrdp/lib" ./configure;\
# make;\
# sudo make install;

###pulseaudio-module-xrdp###############################################
# pulse-xrdp: git-latest
FROM stage-base as stage-pulse
ARG COMPILE_PULSE="yes"
#### pulseaudio-module-xrdp >> pulseaudio ver: 10.0
# RUN git submodule update --init --recursive
RUN mkdir -p /var/lib/xrdp-pulseaudio-installer; \
  \
  test "yes" != "$COMPILE_PULSE" && exit 0 || echo doMake; \
  apt update && apt build-dep -q -y pulseaudio && \
  cd /opt && apt source pulseaudio && \
  pulseaudio=$(pulseaudio --version | awk '{print $2}') && \
  cd /opt/pulseaudio-${pulseaudio} && ./configure
# RUN pulseaudio=$(pulseaudio --version); echo "pulseaudio: $pulseaudio"
# hand copy: /opt/pulseaudio-1.11/config.h +src/pulsecore
# https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
# https://gitee.com/g-system/pulseaudio-module-xrdp.git
RUN test "yes" != "$COMPILE_PULSE" && exit 0 || echo doMake; \
  cd /opt && git clone --branch v0.5 https://gitee.com/g-system/pulseaudio-module-xrdp.git && \
  cd /opt/pulseaudio-module-xrdp ;\
  pulseaudio=$(pulseaudio --version | awk '{print $2}') && echo "pulseaudio ver: $pulseaudio" && \
  ./bootstrap && ./configure PULSE_DIR="/opt/pulseaudio-${pulseaudio}"; \
  cp -a /opt/pulseaudio-${pulseaudio}/config.h . && cp -a /opt/pulseaudio-${pulseaudio}/src/pulsecore/ .; \
  make && \
  cd /opt/pulseaudio-module-xrdp/src/.libs && \
  install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so;

```

- **try static build**

```bash
root@0aca931e9512:/mnt2/xrdp-0.9.23# xx-verify --static /usr/local/xrdp/sbin/xrdp
# file /usr/local/xrdp/sbin/xrdp is not statically linked: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, BuildID[sha1]=1966725d48e83c4bb385775179bbdfe9f73257f3, for GNU/Linux 3.2.0, not stripped
root@0aca931e9512:/mnt2/xrdp-0.9.23# ls -lh  /usr/local/xrdp/sbin/     
total 476K
-rwxr-xr-x 1 root root 228K Oct 23 05:50 xrdp
-rwxr-xr-x 1 root root 170K Oct 23 05:50 xrdp-chansrv
-rwxr-xr-x 1 root root  73K Oct 23 05:50 xrdp-sesman


# ref tiger/build.sh
# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"

unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

# CFLAGS="$CFLAGS -Wno-error=inline" 
./bootstrap;
./configure \
    --prefix=/usr/local/xrdp \
    --enable-vsock \
    --enable-fdkaac \
    --enable-opus \
    --enable-fuse \
    --enable-mp3lame \
    --enable-pixman \
    --enable-static \
    --disable-pam \
    CFLAGS='-Wno-format';
    # CFLAGS='$CFLAGS -Wno-format'; #err

# root@0aca931e9512:/mnt2/xrdp-0.9.23# ./configure     --prefix=/usr/local/xrdp     --enable-vsock     --enable-fdkaac     --enable-opus     --enable-fuse     --enable-mp3lame     --enable-pixman
checking how to run the C preprocessor... gcc -E
checking for X... no
configure: error: please install libx11-dev or libX11-devel
# root@0aca931e9512:/mnt2/xrdp-0.9.23# apt install libx11-dev
libx11-dev is already the newest version (2:1.8.4-2+deb12u2).

# root@0aca931e9512:/mnt2/xrdp-0.9.23# ./configure \
# >     --prefix=/usr/local/xrdp \
# >     --enable-vsock \
# >     --enable-fdkaac \
# >     --enable-opus \
# >     --enable-fuse \
# >     --enable-mp3lame \
# >     --enable-pixman \
# >     CFLAGS='$CFLAGS -Wno-format';
checking whether the C compiler works... no
configure: error: in `/mnt2/xrdp-0.9.23':
configure: error: C compiler cannot create executables
See `config.log' for more details


unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
# root@0aca931e9512:/mnt2/xrdp-0.9.23# ./configure     --prefix=/usr/local/xrdp     --enable-vsock     --enable-fdkaac     --enable-opus     --enable-fuse     --enable-mp3lame     --enable-pixman     CFLAGS='-Wno-format';
xrdp will be compiled with:
  mp3lame                 yes
  opus                    yes
  fdkaac                  yes
  jpeg                    no
  turbo jpeg              no
  rfxcodec                yes
  painter                 yes
  pixman                  yes
  fuse                    yes
  ipv6                    no
  ipv6only                no
  vsock                   yes
  auth mechanism          PAM
  rdpsndaudin             no

  with imlib2             no

  development logging     no
  development streamcheck no

  strict_locations        no
  prefix                  /usr/local/xrdp
  exec_prefix             ${prefix}
  libdir                  ${exec_prefix}/lib
  bindir                  ${exec_prefix}/bin
  sysconfdir              /etc
  pamconfdir              /etc/pam.d

  unit tests performable  yes

  CFLAGS = -Wno-format -Wall -Wwrite-strings -Werror -O2
  LDFLAGS = 
root@0aca931e9512:/mnt2/xrdp-0.9.23# echo $?
0

# 
make;
make install;
```

- ref args

```bash
# https://github.com/PWN-Term/pwn-packages/blob/df4740ecf3dc3433c869abd515964e60dea7dd0c/packages/xrdp/build.sh
    # --enable-static \
    # --disable-pam

# https://github.com/gdsotirov/xrdp.SlackBuild/blob/7a80aa9d328a21525948266863baf4cc4171f3f8/xrdp.SlackBuild#L66
CONFFLAGS=" --build="${ARCH}-slackware-linux" \
            --host="${ARCH}-slackware-linux" \
            --prefix=/usr \
            --libdir=/usr/lib${LIBDIRSUFFIX} \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --docdir=/usr/doc \
            --mandir=/usr/man \
            --disable-silent-rules \
            --disable-dependency-tracking"
#           --enable-xrdpvr      # Slackware is not supported
#           --enable-neutrinordp # Not available for Slackware
CFLAGS="$SLKCFLAGS" \
CXXFLAGS="$SLKCFLAGS" \
./configure ${CONFFLAGS} \
            --enable-shared=yes \
            --enable-static=no \
            --enable-ipv6 \
            --enable-jpeg \
            --enable-tjpeg \
            --enable-fuse \
            --enable-opus \
            --enable-mp3lame \
            --enable-pixman \
            --enable-painter \
            --enable-rfxcodec || exit 60

```