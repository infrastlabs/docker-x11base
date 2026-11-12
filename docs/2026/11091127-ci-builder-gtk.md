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
- 三、gtkmm224（抽取：原 2.7）
  - 1、gtkmm 栈构建验证（2026-11-11）
  - 2、pango 版本顺带结论（2026-11-10/11，纠正旧判断）
  - 3、gtkmm224 镜像核对与乌龙澄清（2026-11-12）
  - 4、gtkmm 栈组件并行化拆解分析（2026-11-12，只分析未落地）
- 四、应用调试（抽取：原 3.4 + 3.5）
  - 1、gtkmm 下游应用缺失清单（pavucontrol / gnome-system-monitor）
  - 2、pulse 栈当时怎么搞的（awe 容器 + 历史文档回顾）
  - 3、pulse 栈项目内版本落地与应用调试
  - 4、容器内网络排查明细 + 误判链（builder-pav，2026-11-12）
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

## 四、应用调试（抽取：原 3.4 + 3.5）

### 1、gtkmm 下游应用缺失清单（pavucontrol / gnome-system-monitor，2026-11-11）

**背景**：gtkmm 栈验证通过（§2.7）后，基于同一镜像跑两个 GTK2/gtkmm-2.4 下游应用，确认组装容器（builder-awe）外的依赖是否缺。容器 `builder-gtkmm-dbg` 内手动跑（pavucontrol 用 `v-pavucontrol`，gnome-system-monitor 用 `v-sysmonitor`）。

**① gnome-system-monitor**（`bash /src/v-sysmonitor/build.sh full`，EXIT=1）：

| 步骤 | 结果 | 说明 |
|---|---|---|
| gtop / wnck 构建 | ✅ | gnome.org 下载 + 静态 `.a` 产出（`gtop-2.0.a`/`wnck-1.a`）|
| gsm 编译（25 个 .o）| ✅ | 修复 `build_gtop` 缺 `glibtop_server.h` 后通过（commit `35c376b`）|
| **静态链** | ❌ | `cannot find -lstartup-notification-1`、`-lxcb-util` |

- **缺**：`libstartup-notification-1.a`（apk 仅 `startup-notification-dev` 提供 .so/.pc，**无静态 .a**，需构建源码静态库）；`libxcb-util.a`（apk 只有 `.so`，需 w-tint2 `xcbutil` 构建出 `/tmp/xcb-util/src/.libs/libxcb-util.a`）。`libX11-xcb.a` 已有 ✅。
- **新修复**：`build_gtop` 原未收集平台头 `glibtop_server.h`（`glibtop.h:61` 用无前缀 `#include <glibtop_server.h>`，该头在 `sysdeps/<plat>/`）→ 显式 `cp sysdeps/linux/glibtop_server.h`，commit `35c376b`。

**② pavucontrol**（`bash /src/v-pavucontrol/build.sh pavucontrol`，EXIT=1）：

- **源码下载失败**：`$GITHUB/pulseaudio/pavucontrol/archive/refs/tags/v3.0.tar.gz`（github 不可达）→ `/tmp/pavucontrol` 空（仅空 `configure.ac.orig`）→ `./autogen.sh`/`./configure` 缺失。与 atk/librsvg 之前的 github 问题同源。
- **缺 pulse 栈**：`libpulsecommon-13.0`/`libpulse.a`（脚本预期 make 链接失败后手动静态链需 pulse 栈；镜像无 `/usr/local/static/pulseaudio`）。

**③ 结论**：gtkmm 栈 + GTK2 静态库齐备（§2.7）；缺的是**再下游组装依赖**——`startup-notification`/`xcb-util`（libwnck→startup-notification→xcb-util）与 `pulse` 栈（pavucontrol），这些在组装容器 `builder-awe` 里有，但 `alpine-builder-gtk224-test`（本镜像）没有。

**④ 下一步（2026-11-11 拍板）**：先补 sysmonitor（`xcb-util` + `startup-notification` 静态库），后 pavucontrol（pulse 栈：**x11base 仓已有构建脚本，可在 `b_deps` 复用脚本调用**；源码源先手动用 `ghfast.top` 代理测试，不调整脚本）。

#### 1.1 gsm 静态链跑通：补建 startup-notification 静态库（2026-11-12）

