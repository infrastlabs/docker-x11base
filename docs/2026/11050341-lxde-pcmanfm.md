# lxde-pcmanfm：新 gtk 库环境下静态构建与 Greybird+Papirus 验证

> 2026-11-05 调试记录。目标：在**新 gtk 库**（已内置 svg loader + pixmap 引擎 + murrine + GModule 判空修复，见 260926 文档 3.6/3.7）环境下，用 `compile/src/v-pcmanfm/build.sh` 构建 **pcmanfm**（LXDE 文件管理器）静态产包，配 Greybird + Papirus 主题图标截图验证。

## 一、调试过程

### 1.1、前置检查（builder-awe 容器库状态）

| 库 | 状态 | 说明 |
|---|---|---|
| `/usr/lib/libgtk-x11-2.0.a` | ✅ 9.3M | 含 `theme_init`（murrine）+ `pixmap_theme_init`（pixmap 引擎） |
| `/usr/lib/libgdk_pixbuf-2.0.a` | ✅ 1.3M | 含 `_gdk_pixbuf__svg_fill_vtable`（builtin svg loader） |
| `/usr/lib/libgdk-x11-2.0.a` | ✅ 1.2M | — |
| `/usr/local/lib/librsvg-2.a` | ✅ 2.1M | svg loader 依赖 |
| `/usr/local/lib/libcroco-0.6.a` | ✅ 437K | svg loader 依赖 |
| `/usr/lib/libfm.a` `/usr/lib/libfm-gtk.a` `/usr/lib/libmenu-cache.a` | ❌ **未装** | pcmanfm 依赖，需先 b_deps |

### 1.2、build.sh 修改（pcmanfm 静态链接依赖，同 lxtask 问题）

`v-pcmanfm/build.sh` 的 `pcmanfm()` 在**新库**下会链接失败（缺新库引入的依赖），参照 v-lxde 的 lxtask 修复：

1. `OB_LIBS`（`:168`）加 **`-lXcursor`**（gdkcursor-x11.o 的 Xcursor* 符号）。
2. `LIBS0`（`:172`）加 **`-lrsvg-2 -lcroco-0.6`**（gdk-pixbuf 内置 svg loader 后 librsvg 依赖）。

### 1.3、b_deps（libfm + menu-cache）

- `bash v-pcmanfm/build.sh b_deps`：先 `apkdeps`（apk 装 gtk-doc/intltool/vala/menu-cache-dev 等），再 `libfm`（gitee fk-libfm 1.3.2）、再 `menu-cache`（gitee fk-menu-cache）。
- 进展：libfm 编译中（base/job 目录完成，gtk 子目录进行，~147 个 .o）；menu-cache 未开始。
- 日志：`/root/build_pcmanfm_deps.log`。

### 1.4、构建结果与产包验证

- `bash v-pcmanfm/build.sh b_deps`：libfm（1.3.2，gitee fk-libfm）+ menu-cache（gitee fk-menu-cache）编译安装成功，`/usr/lib/libfm.a`(541K)/`libfm-gtk.a`(768K)/`libmenu-cache.a`(36.3K) 就位。
- `bash v-pcmanfm/build.sh pcmanfm`（`GITHUB=ghfast.top` 镜像）：**首次链接失败** `undefined reference to XRenderCreateCursor/XRenderCreateAnimCursor`（libfm-gtk 的 cursor.o 引用 Xrender，但 `-lXrender` 在 `-lfm-gtk` 之前且 make 无 `--start-group` 循环解析）→ 修复：
  1. `make LIBS` 加 `-Wl,--start-group ... -Wl,--end-group`（静态库循环引用，同 lxtask）。
  2. `make` 加 `|| { log "PCMANFM build FAILED"; exit 1; }`（原脚本无失败检查，链接失败被忽略——`err 0, pass` 假象）。
- **重跑成功**：产包 `/usr/local/static/pcmanfm/bin/pcmanfm` **43.4M**，`xx-verify --static` **通过**。
- nm 确认产包含：`theme_init`(murrine)、`pixmap_theme_init`(pixmap 引擎)、`_gdk_pixbuf__svg_fill_vtable`(svg loader)、`gdk_pixbuf_loader_get_format`、`rsvg_handle_new`。

### 1.5、runtime 验证（Greybird + Papirus-Bunsen-bluegrey）

