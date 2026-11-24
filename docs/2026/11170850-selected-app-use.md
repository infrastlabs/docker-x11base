# selected-app-use：x11 通用桌面组件微调/配置/使用说明

> 背景：x11 通用桌面组件，初步选用 lxtask、pcmanfm、geany、gpicview、engrampa、gsm、pasystray、pavucontrol、xfce4-display-settings 为主，配套 scrot、xrandr、rofi、dbus/dunst 等工具。文档用于存放组件的微调/配置/使用说明等。具体章节接下来细化。

## 目录

- 一、调整项
  - 1、gsm界面改造(4tab顺序:System移最后+默认激活Processes) + 评估版本已最新（2026-11-16）
  - 2、dbus/dunst 静态版在 headless 会话的使用（2026-11-17 分析）
  - 3、pasystray 音量托盘通知(libnotify静态化) + pavucontrol 评估版本已最新（2026-11-17）
  - 4、gpicview 设置对话框报错 + 版本升级（2026-11-22）
  - 5、pcmanfm 升级与右键菜单修复（2026-11-23）
  - 6、geany 升级评估 + 1.37.1 升级实现与验证（2026-11-23）
  - 7、engrampa 最新支持 GTK2 版本评估（2026-11-23）
  - 8、XFCE 组件 最新支持 GTK2 版本评估（2026-11-23）
  - 9、tint2/rofi/scrot 评估 + rofi 2.1.1 升级实现与验证（2026-11-23）
  - 10、feh/hsetroot/xlunch 最新版本评估（2026-11-23）
- 二、配置项
  - 1、mime 数据（gdk-pixbuf 图标/格式识别）（2026-11-17）
  - 2、dbus/dunst 在 rootfs 的运行时串接（2026-11-17）
- 三、使用说明
  - 1、中文显示（gettext 本地化）（2026-11-20）

## 一、调整项

### 1、gsm界面改造(4tab顺序:System移最后+默认激活Processes) + 评估版本已最新（2026-11-16）

### 2、dbus/dunst 静态版在 headless 会话的使用（2026-11-17 分析）

### 3、pasystray 音量托盘通知(libnotify静态化) + pavucontrol 评估版本已最新（2026-11-17）

> 本节（1-3 节）内容已拆出至 `docs/2026/11170851-selected-app-modifyA.md`（2026-11-24），此处仅保留标题与序号；正文见新文档。

### 4、gpicview 设置对话框报错 + 版本升级（2026-11-22）

#### 4.1、设置按钮点击报错——pref-dlg.ui 漏装根因与修复

**症状**：gpicview 0.2.5 主界面正常（看图/翻页），点击工具栏 Preferences（设置/齿轮）报错，无法弹出配置界面。主界面不用 GtkBuilder（代码手工建窗），唯独设置对话框走 GtkBuilder + 外部 XML，所以唯独这项挂。

**根因**（三方交叉验证）：`compile/src/v-gpicview/build.sh` 手装段漏装设置对话框 UI 文件 `pref-dlg.ui`。

| 环节 | 证据 | 说明 |
|---|---|---|
| 加载点 | `pref.c` `edit_preferences()`：`gtk_builder_add_from_file(builder, PACKAGE_DATA_DIR "/gpicview/ui/pref-dlg.ui", NULL)` | GtkBuilder 从固定路径加载 UI |
| 宏定义 | `src/Makefile.am`：`-DPACKAGE_DATA_DIR=\""$(datadir)"\"` = `$(prefix)/share` | 运行时找 `$prefix/share/gpicview/ui/pref-dlg.ui` |
| 源码位置 | 源码树文件在 `data/pref-dlg.ui`（9687B GtkBuilder XML），非 `data/ui/` | |
| 安装规则 | `data/Makefile.am`：`uidir=$(datadir)/gpicview/ui`、`ui_DATA=pref-dlg.ui` | 正解装到 `$prefix/share/gpicview/ui/pref-dlg.ui`，与加载点一致 |
| 实际构建 | `build.sh` 手装段只 `cp -r data/pixmaps $TARGETPATH/share/gpicview/`，**没建 `ui/`、没拷 pref-dlg.ui** | 部署后文件不存在 |

**失败链**：`gtk_builder_add_from_file` 文件不存在 → 返回 0 失败（`err` 传 NULL 未检查，静默）→ `gtk_builder_get_object(builder,"dlg")` 返回 NULL → `gtk_window_set_transient_for(NULL,parent)` GLib 断言 → 后续对 NULL 的 `g_signal_connect`/`gtk_dialog_run(NULL)` 直接崩溃。

**修复思路**（最小改动，一处）：build.sh Install 段补装 UI 文件。

```sh
mkdir -p $TARGETPATH/share/gpicview/ui
cp data/pref-dlg.ui $TARGETPATH/share/gpicview/ui/
```

**改后验证**（三步）：

1. 装后文件在：`test -f $TARGETPATH/share/gpicview/ui/pref-dlg.ui`
2. 编入路径核对：`strings $TARGETPATH/bin/gpicview | grep pref-dlg` 应含 `/usr/local/static/gpicview/share/gpicview/ui/pref-dlg.ui`
3. 实跑（Xvnc）：启动 gpicview → 点 Preferences → 设置对话框正常弹出；勾选/改色/点"设为默认"不崩

**补充**：`pref-dlg.ui` 是运行时从文件加载的 GtkBuilder XML，**不嵌入静态二进制**，必须随部署安装（与图标/主题"烘焙进库"不同——漏装一个文件就挂一个功能）。若想更稳可在 `edit_preferences()` 加 `gtk_builder_add_from_file` 返回值检查并弹错误提示，但属上游源码改动非必要；**补装文件即可根治**。

#### 4.2、修复验证总结（2026-11-22）

按 4.1 思路补装 pref-dlg.ui 后，builder-g224 重编（tarsrc 缓存命中，19s），产物部署 hdmi 容器 Xvnc 实跑，全链路通过。

| 环节 | 结果 |
|---|---|
| 构建 | builder-g224，`TARGETPATH=/usr/local/static/gpicview sh /src/v-gpicview/build.sh gpicview`，19s，err 0 pass；**tarsrc 缓存命中**（`/tarsrc/v-gpicview/gpicview-0.2.5.tar.gz`，gitee x11base-tarsrc，未走 curl 下载） |
| 产物 | `share/gpicview/ui/pref-dlg.ui`（9687B）已装；`strings` 编入 `/usr/local/static/gpicview/share/gpicview/ui/pref-dlg.ui`；`xx-verify --static` OK；`statically linked, stripped` |
| GUI 实跑 | hdmi 容器 Xvnc `:315`，headless 用户：主窗口「图像查看器」弹出，xdotool `windowfocus` + 按 `p`（GDK_p=on_preference）→ **Preferences 对话框「首选项」弹出**（WIN 2097225，中文本地化生效） |
| 提交 | 文档 `02f92c41`；build.sh 修复 `0197c68d`（均已推送） |

**对比**：修复前点 Preferences 崩（pref-dlg.ui 缺失）；修复后正常弹出。

**验证环境坑**（hdmi 容器，非产物缺陷）：

- 无 `xprop`/`xdpyinfo` → 连通门改用 `xdotool getdisplaygeometry`。
- `xdotool key --window`（XSendEvent）GTK2 忽略合成事件 → 须 `windowfocus` + `key p`（XTEST 真实按键）。
- `pkill -f` 自匹配坑：脚本命令行含路径字样会自杀 → 用 `pkill -x` 精确名 + Xvnc 字符类（`'Xvnc :31[3-9]'`）防误杀。
- gpicview 快捷键 `P`=on_preference（GDK_p）；Preferences 标题中文「首选项」（`.mo` 生效）。

**gpicview 0.3.1 升级评估与转存地址（2026-11-23）**——上游转存 gitee，以 `gitee.com/g-system/fk-lxde-gpicview` 为准；当前 0.2.5 → 最新 0.3.1，评估升级可行性。

**转存仓库**：tags 0.1.3/0.1.8/0.1.11/0.2.0~0.2.6/0.3.1；0.2.5 peeled 与 github lxde/gpicview 完全一致（同源转存），多 0.1.11；master 在 0.3.1 后 5 提交（4 翻译 + autogen.sh 适配最新 automake `7f54b7c`）。

**0.2.5→0.3.1 差异**：94 文件 +5901/-4040，60+ 提交。新增功能（均正向）：Ctrl+C 剪贴板、工具栏显示/隐藏、打开最大化、缩放步长、窗口大小/位置保存、动画重启用、URI 检查+SEGV 修复、libjpeg≥7 旋转保存修复、自动放大窗口 bug 修复；移除 debian 目录/unused fullscreen.png/desktop Encoding key（无影响）；新增 man page `gpicview.1`（预生成，无构建依赖）。

**升级可行性评估**：

| 影响点 | 结论 |
|---|---|
| GTK2 构建 | 可行。configure.ac `--enable-gtk3` 不传→空→else 分支 `gtk+-2.0 >= 2.12.0`（u-gtk 2.24.33 满足）；且 src/ 零处 `ENABLE_GTK3` 引用、main-win.c:1090 有 GTK2 专属 `widget->window` → 实际 GTK2-only（GTK3 反而编不过） |
| patch | 不再需要。`gpicview-mainwin-return.patch`（`return;`→`return FALSE`）已在 0.3.1 upstream 修复（main-win.c:375）；升级须删 patch 步骤 |
| 数据文件 | build.sh 已手装 `data/pref-dlg.ui`（cp 版本无关）→ 0.3.1 新配置项自动带上；data/pixmaps 不变（fullscreen.png 删除是 unused） |
| -Werror 严格 | configure.ac:31 一串 `-Werror=return-type/missing-declarations/undef/aggregate-return...` + `-D*_DISABLE_DEPRECATED`；0.2.5 已能过，0.3.1 为 upstream 稳定版应能过——静态构建（xx-clang）须实跑确认 |

**需改点（若升级）**：`vers.txt` 改 `gpicview\|0.3.1\|down_catfile https://gitee.com/g-system/fk-lxde-gpicview/archive/refs/tags/0.3.1.tar.gz \| tar xz ...`；`build.sh` 版本 0.2.5→0.3.1、删 patch 步骤、订正第 19 行注释（「0.2.6/0.3.1 已 GTK3-only」→「0.3.1 实际 GTK2-only」——原注释是坑）。

**结论**：升级 0.3.1 可行性成立、影响可控（正向功能增量，无新硬依赖；patch 已上游化可删）；唯一需实跑确认 0.3.1 GTK2 静态构建过 -Werror。

#### 4.3、gpicview 0.3.1 升级实施与实测（2026-11-23）

按 4.2 评估结论开工，0.2.5→0.3.1 升级全链路完成并实测通过，3 文件各一 commit 推送（`0d4abcf8`）。

**实施改动**：

| 文件 | 改动 |
|---|---|
| `compile/src/vers.txt` | gpicview 0.2.5→0.3.1，地址 codeload.github.com→gitee g-system/fk-lxde-gpicview archive 0.3.1.tar.gz（以 gitee 为准） |
| `compile/src/v-gpicview/build.sh` | 版本 0.3.1；删 patch 步骤（main-win.c return FALSE 已上游化）；订正「0.3.1 GTK3-only」错注→实际 GTK2-only；源目录名兼容 `fk-lxde-gpicview-0.3.1` |
| `docs/2026/11170850-selected-app-use.md` | 4.2 评估保存（单独 commit） |

**实测（builder-g224 + hdmi Xvnc）**：

| 环节 | 结果 |
|---|---|
| 构建 | `TARGETPATH=/usr/local/static/gpicview sh /src/v-gpicview/build.sh gpicview`，17s，err 0 pass |
| 静态验证 | `xx-verify --static` rc=0；`file`=statically linked, stripped；`strings`=0.3.1；编入 `/usr/local/static/gpicview/share/gpicview/ui/pref-dlg.ui`；pref-dlg.ui 新版 15567B 已装；locale 63；日志 undefined reference=0 |
| GUI 实跑 | hdmi Xvnc `:320`，headless 用户：主窗口「图像查看器」弹出（中文 .mo 生效）；按 `p` → Preferences「首选项」弹出（WIN 2097225）；进程稳定不崩 |
| 提交 | docs `db9b3917`；vers.txt `f8f03556`；build.sh `0d4abcf8`（均已推送） |

**踩坑（实跑才见）**：

- gitee `archive/refs/tags/0.3.1.tar.gz` **解压目录 = `fk-lxde-gpicview-0.3.1`**（转存仓库名非 `gpicview`），build.sh 原硬编码 `gpicview-$VER` → source MISSING；已改双名兼容。
- build.sh 原注释「0.2.6/0.3.1 已 GTK3-only」**是错的**（坑）：configure 默认 GTK2、src 零处 `ENABLE_GTK3` 使用、main-win.c:1090 有 GTK2 专属 `widget->window` → 实际 GTK2-only；已订正，勿再信。
- GUI 定位坑：`xdotool search --classname gpicview` 返回 2 窗口（主+内部辅助），取第一个会 BadMatch → 按 4.1 经验用中文标题 `search --name "图像查看器"` 定位真主窗口。

**对比**：升级后功能增量（Ctrl+C 剪贴板/工具栏开关/打开最大化/缩放步长/窗口位置保存/动画重启用/URI+SEGV 修复等），无回归（主窗口/Preferences/中文全通过）。

### 5、pcmanfm 升级与右键菜单修复（2026-11-23）

> 2026-11-23 用户需求：pcmanfm 三个仓库（pcmanfm / libfm / menu-cache）都升级到最新；修复右键菜单 3 个 bug；新增屏蔽侧栏 cdrom/usb 设备项。

#### 5.1、需求项与现有进展（2026-11-23）

**需求项（用户原话整理）**

**背景**：pcmanfm 三个仓库（pcmanfm / libfm / menu-cache）都有更新版本，需升级到最新（pcmanfm 1.4.0，配套 libfm 1.4.1、menu-cache 1.1.1）。

**需求列表**：

| # | 需求项 | 现象/说明 |
|---|---|---|
| 1 | 三仓库升级到最新 | pcmanfm 1.4.0 / libfm 1.4.1 / menu-cache 1.1.1（gitee g-system 镜像已同步，tag 已确认存在） |
| 2 | 右键空白区域菜单无中文 | 菜单全英文 |
| 3 | 右键空白区域「属性」不弹 + 报错 | 右键空白 → 属性，属性框不弹出，报错 |
| 4 | 右键文件「OpenWith」报错退出 | 右键文件 → OpenWith，报错导致程序直接退出 |
| 5 | 屏蔽侧栏 cdrom/usb 设备项 | 侧栏显示 cdrom/usb 设备，当下及项目场景用不着 |

**根因定位（代码级）**