**背景**：沿用 §3.4 的 `builder-pav`（`alpine-builder-gtkmm224-2` 镜像）容器，参考 Dockerfile 调用 `bash /src/w-tint2/build.sh xcbutil; sh /src/v-sysmonitor/build.sh full`。CI sysmonitor 阶段此前失败在 `#52 [sysmonitor 1/1] ... clang-12: error: linker command failed` → `GSM static-link FAILED`。

**根因（真实链接错误，容器内手动重跑链接命令抓到）**：
- `/usr/bin/x86_64-alpine-linux-musl-ld: cannot find -lstartup-notification-1`。
- 依赖链：`libwnck → libstartup-notification → xcb-util / X11-xcb`。`xcb-util` 已由 `w-tint2 xcbutil` 补建（`/tmp/xcb-util/src/.libs/libxcb-util.a`），但 **startup-notification 的 `.a` 从未构建**——`v-sysmonitor/build.sh` 只链 `-lstartup-notification-1`，没建对应静态库；Dockerfile sysmonitor 阶段也只跑了 `xcbutil` + `full`，无 startup-notification 静态构建。
- apk `startup-notification-dev` 只给 `.so`/`.pc`，**无静态 `.a`**，需源码编译。

**修复（commit `1c7b99d`，`compile/src/v-sysmonitor/build.sh`）**：
- 新增 `build_startup_notification()`：autotools 构建 `startup-notification-0.12`（`--enable-static --disable-shared --prefix=/usr/local`，`make LIBS="-lXau -lXdmcp"`）→ `/usr/local/lib/libstartup-notification-1.a`；同 `x-rofi` 的 `build_dep` 做法，带「已存在则复用」跳过。
- `full` 流程在 `build_wnck` 之后、`gnome_system_monitor` 之前加 `doExec build_startup_notification`。
- `fetch()` 支持 `.tar.gz`（startup-notification 为 gz；gtop/wnck 为 xz）。
- `build_gtop` / `build_wnck` 加「已产出 `.a` 则跳过重编」（构建幂等，网络抖动/离线可复用）。
- gsm 源码已就绪（`Makefile` + `src/procman.cpp` 存在）则跳过 `rm`+重下（避免每次重下源码；网络抖动/离线兜底）。

**源码 URL**：`https://www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz`（`x-rofi` 同款，CI 已验证可达；本地离线缓存 `.gsm-deps/startup-notification-0.12.tar.gz` 仅开发用，未入仓）。

**验证（容器 `builder-pav`，`bash /src/v-sysmonitor/build.sh full`）**：
- gsm 静态链成功 → `/usr/local/static/gsm/bin/gnome-system-monitor` **17.8MB**，`ELF statically linked stripped`。
- `xx-verify --static` ✅；`strings`：`procman.ini`（gconf-shim）/`utilities-system-monitor`（icon）/`MurrineRcStyle`（murrine）全部 OK。

**注意（本容器实测坑）**：
- `doExec` 返回真实 rc，且脚本顶部 `set -e` 会隐式捕获失败（实测 `doExec false` → 脚本 rc=1，尾部 `exit 0` 不会执行）。但 `full` case 原无显式 `|| exit`——为不依赖 `set -e` 隐式行为、避免「调用上下文变化/errexit 被关」时静默掩盖，已改 `full` case 每个 `doExec ... || exit 1`（commit 同下）。判断成功仍建议看 doExec 日志 `/tmp/doExec/<caller>/*.log` 或产物存在，不只凭脚本返回码。
- 容器环境若继承 `TARGETPATH=/usr/local/static_temp1`，gsm 会装到那里而非 `/usr/local/static/gsm`（CI Dockerfile 显式设 `TARGETPATH=/usr/local/static/gsm`，不受影响）。


### 2、pulse 栈当时怎么搞的（awe 容器 + 历史文档回顾，2026-11-11）

#### 2.1 当时做法：官方 pulseaudio-13.0 tarball（弃项目内 fk-pulseaudio）

**背景**：补齐 pavucontrol 时发现 `x-pulseaudio` 当前脚本产出 pulse **13.99**（缺 `libpulse-mainloop-glib`，装 `static_temp1`），与 pavucontrol 期望（13.0 + mainloop-glib + `/usr/local/static/pulseaudio`）不符；回顾 awe 容器与历史文档确认当时做法。