- runtime 容器 `docker-hdmi-desktop-desktop-1`，Xvnc :349，`HOME=/root`、`GTK2_RC_FILES=/root/.gtkrc-2.0.v3`（include Greybird + `gtk-icon-theme-name=Papirus-Bunsen-bluegrey`）。
- pcmanfm 显示 `/root` 目录，stderr：**无 unknown engine "pixmap"、无 GModule-CRITICAL、无 Unable to locate**（仅 benign 的 `~/Templates 不存在`/`modules directory 不可访问` 警告）。
- 截图裁剪 640×480，像素分析：**6 行独立 Papirus 蓝紫/蓝绿文件夹图标**（y 簇 63-98/135-170/.../423-458，间隔 72px，27460 蓝色像素），图标渲染正常。
- 截图：`docs/img/tmp/lxde-pcmanfm/pcmanfm-greybird-papirus.png`。

### 1.6、变更文件（本次）

| 文件 | 说明 |
|---|---|
| `compile/src/v-pcmanfm/build.sh` | pcmanfm 静态链接：OB_LIBS 加 `-lXcursor`、LIBS0 加 `-lrsvg-2 -lcroco-0.6`、make 加 `--start-group` + `||` 失败检查 |
| `docs/2026/261105-lxde-pcmanfm.md` | 本调试记录 |
| `docs/img/tmp/lxde-pcmanfm/pcmanfm-greybird-papirus.png` | 截图（Greybird + Papirus） |

## 二、三个问题复现与根因分析（2026-11-05 复现）

### 2.1、复现、日志与根因（含 APT 无问题 / lxtask About 正常 判别）

**复现环境**：hdmi 容器 `docker-hdmi-desktop-desktop-1`，Xvnc `:463`（1280x800）+ openbox（静态），二进制 `/tmp/pcmanfm_bs`（静态 GTK2 43.4M，含 murrine/pixmap/svg loader/rsvg，见 1.5）。三问题均复现：

| 问题 | 复现证据 |
|---|---|
| **1. 菜单 About 卡住不出框** | 点击 Help→About 后 GtkAboutDialog 被创建（`MODAL`+`UTILITY`+`TRANSIENT`），但 **`IsUnMapped`（从未映射显示）**，尺寸坍缩 **170×37**，定位屏幕外 `(1281,-38)`；强制 `windowmap` 也无效；进程 `poll`（非死锁） |
| **2. 右键打开卡住**（含 applications 目录 .desktop） | 右键菜单**能正常弹出**（132×234）；点 Open 后日志出现整串 Gtk-CRITICAL 断言；默认打开仍能启 Geany（`defaults.list`），但对话框创建失败 |
| **3. 关窗口不死进程** | `--desktop` 关主窗口（WM_DELETE）后进程仍在（`Sl`/poll，窗口已销毁），SIGTERM 可杀（非死锁）；但 X 断开场景残留进程 SIGTERM 不杀，主线程卡 **`pipe_wait/pipe_read`** |

**问题 2 点 Open 的完整断言链**（一个 GtkDialog 及其全部子控件对象类型无效）：

```
Gtk-CRITICAL: IA__gtk_image_set_from_gicon:         assertion 'GTK_IS_IMAGE (image)' failed
Gtk-CRITICAL: IA__gtk_dialog_get_action_area:       assertion 'GTK_IS_DIALOG (dialog)' failed
Gtk-CRITICAL: IA__gtk_box_set_homogeneous:          assertion 'GTK_IS_BOX (box)' failed
Gtk-CRITICAL: IA__gtk_dialog_set_default_response:  assertion 'GTK_IS_DIALOG (dialog)' failed
Gtk-CRITICAL: IA__gtk_label_set_text:               assertion 'GTK_IS_LABEL (label)' failed
Gtk-CRITICAL: IA__gtk_dialog_run:                   assertion 'GTK_IS_DIALOG (dialog)' failed
Gtk-CRITICAL: IA__gtk_widget_destroy:               assertion 'GTK_IS_WIDGET (widget)' failed
```

`GTK_IS_DIALOG` 失败 → **dialog 对象本身无效（NULL/坏指针）**，后续所有操作全断言失败。问题 1 的 About 同样是 GTK 对话框创建/显示异常（内容坍缩 + 不映射）。

**关键判别（修正根因方向）**：

- **APT（Ubuntu 动态 libgtk）版本无这 3 个问题** → 非 pcmanfm 源码逻辑 bug，是**静态链接环境**相关。
- **lxtask About 正常**（同一套静态 GTK 库）→ 静态 GTK 库本身的 About 对话框**能工作** → 问题**不在静态 GTK 库**，而在 **pcmanfm/libfm 特定**（libfm/libfm-gtk 静态链入的对话框路径，或 pcmanfm 与 libfm 的 GTK 交互）。
- 修正：之前"GTK 静态库通用问题"假设不成立；根因应落在 **libfm（对话框/打开流程）+ 静态链接** 的交叉点。

