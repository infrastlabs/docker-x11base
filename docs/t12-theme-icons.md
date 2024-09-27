

```bash
docker run -it --rm  --privileged dockerpull.com/ubuntu:24.04 bash

export DOMAIN="mirrors.ustc.edu.cn";
V2=noble 
target=ubuntu
test -z "$(echo $TARGETPLATFORM |grep arm)" && target=ubuntu || target=ubuntu-ports; \
  echo "deb http://${DOMAIN}/$target ${V2} main restricted universe multiverse" > /etc/apt/sources.list \
  && echo "deb http://${DOMAIN}/$target ${V2}-updates main restricted universe multiverse">> /etc/apt/sources.list; \
  rm -f /etc/apt/sources.list.d/*;

echo -e "Acquire {\n\
  APT::Get::Allow-Unauthenticated \"true\";\n\
  GPG::Ignore \"true\";\n\
  AllowInsecureRepositories \"true\";\n\
  AllowDowngradeToInsecureRepositories \"true\";\n\
}" > /etc/apt/apt.conf.d/skip-gpg-check-ig;
cat /etc/apt/apt.conf.d/skip-gpg-check-ig

apt update
# papirus-icon-theme (20240201-1)
apt install --no-install-recommends -yq  papirus-icon-theme
  # fonts-wqy-microhei 1607 kB of archives.
  # language-pack-gnome-zh-hans 7930 kB>> 32.3 MB of additional disk space
  # greybird-gtk-theme 一堆deps 26.6 MB>> 121 MB of additional disk space


```