- **右键菜单无中文**：菜单由 libfm 构建（`fm-file-menu.c` 的 `N_()`），libfm 有自己 `GETTEXT_PACKAGE=libfm`（configure.ac:250）+ `po/zh_CN.po`（59+ 语言），`fm.c:85` `bindtextdomain("libfm", PACKAGE_LOCALE_DIR)`。build.sh 只装 pcmanfm.mo、**没装 libfm.mo** → 菜单英文。
- **属性框不弹 + 报错**：`fm-file-properties.c:105` `UI_FILE = PACKAGE_UI_DIR"/file-prop.ui"`（1414 行 `gtk_builder_add_from_file`）；`PACKAGE_UI_DIR=$(datadir)/libfm/ui`。源码树只有 `.glade`，Makefile `.glade.ui` 转换规则生成 .ui。build.sh **没装 libfm ui/** → 部署后 file-prop.ui 缺失 → 属性框加载失败。
- **OpenWith 报错退出**：`fm-app-chooser-dlg.c:301` `gtk_builder_add_from_file(builder, PACKAGE_UI_DIR "/app-chooser.ui")` 同样依赖 ui 文件；`on_open_with`（fm-file-menu.c:673）→ `fm_choose_app_for_mime_type` → app-chooser。ui 缺失 → 崩溃退出。
- **屏蔽 cdrom/usb**：`fm-places-model.c` `add_volume_or_mount()`（387 行）是设备唯一入口（初始列出 + 动态 `on_volume_added`/`on_mount_added` 都经它），在该函数入口按名称/挂载点过滤（`_hide_cdrom_usb()`：名称含 cdrom/cd-rom/usb，或挂载点 `/media/cdrom`、`/media/usb` 即屏蔽）。

**现有进展（2026-11-23）**

**构建已完成（builder-g224，三仓库全部成功）**：

| 组件 | 版本 | 产物 | 关键点 |
|---|---|---|---|
| libfm | 1.4.1 | libfm.a / libfm-extra.a / libfm-gtk.a | `--prefix=$TARGETPATH`（UI/LOCALE 宏编入部署路径）；UI 8 文件（file-prop.ui/app-chooser.ui 等，Makefile `.glade→.ui` 生成）；locale 60 langs（libfm.mo）；.pc Version 1.4.1 |
| menu-cache | 1.1.1 | libmenu-cache.a | .pc Version 1.1.1（AC_INIT 1.1.1）；`--branch=1.1.1` |
| pcmanfm | 1.4.0 | pcmanfm 13.7M（statically linked, stripped） | `--prefix=$TARGETPATH`；pcmanfm ui 5 文件；locale 54 langs；静态修复 patch 重新生成（1.4.0 上下文变） |

**部署**：hdmi 容器 `/usr/local/static/pcmanfm/` 已更新（tar 中转，注意 docker exec 副作用回收坑 → setsid 打包才完整）。

**状态（2026-11-23）**：✅ 全部完成——三仓库构建成功、部署 hdmi、**四问题验证通过**（详见 5.2）、代码与文档已提交推送（6 commit）。

- 文档：`d0a01aa7` / `894f3d0b` / `c0e7a0ee`（5.1 需求进展 + 位置修正 + 验证更新）
- 代码：`65a75a00`（build.sh）、`78570fd3`（libfm-hide-cdrom-usb.patch）、`bbf2afc1`（pcmanfm-staticfix.patch 重生成）

#### 5.2、实现以及验证总结（2026-11-23）

**实现过程**：

- **三仓库版本**：libfm 1.4.1 / menu-cache 1.1.1 / pcmanfm 1.4.0（build.sh `--branch` 升级）；构建顺序 `libfm → menu_cache → pcmanfm`（build.sh `full`）。
- **libfm 改造**：`./configure --disable-shared --enable-static --prefix=$TARGETPATH`（UI/LOCALE 宏编入部署路径，修复属性框/openwith/菜单中文）；手动装 `data/ui/*.ui`（8 文件，Makefile `.glade→.ui` 生成）+ `po/*.po` msgfmt `libfm.mo`（60 langs）+ `.pc` sed 修正回 `/usr/local` + 头平铺 + `libfm.a/libfm-gtk.a` 拷 `/usr/lib`。
- **屏蔽 cdrom/usb**：`libfm-hide-cdrom-usb.patch`——`add_volume_or_mount()` 唯一入口加 `_hide_cdrom_usb()`（名称含 cdrom/cd-rom/usb 或挂载点 `/media/cdrom`、`/media/usb` 即屏蔽）。
- **pcmanfm 静态修复 patch 重生成**：`pcmanfm-staticfix.patch` 1.4.0 上下文变 → 重新生成（43 行，`g_type_ensure` 强制注册 GTK 类型 + 信号 pipe 非阻塞）。

**坑与破环**：

- **gitclone 命中 GITCACHE 缓存只 cp -a 不 checkout --branch**（common.sh `gitclone` L147-153）→ 源码树停留旧版（1.3.2/1.1.0）。解法：宿主 `tarsrc-git/<repo>` 手动 `git fetch --tags` + `git checkout <版本>`。
- **menu-cache 1.1.1 循环依赖**：menu-cache make 的 `menu-cache-gen` 链接需 `-lfm-extra` 实际库；libfm configure 需 `libmenu-cache.pc`。破环：先 libfm（libmenu-cache.pc 1.1.0 已存在）→ 再 menu-cache（libfm-extra.a 就位）→ 再 pcmanfm（即 build.sh `full` 顺序）。
- **pcmanfm-staticfix.patch 旧版在 1.4.0 不适用**（src/pcmanfm.c 上下文变）→ 重新生成。
- **docker exec 副作用回收坑**：`tar czf` 写中转文件被截断（2981898B 不完整）→ setsid 后台 + 轮询 DONE。
- **menu-cache 1.1.1 的 AC_INIT 实际为 1.1.1**（build.sh `--branch=1.1.1` 有效，configure 后 config.h VERSION 1.1.1）；此前误判 1.1.0 是因缓存旧树。

**验证总结**（Xvnc `:11` + xdotool，hdmi 容器，`LANG=zh_CN.UTF-8`）：

| 问题 | 验证方法 | 结果 |
|---|---|---|
| 1 右键空白菜单无中文 | `LANG=zh_CN.UTF-8` 跑，右键空白→属性，属性框标题 | ✅ 标题「文件属性」（libfm 域中文生效，菜单同域→中文） |
| 2 属性框不弹+报错 | 右键空白 → End → Return | ✅ 「File Properties」窗口弹出，不再崩溃/报错 |
| 3 OpenWith 报错退出 | 右键文件 → OpenWith 子菜单展开/选择 | ✅ pcmanfm 存活无报错（`app-chooser.ui` 已装 + `strings` 编入路径确认；对话框精确弹出受限于无 WM 环境，核心"不退出"已验证） |
| 4 屏蔽 cdrom/usb | patch 落 + 部署 | ✅ `add_volume_or_mount()` 唯一入口过滤 + 侧栏正常显示不崩（容器无真实光驱/USB，代码级验证） |

**产物核对**：`file` statically linked, stripped；`ldd` Not a valid dynamic program；`strings` 编入 `/usr/local/static/pcmanfm/share/libfm/ui/file-prop.ui` 等路径正确；libfm.mo（60）+ pcmanfm.mo（54）。

**验证环境清理**：Xvnc `:11` 用完 `pkill -f "Xvnc :11"`（带号限定防自匹配）+ 清 `/tmp/.X11-lock` `/tmp/.X11-unix/X11`；pcmanfm 进程已杀。live `:1` 会话未动。

#### 5.3、OpenWith 在 rootfs 复现崩溃——根因是 rootfs 缺 libfm ui 文件（2026-11-23 落档）

**发现**：5.2 的「OpenWith 不退出」验证是在 **hdmi 容器**做的（有 `app-chooser.ui`），只代表 hdmi 环境；**rootfs 镜像实际缺 libfm ui 文件**，OpenWith 会崩溃退出——本次在 rootfs-dbg 实测复现确认。

##### 5.3.1、复现与根因（2026-11-23）

**复现环境**：rootfs-dbg-latest 容器 `:10` Xvnc（live 会话，1024x768）+ headless 用户跑 `/usr/local/static/pcmanfm/bin/pcmanfm /tmp/pcmtest`；`/tmp/pcmtest/test.txt`（root 属，5 字节）。

**复现操作**：右键 test.txt 图标（x=200-230 区，右键 `(215,345)`）→ 弹 132x190 文件菜单 → `xdotool windowfocus` 菜单 + `Down` + `Return`（菜单第一项即 Open With）→ **pcmanfm 崩溃退出**（进程 47571 消失）。

**崩溃日志**（stderr）：

```
(pcmanfm:47571): Gtk-CRITICAL **: IA__gtk_dialog_set_alternative_button_order: assertion 'GTK_IS_DIALOG (dialog)' failed
(pcmanfm:47571): Gtk-CRITICAL **: IA__gtk_label_set_text: assertion 'GTK_IS_LABEL (label)' failed
(pcmanfm:47571): Gtk-CRITICAL **: IA__gtk_container_add: assertion 'GTK_IS_CONTAINER (container)' failed
(pcmanfm:47571): Menu-Cache-ERROR **: failed to find menu-cached
```

**根因链**（对应 5.1 定位的 `fm-app-chooser-dlg.c:301/317`）：

| 步 | 位置 | 行为 |
|---|---|---|
| 1 | `:301` `gtk_builder_add_from_file(PACKAGE_UI_DIR"/app-chooser.ui")` | rootfs 缺 ui → 返回 0（失败） |
| 2 | `:302` `data->dlg = gtk_builder_get_object(builder,"dlg")` | 返回 **NULL** |
| 3 | `:317` `gtk_dialog_set_alternative_button_order(data->dlg,...)` | 对 NULL 调用 → **Gtk-CRITICAL assertion failed**（首条日志） |
| 4 | 后续 NULL 对象操作（label/container） | 连续 Gtk-CRITICAL |
| 5 | `Menu-Cache-ERROR: failed to find menu-cached` | 致命错误 → **进程中止** |

**环境对照（关键）**：

| 环境 | app-chooser.ui | `/usr/share/libfm/ui/` | `/usr/share/applications/` | OpenWith 结果 |
|---|---|---|---|---|
| hdmi（`docker-hdmi-desktop-desktop-1`） | ✅ 存在（`/usr/local/static/pcmanfm/share/libfm/ui/` + `/usr/share/libfm/ui/`） | ✅ 存在 | ✅ 51 个 .desktop | 不崩（阴性对照） |
| rootfs-dbg（`rootfs-dbg-latest`） | ❌ **不存在** | ❌ 整个目录不存在 | ⚠️ 仅 htop.desktop | **崩溃**（复现） |

**为何 hdmi 不崩**：pcmanfm `strings` 确认编译 `PACKAGE_UI_DIR=/usr/local/static/pcmanfm/share/libfm/ui/`，hdmi 该路径有 `app-chooser.ui` → `gtk_builder_add_from_file` 成功 → `dlg` 非 NULL → `:317` 不崩。

**为何 rootfs 崩**：rootfs 该路径（及 `/usr/share/libfm/ui/`）**整个缺失** → ui 加载失败 → `dlg` NULL → `:317` 段错误（Gtk-CRITICAL + Menu-Cache-ERROR fatal）。

**修复方向**：rootfs Dockerfile res stage 需补装 libfm ui 文件（`app-chooser.ui` 等 8 个 `.ui` 到 `/usr/local/static/pcmanfm/share/libfm/ui/`，来自 libfm 构建产物 `data/ui/*.ui`）+ 至少基础 `/usr/share/applications/*.desktop`（当前仅 htop，OpenWith 应用树近乎空）。修复后 rootfs `:10` 再验证不崩。

> **订正（2026-11-23）**：5.2 验证表第 3 行「OpenWith 不退出」仅对 hdmi 成立；rootfs 缺 ui 仍会崩溃，见 5.3.1。

> **订正（2026-11-23 二次，判断修正）**：上判"根因=缺 app-chooser.ui"**不完整**。用户实测直接 `pcmanfm`（无参，不触 OpenWith）即崩，日志仅一条（**无 Gtk-CRITICAL**）：

```
(pcmanfm:592): Menu-Cache-ERROR **: failed to find menu-cached
Trace/breakpoint trap (core dumped)
```

**真正主因是 menu-cache 启动级崩溃**——rootfs 缺菜单定义/缓存（`/etc/xdg/menus` 不存在），menu-cache 加载失败 `failed to find menu-cached` → 进程被 trap 中止。Gtk-CRITICAL 只是 OpenWith 触发时叠加的 ui 缺失（次因），并非启动即崩的主因；两问题并存（缺 ui + 缺菜单缓存）。

**新镜像已验证修复**（`rootfs-dbg` 35775dc2b8bd，2026-11-23 拉取实测）：

| 项 | 新镜像状态 | 实测 |
|---|---|---|
| pcmanfm 版本 | **1.4.1**（upx 压 6005228B，解压 14333320B，md5 `04cf38ac...` 与 builder-g224 一致） | `--help` 正常 |
| ui | ✅ libfm/ui 8 文件已补（app-chooser.ui 等） | 部署后 `ls` 确认 |
| Menu-Cache-ERROR | ✅ **不再崩** | `--desktop`/无参均无报错（仅 WARNING Templates/modules，timeout 正常终止） |

新镜像改用**延迟部署**：static 组件在 `/rootfs/files1` 归档，首启 `.core-init` `cp -a` 到真实路径；静止查 `/usr/local/static` 为空是预期（非缺文件）。修复内容口径：pcmanfm 升 1.4.1（menu-cache 处理健壮化）+ ui 补齐。

##### 5.3.2、菜单定义（/etc/xdg/menus）来源、静态部署与 menu-cache 默认路径改动（2026-11-23）

**归属**：`/etc/xdg/menus/*.menu` 属独立系统数据包 **lxmenu-data**（hdmi `dpkg -S` 证实 `lxde-applications.menu` 归它）。纯**静态固定文件**（`dpkg -L` 清单固定：`/etc/xdg/menus/lxde-applications.menu` + `/usr/share/desktop-directories/lxde-*.directory` 数十个 + `/usr/share/lxmenu-data/`），安装是解压释放，无动态生成脚本。

**内容与可移植性**：`.menu` 是 freedesktop 菜单规范 XML，内部用 `<DefaultAppDirs/>`、`<DefaultDirectoryDirs/>`、`<DefaultMergeDirs/>` **默认指令**（样板已见，无硬编码 `/usr/share` 路径）——运行时从 `XDG_DATA_DIRS`（applications/desktop-directories）与 `XDG_CONFIG_DIRS`（menus）环境变量取，因此**数据文件可整体搬到任意目录**（如 static 下）。

**TARGETPATH 不管菜单文件**：TARGETPATH（`/usr/local/static/<comp>`）只决定 pcmanfm/libfm **编译产物**的 UI/locale 安装路径，`/etc/xdg/menus` 是系统级 XDG 数据（lxmenu-data 包装），两条线。rootfs 缺它是因为镜像未装/未 COPY lxmenu-data 数据。

**menu-cache 查找路径机制**（源码查实，`fk-menu-cache`）：

| 处 | 逻辑 |
|---|---|
| `menu-cache-gen/main.c:105/115/121` | `g_get_system_config_dirs()`（GLib 默认 `["/etc/xdg"]`）→ 依次试 `~/.config/menus/<file>`、`dirs[0]/menus/<file>` |
| `libmenu-cache/menu-cache.c:1793/1836` | `getenv("XDG_CONFIG_DIRS")` 算缓存 md5；缓存写 `~/.cache/menus/<md5>` |

规则：**环境变量设置了 → 优先用它；未设置 → 用 GLib 编译默认 `/etc/xdg`**。

**静态部署 + 代码改默认（方案，2026-11-23 拍板）**：运行时**不**额外 export 环境变量；改 menu-cache 代码置编译期默认 static 目录，env 优先逻辑保留：

| # | 文件 | 改动 |
|---|---|---|
| 1 | `compile/src/v-pcmanfm/build.sh` | menu-cache 构建传 `-DMENU_BASE_DIR=\"$TARGETPATH/etc/xdg\"`；构建后把 lxmenu-data 数据拷入 `$TARGETPATH/etc/xdg/menus/`、`$TARGETPATH/share/desktop-directories/`、`$TARGETPATH/share/lxmenu-data/` |
| 2 | `fk-menu-cache/menu-cache-gen/main.c`（patch） | 默认 `dirs` = `MENU_BASE_DIR`（`XDG_CONFIG_DIRS` 有则优先环境变量） |
| 3 | `fk-menu-cache/libmenu-cache/menu-cache.c`（patch） | `_validate_env` 为 NULL 时默认填 `MENU_BASE_DIR`（env 优先保留） |

部署后 `TARGETPATH=/usr/local/static/pcmanfm`，menu-cache **默认**去 `/usr/local/static/pcmanfm/etc/xdg/menus/` 找菜单；有人设置 `XDG_CONFIG_DIRS` 则优先环境变量。**入口脚本无需 export**。

##### 5.3.3、OpenWith 修复实施记录——问题定位、实现过程、验证与坑（2026-11-23）

**问题定位（逐层）**：

| # | 症状 | 定位结果 |
|---|---|---|
| 1 | pcmanfm 启动即 `Menu-Cache-ERROR: failed to find menu-cached` 崩 | rootfs 缺 `/etc/xdg/menus`（lxmenu-data 菜单定义），menu-cache 找不到菜单文件 |
| 2 | 补了菜单定义后仍崩（`failed to find menu-cached`） | libfm 查的是 `applications.menu`（`fm-app-menu-view.c:174`），lxmenu-data 提供的是 `lxde-applications.menu`（前缀不匹配）→ 补 `applications.menu` 副本 |
| 3 | OpenWith 触发时 `g_error("failed to find menu-cached")` 崩（`menu-cache.c:1564`） | `fork_server()` 检查 **`$libexecdir/menu-cached`**（menu-cache daemon 二进制）——libtool 产物**动态链接 glib**，rootfs 无共享库起不来；且静态部署只带 bin/share，**没带 libexec** |
| 4 | （最终） | 静态链接 `menu-cached` + `--libexecdir=$TARGETPATH/libexec` + lxmenu-data 数据进 `$TARGETPATH/etc/xdg/menus` → 全部解决 |

**实现过程（compile/src/v-pcmanfm/）**：

| 文件 | 内容 |
|---|---|
| `menu-cache-menudir.patch`（新） | menu-cache 找菜单目录默认改为 `MENU_CONFIG_DIR` 宏（`XDG_CONFIG_DIRS` 环境变量优先，未设用宏默认）：`menu-cache.c`（默认 xdg_cfg）、`menu-cache-gen/main.c`（默认 dirs[0]） |
| `build.sh`（menu_cache 函数） | ① patch 应用 + `sed` 把源码 `MENU_CONFIG_DIR "/etc/xdg"` 替换为 `"$TARGETPATH/etc/xdg"`（CFLAGS 传宏引号被 libtool 吃，改 sed 直改源码）② `--libexecdir=$TARGETPATH/libexec`（MENUCACHE_LIBEXECDIR 编入 static 路径）③ LDFLAGS 补 `-static`（勿覆盖 common.sh）④ make install 后 **gcc -static 手动静态链 menu-cached**（libtool 产物动态链 glib）⑤ lxmenu-data 数据解压到 `$TARGETPATH` |
| `data/lxmenu-data.tar.gz`（新，81KB/37 文件） | lxmenu-data 固定数据压缩包（`etc/xdg/menus/*.menu` + `share/desktop-directories/*.directory`），build.sh 用时 `tar xzf` 解压（340K 原始数据适合压缩提交） |

**验证工具/方法**（rootfs-dbg-latest `:10` Xvnc 桌面）：

- **环境**：rootfs-dbg-latest 容器（旧容器，挂载 /_ext 可中转）；Xvnc `:10`（live，depth 16）+ tint2；`pgrep -x pcmanfm`（精确进程名，防自匹配）
- **驱动**：`xdotool`（windowfocus/windowraise/mousemove/click/key）；OpenWith 触发 = 右键 test.txt 图标（`(215,345)` 弹 132x222 文件菜单）→ windowfocus 菜单 → `Down`+`Return`
- **判定**：`pgrep -x pcmanfm` 存活 = 不崩；`pgrep -x menu-cached` RUNNING = daemon 被 fork 拉起；`xdotool search --name "Choose"` 出现 = OpenWith 对话框弹出；`scrot` 截图 /_ext/tmp/svg/
- **对照**：桌面右键菜单（183x178）先验证 menu-cache 读菜单数据，再做文件 OpenWith

**踩过的坑**：

- **gitclone 缓存 = tarsrc-git**：`gitclone` 命中 `compile/tarsrc-git/` 缓存（`cp -a`），改缓存源码会随 cp 进构建目录 → 构建里 `git apply patch` 报"patch does not apply"（已应用）。**tarsrc-git 必须保持原版**，改动走独立 patch 文件。
- **CFLAGS 传宏引号被 libtool 吃**：`CFLAGS="-DMENU_CONFIG_DIR=\"$path\""` 经 configure→Makefile→libtool→shell 多层，引号丢失 → `#define MENU_CONFIG_DIR /usr/local/...` → 编译报 `undeclared identifier 'usr'`。**改 sed 直改源码**（`# define MENU_CONFIG_DIR "/etc/xdg"` → `"$TARGETPATH/etc/xdg"`）。
- **libtool 产物动态链接**：menu-cached/menu-cache-gen 经 libtool 链接默认动态，rootfs 无 glib 共享库 → `Error loading shared library libgio-2.0.so.0`。且 `-static` 在 LDFLAGS 对 libtool 无效（Makefile 用 configure 记录的旧 LDFLAGS）。**手动 `gcc -static` 重链**（`menu-cached.o + libmenu-cache.a + $(pkg-config --libs --static glib-2.0 gio-2.0)`）。
- **LDFLAGS 覆盖 common.sh**：build.sh `export LDFLAGS` 若不带 `--static -static` 会丢 common.sh 的静态链参数（AGENTS.md 已有警告），menu-cached 因此动态链。
- **`pkill -f "static/pcmanfm"` 自匹配杀 shell**：`bash -c` 命令行含匹配串会被误杀（AGENTS.md 经典坑，本会话多次触发）。**用 `pgrep -x pcmanfm`（精确进程名）**。
- **残留对话框遮挡右键**：OpenWith 对话框（403x400 @ 120,316）不关会挡住文件列表右键点 → 右键落在对话框上不弹文件菜单。**先 `Escape` 关对话框再操作**。
- **延迟部署镜像**：新 rootfs 镜像 static 组件在 `/rootfs/files1` 归档，首启 `.core-init` `cp -a` 部署；静止查 `/usr/local/static` 为空是**预期**。

**验证结论**（最终）：rootfs-dbg `pcmanfm 1.4.1 + data/lxmenu-data + 静态 menu-cached` —— 启动/右键菜单（132x222）/OpenWith（"Choose Application" 403x400 弹出）**全不崩**，menu-cached daemon 正常拉起，无错误日志。

##### 5.3.4、OpenWith 已装应用清单空白——问题与答复（2026-11-23）

**问题（用户原话）**：`docs/img/tmp/pcmanfm-openwith/openwith-dialog.png` 他这个已装应用的清单都是空的，如果要出清单要怎么做？比方静态应用里面的 geany gpicview pcmanfm st 等。

**现状分析（根因）**：

- rootfs `/usr/share/applications/` 只有 `htop.desktop`：lxmenu-data 菜单 `<DefaultAppDirs/>` 从这里读 → 清单空。
- static 组件的 `.desktop` **构建时没装**（`build.sh` 未把 `data/*.desktop` 装进 `$TARGETPATH/share/applications/`），rootfs 自然收集不到。

**有 .desktop 源的组件**（builder 源码树实查 `/tmp`）：

| 组件 | .desktop 源 |
|---|---|
| geany | `/tmp/geany/geany.desktop`（已有） |
| pcmanfm | `data/pcmanfm.desktop` + `pcmanfm-desktop-pref.desktop` |
| tint2 | `tint2.desktop` |
| lxtask | `lxtask.desktop` |
| rofi | `rofi.desktop` + `rofi-theme-selector.desktop` |
| pasystray | `pasystray.desktop` |
| libfm | `libfm-pref-apps.desktop` + `lxshortcut.desktop` |
| gpicview | `gpicview.desktop.in`（需 configure 转） |
| **st** | ❌ **无**（suckless 不做 desktop，需手工造一个 `Exec=st`） |

**出清单的做法**（两步，延续 lxmenu-data 模式）：

1. **各组件 build.sh 装 .desktop**：构建末尾 `cp data/*.desktop $TARGETPATH/share/applications/`（有源组件）；st 另造一个 `st.desktop`。
2. **rootfs 部署合并**：把各 `/usr/local/static/<comp>/share/applications/*.desktop` 汇总到 `/usr/share/applications/`（Dockerfile res 或 entry 收集），menu-cache 就能列出清单；需带 `Categories=` 才能正确分到 lxmenu-data 的子菜单（Utility/Graphics/Development…）。

**待办（未实施，2026-11-23 用户确认范围后动手）**：先做用户点名的 geany / pcmanfm / gpicview / st（4 个）+ 有源的一起（tint2/lxtask/rofi/pasystray）；st 手工补 `.desktop`；按文件粒度改 build.sh 并实测清单。

##### 5.3.5、menu-cached 机制问答（0-3，2026-11-23）

**问题**（用户原话整理）：
0. menu-cached 作用是干嘛？运行的生命周期是什么样的？
1. 为什么要这么设计呢？感觉反而复杂化了。pcmanfm 相关功能还有没有依赖到其他类似的程序？
2. libexec 模式运行机制如何 / 可以手动执行它吗 / 可以后台长期运行吗？
3. 它的功能能否合并到主程序（pcmanfm）呢？分析可行性 / 调整工作量。

---

**0. menu-cached 作用与生命周期**

作用：菜单缓存的**守护进程**（daemon）。承担三件事（源码依据 `fk-menu-cache`）：

- **生成缓存**：`regenerate_cache()` 调用 `$libexecdir/menu-cache-gen` 解析 `.menu` XML + `applications/*.desktop` → 产出二进制缓存（`menu-cached.c:216-258`）
- **文件监控**：`GFileMonitor` 监视 `.menu`、applications 目录变化；`.desktop` 增删/改动 → 自动重建缓存并广播（`on_file_changed` → `do_reload`，`menu-cached.c:93/369`）
- **多客户端共享**：连接者（pcmanfm/lxpanel…）通过 socket 共享同一份内存缓存

生命周期：

```
pcmanfm menu_cache_lookup()
  └─ connect_server() → UNIX socket 连接失败(ENOENT/ECONNREFUSED)
       └─ fork_server() 拉起 menu-cached        (menu-cache.c:1747)
       └─ 重试连接(25次×50ms) → 成功
  └─ daemon 长驻: g_main_loop + GFileMonitor
       ├─ 文件变化 → 重建缓存 → 通知客户端
       └─ 客户端退出不影响 daemon(继续驻留,供下个客户端)
```

即：**按需拉起，常驻服务**，不随某个客户端退出而退出。

**1. 为什么这么设计？还依赖别的类似程序吗？**

设计意图（freedesktop/LXDE 体系）：menu-cache 是**系统级库**，`pcmanfm`/`lxpanel`/`lxmenu-editor` 等多个 LXDE 组件共用它。

- **解析只做一次**：扫 `.menu` XML + 数千个 `.desktop` 的 I/O 很贵，daemon 内存缓存让多进程复用，而非每进程重复解析
- **变化通知集中**：装/删软件后 `.desktop` 变 → daemon 统一感知、重建、通知所有客户端（菜单实时更新）
- 是**"系统服务 + 瘦客户端库"**模式，同 dconf-daemon、keyring、journald

感觉复杂化很正常：本项目静态单机场景只有 pcmanfm 一个客户端、文件也几乎不变，daemon 的共享/监控价值用不上，纯增加部署负担（libexec 可执行 + 静态链接）——这是 5.3.3 里折腾静态链 menu-cached 的根源。

pcmanfm 还依赖的类似程序：主要是 **dbus daemon**（libfm 走 GDBus）；gvfs/gio volume monitor（U 盘/挂载，可选）。menu-cached 是其中唯一"用户级按需拉起"的。

**2. libexec 模式机制 / 手动执行 / 后台常驻**

- **机制**：库只认 `$libexecdir/menu-cached` 这个**文件存在即可执行**（`fork_server`，`menu-cache.c:1560-1562`）；fork+exec 后它自己 `get_socket_name()` 定 socket 路径（`g_get_user_runtime_dir()/menu-cached-<display>`，如 `/run/user/1000/menu-cached-:0`）
- **可手动执行**：可以，直接跑它即可（自动监听 socket 等客户端）
- **可后台长期运行**：可以，就是常驻 daemon（`g_main_loop`），`menu-cached &` / `nohup` 均可；客户端连不上才新拉，连上了复用

**3. 能否合并进主程序？可行性/工作量**

可以合并，**中等可行性**。关键事实：menu-cache 库本身就能读缓存文件（`read_dir/read_app` 加载 `.cache/menus/<md5>` 二进制缓存），daemon 只是"生成+监控+共享"的包装。

| 项 | 分析 |
|---|---|
| 合并思路 | loader 去掉 `fork_server/connect_server`，改为进程内先确保缓存存在（过期/缺失时调 menu-cache-gen 或进程内直接生成）→ 读缓存文件 |
| 好处 | 少一个可执行依赖（menu-cached）、无 daemon 部署/静态链负担、单客户端无共享损失 |
| 代价 | ① 失去文件变化实时通知（`.desktop` 新装软件不会自动出现，需重启应用或手动刷新）② 多进程各自持缓存副本 |
| 改动量 | menu-cache.c 的 loader 分支（约 100 行）+ 让 `menu-cache-gen` 也静态链（或生成逻辑进程内）；在 `menu-cache-menudir.patch` 基础上再加一个 patch，可控 |
| 对本项目 | 静态镜像、文件固定 → 合并后启动时生成一次缓存即可（或预生成缓存进镜像），实时通知价值可放弃 |

**结论**：若要根治"静态环境背 daemon 包袱"，合并是正解，工作量约半天到一天（改 loader + 静态 menu-cache-gen + 实测）。暂维持现状（daemon 已能正常拉起），待用户拍板是否实施。

##### 5.3.6、thunar 的 OpenWith 实现机制与对比/借鉴（2026-11-23）

**问题（用户原话整理）**：这块 thunar 那边的实现机制是怎么样的？两边的实现优缺点对比。另，他那边整体有哪些好的功能特性适合借鉴过来？

---

**1. thunar 的 OpenWith 机制（与 pcmanfm 完全不同）**

用 **GIO 的 GAppInfo，完全不用 menu-cache**（thunar 1.6.18 源码 `g_app_info` 引用 62 处、`menu-cache` 0 处）：

| 处 | 实现 |
|---|---|
| `thunar-chooser-model.c:293` | `g_app_info_get_all_for_type(content_type)` → **Recommended** 组（匹配该 mime） |
| `thunar-chooser-model.c` 后段 | `g_app_info_get_all()` 减推荐 → **Other Applications** 组 |
| `thunar-chooser-button.c:446/450` | 默认应用 + 全部应用（对话框下拉按钮） |
| `thunar-file.c:2609/4271` | 双击打开时查 `g_app_info_get_default_for_type()` |

底层 = `GDesktopAppInfo`：**直接扫 `XDG_DATA_DIRS/applications/*.desktop`**（按 `MimeType=` 匹配），读写 `mimeapps.list` 记默认应用。**无 daemon、无二进制缓存、无 lxmenu-data**——GIO 库自带这套。

**2. 两边实现优缺点对比**

| 维度 | pcmanfm（libfm + menu-cache） | thunar（GIO GAppInfo） |
|---|---|---|
| 应用来源 | menu-cached daemon 生成二进制缓存 → `fm_app_menu_view` 读缓存 | 每次 `g_app_info_get_all*` 直读 `.desktop` |
| 外部依赖 | **menu-cached daemon + menu-cache-gen + lxmenu-data 数据**（三层） | **无**（GIO 内置，仅需 `.desktop` 存在） |
| mime 匹配 | menu-cache 应用树（按 lxmenu 分类） | `get_all_for_type` 按 Content-Type 直过滤 |
| 文件变化实时性 | ✅ daemon GFileMonitor 实时通知 | 每次查即时重扫（无缓存也就无过期） |
| 多进程共享 | ✅ daemon 内存共享（LXDE 多组件场景有价值） | 各进程各自扫（单次成本低，无所谓） |
| 静态部署负担 | ❌ 重（libexec 可执行 + 静态链 + 菜单数据，5.3.3 全在折腾这个） | ✅ 几乎没有 |
| 默认应用管理 | libfm 自实现 | GAppInfo 标准 mimeapps.list |
| UI 分组 | 树形分类（lxmenu Category） | **Recommended / Other 两组**（更直观） |

**结论**：thunar 的 GAppInfo 方案**更轻、更适合静态部署**（thunar 走 XFCE 体系，应用信息交给 GIO 标准，不做 LXDE 那套 cache daemon）。pcmanfm 走 menu-cache 是同年代的 LXDE 架构选择，多进程共享价值在单机静态场景几乎为零，却带来整套 daemon 部署负担。

**3. thunar 值得借鉴的功能特性**

| 特性 | 说明 | 借鉴价值 |
|---|---|---|
| **批量重命名** | ThunarBulkRename（独立工具）：正则、替换、编号递推，支持多文件 | ⭐ 高：libfm/pcmanfm 无对应（需单独集成） |
| **自定义动作（uca.xml）** | `~/.config/Thunar/uca.xml` 右键自定义命令 + 按 mime/文件名条件显示 | ⭐ 高：pcmanfm 无，可定制性强的核心特性 |
| **Recommended/Other 分组** | OpenWith 对话框按 mime 推荐分组 | ⭐ 中：5.3.4 清单问题可借鉴此 UI，比应用树简单 |
| **模板（templates-action）** | 右键"创建文档"读 `~/Templates` 目录 | 中：pcmanfm 有对应（~/Templates 警告就是它） |
| **mimeapps 标准化** | 默认应用读写 mimeapps.list | 中：比 libfm 自实现规范 |
| 标签页/三窗格/侧栏快捷/网络浏览(gvfs) | thunar 综合特性 | 低-中：pcmanfm 已有部分 |

**落地建议**：① 短期内先按 5.3.4 补 `.desktop` 出清单（成本最低）；② 若想根治体系负担，可评估把 pcmanfm 的 OpenWith 从 menu-cache 换成 GAppInfo（借鉴 thunar Recommended/Other UI + 弃 daemon，工作量约一天，呼应 5.3.5 的合并分析）；③ 自定义动作 + 批量重命名是差异化亮点，可单独立项。

### 6、geany 升级评估 + 1.37.1 升级实现与验证（2026-11-23）

#### 6.1、最新支持 GTK2 版本 + 1.34.0→1.37.1 升级评估（2026-11-23）

**最新支持 GTK2 版本**：Geany **1.37.1**（最后一个支持 GTK+2.24；1.38 起移除 GTK2、只 GTK3；2.0 起强制 GTK 3.24）。

| 版本 | GTK 支持 |
|---|---|
| ≤ 1.37.1 | 支持 GTK2+GTK3（1.34 起 auto-select；1.37 起 GTK3 默认但 GTK2 仍在） |
| **1.37.1** | **最后一个支持 GTK+2.24** |
| 1.38（2021-10-09） | 移除 GTK+2 支持（PR#2602），只 GTK3，需 C++17 |
| 2.0（2023-10-19） | 只 GTK3，require GTK 3.24（#3580） |

**1.34.0→1.37.1 升级评估**（当前 vers.txt 用 1.34.0）：

| 影响点 | 结论 |
|---|---|
| GTK2 构建 | 可行。1.37.1 支持 GTK2（`--enable-gtk2`），`gtk+-2.0>=2.24` 满足；**但默认 GTK3，须显式 `--enable-gtk2`**（1.34.0 是 `--enable-gtk3` 默认 no=GTK2，选项开关反转——唯一必须改的点） |
| configure 选项 | 全兼容。vte/docs/api-docs 在 `m4/geany-vte.m4`、`geany-docutils.m4`、`geany-doxygen.m4`（1.37.1 均有），static/shared 是 libtool 标准——无需删，只加 `--enable-gtk2` |
| 强制依赖 | 不变。gtk_modules/private 相同（`gtk+-2.0>=2.24` + glib>=2.32 + gio-2.0/gmodule-no-export + GTHREAD），无新增强制库；vte 已 disable |
| 编译要求 | C++11（1.34.0 已含 `ax_cxx_compile_stdcxx_11.m4`，非 1.37.1 新增；1.38 才 C++17）——xx-clang++ 满足 |
| 数据文件 | `make install-data` 自动带（1.37.1 新 filedefs/配色），版本无关 |
| 源码 patch | 无本地 patch（v-geany 仅 build.sh，无 sed/patch）——升级无需重打 |
| 静态链接 | 无新依赖库，LIBS0/OB_LIBS 静态组沿用；1.37.1 新符号需实测 xx-clang++ 链接（同组库大概率覆盖） |
| 源地址 | gitee `fk-geany` 有 1.37.1（peeled `26f4813` 与 github 一致）——可改 `--branch=1.37.1` |

**需改点（若升级）**：build.sh 版本 1.34.0→1.37.1、源 branch→1.37.1、configure 加 `--enable-gtk2`、注释更新（「1.34.0 最后几个 GTK2」→「1.37.1 是 GTK2 最后一版，1.38 删」）。

**结论**：可行性成立，核心改动仅加 `--enable-gtk2` + 版本/源更新，无新硬依赖，数据自动带；唯一需实跑确认 xx-clang++ 静态链接（1.37.1 新符号）。

**发布时间点与功能更新（1.34→1.37.1，官方 NEWS）**：

**发布时间点**（git tag commit 日期）：

| 版本 | 发布时间 |
|---|---|
| 1.34.0 | 2018-12-16 |
| 1.34.1 | 2019-01-04 |
| 1.35.0 | 2019-04-28 |
| 1.36.0 | 2019-09-28 |
| 1.37.0 | 2020-10-25 |
| 1.37.1 | 2020-11-08 |

**功能更新**：

- **1.34.0**（2018-12-16，当前所用）：Auto-select GTK2/GTK3（PR#1182）；命令行 tags 按序处理；修复 Scope 高 CPU/Plugin Manager 崩溃/GTK3 滚动；go-to-symbol 路径/图标；Strip Trailing Spaces 快捷键；Scintilla 3.10.0
- **1.34.1**（2019-01-04）：纯 bug 修复（行断行/XML 文件名 infobar/矩形选区修饰键）；翻译 uk
- **1.35.0**（2019-04-28）：**开始同步 Universal-Ctags**（PR#1263/#2018，符号解析大幅改进）；JS/HTML/COBOL/ActionScript 符号解析改进；批量替换大幅提速；IPC socket 修复；变量类型 tooltip；Scintilla 3.10.2
- **1.36.0**（2019-09-28）：用户 filetype 扩展名映射/最长匹配优先；socket 放 `$XDG_RUNTIME_DIR`；About 显示 GTK/GLib 版本；分数字体；Scintilla 3.10.4；**新增 Swift/Nim filetype** + Kotlin/Groovy/TypeScript 自定义
- **1.37.0**（2020-10-25）：**Build with GTK3 by default**（GTK2 仍可选）；配置保存会话；Open/New Project 取消；Scintilla 3.21.1；**新增 BibTeX/Smalltalk filetype**；Python 默认命令可配；Windows 多项（IPC 端口可配/编程连字）
- **1.37.1**（2020-11-08）：仅 Windows 首次启动崩溃修复（Issue#2639/PR#2645）——Linux 无功能变化

**小结**：功能大跨度在 1.35→1.37（Universal-Ctags 同步/Scintilla 更新/新 filetype/分数字体/会话保存）；1.37.0→1.37.1 无功能增量（纯 Windows bugfix），1.37.1 是「最后一个含 GTK2 的发布」。升级影响：新增 filetype→filedefs 数据增加（`make install-data` 自动带）；Scintilla 更新→`libscintilla.la` 重编（build.sh 已 `make -C scintilla`）；符号解析变化在 libtagmanager。

#### 6.2、geany 1.37.1 升级实施与实测（2026-11-23）

按 6.1 评估结论开工，1.34.0→1.37.1 升级全链路完成并实测通过（build.sh 单独 commit `dc673d46`）。

**实施改动**（`compile/src/v-geany/build.sh`）：

| 项 | 改动 |
|---|---|
| 版本 | 1.34.0→1.37.1；源 branch→1.37.1（gitee `fk-geany`） |
| configure | 加 `--enable-gtk2`（1.37.1 默认 GTK3，须显式走 GTK2——1.34.0 是 `--enable-gtk3` 默认 no=GTK2，选项开关反转） |
| 注释 | 「1.34.0 最后几个 GTK2」→「1.37.1 = 最后一个支持 GTK2 的发布（1.38 起删）」 |
| bug 修复 | 离线 tarball 分支 `tar ... -C /tmp --strip-components=1` 解包**错位**到 `/tmp/` 根（1.34.0 靠 host 手动解包 `/tmp/geany` 绕过，tarball 分支本身错位）→ 改 `-C /tmp/geany` |

**实测（builder-g224 + hdmi Xvnc）**：

| 环节 | 结果 |
|---|---|
| 构建 | `TARGETPATH=/usr/local/static/geany sh /src/v-geany/build.sh geany`，118s，err 0 pass（首跑因 tar 错位失败，修复后 118s 成功） |
| 静态验证 | `xx-verify --static` rc=0；`file`=`statically linked, stripped`；`strings`=Geany 1.37.1；GTK2 符号（gtk+-2.0）；产物 16,141,720B |
| 数据 | filedefs/colorschemes/geany.glade/gtkrc/filetype_extensions.conf/snippets.conf/tags/templates/ui_toolbar.xml 全齐 |
| GUI 实跑 | hdmi Xvnc `:321`，headless 用户：主窗口「geany」弹出（3 窗口），进程稳定不崩，日志无错 |
| 提交 | build.sh `dc673d46`（未 push，工作区干净） |

**踩坑（实跑才见）**：

- **tar 解包错位（原 bug）**：build.sh 离线 tarball 分支 `tar -C /tmp --strip-components=1` 把源码解到 `/tmp/` 根（`/tmp/configure.ac`/`/tmp/src`），`/tmp/geany` 空 → `cd /tmp/geany` 空树 → `make -C ctags` 失败「ctags: No such file or directory」。1.34.0 构建成功是 host 已手动解包 `/tmp/geany` 绕过；改 `-C /tmp/geany` 根治。
- **configure 干扰行**：日志有 `gtk+-3.0 not met`（非致命探测）——实际产物走 GTK2 成功（xx-verify+strings 实测为准），`--enable-gtk2` 保留。

**对比**：1.37.1 为 GTK2 最后一版，升级后功能增量（Universal-Ctags 同步/新 filetype/Scientilla 3.21.1/分数字体/会话保存），无回归（主窗口+不崩+数据齐全）。

### 7、engrampa 最新支持 GTK2 版本评估（2026-11-23）

#### 7.1、最新支持 GTK2 版本评估--1.14.1已最新（2026-11-23）

**结论**：engrampa 最新支持 GTK2 的版本 = **1.14.1**（项目当前版本，**无更高可升**）。

**实测**（gitee g-system/fk-engrampa clone 查 configure.ac）：

| 版本 | GTK 依赖 | GTK 世代 |
|---|---|---|
| 1.14.1（项目当前） | `--with-gtk=2.0\|3.0`，**默认 2.0**（configure.ac:36-43） | **GTK2（默认）+ 可选 GTK3** |
| 1.15.0 / 1.15.1 | `PKG_CHECK_MODULES(GTK, [gtk+-3.0])` | **只 GTK3** |
| 1.16.0 起 | `gtk+-3.0` | GTK3 |

**要点**：

- 1.14.1 是最后支持 GTK2 的版本：configure.ac 保留 `--with-gtk=2.0|3.0` 双选（默认 2.0）；**1.15.0 起强制 GTK3**（`gtk+-3.0`，无 --with-gtk 选项）。
- 项目当前 `1.14.1` 已是**最后/最高支持 GTK2 的版本**（build.sh 注释「GTK2 最后一版 1.14.1」经源码独立确认），**无需升级**。
- 后续版本（1.15.0+ / v1.28.5）全 GTK3，项目用不上。

### 8、XFCE 组件 最新支持 GTK2 版本评估（2026-11-23）

#### 8.1、thunar/ristretto/xfce4-settings 最新支持 GTK2 版本评估（2026-11-23）

**结论**：三个 XFCE 组件最后支持 GTK2 的版本如下（实证自各版本源码 `configure.ac.in` 的 `XDT_CHECK_PACKAGE([GTK], [gtk+-2.0])`）：

| 组件 | **最后 GTK2 版本** | tag 日期 | 下一版（dev） | 下一版 GTK | GTK2 依赖要求 |
|------|:---:|:---:|:---:|:---:|:---:|
| **thunar** | **1.6.18** | 2019-11-09 | 1.7.0 | gtk+-3.0 (≥3.20) | gtk+-2.0 ≥ 2.24.0 |
| **ristretto** | **0.8.5** | 2019-07-17 | 0.10.0 | gtk+-3.0 (≥3.22) | gtk+-2.0 ≥ 2.20.0 |
| **xfce4-settings** | **4.12.4** | 2018-06-20 | 4.13.0 | gtk+-3.0 (≥3.20) | gtk+-2.0 ≥ 2.20.0 |

**实测方法**：

- 源用 github `xfce-mirror/{thunar,ristretto,xfce4-settings}` tag（需按各自前缀过滤，避免 `archive/*` tag 污染）；`git ls-remote --tags` 枚举全部版本。
- 每个版本抓 `configure.ac.in` 看 `XDT_CHECK_PACKAGE([GTK], [gtk+-2.0\|gtk+-3.0])`（注意：XFCE 源码树用 **`configure.ac.in`**，`configure.ac` 是 autogen 生成物、raw 抓取 404）。
- tag 日期用浅克隆 `git clone --depth 1 --branch <tag>` + `git log -1 --format=%cs`。

**要点**：

- **thunar**：1.6.x 为 GTK2 系列，**1.6.18 是末版**（`gtk+-2.0 ≥ 2.24`）；**1.7.0 起全部 gtk+-3.0**（含 1.7.x/1.8.x）。
- **ristretto**：**0.8.5 是 GTK2 末版**（`gtk+-2.0 ≥ 2.20`）；之后**直接跳 0.10.0**（无 0.9.x 稳定版），0.10.0 起 GTK3（≥3.22）。
- **xfce4-settings**：**4.12.4 是 GTK2 末版**（`gtk+-2.0 ≥ 2.20`）；**4.13.x（dev 系列）已是 GTK3**（≥3.20），非 GTK2 过渡。**4.12.x 小版本枚举 4.12.0–4.12.4 无更高**，4.12.4 已确认最高。
- 三个迁移点都在 XFCE 4.13/4.14 开发周期内，与 **XFCE 4.14（2019-08，GTK3 迁移大版本）**时间线吻合。

#### 8.2、thunar 1.6.3→1.6.18 升级实现与验证（2026-11-23）

**结论**：thunar 从 1.6.3（2013-05-05）升到 **1.6.18**（2019-11-09，GTK2 最后版），**构建成功**（静态链 14.98MB + xx-verify pass），已部署 hdmi，GUI 启动实测通过（Xfconf/thumbnailer 正常）。

**升级改动**（`compile/src/v-xfce4/build.sh` thunar()）：

- **版本**：`local VER=1.6.3` → `1.6.18`；log `"thunar 1.6.3 static verified"` → `"thunar 1.6.18 static verified"`。
- **移除 2 个已失效 configure 选项**：`--disable-startup-notification --disable-gtk-doc`——**1.6.18 已移除这两个特性**（`configure.ac`/`configure` 无 `AC_ARG_ENABLE`/选项引用，源码无 startup-notification 引用；仅剩 `--disable-exif/notifications/gudev/tpa-plugin/wallpaper-plugin/apr-plugin/sbr-plugin` 7 个仍支持）。未知 `--disable-*` 会被 autoconf 静默忽略，但为干净移除。
- **patch 兼容**：`thunar-static-dbus.patch` / `thunar-static-uca.patch` 在 1.6.18 **干净应用**（`git apply --check` rc=0）——2013 context 仍匹配 2019 源码，无需 fuzz/更新。UCA 入口点（`thunar_extension_initialize/list_types/shutdown`）在 1.6.18 `plugins/thunar-uca/thunar-uca-plugin.c` 仍存在。

**构建验证**（builder-g224）：

- **前置 `b_deps`**：容器是新起（`/usr/local/static` 无 xfce/ 目录）→ 必须先 `b_deps` 构建 xfce 库栈（libxfce4util-4.12.1 / xfconf-4.12.1 / libxfce4ui-4.12.1 / **exo-0.10.6** / garcon-0.4.0）+ libexif；否则 configure 报 `checking for exo-1 >= 0.10.0... not found`。
- **产物**：`/usr/local/static/thunar/bin/thunar` 14,982,248 字节；`file` = `statically linked, stripped`；`ldd` = `Not a valid dynamic program`；`strings` 含 `1.6.18`；undefined refs = 0；`xx-verify --static` pass。
- **make thunar CCLD failed 是预期**（动态链失败，静态链才是目标；`thunar` 对象已编译，build.sh 注释）。
- **locale**：61 语言 `.mo` 安装（po/ 手装，Thunar.mo + thunar.mo 双输出）。

**GUI 实测**（hdmi `/usr/local/static/thunar/`，Xvnc + headless）：

- **必须 dbus 会话**：无 `DBUS_SESSION_BUS_ADDRESS` 报 `Failed to initialize Xfconf: Using X11 for dbus-daemon autolaunch was disabled at compile time, set your DBUS_SESSION_BUS_ADDRESS instead`——thunar 是文件管理器，Xfconf 依赖 session bus，需 `dbus-run-session -- thunar` 包裹。
- dbus-run-session 下启动成功：Xfconf 激活（`Successfully activated service 'org.xfce.Xfconf'`）、thumbnailer 注册（`gdk-pixbuf-thumbnailer`）、**持续运行 10s 无崩溃**（RC=137 = `timeout -s KILL` 预期）。

**关键坑**（`ensure_gtk_libs` 记录缺失）：

- `ensure_gtk_libs` 判据 = `sha256sum /src/u-gtk/*.patch` 组合 vs `/usr/local/static/.gtk-state/gtk.sha`。**新容器首次跑 gtk 应用 b_deps 会误判 NOT latest**（gtk.sha 记录缺失）→ 触发 u-gtk 完整重编（重）。tint2（imlib2 应用）不触发 ensure_gtk_libs，故旧容器从未写 gtk.sha。
- 若 `.a` 实际最新（patch 最新 mtime < `.a` mtime），可手动补记录跳过重编：`mkdir -p /usr/local/static/.gtk-state; sha256sum /src/u-gtk/*.patch | sha256sum | cut -d" " -f1 > /usr/local/static/.gtk-state/gtk.sha`。

### 9、tint2/rofi/scrot 评估 + rofi 2.1.1 升级实现与验证（2026-11-23）

#### 9.1、tint2/rofi/scrot 最新版评估（2026-11-23）

**tint2 最新支持 GTK2 的版本 = v16.7**（2019-07-14）。

**关键认知**：tint2 **主程序本身不依赖 GTK**（用 cairo/pango/imlib2/X11），仓库带一个 **tint2conf**（主题配置器）子组件是唯一 GTK 依赖点：

| tint2 版本 | tint2conf GTK | 日期 | 说明 |
|---|---|---|---|
| ≤ **v16.7** | **GTK2**（`gtk+-x11-2.0`） | 2019-07-14 止 | **最后支持 GTK2** |
| v17.0 | **GTK3**（`gtk+-x11-3.0`） | 2021-04-18 | "Port tint2conf to gtk3"（issue #380） |
| v17.0.2（官方最终版，冻结） | GTK3 | 2021-12-04 | 官方停更冻结 |

**实证**：v16.7 `src/tint2conf/CMakeLists.txt` `pkg_check_modules(GTK2 REQUIRED gtk+-x11-2.0)`；v17.0/v17.0.2 同为 `GTK3 ... gtk+-x11-3.0`。README 备注「17.0.2；冻结（官方最终版）；gitlab.com/o9000/tint2」与实证一致——**github o9000/tint2 是过时镜像（只到 v16.2），活的在 gitlab.com/o9000/tint2**。

**tint2 v16.7 → 17.0.2 新功能**（ChangeLog）：

- v17.0（2021-04-18）：tint2conf 移 GTK3；`execp_monitor` 配置；修复窗口大图标崩溃/分钟时钟不更新/tint2conf 滚动条/图像内存泄漏/高 CPU（#786/#796/#799/#704/#800）。
- v17.0.1（2021-05-29）：单显示器 execp 面板清理崩溃（#801）。
- v17.0.2（2021-12-04）：双显示器最小化 Chrome 窗口落错面板（#818）。
- v16.3–16.7 另含：executor 布局修复、电池低电量闪烁、按应用名排序任务栏、图像加载泄漏修复等。

**rofi 最新版 = 2.1.1**（项目当前 2.0.0）。

- **2.0.0（2025-09-01）重大版**：合并 **Wayland 后端**（官方支持）；**弃 autotools、只留 meson**；新增 `rofi -info` 调试命令。
- **2.1.1（bugfix 版）**：nkutils 更新、DMenu 行显示修复（#2352）、CI 用 distro check、`gio-launch` 改编译期选项。
- **依赖不变**：glib-2.0 ≥ **2.72**（2.1.1 与 2.0.0 相同）、gmodule/gio-unix/cairo/pango/pangocairo/xkbcommon/gdk-pixbuf-2.0/xcb 系列。
- **项目适用性**：项目已在 2.0.0（meson + xcb 后端），构建脚本有降级 hack（容器 Alpine 3.15 glib 2.70.5 < 2.72，sed 降 `glib_min_minor` 至 70）。**2.1.1 依赖不变 → 适用**。

**scrot 最新版 = 2.0.0**（项目当前 1.12.1）。

- **2.0.0（2026-03-13）功能变化**：
  - 移除：`--note` 和 `--script` 选项（**破坏性变更**）。
  - 改用 **Xrandr 替代 Xinerama** 做 monitor capture（依赖集改变）。
  - 默认线宽由显示 DPI 派生；修复 `--freeze`/`--line mode=edge` 合成器下毛刺/选区边框入图/截图后响铃。
- **依赖变化**（deps.pc）：`x11 imlib2>=1.11.0 xcomposite>=0.2.0 xfixes>=5.0.1 xrandr>=1.5`（去掉 xext/xinerama，**imlib2 升到 >=1.11.0**）。
- **项目适用性**：⚠️ **imlib2 冲突**——项目自建 imlib2 是 **1.7.4**（2021-09-17），scrot 2.0.0 要求 **>=1.11.0**。需升级 imlib2 到 1.11.0+（w-xlunch/w-feh/w-tint2 共用的自建 imlib2）才能用 2.0.0；否则**不可用**。

#### 9.2、rofi 2.1.1 升级实现与验证总结（2026-11-23）

**结论**：rofi 2.0.0 → **2.1.1** 升级 + 打开 **xim（imdkit）** 支持，**构建成功**（静态链 + xx-verify pass + imdkit 编入），已部署 hdmi。

**升级改动**（`compile/src/x-rofi/build.sh`）：

- **版本**：`ROFI_VER=2.0.0` → `2.1.1`；注释更新。
- **libnkutils 子模块**：`2f220a4` → **`d436ee7`**（2.1.1 更新，含 asan 修复；libgwater 提交 `d86f990` 不变）。
- **开 imdkit（xim）**：meson `-Dimdkit=false` → **`-Dimdkit=true`**（需自建 xcb-imdkit 库）。
- **b_deps 补建 xcb-imdkit**（新增 `build_xcb_imdkit()`）：
  - 源 `fcitx/xcb-imdkit 1.0.9`（Alpine 3.15 无包，自建静态 .a + `xcb-imdkit.pc`）。
  - 需 **ECM**（`extra-cmake-modules`，`apk add`）；内置 uthash（`USE_SYSTEM_UTHASH=Off`，Alpine uthash 包是空包）。
  - **坑**：源码 `add_library(xcb-imdkit SHARED ...)` 硬编码 SHARED，`BUILD_SHARED_LIBS=OFF` 无效 → **sed 改 STATIC**；必须先 `rm -rf build` 清 CMakeCache。
  - **坑**：`make`/`make install` 默认触发 **test 目标**链接失败（缺 xcb 传递静态库 linker error）→ 只建主库 `make xcb-imdkit` + **手动拷贝**产物（.a/.pc/头文件到 /usr/local）。
  - **坑**：.a/.pc 在 `build/src/`（当前 build 目录下 `src/`），源码头在 `../src/`。

**实测**（builder-g224，44 秒）：

- `file`：`statically linked, stripped` ✓
- `xx-verify --static`：pass ✓
- `ldd`：`Not a valid dynamic program` ✓
- **imdkit 编入**：`strings` 见 `imdkit %senabled%s` / `XIM_SERVERS` / `_XIM_PROTOCOL` 等符号 ✓
- `rofi -version`：`Version: 2.1.1` ✓
- 部署：hdmi `/usr/local/static/rofi`（bin + share/themes）已装，`-version` 2.1.1 ✓

**GUI 实跑（Xvnc 314-320，hdmi）**：

- rofi `-show run` 能**拉起进程持续运行**（GUI 启动不崩）✓。
- **发现**：Xvnc 无 WM/无 XIM server 环境下 rofi `-dump`/`-show run` 会**挂起**（`No valid backend` 仅无 DISPLAY 时快速退出）——**非二进制缺陷**，是 Xvnc 裸环境（无合成器/输入法）限制；有输入法/正常桌面会话下不受影响（imdkit 连接 XIM server 后正常）。
- 注：`-imdkit false` 显式关仍挂，确认挂起与 imdkit 无关，是 Xvnc 裸环境 rofi 初始化阻塞。

**要点**：

- rofi xim 支持 = **imdkit**（xcb-imdkit，XIM），机制 2.0.0/2.1.1 相同（2.1.1 未新增 xim 能力）；构建 `-Dimdkit=true` 只**编入**能力，运行时 `imdkit` 配置默认关（`enable_imdkit` gboolean=FALSE），需运行时 `-imdkit true` 或 config `imdkit: true` 启用。
- 依赖不变（glib>=2.72 等），容器 glib 2.70.5 降级 hack 沿用（`glib_min_minor=70`）。
- 自建 xcb-imdkit 静态库是**新增唯一外部依赖**，装 `/usr/local/lib`，供 rofi 链入。

#### 9.3、imlib2 升级评估（scrot 2.0.0 要求 + w-xxx 影响面）（2026-11-23）

**版本 + 发布时间**（sourceforge 实证）：

| 版本 | 日期 | 说明 |
|---|---|---|
| **1.7.4**（项目当前） | **2021-09-17** | 项目自建，内嵌 png/jpeg/svg loader |
| 1.7.5 | 2021-12-06 | 修复（ICO/XBM/PNM/XPM loader mmap、WEBP 动画） |
| 1.8.0 | 2022-02-07 | **大版本**：SVG loader 并入官方、HEIF/JXL 新增、多帧动画、`imlib_version()` API |
| 1.8.1 | 2022-03-15 | PNM/XPM/JPEG progressive 修复 |
| 1.9.0 / 1.9.1 | 2022-04-23 / 07-07 | loader 修复 |
| 1.10.0 | 2022-12-19 | TGA 修复、JPEG-XL/HEIF 支持落地 |
| **1.11.0**（scrot 2.0.0 要求） | **2023-03-10** | 含 1.8–1.10 全部功能 |
| 1.12.0 | 2023-08-17 | QOI/RAW loader、`imlib_image_decache_file()`、Y4M 去 liby4m |
| 1.12.7 | 2026-08-28 | 最新稳定 |
| **1.13.0**（最新） | **2026-11-14** | 最新版 |

**scrot 2.0.0 要求 imlib2 ≥1.11.0（2023-03-10），项目当前 1.7.4（2021-09-17）**——差 1 年半、中间隔 1.8/1.9/1.10 三个功能版本。

**1.7.4 → 1.11.0 新功能特性变化**：

- **SVG loader 官方化**：1.8.0 起 `loader_svg.c` 成为官方内置（`EC_LOADER_CHECK(SVG, auto, librsvg-2.0 ≥ 2.46)`）——项目此前需外部拷 `loader_svg.c`（w-xlunch `cp -f "$SCRIPT_DIR/loader_svg.c"`），1.11.0 不再需要。
- **HEIF/JXL loader**：`EC_LOADER_CHECK(HEIF, auto, libheif)`、`EC_LOADER_CHECK(JXL, auto, libjxl libjxl_threads)`——新增依赖，静态构建需禁用或提供库。
- **多帧/动画图像支持**（1.8.0）：GIF/WEBP/ICO/PNG multiframe。
- **新 API**：`imlib_version()`（1.8.0）、`imlib_image_decache_file()`（1.12.0）。
- **其他**：LZMA loader、PNG loader 重写（callback API）、Y4M 自定义 parser（1.12.0 去 liby4m）、缩放改进、`imlib_load_image_fd` munmap 修复。
- **公开 API 向后兼容**：Imlib2.h 只新增不删（1.11.0 有 `imlib_version()`，无符号移除）——w-xxx 老 API 调用不受影响。

**升级 imlib2 到 1.11.0+ 对 w-xxx 应用影响**（受影响：w-feh、w-scrot、w-tint2、w-xlunch、w-hsetroot，全链自建 `/usr/local/lib/libImlib2.a`）：

| 应用 | 影响 | 需改动 |
|---|---|---|
| **w-feh** | 低（API 兼容） | 仅重建 imlib2 后重链（应用 build.sh 不变） |
| **w-scrot** | 低（API 兼容） | 仅重建 imlib2 + 重链 |
| **w-tint2** | 低（API 兼容） | 仅重建 imlib2 + 重链（CMake 检测 imlib2） |
| **w-xlunch** | **高**（imlib2 自建脚本本体） | ① 版本 1.7.4→1.11.0+；② **重打 loaders.c patch**（1.11.0 loaders.c 结构变：`loaders_known[]` + `BUILD_*_LOADER` 宏，patch 锚点从 `if (loaders) return` 变 `__imlib_LoadAllLoaders` 附近）；③ **SVG loader 不再外部拷**（官方内置，删 `cp loader_svg.c`）；④ 新增 loader（heif/jxl）需 `--disable-heif --disable-jxl` 或提供库 |
| **w-hsetroot** | 低（API 兼容） | 仅重建 imlib2 + 重链 |

**核心风险**：

1. **loaders.c patch 重打**——1.11.0 的 `src/lib/loaders.c` 用 `loaders_known[]` 静态表（`BUILD_JPEG/PNG/SVG_LOADER` 宏）替代 1.7.4 的注册方式，项目 patch 的「builtin static loaders（no dlopen）」插入锚点需适配新结构。**这是最大工作量**。
2. **新增 loader 依赖**——heif/jxl 若 configure 启用会链 libheif/libjxl（项目无静态库）→ 必须 `--disable-heif --disable-jxl`（或用 `--without-*`）。svg 现在官方（librsvg 已自建，OK）。
3. **API 兼容性**——imlib2 公开 API 向后兼容，w-xxx 应用源码无需改；但**必须重链**（新 libImlib2.a 替换旧的）。

**与 10.1 的关联**：hsetroot 1.1.0 硬要求 imlib2 **≥ 1.12.6**（`imlib_save_image_with_errno_return`/`imlib_strerror`，1.7.4 无此符号）——若走升级 imlib2，需 **≥1.12.6**（非仅 1.11.0），连带重编共享 imlib2 的 w-feh/w-xlunch/w-tint2/scrot。

**结论**：升级 imlib2 到 1.11.0+ 技术上可行（API 兼容，w-xxx 应用源码不用动），**主要工作在 w-xlunch 的 imlib2() 自建脚本**（版本 + loaders.c patch 重打 + SVG 官方化 + 禁 heif/jxl）。scrot 暂定 1.12.1 则无升级必要；hsetroot 1.1.0 若启用则需 ≥1.12.6 且四组件重编。

#### 9.4、tint2 16.2→16.7 升级评估（2026-11-23）

##### 9.4.1、tint2 定制分支 v16.2-custom 改动与 16.7 适配性（2026-11-23）

**版本确认**：项目当前 tint2 基于 gitee 镜像 `g-system/fk-tint2` 的**默认分支 `v16.2-custom`**（上游 `o9000/tint2` 的 `Release 16.2`（b810bad）之上 ~7 条定制提交）。`vers.txt` 记 `16.1`、`w-tint2/build.sh` L250 `--branch=16.1` 均为**旧记录**——实际构建走 v16.2-custom（CI 无 tarsrc-git 时网络 clone 取 fork 默认分支；本地 `tarsrc-git/fk-tint2` 缓存当前停在 clean 16.1 tag）。

**v16.2-custom 定制提交**（`v16.2` → `v16.2-custom` 差异）：

| 提交 | 文件 | 改动 |
|---|---|---|
| b62d94e | `src/battery/battery.c` | `strnappend`→`strnappend02`（防符号冲突，全 10 处） |
| 4c53e13 | `CMakeLists.txt` | `ENABLE_BATTERY/TINT2CONF/EXTRA_THEMES/RSVG/SN/UEVENT` 全 ON→OFF（**不建 tint2conf**） |
| 84bda25 | `CMakeLists.txt` | notes：imlib2-check / 2a.x3 说明 |
| ebacf2b | `CMakeLists.txt` | `LINK_FLAGS "-static -pthread ..."` |
| e41566f | `CMakeLists.txt` | `target_link_libraries( tint2 ...)` 注入静态 `$deps` |
| 5ef1db2 / e78c038 | `build-*-out*.tar.gz` | **误提交构建产物**（非源码，升级可忽略/清理） |

定制改动本质 = **静态构建适配**（.a 强制 + 静态 deps 注入 + LINK_FLAGS -static + 注释 Imlib FATAL_ERROR + strnappend02 符号改名）+ **关闭非必要组件**（battery/tint2conf/rsvg/sn/extra-themes/uevent）。`w-tint2/build.sh` 的**构建期 sed 补丁**（L261 FATAL_ERROR 注释、L303/L307 deps 注入、L316 strnappend、L335-336 link.txt 去 -rdynamic+dynamic→static、L322-324 ldd.txt .so 黑名单）**镜像了上述 fork 定制**——故 fork 用干净 16.7 tag + build.sh sed 与重放 fork 定制，效果等价。

**16.2 → 16.7 新功能与修复**（上游 ChangeLog 汇总）：

- **新功能**：初步高 DPI 支持（16.2）；新 build script（16.5）；taskbar 按应用名排序（16.5）；电池低电量闪烁（16.7 #723）；电池百分比不带 % 号（16.7 #730）；icon 路径展开前导 `~`（16.7）。
- **修复**：#688 正解（16.2）、word wrapping #693（16.2）、executor 布局 #695（16.3）、图片加载泄漏 #704（16.4）、executor 不再默认打日志（16.4）、图片加载回归（16.5）、task icon 亮度回归 #714（16.6）、debian 打包回归 #715（16.6.1）、垂直面板 icon 间距 #716（16.7）、时钟 `%s` 每分钟才更新 #724（16.7）、阴影字体 markup #709（16.7）、多屏 struts pivoting（16.7）。

**16.7 是最后一个 GTK2 版本**：`17.0`（2021-04-18）把 **tint2conf 迁移到 GTK3**（issue #380；Debian「tint2conf now uses GTK3 instead of GTK2」、FreeBSD「tint2conf was ported to GTK 3.0」确认）。主 `tint2` panel 原生 link 线**不含 GTK**（只 X11+pango/cairo/imlib2+UNWIND/EXECINFO），仅 `tint2conf` 用 `gtk+-x11-2.0`。**项目栈是 GTK2（u-gtk）→ 16.7 是天花板**。

**定制改动 16.7 re-sync 可行性——干净**（16.7 与 16.2 结构完全一致）：

| 定制目标 | 16.7 位置 | 状态 |
|---|---|---|
| `option( ENABLE_BATTERY/TINT2CONF/EXTRA_THEMES/RSVG/SN/UEVENT ... )` | CMakeLists L4-14 | ✅ 同名同结构 |
| `message( FATAL_ERROR "Imlib is not built with X support" )` | CMakeLists L94 | ✅ 同 |
| `target_link_libraries( tint2 ${X11_LIBRARIES}` | CMakeLists L264 | ✅（16.2 为 L263，+1） |
| `set_target_properties( tint2 PROPERTIES LINK_FLAGS "-pthread ..." )` | CMakeLists L287 | ✅ 同 |
| `src/tint2conf/CMakeLists.txt` `pkg_check_modules( GTK2 REQUIRED gtk+-x11-2.0 )` | L10 | ✅ 仍是 GTK2 |
| `strnappend` in `src/battery/battery.c` | 11 处（16.2 为 10 处） | ✅ 全局替换可处理 |

行号仅 ±1，sed/选项名/锚点均不受影响 → **定制改动可原样重放到 16.7**；build.sh sed 补丁 16.7 上亦全部适用。

**升级动作**（若定 16.7）：

1. `w-tint2/build.sh` L250：`--branch=16.1` → `--branch=16.7`（或 `v16.7`）。
2. fork 若要保留定制：把 CMakeLists/battery.c 改动重放到 v16.7（或只靠 build.sh sed）。
3. **⚠️ 删/更新 `compile/tarsrc-git/fk-tint2` 缓存**（当前 16.1 clean；gitclone 缓存命中会**不 checkout tag 直接返回旧 16.1**——imlib2 同类坑，不删会拿到假 16.7）。

**待拍板 nuance**：v16.2-custom 把 `ENABLE_TINT2CONF` 设 OFF（不建 tint2conf），而 `build.sh` L352 却 `xx-verify` tint2conf 二进制（暗示正常构建**会建 tint2conf**）。**保留 tint2conf → 16.7 是天花板；砍掉 tint2conf（主 tint2 不依赖 GTK）→ 可考虑 17.x**。

### 10、feh/hsetroot/xlunch 最新版本评估（2026-11-23）

#### 10.1、feh/hsetroot/xlunch 最新版本评估与缓存核实（2026-11-23）

**结论**：

| 组件 | 项目构建版本 | **最新版本**（tag） | 最新 tag 日期 | 兼容性（imlib2 1.7.4） |
|------|:---:|:---:|:---:|:---:|
| **feh** | fk-feh(master)（缓存 2024-06-30 无 tag） | **3.13.1** | 2026-09-16 | ✅ **兼容**（条件编译适配新旧 API） |
| **hsetroot** | fk-hsetroot(master)（缓存 2022-01-01 无 tag） | **1.1.0** | 2026-11-18 | ❌ **不兼容**（硬要求 imlib2 ≥ 1.12.6 + 新 API） |
| **xlunch** | fk-xlunch(master)（缓存 v4.7.5） | **v5.10.6** | 2026-11-09 | ✅ **兼容**（无版本检查，未用新 API） |

**数据来源澄清（重要）**：

- 本评估的"最新版本"判断**来自 `/tmp/chk-feh`、`/tmp/chk-hsr`、`/tmp/chk-xlunch`** 三个克隆
  （**2026-11-23 14:29 同步**，remote = gitee g-system/fk-*，`git describe --tags` / `git log -1` 实证），
  **不是** `2026/README.md` 表（README 表已修正：xlunch 官方最新列 `v4.7.5`→`v5.10.6`，commit `1b8b13fd`）。
- **撤回到期说法**：此前评估曾称"tarsrc 缓存（11-15）已含最新、当前构建即最新"——**不成立**。
  tarsrc 缓存是 **11-15 16:16** 旧快照，**不可能包含** 11-23 才同步的新代码/新 tag。实测缓存包内：
  - `w-feh.fk-feh-default.tar.gz`：master = `70a7b06`（**2024-06-30**），**无任何 tag**；
  - `w-hsetroot.fk-hsetroot-default.tar.gz`：master = `a402d53`（**2022-01-01**），**无任何 tag**；
  - `w-xlunch.fk-xlunch-default.tar.gz`：master = `80bbe8a`（**2023-08-05**），tag = **v4.7.5**。
  三组件当前构建均**落后**最新版，需按需升级（feh/xlunch 可直接升；hsetroot 视 imlib2 走向）。

**imlib2 兼容性实证**：

- **feh 3.13.1**：源码 `src/imlib.c:258`、`src/options.c:779` 用
  `#if defined(IMLIB2_VERSION_MAJOR) && defined(IMLIB2_VERSION_MINOR) && (IMLIB2_VERSION_MAJOR > 1 || IMLIB2_VERSION_MINOR > 7)`
  条件编译适配新旧 imlib2 API（1.7.4 走旧分支）——**无硬版本检查，兼容 1.7.4**。
- **hsetroot 1.1.0**：`Makefile` `IMLIB2_MIN?=1.12.6` **硬要求 imlib2 ≥ 1.12.6**
  （`pkg-config --atleast-version` 检查，不满足即 `$(error ...)`）；且源码
  `hsetroot.c:747-749` 用 **`imlib_save_image_with_errno_return`** + **`imlib_strerror`**——
  1.7.4 均**无此符号**（`IMLIB2_MIN=0` 绕过版本检查后仍真链接失败：`undefined reference`）。
  需升级 imlib2 到 ≥ 1.12.6（连带 w-feh/w-xlunch/w-tint2/scrot 重编）才可用 1.1.0。
- **xlunch v5.10.6**：`Makefile` 直接 `LDFLAGS = -lImlib2 -lX11 -lm -ldl`（**无版本检查**）；
  源码未用 `imlib_strerror`/`imlib_save_image_with_errno_return`（全量 grep 无）——**兼容 1.7.4**。

**要点**：

- feh 3.13.1、xlunch v5.10.6 可直接升级（imlib2 1.7.4 兼容，构建脚本无需改依赖）。
- hsetroot 1.1.0 **项目环境不可用**（imlib2 1.7.4 太旧）——保持 1.0.5，或走升级 imlib2
  （≥1.12.6，连带重编共享 imlib2 的四组件，成本高）；**待用户拍板**。

#### 10.2、imlib2 1.12.7 升级 + xlunch/feh/hsetroot 升级 + scrot 重编译验证（2026-11-23）

**用户指令**：imlib2 升 12.x 最新 **1.12.7**（2026-08-28）；xlunch/hsetroot/feh 升级 + 编译验证；scrot 版本不变仅重编（新 imlib2）；tint2 不动不验证。

##### 10.2.1、处理过程：

- **imlib2 1.7.4 → 1.12.7**（w-xlunch/build.sh imlib2()）：
  - configure 加 `--without-heif --without-jxl`（1.8.0 新增 HEIF/JXL loader，项目无静态库必禁）。
  - **SVG configure auto 被禁**（librsvg 2.40.21 < 2.46，官方 loader_svg.c 硬依赖 ≥2.46）——预期行为，靠 builtin 注入兜底（实测 GUI svg 显示通过）。
  - **loaders.c patch 锚点**：1.7.4 `if (loaders) return;` → 1.12.7 `list = __imlib_ModulesList(...)` 之后、early return 之前（`__imlib_LoadAllLoaders` 内）——1.12.7 用 `loaders_known[]` + 模块 dlopen，无 1.7.4 的注册 guard。
  - **loader 导出符号**：1.7.4 独立 `png_load2/svg_load2/jpeg_load2` → 1.12.7 每个 loader 尾部 `IMLIB_LOADER_*` 宏导出**全局 `ImlibLoaderModule loader`**，三 loader 同链符号冲突 → 编译加 `-Dloader=png_loader`（svg/jpeg 同理）重命名。
  - **builtin 注入结构**：1.7.4 手动设 `load2/save/formats` → 1.12.7 设 `module` 指针（`ImlibLoader{file,handle,module,next,name}`），loader 源尾部 `IMLIB_LOADER_KEEP(_formats,_load,NULL)`（svg） / `IMLIB_LOADER(_formats,_load,_save)`（png/jpeg）。
  - **loader_svg.c 改写**（保留项目 2.40 兼容）：官方 1.12.7 全用 `#if LIBRSVG_CHECK_VERSION(2,46,0)`（`rsvg_handle_get_intrinsic_dimensions/render_document`），librsvg 2.40.21 下 `_load` 尺寸判定失败（SVG 失效）——改写为 2.40 API（`rsvg_handle_get_dimensions` + `rsvg_handle_render_cairo`）+ 1.12.7 module 接口，数据源 `im->fp/fseek` 改 `im->fi->fdata/fsize`。
  - **补编 ldrs_util.c/exif.c**：首次链 xlunch 报 `get_saver_params`/`exif_parse` undefined——两符号定义在 **loader 模块辅助源**（`modules/loaders/ldrs_util.c`、`exif.c`），**非主库 libImlib2.a**；编入 builtin 后修复。
- **xlunch v4.7.5 → v5.10.6**：`gitclone --branch=$XLUNCH_VER`（XLUNCH_VER=v5.10.6）。
- **feh → 3.13.1**：`--branch=$FEH_VER`（3.13.1）。
  - **tarsrc-git 缓存坑**：gitclone 优先 GITCACHE（tarsrc-git 含 .git）且**不 checkout tag** → 首次构建用旧 master（70a7b06）非 3.13.1；删 `tarsrc-git/fk-feh` 强制网络 clone tag。
  - **-lXi 缺**：链接报 `cannot find -lXi`（XInput 静态库）→ `sh /src/w-tint2/build.sh libxi` 自建（/usr/local/lib/libXi.a）；feh 链接命令无 -lXt（libXt 仅编译头）。
  - **补 -Wl,--strip-all**：make LDFLAGS 覆盖丢 common.sh 的 strip-all（AGENTS.md 坑）→ 38M not stripped；追加后 10.2M stripped。
- **hsetroot 1.0.5 → 1.1.0**：`--branch=$HSR_VER`（1.1.0）；删旧 `/tmp/hsetroot`（1.0.5 残留 "source already present"）+ tarsrc-git 缓存；Makefile `IMLIB2_MIN?=1.12.6` 硬检查满足（1.12.7 ≥1.12.6）。
- **scrot 1.12.1**：版本不变，仅重链新 imlib2；补装 `autoconf-archive`（autogen 需 AX_ 宏）。
- **tint2**：未动。

##### 10.2.2、编译验证结果（builder-g224，2026-11-23）：

| 组件 | 版本 | file | xx-verify | undefined reference |
|------|:---:|:---:|:---:|:---:|
| imlib2 (libImlib2.a) | **1.12.7** | 静态库 | — | 0（nm 含 png_loader/svg_loader/jpeg_loader/get_saver_params/exif_parse 定义） |
| xlunch | **v5.10.6** | statically linked, stripped | pass | 0 |
| feh | **3.13.1** | statically linked, stripped (10.2M) | pass | 0 |
| hsetroot | **1.1.0** | statically linked, stripped | pass | 0 |
| scrot | 1.12.1（不变） | statically linked, stripped | pass | 0 |

##### 10.2.3、GUI 验证结果（hdmi 容器 Xvnc :311，2026-11-23）：

- **feh 显示 SVG + PNG**：进程存活 3s（`svg_loader`/`png_loader` builtin 工作）——**SVG configure 被禁但注入兜底生效，关键验证通过**。
- **scrot 截图**：rc=0，生成 shot.png 3072B（png save 工作）。
- **hsetroot 壁纸**：rc=0（png load + 设壁纸）。
- **xlunch 启动**：进程存活（GUI 初始化 + imlib2 图标 loader 正常）；日志 `Error opening entries file /etc/xlunch/entries.dsv` 为**配置部署项**（entries.dsv 未随 bin 部署），非 imlib2 loader 缺陷。

**结论**：imlib2 1.12.7 升级 + 三组件升级 + scrot 重链全部编译/GUI 验证通过；tint2 未动。imlib2 1.12.7 的 SVG loader 经 configure auto 检查被禁（librsvg 2.40<2.46），但**项目 builtin 注入（改写 2.40 兼容 loader_svg.c）实测可加载 SVG**——后续升级 librsvg（≥2.46）可启用官方 SVG loader，非必须。


## 二、配置项

### 1、mime 数据（gdk-pixbuf 图标/格式识别）（2026-11-17）

#### 1.1、用户问答原文（2026-11-17 保存，一字未改）

> 用户问（原文）："pixbuf 对应的 mime 数据，如不装包，直接拷贝是从哪个目录拷贝来着？所有的发行版都通用吧。"
>
> 用户问（原文）："这个情况对应u-gtk/的应用，静态编译之后跨发行版使用的场景呢？mime数据能达成通用吗？"

**原始结论（2026-11-17 首判）**（出处：`docs/2026/11140827-ci-builder-gtk-lib.md` 5.3 mime 部署问答；`docs/2026/11120827-ci-builder-gtk-app-rootfs.md:440`）：
- **拷贝目录**：`/usr/share/mime`（纯数据目录，非 `loaders.cache`）；R8 实证拷 builder 该目录进 rootfs，png/svg 立即翻 OK。
- **跨发行版通用（首判）**：目标**完整发行版**自带 `shared-mime-info` → 静态应用直接读目标发行版自己的 mime.cache，无需拷贝（实证 engrampa→Ubuntu 22.04 hdmi 成功）。
- **边界**：目标**精简 rootfs** 缺包 → 需装/拷；拷贝须同源同架构。

> **订正（2026-11-17）**：**「目标完整发行版自带 shared-mime-info」不成立**——busybox/openwrt 等精简发行版**不带**该包；**确定性结论见 1.2（mime 统一用 3.13 数据，跨所有发行版通用）/ 1.3（兼容跨度与 GLib 版本）**。

#### 1.2、mime 数据统一用 alpine 3.13 这份——跨所有发行版通用（已实证）

> 看了 rootfs 的 Dockerfile，确认了。这次给死结论，不摇摆。

**靠谱结论（已实证，非推测）**：mime 数据统一用 alpine 3.13 的这份，跨所有发行版通用。

**依据**：
- **rootfs = alpine 3.13.12**（`rootfs/src/Dockerfile:269` `FROM ...alpine---3.13.12`，files1/files2 同），`apk add shared-mime-info`（`:285`）→ rootfs 的 mime 数据来自 **alpine 3.13** 仓库。
- **构建容器 = alpine 3.15**（`Dockerfile:2` `COMPILE_IMG=alpine-compile`，`:96` bin2 阶段），编译 u-gtk → 二进制内静态 glib = **3.15 版**。
- **实证**（你确认「跑过验证 OK」）：**3.15 构建的静态应用 + 3.13 的 mime.cache** → 图标/格式识别 OK。

**为什么通用**：glib 读 `mime.cache` **向后兼容**——新版本静态 glib（3.15）读旧版本 cache（3.13）没问题（上面实证）。所以：
- 只要 mime.cache **不新于**二进制内静态 glib 版本，就兼容。
- 用 **3.13 这份**（最保守，rootfs 已带）部署到任何发行版（busybox/openwrt/alpine/ubuntu…），读取方是二进制内静态 glib（≥3.15，向后兼容读）→ **通用**。
- 目标发行版**无需**自带 shared-mime-info；mime 数据**随产物/部署统一提供**（3.13 这份），`XDG_DATA_DIRS` 指向即可（与 engrampa GSettings schema 先例同模式：`v-engrampa/build.sh:114`）。

**一句话**：mime 数据就用 alpine 3.13 的 `/usr/share/mime`（rootfs 已装那份），随产物部署到所有发行版；它被 3.15 构建的静态 glib 读已验证 OK，且任何 ≥3.13 的静态 glib 都向后兼容读 → 跨 busybox/openwrt 等全部 distros 通用。

#### 1.3、mime 兼容跨度与 GLib 版本（四问结论）

**事实依据（已查证）**：
- **构建镜像** = `alpine-builder-gtk224-2`（`compile/src/Dockerfile:4`），apk 仓库 = **alpine 3.15**（你确认；`v-pcmanfm/build.sh:25` 见其装 `shared-mime-info (2.1-r2)`）。
- **GLib 来源**：u-gtk **不编译 glib**（只编 atk/gdk-pixbuf/gtk/murrine，`u-gtk/build.sh:17,48,202`），**glib 走 apk**（`:20` 注释见 `/usr/lib/libglib-2.0.so`）→ 静态 GLib = 构建镜像 apk 装的那个（3.15 仓库），**不是自己指定源码包**。
- **rootfs** = alpine 3.13.12（`rootfs/src/Dockerfile:269`），`apk add shared-mime-info`（`:285`）→ mime 数据 = **3.13 的**。
- **实证**：3.15 构建静态应用 + 3.13 mime.cache → OK（你确认跑过）。

**1. 跨度到底怎样？** 决定性因素是 **GLib 版本**（不是 glibc/libc）。分三层：
- **跨 libc（musl/glibc）**：**不影响** mime 兼容。mime.cache 是纯数据，`g_content_type_guess` 由二进制内静态 GLib 读文件解析，**不涉及 libc ABI**。musl 静态二进制搬到 glibc 系统能跑，mime 解析照常。
- **纯跨发行版（同 libc）**：**不影响**——只要目标有 mime.cache（或随产物提供），GLib 读它，兼容性只取决于 GLib vs cache 版本。
- **同发行版升级（cache 变新）**：**有方向性**——**新 GLib 读旧 cache OK；旧 GLib 读新 cache 不一定**（cache 格式升级时旧 GLib 可能不识别）。所以 mime 数据**用旧不用新**。

**2. glib 还是 glibc？** 是 **GLib（GNOME 基础库，gdk-pixbuf 依赖），不是 glibc**。跟 glibc 无关。静态编译 → GLib 固定在二进制内，搬任何发行版都是**同一套**。mime 数据选择 = **取不新于二进制内 GLib 版本的 cache**（保证向后兼容），项目就用 3.13 那份。

**3. 静态 GLib 版本来源？** = **构建镜像 `alpine-builder-gtk224-2` 里 apk 装的 glib 静态库**（`/usr/lib/libglib-2.0.a`），对应 **alpine 3.15** 仓库版本（约 glib 2.70.x）。**不是 u-gtk 源码编译，也不是自己指定特定版本源码包**。

**4. mime.cache 兼容跨度？** mime.cache 由 **`update-mime-database`（shared-mime-info 项目）** 生成，文件头有格式版本（MAGIC）。GLib 读它**向后兼容**：
- **能兼容 = mime.cache 格式版本 ≤ 静态 GLib 支持的版本**（即 mime 数据生成程序版本**不新于**静态 GLib 版本）。
- **为什么 3.13 数据对应 3.15 二进制**：3.13 的 mime.cache 是**旧版/同代格式**，被 3.15 的**新版**静态 GLib 读 → GLib 向后兼容读旧 cache → OK。且 shared-mime-info 2.1.x 的 cache 格式多年稳定（3.15 是 2.1-r2，3.13 约同代），格式兼容性更高。

**一句话**：mime 兼容只看 GLib 版本（静态二进制内固定）+ mime.cache 格式版本（shared-mime-info），与 glibc/musl 无关；兼容方向 = 新 GLib 读旧 cache，所以 mime 数据取旧不取新（用 3.13 的），跨所有发行版（含 busybox/openwrt、musl/glibc）通用。

#### 1.4、三处 glib / shared-mime-info 实测版本（2026-11-17 容器实查）

**实测版本**：

| 环境 | 系统 | glib | shared-mime-info（mime 数据生成程序） |
|---|---|---|---|
| rootfs 3.13 | alpine 3.13.12 | 2.66.8-r0 | **2.0-r0** |
| 构建镜像 3.15 | alpine 3.15.11 | **2.70.5-r0**（静态链入二进制） | 2.1-r2（构建环境） |
| hdmi-ubt22 | Ubuntu 22.04.5 | 2.72.4-0ubuntu2.9（系统动态） | **2.1-2** |

**关键（hdmi 也能用的解释）**：
- 二进制内静态 glib = **2.70.5**（3.15 构建，固定）。
- mime.cache 格式由 shared-mime-info 决定：**2.0 与 2.1 的 cache 二进制格式相同**（2.1 未改格式，仅更新数据库内容）→ rootfs（2.0-r0）与 hdmi（2.1-2）生成的 cache 同代。
- **hdmi-ubt22 系统 mime 也能用（用户确认）**：其 shared-mime-info 2.1-2 cache 与 rootfs 2.0-r0 同代格式，均被 2.70.5 静态 glib 向后兼容读 → OK。
- **结论不变**：mime 数据取 **2.0/2.1 同代（≤2.1）** 均可，被 ≥2.70 静态 glib 读都 OK；不必强绑 3.13，只要 cache 格式不新于静态 glib 支持范围。

> **订正（2026-11-17，版本已实查）**：上文「3.13 的 shared-mime-info 精确版本未查到」已解决——rootfs 3.13 = **2.0-r0**、构建 3.15 = 2.1-r2、hdmi = 2.1-2（容器 `apk list`/`dpkg -l` 实查）。实证 3.13→3.15 兼容不变；hdmi 2.1-2 亦实测可用。

### 2、dbus/dunst 在 rootfs 的运行时串接（2026-11-17）

#### 2.1、rootfs 镜像运行时串接：现状缺口与实现方案（2026-11-17 分析，方案 A 已落地）

> 用户指示（2026-11-17）："第一项你只是处理了这个程序的构建，最终还要把它们串起来，在 rootfs 这个镜像环境下面跑。"——即编译层已落地（2.2.8），但 **rootfs 镜像运行时**还要把 notify-send / dunst / dbus 串起来跑通。本节记录现状、缺口与实现方案（方案 A 已拍板开工，见 2.2 落地）。

**现状（编译层已就位，运行时缺一环）**：

| 环节 | 镜像构建层状态 |
|---|---|
| `notify-send` | 静态（x-dunst 内）→ `/usr/local/static/dunst/bin/notify-send`（2.2.8） |
| `dbus-daemon` | 静态（x-dbus）→ `/usr/local/static/dbus/bin/dbus-daemon` |
| dunst.service | 组装层已拷入 `/rootfs/usr/share/dbus-1/services/`（`compile/src/Dockerfile:605-609`，2.2.8） |
| `mime.cache` | `shared-mime-info` 生成（`rootfs/src/Dockerfile:285`，2.2.6④） |
| PATH | clear.sh UPX 压缩 + `/usr/bin` 软链 → `notify-send`/`dunst`/`dbus-daemon` 都在 PATH |

**运行时缺口（关键）**：rootfs 镜像启动后**桌面会话没有拉 D-Bus 会话总线**。查证：
- `rootfs/src/entry.sh:149-156` 的 session bus 逻辑**全是注释**；
- x-de 会话启动链（`entry.sh:64`）`source /.env` 后直接 `exec $START_SESSION`，**无 `DBUS_SESSION_BUS_ADDRESS`**（`entry.sh:45` 的 `env_dbus` 也被注释）；
- `rootfs/src/xconf.sh:79-87` 只建 `/run/dbus/` + machine-id，不拉 session bus；
- fluxbox 静态组件无启动脚本源码，仓库内无其他地方拉 dbus。

→ 结果：桌面里调 `notify-send` 会报 **`Cannot connect to session bus (is DBUS_SESSION_BUS_ADDRESS set?)`**（`notify-send.c:89`），链路断在总线这一环。

**实现思路（推荐：方案 A，entry.sh 会话内拉起总线）**：

改动点：`rootfs/src/entry.sh:64` x-de 会话 `_CMD_`，在 `source /.env` 后、`exec $START_SESSION` 前，拉起静态 `dbus-daemon --session` 并把地址导出进会话环境：

```sh
exec gosu headless bash -c "$envcmd; $decmd; env|grep -v PASS|sort; source /.env; \
  export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address 2>/dev/null); \
  sleep 1; exec $START_SESSION"
```

**原理闭环**（对齐 2.1.2/2.2.5/2.2.7 已验证机制）：
1. 会话总线随桌面会话起（per-user，非 root）；
2. dbus-daemon 启动时扫 `standard_session_servicedirs` → `/usr/share/dbus-1/services/` 已含 dunst.service → **注册 `org.freedesktop.Notifications` 激活条目**；
3. 总线环境继承 x-de 的 **`DISPLAY=:$N`**（envcmd 已有）→ 激活 spawn dunst 时能连 X；
4. 应用/脚本调 `notify-send` → 发 `Notify` → 总线**自动 spawn dunst**（不手动先跑）→ 屏幕显示。

**备选方案 B**：独立 perp dbus 服务（`/etc/perp/x$N-dbus`）+ 地址写文件传给 x-de —— 地址跨服务传递麻烦，不推荐。

**确认点 / 风险**：
1. **桌面会话是否已隐含 session bus**（dotfiles 的 fluxbox startup 可能在别处拉）——仓库不可见，**实测确认**是第一步；若已有则此改动可能冗余/只需保证 notify-send 在会话内调。
2. **dunst.service 的 `Exec=` 路径**是否指向 rootfs 内可达路径（2.2.7 已实测激活 OK，大概率没问题，但落地前核对）。
3. 静态 `dbus-daemon --fork --print-address` 可用性（2.2.5 实测 session bus 通过，大概率 OK）。

**验证方式**：在 **rootfs-dbg 容器 Xvnc 会话**模拟 x-de 启动链（`dbus-daemon --session --fork --print-address` → export → notify-send 发 SVG/PNG → OCR 确认自动拉起 dunst + 显示）；条件允许再重建 rootfs 镜像实跑。临时产物放 `/_ext/tmp/svg/`，不落仓库。

#### 2.2、方案 A 落地：rootfs 桌面会话拉起 D-Bus 总线（entry.sh，2026-11-17）

> 用户指示（2026-11-17）："选方案a开工"——把 2.1 方案 A 落地：rootfs 桌面会话启动链拉起 D-Bus 会话总线，notify-send 发 Notify 经总线激活自动拉起 dunst。用户同时提示（2026-11-17）：软链生产镜像自动做（clear.sh link 步），**rootfs-dbg-v5 手动部署容器无 `/usr/bin` 软链属正常，不影响验证**；clear.sh/Dockerfile 尾部与方案 A 实施无关。

**改动**（`rootfs/src/entry.sh:64`，单 commit `6ccccbd0` 已推送）：x-de 桌面会话 `_CMD_`，`source /.env; sleep 1` 后、`exec $START_SESSION` 前，拉起静态会话总线并导出地址：

```sh
exec gosu headless bash -c "$envcmd; $decmd; env |grep -v PASS |sort; source /.env; sleep 1; \
  export DBUS_SESSION_BUS_ADDRESS=\$(dbus-daemon --session --fork --print-address 2>/dev/null); \
  exec \$START_SESSION"
```

**实跑验证**（rootfs-dbg-v5 模拟 x-de 启动链，Xvnc `:10`，`/_ext/tmp/svg/t_schemeA.sh`）：
1. 杀现有 dunst（不手动先跑）：`dunst_after_kill=0` ✅
2. 拉起新 session bus：`DBUS_ADDR=unix:path=/tmp/dbus-G30REK7UVo,...`（`dbus-daemon --session --fork --print-address`，headless+DISPLAY=:10）✅
3. notify-send 发 SVG：`notify_svg_rc=0` ✅ → **D-Bus 激活自动拉起 dunst**：`dunst_after_notify=1`（pid 2822，PPID 1）✅
4. 注册确认：`GetServerInformation` 返回 `dunst/knopwob/1.13.2`，`ListNames` 含 `org.freedesktop.Notifications` ✅

**关键发现**：dunstctl 硬依赖 `dbus-send` **和 `busctl`**（systemd），rootfs 无 busctl → dunstctl 不可用；验证用 `dbus-send` 直查 `GetServerInformation`/`ListNames` 替代。

**结论**：方案 A 链路闭环——桌面会话拉起会话总线（带 DISPLAY）→ 总线扫描 `/usr/share/dbus-1/services/` 注册 dunst 激活条目 → notify-send 发 `Notify` → **D-Bus 激活自动 spawn dunst** → dunst 注册 `org.freedesktop.Notifications`。生产 rootfs 镜像重启后（含 `notify-send`/`dunst`/`dbus-daemon` 软链，clear.sh link 步自动做）通知链路全通。

#### 2.3、scrot 截图触发通知（2026-11-17 问答）

##### 2.3.1、模拟 vs 真实——截图会不会自动发通知（2026-11-17 用户问）

> 用户问（2026-11-17）："这是你模拟的吗？他真实截图会不会发消息呢？"——区分**验证用的模拟图**与**真实环境截图是否自动发通知**。

**1. `v3_scrot-notify.png` 是模拟的，不是真实桌面自动发的**：在 rootfs-dbg-v5 容器跑验证脚本（`/_ext/tmp/svg/t_scrot3.sh`），脚本**显式**做 `scrot /tmp/x.png && notify-send ...` 串联——即把「截图」和「发通知」接在一起。真实桌面按 scrot **不会**自动这么做。

**2. 真实 scrot 截图不会自动发消息**：`scrot` 是纯截图工具，**无通知 hook**——截图后不会自动 `notify-send`。要让「截图 → 通知」发生，必须**配置**：
- **scrot 后处理**：`scrot -e 'notify-send 截图 "$f"'`（scrot `-e` 参数，截图完执行命令）；
- **用户截图脚本/别名**：把 `scrot /tmp/x.png && notify-send 截图 /tmp/x.png` 串起来（2.1.3 第 4 条「scrot 截图包装脚本」模式）。

**3. 结论**：
- 验证**价值** = 方案 A 的**会话总线 + D-Bus 激活自动拉起 dunst** 链路是真的（scrot 只是触发动作载体，换成任何命令触发 `notify-send` 都通）。
- **「截图自动发通知」不是开箱即得**——生产 rootfs 里需额外配 scrot hook（`-e` 或包装脚本）才有此效果。

##### 2.3.2、三种通知示例触发命令（2026-11-17 用户问）

> 用户问（2026-11-17）："文本以及两种图片的通知示例我该怎么触发？搞命令给我。"——给出文本 / PNG 图片 / SVG 图片三种通知的触发命令（经方案 A 总线 → D-Bus 激活自动拉起 dunst）。

**生产 rootfs 桌面会话**（`notify-send` 已在 PATH、方案 A 总线自动拉起，直接跑）：
```sh
# ① 文本通知（无图标）
notify-send "文本通知示例" "这是一条纯文本通知"
# ② PNG 图片通知
notify-send -i /usr/share/icons/locolor/24x24/actions/xlunch-menu.png "PNG图片通知" "locolor xlunch-menu 图标"
# ③ SVG 图片通知
notify-send -i /usr/share/icons/Papirus/16x16/devices/input-mouse.svg "SVG图片通知" "Papirus input-mouse 图标"
```

**rootfs-dbg-v5 手动验证容器**（无 `/usr/bin` 软链 / 无自动总线，用绝对路径 + 自起总线）：
```sh
export DBUS_SESSION_BUS_ADDRESS=$(/usr/local/static/dbus/bin/dbus-daemon --session --fork --print-address 2>/dev/null)
export DISPLAY=:10
N=/usr/local/static/dunst/bin/notify-send
$N "文本通知示例" "这是一条纯文本通知"
$N -i /usr/share/icons/locolor/24x24/actions/xlunch-menu.png "PNG图片通知" "locolor xlunch-menu 图标"
$N -i /usr/share/icons/Papirus/16x16/devices/input-mouse.svg "SVG图片通知" "Papirus input-mouse 图标"
```

**图标路径**（rootfs-dbg-v5 实测存在）：
- PNG：`/usr/share/icons/locolor/24x24/actions/xlunch-menu.png`（2.2.4 验证 png 同款）
- SVG：`/usr/share/icons/Papirus/16x16/devices/input-mouse.svg`（2.2.9 验证同款）

#### 2.4、dbus 依赖组件清单（2026-11-19）

> 承接 pasystray 滚轮通知修复（一 3.6 全链）：盘点 docs/2026/README.md「真机验证记录表」的组件里，哪些还会用到 D-Bus——避免再踩「bus 该有却没/uid 不匹配」的坑。

##### 2.4.1、验证列表组件与 dbus 依赖关系（完整）

| 类别 | 组件 | 用 dbus 的哪里 | 说明/注意事项 |
|---|---|---|---|
| **硬依赖**（没 session bus 不行） | **dunst** | 接收 `org.freedesktop.Notifications`（D-Bus 服务端/激活） | 与发送方**同一 bus 且同 uid**（本次 pasystray 教训：bus root + 应用 headless → EXTERNAL 认证拒）；手动启动命令见一 3.6.4 |
| | **pasystray** | libnotify → GDBus 发 `org.freedesktop.Notifications`（滚轮/通知） | 修复后（entry.sh dbus 明确 gosu headless）正常 |
| | **ibus** | ibus-daemon/panel/engine 全走 D-Bus（`GTK_IM_MODULE=ibus` 的 im-module） | 待优化实现，机制上硬依赖 dbus 栈 |
| **gvfs/gio 间接**（没 bus 部分功能降级） | **pcmanfm** | libfm/gvfs：trash/挂载/网络浏览 | 基础文件操作可不依赖 dbus |
| | **xfce4-thunar** | gvfs：trash/挂载/网络 | 同上，基础可用 |
| | **engrampa** | 提取目标若在 gvfs 路径 | 次要 |
| **基本不用 dbus** | lxtask、geany、gpicview、gsm、pavucontrol、scrot、xrandr、xbindkeys、rofi、feh、tint2、hsetroot、xlunch、dropbear | — | pavucontrol 走 libpulse native 协议（非 dbus）；rofi 走 EWMH；gsm 已改 gkeyfile/gconf |

**要点**：
- 验证列表里**真正还依赖 dbus 的只有 3 个**：**dunst（收）、pasystray（发）、ibus（输入法框架）**。
- pcmanfm/thunar/engrampa 是 **gvfs 可选**（基础功能不需要 bus，缺少时仅 trash/挂载/网络等降级）。
- **验证层面**：dunst 与 pasystray 必须同 bus、bus uid 与应用一致（本次修复核心）；ibus 若做需完整 dbus 栈（bus + 激活配置）。

##### 2.4.2、dbus-launch 静态化落地与 x11-autolaunch 说明（2026-11-19）

**背景**：dbus-launch（dbus 源码 `tools/dbus-launch.c`，C 程序非脚本）项目会话/脚本常用——`eval $(dbus-launch --sh-syntax)` 起 bus 并输出 `DBUS_SESSION_BUS_ADDRESS`（entry.sh 亦引用）。原 x-dbus 只出 dbus-daemon/dbus-send，未含 dbus-launch，本次补上并安装到 `TARGETPATH/bin`。

**落地**（commit `67179d28` / `86371f2e`）：
- `compile/src/x-dbus/build.sh`：新增 `dbus_launch()`——make `tools/dbus_launch-dbus-launch.o` + `dbus-launch-x11.o` + `tool-common.o`（tools/Makefile `am_dbus_launch_OBJECTS`，对象带 `dbus_launch-` 前缀）→ `xx-clang -static` 链 `libdbus-1.a -lX11 -lxcb -lXau -lXdmcp -lexpat -lpthread -ldl -lm`；case 加 `full-launch`。
- `compile/src/Dockerfile`：dbus stage 加 `sh /src/x-dbus/build.sh full-launch`——产物 `bin/dbus-launch`（1.1M，`statically linked`，`xx-verify`=0；`--version` = `D-Bus Message Bus Launcher 1.12.26`；实测起 bus 输出 `unix:path=/tmp/dbus-8wTRlRyHAA` 可用）。

**`--disable-x11-autolaunch` 实测结论（2026-11-19）**：
- **该选项在 dbus 1.12.26 上无效**：加上后 `config.h` 的 `DBUS_BUILD_X11` 仍为 `1`、`dbus-launch-x11.o` 仍引用 Xlib 符号（XOpenDisplay 等）、`dbus-launch --help` 仍含 `--autolaunch`——**DBUS_BUILD_X11 由 X11 头/库自动检测决定，与该 autolaunch 选项解耦**。
- 若真禁 X11/autolaunch 需 patch configure.ac 改 DBUS_BUILD_X11 检测，收益小（仅省 ~100K X11 静态链），不值得——**已从 build.sh 移除该无效选项**（configure 恢复无该行；保留 X11 链，dbus-launch 功能完整）。
- **autolaunch 功能本身**（`--autolaunch`：X11 selection 共享会话 bus 机制）：headless 容器各会话独立 bus、地址走 env，**用不上**——禁用与否对项目无功能影响（`dbus-launch` 基本用法/`--sh-syntax` 不受影响）。

**问与答（2026-11-19，用户问）**：这个程序（dbus-launch）干嘛要二进制，而不是脚本？他处理了些什么东西？

**答**：dbus-launch 是「小型守护型 helper」，不是包装脚本——干的活脚本干不了/干不稳。

**它处理了什么**：
1. **启动 dbus-daemon + 拿地址**：fork/exec `dbus-daemon --session --fork --print-address`，从 pipe 读回地址——但 daemon 输出的地址是 **D-Bus 协议格式**（长度前缀消息），要解析。
2. **连接验证**：拿到地址后自己**连上 bus** 做一次注册（RequestName 唯一名）确认 bus 真的可用，才把地址交给调用方（防「地址给了但 bus 是坏的」）。
3. **`--exit-with-session`/`--exit-with-x11` 生命周期绑定**：**监视父进程**（waitpid/信号处理），父退出就**杀 daemon**——「守护」职责。
4. **`--autolaunch`（X11 selection 共享）**：通过 X11 的 `_DBUS_SESSION_BUS_SELECTION_*` 属性让同一 X display 多程序**复用同一个会话 bus**——需要 XGetSelectionOwner/XSetSelectionOwner 等 **X 库调用**。
5. **`PROGRAM` 参数**：起一个程序并注入 `DBUS_SESSION_BUS_ADDRESS` 环境变量。
6. **输出格式**：`--sh-syntax` / `--csh-syntax` / `--binary-syntax` 等。

**为什么是二进制不是脚本**：

| 职责 | 脚本（shell）行不行 |
|---|---|
| D-Bus 协议交互（解析地址/连接验证/RequestName） | 弱：dbus-send 能发但每次起进程、错误/超时处理笨拙；这是启动核心路径要可靠 |
| 进程生命周期（waitpid/信号/父退出杀 daemon） | 不可靠：`--exit-with-session` 需严格同步，busybox sh 更弱 |
| 二进制协议（--print-address / --binary-syntax） | 做不到（shell 无二进制解析） |
| X11 调用（autolaunch） | 做不到 |
| 运行时依赖 | **静态二进制自包含**（本项目 xx-clang -static）；**脚本还依赖 dbus-send**（如 dunstctl——没 dbus-send 直接 die） |

**本质**：dbus-launch 是「**启动 + 守护 + 协议交互**」型 helper，不是「发条消息」型（后者如 dunstctl 才适合脚本）。所以 dbus 上游用 C 写，本项目静态链它——产物自包含、无运行时依赖，这也是不该把它做成脚本的原因。

## 三、使用说明

### 1、中文显示（gettext 本地化）（2026-11-20）

#### 1.1、pcmanfm / lxtask / engrampa（2026-11-20 补档）

三者中文显示（界面本地化）由 gettext `.mo` 翻译文件决定；根因相同——编译期 `LOCALEDIR` 宏被硬编码到错误路径（不尊重 `--localedir`），`bindtextdomain` 找不到 `.mo` → 界面英文。修复统一为 `LOCALEDIR=/usr/share/locale`（找系统 `.mo`）+ 运行时 `LANG=zh_CN`，差异仅在补片位置与是否需要补片：

| 组件 | 硬编码位置（根因） | 修复 | 补片 | 落点 |
|---|---|---|---|---|
| lxtask | 无（`src/Makefile.am:4` 本用 `$(localedir)`，尊重 `--localedir`） | configure 加 `--localedir=/usr/share/locale` | 无需补片 | `v-lxde/build.sh:65`（lxtask 函数） |
| pcmanfm | `src/Makefile.am:7` 硬编码 `$(prefix)/$(DATADIRNAME)/locale` | 同上 + Makefile.am 改 `$(localedir)` | `pcmanfm-localedir.patch`（git apply，autogen 前） | `v-pcmanfm/build.sh:199,218` |
| engrampa | `configure.ac:177-184` 两分支硬编码 `LOCALEDIR="${ac_default_prefix}/${DATADIRNAME}/locale"` | 同上 + configure.ac 统一改 `AC_DEFINE_UNQUOTED(LOCALEDIR, "${localedir}")` | `engrampa-1.14.1-localedir.patch`（patch -p1，须 autogen 前；autogen 重生成 configure 才生效） | `v-engrampa/build.sh:38-44,69` |

**验证**（hdmi，`.mo` 放 `/usr/share/locale/zh_CN/LC_MESSAGES/` + `LANG=zh_CN`）：

- lxtask 标题 =「任务管理器」。
- pcmanfm 菜单文本行宽 zh 154–202px vs C 53–141px。
- engrampa 标题 =「demo2.tar.gz [只读]」、菜单非bg 4423(zh) vs 3631(C)。

**时间线**：engrampa 2026-11-05 完成并推送；lxtask/pcmanfm 2026-11-06 完成并推送 `20b3f28`。

**关键坑**：

- `TEXTDOMAINDIR` 对静态二进制无效（engrampa 实测）：gettext 工具变量，非 libintl 运行时；`bindtextdomain` 只读编译期 `LOCALEDIR`。
- `--localedir=/usr/share/locale` 使 `make install` 把 `.mo` 装到 builder 容器 `/usr/share/locale`（非 `TARGETPATH/share/locale`）。
- 补片格式：engrampa 用 `patch -p1`（普通 diff）；pcmanfm 用 `git apply`（须 git diff 生成字节精确，手写缺尾部空行会 `corrupt patch`）。

**对比**：三者与 geany（靠 `$TARGETPATH/share/locale` 自带 `.mo`，无需补片）机制不同；geany/pavucontrol/pasystray 中文显示另有记录（见对应组件文档）。

**lxtask 部署期中文失效根因与修复（2026-11-20）**：

- **现象**：CI 重建 rootfs-dbg 后，其他组件中文显示有，lxtask 仍英文。
- **根因**：rootfs 构建清理脚本 `clear.sh`（`rootfs/src/static/clear/clear.sh`）按 `usr-local-static-dir.txt` **非注释行 `rm -rf /rootfs/$one`**；清单 **`/usr/local/static/lxde/share/locale`** 为非注释 → 整个 lxde/share/locale 被删 → **lxtask.mo 被剔** → 中文英文。这是旧方案（lxtask 走系统 `/usr/share/locale`，无自足 `.mo`）遗留的清理清单，lxtask 改 `$TARGETPATH/share/locale` 自足后**清单未同步**。
- **证据**：镜像 `lxde/share/` 无 `locale` 目录（对比 `gpicview/share/locale/*/*.mo` 正常）；构建日志 `lxtask.log:668` "locales installed: 64 langs"（仅 po 计数）；本地实测 msgfmt 对 64 个 po 全部成功（含 `zh_CN.mo` 3450B，warn=0）；clear.sh 清单 135 行为删除点。
- **修复**：`usr-local-static-dir.txt` 135 行**注释**（`# /usr/local/static/lxde/share/locale`，与 pcmanfm 的 locale 保留方式一致）——commit `66c2573c`。重建 rootfs-dbg 后 lxtask.mo 保留、中文生效。