**awe 容器现状（已成功）**：`pavucontrol`（Nov 8 14:05，20.0M）+ `gnome-system-monitor`（Nov 8 14:20，19.6M）已构建；pulse 栈完整（`/usr/local/static/pulseaudio`）：`libpulse.a` 668K / `libpulse-simple.a` 15K / **`libpulse-mainloop-glib.a`** 19K / `libpulsecommon-13.0.a` 1032K / `libpulsecore-13.0.a` 1393K + pc 三件；版本目录 `pulse-13.0`。

**当时做法**（`docs/2026/11051633-v-pavucontrol.md` §3.4 + `docs/core/pulse03.md`/`pulse05.md`）：

1. **pulseaudio = 13.0 官方发布 tarball**（`pulseaudio-13.0.tar.xz`，自带 configure+build-aux）——git clone `fk-pulseaudio` autotools 全挂（aclocal 悬死/git pull 外网不可达/aux 缺失）→ 弃 git 改官方 tarball。
2. **configure args 复用 `sam-build.sh` 静态配方**（pulse03.md：`--disable-shared --enable-static --disable-alsa/dbus/gtk3/...`），**移除 `--disable-glib2`**（pavucontrol 需 `libpulse-mainloop-glib`）。
3. **libltdl**：configure 硬查 `lt_dladvise_init in -lltdl`，容器仅 `libltdl.so`（无 `.a`）→ **libtool-2.4.6 源码**构建 `libltdl.a`（`libltdlc.a` 重命名）+ `ltdl.h`。
4. **LIBLTDL 修复**：`src/Makefile` 的 `LIBLTDL = @LIBLTDL@` 未替换 → `sed -i "s/LIBLTDL = @LIBLTDL@/LIBLTDL =/g"`（pulse05.md:45）。
5. **装 `/usr/local/static/pulseaudio`**（`CMAKE_BINARY_DIR`，非 static_temp1）；`dep1="-logg -lopus -lsndfile -lFLAC -lvorbis -lvorbisenc"` + `make LDFLAGS="-static --static $dep1"`。

**当前 `x-pulseaudio/build.sh` 差异**：版本 `br-v13-99-3`（fk-pulseaudio git）= **13.99**（非 13.0）；含 `--disable-glib2`（无 mainloop-glib）；装 `$TARGETPATH`（默认 static_temp1）；libltdl / LIBLTDL 未处理。

**结论**：要在 `b_deps` 复用 x11base 脚本产出与 awe 一致的 pulse 栈，需把当时手工步骤落地到 `x-pulseaudio` 脚本（**官方 13.0 tarball + 移除 `--disable-glib2` + libltdl.a + LIBLTDL sed + 装 `static/pulseaudio`**）。

#### 2.2 问与答：当时为什么没用项目内那个版本？

**问（user）**：结合文档最尾部以及回顾历史文档，当时为什么就没有用项目内的那个版本呢？有原因吗？他就自己另外搞了一套。

**答**：有原因，不是随意另搞。当时（2026-11-05，builder-obox）试了项目内版本源（fk-pulseaudio git，`br-v13-99-3`），但 **autotools 全挂**：
1. **`aclocal` 悬死**——`./autogen.sh` 内部跑 `aclocal` 卡死/失败，**生成不了 `configure`**；
2. **`git pull` 外网不可达**——当时容器网络不通，源码更新拉不下来；
3. **`build-aux` 文件缺失**——`config.guess`/`config.sub` 等 aux 脚本缺，autogen 无法收尾。
→ 没有 `configure`，进不了 `./configure`/`make`，**项目内脚本这条路走不通**。

**所以"自己另外搞一套"= 改用官方发布 tarball `pulseaudio-13.0.tar.xz`**：官方发布包**自带 `configure`+`build-aux`**，不需 autogen，直接 `./configure`→`make`；configure args 复用 `sam-build.sh` 静态配方但**移除 `--disable-glib2`**；手动补 `libltdl.a`+`LIBLTDL` sed+装 `/usr/local/static/pulseaudio`。

