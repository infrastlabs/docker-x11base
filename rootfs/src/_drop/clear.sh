#!/bin/bash
cur=$(cd "$(dirname "$0")"; pwd)

# clear
cat $cur/usr-local-static-dir.txt |grep -Ev "^#|^$" |while read one; do
  rm -rf /rootfs/$one
done
cat $cur/*file*.txt |grep -Ev "^#|^$" |while read one; do
  rm -f /rootfs/$one
done

# upx
ln -s /rootfs/usr/local/static/3rd/bin/upx /bin/upx
upx -V
# root@tenvm2:/usr/local/static/3rd# tree -h
# |-- [4.0K]  bin
# |   |-- [1.2M]  gosu
# |   |-- [550K]  upx
# |   `-- [9.3M]  yq
# `-- [4.0K]  sbin
#     |-- [ 13M]  frpc
#     |-- [ 15M]  frps
#     `-- [ 24K]  tini
find /rootfs/usr/local/static -type f |grep -E "/sbin/|/bin/" |grep -v "/3rd/bin/upx" |sort |while read one; do
  echo -e "\n[upx] $one"
  du -sh $one
  upx -7 $one > /dev/null 2>&1 #-7: ref webhookd
  du -sh $one
done

# link-bin,sbin
  rm -rf  /rootfs/usr/bin /rootfs/usr/sbin; mkdir -p /rootfs/usr/bin /rootfs/usr/sbin;

  # clear-xrdp;
  # needed: lib/xrdp/libvnc.so;
  # find /rootfs/usr/local/static -type d |grep -E "/share/man$|xrdp/lib$" | \
  #   while read one; do du -sh $one; rm -rf $one; done; \
  echo -e "\n[link] /rootfs/usr/sbin/"
  find /rootfs/usr/local/static -type f |grep "/sbin/" |sort | \
    while read one; do ls -lh $one; one2=$(echo $one|sed "s^/rootfs^^g"); ln -s $one2 /rootfs/usr/sbin/; done; \

  echo -e "\n[link] /rootfs/usr/bin/"
  find /rootfs/usr/local/static -type f |grep "/bin/" |sort | \
    while read one; do ls -lh $one; one2=$(echo $one|sed "s^/rootfs^^g"); ln -s $one2 /rootfs/usr/bin/; done;

# link-openbox-theme
find  /rootfs/usr/local/static/openbox/share/ -type d |grep openbox-3 |while read one; do
  one=$(echo $one |sed "s^/rootfs^^g"); 
  dst=$(echo $one |sed "s^local/static/openbox/^^g"); 
  # dst-not-exist: 56.08 ln: /rootfs/usr/share/themes/Clearlooks-Olive/openbox-3: No such file or directory
  dst=/rootfs$dst
  mkdir -p $dst; rm -rf $dst;
  ln -s $one $dst #link
done

exit 0
