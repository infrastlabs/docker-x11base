
- http://ftp.debian.org/debian/ #v12.5
- https://mirrors.ustc.edu.cn/help/debian.html 中国科学技术大学
- https://mirrors4.tuna.tsinghua.edu.cn/help/debian/ #err /etc/apt/sources.list

## debian12

**try1**

```bash
# AI@baidu:  debian12 跳过GPG检查
debian12 跳过GPG检查
在Debian 12 (codenamed "Bookworm") 中，如果你想要临时跳过GPG签名检查，可以在APT命令中添加--allow-unauthenticated选项。这样做通常是不推荐的，因为它会跳过所有的包的GPG签名验证，可能会引入安全风险。

例如，当你尝试安装一个未被Debian官方GPG密钥认证的包时，可以这样做：
# sudo apt-get install --allow-unauthenticated package-name
# /etc/apt/apt.conf.d/

cat > /etc/apt/apt.conf.d/skip-gpg-check <<EOF
Acquire {
  Allow-Unauthenticated "true";
}
EOF


# AI@baidu: 02
1.打开终端。
使用你喜欢的文本编辑器编辑APT的配置文件。这里我们使用nano，你可以根据需要选择其他编辑器。
sudo nano /etc/apt/apt.conf.d/10unauthenticated

2.在打开的文件中，添加或修改以下行：
APT::Get::Allow-Unauthenticated "true";
保存并关闭文件。
3.更新APT的配置使改动生效：
sudo apt-get update
cat > /etc/apt/apt.conf.d/skip-gpg-check02 <<EOF
Acquire {
  APT::Get::Allow-Unauthenticated "true";
}
EOF


# AI 03:
# E: Syntax error /etc/apt/apt.conf.d/10unauthenticated:2: Extra junk after value
cat > /etc/apt/apt.conf.d/10unauthenticated <<EOF
Acquire {
  Unauthenticated = 1;
};
EOF
```

**try2**