**那现在（11-11）`x-pulseaudio` 怎么又能构建 13.99？** 看容器里 `sam-build.sh`：它用 **`autoreconf --force --install`**（非 `./autogen.sh`）强制重生成 configure，正好绕开当时 aclocal 悬死；且网络通（gitee 可达），`git pull` 能拉。**但** sam-build.sh 仍含 `--disable-glib2`（缺 mainloop-glib），且版本 13.99 ≠ pavucontrol 期望 13.0。

**结论**：当时弃项目内版本是因 fk-pulseaudio autotools 在容器里跑不动（aclocal 悬死+aux 缺+外网不通），**非主观另搞**；官方 tarball 自带 configure 才走得通。现在能构建是 sam-build.sh 改用 `autoreconf --force --install`+网络通，但仍带 `--disable-glib2`+13.99，故仍与 pavucontrol 期望（13.0+mainloop-glib+`static/pulseaudio`）不一致——这正是"需落地官方 13.0 做法"的原因。

### 3、pulse 栈项目内版本落地与应用调试（2026-11-11）

#### 3.1 按项目内版本（fk-pulseaudio `br-v13-99-3` + sam-build.sh）可行性评估与施工思路（2026-11-11）

**背景**：用户提出改按**项目内版本**（x-pulseaudio 用的 fk-pulseaudio 定制版 + sam-build.sh，非官方 13.0 tarball）落地 pulse 栈；评估可行性与提前验证点。此前"网络不行"判断已纠正——**gitee 可达，13.99 已构建成功**（网络非障碍）。

**可行性：基本可行**（容器实测）：

| 前提 | 现状 | 结论 |
|---|---|---|
| 网络 | gitee 可达，13.99 已构建成功 | ✅ 无风险 |
| autogen | sam-build.sh 用 `autoreconf --force --install`（非 `./autogen.sh`）| ✅ 已绕开当时 aclocal 悬死 |
| glib-2.0（mainloop 前提）| `/usr/lib/libglib-2.0.a` + `pkg-config glib-2.0 OK 2.70.5` | ✅ |
| dep 库（dep1）| `/usr/local/lib/` 有 ogg/FLAC/vorbis/opus/sndfile `.a` | ✅ |
| LIBLTDL sed | sam-build.sh 已含 `LIBLTDL = @LIBLTDL@`→空 | ✅ |
| 13.99 栈 | `static_temp1` 已有 libpulse.a/libpulse-simple.a | ✅（缺 mainloop-glib）|

**需改 4 点**：

1. **移除 `--disable-glib2`**（sam-build.sh）→ 才能产 `libpulse-mainloop-glib.a`（pavucontrol 必需）。
2. **补 `libltdl.a`**：`/usr/lib/libltdl.a` 不存在（只有 `.so`），configure 硬查 `-lltdl` → `apk add libltdl-static`（最快，已装 libtool-2.4.6）或 libtool 源码构建。
3. **装 `/usr/local/static/pulseaudio`**：**调用前指定变量即可**——`CMAKE_BINARY_DIR=/usr/local/static/pulseaudio bash /src/x-pulseaudio/build.sh full`。x-pulseaudio 入口/构建入口 Dockerfile 已指定该路径，sam-build.sh 默认 `CMAKE_BINARY_DIR=/usr/local/static/pulseaudio`，**无需改 build.sh 的 export**。
4. **版本适配**：项目内产出 **13.99**，pavucontrol 硬编码 `-lpulsecommon-13.0`（build.sh:84）+ 期望 13.0 文件（:125）→ 改脚本为 13.99，或软链 13.99→13.0。

**需提前验证**：

1. **⭐ pulse 13.99 API 与 pavucontrol 3.0 兼容**——pavucontrol 3.0（2019）配 pulse **13.0**；fk-pulseaudio **13.99 是定制版**。**用户拍板预估可以**（2026-11-11）；仍建议先试链确认无 `undefined reference` 到 `pa_*`。
2. **`libltdl.a` 来源**：`apk add libltdl-static` 是否提供 `.a`（同版本 2.4.6）；不行则 libtool 源码构建（当时做法）。
3. **移除 `--disable-glib2` 后 configure 过不过**：确认产 `libpulse-mainloop-glib.a` + 其 `.pc`。
4. **dep1 链接顺序**：`-logg -lopus -lsndfile -lFLAC -lvorbis -lvorbisenc`（已按当时做法）。

