# v-pavucontrol：pavucontrol 静态构建（GTK2/gtkmm）记录

> 2026-11-05 启动。目标：在 **新 gtk2 库**（`alpine-builder-gtk224` / `builder-obox`）环境下用
> `compile/src/v-pavucontrol/build.sh` 构建 **pavucontrol**（PulseAudio 音量控制 GUI）静态产包。
> pavucontrol 是 **C++/gtkmm** 应用（非纯 GTK 前端），依赖 gtkmm + sigc++ + libcanberra-gtk + libpulse。

**目录（缩进章节表）**
- **一、版本选择**（2026-11-05 定稿：v3.0）
  - 1 GTK2 兼容的最后一版 = v3.0（2015-03-24）
  - 2 版本/依赖对照
  - 3 本项目基础设施适配
  - 4 结论
- **二、开工规划**（2026-11-05）
  - 1 核心洞察：gtkmm-2.4 栈是 pavucontrol 与 gnome-system-monitor 的共享地基
  - 2 缺口对照
  - 3 gtkmm 栈构建顺序（依赖序）
  - 4 执行策略 A→C→B
  - 3.1 gtkmm-2.4 栈版本定稿（A 步完成，2026-11-05 核实 download.gnome.org）
  - 3.2 libcanberra-gtk 可 patch 掉（C 步完成，2026-11-05 源码实证）
  - 3.3 gtkmm 栈构建结果（B 步完成，2026-11-05 磁盘满中断后恢复）
  - 3.4 B2：pulseaudio 静态库构建（2026-11-05 完成）
  - 3.5 pavucontrol v3.0 静态组装（2026-11-05 完成，builder-awe）
  - 3.6 runtime 实跑验证（2026-11-05，hdmi 容器 Xvnc :464）
  - 3.7 用 headless 已有环境启动的方法（2026-11-05 实测，PULSE_SERVER 可免设）
- **三、音量 tray 图标（pasystray/pnmixer）选型**（2026-11-06）
  - 1 pasystray 0.8.2 主选、pnmixer 排除 + 业界替代品（2026-11-06 用户要求新看）
    - 1.1 已有家底（可直接复用，来自本篇 §3.4）
    - 1.2 pasystray（推荐，PulseAudio 原生）— 版本 0.8.2
    - 1.3 pnmixer — 不建议（ALSA-only，无 PA 后端）
    - 1.4 业界其他可选 / 更受欢迎的音量 tray 工具
    - 1.5 结论建议
    - 2 pasystray 0.8.2 静态构建实现与调试（2026-11-06 完成，builder-awe）
      - 2.1 configure.ac 核实（订正 §1.2 的"待核实"）
      - 2.2 构建（builder-awe，GTK2 静态）
      - 2.3 手动静态链（xx-clang -static）
      - 2.4 glade 类型注册崩溃（关键坑，实测）
      - 2.5 runtime 实跑（hdmi 容器 Xvnc）
      - 2.6 落仓
    - 3 中文支持（zh_CN，2026-11-07 用户问"有现成中文 mo 吗"，没有就自建）
      - 3.1 调查：上游无 i18n 基础，无现成中文 mo
      - 3.2 实现（gettext 静态）
      - 3.3 验证（hdmi 容器 Xvnc :808）
      - 3.4 落仓
      - 3.5 验证流程实录：环境→运行→定位 tray→操作→截图（2026-11-07 hdmi Xvnc :808 实测）

## 一、版本选择（2026-11-05 定稿：v3.0）

### 1、GTK2 兼容的最后一版 = v3.0（2015-03-24）

- pavucontrol 是 **C++/gtkmm** 应用，依赖 gtkmm + sigc++ + libcanberra-gtk + libpulse +
  libpulse-mainloop-glib。
- **v4.0（2019-03-05）起硬编码 `gtkmm-3.0`**（configure.ac 无 gtk3 开关）→ 纯 GTK3。
- **v1.0/v2.0/v3.0 的 configure.ac 相同**，都支持 `--disable-gtk3` 切回 GTK2：
  `gtkmm-2.4 >= 2.16` + `sigc++-2.0` + `libcanberra-gtk`（canberra_ver="" 无 3 后缀）。
- v3.0 源码 GTK2 路径完整：`mainwindow.cc` 有 `#ifdef HAVE_GTK3` 分支（GTK2 用
  `Gdk::Cursor(Gdk::WATCH)`）。
- v3.0 用 `Gtk::Builder::add_from_file(GLADE_FILE)`（GTK2 兼容 glade）。
- **选 v3.0**：最新支持 GTK2、功能最全、源码 GTK2 分支维护到位。

### 2、版本/依赖对照

| 版本 | 日期 | GTK 绑定 | 说明 |
|---|---|---|---|
| v1.0/v2.0/v3.0 | 11-15/13-03/15-03 | gtkmm-2.4（`--disable-gtk3` 可切） | GTK2 可用 |
| v4.0 | 19-03 | gtkmm-3.0 硬编码 | 纯 GTK3 |
| v5.0 | 21-08 | gtkmm3 | Alpine/ubt 打包版，GTK3 栈 |

### 3、本项目基础设施适配

- **GTK2 已就位**：gtk 2.24.33 静态（u-gtk，含 murrine/pixmap/file/lpr 打印后端）。
- **pulseaudio 版本匹配**：本项目 pulseaudio = **v13-99-3**（g-system/fk-pulseaudio，vers.txt），
  v3.0 要求 libpulse >= 0.9.16 → 满足。
- **pulseaudio 静态客户端库——可构建（用户确认，非缺口）**：
  - `compile/src/x-pulseaudio/build.sh` 的 `pulseaudio()` 用 `sam-build.sh` + `make install`，
    配方（docs/core/pulse05.md）：`export LDFLAGS="-static ..."`、`export CC=xx-clang`、
    `./configure --prefix=/usr/local/static/pulseaudio` + `make LDFLAGS="-static --static $dep1"`。
  - 产物（docs/core/pulseaudio.md:319-334 明确列出）：`/usr/local/static/pulseaudio/lib/libpulse.a`、
    `libpulse-mainloop-glib.a`、`libpulse-simple.a`、`libpulsecore-13.99.a` 等。
  - **注意**：当前 host/hdmi 的 `/usr/local/static/pulseaudio` 树只有 `bin`+`etc`（部署了运行二进制），
    无 `lib/`（libpulse.a 未拷入）。要链 pavucontrol 需**在构建容器（box，musl）跑 pulseaudio() 产出完整静态树**，
    或确认 `make install` 确实装 client 库到 `$TARGETPATH/lib/`。
