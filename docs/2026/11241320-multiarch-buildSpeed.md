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
  - 4、alpine-compile-3 三架构全面分析清单（2026-11-28 09:30）

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

### 4、alpine-compile-3 三架构全面分析清单（2026-11-28 09:30）

> 基于 undock 取 `alpine-compile-3`（三架构 manifest list，run 1058 `d1678687`，parent=engrampa 修复 `893c7021`）的 `/rootfs` 产物，长期保留 `/tmp/undock-c3`。
> 维度：构建层（bin/sbin 产物 + 日志失败标记）+ 运行层（用户实测/报告）。

#### 4.1、详细分析（2026-11-28 09:30）

**① 总览**
- **106 组**：amd64 39 + arm64 35 + armv7 35（组件目录）
- 构建层真失败 **3 项** + 假警 2 类 + 库/旧组件 3 项
- 运行层 **2 类**（imlib2 家族 5 组件、tint2 arm64 闪退）
- 主要交付障碍：**运行层 imlib2 家族全军覆没 + tint2 arm64 闪退**

**② 构建失败（无 bin 产物）**

| 组件 | 架构 | 日志证据（原文） | 根因 |
|---|---|---|---|
| `engrampa` | arm64/armv7 | `qemu-aarch64: Could not open '/lib/ld-musl-aarch64.so.1': No such file or directory` → `make[3]: *** [Makefile:918: org.mate.engrampa.gschema.valid] Error 255` → `>>> [aarch64] ENGRAMPA make LINK FAILED` | **musl loader 修复无效**：`v-engrampa/build.sh` 的 `xx-apk add musl >/dev/null 2>&1 \|\| true` 吞错 → CI 没装上 loader。镜像含修复（run 1058 parent=`893c7021`）但仍失败 |
| `pasystray` | arm64/armv7 | `make[2]: *** [Makefile:484: pasystray] Error 1` → `>>> [aarch64] PASYSTRAY make LINK FAILED` | gtkmm 系交叉链接失败 |

> **订正（2026-11-28 13:30）**：`pasystray` 的 arm64/armv7 根因**不是** gtkmm 系链接，是交叉下缺 `libnotify.a`（`cannot find -lnotify`）——`b_deps` 只在单一 arch 上下文跑一次，交叉分支未建。已修，见 4.2.3。`suckless` 的 `tic` 缺失见 4.2.2。

> **订正（2026-11-28 14:02）**：`engrampa` 的根因**不是**「loader 没装上」——`xx-apk add musl` 只补 loader 文件，治不了 qemu 缺 `-L $XX_SYSROOT` 前缀；正解是用 **native `glib-compile-schemas`** 绕开 qemu。已修，见 4.2.4。

**③ 构建部分失败（有 bin 但日志错）**

| 组件 | 架构 | 日志证据 | 影响 |
|---|---|---|---|
| `suckless` | 三架构 | `make: tic: No such file or directory` → `make: *** [Makefile:53: install] Error 127` | st 的 terminfo（`tic -sx st.info`）未生成；st 二进制已产出（8 bins），但终端信息缺 `tic` 工具 |

**④ 运行层问题（构建 OK + 静态链接，但运行失败）**

| 组件 | 架构 | 用户实测 | 根因（假设） |
|---|---|---|---|
| `feh` | 三架构 | 不行 | **imlib2 loader 未链/未注册**：feh 链接命令 `-Wl,--start-group -lImlib2 -lXft ... -Wl,--end-group`（imlib2 在组内），产物静态（readelf 无 NEEDED），但 imlib2 图片格式 loader（png/jpeg/gif/svg）独立模块，静态未链 → 运行 `imlib_load_image` 失败 |
| `scrot` | 三架构 | 截图失败 | 同上（imlib2）|
| `xlunch` | 三架构 | 不行 | 同上（imlib2）|
| `tint2` | 三架构 | arm64 运行闪退、无控制台错误码 | 待专项（arm64；疑 imlib2/面板初始化）|
| `hsetroot` | 三架构 | 未实测（疑同 imlib2）| 同上（imlib2）|

> imlib2 家族 5 组件（feh/scrot/xlunch/tint2/hsetroot）**疑似同一根因（imlib2 loader）**。产物大小：feh 2.68M / scrot 2.58M / xlunch 2.63M / tint2 10.55M / hsetroot 2.55M，均静态。

> **订正（2026-11-28 13:04）**：imlib2 家族根因已锁定并修复，**loader 对象确已编译并注入 `libImlib2.a`（png.o/svg.o/jpeg.o 均在归档内），失效点在 `loaders.c` 注册补丁静默未打**——见 4.2.1。上表「静态未链」的表述需按 4.2.1 细化（非 `--whole-archive` 问题）。

**⑤ gtkmm 家族（两镜像都要满足）**

| 组件 | amd64 | arm64 | armv7 |
|---|---|---|---|
| `pasystray` | 1 bin OK | **0 bin 失败** | **0 bin 失败** |
| `pavucontrol` | 1 bin OK | 1 bin OK | OK |
| `pulseaudio` | 7 bins OK | 11 bins OK | OK |
| `sysmonitor` | 0 bin | 0 bin | 0 bin（无产物，库/未构建待确认）|

