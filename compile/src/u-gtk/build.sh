#!/bin/sh
set -e
source /src/common.sh

function atk(){ ##@meson
  # apk update; apk add gobject-introspection-dev

  log "Downloading atk..."
  branch="--branch=ATK_2_35_1" #ATK_2_36_0  [2.35.1@ubt2004; 2.36.0@alpine315]
  branch="--branch=ATK_2_36_0"
  rm -rf /tmp/atk; git clone --depth=1 $branch $GITHUB/GNOME/atk /tmp/atk
  cd /tmp/atk
    # [44/53] Linking static target atk/libatk-1.0.a
    # [45/53] Linking target atk/libatk-1.0.so.0.23510.1 ##err attempted static link of dynamic object '/usr/lib/libglib-2.0.so'
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    # ./autogen.sh 
    # ./configure --enable-static; 
    # meson build
    # static>> undefined reference to 'png_destroy_write_struct'
    meson build  --default-library=both #both static

  log "Compiling atk..."
    # make
    ninja -C build/

  log "Installing atk..."
    # make install
    ninja -C build/ install
  
  cp -a /usr/local/lib/libatk-1.0.a /usr/lib/
}

# meson build>> clone: gi-docgen [by meson_py slow..; meson两个文件未找到docgen信息]
function gdk-pixbuf(){ ##@meson
  # apk update; apk add shared-mime-info

  log "Downloading gdk-pixbuf..."
  branch="--branch=2.40.0" #2.42.8 [2.40.0@ubt2004; 2.42.8@alpine315]
  branch="--branch=2.42.8"
  rm -rf /tmp/gdk-pixbuf; git clone --depth=1 $branch $GITHUB/GNOME/gdk-pixbuf /tmp/gdk-pixbuf
  cd /tmp/gdk-pixbuf
  log "Patching gdk-pixbuf (builtin svg loader)..."
    patch -p1 < /src/u-gtk/gdk-pixbuf-2.42.8-lxtask-static.patch || { log "GDKPIXBUF PATCH FAILED"; exit 1; }
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all" #同atk
    # ./autogen.sh 
    # ./configure; 
    # meson build
    meson build  --default-library=both #both static

  log "Compiling gdk-pixbuf..."
    # 去除xsltproc;
    dst=/usr/bin/xsltproc
    mv $dst ${dst}00
    touch $dst; chmod +x $dst
    echo -e "!/bin/bash\n echo 123" > $dst

    # make
    ninja -C build

  log "Installing gdk-pixbuf..."
    touch build/docs/gdk-pixbuf-csource.1
    touch build/docs/gdk-pixbuf-query-loaders.1
    # make install
    ninja -C build install
  
  ls -lh /usr/local/lib/libgdk_pixbuf-2.0.a #hand: 1016.6K> build.sh_ver2.40.0_hand: 807.2K
  cp /usr/local/lib/libgdk_pixbuf-2.0.a /usr/lib/ #1016.4K @alpine's_ver_2.42.8
  # cp ./build/gdk-pixbuf/libgdk_pixbuf-2.0.a
}

# You must have automake 1.7.x, 1,10.x, 1.11.x, 1.12.x, 1.13.x, 1.14.x
# or 1.15.x installed to compile Gtk+.
# Install the appropriate package for your distribution,
# or get the source tarball at http://ftp.gnu.org/gnu/automake/
# bash-5.1# apk list |grep automake  ##版本过高?
# automake-1.16.4-r1 x86_64 {automake} (GPL-2.0-or-later MIT Public-Domain) [installed]

