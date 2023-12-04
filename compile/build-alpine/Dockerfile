# syntax=docker/dockerfile:1.4
#
# baseimage-gui Dockerfile
#
# https://github.com/jlesage/docker-baseimage-gui
#

# ARG BASEIMAGE=unknown
# ARG BASEIMAGE=alpine:3.15

# Define the Alpine packages to be installed into the image.
# ARG ALPINE_PKGS="\
#     # Needed to generate self-signed certificates
#     openssl \
#     # Needed to use netcat with unix socket.
#     netcat-openbsd \
# "

# Define the Debian/Ubuntu packages to be installed into the image.
# ARG DEBIAN_PKGS="\
#     # Used to determine if nginx is ready.
#     netcat \
#     # For ifconfig
#     net-tools \
#     # Needed to generate self-signed certificates
#     openssl \
# "

# Build TigerVNC server.
# FROM infrastlabs/x11-base:builder AS cache1
#   # build.sh: split multi steps, to speed up
#   COPY src/tigervnc/build.sh /build/build.sh
#   RUN sh /build/build.sh cache

# --platform=$BUILDPLATFORM 
FROM infrastlabs/x11-base:builder AS tigervnc
ARG TARGETPLATFORM
# COPY --from=xx / /
# COPY --from=upx /usr/bin/upx /usr/bin/upx
RUN apk update; apk add gawk;
ENV TARGETPATH=/usr
# COPY --from=cache1 /mnt /mnt
# https://blog.csdn.net/sodaloveer/article/details/127727729 #batch_exec
COPY src/tigervnc/build.sh /build/build.sh
RUN sh /build/build.sh cache
RUN sh /build/build.sh b_deps
# 
COPY src/tigervnc /build
RUN sh /build/build.sh b_tiger
# RUN apk --no-cache add bash; bash -c """sh /build/build.sh gnutls & ; \
#     sh /build/build.sh libxfont2 & ; \
#     sh /build/build.sh libfontenc & ; \
#     sh /build/build.sh libtasn1 & ; \
#     sh /build/build.sh libxshmfence & ; \
#     wait ; \
#     sh /build/build.sh tigervnc & ; \
#     sh /build/build.sh xkb & ; \
#     sh /build/build.sh xkbcomp & ; \
#     wait ;"""
# 
RUN xx-verify --static /tmp/tigervnc-install/usr/bin/Xvnc; \
  xx-verify --static /tmp/tigervnc-install/usr/bin/vncpasswd
RUN upx /tmp/tigervnc-install/usr/bin/Xvnc; \
  upx /tmp/tigervnc-install/usr/bin/vncpasswd

# Build xdpyprobe.
# Used to determine if the X server (Xvnc) is ready.
# FROM infrastlabs/x11-base:builder AS xdpyprobe
# ARG TARGETPLATFORM
# COPY --from=xx / /
# COPY --from=upx /usr/bin/upx /usr/bin/upx
COPY src/xdpyprobe /tmp/xdpyprobe
# RUN apk --no-cache add make clang
# RUN xx-apk --no-cache add gcc musl-dev libx11-dev libx11-static libxcb-static
# 
RUN CC=xx-clang \
    make -C /tmp/xdpyprobe
RUN xx-verify --static /tmp/xdpyprobe/xdpyprobe; \
  upx /tmp/xdpyprobe/xdpyprobe

# Build Fontconfig.
# FROM infrastlabs/x11-base:builder AS fontconfig
# ARG TARGETPLATFORM
# # COPY --from=xx / /
# COPY src/fontconfig/build.sh /tmp/build-fontconfig.sh
# RUN /tmp/build-fontconfig.sh

# Build Openbox.
# FROM infrastlabs/x11-base:builder AS openbox
# ARG TARGETPLATFORM
# # COPY --from=xx / /
# COPY --from=fontconfig /tmp/fontconfig-install /tmp/fontconfig-install
# COPY src/openbox /tmp/build
# RUN /tmp/build/build.sh
# RUN xx-verify --static \
#     /tmp/openbox-install/usr/bin/openbox \
#     /tmp/openbox-install/usr/bin/obxprop
# # COPY --from=upx /usr/bin/upx /usr/bin/upx
# RUN upx /tmp/openbox-install/usr/bin/openbox
# RUN upx /tmp/openbox-install/usr/bin/obxprop