> `c_gtkmm=no` 时 dbg 版不建 gtkmm；旧三架构版仍建，pasystray 交叉失败需修。

**⑥ 假警（非故障）**
- `dbus`/`dbus-glib`（arm64/armv7）：产物在 **sysroot**（`/aarch64-alpine-linux-musl/usr/local/static/dbus/bin/dbus-daemon|dbus-launch|dbus-send` + `libdbus-1.a` 2.0M），非 `/rootfs`——`--include=/rootfs` 取不到，实际构建成功
- `exif`/`gtop`/`wnck`（amd64）：库/旧组件，本无 bin，正常

**⑦ 待办（按优先级）**
1. **imlib2 家族**（5 组件三架构）：确认 loader 根因——查 `libImlib2.a` 是否含 png/jpeg/svg loader 对象；静态需 `--whole-archive` 或显式链 loader；X 环境实跑
2. **engrampa**：重写修复——去掉吞错，显式 `xx-apk add musl` + 验证 loader 存在；或绕过 `glib-compile-schemas`（`--disable-schemas`）
3. **pasystray**：gtkmm 交叉链接根因；恢复 `c_gtkmm=yes` 前先修
4. **tint2 arm64 闪退**：Xvnc 实跑抓错（无控制台码，需 gdb/strace/GTK_DEBUG）
5. **suckless**：构建镜像补 `ncurses`（提供 `tic`）或 st 跳过 terminfo install
6. **gtkmm 两镜像**：临时调试 + 正式生产都需满足；`c_gtkmm` 按需开

#### 4.2、问题项修复（2026-11-28 13:04）

> 4.1 待办的逐项落地记录。4.2.1 起为已修复项（suckless / pasystray 见 4.2.2 / 4.2.3）。
> **用户新反馈（2026-11-28 17:06）已定位（2026-11-28 17:44，基于 `alpine-compile-3-dbg` 最新 Nov 28 06:04 产物 undock 核对）**：4.2.5~4.2.9——根因见各节，均未修。

##### 4.2.1、imlib2 家族（feh/scrot/xlunch/tint2/hsetroot）：builtin loader 注册补丁静默失效（2026-11-28 13:04）

**结论**：`compile/src/w-xlunch/build.sh` 的 imlib2 自建函数用 python3 heredoc 给 `loaders.c` 打「内置 loader 注册」补丁，**`python3 - <<'PYEOF'` 单引号分隔符阻止 shell 展开 `$SRCROOT`** → Python 拿到字面字符串 `"$SRCROOT/imlib2/src/lib/loaders.c"` → `open()` 失败 → 补丁静默未打（函数内无 `set -e`，build.sh 继续跑）。

**引入时点**：2026-11-25 交叉适配改造，把硬编码 `/tmp/imlib2` 批量改成 `$SRCROOT/imlib2`（heredoc 之外 30 余处 `$SRCROOT` 均在正常命令行，shell 正常展开，**唯独 heredoc 体内那 1 处失效**）。11-23（硬编码路径）时补丁生效、GUI 验证通过。

**证据链（builder-gmm，`alpine-builder-gtkmm224-3`）**：

| 检查 | 11-23（`6699eb57`） | 11-27 CI（`204cda75`） | 修复后 |
|---|---|---|---|
| `ar t libImlib2.a` | 46 成员 | 含 `png.o`/`svg.o`/`jpeg.o`/`loaders.o`/`ldrs_util.o`/`exif.o`（48 成员） | 同左 |
| `nm loaders.o \| grep png_loader` | 引用存在 | **0（补丁未打）** | `U png_loader`/`U svg_loader`/`U jpeg_loader` |
| `nm libImlib2.a \| grep "D.*_loader"` | 定义存在 | `D png_loader`/`D svg_loader`/`D jpeg_loader`（loader 对象已注入，但无人引用→链接器不拉入） | 同左 |
| 运行 | feh 显示 SVG+PNG OK | `No Imlib2 loader for that file format` | feh `ALIVE`+`NO_LOADER_ERR`+`IMAGE_LOADED` |

> 关键区分：`png.o` 里 `png_loader` 是 **D（定义）**，`loaders.o` 里必须是 **U（未定义引用）**——校验只能 grep `U`，grep `D` 会误判（loader 对象在归档里始终存在）。

**修复（`compile/src/w-xlunch/build.sh`）**：
1. heredoc 改经环境变量传路径——`SRCROOT="$SRCROOT" python3 - <<'PYEOF'` + Python 内 `os.environ['SRCROOT']`。保 heredoc 单引号（**勿改无引号**：Python 体内的 `$` 会被 shell 误展开）。
2. 加 nm 兜底校验——注入后逐个判 `U png_loader`/`svg_loader`/`jpeg_loader`，缺失即 `exit 1`。`oneBuild` 用 `set +e` + `find` + `|tee` 会吞错（报 `err 0, pass`），必须显式判失败。

**验证**：
- 重编（builder-gmm，`CONSOLE_LOG=no` + `TARGETPATH=/usr/local/static/<comp>`）：imlib2 / xlunch / feh 全 pass；feh `statically linked, stripped` 9.8M，`ldd` 报 `Not a valid dynamic program`。
- Xvnc 实跑（hdmi 容器 `:314`，`-SecurityTypes None -ac`，**headless 用户**，fresh display）：

