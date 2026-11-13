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
- 五、CI实跑验证（2026-11-12~14）→ 已拆出至 `docs/2026/11120827-ci-builder-gtk-app-rootfs.md`（2026-11-15）
- 六、xfce4 源码包收集与下载源（2026-11-13）→ 已拆出至 `docs/2026/11130827-ci-builder-tarsrc.md`（2026-11-14）

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
## 五、CI实跑验证（2026-11-12~13）【已拆出】

> **去向**：本章已拆出至 `docs/2026/11120827-ci-builder-gtk-app-rootfs.md`（保留原章节序号与层级，含 `### 1~5`、`#### 5.1~5.4.x` 小节，2026-11-15）。本文件仅存四章；对应内容见新文档。

## 六、xfce4 源码包收集与下载源（2026-11-13）【已拆出】

> **去向**：本章已拆出至 `docs/2026/11130827-ci-builder-tarsrc.md`（保留原章节序号与层级，含 `### 1~5`、`#### 4.x/5.x`，2026-11-14）。本文件仅存一~五章；对应内容见新文档。

