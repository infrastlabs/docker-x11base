# ci-builder-gtk：alpine-builder-gtk224 更名 / 烘焙候选 / 缓存清理 分析（2026-11-09）

2026-11-09 启动。针对 builder 镜像 `infrastlabs/x11-base:alpine-builder-gtk224` 的三个诉求做**纯分析**（未改代码）：
① 镜像更名 `alpine-builder-gtk224` → `alpine-builder-gtk224-2`，梳理「构建入口 + 使用方」全部引用点；
② gtk224 已含 gtkmm，找出其他大体量/编译耗时、适合一并烘焙的静态库；
③ 同 gtk 复用缓存前提下，可清理哪些中间产物（减小镜像体积，且不缺口后续应用构建）。

分析手段：`docker diff builder-obox`（区分镜像内容 vs 容器 runtime 新增）、容器内 `du`、读 `compile/buildx.sh` / `compile/src/u-gtk/build.sh` / `builder/Dockerfile.builder.gtk224`。

## 章节表

- 一、gtk224（2026-11-09）
  - 1、镜像更名引用点全量清单（构建入口 + 使用方）
  - 2、gtkmm 烘焙现状 + 其他大/慢库候选
  - 3、缓存复用前提下的中间产物清理分析
  - 4、实施总结（2026-11-09 完成）
  - 5、arm64/armv7 兼容性分析（新加应用/库，2026-11-09，只分析）
  - 6、imlib2 烘焙决策与实施（2026-11-09）
- 二、u-gtk doExec 日志过滤 + 错误码识别（2026-11-11）
  - 1、容器备份（obox 已删 / awe 保留，2026-11-09/10）
  - 2、doExec/oneBuild 吞错根因 + 修复方案 + 日志过滤 + logfile 必要性（2026-11-11）
  - 3、构建失败根因定位与源码源镜像切换（2026-11-11）
  - 4、CI 三架构 gtk 构建错误分析（arm64/armv7 b_deps，2026-11-11 只分析未修）
  - 5、AR 魔改静态库方式盘点（u-gtk 及全构建脚本，2026-11-11）
  - 6、CI fresh 构建 gdk/x11 子库缺失根因分析与验证（2026-11-12，已分析+已验证，修复未落地）
  - 7、oneBuild 废弃/合并 doExec 分析与调整方案（2026-11-12，分析 + 方案A 已落地 + 验证）
  - 8、doExec 日志目录调整：/tmp/doExec 并入 .logs（2026-11-13，由五章镜像核查引出）
- 三、gtkmm224（抽取：原 2.7）
  - 1、gtkmm 栈构建验证（2026-11-11）
  - 2、pango 版本顺带结论（2026-11-10/11，纠正旧判断）
  - 3、gtkmm224 镜像核对与乌龙澄清（2026-11-12）
  - 4、gtkmm 栈组件并行化拆解分析（2026-11-12，只分析未落地）
- 四、应用调试（抽取：原 3.4 + 3.5）→ 已拆出至 `docs/2026/11110827-ci-builder-gtk-app.md`
- 五、CI实跑验证（2026-11-12~13）→ 已拆出至 `docs/2026/11110827-ci-builder-gtk-app.md`
## 一、alpine-builder-gtk224 → gtk224-2 分析（2026-11-09）

### 1、镜像更名引用点全量清单

#### 1.1 构建入口（compile/buildx.sh，`gtk224)` case）

| 行 | 现内容 | 更名改法 |
|---|---|---|
| `compile/buildx.sh:81` | `img="x11-base:alpine-builder-gtk224"` | → `x11-base:alpine-builder-gtk224-2` |
| `:84` | `cimg="$img-cache"` | 自动变 `...-gtk224-2-cache`（注意：会开新 buildx 缓存，见 3.5） |
| `:93` | `docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/Dockerfile.builder.gtk224 .` | 不变（构建入口文件沿用 `Dockerfile.builder.gtk224`；若要用 -2 专属 Dockerfile 需改 `-f`） |

#### 1.2 使用方（消费者）

| 文件 | 行 | 说明 |
|---|---|---|
| **`compile/src/Dockerfile:3`** | `FROM ${REPO}infrastlabs/x11-base:alpine-builder-gtk224 AS base` | **最关键**：所有 app stage 的根，必须改 -2 |
| `.github/workflows/syncer.sh:65` | `$src/infrastlabs/x11-base:alpine-builder-gtk224: $dst/...` | src/dst 镜像映射，更名后改 -2（或保留旧名用于迁移同步） |
| `AGENTS.md:27,35` | builder-obox / alpine-builder-gtk224 提及 | 更新镜像 tag 说明 |
| `README.md:81,84` | `infrastlabs/x11-base:builder  ##alpine-builder-gtk224` 等 | 注释/说明，改 -2 |
| `compile/src/v-geany/build.sh:76` | 注释 "builder-obox，alpine-builder-gtk224" | 注释同步 |

#### 1.3 文档引用（6 篇近况 + 2 篇历史）

- 近况（应改）：`docs/2026/11051218-v-geany.md`、`11051758-v-oth-impl01.md`、`11061251-v-oth-impl02-ibus01.md`、`11051633-v-pavucontrol.md`、`09261448-openbox-解析与优化.md`、`09261949-lxtask-解析与优化.md`。
- 历史（2024，建议**不改**，属历史记录）：`docs/core/pulse03.md`、`docs/core/pulse09-arm-retry2.md`。

#### 1.4 不动项

- `builder-obox` / `builder-awe` 是**运行容器名**，非镜像标签，更名不改。
- `builder/Dockerfile.builder.gtk224` 文件本身若需烘焙 gtkmm 则**加内容**（见 2 节），文件可沿用。

### 2、gtkmm 烘焙现状 + 其他大/慢库候选

#### 2.1 现状（关键事实）

- 当前镜像 `alpine-builder-gtk224` **1.27GB、2 年前**。`docker diff` 证实：**`/usr/lib/libgtkmm-2.4.a` 等 gtkmm 库是 runtime 新增（A），并不在镜像里**——即 gtkmm 是在 live 容器手工构建的，尚未写进 Dockerfile。
- `builder/Dockerfile.builder.gtk224`（485B）目前只 bake：openbox（fontconfig/Xrandr/pango）+ xcompmgr（Xdamage）+ `bash /src/u-gtk/build.sh b_deps`（atk/gdk/gtk）。**没 bake gtkmm。**

#### 2.2 已烘焙对象（live 容器 `/usr/lib` 的 gtkmm 链 ≈ 81M）

`libgtkmm-2.4.a` 42.7M + `libgiomm-2.4.a` 24.9M + `libglibmm-2.4.a` 9.9M + `libatkmm-1.6.a` 3.75M。

#### 2.3 其他大/慢库候选（live 容器 `/usr/lib/*.a` >1M，按「框架级共享 + 编译耗时」排序）

| 库 | 体量 | 是否值得烘焙 |
|---|---|---|
| **ICU**（icudata 27.3M + icui18n 6.8M + icuuc 3.4M） | ≈37.5M | **最值得**：编译极慢；librime/ibus-rime 依赖它。需确认目标应用是否都走 rime |
| **boost**（wave 4.5M + log 3.4M + log_setup 3.0M + 其它） | ≈11M+ | 次选：编译慢；若 geany/某应用用 boost 则值得 |
| nettle + hogweed（GnuTLS 链） | 7.0M+8.6M=15.6M | 视是否有 gnutls 应用 |
| libxml2 | 6.1M | 框架级、多应用用，值得 |
| cairo / pixman | 8.0M / 7.2M | 框架级，值得（若基础镜像已含则跳过） |
| libstdc++ / libgcc_s / libXi | 20.2M / 2.9M / 3.2M | 基础件，通常已含 |

#### 2.4 不要进 builder 的（应用专属产物）

`/usr/local/static/geany` 31.1M、`deps/librime` 9.5M、`xfce/libexo-1` 2.1M 等——留在**应用镜像**，别塞 builder。

> 结论：bake gtkmm（必须，写进 Dockerfile）+ **ICU 最优先**；boost/libxml2 视应用依赖再定；应用专属不碰。

### 3、缓存复用前提下的中间产物清理分析

#### 3.1 两层「缓存」

1. **buildx 层缓存**（registry `-cache` 镜像）：buildx.sh:85-88 `cimg=...-gtk224-cache`、`--cache-from/--cache-to mode=max`、ref=`REPO_TEN_HK`。**跨构建复用主力。**
2. **容器内源码缓存**（u-gtk 模型）：`/tmp/gtk` 有 `.git`+`config.status` → 增量复用；`inc_patch` 按 hash 增量（u-gtk/build.sh:129）；configure 用 SIGFILE 跳过（:207）；`.u-gtk-state` 状态目录（:153）；`.cache` 下载缓存（common.sh:27 `CACHE=$TARGETPATH/../.cache`）。

#### 3.2 镜像 vs 容器（`docker diff` 关键结论）

- **镜像内 `/tmp` 缓存 ≈ 412M**：gtk 274M、gdk-pixbuf 62M、pango 35M、atk 9M、Xdamage 4.7M、ibus-rime 27M。
- **runtime 新增（不在镜像，但重新 commit 会进镜像）**：gtkmm-stack 650M、tlink* 684M、ibus-panel 副本 163M、p-* 187M、rofi-build 85M、ibx11 89M、pa13 60M、glibmm-pristine 58M、xfce-* 77M、ibus-pristine 30M、ibus-build 221M、static_temp1 14.7M。

#### 3.3 可清理（删了后续构建不缺）

- `/var/cache/apk` **4.4M**（apk 包缓存，标准清）
- `/root/.cache` 488K
- **坏缓存**：`/usr/local/static/.cache/libexif-0.6.23.tar.bz2` = **0 字节**（下载失败，删后自动重下）
- 各类 `*.log` / `*.out`（小，可清）
- runtime 实验残留（tlink*/ibus-panel 副本/p-*/xfce-*/pa13/ibx11/ibus-build/static_temp1）——**只要不 commit 就不进镜像**；若要进新镜像需在 Dockerfile 里 `rm -rf`。

#### 3.4 必须保留的缓存（否则失去「复用」意义）

- `/tmp/gtk`（含 `.o`/`config.status`/`.git`）——**gtk 增量缓存核心**
- `/tmp/gtkmm-stack`（子目录均有 `config.status`，无 `.git`，靠 32.5M 的 `.tar.xz` 恢复）——**gtkmm 增量缓存核心**；tarball 是唯一恢复源，**保留**（才 32.5M）
- `/usr/local/static/.cache/*.tar.*`（下载缓存，避免重下）
- `/usr/lib/*.a` + pkg-config/头文件（成品 + 链接依赖，**绝对保留**）

#### 3.5 两个权衡点

1. **更名会重置 buildx 缓存**：`cimg` 自动变 `-gtk224-2-cache` → 首建缓存为空。想复用旧缓存，可在首次构建把 `cimg` 临时指向旧 `-gtk224-cache`（或手动 docker tag）。
2. **要缓存就不要指望大幅减体积**：gtk+gtkmm 的 `/tmp` 源码缓存 ≈ **924M**，是镜像最大头。若进一步压缩，只能二选一：只留 `config.status`+`Makefile`（丢增量 `.o`，改 patch 会全量重编），或把 `/tmp` 缓存移出镜像层（Dockerfile 不 commit）。

### 4、实施总结（2026-11-09 完成）

三个诉求于 2026-11-09 全部落地（每文件单独提交，AGENTS §3.1；gtk2 构建在 `builder-awe` 验证，§5.1）。

#### 4.1 更名落地（12 提交）

| 文件 | 改动 | commit |
|---|---|---|
| `compile/buildx.sh:81` | `img` → `x11-base:alpine-builder-gtk224-2` | `83712d6` |
| `compile/src/Dockerfile:3` | `FROM ${REPO}infrastlabs/x11-base:alpine-builder-gtk224-2 AS base` | `1402759` |
| `.github/workflows/syncer.sh:65` | images.yaml 同步映射改 `gtk224-2` | `cf4b433` |
| `README.md:81,84` | 注释 + docker run 示例 tag 改 `-2` | `467fa69` |
| `AGENTS.md:27,35` | 构建模型/构建容器 镜像 tag 说明改 `-2` | `b759b13` |
| `compile/src/v-geany/build.sh:76` | b_deps 注释镜像 tag 改 `-2` | `f4919ed` |
| 近况文档 6 篇 | 按 AGENTS §3.2 **不改旧结论**，追加 `> **订正（2026-11-09）**：...` 注 | `90f44a5..b2d13d5` |

> 2024 历史文档（`docs/core/pulse03.md`、`pulse09-arm-retry2.md`）未动（历史记录）。`builder-obox`/`builder-awe` 是容器名，未改。

#### 4.2 烘焙落地 + u-gtkmm cp 路径修复

- `compile/builder/Dockerfile.builder.gtk224`（commit `f19e230`）：
  - `apk add gawk git icu-static icu-dev`（ICU 为 runtime 新增、不在镜像，须加；供 rime 链）。
  - u-gtk `b_deps` 后加 `RUN bash /src/u-gtkmm/build.sh full`（7 组件+mm-common 静态，`.a` 落 `/usr/lib`，供 pavucontrol/gsm 复用）。
  - 末尾清 apk 包缓存/构建日志/坏（0字节）libexif 缓存；**保留** `/tmp/gtk`+`/tmp/gtkmm-src` 源树（增量复用）与 `/usr/lib/*.a`（§5.2 gtk2 `.a` 禁清）。
- `compile/src/u-gtkmm/build.sh`（commit `bb2cd58`）：实跑发现 libsigc++ 的 `.a` 拷贝路径 `libsigc++-2.0/.libs` 与实际落点 `sigc++/.libs` 不符，`set -e` abort；全部 8 个 `.a` 拷贝行改 `[ -f /usr/lib/X.a ] || cp "$(find . -name X.a 2>/dev/null | head -1)" /usr/lib/`（make install 已装则跳过；真缺才 abort；布局随 tarball 而异）。

#### 4.3 验证（builder-awe，AGENTS §3.3）

- `bash /src/u-gtkmm/build.sh full` 全流程跑通：7 组件全 build、`pkg-config gtkmm-2.4 OK: 2.24.5`。
- 8 个 `.a` 全落 `/usr/lib`：libsigc 36K / glibmm 954K / giomm 3.4M / cairomm 256K / pangomm 291K / atkmm 583K / gdkmm 491K / gtkmm 7.4M。
- `libgtkmm-2.4.a` 现 **7.4M**（Nov 5 曾 42.7M，为 `-Os` 优化版）；`nm` 含 6912 个 Gtk 符号。
- 最小 gtkmm 程序**动态链接成功**（gtkmm/gtk 全符号解析 → 库完整）；`-static` 链接仅缺 gdk-pixbuf SVG 的 `rsvg_*`（librsvg，应用层处理，非 bake 问题）。

#### 4.4 注意（后续构建）

1. buildx `cimg` 自动变 `-gtk224-2-cache`（首建缓存为空；复用旧缓存需首次临时指向旧 `-gtk224-cache`）。
2. Dockerfile 构建依赖 `download.gnome.org`（**宿主可达 HTTP200**；builder 容器网络不通 GNOME，实跑只测 tarball 路径）。
3. 已推 `6d56fe5..bb2cd58`。真正出镜像跑 `compile/buildx.sh gtk224`（首次全量下载+编 gtkmm，较久；之后 buildx `-cache` 层复用）。

### 5、arm64/armv7 兼容性分析（新加应用/库，2026-11-09，只分析未实建）

> **结论：推断可移植，但未实证。** 脚本层/库层无 x86 限定，可移植性高；但新 21 组件 + gtkmm/ICU 只在 **amd64** 构建验证过，**arm64/armv7 从未实建**（推断，非实证）。

**① 多架构构建：arm64/armv7 是既定目标。** `buildx.sh` 所有 builder/compile case 一律 `--platform linux/amd64,linux/arm64,linux/arm`（gtk224 case 第 90 行同）；`compile/src/Dockerfile` **无 arch 分支**（`TARGETPLATFORM` ARG 声明但未用）→ 纯靠 buildx **QEMU 多架构**。2 年前 gtk224 镜像 1.27GB 即按 3 架构构建；`docs/confs/02/arm64-pulse-alpine.txt`（2024）记录过 **native aarch64** 编 pulseaudio → arm64 是真实目标。

**② 构建脚本层：无 x86 限定（可移植）。** 新组件 build.sh 全量 grep `x86_64|__asm|SSE|AVX|-march|\.S` → 仅命中注释/错误日志字符串（fluxbox/suckless/u-gtk/v-pcmanfm/x-xrdp），无真实 x86 专属汇编或编译 flag；无 `uname -m`/`getconf` arch 探测（唯一 `[host_machine]` 是 openbox config 片段）；`common.sh` `CC=xx-clang`/`CFLAGS=-Os`/`LDFLAGS=--static` 全架构中性 → **脚本层可移植**。