| 用例 | 进程 | loader 错误 | 图片加载 |
|---|---|---|---|
| feh + PNG | ALIVE | 无 | OK（`png.out` 空输出） |
| feh + SVG | ALIVE | 无 | OK（`svg.out` 空输出） |

- 与 11-23（`11170850-selected-app-use.md` §10.2.3）验证特征一致；Xvnc 用完已清（仅剩用户 live `:1`）。
- **已提交**：`5de4beb7`。

**顺带环境补全（非仓库改动）**：builder-gmm 缺 `libXi.a` / `libxcb-util.a`（feh 的 `-lXi`/`-lxcb-util`），经 `sh /src/w-tint2/build.sh libxi` 与 `... xcbutil` 自建补齐——属 w-feh 的 `b_deps`（w-feh `build.sh:81-82`），CI 走 `full` 入口时会建，本地直接 `sh build.sh feh` 会缺。

##### 4.2.2、suckless st：make install 缺 tic（Error 127）（2026-11-28 13:30）

**现象**：三架构 `suckless` 的 st 安装阶段 `make: tic: No such file or directory` → `make: *** [Makefile:53: install] Error 127`。**st 二进制已产出（4.8M，`bin/` 下 st/st-copyout/st-urlhandler 均已 `cp` 完）**——失败点在 install 最末的 terminfo 生成，非编译。

**根因**：st 的 Makefile `install` 目标含 `tic -sx st.info`（把 `st.info` 编译成 terminfo 二进制条目）。`tic` 由 native `ncurses` 包提供，构建镜像未装 → `make` 报 command not found（127）。dwm/dmenu 的 Makefile install 无 tic 步骤，故只有 st 挂。

> **交叉同理需要 native tic**：terminfo 在宿主侧生成，`make install` 从 PATH 取 **native** `tic`（native `tic` 产出的 terminfo 条目对 target arch 通用），**不可**用 `xx-apk` 装（那会把 target arch 的 `tic` 装进 `sysroot/usr/bin`，反而污染）。

**修复**（`compile/src/suckless/build.sh` `st()` 内 `make install` 前）：

```sh
command -v tic >/dev/null 2>&1 || apk add ncurses
```

用 common.sh 的 native `apk`（flock 包装器），**不用 `xx-apk`**；`command -v` 幂等，已装则不重复 apk。

**验证（builder-gmm，native amd64）**：

| 检查 | 结果 |
|---|---|
| 前置模拟 CI（`apk del ncurses`） | `which tic` 空 |
| `sh /src/suckless/build.sh st` | RC=0，3 秒 |
| `make install` 日志 | `tic -sx st.info` → **`7 entries written to /usr/share/terminfo`**，无 Error 127 |
| 产物 | `bin/st` 4.8M `statically linked`；st-copyout / st-urlhandler 在 |
| terminfo 条目 | `/usr/share/terminfo/s/st` + `st-256color` 生成 |

**遗留观察（部署项，非本次构建失败）**：该 st 变体（`br-luke-st`）Makefile 用 `tic -sx`（无 `-o`），terminfo 装到**系统** `/usr/share/terminfo`，`$TARGETPATH/share/terminfo` 下为空 → terminfo 条目不随静态组件一起部署（目标机需自带）。如需随包带，改 Makefile 的 `tic` 调用为 `-o $(PREFIX)/share/terminfo`。

##### 4.2.3、pasystray：交叉缺 -lnotify（cannot find -lnotify）（2026-11-28 13:30）

**现象**：amd64 1 bin OK；arm64/armv7 **0 bin 失败**。日志：`/usr/bin/linux-armv7-ld: cannot find -lnotify: Invalid argument` → `clang-12: error: linker command failed with exit code 1` → `make[2]: *** [Makefile:484: pasystray] Error 1`。

**根因**：`-lnotify` 的静态库只在 sysroot 路径搜（`-L${XX_LIBS_PREFIX}/usr/local/static/pulseaudio/lib`、`.../lib/pulseaudio`、`${XX_LIBS_PREFIX}/usr/local/lib` + 交叉段的 `-L$XX_SYSROOT/usr/lib`），native 无。`libnotify()` 自建函数**本身没问题**——builder-gmm 里 armv7 交叉可正确产出 `libnotify.a`（成员为 `ELF 32-bit LSB relocatable, ARM, EABI5`）。问题在**调用上下文**：`b_deps` 只在单一 arch 上下文跑一次；交叉分支若未在其自身 arch 上下文跑过（或该 sysroot 的 `.a` 被 builder 镜像每架构建栈前的 `xx-clear.sh staticlib` 清过），`libnotify.a` 即缺 → 链 `-lnotify` 失败。amd64 走 native `/usr/lib`（`XX_SYSROOT` 空）命中，故**仅交叉挂**。

- 同 imlib2 教训：**构建脚本不得假定依赖已在同一 arch 上下文构建**。
- 放大因素：`compile/src/Dockerfile` 的 pasystray stage 用 `;` 分隔 `b_deps` 与 `pasystray`，末条 `find …|grep|sort|head -3` 退出码恒为 0 → stage 失败被吞，镜像照常产出（armv7 rootfs 里 `pasystray/` 目录在、`bin/` 空）。

