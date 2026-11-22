# selected-app-use：x11 通用桌面组件微调/配置/使用说明

> 背景：x11 通用桌面组件，初步选用 lxtask、pcmanfm、geany、gpicview、engrampa、gsm、pasystray、pavucontrol、xfce4-display-settings 为主，配套 scrot、xrandr、rofi、dbus/dunst 等工具。文档用于存放组件的微调/配置/使用说明等。具体章节接下来细化。

## 目录

- 一、调整项
  - 1、gsm界面改造(4tab顺序:System移最后+默认激活Processes) + 评估版本已最新
  - 2、dbus/dunst 静态版在 headless 会话的使用
  - 3、pasystray 音量托盘通知(libnotify静态化) + pavucontrol 评估版本已最新
  - 4、gpicview 设置对话框报错 + 版本升级（2026-11-22）
  - 5、pcmanfm 升级与右键菜单修复（2026-11-23）
  - 6、geany 升级评估 + 1.37.1 升级实现与验证（2026-11-23）
  - 7、engrampa 最新支持 GTK2 版本评估（2026-11-23）
  - 8、XFCE 组件 最新支持 GTK2 版本评估（2026-11-23）
  - 9、tint2/rofi/scrot 评估 + rofi 2.1.1 升级实现与验证 + imlib2 升级评估（2026-11-23）
  - 10、feh/hsetroot/xlunch 最新版本评估（2026-11-23）
- 二、配置项
  - 1、mime 数据（gdk-pixbuf 图标/格式识别）
  - 2、dbus/dunst 在 rootfs 的运行时串接
- 三、使用说明
  - 1、中文显示（gettext 本地化）

## 一、调整项

### 1、gsm界面改造(4tab顺序:System移最后+默认激活Processes) + 评估版本已最新

#### 1.1、评估分析（2026-11-16 评估，2026-11-17 落档）

> 用户需求：gsm（GNOME System Monitor）主界面 4 个 tab，把第 1 个 System 放到最后，默认打开激活 Processes。先评估改法/代码量。

**现状（源码 `/tmp/gsm-build/gsm/src/`，构建容器内）**：

| 项 | 位置 | 内容 |
|---|---|---|
| 枚举 | `procman.h:64-67` | `PROCMAN_TAB_SYSINFO, PROCMAN_TAB_PROCESSES, PROCMAN_TAB_RESOURCES, PROCMAN_TAB_DISKS` → 索引 0=System,1=Processes,2=Resources,3=Disks |
| 显示顺序 | `interface.cpp:691-703` | `gtk_notebook_append_page` 依次 System→Processes→Resources→Disks |
| 默认激活 | `procman.cpp:299` + `interface.cpp:711` | `current_tab` 从 gconf `/apps/procman/current_tab` 读取（默认 0=System），启动 `set_current_page(current_tab)` |

**改法（2 处，~10 行 diff）**：

① `procman.h:64-67` 枚举重排（改索引语义，符号引用全跟随）：
```c
PROCMAN_TAB_PROCESSES,   /* 0 */
PROCMAN_TAB_RESOURCES,   /* 1 */
PROCMAN_TAB_DISKS,       /* 2 */
PROCMAN_TAB_SYSINFO      /* 3 */
```

② `interface.cpp:691-703` append 顺序重排（与枚举一致，显示索引=枚举值）：
```c
gtk_notebook_append_page(notebook, vbox1, tab_label1);        /* Processes → 0 */
gtk_notebook_append_page(notebook, sys_box, tab_label2);      /* Resources → 1 */
gtk_notebook_append_page(notebook, devices_box, tab_label3);  /* Disks → 2 */
gtk_notebook_append_page(notebook, sysinfo_box, sysinfo_label); /* System → 3 */
```

**默认激活 Processes：自动满足（无需额外改）**——枚举改后 `PROCMAN_TAB_PROCESSES=0`，gconf `current_tab` 默认 0 → 启动即 Processes。不必再显式改 `interface.cpp:711`（若想强制可在 711 前加 `procdata->config.current_tab = PROCMAN_TAB_PROCESSES;`，属冗余）。

**关键点 / 风险**：
- 显示索引必须 = 枚举值（①②同时改保证），否则 `set_current_page(PROCMAN_TAB_PROCESSES)` 错位——唯一易错点。
- 枚举值变 → gconf `current_tab` 数值语义变（老配置 0 原=System 现=Processes；3 原=Disks 现=System）。自用静态应用可接受；严格兼容须迁移（不建议）。
- 所有 `PROCMAN_TAB_*` 引用（`--show-system-tab`→SYSINFO=3、`processes_sensitivity`→PROCESSES=0、tab 切换回调 `callbacks.cpp:337` 的 page num）均符号引用自动跟随，无遗漏。
- `procdialogs.cpp:527/642/707` 的 append_page 是别的对话框（进程详情/系统信息），不动。

**验证建议**：改后需在 gsm 构建容器（libgtop/libwnck/gtk 栈）实跑 + Xvnc 截图确认 tab 顺序 [Processes, Resources, Disks, System]、默认页 Processes。构建环境容器待查（`/tmp/gsm-build` 在，但哪个容器具备 gsm 依赖栈需确认）。

#### 1.2、实现过程与总结（2026-11-17）

> 承接 1.1：评估判"默认激活 Processes 自动满足（无需额外改）"，实现时**证伪**——因 CLAMP 边界 min>max 失效，强制的 0 被钳回 3(System)。需强制 + CLAMP 边界修正。以下为实现细节与验证。

**实现（3 处，`compile/src/v-sysmonitor/gsm-tab-order.patch`）**：

| # | 文件 | 改动 |
|---|---|---|
| ① | `src/procman.h` | 枚举重排：`PROCMAN_TAB_PROCESSES, PROCMAN_TAB_RESOURCES, PROCMAN_TAB_DISKS, PROCMAN_TAB_SYSINFO`（索引 0/1/2/3） |
| ② | `src/interface.cpp` | append 顺序重排（与枚举一致）：Processes→Resources→File Systems→System（System 移最后） |
| ③ | `src/procman.cpp` | 两处：`current_tab` 读取后**强制** `= PROCMAN_TAB_PROCESSES`（不记忆 last tab）；尾部 CLAMP 边界改 `CLAMP(current_tab, PROCMAN_TAB_PROCESSES, PROCMAN_TAB_SYSINFO)` |

**根因（默认激活落在 System）**：①后枚举 SYSINFO=3、DISKS=2，原 `CLAMP(current_tab, PROCMAN_TAB_SYSINFO, PROCMAN_TAB_DISKS)` 即 `CLAMP(x, 3, 2)` **min>max 失效**——GLib CLAMP 当 `x<low` 返回 low，`CLAMP(0,3,2)=3(System)`，把③强制的 0 钳回 3。修复为 `CLAMP(current_tab, PROCMAN_TAB_PROCESSES, PROCMAN_TAB_SYSINFO)`（0..3 有效）。

**headless procman.ini 残留坑**：`/_ext/home/headless/.config/gnome-system-monitor/procman.ini` 有 `current_tab=i:3`（旧枚举 3=Disks；重排后 3=System）→ 语义错位且与强制行冲突，验证时删除。③强制行保证启动即 Processes，不读旧值，自用静态应用可接受。

**验证**：
- 构建容器 `builder-g224`（`alpine-builder-gtk224`，u-gtkmm 栈已具备）编译 gsm，产物 18M static，`xx-verify --static`=0。
- 运行容器 `docker-hdmi-desktop-desktop-1`（app-ubuntu-22.04，TigerVNC 1.13.1）Xvnc `:603` headless 实跑，截图 OCR 确认：tab 栏 =「Processes | Resources FileSystems System」（System 移最后）；默认激活页内容区为进程表（Load averages/User/Status/Sleeping/Running）= Processes。✅

**总结**：tab 顺序调整 + 默认激活 Processes 均达成；1.1 的"自动满足"结论被实现证伪，根因是枚举重排后 CLAMP min>max 失效，须强制 current_tab + 修正 CLAMP 边界。验证截图（hdmi Xvnc :603 OCR）确认默认激活 Processes。

#### 1.3、gsm 配置（procman.ini / 进程列表列显示）

##### 1.3.1、配置文件机制与默认值（2026-11-17 调研+实测）

> 用户问：procman.ini 是运行时配置吗？运行自动创建还是调整后创建？还有其他配置文件吗？设置项存哪？无配置文件时默认取哪？发布包有默认配置文件吗？

**结论：gsm 配置全走 GConf（XML 后端），唯一配置文件 `~/.config/gnome-system-monitor/procman.ini`（key 前缀 `/apps/procman/`）。**

- **创建时机**：**不是运行就自动创建**——纯运行（不退出）不创建；**正常关闭窗口（delete-event→`cb_app_delete`→`procman_save_config`）或用户调整设置时**创建/更新。实测：hdmi Xvnc `:605` 无 ini 启动 → xdotool 关窗 → **自动生成 procman.ini**（1954B，`[procman]` 节 + `apps/procman/{proctree,disktreenew}/col_N_{width,visible}` + `columns_order`）；SIGKILL/杀进程不创建。
- **"设置"对话框项**：同一 ini 的 `/apps/procman/` 下（`update_interval`、`show_tree`、`show_all_fs`、`view_as`、各颜色、`kill_dialog` 等；key 清单见源码 `gnome-system-monitor.schemas.in`）。无独立配置文件。
- **无配置文件时默认**：`procman_get_tree_state` 先 `gconf_client_dir_exists(prefix)`，**FALSE → 不读配置，用程序内部代码默认**（建列默认全列可见；各 config 项用代码初始值）。
- **发布包无默认配置文件**：静态产物 `/usr/local/static/gsm` 只装 `applications`+`pixmaps`，**无 schemas、无 procman.ini**；schema 默认值（仅 name/status 可见）**不生效**（schema 未安装到 gconf）。→ **无配置文件时按程序内部默认值（全列显示）**。

##### 1.3.2、默认设置需求项：出包默认隐藏部分进程列表列（2026-11-17）

> 用户需求：出包后就有一些默认设置，如进程列表某些列不显示。

**列 ID↔名称**（`proctable.cpp` titles[]，`sort_column_id`=数组索引）：

| ID | 名称 | ID | 名称 | ID | 名称 |
|---|---|---|---|---|---|
| 0 | Process Name | 6 | Shared Memory | 12 | ID |
| 1 | User | 7 | X Server Memory | 13 | Security Context |
| 2 | Status | 8 | % CPU | 14 | Command Line |
| 3 | Virtual Memory | 9 | CPU Time | 15 | Memory |
| 4 | Resident Memory | 10 | Started | 16 | Waiting Channel |
| 5 | Writable Memory | 11 | Nice | | |

**方案 A（推荐，打包预置配置文件）**：出包时 rootfs 预置 `~/.config/gnome-system-monitor/procman.ini`（gconf XML 格式 `[procman]` 节），对想隐藏的列写 `apps/procman/proctree/col_N_visible=b:false`；启动时 dir 存在 → 恢复 → 隐藏生效。可同时预置 `col_N_width`、`columns_order`（`l:` 前缀 list）、`sort_col/order`。
- 格式样例（实测生成）：`apps/procman/proctree/col_13_visible=b:false`、`col_0_width=i:198`、`columns_order=l:`。
- **坑（dir 存在但 key 缺失）**：`gconf_client_get_bool(key)` 无默认值，key 缺失返回 FALSE → 该列被隐藏。所以预置 ini 需**写全 proctree 全部 17 列（0-16）的 visible**（想显示 true、想隐藏 false），避免未写列被误隐藏；width/sort 可选。

**方案 B（改源码内部默认）**：`proctable.cpp` 建列时对指定列 `set_visible(FALSE)`（或无配置分支隐藏），需重编 gsm，出包即生效、不依赖配置文件。

> 待确认：部署 rootfs 用户 HOME（root 或普通用户）决定 ini 放置路径；dir 存在但 key 缺失时 visible 取 FALSE 的实测。

> ✅ **拍板（2026-11-17）**：两方案（A 预置 procman.ini / B 改源码）**均不采用**，仅知会留档；后续在项目对应 **dotfiles 仓库**做预设配置（按方案 A 思路，预置 procman.ini）。部署 rootfs 用户 HOME（决定 ini 放置路径）届时在 dotfiles 仓库定，本项目不再操作。

#### 1.4、gsm 退出 segfault + 配置不生效（2026-11-18 调研）

> 用户反馈：gsm 退出时报 `segfault core dumped`；**不动配置、打开后直接退出也错**（文档改前就有）；改配置（进程显示列）后每次重启是默认显示内容。

**现象**：
- 关窗（delete-event）退出时 `SIGSEGV`（core dumped）。
- 改"进程显示列"后重启，列回到默认（全列显示），配置似不保存生效。

**根因（gdb 带符号 backtrace 定位，`/_ext/tmp/gsm-dbg`）**：
```
#0  get_meta (p=0x7ffff7f57f40)  ← free 野指针
#1  __libc_free
#2  procman::tree_store_update<char const>
#3  proctable_update_list(ProcData*)
#4  cb_timeout(void*)   ← 定时刷新回调
#5  g_timeout_dispatch → g_main_loop_run → gtk_main → main
```
**A（segfault）**：`cb_timeout`（进程列表定时刷新）在**窗口已销毁后仍被 dispatch**——`cb_app_delete` 先 `save_config`、再 `g_source_remove(timeout)`、`gtk_main_quit`，但主循环退出前最后一次 dispatch 仍触发 `cb_timeout` → `proctable_update_list` → `tree_store_update` 写已销毁的 tree model → `free` 野指针 → SIGSEGV。

**B（配置不生效）**：同源析构时序 bug——`cb_app_delete` 的 `save_config`→`procman_save_tree_state` 遍历列时，**部分 GTK 对象已开始销毁**（日志 `GdkWindow unexpectedly destroyed` + `invalid unclassed pointer in cast to 'GtkTreeView'` + `GTK_IS_TREE_VIEW/TREE_MODEL assertion failed`）→ 列 visible/width 读不到正确值 → ini 写不全 → 重启读默认。
- **读侧正常**（已实证）：预置 ini `col_0_width+col_0_visible=b:false` → 启动 OCR 确认 Process Name 列**隐藏**（`gconf-shim.h` 读链路 OK）。
- **写侧问题**：关窗析构中 save_tree_state 访问已销毁 tree，列未正确写入。

**结论**：A/B 同源 = **GSM 2.28.2 关窗析构时序 bug**（非 tab patch 引入，文档改前既有）。**已修复（2026-11-18）**：`gsm-exit-crash.patch`——ProcData 加 `quitting` 标志；`cb_app_delete` 改为**先置 quitting + 停 timeout/disk_timeout 再 `save_config`**（save 时 widget 稳定，列配置正确写）；`cb_timeout`/`cb_update_disks` 开头 `if (quitting) return`（析构/退出不再刷新，防访问已销毁 tree）。重编产物 18.6M strip `xx-verify`=0；**gdb 带符号复现 3 轮（windowclose/openbox/WM_DELETE）SIGSEGV 均 0**（修复前稳定崩溃于 `cb_timeout`→`tree_store_update` free 野指针）。配置保存（ini 写列）在 Xvnc 测试环境因 WM/IO error 干扰未干净复现，**建议真机复核**（源码逻辑已保证 `cb_app_delete` 走 `save_config` 写 ini）。

