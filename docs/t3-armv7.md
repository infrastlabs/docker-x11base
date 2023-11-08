
```bash
root@825b6abd8dbb:/usr/local/static# ls
dropbear  fluxbox  openbox  suckless  tigervnc  xrdp
```

- dropbear

```bash
root@825b6abd8dbb:/usr/local/static/dropbear/sbin# ./dropbear
root@825b6abd8dbb:/usr/local/static/dropbear/sbin# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 08:09 pts/0    00:00:00 bash
root        11     1  0 08:10 pts/0    00:00:00 ../../tigervnc/bin/Xvnc :23
root        30     1  0 08:12 ?        00:00:00 ./dropbear
root        31     1  0 08:12 pts/0    00:00:00 ps -ef
root@825b6abd8dbb:/usr/local/static/dropbear/sbin# ./dropbear  -h

root@825b6abd8dbb:/usr/local/static/dropbear/sbin# netstat -ntlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      30/./dropbear
tcp        0      0 0.0.0.0:5923            0.0.0.0:*               LISTEN      11/../../tigervnc/b
tcp6       0      0 :::22                   :::*                    LISTEN      30/./dropbear
tcp6       0      0 :::5923                 :::*                    LISTEN      11/../../tigervnc/b
```

- Xvnc

```bash
root@6be0b291f5b2:/rootfs/files1/usr/local/static/tigervnc/bin# ln -s /rootfs/files1/usr/local/static /usr/local/static
root@6be0b291f5b2:/rootfs/files1/usr/local/static/tigervnc/bin# ./Xvnc  :23

Xvnc TigerVNC 1.13.1 - built Nov  4 2023 06:03:50
Copyright (C) 1999-2022 TigerVNC Team and many others (see README.rst)
See https://www.tigervnc.org for information on TigerVNC.
Underlying X server release 12014000


Fri Nov 10 08:07:45 2023
 vncext:      VNC extension running!
 vncext:      Listening for VNC connections on all interface(s), port 5923
 vncext:      created VNC server for screen 0
^C
Fri Nov 10 08:07:48 2023
 ComparingUpdateTracker: 0 pixels in / 0 pixels out
 ComparingUpdateTracker: (1:nan ratio)
root@6be0b291f5b2:/rootfs/files1/usr/local/static/tigervnc/bin#
```

- fluxbox


```bash
# root@825b6abd8dbb:/usr/local/static/fluxbox/bin# history |tail -12
    1  ln -s /rootfs/files1/usr/local/static /usr/local/static
    2  cd /usr/local/static/fluxbox/
    3  ls
    4  cd bin/
    5  ls
    6  ../../tigervnc/bin/Xvnc :23 &
    7  ./fluxbox
    8  export DISPLAY=:23
    9  ./fluxbox
Failed to read: session.screen0.systray.pinLeft
Setting default value
Failed to read: session.screen0.systray.pinRight
Setting default value
Failed to read: session.screen0.strftimeFormat
Setting default value
^C
```

- suckless

```bash
root@825b6abd8dbb:/usr/local/static/suckless/bin# ls
dmenu  dmenu_path  dmenu_run  dwm  st  stest
root@825b6abd8dbb:/usr/local/static/suckless/bin# ./st
^C
root@825b6abd8dbb:/usr/local/static/suckless/bin# ./dmenu
^C
root@825b6abd8dbb:/usr/local/static/suckless/bin# ./dwm
^C
```

- xrdp

```bash
root@825b6abd8dbb:/usr/local/static/xrdp/sbin# ./xrdp -n
xrdp[46]: [INFO ] starting xrdp with pid 46
xrdp[46]: [INFO ] address [0.0.0.0] port [3389] mode 1
xrdp[46]: [INFO ] listening to port 3389 on 0.0.0.0
xrdp[46]: [INFO ] xrdp_listen_pp done
```