**待验证**（下一步）：
1. `gdb call gtk_dialog_new()` 验证是否返回 NULL（对象创建失败 vs 类型注册错乱）。
2. 定位失败对话框是 libfm 的 `fm_dialog`/`fm_app_info` 路径还是 pcmanfm 直接 `gtk_show_about_dialog`。
3. 检查 libfm 静态链接是否引入**第二套 GTK 符号**（`nm pcmanfm_bs | grep gtk_dialog_get_type` 已确认单一，需进一步查 libfm 编译时是否用了不同 GTK）。

### 2.2、根因实证（gdb 栈 + 反汇编 + strings 三重锁定，2026-11-05）

**排除项**（`gdb call gtk_dialog_new()`）：
- `gtk_dialog_new()` 返回**有效指针**，`g_type_name` 全正确（GtkDialog/GtkAboutDialog）→ GTK 库/类型系统**正常**，排除"静态 GTK 库损坏"假设。
- 根因落在**对话框创建前的 UI 加载**环节。

**gdb 栈实证**：断 `g_return_if_fail_warning` 抓到首个断言调用栈：
```
#0  g_return_if_fail_warning
#1  on_exec_file            (0x4a6e65, pcmanfm 菜单激活回调)
#2  fm_launch_files         (libfm)
#3  (菜单激活)
```
→ 断言发生在 `on_exec_file`（pcmanfm 打开流程）→ 确认走 libfm 的 `fm_launch_files`，**非** `gtk_show_about_dialog`。

**反汇编实证**（`on_exec_file`）：
```
gtk_builder_new          → gtk_builder_add_from_file   → gtk_builder_get_object   → gtk_image_set_from_gicon (首个断言)
```
→ GtkBuilder 从文件构建 UI 失败 → `get_object` 返回 NULL → 对话框及子控件全无效。

**strings 实证**（硬编码路径）：
```
/usr/local/static/pcmanfm/share/pcmanfm/ui/about.ui
/usr/local/static/pcmanfm/share/pcmanfm/ui/open-with.ui
```
→ 静态二进制编译时硬编码 `TARGETPATH/share/pcmanfm/ui/*.ui`（configure `--prefix`）；hdmi 容器该目录**不存在**，实际 UI 在 `/usr/share/pcmanfm/ui/`（apt 版路径）。

**根因定论（问题 1+2 同根因，2026-11-05 修正）**：**静态链接 gc-sections/--as-needed 裁剪了 `gtk_type_init` 的 GTK 类型注册调用**——`g_type_from_name("GtkDialog")=0`、`"GtkAboutDialog"=0`（**未注册**），但 `"GtkWindow"` 非0（已注册）。GtkBuilder 解析 `<object class="GtkAboutDialog">` → `gtk_builder_real_get_type_from_name` 调 `g_module_symbol(module=NULL,"gtk_about_dialog_get_type")` → module=NULL 断言 → `gtk_builder_add_from_file` 返回 **0** → `gtk_builder_get_object` 返回 NULL → 对话框对象无效 → `GTK_IS_*` 断言全链失败。**次要因素**：UI 文件硬编码路径 `TARGETPATH/share/pcmanfm/ui/` 在目标容器缺失（产包只拷 bin 未拷 share）。

**问题 1+2 修复验证成功（2026-11-05 重编）**：pcmanfm.c 加 `g_type_ensure(gtk_dialog_get_type())` 等强制注册（patch `pcmanfm-staticfix.patch`）+ 拷入 `TARGETPATH/share/pcmanfm/ui/*.ui`（pcmanfm）+ `/usr/local/share/libfm/ui/*.ui`（libfm，exec-file 等）后：
- `g_type_from_name("GtkDialog")`/`"GtkAboutDialog"` 均**非0**（已注册）
- `gtk_builder_add_from_file(about.ui)` 返回 **1**（加载成功）
- `on_about` → `gtk_window_present` 被调用（About 显示成功）
- 右键 Open → **Execute File 对话框 582×106 IsViewable**（exec-file.ui 正常渲染，无断言链）

**问题 3 独立成因**：见 2.3（信号 pipe 读端阻塞 → on_unix_signal 死锁 → SIGTERM 不杀），与 UI 路径缺失**无关**。