# Build yad.
# FROM infrastlabs/x11-base:builder AS yad
# ARG TARGETPLATFORM
# # COPY --from=xx / /
# COPY --from=fontconfig /tmp/fontconfig-install /tmp/fontconfig-install
# COPY src/yad/build.sh /tmp/build-yad.sh
# RUN /tmp/build-yad.sh
# RUN xx-verify --static /tmp/yad-install/usr/bin/yad
# # COPY --from=upx /usr/bin/upx /usr/bin/upx
# RUN upx /tmp/yad-install/usr/bin/yad



# COPY --link --from=tigervnc /tmp/tigervnc-install/usr/bin/Xvnc /rootfs/usr/bin/
# COPY --link --from=tigervnc /tmp/tigervnc-install/usr/bin/vncpasswd /rootfs/usr/bin/
# COPY --link --from=tigervnc /tmp/xkb-install/usr/share/X11/xkb /rootfs/usr/share/X11/xkb
# COPY --link --from=tigervnc /tmp/xkbcomp-install/usr/bin/xkbcomp /rootfs/usr/bin/
# COPY --link --from=xdpyprobe /tmp/xdpyprobe/xdpyprobe /rootfs/usr/bin/

RUN rm -rf /rootfs; mkdir -p /rootfs${TARGETPATH}/bin /rootfs${TARGETPATH}/share/X11; \
  \cp -a /tmp/tigervnc-install/usr/bin/Xvnc /rootfs${TARGETPATH}/bin/; \
  \cp -a /tmp/tigervnc-install/usr/bin/vncpasswd /rootfs${TARGETPATH}/bin/; \
  \cp -a /tmp/xkb-install/usr/share/X11/xkb /rootfs${TARGETPATH}/share/X11/xkb; \
  \cp -a /tmp/xkbcomp-install/usr/bin/xkbcomp /rootfs${TARGETPATH}/bin/; \
  \cp -a /tmp/xdpyprobe/xdpyprobe /rootfs${TARGETPATH}/bin/; \
  \cp -a /tmp/logs /rootfs/

# validate
RUN du -sh /rootfs; \
  /rootfs/usr/bin/Xvnc -version; \
  find /rootfs -type f |sort

# Build Nginx.
# FROM infrastlabs/x11-base:builder AS nginx
# ARG TARGETPLATFORM
# # COPY --from=xx / /
# COPY src/nginx/build.sh /tmp/build-nginx.sh
# RUN /tmp/build-nginx.sh
# RUN xx-verify --static /tmp/nginx-install/sbin/nginx
# # COPY --from=upx /usr/bin/upx /usr/bin/upx
# RUN upx /tmp/nginx-install/sbin/nginx
# # NOTE: Extended attributes are kept by buildx when using the COPY command.
# #       See https://wildwolf.name/multi-stage-docker-builds-and-xattrs/.
# RUN apk --no-cache add libcap && setcap cap_net_bind_service=ep /tmp/nginx-install/sbin/nginx