**③ 库层：gtkmm/ICU 可移植。** gtkmm 栈（glibmm/giomm/atkmm/cairomm/pangomm/libsigc++/gtkmm/gdkmm）纯可移植 C++（GLib/GTK 包装），无 x86 asm，Android/Linux arm 普遍编译；ICU 有 arch 优化代码但有 C 回退，arm64/armv7 支持（Android 用 ICU on arm），apk `icu-static` 按 arch 提供；cairomm→cairo、pangomm→pango 有 arch 后端（NEON/asm）但有 C 回退；imlib2（w-feh/w-scrot/w-hsetroot/w-xlunch/w-tint2 依赖）有 x86 MMX/SSE 优化但有 C 回退，arm 普遍可用。

**④ 未验证（关键缺口）。** 新 21 组件 + gtkmm/ICU 只在本机 amd64（builder-awe/obox 均 amd64）构建/验证；arm64/armv7 从未实建 → ②③ 是推断。

**⑤ armv7（32 位）特有风险（最可能的坑）。**
- **`-latomic`**：armv7 无原生 64 位原子，glib/glibmm/gtkmm 静态链可能需显式 `-latomic`（项目当前**未用**，grep 无命中）→ armv7 可能报 `undefined __atomic_*`；**arm64 不需要**。
- **硬浮点一致性**：alpine arm 默认 `gnueabihf`（硬浮点），静态链须全链同 ABI，混软/硬浮点会链接失败。
- 32 位大文件/长双精度边缘；armv7 风险 > arm64。
- QEMU 模拟构建慢但功能可用；GUI 运行时验证在 QEMU 下行为可能不同（AGENTS §3.1 用 Xvnc，需真机/arm 实跑）。

**⑥ 建议（验证路径）。**
1. 真正验证：`compile/buildx.sh gtk224` 已按 3 架构，出镜像即验；或先单架构 `--platform linux/arm64`（快）/`linux/arm`（QEMU）build 新 stage 看是否过。
2. 若 armv7 报 `undefined __atomic_*` → 对应 stage 的 link 组内加 `-latomic`（同 `--start-group`）。
3. 实跑用 `docker run --platform linux/arm64` 起的容器（或 native arm 机）验产物，别只信 amd64 结果。

### 6、imlib2 烘焙决策与实施（2026-11-09）

> **决策：烘焙 imlib2 进 gtk224-2。** 它是 5 个 `w-*` 应用（feh/scrot/hsetroot/tint2/xlunch）共享的框架级图片库；Dockerfile 里 feh/scrot/tint2/xlunch 各自 stage 重复下载+编译 imlib2（~4 次/镜像）。虽然 `libImlib2.a` 仅 **597KB**、编译 ~1-2min（不满足「大/慢库」标准），但作为真框架级共享库，烘焙可消除重复构建 + sourceforge 重复下载（源址多镜像、常不稳）。

**烘焙要点（区别于 gtkmm/ICU）：**
- 必须用 `w-xlunch/build.sh imlib2` 的**定制构建**（`make install` 后手动把 **PNG/SVG/JPEG loader 内嵌**进 `libImlib2.a`），非单纯 `make install`——否则 feh/scrot 等丢图片格式支持。
- 前置 apk：`libjpeg-turbo-static jpeg-dev`（内置 jpeg loader 需 `jpeglib.h`）+ imlib2 函数内自带 `apk add xorg-server-dev`。
- 产物落 `/usr/local/lib/libImlib2.a`；`/tmp/imlib2` 源树保留作缓存（同 gtk 复用模型）。

**落地**：`compile/builder/Dockerfile.builder.gtk224` 的 apk 行加 `libjpeg-turbo-static jpeg-dev`；u-gtk `b_deps` 后加 `RUN bash /src/w-xlunch/build.sh imlib2`。后续 w-* stage 的 b_deps 里 imlib2 调用保留（幂等，已存在则复用/跳过）。

### 7、gtkmm 镜像 svg loader 未生效（2026-11-13）

#### 7.1、发现与根因分析（2026-11-13，镜像内无日志、只能构建链推断）

> **背景**：拉取新 gtkmm224-2 镜像（`sha256:328141db`，Digest 新于旧 `d4c994c8`）后，按 AGENTS 五章 4 节核查 gtk2 图标/主题支持：**主题引擎（murrine/pixmap）已生效**（libgtk 有 `pixmap_theme_*`/`theme_pixbuf_render` 等 73 个 theme 符号），但 **SVG 图标 loader 未生效**。

**实测（新 gtkmm 镜像 `libgdk_pixbuf-2.0.a`）**：

| 项 | `gtkmm224-2`（新 328141db） | `gtk224`（builder-awe 容器） |
|---|---|---|
| libgdk_pixbuf-2.0.a 大小 | 1,040,794 B | 1,314,642 B |
| svg 符号数（`nm \| grep -ic svg`） | **0** | **15**（含 `_gdk_pixbuf__svg_fill_vtable`）|
| 可用 loader | 仅 jpeg/png | jpeg/png + **svg** |

**根因（镜像内日志看不到，推断）**：
1. **镜像内无构建日志**：`/rootfs/usr/local/static/.logs`、`/usr/local/static/.logs`、`/tmp/*.log` 全无——Dockerfile.builder.gtkmm224:27 `rm -f /tmp/*.log /tmp/*.out` 构建时清理，**无法从镜像内日志定位**。
2. **u-gtkmm 不重编 gdk-pixbuf**：`u-gtkmm/build.sh` 的 `b_deps` 只 `echo "base GTK2"` 检查、`c_gtkmm` 只产 `libgdkmm/libgtkmm` 绑定层（`u-gtkmm/build.sh:141-152`），**不碰 libgdk_pixbuf** → gtkmm 镜像 libgdk_pixbuf 继承自 `FROM gtk224-2`。
3. **u-gtk 有 svg patch 但 gtk224-2 可能未烤**：`u-gtk/build.sh gdk_pixbuf()`（:41-76）应用 `gdk-pixbuf-2.42.8-lxtask-static.patch`（builtin svg loader，:51）并 `cp /usr/local/lib/libgdk_pixbuf-2.0.a /usr/lib/`（:75）——理论上 `Dockerfile.builder.gtk224:15 RUN bash /src/u-gtk/build.sh b_deps` 应烤入 svg loader。但 gtkmm（FROM gtk224-2）无 svg → **gtk224-2 镜像构建早于 svg loader patch 加入**（patch 是 2026-11 上旬 lxtask 3.6.1 才加，gtk224-2 未重烤）→ FROM 继承无 svg 版。
4. **builder-awe 有 svg 是容器层**：builder-awe 用 `alpine-builder-gtk224`（无 `-2`，2 年前镜像），其 svg 版 libgdk_pixbuf 是容器内跑过最新 u-gtk b_deps（AGENTS 五章 1：改造版 gtk2 只在 builder-awe 构建）所致，**非镜像自带**——不能以 builder-awe 反推 gtk224-2 含 svg。

**修复方向（需实证 gtk224-2 现状）**：
- **A（FROM 源）**：拉 gtk224-2 镜像测 libgdk_pixbuf svg 符号，确认是否缺；若缺则**重烤 gtk224-2**（Dockerfile.builder.gtk224 已含 u-gtk b_deps + svg patch）→ 重烤 gtkmm224-2（FROM 新 gtk224-2 继承 svg）。
- **B（gtkmm 镜像内补）**：Dockerfile.builder.gtkmm224 在 u-gtkmm 后补 `RUN bash /src/u-gtk/build.sh gdk_pixbuf`（重建含 svg loader 版，同 libgtk theme_pixbuf_render 处理）——不改 FROM，只重烤 gtkmm。
- **净影响**：SVG 图标（Papirus，实测 509 svg/0 png）在静态 gtk2 下**无法显示**；需 PNG 集 `elementary-xfce` 或补 svg loader（u-gtk.md 改造项 3）。

##### 7.2、根因确认 + 修复（2026-11-13，镜像内日志 + 实跑验证）

> **背景**：用户重构建 `gtk224-2`（fd811b17）后图标仍故障，实测 `libgdk_pixbuf-2.0.a` 仍 svg=0/1.04MB。7.1 的"构建早于 patch"推断被证伪——**patch 在、构建也跑了 svg，但编成了独立 `.so`**。

**根因（镜像内日志铁证）**：`/usr/local/static/.logs/doExec/u-gtk/gdk_pixbuf.log`：
- `patch -p1` 应用成功（gdk-pixbuf-io.c/io-svg.c/meson.build/meson_options.txt 5 文件）
- `Builtin loaders : png`（**只 png，无 svg**）；`Installing libpixbufloader-svg.so to .../loaders`（svg 成**独立动态 loader**）
- 直接原因：`u-gtk/build.sh gdk_pixbuf` meson 命令 `meson build --default-library=both` **没传 `-Dbuiltin_loaders=svg`**；而 patch 只把 svg 加进 `meson_options.txt` 的 **choices**，**默认 `value:['png','jpeg']` 不含 svg** → meson 把 svg 当普通 loader 编 `.so`（dlopen 用不上）。

**修复**（commit `b7da717`）：`u-gtk/build.sh` gdk_pixbuf meson 改 `-Dbuiltin_loaders=png,jpeg,svg`。

**实跑验证**（builder-awe / gtk224-2 容器，gdk_pixbuf 增量）：
- 修复后 `libgdk_pixbuf-2.0.a` = **1,314,642 B，svg=15 符号**（vs 旧 1,040,794 B svg=0）——svg 已编进 `.a`。
- 注：日志 `xmlNewEntity`/`pango_cairo_font_map_get_default` 链接错误 = 构建期工具链 librsvg 测试程序失败（缺 xml2/pango 传递），**不影响 `.a` 产出**。

**结论**：7.1 的"gtk224-2 构建早于 patch"推断**不成立**；真根因是 meson `builtin_loaders` 默认不含 svg（patch 没改默认 value）。修 build.sh 后重烤 gtk224-2→gtkmm224-2 即生效。

**⚠️ 二次验证（干净 gtk224-2 容器 `ver-gtk224`，2026-11-13）——发现第 2 层根因**：
- `b7da717` 后 builder-awe svg=15 是**容器层旧残留**（误导）；**干净 gtk224-2 容器跑 gdk_pixbuf 仍 svg=0**。
- 日志：`libstaticpixbufloader-svg.a` 编译了（`-Dbuiltin_loaders=svg` 生效），但链接 `libgdk_pixbuf-2.0.so` 失败：`undefined reference to xml*`→`pango_cairo_*`→`cr_*`（按序补依赖逐个暴露）。
- **根因**：`librsvg-2.0.pc` Requires **只有** `glib-2.0 gio-2.0 gdk-pixbuf-2.0 cairo`，Requires.private 空——**缺 pangocairo/libxml-2.0/libcroco-0.6**（librsvg 静态依赖链，lxtask 3.6.1:804 `-lrsvg-2 -lcroco-0.6 -lxml2`）→ meson `dependency('librsvg-2.0')` 不带这些 → 链接 librsvg-2.a 失败 → svg loader 未编入 `.a`。
- **修复**：`librsvg-2.0.pc` Requires 补 `pangocairo libxml-2.0 libcroco-0.6`（w-tint2/build.sh librsvg make install 后 sed 补）；实跑 `libgdk_pixbuf-2.0.a` = **1,060,650 B，svg=19 符号**，undefined 清零。
- **结论**：svg loader 需**两层**修复——① `-Dbuiltin_loaders=svg`（u-gtk gdk_pixbuf，b7da717）② librsvg `.pc` 补依赖（w-tint2 librsvg）。两者齐备重烤 gtk224-2→gtkmm224-2 才真正生效。

##### 7.3、打印 / 输入法适配核查（2026-11-13，gtk224-2 镜像）

> **背景**：svg loader 修复后，按 AGENTS 五章 4 项核查打印 / 输入法适配（gtk2 应用验证项②③④之一）。

**打印（print backends）✅ 正常**：
- `libgtk-x11-2.0.a` 含 `_gtk_print_backend_file_init/create/exit` + `_gtk_print_backend_lpr_init/create/exit`（file/lpr 两 backend 编进 libgtk）。
- gtk.log 确认 `gtk2-2.24.33-printbackends-static.patch` 应用（`inc_patch: ...printbackends-static.patch changed -> reset+apply` + patching gtkprintbackend.c / file / lpr 3 文件）。
- 结论：print 静态适配已生效，无需处理。

**输入法（ibus）❌ 未生效**：
- 镜像 `libgtk-x11-2.0.a` **无 ibus 符号**（`nm` 仅 gtk 基础，无 `_gtk_im_module` ibus 注册）。
- 根因：`u-gtk/build.sh gtk_ibus_a2()`（:93）前置检查 `/tmp/ibus/client/gtk2/.libs/im_ibus_la-ibusim.o`，**缺失则 A2 SKIP**（:103）；而 **u-gtk b_deps 无 ibus 构建步骤**（仅 apkdeps/pango/libxrandr/Xdamage/libcroco/librsvg/atk/gdk_pixbuf/gtk），`Dockerfile.builder.gtk224` 也只跑 u-gtk b_deps → 镜像构建时 `/tmp/ibus` 不存在 → **A2 SKIP → ibus 未编进 libgtk**。
- 佐证：builder-awe 容器层有 `/tmp/ibus`（手工构建过）→ 其 libgtk 含 `_gtk_im_module_create/list/get_default_context_id`（merge 过）；镜像无 → 差异证明镜像构建漏了 ibus。
- 修复方向（未落地）：
  1. `Dockerfile.builder.gtk224` 在 u-gtk b_deps 前加 `RUN bash /src/v-ibus/build.sh ibus`（构建 `/tmp/ibus`，v-ibus:188 产出 `im_ibus_la-ibusim.o`）→ u-gtk gtk() 的 `gtk_ibus_a2` 即可 merge。
  2. **源码源**：v-ibus `ibus()` 源码走 `git clone $GITHUB/ibus/ibus@1.5.35`（:146，仓内无 ibus tarball，`compile/tarsrc` 也无）——容器 github 可能不通，需缓存兜底（宿主克隆 ibus@1.5.35 入 `tarsrc-git/ibus` 或下载 ibus-1.5.35.tar.gz 入 `tarsrc`）。
  3. 中文输入法可能仍走 **xim**（不依赖 ibus）——但 AGENTS 五章 4 项要求 ibus 可输入，故 ibus 适配需补。

## 二、u-gtk doExec 日志过滤 + 错误码识别（2026-11-11）

> 起因：gtkmm CI 构建失败（`pangomm/attrlist.cc: pango/pango-markup.h not found`，2026-11-10）。排查 pango 版本时发现 `u-gtk/build.sh` 的并发 `doExec` **记录不到错误码**——`atk` 克隆失败（`fatal: could not read Username`）后仍报 `err 0, pass` 继续跑。根因定位到 `common.sh` 的 `oneBuild` 吞错，而非 doExec 本身。

### 1、容器备份（obox 已删 / awe 保留，2026-11-09/10）

磁盘告急（overlay 50G 满 99%），评估两个 builder 运行容器 `builder-obox` / `builder-awe` 的可备份价值后，备份「未入库手工脚本 + 静态库」到宿主；obox 容器删除释放空间，awe 保留（未删）。

| 容器 | 镜像 | 状态 | 备份内容 | 宿主备份位置 |
|---|---|---|---|---|
| `builder-obox` | alpine-builder-gtk224 | **已删**（释放 ~4GB，磁盘 99%→91%） | 13 未入库脚本 + 25 个 .a | `/_ext/home/headless/xm-zs01/obox-backup/` |
| `builder-awe` | alpine-builder-gtk224 | 保留（未删） | 67 脚本 + 15 个 .a | `/_ext/home/headless/xm-zs01/awe-backup/` |

- **obox**（2026-11-09）：13 个未入库手工脚本（`build-panel.sh`/`link-rime.sh`/`link_ibus_x11.sh` 等 ibus-rime 静态链接配方，均未入库）+ `/usr/local/lib/*.a` 25 个（imlib2/librsvg/croco/xcb-* 系列）；`/usr/local/static` 334.9M 编译产物（openbox/geany/engrampa/scrot 等）**未备份**（可重建）；sha256 校验一致后删容器。
- **awe**（2026-11-10）：67 个手工调试脚本（ibus/rime/gtk/theme/pcmanfm/xfce4 配方）+ 15 个 .a（libfm/menu-cache/xdg-basedir/Xi/dbus-1/lua 等）；`/usr/local/static` 405.1M（awesome/awm/pavucontrol/pcmanfm/xlunch/thunar 等 13 个 obox 无）**未备份**；sha256 校验一致，容器保留。
- 两容器 `/src` 均软链宿主仓库 `compile/src`（源码/构建脚本无需备份）；`/_ext` 宿主挂载。

### 2、doExec / oneBuild 吞错根因 + 修复方案 + 日志过滤 + logfile 必要性（2026-11-11）

#### 2.0 需求原文 + 拍板 + 答复 + 实施记录（2026-11-11 完成）

**需求原文（user，2026-11-11）：**

