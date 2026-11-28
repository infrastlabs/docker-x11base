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
    **gtkmm 组件（gsm/v-sysmonitor，链 gtkmm-2.4）用 `alpine-builder-gtkmm224-2`**（Dockerfile `basemm` stage；
    gtk224-2 是 `base` stage，供常规 gtk2 组件；两者库/依赖不同，产物不可互代）。
  - `common.sh`：`CC=xx-clang`、`LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"`、
    `down_catfile`（curl 缓存下载）、`oneBuild`（包装函数）、`GITHUB` 默认 `https://github.com`。
  - `vers.txt` 一行一组件：`名称|版本|克隆或下载命令`（常引用 `$GITHUB` 变量）。
  - 交叉调用：`bash /src/v-tint2/build.sh librsvg` 调对方脚本里的函数；`b_deps` 分支负责先编依赖。
  - 验证工具：`xx-verify --static <bin>`（容器内 `/usr/bin/xx-verify`）。
- **构建容器**（验证/复现用，`docker ps` 常驻）：`builder-g224`（**新基准**，自 `alpine-builder-gtkmm224-2` 镜像按需 pull 起容器，见五章 1——gsm/gtkmm 组件基准；常规 gtk2 组件仍用 gtk224-2）；
  ~~`builder-obox`、`builder-awe`~~（**禁用**，非 CI 基准）；`docker-hdmi-desktop-desktop-1`（`app-ubuntu-22.04`，
  用于跨发行版实跑）。构建容器里 `/src` = **软链** → 宿主
  `/_ext/home/headless/xm-zs01/docker-x11base/compile/src`（软链**实时反映宿主改动**，
  改完脚本**无需再 `docker cp` 进容器**，直接 `docker exec <容器> sh /src/<comp>/build.sh <组件>`）。
  注意：`/_ext` 是宿主机项目目录的 bind mount；`/src` 本身**不是** bind mount，是**容器态软链**
  （手动创建；若容器重建需重新 `ln -s ... /src`，因镜像内 `/src`
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

### 0、强制硬性规则：表达清晰禁推理（2026-11-28 用户拍板）

- **当用户表达意见清晰时**：禁止模型深度推理、反推用户意图、过度思考、挖掘无关背景；**3 分钟想不清楚就别想了**，直接照字面执行。
- **当模型理解不清 / 用户表达不完整缺信息时**：**直接回复**说明缺什么信息、要补什么，**禁止调用智能体提问模式（question 工具）**——不友好。

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
  四级 `#### 1.1、`（1.x.x 小节；AGENTS 原只规定到三级，2026-11-06 补写），
  五级 `##### 1.1.1、` / 六级 `###### 1.1.1.1、`（2026-11-26 补写，用户拍板允许 6 级——按数字序号段数定层级：N 段号 = (N+2) 个 `#`）。
- **顶部目录只两层**（2026-11-24 追加，用户拍板）：文档顶部 `## 目录` 缩进章节表**最多两层**——一级 `一、` + 二级 `1、`，**不再列 `1.1`/`1.1.1` 子节**；子节（`#### 1.1、`）只出现在正文，不进目录。
- **日期标记必须带具体时间（HH:MM）**（2026-11-26 追加，用户拍板，**硬性规则**）：文档里所有日期标记一律写 `YYYY-MM-DD HH:MM`（如 `（2026-11-26 14:10）`、`> **订正（2026-11-26 14:10）**`），**禁止只写日期**（`2026-11-26`）不带时间；时间点取**当时提交/决策时刻**，精确到分钟。
- **文档历史不动**：新结论用 `> **订正（日期）**：...` 或 `✅/⚠️` 标注追加，**不改删旧结论**。
- **先落文档再给结论**：新结论/命令/决策先写进相应文档，再回复用户。
- **禁止长条 `>` 块引用**（2026-11-15 追加，用户拍板）：补充/订正/回顾一律用**普通段落＋列表/表格**，禁止一大段 `>` 引用（超长难看）；仅短句/单行醒目可用 `>`（如 `> **订正（日期）**` 单行）。
- 相关分析：`docs/2026/260926-openbox-解析与优化.md`（openbox 全功能静态，章节已定型，
  含 8.4 oneBuild 失效、五章 落仓改动明细）；`docs/2026/260926-lxtask-解析与优化.md`
  （一、现状与待办；二、静态构建图标/主题失效问答实录）。