# Build noVNC.
# FROM infrastlabs/x11-base:builder AS noVNC
# ARG NOVNC_VERSION=1.4.0
# ARG BOOTSTRAP_VERSION=5.1.3
# ARG BOOTSTRAP_NIGHTSHADE_VERSION=1.1.3
# ARG FONTAWESOME_VERSION=4.7.0
# ARG NOVNC_URL=https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz
# ARG BOOTSTRAP_URL=https://github.com/twbs/bootstrap/releases/download/v${BOOTSTRAP_VERSION}/bootstrap-${BOOTSTRAP_VERSION}-dist.zip
# ARG BOOTSTRAP_NIGHTSHADE_URL=https://github.com/vinorodrigues/bootstrap-dark-5/archive/refs/tags/v${BOOTSTRAP_NIGHTSHADE_VERSION}.tar.gz
# ARG FONTAWESOME_URL=https://fontawesome.com/v${FONTAWESOME_VERSION}/assets/font-awesome-${FONTAWESOME_VERSION}.zip
# WORKDIR /tmp
# COPY helpers/* /usr/bin/
# COPY rootfs/opt/noVNC/index.html /opt/noVNC/index.html
# RUN \
#     # Install required tools.
#     apk --no-cache add \
#         curl \
#         sed \
#         jq \
#         npm \
#         && \
#     npm install clean-css-cli -g
# RUN \
#     # Create required directories.
#     mkdir -p \
#         /opt/noVNC/app/styles \
#         /opt/noVNC/app/fonts
# RUN \
#     # Install noVNC.
#     mkdir /tmp/noVNC && \
#     curl -# -L ${NOVNC_URL} | tar -xz --strip 1 -C /tmp/noVNC && \
#     cp -vr /tmp/noVNC/core /opt/noVNC/ && \
#     cp -vr /tmp/noVNC/vendor /opt/noVNC/
# RUN \
#     # Install Bootstrap.
#     # NOTE: Only copy the JS bundle, since the CSS is taken from Bootstrap
#     #       Nightshade.
#     curl -sS -L -O ${BOOTSTRAP_URL} && \
#     unzip bootstrap-${BOOTSTRAP_VERSION}-dist.zip && \
#     #cp -v bootstrap-${BOOTSTRAP_VERSION}-dist/css/bootstrap.min.css /opt/noVNC/app/styles/ && \
#     cp -v bootstrap-${BOOTSTRAP_VERSION}-dist/js/bootstrap.bundle.min.js* /opt/noVNC/app/
# RUN \
#     # Install Bootstrap Nightshade.
#     mkdir /tmp/bootstrap-nightshade && \
#     curl -# -L ${BOOTSTRAP_NIGHTSHADE_URL} | tar -xz --strip 1 -C /tmp/bootstrap-nightshade && \
#     cleancss \
#         -O1 \
#         --format breakWith=lf \
#         --output /opt/noVNC/app/styles/bootstrap-nightshade.min.css \
#         /tmp/bootstrap-nightshade/dist/css/bootstrap-nightshade.css
# RUN \
#     # Install Font Awesome.
#     curl -sS -L -O ${FONTAWESOME_URL} && \
#     unzip font-awesome-${FONTAWESOME_VERSION}.zip && \
#     cp -v font-awesome-${FONTAWESOME_VERSION}/fonts/fontawesome-webfont.* /opt/noVNC/app/fonts/ && \
#     cp -v font-awesome-${FONTAWESOME_VERSION}/css/font-awesome.min.css /opt/noVNC/app/styles/
# RUN \
#     # Set version of CSS and JavaScript file URLs.
#     sed "s/UNIQUE_VERSION/$(date | md5sum | cut -c1-10)/g" -i /opt/noVNC/index.html
# RUN \
#     # Generate favicons.
#     APP_ICON_URL=https://github.com/jlesage/docker-templates/raw/master/jlesage/images/generic-app-icon.png && \
#     install_app_icon.sh --no-tools-install "$APP_ICON_URL"

# Generate default DH params.
# FROM infrastlabs/x11-base:builder AS dhparam
# RUN apk --no-cache add openssl
# RUN echo "Generating default DH parameters (2048 bits)..."
# RUN openssl dhparam \
#         -out "/tmp/dhparam.pem" \
#         2048 \
#         > /dev/null 2>&1

# Pull base image.
# FROM ${BASEIMAGE}

# Define working directory.
# WORKDIR /tmp

# Install system packages.
# ARG ALPINE_PKGS
# ARG DEBIAN_PKGS
# RUN \
#     if [ -n "$(which apk)" ]; then \
#         add-pkg ${ALPINE_PKGS}; \
#     else \
#         add-pkg ${DEBIAN_PKGS}; \
#     fi && \
#     # Remove some unneeded stuff.
#     rm -rf /var/cache/fontconfig/*

# Add files.
# # COPY --link helpers/* /rootfs/usr/bin/
# # COPY --link rootfs/ /
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

# Set environment variables.
# ENV \
#     DISPLAY_WIDTH=1920 \
#     DISPLAY_HEIGHT=1080 \
#     DARK_MODE=0 \
#     SECURE_CONNECTION=0 \
#     SECURE_CONNECTION_VNC_METHOD=SSL \
#     SECURE_CONNECTION_CERTS_CHECK_INTERVAL=60 \
#     WEB_LISTENING_PORT=5800 \
#     VNC_LISTENING_PORT=5900 \
#     VNC_PASSWORD= \
#     ENABLE_CJK_FONT=0

# Expose ports.
#   - 5800: VNC web interface
#   - 5900: VNC
# EXPOSE 5800 5900

# Metadata.
# ARG IMAGE_VERSION=unknown
# LABEL \
#       org.label-schema.name="baseimage-gui" \
#       org.label-schema.description="A minimal docker baseimage to ease creation of X graphical application containers" \
#       org.label-schema.version="${IMAGE_VERSION}" \
#       org.label-schema.vcs-url="https://github.com/jlesage/docker-baseimage-gui" \
#       org.label-schema.schema-version="1.0"
