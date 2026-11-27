# Changelog 2026-11（docker-x11base 逐日变化概要）

> 基于本地 git 历史（`feat/ai-260925`，11-04 起约 251 commit，按 commit 日期逐日）。
> 临时存放于用户 HOME，不在仓库下。

## 逐日概要（2026-11-04 → 11-27）

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

### 11-20 · 中文本地化落地 + 默认会话
- 六组件中文 `.mo` 自足：lxtask/pcmanfm/engrampa/gpicview/gsm/xfce4-settings 改 `localedir=$TARGETPATH/share/locale` + msgfmt 装 `.mo`（thunar 大写 domain `Thunar.mo` 双输出；产物自足可迁移，无 XDG 环境可用）。
- v-pasystray `pasystray-no-icon-tooltip.patch`（修 `--no-icon-tooltip` 上游 no-op——G_OPTION_ARG_NONE 无法置 default-TRUE 变量）；rfs/entry.sh + dcp 默认 `START_SESSION=openbox-session`。

### 11-21 · ibus 接入矩阵评估
- ibusB 五章总结篇（2026-11-21）：静态/动态 ibus 服务 × 动/静态应用接入矩阵——A2 标准路径 vs XIM 转接，`ibus:xim` 回退列表消「未 A2 静默降级 simple」风险；建议先 XIM 顶上、按待办闭环 A2 后切标准配置。

### 11-22 · gpicview 修复 + 发行版调整
- v-gpicview 手装段补 `pref-dlg.ui`（GtkBuilder 运行时加载，漏装点 Preferences 崩）；11170850 4.1 根因落档。
- ibusB 五章 1.1：librime-data-wubi 在 Alpine 无包的安装方案（plum/跨发行版拷 schema）。
- dist/alpine/ubt/opsuse + dist/oth/debian 补 ibus/notes；rfs/xconf.sh core 加 dbus/ibus；rfs dockeffile 换 infrasync v2025 alpine-3.12。

### 11-23 · 版本升级大日（GTK2 最后版全线对齐）
- **版本升级**：thunar 1.6.3→1.6.18、tint2 16.1→16.7、rofi 2.0.0→2.1.1（开 imdkit/xim，自建 xcb-imdkit 静态库）、imlib2 1.7.4→1.12.7 + xlunch v4.7.5→v5.10.6 + feh→3.13.1 + hsetroot→1.1.0 + scrot 重链、geany 1.34.0→1.37.1、gpicview 0.2.5→0.3.1、dbus 1.12.26→1.16.4（方案C Meson，多版本构建）、pcmanfm 1.3.1→1.4.0 + libfm 1.4.1 + menu-cache 1.1.1、lxtask 改 0.1.12 tag。
- imlib2 1.12.7 适配：loader_svg.c 改写 2.40 兼容 + loaders.c 锚点迁移 + `-Dloader=png_loader` 重命名 + 补编 ldrs_util.c/exif.c；feh/hsetroot 需删 tarsrc-git 缓存强制网络 clone tag。
- pcmanfm 右键菜单/OpenWith 修复：menu-cached 静态链 + 菜单数据 + `menu-cache-menudir.patch`（MENU_CONFIG_DIR env 优先）+ OpenWith 对话框截图验证。
- tarsrc 落仓（compile/tarsrc 源码包 + _cache_repo 快照）；README 真机验证表版本列对齐；gsm/pavucontrol 最新 GTK2 版评估。

### 11-24 · 文档拆分收口
- `11170850-selected-app-use.md` 一章 1-3 节（gsm/dbus-dunst/pasystray）拆出至 `11170851-selected-app-modifyA.md`（保留标题序号+去向/来源块引用+3/4级章节表）；三级标题补齐日期；章节表两层/表随正文修正。
- rfs/dockerfile link usr/share/applications + fix/drop；cpl/dockerfile xfce4 full；gitac buildx compile/gtkmm224。

### 11-25 · 交叉编译改造启动
- README 真机验证表加 clipit 行（44ece608 11-25 10:42，版本标最新）。
- 交叉编译方案一：剩余组件交叉适配（二章 4，11-25 15:20）；方案二进展、方案三落地、方案一收尾（二章 2-3）。
- xdpyprobe 交叉缺 X11：修复+依赖清单（三章 1，11-25 19:01）；GTK2 应用交叉失败：烤基础镜像方案（三章 2，11-25 21:49）。