##### 1.4.1、修复实现与验证（2026-11-18）

**修复方案**（`compile/src/v-sysmonitor/gsm-exit-crash.patch`，4 文件 5 处）：
| # | 文件 | 改动 |
|---|---|---|
| ① | `src/procman.h` | `ProcData` 加 `gboolean quitting;`（`timeout`/`disk_timeout` 后） |
| ② | `src/procman.cpp` | 构造初始化 `quitting(FALSE)` |
| ③ | `src/callbacks.cpp` | `cb_app_delete` 重排：**先 `quitting=TRUE` + 停 `timeout`/`disk_timeout`，再 `save_config`**，`gtk_main_quit`（原先 save 后停） |
| ④ | `src/callbacks.cpp` | `cb_timeout` 开头 `if (quitting) return FALSE;` |
| ⑤ | `src/disks.cpp` | `cb_update_disks` 开头 `if (quitting) return 0;` |

**原理**：
- A（segfault）：`cb_app_delete` 先停 timeout + `quitting` 标志，退出时 `cb_timeout`/`cb_update_disks` 不再刷新已销毁的 tree/disk_list。
- B（配置不生效）：`save_config` 改在 timeout 停止后执行，此时 widget 稳定，`save_tree_state` 遍历列读到的 visible/width 正确 → 写 ini 完整 → 重启恢复。

**验证**：
- 重编产物 `18.6M static stripped`，`xx-verify --static`=0（builder-g224 `/usr/local/static/gsm/bin/gnome-system-monitor`，11-17/17:24）。
- 反汇编 `cb_timeout` 确认防护编译进：`cmpl $0x0, 0x3100(%rdi)`（quitting 检查）→ `jne` return。
- **gdb 带符号（`/_ext/tmp/gsm-fixed-dbg`，58.7M）复现 3 轮**（xdotool windowclose / openbox WM / python WM_DELETE_WINDOW）**SIGSEGV 均 0**；修复前同场景稳定崩溃于 `cb_timeout`→`proctable_update_list`→`tree_store_update` free 野指针（`get_meta`）。

**配置保存（ini 写列）**：源码逻辑已保证 `cb_app_delete` 走 `save_config` 写 ini（读侧已实证：预置 `col_0_visible=b:false` → OCR 确认列隐藏）；但 **Xvnc 测试环境的 WM/IO error（Fatal IO error 11/22）干扰，未在容器干净复现 ini 写列**——建议**真机复核**（改列→关窗→重启，确认列显示恢复）。若仍不生效，再深挖写侧（`procman_save_tree_state` 遍历列与 gconf-shim list 读写一致性）。

**提交**：`78571b9a`（patch）/ `5383ef1e`（build.sh 接入）/ `d1bdd17c`（本文档结论更新）。

#### 1.5、undecorate 后退出 segfault——gconf-shim 释放器不匹配（2026-11-18 落档）

**现象**：openbox 执行 `undecorate` 后 gsm 退出时报 `SIGSEGV`（core dumped），rc=139。与 1.4 的关窗 segfault **不同源**——本项仅在 undecorate 场景触发（SmoothRefresh 析构路径），1.4 已修复后仍存在。

**根因（gdb 带符号反汇编 + 内存 dump 实证，`/_ext/tmp/gsm-new-dbg`）**：
```
#0  get_meta (p=0x7ffff7f12cb0)
#1  __libc_free
#2  gconf_client_notify_remove   ← gconf-shim 里 g_free(it)
#3  SmoothRefresh::~SmoothRefresh
```
- `SmoothRefresh::~SmoothRefresh` → `gconf_client_notify_remove(client, connection)` 释放 notify 链表节点 `it`。
- **`g_free(it)` 用 musl free 释放了由 `g_slist_append` 分配的 GSList 节点**——该节点来自 **glib `g_slice` 分配器**（16 字节 slab 紧密打包），musl free 把 g_slice slab 对象当 mallocng chunk → `get_meta` 读 p-8..p-1（实为前一节点 `next=0`）→ `assert(meta->mem==base)` 失败（`hlt`）→ SIGSEGV。
- **判据**：
  - 崩溃地址确定性（`0x7ffff7f12cb0` 两次构建相同）——堆布局确定。
  - gdb 断 `g_free if $rdi==<崩溃地址>` 证明该节点**从未被提前 free**（唯一 free 在 notify_remove 内）→ 非 use-after-free，是**分配器不匹配**。
  - 内存 dump：节点 **16 字节紧密打包**（g_slice slab 特征，非 musl class-1 的 32 字节间隔）。
  - `get_meta` 反汇编：崩溃于 `assert(meta->mem==base)`，offset=0/index=0（p-8..p-1 被前一节点 next 覆盖清零）。

**修复**（`compile/src/v-sysmonitor/gsm-gconf-keyfile.patch`，4 处）：
| # | 位置 | 改动 |
|---|---|---|
| ① | `notify_remove` | **主修复**：`g_free(it)` → **`g_slist_free1(it)`**（g_slice 正确释放） |
| ② | `notify_add` | 同 key 二次 add 不再 `g_hash_table_insert` 覆盖（否则 value_destroy 释放旧节点、链表留悬挂指针）→ 改 `g_slist_append` 就地扩展 / 首次才 insert |
| ③ | `get_default` values | value_destroy 回退 `gconf_shim_free_value`（曾误改 `gconf_shim_notify_list_free`——会把 GConfValue 当 GSList 释放） |
| ④ | `get_default` notify | value_destroy `g_slist_free` → `gconf_shim_notify_list_free`（补 GConfNotify 节点泄漏） |

**验证**：
- 重编产物 `18.6M static stripped`，`xx-verify --static`=0（builder-g224 `/usr/local/static/gsm/bin/gnome-system-monitor`，11-18/03:03）。
- **Xvnc(:323/:324)+openbox 实跑 2 轮**（`wmunde.py undecorate` → `wmclose.py WM_DELETE_WINDOW`）：**gsm 退出 rc=0 干净退出**；修复前同场景 rc=139 SIGSEGV。
- patch 干净应用到原始 gsm 源码（`git apply` OK），4 处修复全部落地。
- gconf-shim 全量 `g_free`/`g_slist_free` 审计：所有 `g_free` 均作用于 `g_malloc`/`g_strdup`/`g_new0` 对象，GSList 节点全走 `g_slist_free`/`g_slist_free1`，无剩余不匹配。

**提交**：`3970b5aa`。

> 教训：**glib 容器对象（GSList/GList/GHashTable 节点、g_slice 分配）必须用对应 `g_*_free` 释放，勿用 `g_free`**；`g_free` 仅用于 `g_malloc`/`g_strdup`/`g_new0` 对象。

#### 1.6、关窗保存配置不生效 + 关闭报错——WM 直接销毁 toplevel，`delete_event` 根本不触发（2026-11-18 落档）

**背景/现象**：在 hdmi 容器（Xvnc+openbox）实跑 gsm 2.28.2（新基准镜像 `alpine-builder-gtkmm224-2` 构建，见五章 1），**改窗口大小/切 tab 后点 WM 关闭按钮重开，配置不生效**（重开仍是默认 532x437、回 Processes tab）；且关闭时日志报 `GdkWindow ... unexpectedly destroyed` + X `BadWindow`，进程 `exit(1)`。用户拍板「拿最新代码构建跑的、已确认复现」→ 进入本次根因排查。

**关键判据（builder 容器内插桩 `fprintf` 实跑 2 轮，Xvnc:437+openbox）**：

| 路径 | `[DBG] cb_app_delete` | `[DBG] save_config` | `procman.ini` 关键键 | 退出码 |
|---|---|---|---|---|
| WM 关闭（`xdotool windowclose`） | **未打印** | **未打印** | 无 `width`/`height`/`current_tab`（只有列宽 46 键） | **rc=1** |
| ctrl+q（程序内 Quit 菜单） | 打印 | 打印 | `width=1024/height=700/current_tab=0` ✓ | rc=0 |

**根因**：gsm 只把 `cb_app_delete` 连到 `delete_event`（`interface.cpp`）。openbox 点关闭按钮走 **`XDestroyWindow` 直接销毁 toplevel**，`delete_event` 信号**根本不发** → `cb_app_delete`/`procman_save_config` 从不执行 → ini 缺 `width/height/current_tab`（1.4 的修复只保住了 ctrl+q/Quit 菜单路径）。同时销毁后 GTK 仍跑刷新回调（`cb_timeout` 等）访问已销毁 widget → X 报 `BadWindow`（request_code 2 minor 0 = `CreateWindow` 以已销毁窗口为父）→ gdk 默认错误处理 `exit(1)` = 「关闭有错」。

**第一版方案（已废弃）**：把 `destroy` 也连到 `cb_app_delete`。实测 `rc=139` SIGSEGV，插桩显示 `procdata->app` 读到垃圾 `0x5f6d75736b636568` → **destroy 信号触发时 `ProcData` 已被 `procman_free_data` 释放**（use-after-free），`cb_app_delete` 再解引用 `procdata` 即崩。**结论：destroy 路径下不可解引用 procdata。**

**定稿方案（`compile/src/v-sysmonitor/gsm-exit-crash.patch` 追加，4 处改动）**：

| # | 文件 | 改动 |
|---|---|---|
| ① | `callbacks.cpp` | 新增**全局标志** `gboolean gsm_procman_quitting`（定义）+ `cb_app_configure`（`configure-event` 里 `gconf_client_set_int` 实时写 `width/height`，窗口尺寸不依赖退出路径即落盘）+ `gsm_procman_app_destroyed`（只置全局标志 + `gtk_main_quit`，**不解引用 procdata**） |
| ② | `callbacks.cpp` | `cb_change_current_page` 切 tab 时立即 `gconf_client_set_int current_tab`（原来只在退出时写） |
| ③ | `interface.cpp` | 主窗口 `app` 连 `configure-event → cb_app_configure`（带 procdata，窗口存活期安全）＋ `destroy → gsm_procman_app_destroyed`（**user_data=NULL**，不碰 procdata） |
| ④ | `callbacks.cpp`/`disks.cpp` | `cb_timeout`/`cb_update_disks` 防护改为**先查 `gsm_procman_quitting` 再查 `procdata->quitting`**（destroy 时 procdata 可能已释放，必须先用全局标志短路）；`procman.h` 加 `extern gboolean gsm_procman_quitting;`，`callbacks.h` 加两个新函数声明 |

**patch 文件格式 4 类坑（本次踩完，已全修）**：

| # | 坑 | 修法 |
|---|---|---|
| ① | hunk header 行号/计数与实际 body 不符（手写 hunk，`patch` 报 `malformed patch`、`git apply` 报 `corrupt patch`） | 逐 hunk 数清 context/add/del 行，改 header `-old,+new` 与 body 严格一致 |
| ② | hunk header **缺尾部 `@@`**（`git-diff` 生成的有，手写的没有 → `git apply` 直接 corrupt） | 每行 `@@ -a,b +c,d @@` 补尾 `@@` |
| ③ | 空上下文行写成真空行（须为**单个空格**，否则 `patch` 判 malformed） | 全局把 hunk 内空行转 `' '` |
| ④ | patch 文件末行缺换行 / 末尾多余空格 | `rstrip()+'\n'` 收口 |

**当前状态（2026-11-18 复核）**：新 patch 已在 builder 内 pristine 重建（`/tmp/gsm-src.tar.bz2` 解包 → 正序 `git apply` 4 个 patch：gconf-keyfile、disk-icon、tab-order、exit-crash，顺序应用全通过、`rej=0`）→ fresh 构建 `BUILD_RC=0`/`VERIFY_RC=0`，产物 18.68MB 静态 → 部署 hdmi。**Xvnc:440+openbox 实跑 3 轮验收**：`windowclose` 均 clean exit（109/111/108ms，无 segfault/GPF）；RUN1 **运行中** ini 已实时落盘 `width=1024/height=700/current_tab=1`（configure-event 实时写 + 切 tab 立即写），关闭后保留。仅存 `GdkWindow ... unexpectedly destroyed` 良性警告。**「关闭无错误 / 保存配置生效」两项验收已过。**

**遗留（独立问题，不在本 patch 范围）**：重开恢复尺寸不生效——gsm 确实读回（`procman.cpp:256-257` 读 width/height、`interface.cpp:633` `set_default_size`），但 `config.width` 读回 0/默认 → 指向 **gconf-shim 读路径返回 0**（写正常、读异常），大概率既有 bug，非 exit-crash 修复引入。**tab 恢复被刻意禁用**（`procman.cpp:302-303`，2026-11-17 的 gsm-tab-order.patch 强制 Processes 不记忆 last tab——已有设计决策）。两问题单列跟进。

**待办**：① 提交 `gsm-exit-crash.patch` + `gsm-gconf-keyfile.patch` + docs 1.6（单文件单 commit，信息以文件路径开头）；② 更新 AGENTS.md 五章 1 基准镜像名（gtk224-2→gtkmm224-2）；③ 重开恢复尺寸（shim 读路径）单独排查。

#### 1.7、重开恢复尺寸根因与修复——gconf-shim 读路径从未装载 ini（2026-11-18 落档）

**根因**：`fee2f850` 之前，`gconf_shim_load()`（`gconf-shim.cpp`）**从未调用 `g_key_file_load_from_file()`** 把 ini 内容装载进 `GKeyFile` → `values` 哈希**恒空** → `gconf_shim_get_int()` 恒返回 0 → 重开时 `config.width/height` 读回 0 → 回退默认 532x437；且 1.6 方案 ① 的 `configure-event` 实时写会在窗口创建后立刻把默认尺寸写回，覆盖已保存值。**写路径正常、读路径异常**（与 1.6 节遗留判断一致）。

**修复**（`compile/src/v-sysmonitor/gsm-gconf-keyfile.patch` 第三版，commit `fee2f850`）：`gconf_shim_load()` 补一行 `g_key_file_load_from_file()` 装载 ini；同时修 hunk header 行数（595→598，防 `endif` 截断）。干净构建 `xx-verify=0`；hdmi Xvnc:440 复验 RUN2/RUN3 重开恢复 **1024x700**。

**rootfs-dbg 实测（用户实际验证环境，2026-11-18 补完）**：

| 轮 | 操作 | 窗口尺寸 | ini 关键键（关闭后） | 退出 |
|---|---|---|---|---|
| RUN1 | 清 ini 启动 → resize 1024x700 → windowclose | 534x435（默认）→ 1024x700 | `width=1024/height=700/current_tab=0` | 干净 |
| RUN2 | 重开（期望恢复保存尺寸） | **1020x700**（内容区，fluxbox 边框 -4px） | `width=1020/height=700/current_tab=0` | 干净 |
| RUN3 | 再开稳定复核 | **1020x700** | `width=1020/height=700/current_tab=0` | 干净 |

