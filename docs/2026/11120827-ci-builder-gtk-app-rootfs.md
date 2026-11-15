# CI实跑验证与 rootfs 图标排查（拆出自 11110827-ci-builder-gtk-app.md）

> 来源：2026-11-15 从 `docs/2026/11110827-ci-builder-gtk-app.md` 第五章拆出（原文档过大）。本章保留原章节序号与层级迁入本文件（含 `### 1~4` 小节）。

## 章节表

- 五、CI实跑验证（2026-11-12~15）
  - 1、镜像 alpine-compile-2-dbg 核查（回复原文，1.1–1.6）
  - 2、镜像二次分析（2.1 远端更新/编译结果 + 2.1.1–2.1.7 子节 + 2.2 三失败 gpicview/engrampa/lxappearance 日志与修复，2026-11-13）
  - 3、镜像三次分析（3.1 远端又更新/4 空组件 feh/scrot/tint2/pcmanfm 根因 + 3.2 日志分析 + 3.3 依赖未就位修复验证，2026-11-13）
  - 4、镜像四次分析与 rootfs 图标排查（4.1 远端再更新/7 组件全过/scrot+pcmanfm 修复/cachesrc CI 生效/xrandr-dunst COPY 注释 + 4.2 图标找不到三原因与三件套/非 musl + 4.2.5 订正实测 + 4.3 UPX 干扰与 gdk-pixbuf svg loader 机制（4.3.1–4.3.5），2026-11-14）
  - 5、第五次拉取分析（5.1 分析原文：开关集/启用 10 stage + 三失败 geany/engrampa/dunst 根因 + 与 lib 文档对照结论；5.2 修复进展 5.2.1 验证环境切换+三组件修复落地、5.2.2 pcmanfm 修复（libfm 手动补头/.pc+bin_PROGRAMS= 源头消错）、5.2.3 rofi 修复（嵌套/固定提交/xkbcommon 缺→meson 静默丢目标/链接 zstd+rsvg），2026-11-15）
  - 6、第六次拉取分析与组件根因修复（6.1 engrampa libtool 重排根因 + 落地验证与三坑 + 6.2 pcmanfm 清理清单误删根因定案与修复 + 踩坑表 + 6.3 tint2 日志脏定位 + 6.4 日志脏全局汇总 + 6.5 gtkmm 应用验证与修复（四应用全出 bin）+ 6.6 dropbear/openbox undock 取件 + 6.7 hsetroot 用法说明（6.7.1 无参=纯黑与正确用法），2026-11-16）

（以下为五章正文，序号层级与原文档一致）

## 五、CI实跑验证（2026-11-12~13）

### 1、镜像 alpine-compile-2-dbg 核查（回复原文）

> 阿里云的infrastlabs/x11-base:alpine-compile-2-dbg拉下来看下编译情况，编译开关见buildx.sh  。

核查结果如下。

#### 1.1、镜像元数据

| 项 | 值 |
|---|---|
| 镜像 | registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-compile-2-dbg |
| 大小 | 323MB |
| `builtdate` label | **2026-11-12_16:41:05**（今天） |
| version / release | v26.11 / production |
| 对应 buildx.sh 分支 | dbg（`plat=linux/amd64` → 镜像名加 `-dbg`，`buildx.sh:156/204`） |

#### 1.2、总览：33 个组件目录，**19 个空**

**❌ 开关 =yes 但产物为空（4 个）**：

| 开关 | 目录 | 实际 |
|---|---|---|
| `COMPILE_XFCE4` | xfce4 | 0 文件；**`thunar` / `ristretto` 目录根本不存在**，`dbus`/`xfce` 库栈也空 → **b_deps 压根没跑，stage 被门控跳过** |
| `COMPILE_SYSMONITOR` | gsm | `gsm/bin` 在但无 `gnome-system-monitor`；`gtop` 54 文件、`wnck` 22 文件（依赖库建了，主程序没出） |
| `COMPILE_ENGRAMPA` | engrampa | `engrampa/bin` 在但空 → 构建函数跑了（建了 bin），没出二进制 |
| `COMPILE_GPICVIEW` | gpicview | 0 文件、无 bin 子目录 → 同 xfce4，被门控跳过 |

**✅ 开关 =yes 且产物正常（6 个）**：`PULSE`(11 个二进制) / `PASYSTRAY` / `PAVUCONTROL` / `LXDE`(lxtask) / `PCMANFM` / `GEANY` —— **必须关心**：开关打开 = 编译出的二进制一定要有，缺了就是构建失败被 `oneBuild` 吞掉（AGENTS §3 的坑），这 6 个是验证点。

**⚠️ 开关 =no 却有产物（6 个）**：`SSH`→dropbear(4) / `FLUX`→fluxbox(8) / `OPENBOX`(8) / `SUCKLESS`(9) / `TIGER`→tigervnc / `XRDP`(2) —— **不用关心**：镜像是复用的，会从历史镜像层拷贝出以前构建留下的产物，所以即使 `buildx.sh` 开关关掉，旧二进制仍带着走，不是错误。

> 区分：**=yes 缺产物 = 要修的问题；=no 有产物 = 历史层复用，正常**。

#### 1.3、结论：这个镜像不是用 buildx.sh 当前开关集构建的

有 **8 个开关状态与 `buildx.sh:166-200` 相反**：

```
镜像里 =yes，buildx.sh 写 =no :  TIGER  XRDP  SSH  FLUX  OPENBOX  SUCKLESS
镜像里 =no，buildx.sh 写 =yes :  XFCE4  GPICVIEW
```

指纹非常具体，基本可以断定是 CI 构建时用的 buildx.sh 开关块是**较早版本**（xfce4/gpicview 还没打开、tiger/xrdp/ssh/flux/openbox/suckless 还没关掉）。ENGGRAMPA/SYSMONITOR 两边一致（都 yes），但它们构建失败又被 `oneBuild` 吞掉（AGENTS §3 记的那个坑：`err 0, pass`），所以镜像照样出。

#### 1.4、对我们工作的直接含义

本轮在 `builder-pav` 里已验证 **thunar 1.6.3 / ristretto 0.8.5 / xfce4-display-settings** 三个二进制静态链通（`xx-verify rc=0`、未定义符号 0），但**这个镜像里一个都没有**。要进镜像必须用当前 buildx.sh 重跑 CI。

#### 1.5、两个可落地的点

1. **xfce4 stage 静默失败问题**：`COMPILE_XFCE4=yes` 时若 `b_deps` 失败，`oneBuild` 会吞成 `err 0, pass`，镜像照常产出空目录。建议在 stage 末尾加断言——`test -x /usr/local/static/thunar/bin/thunar || exit 1`，把吞错变成硬失败。
2. **thunar/ristretto 路径与 TARGETPATH 不一致**：build.sh 硬编码 `PREFIX=/usr/local/static/thunar|ristretto`，而 stage 的 `TARGETPATH=/usr/local/static/xfce4`。虽然 `COPY --from=xfce4 ${STATIC}` 是整树能带上，但 `build.sh` 内硬编码 prefix 违反 AGENTS §3.2（pavucontrol 的教训）。（**不用管**：最初实现即如此——三者复用同一组基础库、直接放一起构建；目标产物层面又要三个独立，非问题。）

要我把第 1 条的断言加到 Dockerfile 的 xfce4 stage 吗？（**已落地**：Dockerfile xfce4 stage 已加该断言，commit `7154e75`）

#### 1.6、镜像内无四个失败组件日志（已移至二章 8.1）

> 本节内容已移至**二章 `### 8、doExec 日志目录调整：/tmp/doExec 并入 .logs/`** 的 `#### 8.1`（doExec 日志在 `/tmp` 未导出、并入 `.logs/`）。详见二章 8.1（含 8.1.1 脚本调整方案）。

### 2、alpine-compile-2-dbg 镜像二次分析（2026-11-13）

#### 2.1、远端更新确认与编译结果（三失败根因）

> **触发**：用户要求拉取阿里云远端 `infrastlabs/x11-base:alpine-compile-2-dbg`（编译开关见 `compile/buildx.sh` compile 分支）看编译情况；确认远端**有更新**后做二次分析。

##### 2.1.1、远端是否有更新

- **确认有更新**：拉取 `registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-compile-2-dbg` 返回 `Digest: sha256:95aa2609...`、`Downloaded newer image`。
- **ID 对比**：旧本地 `5de6c26bab43`（13h ago，已覆盖为 dangling）→ 新 `314b41771c40`（镜像内 label `BUILDDATE=2026-11-13_03:11:19`）；镜像大小 330MB。

##### 2.1.2、编译开关（compile/buildx.sh compile 分支）

- **=yes**：`COMPILE_PULSE`/`PASYSTRAY`/`PAVUCONTROL`/`SYSMONITOR`/`LXDE`/`PCMANFM`/`GEANY`/`ENGRAMPA`/`GPICVIEW`。
- **=no**：其余（`TIGER`/`XRDP`/`X11VNC`/`SSH`/`FLUX`/`OPENBOX`/`SUCKLESS`/`XCOMPMGR`/`PERP`/`MISC`/`FEH`/`HSETROOT`/`SCROT`/`TINT2`/`XLUNCH`/`XBINDKEYS`/`XRANDR`/`DUNST`/`ROFI`/`XFCE4`/`DBUS`/`IBUS`），=no 组件产物为历史层复用（mtime 2023-11~2024，非本次编译）。

##### 2.1.3、镜像内产物/日志位置

- **产物**：`/rootfs/usr/local/static/<comp>/`（顶层 `/usr/local/static` 为空，`STATIC=/usr/local/static`）。
- **日志**：`.logs/oneBuild-*.log`（仅耗时，`set +e` 吞错、**不可判成败**——AGENTS.md 已警示）；真实输出在 `.logs/doExec/u-gtkmm/*.log`（`_exec_result.txt` 记录 exit=0 项）。

##### 2.1.4、编译时间线与结果（本次构建 2026-11-13 03:11:57–03:21:21）

**✅ 成功（产物已装）**：

| 组件 | 产物 | 备注 |
|---|---|---|
| pulseaudio | `bin/pulseaudio` + `pa-*`/`pacat`/`pactl`/`padsp` 等 12 个 | deps：libogg(18s)/libvorbis(41s)/libopus(89s)/libflac(104s)/libsndfile(79s) |
| pasystray | `bin/pasystray` | |
| pavucontrol | `bin/pavucontrol` | |
| sysmonitor | `gsm/bin/gnome-system-monitor` | deps：gtop/wnck/startup_notification（.a 已产） |
| pcmanfm | `bin/pcmanfm` | deps：libfm/menu-cache |
| geany | `bin/geany` | |
| lxde（lxtask） | `lxde/bin/lxtask` | ⚠️ **lxappearance 失败**（见下） |

**❌ 失败 3 个（本次二次分析重点）**：

| 组件 | 失败点 | 根因（日志/镜像核实） |
|---|---|---|
| **gpicview** | `>>> static-link FAILED` | `x86_64-alpine-linux-musl-ld: cannot find -lzstd`——**镜像无 `libzstd.a`**（全盘 `find / -name "libzstd*"` 无结果）；目录完全空 |
| **engrampa** | configure 失败 | `You need to install mate-common` → `./configure: not found`（configure 未生成）+ `libeggsmclient.a MISSING`；**镜像无 mate-common/eggsmclient**；bin 空 |
| **lxappearance**（lxde 内） | make 链接失败 | `undefined reference to XRenderCreateCursor/XRenderCreateAnimCursor`（libXcursor.a→**Xrender 传递依赖未链**）；**镜像无 `libXrender.a`**；仅产出 lxappearance.pc，**无 `bin/lxappearance` 二进制** |

##### 2.1.5、关键环境事实（解释为何"产物在、重编缺库"）

- 镜像 `/usr/lib`、`/usr/local/lib` **无任何 `.a`**；全盘仅 **44 个 `.a`**，全是**应用内部库**（pulseaudio 模块 20 个、geany 插件 6 个、xrdp 4+2 个、openbox 2 个、wnck/gtop/tigervnc 各 1 个等）。
- **无基础依赖静态库**：`libXrender/libxcb/libpixman/libXfixes/libzstd/libpng` 全盘 `find` **无结果**；gtk2 静态库亦不在（u-gtk 改造库在 `builder-awe`=alpine-builder-gtk224 容器，AGENTS.md 五章 1 节）。
- **结论**：本镜像只保留产物、不保留编译依赖库——**"能跑但不能重编缺库组件"**。构建模型依据见 **2.1.6**；三失败发生在 **base 编译阶段**（真实失败，非清理/COPY 问题）。

##### 2.1.6、compile/src/Dockerfile 结构核实（2026-11-13）

**构建模型 = 多阶段（组件 stage 在 base 编译 → 最终镜像聚合产物）**：

- **base**（`Dockerfile:4`）：`FROM ${REPO}infrastlabs/x11-base:alpine-builder-gtkmm224-2 AS base` —— **编译依赖库（gtk2/xcb/Xrender/pixman/zstd）都在此镜像**。
- **每组件一个 stage**（:16 起）：`FROM base AS <comp>` + `ARG COMPILE_<comp>="yes"` + `test "yes" != "$COMPILE_<comp>" && exit 0` 开关（=no 直接跳过、产物靠历史复用）；stage 内 `ENV TARGETPATH=/usr/local/static/<comp>` + `RUN sh /src/<comp>/build.sh` 编译，产物/日志落 `STATIC/.logs|.cache`。
  - 特殊：`pavucontrol`/`pasystray` 基于 `FROM pulseaudio`（:454/:468，复用 pulseaudio stage 的库）；`ibus` 基于 `FROM dbus`（:506）。
- **预置 stage ff**（:520）：`FROM ${REPO}infrastlabs/x11-base:${COMPILE_IMG} AS ff`（`COMPILE_IMG`=`alpine-compile`/`-dbg`）——预置镜像，携带预编译 `/rootfs`。
- **最终镜像**（:523）：`FROM registry.cn-shenzhen.aliyuncs.com/infrasync/v2025:library--alpine---3.13.12`；`COPY --from=ff /rootfs /rootfs`（:524）+ 逐组件 `COPY --from=<comp> ${STATIC} /rootfs${STATIC}`（:564-597）+ `rm -rf /rootfs/bin /rootfs/sbin`（:600）。
- **结论**：最终镜像 = **Alpine 3.13.12 基础 + 纯产物/日志**，**无任何编译依赖库**（`/usr/lib`、`/usr/local/lib` 无 `.a` 佐证）。gpicview/engrampa/lxappearance 的失败是 **base 编译阶段真实失败**（非清理/COPY 问题）。

##### 2.1.7、结论/修复方向

- **gpicview**：构建环境需补 `zstd-static`（提供 `libzstd.a`），或确认依赖链改走非 zstd 路径。
- **engrampa**：需先装 `mate-common`（autotools 提供 `configure`）+ 构建 `libeggsmclient.a`（mate-desktop 家族）；二者当前镜像/源码树均无。
- **lxappearance**：链接需把 `-lXrender` 纳入 `--start-group`（AGENTS.md「静态传递依赖必须 `--start-group`」已知坑），否则 Xcursor.a 的 `XRenderCreateCursor` 悬空。
- 三者均**未落产物**，CI 部署到 hdmi 容器前需先修复；`builder-awe`（gtk2 库源）为修复执行环境。

#### 2.2、三失败组件的日志来源与修复思路（2026-11-13）

> **日志来源**：三失败（gpicview/engrampa/lxappearance）错误信息取自**拉取的 aliyun 镜像 `alpine-compile-2-dbg`（`314b41771c40`）内 `/rootfs/usr/local/static/.logs/doExec/u-gtkmm/`** 下的 doExec 日志（编译在 base 阶段产出、COPY 进最终镜像保留）。

##### 2.2.1、gpicview（日志 `gpicview_.log:22-25`）

- **错误**：`>>> static-link FAILED` → `x86_64-alpine-linux-musl-ld: cannot find -lzstd`（×2）。
- **来源**：`v-gpicview/build.sh:85-94` 手动直链 `xx-clang -static ... $(pkg-config --static --libs gtk+-2.0) -lXrandr ... -lxml2 -llzma`；`pkg-config --static --libs gtk+-2.0` 输出含 `-lzstd`（gdk-pixbuf/gtk 链传递），构建环境**无 `libzstd.a`**。
- **修复**：构建环境（base/`builder-awe`）`apk add zstd-static`（提供 `/usr/lib/libzstd.a`）；或从链接命令剔除 `-lzstd`（若该依赖可选未用）。链接组结构已正确（`--start-group` 包全传递依赖，:89-93），**只差库文件**。

##### 2.2.2、engrampa（日志 `engrampa_.log:37-52`）

- **错误**：`:38 You need to install mate-common` → `:39 ./configure: not found`；`:43 make: No targets and no makefile`；`:52 libeggsmclient.a MISSING`。
- **来源**：`v-engrampa/build.sh:52` `./autogen.sh`（**mate-common** 提供 MATE autotools 宏，缺则 autoreconf 失败→无 configure）→ `:53 ./configure` 不存在；`:77` `test -f ../copy-n-paste/.libs/libeggsmclient.a` 失败。
- **修复**：① 构建环境装 `mate-common`（MATE 宏包，提供 `MATE_COMMON_INIT`/`MATE_MAKE_INIT` 等）；② 先构建 `copy-n-paste/.libs/libeggsmclient.a`（engrampa 自带 copy-n-paste/eggsmclient 子目录，`make -C copy-n-paste` 出 `.a`）再入 `:89` 链接行。

