
## Core

- perp
  - ~~busybox,openwrt~~ (`chmod o+t> chmod 1755`)
- debian
  - ~~font-ttf~~ (`fonts-dejavu-core`)
- font-st
  - except alpine


**busybox**

```bash
# bash-5.2# chmod o+t xrdp/
bash-5.2# echo $?
0
# bash-5.2# sv start xrdp
error: xrdp: service directory not activated

```


## Apps

- firefox https://www.firefox.com.cn/download/#product-desktop-esr ##esr/115.1
- 163music https://music.163.com/#/download #v1.2.1; org-none-link
- vscode https://code.visualstudio.com/ #1.88.1
- wps https://linux.wps.cn/ #WPS2019 11.1.0.11719
- fcitx sogoupinyin_4.0.1.2800.deb

**alpine**

```bash
# alpine
firefox
input, tz, locale

```

**ubuntu**

```bash
# lite
browser, vscode, 
input, tz, locale

# ubuntu
firefox, vscode, wps
netease-cloud-music


# 163music
apt install libharfbuzz0b libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libasound2

# wps 
apt install --no-install-recommends \
  libfreetype6 libcups2 libglib2.0-0 libglu1-mesa libsm6 libxrender1 libfontconfig1 libxext6 libxcb1
wps-office depends on libfreetype6 (>= 2.4); however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:
wps-office depends on ; however:

# vscode 1.88.1 ##libgtk-3-0: 16M;
apt install --no-install-recommends \
  libnss3 libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 libgbm1

```

- note from: base/Dockerfile-ubt

```dockerfile
# # fontconfig>> ttf-dejavu
# RUN apt.sh \
#   ttf-dejavu

# libicu66: 
# RUN apt.sh \
#     # plank \ #compton-plank遮盖去域不可用
#     # compton \
#     xcompmgr \
#     hsetroot 
#     # dunst pnmixer clipit \
#     # fluxbox 

# +Apps
# RUN apt.sh \
#  pcmanfm geany ristretto engrampa \
#  lxtask lxappearance pavucontrol
# RUN apt.sh gparted

# # vscode-deps
# RUN apt.sh \
#   libdrm2 libgbm1 libnspr4 libnss3 libsecret-1-0 libxkbfile1 xdg-utils

# ASBRU: 3586 kB (disk: 15.5 MB)
# RUN echo 1;\
#   curl -1sLf 'https://dl.cloudsmith.io/public/asbru-cm/release/cfg/setup/bash.deb.sh' | sudo -E bash; \
#   apt.sh asbru-cm; rm -f /etc/apt/sources.list.d/asbru-cm-release.list; \
#   mv /opt/asbru /usr/local; rm -f /usr/bin/asbru-cm; ln -s /usr/local/asbru/asbru-cm /usr/bin/; \
#   cd /usr/share/icons/hicolor/scalable/apps; rm -f asbru-cm.svg; ln -s /usr/local/asbru/res/asbru-logo.svg ./asbru-cm.svg; \
#   dpkg -l |grep asbru && exit 0 || exit 1;  

  # thunar lxappearance language-pack-gnome-zh-hans \
# THEME
# RUN apt.sh \
#   \
#   # +papirus-icon-theme
#   # dbus-x11 at-spi2-core
#   papirus-icon-theme greybird-gtk-theme; \
#   rm -f /usr/share/backgrounds/greybird.svg; \
#   \
#   wget --no-check-certificate https://gitee.com/infrastlabs/docker-headless/raw/dev/_doc/assets/bunsen-papirus-icon-theme_10.3-2_all.deb; \
#   dpkg -i bunsen-papirus-icon-theme_10.3-2_all.deb; rm -f bunsen-papirus-icon-theme_10.3-2_all.deb; \
#   cd /usr/share/icons && rm -rf Papirus-Bunsen-Dark-bluegrey Papirus-Bunsen-Dark-grey Papirus-Dark Papirus-Light ePapirus; \
#   \
#   # Papirus left: 16x(clipit:21M) 64x(desktop:21M)
#   cd /usr/share/icons/Papirus && rm -rf 18x* 22x* 24x* 32x*  48x* 64x* ; \
#   ls -lh /usr/share/icons/Papirus; \
#   \
#   dpkg -l |grep bunsen && exit 0 || exit 1;

```


## ref headless