- **⚠️ 真缺口（比 geany 的 Scintilla 更重）**：pavucontrol 还需要以下**静态库**，box/awe 当前**都没有**：
  - `gtkmm-2.4`（C++ 封装，含 atkmm/pangomm/cairomm 派生）
  - `libsigc++-2.0`
  - `libcanberra-gtk`（GTK2 版，`>= 0.16`，拉 GStreamer 栈）

### 4、结论

- **选 v3.0** 作为 pavucontrol 静态编译版本（GTK2 最后一版）。
- **前置工作**：①在 box（musl）跑 `x-pulseaudio/build.sh pulseaudio` 产出含 libpulse.a 的静态树；
  ②构建 gtkmm-2.4 + libsigc++ 静态；③构建 libcanberra-gtk（GTK2 版）。
  后两者（gtkmm-2.4/libcanberra-gtk）是真正尚未就位的硬依赖。

## 二、开工规划（2026-11-05）

### 1、核心洞察：gtkmm-2.4 栈是 pavucontrol 与 gnome-system-monitor 的**共享地基**

- `gtkmm-2.4` + `libsigc++-2.0` 是 **pavucontrol v3.0** 与 **gnome-system-monitor 2.28.2** 的共同硬依赖
  （后者缺口更重：7 项，含 gtkmm 全套 + libgtop/wnck/dbus-glib/gconf）。
- **一次构建 gtkmm-2.4 栈，两应用同时受益** → 列为第一优先级工作。
- 实测 builder-awe / builder-obox 两容器**均无** gtkmm/sigc/canberra/pulse 静态库（全空缺口）。

### 2、缺口对照

| 组件 | pavucontrol | gnome-system-monitor |
|---|---|---|
| gtkmm-2.4 全套（sigc++/glibmm/giomm/cairomm/pangomm/atkmm/gdkmm） | 需 | 需（共享） |
| libcanberra-gtk（GTK2） | 需 | — |
| libpulse 静态客户端库 | 需（可构建，非缺口） | — |
| libgtop / libwnck / dbus-glib / gconf | — | 需（更重） |

### 3、gtkmm 栈构建顺序（依赖序）

```
libsigc++-2.0 → glibmm-2.4 → cairomm → pangomm-1.4 → atkmm-1.6
            → gdkmm-2.4 → giomm-2.4 → gtkmm-2.4 (2.24.5)
```

### 4、执行策略 A→C→B

- **A（先做，信息量最大）**：gtkmm-2.4 栈各组件**版本定稿** + 构建方法（gmmproc/mm-common 工具链、C++ 标准 flag）——见下节 3.1。
- **C（宜早决策）**：评估 libcanberra-gtk 是否可 patch 掉（省 GStreamer 栈一大块）——见 3.2。
- **B（后动手）**：box 容器构建 gtkmm 栈 → 跑 pulseaudio 产出 libpulse.a → 创建 v-pavucontrol/build.sh（geany 模式）。

> 参考已验证模式：`compile/src/v-geany/build.sh`（GTK2 静态链 `LIBS0` + 直接 `xx-clang++ -static`
> 绕开 libtool 不转发 `-static` + `libgcc_s.a` 兜底 + `--disable-*`）。

### 3.1、gtkmm-2.4 栈版本定稿（A 步完成，2026-11-05 核实 download.gnome.org）

| 组件 | 版本 | tarball 来源 | 说明 |
|---|---|---|---|
| libsigc++-2.0 | **2.10.8** | `sources/libsigc++/2.10/` | 2.10 系列 GNOME 源最后版（≥2.5.1 需 C++11，注意） |
| glibmm-2.4 | **2.46.4** | `sources/glibmm/2.46/` | 包装 glib 2.44；**giomm-2.4 在 glibmm 源码树内**（gio/ 子目录），随其构建 |
| cairomm-1.0 | **1.12.0** | `sources/cairomm/1.12/` | cairomm-1.0 ABI（gtkmm-2.4/3.0 共用；1.16 起新 ABI 不可用） |
| pangomm-1.4 | **2.40.0** | `sources/pangomm/2.40/` | 1.4 ABI；2016-11，与 gtkmm 2.24.5 同期 |
| atkmm-1.6 | **2.24.2** | atkmm-1.6 终版 | 2015-12；GitLab 明确"atkmm-1.6 ABI 最近版 = 2.24.2" |
| gdkmm-2.4 | （**随 gtkmm 树**） | — | gdkmm **不是独立 tarball**，在 gtkmm 源码树 `gdk/` 子目录，随 gtkmm 构建 |
| gtkmm-2.4 | **2.24.5** | `sources/gtkmm/2.24/` | **GTK2 终版**（2016-09-04，gtkmm-2-24 分支）；满足 pavucontrol ≥2.16、gsm ≥2.8 |

**关键简化**：gdkmm + giomm 不独立发布（分别在 gtkmm/glibmm 源码树内）→ 实际需**独立构建 5 个**：
`libsigc++ → glibmm(含 giomm) → cairomm → pangomm → atkmm → gtkmm(含 gdkmm)`。

**构建方法（gmmproc 生成式，比纯 C 的 GTK2 更复杂）**：
- 需先构建 **mm-common**（元工具）+ glibmm（提供 **gmmproc** Perl 脚本）——gtkmm 等靠已装 gmmproc 生成 C++。
- 各组件 autotools：`./autogen.sh && ./configure --enable-static --disable-shared --prefix=$TARGETPATH`，
  静态产物 `.a` 入 `$TARGETPATH/lib`。
- 静态编译 flag：`LDFLAGS="-static"`（或链时 xx-clang++ -static）；老组件 C++98，gtkmm 2.24.5 可用 C++11。
- 工具链：box（musl）`xx-clang++` 交叉静态，参照 `v-geany/build.sh`。

### 3.2、libcanberra-gtk 可 patch 掉（C 步完成，2026-11-05 源码实证）

**结论：✅ 完全可 patch 掉，省下整条 GStreamer 静态依赖链。**

- **使用深度极浅**（全树 `src/*.cc` grep 实证）：canberra 引用**仅 1 处**——
  `src/pavucontrol.cc`：`#include <canberra-gtk.h>` + `ca_context_set_driver(ca_gtk_context_get(), "pulse")`。
  **全树无任何 `ca_context_play`（实际播放）** → canberra 仅设置 driver，音效可安全移除。
- **configure.ac 硬依赖**：`PKG_CHECK_MODULES(GUILIBS, [ gtkmm-... sigc++-2.0 libcanberra-gtk$canberra_ver >= 0.16 ])`，
  无 `--disable-canberra` 开关 → 必须 patch 才能跳过。
- **patch 方案（干净，无需伪存根库）**：
  1. `configure.ac`：从 `PKG_CHECK_MODULES(GUILIBS, ...)` 移除 `libcanberra-gtk$canberra_ver >= 0.16`；
  2. `src/pavucontrol.cc`：删除 `#include <canberra-gtk.h>` 与 `ca_context_set_driver(...)` 两行。