##### 2.2.3、lxappearance（日志 `lxappearance_.log:252-262,1102+`）

- **错误**：`CCLD lxappearance` → `undefined XRenderCreateCursor/XRenderCreateAnimCursor`（libXcursor.a）+ cairo `XRenderFillRectangle/XRenderCompositeText*`（:1102+）。
- **来源**：`v-lxde/build.sh:40` `make LDFLAGS="-static " LIBS="-lXinerama -lXfixes -lXrandr $LIBS0"`——**无 `-Wl,--start-group`**（对比成功版 lxtask `:70-71` 有），且 `OB_LIBS`（:33）里 `-lXrender` 排在 `-lXcursor` **之前** → 静态库右到左解析、Xrender 符号悬空。
- **修复**：照 lxtask 套路改 `LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -Wl,--end-group"`（start-group 反复扫描自动解传递依赖），并把 `LDFLAGS="-static "` 改 `LDFLAGS="$LDFLAGS"`（不覆盖 common.sh 的 `--strip-all/--as-needed`，AGENTS.md 坑）。

> **共同结论**：gpicview/engrampa 是**环境缺库**（`zstd-static` / `mate-common`+`libeggsmclient.a`）；lxappearance 是**脚本链接组缺 `--start-group`**（纯 build.sh 逻辑，无需新库）。执行环境：`builder-awe`（gtk2 库源）修复三组件。


##### 2.2.4、三组件修复落地与验证（2026-11-13，均 base 容器 builder-pav 实跑通过）

> 2.1.7 / 2.2.1-2.2.3 的"修复方向"为**推断**；实际落地（各 build.sh 单 commit）如下，验证环境 = base（`alpine-builder-gtkmm224-2`）容器 `builder-pav`。

| 组件 | 落地 commit | 实际方案（与推断差异） | 实跑验证 |
|---|---|---|---|
| lxappearance | `a3acd38` `v-lxde/build.sh` | 照 lxtask 加 `-Wl,--start-group ... --end-group`（:40）；`LDFLAGS="-static "`→`"$LDFLAGS"` | 12.4M，`xx-verify` PASS，`file`=static stripped，undef=0 |
| gpicview | `5f83841` `v-gpicview/build.sh` | **过滤 `-lzstd -ltiff`**（非装 zstd-static，同 w-feh :27-28）；`GTK_LIBS` 存变量（修复注释插 `\` 续行断链） | 12.4M，PASS，static，undef=0 |
| engrampa | `399bad0` `v-engrampa/build.sh` | **build.sh 内 apk add mate-common/yelp-tools/itstool**（非仅环境装）；dup-globals 判断 grep 改宽松正则 | 12.7M，PASS，static |

- **三修复均在 `builder-pav`（=base）实跑验证通过**，产物落 `/usr/local/static/<comp>/bin/`（lxappearance/gpicview 各 12.4M、engrampa 12.7M + `libexec/isoinfo.sh`）。
- **与 2.1.7 推断差异**：gpicview 未装 zstd-static而是剔 `-lzstd`（gdk-pixbuf 非必需 io，w-feh 先例）；engrampa 依赖装进 build.sh（幂等 apk add）而非 Dockerfile/环境。
- **engrampa 附加根因（本次实跑才暴露，推断未及）**：dup-globals patch 的 grep 判断 `'WindowList        = NULL'`（8 空格）不匹配 tarball 实际 `*WindowList = NULL`（1 空格）→ patch 未应用 → `WindowList`/`ForceDirectoryCreation` **multiple definition**（main.o↔fr-init.o）；改 `grep -qE 'WindowList[[:space:]]*=[[:space:]]*NULL'` 后 patch 应用、链接通过。历史 `11051758-v-oth-impl01.md` 只记 apk add mate-common/yelp-tools + 手动链，**未记此 grep 坑**。
- **commit**：`a3acd38` / `5f83841` / `399bad0`（已推送 `8df9807..399bad0` → `origin/feat/ai-260925`）。

### 3、alpine-compile-2-dbg 镜像三次分析（2026-11-13，本次远端又更新）

#### 3.1、远端更新确认与编译结果（4 空组件根因）

> **触发**：用户再次要求拉取远端 `infrastlabs/x11-base:alpine-compile-2-dbg` 看编译情况（编译开关见 `compile/buildx.sh`）；确认**远端又有更新**（较 2.1 的 `95aa2609...`），拉取后做三次分析。

##### 3.1.1、远端更新确认

- **有更新**：`docker pull` 返回 `Digest: sha256:180783c48e60...`、`Downloaded newer image`（上轮 2.1 为 `sha256:95aa2609...`）。
- **ID 对比**：上轮 `314b41771c40`（BUILDDATE 2026-11-13_03:11:19）→ 本次新 `48517084f2e1`（`RepoDigest`=`@sha256:180783c4...`）。

##### 3.1.2、编译开关（compile/buildx.sh compile 分支，本次已扩）

> **=yes 共 15 个**（较 2.1.2 的 9 个新增 w-* 与 xfce4）：`FEH`/`HSETROOT`/`SCROT`/`TINT2`/`XLUNCH`/`PULSE`/`PASYSTRAY`/`PAVUCONTROL`/`SYSMONITOR`/`LXDE`/`PCMANFM`/`XFCE4`/`GEANY`/`ENGRAMPA`/`GPICVIEW`。
> **=no**：`TIGER`/`XRDP`/`X11VNC`/`SSH`/`FLUX`/`OPENBOX`/`SUCKLESS`/`XCOMPMGR`/`PERP`/`MISC`/`XBINDKEYS`/`XRANDR`/`DUNST`/`ROFI`/`DBUS`/`IBUS`（目录存在系缓存/基础镜像复用，mtime 早于本次）。

##### 3.1.3、编译结果（本次镜像 `/rootfs/usr/local/static/`）

- **✅ 11 个有产物**：hsetroot、xlunch、pulseaudio（+pa-*）、pasystray、pavucontrol、gsm（gnome-system-monitor）、lxde（**lxappearance+lxtask**，上轮 lxappearance 失败已修复 `a3acd38`）、xfce4（**xfce4-display-settings+thunar+ristretto**，上轮 2.1 未列为 yes、本次已开）、geany、engrampa（上轮失败已修复 `399bad0`）、gpicview（上轮失败已修复 `5f83841`）。
- **❌ 4 个目录完全空**（连 `bin/` 都没有，仅空目录）：

| 空组件 | 开关 | 依赖（构建期） |
|---|---|---|
| **feh** | `COMPILE_FEH=yes` | imlib2（w-xlunch 建） |
| **scrot** | `COMPILE_SCROT=yes` | imlib2 |
| **tint2** | `COMPILE_TINT2=yes` | imlib2/librsvg/libcroco |
| **pcmanfm** | `COMPILE_PCMANFM=yes` | libfm/menu-cache/GTK2 |

##### 3.1.4、根因（三层，镜像层面）

1. **Dockerfile stage 吞错**：`RUN ...; sh /src/<c>/build.sh b_deps; \ sh /src/<c>/build.sh <comp>; \ find ${TARGETPATH} -type f |sort;` —— **`find` 是最后一条命令（恒 rc=0）**，`;` 也不检查退出码 → build.sh 失败被掩盖，产物空但 stage 显示成功（镜像照常构建出"新" digest）。
2. **build.sh 尾部 `exit 0` 吞错**：`w-feh:70`、`w-tint2:356`、`v-pcmanfm:276` 均 `exit 0`（AGENTS「case 结尾不要 exit 0」明令禁止）；即使 oneBuild 失败也返回 0。w-scrot 无尾部 exit 0，但仍被 Dockerfile `find` 掩盖。
3. **依赖未就位（具体编译失败点）**：4 组件构建期依赖（imlib2 / libfm+menu-cache / librsvg+libcroco）在 base 编译阶段未就位/未建好 → 链接缺依赖失败。**组件脚本本身无 bug**（见 3.1.5）。

##### 3.1.5、本地复现（区分"脚本 bug"与"环境缺依赖"）

- **builder-awe（依赖已就位：`/usr/local/lib/libImlib2.a`、`libfm-gtk.a`、`librsvg-2.a`、`libcroco-0.6.a`）复现 `sh /src/w-feh/build.sh feh`** → **成功**：`/tmp/feh-repro/bin/feh` 生成 + `err 0, pass`、RC=0（19s）。
- **结论**：w-feh 脚本 + 链接逻辑本身 OK；CI 空产物是**构建期 imlib2 等依赖未就位**（base 阶段 w-xlunch imlib2 / libfm 等构建失败或下载失败），非脚本缺陷。**本地 builder 无网络**（github/curl 不通），无法复现 CI 的 imlib2 下载/构建失败点。

**订正（2026-11-13 镜像内日志实查）**：4 空组件编译日志**就在镜像内**——`.logs/doExec/u-gtkmm/{feh,scrot,tint2,pcmanfm}.log`（上层镜像环境变量写死导致 doExec 日志全落 u-gtkmm 目录，故此前漏查、误判"需 CI 日志"）。从日志确证具体失败点：
- **feh**：`fatal: unable to access 'https://gitee.com/g-system/fk-feh/': Recv failure: Connection reset by peer`（clone 失败→`/tmp/fk-feh` 无→make 全 No such file）→ **网络（gitee 连接被重置）**。
- **scrot**：`configure.ac:25/28: error: => GNU autoconf-archive not present <=` → `autoreconf failed` → **缺 autoconf-archive（构建期依赖未装，非网络）**。
- **tint2**：cmake **配置成功**（`Found imlib2 1.7.4`），但链接 `cannot find -lxcb-util`（×2，`/usr/bin/x86_64-alpine-linux-musl-ld`）→ 编到 60% `Linking C executable tint2` 失败、无产物 → **xcb-util 静态库缺失**；且 `/usr/local/lib/libImlib2.a` 全盘不存在（imlib2 构建"err 0 pass"但 `.a` 未落标准路径）→ cmake `Looking for imlib_context_set_display in Imlib2 - not found`（次要点）。b_deps `xcbutil` 日志：clone `gitee.com/g-system/fk-xcb__util` → `Connection reset by peer` → `/tmp/xcb-util` 无 → autogen/configure 全 No such file → 无 `.a`。
- **pcmanfm**：依赖 `menu-cache` clone 失败（`unable to access 'https://gitee.com/g-system/fk-menu-cache/': Recv failure: Connection reset by peer`→`/tmp/menu-cache` 无→autogen/configure 全 No such file→`cp: can't stat /usr/local/lib/libmenu-cache.a`）→ 链接 `cannot find -lmenu-cache` → `PCMANFM build FAILED` → **menu-cache 网络 clone 失败，非 pcmanfm 脚本 bug**（libfm 同轮 gitee g-system 克隆成功 338s）。
即 **feh/tint2（xcb-util）/pcmanfm（menu-cache）根因 = gitee g-system clone 遇 `Recv failure: Connection reset by peer`（网络瞬断/限流，非永久不可达——同源 fk-libfm 同轮成功）→ 源码没克隆下来 → 依赖静态库缺失 → 链接失败**；**scrot 根因 = 缺 `autoconf-archive`（clone 成功但 autoreconf 失败，非网络）**。与 3.1.4 三层（Dockerfile `find` 掩盖 + `exit 0` + 依赖未就位）吻合，且**不再需要"有网络重跑"即可定论**。

##### 3.1.6、结论与建议（未落地）

- **需 CI 构建日志**（job-logs 中 feh/scrot/tint2/pcmanfm stage 输出）或**有网络环境**清依赖重跑，确证 imlib2/libfm 下载或构建失败点（tarsrc 未命中 + curl 源不稳，AGENTS 已知）。
- **修 Dockerfile**：4 stage 的 `sh build.sh b_deps; sh build.sh <comp>;` 改 `... || exit 1`；stage 末尾用 `test -x $TARGETPATH/bin/<主产物> || exit 1`（替代 `find` 掩盖）。
- **修 build.sh**：`w-feh`/`w-tint2`/`v-pcmanfm` 去掉尾部 `exit 0`（让 `*)` → `oneBuild $1` 返回值自然传播）。

#### 3.2、4 空组件日志分析（镜像内 `u-gtkmm/` 确证）与修复思路（2026-11-13）

> **背景**：3.1.5 曾误判"需 CI 构建日志/有网络重跑"。实查**本次镜像 `48517084f2e1` 内 `/rootfs/usr/local/static/.logs/doExec/u-gtkmm/{feh,scrot,tint2,pcmanfm}.log`**（上层镜像环境变量写死致 doExec 日志全落 u-gtkmm 目录，故此前漏查），4 空组件具体失败点**全部确证**，无需 CI 日志/重跑。

##### 3.2.1、根因（镜像内日志确证）

| 组件 | 日志确证失败点 | 根因 |
|---|---|---|
| **feh** | `fatal: unable to access 'https://gitee.com/g-system/fk-feh/': Recv failure: Connection reset by peer` → `/tmp/fk-feh` 无 → `cd`/`sed`/`make` 全 No such file → `file not found: /tmp/fk-feh/src/feh` | **gitee g-system clone 被重置**（网络） |
| **scrot** | `configure.ac:25/28: error: => GNU autoconf-archive not present <=` → `autoreconf failed`（clone **成功**，ghfast.top 代理 OK） | **缺 autoconf-archive**（构建期 m4 宏包，非网络） |
| **tint2** | b_deps `xcbutil`：clone `gitee g-system/fk-xcb__util` → `Connection reset` → `/tmp/xcb-util` 无 → autogen/configure 全 No such file → 无 `.a`；链接 `cannot find -lxcb-util`（×2）→ `Linking C executable tint2` 失败、无产物 | **xcb-util clone 失败**；另 imlib2 构建"err 0 pass"但 `/usr/local/lib/libImlib2.a` **全盘不存在**（`.a` 未落标准路径）→ cmake `Looking for imlib_context_set_display in Imlib2 - not found`（次要点） |
| **pcmanfm** | 依赖 `menu-cache`：clone `gitee g-system/fk-menu-cache` → `Connection reset` → 无源码 → `cp: can't stat /usr/local/lib/libmenu-cache.a` → 链接 `cannot find -lmenu-cache` → `PCMANFM build FAILED` | **menu-cache clone 失败**（非 pcmanfm 脚本 bug；libfm 同轮 gitee g-system clone 成功 338s） |

##### 3.2.2、共同模式

- **feh / tint2（xcb-util）/ pcmanfm（menu-cache）**：三个 clone 全走 `gitee.com/g-system/fk-*`、全遇 `Recv failure: Connection reset by peer`；但**同源 `fk-libfm` 同轮 clone 成功**（338s）→ gitee g-system 是**间歇性/限流**，非永久不可达。
- **scrot**：clone 成功但缺 autoconf-archive（唯一非网络、唯一需装系统包）。
- 这些 b_deps 是 build.sh **直连 `git clone`，没走 down_catfile/tarsrc**（4.2 的 tarsrc 只覆盖下载型 fetch_src/down_catfile，clone 型无兜底）。

##### 3.2.3、修复思路（按优先级）

1. **换 clone 源（最直接）**：`git clone https://gitee.com/g-system/fk-xxx` → **ghfast.top 代理** `https://ghfast.top/https://github.com/<upstream>`（scrot 已用此法且本次 clone 成功，实证可行）。对应：feh 需查 `vers.txt` upstream；xcb-util→`$GITHUB/freedesktop-unofficial-mirror/xcb__util`（w-tint2:113 注释）；menu-cache→`$GITHUB/lxde/menu-cache`（v-pcmanfm:103 注释）。
2. **tarsrc 源码包兜底（CI 无网稳健）**：feh/xcb-util/menu-cache 源码 tarball 放 `compile/tarsrc/<comp>/`，clone 失败回退 `tar -xf`（imlib2-1.7.4.tar.gz 已在 `/_ext/x11base_tar_src/imlib2/`，可复制先例）；或给 `git clone` 加失败重试（`Connection reset` 是瞬态）。
3. **scrot：base 镜像 `apk add autoconf-archive`**（Dockerfile base stage 或 w-scrot b_deps 内装，Alpine 有该包）。
4. **imlib2 `.a` 落点（tint2 次要点）**：w-xlunch build.sh imlib2 分支被 w-tint2 b_deps 调用时 `TARGETPATH=/usr/local/static/tint2` 被继承 → 可能 install prefix 偏移致 `.a` 未落 `/usr/local/lib`。需查 imlib2 build.sh install 目标，确保 `libImlib2.a` 落 `/usr/local/lib`（否则 cmake 探测一直 fail）。
5. **配套（3.1.4 已述，勿漏）**：去掉 w-feh/w-tint2/v-pcmanfm 尾部 `exit 0`；Dockerfile stage 末尾 `test -x $TARGETPATH/bin/<产物> || exit 1` 替代 `find` 掩盖。

> **注意**：改 build.sh 后须在 builder 容器实跑（`docker exec builder-awe sh /src/w-feh/build.sh feh`，AGENTS 三章），别只看日志定论。

#### 3.3、4 空组件依赖未就位修复验证（2026-11-13 实跑，干净 gtkmm 容器）

> **背景**：按 3.2.3 修复思路落地后，用**干净 `alpine-builder-gtkmm224-2` 容器**（= Dockerfile base）逐一实跑 4 空组件，验证"依赖未就位"是否真正解除。容器带 `--network host` + `-v /_ext:/_ext` + `/src` 软链（= AGENTS 三章 3.1 Xvnc 同款套路，但构建类），每组件**独立容器**（`ver-feh`/`ver-scrot`/`ver-tint2`/`ver-pcmanfm`），避免同容器互装库掩盖"缺依赖"。
> **调用法**：照 Dockerfile stage——`TARGETPATH=/usr/local/static/<comp>`、`CONSOLE_LOG=no`、`sh|bash /src/<comp>/build.sh b_deps` + 主组件，`test -x $TARGETPATH/bin/<产物> || exit 1` 兜底。