- 3 轮均 `windowclose` **干净退出**（无 alive 回退、无 `CRITICAL`/`ERROR`/`Trace`；仅良性 `GdkWindow ... unexpectedly destroyed` 警告，与 hdmi 一致）。
- **结论**：写路径（resize 实时落盘 1024x700）+ 读路径（重开恢复 1020x700，非默认 532x437）**均生效**，配置持久化问题闭环。
- 环境：rootfs-dbg 容器默认桌面（Xvnc `:10` depth16 + fluxbox + tint2，headless 用户）；窗口查找用 `xdotool search --classname "gnome-system-monitor"` 返回 2 窗口（1 个 10x10 内部辅助 + 1 个真主窗口），按面积取最大选中真主窗口。容器运行环境/访问方式详见 memory `container-env.md`。

**用户问答补记（2026-11-18，两轮问答原文/答复保存）**：

**问 1**：先前不行的具体原因是啥？你修复了一些啥，都推送了吗？
**答 1**：根因见上（`gconf_shim_load` 从未 `g_key_file_load_from_file` → `values` 恒空 → `get_int` 恒 0 → 重开回退默认 532x437 + `configure-event` 覆盖保存值）。修复 4 个核心 commit：`db5e340b`（exit-crash：WM `XDestroyWindow` 不触发 `delete_event` → 保存不执行 + 刷新回调访问已销毁 widget → `BadWindow exit(1)`；改全局 `gsm_procman_quitting` 标志 + destroy 只置标志 + `configure-event` 实时写 width/height + 切 tab 立即写 current_tab）、`24ce2fab`（gconf shim 跨 TU 单例 + dirty/autosave + `procman_save_config` 加固）、`fee2f850`（读路径：补 `load_from_file` + 修 hunk 行数）、`641ee424`/`3e359326`（docs 1.6/1.7）。全部已推送（HEAD=`3e359326`=`origin/feat/ai-260925`，工作树干净）。

**问 2**：配置项改动之后关掉再打开，配置没生效还是程序默认，这一块修好了吗？
**答 2**：修好了，正是 `fee2f850` 修的读路径 bug（写正常、读异常）。rootfs-dbg 实测：RUN1 清 ini → resize 1024x700 → 关闭存 `width=1024/height=700`；RUN2 重开恢复 **1020x700**（非默认 532x437）；RUN3 一致；hdmi 同样恢复 1024x700。边界说明：**tab 恢复刻意禁用**（`gsm-tab-order.patch` 强制回 Processes tab，非 bug），窗口尺寸/列宽正常恢复。

#### 1.8、进程列表列配置（列显隐/列顺序）关开恢复默认——根因与修复（2026-11-18 落档）

> 本节 = 用户实际验证环境反馈「进程列表列配置（关列显示/拖列排序）关掉重开恢复默认」的排查结论与修复。**此前 1.6/1.7 只验了窗口尺寸，未覆盖列配置——验证项没对准用户真实需求。**

**根因（插桩铁证，非理论）**：列配置存在 `/apps/procman/proctree/*`（`columns_order`/`col_N_width`/`col_N_visible`/`sort_col`/`sort_order`），读写走 `procman_get_tree_state`/`procman_save_tree_state`。**两个独立 bug**：

| # | 现象 | 根因 |
|---|---|---|
| ① | **列顺序**重开回默认 | `cb_columns_changed`（columns-changed 信号→`save_tree_state`）在**窗口关闭销毁期间连发**（列逐个拆除）。插桩实测 `get_columns_order count` **16→15→…→0**，最后一次把**空 `columns_order=l:`** 写入，**覆盖掉正常会话已存好的顺序**。同 bug 在 disk 树（`cb_disk_columns_changed`）。 |
| ② | **列显隐**重开回默认 | `field_toggled`（Preferences 勾选框）只 `gtk_tree_view_column_set_visible`，**不触发 columns-changed**（GTK2 `set_visible` 不发信号）→ **从不写盘**。 |

**修复**（`compile/src/v-sysmonitor/gsm-column-persist.patch`）：
1. `cb_columns_changed`/`cb_disk_columns_changed` 加 `if (gsm_procman_quitting) return;` 守卫（同 exit-crash 模式）——修列顺序。
2. `field_toggled` 在 `set_visible` 后**手动 `g_signal_emit_by_name(gtk_tree_view_column_get_tree_view(column), "columns-changed")`** 走既有 `save_tree_state`——修列显隐。

**验证（rootfs-dbg Xvnc:10 种子测试，runtime 证据）**：
- **修复前**：种子 `columns_order=l:2,0,8,1,3,4,5,6,7,9,10,11,12,13,14,15,16` 关闭后变 **`l:` 空**（DBG 显示 destroy 期间连发 count 递减到 0）。
- **修复后**：`columns_order` **完整保留**、`col_0_visible=b:false` **保留**；DBG 为空（destroy 不再触发）；**二次开关循环仍稳定**；无 `CRITICAL`/`ERROR`。
- 干净构建 `BUILD_RC=0`；pristine `git apply` 5 个 patch（含新 patch）顺序全过。

**诚实说明**：列顺序/显隐的**持久化机制**（种子非默认配置 → 关 → 开 → 保留）已 runtime 实测。Preferences 勾选 GUI 路径（修复 ②）是**复用同一条已验证的 `save_tree_state`**（`set_visible` 后发信号触发它）；GUI 自动化点勾选框在 headless 环境不可靠，未单独 GUI 点测。

**提交**：`gsm-column-persist.patch`（单独 commit）+ `build.sh` 应用（单独 commit）→ 已推送 `e09644ae..e40a6b26`，HEAD=`e40a6b26`。

**插桩/调试坑**：容器内 `python3 -c` 经 bash 双重引号 `\\n` 变真实换行（字符串跨行非法 C）→ 写脚本文件避免转义地狱；`pkill -f`/`pgrep -f` 匹配串出现在脚本文本会**自匹配杀外层 bash**（AGENTS 已知坑）→ 用 `pkill -x <comm>` 或按 PID。


#### 1.9、用户问答补记——「为什么静态化后问题这么多 / 2.28.2 历史版本固有缺陷吗 / 动态版是不是没事」（2026-11-18 落档）

> 本节保存用户两问的**完整答复原文（含表格）**。结论要点：**配置类 bug = 静态化引入（gconf-shim，已修）；关窗报错/不保存 = 2.28 原版设计局限（`delete_event` 未处理 WM 直接 destroy），静态构建放大；hdmi ubt22 是 3.28.x（gsettings）≠ 2.28.2（gconf），不能当「2.28.2 动态版正常」的证据。**

**问 1**：gsm 2.28.2 是历史版本固有缺陷吗？非静态版包是否同样有问题？
**答 1**：要分两类看——

| 问题现象 | 是不是 2.28.2 历史版本固有缺陷 | 说明 |
|---|---|---|
| 配置保存无效（读不回来 / 关开回默认） | **不是**——是静态化引入的 bug | 原版 gsm 2.28.2 走 **gconfd**（D-Bus 守护进程，存 `~/.gconf/*.xml`）；静态库**无法提供守护进程** → 手写 **gconf-shim**（`gconf-shim.h/cpp`，GKeyFile 存 `procman.ini`）替代，配置读写**全在 shim 层**。本次修的 3 个 bug（exit-crash `db5e340b`、读路径 `fee2f850`、列配置 `e40a6b26`）**全在 shim/回调层**，非上游原版代码缺陷。 |
| 关闭报错 / 关闭时配置不保存 | **部分是原版设计局限** | 2.28 时代原版只在 `delete_event` 存配置，且刷新回调不防 destroy（WM 直接 `XDestroyWindow` 时 `delete_event` 根本不触发）——这是 **2.28 时代原版设计局限**，**非静态包也可能有**，但静态构建（gconf-shim + 无窗口管理器干预兜底）**放大**。 |

> **诚实声明**：**未在别发行版实测 2.28.2 非静态包**。上述「非静态包也可能有」基于**机制推断**（原版依赖 gconfd / `delete_event` 的设计），**非实测**。

**问 2**：动态版是不是没事、只是静态化影响大？hdmi ubt22 环境列配置正常，不是证据吗？
**答 2**：**hdmi ubt22 那个 gsm 是 3.28.x（gsettings，非 gconf）**，与 2.28.2（gconf）**不同代**，不能直接证明「2.28.2 动态版正常」。

| 问题 | 静态版（本项目 2.28.2） | 动态版（hdmi ubt22 3.28.x） | 结论 |
|---|---|---|---|
| 配置保存/读取 | 有 bug（shim 层，已修） | 正常（gsettings 原生支持） | **配置问题确实是静态化引入**（gconfd 缺失 → shim bug）；与 2.28.2 原版无关。 |
| 关窗报错 / 不保存 | 有（原版设计局限 + 静态放大） | 3.x 已改 `delete_event`/gsettings 处理 | **关窗问题原版 2.28 就有设计局限**（非静态包也可能有）；静态构建放大，非 3.x 可比。 |

**一句话总结**：**配置类 bug = 静态化引入（gconf-shim，已修）；关窗报错/不保存 = 2.28 原版设计局限（`delete_event` 未处理 WM 直接 destroy），静态构建放大——不能拿 hdmi 3.28.x 动态版证明「2.28.2 动态版正常」；且未实测 2.28.2 非静态包，上述基于机制推断。**

#### 1.10、gsm 最新支持 GTK2 版本评估（2026-11-23）

**结论**：gsm 最新支持 GTK2（gtkmm-2.4）的稳定版本 = **2.28.2**（项目当前版本，**无更高可升**）。

**实测**（download.gnome.org 各版本 configure 依赖）：

| 版本 | 关键依赖 | GTK 世代 |
|---|---|---|
| 2.28.2（项目当前，2.x 最后稳定） | `gtk+-2.0` + `gtkmm-2.4` + `libwnck-1.0` + `gconf-2.0` + `dbus-glib-1` | **GTK2 / gtkmm-2.4** |
| 2.99.0–2.99.3（GNOME 3 过渡开发版） | `gtk+-3.0` + `gtkmm-3.0` + `libwnck-3.0` | GTK3 |
| 3.0.0 起 | `gtk+-3.0` + `gtkmm-3.0` | GTK3 |

**要点**：

- 2.x 系列（最后 2.28.2）全用 GTK2/gtkmm-2.4；**2.99.x 起一次性迁 GTK3**（`configure.ac` 已确认 2.99.3 为 `gtkmm-3.0`）。
- 中间**不存在**更高的 GTK2 版本——2.28.2 之后直接跳 GTK3，项目当前 `2.28.2` 已是**最后/最高支持 GTK2 的稳定版**。
- 类似 geany 的 1.37.1（最后支持 GTK2）：gsm **无需升级**（已是最新 GTK2 版），后续 GTK3 版本（3.0+/40+）项目用不上。

### 2、dbus/dunst 静态版在 headless 会话的使用（2026-11-17 分析）

#### 2.1、使用链路与结论

##### 2.1.1、使用链路（headless 用户会话）

```
Xvnc（rootfs-dbg 自带，完整桌面）→ DISPLAY=:N
  └─ dbus-daemon --session --nofork --address=unix:abstract=/tmp/dbus-uid<uid>   ← 用户会话总线（唯一 owner，保活）
        └─ dunst（D-Bus 按需激活，见 2.1.2）→ 注册 org.freedesktop.Notifications → 接收显示
              └─ scrot 截图脚本 → 发送端（notify-send/dbus-send）→ 同一 session bus → dunst 显示
```

通知**必须走用户会话总线**（`org.freedesktop.Notifications` 在 session bus），不是系统总线。

**两条总线（b17 链路）**：

| | **系统总线 (system)** | **会话总线 (session)** |
|---|---|---|
| 数量 | 全容器一条，root 起，perp 盯 | 每用户一条，谁起谁管 |
| 地址 | 写死 `unix:path=/var/run/dbus/system_bus_socket` | 固定 `unix:abstract=/tmp/dbus-uid<uid>`（perp 起） |
| 谁能连 | 任何人零配置（socket 0777） | 必须知道地址（env 或猜常量） |
| 管什么 | 全机共享服务 | 一个桌面会话内互认（通知、mpris、ibus） |

##### 2.1.2、dunst 启动与注册——D-Bus 按需激活（a1 纠正）

- **dunst 不用提前常驻**：D-Bus **激活**机制。dunst 源码自带 `org.knopwob.dunst.service.in`（内容 `[D-BUS Service] Name=org.freedesktop.Notifications / Exec=@bindir@/dunst`）；`make install` 经 `config.mk:13 SERVICEDIR_DBUS=${DATADIR}/dbus-1/services`（随 PREFIX）装到 **`$TARGETPATH/share/dbus-1/services/org.knopwob.dunst.service`** → 静态产物**自带激活 service**。
- **机制**：客户端发 `Notify` 到 `org.freedesktop.Notifications` → D-Bus 见该名无 owner → 按 service 的 `Exec=dunst` 自动拉起 dunst → dunst 运行时自动 RequestName 接管并显示。**有通知时才触发**。
- **静态版不需要手动注册**：D-Bus 激活文件 + dunst 运行时自动注册（走 GDBus，glib/gio 内置，不链 libdbus-1，`x-dunst/build.sh:12`）。需前提：① 产物 `share/dbus-1/services/` 放到运行环境 session 总线激活目录（`/usr/share/dbus-1/services/` 或 `XDG_DATA_DIRS` 下 `dbus-1/services/`）；② 用户会话总线已起 + `DBUS_SESSION_BUS_ADDRESS` 指向。
- **对照 hdmi**：那边 dunst 是系统包（`Dockerfile.app-debian:35` apt install dunst），自带同款 service → 同样按需激活，与 a1 描述吻合。

##### 2.1.3、rootfs-dbg 调试验证（a2 纠正）

- **rootfs-dbg 无参启动 = 完整桌面**：`entry.sh:175` `START_SESSION` 默认 `startfluxbox`，可 `-e START_SESSION=openbox-session` 指定；**自带 Xvnc**（rootfs 有 VNC 支持：`entry.sh:3-16` VNC_OFFSET/PORT_VNC 等）。历史命令参考：`docs/core/dropbear.md:79` 类 `-e START_SESSION2=openbox-session`。
- **注意**：rootfs `entry.sh` dbus 相关全注释（L141-150），**默认不自动起 dbus 总线** → 验证需手动/脚本起。
- **验证步骤（rootfs-dbg 内，静态产物）**：
  1. 起用户会话总线：`DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-uid$(id -u) /usr/local/static/dbus/bin/dbus-daemon --session --nosyslog --nofork --address=unix:abstract=/tmp/dbus-uid$(id -u) &`（唯一 owner，勿双起）。
  2. 部署 dunst 激活 service：`cp /usr/local/static/dunst/share/dbus-1/services/org.knopwob.dunst.service /usr/share/dbus-1/services/`。
  3. 发通知：`DBUS_SESSION_BUS_ADDRESS=<addr> notify-send 标题 正文`（或 dbus-send Notify）→ D-Bus 自动拉起 dunst → 显示。
  4. scrot 截图包装脚本：`scrot /tmp/x.png && notify-send 截图 /tmp/x.png`。

##### 2.1.4、hdmi 双线改造参考（b17 照搬）

`docker-hdmi-desktop/docs/b17-261026-dbus-sys-user-session.md`（那边 dbus 动态）链路逻辑适用静态版：

