ARG COMPILE_IMG=alpine-compile
ARG REPO=
# BUILDPLATFORM: global-scope 声明(不给默认值)——FROM --platform=$BUILDPLATFORM 需其解析。
# buildx(CI)自动注入真实 build 平台;本地 docker build 用 --build-arg BUILDPLATFORM=linux/amd64 传入。
ARG BUILDPLATFORM
# split to basemm, for former validate: like geany with gtk's theme/icon/print/input/..
FROM --platform=$BUILDPLATFORM ${REPO}infrastlabs/x11-base:alpine-builder-gtk224-3 AS base
  ARG TARGETPLATFORM
  ENV CACHE=/usr/local/static/.cache
  RUN apk update; apk add gawk git; \
    xx-apk add musl-dev gcc
  ##Close SSL Verify, for hubProxy's clone; ref x-pulseaudio/build.sh
  RUN git config --global http.sslVerify false
  # COPY --from=compile /rootfs${CACHE} ${CACHE}
  COPY ./tarsrc /tarsrc
  COPY ./src /src
  RUN chmod +x /src/**/*.sh; \
    ls -lh /src/**/*.sh
FROM --platform=$BUILDPLATFORM ${REPO}infrastlabs/x11-base:alpine-builder-gtkmm224-3 AS basemm
  ARG TARGETPLATFORM
  ENV CACHE=/usr/local/static/.cache
  RUN apk update; apk add gawk git; \
    xx-apk add musl-dev gcc
  ##Close SSL Verify, for hubProxy's clone; ref x-pulseaudio/build.sh
  RUN git config --global http.sslVerify false
  # COPY --from=compile /rootfs${CACHE} ${CACHE}
  COPY ./tarsrc /tarsrc
  COPY ./src /src
  RUN chmod +x /src/**/*.sh
    # ls -lh /src/**/*.sh ##avoid ci-log with double print

# --platform=$BUILDPLATFORM 
FROM --platform=$BUILDPLATFORM base AS tiger
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3
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
# 2026-11-25 fix: 交叉(arm/v7,arm64)下 base 仅 xx-apk 装 musl-dev+gcc，sysroot 无 X11 头/静态库
#   → "fatal error: 'X11/Xlib.h' file not found"（native amd64 靠镜像烘焙的 X11，不触发）。
#   复用 common.sh 的共享清单 $XX_X11_PKGS（详见 common.sh 顶部注释 + docs 11241320 三章 1.6），
#   免得各 X11 组件重复维护那份 .a 归属清单。native 已装 → xx-apk 幂等零影响。
#   另把 '; ' 改 '&&'：原 make 失败被 upx 掩盖，错误归因错到 upx 而非 make，难定位。
RUN . /src/common.sh && \
  xx-apk add --no-cache $XX_X11_PKGS && \
  CC=xx-clang make -C /tmp/xdpyprobe && \
  xx-verify --static /tmp/xdpyprobe/xdpyprobe && \
  upx /tmp/xdpyprobe/xdpyprobe


FROM --platform=$BUILDPLATFORM base AS xrdp
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;
  # xx-verify --static ${TARGETPATH}/sbin/xrdp; \
  # xx-verify --static ${TARGETPATH}/sbin/xrdp-chansrv; \
  # upx ${TARGETPATH}/sbin/xrdp; \
  # upx ${TARGETPATH}/sbin/xrdp-chansrv
# xrdp-mods-cut
# RUN mkdir -p $TARGETPATH/etc/xrdp;

FROM --platform=$BUILDPLATFORM base AS x11vnc
ARG TARGETPLATFORM
ARG COMPILE_X11VNC="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/x11vnc
## build.sh: split multi steps, to speed up
RUN mkdir -p $TARGETPATH; \
  # sh /src/x-x11vnc/build.sh cache; \
  \
  test "yes" != "$COMPILE_X11VNC" && exit 0 || echo doMake; \
  sh /src/x-x11vnc/build.sh b_deps; \
  sh /src/x-x11vnc/build.sh x11vnc; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

FROM --platform=$BUILDPLATFORM base AS dropbear
ARG TARGETPLATFORM
ARG COMPILE_SSH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/dropbear
RUN mkdir -p $TARGETPATH; \
  # sh /src/x-dropbear/build.sh cache; \
  \
  test "yes" != "$COMPILE_SSH" && exit 0 || echo doMake; \
  # 2026-11-16: 先 b_deps 建 libxcrypt(yescrypt), 再 dropbear 链入——原只调 dropbear 未建 libcrypt.a→无 yescrypt 登录失败
  sh /src/x-dropbear/build.sh b_deps; \
  sh /src/x-dropbear/build.sh dropbear_2026_94; \
  \
  # test -x ${TARGETPATH}/sbin/dropbear || exit 1; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

