#!/bin/sh
set -e
source /src/common.sh

#
# Build dropbear
#
function dropbear(){
  log "Downloading DROPBEAR..."
  rm -rf /tmp/dropbear; # mkdir -p /tmp/dropbear
  # down_catfile ${DROPBEAR_URL} | tar -zx --strip 1 -C /tmp/dropbear
  # branch="--branch=$DROPBEAR_VER"
  git clone --depth=1 $branch https://github.com/mkj/dropbear /tmp/dropbear #;
  log "Configuring DROPBEAR..."
  cd /tmp/dropbear #&& ./bootstrap;
  ./configure  --enable-static --prefix=$TARGETPATH
  make

  log "Install DROPBEAR..."
  # make;
  make install;

  # view
  ls -lh /tmp/dropbear/
  xx-verify --static /tmp/dropbear/dropbear
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    dropbear
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
