# ci-builder-gtkmm-lib：gtkmm 编译缺依赖修复与评估（2026-11-15 拆出）

2026-11-15 自 `docs/2026/11091127-ci-builder-gtk.md` 三章 5 节整拆，层级上调一级（`5.x→x`、`5.x.x→x.x`、`5.x.x.x→x.x.x`）。
内容为 gtkmm 编译缺依赖修复（c_gtkmm 覆盖 GTKMM_LIBS + librsvg `.la` 循环依赖处理）与 tarsrc 复用、影响面评估、问答三连的完整记录。

## 章节表

- 一、gtkmm 编译缺依赖修复与评估（原 5 节，2026-11-15 拆出）
  - 0、最近两天（11-13~11-15）整体变化主题（原 5.0）
  - 1、方案A 落地后 gtkmm 编译缺依赖分析与 tarsrc 复用（2026-11-15，原 5.1）
  - 2、w-tint2 librsvg .la 修复的影响面评估（2026-11-15，原 5.2，先评估未开工）

## 一、gtkmm 编译缺依赖修复与评估

### 0、最近两天（11-13~11-15）整体变化主题

#### 0.1、gitclone 机制（`compile/src/common.sh`，11-13/11-14）

- 本地缓存 clone（tarsrc-git，宿主预克隆 gitee/github 仓库）规避 gitee/github 抖动（Connection reset / Failure receiving data）致 b_deps 依赖未就位。
- tar.gz 快照缓存（`_cache_repo/`，含 `.git`，包名带组件前缀）；优先级 **GITCACHE > tar.gz 快照 > 网络 clone**；`safe.directory` 全局 `*`（git>=2.35.2 通配）。
- cachesrc 日志：`/usr/local/static/.logs/cachesrc/<name>.log`，表头（时间|组件|包|大小|缓存命中|耗时|来源|ver|url|路径），hit 标识统一小写 `gitcache|tarsrc|net|net-fail`，耗时毫秒（`/proc/uptime`，busybox date 无 %N）。
- **18 个 build.sh 的裸 `git clone` 全量替换 `gitclone`**（`--branch` 移第三参；不换源；无残留裸 clone 可执行）。

#### 0.2、doExec 适配（11-13）

- 17 个 build.sh 应用 `doExec` + `|| exit 1`，b_deps 并行组 `doExec_mark/check`，入口设 `DOEXEC_CALLER=<comp>`（预防，full 无调用）。
- `doExec_mark` 补 mkdir `.logs/doExec/<caller>`——并发组边界首 doExec 前子目录未建致 `_exec_result.txt can't create`。
- `STATIC=yes` 前缀 env 不传子进程坑 → 改 `doExec env STATIC=yes bash ...`；日志目录 `/tmp/doExec` 并入 `.logs/doExec/`。

#### 0.3、u-gtk 库层根治（gdk_pixbuf svg loader，11-14）

- `-Dbuiltin_loaders=png,jpeg,svg`（patch choices 已加 svg 但默认 value 不含，须显式传）+ `--default-library=static`（避 non-PIC 重定位）+ 禁 introspection（临时二进制缺依赖致 ninja 停滞）。
- `librsvg-2.0.pc` Requires.private 补全（pangocairo/libxml-2.0/libcroco-0.6，svg loader 未编入第 2 层根因）；`gdk-pixbuf-2.42.8-lxtask-static.patch` 依赖加 `static: true`。
- 方案A 库层注册根治：`io.c` 导出 `gdk_pixbuf_io_init_builtin`（去 static+幂等 guard）+ `io.h` 声明 + `gdk-pixbuf.c get_type` 调用注册 → 应用**无需 `-u`**（lxtask 去双 `-u`，图标打叉修复；hdmi 实跑用户确认正常）。
- `u-gtk/build.sh` gdk_pixbuf 单目标编译（`libgdk_pixbuf-2.0.a`）+ 手动 cp 到 `/usr/local/lib`+`/usr/lib`，绕开 builtin 外 loader 的 `.so` 共享模块链接（non-PIC cairo/intl → R_X86_64_TPOFF32/PC32 12 连败刷屏）；install 兜底（build 目录无 .a 时 cp，模拟 CI 干净环境验证）。

#### 0.4、组件构建收口（各 build.sh，11-13~11-15）

- **geany**：CI 干净树先编 scintilla/tagmanager 子目录（`No rule to make target ../scintilla/libscintilla.la`）；`libtagmanager.la`→`../ctags/libctags.la` 补 ctags 前置；static-link 前 `mkdir -p $TARGETPATH/bin`（cannot open output file geany）；`bin_PROGRAMS=` 跳过非核心工具（工具动态链 libgtk .so 链接失败根源）；静态链改 `xx-clang++ -static` 直链（libtool 破坏 `-lrsvg-2` group）。
- **pcmanfm/libfm**：`--disable-shared` 消 .so 链（gmodule 坑）+ `make -k` 容忍工具失败 + 手动 cp `.a` + menu_cache 头软链（`/usr/include/libfm`）；`bin_PROGRAMS=`（libfm-pref-apps/lxshortcut 动态链失败致 make install 中断→头/.pc 未装，手动平铺拷 88 头+3 .pc）；make install 加 `pkglib_LTLIBRARIES=` 跳过 src/modules 共享模块（vfs-menu/gtk-menu-actions/trash `-module -shared` 强制共享→`--disable-shared` 下 libtool `func__fatal_error` 模板混配）；libfm 链接补 gdk_pixbuf loader 依赖（`-lgmodule-2.0 -ljpeg -lpng -lrsvg-2 -lcroco-0.6 -lxml2 -llzma`）。
- **rofi**：子工程取固定提交 d86f990/2f220a4（非 master，修'Subproject exists but has no meson.build'嵌套）；b_deps 装 libxkbcommon-dev+static（缺 xkbcommon→libnkutils disabler→meson 0.59 静默丢 rofi 目标真因）；pkgconfig 包装器无 `.a` 的 `-l` 丢弃（免拉动态 .so 踢 zstd）+ 安全网补 librsvg/croco/xml2（io-svg rsvg_handle_*）；get_src 加 tarsrc 缓存。产物 rofi 9.3M static xx-verify PASS。
- **engrampa**：autogen 前置 mate-common/yelp-tools/itstool（缺则 autogen 静默失败无 configure）；schema 编入（`-DENG_SCHEMA_DIR="..."` 改 `-include` 头文件法，引号被 make recipe shell 剥掉→`use of undeclared identifier 'usr'`）；LIBTOOL=true 坑（令 `--mode=compile` 空操作→.o 缺失）；去 LIBTOOL=true 使 objects 段正常编译；补装 GSettings schema（org.mate.engrampa.listing 缺失 GLib-GIO-ERROR 崩溃）。
- **dunst**：DUNST_LIBS 剔 `-lzstd`（镜像无 libzstd.a→cannot find -lzstd，同 gpicview/w-feh 先例）；下载改 down_catfile（tarsrc 缓存命中）+ tarsrc 缓存包兜底（github 瞬时 404 不直接挂）。
- **w-tint2**：librsvg `.pc` Requires 补全（svg loader 未编入第 2 层根因）；xcbutil m4 submodule 修复（CI 构建上下文无 tarsrc-git，原无条件 sed→submodule/cp 全失败；改缓存存在才 sed+cp，无缓存原始 URL+回落 gitee g-system/util-common-m4 镜像）。