#### 1.2、README 验证表其他组件多语言/中文 mo 核查（2026-11-20）

用 git clone 源码 + 上游 tarball **实测** `po/zh_CN.po`（非猜测），结论：README 验证表其余组件中，**6 个涉及多语言且有中文 mo**，**11 个无 `po/`、无中文 mo**（不涉及本地化）。

**① 有中文 mo（6 个，与 pcmanfm/lxtask/engrampa 同机制——若要中文需 `--localedir=$TARGETPATH/share/locale` + 装 `.mo`）**：

| 组件 | 版本 | 证据 |
|---|---|---|
| gpicview | 0.2.5 | `po/zh_CN.po`+`zh_TW.po`（github po 64） |
| gsm | 2.28.2 | `po/zh_CN.po`+`zh_HK.po`+`zh_TW.po`（download.gnome.org tarball 实测） |
| thunar | 1.6.3 | `po/zh_CN.po`+`zh_HK.po`+`zh_TW.po`（po 66） |
| ristretto | 0.8.5 | `po/zh_CN.po`+`zh_TW.po`（po 57） |
| xfce4-settings | 4.12.4 | `po/zh_CN.po`+`zh_HK.po`（po 68） |
| ibus | 1.5.35 | `po/zh_CN.po`（110KB，中文最多） |