**修复**（`compile/src/v-pasystray/build.sh` `pasystray()` 内、`cd $SRCROOT/pasystray` 之前）：

```sh
[ -f ${XX_SYSROOT:-}/usr/lib/libnotify.a ] || { libnotify || exit 1; }
```

缺失即现场建（小，~30s）；失败显式 `exit 1`，不再靠 `oneBuild` 吞错假成功。须在 `cd` 前调——`libnotify()` 内部 `cd /tmp` 且不自返。

**验证（builder-gmm，TARGETPLATFORM=linux/arm/v7）**：

| 检查 | 结果 |
|---|---|
| 前置 `rm $XX_SYSROOT/usr/lib/libnotify.a` | 确认删除 |
| `sh /src/v-pasystray/build.sh pasystray` | 守卫触发：`Building libnotify (static) 0.8.9` → `xx_meson_crossfix: remapped native /usr -> /armv7-alpine-linux-musleabihf` → `xx_la_fix: 14 .la …` → **`libnotify done`**，`libnotify.a` 重建 169124 B |
| 后续 | `configure: error: Package requirements (libpulse …) were not met` → `PULSECOMMON not found` → **本镜像缺 pulseaudio 交叉栈**（CI 由 `FROM pulseaudio` stage 提供）→ 测试环境限制，非代码问题 |

**待 CI 复核**：arm64/armv7 全量 pasystray 出 bin 需跑一次 CI 确认；本机无法完整复现（无 pulse 交叉栈）。

##### 4.2.4、engrampa：交叉 gschema.valid 经 qemu 缺 loader（Error 255）（2026-11-28 14:02）

**现象**：amd64 1 bin OK；arm64/armv7 **0 bin 失败**。日志：`qemu-arm: Could not open '/lib/ld-musl-armhf.so.1': No such file or directory` → `make[3]: *** [Makefile:918: org.mate.engrampa.gschema.valid] Error 255` → `>>> [aarch64] ENGRAMPA make LINK FAILED`。

**根因（2026-11-28 深挖，推翻旧结论）**：

1. 报错目标是 `%.gschema.valid` 规则（`/usr/share/aclocal/gsettings.m4:45`）：`$(GLIB_COMPILE_SCHEMAS) --strict --dry-run … --schema-file=$<`。
2. 交叉下 `gsettings.m4:28` 的 `PKG_CHECK_VAR([GLIB_COMPILE_SCHEMAS],[gio-2.0],[glib_compile_schemas])` 解析成 **sysroot 里的 ARM 二进制** → make 经 binfmt/qemu 跑它。
3. 该 qemu 调用**未带 `-L $XX_SYSROOT`** → 按字面路径找 `/lib/ld-musl-<arch>.so.1` → loader 不在宿主 → 报「Could not open」。

> **旧修复为何无效（commit `893c7021`，2026-11-27）**：`xx-apk add musl >/dev/null 2>&1 || true` 只把 musl loader **文件**装进 sysroot；qemu 缺的是 `-L` **前缀**，找不到 sysroot 根，文件在也不看。且错误被 `>/dev/null 2>&1 || true` 吞掉，CI 失败无从排查。

**正解**：该规则只做 `--strict --dry-run` **schema 校验**（不生成二进制代码，与目标架构无关）→ 直接用 **native** `glib-compile-schemas`，彻底不走 qemu。`GLIB_COMPILE_SCHEMAS` 由 `gsettings.m4:30` `AC_SUBST` 出，是 Makefile 里的**普通 `=` 变量（非 `override`）→ make 命令行覆盖即生效**。

**修复**（`compile/src/v-engrampa/build.sh`）：

1. `eng_cross()` 内：
   - `export QEMU_LD_PREFIX="$XX_SYSROOT"`——等同 `qemu -L $XX_SYSROOT`，兜底保护 make 里其它可能经 qemu 的 ARM 子进程（如 `gtk-update-icon-cache`）；binfmt 若已带 `-L` 则命令行优先、本变量不生效（无害）。
   - `xx-apk add musl || log "WARN: …"`——loader 文件仍需就位（供带 `-L` 的 qemu 用），但**去掉旧的吞错**，失败要可见。
   - `apk add --no-cache glib`（本镜像已装，幂等）；`XX_GSCHEMAS=$(command -v glib-compile-schemas)`，缺失即 `exit 1`。
   - `XX_MAKE_GSCHEMAS="GLIB_COMPILE_SCHEMAS=$XX_GSCHEMAS"`。
2. `make` 调用追加 `$XX_MAKE_GSCHEMAS`（不加引号）——交叉时展开为 `GLIB_COMPILE_SCHEMAS=/usr/bin/glib-compile-schemas` 单个参数；native 时变量为空、展开后无参，**原路径零影响**。

**验证（2026-11-28 14:20，builder-gmm 实跑 armv7 + arm64）**：