**修复方案（问题 1+2）**（已落地，见 `pcmanfm-staticfix.patch` + build.sh）：
1. **类型注册（根本）**：build.sh 在 `git clone` 后 `git apply pcmanfm-staticfix.patch`——pcmanfm.c 在 `gtk_init_with_args` 后 `g_type_ensure(gtk_dialog_get_type())` 等强制注册 GTK 类型。
2. **产包 UI**：`make install --prefix=$TARGETPATH` 已装 UI 到 `TARGETPATH/share/pcmanfm/ui`；**打包时须整体拷贝 `$TARGETPATH`（含 share）**，并拷 `/usr/local/share/libfm/ui`（libfm 的 exec-file/file-prop 等）。
3. **备选**：容器内 symlink `/usr/local/static/pcmanfm/share/pcmanfm/ui → /usr/share/pcmanfm/ui`。

**同类问题**：同为 GTK2 静态的 **lxtask About 已确认正常**（排除）；仍需冒烟测 lxtask 的**确认/打开对话框**（非 About）及 `v-tint2` 对话框。

### 2.3、问题 3 根因实证（信号 pipe 读端阻塞，2026-11-05）

**精确复现**：`/tmp/pcmanfm_bs --desktop`（Xvnc :463 + openbox），关闭桌面窗口（WM_DELETE）后**进程仍活**；实测**无 gdb 时 SIGTERM 也杀不死**（多实例 683161/683905/684535/684964 均复现），且**窗口模式（非 `--desktop`）关窗口后进程正常退出**（682046）。

**判别**：
- **APT（1.3.2 动态）`--desktop` 关窗口后进程也活**，但 **SIGTERM 能杀**（682807 实测退出）→ "关窗口自动退出"非 APT/静态差异；差异在 **SIGTERM 是否生效**。
- **lxtask 关闭正常**（无信号 pipe 机制，标准 destroy→gtk_main_quit）→ 排除静态 GTK 通用问题。
- **版本非根因**：1.3.1 与 1.3.2 的 `unix_signal_handler`/`on_unix_signal`/`pcmanfm_unref`/`delete_event` 逻辑**逐行相同**（行号仅差几行）。

**根因机制**（pcmanfm 信号 pipe 优雅退出路径）：
```
signal(SIGTERM, unix_signal_handler)          →  handler 只 write(signal_pipe[1], &sig, 4)
pipe(signal_pipe) → g_io_add_watch(signal_pipe[0], G_IO_IN|G_IO_PRI, on_unix_signal)
on_unix_signal → g_io_channel_read_chars → read(signal_pipe[0]) → 读到则 gtk_main_quit()
```

**实证链**（gdb + /proc）：
- `signal_pipe = {6, 7}`（gdb `x/2dw`），fd6 读端 / fd7 写端，**同一 pipe inode**（ls `/proc/PID/fd`）。
- handler **确实被调用**（gdb 断 `unix_signal_handler` 命中，栈 `<signal handler called>`）；反汇编：`write(fd=signal_pipe[1]=7, count=4)`，断点处 `rax=4`（**写入成功**）。
- **主线程卡死**：`/proc/PID/syscall` = `read(0x6, buf, 0x400)`，栈 `on_unix_signal → g_io_channel_read_chars → g_io_unix_read → read(fd6)` **阻塞**。
- `gdb call poll(&pf,1,0)` → **0 / revents=0x0**（fd6 **无数据可读**）→ read 卡在**空 pipe**。
- **反汇编 on_unix_signal 无 while 循环**（只一次 `g_io_channel_read_chars`）→ 卡在唯一 read。

**根因定论**：`g_io_channel_unix_new(signal_pipe[0])` 后**未设非阻塞**（源码无 `g_io_channel_set_flags(...NONBLOCK)`），fd6 保持**阻塞**（`F_GETFL=0x8000`，nonblock=False 实测）。SIGTERM → handler write(fd7) 成功 → 主循环 dispatch `on_unix_signal`，但 `read(fd6)` 在**阻塞 fd 上空管道卡死**（poll 唤醒与数据就绪竞态），`gtk_main_quit()` 永不执行 → **SIGTERM 杀不死**。静态 musl glib 2.70 复现；APT（Ubuntu glib）gIoChannel 行为不同，read 正常返回。

**修复验证成功**：`gdb call fcntl(6, F_SETFL, O_NONBLOCK)`（返回 0）后，**进程立即正常退出**（684964 确认）→ read 不再阻塞 → `gtk_main_quit` 生效。**"读端非阻塞"是修复关键**。