##### 3.3.1、验证矩阵（4 组件全部构建成功）

| 组件 | 首次失败点 | 修复落地 | 复验 | 产物（xx-verify=0 / ldd） |
|---|---|---|---|---|
| **feh** | `gitee g-system/fk-feh` Connection reset（3.2.1） | `apk add curl-dev curl-static`（w-feh:14，已提交 2026649）+ `git clone`→`gitclone`（:21）+ 删尾部 `exit 0` | `feh_rc=0` | feh 3.9M，`statically linked`（**not stripped**，debug_info，xx-verify=0），ldd Not a valid dynamic program |
| **scrot** | 缺 autoconf-archive（3.2.1） | `apk add autoconf-archive`（w-scrot b_deps，已提交 e9938e2） | `scrot_rc=0` | scrot 2.5M，`statically linked, stripped`，xx-verify=0 |
| **tint2** | `fk-xcb__util` Connection reset → 无 `.a`（3.2.1） | `gitclone` 缓存命中（w-tint2 xcbutil:111）+ b_deps 补 `libtool automake autoconf`（:115）+ submodule fallback 修正 `m4/`（:118）+ 删 `exit 0` | `tint2_rc=0`（33s） | tint2 10.5M，`statically linked, stripped`，xx-verify=0 |
| **pcmanfm** | `fk-menu-cache` Connection reset → 无 `.a`（3.2.1） | `gitclone` 缓存（v-pcmanfm libfm:57/menu-cache:104）+ **主源码 `github.com/lxde/pcmanfm` clone 失败**→ 改 `gitclone`（:160，宿主克隆 1.3.1 入缓存）+ 删 `exit 0` | `pcmanfm_rc=0`（16s） | pcmanfm 13.3M，`statically linked, stripped`，xx-verify=0 |

- **判据**（AGENTS 三章 3）：`xx-verify --static` 返回 0 + `file` 报 `statically linked` + `ldd` 报 `Not a valid dynamic program`；成功复验日志 `grep -c "undefined reference|attempted static link"` = 0。4 组件全过。
- **feh not stripped**：构建时 LDFLAGS 未带 `--strip-all` 残留 debug_info（体积 3.9M vs 应 ~2M）；`xx-verify` 仍 0、静态性无损，**后续可选修**（w-feh build.sh 确认 LDFLAGS 覆盖处），本轮不阻塞。

##### 3.3.2、新增根因（3.2.1 未覆盖，本次实跑暴露）

1. **base 镜像 libgtk 缺 u-gtk 改造符号**（tint2/pcmanfm 真正卡点）：
   - 现象：tint2 `tint2conf`、pcmanfm 链接均报 `undefined reference to theme_pixbuf_render`（`pixbuf-draw.c`），复验日志此前 = 22/11。
   - 根因：`theme_pixbuf_render/get_pixbuf/pixbuf_rc_style_register_type/pixbuf_type_rc_style` 4 符号由 u-gtk pixmap engine 提供（`pixbuf-render.c` 等 4 个 `.c`，2026-11-12 才补全，见 u-gtk/build.sh:280-285）；**`gtkmm224-2` 镜像（=base）的 `/usr/lib/libgtk-x11-2.0.a` 是 u-gtkmm 重编的无 patch 版**（Nov 12 04:52，9.76M，nm 无 `theme_pixbuf_render`），而 `gtk224-2` 镜像（builder-awe）是改造版（Nov 8 10.8M，nm 有）。
   - 佐证：`Dockerfile.builder.gtkmm224:15` 注释掉 `RUN bash /src/u-gtk/build.sh b_deps`，u-gtkmm/full 重编 gtk2 覆盖 gtk224-2 继承的改造 libgtk → base 镜像缺符号；builder-pav 容器（§3.4）Nov 12 11:34 的 libgtk 有符号 = **容器层手动重建**，**不在镜像层**（`docker inspect` 同 digest `d4c994c8` 但 libgtk mtime/size 不同）。故 CI 构建（干净 base）必失败。
   - **验证**：从 builder-awe 拷改造版 libgtk 覆盖 ver-tint2/ver-pcmanfm 的 `/usr/lib/libgtk-x11-2.0.a` → tint2/pcmanfm 复验通过（tint2_rc=0/pcmanfm_rc=0）。**证明确认唯一缺项是改造版 libgtk**。
   - **修复方向**：Dockerfile.builder.gtkmm224 需在 u-gtkmm 之后补跑 `u-gtk/build.sh b_deps`（重烤 base 镜像），或主 Dockerfile 加 u-gtk stage 供 gtk2 应用 FROM。**用户 2026-11-13 拍板：远端已有新 gtkmm224-2 镜像解决此问题，本次不拉镜像（磁盘 99% 满），验证用拷贝改造版 libgtk 代替**。
2. **pcmanfm 主源码 github clone 失败**（3.2.1 未覆盖，b_deps 过了但主组件源码拉不到）：
   - 现象：pcmanfm 主组件 `git clone $GITHUB/lxde/pcmanfm`（v-pcmanfm:160）报 `Failure when receiving data from the peer` → `/tmp/pcmanfm` 无 → cd/autogen/configure 全 No such file。
   - 根因：pcmanfm 主源码走 `$GITHUB`（默认 github），**容器内 github 不通**（宿主 github 通，宿主克隆 pcmanfm@1.3.1 成功 RC=0）；b_deps 的 gitee 缓存命中了，主源码没走缓存。
   - 修复：v-pcmanfm:160 `git clone`→`gitclone`（宿主克隆 pcmanfm@1.3.1 入 `compile/tarsrc-git/pcmanfm`）→ 复验 `pcmanfm_rc=0`。

##### 3.3.3、落地改动（gitclone 机制，2026-11-13）

- `common.sh`：新增 `gitclone()`（本地缓存 clone，`GITCACHE` 默认 `/src/../tarsrc-git`；命中 `cp -a` 保留 `.git` 供 submodule；命中后 `git config --global --add safe.directory` 规避 `dubious ownership`——feh 曾中招；未命中回落网络 clone 不换源）。
- `w-feh/build.sh`：`git clone`→`gitclone`（:21）；curl-dev/curl-static（:14）；删尾部 `exit 0`（已提交 2026649）。
- `w-tint2/build.sh`：5 处 `git clone`→`gitclone`（libcroco/librsvg/xcb-util/libxi/tint2）；b_deps 补 `libtool automake autoconf`（:115）；submodule fallback 修正 `m4/`（:118）；删尾部 `exit 0`（已提交 263517f）。
- `v-pcmanfm/build.sh`：2 处 `git clone`→`gitclone`（libfm/menu-cache）+ 主源码 gitclone（:160）；删尾部 `exit 0`（已提交 cd07e39）。
- `.gitignore`：加 `/compile/tarsrc-git/`（宿主预克隆 gitee/github 仓库缓存，勿入仓）。
- **宿主机预克隆缓存**（`compile/tarsrc-git/`，不入仓）：fk-feh/fk-libcroco/fk-libfm/fk-librsvg/fk-libxi/fk-menu-cache/fk-tint2/fk-xcb__util/util-common-m4/pcmanfm；分支已按 build.sh 对齐（libcroco@0.6.13/librsvg@2.40.21/libfm@1.3.2/tint2@16.1/pcmanfm@1.3.1）。

> **⚠️ 待办**：base 镜像 libgtk 缺符号（3.3.2-1）需镜像层修复（重烤 gtkmm224-2 含 u-gtk 改造）才能真正解除 CI 依赖；本次验证依赖拷贝改造版 libgtk（临时），**非 CI 可复现**。远端已有新镜像但本次未拉取。

##### 3.3.4、CI feh stage 复现 xcbutil m4 submodule 失败——修复（2026-11-13，gitac CI 实跑复现）

> **背景**：3.3.3 落地 gitclone 机制后，gitac CI（`bash buildx.sh gtk224`，用户跑）在 **feh stage** 真实失败复现，非本地猜测。CI 错误：
> ```
> #30 [feh 1/1] —— sh /src/w-feh/build.sh b_deps → imlib2 OK → sh /src/w-tint2/build.sh xcbutil
> cp: can't stat '/src/../tarsrc-git/util-common-m4': No such file or directory
> make: *** No rule to make target 'install'.  Stop.
> == doExec FAIL: bash /src/w-tint2/build.sh xcbutil (rc=1) ==
> ```

**根因**：CI 构建上下文**不带 `compile/tarsrc-git`**（`.gitignore` 排除 + Dockerfile 只 `COPY ./src /src`）→ 容器内 `/src/../tarsrc-git` 不存在 → `gitclone` 缓存未命中（回落网络 clone，xcb-util 主仓库 OK）；但 xcbutil 里 m4 submodule 处理**无条件 sed 指向 `/src/../tarsrc-git/util-common-m4`**（原 w-tint2:118）→ `git submodule update --init` 从不存在路径拉取失败 → `test -f m4/xcb_util_common.m4` 不成立 → fallback `cp -a /src/../tarsrc-git/util-common-m4 m4` 也因源不存在报 `can't stat`（即 CI 报错行）→ `./autogen.sh` 无 m4 宏/无 configure → `make` 无 install 目标 → `doExec FAIL`。即 **3.3.3 的 submodule fallback 只考虑了本地缓存存在，没考虑 CI 无缓存**。

**修复（w-tint2/build.sh xcbutil，:121-126）**：m4 缓存路径只在**存在时**才 sed 指向缓存（本地构建行为不变）；缓存不存在（CI）→ **保持原始 freedesktop URL** 走网络 `git submodule update --init`；该步失败（`git://` 在 CI 常被禁）再回落 **gitee `g-system/util-common-m4` 镜像** clone（缓存即从该源克隆，非换源）：
```sh
M4CACHE=${GITCACHE:-/src/../tarsrc-git}/util-common-m4
test -d "$M4CACHE/.git" && sed -i "s^git://anongit.freedesktop.org/xcb/util-common-m4.git^$M4CACHE^g" .gitmodules
git submodule update --init 2>&1 | tail -1
test -f m4/xcb_util_common.m4 || { rm -rf m4; test -d "$M4CACHE/.git" && cp -a "$M4CACHE" m4 || git clone --depth=1 https://gitee.com/g-system/util-common-m4 m4; }
```

**验证（builder-awe，2026-11-13）**：
- **缓存路径**（默认 GITCACHE）：`sh /src/w-tint2/build.sh xcbutil` → `m4/xcb_util_common.m4` 生成 + `libxcb-util.a` 落 `/usr/local/lib` + configure/make/make install 全过（RC=0）。
- **无缓存路径**（模拟 CI `GITCACHE=/nonexistent`）：`.gitmodules` 保持原始 `git://anongit.freedesktop.org/...` 未 sed；`git submodule update` 失败后回落 `git clone https://gitee.com/g-system/util-common-m4 m4` → `m4/xcb_util_common.m4` 生成（remote 确认 gitee g-system）。**两条路 m4 均就位**，CI 不再 `cp can't stat`。

> **⚠️ 与 3.3.2/3.3.3 关系**：本修复只解决 **m4 submodule 获取**（xcbutil 的依赖宏）；feh stage 后续仍可能因其他依赖（imlib2 等）失败，但 m4 卡点已解。

### 4、镜像四次分析与 rootfs 图标排查（2026-11-14）

#### 4.1、alpine-compile-2-dbg 镜像四次分析（2026-11-14，本次远端又更新）

##### 4.1.1、远端更新确认

| 项 | 三次分析（11-13） | 本次（11-14） |
|---|---|---|
| RepoDigest | `sha256:180783c48e60...` | **`sha256:e3382bfef70e...`** |
| Image ID | `48517084f2e1` | **`8608e2df11f1`** |
| BUILDDATE | 2026-11-13_03:11:19 | **2026-11-14_01:48:16** |

`docker pull` 返回 `Downloaded newer image`；label `github.com.infrastlabs.docker-x11base.builtdate = 2026-11-14_01:48:16`。

##### 4.1.2、本次构建范围与结果（产物 mtime 判定，2026-11-14 01:48~01:52，约 4 分钟）

**7 个组件成功**，静态链接**全部通过**（`readelf -d` 无 NEEDED = 静态）：

| 组件 | 大小 | mtime |
|---|---|---|
| hsetroot / hsr-outputs | 2.3M / 1.0M | 01:48:53 |
| gpicview | 13.0M | 01:49:13 |
| scrot | 2.5M | 01:50:34 |
| engrampa | 13.4M | 01:50:35 |
| geany | 15.3M | 01:51:31 |
| pcmanfm | 13.7M | 01:52:28 |
| lxde（lxappearance + lxtask） | 36.4M / 12.8M | doExec 有日志（产物 mtime 为 tar 包内时间） |

doExec 日志目录 8 个：`u-gtk`/`v-engrampa`/`v-geany`/`v-gpicview`/`v-lxde`/`v-pcmanfm`/`w-hsetroot`/`w-scrot`，与上表 7 组件 + u-gtk 依赖一致。

##### 4.1.3、对比三次分析的 4 空组件：真正修复 2 个，另 2 个是"基础镜像残留"假象

| 上次空组件 | 上次根因 | 本次 |
|---|---|---|
| **scrot** | 缺 autoconf-archive（autoreconf 失败） | ✅ **本次构建成功**（2.5M 静态，mtime 01:50:34） |
| **pcmanfm** | menu-cache clone 断连 | ✅ **本次构建成功**（13.7M 静态，mtime 01:52:28） |
| feh | gitee clone 断连 | ⚠️ 产物 mtime **2026-02-06** = 基础镜像残留；本次开关 `COMPILE_FEH=no` |
| tint2 | xcb-util 缺失 | ⚠️ 产物 mtime **2023-12-30** = 基础镜像残留；本次 `COMPILE_TINT2=no` |

##### 4.1.4、cachesrc 快照机制在 CI 真实生效（docs 六章 5.4 的产物）

镜像内 `/rootfs/usr/local/static/.logs/cachesrc/` 两日志时间戳与 BUILDDATE 吻合：

- `gitclone.log`：`2026-11-14 01:49:01|v-engrampa|v-engrampa.fk-engrampa-v1.14.1.tar.gz|v1.14.1|4111144B|MISS|8680ms|net|https://gitee.com/g-system/fk-engrampa` → gitee clone **成功**（三次分析里 feh 同源 clone 是 `Recv failure: Connection reset by peer`）。
- `downcatfile.log`：`gpicview|0.2.5|...|165106B|CACHE|0ms|tarsrc|...` → **tarsrc 命中 0 毫秒**。

##### 4.1.5、xrandr / dunst / rofi 无产物根因（非构建失败）

`buildx.sh` 传 `COMPILE_XRANDR=yes`/`COMPILE_DUNST=yes`、Dockerfile 两处 `ARG` 默认也是 `yes`、stage 内 `test "yes" != "$COMPILE_XRANDR" && exit 0` 逻辑通过，但**最终镜像无 xrandr/dunst 目录**（TARGETPATH 分别为 `/usr/local/static/xrandr`、`/usr/local/static/dunst`）。

根因：**`compile/src/Dockerfile:599-601` 的三行 COPY 被注释**：

```dockerfile
# COPY --from=xrandr ${STATIC} /rootfs${STATIC}
# COPY --from=dunst ${STATIC} /rootfs${STATIC}
# COPY --from=rofi ${STATIC} /rootfs${STATIC}
```

→ stage 会构建，但产物**不进最终镜像**。

##### 4.1.6、产物来源分层（避免误判"本次成功"）

- **本次构建**（mtime 2026-11-14）：hsetroot、gpicview、scrot、engrampa、geany、pcmanfm、lxde。
- **基础镜像残留**（mtime 2023-12-02 ~ 2026-02-06）：feh(2026-02-06)、tint2(2023-12-30)、lxde 部分(2023-12-30)、fluxbox(2023-12-02)、openbox(2024-04-08) 等。
- **开关关闭**（空目录，COPY 空 stage）：gsm、pasystray、pavucontrol、xfce4。
- **`temp1`**：common.sh 默认 TARGETPATH 残留目录。

#### 4.2、rootfs-dbg 运行"rsvg 已有效但找不到图标"排查（2026-11-14）

##### 4.2.1、现象与前提

rootfs-dbg 里跑 GTK2 静态应用，判断 librsvg 已生效，但仍提示找不到图标。历史同类验证记录：`docs/2026/11051758-v-oth-impl01.md` 五章（hdmi 容器 `docker-hdmi-desktop-desktop-1`，Ubuntu 22.04 + TigerVNC 1.13.1，Greybird + Papirus 效果图）。

##### 4.2.2、三原因（镜像内实测，缺一不可）

**原因 A：CI 编译的二进制没有 librsvg 符号（关键，推翻了"rsvg 已有效"的前提）**

```sh
readelf -s /rootfs/usr/local/static/engrampa/bin/engrampa | grep -i rsvg     # 0 个
readelf -s ... | grep svg_fill                                              # 0 个
```