- **省下的依赖**：libcanberra-gtk 原拉 GStreamer 栈（gtk3 apk 记录带 46 项：gstreamer/gst-plugins-base/webrtc/alsa/libtheora 等）——整条静态链免构建。
- 注：`mainwindow.cc` 的 "System Sounds" 仅是 UI 标签字符串（非 canberra 调用），保留无碍。

**决策**：走 patch 方案，GTK2 版 libcanberra-gtk **不构建**。

### 3.3、gtkmm 栈构建结果（B 步完成，2026-11-05 磁盘满中断后恢复）

**7/7 组件全部构建并安装成功**（builder-obox，`/usr/lib`，`--enable-static --disable-shared`）：

| 组件 | 版本 | 产物 | 备注 |
|---|---|---|---|
| libsigc++-2.0 | 2.10.8 | `libsigc-2.0.a` | 需 `--disable-documentation`（doxygen/xsltproc 缺失致 docs 失败） |
| glibmm-2.4（含 giomm） | 2.48.1 | `libglibmm-2.4.a` 9.9M + `libgiomm-2.4.a` 24.9M | **先装 2.46.4 失败**：pangomm 2.40 需 glibmm≥2.48 → 升级 2.48.1 |
| cairomm-1.0 | 1.12.0 | `libcairomm-1.0.a` 2.2M | |
| pangomm-1.4 | 2.40.0 | `libpangomm-1.4.a` 2.7M | 需 patch：`attrlist.cc` 加 `#include <pango/pango-markup.h>`（pango 1.49 不再自动暴露） |
| atkmm-1.6 | 2.24.2 | `libatkmm-1.6.a` 3.7M | |
| gdkmm-2.4 | （随 gtkmm 树） | `libgdkmm-2.4.a` 4.3M | gdkmm 在 gtkmm 源码树 `gdk/`，非独立 |
| gtkmm-2.4 | 2.24.5 | `libgtkmm-2.4.a` 42.7M | 编译完成于磁盘满前，install 于恢复后 |

**已修复的关键坑**：
- **glibmm `threads.h` GPrivate**：glib 2.70 中 `GPrivate` 为结构体，`gobj()` 需 `return &gobject_;`（2.46/2.48 均需此 patch）。
- **u-gtk 的 pc 命名**：pango/atk/gail 的 pc 缺版本后缀（`pango.pc` 非 `pango-1.0.pc`）→ 创建符号链接别名（`pango-1.0.pc`←`pango.pc` 等 8 个）才能 pkg-config 解析。
- **libtool install-exec 不装 `.a`**：glibmm/pangomm/gtkmm 顶层 `make install` 只装头/pc，`.a` 需在子目录 `make install` 或手动 `cp .libs/*.a`。
- **pangomm 需 glibmm≥2.48.0**（2.40.0 的 configure 硬性要求）→ 弃 2.46.4 用 2.48.1。

**验证**：`pkg-config --exists gtkmm-2.4` → OK（2.24.5），全链路 Requires（atkmm/giomm/pangomm/gtk+-2.0/gtk+-unix-print-2.0/gdkmm-2.4）解析通过。

**构建脚本已落仓**（2026-11-05 在干净 base 容器全流程实测通过）：`compile/src/u-gtkmm/build.sh`（`bash build.sh gtkmm` 一键重建 7 组件）+ `compile/src/u-gtkmm/glibmm-gprivate.patch` + `pangomm-pango-markup.patch`。关键点（实测坑）：① 各组件 box 的 git-archive tarball 无生成 configure → `mkcfg` 缺则 `./autogen.sh`；② **`common.sh` 的 `LDFLAGS="-static"` 必须去掉**（否则 glibmm 构建辅助工具 `generate_defs_glib` 静态链失败致 make 中断）→ gtkmm() 内 `export LDFLAGS="-Wl,--as-needed"`（`.a` 由 `--enable-static --disable-shared` 控制）；③ 8 个 u-gtk pc 符号链接别名；④ libtool `make install` 不装 `.a` → 手动 `cp */.../.libs/*.a`；⑤ 重建后 pkg-config 2.24.5 + glibmm 符号数 1736≈box 1744（功能等价，box 尺寸大系含调试符号），且 **pavucontrol 用重建 gtkmm 库静态链成功（19.1M）**。

### 3.4、B2：pulseaudio 静态库构建（2026-11-05 完成）

**结论：✅ 产出 `libpulse.a`/`libpulse-simple.a`/`libpulse-mainloop-glib.a` 静态库（pulseaudio 13.0），装入 `builder-obox:/usr/local/static/pulseaudio`。**

- **5 个依赖全部静态构建**（builder-obox，`--enable-static --disable-shared`）：
  | 依赖 | 版本 | 产物 |
  |---|---|---|
  | libogg | 1.3.5 | `libogg.a` 119K |
  | libopus | 1.3.1 | `libopus.a` 3.7M |
  | libFLAC | 1.3.4 | `libFLAC.a` 630K |
  | libvorbis | 1.3.7 | `libvorbis.a` 302K + `libvorbisenc.a` 806K + `libvorbisfile.a` 44K |
  | libsndfile | 1.0.31 | `libsndfile.a` 892K |
  - **坑**：各 dep `autogen.sh` 均不生成 configure（只跑 libtoolize）→ 需手动 `autoreconf`/`aclocal`（慢，扫描系统 m4）+ `autoconf`；libsndfile 的 Makefile 调 `autogen`（未装）→ `sed "s/autogen/echo autogen/g" Makefile`（同参考 build.sh）。
- **libltdl**：pulseaudio configure 硬查 `lt_dladvise_init in -lltdl`；容器仅有 `libltdl.so`（无 `.a`）→ 用 libtool-2.4.6 源码构建 `libltdl.a`（`libltdlc.a` 重命名）+ `ltdl.h`。
- **pulseaudio 13.0 构建**：git clone（fk-pulseaudio）autotools 全挂（aclocal 悬死、git pull 外网不可达、aux 文件缺失）→ **改用官方发布 tarball `pulseaudio-13.0.tar.xz`**（自带 configure + build-aux），`sam-build.sh` 的静态 configure args（`--disable-alsa/dbus/gtk3/...`）复用，**`--disable-glib2` 移除**（pavucontrol 需 `libpulse-mainloop-glib`）。
  - 产物：`/usr/local/static/pulseaudio/lib/libpulse.a` 669K、`libpulse-simple.a` 16K、`libpulse-mainloop-glib.a` 20K、`lib/pulseaudio/libpulsecommon-13.0.a`（pc 的 `Libs.private` 依赖）。
  - 头 `include/pulse/*` + pc `lib/pkgconfig/libpulse*.pc` 一并安装。

### 3.5、pavucontrol v3.0 静态组装（2026-11-05 完成，builder-awe）