# 改2.24.33;
# checking for gdk-pixbuf-csource... /usr/local/bin/gdk-pixbuf-csource
# checking for XOpenDisplay... no
# configure: error: *** libX11 not found. Check 'config.log' for more details.
# 
# xcompmgr>> # ref: opbox>> deps: 已全装
# 试着改回: meson的两个; （一样错：libX11 not found）
function gtk_ibus_a2(){
  # 方案A2(2026-11-07 定案+实测通过): 把 ibus im 模块静态注册进 libgtk-x11-2.0.a。
  # 前置: IBUS_BUILD 指向已构建的 ibus 源码树(client/gtk2/.libs 三对象 + src/.libs/libibus-1.0.a),
  # 默认 /tmp/ibus; 产物缺失则跳过(基座 gtk 仍可用)。最终合并进 ./gtk/.libs/libgtk-x11-2.0.a。
  # 说明: gtkimmodule.o 用 make -n 捕获编译命令+追加 -DINCLUDE_IM_ibus 重编; ibusim.o 用守卫
  # 补丁+ -DINCLUDE_IM_ibus 重编(排除 g_module_check_init, 避免与 murrine_theme_main.o 冲突);
  # 其余 ibus 对象/libibus.a 直接取自 IBUS_BUILD 构建产物, ar r 按名合并。
  local IBUS="${IBUS_BUILD:-/tmp/ibus}"
  local OBJ=/tmp/ibus-a2-merge
  [ -f "$IBUS/client/gtk2/.libs/im_ibus_la-ibusim.o" ] || { log "A2 SKIP: ibus module objects NOT found ($IBUS)"; return 0; }
  [ -f "$IBUS/src/.libs/libibus-1.0.a" ] || { log "A2 SKIP: libibus-1.0.a NOT found ($IBUS)"; return 0; }
  log "A2: merge ibus im module -> ./gtk/.libs/libgtk-x11-2.0.a (IBUS=$IBUS)"
  rm -rf "$OBJ"; mkdir -p "$OBJ"; cd /tmp/gtk
  # 1) gtkimmodule.c: 加 INCLUDE_IM_ibus do_builtin(ibus)
  grep -q "do_builtin (ibus)" gtk/gtkimmodule.c || patch -p1 < /src/u-gtk/gtk-ibus-builtin.patch || { log "A2 gtk patch FAILED"; exit 1; }
  # 2) 重编 gtkimmodule.o (继承配置宏 + INCLUDE_IM_ibus)
  local CMD; CMD=$(make -n -C gtk gtkimmodule.lo 2>/dev/null | grep -m1 "mode=compile")
  CMD=$(printf '%s' "$CMD" | sed -n 's#^.* gcc #gcc #p')
  CMD=$(printf '%s' "$CMD" | sed "s#-o gtkimmodule\.lo#-o $OBJ/gtkimmodule.o#; s#-DINCLUDE_IM_xim#-DINCLUDE_IM_xim -DINCLUDE_IM_ibus#")
  [ -n "$CMD" ] || { log "A2 FAIL: gtkimmodule compile cmd NOT captured"; exit 1; }
  ( cd /tmp/gtk/gtk && eval "$CMD" ) || { log "A2 FAIL: gtkimmodule.o compile"; exit 1; }
  # 3) glue: im_module_* -> _gtk_immodule_ibus_*
  xx-clang $(pkg-config --cflags gtk+-2.0) -c /src/u-gtk/ibus-builtin-glue.c -o "$OBJ/ibus-builtin.o" || { log "A2 FAIL: glue compile"; exit 1; }
  # 4) ibusim.o: 守卫补丁 + -DINCLUDE_IM_ibus 重编
  grep -q "#ifndef INCLUDE_IM_ibus" "$IBUS/client/gtk2/ibusim.c" || patch -d "$IBUS" -p1 < /src/u-gtk/ibus-ibusim-gmodule-check-init.patch || { log "A2 ibusim patch FAILED"; exit 1; }
  local IBCMD; IBCMD=$(make -n -C "$IBUS/client/gtk2" im_ibus_la-ibusim.lo 2>/dev/null | grep -m1 "mode=compile")
  IBCMD=$(printf '%s' "$IBCMD" | sed -n 's#^.* xx-clang #xx-clang #p')
  IBCMD=$(printf '%s' "$IBCMD" | sed "s#-o im_ibus_la-ibusim\.lo#-o $OBJ/ibusim.o#; s#-DHAVE_CONFIG_H#-DHAVE_CONFIG_H -DINCLUDE_IM_ibus#")
  [ -n "$IBCMD" ] || { log "A2 FAIL: ibusim compile cmd NOT captured"; exit 1; }
  ( cd "$IBUS/client/gtk2" && eval "$IBCMD" ) || { log "A2 FAIL: ibusim.o compile"; exit 1; }
  cp "$IBUS/client/gtk2/.libs/im_ibus_la-ibusimcontext.o" "$OBJ/ibusimcontext.o"
  cp "$IBUS/client/gtk2/.libs/im_ibus_la-iconwidget.o" "$OBJ/iconwidget.o"
  # 5) 解出 libibus-1.0.a 全部 .o
  ( cd "$OBJ" && ar x "$IBUS/src/.libs/libibus-1.0.a" )
  [ -n "$(ls "$OBJ"/libibus_1_0_la-*.o 2>/dev/null)" ] || { log "A2 FAIL: no libibus .o extracted"; exit 1; }
  # 6) ar r 按名替换/加入 (gtkimmodule.o 替换原版; 其余新增)
  ar r ./gtk/.libs/libgtk-x11-2.0.a "$OBJ/gtkimmodule.o" "$OBJ/ibus-builtin.o" "$OBJ/ibusim.o" "$OBJ/ibusimcontext.o" "$OBJ/iconwidget.o" "$OBJ"/libibus_1_0_la-*.o || { log "A2 FAIL: ar r"; exit 1; }
  log "A2 merged; _gtk_immodule_ibus_init count: $(nm ./gtk/.libs/libgtk-x11-2.0.a 2>/dev/null | grep -c ' T _gtk_immodule_ibus_init')"
}

