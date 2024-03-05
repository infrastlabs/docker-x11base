#!/bin/bash

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
    local varlog=/var/log/supervisor
    echo """
#[program:xvnc$N-$name1]
[program:$xn-xvnc]
environment=DISPLAY=:$N,HOME=/home/$user1$env_dbus
priority=35
user=$user1
startretries=5
autorestart=true
command=/xvnc.sh xvnc $N
stdout_logfile=$varlog/$xn-xvnc.log
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
redirect_stderr=true

[program:$xn-chansrv]
environment=DISPLAY=:$N,HOME=/home/$user1$env_dbus
priority=36
user=$user1
startretries=5
autorestart=true
command=/xvnc.sh chansrv $N
stdout_logfile=$varlog/$xn-chansrv.log
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
redirect_stderr=true

[program:$xn-pulse]
environment=DISPLAY=:$N,HOME=/home/$user1$env_dbus
priority=36
user=$user1
startretries=5
autorestart=true
command=/xvnc.sh pulse $N
stdout_logfile=$varlog/$xn-pulse.log
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
redirect_stderr=true

[program:$xn-parec]
environment=DISPLAY=:$N,HOME=/home/$user1,PORT_VNC=$PORT_VNC$env_dbus
priority=37
user=$user1
startretries=5
autorestart=true
command=/xvnc.sh parec $N
stdout_logfile=$varlog/$xn-parec.log
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
redirect_stderr=true
    """ |sudo tee /etc/supervisor/conf.d/xvnc$N.conf > /dev/null 2>&1
    # SV: x$N-de.conf
    echo """
[program:$xn-de]
#,LANG=$L.UTF-8,LANGUAGE=$L:en #cur: 不加没中文
environment=DISPLAY=:$N,HOME=/home/headless,USER=headless,SHELL=/bin/bash,TERM=xterm,LANG=$L.UTF-8,LANGUAGE=$L:en$env_dbus
priority=45
user=headless
startretries=5
command=bash -c \"env |grep -v PASS; source /.env; exec startfluxbox\"
stdout_logfile=/var/log/supervisor/$xn-de.log
stdout_logfile_maxbytes = 50MB
stdout_logfile_backups  = 10
redirect_stderr=true    
    """ |sudo tee /etc/supervisor/conf.d/x$N-de.conf > /dev/null 2>&1

    # PERP: x-xvnc,chansrv,pulse,parec
    envcmd="export DISPLAY=:$N; export HOME=/home/$user1" #DISPLAY=:$N,HOME=/home/$user1$env_dbus
    #  de: USER=headless,SHELL=/bin/bash,TERM=xterm,LANG=$L.UTF-8,LANGUAGE=$L:en$env_dbus
    decmd="export USER=headless; export SHELL=/bin/bash; export TERM=xterm"
    #  parec: PORT_VNC=$PORT_VNC$env_dbus
    # 
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
    # gosu headless bash -c "xxx"
    dest=/etc/perp/$xn-de; mkdir -p $dest
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
    
    
    # frpc.ini
    local ip=$(echo $FRPC_CONN |cut -d':' -f1)
    local port=$(echo $FRPC_CONN |cut -d':' -f2)
    local admin_port=$(expr 7500 + $VNC_OFFSET) #7521
    echo """
[common]
server_addr = $ip
server_port = $port

# set admin address for control frpc's action by http api such as reload
admin_addr = 127.0.0.1
admin_port = 7400
admin_user = headless
admin_pwd = headless

[$xn-frpc-admin]
type = tcp
local_ip = 127.0.0.1
local_port = 7400
remote_port = $admin_port

[$xn-ssh]
type = tcp
local_ip = 127.0.0.1
local_port = $(expr $PORT_SSH - 100)
remote_port = ${PORT_SSH}
[$xn-xrdp]
type = tcp
local_ip = 127.0.0.1
local_port = $(expr $PORT_RDP - 100)
remote_port = ${PORT_RDP}
[$xn-novnc]
type = tcp
local_ip = 127.0.0.1
local_port = $(expr $PORT_VNC - 100)
remote_port = ${PORT_VNC}
    """ |sudo tee /etc/frp/frpc.ini > /dev/null 2>&1
}

function frp(){
    mkdir -p /etc/frp
    # frps.ini
    # local port=$(echo $FRPC_CONN |cut -d':' -f2)
    local port=$(echo $FRPS_BIND |cut -d':' -f2)
    echo """
[common]
#10080
bind_port = $port

#10080-1 #10080 forbid by browser
dashboard_port = $(expr $port - 1)
#user,pass optional
dashboard_user = headless
dashboard_pwd = headless
# dashboard_tls_mode = true
# dashboard_tls_cert_file = server.crt
# dashboard_tls_key_file = server.key
    """ |sudo tee /etc/frp/frps.ini > /dev/null 2>&1
    # frpc.ini
}
frp

