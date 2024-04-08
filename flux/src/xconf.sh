#!/bin/bash
rm -f /xconf.sh

##########################################
  # xrdp
  mkdir -p /etc/xrdp && xrdp-keygen xrdp auto #/etc/xrdp/rsakeys.ini
  # rm -rf /etc/xrdp; ln -s /usr/local/static/xrdp/etc/xrdp /etc/xrdp

  # dropbear
  mkdir -p /etc/dropbear

##########################################
# echo emp; << fix match1
  # mkdir -p /var/log/supervisor; \
$RUN \
  echo "" > /dev/null; \
  match1=$(cat /etc/group |grep sudo); \
  # groupadd > addgroup
  if [ -s /bin/addgroup ]; then \
    test -z "$match1" && addgroup sudo; \
  else \
    test -z "$match1" && groupadd sudo; \
  fi; \
  \
  export user=headless; \
  if [ -s /bin/adduser ]; then \
    # busybox: adduser -s /bin/bash -G sudo u2 -S #-S 免密码询问
    adduser -s /bin/bash -G sudo $user -S; \
  else \
    useradd -mp j9X2HRQvPCphA -s /bin/bash -G sudo $user; \
  fi; \
  echo "$user:$user" |chpasswd \
  && echo 'Cmnd_Alias SU = /bin/su' |sudo tee -a /etc/sudoers \
  && echo "$user ALL=(root) NOPASSWD: ALL" |sudo tee -a /etc/sudoers \
  \
  && chmod +x /*.sh; \
  test -f /usr/bin/dbus-daemon && chmod 700 /usr/bin/dbus-* || echo "dbus skip chmod."; \
  test -f /usr/bin/dbus-daemon && chown headless:headless /usr/bin/dbus-* || echo "dbus skip chown."; \
  \
  chmod +x /*.sh \
  && echo "welcome! HeadlessBox." > /etc/motd \
  && ln -s /usr/bin/vim.tiny /usr/bin/vt \
  && rm -f /bin/sh && ln -s /bin/bash /bin/sh; \
  \
  echo "alias ll='ls -lF'; alias la='ls -A'; alias l='ls -CF';" |sudo tee -a /home/$user/.bashrc


# +002
$RUN \
    mkdir -p  /usr/share/man/man1/; 
    # # root@vm1:/rootfs/files1/usr/bin# ./gosu 
    # # Usage: gosu user-spec command [args]
    # #    ie: gosu tianon bash
    # #        gosu nobody:root bash -c 'whoami && id'
    # #        gosu 1000:1 id
    # gosu headless bash -c "mkdir -p /home/headless/.config/plank/dock1/launchers"; \
    # echo "curl mp3.." && gosu headless bash -c "curl --connect-timeout 3 -k -O -fSL https://www.51mp3ring.com/51mp3ring_com3/at20131018141155.mp3";

##AUDIO###########################
# # Setup D-Bus; ;
# $RUN \
#   mkdir -p /run/dbus/ && chown messagebus:messagebus /run/dbus/; \
#   dbus-uuidgen > /etc/machine-id; \
#   ln -sf /etc/machine-id /var/lib/dbus/machine-id; 
  

##FULL###########################
# # IBUS+DCONF env
# $RUN \
#   find /home/headless/.config |wc; \
#   mkdir -p /home/headless/.config/ibus/rime/; \
#   ln -s /usr/share/rime-data/wubi_pinyin.schema.yaml /home/headless/.config/ibus/rime/; \
#   chown -R headless:headless /home/headless/.config; \
#   \
#   # ibus env
#   # 冗余? 复用/.env?
#   echo "export XMODIFIERS=@im=ibus" |sudo tee -a /etc/profile;\
#   echo "export GTK_IM_MODULE=ibus" |sudo tee -a /etc/profile;\
#   echo "export QT_IM_MODULE=ibus" |sudo tee -a /etc/profile;\
#   \
#   # 独立/.env每次entry都重生成;
#   echo "export XMODIFIERS=@im=ibus" |sudo tee -a /.env;\
#   echo "export GTK_IM_MODULE=ibus" |sudo tee -a /.env;\
#   echo "export QT_IM_MODULE=ibus" |sudo tee -a /.env;\
#   \
#   # dconf: ibus, plank, engrampa; dconf dump / > xx.ini
#   mkdir -p /etc/dconf/db;\
#   gosu headless bash -c "dbus-launch dconf reset -f /; dbus-launch dconf load / < /home/headless/dconf.ini; ";\
#   dbus-launch dconf update;

# # for core: avoid multi> 'dbus-daemon --syslog --fork --print-pid 4 --print-address 6 --session'; #(headless x2, root x1)
# kill -9 `ps -ef |grep dbus |grep -v grep |awk '{print $2}'`

# # LOCALE, OHMYBASH, SETTINGS
# $RUN \
#   echo "curl oh-my-bash.." && gosu headless bash -c "$(curl -k --connect-timeout 8 -fsSL https://gitee.com/g-system/oh-my-bash/raw/sam-custom/tools/install.sh)"; \
#   rm -rf /home/headless/.oh-my-bash/.git; 
#   # danger!
#   bash -c 'cd /home/headless/.oh-my-bash/themes && rm -rf `ls |grep -v "axin\|sh$"` || echo "onmybash not exist, skip clear"'; \
#   \
#   sed -i "s^OSH_THEME=\"font\"^OSH_THEME=\"axin\"^g" /home/headless/.bashrc; 
#   # sed -i "s^value=\"gnome\"^value=\"Papirus-Bunsen-grey\"^g" /home/headless/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml; \