| 检查 | 结果 |
|---|---|
| `sh -n build.sh` | OK |
| `gsettings.m4` 变量名（`/usr/share/aclocal/gsettings.m4:28-30,45`） | `AC_SUBST(GLIB_COMPILE_SCHEMAS)` + 规则确用 `$(GLIB_COMPILE_SCHEMAS)` |
| native `glib-compile-schemas`（builder-gmm） | `/usr/bin/glib-compile-schemas`（glib 2.70.5） |
| make 命令行覆盖语义（mini makefile 实测） | 默认取 Makefile 值；覆盖后取命令行值；变量为空时**无参**、仍取 Makefile 值 |
| **armv7 交叉构建**（`TARGETPLATFORM=linux/arm/v7`） | `BUILD_RC=0`、`err 0, pass`，62s；产物 `ELF 32-bit LSB executable, ARM, EABI5, statically linked, stripped`（10.2M）；`ldd` → `Not a valid dynamic program`；`grep -c "undefined reference\|attempted static link"` = **0** |
| **arm64 交叉构建**（`TARGETPLATFORM=linux/arm64` + per-arch `WS=/tmp/ws-eng-aarch64 WS_LOCK=1`） | `BUILD_RC=0`、`err 0, pass`，61s；产物 `ELF 64-bit LSB executable, ARM aarch64, statically linked, stripped`；同上计数 **0**；`gschemas.compiled` 4224B 正常 |

**因果验证（证明 `XX_MAKE_GSCHEMAS` 生效且在关键路径上）**：

- **打点法**：把 native `/usr/bin/glib-compile-schemas` 换成「打印标记后 exec 真二进制」的 wrapper 重跑 armv7 构建 → 构建日志中 `GEN org.mate.engrampa.gschema.valid` 之后紧接
  `MARKER-NGS-NATIVE args: --strict --dry-run --schema-file=org.mate.engrampa.gschema.xml`
  → make 的 `%.gschema.valid` 规则（`data/Makefile:918`）走 **native 二进制**，不经 qemu。
- **负向对照**：wrapper 换成 `exit 123` stub → `make[3]: *** [Makefile:918: org.mate.engrampa.gschema.valid] Error 123`——确认命令行覆盖被 make 采纳、且该变量确在失败点上。
- wrapper 已还原（47160 B、`--version` = 2.70.5）并复跑 armv7 全量确认仍 pass。

> **订正（2026-11-28 14:20）**：本镜像（builder-gmm / `alpine-builder-gtkmm224-3`）的 native 与 sysroot **`glib-2.0.pc` 均未定义 `glib_compile_schemas` 变量**，configure 已直接解析到 native（`checking for glib-compile-schemas... /usr/bin/glib-compile-schemas`）。即**本机未复现**上文所述的「解析成 sysroot ARM 二进制」路径；`XX_MAKE_GSCHEMAS` 在本镜像是**防御性兜底**——只有当某镜像的 `.pc` 返回 sysroot 路径时才真正救命。CI 各 builder 镜像的 `.pc` 可能不同（`alpine-compile-3` 浮动 tag 亦会变），故保留该覆盖。

> **另（arm64 串行坑，2026-11-28 14:20）**：串行跑（未设 `$WS`）时 `SRCROOT=/tmp`，**两架构共用 `/tmp/engrampa` 源码树**；换 `--host` 不会触发 `.o` 重编 → arm64 必须显式传 per-arch `WS`（如 `WS=/tmp/ws-eng-aarch64 WS_LOCK=1`），否则可能产出混架构产物。CI 并行分支本就按 arch 传 `WS`，无此风险。

**通用教训**：交叉下 make 规则里凡「跑 target 二进制做**纯文本/schema 校验**」的（`%.gschema.valid`），应改指 native 同名工具——既免 qemu 依赖，又快。**注意区分**：`%.gschema.valid` 是 dry-run 校验（可 native）；`make` 期生成 `gschemas.compiled`（build.sh 第 178 行 install-data 后另调 native `glib-compile-schemas`）本就是 native 调用，无需改。

##### 4.2.5、pcmanfm（旧版）：amd64/arm64 产物缺失（已修）（2026-11-28 17:06）

**反馈（用户核对）**：pcmanfm **旧版**在 amd64 与 arm64 **产物缺失**（cross-check01 一节2 `pcmanfm`，备注「旧版有/新优化」）。

**核对（2026-11-28 17:44，`alpine-compile-3-dbg` 最新 Nov 28 06:04 产物）**：amd64 `pcmanfm/bin/pcmanfm` **有**（14M，Nov 28 06:04 编译，`v-pcmanfm` 新构建、locales 54 langs）；arm64 `pcmanfm/bin/` **空**。

**根因**：
1. **旧版（38.9M，2023-12 旧构建）未被拷入镜像**——用户 2026-11-28 17:44 确认「旧版没拷贝到镜像里来」。属正常更替（新版在），**非故障**。
2. **arm64 新版缺失**：构建日志 `13.5M Nov 28 06:04` 编译成功，但 install 装到 **`/aarch64-alpine-linux-musl//usr/local/static/pcmanfm/`（sysroot）**，最终镜像 `/usr/local/static/pcmanfm` 空——交叉产物装到 sysroot 前缀路径，未进最终镜像（与 dbus 同因）。

**状态**：✅ **已修**（2026-11-28 18:47）。

