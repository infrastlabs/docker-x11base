ARG COMPILE_IMG=alpine-compile
FROM infrastlabs/x11-base:alpine-builder-gtk224 AS base
  ARG TARGETPLATFORM
  ENV CACHE=/usr/local/static/.cache
  RUN apk update; apk add gawk git;
  ##Close SSL Verify, for hubProxy's clone; ref x-pulseaudio/build.sh
  RUN git config --global http.sslVerify false
  # COPY --from=compile /rootfs${CACHE} ${CACHE}
  COPY ./src /src
  RUN chmod +x /src/**/*.sh; \
    ls -lh /src/**/*.sh

# --platform=$BUILDPLATFORM 
FROM base AS tiger
ARG COMPILE_TIGER="yes"
ENV TARGETPATH=/usr/local/static/tigervnc
RUN mkdir -p $TARGETPATH; \
  sh /src/x-tigervnc/build.sh cache; \
  \
  # https://blog.csdn.net/sodaloveer/article/details/127727729 #wait并行
  test "yes" != "$COMPILE_TIGER" && exit 0 || echo doMake; \
  sh /src/x-tigervnc/build.sh b_deps; \
  sh /src/x-tigervnc/build.sh b_tiger; \
  \
  find ${TARGETPATH} -type f |sort
  # xx-verify --static ${TARGETPATH}/bin/Xvnc; \
  # xx-verify --static ${TARGETPATH}/bin/vncpasswd; \
  # upx ${TARGETPATH}/bin/Xvnc; \
  # upx ${TARGETPATH}/bin/vncpasswd
# validate
# RUN du -sh /rootfs; \
#   /rootfs/usr/bin/Xvnc -version; \
#   find /rootfs -type f |sort

# Build xdpyprobe.
# Used to determine if the X server (Xvnc) is ready.
# FROM infrastlabs/x11-base:builder AS xdpyprobe
# ARG TARGETPLATFORM
COPY src/xdpyprobe /tmp/xdpyprobe
# RUN apk --no-cache add make clang
# RUN xx-apk --no-cache add gcc musl-dev libx11-dev libx11-static libxcb-static
# 
RUN \
  CC=xx-clang make -C /tmp/xdpyprobe; \
  xx-verify --static /tmp/xdpyprobe/xdpyprobe; \
  upx /tmp/xdpyprobe/xdpyprobe



FROM base AS xrdp
ARG COMPILE_XRDP="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xrdp
## build.sh: split multi steps, to speed up
RUN mkdir -p $TARGETPATH; \
  sh /src/x-xrdp/build.sh cache; \
  \
  test "yes" != "$COMPILE_XRDP" && exit 0 || echo doMake; \
  sh /src/x-xrdp/build.sh b_deps; \
  sh /src/x-xrdp/build.sh xrdp; \
  \
  find ${TARGETPATH} -type f |sort;
  # xx-verify --static ${TARGETPATH}/sbin/xrdp; \
  # xx-verify --static ${TARGETPATH}/sbin/xrdp-chansrv; \
  # upx ${TARGETPATH}/sbin/xrdp; \
  # upx ${TARGETPATH}/sbin/xrdp-chansrv
# xrdp-mods-cut
# RUN mkdir -p $TARGETPATH/etc/xrdp;

FROM base AS dropbear
ARG COMPILE_SSH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/dropbear
RUN mkdir -p $TARGETPATH; \
  # sh /src/x-dropbear/build.sh cache; \
  \
  test "yes" != "$COMPILE_SSH" && exit 0 || echo doMake; \
  sh /src/x-dropbear/build.sh dropbear; \
  \
  find ${TARGETPATH} -type f |sort; 

FROM base AS pulseaudio
ARG COMPILE_PULSE="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/pulseaudio
RUN mkdir -p $TARGETPATH; \
  # sh /src/x-dropbear/build.sh cache; \
  \
  test "yes" != "$COMPILE_PULSE" && exit 0 || echo doMake; \
  sh /src/x-pulseaudio/build.sh b_deps; \
  sh /src/x-pulseaudio/build.sh pulseaudio; \
  \
  find ${TARGETPATH} -type f |sort; 

FROM base AS fluxbox
ARG COMPILE_FLUX="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/fluxbox
RUN mkdir -p $TARGETPATH; \
  # sh /src/fluxbox/build.sh cache; \
  \
  test "yes" != "$COMPILE_FLUX" && exit 0 || echo doMake; \
  sh /src/x-xrdp/build.sh libxrandr; \
  # sh /src/fluxbox/build.sh fluxbox; \
    export TARGETPATH=/usr; \
    bash /src/_ex/fontconfig/build.sh ; \
    # bash _ex/fontconfig/build.sh
    cp /tmp/fontconfig-install/usr/lib/libfontconfig.a /usr/lib/; \
    export TARGETPATH=/usr/local/static/fluxbox; \
    bash /src/fluxbox/build.sh.xft.sh fluxbox; \
  \
  find ${TARGETPATH} -type f |sort; 