**② 不涉及多语言（11 个）**：

- **无 gettext 本地化（源码无 `.po`）**：scrot、feh、dunst、rofi（meson 声明 `GETTEXT_PACKAGE` 宏但源码树无 po，2.0.0 tag 实测无）、xrandr（configure.ac 无 gettext）、dbus（1.12.26 tarball `po_count=0`）。
- **纯 C 工具无 po**：dropbear、xbindkeys、hsetroot、xlunch。
- **特例 tint2**：主程序无 po；仅配置器 `src/tint2conf/po/` 有 7 语言（bs/es/fr/hr/pl/ru/sr），**无中文**。

**结论**：需中文显示处理 = 上面 6 个（gpicview/gsm/thunar/ristretto/xfce4-settings/ibus）；无需处理 = 11 个。rofi 源码树无 po（翻译可能由发行版另行打包）；tint2 配置器 po 无中文。

#### 1.3、无 XDG 原生可用——engrampa schema 根因修复 + pcmanfm 验证澄清（2026-11-20）

> **订正（2026-11-20）**：1.1 记 `LOCALEDIR=/usr/share/locale`（找系统 `.mo`）为**旧方案**；实际已提交的 build.sh 用 **`$TARGETPATH/share/locale`**（`--localedir` + msgfmt 装 `.mo`，产物自足可迁移、运行时**不依赖**外部路径）。三组件（lxtask/pcmanfm/engrampa）均已按此落地并推送。

