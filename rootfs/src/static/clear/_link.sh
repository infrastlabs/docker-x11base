#!/bin/bash

# link-bin,sbin
rfs=/; mkdir -p ${rfs}usr/bin ${rfs}usr/sbin #rfs=/rootfs/
cd ${rfs}; echo -e "\n[link] ${rfs}usr/sbin/ ${rfs}usr/bin/"
find usr/local/static -type f |grep -Ev "/\.dotfiles/" |grep -E "/bin/|/sbin/" |sort | \
  while read one; do du -sh $one; t=${one%/*}; echo ln -s /$one usr/${t##*/}/; done
