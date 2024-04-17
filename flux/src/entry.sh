#!/bin/bash

test -z "$PORT_SSH" && export PORT_SSH=10022
test -z "$PORT_RDP" && export PORT_RDP=10089
test -z "$PORT_VNC" && export PORT_VNC=10081
# 
test -z "$SSH_PASS" && export SSH_PASS=headless
test -z "$VNC_PASS" && export VNC_PASS=headless
test -z "$VNC_PASS_RO" && export VNC_PASS_RO=View123
test -z "$VNC_OFFSET" && export VNC_OFFSET=10

# TODO: check port: ssh, rdp, vnc
# sudo: unable to resolve host x11-ubuntu: Name or service not known
match1=$(cat /etc/hosts |egrep "^127.0.0.1 $HOSTNAME")
test ! -z "$match1" && echo "[hosts] existed, skip." || echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

function oneVnc(){
    local N=$1
    local name1=$2
    local user1=xvnc$N
    local port1=$(expr 5900 + $N)
    echo "oneVnc: id=$N, name=$name1"

    # createUser
    if [ "headless" != "$name1" ]; then #固定headless名?
        echo "SKEL=/etc/skel2" |sudo tee -a /etc/default/useradd
        useradd -ms /usr/sbin/nologin xvnc$N;
        sed -i "s^SKEL=/etc/skel2^# SKEL=/etc/skel2^g" /etc/default/useradd
    else
        user1=headless #xvnc$N
    fi

    # SV: xvnc$N.conf
    local xn="x$N"

    # PERP: 
    envcmd="export DISPLAY=:$N; export HOME=/home/$user1" #DISPLAY=:$N,HOME=/home/$user1$env_dbus
    #  de: USER=headless,SHELL=/bin/bash,TERM=xterm,LANG=$L.UTF-8,LANGUAGE=$L:en$env_dbus
    decmd="export USER=headless; export SHELL=/bin/bash; export TERM=xterm"
    #  parec: PORT_VNC=$PORT_VNC$env_dbus
    # xvnc,chansrv
    dest=/etc/perp/$xn-xvnc; mkdir -p $dest/
    cat /etc/perp/tpl-rc.main |sed "s^_CMD_^exec gosu headless bash -c \"$envcmd; exec /xvnc.sh xvnc $N\"^g" > $dest/rc.main
    dest=/etc/perp/$xn-chansrv; mkdir -p $dest
    cat /etc/perp/tpl-rc.main |sed "s^_CMD_^exec gosu headless bash -c \"$envcmd; exec /xvnc.sh chansrv $N\"^g" > $dest/rc.main
    # pulse,parec
    dest=/etc/perp/$xn-pulse; mkdir -p $dest
    cat /etc/perp/tpl-rc.main |sed "s^_CMD_^exec gosu headless bash -c \"$envcmd; exec /xvnc.sh pulse $N\"^g" > $dest/rc.main
    dest=/etc/perp/$xn-parec; mkdir -p $dest
    cat /etc/perp/tpl-rc.main |sed "s^_CMD_^exec gosu headless bash -c \"$envcmd; exec /xvnc.sh parec $N\"^g" > $dest/rc.main
    # 
    # de: gosu headless bash -c "xxx"
    dest=/etc/perp/$xn-de; mkdir -p $dest
    # exec startfluxbox > /dev/null 2>\&1
    cat /etc/perp/tpl-rc.main |sed "s^_CMD_^exec gosu headless bash -c \"$envcmd; $decmd; env |grep -v PASS; source /.env; exec startfluxbox\"^g" > $dest/rc.main


    # XRDP /etc/xrdp/xrdp.ini
    echo """
[Xvnc$N]
name=Xvnc$N
lib=libvnc.so
username=asknoUser
password=askheadless
ip=127.0.0.1
port=$port1
chansrvport=DISPLAY($N)
    """ |sudo tee $tmpDir/xrdp-sesOne$N.conf > /dev/null 2>&1
    # $N atLast
    local line=$(cat /etc/xrdp/xrdp.ini |grep  "^# \[PRE_ADD_HERE\]" -n |cut -d':' -f1)
    line=$(expr $line - 1)
    sed -i "$line r $tmpDir/xrdp-sesOne$N.conf" /etc/xrdp/xrdp.ini
    rm -f $tmpDir/xrdp-sesOne$N.conf

    # noVNC /usr/local/webhookd/static/index.html
    # TODO: fk-webhookd: wsconn识别display10参数; 
    mkdir -p /etc/novnc
    echo "display$N: 127.0.0.1:$port1" |sudo tee -a /etc/novnc/token.conf
    # 
    # echo "<li>[<a href=\"javascript:void(0);\" onclick=\"openVnc('display$N', 'vnc')\">$N-resize</a>&nbsp;&nbsp; <a href=\"javascript:void(0);\" onclick=\"openVnc('display$N', 'vnc_lite')\">lite</a>] | $name1</li>" |sudo tee -a $tmpDir/novncHtml$N.htm
    echo "<li><a href=\"javascript:void(0);\" onclick=\"openVnc('display$N', 'vnc')\">display$N</a></li>" |sudo tee $tmpDir/novncHtml$N.htm > /dev/null 2>&1
    echo "<li><a href=\"javascript:void(0);\" onclick=\"openVnc('display$N', 'vnc_lite')\">display$N-lite</a></li>" |sudo tee -a $tmpDir/novncHtml$N.htm > /dev/null 2>&1
    local line2=$(cat /usr/local/webhookd/static/index.html |grep  "ADD_HERE" -n |cut -d':' -f1)
    line2=$(expr $line2 - 1)
    sed -i "$line2 r $tmpDir/novncHtml$N.htm" /usr/local/webhookd/static/index.html
    rm -f $tmpDir/novncHtml$N.
}

