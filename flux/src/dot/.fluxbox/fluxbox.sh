$RUN \
  # cd /tmp; file=Squared_for_Debian.zip; curl -fSL -k -O https://gitee.com/infrastlabs/docker-headless/raw/dev/_doc/assets/flux/$file; \
  # unzip -d /usr/share/fluxbox/styles/ $file; rm -f /tmp/$file; \
  # wget -qO /usr/share/images/fluxbox/debian-squared.jpg https://gitee.com/infrastlabs/docker-headless/raw/dev/_doc/assets/bg/bg-debian-liteblue.png; \
  \
  # wget --connect-timeout=3 -qO /usr/share/images/fluxbox/ubuntu-light.png https://gitee.com/infrastlabs/docker-headless/raw/dev/_doc/assets/bg/bg-debian-liteblue.png; 
  # openwrt: wget: unrecognized option: connect-timeout=3
  wget --connect-timeout=3 -qO /usr/share/images/fluxbox/ubuntu-light.png https://gitee.com/infrastlabs/docker-headless/raw/dev/_doc/assets/bg/pure-blue.jpg; 

# # theme
##left:
# MerleyKay
# Squared_blue
# Squared_green
# bora_black
# carp
# ubuntu-light
# zimek_darkblue
# zimek_green
echo """
# Artwiz
# Bity_fluxbox
# BlueFlux
# BlueNight
# Doty
# Emerge
# Flux
# LemonSpace
# Makro
MerleyKay
# Meta
# Nyz
# Operation
# Outcomes
# Results
# Shade
Squared_blue
Squared_green
# Twice
# arch
# bloe
bora_black
# bora_blue
# bora_green
carp
# green_tea
# ostrich
# qnx-photon
# ubuntu-dark
ubuntu-light
# zimek_bisque
zimek_darkblue
zimek_green
""" > /tmp/_flux_themes.txt
dst=/usr/local/static/fluxbox/share/fluxbox #/styles
ls $dst/styles |while read one; do
  match1=$(cat /tmp/_flux_themes.txt |grep -Ev "^#|^$" |grep "$one")
  test -z "$match1" && rm -rf $dst/styles/$one
done
dst=/usr/share/fluxbox; mkdir -p $dst
\cp -a /usr/local/static/fluxbox/share/fluxbox/* $dst/ #copy
# origin's clear
ls $dst/styles |while read one; do
  match1=$(cat /tmp/_flux_themes.txt |grep -Ev "^#|^$" |grep "$one")
  test -z "$match1" && rm -rf $dst/styles/$one
done



# skel
  # /etc/skel/.config/clipit \
  # /etc/skel/.config/pnmixer \
  # /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml \
mkdir -p \
  /etc/skel/.config/gtk-3.0 \
  /etc/skel/.fluxbox;

file=/etc/skel/.fluxbox/overlay; \
echo -e "\
menu.hilite.font: PT Sans-11:regular\n\
menu.frame.font: PT Sans-11:regular\n\
menu.title.font: PT Sans-11:regular\n\
toolbar.clock.font: PT Sans-11:bold\n\
toolbar.workspace.font: PT Sans-11:regular\n\
toolbar.iconbar.focused.font: PT Sans-11:regular\n\
toolbar.iconbar.unfocused.font: PT Sans-11:regular\n\
window.font: PT Sans-9:regular\n\
  " > $file;
# sed -i  "s/PT Sans/WenQuanYi Zen Hei/" $file; 
  
file=/etc/skel/.fluxbox/init; \
echo -e "\
# session.styleFile: /usr/share/fluxbox/styles/Squared_for_Debian\n\
# bloe> zimek_darkblue> MerleyKay\n\
# session.styleFile: /usr/local/static/fluxbox/share/fluxbox/styles/MerleyKay\n\
session.styleFile: /usr/share/fluxbox/styles/MerleyKay\n\
#sakura's border
session.screen0.colPlacementDirection: TopToBottom\n\
session.screen0.defaultDeco: NORMAL\n\
\n\
#windows's width @bar
session.screen0.iconbar.alignment: Left\n\
session.screen0.iconbar.iconTextPadding:        15\n\
session.screen0.iconbar.iconWidth:      134\n\
session.screen0.iconbar.mode: {static groups} (workspace)\n\
session.screen0.iconbar.usePixmap: false\n\
\n\
# #session.screen0.toolbar.placement:      TopRight\n\
session.screen0.toolbar.tools: prevworkspace, workspacename, nextworkspace, iconbar, systemtray, clock\n\
session.screen0.toolbar.widthPercent: 99\n\
  " > $file; 
  
# file=/etc/skel/.config/clipit/clipitrc; \
# echo -e "\
# [rc]\n\
# save_history=true\n\
#   " > $file; 
  
# file=/etc/skel/.config/pnmixer/config; \
# echo -e "\
# [PNMixer]\n\
# VolumeControlCommand=pavucontrol\n\
#   " > $file; 
  
# file=/etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml; \
# echo -e "\
# <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
# \n\
# <channel name=\"thunar\" version=\"1.0\">\n\
#   <property name=\"last-view\" type=\"string\" value=\"ThunarIconView\"/>\n\
#   <property name=\"last-location-bar\" type=\"string\" value=\"ThunarLocationEntry\"/>\n\
#   <property name=\"last-icon-view-zoom-level\" type=\"string\" value=\"THUNAR_ZOOM_LEVEL_100_PERCENT\"/>\n\
#   <property name=\"last-separator-position\" type=\"int\" value=\"170\"/>\n\
#   <property name=\"hidden-bookmarks\" type=\"array\">\n\
#     <value type=\"string\" value=\"network://\"/>\n\
#   </property>\n\
# </channel>\n\
#   " > $file; 
  
file=/etc/skel/.config/gtk-3.0/settings.ini; \
echo -e "\
[Settings]\n\
gtk-theme-name=Greybird\n\
gtk-icon-theme-name=Papirus-Bunsen-bluegrey\n\
gtk-cursor-theme-name=XCursor-Pro-Dark\n\
gtk-cursor-theme-size=0\n\
  " > $file; 
  
# .gtkrc-2.0: lxappearance still not preseted.
# cat $file > /etc/skel/.gtkrc-2.0; \


# view
find /etc/skel |wc; 