Papirus 是**纯 SVG 图标集**（历史实测 509 svg / 0 png），无 SVG 解码器就解不了。历史结论（`11051758:150-155`）：必须在 `builder-awe` 编——awe 的 `/usr/local/lib/libgdk_pixbuf-2.0.a` 是 meson `-Dbuiltin_loaders=png,jpeg,svg`（`nm` 见 `U _gdk_pixbuf__svg_fill_vtable`），配 `librsvg-2.a`(2.40.21) + `libcroco-0.6.a`；**alpine 系统包 gdk_pixbuf 无 svg builtin，产物照样不显示**。

**原因 B：镜像里没有图标/主题资源**

```sh
ls /usr/share/icons/    # No such file or directory
ls /usr/share/themes/   # No such file or directory
find /usr/share/icons/Papirus* -name '*.svg' | wc -l   # 0
```

**原因 C：无 gtkrc 设 `gtk-icon-theme-name`** → GTK 落默认 hicolor（历史：Greybird 的 `gtk-2.0/gtkrc` 无 `gtk-icon-theme-name`，`11051758:157-158`）。

##### 4.2.3、解决三件套（历史已实测通过）

1. **二进制必须是 awe 编译版**（内含 svg loader + librsvg）；
2. **资源到位**：`/usr/share/icons/Papirus` + `/usr/share/themes/Greybird`，运行带 `GTK_DATA_PREFIX=/usr`；
3. **`GTK2_RC_FILES=/tmp/greybird-papirus.gtkrc`**，内容：
   ```
   gtk-theme-name = "Greybird"
   gtk-icon-theme-name = "Papirus"
   ```
   另需 `HOME=<可写>`（icon cache 可写）+ `DISPLAY=:NNN`。

##### 4.2.4、结论：不是 musl 环境问题

同一 awe 编译的 engrampa 在 hdmi 容器（**glibc / Ubuntu 22.04**）显示 Papirus 彩色图标（`11051758` §5 实测：14 彩色图标行、特征色 (54,172,163)/(192,54,48)/(57,116,225)）；alpine headless 用户跑同样通过（`11051758:193-197`）。障碍是 **gdk_pixbuf 的 svg builtin loader（编译侧）+ 运行时图标/主题资源与 gtkrc（部署侧）**，与 musl/glibc 无关。

##### 4.2.5、订正与实测（2026-11-14，rootfs-dbg 按原 CMD 起容器复现）

> **订正（2026-11-14）**：4.2.2 的"原因 B/C（镜像无 `/usr/share/icons`、无主题、无 gtkrc）"是在
> **`alpine-compile-2-dbg` 的 `/rootfs/` 树**上判断的，**对 rootfs-dbg 运行态不成立**。用户指出
> rootfs-dbg 的主题/图标/配置由入口准备好——实测确认。本节为起容器实测结果。

**入口链路（`rootfs/src/Dockerfile`，`bash buildx.sh rootfs`）**：

- `CMD ["bash","-c","test -f /rootfs/.core-init-lock || bash /rootfs/.core-init; exec /entry.sh"]`
- `/rootfs/.core-init`（141B）：`cp -a /rootfs/files1/* /` → `cp -a /rootfs/files2/* /` →
  `cp -a /rootfs/res_ubt_share/* /` → `bash /xconf.sh core`
- 资源来自 `res_ubt_share`（`FROM ...ubuntu---22.04` stage COPY）：**Papirus 15041 个 SVG**（0 PNG）、
  `Papirus-Bunsen-*`、Greybird/Greybird-compact/Greybird-dark、wqy 字体、locale。
- 实测容器 `rootfs-dbg-x`（`VNC_OFFSET=311`，`START_SESSION=startfluxbox`）：
  `/usr/share/icons/` 有 Papirus、`/usr/share/themes/Greybird*` 齐全，`Xvnc -ac :311` + fluxbox 已起。

**"找不到图标"实测复现（lxtask / geany，2026-11-14）**：

```sh
(lxtask:532): Gtk-WARNING **: Error loading theme icon 'application-exit' for stock: Unrecognized image file format
```

- Papirus 全 SVG（`7119 svg / 1 theme / 1 cache`，**0 png**）；目标图标
  `Papirus/16x16/actions/application-exit.svg` 存在。
- **rootfs-dbg 里的产物被 UPX 压缩**（`upx -l`：`13468584 -> 5524780  41.02%`）→
  `strings`/`grep -a` 全部 0 命中（`pixbuf`/`rsvg`/`icon_theme` 全 0），**静态分析失真**；
  `readelf -s` 无符号（stripped）同样失效。
- 按用户指示从 **`alpine-compile-2-dbg` 取未压缩原文件**（13468584B，与 `upx -d` 一致）带入容器分析：
  - `strings` 出的 gdk-pixbuf 源文件只有 **`io-jpeg.c` + `io-png.c`**，**无 `io-svg.c`**
  - `svg_fill=0`、`croco=0`（对比 `11051758:152`：awe 版 `nm` 见 `U _gdk_pixbuf__svg_fill_vtable`）
  - 即 CI 产物 gdk-pixbuf 的 **`builtin_loaders=png,jpeg`（缺 svg）**；lxtask、geany 一致。
- 排除 UPX 因素：原文件运行同样报 `Unrecognized image file format`（`lxtask.orig:897`）。
- 同二进制在 rootfs-dbg（有 Papirus/Greybird）与 `alpine-compile-2-dbg` 行为一致 →
  **资源侧无问题，是编译侧 gdk-pixbuf 无 svg loader**。

**结论（推翻 4.2.2 的原因 B/C，确认原因 A）**：

1. **根因 = 原因 A**：CI（`alpine-compile-2-dbg`）链的 gdk-pixbuf **只有 png/jpeg 内置 loader**，
   解不了 Papirus 的纯 SVG → 菜单项/关于窗口图标全部打叉。
2. 原因 B/C（资源、gtkrc）**不是问题**——镜像入口已备好 Papirus + Greybird。
3. 与 4.2.2 的原因 A 一致，且与 musl 无关（同二进制在 glibc 容器同样缺 svg loader）。
4. **修复方向**：改 `compile/src/u-gtk/build.sh` 的 gdk-pixbuf 构建参数为
   `-Dbuiltin_loaders=png,jpeg,svg` 并链 `librsvg-2.a` + `libcroco-0.6.a`
   （即 `builder-awe` 那套，`11051758:150-154`），**不能**手工往 `.a` 打补丁（AGENTS 五章 2）。

#### 4.3、图标打叉排查续：UPX 干扰、取原文件法与 gdk-pixbuf svg loader 机制（2026-11-14）

##### 4.3.1、UPX 压缩干扰静态分析

rootfs-dbg 里的产物**被 UPX 压缩过**：`upx -l` 报 `13468584 -> 5524780  41.02%`。后果是静态分析全部失真：

- `strings` / `grep -a` 对 `pixbuf`/`rsvg`/`croco`/`icon_theme` **全 0 命中**（原文件实际有 `pixbuf=24`、`gdk_pixbuf=8`、`rsvg=5`）
- `readelf -s` 无符号表（stripped）同样失效（`NEEDED` 查询返回空，误判"无动态依赖"）
- **取原文件法**：`docker run --entrypoint sh alpine-compile-2-dbg -c 'cat /rootfs/usr/local/static/lxde/bin/lxtask' > /tmp/lxtask.orig`
  取未压缩版（13468584B，与 `upx -d` 后一致）再分析。

##### 4.3.2、原文件证据（lxtask / geany 一致）

| 检查 | 结果 |
|---|---|
| gdk-pixbuf 内置 loader 源文件 | 仅 `io-jpeg.c` + `io-png.c` |
| `io-svg.c` | **无** |
| `svg_fill`（对应 `_gdk_pixbuf__svg_fill_vtable`） | **0** |
| `croco` | **0** |

原文件（未 upx）实跑同样报 `Unrecognized image file format`（`lxtask.orig:897`）→ **排除 UPX 是根因**。

##### 4.3.3、上游 gdk-pixbuf meson 机制（划清修法边界）

`u-gtk/gdk-pixbuf-2.42.8-lxtask-static.patch` 已做三处：`loaders['svg']`（`sources: io-svg.c`、`enabled: true`）、
`meson_options.txt` choices 加 `svg`、顶层 `loaders_deps += librsvg_dep`（`required: false`）。

上游 `gdk-pixbuf/meson.build`（实测 `/tmp/gdk-pixbuf/gdk-pixbuf/meson.build`）：

- **第 162 行自动生成 `-DINCLUDE_<name>`**（`cflag_for_included_loader = ['-DINCLUDE_@0@'.format(name)]`）→
  `io-svg.c` 与 `gdk-pixbuf-io.c` 里的 `#ifdef INCLUDE_svg` 会被满足，**无需在 patch 手加**
  （本轮试过手加 `-DINCLUDE_svg`，确认与上游重复，已回滚）。
- svg loader 编成**独立静态库** `libstaticpixbufloader-svg.a`（`static_library('staticpixbufloader-@0@')`），
  经 `included_loaders_deps += declare_dependency(link_with: mod)` 链进主库。
- 与 AGENTS「gdk-pixbuf 图标坑」同源：**loader 是独立 `.a`，必须真正链进产物**，否则符号不落地。

##### 4.3.4、待确认（本轮未验证）

- `alpine-compile-2-dbg` 内 `/rootfs/usr/lib/`、`/rootfs/usr/local/lib/` **均无 `libgdk_pixbuf*`**，
  也无 `gdk-pixbuf-2.0.pc` → 疑 CI 未跑 `u-gtk`，lxtask 实际链的 gdk-pixbuf 来源待定。
- 若 CI base 不含 u-gtk 产物，则 svg loader 不可能进产物（与 4.3.2 现象一致）。

##### 4.3.5、修复方向（用户指定只改 `u-gtk/`）

1. 确认 `u-gtk/build.sh` 的 `meson build` **无 `build/` 残留复用旧 `builtin_loaders`**（meson 不自动 reconfigure）；
2. 确认 librsvg 的 `.pc` 可达（`PKG_CONFIG_PATH` 已前置，`build.sh:8`），否则 `required: false` 静默跳过；
3. 确认 `libstaticpixbufloader-svg.a` 经 `included_loaders_deps` 真正链进 `libgdk_pixbuf-2.0.a`
   （判定标准：`svg_fill` 非 0）。




### 5、第五次拉取分析（rootfs-dbg 第 5 次构建，2026-11-15）

#### 5.1、分析原文（2026-11-15 回复用户）

**镜像确认**：本地原 `33bef8ffdef4`（09:11，旧）对不上你一小时前构建；重新 `docker pull` 拉到 **`9a85821a09c2`**（13:36，277MB，digest `674f48a…` 与你 CI 推送一致）。访问通道：宿主 docker-data 挂载 ENOSPC 使 `exec/cp` 失效，改用 **`setsid` 独立后台**（容器内跑、写 `/_ext/tmp/svg/`、宿主轮询）——按你的规则没写脚本、直接拼命令，实测稳定。

**开关集（compile/buildx.sh 254-292）**

本次启用 **10 个 stage**：u-gtk、v-lxde、v-geany、v-engrampa、v-gpicview、w-hsetroot、w-scrot、x-dunst、x-xbindkeys、x-xrandr。
其余空 bins（gsm/pasystray/pavucontrol/perp/rofi/xfce4）= **开关关闭未构建，非失败**；dropbear/pulseaudio/tigervnc/xrdp/x11vnc/fluxbox/openbox/tint2/feh/xlunch 等有 bin 但开关 `no` = **base 镜像烤入的旧产物**（日志 2023-12~2026-02），非本次。

**失败 3 个（bins 空 + doExec `_exec_result.txt` 非 0）**

**① geany（v-geany，`_exec_result=1|geany`）**
- 日志：`make: *** No rule to make target '../scintilla/libscintilla.la', needed by 'libgeany.la'. Stop.`
- 根因：`build.sh:50` 只 `make -C src main.o libgeany.la`，**未先编 `scintilla` 子目录**；CI 干净树无该库 → libgeany.la 无法链接。
- 对照文档：3.5 节"make -C src main.o libgeany.la 绕 libtool"在**手动验证时 scintilla 已被先前 make 编好**，CI 干净树暴露缺口。**修复：make 前加 `make -C scintilla`**。

**② engrampa（v-engrampa，`_exec_result=1|engrampa`）**
- 日志：`CC libeggsmclient_la-eggdesktopfile.lo` → `mv: can't rename '.deps/…Tpo': No such file or directory` → `make Error 1` → `libeggsmclient.a MISSING`。
- 根因：`build.sh:89` `make LIBTOOL=true`——LIBTOOL=true 让 `--mode=compile` 变 `true`（空操作），**CI 干净树里 copy-n-paste 子目录编译被跳过** → 无 `.o`/`.Tpo` → mv 失败 → libeggsmclient.a 没产出 → 主链失败。手动验证时该子目录对象已存在（增量），LIBTOOL=true 只影响链接所以通过。
- 对照文档：3.3.1/3.3（engrampa schema patch、批量验证）+ 3.5（libtool 破坏 --start-group）。**修复：objects 阶段不用 LIBTOOL=true（或先 `make -C copy-n-paste` 编对象），LIBTOOL=true 只留链接；主链已走下方手动 xx-clang**。

**③ dunst（x-dunst，`_exec_result=0|libxscrnsaver / 1|dunst`）**
- 日志：`/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lzstd` → `clang-12: error: linker command failed`。
- 根因：`build.sh:87` `DUNST_LIBS=$(pkg-config --static --libs …)` 拉进 `-lzstd`（某静态依赖传递），但 `libzstd.a` 不在静态链路径。**修复：装 zstd-dev（提供 libzstd.a）或从 DUNST_LIBS 剔除 `-lzstd`**。

**对照结论**

本次 3 个失败都是**文档 3.x 手动验证修复在 CI 干净树未完全闭环**：geany/engrampa 的"绕 libtool"做法依赖先前已编对象（增量），干净树暴露子目录/对象未就位；dunst 为新开关组件的静态依赖缺 `zstd`。

#### 5.2、修复进展（2026-11-15 当日下午，本地实证 + 已推送）

##### 5.2.1、验证环境切换（用户拍板）与三组件修复落地

**验证环境变更（2026-11-15 用户拍板）**：
- **构建基准改 `alpine-builder-gtk224-2` 镜像**（本地 `97cdadb8feb5`，按需 pull 最新）；**builder-awe/obox 禁用**（规则过时）——awe 容器+镜像已删（释放 1.27GB）。
- 新起基准容器 **`builder-g224`**（awe 跑法：`/_ext` 挂载 + `/src` 软链宿主导，容器内 `rm -rf /src && ln -s`）。
- **docker-data ENOSPC 坑**（2026-11-15 实测）：`docker run/start` 全挂（连 `alpine` 都起不来，df 却有余）——dind 存储满、mount 层故障；**删 awe 释放空间后恢复**。AGENTS 三章 3.1 已记该坑。
- **tarsrc 缓存仓库拉到最新 `9053314`**（含 `_cache_repo/` x52 源包，geany/dunst 等在）；`_cache_repo` 冲突（origin 新提交同名目录）挪 /tmp 备份后 pull，已 `chown` 回 headless。

**① geany ✅ 本地验证通过（rc=0，`bin/geany` 15.3M static，xx-verify 过，undef=0）**
- 修复链（libgeany.la 依赖逐级暴露，干净树实测）：先 `make -C ctags libctags.la` → `make -C scintilla libscintilla.la` → `make -C src/tagmanager libtagmanager.la` → 再 `make -C src main.o libgeany.la`。commits `9cf6f58`（scintilla+tagmanager）/ `4ffb188`（+ctags）。
- 再修：static-link 前 `mkdir -p $TARGETPATH/bin`（`d9ee063`；否则 `cannot open output file .../bin/geany`）。
- configure 报 `Documentation enabled but rst2html not found`（基准镜像无 docutils）= **非致命**（Makefiles 照常生成、构建继续，CI 亦同）。

**② engrampa ✅ 本地验证通过（rc=0，`bin/engrampa` 13.4M static，xx-verify PASS，未定义符号 0）**
- `348c52d`：去 `LIBTOOL=true`——干净树 copy-n-paste `--mode=compile` 空操作 → 无 `.o`/`libeggsmclient.a`。
- `5283b39`：ENG_SCHEMA_DIR 改 **`-include` 头文件法**——原 `-DENG_SCHEMA_DIR=\"..\"` 引号被 make recipe shell 剥掉 → fr-init.c:682 `use of undeclared identifier 'usr'`（LIBTOOL=true 掩盖的潜伏 bug；gtk224-2 基准复现）。
- caja-extension 此前 build4/5 报阻塞：**手动 `./configure ... --disable-caja-actions` 实测通过**（守卫健全、"Caja support: no"）；build6 干净重跑（免 head 截断）后 configure 未再报——**此前为 runner `head -25` 截断 SIGPIPE（rc=141）假象**，非配置死结。
- log 里 undef=353 为 make 段（libtool 破坏 group）**预期噪音**，手链（xx-clang -static）产物 `undefined_symbols=0` 干净。

**③ dunst ✅ 本地验证通过（rc=0，`bin/dunst` 9.6M static，xx-verify PASS，undef=0）**
- `9f26cd7`：DUNST_LIBS 剔 `-lzstd`（gtk224-2 镜像实测**无 `libzstd.a`**，同 gpicview/w-feh 先例）。
- `284dd8f`：下载改走 **`down_catfile`（common.sh 机制）**——自动 tarsrc 缓存命中（cachesrc.log `CACHE|10ms|tarsrc|x-dunst//dunst-1.13.2.tar.gz` 4685829B）；**勿手写 tarsrc 拷贝（common 已处理）**。`x-dunst` 的 b_deps 自建 libXss.a 正常。
- 教训：调试运行器 `| grep | head -N` 截断会把长输出 build 打成 SIGPIPE（rc=141），**验证重跑须全输出写文件、构建后再 grep**。