**修复（commit `20b23721`，`compile/src/v-pcmanfm/build.sh`）**：按用户拍板A——交叉下运行时数据（bin/share/locale/ui/libexec/menus）装最终 `$TARGETPATH`（不带 DESTDIR/无 sysroot 前缀），仅 `.a/.pc/头` 装 sysroot（下游 link 用）。
- `pcmanfm()` make install 去 DESTDIR + locale/view/verify 去 sysroot 前缀（bin+share 落 `$TARGETPATH`）；`libfm()` UI/locale 去 sysroot 前缀（库 `.a/.pc/头` 仍 sysroot）；`menu_cache()` lxmenu-data/menu-cached 去 sysroot 前缀。
- native 零影响（`${XX_SYSROOT:-}$TARGETPATH` 在 XX_SYSROOT 空时 == `$TARGETPATH`；`${XX_DESTDIR:-}` 空时 == 无）。
- 交叉验证由 CI push 承担（builder-gmm 无 pcmanfm 链）。

##### 4.2.6、dbus：arm64 产物缺失（已修）（2026-11-28 17:06）

**反馈（用户核对）**：dbus 在 **arm64 产物缺失**（cross-check01 一节2 `dbus`）。

**核对（2026-11-28 17:44）**：arm64 `dbus/` **空**（无 bin）；amd64 `dbus/bin/dbus-daemon` **有**（596K）。

**根因**：arm64 **构建+安装成功**（`.logs/oth/aarch64/dbus164-inst.log` 装到 `/aarch64-alpine-linux-musl//usr/local/static/dbus/`），但最终镜像 `/usr/local/static/dbus` **空**——交叉产物装到 sysroot 前缀路径，未进最终镜像。

**状态**：✅ **已修**（2026-11-28 18:47）。

**修复（commit `1f2ccd94`，`compile/src/x-dbus/build.sh`）**：按用户拍板A——`dbus_1_16_4()` ninja install 去 DESTDIR→工具+数据装最终 `$TARGETPATH`，仅 `.a/.pc/头` 装 sysroot（下游 xfce/ibus 交叉 link，`[ -n "$XX_SYSROOT" ]` 守卫）；`dbus_glib()` bin 工具（dbus-glib-tool/dbus-binding-tool）改装 `$TARGETPATH`，库/`.pc/头` 仍 sysroot。
- native 零影响（XX_SYSROOT 空时 `${XX_SYSROOT:-}$TARGETPATH`==`$TARGETPATH`，sysroot 副本守卫跳过）。
- 交叉验证由 CI push 承担。

##### 4.2.7、xrdp：x64 运行失败（已修）（2026-11-28 17:06）

**反馈（用户核对）**：xrdp 在 **x64 运行失败**（跑不起来）。用户补充（2026-11-28 17:06）：**程序有没有不确定**，反正是跑不起来。

**核对（2026-11-28 17:44）**：amd64 `xrdp/sbin/xrdp` **无**（主程序缺失，bin/ 仅辅助程序 xrdp-dis/keygen 等）；arm64 `xrdp/sbin/xrdp` **有**（3.1M）。

**根因**：amd64 configure `error: please install libssl-dev or openssl-devel`——build.sh 只 `apk add fuse-dev fdk-aac-dev opus-dev lame-dev`，**没装 openssl-dev**（注释「公共库 openssl 已由 u-gtk 统一装」但 u-gtk 只给静态 `.a`，头文件不在）。源码取源正常（`gitclone tar.gz hit: x-xrdp.fk-xrdp-sam-custom`，tarsrc 缓存/gitee）。

**状态**：✅ **已修**（2026-11-28 18:47）。

**修复（commit `5953d4cd`，`compile/src/x-xrdp/build.sh`）**：按问题①模式（TODO2611）——`xrdp()` 本地补 `apk add openssl-dev openssl-libs-static`（dev=configure 检测 libssl-dev 头；libs-static=静态链 libcrypto.a/libssl.a）。
- 实跑（builder-gmm native amd64，b_deps 先跑 fdkaac+libxrandr）：configure 过，`sbin/xrdp` 3.4M + `sbin/xrdp-chansrv` 4.9M + `bin/xrdp-keygen/genkeymap`，xx-verify 通过。xrdp-chansrv 需 libfdk-aac.a（b_deps fdkaac 自建落 `/usr/local/lib`），与 openssl 修复互补。
- cross（xrdp_cross）未动——arm64 已通（sysroot 由 u-gtk 提供 openssl）。

##### 4.2.8、x11vnc：x64 无程序（已修）（2026-11-28 17:06）

**反馈（用户核对）**：x11vnc 在 **x64 无程序**。用户确认（2026-11-28 17:06）：**100% 确定没有程序**。

**核对（2026-11-28 17:44）**：amd64 `x11vnc/bin/x11vnc` **无**；arm64 `x11vnc/bin/x11vnc` **有**（16M）。

**根因**：amd64 configure `C compiler cannot create executables`——`checking for gcc... xx-clang`（**native 构建 CC 泄漏成 xx-clang**，编译测试失败）→ 无 Makefile → `make install: No rule to make target 'install'` → xx-verify FAILED。源码取源正常（`gitclone tar.gz hit: x-x11vnc.fk-libvnc-x11vnc-fix-152`，tarsrc 缓存/gitee）。

