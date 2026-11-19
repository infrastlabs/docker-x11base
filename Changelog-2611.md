# Changelog 2026-11（docker-x11base 逐日变化概要）

> 基于本地 git 历史（`feat/ai-260925`，11-04 起约 387 commit，按 commit 日期逐日）。
> 临时存放于用户 HOME，不在仓库下。

## 逐日概要（2026-11-04 → 11-19）

### 11-04 · 起步
- `AGENTS.md` 新建（项目信息 + 静态构建避坑手册：oneBuild 吞错 / LDFLAGS 勿覆盖 / --start-group / gdk-pixbuf 图标坑等）。
- lxtask 文档复核：github 源已通、硬阻塞解除、0.1.12 静态 35.9M 成功，订正 7 处。

### 11-05 · 组件铺开 + 版本选型
- 新建大量文档：engrampa（libtool `--start-group` 根因）、geany 1.34.0、pavucontrol（GTK2 最后版 3.0）、feh/xlunch imlib2 loader、pcmanfm 新库（Greybird+Papirus）、v-oth 重命名。
- `vers.txt` 大补：geany/engrampa/scrot/gsysmonitor/dbus 1.12.26/dbus-glib 0.112/pasystray 0.8.2/xbindkeys 1.8.7/xrandr 1.5.4/hsetroot 1.0.5/gpicview 0.2.5。
- `compile/src/Dockerfile`：接入 geany/pavucontrol/xbindkeys/xrandr + 新增 xfce4 stage + 补 10 无 stage 组件入口 + 镜像更名 gtk224→gtk224-2。

### 11-06 · ibus 开工
- ibus/ibus-rime 静态构建调试记录（impl02）新建，ibus01 拆出（ch1+ch2）。

### 11-07 · ibus 栈 + 无 GTK 组件
- `v-ibus/build.sh` 新建：ibus 栈静态构建；panel 源 + ibus main.c 补丁（方案B候选窗/A2 im 模块）；ibus-setup C 重写；panel 托盘菜单（当前引擎/切换/退出）。
- 新增静态构建：rofi 2.0.0、dunst 1.13.2、gpicview 0.2.5、hsetroot 1.0.5、xbindkeys 1.8.7。

### 11-08 · GTK2 库改造 + xfce4
- `u-gtk.md` GTK2 库静态改造总结（图标/主题/免环境变量/中文/xim/ibus）。
- xfce4：thunar 双修复（D-Bus 单实例改名 + UCA 静态内链）；ristretto/display-settings 免 xfconf patch；gsm 磁盘 tab 卡顿（VolumeMonitor 枚举）patch。
- engrampa 去 multiple-definition（main.c 重复定义 patch）；pavucontrol glade expand + 中文 locale。

### 11-09 · CI 基建
- `buildx.sh` 补齐 17 stage 的 `COMPILE_*=no` 开关（默认不建）；`Dockerfile.builder.gtk224` 烘焙 gtkmm 栈+ICU；`ensure_gtk_libs`（判 patch hash 自动重编 .a）；README/syncer 镜像更名 gtk224→gtk224-2。

### 11-10 · gtkmm 容器
- `Dockerfile.builder.gtkmm224` 新建（gtkmm 基准）；u-gtkmm pangomm 头路径修复（自编库头不在标准位）；容器备份（obox 删、awe 留）。

### 11-11 · doExec 重构 + u-gtk 修复
- `common.sh` 新增 doExec 公共执行包装（分层日志/白名单回显/错误码）；`oneBuild` 吞错修复（mktemp 捕获真实退出码，弃 `|tee` 假绿）。
- u-gtk 三类错误修（并行→串行、--disable-shared、只建库目标）+ gdkenumtypes.h 生成修复；pixbuf theme engine 转 patch（弃 ar 魔改）。

### 11-12 · CI fresh 修复
- u-gtk gdk/x11 子库缺失 + BUILT_SOURCES 生成修复；oneBuild 复用 doExec；Dockerfile 拆 basemm。

