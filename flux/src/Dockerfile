ARG COMPILE_IMG=alpine-compile
FROM infrastlabs/docker-headless:core-compile2 as bin
# FROM infrastlabs/x11-base:rootfs as bin2
# FROM infrastlabs/x11-base:deb12-rootfs as bin2
# FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-compile-dbg as bin2
FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:${COMPILE_IMG} as bin2
FROM ubuntu:20.04 as files1
  COPY --from=bin /rootfs /rootfs/
  COPY --from=bin2 /rootfs /rootfs/

FROM ubuntu:20.04 as files2
  ARG TARGETPLATFORM
  RUN export DOMAIN="mirrors.ustc.edu.cn"; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
    echo "deb http://${DOMAIN}/$target focal main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://${DOMAIN}/$target focal-updates main restricted universe multiverse">> /etc/apt/sources.list; \
    apt update && apt -y install curl
  # webhookd, noVNC
  # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/webhookd.tar.gz
  RUN echo a.123; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" && file=webhookd.tar.gz || file=webhookd-arm64.tar.gz; \
    cd /tmp; curl -fSL -k -O https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    hookd=/rootfs/usr/local/webhookd; mkdir -p $hookd; tar -zxvf $file -C $hookd; rm -f $file; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" || mv $hookd/webhookd-arm64 $hookd/webhookd; \
    test -z "$(echo $TARGETPLATFORM |grep arm)" || sed -i 's^cmd="go run ./"^cmd=./webhookd^g' $hookd/run.sh; \
    \
    # https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/v1.3.0.tar.gz #https://github.com/novnc/noVNC/archive
    cd /rootfs/usr/local/webhookd/static; file=v1.3.0.tar.gz; curl -k -O -fSL https://gitee.com/infrastlabs/fk-webhookd/releases/download/v22.08.18/$file; \
    bash down_vnc.sh; rm -f $file;
  # 
  COPY src/*.sh /rootfs/
  ADD src/dot /rootfs/etc/skel
  ADD src/bin /rootfs/usr/bin
  ADD src/etc /rootfs/etc
  ADD src/svd.conf /rootfs/etc/supervisor/supervisord.conf
  ADD src/sv.conf /rootfs/etc/supervisor/conf.d/sv.conf
  RUN chmod +x /rootfs/*.sh; chmod +x /rootfs/usr/bin/*

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
    && chmod +x /usr/local/bin/apt.sh; \
  \
# MISC 15.1 MB
#  lame sox libsox-fmt-mp3 
# RUN \
  apt.sh wget ca-certificates \
  curl \
  htop rsync tree tmux lrzsz psmisc fuse net-tools netcat iputils-ping \
  procps sudo iproute2 iptables zip unzip xz-utils vim-tiny \
  dropbear-bin dropbear-run openssh-sftp-server lftp jq;

# libicu66: 
#  adwaita-icon-theme clipit dunst humanity-icon-theme
#  libxml2 pnmixer shared-mime-info ubuntu-mono
RUN apt.sh \
    # plank \ #compton-plank遮盖去域不可用
    # compton \
    xcompmgr \
    hsetroot \
    # dunst pnmixer clipit \
    fluxbox 

# go-supervisor https://github.com/ochinchina/supervisord/releases
RUN echo a.1; \
  # test -z "$(echo $TARGETPLATFORM |grep arm)" && arch=64-bit || arch=ARM64; \
  # test -z "$(echo $TARGETPLATFORM |grep arm/v7)" || arch=ARM64v7; \
  case ${TARGETPLATFORM} in \
    "linux/amd64")  arch=64-bit    ;; \
    "linux/arm64")  arch=ARM64     ;; \
    "linux/arm/v7") arch=ARMv7   ;; \
    "linux/arm/v6") arch=ARMv6   ;; \
    "linux/386")    arch=NONE_i386 ;; \
  esac; \
  cd /tmp; curl -fSL -O https://ghproxy.com/https://github.com/ochinchina/supervisord/releases/download/v0.7.3/supervisord_0.7.3_Linux_$arch.tar.gz; \
  tar -zxf supervisord_0.7.3_Linux_$arch.tar.gz; \cp -a supervisord_0.7.3_Linux_$arch/supervisord /usr/local/bin/go-supervisord; \
  rm -rf /tmp/supervisord_0.7.3_Linux*; ls -lh /usr/local/bin/
# go-sv armv7: config arr err out of idx

#45 63.93 The following NEW packages will be installed:
#45 63.93   libmpdec2 libpython3-stdlib libpython3.8-minimal libpython3.8-stdlib
#45 63.93   mime-support python3 python3-minimal python3-pkg-resources python3.8
#45 63.93   python3.8-minimal supervisor
#45 64.51 0 upgraded, 11 newly installed, 0 to remove and 0 not upgraded.
#45 64.51 Need to get 5177 kB of archives.
#45 64.51 After this operation, 21.6 MB of additional disk space will be used.
RUN apt.sh supervisor

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
