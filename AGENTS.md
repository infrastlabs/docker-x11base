# AGENTS.md

`docker-x11base`（多发行版 headless X11 容器 + 静态组件构建）的智能体工作手册。给后续 AI
智能体（及协作者）看：**项目是什么、怎么构建、操作时遵守什么规则、踩过哪些坑**。

---

## 一、路径

- **项目根目录**：`/_ext/home/headless/xm-zs01/docker-x11base`
- **构建脚本**：`compile/src/` —— `common.sh`（共享环境）、`Dockerfile`（多阶段构建）、
  `vers.txt`（源登记）、每组件一个子目录（`openbox/`、`tint2/`、`v-lxde/`、`v-pcmanfm/`、
  `u-gtk/`、`v-feh/`、`v-geany/`、`v-xlunch/`、`suckless/`、`fluxbox/`、`x-xrdp/`、
  `x-tigervnc/`、`x-x11vnc/`、`x-dropbear/`、`x-pulseaudio/`、`xcompmgr/`、`xdpyprobe/`、`u-misc/`、`_ex/`）
- **分析文档**：`docs/` —— `desk/lxde/`、`desk/`、`2026/`、`confs/`、`core/`、`wm/`
- **下游 rootfs**：`rootfs/`；**发行版**：`distros/`；**包**：`pkgs/`
- **运行/部署**：`docker-compose*.yml`、`.github/workflows/`

## 二、项目介绍

- **项目**：`infrastlabs/docker-x11base` 的本地仓库，构建多发行版
  （alpine/ubuntu/opensuse/busybox/openwrt/debian/fedora）的 headless X11 镜像；窗口管理器/
  桌面组件以 **musl 静态链接**产出，可在任意发行版直接运行。
- **远程**：Gitea `sam-dev.local:3000/g-dev1/docker-x11base`（工作分支 `feat/ai-260925`，
  上游 `dev`）；亦镜像到 github `infrastlabs/docker-x11base`。
- **构建模型**：
  - 组件在 `alpine-builder-gtk224-2` 镜像（`infrastlabs/x11-base:alpine-builder-gtk224-2`）内构建，
    产物隔离安装到 `/usr/local/static/<comp>/`（openbox、lxde、tint2、pcmanfm…）。
  - `common.sh`：`CC=xx-clang`、`LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"`、
    `down_catfile`（curl 缓存下载）、`oneBuild`（包装函数）、`GITHUB` 默认 `https://github.com`。
  - `vers.txt` 一行一组件：`名称|版本|克隆或下载命令`（常引用 `$GITHUB` 变量）。
  - 交叉调用：`bash /src/v-tint2/build.sh librsvg` 调对方脚本里的函数；`b_deps` 分支负责先编依赖。
  - 验证工具：`xx-verify --static <bin>`（容器内 `/usr/bin/xx-verify`）。
- **构建容器**（验证/复现用，`docker ps` 常驻）：`builder-obox`、`builder-awe`
  （均 `alpine-builder-gtk224-2`）；`docker-hdmi-desktop-desktop-1`（`app-ubuntu-22.04`，
  用于跨发行版实跑）。构建容器里 `/src` = **软链** → 宿主
  `/_ext/home/headless/xm-zs01/docker-x11base/compile/src`（两容器一致；软链**实时反映宿主改动**，
  改完脚本**无需再 `docker cp` 进容器**，直接 `docker exec <容器> sh /src/<comp>/build.sh <组件>`）。
  注意：`/_ext` 是宿主机项目目录的 bind mount；`/src` 本身**不是** bind mount，是**容器态软链**
  （builder-obox 与 builder-awe 各手动创建；若容器重建需重新 `ln -s ... /src`，因镜像内 `/src`
  是烘焙目录/可能缺失，非镜像自带软链）。