##### 5.2.3、rofi 修复（2026-11-15，builder-g224 复现+验证，commit `5a5544e`，详见 11051758 九章 §6）

CI 首次跑通 rofi 报 `meson.build:69 Subproject exists but has no meson.build file`，复现后 **4 处修复闭环**：

| # | 坑（根因） | 修复 |
|---|---|---|
| ① | rofi tarball 自带空占位子目录（git 子模块占位），`mv libgwater-master libgwater` 因目标存在压入内部 → `libgwater/libgwater-d86f990` 嵌套 → meson 报 "Subproject exists but has no meson.build" | 先 `rm -rf` 占位再 mv，后缀通配化（-master / 提交 SHA） |
| ② | build.sh 注释写固定提交 d86f990/2f220a4（文档九章原法）却下载 **master** | 改回固定提交 + `get_src` 加 tarsrc 缓存检查 |
| ③ | **真因**：gtk224-2 缺 xkbcommon（.pc/.h/.a 全无）→ libnkutils 子工程 xkbcommon 版本检查失败（`disabler:true`）→ `nk` 变量全 disabler → `deps += nk.get_variable(...)` → **meson 0.59 静默丢 rofi 可执行目标**（18 vs 30 目标、无任何报错） | b_deps `apk add libxkbcommon-dev libxkbcommon-static` |
| ④ | 链接层两坑：无 `.a` 的 `-lzstd`（gtk224-2 无 libzstd.a）拉动态 `.so` 报 `attempted static link of dynamic object`；gdk-pixbuf svg loader（io-svg.c）引 `rsvg_handle_*` 未扩散 | pkgconfig-static 包装器无 `.a` 的 `-l` **直接丢弃** + 安全网补 `librsvg-2.a libcroco-0.6.a libxml2.a`（lxtask LIBS0 同款） |

**验证 ✅**：`bin/rofi` 9.3M `statically linked, stripped`，`xx-verify` PASS，`rofi -version` → `Version: 2.0.0`，errs=0。

**排查方法论**：meson 0.59 静默丢目标时用 `meson introspect --targets` 数目标（18 vs 30）+ 隔离替换 `dependencies:` 逐组 bisect；**先补真缺依赖（xkbcommon），别先改 meson.build**——补上后原版 `dependencies: deps` 直接生效。

> ⚠️ tarsrc 已本地提交 `88d589c`（x-rofi/ 下 libgwater/libnkutils 换固定提交包、删 master 包），**需用户推 gitee** 供 CI/离线构建使用（我无 gitee 推流凭据）。

##### 5.2.2、pcmanfm 修复（2026-11-15，builder-g224=gtk224-2 基准复现+验证）

**复现**：`b_deps`（libfm + menu_cache）→ `pcmanfm`——libfm() 的 `make install` 因 bin_PROGRAMS（`libfm-pref-apps`/`lxshortcut`，动态链 apk `libgtk-x11-2.0.so` 报 `undefined reference to symbol 'g_module_open'`）失败中断：
- `.a` 三件（libfm/libfm-gtk/libfm-extra）已有手动拷贝逻辑（OK）；
- **头文件只装了 `fm-actions.h`**（`/usr/local/include/libfm-1.0/` 缺 fm-extra/fm-version/fm-xml-file 等）→ 末尾 `ls` 失败 → libfm() rc=1 → b_deps 断；
- **`libfm*.pc` 也没装** → menu_cache/pcmanfm configure 报 `Package requirements (libfm-extra/libfm) were not met`。

**修复（commit `0e0c7e2`，v-pcmanfm/build.sh）**：make install 后手动补两段（同 .a 手动模式）：
1. `find /tmp/libfm/src -name "*.h"` 平铺拷贝全部 88 个头到 `/usr/local/include/libfm-1.0/`（libfm 头互 include 为平铺式 `"fm-xxx.h"`）；
2. 拷 `/tmp/libfm/libfm-{,-extra,-gtk}.pc` 到 `/usr/local/lib/pkgconfig/`（prefix=/usr/local 与落点一致）。

**验证 ✅**：`b_deps_rc=0` + `pcmanfm_rc=0`，`bin/pcmanfm` 13.7M：`statically linked, stripped`、xx-verify PASS、ldd `Not a valid dynamic program`、undef=0；产物含 `etc/xdg/pcmanfm/default/pcmanfm.conf` + `share/pcmanfm/ui/*.ui`。

**源头消错（2026-11-15 二轮，commit `9c44706`）**——用户要求"错误提示从源头解决"：
- 残留错误链：`libfm-pref-apps`/`lxshortcut`（libfm 的 bin_PROGRAMS 工具，pcmanfm 不需要）→ 动态链 apk `libgtk-x11-2.0.so` → 先后报 `g_module_open`（`--as-needed` 丢弃 LIBS 的 `-lgmodule-2.0`）/ `rsvg_handle_*`（gdk-pixbuf io-svg 整链拉入、libtool 拆 `--start-group`）undefined。
- **根治**：`make -k ... bin_PROGRAMS= ` + `make install bin_PROGRAMS=`——命令行覆盖 bin_PROGRAMS 为空（递归 make 经 MAKEFLAGS 传递），工具目标根本不建 → 链接错误从源头消失。
- **实测**：`g_module_open=0 / rsvg=0 / 工具Err=0 / make_warn=0`，make 与 make install 均 rc=0 → **头文件/.pc 由 make install 正常装全**（88 头 + 3 pc），手动拷贝降级为幂等保险（保留无害）。
- 临时实验（去 --as-needed / LIBS 加 --start-group）均验证无效后回退，最终 diff 仅 +`bin_PROGRAMS=` 两处。

**源头消错（2026-11-15 三轮，commit `cc9f02e`；CI 再报 `../../libtool: func__fatal_error: not found` ×6）**：
- **根因**：libtool 模板版本混配——fc-libfm 源 ltmain.sh 引用 `func__fatal_error` 但生成脚本未定义（"not found" 是真致命但函数缺失）。**补定义暴露真实错误** = `cannot build a shared library` ×3（`src/modules/` 的 `pkglib_LTLIBRARIES`：vfs-menu/gtk-menu-actions/gtk-menu-trash 等 6 模块带 `-module -shared` **强制共享**，`--disable-shared` 下 libtool 致命）。
- **根治**：make 加 **`pkglib_LTLIBRARIES=`**（跳过共享模块；pcmanfm 不 dlopen 模块，libfm.a/gtk/extra 核心库正常产出）。
- **实测**：`func_fatal_error=0 / fatal=0`，pcmanfm 13.7M PASS。
- 方法论：libtool `func__fatal_error: not found` = "真致命但函数缺失"——**先临时补函数定义暴露真实错误，再根治触发点**（不是塞函数掩盖）。

### 6、第六次拉取分析与组件根因修复（engrampa libtool 重排、pcmanfm 清理误删，2026-11-16）

#### 6.1、根因与源头方案（含证据 + 同类项排查）

**现状**：`v-engrampa/build.sh` CI 构建里 `make` 段海量 undefined 后靠 `|| log "make link engrampa warn"` 容错、真实产物由下方手动 `xx-clang -static` 直链产出（`err 0, pass`）。用户要求**从源头解决**（make 期就成功链接，不冒错误、不屏蔽）。

**关键事实**：make 段其实**已传完整 LIBS**（`v-engrampa/build.sh:98-99`）：

```sh
make LDFLAGS="$LDFLAGS" FR_LIBS="" \
  LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group"
```

LIBS0 全依赖 + 组，与下方手动直链**完全相同**，但 make 段仍海量 undefined——**不是 LIBS 缺失，是链接走 libtool**。

**根因（与 u-gtkmm generate_extra_defs / libtool group 同一机制，见 11150827-ci-builder-gtkmm-lib.md 2.4.3）**：automake 的 engrampa 链接规则

```
engrampa_LINK = $(LIBTOOL) --tag=CC --mode=link ... -o $@
make: $(engrampa_LINK) $(engrampa_OBJECTS) $(engrampa_LDADD) $(LIBS)
```

**LIBTOOL 参与**，而 libtool 机制：① 把带 `.la` 的 `-l` 展开成绝对路径 + 按 dependency_libs 重排；② `--start-group` 被透传但组内容移出（`--start-group -Wl,--end-group` 中间变空）；③ 连绝对路径 `.a` 也照排。→ group 失效、顺序全乱 → io-svg 引 rsvg、gtk 引 gdk/xcb/XRR、gobject 引 ffi、fontconfig 引 freetype/expat/uuid、cairo 引 pixman……交叉引用单遍全错过 → 海量 undefined。**libtool 本质行为，LIBS 再全也白搭**（注释 97 行自述"libtool 主链会拆散 --start-group 致 undefined(预期失败…)"正是把必然当容错）。

**为何手动直链成功**：`xx-clang -static` 不经 libtool，`--start-group` 原样到 ld → 组内反复扫描 → 交叉引用全解析。

**源头方案（非屏蔽）**：make 链接也直链——覆盖 `engrampa_LINK` 去 LIBTOOL（同 u-gtkmm `extra_defs_gen_generate_extra_defs_LINK` 直链修法）：

```sh
make LDFLAGS="$LDFLAGS" FR_LIBS="" \
  engrampa_LINK="xx-clang -Wall -O2 $(CFLAGS) $(LDFLAGS) -o \$@" \
  LIBS="-Wl,--start-group -lXinerama -lXfixes -lXrandr $LIBS0 -lintl -Wl,--end-group"
```

→ make 直链 + 完整组 → 链接成功、undefined 清零；`make link engrampa warn` 容错可删，下方手动直链可退化为兜底/删除（保留 xx-verify 校验）。

**同类项排查**（同"make 只编对象 + 手动直链"被 libtool 重排逼成手链的模式）：`v-geany` / `v-pavucontrol` / `v-gpicview` / `v-pasystray` 同款——均可 `xxx_LINK` 直链覆盖源头修（排优先级，用户定）。

**待办**：~~容器验证 `engrampa_LINK` 直链覆盖后 make 链接成功（undefined=0）→ 落地 `v-engrampa/build.sh`~~ → **已落地（commit `177ef28`，容器实测 RC=0）**；同类项排队。

> **补充（2026-11-16）：落地验证——实际修法与三个坑（commit `177ef28`）**

**实际改法**（`v-engrampa/build.sh`，区别于 6.1 分析的初稿）：
1. make 覆盖 **`LINK`**（非 `engrampa_LINK`）直链：`xx-clang -static -Wl,--strip-all -Wall -O2 $(CFLAGS) $(LDFLAGS) -o $@`（去 LIBTOOL）；
2. `sed` LDADD 的 `../copy-n-paste/libeggsmclient.la` → `../copy-n-paste/.libs/libeggsmclient.a`；
3. 删旧"warn 容错 + 手动 xx-clang 直链"段，产物改用 make 产出（`make` 失败即 `exit 1`，不再屏蔽）。

**三个坑（实证）**：
- **`engrampa_LINK` 变量不存在**——engrampa 程序链接走自动 make 通用 **`$(LINK)`**（src/Makefile:769 规则 `$(LINK) $(engrampa_OBJECTS) $(engrampa_LDADD) $(LIBS)`；LINK 定义 286 行 `$(LIBTOOL) --tag=CC ...`）。第一版覆盖 `engrampa_LINK=` 无效（undefined 照旧）。
- **LDADD 的 `.la`**：直链后 clang 报 `linker command failed`（无 undefined）——`libeggsmclient.la`（libtool 描述文件）被 clang 当输入不识别；旧手链用的就是 `.libs/libeggsmclient.a`。sed 换 `.a` 后过。
- **LDFLAGS 无 `-static`**：engrampa() 不 export LDFLAGS（common.sh 默认非静态），覆写的 LINK 里 `$(LDFLAGS)` 缺 -static → 产物**动态链接**（xx-verify FAILED）；LINK 覆盖里显式加 `-static -Wl,--strip-all` 解决。

**实测结果**：make 期链接成功、undefined 清零（CI 海量错误消失）；产物 14.0MB `statically linked, stripped` + `xx-verify PASS`；`err 0, pass`，**77s**（原 115s，不再有容错重链）。

**方法论沉淀**：自动化 bins 链接若走 automake 且无显式 `xxx_LINK`，通用 `$(LINK)` 覆盖最有效；直链后注意 LDADD 的 `.la` 与 `-static` 显式性——三步缺一不可。

#### 6.2、pcmanfm 无二进制根因定案与修复：clear.sh handAdd 段 rm -rf 误删（2026-11-16，已提交推送）

> **背景**：真机验证表（11140827 二章 3.3）pcmanfm 长期「无二进制文件、部署仍失败」。前期多轮排查把矛头指向**编译失败**（CI 干净环境、日志断在 menu_cache 段），但始终没找到编译日志里的硬错误——因为**编译根本没失败**。本轮换思路：不查「怎么编的」，查「编出来的二进制去哪了」。

##### 6.2.1、排查过程（undock 逐层取物，非 docker pull）

**前提与坑（复盘）**：
- `docker pull x11-base:alpine-compile-2-dbg` **在本地失败**（overlay 盘 `no space left on device`，`df` 显示 `/` 93–95%）。**但这不是真因**——本地盘满只影响 docker 落地层，`undock` 直接从 registry/OCI cache 解包，**不需要 docker 层**。改用 undock 缓存：`~/.local/share/undock/cache/docker-<hash>/`（**之前已拉过一次**，cache 在）。
- **undock cache 不记 tag**：每个 `docker-<hash>/` 目录只有 `index.json`+blobs，`index.json` 的 manifest 无 ref name。**靠 `blobs/sha256/<config>` 的 `history` 识别镜像身份**（`created_by` 的 `COPY ./src /src`、`NOCACHE`、`LABEL vendor`、`COPY /rootfs /rootfs` 等特征行），不能只看目录名/大小。
- **`alpine-compile-2-dbg` 不是单一镜像**：仓库里同时存在**编译基座**（ff base，`f3f26e4...`，history 到 `bash /src/u-gtk/build.sh b_deps` 为止，`/usr/local/static/temp1` 为空）和 **ff 组装输出**（`71b4340f...`，history 有 `COPY /rootfs /rootfs` + 组件 `COPY /usr/local/static ...` + `find /rootfs${STATIC}`，含 `/rootfs`）。用户强调 `compile="alpine-compile"`（V2 TEST, AVOID DBG）是**有意**复用两年旧包——**基座选哪个与 pcmanfm 问题无关**，别再往编译基座方向查。
- 镜像 `layer` 是 gzip 压缩的 `blobs/sha256/<digest>`，**逐层 `gzip -dc | tar -tf` 探目录**（`tar -tf` 只看清单不落盘，快）；要取物再 `gzip -dc | tar -xf -C /tmp/... --wildcards 'path/*'`（**只解相关路径**，避免 300M+ 层全解爆盘）。

##### 6.2.2、关键事实链（最终根因的证明）

1. **`alpine-compile-2-dbg`（ff 组装输出，`71b4340f`）的 `/rootfs/usr/local/static/pcmanfm/bin/pcmanfm` 存在**：38,928,392B（38.9M，`2023-12-02` 时间戳 = 两年前的旧构建），含 bin/etc/include/lib/share 完整树。**→ pcmanfm 二进制在 `bin2` 源里是有的**。
2. **rootfs/src/Dockerfile 组装链**：`bin2` stage（`FROM x11-base:${COMPILE_IMG}`，rootfs/buildx.sh 传 `alpine-compile-2-dbg`）→ `COPY --from=bin2 /rootfs /rootfs/`（181 行）→ `ADD src/static/clear` → `RUN bash /tmp/static-clear/clear.sh`（183–184 行）。
3. **`clear.sh` 逻辑**：对 `usr-local-static-dir.txt` 每个**非 `#` 行**执行 `rm -rf /rootfs/$one`（目录级）＋对 `*file*.txt` 每个非 `#` 行 `rm -f /rootfs/$one`（文件级）。
4. **`usr-local-static-dir.txt` 里 pcmanfm 有两个区段**：
   - 主 pcmanfm 块（114–125 行）：`bin`/`etc`/`share` 等**都带 `#`**（保留），只有 `include`/`lib`/`share/man` 不带（清掉头/静态库/man，属正常瘦身）——**这没问题**。
   - **`### handAdd` 段第 156 行：`/usr/local/static/pcmanfm`（无 `#`）** → `clear.sh` 对它 `rm -rf` → **删掉整个 pcmanfm 目录（含 bin/pcmanfm）**，把主块的「保留 bin」**完全覆盖**。
5. **156 行来源**：`git blame` → commit `8658ae5`（**2024-09-25**，`sq: rfs>> /rootfs/res_ubt_share...`）加进 handAdd 段，`rm -rf` 语义一直生效到 2026-11 仍未除。

**→ 闭环**：bin2 源有 pcmanfm ✅ → `clear.sh` `rm -rf /rootfs/usr/local/static/pcmanfm`（156 行）→ 最终 rootfs-dbg 无 pcmanfm ❌。**编译失败是假象，真因是 rootfs 组装的清理清单误删**。

##### 6.2.3、修复与提交