> git pull，我给 u-gtk/build 加的 doExec，目的：1 独立记录日志，控制台回显过滤减少刷屏日志；2 记录执行完毕的错误码。需你完善：1 过滤那里，看还有哪些日志适合回显；2 对于并发执行，wait 后要识别错误码记录，对应项错误则报错退出处理，非并发的 doExec 也要是识别的。先给思路，完整日志上传到 /_ext/tmp/ 下了，zip 文件。

**拍板（user）：**

| 项 | 拍板 |
|---|---|
| 过滤 | **按推荐**：正向白名单；重复编译器警告控制台丢弃（只留日志文件） |
| oneBuild | **修复**；管道方式可改 doExec 写法；另分析原 logfile 是否还有必要 |
| doExec 位置 | 先**不加全局**（common.sh），跑顺才考虑移；但设计要考虑后续移 common 的场景 |
| 实时回显 | **要保留**，不改掉原写法 |

**答复（实时回显，2026-11-11）：**

> **没有改掉实时回显**，只是换了"取错误码"的方式。原 `$cmd $args > >(tee -a log \| grep ...) 2>&1` 与现 `( set +e; $cmd $args; echo $? > $rcfile ) 2>&1 \| tee -a "$lf" \| grep 白名单` **都是实时流式**（tee 一边接收一边写日志+转发回显）。区别仅：① 去 bash 专属 `>(...)` 进程替换改标准管道（POSIX 可移植，为移 common 做准备）；② 错误码改临时文件精确捕获（原 `$?` 取进程替换/管道尾部，吞错恒 0）。回显行为一致。

**实施记录（已完成，2 提交已推）：**

- **`common.sh` oneBuild 修复**（commit `9ab5919`）：
  - 去函数级 `set +e`（吞错帮凶）；改 `mktemp` 临时文件捕获 `$1` 真实退出码（子 shell 内 `set +e` 保 `$1` 失败继续行为不变）。
  - `return $rc` → 调用方 `set -e` 正确捕获；管道 `|| true` 防 find/tail 无内容误触发。
- **`u-gtk/build.sh` doExec 重写 + doExec_check**（commit `ece91f2`）：
  - doExec：去 `>(tee|grep)` 进程替换改标准管道（保实时回显、POSIX）；rc 用临时文件精确捕获；过滤改正向白名单（原 `warn|error` 被 ~23,500 行重复编译器警告淹没且漏 `fatal:`/`can't stat`/`No such file`）。
  - 新增 `doExec_check`：并发组 `wait` 后读 `/tmp/doExec/_exec_result.txt`，任一 `rc!=0` → 打印失败项 + 返回 1（调用方 `|| exit 1`）。
  - `b_deps`：每组并发前 `: > _exec_result.txt`，`wait` 后 `doExec_check || exit 1`；非并发 doExec 由调用方 `set -e` 捕获。
  - `*)` case：`doExec oneBuild $1` → **`oneBuild $1`**（去嵌套 doExec，消除 3 份冗余日志）。

**验证（隔离测试，非容器）：**

- doExec：成功只回显 `>>>` 里程碑（noise/WARNING 不回显）；`exit 3` → **rc=3**（精确非 0）；并发 `doExec_check` 只报失败项。
- oneBuild：`err 0, pass`/`err 3, fail` + `tail -200`；`oneBuild_rc=3`；调用方 `set -e` **中止且 subshell_rc=3**；`$1` 内 `set +e` 行为不变。
- `bash -n` 与 `sh -n` 均通过。
- **待实跑**：`builder-awe` 里 `bash /src/u-gtk/build.sh b_deps` 验证并发错误码真正捕获（如 atk 克隆失败 → `doExec FAILED` + `exit 1`，不再 `err 0, pass` 继续）。

#### 2.1 根因：`common.sh oneBuild` 吞错（3 个 bug）

`oneBuild`（common.sh:51-65）是三处缺陷叠加，导致构建函数失败被**完全吞掉**：

| 行 | 问题 | 后果 |
|---|---|---|
| `common.sh:55` | `set +e` 关掉 errexit | 后续命令失败不退出 |
| `common.sh:59` | `$1 \|tee $logfile` 管道退出码 = `tee` 的（0），非 `$1` 的 | `$1` 失败被管道吞掉 |
| `common.sh:63` | `test "0" != "$?"` 的 `$?` 是 `find \|sort`（:62）的，非 `$1` 的 | **恒报 `err 0, pass`**，与 `$1` 实际结果无关 |

→ `bash /src/u-gtk/build.sh atk` 即使 `atk` 克隆失败也 `exit 0` → `doExec` 记录 `0`。**不修 oneBuild，doExec 怎么改都拿不到真实错误码。**

#### 2.2 修复方案（拍板②：oneBuild 修复 + doExec 写法可改）

**oneBuild**：用临时文件取真实退出码（`#!/bin/sh` 无 `PIPESTATUS`，须可移植）：
```sh
local rcfile=$LOGS/.rc-$$
( $1; echo $? > $rcfile ) 2>&1 | tee $logfile
local rc=$(cat $rcfile); rm -f $rcfile
...
if [ "$rc" != 0 ]; then echo "err $rc, fail"; tail -200 $logfile; return $rc; else echo "err 0, pass"; fi
```
（`return $rc` 让调用方/doExec 捕获；`set +e` 仅包住非致命段或去除。）

**doExec**：
- 非并发：`$cmd; rc=$?; [ $rc != 0 ] && { echo "FAIL: $cmd (rc=$rc)"; exit 1; }`
- 并发：记录 `$rc|$cmd $args` 到结果文件；`wait` 后遍历，任一 `rc!=0` → 打印失败项 + `exit 1`（**每组独立结果文件**，避免跨组累积干扰）。

#### 2.3 日志过滤（拍板①：按推荐；实测 160,498 行）

当前 `grep -Ei "warn|error"` 命中 **23,789 行（14.8%）**，但绝大多数是**重复编译器警告**（`gdkalias.h` 宏展开、`Deprecated pre-processor`、`token "NONE" deprecated` 等），且**漏掉** `fatal:`/`can't stat`/`No such file`/`ninja: open build.ninja` 等真错误。

| 类别 | 行数 | 建议 |
|---|---|---|
| 重复编译器警告 | ~23,500 | ❌ 控制台丢弃（纯噪音，只留日志文件） |
| 真错误（`ERROR:`/`fatal error:`/`fatal:`/`error:`/`Error N`/`undefined reference`/`No such file`/`can't stat`/`MISSING`/`FAILED`） | ~206 | ✅ 回显 |
| 里程碑（`>>> `、`start building`、`err N, pass/fail`、`本操作`、`OK: X MiB`、`TARGETPATH=`） | ~231 | ✅ 回显（进度可见性） |

**改成正向白名单**：
```sh
grep -E "ERROR:|fatal error:|fatal:|error:|\bError\b|undefined reference|No such file|can't stat|MISSING|FAILED|>>> |start building|err [0-9]+, (pass|fail)|本操作|OK: [0-9]+ MiB|TARGETPATH=" \
 | grep -vE "perl-error|fail_on_|--add-missing|-Werror|pixbuf-fail|\[[0-9]+/[0-9]+\] (Compiling|Generating|Linking)"
```
→ 回显 23,789 → **~430 行（降 98%）**，且**多抓到**被漏的真错误。警告只留日志文件、控制台丢弃（拍板①）。

##### 2.3.1 过滤后错误明细（`job-logs03-gtk224-2.txt`，3 容器并发：`#18` amd64、`#21` arm/v7、`#24` arm64，跑 `b_deps` 静态库）

三容器结论一致，**静态库失败清单**：

| 静态库 | 结果 | 直接错误（日志原文） | 根本原因 |
|---|---|---|---|
| **atk** | ❌ 3/3 | `fatal: could not read Username for 'https://github.com'` → `cd: /tmp/atk: No such file` → `cp: can't stat libatk-1.0.a` | **git clone 需 GitHub 凭据**（u-gtk/build.sh:11），`/tmp/atk` 不存在 |
| **libcroco** | ❌ 3/3 | `./autogen.sh: line 25: gtkdocize: not found` → `./configure: No such file` | **缺 gtk-doc（gtkdocize）**（w-tint2/build.sh:26），configure 未生成 → `libcroco-0.6.pc` 未装 |
| **librsvg** | ❌ 3/3 | `configure: error: Package 'libcroco-0.6' not found` | **libcroco 先失败** → `libcroco-0.6.pc` 缺失 → librsvg configure 失败 |
| **gdk-pixbuf** | ❌ 3/3 | `io-svg.c:28:10: fatal error: 'rsvg.h' file not found` → `ninja: subcommand failed` → `cp: can't stat libgdk_pixbuf-2.0.a` | **librsvg 先失败** → `rsvg.h` 未装 → builtin SVG loader 失败 → `.a` 未生成 |
| **libxrandr** | ⚠️ 仅 #18 | `#18 configure: error: C compiler cannot create executables`（7s 即败） | **#18 amd64 最先跑、toolchain 未就绪竞态**；#21/#24 均成功装 `libXrandr.a`。非稳定失败 |

##### 2.3.2 根因链条（修正版，2026-11-11）

```
libcroco: gtkdocize 缺失 (w-tint2/build.sh:26 autogen.sh)
   → libcroco-0.6.pc 未安装
   → librsvg configure 失败 (Package 'libcroco-0.6' not found)
   → rsvg.h 未安装
   → gdk-pixbuf io-svg.c 失败 (rsvg.h not found)
   → libgdk_pixbuf-2.0.a 未生成
       └→ gtk 回退用系统 apk gdk-pixbuf/atk

atk: git clone 需凭据 (u-gtk/build.sh:11)
   → /tmp/atk 不存在 → libatk-1.0.a 未生成
```

**两个独立根因**：① libcroco 缺 gtk-doc（`gtkdocize`）；② atk clone 需 GitHub 凭据。

##### 2.3.3 纠正上轮判断（2.5 需修正）

- **pango**：✅ 实际成功且已装 `.pc` 到 `/usr/lib/pkgconfig`（`pango.pc`/`pangocairo.pc`/`pangoft2.pc`…，日志 56097/56211 行）。**上轮 2.5「pango .pc 未安装」判断有误**——真正卡 librsvg 的是 libcroco。
- **gtk / gdk**：✅ 实际成功（`Merged pixmap engine into ./gtk/.libs/libgtk-x11-2.0.a`，`err 0, pass`），但用**系统 apk 库回退**（atk-dev 2.36.0 / gdk-pixbuf-dev 2.42.8），非自编译静态 `.a`。**上轮「gtk 失败（gdk.h:40 / gdkenumtypes.h）」亦误判**——该报错仅 #18 一次性竞态，稍后 `gdkenumtypes.lo` 已正常编译（日志 52614 行），最终 gtk 构建成功。
- **关键发现**：所有失败在**旧版 oneBuild** 下都打 `err 0, pass`（真实失败被吞，恒 pass）——正是 2.1 所述吞错 bug 的**日志实锤**；已由 `9ab5919` 修复。

##### 2.3.4 修复方向（按优先级）

1. **libcroco（openbox apkdeps 补 `gtk-doc`）**：缺 `gtkdocize` 的缺口在 **openbox apkdeps 未装 gtk-doc**（见 3.1①），补上即解；确认 `libcroco-0.6.pc` 装入 `/usr/lib/pkgconfig`（STATIC 模式 `rm -f .so` 不影响 .pc，但 configure 须先成功）。
2. **atk（u-gtk/build.sh:11 改镜像源）**：clone 需凭据/github 源不可达——改用可达镜像（如 `gitee.com/g-system/fk-atk` / `https://hub.njuu.cf`，与 libcroco/librsvg 一致），或 CI 注入 git 凭据/网络。
3. **librsvg**：libcroco 修好后自动解（依赖 `libcroco-0.6.pc`）。
4. **gdk-pixbuf**：librsvg 修好后自动解（依赖 `rsvg.h`）。
5. **libxrandr #18**：toolchain 竞态，建议 b_deps 前确保编译器就绪或重试，非脚本 bug。

##### 2.3.5 doExec 结果文件留痕 + 精准识别实施（commit `3c5da41`，2026-11-11）

**需求（user）**：`_exec_result.txt` 每次完整调用要留痕；过程不能清理；`doExec_check` 取值要精准识别当前组。

**原问题**：`b_deps` 每组前 `: > /tmp/doExec/_exec_result.txt` **截断** → 前组记录丢失，无法留痕；若不清空则 `doExec_check` 读全文件误判前组。

**方案**（结果文件只增不清 + 组边界标记）：

```sh
# doExec 仍 >> 追加（每行 "rc|cmd args"，留痕）
function doExec_mark(){ echo "# MARK $*" >> /tmp/doExec/_exec_result.txt; }
# doExec_check: 只读最后一个 # MARK 之后的记录 -> 精准圈定当前组
start=$(grep -n '^# MARK ' "$f" | tail -1 | cut -d: -f1); [ -z "$start" ] && start=0
# b_deps: : > 截断 -> doExec_mark "groupN: ..."
```

- 隔离测试通过：组1 检 `libxrandr` 失败 ✓；组2 全成功且**不误判**组1失败 ✓；组3 检 `gtk` 失败 ✓；文件留痕不清 ✓。`bash -n`/`sh -n` 通过。
- 仅 u-gtk 用此机制（openbox/w-xlunch 用 `bash ... &`+`wait`，无结果文件），改动局域化。

#### 2.4 原 logfile 日志是否还有必要（拍板②分析）

- `oneBuild` 的 `$logfile`（`oneBuild-$1.log`）：**仍必要**。逐步骤诊断日志 + 失败 `tail -200` 依据，供**所有**走 `oneBuild` 的构建脚本用；修复后可可靠触发。
- `doExec` 的 `/tmp/doExec/*.log`：**必要**。它包裹的是**不一定走 oneBuild** 的命令（openbox `pango`/`libxrandr`、xcompmgr `Xdamage`、w-tint2 `libcroco`/`librsvg`），这些没有 oneBuild 日志兜底。
- **冗余点**：`u-gtk/build.sh:333` `*) doExec oneBuild $1` 是**嵌套 doExec**，导致 atk/gdk-pixbuf/gtk 一步被记 **3 份**（doExec-外 + doExec-内 + oneBuild-logfile）。
- **建议**：`*)` 改直接 `oneBuild $1`（oneBuild 已自处理日志+退出码），**去掉嵌套 doExec**；保留 oneBuild-logfile（逐步骤）+ doExec-log（外层、非-oneBuild 命令），消除三份冗余。

#### 2.5 doExec 上移 common.sh 公共包装 + u-gtkmm 调入口应用（2026-11-11）

**背景**：doExec（含 doExec_mark/doExec_check）最初定义在 `u-gtk/build.sh` 内、仅 u-gtk 用；本次上移 common.sh 公共，并让 `u-gtkmm` 也应用（用户 2026-11-11 指令「把 u-gtk/build 的 doExec 移到 common，u-gtkmm 也应用上」）。

**改动（3 commit，每文件一个）**：

- `compile/src/common.sh`（`8c7666e`）：doExec/doExec_mark/doExec_check 从 u-gtk/build.sh 上移（oneBuild 之后）——公共执行包装：全量落日志 + 白名单实时回显 + 错误码记录（供并发 wait 后检查），供 u-gtk/u-gtkmm 等共用。
- `compile/src/u-gtk/build.sh`（`0d6dbdd`）：删本地 doExec 三函数定义（-49 行），改靠 `source /src/common.sh`（已 L3），**行为不变**（调用处 b_deps 并发组未动）。
- `compile/src/u-gtkmm/build.sh`（`13ac7d0` 初稿 → **`5d7c7da` 修正**）：应用 doExec。

**u-gtkmm 应用方式（fix：调入口，非函数内散落）**：

- **初稿（`13ac7d0`）错**在函数内部 7 处 `doExec make -j$(nproc); doExec make install` 散落包装——用户指正「gtkmm 的写法不是那样改调用的，要在整个方法块的调入口，像 u-gtk 那样」。
- **修正（`5d7c7da`）**：撤销内部 7 处散落（恢复 `make -j$(nproc); make install`），改 `case full)` 分支 `gtkmm` → **`doExec gtkmm`**（调入口包装整个 gtkmm() 方法块，类比 u-gtk 的 `*)` 分支 `oneBuild $1`）；`gtkmm()` 函数开头加 **`set -e`**。

**关键设计**：

- **调入口包装**：u-gtkmm 在 case `full)` 调入口 `doExec gtkmm`，与 u-gtk 在 case `*)` 调入口 `oneBuild $1` 同类——执行入口统一包装整个方法块（全量落日志+白名单回显+错误码），函数内部不再散落。
- **函数内 `set -e` 必要性**：doExec 子 shell `( set +e; $cmd $args; echo $? > $rcfile )` 关 set -e 保命令继续 + rcfile 捕获真实 rc；若函数内不重启用 set -e（或显式 exit），失败会被吞、最终 rc 误报 0。gtkmm() 开头 `set -e` 保失败即终止（与 u-gtk 构建函数内 `|| exit 1` 同理）。
- **作用域**：函数内 set -e 在 doExec 子 shell 内生效，子 shell 退出后不影响外层（doExec 函数体 set -e 状态不变）；函数正常调用（不经 doExec）时 set -e 本就开启，无副作用。