- **静态组件清单**：openbox、fluxbox、suckless(st/dwm)、tint2、pcmanfm、geany、xlunch、
  xcompmgr、lxtask、lxappearance、tigervnc、xrdp、x11vnc、dropbear、pulseaudio、perp…

- **组件目录前缀分类规则（2026-11-07 用户拍板）**：
  - `v-xxx`：**GTK2 应用**（链 gtk+-2.0），如 v-lxde、v-geany、v-pcmanfm、v-pasystray、
    v-pavucontrol、v-sysmonitor、v-gpicview、v-ibus、v-engrampa、v-xfce4。
  - `w-xxx`：**imlib2 应用**（链 imlib2，非 GTK），如 w-feh、w-scrot、w-xlunch、w-tint2、w-hsetroot。
  - `x-xxx`：**基础应用/组件**（底层，非 GTK 非 imlib），如 x-dbus、x-dunst、x-xrdp、x-tigervnc、
    x-x11vnc、x-pulseaudio、x-dropbear、x-xbindkeys、x-xrandr、x-rofi、xcompmgr、xdpyprobe。

## 三、智能体操作行为规则（必须遵守）

### 1、提交粒度：一个一个提交

- **每个 md 文档单独一个 commit**；**每个脚本/配置文件单独一个 commit**
  （如 `compile/src/v-lxde/build.sh`、`compile/src/common.sh`、`compile/src/Dockerfile`、
  `AGENTS.md` 各一），禁止串提。
- **改文档 + 改代码拆成两个 commit**（先文档、后代码，或按用户指定顺序）。
- **提交信息首行以文件路径开头**（参考仓库既有提交风格）：
  - `build/src/v-lxde/build.sh # 260926: lxtask 静态构建收口——...`
  - `docs/2026/260926-lxtask-解析与优化.md: 2026-11-04 复核修正——...`

### 2、文档规范

- **章节编号**：二级 `## 一、`，三级 `### 1、`（历史文档用 `### 1.` 亦可，与仓库既有体例一致即可），
  四级 `#### 1.1、`（1.x.x 小节；AGENTS 原只规定到三级，2026-11-06 补写）。
- **文档历史不动**：新结论用 `> **订正（日期）**：...` 或 `✅/⚠️` 标注追加，**不改删旧结论**。
- **先落文档再给结论**：新结论/命令/决策先写进相应文档，再回复用户。
- 相关分析：`docs/2026/260926-openbox-解析与优化.md`（openbox 全功能静态，章节已定型，
  含 8.4 oneBuild 失效、五章 落仓改动明细）；`docs/2026/260926-lxtask-解析与优化.md`
  （一、现状与待办；二、静态构建图标/主题失效问答实录）。

### 3、验证（构建类）

- **改完必须实跑**：在构建容器里 `docker exec builder-obox sh /src/<comp>/build.sh <组件>`，
  别只静态阅读下结论。
- **判成功别信 `oneBuild`**：`oneBuild` 用 `set +e` + 判 `find` 退出码 + `|tee` 管线，
  失败被吞成 `err 0, pass`。自己用 `xx-verify --static $ROOT_DEST_DIR${INS_PREFIX}/bin/<产物>`
  + `grep -c "undefined reference\|attempted static link" <日志>` 兜底（结果 =0）。
- **错误传播**：`CONSOLE_LOG=no`（Dockerfile 构建用）时脚本内 `exit 1` 可传出
  （`sh build.sh <c>` 非 0）；`CONSOLE_LOG=yes`（手动调试）时 `oneBuild` 的 `|tee` 管线会屏蔽，
  靠日志 + xx-verify。
- **产物核对**：`file` 应为 `statically linked, stripped`；`ldd` 应报 `Not a valid dynamic program`；
  装后路径 `$ROOT_DEST_DIR${INS_PREFIX}/bin/<产物>`（`ROOT_DEST_DIR="/"`、`INS_PREFIX=$TARGETPATH`）。