FROM --platform=$BUILDPLATFORM base AS suckless
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;


FROM --platform=$BUILDPLATFORM base AS fluxbox
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3; 

# Build Openbox.
# FROM infrastlabs/x11-base:builder AS openbox
FROM --platform=$BUILDPLATFORM base AS openbox
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;
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


#######################################################
#######################################################
FROM --platform=$BUILDPLATFORM base AS xcompmgr
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

FROM --platform=$BUILDPLATFORM base AS perp
ARG TARGETPLATFORM
ARG COMPILE_PERP="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/perp
RUN mkdir -p $TARGETPATH; \
  # sh /src/xperp/build.sh cache; \
  \
  test "yes" != "$COMPILE_PERP" && exit 0 || echo doMake; \
  sh /src/xperp/build.sh perp; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build misc:su-exec,lrzsz,n2n,tinc
FROM --platform=$BUILDPLATFORM base AS misc
ARG TARGETPLATFORM
ARG COMPILE_MISC="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/misc
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-misc/build.sh cache; \
  \
  test "yes" != "$COMPILE_MISC" && exit 0 || echo doMake; \
  sh /src/u-misc/build.sh su_exec; \
  sh /src/u-misc/build.sh lrzsz; \
  sh /src/u-misc/build.sh n2n; \
  sh /src/u-misc/build.sh tinc; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build xbindkeys
FROM --platform=$BUILDPLATFORM base AS xbindkeys
ARG TARGETPLATFORM
ARG COMPILE_XBINDKEYS="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xbindkeys
RUN mkdir -p $TARGETPATH; \
  # 源码: 落仓 tarball(容器内 nongnu 截断, 不可在线) -> cp 到 /tmp 供 build.sh
  cp /src/x-xbindkeys/xbindkeys-1.8.7.tar.gz /tmp/; \
  \
  test "yes" != "$COMPILE_XBINDKEYS" && exit 0 || echo doMake; \
  sh /src/x-xbindkeys/build.sh xbindkeys; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build xrandr
FROM --platform=$BUILDPLATFORM base AS xrandr
ARG TARGETPLATFORM
ARG COMPILE_XRANDR="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xrandr
RUN mkdir -p $TARGETPATH; \
  \
  test "yes" != "$COMPILE_XRANDR" && exit 0 || echo doMake; \
  sh /src/x-xrandr/build.sh xrandr; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;


# Build dunst (xcb 通知守护) + notify-send（通知发送端，x-dunst 内构建）
FROM --platform=$BUILDPLATFORM base AS dunst
ARG TARGETPLATFORM
ARG COMPILE_DUNST="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/dunst
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_DUNST" && exit 0 || echo doMake; \
  sh /src/x-dunst/build.sh b_deps; \
  sh /src/x-dunst/build.sh dunst; \
  sh /src/x-dunst/build.sh notify_send; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build rofi (基础应用; 需 xcb-util -> b_deps 复用 w-tint2 xcbutil)
FROM --platform=$BUILDPLATFORM base AS rofi
ARG TARGETPLATFORM
ARG COMPILE_ROFI="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/rofi
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_ROFI" && exit 0 || echo doMake; \
  sh /src/x-rofi/build.sh b_deps; \
  sh /src/x-rofi/build.sh rofi; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

#######################################################
#######################################################
# Build feh
FROM --platform=$BUILDPLATFORM base AS feh
ARG TARGETPLATFORM
ARG COMPILE_FEH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/feh
RUN mkdir -p $TARGETPATH; \
  # sh /src/w-feh/build.sh cache; \
  \
  test "yes" != "$COMPILE_FEH" && exit 0 || echo doMake; \
  sh /src/w-feh/build.sh b_deps; \
  sh /src/w-feh/build.sh feh; \
  \
  # test -x ${TARGETPATH}/bin/feh || exit 1; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;


# Build hsetroot (imlib 应用, 壁纸设置)
FROM --platform=$BUILDPLATFORM base AS hsetroot
ARG TARGETPLATFORM
ARG COMPILE_HSETROOT="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/hsetroot
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_HSETROOT" && exit 0 || echo doMake; \
  sh /src/w-hsetroot/build.sh b_deps; \
  sh /src/w-hsetroot/build.sh hsetroot; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build scrot (imlib 截图)
