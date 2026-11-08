# v-oth-impl02-ibusB：后续完善项（ibus + ibus-rime 静态构建调试记录 第三章拆出）

> **来处**：本文档原为 `docs/2026/11061251-v-oth-impl02-ibusA.md` 的「第三章：后续完善项」，
> 因原文档过大拆出独立成篇。**章节序号与层级保留不变**。
> **订正（2026-11-21）**：章号随 ibusA 二/三章对调同步为**第三章**（本章内容、层级、`### N、` 子节序号不变）；
> 即本文档与 ibusA 尾部的「三、后续完善项」占位指向同一章。
> **原文档去向**：`docs/2026/11061251-v-oth-impl02-ibusA.md`（现余「一、ibus/ibus-rime 静态构建调试」；
> 第三章位置已留占位注明去向）。
> **订正（2026-11-21）**：更上游的 `docs/2026/11061251-v-oth-impl02.md` 已删除——原「二、xfce4-settings」移至
> `11051758-v-oth-impl01.md` 第十章、原「三、v-ibus 落仓 + 复现性验证」移至 `11061251-v-oth-impl02-ibusA.md` 尾部第二章。
> **订正（2026-11-21）**：原「三 3.3~3.7」（动静态输入法对于应用的支持分析，含子节）**各上调一级、并入新四章**
> （`#### 3.N`→`## 四、`+`### N、`；`##### 3.N.y`→`#### N.y、`；`###### 3.N.y.z`→`##### N.y.z、`）；
> 内容未动，仅层级/序号按章内惯例重排（3.3~3.7→四章 1~5），相关引用同步改；三章「### 3、」标题去掉「动静态输入法…」部分。

## 目录

- 三、后续完善项（2026-11-07）
  - 1、ibus/ibus-rime部署形态与apt版对比
  - 2、叁个待办的处理/panel面板打磨:自建系统托盘右键菜单/多引擎切换分析（2026-11-07）
  - 3、现状回顾/gtk2-fcitx支持分析（2026-11-19）
- 四、动静态输入法对于应用的支持分析（2026-11-19）
  - 1、动静态ibus组件，对于发行版应用/项目静态应用的支持分析（2026-11-19）
  - 2、dlopen三层墙，XIM细化：静态程序->动态IBUS/Fcitx（2026-11-21）
  - 3、XIM仍在用，输入底层：经其转接，静态/动态IBUS对比（2026-11-21）
  - 4、应用顶层：静态程序->静态IBUS:直接对接 vs XIM转接，项目实景分析（2026-11-21）
  - 5、总结篇：静态/动态 ibus 服务 × 动/静态应用的接入矩阵（2026-11-21）

## 三、后续完善项（2026-11-07）

### 1、ibus/ibus-rime部署形态与apt版对比

#### 1.0、如何从 maki 本地会话历史定位并提取解说原文（2026-11-07）

> 本节记录「§1-§3 解说原文」的来源定位与提取方法（2026-11-07 实测，可复现）。

##### 1.0.1、会话文件在哪？什么格式？要解码吗？

- **目录**：`~/.local/state/maki/sessions/`。每个会话一个 `<session-id>.jsonl` 主文件；压缩/归档后的分片在 `archive/<session-id>/N.jsonl`（N 递增）。
- **当前会话映射**：`sessions/cwd_latest.json` 把工作目录映射到会话 ID（如
  `/_ext/home/headless/xm-zs01/docker-x11base` → `Cgj4GQj2d8otFEnDj3ZDG`）。
- **格式**：**jsonl**（每行一个 JSON 对象，UTF-8 明文文本）。**不是二进制、无需解码**；但需
  `json.loads` **解析**取字段。
- **行结构**：
  ```
  {"t":"msg","d":{"role":"assistant","content":[
      {"type":"text","text":"…markdown 原文…"},
      {"type":"thinking","thinking":"…推理…"}
  ]}}
  ```
  `t:"msg"` 是消息（user/assistant），`t:"out"` 是工具输出，`t:"meta"` 是元数据。
  **markdown 原文在 `content[]` 中 `type=="text"` 的 `text` 字段**；`thinking` 是推理过程，不抄。

##### 1.0.2、按关键字定位（实测命令）

1. 先按**独特短语**（非泛词，如"形态"）在 sessions 目录缩小范围：
   ```bash
   cd ~/.local/state/maki/sessions
   grep -rl '是独立二进制，不是共享库' .
   # → ./Cgh6RH29t1ASLeFDhAiov.jsonl
   #   ./archive/Cgh6RH29t1ASLeFDhAiov/32.jsonl
   ```
2. 同会话**主文件可能已压缩**（只保留最近摘要），完整原文在**归档分片**
   `archive/Cgh6RH29t1ASLeFDhAiov/32.jsonl` 第 7868 行（assistant TEXT，3722 字符）。
3. 用 python 逐行 `json.loads`，找 `t=="msg"` 且 `d.role=="assistant"` 且 text 含关键短语的
   行号（比 `grep -n` 稳——大文件/编码不易崩）。

##### 1.0.3、提取、改写、拷贝与校验

```python
import json
o=json.loads(open("archive/Cgh6RH29t1ASLeFDhAiov/32.jsonl").read().split("\n")[7867])
text="\n".join(it["text"] for it in o["d"]["content"] if it.get("type")=="text")
# text 即 markdown 原文（3722 字符）
```

- **拷贝前处理**：删对话回显首行（"调研完毕，给出详细解说。"）+ 末句提问（"需要我把这份对比也追加…加固吗？"）；
  章节序号降级（`## 一、`→`### 1、`，`## 二、最终…`→`### 2、`，`## 三、静态…`→`### 3、`，按 AGENTS 规则）。
- **写入**：`edit_lines` 替换文档第二章（原 1213-1244 行）为提取内容。
- **校验**：取历史 TEXT 做同样转换后与文档逐字 diff——**前 65 行零差异**（仅文档尾部多一空行，无害），
  证明正文 1 字未改。

#### 1.1、ibus-rime 是什么形态？是独立二进制吗？

**是独立二进制，不是共享库**。ibus 1.5 的输入法引擎（IME engine）采用**按需启动的独立子进程**模型：

- 每个引擎是一个**可执行程序**（`ibus-engine-<name>`），由 `ibus-daemon` 在首次用到时 `fork/exec` 拉起来，二者通过 D-Bus 通信。引擎进程常驻，直到 daemon 退出。
- **不是 `.so` 插件**（对比 ibus 1.2-1.4 曾用 GModule 动态加载；1.5 改独立进程，便于隔离崩溃）。
- 所以 `ibus-engine-rime` 是个**自带 `main()` 的可执行文件**，`--ibus` 参数告诉它作为引擎进程连 daemon。

**注册方式**：通过 **component XML**（`rime.xml`）声明引擎的 `name`（`im.rime.Rime`）、`exec`（启动命令）、`icon`、`engines` 列表。daemon 扫描 component 目录发现引擎。

#### 1.2、最终（部署后）形态对比：完整目录树

**静态版（我们，`/usr/local/static/`）**
```
/usr/local/static/ibus/
  bin/ibus-daemon              # 主进程（静态 3.8M）
  bin/ibus-setup               # 配置工具（GTK2 C 重写，静态 14M）
  libexec/ibus-engine-simple   # 内置简单引擎（静态）
  libexec/ibus-panel           # 候选窗面板（自定义 GTK2，静态 14M）
  libexec/ibus-x11             # XIM 模块（静态 14M，GTK 客户端兜底）
  lib/libibus-1.0.a            # libibus 静态库（供 panel/engine 链）
  share/ibus/component/{rime.xml,simple.xml}   # 引擎注册（daemon 扫描此）
  share/ibus/keymaps/…
/usr/local/static/ibus-rime/
  libexec/ibus-rime/ibus-engine-rime   # rime 引擎（独立二进制，全静态）
  share/ibus-rime/icons/{rime,abc,zh,…}.png
  share/ibus/component/rime.xml        # 组件声明（exec 指向绝对路径）
/usr/local/static/deps/
  lib/librime.a + 依赖 .a             # librime 静态库（仅链入用）
  share/rime-data/{default.yaml,luna_pinyin*.yaml,…}  # rime 数据（编译期 RIME_DATA_DIR）
```

**apt 版（Ubuntu 22.04，`/usr/`）**
```
/usr/bin/ibus-daemon, /usr/bin/ibus-setup（Python GTK3）
/usr/libexec/ibus-{x11,engine-simple,dconf,ui-gtk3,portal,memconf}
/usr/lib/ibus-rime/ibus-engine-rime   # rime 引擎（动态链接 librime-1.0.so / libibus.so.5，仅 26KB）
/usr/share/ibus/component/rime.xml
/usr/share/ibus-rime/icons/*.png
/usr/share/ibus/setup/*.py            # Python 配置（GTK3）
/usr/share/rime-data/{build/,default.yaml,…}   # 含预编译 build/
```

#### 1.3、静态版 vs apt 版使用注意项

| 维度 | 静态版（/usr/local/static） | apt 版（/usr/） |
|------|------|------|
| **链接** | 全静态，各二进制自包含（glib/gtk/librime/libibus 全 `.a` 链入），**不依赖系统 .so 版本** | 动态，依赖系统 librime/ibus/gtk `.so` |
| **引擎大小** | 6.9M（strip）/ 26.9M（带 debug） | 26KB（几乎全是动态依赖） |
| **引擎发现** | daemon 读 `share/ibus/component/rime.xml`，`exec` 是**绝对路径** `/usr/local/static/ibus-rime/.../ibus-engine-rime --ibus` | 同机制，路径 `/usr/lib/ibus-rime/...` |
| **rime 数据** | 编译期内置 `RIME_DATA_DIR=/usr/local/static/deps/share/rime-data`（仅 `.yaml`，**首次需构建词典**到 `~/.config/ibus/rime/build/`） | `/usr/share/rime-data/`（**含预编译 `build/`**，首次更快） |
| **用户数据** | `~/.config/ibus/rime/`（静态实测）+ `~/.rime` | 同 |
| **面板** | 必须跑我们**自定义 `ibus-panel`**（无 ibus-ui-gtk3）；**候选窗深色圆角**是定制效果 | 系统 `ibus-ui-gtk3`（GTK3 动态），样式随 GTK 主题 |
| **配置工具** | `ibus-setup`（**GTK2 C 重写**，引擎管理） | `ibus-setup`（**Python GTK3**，全功能） |
| **daemon 参数** | 必须 **`-c disable`**（无 dconf/gschemas 注册）；需 `IBUS_ADDRESS` 或同 dbus 会话 | 默认用 dconf 存配置 |
| **自启动** | 无 XDG autostart / systemd unit，需手动拉起 daemon+panel | apt 有 `ibus-daemon` autostart / systemd |
| **运行时依赖** | 仍要 X server + dbus session + **compositor**（圆角 ARGB）；X/字体/glib 全链入，不需 dev 包 | 要系统库（gtk3/librime .so 等） |
| **图标** | panel 源码硬编码 `/usr/local/static/ibus-rime/share/ibus-rime/icons/rime.png` | `/usr/share/ibus-rime/icons/` |
| **语言栏/托盘** | `GtkStatusIcon`（XEmbed systray，tint2） | StatusNotifier/appindicator（DBus 通知） |