**状态**：✅ **已修**（2026-11-28 18:47）。

> **订正（2026-11-28 18:47）**：真根因非「CC 泄漏 xx-clang」——xx-clang 本身正常（native hello 编译 rc=0）。实为 configure `LIBS="$LIBS2"` 含 `-llzo2 -lcrypto -lXtst`，native 缺 `libcrypto.a`（无 openssl-libs-static）+ `libXtst.a`（无 apk 静态包）→ configure link-test 失败；且 native `libvncserver()` 的 `cmake ..` 在源码目录跑→配置父目录（无 CMakeLists.txt）→静默失败→无 `libvncserver.a`→产物动态链。

**修复（commit `8423be05`，`compile/src/x-x11vnc/build.sh`）**：按用户拍板A（TODO2611）——`x11vnc()` 本地补 `apk add openssl-libs-static` + 缺 `libXtst.a` 则自建 `libxtst()`（落 `/usr/local/lib`）；`x11vnc_cross()` 补 `xx-apk add openssl-libs-static`；修 native `libvncserver()`（改 `build/` 外建+手动装 `.a/头/.pc` 到 `/usr`）；LDFLAGS 改显式 if/else（cross=`-L$XX_SYSROOT/usr/lib -L$XX_SYSROOT/usr/local/lib`；native=`-L/usr/local/lib`；均 `-static -Wl,--strip-all`）。
- 原 ternary 默认值前导空格致 native LDFLAGS=`-L/usr/local/lib-static`（粘连、丢 `-static`）→二进制动态；改显式 if/else。
- 实跑（builder-gmm native amd64）：xx-verify 通过，`file`=statically linked, stripped（6.06M）。

##### 4.2.9、misc/tinc：amd64/arm64 产物缺失（已修）（2026-11-28 17:06）

**反馈（用户核对）**：`u-misc` 的 **tinc** 在 amd64 与 arm64 **产物缺失**（cross-check01 一节1 `misc`，备注「su-exec/lrzsz/edge/tinc」）。

**核对（2026-11-28 17:44）**：amd64 `misc/sbin/tincd` **无**（仅 edge/n2n-benchmark/supernode）；arm64 `misc/sbin/tincd` **有**（1.9M）。

**根因**：amd64 configure `error: "lzo libraries not found."`——`tinc()` 只 `apk add texinfo`，**没装 lzo-dev**（build.sh 假定 lzo/openssl 由 u-gtk 统一装，但 u-gtk 只给静态 `.a`，头文件不在）。源码取源正常（`gitclone tar.gz hit: u-misc.fk-tinc-default`，tarsrc 缓存/gitee）。

**状态**：✅ **已修**（2026-11-28 18:47）。

**修复（commit `6d5e5163`，`compile/src/u-misc/build.sh`）**：按问题①模式（用户拍板A TODO2611）——`tinc()` `xx-apk add lzo-dev openssl-dev openssl-libs-static`（configure 需 lzo 头，静态链需 libcrypto.a/libssl.a）。
- 用 `xx-apk` 非 `apk`（用户指示）：native 落 `/usr`、cross 落 sysroot——一条命令双架构通用；`texinfo` 仍 `apk`（构建工具留 build 容器）。
- 实跑（builder-gmm native amd64）：configure 过，`sbin/tincd` 9.9M，xx-verify 通过。

#### 4.3、问题修复项2（2026-11-28 20:18）

##### 4.3.1、pulseaudio：arm64 无程序（已修）（2026-11-28 20:18）

**反馈（用户核对）**：arm64 `pulseaudio` **无程序**（`/usr/local/static/pulseaudio` 空，bin/ 缺失）。

**核对（2026-11-28 20:15）**：undock-dbg（11-28 17:31）arm64 `pulseaudio/` 目录**空**（无 bin/etc/include/lib/share）；amd64 同镜像 `bin/` **完整**（pulseaudio 主程序 + pacat/pacmd/pactl/padsp/pa-info/pamon/paplay/parec/parecord/pasuspender）。

**根因**：`x-pulseaudio/build.sh` `make install ${XX_DESTDIR:-}`——交叉下 `XX_DESTDIR="DESTDIR=$XX_SYSROOT"`（px_cross 62 行）把**全部运行时产物**推入 `$XX_SYSROOT/usr/local/static/pulseaudio`（构建日志 install 路径 `/aarch64-alpine-linux-musl//usr/local/static/pulseaudio/...`），最终镜像 `$TARGETPATH` 空。amd64 正常因 native `XX_DESTDIR` 空。

**状态**：✅ **已修**（2026-11-28 20:18）。

**修复（commit `06b69236`，`compile/src/x-pulseaudio/build.sh`）**：按用户拍板A（同 pcmanfm/dbus 问题③）——`make install` 去 DESTDIR（运行时数据装最终 `$TARGETPATH`）；`.a` 单独 cp 进 sysroot（`cp libpulse*.a ${XX_SYSROOT:-}/usr/lib/`，下行已有）。
- native 零影响（`${XX_DESTDIR:-}` 空时 `make install ${XX_DESTDIR:-}`==`make install`）。
- 交叉验证由 CI push 承担（builder-gmm 无 aarch64 sysroot）。