**结论：✅ `pavucontrol` 静态二进制 19.75M 组装成功，装在 `builder-awe:/usr/local/static/pavucontrol/bin/pavucontrol`（含 glade + desktop）。**

- **组装容器 = builder-awe**（用户要求）：主题/图标库（murrine/pixmap/rsvg/svg）在 awe；box 构建的 gtkmm 栈 + pulse 栈已拷入 awe（`.a` + 头 + pc + 生成 config 头）。
- **canberra patch 修正**：§3.2 结论"仅 1 处"**不准确**——实证 `src/sinkwidget.cc` 也大量用 canberra（`executeVolumeUpdate()` 的 `ca_gtk_play_for_widget`/`ca_context_playing`/`ca_context_change_device`）。实际 patch **4 处**：
  1. `configure.ac`：`PKG_CHECK_MODULES(GUILIBS,...)` 移除 `libcanberra-gtk$canberra_ver >= 0.16`；
  2. `src/pavucontrol.cc`：删 `#include <canberra-gtk.h>` + `ca_context_set_driver(ca_gtk_context_get(),"pulse")`；
  3. `src/sinkwidget.cc`：删 `#include <canberra-gtk.h>` + `executeVolumeUpdate()` 内 canberra 块（`char dev[64]`/`int playing`/`ca_*` 全段）；
  4. 保留 `configure.ac` 的 `canberra_ver` 赋值（未用，无害）。
- **构建**：`./configure --disable-gtk3 --enable-static --disable-shared --prefix=/usr/local/static/pavucontrol`（GTK2 模式，`HAVE_GTK3` 未定义；GUILIBS/PULSE 均 yes）→ `make` 编译 12 个 `.o` → **手动静态链**（geany 式 `xx-clang++ -static`）。
- **静态链 LIBS**（关键）：
  - gtkmm 栈：`-lgtkmm-2.4 -latkmm-1.6 -lgdkmm-2.4 -lgiomm-2.4 -lpangomm-1.4 -lglibmm-2.4 -lcairomm-1.0 -lsigc-2.0`
  - pulse 栈：`-L/usr/local/static/pulseaudio/lib -L.../pulseaudio -lpulse-mainloop-glib -lpulse -lpulsecommon-13.0`
  - GTK2 静态链（pcmanfm 验证的 `LIBS0`：`-lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lgdk_pixbuf-2.0 -lrsvg-2 -lcroco-0.6 -lpangocairo-1.0 -lpangoft2-1.0 -lpango-1.0 -lfontconfig -lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lfreetype -lpng -lXrender -lXcursor -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon -lintl -lfribidi -lharfbuzz -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi -lgmodule-2.0 -lgpg-error -lpixman-1 -ljpeg -luuid -lmount -lblkid -lXcomposite -lfontconfig -lcairo -lXdamage`）
  - **坑 1**：`make` 用 Makefile 的 `PULSE_LIBS`（无 `-lpulsecommon-13.0`）链接失败（`pa_log_level_meta`/`pa_init_i18n` 未定义）→ 手动链加 `-lpulsecommon-13.0` + `--start-group`。
  - **坑 2**：gtkmm 拉入 `gtkprintbackend.o`，其引用的 `_gtk_print_backend_file/lpr_{init,exit,create}` 在静态 libgtk 中**未定义**（GTK2 静态构建未含 print 后端）→ 提供 6 个**存根函数**（返回 0/NULL，pavucontrol 不用打印）。
  - **坑 3**：`gdkscreen/gdkcursor` 引用 `Xinerama/Xrandr/Xfixes` → 加 `-lXinerama -lXrandr -lXfixes`（同 pcmanfm 修复）。
  - **坑 4**：`libgcc_s.a` 缺失（`-static` 下 `-lgcc_s` 只有 .so）→ `cp libgcc.a libgcc_s.a`（geany 兜底）。
- **验证**：`file` = ELF x86-64 **statically linked, stripped**；`ldd` = "Not a valid dynamic program"（纯静态）；strings 含 **GTK_ICON_THEME / murrine / rsvg / GDK_PIXMAP**（主题+图标+SVG 支持，符合 awe 组装要求）。
- **数据**：`share/pavucontrol/pavucontrol.glade`（78K，GLADE_FILE 编译指向 `$prefix/share/pavucontrol/`）+ `share/applications/pavucontrol.desktop`。
- **注意**：`make install` 会重链 pavucontrol（Makefile 的 LIBS 缺 libpulsecommon）→ 已手装数据文件；二进制已在 `$prefix/bin/`。
- **构建脚本已落仓**（2026-11-05 全流程实测通过）：`compile/src/v-pavucontrol/build.sh`（`bash build.sh pavucontrol` 一键复现本节）+ `compile/src/v-pavucontrol/pavucontrol-canberra.patch`（4 处 canberra 去除）。关键点：① 源码 v3.0 tarball 无生成 configure → 先 `./autogen.sh`；② `PKG_CONFIG_PATH` 须含 `/usr/local/static/pulseaudio/lib/pkgconfig`（否则 PULSE=no 无 Makefile）；③ 手动链须 `-lpulsecommon-13.0`（Makefile PULSE_LIBS 只有公开 Libs）+ 打印后端存根 `.a` **放 `--start-group` 内**（放组外会被单遍链接器提前跳过致 6 个 `_gtk_print_backend_*` 未定义）；④ 数据文件（glade+desktop）手装（make install 重链失败）。

### 3.6、runtime 实跑验证（2026-11-05，hdmi 容器 Xvnc :464）

> 按 v-oth-impl01 §5（Greybird+Papirus 效果图两必要条件）套路，awe 编译 + runtime wrapper gtkrc。

- **运行**：`docker-hdmi-desktop-desktop-1`（Ubuntu 22.04 + TigerVNC），新起 Xvnc `:464` 1280x800 + openbox，以 **headless**（uid=1000）跑：
  ```bash
  export DISPLAY=:464 HOME=/_ext/home/headless \
         GTK2_RC_FILES=/tmp/greybird-papirus.gtkrc \
         GTK_DATA_PREFIX=/usr \
         PULSE_SERVER=/tmp/pulse-avS8fJ3Lnh9c/native
  /usr/local/static/pavucontrol/bin/pavucontrol
  ```
  wrapper `/tmp/greybird-papirus.gtkrc`：`gtk-theme-name="Greybird"` + `gtk-icon-theme-name="Papirus"`（Greybird 自带 gtkrc **无** icon-theme，不加→hicolor 灰图标）。
- **验证通过**：
  - ✅ 窗口 "Volume Control" 500x400（openbox 管理，IsViewable）
  - ✅ 日志空（无 gtkrc/glade/pulse 警告）→ pulse 连接成功（列设备）
  - ✅ **Papirus 图标渲染**：蓝 `(57,116,225)` 625 点 + 绿 `(76,175,80)` 90 点（Papirus 特征色，非灰 hicolor）
  - ✅ **Greybird 主题**：窗口灰底 `(217,217,217)` 主题化界面