```bash
# 04:
# https://blog.csdn.net/weixin_36297381/article/details/116962448
apt \
  -o Acquire::AllowInsecureRepositories=true \
  -o Acquire::AllowDowngradeToInsecureRepositories=true \
  update


# 05:
cat > /etc/apt/apt.conf.d/skip-gpg-check-ig <<EOF
Acquire {
  GPG::Ignore "true";
}
EOF


# ok;
root@757b916af624:/etc/apt/apt.conf.d# find
.
./skip-gpg-check-ig  #05
./skip-gpg-check02  #ref 02
# with apt05:
root@757b916af624:/etc/apt/apt.conf.d# apt \
>   -o Acquire::AllowInsecureRepositories=true \
>   -o Acquire::AllowDowngradeToInsecureRepositories=true \
>   update
Get:1 http://mirrors.ustc.edu.cn/debian bookworm InRelease [151 kB]
Ign:1 http://mirrors.ustc.edu.cn/debian bookworm InRelease
Get:2 http://mirrors.ustc.edu.cn/debian bookworm-updates InRelease [55.4 kB]
Ign:2 http://mirrors.ustc.edu.cn/debian bookworm-updates InRelease
Get:3 http://mirrors.ustc.edu.cn/debian-security bookworm-security InRelease [48.0 kB]
Get:4 http://mirrors.ustc.edu.cn/debian bookworm/main amd64 Packages [8786 kB]
Ign:3 http://mirrors.ustc.edu.cn/debian-security bookworm-security InRelease
Get:5 http://mirrors.ustc.edu.cn/debian bookworm/main Translation-en [6109 kB]
Get:6 http://mirrors.ustc.edu.cn/debian bookworm-updates/main amd64 Packages [12.7 kB]
Get:7 http://mirrors.ustc.edu.cn/debian bookworm-updates/main Translation-en [13.8 kB]
Get:8 http://mirrors.ustc.edu.cn/debian-security bookworm-security/main amd64 Packages [150 kB]
Get:9 http://mirrors.ustc.edu.cn/debian-security bookworm-security/main Translation-en [90.3 kB]
Fetched 15.4 MB in 4s (4267 kB/s)                                
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
37 packages can be upgraded. Run 'apt list --upgradable' to see them.
W: GPG error: http://mirrors.ustc.edu.cn/debian bookworm InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 0E98404D386FA1D9 NO_PUBKEY 6ED0E7B82643E131 NO_PUBKEY F8D2585B8783D481
W: The repository 'http://mirrors.ustc.edu.cn/debian bookworm InRelease' is not signed.
N: Data from such a repository can't be authenticated and is therefore potentially dangerous to use.
N: See apt-secure(8) manpage for repository creation and user configuration details.
W: GPG error: http://mirrors.ustc.edu.cn/debian bookworm-updates InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 0E98404D386FA1D9 NO_PUBKEY 6ED0E7B82643E131
W: The repository 'http://mirrors.ustc.edu.cn/debian bookworm-updates InRelease' is not signed.
N: Data from such a repository can't be authenticated and is therefore potentially dangerous to use.
N: See apt-secure(8) manpage for repository creation and user configuration details.
W: GPG error: http://mirrors.ustc.edu.cn/debian-security bookworm-security InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 54404762BBB6E853 NO_PUBKEY BDE6D2B9216EC7A8
W: The repository 'http://mirrors.ustc.edu.cn/debian-security bookworm-security InRelease' is not signed.
N: Data from such a repository can't be authenticated and is therefore potentially dangerous to use.
N: See apt-secure(8) manpage for repository creation and user configuration details.
root@757b916af624:/etc/apt/apt.conf.d# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install tree
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
tree is already the newest version (2.1.0-1).
0 upgraded, 0 newly installed, 0 to remove and 37 not upgraded.

# try ins:
# root@757b916af624:/etc/apt/apt.conf.d# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install arandr
# 
dpkg-deb (subprocess): decompressing archive '/var/cache/apt/archives/python3.11-minimal_3.11.2-6_amd64.deb' (size=2064032) member 'control.tar': lzma error: Cannot allocate memory
tar: This does not look like a tar archive
tar: Exiting with failure status due to previous errors
dpkg-deb: error: tar subprocess returned error exit status 2
dpkg: error processing archive /var/cache/apt/archives/python3.11-minimal_3.11.2-6_amd64.deb (--unpack):
 dpkg-deb --control subprocess returned error exit status 2
Errors were encountered while processing:
 /var/cache/apt/archives/libpython3.11-minimal_3.11.2-6_amd64.deb
 /var/cache/apt/archives/python3.11-minimal_3.11.2-6_amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)



# root@757b916af624:/etc/apt/apt.conf.d# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install plank
# 
dpkg-deb (subprocess): decompressing archive '/tmp/apt-dpkg-install-Qodb4n/11-plank_0.11.89-4+b1_amd64.deb' (size=148908) member 'control.tar': lzma error: Cannot allocate memory #需特权模式
tar: This does not look like a tar archive
tar: Exiting with failure status due to previous errors
dpkg-deb: error: tar subprocess returned error exit status 2
dpkg: error processing archive /tmp/apt-dpkg-install-Qodb4n/11-plank_0.11.89-4+b1_amd64.deb (--unpack):
 dpkg-deb --control subprocess returned error exit status 2
Errors were encountered while processing:
 /tmp/apt-dpkg-install-Qodb4n/00-libbamf3-2_0.5.6+repack-1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/01-libxres1_2%3a1.2.1-1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/02-libwnck-3-common_43.0-3_all.deb
 /tmp/apt-dpkg-install-Qodb4n/03-libwnck-3-0_43.0-3_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/04-bamfdaemon_0.5.6+repack-1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/05-libdbusmenu-glib4_18.10.20180917~bzr492+repack1-3_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/06-libdbusmenu-gtk3-4_18.10.20180917~bzr492+repack1-3_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/07-libgee-0.8-2_0.20.6-1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/08-libgnome-menu-3-0_3.36.0-1.1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/09-libplank-common_0.11.89-4_all.deb
 /tmp/apt-dpkg-install-Qodb4n/10-libplank1_0.11.89-4+b1_amd64.deb
 /tmp/apt-dpkg-install-Qodb4n/11-plank_0.11.89-4+b1_amd64.deb
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

**try3**

```bash
# --privileged 特权模式即OK
root @ deb1013 in ~ |01:52:56  
$ docker run -it --rm --privileged  debian:12

   cd /etc/apt/apt.conf.d/
   mkdir ../_01
   mv * ../_01/
   cat > /etc/apt/apt.conf.d/skip-gpg-check02 <<EOF
Acquire {
  APT::Get::Allow-Unauthenticated "true";
}
EOF

   cat > /etc/apt/apt.conf.d/skip-gpg-check-ig <<EOF
Acquire {
  GPG::Ignore "true";
}
EOF

# trans
sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources;
# sed -i 's/mirrors.ustc.edu.cn/deb.debian.org/g' /etc/apt/sources.list.d/debian.sources;

   apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   update
   apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install plank