#### 0.5、imlib2 注入版（w-xlunch，11-15）

- `imlib2()` 尾部注入版覆盖 `/usr/local/lib/libImlib2.a`——base 烘焙后 5 个 w-xxx 裸 `-lImlib2` 即取注入库（免逐 app 改 -L；注入符号实测 6）。
- 5 应用（feh36.5/scrot9.7/hsetroot9.7/tint2 10.1/xlunch36.1）全 static + xx-verify PASS；feh/xlunch nm 直证注入符号。

#### 0.6、文档拆分（11-15）

- `11140827-ci-builder-gtk-lib.md`（gtk2 库层与 imlib2 依赖适配，自 11120827-ci-builder-gtk-app-rootfs.md 五章 5/6 节上调一级重排：5.1→1、5.1.x→1.x、6.1.x→2.1.x；18 处交叉引用同步）。
- `11130827-ci-builder-tarsrc.md`（xfce4 源码包收集与下载源，自 11110827-ci-builder-gtk-app.md 六章拆出，保留原层级）。
- `11120827-ci-builder-gtk-app-rootfs.md`（CI实跑验证与 rootfs 图标排查，自 11110827-ci-builder-gtk-app.md 五章拆出，注明来处）。

#### 0.7、构建环境规则（AGENTS.md，11-15）

- 基准改 `alpine-builder-gtk224-2` 镜像按需 pull 起容器（像 awe 跑法）/`/src` 软链/Dockerfile 调用方式；**禁止 builder-awe/obox**（原规则过时）。
- setsid 直拼命令法（不再写脚本文件 t_xx.sh，命令内容直拼 `setsid bash -c '...'` 后台跑，结果写 `/_ext/tmp` 中转轮询 DONE）；docker exec 回执被回收坑；容器→宿主文件中转强制规则（统一 sudo 写 `/_ext/tmp`(777)、失败重试+拆命令、禁止 docker export）。

#### 0.8、本次拉取（11-15，7 commit / 净 2 文件）

- `.github/workflows/docker-image-x11-base.yml`：注释掉 `bash buildx.sh gtk224 #builder-gtk224`（CI gtk224 构建 job 停用）。
- `compile/src/common.sh` oneBuild：产物清单 `find $TARGETPATH -type f |sort` 全量 → `grep -E "/bin|/sbin" |sort |head -3`（日志降噪，只显 3 条产物）。

### 1、方案A 落地后 gtkmm 编译缺依赖分析与 tarsrc 复用（2026-11-15）

#### 1.1、问题：一章3节落地后 gtkmm 编译缺依赖（CI gtkmm224 buildx 失败）

- 现象：`u-gtkmm/build.sh full` 的 gtkmm 阶段 `tools/extra_defs_gen/generate_extra_defs` 链接失败——
  `/usr/lib/libgdk_pixbuf-2.0.a(io-png.c.o): undefined reference to 'png_read_end@@PNG16_0'` → make 中断 →
  库不落地（`cp: can't stat ''`）→ verify 缺 `libgdkmm-2.4.a`/`libgtkmm-2.4.a`。
- 根因链：
  1. **一章3节方案A**（`gdk_pixbuf_io_init_builtin` 注册挪入 gdk-pixbuf.c.o）后，`libgdk_pixbuf-2.0.a` 的
     `io-png/io-jpeg/io-svg` 被**整链拉入**——凡链 gdk-pixbuf 的程序/工具都需补 `-lpng16/-ljpeg/-lrsvg-2` 等 loader 依赖；
  2. gdkmm 构建期工具 `generate_extra_defs` 链接 **`$(GTKMM_LIBS)`**（`tools/Makefile.am:29`），而 GTKMM_LIBS 由 configure
     `PKG_CHECK_MODULES([GTKMM],[atkmm giomm pangomm gtk+-2.0 gtk+-unix-print-2.0])` 取 **pkg-config 非 static** 值——
     `pkg-config --libs gtk+-2.0` **不展开 Requires.private** → 不含 `-lpng16/-ljpeg/-lrsvg-2`；
  3. → `generate_extra_defs` 链 `libgdk_pixbuf-2.0.a` 时 `io-png` 引 `png_read_end` 未定义。
- 验证事实（builder-g224 探针）：`/usr/lib/libgdk_pixbuf-2.0.a`=1061240B 含 `U png_read_end`（1 处）；
  `pkg-config --libs gdk-pixbuf-2.0`=`-lgdk_pixbuf-2.0 -lgobject-2.0 -lglib-2.0 -lintl`（**无 -lpng16**）；
  `pkg-config --static --libs` 含 `-lpng16 -lz -ljpeg -ltiff -lwebp -lzstd -llzma -lgmodule-2.0`；libpng 在 `/usr/lib/libpng16.a`。

