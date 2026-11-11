#!/bin/sh
set -e
source /src/common.sh
export DOEXEC_CALLER="${DOEXEC_CALLER:-u-gtk}"

# 静态库链装在 /usr/local，其 .pc 也在 /usr/local/lib/pkgconfig；Alpine pkgconf 默认不含该路径
# → 前置 PKG_CONFIG_PATH，让 librsvg configure 能找到组1 新装的 libcroco-0.6.pc（gdk-pixbuf/atk 同理，供 gtk 用）。
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

function atk(){ ##@meson
  # apk update; apk add gobject-introspection-dev

  log "Downloading atk..."
  branch="--branch=ATK_2_35_1" #ATK_2_36_0  [2.35.1@ubt2004; 2.36.0@alpine315]
  branch="--branch=ATK_2_36_0"
  # 源码源切到 gitee 镜像: GNOME/atk 仓库已归档消失(github 404), 改由 g-system/fk-atk 提供 (tag ATK_2_36_0)
  rm -rf /tmp/atk; git clone --depth=1 $branch https://gitee.com/g-system/fk-atk /tmp/atk
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
  # 源码源切到 gitee 镜像 g-system/fk-gdk-pixbuf (tag 2.42.8 镜像内已确认)
  rm -rf /tmp/gdk-pixbuf; git clone --depth=1 $branch https://gitee.com/g-system/fk-gdk-pixbuf /tmp/gdk-pixbuf
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
  git config --global --add safe.directory "$IBUS" 2>/dev/null || true
  [ -f "$IBUS/client/gtk2/.libs/im_ibus_la-ibusim.o" ] || { log "A2 SKIP: ibus module objects NOT found ($IBUS)"; return 0; }
  [ -f "$IBUS/src/.libs/libibus-1.0.a" ] || { log "A2 SKIP: libibus-1.0.a NOT found ($IBUS)"; return 0; }
  log "A2: merge ibus im module -> ./gtk/.libs/libgtk-x11-2.0.a (IBUS=$IBUS)"
  rm -rf "$OBJ"; mkdir -p "$OBJ"; cd /tmp/gtk
  # 1) gtkimmodule.c: 加 INCLUDE_IM_ibus do_builtin(ibus)
  grep -q "do_builtin (ibus)" gtk/gtkimmodule.c || patch -p1 < /src/u-gtk/gtk-ibus-builtin.patch || { log "A2 gtk patch FAILED"; exit 1; }
  # 2) 重编 gtkimmodule.o (继承配置宏 + INCLUDE_IM_ibus)
  # 2b) 强制源文件比 .o 新: 主 build 刚把对象编到最新, make -n 不打印命令 → touch 保证捕获到
  touch gtk/gtkimmodule.c
  local CMD; CMD=$(make -n -C gtk gtkimmodule.lo 2>/dev/null | grep -m1 "mode=compile")
  CMD=$(printf '%s' "$CMD" | sed -n 's#^.* xx-clang #xx-clang #p')
  CMD=$(printf '%s' "$CMD" | sed "s#-o gtkimmodule\.lo#-o $OBJ/gtkimmodule.o#; s#-DINCLUDE_IM_xim#-DINCLUDE_IM_xim -DINCLUDE_IM_ibus#")
  [ -n "$CMD" ] || { log "A2 FAIL: gtkimmodule compile cmd NOT captured"; exit 1; }
  ( cd /tmp/gtk/gtk && eval "$CMD" ) || { log "A2 FAIL: gtkimmodule.o compile"; exit 1; }
  # 3) glue: im_module_* -> _gtk_immodule_ibus_*
  xx-clang $(pkg-config --cflags gtk+-2.0) -c /src/u-gtk/ibus-builtin-glue.c -o "$OBJ/ibus-builtin.o" || { log "A2 FAIL: glue compile"; exit 1; }
  # 4) ibusim.o: 守卫补丁 + -DINCLUDE_IM_ibus 重编
  grep -q "#ifndef INCLUDE_IM_ibus" "$IBUS/client/gtk2/ibusim.c" || patch -d "$IBUS" -p1 < /src/u-gtk/ibus-ibusim-gmodule-check-init.patch || { log "A2 ibusim patch FAILED"; exit 1; }
  local IBCMD; IBCMD=$(make -n -C "$IBUS/client/gtk2" im_ibus_la-ibusim.lo 2>/dev/null | grep -m1 "mode=compile")
  IBCMD=$(printf '%s' "$IBCMD" | sed -n 's#^.* gcc #gcc #p')
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

# 增量应用 patch: 内容 hash 未变则跳过(文件 mtime 保持 → make 复用 .o);
# 变更则先 git checkout 还原触及文件到 HEAD, 再重打(新 mtime → 只重编这些 .o)。
# 依赖 gtk() 设置的 PATCHDIR / STATEDIR 全局。
function inc_patch(){
  local name="$1" files="$2"
  local pf="$PATCHDIR/$name"
  local h; h=$(sha256sum "$pf" 2>/dev/null | cut -d' ' -f1)
  [ -n "$h" ] || { log "inc_patch: $name MISSING ($pf)"; exit 1; }
  local prev; prev=$(cat "$STATEDIR/$name.sha" 2>/dev/null || true)
  if [ "$prev" = "$h" ]; then log "inc_patch: $name unchanged (skip)"; return 0; fi
  log "inc_patch: $name changed -> reset+apply"
  for f in $files; do git checkout --force -- "$f" 2>/dev/null || true; done
  patch -p1 < "$pf" || { log "PATCH FAILED: $name"; exit 1; }
  mkdir -p "$STATEDIR"  # fresh clone 后目录被 rm -rf 删; 写前再保证(见 gtk() clone 后 mkdir)
  echo "$h" > "$STATEDIR/$name.sha"
}

function gtk(){
  # apk update; apk add gtk-doc shared-mime-info

  log "Preparing gtk source tree..."
  branch="--branch=2.24.33"
  local GTK=/tmp/gtk
  local PATCHDIR="${PATCH_DIR:-/src/u-gtk}"
  local SIGFILE="$GTK/.u-gtk-config.sig"
  local STATEDIR="$GTK/.u-gtk-state"
  mkdir -p "$STATEDIR"
  # 安全目录: 树可能由外部(host/另一容器)拷贝进来, 属主非 root, git 拒绝操作。
  git config --global --add safe.directory "$GTK" 2>/dev/null || true
  # ① 源码树缓存: 已有完整配置的树则复用(增量), 否则全新 clone。
  #    复用判定需 .git(能 checkout 还原) + config.status(已 configure 过)。
  #    当前 broken 状态(无 .git 或半成品)会被丢弃重 clone。
  if [ -d "$GTK/.git" ] && [ -f "$GTK/config.status" ]; then
    log "Reuse /tmp/gtk source tree (incremental)"
    cd "$GTK"
  else
    log "Fresh clone gtk (no usable cache)"
    # 源码源切到 gitee 镜像 g-system/fk-gtk (tag 2.24.33 镜像内已确认; 默认分支 main 为 gtk4, 必须按 tag 拉)
    rm -rf "$GTK"; git clone --depth=1 $branch https://gitee.com/g-system/fk-gtk "$GTK"
    cd "$GTK"
  fi
  mkdir -p "$STATEDIR"  # fresh clone 的 rm -rf 会删掉 .u-gtk-state, clone 后重建; 增量则幂等
  # ② patch 增量: 按 patch 内容 hash 判定是否变更; 变更才 reset+重打(只重编该 patch
  #    触及的 .o), 未变则跳过(文件 mtime 保持 → make 时间戳增量复用 .o)。
  #    .libs/*.o、Makefile、config.status 是 untracked 生成物, 不受 checkout 影响。
  log "Applying gtk patches (incremental)..."
    inc_patch gtkthemes-builtin-murrine.patch "gtk/gtkthemes.c"
    inc_patch gtk2-2.24.33-lxtask-static.patch "gtk/gtkmain.c gtk/gtkmodules.c gtk/gtkprintbackend.c modules/engines/pixbuf/pixbuf-main.c"
    inc_patch gtk2-2.24.33-printbackends-static.patch "gtk/Makefile.am modules/printbackends/file/gtkprintbackendfile.c modules/printbackends/lpr/gtkprintbackendlpr.c"
    inc_patch gtkbuilder-static-types.patch "gtk/gtkbuilder.c"
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
    CONFIG_ARGS="--enable-static --disable-shared --with-included-immodules=xim --prefix=/usr"  # --disable-shared: 项目只要 .a; 原默认建 .so 在 murrine/pixmap merge 前链接 → theme_* undefined
    # ③ configure 缓存: 参数 + Makefile.am 补丁未变 → 跳过 configure (省 ~5min)。
    #    Makefile.am 补丁(printbackends)变更才需重新生成 Makefile.in; 只改 .c 的补丁不需要。
    local SIG=$( { cat "$PATCHDIR/gtk2-2.24.33-printbackends-static.patch"; echo "$CONFIG_ARGS"; } | sha256sum | cut -d' ' -f1 )
    if [ -f config.status ] && [ "$(cat "$SIGFILE" 2>/dev/null)" = "$SIG" ]; then
      log "Skip configure (args + Makefile.am patch unchanged)"
    else
      ./autogen.sh
      # 2026-11-04: 内置 XIM(输入法)走 --with-included-immodules=xim → libstatic-im-xim + -DINCLUDE_IM_xim,
      # 静态下无需 dlopen(实测 3.5.1)。注意 args1 是死代码(从未定义), 参数必须真传这里, 别塞进 args= 块。
      ./configure $CONFIG_ARGS
      echo "$SIG" > "$SIGFILE"
    fi

  log "Compiling gtk..."
    # make -j$(nproc) #gtk全部构建>> build.sh pcmanfm>> 生成pcmanfm静态文件成功
    # 
    # retry2
    # 2026-11-11: 串行——原并行(gdk & gtk)无依赖协调, gtk 会先于 gdk 生成 gdkenumtypes.h
    # → fatal error: gdk/gdkenumtypes.h not found (可恢复但报错刷屏); 先 gdk 完(生成头)再 gtk 彻底避免。
    # 2026-11-11: 只建库目标(.la→.a), 不建工具(gtk-query-immodules-2.0/g-ir-scanner 临时可执行
    # 会静态链 .a, 而 .a 的 gtkthemes.o 引用 theme_*(murrine/pixmap) 尚未 merge → undefined reference;
    # 项目只要 .a, 工具无需构建。库目标依赖含 gdkenumtypes.h 生成。
    # || log 容忍部分失败(如 .so 目标), 真正门在下方 [ -f .a ] 检查。
    make -j$(nproc) -C gdk libgdk-x11-2.0.la || log "gdk make rc=$? (partial, .a checked below)"
    make -j$(nproc) -C gtk libgtk-x11-2.0.la || log "gtk make rc=$? (partial, .a checked below)"
    find |egrep "g.*k-x11.*\.a$"
    [ -f ./gtk/.libs/libgtk-x11-2.0.a ] || { log "libgtk-x11-2.0.a MISSING"; exit 1; }

  log "Building murrine theme engine (static)..."
    # 源码源切到 gitee 镜像 g-system/fk-murrine (master); 环境变量 MURRINE_GIT 仍可覆盖
    MURRINE_GIT="${MURRINE_GIT:-https://gitee.com/g-system/fk-murrine}"
    # ④ murrine 缓存: 已有构建树则复用, make 增量; 否则全新 clone+configure。
    git config --global --add safe.directory /tmp/murrine 2>/dev/null || true
    if [ -d /tmp/murrine/.git ] && [ -f /tmp/murrine/config.status ]; then
      log "Reuse /tmp/murrine (incremental)"
      ( cd /tmp/murrine && unset LDFLAGS; make -j$(nproc) )
    else
      rm -rf /tmp/murrine; git clone --depth=1 "$MURRINE_GIT" /tmp/murrine
      ( cd /tmp/murrine && unset LDFLAGS; ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) )
    fi
    [ -f /tmp/murrine/.libs/libmurrine.a ] || { log "MURRINE build FAILED"; exit 1; }
    ar r ./gtk/.libs/libgtk-x11-2.0.a /tmp/murrine/*.o
    log "Merged murrine into ./gtk/.libs/libgtk-x11-2.0.a"
  log "Pixmap theme engine (builtin via Makefile.am source, no separate make/ar r)..."
    # 2026-11-11: pixbuf engine 改为编进 libgtk——printbackends-static.patch 的 gtk/Makefile.am
    # 已加 modules/engines/pixbuf/pixbuf-draw.c+pixbuf-main.c 到 gtk_os_unix_c_sources, make -C gtk
    # 自然编进 libgtk-x11-2.0.a(提供 pixmap_theme_* 符号, gtkthemes-builtin-murrine.patch 已 extern 声明;
    # pixbuf-main.c 的 theme_*→pixmap_theme_* 改名由 lxtask-static.patch 完成, 免与 murrine 冲突)。
    # 替代旧独立 make -C modules/engines/pixbuf + ar r merge(同 printbackends 复盘, 弃 ar r 魔改)。
    # 产物检查仍靠下方 [ -f .a ] + xx-verify。
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
    fontconfig-static libxcomposite-dev \
    gdk-pixbuf-dev pango-dev # librsvg configure 需 gdk-pixbuf-2.0/pangocairo/pangoft2 .pc；gtk+2.0-dev 未传递装这两个（实测 MISS）
  # 注: gtk-doc 提供 gtkdocize, 供 w-tint2 的 libcroco autogen.sh 用 (b_deps 组1 前已装)。
}

case "$1" in
cache)
    # down_catfile ${XRDP_URL} > /dev/null
    ;;
full)
    echo "emp";
    ;;
b_deps)
    doExec apkdeps   # u-gtk 的 apkdeps 放最前: 含 gtk-doc(gtkdocize), 供组1 libcroco autogen.sh 用
    doExec /src/openbox/build.sh apkdeps   # openbox 依赖(静态库链); 不动
    doExec_mark "group1: pango libxrandr Xdamage libcroco"   # 组边界: 留痕不清, check 只读本组
    doExec /src/openbox/build.sh pango & ##needed by gtk
    doExec /src/openbox/build.sh libxrandr & #same: x-xrdp/build.sh
    doExec /src/xcompmgr/build.sh Xdamage &
    STATIC=yes doExec /src/w-tint2/build.sh libcroco & #librsvg 前置，复用 w-tint2 脚本
    wait
    doExec_check || exit 1   # 并发组1 错误码识别: 任一失败即退出
    doExec_mark "group2: librsvg atk"   # 组边界: 留痕不清, check 只读本组
    STATIC=yes doExec /src/w-tint2/build.sh librsvg & #librsvg > libcroco；STATIC=yes 只出 .a
    doExec /src/u-gtk/build.sh atk & #needed by gtk
    wait
    doExec_check || exit 1   # 并发组2 错误码识别
    doExec /src/u-gtk/build.sh gdk-pixbuf #needs librsvg (svg loader)
    doExec /src/u-gtk/build.sh gtk

    # view
    find /usr/lib |egrep "libpango|Xrandr|Xdamage|libatk|pixbuf|libgdk|libgtk" |grep "\.a$" |sort #|libfm|menu-cache
    ;;
*) #compile
    oneBuild $1   # 去嵌套 doExec: oneBuild 自处理日志+退出码, 失败由 set -e 捕获
    ;;          
esac
exit 0