### 3、验证（构建类）

- **改完必须实跑**：在构建容器里 `docker exec <基准容器> sh /src/<comp>/build.sh <组件>`
  （基准容器 = `alpine-builder-gtk224-2` 镜像按需 pull 起，见五章 1），
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
> Alpine 构建容器（gtk224-2 基准容器等）**没有 Xvnc**，只有 Xvfb。所以 GUI 验证一律去
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
- **docker exec 输出被吞（根因 2026-11-16 确认）**：本环境 `docker exec` 输出被 **tcp 沙箱 daemon（`127.0.0.1:2375`）吞掉**（rc=0 无输出、命令似执行但无效果），真实 daemon 在 **`/_ext/docker.sock`**（root 属），需 **`sudo docker exec`** 才有输出（本机 sudo 免密）。与上方 setsid/Xvnc 用例同理（输出重定向绕过），但**根因是 daemon 端口差异**，`sudo docker exec` 最直接。
- **容器→宿主文件中转（2026-11-14 用户拍板，强制遵守）**：容器写宿主文件**统一用 `sudo` 写 `/_ext/tmp/` 中转**
  （宿主 `/_ext/tmp` 为 777），宿主导读；**写失败就一直重试（拆成一条命令一个动作循环跑）**；
  **禁止 `docker export` 容器**（重、用户明确禁止）；`docker cp` 在本机 mount 故障（ENOSPC）也不可用。
- **容器内编译调试 `/src`（2026-11-14 补充）**：构建容器内 `/src` **软链 → 宿主 `/_ext/.../compile/src`**
  （实时反映宿主改动，改脚本无需 `docker cp`）；镜像烘焙的 `/src` 是**旧真实目录**，
  须 `rm -rf /src && ln -s 宿主compile/src /src` 重建（否则用旧脚本，修复不生效）。
- **复杂容器命令用脚本文件化（2026-11-14 追加，用户拍板）**：~~写成 `/_ext/tmp/svg/t_xx.sh`（宿主），容器内 `docker exec <c> bash /_ext/tmp/svg/t_xx.sh` 执行~~ **已于 2026-11-15 废止**——改用下方「setsid 直拼命令法」优先，**不再写脚本文件**。
- **`docker exec` 回执被回收坑 + `setsid` 直拼命令法（2026-11-15 用户拍板，**优先/默认**）**：本机 `docker exec`
  不仅**输出被吞**（stdout 不返回），且 exec 返回时**被拉起的进程会被回收**——文件写入等副作用
  全丢、`rc=0` 但"什么都没发生"（曾误判"命令没执行"）。解法：**`docker exec <c> setsid bash -c '<cmd> > /_ext/tmp/svg/out.txt 2>&1 &'`**
  （`setsid` 脱离会话 + 后台，进程独立存活），宿主轮询 `out.txt` 末尾 `DONE` 标记；
  **命令内容直接拼进 `setsid bash -c '...'`，不写脚本文件**（多步/长命令同样直拼，用 `;`/换行拼接即可）；
  **不再写 `/_ext/tmp/svg/t_xx.sh` 再 exec**。结果统一写 `/_ext/tmp/svg/` 中转，宿主导读。

**示例（宿主执行，长/多步命令直拼）**：
```sh
INNER=$(cat <<'OUTER'          # 'OUTER' 带引号→宿主不展开 $var，内容直进容器端 bash -c
{
echo "JOB_START $(date +%T)"
# ...多步命令（容器内执行，$var 在容器内展开）...
ls /usr/local/static/geany/bin/geany
} > /_ext/tmp/svg/out.txt 2>&1
echo "DONE" >> /_ext/tmp/svg/out.txt   # 末行 DONE 标记，宿主导读
OUTER
)
docker exec builder-g224 setsid bash -c "$INNER" >/dev/null 2>&1 &
# 宿主轮询：grep -c DONE /_ext/tmp/svg/out.txt 直到 >=1；tail 看进度
```

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

### 3.3、临时容器用完提示清理（2026-11-19 追加）