#### 1.2、首轮修复（c_gtkmm 覆盖 GTKMM_LIBS）与实跑结果

- 修复（`compile/src/u-gtkmm/build.sh` `c_gtkmm`）：make/make install 传
  `GTKMM_LIBS="$(pkg-config --libs atkmm-1.6 giomm-2.4 pangomm-1.4 gtk+-2.0 gtk+-unix-print-2.0) -lpng16 -ljpeg -lz -llzma -lzstd -lgmodule-2.0 -lrsvg-2 -lcroco-0.6 -lxml2"`
  （保留 configure 同款模块集非 static + 追加 loader 依赖；**不用整包 `--static`**——会展开出无 `.a` 的库如 cups/Xi → cannot find -l）。
- 实跑（builder-g224，nproc=2 串行，full 全栈）：mm-common→libsigc++→glibmm→cairomm→pangomm→atkmm→gtkmm 到 gtkmm 阶段，
  **RC=1**，错误**变**为 `io-svg.c` 的 `rsvg_handle_close/new/get_pixbuf/set_size_callback/write/error_quark` undefined
  （`-lrsvg-2` 已加仍未解析）。
- 结论：首轮修复消除了 `png_read_end`，但 **`-lrsvg-2` 未生效**——需看 `generate_extra_defs` 实际链接命令
  （`make -n`/`libtool -v`；AGENTS 3.5③ 教训：别凭库路径猜）。

#### 1.3、tarsrc 复用（gtkmm 栈源码包缓存）

- 背景：gtkmm 栈源码（mm-common/libsigc++/glibmm/cairomm/pangomm/atkmm/gtkmm 7 包）每次走 GNOME 网络下载；
  tarsrc（`compile/tarsrc`，gitee x11base-tarsrc）原本**无 u-gtkmm 目录**（README 仅 13 组件/31 包）。
- 手动下载 7 包到 `compile/tarsrc/u-gtkmm/`（GNOME 原始名；`gtkmm-2.24.5` 首次截断 7.9M 损坏，重下 12M OK；其余 tar 完整）。
- README 更新（14 组件/38 包/约 48.7M；u-gtkmm 表行 7 条 + 归属说明）。
- **分开提交**（用户要求）：包 `a871f71`、文档 `54b7cc8`；推送 gitea `prs`（`sam-dev.local:3000/g-dev1/x11base-tarsrc`，
  `88d589c..54b7cc8`；gitee origin 需认证失败）。
- **复用缺口**：`u-gtkmm/build.sh` `fetch()` 只查 `/tmp/gtkmm-stack`，否则 `down_catfile` 网络；
  `down_catfile` 查 tarsrc 需 `TARGETPATH` 非空（u-gtkmm 装 `/usr/lib` 未设）→ 当前**不命中** `tarsrc/u-gtkmm/`。
  要复用需改 `fetch()` 加 tarsrc 命中（`/src/../tarsrc/u-gtkmm/<包>` 存在则解包，否则回落网络；CI 构建上下文无 tarsrc 自动回落）。
- 容器验证用源码：7 包已放 `/tmp/gtkmm-stack/`（builder-g224）；下载速度：`glibmm-2.48.1` 34s(≈180KB/s)、
  `gtkmm-2.24.5` 23s(≈520KB/s)、`pangomm-2.40.0` 一次 SSL(rc=35) 重试成功。

#### 1.4、下一步

- ~~深查 rsvg 链接~~ → 已闭环见 1.5（builder-g224 手动验证 libtool 链接通过）。
- 重新跑 full 完整验证（容器 `librsvg/croco .la` 已手动修）——待做。
- 源头落地：`w-tint2/build.sh` `librsvg()` 构建后修 `.la`（清 .so 记录 + dependency_libs 去 `-lgdk_pixbuf-2.0`）——待做。
- 复用机制：改 `fetch()` 加 tarsrc 命中（或 `down_catfile` 对 u-gtkmm 生效）——待做。

#### 1.5、rsvg 根因闭环：ar 魔改致 rsvg↔gdk_pixbuf 循环依赖，libtool 无法排序（2026-11-15，兼容 libtool 修复已验证）

- 深查（`make -n` 实际链接命令）：`generate_extra_defs` 用 **`../libtool --mode=link`**（libtool 参与），
  覆盖的 `-lrsvg-2` **在命令里**，但 libtool 展开 `-lrsvg-2` → `/usr/local/lib/librsvg-2.so`
  （`.la` 的 `library_names`/`dlname` 记录 `.so` → libtool **优先 shared**；STATIC 构建清了 `.so` 文件但 `.la` 记录未清）。
- 修 `.la`（清 `library_names`/`dlname`）后 libtool 走 `.a`，但**仍 undefined**——顺序
  `librsvg-2.a ... -lgdk_pixbuf-2.0`：rsvg 仍在 gdk_pixbuf **前**（提供方在引用方前）。
- **根因（与 ar 魔改直接相关）**：
  1. u-gtk **ar 魔改**把 `io-svg` 塞进 `libgdk_pixbuf-2.0.a`（方案A）→ gdk_pixbuf 新增对 rsvg 的**反向依赖**；
  2. `librsvg-2.la` 的 `dependency_libs` 又声明 `-lgdk_pixbuf-2.0`（librsvg→gdk_pixbuf）→
     **rsvg↔gdk_pixbuf 循环依赖**；
  3. 标准 libtool **无法排序循环依赖** → 把 rsvg 排 gdk_pixbuf 前 → `io-svg.c` 引 `rsvg_handle_*` 时
     librsvg 已过 → undefined（贴 AGENTS 二章5节 AR 魔改盘点 + 三章3.5③ libtool 破坏）。
