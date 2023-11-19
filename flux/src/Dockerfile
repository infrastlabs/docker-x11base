ARG COMPILE_IMG=alpine-compile
FROM infrastlabs/docker-headless:core-compile2 as bin
# FROM infrastlabs/x11-base:rootfs as bin2
# FROM infrastlabs/x11-base:deb12-rootfs as bin2
# FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:${COMPILE_IMG} as bin2
FROM infrastlabs/x11-base:${COMPILE_IMG} as bin2
FROM ubuntu:20.04 as files1
  # files1: 三方文件, files2: src编译
  ARG TARGETPLATFORM
  RUN export DOMAIN="mirrors.ustc.edu.cn"; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
    echo "deb http://${DOMAIN}/$target focal main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://${DOMAIN}/$target focal-updates main restricted universe multiverse">> /etc/apt/sources.list; \
    apt update && apt -y install curl xz-utils
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
  mkdir -p /rootfs/usr/local/static/3rd/sbin /rootfs/usr/local/static/3rd/bin; \
  \
  # tini armel, armhf
  curl -o /rootfs/usr/local/static/3rd/sbin/tini -k -fSL https://github.com/krallin/tini/releases/download/v0.19.0/tini-$arch; chmod +x /rootfs/usr/local/static/3rd/sbin/tini; \
  #gosu-1.10_1.23MB @Sep 29, 2016;  1.16_2.25MB @Dec 20, 2022; armel, armhf
  curl -o /rootfs/usr/local/static/3rd/bin/gosu -k -fSL https://github.com/tianon/gosu/releases/download/1.10/gosu-$arch; chmod +x /rootfs/usr/local/static/3rd/bin/gosu; \
  \
  # https://github.com/upx/upx/releases/download/v4.2.1/upx-4.2.1-amd64_linux.tar.xz
  # armel> armeb;
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=amd64    ;; \
    "linux/arm64")  arch=arm64     ;; \
    "linux/arm/v7") arch=arm   ;; \
    "linux/arm/v6") arch=armeb   ;; \
    "linux/386")    arch=NONE_i386 ;; \
  esac; \
  file=upx-4.2.1-${arch}_linux.tar.xz; \
  cd /tmp; curl -fSL -k -O https://github.com/upx/upx/releases/download/v4.2.1/$file; \
  upack=/tmp/unpack-upx; mkdir -p $upack; tar -Jxf $file -C $upack --strip-components 1; \
  \cp -a $upack/upx /rootfs/usr/local/static/3rd/bin/; rm -f $file $upack; /rootfs/usr/local/static/3rd/bin/upx -V;
  # 
  COPY --from=bin /rootfs /rootfs/
  COPY --from=bin2 /rootfs /rootfs/
  RUN rm -rf /rootfs/usr/local/xrdp /rootfs/usr/local/tigervnc
  ADD src/static /tmp/static
  RUN bash /tmp/static/clear.sh
  