**修复方案（问题 3）**：在 pcmanfm 源码 `pcmanfm.c` 信号注册处，给读端设非阻塞：
```c
if(pipe(signal_pipe) == 0)
{
    GIOChannel* ch = g_io_channel_unix_new(signal_pipe[0]);
    g_io_channel_set_flags(ch, G_IO_FLAG_NONBLOCK, NULL);   /* 关键修复 */
    g_io_add_watch(ch, G_IO_IN|G_IO_PRI, (GIOFunc)on_unix_signal, NULL);
    g_io_channel_unref(ch);
    signal(SIGHUP, unix_signal_handler);
    signal(SIGTERM, unix_signal_handler);
    signal(SIGINT, unix_signal_handler);
}
```
（或 `fcntl(signal_pipe[0], F_SETFL, O_NONBLOCK)`。）注意：`--desktop` 关窗口后进程**不自动退出是设计行为**（desktop_running=1 保持 ref），SIGTERM 应能杀即可；若需关窗口即退，需另处理 `pcmanfm_unref` 逻辑。

## 三、复现→定位→解决的调试技巧 / 避坑项（2026-11-05 总结）

> 本节沉淀本次调试 pcmanfm 三个问题时用到的技巧与踩过的坑，供后续同类问题复用。

### 3.1、进程控制与容器坑

| # | 坑 / 技巧 | 说明 |
|---|---|---|
| 1 | **`pkill -f` 自杀坑** | `pkill -f "pcmanfm_bs --desktop"` 会匹配 `docker exec` 自身命令行（含同样字符串），导致**自杀**（exit -1）。应改用 `pkill -x pcmanfm_bs`（精确进程名匹配）。 |
| 2 | **docker exec 后台进程不存活** | `docker exec` 内 `setsid nohup xxx &` 在 exec 结束后子进程仍被杀。应改用 `docker exec -d` 启动持久后台进程。 |
| 3 | **跨 exec 变量丢失** | PID/WIN 等变量**不跨 `docker exec` 保留**。须写入文件（如 `/tmp/x.pid`）或单次 exec 内完成整个流程。 |
| 4 | **gdb 下 SIGTERM 干扰** | gdb 调试时 SIGTERM 会直接终止程序（`Program terminated with signal SIGTERM`）。须先 `handle SIGTERM nostop noprint pass`。 |

### 3.2、快速定位阻塞 / 标志状态的技巧

| # | 技巧 | 说明 |
|---|---|---|
| 5 | **`/proc/PID/syscall` 定位阻塞** | `cat /proc/PID/syscall` 显示当前阻塞系统调用（如 `read(0x6,...)` = read(fd6)），比 `bt` 更快定位；多线程用 `cat /proc/PID/task/*/syscall`。 |
| 6 | **`/proc/PID/fdinfo` + python fcntl 查 O_NONBLOCK** | 用 `fcntl(fcntl.F_GETFL, fd)` 判断阻塞标志（如 0x8000 → nonblock=False），实证"fd6 阻塞"。 |
| 7 | **gdb 设非阻塞即验证根因** | `gdb call fcntl(6, F_SETFL, O_NONBLOCK)`（返回 0）后进程立即正常退出 → **实证"读端阻塞是根因"**。这是最快根因验证法。 |
| 8 | **gdb call 触发静态函数** | `call (void)on_about(0,0)` 直接调用静态函数，绕过 UI 导航验证。 |
| 9 | **gdb 断点 + finish 取返回值** | `break gtk_builder_add_from_file` + `call on_about(0,0)` + `finish` + `p $eax`（0=失败、1=成功）判定加载结果。 |
| 10 | **gdb 反汇编看参数/分支** | `disassemble unix_signal_handler` 看 `write` 参数；`disassemble on_unix_signal` 看 `read` 返回值分支。 |

### 3.3、判别静态裁剪 / 排除干扰

| # | 技巧 | 说明 |
|---|---|---|
| 11 | **`g_type_from_name` 判别类型注册** | `g_type_from_name("GtkDialog")=0` 但 `GtkWindow` 非 0 → 同文件**部分类型未注册**，指向静态 `--gc-sections` 裁剪。 |
| 12 | **版本对照排除差异** | 拉 1.3.1 / 1.3.2 源码逐行 `diff`（`unix_signal_handler`/`on_unix_signal` 相同）→ 排除版本差异；APT 版（动态 glib）作对照组确认差异在**静态**构建。 |
| 13 | **补丁生成避坑** | 宿主无 `patch` 命令，用 `git apply --check` 校验；手动 write 补丁易 corrupt，改用「源码树改代码后 `git diff` 生成规范补丁」。 |

### 3.4、UI 测试与截图坑

| # | 坑 / 技巧 | 说明 |
|---|---|---|
| 14 | **xdotool 操作坑** | `windowactivate` 在 openbox 不支持（_NET_ACTIVE_WINDOW）；改用 `windowfocus` + `mousemove` 替代；`windowclose` 发 WM_DELETE。 |
| 15 | **截图提交** | `import -window root` 截图，图片**单独 commit**（避免与 md 混提）。 |