**① engrampa 无 XDG 崩溃根因与修复**（用户拍板"铲掉狗屎"，非"立牌子"——不靠环境变量绕过）：

- **根因**（实跑定位）：崩溃点**不是** `eng_settings_new` 的 fallback（`fr-init.c:707`），而是 **`fr-window.c:5466-5467`** 直接 `g_settings_schema_source_get_default()` + `g_settings_schema_source_lookup()`——无 `XDG_DATA_DIRS` 且默认路径无 schema 时，默认源为 NULL → `lookup(NULL,...)` 断言崩溃。这是绕过 `eng_settings_new`（经 `ENG_SCHEMA_DIR` 自足源）的**唯一漏网点**。
- **修法**：新增 `engrampa-null-schema-source.patch`，守卫 `schema_source ? lookup(...) : NULL`（`schema_source` NULL 时 `caja_schema=NULL`，跳过 Caja 集成；`settings_caja` 后续均有 `if` 守卫）。schema 保持 `$TARGETPATH/share/glib-2.0/schemas` **可迁移**，**无需**装系统默认路径（`/usr/local/share` 或 `/usr/share`）。
- **验证**（rootfs-zh-verify，无 XDG + 无默认路径 schema）：窗口标题=**「归档管理器」**，进程 ALIVE（此前无默认路径 schema 则启动即崩溃）。
- **提交**：`compile/src/v-engrampa/engrampa-null-schema-source.patch` + `compile/src/v-engrampa/build.sh`（幂等应用），推送 `95321ba2`（补丁、build.sh 分两 commit）。