```bash
# dev############################
# JAVA
sudo apt -y install openjdk-8-jdk openjdk-8-source && sudo apt -y install maven 
# GO
goVer=go1.19.9 #1.19.9:142.16M 1.17.8:129M #go1.16.15 #go1.13.15
wget https://studygolang.com/dl/golang/$goVer.linux-amd64.tar.gz
tar -zxf $goVer.linux-amd64.tar.gz; mv go $goVer.linux-amd64
rm -f godev; ln -s $goVer.linux-amd64 godev #link godev
# NODE https://nodejs.org/zh-cn/download/releases
ver=v18.16.0 #v16.20.0 #v14.20.0
wget https://nodejs.org/download/release/$ver/node-$ver-linux-x64.tar.xz
xz -d node-$ver-linux-x64.tar.xz #tar.xz消失
tar -xvf node-$ver-linux-x64.tar

# cat >> /etc/profile <<EOF
cat <<EOF |sudo tee -a /etc/profile
# NODE
NODE_HOME=/_ext/down/node-v14.20.0-linux-x64
PATH=\$NODE_HOME/bin:\$PATH
export NODE_HOME PATH
# GO
GO_HOME=/_ext/down/godev
GOPATH=/_ext/gopath
PATH=\$GO_HOME/bin:\$GOPATH/bin:\$PATH
export GO_HOME GOPATH PATH
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
EOF


#IDE: vscode, ideaIC###################
# wget https://vscode.cdn.azure.cn/stable/91899dcef7b8110878ea59626991a18c8a6a1b3e/code_1.47.3-1595520028_amd64.deb
# wget https://vscode.cdn.azure.cn/stable/c3f126316369cd610563c75b1b1725e0679adfb3/code_1.58.2-1626302803_amd64.deb
# wget https://vscode.cdn.azure.cn/stable/6cba118ac49a1b88332f312a8f67186f7f3c1643/code_1.61.2-1634656828_amd64.deb
wget https://vscode.cdn.azure.cn/stable/e8a3071ea4344d9d48ef8a4df2c097372b0c5161/code_1.74.2-1671532382_arm64.deb
wget https://vscode.cdn.azure.cn/stable/6445d93c81ebe42c4cbd7a60712e0b17d9463e97/code_1.81.0-1690980880_amd64.deb
###
https://code.visualstudio.com/updates/v1_74  #az764295.vo.msecnd.net > vscode.cdn.azure.cn
https://update.code.visualstudio.com/1.74.3/linux-x64/stable
https://update.code.visualstudio.com/1.74.3/linux-arm64/stable #x64> arm64
https://vscode.cdn.azure.cn/stable/97dec172d3256f8ca4bfb2143f3f76b503ca0534/code-stable-arm64-1673284434.tar.gz
https://vscode.cdn.azure.cn/stable/97dec172d3256f8ca4bfb2143f3f76b503ca0534/code-stable-x64-1673285154.tar.gz
# 2024.4
https://vscode.download.prss.microsoft.com/dbazure/download/stable/e170252f762678dec6ca2cc69aba1570769a5d39/code-stable-x64-1712770462.tar.gz
#
#wget https://download.jetbrains.8686c.com/idea/ideaIC-2016.3.8-no-jdk.tar.gz
#wget https://download.jetbrains.com.cn/idea/ideaIC-2016.3.8-no-jdk.tar.gz #322M
wget https://download.jetbrains.com/idea/ideaIC-2017.3.7-no-jdk.tar.gz #366M JUnit5 Support


# wps, chrome/firefox###################
# 火狐/谷歌浏览器
sudo apt -y install firefox #firefox-esr chromium
# firefox-cn #dep:libdbus-glib-1-2
https://download-ssl.firefox.com.cn/releases/firefox/esr/115.1/zh-CN/Firefox-latest-x86_64.tar.bz2

# 网易云音乐
wget https://d1.music.126.net/dmusic/netease-cloud-music_1.2.1_amd64_ubuntu_20190428.deb
# WPS三件套
# https://blog.csdn.net/u012939880/article/details/89439647 #wps_symbol_fonts.zip
wget https://wdl1.cache.wps.cn/wps/download/ep/Linux2019/10161/wps-office_11.1.0.10161_amd64.deb
# 支持中文输入法
sudo sed -i "1a export XMODIFIERS=@im=ibus" /usr/bin/{wps,wpp,et}
sudo sed -i "2a export QT_IM_MODULE=ibus" /usr/bin/{wps,wpp,et}
```