# oneVnc "$id" "$name"
function setXserver(){
    #tpl replace: each revert clean;
    cat /etc/xrdp/xrdp.ini.tpl > /etc/xrdp/xrdp.ini
    cat /etc/novnc/index.html > /usr/local/webhookd/static/index.html
    # /xvnc.sh pulse X; oneVnc: xrdp,novnc sed_add_tmpfile
    # busybox: chown headless:headless > chmod 777
    tmpDir=/tmp/.headless; mkdir -p $tmpDir && chmod 777 -R $tmpDir ; #pulse: default-xx.pa

    # setPorts; sed port=.* || env_ctReset
    sed -i "s^port=3389^port=$PORT_RDP^g" /etc/xrdp/xrdp.ini
    sed -i "s/EFRp 22/EFRp $PORT_SSH/g" /etc/perp/ssh/rc.main #perp
    sed -i "3a\PORT_VNC=$PORT_VNC" /usr/local/webhookd/run.sh #+
    # run.sh line4: PORT_VNC=${PORT_VNC:-10091}; echo "PORT_VNC: $PORT_VNC"

    # sesman
    # SES_PORT=$(echo "${PORT_RDP%??}50") #ref PORT_RDP, replace last 2 char
    SES_PORT=$(expr $PORT_RDP + 1000) #$(($PORT_RDP + 101)); #without sesman's run?
    sed -i "s/ListenPort=3350/ListenPort=${SES_PORT}/g" /etc/xrdp/sesman.ini

    # xvnc0-de
    port0=$(expr 0 + $VNC_OFFSET) #vnc: 5900+10
    oneVnc "$port0" "headless" #sv
    
    # clearPass: if not default
    if [ "headless" != "$VNC_PASS" ]; then
        sed -i "s/password=askheadless/password=ask/g" /etc/xrdp/xrdp.ini
        sed -i "s/value=\"headless\"/value=\"\"/g" /usr/local/webhookd/static/index.html
    fi

    # SSH_PASS VNC_PASS VNC_PASS_RO
    if [ ! -f "$lock" ]; then
        echo "headless:$SSH_PASS" |chpasswd > /dev/null 2>&1
        echo -e "$VNC_PASS\n$VNC_PASS\ny\n$VNC_PASS_RO\n$VNC_PASS_RO"  |vncpasswd /etc/xrdp/vnc_pass > /dev/null 2>&1;
        chmod 644 /etc/xrdp/vnc_pass
        # echo "" #newLine
    fi
    unset SSH_PASS VNC_PASS VNC_PASS_RO #unset, not show in desktopEnv.
    unset LOC_XFCE LOC_APPS LOC_APPS2 DEBIAN_FRONTEND LOCALE_INCLUDE 
}

##xconf.sh#########
#   # 
#   mkdir -p /run/dbus/ && chown messagebus:messagebus /run/dbus/; \
#   dbus-uuidgen > /etc/machine-id; \
#   ln -sf /etc/machine-id /var/lib/dbus/machine-id; \
#   # dconf: ibus, plank, engrampa; dconf dump / > xx.ini
#   mkdir -p /etc/dconf/db;\
#   su - headless -c "dbus-launch dconf reset -f /; dbus-launch dconf load / < /usr/share/dconf.ini; ";\
#   dbus-launch dconf update;

# touch /var/run/dbus/system_bus_socket && chmod 777 /var/run/dbus/system_bus_socket; #pulse: conn dbus err.
# # Start DBUS session bus: (ref: deb9 .flubxbox/startup)
# if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
#     #dbus-daemon --syslog --fork --print-pid 4 --print-address 6 --session
#     eval $(dbus-launch --sh-syntax --exit-with-session)
    echo "D-Bus per-session daemon address is: $DBUS_SESSION_BUS_ADDRESS"
# fi
test -z "$DBUS_SESSION_BUS_ADDRESS" || env_dbus=",DBUS_SESSION_BUS_ADDRESS=\"$DBUS_SESSION_BUS_ADDRESS\""


