#!/bin/sh
set -e
source /src/common.sh

#
# Build perp
#
function perp(){
  log "Downloading perp..."
  git clone https://gitee.com/infrastlabs/fk-perp /tmp/fk-perp
  cd /tmp/fk-perp

  log "Compiling perp..."
  # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
  make -C lasagna/
  make -C perp/
  #make -C runtools/

  log "Installing perp..."
  make -C perp/ install

  # view
  ls -lh /tmp/fk-perp/perp
  xx-verify --static /tmp/fk-perp/perp/perpd
  xx-verify --static /tmp/fk-perp/perp/perpctl
  xx-verify --static /tmp/fk-perp/perp/perpls
}


case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    # down_catfile ${FDKAAC_URL} > /dev/null
    ;;
full)
    perp
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