**几个实操要点**：
1. 静态版**不自动起 daemon/panel**——部署后要手动 `ibus-daemon -p disable -c disable --replace --daemonize` + `ibus-panel`（用 `IBUS_ADDRESS`/同 dbus 会话）。
2. 静态 rime-data **无预编译 `build/`**，首次输入会现场编译词典（稍慢，一次性）；可把 apt 版 `/usr/share/rime-data/build/` 拷过去或等首次自建。
3. 静态版引擎路径是**绝对路径写死**在 `rime.xml`，若移动 `/usr/local/static/` 需同步改 `rime.xml` 的 `exec` 和 panel 里的图标路径。
4. 静态版 `--strip-all` 后**无符号**，调试崩（如 ibus-setup 段错误）需用未 strip + `-g` 版 + gdb。

### 2、叁个待办的处理/panel面板打磨:自建系统托盘右键菜单/多引擎切换分析（2026-11-07）

> 对 §11.9/§11.8 遗留的 3 项待办逐一细化：当前问题 → 目的 → 解决 → 收益。

#### 2.1、待办 1：`build.sh ibus-rime()` 加固

- **当前问题**：`build.sh ibus-rime()`（297 行）只写了 `-DRIME_DATA_DIR` + `BUILD_STATIC=ON`，
  但静态链真正需要的 4 个条件（`-DRime_DIR`、boost_signals 空桩、ICU 强制 `.a`、glib 静态闭包）
  **没写死**——builder-awe 复验时是**手工**加进去才成功的。干净容器里跑 `full` 很可能
  **链接失败**或产出"假静态"（带 undefined 符号）。
- **目的**：把这 4 个条件固化进脚本，让 `build.sh full` 在任何干净环境**一键复现**静态
  `ibus-engine-rime`（6.9MB，`xx-verify --static` rc=0），不再靠手工和运气。
- **解决**：`ibus-rime()` 的 cmake 行补 `-DRime_DIR=<librime 安装目录>`；构建前注入 boost_signals
  空桩；ICU 强制 `.a`（禁用动态）；glib 闭包用与 `x11()`/`panel` 相同的 `--start-group…--end-group`
  手工直链。改完在 builder-obox 实跑 `build.sh ibus-rime`，以 `xx-verify --static` rc=0 为准。
- **收益**：构建**可复现、确定性**；CI/新容器跑 `full` 得到同样静态产物；文档 §6/§11.9 的
  静态链要点与脚本真正一致，消除"这次能链下次不能"的隐患。

#### 2.2、待办 2：真实应用全重链（遗留缺口 #2）

> **现状澄清（2026-11-07）**：GTK2 同时支持 xim/ibus 的调整**已做并写进 `.a` 库**
> （`compile/src/u-gtk/build.sh` 的 `gtk_ibus_a2()`，commit `ef492e8`）；测试程序
> `gtkibustest` 就基于这个 `.a`，中文上屏全通（§11.7.12）；**pcmanfm 也已重链**（15.1M 静态，
> hdmi :1 连接成功无报错，§11.7.13）。**真正剩余**：真实应用**内**中文提交未被程序化回读证实。

- **GTK2 怎么调整的（A2 手术式合并，§11.7.11-12）**：
  1. 编 ibus gtk2 模块三对象（`ibusim`/`ibusimcontext`/`iconwidget`）。
  2. glue `ibus-builtin.c` 把模块 `im_module_init/exit/create/list` 重导出为
     `_gtk_immodule_ibus_*`（builtin 形态）。
  3. 补丁 `gtkimmodule.c` 在 `INCLUDE_IM_xim do_builtin(xim)` 后加
     `#ifdef INCLUDE_IM_ibus do_builtin(ibus); #endif`——**XIM 是现成 builtin 模型，ibus 并进去**，
     两者都作为内置模块，**不再依赖 dlopen im module `.so`**（静态 GTK 不支持 dlopen）。
  4. 补丁 `ibusim.c` 的 `g_module_check_init` 用 `#ifndef INCLUDE_IM_ibus` 包住，避免与
     murrine 冲突。
  5. `ar rcs` 把上述对象 + `libibus-1.0.a` 的 39 个 `.o` 并入 `libgtk-x11-2.0.a`（→37.5MB）。
- **当前问题**：pcmanfm 已连上 daemon、无 IBUS 报错；但**真实应用内中文提交未程序化回读**
  （位置栏 GtkEntry 落点/文本回读难），权威证明仍为 `gtkibustest`。
- **目的**：在真实应用里**程序化证实中文上屏**（不只连接），把"中文能用"钉在真实桌面应用级。
- **解决**：选可程序化回读文本的真实应用载体（如自写 GtkEntry 测试窗口或 `zenity --entry`），
  hdmi :1 起 daemon+panel+engine，真实点击 + 键入 + 回读 `你好`。
- **收益**：消除"真实应用内提交"这块唯一未证实的不确定性；为后续真实应用重链提供模板。

#### 2.3、待办 3：面板打磨（遗留缺口 #3）

> **范围与反馈**：面板打磨不只自己校验，**需用户体验反馈**（用户按实际使用体验反馈）。
> 候选/提示词列表框（候选窗）**已处理过**（用户已看）。**托盘图标右键菜单**也算 panel
> （`GtkStatusIcon` 的 popup-menu，`_panel_status_popup`）；当前**菜单空白、只有一小白条**。

- **当前问题**：
  1. **托盘右键菜单空白**：`_panel_status_popup` 从 `ibus_bus_list_active_engines` 建菜单项；
     单引擎（rime 直拉）下该列表**为空**（§11.7.11 已记录）→ 0 项空菜单 → 白条。
  2. 细节未打磨：候选对齐/间距、翻页按钮、当前候选高亮、空状态显示、与 tint2 协调。
- **目的**：托盘菜单**有内容**（至少显示当前引擎 + 退出项）；候选窗/语言栏**视觉交互接近
  成熟输入法**；打磨结果**以用户实体验反馈为准**。
- **解决**：
  1. 托盘菜单改为**基于 `ibus_bus_get_global_engine`（当前引擎）**建项（单引擎也显示），
     或 fallback：无活跃引擎时至少放"当前引擎(只读) + 退出"两项。
  2. 逐细节改 panel 源码（布局/高亮/按钮/间距/字体/圆角），每改一次 hdmi :1 实跑截图对比
     （`docs/img/tmp/ibus` v5 系列已存），确认后提交源码+截图。
  3. **用户试用反馈**：改完请用户实际用，按反馈再调。
- **收益**：托盘菜单不再空白；候选窗/语言栏**好看好用**；以用户反馈为准，避免自说自话。

#### 2.4、本轮验证结果（2026-11-07 三待办全部完成）

> 三个待办已全部落地并验证，效果截图存 `docs/img/tmp/ibus-panel/`（`ibus-panel-tray-menu-current-engine-rime*.png`）。

- **待办 1（`build.sh ibus-rime()` 加固）✅**：
  - 静态链接缺 `libgflags.a`（libglog 依赖，`google::FlagRegisterer` 未定义）与 `libnotify.a`
    （`rime_main.c` 直接调 `notify_*`）→ 两库补入 `STATIC_LIBS`（gflags 容器内 `cmake+xx-clang`
    构建 228KB；libnotify 为 2KB stub，从 builder-awe 拷）。
  - 产物 `ibus-engine-rime` **27.1MB**，`xx-verify --static` rc=0（statically linked），`make install`
    到 `/usr/local/static/ibus-rime/`，smoke test 正常启动。
  - `build.sh` 补 `ibus-rime)` case 分支 → commit `6bd8152` 已推。
- **待办 2（真实应用内中文提交回读）✅**：
  - 载体：**静态 pcmanfm**（15.1M，A2 libgtk 重链）部署 hdmi `:1`，`GTK_IM_MODULE=ibus`。
  - `Ctrl+L` 位置栏 → `type nihao` → 候选 `ncand=6`（panel 日志）→ 空格选字 → `Ctrl+A Ctrl+C` →
    `xclip -o` 回读剪贴板 = **`e4 bd a0 e5 a5 bd`（UTF-8 "你好"）**（python 严格解码）。
  - 比 §11.7.12 的 `gtkibustest` 更强：**真实桌面应用**内中文上屏已程序化证实。
- **待办 3（托盘菜单不再空白，显示当前引擎）✅**：
  - 根因 1：`list_active_engines`/`get_global_engine` 在单引擎（rime 直拉）下为空 → 空菜单白条。
  - 根因 2：`ibus_bus_list_engines` 在静态 libibus 下**崩溃**（`ibus_serializable_deserialize_object`
    反序列化断言，type 非 `IBUS_TYPE_SERIALIZABLE`）→ 当时 revert 回 `list_active_engines`。
    **注**：该崩溃本质也是根因 3 的「类型未注册」——`main()` 补 `ibus_init()` 后 `list_engines`
    可正常返回（§2.5 验证 n=980），故多引擎菜单改用它。
  - 根因 3（关键）：panel `main()` **未调 `ibus_init()`** → IBus 类型（`IBusEngineDesc`）未注册 →
    `get_global_engine` 反序列化失败恒返 NULL → 菜单 fallback"当前引擎: 无"。
  - 修复：`main()` 加 `ibus_init()`（类型注册）+ `_panel_status_popup` 若 `get_global_engine` 为
    NULL 则 `set_global_engine("rime")` 建立全局引擎再重查 → **菜单显示"中州韵 Rime"单项**
    （82x26，非空白），截图 `docs/img/tmp/ibus-panel/ibus-panel-tray-menu-current-engine-rime.png`。
- **坑与手法（已存 `memory: tray-pcmanfm-verify.md`）**：
  - `strings` 不显示 UTF-8 → 检测"当前引擎"需 `grep -a` 或 python `.encode()` 计数。
  - 托盘菜单触发：`xdotool click 3` **不触发** `GtkStatusIcon` popup-menu；**python-Xlib
    `XTest.fake_input(ButtonPress/Release,3)`** 才触发。
  - `IBUS_ADDRESS` 提取用 `grep ^IBUS_ADDRESS bus/* | sed 's/^IBUS_ADDRESS=//'`（**不能** `cut -f2`，
    值内含 `=` 被截断）。
  - 回读剪贴板需 `apt-get install -y xclip`；panel 启动 env 需 `DISPLAY=:1` +
    `DBUS_SESSION_BUS_ADDRESS=unix:abstract=/tmp/dbus-uid1000` + `HOME=/_ext/home/headless` + `IBUS_ADDRESS`。

#### 2.5、托盘菜单对标 apt + 多引擎切换（2026-11-07 续）

> 用户反馈：菜单**太单一**（只显示当前引擎 Rime），要求**对标 apt 原版菜单结构**，能列出
> **多个输入法引擎并切换**（如 ibus-rime / libpinyin）。截图存
> `docs/img/tmp/ibus-panel/ibus-panel-tray-menu-multi-engine-*.png`。

- **菜单重构**（`panel-gtk2-ibus-panel.c` `_panel_status_popup`，commit `be37092`）：
  - `list_active_engines` → **`ibus_bus_list_engines`**（`ibus_init()` 后可用，不崩）；
  - **过滤 `xkb:` 前缀**（跳 885 个键盘布局），只留输入法引擎；
  - 每引擎一个 `gtk_check_menu_item`，勾选当前全局引擎，`activate` → `set_global_engine` 切换；
  - 菜单尾部**分隔线 + 退出**（对标 apt 原版 Quit 项）。
- **libpinyin 接入静态 daemon（关键）**：装 `ibus-libpinyin` 后 `list_engines` 仍无它——静态 daemon
  **只扫 `/usr/local/static/ibus/share/ibus/component/`**（rime.xml、simple.xml），不扫系统
  `/usr/share/ibus/component/`（libpinyin.xml 在那）。解决：
  1. `cp /usr/share/ibus/component/libpinyin.xml` → 静态 component 目录；
  2. 引擎初始化需 **config 组件**（`IBus config component is not ready!`）——daemon 原启动参数
     `-c disable` 禁了 config → **去掉 `-c disable`**；
  3. `cp /usr/share/ibus/component/memconf.xml` → 静态 component 目录（on-memory config，无持久化
     依赖）；daemon 自动拉起 `/usr/libexec/ibus-memconf`（22KB，动态 glibc，可连静态 daemon）。
