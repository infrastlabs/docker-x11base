#!/bin/bash
cur=$(cd "$(dirname "$0")"; pwd)

# clear ###########################################
cat $cur/usr-local-static-dir.txt |grep -Ev "^#|^$" |while read one; do
  rm -rf /rootfs/$one
done
cat $cur/*file*.txt |grep -Ev "^#|^$" |while read one; do
  rm -f /rootfs/$one
done

# upx ###########################################
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
  # 只 upx ELF 二进制；脚本(shebang #!)跳过——UPX --shell 压 bash/sh 脚本运行会坏(genentries 报 can: command not found)
  # 纯 bash 内置判文件头魔数(零外部命令, 不依赖 file/od): read -N4 读前4字节, = \177ELF 才是 ELF
  magic=""; IFS= read -r -N4 magic < "$one" 2>/dev/null || true
  test "$magic" = "$(printf '\177ELF')" || { echo -e "\n[skip script] $one"; continue; }
  echo -e "\n[upx] $one"
  du -sh $one
  upx -7 $one > /dev/null 2>&1 #-7: ref webhookd
  du -sh $one
done

# link-bin,sbin ###########################################
  rm -rf  /rootfs/usr/bin /rootfs/usr/sbin
  rfs=/rootfs/; mkdir -p ${rfs}usr/bin ${rfs}usr/sbin
  cd ${rfs}; echo -e "\n[link] ${rfs}usr/sbin/ ${rfs}usr/bin/"
  find usr/local/static -type f |grep -Ev "/\.dotfiles/" |grep -E "/bin/|/sbin/" |sort | \
    while read one; do du -sh $one; t=${one%/*}; ln -s /$one usr/${t##*/}/; done
  # link usr/share/applications
  mkdir -p usr/share/applications; \
  find usr/local/static/ -type f |grep "/applications/" |grep -E "\.desktop$" |sort | \
    while read one; do ln -s /$one usr/share/applications/; done; 

# link-openbox-theme ###########################################
find  /rootfs/usr/local/static/openbox/share/ -type d |grep openbox-3 |while read one; do
  one=$(echo $one |sed "s^/rootfs^^g"); 
  dst=$(echo $one |sed "s^local/static/openbox/^^g"); 
  # dst-not-exist: 56.08 ln: /rootfs/usr/share/themes/Clearlooks-Olive/openbox-3: No such file or directory
  dst=/rootfs$dst
  mkdir -p $dst; rm -rf $dst;
  ln -s $one $dst #link
done

exit 0
