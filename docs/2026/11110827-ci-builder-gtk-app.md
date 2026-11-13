# 应用调试 + CI实跑验证（拆出自 11091127-ci-builder-gtk.md）

> 来源：2026-11-13 从 `docs/2026/11091127-ci-builder-gtk.md` 拆出（原文档过大）。四、五两章保留原章节序号与层级迁入本文件；原文档相应位置已注明去向。

## 章节表

- 四、应用调试（抽取：原 3.4 + 3.5）
  - 1、gtkmm 下游应用缺失清单（pavucontrol / gnome-system-monitor）
  - 2、pulse 栈当时怎么搞的（awe 容器 + 历史文档回顾）
  - 3、pulse 栈项目内版本落地与应用调试
  - 4、容器网络排查明细：bridge NAT 与 iptables 双后端（4.1-4.5，builder-pav，2026-11-12）
  - 5、xfce4 构建最终结果（thunar / ristretto / display-settings 均验证通过，5.1-5.2，2026-11-12）
  - 6、pasystray 构建收口（照 Dockerfile 调用方式，6.1-6.4，2026-11-12）
  - 7、lxtask + pcmanfm 构建收口（照 Dockerfile 调用方式，7.1-7.4，2026-11-12）
- 五、CI实跑验证（2026-11-12~13）
  - 1、镜像 alpine-compile-2-dbg 核查（回复原文）
  - 2、镜像二次分析（2.1 远端更新/编译结果 + 2.2 三失败 gpicview/engrampa/lxappearance 日志与修复，2026-11-13）
  - 3、镜像三次分析（3.1 远端又更新/4 空组件 feh/scrot/tint2/pcmanfm 根因，2026-11-13）
- 六、xfce4 源码包收集与下载源（2026-11-13）
  - 1、源码包清单与来源（/_ext/x11base_tar_src/xfce4）
  - 2、全仓下载/克隆源统计（compile/ 下，gitee=已处理）
  - 3、源码包下载落地清单（组件目录+大小汇总）

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

#### 4.1、现象与初判

- `curl` / `wget` 下载超时，`apt-get` 无法连接镜像源。
- 宿主机网络正常，容器内 `ping` 公网 DNS 通但 HTTP 不通。
- 初判为 iptables NAT 规则缺失：`docker0` 是 bridge 网络，容器出站必须经宿主机 `FORWARD` + `POSTROUTING` MASQUERADE。

#### 4.2、关键误判：iptables 双后端（nft vs legacy）

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

#### 4.3、逐层诊断法（本次验证有效）

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

#### 4.4、实际结论：网络是瞬态故障，bridge NAT 无问题

排查推进到最后，发现：

```bash
# 容器内
echo > /dev/tcp/8.8.8.8/443 && echo "TCP OK"     # 通
curl -v https://www.google.com 2>&1 | grep "SSL connection"  # TLS 握手成功
curl -o /dev/null -w '%{http_code}' https://dl.xfce.org/...     # 200/404 均有响应
```

**结论：bridge NAT 规则一直存在且工作正常，之前不通是瞬态网络退化**（DNS 解析成功但 TCP 三次握手失败 / 上游路由抖动），重启或等待即恢复，**不是 iptables 配置问题**。

> 教训：网络不通时先用 `ip route get` 验证 NAT 路径，再 `nc -vz` 逐跳测试，最后才怀疑 iptables。盲目往 iptables 加规则只会污染规则链（尤其双后端环境）。

#### 4.5、busybox 容器内网络诊断的两个坑（本次踩到）

1. **`sh` 不支持 `/dev/tcp`**：`echo > /dev/tcp/8.8.8.8/443` 报 `nonexistent directory`，是 busybox `sh` 无此实现，**不代表网络不通**。TCP 测试要用 `curl` / `nc`。
2. **长耗时 `docker exec` 触发 host 侧输出截断**：`nc -zv`、`curl` 等待类命令常表现为"整段无输出"，极易误判为卡死/不通。解法：命令输出重定向到容器内文件，再单独 `cat` 读；或后台 `&` 跑。
   实测 `curl http://archive.xfce.org/` → `code=301`，**网络实际是通的**（301 为该站正常重定向）。

### 5、xfce4 构建最终结果（2026-11-12 完成，thunar / ristretto / display-settings 均验证通过）

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

##### 5.1、两处脚本修复

**（1）`xfce_lib` 闸门放宽**（`compile/src/v-xfce4/build.sh:298` 附近）

xfce 包常含 daemon（xfconfd / xfce4ui），其链接需额外符号；原逻辑 `make` / `make install` 失败即 `exit 1`，会把仅需库本身的构建整个中断。改为 make/install 失败仅 WARN，**真正闸门只保留 `test -f $PREFIX/lib/$CHECK`**（`.a` 存在性）。实测 libxfce4ui / exo / garcon 均出现 MAKE WARN 后仍 `installed`。

**（2）LIBS 去掉 `-lXi -lSM -lICE`**（`static_gtk_libs` 与 xfce4settings 两份 LIBS 共 4 行）

Alpine 的 `libice-dev` / `libxi-dev` **不含 `.a`**（仅运行时 `.so`），静态链接报 `cannot find -lXi` / `-lICE`。实测三者均无符号被引用，直接不链即可，链接即通过。

##### 5.2、日志里"看似失败"的红鲱鱼

`build.sh:212` 的 `make -C thunar` 是**故意允许失败**的（脚本注释明写 "CCLD failed (expected, objects built)"，只用它产出的 `.o`）。该步 stderr 里大量 `undefined reference to pcre_* / pixman_*` 属于动态链 libglib 的传递依赖，**与最终静态链接无关**，勿据此判断静态链失败。真错误要看 `build.sh:229` 静态链一行。
### 6、pasystray 构建收口（2026-11-12，builder-pav，照 Dockerfile 调用方式）

#### 6.1、调用方式

照 `compile/src/Dockerfile:464-472` 原样（`FROM pulseaudio AS pasystray` 继承 pulse 栈；
builder-pav 容器里的等价物是它已有的 `/usr/local/static/pulseaudio/`，故无需重建阶段）：

```sh
mkdir -p /usr/local/static/pasystray
export CONSOLE_LOG=no TARGETPATH=/usr/local/static/pasystray
sh /src/v-pasystray/build.sh b_deps        # → B_DEPS_EXIT=0
sh /src/v-pasystray/build.sh pasystray     # → PASY_EXIT=0
```

`CONSOLE_LOG=no` 按 AGENTS §3：脚本内 `exit 1` 可传出；`TARGETPATH` 由调用方传入
（AGENTS §3.2，勿在 build.sh 硬编码）。