# plank insOK;
```

## ubuntu2404

**ubt2404/2204**

```bash
# 2404
cd /etc/apt/apt.conf.d/
mkdir ../_01
mv * ../_01/
cat > /etc/apt/apt.conf.d/skip-gpg-check02 <<EOF
Acquire {
  APT::Get::Allow-Unauthenticated "true";
}
EOF

cat > /etc/apt/apt.conf.d/skip-gpg-check-ig <<EOF
Acquire {
  GPG::Ignore "true";
}
EOF

# root@a90d325350c9:/etc/apt/apt.conf.d# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install pulseaudio --no-install-recommends
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  adduser dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dbus-user-session dconf-gsettings-backend dconf-service
  fontconfig fontconfig-config fonts-dejavu-core fonts-dejavu-mono glib-networking glib-networking-common glib-networking-services
  gsettings-desktop-schemas iso-codes libaom3 libapparmor1 libargon2-1 libasound2-data libasound2-plugins libasound2t64 libasyncns0
  libavcodec60 libavutil58 libbrotli1 libbsd0 libcairo-gobject2 libcairo2 libcap2-bin libcodec2-1.2 libcryptsetup12 libcurl3t64-gnutls
  libdatrie1 libdav1d7 libdb5.3t64 libdbus-1-3 libdconf1 libdeflate0 libdevmapper1.02.1 libdrm-common libdrm-intel1 libdrm2 libduktape207
  libdw1t64 libelf1t64 libexpat1 libfdisk1 libfftw3-single3 libflac12t64 libfontconfig1 libfreetype6 libfribidi0 libgdk-pixbuf-2.0-0
  libgdk-pixbuf2.0-common libglib2.0-0t64 libgomp1 libgraphite2-3 libgsm1 libgssapi-krb5-2 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0
  libharfbuzz0b libhwy1t64 libice6 libicu74 libjack-jackd2-0 libjbig0 libjpeg-turbo8 libjpeg8 libjson-c5 libjson-glib-1.0-0
  libjson-glib-1.0-common libjxl0.7 libk5crypto3 libkeyutils1 libkmod2 libkrb5-3 libkrb5support0 liblcms2-2 libldap2 liblerc4 libltdl7
  libmp3lame0 libmpg123-0t64 libnghttp2-14 libnuma1 libogg0 libopenjp2-7 libopus0 liborc-0.4-0t64 libpam-systemd libpango-1.0-0
  libpangocairo-1.0-0 libpangoft2-1.0-0 libpciaccess0 libpixman-1-0 libpng16-16t64 libproxy1v5 libpsl5t64 libpulse0 librav1e0 librsvg2-2
  librtmp1 libsamplerate0 libsasl2-2 libsasl2-modules-db libsharpyuv0 libshine3 libsm6 libsnapd-glib-2-1 libsnappy1v5 libsndfile1
  libsoup-3.0-0 libsoup-3.0-common libsoxr0 libspeex1 libspeexdsp1 libsqlite3-0 libssh-4 libsvtav1enc1d1 libswresample4 libsystemd-shared
  libtdb1 libthai-data libthai0 libtheora0 libtiff6 libtwolame0 libunwind8 libva-drm2 libva-x11-2 libva2 libvdpau1 libvorbis0a libvorbisenc2
  libvpl2 libvpx9 libwayland-client0 libwebp7 libwebpmux3 libwebrtc-audio-processing1 libwrap0 libx11-6 libx11-data libx11-xcb1 libx264-164
  libx265-199 libxau6 libxcb-dri3-0 libxcb-render0 libxcb-shm0 libxcb1 libxdmcp6 libxext6 libxfixes3 libxml2 libxrender1 libxtst6
  libxvidcore4 libzvbi-common libzvbi0t64 ocl-icd-libopencl1 pulseaudio-utils session-migration shared-mime-info systemd systemd-dev
  systemd-sysv x11-common
Suggested packages:
  liblocale-gettext-perl perl cron quota ecryptfs-utils isoquery alsa-utils libcuda1 libnvcuvid1 libnvidia-encode1 libfftw3-bin libfftw3-dev
  low-memory-monitor krb5-doc krb5-user libvisual-0.4-plugins gstreamer1.0-tools jackd2 liblcms2-utils opus-tools pciutils librsvg2-bin snapd
  speex opencl-icd udev pavumeter pavucontrol paprefs avahi-daemon systemd-container systemd-homed systemd-userdbd systemd-boot libfido2-1
  libip4tc2 libqrencode4 libtss2-esys-3.0.2-0 libtss2-mu-4.0.1-0 libtss2-rc0 libtss2-tcti-device0 polkitd