- **效果图已推送**：`docs/img/tmp/v-pavucontrol/v1-pavucontrol-greybird-papirus.png`（500x400 特写）+ `v1-pavucontrol-fullscreen.png`（1280x800）。
- **注意**：pulse socket 在 `/tmp/pulse-avS8fJ3Lnh9c/native`（headless 属主，root 无法访问）→ 必须 headless 跑（PULSE_SERVER 免设，autospawn 自动发现，见 3.7）。

### 3.7、用 headless 已有环境启动的方法（2026-11-05 实测，**PULSE_SERVER 可免设**）

> headless 用户**已有**：Xvnc `:1`（depth 16, tcp，openbox+xfce4-power-manager 活跃桌面）、
> gtkrc `/_ext/home/headless/.gtkrc-2.0`（**已含** `gtk-theme-name="Greybird"` +
> `gtk-icon-theme-name="Papirus-Bunsen-bluegrey"`）、pulse daemon（PID 234，socket `/tmp/pulse-*/native`）。

- **PULSE_SERVER 可免设**（实测：静态版不设 PULSE_SERVER 也能连上，日志空、设备渲染、
  `ss` 见 ESTAB 到 `/tmp/pulse-avS8fJ3Lnh9c/native`、daemon pid 234）。**与 apt 动态版同机制**：
  libpulse 未设 `PULSE_SERVER` 时走 **autospawn**（`pulseaudio --start` → 凭 `~/.config/pulse/cookie`
  探测已运行的 daemon 并连其 socket），非直接找 `/tmp/pulse-*` 路径。
  ⚠️ 此前误判"必须设 PULSE_SERVER"：那是 `PULSE_SERVER=`（**空串**=无效显式服务器）所致；
  真正 **unset** 即走 autospawn，无需设。
- **已在 headless 桌面终端（DISPLAY/HOME 已设）**，直接：
  ```bash
  /usr/local/static/pavucontrol/bin/pavucontrol
  ```
- **从 root/docker 拉起 headless 会话**：
  ```bash
  su -s /bin/sh headless -c 'DISPLAY=:1 HOME=/_ext/home/headless \
    /usr/local/static/pavucontrol/bin/pavucontrol'
  ```
- **实测**（:1，无 PULSE_SERVER）：窗口 500x400 显示、日志空、`ss` ESTAB pulse 连接、
  Papirus-Bunsen-bluegrey 图标（绿 `(76,175,80)` 538 点）+ Greybird 灰底、2044 色设备列表渲染 ✅。
- **gtkrc 免设**：headless 已有 `~/.gtkrc-2.0` 即 Greybird+Papirus-Bunsen-bluegrey，`HOME=/_ext/home/headless` 下 GTK2 自动加载（无需 wrapper）。若想换 Papirus 主集，可 `GTK2_RC_FILES` 指向 wrapper。
- **`GTK_DATA_PREFIX` 也可免设**（对照 lxtask 文档"必须 /usr"的修正）：
  - 静态 libgtk 的 `GTK_DATA_PREFIX` 宏**烤死 `/usr/local`**（u-gtk configure 无 `--prefix`）→
    `strings` 见 `/usr/local/share/locale`、`/usr/local/etc`。
  - 但**主题/图标查找走 XDG 系统数据目录**（`g_get_system_data_dirs()`），二进制内置
    `/usr/local/share/:/usr/share/`（`strings` 实见）→ 遍历到 `/usr/share/themes` 的 Greybird、
    `/usr/share/icons` 的 Papirus-Bunsen-bluegrey，**无需 `GTK_DATA_PREFIX=/usr`**。
  - 实测 :1 只设 `DISPLAY+HOME`（无 GTK_DATA_PREFIX、无 PULSE_SERVER）：Greybird
    `(216,216,208)` 暖灰 + Papirus-Bunsen-bluegrey 图标（绿 `(76,175,80)` 538 点）渲染成功 ✅。
  - lxtask 文档的 `GTK_DATA_PREFIX=/usr` 场景是 box/musl 容器（主题未在 XDG 搜索路径或
    引擎缺失）；ubt22 runtime 主题在 `/usr/share`（XDG 第二项），免设即通。

## 三、音量 tray 图标（pasystray/pnmixer）选型（2026-11-06）

### 1、pasystray 0.8.2 主选、pnmixer 排除 + 业界替代品（2026-11-06 用户要求新看）

> 背景：pavucontrol 是完整音量 GUI；用户另要一个**系统 tray 常驻图标**（滚轮调音量/静音、
> 点开菜单）。本小节结合本篇已建静态地基，评估 pasystray / pnmixer 静态编译本选用与依赖准备，
> 并盘点业界其他可选 / 更受欢迎的音量 tray 工具。

#### 1.1、已有家底（可直接复用，来自本篇 §3.4）

- **libpulse 静态客户端库已构建**（§3.4，pulseaudio 13.0）：`libpulse.a`(669K)、
  `libpulse-simple.a`(16K)、`libpulse-mainloop-glib.a`(20K)、`libpulsecommon-13.0.a`，
  头 + `libpulse*.pc` 齐全，装入 `builder-obox:/usr/local/static/pulseaudio`。
- **GTK2 2.24.33 静态**（u-gtk）已就位；libX11 等基础库在。
- **gtkmm 栈**（§3.3）已建——但 **pasystray / pnmixer 均用不到**（二者是纯 C/GTK2，非 gtkmm）。

#### 1.2、pasystray（推荐，PulseAudio 原生）— 版本 0.8.2 ✅ 已实现

- **最新 0.8.2**（2024 起入 Arch/Fedora/Debian 稳定，Ubuntu 25.10 也是 0.8.2-1.1）；
  AUR 明确分 `pasystray-gtk2-git` / `pasystray-git`(gtk3) 两包 → **源码保留 GTK2/GTK3 双后端**
  （configure 检测，可强制 gtk2）。
- **⚠️ 待核实**：0.8.2 的 `configure.ac` 是否仍可 `--without-gtk3`；若已砍 gtk2 分支，退 0.7.1。

> **订正（2026-11-06）**：0.8.2 `configure.ac` **保留 GTK2 分支**，参数是 **`--with-gtk=2`**
> （**不是** `--without-gtk3`），无需退 0.7.1。详见 §2.1。
- **依赖对照**：

| 依赖 | 本项目状态 |
|---|---|
| gtk2 | ✅ 2.24.33 静态 |
| libpulse + libpulse-mainloop-glib | ✅ **已构建**（§3.4） |
| libX11 | ✅ |
| libnotify | ⚠️ 需建静态 或 `--disable-notify`（仅通知，可去） |
| avahi | ⚠️ 需建静态 或 禁用（zeroconf 网络发现，非必需） |

