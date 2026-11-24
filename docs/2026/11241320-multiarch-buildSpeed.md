# multiarch-buildSpeed：多架构构建提速方案调研

> **来处**：承接用户 2026-11-24 13:29 提问「buildx 给 arm64/v7 做多架构构建，兼容性好但速度太慢，有无更快且兼容有保障的方案」。本章记录当前方式实据、方案对比与结论（用户拍板方案一不可行后重新深度挖掘）。

## 目录

- 一、多架构构建提速方案调研
  - 1、多架构构建提速方案（2026-11-24 13:29）
  - 2、qemu 局部优化（2026-11-24 13:56）
  - 3、交叉编译与参考项目（2026-11-24 13:56）
- 二、本项目应用 xx 交叉编译改造
  - 1、改造思路与实施（2026-11-24 16:33）
  - 2、方案二实施进展（2026-11-25 12:16）
  - 3、方案三落地，方案一收尾（2026-11-25 12:16）
  - 4、方案一：剩余组件交叉适配（2026-11-25 15:20）
- 三、CI实跑问题处理
  - 1、xdpyprobe 交叉缺 X11：修复+依赖清单（2026-11-25 19:01）
  - 2、GTK2 应用交叉失败：烤基础镜像方案（2026-11-25 21:49）
  - 3、并行构建：独立WS修复+镜像内排错日志获取（2026-11-26 14:46）
  - 4、跨架构源码树互踩：方案一修复验证（2026-11-27 00:55）
- 四、应用构建问题处理
  - 1、pcmanfm 构建故障排查（2026-11-27 10:21）
  - 2、alpine-compile-3 最新镜像核对：最新开关组件产出（2026-11-27 19:11）
  - 3、alpine-compile-3-dbg 镜像三架构产出核对（2026-11-27 22:30）

## 一、多架构构建提速方案调研

### 1、多架构构建提速方案（2026-11-24 13:29）

#### 1.1、问题与当前方式（2026-11-24 13:29）

**用户问题（原文）**：当前项目 buildx 给 arm64/v7 做多架构构建，兼容性挺好（代码不用特别适配），但速度太慢。有无其他方案？速度要快，兼容性也要有保障。

**当前构建方式（实据，2026-11-24 13:29 核对）**：

- **CI 入口**：`.github/workflows/docker-image-x11-base.yml` 用 `docker/setup-qemu-action@v2`（platforms: `arm,arm64,ppc64le,mips64,s390x`）+ `docker/setup-buildx-action@v2`（`driver-opts: network=host`），runner 为 `ubuntu-22.04`（x86）。
- **平台集**：`distros/buildx.sh` 内 `PLAT0="--platform linux/amd64,linux/arm64,linux/arm"`（`type=app` 去 armv7）；个别 distro 收缩为 amd64+arm64（fedora/opensuse 15.0/15.6/openeuler）或 amd64（debian8、alpine≤3.5）。
- **缓存**：registry cache（`--cache-from/to type=registry,ref=$ali2/$ns/$cimg`，`mode=max`，腾讯云 hkccr）。
- **慢因定位**：qemu 用户态模拟**逐条翻译指令**（实测经验约慢 5-15 倍）；且三平台挤一台 x86 轮转模拟、彼此干扰；网络 IO 推送层亦是次要瓶颈。

#### 1.2、方案对比（用户否决方案一后）

**初版方案一（buildx 多节点原生，自建·自家 ARM 真机）**：用户 2026-11-24 13:29 拍板**不可行**——`hk1box-arm64`、`onecloud-armv7` **无公网且时常离线**，无法作 buildx 远程节点/原生构建节点（属**自建**类：自家设备）。

**重新挖掘后的方案对比**：

| 方案 | 速度 | 兼容性 | 成本/前提 | 关键点 |
|---|---|---|---|---|
| ~~① buildx 多节点原生（自建·自家 ARM）~~ | ~~最快~~ | ~~100%~~ | ~~**被否**：无公网、时常离线~~ | ~~不可行（属自建类）~~ |
| ② GitHub Actions 原生 arm64 runner | 快（原生 arm64） | 100%（arm64） | 公共仓库**免费**；私有需付费 larger runner | `runs-on: ubuntu-22.04-arm`（4vCPU arm64，2025-08-07 GA）；**armv7 无官方 runner**（仍 qemu） |
| ~~③ Docker Build Cloud~~ | ~~快（托管原生多节点）~~ | ~~100%（官方支持 amd64+arm64+arm/v7）~~ | ~~**付费**：Pro $9/mo 200min、Team 500min，超 $3/100min；仅 US East；免费仅 Personal 7 天试用~~ | ~~`docker buildx create --driver cloud <ORG>/<BUILDER>`；对接出去最省事~~ |
| ~~④ buildx remote driver 到云 ARM~~ | ~~快（原生）~~ | ~~100%~~ | ~~需云 ARM 实例**有公网 IP**~~ | ~~`--driver remote tcp://host:port`（buildkitd 暴露端口）或 `ssh://`；坑：同一 builder 所有 node 必须同 driver~~ |
| ~~⑤ 云 ARM 自托管 GitHub runner~~ | ~~快（原生）~~ | ~~100%~~ | ~~需云 ARM 实例 + 能连 GitHub~~ | ~~`runs-on: [self-hosted, linux, arm64]`；项目已用阿里云/腾讯云仓库~~ |
| ⑥ qemu 局部优化 | 慢（仅小幅） | 好 | 零成本 | **详见 2.1**——治标不治本 |
| ⑦ 交叉编译 | 快（编译 5-15x） | 未验证（配置错风险高） | 高维护 | **详见 3.1**——gtk2 栈交叉未做 + 无 arm 真机验证，当前不优先 |

#### 1.3、深度挖掘结论与推荐（2026-11-24 13:29）

**核心思路（绕开「一台机器多平台」限制）**：把平台**拆分构建**，每个平台在对应**原生**环境跑，最后同 tag 推送由 registry 聚合为 manifest list——各平台原生速度、无 qemu 翻译、兼容性 100%。

**按「把 arm64 对接出去」的可行组合**：

- **arm64**（推荐三选一）：
  - GitHub Actions 原生 arm64 runner（`runs-on: ubuntu-22.04-arm`）——**公共仓库免费**，最贴合现有 CI（GitHub 镜像 `infrastlabs/docker-x11base` 若为 public 则免费；需确认可见性）。
  - Docker Build Cloud（`--driver cloud`）——**付费**，但零基础设施维护、无公网/离线顾虑，官方明确支持 arm/v7。
  - 云 ARM 实例（阿里云/腾讯云 ARM）——**有公网 IP 可用**，作 `remote driver` 或自托管 runner。
- **amd64**：现有 x86 runner 原生构建（不变）。
- **armv7**：**无免费原生方案**（GitHub 无 armv7 runner）→ 保持 **qemu**（在当前 x86 或 arm64 runner 上模拟）；兼容性维持现状，仅速度仍受限。若愿付费，Docker Build Cloud 的 arm/v7 或云 ARM（armv7 实例）可原生。

**落地建议（GitHub Actions matrix + manifest 聚合，兼容现有 buildx.sh）**：

```yaml
strategy:
  matrix:
    platform: [linux/amd64, linux/arm64]   # armv7 单独 job 或并入 arm64 用 qemu
runs-on: ${{ matrix.platform == 'linux/arm64' && 'ubuntu-22.04-arm' || 'ubuntu-22.04' }}
steps:
  - run: bash buildx.sh core alpine 3.23 latest   # 内层 docker buildx build --platform ${{ matrix.platform }} --push
# 各 platform 同 tag push → registry 自动聚合 manifest list；armv7 另 job 走 qemu
```

**结论**：自建（自家 ARM 设备 + 云 ARM 实例）排除后，**arm64 唯一「免费 + 原生 + 100% 兼容」路径 = GitHub Actions 原生 arm64 runner**（公共仓库）；**armv7 无免费原生方案，只能维持 qemu**（兼容性不降、速度仍受限）；若愿付费，**Docker Build Cloud** 是「对接出去 + 原生多节点 + 无公网顾虑」的最省事方案。

#### 1.4、决策收窄（订正，2026-11-24 13:29 用户拍板）

> **订正（2026-11-24 13:29）**：用户追加拍板「需要付费的不考虑，自建的也不考虑先」，收窄候选。

- **排除（自建类）**：**自家 ARM 设备**（hk1box/onecloud，无公网时常离线）+ **云 ARM 自托管 runner / remote driver 到云 ARM**（自建，需维护云实例）。
- **概念澄清**：自家 ARM 设备与云 ARM 实例同属**自建**大类——都是自搭/自维护的构建节点，用户「自建的不考虑」已同时涵盖两者；仅**托管服务**（GitHub 原生 runner、Docker Build Cloud）非自建。
- **保留唯一**：**GitHub Actions 原生 arm64 runner**（`ubuntu-22.04-arm`，公共仓库免费）——arm64 走原生，armv7 维持 qemu。
- **落地（收窄后）**：平台拆分 job（amd64 走 x86 runner 原生、arm64 走 arm64 runner 原生、armv7 走 qemu），各平台同 tag `--push` 由 registry 聚合 manifest list；**前提是 GitHub 镜像仓库 `infrastlabs/docker-x11base` 为 public**（private 则免费 arm64 runner 不可用，需另行评估）。

### 2、qemu 局部优化（2026-11-24 13:56）

#### 2.1、优化手段与提速估算（2026-11-24 13:56）

> **定位**：自建/付费排除后，qemu 是 armv7 唯一可用路径（arm64 可换 GitHub 原生 runner）。本小节细化 qemu 下**如何提速**及**可评估的量级**（估算，需实测验证）。

**qemu 慢的根因**：用户态模拟**逐条翻译指令**，实测经验约慢 **5-15 倍**；三平台挤一台 x86 轮转模拟、层缓存互相干扰、推送网络 IO 亦为次要瓶颈。局部优化只能缓解、不能消除数量级差距。

**优化手段与提速估算**：