**结论（用户拍板）**：走项目内版本（fk-pulseaudio `br-v13-99-3`），**版本 API 预估可以**；施工顺序 = 补 libltdl.a → 去 `--disable-glib2` → 调用前设 `CMAKE_BINARY_DIR` 重跑 full → 13.99 栈试链 pavucontrol（过则改 13.0→13.99；不过回官方 13.0）。

#### 3.2 按项目内版本落地实施结果（2026-11-11，builder-gtkmm-dbg）

**背景**：2.3 评估后用户拍板走**项目内版本**（fk-pulseaudio `br-v13-99-3` + sam-build.sh），开工实施；要求保证**不影响原有静态版编译**与**fk 定制功能**（只动构建开关，不碰定制源码）。

**实施步骤与结果**：

| 步骤 | 做法 | 结果 |
|---|---|---|
| ① 补 `libltdl.a` | `apk add libltdl-static` | `/usr/lib/libltdl.a` 61.5K ✅ |
| ② 去 `--disable-glib2` | `sed -i '/--disable-glib2/d' sam-build.sh`（只动 configure 开关，fk 源码未碰）| ✅ |
| ③ 重跑 pulse 栈 | `CMAKE_BINARY_DIR=/usr/local/static/pulseaudio bash sam-build.sh` + `make install` | 装 `/usr/local/static/pulseaudio` ✅ |
| ④ 产出验证 | 见下 | ✅ |
| ⑤ 试链 pavucontrol | v-pavucontrol 改 `-lpulsecommon-13.99` | **RC=0**，17.0M static stripped ✅ |

**④ 产出（`/usr/local/static/pulseaudio`）**：
- `lib/libpulse.a` + `lib/libpulse-simple.a` + **`lib/libpulse-mainloop-glib.a`（新增，原 `--disable-glib2` 时无）**；
- `lib/pulseaudio/libpulsecommon-13.99.a` + `libpulsecore-13.99.a`（原有库**全保留**，未破坏静态版）；
- `lib/pkgconfig/libpulse.pc`/`libpulse-simple.pc`/`libpulse-mainloop-glib.pc`（pc `Requires: libpulse glib-2.0`，`Version 13.99.3-133-g63453-dirty`）。

**⑤ pavucontrol 验证**：`xx-clang++ -static` 链 `-lpulse-mainloop-glib -lpulse -lpulsecommon-13.99` → 成功；`file` = ELF x86-64 **statically linked, stripped**（17.0M）；**无 `undefined reference` 到 `pa_*`** → **pulse 13.99 API 与 pavucontrol 3.0 兼容**（用户预估正确）；strings 含 GTK_ICON_THEME（图标主题支持）。产物 `/usr/local/static_temp1/bin/pavucontrol`（容器 TARGETPATH 默认）。

**落地脚本改动（已提交推送）**：
- `compile/src/x-pulseaudio/build.sh`（`c869d0f`）：clone 后 `sed -i '/--disable-glib2/d' sam-build.sh`（产 mainloop-glib，不碰 fk 源）；`export CMAKE_BINARY_DIR="${CMAKE_BINARY_DIR:-$TARGETPATH}"`（外部指定即装 `static/pulseaudio`）。
- `compile/src/v-pavucontrol/build.sh`（`e85dccb`）：`-lpulsecommon-13.0`→`-lpulsecommon-13.99`（3 处：静态链 / 注释 / b_deps 检查）。

**结论**：项目内版本（fk-pulseaudio 定制 13.99）**走通**；pavucontrol 依赖链（gtkmm 栈 + GTK2 + pulse 13.99 + mainloop-glib + libltdl）齐备；原静态版编译不受影响、fk 定制功能保留（仅去掉一个 configure 开关）。

#### 3.3 v-pavucontrol b_deps 改为实际调用 x-pulseaudio 编译依赖库（2026-11-11）

**问题**：v-pavucontrol/build.sh 的 `b_deps` 分支原只 `echo "GTK2 静态库 + gtkmm 栈 + pulse 栈已在 builder-awe 就位"`（假设已有），但脚本是给 CI 调用的——CI 里 pulse 栈由 **x-pulseaudio** 构建（pulseaudio stage），并非"在 awe 就位"。b_deps 应**实际编译依赖库**。