- **修复**：`rootfs/src/static/clear/usr-local-static-dir.txt` 156 行 `/usr/local/static/pcmanfm` → `# /usr/local/static/pcmanfm`（加 `#` 保留）。
- **验证（dry-run 逻辑级）**：对比 `git HEAD`（旧）与工作树（新）的非注释行——旧含 `/usr/local/static/pcmanfm`（删全目录），新只剩 `include`/`lib`/`share/man`（瘦身，bin 保留）。
- **提交（3 个，已推送 `a07898d..d4ff29a`）**：
  - `0b3145a` rootfs/src/static/clear/usr-local-static-dir.txt（修复）
  - `b3c7e6e` docs/2026/11140827-ci-builder-gtk-lib.md（3.3 表订正：状态改「根因已定+修复已提交」）
  - `d4ff29a` docs/2026/README.md（真机验证记录表 + 待办同步）

##### 6.2.4、踩过的坑 / 经验沉淀（供后续排查「组件缺失」类问题）

| 坑 | 教训 |
|---|---|
| 怀疑编译失败、反复查 build.sh/日志 | **组件缺失先分清「没编出来」还是「编出来了被删/没拷」**。判据：编出来 → 在源镜像（bin2/ff）`/rootfs/usr/local/static/<comp>/bin/` 找得到二进制；没编出来 → 源镜像里也没有。 |
| `docker pull` 报 no space 就以为查不了 | **undock 不从 docker 层走**，盘满不挡 undock；或直接用 OCI cache 逐层解包（`gzip -dc blob \| tar -tf`），只解需要的路径。 |
| undock cache 目录无 tag、难认镜像 | 用 `blobs/sha256/<config>` 的 `history` 特征行认镜像（`COPY ./src /src`、`NOCACHE`、`COPY /rootfs /rootfs`、`LABEL vendor`），别靠目录名/大小猜。 |
| 只查编译基座（ff base） | 基座只编 deps 组、`temp1` 空、无组件二进制是**正常**的；组件在各 stage 构建、由 ff 组装 COPY 进 `/rootfs`。要看 `/rootfs` 得查 ff **组装输出**（history 含 `COPY /rootfs /rootfs`）。 |
| 主块注释保留、却没注意 handAdd 重复条目 | 清理清单（clear.sh 的 `*dir.txt`/`*file*.txt`）可能**同一组件出现多次**：一次瘦身（部分注释）、一次 handAdd 全删（无 `#`）。查「保留却仍丢」要 grep 该组件**所有**出现位置，别只看第一处。 |
| 只看 `clear.sh` 逻辑、不追清单来源 | 真正决定删哪的是**清单文件**（usr-local-static-dir.txt 等），`clear.sh` 只是执行器。定位改清单而非改脚本。 |

##### 6.2.5、遗留与后续

- 重建 rootfs-dbg（CI 复跑）确认 pcmanfm 出现在最终镜像（`/usr/local/static/pcmanfm/bin/pcmanfm` + 真机可启动）。
- 顺带复核同类 handAdd 全删条目：`/usr/local/static/misc/share`（158 行）是否也该保留，视 misc 是否需要。
- tint2 / dunst 仍待确认（见 11140827 二章 3.3）。

#### 6.3、tint2 构建日志脏（`=.so` 调试残留）定位与源头处理（2026-11-16，已提交 `a07898d`）

**定位**（undock 解包 rootfs-dbg 镜像 `42db6033bc79`，`--include=rootfs` 绕过 daemon overlay 挂载坏 + undock 对 `bin/egrep` 软链的 FTL bug）：
- 日志在 `/rootfs/files1/usr/local/static/.logs/doExec/w-tint2/tint2.log`（730 行，rootfs 镜像随附构建日志）
- 不干净 = `>>> Compiling TINT2...` 后 **50 行 `=/usr/lib/lib*.so`**（libmount/libmd/libXft/libpng…）——LD** 打印，纯调试残留

**根因**（`w-tint2/build.sh` tint2() 编译段）：
```sh
cat /src/w-tint2/ldd.txt |egrep -v "^#|^$" |while read one; do echo =$one; test -s $one && \cp -a $one ${one}-ex; ...; done
```
`ldd.txt` = 仓库 54 行 `.so` 黑名单（静态链接前把 `lib*.so` 改名 `lib*.so-ex` 防"动态链被优先"），`echo =$one` 把每行 **print 出来**——调试残留（`echo =xxx` 式的确认打印），每次 tint2 构建刷 50 行脏日志。

**源头处理**（commit `a07898d`）：去掉 `echo =$one`——改名逻辑保留、**静默执行**。

**验证**（builder-g224）：重跑 `w-tint2/build.sh tint2` → `err 0, pass`、40 秒、**日志 `=.so` 行数 0**、产物正常（`xx-verify` 随脚本校验）。

**可续**：镜像 `.logs` 还随附其它组件构建日志（`oneBuild-*.log` / `doExec/*/`），同类"日志脏"可逐一排查；tint2 另有 GTK2 `-Wdeprecated-declarations` 编译器警告噪音（非调试残留，可选治理）；dunst 待确认（见 6.2 末尾）。

#### 6.4、镜像 .logs 全局"日志脏"排查汇总（2026-11-16，undock 扫描，未逐一处理）

##### 6.4.1、排查范围与方法

- 对象：rootfs-dbg 镜像（`42db6033bc79`）undock 解出的 `/rootfs/files1/usr/local/static/.logs/`（**211 个日志文件、约 83.7MB**，随镜像构建期归档）。
- 结构：顶层 `oneBuild-*.log` + `<comp>-<sub>.log`（脚本直跑日志，94 个）+ `doExec/<caller>/`（doExec 包装日志，各组件目录含 `_exec_result.txt`）。
- 扫描模式：`undefined reference`(UNDEF) / `attempted static link of dynamic object`(ATTEMPTED) / `^=/usr/lib/*.so`(=so 调试残留) / `error|FAILED|not found|cannot find|MISSING`(ERR) / `warning:`(WARN) / `deprecated`(DEPREC)。

##### 6.4.2、已源头修复（本两轮，见 6.1/6.3）

| 日志 | 脏 | 处理 |
|---|---|---|
| `doExec/v-engrampa/engrampa.log` | **UNDEF 347**（make 链接海量 undefined，被 warn 容错） | `177ef28` LINK 直链源修（6.1） |
| `doExec/w-tint2/tint2.log` | **=so 49 行**（ldd.txt 黑名单 echo 调试残留） | `a07898d` 去 echo（6.3） |

##### 6.4.3、疑真错误（ERR 计数高但行数小——多为 2023-12 历史构建，**本次不处理**）

| 日志 | ERR | 性质待查 |
|---|---|---|
| `tiger-tigervnc.log` | 11 | tigervnc 构建 11 处 error？ |
| `xrdp-xrdp.log` | 8 | xrdp 8 处 |
| `tint2-libxi.log` / `doExec/w-tint2/libxi.log` / `doExec/w-feh/libxi.log` | 8 | libxi 构建 8 处 |
| `oneBuild-lrzsz.log` | 5 | lrzsz 5 处 |
| `oneBuild-libvncserver.log` | 5 | libvncserver 5 处 |
| `oneBuild-libxtst.log` / `tiger-libtasn1.log` / `pcmanfm-libfm.log` / `doExec/v-pcmanfm/libfm.log` | 2-4 | 少量 |

> **用户拍板（2026-11-16）**：这些好些是两年前（2023-12）历史构建日志，先不处理。

##### 6.4.4、噪音类与巨型日志（可选治理，非本仓问题）

- **deprecated/WARN 海量**（GTK2/C 源码弃用 API 警告 + autoconf 过时宏，上游源码 vs 工具链导致）：`u-gtkmm/gtkmm.log`(DEPREC 13140)、`bash_src_u-gtkmm_build.sh_glibmm.log`(9494)、`pangomm/atkmm`(各 ~1900)、`pulseaudio-pulseaudio.log`(WARN 3254)、`pcmanfm-gtk.log`(1049)、`doExec/u-gtk/gtk.log`(1047) 等——可加 `-Wno-deprecated-declarations` 治理（可选）。
- **巨型日志**：`pcmanfm-gtk.log` **74.8 万行**、`doExec/u-gtk/gtk.log` **74.7 万行**、`doExec/u-gtkmm/gtkmm.log` 8.4 万行——完整编译输出（warnings 刷屏），非脏但占空间。

##### 6.4.5、全局结论

- **UNDEF/ATTEMPTED/=so 全组件为 0**（除已修的 engrampa/tint2 两个）——其余组件 make 链接均无海量 undefined、无 `.so` 动态链残留（黑名单改名机制全组件生效）、无其它 `echo =` 调试残留。
- 待深入 = 6.4.3 疑真错误类（用户已拍板暂不处理，两年前历史）。
- 若 CI 重烤后这些历史日志被替换，可届时重新扫描核验。

##### 6.4.6、日志清单（211 个文件，含大小，2026-11-16）

镜像 `.logs`（rootfs-dbg `42db6033bc79` undock：`/rootfs/files1/usr/local/static/.logs/`）完整日志清单，按目录分组、含文件大小：

- **共 211 个文件、约 83.7MB**：
  - 顶层 94 个：`oneBuild-*.log`（48 个，旧 oneBuild 机制直跑日志）+ `<comp>-<子组件>.log`（46 个，如 `tint2-librsvg.log` / `pcmanfm-gtk.log` / `tiger-tigervnc.log` / `xrdp-*.log` / `pulseaudio-*.log` / `fluxbox-*.log` / `suckless-*.log` / `xlunch-*.log` / `xcompmgr-*.log` / `perp-*.log` / `lxde-*.log` 等）
  - `doExec/cachesrc/` 2 个：`downcatfile.log`、`gitclone.log`（缓存命中/下载日志）
  - `doExec/` 21 个组件目录 115 个：`_exec_result.txt`（各调用 rc 留痕）+ 组件 .log + `bash_src_*_build.sh_*.log`（交叉调用日志）

```text
== (根)/ (94) ==
  dropbear-dropbear.log                                         343K
  fluxbox-apkdeps.log                                             2K
  fluxbox-fluxbox.log                                           124K
  fluxbox-fontconfig.log                                         41K
  fluxbox-libxrandr.log                                          10K
  fluxbox-openbox.log                                           369K
  fluxbox-pango.log                                              13K
  lxde-lxappearance.log                                          45K
  lxde-lxtask.log                                                36K
  oneBuild-Xdamage.log                                            0K
  oneBuild-apkdeps.log                                            0K
  oneBuild-atk.log                                                0K
  oneBuild-b_deps.log                                             0K
  oneBuild-dbus.log                                               0K
  oneBuild-dbus_glib.log                                          0K
  oneBuild-dropbear.log                                         344K
  oneBuild-dunst.log                                              0K
  oneBuild-engrampa.log                                           0K
  oneBuild-feh.log                                                0K
  oneBuild-gdk_pixbuf.log                                         0K
  oneBuild-geany.log                                              0K
  oneBuild-gpicview.log                                           0K
  oneBuild-gtk.log                                                0K
  oneBuild-hsetroot.log                                           0K
  oneBuild-imlib2.log                                             0K
  oneBuild-libcroco.log                                           0K
  oneBuild-libflac.log                                            0K
  oneBuild-libfm.log                                              0K
  oneBuild-libogg.log                                             0K
  oneBuild-libopus.log                                            0K
  oneBuild-librsvg.log                                            0K
  oneBuild-libsndfile.log                                         0K
  oneBuild-libvncserver.log                                      21K
  oneBuild-libvorbis.log                                          0K
  oneBuild-libxi.log                                              0K
  oneBuild-libxrandr.log                                          0K
  oneBuild-libxtst.log                                           13K
  oneBuild-lrzsz.log                                             34K
  oneBuild-lxappearance.log                                       0K
  oneBuild-lxtask.log                                             0K
  oneBuild-menu_cache.log                                         0K
  oneBuild-n2n.log                                                9K
  oneBuild-pango.log                                              0K
  oneBuild-pcmanfm.log                                            0K
  oneBuild-rofi.log                                               0K
  oneBuild-scrot.log                                              0K
  oneBuild-su_exec.log                                            1K
  oneBuild-tinc.log                                              12K
  oneBuild-tint2.log                                              0K
  oneBuild-x11vnc.log                                            21K
  oneBuild-xbindkeys.log                                          0K
  oneBuild-xcbutil.log                                            0K
  oneBuild-xlunch.log                                             0K
  oneBuild-xrandr.log                                             0K
  pcmanfm-atk.log                                                20K
  pcmanfm-gdk-pixbuf.log                                        110K
  pcmanfm-gtk.log                                              32.7M
  pcmanfm-libfm.log                                             219K
  pcmanfm-menu-cache.log                                         13K
  pcmanfm-pcmanfm.log                                            76K
  perp-perp.log                                                  56K
  pulseaudio-libflac.log                                        313K
  pulseaudio-libogg.log                                          16K
  pulseaudio-libopus.log                                         34K
  pulseaudio-libsndfile.log                                      43K
  pulseaudio-libvorbis.log                                       25K
  pulseaudio-pulseaudio.log                                     764K
  suckless-dmenu.log                                              5K
  suckless-dwm.log                                                4K
  suckless-st.log                                                 5K
  tiger-libfontenc.log                                            9K
  tiger-libtasn1.log                                             30K
  tiger-libxfont2.log                                            12K
  tiger-libxshmfence.log                                         10K
  tiger-tigervnc.log                                             81K
  tiger-xkb.log                                                  39K
  tiger-xkbcomp.log                                               6K
  tint2-libcroco.log                                             44K
  tint2-librsvg.log                                              41K
  tint2-libxi.log                                                20K
  tint2-tint2.log                                                39K
  tint2-xcbutil.log                                              12K
  xcompmgr-Xdamage.log                                           18K
  xcompmgr-xcompmgr.log                                          13K
  xlunch-imlib2.log                                              84K
  xlunch-xlunch.log                                               2K
  xrdp-dmenu.log                                                  5K
  xrdp-dropbear.log                                               0K
  xrdp-dwm.log                                                    4K
  xrdp-fdkaac.log                                                14K
  xrdp-fluxbox.log                                              123K
  xrdp-libxrandr.log                                             10K
  xrdp-st.log                                                     4K
  xrdp-xrdp.log                                                  19K
== cachesrc/ (2) ==
  downcatfile.log                                                 1K
  gitclone.log                                                    1K
== doExec/u-gtk/ (20) ==
  Xdamage.log                                                    18K
  _exec_result.txt                                                1K
  apkdeps.log                                                     5K
  atk.log                                                        20K
  bash_src_openbox_build.sh_apkdeps.log                           0K
  bash_src_openbox_build.sh_libxrandr.log                         0K
  bash_src_openbox_build.sh_pango.log                             0K
  bash_src_u-gtk_build.sh_atk.log                                 0K
  bash_src_u-gtk_build.sh_gdk_pixbuf.log                          1K
  bash_src_u-gtk_build.sh_gtk.log                                 1K
  bash_src_xcompmgr_build.sh_Xdamage.log                          0K
  env_STATIC_yes_bash_src_w-tint2_build.sh_libcroco.log           0K
  env_STATIC_yes_bash_src_w-tint2_build.sh_librsvg.log            0K
  gdk_pixbuf.log                                                 15K
  gtk.log                                                      32.3M
  imlib2.log                                                     85K
  libcroco.log                                                   42K
  librsvg.log                                                    33K
  libxrandr.log                                                  11K
  pango.log                                                      21K
== doExec/u-gtkmm/ (6) ==
  _exec_result.txt                                                0K
  bash_src_u-gtkmm_build.sh_atkmm.log                           511K
  bash_src_u-gtkmm_build.sh_cairomm.log                          47K
  bash_src_u-gtkmm_build.sh_glibmm.log                          3.8M
  bash_src_u-gtkmm_build.sh_pangomm.log                         649K
  gtkmm.log                                                     5.8M
== doExec/v-engrampa/ (2) ==
  _exec_result.txt                                                0K
  engrampa.log                                                  243K
== doExec/v-geany/ (2) ==
  _exec_result.txt                                                0K
  geany.log                                                      85K
== doExec/v-gpicview/ (2) ==
  _exec_result.txt                                                0K
  gpicview.log                                                    1K
== doExec/v-lxde/ (3) ==
  _exec_result.txt                                                0K
  lxappearance.log                                               19K
  lxtask.log                                                     34K
== doExec/v-pasystray/ (2) ==
  _exec_result.txt                                                0K
  pasystray.log                                                   3K
== doExec/v-pavucontrol/ (15) ==
  _exec_result.txt                                                0K
  bash_src_x-pulseaudio_build.sh_b_deps.log                       2K
  bash_src_x-pulseaudio_build.sh_full.log                         0K
  bash_src_x-pulseaudio_build.sh_libflac.log                      0K
  bash_src_x-pulseaudio_build.sh_libogg.log                       0K
  bash_src_x-pulseaudio_build.sh_libopus.log                      0K
  bash_src_x-pulseaudio_build.sh_libsndfile.log                   0K
  bash_src_x-pulseaudio_build.sh_libvorbis.log                    0K
  libflac.log                                                   312K
  libogg.log                                                     16K
  libopus.log                                                    33K
  libsndfile.log                                                 43K
  libvorbis.log                                                  24K
  pavucontrol.log                                               101K
  pulseaudio.log                                                 33K
== doExec/v-pcmanfm/ (6) ==
  _exec_result.txt                                                0K
  bash_src_v-pcmanfm_build.sh_libfm.log                           0K
  bash_src_v-pcmanfm_build.sh_menu_cache.log                      0K
  libfm.log                                                     173K
  menu_cache.log                                                 12K
  pcmanfm.log                                                    76K
== doExec/v-sysmonitor/ (5) ==
  _exec_result.txt                                                0K
  build_gtop.log                                                  0K
  build_startup_notification.log                                  0K
  build_wnck.log                                                  0K
  gnome_system_monitor.log                                        1K
== doExec/w-feh/ (6) ==
  _exec_result.txt                                                0K
  bash_src_w-tint2_build.sh_libxi.log                             0K
  bash_src_w-tint2_build.sh_xcbutil.log                           0K
  feh.log                                                        31K
  libxi.log                                                      20K
  xcbutil.log                                                    11K
== doExec/w-hsetroot/ (2) ==
  _exec_result.txt                                                0K
  hsetroot.log                                                   28K
== doExec/w-scrot/ (2) ==
  _exec_result.txt                                                0K
  scrot.log                                                      22K
== doExec/w-tint2/ (6) ==
  _exec_result.txt                                                0K
  bash_src_w-tint2_build.sh_libxi.log                             0K
  bash_src_w-tint2_build.sh_xcbutil.log                           0K
  libxi.log                                                      20K
  tint2.log                                                      38K
  xcbutil.log                                                    11K
== doExec/w-xlunch/ (2) ==
  _exec_result.txt                                                0K
  xlunch.log                                                     16K
== doExec/x-dbus/ (3) ==
  _exec_result.txt                                                0K
  dbus.log                                                        1K
  dbus_glib.log                                                   1K
== doExec/x-dunst/ (3) ==
  _exec_result.txt                                                0K
  dunst.log                                                      34K
  libxscrnsaver.log                                              11K
== doExec/x-pulseaudio/ (12) ==
  _exec_result.txt                                                0K
  bash_src_x-pulseaudio_build.sh_libflac.log                      0K
  bash_src_x-pulseaudio_build.sh_libogg.log                       0K
  bash_src_x-pulseaudio_build.sh_libopus.log                      0K
  bash_src_x-pulseaudio_build.sh_libsndfile.log                   0K
  bash_src_x-pulseaudio_build.sh_libvorbis.log                    0K
  libflac.log                                                   312K
  libogg.log                                                     16K
  libopus.log                                                    34K
  libsndfile.log                                                 43K
  libvorbis.log                                                  25K
  pulseaudio.log                                                 33K
== doExec/x-rofi/ (12) ==
  _exec_result.txt                                                1K
  b_deps.log                                                      2K
  bash_src_w-tint2_build.sh_xcbutil.log                           0K
  build_dep_startup-notification-0.12.tar.gz_startup-notification-0.12_libstartup-notification-1.a_https_www.freedesktop.o.log     15K
  build_dep_xcb-util-cursor-0.1.6.tar.gz_xcb-util-cursor-0.1.6_libxcb-cursor.a_https_xorg.freedesktop.org_archive_individu.log     10K
  build_dep_xcb-util-image-0.4.1.tar.gz_xcb-util-image-0.4.1_libxcb-image.a_https_xorg.freedesktop.org_archive_individual_.log     10K
  build_dep_xcb-util-keysyms-0.4.1.tar.gz_xcb-util-keysyms-0.4.1_libxcb-keysyms.a_https_xorg.freedesktop.org_archive_indiv.log      9K
  build_dep_xcb-util-renderutil-0.3.10.tar.gz_xcb-util-renderutil-0.3.10_libxcb-render-util.a_https_xorg.freedesktop.org_a.log     10K
  build_dep_xcb-util-wm-0.4.2.tar.gz_xcb-util-wm-0.4.2_libxcb-icccm.a_libxcb-ewmh.a_https_xorg.freedesktop.org_archive_ind.log     12K
  build_dep_xcb-util-xrm-1.0.tar.gz_xcb-util-xrm-1.0_libxcb-xrm.a_https_github.com_Airblader_xcb-util-xrm_releases_downloa.log      9K
  rofi.log                                                       82K
  xcbutil.log                                                    11K
== doExec/x-xbindkeys/ (2) ==
  _exec_result.txt                                                0K
  xbindkeys.log                                                   5K
== doExec/x-xrandr/ (2) ==
  _exec_result.txt                                                0K
  xrandr.log                                                      6K
```