FROM base AS suckless
ARG COMPILE_SUCKLESS="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/suckless
RUN mkdir -p $TARGETPATH; \
  # sh /src/suckless/build.sh cache; \
  \
  test "yes" != "$COMPILE_SUCKLESS" && exit 0 || echo doMake; \
  sh /src/suckless/build.sh st; \
  sh /src/suckless/build.sh dwm; \
  sh /src/suckless/build.sh dmenu; \
  \
  find ${TARGETPATH} -type f |sort;


# Build Openbox.
# FROM infrastlabs/x11-base:builder AS openbox
FROM base AS openbox
ARG COMPILE_OPENBOX="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/openbox
# ARG TARGETPLATFORM
# COPY --from=fontconfig /tmp/fontconfig-install /tmp/fontconfig-install
# COPY src/openbox /tmp/build
# RUN /tmp/build/build.sh
RUN mkdir -p $TARGETPATH; \
  bash /src/openbox/build.sh cache; \
  \
  test "yes" != "$COMPILE_OPENBOX" && exit 0 || echo doMake; \
  # configure: error: C compiler cannot create executables
  bash /src/openbox/build.sh b_deps; \
  bash /src/openbox/build.sh openbox; \
  \
  # old:
  # bash /src/_ex/fontconfig/build.sh; \
  # bash /src/openbox/build.sh.bk1.sh; \
  \
  find ${TARGETPATH} -type f |sort;
# RUN xx-verify --static \
#     /tmp/openbox-install/usr/bin/openbox \
#     /tmp/openbox-install/usr/bin/obxprop
# RUN upx /tmp/openbox-install/usr/bin/openbox
# RUN upx /tmp/openbox-install/usr/bin/obxprop
# 
# RUN cp /tmp/openbox-install ${TARGETPATH}/; \
#   cp /tmp/fontconfig-install ${TARGETPATH}/; \
#   du -sh ${TARGETPATH}/*

# Build yad.
# FROM infrastlabs/x11-base:builder AS yad
# ARG TARGETPLATFORM
# COPY --from=fontconfig /tmp/fontconfig-install /tmp/fontconfig-install
# COPY src/yad/build.sh /tmp/build-yad.sh
# RUN /tmp/build-yad.sh
# RUN xx-verify --static /tmp/yad-install/usr/bin/yad
# RUN upx /tmp/yad-install/usr/bin/yad

# Build Fontconfig.
# FROM infrastlabs/x11-base:builder AS fontconfig
# ARG TARGETPLATFORM
# COPY src/fontconfig/build.sh /tmp/build-fontconfig.sh
# RUN /tmp/build-fontconfig.sh


# Build lxde
FROM base AS lxde
ARG COMPILE_LXDE="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/lxde
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-lxde/build.sh cache; \
  \
  test "yes" != "$COMPILE_LXDE" && exit 0 || echo doMake; \
  sh /src/v-lxde/build.sh lxappearance; \
  sh /src/v-lxde/build.sh lxtask; \
  \
  find ${TARGETPATH} -type f |sort;

# Build xlunch
FROM base AS xlunch
ARG COMPILE_XLUNCH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xlunch
RUN mkdir -p $TARGETPATH; \
  sh /src/v-xlunch/build.sh cache; \
  \
  test "yes" != "$COMPILE_XLUNCH" && exit 0 || echo doMake; \
  sh /src/v-xlunch/build.sh imlib2; \
  sh /src/v-xlunch/build.sh xlunch; \
  \
  find ${TARGETPATH} -type f |sort;

# Build tint2
FROM base AS tint2
ARG COMPILE_TINT2="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/tint2
RUN mkdir -p $TARGETPATH; \
  sh /src/v-tint2/build.sh cache; \
  \
  test "yes" != "$COMPILE_TINT2" && exit 0 || echo doMake; \
  sh /src/v-tint2/build.sh b_deps; \
  sh /src/v-tint2/build.sh tint2; \
  \
  find ${TARGETPATH} -type f |sort;

# Build feh
FROM base AS feh
ARG COMPILE_FEH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/feh
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-feh/build.sh cache; \
  \
  test "yes" != "$COMPILE_FEH" && exit 0 || echo doMake; \
  sh /src/v-feh/build.sh b_deps; \
  sh /src/v-feh/build.sh feh; \
  \
  find ${TARGETPATH} -type f |sort;

FROM base AS xcompmgr
ARG COMPILE_XCOMPMGR="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xcompmgr
RUN mkdir -p $TARGETPATH; \
  # sh /src/xcompmgr/build.sh cache; \
  \
  test "yes" != "$COMPILE_XCOMPMGR" && exit 0 || echo doMake; \
  sh /src/xcompmgr/build.sh Xdamage; \
  sh /src/xcompmgr/build.sh xcompmgr; \
  \
  find ${TARGETPATH} -type f |sort;