### 11-13 · 峰值：缓存机制 + doExec 全适配
- `common.sh` 新增 `gitclone`（GITCACHE>tar.gz 快照>网络，解决 CI gitee/github 抖动）；`down_catfile` 接 tarsrc 缓存。
- doExec 适配 17 个 build.sh（b_deps/full 调入口、DOEXEC_CALLER、并行组 doExec_mark/check）。
- u-gtk `-Dbuiltin_loaders=png,jpeg,svg`（svg loader 生效根因）；w-tint2 librsvg `.pc` Requires 补全 + xcbutil m4 submodule 修复；空组件 stage 加 `test -x` 硬断言。
- 大量文档拆分（ci-builder-gtk-app 等）。

### 11-14 · git clone 替换 + svg 库层根治
- 约 18 个 build.sh `git clone`→`gitclone` 全量替换；gitclone 打 tar.gz 快照缓存 + cachesrc 日志。
- gdk_pixbuf svg loader **库层根治**（方案A：io.c 导出 init_builtin + get_type 调用 + build.sh 内联 python）；lxtask 去 `-u`；pcmanfm/libfm 补 loader 依赖；engrampa GSettings schema patch；AGENTS.md 3.1 文件中转规则。

### 11-15 · 组件源头消错 + 注入库
- v-pcmanfm/libfm 源头消错（跳过非核心工具/共享模块、补头/.pc、--disable-shared 消 .so）；w-xlunch imlib2 注入版覆盖 `/usr/local/lib/libImlib2.a`（5 个 w-xxx 裸链取注入库）；w-tint2 librsvg -ljpeg + .la 修元数据；x-rofi 4 处修复；v-geany/v-engrampa 链接修复；README 真机验证表新建。

### 11-16 · 版本漂移根因 + 多版本支持
- pulseaudio `git-version-gen failed` 根因（.tarball-version）；pasystray/pavucontrol static-link 根因（硬编码 pulsecommon 版本→动态 PULSECOMMON + 覆盖程序专属 LINK）；x-dropbear 多版本支持（2024.86/2026.94）+ libcrypt whole-archive 前置；u-gtkmm GTKMM_LIBS 修；rootfs 组装段打开 10 COPY。

### 11-17 · D-Bus 桌面会话 + 通知
- `rootfs/src/entry.sh` 方案A 落地（拉起 D-Bus 会话总线 + export `DBUS_SESSION_BUS_ADDRESS`）；x-dbus `dbus_send()`、x-dunst `notify_send()` + notify-send.c 新建；v-pasystray libnotify 静态化；v-sysmonitor gsm-tab-order.patch；11170850-selected-app-use.md 新建。

### 11-18 · 收尾修复
- v-pasystray libnotify 下载改 down_catfile（tarsrc 缓存）；v-sysmonitor gsm-exit-crash/gconf-keyfile/column-persist 三 patch；v-xfce4 make 只编 .o 不触发 CCLD（libtool .la 缺失）。

### 11-19 · 文档收口 + 安全章节 + 版本对齐
- dbus-launch 静态化（dbus_launch() + full-launch + 去 --disable-x11-autolaunch）；AGENTS.md 新增**四章安全守则** + swap 订正；README 状态勾上色 + **真机验证表版本列**（对齐 compile/tarsrc）；ibus01 零章设计/关系链梳理 + panel 官方 Python 标记；ibus02 3.1/3.2/3.3 大重构（fcitx 细化/跨发行版可用性/结论汇合）。

## 主题脉络
组件版本选型（11-05）→ 各组件静态构建收口（11-07~11-15，核心：doExec 重构、gitclone 缓存、svg 库层根治、pulsecommon 版本漂移）→ 构建基建/CI（11-09/11-13）→ D-Bus 桌面会话/通知（11-17）→ 文档收口+版本对齐+安全守则（11-19）。

> 注：另有少量 commit 带旧 author 日期（02-04 等，属 rebase 历史），但 commit 日期均在 11-04 后，为本次分支工作的一部分；逐日主题以 commit 内容为准。