**验证**（builder-gtkmm-dbg，`/src` 挂载最新）：

- `bash -n` 三文件语法 OK；u-gtk/u-gtkmm `cache` 分支 rc=0（bash 跑，同 Dockerfile）。
- doExec 错误传播实测：函数内 `set -e; false` → `doExec` 返回 **1**（正确捕获失败）；`set -e; true` → 返回 **0**。
- 注：u-gtk/build.sh 在 `sh`（busybox ash）下会因 `function gdk-pixbuf()` 连字符函数名报 `bad function name`——**既有问题**（HEAD 同样报），与本次无关；Dockerfile 用 `bash` 跑不受影响。完整 gtkmm 栈构建太重未实跑（函数行为/source/case/语法均验）。

#### 2.6 doExec 分层目录（按脚本调入口）设计问答 + 拍板（2026-11-11）

**背景**：2.5 落地后，用户提出 doExec 日志/结果目录 `/tmp/doExec/` 需**额外挂一层目录**（`/tmp/doExec/<caller>/`，caller=脚本调入口名，如 u-gtk/u-gtkmm），并考虑 doExec 等方法块传参——先给设计思路待确认，拍板后开工。

##### 2.6.1 需求

- `/tmp/doExec/<caller>/` 分层，caller 取**脚本调入口**名（u-gtk、u-gtkmm…）。
- doExec 等方法块传参：u-gtk 调 openbox 脚本（`doExec /src/openbox/build.sh pango`），openbox 脚本内若有 doExec 调用，记录仍落 `/tmp/doExec/u-gtk/`（调用方）；openbox 自身经 Dockerfile 入口执行时，记录落 `/tmp/doExec/openbox/`。

##### 2.6.2 方案（设计思路，待确认）

- **目录结构**：`/tmp/doExec/<caller>/`（`_exec_result.txt` + `<cmd>.log` + `.rc.*`），每调用方独立；`doExec_mark`/`doExec_check` 读**同一 caller 目录**（并发组隔离保持）。
- **caller 确定：环境变量 `DOEXEC_CALLER`（继承不覆盖）**：common.sh 的 doExec 三函数统一 `local caller="${DOEXEC_CALLER:-default}"; elog=/tmp/doExec/$caller`；各 build.sh 入口统一 `export DOEXEC_CALLER="${DOEXEC_CALLER:-<脚本名>}"`——被 doExec 调用时**继承调用方不覆盖**，顶层入口（Dockerfile）设自身名。
- **场景**：Dockerfile 入口 u-gtk→`/tmp/doExec/u-gtk/`；u-gtk 调 openbox→子 shell 传 env，openbox 入口 `${VAR:-openbox}` 保持 u-gtk→`/tmp/doExec/u-gtk/`；openbox 自身入口→`/tmp/doExec/openbox/`。
- **传参**：**不改函数签名**（`doExec <cmd> [args...]` 不变），caller 从 `$DOEXEC_CALLER` 读——嵌套（u-gtk→openbox→…）自动继承，显式传参需层层透传易漏。
- **需改脚本**：`common.sh`（必）+ `u-gtk`/`u-gtkmm`（用 doExec）+ `openbox`/`w-tint2`/`xcompmgr`（被 doExec 调用、预防内部未来 doExec）。

##### 2.6.3 拍板 + 开工（2026-11-11）

- **① 环境变量方案**：✅ 用户拍板可以。
- **② 被调用脚本一并加入**：✅ 用户拍板 openbox/w-tint2/xcompmgr 也加入口设置（预防）。
- 开工顺序：common.sh（分层）→ u-gtk/u-gtkmm（入口）→ openbox/w-tint2/xcompmgr（入口）——每脚本一个 commit（AGENTS 规则）。

##### 2.6.4 实施（6 commit）+ 验证（2026-11-11）

**实施（每脚本一个 commit，AGENTS 规则）**：

- `42b1d31` common.sh：doExec 三函数按 caller 分层——`local caller="${DOEXEC_CALLER:-default}"; local elog=/tmp/doExec/$caller`；doExec_mark/check 同步用 `${DOEXEC_CALLER:-default}`。
- `bea48f7` u-gtk / `68ad8bd` u-gtkmm / `95198e1` openbox / `0e64f68` w-tint2 / `3337bef` xcompmgr：各入口 `export DOEXEC_CALLER="${DOEXEC_CALLER:-<名>}"`——被 doExec 调时**继承调用方不覆盖**，顶层入口（Dockerfile）设自身名。

**验证**（builder-gtkmm-dbg，`/src` 挂载最新）：

- `bash -n` 6 文件语法全 OK。
- **T1 分层**：`DOEXEC_CALLER=u-gtk doExec echo x1` → `/tmp/doExec/u-gtk/_exec_result.txt`（`0|echo x1`）✅
- **T2 继承**：`DOEXEC_CALLER=u-gtk doExec /tmp/sub.sh`（子脚本内 `source common.sh` + `export DOEXEC_CALLER="${DOEXEC_CALLER:-openbox}"` + `doExec echo inner`）→ 子脚本内 doExec 落 **`/tmp/doExec/u-gtk/echo_inner.log`**（继承调用方，非 openbox）✅——正是需求「u-gtk 调 openbox 时 openbox 内 doExec 落 u-gtk 目录」。
- **T3 默认**：未设 caller `doExec echo dflt` → `/tmp/doExec/default/` ✅。
- **目录结构**：`/tmp/doExec/<caller>/`（`_exec_result.txt` + `<cmd>.log` + `.rc.*`），每调用方独立、并发组隔离保持；旧平铺 `/tmp/doExec/*` 残留不再读写（/tmp 临时，可忽略）。

**结论**：分层按脚本调入口落地；环境变量继承不覆盖保证「谁发起归谁」；u-gtk b_deps 并发组多子脚本 doExec 记录同落 `/tmp/doExec/u-gtk/`（doExec_check 读同目录，组隔离不变）。

### 3、构建失败根因定位与源码源镜像切换（2026-11-11）

#### 3.1 两处根因定位修正（2026-11-11，结合 w-tint2/openbox 脚本）

**① libcroco 缺 `gtkdocize`——真正缺口在 openbox apkdeps，非 w-tint2：**

- 已确认：`cb728b8`（2026-09-26）把 libcroco/librsvg **新引入静态依赖图**并加 `STATIC=yes` 开关（`--disable-shared` 只出 `.a`），是"最近调整引入"。
- **`STATIC=yes` 与 gtkdocize 正交，不能免去失败**：STATIC 只影响 `./configure --enable-static --disable-shared`（决定 `.a`/`.so` 输出），失败点在**更早的 `./autogen.sh:25`**（`gtkdocize: not found`），configure 根本没生成。
- **结构一致性已满足**：所有纯静态消费方（w-xlunch:192-193 / openbox:398-400 / u-gtk:346,351）都传 `STATIC=yes`；仅 w-tint2 自用（325-326，非纯静态要 `.so`）不传，合理。
- **直接根因**：u-gtk `b_deps` 组1 用 `doExec /src/openbox/build.sh apkdeps`（u-gtk:351），而 **openbox 的 apkdeps 只装 `intltool`，缺 `gtk-doc`**（openbox:339，注释只提 intltoolize）→ 无 `gtkdocize`。u-gtk 自己的 apkdeps 有 `gtk-doc`（u-gtk:285,288）但只在组2后被调（u-gtk:359），救不了组1。
- **修复**：openbox `apkdeps` 补 `gtk-doc`（与已有 `intltool` 并列）。

> **注（实际落地，以代码为准）**：按 user 拍板，`gtk-doc` 最终补在 **u-gtk 自身 apkdeps 并置最前**（含 gtkdocize 备注，commit `45038e1`），**openbox apkdeps 未动**；与上文"openbox 补 gtk-doc"的分析方向不同，但补的依赖一致（`gtk-doc`）。

**② atk 克隆失败——github 源访问问题（非纯抖动）：**

- atk 用 `$GITHUB/GNOME/atk`（u-gtk:11），`$GITHUB` 默认 `https://github.com`（common.sh:20）。
- 同一时刻 librsvg/gdk-pixbuf 克隆源为 `gitee.com/g-system/fk-*`（**成功**），pango/Xdamage/libcroco 亦成功；**仅 atk（github.com）失败**，且三容器一致 `could not read Username ... No such device or address`（git 无交互 tty 下尝试认证，指向 github 匿名访问被拒/需凭据，非网络超时抖动）。
- **修复方向**：atk 改用可达镜像（如 `gitee.com/g-system/fk-atk` 或 `https://hub.njuu.cf`，与 libcroco/librsvg/openbox:417 一致），最稳。

#### 3.2 源码源 github→gitee 镜像切换（commit `1e56d04`，2026-11-11）

**背景**：CI 中 atk 克隆失败根因是 `GNOME/atk` 仓库在 github 已**归档消失**（2022 并入 at-spi2-core，API 返回 404，**非网络抖动**）；gdk-pixbuf/gtk 的 github clone 实际均成功（非稳定失败，推翻"GitHub 整体不可达"判断）。为摆脱 github 间歇不可达 + 仓库消失风险，改走 gitee 镜像。

**命名（user 确认）**：`g-system/fk-atk`、`fk-gdk-pixbuf`、`fk-gtk`、`fk-murrine`。

**镜像验证（gitee API，2026-11-11）**：

| 镜像 | 状态 | 默认分支 | 所需 tag/分支 | 结论 |
|---|---|---|---|---|
| fk-gdk-pixbuf | ✅ 存在 | master | tag `2.42.8`（445 tags，含 2.42.8） | 匹配 |
| fk-gtk | ✅ 存在 | **main（gtk4）** | tag `2.24.33`（2.24.0~2.24.33 全有） | 匹配，**必须按 tag 拉** |
| fk-murrine | ✅ 存在 | master | master | 匹配 |
| fk-atk | ✅ 就绪（2026-11-11） | distrotech-atk | tag `ATK_2_36_0`（commit `e087974`） | 匹配 |

**改动（`compile/src/u-gtk/build.sh`，4 处 clone 源）**：

```sh
atk:        git clone --depth=1 $branch https://gitee.com/g-system/fk-atk /tmp/atk        # ATK_2_36_0
gdk-pixbuf: git clone --depth=1 $branch https://gitee.com/g-system/fk-gdk-pixbuf /tmp/gdk-pixbuf  # 2.42.8
gtk:        git clone --depth=1 $branch https://gitee.com/g-system/fk-gtk "$GTK"          # 2.24.33（main 为 gtk4）
murrine:    MURRINE_GIT="${MURRINE_GIT:-https://gitee.com/g-system/fk-murrine}"          # master，env 仍可覆盖
```

- 原 `$GITHUB/GNOME/*` 拼接改为写死 gitee URL；murrine 原默认走 `ghfast.top` 代理，现直连 gitee（`MURRINE_GIT` 环境变量仍可覆盖）。
- `sh -n`/`bash -n` 通过；提交 `1e56d04` 已推送。
- **fk-atk 就绪确认**：2026-11-11 用户创建后 gitee API 返回 `default_branch=distrotech-atk`（归档 atk 完整镜像），tags 含 `ATK_2_36_0`（commit `e087974`）→ 四镜像全部可用，无需再改代码。

#### 3.3 libcroco/librsvg 静态构建依赖修复（commit `0efd7ad`，2026-11-11）

**背景**：3.1 修 gtkdocize 后 libcroco configure 通过，但 make install 仍失败；librsvg configure 缺 `libcroco-0.6.pc`（因 make install 失败未装）→ 级联失败。逐步在 alpine-builder 容器（`builder-gtk-dbg`）内验证。

**① libcroco：csslint-0.6 链接 libxml2.a 缺传递依赖**

- `make install` 失败：`csslint-0.6` 链接**静态 libxml2.a**，其依赖 zlib/lzma/bzip2/m 不自动传递 → `undefined reference to deflateEnd/gzopen/lzma_code…` → install 中断 → `libcroco-0.6.pc` 未装 → 后续 librsvg configure 缺它。
- **修复**（`w-tint2/build.sh` libcroco）：STATIC 时 `export LIBS="-lz -llzma -lbz2 -lm"`。

**② librsvg：静态可执行（rsvg-convert/rsvg-loader/GISCAN）需 libgdk_pixbuf-2.0.a**

- configure 需 `libcroco-0.6.pc`（①修后已装，PKG_CONFIG_PATH 前置）+ `gdk-pixbuf-2.0.pc`/`pangocairo`/`pangoft2`（u-gtk apkdeps 补 gdk-pixbuf-dev/pango-dev，commit `25d08c6`）。
- make 失败：`rsvg-convert`/`rsvg-loader`/GISCAN（Rsvg-2.0.gir）等可执行在 STATIC 下被 `-static` 强制静态链接，需 **libgdk_pixbuf-2.0.a**（Alpine 无 gdk-pixbuf-static 包）→ `cannot find -lgdk_pixbuf-2.0`。
- **注意**：librsvg 2.40.21 的 `--disable-tools` **不能**跳过 rsvg-convert（无条件构建，且反而令 rsvg-loader 走静态链接）。
- **修复**（`w-tint2/build.sh` librsvg）：`--enable-introspection=no`（跳 GISCAN）+ sed 清空顶层 `bin_PROGRAMS`（rsvg-convert 等）+ sed 剔除 SUBDIRS 中 `gdk-pixbuf-loader tests tools doc`（只留 `. build`）→ 仅构建/安装 librsvg-2.a 库本体。

**③ 依赖顺序确认**：gdk-pixbuf 的 svg loader（io-svg.c）需 `rsvg.h` → **librsvg 必须先于 gdk-pixbuf** 构建；librsvg 静态库本身需 gdk_pixbuf 头（apk 的 gdk-pixbuf-dev 提供），静态可执行需 gdk_pixbuf `.a`（②已跳过）。

**④ 验证（容器内 `STATIC=yes` 逐组件）**：libcroco-0.6.a ✅ / pango（`/usr/lib/libpango-1.0.a`，meson prefix=/usr）✅ / librsvg-2.a ✅ / libgdk_pixbuf-2.0.a ✅（已 cp `/usr/lib`）/ libatk-1.0.a ✅ —— 依赖链全通。

### 4、CI 三架构 gtk 构建错误分析（arm64/armv7 b_deps，2026-11-11 只分析未修）

#### 4.1 现象与产出核对（问题1 答复）

**背景**：CI `buildx` 三架构（amd64/arm64/armv7）跑 `/src/u-gtk/build.sh b_deps`，arm64/armv7 日志出现 3 类报错（`gdkenumtypes.h not found`、`theme_*/pixmap_theme_* undefined`、`inc_patch .sha No such file`），但脚本最终 `err 0, pass` + 产物 ls 齐全。

##### 4.1.1 a 库产出核对

- **是，`.a` 全部产出**：`/usr/lib/libgtk-x11-2.0.a、libgdk-x11-2.0.a、libgdk_pixbuf-2.0.a、libpango-1.0.a、libpangocairo-1.0.a、libpangoft2-1.0.a、libpangoxft-1.0.a、libatk-1.0.a、libXdamage.a、libXrandr.a` 齐全，`err 0, pass` + `DONE`。
- **但「产出」≠「完整可用」**：`.a` 是归档，链接阶段不解析符号（故 `.so` 的 `undefined theme_*` **不影响 `.a` 归档**）；但**编译期 `gdkenumtypes.h` fatal 可能让依赖它的 `.o` 未编出 → `.a` 缺 `.o` → 下游静态链时才炸**。需 `nm`/`ar t` 核实，不能只看 ls/err 0 pass。
- `theme_* / pixmap_theme_*`：**`.a` 里是有**（日志 `Merged murrine/pixmap into ./gtk/.libs/libgtk-x11-2.0.a`），`.so` 的 undefined 只因 merge 发生在 `.so` 链接**之后**。

##### 4.1.2 错误①：`inc_patch ... .patch.sha: No such file`（build.sh line 148，中）

- **根因**：`Fresh clone gtk (no usable cache)` → `/tmp/gtk/.u-gtk-state/` 目录不存在，`inc_patch` 读 `.sha` 时报 No such file（增量构建有 cache 则正常，故 CI 干净环境才现）。
- **解决**：`inc_patch` 读 `.sha` 前 `mkdir -p /tmp/gtk/.u-gtk-state` 或 `[ -f ]` 容错（视为首次 apply）。不致命（patch 仍 reset+apply），但污染日志 + 可能状态跟踪错乱。**小改，建议修**。

##### 4.1.3 错误②：`fatal error: 'gdk/gdkenumtypes.h' file not found`（**高，真正的编译错误**）