#### 6.5、c_gtkmm=yes 后 gtkmm 应用验证与修复：四应用全部出 bin（2026-11-16，已修复提交）

> **背景**：commit `a39a4f8`（`bx c_gtkmm=yes`）把 `compile/buildx.sh` 的 `c_gtkmm=no`→`yes`，打开 `COMPILE_PULSE`/`COMPILE_PASYSTRAY`/`COMPILE_PAVUCONTROL`/`COMPILE_SYSMONITOR` 四个 stage。undock 取最新 rootfs-dbg（cache `10208d75`，BUILDDATE `2026-11-16_01:38:13`）核验四应用二进制与日志；随后在 `builder-g224` 实跑修复验证。

##### 6.5.1、验证结果表（修复前 / 修复后）

| 应用 | 修复前（rootfs-dbg 10208d75） | 修复后（builder-g224 实跑） |
|---|---|---|
| **gsm**（v-sysmonitor→`gnome-system-monitor`） | ✅ `bin/gnome-system-monitor` 17.8M static stripped（01:33） | ✅（本就成功，未动） |
| **pulseaudio**（x-pulseaudio） | ⚠️ `bin/pulseaudio` 1.76M + pacat/pactl/pacmd/pa-info **2024-06-17 旧缓存**；`git-version-gen failed`→configure 失败→本次未产出 | ✅ 新产 `bin/pulseaudio` **6.2M**（02:54）+ `libpulse.pc`/`libpulse-mainloop-glib.pc`/`include/pulse/version.h`；`statically linked` `xx-verify=0` |
| **pasystray**（v-pasystray） | ❌ 目录空（无 bin）；`pkg-config` 找不到 `libpulse` → configure 失败 | ✅ `bin/pasystray` **14M** static stripped（03:00），`xx-verify=0`，strings 含 rsvg+pulse |
| **pavucontrol**（v-pavucontrol） | ❌ 目录空（无 bin）；`pulse/version.h not found` → make 失败 | ✅ `bin/pavucontrol` **19M** static stripped（03:02），`xx-verify=0` |

**u-gtkmm（gtkmm 栈库）全 0**：`cairomm`/`glibmm`/`atkmm`/`pangomm`/`gtkmm` 均 `0|`（`doExec/u-gtkmm/_exec_result.txt`）——依赖库本身没问题。

##### 6.5.2、根因（三个叠加，全部修复）

**① x-pulseaudio `git-version-gen failed`（源头）**：gitclone 快照恢复的 `.git` 无 version tag（`git describe` → `fatal: No names found`）且无 `.tarball-version`；`configure.ac:24` 用 `m4_esyscmd(./git-version-gen .tarball-version)`，只要存在 `.tarball-version`（内容**数字开头**）即读它、不依赖 git describe。→ configure 失败 → `src/Makefile` 未生成 → `make install` 无目标 → **`libpulse.a`/`pulse.pc`/`pulse/version.h` 均未装**（files1 pulseaudio 目录只有 bin/+etc/，无 lib/include/pc）。

**② 下游两个应用缺依赖**（①的直接结果）：pasystray `pkg-config` 找不到 `libpulse`/`libpulse-mainloop-glib`；pavucontrol `pulse/version.h not found`。

**③ `-lpulsecommon` 版本硬编码错误**（①修好后暴露）：`v-pasystray/build.sh:73`、`v-pavucontrol/build.sh:86` 都硬编码 `-lpulsecommon-13.99`，但 pulseaudio 源码内部 `PA_MAJOR.PA_MINOR=13.13`（`version.h`），实际产物 `libpulsecommon-13.13.a`——**13.99 永远链接不到**（分支名 `br-v13-99-3` ≠ 源码 API 版本 13.13）→ 手动 static-link 也失败。

**验证**（git-version-gen 行为实证）：本地 pulseaudio-src，无 `.tarball-version` → `Failed to determine git revision`；写入 `13.99.3` → 正常输出；写入 `v13-99-3`（v 开头）→ **damaged 被拒**（必须数字开头）。

##### 6.5.3、修复落地（3 个脚本）

1. **`compile/src/x-pulseaudio/build.sh`** pulseaudio()：`gitclone` 后、`bash sam-build.sh` 前，`echo "${PULSEAUDIO_VER#br-v}" > .tarball-version`（`br-v13-99-3`→`13-99-3`，数字开头；git-version-gen 只认数字开头，v 前缀判 damaged）。
2. **`compile/src/v-pasystray/build.sh`** static-link：删硬编码 `-lpulsecommon-13.99`，动态 `PULSECOMMON=$(basename $(ls .../libpulsecommon-*.a|head -1)|sed ...)`（从已装 `.a` glob 取，防版本漂移）；b_deps 检查段同步改通配。
3. **`compile/src/v-pavucontrol/build.sh`** 同 pasystray：动态 `PULSECOMMON` + 检查段通配。

**实跑验证**（builder-g224，先 `b_deps` 再逐应用）：
- `x-pulseaudio/build.sh b_deps`：ogg/opus/flac/vorbis/sndfile 全 `err 0, pass`（库→`/usr/local/lib`）。
- `x-pulseaudio/build.sh pulseaudio`：`err 0, pass`、`statically linked`、`xx-verify=0`（02:54，158s）。
- `v-pasystray/build.sh pasystray`：`err 0, pass`、14M static stripped、`xx-verify=0`（03:00，5s）。
- `v-pavucontrol/build.sh pavucontrol`：`err 0, pass`、19M static stripped、`xx-verify=0`（03:02，45s）。

> 注：pulseaudio 主构建须**先 b_deps**（`dep1="-logg -lopus -lsndfile -lFLAC -lvorbis -lvorbisenc"` 在 configure LIBS，deps 库未装则 `C compiler cannot create executables`）——CI Dockerfile 本就先 `b_deps` 再 `pulseaudio`，符合。

##### 6.5.4、遗留

- 重建 rootfs-dbg（CI 复跑）确认：四应用（gsm/pulseaudio/pasystray/pavucontrol）在最终镜像都有新二进制。
- 真机验证表（11140827 二章 3.3）对应行后续更新。

##### 6.5.5、pasystray make 链接源头修（2026-11-16，commit `56373dc`）

**现象**：CI pasystray 构建 make 段报 `libgtk-x11-2.0.so: undefined reference to 'g_module_open'` 等 → 靠 `|| log "make link step expected to fail (PULSEAUDIO_LIBS lacks libpulsecommon)"` 容错 + 手动 `xx-clang -static` 直链兜底（`err 0, pass` 但日志脏）。用户要求源头解决（同 engrampa）。

**根因（区别于 engrampa）**：

| 项 | engrampa | pasystray |
|---|---|---|
| automake 链接变量 | 通用 `$(LINK)`（无专属） | **专属 `pasystray_LINK`**（`src/Makefile:148`，`$(CCLD)` 直链但**无 `-static`**） |
| 覆盖对象 | `LINK` 有效 | 覆盖 `LINK` **无效**，须覆盖 `pasystray_LINK` |
| 动态原因 | 无（-static 显式后静态） | `-static` 未进链接 → 产物**动态 PIE**；且 `PULSEAUDIO_LIBS` 缺 `-lpulsecommon` |

**修复**（commit `56373dc`）：覆盖 **`pasystray_LINK`** 直链（`xx-clang -static -no-pie -Wl,--strip-all -Wall -O2 -Os`）+ `LIBS` 补全 pulse 链（`PULSECOMMON` 动态获取 13.13：`-lpulse-mainloop-glib -lpulse -lpulsecommon-$PULSECOMMON` + gtk/X 全链 `--start-group`）；删 `|| log 容错` + 手动直链段（屏蔽变源头），make 失败即 `exit 1`。

**验证**（builder-g224 干净重建）：`err 0, pass`、**RC=0**、产物 **`statically linked, stripped` + xx-verify PASS**、无 undefined 无容错行。

**类比沉淀**：automake 程序若存在专属 `xxx_LINK` 须覆盖它（pasystray），无专属才走通用 `$(LINK)`（engrampa）；`-static -no-pie` 显式防动态 PIE。**pavucontrol 同模式待处理**（6.5.4 遗留）。

##### 6.5.6、pavucontrol「make 链接源头修」评估（2026-11-16，结论：不做）

> **用户询问**：第二个待处理项（pavucontrol 同模式源修）内容是什么、要干什么、有什么问题、解决收益确认？是实际有问题吗？
>
> **评估结论**：pavucontrol **没有实际问题**（产物正常可运行），「日志脏」是有意设计（手动直链兜底已成功）。源头修**收益有限（只净日志）、风险较高（可能丢 gtk print 定制）**。**建议不做**。

**要干什么**：把 pavucontrol 从「make 链接失败容错 + 手动 `xx-clang++` 直链兜底」改成「make 直链成功（覆盖 `pavucontrol_LINK`）」，消除 make 段链接失败的脏日志——像 engrampa（`177ef28`）/ pasystray（`56373dc`）那样源头修。

**是不是真有问题**：**构建/产物没有阻塞问题**
- 产物正常：`/usr/local/static/pavucontrol/bin/pavucontrol` **19M `statically linked, stripped`**，`xx-verify=0`（CI 已产出，2026-11-16 03:02）
- 唯一「问题」是**日志脏**（`doExec/v-pavucontrol/pavucontrol.log` 6693 行）：make 段 `undefined reference to symbol '_XGetRequest'`（来自 `libgdk-x11-2.0.so`）+ 容错行 `make link step expected to fail`——**这是有意设计**（make 只产 .o，手动直链兜底），非失败
- configure 的 `gtkmm-3.0` 报错（118 行）是 `--disable-gtk3` 走 gtk2 分支的成功尝试，非问题

**源头修的收益 vs 风险**：

| 项 | 评估 |
|---|---|
| 收益 | 仅日志干净（消 1 条 undefined + 1 条容错），不再手维护直链 |
| 风险 | **高**：pavucontrol 手动直链定制**最多**（`-u _gtk_print_backend_file/lpr_*` 6 个强制符号、`-lpulsecommon-$PULSECOMMON` 动态版本、`libgcc_s.a` 兜底、GTK2 print 后端、`--start-group` 全链）——这些**不会自动进 `pavucontrol_LINK`**，源头修须全搬进 make，易错，且可能丢 gtk print 符号→打印缺功能 |
| 对比 | engrampa（`$(LINK)` 无定制）简单；pasystray（`pasystray_LINK` 定制少）适中；**pavucontrol 定制最多、性价比低** |

**结论**：pavucontrol **没有实际问题**（产物正常可运行），「日志脏」是有意设计（手动直链兜底已成功）。源头修**收益有限（只净日志）、风险较高（可能丢 gtk print 定制）**。**建议不做**，除非要求「日志必须全干净」且愿完整迁移定制。

> **订正（2026-11-16）**：用户后续拍板**改做源头修**（推翻"建议不做"）——pavucontrol 按 engrampa/pasystray 同套路（覆盖 `pavucontrol_LINK` 去 LIBTOOL 直链 + 清 `PULSE_LIBS`/`GUILIBS_LIBS` + `LIBS` 全量 group 直链：pulse/gtkmm/gtk/X 全链含 `-u` 6 符号 + `-lpulsecommon-$PULSECOMMON` 动态版本），make 期即出静态二进制、undefined 清零（消除 make 段 `_XGetRequest` 脏日志）。风险点（gtk print 定制）已全量搬进 `LIBS`（`-u` 6 符号保留），未丢。本地无 gtkmm 栈容器（builder-awe/gtkmm224 镜像不在），**须 CI 实跑验证**（CI compile 镜像含 gtkmm 栈）。

> 佐证（build.sh/Makefile 现状）：`v-pavucontrol/build.sh` 63 行 `make ... || log "make link step expected to fail (PULSE_LIBS lacks libpulsecommon); objects produced"` 容错；83-95 行手动 `xx-clang++ -static` 直链（含 `-u _gtk_print_backend_file/lpr_*` 6 符号 + `-lpulsecommon-$PULSECOMMON` 动态 + `libgcc_s.a` 兜底）。Makefile 137 行 `pavucontrol_LINK = $(CXXLD) $(pavucontrol_CXXFLAGS) $(CXXFLAGS) $(AM_LDFLAGS) $(LDFLAGS) -o $@`（无 `-static`）；329 行 `PULSE_LIBS = -L$(top_srcdir)/../pulseaudio/src/.libs -lpulse -lpulse-mainloop-glib`（相对路径，静态构建时无效）。

#### 6.6、dropbear/openbox undock 取件 + dropbear hdmi 实测登录（2026-11-16）

##### 6.6.1、undock 取件与 hdmi 实测结论（参考 11121650-x-dropbear-auth.md）

**取件**（rootfs-dbg `42db6033bc79` undock：`/rootfs/files1/usr/local/static/`）：
- **dropbear 二进制**：`sbin/dropbear`（187K，static）+ `bin/dropbearkey`（90K）；构建日志 `dropbear-dropbear.log`（**2023-12-02 构建**）
- **openbox 二进制**：`bin/openbox`（2.8M static）+ `bin/obxprop`/`bin/openbox-session`；构建日志 `fluxbox-openbox.log` 等