- 任何**临时任务**（验证/排查/测试）起的容器（如 rootfs 无参验证容器、临时查询容器），**任务搞完后主动提示用户是否清理释放资源**，不擅自保留、也不擅自删——问一句让用户拍板：`docker rm -f <临时容器>`。
- 背景：本机内存 1.9Gi 红线（见 `memory/resource-guard.md`），多临时容器叠加会 OOM（2026-11-18 爆内存事故）。
- **固定/常驻容器除外**（builder-g224 / builder-gsm-verify 等构建基座、用户 docker-compose 服务），保留备用。

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
- **未获明确指示写文档，只回答不动文档**（2026-11-17 用户明示）：用户只说「结论是/怎么弄」时**只回答，不主动落档**；主动预写会导致后续挪动/重排多走弯路。判断：说「保存到 xx 节/落档/写到文档」才写。

## 四、安全守则（2026-11-19 用户拍板新增，整合分散安全内容：网络端口/系统权限/内存磁盘资源）

> 独立安全章节。**所有智能体操作必须遵守**。内容汇总此前分散在 3.1/3.3 及 memory（`machine-memory-limit-oom.md`/`resource-guard.md`）的安全约束。

### 1、网络端口（安全）

#### 1.1、⚠️⚠️⚠️ 端口绑定极度严重安全警告（2026-11-19 用户紧急追加，毁灭性安全事故）

- **任何 socat/监听转发只允许绑定本地回环 `127.0.0.1`，绝对禁止省略 bind 地址**。`socat TCP-LISTEN:2375` 不写地址 → 默认绑 **0.0.0.0（全部接口）** → 公网机器上无认证 docker daemon 裸奔 → **被黑、容器被销毁（hdmi 容器被毁）**。转发 docker.sock 一律显式：
  `sudo socat TCP-LISTEN:127.0.0.1:2375,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock &`
- 本机/公网必须只暴露本地，违反即重灾。

#### 1.2、docker daemon 访问入口

- 可用入口：`sudo docker -H tcp://127.0.0.1:2375 <cmd>`（socat 转发 `/var/run/docker.sock`，**绑 127.0.0.1**）。
- `/_ext/docker.sock` 是 **0 字节失效文件**（非真 socket），socket 直连会失败；以 tcp 2375 实测为准。
- docker daemon 重启后需手动起（`sudo dockerd` 或项目脚本）；容器不会自动恢复。

#### 1.3、端口暴露原则

- 只暴露本地回环，不暴露公网/`0.0.0.0`；服务端口（gitea/nginx 等）由 docker-compose 管理，勿自行开裸端口/裸转发。

### 2、系统权限

#### 2.1、sudo 使用

- 本机 sudo **免密**；`docker exec` 需 **`sudo`**（否则输出被 tcp 沙箱 daemon 吞掉、副作用似执行但无效果）。
- 容器→宿主文件中转：统一 `sudo` 写 `/_ext/tmp/`（777）中转，宿主导读；写失败一直重试（拆成一条命令一个动作循环跑）；**禁止 `docker export`**（重、用户明确禁止）；`docker cp` 在本机 mount 故障（ENOSPC）不可用。

#### 2.2、容器内用户/权限

- 构建容器 root 跑；运行时桌面（rootfs-dbg/hdmi）以 **headless 用户**跑（`su -s /bin/bash headless -c "DISPLAY=... BIN"`）。
- 容器内 `/tmp` 对 headless 无写权限（bind EACCES）→ 需 `TMPDIR=/var/tmp`（bacon socket 等）。
- 容器内 `/src` 软链 → 宿主 `/_ext/.../compile/src`（实时反映宿主改动）；镜像烘焙 `/src` 旧真实目录，须 `rm -rf /src && ln -s ...` 重建。

### 3、内存磁盘资源（OOM 红线）

#### 3.1、宿主机资源基线

- 内存：**1.9Gi 总量、swap 2G**（`/swapfile`，当前已启用），idle 仅剩 ~600Mi 可用（用户 live `:1` 桌面会话 + 服务占 ~1.1Gi）。磁盘 **~96%**（50G 盘，~2G 余）。
- **swap 需重启后手动 `swapon /swapfile` 才生效**：重启后不自动挂载，忘记启用则退回无 swap 状态；2026-11-18 爆内存事故时 swap 未启用（进程一多即 OOM kill，用户重启才恢复）。