- **结论**：pasystray 依赖几乎全免，只需 libnotify / avahi 二选一（建或禁），是最省力的 PA 原生 tray。

#### 1.3、pnmixer — 不建议（ALSA-only，无 PA 后端）

- 最新 0.7.2（0.7 起 CMake，`WITH_GTK3`/`WITH_LIBNOTIFY`/`ENABLE_NLS`）。
- **README 明言**："designed to work on systems that use **ALSA**… There is **no official
  PulseAudio support**… **PulseAudio support will likely not happen**."
- **硬依赖 alsa-lib（libasound）**，需另建一条 ALSA 静态链；且它直接控 ALSA，
  **绕过本项目的 PULSE_SERVER** → 音量与 PA 状态脱节（README 还列了 PA 下 unmute 异常等已知问题）。
- **本项目音频栈是纯 PulseAudio**（pulseaudio 静态 + `/tmp/pulse-*/native` socket），
  pnmixer 方向相反 → **不选**。

#### 1.4、业界其他可选 / 更受欢迎的音量 tray 工具

| 工具 | 后端 | 状态 | 评价 |
|---|---|---|---|
| **pasystray** | **PulseAudio** | 活跃（0.8.2 各发行版打包，472★） | ✅ **PA 原生首选**，PulseAudio 官方文档明确替代已废弃的 padevchooser |
| **volumeicon**（Maato） | **ALSA** | 0.5.1（2015），**GitHub 已 ARCHIVED**，189★ | tint2 时代很火，但 ALSA-only、不再维护，**非 PA** → 不适合 |
| **pnmixer** | ALSA | 0.7.2，**无 PA 后端** | 如上，不适合 |
| gvolwheel（Junker） | ALSA+**libpulse** | GTK2，小众 | PA 场景可作 gtk2 备选（pasystray gtk2 构建失败时） |
| volctl | PulseAudio | GTK3 | gtk3，不符静态 gtk2 栈 |
| MicTray | PulseAudio | GTK3，仅麦克风 | 不对口 |
| xfce4-pulseaudio-plugin / mate-volume-control | PulseAudio | 面板插件 | 需 panel；我们只有 tint2 **独立 tray**，不适用 |
| pavumeter / paman / padevchooser | — | 已废弃/过时 | PulseAudio 官方点名不用 |

#### 1.5、结论建议

- **主选：pasystray 0.8.2**（GTK2 后端）——复用已建 libpulse 静态，仅需补 libnotify
  （或 `--disable-notify`）+ 禁 avahi，工程量最小。
- **备选：gvolwheel**（GTK2 + libpulse）——若 0.8.2 的 gtk2 分支不可用。
- **pnmixer 排除**（ALSA-only、无 PA 后端、需另建 alsa 链且音量与 PA 脱节）。
- 业界更受欢迎的 PA tray 即 **pasystray**；volumeicon/pnmixer 火在 ALSA 时代，均已不契合本项目的纯 PulseAudio 栈。
- **下一步**：核实 pasystray 0.8.2 `configure.ac` 的 gtk2 分支（决定 0.8.2 或退 0.7.1），
  再落 `compile/src/v-pasystray/build.sh`。

> **订正（2026-11-06）**：已完成——0.8.2 gtk2 分支可用、`build.sh` + 补丁落仓、runtime 实跑通过，
> 详见 §2。

---

### 2、pasystray 0.8.2 静态构建实现与调试（2026-11-06 完成，builder-awe）

> 承接 §1 选型：主选 pasystray 0.8.2。本节记录 configure 核实、make 失败、手动静态链、
> **glade 类型注册崩溃修复**、runtime 实跑、落仓明细。

#### 2.1、configure.ac 核实（订正 §1.2 的"待核实"）

- 0.8.2 `configure.ac` **保留 GTK2 分支**，参数是 **`--with-gtk=2|3`**（默认 3，选 2 走 GTK2）。
- 可选组件：`--disable-avahi` / `--disable-notify` / `--disable-appindicator` / `--disable-x11`；
  默认 avahi/notify/appindicator 开启，**须显式禁**（静态链无对应库）。
- `PKG_CHECK_MODULES(PULSEAUDIO, [ libpulse >= 1.0 libpulse-mainloop-glib >= 1.0 ])` — pulse 13.0 满足。
- `--with-gtk=2` → `GTK_VERSION=gtk+-2.0`、`GLADE_FILE=$(pkgdatadir)/pasystray.gtk2.glade`。

#### 2.2、构建（builder-awe，GTK2 静态）

- 源码：`git clone github.com/christophgysin/pasystray`（tag **0.8.2**，commit `3d6e00d`）。
- autogen：`aclocal && autoconf && autoheader && automake --add-missing`
  （`AC_HELP_STRING` 过时警告，无碍）。
- configure：`--with-gtk=2 --disable-avahi --disable-notify --disable-appindicator
  --prefix=/usr/local/static/pasystray`，结果 `GTK=gtk+-2.0`、`PULSEAUDIO=yes`、`X11=yes`。
- make：**链接必然失败**（RC=2）——`PULSEAUDIO_LIBS` 缺 `-lpulsecommon-13.0`
  （`pa_log_level_meta`/`pa_init_i18n`/`pa_snprintf`/`pa_loop_write` 未定义）；**13 个 `.o` 已产出**。

#### 2.3、手动静态链（xx-clang -static）

- 用 Makefile 产出的 **13 个 `.o`** + `--start-group` 全组静态链；**必须显式加**：
  - `-lpulsecommon-13.0`（Makefile 漏掉 → 上述 4 个符号）；
  - `-lcairo`（pkg-config `gtk+-2.0` 末尾有，但手写链易漏）；
  - `-lXinerama -lXrandr -lXfixes`（漏掉 → **2350 个 undefined**：`cairo_*`/`XFixes*`/`XRR*`/`Xinerama*`）。
- 产物：**13.7M stripped 静态 ELF**；`xx-verify --static` 通过；`ldd` 报 "Not a valid dynamic program"。

#### 2.4、glade 类型注册崩溃（关键坑，实测）

- **症状**：启动即崩，rc=133（SIGTRAP），stderr：
  `pasystray-ERROR **: [ui] Invalid object type 'GtkMessageDialog'`。
- **根因**：GtkBuilder 解析 glade object class 用 `g_type_from_name()`，**只认已注册的 GType**；
  静态链下 widget `.o` 被代码引用拉进（`gtk_message_dialog_set_markup` 引用同一 `.o`），
  但 `get_type()` **从不在运行时被调用** → 类型未注册 → glade 加载失败。
