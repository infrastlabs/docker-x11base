# gtk2 库层与 imlib2 依赖适配

## 章节表

- 一、贰次手动编译：gtk224 镜像启容器 gtk2（u-gtk gdk_pixbuf）+ lxtask 至截图验证/复现图标正常（2026-11-14，用户拍板：按历史手动方式）
  - 1、总体链接流程（1.1 八步跑通+双 -u 修复原理 + 1.2 注意项/踩坑）
  - 2、相关问答（两轮对话存档，2.1–2.2）：svg 注册 -u 与库层/应用层边界
  - 3、库层根治方案（3.1 方案分析 3.1.1–3.1.5 + 3.2 实施验证 + 3.3 批量验证 3.3.1 + 3.4 CI 全自动缺口 + 3.5 libtool/geany，2026-11-14）
  - 4、3 落地后反馈与排查（4.1 lxtask 无图标→订正 v4 环境无 mime；4.2 原文回溯，2026-11-14 晚~11-15）
  - 5、运行环境无svg无图排查，mime配置修正（5.1 实跑复核 UPX 排除/方案A/mime 根因 R8；5.2 反查原文回顾 5.2.1–5.2.2；5.3 mime 部署问答；5.4 gdk_pixbuf 构建错误日志源头修复 5.4.1/5.4.2，2026-11-15） ✅已解决
- 二、imlib2 与 gtk2 共同依赖/适配现状问答（2026-11-15）
  - 1、问与答原文收录（1.1 问、1.2–1.5 回答，2026-11-15）
  - 2、开工定案与验证方案（2.1 分工拍板：imlib2 挪 u-gtk b_deps 尾部/本侧处理余下；门 A1/A2+B1/B2/B3，png/jpg/svg 三格式；2.2 Phase A/B 执行记录：注入库三格式真解码✅/5 应用全出 bin，2026-11-15）
  - 3、2节完善前，直接开工修现有问题（3.1：feh git describe fatal✅修+真图可开/证伪/tint2 librsvg jpeg_*✅修/scrot Xvnc 运行时定论＝保存目录不可写+默认存cwd语义；3.2 整体进展汇总；3.3 真机验证记录表（用户 rootfs-dbg 实测：geany/engrampa/rofi/feh/scrot✅、pcmanfm❌无二进制待修、tint2⏳），2026-11-15 晚）

（以下为正文，章号重新从一/二起，序号层级与原文档一致）

## 一、贰次手动编译：gtk224 镜像启容器 gtk2（u-gtk gdk_pixbuf）+ lxtask 至截图验证/复现图标正常（2026-11-14，用户拍板：按历史手动方式）

> **订正（2026-11-14）**：4.3.4（原文档 `docs/2026/11120827-ci-builder-gtk-app-rootfs.md` §4.3.4）的待确认项本轮全部落地——CI 已重建 base（远端 pull 的 `alpine-builder-gtk224-2` 自带 `libgdk_pixbuf-2.0.a`=1060610B、`_gdk_pixbuf__svg_fill_vtable` 已定义，Nov 13 构建含 svg loader）；但 **u-gtk 最新修复（Requires.private 补全 + `--default-library=static` + introspection 禁用）未烤入该镜像**，且各应用链接缺「svg 注册方强制拉入」环节。本 1 记录二次复现的完整链接流程与踩坑。

### 1、总体链接流程（8 步跑通，验证截图用户确认图标正常）

| 步 | 内容 | 命令/要点 |
|---|---|---|
| ① | 拉取 base 镜像 | `docker pull registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-builder-gtk224-2`（本地曾被我误 prune 删除；远端 Nov 13 版库已含 svg_fill_vtable） |
| ② | 起容器（像 awe 跑法） | `docker run -d --name builder-svg --network host -e CACHE=/usr/local/static/.cache -v /_ext:/_ext --entrypoint bash <img> -c 'while :; do sleep 3600; done'` |
| ③ | **`/src` 换软链**（关键坑） | 镜像内 `/src` 是烘焙真实目录（旧脚本）；必须 `rm -rf /src && ln -s /_ext/.../compile/src /src`，否则用旧 u-gtk build.sh → 链 `.so` + 无 Requires.private → `cr_*`（libcroco）undefined |
| ④ | 增量跑 gdk_pixbuf | `cd /src/u-gtk && CONSOLE_LOG=no bash build.sh gdk_pixbuf` → build 主库 `libgdk_pixbuf-2.0.a`=1060650B（`svg_fill=11`）编出；**install 的工具（query-loaders/csource）链接失败是已知坑**（AGENTS 三章 3），主库已备 |
| ⑤ | **lxtask 链接**（双 `-u` 强制拉入，核心修复） | `TARGETPATH=/usr/local/static/lxtask CONSOLE_LOG=no bash /src/v-lxde/build.sh lxtask`；v-lxde/build.sh LIBS0 加 `-Wl,-u,_gdk_pixbuf__svg_fill_vtable -Wl,-u,gdk_pixbuf_new_from_file`（详见 1.1） |
| ⑥ | 部署验证环境（**rootfs-dbg 默认桌面**） | rootfs-dbg 镜像**不带自定义命令**重起容器（默认 entrypoint `.core-init + /entry.sh` 拉起 Xvnc `:10` + fluxbox + tint2 + headless 主题配置）；`apk add scrot thunar` |
| ⑦ | headless 用户实跑 | `su -s /bin/bash headless -c "DISPLAY=:10 /usr/local/static/lxtask/bin/lxtask &"` → 日志**空（无 Unrecognized 警告）** |
| ⑧ | 截图验收 | `DISPLAY=:10 scrot /tmp/rd-compare.png` → 用户确认「lxtask 图标正常」（`docs/img/tmp/gtk2-svg/v2_rootfs-dbg-default-desktop.png`） |

#### 1.1、lxtask 链接修复的原理（双 `-u`）

- **现象**：gdk_pixbuf 库里 svg loader（`io-svg.c.o`）已编入（`T _gdk_pixbuf__svg_fill_vtable`）、注册方 `gdk-pixbuf-io.c.o` 也 `U` 引用它，但 lxtask 运行时仍 `Unrecognized image file format`。
- **根因**：静态链接**按需拉取**——lxtask 未直接引用 `gdk-pixbuf-io.c.o` 的符号（图标走 `gtk_icon_theme_load_icon`→gtk 库间接路径），ld 不拉入注册方 → 内置 loader 数组里没有 svg → svg loader 就算链入也不注册。
- **`-u _gdk_pixbuf__svg_fill_vtable` 单独不够**（只拉 `io-svg.c.o`，注册方仍缺，实测仍报错）；**`--whole-archive` 也不行**（拉入 `io-jpeg/io-png` 引来 libjpeg 链式 undefined，实测 make 失败）。
- **正解**：双 `-u` —— `-Wl,-u,_gdk_pixbuf__svg_fill_vtable`（svg loader）+ `-Wl,-u,gdk_pixbuf_new_from_file`（注册方 `gdk-pixbuf-io.c.o`，其 U 引用 svg_fill → 自动链 `io-svg.c.o`）→ 完成注册。

#### 1.2、注意项 / 踩过的坑（本流程新增）

1. **image 内 `/src` 是烘焙目录不是软链**（AGENTS 原记 `/src` 是容器态软链、镜像缺失——builder-svg 实测镜像里是**真实目录**）：必须 `rm -rf /src && ln -s 宿主 /src`，否则 u-gtk 走旧脚本（`--default-library=both` 链 `.so` + `Requires.private` 未补）→ `cr_*`/`R_X86_64_TPOFF32` 链接失败。
2. **docker exec stdout 时好时坏 + `docker cp` mount 报 `no space left`**（daemon 层 mount 故障，宿主 `df` 实际有余，非磁盘满）：统一用**容器内写 `/_ext/tmp`**（777；rootfs-dbg 系写 `/_ext` 需容器内 `sudo -n` 提权）通道拿日志/产物；命令**一条 exec 一个动作**，多命令链/管道易截断。
3. **`pkill -f "xxx"` 会杀自身命令行**（sudo sh -c 里同理）→ 用 `[x]xx` 字面量技巧避免自杀。
4. **验证必须 headless 用户 + 默认桌面**：rootfs-dbg 重起容器**不带自定义命令**（否则破坏 entrypoint 链路，主题/图标配置拉不起来）；`HOME=/home/headless` 才有 Greybird/Papirus（root 用户跑 = 主题错 + 图标打叉，对照组 `v2_lxtask-about-261114.png`）。
5. **AI Alpine 容器无 Papirus 图标/无 Xvnc**：svg 解码测试用自建 `svgtest.c` + 简单 `test.svg`，别找图标样例。
6. **窗口名中文**（如 lxtask"任务管理器"）：`xdotool search --name "Task Manager"` 找不到，用 `.`/`.*` 遍历 + `getwindowname` 过滤。
7. 判成功**别信 oneBuild 的 `err 0, pass`**（沿用 AGENTS 三章 3）：兜底 `xx-verify --static` + `grep -c "undefined reference"` + 实跑截图人工确认。

### 2、相关问答（两轮对话存档）：svg 注册 -u 与库层/应用层边界（2026-11-14）

#### 2.1、第一轮问答：CI 脚本漏调整 / alpine-builder-2 重跑可修 / 其他 gtk2 应用参数

**Q（用户，原话）**：

> 那现在回到最初的问题。docs/2026/11110827-ci-builder-gtk-app.md 五章 5.1，这个是你第二次手动搞通的。
> 1. 那对应ci构建，u-gtk/build.sh 产gtk224-2的镜像，再是lxtask等应用的编译， 你给检查一下脚本还有没有漏调整的呀？
> 2. 然后用alpine-builder-2镜像重跑u-gtk，再是lxtask是否编译后也可修正？？
> 3. 其他gtk2应用如geany等，他们自身build.sh编译参数有要调整的？？

**A（检查结论）**：

| 检查项 | 状态 |
|---|---|
| u-gtk/build.sh gdk_pixbuf（Requires.private / `--default-library=static` / introspection 禁用） | ✅ 已在（58/64 行） |
| **u-gtk gdk_pixbuf `ninja install` 兜底** | ⚠️ **漏**：install 时 query-loaders/csource 工具链接失败（builder-svg 实测 6 处 clang error）→ 主库不进 `/usr/local/lib`；83 行 `cp /usr/local/lib`（装旧库）、**84 行 `cp build/...` 兜底被注释**。CI（`Dockerfile.builder.gtk224:15 RUN u-gtk b_deps`）重建 gtk224-2 若 install 失败 → 镜像库仍旧 → **CI 产物可能又打叉** |
| 主 Dockerfile lxde stage（354-364 行） | ✅ `sh /src/v-lxde/build.sh lxtask` 走修复脚本（COPY 源码含双 -u） |
| alpine-builder-2 重跑 u-gtk + lxtask | ✅ **能修**（builder-svg = gtk224-2 镜像容器实测：主库 1060650B `svg_fill=11` 编出 → lxtask 双 -u RC=0 → 截图正常）；但**自动路径缺 install 兜底**（手动靠 `cp build 主库` 绕过） |
| 其他 gtk2 应用（geany 等）LIBS | ⚠️ 需统一加双 `-u`（见下表和 2.2④），否则同 lxtask 打叉风险 |

| 应用 | rsvg/croco（现有） | 双 `-u`（现有） | 判断 |
|---|---|---|---|
| lxtask（v-lxde） | ✅ | ✅ | 已修（实测） |
| geany（v-geany 43 行） | ✅ 有 | ❌ 无 | 需加（与 lxtask 同风险） |
| pcmanfm（v-pcmanfm 184 行） | ✅ 有 | ❌ 无 | 需加 |
| lxappearance（v-lxde 39 行） | ❌ 无 | ❌ 无 | 需加 rsvg/croco + 双 -u |
| engrampa/gpicview/ibus/pavucontrol/sysmonitor/xfce4/pasystray | 参差 | 大部分无 | 同风险，建议统一处理 |

