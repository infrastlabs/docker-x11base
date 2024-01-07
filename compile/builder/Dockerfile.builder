
# Get Dockerfile cross-compilation helpers.
# --platform=$BUILDPLATFORM 
FROM tonistiigi/xx AS xx

# Build UPX.
FROM alpine:3.15 AS upx
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.15/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.15/community" >> /etc/apk/repositories
#RUN ping -c 2 qq.com; apk update;
RUN apk update; apk --no-cache add build-base curl make cmake git;
RUN mkdir /tmp/upx && \
    curl -# -L https://ghproxy.com/https://github.com/upx/upx/releases/download/v4.0.1/upx-4.0.1-src.tar.xz | tar xJ --strip 1 -C /tmp/upx && \
    make -C /tmp/upx build/release-gcc -j$(nproc) && \
    cp -v /tmp/upx/build/release-gcc/upx /usr/bin/upx


FROM alpine:3.15 AS builder
ARG TARGETPLATFORM
# https://www.jakehu.me/2021/alpine-mirrors/
# domain="mirrors.ustc.edu.cn"
# domain="mirrors.aliyun.com";
# mirrors.tuna.tsinghua.edu.cn
RUN export domain="mirrors.ustc.edu.cn"; \
  echo "http://$domain/alpine/v3.15/main" > /etc/apk/repositories; \
  echo "http://$domain/alpine/v3.15/community" >> /etc/apk/repositories
#
COPY --from=xx / /
COPY --from=upx /usr/bin/upx /usr/bin/upx
RUN apk update; apk --no-cache add make clang
RUN xx-apk --no-cache add gcc musl-dev libx11-dev libx11-static libxcb-static

###TIGERVNC
# log "Installing required Alpine packages..."
# ping -c 2 qq.com
RUN apk --no-cache add \
    curl \
    build-base \
    clang \
    cmake \
    autoconf \
    automake \
    libtool \
    pkgconf \
    meson \
    util-macros \
    font-util-dev \
    xtrans 
# ping -c 2 qq.com
RUN xx-apk --no-cache --no-scripts add \
    g++ \
    xcb-util-dev \
    pixman-dev \
    libx11-dev \
    libgcrypt-dev \
    libgcrypt-static \
    libgpg-error-static \
    libxkbfile-dev \
    libxfont2-dev \
    libjpeg-turbo-dev \
    nettle-dev \
    libunistring-dev \
    gnutls-dev \
    fltk-dev \
    libxrandr-dev \
    libxtst-dev \
    freetype-dev \
    libfontenc-dev \
    zlib-dev \
    libx11-static \
    libxcb-static \
    zlib-static \
    pixman-static \
    libjpeg-turbo-static \
    freetype-static \
    libpng-static \
    bzip2-static \
    brotli-static \
    libunistring-static \
    nettle-static \
    gettext-static \
    libunistring-dev \
    libbsd-dev 


###XDPY
RUN xx-apk --no-cache add gcc musl-dev libx11-dev libx11-static libxcb-static


###FONTCONFIG
# log "Installing required Alpine packages..."
RUN apk --no-cache add \
    curl \
    build-base \
    clang \
    pkgconfig \
    gperf \
    python3 \
    font-croscore 
RUN xx-apk --no-cache --no-scripts add \
    glib-dev \
    g++ \
    freetype-dev \
    expat-dev 

