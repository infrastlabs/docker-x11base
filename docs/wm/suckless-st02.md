

- alpine-apk-st084


```bash
/mnt2/jgmenu # apk add st
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/main/x86_64/APKINDEX.tar.gz
fetch http://mirrors.ustc.edu.cn/alpine/v3.15/community/x86_64/APKINDEX.tar.gz
(1/1) Installing st (0.8.4-r0)
Executing busybox-1.34.1-r7.trigger
OK: 910 MiB in 358 packages
/mnt2/jgmenu # st
can't open display
/mnt2/jgmenu # st -v
st 0.8.4
/mnt2/jgmenu # st -h
usage: st [-aiv] [-c class] [-f font] [-g geometry] [-n name] [-o file]
          [-T title] [-t title] [-w windowid] [[-e] command [args ...]]
       st [-aiv] [-c class] [-f font] [-g geometry] [-n name] [-o file]
          [-T title] [-t title] [-w windowid] -l line [stty_args ...]
```

- fk-suckless-st(org's master)

```bash
# cd /mnt2/
# git clone https://gitee.com/g-system/fk-suckless-st
1012 cd ../fk-suckless-st/
1013 ls
1014 env |grep FLAG
1015 make
1016 cp config.mk config.mk-bk1
1017 vi config.mk
1025 make
1026 ls /usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a
1027 make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
1028 cat config.mk |grep "lX11" -n


# mk libs
# -lX11-xcb -lxcb  -ljpeg
/mnt2/fk-suckless-st # cat config.mk |grep "lX11" -n
19:LIBS = -L$(X11LIB) -lm -lrt -lX11 -lutil -lXft -lX11-xcb -lxcb  -ljpeg  \
30:#LIBS = -L$(X11LIB) -lm -lX11 -lutil -lXft \


/mnt2/fk-suckless-st # make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcolor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcore.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdpy.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdraw.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftfreetype.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftglyphs.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftrender.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fcxml.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftgzip.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb.a(xcb_auth.o):
/mnt2/fk-suckless-st # 




# -lfreetype ##一样错误
/mnt2/fk-suckless-st # cat config.mk |grep "lX11" -n
19:LIBS = -L$(X11LIB) -lm -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -ljpeg -lfreetype   \
```

- master> v084

```bash
# git clone --branch 0.8.4 https://gitee.com/g-system/fk-suckless-st fk-suckless-st-v084
# /mnt2/fk-suckless-st-v084 # make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(ClDisplay.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(OpenDis.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_disp.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libX11.a(xcb_io.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcolor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcore.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdpy.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdraw.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftfreetype.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftglyphs.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftrender.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fcxml.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftgzip.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):



# refs
# tiger-xorg
# sed 's/^XSERVER_SYS_LIBS = .*/XSERVER_SYS_LIBS = -lXau -lXdmcp -lpixman-1 -ljpeg -lXfont2 -lfreetype -lfontenc -lpng16 -lbrotlidec -lbrotlicommon -lz -lbz2 -lgnutls -lhogweed -lgmp -lnettle -lunistring -ltasn1 -lbsd -lmd/' -i /tmp/tigervnc/unix/xserver/hw/vnc/Makefile
# openbox
# OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" \


# out: -lpng 
# -lfontconfig -lfreetype -lXrender
/mnt2/fk-suckless-st-v084 # cat config.mk |grep "lX11" -n
19:LIBS = -L$(X11LIB) -lm -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender  \

/mnt2/fk-suckless-st-v084 # make 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcolor.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftcore.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdpy.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftdraw.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libXft.a(xftglyphs.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fcxml.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftgzip.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libxcb.a(xcb_auth.o):
/mnt2/fk-suckless-st-v084 # 
```


- try03, static-build-OK

```bash
# ref openbox; 全已装
apk add libx11-static \
    libxcb-static \
    libxdmcp-dev \
    libxau-dev \
    freetype-static


# OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 

# -lXdmcp>> xcb_auth错误没有了; libXft错误没有了; 
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfontconfig.a(fcxml.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftbzip2.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(ftgzip.o):
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):


#  -lexpat -lxml2 -lz -lbz2 -llzma >> 只剩libfreetype.a(sfnt.o)错误;
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp    -lexpat -lxml2 -lz -lbz2 -llzma" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):


####INFO, REPEAT
/mnt2/fk-suckless-st-v084 # cat config.mk |grep lX11 -A2
LIBS = -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender  \
       `$(PKG_CONFIG) --libs fontconfig` \
       `$(PKG_CONFIG) --libs freetype2`

/mnt2/fk-suckless-st-v084 # make clean
rm -f st st.o x.o st-0.8.4.tar.gz
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp    -lexpat -lxml2 -lz -lbz2 -llzma" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/usr/bin/../lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../libfreetype.a(sfnt.o):



# ref_openbox OB_LIBS全拷贝(冗余)>> 编译过了!!
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp    -lexpat -lxml2 -lz -lbz2 -llzma     -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u

# validate01
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 15:58 st
/mnt2/fk-suckless-st-v084 # xx-verify --static st
/mnt2/fk-suckless-st-v084 # echo $?
0
```

- args-cut


` -static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon `

```bash
#####args-cut
/mnt2/fk-suckless-st-v084 # 
/mnt2/fk-suckless-st-v084 # make clean
rm -f st st.o x.o st-0.8.4.tar.gz
/mnt2/fk-suckless-st-v084 # 
/mnt2/fk-suckless-st-v084 # 
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp    -lexpat -lxml2 -lz -lbz2 -llzma     -lX11  -lfontconfig -lfreetype -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi" 2>&1 |grep musl/10 |awk '{print $2}' |sort -u
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:14 st


/mnt2/fk-suckless-st-v084 # make clean
rm -f st st.o x.o st-0.8.4.tar.gz
/mnt2/fk-suckless-st-v084 # make LDFLAGS="--static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon " 2>&1 |grep musl/10 |awk '{print $2}' |sort -u


# logs-cmd:
xx-clang -o st st.o x.o -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender   `pkg-config --libs fontconfig`  `pkg-config --libs freetype2` --static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon 

# OK1
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg    `pkg-config --libs fontconfig`  `pkg-config --libs freetype2` --static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon


# OK2
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o -lrt -lX11 -lutil -lXft        --static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon 
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:34 st


# OK3
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o   -lXft        --static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon 
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:36 st


# OK4
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o   -lXft        --static -lrt -lX11 -lutil -lXft    -lX11-xcb -lxcb -lXau -ljpeg  -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:40 st


# OK5
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o   -lXft        --static -lrt -lX11 -lutil -lXft     -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
/mnt2/fk-suckless-st-v084 # 
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:45 st


# OK51
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o   -lXft        --static  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp
        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:46 st

# OK52(-lXft后移; --static/-static)
/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o           --static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon

/mnt2/fk-suckless-st-v084 # xx-clang -o st st.o x.o           -static -lXft  -lX11       -lxcb -lXau -lfontconfig -lfreetype  -lXrender -lXdmcp        -lpng  -lexpat -lxml2 -lz -lbz2  -lbrotlidec -lbrotlicommon 

# view,cp-out
/mnt2/fk-suckless-st-v084 # ls -lh st
-rwxr-xr-x    1 root     root        3.7M Nov  1 16:49 st
/mnt2/fk-suckless-st-v084 # cp st /mnt2/xrdp-static-alpine/


# validate02:
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ls
bin  dropbear  etc  include  lib  sbin  share  st  xrdp-chansrv
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./st  -h
usage: ./st [-aiv] [-c class] [-f font] [-g geometry] [-n name] [-o file]
          [-T title] [-t title] [-w windowid] [[-e] command [args ...]]
       ./st [-aiv] [-c class] [-f font] [-g geometry] [-n name] [-o file]
          [-T title] [-t title] [-w windowid] -l line [stty_args ...]
root@VM-12-9-ubuntu:/mnt/xrdp-static-alpine# ./st  
can't open display
```