### 3.1、Xvnc 调试套路（GUI/多屏/主题类验证，规则自 fk-awesomewm AGENTS.md 引入）

> **前提**：**Xvnc 只在 Ubuntu 运行容器 `docker-hdmi-desktop-desktop-1`（TigerVNC 1.13.1）有**；
> Alpine 构建容器（`builder-obox`/`builder-awe`）**没有 Xvnc**，只有 Xvfb。所以 GUI 验证一律去
> hdmi-desktop 容器做。规则来源：`fk-awesomewm/AGENTS.md`「三、调试套路」（用户 2026-10-24 拍板
> 「验证一律用 Xvnc，不再用 Xvfb」）。

- **验证环境一律用 Xvnc（TigerVNC 1.13.1），不用 Xvfb**：Xvfb 与真机 RandR/shape 行为有差异
  （`--setmonitor` 无效、单 CRTC），Xvnc 与真实 xrdp 会话同源。
- **探针一律开全新 display 号，禁止复用 live 会话 `:1`**（hdmi 里 `:1` 是 xrdp→Xvnc live 会话，
  一直在跑）。先 `ls /tmp/.X11-unix/` 挑空号，**每次换号**（root 残留壁纸会污染对比结果）。
- **spawn 模板**（免密码 = `-SecurityTypes None`；`-ac` 关访问控制；TigerVNC 用 `-geometry` 不是 `-screen`；
  **`-nopw`/`-forever` 在 1.13.1 不存在**，加了直接启动失败；`-depth 24` 统一）：
  ```sh
  DISP=311   # 每次换号
  Xvnc ":$DISP" -geometry 1280x800 -depth 24 -SecurityTypes None -localhost -ac \
    </dev/null >/tmp/xvnc-$DISP.log 2>&1 &
  sleep 2
  DISPLAY=:$DISP xprop -root >/dev/null || echo "!! Xvnc 没起好"   # 连通性门
  DISPLAY=:$DISP HOME=/root timeout -s KILL 8 <被验二进制> >/tmp/out.txt 2>&1; echo "rc=$?" >> /tmp/out.txt
  pkill -f "Xvnc :$DISP"; rm -f /tmp/.X$DISP-lock /tmp/.X11-unix/X$DISP
  ```
- **清理坑**：`pkill -f Xvnc` 会杀外层 `bash -c`（自匹配），必须带 display 号限定
  `pkill -f "Xvnc :$DISP"`；用完清 `/tmp/.X<NN>-lock`（单文件）和 `/tmp/.X11-unix/X<NN>` socket，
  否则同号重起报 "Another server is already running"。
- **docker exec 输出被吞**：脚本输出重定向到文件，单独一次 exec `cat`；或用
  `nohup bash -c '... > /tmp/x.log 2>&1 &'` 再轮询 log。探针/临时文件放 `/tmp`，别落仓库。
- **容器→宿主文件中转（2026-11-14 用户拍板，强制遵守）**：容器写宿主文件**统一用 `sudo` 写 `/_ext/tmp/` 中转**
  （宿主 `/_ext/tmp` 为 777），宿主导读；**写失败就一直重试（拆成一条命令一个动作循环跑）**；
  **禁止 `docker export` 容器**（重、用户明确禁止）；`docker cp` 在本机 mount 故障（ENOSPC）也不可用。
- **容器内编译调试 `/src`（2026-11-14 补充）**：构建容器内 `/src` **软链 → 宿主 `/_ext/.../compile/src`**
  （实时反映宿主改动，改脚本无需 `docker cp`）；镜像烘焙的 `/src` 是**旧真实目录**，
  须 `rm -rf /src && ln -s 宿主compile/src /src` 重建（否则用旧脚本，修复不生效）。