- **验证**（hdmi `:1`，探针 `probe_engines`/`probe_geteng`/`probe_seteng`，静态链 libibus）：
  - `list_engines` **n=980**，非 xkb 引擎 **3 个**：`libpinyin`(Intelligent Pinyin)、
    `libbopomofo`(Bopomofo)、`rime`(Rime)；
  - `set_global_engine("libpinyin")` → 全局引擎=**libpinyin**，`ibus-engine-libpinyin` 进程被拉起
    并保持运行（动态系统引擎连静态 daemon 成功）；
  - 菜单实测 **194x94**（3 引擎+分隔线+退出），点第 3 项 → 全局引擎从 libpinyin 切回 **rime** ✅。
- **探针**：`/tmp/probe_{engines,geteng,seteng}.c`（builder-obox 内 `xx-clang -static` 编译，拷 hdmi
  以 headless + IBUS_ADDRESS 跑）；`run_seteng.sh` 包装环境。**注意**：`probe_engines`/`geteng` 需
  `ibus_init()` 才能正确反序列化引擎名（否则报断言/空）。
- **libpinyin 静态集成状态（2026-11-07 用户确认）**：`ibus-libpinyin` 为 **apt 动态引擎**
  （`/usr/libexec/ibus-engine-libpinyin`，dynamically linked PIE，依赖系统 `libpinyin.so.13`/
  `libopencc`/`liblua`），**仅作多引擎菜单切换的对照验证**，**未静态编译**；静态栈交付仍以
  **ibus-rime 静态**为主。静态目录 `/usr/local/static/ibus-rime/` 只有 `ibus-engine-rime`，
  无静态 libpinyin。若要静态集成需从零构建 libpinyin+libopencc+lua+boost+libibus 静态链
  （builder-obox 当前无源码/静态库，工作量类似 ibus-rime）。多引擎菜单本身不依赖 libpinyin
  静态化——`list_engines` 枚举 + 切换逻辑已独立验证。

### 3、现状回顾/gtk2-fcitx支持分析（2026-11-19）

#### 3.1、设计/完成/待完善回顾（2026-11-19 保存，回复原文含表格）

> 本节保存 2026-11-19 用户「回顾 ibus 记录文档与现有脚本实现，看当前怎么设计、完成了哪些、哪些还要完善」的完整答复原文（含两张表格）。

**设计（架构决策 + 脚本结构）**：

- **架构决策**（`ibus01` §7/§8/§10/§11）：ibus 1.5.35 + ibus-rime 1.6.1 全静态（Alpine musl，`xx-clang`），**弃用整栈降级 1.4**（§10.4）；**方案 B** 自定义 GTK2 **panel**（候选/aux/property/语言栏，深色圆角 v5）；**方案 A2** ibus im 模块**静态注册进 `libgtk-x11-2.0.a`**（`u-gtk` 的 `gtk_ibus_a2()`）；**ibus-setup** 原版 Python→**GTK2 C 重写**（`ibus-setup-gtk2.c`）；查询必须用 `IBUS_ADDRESS`（ibus 私有 D-Bus）；daemon 用 `-c disable`（无 dconf）。
- **脚本结构**（`compile/src/v-ibus/build.sh`，409 行，注释头 6-16 明确产物）：`deps_glog/leveldb/yaml/marisa/opencc`（librime 5 依赖）→ `librime` → `ibus` → `panel`（方案B）→ `x11` → `ibus_rime` → `setup`；入口 `full`（一键）/单组件分支/`b_deps` 盘点。

**已完成（全部 `xx-verify --static` 通过）**：

| 项 | 状态 | 出处 |
|---|---|---|
| ibus 1.5.35（daemon/x11/engine-simple/libibus.a） | ✅ | ibus01 §4/§10.3 |
| librime 1.9.0 + glog/yaml-cpp/leveldb/marisa/opencc | ✅ | ibus01 §5 |
| ibus-rime 1.6.1（独立二进制，静态 6.9M/26.9M） | ✅ | ibus01 §6、§11.9 |
| 方案 B panel（候选窗深色圆角 v5，`PANEL_ROUND` 可调） | ✅ | ibusB §2.4、主文档 v2→v5 |
| 方案 A2 im 模块注册进 libgtk + 静态应用中文全通 | ✅ | ibus01 §11.7.12/13 |
| ibus-setup GTK2 C 重写（引擎管理） | ✅ | ibus01 §11.9 |
| 托盘菜单多引擎切换（`list_engines`+`set_global_engine`） | ✅ | ibusB §2.5 |
| 三待办（ibus-rime 加固 `6bd8152`/真实应用 pcmanfm 中文回读/托盘菜单） | ✅ | ibusB §2.4 |
| XIM 全链路 + 真实应用（pcmanfm `Ctrl+L`→`你好` 剪贴板回读） | ✅ | ibusB §2.4 |

**哪些还要完善**：

- **构建/功能层（文档明确列出）**：
  1. **真实应用全重链**：仅 pcmanfm 已带 ibus；**geany/lxtask/engrampa 等 build 树已失，需重建才带 ibus**（`ibus01` §11.8.3 遗留 #2）。
  2. **libpinyin 静态集成未做**：现仅 **apt 动态引擎**作多引擎菜单对照；要静态集成需从零建 libpinyin+libopencc+lua+boost+libibus（工作量大，`ibusB` §2.5 结尾）。
  3. **panel 打磨**：`ibus01` §11.8.3 遗留 #3（非阻塞；视觉以用户实体验反馈为准）。
  4. **`ibus` CLI 未建**（tools/main.vala，Vala，可选；`ibus01` §10.3）。
- **部署/运行层（注意项，非构建 bug，`ibusB` §1.3）**：
  5. **无自启动**——部署后需手动 `ibus-daemon -p disable -c disable --replace --daemonize` + `ibus-panel`（`IBUS_ADDRESS`/同 dbus 会话）。
  6. **rime-data 无预编译 `build/`**——首次输入现场编译词典（一次性稍慢；可拷 apt 版 `/usr/share/rime-data/build/`）。
  7. **路径写死**——`rime.xml` 的 `exec`/panel 图标路径是绝对路径，移动 `/usr/local/static/` 需同步改。
  8. **`--strip-all` 后无符号**——调试崩溃需未 strip + `-g` 版 + gdb。
  9. **运行时需 compositor**（ARGB 圆角依赖 xcompmgr+Composite）+ X + dbus session。

**一句总括**：构建栈已**全部静态落地并验证**（ibus/ibus-rime/panel/ibus-setup/A2 im 模块/多引擎菜单），剩余主要是**部署层注意项** + 两个非阻塞功能缺口（**其他真实应用重链**、**libpinyin 静态化**）。

#### 3.2、fcitx 输入法提前支持——细化分析（2026-11-19 保存，回复原文含表格）

> 本节保存 2026-11-19 用户「GTK2 静态库层输入法支持 xim/ibus/fcitx，现只支持前两种；fcitx 提前支持怎么处理 + 静态版未就绪前先装动态版让基于这个库的应用也能输入」的完整答复原文（含表格）。

###### 3.2.1、现状确认：静态 GTK2 库层输入法支持（基于 `u-gtk` A2 实现 + `ibus01` §11.7.6-11.7.10 + 主文档 519-526）

| 输入法 | 现状 | 机制 |
|---|---|---|
| **xim** | ✅ 支持 | GTK 原生内置（`--with-included-immodules=xim` + `-DINCLUDE_IM_xim`，`libstatic-im-xim`，零 dlopen） |
| **ibus** | ✅ 支持 | **A2 手术式并入** libgtk（`INCLUDE_IM_ibus do_builtin(ibus)` + glue + libibus .o 合并进 `libgtk-x11-2.0.a`） |
| **fcitx** | ❌ 不支持 | 无文档、无脚本、无 `vers.txt` 登记，完全未涉足 |

即**只支持 xim、ibus 两种，fcitx 未做**。

###### 3.2.2、fcitx 要支持，怎么处理？——两条途径

- **途径 1（彻底、标准）：A2 式静态化 fcitx im module 并入 libgtk**
  - 步骤（完全对照 ibus A2）：① 静态化 **fcitx 本体**（fcitx4/5 + 依赖 D-Bus/xkbcommon/libxcb 等，新建 `v-fcitx/` 或并入 u-gtk）；② 编 fcitx 的 **gtk2 im module**（fcitx4 的 `fcitx-gtk2`/fcitx5 的 `fcitx5-gtk`）为静态对象；③ `gtkimmodule.c` 加 `INCLUDE_IM_fcitx do_builtin(fcitx)` + glue（`im_module_*`→`_gtk_immodule_fcitx_*`）+ `ar r` 并入 `libgtk-x11-2.0.a`。
  - 效果：`GTK_IM_MODULE=fcitx` 直接可用（标准配置），跨发行版、自包含。
  - 工作量：**中偏大**（≈ ibus A2 + fcitx 全套静态化；fcitx 依赖略异于 ibus，需单独盘点）。
- **途径 2（临时、兜底）：XIM**
  - 静态应用用 builtin xim + `XMODIFIERS=@im=fcitx` + **fcitx 自带的 XIM server**；**零 libgtk 改动**，即装即用。
  - 缺点：**XIM 已被用户否决为主路径**（§11.7.7）；XIM 是 legacy 协议、单点故障（fcitx XIM 崩了全断）、Qt 不看、个别应用有 XIM bug。

## 四、动静态输入法对于应用的支持分析（2026-11-19）

### 1、动静态ibus组件，对于发行版应用/项目静态应用的支持分析（2026-11-19）

#### 1.1、「静态版未就绪前先装动态版 ibus/fcitx」可行性——要分对象，且基本只能走 XIM

- **GTK2静态应用 + 系统动态ibus/fcitx，`GTK_IM_MODULE=ibus/fcitx` 走不通。**
  - 硬根因（三层墙，lxtask §3.3.1 / §11.7.8）：系统 im 模块 `.so`（`im-ibus.so`/`im-fcitx.so`）是 **glibc 动态**，静态 musl 应用**无法 dlopen**（跨 libc + 符号冲突 + 无共享 glib/gtk/libibus）。
  - **铁证**（主文档 519-526）：静态 geany 认不到系统 `im-ibus.so`（它注册进「另一份」系统 libgtk，静态 geany 的 GTK 看不见）。
  - 所以静态应用用动态 ibus/fcitx，**唯一可行路径 = XIM**：`GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus/fcitx` + 对应 XIM server（ibus 走 `ibus-x11`，fcitx 走自身 XIM）。
- **但 XIM 已被否决为主路径（§11.7.7）** → 「先装动态版走 XIM」只能算**应急/临时兜底**，不能作为最终交付。
- **对系统（apt）应用**：装动态 ibus/fcitx **直接可用**——distro 自带 `im-ibus.so`/`im-fcitx.so` 连各自 daemon，各自画候选。但注意：**fcitx 与 ibus 是两套独立输入法栈**（fcitx 有自己 daemon+UI，不走我们的 ibus panel）；且这属于**系统应用侧**，与我们静态应用无关，也**不需要我们静态化**（distro 自足，§11.7.10 ④）。

#### 1.2、firefox 等系统动态应用可用我们静态 ibus——答复原文保存（2026-11-19）