Recommended packages:
  alsa-ucm-conf alsa-topology-conf libpam-cap ca-certificates dmsetup libgdk-pixbuf2.0-bin libglib2.0-data xdg-user-dirs
  gstreamer1.0-plugins-base krb5-locales libldap-common publicsuffix librsvg2-common libsasl2-modules va-driver-all | va-driver
  vdpau-driver-all | vdpau-driver rtkit networkd-dispatcher systemd-timesyncd | time-daemon systemd-resolved libnss-systemd
The following NEW packages will be installed:
  adduser dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dbus-user-session dconf-gsettings-backend dconf-service
  fontconfig fontconfig-config fonts-dejavu-core fonts-dejavu-mono glib-networking glib-networking-common glib-networking-services
  gsettings-desktop-schemas iso-codes libaom3 libapparmor1 libargon2-1 libasound2-data libasound2-plugins libasound2t64 libasyncns0
  libavcodec60 libavutil58 libbrotli1 libbsd0 libcairo-gobject2 libcairo2 libcap2-bin libcodec2-1.2 libcryptsetup12 libcurl3t64-gnutls
  libdatrie1 libdav1d7 libdb5.3t64 libdbus-1-3 libdconf1 libdeflate0 libdevmapper1.02.1 libdrm-common libdrm-intel1 libdrm2 libduktape207
  libdw1t64 libelf1t64 libexpat1 libfdisk1 libfftw3-single3 libflac12t64 libfontconfig1 libfreetype6 libfribidi0 libgdk-pixbuf-2.0-0
  libgdk-pixbuf2.0-common libglib2.0-0t64 libgomp1 libgraphite2-3 libgsm1 libgssapi-krb5-2 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0
  libharfbuzz0b libhwy1t64 libice6 libicu74 libjack-jackd2-0 libjbig0 libjpeg-turbo8 libjpeg8 libjson-c5 libjson-glib-1.0-0
  libjson-glib-1.0-common libjxl0.7 libk5crypto3 libkeyutils1 libkmod2 libkrb5-3 libkrb5support0 liblcms2-2 libldap2 liblerc4 libltdl7
  libmp3lame0 libmpg123-0t64 libnghttp2-14 libnuma1 libogg0 libopenjp2-7 libopus0 liborc-0.4-0t64 libpam-systemd libpango-1.0-0
  libpangocairo-1.0-0 libpangoft2-1.0-0 libpciaccess0 libpixman-1-0 libpng16-16t64 libproxy1v5 libpsl5t64 libpulse0 librav1e0 librsvg2-2
  librtmp1 libsamplerate0 libsasl2-2 libsasl2-modules-db libsharpyuv0 libshine3 libsm6 libsnapd-glib-2-1 libsnappy1v5 libsndfile1
  libsoup-3.0-0 libsoup-3.0-common libsoxr0 libspeex1 libspeexdsp1 libsqlite3-0 libssh-4 libsvtav1enc1d1 libswresample4 libsystemd-shared
  libtdb1 libthai-data libthai0 libtheora0 libtiff6 libtwolame0 libunwind8 libva-drm2 libva-x11-2 libva2 libvdpau1 libvorbis0a libvorbisenc2
  libvpl2 libvpx9 libwayland-client0 libwebp7 libwebpmux3 libwebrtc-audio-processing1 libwrap0 libx11-6 libx11-data libx11-xcb1 libx264-164
  libx265-199 libxau6 libxcb-dri3-0 libxcb-render0 libxcb-shm0 libxcb1 libxdmcp6 libxext6 libxfixes3 libxml2 libxrender1 libxtst6
  libxvidcore4 libzvbi-common libzvbi0t64 ocl-icd-libopencl1 pulseaudio pulseaudio-utils session-migration shared-mime-info systemd
  systemd-dev systemd-sysv x11-common
0 upgraded, 173 newly installed, 0 to remove and 0 not upgraded.
Need to get 73.3 MB of archives.
After this operation, 241 MB of additional disk space will be used.
Do you want to continue? [Y/n] ^C


# 2204
# 2204
export DOMAIN="mirrors.ustc.edu.cn"; \
  test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
  echo "deb http://${DOMAIN}/$target jammy main restricted universe multiverse" > /etc/apt/sources.list \
  && echo "deb http://${DOMAIN}/$target jammy-updates main restricted universe multiverse">> /etc/apt/sources.list; 