function gtk(){
  # apk update; apk add gtk-doc shared-mime-info

  log "Downloading gtk..."
  branch="--branch=2.24.32" #2.24.33  ##提示automake版本不符(过高)
  branch="--branch=2.24.33"
  # https://blog.csdn.net/weixin_46591962/article/details/132247425
  rm -rf /tmp/gtk; git clone --depth=1 $branch $GITHUB/GNOME/gtk /tmp/gtk
  cd /tmp/gtk
  log "Patching gtk theme engine (builtin murrine)..."
    patch -p1 < /src/u-gtk/gtkthemes-builtin-murrine.patch || { log "THEME PATCH FAILED"; exit 1; }
    patch -p1 < /src/u-gtk/gtk2-2.24.33-lxtask-static.patch || { log "GTK PATCH FAILED"; exit 1; }
    patch -p1 < /src/u-gtk/gtk2-2.24.33-printbackends-static.patch || { log "PRINTBACKEND PATCH FAILED"; exit 1; }
    patch -p1 < /src/u-gtk/gtkbuilder-static-types.patch || { log "GTKBUILDER PATCH FAILED"; exit 1; }
    args="--disable-option-checking \
      --disable-FEATURE  \
      --disable-silent-rules \
      --disable-dependency-tracking \
      --enable-fast-install=yes \
      --disable-libtool-lock  \
      --disable-largefile  \
      --disable-maintainer-mode \
      --enable-shm=no \
      --enable-xkb=yes \
      --enable-xinerama=no \
      --disable-rebuilds \
      --disable-visibility \
      --enable-explicit-deps=no \
      --disable-glibtest    \
      --disable-modules     \
      --disable-cups \
      --disable-papi \
      --enable-introspection=no \
      --enable-gtk-doc=no \
      --enable-gtk-doc-html=no \
      --enable-gtk-doc-pdf=no \
      --enable-man=no"
      # --enable-static=yes \
      # --enable-shared=no \
    # export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
    export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
    ./autogen.sh 
    # --enable-xkb=yes \ #no>yes
    # 2026-11-04: 内置 XIM(输入法)走 --with-included-immodules=xim → libstatic-im-xim + -DINCLUDE_IM_xim,
    # 静态下无需 dlopen(实测 3.5.1)。注意 args1 是死代码(从未定义), 参数必须真传这里, 别塞进 args= 块。
    ./configure --enable-static \
      --with-included-immodules=xim \
      --prefix=/usr

  log "Compiling gtk..."
    # make -j$(nproc) #gtk全部构建>> build.sh pcmanfm>> 生成pcmanfm静态文件成功
    # 
    # retry2
    make -j$(nproc) -C gdk & #first
    make -j$(nproc) -C gtk &
    wait
    find |egrep "g.*k-x11.*\.a$"
    [ -f ./gtk/.libs/libgtk-x11-2.0.a ] || { log "libgtk-x11-2.0.a MISSING"; exit 1; }

  log "Building murrine theme engine (static)..."
    MURRINE_GIT="${MURRINE_GIT:-https://ghfast.top/https://github.com/jlindgren90/murrine.git}"
    rm -rf /tmp/murrine; git clone --depth=1 "$MURRINE_GIT" /tmp/murrine
    ( cd /tmp/murrine && unset LDFLAGS; ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) )
    [ -f /tmp/murrine/.libs/libmurrine.a ] || { log "MURRINE build FAILED"; exit 1; }
    ar r ./gtk/.libs/libgtk-x11-2.0.a /tmp/murrine/*.o
    log "Merged murrine into ./gtk/.libs/libgtk-x11-2.0.a"
  log "Building pixmap theme engine (static)..."
    make -C modules/engines/pixbuf || { log "PIXMAP build FAILED"; exit 1; }
    ar r ./gtk/.libs/libgtk-x11-2.0.a modules/engines/pixbuf/*.o
    log "Merged pixmap engine into ./gtk/.libs/libgtk-x11-2.0.a"
  gtk_ibus_a2
  log "Print backends (file/lpr) built via Makefile.am sources..."
    # gtk2-2.24.33-printbackends-static.patch: ①改 gtkprintbackend{file,lpr}.c 的
    # pb_module_* → _gtk_print_backend_{file,lpr}_*（对齐 gtkprintbackend.c builtin 表）；
    # ②把两个 .c 加进 gtk/Makefile.am 的 gtk_os_unix_c_sources → make -C gtk 自然编进
    # libgtk-x11-2.0.a。替代旧 objcopy --redefine-sym + 手动 ar r（不正规，2026-11-05 复盘）。
    # 此段无需任何手动编/合并，产物检查靠下方 [ -f ... ] + xx-verify。
    # ./gdk/.libs/libgdk-x11-2.0.a
    # ./gtk/.libs/libgtk-x11-2.0.a
    # ./gdk/x11/.libs/libgdk-x11.a
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a 
    # -rw-r--r--    1 root     root        5.0M Dec  1 17:12 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root       33.2M Dec  1 17:14 ./gtk/.libs/libgtk-x11-2.0.a
    # with args lite?
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a 
    # -rw-r--r--    1 root     root        1.1M Dec  1 17:52 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.6M Dec  1 17:56 ./gtk/.libs/libgtk-x11-2.0.a
    # without args
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a
    # -rw-r--r--    1 root     root        1.2M Dec  1 18:26 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.9M Dec  1 18:33 ./gtk/.libs/libgtk-x11-2.0.a
    # make -j$(nproc) #根目录下构建; >> build.sh pcmanfm>> 生成静态文件ok
    # # bash-5.1# ls -lh ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a
    # -rw-r--r--    1 root     root        1.2M Dec  1 18:56 ./gdk/.libs/libgdk-x11-2.0.a
    # -rw-r--r--    1 root     root        8.9M Dec  1 19:05 ./gtk/.libs/libgtk-x11-2.0.a

  log "Installing gtk..."
    # make[3]: *** [/usr/share/gobject-introspection-1.0/Makefile.introspection:156: Gdk-2.0.gir] Error 1
    # make install  #make, make install err:>> 不影响静态库的生成 及安装到/usr/local/lib/libgdk_pixbuf-2.0.a
    # find /usr/local/lib |egrep "g.*k-x11.*\.a$"
    # cp /usr/local/lib/libgdk-x11-2.0.a /usr/local/lib/libgtk-x11-2.0.a /usr/lib/

    # ./gdk/x11/.libs/libgdk-x11.a 
    \cp -a ./gdk/.libs/libgdk-x11-2.0.a ./gtk/.libs/libgtk-x11-2.0.a /usr/lib/
}


function apkdeps(){
  apk update; 
      # menu-cache-dev \
  apk add gtk-doc shared-mime-info \
    gobject-introspection-dev \
    \
    gtk-doc intltool vala \
      gtk+2.0-dev \
    \
    fontconfig-static libxcomposite-dev #pcmanfm
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    echo "emp";
    ;;
b_deps)
    bash /src/openbox/build.sh apkdeps
    bash /src/openbox/build.sh pango & ##needed by gtk
    bash /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    bash /src/xcompmgr/build.sh Xdamage &
    STATIC=yes bash /src/w-tint2/build.sh libcroco & #librsvg 前置，复用 w-tint2 脚本
    wait
    # 
    apkdeps
    STATIC=yes bash /src/w-tint2/build.sh librsvg & #librsvg > libcroco；STATIC=yes 只出 .a
    bash /src/u-gtk/build.sh atk & #needed by gtk
    wait
    bash /src/u-gtk/build.sh gdk-pixbuf #needs librsvg (svg loader)
    bash /src/u-gtk/build.sh gtk

    # view
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk" |grep "\.a$" |sort #|libfm|menu-cache
    ;;
*) #compile
    oneBuild $1
    ;;          
esac
exit 0