- **修复（兼容 libtool，不绕开）**：`librsvg-2.la`（+`libcroco-0.6.la`）：
  - 清 `library_names`/`dlname`（去 `.so` 记录，libtool 走 `old_library=.a`）；
  - `dependency_libs` 去 `-lgdk_pixbuf-2.0`（**librsvg 2.40 实际不依赖 gdk_pixbuf**，循环由该声明 + ar 魔改双造成）；
  - 删 `.so` 残留（`librsvg-2.so*`/`libcroco-0.6.so*`）。
- **验证**（builder-g224 手动）：修后 libtool -v 展开顺序变
  `-lgdk_pixbuf-2.0 ... -llzma -lzstd /usr/local/lib/librsvg-2.a ...`（引用方在前提供方在后），
  `/tmp/ged_test` 1MB 可执行**链接成功 undefined=0**。
- **落地**：源头改 `w-tint2/build.sh` `librsvg()`（STATIC 清 `.so` 处同步 sed 修 `.la`）；
  u-gtkmm `c_gtkmm` 的 GTKMM_LIBS 补 `-lrsvg-2` 等仍需保留（loader 依赖 + 单向排序才成立，两者缺一不可）。

#### 1.6、CI 第三轮（2026-11-16）：jpeg 版本符号 `@@LIBJPEG_8.0` 修复

- **现象**：CI gtkmm224 buildx 复跑，`generate_extra_defs` 链接报
  `libgdk_pixbuf-2.0.a(io-jpeg.c.o): undefined reference to 'jpeg_input_complete@@LIBJPEG_8.0'`
  （png/svg 已过——`-lpng16` 与 `.la` 剪环生效；jpeg 新挂）。
- **根因**：`generate_extra_defs` 是**动态链模式**（LDFLAGS `-Wl,--as-needed` 无 `-static`）→ ld 的 `-ljpeg`
  **默认优先 `libjpeg.so`**（带版本符号 `@@LIBJPEG_8.0`），CI 的 `.so` 版本符号与 `io-jpeg.o` 的无版本引用
  不匹配 → undefined。本地 builder-g224 模拟**未复现**（本地 `.so` 恰好匹配）→ 环境差异；`@@` 是动态库
  版本符号特有的失败形态（静态 `.a` 无版本符号不会踩）。
- **修复**（`compile/src/u-gtkmm/build.sh` `c_gtkmm`，commit `d901da8`）：`GTKMM_LIBS_EXTRA` 的 `-ljpeg`
  → **`/usr/lib/libjpeg.a`**（绝对路径 `.a` 无版本符号，天然规避 `.so` 版本差异；librsvg.la 展开残留的
  `-ljpeg` 因 io-jpeg 引用已被 `.a` 满足 → `--as-needed` 丢弃，安全）。
- **验证**：本地 `libtool -v` 模拟 RC=0（`/tmp/ged_ja` 1.6MB 生成）+ 完整 `u-gtkmm full` **RC=0**
  （全栈 8 库 + Verify 通过，无回归）。
- **三轮迭代收口**（png → rsvg → jpeg）：`-lpng16`（符号版本匹配）；`.la` 剪环（librsvg/croco 顺序）；
  jpeg 绝对路径 `.a`（`.so` 版本符号规避）。gtkmm 下游 gsm（gnome-system-monitor 2.28.2）在同环境
  `xx-clang++ -static` 直链 **18.7M 静态验证通过**（GTKMM_LIBS 覆盖无回归）。

### 2、w-tint2 librsvg .la 修复的影响面评估（2026-11-15，先评估未开工）


### 2、w-tint2 librsvg .la 修复的影响面评估（2026-11-15，先评估未开工）

#### 2.1、评估：对 u-gtk/build.sh 与其他依赖 rsvg 应用的影响（含表格）

**改动内容**（拟在 `w-tint2/build.sh librsvg()` 内落地）：

1. `librsvg-2.la` 清 `library_names`/`dlname`（去 `.so` 记录）→ libtool 走 `old_library=.a`
2. `librsvg-2.la` 的 `dependency_libs` 去 `-lgdk_pixbuf-2.0`（librsvg 2.40 不依赖 gdk_pixbuf）
3. 删 `.so` 残留（`librsvg-2.so*` / `libcroco-0.6.so*`）

**影响机制（关键）**：只有"libtool 链接且含 `-lrsvg-2`"的消费方会读 `.la`；直链（`xx-clang -static`）**不读 `.la`，零影响**。

**逐消费方评估**：

| 消费方 | 链接方式（build.sh 实证） | 影响 |
|---|---|---|
| u-gtk/build.sh | `gdk_pixbuf()` meson **只编 `.a` 不链可执行**（88 行 `--default-library=static` + introspection 禁用就是绕开 loader 工具链）；`gtk()` make 归档不链 bin | **无需改**；b_deps `STATIC=yes` 调 `w-tint2 librsvg`（386 行）→ **直接拿到修好的 `.la`，自动受益** |
| u-gtkmm（generate_extra_defs） | **libtool `--mode=link`，LDFLAGS 无 `-static`**（本次踩坑者） | **受益**：`.la` 修后走 `.a` + 单向排序；配合 `c_gtkmm` GTKMM_LIBS 补 `-lrsvg-2`（两者缺一不可） |
| geany / engrampa / pavucontrol / gpicview / pasystray / ibus / xfce4 | **`xx-clang -static` 手动直链**（各 build.sh 实证：geany 68 / engrampa 106 / pavucontrol 78 / gpicview 70-72 / pasystray 69 / ibus 235 / xfce4 118） | **零影响**（不读 `.la`，LIBS 自控顺序 + group，现状已验证过） |
| lxtask / lxappearance（v-lxde） | `make LDFLAGS`（3.5③ 实测 `$(CC)` 直链不踩 libtool） | **零影响** |
| pcmanfm（libfm） | `make -k LDFLAGS`（automake **libtool 但 `LDFLAGS` 含 common.sh 的 `-static`**） | **无回归**：本就走 `.a`；`.la` 去 `-lgdk_pixbuf-2.0` 后排序单向，LIBS 已显式含 gdk_pixbuf（85 行） |
| openbox | libtool 构建（78-79 行注释）但静态产物已 PASS | **无回归**（同上，`-static` 模式 + LIBS 显式全依赖） |