### 11-26 · 排错日志获取 + 方案A 落地
- `11241320-multiarch-buildSpeed.md` 三章 3.4 排错日志获取优化（3.4.1 问题与 A/B/C 方案对比，A+B 组合：b_deps 直通 stdout + 末尾验产物 + .logs 随镜像留存）。
- `u-gtk/analyze.sh` 新增：单架构静态产物分析+报告（3.4.3）——关键产物存在性 + archcheck + .a 清单 + 失败定位（doExec _exec_result.txt 末条 rc!=0→FAIL_MODULE/FAIL_LOG）+ CONCLUSION。
- `Dockerfile.builder.gtk224.xx` 方案A 落地（3.4.3）：① RUN 首行 set -e 改包子 shell ② 并行分支 intermediate 清理加成功门 `[ "$RC" = 0 ] &&`（失败不清中间产物）③ 末尾 apkc clean 后补 analyze 循环写 `/report/u-gtk-$tag.txt` + exit 0（镜像无条件建成）。
- `build-local.sh`/`buildx.sh` gtk224 case 外层读 `/report/u-gtk-*.txt` 判成败（3.4.3）——docker pull + cat 通配符一把梭哈，grep CONCLUSION: FAILED 有则打印报告+exit 1。
- `Dockerfile.builder.gtk224.xx` 修正 ARCHS 赋值作用域——sed 转译（armv7→arm/v7，逗号→空格）提到子 shell 外，否则 analyze 的 for arch 拿到原始逗号串（amd64,arm64,armv7）单次迭代 case 不匹配→unknown arch（3.4.3）。

### 11-27 · 方案B 公共库统一装 + CI 全量验证 + arm64 双失败修复
- **pcmanfm 构建故障排查**（四章 1）：armv7 交叉复现 + 根因（sysroot 缺 libXcomposite/libgpg-error）→ 方案拍板 B（公共库基础镜像预装进 sysroot）；apk 基础库全局梳理（公共 58 / 单次 30）。
- **方案B 实施**：`u-gtk/build.sh` b_deps 尾部 xx-apk 统一装公共库（44 唯一包/展开约 60，实测 openssl-static 不存在→openssl-libs-static、zlib 需 zlib-static）；16 组件 build.sh 移除公共库（cross/native 行）。
- **三架构验证**（builder-g224）：lxtask/gpicview/lxappearance/pcmanfm/geany 全 xx-verify pass；两处出入（gpg-error 归公共——lxtask 也链 -lgpg-error；lxappearance 补交叉分支）。
- **B 方案改造后 CI 故障排查**（1.5.3）：arm64 失败根因（gcc 下载中断 + 报错被吞）+ 交叉 sysroot 依赖提前安装（1.5.3.2 B 类清单）。
- **alpine-compile-3 镜像核对**（四章 2）：rofi 缺 bin 根因锁定——方案B 漏装 native libxkbcommon→libnkutils disabler→meson 0.59 静默丢 rofi 目标（推翻 xcb-imdkit 初判）；修复：native 临时补装 libxkbcommon（92f5f960，TEMP 标记专题后移除）。
- **buildx 开关演变**：ss2→ss3（已 Revert）→ss4→`3611b924`（除 gtkmm 外全开，plat=amd64,arm64）。
- **CI 全量重跑验证**（run 1057，3611b924，12:18Z 起 12:54Z 止，success）：amd64 全组件产出，v-xfce4 ristretto/thunar 海量 `undefined reference`（615+584）为 make 阶段预期噪声（手工链接补救，产物 xx-verify pass）。
- **alpine-compile-3-dbg 镜像三架构产出核对**（四章 3）：真正 CI 产物在 `-dbg` tag（digest e4af5e22，之前误拉 alpine-compile-3 旧 84874349）；armv7 未编 dbg（plat 不含 arm）；arm64 两失败——rofi b_deps（startup-notification config.sub 不认 aarch64-alpine-linux-musl）+ engrampa make（sysroot 缺 /lib/ld-musl-aarch64.so.1）。
- **arm64 双失败修复**（方案A）：`x-rofi/build.sh` build_dep 交叉换 automake 1.16 config.sub/config.guess（c0832c75，验证原版报 Invalid configuration、替换后过）；`v-engrampa/build.sh` eng_cross 补 `xx-apk add musl`（893c7021，验证 sysroot ld-musl-aarch64.so.1 就位）。

## 主题脉络
组件版本选型（11-05）→ 各组件静态构建收口（11-07~11-15，核心：doExec 重构、gitclone 缓存、svg 库层根治、pulsecommon 版本漂移）→ 构建基建/CI（11-09/11-13）→ D-Bus 桌面会话/通知（11-17）→ 文档收口+版本对齐+安全守则（11-19）→ 中文本地化+版本升级大日（11-20~11-23，GTK2 最后版全线对齐）→ 文档拆分收口（11-24）→ 交叉编译改造启动（11-25）→ 排错日志获取+方案A 落地（11-26）→ 方案B 公共库统一装+CI 全量验证+arm64 双失败修复（11-27）。

> 注：另有少量 commit 带旧 author 日期（02-04 等，属 rebase 历史），但 commit 日期均在 11-04 后，为本次分支工作的一部分；逐日主题以 commit 内容为准。
