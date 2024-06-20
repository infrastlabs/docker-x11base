#!/bin/bash
# rm -f /xconf2.sh
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


# dotfiles
rm -rf /tmp/dots; git clone --depth=1 https://gitee.com/infrastlabs/dotfiles.git /tmp/dots
cd /tmp/dots && bash refresh.sh
rm -rf /tmp/dots;