#### 6.2、根因：`libpulsecommon` 的 soname 版本写错（`-13.0` → 应为 `-13.99`）

- `vers.txt:22` 钉的 pulseaudio 分支是 `br-v13-99-3` → soname **13.99**，实际产物
  `/usr/local/static/pulseaudio/lib/pulseaudio/libpulsecommon-13.99.a`。
- `v-pasystray/build.sh` 两处硬编码 `-13.0`：`:72` 静态链 LIBS、`:114` `b_deps` 的 `ls` 检查。

**两个失败同源**：

| 失败点 | 表现 |
|---|---|
| `b_deps` 的 `ls` 检查（`:114`） | 路径不存在，`set -e` 下 `B_DEPS_EXIT=1` |
| 静态链（`:72`） | `undefined reference to pa_log_level_meta` / `pa_init_i18n`——正是 libpulsecommon 的符号 |

改 `-13.99` 后一次通过。

#### 6.3、验证（不采信 `oneBuild` 的 `err 0, pass`）

| 项 | 结果 |
|---|---|
| `xx-verify --static` | rc=**0** |
| `nm \| grep -c " U "` | **0** 未定义符号 |
| 二进制 | 12.7MB |
| 产物 4 件 | `bin/pasystray`、`applications/pasystray.desktop`、`locale/zh_CN/.../pasystray.mo`、`pasystray/pasystray.gtk2.glade` |

#### 6.4、本轮顺带订正的两处环境误判

| 误判 | 实际 |
|---|---|
| 容器名 `xm-zs01-builder-x11` | **只有 `builder-pav`**（误建的同名容器已删） |
| xfce4 的 xfconf「失败、`.a` 未产出」 | `libxfconf-0.a` 早已存在，xfconf 本就通过了 |

### 7、lxtask + pcmanfm 构建收口（照 Dockerfile 调用方式，2026-11-12，builder-pav）

#### 7.1、调用方式（参考 Dockerfile lxde / pcmanfm stage）

| 组件 | Dockerfile stage | `ENV` | 调用 |
|---|---|---|---|
| lxtask | `FROM base AS lxde`（352-366） | `CONSOLE_LOG=no`<br>`TARGETPATH=/usr/local/static/lxde` | `sh /src/v-lxde/build.sh lxtask` |
| pcmanfm | `FROM base AS pcmanfm`（368-380） | `CONSOLE_LOG=no`<br>`TARGETPATH=/usr/local/static/pcmanfm` | `bash /src/v-pcmanfm/build.sh b_deps`<br>`bash /src/v-pcmanfm/build.sh pcmanfm` |

builder-pav（`alpine-builder-gtkmm224-2`，与 Dockerfile `base` 同镜像）内 `/src` 已软链宿主 `compile/src`，照 stage 的环境变量在容器内执行即可复现。

#### 7.2、源码获取：GITHUB 覆盖（hub.njuu.cf 不可达）

- **容器内网络实测**：`gitee.com` **可达**（`g-system/fk-libfm`、`g-system/fk-menu-cache` 直连 clone OK）；`hub.njuu.cf` **不可达**（`git ls-remote` rc=128）；`github.com` 直连 clone **失败**（`Failure when receiving data from the peer`）→ 用 **ghfast.top 前缀代理**。
- **lxtask 可换源不改脚本**：`common.sh:20` 是**条件导出**（`test -z "$GITHUB" && export GITHUB=https://github.com`）→ 容器内直接 `export GITHUB=https://ghfast.top/https://github.com` 即可。
- **pcmanfm 须改脚本位置**：`v-pcmanfm/build.sh` 尾部 `export GITHUB=https://hub.njuu.cf`（282 行）**位于 `exit 0`（275 行）之后 → 永不执行**，实际克隆源取 common.sh 默认 `github.com`；调试期把覆盖行插到脚本开头 `source /src/common.sh` **之后**（4 行）才生效。
- ghfast.top 前缀代理对 `lxde/lxtask`、`lxde/pcmanfm` 均可用（`git ls-remote` rc=0，pcmanfm 1.3.1 tag 在）。**待办**：作者后续把源转存 gitee，届时改 `vers.txt` / `build.sh` 的克隆源。

#### 7.3、结果与验证（独立兜底，不信 `err 0, pass`）

| 组件 | 产物 | `file` | `ldd` | `xx-verify --static` | 日志 miss |
|---|---|---|---|---|---|
| lxtask | `/usr/local/static/lxde/bin/lxtask` **11.6M** | statically linked, stripped | Not a valid dynamic program | **PASS** | 0 |
| pcmanfm | `/usr/local/static/pcmanfm/bin/pcmanfm` **12.5M** | statically linked, stripped | Not a valid dynamic program | **PASS** | 0 |

- b_deps 产物齐备：`/usr/local/lib/libfm.a`（554K）、`libfm-gtk.a`（786K）、`libfm-extra.a`（25K）、`/usr/lib/libmenu-cache.a`（37K）。
- 日志兜底口径：`grep -acE "undefined reference|attempted static link|cannot find"` = **0**。
- pcmanfm 日志尾段计时 22 秒（2 核）；安装文件 11 个（bin/ui/desktop/man 齐全）。

#### 7.4、避坑项（本次新增）

- **脚本内 `export` 的位置决定它是否执行**：`v-pcmanfm/build.sh` 的 `export GITHUB=...` 在 `exit 0` 之后的尾部注释区 → 永不执行；改克隆源必须插到 `source /src/common.sh` 之后、首个 clone 之前。第一次构建失败即此因。
- **pcmanfm 克隆失败的表象是"源码缺失"**：clone 失败后脚本仍继续（`cd /tmp/pcmanfm` 报 `No such file or directory`、`./autogen.sh`/`./configure` 均 `No such file`），到 `make` 阶段才报 `PCMANFM build FAILED` → **日志前段 `fatal: unable to access` 才是真因**。
- lxtask 与 pcmanfm 换源方式不同：前者可用环境变量覆盖（common.sh 条件导出），后者须改脚本内 export 位置。
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

## 六、xfce4 源码包收集与下载源（2026-11-13）

### 1、源码包清单与来源（`/_ext/x11base_tar_src/xfce4`）

**背景**：CI 跑 xfce4 stage 失败——`TARBALL EXTRACT FAILED: Thunar-1.6.3` / `libexif-0.6.23`（`.cache` 无 tarball、下载源不可达）。翻本地缓存确认：解压源码**有编译污染**（`/tmp/xfce-build` 262 个 `.o` + 已生成 Makefile），不能当干净源码；**干净源码包 = 原始 tarball**。