# (还未单用sources.list.d); gpg-check同2404:
cd /etc/apt/apt.conf.d/
mkdir ../_01; mv * ../_01/
# cat > /etc/apt/apt.conf.d/skip-gpg-check02 <<EOF
# Acquire {
#   APT::Get::Allow-Unauthenticated "true";
# }
# EOF
# cat > /etc/apt/apt.conf.d/skip-gpg-check-ig <<EOF
# Acquire {
#   GPG::Ignore "true";
# }
# EOF
# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true update


cat > /etc/apt/apt.conf.d/skip-gpg-check-ig <<EOF
Acquire {
  APT::Get::Allow-Unauthenticated "true";
  GPG::Ignore "true";
  AllowInsecureRepositories "true";
  AllowDowngradeToInsecureRepositories "true";
}
EOF
apt update

root@bf8a8d987d20:/etc/apt/apt.conf.d# apt   -o Acquire::AllowInsecureRepositories=true   -o Acquire::AllowDowngradeToInsecureRepositories=true   install pulseaudio --no-install-recommends
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  dbus dbus-user-session dconf-gsettings-backend dconf-service glib-networking glib-networking-common glib-networking-services
  gsettings-desktop-schemas iso-codes libapparmor1 libargon2-1 libasound2 libasound2-data libasound2-plugins libasyncns0 libbrotli1 libbsd0
  libcap2-bin libcryptsetup12 libdbus-1-3 libdconf1 libdevmapper1.02.1 libdw1 libelf1 libexpat1 libfftw3-single3 libflac8 libglib2.0-0
  libgomp1 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libice6 libicu70 libip4tc2 libjack-jackd2-0 libjson-c5 libjson-glib-1.0-0
  libjson-glib-1.0-common libkmod2 libltdl7 libmd0 libogg0 libopus0 liborc-0.4-0 libpam-systemd libproxy1v5 libpsl5 libpulse0 libpulsedsp
  libsamplerate0 libsm6 libsnapd-glib1 libsndfile1 libsoup2.4-1 libsoup2.4-common libsoxr0 libspeexdsp1 libsqlite3-0 libtdb1 libunwind8
  libvorbis0a libvorbisenc2 libwebrtc-audio-processing1 libwrap0 libx11-6 libx11-data libx11-xcb1 libxau6 libxcb1 libxdmcp6 libxext6 libxml2
  libxtst6 pulseaudio-utils session-migration systemd systemd-sysv x11-common
Suggested packages:
  isoquery alsa-utils libfftw3-bin libfftw3-dev libvisual-0.4-plugins gstreamer1.0-tools jackd2 opus-tools snapd udev pavumeter pavucontrol
  paprefs ubuntu-sounds avahi-daemon systemd-container libfido2-1 libtss2-esys-3.0.2-0 libtss2-mu0 libtss2-rc0 policykit-1
Recommended packages:
  alsa-ucm-conf alsa-topology-conf libpam-cap dmsetup libglib2.0-data shared-mime-info xdg-user-dirs gstreamer1.0-plugins-base publicsuffix
  rtkit networkd-dispatcher systemd-timesyncd | time-daemon libnss-systemd
The following NEW packages will be installed:
  dbus dbus-user-session dconf-gsettings-backend dconf-service glib-networking glib-networking-common glib-networking-services
  gsettings-desktop-schemas iso-codes libapparmor1 libargon2-1 libasound2 libasound2-data libasound2-plugins libasyncns0 libbrotli1 libbsd0
  libcap2-bin libcryptsetup12 libdbus-1-3 libdconf1 libdevmapper1.02.1 libdw1 libelf1 libexpat1 libfftw3-single3 libflac8 libglib2.0-0
  libgomp1 libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libice6 libicu70 libip4tc2 libjack-jackd2-0 libjson-c5 libjson-glib-1.0-0
  libjson-glib-1.0-common libkmod2 libltdl7 libmd0 libogg0 libopus0 liborc-0.4-0 libpam-systemd libproxy1v5 libpsl5 libpulse0 libpulsedsp
  libsamplerate0 libsm6 libsnapd-glib1 libsndfile1 libsoup2.4-1 libsoup2.4-common libsoxr0 libspeexdsp1 libsqlite3-0 libtdb1 libunwind8
  libvorbis0a libvorbisenc2 libwebrtc-audio-processing1 libwrap0 libx11-6 libx11-data libx11-xcb1 libxau6 libxcb1 libxdmcp6 libxext6 libxml2
  libxtst6 pulseaudio pulseaudio-utils session-migration systemd systemd-sysv x11-common
0 upgraded, 79 newly installed, 0 to remove and 0 not upgraded.
Need to get 32.9 MB of archives.
After this operation, 118 MB of additional disk space will be used.
Do you want to continue? [Y/n] ^C
```