> **订正（2026-11-19）**：初稿误记"0 swap"——本机实有 2G swap（`/swapfile`，`free -m` 实测 Swap 2047M 已启用）；但重启后需手动 `swapon`，否则仍退回无 swap 的 OOM 风险。

#### 3.2、硬约束（每次容器/构建前必须检查）

1. **先 `free -m`**：available < **500Mi** 不起容器/不跑构建（宁等不冒险）。
2. **一次只起一个验证容器，用完 `docker rm -f` 即删**；禁止多容器并行（builder + 验证 + 其他任务叠加是事故主因）。
3. **禁止并行跑多个重构建**（compile+link 峰值内存高）——一次一个，串行，跑完停/清。
4. **起桌面验证前查 X 残留**：`ls /tmp/.X11-unix/` 数量多（曾 138 个）→ 先清理（除 live `:1` 外，无活动 Xvnc 进程的 socket + `/tmp/.X<NN>-lock` 可删），**挑空闲 display 号**，禁止占用已知号（:10 曾起不来）。
5. **起桌面容器后做连通性门**：`DISPLAY=:$DISP xprop -root >/dev/null` 不通 → 立即停容器/进程，**绝不放任 perp 反复拉起 tint2/pasystray crash-loop**（事故直接元凶）。
6. **Xvnc 只留用户 live `:1`**，其余用完 `pkill -f "Xvnc :$DISP"`（带号限定，防误杀 bash 外壳）；清 `/tmp/.X<NN>-lock` + socket。
7. **GUI 测试完杀干净**（pkill gnome-system-monitor / 关容器），别留 live 进程。
8. **临时容器用完提示清理**（同 3.3）：临时任务起的容器，任务完主动提示用户是否清理（`docker rm -f <c>`），不擅自保留/删除——问一句让用户拍板；固定/常驻容器（builder-g224 等）除外。
9. **临时文件别落仓库**（探针/.bak 放 `/tmp` 或容器内）；别把 `/_ext/tmp` 当垃圾桶堆多个 `.bin`（磁盘紧）。

## 五、gtk2 应用处理守则（必须遵守）

> 依据：`docs/2026/11040000-u-gtk.md`（GTK2 库静态改造总结——改造项、落到哪个库、图标/主题/
> 中文/输入法机制）。**任何 gtk2 应用（`v-*` 目录，链 gtk+-2.0）的构建/调整/修复必须遵守本节。**

### 1、构建环境（基准镜像 = 按需 pull 最新，禁止旧容器）

- **构建基准 = `alpine-builder-gtk224-2` 镜像**（`registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-builder-gtk224-2`），
  **按需 `docker pull` 取最新**——该镜像会变化（CI 各组件 stage 的 base 即此镜像，库/依赖随镜像更新；本地旧缓存可能过时）。
  **gtkmm 组件（gsm/v-sysmonitor，链 gtkmm-2.4）基准为 `alpine-builder-gtkmm224-2`**（`.../x11-base:alpine-builder-gtkmm224-2`，Dockerfile `basemm` stage；本节其余规则（起容器/软链/构建方式/禁止 builder-awe）通用）。
- **起容器像 awe 跑法**（`docker run -d --name <c> --network host -e CACHE=/usr/local/static/.cache -v /_ext:/_ext --entrypoint bash <img> -c 'while :; do sleep 3600; done'`），
  容器内 **`/src` 换软链** → 宿主 `/_ext/.../compile/src`（实时反映宿主改动；镜像内 `/src` 是烘焙真实目录/旧脚本，必须 `rm -rf /src && ln -s ... /src`）。
- **按 Dockerfile 调用方式构建**：`TARGETPATH=/usr/local/static/<comp>` + `sh /src/<comp>/build.sh <comp>`（`CONSOLE_LOG=no`），别只在旧容器增量跑。
- **禁止**在 `builder-awe`（及 `builder-obox`）做 gtk2（或任何 gtk2 依赖）构建——**原规则过时**：该容器非 CI 基准，库/依赖与 CI base（gtk224-2）不一致，产物无法代表 CI。

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