**结论**：

- **u-gtk/build.sh 无需调整**：自身无 libtool 链 `-lrsvg-2` 的点，且复用 w-tint2 修好的 `.la`
- **其他依赖 rsvg 的应用无需跟着改**：直链应用零影响；libtool `-static` 应用（pcmanfm/openbox）LIBS 已显式含 `-lgdk_pixbuf-2.0`，不依赖 `.la` 自动展开 → 无回归
- 影响面**集中在唯一 libtool 非-static 路径（gtkmm 构建期工具）**，正是本次修复目标
- 已验证：容器手动修 `.la` 后 `libtool -v` 模拟链接 `/tmp/ged_test` 成功（undefined=0）

**建议落地位置**：`w-tint2/build.sh` `librsvg()` 末尾（现有"STATIC 清 .so"处）：STATIC 路径 rm `.so` + 无条件 sed 修 `.la`（`library_names`/`dlname` 清空 + 去 `-lgdk_pixbuf-2.0`），并同样处理 `libcroco-0.6.la`（`libcroco()` 或 librsvg 依赖处）。

#### 2.2、功能点继承评估：librsvg 声明去留与新方案权衡（2026-11-15，补充于 2.1 落地验证后）

**关键新发现（nm 实证，推翻"误声明"判断）**：`/usr/local/lib/librsvg-2.a` **真实引用 gdk_pixbuf 符号**
（`U gdk_pixbuf_loader_close/get_format/get_pixbuf/new/new_with_mime_type/write/error_quark/...` 共 15 个）——
**librsvg 2.40 的 loader 集成确实依赖 gdk-pixbuf**，`librsvg-2.la` 的 `dependency_libs` 含 `-lgdk_pixbuf-2.0` 原本是**正确声明**。
而 u-gtk ar 魔改（io-svg 编入 `libgdk_pixbuf-2.0.a`）使 gdk_pixbuf 反向依赖 rsvg → **真·双向依赖（循环）**，
标准 libtool 天然排不了（排 rsvg 在前 → undefined）。去掉声明是**打破循环的治标，牺牲了 `.la` 依赖完整性**。

**去掉 `-lgdk_pixbuf-2.0` 的目的**：让 `librsvg.la` 依赖拓扑单向，libtool 才排对序
（引证：清 `.so` 后保留声明仍 `librsvg-2.a ... -lgdk_pixbuf-2.0` 顺序错 → 去声明后 `-lgdk_pixbuf-2.0 ... librsvg-2.a` 才对）。

**功能点继承评估**（nm 实证 + full 实跑）：

| 项 | 状态 |
|---|---|
| `libgdk_pixbuf-2.0.a` 功能点（io_init_builtin / svg_fill_vtable / io_png / io_jpeg） | **完好**（nm 5 处） |
| gtk-lib 定制调整（svg loader 编入、注册链、`.pc` Requires 含 gdk-pixbuf） | **未动**（只改了 `.la` 文本元数据） |
| 消费方链 `gdk_pixbuf` 符号 | **仍解析**：本项目所有消费方（gtkmm GTKMM_LIBS、各应用 LIBS0）**显式含 `-lgdk_pixbuf-2.0`**，不靠 librsvg.la 隐式带 |
| gtkmm full 实跑 | **RC=0**（generate_extra_defs 链通 gdk_pixbuf+rsvg） |
| **风险** | 未来若出现"只链 rsvg 不链 gdk_pixbuf"的 libtool 消费方 → 缺 15 个 `gdk_pixbuf_*` 符号（本项目消费方模式已定，不踩） |

**更优方案（保留 `.la` 完整性，不牺牲继承）**：声明是真实依赖，正解不该去它——改在**消费方侧**解决循环：
`c_gtkmm` 的 `GTKMM_LIBS` 把 `-lrsvg-2`/`-lgdk_pixbuf-2.0` 用**绝对路径 `.a` + `-Wl,--start-group`** 包住
（`/usr/local/lib/librsvg-2.a`、`/usr/local/lib/libgdk_pixbuf-2.0.a`；libtool 对绝对路径不展开不重排，
group 透传 ld 循环解析）→ **不碰 librsvg.la**（保留完整声明），功能继承 100%。

**待定**：A 维持现状（去声明，已验证 full 过）vs B 改消费方侧（保留 `.la` 原样 + absolute-path group，需重测 libtool -v + 重跑 full）。

#### 2.3、问答三连：rsvg↔gdk_pixbuf 依赖的由来 / 版本 / 剔除（2026-11-15，nm+源码实证）

##### 2.3.1、rsvg 为何反向依赖 gdk_pixbuf？是原生还是魔改？哪块功能？（nm 实证）

**问（用户）**：1. 魔改后：gdk_pixbuf(io-svg.c.o 编入) 引用 rsvg → 反向依赖 → 循环。这个好理解，当时开工 我是知情的。
2. 但 rsvg 他作为一个底层的基础库，为什么会去反向依赖 gdk_pixbuf 呢？是它原生代码就依赖，还是后来魔改的呢？是哪一块的功能需要依赖到他这一边？

**答**：

**引用点**：15 个 `U gdk_pixbuf_*` 符号**全部集中在单个对象 `librsvg_2_la-rsvg-image.o`**（`rsvg-image.c`）。

**功能块**：SVG 的 **`<image>` 元素（内嵌位图）解码**。`rsvg-image.c` 处理 SVG 里 `<image href="data:image/png;base64,...">`（或外部位图引用）时，流程是：
1. `gdk_pixbuf_loader_new/new_with_mime_type` —— 建 loader
2. `gdk_pixbuf_loader_write` —— 把位图字节流喂进去
3. `gdk_pixbuf_loader_close/get_pixbuf` —— 解出 `GdkPixbuf`
4. `gdk_pixbuf_format_get_mime_types` —— 认 MIME 决定格式
5. 再转 cairo 表面绘制

