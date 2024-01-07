
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
