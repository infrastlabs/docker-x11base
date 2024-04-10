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
  echo "alias ll='ls -lF'; alias la='ls -A'; alias l='ls -CF';" |sudo tee -a /home/$user/.bashrc; 
  # echo "export PS1='[\u@\h \W]\$ '" > /root/.bashrc


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