- **根因**：`gdkenumtypes.h` 是 gtk 构建时由 `glib-mkenums` 生成的枚举头。fresh clone 下**它没生成**（增量构建有 cache 生成过就不报）→ 最可能是**交叉工具链缺 `glib-mkenums`**（不在 PATH）或 autogen 未触发枚举生成；其次才是 CPPFLAGS 未含生成头目录。
- **解决方向**（按可能性）：
  1. 确认交叉容器 `glib-mkenums` 在 PATH（apk 装 `glib-dev`/`glib`，交叉 rootfs 需带）；fresh clone 后 `configure` 前显式生成：`make gdk/gdkenumtypes.h`；
  2. 若生成头在 build 目录而 CPPFLAGS 缺 `-I`，configure 时补 `CPPFLAGS` 加生成目录；
  3. **必查**：`nm libgtk-x11-2.0.a | grep -c gdkenumtypes`（或 `ar t`），确认 `.a` 里 gdk 枚举 `.o` 在——缺失则下游应用静态链会 undefined。
- **最该处理**：`.so` 失败可忽略，但 `.a` 缺 `.o` 不可忽略。

##### 4.1.4 错误③：`undefined reference to theme_* / pixmap_theme_*`（`.so` 链接，低-中）

- **根因**：gtk `.so` 链接发生在 murrine/pixmap theme engine 构建+merge **之前**，此时符号未并入 → `.so` undefined。`.a` 后续 merge 成功（含符号）。
- **解决**：a) 纯静态需求下**可忽略**（`.a` 有符号）；b) 若要 `.so` 也过：把 theme engine 构建+merge **提前**到 gtk 编译/链接前，或 `.so` 链接追加 theme `.o`；c) 若只是不想刷屏，build.sh 对 `.so` 链接失败 `|| true`（但别用 oneBuild 吞错当通过）。
- **建议**：忽略（目标只有 `.a`），用 `nm` 确认 `.a` 含 `theme_init/theme_create_rc_style/pixmap_theme_init` 等。

##### 4.1.5 信息性项（非错误）

- `A2 SKIP: ibus module objects NOT found (/tmp/ibus)`——预期跳过（交叉未建 ibus 模块）。
- `TARGETPATH=/usr/local/static_temp1`——b_deps 库构建装 `/usr/lib`，TARGETPATH 只影响 data/locale（theme 数据落 static_temp1）。按 AGENTS §3.2 应传正确 TARGETPATH，但**非本次回归**，可另行处理。
- `err 0, pass`——**别信**（AGENTS §3 教训）：`.so` 链接已失败仍报 pass，需人工用 `nm`/`xx-verify` 核实 `.a`。

##### 4.1.6 优先级与解决

1. **② 必查/必修**：`gdkenumtypes.h`（fresh clone 未生成）——确认 `.a` 完整，否则下游静态链炸；修 `glib-mkenums` 就位/显式生成。
2. **① 小修**：`inc_patch` `.sha` 目录容错（干净日志 + 状态跟踪）。
3. **③ 可忽略**：`.so` theme undefined（`.a` 已 merge 符号），纯静态目标不受影响。
4. **全局**：交叉构建 CI 下 `.a` 完整性靠 `nm`/`ar t` 核对，不能只看 `err 0, pass` + ls。

#### 4.2 本地实证与彻底修复思路（2026-11-11）

##### 4.2.1 本地实证（builder-gtkmm-dbg，2026-11-11 补充）

**背景**：gtk-dbg 容器**无** gtk 构建日志（b_deps 卡 librsvg，06:02 旧失败，`/tmp/gtk` 不存在、无 `oneBuild-gtk.log`）；改查 **gtkmm 容器**（`builder-gtkmm-dbg`）——该容器有完整 gtk 构建日志：`oneBuild-gtk.log`（34MB，07:28）+ `doExec/bash__src_u-gtk_build.sh_gtk.log`（748,834 行，07:28，**amd64**）。

**核对结果**（三类错误本地全有，内容与 CI **完全一致**）：

| 错误 | 本地行号 | 内容 |
|---|---|---|
| `gdkenumtypes.h not found` | L1026 | `../gdk/gdk.h:40:10: fatal error: 'gdk/gdkenumtypes.h' file not found` |
| `theme_* undefined` | L747403-595 | `undefined reference to \`theme_create_rc_style' / theme_init / theme_exit`（6 处）|
| `pixmap_theme_* undefined` | 同段 | 同上（6 处）|
| `patch.sha No such file` | L35-55 | `/tmp/gtk/.u-gtk-state/*.patch.sha: No such file or directory`（4 patch 同名）|

**关键结论**：
- **三类错误不是交叉架构特有**——本地 amd64（`x86_64-alpine-linux-musl-ld`）同样复现、同内容；4.1.3 推测「交叉工具链缺 glib-mkenums」**不成立**。
- **三类错误不阻碍 `.a` 产出**——该次 gtk 构建虽报错，但 `Merged murrine/pixmap into libgtk-x11-2.0.a`，且后续 **gtkmm（07:51，11MB 日志）+ pavucontrol（10:39，446KB）均静态构建成功**（依赖 libgtk-x11-2.0.a）→ 证明 `.a` **完整可用**；`gdkenumtypes.h` fatal 是**可恢复**（make 重试生成头后继续），非缺 `.o`。
- 与 CI `err 0, pass` + `.a` 齐全一致——**产物正常，报错属构建脚本的噪音/顺序问题**，非产物缺陷。

> **订正（2026-11-11）**：4.1.3 原判断「`gdkenumtypes.h` 未生成→交叉缺 glib-mkenums、严重度高必查、可能缺 `.o`」经本地 amd64 实证**不成立**——三类错误本地全有且同内容（非交叉特有）；gdkenumtypes.h fatal 可恢复，`.a` 完整可用（下游 gtkmm/pavucontrol 静态链成功），严重度由「高必查」下调为「构建脚本顺序/噪音问题，不阻碍产物」。4.1.4（`.so` theme undefined 可忽略）、4.1.2（`.sha` 目录小修）维持。

##### 4.2.2 三类错误彻底修复思路（2026-11-11）

**根因已全部定位**（结合 build.sh 代码 + 本地实证），修复都集中在 `compile/src/u-gtk/build.sh`：

**① `patch.sha No such file`（L148 写入失败）——顺序 bug**

- **根因**：`mkdir -p "$STATEDIR"`（L160）在 fresh clone 分支的 **`rm -rf "$GTK"; git clone`（L172）之前**执行——fresh 时 `rm -rf` 把刚建的 `.u-gtk-state/` 删掉，之后 `inc_patch` 写 `.sha`（L148）报目录不存在。
- **修法**：把 `mkdir -p "$STATEDIR"` **移到 clone 块之后**（L174 后）；更稳是在 `inc_patch` 写 `.sha` 前加 `mkdir -p "$STATEDIR"`（两处都加，增量/克隆两路径都覆盖）。
- **效果**：fresh clone 下 `.sha` 正常写入，patch 状态跟踪正确，日志无报错。

**② `gdkenumtypes.h not found`（L1026 fatal）——并行竞争**

- **根因**：`make -C gdk &` + `make -C gtk &`（L228-229）**并行且无依赖协调**——gtk 编译先于 gdk 生成 `gdkenumtypes.h` → fatal。可恢复（make 重试后 `.a` 完整），但报错刷屏且并行时序不可靠。
- **修法**：**串行化**——先 `make -C gdk`（等 gdkenumtypes.h 生成完）再 `make -C gtk`；或先 `make -C gdk gdkenumtypes.h`（只生成头，快）再并行剩余。
- **推荐**：串行（简单可靠，消除竞争）；代价略慢，但 gtk 本依赖 gdk 生成头，并行本就不可靠。

**③ `theme_* / pixmap_theme_* undefined`（`.so` 链接，L747403）——configure 未禁 shared**

- **根因**：`CONFIG_ARGS`（L210）只有 `--enable-static ...`，**没有 `--disable-shared`**（L206-207 是注释死代码）→ gtk `make` 链接 `libgtk-x11-2.0.so`，而 murrine/pixmap 在 **L234+ 才构建+merge**（L247/251 `ar r`）——`.so` 链接时 theme 符号未并入 → undefined。
- **修法**：`CONFIG_ARGS` 加 **`--disable-shared`**（本项目只要 `.a`，`.so` 不需要）→ make 不再链接 `.so`，theme undefined 彻底消失；`.a` 产出不受影响（`--enable-static` 保持）。
- **注意**：改 `CONFIG_ARGS` 使 configure 签名 SIG（L213）变化 → 触发一次重新 `autogen+configure`（一次性代价 ~5min）。

**修复后预期**：三类错误全部不再出现（fresh clone + 增量构建都干净），`.a` 产物不变（murrine/pixmap 仍 merge、printbackends 仍内链）。

**执行顺序（待拍板）**：① 改 build.sh 三处；② builder 容器实跑验证（AGENTS §3.3，fresh + 增量路径各一，确认日志无三类错误、`.a` 产出 + `nm` 含 theme 符号）；③ 文档记录（本小节为修复思路，落地结果另记）+ 单独 commit/推送。

##### 4.2.3 三类错误修复落地与验证（2026-11-11 完成）

| 错误 | 根因 | 修法 |
|---|---|---|
| ① `patch.sha No such file` | `mkdir .u-gtk-state` 在 fresh `rm -rf` 前被删 | inc_patch 写前 + clone 后各 `mkdir -p` |
| ② `gdkenumtypes.h not found` | gdk/gtk 并行无依赖，gtk 先于生成头编译 | **串行**（gdk 完再 gtk） |
| ③ `theme_* undefined` | 默认建 `.so`（未禁 shared）+ make 建工具在 merge 前链 `.a` | `--disable-shared` + make **只建库目标** `lib*.la`（不建工具） |

**改动**（`compile/src/u-gtk/build.sh`，4 处，11+4 行）：
- **① `patch.sha`**：`inc_patch` 写 `.sha` 前 + `gtk()` clone 块后各加 `mkdir -p "$STATEDIR"`——fresh clone 的 `rm -rf "$GTK"` 会删 `.u-gtk-state`，写入/克隆后重建（增量幂等）。
- **② `gdkenumtypes.h`**：`make -C gdk &` + `make -C gtk &` + `wait`（并行）→ **串行** `make -C gdk` 完再 `make -C gtk`——gtk 依赖 gdk 生成头，串行消除竞争。
- **③ `theme_*` undefined**：`CONFIG_ARGS` 加 **`--disable-shared`**（不再链 `.so`）+ make 目标改 **`libgdk-x11-2.0.la`/`libgtk-x11-2.0.la`**（只建库，跳过工具 `gtk-query-immodules-2.0`/g-ir-scanner 临时可执行——它们静态链 `.a` 的 `gtkthemes.o` 引用 theme_*（murrine/pixmap 未 merge）报 undefined；项目只要 `.a`，工具无需构建）。

**验证**（builder-gtkmm-dbg，amd64，增量缓存加速）：
- 完整构建 **229s**：`gdkenumtypes.h not found`=0、`patch.sha`=0、`Merged murrine/pixmap`=1——① ② 生效（`.u-gtk-state` 缺失路径验证 ① 写入兜底）。
- 库目标强制重链（删源码 `.la`+`.libs/.a`）**3s**：`undefined reference`=0、`gtk-query-immodules`=0（工具未建）、`merged murrine/pixmap`=1——③ 生效。
- 产物：`/usr/lib/libgtk-x11-2.0.a`（9.8M）、`libgdk-x11-2.0.a`（1.2M）；`nm` theme 符号=4（`theme_init/theme_exit/theme_create_rc_style/pixmap_theme_init` 均在，merge 生效）；`file`=current ar archive。
- **三类错误全部不再出现** ✅（① 缺失/存在两路径、② 串行、③ 无工具链接均验证）。

**注意**：`--disable-shared` 使 configure 签名 SIG 变化 → 下次 fresh 构建会触发一次 `autogen+configure`（一次性 ~5min）；库目标不建工具（`gtk-query-immodules-2.0` 等），项目只要 `.a` 无碍（工具本非可靠产物——默认目标下也报 undefined）。

### 5、AR 魔改静态库方式盘点（2026-11-11，u-gtk 及全构建脚本）

#### 5.1 u-gtk 内 `ar` 魔改分布 + 其他脚本盘点

**u-gtk 内（compile/src/u-gtk/build.sh）**

| 行 | 操作 | 内容 | 能否 patch 化 |
|---|---|---|---|
| L129-132 | `ar x libibus-1.0.a` + `ar r ... libibus_1_0_la-*.o` | ibus im 模块并入 `libgtk-x11-2.0.a` | 部分（`gtkimmodule.c` 已 patch + `-DINCLUDE_IM_ibus` 重编，但 libibus 独立项目对象合并仍需 `ar r`） |
| L260 | `ar r ./gtk/.libs/libgtk-x11-2.0.a /tmp/murrine/*.o` | murrine theme engine 并入 libgtk | 难——murrine 是独立项目（fk-murrine），源码不在 gtk 树，patch gtk 无法包含 |
| L264 | `ar r ./gtk/.libs/libgtk-x11-2.0.a modules/engines/pixbuf/*.o` | pixbuf theme engine 并入 libgtk | 可——`modules/engines/pixbuf` 在 gtk 树内，可像 printbackends 那样 patch `Makefile.am` 让 make 自然编进 |
| L267-271 | （无 ar） | printbackends | 已 patch 化（`gtk2-2.24.33-printbackends-static.patch`：Makefile.am 加 2 个 `.c` → make 自然编进；注释明确"替代旧 objcopy --redefine-sym + 手动 ar r（不正规，2026-11-05 复盘）"） |

**其他构建脚本**

| 脚本 | 行 | 说明 |
|---|---|---|
| v-ibus | L214 `ar rcs libIMdkit.a *.o` | IMdkit 库正常打包（非魔改系统库） |
| v-ibus | L319 `ar rcs libboost_signals.a` | boost_signals stub 伪造库（满足 ibus 静态链，必要 stub） |
| w-xlunch | L131-135 `ar r /tmp/builtin/libImlib2.a` | imlib2 魔改，但 L132 注释已改进：不再 `ar r` 直改系统 `/usr/local/lib/libImlib2.a`，改 `cp` 到 `/tmp/builtin` 隔离（不隐式影响其他 imlib2 链接者） |

**为什么不用 patch（规律）**

- 源码在 gtk 树内 → 可 patch（printbackends 已示范；pixbuf 已于 2026-11-11 转 patch，commit `7d733fc`）。
- 独立项目（murrine、libibus）→ 只能构建后 `ar r` merge，patch gtk 无法包含外部项目对象。

### 6、CI fresh 构建 gdk/x11 子库缺失根因分析与验证（2026-11-12，已分析+已验证+修复已落地，本地全量复验见下）

**现象（CI `Dockerfile.builder.gtk224` fresh b_deps，2026-11-12 03:13）**

```
>>> gdk make rc=2 (partial, .a checked below)
../gtk/gtktypeutils.h:36:10: fatal error: 'gtk/gtktypebuiltins.h' file not found
libtool: error: cannot find the library '../gdk/libgdk-x11-2.0.la' or unhandled argument '../gdk/libgdk-x11-2.0.la'
>>> gtk make rc=2 (partial, .a checked below)
>>> libgtk-x11-2.0.a MISSING
```

**根因（faithful fresh 复现，全量日志定位）**

```
make: *** No rule to make target 'x11/libgdk-x11.la', needed by 'libgdk-x11-2.0.la'.  Stop.
```

- `libgdk-x11-2.0.la` 的 `DEPENDENCIES`/`LIBADD` 引用 `x11/libgdk-x11.la`（X11 后端子库），但 **gdk/Makefile 无其构建规则**——它只由 SUBDIRS 递归（`make all` 的 `all-recursive`；gdk `SUBDIRS = $(gdktarget) . tests`，gdktarget=x11）构建。
- 改为只建 `.la` 目标后，`make -C gdk libgdk-x11-2.0.la` 不触发 SUBDIRS 递归 → fresh 树（无 x11/libgdk-x11.la）→ 目标缺失且无规则 → rc=2。
- **CI 白名单吞错**：doExec grep 白名单匹配 `No such file` 但**不匹配 `No rule`**（`Error 2` 也不匹配）→ gdk 真实报错被静默，只剩 `gdk make rc=2`。
- gdk 失败 → 缺 `../gdk/libgdk-x11-2.0.la` → gtk link `libtool: error: cannot find the library ...` → `libgtk-x11-2.0.a MISSING`。
- CI 的 `gtktypeutils.h:36 gtktypebuiltins.h not found` 为次要/高并行偶发：复现中 gtk BUILT_SOURCES 正常生成头、gtktypeutils.lo 正常编过，未复现该行。

**为什么以前不炸**