FROM --platform=$BUILDPLATFORM base AS scrot
ARG TARGETPLATFORM
ARG COMPILE_SCROT="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/scrot
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_SCROT" && exit 0 || echo doMake; \
  sh /src/w-scrot/build.sh b_deps; \
  sh /src/w-scrot/build.sh scrot; \
  # test -x ${TARGETPATH}/bin/scrot || exit 1; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build tint2
FROM --platform=$BUILDPLATFORM base AS tint2
ARG TARGETPLATFORM
ARG COMPILE_TINT2="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/tint2
RUN mkdir -p $TARGETPATH; \
  # sh /src/w-tint2/build.sh cache; \
  \
  test "yes" != "$COMPILE_TINT2" && exit 0 || echo doMake; \
  sh /src/w-tint2/build.sh b_deps; \
  sh /src/w-tint2/build.sh tint2; \
  \
  # test -x ${TARGETPATH}/bin/tint2 || exit 1; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build xlunch
FROM --platform=$BUILDPLATFORM base AS xlunch
ARG TARGETPLATFORM
ARG COMPILE_XLUNCH="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xlunch
RUN mkdir -p $TARGETPATH; \
  sh /src/w-xlunch/build.sh cache; \
  \
  test "yes" != "$COMPILE_XLUNCH" && exit 0 || echo doMake; \
  # sh /src/w-xlunch/build.sh imlib2; \
  sh /src/w-xlunch/build.sh xlunch; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

#######################################################
#######################################################
# Build lxde
FROM --platform=$BUILDPLATFORM base AS lxde
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

FROM --platform=$BUILDPLATFORM base AS pcmanfm
ARG TARGETPLATFORM
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
  # test -x ${TARGETPATH}/bin/pcmanfm || exit 1; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build xfce4 (xfce4settings/thunar/ristretto; GTK2, 共享 xfce 库栈)
# b_deps: ensure_gtk_libs(最新 gtk2) + dbus/dbus-glib + xfce 库栈(util/conf/ui/exo/garcon) + libexif
FROM --platform=$BUILDPLATFORM base AS xfce4
ARG TARGETPLATFORM
ARG COMPILE_XFCE4="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/xfce4
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-xfce4/build.sh cache; \
  \
  test "yes" != "$COMPILE_XFCE4" && exit 0 || echo doMake; \
  sh /src/v-xfce4/build.sh b_deps; \
  sh /src/v-xfce4/build.sh full; \
  \
  test -x $TARGETPATH/bin/xfce4-display-settings || { echo "XFCE4 FAIL: xfce4-display-settings not built"; exit 1; }; \
  # test -x /usr/local/static/ristretto/bin/ristretto || { echo "XFCE4 FAIL: ristretto not built"; exit 1; }; \
  # test -x /usr/local/static/thunar/bin/thunar || { echo "XFCE4 FAIL: thunar not built"; exit 1; }; \
  \
  find ${TARGETPATH} /usr/local/static/thunar /usr/local/static/ristretto -type f 2>/dev/null |grep -E "/bin|/sbin" |sort |head -3;

# Build geany
FROM --platform=$BUILDPLATFORM base AS geany
ARG TARGETPLATFORM
ARG COMPILE_GEANY="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/geany
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-geany/build.sh cache; \
  \
  test "yes" != "$COMPILE_GEANY" && exit 0 || echo doMake; \
  sh /src/v-geany/build.sh b_deps; \
  sh /src/v-geany/build.sh geany; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build engrampa (GTK2 归档管理器; engrampa() 自足, 无独立 b_deps)
FROM --platform=$BUILDPLATFORM base AS engrampa
ARG TARGETPLATFORM
ARG COMPILE_ENGRAMPA="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/engrampa
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_ENGRAMPA" && exit 0 || echo doMake; \
  sh /src/v-engrampa/build.sh engrampa; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build gpicview (GTK2 图片查看器)
FROM --platform=$BUILDPLATFORM base AS gpicview
ARG TARGETPLATFORM
ARG COMPILE_GPICVIEW="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/gpicview
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_GPICVIEW" && exit 0 || echo doMake; \
  sh /src/v-gpicview/build.sh b_deps; \
  sh /src/v-gpicview/build.sh gpicview; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;


#######################################################
#######################################################
# Build gtkmm 栈 (7 libs, 供 pavucontrol/gnome-system-monitor)
# pavucontrol 需 pulse 静态库 -> gtkmm 建在 pulseaudio stage 上 (继承 pulse), pavucontrol 再 FROM gtkmm
# FROM pulseaudio AS gtkmm
# ARG COMPILE_GTKMM="yes"
# ENV CONSOLE_LOG=no
# RUN mkdir -p /usr/local/static; \
#   test "yes" != "$COMPILE_GTKMM" && exit 0 || echo doMake; \
#   sh /src/u-gtkmm/build.sh b_deps; \
#   sh /src/u-gtkmm/build.sh gtkmm; \
#   \
#   ls /usr/lib/libgtkmm-2.4.a /usr/lib/libglibmm-2.4.a /usr/lib/libgiomm-2.4.a;