**建议改动（待用户确认）**：① `u-gtk/build.sh` 启用 84 行兜底（`cp build/gdk-pixbuf/libgdk_pixbuf-2.0.a /usr/local/lib/ /usr/lib/`，CI 不回归的关键）；② 各 `v-*` LIBS0 统一加 `-Wl,-u,_gdk_pixbuf__svg_fill_vtable -Wl,-u,gdk_pixbuf_new_from_file`（缺 rsvg/croco 的补上）。

> **订正（2026-11-16）**：本段"① 启用 84 行兜底"**已过时，无需调整**——`u-gtk/build.sh` 于 11-15 做源头修（`gdk_pixbuf()` :91-104）：不再 `ninja install`（query-loaders/csource 工具链接失败致主库不落地），改**只编 `ninja -C build gdk-pixbuf/libgdk_pixbuf-2.0.a`（:98，绕开工具链接）+ 手动 `cp` 到 `/usr/local/lib`（:102）与 `/usr/lib`（:104）**——即原兜底已被该路径**直接替代且更彻底**（单目标 ninja 从源头绕开工具，非事后补救 cp）。② 各 `v-*` 双 `-u` 项后续亦被「方案A 库层 svg 注册根治（`u-gtk/build.sh` :52-75 注册导出+get_type 必然调用 + `-Dbuiltin_loaders=png,jpeg,svg`）+ 下游补 `-lrsvg-2 -lcroco-0.6`」取代（见本文件 3.3 订正与 lxtask 已回退双 `-u`）。

#### 2.2、第二轮问答：-u 双符号是干嘛的？必须应用层吗？最初怎么搞的？

**Q（用户，原话）**：

> 没有 -u svg 注册拉入！但都没有 lxtask 的 -u 双符号；他这个是干嘛的？ 必须得在应用层处理吗？u-gtk那边处理还不行？ 最初手动编译的时候也是在应用层吗？当时是怎么搞定的？

**A**：

**① 双 `-u` 是干嘛的**：`-Wl,-u,SYMBOL` = 告诉链接器「该符号必须被解析」，强制从静态库拉出**定义它的对象**：

| 符号 | 拉出的对象 | 作用 |
|---|---|---|
| `-u _gdk_pixbuf__svg_fill_vtable` | `io-svg.c.o` | svg loader 本体 |
| `-u gdk_pixbuf_new_from_file` | `gdk-pixbuf-io.c.o`（注册方） | 它 U 引用 svg_fill → 自动链 io-svg.c.o → svg 进内置 loader 数组 |

静态库是**按需拉取**——ld 只拉「被引用了的 .o」。lxtask 图标走 `gtk_icon_theme_load_icon`→gtk 库间接路径，**不直接引用 `gdk-pixbuf-io.c.o` 的符号** → 注册方不被拉入 → 库里 svg 编了也没注册 → 运行时 `Unrecognized image file format`。

**② 必须应用层处理吗？u-gtk（库层）不行**：必须应用层（链接层）。u-gtk 库层只能保证「loader 编进 `.a`」（已做到，`included_loaders_deps` 链入 io-svg.c.o），但**拉入注册方是链接时行为**，库层无法强制「gdk-pixbuf-io.c.o 必被拉」：

- 真在库层解决 = 改 gdk-pixbuf 源码把 svg 注册挪进**必然被引用的 .o**（如 gdk-pixbuf.c.o）——侵入式改造，成本高、影响全库。
- AGENTS 四章「gdk-pixbuf 图标坑」本就是这结论：**静态下 loader 是独立 `.a`，要图标必须静态链 loader（应用侧）或自解码**——「应用层处理」是既定做法。

**③ 最初手动编译时也是在应用层吗**：最初**没有 -u**。回 `11051758-v-oth-impl01.md:697`：

> 第 4 轮：`io-svg.c.o` **被静态模块注册拉入**，需 `rsvg_handle_new/...` → 加 `-lrsvg-2 -lcroco-0.6 -lxml2 -llzma`

当时能出图标的应用（dunst/engrampa）**直接调用 gdk_pixbuf IO API**（`gdk_pixbuf_new_from_file` 加载缩略图/图像）→ **自然拉入 `gdk-pixbuf-io.c.o`（注册方）** → svg 自动注册，无 -u。lxtask 恰恰不走这条路（纯 `gtk_icon_theme`）→ 打叉 → 才需要 -u 补救。

**④ 其他 gtk2 应用（geany 等）判断法**：**谁直接引用 gdk_pixbuf IO 符号，谁不需要 -u；谁走 `gtk_icon_theme` 间接路径，谁需要**：

| 应用 | rsvg/croco（现有） | 双 `-u`（现有） | 判断 |
|---|---|---|---|
| lxtask（v-lxde） | ✅ | ✅ | 已修（实测） |
| geany（43 行） | ✅ 有 | ❌ 无 | 文本编辑器，图标走 gtk_icon_theme → **大概率要 -u** |
| pcmanfm（184 行） | ✅ 有 | ❌ 无 | 缩略图直接调 gdk_pixbuf → **可能自然拉入，不用 -u** |
| lxappearance（39 行） | ❌ 无 | ❌ 无 | 图标预览走 gtk_icon_theme → 大概率要，且还缺 rsvg/croco |
| engrampa/gpicview/ibus/pavucontrol/sysmonitor/xfce4/pasystray | 参差 | 大部分无 | 同风险，视是否直接调 gdk_pixbuf IO |

**确认方式**：grep 各应用源码 `gdk_pixbuf_new_from_file`（或编译后 `strings <bin> | grep org.w3c.svg.static` 查 io-svg.c.o 特征）。

### 3、库层根治方案：svg 注册挪入必然被引用的 .o（2026-11-14）

#### 3.1、方案分析（库层解决 vs 应用层 -u，用户要求细化）

##### 3.1.1、现有机制与 -u 的由来

- svg loader 注册逻辑在 `gdk-pixbuf-io.c`（patch 改的 module/try_module/load_one_builtin_module 三处），编成 `gdk-pixbuf-io.c.o`。
- 应用（如 lxtask）走 `gtk_icon_theme_load_icon` 间接路径，**不引用 `gdk-pixbuf-io.c.o` 的符号** → ld 按需拉取不拉它 → 注册不执行 → `-u gdk_pixbuf_new_from_file` 在应用侧强制拉入补救（见 2.2）。

##### 3.1.2、方案 A（推荐）：注册挪进"必然被引用的 .o"

改法（u-gtk patch 加 3 处）：

1. `gdk-pixbuf-io.c`：把内置 loader 注册逻辑抽成**非 static** 导出函数 `gdk_pixbuf_register_builtin_loaders(void)`（现有逻辑原样包一层），头文件（gdk-pixbuf-private.h）声明；
2. `gdk-pixbuf.c`：在 `gdk_pixbuf_get_type()`（**GTK 首次用 pixbuf 必调的类型注册**）里调用 `gdk_pixbuf_register_builtin_loaders()`；
3. 注册时机安全：get_type 发生在任何 `gdk_pixbuf_new_from_file` 之前 ✓。

**链接自动成立**：应用（GTK 内部）必然引用 `gdk_pixbuf_get_type`（gdk-pixbuf.c.o）→ 拉入 gdk-pixbuf.c.o → U 引用注册函数 → 拉入 gdk-pixbuf-io.c.o → U 引用 io-svg/io-png/io-jpeg fill_vtable → **三个 loader 全拉入** + rsvg/png/jpeg 库解析。**应用无需 -u**。

方案 B（constructor 变体）：`gdk-pixbuf.c.o` 加 `__attribute__((constructor))` 做注册——前提同样是该 .o 被拉入，可作 A 的加固（不依赖 get_type 调用链）。

##### 3.1.3、实现成本

| 项 | 工作量 |
|---|---|
| patch 改动 | u-gtk patch +3 处（io.c 导出 / c.c 调用 / 头声明），机制简单 |
| 重编 | `u-gtk build.sh gdk_pixbuf` 1 次 + CI 重烤 gtk224-2 镜像（耗时主要在 CI） |
| 应用回归 | **全部 v-\* 重编 + xx-verify + 图标实跑**（N 个） |

##### 3.1.4、对现有应用的影响 / 调整点（关键）

| 应用 | 现状 | 库层改造后 | 依赖检查 |
|---|---|---|---|
| 全部 v-\* | 需加/已加 -u | **去掉 -u**（或保留需确认注册幂等） | `-lrsvg-2 -lcroco-0.6 -lpng -ljpeg` **实测已全含**（8 应用；gpicview 唯一缺 `-lpng` 需补） |
| lxtask | 双 -u 已修 | 去 -u，回归 | ✓ |
| **新增影响点** | — | gdk-pixbuf-io.c.o 被拉入 → **png/jpeg loader 也进所有应用** | 二进制略大（几~几十 KB）；`-lpng/-ljpeg` 基本具备 |

##### 3.1.5、权衡结论

- **库层（A）**：实现成本**中等**（patch 小），**根治**（新 gtk2 应用免记 -u）；但需**全量应用重编回归** + gpicview 补 `-lpng` + 镜像重烤。
- **应用层（现状 -u）**：每应用 1 行（lxtask 已做），无库改动/重烤；代价是**每个新 gtk2 应用都要记得加 -u**。
- 风险点：库层后 `gdk-pixbuf-io.c.o` 必被拉，若某应用靠"不拉它"规避过 png/jpeg 符号冲突会暴露（概率低，依赖已实测齐备）。
- **用户拍板（2026-11-14）**：按方案 A 开工。

#### 3.2、实施与验证结果（2026-11-14）

**实现**（三处源码改动，走 `u-gtk/build.sh gdk_pixbuf` 统一入口；patch 后**内联 python3** 修缮——patch hunk 方案多轮格式失败后弃用）：

1. `gdk-pixbuf-io.c`：`static void gdk_pixbuf_io_init_builtin` → **导出** `void` + 幂等 guard（`static gboolean inited`，防 `gdk_pixbuf_io_init` 重复注册）；
2. `gdk-pixbuf-io.h`：`G_END_DECLS` 前加 `void gdk_pixbuf_io_init_builtin (void);`;
3. `gdk-pixbuf.c`：include `gdk-pixbuf-io.h` + `G_DEFINE_TYPE_WITH_CODE` 的 code 参数里追加 `gdk_pixbuf_io_init_builtin ();`（**get_type 必然执行**）。

