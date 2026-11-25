# docs/2026 文档索引与真机验证记录

## 章节表（按文件名月份）

- **09 月**
  - [09261448-openbox-解析与优化.md](09261448-openbox-解析与优化.md) 【依赖闭包、全开功能开关实测、build.sh 落仓改动】
  - [09261949-lxtask-解析与优化.md](09261949-lxtask-解析与优化.md) 【图标/主题失效根因排查、问答实录、主题路径配置】

- **11 月**
  - [11040000-u-gtk.md](11040000-u-gtk.md) 【图标/主题免环境变量/中文/输入法，改造落到哪个库】
  - [11050341-lxde-pcmanfm.md](11050341-lxde-pcmanfm.md) 【三类问题复现、根因定位、调试技巧、Dockerfile 重跑】
  - [11051001-imlib2-apps.md](11051001-imlib2-apps.md) 【xlunch/feh 图标显示、feh 用不了修复】
  - [11051218-v-geany.md](11051218-v-geany.md) 【版本决策、构建过程、打印后端合并复盘】
  - [11051633-v-pavucontrol.md](11051633-v-pavucontrol.md) 【版本定稿 3.0、开工规划、音量 tray 图标选型】
  - [11051652-v-oth.md](11051652-v-oth.md) 【gsm/engrampa/ibus/xfce4 选型与难度】
  - [11051758-v-oth-impl01.md](11051758-v-oth-impl01.md) 【engrampa/gsm/rofi/dunst 逐章调试实录】
  - [11061251-v-oth-impl02-ibusA.md](11061251-v-oth-impl02-ibusA.md) 【构建调试、panel 候选窗、落仓复现】
  - [11061251-v-oth-impl02-ibusB.md](11061251-v-oth-impl02-ibusB.md) 【部署形态对比、三待办收尾、fcitx/动静态输入法分析】
  - [11080050-v-oth-check01.md](11080050-v-oth-check01.md) 【磁盘 tab 卡顿、主题前缀、魔改库排查、CI 入口自查】
  - [11091127-ci-builder-gtk.md](11091127-ci-builder-gtk.md) 【gtk224 更名、烘焙候选、缓存清理、日志错误码】
  - [11110827-ci-builder-gtk-app.md](11110827-ci-builder-gtk-app.md) 【pulse 栈落地、xfce4 结果、网络排查】
  - [11120827-ci-builder-gtk-app-rootfs.md](11120827-ci-builder-gtk-app-rootfs.md) 【镜像五次拉取分析、图标排查、依赖重排修复】
  - [11121650-x-dropbear-auth.md](11121650-x-dropbear-auth.md) 【认证失败、yescrypt 根因、版本升级评估】
  - [11130827-ci-builder-tarsrc.md](11130827-ci-builder-tarsrc.md) 【源码包下载源收集、tarsrc 仓库接入、快照缓存】
  - [11140827-ci-builder-gtk-lib.md](11140827-ci-builder-gtk-lib.md) 【svg 注册库层根治、mime 修正、共同依赖问答】
  - [11150827-ci-builder-gtkmm-lib.md](11150827-ci-builder-gtkmm-lib.md) 【编译缺依赖修复、tarsrc 复用、基底评估】
  - [11170850-selected-app-use.md](11170850-selected-app-use.md) 【gpicview/pcmanfm/geany 升级、xfce4/tint2/rofi 版本评估】
  - [11170851-selected-app-modifyA.md](11170851-selected-app-modifyA.md) 【gsm 界面改造、dbus/dunst 串接、pasystray 托盘通知】
  - [11241240-v-oth-impl03.md](11241240-v-oth-impl03.md) 【clipit 剪贴板托盘静态化、xdotool 连带】

---

# docs/2026 真机验证记录（以本 README 为准）

> **说明（2026-11-15）**：本 README 为**真机（rootfs-dbg）验证结果的权威记录**——
> 与 `docs/2026/11140827-ci-builder-gtk-lib.md` 二章 3.3 表**同步更新**；若有出入，**以本 README 为准**。
> 状态列：<span style="color:#2e7d32;">✔</span> 已过 / ❌ 待修 / ⏳ 待确认。灰勾（<span style="color:#8a8a8a;">✔</span>）表示**已过 + 项目未选用**。

## 真机验证记录表（2026-11-15 用户 rootfs-dbg 最新实测）

