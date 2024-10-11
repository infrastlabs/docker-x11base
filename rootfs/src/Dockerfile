ARG REPO=
ARG COMPILE_IMG=alpine-compile
# FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:${COMPILE_IMG} AS bin2
FROM ${REPO}infrastlabs/x11-base:${COMPILE_IMG} AS bin2
FROM alpine:3.13.12 AS files1
  # files1: 三方文件, files2: src编译
  # xz-utils > xz
  ARG TARGETPLATFORM
  RUN sed -i "s^dl-cdn.alpinelinux.org^mirrors.tuna.tsinghua.edu.cn^g" /etc/apk/repositories; \
    apk add bash curl xz
  RUN \
  # test -z "$(echo $TARGETPLATFORM |grep arm)" && arch=amd64 || arch=arm64; \
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=amd64    ;; \
    "linux/arm64")  arch=arm64     ;; \
    "linux/arm/v7") arch=armhf   ;; \
    "linux/arm/v6") arch=armel   ;; \
    "linux/386")    arch=NONE_i386 ;; \
  esac; \
  # http://www.taodudu.cc/news/show-1624185.html?action=onClick
  # armhf php环境搭建,armel、armhf 和 arm64 区别选择
  #  1.在一些社区的支持下，armhf目前已经得到了很大的发展。像Ubuntu，已经计划在之后的发行版中放弃armel，转而支持armhf编译的版本。正如目前依然很火热的Raspberry Pi(ARM11)，由于ubuntu只支持armv7架构的编译，Raspberry Pi将不能直接安装ubuntu系统。而 BB Black(Cortex-A8)和 Cubietruct(Cortex-A7)则同时支持ubuntu的armel与armhf的编译。
  #  2.armhf的开启需要硬件的支持，在Debian的wiki上要求 ARMv7 CPU、Thumb-2 指令集以及 VFP3D16 浮点处理器
  export third=/rootfs/usr/local/static/3rd; mkdir -p $third/sbin $third/bin; \
  \
  # tini armel, armhf
  # https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64
  curl -o $third/sbin/tini -k -fSL https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-$arch; chmod +x $third/sbin/tini; \
  #gosu-1.10_1.23MB @Sep 29, 2016;  1.16_2.25MB @Dec 20, 2022; armel, armhf
  # https://github.com/tianon/gosu/issues/93 ##err-with-qemu; >> ok with 1.14+; 1.17@Nov 3, 2023
  # https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64
  curl -o $third/bin/gosu -k -fSL https://github.com/tianon/gosu/releases/download/1.17/gosu-$arch; chmod +x $third/bin/gosu; \
  \
  echo a.1; \
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=amd64    ;; \
    "linux/arm64")  arch=arm64     ;; \
    "linux/arm/v7") arch=arm   ;; \
    "linux/arm/v6") arch=armeb   ;; \
    "linux/386")    arch=NONE_i386 ;; \
  esac; \
  # yq v4.44.3
  curl -o $third/bin/yq -k -fSL https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_$arch; chmod +x $third/bin/yq; \
  # upx
  # https://github.com/upx/upx/releases/download/v4.2.2/upx-4.2.2-arm64_linux.tar.xz #ok;
  file=upx-4.2.2-${arch}_linux.tar.xz; \
  cd /tmp; curl -fSL -k -O https://github.com/upx/upx/releases/download/v4.2.2/$file; \
  upack=/tmp/unpack-upx; mkdir -p $upack; tar -Jxf $file -C $upack --strip-components 1; \
  \cp -a $upack/upx $third/bin/; rm -rf $file $upack; $third/bin/upx -V; \
  # curl-static
  # https://github.com/moparisthebest/static-curl/releases/download/v7.69.1/curl-aarch64
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=amd64    ;; \
    "linux/arm64")  arch=aarch64  ;; \
    "linux/arm/v7") arch=armv7    ;; \
    "linux/arm/v6") arch=NONE_v6  ;; \
    "linux/386")    arch=i386     ;; \
  esac; \
  dst=$third/bin/curl; \
  curl -o $dst -k -fSL github.com/moparisthebest/static-curl/releases/download/v7.69.1/curl-$arch; chmod +x $dst; \
  # 24.8.20: +undock
  # https://github.com/crazy-max/undock/releases/download/v0.8.0/undock_0.8.0_linux_amd64.tar.gz
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=amd64      ;; \
    "linux/arm64")  arch=arm64      ;; \
    "linux/arm/v7") arch=armv7      ;; \
    "linux/arm/v6") arch=NONE_v6    ;; \
    "linux/386")    arch=NONE_i386  ;; \
  esac; \
  file=undock_0.8.0_linux_$arch.tar.gz; \
  cd /tmp; curl -O -k -fSL https://github.com/crazy-max/undock/releases/download/v0.8.0/$file; \
  upack=/tmp/unpack-undock; mkdir -p $upack; tar -zxf $file -C $upack; \
  \cp -a $upack/undock $third/bin/; rm -rf $file $upack; \
  # validate: ref quickstart-dockerfile//env-sdk/ubt20
  export PATH=$third/sbin/:$third/bin/:$PATH; \
  set -e; yq --version; tini --version; gosu -v; undock --version; 

  COPY --from=bin2 /rootfs /rootfs/
  RUN rm -rf /rootfs/usr/local/xrdp /rootfs/usr/local/tigervnc
  ADD src/_drop /tmp/drop
  RUN bash /tmp/drop/clear.sh
  