> 本节保存 2026-11-19 用户「现有 ibus 静态化输入法，后续不同发行版动态安装的应用（alpine/ubt22 下 apk/apt 安装的 firefox）能够使用吗」的完整答复原文（含表格）。

**结论：能——但有个关键前提与分工**。系统动态应用（firefox 等）可以用我们静态 ibus 输入法，前提是装了 **distro 自己的 ibus im 模块**（匹配应用 toolkit），且**不跑 distro 的 ibus-daemon**（我们静态 daemon 独占 `org.freedesktop.IBus`）。候选统一由**我们的 panel** 显示。

##### 1.2.1、分工（§11.7.10 ④，已定案）

| 谁 | 提供 | 服务对象 |
|---|---|---|
| **我们（静态）** | ibus-daemon + panel + 静态 im 模块 | daemon/panel 给**所有客户端**；静态 im 模块只给**静态应用** |
| **distro** | 自家 im 模块 `.so`（im-ibus.so / ibus.so / gtk4 im / qt plugin）+ libibus | 系统动态应用（firefox 等），ABI 由 distro 匹配 |

我们**不提供、也不能提供**跨发行版 im `.so`（ABI/libc/符号版本化），系统应用侧**靠 distro 自己的 im 模块**。所以 firefox 用 distro 的 im 模块 → 连**我们的** daemon → **我们的** panel 画候选。

##### 1.2.2、firefox 具体（alpine / ubt22）

- **firefox Linux 是 GTK3 应用**，输入走 `GTK_IM_MODULE=ibus`（GTK 框架 dlopen `ibus.so`，GTK3 im 模块）。
- **需装**：alpine → `apk add firefox ibus-gtk3 libibus`；ubt22 → `apt install firefox ibus-gtk3 libibus5`。
- **配置**：`GTK_IM_MODULE=ibus` + 同一 dbus session（`DBUS_SESSION_BUS_ADDRESS`/`IBUS_ADDRESS` 指向我们 daemon）。
- **候选**：firefox（GTK3）候选表经 daemon 转发给**我们的 GTK2 panel**——panel 独立进程，与客户端 toolkit 无关（§8.1 已证）。

##### 1.2.3、几个关键点（能跑通的依据）

1. **D-Bus 协议兼容**：系统 im 模块（distro ibus 1.5.x）连我们静态 daemon（1.5.35）走 IBus D-Bus 协议——1.5.x 协议稳定，跨版本兼容（daemon 忽略未知字段）。
2. **component 扫描**（§2.5）：我们静态 daemon **只扫 `/usr/local/static/ibus/share/ibus/component/`**（rime.xml/simple.xml），不扫系统 `/usr/share/ibus/component/`。firefox 只是客户端，引擎用**我们的 rime**（静态目录已有 rime.xml）——**无需系统引擎**。
3. **不冲突**：只装 distro im 模块小包（`ibus-gtk3`/`libibus`，不含 daemon），**禁 distro 的 ibus-daemon 自启**——一个 daemon（我们的）+ 一堆客户端 im 模块（distro 的），无两套 daemon 冲突（§11.7.10 ③）。
4. **兜底 XIM**：若某发行版没装对应 im 模块，firefox 可走 `XMODIFIERS=@im=ibus` + `GTK_IM_MODULE=xim` 连**我们的 ibus-x11**（XIM server）→ daemon——但 XIM 是 legacy、已否决为主路径，只作兜底。

**一句话**：能——firefox 等系统动态应用，**装 distro 的 ibus im 模块（如 `ibus-gtk3`）+ 不跑 distro daemon + 同 session 连我们静态 daemon**，候选由我们 panel 画——「一个 daemon（我们的）+ distro im 模块（系统应用）+ 静态 im 模块（静态应用）」既定分工，覆盖跨发行版；我们无需为各发行版提供 im `.so`。

#### 1.3、结论与总结（2026-11-19）

- **静态（项目）应用侧**：装系统动态 ibus/fcitx **仅 XIM 可行**（`GTK_IM_MODULE=xim` + `XMODIFIERS` + 对应 XIM server），且 **XIM 已否决为主路径**（§11.7.7）→ 「先装动态版」**只宜作临时应急**，不作为方案。
- **发行版（系统）应用侧**：装 distro 自己的 ibus/fcitx im 模块即可**直接自足**（各自 daemon+UI，与我们静态栈无冲突——不同时跑两套 daemon 即可），**无需我们动库/静态化**。
- **firefox 具体**（1.2）：装 distro ibus im 模块（`ibus-gtk3`）+ 禁 distro daemon 自启 + 同 session 连我们静态 daemon → 候选由**我们的 panel** 画——「一个 daemon（我们的）+ distro im 模块（系统应用）+ 静态 im 模块（静态应用）」既定分工，覆盖跨发行版。

**一句话**：「先装动态版」对静态应用**只能走 XIM**（应急、非主路径）；系统应用侧**装系统版即自足**（distro im 模块 + 各自 daemon），我们无需为各发行版提供 im `.so`。

### 2、dlopen三层墙，XIM细化：静态程序->动态IBUS/Fcitx（2026-11-21）

> 本节补 1.1 一句"唯一可行路径 = XIM"的细化：**对象是发行版动态装的 ibus/fcitx**（不是我们的静态栈）。
> 硬根因引用 lxtask `09261949-lxtask-解析与优化.md` §3.3.1（三层墙）/ 本文档族 `11051758-v-oth-impl01.md` §11.7.8。

#### 2.1、三层墙是啥（逐层封死，任一层不成立即死）

| 层 | 是什么 | 对 im 模块的直接后果 |
|---|---|---|
| **① musl 静态 `dlopen` 是空壳** | musl `libc.a` 里 `dlopen` 直接 `return 0`（`src/ldso/dlopen.c`）；真加载器 `ldso/dynlink.c` **只编进 `libc.so`，从不进 `libc.a`**（musl 1.2.4 Makefile `LDSO_OBJS`） | 静态二进制里**根本没有动态加载器**，`dlopen` 永远 NULL |
| **② 静态二进制没有动态段** | `readelf`：`.dynsym`=0、无 dynamic section；loader `.so` 的 `DT_NEEDED` 是 `libgdk_pixbuf-2.0.so.0`/`libglib-2.0.so.0`/`libc.so.6`——我们链 `.a`，这些 `.so.0` **磁盘上不存在** | 有加载器也没东西可加载；就算打开，注册函数**无处解析**（无动态符号表） |
| **③ 跨 libc 硬墙（核心）** | `im-ibus.so`/`im-fcitx.so` 是 **glibc 编译**；其 `malloc/pthread/TLS` 依赖 glibc **FS/GS 线程指针 + 全局态**（signal handler、prctl）。Rich Felker：「run a foreign libc in the same process is inherently poking at implementation internals」；`foreign-dlopen` 用户态绕法实测 musl+glibc 共存必抢冲突 | 前两层即使绕过也不成立——glibc 模块与 musl 进程**同进程共存结构性冲突** |

```
①能不能调 dlopen？        → musl 静态没有加载器（能力层）
②有加载器也没东西可加载   → 无动态段 + .so 不在磁盘 + 符号无处解析（链接层）
③就算前两层绕过也不行     → glibc/musl 同进程共存踩内部实现（运行时层）
```

1.1 那句「跨 libc + 符号冲突 + 无共享 glib/gtk/libibus」= **③的展开**（符号冲突、无共享 glib/gtk/libibus 属 ②③的运行时表现）。

**铁证**（`11061251-v-oth-impl02-ibusA.md` 二章 §9，原"主文档 519-526"）：geany 全静态 libgtk2 + 系统 `im-ibus.so` → 该模块**注册进「另一份」系统 libgtk2**，静态 geany 自带的 GTK **认不到** → 候选窗不弹。

#### 2.2、XIM 在哪个层

- **XIM 是 X11 协议层，不是 GTK2 私有的**：XIM Protocol Spec 与 toolkit 无关，靠 X 根属性 `XMODIFIERS`/`XIM_SERVERS` 协商；GTK2/GTK3/Qt/Wx 都能走。
- **GTK2 只是内置了一个"走 XIM 协议"的 im 客户端模块**（`modules/input/xim`），它是所有 im 模块里**唯一能零 dlopen 内置**的（`--with-included-immodules=xim` → `libstatic-im-xim` + `do_builtin(xim)` 注册）。`compile/src/u-gtk/build.sh:241` 现即 `--with-included-immodules=xim` → **本项目静态 libgtk 已带 XIM 客户端**。
- 覆盖范围：**所有共用这份静态 `libgtk-x11-2.0.a` 的 GTK2 应用**（lxtask/pcmanfm/geany/engrampa/rofi/dunst/hsetroot/gpicview/gsm/pavucontrol/xfce4 等）——一处重编、全部生效；**不覆盖** GTK3/GTK4/Qt（它们各有各的 im 插件，不在我们这份 libgtk 里）。

#### 2.3、桥接链路（动态 ibus 侧）

```
GTK2 静态应用(builtin xim 模块)
   --XIM 协议(X 属性协商, @im=ibus)-->  ibus-x11（XIM server, /usr/libexec/ibus-x11）
   --XIM 事件--> IBus 事件 --> ibus-daemon（系统动态） --> 引擎 ibus-engine-rime
   <--候选/上屏经 XIM 回调--> 应用；候选窗由 ibus-x11/系统 panel 自绘
```

- **与 1.1/1.2 静态侧的关键差别**：这里 daemon 是**系统动态**的——**不需要** `IBUS_ADDRESS`、不需要我们的 panel、不与我们的静态 daemon 抢 `org.freedesktop.IBus`（本来也不该同时跑两套）。
- `ibus-x11` **由 `ibus-daemon` 拉起**（上游 `configure.ac`：`XIM_CLI_ARG=[--xim]`，`--disable-xim` 默认开）；Wayland/XWayland 下由 `/etc/xdg/Xwayland-session.d/10-ibus-x11` 钩子启。**必须先有 daemon 再起 x11**（x11 连不上 daemon 直接 exit 1）。
- 变量必须**同时设**：`GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus`。只设 `XMODIFIERS` 不可行（`@im=ibus` 会把 `ibus` 当模块 dlopen，ibusA §6 实测）。
- **fcitx 完全同构**：`XMODIFIERS=@im=fcitx` + fcitx 自带 XIM server，零 libgtk 改动。ibus 与 fcitx **不可同时当 XIM server**（`XMODIFIERS` 只指一个）。

#### 2.4、要装/要设什么（动态侧）

| 发行版 | 包 | 关键点 |
|---|---|---|
| alpine | `apk add ibus ibus-rime`（community：ibus **1.5.35-r0**、ibus-rime **1.6.1-r0**） | `ibus` 主包含 `libexec/ibus-x11`（XIM server）；engine 二进制 `ibus-engine-rime` + `rime-data`；组件在 `/usr/share/ibus/component/` |
| ubt22 | `apt install ibus ibus-rime` | `ibus` 含 `/usr/libexec/ibus-x11`（jammy 文件清单已核）；`ibus-rime` 依赖 `librime1`+`librime-data` |

```sh
export GTK_IM_MODULE=xim        # 让 GTK2 选内置 xim 客户端模块
export XMODIFIERS=@im=ibus     # 指向动态 ibus 的 XIM server
ibus-daemon -dx                # 先起 daemon（-x 顺带拉起 ibus-x11）
```

**验证**：`pgrep -a ibus-x11`（在跑）+ `xprop -root XMODIFIERS` + 静态应用（如 lxtask）内 `nihao` → 候选窗由系统 ibus-x11 画出。

#### 2.5、缺陷/隐患（含本路径特有）