### 3.5、一句话根因（速查）

- **问题 1+2**：静态 `--gc-sections` 裁剪未引用的 GTK 类型注册（`GtkDialog`/`GtkAboutDialog` 未注册）→ `gtk_builder_add_from_file` 加载对话框失败。修复：`g_type_ensure(...)` 强制注册 + UI 路径补齐。
- **问题 3**：信号 pipe 读端未设非阻塞（fd6 阻塞）→ `on_unix_signal` 卡 `read(fd6)` 空管道 → SIGTERM 杀不死。修复：`g_io_channel_set_flags(NONBLOCK)`。

## 四、深入挖掘：同类问题与潜在优化（2026-11-05）

### 4.1、同类问题：`--gc-sections` 裁剪的更多 GTK 类型（gdb 实证）

> 初步验证 3 个问题已解决后，对运行中的 pcmanfm_bs 用 gdb `g_type_from_name()` 逐一检查 **13 个 UI 文件用到的全部 33 个 GTK 类型**的注册状态，发现**同类问题（问题 1 根因）仍大量存在**。

#### 4.1.1、未注册类型（`g_type_from_name` 返回 0）

静态 `--gc-sections` 还裁剪了 **11 个 GTK 类型**（C 代码未直接引用 → 类型注册代码被裁剪）：

| 未注册类型 | 使用它的 UI 文件 |
|---|---|
| `GtkComboBox` | connect / desktop-pref / pref / file-prop / preferred-apps |
| `GtkTable` | connect / desktop-pref / pref / file-prop / filesearch / progress |
| `GtkColorButton` | desktop-pref |
| `GtkFontButton` | desktop-pref |
| `GtkFileChooserButton` | desktop-pref |
| `GtkHScale` | pref |
| `GtkFileChooserWidget` | choose-icon |
| `GtkIconView` | choose-icon |
| `GtkCalendar` | filesearch |
| `GtkProgressBar` | progress |
| `GtkTextView` | progress |

#### 4.1.2、8 个对话框加载失败（`gtk_builder_add_from_file` 返回 0）

gdb 实测每个 UI 的加载返回值（0=失败）：

| UI 文件 | 对话框 | 结果 | 缺失类型 |
|---|---|---|---|
| `about.ui` | About | ✅ 1 | （已修复） |
| `autorun.ui` | 自动运行 | ✅ 1 | — |
| `app-chooser.ui` | 打开方式 | ✅ 1 | — |
| `ask-rename.ui` | 重命名 | ✅ 1 | — |
| `exec-file.ui` | 执行文件 | ✅ 1 | （已修复） |
| **`pref.ui`** | **偏好设置** | ❌ **0** | GtkComboBox/GtkTable/GtkHScale |
| **`desktop-pref.ui`** | **桌面偏好** | ❌ **0** | GtkComboBox/GtkTable/GtkColorButton/GtkFileChooserButton/GtkFontButton |
| **`connect.ui`** | **连接** | ❌ **0** | GtkComboBox/GtkTable |
| **`file-prop.ui`** | **文件属性** | ❌ **0** | GtkComboBox/GtkTable |
| **`filesearch.ui`** | **文件搜索** | ❌ **0** | GtkTable/GtkCalendar |
| **`preferred-apps.ui`** | **首选应用** | ❌ **0** | GtkComboBox |
| **`progress.ui`** | **进度** | ❌ **0** | GtkTable/GtkProgressBar/GtkTextView |
| **`choose-icon.ui`** | **选择图标** | ❌ **0** | GtkFileChooserWidget/GtkIconView |

> ⚠️ **偏好设置、桌面偏好、文件属性、连接、搜索、首选应用、进度、选择图标**这些对话框当前**都打不开**，与最初问题 1（About 卡住）是**同一根因**（gc-sections 裁剪类型注册）。

#### 4.1.3、修复可行性（已验证）

- **10/11 类型可直接修复**：符号在二进制里（`nm` 确认 `gtk_combo_box_get_type` / `gtk_table_get_type` / `gtk_hscale_get_type` / `gtk_color_button_get_type` / `gtk_font_button_get_type` / `gtk_file_chooser_widget_get_type` / `gtk_icon_view_get_type` / `gtk_calendar_get_type` / `gtk_progress_bar_get_type` / `gtk_text_view_get_type`），用 `g_type_ensure(gtk_xxx_get_type())` 强制注册即可（同问题 1 修复法）。
  - **已实测**：gdb 注册 GtkComboBox/GtkTable/GtkHScale 后，**`pref.ui` 加载成功（返回 1）** ✅。