FROM alpine:3.13.12 AS files2
  ARG TARGETPLATFORM
  RUN sed -i "s^dl-cdn.alpinelinux.org^mirrors.tuna.tsinghua.edu.cn^g" /etc/apk/repositories; \
    apk add bash curl wget git
  # webhookd, noVNC
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd.tar.gz
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd-armv7.tar.gz
  # 23.12.5: ee's rediret, curl>> wget
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd-arm64.tar.gz
  # https://foruda.gitee.com/attach_file/1667578886414239989/webhookd-arm64.tar.gz?token=8d25d71a91c2a74f6a4998ee8bef8f1c&ts=1701787483&attname=webhookd-arm64.tar.gz
  RUN echo a.125; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" && file=webhookd.tar.gz || file=webhookd-arm64.tar.gz; \
    # test -z "$(echo $TARGETPLATFORM |grep arm/v7)" || arch=ARM64v7; \
    case ${TARGETPLATFORM} in \
      "linux/amd64")  arch=    ;; \
      "linux/arm64")  arch=-arm64     ;; \
      "linux/arm/v7") arch=-armv7   ;; \
      "linux/arm/v6") arch=NONE_ARMv6   ;; \
      "linux/386")    arch=NONE_i386 ;; \
    esac; \
    file=webhookd$arch.tar.gz; \
    cd /tmp; wget --no-check-certificate https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    hookd=/rootfs/usr/local/webhookd; mkdir -p $hookd; tar -zxvf $file -C $hookd; rm -f $file; \
    # webhookd if not amd64: -arm64, armv7
    test -z "$(echo $TARGETPLATFORM |grep amd64)" && mv $hookd/webhookd* $hookd/webhookd; \
    sed -i 's^cmd="go run ./"^cmd=./webhookd^g' $hookd/run.sh; \
    sed -i "s^\$cmd^exec \$cmd^g" /rootfs/usr/local/webhookd/run.sh; \
    \
    # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/v1.3.0.tar.gz #https://github.com/novnc/noVNC/archive
    # curl -k -O -fSL >> wget
    cd /rootfs/usr/local/webhookd/static; \
    file=v1.3.0.tar.gz; wget --no-check-certificate https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    find |sort; \
    bash down_vnc.sh; rm -f $file; \
    \
    # test -s /rootfs/usr/local/webhookd/webhookd || exit 1; \
    # test -s /rootfs/usr/local/webhookd/static/noVNC-1.3.0/vnc.html || exit 1;
    # fonts: DejaVuSansMono
    git clone https://gitee.com/g-system/fk-fonts /tmp/powerline-fonts; \
    dst=/rootfs/usr/share/fonts/DejaVuSansMono; \
    mkdir -p $dst; \cp -a /tmp/powerline-fonts/DejaVuSansMono/*.ttf $dst/;
  
  COPY src/*.sh /rootfs/
  # ADD src/dot /rootfs/etc/skel
  # ADD src/bin /rootfs/usr/bin
  ADD src/etc /rootfs/etc
  RUN chmod +x /rootfs/*.sh;
  # DO: build-arg NOCACHE=$rand.time
  ARG NOCACHE
  RUN echo "NOCACHE=${NOCACHE}"; \
    dst=/rootfs/usr/local/static/.dotfiles; \
    mkdir -p $dst; git clone --depth=1 https://gitee.com/infrastlabs/dotfiles.git $dst; \
    exit 0; 

# FROM busybox:1.36.1
# FROM ubuntu:20.04
FROM alpine:3.13.12
# Set multiple labels at once, author,builtdate
LABEL \
  github.com.infrastlabs.docker-x11base.vendor=Infrastlabs \
  github.com.infrastlabs.docker-x11base.release="production" \
  github.com.infrastlabs.docker-x11base.version="1.0.1-beta" \
  github.com.infrastlabs.docker-x11base.maintainer="sam <sldevsir@126.com>" \
  github.com.infrastlabs.docker-x11base.builtdate="$(date -u +'%Y-%m-%d %H:%M:%S')"

# https://www.jakehu.me/2021/alpine-mirrors/
# domain="mirrors.ustc.edu.cn"
# domain="mirrors.aliyun.com";
# mirrors.tuna.tsinghua.edu.cn
RUN \
  sed -i "s^dl-cdn.alpinelinux.org^mirrors.tuna.tsinghua.edu.cn^g" /etc/apk/repositories
  # ca-certificates tzdata 
  #  bash-completion coreutils busybox-extras 
  # xterm :/usr/share/applications/{xterm,uxterm}
  # ping: @busybox / @iputils-ping
RUN apk add --no-cache \
  bash curl wget \
  sed grep gawk findutils sudo tree unzip procps htop \
  expect shadow \
  jq sysstat lame iproute2-ss net-tools; \
  chmod u+s /bin/ping;
# fontconfig>> ttf-dejavu
# RUN apk add --no-cache \
#   ttf-dejavu

# 拆分包体与配置项两块，免频繁变动基础包
# HEADLESS
COPY --from=files1 /rootfs /rootfs/files1
COPY --from=files2 /rootfs /rootfs/files2

ENV \
  TERM=xterm \
  SHELL=/bin/bash
  # 默认约定
#   L="en_US" \
#   TZ="Asia/Shanghai"

RUN \
  echo -e "\n\
cp -a /rootfs/files1/* /; \n\
cp -a /rootfs/files2/* /; \n\
bash /xconf.sh core;\n\
touch /rootfs/.core-init-lock\n\
" > /rootfs/.core-init
# # tini: https://www.5axxw.com/wiki/content/01ppi2
# ENTRYPOINT ["/sbin/tini","--"]
CMD ["bash", "-c", "test -f /rootfs/.core-init-lock || bash /rootfs/.core-init;  exec /entry.sh"]
