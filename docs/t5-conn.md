

```bash
# 
frp: frpc-> frps; index页,取frps上记录信息
# 长连接，端口类别/列表，端口流量
# 不可主动增/删映射

# index@yq
curl -fsSL -u headless:headless http://127.0.0.1:10079/api/proxy/tcp |yq ".proxies[].name"
```

## UDS

- ssh 10022 `xinetd> dropbear -i`
- noVnc 10081 `webhookd:cur none uds-mode`
- xrdp 10089 ``

```bash
root@20cd9a831df8:/# netstat -ntlp |sort
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
# Xvnc
tcp        0      0 0.0.0.0:5921            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:6021            0.0.0.0:*               LISTEN      -                   
tcp6       0      0 :::5921                 :::*                    LISTEN      -                   
tcp6       0      0 :::6021                 :::*                    LISTEN      -                   
# xrdp,webhookd,ssh
tcp        0      0 0.0.0.0:9989            0.0.0.0:*               LISTEN      490/xrdp            
tcp6       0      0 :::9981                 :::*                    LISTEN      485/./webhookd 
tcp        0      0 0.0.0.0:9922            0.0.0.0:*               LISTEN      489/dropbear        
tcp6       0      0 :::9922                 :::*                    LISTEN      489/dropbear        
# 
tcp        0      0 127.0.0.1:7400          0.0.0.0:*               LISTEN      558/frpc            
tcp6       0      0 :::10022                :::*                    LISTEN      494/frps            
tcp6       0      0 :::10079                :::*                    LISTEN      494/frps            
tcp6       0      0 :::10080                :::*                    LISTEN      494/frps            
tcp6       0      0 :::10081                :::*                    LISTEN      494/frps            
tcp6       0      0 :::10089                :::*                    LISTEN      494/frps            
tcp6       0      0 :::7521                 :::*                    LISTEN      494/frps            
```


**xrdp**

```bash
# root@tenvm2:/usr/local/webhookd# xrdp -h
xrdp 0.9.16
  A Remote Desktop Protocol Server.
  Copyright (C) 2004-2020 Jay Sorg, Neutrino Labs, and all contributors.
  See https://github.com/neutrinolabs/xrdp for more information.

  Configure options:
      --prefix=/usr/local/static/xrdp
      --enable-vsock
      --enable-fdkaac
      --enable-opus
      --enable-fuse
      --enable-mp3lame
      --enable-pixman
      --disable-pam
      --enable-static
      --enable-shared
      --enable-devel-all
      CC=xx-clang
      CFLAGS=-Os -fomit-frame-pointer
      LDFLAGS=-Wl,--as-needed --static -static -Wl,--strip-all
      CPPFLAGS=-Os -fomit-frame-pointer
  Compiled with OpenSSL 1.1.1w  11 Sep 2023
Usage: xrdp [options]
   -k, --kill        shut down xrdp
   -h, --help        show help
   -v, --version     show version
   -n, --nodaemon    don\'t fork into background
   -p, --port        tcp listen port
   -f, --fork        fork on new connection
   -c, --config      specify new path to xrdp.ini
       --dump-config display config on stdout on startup
# chansrv
root@tenvm2:/usr/local/webhookd# find /tmp/ |grep xrd
/tmp/.xrdp
/tmp/.xrdp/xrdpapi_21
/tmp/.xrdp/xrdp_chansrv_socket_21
```

**Xvnc**

```bash
# ss
Xvnc -ac :21 -listen tcp -rfbauth=/etc/xrdp/vnc_pass -depth 16 -BlacklistThreshold=3 -BlacklistTimeout=1
root@tenvm2:/# Xvnc -ac :31  -rfbauth=/etc/xrdp/vnc_pass -depth 16

# 5900/6000
root@tenvm2:/# netstat -ntlp |grep Xvnc
tcp   0 0 0.0.0.0:5921  0.0.0.0:*     LISTEN 459/Xvnc  
tcp   0 0 0.0.0.0:6021  0.0.0.0:*     LISTEN 459/Xvnc
tcp   0 0 0.0.0.0:5931  0.0.0.0:*     LISTEN 2234/Xvnc    #5900RFB; X11.TCP不开(drop: -listen tcp)
root@tenvm2:/# find /tmp/|sort
/tmp/
/tmp/.X11-unix
/tmp/.X11-unix/X21
/tmp/.X11-unix/X31
/tmp/.X21-lock
/tmp/.X31-lock

# https://www.codenong.com/cs106457509/
# 默认的, vnc 服务监听3个TCP端口
HTTP协议默认端口 : 5800+显示器号
RFB(Remote FrameBuffer)协议 默认端口 : 5900+显示器号
X协议 默认端口 : 6000+显示器号 #+ /tmp/.X11-unix/X31
vncserver使用的显示器编号默认从1开始, 依次使用, 也可以参数指定端口号
root@tenvm2:/# Xvnc -h 2>&1 |grep rfb
  rfbunixmode    - Unix socket access mode (default=384)
  rfbunixpath    - Unix socket to listen for RFB protocol (default=)
  rfbport        - TCP port to listen for RFB protocol (default=0)
  rfbauth        - Alias for PasswordFile


# -rfbport=-1; 则不监听RFBPORT;
root@tenvm2:/# Xvnc -ac :31  -rfbauth=/etc/xrdp/vnc_pass -rfbunixpath=/tmp/.X11-unix/RFB31 -rfbport=0 -depth 16
Xvnc TigerVNC 1.13.1 - built Nov  4 2023 04:51:22
Copyright (C) 1999-2022 TigerVNC Team and many others (see README.rst)
See https://www.tigervnc.org for information on TigerVNC.
Underlying X server release 12014000
Thu Dec  7 10:43:41 2023
 vncext:      VNC extension running!
 vncext:      Listening for VNC connections on /tmp/.X11-unix/RFB31 (mode 0600)
 vncext:      Listening for VNC connections on all interface(s), port 5931 ###
 vncext:      created VNC server for screen 0
^C
Thu Dec  7 10:44:19 2023
 ComparingUpdateTracker: 0 pixels in / 0 pixels out
 ComparingUpdateTracker: (1:-nan ratio)
root@tenvm2:/# Xvnc -ac :31  -rfbauth=/etc/xrdp/vnc_pass -rfbunixpath=/tmp/.X11-unix/RFB31 -rfbport=-1 -depth 16
Xvnc TigerVNC 1.13.1 - built Nov  4 2023 04:51:22
Copyright (C) 1999-2022 TigerVNC Team and many others (see README.rst)
See https://www.tigervnc.org for information on TigerVNC.
Underlying X server release 12014000
Thu Dec  7 10:44:23 2023
 vncext:      VNC extension running!
 vncext:      Listening for VNC connections on /tmp/.X11-unix/RFB31 (mode 0600)
 vncext:      created VNC server for screen 0
```