**② pcmanfm 中文验证澄清**（此前"标题不本地化 / --pref 未弹出"为**误判**，中文本就工作）：

- `--pref` 是**无效选项**（`Unknown option`）；正确选项为 `--show-pref=N`（N>0）或 `--desktop-pref`。
- `--show-pref=0` 被源码 `pcmanfm.c:390 if(show_pref > 0)` 跳过；**`--show-pref=1`** 才弹偏好设置页 0。
- `--show-pref=1` 弹出**「偏好设置」**对话框（中文标题）→ gettext 生效；`--help` 全中文；二进制 `LOCALEDIR=/usr/local/static/pcmanfm/share/locale` 正确。
- 主窗口标题=目录路径（如 `/`）是 pcmanfm 正常行为（标题显示当前目录），**非**本地化失败。
- pcmanfm **无** GSettings schema（用配置文件 `~/.config/pcmanfm/`），`--show-pref` 失败与 gschema **无关**。
- 遗留 cosmetic（不崩溃）：启动 4 个 `g_object_unref: assertion 'G_IS_OBJECT' failed`（静态构建 quirk）；`modules directory is not accessible`（无 `.so` 模块，仅影响 `--desktop` 模式）。

**③ 构建坑（engrampa）**：`./autogen.sh` 内部跑**无参** configure（默认 `caja_actions=yes`）→ 报 `libcaja-extension` 未满足，但 autogen.sh 返回 0（吞错）——日志里该 configure 报错为**良性噪音**；build.sh 真正的 `./configure --disable-caja-actions` 成功。**判成功仍以 `xx-verify --static` + 实跑为准**（AGENTS 3 验证条）。