**改动（commit `028c67b`，`compile/src/v-pavucontrol/build.sh`）**：

```sh
b_deps)
    # 编译依赖库：pulse 栈（项目内 fk-pulseaudio 定制版，含 libpulse-mainloop-glib）
    #   x-pulseaudio b_deps = dep 库（libogg/libFLAC/libvorbis/libopus/libsndfile .a → /usr/local/lib）
    #   x-pulseaudio full   = pulse 静态库（libpulse/libpulse-simple/libpulse-mainloop-glib + pulsecommon/pulsecore → /usr/local/static/pulseaudio）
    export CMAKE_BINARY_DIR=/usr/local/static/pulseaudio
    bash /src/x-pulseaudio/build.sh b_deps
    bash /src/x-pulseaudio/build.sh full
    echo "== gtkmm stack =="; ls /usr/lib/libgtkmm-2.4.a /usr/lib/libglibmm-2.4.a /usr/lib/libgiomm-2.4.a 2>&1
    echo "== pulse stack =="; ls /usr/local/static/pulseaudio/lib/libpulse.a /usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.a 2>&1
    ;;
```

→ CI 里 v-pavucontrol **自包含**：调 `b_deps` 即构建 pulse 栈（不再假设已有）；`v-pavucontrol` 的 `pavucontrol()` 后续直接复用。

**入口 Dockerfile b_deps 调用（已有，链通，无需重复加）**：
- `compile/src/Dockerfile:59-60`（pulseaudio stage）：`sh /src/x-pulseaudio/build.sh b_deps` + `pulseaudio` → 构建 pulse 栈到 `/usr/local/static/pulseaudio`；
- `compile/src/Dockerfile:441`（pavucontrol stage，`FROM gtkmm` 继承 pulseaudio）：`sh /src/v-pavucontrol/build.sh b_deps` → 现在触发 x-pulseaudio 构建依赖库。

**依赖链**：`pulseaudio stage`（x-pulseaudio b_deps+full）→ `gtkmm stage`（FROM pulseaudio 继承）→ `pavucontrol stage`（FROM gtkmm，v-pavucontrol b_deps 再触发/确认）。

#### 3.4 新 gtkmm224-2 镜像容器跑通 pavucontrol + libgtk pixmap theme 不完整修复（2026-11-12）

**背景**：用户拉取远端更新版 `alpine-builder-gtkmm224-2`（digest `1340081e`，本地旧 `1c8e613`），照 awe 方式起容器 `builder-pav`（`-v /_ext:/_ext` + sleep 循环），参考 Dockerfile 调用 `bash /src/v-pavucontrol/build.sh full` 构建 pavucontrol。

**流程**：
1. `b_deps`：x-pulseaudio 编译 libogg/flac/vorbis/opus/sndfile + pulseaudio 13.99 → `/usr/local/static/pulseaudio/lib/libpulse.a` + `libpulsecommon-13.99.a`。
2. `full`（pavucontrol()）：静态链失败 → 暴露 libgtk bug。

**libgtk pixmap theme 不完整 bug（根因）**：
- 现象：`theme_pixbuf_render`/`theme_pixbuf_get_pixbuf`/`pixbuf_rc_style_register_type`/`pixbuf_type_rc_style` undefined（pixbuf-draw.o/pixbuf-main.o 被链入但符号缺失）。
- 根因：`gtk2-2.24.33-printbackends-static.patch` 把 pixmap theme 编进 libgtk 时**只加** `pixbuf-draw.c`+`pixbuf-main.c`，漏了 `pixbuf-rc-style.c`（rc_style 注册）+`pixbuf-render.c`（render 实现）——pixmap engine 共 **4 个 .c**，只加 2 个，libgtk 不完整。应用静态链 libgtk 拉入 pixmap theme 对象 → 缺符号。
- 为何 gtk 构建时不炸：只建 `.a` 不链应用，未暴露；应用（pavucontrol）链接才暴露。

