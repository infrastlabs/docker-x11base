#!/bin/bash

function core(){
##########################################
  # xrdp
  mkdir -p /etc/xrdp && xrdp-keygen xrdp auto #/etc/xrdp/rsakeys.ini
  # rm -rf /etc/xrdp; ln -s /usr/local/static/xrdp/etc/xrdp /etc/xrdp
  # dropbear
  mkdir -p /etc/dropbear

##########################################
# $RUN
  export group=headless
  export user=headless

  # group: $user, sudo
  match1=$(cat /etc/group |grep sudo)
  # groupadd > addgroup
  if [ -s /bin/addgroup ]; then
    addgroup $group; #opsuse15
    test -z "$match1" && addgroup sudo
  else
    groupadd $group; #opsuse15
    test -z "$match1" && groupadd sudo
  fi
  # user
  if [ -s /bin/adduser ]; then
    # busybox: adduser -s /bin/bash -G sudo u2 -S #-S 免密码询问
    adduser -s /bin/bash -g $group -G sudo $user -S
  else
    useradd -mp j9X2HRQvPCphA -s /bin/bash -g $group -G sudo $user
  fi


  echo "$user:$user" |chpasswd
  echo 'Cmnd_Alias SU = /bin/su' |sudo tee -a /etc/sudoers
  echo "$user ALL=(root) NOPASSWD: ALL" |sudo tee -a /etc/sudoers
  
  chmod +x /*.sh
  echo "welcome! HeadlessBox." > /etc/motd
  ln -s /usr/bin/vim.tiny /usr/bin/vt
  rm -f /bin/sh && ln -s /bin/bash /bin/sh
  
  touch /home/$user/.bashrc #not existed @opsuse15
  echo "alias ll='ls -lF'; alias la='ls -A'; alias l='ls -CF';" |sudo tee -a /home/$user/.bashrc; 
  # echo "export PS1='[\u@\h \W]\$ '" > /root/.bashrc


# +002
# $RUN 
    mkdir -p  /usr/share/man/man1/; 
    # # root@vm1:/rootfs/files1/usr/bin# ./gosu 
    # # Usage: gosu user-spec command [args]
    # #    ie: gosu tianon bash
    # #        gosu nobody:root bash -c 'whoami && id'
    # #        gosu 1000:1 id
    # gosu headless bash -c "mkdir -p /home/headless/.config/plank/dock1/launchers"
    # echo "curl mp3.." && gosu headless bash -c "curl --connect-timeout 3 -k -O -fSL https://www.51mp3ring.com/51mp3ring_com3/at20131018141155.mp3";


# dotfiles
# rm -rf /tmp/dots; git clone --depth=1 https://gitee.com/infrastlabs/dotfiles.git /tmp/dots
# cd /tmp/dots && bash refresh.sh
# rm -rf /tmp/dots;
# 
# git clone --depth=1 https://gitee.com/infrastlabs/dotfiles.git /usr/local/static/.dotfiles
bash /usr/local/static/.dotfiles/refresh.sh
}



function app(){
  rm -f /xconf.sh #delete here, @second call
test "app" != "$TYPE" && exit 0 || echo appInstall;

##AUDIO###########################
# Setup D-Bus; ;
# $RUN
  mkdir -p /run/dbus/ && chown messagebus:messagebus /run/dbus/
  dbus-uuidgen > /etc/machine-id
  ln -sf /etc/machine-id /var/lib/dbus/machine-id; 

# @entry
# # for core: avoid multi> 'dbus-daemon --syslog --fork --print-pid 4 --print-address 6 --session'; #(headless x2, root x1)
# kill -9 `ps -ef |grep dbus |grep -v grep |awk '{print $2}'`

##FULL###########################
# IBUS+DCONF env
# $RUN
  find /home/headless/.config |wc
  mkdir -p /home/headless/.config/ibus/rime/
  ln -s /usr/share/rime-data/wubi_pinyin.schema.yaml /home/headless/.config/ibus/rime/
  chown -R headless:headless /home/headless/.; 
  # 
  # #   ##@entry.sh
  # # ibus env
  # # 冗余? 复用/.env?
  # echo "export XMODIFIERS=@im=ibus" |sudo tee -a /etc/profile
  # echo "export GTK_IM_MODULE=ibus" |sudo tee -a /etc/profile
  # echo "export QT_IM_MODULE=ibus" |sudo tee -a /etc/profile;
  # # 
  # # 独立/.env每次entry都重生成;
  # echo "export XMODIFIERS=@im=ibus" |sudo tee -a /.env
  # echo "export GTK_IM_MODULE=ibus" |sudo tee -a /.env
  # echo "export QT_IM_MODULE=ibus" |sudo tee -a /.env;

# ohmybash
# $RUN
  echo "curl oh-my-bash.." && gosu headless bash -c "$(curl -k --connect-timeout 38 -fsSL https://gitee.com/g-system/oh-my-bash/raw/sam-custom/tools/install.sh)"
  rm -rf /home/headless/.oh-my-bash/.git; 
  # danger!
  bash -c 'cd /home/headless/.oh-my-bash/themes && rm -rf `ls |grep -v "axin\|sh$"` || echo "onmybash not exist, skip clear"'
  touch /home/$user/.bashrc #not existed @opsuse15
  sed -i "s^OSH_THEME=\"font\"^OSH_THEME=\"axin\"^g" /home/headless/.bashrc; 
  # sed -i "s^value=\"gnome\"^value=\"Papirus-Bunsen-grey\"^g" /home/headless/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

}

$1