- **复杂容器命令用脚本文件化（2026-11-14 追加，用户拍板）**：多步骤/易出错的容器命令
  **写成 `/_ext/tmp/svg/t_xx.sh`（宿主），容器内 `docker exec <c> bash /_ext/tmp/svg/t_xx.sh` 执行**，
  结果写回 `/_ext/tmp/svg/`（脚本内重定向 + 末尾 `DONE` 标记，宿主导读）；
  避开单条 exec 长命令/拼接被丢、stdout 被吞等坑（本模式实测稳定）。

### 3.2、TARGETPATH：本地调试与 CI 构建两个入口（2026-11-08 补，pavucontrol 教训）

- **build.sh 禁止硬编码 `export TARGETPATH=...`**：二进制把 `PKGDATADIR/LOCALEDIR`（由 `--prefix`
  派生）编进去，`TARGETPATH` 必须由调用方传入且与部署路径一致，否则运行时找不到数据文件
  （pavucontrol 教训：未设退回 common.sh 默认 `static_temp1`，glade 找不到 → `Glib::FileError` 崩溃）。
- **两个入口**：
  - **本地调试**：调用前环境变量传入——`TARGETPATH=/usr/local/static/<comp> sh /src/<comp>/build.sh <comp>`。
  - **CI 构建**：`compile/src/Dockerfile` 每 stage 以 `TARGETPATH=/usr/local/static/<comp>` 作为
    RUN 前缀/ENV（如 pavucontrol stage 已设）。改 prefix 只在 Dockerfile 加，别动 build.sh。
- **改 prefix 后必须清 `.o` 重编**：configure 只更新 Makefile 的 `-DPKGDATADIR`，`.o` 不会自动重编
  （`.cc` 比 `.o` 旧 → make 跳过）；删 `src/*.o` 再跑 build.sh，否则链接出的仍是旧路径。
- **验证须在最终部署路径实跑**：别只信 builder `static_temp1` 上的结果；部署后必须用
  `strings <bin> | grep <数据文件>` 核对编入路径 + 实跑。

### 4、不要做的事 / 避坑

- **别覆盖 `LDFLAGS`**：`make LDFLAGS="-static "` 会丢掉 `common.sh` 的
  `-Wl,--strip-all`/`--as-needed`（实测产物 35.9M 未 strip）。应 `make LDFLAGS="$LDFLAGS"` 或追加。
- **静态传递依赖必须 `--start-group`**：`-lXinerama -lXfixes -lXrandr` 等必须在 group 内
  （放外会剩 21 个 `XFixes*`/`XRR*` undefined）；整组
  `LIBS="-Wl,--start-group ... -Wl,--end-group"` 最稳。
- **`case` 结尾不要 `exit 0`**（无条件返回 0，吞错）；各关键步（make/install/xx-verify）
  加 `|| { ...; exit 1; }`。
- **gdk-pixbuf 图标坑**：静态构建下 PNG/JPEG loader 是独立 `.a`、没链进去，且无 `-rdynamic`
  → `nm -D` 报 no symbols → dlopen 失败 → 图标空白。lxtask 图标必经
  `gtk_icon_theme_load_icon`→`gdk_pixbuf`。要图标需静态链 `libstaticpixbufloader-png/jpeg.a`
  或自解码。
- **GTK2 主题坑**：u-gtk 构建没给 `--prefix` → 烤死 `/usr/local` → 找 `/usr/local/share/themes`，
  而 Alpine 装 `/usr/share/themes`。用 `GTK_DATA_PREFIX=/usr` 或 `GTK2_RC_FILES=.../gtkrc`
  重定向。**GTK2 不读 `settings.ini`**（GTK3-only），只读 gtkrc。
- **openbox 主题不通用**：`/usr/local/static/openbox/share/themes/` 的 11 个主题只有
  `openbox-3/`（`themerc`+位图），**没有 `gtk-2.0/gtkrc`**，GTK 应用认不出；且不在 GTK 查找路径上。
  真 GTK 主题需带 `gtk-2.0/gtkrc`。