**修复 + 重建**：
- 补丁加回 2 文件（hunk `+704,10`→`+704,12`）。
- 容器内用 GNOME tarball 源码（`/tmp/gtk+-2.24.33`）+ `git init` + `touch config.status`（Reuse 分支），建最小 `autogen.sh`（`autoreconf -fi`）重生成 Makefile.in（初版 tarball 无 autogen.sh + automake 版本不匹配坑），删 SIG 强制 configure。
- 重建 gtk `err 0, pass` 217s；`theme_pixbuf_render/get_pixbuf`+`pixbuf_rc_style_register_type`+`pixbuf_type_rc_style` 全部定义（pixbuf-type 为 BSS `B` 符号）。

**结果**：pavucontrol 静态链成功 → `/usr/local/static/pavucontrol/bin/pavucontrol` **17.8MB**，`ELF statically linked stripped`，xx-verify 通过；glade+desktop+35 语言 .mo；strings GTK_ICON_THEME/MurrineRcStyle ✓（rsvg 软检查 0，pavucontrol 未引用 rsvg 故未拉入，不阻断）。

**commit**：`be7883e`（libgtk pixmap theme 修复，补丁+build.sh 注释）。

**注**：容器内重建 libgtk 缺 ibus（/tmp/ibus 不在，A2 SKIP）——不影响 pavucontrol（仅 xim 内置够用）；需 ibus 输入法需另起 ibus 树合并。


### 4、容器网络排查明细（2026-11-12）：bridge NAT 与 iptables 双后端

任务：容器内跑 `xfce4` 的 `thunar` / `ristretto`，需要构建 `libxfce4ui`、`exo`、`libgarcon`，其中 `libgarcon` 依赖 `libexif`。构建过程中 `v-xfce4` 需要下载大量源码包，网络不通。以下记录完整排查过程。

#### 一、现象与初判

- `curl` / `wget` 下载超时，`apt-get` 无法连接镜像源。
- 宿主机网络正常，容器内 `ping` 公网 DNS 通但 HTTP 不通。
- 初判为 iptables NAT 规则缺失：`docker0` 是 bridge 网络，容器出站必须经宿主机 `FORWARD` + `POSTROUTING` MASQUERADE。

#### 二、关键误判：iptables 双后端（nft vs legacy）

**这是本次排查最重要的坑。**

```bash
# 宿主机检查后端
iptables --version
# 如果输出 "iptables v1.8.x (legacy)" → legacy 后端
# 如果输出 "iptables v1.8.x (nf_tables)" → nft 后端

# 容器内检查
ls /proc/net/ip_tables_names
# 存在 → legacy 内核模块已加载
# 不存在 → 容器实际走 nftables 后端
```

本环境宿主机为 **legacy** 后端。我在排查中一度往 `iptables-nft` 加了 3 条规则：

```bash
iptables -I FORWARD -i docker0 -j ACCEPT
iptables -I FORWARD -o docker0 -j ACCEPT
iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
```

**这 3 条规则加到了 nft 后端，而容器流量实际走 legacy 后端，所以完全无效。**

#### 三、逐层诊断法（本次验证有效）

```bash
# 1. 包到没到容器 veth（宿主机执行）
tcpdump -i docker0 -n 'src host 172.17.0.2' &
# 从容器 curl 外部地址，看 tcpdump 是否抓到 SYN

# 2. FORWARD 链规则（legacy 后端）
iptables -L FORWARD -n -v

# 3. nat POSTROUTING 规则
iptables -t nat -L POSTROUTING -n -v

# 4. 容器内实际出口 IP（关键验证）
ip route get 1.1.1.1
# 应输出 "via <gateway> src <容器IP>"
# 如果 src 不是容器 IP → NAT 未生效，包会以源地址 172.17.0.2 出去，公网回包无处可回
```

`ip route get` 是判断 NAT 是否生效的最快方法，不需要抓包。

#### 四、实际结论：网络是瞬态故障，bridge NAT 无问题

排查推进到最后，发现：

```bash
# 容器内
echo > /dev/tcp/8.8.8.8/443 && echo "TCP OK"     # 通
curl -v https://www.google.com 2>&1 | grep "SSL connection"  # TLS 握手成功
curl -o /dev/null -w '%{http_code}' https://dl.xfce.org/...     # 200/404 均有响应
```

**结论：bridge NAT 规则一直存在且工作正常，之前不通是瞬态网络退化**（DNS 解析成功但 TCP 三次握手失败 / 上游路由抖动），重启或等待即恢复，**不是 iptables 配置问题**。