**踩坑（patch 落地）**：补丁 hunk 反复出格式问题——`@@` 计数不匹配、行尾 `\` 被当续行（malformed）、`index ..0000000` 被当新文件、hunk 间缺空行、**misordered hunks**（新 hunk 行号逆序）、多 hunk 同文件**新行号 offset**（hunk1 +1 行后 hunk2 新行号要 +1）、**dry-run rc=0 但 fuzz 错位未实际应用**（gdk-pixbuf.c 的 G_DEFINE hunk 就是此例）→ **弃用 patch hunk，改 build.sh 内联 python**（assert 校验 + 精确替换，稳定可维护）。

**验证结果**：

| 项 | 结果 |
|---|---|
| build.sh gdk_pixbuf | RC=0，主库 `libgdk_pixbuf-2.0.a`=1060160B（安装工具仍链接失败为已知坑，主库已备并手动装 `/usr/local/lib`+`/usr/lib`） |
| 注册函数导出 | nm：`T gdk_pixbuf_io_init_builtin` + `b gdk_pixbuf_io_init_builtin.inited`（guard）|
| 注册链自动成立 | nm：`gdk-pixbuf.c.o` **`U` 引用 `gdk_pixbuf_io_init_builtin`** → 应用拉 gdk-pixbuf.c.o 即自动拉注册方 gdk-pixbuf-io.c.o → io-svg.c.o |
| svg loader | nm：`T _gdk_pixbuf__svg_fill_vtable` = 1 |
| **去 -u lxtask**（方案 A 关键）| 编译 RC=0，`org.w3c.svg.static`=1（svg loader **自动进，应用无需 -u**）|

**影响**：`v-lxde/build.sh` lxtask 已回退原 LIBS0（去掉双 -u，保留 `-lrsvg-2 -lcroco-0.6`）；CI 重建 gtk224-2（烤新 u-gtk）后，**各 gtk2 应用（geany/pcmanfm/lxappearance…）理论上均无需 -u**（`-lrsvg-2 -lcroco-0.6` 及缺的 `-lpng` 需保留/补齐），后续逐个回归。
> **订正（2026-11-14 收尾）**：遗留①已闭环——rootfs-dbg **默认桌面**（重起容器、默认 entrypoint 拉起 Xvnc :10+fluxbox+tint2+headless 主题）实跑**方案 A 版（去 -u）lxtask**，About 截图用户确认图标正常（`v3_lxtask-about-schemeA.png`）。库 A 改造经 multi-app 验证（3.3）均 `org.w3c.svg.static=1` 生效。

#### 3.3、gtk2 应用批量验证进展（2026-11-14 第二天，批量检查修正）

**范围**（用户拍板）：非 gtkmm（pavucontrol/gnome-system-monitor）、非 pasystray、非 w-xxx（imlib2）、非 ibus 的其余 gtk2 应用，逐个编译验证+实跑截图。

| 应用 | 编译 RC | `org.w3c.svg.static` | 实跑截图 | 状态 |
|---|---|---|---|---|
| lxtask（v-lxde） | RC=0（先 -u 后去 -u） | 1 | `v3_lxtask-about-schemeA.png`（rootfs-dbg 默认桌面） | ✅ 用户确认图标正常 |
| geany（v-geany） | RC=0（142s，去 -u） | 1 | `v3_geany-main/about.png`（已推） | ✅ 用户确认 |
| engrampa（v-engrampa） | RC=0 | 1 | `v3_engrampa.png`（已推） | ✅ 用户确认 |
| gpicview（v-gpicview） | RC=0 | 1 | `v3_gpicview-{jpg,png,svg}.png`（三格式分别打开） | ✅ 用户确认三格式 OK |
| pcmanfm（v-pcmanfm） | RC=0（先 b_deps） | 1 | `v3_pcmanfm.png`（已推） | ✅ 用户确认 |
| **xfce4 三件**（thunar/ristretto/display-settings） | RC=0 | 全 1 | `v3_thunar/ristretto/display-settings.png`（已推） | ✅ 用户确认 |
| lxappearance（v-lxde） | RC=0（补 rsvg/croco） | 1 | — | ⏳ 以后再看（运行 rc=1，dbus session/machine-id/ui 已配齐仍静默退，疑 rootfs 环境能力） |

> **订正（2026-11-14 收尾）**：批量 7 项中 lxtask/engrampa/pcmanfm/gpicview(三格式)/xfce4 三件/geany 用户全部确认 OK（gpicview svg = 方案 A loader 直接证）；lxappearance 待以后；lxappearance 编译+svg 通过、运行待环境（dbus 会话能力）。

**坑/修正（本批新增）**：

- ① **pcmanfm 必须先 `b_deps`**（libfm/menu_cache/libfm-gtk 前置库）再 `pcmanfm`——直接跑 configure 报 `cannot find -lmenu-cache -lfm -lfm-gtk`（conftest 链接失败 → "C compiler cannot create executables"）。
- ② **engrampa 缺 GSettings schema**：`make install-data` 未装 → 运行时 `GLib-GIO-ERROR: Settings schema 'org.mate.engrampa.listing' is not installed`。处理（演进）：
  - v1（`613c874`）：schema 装 `$TARGETPATH/share/glib-2.0/schemas/` + 运行时 `XDG_DATA_DIRS`——需部署侧设变量，弃；
  - v2（`8361cd6`）：改装系统 `/usr/share/glib-2.0/schemas` + `glib-compile-schemas`——**不可迁移**（产物以 `/usr/local/static` 为基准拷走，系统文件丢），撤；
  - v3（`bed74ff` 定稿 + **用户拍板选 2 改源码编入**）：schema 回 **`$TARGETPATH/share/glib-2.0/schemas`**（可迁移）+ `glib-compile-schemas` 同目录产 `gschemas.compiled`（同目录自足）；**运行时免环境变量 = 改 engrampa 源码**：`g_settings_new` → 自定义 schema source（`g_settings_new_full` 指向编译期 `$TARGETPATH/share/glib-2.0/schemas`，`-DENG_SCHEMA_DIR="..."` 编入）——**编译期真编入，与 --prefix 编 PKGDATADIR 同法**（进行中）。残余 xfconf gsettings 后端动态加载警告（非致命）。
#### 3.3.1、engrampa schema 改源码编入实施明细（2026-11-14 开工，按用户拍板选 2 落地）

**目标**：产物可迁移（整目录 `/usr/local/static/engrampa/` 拷走即跑）、**运行时零环境变量**
（不设 `XDG_DATA_DIRS`/`GSETTINGS_SCHEMA_DIR`），schema 目录在 **编译期编入二进制**。

**事实基线（容器内实探，非推断）**：
- 真调用点 **20 处 / 10 个 `.c` 文件**（grep `g_settings_new` 命中 30 行，其中 10 行为 `.o` 二进制噪音）：
  `fr-window.c`(5)、`actions.c`(4)、`preferences.c`(2)、`dlg-new.c`(2)、`dlg-batch-add.c`(2)、
  `dlg-add-folder.c`/`dlg-add-files.c`/`dlg-extract.c`/`dlg-password.c`/`dlg-open-with.c`(各 1)。
- `CAJA_SCHEMA` **已自带容错**（`fr-window.c:5467` 先 `g_settings_schema_source_lookup` 命中才 new）→
  只需换函数、判空语义等价，无需额外容错逻辑。
- `glib-compile-schemas` **支持 `--targetdir`**（builder-clean 实跑 `--help` 确认）→ 无需"运行时拷
  compiled 到可写目录"这类补丁式做法。
- schema 落点已定：`$TARGETPATH/share/glib-2.0/schemas/{org.mate.engrampa.gschema.xml, gschemas.compiled}`。

**改动四步**：
1. **`fr-init.c` 加 helper** `eng_settings_new(const char *schema)`：`g_settings_new_full(schema,
   g_settings_schema_source_new_from_directory(ENG_SCHEMA_DIR, NULL), NULL, NULL)`；
   `ENG_SCHEMA_DIR` 未定义或新 source 失败 → 回落 `g_settings_new(schema)`（健壮性 + 可回滚）。
2. **`fr-init.h`** 声明 `GSettings *eng_settings_new(const char *schema);`。
3. **20 处 `g_settings_new (` → `eng_settings_new (`**（精确匹配 `g_settings_new (`，不误伤
   `g_settings_new_full`；`fr-window.c` 那处带 `window->priv->` 不影响行内替换）。
4. **`build.sh` configure 加** `CPPFLAGS="-DENG_SCHEMA_DIR=\"$TARGETPATH/share/glib-2.0/schemas\""`
   （`TARGETPATH` 由调用方传入，build.sh 不硬编码——AGENTS 3.2）。

**决策点已验证（2026-11-14 探针实测，`t_helper_test.sh`）**：schema 目录 **555 只读**、非特权
用户（uid 65534）下 helper 形态 `new_from_directory` + `lookup(recursive=TRUE)` + `new_full` 全部
`OK`（`org.mate.engrampa.listing` / `org.mate.engrampa.dialogs.extract` 均取到），**无
`GLib-GIO-ERROR`** → **无需 `--targetdir` 回退方案**，`build.sh` 直接指向
`$TARGETPATH/share/glib-2.0/schemas` 即可。唯一告警 `Failed to create /.config/glib-2.0/settings`
是 backend 落盘目录（探针 HOME 指向 `/`），非 schema 问题，真实部署 HOME 可写即消失。

**API 签名（GLib 2.70.5，实测头文件，helper 写法依此）**：
- `g_settings_schema_source_new_from_directory(dir, parent, trusted, error)` —— **4 参**，`trusted=TRUE`
- `g_settings_schema_source_lookup(source, schema_id, recursive)` → `GSettingsSchema*`
- `g_settings_new_full(GSettingsSchema *schema, backend, path)` —— 首参是 **schema 对象**，非 id
  → **helper 必须先 `lookup` 再 `new_full`**，不能直接拿 id 塞进去
- source 实例 **缓存 + ref/unref**（多次 `new_from_directory` 会产生重复实例）

**验证门（AGENTS 五-4 四项 + 本任务专项）**：① 图标 ② 主题 ③ 中文 ④ 输入法 +
`strings <bin> | grep -c 'org.mate.engrampa'` 编入路径生效、`xx-verify --static`、
**实跑不设任何 XDG/GSETTINGS 变量**且 stderr 无 `GLib-GIO-ERROR`。

**验证结果（2026-11-14 实跑，全绿）**：

| 项 | 结果 |
|---|---|
| `build.sh` 全流程（builder-clean） | `BUILD_RC=0`，产物 `statically linked, stripped` |
| schema 路径编入 | `strings <bin> \| grep -c 'engrampa/share/glib-2.0/schemas'` = **1** |
| svg 特征（方案 A） | `org.w3c.svg.static` = **1** |
| GUI 实跑环境 | hdmi 容器 Xvnc `:1`（现成会话），`headless` 用户，`scrot` 截图 |
| **免环境变量** | `XDG_DATA_DIRS=[]`、`GSETTINGS_SCHEMA_DIR=[]`（`env -u` 剥离）|
| `GLib-GIO-ERROR` / `not installed` / `GLib-GIO-WARNING` | **0 / 0 / 0**，stderr 完全为空 |
| 窗口 | `"归档管理器" (engrampa) 600x480` → **中文界面生效**（AGENTS 五-4 ③）|
| 进程 | `alive=YES` |

**实施坑（2026-11-14 实踩）**：

1. **`-D` 的引号语义（曾误判为"编入=0"）**：Makefile 里 `CPPFLAGS = -DENG_SCHEMA_DIR="/path"`
   的 `"` 是**字面字符**，经 make→shell 传递后 gcc 收到的是含引号的值 → 宏展开为**字符串字面量**。
   若误写成 `-DENG_SCHEMA_DIR=/path`（无引号）→ 宏值无引号 → 展开成 `/usr`、`local`… 标识符序列 →
   `expected expression` / `use of undeclared identifier 'usr'`。**参照同 Makefile 既有
   `AM_CPPFLAGS` 的 `-DFR_DATADIR=\"$(datadir)\"` 写法**（`\"` 转义）即可。
2. **`rm -f src/*.o` 是反效果**：强制全量重编会让 `copy-n-paste/libeggsmclient` 的
   `mv ...eggdesktopfile.Tpo` 竞争报 `No such file or directory` → make 段提前中止 →
   `src/*.o` 反而**不重编** → 手动 xx-clang 静默链接**旧的 .o** → `strings` 查路径 = 0（假阴性）。
   正确做法：**不清 .o**，靠 `CPPFLAGS` 变化 + automake 依赖（`.Po`）增量重编；
   手动 `make -C src fr-init.o` 单目标验证最快（`CPPFLAGS` 立即生效，`path-in-o=1`）。
3. **判断"编入是否生效"要看 `.o` 不是二进制**：stripped 静态产物里 `nm` 查不到
   `eng_settings_new`（符号被 strip），但 `strings | grep <路径>` 仍可见（路径在 `.rodata`）。

- ③ ~~schema 需部署层 XDG_DATA_DIRS~~（**终订 2026-11-14**：改源码编入 schema 目录后运行时免环境变量；schema 仅在组件目录内，可迁移）
- ④ **lxappearance 依赖 dbus session**：无 session bus 时自动 spawn `dbus-launch`——alpine `dbus` 包**不含 dbus-launch**（在 `dbus-x11`），缺则 `Failed to execute child process "dbus-launch"` rc=1；且需 machine-id（`dbus-uuidgen --ensure=/var/lib/dbus/machine-id`）。
- ⑤ gpicview 依赖由 `pkg-config --static --libs gtk+-2.0` 提供 png/jpeg（文件无字面量 -lpng，勿误判需补）。

**执行方式**（沿用 AGENTS 3.1 新增规则）：多步容器命令写 `/_ext/tmp/svg/t_xxx.sh` → 容器内 `bash <脚本>` 执行，结果写 `/_ext/tmp/svg/` + DONE 标记；环境读取问题（exec stdout 吞、docker cp mount ENOSPC）均绕开。

#### 3.4、CI 全自动路径缺口与修复（2026-11-14，buildx gtk224 / pcmanfm stage 暴露）

**背景**：方案 A 在手动验证（builder-svg + rootfs-dbg）全绿，但 **CI 全自动**跑出两个缺口（手动验证时环境铺好/应用 LIBS 齐，未覆盖到；CI 干净环境暴露）。

> **订正/复盘（2026-11-14）**：手动验证的应用（lxtask/geany/pcmanfm/gpicview/xfce4）build.sh LIBS 恰好全带 -ljpeg/-lpng/-lrsvg-2 → 全绿；但 **libfm 等中间库**（链接靠 configure/Makefile，未显式带）在 CI 干净环境暴露缺依赖。3.1.4 已预测"loader 全拉入→依赖增加"，正式踩到。

**① gdk_pixbuf `ninja install` 工具链接失败 → 主库不落地 → b_deps exit 1**（已修，`e086d7e`）
- 现象：`#12 gdk_pixbuf` 12× `clang-12: error`（query-loaders/csource 工具首次链接报错）→ `/usr/local/lib/libgdk_pixbuf-2.0.a: No such file` → `cp: can't stat` → `doExec FAIL rc=1` → `b_deps exit 1`。
- 根因：install 的工具目标失败使 `ninja install` 中止，主库（build/ 已编出）不落地；build.sh 尾部 `cp /usr/local/lib` 依赖 install 成功。
- 修复：`u-gtk/build.sh` gdk_pixbuf 尾部兜底（`/usr/local/lib` 无库时 `cp build/gdk-pixbuf/libgdk_pixbuf-2.0.a`）→ 尾部 `cp /usr/lib` 成功。
- 验证：模拟 CI 干净环境（删库重跑）→ RC=0；CI 复跑 `err 0, pass` + 继续 gtk ✅。

**② 下游（libfm 等中间库）链 gdk_pixbuf undefined loader 依赖（先试选 1 无效 → 改选 b 落地）**
- 现象：`#30 pcmanfm` 的 libfm：`libfm-gtk.la` 链接 `libgdk_pixbuf-2.0.a` → undefined `g_module_open/symbol/error`、`jpeg_*`、`png_*`、`rsvg_*` → `cp: can't stat /usr/local/lib/libfm.a` → pcmanfm configure "C compiler cannot create executables"。
- 根因：**方案 A 后 gdk-pixbuf-io/io-png/io-jpeg/io-svg 被整链拉入**（3.1.4 预测的影响点）→ 链接方需 `-lgmodule-2.0 -ljpeg -lpng -lrsvg-2 -lcroco-0.6 -lxml2 -llzma`；**gdk_pixbuf 的传递依赖未传播**（`gdk-pixbuf-2.0.pc` 的 `Libs.private` 不含 loader 依赖）→ 每个下游（libfm、menu_cache…）都要自己补，易漏。
- **方案（验证后改选 b 落地）**：先试选 1（`gdk-pixbuf-2.0.pc` Libs.private 补全）——验证发现 **不生效**：pc 的 `Requires.private` 本已声明全部依赖（meson 自动），但 **libfm 取 libs 用非 --static**（`pkg-config --libs` 不展开 private）→ 上游补 pc 救不了。**改选 b（用户拍板）**：`v-pcmanfm/build.sh` 的 `libfm()` make 补 `LIBS="-lgmodule-2.0 -ljpeg -lpng -lrsvg-2 -lcroco-0.6 -lxml2 -llzma"`（`33d7baa`），验证 RC=0 undefined=0；u-gtk 的 Libs.private 补丁已回退。
- **验证/执行方式**（沿用 AGENTS 3.1 新增规则）：构建容器命令脚本化（`/_ext/tmp/svg/t_xx.sh` → 容器内执行 → 结果写 `/_ext/tmp/svg/` + DONE）；①模拟 CI 干净环境（删库重跑）RC=0 + CI 复跑 `err 0, pass` 继续 gtk；②libfm 重跑 RC=0 undefined=0。**CI 全自动复跑待用户确认两处通过**。

**订正（2026-11-14，CI 干净环境复现）**：方案 b（`33d7baa` 的 `make LIBS` 补 `-lgmodule-2.0`）验证"RC=0 undefined=0"是**假绿**——在 builder-awe 验证（该容器残留源码编译的 `/usr/lib/libmenu-cache.a` 37K、`libfm.a`/`libfm-gtk.a`，Nov 4 第一次手动 b_deps 产物），libfm 静态链该 `.a` 不踩 gtk `.so` 坑；**CI 干净 base 只有 apk `menu-cache-dev` 的 `.so`（无 `.a`）** → libfm 动态链 `libgtk-x11-2.0.so`（u-gtk `--as-needed` 建库缺 gmodule DT_NEEDED）→ `g_module_open` 必 undefined；`make LIBS` 补的库只进 automake 主链接行、**不进 libtool `.so` 的 `$deplibs`**（`gdk-pixbuf-2.0.la` 不存在，meson 只产 `.a`）→ 无效。**改 `--disable-shared --enable-static`**：不产 `libfm-gtk.so` 从源头消掉该链接阶段；`libfm.a`(554K)/`libfm-gtk.a`(786K)/`libfm-extra.a`(25K) 产出，剩余 `g_module_open` 仅 `libfm-pref-apps`/`lxshortcut`（bin_PROGRAMS 工具）链接报、`make -k` 容忍；`make install` 因工具失败中断 src 段 → `.a` 不落地 → **手动 `cp src/.libs/*.a` 到 `/usr/local/lib`**（+拷 `/usr/lib`）。**另发现 menu_cache 段编不过**：`menu-tags.h:22` `#include <libfm/fm-extra.h>`，而 libfm 头文件平铺在 `/usr/local/include/libfm-1.0/`（`libfm-extra.pc` Cflags=`-I/usr/local/include`，无 `libfm/` 子目录）→ **`ln -sfn /usr/local/include/libfm-1.0 /usr/include/libfm`** 软链修复（已固化进 `libfm()` 尾部）。**builder-clean 模拟 CI 干净环境三段实测**：libfm→menu_cache→pcmanfm 全通，pcmanfm 最终 13.7M `statically linked, stripped`、xx-verify=0、undefined=0 → **两处（①gdk_pixbuf、②libfm/menu_cache/pcmanfm）均已确认通过**。

**订正（2026-11-14，③ geany 下游同样踩，根因不同——libtool 链接破坏 group）**：`#36 geany` 报 `undefined reference to rsvg_handle_*`（来自 `/tmp/gdk-pixbuf/.../io-svg.c`，gdk_pixbuf svg loader 整链拉入）。**排查确认非"缺 `-lrsvg-2`"**（geany `LIBS0` line 43 已带 `-lrsvg-2 -lcroco-0.6`）、**非"缺 `librsvg-2.a` 路径"**（dry-run 链接命令**本含 `-L/usr/local/lib`**，`/usr/local/lib/librsvg-2.a` 完整含 `rsvg_handle_*`）——起初误判"librsvg-2.a 只在 `/usr/local/lib` 未拷 `/usr/lib`"，试 u-gtk gdk_pixbuf 段加拷——**不靠谱**（`-L/usr/local/lib` 已在，拷后实测仍 undefined，证明非路径问题），已撤销。**真因**：geany 二进制用 `geany_LINK = $(LIBTOOL) --tag=CC`（src/Makefile:243）链接，**libtool 处理 LIBS 里 `-lrsvg-2`（有 `librsvg-2.la`）时展开/重排、破坏 `--start-group` 循环** → rsvg 未解析；而 line 62 的 `xx-clang++ -static` 直链（无 libtool）**实测成功**（15.3M 静态、undefined=0）。**修复（`332166e`）**：make 改 `-C src main.o libgeany.la`（`geany_SOURCES=main.c`，只编对象+库不链二进制绕开 libtool）+ `make install-data`（`install` 默认依赖 all 会链 geany 二进制，改只装数据）+ geany 二进制走 line 62 `xx-clang++ -static` 直链。**预防核查**：lxappearance/lxtask（同 `make LIBS` 模式）实测**不踩**（configure 链接非 libtool 破坏）；gpicview/pasystray/sysmonitor 已是"make 只编对象 + 手动直链"模式。**结论：方案 A 后需 `-lrsvg-2` 的下游，凡用 libtool 链接（geany_LINK 式）必踩，需改直链；非 libtool（直接 `$(CC)`）不踩**。

#### 3.5、libtool 链接破坏 --start-group 的机制细化 + geany 修复总结（2026-11-14）

**背景**：3.4 ③ 记录了 geany 踩坑（libtool 破坏 group）。本节细化 libtool 的具体行为（实证），并收口 geany 修复总结。

**① libtool 破坏 group 的实证**（builder-clean 手动跑 `libtool --mode=link --tag=CC -v` 模拟 geany_LINK）：
- 原命令（dry-run）：`libtool ... xx-clang ... main.o libgeany.la ... -Wl,--start-group ... -lrsvg-2 ... -Wl,--end-group`
- libtool verbose **实际执行**：`xx-clang ... -o geany main.o -pthread -pthread -Wl,--start-group -Wl,--end-group ./.libs/libgeany.a -lrsvg-2 -lcroco-0.6 ... /usr/local/lib/librsvg-2.a ...`（**`--start-group`/`--end-group` 中间变空**）
- **机制**：
  1. libtool `--mode=link` 对 `-lNAME`：若找到 `libNAME.la` → 读其 `old_library`（如 `librsvg-2.a`）+ `dependency_libs`，把 `-lNAME` **展开成绝对路径**（如 `/usr/local/lib/librsvg-2.a`）；
  2. libtool **不识别 `-Wl,--start-group`/`-Wl,--end-group` 语义**（仅透传），但把展开的库 + `-l` 依赖**重排/移到 group 结构之外** → group 中间**变空**，循环语义失效；
  3. 库被 libtool 按 `.la` 的 `dependency_libs` 拓扑重排，绝对路径 `.a` 与 `-l` 混排，**顺序不再保证"引用方在前/提供方在后"** → `io-svg.c.o` 引用 `rsvg_handle_*` 时 `librsvg-2.a` 顺序不对 → undefined（本次实测连 `io-jpeg.c.o` 的 `jpeg_input_complete` 也乱，`libjpeg.so DSO missing from command line`）。
- **对照**：line 62 `xx-clang++ -static ... -Wl,--start-group ... -lrsvg-2 ... -Wl,--end-group`（**无 libtool**）→ group 原样传 ld，循环正确 → 成功（15.3M 静态、undefined=0）。

**② geany 修复收口**（commit `dbb31b9`）：
- make 改 `-C src main.o libgeany.la`（`geany_SOURCES=main.c`，只编对象+库，不链二进制绕开 libtool；`geany_OBJECTS` 是**变量名非 make 目标**，`main.o`/`libgeany.la` 在 `src/` 子目录须 `-C src`）
- `make install-data`（`install` 默认依赖 `all` 会链 geany 二进制，改只装数据，二进制由 line 62 直链）
- geany 二进制走 line 62 `xx-clang++ -static` 直链
- 实测：builder-clean geany 段 RC=0、15.3M `statically linked, stripped`、xx-verify=0、undefined=0

**③ 预防核查（其它带 `-lrsvg-2` 下游）**：
- lxappearance/lxtask（同 `make LIBS` 模式）：实测**不踩**（configure 链接非 libtool 破坏，`$(CC)` 直链）
- gpicview/pasystray/sysmonitor：已是"make 只编对象 + 手动 `xx-clang` 直链"模式
- **结论**：方案 A 后需 `-lrsvg-2` 的下游，**凡用 libtool 链接（`geany_LINK` 式）必踩**，需改直链；非 libtool（直接 `$(CC)`）不踩。
- **教训**：先 `make -n`/`libtool -v` 看**实际链接命令**再下结论；别凭"库在哪个路径"猜（拷 `.a` 到 `/usr/lib` 治标且常无效——`-L/usr/local/lib` 本就在）。

### 4、3 落地后反馈与排查（2026-11-14 晚，构建镜像层缓存）

#### 4.1、lxtask 无图标：本地编译 OK / rootfs-dbg 查看则无（构建镜像层缓存命中旧 base）

**背景（用户反馈，2026-11-14 晚约 8 点，原话"**lxtask图标还是不行**"）**：3（方案 A 落地）之后，用户反馈"**lxtask 图标还是不行**"：本地编译 lxtask 图标正常，但**拉取 rootfs-dbg 里的 lxtask 查看 → 无图标/图标打叉**（`Gtk-WARNING: Error loading theme icon 'application-exit' for stock: Unrecognized image file format`）。用户当时判断"**我那边是构建镜像层，有缓存导致的问题**"。

> **备注**：本段为 5.3 落地后、用户直接反馈的排查记录（未与 §4.2.5/§4.3.1 的 UPX 干扰段、3.4/3.5 的 CI 链接失败段混同）。当时结论只沉淀在 memory（`compile-debug-tips.md` §4），未及时写入文档，本节补记。

**排查关键（产物核对 svg 特征，一锤定音）**：用 `strings <bin> | grep -c "org.w3c.svg.static"` 核对部署产物是否带 svg loader（方案 A 落地后正常产物应为 1）：

| 产物 | `org.w3c.svg.static` | 结果 |
|---|---|---|
| rootfs-dbg 里的 lxtask | **=0** | ❌ 无 svg loader → 图标打叉 |
| 最新 base（builder-clean）编的 lxtask | =1 | ✅ 正常 |

> **订正（2026-11-15）**：上表"rootfs-dbg lxtask =0"为 **UPX 打包假阴性**——部署产物经 `clear.sh`/UPX 压缩（13.4M→5.3M），`org.w3c.svg.static` 字符串被压缩进 UPX payload，`strings`/`grep` 找不到≠没有。**验证部署产物 svg 必须先 `upx -d` 解压再 grep**（对照 §4.2.5 UPX 干扰坑）。用最新 CI 产物复核（rootfs-dbg `33bef8ffdef4`，lxtask 位于 `/rootfs/files1/usr/local/static/lxde/bin/lxtask`）：解压后 13,468,584B（与新 base 产物同尺寸），`svg.static`=1、loaders **JPEG/PNG/SVG** 俱全 → **新部署 lxtask 支持 SVG 图标，问题已解决**。
> **另**：`/tmp/NOCACHE` 标记只随 `alpine-compile-2-dbg` 的 `COPY --from=base /tmp/NOCACHE /tmp/`（对应 `#65/#67`，值 `NOCACHE.gtk=2026-11-15_01:03:06`）进 **compile 镜像**；**rootfs-dbg 无此标记**（rootfs 仅从 bin2 COPY `/rootfs`，标记在容器 `/tmp` 不在 `/rootfs`，2026-11-15 实测）。

**根因：CI 部署产物 ≠ 本地编译产物（构建镜像层缓存命中旧 base）**：
- CI 的 lxde stage 构建时**命中了旧 base 的构建镜像层缓存**，产物是**旧 base 编的**（gdk-pixbuf `builtin_loaders=png,jpeg`，**缺 svg loader**）→ rootfs 里 lxtask 无 svg loader → 图标打叉。
- 本地用**最新 base**（builder-clean）干净编的带 svg loader（=1）→ 图标正常。
- 即**同一份 build.sh，产物因 CI 构建层缓存而新旧不一致**——正是用户说的"构建镜像层有缓存导致"。

**佐证（镜像层复用机制）**：§3 的 `alpine-compile-2-dbg` 核查（"镜像是复用的，会从历史镜像层拷贝出以前构建留下的产物……不是错误"，`:444`）+ "目录存在系缓存/基础镜像复用，mtime 早于本次"（`:595`）。

**结论 / 后续处理**：
- 该问题属"产物一致性"：**CI 构建镜像层缓存命中旧 base → 部署产物与本地编译产物不一致**。
- 规避：CI 清理对应 stage（lxde）构建缓存 / 强制用最新 base 重跑；并把"**产物核对查 svg 特征**"（`strings <bin> | grep -c "org.w3c.svg.static"` 应为 1）纳入验证项，防止"部署产物缺 svg loader"再次漏检。

#### 4.2、原文回溯：maki 会话归档查找结果（2026-11-15 补记）

> 目的：找回 4.1 的"用户 11-14 晚 8 点原话"逐字文本。方法见 `docs/2026/11061251-v-oth-impl02-ibus02.md` §1.4（如何翻看 maki archive jsonl）。

**方法（§1.4.1–1.4.3）**：`~/.local/state/maki/sessions/` 下主文件 `<session-id>.jsonl` + 归档分片 `archive/<id>/N.jsonl`（jsonl，需 `json.loads` 解析）；`cwd_latest.json` 映射目录→会话；`grep -rl '独特短语' .` 定位，python 逐行找 `t=="msg"` 且 `role=="user"` 且 text 含短语。

**查找结果**：
- 当前会话 `docker-x11base → Cgh6RH29`（`cwd_latest.json`），与用户截图一致；会话自 ~11-03/04（header `created_at=1793759082`）起。
- 归档目录 `archive/Cgh6RH29t1ASLeFDhAiov/` **只剩 `67.jsonl`**（11-15 02:21，69MB）；**主文件与 67.jsonl 的 L1 均为同一 header、L2 均为 `What did we do so far?`**——即两者**都只从"续话"开始**，11-14 的原始反馈（在本续话之前）**落在已被清理的分片 1–66**，磁盘上已无。
- 按词1（`lxtask图标还是不行`/`图标还是不行`）与词2（`新产物问题还是部署环境问题`/`部署环境`/`新产物`）跨全部会话（主文件+分片）搜 `role=="user"`：**均只命中本续话的消息**（词1→`67.jsonl` L13836 与 `input_draft` 轨迹 L13806–13831；词2→主文件 L13820 与轨迹 L13789–13818），**未命中任何历史会话的 11-14 原文**。
- 其余 docker-x11base 会话均无此原文：`CfRZ5tcr`（09-26/10-12，早期"图标不显示"实例）、`Cgj4GQ`（11-12/11-15）、`Ch34s`（11-14）、项目级 `input_history.json`（11-08，早于 11-14）。

**结论**：原始消息**记录已被 maki 清理**（分片 1–66），无法从磁盘恢复；但**原文逐字文本与时间由用户亲口确认**（"我的原文:**lxtask图标还是不行**"，"**14号晚8点左右**"），4.1 以此为准。教训：会话归档分片会被 maki 定期清理（§1.4 方法示例引用的 `32.jsonl` 现已不存在），**敏感原文应即时写入文档**。

### 5、运行环境无svg无图排查，mime配置修正 ✅已解决

#### 5.1、实跑复核：UPX 排除 / 方案A 库层就绪 / 问题在 gtk 图标主题加载路径（2026-11-15）

> **背景**：新 CI 全链（base `NOCACHE.gtk=2026-11-15_01:03:06` → compile → rootfs-dbg `33bef8ffdef4`）部署 lxtask **实跑仍无图标**（`Gtk-WARNING: Error loading theme icon 'application-exit' for stock: Unrecognized image file format`，与旧构建同错）。本节为"字符串判据 vs 实跑"对不上的排查实录。**修法约束：在 u-gtk（库层）/gtk 层修，不引入应用层 `-u`**——方案A 已是库层根治（`u-gtk/build.sh` 59–88 行：注册导出 + get_type 必然调用 + `-Dbuiltin_loaders=png,jpeg,svg` + `--default-library=static`），`v-lxde/build.sh` 72–74 行注释明示 -u 仅为初版应用层补救、方案A 后已撤。

**实验**（booted rootfs-dbg 默认启动合并环境 + 全新 Xvnc display，按 AGENTS Xvnc 规则）：

| 实验 | 做法 | 结果 |
|---|---|---|
| **A/B（UPX）** | 部署 lxtask 打包态（5,524,740B）vs `upx -d`（13,468,584B），同环境同样式 | **同报错** → **UPX 无关**（原文档 §4.3 结论再次实证） |
| **md5 同源** | base（gtk224-2）lxtask vs 部署 upx -d 后 | 同一二进制 `28bded30…` |
| **库层 nm** | base `/usr/lib/libgdk_pixbuf-2.0.a` | **方案A 全链就绪**：`gdk-pixbuf-io.c.o` 引 `U _gdk_pixbuf__svg_fill_vtable/info`、`io-svg.c.o` 定义 + `gdk_pixbuf__svg_image_*` + rsvg_handle_*、`gdk-pixbuf.c.o` 引 `U gdk_pixbuf_io_init_builtin`（get_type 必然调用）→ **撤回"库缺 svg loader"猜测** |
| **判据订正** | `strings/grep -c "org.w3c.svg.static"`（及 io-svg/svg_fill 串） | **均不可靠**——串来自 `.symtab`，`-Wl,--strip-all` 后全 0 但功能在（同参数微程序 io-svg=0 仍正常加载）。**判定以实跑为准** |
| **E1/E2 库层真值** | 微程序链同一 `.a`，直接 `gdk_pixbuf_new_from_file(application-exit.svg)`（有/无 `--as-needed --strip-all`） | **均 `OK 16x16`** → 库层 svg 加载正常 |
| **E3 gtk 路径** | 微程序 **lxtask 同款链接**（GTK+同 LIBS0），`gtk_icon_theme_load_icon('application-exit')` | **`GTK-FAIL: Unrecognized image file format`**（与 lxtask 一字不差）→ **问题收缩到 gtk 图标主题加载路径**（theme 检索/loader 流/尺寸缩放），非直接文件加载 |

**待办（下一步，E4 已备脚本未跑）**：无头微程序同链（`new_from_file` / `formats 是否含 svg` / `loader 流式`），**builder 与 rootfs 双端**各跑一次定层：
- 双端全 OK → 断点在 gtk_icon_theme 检索/缩放路径 → 查 gtk 侧；
- C(loader 流) 双端 FAIL → 方案A 注册了文件格式检测但 loader 模块回调（begin_load/increment）未链全 → 修 **u-gtk gdk_pixbuf builtin-loader 注册完整性**；
- builder OK / rootfs FAIL → 环境差异（schemas/locale/模块缓存）→ 查 rootfs。
定层后修 u-gtk/gtk → 重编 → 实跑四项校验（AGENTS 五章 4）。

**根因定位与反查（2026-11-15 追加，R8 实证）**

**根因**：rootfs 缺 `shared-mime-info` 的 MIME 数据库（`/usr/share/mime/mime.cache`）。

- **E4 双端**：同一静态二进制 builder 全 OK（png/svg/loader 流），rootfs **png/jpeg/svg 全 FAIL** → 不是 svg 特有，是 gdk-pixbuf **formats 整条为空**；gtk 只是第一受害者。
- **p8/p11**：builder 中 `XDG_DATA_DIRS=/nonexistent`（组合）即复现 FAIL；单变量全无害 → 指向 gio 内容类型猜测依赖。
- **R8 一锤定音**：rootfs 移植 builder 的 `/usr/share/mime` 后，**png/svg 全部翻 OK**。根因= gdk-pixbuf 2.42 检测走 gio `g_content_type_guess`（依赖 shared-mime-info 数据库），rootfs 未装该包 → 一切格式无法识别（`Unrecognized image file format`）。与 UPX、方案A/-u、链接、旧 base 缓存均无关。
- **修复**：`rootfs/src/Dockerfile` 最终阶段 `apk add` 已补 `shared-mime-info`（2026-11-15）；重建 rootfs-dbg 后实跑四项校验验收。
- **历史佐证（2026-11-15 补）**：旧容器 `rootfs-dbg-v5`（image `8ca1d553ceca`）复核——当前**也无 `mime.cache`**（thunar 为静态版，`ldd` 报 `Not a valid dynamic program`），即"昨天手动验证 OK"并非 rootfs 自带 mime，而是**当时环境带 mime**：曾 `apk add thunar`（`docs/desk/xfce/xfce4.md:46`，动态版 1.6.11，依赖链执行 `shared-mime-info-1.8-r0.trigger`）；同型先例见 `docs/desk/tint2-v16.1.md:1111`（装 `librsvg-dev` 时 `(1/10) Installing shared-mime-info` + trigger）。结论自洽：**谁装过动态 thunar/librsvg 等 GTK 系包，谁就被带入 mime → 图标 OK；干净 rootfs 无 mime → 全失败**。此即"图标依赖 mime.cache、由动态 GTK 包带入"的完整画像。
- **昨日验证流程还原（用户 2026-11-15 口述确认）**：当时 hdmi 与 rootfs-dbg **双容器**均有 GUI 验证；rootfs-dbg 侧截图用 `apk add scrot`，**对比用 `apk add thunar` 与 lxtask 一同跑起来截图**——动态 thunar 依赖链把 `shared-mime-info` 装进该容器 → `mime.cache` 出现 → 同一静态 lxtask 截图中图标正常。新 rootfs-dbg 镜像为干净构建（无动态 thunar/scrot）→ 无 mime.cache → 图标全无。与 R8 根因完全闭环。
- **git 时间线反查（提交信息=当时动作+结论，2026-11-15 补）**：以截图提交 `154d9f9`（11-14 14:45:03）为锚点反查 git 历史，完整还原 11-14 会话上下文：
  - 14:38 `ccab9f6`：v-lxde/build.sh **双 -u 修复**（`-Wl,-u,_gdk_pixbuf__svg_fill_vtable` + `-Wl,-u,gdk_pixbuf_new_from_file`）→ "hdmi :1 headless 实跑**用户确认图标正常**"；
  - 14:45 `154d9f9`：`v2_rootfs-dbg-default-desktop.png`（静态 lxtask**双-u 版** + **系统 thunar(apk)** 同屏，lxtask 日志**无图标警告**）；
  - 16:43 `66277e9`：**摘双 -u**（应用层补救回退）→ u-gtk 方案A（get_type 自动注册）接任；
  - 17:54–18:08 v3 系列（`rootfs-dbg-new :10 headless`）：方案A 批量实跑（gpicview 三格式 svg 正常=方案A 生效直接证、pcmanfm/geany/engrampa/xfce4 三件），用户确认；
  - 20:02 `5d33194`：v4 新 base（CI buildx 重建 gtk224-2）lxtask About 截图——"svg 特征=1/库含方案A/log 空；**请核验图标是否仍打叉**" ← **用户 11-14 晚8点反馈节点**（20 点后提交均为 engrampa schema 等，反馈只存在于会话 jsonl，其早期分片已清）；
  - **推论（根治 4.1 表述）**：v2/v3 OK 与 v4 打叉之差 = **验证容器是否有 mime**——v2/v3 为同一台曾 `apk add scrot thunar` 的 rootfs-dbg（mime 在）；v4 若为干净 rootfs 则无 mime → 打叉。与 5.1/R8 完全同因。**据此将 4.1"根因=CI 旧 base 缓存命中"订正为"11-14 晚8点反馈 = v4 验证/部署环境无 mime"**（构建链无责：方案A 库层就绪、svg 特征=1、log 空；缺的是运行环境 mime 库，非产物）。

#### 5.2、反查原文回顾：git 时间线反查的会话上下文（2026-11-15 原文收录）

按用户要求收录反查回复原文（含表格，非再提取转化）。

**反查完成——能反查到，且比 maki jsonl 更完整**（jsonl 原始分片 1–66 已被清，但 git 提交信息=当时动作+结论的带时间戳记录，等价保留了上下文）。以 `154d9f9`（11-14 14:45:03）为锚点拉出的完整时间线：

##### 5.2.1、按提交时间反查的会话上下文（11-14）

| 时间 | 提交 | 内容（提交信息=当时的动作+结论） |
|---|---|---|
| 14:38 | `ccab9f6` | v-lxde **双 -u 修复**（`-u _gdk_pixbuf__svg_fill_vtable` + `-u gdk_pixbuf_new_from_file`）→ "已 hdmi :1 headless 实跑**用户确认图标正常**" |
| 14:45 | `154d9f9` | **你指名的图**：rootfs-dbg 默认桌面(:10)——"静态 lxtask(**双-u 修复版**) + **系统 thunar(apk)** 同屏, lxtask 日志**无图标警告**" |
| 16:43 | `66277e9` | **摘掉双 -u**（应用层补救回退）→ 方案A（库层 get_type 自动注册）接任 |
| 17:54–18:08 | v3 系列 | 方案A 批量实跑（rootfs-dbg-new :10）：gpicview 三格式、pcmanfm、geany、engrampa、xfce4——"svg 正常渲染=方案A 生效直接证"，**用户确认** |
| 20:02 | `5d33194` | **v4 新 base（CI 重建 gtk224-2）lxtask About 截图**——"svg 特征=1/库含方案A/log 空；**请核验图标是否仍打叉**" ← **你晚8点反馈节点** |

##### 5.2.2、关键回答：「也是这个原因吗？」——是，且这正是"晚8点反馈"的真根因

- 昨天 OK（v2 14:45 / v3 17:5x）的验证容器是**同一台 rootfs-dbg**（14:45 起 `apk add scrot thunar` → **mime.cache 在**）→ 同屏无警告、用户确认正常。
- **20:02 v4 换到新 base 验证时，若容器是干净 rootfs（无 apk thunar → 无 mime）→ 图标打叉 → 你反馈"lxtask图标还是不行"**。
- 与今天 R8 完全同因：**mime.cache 缺失 → gdk-pixbuf formats 空 → 一切格式识别失败**。即 **4.1 的"根因=CI 旧 base 缓存"表述需订正为"v4 验证/部署环境无 mime"**。

#### 5.3、mime 部署问答与 update-mime-database 查证（2026-11-15）

**问1：不装 shared-mime-info 包、直接拷贝其数据目录，可行吗？**
- **可行**。`/usr/share/mime` 是纯数据目录；R8 实证即直接拷贝 builder 的 `/usr/share/mime` 进 rootfs，png/svg 立即翻 OK。
- 注意：① 需与 glib 版本/架构兼容（同源同为 alpine 3.13 无碍）；② 拷贝=只读快照，不随 apk 升级；要可维护仍建议 `apk add shared-mime-info`（`rootfs/src/Dockerfile` 已加，68ff901）。部署冻结点二者皆可。

**问2：数据目录文件格式？二进制还是可编辑？**
- `mime.cache` = **二进制**（编译后的 mmap 索引，运行时 gio 主要读它），由 `update-mime-database` 从 XML 源生成，**不可直接编辑**（手改无效）。
- 其余配套 = **纯文本可编辑**：`globs`（扩展名映射）、`magic`（幻数签名）、`types`/`aliases`/`subclasses`/`generic-icons` 逐行文本；`packages/*.xml` 为 XML 源定义。
- 有效口径：**改文本/XML 后必须 `update-mime-database` 重编出 `mime.cache` 才生效**（新版 glib 只读 cache，不读散文本）。

**问3：`update-mime-database` 是二进制还是脚本？源包在哪？可静态化吗？**
- **是 C 二进制**（非脚本），源码 `src/update-mime-database.c`，shared-mime-info 项目 meson 构建；运行时依赖 glib-2.0/gio-2.0/libxml2（动态链）。
- **源包**：`shared-mime-info`（freedesktop.org：`https://gitlab.freedesktop.org/xdg/shared-mime-info`）；alpine 二进制包同名 `shared-mime-info`（源码走 alpine abuild/aports 取）。
- **可静态化**：C + meson，配 xx-clang + glib/libxml2 静态 `.a` 即可。
- **但部署端不需要它**：rootfs 运行时只读 `mime.cache`，cache 由**构建期任意机器**生成一次即可；`apk add shared-mime-info` 已带现成二进制+cache。若要完全离线/自足，可选：静态编 `update-mime-database` 在构建期产 cache 并 COPY，或直接把现成 `/usr/share/mime` 分层 COPY（同问1）。

#### 5.4、gdk_pixbuf 构建错误日志源头修复：问题与答复总结（2026-11-15）

两轮「需求=问题 + 答复」总结（子节仅 5.4.1 / 5.4.2），保留原表格与段落结构。

##### 5.4.1、问题一 + 答复：gdk_pixbuf 编译期 clang 链接错误刷屏——根因/源头修/验证

用户需求：如何避免这种错误日志的出现，u-gtk/build.sh **要从源头解决，而不是屏蔽日志**（不要 `|| true`/重定向掩盖）。CI 日志片段：

```
>>> Compiling gdk-pixbuf...
clang-12: error: linker command failed with exit code 1   （×12）
>>> Installing gdk-pixbuf...
clang-12: error: linker command failed with exit code 1   （×4）
err 0, pass   （oneBuild 吞错）
[gdk_pixbuf]…共历时38秒
```

**根因（`ninja -v` 实证）**：失败目标 = `builtin_loaders` 之外 loader 的**共享模块** `libpixbufloader-*.so`（meson 在 `--default-library=static` 下仍把非内置 loader 编成 `.so`）；每条 `-shared` 链接把 `libgdk_pixbuf-2.0.a + libstaticpixbufloader-*.a + librsvg-2.a + libcairo.a/libintl.a/libxml2.a …` **整链拉入** → non-PIC 静态库进共享对象：

```
/usr/bin/…-musl-ld: libcairo.a(cairo-rectangular-scan-converter.o): relocation R_X86_64_TPOFF32 against 'sweep_line.1' can not be used when making a shared object; recompile with -fPIC
/usr/bin/…-musl-ld: libintl.a(bindtextdom.o): relocation R_X86_64_PC32 against symbol '_nl_msg_cat_cntr' can not be used when making a shared object; recompile with -fPIC
final link failed: bad value
clang-12: error: linker command failed with exit code 1
```

12 连败 ≈ 12 个 loader 模块；`oneBuild` 吞成 `err 0, pass` + install 兜底 cp 均为**治标**。

**源头修**：只需主静态库（含 png/jpeg/svg builtin loader，`ar` 自证 io-svg.c.o ∈ .a），**只编该 ninja 目标**即绕开一切 `.so` 链接与 query-loaders/csource 工具：

```
ninja -C build gdk-pixbuf/libgdk_pixbuf-2.0.a
# [1/2] 编 gdk-pixbuf-io.c → [2/2] ar csrD 合入 …io-jpeg.c.o io-png.c.o io-svg.c.o（REBUILD_RC=0，无 .so）
cp -f build/gdk-pixbuf/libgdk_pixbuf-2.0.a /usr/local/lib/ && cp -f /usr/local/lib/libgdk_pixbuf-2.0.a /usr/lib/
```

u-gtk/build.sh gdk_pixbuf() 实改：弃 `ninja -C build`（全量）+ `ninja -C build install` + 兜底 cp，改**单目标 ninja + 手动 cp**（头/.pc/query-loaders/csource 由 apk `gdk-pixbuf-dev` 兜底）。实跑结果：

| 项 | 结果 |
|---|---|
| BUILD_RC | 0 |
| `clang-12: error` 计数 | **0**（原 12 连败刷屏）|
| `libgdk_pixbuf-2.0.a` | 1061240B，含 io-svg.c.o / io-png.c.o |
| 构建耗时 | 17 秒（原 38 秒含错误重试）|

##### 5.4.2、问题二 + 答复：改法不会有副作用导致失败吧（改了这里坏了那里）

用户需求原话：之前这边改来改去，改了这里就坏了那里的，担心本次改法引入新问题。

**改动面**＝仅 gdk_pixbuf() 的“编译/安装动作”；meson 配置、patch、产物内容均未动（实测 .a 同 1061240B、io-svg/io-png 同 ∈ .a）→ 下游链接输入无变化；不再 `meson install` 会缺的（.pc/头/query-loaders/csource）由 apk `gdk-pixbuf-dev` 兜底。

集成验证（同一容器内 修改版 gdk_pixbuf() → pkg-config → lxtask）：

| 环节 | 结果 |
|---|---|
| pkg-config gdk-pixbuf-2.0 | 命中 apk `/usr/lib/pkgconfig/gdk-pixbuf-2.0.pc`，输出 `-I/usr/include/gdk-pixbuf-2.0 … -lgdk_pixbuf-2.0 -lgobject-2.0 -lglib-2.0 -lintl`（→ 本 .a）|
| 头文件/工具 | `/usr/include/gdk-pixbuf-2.0`、`/usr/bin/gdk-pixbuf-query-loaders`、`-csource` 均在 |
| 下游 lxtask 构建链接 | `LXTASK_RC=0`，产物 `/usr/local/static/lxde/bin/lxtask` |
| 产物 svg 链 | `rsvg_handle_new=2`、`org.w3c.svg.static=1`（方案A 未破坏）|

**结论**：换的是“怎么编/怎么装”的动作，没换“编出什么”——本次不是“改了这里坏了那里”型改动。日志中 `gi-docgen 406` 为 meson setup 阶段拉 docs 子项目的**既有告警**（非致命、与本改动无关，先前同样存在）。


## 二、imlib2 与 gtk2 共同依赖/适配现状问答（2026-11-15）

### 1、问与答原文收录（2026-11-15，原文，仅分析未改动）

#### 1.1、问（用户 2026-11-15）

gtk2、imlib2 都依赖 rsvg 等库。1. 后者当前是在 gtkmm224 的 dockerfile 构建的，后续考虑放到 gtk224 这边来；2. imlib2 之前手动跑应用应该也是有调整，内部自集成 jpg/png/svg 的解码，但当前的构建能生成的静态库并没有生效，具体表现 w-xxx 的五个应用都是识别不了图标图片；3. 上面两条解决之后，w-xxx 应用层二次调用 imlib2 构建应判断静态库是否已存在且代码/patch 无变化则跳过、有变化则增量构建（参考 gtk2 现有增量）。

#### 1.2、现况分析——两条链 + imlib2 注入库"独享"问题

依赖构建归属：
- **gtk224**（`alpine-builder-gtk224-2`）：`u-gtk/build.sh b_deps` 已编 **librsvg-2.a + libcroco-0.6.a**（CI 日志 `>>> Downloading librsvg... Compiling... Installing...` 可见），即 rsvg 其实**已在 gtk224 侧编好**。
- **gtkmm224**（`alpine-builder-gtkmm224-2`）：`Dockerfile.builder.gtkmm224` 又**重复** `u-gtkmm full` + `w-xlunch/build.sh imlib2`（24–25 行）→ **rsvg/imlib2 链被编了两份**，来源不一致。→ 用户第 1 条"挪到 gtk224 统一"方向正确，实为**去重**。

imlib2 注入库现状（w-xlunch/build.sh，2026-11-08 整改）：
- 手动适配：私有 `loader_svg.c` 覆盖 + python 幂等补丁 `src/lib/loaders.c`（注入 png/svg/jpeg 三 builtin loader，跳过 dlopen，因为 musl/静态下 dlopen 外部 loader 全失效）；`xx-clang -Dload2=xxx -Dsave=xxx -Dformats=xxx` 编 4 个 .o；**拷系统 .a → `/tmp/builtin/libImlib2.a` 注入后 ar r + ranlib**，`-L/tmp/builtin -lImlib2` 优先链。

#### 1.3、gtk2 与 imlib2 的共同基础库依赖

| 库 | gtk2 用途 | imlib2 用途 |
|---|---|---|
| **librsvg-2.a** | gdk-pixbuf svg loader（方案A） | svg loader（loader_svg.c） |
| **libcroco-0.6.a** | rsvg 的 CSS 解析 | 同上 |
| **cairo/pango/pangoft2** | rsvg 渲染面 | 同上 |
| **libpng/libjpeg/zlib/libxml2/glib/gobject** | 图片解码/基础 | png/jpeg loader + rsvg 基础 |

共同点就是 **librsvg+croco+cairo+pango+glib** 这条静态链，两边共用；差异仅在 gtk2 走 gdk-pixbuf loader 表、imlib2 走自己内嵌 loader。

#### 1.4、现有脚本是否"对不上号"——是，这就是故障根因

- **只有 `xlunch` 链了 `-L/tmp/builtin`**（注入库）；**`feh`/`scrot`/`hsetroot`/`tint2` 全是裸 `-lImlib2`**（w-feh config.mk sed、w-scrot/w-hsetroot 同款）→ 它们拉到的是**系统 `/usr/local/lib/libImlib2.a`（未注入内置 loader）** → 静态下 dlopen 外部 loader 失效 → **图片识别不了** → 与"w-xxx 五个应用都识别不了图标图片"完全吻合。
- 且 `/tmp/builtin` 是**容器内临时目录**：compile 链 feh/scrot/tint2 都是**独立 stage/独立容器**，**/tmp/builtin 不跨 stage 存在** → 即便脚本写了 `-L/tmp/builtin`，到其它 stage 也没有 → 必然回退系统库。
- imlib2() 本身**无增量/跳过**：full 每次全量 configure/make/install + 重建注入库。

#### 1.5、对应三条规划的回应

1. **librsvg 挪 gtk224 统一**：合理（现成已在 gtk224 编）；落地=删 gtkmm224 侧重复 build（`u-gtkmm full`/`w-xlunch imlib2` 那两段按需收敛），并理清 compile `basemm` 是否还依赖 gtkmm224 内的 rsvg。
2. **imlib2 注入库"不生效"根因**＝见 1.4：**其它 w-xxx 没用注入库 + /tmp/builtin 不跨 stage**。修法：把注入版 `.a` 做成**共享稳定产物**（如统一装 `/usr/local/lib/libImlib2.a`——把注入动作从 /tmp 私有改为覆盖系统库或独立共享路径），并让 feh/scrot/hsetroot/tint2 全量 `-L` 指向它。
3. **增量构建**：参考 u-gtk 的增量（patch 指纹/已存在跳过，如 `w-tint2 librsvg` 的 `test -s ... || build` 模式）——`libImlib2.a` 已存在且 loader_*.c/patch 无变化则跳过，有变化则增量重建。

### 2、开工定案与验证方案（2026-11-15 下午，用户拍板）

#### 2.1、开工/验证方案（细化）

**分工（用户拍板）**：imlib2 构建从 gtkmm224 Dockerfile.builder 挪到 **`u-gtk/build.sh b_deps` 尾部**（base 烘焙，统一入口仍 `bash /src/w-xlunch/build.sh imlib2`）；**余下（应用侧链接统一 + 增量 + 验证）由本侧处理，不依赖用户调整**（本地在 gtk224-2 容器直接调 imlib2() 验证）。

**核心事实（实测，2026-11-15）**：
- gtk224-2 基准镜像**无 `/usr/local/lib/libImlib2.a`**——imlib2 目前只在 gtkmm224 builder 构建，compile 的 w-xxx stage（FROM base）根本拿不到。
- `imlib2()`（w-xlunch/build.sh:27-140）产出两份：`make install` 的**普通库** `/usr/local/lib/libImlib2.a` + 注入 png/svg/jpeg 三内置 loader 的 `/tmp/builtin/libImlib2.a`（musl/静态 dlopen 外部 loader 全失效故内嵌；loader_svg.c 私有覆盖 + loaders.c 补丁注入 load2/save/formats）。
- **png/jpg/svg 三格式都必须支持**——注入的就是 `png_load2/svg_load2/jpeg_load2` 三符号，验证门禁全部按三格式查。

**Phase A · 构建注入库（builder-g224 = gtk224-2 基准）**
1. `TARGETPATH=/usr/local/static/imlib2 CONSOLE_LOG=no bash /src/w-xlunch/build.sh imlib2`（setsid 直拼，输出 `/_ext/tmp/svg/`；down_catfile 走 tarsrc 缓存，无则网络 $IMLIB2_URL）。
2. **门 A1（注入库成形）**：`nm /tmp/builtin/libImlib2.a | grep -cE "png_load2|svg_load2|jpeg_load2"` ≥ 3。
3. **门 A2（jpg/png/svg 三格式加载）**：最小 C 探针链注入库+rsvg 组，`imlib_load_image` 分别加载 `test.png`/`test.jpg`/`test.svg`（复用 lxtask svgtest 样式），三张全部非空即过。headless 无法加载（`--with-x` 无 DISPLAY）则挪 hdmi 容器 Xvnc 验。

**Phase B · 5 个 w-xxx 应用（每 app 一 commit）**
1. **链接统一**：feh（config.mk sed）/ scrot（LIBS=）/ hsetroot（LDLIBS=）的 `-lImlib2` 前补 `-L/tmp/builtin`；xlunch 已有（核查）；**tint2 摸底**——`-lImlib2` 在注释里，确认到底链不链（若不链则"5 应用"为 4 个，另查其面板图标走 gtk/gdk-pixbuf 还是 imlib2）。
2. **依赖组核查**：各 app `--start-group` 已含 `-lrsvg-2 -lcroco-0.6 -lxml2`（svg loader 静态链必需，lxtask 同款），逐个核对。
3. **门 B1**：各 app 出 bin，`xx-verify --static` PASS、`file` static、未定义符号 0。
4. **门 B2（注入符号链进 bin）**：`nm <bin> | grep -E "png_load2|svg_load2|jpeg_load2"` 三符号在——B1 过但 B2 空 = 仍拉普通库，不算对。
5. **门 B3（hdmi Xvnc 实跑三格式）**：feh 显示 / scrot 截图 / hsetroot 设壁纸 / xlunch 图标，png、jpg、svg 三格式逐张验证识别成功。

**Phase C · 收尾**
- **增量幂等（需求 3）**：`imlib2()` 内加 `test -s /tmp/builtin/libImlib2.a` + 指纹（`loader_svg.c` + `loaders.c` patch 的 md5）一致即跳过、有变化重建——放函数内部一处生效，`u-gtk b_deps` 尾部调用自然幂等。
- **落文档**：本方案（2.1）+ 执行结果按阶段回填到 2.1.x。

**风险点**：① imlib2 源码网络下载（tarsrc 顶层无 imlib2 目录，需先补缓存或网络可达）；② `--with-x` 在无 DISPLAY 下加载可能失败 → 门 A2/B3 挪 hdmi Xvnc；③ tint2 是否真链 imlib2（摸底决定范围）。

#### 2.2、Phase A/B 执行记录（2026-11-15 下午，builder-g224=gtk224-2 基准）

**Phase A 注入库 ✅（门 A1/A2 过）**
- `TARGETPATH=/usr/local/static/imlib2 bash /src/w-xlunch/build.sh imlib2`：down_catfile tarsrc 缓存命中（`tarsrc/w-xlunch/imlib2-1.7.4.tar.gz` 全局兜底），configure `--with-x` + `LDFLAGS=-static`，注入 png/svg/jpeg 三 loader → `/tmp/builtin/libImlib2.a`。
- 门 A1：`nm /tmp/builtin/libImlib2.a | grep -cE "png_load2|svg_load2|jpeg_load2"` = 6 ✅。
- 门 A2：最小 C 探针（`imlib_load_image`）三格式真解码：**test.svg → 16×16 / test.png → 8×8 / test.jpg（gtk demo 背景图）→ 400×400，全 OK**，编译错 0 ✅。
- 坑：① imlib2 的 `imlib_image_get_width()` 用 **context**（须先 `imlib_context_set_image(im)`），不是参数——探针第一版 w=0 假象；② 静态链补 `-lX11-xcb`（ximage.o 的 `XGetXCBConnection`）。

**Phase B 五个 w-xxx 应用 ✅（门 B1 过，B2 部分直证）**
- `imlib2()` 尾部**注入版覆盖 `/usr/local/lib/libImlib2.a`**（commit `2751cff`，二章 1.5-2"覆盖系统库"方案；base 内 imlib2 链接者仅 w-xxx，无其他影响）→ 五个应用裸 `-lImlib2` 即取注入库，**无需逐 app 改 -L**。
- 构建结果（均 rc=0、xx-verify PASS、undef=0）：**feh 36.5M / scrot 9.7M / hsetroot 9.7M(+hsr-outputs) / tint2 10.1M + tint2conf 13.6M / xlunch 36.1M**，TARGETPATH 各自 `/usr/local/static/<comp>`。
- 门 B2：**feh/xlunch（链接未 strip）`nm bin | grep -cE png_load2|svg_load2|jpeg_load2`=3 直证注入 loader 链入**；scrot/hsetroot/tint2 走 common `$LDFLAGS`（含 `--strip-all`）→ **nm 查不到=假阴性**，链接解析同为注入版 `/usr/local/lib/libImlib2.a`（该文件已 nm 证 6 符号）→ **待门 B3 实跑三格式确认**。

**待办**：门 B3（hdmi 容器 Xvnc 实跑 png/jpg/svg：feh 显示 / scrot 截图 / hsetroot 壁纸 / tint2 面板 / xlunch 图标）；增量幂等（需求 3，imlib2() 内 `test -s`+md5 指纹）；gtkmm224 侧去重（用户侧 u-gtk b_deps 挪入）。

**5 应用静态验证表（2026-11-15 补，builder-g224 实测）**：

| 应用 | 产物 | file | xx-verify |
|---|---|---|---|
| feh | 36.5M | statically linked, not stripped | PASS |
| scrot | 9.7M | statically linked, stripped | PASS |
| hsetroot | 9.7M (+hsr-outputs 996K) | statically linked, stripped | PASS |
| tint2 | 10.1M (+tint2conf 13.6M) | statically linked, stripped | PASS |
| xlunch | 36.1M | statically linked, not stripped | PASS |

全 rc=0 / xx-verify PASS / undef=0；feh/xlunch（未 strip）nm 直证 png/svg/jpeg 三 loader 符号链入；scrot/hsetroot/tint2 因 `--strip-all` 剥符号（nm 不可查属假阴性），同源注入版库链接。

### 3、2节完善前，直接开工修现有问题（2026-11-15 晚，用户拍板：不等 2 节完善，边 CI 边修）

#### 3.1、feh / tint2 / scrot CI 实测问题与修复（w-xxx 应用）

CI 跑 w-xxx stage 时暴露三个问题（2.2 只验到编译，未验到 CI 实跑）：

**① feh 编译刷屏 `fatal: No names found, cannot describe anything.`**（commit `65ff80c`）
- 根因：`config.mk: VERSION ?= ${shell git describe --dirty}`——gitclone 缓存仓无 tag → git describe 报 fatal 每次编译刷屏（73 次；编译容错继续、产物正常）。
- 修复：sed 加 `2>/dev/null \|\| echo 3.9.1` 兜底——**须在 `cd /tmp/fk-feh` 之后执行**（初版放 cd 前致 `sed: config.mk: No such file` 未生效）。
- 验证：fatal=0 / errs=0 / feh 37M PASS。

**② tint2 依赖 librsvg 链接失败 `undefined reference to jpeg_*`**（commit `7e01391`）
- 根因：librsvg 2.40 用 libjpeg（svg 内嵌 jpeg），configure 的 JPEG 依赖未进 `.so`/rsvg-convert 链接 → CI tint2 b_deps 实测 librsvg-2.so + rsvg-convert 全 `undefined jpeg_input_complete/jpeg_write_scanlines/...` → librsvg 未装上 → tint2 起不来（oneBuild `err 0, pass` 假绿）。
- 修复：librsvg() `make/make install` LIBS 追加 `-ljpeg`（`LIBS="${LIBS:-} -ljpeg"`，不覆盖 STATIC 路径的 z/lzma/bz2/m）。
- 验证：非 STATIC 路径（=CI 走法）rc=0 / jpeg_err=0 / undef=0，`.a`+`.so` 齐全。

**③ scrot 运行时截图失败（⚠️ 结论更正：用户 Xvnc 环境实跑异常，非缺 X）**
- 本机 Xvfb 下实测 scrot rc=0 出图（PNG save 正常，注入 imlib2 OK）——**但用户 Xvnc 环境运行截图仍失败**：编译 OK、运行时截图出错，**Xvfb 结论不成立**。
- 待排查方向：Xvnc 与 Xvfb 行为差异（AGENTS 3.1：Xvnc 与真实 xrdp 会话同源）；scrot 的 XShm/GetImage 抓屏路径或 imlib2 渲染在 Xvnc 下的差异。
- **下一步：builder-g224 装 tigervnc-server（Xvnc）复现真错再修**。

**③ 复查定论（2026-11-15 晚，hdmi 容器 Xvnc :312/313/318 实跑，按 AGENTS 3.1 全新 display 模板）——scrot 失败唯一条件 = 保存目标不可写；feh 真图可开**：
- 二进制取自新 rootfs-dbg（undock 分层解包，`--include=/rootfs/files1/usr/local/static`，scrot 4.2M / feh 12M，`no section header`＝UPX 压缩）→ stdin 管道入 hdmi `/tmp/rt/`。
- **scrot 四场景 sweep（headless + 全新 Xvnc）**：
  - A 无参数 cwd=`~/`：rc=0 出图（`2026-11-15-221033_1024x768_scrot.png` 2.4K ✅）
  - B 显式 `~/s.png`：rc=0 出图 ✅
  - C 无参数 cwd=`/`：**`scrot: failed to save image` rc=1** ❌
  - D 显式 `/root/x.png`：**`failed to save image` rc=1** ❌
- **定论**：scrot XShm 抓屏 + 注入 imlib2 PNG 保存链路正常；`failed to save image` = **保存目标对 headless 不可写**（imlib 保存失败原文）。headless 在可写 HOME/cwd 完全正常。**用户环境失败 = headless 会话 cwd/HOME 落 root 不可写目录**；部署侧保证 headless 起始 cwd 可写（=其 HOME）即过。
- **feh**（用户待审）：feh 真图（`feh_demo.png` 420x280 四色）在全新 Xvnc + headless 下**进程存活、控制台 0 错误、截屏 `feh2.png` 像素证实显示**（左上 255,0,0 红 / 中心 0,255,0 绿）✅；`feh` 无参数 = 扫 cwd 非图片文件报 `No Imlib2 loader` + `No loadable images specified` 退出（feh 正常行为，默认不开空窗口，需 `--blank` 类 flag）；git describe 编译期刷屏已修（①）。

**scrot 保存目录语义（用户确认清晰，2026-11-15 晚）**：
- **默认保存到"当前运行目录(cwd)"，不是用户家目录**：`scrot [OPTIONS...] [FILE]`——无 FILE 参时存 cwd（A 测 `~/`→存 HOME；C 测 `/`→试图存 `/`=失败）。CLI 工具惯例（同 import/xwd：默认落 cwd）。
- **指定方式（无配置文件、无环境变量**——`--help` 无 config 项、strings 无 `.scrotrc/SCROT_/config`）：
  1. 位置参数 / `-F`：`scrot ~/shot.png`（shell 展开 `~`）或 `scrot -F /home/user/shot.png`（绝对路径）
  2. strftime 模板：`scrot ~/'%Y%m%d-%H%M%S.png'`
  3. 运行时 cwd：无参=存 cwd（部署时保证会话 cwd 可写即可）
- **用户环境失败根因**：headless 会话**运行目录落在 root 不可写处**（如 `/`）→ 无参按 cwd 存 → 写失败 → `failed to save image`。普通用户登录后 cwd 本应 = `$HOME`（可写），scrot 默认可跑；只有会话起始目录异常才踩。
- **部署侧建议（任一）**：① rootfs 保证 headless 会话起始 cwd = 其 HOME（可写，最符合"普通用户应存家目录"预期）；② 调用处显式 `scrot ~/xxx.png`；③ 包 wrapper：`cd "$HOME" && scrot "$@"`。

#### 3.2、整体进展汇总（2026-11-15 晚，用户确认清晰）

**本轮三个（w-xxx 运行时/编译问题）**：

| 项 | 性质 | 状态 |
|---|---|---|
| **tint2**（librsvg `jpeg_*` undefined） | 编译真失败（librsvg 没装上） | ✅ **已修复**（`w-tint2` librsvg make LIBS+=`-ljpeg`，commit `7e01391`；非 STATIC 路径实测 jpeg_err=0，`.a`+`.so` 齐全） |
| **feh** | ①编译期 `git describe` 刷屏 ②运行时"直接退出" | ✅ **①已修**（sed 兜底版本，fatal=0，`65ff80c`）；**②证伪**——真图能开能显示（截屏 feh2.png 像素证实），无参数报错是 feh 扫 cwd 的正常行为。**待用户最终确认** |
| **scrot** | 运行时截图失败 | ✅ **已定论**（用户确认清晰）——默认存 cwd 非 HOME、无配置/环境变量；失败唯一条件=保存目标不可写；部署三建议（3.1 ③） |

**整体批次**（更早闭环，本地验证过）：geany ✅ / engrampa ✅ / dunst ✅（ci-rootfs 5.2.1）、pcmanfm ✅（5.2.2 三轮）、rofi ✅（5.2.3，9.3M static 可 `-version`）、imlib2 注入库 ✅ + 5 个 w-xxx 应用出 bin（二章 2.2）。

**结论**：tint2/scrot 实质解决；feh 编译期修完 + 运行时确认为正常行为，唯一悬着的是**用户对 feh 的预期**（是否要支持"无参数开空窗口"之类）。其余全部本地验证通过、CI 修复已推送。

#### 3.3、真机验证记录表（2026-11-15 用户 rootfs-dbg 最新实测反馈）

| 组件 | 真机实测（用户 rootfs-dbg） | 状态 | 文档跟踪 |
|---|---|---|---|
| geany | 正常 | ✅ | ci-rootfs 5.2.1 |
| engrampa | 正常 | ✅ | ci-rootfs 5.2.1 |
| rofi | 正常（9.3M static，`-version` 可跑） | ✅ | ci-rootfs 5.2.3 |
| lxtask | 正常 | ✅ | u-gtk 改造（11040000） |
| gpicview | 正常 | ✅ | ci-rootfs 2.2.x |
| xfce4（三件：thunar 等） | 正常 | ✅ | v-xfce4 |
| xrandr | 正常 | ✅ | — |
| xbindkeys | 正常 | ✅ | — |
| **pcmanfm** | **无二进制文件（部署仍失败）** | ⚠️ **根因已定 + 修复已提交（2026-11-16 复核）** | ci-rootfs 5.2.2 / 本二章 3.3 订正 |
| feh | 按用法执行使用：正常 | ✅ | 本二章 3.1 ①/③ |
| scrot | 按用法执行使用：正常（存可写 cwd） | ✅ | 本二章 3.1 ③ |
| tint2 | 待细化确认 | ⏳ | 本二章 3.1 ②（librsvg -ljpeg 已修，待 CI 复跑确认） |
| dunst | 依赖 dbus，待测 | ⏳ | ci-rootfs 5.2.1 |

> **订正（2026-11-16）**：pcmanfm 无二进制的**根因定案**——不是编译失败（`alpine-compile-2-dbg` 的 `/rootfs/usr/local/static/pcmanfm/bin/pcmanfm` 38.9M 存在，2023-12-02 旧构建），而是 **`rootfs/src/static/clear/usr-local-static-dir.txt` `### handAdd` 段第 156 行 `/usr/local/static/pcmanfm`（无 `#`，2024-09-25 commit `8658ae5` 加）被 `clear.sh` 当作 `rm -rf` 目标，整个 pcmanfm 目录（含 bin）在 rootfs 组装时被删**。主 pcmanfm 块（114-125 行）bin/etc/share 均为注释保留，但被 handAdd 重复条目覆盖。**修复：第 156 行加 `#`（提交待落）**。
> 验证链：`alpine-compile-2-dbg`（rootfs Dockerfile `bin2` 源，`COPY --from=bin2 /rootfs`）有 pcmanfm ✅ → `clear.sh`（181→184 行）`rm -rf /rootfs/usr/local/static/pcmanfm` → 最终 rootfs-dbg 无 pcmanfm ❌。