| b17 结论 | 静态版照搬 |
|---|---|
| 两条总线：系统（root，/var/run/dbus/system_bus_socket，0777）+ 用户会话（headless，固定 abstract） | ✅ 同；通知只走 session，系统总线非必需 |
| 用户会话总线唯一 owner + 保活（--nofork，perp）；ensure-* 删（否则再 spawn→bind 失败→perp 自转） | ✅ 同：dbus-daemon --session --nofork --address=<固定> |
| 地址注入：perp 服务命令（envcmd 覆盖桌面子树）+ /etc/profile.d/99dbus-session.sh 一行 export；不塞 ~/.bashrc | ✅ 同：export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:abstract=/tmp/dbus-uid$(id -u)}" |
| 通知（org.freedesktop.Notifications）/mpris 走 session bus | ✅ 同：dunst 连 session bus |

##### 2.1.5、产物缺口与提醒

- **无通知发送端**：静态产物**没有 notify-send/dbus-send/dunstctl**——x-dbus 只出 dbus-daemon+libdbus；x-dunst `DUNSTIFY=0`（dunstify 需 libnotify，不在静态栈，`x-dunst/build.sh:88`）只出 dunst。发通知需补：静态化 libnotify 的 notify-send，或 x-dbus 补 dbus-send，或用 libdbus-1.a 编小发送器。
- **dunst 通知图标可能空白**（`x-dunst/build.sh` 注释：gdk-pixbuf PNG/JPEG loader 静态下 dlopen，AGENTS「gdk-pixbuf 图标坑」）——文本可显示，图标需静态链 loader 或自解码。

**一句话**：链路 = 用户会话 dbus-daemon（唯一 owner，perp 保活）→ dunst（D-Bus 按需激活，产物自带 org.knopwob.dunst.service）→ scrot 脚本经发送端发 Notify；dunst 不用提前常驻，静态版无需手动注册（激活文件+自动 RequestName）；rootfs-dbg 无参=完整桌面+Xvnc（START_SESSION 可选）；缺通知发送端需补。

##### 2.1.6、通知发送端静态化可行性（2026-11-17 分析）

> 承接 2.1.5「缺通知发送端」：分析 dbus-send / notify-send / dunstify 三条静态化路径与成本，给出推荐。

**先订正 2.1.5 的一条**：静态产物**其实有 dunstctl**——但它**不是编译产物，是 shell 脚本**（上游 tarball 直接带 `dunstctl` 文件，非 dunstctl.c 编译），已装到 `/usr/local/static/dunst/bin/dunstctl`（8.7K，`file`=POSIX shell script）。它是**控制工具**（close/close-all/history/Ping），**不是通知发送端**；且**运行期硬依赖 dbus-send**（脚本内 `command -v dbus-send || die "Command dbus-send not found"`）→ 无 dbus-send 时 dunstctl 直接报错。所以 2.1.5 说的「没有 dunstctl」严格说是**没有可用的 dunstctl**（缺 dbus-send 它跑不了），且它本来也发不了新通知。

**发送端三条路径（静态化可行性）**：

| 路径 | 依赖 | 静态化成本 | 说明 |
|---|---|---|---|
| **dbus-send**（推荐） | 无新增——dbus 自带工具 | **低** | `tools/dbus-send.c` + `dbus-print-message.c` + `tool-common.c` 三对象 + `libdbus-1.a` + `-lexpat -lpthread -ldl -lm`；`tools/Makefile` 里 `dbus_send_DEPENDENCIES = libdbus-1.la`，只链 libdbus-1。在 `x-dbus/build.sh` 追加（dbus 源码已就位）。**一石二鸟**：既能发 `Notify`，又解锁 dunstctl（其运行期要 dbus-send） |
| **notify-send** | 需 **libnotify**（新组件，静态栈没有） | 中 | libnotify 走 GDBus（gio，静态栈有）或 libdbus（x-dbus 有），`--enable-static` 可行；需新增组件（如 `w-notify`/`v-notify`）+ 下载 libnotify 源码 |
| **dunstify** | 需 **libnotify**（`Makefile:30-31` pkg-config libnotify） | 中 | dunst 自家发送工具（dunstify.c）；与 notify-send 同依赖——建了 libnotify 可顺手把 `DUNSTIFY=0` 改 `1` 一并出 |

**结论**：**先补 dbus-send**（成本最低，解锁 dunstctl + 能发 Notify，`x-dbus/build.sh` 一条手工链即可）；notify-send/dunstify 视需要再建 libnotify（新组件，成本中，非当务之急）。

> ⚠️ **订正（2026-11-17，实跑证伪）**：dbus-send **不能发通知**——`Notify` 的 hints 参数是 `a{sv}`（string→variant 字典），而 dbus-send 1.12.26 的 `type_from_name()` **只认基础类型（string/int*/uint*/double/byte/boolean/objpath），不认 `variant`**（`tools/dbus-send.c` 源码实证）→ `dict:string:variant:` 直接 `Unknown type "variant"` 报错。所以 dbus-send **只能做 dunstctl 的控制命令**（close/close-all/history/Ping/GetServerInformation 全走 string/uint，无 a{sv}），**发通知必须 notify-send（libnotify）或 dunstify（libnotify）**。结论修订：**dbus-send 已建可用（dunstctl 用），通知发送端 = notify-send（libnotify，真正该优先的）**。
>
> **dbus-send 实跑验证（2026-11-17）**：`x-dbus/build.sh` 加 `dbus_send()` 手工链成功，产物 `/usr/local/static/dbus/bin/dbus-send`（306K）`file`=statically linked/stripped、`xx-verify --static`=0、`ldd`=Not a valid dynamic program、`--help` 可跑；在 hdmi 容器经 `DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-uid1000` 以 **uid1000（headless）** 连 session bus `ListNames` 成功（root 连被拒，session bus 属 uid1000）。

##### 2.1.7、dunst 通知图标 loader 方案（订正 2.1.5「可能空白」）

> 承接 2.1.5「dunst 通知图标可能空白」：实查静态 gdk-pixbuf 栈后**订正**——不再空白，方案已就位，无需再补 loader。

**订正结论**：dunst 图标**不再必空白**——u-gtk 已把 gdk-pixbuf 2.42.8 的 **png/jpeg/svg 设为 builtin loader**（`u-gtk/build.sh:88` `-Dbuiltin_loaders=png,jpeg,svg`，`--default-library=static` 只出 .a），静态 `libgdk_pixbuf-2.0.a`（`/usr/lib/`，1.1M）**内含 `io-png.c.o / io-jpeg.c.o / io-svg.c.o`**（2026-11-17 `ar t` 自证）。dunst 经 `pkg-config --static --libs gdk-pixbuf-2.0` 链这个 .a（libdir=`/usr/lib`）→ **PNG/SVG 图标加载 OK**。2.1.5 的「可能空白」基于旧 dlopen loader 模型（`-rdynamic` 缺失），**已被 builtin loader 方案取代**。

**dunst 图标取用路径**（`src/icon.c`）：`get_pixbuf_from_file()` → `gdk_pixbuf_get_file_info()` + `gdk_pixbuf_new_from_file_at_scale()`，只需 loader 已注册（builtin 注册于 `gdk_pixbuf_get_type` 的 `gdk_pixbuf_io_init_builtin()`，u-gtk patch 注入）+ 图标文件存在。

**运行期前提**：
- **按名字查图标（`icon_name`）**：还需**图标主题**目录（`index.theme` + PNG/SVG 位图，如 Papirus/hicolor）在 `XDG_DATA_DIRS`/`~/.local/share/icons` 路径上（hdmi 容器有 Papirus/Adwaita/Yaru 等，实查）。
- **按文件路径（`file://` 或绝对路径）**：只需 loader（builtin 已就位），无需主题。

**结论**：静态 loader 方案 = **沿用 u-gtk builtin loader（已就位）**，无需再补 `libstaticpixbufloader-*.a` 或自解码（AGENTS「gdk-pixbuf 图标坑」针对旧模型）；只需运行时提供图标主题目录（部署项，非构建项）。

### 2.2、实现验证篇

#### 2.2.1、通知发送端 notify-send 实现（x-dunst 内构建，GDBus 直发，2026-11-17 落档）

> 承接 2.1.6 订正（通知发送端 = notify-send）：实现并验证——**不是 libnotify，是 x-dunst 内最小 GDBus 直发**（`notify_send()` 方法块，同目录部署，见 2.2.3 结构调整）。
>
> **澄清（2026-11-17）**：notify-send 是**独立程序**，只走 D-Bus 发 `Notify`，**不与 dunst 耦合**（不链 dunst 任何库）；dunst 本身**无 GTK 依赖**——它链的是 **gdk-pixbuf**（GTK 家族中独立的图像加载库，非 GTK 组件库），见 2.2.2 图标依赖链分析。

**为什么不用 libnotify（notify-send 官方工具）**：libnotify 0.8.9 **硬依赖 `gio-unix-2.0.a`**（`libnotify/meson.build` `dependency('gio-unix-2.0')`），而静态栈**缺该 .a**（`find / -name libgio-unix-2.0.a` 无果；glib 源码不在，无从补编）；且 libnotify 主库是 `shared_library`（meson 需 patch 成 static，成本高）。**GDBus 直发只需 gio+glib**（dunst 已证可静态链），且 GDBus **原生能编 `a{sv}`**（dbus-send 不能，见 2.1.6 订正）→ 选最小 GDBus 直发。

**实现**（`compile/src/x-dunst/`，`notify_send()` 方法块 + `notify-send.c`）：
- `notify-send.c`：直连 session bus，`g_dbus_connection_call_sync` 发 `org.freedesktop.Notifications.Notify`，签名 `(susssasa{sv}i)`——用 `GVariantBuilder` 显式构造（空 `as` + `a{sv}`（可带 urgency hint））；支持 `-a/-i/-t/-u` 选项。
- `build.sh`：`xx-clang -static` + `pkg-config --static --libs gio-2.0 glib-2.0 gobject-2.0`（含 gmodule/pcre/ffi/mount/blkid，`-L/lib` 取 `libz.a`），`--start-group` 解静态循环依赖；产物 `bin/notify-send`。
- **坑**：`g_variant_new` 直接传 `&hints`/`g_variant_new_strv(NULL,0)` 会 `g_variant_builder_end` 断言（空容器），改 `GVariantBuilder` 显式构造；`call_sync` **sink 掉 params 浮引**，**勿再 `g_variant_unref(params)`**（否则 `g_atomic_ref_count_dec` 断言）。

**验证（2026-11-17）**：
- 产物 `bin/notify-send` 3.3M，`file`=statically linked/stripped、`xx-verify --static`=0、`--help` 可跑。
- hdmi 实跑（uid1000/headless，`DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-uid1000`）：`notify-send -a test-static -u critical "..." "..."` → **bus 收到 Notify 并触发 dunst 激活**（报 `Spawn.ChildExited: Process org.freedesktop.Notifications exited with status 1` = dunst 在该测试上下文起不来（多会话/环境），**非 notify-send bug**——消息构造与 a{sv} 正确）。

**结论**：通知发送端 = **notify-send（x-dunst notify_send 最小 GDBus 直发）**，已建可用；dbus-send 只做 dunstctl 控制。两组件（dbus-send/notify-send）**均可静态编译**，**优先 notify-send**（真发送端）；dunst 显示链路完整验证待 rootfs-dbg 实跑（见 2.1.3）。

#### 2.2.2、dunst 图标依赖链分析（复用 gdk-pixbuf，非 GTK；2026-11-17）

> 用户问：图标显示复用 gtk 那边的库，依赖链如何？会不会太重？
>
> **澄清**：dunst **无 GTK 依赖**——它链的是 **gdk-pixbuf**（GTK 家族里**独立的图像加载库**，非 GTK 组件库）；notify-send 是**独立程序**，只走 D-Bus，**不用 gdk-pixbuf**，与 dunst 解耦。

**dunst 图标依赖链**（`x-dunst/build.sh` 的 deps + `strings` 实链核）：

```
dunst → gdk-pixbuf-2.0.a（builtin png/jpeg/svg loader，1.1M）
         ├─ png loader → libpng16.a（309K）
         ├─ jpeg loader → libjpeg.a（770K）
         └─ svg loader → librsvg-2.a（423K）→ libcroco-0.6.a（438K）+ libxml2.a（6.1M）
         └─ glib/gio/gobject（dunst 本来就链）
```

**会不会太重？——不算重，且不新增依赖**：
- gdk-pixbuf **本来就是 dunst 的硬依赖**（build deps 明列 `gdk-pixbuf-2.0`，非可选）→ 图标支持**没给 dunst 加新链**；dunst 静态 9.6M 里图标相关（png/jpeg/svg loader + rsvg/croco/xml2 被引用部分）只占**小头**。
- 大头是 **cairo（8.0M .a）+ pango + freetype + harfbuzz**——dunst **渲染文字/背景必需**，**非图标专属**（无 gdk-pixbuf 也得链）。
- 实际链接用 `--as-needed`，只拉被引用的 .o，二进制远小于 .a 之和。
- **替代考量**：若嫌重，可把 dunst 图标降级为**无图标/单色**（`icon_path`/不设 `icon`），或换更轻的图像库（如 libpng 直读 + 自绘，弃 SVG）——但 gdk-pixbuf 已链、增量小，**不值得为此改动**。

**结论**：dunst 图标走 **gdk-pixbuf（非 GTK）**，依赖链 = gdk-pixbuf → png/jpeg/svg loader → png16/jpeg/rsvg/croco/xml2 + glib/gio；**重量可接受**（已是 dunst 硬依赖、增量小，大头 cairo/pango 是渲染必需非图标专属）。notify-send 与 dunst 解耦、不用 gdk-pixbuf（3.3M，只链 gio/glib）。

#### 2.2.3、结构调整：notify-send 并入 x-dunst（2026-11-17 用户拍板）

> 用户指示：notify-send **不要独立 x-notify 模块**，**放 dunst 内构建**——加多一个方法块，各一个参数调入口编译即可。

**调整**：
- **删除** `compile/src/x-notify/`（build.sh + notify-send.c）独立组件。
- **notify-send.c 移入** `compile/src/x-dunst/`；`x-dunst/build.sh` 加 **`notify_send()` 方法块** + **独立参数调入口** `sh /src/x-dunst/build.sh notify_send`（`notify_send)` case 分支，`doExec notify_send`）。
- **同目录部署**：产物装 `/usr/local/static/dunst/bin/notify-send`（与 dunst/dunstctl 同目录，配套）。
- 仍是**独立程序**（不链 dunst 库、不用 gdk-pixbuf），只是**构建/部署归口**到 x-dunst。

**理由**：notify-send 与 dunst 是通知发送/显示的**配套工具**（同用 org.freedesktop.Notifications），归 x-dunst 构建、同目录部署更内聚；Dockerfile/CI 只加一条 `sh /src/x-dunst/build.sh notify_send`。

#### 2.2.4、全链路实跑验证（rootfs-dbg 现有 Xvnc 会话，2026-11-17）

> 用户指示：验证用**容器里现有的 Xvnc**（rootfs-dbg-v5 的 `:10` 活动会话，Xvnc+fluxbox 常驻），不另起新号。