1. **单点故障、无重连**：XIM 链路全押在 `ibus-x11` 进程上；im 模块那套有重连逻辑，**XIM 没有**（ibusA §11.7.6）。
2. **`XIM_SERVERS` 残留坑（上游 bug，已确认）**：`ibus-x11` 连不上 daemon 时 exit 1，但**已公告自己为 XIM server 且不注销** → `xprop -root XIM_SERVERS` 残留 `@server=ibus`，XIM 客户端指向不存在的 server → **"静默失灵"**（ibus 上游 issue #2931 定案；fcitx5 诊断也会报 `XIM server name 'ibus' differs from XMODIFIERS=@im=fcitx`）。规避：确认 daemon 先起；必要时 `xprop -root -remove XIM_SERVERS`。
3. **候选窗不可控**：由系统 `ibus-x11`/系统 panel 自绘——**样式不可调**（我们的 panel 在这条路上用不上；ibusA §11.7.6「方案 D 只在客户端走 XIM 时生效」在本节语境 = 静态 panel 无效）。
4. **改通用配置认知**：`GTK_IM_MODULE=xim` 让所有 GTK 应用走 legacy XIM（ibusA §11.7.6.3），且**用户已否决 XIM 为主路径**（§11.7.7）→ 只能应急/兜底。
5. **不覆盖 Qt**（走 QPlatformInputContext），个别应用自带 XIM bug。
6. **静态/动态 daemon 互斥**：动态侧若同时被我们的静态 `ibus-daemon` 抢了 `org.freedesktop.IBus`（同 X + 同 session 且我们 daemon 自启），动态 `ibus-x11` 连不上 daemon → 踩隐患 2。
7. **引擎/组件目录是系统的**：`/usr/share/ibus/component/`（不是我们的 `/usr/local/static/ibus/share/ibus/component/`）——要换引擎得装系统 engine 包。

**一句话**：静态 GTK2 应用经 XIM 对接**动态** ibus/fcitx = `GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus` + 系统 `ibus-daemon -dx`（拉起 `ibus-x11`）；包只需 `ibus` + `ibus-rime`（或 fcitx）。可行但**legacy、单点故障、候选窗不可控**，且要防 `XIM_SERVERS` 残留静默失灵——**只作应急，不作最终交付**。

### 3、XIM仍在用，输入底层：经其转接，静态/动态IBUS对比（2026-11-21）

#### 3.1、哪些发行版/模式仍在用 XIM（2026-11-21 用户归纳）

1. **所有 Linux 桌面发行版默认还带 ibus 的 ibus-x11**（ibus 主包，`--disable-xim` 默认开）→ 主要服务 **XWayland 应用**（Java Swing/Electron/老 X11 应用）。GNOME/KDE 上 Wayland 原生应用走 portal/SettingsDaemon，但 XWayland 应用仍靠 ibus-x11。**这是当前 XIM 最实际的存在场景**。
2. **fcitx5 默认在 X11 会话里就是走 XIM 桥**（fcitx5-x11 自带 XIM 平台）：KDE/Arch/NixOS/openSUSE 等用 fcitx5 的发行版，X11 应用全靠 `XMODIFIERS=@im=fcitx`；fcitx5 的 "platform context" 有 x11/wayland。Arch Linux 默认 fcitx5 + im-config，X11 会话就是 XIM。
3. **im-config 体系（Debian/Ubuntu 老式）**：`im-config -n ibus/fcitx` → 写 `XMODIFIERS`，本质仍是 XIM 协商。
4. **Qt5/Qt6**：X11 下 Qt 的 input context 也是 XIM（`QXcbConnection` 的 platform input context 走 XIM），Wayland 下走 `QtWaylandInputContext`（走 TextInput v3）。所以 Qt 在 X11 = XIM。
5. **xkb + 无 IM 的纯 X11 老发行版/瘦客户端**：X 本身内置 XIM 支持（Xorg 的 XIM 服务端可选，如 iiimf/xim-protocol server、UIM、Canna/kinput2）。发行版角度：OpenBSD 的 xim（kinput2/scim）、NetBSD、Void（scim）、老 Gentoo（scim/xim）。
6. **X.org 自带的 XIM 协议仍活跃**：xorg-server 里 `XkbUseNativeXIM`/XIM 扩展仍编译在内（`--enable-xim`），xterm、vim、老 Motif/awesomewm、XTerm/xwit、Openbox 客户端、以及 Java AWT/Swing（XToolkit）、很多 Java/Electron 应用 → 仍靠 XIM。
7. **UIM/scim 老发行版**：UIM 在 Debian/Ubuntu 还有包（uim 包在 Debian 里仍存），CentOS/RHEL 老版本的 kinput2 / SCIM（**RHEL6/7 桌面默认 SCIM**）—— 这是重要一例：RHEL/CentOS 6-7 的桌面默认输入法框架就是 SCIM（走 XIM）。
8. Android/Termux？不算。
9. **Windows 下的 WSLg/X410 / Xming**：客户端侧 XIM server（如 fcitx5-win32）—— 桌面 Linux 应用通过 X11 转发到 Windows，走 XIM。
10. **NixOS**：fcitx5/xim bridge（fcitx5-x11）—— 常见。
11. **KDE X11 session + ibus**：KDE 的 ibus platformtheme 也是 dbus，但 X11 应用 fallback XIM。
12. **xinit/Xvfb 无桌面环境（我们的场景）**：很多 CI/无头 X 环境仍用 `XMODIFIERS=XIM`。

> **佐证（2026-11-21）**：GNOME 50 之后，ibus 仍在维护 ibus-x11（2026 年 issue #2931 就是 GNOME 50 / ibus 1.5.34 仍依赖它）→ 证明到 2026 年 XIM 仍是现役路径。

**小结**：XIM 在"桌面首选输入法"位置已被 dbus/portal 取代，但在 **XWayland、fcitx5 桌面 fallback、Qt-X11、Compose key、老发行版（RHEL6-7 SCIM）、X 转发（WSLg/X410/VcXsrv）** 这些场景里仍是现役唯一或主要通道。

#### 3.2、XIM 对接**静态** ibus vs **动态** ibus——流程与对比（2026-11-21）

##### 3.2.1、XIM → 静态版 ibus 流程

```
静态 GTK2 应用 (builtin xim 客户端模块)
  --XIM 协议, @im=ibus--> 静态 ibus-x11  (/usr/local/static/ibus/libexec/ibus-x11, 14.17M,
                             方案 D patch：进程内 GTK2 候选窗自绘)
  --XIM 事件--> IBus 事件 --> 静态 ibus-daemon (-x -p disable -c disable --replace --daemonize)
  --> 静态 ibus-engine-rime (RIME_DATA_DIR=/usr/local/static/deps/share/rime-data)
  <--候选/上屏经 XIM 回调--> 应用；候选窗 = ibus-x11 进程内 GTK2 自绘（深色圆角 v5、Greybird-dark）
```

- **候选窗**：静态侧用**我们 patch 过的 ibus-x11**——收到候选表时**自己用 GTK2 画出来**（`11061251-v-oth-impl02-ibusA.md` §11.7.6.2、§11.1），样式可控（深色圆角、选中蓝 `#398ee7`）。与动态侧最大差别。
- **daemon**：`-x -p disable -c disable --replace --daemonize`（`-x` 顺带拉起 ibus-x11，`ibusA:378`）；`-p disable` = 不走 panel，候选由 ibus-x11 自绘。
- **地址**：静态 daemon 用**私有 bus**，必须 `export IBUS_ADDRESS=$(grep ^IBUS_ADDRESS ~/.config/ibus/bus/* | cut -d= -f2)`（`ibusA` §6.5.1）。
- **引擎**：静态 ibus-engine-rime + rime-data；组件目录 `/usr/local/static/ibus/share/ibus/component/`（daemon 只扫这个）。
- **启动顺序**：先 daemon 再 ibus-x11；引擎若在 rime 用户数据部署前启动会卡死（`ibusA:1330`），daemon 崩溃后全局引擎丢失需 `set_global_engine('rime')`（`:1331`）。

##### 3.2.2、XIM → 静态侧缺陷隐患（特有）

1. **XIM 已被否决为主路径**（`ibusA` §11.7.7）；方案 D「进程内候选窗挂 ibus-x11」这条线**已作废**（`:915`）——ibus-x11 只留作 **XIM 兜底/非 GTK 客户端**（xterm 等）。
2. **单点故障、无重连**：全押 ibus-x11（`:894`）。
3. **无自启动**：部署后手动拉 daemon（`-x` 带 ibus-x11）；忘启 → 我们的 ibus-x11 同样**公告 XIM server 后连不上 daemon 就 exit 但不注销** → `XIM_SERVERS` 残留静默失灵（与动态侧同源 bug）。
4. **私有 bus 麻烦**：查询/调试都必须 `IBUS_ADDRESS`（`:385-388`）。
5. **体积/路径写死**：ibus-x11 14.17M（方案 D 链 GTK2）、daemon 3.8M；`rime.xml` exec/panel 图标绝对路径，挪 `/usr/local/static/` 需同步改。
6. **维护自管**：升级/替换需 `kill` 正在跑的 ibus-x11 再覆盖二进制（`:836`）；无 systemd/XDG autostart。

##### 3.2.3、对比表

| 维度 | XIM → **静态** ibus | XIM → **动态** ibus |
|---|---|---|
| XIM server | 我们 patch 的静态 ibus-x11（14.17M，自绘候选窗） | 系统 `/usr/libexec/ibus-x11` |
| daemon | 静态 ibus-daemon（`-x -p disable -c disable --replace --daemonize`） | 系统 `ibus-daemon -dx` |
| **候选窗** | **我们自绘**：深色圆角 v5、Greybird-dark、样式可控 | 系统 ibus-x11/panel 自绘，**样式不可控**（我们 panel 用不上） |
| 引擎 | 静态 ibus-engine-rime + rime-data（`/usr/local/static/ibus/share/ibus/component/`） | 系统 ibus-engine-rime + librime + rime-data（`/usr/share/ibus/component/`） |
| 地址 | **私有 bus，需 IBUS_ADDRESS** | 默认 dbus，无需 |
| 启动 | 无自启动，手动 daemon（`-x` 带 ibus-x11）+ 无重连 | `ibus-daemon -dx` 一键；XWayland 由 `/etc/xdg/Xwayland-session.d/10-ibus-x11` 钩子自动启 |
| 体积 | 静态栈（ibus-x11 14.17M + daemon 3.8M + engine + rime-data） | 发行版包管理，磁盘/升级归 distro |
| daemon 互斥 | 若系统 daemon 同跑抢 `org.freedesktop.IBus` → 我们 daemon 冲突 | 若我们静态 daemon 自启 → 动态 ibus-x11 连不上 → `XIM_SERVERS` 残留静默失灵 |
| 样式一致性 | 与项目其他静态应用一致（深色圆角） | 系统样式，与项目不一致 |
| 定位 | XIM 兜底/非 GTK 客户端（主路径已由 `GTK_IM_MODULE=ibus`+A2 静态 im 模块+panel 取代） | 只能**应急**，不作最终交付 |
| 共同缺陷 | legacy 协议、单点故障无重连、Qt 不看、个别应用 XIM bug、daemon 必须先起、候选键选择不经 panel | 同左 |

**一句话**：两者走**同一条 XIM 桥**（`GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus` + ibus-x11 + daemon + rime），差别全在**候选窗与 daemon 归属**——静态侧候选窗我们自绘（样式可控、但 XIM 路已否决+单点故障+无自启动），动态侧候选窗系统自绘（样式不可控、有 `XIM_SERVERS` 残留上游实锤 bug）；**共同点：都只能当兜底，不能当主路径**。