- **修复**：patch `src/ui.c` 在 `gtk_builder_add_from_file()` 前注册 glade 用到的 7 类
  （`GtkButton`/`GtkDialog`/`GtkEntry`/`GtkHButtonBox`/`GtkLabel`/`GtkMessageDialog`/`GtkVBox`）。
  **关键**：`gtk_*_get_type()` 被 gcc 当 **pure/const**，**裸调用语句会被折叠掉**（编译出
  `-Wunused-value: statement with no effect`，`.o` 里没有该调用）；必须**用 `volatile` 存返回值**
  强制调用。补丁：`compile/src/v-pasystray/pasystray-glade-types.patch`。

#### 2.5、runtime 实跑（hdmi 容器 Xvnc）

- 环境：Xvnc `:804` 1280x800 + tint2（systray 宿主）+ headless 用户
  `PULSE_SERVER=/tmp/pulse-avS8fJ3Lnh9c/native`（`pulse` socket 已存在）。
- **结果**：进程存活、stderr **空**（无 "Invalid object type"）、`xwininfo -root -tree` 见
  `0x400003 "PulseAudio system tray" 48x48`（tray 图标窗口渲染）→ **通过**。

#### 2.6、落仓

- `compile/src/v-pasystray/build.sh`（复用 v-pavucontrol 的静态链模式：make 取 `.o` + 手动
  `xx-clang -static`）+ `pasystray-glade-types.patch`。
- 版本定稿：**0.8.2**（`--with-gtk=2` 可用，无需退 0.7.1）；`vers.txt` 增 pasystray 条目。

### 3、中文支持（zh_CN，2026-11-07 用户问"有现成中文 mo 吗"，没有就自建）

> 承接 §2 落仓（0.8.2 静态可用）。用户问"有现成中文 mo 文件吗"——实测**没有**，于是
> 自建 gettext i18n。本节记录调查、实现、验证与落仓。

#### 3.1、调查：上游无 i18n 基础，无现成中文 mo

- **无 `po/` 目录**、无 `LINGUAS`；`configure.ac` 无 `AM_GNU_GETTEXT`/`AC_PROG_INTLTOOL`。
- 源码仅 About 对话框 **3 处 `_()`**，且 `main()` **从不**调 `bindtextdomain`/`textdomain`/`setlocale`。
- **Ubuntu 24.04 / Debian 包内均无 pasystray 的 `.mo`**（不 ship NLS）；0.8.2 全上游版本
  亦无翻译基础设施。
- 用户可见字符串全部硬编码英文：根菜单/子菜单（`Default _Server`、`Default S_ink`、
  `Volume _Control...` 等）、`Rename`/`Unload`、` [muted]` 后缀、About 对话框。
- **结论**：要中文必须自建 gettext——初始化 + `_()` 包裹 + 自写 `.po` 编译 `.mo`。

#### 3.2、实现（gettext 静态）

- **初始化**（patch `src/pasystray.c` `main()` 开头）：
  ```c
  setlocale(LC_ALL, "");
  bindtextdomain(GETTEXT_PACKAGE, LOCALEDIR);
  textdomain(GETTEXT_PACKAGE);
  ```
  `LOCALEDIR` 硬编码 `/usr/local/static/pasystray/share/locale`（与 `--prefix`/TARGETPATH 一致）。
- **`_()` 生效前提**：**先 `#define ENABLE_NLS 1` 再 `#include <glib/gi18n.h>`**（否则 `_()`=恒等，不翻译）。
- **包裹**：`systray.c`（根/子菜单、` [muted]`、Rename/Unload）、`menu_info.c`（rename 对话框、
  module-device-manager 提示）、`pasystray.c`（About）共 **30 处 `_()`**。
- **msgid 是 mnemonic 原文**：GTK 菜单文本带 `_` 加速键（如 `Default _Server`），`_()` 的 msgid
  含 `_`；翻译查找按**含 `_` 原文**，GTK 显示时去 `_`。故 `.po` 的 msgid 须与源码字符串完全一致。
- **链接**：`-lintl` 已在静态链命令（builder 有 `/usr/lib/libintl.a`，含
  `gettext`/`bindtextdomain`/`textdomain`；产物 `strings` 可 grep 到）。
- **`.mo` 安装**：`build.sh` 在装数据后 `msgfmt -c -o <dest>/zh_CN/LC_MESSAGES/pasystray.mo zh_CN.po`
  （builder msgfmt 0.21）；`.po` 放 `compile/src/v-pasystray/zh_CN.po`。

#### 3.3、验证（hdmi 容器 Xvnc :808）

- `.mo`：python `gettext` 读 30 条 msgid→msgstr **全部翻译成功**（`Default _Server`→默认服务器、
  `About`→关于、`Quit`→退出、` [muted]`→[静音]、`Rename`→重命名...）。
- **PIL 像素对比**（zh 截图 vs 之前 en 截图，均 1280x800）：
  `menu` bbox(866,7,1261,376) **136K px 差异**（整菜单文本变）、`about` 1.2K 差异（对话框标题→关于）、
  `base` 仅托盘图标 108px（几乎相同）→ **翻译生效**。
- 运行环境：`LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8` + **wqy-microhei**（CJK 字体，
  hdmi 已有）+ `zh_CN.utf8` locale（已生成）。
- 截图：`docs/img/tmp/v-pasystray/v2_zh_{base,menu,about}.png`。

#### 3.4、落仓

- `compile/src/v-pasystray/pasystray-i18n.patch`（新）、`zh_CN.po`（新，30 条）、`build.sh`（改：
  应用 i18n 补丁 + msgfmt 装 .mo）。
- **补丁顺序**：先 glade-types、后 i18n（i18n 基于 glade-patched 源码生成）。
- **运行前置**：`.mo` 在 `$TARGET/share/locale/zh_CN/LC_MESSAGES/pasystray.mo`；应用侧设
  `LANG/LANGUAGE/LC_ALL=zh_CN.UTF-8` 并有 CJK 字体即可出中文。

#### 3.5、验证流程实录：环境→运行→定位 tray→操作→截图（2026-11-07 hdmi Xvnc :808 实测）

> 用户要求"从准备环境到运行、定位 tray 图标、操作菜单项、到截图"的完整过程落文档。
> 本节按实测流程逐段记录，含工具/脚本与**掉过的坑**。通用套路另见 AGENTS.md §3.1（Xvnc 调试）。

##### 3.5.1、准备环境

- **前提检查**（hdmi 容器 `docker-hdmi-desktop-desktop-1`）：
  - CJK 字体：`fc-list | grep -iE "cjk|wqy"` → **wqy-microhei.ttc** 在（无则中文字显示豆腐块）。
  - locale：`locale -a | grep zh` → `zh_CN.utf8` 已生成（无则 `setlocale` 静默失败→回英文）。
  - pulse：`ls -d /tmp/pulse-*/native` + `pgrep pulseaudio` → socket 存在、进程在跑。
  - 部署：`docker cp <bin> <容器>:/usr/local/static/pasystray/bin/` + `.mo` 到
    `.../share/locale/zh_CN/LC_MESSAGES/`。