即：**librsvg 渲染 SVG 内嵌的 PNG/JPEG 位图时，借 GdkPixbufLoader 解码**。

**原生 vs 魔改**：`w-tint2/build.sh` 对 librsvg **只有 configure/SUBDIRS 删减和 `.pc` 补 Requires，没有任何源码 patch**；`rsvg-image.c` 是 librsvg 2.40（GNOME C 版）上游自带文件。→ **纯原生依赖**（C 版 librsvg 的上游设计，它本来就链 gdk-pixbuf）。

**对方案的影响**（印证 2.2）：这条依赖是**真实功能需求**（SVG 位图渲染），方案 B（保留 `librsvg.la` 声明 + 消费方侧解决循环）语义**完全正确**；方案 A（去声明）当前无功能损失（消费方都显式链 `-lgdk_pixbuf-2.0`，`GdkPixbufLoader` 照常解析，full RC=0），但 `.la` 元数据会"丢"这条真实依赖，仅靠消费方显式补齐。

##### 2.3.2、rsvg 有无早期版本不依赖 gdk-pixbuf？——Rust 版不适合（已拍板排除）

**问（用户）**：rsvg 有早期版本不依赖 gdk-pixbuf 的不？如有，可适合在本项目环境使用？

**答**：没有"早期版本不依赖"——不依赖的是**后期 Rust 版**（证据：GNOME 2.41 NEWS + MR !904 + Federico 博客）：

| 版本 | 时间 | 是否依赖 gdk-pixbuf | 说明 |
|---|---|---|---|
| **C 版 ≤ 2.40.x**（本项目 2.40.21） | ~2017 前 | **全部依赖** | `rsvg-image.c` 的 `GdkPixbufLoader` 解码 `<image>` 内嵌位图**是历史原因、一直如此**（Federico 原话："librsvg's original C code did not even bother…it would just ask gdk-pixbuf"） |
| **2.41 ~ 2.57**（Rust 重写期） | 2017~2023 | **仍依赖** | 只是部分代码 Rust 化，`<image>` 解码仍走 gdk-pixbuf |
| **2.58.0+**（2023-12，MR !904） | 2023~ | **不依赖** | 改用 Rust `image-rs` crate 解码（仅 JPEG/PNG/GIF/WebP） |

**关键点**：librsvg 从未在"早期"去掉 gdk-pixbuf——去掉是 2.58 的未来方向（Rust 化的一部分）。

**2.58.0 不适合本项目**（3 点）：① 需整套 Rust 工具链（`cargo vendor` image-rs crate 闭包 + musl 静态链 Rust 库，Alpine builder 无 Rust 链，体积/复杂度大增）；② 与现有链不兼容（C 版 2.40.21 + libcroco + 现有 make/.pc/SUBDIRS 逻辑已调通，换 2.58 等于重写 librsvg 构建）；③ 杀鸡用牛刀（只为一个 `.la` 元数据循环，方案 A/B 已闭环不动功能）。

**拍板（用户 2026-11-15）**：**Rust 版本不合适，不用考虑**。维持 2.40.21。

##### 2.3.3、`<image>` 内嵌位图是啥？能否剔除屏蔽该功能避依赖？

**问（用户）**：rsvg-image.c 的 GdkPixbufLoader 解码 `<image>` 内嵌位图是历史原因、这里的内嵌位图是啥，bmp?? 我们的场景，可以剔除屏蔽这个功能 从而避免依赖吗？

**答**：

**① 内嵌位图是啥**：SVG `<image>` 元素引用的**位图**：`<image href="data:image/png;base64,...">`（data URI 内嵌）或外部位图引用。主流是 **PNG/JPEG**（SVG spec 对 viewer 的最低要求），BMP/GIF/WebP 等 gdk-pixbuf 支持的格式也可。**BMP 只是其中一种，不是主场景**。

**② 能剔除屏蔽吗？不能（实证）**：

| 证据 | 结论 |
|---|---|
| `configure.ac:100` `PKG_CHECK_MODULES(LIBRSVG, gdk-pixbuf-2.0 >= 2.20 ...)` | **gdk-pixbuf 是 librsvg 库本体的硬依赖**（无 `--without-gdk-pixbuf` 开关），configure 找不到直接失败 |
| gdk-pixbuf 引用渗入 **7 个源文件**（`rsvg-image.c` 7 处 + `rsvg.c`/`rsvg-base.c`/`rsvg-cairo-draw.c`/`rsvg-gobject.c`/`rsvg-file-util.c`/`rsvg-base-file-util.c`） | 不是单一 image 解码点——公共 API `rsvg_handle_get_pixbuf`、节点数据、cairo 绘制、GObject 属性**处处是它**，屏蔽不了 |
| 即便删 `rsvg-image.o`，其余 6 文件的引用还在 | 依赖仍在，等于没剔 |

**③ 结论：不需要剔**——依赖本身不痛（gdk-pixbuf 静态库本来就在我们环境里、消费方都显式链）；痛的是 `.la` 循环元数据（方案 A/B 已闭环，full RC=0）；剔功能反而**损失含位图的 SVG 渲染**（SVG 图标/贴图场景常见），且动源码大手术。**维持 2.40.21 + 方案 A/B，不用考虑剔除。**

#### 2.4、循环依赖处理：能否免去 gdk_pixbuf→rsvg 依赖？业界做法（2026-11-15）

##### 2.4.1、问答：底层↔次底层循环依赖，"免去前者依赖"可行吗？业界怎么处理？

**问（用户）**：gdk_pixbuf(io-svg.c.o 编入) 引用 rsvg——底层依赖次底层；而次底层（rsvg）本身又依赖底层（gdk_pixbuf）。可以把前者的依赖指定免去吗？这种情况业界一般是怎么处理的？

**答**：分三个层面：