**hdmi 实测 dropbear 登录**（`docker-hdmi-desktop-desktop-1`，ubt22.04，挂载 `/_ext` 中转）：
1. 拷 `dropbear`/`dropbearkey` 到 `/_ext/tmp/dropbear-test/` → hdmi 内取用；
2. 生成 hostkey（dropbearkey rsa）+ 新建 test 用户（`echo test:test123|chpasswd`，shadow=`$y$` **yescrypt**）；
3. 起 dropbear `-p 2222` → python3 pty 交互 `ssh -p 2222` 输密码；
4. 结果：**`Bad password attempt for 'test'` / Permission denied——密码登录失败**。

**对照记录文档（11121650）判断**：

| 项 | 结论 |
|---|---|
| 实测失败 | **复现文档根因**：静态 `crypt()` 不支持 yescrypt，无法验证 ubt22/24 的 `$y$` shadow（Xshell 密码认证亦同） |
| undock 二进制 | **旧版未修复**：strings 无 yescrypt 符号（构建日志 2023-12-02，早于 11-12 修复）；`/etc/shadow` 的 headless/test 均为 `$y$` |
| 修复是否已在代码 | **✅ 已在**：`x-dropbear/build.sh` 已落地 libxcrypt 集成（`libxcrypt()` 构建 v4.4.28 + `LIBXCRYPT_ALL` 全系，静态内嵌 yescrypt） |
| 干扰排除 | 系统 openssh（22）也拒 test（hdmi openssh 配置禁密码，对照无效）；dropbear `Bad password attempt` 日志即其自身 crypt 验证失败，与 openssh 配置无关 |

**结论**：修复在**源码**（build.sh 的 libxcrypt 集成），但 **rootfs-dbg 镜像是旧烤制**（dropbear 2023-12 未含 libxcrypt）——实测失败是镜像旧二进制的**预期结果**。

**下一步（待办）**：用现 `x-dropbear/build.sh` 在 builder 重跑 dropbear（链 libxcrypt 修复版）→ 新二进制拷 hdmi 实测登录（预期成功，证明修复有效）；openbox 二进制可顺带运行验证（未做）。


##### 6.6.2、openbox 日志/二进制核查 + Dockerfile 尾部 COPY --from 打开（2026-11-16，commit `54870af`）

**openbox 核查（undock 产物）**：
- **二进制正常**：`bin/openbox` 2.8M `statically linked, no section header`（strip 静态）；`obxprop` 同。
- **日志干净**：`fluxbox-openbox.log`（3120 行）**error / undefined / Failed = 0**；仅 151 条 `warning:` / 441 条 `deprecated`（`g_memdup`/`pango_xft_get_context` 等 GTK2/glib 弃用 API 编译警告，非错误非调试残留）；流程 `Configuring→Compiling→Installing` 完整。
- **构建时间**：2024-04-08（旧，同 dropbear 为两年前历史产物）。

**Dockerfile 尾部 rootfs 组装段发现（579-588 行）**：
```dockerfile
# stages: 未用到的stage,会跳过构建
# COPY --from=tiger ${STATIC} /rootfs${STATIC}
# COPY --from=xrdp ${STATIC} /rootfs${STATIC}
# COPY --from=x11vnc ${STATIC} /rootfs${STATIC}
# COPY --from=dropbear ${STATIC} /rootfs${STATIC}   ← 注释
# COPY --from=fluxbox ${STATIC} /rootfs${STATIC}
# COPY --from=openbox ${STATIC} /rootfs${STATIC}    ← 注释
# COPY --from=suckless ${STATIC} /rootfs${STATIC}
# COPY --from=xcompmgr ${STATIC} /rootfs${STATIC}
# COPY --from=perp ${STATIC} /rootfs${STATIC}
# COPY --from=misc ${STATIC} /rootfs${STATIC}
```
- **根因确认（用户指正）**：注释的是**文件尾部 rootfs 组装 `COPY --from=`**（决定组件是否进 `/rootfs`），非 openbox stage 内部旧注释（`/tmp/openbox-install` 时代）；被注释的 10 个 stage 在新重烤时**不拷入 rootfs**（且无 COPY 引用时构建甚至被跳过）。
- undock 到的 dropbear/openbox 产物（2.8M/187K）是**旧镜像层残留**（此前 COPY 打开过），新 Dockerfile 状态下重烤将缺失。
- **用户拍板（2026-11-16）**：这些两年前构建产物当前直接复用历史，**10 行全部打开**（dropbear/openbox/tiger/xrdp/x11vnc/fluxbox/suckless/xcompmgr/perp/misc）。

**落地**（commit `54870af`）：`compile/src/Dockerfile` 去 `# ` 前缀，10 行 `COPY --from=` 全部启用（diff 精确 10 删 10 增）；重烤 rootfs 后这些应用正式进 `/rootfs`。

**后续**：重烤后可 undock 复核 dropbear/openbox 以新构建产物出现；dropbear 修复版登录验证待执行（6.6.1 待办）。

#### 6.7、hsetroot 用法说明（无参=纯黑，2026-11-16）

##### 6.7.1、用户问题：无参执行把桌面变纯黑——是默认行为，非 bug

**现象**：`hsetroot` 不带任何参数执行 → 整个桌面背景变纯黑。

**结论（himdel hsetroot 1.0.5 man 原文）**：*"Without any commands, the background is set to black."* —— 无参默认 `-solid black`（纯黑）。**不是 bug，是默认行为**。本项目 `w-hsetroot`（1.0.5，gitee `g-system/fk-hsetroot`）即此行为。

**正确用法**（himdel 1.0.5 以 `--name` 双横线为主，亦兼容旧式 `-name`）：

| 目的 | 命令 |
|---|---|
| 壁纸（推荐，铺满不变形） | `hsetroot --cover /path/wallpaper.jpg` |
| 拉伸铺满（可变形） | `hsetroot --fill 图片` |
| 居中原尺寸 | `hsetroot --center 图片` |
| 最大宽高比（可留边） | `hsetroot --full 图片` |
| 最大宽高比 + 1px 边框扩展（无黑边） | `hsetroot --extend 图片` |
| 平铺 | `hsetroot --tile 图片` |
| 纯色 | `hsetroot --solid '#1e1e2e'`（或颜色名 / #rgb / rgb:r/g/b） |
| 渐变 | `hsetroot --add c1 --add c2 --gradient 30` |
| 多屏不同壁纸 | `hsetroot --output eDP-1 --cover a.jpg --output HDMI-1 --cover b.jpg` |
| 全屏单图 | `hsetroot --root --fill 图片` |

**其他**：`--alpha 0-255`（透明度）、`--tint/--blur/--sharpen/--contrast/--brightness/--gamma`（图片处理）、`--write 文件`（导出当前图）、`--fg/--bg/--mod/--bitmap/--gray`（xsetroot 风格网格/位图）。

**本项目注意**：

- **imlib2 = 1.7.4 < 1.12.6**：某些操作仅 **< 4096 像素**正确（`docs/2026/11051652-v-oth.md` 4.3.5 ②）——**高分辨率壁纸可能受影响**。
- **建议**：桌面默认壁纸/启动脚本**别裸跑 `hsetroot`**（会黑屏）；要么 `hsetroot --cover <壁纸路径>`，要么 `--solid <颜色>`。
- 多屏需 `xrandr --listmonitors`（或 Xinerama heads）；无 RandR 1.5 走 Xinerama。1.0.5 用 xinerama 处理多屏 outputs（非 xrandr，见 4.3.5 ④）。

##### 6.7.2、xlunch 裸跑空屏/无列表——运行时缺口，非构建 bug（2026-11-16，rootfs-dbg-v5 实查）

**用户问题**：xlunch 裸跑（不带参数）→ 空屏/无列表，图标也没有。

**1、怎么调出全屏应用列表框**

- 直接运行 `xlunch` 就是**全屏列表**（无需参数，默认全屏模式，选中后退出；Esc/右键关闭）。桌面里通常绑个快捷键（如 `Alt+F2` → xlunch）或任务栏按钮。
- 但前提是 `entries.dsv` 存在（否则空屏/无列表）：

  ```sh
  xlunch -i /path/to/entries.dsv      # 指定条目文件
  # 或直接用默认查找：~/.config/xlunch/entries.dsv → /etc/xlunch/entries.dsv
  ```

**2、完整使用方式 / 操作命令（Tomas-M xlunch 0.8.4）**

- **条目文件格式**（entries.dsv，每行一条，分号分隔）：

  ```
  title;icon_path;command
  firefox;/path/to/firefox.png;firefox
  ```

- **生成条目**（从 .desktop 扫描）——genentries 脚本（已装到 `/usr/local/static/xlunch/bin/genentries`）：

  ```sh
  genentries > ~/.config/xlunch/entries.dsv    # 或 > /etc/xlunch/entries.dsv
  ```

- **常用选项**：`-c` 列数 `-r` 行数 `-b` 边框 `-I` 图标尺寸 `-p "提示符"` `--textpadding N` `-B/--background` 图 `--font` 字体、`-n/--noprompt`（隐藏提示，纯图标选择）、`-d/--desktop`（桌面模式，常驻后台）、`-q/--dontquit`（选中后不退出）、`-m/--multiple`、`-W/--windowed`（窗口模式）、`-o/--outputonly`、`-S/--selectonly`、`-U/--shortcuts "atf"`、`-A/--button`、`-R/--reverse`、`-t/--voidclickterminate`、`--focuslostterminate`、`--noscroll`、`--config` 文件。
- **键位**：方向键 / 鼠标移动选中，Enter 执行，Esc 或右键退出（desktop 模式除外）。
- **本项目的运行示例**（`docs/2026/11051001-imlib2-apps.md` 1.6 实测）：

  ```sh
  xlunch -i /tmp/entries.dsv -c 6 -r 1 -b 60 -I 40 --textpadding 10 -p "Run: "
  ```

**3、根因（已实查 rootfs-dbg-v5）**

| 项 | 状态 | 影响 |
|---|---|---|
| `/etc/xlunch/entries.dsv` | 不存在（`/etc/xlunch/` 目录都没有） | xlunch 无条目 → 空屏/无列表 |
| `bin/genentries` | ✅ 有（4992B） | 可手动生成 entries.dsv |
| `/usr/share/icons/Papirus/` 规格裁剪 | 主主题**存在**但被体积裁剪：`16x16/`+`16x16@2x/` **完整 3668 个 SVG**，`42x42/84x84` 仅 20 个（deepin 控制中心），**`48x48/64x64/22x22/24x24/32x32` 无**；Bunsen 变体 `48x48/apps` 仅 1 文件 | 48x48 无图标，**但换 16x16 规格有完整图标**（非全缺） |

- `build.sh:167` 把 Makefile 的 `bash extra/genentries` 注释了 → `make install` 没生成系统 entries.dsv（但 genentries 脚本本身装进了 bin/）。
- 1.6 之前验证成功，是因为在 hdmi 容器（Ubuntu，有完整 Papirus 主题）+ 手动 `-i /tmp/entries.dsv`；rootfs-dbg（Alpine 静态 rootfs）**没 entries.dsv**，且 Papirus 主主题**被体积裁剪**（只留 16x16 完整，48x48 无），所以空/无大图标。

> **订正（2026-11-16）**：根因②初判"Papirus 48x48 全缺"**不准确**——实查 `/usr/share/icons/Papirus/` 主主题**存在**且 `16x16/`+`16x16@2x/` **完整 3668 个 SVG 应用图标**（42x42/84x84 仅 20 个 deepin 控制中心，48x48/64x64/22x22/24x24/32x32 被裁剪无）；Bunsen 变体 `48x48/apps` 仅 1 文件。**换 16x16 规格仍有大量图标**（用户质疑成立）。genentries 解析 .desktop `Icon` → **绝对路径** icon_path，auto-detect 主题失败默认 hicolor，可用 `--theme <name> --size <px> --path <dir>` 指定（`--category` 过滤）。

**解决方向（需用户拍板再动）**：

1. **生成 entries.dsv**：容器里跑 `genentries > /etc/xlunch/entries.dsv`（或 `~/.config/xlunch/`）。
2. **图标路径指向真实存在的图标**：主 Papirus 已有 `16x16` 完整规格——`genentries --theme Papirus --size 16 > ...` 指向 16x16（或手写 entries.dsv 用 `16x16/apps/*.svg`）；若需 **48x48 大图标**则主主题无（被裁剪），要么部署完整 Papirus，要么接受 16x16 放大（Bunsen 变体 48x48 也仅 1 文件，不可用）。

**完整命令（可直接拷贝执行）**：

```sh
# 生成系统级条目：图标指向 Papirus 16x16 完整规格（主主题被裁剪，无 48x48）
mkdir -p /etc/xlunch && genentries --theme Papirus --size 16 > /etc/xlunch/entries.dsv
# 用户级备选：genentries --theme Papirus --size 16 > ~/.config/xlunch/entries.dsv
```

##### 6.7.3、hsetroot XINERAMA missing 与 xlunch genentries `can` 报错——问题-答复成对反馈（2026-11-16）

###### 6.7.3.1、hsetroot `XINERAMA missing`（用户问题 + 答复原文）

**用户问题**：hsetroot 用正确的参数带上图片后，跑运行报错 `XINERAMA missing`；补充：`hsetroot -fill xxx.jpg` 这么跑的，xvnc 是静态编译的、基于 tigervnc。

**答复/调查原文**：

- 本项目 hsetroot（rootfs-dbg-v5 二进制 + `g-system/fk-hsetroot` 源码 + himdel 官方源码）**均不含 "XINERAMA missing" 字符串**；rootfs-dbg-v5 全量搜索（`/usr/local/static` `/usr/lib` `/usr/bin`）也无 → 报错**不来自本项目 hsetroot 产物**，来自 **X 服务器/扩展层**。
- TigerVNC 官方构建默认含 Xinerama，但本项目静态编译**显式 `--disable-xinerama`**（`compile/src/x-tigervnc/build.sh:346`，xorg-server configure）→ Xvnc **无 XINERAMA 扩展** → hsetroot `XineramaQueryScreens`（hsetroot.c:286）失败。
- 用户补充"编译的脚本也在项目内，看参数是否打开了他的支持"→ 确认 `build.sh:346` `--disable-xinerama`（**未打开支持**）。

**关联问答（用户后续两问）**：

1. **"禁用的情况，这个程序如何可以支持设置背景呢？"** → 方案 1 `hsetroot -root -fill xxx.jpg`（`-root` 走单屏 fake，hsetroot.c:282-284/303-306，绕过 Xinerama）；方案 2 改 hsetroot.c：`:286` 后加 fallback（`XineramaQueryScreens` 返回 NULL/0 屏 → `noutputs=1; outputs=&fake`）+ `:303` `if (opt_root)` 放宽 `if (opt_root || noutputs == 1)`（fallback 单屏也填宽高）。
2. **"tigervnc 这个选项禁用会有哪些影响？"** → 影响面：①Xvnc 无 XINERAMA 扩展（客户端 `XineramaQueryScreens`/`XineramaQueryExtension` 失败）②多屏感知客户端回退单屏（`feh --multi-screen`、`hsetroot --output`、GTK/Openbox/lxpanel/tint2/pcmanfm 多屏检测）③单屏显示不受影响（TigerVNC 1.13 用 **RandR** 虚拟屏幕，非 Xinerama）④多屏无实质影响（TigerVNC 官方已弃用 Xinerama 多屏，走 RandR）⑤省 `libXinerama` 依赖（体积，当初 `--disable-xinerama` 目的）。

**结论**：单屏 Xvnc 场景禁用影响小；hsetroot 用 `-root` 或 fallback 即可，无需改 Xvnc 启用 Xinerama。

###### 6.7.3.2、xlunch genentries `can: command not found`（用户问题 + 答复原文）

**用户问题**：xlunch 跑 `genentries --theme Papirus --size 16`（`mkdir -p /etc/xlunch && genentries --theme Papirus --size 16 > /etc/xlunch/entries.dsv`）提示 `can` 没有（`genentries: line 266: can: command not found`）。

**答复/调查原文**：

- fk-xlunch master 源码 `extra/genentries` 266 行**无 `can`**（`for key in "${!applications[@]}"` 循环）——运行版与源码不一致。
- 运行版 genentries 是 **UPX 4.22 压缩 ELF**（`upx -d` 解压得 `#!/bin/bash` 脚本）；**解压版 266 行无 `can`**，且**解压版跑通**（`Htop;/usr/share/pixmaps/htop.png;xterm -e htop`，rc=0），**UPX 版报 `can`**——UPX 压 bash 脚本致运行故障。
- 用户补充"rootfs 组装时，upx 统一处理的"→ `rootfs/src/static/clear/clear.sh:24` 统一 `upx -7` 所有 `/bin` `/sbin` 文件（除 `3rd/bin/upx`）→ **genentries（`#!/bin/bash` 脚本）被 UPX `--shell` 压成 ELF** → 运行时解压执行报 `can`（UPX 压 bash 脚本缺陷）。
- 用户"不能用 file 判断，它没装，看纯粹 shell 脚本有没有方法判断"→ **纯 bash 内置 `read -N4` 读前 4 字节判 ELF 魔数 `\177ELF`**（零外部命令，不依赖 file/od；实测 ELF✓ 脚本✓ 文本✓）。

**修复（已提交推送）**：

- `clear.sh` upx 循环**只处理 ELF 二进制**（脚本/文本跳过）：`2a6090f`（head+od 判 `7f454c46`）→ `bd3f674`（改纯 bash `read -N4` 判 `\177ELF`）。
- **验证**：rootfs-dbg-v5 genentries 替换解压版跑通（`Htop` 条目 rc=0）。

**结论**：rootfs 统一 upx 只该压 ELF 可执行，脚本不该 upx（UPX `--shell` 压 bash/sh 会坏）。