- 旧代码 `make -j$(nproc)`（全量 make）→ `all` → `all-recursive` 会先建 x11 子目录；增量树里 x11/.la 早已存在。
- 为避开工具（gtk-query-immodules 等）链接未 merge `theme_*` 的 undefined，2026-11-11 改为串行只建 `.la` 目标后，fresh 首次暴露 SUBDIRS 缺口。
- 与 gdkenumtypes.h（`292e74b`）、BUILT_SOURCES（`121a4de`）同属该改造的三处遗漏：前两处补的是「生成头不随 .la 目标构建」，本次是「子目录子库不随 .la 目标构建」。

**验证（真实 fresh 复现）**

- 环境：host 拉 fk-gtk 2.24.33（6863194）→ 拷贝进 `builder-gtkmm-dbg` 容器（容器无外网无法 clone）；`touch config.status` 让 gtk() 走复用分支但缺 SIG → 实际跑 fresh autogen + configure + inc_patch + 构建；全量日志 `/tmp/fresh2-host.log`（716K 行）。
- 复现同款失败：`No rule ... x11/libgdk-x11.la` → gdk rc=2 → gtk link `cannot find ../gdk/libgdk-x11-2.0.la` → `.a MISSING`。
- 补建 x11 后全通：`make -C gdk/x11 libgdk-x11.la` → `make -C gdk libgdk-x11-2.0.la` → `make -C gtk libgtk-x11-2.0.la` 全部成功：
  - `gdk/.libs/libgdk-x11-2.0.a` 1.26M、`gdk/x11/.libs/libgdk-x11.a` 537K、`gtk/.libs/libgtk-x11-2.0.a` 9.4M。
  - `nm` 确认：`pixmap_theme`×3（pixbuf engine 内置）、`_gtk_print_backend`×7（printbackends）、xim 符号在位，fatal=0。

**修复方案（已落地，2026-11-12）**

```sh
make -j$(nproc) -C gdk/x11 libgdk-x11.la || log "gdk x11 rc=$? (continue)"
```

已插入 `compile/src/u-gtk/build.sh`（gdk BUILT_SOURCES 之后、`make -C gdk libgdk-x11-2.0.la` 之前，附注释说明为何 .la 目标不触发 SUBDIRS 递归需显式补建）。

**本地全量复验（2026-11-12，builder-gtkmm-dbg 内 fresh 树重跑 gtk() 全流程，210s，`err 0, pass`）**：

- 复现用树先 `git reset --hard` + `git clean -fdx`（gdk/x11/.libs 空 = fresh）→ 重跑 `/src/u-gtk/build.sh gtk`。
- 结果：x11 子库由新增行从零构建 → gdk 1.26M → gtk 9.77M，全部成功，`/usr/lib/libgdk-x11-2.0.a` + `libgtk-x11-2.0.a` 已装。
- 符号确认：`pixmap_theme_create_rc_style/exit/init`×3（pixbuf engine 内置）、`_gtk_print_backend_{file,lpr}_*`（printbackends）、`_gtk_immodule_xim_{create,exit,init,list}`（xim）在位。
- doExec 全量日志无 `No rule to make target` / `cannot find the library` / `MISSING`（此前这些被白名单吞掉，本次白名单已修 + 修复使 x11 正常构建）。

**doExec 白名单（已落地，2026-11-12）**：`compile/src/common.sh` 白名单 grep 原为 `Error[0-9]`（匹配 `Error2` 但**不匹配 `Error 2`**，带空格）且无 `No rule` → 本次 gdk 的 `No rule to make target` 与 `make: *** ... Error 2` 全被静默过滤。已修为 `Error ?[0-9]`（同时匹配带/不带空格）+ 补 `No rule`，避免此类隐藏失败再次吞错。

### 7、oneBuild 废弃/合并 doExec 分析与调整方案（2026-11-12，分析 + 方案A 已落地 + 验证）

#### 7.1 oneBuild 包装内容 + 全局调整方案 + 影响项/风险点（用户 2026-11-12 只回复分析）

**oneBuild 包装干啥**（`common.sh` L53-80）：`oneBuild <方法名>` 是**方法块级**包装（`case` 分支里 `oneBuild $1`，$1=方法名如 imlib2/xlunch）：

- **落日志**：`$LOGS/oneBuild-$1.log`（`$TARGETPATH/../.logs`），`CONSOLE_LOG=yes`→`|tee` 实时、`no`→纯重定向。
- **精确错误码**（2026-11-11 修复）：`( set +e; $1; echo $? > rcfile )` 临时文件捕获方法真实退出码，修掉原管道取 tee(0)/find(0) 恒报 `err 0, pass` 吞错。
- **产物清单**：`find $TARGETPATH -type f | sort` 打印（验证产出物）。
- **结果判定**：`rc!=0→err N, fail + tail -200`；`0→err 0, pass`。
- **耗时**：`print_time_cost $1 $begin_time`；`return $rc`→调用方 `set -e` 捕获。

**与 doExec 本质差异**：oneBuild=**方法块粒度**（包多条命令+产物清单+耗时）；doExec=**单命令粒度**（包 make/configure/install 一条+白名单回显+分层日志 `/tmp/doExec/<caller>/`+`_exec_result.txt` 错误码记录+mark/check 并发组）。**doExec 没有产物清单和耗时**；oneBuild 没有白名单/分层/并发组。

**全局脚本现状**：oneBuild 调用 **33 处/32 脚本**（x-rofi 2 处，其余各 1）；已用 doExec 7 脚本（u-gtk/u-gtkmm/openbox/w-tint2/v-sysmonitor/v-pavucontrol/w-xlunch，已验证）；仍 oneBuild 26 脚本（fluxbox/suckless/u-misc/v-lxde/v-engrampa/v-geany/v-gpicview/v-ibus/v-pasystray/v-pcmanfm/v-xfce4/w-feh/w-hsetroot/w-scrot/x-dbus/x-dropbear/x-dunst/xperp/x-pulseaudio/x-rofi/x-tigervnc/x-x11vnc/x-xbindkeys/x-xrandr/x-xrdp/xcompmgr）。

**调整方案**：
- **方案A（推荐，最小风险）**：oneBuild 内部**改为调用 doExec**——签名不动，函数体=`doExec $1`+`find $TARGETPATH` 产物清单+`print_time_cost`。33 处调用点**零改动**，语义不变，拿到 doExec 白名单/分层/精确 rc。后续再逐步下沉纯 doExec。
- **方案B（彻底）**：废弃 oneBuild，26 脚本逐个改 `doExec <方法>` 调入口包装+方法内 `set -e`。代价：逐个审方法块内部命令可否 `set -e`、改动面大、逐个实跑验证。

**影响项/风险点**：
1. **失败语义变化（最大）**：oneBuild 内部 `set +e`（失败继续跑完再报错）；doExec+`set -e`（失败即停）。顺序构建 doExec 更安全，但方法块内"可失败不致命"步骤（可选组件/`|| true` 兜底）会被 `set -e` 误杀——**必须逐个方法块审**。
2. **产物清单丢失**：doExec 不 `find $TARGETPATH`；方案B 需调用方补。
3. **耗时丢失**：doExec 无 `print_time_cost`；方案B 需补。
4. **日志路径/内容变化**：`$LOGS/oneBuild-$1.log`→`/tmp/doExec/<caller>/<cmd>.log`；CI job 按旧路径采集需核对；doExec 白名单只回显高信号行（全量仍落文件）。
5. **函数执行**：doExec `[ -f "$cmd" ] && cmd="bash $cmd"`——方法名（shell 函数）走子 shell 执行（函数定义继承）；需确认 33 处 oneBuild 参数全是函数名非文件路径。
6. **CONSOLE_LOG 行为**：doExec 无此开关，始终 `tee+grep` 实时；CI（CONSOLE_LOG=no）用 doExec 多回显白名单行（量可控）。
7. **并发**：doExec 有 mark/check 并发组，oneBuild 无；单方法块无增益无损失，多方法并发是增益。
8. **回归范围**：方案B 改 26 脚本，逐个容器实跑+xx-verify（AGENTS §3.3 强制），一次全换风险大。

**结论**：推荐**方案A**（oneBuild 内部复用 doExec，签名零改动），先拿白名单/分层/精确 rc 收益，避免 26 脚本一次性迁移的失败语义/产物清单/耗时三处回归；方案B 作为后续逐步下沉。

#### 7.2 方案A 落地与验证（2026-11-12）

**落地（commit `cd227e1`，`compile/src/common.sh`）**：

- `doExec` 新增 `export DOEXEC_LOG=$lf`（实际日志路径，供 oneBuild 失败 tail 到本 doExec 日志）。
- `oneBuild` 内部改调 `doExec "$1"`——拿精确 rc + 白名单实时回显 + 分层日志 `/tmp/doExec/<caller>/`；**保留**产物清单 `find TARGETPATH`、err/pass 判定、耗时。33 处调用点零改动。

**验证（builder-awe 容器冒烟，`source /src/common.sh`）**：

| 路径 | 结果 |
|---|---|
| 成功 `oneBuild true` | `err 0, pass` rc=0；`DOEXEC_LOG=/tmp/doExec/smoke/true_.log`；分层日志 + `_exec_result.txt`（`0|true`）生成 |
| 失败 `oneBuild false` | `err 1, fail` + 耗时打印；`RET=1` 正确传播 |
| set -e 语义 | doExec 返回非0 → 调用方 set -e 终止（**与原 oneBuild 一致**，非行为变更） |

**关键确认**：方案A 下 doExec 内部仍是 `set +e`（方法块失败继续跑完），**失败语义与旧 oneBuild 完全一致**——原风险点 1（失败语义变化）在方案A 不触发。

**后续**：彻底废弃 oneBuild（方案B，26 脚本逐个下沉纯 doExec + 逐个实跑）可作为后续步骤，当前方案A 已让全部 33 处拿到 doExec 的白名单/分层/精确 rc 收益。

### 8、doExec 日志目录调整：`/tmp/doExec` 并入 `.logs/`（2026-11-13，由五章镜像核查引出）

#### 8.1、镜像内无四个失败组件日志（doExec 日志在 `/tmp`，未导出）

**先看前一条能否满足：不能**。四个失败组件（xfce4 / gsm / engrampa / gpicview）的具体失败原因，**镜像现存日志里找不到**：

- **`/tmp/doExec/` 未导出**：`doExec` 全量日志落在 `/tmp/doExec/<caller>/`（`common.sh` 旧 `:86`，已改 `:89`），oneBuild 失败 tail 也从那读（`:67`）——都在 `/tmp`，构建后**不进镜像层**，镜像 `/tmp` 实测为空。
- **镜像里唯一日志目录 `/rootfs/usr/local/static/.logs/`（37 个 .log）**，但四个失败组件**一个都没有**（xfce4 / gsm / engrampa / gpicview 全无）。有日志的全是「=no 却有产物」或「=yes 正常」的组件（pulseaudio/pasystray/pavucontrol/lxtask/pcmanfm/geany + dropbear/fluxbox/suckless/tiger/xrdp 等）。
- **对照五章 1.2 的根因**：`xfce4`/`gpicview` → b_deps 没跑、stage 被门控跳过（未构建，无日志）；`engrampa` → 构建函数跑了（建了 bin）未出二进制（写日志前中断）；`gsm` → 依赖库 gtop/wnck 建了、主程序没出（无 oneBuild-gsm 日志）。

**结论**：现存日志不足以定位四个失败原因。要拿到，需把 `/tmp/doExec/` 路径并入 oneBuild 的日志目录（`.logs/`），下次重建导出。

##### 8.1.1、脚本调整方案（把 `/tmp/doExec` 并入 `.logs/`，已落地）

目标：`doExec` 全量日志从 `/tmp/doExec/<caller>/`（构建后被清、不进镜像）移到会进镜像层的 `.logs/`（=`$TARGETPATH/../.logs`）。

改动点（全部在 `compile/src/common.sh`）：

1. **`doExec()` 日志目录**（改后 `:89`）：`elog=/tmp/doExec/$caller` → `$LOGS/doExec/$caller`；函数内兜底 `: ${TARGETPATH:=/tmp}`、`LOGS=${LOGS:-$TARGETPATH/../.logs}`、`mkdir -p $LOGS`（`:87-88`）。
2. **`rcfile`**（改后 `:93` `mktemp $elog/...`）：跟随 `$elog`，自动改。
3. **`doExec_mark()`**（改后 `:109`）/ **`doExec_check()`**（改后 `:117`）：`/tmp/doExec/...` → `$LOGS/doExec/...`。
4. **`oneBuild()`**（`:58`/`:67`）：`logfile` 已用 `LOGS`，失败 `tail` 读 `$DOEXEC_LOG`（指向新位置），无需改。

影响面：`u-gtk`/`u-gtkmm`/`v-sysmonitor` 的 `doExec`/`doExec_check` 调用点**不用改**（路径封装在函数内）。`_exec_result.txt`「只增不清 -> 留痕」保留，且跨构建留存。注意确认无 `rm -rf /tmp/doExec` 清理逻辑、doExec 上下文都有 `TARGETPATH`（否则兜底回 `/tmp` 仍丢）。

可选：`oneBuild` 的 `logfile`（`.logs/oneBuild-<name>.log`）当前并未被 `doExec` 写入（镜像里的是旧版产物）；若想让其更新，可在 doExec 管道加 `tee -a "$logfile"`（非必需）。

**落地**：`compile/src/common.sh` 已按上述改（commit `667c6f6`），`bash -n` 通过；`doExec`/`doExec_mark`/`doExec_check` 路径全部改到 `$LOGS/doExec`，各函数内加 `: ${TARGETPATH:=/tmp}`、`LOGS=${LOGS:-$TARGETPATH/../.logs}` 兜底；相关注释同步。调用点未改（路径封装在函数内）。

### 9、11.4 后新增 build.sh 的 b_deps/full 调用 doExec 适配（2026-11-13 实施+验证，已推送）

#### 9.1、实施与验证总结

**范围**：`git log --diff-filter=A --since=2026-11-04` 筛出的 **14 个**新增 build.sh，其 `b_deps`/`full` 内的调用（子函数调用 + 跨组件 `bash/sh /src/<other>`）全部加 doExec 包装；`v-sysmonitor`/`u-gtkmm` 早已适配，不动。

**改动模式（每文件）**：
1. 入口加 `export DOEXEC_CALLER="${DOEXEC_CALLER:-<comp>}"`（被调继承调用方、顶层入口设自身名，doExec 分层日志落 `$LOGS/doExec/<caller>/`）。
2. `b_deps`/`full` 内每个调用 → `doExec X || exit 1`（跨组件调用也包，失败即停链、不再被 `set +e` 吞掉继续跑）。

**14 文件明细**：

| 文件 | 改动 |
|---|---|
| v-ibus | full 七方法块（deps/librime/ibus/panel/x11/ibus-rime/setup）doExec+`\|\| exit 1` |
| x-rofi | b_deps 全链（w-tint2 xcbutil 跨调用 + build_dep×7）doExec+`\|\| exit 1`（保留原 log+exit 1） |
| x-dunst | b_deps `libxscrnsaver` doExec+`\|\| exit 1` |
| v-gpicview | full `gpicview` doExec+`\|\| exit 1` |
| v-pasystray | full `pasystray` doExec+`\|\| exit 1` |
| v-xfce4 | b_deps 全链（ensure_gtk_libs/dbus×2 跨调用/xfce_lib×5/libexif）doExec+`\|\| exit 1` |
| x-dbus | full `dbus` / full-glib `dbus_glib` doExec+`\|\| exit 1` |
| w-scrot | b_deps 跨调用（w-xlunch imlib2）doExec+`\|\| exit 1` |
| w-xlunch | b_deps 跨调用（tint2 libcroco/librsvg）doExec `env STATIC=yes ...`+`\|\| exit 1`；b_deps 调入口 doExec b_deps+`\|\| exit 1`；full imlib2/xlunch 补 `\|\| exit 1` |
| v-pavucontrol | b_deps 跨调用（x-pulseaudio b_deps/full）doExec+`\|\| exit 1`；full pavucontrol 补 `\|\| exit 1` |
| w-hsetroot | 仅入口 DOEXEC_CALLER（full/b_deps 无调用） |
| x-xbindkeys | 仅入口 DOEXEC_CALLER |
| x-xrandr | 仅入口 DOEXEC_CALLER |
| v-engrampa | 仅入口 DOEXEC_CALLER |

**关键坑（2026-11-13 实测，勿再踩）**：
- **dash 函数前缀 env 不传到子进程**：`TARGETPATH=... doExec sh ...` 不生效（`/tmp/tp1` 未建）→ 必须 `doExec env TARGETPATH=... sh ...`（env 前缀在 doExec 内仍 word-split，但 `VAR=x` 无空格安全；已实测 TARGETPATH 传通）。v-xfce4/w-xlunch 跨调用即用此式。
- **doExec word-splits args**：`doExec sh -c 'STR'` 单引号串被拆不可用；`doExec xfce_lib name "url"` 的 URL 无空格可安全。
- **bare `doExec X` 无 `|| exit 1` 会被尾部 `exit 0` 掩盖**：v-pavucontrol/v-xlunch full 原 bare 已补 `|| exit 1`。
- doExec 函数内 `set +e` 子 shell，被调函数靠内部 `|| return/exit` 守卫传播 rc（本批函数均有，无需再加 set -e）。