### 4、应用顶层：静态程序->静态IBUS:直接对接 vs XIM转接，项目实景分析（2026-11-21）

#### 4.1、纯技术性比较（问答 1 原文，含表格）

**问（用户）**：那再分析下，结合现有的项目场景：现有项目内选用的静态应用对接静态版 ibus，直接对接相比经过 xim 转接，有什么优缺点？

> 附：用户要求「**不要管我历史否不否决**，之前的说法都是那回片面的决策。你新的分析，**不要带上我历史的主观判断**。」——故本节为纯技术性比较（不带历史取舍/否决/兜底/作废措辞）。两者都基于同一静态栈：**静态 ibus-daemon（私有 bus）+ 静态 ibus-engine-rime + rime-data**，差别只在**客户端 im 层**和**候选显示层**。

**答**：

**两条路**（静态 GTK2 应用 → 静态 ibus）：

> **A2 概要**：把 ibus 的 im 模块**静态注册进 libgtk**（`INCLUDE_IM_ibus do_builtin(ibus)` + glue + `libibus-1.0.a` 的 `.o` 合并进 `libgtk-x11-2.0.a`），让静态 musl GTK2 应用也能走 ibus；角色与系统 im 模块相同（连 daemon → 转发候选给 panel），仅把「dlopen 加载」换成「静态注册」。出处：`11061251-v-oth-impl02-ibusA.md` §11.7.9/§11.7.10（A2 定案/桥接确认）、`compile/src/u-gtk/build.sh:135-151`（实现：gtkimmodule.c 加 `INCLUDE_IM_ibus` + ibusim.o 重编 + 合并）。

| | 直接对接 | XIM 转接 |
|---|---|---|
| 客户端侧 | `GTK_IM_MODULE=ibus`：**A2 静态注册** im 模块（`INCLUDE_IM_ibus do_builtin(ibus)`，并入 `libgtk-x11-2.0.a`） | `GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus`：GTK2 **内置 xim** builtin 模块（`--with-included-immodules=xim`） |
| 链路 | im 模块 → **D-Bus 直通 daemon**（绕过 ibus-x11） | 应用 → **XIM 协议** → **ibus-x11**（XIM server）→ daemon |
| 候选显示 | daemon → **panel**（方案 B 独立 GTK2 panel，深色圆角 v5） | **ibus-x11 进程内自绘**（方案 D patch，深色圆角 v5，样式可控） |
| 候选键选择 | 经 panel（选字逻辑完整） | 经 XIM→ibus-x11→daemon→引擎（`ProcessKeyEvent`），不经 panel |

**直接对接（GTK_IM_MODULE=ibus / A2）优缺点**

- 优点：
  1. **标准配置、通用习惯**——与主流 ibus 部署完全一致，工具链/文档/用户习惯零偏离。
  2. **候选统一由 panel 显示**——静态应用、系统应用、Qt 应用**全部汇聚到同一个 panel**，候选样式、选字逻辑、语言栏/托盘全一致（A2 与系统 im 模块角色相同，只是把 dlopen 换成静态注册）。
  3. **不依赖 ibus-x11 进程**——im 模块直连 daemon，少一个单点；且 im 模块那套**有重连逻辑**。
  4. **无 `XIM_SERVERS` 残留类问题**——不走 X 属性协商，无"公告了 server 但连不上"的静默失灵面。
- 缺点：
  1. **需要改库**——A2 要把 ibusimcontext.c 静态编入 + patch `gtkimmodule.c` + 合并 `libibus-1.0.a` 的 `.o` 进 `libgtk-x11-2.0.a`，属 u-gtk 重编，`libgtk` 体积增大。
  2. **影响面大、需全量重链**——所有静态 GTK2 应用共用这一份 libgtk，一处改、全生效；改一次 u-gtk 后相关静态应用都要重链。
  3. **需要 panel 常驻**——独立可执行、自管理/自启动；panel 挂掉则候选不显示（daemon `-p` 需指到它）。
  4. **仅覆盖 GTK 应用**——Qt 应用要看 `QT_IM_MODULE=ibus`（不在我们 libgtk 范围）；非 GTK X 客户端（xterm/vim）**走不了这条路**。
  5. **依赖 dbus session + `IBUS_ADDRESS`**（静态 daemon 私有 bus）。

**XIM 转接（GTK_IM_MODULE=xim）优缺点**

- 优点：
  1. **零 libgtk 改动**——XIM 是 GTK2 **原生内置** builtin 模块，`--with-included-immodules=xim` 已编进当前静态 libgtk，不需要 A2、不需要改 u-gtk。
  2. **覆盖所有 X 客户端**——XIM 是 X 协议层，不只 GTK2：xterm/vim/Motif/老 X 应用都能接 ibus（**非 GTK 客户端只有 XIM 这条通道**）。
  3. **不需要 panel**——候选由 ibus-x11 进程内 GTK2 自绘（深色圆角 v5，样式可控），少一个常驻进程、少一个 panel 服务实现。
  4. **跨 toolkit 通用**——GTK2/GTK3/Qt 在 X11 下都能走 XIM（只要设 `XMODIFIERS=@im=ibus`）。
  5. **不依赖 dbus session 直连**（经 X 属性协商，XIM server 在 X display 注册）。
- 缺点：
  1. **单点故障、无重连**——整条链路押在 `ibus-x11` 进程上；它崩了/没起来全断，**im 模块那套有重连，XIM 没有**。
  2. **legacy 协议**——GTK3/GTK4 对 XIM 支持弱或有 bug（光标定位、内嵌 preedit、候选选字都有坑）；个别应用有 XIM 专属 bug；Qt 看 `QT_IM_MODULE` 不看 `GTK_IM_MODULE`（只设 GTK_IM_MODULE=xim 对 Qt 无效）。
  3. **必须同时设两个变量**——只设 `XMODIFIERS=@im=ibus` 不可行（会把 `ibus` 当模块 dlopen）；`GTK_IM_MODULE=xim` 也必须设。
  4. **候选键选择不经 panel**——选字逻辑走 XIM 回调，部分应用候选选字有坑。
  5. **需要 ibus-x11 运行**——多一个大进程（14.17M，方案 D patch 自绘），且由 daemon `-x` 拉起，**先有 daemon 才有 x11**。
  6. **`XIM_SERVERS` 残留风险**——ibus-x11 连不上 daemon 时 exit 但**不注销已公告的 XIM server** → 客户端指向不存在的 server → 静默失灵。

**一句话**：直接对接 = 标准 + 候选统一 + 无 XIM 单点，代价是**要改库（A2）、要 panel 常驻、只覆盖 GTK**；XIM 转接 = 零改库 + 覆盖所有 X 客户端 + 免 panel，代价是**单点故障无重连、legacy 协议坑、必须设两变量、候选选字不经 panel、多一个大进程**。对"现有静态 GTK2 应用"这一群体，**两者都能用**；XIM 的额外价值只在"非 GTK X 客户端（xterm/vim）"和"不想改库"这两点上，直接对接的额外价值在"标准配置 + 候选一致 + 可靠性"。

#### 4.2、结合项目实际场景分析（问答 2 原文，含表格）

**问（用户）**：结合当前项目的实际场景来分析（追问：实际在用的这些特定的 APP 应用来分析）。

> 按项目**实际在用**的应用来分（结合"headless X11 + openbox/tint2 + 无桌面环境 + 跨发行版"场景 + "A2 只确认 pcmanfm 已带"这一实情）。

**答**：

**应用分组（按 IM 相关性）**

- **A 组——真正需要中文输入（有文本/编辑框，GTK2）**
  - **geany**（编辑器，主力输入场景）
  - **pcmanfm / thunar**（文件管理器：重命名 + `Ctrl+L` 路径栏，pcmanfm 已实测 `Ctrl+L`→`你好` 回读）
  - **engrampa**（新建/重命名文件名）
  - **gsm / pavucontrol / xfce4-settings**（过滤/搜索框，gtkmm）
  - lxtask（任务管理器，无实质输入，可忽略）
- **B 组——无 IM 需求或非 GTK**
  - gpicview / ristretto（看图，无输入）
  - xlunch / feh / scrot（imlib2）、hsetroot、dunst、xbindkeys、xrandr、pasystray、openbox/fluxbox/tint2（非 GTK/无输入）
  - **rofi**（xcb + cairo + pango **直接渲染，不依赖 GTK**）——启动器有输入框，但**不走 GTK im 模块**，唯一可能通道是 XIM（且取决于 rofi 自身是否实现 XIM，需单测）

**项目场景关键实情**

1. **A2 直接对接当前未全覆盖**：`11061251-v-oth-impl02-ibusB.md` §2.2（原 §11.8.3 遗留 #2）——「仅 **pcmanfm 已带 ibus**；geany/lxtask/engrampa 等 build 树已失，需重建才带 ibus」→ 对已交付二进制，A2 并非立即可用。（A2 概要见 4.1「两条路」下块引用）
2. **XIM 零改库、立即可用**：当前静态 libgtk 已内置 xim（`--with-included-immodules=xim`）→ **所有已交付的 GTK2 静态应用（A 组全体）设两个变量即可走 XIM，不用重链任何应用**。
3. **项目主力是 GTK2**（pcmanfm/geany/engrampa/thunar…），GTK2 对 XIM 支持成熟（`ibusA` §11.7.6：GTK2 出问题概率低）。
4. **无桌面环境**：非 GNOME/KDE，没有 portal/textinput，**XIM 是 X 层唯一通用通道**；且非 GTK X 客户端（xterm/vim/老 X 应用）**只能走 XIM**。
5. **跨发行版部署**（alpine/ubuntu/opensuse/…）：系统动态 ibus 不是目标，我们提供**自包含静态栈**（daemon + panel/ibus-x11 + rime 全静态，不依赖 distro）。

**对比（针对 A 组实际应用）**

| | 直接对接（A2 + panel） | XIM 转接（ibus-x11 自绘） |
|---|---|---|
| 对现有交付二进制 | **仅 pcmanfm 已带**；geany/engrampa/thunar/lxtask **需重建/重链** | **立即可用**（libgtk 已内置 xim，零重链） |
| 覆盖 A 组（GTK2） | ✅（待 #2 闭环后） | ✅ 全部 |
| 覆盖 B 组 / xterm / vim | ❌（GTK 专属） | ✅（X 层通用，rofi 视其自身实现） |
| 候选显示 | panel（深色圆角 v5，**全部客户端汇聚一处**） | ibus-x11 进程内自绘（深色圆角 v5，样式一致） |
| 配置 | `GTK_IM_MODULE=ibus` + `IBUS_ADDRESS`（标准、通用） | `GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus`（必须两个） |
| 可靠性 | 不依赖 ibus-x11，**有重连**；panel 挂则候选不显示 | **单点故障**（押 ibus-x11）、**无重连** |
| 常驻进程 | panel（独立可执行，自管理） | ibus-x11（14.17M，daemon `-x` 拉起） |
| 选字 | 经 panel（逻辑完整） | 不经 panel（XIM 回调，个别应用有坑） |
| 维护 | u-gtk 重编（A2）+ 各应用重链 | 零库改动 |

**结论（项目场景）**