**命名规范**：`名字-版本.tar.gz|bz2`（参考 `Thunar-1.6.3.tar.bz2`）。本地两个只有版本号的包已改名：`0.8.2.tar.gz`→**`pasystray-0.8.2.tar.gz`**、`v3.0.tar.gz`→**`pavucontrol-3.0.tar.gz`**。

**下载源（实测可达）**：
- **archive.xfce.org**：需带浏览器 UA（`Mozilla/5.0`），否则可能下到空文件（官方默认拒无 UA 的 curl/wget）。
- **github.com/libexif/libexif/releases/download/v0.6.23/**：直连 200 可达。

**清单（12 个干净源码包，`/_ext/x11base_tar_src/xfce4`）**：

| 包 | 大小 | 来源 |
|---|---|---|
| `Thunar-1.6.3.tar.bz2` | 1.98M | builder-awe `.cache`（已有） |
| `ristretto-0.8.5.tar.bz2` | 584K | archive.xfce.org 下载 |
| `xfce4-settings-4.12.4.tar.bz2` | 1.04M | archive.xfce.org 下载 |
| `exo-0.10.6.tar.bz2` | 1.28M | archive.xfce.org 下载 |
| `libxfce4ui-4.12.1.tar.bz2` | 666K | archive.xfce.org 下载 |
| `libxfce4util-4.12.1.tar.bz2` | 455K | builder-pav `.cache`（已有） |
| `garcon-0.4.0.tar.bz2` | 466K | archive.xfce.org 下载 |
| `xfconf-4.12.1.tar.bz2` | 564K | builder-pav `.cache`（已有） |
| `dbus-glib-0.112.tar.gz` | 715K | builder-pav `.cache`（已有） |
| `libexif-0.6.23.tar.bz2` | 1.46M | github libexif releases |
| `pasystray-0.8.2.tar.gz` | 60K | builder-pav `.cache`（改名） |
| `pavucontrol-3.0.tar.gz` | 133K | builder-pav `.cache`（改名） |

**关键结论**：宿主机环境能下载（archive.xfce.org 带 UA / github 直连 200），**CI 容器/受限环境不能**（CI 之前失败、用户下到空文件，均是容器网络到 archive/github 不通）。要让 CI 用，需把这 12 个 `COPY` 进镜像 `.cache/`（=`$TARGETPATH/../.cache`）或容器，供 `fetch_src` 的 `test -s $TARBALL` 命中、免下载。

### 2、全仓下载/克隆源统计（`compile/` 下，2026-11-13，gitee=已处理）

**规则**：gitee（`g-system`/`infrastlabs`）= 已处理过的源；非 gitee = 潜在问题源（CI 网络到 github/官方不可达）。`$GITHUB` 默认 `https://github.com`（common.sh:20，可环境覆盖）。统计：git clone 55 处 + tarball 下载 26 个字面 URL。

**① 克隆（git clone，含 branch 版本）**

**✅ 已处理（gitee）**：

| 组件 | 源（gitee.com） | 版本 |
|---|---|---|
| u-gtk atk / gdk-pixbuf / gtk / murrine | `g-system/fk-atk` / `fk-gdk-pixbuf` / `fk-gtk` / `fk-murrine` | ATK_2_36_0 / 2.42.8 / 2.24.33 / — |
| w-tint2 libcroco / librsvg / xcb-util / libxi / tint2 | `g-system/fk-libcroco` / `fk-librsvg` / `fk-xcb__util` / `fk-libxi` / `fk-tint2` | 0.6.13 / 2.40.21 / — / — / 16.1 |
| w-feh / w-xlunch / w-hsetroot | `g-system/fk-feh` / `fk-xlunch` / `fk-hsetroot` | master / 0.8.4 / 1.0.5 |
| x-pulseaudio pulseaudio | `g-system/fk-pulseaudio` | br-v13-99-3 |
| v-geany | `g-system/fk-geany` | 1.34.0 |
| x-dropbear dropbear | `g-system/fk-dropbear` | DROPBEAR_2024.86 |
| v-pcmanfm libfm / menu-cache | `g-system/fk-libfm` / `fk-menu-cache` | — |
| x-x11vnc libvnc / libxtst / x11vnc | `g-system/fk-libvnc-libvncserver` / `fk-xorg-libxtst` / `fk-libvnc-x11vnc` | LibVNCServer-0.9.13 / libXtst-1.2.3 / fix-152 |
| xcompmgr / fluxbox | `g-system/fk-xcompmgr` / `fk-fluxbox` | master |
| x-xrdp / xperp | `g-system/fk-xrdp` / `infrastlabs/fk-perp` | sam-custom / master-cust |
| u-misc su-exec / lrzsz / n2n / tinc | `g-system/fk-su-exec` / `fk-lrzsz` / `fk-lucktu-n2n` / `fk-tinc` | master / lucktu-new2 / master-v1.0 |
| suckless st | `g-system/fk-suckless-st` | br-luke-st |

**⚠️ 非 gitee（`$GITHUB`=github 或硬编码代理）**：

| 组件 | 源 | 版本 |
|---|---|---|
| v-engrampa | `github.com/mate-desktop/engrampa` | v1.14.1 |
| v-lxde lxappearance / lxtask | `github.com/lxde/lxappearance` / `lxde/lxtask` | master |
| v-ibus glog / leveldb / yaml-cpp / marisa-trie / OpenCC / librime / ibus / ibus-rime | `github.com/google/glog` / `google/leveldb` / `jbeder/yaml-cpp` / `s-yata/marisa-trie` / `BYVoid/OpenCC` / `rime/librime` / `ibus/ibus` / `rime/ibus-rime` | v0.6.0 / v1.20 / 0.8.0 / v0.2.6 / ver.1.1.9 / 1.9.0 / 1.5.35 / 1.6.1 |
| x-dropbear libxcrypt | `github.com/besser82/libxcrypt` | v4.4.28 |
| x-pulseaudio ogg / flac / vorbis / opus / libsndfile | `github.com/xiph/ogg` / `xiph/flac` / `xiph/vorbis` / `xiph/opus` / `libsndfile/libsndfile` | v1.3.5 / 1.3.4 / v1.3.7 / v1.3.1 / 1.0.31 |
| v-pcmanfm pcmanfm | `github.com/lxde/pcmanfm` | 1.3.1 |
| suckless dwm / dmenu | `git://git.suckless.org/dwm` / `dmenu` | 6.2 / 5.0 |
| w-scrot | `ghfast.top/https://github.com/resurrecting-open-source-projects/scrot` | 1.12.1 |
| dropbear（vers.txt） | `github.com/mkj/dropbear` | master |
| geany / lxde / tint2 / pcmanfm（vers.txt） | `$GITHUB/...`（脚本内已改 gitee，vers.txt 未同步） | 见上 |

**② 源码包下载（tarball，26 个字面 URL，全部非 gitee）**：

| 组件 | 完整 URL | 域名 |
|---|---|---|
| xfce4-settings 4.12.4 | `archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-4.12.4.tar.bz2` | xfce |
| Thunar 1.6.3 | `archive.xfce.org/src/xfce/thunar/1.6/Thunar-1.6.3.tar.bz2` | xfce |
| ristretto 0.8.5 | `archive.xfce.org/src/apps/ristretto/0.8/ristretto-0.8.5.tar.bz2` | xfce |
| exo 0.10.6 | `archive.xfce.org/src/xfce/exo/0.10/exo-0.10.6.tar.bz2` | xfce |
| libxfce4ui 4.12.1 | `archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2` | xfce |
| libxfce4util 4.12.1 | `archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2` | xfce |
| garcon 0.4.0 | `archive.xfce.org/src/xfce/garcon/0.4/garcon-0.4.0.tar.bz2` | xfce |
| xfconf 4.12.1 | `archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2` | xfce |
| libexif 0.6.23 | `github.com/libexif/libexif/releases/download/v0.6.23/libexif-0.6.23.tar.bz2` | github |
| dbus 1.12.26 | `dbus.freedesktop.org/releases/dbus/dbus-1.12.26.tar.gz` | dbus |
| dbus-glib 0.112 | `dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.112.tar.gz` | dbus |
| gnome-system-monitor 2.28.2 | `download.gnome.org/sources/gnome-system-monitor/2.28/gnome-system-monitor-2.28.2.tar.bz2` | gnome |
| xbindkeys 1.8.7 | `www.nongnu.org/xbindkeys/xbindkeys-1.8.7.tar.gz` | nongnu |
| xrandr 1.5.4 | `www.x.org/releases/individual/app/xrandr-1.5.4.tar.gz` | x.org |
| openbox 3.6.1 | `openbox.org/dist/openbox/openbox-3.6.1.tar.xz` | openbox |
| tigervnc | `github.com/TigerVNC/tigervnc/archive/v1.13.1-1.20.14.tar.gz` | github |
| pasystray 0.8.2 | `github.com/christophgysin/pasystray/archive/refs/tags/0.8.2.tar.gz` | github |
| gpicview 0.2.5 | `codeload.github.com/lxde/gpicview/tar.gz/refs/tags/0.2.5` | github |
| dunst 1.13.2 | `github.com/dunst-project/dunst/archive/refs/tags/v1.13.2.tar.gz` | github |
| rofi 2.0.0 | `github.com/davatorium/rofi/archive/refs/tags/2.0.0.tar.gz` | github |
| xcb-util-xrm 1.0 | `github.com/Airblader/xcb-util-xrm/releases/download/v1.0/xcb-util-xrm-1.0.tar.gz` | github |
| libgwater / libnkutils | `github.com/sardemff7/libgwater` / `libnkutils`（master） | github |
| imlib2 1.7.4 / loaders | `master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz`（`_loaders`） | sf |
| imlib2 1.12.2 / loaders | `nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz`（`_loaders`） | sf |
| librsvg 2.5.0 | `sourceforge.net/projects/librsvg/files/librsvg/2.5.0/librsvg-2.5.0.tar.gz` | sf |
| libcroco 0.6.13 | `mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz` | ossplanet |
| startup-notification 0.12 | `www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz` | freedesktop |
| xcb-util-cursor 0.1.6 / image 0.4.1 / keysyms 0.4.1 / renderutil 0.3.10 / wm 0.4.2 | `xorg.freedesktop.org/archive/individual/lib/xcb-util-{cursor,image,keysyms,renderutil,wm}-<ver>.tar.gz` | x.org |
| st 0.8.4 / fluxbox 0.8.4 | `dl.suckless.org/st/st-0.8.4.tar.gz` / `dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz` | suckless |

**③ 结论**：tarball 下载源**几乎全部非 gitee 官方**（xfce/gnome/x.org/sourceforge/github/dbus），CI 网络不通时全挂；克隆源大部分已 gitee，但仍有 ~20 处 `$GITHUB`（默认 github）+ 硬编码代理（hub.*、git.suckless.org）。修复方向：换源（gitee/ghfast）或**本地缓存 COPY 进镜像 `.cache/`**（如 1 节 xfce4 12 包做法）。

**清单修正（2026-11-13 下载核对）**：`tigervnc`（实际 `gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/tigervnc-1.13.1.tar.gz`）、`st`（fk-suckless-st）、`fluxbox`（fk-fluxbox）、`libcroco`（fk-libcroco）均为 **gitee 源（已处理）**，非 tarball 下载，从 ② 非 gitee 清单移除。

### 3、源码包下载落地清单（`/_ext/x11base_tar_src/<组件>/`，2026-11-13）

> **订正（2026-11-13 归位后）**：`/_ext/x11base_tar_src` 源码包缓存已按 `compile/src/` 组件目录名**重新组织**——库包全部归到**下载/构建它的组件**下（不再按库名/混合 `xfce4/` 收集目录），最终 **13 组件目录 31 个源码包**（`openbox`(1)/`suckless`(1)/`v-xfce4`(9)/`x-rofi`(10)/`x-dbus`(2)/`w-xlunch`(1)/`v-sysmonitor`(1)/`v-gpicview`(1)/`v-pasystray`(1)/`v-pavucontrol`(1)/`x-dunst`(1)/`x-xbindkeys`(1)/`x-xrandr`(1)）；并**已推送到独立 git 仓库** `http://sam-dev.local:3000/g-dev1/x11base-tarsrc`（分支 `main`，HEAD `15b3979`，工作区干净）。新结构清单见该仓库 `README.md`。下方旧表（30 组件目录 + `xfce4/` 混合）已过时，仅供历史参考。

**下载方法**：curl 直连（archive.xfce.org / github 直连 200 / dbus / gnome / x.org / openbox / suckless / freedesktop）+ github 用 `ghfast.top` 前缀代理（`curl -k`）。**包名统一 `名字-版本.tar.gz|bz2|xz`**——本地原先仅版本号的已按此调整：`0.8.2.tar.gz`→`pasystray-0.8.2.tar.gz`、`v3.0.tar.gz`→`pavucontrol-3.0.tar.gz`；现全库无「只有版本号」的包名。

**按组件汇总（30 组件目录 ≈ 23.8M + xfce4/ 混合 9.2M = 总计 33M）**：

| 组件 | 包 | 大小 |
|---|---|---|
| dbus | dbus-1.12.26.tar.gz | 2071K |
| dbus-glib | dbus-glib-0.112.tar.gz | 699K |
| dunst | dunst-1.13.2.tar.gz | 4576K |
| exo | exo-0.10.6.tar.bz2 | 1246K |
| garcon | garcon-0.4.0.tar.bz2 | 455K |
| gnome-system-monitor | gnome-system-monitor-2.28.2.tar.bz2 | 2375K |
| gpicview | gpicview-0.2.5.tar.gz | 161K |
| imlib2 | imlib2-1.7.4.tar.gz | 1018K |
| libexif | libexif-0.6.23.tar.bz2 | 1919K |
| libgwater | libgwater-master.tar.gz | 11K |
| libnkutils | libnkutils-master.tar.gz | 65K |
| libxfce4ui | libxfce4ui-4.12.1.tar.bz2 | 650K |
| libxfce4util | libxfce4util-4.12.1.tar.bz2 | 445K |
| openbox | openbox-3.6.1.tar.xz | 644K |
| pasystray | pasystray-0.8.2.tar.gz | 58K |
| ristretto | ristretto-0.8.5.tar.bz2 | 570K |
| rofi | rofi-2.0.0.tar.gz | 696K |
| st | st-0.8.4.tar.gz | 46K |
| startup-notification | startup-notification-0.12.tar.gz | 347K |
| thunar | Thunar-1.6.3.tar.bz2 | 1937K |
| xbindkeys | xbindkeys-1.8.7.tar.gz | 173K |
| xcb-util-cursor | xcb-util-cursor-0.1.6.tar.gz | 397K |
| xcb-util-image | xcb-util-image-0.4.1.tar.gz | 418K |
| xcb-util-keysyms | xcb-util-keysyms-0.4.1.tar.gz | 376K |
| xcb-util-renderutil | xcb-util-renderutil-0.3.10.tar.gz | 378K |
| xcb-util-wm | xcb-util-wm-0.4.2.tar.gz | 416K |
| xcb-util-xrm | xcb-util-xrm-1.0.tar.gz | 393K |
| xfce4-settings | xfce4-settings-4.12.4.tar.bz2 | 1013K |
| xfconf | xfconf-4.12.1.tar.bz2 | 551K |
| xrandr | xrandr-1.5.4.tar.gz | 234K |
| xfce4（混合收集目录） | 12 包（含已复制到组件目录的副本） | 9177K |

**imlib2 缺口已解决（2026-11-13）**：`imlib2-1.7.4.tar.gz`（1018K）从**本地 aliyun 镜像 `alpine-compile-2-dbg`（ID 5de6c26bab43）的 `/rootfs/usr/local/static/.cache/`** 提取（该镜像曾跑 w-xlunch imlib2 构建，`down_catfile` 缓存保留 tarball），已落 `/_ext/x11base_tar_src/imlib2/`。

**`imlib2_loaders-1.7.4.tar.gz` 不需要额外包（2026-11-13 复核确认）**，依据：
- **新旧 build.sh 都只下载 imlib2 本体**：当前 `w-xlunch/build.sh:35` `down_catfile ${IMLIB2_URL}`（IMLIB2_URL 仅 `imlib2-1.7.4.tar.gz`）；旧版 `v-xlunch/build.sh:30` 同。`imlib2_loaders` URL 在 `w-xlunch/build.sh:15/:18/:26`、旧版 `:11/:14/:21` **全是注释**，从未真正下载。
- **实际 loader 来自 imlib2 源码自带模块**：`imlib2-1.7.4.tar.gz` 内含 `src/modules/loaders/loader_png.c`、`loader_jpeg.c`（及 gif/tiff/bmp/webp 等）；**svg 上游无**（包内无 `loader_svg.c`）。
- **svg loader 靠 patch 手写**：`w-xlunch/loader_svg.c`（librsvg→cairo ARGB32，87 行）+ `build.sh:55-119` python 幂等补 `src/lib/loaders.c` 注入内置块（跳过 dlopen）→ `build.sh:120-139` 编译 png/jpeg/svg `.o` 进**私有** `libImlib2.a`。
- **`imlib2_loaders` 独立包无 svg**：`docs/2026/11051001-xlunch.md:12` ——"imlib2 1.7.4 的 imlib2_loaders 只有 ani/eet/xcf，**无 svg loader** → 必须手写"。下载它无助于图标（xlunch 用 png/svg/jpeg），反而没有 svg。

> **注**：sourceforge 直连仍被拦（master.dl/nchc.dl 等 0-2 字节）、github `enlightenment/imlib2` tag 404——本包靠镜像缓存绕过，后续重建镜像/换机需留意该缓存源。


### 4、tarsrc 仓库接入方案（gitee `infrastlabs/x11base-tarsrc` 源码包，2026-11-13 分析；4.2 起已实施）

#### 4.1、接入点与实现思路

##### 4.1.1、现状调用链（接入点为什么选 down_catfile）

- `common.sh:28` **`down_catfile`**：全局下载函数——`CACHE=$TARGETPATH/../.cache`；`test -s $CACHE/$file || curl ... > $CACHE/$file`。
- `v-xfce4/build.sh:39` **`fetch_src`**：局部函数，缓存规范化名 `$name.tar.bz2` 到 `.cache`，**底层调 `down_catfile`**（:46）。
- 其余所有组件（gpicview/pavucontrol/dbus…）直接调 `down_catfile`。
- **结论：改 `down_catfile` 一处即可覆盖 xfce4 + 全项目；xfce4 的 `fetch_src` 无需单独改**（它透传 down_catfile）。

##### 4.1.2、实现逻辑（要求 1+2+3）

```sh
function down_catfile(){
  CACHE=$TARGETPATH/../.cache; mkdir -p $CACHE
  url=$1; fname=$(basename ${url%%\?*})                # 去 query 取文件名
  comp=$(basename $TARGETPATH)                          # xxx（如 xfce4/gpicview）
  TARSRC=${TARSRC:-/src/../tarsrc}                      # 宿主项目根/tarsrc（/src 软链透传，见 4.1.4）
  # ① 要求1：仓库不存在 → depth1 克隆（gitee 容器可达，lxtask 先例）
  test -d $TARSRC/.git || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc $TARSRC
  TARSRC_COMP=$(ls -d $TARSRC/*${comp}/ 2>/dev/null | head -1)   # 方案2a 组件目录（见 4.1.3）
  test -n "$TARSRC_COMP" || TARSRC_COMP=$TARSRC
  # ② 要求2：tarsrc 有包优先（精确名 → 版本模糊兜底）
  if test -s $TARSRC_COMP/$fname; then
    cp $TARSRC_COMP/$fname $CACHE/$fname
  else
    ver=${fname#v}; ver=${ver%.tar.*}                    # github archive 版本号名兜底
    hit=$(ls $TARSRC_COMP/*$ver* 2>/dev/null | head -1)
    test -n "$hit" && cp "$hit" $CACHE/$fname
  fi
  # ② 无则源头下载
  test -s $CACHE/$fname || curl -# -k -fSL $url > $CACHE/$fname
  cat $CACHE/$fname
}
```

##### 4.1.3、组件名映射（方案 2a：TARGETPATH basename → ls -d *xxx/）

- **不可行**：`basename $TARGETPATH` 直接当 tarsrc 目录名——`/usr/local/static/xfce4`（无前缀）vs tarsrc `v-xfce4`（带 `v-/w-/x-`）不一致。
- **方案 2a（用户拍板）**：先读 `TARGETPATH=/usr/local/static/xxx`，再在 tarsrc 根目录 `ls -F | grep "*xxx/"` 匹配——**xxx 唯一，不会跨前缀存在多个**（`v-xfce4`/`v-gpicview`/`v-pavucontrol`…均以 xxx 结尾，ls -F 目录带尾 `/`）：
  ```sh
  comp=$(basename $TARGETPATH)                            # xfce4 / gpicview / pavucontrol
  # 用户表述 `ls -F | grep "*xxx/"`；grep 的 * 是正则（非 glob），按目录名 xxx/ 结尾匹配更稳（=ls -d $TARSRC/*${comp}/）
  TARSRC_COMP=$(ls -F $TARSRC | grep "${comp}/$" | tr -d '/' | head -1)
  test -n "$TARSRC_COMP" || TARSRC_COMP=$TARSRC           # 未命中回退（无 tarsrc 时原逻辑）
  ```
- **唯一性依据**：tarsrc 目录名=`v-/w-/x-` + 组件名，**xxx（xfce4/gpicview/…）在各前缀下唯一**，`*xxx/` 不会跨前缀多命中（tarsrc 无 `libxfce4`/`xfce4settings` 等干扰目录；库包已按组件归位）。
- **验证**：xfce4 → `*xfce4/` 命中 `v-xfce4/`；gpicview → `v-gpicview/`；pavucontrol → `v-pavucontrol/`。

> **订正（2026-11-13）**：gsm/dbus-glib 两组件 **basename 与 tarsrc 目录名不一致**，2a 通配会 miss → 在 `common.sh` 内维护 **case 映射表**单独映射，其余组件仍走 2a：
> ```sh
> case "$comp" in
>   gsm)       TARSRC_COMP="$TARSRC/v-sysmonitor" ;;  # sysmonitor TARGETPATH=/usr/local/static/gsm
>   dbus-glib) TARSRC_COMP="$TARSRC/x-dbus" ;;         # dbus-glib 包在 x-dbus/ 下
>   *)         TARSRC_COMP=$(ls -d "$TARSRC"/*"$comp"/ 2>/dev/null | head -1) ;;
> esac
> ```
> 另加**全局包名兜底**（最后防线）：`find "$TARSRC" -name "$file" -type f | head -1`（tarsrc 31 包 13 目录无重名，唯一命中）。已实测：gsm→`gnome-system-monitor-2.28.2.tar.bz2`、dbus-glib→`dbus-glib-0.112.tar.gz` 均与 tarsrc 文件字节一致（cmp MATCH）。

##### 4.1.4、TARSRC 位置与 buildx.sh 提前克隆（要求 1）

- **TARSRC=/src/../tarsrc**：构建容器 `/src` 软链宿主 `compile/src`，`/src/../tarsrc` = **宿主项目根 `/tarsrc`**（`/src` 软链透传）→ 容器内可访问，跨容器/跨镜像复用。
- **buildx.sh 内提前克隆**（`compile/buildx.sh`）：clone 到**项目相对目录** `tarsrc/`（项目根）：
  ```sh
  # compile/buildx.sh 顶部（compile 分支前）
  test -d tarsrc/.git || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc tarsrc
  ```
  （buildx.sh 在 `compile/` 下，`tarsrc/` = `compile/../tarsrc` = 项目根/tarsrc；可加 echo 提示。）
- **外部克隆亦可**：`git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc /_ext/.../docker-x11base/tarsrc`（宿主侧，等价）。

> **订正（2026-11-13）**：`TARSRC=/src/../tarsrc` 经 `/src` 软链（→`compile/src`）透传，实际解析为 **宿主 `compile/tarsrc`**（非项目根 `/tarsrc`）。`compile/buildx.sh` 相应改 `_TS=$(dirname "$0")/tarsrc`（= `compile/tarsrc`，与 down_catfile 默认同址），否则两处各克隆一份。实测容器内 `/src/../tarsrc` = host `compile/tarsrc`（13 目录 31 包）。

##### 4.1.5、xfce4 覆盖确认（要求 3 优先 xfce4）

- xfce4 `fetch_src` 包名=**规范化**（`Thunar-1.6.3.tar.bz2`…），与 tarsrc `v-xfce4/` **完全一致** → 精确匹配，无需模糊兜底；其 URL 尾文件名也=规范名。
- 9 个 xfce4 包（exo/garcon/libexif/libxfce4ui/libxfce4util/ristretto/Thunar/xfce4-settings/xfconf）全命中。

##### 4.1.6、风险与边界

- **URL 文件名≠tarsrc 规范名**：github archive（`v3.0.tar.gz`/`0.8.2.tar.gz`）→ 版本模糊兜底；tarsrc 每组件包少、冲突低。
- **CI/buildx 多阶段不持久**：每次镜像重建 depth1 clone 一次（gitee 快、可达）；落宿主项目根 → 跨容器复用。
- **改全局函数副作用**：影响所有组件 + `gitac/syncer.sh`（common.sh:29 注释提到）。**建议默认门控**：`TARSRC` 为空则不启用（`test -n "$TARSRC" || <原逻辑>`），CI 显式传 `--build-arg TARSRC=/src/../tarsrc` 才开 → 低风险易回退。
- **验证**：`docker exec builder-awe sh /src/v-xfce4/build.sh b_deps` 实跑，确认 tarsrc 命中、无网络下载。

##### 4.1.7、结论（要不要两处改）

- **不用两处（xfce4 fetch_src 单独改）**：只改 `common.sh` 的 `down_catfile`（接入）+ `compile/buildx.sh`（clone 提示）两文件；xfce4 `fetch_src` 自动受益。
- 前提：组件名映射用 **4.1.3 方案 2a**（`ls -d *xxx/`）。

#### 4.2、实施落地与验证（2026-11-13，已推送 `feat/ai-260925`）

##### 4.2.1、落仓改动（commit 清单）

| commit | 文件 | 说明 |
|---|---|---|
| `cbd0596` | docs/.../11110827-ci-builder-gtk-app.md | 六章 4.1 订正：case 映射表 + TARSRC=compile/tarsrc |
| `8277f76` | compile/src/common.sh | down_catfile 接 tarsrc（case 表 + 2a 通配 + find 兜底） |
| `7706c55` | compile/buildx.sh | 克隆路径修正 `$(dirname $0)/tarsrc` |
| `33dd9dd` | .gitignore | 忽略 `/compile/tarsrc/` |

- **范围**：只改 `common.sh` 的 `down_catfile` 一处 + `buildx.sh` 提前克隆 + `.gitignore`；xfce4 `fetch_src` 底层透传 `down_catfile`，自动受益，无需单独改。

##### 4.2.2、down_catfile 最终实现（compile/src/common.sh:28-61）

```sh
function down_catfile(){
  CACHE=$TARGETPATH/../.cache; mkdir -p $CACHE #移到func内; gitac/syncer.sh调用时vm内执行 会权限故障;
  url=$1
  file=${url##*/}
  # tarsrc 优先（gitee x11base-tarsrc 源码包缓存，2026-11-13）：任何步骤失败/未命中回退 curl 下载，不阻塞。
  # ① 仓库不存在 → depth1 克隆（幂等）② 组件目录映射（TARGETPATH=xxx → *xxx/；例外走映射表）③ 目录内取包（精确名→版本模糊）
  # ④ 全局包名兜底（find -name 唯一命中，最后防线）
  TARSRC=${TARSRC:-/src/../tarsrc}
  if test -n "$TARGETPATH"; then
    (
      test -d "$TARSRC/.git" || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc "$TARSRC" >/dev/null 2>&1
      test -d "$TARSRC/.git" || exit 0
      comp=$(basename "$TARGETPATH")
      # 组件目录映射表（basename 与 tarsrc 目录名不一致的例外；其余走 2a *xxx/；xxx 唯一不跨前缀多命中）
      case "$comp" in
        gsm)       TARSRC_COMP="$TARSRC/v-sysmonitor" ;;  # sysmonitor TARGETPATH=/usr/local/static/gsm
        dbus-glib) TARSRC_COMP="$TARSRC/x-dbus" ;;         # dbus-glib 包在 x-dbus/ 下
        *)         TARSRC_COMP=$(ls -d "$TARSRC"/*"$comp"/ 2>/dev/null | head -1) ;;
      esac
      if test -n "$TARSRC_COMP" && test -s "$TARSRC_COMP/$file"; then
        cp "$TARSRC_COMP/$file" "$CACHE/$file"; exit 0
      elif test -n "$TARSRC_COMP"; then
        ver=${file#v}; ver=${ver%.tar.*}
        hit=$(ls "$TARSRC_COMP"/*"$ver"* 2>/dev/null | head -1)
        test -n "$hit" && cp "$hit" "$CACHE/$file" && exit 0
      fi
      hit=$(find "$TARSRC" -name "$file" -type f 2>/dev/null | head -1)
      test -n "$hit" && cp "$hit" "$CACHE/$file"
    ) >/dev/null 2>&1 || true
  fi
  # ② 无则源头下载
  test -s $CACHE/$file || curl -# -k -fSL $url > $CACHE/$file
  cat $CACHE/$file
}
```

- **容错**：tarsrc 整段包在 `( ... ) >/dev/null 2>&1 || true` 子 shell 内，任何步骤失败（clone 失败/目录未命中/find 未命中）都回退末尾 `curl` 下载，不阻塞；`test -n "$TARGETPATH"` 守卫（TARGETPATH 空时跳过 tarsrc）。
- **映射表**：case 里 `gsm→v-sysmonitor`、`dbus-glib→x-dbus`（二者 basename 与 tarsrc 目录名不一致）；其余走 `*)` 2a 通配 `ls -d *xxx/`（xxx 唯一）。

##### 4.2.3、TARSRC 路径澄清（关键坑，2026-11-13 实测）

- `TARSRC=${TARSRC:-/src/../tarsrc}`：容器内 `/src` 是**软链** → 宿主 `compile/src`，故 `/src/../tarsrc` **透传解析为宿主 `compile/tarsrc`**（**不是**项目根 `/tarsrc`）。
- `buildx.sh` 原写 `$(dirname $0)/../tarsrc` = 项目根/tarsrc → 与 down_catfile 默认**不一致**，会各克隆一份。已改 `_TS=$(dirname "$0")/tarsrc`（= `compile/tarsrc`），两处同址。
- 宿主 `compile/tarsrc/`（gitee 克隆产物）已加 `.gitignore` 忽略，勿入仓。

##### 4.2.4、验证（builder-pav 实测，`/src/../tarsrc` → 宿主 `compile/tarsrc`）

| 组件 | TARGETPATH | tarsrc 目录 | 包 | 结果 |
|---|---|---|---|---|
| gsm | `/usr/local/static/gsm` | `v-sysmonitor/` | gnome-system-monitor-2.28.2.tar.bz2 | `cmp` 字节一致（2432252B）✅ |
| dbus-glib | `/usr/local/static/dbus-glib` | `x-dbus/` | dbus-glib-0.112.tar.gz | `cmp` 字节一致（715340B）✅ |
| xfce4 | `/usr/local/static/xfce4` | `v-xfce4/` | Thunar-1.6.3.tar.bz2 | 精确名 `cmp` MATCH ✅ |
| gpicview | `/usr/local/static/gpicview` | `v-gpicview/` | gpicview-0.2.5.tar.gz | 版本模糊 `cmp` MATCH ✅ |

- **判据**：`down_catfile` 写入 `$CACHE/$file`（`$TARGETPATH/../.cache`）后，与 tarsrc 内对应包 `cmp` 逐字节比对；gsm/dbus-glib 走 **case 映射表**命中，xfce4/gpicview 走 `*)` 2a 通配命中。tarsrc 31 包 13 目录**无重名**（find 兜底唯一命中安全）。
- 命令替换取二进制会剥尾部换行致 `wc -c` 偏小，**判据以 `cmp` 为准**（勿用 `wc -c` 对包大小）。

### 5、gitclone 网络抖动与源码快照缓存（2026-11-13）

#### 5.1、xcbutil m4 submodule 修复：CI 无 tarsrc-git 缓存（已推送 `18d9ee6`）

> 详版见五章 3.3.4；本节为六章"源码获取/网络"专题衔接，记录 gitclone 机制在 **CI 无缓存**场景的坑与修复。

**根因**：CI 构建上下文**不带 `compile/tarsrc-git`**（`.gitignore` 排除 + Dockerfile 只 `COPY ./src /src`）→ 容器内 `/src/../tarsrc-git` 不存在。`gitclone` 缓存未命中回落网络（common.sh:77-78，安全），**但** `w-tint2/build.sh` xcbutil 的 m4 submodule 处理原**无条件 `sed` `.gitmodules` 指向 `/src/../tarsrc-git/util-common-m4`** → CI 下 `git submodule update --init` 从不存在路径拉取失败 → fallback `cp -a` 也因源不存在报 `cp: can't stat '/src/../tarsrc-git/util-common-m4'` → `./autogen.sh` 无 m4 宏/无 configure → `make` 无 install 目标 → feh stage `doExec FAIL`。

**修复（w-tint2/build.sh xcbutil，2026-11-13 最终版）**：
> **订正（2026-11-13）**：进一步改为 m4 子模块用 `gitclone` 预热（用户拍板"5.1子模块也可用gitclone命令先给预热目标目录"），不再 sed+submodule update+cp fallback——gitclone 享受缓存链（GITCACHE>tar.gz>网络）且不依赖 `git://` 协议。
```sh
# m4 子模块: gitclone 预热(享受缓存链 GITCACHE>tar.gz>网络)
rm -rf m4; gitclone https://gitee.com/g-system/util-common-m4 m4
# autogen.sh 检查 `git submodule status|grep ^-`: 父仓库 gitlink 与 gitclone 的 m4 独立克隆 HEAD 不一致→uninitialized→exit 1
# → 移除父仓库对 m4 的 submodule 跟踪(.gitmodules 删段+git rm --cached+.git/config), autogen 检查即过(实测生成 Makefile)
sed -i '/\[submodule "m4"\]/,/^$/d' .gitmodules 2>/dev/null || true
git rm --cached m4 >/dev/null 2>&1 || true
git config --remove-section submodule.m4 2>/dev/null || true
test -f m4/xcb_util_common.m4 || { echo "!! m4 gitclone 未就位(autogen 将失败)"; }
```
- gitee `g-system/util-common-m4` 与宿主缓存 `tarsrc-git/util-common-m4` 同名（`_repo=util-common-m4`）→ **GITCACHE 命中**；CI 无缓存回落 tar.gz 快照/网络 gitee 克隆。
- **原方案（sed+cp，见五章 3.3.4）已废弃**：sed 指向缓存路径 + submodule update + cp fallback——但 submodule update 走 `git://`（CI 常被禁）且 xcb-util `autogen.sh` 会因 m4 uninitialized 再 exit 1，故改 gitclone 预热 + 移除 submodule 跟踪更可控。

**验证（builder-awe，2026-11-13）**：
- **缓存路径**（GITCACHE 命中）：`xcbutil` 全过——m4 gitclone 缓存命中（origin gitee g-system）、`./autogen.sh` 生成 Makefile/config.status/configure、CCLD 链接、libtool install `libxcb-util.a` 落 `/usr/local/lib`（RC=0）。
- **tar.gz 复用路径**（`GITCACHE=/nonexistent`+预置快照）：`gitclone tar.gz hit` → 解压还原 `.git`+`configure.ac`（含 `.git` 快照）。
- 网络 clone→打 tar.gz 路径：gitee 当前抖动未实测（环境问题），逻辑已代码确认（`test -d .git`→`tar czf`）。

**结论**：`grep tarsrc-git compile/src/` 仅剩 w-tint2 一处（已修）；其余 `gitclone` 用法均已回落网络。**CI 下 feh/libcroco/librsvg/libxi/libfm/menu-cache/pcmanfm 主仓库 clone 走 gitee 网络**——gitee 波动是剩余唯一网络风险。

#### 5.2、gitclone 打 tar.gz 快照缓存方案（2026-11-13 已实施，用户拍板）

**问题**：5.1 修复后，CI 无 `tarsrc-git` → 各组件 gitclone 回落网络（gitee/github）；gitee 间歇 `Connection reset by peer` / 慢（fk-libfm 338s）仍致 b_deps 依赖未就位。需让 CI 也能"免网络"命中源码缓存。

**方案（已实施，gitclone 方法内，common.sh）**：
1. **克隆成功之后**：把代码目录打一个压缩包 `<repo>-<ver>.tar.gz` 放 `$TARSRC/_cache_repo/`（**含 `.git`**，即完整 git 仓库快照）；
2. **克隆之前**：检查对应包已有则**直接复用之（解压），跳过克隆**。

**细化（用户拍板 2026-11-13）**：
- **命名**：`<repo>-<ver>.tar.gz`；**`ver` = `--branch` 值去 `--branch=` 前缀，无则 `default`**（用户拍板）；`repo`=URL 末段 `_repo`（如 `fk-tint2-16.1.tar.gz`、`fk-libxi-default.tar.gz`）。
- **路径**：`$TARSRC/_cache_repo/`（`TARSRC=${TARSRC:-/src/../tarsrc}`，gitee `infrastlabs/x11base-tarsrc` 源码包仓库克隆，common.sh:35）。
- **①只存不推（用户拍板）**：gitclone 只**本地打包**，**不自动推送**；`_cache_repo/` 由用户**手动管理推送**（何时推 tarsrc、推哪些，用户定）。
- **②safe.directory 全局 `*`（用户拍板）**：`git config --global --add safe.directory '*'`（git≥2.35.2 支持通配；容器内可信环境，**免仓库粒度逐个登记**——实测 root 跑宿主 uid=1000 的仓库不再报 dubious ownership，git status 正常）。
- **优先级**：`GITCACHE` 缓存（含 `.git`，本地）> tar.gz 快照（`_cache_repo/`，含 `.git`）> 网络 clone（未命中，不换源）。
- **③边界（解释，用户未看懂处）**：`down_catfile`（六章 4.x）管 **tarball 源码包**（如 `Thunar-1.6.3.tar.bz2`，下载缓存到 `$TARGETPATH/../.cache`）；`gitclone`（本节 5.2）管 **git 仓库源码**（如 `fk-tint2`，快照到 `$TARSRC/_cache_repo/`）。二者是**两种不同形态的源码缓存**——tarball（解压即用，无 git）与 git 仓库（含 `.git`，可 git 操作/后续 submodule）——**用途不同、目录不同（`$TARSRC/<组件>/` vs `$TARSRC/_cache_repo/`）、互不干扰、无重叠**。简单说：down_catfile 是"压缩源码包"、gitclone 是"git 仓库快照"，各管各的，不冲突。
