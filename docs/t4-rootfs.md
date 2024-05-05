
**barge-os**

```bash
[root@barge /]# ls -lh /
total 8
drwxr-xr-x    3 root     root          60 Jun 11 03:53 _ext/
drwxr-xr-x    2 root     root        1.4K Jun 11 03:53 bin/
drwxr-xr-x    7 root     root        2.4K Jun 11 03:53 dev/
drwxr-xr-x    1 root     root        4.0K Jun 17 08:01 etc/
lrwxrwxrwx    1 root     root          14 Jun 11 03:53 home -> /mnt/data/home/
-rwxr-xr-x    1 root     root        3.7K Oct  3  2018 init*
drwxr-xr-x    4 root     root         780 Jun 11 03:53 lib/
lrwxrwxrwx    1 root     root           3 Jun 11 03:53 lib64 -> lib/
drwxr-xr-x    2 root     root          40 Mar  5  2019 media/
drwxr-xr-x    4 root     root          80 Jun 11 03:53 mnt/
lrwxrwxrwx    1 root     root          13 Jun 11 03:53 opt -> /mnt/data/opt/
dr-xr-xr-x  217 root     root           0 Jun 11 03:53 proc/
drwx------    2 root     root          80 Jun 11 03:53 root/
drwxrwxrwt    4 root     root         100 Jun 11 03:53 run/
drwxr-xr-x    2 root     root        1.2K Jun 11 03:53 sbin/
dr-xr-xr-x   13 root     root           0 Jun 11 03:53 sys/
drwxrwxrwt    2 root     root          60 Jun 11 03:53 tmp/
drwxr-xr-x    7 root     root         160 Jun 11 03:53 usr/
drwxr-xr-x   11 root     root         240 Jun 11 03:53 var/

[root@barge /]# ls |egrep -v "_ext|mnt|media|sys|proc|dev|run|var|home|lib64|opt" |while read one; do du -sh $one; done
1.2M	bin/
1.1M	etc/
4.0K	init
8.0M	lib/
8.0K	root/
640.0K	sbin/
4.0K	tmp/
168.9M	usr/
[root@barge /]# ls /bin
base64@        chmod@         dd@            echo@          fgrep@         hostname@      login@         more@          netstat@       pipe_progress@ rmdir@         sh@            sync@          uname@
bash*          chown@         df@            egrep@         getopt@        kill@          ls@            mount@         nice@          printenv@      run-parts@     sleep@         tar@           usleep@
busybox*       cp@            dmesg@         false@         grep@          linux32@       mkdir@         mountpoint@    pidof@         ps@            sed@           stat@          touch@         vi@
cat@           cpio@          dnsdomainname@ fatattr@       gunzip@        linux64@       mknod@         mt@            ping@          pwd@           setarch@       stty@          true@          watch@
chgrp@         date@          dumpkmap@      fdflush@       gzip@          ln@            mktemp@        mv@            ping6@         rm@            setserial@     su@            umount@        zcat@
[root@barge /]# ls sbin/
blkid@             fsck.ext2@         hdparm@            ip@                iptunnel@          mke2fs*            nameif@            rmmod@             sulogin@           uevent@
devmem@            fsck.ext3@         hwclock@           ipaddr@            klogd@             mkfs.ext2@         pivot_root@        route@             swapoff@           vconfig@
dhcpcd*            fsck.ext4@         ifconfig@          iplink@            loadkmap@          mkfs.ext3@         poweroff@          runlevel@          swapon@            watchdog@
e2fsck*            fstrim@            ifdown@            ipneigh@           losetup@           mkfs.ext4@         reboot@            setconsole@        switch_root@
fdisk@             getty@             ifup@              iproute@           lsmod@             mkswap@            resize2fs*         shutdown*          sysctl@
freeramdisk@       halt@              insmod@            iprule@            makedevs@          modprobe@          respawn*           start-stop-daemon@ syslogd@


[root@barge /]# ls etc/
acpi/              docker/            init.d/            logrotate.conf     mtab@              passwd             random-seed        shadow-            sudoers
bash_completion.d/ fstab              inputrc            logrotate.d/       network/           passwd-            resolv.conf@       shells             sudoers.d/
bashrc             group              issue              logrotate.status   nsswitch.conf      profile            resolv.conf.tail   skel/              sysctl.conf
cron/              hostname           locale.conf        mke2fs.conf        ntp.conf           profile.d/         services           ssh/               timezone
dhcpcd.conf        hosts              localtime@         motd               os-release         protocols          shadow             ssl/               wgetrc

[root@barge /]# find root/
root/
root/.bash_profile
root/.bashrc
[root@barge /]# find tmp/
tmp/
tmp/resolv.conf

[root@barge /]# find lib |wc
      438       438     24661
[root@barge /]# ls lib
dhcpcd/               libanl.so.1@          libblkid.so.1@        libcrypt-2.25.so*     libgcc_s.so           libmvec-2.25.so*      libnss_files-2.25.so* libresolv-2.25.so*    libutil-2.25.so*      modules/
ld-2.25.so*           libatomic.so@         libblkid.so.1.1.0*    libcrypt.so.1@        libgcc_s.so.1         libmvec.so.1@         libnss_files.so.2@    libresolv.so.2@       libutil.so.1@
ld-linux-x86-64.so.2@ libatomic.so.1@       libc-2.25.so*         libdl-2.25.so*        libm-2.25.so*         libnss_dns-2.25.so*   libpthread-2.25.so*   librt-2.25.so*        libuuid.so.1@
libanl-2.25.so*       libatomic.so.1.2.0*   libc.so.6@            libdl.so.2@           libm.so.6@            libnss_dns.so.2@      libpthread.so.0@      librt.so.1@           libuuid.so.1.3.0*

# usr
[root@barge /]# du -sh usr/*
160.8M	usr/bin
5.6M	usr/lib
0	usr/lib64
1.1M	usr/libexec
1012.0K	usr/sbin
548.0K	usr/share

[root@barge usr]# ls bin/
[@                 containerd-shim*   du@                ipcrm@             lzdiff@            nohup@             reset@             sha512sum@         tail@              unlzma@            xz*
[[@                crontab@           dumb-init*         ipcs@              lzegrep@           nsenter@           resize@            shuf@              tee@               unshare@           xzcat@
acpi_listen*       ctr*               eject@             iptables-xml@      lzfgrep@           nslookup@          rsync*             sntp*              telnet@            unxz@              xzcmp@
ar@                cut@               env@               killall@           lzgrep@            od@                runc*              sort@              test@              unzip@             xzdec*
awk@               cvtsudoers*        expr@              last@              lzless@            openvt@            scmp_sys_resolver* ssh*               tftp@              uptime@            xzdiff*
basename@          dc@                find@              less@              lzma@              passwd@            scp*               ssh-add*           time@              uudecode@          xzegrep@
bunzip2@           deallocvt@         fold@              locale*            lzmadec*           patch@             seq@               ssh-agent*         top@               uuencode@          xzfgrep@
bzcat@             diff@              free@              logger@            lzmainfo*          pgrep@             setfattr@          ssh-copy-id*       tr@                vlock@             xzgrep*
chrt@              dirname@           fuser@             logname@           lzmore@            pkg*               setkeycodes@       ssh-keygen*        traceroute@        wc@                xzless*
chvt@              docker*            head@              lsof@              md5sum@            pkill@             setsid@            ssh-keyscan*       truncate@          wget*              xzmore*
cksum@             docker-init*       hexdump@           lspci@             microcom@          printf@            sftp*              strings@           tty@               which@             yes@
clear@             docker-proxy*      hostid@            lsusb@             mkfifo@            readlink@          sha1sum@           sudo*              uniq@              who@
cmp@               dockerd*           id@                lzcat@             mkpasswd@          realpath@          sha256sum@         sudoedit@          unix2dos@          whoami@
containerd*        dos2unix@          install@           lzcmp@             nc@                renice@            sha3sum@           sudoreplay*        unlink@            xargs@
[root@barge usr]# ls sbin/
acpid*                    chroot@                   ether-wake@               ip6tables@                ip6tables-save@           iptables-restore@         logrotate*                visudo*
addgroup@                 crond@                    fbset@                    ip6tables-legacy@         iptables@                 iptables-save@            rdate@                    xtables-legacy-multi*
adduser@                  delgroup@                 fdformat@                 ip6tables-legacy-restore@ iptables-legacy@          kacpimon*                 readprofile@
arping@                   deluser@                  haveged*                  ip6tables-legacy-save@    iptables-legacy-restore@  killall5@                 setlogcons@
chpasswd@                 dnsd@                     inetd@                    ip6tables-restore@        iptables-legacy-save@     loadfont@                 sshd*
# [root@barge usr/bin]# ls -lSh |grep M 
-rwxr-xr-x    1 bargee   bargees    51.8M Feb 28  2019 dockerd*
-rwxr-xr-x    1 bargee   bargees    48.3M Feb 28  2019 docker*
-rwxr-xr-x    1 bargee   bargees    26.7M Feb 28  2019 containerd*
-rwxr-xr-x    1 bargee   bargees    15.0M Feb 28  2019 ctr*
-rwxr-xr-x    1 bargee   bargees     7.2M Feb 28  2019 runc*
-rwxr-xr-x    1 bargee   bargees     4.7M Feb 28  2019 containerd-shim*
-rwxr-xr-x    1 bargee   bargees     2.7M Feb 28  2019 docker-proxy*
-rwxr-xr-x    1 root     root      606.6K Mar  5  2019 ssh*
-rwxr-xr-x    1 root     root      402.5K Mar  5  2019 wget*
-rwxr-xr-x    1 root     root      362.2K Mar  5  2019 ssh-keyscan*
-rwxr-xr-x    1 root     root      358.1K Mar  5  2019 ssh-keygen*
-rwxr-xr-x    1 root     root      317.7K Mar  5  2019 rsync*
-rwxr-xr-x    1 root     root      294.0K Mar  5  2019 ssh-add*
-rwxr-xr-x    1 root     root      278.0K Mar  5  2019 ssh-agent*
-rwxr-xr-x    1 root     root      227.5K Mar  5  2019 sntp*

[root@barge usr]# ls lib
libblkid.so@                    libe2p.so.2.3*                  libext2fs.so.2.4*               libip4tc.so.0.1.0*              liblzma.so.5.2.3*               libreadline.so.8.0*             libxtables.so.12.2.0*
libcom_err.so@                  libevent_core-2.1.so.6@         libhavege.so@                   libip6tc.so@                    libncurses.so@                  libseccomp.so@                  libz.so@
libcom_err.so.2@                libevent_core-2.1.so.6.0.2*     libhavege.so.1@                 libip6tc.so.0@                  libncurses.so.5@                libseccomp.so.2@                libz.so.1@
libcom_err.so.2.1*              libevent_core.so@               libhavege.so.1.1.0*             libip6tc.so.0.1.0*              libncurses.so.5.9*              libseccomp.so.2.3.3*            libz.so.1.2.11*
libcrypto.so@                   libevent_pthreads-2.1.so.6@     libhistory.so@                  libiptc.so@                     libpopt.so@                     libssl.so@                      locale/
libcrypto.so.1.1*               libevent_pthreads-2.1.so.6.0.2* libhistory.so.8@                libiptc.so.0@                   libpopt.so.0@                   libssl.so.1.1*                  os-release
libcurses.so@                   libevent_pthreads.so@           libhistory.so.8.0*              libiptc.so.0.0.0*               libpopt.so.0.0.0*               libuuid.so@                     terminfo@
libe2p.so@                      libext2fs.so@                   libip4tc.so@                    liblzma.so@                     libreadline.so@                 libxtables.so@                  xtables/
libe2p.so.2@                    libext2fs.so.2@                 libip4tc.so.0@                  liblzma.so.5@                   libreadline.so.8@               libxtables.so.12@
[root@barge usr]# ls libexec/
sftp-server*       ssh-keysign*       ssh-pkcs11-helper* sudo/
[root@barge usr]# find libexec/
libexec/
libexec/sudo
libexec/sudo/libsudo_util.so
libexec/sudo/libsudo_util.so.0
libexec/sudo/system_group.so
libexec/sudo/group_file.so
libexec/sudo/sudo_noexec.so
libexec/sudo/sudoers.so
libexec/sudo/libsudo_util.so.0.0.0
libexec/ssh-keysign
libexec/sftp-server
libexec/ssh-pkcs11-helper
[root@barge usr]# find share/ |wc
      119       119      3392
```