# oneVnc "$id" "$name"
function setXserver(){
    #tpl replace: each revert clean;
    cat /etc/xrdp/xrdp.ini.tpl > /etc/xrdp/xrdp.ini
    cat /etc/novnc/index.html > /usr/local/webhookd/static/index.html
    # /xvnc.sh pulse X; oneVnc: xrdp,novnc sed_add_tmpfile
    tmpDir=/tmp/.headless; mkdir -p $tmpDir && chown headless:headless -R $tmpDir ; #pulse: default-xx.pa

    # setPorts; sed port=.* || env_ctReset
    sed -i "s^port=3389^port=$(expr $PORT_RDP - 100)^g" /etc/xrdp/xrdp.ini
    sed -i "s/EFRp 22/EFRp $(expr $PORT_SSH - 100)/g" /etc/supervisor/conf.d/sv.conf #sv.conf
    sed -i "s/EFRp 22/EFRp $(expr $PORT_SSH - 100)/g" /etc/perp/ssh/rc.main #perp
    sed -i "3a\PORT_VNC=$(expr $PORT_VNC - 100)" /usr/local/webhookd/run.sh #+
    # run.sh line4: PORT_VNC=${PORT_VNC:-10091}; echo "PORT_VNC: $PORT_VNC"

    # sesman
    # SES_PORT=$(echo "${PORT_RDP%??}50") #ref PORT_RDP, replace last 2 char
    SES_PORT=$(expr $PORT_RDP - 100 + 1000) #$(($PORT_RDP + 101)); #without sesman's run?
    sed -i "s/ListenPort=3350/ListenPort=${SES_PORT}/g" /etc/xrdp/sesman.ini

    # go-sv
    PORT_SV=$(($PORT_SSH + 1)) #10022> 10023
    sed -i "s/port=0.0.0.0:.*/port=0.0.0.0:${PORT_SV}/g" /etc/supervisor/supervisord.conf
    
    # xvnc0-de
    port0=$(expr 0 + $VNC_OFFSET) #vnc: 5900+10
    # sed -i "s/_DISPLAY_/$port0/" /etc/supervisor/conf.d/sv.conf
    oneVnc "$port0" "headless" #sv
    
    # de-start.service
    # sed -i "s/Environment=DISPLAY=.*/Environment=DISPLAY=:$VNC_OFFSET/g" /etc/systemd/system/de-start.service
    # sed -i "s/Environment=LANG=.*/Environment=LANG=$L.UTF-8/g" /etc/systemd/system/de-start.service
    # sed -i "s/Environment=LANGUAGE=.*/Environment=LANGUAGE=$L:en/g" /etc/systemd/system/de-start.service

    # clearPass: if not default
    if [ "headless" != "$VNC_PASS" ]; then
        sed -i "s/password=askheadless/password=ask/g" /etc/xrdp/xrdp.ini
        sed -i "s/value=\"headless\"/value=\"\"/g" /usr/local/webhookd/static/index.html
    fi

    # SSH_PASS VNC_PASS VNC_PASS_RO
    if [ ! -f "$lock" ]; then
        echo "headless:$SSH_PASS" |chpasswd
        echo -e "$VNC_PASS\n$VNC_PASS\ny\n$VNC_PASS_RO\n$VNC_PASS_RO"  |vncpasswd /etc/xrdp/vnc_pass; chmod 644 /etc/xrdp/vnc_pass
        echo "" #newLine
        # SV: headless:VNC_PASS_RO
        sed -i "s/password=.*/password=${VNC_PASS_RO}/g" /etc/supervisor/supervisord.conf
    fi
    unset SSH_PASS VNC_PASS VNC_PASS_RO #unset, not show in desktopEnv.
    unset LOC_XFCE LOC_APPS LOC_APPS2 DEBIAN_FRONTEND    
}

# touch /var/run/dbus/system_bus_socket && chmod 777 /var/run/dbus/system_bus_socket; #pulse: conn dbus err.
# # Start DBUS session bus: (ref: deb9 .flubxbox/startup)
# if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
#     #dbus-daemon --syslog --fork --print-pid 4 --print-address 6 --session
#     eval $(dbus-launch --sh-syntax --exit-with-session)
    echo "D-Bus per-session daemon address is: $DBUS_SESSION_BUS_ADDRESS"
# fi
test -z "$DBUS_SESSION_BUS_ADDRESS" || env_dbus=",DBUS_SESSION_BUS_ADDRESS=\"$DBUS_SESSION_BUS_ADDRESS\""
lock=/.1stinit.lock
setXserver