1. **当下能立刻用上的**：对已交付二进制 + 主力 GTK2 应用，**XIM 是唯一零重链路径**——`GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus` 即可，覆盖 A 组全部 + xterm/vim；代价是单点故障（ibus-x11）无重连 + 必须设两变量。
2. **更优但需投入的**：A2+panel——标准配置、候选统一、无 XIM 单点、有重连；但要把**待办 #2（真实应用全重链）闭环**（geany/engrampa/thunar/lxtask 重建/重链）并让 panel 常驻。
3. **实际建议（不预设取舍）**：**先 XIM 顶上**（零成本覆盖现有全部），**再按 #2 把 A2 全重链闭环后切回 `GTK_IM_MODULE=ibus` 标准配置**；两者可并存——GTK2 应用走 A2、非 GTK（xterm/vim/rofi）走 XIM，panel 与 ibus-x11 自绘都能被同一 daemon 服务。
4. **提醒**：pcmanfm 是唯一已验双路（A2 `GTK_IM_MODULE=ibus` §9 与 XIM §6 都实测通过）的样板；geany/engrampa/thunar 的 XIM 路未实测，落地前各跑一次 `nihao` 验证。

### 5、总结篇：静态/动态 ibus 服务 × 动/静态应用的接入矩阵（2026-11-21）

#### 5.1、最终环境 vs 过渡环境——用户理解核对（问答原文，2026-11-21）

**问（用户）**：

> 实际建议（不预设取舍）：先 XIM 顶上（零成本覆盖现有全部），再按 #2 把 A2 全重链闭环后切回 `GTK_IM_MODULE=ibus` 标准配置；两者可并存——GTK2 应用走 A2、非 GTK（xterm/vim/rofi）走 XIM，panel 与 ibus-x11 自绘都能被同一 daemon 服务。
>
> 这块结合整篇，说下我的理解，看是否准确
>
> 1、最终环境:全静态ibus/ibus-x11/xim服务 供动静态应用使用。
> 1a.gtk2静态应用，在gtk的a库集成ibus-x11支持免dlopen调用ibus-x11的库，与ibus-deamon直通，另xim默认即支持的
> 1b.xterm/st/rofi等静态非gtk应用，只能xim模式，或也得静态集成ibus-x11
> 1c.系统动态应用，经ibus-x11.so库与ibus-deamon直通，xim模式一样支持的
>
> 2、过渡环境:动态ibus/ibus-x11/xim服务 供动静态应用
> 2a.gtk2静态应用，xim默认即支持。理论来说gtk的a库集成ibus-x11支持免dlopen，它也能与动态ibus-deamon直通？？
> 2b.xterm/st/rofi等静态非gtk应用，同上段。
> 2c.系统动态应用，同上段。

**答**：

你的骨架是对的，但有 **3 处术语/归类需要修正**，其中 **2a 的答案是 YES**（这恰好是整篇的关键结论）。逐项核对：

##### 5.1.1、需要修的 3 处

**①、「ibus-x11」≠「im-ibus 模块」——两个完全不同角色（1a、1c、2c 都踩了）**

| 组件 | 角色 | 位置 | 谁用它 |
|---|---|---|---|
| **im-ibus 模块**（`ibusim.o` + `libibus` 客户端） | **客户端侧**：GTK 应用的输入法模块 | A2：静态注册进 `libgtk-x11-2.0.a`；动态：`/usr/lib/.../im-ibus.so` 被 GTK dlopen | GTK 应用（1a/2c） |
| **ibus-x11** | **服务端**：X 层 **XIM server 进程** | `/usr/libexec/ibus-x11`（静态 14M 在 `/usr/local/static/ibus/libexec/`） | 非 GTK 的 X 客户端（xterm/vim/老 X 应用）+ 所有走 `GTK_IM_MODULE=xim` 的应用 |

文档里 A2 的原文是「把 **ibus 的 im 模块**静态注册进 libgtk」（`INCLUDE_IM_ibus do_builtin(ibus)`），**不是把 ibus-x11 塞进 a 库**。ibus-x11 是被 `ibus-daemon -x` **拉起的一个进程**（见 2.3/2.4 行 427、441），它不链接进任何应用。

**所以 1a 准确说法**：libgtk 集成 **im-ibus 模块**（免 dlopen），经 D-Bus 连 daemon。

**②、「直通」不准确——是 D-Bus，不是进程内**

im-ibus 模块是 `libibus` 客户端，**经 D-Bus 会话总线**连 `ibus-daemon`（同 session 内 `DBUS_SESSION_BUS_ADDRESS`，daemon 持有 `org.freedesktop.IBus` 名字）。不是进程内直通。

不过意图（"比 XIM 少一层、是标准通道"）是对的——这正是 `GTK_IM_MODULE=ibus` 相对 `xim` 的差别。

**③. rofi 归类——文档 4.2 原判正确，答复初稿曾误判「rofi 是 GTK 应用」已被订正**

> **订正（2026-11-21）**：本节答复初稿曾称「rofi 是 GTK 应用、属 1a 侧」——**该说法错误**。rofi 官方依赖清单（`davatorium.github.io/rofi/INSTALL/`、`meson.build`）不含任何 GTK：`libpango / libpangocairo / libcairo / libcairo-xcb / libglib2.0 / gmodule-2.0 / gio-unix-2.0 / libgdk-pixbuf-2.0 / libstartup-notification / libxkbcommon(-x11) / libxcb / xcb-util*`，**无 gtk+-2.0/gtk+-3.0** → 文档 4.2 B 组原判「xcb + cairo + pango 直接渲染，不依赖 GTK」**正确**（老版 rofi 1.x 曾用 GTK，meson 化的 2.0 已移除）。

- **rofi 是 xcb+cairo+pango 直渲染、不依赖 GTK** → 属 **1b 侧（非 GTK）**，不是 1a 侧；真·非 GTK 群体应为 **xterm / st / rofi**（+ vim/老 X 应用）。
- **XIM 通道有据（印证 4.2「唯一可能通道是 XIM、需单测」）**：rofi 有**可选依赖 `xcb-imdkit`（≥1.0.3 优先）**——imdkit 正是 **XCB 侧的 XIM 协议库**；需**编译时开 `-Dimdkit`** 才启用，故仍须实测单测。
- 1b 里"或也得静态集成 ibus-x11"——机制也不对：非 GTK 应用要静态集成的是 **`libibus-1.0.a` 客户端 + 自己写 D-Bus 客户端代码**（不是 ibus-x11，那是服务端）；而且**没有实际收益**（候选窗仍在 daemon 侧画），所以 XIM 就够了。

##### 5.1.2、逐项结论

| 你的条目 | 判定 | 修正/补充 |
|---|---|---|
| **1** 最终全静态 daemon+ibus-x11+xim 服务 | ✅ 对 | 与 2/3 目标一致 |
| **1a** gtk2 静态：libgtk 集成 im-ibus、免 dlopen、连 daemon；xim 默认即支持 | ✅ 对（术语改 im-ibus） | 「默认即支持」= `--with-included-immodules=xim` 内置模块，**零成本**，正确 |
| **1b** xterm/st（+rofi）只能 xim，或静态集成 | ⚠️ 半对 | rofi **留在此组**（非 GTK，XIM 需编译开 `-Dimdkit`）；xterm/st/rofi **只能 XIM**（X 层唯一通用通道），静态集成 ibus 客户端无收益 |
| **1c** 系统动态应用经 ibus-x11.so 直通，xim 也支持 | ⚠️ 术语错 | 经**系统 im-ibus.so**（GTK dlopen）走 D-Bus；xim 模式确实同样支持 |
| **2a** 静态 libgtk 集成 im-ibus，**能否**对接**动态** daemon？ | ✅ **YES** | 见下 |
| **2b** 同 1b | ✅ | 且与 daemon 形态**无关**——XIM 是 X 层协议，任何环境都只能 XIM |
| **2c** 同 1c | ✅ | |

##### 5.1.3、2a 的答案：YES，而且这是整篇的枢纽

**A2 是纯 client 侧改造**（把 im 模块从「dlopen 系统 `.so`」换成「静态注册」）。im-ibus 连 daemon 走的是 **D-Bus 协议**——daemon 是**另一个进程**，它自己是静态还是动态二进制，对 client **完全无关**。

所以过渡环境里，A2 应用 + 动态 daemon **今天就可用**，条件只有：

- 同 D-Bus session（`DBUS_SESSION_BUS_ADDRESS` 指向动态 daemon 所在 bus）
- ibus 版本大致匹配（我们静态编的 `libibus` 客户端 vs 系统 daemon 的 D-Bus 接口版本）
- 别让我们的静态 daemon 同时抢 `org.freedesktop.IBus`（见 2.5 隐患 6 / 3.2 对比表「daemon 互斥」行）

**代价只有一个：候选窗**。候选窗由 **daemon 侧的 panel 进程**画——过渡期由动态 ibus 的 panel 画（**样式不可控**，我们 patch 过的静态 panel 用不上）；全静态后才是我们自绘的深色圆角 v5。

**推论**：4.2 结论第 3 条「先 XIM 顶上 → 再切 `GTK_IM_MODULE=ibus`」里，**切换的前置条件不是 daemon 静态化**，而是 **A2 全覆盖重链**（当前仅 pcmanfm 带 ibus，§2.2）。daemon 全静态化解决的是候选窗样式 + 不依赖 distro 装 ibus，是更晚的事。

#### 5.2、`GTK_IM_MODULE` 变量冲突范围 / 非 GTK2 应用 IM 支持细化（问答原文，2026-11-21）

**问（用户）**：

> 输入法环境配置方面，还有一点 `GTK_IM_MODULE=xim` + `XMODIFIERS=@im=ibus`，这个环境变量的设置与 x11base 项目内 rootfs 现有 ibus 的设定应该是冲突的，只能二选一，
>
> 考虑默认用后者 用现有的变量，让只能 xim 的应用:要么他原本应该就不受 `GTK_IM_MODULE=ibus` 的影响，要么就得改造他即使指定 ibus 也转用 xim。这块可以根据项目实际使用的非 gtk2 的应用具体细化一下先。
>
> 然后余下的输入法侧: 无论动静态 ibus，把 ibus/ibus-x11 装好并运行即可。ibus 为本体，ibus-x11:提供 ibusim.so 库+ibus-x11 的 XIM Server 服务程序。

**答**：

**①、冲突的真实范围：比"二选一"更小**

**`GTK_IM_MODULE` 只有 GTK 读它。** 非 GTK 应用（st/rofi/tint2/xcompmgr/dunst…）压根不读这个变量，只认 `XMODIFIERS`。所以：

- **非 GTK 应用 vs `GTK_IM_MODULE=ibus` = 零冲突**（第一分支"原本就不受影响"完全成立）。
- **只有 GTK 应用才真正互斥**：一个 GTK 应用要么 im-ibus（A2）、要么 builtin xim，由 `GTK_IM_MODULE` 二选一。

**②、第三选项：`GTK_IM_MODULE` 支持冒号回退列表（upstream 原生）**

你列的两个分支（不受影响 / 得改造它）之间，其实有**第三个：不用改应用、不用 per-app 覆盖**。

`gtkimmodule.c` 的 `lookup_immodule()` 用 `g_strsplit(envvar, ":", 0)` **逐个试**（GTK2 2.24 起，backport bug #603559；`docs/reference/gtk/running.sgml` 明写 "This also can be a colon-separated list of input-methods, which GTK+ will try in turn until it finds one available"）。

即 **`GTK_IM_MODULE=ibus:xim`**：

| 应用 | 行为 |
|---|---|
| A2 应用 | 命中 `ibus` → D-Bus 直连 daemon（标准路径） |
| 非 A2 的 GTK2 应用 | `ibus` 未注册 → `g_warning("No IM module matching GTK_IM_MODULE=%s found")` → **继续试 `xim`** → 命中 builtin → 走 XIM |

**未命中时 GTK 不会崩**，只会 warning + 一路退到 `gtk-im-context-simple`（无输入法、仅 ASCII）。