- **display 号**：每次换新（如 `:808`），先 `rm -f /tmp/.X$DISP-lock /tmp/.X11-unix/X$DISP`，
  再 `ss -tlnp | grep 6708` 确认端口空。

##### 3.5.2、运行

- 顺序：**Xvnc → openbox(WM) → tint2(面板+systray) → pasystray**（tint2 必须在 openbox 后）。
- Xvnc：`Xvnc :808 -geometry 1280x800 -depth 24 -SecurityTypes None -localhost -ac &`；
  `xprop -root` 连通性门。
- GUI 程序以 **headless 用户**跑：`su -s /bin/bash headless -c "nohup env HOME=... DISPLAY=:$DISP ... &"`；
  pasystray 需 `PULSE_SERVER=/tmp/pulse-*/native`。
- **中文三件套**：`LANG=zh_CN.UTF-8 LANGUAGE=zh_CN:zh LC_ALL=zh_CN.UTF-8`（仅设 LANG 可能不够）。

##### 3.5.3、定位 tray 图标

- `xdotool search --name "PulseAudio"` → WID（GTK StatusIcon 的 XEmbed 窗口名
  `"PulseAudio system tray"`，48x48）。
- `eval $(xdotool getwindowgeometry --shell $WID)` → 取 X/Y/WIDTH/HEIGHT，中心点
  `CX=X+W/2, CY=Y+H/2`；`xdotool mousemove $CX $CY click 1` **单击**打开根菜单。

##### 3.5.4、操作菜单项

- **打开 About**：菜单弹出后（GTK 菜单 grab 键盘），`xdotool key Down Down ... Return`（**9 次 Down**
  到 About 项 + Return 激活；位置 9 = About）。其他项同理按序 Down。
- 截图时机：`sleep 1` 让菜单/对话框渲染完。

##### 3.5.5、截图与验证

- `scrot $XDIR/v2_zh_base.png`（全屏 1280x800）→ 菜单 → About。
- **验证翻译生效**（无 OCR 工具时）：
  - `python3 gettext` 读 `.mo`：`gettext.translation('pasystray', localedir=..., languages=['zh_CN'])`
    逐条 `gettext(msgid)`；**msgid 必须带 mnemonic `_`**（如 `Default _Server`，否则查不到→回英文）。
  - **PIL 像素对比** en/zh 同尺寸截图：`ImageChops.difference(a,b).convert('L').getbbox()` +
    histogram；`menu` 区域大差异（整菜单文本变）→ 翻译生效；`base` 仅托盘图标差异（几乎同）。

##### 3.5.6、工具/脚本清单

- 工具：Xvnc(TigerVNC 1.13.1)、openbox、tint2、pasystray、xdotool、scrot、xwininfo、xprop、
  pgrep/ss、su、nohup、msgfmt、python3(PIL/gettext)。
- 脚本：容器内 `/tmp/ps-zh-shot2.sh`（完整流程：Xvnc 后台记 PID→openbox→tint2→pasystray→
  scrot base→xdotool 定位+click→scrot menu→Down×9+Return→scrot about→cleanup）。关键模板：
  ```sh
  Xvnc ":$DISP" ... & XVNC_PID=$!; sleep 3; xprop -root || exit 1
  su -s /bin/bash headless -c "nohup env ... DISPLAY=:$DISP tint2 &"
  su -s /bin/bash headless -c "nohup env ... DISPLAY=:$DISP LANG=... PULSE_SERVER=... pasystray &"
  WID=$(xdotool search --name "PulseAudio" | head -1); eval $(xdotool getwindowgeometry --shell $WID)
  xdotool mousemove $((X+W/2)) $((Y+H/2)) click 1; scrot menu.png
  xdotool key Down ... Return; scrot about.png
  kill -9 $XVNC_PID; rm -f /tmp/.X$DISP-lock /tmp/.X11-unix/X$DISP
  ```

##### 3.5.7、掉过的坑 / 注意项（实测）

1. **docker exec 输出被吞**（AGENTS.md §3.1 已载）：容器内启动后台进程后，docker exec 的
   stdout 可能不再回传。**对策**：验证脚本用 `nohup bash script >/tmp/x.log 2>&1 &` 启动，
   脚本内 `exec >$XDIR/run.out`，轮询/单独 `cat`。
2. **`pkill -9 -f "Xvnc :$DISP"` 自杀**：pkill -f 匹配自身命令行（含该串）→ 脚本被 SIGKILL。
   **对策**：启动时记 `XVNC_PID=$!`，清理 `kill -9 $XVNC_PID`；其他进程用 `pkill -x <名>`。
3. **`ps|grep "[X]vnc"` 误匹配自身**：docker exec 的 `bash -c` 命令行含 `Xvnc :806` 字面量，
   awk/grep 匹配到 bash -c 自己 → 误杀。**对策**：不用 grep 清 Xvnc，用 `ss -tlnp | grep 670x`
   查端口占用人 PID，直接 `kill <PID>`。
4. **Xvnc 端口冲突**：Xvnc :N 端口 = `5900+N`（:806→6706）。残留 Xvnc 占端口 → 启动报
   `(EE) vncExtInit: failed to bind socket: Address in use (98)`。**对策**：先清理残留/换 display 号。
5. **残留 Xvnc 占内存/端口**：验证前清理非 live 的旧 Xvnc（保留 `:1` xrdp live 会话）。
6. **同号重起**：不删 `/tmp/.X<NN>-lock` + `/tmp/.X11-unix/X<NN>` → "Another server is already running"。
7. **PULSE_SERVER 必须指向存在的 socket**：`/tmp/pulse-avS8fJ3Lnh9c/native`（pulseaudio 进程在跑）。
8. **CJK 字体 + zh_CN locale 缺一不可**：缺字体→豆腐块；缺 locale→setlocale 失败→回英文。
9. **托盘图标窗口名**：`PulseAudio system tray`（search 用子串 "PulseAudio" 即可）。
10. **About 是第 9 项**：键盘 Down×9 + Return（菜单 grab 键盘，无 `--window`）。
11. **验证截图别只靠 size**：`v2_zh_menu.png` 与 en 版 size 相近，须 PIL 像素对比确认差异
    在菜单区域（bbox）才可信。

> **订正（2026-11-09）**：构建基底镜像已由 `alpine-builder-gtk224` 更名为 `alpine-builder-gtk224-2`（buildx.sh `img=` / `Dockerfile` FROM / syncer 同步映射同步更新），后续构建以 -2 为准。
