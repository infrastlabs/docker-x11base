

**Compile**

- de-alpine-xxbox.md
  - ### dyn build
    - try01: nls err
    - try02: v137 with --disable-xx x4 >> masterBuild OK;
  - ### static build
    - try03: static with master `0f95d62b1b1add8ee7327305db7d372010fdb2f4` (--enable-static还是动态)
    - try04: LDFALGS (ref suckless) `make LDFLAGS="$flags $OB_LIBS -luuid"`
    - try05: `try: pango,xrandr` 查找/usr/lib下静态库
    - try06: src//`./INSTALL`>> `./configure加参数` >> `undefined reference to 'Remember::s_instance'
    - try07: notes `--disable-remember \` >> static buildOK
    - try08: **libs clear** `CONFIGURE去EX_LIBS>> OK;  disable_x4> enable_x4`
  - ### flux-run @ubt2004 `Couldn\'t initialize fonts. Check your fontconfig installation.`
- t1-obox-dbg.md
  - **flux try run** `Couldn\'t initialize fonts. Check your fontconfig installation.`
  - enable-xft;
  - cp2 [**libs clear**], `--disable-xmb`
  - 安装font即可？(ubt默认有; alpine:`ttf-dejavu`)

**Src**

- master@23.11 [lastCommit:20230806]
- mark-20210725
- v137@2015.2.8
- v100@2007.4.8
- v0.9.11@2004.12.7
- v0.9.0@2003.2.24
- v0.1.6@2002.1.11
- devel@2001.12.12[init]

## Fluxbox03

- with imlib2

```bash
# fontconfig
# bash _ex/fontconfig/build.sh
# cp /tmp/fontconfig-install/usr/lib/libfontconfig.a /usr/lib/
apk add fontconfig-static

# deps
bash x-xrdp/build.sh libxrandr #不指定，内部即需要
bash v-xlunch/build.sh imlib2; #+
\cp -a /usr/local/lib/imlib2 /usr/lib/

# flux
export TARGETPATH=/usr/local/static/fluxbox
git pull; bash fluxbox/build.sh.xft.sh fluxbox
# configure: error: C compiler cannot create executables


# git clone;
# branch="--branch=$FLUXBOX_VER"
git clone --depth=1 $branch https://gitee.com/g-system/fk-fluxbox /tmp/fluxbox

cd /tmp/fluxbox
# OB_LIBS=""
flags="-lXft -lX11 -lxcb -lXau -lfontconfig -lfreetype -lXrender -lXdmcp -lpng -lexpat -lxml2 -lz -lbz2 -lbrotlidec -lbrotlicommon"
imlib="-lImlib2 -L/usr/local/lib -lxcb-shm "
EX_LIBS="$flags $OB_LIBS -lXinerama $imlib  -lX11 -lfontconfig -lfreetype -lXext -lXrandr"

# 
autoreconf -fi

# configure: WARNING: unrecognized options: --disable-docs, --enable-static, --disable-shared
./configure \
  --prefix=$TARGETPATH \
  --enable-xmb \
  --enable-slit \
  --enable-toolbar \
  --enable-fribidi \
  \
  --enable-imlib2 \
  --disable-nls \
  --enable-xft \
  --enable-xinerama \
  \
  --disable-docs \
  --enable-static \
  --disable-shared \
  LIBS="-lxcb -lXdmcp -lXau -lpthread $EX_LIBS"

# make
make LDFLAGS="-static"
make LDFLAGS="-static" LIBS="-lxcb -lXdmcp -lXau -lpthread -luuid -lX11-xcb $EX_LIBS" #+uuid -lX11-xcb
# /usr/lib/gcc/x86_64-alpine-linux-musl/10.3.1/../../../../x86_64-alpine-linux-musl/bin/ld: /usr/local/lib/libImlib2.a(ximage.o): in function `__imlib_ShmGetXImage':