⚠️ **唯一前提需实测**：我们的 libgtk 被 A2 patch 过，**改的正是 `gtkimmodule.c`**。需确认 patch 后仍保留 `g_strsplit(envvar` + `No IM module matching` 这两段（`grep` 我们的源码即可）。这是把"二选一"变成"一个全局变量通吃两类 GTK 应用"的关键。

**③、非 GTK2 应用细化（按 `compile/src/` 实际清单）**

**有文本输入的只有 2 个**：

| 应用 | XIM 支持现状 | 需要的动作 |
|---|---|---|
| **st**（suckless，`br-luke-st`） | **现成有**：`st.c` 的 `xinit()` 内建 `XOpenIM`/`XCreateIC`，不依赖 GTK | 零改造，设 `XMODIFIERS=@im=ibus` 即用 |
| **rofi**（`x-rofi`，2.0.0） | **当前被关掉**：`compile/src/x-rofi/build.sh:206-208` 明写 `-Dimdkit=false` | 要支持需**重编**：`-Dimdkit=true` + 静态 `libxcb-imdkit.a`（xcb 侧 XIM 库，≥1.0.3） |

其余非 GTK 组件（openbox/fluxbox/tint2/xcompmgr/dunst/xbindkeys/xrandr/xlunch/feh/scrot/hsetroot/pasystray + xrdp/tigervnc/x11vnc/dropbear/pulseaudio/dbus/perp/xdpyprobe）**无文本输入框**，与 IM 无关（openbox/fluxbox 菜单也无内建输入框）。

**所以本问方案可以收敛成一句**：非 GTK 侧只有 st 现成、rofi 需开 imdkit 重编，其余不用管。

**④、"默认用现有变量"的成本，要盯住一处**

保持 `rootfs/src/entry.sh:185-190` 现值（`GTK_IM_MODULE=ibus` + `XMODIFIERS=@im=ibus`）：

- ✅ A2 应用标准路径；非 GTK 应用完全不受影响
- ⚠️ **代价**：未做 A2 的 GTK2 应用（geany/engrampa/thunar/lxtask，§2.2 未全覆盖）→ `ibus` 未注册 → **静默降级成 simple（无输入法）**，只留一条 warning。这是这条路的真实风险点，不是"不影响"。
- ✅ 用 `ibus:xim` 回退列表即消掉该风险（未 A2 自动落 xim，无需改造、无需 per-app）。

**⑤、ibus 侧：归属说法要修一处**

按 ibus 上游 `meson.build` 的构建目标划分：

| 产物 | 源码 | 归属 | 说明 |
|---|---|---|---|
| `im-ibus.so`（GTK2 客户端 im 模块） | `client/gtk2/`（`ibusim.c` + `ibusimcontext.c`） | **ibus 本体** | 装 `<libdir>/gtk-2.0/<ver>/immodules/` |
| `ibus-x11`（XIM Server 程序） | `client/x11/`（`gdk-private.c` + `main.c`） | ibus-x11 | 装 `<libexecdir>/`，链 **libimdkit**，由 daemon `-x` 拉起 |

**`im-ibus.so` 不属于 ibus-x11**，它是 ibus 本体的 `client/gtk2` 目标；两者同源于 ibus 源码树但**是独立构建目标**。

顺带一个对称细节：ibus-x11 用 **libimdkit**（X11 侧 XIM 库），rofi 的 `-Dimdkit` 用 **xcb-imdkit**（xcb 侧 XIM 库）——同一套 XIM 协议的两侧实现，一个服务端、一个客户端。

**结论那半句完全成立**：无论动静态，把 `ibus` 装好、跑 daemon + `-x` 起 ibus-x11 即可。

> 附（措辞订正）：答复原文写"rofi 的 `-Dimdkit`"，准确说是 rofi 的**可选依赖 `xcb-imdkit`（≥1.0.3 优先）**，经 meson 的 `-Dimdkit` 开关启用；`-Dimdkit=true` 具体写法待 `meson_options.txt` 核对。
#### 5.3、`im-ibus.so` 独立性 / 各发行版分包——系统动态应用对接静态 ibus（问答原文，2026-11-21）

**问（用户）**：

> `im-ibus.so`（GTK2 客户端 im 模块），那系统的动态应用要支持对接静态 ibus 时，安装这个库不是得安装完整的动态 ibus 包？有独立的子包，只包含这个库的吗？

**答**：

结论分两层：**`im-ibus.so` 不是自足的**（还需要 `libibus-1.0.so` 客户端库），而且**子包情况分发行版**——Debian/Fedora 有独立子包，Arch/Alpine 没有。

**①、先纠正一个前提：不需要"完整的动态 ibus"**

`im-ibus.so` 是**客户端** im 模块，走 **D-Bus** 连 daemon。系统动态应用对接**我们的静态 daemon** 时：

- daemon = **我们的静态**那个（不需要 distro 的动态 daemon）
- `im-ibus.so`（distro 动态）+ `libibus-1.0.so`（distro 动态客户端库）→ 经 D-Bus 连静态 daemon

所以**不需要装 distro 的 daemon/engine/data/panel**，只需要 im 模块 + 客户端库这两个动态组件。

**②、`im-ibus.so` 本身不独立：必须带 `libibus-1.0.so`**

`im-ibus.so` 是 `shared_module('im-ibus', [ibusim.c, ibusimcontext.c], deps: [ibus_dep, gtk2_dep, dbus_dep])`——**它链接 `libibus-1.0.so` + libgtk2 + libdbus**。所以"只装这一个 `.so`"不成立，必须同时有 **`libibus-1.0.so`（客户端库）**。这正是"独立的子包只有这一个库吗"的答案核心。

**③、子包情况（分发行版，实测文件清单）**

| 发行版 | 有独立子包？ | 实际分包 | 装什么即可 |
|---|---|---|---|
| **Debian/Ubuntu** | ✅ **有** | `ibus-gtk`（**仅** `im-ibus.so` GTK2，329.7k）、`ibus-gtk3`、`ibus-gtk4`、`libibus-1.0-5`（客户端库）、`ibus`（daemon/engine/data） | `ibus-gtk` + `libibus-1.0-5`（GTK2）；GTK3 应用用 `ibus-gtk3` |
| **Fedora/RHEL** | ✅ **有** | `ibus-gtk2`、`ibus-gtk3`（仅 `im-ibus.so`）、`ibus-libs`（`libibus-1.0.so.*`）、`ibus` 主包 | `ibus-gtk2` + `ibus-libs` |
| **Arch** | ❌ 无 | 单 `ibus` 包（`im-ibus.so` + `libibus-1.0.so` + daemon 全含） | `ibus`（单包） |
| **Alpine** | ❌ 无 | 单 `ibus` 包（3.1 已核：含 `libexec/ibus-x11` + im 模块） | `ibus`（单包） |

**Debian 系最省**：`apt install ibus-gtk libibus-1.0-5`（GTK2）即可，**不装 `ibus` 主包**；但注意 `ibus-gtk` 依赖链 `libgtk2.0-0`/`libpango`/`libglib`/`libc6`——都是给**系统动态应用**用的，正好匹配，与我们静态栈无关。

**④、真正要盯的一条**

系统动态应用既然要 ibus 输入，**它的 distro 必然有 im 模块 + 客户端库**（拆不拆包都行），我们**无需提供任何动态库**。但必须防 **distro 的动态 `ibus-daemon` 自启**去抢 `org.freedesktop.IBus`（2.5 隐患 6 / 3.2「daemon 互斥」行）——不然我们的静态 daemon 就白起了。

**⑤、版本兼容**

distro 的 `libibus-1.0.so.5` + `im-ibus.so` 连我们**静态** daemon，走 D-Bus；要求两边 **ibus 主版本一致**（都是 1.5.x）→ D-Bus 接口/GVariant 兼容即可，一般无碍。

**补充判断**：**firefox 是 GTK3**，需要的是 `ibus-gtk3` 的 `im-ibus.so`（不是 GTK2 的），对应 1.2 已记的 firefox 走 `GTK_IM_MODULE=ibus` + GTK3 im 模块。

#### 5.4、ibus 1.5.x 年代与主要发行版覆盖（问答原文，2026-11-21）

**问（用户）**：

> distro 的 `libibus-1.0.so.5` + `im-ibus.so` 连我们静态 daemon，走 D-Bus；要求两边 ibus 主版本一致（都是 1.5.x）。
>
> 1.5.x 这个版本是什么时候出来的？都支持主要发行版的哪些版本？

**答**：

项目静态 ibus 是 **1.5.35**（最新版），这把兼容风险直接降到近零。

**①、1.5.x 是什么时候出来的？**

**2012-12-07**（upstream `1.5.0` 发布；Arch 当天打包 `ibus 1.5.0-1`）。Ubuntu 首次进库是 2013-09（saucy 1.5.3）。

- **已活了 ~13.9 年，且至今仍是现行主线**：最新 **1.5.35**（2026-09-22）。
- 期间累计 **100+ 个小版本**（1.5.0 → 1.5.35）。
- 上一代 **1.4.x** 早已 EOL（2013-2014 退役）；**没有任何主流发行版还用 1.4.x**。

所以"两边都是 1.5.x"这个条件，**事实上几乎所有 2013 年以后的 Linux 都满足**——1.5.x 不是老版本，是唯一的现役主线。

**②、主要发行版支持情况（实测包版本）**

| 发行版 | 版本 | ibus | 发行版 | 版本 | ibus |
|---|---|---|---|---|---|
| **Debian** | 11 bullseye | 1.5.23 | **Ubuntu** | 20.04 focal | 1.5.22 |
| | 12 bookworm | 1.5.27（bpo 1.5.31） | | 22.04 jammy | 1.5.26 |
| | 13 trixie | 1.5.32 | | 24.04 noble | 1.5.29 |
| | 14 forky / sid | 1.5.35 | | 25.10 / 26.10 | 1.5.32 / 1.5.34 |
| **Fedora** | 40 / 42 | 1.5.30 / 1.5.32 | **openSUSE** | Leap 15.5 / 15.6 | 1.5.25 / 1.5.28 |
| | 43 / 44 / 45 | 1.5.33 / 1.5.34 / 1.5.35 | | Tumbleweed | 1.5.35~rc1 |
| **Alpine** | 3.17 / 3.18 | 1.5.27 | **Arch** | 现行 | 1.5.34 |
| | 3.21 / 3.23 | 1.5.31 / 1.5.33 | **项目静态 ibus** | v-ibus | **1.5.35** |
| | 3.24 / edge | 1.5.35 | | | |

（数据：Repology / Launchpad / Fedora Packages / Alpine pkgs / Debian tracker，2026-11 核对）

**③、对"对接"的实际含义**

1. **所有目标发行版都 ≥1.5.22、最新 ≥1.5.35**，且项目静态 daemon = **1.5.35**（最新）→ D-Bus 接口/GVariant 兼容**基本零风险**。
2. 1.5.x 内部的 D-Bus 接口**只增不删**（新特性/新信号加接口，不破坏旧）→ 跨小版本兼容性稳定。真正要防的不是版本号，而是：
   - **distro 动态 daemon 抢 `org.freedesktop.IBus`**（2.5 隐患 6）
   - 极端情况：我们静态 daemon 若是**很旧的** 1.5.x、客户端是**很新的** 1.5.x，可能缺新接口 → 但本项目是 1.5.35，**无此问题**。

**一句话**：1.5.x 是 2012 年底至今 13 年、100+ 版的唯一现役主线；项目静态 ibus 又是最顶的 1.5.35，所以"两边主版本一致"在全部目标发行版上**天然成立**，兼容风险可忽略。