**验证环境**：rootfs-dbg-v5（alpine rootfs 3.13），复用**现有 `:10`**（headless uid1000 的 Xvnc+fluxbox 活动会话）。

**步骤与结果**（静态产物部署到 `/usr/local/static/{dbus,dunst}`，全部 headless 运行）：
1. **会话总线**：`/usr/local/static/dbus/bin/dbus-daemon --session --nosyslog --nofork --address=unix:abstract=/tmp/dbus-uid1000`（rootfs entry.sh dbus 注释默认不起，手动起）→ proc 存活、无报错。
2. **dunst 注册**：`DISPLAY=:10 DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-uid1000 /usr/local/static/dunst/bin/dunst` → `ListNames` 见 **`org.freedesktop.Notifications` 被持有**（注册成功）；日志 `No configuration file found, using defaults`（无配置文件走默认，正常）。
3. **notify-send 发送**：`/usr/local/static/dunst/bin/notify-send -a static-test -u critical -t 15000 "DISPLAY-CHECK-12345" "全链路显示验证正文"` → **返回通知 ID**（dunst 接受，rc=0）。
4. **显示确认**：`DISPLAY=:10 scrot` + OCR → **`DISPLAY-CHECK-12345` 清晰可见**（3x 放大 OCR，chi_sim+eng）→ **通知在 :10 屏幕上渲染**。✅

**结论**：静态通知**全链路通**——notify-send（x-dunst）→ 会话总线（static dbus-daemon）→ dunst（static，D-Bus 注册）→ **屏幕显示**（OCR 确认）。notify-send 独立（只走 D-Bus、不用 gdk-pixbuf）；dunst 用 gdk-pixbuf（非 GTK，见 2.2.2）渲染图标。

#### 2.2.5、D-Bus 激活自动拉起 dunst（不手动先跑，2026-11-17 用户拍板验证）

> 用户问（2026-11-17）："dunst 你要先跑起来他吗？按照先前的设计，不是不用先跑吗？直接让默认注册去拉起来他。这个你也验证一遍。"

**背景（hdmi 动态版对照）**：Ubuntu 22.04 hdmi 容器的 `/usr/bin/dunst` 由 `perpd` **开机自启**（ppid=1，3 个常驻进程），且**未装 notify-send**（`which notify-send` 空）——动态版靠桌面会话自启、不靠 D-Bus 激活。其 `/usr/share/dbus-1/services/org.knopwob.dunst.service` 仅作标准接口兜底（内容 `Name=org.freedesktop.Notifications, Exec=/usr/bin/dunst`）。

**根因（首次实测失败）**：rootfs-dbg-v5 的静态 dunst 部署在 `/usr/local/static/dunst/share/dbus-1/services/org.knopwob.dunst.service`（内容 `Name=org.freedesktop.Notifications, Exec=/usr/local/static/dunst/bin/dunst`），但 **dbus-daemon 扫描目录（`<standard_session_servicedirs />` = `~/.local/share`、`/usr/local/share`、`/usr/share` 下 `dbus-1/services/`）均为空** → 激活条目未加载 → notify-send 报 `not provided by any .service files`。且 `/usr/bin/dunst` 不存在（宿主机装的服务文件不适用）。

**修复**：把 service 文件放 `/usr/share/dbus-1/services/org.knopwob.dunst.service`（扫描目录内），重启 session bus 让 dbus-daemon 重新加载激活条目（bus 启动时扫描，运行中不热加载）。

**验证步骤与结果**（rootfs-dbg-v5 `:10`，全部 headless）：
1. **放置 service 文件** → `/usr/share/dbus-1/services/org.knopwob.dunst.service`（`Name=org.freedesktop.Notifications`、`Exec=/usr/local/static/dunst/bin/dunst`）。
2. **kill 现有 dunst**（此前手动起）→ `ps -C dunst` 空（确认不跑）。
3. **重启 session bus**：`dbus-daemon --session --nosyslog --nofork --address=unix:abstract=/tmp/dbus-uid1000`（**需带 `DISPLAY=:10`**——激活子进程继承 bus 环境，缺 DISPLAY 则 dunst 激活后连不上 X 退出 status 1；首次实测 `Spawn.ChildExited: ...exited with status 1` 即此因）。
4. **notify-send 发送**（不先跑 dunst）：`notify-send -t 15000 "ACT-CHECK-3" "dunst auto-activate via dbus service file OK"` → **返回 ID=3（rc=0）**，dunst **被 D-Bus 激活自动拉起**（`ps` 见 `/usr/local/static/dunst/bin/dunst`，pid 2123）。
5. **注册确认**：`ListNames` 见 **`org.freedesktop.Notifications` 被持有**（激活的 dunst 已注册）。
6. **显示确认**：`DISPLAY=:10 scrot` + 裁剪放大 OCR → **`ACT-CHECK-3` 清晰可见**（通知在右上角渲染）。✅

**结论**：**dunst 无需手动先跑**——把 service 文件放进 dbus-daemon 扫描目录（`/usr/share/dbus-1/services/`），notify-send 发 `Notify` 时 dbus-daemon 按 `Name=org.freedesktop.Notifications` 自动 `Exec` dunst（继承 bus 环境含 DISPLAY），dunst 自注册并显示。**前提两条**：① service 文件在扫描目录（静态部署的 `share/dbus-1/services/` 非扫描路径，需拷入 `/usr/share/dbus-1/services/`）；② bus 重启（启动时扫描）且带 DISPLAY。截图：`docs/img/tmp/notify-dunst/notif-autoact.png`。

#### 2.2.6、图标空白根因与 dunst 图标支持现状（mime.cache / SVG builtin，2026-11-17）

> 用户问（2026-11-17）："dunst 已链接 pixbuf 这个是最初 CI 那边构建/镜像内的包就已经包含的，还是你先前调试的时候重新编译的？""跟文档内说的 mime 有关吗？完全没有 loaders.cache 和 gdk-pixbuf-2.0/2.10.0/ 目录；builder 有 ... 啥其他的程序没有这个东西也是可以的呢，这个东西感觉不需要了吧。"
> 用户确认（2026-11-17）："svg 那个，你查看代码 跟记录文档应该是已经就绪了，ci 那边已经跑了新的镜像，只是本地的镜像是旧的滞后的。""mime 那个 也是已经处理了，新镜像里头有配置了的。"

**① dunst 二进制来源：CI 镜像内置，非调试重编**。
- rootfs-dbg-v5 的 dunst md5 `3d1c09e7...` 与 **builder-g224（CI 构建镜像）完全一致**，时间戳 Nov 15 08:40（镜像烘焙时间）。Nov 17 仅**部署**（拷 `/usr/local/static/dunst/`），**未重编**。
- 链接行（strings）：`-lgdk_pixbuf-2.0 -lrsvg-2 -lpng16 -ljpeg`——CI 的 `x-dunst/build.sh` `DUNST_LIBS` 本就含，非调试新增。

**② 图标空白根因 = mime.cache 缺失（非 loaders.cache）**。决定性实验（探针 `pbprobe`，静态链同套 gdk-pixbuf）：
- 格式表：builder 与 rootfs **都 13 个格式**（含 png/jpeg），无差异——**格式注册正常**。
- builder 加载 png OK、rootfs png FAIL（"Couldn't recognize the image file format"）。
- **挪走 builder 两份 `gdk-pixbuf-2.0/2.10.0/`（loaders.cache + loaders/）→ png 仍 OK**——**builtin loader 不依赖 loaders.cache**（用户判断正确：loaders.cache 不需要）。
- **拷入 `/usr/share/mime/mime.cache` → rootfs 探针 png 立即 OK（24x24）**。✅
- **根因**：gdk-pixbuf 编译 `config.h` 定义 `GDK_PIXBUF_USE_GIO_MIME 1` → `_gdk_pixbuf_get_module` 走 **`g_content_type_guess`（按 MIME，非 magic）** 匹配格式；rootfs 无 `shared-mime-info`（`mime.cache`）→ 猜不出 `image/png` → 匹配不到 png 格式 → 图标空白。**builder 有 mime.cache 故一直 OK**。
- **与文档「二、配置项 1、mime 数据」完全吻合**（R8 实证：拷 builder `/usr/share/mime` 进 rootfs，png/svg 立即翻 OK）。

**③ SVG builtin：代码已就绪，本地镜像滞后**（用户确认）。
- u-gtk 代码：`meson -Dbuiltin_loaders=png,jpeg,svg`（`u-gtk/build.sh:88`）+ patch `gdk-pixbuf-2.42.8-lxtask-static.patch` 加 `io-svg.c` + `INCLUDE_svg` 三处（`module(svg)`/`try_module(svg,svg)`/`load_one_builtin_module(svg)`）。
- 文档 `09261949-lxtask-解析与优化.md:782-786` 已记录：svg loader 编进 builtin，`.a` 1.31MB 含 `io-svg.c.o` + `_gdk_pixbuf__svg_fill_vtable` T。
- **本地 builder 滞后**：`/usr/lib` 与 `/usr/local/lib` 的 `libgdk_pixbuf-2.0.a` **md5 相同、Nov 11 06:33 旧构建**，`ar t` 只有 io-png/io-jpeg **无 io-svg** → 探针格式表无 svg → dunst svg 图标空白（本地）。
- **CI 新镜像已含**（u-gtk 已配 svg builtin + `shared-mime-info` 装包带 mime.cache），本地重编 u-gtk 或拉新镜像即可。

**④ mime 部署配置已就绪**（用户确认）：`rootfs/src/Dockerfile:285` 装 `shared-mime-info`（生成 `/usr/share/mime/mime.cache`）；`u-gtk/build.sh:357` 同装。本地旧镜像未装（手动拷 mime.cache 才 PNG OK）。

**结论**：**dunst 图标支持（png/jpeg builtin + svg builtin + mime.cache）在 CI 新镜像均已就绪**；本地 rootfs-dbg-v5/builder 旧镜像滞后（缺 io-svg 与 mime.cache），故本地验证 PNG 需手动补 mime.cache、SVG 需重编 u-gtk 或拉新镜像。**loaders.cache / `gdk-pixbuf-2.0/2.10.0/` 无需部署**（builtin 不依赖，用户判断正确）。效果截图（本地补 mime.cache 后 PNG OK）：`docs/img/tmp/notify-dunst/notif-icon-png-mime-fixed.png`。

#### 2.2.7、D-Bus 服务激活机制（怎么操作 / 写哪 / 内容，2026-11-17 用户问）

> 用户问（2026-11-17）："它的那个 dbus 自动注册是怎么样的操作？写哪里的配置文件？配置的内容又是啥？"

**D-Bus 服务激活（service activation）**——即"默认注册自动拉起"（2.2.5 已验证）。

**① 操作（机制链路）**：
```
notify-send 发 org.freedesktop.Notifications.Notify
        ↓（该名当前无 owner）
dbus-daemon 查「激活条目表」（启动时从 service 文件加载）
        ↓（找到 Name=org.freedesktop.Notifications 的条目）
dbus-daemon 按 Exec 自动 spawn 服务（继承 bus 环境，含 DISPLAY）
        ↓
dunst 启动 → 注册 org.freedesktop.Notifications → 接收通知并显示
```
- **dbus-daemon 启动时扫描 service 目录**（运行中新增文件不热加载）→ 放好文件后需**重启 session bus**。
- bus 环境要带 `DISPLAY`（激活子进程继承 bus 环境，缺 DISPLAY 则 dunst 连不上 X 退出 status 1，2.2.5 实测）。

**② 配置文件位置**（`session.conf` 的 `<standard_session_servicedirs />` 扫描，任一即可）：
- `$XDG_DATA_HOME/dbus-1/services/`（默认 `~/.local/share/dbus-1/services/`）
- `$XDG_DATA_DIRS/dbus-1/services/`（默认 `/usr/local/share:/usr/share` → `/usr/local/share/dbus-1/services/`、`/usr/share/dbus-1/services/`）

验证用：**`/usr/share/dbus-1/services/org.knopwob.dunst.service`**。

**③ 内容**：
```
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/local/static/dunst/bin/dunst
```
- `Name=` = **要激活的 bus 名**（dbus-daemon 按 `Name=` 字段建激活条目，非文件名）。
- `Exec=` = **自动启动命令**（指向静态 dunst 绝对路径）。
- **文件名**：dunst 源码就叫 `org.knopwob.dunst.service`（内容 Name 是 `org.freedesktop.Notifications`）——文件名与 Name **不一致**，但 session bus **非严格命名**不报错、仍按 Name 激活（system bus 严格命名才拒绝）；dunst 上游就这样设计，可用。

**落地注意**：当前 build.sh 只把 service 文件装到 `$TARGETPATH/share/dbus-1/services/`（`/usr/local/static/dunst/share/dbus-1/services/`）——**这不是扫描目录**，CI 镜像要能自动激活，还需拷到 `/usr/share/dbus-1/services/`（或任一扫描目录）。

#### 2.2.8、第一项落地：Dockerfile 加 notify_send 构建 + service 文件入扫描目录（2026-11-17）

> 用户指示（2026-11-17）："先第一项，然后第二项"——第一项 = Dockerfile/CI 落地（notify_send 构建 + service 文件入扫描目录 + mime.cache 确认）。实现后用户要求"把你的实现也更新到记录文档"。

**改动**（`compile/src/Dockerfile`，单 commit `16b1b105` 已推送）：
1. **dunst stage 加 `notify_send` 构建**：`sh /src/x-dunst/build.sh notify_send;` → notify-send 进新镜像 `/usr/local/static/dunst/bin/notify-send`（此前 stage 只有 `b_deps`+`dunst`）。
2. **service 文件入扫描目录**：组装层 `COPY --from=dunst` 后加 `RUN`，把 `/rootfs/usr/local/static/dunst/share/dbus-1/services/*.service` 拷到 **`/rootfs/usr/share/dbus-1/services/`**（dbus 扫描目录）→ 新镜像里 notify-send 发 `Notify` 时 **D-Bus 激活自动拉起 dunst**（2.2.5/2.2.7 机制）。

**实跑验证**（builder-gtk-dbg 执行 `notify_send` 分支）：
- `notify-send` 编译+验证通过 → **3.36M 静态**，`xx-verify --static` = **0**（rc=0）✅

**mime.cache**：`rootfs/src/Dockerfile:285` 已装 `shared-mime-info`（自动生成 `/usr/share/mime/mime.cache`），新镜像已就绪，无需改动（2.2.6 ④）。

**结论**：新镜像将自动含 `notify-send`（x-dunst 内构建）与 dbus 扫描目录 service 文件，D-Bus 激活自动拉起 dunst 全链路落地。

#### 2.2.9、第二项落地：新 dunst 验证 SVG 图标（undock 取阿里云最新镜像，2026-11-17）

> 用户指示（2026-11-17）："只做第 1、2 项"——第二项 = 新 dunst 验证 SVG 图标。**用户指出关键工具**：新 dunst 4M 是 **UPX 压缩**（`rootfs/src/static/clear/clear.sh:24-31` `upx -7`），**不是不含库**。