# view
# bash-5.1# ls -lh
-rwxr-xr-x    1 root     root       13.0M Dec  2 17:42 fbrun
-rwxr-xr-x    1 root     root       13.0M Dec  2 17:42 fbsetroot
-rwxr-xr-x    1 root     root       49.5M Dec  2 17:42 fluxbox ##多次调试deps,导致文件体变大? (xx.c> xx.o; ld?)
-rwxr-xr-x    1 root     root        3.1M Dec  2 17:42 fluxbox-remote
-rwxr-xr-x    1 root     root       10.2M Dec  2 17:42 fluxbox-update_configs
-rw-r--r--    1 root     root       12.5M Dec  2 17:31 libFbTk.a

# build.sh.xft.sh 脚本内二次验证;
err 0, pass
本操作从2023年12月02日17:48:43 开始 , 到2023年12月02日17:51:22 结束,  共历时159秒
fluxbox, finished.
bash-5.1# ls -lh /tmp/fluxbox/fluxbox
-rwxr-xr-x    1 root     root       12.4M Dec  2 17:51 /tmp/fluxbox/fluxbox
bash-5.1# git pull; bash fluxbox/build.sh.xft.sh fluxbox


# validate bin>> 也是无time; bar无右键; (双击winTitle:最大/最小化)
root@tenvm2:~# docker run -it --rm --net=host -v /mnt/_statics/fluxbox:/rootfs/files1/usr/local/static/fluxbox/bin/fluxbox infrastlabs/x11-base:alpine


```

- nls

```bash
# ref: de-alpine-xxbox.md
# hand
./autogen.sh
./configure 
make
/bin/sh: fluxbox.cat: not found



```

- args

```bash
# ref
  --disable-dependency-tracking
                          speeds up one-time build
  --enable-silent-rules   less verbose build output (undo: "make V=1")
  --disable-silent-rules  verbose build output (undo: "make V=0")
  --disable-rpath         do not hardcode runtime library paths
  --enable-remember       include Remembering attributes (default=yes)
  --enable-regexp         regular expression support (default=yes)
  --enable-slit           include code for the Slit (default=yes)
  --enable-systray        include SystemTray (default=yes)
  --enable-toolbar        include Toolbar (default=yes)
  --enable-ewmh           enable support for Extended Window Manager Hints
                          (default=yes)
  --enable-debug          include verbose debugging code (default=no)
  --enable-test           build programs used in testing fluxbox (default=no)
  --enable-nls            include native language support (default=yes)
  --enable-timedcache     use new timed pixmap cache (default=yes)
  --enable-xmb            XMB (multibyte font, utf-8) support (default=yes)
  --disable-imlib2        disable imlib2 support
  --disable-xft           disable xft support
  --disable-freetype2     disable freetype2 support
  --disable-xrender       disable xrender support
  --disable-xpm           disable xpm support
  --disable-xinerama      disable xinerama support
  --disable-xext          disable Misc X Extension Library support
  --disable-xrandr        disable xrandr support
  --disable-fribidi       disable fribidi support


# args
  # --disable-rpath  \
  --disable-dependency-tracking \
  --disable-silent-rules \
  --enable-remember=yes \
  --enable-regexp=yes \
  --enable-slit=yes \
  --enable-systray=yes \
  --enable-toolbar=yes \
  --enable-ewmh=yes \
  --enable-debug=no \
  --enable-test=no \
  --enable-nls=no \
  --enable-timedcache=yes \
  --enable-xmb=yes \
  \
  --disable-imlib2 \
  --disable-freetype2 \
  --disable-xrender   \
  --disable-xft       \
  --disable-xpm       \
  --disable-xext      \
  --disable-xrandr    \
  --disable-fribidi   \
  --disable-xinerama  

# /mnt/_statics/fluxbox ##3rd生成，验证：
#  符号字体乱码@Alpine;
#  bar邮件/时间: 依旧无
#  3rd: xcompmgr可运行了@.flux/startup
```