FROM ubuntu:20.04 as files2
  ARG TARGETPLATFORM
  RUN export DOMAIN="mirrors.ustc.edu.cn"; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
    echo "deb http://${DOMAIN}/$target focal main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://${DOMAIN}/$target focal-updates main restricted universe multiverse">> /etc/apt/sources.list; \
    apt update && apt -y install curl
  # webhookd, noVNC
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd.tar.gz
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd-armv7.tar.gz
  RUN echo a.123; \
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
    cd /tmp; curl -fSL -k -O https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    hookd=/rootfs/usr/local/webhookd; mkdir -p $hookd; tar -zxvf $file -C $hookd; rm -f $file; \
    # test -z "$(echo $TARGETPLATFORM |grep arm)" || mv $hookd/webhookd-arm64 $hookd/webhookd; \
    mv $hookd/webhookd* $hookd/webhookd; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" || sed -i 's^cmd="go run ./"^cmd=./webhookd^g' $hookd/run.sh; \
    \
    # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/v1.3.0.tar.gz #https://github.com/novnc/noVNC/archive
    cd /rootfs/usr/local/webhookd/static; file=v1.3.0.tar.gz; curl -k -O -fSL https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    bash down_vnc.sh; rm -f $file;
  # 

  # go-supervisor https://github.com/ochinchina/supervisord/releases
  # https://gitee.com/g-golang/fk-supervisord/releases/download/v23.11.20/supervisord-armv7.tar.gz
  RUN echo a.1; \
    # test -z "$(echo $TARGETPLATFORM |grep arm)" && arch=64-bit || arch=ARM64; \
    # test -z "$(echo $TARGETPLATFORM |grep arm/v7)" || arch=ARM64v7; \
    case ${TARGETPLATFORM} in \
      "linux/amd64")  arch=    ;; \
      "linux/arm64")  arch=-arm64     ;; \
      "linux/arm/v7") arch=-armv7   ;; \
      "linux/arm/v6") arch=NONE_ARMv6   ;; \
      "linux/386")    arch=NONE_i386 ;; \
    esac; \
    file=supervisord$arch.tar.gz; \
    cd /tmp; curl -fSL -k -O https://gitee.com/g-golang/fk-supervisord/releases/download/v23.11.20/$file; \
    mkdir -p /rootfs/usr/local/bin; \
    tar -zxf $file; rm -f $file; \cp -a supervisord* /rootfs/usr/local/bin/go-supervisord; \
    rm -rf /tmp/supervisord*; ls -lh /rootfs/usr/local/bin/
    # 
    # go-sv armv7: config arr err out of idx
    # case ${TARGETPLATFORM} in \
    #   "linux/amd64")  arch=64-bit    ;; \
    #   "linux/arm64")  arch=ARM64     ;; \
    #   "linux/arm/v7") arch=ARMv7   ;; \
    #   "linux/arm/v6") arch=ARMv6   ;; \
    #   "linux/386")    arch=NONE_i386 ;; \
    # esac; \
    # cd /tmp; curl -fSL -O https://ghproxy.com/https://github.com/ochinchina/supervisord/releases/download/v0.7.3/supervisord_0.7.3_Linux_$arch.tar.gz; \
    # tar -zxf supervisord_0.7.3_Linux_$arch.tar.gz; \cp -a supervisord_0.7.3_Linux_$arch/supervisord /usr/local/bin/go-supervisord; \
    # rm -rf /tmp/supervisord_0.7.3_Linux*; ls -lh /usr/local/bin/
  # 
  COPY src/*.sh /rootfs/
  ADD src/dot /rootfs/etc/skel
  ADD src/bin /rootfs/usr/local/static/3rd/bin
  ADD src/etc /rootfs/etc
  ADD src/svd.conf /rootfs/etc/supervisor/supervisord.conf
  ADD src/sv.conf /rootfs/etc/supervisor/conf.d/sv.conf
  RUN chmod +x /rootfs/*.sh; chmod +x /rootfs/usr/local/static/3rd/bin/*

# FROM busybox:1.36.1
FROM ubuntu:20.04
ENV \
  DEBIAN_FRONTEND=noninteractive \
  LOCALE_INCLUDE="en"
  # LOCALE_INCLUDE="zh_CN zh_HK zh_TW en en_AU fr fr_CA pt pt_BR es ar cs de it ru nl tr is sv uk ja ko th vi"
ARG TARGETPLATFORM
RUN export DOMAIN="mirrors.ustc.edu.cn"; \
  test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
  echo "deb http://${DOMAIN}/$target focal main restricted universe multiverse" > /etc/apt/sources.list \
  && echo "deb http://${DOMAIN}/$target focal-updates main restricted universe multiverse">> /etc/apt/sources.list; \
    \
  # default:echo -e;
  echo "path-exclude /usr/share/doc/*\n\
path-exclude /usr/share/man/*\n\
path-exclude /usr/share/locale/*\n\
path-exclude /usr/share/info/*\n\
path-exclude /usr/share/help/*\n\
path-exclude /usr/share/lintian/*\n\
#path-exclude /usr/share/zoneinfo/*\n\
#path-exclude /usr/share/i18n/*\n\
# XKB: Failed to compile keymap
# path-exclude /usr/share/X11/*\n\
# path-include /usr/share/locale/zh_CN/*\n\
" > /etc/dpkg/dpkg.cfg.d/excludes; \
  echo $LOCALE_INCLUDE |sed "s/ /\n/g" |while read one; do echo "path-include /usr/share/locale/$one/*" >> /etc/dpkg/dpkg.cfg.d/excludes; done; \
  cat /etc/dpkg/dpkg.cfg.d/excludes; \
  rm -rf /usr/share/locale/* ; \
  \
  echo 'apt update -qq && apt install -yq --no-install-recommends $@ && apt clean && rm -rf /var/lib/apt/lists/*; ' > /usr/local/bin/apt.sh \
    && chmod +x /usr/local/bin/apt.sh; 

# MISC 15.1 MB
#  lame sox libsox-fmt-mp3 
# dropbear-bin dropbear-run openssh-sftp-server 
RUN \
  apt.sh wget ca-certificates \
  curl \
  htop rsync tree tmux lrzsz psmisc fuse net-tools netcat iputils-ping \
  procps sudo iproute2 iptables zip unzip xz-utils vim-tiny \
  openssh-sftp-server lftp jq;

# libicu66: 
#  adwaita-icon-theme clipit dunst humanity-icon-theme
#  libxml2 pnmixer shared-mime-info ubuntu-mono
RUN apt.sh \
    # plank \ #compton-plank遮盖去域不可用
    # compton \
    xcompmgr \
    hsetroot 
    # dunst pnmixer clipit \
    # fluxbox 

# +asbru-cm
# +Apps
#  thunar: 32M; thunar> pcmanfm
#  total:
#   Need to get 44.2 MB of archives.
#   After this operation, 215 MB of additional disk space will be used.
# +replace: sakura> st; gnome-system-monitor> lxtask;
#   sakura gnome-system-monitor
#   lxde: (st+pcmanfm+lxtask)
RUN apt.sh \
 pcmanfm geany ristretto engrampa \
 lxtask lxappearance pavucontrol
RUN apt.sh gparted

# vscode-deps
RUN apt.sh \
  libdrm2 libgbm1 libnspr4 libnss3 libsecret-1-0 libxkbfile1 xdg-utils

#45 63.93 The following NEW packages will be installed:
#45 63.93   libmpdec2 libpython3-stdlib libpython3.8-minimal libpython3.8-stdlib
#45 63.93   mime-support python3 python3-minimal python3-pkg-resources python3.8
#45 63.93   python3.8-minimal supervisor
#45 64.51 0 upgraded, 11 newly installed, 0 to remove and 0 not upgraded.
#45 64.51 Need to get 5177 kB of archives.
#45 64.51 After this operation, 21.6 MB of additional disk space will be used.
# RUN apt.sh supervisor fluxbox

# 拆分包体与配置项两块，免频繁变动基础包
# HEADLESS
COPY --from=files1 /rootfs /rootfs/files1
COPY --from=files2 /rootfs /rootfs/files2

ENV \
  TERM=xterm \
  SHELL=/bin/bash \
  # 默认约定
  # DISPLAY=":10" \ #取VNC_OFFSET
  # L="zh_CN" \
  L="en_US" \
  TZ="Asia/Shanghai" \
  \
  PORT_SSH=10022 \
  PORT_RDP=10089 \
  PORT_VNC=10081 \
  # 
  SSH_PASS=headless \
  VNC_PASS=headless \
  VNC_PASS_RO=View123 \
  VNC_OFFSET=10

RUN \
  echo "cp -a /rootfs/files1/* /; \n\
cp -a /rootfs/files2/* /; \n\
bash /etc/skel/.fluxbox/fluxbox.sh; \n\
bash /xconf.sh;\n\
touch /rootfs/.core-init-lock\n\
" > /rootfs/.core-init
CMD ["bash", "-c", "test -f /rootfs/.core-init-lock || bash /rootfs/.core-init;  exec /entry.sh"]