FROM base AS pcmanfm
ARG COMPILE_PCMANFM="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/pcmanfm
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-pcmanfm/build.sh cache; \
  \
  test "yes" != "$COMPILE_PCMANFM" && exit 0 || echo doMake; \
  bash /src/v-pcmanfm/build.sh b_deps; \
  bash /src/v-pcmanfm/build.sh pcmanfm; \
  \
  find ${TARGETPATH} -type f |sort;



FROM base AS perp
ARG COMPILE_PERP="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/perp
RUN mkdir -p $TARGETPATH; \
  # sh /src/xperp/build.sh cache; \
  \
  test "yes" != "$COMPILE_PERP" && exit 0 || echo doMake; \
  sh /src/xperp/build.sh perp; \
  \
  find ${TARGETPATH} -type f |sort;

# FROM compile
# FROM ${BASEIMAGE} #导致img嵌套，层次达max;
# FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:${COMPILE_IMG} AS ff
FROM infrastlabs/x11-base:${COMPILE_IMG} AS ff
FROM alpine:3.15
COPY --from=ff /rootfs /rootfs
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.15/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.15/community" >> /etc/apk/repositories; 
  # arm64: 无upx包..>> TODO static-upx
  # \
  # apk update; apk add upx; upx -V
ENV STATIC=/usr/local/static
WORKDIR ${STATIC}

# Add files.
# COPY --link --from=tigervnc /tmp/tigervnc-install/usr/bin/Xvnc /rootfs/usr/bin/
# COPY --link --from=tigervnc /tmp/tigervnc-install/usr/bin/vncpasswd /rootfs/usr/bin/
# COPY --link --from=tigervnc /tmp/xkb-install/usr/share/X11/xkb /rootfs/usr/share/X11/xkb
# COPY --link --from=tigervnc /tmp/xkbcomp-install/usr/bin/xkbcomp /rootfs/usr/bin/
# COPY --link --from=xdpyprobe /tmp/xdpyprobe/xdpyprobe /rootfs/usr/bin/
# 
# COPY --link --from=fontconfig /tmp/fontconfig-install/opt /opt
# COPY --link --from=openbox /tmp/openbox-install/usr/bin/openbox /rootfs/usr/bin/
# COPY --link --from=openbox /tmp/openbox-install/usr/bin/obxprop /rootfs/usr/bin/
# COPY --link --from=yad /tmp/yad-install/usr/bin/yad /rootfs/usr/bin/
# 
# COPY --link --from=nginx /tmp/nginx-install /rootfs/usr/
# COPY --link --from=dhparam /tmp/dhparam.pem /defaults/
# COPY --link --from=noVNC /opt/noVNC /opt/noVNC


# view01
# find |while read one; do md5sum..; echo "$md5|$one" > list-$rq-f.txt; done
RUN find /rootfs${STATIC} -type f |sort |wc

# CARE!! dirty clear;
# RUN rm -rf /rootfs${STATIC}/tigervnc
# RUN rm -rf /rootfs${STATIC}/xrdp
# RUN rm -rf /rootfs/usr/local/xrdp /rootfs/usr/local/tigervnc
# stages: 未用到的stage,会跳过构建
COPY --from=tiger ${STATIC} /rootfs${STATIC}
COPY --from=xrdp ${STATIC} /rootfs${STATIC}
COPY --from=dropbear ${STATIC} /rootfs${STATIC}
COPY --from=pulseaudio ${STATIC} /rootfs${STATIC}
COPY --from=fluxbox ${STATIC} /rootfs${STATIC}
COPY --from=openbox ${STATIC} /rootfs${STATIC}
COPY --from=suckless ${STATIC} /rootfs${STATIC}
# 
COPY --from=xcompmgr ${STATIC} /rootfs${STATIC}
COPY --from=xlunch ${STATIC} /rootfs${STATIC}
COPY --from=tint2 ${STATIC} /rootfs${STATIC}
COPY --from=feh ${STATIC} /rootfs${STATIC}
COPY --from=pcmanfm ${STATIC} /rootfs${STATIC}
COPY --from=lxde ${STATIC} /rootfs${STATIC}
COPY --from=perp ${STATIC} /rootfs${STATIC}

# clear lib,share/man; create links: (ubt/deb: bin> /usr/bin)
RUN rm -rf  /rootfs/bin /rootfs/sbin;
# keeplist, outDir;
# ..
# upx
# RUN \
#   upx /rootfs${STATIC}/suckless/bin/st; \
#   upx /rootfs${STATIC}/suckless/bin/dwm; \
#   upx /rootfs${STATIC}/suckless/bin/dmenu
# view02
RUN find /rootfs${STATIC} -type f |sort |wc
RUN find /rootfs${STATIC} -type f |sort
# RUN rm -rf ${STATIC}; ln -s /rootfs${STATIC} ${STATIC}