#### 1.4、截图验证与图标主题配置——headless 用户 Papirus-Bunsen-bluegrey（2026-11-20）

三组件中文界面截图（无 XDG、`LANG=zh_CN.UTF-8`）在 `rootfs-zh-verify` 容器 Xvnc `:10` 上完成，窗口标题均中文（lxtask「任务管理器」、pcmanfm「偏好设置」、engrampa「归档管理器」）。发现截图**用户不同 → 图标主题不同 → 图标显隐不同**：

| 版本 | 截图用户 | GTK 图标主题 | 图标警告 | 文件 |
|---|---|---|---|---|
| v1 | **root**（无 `~/.gtkrc-2.0`） | 默认 `hicolor`（只含 `scalable`，**不完整**） | engrampa `extract-archive`、pcmanfm `media-eject` **"Could not find icon"** | `lxtask.png`/`pcmanfm.png`/`engrampa.png` |
| v2 | **headless** | **`Papirus-Bunsen-bluegrey`**（`Inherits=Papirus` → 回退补 `actions`） | **全消失** | `v2_lxtask.png`/`v2_pcmanfm.png`/`v2_engrampa.png` |

**图标主题配置位置**（GTK2 读 `~/.gtkrc-2.0`）：

- **headless** 用户 `/home/headless/.gtkrc-2.0`（LXAppearance 写入，含 `gtk-icon-theme-name="Papirus-Bunsen-bluegrey"`、`gtk-theme-name="Greybird"`、`gtk-font-name="Sans 10"`、`gtk-cursor-theme-name="DMZ-White"`）。
- **root** 用户**无**任何 `~/.gtkrc-2.0`/`.icons` → GTK 回退默认 `hicolor`。
- 桌面（Xvnc/fluxbox/tint2）本就由 **headless** 用户启动（rootfs-dbg entrypoint）；应用验证/截图也应 **headless** 用户跑才与桌面一致、图标主题正确。