**① 符号层面——免不了**：`io-svg.c.o` 里的 `rsvg_handle_*` 引用是编译进代码的，只要它留在 `libgdk_pixbuf-2.0.a`，任何链接该库的程序就必须解析 rsvg 符号（ld 强制）。`--unresolved-symbols=ignore` 能骗过链接但运行即崩，不算解。

**② 链接层面——业界标准是 `--start-group/--end-group`**：ld 对循环库的标准解（group 内反复扫描直到符号全解析）。本项目不生效的唯一原因是 libtool 破坏 group（把展开的 `.la` 排到 group 外，见 1.5 / 3.5③），并非 ld 不行。

**③ 架构层面——依赖倒置/插件化（首选，上游就是这么干的）**：底层不编译期依赖上层，上层以插件/接口实现挂载。上游 gdk-pixbuf 就是范本：本体零 loader 依赖（io-png/jpeg/svg 是独立 loader，运行时经 `gdk-pixbuf-query-loaders` 注册表/dlopen 拉入）。**本项目方案 A"编入"恰好反着来**（为省 `-u` 把 loader 编进 `.a`，亲手制造了 gdk_pixbuf→rsvg 这半个环——上游本无此环）。

**业界三种标准处理**：

| 做法 | 说明 | 本项目对应 |
|---|---|---|
| 依赖倒置/插件化 | 底层零依赖、上层插件挂载（gdk-pixbuf 上游范本） | 拆 loader 出 `.a`（回到上游架构 + get_type 注册），但 rsvg→gdk_pixbuf 是真的，环仍结构性存在 |
| `--start-group`（链接期，治标） | ld 循环库标准工具，前提不被 libtool 重排破坏 | 方案 B（消费方侧 absolute-path + group，保留 .la）——**最贴近业界标准** |
| 合并库 | 循环双方合成一个大库 | — |

**结论**："免去 gdk_pixbuf 依赖 rsvg"：符号层免不掉；链接层靠 group（需绕开 libtool 或不让它拆 group）；架构层拆插件也消不掉环（rsvg→gdk_pixbuf 是真实依赖，见 2.3.1），只能"消费方显式全链 + group"。

**业界实践总结：循环依赖靠 `--start-group` 兜底 + 尽量别制造环**。本项目环是魔改制造的，**方案 B 是业界正统**（group = ld 官方循环机制，libtool 只透传）；方案 A 是"用元数据声明剪掉半个环"的变通。

##### 2.4.2、问答：librsvg 有无其他替代实现（无 gdk_pixbuf 反向依赖 + 满足本项目场景）？

**问（用户）**：gdk_pixbuf(io-svg.c.o 编入) 引用 rsvg——底层依赖次底层，而次底层（rsvg）本身又反向依赖底层。jpg/png 没有问题，是因为他们没有后者的反向依赖哈。librsvg 有其他替代实现吗，无后者反向依赖且满足当前项目场景功能需要的？

**答**：先界定本项目场景 = **gdk-pixbuf 的 SVG loader**（`gtk_icon_theme_load_icon → gdk_pixbuf → svg loader`，实现 `GdkPixbufModule` 接口把 SVG 渲成像素）。候选盘点：

| 候选 | 无 gdk_pixbuf 反向依赖？ | 满足本项目场景？ | 结论 |
|---|---|---|---|
| **Rust 版 librsvg 2.58+** | ✅（image-rs 解码） | gdk-pixbuf loader 插件仍保留（官方仍装 loader），功能齐 | ❌ 需 Rust 工具链，已拍板排除 |
| **C 版 librsvg ≤2.40 全线** | ❌ 全依赖（rsvg-image.c GdkPixbufLoader 是 C 版历史设计） | ✅ | 就是现状，无解 |
| **lunasvg（C++ 轻量渲染）** | ✅（纯 C++ 自渲染，可无外部依赖） | ❌ 无 `GdkPixbufModule` 集成接口（自绘 surface 非 GdkPixbuf），SVG 支持子集 | ❌ |
| **resvg（Rust）** | ✅ | ❌ 同 lunasvg + Rust 工具链 | ❌ |
| **CairoSVG（Python）** | ✅ | ❌ 解释型非 C ABI，静态链不适用 | ❌ |
| **cairo-svg-surface** | ✅ | ❌ 那是 SVG **输出**，非渲染 SVG 输入 | ❌ |
| **QtSvg** | ✅ | ❌ Qt 依赖，重量级 | ❌ |

**结论：没有合适的替代**。① "无 gdk_pixbuf 反向依赖"的实现（lunasvg/resvg/2.58+）要么**不能当 gdk-pixbuf loader**（无 `GdkPixbufModule` 插件集成——本项目要的就是 svg loader），要么**工具链不符**（Rust 已排除）；② 能当 gdk-pixbuf svg loader 的标准实现**只有 librsvg 一家**（GNOME 官方，gdk-pixbuf loader 就是其生态配套），而 C 版全线都有这个反向依赖（librsvg 本体用 gdk-pixbuf 解 `<image>` 是上游设计，非魔改）。

**本质**：环的一半（rsvg→gdk_pixbuf）是 librsvg 作为 gdk-pixbuf 生态成员的**天生耦合**，另一半（gdk_pixbuf→rsvg）是本项目魔改编入制造的。换实现消不掉（没得换），处理仍为 **方案 B（group 消化，业界标准）或方案 A（元数据剪环）**。

##### 2.4.3、方案 A/B 明确定义 + 方案 B 在 libtool 下可行性（实测：group 被拆空，不可行）

**方案 A / B 是什么（重新说明）**：