| 手段 | 做法 | 机制 | 估算收益（总构建时间） |
|---|---|---|---|
| ① 拆分平台构建 | `--platform` 分开跑（amd64/arm64/armv7 各自独立 job），各平台独立 cache | 避免 qemu 下三平台共享层缓存互相干扰失效；增量构建缓存命中率↑ | **-20~40%** |
| ② Dockerfile 层合并 | 合并 `RUN apk add`/`COPY`，减少 RUN 层数 | 每层 RUN 在 qemu 下都要重新模拟/解包，层数↓ → 模拟开销↓ | **-10~30%** |
| ③ zstd 压缩 | `--cache-to type=registry,ref=...,mode=max,compression=zstd` + `--output type=image,compression=zstd` | 缓存/推送层更小，网络 IO 快 | 推送时间 **-20~50%**（推送非主瓶颈，对总时间影响小） |
| ④ armv7 挪到 arm64 runner 上模拟 | armv7 job 跑在 `ubuntu-22.04-arm`（原生 arm64）上，qemu 模拟 armv7 | arm64 宿主模拟 armv7 指令集相近，qemu 翻译开销比 x86 模拟低 | **-1.3~2x**（相对 x86 模拟） |
| ⑤ binfmt 升级 | `tonistiigi/binfmt` 或 `setup-qemu-action` 换更全版本 | 支持更多平台/变体 | 微小（<5%） |

**综合评估**：以上①-③可叠加，**总构建时间约 -30~60%**（估算），④仅在有 arm64 runner 时对 armv7 额外 -1.3~2x。但**不改变 qemu 本质**——仍是模拟（慢 5-15x），**无法通过局部优化消除数量级差距**。

**诚实结论**：⑥ 是**治标**。对 **armv7**（无免费原生方案）是唯一免费手段，值得做（叠加后预计 -30~60%）；对 **arm64** 不如直接换 GitHub 原生 runner（原生 vs 模拟，预计 -80% 以上，且彻底消除 qemu 差异）。若做，**先落地①（拆分平台+独立缓存）**，收益最大且改动最小（只拆 buildx.sh 平台参数）。

### 3、交叉编译与参考项目（2026-11-24 13:56）

#### 3.1、交叉编译细化（2026-11-24 13:56）

> **定位**：⑦ 交叉编译是唯一「编译过程=原生速度、无需 qemu、无需 arm 真机」的路径，但本项目 GTK2 静态栈交叉**未验证、复杂度高**。本小节细化复杂度与速度评估。

**基础设施现状（实据核对）**：
- **已有**：`xx-clang`/`xx-clang++`（Alpine clang + `--target`，天然交叉编译器）、`xx-info sysroot`（目标 sysroot）、`xx-clang-wrapper`（修 libtool `--start-group` 重排）、`TARGETPLATFORM` 环境变量（buildx 注入目标平台）。
- **已交叉可行**：**openbox**（纯 X11）——`libxrandr()` 已用 `--build=$(TARGETPLATFORM= xx-clang --print-target-triple)` + `--host=$(xx-clang --print-target-triple)`，`make DESTDIR=$(xx-info sysroot) install`。
- **未交叉**：**GTK2 栈（u-gtk）及 v-* 应用**（pcmanfm/geany/gsm/lxde…）——当前在 target 架构环境（qemu 模拟）下编译，**无 `--host` 交叉逻辑**。

**复杂度清单**：

| 复杂度 | 内容 | 严重度 |
|---|---|---|
| ① GTK2 栈交叉重编 | u-gtk 栈（glib/gtk/pango/cairo/gdk-pixbuf/atk/librsvg/fontconfig/freetype/harfbuzz…）须为 target 架构**全套重编**（当前 .a 为 x86 编译），`--host=arm64-musl` | **高**（最大成本） |
| ② libtool/pkg-config | 交叉时 `.la`/`.pc` 指向 host 路径；需 target sysroot 的 `PKG_CONFIG_SYSROOT_DIR`/`PKG_CONFIG_PATH`，libtool 依赖重排（xx-clang-wrapper 仅 openbox 有） | 高 |
| ③ configure 运行测试 | GTK2 的 configure 含 compile+run 测试，**交叉不能运行** → 需 `--disable-runpath`/手动跳过，漏跳会误判 | 中高 |
| ④ 各组件改造 | v-* 每个组件 configure 加 `--host/--build/--prefix`（参考 openbox），非批量 | 中 |
| ⑤ 架构优化 | cairo/pixman 等有 NEON/SSE 优化，需 `-march=armv7-a -mfpu=neon` 等，否则性能/兼容问题 | 中 |
| ⑥ 验证难 | 交叉产物**无法在 x86 运行**，需 arm 真机/云 ARM 验证（自家 ARM 不可用）→ **运行时错误风险高**（TARGETPATH/PKGDATADIR 等配置错不暴露） | **高**（最大短板） |

**速度评估**：
- **编译过程** = 原生 x86 速度（无 qemu 翻译）→ 比 qemu 快 **5-15x**。
- **首次**：需交叉重编 gtk2 栈 + 组件，仍是原生速度（比 qemu 首次快），但**setup 成本高**（工具链+依赖交叉），实际总收益被 setup 摊薄。
- **增量**（改组件/改 gtk2 库后重编）：**快 5-15x**（原生 vs 模拟），收益最明显。
- 诚实：**编译确实最快**，但**未验证（gtk2 栈未交叉）+ 验证难（无 arm 真机）** → 落地风险高。

**诚实结论**：⑦ 速度最快（编译 5-15x，增量最明显），但**复杂度高**（①gtk2 栈全套交叉是最大成本）+ **验证难**（⑥，x86 无法运行交叉产物，自家 ARM 不可用）——qemu 虽慢却**能跑 configure 测试、无需 arm 真机**。因此⑦当前**不优先**；除非先解决 arm 验证环境（云 ARM/真机）或仅对纯 X11 组件（openbox/fluxbox/tint2…）做交叉（已证可行、依赖少）。若做，**先落地 openbox 类纯 X11 组件交叉**（收益 5-15x、已验证），GTK2 栈交叉留作长期。

#### 3.2、jlesage/docker-baseimage-gui 调研（2026-11-24 14:02，**基于源码克隆分析**）