# basemm for pavucontrol
FROM --platform=$BUILDPLATFORM basemm AS pulseaudio
ARG TARGETPLATFORM
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
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3

# Build pavucontrol (GTK2/gtkmm, 需 pulse+gtkmm 栈)
FROM --platform=$BUILDPLATFORM pulseaudio AS pavucontrol
ARG TARGETPLATFORM
ARG COMPILE_PAVUCONTROL="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/pavucontrol
RUN mkdir -p $TARGETPATH; \
  # sh /src/v-pavucontrol/build.sh cache; \
  \
  test "yes" != "$COMPILE_PAVUCONTROL" && exit 0 || echo doMake; \
  sh /src/v-pavucontrol/build.sh b_deps; \
  sh /src/v-pavucontrol/build.sh pavucontrol; \
  \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build pasystray (GTK2 托盘, 需 pulse 栈 -> FROM pulseaudio 继承)
FROM --platform=$BUILDPLATFORM pulseaudio AS pasystray
ARG TARGETPLATFORM
ARG COMPILE_PASYSTRAY="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/pasystray
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_PASYSTRAY" && exit 0 || echo doMake; \
  sh /src/v-pasystray/build.sh b_deps; \
  sh /src/v-pasystray/build.sh pasystray; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build sysmonitor (gtkmm 栈; 需 pulse+gtkmm -> FROM gtkmm 继承)
# full = build_gtop + build_wnck + gnome_system_monitor (gtop/wnck 非父级提供, 故直接 full,
# 不调 b_deps -- 其 ls gtop/wnck 在 set -e 下会因未建而中止)
# 静态链需 xcb-util (libwnck→startup-notification→xcb-util), 由 w-tint2 xcbutil 补建
FROM --platform=$BUILDPLATFORM basemm AS sysmonitor
ARG TARGETPLATFORM
ARG COMPILE_SYSMONITOR="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/gsm
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_SYSMONITOR" && exit 0 || echo doMake; \
  bash /src/w-tint2/build.sh xcbutil; \
  sh /src/v-sysmonitor/build.sh full; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;


# Build clipit
FROM --platform=$BUILDPLATFORM base AS clipit
ARG TARGETPLATFORM
ARG COMPILE_CLIPIT="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/clipit
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_CLIPIT" && exit 0 || echo doMake; \
  # sh /src/v-clipit/build.sh b_deps; \
  sh /src/v-clipit/build.sh clipit; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# Build dbus (静态 dbus-daemon + libdbus-1.a + dbus-glib; 共享依赖, xfce/ibus 等用)
FROM --platform=$BUILDPLATFORM base AS dbus
ARG TARGETPLATFORM
ARG COMPILE_DBUS="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/dbus
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_DBUS" && exit 0 || echo doMake; \
  sh /src/x-dbus/build.sh dbus; \
  sh /src/x-dbus/build.sh dbus-launch; \
  TARGETPATH=/usr/local/static/dbus-glib sh /src/x-dbus/build.sh dbus_glib; \
  find /usr/local/static/dbus /usr/local/static/dbus-glib -type f 2>/dev/null |grep -E "/bin|/sbin" |sort |head -3;

# Build ibus (GTK2 输入法: librime/ibus/panel/x11/ibus-rime/setup; 需 dbus+gtk2)
# 注意: v-ibus/build.sh 是 bash-only (busybox sh 解析失败 line297), 故用 bash 调用
FROM --platform=$BUILDPLATFORM dbus AS ibus
ARG TARGETPLATFORM
ARG COMPILE_IBUS="yes"
ENV CONSOLE_LOG=no \
  TARGETPATH=/usr/local/static/ibus
RUN mkdir -p $TARGETPATH; \
  test "yes" != "$COMPILE_IBUS" && exit 0 || echo doMake; \
  bash /src/v-ibus/build.sh b_deps; \
  bash /src/v-ibus/build.sh full; \
  find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;