- **方案 A（库层 `.la` 剪环，libtool 兼容）**：改 `w-tint2/build.sh` 的 `librsvg()`/`libcroco()`——构建后修 `librsvg-2.la`/`libcroco-0.6.la` 元数据（清 `library_names`/`dlname` 的 `.so` 记录 + `dependency_libs` 去 `-lgdk_pixbuf-2.0`）+ 删 `.so` 残留 → libtool 链接走 `old_library=.a` 且依赖拓扑单向（不再循环）。配合 `u-gtkmm/build.sh` `c_gtkmm` 的 GTKMM_LIBS 补 `-lrsvg-2/-lpng16/...` loader 依赖（消费方显式全链）。**已 full 实测 RC=0**。代价：`.la` 元数据"丢"一条真实依赖（librsvg 实际用 gdk_pixbuf，见 2.3.1），仅靠消费方显式补齐。
- **方案 B（消费方侧 group 消化环，保留 `.la`）**：不改库元数据，在 `u-gtkmm/build.sh` `c_gtkmm` 的 GTKMM_LIBS 里把 `-lrsvg-2`/`-lgdk_pixbuf-2.0` 用**绝对路径 `.a` + `-Wl,--start-group/--end-group`** 包住，让 ld group 内循环解析（业界正统，见 2.4.1）。

**问（用户）**：方案B libtool能用吗？要改造哪些，分析影响点。

**答（实测）**：**libtool 下用不了 group**——

```
xx-clang++ ... -Wl,--start-group -Wl,--end-group  /usr/lib/libatkmm-1.6.a ...
/usr/local/lib/libgdk_pixbuf-2.0.a /usr/local/lib/librsvg-2.a /usr/lib/libpng16.a ...
```

`libtool -v` 实际展开：**`--start-group` 与 `--end-group` 中间是空的**——libtool 把 group 内的库（**包括绝对路径 `.a` 也一并**）重排移到 group 之外（3.5③ 的"收集库参数按拓扑重排"机制对绝对路径同样生效）。**"绝对路径可避开 libtool 重排"的假设不成立**，group 结构被拆散 = ld 循环失效。这是 libtool 固有限制，无法用参数规避。

**要 group 生效必须绕开 libtool 直链**（`generate_extra_defs` 的 `extra_defs_gen_generate_extra_defs_LINK` 覆盖为 `xx-clang++` 直链），即方案 B'（直链版，非 libtool 版）。

**两路对比与影响点**：

| 方案 | libtool 兼容 | 改造点 | 影响面 |
|---|---|---|---|
| **A**（`.la` 剪环） | ✅ libtool 正常排 | `w-tint2/build.sh` librsvg/croco `.la` 元数据（已改+实测 full RC=0）+ `u-gtkmm/build.sh` c_gtkmm GTKMM_LIBS 补 loader 依赖 | 库层元数据（已证明无功能损失，见 2.2） |
| **B'**（直链 + group） | ❌ 需绕 libtool | `u-gtkmm/build.sh` c_gtkmm：`extra_defs_gen_generate_extra_defs_LINK` 覆盖直链 + GTKMM_LIBS absolute-path group；`librsvg-2.la`/`libcroco-0.6.la` 可**完全回退原样** | 仅 u-gtkmm 一个文件；其他 rsvg 直链应用零影响 |

**当前建议**：A 是"libtool 环境下的标准解"（已验证、改动小、full 过）；B' 更"正统"但改 gtkmm 内部链接规则 + 需重测。**待用户拍板收尾。**

##### 2.4.4、问答：不剪 rsvg（标准方）改剪 pixbuf（魔改方）可行吗？

**问（用户）**：但 `.la` 元数据会"丢"这条真实依赖，仅靠消费方显式补齐。`.la` 剪环，不剪 rsvg 剪 pixbuf 这边可行吗？因为前者是标准的，后者反而是魔改的。

**答**：洞察对——剪魔改方（gdk_pixbuf→rsvg 是魔改制造）比剪标准方（librsvg→gdk_pixbuf 是上游设计）更合理。但"剪 pixbuf 这边"有结构坑：

**拆 gdk_pixbuf 侧（io-svg 拆回独立 loader）的环分析**：

| 拆法 | 依赖图 | 环？ |
|---|---|---|
| 只拆 `io-svg` 出 `.a`（gdk_pixbuf 本体留注册链） | `gdk_pixbuf(init_builtin) → loader(io-svg) → rsvg → gdk_pixbuf` | ❌ **环仍在**——方案 A 的注册链（`get_type → init_builtin → loader fill_vtable`）编译在 `gdk_pixbuf.a` 内，只要它引 loader，loader→rsvg→gdk_pixbuf 就成环回来 |
| 拆 io-svg + 注册也拆（loader 侧 constructor 自动注册，gdk_pixbuf.a **零 loader 引用**） | `gdk_pixbuf`（无引用）‖ `loader → rsvg → gdk_pixbuf`（单向链） | ✅ **无环**，librsvg.la 可**完全原样保留**（标准方不动） |

**现实代价（为什么 A 仍务实）**："剪 pixbuf + 注册拆出"= 重做方案 A 之前的架构：
1. `u-gtk/build.sh` gdk_pixbuf 改多目标（core `.a` + 独立 `loader-svg.a`）+ loader 侧 `__attribute__((constructor))` 注册（替代 get_type 注册链）；
2. **全部 8+ svg 应用**（lxtask/geany/pcmanfm/gpicview/xfce4/engrampa…）LIBS 显式加 `-lloader-svg`（或 whole-archive）——否则静态按需拉取不拉 loader → 回到"图标打叉"老问题；
3. 全量回归 + full 重验。

**收益**：仅 `.la` 元数据语义完整——**功能层面与 A 完全无差异**。

**关键缓解：A 其实没"丢"依赖声明**——A 只改 `.la`，`librsvg-2.0.pc` 的 `Requires` **仍含 `gdk-pixbuf-2.0`**（2026-11-13 w-tint2 补的），**pkg-config 消费路径（meson/configure）依赖声明完整**；"丢"的只是 libtool `.la` 展开路径，且由消费方显式 `-lgdk_pixbuf-2.0` 补齐（已验证 full RC=0、功能无损）。

**结论（用户 2026-11-15 拍板）**：按 **A 收尾**（.la 剪环 + 消费方补依赖，full 已验证）；剪 pixbuf 魔改方（重构 loader 架构）可单独立项，不阻塞当前修复。