> **参考项目**：`github.com/jlesage/docker-baseimage-gui`（headless GUI 基础镜像：openbox + TigerVNC + noVNC + nginx，与本项目 rootfs 思路同源）。**2026-11-24 13:56 浅克隆仓库（`git clone --depth 1`）实际分析 Dockerfile.common + src/*/build.sh**，核实架构覆盖与构建方式。

##### 3.2.1、CPU 架构覆盖（多架构，非仅 x64）

| 发行版 | 架构 |
|---|---|
| Alpine 3.18-3.24 | amd64, 386, arm/v6, arm/v7, arm64/v8 |
| Debian 12/13 | amd64, 386, arm/v7, arm64/v8 |
| Ubuntu 18.04 | amd64, 386, arm/v7, arm64/v8 |
| Ubuntu 20.04+ | amd64, arm/v7, arm64/v8 |

##### 3.2.2、构建方式（源码分析修正）

- 编译 stage 全部 `FROM --platform=$BUILDPLATFORM alpine:3.2x AS <comp>`（**在 x86 build 平台跑**，非 target）+ `COPY --from=xx / /`（引入 xx 工具）+ `ARG TARGETPLATFORM` + `RUN /build/build.sh`。
- `CC=xx-clang`/`CXX=xx-clang++`；configure 用 `--build=$(TARGETPLATFORM= xx-clang --print-target-triple)` + `--host=$(xx-clang --print-target-triple)`；`xx-info sysroot/arch/march`；`xx-info-pkg-config`（`pkg_config_libdir=$(xx-info sysroot)/usr/lib/pkgconfig`）；`xx-apk`（target sysroot 装依赖）。
- 产物 `xx-verify --static` 验证 + **UPX 压缩**；最终 `FROM scratch` + `COPY --link --from=<comp> /tmp/... /opt/base/` 拷入交叉产物。

##### 3.2.3、组件交叉编译清单

| 组件 | 语言/栈 | 交叉方式 |
|---|---|---|
| tigervnc（Xvnc/vncpasswd） | C | build.sh（含 gmp `--build/--host`）+ xx-verify |
| openbox（openbox/obxprop） | C | build.sh + xx-verify |
| yad | **GTK2** | build.sh（meson 交叉编译 **pango/atk/gdk-pixbuf** 到 `xx-info sysroot`） |
| nginx / pulseaudio / dbus-daemon / xkbcomp / xrdb / fastcompmgr / hsetroot / htpasswd / audiorecorder / microphone | C | build.sh + xx-verify |
| xdpyprobe | C | `CC=xx-clang make` + `xx-apk add gcc musl-dev libx11-static` |
| notify-send / webauth / webservices | Go | `xx-go build`（CGO_ENABLED=0） |
| fontconfig / xkeyboard-config / intel_clc / viewer-cursor-theme | C/数据 | build.sh |
| noVNC | JS/npm | npm + minify + patch（**架构无关**，非交叉） |

##### 3.2.4、关键结论（对本项目重大启示）
- jlesage **已规模化验证：GTK2 依赖栈（pango/atk/gdk-pixbuf，meson 交叉）+ GTK2 应用（yad）可 xx 交叉编译静态**——本项目 u-gtk 栈未交叉是瓶颈，但 jlesage 证明**可行**。
- 本项目 openbox 已用同样机制（xx-clang + TARGETPLATFORM），**只差把 GTK2 栈（u-gtk）也纳入 xx 交叉**（参考 jlesage yad/fontconfig 的 `xx-info sysroot` + meson/configure --host + `xx-apk` 装依赖）。
- 若 GTK2 栈交叉落地，**编译从 qemu 挪到 x86 原生交叉**，编译部分提速 **5-15x**（同 3.1），无需 arm 真机（交叉产物 `xx-verify` 验证即可）。

**可借鉴的构建流水线**：matrix 按 distro×platform 拆分 job + 各平台独立 `cache mode=max`；build-common 多阶段（公共层缓存复用）；多平台 digest 逐个 pull+run+bats 验证；双 build 规避 `--load` 单平台限制（release 二次 build 靠 cache 秒级）。

#### 3.3、jlesage 交叉编译机制（源码分析，2026-11-24 14:32）

> **依据**：2026-11-24 14:32 克隆 `jlesage/docker-baseimage-gui`，分析 `Dockerfile.common` + `src/*/build.sh` 后，回答交叉编译四个机制问题（并行/产物/与buildx关系/build.sh适配）。与 3.2 同源。

##### 3.3.1、几个架构并行编译？同源码同机器？
- **是**：buildx 一次 `--platform linux/amd64,linux/386,linux/arm/v6,linux/arm/v7,linux/arm64/v8` 驱动 multi-platform；编译 stage 全部 `FROM --platform=$BUILDPLATFORM alpine AS <comp>`（**stage 平台固定 x86 构建机**）+ `ARG TARGETPLATFORM`。
- 同一份源码 `src/<comp>/` + 同一套 xx 工具链（`tonistiigi/xx`），**仅 TARGETPLATFORM 不同** → **每个 target 架构各跑一次交叉编译**（BuildKit 按 target 并行调度）。
- 结论：**同机（x86）、同源码、同编译环境，靠 TARGETPLATFORM 区分架构并行产出**。

##### 3.3.2、编译产物最终放哪？
- **依赖**（pango/brotli/gmp/gnutls/pixman/mesa…）：`make DESTDIR=$(xx-info sysroot) install` 装进**目标 sysroot**（`xx-info sysroot` = target 架构虚拟系统）。
- **组件本体**（tigervnc/openbox/nginx…）：`make DESTDIR=/tmp/<comp>-install`（如 `/tmp/tigervnc-install`、`/tmp/tigervnc-rootfs`、`/tmp/nginx-install`）。
- **最终**：`FROM scratch` stage `COPY --link --from=<comp> /tmp/<comp>-install /opt/base/` 拷入镜像 `/opt/base/bin|lib|share`，buildx 推送 registry（ghcr 缓存 / dockerhub 发布）。

##### 3.3.3、交叉编译与 buildx 的关系？
- **分工**：xx 交叉编译只管**源码→二进制**（产物在 `/tmp/<comp>-install`/sysroot，不碰镜像打包）；buildx 只管**二进制→多架构镜像+推送**（最终 `FROM scratch` + `COPY --link` 组装 + manifest list 聚合 + push）。
- 衔接靠 **Dockerfile 多阶段**（编译 stage 产物 → 最终 scratch stage COPY）。
- 混合：非编译部分（BASEIMAGE 装包、noVNC JS）在 target 平台（**qemu 模拟**）执行；编译部分在 x86 **原生交叉**——buildx 同时调度两者。

##### 3.3.4、build.sh 需要额外适配吗？
- **需要，每组件都改**（共性模板 + 按构建系统不同）：

| 构建系统 | 交叉适配 |
|---|---|
| autotools（openbox 的 libxrandr/xfixes/xcursor） | `CC=xx-clang` + `./configure --build=$(TARGETPLATFORM= xx-clang --print-target-triple) --host=$(xx-clang --print-target-triple)` |
| meson（pango/atk/gdk-pixbuf/libdrm/pixman） | 交叉文件：`pkgconfig='$(xx-info)-pkg-config'`、`sys_root='$(xx-info sysroot)'`、`pkg_config_libdir`、`cpu_family='$(xx-info arch)'` |
| cmake（brotli/llvm/mesa） | `-DCMAKE_FIND_ROOT_PATH=$(xx-info sysroot)`、`DESTDIR=$(xx-info sysroot) cmake --install` |
| Go（notify-send/webauth/webservices） | `xx-go build`（`CGO_ENABLED=0`） |
| make（xdpyprobe） | `CC=xx-clang make` + `xx-apk add gcc musl-dev libx11-static` |

- 统一共性：`export CC=xx-clang`、`DESTDIR=$(xx-info sysroot) install`、`xx-verify --static` 验证、`xx-apk` 装 target 依赖。
- **非无痛**：每个 build.sh 的编译参数全换交叉（下载源码+SHA256 机制不变），且**依赖也一并交叉重编**（openbox 自编 pango/brotli，tigervnc 自编 gmp/gnutls/pixman/mesa）——这是 jlesage 能规模化交叉的关键（**依赖和组件统一走 xx 交叉**）。

#### 3.4、交叉编译底层原理与注意项（2026-11-24 15:03）

> **依据**：通用交叉编译原理 + `jlesage/docker-baseimage-gui` 源码（`tonistiigi/xx` 工具链、`src/*/build.sh`）实证。本小节为 3.3 机制的底层展开。

##### 3.4.1、底层原理

| 环节 | 机制 | 要点 |
|---|---|---|
| clang 天然交叉编译器 | `clang --target=<triple>` 直接指定目标架构，无需单独 gcc 交叉工具链 | 配合 `--sysroot=<xx-info sysroot>` 指向 target 虚拟根（含 target libc/头文件/库） |
| TARGETPLATFORM → triple | `xx-clang --print-target-triple` = **target triple**（如 aarch64-linux-musl）；`TARGETPLATFORM= xx-clang --print-target-triple` = **build triple**（x86_64-alpine-linux-musl） | 同一源码靠 TARGETPLATFORM 分架构，编译 stage 在 x86 机产出各 target 产物 |
| configure `--build/--host` | `--host`=产物运行平台（target），`--build`=编译机平台 | **必须显式**，否则 configure 误判为 host 编译 |
| sysroot 核心 | `xx-info sysroot` = target 架构虚拟系统（/usr 下 target libc+库+头文件） | 所有依赖装进它、组件链它 → 依赖与产物**同架构** |
| pkg-config 交叉 | `xx-info-pkg-config` 查 target sysroot 的 .pc（`pkg_config_libdir=$(xx-info sysroot)/usr/lib/pkgconfig`） | 避免误用 host 库 |
| 产物落点 | 依赖 `DESTDIR=$(xx-info sysroot) install` 进 sysroot；组件 `/tmp/<comp>-install` → 最终 COPY 进镜像 | 见 3.3-2 |

##### 3.4.2、编译环境要额外装哪些

| 类别 | 装什么 | 来源 |
|---|---|---|
| **xx 工具链**（核心） | `xx-clang`/`xx-go`/`xx-apk`/`xx-info`/`xx-verify`/`xx-info-pkg-config` + clang/lld | `FROM tonistiigi/xx`（`COPY --from=xx / /`，jlesage 每编译 stage 都引入） |
| **build 机工具** | `build-base cmake clang git make lld`（编译工具链） | `apk add`（build 平台） |
| **target 依赖** | `xx-apk add gcc musl-dev libx11-dev libx11-static libxcb-static ...`（target 架构 dev/static 包） | `xx-apk`（装进 sysroot） |
| **源码自编依赖** | 每组件自己下载+SHA256+交叉编译（pango/brotli/gmp/gnutls/pixman/mesa...）→ 装 sysroot | 各 `build.sh` |
| **upx**（可选） | 静态产物压缩 | `upx`（build 机，jlesage 单独 stage） |

**要点**：xx 镜像自带 clang+lld（无需另装 gcc 交叉）；gcc/musl-dev 及目标库的 **dev+static 包**必须通过 `xx-apk` 装（普通 apk 装的是 host 架构）；组件依赖**源码自编交叉**（因 Alpine 仓库 target 包未必有 static 版）。

**补充明细（用户 2026-11-24 15:06 提供，与上表同源）**：
- **tonistiigi/xx**（`COPY --from=xx / /`）：提供 `xx-clang`/`xx-go`/`xx-apk`/`xx-info`/`xx-verify` + clang/lld（xx 镜像自带 clang+lld）。
- **build 机工具**：`apk add make clang lld build-base cmake git`（编译工具）。
- **target 依赖**：`xx-apk add gcc musl-dev libx11-dev libx11-static ...`（交叉 sysroot 的 target 包，gcc/musl-dev/各库 dev+static）。
- **源码自编依赖**：每个组件 `build.sh` 自己下载+交叉编译依赖（pango/brotli/gmp/gnutls/pixman...）→ 装 sysroot。
- **upx**（可选）：压缩静态产物。

##### 3.4.3、注意项（坑）

| 坑 | 说明 | 处理（jlesage 实证） |
|---|---|---|
| ① `--build/--host` 必须显式 | 不传 configure 误判为 host 编译 | `--build=$(TARGETPLATFORM= xx-clang --print-target-triple)` + `--host=$(xx-clang ...)` |
| ② pkg-config 误用 host | 默认查 host `/usr/lib/pkgconfig`，链到 host 库（架构错） | `xx-info-pkg-config` / `PKG_CONFIG_SYSROOT_DIR=$(xx-info sysroot)` |
| ③ libtool `.la` 陷阱 | `.la` 的 dependency_libs 可能指向 host 路径 | `find $(xx-info sysroot)usr/lib -name "*.la" -delete` |
| ④ configure 运行测试 | 交叉不能运行 target 二进制，`AC_RUN_IFELSE` 误判 | `--disable-*`/跳过（如 `--enable-malloc0returnsnull`） |
| ⑤ 依赖必须同架构 | 绝不混 host 库 | 全部装进 sysroot |
| ⑥ 静态链顺序 | libtool 重排 `--start-group` | 本项目 `xx-clang-wrapper`；jlesage `LDFLAGS="-fuse-ld=lld --static -static -Wl,--strip-all"` |
| ⑦ march 变体 | armv7 需 `-march=armv7-a -mfpu=neon` | tigervnc `case $(xx-info march)` 处理 |
| ⑧ `xx-verify --static` | 检查产物架构+静态，防架构错不易发现 | 每组件 build 后验证 |
| ⑨ Go 交叉 | `xx-go build`（CGO_ENABLED=0 纯 Go 易；CGO 需 C 交叉编译器） | jlesage notify-send/webauth/webservices |

## 二、本项目应用 xx 交叉编译改造

### 1、改造思路与实施（2026-11-24 16:33）

> 本节内容已拆出至 `docs/2026/11241321-cross-xx01.md`（2026-11-26 12:12）。详见新文档「1、改造思路与实施」。

### 2、方案二实施进展（2026-11-24 18:56）

> 本节内容已拆出至 `docs/2026/11241321-cross-xx01.md`（2026-11-26 12:12）。详见新文档「2、方案二实施进展」。

### 3、方案三落地，方案一收尾（2026-11-25 12:16，本轮）

> 本节内容已拆出至 `docs/2026/11241321-cross-xx01.md`（2026-11-26 12:12）。详见新文档「3、方案三落地，方案一收尾」。

### 4、方案一：剩余组件交叉适配（2026-11-25 15:20）

> 本节内容已拆出至 `docs/2026/11241321-cross-xx01.md`（2026-11-26 12:12）。详见新文档「4、方案一：剩余组件交叉适配」。

## 三、CI实跑问题处理

### 1、xdpyprobe 交叉缺 X11：修复+依赖清单（2026-11-25 19:01）

> 本节内容已拆出至 `docs/2026/11241322-cross-gtk.md`（2026-11-27）。详见新文档「1、xdpyprobe 交叉缺 X11：修复+依赖清单」。

### 2、GTK2 应用交叉失败：烤基础镜像方案（2026-11-25 21:49）

> 本节内容已拆出至 `docs/2026/11241322-cross-gtk.md`（2026-11-27）。详见新文档「2、GTK2 应用交叉失败：烤基础镜像方案」。

### 3、并行构建：独立WS修复+镜像内排错日志获取（2026-11-26 14:46）

> 本节内容已拆出至 `docs/2026/11241322-cross-gtk.md`（2026-11-27）。详见新文档「3、并行构建：独立WS修复+镜像内排错日志获取」。

### 4、跨架构源码树互踩：方案一修复验证（2026-11-27 00:55）

> 本节内容已拆出至 `docs/2026/11241322-cross-gtk.md`（2026-11-27）。详见新文档「4、跨架构源码树互踩：方案一修复验证」。

## 四、应用构建问题处理

### 1、pcmanfm 构建故障排查（2026-11-27 10:21，本轮）

#### 1.1、复现与根因（2026-11-27 10:21，本轮）

**复现结果（成功）**：在最新 `alpine-builder-gtk224-3`（主 Dockerfile base）容器里，按 Dockerfile 调 `b_deps; pcmanfm`（armv7 交叉）——`b_deps rc=0`（libfm/menu_cache 过），`pcmanfm rc=1` → `configure: error: C compiler cannot create executables`。**新容器（builder-g224-verify，pull 最新镜像后）同样复现**。

**根因（config.log 铁证）**：

```
/usr/bin/linux-armv7-ld: cannot find -lgpg-error: Invalid argument
/usr/bin/linux-armv7-ld: cannot find -lXcomposite: Invalid argument
configure:3817: error: C compiler cannot create executables
```

**sysroot 缺 `libXcomposite` + `libgpg-error` 静态库** → configure 测试链接失败。对照：
- `apkdeps()` 用 `apk add`（native 装 `/`，**不进 sysroot**）——`v-pcmanfm/build.sh:345`；
- libfm 正确用 `xx-apk add menu-cache-dev`（进 sysroot）——`v-pcmanfm/build.sh:70`；
- Alpine 包名：`libxcomposite-dev`（含 `libXcomposite.a`+头）、`libgpg-error-static`（含 `libgpg-error.a`）+ `libgpg-error-dev`（头）。

**修复方向（待续）**：pcmanfm() 交叉时补 `xx-apk add libxcomposite-dev libgpg-error-dev libgpg-error-static` 进 sysroot。

#### 1.2、基础库缺失分析与方案拍板（2026-11-27 10:33，本轮）

**三个问题答案**（基础库为何缺失）：

- **① 基础镜像 sysroot 没有这些基础库的 `.a`**——`ls` 确认 fontconfig/Xinerama/pixman/Xcomposite/gpg-error 的 `.a` 全 No such file，**从没装过，非被清**：只有 `.so`（`libfontconfig.so`/`libpixman-1.so`/`libgpg-error.so.0` 的 -dev/运行时、`libXcomposite.so.1` 运行时）；**`libXinerama` 连 `.so` 都没有**（gtk2 栈不用它，pcmanfm 才用）。
- **② gtk 编译为何不需要**——gtk2 栈交叉构建用 `.so`（-dev）**就够**（只引用符号）；**最终静态应用**（pcmanfm）链接才需 `.a`。故 gtk 栈 `.a` 在 sysroot，但其基础依赖 `.a` 从没进 sysroot。
- **③ xx-clear.sh 不会误清**——`intermediate` 只清 `.o/.lo/.libs/.deps`+源码树+apk 缓存（xx-clear.sh:41-45,50-60），**明确保留 `.a/.pc/include/.la`**（:61）；`staticlib` 仅构建前清旧（防串污染），非误清。

**方案拍板**：用户选 **方案 B（基础镜像预装这些基础库 `.a` 进 sysroot——一次、所有应用共享）**；方案 A（各应用 build.sh 补 `xx-apk`）**不采用**。**先只保存文档，暂不开工**（基础镜像预装涉及 gtk224 builder 改动，待后续）。

**订正（2026-11-27 10:33）**：1.1 的「修复方向（待续）：pcmanfm() 交叉补 xx-apk」为方案 A 思路——**方案 B 已拍板，该方向废弃**（pcmanfm build.sh 的 xx-apk 改动已回退）。

#### 1.3、apk 基础库全局梳理与复用通道分类（2026-11-27 11:03，本轮）

**梳理范围**：`compile/src` 全部 `build.sh`（37 个），**20 个真实组件脚本有 apk 使用**（`_ex/` 示例、u-gtk/u-gtkmm 单列）。区分两种：
- **native `apk add`**——装构建宿主 `/`（编译工具/运行时库），**不进 sysroot**；
- **cross `xx-apk add`**——装进 `$XX_SYSROOT`（交叉静态链接用），**本表聚焦此类**。

**复用通道分类规则（用户 2026-11-27 11:03 拍板）**：
- **≥2 组件用到 → 全局复用通道**（统一预装，应用共享；由 u-gtk 构建时统一装入 sysroot）；
- **==1 组件用到 → 组件自有**（写在该组件 `build.sh` 里）。

##### 1.3.1、全局复用候选（cross，≥2 应用脚本）——46 包

| 库 | 频次 | 应用脚本 |
|---|---|---|
| `libx11-dev` | 9 | fluxbox, openbox, suckless, x-tigervnc, x-x11vnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libx11-static` | 9 | fluxbox, openbox, suckless, x-tigervnc, x-x11vnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxcb-static` | 9 | fluxbox, openbox, suckless, x-tigervnc, x-x11vnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxau-dev` | 8 | fluxbox, openbox, suckless, x-tigervnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxdmcp-dev` | 8 | fluxbox, openbox, suckless, x-tigervnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxext-dev` | 8 | fluxbox, suckless, x-tigervnc, x-x11vnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxcb-dev` | 7 | fluxbox, x-tigervnc, x-x11vnc, x-xbindkeys, x-xrandr, x-xrdp, xcompmgr |
| `libxrender-dev` | 7 | fluxbox, openbox, suckless, x-tigervnc, x-xrandr, x-xrdp, xcompmgr |
| `libxfixes-dev` | 5 | openbox, x-tigervnc, x-x11vnc, x-xrdp, xcompmgr |
| `zlib-static` | 5 | openbox, suckless, x-dropbear, x-tigervnc, x-x11vnc |
| `fontconfig-dev` | 4 | fluxbox, suckless, x-tigervnc, x-xrdp |
| `freetype-dev` | 4 | fluxbox, suckless, x-tigervnc, x-xrdp |
| `libxcursor-dev` | 4 | openbox, suckless, x-tigervnc, x-x11vnc |
| `libxinerama-dev` | 4 | suckless, x-tigervnc, x-x11vnc, x-xrdp |
| `libxrandr-dev` | 4 | suckless, x-tigervnc, x-x11vnc, x-xrdp |
| `brotli-static` | 3 | openbox, suckless, x-tigervnc |
| `bzip2-static` | 3 | openbox, suckless, x-tigervnc |
| `fribidi-dev` | 3 | fluxbox, openbox, suckless |
| `fribidi-static` | 3 | fluxbox, openbox, suckless |
| `libpng-static` | 3 | openbox, suckless, x-tigervnc |
| `libxft-dev` | 3 | openbox, suckless, x-tigervnc |
| `openssl-dev` | 3 | u-misc, x-x11vnc, x-xrdp |
| `openssl-libs-static` | 3 | u-misc, x-x11vnc, x-xrdp |
| `cairo-dev` | 2 | openbox, suckless |
| `cairo-static` | 2 | openbox, suckless |
| `expat-static` | 2 | openbox, suckless |
| `fontconfig-static` | 2 | fluxbox, suckless |
| `freetype-static` | 2 | openbox, suckless |
| `g++` | 2 | openbox, suckless |
| `glib-dev` | 2 | openbox, suckless |
| `glib-static` | 2 | openbox, suckless |
| `graphite2-static` | 2 | openbox, suckless |
| `harfbuzz-dev` | 2 | openbox, suckless |
| `harfbuzz-static` | 2 | openbox, suckless |
| `libffi-dev` | 2 | openbox, suckless |
| `libpng-dev` | 2 | openbox, suckless |
| `libxcomposite-dev` | 2 | xcompmgr, pcmanfm(需) |
| `libxdamage-dev` | 2 | x-tigervnc, x-x11vnc |
| `libxml2-dev` | 2 | openbox, suckless |
| `pcre-dev` | 2 | openbox, suckless |
| `pixman-dev` | 2 | x-xrdp, pcmanfm(需) |
| `pixman-static` | 2 | x-tigervnc, pcmanfm(需) |
| `xz-dev` | 2 | openbox, suckless |
| `zlib-dev` | 2 | x-dropbear, x-x11vnc |
| `libgpg-error-dev` | 0脚本(基础crypto) | pcmanfm(经libfm/gcrypt链) |
| `libgpg-error-static` | 0脚本(基础crypto) | pcmanfm(经libfm/gcrypt链) |

**注**：`libgpg-error-*` 当前 **0 脚本显式安装**（仅 pcmanfm 经 libfm/gcrypt 链需要）；属基础 crypto 库（类 zlib/openssl），归全局清单避免回退方案A，**待确认**。

> **订正（2026-11-27 11:55）**：`libgpg-error-*` 经确认**非公共**（仅 pcmanfm 用）→ **归单次（方案A，pcmanfm 脚本）**，不进全局；1.3.1 全局 46→**44**、1.3.2 单次 30→**32**（决策2 折入见 1.4，最终口径以 1.4 为准）。

##### 1.3.2、单次专属（cross，==1 应用脚本）——30 包

| 库 | 组件 |
|---|---|
| `fdk-aac-dev` | x-xrdp |
| `fuse-dev` | x-xrdp |
| `fuse-static` | x-xrdp |
| `imlib2-dev` | openbox |
| `lame-dev` | x-xrdp |
| `libbsd-dev` | x-tigervnc |
| `libfontenc-dev` | x-tigervnc |
| `libjpeg-turbo-static` | x-tigervnc |
| `libmd-dev` | x-tigervnc |
| `libtasn1-dev` | x-tigervnc |
| `libunistring-dev` | x-tigervnc |
| `libunistring-static` | x-tigervnc |
| `libwebp-static` | openbox |
| `libxi-dev` | x-x11vnc |
| `libxkbcommon-dev` | x-tigervnc |
| `libxkbcommon-static` | x-tigervnc |
| `libxkbfile-dev` | x-tigervnc |
| `libxshmfence-dev` | x-tigervnc |
| `libxtst-dev` | x-x11vnc |
| `libxxf86vm-dev` | suckless |
| `lz4-dev` | x-x11vnc |
| `lz4-static` | x-x11vnc |
| `lzo-dev` | u-misc |
| `menu-cache-dev` | v-pcmanfm |
| `nettle-dev` | x-tigervnc |
| `nettle-static` | x-tigervnc |
| `opus-dev` | x-xrdp |
| `tiff-dev` | openbox |
| `xorgproto` | x-x11vnc |
| `zstd-static` | u-misc |

##### 1.3.3、u-gtk/u-gtkmm 单独统计与方案B 细化

**u-gtk/u-gtkmm 依赖对齐（用户 2026-11-27 11:03）**：三架构装的依赖**保持一致**（除非某特定架构有特殊依赖包）；清单**保留最基础、必要**，不搞冗余。u-gtk 现有 16 包（native 构建 gtk 库自身：gtk+2.0-dev、gdk-pixbuf-dev、intltool、vala、shared-mime-info 等；cross 仅 gtk+2.0-dev、curl-static、libbsd-dev、libjpeg-turbo-static、libmd-dev、libwebp-static、libxi-dev）；**u-gtkmm 无 apk 使用**（纯 gtkmm 静态改造）。

**方案B 细化（用户 2026-11-27 11:03）**：1.3.1 的 ≥2 组件库**另列清单表、额外统一安装**——**在 u-gtk 里装**（`u-gtk/build.sh`），**等 gtk 依赖库构建完后再装这一批**（进 sysroot）。替代 1.2 的「基础镜像预装」表述。

> **订正（2026-11-27 11:03）**：1.2「方案 B（基础镜像预装）」细化——**改为在 u-gtk 统一装 ≥2 组件库（gtk 依赖构建完后）**，见 1.3.3。

#### 1.4、apk 基础库改动清单摸底与方案B实施范围（2026-11-27 11:55，本轮）

**方案A/方案B 分工（用户 2026-11-27 11:55 拍板）**：
- **方案B**：公共库（**≥2 组件**用）→ **u-gtk 统一装**（一次、所有应用共享）；
- **方案A**：单次库（**==1 组件**用）→ **该组件自己的 build.sh**；
- 两者**并存分工，非互斥**。
- **决策1**：`g++` 是 C++ 编译器工具，归"工具"**不进公共库**（留 openbox/suckless）。
- **决策2**：**单次-cross 但多组件共享的库**（native 多组件用）→ **也归 u-gtk 公共库**（如 libjpeg-turbo-static、pango-dev、librsvg-dev、xorg-server-dev、curl-static、jpeg-dev、util-linux-dev、lzo-dev、libxkbcommon-*、gtk+2.0-dev 等）。

##### 1.4.1、公共库清单（≥2 组件，→u-gtk）——58 库

`brotli-static` `bzip2-static` `cairo-dev/static` `curl-static` `expat-static` `fontconfig-dev/static` `freetype-dev/static` `fribidi-dev/static` `glib-dev/static` `graphite2-static` `gtk+2.0-dev` `harfbuzz-dev/static` `jpeg-dev` `libbsd-dev` `libffi-dev` `libjpeg-turbo-static` `libmd-dev` `libpng-dev/static` `librsvg-dev` `libwebp-static` `libx11-dev/static` `libxau-dev` `libxcb-dev/static` `libxcomposite-dev` `libxcursor-dev` `libxdamage-dev` `libxdmcp-dev` `libxext-dev` `libxfixes-dev` `libxft-dev` `libxi-dev` `libxinerama-dev` `libxkbcommon-dev/static` `libxml2-dev` `libxrandr-dev` `libxrender-dev` `lzo-dev` `openssl-dev/static` `pango-dev` `pcre-dev` `pixman-dev/static` `util-linux-dev` `xorg-server-dev` `xz-dev` `zlib-dev/static`

##### 1.4.2、单次库清单（==1 组件，留各脚本）——30 库

`boost1.77-static`（v-ibus）`curl-dev`（w-feh）`fdk-aac-dev`（x-xrdp）`fuse-dev/static`（x-xrdp）`gdk-pixbuf-dev`（u-gtk）`imlib2-dev`（openbox）`lame-dev`（x-xrdp）`libfontenc-dev`（x-tigervnc）`libgpg-error-dev/static`（**pcmanfm**）`libtasn1-dev`（x-tigervnc）`libunistring-dev/static`（x-tigervnc）`libvncserver-dev`（x-x11vnc）`libxkbfile-dev`（x-tigervnc）`libxshmfence-dev`（x-tigervnc）`libxt-dev`（w-feh）`libxtst-dev`（x-x11vnc）`libxxf86vm-dev`（suckless）`lz4-dev/static`（x-x11vnc）`menu-cache-dev`（v-pcmanfm）`nettle-dev/static`（x-tigervnc）`opus-dev`（x-xrdp）`startup-notification-dev`（w-tint2）`tiff-dev`（openbox）`xorgproto`（x-x11vnc）`zstd-static`（u-misc）

##### 1.4.3、各组件改动明细（仅链接库；构建工具不动）

| 组件 | 移除公共(cross→u-gtk) | 移除公共(native→u-gtk) | 保留单次 | 新增 |
|---|---|---|---|---|
| fluxbox | fontconfig+fribidi+freetype+libx11/xcb/xau/xdmcp/xext/xrender（13） | fontconfig+fribidi（4） | — | — |
| openbox | X11链+font链+cairo/glib/harfbuzz/graphite2/expat/pcre/xz/brotli/bzip2/libpng/libffi+libxcursor/libxfixes/libxft/libxml2+libwebp（30） | expat+fontconfig+glib+util-linux（5） | imlib2 tiff | — |
| suckless | X11链+font链+cairo/glib/harfbuzz/graphite2/expat/pcre/xz/brotli/bzip2/libpng/libffi+libxcursor/libxfixes/libxft/libxml2+libxinerama/libxrandr（33） | fontconfig+libxcursor+util-linux（4） | libxxf86vm | — |
| u-misc | lzo+openssl（3） | lzo+openssl（3） | zstd | — |
| v-pcmanfm | fontconfig+libxcomposite+libxinerama+pixman（5） | fontconfig+gtk+2.0+libxcomposite（3） | menu-cache | **libgpg-error-dev/static** |
| x-tigervnc | X11链+font链+libpng+brotli/bzip2/zlib+libbsd/libmd/libjpeg/libxkbcommon+pixman（26） | — | libfontenc/libtasn1/libunistring/libxkbfile/libxshmfence/nettle（8） | — |
| x-x11vnc | X11链+openssl+zlib+libxcursor/libxdamage/libxfixes/libxi/libxinerama/libxrandr（15） | lzo+openssl+xorg-server（4） | libxtst lz4 xorgproto | — |
| x-xrdp | X11链+fontconfig+freetype+openssl+pixman（16） | libxcb+openssl（3） | fdk-aac fuse lame opus | — |
| xcompmgr | X11链+libxcomposite（10） | libxcomposite（1） | — | — |
| x-xbindkeys | libx11/xcb/xau/xdmcp/xext（7） | — | — | — |
| x-xrandr | libx11/xcb/xau/xdmcp/xext/xrender（8） | — | — | — |
| x-dropbear | zlib（2） | — | — | — |
| w-xlunch | — | cairo/glib/expat/fribidi/graphite2/harfbuzz/libxml2/librsvg/pango/xorg-server/xz（12） | — | — |
| w-tint2 | — | librsvg/libxcursor/pango/xorg-server（4） | startup-notification | — |
| w-feh | — | curl-static+jpeg+libjpeg（3） | curl-dev libxt | — |
| w-scrot | — | jpeg+libjpeg（2） | — | — |
| x-rofi | — | libxkbcommon（2） | — | — |

##### 1.4.4、实施要点

- **u-gtk 先装公共库**（1.4.1 的 58 库）：cross `xx-apk add`（进 sysroot）+ native `apk add`（进宿主 `/`），**等 gtk 依赖库构建完后再装这批**。
- **组件侧**：移除公共库（cross/native 行），pcmanfm 增 `libgpg-error-dev libgpg-error-static`（单次）。
- **native/cross 三架构**：cross（arm64/armv7）用 sysroot（u-gtk `xx-apk`）；native（amd64）用宿主（u-gtk `apk`）。u-gtk 在 base 镜像先跑、组件 `FROM base` 后跑 → 公共库构建前已就位。
- 构建工具（clang/autoconf/git/intltool/vala/gtk-doc 等）**不参与方案B**，留各组件。

#### 1.5、方案B实施与验证（2026-11-27 13:10，本轮）

##### 1.5.1、公共库统一装、组件移除与三架构验证（2026-11-27 13:10）

**实施（1.4.1/1.4.3 落地）**：公共库由 **u-gtk b_deps 尾部统一 xx-apk add** 进 sysroot（仅 is-cross，45 唯一包/展开约 62 apk 包，含 gpg-error 修正）；**16 组件 build.sh 移除公共库**（cross/native 行），保留单次库 + 构建工具；**openbox apkdeps 保留原样**——被 u-gtk b_deps 调用（构建 pango 等基础库依赖），不能删公共库（1.4.3 出入）；v-pcmanfm 不新增 gpg-error（归公共）。

**验证（builder-g224 容器，alpine-builder-gtk224-3）**：手动装公共库进 armv7/arm64 sysroot 后，挑 GTK2 简单应用随机架构构建，全部 `xx-verify --static` pass：

| 应用 | 架构 | 结果 |
|---|---|---|
| lxtask | armv7（cross） | ✅ xx-verify pass |
| gpicview | arm64（cross） | ✅ xx-verify pass |
| lxtask | amd64（native） | ✅ xx-verify pass |
| lxappearance | arm64（cross，修复后） | ✅ xx-verify pass |
| pcmanfm | arm64（cross） | ✅ xx-verify pass（libfm→menu_cache→pcmanfm 顺序） |
| geany | armv7（cross） | ✅ xx-verify pass（C 程序，静态链） |

**两处出入（验证发现，已修）**：

- **gpg-error 归公共**：1.4.3 归单次（v-pcmanfm），实测 **lxtask 也链 `-lgpg-error`**（v-lxde/build.sh:79，缺 `.a` 时 lxtask FAILED `cannot find -lgpg-error`）→ lxtask+pcmanfm 都用，**≥2 组件应归公共**；改 u-gtk 清单加 `libgpg-error-dev libgpg-error-static`，v-pcmanfm 去掉单次装。
- **lxappearance 补交叉分支**：原 lxappearance() **无交叉适配**（未设 `--host`/`CC`/`PKG_CONFIG`/`ac_cv_prog_cc_cross`），arm64 configure 报 `cannot run C compiled programs`；按 lxtask 模板补全交叉分支，重跑 pass。

**pcmanfm 构建顺序坑（2026-11-27 13:20 验证）**：`menu_cache` 依赖 `libfm-extra.pc`（libfm 前置）→ 必须 **`libfm→menu_cache→pcmanfm`**；逆序则 menu_cache configure 报 `libfm-extra were not met`、pcmanfm 缺 `libmenu-cache.a`。libfm 的 `fm-path`/`file-search-cli-demo` 工具链接失败可容忍（`.a` 已产出，`make install warn` 容忍）。geany 为 C 程序（GTK2，静态链用 `xx-clang++` 因依赖 C++ 库）。

**提交**：u-gtk 全公共库清单 `5d4dd1c6`；16 组件移除公共 `2b9162e4..8c69d1a1`；出入修复 `d3c6cdd5`（u-gtk gpg-error 归公共）、`cf9db82b`（v-pcmanfm 去单次）、`2de36f0b`（lxappearance 补交叉）。

##### 1.5.2、apk 与 xx-apk 区别、单次库交叉进 sysroot 核对与补漏（2026-11-27 14:14）

**用户疑点（2026-11-27 14:14 原文，暂停待细化跟进）**：

1. 「你留在那些应用层面的，那个 `apk` 装包的命令，看还是保留之前的 `apk add`，要用 `xx-apk` 嘛，不用它会不会有问题？？？」
2. 「方案B 没有相悖 —— 特殊库也是进 sysroot 的，这边你说的本地分支跟 cross 分支，意思就是脚本里头还写了两个代码？？都是怎么写的？执行逻辑是怎么样的？比方 `apk add xxx` 我先前看是直接写在那个脚本的根环境的，没有包装在方法体里头的。这样的话，那个脚本一执行就也会用这个本地的方式去安装，那即使交叉编译模式也装了一个本地的，那不是冗余了吗？何必多此一举呢？」
3. 「`xx-apk` 与 `apk` 他们之于三个架构的作用功效是一样的，何不直接用前者一条命令直接写好，不用区分分支，这么搞不简单干脆吗？难不成不同的架构他们的依赖库还会有很大的差异吗？」

**疑点 1 结论（2026-11-27 14:14）**：取决于**该组件是否交叉构建**——

- **只 native 的组件**（无 `XX_CROSS_FILE` 交叉分支）：保留 `apk add` **没问题**，交叉模式根本不会走到。
- **有交叉能力的组件**（有 `XX_CROSS_FILE` 分支 / Dockerfile 有 cross stage）：**必须用 `xx-apk`**（或按架构分流）。因为 `apk add` 把包装进**宿主 amd64 的 `/`**，而交叉编译从 **sysroot**（target 架构目录）取头文件/`.a`/`.pc`——`apk add` 装的库**到不了 sysroot**，交叉时即缺头/缺库而失败。
- 实例：**w-feh**（`libxt-dev` 供 `X11/Intrinsic.h`）、**w-tint2**（`startup-notification-dev` 供 `libstartup-notification-1.0.pc`）原先只有 `apk add`，交叉时 sysroot 缺该头/`.pc` → 缺头编译失败 / cmake `FATAL_ERROR`；已改按架构分流（见 1.5.2.4）。

###### 1.5.2.1、apk 与 xx-apk 的区别

`xx-apk` 是**包在 `apk` 外面的 sh 脚本**（`/usr/bin/xx-apk`），核心逻辑就几句：

```sh
root="/"
if xx-info is-cross; then root="/${XX_TRIPLE}"; fi
apk --root "$root" "$@"
```

| | `apk add X` | `xx-apk add X` |
|---|---|---|
| 目标架构 | **宿主**（amd64，build 平台） | **target**（arm64/armv7，交叉时） |
| 装到哪 | `/`（容器自身根） | 交叉 → `/$XX_TRIPLE`（=sysroot）；native → `/` |
| native 下的行为 | — | **退化为 `apk --root / add X`，与 apk 完全等价** |

**结论：`xx-apk` 三架构通用**。native 下它就是个 `apk --root /`，换成 `xx-apk` 对 native 构建**零影响**；交叉下它把包装进 sysroot。这就是"单一 `xx-apk` 命令打通三架构"的依据。

###### 1.5.2.2、方案B 与单次库不矛盾

方案B = **公共库 u-gtk 统一 `xx-apk` 装 sysroot** + **单次库各组件自己装**。但"各组件自己装"在其 **cross 分支**（`if [ -n "$XX_CROSS_FILE" ]`）里用的就是 `xx-apk`，所以单次库照样进 sysroot。已核对的组件：

| 组件 | 单次库 | cross 分支位置 |
|---|---|---|
| x-xrdp | fuse-dev/static、fdk-aac-dev、opus-dev、lame-dev | `xx-apk` :44 |
| x-tigervnc | nettle-dev/static、libunistring-dev/static、libtasn1-dev、libfontenc-dev、libxshmfence-dev、libxkbfile-dev | `xx-apk` :311 |
| x-x11vnc | lz4-static/dev、libxtst-dev、xorgproto | `xx-apk` :30、:144 |
| suckless | libxxf86vm-dev | `xx-apk` :28 |
| u-misc | zstd-static | `xx-apk` :28 |
| v-pcmanfm | menu-cache-dev | `xx-apk` :71 |
| openbox | imlib2-dev、tiff-dev | `xx-apk` :437-438 |

这些组件交叉能过，正是因为单次库经 `xx-apk` 进了 sysroot——**方案B 与"单次库不进 sysroot 就编不过"并不矛盾**。

###### 1.5.2.3、两处真缺口（w-feh / w-tint2）

**w-feh** 与 **w-tint2** 是**真缺口**（此前一度误判为"不影响"，实为漏判）：

- 这俩**有交叉能力**（w-feh `feh_cross()` 判 `XX_CROSS_FILE`；w-tint2 交叉生成 cmake toolchain 文件），但单次库**只写了 native `apk add`，cross 分支没有 `xx-apk`**：
  - `w-feh/build.sh:30` `apk add libxt-dev curl-dev` —— `libxt-dev` 提供 `X11/Intrinsic.h`（feh 编译必需，缺则 `wallpaper.h:31: fatal error: 'X11/Intrinsic.h' file not found`），交叉时 sysroot 缺该头。
  - `w-tint2/build.sh:350` `apk add startup-notification-dev` —— tint2 16.7 的 `CMakeLists.txt:201` 是 `FATAL_ERROR`（`ENABLE_SN` 默认 ON，build.sh 未 sed 关），交叉时 sysroot 找不到 `libstartup-notification-1.0.pc` → **cmake 直接中止**。
- 未暴露的原因只是 `compile/buildx.sh:301-302` 当前 `COMPILE_TINT2=no` / `COMPILE_FEH=no`（**CI 未启用**）；一旦启用交叉即炸。

**修法**：单次库按架构分流——交叉 `xx-apk`（进 sysroot）、native `apk`（进宿主），避免交叉下多余的 native 安装（见 1.5.2.4）。

###### 1.5.2.4、native/cross 两分支的执行逻辑与冗余问题

**写法（以 x-xrdp 为例）**：脚本里**确实写了两处**——根级 unconditional `apk add`（native 用）+ cross 分支内 `xx-apk add`（交叉用）：

```sh
# 根级：unconditional，任何模式都跑
apk add fuse-static fuse-dev fdk-aac-dev opus-dev lame-dev nasm

# cross 分支：仅 is-cross 跑
if [ -n "$XX_CROSS_FILE" ]; then
  ...
  xx-apk add fuse-dev fuse-static fdk-aac-dev opus-dev lame-dev
fi
```

**执行逻辑**：`source common.sh` → `xx_cross_init`（:443）判 `xx-info is-cross`——交叉则导出 `XX_SYSROOT`/`XX_CROSS_FILE`/`XX_TRIPLE`/`XX_MARCH`，native 则这些变量留空 → cross 分支 `if` 不成立。故根级 `apk add` 两种模式都跑，`xx-apk add` 只有交叉跑。

**冗余性（如实）**：现有组件（x-xrdp/x-tigervnc 等）的根级 `apk add` 在**交叉模式下也照样跑**，把 amd64 包装进宿主 `/`——对交叉产物无用，**属冗余**（且污染宿主 `/usr/local` 的 `.pc`，正是各脚本 `unset PKG_CONFIG_PATH` 防"native .pc 抢先"的原因）。但因其不指向 sysroot，不破坏交叉正确性，故此前未改。

**更干脆的写法**（w-feh / w-tint2 补漏采用，推荐推广）：单次库**只留一处，按架构分流**，根级不再无条件 `apk add`：

```sh
if [ -n "$XX_CROSS_FILE" ]; then
  xx-apk add libxt-dev curl-dev     # 交叉：进 sysroot
else
  apk add libxt-dev curl-dev        # native：进宿主
fi
```

各架构的**依赖库内容一致**（同一 Alpine 仓库、同包名），差异只在**产物架构 + 安装根**（`/` vs `/$XX_TRIPLE`），由 `xx-apk` 内部 `apk --root` 处理——故无需为不同架构各写一份清单。

> **板块状态：暂停（2026-11-27 14:14 用户拍板）**。上述疑点 1/2 已给初答（1.5.2.4）；1.5.2.3 提到的 w-feh/w-tint2 补漏代码**未提交、已回退**。**"是否全组件统一改用单条 `xx-apk`、取消 native/cross 分支"** 待细化跟进（涉及 u-gtk 公共库清单与各组件单次库的合并口径、以及"跨架构包名是否有差异"的实测）。

##### 1.5.3、B方案改造后u-gtk重编译故障排查（2026-11-27 14:50）

###### 1.5.3.1、arm64 单架构失败根因：gcc 下载中断 + 报错被吞（2026-11-27 14:50）

**现象**：CI 三架构（amd64 native / armv7 / arm64）中**仅 arm64 失败**，`u-gtk b_deps` 组1 并发里的 `env STATIC=yes bash /src/w-tint2/build.sh libcroco` 报 `rc=1`。

**证据（取自 `alpine-builder-gtk224-3` 镜像内烘焙的日志，`/usr/local/static/.logs/<arch>/`）**：

1. `aarch64/doExec/u-gtk/bash_src_openbox_build.sh_apkdeps.log`：
   ```
   OK: 894 MiB in 310 packages
   ERROR: Failed to create usr/bin/gcov: Connection aborted    ← 下载中断
   ERROR: gcc-10.3.1_git20211027-r0: IO ERROR                   ← gcc 包未装上
   OK: 938 MiB in 323 packages
   err 0, pass                                                    ← ERROR 被吞
   ```
2. 镜像内实查 `/aarch64-alpine-linux-musl`（sysroot）**gcc/compiler-rt 全空** → gcc 确实没进 sysroot。
3. `aarch64/doExec/u-gtk/env_STATIC_yes_bash_src_w-tint2_build.sh_libcroco.log`（全 15 行）：
   ```
   configure: error: C compiler cannot create executables   ← 无 gcc 运行时，测试程序链不出
   >>> Compiling libcroco...                                ← set +e 未中止
   >>> Installing libcroco...
   make: *** No rule to make target 'install'. Stop.        ← configure 失败 → 无 Makefile
   == doExec FAIL: libcroco  (rc=1) ==
   ```
4. `armv7l/.../bash_src_openbox_build.sh_apkdeps.log` 对照：同样 `OK: 938 MiB in 323 packages`，gcc 下成功（armv7 的报错是 `xx-apk` flock 的 `lock database temporary error`，自动重试已恢复）→ **故 armv7 通过**。

**结论**：

| 项 | 判断 |
|---|---|
| 方案B 缺库？ | **否**。openbox 未被方案B 改动；`gcc` 仍在 openbox apkdeps 的 `xx-apk` 清单里（:406） |
| 并发竞态？ | **否**。armv7 的 lock 报错已自动恢复 |
| 真根因 | **arm64 的 `gcc` 包下载被中断**（`Connection aborted`）→ gcc 未装进 sysroot → libcroco configure 链不出测试程序 |
| 放大器 | `oneBuild`/`doExec` 的 `set +e` + `\|tee` 把 apk 的 `ERROR` **吞成 `err 0, pass`**，一路放行到 libcroco 才炸 |

**待修**：apkdeps 的 `xx-apk add gcc ...` 之后必须**硬校验** gcc 就位（缺则 `exit 1`），否则下游全链都会以难懂的 `cannot create executables` 挂掉。

###### 1.5.3.2、交叉 sysroot 依赖如何提前安装（2026-11-27 15:29）

**问题**：另两个架构（arm64 / armv7）的交叉 sysroot 依赖编译环境，能不能提前装好，别等到组件编译时才现下载？

**先分清两类**（装的位置不同）：

| 类 | 装哪 | 说明 |
|---|---|---|
| A 构建工具 | 宿主 `/`（不分架构） | `musl-dev gcc clang autoconf automake libtool meson pkgconfig patch intltool vala gtk-doc gawk git curl`，`apk add` 即可，现在 `Dockerfile` base stage（:10-11）已有 |
| B 交叉 sysroot 依赖 | `$XX_SYSROOT`（**必须按架构装**） | 就是 `xx-apk add` 的清单，装进去的 `.a`/`.pc`/头都是目标架构的 |

**B 类清单**（散在各脚本里，合并后约 70 个包，按用途分组）：

| 组 | 包 |
|---|---|
| 工具链 | `gcc g++ musl-dev` |
| X11 最小集（`$XX_X11_PKGS`，common.sh:340） | `libx11-dev libx11-static libxcb-dev libxcb-static libxau-dev libxdmcp-dev` |
| X 扩展 | `libxext-dev libxrender-dev libxfixes-dev libxi-dev libxcursor-dev libxcomposite-dev libxrandr-dev libxdamage-dev libxkbcommon-dev libxkbcommon-static xorg-server-dev` |
| 图形栈 | `pango-dev cairo-dev cairo-static fontconfig-dev fontconfig-static freetype-dev freetype-static graphite2-static harfbuzz-dev harfbuzz-static pixman-dev pixman-static fribidi-dev fribidi-static libxft-dev` |
| glib/gtk | `glib-dev glib-static gtk+2.0-dev librsvg-dev libffi-dev libxml2-dev` |
| 图片/压缩/文本 codec | `libpng-dev libpng-static jpeg-dev libjpeg-turbo-static libwebp-static tiff-dev curl-static libbsd-dev libmd-dev zlib-dev zlib-static bzip2-static brotli-static lzo-dev xz-dev libgpg-error-dev libgpg-error-static openssl-dev openssl-libs-static pcre-dev expat-static` |
| 杂项 | `imlib2-dev util-linux-dev` |

（即 u-gtk 尾部 45 个公共库清单 + openbox apkdeps 交叉分支 + X11 最小集的并集。）

**触发提前安装的做法**：在 `Dockerfile.builder.gtk224.xx` 的 arch 循环（:37）**之前**加一个独立 RUN，按架构循环 `xx_cross_init` 后 `xx-apk add` 上面 B 类全集：

```dockerfile
RUN ARCHS=$(echo "$ARCHS" | sed 's|armv7|arm/v7|g; s|,| |g'); \
    for arch in $ARCHS; do \
      unset XX_SYSROOT XX_CROSS_FILE XX_TRIPLE XX_MARCH; \
      export TARGETPLATFORM=linux/$arch; . /src/common.sh; xx_cross_init; \
      [ -z "$XX_SYSROOT" ] && continue; \
      xx-apk --no-cache --no-scripts add <B 类全集>; \
    done
```

**为什么这样就够了**：

- 该 RUN 是**独立层**：只改后面的编译代码时命中 buildkit 缓存 → sysroot 依赖层直接继承，不重新下载。
- `xx-apk` **幂等**：native（amd64）时 `XX_SYSROOT` 为空 → `continue` 跳过，零影响。
- 独立层失败会**直接 fail build**，不再被 b_deps 里 `doExec` 的 `set +e`+`|tee` 吞掉（1.5.3.1 的放大器）。
- b_deps 里 `openbox apkdeps` 的 `xx-apk add g++`（arm64 挂点）与 u-gtk 尾部 45 包清单可保留（幂等）或删除（已提前装），但**冷跑下载面已归零**。

### 2、alpine-compile-3 最新镜像核对：最新开关组件产出（2026-11-27 19:11，本轮）

> **背景（2026-11-27 19:11 用户拍板）**：`alpine-compile-3` 是阿里云**浮动 tag**（CI 每次 push 更新），从阿里云拉取后以最新 `buildx.sh` 开关核对镜像内组件产出，两头对齐。**镜像 tag 会漂移，必须每次重新 `docker pull` 取最新**，否则对不上。

**基准信息（两头）**：

| 项 | 值 |
|---|---|
| 镜像（最新） | `registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-compile-3` |
| 镜像 digest（最新） | `sha256:848743495b6f0d206c33638dd8d84e760665078127bdacb59439ab4b97cf1df1`（重新 pull 才到；先前误拉 `sha256:d250c00e...` 旧构建） |
| 镜像架构 | amd64（本机拉取；arm64 用户暂缓核对） |
| 开关来源提交 | `eee77ef7` "bx plat x3" 2026-11-27 18:19:41（当前 HEAD，最新） |
| ss2 提交 | `9c2de734` "ss2" 2026-11-27 17:02:54（XBINDKEYS/XRANDR/DUNST/ROFI no→yes） |
| ss3/ss4 | `fea0caee` 17:03:55（5 组件 yes，**已 Revert** `3a23a4ef`）；`476d5cd6` 17:04:58（SSH/OPENBOX/PERP yes，保留） |

#### 2.1、最新开关 14 个 yes 组件产出核对表（2026-11-27 19:11）

**开关口径**：`eee77ef7` 的 `compile/buildx.sh`（= ss2 + ss4 并集，ss3 已 Revert）yes 共 14 个：SSH/OPENBOX/PERP/XBINDKEYS/XRANDR/DUNST/ROFI/LXDE/XFCE4/GEANY/ENGRAMPA/GPICVIEW/CLIPIT/DBUS。

**产物核对（镜像内 `/rootfs/usr/local/static/<comp>/`）**：

| 组件 | 最新开关 | 镜像产物 | mtime（UTC） | 状态 |
|---|---|---|---|---|
| dropbear (SSH) | yes | ✓ dbclient/dropbearkey/dropbearconvert + sbin/dropbear | 2026-11-27 10:32 | OK |
| openbox | yes | ✓ 7 个（openbox-session/openbox/...） | 2026-11-27 10:29 | OK |
| perp | yes | ✓ 11 个（sbin/perpd/...） | 2026-11-27 10:25 | OK |
| xbindkeys | yes | ✓ xbindkeys | 2026-11-27 10:25 | OK |
| xrandr | yes | ✓ xrandr + xkeystone | 2026-11-27 10:25 | OK |
| dunst | yes | ✓ dunst/notify-send/dunstctl | 2026-11-27 10:26 | OK |
| **rofi** | yes | **缺 `bin/rofi`**（仅 2 辅助 + themes 数据） | 2026-11-10 17:07（旧） | **FAIL** |
| lxde | yes | ✓ lxappearance/lxtask | 2026-11-27 10:25 | OK |
| xfce4 | yes | ✓ xfce4-display-settings（+ thunar/ristretto/xfce 依赖） | 2026-11-27 10:38 | OK |
| geany | yes | ✓ geany | 2026-11-27 10:34 | OK |
| engrampa | yes | ✓ engrampa | 2026-11-27 10:29 | OK |
| gpicview | yes | ✓ gpicview | 2026-11-27 10:26 | OK |
| clipit | yes | ✓ clipit | 2026-11-27 10:26 | OK |
| dbus | yes | ✓ 9 个（dbus-* + dbus-glib） | 2026-11-27 10:30 | OK |

**结论**：14 个 yes 里 **13 个产出正常**，**仅 rofi 缺主二进制 `bin/rofi`**，其余全部对上。

**rofi 异常明细（日志错误）**——`/rootfs/usr/local/static/.logs/native/doExec/x-rofi/rofi.log` 末 3 行：

```
>>> [native] Verify rofi ...
ls: /usr/local/static/rofi/bin/rofi: No such file or directory
>>> [native] xx-verify FAILED
```

**根因（初判 2026-11-27 19:11）**：meson 0.59 **未生成 rofi 主程序 target**——`ninja` 只跑到 libnkutils 子模块 `[26/28]`，日志无 rofi 主程序链接步骤，`install` 只装 themes/`.pc`（无 `bin/rofi`）。即 `x-rofi/build.sh:283-284` 注释已知的「meson 0.59 丢 rofi 目标」问题（已用固定提交版 libnkutils d436ee7 仍复现）。**放大器**：`oneBuild` 的 `set +e`+`|tee` 把 `xx-verify FAILED` 的 `exit 1` 吞掉（AGENTS 已知坑）→ 镜像带缺 `bin/rofi` 完成。

> **订正（2026-11-27 19:18，用户拍板）**：真正根因是 **xcb-imdkit 版本不匹配**，非 meson 丢 rofi 目标。

**订正依据（rofi.log configure 段，日志有明示）**：`Dependency xcb-imdkit found: NO found 1.0.9 but need: '<= 1.0.2'`——rofi 2.1.1 要求 `xcb-imdkit <= 1.0.2`，容器内自建 **1.0.9** 不满足 → 依赖不满足 → rofi 主程序 target 未生成 → `bin/rofi` 未产出。日志无编译 `error`；依赖构件（xcbutil / xcb-util-{image,renderutil,wm,keysyms,xrm,cursor} / startup-notification / xcb-imdkit）全部 `reuse OK`、`_exec_result.txt` rc=0，唯一失败即 rofi 本体 rc=1。

**老组件两年前拷贝说明**：no 开关组件不重建，镜像内保留**两年前旧产物**（openbox/fluxbox/tigervnc/tint2/pcmanfm/xrdp/suckless/xcompmgr/xlunch mtime 2023-12~2024-09；feh/x11vnc 2026-02）。本次只新构建 yes 组件，故新旧混合属正常，非故障。

**后续**：rofi 需解决 **xcb-imdkit 版本不匹配**（降 xcb-imdkit 到 `<= 1.0.2` / 放宽其 `.pc` 版本 / patch rofi meson 版本要求）才能产出 `bin/rofi`；arm64 架构镜像核对暂缓（用户拍板）。

#### 2.2、rofi 丢 bin/rofi 根因锁定：方案B 漏装 libxkbcommon（2026-11-27 19:44）

> **订正（2026-11-27 19:44）**：2.1 的「19:18 订正 xcb-imdkit 版本不匹配」**被源码推翻**——真正根因是 **xkbcommon 缺失 → libnkutils disabler → meson 0.59 静默丢 rofi 目标**，且源头是 **方案B 漏装 native libxkbcommon**。本节给出完整分析流程与锁定根因。

**现象**：2.1 镜像核对发现 rofi 缺 `bin/rofi`（仅 2 辅助脚本 + themes 数据）。

**分析流程（逐步锁定）**：

1. **初判（2.1，19:18）**：xcb-imdkit 版本不匹配——日志 `Dependency xcb-imdkit found: NO found 1.0.9 but need: '<= 1.0.2'`。
2. **初判被源码推翻**：rofi `meson.build:131-139` 是**双分支**设计——`imdkit_new = dependency('xcb-imdkit', version: '>= 1.0.3')`、`imdkit_old = dependency('xcb-imdkit', version: '<= 1.0.2')`，`if imdkit_new.found() ... elif imdkit_old.found()`。**1.0.9 满足 `>= 1.0.3`**（日志 `Run-time dependency xcb-imdkit found: YES 1.0.9`），`<= 1.0.2` 的 NO 只是 `imdkit_old` 分支**正常判断**（1.0.9 不满足旧分支是预期），**非错误** → xcb-imdkit 版本不是根因。
3. **本地复现**：`builder-g224` **纯 amd64** 完整跑（b_deps + rofi，最新代码）= **同 CI 错误**（rofi rc=1、`bin/rofi` 未产出、`xx-verify FAILED`、`ls: .../bin/rofi: No such file`）→ **非 CI 偶发、非交叉/并行问题**（native 串行也挂）。
4. **build.ninja 查证**：`build rofi` = **0 条**、`source/` 编译 = **0 条**（rofi 上百个源文件一个没编译）、libnkutils 93 条正常 → **rofi 主程序 target 压根没进 build.ninja**（meson 0.59 静默丢目标）。
5. **历史对比**：11-23 可用 commit（`4bb08e2b`，rofi 2.1.1 升级）`x-rofi/build.sh:90` 注释早有记载——「libnkutils 子工程 **xkbcommon 版本检查失败(disabler:true) → nk 变量全 disabler → meson 0.59 静默丢 rofi 目标**」→ 指向 **xkbcommon**。
6. **实查确认**：容器 `find /usr -name "xkbcommon.pc"` **空**、`pkg-config xkbcommon` 报 `not found`；libnkutils `meson.build:96` `nk_xkbcommon = dependency('xkbcommon', version: '>= 0.4.1', required: false)` → NO → disabler → `nk.get_variable('libnkutils')` 变 disabler → rofi `executable('rofi', ..., dependencies: deps)`（meson.build:372）被 meson **静默丢弃**。

**锁定根因**：

| 项 | 判断 |
|---|---|
| 直接根因 | **libnkutils 子工程 xkbcommon 版本检查 NO（≥0.4.1）→ disabler → meson 0.59 静默丢 rofi 目标** |
| 源头 | **方案B（1.4.1）**：`x-rofi/build.sh:162-164` 把 native 的 libxkbcommon 移除（`: # 公共库(libxkbcommon)已由 u-gtk 统一装`），但 **u-gtk native apkdeps（`apk add`）没装 libxkbcommon**——只在 **cross `xx-apk` 分支（:461）装** → native 缺 `xkbcommon.pc` |
| 时间线 | 11-23 可用（x-rofi 自己 `apk add libxkbcommon`）→ 11-25 交叉适配（feaa827f，native 保持 apk add 原路径）→ 11-27 方案B（8c69d1a1，移除 native 装，u-gtk 只 cross 装）→ **挂** |

**修法**：`x-rofi/build.sh` b_deps native 分支恢复补装（幂等；cross 仍走 u-gtk 公共）：

```sh
else
  apk add --no-cache libxkbcommon-dev libxkbcommon-static
fi
```

**影响面**：仅 native rofi（cross 已由 u-gtk `xx-apk` 装 xkbcommon）；`libnkutils` 子工程仅 rofi 用，其他组件不涉。

### 3、alpine-compile-3-dbg 镜像三架构产出核对（2026-11-27 22:30）

**镜像获取踩坑**：`alpine-compile-3` tag 一直停在 digest `84874349`（旧），真正 CI 产物在 **`alpine-compile-3-dbg`**（digest `e4af5e22`）。原因：`compile/buildx.sh:273` 的 plat 被 dbg 注释覆盖成 `linux/amd64,linux/arm64`（无 `linux/arm`），触发 `buildx.sh:327` 的 `img="${img}-dbg"` 后缀逻辑，CI 推送 tag 变成 `alpine-compile-3-dbg`。**armv7 未编 dbg**（plat 不含 arm）。CI run 1057（`3611b924`）12:18Z 启动、12:54Z 结束，status=completed / conclusion=success。

#### 3.1、arm64 交叉失败：rofi b_deps + engrampa 缺 musl loader（2026-11-27 22:30）

**核对方式**：undock 取 `alpine-compile-3-dbg` 的 `linux_arm64` 层，扫 `/rootfs/usr/local/static/` 产物与 `.logs/aarch64/` 日志。

**arm64 失败组件（2 个）**：

**① rofi|0 —— b_deps 阶段就挂**
```
configure: error: /bin/sh ./config.sub aarch64-alpine-linux-musl failed
>>> [aarch64] configure FAILED: startup-notification-0.12
>>> [aarch64] b_deps FAILED: startup-notification
>>> [aarch64] rofi FAILED: b_deps
```
**根因**：`startup-notification-0.12` 的 `config.sub` 版本太老，不认识 `aarch64-alpine-linux-musl` 这个 host triple（musl 后缀是本项目交叉命名）。rofi 的 b_deps 依赖 startup-notification，该依赖 configure 即失败 → rofi 整个没产出。

**② engrampa|0 —— make 阶段缺 musl 动态链接库**
```
qemu-aarch64: Could not open '/lib/ld-musl-aarch64.so.1': No such file or directory
make[3]: *** [Makefile:918: org.mate.engrampa.gschema.valid] Error 255
>>> [aarch64] ENGRAMPA make LINK FAILED
```
**根因**：`glib-compile-schemas`（make 子进程）需要在 sysroot 里跑起来。交叉环境下 qemu 模拟执行，但 **sysroot 缺 `/lib/ld-musl-aarch64.so.1`**（musl 动态 loader）→ 子进程起不来。与 qemu 本身无关，是 **sysroot 的 musl 运行时不完整**——静态链的最终产物不需要 musl loader，但 make 过程中要执行生成的工具（glib-compile-schemas 等）就得有。

**其余组件**：arm64 上 20 个 yes 开关组件全部正常产出（dropbear/fluxbox/openbox/suckless/tigervnc/xrdp/x11vnc/dunst/pcmanfm/lxde/geany/gpicview/clipit/xbindkeys/xrandr/scrot/tint2/feh/xlunch/hsetroot/xcompmgr/perp/thunar/ristretto/xfce4/misc/dbus/hsetroot）。

**三架构状态**：

| 架构 | yes 组件数 | 失败 | 失败项 |
|---|---|---|---|
| amd64 | 22+ | 0 | — |
| arm64 | 20 | 2 | rofi（config.sub 老）、engrampa（sysroot 缺 musl loader）|
| armv7 | — | — | 未编 dbg（plat 不含 arm）|

#### 3.2、arm64 两失败修复方案拍板（2026-11-27 22:45）

**用户拍板：两处都选 A 方案开工**。

**① rofi（startup-notification config.sub 老）——A：替换 config.sub/config.guess 为最新版**
- 做法：构建 b_deps 时，把 startup-notification 源码树里的 `config.sub`/`config.guess` 替换为 automake 自带新版（`/usr/share/automake-*/`），或 `autoreconf -i` 重新生成。
- 作用：新 config.sub 认识 `aarch64-alpine-linux-musl` → configure 过 → b_deps 继续。

**② engrampa（sysroot 缺 musl loader）——A：补 sysroot musl loader**
- 做法：交叉构建时 `xx-apk add musl`（含 `ld-musl-aarch64.so.1`）装进 sysroot `/lib/`。
- 作用：make 子进程 `glib-compile-schemas` 经 qemu 能起 → make 链接继续。
