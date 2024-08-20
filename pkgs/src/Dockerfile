# ARG REPO=
FROM alpine:3.13.12
# Set multiple labels at once, author,builtdate
LABEL \
  github.com.infrastlabs.docker-x11base.vendor=Infrastlabs \
  github.com.infrastlabs.docker-x11base.release="production" \
  github.com.infrastlabs.docker-x11base.version="1.0.1-beta" \
  github.com.infrastlabs.docker-x11base.maintainer="sam <sldevsir@126.com>" \
  github.com.infrastlabs.docker-x11base.builtdate="$(date -u +'%Y-%m-%d %H:%M:%S')"
ARG TARGETPLATFORM
RUN sed -i "s^dl-cdn.alpinelinux.org^mirrors.tuna.tsinghua.edu.cn^g" /etc/apk/repositories; \
  apk add bash curl xz
# RUN \
# case ${TARGETPLATFORM} in \
#   "linux/amd64")  arch=amd64    ;; \
#   "linux/arm64")  arch=arm64     ;; \
#   "linux/arm/v7") arch=armhf   ;; \
#   "linux/arm/v6") arch=armel   ;; \
#   "linux/386")    arch=NONE_i386 ;; \
# esac; 
ADD ./down/2408 /down/2408