| 组件 | 版本 | 真机实测（用户 rootfs-dbg） | 状态 | 文档跟踪 | 上游:最新/状态/原始仓 |
|---|---|---|---|---|---|
| lxtask | 0.1.12 (最新) | 正常 | <span style="color:#8a8a8a;">✔</span> 正常 | u-gtk 改造（11040000） | 0.1.12；即最新（2026-11-23 改 tag 构建，原 master 分支）；github.com/lxde/lxtask |
| pcmanfm | 1.3.1→1.4.0 | 正常（修复后静态二进制已出，可用；gvfs→dbus 可选，trash/挂载降级） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 5.2.2 / 11140827 二章 3.3 订正 | <span style="color:#2e7d32;">✔</span> 已升级 gtk2环境最新（1.4.0，2026-11-23 三仓库 libfm/menu-cache 同升）；1.4.0；github.com/lxde/pcmanfm |
| geany | 1.34.0→1.37.1 | 正常 | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 5.2.1 | <span style="color:#2e7d32;">✔</span> 已升级 gtk2环境最新（1.37.1，GTK2 最后一版）；2.1.0；跨代（1.x→2.x）；github.com/geany/geany |
| gpicview | 0.2.5→0.3.1 | 正常 | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 2.2.x | <span style="color:#2e7d32;">✔</span> 已升级 gtk2环境最新（0.3.1，GTK2 最后版）；0.3.1；github.com/lxde/gpicview |
| engrampa | 1.14.1 (gtk2最新) | 正常（gvfs→dbus 次要可选） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 5.2.1 | <span style="color:#2e7d32;">✔</span> gtk2环境最新（1.14.1，无更高 GTK2）；v1.28.5；有更新；github.com/mate-desktop/engrampa |
| gsm | 2.28.2 (gtk2最新) | c_gtkmm=yes 后正常（18.7M static） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 6.5 / c_gtkmm 验证 | <span style="color:#2e7d32;">✔</span> gtk2环境最新（2.28.2，无更高 GTK2）；51.1；跨代极大（GTK2→GTK4）；gitlab.gnome.org/GNOME/gnome-system-monitor |
| pavucontrol | 3.0 (gtk2最新) | 可用（四应用全部出 bin，2026-11-16 已修复） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 6.5 | <span style="color:#2e7d32;">✔</span> gtk2环境最新（3.0，无更高 GTK2）；6.2；跨代（GTK2→GTK3）；gitlab.freedesktop.org/pulseaudio/pavucontrol |
| pasystray | 0.8.2 (最新) | 可用（make 链接源头修，static+verify PASS；用 dbus 发通知，见 11170850 一 3.6.4 已修 headless bus） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 6.5.5 | <span style="color:#2e7d32;">✔</span> 最新（停更即最新）；0.8.2；停更（即最新）；github.com/christophgysin/pasystray |
| xfce4（三件：thunar 等） | thunar 1.6.3→1.6.18（ristretto 0.8.5、xfce4-settings 4.12.4） | 正常（2026-11-23 重编 14.98M static+xx-verify pass；GUI 实测需 dbus 会话，Xfconf/thumbnailer 正常；gvfs→dbus 可选） | <span style="color:#2e7d32;">✔</span> 正常 | v-xfce4 / 11170850 8.2 | <span style="color:#2e7d32;">✔</span> 已升级 gtk2环境最新（thunar 1.6.18，2026-11-23，GTK2 最后版；ristretto/xfce4-settings 未动）；thunar 4.20.10（ristretto 0.14.0、xfce4-settings 4.20.5）；跨代（1.x→4.x）；gitlab.xfce.org（thunar/ristretto/xfce4-settings） |
| dropbear | 2026.94 (最新) | 2026-11-16 修复后 hdmi 端口 51023 ssh 登录 test 用户（`$y$j9T$` yescrypt shadow）成功；阴性对照旧版 Bad password×3 → 修复生效 | <span style="color:#2e7d32;">✔</span> 正常 | 11121650-x-dropbear-auth.md 5.1 | 2026.94；即最新；github.com/mkj/dropbear |
| xrandr | 1.5.4 (最新) | 正常 | <span style="color:#2e7d32;">✔</span> 正常 | — | 1.5.4；即最新；gitlab.freedesktop.org/xorg/app/xrandr |
| xbindkeys | 1.8.7 (最新) | 正常 | <span style="color:#8a8a8a;">✔</span> 正常 | — | 1.8.7；近停更（官网 2020 后未更新）；nongnu.org/xbindkeys |
| rofi | 2.0.0→2.1.1 | `-version` 2.1.1（static+verify pass，部署 hdmi）；xim/imdkit 编入（运行时默认关，需 `-imdkit true` 或 config `imdkit: true` 启用） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 5.2.3 / 11170850 一 9.2 | 2.1.1；即最新（2026-11-23 升级 2.0.0→2.1.1，开 xim/imdkit 支持，自建 xcb-imdkit 静态库）；github.com/davatorium/rofi |
| clipit | 1.4.5+git20241103 (最新) | 静态 PASS（12.9M，xx-verify rc=0）；hdmi Xvnc :318 + tint2 托盘宿主启动存活 6s+ 无崩溃、scrot 截图 30K 正常（11241240 2.4） | <span style="color:#2e7d32;">✔</span> 正常 | 11241240-v-oth-impl03.md | 1.4.5+git20241103（commit f35db54）；弃更即最新（last tag 1.4.5@2020-06，2024-11 C99 fix，Debian/Ubuntu deprecated）；github.com/CristianHenzel/ClipIt |
| scrot | 1.12.1 (最新) | 按用法执行使用：正常（存可写 cwd） | <span style="color:#2e7d32;">✔</span> 正常 | 11140827 二章 3.1 ③ | 1.12.1；即最新（imlib2 线，2026-11-23 重链 imlib2 1.7.4→1.12.7）；2.0.0 需 imlib2≥1.11 不可用（9.1 评估）；github.com/resurrecting-open-source-projects/scrot |
| tint2 | 16.1→16.7 | <span style="color:#8a8a8a;">待编译验证</span>（build.sh 已切 `--branch=16.7`、16.7 快照已落 tarsrc；2026-11-23 用户指示 tint2 不动不验证，未重编——9.4 评估 16.7 为最后 GTK2 版） | ⏳ 待确认 | 11140827 二章 3.1 ② / 11170850 9.4 | <span style="color:#2e7d32;">✔</span> 已升级 gtk2环境最新（16.7，17.0 起 tint2conf 转 GTK3）；17.0.2；冻结（官方最终版）；imlib2 未重链（本次 tint2 未重编，仍链旧 1.7.4）；gitlab.com/o9000/tint2 |
| feh | 3.10.3-master→3.13.1 | 按用法执行使用：正常 | <span style="color:#8a8a8a;">✔</span> 正常 | 11140827 二章 3.1 ①/③ | 3.13.1；即最新（2026-11-23 升级，重链 imlib2 1.7.4→1.12.7）；github.com/derf/feh |
| hsetroot | 1.0.5-master→1.1.0 | 11-15 五应用静态 PASS（9.7M），真机待确认 | <span style="color:#8a8a8a;">✔</span> 正常 | 11140827 二章 2.2 | 1.1.0；即最新（2026-11-23 升级，需 imlib2≥1.12.6，已满足 1.12.7）；github.com/himdel/hsetroot |
| xlunch | v4.7.5=master→v5.10.6 | 11-15 五应用静态 PASS（36.1M），真机待确认 | <span style="color:#8a8a8a;">✔</span> 正常 | 11140827 二章 2.2 | v5.10.6；即最新（2026-11-23 升级，重链 imlib2 1.7.4→1.12.7；上游 Tomas-M/xlunch，非 jarun）；github.com/Tomas-M/xlunch |
| dunst | 1.13.2 (最新) | 依赖 dbus（通知接收；bus 须与发送方同 uid，见 11170850 一 3.6）——headless bus 下通知显示实测 OK（一 3.6.4 滚轮通知验证） | <span style="color:#2e7d32;">✔</span> 正常 | ci-rootfs 5.2.1 / 11170850 一 3.6.4 | 1.13.2；即最新；github.com/dunst-project/dunst |
| dbus | 1.12.26→1.16.4 (最新) | session bus 实测（headless daemon + 通知链路走同 bus 正常，一 3.6）；bus uid 须与桌面应用一致（entry.sh 已修） | <span style="color:#2e7d32;">✔</span> 正常 | 11170850 一 3.6 / 2.3.2 | 1.16.4；即最新（2026-11-23 方案C 升级，Meson 构建，含 CVE-2026-120749 等）；gitlab.freedesktop.org/dbus/dbus |
| ibus | 1.5.35 (最新) | 功能庞大（ibus/rime 适配），待优化实现（**硬依赖 dbus 栈**：daemon/panel/engine 全走 D-Bus） | 待优化实现 | 11061251-v-oth-impl02-ibusA.md / 11061251-v-oth-impl02-ibusB.md | 1.5.35；即最新；github.com/ibus/ibus |

**dbus 依赖说明（2026-11-19）**：验证列表中**硬依赖** dbus 的只有 **dunst（收）**、**pasystray（发）**、**ibus（输入法框架）**；**pcmanfm / thunar（xfce4）/ engrampa** 为 **gvfs→dbus 可选**（缺 bus 仅 trash/挂载/网络等功能降级，基础操作不受影响）；其余组件（lxtask/geany/gpicview/gsm/pavucontrol/scrot/xrandr/rofi/feh/tint2/hsetroot/xlunch/dropbear 等）基本不依赖。完整表格见 `11170850-selected-app-use.md` 二章 2.4.1。

## 待办

- **tint2**：librsvg `.la` 剪环（`8821ce3`）+ 编译段 ldd.txt echo 静默（`a07898d`）已提交、 builder 本地重建 `err 0 pass`，待 CI 复跑确认。
- **dunst**：依赖 dbus，待部署后测。