- **网络**：构建容器外网 github 曾不通（2026-09-26）、后已通（2026-11-04）；gitea 镜像
  `g-system` 覆盖 tint2/pcmanfm/gtk2/xorg 链，**不覆盖 lxde**（lxappearance/lxtask）。
  `vers.txt` 的 `$GITHUB` 默认 `https://github.com`。
- **临时文件别落仓库**：探针/`.bak`/A-B 测试放 `/tmp` 或容器内，别 commit。
- **不重写已推送历史**（要拆提交需用户明确指示）。

## 五、gtk2 应用处理守则（必须遵守）

> 依据：`docs/2026/11040000-u-gtk.md`（GTK2 库静态改造总结——改造项、落到哪个库、图标/主题/
> 中文/输入法机制）。**任何 gtk2 应用（`v-*` 目录，链 gtk+-2.0）的构建/调整/修复必须遵守本节。**

### 1、构建环境（只认一个容器）

- 改造版 gtk2 **只在 `builder-awe` 容器**构建（该容器有完整 gtk2 静态库 + 源码/patch 环境）。
- **`builder-obox` 改名标记 disable、禁用**，**禁止**在其上做 gtk2（或任何 gtk2 依赖）构建
  ——避免两个容器来回跑、改了这边坏那边。

### 2、库改动统一入口 + 中间产物清理（禁止打补丁到 .a）

- **任何 gtk2 库改动**（引擎/主题/图标/输入法/路径宏等）**必须走 `u-gtk/build.sh` 统一
  标准入口完整重编**（clone → patch → configure → make → 合并 → 装 `/usr/lib`）。
  - **禁止**用 `ar r` 手动往 `/usr/lib/libgtk-x11-2.0.a` 塞/替换对象（打补丁魔改）——补丁会被
    后续重编顶掉、别人重编时用不到、改了这边漏那边。
- **编译加速在脚本内做**：`u-gtk/build.sh` 里做**增量复用**（已有 `.o`/中间产物复用，如
  `make -C gtk xxx.lo` 增量），**不要**靠手动改库来"省事"。
- gtk2 的 `.a` 库（`/usr/lib/libgtk-x11-2.0.a`、`/usr/lib/libgdk_pixbuf-2.0.a`、
  `/usr/local/lib/librsvg-2.a`、`libcroco-0.6.a`）**禁止清理**（改一次成本极高）。
- 只允许清理**中间产物**（`/tmp` 下源码树、`.o`/`.lo`/`.libs`、日志）。

### 3、改造总结（引 u-gtk.md）

- gtk2 改造的**具体项、落到哪个库、内容**（图标/主题/主题免环境变量/中文/xim/ibus）见
  `docs/2026/11040000-u-gtk.md`。**改 gtk2 库前先读该文档**，别重复踩坑。

### 4、通用验证项（通过才下一步）

- 任何 gtk2 应用调整，**必须**验证四项正常：**① 图标**（Papirus/SVG 显示）、**② 主题**
  （Greybird 控件渲染）、**③ 中文语言**（界面中文）、**④ 输入法**（xim/ibus 可输入）。
- 四项校验通过才可进入下一步（部署/提交）。

### 5、部署与验证环境（先自验后复核）

- 功能处理完 → 部署到 **hdmi 容器 `/usr/local/static/<comp>/`** 对应路径。
- 第 4 条校验在**这个环境这个路径**做。**先自行验证没问题**，之后用户复核验收。

### 6、默认配置项（不预设，留优先级）

- 应用配置项：**用户目录 + 系统目录默认不做额外预设**，但**保留加载优先级**
  （系统 `/etc/xdg/...` → 用户 `~/.config/...` 覆盖）。
- 两块都**没有配置时**，默认应**从 static 下或应用缺省配置即可满足需要**
  （如 libfm `quick_exec` 靠编译期默认宏、thunar 靠缺省 uca.xml）。