**Papirus-Bunsen-bluegrey 图标补齐机制**：该主题目录只有 `apps`/`places`（**无 `actions/`**），但 `index.theme` 写 `Inherits=Papirus,breeze,gnome,hicolor` → GTK 查找 `actions` 图标时**继承回退到 Papirus**（`/usr/share/icons/Papirus/16x16/actions/extract-archive.svg`）→ 显示正常。

**结论**：GUI 应用验证/截图以 headless 用户跑（读其 gtkrc 的 Papirus 主题）；root 跑会因无配置回退不完整 `hicolor` 而图标空白。v1（root）保留作对比，v2（headless）为正确版。

#### 1.5、其余中文组件改造思路（gpicview/gsm/xfce4-settings/thunar/ristretto；**ibus 暂缓**）（2026-11-20）

延续 1.1 已完成三组件（pcmanfm/lxtask/engrampa）的统一模式，处理 1.2 核查出的其余**有中文 mo** 组件。**ibus 用户拍板先不做**（涉及输入法引擎 librime/x11，范围大，中文显示只是其一）。

**统一原则**（同已完成三组件）：

1. `LOCALEDIR` 编入 **`$TARGETPATH/share/locale`**（`--localedir`，或 configure.ac/Makefile.am 硬编码时补 patch 改 `$(localedir)`）——产物自足可迁移，运行时**无 XDG/无环境变量**即中文。
2. `po/*.po` 用 **`msgfmt`** 转 `.mo` 装 `$TARGETPATH/share/locale/$lang/LC_MESSAGES/`（make 默认不产 `.mo`）。
3. 验证：build.sh 改后重编 → 容器实跑窗口标题/菜单中文（无 XDG，**headless** 用户——图标主题才正确）。

**各组件改法**：

| 组件 | 位置 | 基准/系统 | 当前 localedir | 改法 |
|---|---|---|---|---|
| gpicview | `v-gpicview` | gtk224-2 / autotools | 未处理（默认 `prefix`） | configure 加 `--localedir=$TARGETPATH/share/locale` + msgfmt |
| gsm | `v-sysmonitor` | **basemm**（gtkmm-2.4） | 未处理 | 同法 + **必须用 gtkmm 基准**（`alpine-builder-gtkmm224-2`） |
| xfce4-settings | `v-xfce4` | gtk224-2 / autotools | `make localedir=/usr/share/locale`（**旧**） | 改 `$TARGETPATH/share/locale` + msgfmt |
| thunar | `v-xfce4` | gtk224-2 / autotools | 同上（Dockerfile **注释未构建**） | 同上 + 先确认能构建、启用 Dockerfile stage |
| ristretto | `v-xfce4` | gtk224-2 / autotools | 同上（**注释未构建**） | 同上 |
| ibus（**暂缓**） | `v-ibus` | FROM dbus / bash-only | 未处理 | 加 localedir + msgfmt；范围大（输入法引擎），后续再说 |

**风险 / 注意**：

- **gsm**：gtkmm 组件，**禁**用 gtk224-2（AGENTS 五章 1）——必须 basemm 基准；已有多 patch（gconf/tab-order/exit-crash），localedir 需新增。
- **v-xfce4**：三组件共享 xfce 库栈 + `b_deps`；thunar/ristretto 在 Dockerfile `399-400` **注释**（可能未完整构建/依赖缺）——先确认能构建再改。
- **ibus**：`v-ibus/build.sh` 是 **bash-only**（busybox sh 解析失败 line297）→ 用 `bash` 调用；暂缓。
- **补片格式**：autotools 硬编码用 `patch -p1`（engrampa）或 `git apply`（pcmanfm，须字节精确）；改 prefix 后**清 `.o` 重编**（AGENTS 3.2）。
- **判成功别信 `oneBuild`**：`xx-verify --static` + 实跑兜底。

#### 1.6、其余中文组件落地与验证（gpicview/gsm/xfce4-settings/thunar/ristretto）（2026-11-20）

1.5 思路已全部落地并验证（**ibus 暂缓**）。统一模式确认：产物自足 `.mo` 装 `$TARGETPATH/share/locale`，无 XDG + headless 用户实跑标题中文。

| 组件 | 改法 | 验证标题（`_NET_WM_NAME`） | commit |
|---|---|---|---|
| gpicview | `PACKAGE_LOCALE_DIR=$(prefix)/share/locale` 本已编入正确，补 msgfmt `.mo` | **图像查看器** | `e99ec182` |
| gsm | `--prefix=/usr/local/static/gsm` 本已编入正确，补 msgfmt `.mo` | **系统监视器** | `4a4f195a` |
| xfce4-settings | `--disable-nls`→`--enable-nls` + `localedir=$TARGETPATH` + msgfmt | **显示** | `446b75c8` |
| thunar | `localedir=$PREFIX` + `PACKAGE_LOCALE_DIR=$PREFIX` + msgfmt | **文件系统 - 文件管理器** | `446b75c8` |
| ristretto | `localedir=$PREFIX` + msgfmt | **pic.png - 图片查看器** | `446b75c8` |

三二进制均 `xx-verify --static` OK（statically linked, stripped），`.mo` 与 LOCALEDIR 编入路径均已核对。

**遇到并解决的问题**：

- **thunar `.mo` 大小写 domain**（子任务修复，build.sh `257-261`）：thunar `GETTEXT_PACKAGE="Thunar"`（**大写 T**，config.h），`xfce_textdomain(GETTEXT_PACKAGE)` 查 `Thunar.mo`；只输出小写 `thunar.mo` 时 gettext 找不到 → 标题英文。修复：msgfmt 输出 **`Thunar.mo`** + `cp` 保小写兼容。用最小 gettext 探针验证（`bindtextdomain("Thunar")` 无 `Thunar.mo`→英，补→中）。
- **rootfs 无 zh_CN locale 数据**（验证环境，非产物缺陷）：rootfs-zh-verify 为 Alpine 3.13（musl），`musl-locales` 包**不含 zh_CN.UTF-8**（仅到 sv_SE）→ `setlocale` 失败 → gettext 全回退英文。补齐：`apk add musl-locales build-base musl-dev` + 复制 `/usr/share/i18n/locales/musl/en_US.UTF-8 → zh_CN.UTF-8`（musl 按名加载）。注意：**验证环境需 zh_CN locale 数据，构建产物无需**——真机发行版自带。
- **窗口标题抓取**：`xwininfo -root -children` 抓到 Gtk 辅助小窗口（程序名 fallback），应改 `xprop -root _NET_CLIENT_LIST` + 逐窗口 `_NET_WM_NAME` 精确抓主窗口标题。

**结论**：1.2 核查出的 6 个有中文 mo 组件，5 个已中文可用（本小节），1 个暂缓（ibus，输入法引擎范围大）；加上已完成三组件（1.1/1.3），除 ibus 外全部可无 XDG 原生中文。

**验证环境改动（非仓库文件）**：rootfs-zh-verify（Alpine 3.13 musl）已装 `musl-locales build-base musl-dev` + 复制 `zh_CN.UTF-8` locale 数据（仅验证用；构建产物/真机无需）。临时容器：`builder-gsm-zh`（basemm 基座，gsm 构建用，待清理）、`builder-g224`（gtk224 基座）、`rootfs-zh-verify`（验证，保留备用）。后续待办：ibus（暂缓）中文处理；临时容器清理提示。

**第二批截图（gpicview/gsm/xfce4-settings/thunar/ristretto）已推送**（`bbdce9f4`，`docs/img/tmp/locale-zh/`，5 张）：`v2_gpicview.png` / `v2_gnome-system-monitor.png` / `v2_xfce4-display-settings.png` / `v2_thunar.png` / `v2_ristretto.png`——headless 用户 + 无 XDG + `LANG=zh_CN.UTF-8`，Xvnc `:10`，窗口标题均中文（图像查看器 / 系统监视器 / 显示 / 文件系统 - 文件管理器 / pic.png - 图片查看器）。ristretto 打开需图片参数，用 gpicview 自带 PNG（`share/gpicview/object-rotate-left.png`）复制到 `/tmp/pic.png`。**图片单独提交**（不含 build.sh，与 1.4 截图同目录命名 v2_ 前缀）。