##xconf.sh#########
#   # 
#   mkdir -p /run/dbus/ && chown messagebus:messagebus /run/dbus/; \
#   dbus-uuidgen > /etc/machine-id; \
#   ln -sf /etc/machine-id /var/lib/dbus/machine-id; \
#   # dconf: ibus, plank, engrampa; dconf dump / > xx.ini
#   mkdir -p /etc/dconf/db;\
#   su - headless -c "dbus-launch dconf reset -f /; dbus-launch dconf load / < /usr/share/dconf.ini; ";\
#   dbus-launch dconf update;

# setLocale: bin/setlocale
test -f "$lock" && echo "[locale] none-first, skip." || setlocale #locale只首次设定(arm下单核cpu占满, 切换-e L=zh_HK时容器重置)
touch $lock
# TODO export LANG LANGUAGE to supervisord <sv,sysd>

# Dump environment variables
# https://hub.fastgit.org/hectorm/docker-xubuntu/blob/master/scripts/bin/container-init
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export DISPLAY=:$VNC_OFFSET
 #| grep -Ev '^(.*PASS.*|PWD|OLDPWD|HOME|USER|SHELL|TERM|([^=]*(PASSWORD|SECRET)[^=]*))=' \
env \
 |grep -Ev '_PASS$|^SHLVL|^HOSTNAME|^PWD|^OLDPWD|^HOME|^USER|^SHELL|^TERM' \
 |grep -Ev "LOC_|DEBIAN_FRONTEND|LOCALE_INCLUDE" | sort |sudo tee /etc/environment > /dev/null 2>&1
# source /.env
: |sudo tee /.env
cat /etc/environment |while read one; do echo export $one | sudo tee -a /.env > /dev/null 2>&1; done
echo "export XMODIFIERS=@im=ibus" |sudo tee -a /.env
echo "export GTK_IM_MODULE=ibus" |sudo tee -a /.env
echo "export QT_IM_MODULE=ibus" |sudo tee -a /.env

# ENV
# DISPLAY=${DISPLAY:-localhost:21}
# PULSE_SERVER=${PULSE_SERVER:-tcp:localhost:4721}
# echo "export DISPLAY=$DISPLAY" |sudo tee -a /tmp/profile.txt
# echo "export PULSE_SERVER=$PULSE_SERVER" |sudo tee -a /tmp/profile.txt

# CONF
test -f /home/headless/.ICEauthority && chmod 644 /home/headless/.ICEauthority #mate err
rm -f /home/headless/.config/autostart/pulseaudio.desktop
# chmod +x /usr/share/applications/*.desktop ##fluxbox> pcmanfm> exec-dialog

# startCMD
test -z "$START_SESSION" || sed -i "s/startfluxbox/$START_SESSION/g" /etc/systemd/system/de-start.service
test -z "$START_SESSION" || sed -i "s/startfluxbox/$START_SESSION/g" /etc/supervisor/conf.d/x$VNC_OFFSET-de.conf

cnt=0.1
echo "sleep $cnt" && sleep $cnt;
# test "true" != "$START_SYSTEMD" || rm -f /etc/supervisor/conf.d/x$VNC_OFFSET-de.conf
# test "true" != "$START_SYSTEMD" && exec go-supervisord || exec /lib/systemd/systemd

# link parec
rm -f /usr/bin/parec; ln -s /usr/bin/pacat /usr/bin/parec

# 
# set rc.* executable
chmod +x /etc/perp/**/rc.*
# autostart: <perpctl A xx> dir sticky
#  设定再启动perpd才有效，启动后再设定会提示err
ls -F /etc/perp/ |grep "/$" |while read one; do chmod o+t /etc/perp/$one; done
frps_port=$(echo $FRPS_BIND |cut -d':' -f2)
test "-1" == "$frps_port" && chmod o-t /etc/perp/frps #-1 不启动; TODO sv.conf: autorestart?

# sv
# ln -s /usr/bin/supervisorctl /usr/bin/sv
file=/usr/bin/sv; rm -f $file;
if [ "$INIT" == "supervisord" ]; then
  echo -e "#!/bin/bash\ntest -z "\$1" && go-supervisord ctl -h || go-supervisord ctl \$@" > $file;
else
  cat /usr/bin/psv.sh > $file;
fi
chmod +x $file;

# supervisord -n> go-supervisord
# exec supervisord -n
# exec go-supervisord
# exec /sbin/tini -- perpd
# alpine: not /sbin > /usr/sbin
test "$INIT" == "supervisord" && exec go-supervisord || exec /usr/sbin/tini -- perpd