**验证（builder-pav 实跑，AGENTS §3 判据）**：
- `w-scrot b_deps`：`doExec bash /src/w-xlunch/build.sh imlib2` 跨调用实建 imlib2（11s，rc=0），分层日志 `bash__src_w-xlunch_build.sh_imlib2.log` 生成，结果文件 `0|bash /src/w-xlunch/build.sh imlib2`。
- `doExec false || exit 1`：停链（后续命令未执行）、rc=1 传播（防尾部 `exit 0` 掩盖）。
- `doExec env TARGETPATH=... sh ...`：TARGETPATH 传通（`tp_result=TP=/usr/local/static/dbus`）。
- 14 文件 `sh -n` 全通过。

**落仓**：14 个独立 commit（每 build.sh 一 commit，agents §3.1），推送 `feat/ai-260925`（rebase 远端 3 个 `bx/cpl` 新提交后 `84316ed..6d375c4`）。

#### 9.2、11.4 前（历史）build.sh 的 b_deps/full 调用 doExec 适配（2026-11-13 实施+验证，已推送）

**范围**：11.4 前已存在的 build.sh（`git log --diff-filter=A --until=2026-11-04` 之前入库），其 `b_deps`/`full` 内的调用全部补 doExec 包装。共 **17 个 build.sh** + 1 处 `common.sh` 修复（18 commit）。`_ex/{fontconfig,nginx,yad}` 为独立 helper 脚本（不 source common.sh、无 b_deps/full case 分发），范围外。

**改动模式（每文件）**：
1. 入口加 `export DOEXEC_CALLER="${DOEXEC_CALLER:-<comp>}"`（被调继承调用方、顶层入口设自身名；openbox/w-tint2 已有，跳过）。
2. `full` 内每个方法块调用 → `doExec X || exit 1`（防尾部 `exit 0` 掩盖失败）。
3. `b_deps` 内**串行**跨组件调用 → `doExec bash /src/<other>/build.sh <comp> || exit 1`。
4. `b_deps` 内**并行 `&` 组** → `doExec_mark "组名"` 前置 → 每条 `doExec X &` → `wait` → `doExec_check || exit 1`（doExec_mark 写组边界留痕不清，doExec_check 只读本组，见 u-gtkmm `full` 先例）。

**17 文件明细**：

| 文件 | 改动 |
|---|---|
| fluxbox | full `fluxbox` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| openbox | full 三方法块（libxrandr/pango/openbox）补 `\|\| exit 1`；b_deps 两并行组（grp1: libxrandr/pango/libcroco、grp2: librsvg）doExec_mark/&/wait/doExec_check；`STATIC=yes` 跨调用改 `doExec env STATIC=yes bash`（已有 caller） |
| suckless | full `st`/`dwm`/`dmenu` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| u-gtk | 修 `STATIC=yes doExec`→`doExec env STATIC=yes bash`（libcroco/librsvg，前缀 env 不传子进程）；顺序 doExec（gdk-pixbuf/gtk）补 `\|\| exit 1`（已适配，本次修 bug） |
| u-misc | full `su_exec`/`lrzsz`/`n2n`/`tinc` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| v-geany | full `geany` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| v-lxde | 仅入口 DOEXEC_CALLER（full 无调用） |
| v-pcmanfm | full 六方法块（atk/gdk-pixbuf/gtk/libfm/menu-cache/pcmanfm）doExec+`\|\| exit 1`；b_deps 串行 libfm/menu-cache 改 doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| w-feh | full `feh` doExec+`\|\| exit 1`；b_deps 串行 imlib2 + 并行组（xcbutil/libxi）doExec_mark/check；入口 DOEXEC_CALLER |
| w-tint2 | full `tint2` 补 `\|\| exit 1`；b_deps 串行 imlib2/libcroco + 并行组（librsvg/xcbutil/libxi）doExec_mark/check（已有 caller） |
| x-dropbear | full `libxcrypt`/`dropbear` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| x-pulseaudio | full `pulseaudio` doExec+`\|\| exit 1`；b_deps 三并行组（grp1 libogg、grp2 opus+flac+vorbis、grp3 libsndfile）doExec_mark/check；入口 DOEXEC_CALLER |
| x-tigervnc | full 八方法块（gnutls/libxfont2/libfontenc/libtasn1/libxshmfence/tigervnc/xkb/xkbcomp）doExec+`\|\| exit 1`；b_deps+b_tiger 两并行组 doExec_mark/check；入口 DOEXEC_CALLER |
| x-x11vnc | full 三方法块（libvncserver/libxtst/x11vnc）doExec+`\|\| exit 1`；b_deps 并行组（libvncserver/libxtst + w-tint2 libxi 跨调用）doExec_mark/check；入口 DOEXEC_CALLER |
| x-xrdp | full 三方法块（libxrandr/fdkaac/xrdp）doExec+`\|\| exit 1`；b_deps 并行组（libxrandr/fdkaac）doExec_mark/check；入口 DOEXEC_CALLER |
| xcompmgr | full `Xdamage`/`xcompmgr` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |
| xperp | full `perp` doExec+`\|\| exit 1`；入口 DOEXEC_CALLER |

**关键坑（2026-11-13 实测，勿再踩）**：
- **`doExec_mark` 目录 bug（common.sh 已修）**：`doExec_mark` 写 `$LOGS/doExec/$caller/_exec_result.txt`，但原实现只 `mkdir -p $LOGS`（**不建 `doExec/$caller` 子目录**）→ 当并发组边界先于首个 `doExec` 执行时写失败（`can't create ..._exec_result.txt: nonexistent directory`）。u-gtkmm 未踩因 `full` 先 `doExec gtkmm` 已建目录；本次 11.4- 文件 `doExec_mark` 为 case 分支首句才暴露。修复：`mkdir -p $LOGS/doExec/${DOEXEC_CALLER:-default}`。
- **`STATIC=yes doExec` 前缀 env 不传子进程**（同 9.1 dash 前缀 env 坑）：u-gtk/openbox 原 `STATIC=yes doExec /src/w-tint2/build.sh libcroco &` 不生效 → 改 `doExec env STATIC=yes bash ...`。

**验证（builder-pav 实跑，AGENTS §3 判据）**：
- **doExec_mark/check 并行机制合成测试**：组 A（true/echo，全成功）`doExec_check` 返回 0；组 B（true + `false`，一个失败）`doExec_check` 返回 1（捕获 `rc=1`）；`_exec_result.txt` 含正确 `# MARK` 组边界 + 逐条 `rc|cmd` 记录。
- **x-xrdp b_deps 实跑**：`doExec bash /src/x-xrdp/build.sh libxrandr` 并行分发正常，`doExec` 捕获 libxrandr 真实 `rc=2` 写入 `_exec_result.txt`（`2|bash ... libxrandr`）；构建失败为容器无网络/缺 xrdp 依赖的**环境限制**（CI 有网络），非接线问题。
- **17 build.sh + common.sh 语法**：`sh -n` 全通过。

**落仓**：18 个独立 commit（common.sh 1 + 17 build.sh，每文件一 commit，agents §3.1），推送 `feat/ai-260925`（`ecdb9d1..23f06a2`，ahead 18/behind 0 无 rebase，工作树干净）。

#### 9.3、doExec / oneBuild 日志文件名记录方式对比（2026-11-13 分析，未落地）

**背景**：排查 doExec 日志文件名生成行（`common.sh`）时，对比 oneBuild 侧如何记录，确认优化范围。

**两边记录方式**：

| 位置 | 记录行 | 入参 | 是否需清洗 |
|---|---|---|---|
| `doExec` | `local lf=$elog/$(echo "$cmd $args" \| sed 's^[ /]^_^g').log` | `$cmd $args`（含 `bash /src/...` 路径、`env VAR=x`、`=` 等） | **需要**（现状字符集窄） |
| `oneBuild` | `export logfile=$LOGS/oneBuild-$1.log` | `$1` = 方法块名（`libxrandr`/`pango`/`imlib2`/`gdk-pixbuf`…，简单标识符） | **不需要**（无特殊字符） |

**关键差异**：
1. **oneBuild 的 `$1` 是简单方法块名**——不含空格/`/`/引号/glob 元字符，`oneBuild-` 前缀直接可用，**无需清洗**。
2. **oneBuild 已内部改调 `doExec "$1"`**（方案A）：真正构建日志落 `$DOEXEC_LOG`（= doExec 的 `$lf`，`$LOGS/doExec/<caller>/<方法块名>.log`）；`logfile`（`$LOGS/oneBuild-$1.log`）只是失败 tail 的 **fallback**（`${DOEXEC_LOG:-$logfile}`）。
3. doExec 的入参 `$cmd $args` 才暴露清洗问题：`$args` 是 `$@` 用 IFS 拼的，**引号已被调用方 shell 解析剥掉**（`doExec sh -c 'STR'` 到 doExec 内 `STR` 已拆成多参数，无引号残留），实际字符集 ≈ `[A-Za-z0-9_.=-/  ]`。

**现状 doExec 问题**（`local lf=...` 行）：
- 只替换 `空格` 和 `/`，其余 shell/glob 特殊字符（`* ? [ ]`、`& | ; < > $ ( ) { } # ! \``、`=`、`:`、`"`）留在文件名。
- `local lf=...` **未加双引号**：`$(...)` 结果会 field-split + glob 展开，入参含 `*`/`?`/`[ ]` 时可能被替换/拆分。
- 入参带长 URL 时文件名可超 NAME_MAX(255)。

**优化建议（推荐，未落地）**：
```sh
local lf=$elog/$(printf '%s' "$cmd $args" | sed 's/[^A-Za-z0-9_.=-]/_/g; s/__*/_/g; s/^_//; s/_$//' | cut -c1-120).log
```
- `[^A-Za-z0-9_.=-]` → `_`：保留字母数字、`_`、`.`、`-`、`=`（`env STATIC=yes` 可读），其余（含空格、`/`、`*?[]`、`&|;$`、引号）全换 `_`；`bash /src/xxx` → `bash__src_xxx`（路径层级仍可辨）。
- `s/__*/_/g` 压缩连续 `_`、`s/^_//;s/_$//` 去首尾 → 无 glob/field-split 风险。
- `cut -c1-120` 防超长（URL 场景）。
- `local lf="..."` **加双引号**（防御性，唯一必须加的）。

**结论**：只需优化 doExec 一行，oneBuild 完全不受影响；对 oneBuild 传 `doExec "$1"` 时 `$args` 空、`$cmd`=方法块名，清洗幂等无副作用（`[^A-Za-z0-9_.=-]` 不命中任何字符）。状态：**分析未落地**，待用户拍板后实施。

> **订正（2026-11-13，已实施）**：用户拍板采纳方案，且 **`=` 也替换**（白名单不含 `=`）。最终落地 `common.sh` doExec：
> `local lf=$elog/$(printf '%s' "$cmd $args" | sed 's/[^A-Za-z0-9_.-]/_/g; s/__*/_/g; s/^_//; s/_$//' | cut -c1-120).log`
> 实测（builder-pav）：`bash /src/x-xrdp/build.sh libxrandr`→`bash_src_x-xrdp_build.sh_libxrandr.log`、`env STATIC=yes bash /src/w-tint2/build.sh libcroco`→`env_STATIC_yes_bash_src_w-tint2_build.sh_libcroco.log`（`=`→`_`）、`echo ok`→`echo_ok.log`；`sh -n` 通过。oneBuild 侧不动（`$1` 方法块名清洗幂等）。

#### 9.4、STATIC=yes 机制分析与冗余（2026-11-13 讨论，未落地）

**背景**：用户质疑「整个项目都是静态构建，为何 libcroco/librsvg 还要区分 `STATIC=yes`？」。核查后确认该开关**不是「组件是否静态」**，而是这两个库的**产物模式**开关；且现状存在**历史冗余**。

**开关控制（w-tint2/build.sh libcroco/librsvg）**：

| 行为 | 默认（无 `STATIC`） | `STATIC=yes` |
|---|---|---|
| LDFLAGS | 覆盖成 `-Wl,--as-needed -Wl,--strip-all`（**去 `-static`**） | 不覆盖（保留 common.sh `-static`） |
| configure | `--enable-static`（默认连 `.so` 一起装） | `--enable-static --disable-shared`（**只出 `.a`**） |
| 辅助可执行 | 动态链（能跑） | 静态链（补 `LIBS+= -lz -llzma -lbz2 -lm`）/ 剔除（librsvg 剔 `bin_PROGRAMS`/`SUBDIRS`、`--enable-introspection=no`） |
| 装后 | 留 `.so` | `rm -f libcroco-0.6.so*` / `rm -f librsvg-2.so*` |

**为什么全静态项目还需要它（不能全局 `-static` 一刀切）**——构建静态库时生成的**辅助可执行必须能运行**：
- libcroco `csslint-0.6`：静态链 libxml2.a 时 zlib/lzma/bzip2/m 传递依赖**不自动链** → `undefined reference to deflateEnd/gzopen/lzma_code` → `make install` 失败（w-tint2/build.sh:20-22 实锤）。
- librsvg `rsvg-convert`/`GISCAN`：需 `libgdk_pixbuf-2.0.a`（Alpine **无 gdk-pixbuf-static 包**）→ 链失败（:90-92 实锤）。
→ 全局 `-static` 会把辅助工具也强制静态链而挂；`STATIC=yes` 靠「剔工具（librsvg）+ 补传递依赖（libcroco）」绕开，默认模式靠「去 `-static` 让工具动态链」绕开。**这是「静态项目里编静态库」的固有矛盾。**

**为什么还要清 `.so`**：configure 默认 `--enable-shared --enable-static` 同时装 `.a`+`.so`；静态消费方（tint2/openbox）pkg-config `-lcroco-0.6` **优先链 `.so`** → `attempted static link of dynamic object`（:75 实锤）。`STATIC=yes` 用 `--disable-shared`+`rm .so` 防此。

**现状冗余**：`STATIC=yes` 调用只有指向 w-tint2 一家（libcroco/librsvg），3 消费方 / 6 处：u-gtk(:354/358)、openbox(:402/406)、w-xlunch(:195/196)。但 **w-tint2 自身 b_deps 用默认**（:339/341，出 `.a`+`.so`），消费方再 `STATIC=yes` **重编一次**（只出 `.a`、清 `.so`）→ **同一 `.a` 编两次、`.so` 装了又被清**。历史遗留（早期 tint2 可能动态构建，:299 有 `.so` ldd；openbox 等纯静态消费方加入后为其加 `STATIC=yes`）。

**可统一方案（未落地）**：w-tint2 b_deps 也直接 `STATIC=yes`（一次只出 `.a`、清 `.so`），消费方不再重编。现状「能跑就没动」。**待用户拍板**：统一 or 维持现状。

## 三、gtkmm224（抽取：原 2.7）

### 1、gtkmm 栈构建验证（2026-11-11，基于 `alpine-builder-gtk224-test` 镜像）

**背景**：本地 amd64 构建 `Dockerfile.builder.gtk224` 成功（`b_deps` 全通过，GTK2 静态库齐备）后，验证 gtkmm 下游依赖是否缺。基于该镜像拉起容器 `builder-gtkmm-dbg`（bind mount 本地 `compile/src:/src`），手动跑 `/src/u-gtkmm/build.sh gtkmm`。

**结果**（`EXIT=0`，604s，07:41:05→07:51:09）：

- **8 个静态库全部产出**（`/usr/lib`）：`libsigc-2.0.a`(36K) `libglibmm-2.4.a`(955K) `libgiomm-2.4.a`(3.4M) `libcairomm-1.0.a`(257K) `libpangomm-1.4.a`(291K) `libatkmm-1.6.a`(583K) `libgdkmm-2.4.a`(491K) `libgtkmm-2.4.a`(7.4M)。
- **`pkg-config gtkmm-2.4 OK: 2.24.5`**。

**依赖齐备确认**：gtk/pango/atk/gdk-pixbuf 的头文件、静态库、pc 均在标准位（`/usr/include/gtk-2.0/...`、`/usr/lib/*.a`、`gtk+-2.0/pango/atk/gdk-2.0/gdk-pixbuf-2.0/glib-2.0/cairo.pc`）；**无缺东西**。仅编译输出为 glib 2.70 `GTimeVal` deprecated **警告**（非错误，预期；代码已有 `glibmm-gprivate`/`pangomm-pango-markup` 两 patch 处理）。

**结论**：gtkmm 栈（libsigc++/glibmm/giomm/cairomm/pangomm/atkmm/gdkmm/gtkmm-2.4）在 GTK2 静态库基础上可直接复用，无需补包/补路径。

### 2、pango 版本顺带结论（2026-11-10/11，纠正旧判断）