> 教训：网络不通时先用 `ip route get` 验证 NAT 路径，再 `nc -vz` 逐跳测试，最后才怀疑 iptables。盲目往 iptables 加规则只会污染规则链（尤其双后端环境）。

#### 五、busybox 容器内网络诊断的两个坑（本次踩到）

1. **`sh` 不支持 `/dev/tcp`**：`echo > /dev/tcp/8.8.8.8/443` 报 `nonexistent directory`，是 busybox `sh` 无此实现，**不代表网络不通**。TCP 测试要用 `curl` / `nc`。
2. **长耗时 `docker exec` 触发 host 侧输出截断**：`nc -zv`、`curl` 等待类命令常表现为"整段无输出"，极易误判为卡死/不通。解法：命令输出重定向到容器内文件，再单独 `cat` 读；或后台 `&` 跑。
   实测 `curl http://archive.xfce.org/` → `code=301`，**网络实际是通的**（301 为该站正常重定向）。

#### 六、xfce4 构建最终结果（2026-11-12 完成，thunar / ristretto / display-settings 均验证通过）

**容器实为 `builder-pav`**（镜像 `x11-base:alpine-builder-gtkmm224-2`，网络 10.18.0.0/24）。直接跑 `sh /src/v-xfce4/build.sh <sub>`，**无 `/usr/local/bin/build-xfce4.sh` 包装器**。

**`/src` 已软链接到仓库**：`/src` → `.../docker-x11base/compile/src`（原烘焙副本备份 `/src-baked`），改仓库文件容器内即时生效，免 `docker cp`。

| 步骤 | 结果 |
|---|---|
| ensure_gtk_libs | skip（gtk2 静态树已在 `/usr/lib/`，marker `/usr/local/static/.gtk-state/gtk.sha` 有效） |
| dbus / dbus-glib | 已就绪，skip |
| libxfce4util / xfconf / libxfce4ui / exo / garcon | 全部产出 `.a`（顺带 `libgarcon-gtk2-1.a`、`libxfce4kbd-private-2.a`） |
| libexif 0.6.23 | 产出 `/usr/local/static/exif/lib/libexif.a` |
| **thunar 1.6.3** | **静态链接成功，`xx-verify --static` rc=0，13.7MB，未定义符号 0** |
| **ristretto 0.8.5** | **静态链接成功，`xx-verify --static` rc=0，13.2MB，未定义符号 0** |
| **xfce4-display-settings** | **静态链接成功，`xx-verify --static` rc=0，12.8MB**（`xfce4settings` 只建这 1 个二进制，其余 9 个注释屏蔽；产物落在 `TARGETPATH=/usr/local/static_temp1/bin/`——common.sh 默认值） |

##### 6.1、两处脚本修复

**（1）`xfce_lib` 闸门放宽**（`compile/src/v-xfce4/build.sh:298` 附近）

xfce 包常含 daemon（xfconfd / xfce4ui），其链接需额外符号；原逻辑 `make` / `make install` 失败即 `exit 1`，会把仅需库本身的构建整个中断。改为 make/install 失败仅 WARN，**真正闸门只保留 `test -f $PREFIX/lib/$CHECK`**（`.a` 存在性）。实测 libxfce4ui / exo / garcon 均出现 MAKE WARN 后仍 `installed`。

**（2）LIBS 去掉 `-lXi -lSM -lICE`**（`static_gtk_libs` 与 xfce4settings 两份 LIBS 共 4 行）

Alpine 的 `libice-dev` / `libxi-dev` **不含 `.a`**（仅运行时 `.so`），静态链接报 `cannot find -lXi` / `-lICE`。实测三者均无符号被引用，直接不链即可，链接即通过。

##### 6.2、日志里"看似失败"的红鲱鱼

`build.sh:212` 的 `make -C thunar` 是**故意允许失败**的（脚本注释明写 "CCLD failed (expected, objects built)"，只用它产出的 `.o`）。该步 stderr 里大量 `undefined reference to pcre_* / pixman_*` 属于动态链 libglib 的传递依赖，**与最终静态链接无关**，勿据此判断静态链失败。真错误要看 `build.sh:229` 静态链一行。