- **1 个特殊**：`GtkFileChooserButton` 的 `get_type` 符号**被完全裁剪**（`nm` 无 `gtk_file_chooser_button_get_type`，gdb `info functions` 亦无），无法用 `g_type_ensure` 直接引用。需链接期保留（`--whole-archive` / 调整 `--gc-sections`）或改用 `GtkFileChooserWidget`。

#### 4.1.4、其他发现 / 可优化项（次要）

- **问题 3 同类**：已复查完毕，见 4.1.7（发现 single-inst.c client socket 未设非阻塞，1 处风险）。
- **二进制 45MB 未 strip**：含符号便于 gdb；可 `strip` 减至 ~8-10MB 分发（牺牲调试能力，二选一）。
- **桌面纯黑**：无壁纸（Greybird 默认背景），可配 `--set-wallpaper`。
- **关窗不退出**：`--desktop` 关窗不自动退是**设计行为**（desktop_running=1 保持 ref），非 bug。

#### 4.1.5、修复实现（2026-11-05 开工）

在 `pcmanfm.c` 现有 `g_type_ensure` 基础上，追加注册 **11 个类型**（`pcmanfm.c:230` 起）：

```c
g_type_ensure(gtk_combo_box_get_type());
g_type_ensure(gtk_table_get_type());
g_type_ensure(gtk_hscale_get_type());
g_type_ensure(gtk_color_button_get_type());
g_type_ensure(gtk_font_button_get_type());
g_type_ensure(gtk_file_chooser_button_get_type());
g_type_ensure(gtk_file_chooser_widget_get_type());
g_type_ensure(gtk_icon_view_get_type());
g_type_ensure(gtk_calendar_get_type());
g_type_ensure(gtk_progress_bar_get_type());
g_type_ensure(gtk_text_view_get_type());
```

> **关键**：`GtkFileChooserButton` 的 `get_type` 在旧二进制里被完全裁剪（`nm` 无符号）；但只要**源码引用** `gtk_file_chooser_button_get_type()`，链接器会从 libgtk 静态库保留该对象文件，符号即存在。故 11 个类型**均可用同法修复**（无需 `--whole-archive`）。

构建：builder-awe `/tmp/pcmanfm` 内增量 `make LDFLAGS="-static" LIBS=...`（保留此前 staticfix 补丁 + FIX2，不重新 clone）。

#### 4.1.6、验证结果（gdb 实证 + 真实对话框）

- **gdb `gtk_builder_add_from_file` 全部 13 个 UI 均返回 1**（此前 8 个为 0）✅：
  `about / autorun / connect / desktop-pref / pref / app-chooser / ask-rename / choose-icon / exec-file / file-prop / filesearch / preferred-apps / progress`
- **真实对话框**：gdb `call on_preference(0,0)` 触发偏好设置，`Preferences` 窗口成功弹出（**627×519**，截图 `docs/img/tmp/lxde-pcmanfm/pcmanfm-pref-ui.png`）✅。
- 新二进制 `nm` 确认含全部 11 个 `gtk_xxx_get_type` 符号（含 `gtk_file_chooser_button_get_type` @0x51997c）。

#### 4.1.7、问题 3 同类复查与其他发现（2026-11-05 复查完成）

**复查范围**：在 pcmanfm + libfm 全源码范围复查问题 3 同类根因（`GIOChannel`/pipe/socket 未设非阻塞）。

**结论：1 处同类风险（single-inst.c）**

- **pcmanfm.c 信号 pipe 已修复**：`pcmanfm.c:265` 读端已加 `G_IO_FLAG_NONBLOCK`（见 2.3），问题 3 闭环，无需再动。
- **libfm 库干净**：libfm 全库无 `g_io_channel` / `socket` / `accept` / `pipe` 调用，无同类风险。
- **⚠️ 单实例 client socket 未设非阻塞（`single-inst.c:379` 附近）**：
  - 单实例 client 连接的 `g_io_channel_unix_new` 之后**未设 `G_IO_FLAG_NONBLOCK`**。
  - `on_client_socket_event` 的 `read_chars` 循环在**阻塞** socket 上读取；若 client 进程异常退出（fclose 前被杀 / 写入中断），主循环可能卡在 read → **症状与问题 3 一致（UI 冻结）**。
  - **建议修复**：两处 `g_io_channel_unix_new`（server + client）后各加 `g_io_channel_set_flags(ch, G_IO_FLAG_NONBLOCK, NULL)`，使 read 返回 `G_IO_STATUS_AGAIN` 而非阻塞。
  - **严重度**：中等。触发条件较苛刻（需 client 写连接后异常退出），实际低概率，但属**同类根因**，建议随下次改动一并修复。