**为什么本地旧 dunst 不能验 SVG**：本地 builder 旧 `.a`（Nov 11，无 io-svg）滞后；CI 新镜像已含 SVG builtin 代码（u-gtk `-Dbuiltin_loaders=png,jpeg,svg`，build.sh:88，2.2.6 ④）。故用 **`undock`**（crazy-max，`/usr/bin/undock`→`/usr/local/static/3rd/bin/undock`）从**阿里云远程镜像 `x11-base:rootfs-dbg`** 直接抽取内容（`undock --platform linux/amd64 --include="/rootfs/files1/usr/local/static/dunst" <镜像> <输出目录>`），绕开 docker overlay ENOSPC（宿主 `/` 与 `/_ext` 均 98% 满）。

**新 dunst 特征**（undock 抽取到 `/_ext/tmp/svg/undock-out/`）：
- md5 **`37b454a9`**，**4.01M（UPX 压缩）**，解压后 ~10M 原大小；与 v5 旧（`3d1c09e7`，10M 未压缩）**不同**。
- 链接含 **`-lrsvg-2`**，strings 有 `image/svg+xml`/`<svg`、`svg_load`/`rsvg` → **librsvg/io-svg 已编入**；stripped 无符号，需实测验证。

**验证方法**（rootfs-dbg，Xvnc 会话）：
1. 新 dunst 替换 v5 `/usr/local/static/dunst/bin/dunst`（旧备份 `dunst.old-bak`），重启。
2. 发 SVG/PNG 图标通知：**SVG ID=2 rc=0、PNG ID=3 rc=0**，OCR 确认文本 `SVG-ICON-NEW`/`PNG-ICON-NEW`。
3. **用户确认**：`notif-svg-new-dunst-zoom.png` 有鼠标图标（SVG Papirus `input-mouse`），`notif-png-new-dunst.png` SVG+PNG 两条都有图标 → **SVG builtin 验证通过 ✅**。

**截图已推送**（`017fb2a2`，`docs/img/tmp/notify-dunst/`，3 张）：`notif-svg-new-dunst.png` / `notif-png-new-dunst.png` / `notif-svg-new-dunst-zoom.png`。

**结论**：新镜像 dunst（UPX 压缩 4M，含 librsvg/io-svg）**SVG+PNG 图标均渲染正常**，图标链路（2.2.6 根因）在最终产物上闭环。

### 2.3、dbus 版本升级评估与实现（2026-11-23）

#### 2.3.1、最新版本评估（2026-11-23）

**结论**：项目当前 dbus **1.12.26**（2023-02-08），上游最新 **1.16.4**（2026-11-12）；1.12 系列最高 **1.12.28**。方案 C（升最新 1.16.4）需 **Meson 构建改造**（1.16 起 Autotools 移除，tarball 无 configure）。

**发布时间对比**：

| 版本 | 角色 | 发布时间 |
|---|---|---|
| 1.12.26（项目当前） | 1.12.x 老稳定 | 2023-02-08 |
| 1.12.28 | 1.12 系列最后（项目未到） | 2023-06 |
| 1.14.0 | 1.14.x 稳定分支（取代 1.12.x） | 2022-02-28 |
| 1.14.10 | 1.14 末版 LTS | 2024-06 |
| 1.16.0 | 1.16.x 新稳定（取代 1.14.x） | 2024-12-16 |
| 1.16.2 | 1.16 点版 | 2025-02-27 |
| 1.16.4（上游最新） | 当前稳定 | 2026-11-12 |

**1.16.x 功能变化**（相对 1.12.26）：

- **构建系统：Autotools 移除，Meson 推荐/默认**（Meson ≥ 0.56 + Python 3.5）——官方 1.16.x tarball 不再含 `configure`。
- C99 编译器要求；>64 位指针平台需 C11。
- 系统总线 socket 默认 runtime state dir（/run）。
- 传统 activation 的 `dbus-daemon-launch-helper` setuid 权限不自动设置（需打包/手动）。
- `pam_console`/`pam_foreground` 集成移除。
- Linux `GetConnectionCredentials()` 支持 **ProcessFD**。
- 系统总线从 /etc 和 /run 加载 .service 文件。
- `close_range()` 关闭 fd / close-on-exec。
- **Y2038 安全**：32 位平台 64 位时间戳、64 位 inode/timestamp API。
- dbus-send 支持数组/字典/嵌套变体；AF_UNIX on Windows；大指针架构可移植性。

**CVE 修复**（1.12.26 未含，1.16.4 已含）：