##### 4.3.2、XX_DESTDIR 交叉产物落点排查——库组件保留/应用组件去 DESTDIR（2026-11-28 20:24）

**背景**：`${XX_DESTDIR:-}` 是方案二交叉全局模式（`make install DESTDIR=$XX_SYSROOT`），影响面大——排查历史引入、使用范围、是否会改坏其他组件。

**引入历史**：2026-11-24 方案二交叉适配统一引入（`f5d407c5`/`b3266f9e`/`f95ae973`/`5034fb7e` 等一批），2026-11-25 扩至 xlunch/tint2/dunst/rofi/xrdp。设计意图：交叉下库/头/.pc 装 sysroot 供下游交叉 link。

**使用范围（12 文件）分两类**：

- **库组件——DESTDIR=sysroot 正确用途，不能改**（改了库不进 sysroot→下游交叉 link 失败）：u-gtkmm(gtkmm 7库)、w-xlunch(imlib2)、v-xfce4(xfce库栈)、x-rofi(xkbcommon)、x-dunst(libxscrnsaver)、x-xrdp(fdkaac)、x-x11vnc(libvncserver)、w-tint2(xcbutil/libxi/libcroco/librsvg)。
- **应用组件——需镜像产物，问题③风险区**：

| 组件 | 本体 install | 状态 |
|---|---|---|
| pcmanfm | 库 make install DESTDIR + 数据手工装 TARGETPATH | ✅ 已修 `bcb780ab` |
| dbus | 改手动 install（免 make install） | ✅ 已修 `da422f3f` |
| pulseaudio | `make install` 去 DESTDIR + 库 cp sysroot | ✅ 已修 `06b69236` |
| gsm | 手工 xx-clang 链 TARGETPATH | 安全（不受 DESTDIR） |
| xlunch | `make install` 无 DESTDIR | 安全 |
| xrdp | `make install` 无 DESTDIR | 安全 |
| rofi | `make install` 无 DESTDIR | 安全 |
| tint2 | 本体交叉未适配（用户暂不处理） | — |

**结论**：`XX_DESTDIR` 本身不是坑——坑只在「应用组件用 `make install ${XX_DESTDIR:-}` 装 DESTDIR」（把 bin 也推 sysroot）。这类应用组件仅 pcmanfm/dbus/pulseaudio 三个，已全部按拍板A修完。库组件 `XX_DESTDIR` 保留（正确用途），一处未动；gsm/xlunch/xrdp/rofi 本体不受影响。

##### 4.3.3、TODO2611 公共库缺口分析——native apkdeps 未对齐 cross 清单（2026-11-28 20:32）

**TODO2611 位置（4 组件 6 处）与所缺库**：

| 组件 | 缺的库 | u-gtk 清单 |
|---|---|---|
| xrdp | openssl（dev+static） | ⚠️ 只在 cross，不在 native |
| tinc | lzo（dev）+openssl（dev+static） | ⚠️ 同 |
| x11vnc | openssl（static）+libXtst（static）+libvncserver（自建） | ⚠️ openssl 同；libXtst 两清单都无 |
| rofi | libxkbcommon（dev+static） | ⚠️ 只在 cross，不在 native |

**根因（两条链路不对称）**：
- cross（arm64）：`b_deps` 尾部 `if [ -n "$XX_CROSS_FILE" ]` 清单（453-465 行）→ `xx-apk` 装 sysroot，含 openssl-dev/openssl-libs-static/lzo-dev/libxkbcommon-\*（461-462 行）——交叉齐。
- native（amd64）：`apkdeps`（388-398 行）→ `apk add` 装宿主，**只装 gtk 相关**，没装 openssl/lzo/libxkbcommon。
- `if [ -n "$XX_CROSS_FILE" ]` 门控清单只 cross 生效；native `apkdeps` 未对齐 → xrdp/tinc/rofi/x11vnc **amd64 缺库** → TODO2611 应用层临时补。

**libXtst 特殊**：libxtst（dev/static）两清单都无（Alpine 无 libxtst-static 包）→ x11vnc 连 cross 也缺，靠 `libxtst()` 自建兜底（`8423be05`）。

**修复方向（用户拍板，两条都做）**：① native `apkdeps` 补 openssl-dev/openssl-libs-static/lzo-dev/libxkbcommon-dev/libxkbcommon-static（对齐 cross 清单）；② libxtst 保留自建兜底（无 apk 静态包）。

**libXtst 复用决策（用户拍板，方案A，2026-11-28 20:56）**：libXtst 不只 x11vnc 用——v-clipit 的 **xdotool** 也用（`-lXtst`，自动粘贴）。Alpine 无 libxtst-static 包，不进公共库清单，留组件兜底。方案A：v-clipit `libxtst()` 复用 x11vnc 的（`bash /src/x-x11vnc/build.sh libxtst`，落 `/usr/local/lib`，gitee 1.2.3），去 v-clipit 原自建（x.org 1.2.4 落 `/usr/lib`）重复；xdotool `LDFLAGS` 加 `-L${XX_LIBS_PREFIX:-}/usr/local/lib`（native `/usr/local/lib`、cross sysroot）找到 libXtst.a。