**其他确认无问题 / 可优化项**

- 资源无泄漏：`single_inst_client_free` 正确释放 channel + socket。
- `PACKAGE_UI_DIR` 硬编码 `/usr/local/static/pcmanfm/share/pcmanfm/`：仅影响跨前缀分发，非 bug。
- 壁纸 / 关窗不退出见 4.1.4。

## 五、builder-pav 容器内按 Dockerfile 方式重跑（2026-11-12）

### 5.1、调用方式（参考 Dockerfile lxde / pcmanfm stage）

- **lxde stage**（Dockerfile 352-366 行）：`ENV CONSOLE_LOG=no TARGETPATH=/usr/local/static/lxde` → `sh /src/v-lxde/build.sh lxtask`
- **pcmanfm stage**（368-380 行）：`ENV CONSOLE_LOG=no TARGETPATH=/usr/local/static/pcmanfm` → `bash /src/v-pcmanfm/build.sh b_deps` → `bash /src/v-pcmanfm/build.sh pcmanfm`
- builder-pav（`alpine-builder-gtkmm224-2`，与 Dockerfile `base` 同镜像）内 `/src` 已软链宿主 `compile/src`，照 stage 的环境变量在容器内执行即可复现。

### 5.2、源码获取：GITHUB 覆盖（hub.njuu.cf 不可达）

- 容器内网络实测：`gitee.com` **可达**（`g-system/fk-libfm`、`g-system/fk-menu-cache` 直连 clone OK）；`hub.njuu.cf` **不可达**（`git ls-remote` rc=128）；`github.com` 直连 clone **失败**（`Failure when receiving data from the peer`）。
- **lxtask 可换源不改脚本**：`common.sh:20` 是**条件导出**（`test -z "$GITHUB" && export GITHUB=https://github.com`）→ 容器内直接 `export GITHUB=https://ghfast.top/https://github.com` 即可。
- **pcmanfm 必须改脚本位置**：`v-pcmanfm/build.sh` 尾部 `export GITHUB=https://hub.njuu.cf`（282 行）**位于 `exit 0`（275 行）之后** → 永不执行，实际克隆源取 common.sh 默认 `github.com`。调试期把覆盖行插到脚本开头 `source /src/common.sh` **之后**（4 行）才生效；**第一次失败即因插到 `exit 0` 之后**。
- ghfast.top 前缀代理对 `lxde/lxtask`、`lxde/pcmanfm` 均可用（`git ls-remote` rc=0，pcmanfm 1.3.1 tag 在）。
- **待办**：作者后续将把源转存 gitee，届时改 `vers.txt` / `build.sh` 的克隆源。

### 5.3、结果与验证（独立兜底，不信 oneBuild 的 `err 0, pass`）

| 组件 | 产物 | `file` | `ldd` | `xx-verify --static` | 日志 miss |
|---|---|---|---|---|---|
| lxtask | `/usr/local/static/lxde/bin/lxtask` **11.6M** | statically linked, stripped | Not a valid dynamic program | **PASS** | 0 |
| pcmanfm | `/usr/local/static/pcmanfm/bin/pcmanfm` **12.5M** | statically linked, stripped | Not a valid dynamic program | **PASS** | 0 |

- b_deps 产物齐备：`/usr/local/lib/libfm.a`（554K）、`libfm-gtk.a`（786K）、`libfm-extra.a`（25K）、`/usr/lib/libmenu-cache.a`（37K）。
- 日志兜底口径：`grep -acE "undefined reference|attempted static link|cannot find"` = **0**。
- pcmanfm 日志尾段计时 22 秒（2 核）；安装文件 11 个（bin/ui/desktop/man/desktopfile 齐全）。

### 5.4、避坑项（本次新增）

- **脚本内 `export` 的位置决定它是否执行**：`v-pcmanfm/build.sh` 的 `export GITHUB=...` 在 `exit 0`（275 行）之后的尾部注释区 → 永不执行；改克隆源必须插到 `source /src/common.sh` 之后、首个 clone 之前。
- **pcmanfm 克隆失败的表象是"源码缺失"**：clone 失败后脚本仍继续（`cd /tmp/pcmanfm` 报 `No such file or directory`、`./autogen.sh`/`./configure` 均 `No such file`），要到 `make` 阶段才报 `PCMANFM build FAILED` → **日志前段 `fatal: unable to access` 才是真因**（AGENTS 三、3「看日志兜底」在此同样适用）。
- lxtask 与 pcmanfm 换源方式不同：前者可用环境变量覆盖（common.sh 条件导出），后者须改脚本内 export 位置。