| CVE/编号 | 类型 | 修复版本 |
|---|---|---|
| CVE-2023-34969 | Monitoring interface DoS | 1.12.28 / 1.14.6 |
| CVE-2026-120749 | 系统总线 DoS（CVE-2023-34969 不完整修复） | 1.16.4 |
| RHEL-239613 (dbus#587) | 客户端关 socket busy-loop DoS | 1.16.4 |
| RHEL-239294 (dbus#586) | nonce-tcp 阻塞 DoS | 1.16.4 |
| RHEL-239610/239934 | 非 Linux 平台 DoS（macOS/FreeBSD，x86_64 Linux 不直接相关） | 1.16.4 |

**项目环境兼容性（用 1.16.4）**：

| 维度 | 评估 | 说明 |
|---|---|---|
| 构建 | ⚠️ 最大障碍 | 项目 build.sh 用 Autotools `./configure`；1.16.x 无 configure → 需重写 **Meson 构建**（meson setup+ninja），静态链逻辑可保留 |
| ABI/API | ✅ 兼容 | libdbus 公共 ABI 稳定，下游（dbus-glib/gtk2 应用）无需重编，直接换 libdbus-1.a |
| dbus-glib | ✅ 基本兼容 | 1.16 的 dbus-1.pc（Meson 生成）需补 Libs.private（-lexpat -lpthread -ldl -lm，项目已有 sed 补丁） |
| session bus 运行时 | ✅ 功能兼容 | 项目 headless session bus（非 systemd），1.16 的系统 bus /run、setuid helper、systemd 差异不触及 |
| 安全收益 | ✅ 显著 | 获 CVE-2026-120749 + RHEL-239613 + CVE-2023-34969 等（当前全未含） |
| 成本/风险 | 中 | Meson 改造 + 重新验证（session bus 起停 / dbus-send / dunst / dbus-glib） |

**建议**：方案 C 升 1.16.4（最新安全），需 Meson 构建改造；build.sh 改多版本（像 dropbear），旧 1.12.26 保留。

#### 2.3.2、方案C 开工实现与验证（2026-11-23）

**方案 C（升最新 1.16.4）实现完成**：`x-dbus/build.sh` 改**多版本构建**（像 dropbear），默认走 `dbus_1_16_4`（Meson 静态全建），旧 1.12.26 方法保留（`dbus_1_12_26`/`dbus_send_1_12_26`/`dbus_launch_1_12_26` 可调）。

**构建过程与坑**（容器 builder-g224，alpine-builder-gtk224-2）：

1. **build.sh 多版本化**：保留旧 `dbus()`（1.12.26 Autotools）为 `dbus_1_12_26` 等可调；新增 `dbus_1_16_4()`；case 默认 `dbus`/`dbus-send`/`dbus-launch` → `dbus_1_16_4`。
2. **1.16 构建系统迁移**：1.16 起 Autotools 移除（tarball 无 configure），须 **Meson**（容器已有 meson/ninja/python3）。Meson 选项名全变（`meson_options.txt`）：`x11_autolaunch`（可正确关 X11，旧 configure `--disable-x11` 无效）、`default_library` 为 Meson 内建（meson_options 不列）。
3. **Meson 选项类型坑**：`modular_tests`/`xml_docs` 是 **feature**（enabled/disabled/auto），`user_session`/`installed_tests`/`intrusive_tests`/`tools`/`message_bus`/`traditional_activation`/`asserts`/`checks` 是 **boolean**（true/false）——首次传值错（boolean 收 `disabled` / feature 收 `false`）报「Value ... is not boolean / not one of the choices」。
4. **expat 静态坑**：Meson 的 expat dependency 默认用 `/usr/lib/libexpat.so`（动态），与 `-Dc_link_args=-static` 冲突（attempted static link of dynamic object）→ patch meson.build 给 expat dependency 加 `static: true` 强制 libexpat.a。
5. **ninja target 名带路径**：`bus/dbus-daemon`、`tools/dbus-send`、`tools/dbus-launch`、`dbus/libdbus-1.a`（裸名报 unknown target）。
6. **只建产品 target 避测试程序**：`test-service` 无条件建、`launch-helper-for-tests` 因 `traditional_activation` 触发（链 glib 动态）→ ninja 只建 4 产品 target，避开测试链。
7. **strip**：`-Dc_link_args='-static -Wl,--strip-all'` 令产物 `statically linked, stripped`（Meson 默认不 strip）。

**验证结果**（容器 builder-g224）：

| 项 | 结果 |
|---|---|
| dbus-daemon | `statically linked, stripped`（582K）；`--version` = D-Bus Message Bus Daemon **1.16.4** |
| dbus-send | 静态（309K），xx-verify PASS |
| dbus-launch | 静态（1.1M），xx-verify PASS |
| libdbus-1.a | 2.0M，nm `dbus_bus_get` OK |
| session bus 实跑 | 起 `dbus-daemon --session` 成功 + `dbus-send` ListNames 返回（org.freedesktop.DBus + :1.0） |
| dbus-glib 下游 | dbus-glib 0.112 对 **1.16.4 libdbus-1.a** 编译成功（libdbus-glib-1.a 275K，**ABI 兼容**） |
| 产物路径 | `/usr/local/static/dbus/bin/{dbus-daemon,dbus-send,dbus-launch,...}` + `lib/libdbus-1.a` + `lib/pkgconfig/dbus-1.pc` + `share/dbus-1/*.conf` |

**总结**：方案 C 完成，dbus 1.16.4 静态构建 + 运行 + 下游 dbus-glib 全验证通过。升级获 CVE-2026-120749 + RHEL-239613 + CVE-2023-34969 等修复；构建系统改 Meson（Autotools 移除），旧 1.12.26 方法保留可回退。

### 3、pasystray 音量托盘通知(libnotify静态化) + pavucontrol 评估版本已最新

#### 3.1、pasystray 滚轮调音量通知：现状与方案（静态化 libnotify，2026-11-17）

> 用户问（2026-11-17）："pasystray 鼠标在那个托盘区域，鼠标中键滚轮调大或者改小音量会有通知吧，它本身触发通知。"——调研 pasystray 滚轮调音量是否触发通知；用户拍板方案：**静态化 libnotify**，库放组件脚本内构建（开工见 3.2）。

**结论：静态版 pasystray 滚轮调音量不会触发通知**——构建时就把 notify 禁了。

**源码依据**（pasystray 0.8.2，`compile/tarsrc/v-pasystray/`）：
- **构建**（`v-pasystray/build.sh:52`）：`./configure --with-gtk=2 --disable-avahi --disable-notify --disable-appindicator`——**`--disable-notify`**（libnotify 不在静态栈，2.1.6 已证）。
- **notify.c 空实现**（`#ifndef HAVE_NOTIFY`，`src/notify.c:24-30`）：`HAVE_NOTIFY=0` 时 `notify()` 返回 0、`notify_update()` 空——**滚轮调音量调了但什么都不显示**。
- **调用链**（真实存在）：滚轮 → `systray_scroll_cb`（`systray.c:408`）→ `pulseaudio_volume` → **`notify()`/`notify_update()`**（`pulseaudio_action.c:288-290`）→ 若有 libnotify 则发 D-Bus 通知；**静态版是空函数**。

**方案（用户拍板）**：要让它「滚轮调音量有通知」（走方案 A 的 dunst），选**静态化 libnotify**——libnotify 走 GDBus/libdbus（2.1.6 已分析：`--enable-static` 可行，需下载源码），**库放在组件脚本内构建**；然后 pasystray 去掉 `--disable-notify` 重建。备选：改 notify.c 直接发 D-Bus（GDBus 直发，不依赖 libnotify）。

#### 3.2、libnotify 静态化落地（meson patch，2026-11-17 已推送）

> 承接 3.1 方案：静态化 libnotify 0.8.9（放 `v-pasystray/build.sh` 组件脚本内构建），pasystray 去 `--disable-notify` 链入——滚轮调音量通知链路落地。单 commit `e2ebbeb7`。

**libnotify 静态化要点**（`compile/src/v-pasystray/build.sh` 加 `libnotify()` 函数，`b_deps` 调用）：
1. **meson 主库坑**：`libnotify/meson.build:58` **`shared_library` 硬编码**（`--default-library=static` 无效）→ patch 成 `static_library`，且 `static_library` **不接受 `version`/`soversion`**（shared 才有）→ 一并删。
2. **tools/docs 阻塞**：meson 自带 `tools/notify-send` 链 `.so` + `--static` 失败（`attempted static link of dynamic object`）→ patch 删 `subdir('tools')`/`subdir('docs')`，只编主库。
3. **gio-unix 不构成问题**：`gio-unix-2.0.pc` **无 Libs**（仅 `Requires: gio-2.0`），且 libnotify 代码**不用 `g_unix_*` 符号**——符号在 `libgio-2.0.a` 里，无需独立 gio-unix.a（2.1.6 坑证伪）。
4. **构建**：`meson setup --prefix=/usr --default-library=static -Dintrospection=disabled -Dtests=false -Dman=false -Dgtk_doc=false -Ddocbook_docs=disabled` → `meson compile` + `meson install`。
5. **产物**：`/usr/lib/libnotify.a`（234K）+ `/usr/lib/pkgconfig/libnotify.pc` + `/usr/include/libnotify/{notify,notification,notification-hints,notify-features,notify-enum-types}.h`。

**pasystray 接入**（同 commit）：`configure` 去 `--disable-notify`（保留 `--disable-avahi --disable-appindicator`），`PST_LIBS` 加 `-lnotify`（start-group 内）。

**实跑验证**（builder-g224）：
- libnotify.a 234K 装 `/usr/lib` ✅；`pkg-config --exists libnotify` OK ✅。
- pasystray 14M `statically linked, stripped`，`xx-verify --static` = **0** ✅。
- **strings 确认 libnotify 真实现编入**：`notify_notification_show`/`notify_notification_update`/`notify_notification_set_timeout` + `you must call notify_init() before showing`（`notify_init` 前置检查）+ `../libnotify/notify.c` → **HAVE_NOTIFY=1，notify() 真实现**（非空实现）✅。

**结论**：滚轮调音量 → `notify()` → libnotify → D-Bus `org.freedesktop.Notifications` → 方案 A 会话总线 → dunst 激活显示，链路已接通（运行期滚轮实测待做，见 3.3 待补充）。

#### 3.3、运行期滚轮实测（rootfs-dbg-v5 Xvnc，2026-11-17 已推送）

> 承接 3.2：静态版 pasystray 已链 libnotify 真实现，本节在运行环境实测「托盘滚轮调音量 → 通知弹出」是否真的生效。截图 `docs/img/tmp/notify-dunst/v4_notif-pasystray-scroll.png`（commit `7a5564c6`）。

**测试环境**：rootfs-dbg-v5（Xvnc `:10` + fluxbox + tint2 托盘 + pulseaudio + dunst + dbus-daemon）。

**两个关键坑（实测踩到）**：
1. **dunst 挂在 fork 会话总线** `unix:path=/tmp/dbus-wrJOIvjpMf`（**不是** entry.sh 方案 A 的抽象总线 `unix:abstract=/tmp/dbus-uid1000`）——`ListNames` 确认 `org.freedesktop.Notifications` 只在 fork 总线；抽象总线上没有 dunst。
2. **总线为 `headless` 用户所有，root 连不上**（unix 认证拒绝）——`dbus-send`/pasystray 必须 `docker exec -u headless` 跑（root 下连 ListNames 都失败）。

**部署**：builder-g224 的 `/usr/local/static/pasystray/share/`（`pasystray.gtk2.glade` + `zh_CN/LC_MESSAGES/pasystray.mo` + `applications/pasystray.desktop`，共 40K）经 `/_ext/tmp` 中转拷到 rootfs-dbg-v5 同名路径；起 pasystray（headless，`DISPLAY=:10`，`DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-wrJOIvjpMf`，pid 3360，无崩溃）。

**托盘图标定位**：真图标 = `PulseAudio system tray`（win `12582915`）@ (975,745) 19x19；`pasystray` win @ (10,10) 10x10 是**隐藏窗口**（别点错，第一次就点错没反应）。

**验证（干净 A/B 裁剪 dunst 窗口区域 705,50-1014,104）**：
- 滚轮前：2 色（纯背景）。
- 滚轮后：32 色（通知框弹出，含文字/图标）。

**结论**：滚轮 → `systray_scroll_cb` → `pulseaudio_volume` → `notify_update()` → **libnotify → D-Bus → dunst 通知显示**，`HAVE_NOTIFY=1` 真实现运行期生效 ✅（静态版 pasystray 滚轮调音量**现在有通知**了）。

#### 3.4、重编后运行期复验（builder 重编 + hdmi Xvnc :352，2026-11-18 落档）

承接 3.3（rootfs-dbg-v5 已实证滚轮→dunst）：用户 2026-11-18 问"pasystray 是否有编译错误/没产生二进制"、以及"运行正常吗 / 有没有托盘图标 / 托盘图标中间滚轮会不会触发 dunst 通知"——**builder 重编 + hdmi 全新 display 复验，结论全部正常**。

**构建复验**（builder-g224，重跑 build.sh）：
- `CONSOLE_LOG=no TARGETPATH=/usr/local/static/pasystray sh /src/v-pasystray/build.sh pasystray` → **BUILD_RC=0**，6s（增量重链），日志 **0 处** `undefined reference`/`attempted static link`。
- 产物 `/usr/local/static/pasystray/bin/pasystray` 14.0M `statically linked, stripped`，`xx-verify --static` = 0；ldd 报 `Not a valid dynamic program`。
- **源码树 4 个 `.c.rej`（menu_info/pasystray/systray/ui）是良性残留**：build.sh `patch -p1 -N ... || true` 对已打补丁树重跑时部分 hunk 上下文不精确匹配 → 生成 `.rej` 但被 `|| true` 吞；grep 确证源码**确实含全部改动**（menu_info.c 8 处 `_(`、systray.c 20 处、pasystray.c setlocale/bindtextdomain、ui.c ui_register_glade_types），勿误判"缺补丁"。

**运行复验**（hdmi `docker-hdmi-desktop-desktop-1`，全新 Xvnc `:352`；按规则不用 live `:1`）：
- 环境：Xvnc :352 + `dbus-launch` + `pulseaudio --start`（+ `module-null-sink sink_name=pstest`）+ **单实例 dunst** + openbox + tint2 托盘 + pasystray（新编版，先经 `/_ext/tmp` 中转部署到 `/usr/local/static/pasystray/`）。
- **托盘图标存在且渲染**：GtkStatusIcon 窗口 `PulseAudio system tray`（22x22）嵌入 tint2 托盘；图标 crop 区 **422 种颜色**（非空白，真画出来了）。`pasystray` win 10x10 是隐藏窗口（3.3 同坑，别点错）。
- **滚轮改变音量**：`xdotool click --window <icon_id> 4/5` → 100%→102%→104%→106%（null-sink 实测）。
- **滚轮触发 dunst 通知**：dbus-monitor 捕获 `org.freedesktop.Notifications.Notify` → destination=:1.7（dunst），文本 `sink Null Output 106%`，hints `image-path=audio-volume-high`、`value=106`；`dunstctl is-paused=false`，截图 diff 右上角 (1075,33) 通知文字更新（连续滚轮同一通知复用，仅末位数字变）。

**通知门控（默认）**——`options.c notify_default`：`n_systray_action=TRUE`（pasystray 自身操作→通知），`n_sink/source=FALSE`（外部音量变更→不通知）。**故默认配置滚轮→dunst 通知会触发**；`--notify=all` 才全开。

**本次新增测试坑（2026-11-18）**：
1. **多 dunst 实例竞争 `org.freedesktop.Notifications` 名→通知丢失/不到达**——测试必须单实例 dunst（初次"没捕获到"即此因）。
2. **托盘图标窗口须 `xdotool click --window <id>` 定向**——`mousemove+click` 落不到图标（XEmbed 位置偏移，指针实际落在 tint2 主窗口）。
3. `notify_update` 复用同一通知句柄→连续滚轮仅末位数字变化（截图 diff 区域小）。

**结论**：pasystray 构建无错、二进制有效；运行正常、托盘图标有、滚轮→dunst 通知默认触发 ✅。

#### 3.5、CI 产物无通知排查（rootfs-dbg 最新镜像，2026-11-18 落档）

承接 3.4（builder 重编验证有通知）：**CI 构建产物（rootfs-dbg 镜像）的 pasystray 无通知**——用户 2026-11-18 反馈「CI 构建成功后滚轮仍无 dunst 通知」。

**实测（最新镜像 `b51a761c` / 本地 `8e9b136bda1e`，产物 11-18 11:44 构建）**：

- 产物 `/usr/local/static/pasystray/bin/pasystray`（5.7M，静态）`strings | grep -c "notify_notification_show\|notify_init"` = **0**——**二进制不含 libnotify 实现**（连 `you must call notify_init` 字面量都没有），非 UPX 假阴性（ELF 头正常，`ci-upx` 已证）。
- CI 日志（`ci-pasystray-log.txt`）编译命令**带 libnotify Cflags** `-DG_LOG_DOMAIN=libnotify`（来自 libnotify.pc）且 `pasystray-notify.o` 编译成功（`.Tpo→.Po`，line 17）——**configure 检测到 libnotify（NOTIFY=yes）**。

**根因排查（2026-11-18，`builder-gsm-verify` 复现，非猜测）**：

- `configure` 在 libnotify.pc 存在时**完全正常**：`checking for NOTIFY... yes` + `src/config.h` = `#define HAVE_NOTIFY 1`（AC_DEFINE 生效，`src/config.h.in` 模板有 `#undef HAVE_NOTIFY`）。
- `make -C src pasystray-notify.o` 正常：notify.o **真实现**——`U notify_init`、`U notify_notification_new/show/update`（引用 libnotify，8 处）+ `T notify_initialize/show/update`（真实现函数）。
- `libnotify.pc`（meson 生成）Cflags = `-I${includedir} -DG_LOG_DOMAIN="libnotify"`——**该宏确来自 libnotify.pc**；NOTIFY_CFLAGS 非空 ⟺ PKG_CHECK 成功 ⟺ HAVE_NOTIFY=1。
- 链接：`-lnotify` 可链（libnotify.a 在 `/usr/lib`，脚本 `PST_LIBS` 完整含 glib/pcre 全链）；手动测试报 `undefined reference pcre_*` 只是测试命令漏 `-lpcre`，非脚本问题。

**结论**：**脚本/源码/configure 均正常**（本地能得出 HAVE_NOTIFY=1 真实现 + notify.o 引用 libnotify）；**CI 产物无 notify 符号 = CI 构建环境问题**——notify.o 或 libnotify.a **未链入最终二进制**，且 `oneBuild` 吞错（AGENTS「判成功别信 oneBuild」）致 `_exec_result.txt=0` **假成功**。**需 CI 侧构建日志（本镜像 `/usr/local/static/.logs/` 已被清）/构建缓存排查**；本仓库脚本侧无可修点。

**与 3.3/3.4 区分**：3.3/3.4 验证的是 **builder 手链版**（有通知）；**CI 产物无**。运行期无通知与用户反馈**一致**（产物无 notify 代码，滚轮 `notify_update()` 走空实现）。

**订正（2026-11-18 晚，镜像内完整日志 + upx 解压实测）**：3.5 上述「CI 构建环境未链入 libnotify」结论**有误，撤**。

真实情况（镜像内 `/rootfs/files1/usr/local/static/.logs/doExec/v-pasystray/pasystray.log` 727 行完整日志 + `upx -d` 解压实测）：

- **CI 构建完全正常**（12:39）：`checking for NOTIFY... yes`（51 行）；链接命令（706 行）含 `pasystray-notify.o` + 两次 `-lnotify` + `-lpulsecommon-13.13`；`undefined reference` 计数 **0**；verify 段产物 **13.4M** `statically linked, stripped`，GTK_ICON_THEME/murrine/rsvg strings 全 OK。
- **产物被 UPX 压缩**（13.4M → 5.7M，40.79%）——notify 代码在 UPX 压缩段内，`strings` 看到「无 notify」是**压缩假阴性**。用镜像自带 `upx -d`（`/rootfs/files1/usr/local/static/3rd/bin/upx`）解压后 = **14,046,968 字节**（与本地构建同尺寸），`strings` notify 计数 **2**，真实现字符串 `[notify] unable to show notification: %s: %s (%i)`、`[notify] invalid arguments passed to notify_update()` 均在。
- **3.5 分析错误根因**：① 镜像内产物在 `/rootfs/files1/usr/local/static/`（rootfs 分层），此前误查容器 `/usr/local/static/`（不存在）判「日志被清」；② `strings` 检查未考虑 UPX 压缩（`ci-upx` 只查前 4 字节 ELF magic，UPX 保留 magic，检查方法错误）。
- **因此「滚轮无通知」真实原因不在构建**（CI 产物含 notify 实现，解压可运行）——**转向运行层**：dunst 会话总线归属 / notify 门控（`options.c notify_default`）/ UPX 运行时行为，**待实跑定位**。

**build.sh 补充防御**（2026-11-18）：verify 段加 `strings | grep "notify_notification_show\|notify_init"` 检查（构建产物真缺 notify 时直接 `exit 1`）；`case` 默认分支 `oneBuild $1` 后改 `exit $?`（撤掉原本无条件 `exit 0` 吞错，AGENTS「case 结尾不要 exit 0」坑）。

#### 3.6、现有进展：滚轮无通知根因钉死（libnotify GDBus connection closed，2026-11-18 保存）

用户 rootfs-dbg（`docker run -it --rm --net=host -e L=zh_CN -e START_SESSION=openbox-session <rootfs-dbg>`）托盘滚轮调音量**无 dunst 通知**，且反复排查多轮才定位。本节保存当前定论与验证链（供后续实施解决）。

##### 3.6.1、现有进展记录（验证链与结论）

**结论（已实测钉死）**：**pasystray 静态链 libnotify 的 `notify_notification_show` 失败——报 `The connection is closed`（GDBus 连接关闭）**——滚轮 → `notify()` → show 失败 → 总线无 Notify → dunst 无事可做，无通知。**notify-send（x-dunst GDBus 直发）同环境正常显示**——libnotify 与 GDBus 直发**实现不一致**坐实。

**验证链（逐步排除，全程实测）**：

| 环节 | 结果 |
|---|---|
| CI 构建 | ✅ 正常（13.4M 有 notify；UPX 压 5.7M 是 strings 假阴性，见 3.5 订正） |
| dunst 显示 | ✅ 正常（notify-send 显示；手动起 dunst 后 notify-send 也显示，diff bbox 证实） |
| 音频 sink | ✅ 正常（用户环境有 `xrdp-sink`，pulse 定制；滚轮 `set_volume` 成功，pavucontrol 音量相应变化） |
| UPX 运行时 | ❌ 排除（同环境换 14M 解压版，滚轮仍无通知，diff None） |
| dunst 接管 | ❌ 排除（手动起 dunst 常驻 + 滚轮仍无通知） |
| 总线 Notify | ❌ **0 条**（dbus-monitor 监听滚轮，无 `member=Notify`） |
| **libnotify 独立实测** | ❌ **`show rc=0 (The connection is closed)`**（test-notify 静态链：notify_init → new → show） |
| notify-send 对照 | ✅ 显示（GDBus 直发 `g_dbus_connection_call_sync` 工作） |

**根因机制**：
- `systray_scroll_cb`（systray.c:408-429）→ `pulseaudio_volume`（pulseaudio_action.c:161，set_volume 成功）→ `pulseaudio_set_volume_success_cb`（`success=1`，无 "failed to set volume" 警告）→ `n_systray_action=TRUE`（options.c:79 默认开，无配置覆盖）→ `notify()`（notify.c 真实现）→ `notify_notification_show`（libnotify）→ **失败（connection closed）** → 总线无 Notify。
- libnotify 的 GDBus connection（notify_init 建立）在 show 时已 closed；notify-send 每次 `g_dbus_connection_call_sync` 独立连接则正常——**差异在连接生命周期/复用**（静态 glib/libnotify 在 musl 下的问题）。

**解决路径（待实施）**：
- A（推荐）：patch `compile/src/v-pasystray/notify.c` 改 **GDBus 直发**（`g_dbus_connection_call_sync` 发 `org.freedesktop.Notifications.Notify`，复用 x-dunst notify-send 已验证实现），绕开 libnotify——静态栈 GDBus 直发已被证明工作。
- B：深修静态 libnotify/glib 的 GDBus connection（musl/静态下连接生命周期，成本高不确定）。
- 下一步：实施 A + 静态链验证 + rootfs-dbg（用户跑法）实跑确认通知弹出。

##### 3.6.2、根因修正与修复实施（2026-11-18）

**订正 3.6.1**：3.6.1 的「libnotify connection closed」是**连接失败的表现层**——**最终根因不是 libnotify**，是**会话 bus 与桌面应用 uid 不匹配**（libnotify/UPX/dunst/sink 均无辜，逐项实测排除过）。

**真因（实测钉死）**：
- 会话 `dbus-daemon`(357) 为 **root** 启动（父进程=1/perpd；模板本应 `gosu headless` 内起，实际 root——uid bug）。
- 桌面应用 `pasystray`/`pulse` 为 **headless**（openbox session 内，用户确认 pulse 在 headless 下正常）。
- **headless 连 root bus：EXTERNAL 认证拒绝**（gio 报 `The connection is closed`；dbus-send 报 `Did not receive a reply`）→ `notify_notification_show` 发不出 → 总线无 Notify → dunst 收不到 → 无通知。
- root 连 root bus：正常（`method return`）——三者对照锁定认证。

**验证链**：

| 连接 | 结果 |
|---|---|
| headless → root bus(357) | ❌ 认证拒绝（connection closed / Did not receive a reply） |
| root → root bus(357) | ✅ `method return`（ListNames 正常） |
| headless → 新起 headless bus | ✅ 连接成功（notify-send 发出，认证通过） |
| headless bus + headless dunst(带 DISPLAY) + headless notify-send | ✅ **通知显示**（diff bbox (221,2,530,93) + 773 色） |

**修复（用户拍板选 A）**：修 `entry.sh` / `tpl-rc.main` / `x10-de/rc.main` 里 `dbus-daemon` 启动**明确以 headless（+DISPLAY 环境）**起，让会话 bus 与桌面应用同 uid → 重构建 rootfs 镜像验证。备选 B（openbox autostart 起 headless bus + dunst 常驻）已证链路可行，未选。

##### 3.6.3、修复落地与 dunst 手动启动（2026-11-19）

**修复 A 已落地**：`rootfs/src/entry.sh`（x10-de 会话生成处）`dbus-daemon` 改为**明确 `gosu headless dbus-daemon --session`**（commit `293c5f5e`）——重建 rootfs 镜像后会话 bus 属 headless，桌面应用（headless）连接认证通过，通知链路恢复。

**根因实证补充（2026-11-19，前文之外）**：
- headless → root bus(357)：认证拒绝（`Did not receive a reply` / `The connection is closed`）；root → root bus：通过（`method return`）。
- 新起 `dbus-daemon --session`（无论 root bash 还是 headless bash 调）**均为 headless**（实测 1447/1478）——仅 16:31 容器启动早期的 357 为 root（异常：早期环境/rootfs 未就绪时 gosu 失效）。
- **libnotify 本身无辜**：test-notify（静态链 libnotify）在 **headless bus 下 `show rc=1`（成功）**；root bus 下 closed 只是认证失败的表现（非库问题）。

**dunst 手动启动命令（用户问「直接 dunst 命令不行」——缺环境）**：
```sh
su headless -s /bin/sh -c 'DISPLAY=:10 DBUS_SESSION_BUS_ADDRESS=<会话bus地址> nohup /usr/local/static/dunst/bin/dunst > /tmp/dunst.log 2>&1 &'
```
- 必须：`su headless`（用户）、`DISPLAY`（X）、`DBUS_SESSION_BUS_ADDRESS`（与通知发送方**同一会话 bus**——查 `ls /tmp/dbus-*` 或 `pgrep -af dbus-daemon` 取地址）、`nohup ... &`（后台）。
- 直接 `dunst`（root/缺 DISPLAY/缺 bus）会启动失败或没接管 `org.freedesktop.Notifications`，通知照旧丢失。

**待续**：重建 rootfs-dbg 镜像后用用户跑法验证滚轮通知；「第二层」（pasystray 滚轮在干净 headless 环境是否触发 notify——现容器多实例污染未钉死）待确认。

**第二层定论与修复验证通过（2026-11-19 补）**：
- 干净环境（单 dunst 6098 + 单 pasystray 6107，均为 headless、同一 headless bus）滚轮 → **通知区 diff bbox (301,15,535,89)、584 色——通知框正常渲染**（与 notify-send 显示同位置同特征）——**pasystray 滚轮 notify 触发正常**，之前 root bus 时「无 notify」全系第一层认证拒绝所致。
- **「bus 0 条 Notify」为 monitor 失效假象**：headless `su` 后台化 dbus-monitor 连上（NameAcquired）后即 NameLost 退出（`cm.log` 实证），monitor 未覆盖滚轮窗口——不可信。
- **完整根因 = 第一层（bus uid 错位）**，**修复 A（entry.sh dbus 明确 gosu headless）完整有效**（模拟修复环境全链路验证通过：headless bus + headless dunst + headless pasystray + 滚轮 → 通知显示）。
- **下一步**：重建 rootfs-dbg 镜像（entry.sh commit `293c5f5e` 生效）→ 用户跑法实跑验证。

##### 3.6.4、修复验证成功（重建 rootfs-dbg 镜像，2026-11-19）

**用户实跑确认**：重建 rootfs-dbg 镜像后，托盘图标滚轮调音量 → **通知正常弹出 —— 问题解决** ✅（修复 A：`entry.sh` dbus 明确 `gosu headless` 起，commit `293c5f5e`）。

**用户补充（印证根因）**：之前滚轮报错时，`DISPLAY` 与 `DBUS_SESSION_BUS_ADDRESS` 两个环境变量**都是有的**——不行的原因是 **dbus 当时是 root 跑的**（会话 bus root 属 + 桌面应用 headless → EXTERNAL 认证拒绝）——与 3.6.2/3.6.3 锁定的根因一致。

**dunst 手动启动命令（用户问，实测保存）**：
```sh
su headless -s /bin/sh -c 'DISPLAY=:10 DBUS_SESSION_BUS_ADDRESS=<会话bus地址> nohup /usr/local/static/dunst/bin/dunst > /tmp/dunst.log 2>&1 &'
```
- 必须 `su headless`（root 直接跑不行：连 headless 的 X/bus 认证/权限都不对）。
- `DISPLAY=:10`（X 显示号）。
- `DBUS_SESSION_BUS_ADDRESS` 必须与通知发送方（pasystray）**同一会话 bus**——`ls /tmp/dbus-*` 或 `pgrep -af dbus-daemon` 取。
- `nohup &` 后台；日志看 `/tmp/dunst.log`。
- 「直接 dunst 不行」= 缺 DISPLAY/bus/用户不对——dunst 启动失败或没接管 `org.freedesktop.Notifications`，通知照旧丢失。

#### 3.7、托盘图标悬停 tooltip 遮挡 dunst——`--no-icon-tooltip` 关闭（2026-11-20）

用户反馈（2026-11-20）：鼠标悬停托盘图标跳出信息框（连接状态 tooltip），与 dunst 通知区域互相遮挡，要屏蔽并问原生有无配置项。

**结论：原生有配置项**——`pasystray --no-icon-tooltip`（短参数 `-t`）关闭连接状态托盘图标 tooltip；`icon_tooltip` 默认 `TRUE`。

**源码依据**（pasystray 0.8.2，`compile/tarsrc/v-pasystray/`）：

- `src/options.c:33`：`static gboolean icon_tooltip = TRUE;`（默认开启）。
- `src/options.c:49-50`：`{ "no-icon-tooltip", 't', 0, G_OPTION_ARG_NONE, &icon_tooltip, "Disable the status icon tooltip for the connected state", NULL }`。
- `src/options.c:132`：`settings->icon_tooltip = icon_tooltip;`（仅 CLI，无 gconf 键持久化）。
- `src/pulseaudio.c:105`：`PA_CONTEXT_READY` 时 `if(mis->settings.icon_tooltip)` → `systray_impl_set_tooltip()`（`context_info_str` 的 server 信息，`systray_impl.c:156` `gtk_status_icon_set_tooltip_markup`）；else `systray_impl_set_has_tooltip(FALSE)`。
- 悬停框 = 连接状态 tooltip（显示 PulseAudio server 信息），正是 `--no-icon-tooltip` 关闭的对象。

**实测**：hdmi 发行版系统包 `/usr/bin/pasystray --help` 含 `-t, --no-icon-tooltip`；生产静态版同源码同样支持。

**应用方式**：

- 运行环境（hdmi/Ubuntu）：改 `/etc/xdg/autostart/pasystray.desktop` 的 `Exec=pasystray` → `Exec=pasystray --no-icon-tooltip`，`pkill pasystray` 重启生效。
- 生产 rootfs 静态版：启动加 `--no-icon-tooltip` 即可（同源码 0.8.2）。
- 注：只关**连接状态** tooltip；未连接瞬态 "connecting to server..."（`systray_impl.c:114`）与下拉菜单项 tooltip 不受控制（非悬停框场景）。

**拍板**：用户 2026-11-20 决定「只存文档」（本章 3 节下），运行环境（hdmi autostart）与生产 rootfs 落点**未改**，后续按需实施。

#### 3.8、订正：`--no-icon-tooltip` 上游是空转开关——根因、修复与实测（2026-11-20）

> **订正（2026-11-20）**：3.7 的「应用方式」结论作废。加 `--no-icon-tooltip` **无法关闭 tooltip**，原因是开关本身在上游就是无效的。

用户把 `pasystray --no-icon-tooltip` 加进生产 rootfs 的 openbox autostart 后，悬停托盘图标**仍弹信息框**（`ps -ef` 已确认参数在进程命令行上）。因此 3.7 的"加参数即可解决"不成立。

**根因**：`--no-icon-tooltip` / `-t` 在 pasystray 0.8.2 **就是空转的 no-op 开关**。

- `src/options.c:49-50` 把该开关（`G_OPTION_ARG_NONE`）直接绑定到 `src/options.c:33` 的 `static gboolean icon_tooltip`，而它**默认已是 `TRUE`**。
- GLib 的 `G_OPTION_ARG_NONE` 处理器是无条件 `*bool = TRUE`，**无法表达"未传"**——所以传了 flag，`icon_tooltip` 还是 `TRUE`（等于默认值），开关根本翻不过去。
- 于是 `src/options.c:132` 的 `settings->icon_tooltip = icon_tooltip;` 恒为 `TRUE`，`src/pulseaudio.c:105` 的 `if(mis->settings.icon_tooltip)` 永远走"设 tooltip"分支，`systray_impl.c:156` 的 `gtk_status_icon_set_tooltip_markup` 照常被调用。
- 已抓上游 `master/src/options.c` 逐行核对：**与我们 0.8.2 源码完全一致**，属上游 bug，不是本项目构建或部署问题。

**GLib 探针实测**（builder 容器内 gcc + glib-2.0 编译真跑，不靠推测）：同一程序放两个开关，A 绑 default-TRUE 变量（pasystray 现状写法）、B 绑 default-FALSE 变量（拟修复写法）。

| 命令行 | A（default-TRUE 变量） | B（default-FALSE 变量） |
| --- | --- | --- |
| `--no-icon-tooltip --no-flag` | 1 | 1 |
| `--no-icon-tooltip` | 1 | 0 |
| `-t` | 1 | 0 |
| （无参数） | 1 | 0 |

A 在"传"与"不传"下都是 1 —— 与 pasystray 现状行为完全吻合；B 才是正确语义。

**同时推翻上一轮的"启动环境差异"假设**：手动 `su` 起干净环境（只设 `DISPLAY/HOME/LANG`）、以及 autostart 环境，**都复现 tooltip**（悬停 19363 / 19487 字节，移开基线 11079 / 11233）。差异是测试假象，不是 autostart 环境变量（`GTK_IM_MODULE`/`XMODIFIERS`/`DBUS` 等）导致。

**修复**（已落代码，未推 CI）：

- 新增 `compile/src/v-pasystray/pasystray-no-icon-tooltip.patch`：新增 `static gboolean no_icon_tooltip = FALSE;`，开关改绑 `&no_icon_tooltip`，`parse_options()` 里改 `settings->icon_tooltip = !no_icon_tooltip;`。
- `compile/src/v-pasystray/build.sh`：在 glade-types、i18n 之后应用第 3 个 patch。

**全链路实跑验证**（`alpine-builder-gtkmm224-2` 起临时容器 `builder-mm224`，`/src` 软链宿主；`x-pulseaudio` 静态栈 126s、`PULSE_RC=0`，`pasystray` 10s，`xx-verify --static` 通过、`0` 个 undefined reference、patch 确认落在 `src/options.c:34/51/133`）：

| 二进制 | 参数 | 悬停截图 | 移开基线 | 结论 |
| --- | --- | --- | --- | --- |
| CI 旧件（5733608B，`md5 20a45bfa...`，Nov 20 10:30） | `--no-icon-tooltip` | 19363 / 19487 | 11079 / 11233 | **仍有 tooltip（bug）** |
| 修复后（14046968B，`md5 06d0d08c...`） | `--no-icon-tooltip` | **11229** | **11229** | **无 tooltip ✅** |
| 修复后 | （不带参数） | 19541 | 11299 | 默认 tooltip 保留 ✅ |

验证环境：`rootfs-dbg` 最新镜像（Digest `22c90072fa86`）容器 `rootfs-dbg-latest`，Xvnc `:10` 1024x768，tint2 托盘，托盘图标窗口 `6291459 @ (977,745) 19x19`。截图用 `scrot`，宿主无 PIL/ImageMagick，**比字节数**即能判定有无 tooltip（有 ≈19KB，无 ≈11KB）。

旁证：托盘图标仍渲染、右键菜单正常弹出（截图 11299 → 31995 字节）、`share/locale/zh_CN/LC_MESSAGES/pasystray.mo` 未受影响。

**产物体积**：本地全量静态链接 14046968B，CI 镜像内为 5733608B——**不用管**，CI 到 rootfs 后有 upx 压缩（用户 2026-11-20 澄清），非缺链接。

**生效路径**：patch 随 CI 重建 rootfs 镜像后，生产 autostart 里已有的 `pasystray --no-icon-tooltip &`（`~/.config/openbox/autostart:73`）才真正生效；本 3.7 的 hdmi autostart 改法同理，需等 CI 新产物。

#### 3.9、pavucontrol 最新支持 GTK2 版本评估（2026-11-23）

**结论**：pavucontrol 最新支持 GTK2 的版本 = **3.0**（项目当前版本，**无更高可升**）。

**实测**（gitlab.freedesktop.org/pulseaudio/pavucontrol 各 tag 查 configure.ac）：

| 版本 | GTK/gtkmm 依赖 | GTK 世代 |
|---|---|---|
| 3.0（项目当前） | `AC_ARG_ENABLE(gtk3, --disable-gtk3)`：默认 `gtkmm-3.0 ≥ 2.99`；**`--disable-gtk3` → `gtkmm-2.4 ≥ 2.16`**（configure.ac:43-62） | **GTK2（--disable-gtk3）+ 默认 GTK3** |
| 4.0 | `PKG_CHECK_MODULES(GUILIBS, [ gtkmm-3.0 >= 3.0 sigc++-2.0 libcanberra-gtk3 >= 0.16 ])` | **只 GTK3** |
| 5.0 | `gtkmm-3.0 ≥ 3.22 ... json-glib-1.0` | GTK3 |
| 6.2（上游最新） | gtkmm-3.0 | GTK3 |

**要点**：

- 3.0 是最后支持 GTK2 的版本：configure.ac 保留 `AC_ARG_ENABLE(gtk3, --disable-gtk3)` 双选（默认 gtk3=yes，--disable-gtk3 走 gtkmm-2.4 分支）；**4.0 起强制 GTK3**（`PKG_CHECK_MODULES(gtkmm-3.0)`，无 --disable-gtk3 / gtkmm-2.4 分支）。
- **3.0 系列确认无更高小版本**：`git ls-remote --tags` 仅 v3.0（无 v3.0.1/v3.0.x），3.0 系列就一个版本。
- 项目当前 `3.0` 已是**最后/最高支持 GTK2 的版本**（build.sh 注释「版本 3.0 = 最后 GTK2 版（--disable-gtk3 走 gtkmm-2.4 分支）」经源码独立确认），**无需升级**。
- 后续版本（4.0+/5.0/6.2）全 GTK3，项目用不上。

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

### 1、mime 数据（gdk-pixbuf 图标/格式识别）

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

### 1、中文显示（gettext 本地化）

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
