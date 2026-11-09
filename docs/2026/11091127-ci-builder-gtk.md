# ci-builder-gtk：alpine-builder-gtk224 更名 / 烘焙候选 / 缓存清理 分析（2026-11-09）

2026-11-09 启动。针对 builder 镜像 `infrastlabs/x11-base:alpine-builder-gtk224` 的三个诉求做**纯分析**（未改代码）：
① 镜像更名 `alpine-builder-gtk224` → `alpine-builder-gtk224-2`，梳理「构建入口 + 使用方」全部引用点；
② gtk224 已含 gtkmm，找出其他大体量/编译耗时、适合一并烘焙的静态库；
③ 同 gtk 复用缓存前提下，可清理哪些中间产物（减小镜像体积，且不缺口后续应用构建）。

分析手段：`docker diff builder-obox`（区分镜像内容 vs 容器 runtime 新增）、容器内 `du`、读 `compile/buildx.sh` / `compile/src/u-gtk/build.sh` / `builder/Dockerfile.builder.gtk224`。

## 章节表

- 一、alpine-builder-gtk224 → gtk224-2 分析（2026-11-09）
  - 1、镜像更名引用点全量清单（构建入口 + 使用方）
  - 2、gtkmm 烘焙现状 + 其他大/慢库候选
  - 3、缓存复用前提下的中间产物清理分析
  - 4、实施总结（2026-11-09 完成）
  - 5、arm64/armv7 兼容性分析（新加应用/库，2026-11-09，只分析）
  - 6、imlib2 烘焙决策与实施（2026-11-09）

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

#### 4.5 arm64/armv7 兼容性分析（新加应用/库，2026-11-09，只分析未实建）

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

#### 4.6 imlib2 烘焙决策与实施（2026-11-09）

> **决策：烘焙 imlib2 进 gtk224-2。** 它是 5 个 `w-*` 应用（feh/scrot/hsetroot/tint2/xlunch）共享的框架级图片库；Dockerfile 里 feh/scrot/tint2/xlunch 各自 stage 重复下载+编译 imlib2（~4 次/镜像）。虽然 `libImlib2.a` 仅 **597KB**、编译 ~1-2min（不满足「大/慢库」标准），但作为真框架级共享库，烘焙可消除重复构建 + sourceforge 重复下载（源址多镜像、常不稳）。

**烘焙要点（区别于 gtkmm/ICU）：**
- 必须用 `w-xlunch/build.sh imlib2` 的**定制构建**（`make install` 后手动把 **PNG/SVG/JPEG loader 内嵌**进 `libImlib2.a`），非单纯 `make install`——否则 feh/scrot 等丢图片格式支持。
- 前置 apk：`libjpeg-turbo-static jpeg-dev`（内置 jpeg loader 需 `jpeglib.h`）+ imlib2 函数内自带 `apk add xorg-server-dev`。
- 产物落 `/usr/local/lib/libImlib2.a`；`/tmp/imlib2` 源树保留作缓存（同 gtk 复用模型）。

**落地**：`compile/builder/Dockerfile.builder.gtk224` 的 apk 行加 `libjpeg-turbo-static jpeg-dev`；u-gtk `b_deps` 后加 `RUN bash /src/w-xlunch/build.sh imlib2`。后续 w-* stage 的 b_deps 里 imlib2 调用保留（幂等，已存在则复用/跳过）。
