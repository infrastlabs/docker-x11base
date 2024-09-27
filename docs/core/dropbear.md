
- **dropbear**

```bash
./configure
make
make install
# build ok;
/mnt2/dropbear # ls -lh dropbear
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:26 dropbear


# static-build
./configure  --enable-static --prefix=/usr/local/static/dropbear
make

/mnt2/dropbear # echo $?
0
/mnt2/dropbear # ls -lh dropbear
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:27 dropbear


# /mnt2/dropbear # make install
# validate01
/mnt2/dropbear # xx-verify --static /usr/local/static/dropbear/sbin/dropbear 
/mnt2/dropbear # echo $?
0
/mnt2/dropbear # ls -lh /usr/local/static/dropbear/sbin/dropbear 
-rwxr-xr-x    1 root     root      367.0K Oct 31 12:28 /usr/local/static/dropbear/sbin/dropbear


# validate02
root@VM-12-9-ubuntu:~# cd /mnt/xrdp-static-alpine/
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ls
bin  dropbear  etc  include  lib  sbin  share  xrdp-chansrv
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./dropbear -h
Dropbear server v2022.83 https://matt.ucc.asn.au/dropbear/dropbear.html
Usage: ./dropbear [options]
```

- **dist-vers**
  - core-alpine-3.19: ok
  - core-ubuntu-18.04/20.04 ok; 2204/2404: authFail!
  - core-opensuse-15.6 ok;
  - core-debian12,fedora39,busybox-1.36.1: authFail!; openwrt_dropbear_runErr;

```bash
  # https://github.com/mkj/dropbear
  #  master 2037
  #  DROPBEAR_2024.86 2031
  #  DROPBEAR_2022.83 1863

headless@2746902c89a4:~$ sudo su 
root@2746902c89a4:/home/headless# dropbear -V   
Dropbear v2022.83

# buildDate: Dec  2  2023 ##clone github's master
root@2746902c89a4:/usr/local/static/dropbear/sbin# ls -lh
total 184K
-rwxr-xr-x 1 root root 184K Dec  2  2023 dropbear

# deb1013
root @ deb1013 in ~ |11:21:47  
$ dropbear -V
Dropbear v2018.76
$ which dropbear
/usr/sbin/dropbear
```

- try 250213
  - https://github.com/danielkza/docker-dropbear-static/blob/master/Dockerfile `make -j4 PROGRAMS="$PROGRAMS" MULTI=1; ln -s dropbearmulti $program`
  - https://ask.csdn.net/questions/7654638 `getpwnam 函数静态编译会有问题=busybox 配置 dropbear 的问题`
  - https://www.cnblogs.com/bwangel23/p/4415739.html `getpwnam_r; @2015-04-11=关于getpw系列函数返回的静态区域 `

```bash
###try-dropbearmulti#######################
# ubt24也不行;
# root @ deb1013 in ~ |11:19:10  
# $ docker run -it --rm --net=host -v  /_ext/:/_ext -e START_SESSION2=openbox-session ${REPO}infrastlabs/x11-base:core-ubuntu-22.04 bash
root@deb1013:/# which dropbear; which dropbearkey 
root@deb1013:/# mv /usr/sbin/dropbear /usr/sbin/dropbear00; mv /usr/bin/dropbearkey /usr/bin/dropbearkey00
root@deb1013:/# cd /_ext/_dropbear_multi/
root@deb1013:/_ext/_dropbear_multi# ./dropbear -EFRp 10022


# 换ubt20则可
# root @ deb1013 in ~ |11:23:18  
# $ docker run -it --rm --net=host -v  /_ext/:/_ext -e START_SESSION2=openbox-session ${REPO}infrastlabs/x11-base:core-ubuntu-20.04 bash
root@deb1013:/# mv /usr/sbin/dropbear /usr/sbin/dropbear00; mv /usr/bin/dropbearkey /usr/bin/dropbearkey00
root@deb1013:/# cd /_ext/_dropbear_multi/
root@deb1013:/_ext/_dropbear_multi# ./dropbear -EFRp 10022
# root @ deb1013 in ~ |11:25:52  
$ ssh-keygen -f "/root/.ssh/known_hosts" -R "[127.0.0.1]:10022";  ssh headless@127.0.0.1 -p 10022

###tag_vs_pkg########################
# core-ubuntu-xx.04 容器内还是上一版的;
root@deb1013:/home/headless# dropbear00 -V
Dropbear v2022.83

# pkg版的:已是新版dropbear了; >>但:在ubt24/22下也不行;
root@deb1013:/_ext/_dropbear_multi/_pkg# ./usr/local/static/dropbear/sbin/dropbear -V
Dropbear v2024.86


###core-ubuntu-22.04###########################
# $ docker run -it --rm --net=host -v  /_ext/:/_ext -e START_SESSION2=openbox-session ${REPO}infrastlabs/x11-base:core-ubuntu-22.04 bash
root@deb1013:/# mv /usr/sbin/dropbear /usr/sbin/dropbear00; mv /usr/bin/dropbearkey /usr/bin/dropbearkey00
root@deb1013:/# cd /_ext/_dropbear_multi/_pkg/
root@deb1013:/_ext/_dropbear_multi/_pkg# ./usr/local/static/dropbear/sbin/dropbear -EFRp 10022


# try-dynDropbear
  # root@deb1013:/_ext/_dropbear_multi/_pkg# apt install dropbear --no-install-recommends
  Reading package lists... Done
  Building dependency tree... Done
  Reading state information... Done
  The following additional packages will be installed:
    dropbear-bin libtomcrypt1 libtommath1
  Suggested packages:
    dropbear-initramfs runit
  The following NEW packages will be installed:
    dropbear dropbear-bin libtomcrypt1 libtommath1
  0 upgraded, 4 newly installed, 0 to remove and 17 not upgraded.
  Need to get 559 kB of archives.
  After this operation, 1581 kB of additional disk space will be used.
  Do you want to continue? [Y/n] ^C
  # root@deb1013:/_ext/_dropbear_multi/_pkg# apt install  libtomcrypt1 libtommath1
  Reading package lists... Done
  Building dependency tree... Done
  Reading state information... Done
  The following NEW packages will be installed:
    libtomcrypt1 libtommath1
  0 upgraded, 2 newly installed, 0 to remove and 17 not upgraded.
  Need to get 411 kB of archives.
  After this operation, 1090 kB of additional disk space will be used.
  Get:1 http://mirrors.ustc.edu.cn/ubuntu jammy-updates/main amd64 libtommath1 amd64 1.2.0-6ubuntu0.22.04.1 [56.5 kB]
  Get:2 http://mirrors.ustc.edu.cn/ubuntu jammy/universe amd64 libtomcrypt1 amd64 1.18.2-5 [354 kB]
  Fetched 411 kB in 0s (1248 kB/s)
  # root@deb1013:/_ext/_dropbear_multi/_pkg# apt install dropbear-bin --no-install-recommends
  root@deb1013:/_ext/_dropbear_multi/_pkg# dropbear -V
  Dropbear v2020.81 #dyn版: 可ssh成功;


```