旧镜像 `alpine-builder-gtk224`（`0de72edbf2d3`，创建 **2023-12-23 03:53:46Z**）内 `libpango-1.0.a`（mtime **2023-12-23 03:48:54Z**，565198B）版本 **1.49.3**（`meson-info/intro-projectinfo.json`），与仓库脚本 `PANGO_VERSION=1.49.3`（自 init `6666836` 2023-10-18 起从未变）一致 → **旧镜像当年成功构建 1.49.3**。此前"旧镜像 1.48.10"判断有误：1.48.10 实为 apk 共享库（`libpango-1.0.so.0.4800.10`），非自编译产物。当前 gtkmm 构建失败是**新环境回归**，非 pango 版本问题。


### 3、gtkmm224 镜像核对与乌龙澄清（2026-11-12）

**背景**：CI 日志（`job-logs04-gtkmm224.txt`，上一轮回）显示 gtkmm 栈构建成功，但核对本地镜像却查无 gtkmm 静态库 → 一度看似矛盾。实为**拿错镜像 tag**。

**澄清：日志与镜像的对应关系（关键）**：
- CI 日志对应 **`gtkmm224-2` 最终镜像**的构建（`buildx.sh` L117 `img="x11-base:alpine-builder-gtkmm224-2"`；job 跑 `bash buildx.sh gtkmm224`）。
- `Dockerfile.builder.gtkmm224` L3 `FROM ...alpine-builder-gtk224-2`（**起点**）+ L19 `RUN bash /src/u-gtkmm/build.sh full`（gtkmm 栈装进**新镜像层** = 最终镜像）。
- 故 **gtk224-2（FROM 基础）本来就不含 gtkmm**，gtkmm 在 **gtkmm224-2（最终）**——两者不同，**无矛盾**。

**乌龙**：昨天（11-11 15:32）误拿 **`alpine-builder-gtk224-2`**（c9bb66e，基础，无 gtkmm 栈）——tag 比 `gtkmm224-2` **少个 `mm`**（`gtk224-2` vs `gtkmm224-2`），拿错。本地 `docker images -a` 全列无任何 gtkmm tag 镜像（连 dangling 都查过）。

**结论（2026-11-12 拉取 `gtkmm224-2`，Digest `1c8e613`，下一轮回）**：
- ✅ **gtkmm 栈 a 库 8 个齐全**：`libgtkmm-2.4.a` 7.4M / `libgiomm-2.4.a` 3.4M / `libglibmm-2.4.a` 954.8K / `libatkmm-1.6.a` 583.0K / `libgdkmm-2.4.a` 491.1K / `libpangomm-1.4.a` 291.4K / `libcairomm-1.0.a` 256.7K / `libsigc-2.0.a` 36.1K（构建 11-11 14:27-14:34）。
- ✅ **doExec 分层日志** `/tmp/doExec/u-gtkmm/`：`gtkmm_.log`（157886 行，11.3M）+ `_exec_result.txt` = `0|gtkmm`（**rc=0**）；尾部 `>>> Verify gtkmm stack...` + `pkg-config gtkmm-2.4 OK: 2.24.5`。
- ⚠️ 平铺 `/tmp/doExec/*.log`（`bash__src_openbox_*.log` 等）= **基础 gtk224-2 遗留**（旧代码 u-gtk b_deps；`Dockerfile.builder.gtkmm224` L14 注释 `u-gtk b_deps` 未在 gtkmm224-2 层重跑）——与分层共存，正常。
- **轮回对应**：job-logs04 = **上一轮回**（旧 gtkmm 构建日志）；新拉的 gtkmm224-2 = **下一轮回**（新构建，含分层 doExec）。

**镜像备份**：`gtk224-2` → `alpine-builder-gtk224-2-bak-20261112:latest`（c9bb66e，防误覆盖）。

### 4、gtkmm 栈组件并行化拆解分析（2026-11-12，只分析未落地）

#### 4.1、依赖图与可并行性结论

##### 4.1.1、现状：8 组件全串行

`compile/src/u-gtkmm/build.sh` 的 `gtkmm()` 是唯一方法块，8 组件**全串行**：mm-common(0.9.12) → libsigc++(2.10.8) → glibmm/giomm(2.48.1) → cairomm(1.12.0) → pangomm(2.40.0) → atkmm(2.24.2) → gtkmm/gdkmm(2.24.5) → verify。每个组件内部 `make -j$(nproc)` 已并行，但**组件之间串行**——总时长 604s（约 10min，§3.1 记录）。

##### 4.1.2、真实依赖图（configure.ac PKG_CHECK_MODULES 实锤）

从各组件 `configure.ac` 的 `PKG_CHECK_MODULES` 提取（源码 `/tmp/gtkmm-src/`）：

| 组件 | PKG_CHECK_MODULES 声明的依赖 | 说明 |
|---|---|---|
| libsigc++ | mm-common（MM_PREREQ/MM_INIT_MODULE） | 自身即 sigc++ 基础 |
| glibmm/giomm | **sigc++**（sigc++-2.0>=2.8.0） | glib/gobject/gio = 系统 C 库 |
| cairomm | **sigc++**（sigc++-2.0>=2.5.1） | cairo = 系统 |
| pangomm | **glibmm + cairomm**（glibmm>=2.48.0 cairomm>=1.2.2 pangocairo>=1.38.0） | pangocairo 系统 |
| atkmm | **glibmm**（glibmm>=2.46.2 + atk>=1.18） | atk 系统 |
| gtkmm/gdkmm | **giomm(随glibmm) + pangomm + atkmm**（giomm>=2.27.93 pangomm>=2.27.1 atkmm>=2.22.2 + gtk+-2.0） | gtk 系统 |

依赖图（菱形 DAG，非星形）：

```
mm-common → libsigc++ → { glibmm ∥ cairomm } → { pangomm ∥ atkmm } → gtkmm
```

##### 4.1.3、可并行调度表（依赖尊重，最多 2 路）

| 阶段 | 并行内容 | 前置依赖 |
|---|---|---|
| A | mm-common | —（提供 MM_* m4 宏，必须最先） |
| B | libsigc++ | mm-common |
| C | **glibmm ∥ cairomm** | libsigc++ |
| D | **pangomm ∥ atkmm** | glibmm（pangomm 另需 cairomm） |
| E | gtkmm | giomm + pangomm + atkmm |

**每阶段最多 2 路**（结构限制，非机器限制）：
- C 阶段仅 glibmm/cairomm 两个独立。
- D 阶段 pangomm 需等 cairomm（pango 用 cairo），atkmm 只等 glibmm。

##### 4.1.4、预计收益

串行 604s。并行后：C 省 min(glibmm,cairomm)≈60s、D 省 min(pangomm,atkmm)≈60s → **总省约 2min，10min→8min，约 20%**。不会 4x——最重的 glibmm/gtkmm 仍在关键路径串行。

##### 4.1.5、落地注意点（4 个坑）

1. **`fetch()` 的 `name` 是全局变量**——并行两路同时 fetch 会互相覆盖 → 须改 `local name="$1"`。
2. **`cd /tmp/gtkmm-src/<comp>`** 状态性——每组件须包进子 shell `( ... )`，否则并行 cwd 互相干扰。
3. **`set -e` + 后台 `&` + `wait`**——需逐 rc 检查（复用 `doExec_mark/doExec_check` 并发组模式，同 u-gtk b_deps）。
4. **峰值内存/CPU**——glibmm+cairomm 同时编瞬时负载翻倍；CI 弱机可能 OOM。gtkmm（最重）保持串行，风险可控。

##### 4.1.6、结论

**能拆，但只值 2 路**（菱形依赖链 + 最重两组件在关键路径），收益 ~20%（约省 2min），且须解决 4 个并行坑。**投入产出比一般**——若 CI 不卡 gtkmm 这一步，优先级不高；若确要省时，按 A-E 调度落地。

#### 4.2、并行化落地实现思路（细化，2026-11-12 补充，仅思路未改码）

##### 4.2.1、重构原则：组件函数化 + doExec 组调度

现状 `gtkmm()` 是单方法块、8 组件内联**串行**（`u-gtkmm/build.sh` 32-133 行），无法直接并行。落地分两步：

1. **组件函数化**：把每个组件的 `configure/make/install` 段抽成独立函数（`mm_common/libsigc/glibmm/cairomm/pangomm/atkmm/gtkmm/verify`），并加对应 `case` 入口，使每组件可独立 `doExec /src/u-gtkmm/build.sh <comp>` 调用。
2. **调度并行**：`full`/`b_deps` 按 A-E 阶段调度，C/D 阶段用 `doExec ... &` 两路 + `wait` + `doExec_check`（**复用 u-gtk `b_deps` 组模式**：`doExec_mark` 写组边界留痕，`doExec_check` wait 后只读本组记录）。

##### 4.2.2、每组件函数要点（继承现状逻辑）

- 每函数开头 `set -e`（doExec 子 shell 会 `set +e`，函数内重启用，保失败即终止——同现 `gtkmm()` 开头 `set -e`）。
- `cd /tmp/gtkmm-src/<comp>` 在函数内：每路 doExec 是**独立子 shell**，cwd 天然隔离，并行互不干扰。
- 保留各组件 patch（`glibmm-gprivate.patch` / `pangomm-pango-markup.patch`）、`mkcfg`（无 configure 则 autogen）、`--enable-static --disable-shared`、make install 后 `.a` 兜底 cp。
- 特例：mm-common 只装宏（不链静态）；libsigc++ 需 `--disable-documentation`（doxygen 缺失）。

##### 4.2.3、调度伪代码（`full`/`b_deps` 同体）

```sh
b_deps)
  # A/B 串行（轻量小件，无并行价值）
  doExec /src/u-gtkmm/build.sh mm_common || exit 1
  doExec /src/u-gtkmm/build.sh libsigc  || exit 1
  # C 两路：glibmm ∥ cairomm
  doExec_mark "C: glibmm cairomm"
  doExec /src/u-gtkmm/build.sh glibmm &
  doExec /src/u-gtkmm/build.sh cairomm &
  wait; doExec_check || exit 1
  # D 两路：pangomm ∥ atkmm
  doExec_mark "D: pangomm atkmm"
  doExec /src/u-gtkmm/build.sh pangomm &
  doExec /src/u-gtkmm/build.sh atkmm  &
  wait; doExec_check || exit 1
  # E 最重，单独串行（gtkmm 在关键路径）
  doExec /src/u-gtkmm/build.sh gtkmm || exit 1
  doExec /src/u-gtkmm/build.sh verify || exit 1
  ;;
```

- `full` 改为走同一调度（现状 `doExec gtkmm` 整块 → 改为 b_deps 逻辑，或 `full) b_deps` 复用）。
- `doExec` 首个参数是文件路径 → 内部 `bash` 执行（common.sh `doExec` 87 行），组件 `case` 分支接收 `<comp>`。

##### 4.2.4、4 个坑的落地处理

| 坑（§4.1.5） | 落地处理 |
|---|---|
| 1. `fetch()` 的 `name` 全局变量 | 改 `local name="$1"`（函数内声明，两路并行 fetch 互不覆盖） |
| 2. `cd` 状态性 | 每组件函数独立 `cd` + doExec 独立子 shell，cwd 天然隔离 |
| 3. `set -e` + `&` + `wait` | doExec 捕获真实 rc 到 `_exec_result.txt`；`doExec_mark` 写组边界；`wait` 后 `doExec_check` 只读本组，任一非 0 退出 |
| 4. 峰值内存/CPU | 只 2 路；gtkmm（最重）E 阶段单独串行，风险可控；CI 弱机可退 1 路（组内改串行） |

##### 4.2.5、收益与取舍

- 按 §4.1.4：省约 2min（10min→8min，约 20%），结构上限 2 路。
- **决策建议**：若 CI gtkmm 这步是瓶颈且机器有余量 → 按 4.2.3 落地；若 CI 不卡或机器弱 → 保持现状串行，优先级低（§4.1.6 结论）。

##### 4.2.6、落地后验证方法

- 实跑：`docker exec builder-awe sh /src/u-gtkmm/build.sh b_deps`（或 full），对照串行 604s 记录（§3.1）。
- 错误定位：`/tmp/doExec/u-gtkmm/_exec_result.txt` 各组件 `rc|cmd`，`doExec_check` 报错行。
- 产物核对：`verify` 分支 `ls /usr/lib/libgtkmm-2.4.a ...` + `pkg-config --exists gtkmm-2.4`。

#### 4.3、落地实施结果（2026-11-12，builder-awe 实测，已落地）

##### 4.3.1、build.sh 落地改造（`compile/src/u-gtkmm/build.sh`）

- **组件函数化**：原 `gtkmm()` 内联 8 组件拆成 `c_mm_common/c_libsigc/c_glibmm/c_cairomm/c_pangomm/c_atkmm/c_gtkmm/c_verify`，各组件独立 `case` 入口（`mm_common/libsigc/glibmm/cairomm/pangomm/atkmm/gtkmm_comp/verify`），供 `doExec /src/u-gtkmm/build.sh <comp>` 独立调用。
- **A-E 调度**：`gtkmm()` 按依赖图，C/D 用 `doExec_mark` + `doExec ... &` 两路 + `wait` + `doExec_check`（u-gtk b_deps 组模式）。
- **4 坑处理**：`fetch` name 改 `local`；每组件函数独立子 shell（doExec）天然隔离 cwd；doExec 捕获 rc + doExec_check 逐组错误识别；`make -j${PARALLEL_JOBS:-$(nproc)}`（并行时降线程）。

##### 4.3.2、关键：并行收益取决于核数（nproc 自适应）

- **实测发现**：`builder-awe` 仅 **2 核**（`nproc=2`）。2 路各 `make -j$(nproc)`（=4 线程）**过载**；改 `PARALLEL_JOBS=nproc/2`（每路 1 线程）后仍**比串行慢**——总 **833s（13.9min）> 串行 604s（10min）**。
- **原因**：核数固定 2 时，并行两路各分半核，每组件用 1 核（慢 2 倍）；关键路径（glibmm）仍 1 核，不比串行（单路 -j2 满 2 核）快。**nproc<4 并行无收益甚至更慢**。
- **落地**：`gtkmm()` 按 `nproc` 自适应——**nproc>=4 才并行**（2 路各 `-j(nproc/2)`，总 nproc 线程不超载），**nproc<4 自动退串行**（全组件 `-j$(nproc)`）。`FORCE_PARALLEL=1` 可强制并行（验证调度逻辑用）。

##### 4.3.3、强制并行验证（FORCE_PARALLEL=1，nproc=2）

- 完整调度序列跑通：`A/B (mm-common libsigc++) → C 两路 (glibmm∥cairomm) → D 两路 (pangomm∥atkmm) → E (gtkmm) → Verify`。
- **C/D 组 `doExec_check` 全部通过**（glibmm/cairomm/pangomm/atkmm 均 rc=0），无 `exit 1`。
- **产物正确**：8 库全装（`/usr/lib/libgtkmm-2.4.a` 7.4M 等），`pkg-config gtkmm-2.4 OK (2.24.5)`。
- **结论**：并行调度逻辑正确（功能无损）；时长层面 nproc=2 无收益（833s>604s），**CI 机器 nproc>=4 才提速**。

##### 4.3.4、CI 三架构适配

- CI 三架构（amd64/arm64/armv7）同一 `build.sh`：`nproc>=4` 走并行（C/D 两路各半核），**慢架构（arm64/armv7）绝对省时更大**（组件构建时长更长，并行重叠省 min 时长按比例放大）；`nproc<4` 自动串行（不劣化）。
- 注意：arm 交叉编译若 CI 用模拟器/慢 runner，核数可能 <4 → 自动串行；需确认 CI runner 核数再定。

##### 4.3.5、落地总结（凝练，2026-11-12）

- **改动**（`compile/src/u-gtkmm/build.sh`）：组件函数化（8 组件独立 `case` 入口）+ A-E 调度（C/D 两路 `doExec` 组）+ 4 坑落地（`fetch name` 改 `local` / doExec 子 shell 隔离 cwd / `doExec_check` 逐组错误识别 / `PARALLEL_JOBS` 并行降线程）。
- **关键发现**：并行收益**取决于核数**——`builder-awe` 仅 2 核，并行反而慢（`FORCE_PARALLEL=1` 实测 **833s > 串行 604s**）；故 `nproc>=4` 才并行（2 路各 `-j(nproc/2)`，总 nproc 线程不超载），`nproc<4` 自动退串行。
- **实测**：强制并行完整跑通（A/B → C 两路 → D 两路 → E → Verify），**C/D `doExec_check` 全过**（4 组件 rc=0），8 库装全 + `pkg-config gtkmm-2.4 OK (2.24.5)`。
- **CI 三架构**：同一脚本 `nproc>=4` 走并行，**arm64/armv7 慢架构绝对省时更大**；`nproc<4`（如 arm 模拟器 runner）自动串行——需确认 CI runner 核数。


> **去向**：四、五两章（应用调试 + CI实跑验证）已拆出至 `docs/2026/11110827-ci-builder-gtk-app.md`（保留原章节序号与层级，2026-11-13）。本文件仅存一~三章；对应内容见新文档。