# Dump environment variables
# https://hub.fastgit.org/hectorm/docker-xubuntu/blob/master/scripts/bin/container-init
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DISPLAY=:$VNC_OFFSET
if [ ! -z "$L" ]; then #export LANG,LANGUAGE
    charset=${L##*.}; test "$charset" == "$L" && charset="UTF-8" || echo "charset: $charset"
    lang_area=${L%%.*}
    export LANG=${lang_area}.${charset}
    export LANGUAGE=${lang_area}:en #default> en
    echo "====LANG: $LANG, LANGUAGE: $LANGUAGE=========================="
fi
 #| grep -Ev '^(.*PASS.*|PWD|OLDPWD|HOME|USER|SHELL|TERM|([^=]*(PASSWORD|SECRET)[^=]*))=' \
env \
 |grep -Ev '_PASS.*|^SHLVL|^HOSTNAME|^PWD|^OLDPWD|^HOME|^USER|^SHELL|^TERM' \
 |grep -Ev "LOC_|DEBIAN_FRONTEND|LOCALE_INCLUDE" | sort |sudo tee /etc/environment > /dev/null 2>&1
# source /.env
: |sudo tee /.env
cat /etc/environment |while read one; do echo export $one | sudo tee -a /.env > /dev/null 2>&1; done
echo "export XMODIFIERS=@im=ibus" |sudo tee -a /etc/profile;\
echo "export GTK_IM_MODULE=ibus" |sudo tee -a /etc/profile;\
echo "export QT_IM_MODULE=ibus" |sudo tee -a /etc/profile;
# \
echo "export XMODIFIERS=@im=ibus" |sudo tee -a /.env;\
echo "export GTK_IM_MODULE=ibus" |sudo tee -a /.env;\
echo "export QT_IM_MODULE=ibus" |sudo tee -a /.env;

# ENV
# DISPLAY=${DISPLAY:-localhost:21}
# PULSE_SERVER=${PULSE_SERVER:-tcp:localhost:4721}
# echo "export DISPLAY=$DISPLAY" |sudo tee -a /tmp/profile.txt
# echo "export PULSE_SERVER=$PULSE_SERVER" |sudo tee -a /tmp/profile.txt


# setlocale: bin/setlocale
lock=/.1stinit.lock
setXserver
test -f "$lock" && echo "[locale] none-first, skip." || setlocale #locale只首次设定(arm下单核cpu占满, 切换-e L=zh_HK时容器重置)
touch $lock

# CONF
test -f /home/headless/.ICEauthority && chmod 644 /home/headless/.ICEauthority #mate err
rm -f /home/headless/.config/autostart/pulseaudio.desktop
# chmod +x /usr/share/applications/*.desktop ##fluxbox> pcmanfm> exec-dialog

# startCMD
# test -z "$START_SESSION" || sed -i "s/startfluxbox/$START_SESSION/g" /etc/systemd/system/de-start.service
test -z "$START_SESSION" || sed -i "s/startfluxbox/$START_SESSION/g" /etc/perp/x$VNC_OFFSET-de/rc.main

cnt=0.1
echo "sleep $cnt" && sleep $cnt;

# link parec
rm -f /usr/bin/parec; ln -s /usr/bin/pacat /usr/bin/parec

# 
# http://b0llix.net/perp/site.cgi?page=tinylog.8
cat > /etc/tinylog.conf  <<EOF
export TINYLOG_USER=root #tinylog
export TINYLOG_BASE=/var/log/tinylog #/var/log
export TINYLOG_OPTS="-k2 -s1000 -z" #keep2, size1000, gzip
EOF

cat > /usr/sbin/runtool <<EOF
#!/bin/bash
# -u xxx;
# shift
# shift
# exec \$@
#DO gosu
shift; user1=\$1
shift
cmd="\$@" #fix bash -c "exec \$@"
exec gosu \$user1 bash -c "exec \$cmd";
EOF
chmod +x /usr/sbin/runtool

function rclog(){
cat > /etc/perp/$one/rc.log <<EOF
#!/bin/sh
if test \${1} = 'start' ; then
  exec tinylog_run \${2}
fi
exit 0
EOF
}

# autostart: <perpctl A xx> dir sticky
#  设定再启动perpd才有效，启动后再设定会提示err
# https://blog.csdn.net/qq_21438461/article/details/131021640
# chmod o+t > chmod 1755 #o+t: busybox,openwrt不支持
ls -F /etc/perp/ |grep "/$" |while read one; do
  chmod 1755 /etc/perp/$one;
  test ! -z "$(echo $one |grep -E '^x.*-de|^x.*-xvnc')" && rclog;
done
# set rc.* executable 
chmod +x /etc/perp/**/rc.*

# sv
file=/usr/bin/sv; rm -f $file;
cat /usr/bin/psv.sh > $file;
chmod +x $file;

# bash-5.2# echo $PS1  ##@openwrt
# \s-\v\$
export PS1='[\u@\h \W]\$ '

export PERP_BASE=/etc/perp; dst=/var/log/tinylog/_perp; mkdir -p $dst
# exec /usr/sbin/tini -- perpd
# exec perpd |tinylog -k2 -s1000 -z $dst
exec perpd > >(exec tinylog -k2 -s1000 -z $dst) 2>&1