# FROM compile
# FROM ${BASEIMAGE} #导致img嵌套，层次达max;
# FROM registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:${COMPILE_IMG} AS ff
ARG REPO=
FROM ${REPO}infrastlabs/x11-base:${COMPILE_IMG} AS ff
# FROM alpine:3.15
# FROM registry.cn-shenzhen.aliyuncs.com/infrasync/v2025:library--alpine---3.15 #not-exist
FROM registry.cn-shenzhen.aliyuncs.com/infrasync/v2025:library--alpine---3.13.12
ENV STATIC=/usr/local/static
WORKDIR ${STATIC}
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.15/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.15/community" >> /etc/apk/repositories; 
  # arm64: 无upx包..>> TODO static-upx
  # \
  # apk update; apk add upx; upx -V

# Add files.
# COPY --link --from=tigervnc /tmp/tigervnc-install/usr/bin/Xvnc /rootfs/usr/bin/
# COPY --from=ff /rootfs /rootfs

# view01
# find |while read one; do md5sum..; echo "$md5|$one" > list-$rq-f.txt; done
RUN \
  # clear old
  # rm -rf /rootfs${STATIC}/misc; \
  \
  find /rootfs${STATIC} -type f |sort |wc; \
  du -sh /rootfs${STATIC}/*; \
  exit 0;

# CARE!! dirty clear;
# RUN rm -rf /rootfs${STATIC}/tigervnc
# RUN rm -rf /rootfs${STATIC}/xrdp
# RUN rm -rf /rootfs/usr/local/xrdp /rootfs/usr/local/tigervnc
# stages: 未用到的stage,会跳过构建
COPY --from=tiger ${STATIC} /rootfs${STATIC}
COPY --from=xrdp ${STATIC} /rootfs${STATIC}
COPY --from=x11vnc ${STATIC} /rootfs${STATIC}
COPY --from=dropbear ${STATIC} /rootfs${STATIC}
COPY --from=fluxbox ${STATIC} /rootfs${STATIC}
COPY --from=openbox ${STATIC} /rootfs${STATIC}
COPY --from=suckless ${STATIC} /rootfs${STATIC}
COPY --from=xcompmgr ${STATIC} /rootfs${STATIC}
COPY --from=perp ${STATIC} /rootfs${STATIC}
COPY --from=misc ${STATIC} /rootfs${STATIC}
# 
COPY --from=hsetroot ${STATIC} /rootfs${STATIC}
COPY --from=scrot ${STATIC} /rootfs${STATIC}
COPY --from=tint2 ${STATIC} /rootfs${STATIC}
COPY --from=feh ${STATIC} /rootfs${STATIC}
COPY --from=xlunch ${STATIC} /rootfs${STATIC}
# CARE!! dirty clear;
# RUN rm -rf /rootfs${STATIC}/tint2
# 
COPY --from=xbindkeys ${STATIC} /rootfs${STATIC}
COPY --from=xrandr ${STATIC} /rootfs${STATIC}
COPY --from=dunst ${STATIC} /rootfs${STATIC}
COPY --from=rofi ${STATIC} /rootfs${STATIC}
COPY --from=pulseaudio ${STATIC} /rootfs${STATIC}
COPY --from=pasystray ${STATIC} /rootfs${STATIC}
COPY --from=pavucontrol ${STATIC} /rootfs${STATIC}
COPY --from=sysmonitor ${STATIC} /rootfs${STATIC}
# 
COPY --from=lxde ${STATIC} /rootfs${STATIC}
COPY --from=pcmanfm ${STATIC} /rootfs${STATIC}
COPY --from=xfce4 ${STATIC} /rootfs${STATIC}
COPY --from=geany ${STATIC} /rootfs${STATIC}
COPY --from=engrampa ${STATIC} /rootfs${STATIC}
COPY --from=gpicview ${STATIC} /rootfs${STATIC}
COPY --from=clipit ${STATIC} /rootfs${STATIC}
COPY --from=dbus ${STATIC} /rootfs${STATIC}
# COPY --from=ibus ${STATIC} /rootfs${STATIC}
COPY --from=base /tmp/NOCACHE /tmp/

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
# RUN find /rootfs${STATIC} -type f |sort
RUN find /rootfs${STATIC} -type f |sort |wc; \
  du -sh /rootfs${STATIC}/*; \
  cat /tmp/NOCACHE
# RUN rm -rf ${STATIC}; ln -s /rootfs${STATIC} ${STATIC}

# Set multiple labels at once, author,builtdate
ARG BUILDDATE
LABEL \
  github.com.infrastlabs.docker-x11base.vendor=Infrastlabs \
  github.com.infrastlabs.docker-x11base.release="production" \
  github.com.infrastlabs.docker-x11base.version="v26.11" \
  github.com.infrastlabs.docker-x11base.maintainer="sam <sldevsir@126.com>" \
  github.com.infrastlabs.docker-x11base.builtdate="$BUILDDATE"
