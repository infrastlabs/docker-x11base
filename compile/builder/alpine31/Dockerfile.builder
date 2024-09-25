
# Get Dockerfile cross-compilation helpers.
# --platform=$BUILDPLATFORM 
FROM tonistiigi/xx AS xx

# Build UPX.
FROM alpine:3.1 AS upx
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.1/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.1/community" >> /etc/apk/repositories
#RUN ping -c 2 qq.com; apk update;
RUN apk update; apk --no-cache add build-base curl make cmake git;
RUN mkdir /tmp/upx && \
    curl -# -L https://ghproxy.com/https://github.com/upx/upx/releases/download/v4.0.1/upx-4.0.1-src.tar.xz | tar xJ --strip 1 -C /tmp/upx && \
    make -C /tmp/upx build/release-gcc -j$(nproc) && \
    cp -v /tmp/upx/build/release-gcc/upx /usr/bin/upx


FROM alpine:3.1 AS builder
ARG TARGETPLATFORM
# https://www.jakehu.me/2021/alpine-mirrors/
# domain="mirrors.ustc.edu.cn"
# domain="mirrors.aliyun.com";
# mirrors.tuna.tsinghua.edu.cn
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.1/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.1/community" >> /etc/apk/repositories
#
COPY --from=xx / /
COPY --from=upx /usr/bin/upx /usr/bin/upx
# make (4.1-r0) clang (3.5.0-r0)
RUN apk update; apk --no-cache add make clang
# alpine31_none: libx11-static libxcb-static
RUN xx-apk --no-cache add gcc musl-dev libx11-dev 

###TIGERVNC
# log "Installing required Alpine packages..."
# ping -c 2 qq.com
# alpine31_none: meson \
RUN apk --no-cache add \
curl \
build-base \
clang \
cmake \
autoconf \
automake \
libtool \
pkgconf \
util-macros \
font-util-dev \
xtrans 
# ping -c 2 qq.com
# alpine31_none:
  # libgcrypt-static \
  # libgpg-error-static \
  # libxfont2-dev \
  # libunistring-dev \
  # fltk-dev \
  # libx11-static \
  # libxcb-static \
  # zlib-static \
  # pixman-static \
  # libjpeg-turbo-static \
  # freetype-static \
  # libpng-static \
  # bzip2-static \
  # brotli-static \
  # libunistring-static \
  # nettle-static \
  # gettext-static \
  # libunistring-dev \
RUN xx-apk --no-cache --no-scripts add \
      g++ \
      xcb-util-dev \
      pixman-dev \
      libx11-dev \
      libgcrypt-dev \
      libxkbfile-dev \
      libjpeg-turbo-dev \
      nettle-dev \
      gnutls-dev \
      libxrandr-dev \
      libxtst-dev \
      freetype-dev \
      libfontenc-dev \
      zlib-dev \
    libbsd-dev 


###XDPY
# alpine31_none:
  # libx11-static libxcb-static
RUN xx-apk --no-cache add gcc musl-dev libx11-dev 


###FONTCONFIG
# log "Installing required Alpine packages..."
# alpine31_none:
  # python3 \
  # font-croscore 
RUN apk --no-cache add \
    curl \
    build-base \
    clang \
    pkgconfig \
    gperf 
RUN xx-apk --no-cache --no-scripts add \
    glib-dev \
    g++ \
    freetype-dev \
    expat-dev 

