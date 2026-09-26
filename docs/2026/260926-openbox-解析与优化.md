# openbox解析与优化

> 日期: 2026-09-26 | 范围: `compile/src/openbox/` 静态构建链路
> 涉及: openbox 3.6.1 / pango 1.49.3 / libXrandr 1.5.3 / fontconfig 2.14.0
> 构建基底: `infrastlabs/x11-base:alpine-builder-gtk224` → 运行基底 `alpine:3.13.12`

## 一、openbox 静态构建解析与优化

### 1. 构建位置与产物

| 项 | 内容 |
|---|---|
| 源码 | `compile/src/openbox/` (build.sh + 2 个 patch + config.sub + xx-clang-wrapper) |
| Docker stage | `compile/src/Dockerfile:146-166` (`FROM base AS openbox`) |
| 安装前缀 | `TARGETPATH=/usr/local/static/openbox` |
| 下游 | `COPY --from=openbox ${STATIC} /rootfs${STATIC}` (Dockerfile:359) → `rootfs/src/static/clear/clear.sh` 裁剪 + UPX |
| 最终产物 | `bin/openbox` 915K、`bin/obxprop`、`bin/openbox-session` + `etc/xdg/` 配置 + `share/themes/` + `share/xsessions/`，**整目录 2.0M**（`docs/t2-x11-use.md:45`），对比 fluxbox 46M |

### 2. Dockerfile 分派链

```
buildx.sh → COMPILE_OPENBOX=yes/no
Dockerfile:154  mkdir -p $TARGETPATH
Dockerfile:155  bash build.sh cache      # 预下载 4 个 tarball
Dockerfile:157  test "yes" != "$COMPILE_OPENBOX" && exit 0   # 开关
Dockerfile:159  bash build.sh b_deps     # apkdeps + apk add fontconfig-{dev,static} + libxrandr & pango &
Dockerfile:160  bash build.sh openbox    # 打补丁→configure→make→install→xx-verify
```

**关键点**：openbox 的依赖安装函数被全项目复用 —— `u-gtk/build.sh:183-185` 直接调用 `openbox/build.sh apkdeps / pango / libxrandr`，再烘焙进 `alpine-builder-gtk224` 基础镜像。也就是说 **openbox/build.sh 实际上是全项目的"X11+字体栈静态依赖提供者"**，是构建体系的中枢而非普通组件脚本。

### 3. 依赖分层（三类）

#### 3.1 自编译静态库（Alpine 仓库不提供 .a）

`build.sh:115-166`

| 库 | 版本 | 构建系统 | 静态参数 |
|---|---|---|---|
| pango | 1.49.3 | meson | `-Ddefault_library=static -Dintrospection=disabled -Dgtk_doc=false` + `/tmp/meson-cross.txt`（指向 `xx-info sysroot`，`pkg_config_libdir` 重定向） |
| libXrandr | 1.5.3 | autotools | `--disable-shared --enable-static --enable-malloc0returnsnull` |
| fontconfig | 2.14.0 | autotools | 见 8.1 |

#### 3.2 Alpine `-static` 包

（`apkdeps`，`build.sh:336-364`）：glib / fribidi / harfbuzz / cairo / freetype / expat / libpng / zlib / bzip2 / xz(lzma) / graphite2 / brotli 共 12 个 static；配 `-dev` 头文件：libxft / libxml2 / libx11 / libxcb-static / libxdmcp / libxau / pcre / libxrender / libffi。

#### 3.3 运行时自带

musl libc 本身、openbox 自产 `libobt.a` / `libobrender.a`。

### 4. 静态链接的三个核心技巧（本脚本的精华）

#### 4.1 全局强制静态

`common.sh:8-14`

```sh
CFLAGS="-Os -fomit-frame-pointer"
LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
CC=xx-clang CXX=xx-clang++
```

`--static` 放两次（GNU ld 标志 + 兼容写法），`--as-needed` 会丢弃未引用符号的静态库，`--strip-all` 直接产出可执行体积。

#### 4.2 手写传递闭包 + group 解决顺序依赖

`build.sh:278-288`

```sh
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype \
 -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon \
 -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 \
 -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"
OB_LIBS="$OB_LIBS -luuid"
LDFLAGS="$LDFLAGS -Wl,--start-group $OB_LIBS -Wl,--end-group" LIBS="$LDFLAGS" ./configure
```

pango↔harfbuzz↔glib↔cairo 存在循环引用，单线 `-l` 无法一次链接成功。做法是：**手动枚举 27 个库的完整传递闭包，整包塞进一个 `--start-group`**；同时 `LIBS="$LDFLAGS"`，因为 autoconf 会把 LDFLAGS 和 LIBS **各自**拼到链接行，group 才能在 libtool 介入前就已成型。这也是为什么 `LDFLAGS="-static"` 单加不行（`build.sh:307` 注释 "still dyn"）。

#### 4.3 xx-clang-wrapper 修复 libtool 重排

`xx-clang-wrapper:9-32`

```sh
if ! echo "$*" | grep -q "\-Wl,--start-group -Wl,--end-group"; then exec xx-clang "$@"; fi
```

openbox 用 libtool 构建 `libobt/libobrender`，**libtool 会把 LDFLAGS 里的所有参数重新排序**，导致库跑到 group 外面 → group 失效。wrapper 的检测条件是"两个 group 标志相邻（中间无库）"，命中即认为已被 libtool 打散：扫描全部参数，把 `-l*` / `*.a` 抽到 `libs`，其余（含 .o、-o）留在 `args`，最后重组为 `args -Wl,--start-group libs -Wl,--end-group`。guard 用 `$*` 拼接后再 grep，保证跨参数边界也能命中。代价是 `-Wl,--export-dynamic` 被主动丢弃（无害，纯静态无导出需求）。

`build.sh:25` `export CC=xx-clang-wrapper` 覆盖了 common.sh 的 `CC=xx-clang`，并在 `pango_meson` 里 `cp` 到 `/usr/bin`（供 libtool 子进程调用）。

### 5. 功能裁剪 → 依赖削减对照

`docs/wm/openbox.md:29-97` 记录了 Ubuntu 动态版的 `ldd` 全清单（60+ 库），作为裁剪基线：

| configure 开关 | 直接剔除的动态库 |
|---|---|
| `--disable-xcursor` | libXcursor |
| `--disable-xinerama` | libXinerama |
| `--disable-librsvg` | librsvg-2 / libgdk_pixbuf-2.0（连带 gmodule/gobject 部分路径） |
| `--disable-startup-notification` | libstartup-notification-1 |
| `--disable-session-management` | libICE / libSM |
| `--disable-xkb` | XKB/XSetCode 相关 |
| `--disable-nls` | gettext |

最终收敛到：X11/xcb 栈 + pango/harfbuzz/freetype/fontconfig 字体栈 + glib/gio + 压缩编码族（z/bz2/lzma/brotli/png/expat/xml2/pcre/graphite2/fribidi/ffi）。这就是 915K 静态二进制的构成。

### 6. 两个 patch 的作用

1. **`disable-x-locale.patch`** — `#if 0` 掉 `XSupportsLocale()` / `XSetLocaleModifiers("")`（openbox.c）和 `xim_init()`（obt/keyboard.c）。因为 `--disable-nls` 后没有 locale 数据，这两处会在缺 locale 环境下报 `g_message` 并破坏键盘初始化，对无 XIM 的容器场景必须关掉。
2. **`menu-file-order.patch`** — 把 `obt_xml_load_config_file()` 和 `obt_xml_load_file()` 的调用顺序对调，让菜单文件**先按字面路径加载，再回退 XDG 路径**。这对 `--prefix=/usr/local/static/openbox` 的自包含部署是必需的（否则 `~/.config/openbox/menu.xml` 相对路径失效）。

另：`config.sub` 被整体替换 —— openbox 3.6.1 自带版本过老，不识别新 target triple。

### 7. 下游裁剪（`rootfs/src/static/clear/`）

`clear.sh` 用**两份删除清单**，注意 `file-openbox.txt` 语义是**反向的**——未注释行 = 删除：

- 删目录（`usr-local-static-dir.txt:66-74`）：`include/`、`lib/`（含 libobt.a/libobrender.a/.la/.pc）、`share/doc`、`share/gnome*`
- 删文件（`file-openbox.txt` 未注释）：`gdm-control`、`gnome-panel-control`、全部头文件、`lib/*.a/.la/.pc`
- **保留**（注释行）：`bin/openbox`、`bin/obxprop`、`bin/openbox-session`、`etc/xdg/openbox/{rc,menu,autostart,environment}`、`share/themes/**`、`share/xsessions/*`
- 之后 `upx -7` 压缩所有 bin/sbin，软链到 `/rootfs/usr/bin`；并把每个主题 `ln -s` 到 `/usr/share/themes/<name>/openbox-3`（`clear.sh:48-56`），所以 themes 必须保留。

### 8. 发现的问题与风险

#### 8.1 `fontconfig_drop1()` 是死代码

`build.sh:214-249`：`case` 分支里 `full`/`b_deps`/默认分支**都没有调用它**；`b_deps` 实际走的是 `apk add fontconfig-dev fontconfig-static`（`build.sh:384`），用的是 Alpine 原生字体路径，那段精心设计的 `--with-default-fonts=$INS_PREFIX/share/fonts`、`--with-cache-dir=/config/xdg/cache/fontconfig` 自包含路径重映射**完全没生效**。真正启用该逻辑的是 fluxbox 阶段（Dockerfile:121-123，用 `_ex/fontconfig/build.sh` 且只拷 `libfontconfig.a` 进 `/usr/lib`）。openbox 与 fluxbox 在此不一致，是最值得确认的一处。

#### 8.2 `full` 分支不可用

`build.sh:376-381`：`libxrandr; pango; openbox` 却**不装依赖** → 直接报 `configure: error: C compiler cannot create executables`。脚本尾部注释（408-413）已记录了这一现象。

#### 8.3 入口损坏

`bash build.sh fontconfig` 会失败——函数名是 `fontconfig_drop1`，不是 `fontconfig`（`build.sh:385` 注释显示曾这样调用）。

#### 8.4 `oneBuild` 的错误检测失效

`common.sh:55-63`

```sh
set +e
$1 |tee $logfile
find $TARGETPATH -type f |sort
test "0" != "$?" && tail -200 $logfile || echo "err 0, pass"
```

`$?` 取的是上一行 `find` 的状态，**不是构建的状态**，所以构建失败不会触发 tail。而且 `set +e` 让 `$1` 的失败根本不会中断，`oneBuild` 必定正常返回。

由此两条更糟的推论（2026-09-26 落仓 librsvg 时实测到）：

1. **`xx-verify` 只覆盖 `openbox()` 一个函数**——`build.sh:325` 末尾的 `xx-verify --static` 在 `openbox()` 函数体里。`bash build.sh b_deps` 走 `case` 的 `*)` 分支 → `oneBuild b_deps`，**deps 阶段完全没有质量门**。实测：librsvg 的 `.la` 被误删导致安装产物不对，`b_deps` 照样打印 `err 0, pass`。
2. **`case` 结尾没有 `exit`**，脚本退出码是最后一条 `find ... | sort` 的 0，所以 `b_deps && openbox` 的 `&&` 一定放行、后续步骤照跑——直到 openbox 链接阶段才炸出 `pango_cairo_*` undefined。

结论：判成功只能自己 `xx-verify --static` + `grep -c "undefined reference\|attempted static link"` 兜底，别信 `oneBuild` 的 `pass`，也别把 `&&` 当流程控制用。

#### 8.5 验证覆盖不全

`build.sh:316-322`：只 verify 了 `bin/openbox`；`obxprop`、`openbox-session` 的 `xx-verify --static` 和 `upx` 都被注释掉。若某个次级二进制偷偷变成动态链接，流水线不会失败。

#### 8.6 `-luuid` 无显式来源

`build.sh:286` 追加 `-luuid`（对应 tail 注释 `fontconfig-static: << -luuid`），但 `apkdeps` 里**没有任何包显式提供 `libuuid.a`**，靠的是 `fontconfig-static` 的传递依赖。依赖链一调整就会在这里断。

#### 8.7 `--build`/`--host` 被折叠

`--build=$(TARGETPLATFORM= xx-clang --print-target-triple)` 清空 `TARGETPLATFORM` 后取 triple，使 `--build == --host`。这对 wrapper-toolchain 方案是**有意的**（不跨编，只换 target），副作用是 autoconf 完全不做 host 探测；Dockerfile:150 也删掉了 `ARG TARGETPLATFORM`。多架构下 `--build` 不再反映真实构建机架构，属于可接受的取舍但要知晓。

#### 8.8 libxrandr 的 `make` 未清 LDFLAGS

`configure` 时 `LDFLAGS=`（152 行），但 `make`（162 行）继承了全局 `-Wl,--as-needed --static -static -Wl,--strip-all`。对 `--disable-shared` 的静态库影响很小，但与 fontconfig 显式 `make LDFLAGS="$flags"` 的写法不一致。

#### 8.9 增量构建的脆弱性（较隐蔽）

`buildx.sh` 默认传 `--build-arg COMPILE_OPENBOX=no`，此时 stage 的 RUN 在 `cache` 后 `exit 0`。而 `COPY --from=openbox ${STATIC}` 仍会执行，只是拷进一个空目录。openbox 之所以没消失，是因为 Dockerfile:308-313 用**上一个版本的 compile 镜像自身**当 `ff` stage：

```dockerfile
FROM ${REPO}infrastlabs/x11-base:${COMPILE_IMG} AS ff
FROM .../library--alpine---3.13.12
COPY --from=ff /rootfs /rootfs
```

即最终镜像 = 上次镜像的 /rootfs + 本次重跑的 stage。**如果 `COMPILE_IMG` 换新 tag（如 `-dbg` 变体）而其 /rootfs 里没有 openbox，增量构建就会静默丢失整个 openbox**，且不会报错。

#### 8.10 版本错配风险

pango 1.49.3 是自编译，但它的 glib/harfbuzz/cairo 来自 Alpine 仓库 static 包。三者 ABI/API 漂移（Alpine 大版本升级）会在此断裂，且没有版本锁。

#### 8.11 产物冗余

`--enable-static` 导致 `libobt.a`、`libobrender.a`、头文件、`.pc` 全部 install（~250K），随后被 clear.sh 又删掉。openbox 没有跳过安装 lib 的开关，但至少不应把清理依赖放到下游清单里。

#### 8.12 调试噪音

`env |egrep`、`grep1=$(echo $OB_LIBS |sed "s^ -l^|lib^g" |sed "s^-lX11^libX11^g")`（`^` 当分隔符，产出无意义正则）、`find /usr/lib |egrep "$grep1"`、`make V=1` —— 都在正式流程里跑，纯属噪音。`--disable-nls` 下 OB_LIBS 里的 `-lintl` 是残留项。

### 9. 优化建议（按性价比排序）

1. **补验证**：把 `xx-verify --static` 扩展到 `obxprop` 和 `openbox-session`，并加一次 `./openbox --help` 冒烟（目前 Dockerfile 里没有，只存在于手工记录）。
2. **修入口**：`case` 加 `fontconfig) fontconfig_drop1;;`，或删掉 `fontconfig_drop1`；`full` 里补 `apkdeps`。
3. **决定 fontconfig 归属**：要么 openbox 也走 `_ex/fontconfig` 自包含路径（与 fluxbox 对齐），要么把 `fontconfig_drop1` 删掉并注明"用 Alpine 原生 fontconfig"。
4. **加固 8.9**：Dockerfile 里对 `COPY --from=openbox` 加一句存在性断言，如 `test -x /rootfs${STATIC}/openbox/bin/openbox`。
5. **锁版本**：在 `vers.txt` 之外，把 Alpine 的 glib/harfbuzz/cairo 版本一并记录（目前只锁了 pango 1.49.3 / libXrandr 1.5.3 / openbox 3.6.1）。

### 10. 分析说明

以上为基于源码与文档的静态分析，无 `alpine-builder-gtk224` 镜像与 `xx-clang/xx-verify/abuild-meson` 等外部工具链，未实际执行构建；体积数字（915K / 2.0M）取自 `docs/t2-x11-use.md` 的历史记录。

## 二、调试与环境

### 1. 调试方式

#### 1.1 编译调试入口

`README.md:81-98`（CompileDbg 段）+ `openbox/build.sh:398-407`（尾部 debug 段）两处口径一致：

```bash
# --privileged 必需：否则 apk update 挂在 fetch APKINDEX 一行
docker run -it --rm -v /mnt:/mnt2 --privileged \
  ${REPO}infrastlabs/x11-base:alpine-builder-gtk224 sh
# REPO=registry.cn-shenzhen.aliyuncs.com/ | ccr.ccs.tencentyun.com/ | dockerhub.qingcloud.com/ | registry-1.docker.io/

export GITHUB=https://hub.yzuu.cf          # 或 hub.njuu.cf / hub.nuaa.cf / hub.yzuu.cf
cd /mnt2/docker-x11base/compile/src/
rm -rf /src; ln -s $(pwd) /src             # build.sh 里是 source /src/common.sh
git pull; bash openbox/build.sh b_deps     # 装依赖（含 apk add fontconfig-dev fontconfig-static）
export TARGETPATH=/usr/local/static/openbox
bash openbox/build.sh openbox
```

`alpine-builder-gtk224` 已预装 `openbox/build.sh apkdeps` + `pango` + `libxrandr` + `Xdamage`（由 `u-gtk/build.sh b_deps` 在烘焙镜像时跑），所以重跑组件时依赖是热的。

#### 1.2 单组件增量重编

- **容器级**：`bash <组件>/build.sh <方法名>`，方法名对应脚本内函数（`openbox` / `pango` / `libxrandr` / `fontconfig_drop1`）。
- **Dockerfile 级**：`--build-arg COMPILE_OPENBOX=yes`（`buildx.sh` 默认全 `no`，即只重跑指定 stage）。
- **日志开关**：`CONSOLE_LOG=yes` 才 `tee` 到控制台，否则只写 `$TARGETPATH/../.logs/oneBuild-$1.log`；`CONSOLE_LOG=no` 时构建失败**不会在控制台留任何痕迹**。

#### 1.3 静态校验三件套

```bash
xx-verify --static /tmp/openbox/openbox/openbox
echo $?                          # 0 = 通过
upx -7 <bin>                     # 下游 clear.sh 统一做 -7
find /usr/lib |egrep "libpango|Xrandr|libfontconfig" |grep "\.a$" |sort   # 静态就绪度自查
```

不要用 `find / -name '*.a'` 探测静态库——容器里会遍历绑定挂载的宿主机整盘，直接超时。

#### 1.4 运行期调试（openbox）

`docs/t1-obox-dbg.md` 的实测结论：

- **必须带 rc**：`./bin/openbox --config-file ./etc/xdg/openbox/rc.xml`。裸跑报 `Unable to find a valid config file, using some simple defaults` / `Unable to load the theme 'Clearlooks'`。
- **fontconfig 不生效**的典型症状：一串 `Pango-CRITICAL pango_font_describe: assertion 'font != NULL'`。
- X server：`./Xvnc :21` 或 `Xvfb :99 -screen 0 1280x800x24`。

#### 1.5 失效检测盲区

`common.sh:55-63` 的 `oneBuild` 里 `test "0" != "$?"` 判的是上一行 `find` 的退出码，**不是构建的**；`CONSOLE_LOG=no` 下失败只在日志文件里。所以「构建成功」这个判断必须自己用 `xx-verify --static` 或 `ls -lh` 产物兜底，别信 `oneBuild` 的输出。**注意这个盲区比表面更大**：`openbox()` 末尾的 `xx-verify` 只护住程序编译那一步，`b_deps` 走的 `*)` 分支连质量门都没有（见 8.4）。

#### 1.6 文档索引

| 想找什么 | 去哪 |
|---|---|
| 编译 / 运行总入口 | `README.md` Run / CompileDbg 两段 |
| openbox 依赖清单与 ldd 基线 | `docs/wm/openbox.md` |
| openbox 运行调试实录 | `docs/t1-obox-dbg.md` |
| 产物清单 / 目录体积 | `docs/t2-x11-use.md` |
| arm 验证 | `docs/t3-armv7.md` |
| rootfs 组装 | `docs/t4-rootfs.md` |
| 字体 | `docs/t6-fonts.md` |
| 组件进度总表 | `Validate.md`、`TODO.md` |
| 各组件静态调试实录 | `docs/core/pulse06-static-dbg.md`、`docs/wm/*`、`docs/desk/*` |

### 2. docker 环境使用

#### 2.1 两套环境

| | x11base 编译（`README.md`） | builder-awe（长期） |
|---|---|---|
| 镜像 | `alpine-builder-gtk224` / `builder` | 同 `alpine-builder-gtk224` |
| 挂载 | `-v /mnt:/mnt2` + `ln -s $(pwd) /src` | **只挂一个** `-v /_ext:/_ext`，容器内路径与宿主一致 |
| 生命周期 | `--rm`，临时进去改 | 长期命名容器，**不 `--rm`、不 commit、不 push** |
| 进入方式 | `docker run -it ... sh` | `docker exec builder-awe sh ...` |
| 适用 | 重跑 `build.sh` 组件 | 长实验、脚本反复跑 |

镜像实测：Alpine **3.15.10** / glib **2.70.5** / cairo **1.16.0** / pangocairo **1.48.10** / lua5.3 **5.3.6**。
注意 pkg-config 报的 pango 版本 ≠ `.a` 构建时间：`/usr/lib/pkgconfig/pango*.pc` 是 2021-09-12（apk 原版），`/usr/lib/libpango-1.0.a` 是 2023-12-23 重建 —— **`pkg-config --modversion` 不可信，判版本要看 `.a` 的 mtime**。

#### 2.2 启动与必备 flags

```bash
docker run -d --name builder-awe --network=host --privileged \
  -v /_ext:/_ext \
  registry.cn-shenzhen.aliyuncs.com/infrastlabs/x11-base:alpine-builder-gtk224 \
  bash -c 'while :; do sleep 3600; done'
```

- maki 自己跑在容器内，通过 `DOCKER_HOST=tcp://127.0.0.1:2375` 连内嵌 dind。
- **`--privileged` 必需**：缺则 `apk update` 卡在 `fetch .../APKINDEX.tar.gz` 一行，无错无后续；`apk search` 返回空会被误判成"包不存在"。
- **`--network=host` 必需**：缺则 bridge egress 死（`ping 10.18.0.1` 无回应）。
- 反例陷阱：`apk update --quiet` 在 apk-tools 2.12.7 下会挂死 → **别加 `--quiet`**。
- 出口间歇限流：容器内 curl 可能掉到 ~1KB/s（宿主 1.1MB/s），TCP/ping/HTTP 200 都正常，纯吞吐被掐，**可自愈**，等一阵重试。github.com 被封 → 走 `gitee.com/g-system/`。
- 重建容器（改挂载/网络）会清空容器 fs，已装的包要重跑 setup。

#### 2.3 传脚本 / 取结果

stdin 会截断、stdout 会丢，唯一稳的模板：

```bash
B64=$(base64 -w0 /path/exp.sh)
docker exec builder-awe sh -c "echo $B64 | base64 -d > /tmp/s.sh; \
  rm -f /tmp/res.out; nohup sh /tmp/s.sh > /tmp/res.out 2>&1 & echo STARTED"
sleep 40
docker cp builder-awe:/tmp/res.out /tmp/host_res.out
cat /tmp/host_res.out
```

- `docker exec -i <c> sh -s < script.sh` —— 脚本体量大时 **stdin 被提前截断**，只跑完前几行且难以察觉。
- `docker exec ... | tail` 或 `> hostfile` —— 常拿到 0 字节 / 截断内容 → 让容器内脚本**自己重定向**，再 `docker cp`。
- 长 `docker exec sh -c '...'` 会**静默 no-op**（exit 0、无输出、无文件）→ 一律写成脚本文件。
- 脚本里 `cmd &` 会继承 exec 的输出 FD → exec 永不返回；用 `nohup ... </dev/null >/dev/null 2>&1 &` 或 `docker exec -d`。
- `sleep` 时长 = case 数 × 单次时长 + 余量。

#### 2.4 容器内 X11 冒烟

```bash
rm -f /tmp/.X11-unix/X99                        # 残留 socket 会让就绪检测假通过
Xvfb :99 -screen 0 1280x800x24 >/dev/null 2>&1 &
sleep 2
DISPLAY=:99 timeout -s KILL 8 "$PREFIX/bin/awesome"   # rc 0|124|137|143 = PASS
```

- BusyBox `timeout` **没有 `-k`**，只有 `-s SIG`（默认 TERM）。
- BusyBox `pgrep` **不支持 `-c`**（`pgrep: unrecognized option: c`）。
- **无 `dbus-daemon`、无 `/etc/machine-id`、无 `dbus-send`** → `a_dbus_connect` 失败、`awesome-client` 不可用、通知静默降级。项目是**故意不配 D-Bus**，不要试图起 session bus。
- 截图基线判据：空 Xvfb `279B / 1 色 / 100% 黑`；只出 wibar `~16KB / ~185 色 / 97.4% 黑`；修好 `~80-110KB / 数千色`。**PNG 字节数本身就是粗判据**。
- 跑 spec/smoke 时设 `LUA_PATH="$REPO/lib/?.lua;$REPO/lib/?/init.lua"`。

#### 2.5 工具差异（别猜，先查）

实测于 `builder-awe`（2026-09-26）：

| 环境 | 有 | 没有 |
|---|---|---|
| builder-awe | `Xvfb` `/usr/bin/Xvfb`、`import`、`convert`、`gcc/g++`(10.3.1)、`cmake`(3.21.7)、`ninja`、`meson`、`pkg-config`、`lua`(=/usr/local/bin/lua)、`lua5.3`、`busted-5.3`、`git`、`perl`、`python3`、`awk`、`timeout`、`pgrep` | **`xprop`、`xdpyinfo`、`Xvnc`、`scrot`、`pngtopnm`、`xsetroot`、`busted`** |
| host (Ubuntu 22.04.5) | `Xvfb`、`xprop`、`xdpyinfo`、`scrot`、`xsetroot`、TigerVNC 1.13.1(`:10`) | `convert`、`import`、`xwd`；无 PIL |
| subagent sandbox | — | `Xvfb`/`xvfb-run`、`file`、`pkg-config`、lua 头、PIL、`import`、`convert`、`xwd` |

→ **截图必须容器内 `import`，`xprop` 必须回宿主**。跨环境别把对方有的工具写进脚本。

#### 2.6 其他坑

- `/tmp` 是容器本地，**只有 `/_ext` 共享**；`/_ext/tmp` 里宿主刚写的文件，容器可能只看到前几行甚至 `No such file or directory` → 每次进容器先 `ls -la`。
- 诊断脚本忘了 `docker exec` 就跑在**宿主机**上，全是假 MISS → 容器侧脚本自检 `test -f /etc/alpine-release`，宿主侧脚本自检 `command -v docker`。
- 判别 shell：GNU `ls: cannot access 'X': No such file`，busybox `ls: X: No such file`。
- 别覆盖 `PKG_CONFIG_PATH=/usr/lib/pkgconfig`：会屏蔽 `/usr/local/{lib,share}/pkgconfig`，源码产物（xcb-util、libxdg-basedir）的 pc 全部查不到。
- `pkg-config --static --exists` **不检查 `.a` 是否存在**（只解析 Requires.private），判静态可行性必须直接 `ls *.a`。
- `pkill -9 -f "Xvfb :99"` 在 `sh -c` 里会匹配到自己命令行 → 容器 137 死。
- 容器内产物是 `root:root 444`，宿主编辑 `Permission denied` → 收尾要 `chown`。
- `docker stop builder-awe` 会释放可写层（观测到 +15GB 磁盘占用）；**0 字节文件 = 磁盘满**。
- subagent sandbox 内跑 `docker exec ... timeout -s KILL` 会吞掉被 kill 子进程的 stdout。

## 三、实测记录

本章两节均为 2026-09-26 在 `builder-obox` 容器内的实测结论，非静态阅读推演。

### 1. 容器环境搭建到跑通 `build.sh`

#### 1.1 概要

| 步骤 | 命令 | 说明 |
|---|---|---|
| 1. 起容器 | `docker run -d --name builder-obox --network=host --privileged -v /_ext:/_ext <alpine-builder-gtk224> sleep infinity` | 长跑容器，反复 `docker exec`；两个 flag 都必需，见 2.2 |
| 2. 换 apk 源 | 默认 ustc 源卡死 `apk update` → 改 `mirrors.tencent.com` | 网络可通 |
| 3. 建软链 | `ln -s /_ext/home/headless/xm-zs01/docker-x11base/compile/src /src` | 绕开容器内 `cd /_ext` 报 ENOENT |
| 4. 预热 cache | `/usr/local/static/.cache/` 放入 `openbox-3.6.1.tar.xz`(643K)、`pango-1.49.3.tar.xz`(2.5M) | 跳过下载 |
| 5. 建安装目录 | `mkdir -p /usr/local/static/openbox` | 等价于 `Dockerfile:154 mkdir -p $TARGETPATH`，不可省 |
| 6. 构建 | `docker exec builder-obox bash /src/openbox/build.sh openbox` | **32 秒成功** |
| 7. 验证 | `xx-verify --static` + `file` + `ldd` | openbox 6.3M / obxprop 1.8M，均 `statically linked`、`stripped`；`ldd` 报 `Not a valid dynamic program` |

产物落到 `/usr/local/static/openbox/bin/{openbox,obxprop}`，对应 `build.sh:314` 的 `make DESTDIR=/ install` 与 `build.sh:322` 的 `xx-verify`。

#### 1.2 避坑项

- **`bash build.sh cache` 从写下起就没成功过（rc=1）**：`build.sh:372` 写的是 `${LIBXRAND_URL}`（少一个 `R`，变量为空）→ 空 url 传入 `down_catfile` → BusyBox `test -s <目录>` 返回 0（GNU 语义下应为 1）→ `cat <目录>` 报 `EISDIR` → 头部 `set -e` 中止。Dockerfile 里该 RUN 用 `;` 串联且**不带 `-e`**，失败被静默吞掉，构建照样继续。**别指望 cache 阶段预热下载**。
- **`bash build.sh full` 同样不可用**：它把 `openbox()` 里的 `down_catfile` 当顺序调用，中间夹 `apkdeps`，依赖顺序与 `oneBuild` 包装都对不上。真正可用的是 `bash build.sh openbox`（`case` 的 `*)` 分支 → `oneBuild` → `function openbox`）。
- **`cd /_ext/...` 在容器内报 ENOENT，但 `ls` / `namei` 正常**：必须走 `/src` 软链，脚本里别写绝对 `/_ext` 路径。
- **`mkdir -p $TARGETPATH` 不是可选项**：`down_catfile` 里 `CACHE=$TARGETPATH/../.cache`，目录不存在时 `..` 会被当字面量建出一个名为 `..` 的目录。
- **`apk update --quiet` 在 apk-tools 2.12.7 下会挂死**：不要加 `--quiet`，卡住就换源。
- **`pkg-config --modversion` 不可信**：本机 pc 报 `1.48.10`，实际 `.a` 是 `1.49.3`（自编译 pango 未覆盖 `PKG_CONFIG_PATH`）。判版本看 `.a` 时间戳 / 源码目录，别信 pc。
- **`pkg-config --static --exists` 也不检查 `.a` 是否存在**：只解析 `Requires.private`，判静态可行性必须直接 `ls *.a`。
- **`xx-verify --static` 成功时静默无输出**：必须接 `echo $?` 或 `&& echo OK`，否则分不清"通过"还是"没跑"。
- **`xx-verify` 只校验了 openbox**：`build.sh:322` 只传 `$ROOT_DEST_DIR${INS_PREFIX}/bin/openbox`，`obxprop` 未校验（`build.sh:316-320` 的校验段被注释）。
- **两个 patch 必须按序打且必须换 `config.sub`**：`disable-x-locale.patch` → `menu-file-order.patch`（`build.sh:263-264`）；`config.sub`（`build.sh:268`）——openbox 自带的太老，不认识 `x86_64-alpine-linux-musl`，不换则 `configure: error: cannot find host system type`。
- **`make V=1` 后 `ldd` 仍可能报动态**：`build.sh:307` 注释掉的尝试证实过；静态必须靠 `xx-clang-wrapper` + `-Wl,--start-group ... --end-group` 那套（`build.sh:288`）。

### 2. 源码级配置项明细

以下全部来自 `openbox-3.6.1` 的 `configure.ac` + `m4/*.m4`，**不受 `openbox/build.sh` 指定的参数影响**（build.sh 的对照见 2.4）。

#### 2.1 声明分布（只看 `configure.ac` 会漏 12 个）

| 位置 | 数量 | 开关 |
|---|---|---|
| `configure.ac` 128/153/178/208 | 4 | startup-notification、xcursor、imlib2、librsvg |
| `m4/x11.m4` 41/105/170/233/292/406 | 6 | xkb、xrandr、xshape、xinerama、xsync、session-management |
| `m4/openbox.m4` `OB_DEBUG` 10/14/18/22/26（由 `configure.ac:86` 调用） | 5 | strict-ansi、super-warnings、debug、gprof、gprof-libc |
| `m4/nls.m4:26`（`configure.ac:100 AM_GNU_GETTEXT([external])` 带入） | 1 | nls |

#### 2.2 功能特性开关（10 个，全部 `[default=enabled]`）

默认全开，不传参数即启用（探测失败才静默降级）；要关必须显式 `--disable-*`。

「作用」定位到源码 `#ifdef` 分支；「库依赖」为 configure 实际探测方式；「当前环境」为 `builder-obox` 实测（HAS=可静态链接 / MISS=缺件）；「x11base」为仓内其他组件构建脚本的引用（不含 `openbox/` 本身）。

| 开关 / `./configure` 参数 | 源码位置 / AC_DEFINE | 作用（源码定位） | 库依赖（探测方式） | 当前环境 `builder-obox` | x11base 其他组件 |
|---|---|---|---|---|---|
| **startup-notification**<br>`--disable-startup-notification`<br>`--enable-startup-notification` | `configure.ac:128` → `USE_LIBSN` | XDG 启动通知：WM 经 `_NET_STARTUP_ID` 与 launcher 通信，标记"应用已启动"、识别假启动；关时 `openbox/startupnotify.c:31-41` 整组 `sn_*` 退化为空实现 | `PKG_CHECK_MODULES(LIBSN, libstartup-notification-1.0 >= 0.8)` | pc **MISS** / `libstartup-notify.a` **MISS** / apk 仓库无 static 包 → **无法静态链接** | `v-tint2/build.sh:188` `apk add startup-notification-dev`（仅动态，无 static 变体） |
| **xcursor**<br>`--disable-xcursor`<br>`--enable-xcursor` | `configure.ac:153` → `USE_XCURSOR` | 用 libXcursor 解析主题/系统光标并渲染鼠标指针（`openbox/openbox.c:81`、`:725`） | `PKG_CHECK_MODULES(XCURSOR, xcursor)` | pc **MISS** / `libXcursor.a` **MISS** / `X11/extensions/cursor.h` **MISS**（`libxcursor` 运行库在、dev 未装）→ **无法静态链接** | `suckless/build.sh:84,140` `-lXcursor`、`:195` `apk add libxcursor-dev`；`v-tint2/build.sh:189`、`:247` `Imlib2 Xcursor Xi` |
| **imlib2**<br>`--disable-imlib2`<br>`--enable-imlib2` | `configure.ac:178` → `USE_IMLIB2` | 位图图标加载（png/jpg/gif），`obrender/image.c:24,471-510`；与 librsvg 二选一决定图标路径（`openbox/config.c:954`） | `PKG_CHECK_MODULES(IMLIB2, imlib2)` | pc **MISS** / `libimlib.a` **MISS** → **自动降级 off**（build.sh 未传 disable） | **有完整源码编译路径**：`v-xlunch/build.sh:23-42` `imlib2()` 函数、`:94` case 项；`Dockerfile:229` `sh /src/v-xlunch/build.sh imlib2`；`fluxbox/build.sh:33` `--disable-imlib2` 对照 `fluxbox/build.sh.xft.sh:69` `--enable-imlib2` |
| **librsvg**<br>`--disable-librsvg`<br>`--enable-librsvg` | `configure.ac:208` → `USE_LIBRSVG` | SVG 图标加载，`obrender/image.c:27,512-612` | `PKG_CHECK_MODULES(LIBRSVG, librsvg-2.0)` | pc **MISS** / `librsvg.a` **MISS** → **无法静态链接** | **有源码编译路径**：`v-tint2/build.sh:63-80` `librsvg()`（gitee `fk-librsvg`）、`:187` `apk add pango-dev librsvg-dev` |
| **session-management**<br>`--disable-session-management`<br>`--enable-session-management` | `m4/x11.m4:406` → `USE_SM` | X11 SM 会话恢复：处理 `SmcSaveYourself` 以保存/恢复窗口布局（`openbox/event.c:61,120,153,164`） | `AC_CHECK_LIB(SM, SmcSaveYourselfDone)` + `AC_CHECK_HEADERS(X11/SM/SMlib.h)` → 产出 `-lSM -lICE` | `SMlib.h` HAS / `sm.pc` HAS / **`libSM.a` HAS** / **`libICE.a` MISS**（`libice-dev` 不含 `.a`，仅 `libICE.so.6.3.0`）→ **半残，静态链不了** | **全仓无引用**（`libSM` / `-lICE` / `session-management` grep 为空） |
| **xkb**<br>`--disable-xkb`<br>`--enable-xkb` | `m4/x11.m4:41` → `XKB` | XKB 键盘布局 / 键盘热键扩展，`openbox/event.c:202`；`obt/display.c:74-82` 缺失时 `g_message("XKB extension is not present...")` | `AC_CHECK_LIB(X11, XkbBell)` —— **只需 libX11，无额外库** | `X11/extensions/XKBstr.h` HAS / `libX11.a` HAS → **可静态链接** | 无组件显式引用 `Xkb`；`-lX11` 是所有组件 `OB_LIBS` 首项（如 `v-geany/build.sh:18`） |
| **xrandr**<br>`--disable-xrandr`<br>`--enable-xrandr` | `m4/x11.m4:105` → `XRANDR` | Xrandr 屏幕旋转 / 分辨率 / 多屏热重配，`openbox/event.c:806`、`obt/display.c:102` | `AC_CHECK_LIB(Xrandr, XRRSelectInput)` → `-lXext -lXrender -lXrandr` | `Xrandr.h` HAS / `xrandr.pc` HAS / `libXrandr.a` + `libXext.a` + `libXrender.a` 全 HAS → **可静态链接**；`build.sh:152-158` 另自编译了 libXrandr 1.5.3 | **引用最广**：`suckless/build.sh:6-7` `xrandr` 变量、`:84,140`；`v-geany:26`、`v-lxde:40,69`、`v-pcmanfm:182`、`v-feh:25`、`x-x11vnc:88,92`、`x-xrdp:96`、`u-gtk` |
| **xshape**<br>`--disable-xshape`<br>`--enable-xshape` | `m4/x11.m4:170` → **`SHAPE`** | XShape 窗口异形 / 圆角，`openbox/client.c:1385`、`event.c:1721`、`frame.c:274,329`、`obt/display.c:85` | `AC_CHECK_LIB(Xext, XShapeCombineShape)` + `AC_TRY_LINK(long foo = ShapeSet)` → `-lXext` | `shape.h` HAS / `libXext.a` HAS → **可静态链接** | 无组件显式引用 `XShape`；`-lXext` 是通用项 |
| **xinerama**<br>`--disable-xinerama`<br>`--enable-xinerama` | `m4/x11.m4:233` → `XINERAMA` | Xinerama 多显示器布局合并，`openbox/screen.c:1364,1377`、`obt/display.c:93` | `AC_CHECK_LIB(Xinerama, XineramaQueryExtension)` → `-lXext` | `Xinerama.h` HAS / `xinerama.pc` HAS / `libXinerama.a` + `libXext.a` 全 HAS → **可静态链接** | **引用广泛**：`suckless:84,140`、`v-geany:26`、`v-lxde:40,69`、`v-pcmanfm:182`、`v-feh:25`、`x-x11vnc:88,92`、`fluxbox/build.sh.xft.sh` |
| **xsync**<br>`--disable-xsync`<br>`--enable-xsync` | `m4/x11.m4:292` → **`SYNC`** | XSync 交换同步：resize 期间抑制多余 `ConfigureNotify`，`openbox/client.c:1258,1655,1667`、`event.c:215,254,691,1704`、`moveresize.c:49` | `AC_CHECK_LIB(Xext, XSyncInitialize)` + `AC_TRY_LINK(XSyncValueType foo)` → `-lXext` | `sync.h` HAS / `libXext.a` HAS → **可静态链接** | 无组件显式引用 `XSync` |

首列里 `--enable-X` 与 `--disable-X` 是**同一开关的两种等价写法，两者都被接受**：autoconf 把二者映射到同一个 `enable_X` shell 变量（生成的 `configure:15903-15905` 只有一个 `Check whether --enable-xkb was given` 块，读 `enableval`），实测传 `--disable-xkb` 后 `Makefile` 的 `DEFS` 里 `-DXKB` 消失。因默认全开，**真正有意义的是 `--disable-X`**——实测构建用的就是它。

**实测判定（`Makefile:436` `DEFS` 原文，非推演）**：

```
DEFS = ... -DHAVE_LIBX11=1 -DXRANDR=1 -DSHAPE=1 -DSYNC=1 -DAUTH=1
```

- **on**：`xrandr`（`XRANDR_LIBS = -lXext -lXrender -lXrandr`）、`xshape`（`XSHAPE_LIBS = -lXext`）、`xsync`（`XSYNC_LIBS = -lXext`）、`Xauth`（`XAUTH_LIBS = -lXau`），见 `Makefile:541-558`。
- **off**：`xkb`、`xinerama`（DEFS 无 `-DXKB` / `-DXINERAMA`，`XKB_LIBS = ` / `XINERAMA_LIBS = ` 空）；`startup-notification`、`xcursor`、`imlib2`、`librsvg`、`session-management`（DEFS 无 `USE_LIBSN` / `USE_XCURSOR` / `USE_IMLIB2` / `USE_LIBRSVG` / `USE_SM`，`SM_LIBS = ` 空）。

**三个容易搞错的地方**：

1. **宏名 ≠ 开关名**：`xshape` → `SHAPE`，`xsync` → `SYNC`（`m4/x11.m4:198`、`:320`），**不是** `XSHAPE` / `XSYNC`。直接 grep `XSHAPE` 会得出"该特性未被使用"的错误结论。
2. **没有 `config.h`**：openbox 3.6.1 的 `configure.ac` 不调用 `AC_CONFIG_HEADERS`，`AC_DEFINE` 的宏全部以 `-D` 形式进入 `Makefile` 的 `DEFS`（`Makefile:436`）随编译命令行下发。查产物实际配置要读 `Makefile`，找 `config.h` 会扑空。
3. **`X*_LIBS` 在静态构建里基本是摆设**：`obt_libobt_la_LIBADD`（`Makefile:731-739`）确实引用了 `$(XINERAMA_LIBS) $(XKB_LIBS) $(XRANDR_LIBS) $(XSHAPE_LIBS) $(XSYNC_LIBS)`，`openbox_openbox_LDADD`（`Makefile:778`）引用了 `$(XINERAMA_LIBS) $(XRANDR_LIBS) $(SM_LIBS) $(XCURSOR_LIBS) $(LIBSN_LIBS)`（注意此处**没有** `XSHAPE_LIBS` / `XSYNC_LIBS`）；但 `build.sh:288` 用 `LDFLAGS="$LDFLAGS -Wl,--start-group $OB_LIBS -Wl,--end-group" LIBS="$LDFLAGS"` 覆盖了整条链接闭包，`libXrandr` / `libXext` / `libXrender` 实际来自 `build.sh:278-281` 的 `OB_LIBS` 手写清单。→ **configure 的探测只决定 `#ifdef` 分支是否编进代码，不负责链接**。

   > **本条已被四.6.1 推翻**：全开实测证明 `XINERAMA_LIBS` 是 `-lXinerama` 的唯一来源，而 OB_LIBS 里没有 `-lXinerama`。准确说法见四.6.1。

#### 2.3 构建类型开关（5 个，全部 `[default=no]`）

`m4/openbox.m4` 的 `OB_DEBUG` 宏，方向与 2.2 **相反**（默认关，需 `--enable-*`）：

| 开关 | 源码位置 | 作用 |
|---|---|---|
| `--enable-strict-ansi` | `m4/openbox.m4:10` | 严格 ANSI 编译 |
| `--enable-super-warnings` | `m4/openbox.m4:14` | 额外编译告警 |
| `--enable-debug` | `m4/openbox.m4:18` | 调试版；`VERSION` 含 `alpha`/`beta` 时**强制置 yes** |
| `--enable-gprof` | `m4/openbox.m4:22` | gprof 插桩输出 |
| `--enable-gprof-libc` | `m4/openbox.m4:26` | 链接 profiling 版 libc；置 yes 时**连带强制 gprof=yes** |

NLS：`--disable-nls`（`m4/nls.m4:26`，default=yes，由 `configure.ac:100` 带入）。`m4/openbox.m4:112` 的 `OB_NLS` 宏定义了 `--enable-nls` 但**从未被调用**，是死代码——所以 `--help` 只有 `--disable-nls` 而没有 `--enable-nls`。

#### 2.4 与 `build.sh` 的对照（实测判定）

`build.sh:288-301` 只传 11 个参数，对照源码 10 个功能开关：

| 开关 | build.sh | 实测结果 |
|---|---|---|
| xcursor | `--disable-xcursor`（296） | off |
| librsvg | `--disable-librsvg`（297） | off |
| startup-notification | `--disable-startup-notification`（298） | off |
| session-management | `--disable-session-management`（299） | off |
| xkb | `--disable-xkb`（300） | off |
| xinerama | `--disable-xinerama`（301） | off |
| **xrandr** | **未传** | **on**（`checking for XRRSelectInput in -lXrandr`） |
| **xshape** | **未传** | **on**（`checking for XShapeCombineShape in -lXext`） |
| **xsync** | **未传** | **on**（`checking for XSyncInitialize in -lXext`） |
| imlib2 | 未传 | off（自动降级：镜像未装，`checking for IMLIB2... no`） |

实测 configure 命令行（config.log 原文）：

```
./configure --build=x86_64-alpine-linux-musl --host=x86_64-alpine-linux-musl \
  --prefix=/usr/local/static/openbox --datarootdir=/usr/local/static/openbox/share \
  --disable-shared --enable-static --disable-nls --disable-xcursor --disable-librsvg \
  --disable-startup-notification --disable-session-management --disable-xkb --disable-xinerama
```

→ 结论：**xrandr / xshape / xsync 实际是开启并链接进去的**，`build.sh:295-301` 的裁剪名单不完整；imlib2 属于"漏传 disable 但恰好被自动关掉"。

#### 2.5 `AC_ARG_WITH` / `AC_ARG_VAR` / 无开关项

- openbox 源码 `AC_ARG_WITH` 数量是 **0**。`m4/x11.m4:5` 的 `X11_DEVEL`（内含 `AC_PATH_XTRA` → `--with-x`）从未被 `configure.ac` 调用；`aclocal.m4:195/215` 的 `--with-pkgconfigdir` / `--with-noarch-pkgconfigdir` 来自 `PKG_INSTALLDIR` 宏，openbox 从未调用 → 全是死代码。`--with-x`、`--with-pic`、`--with-sysroot`、`--with-gnu-ld`、`--with-libiconv-prefix`、`--with-libintl-prefix`、`--with-aix-soname` 均为 autotools 自带（`configure:1574` / `15051`）。
- openbox 自有 `AC_ARG_VAR` 数量也是 **0**。只有 autotools 通用宏生成的两组：`PKG_CONFIG` / `PKG_CONFIG_PATH` / `PKG_CONFIG_LIBDIR`（`aclocal.m4:53-55`），以及 `<PKG>_CFLAGS` / `<PKG>_LIBS` / `<PKG>`（`aclocal.m4:130-131`、`230`）——可手工注入 `GLIB_*`、`PANGO_*`、`XML_*`、`X_CFLAGS`、`X_LIBS`、`X_PRE_LIBS` 覆盖 pkg-config 结果。
- **无开关、无法 `--disable`**：`X11_EXT_AUTH`（`m4/x11.m4:350`，`configure.ac:251` 调用）强制探测 `XauReadAuth` / `X11/Xauth.h`，Xau 属必需项，只能靠 `CFLAGS` / `LDFLAGS` 绕过。
- 校验方法：`./configure --help | grep -oE -- '--(enable|disable|with)-[a-z0-9-]+' | sort -u` → **37 项**（openbox 自有 16 + autotools 21），与上述源码定义一一对齐。

## 四、全开功能开关实测

### 1. 结论速览

改 `build.sh` 的 configure flag 就能让**首轮静态编译一次跑通（34 秒）**——但产物只有 3 个特性。补齐 10 个开关需要三段活：装 apk 包（xcursor/imlib2）、源码编译静态库（libcroco/librsvg）、补 `PKG_CHECK_MODULES` 拿不到的传递依赖。最终 **8 个开关开、2 个关**（`session-management`、`startup-notification` 都是按要求关），openbox **10.0M**，仍 100% 静态。

- **实际新增开启**：`xkb`、`xinerama` 两个
- **baseline 本来就开着**（`build.sh` 漏传 disable，见 2.4）：`xrandr`、`xshape`、`xsync`
- **静默降级 off**：`startup-notification`、`xcursor`、`imlib2`、`librsvg` —— 库不存在，configure 不报错、直接跳过对应 `#ifdef` 分支

> 最终进展：10 个开关全部打通。**8 个开**（`xkb`、`xinerama`、`xrandr`、`xshape`、`xsync`、`xcursor`、`imlib2`、`librsvg`），**2 个按要求关**（`session-management`、`startup-notification`）。见四.7（imlib2/xcursor）、四.8（librsvg 解法）。

→ **构建成功 ≠ 特性齐全**。首轮产物是 100% 静态可运行的，只是那 4 个功能的代码根本没编进去，所以也谈不上"缺依赖"——那段代码不需要任何链接。要真正区分"关掉了"和"没编进去"，只能看 DEFS / 业务符号（见四.3）。

### 2. 做法（容器内沙箱，不动仓库）

```bash
cp -a /src/openbox /tmp/obox-test
cd /tmp/obox-test
grep -v -e disable-xcursor -e disable-librsvg -e disable-startup-notification \
     -e disable-xkb -e disable-xinerama build.sh > build.sh.new
mv build.sh.new build.sh          # 420 → 415 行
TARGETPATH=/usr/local/static/openbox-all bash /tmp/obox-test/build.sh openbox
```

- `SCRIPT_DIR` 从脚本自身路径推导（`build.sh:6`），所以副本照样能找到 `disable-x-locale.patch` / `menu-file-order.patch` / `config.sub`。
- `TARGETPATH` 走 env 覆盖即可（`INS_PREFIX=$TARGETPATH` 在脚本头部求值），产物隔离到 `openbox-all`，baseline 的 `/usr/local/static/openbox` 未动。
- `pango_meson`（`build.sh:81`）只是把 `xx-clang-wrapper` 拷到 `/usr/bin` 并写 `/tmp/meson-cross.txt`，不重建 pango，很快。

### 3. 实测结果

`Makefile:436` DEFS 对比：

```
baseline:   -DHAVE_LIBX11=1 -DXRANDR=1 -DSHAPE=1 -DSYNC=1 -DAUTH=1
全  开  :   -DHAVE_LIBX11=1 -DXKB=1 -DXRANDR=1 -DSHAPE=1 -DXINERAMA=1 -DSYNC=1 -DAUTH=1
+补库后 :   -DUSE_XCURSOR=1 -DUSE_IMLIB2=1 -DXKB=1 -DXRANDR=1 -DSHAPE=1 -DXINERAMA=1 -DSYNC=1 -DAUTH=1
+rsvg   :   -DUSE_XCURSOR=1 -DUSE_IMLIB2=1 -DUSE_LIBRSVG=1 -DXKB=1 -DXRANDR=1 -DSHAPE=1 -DXINERAMA=1 -DSYNC=1 -DAUTH=1
```

| 开关 | 请求 | 首轮实际 | 证据 | 最新状态 |
|---|---|---|---|---|
| session-management | 关 | off | `--disable-session-management` | ✗ 关（用户指定，`libICE.a` 也没有，见四.2） |
| **xkb** | 开 | **on（新增）** | `-DXKB=1` | ✓ on |
| **xinerama** | 开 | **on（新增）** | `-DXINERAMA=1`；`XINERAMA_LIBS = -lXext -lXinerama` | ✓ on |
| xrandr / xshape / xsync | 开 | on（baseline 已 on） | 见 2.4 | ✓ on |
| xcursor | 开 | 降级 off | `X Cursor Library... no` | ✓ on——装 `libxcursor-dev-1.2.0`，出 `libXcursor.a` + `xcursor.pc`，见四.7 |
| imlib2 | 开 | 降级 off | `Imlib2 Library... no` | ✓ on——装 `imlib2-dev-1.7.4`，出 `libImlib2.a` + `imlib2.pc`，另需 OB_LIBS 补 `-lXfixes -lX11-xcb -lxcb-shm` 等传递依赖，见四.7 |
| **librsvg** | 开 | 降级 off | `SVG Support (librsvg)... no` | ✓ **on**——跨脚本调 `v-tint2/build.sh` 的 `libcroco()`/`librsvg()`（加 `STATIC=yes` 只出 `.a`），再补 `-lrsvg-2 -lcroco-0.6 -lgmodule-2.0 -lmount -lblkid -lpixman-1 -lpangocairo-1.0`，见四.8 |
| startup-notification | 开 | 降级 off | `Startup Notification... no` | ✗ **关**——Alpine main + community 无包，仓内无静态构建路径；已在 build.sh 显式 `--disable-startup-notification`（用户指定） |

> 最终 **8/10 开、2/10 关**（关的两个都是用户指定）。DEFS 见上表最后一行，`file` = statically linked, stripped，`ldd` = `Not a valid dynamic program`，`xx-verify --static` 对 openbox / obxprop 都 rc=0 并打印 `err 0, pass`。

产物：openbox **10.0M** / obxprop 1.8M（baseline 6.3M）。体积暴涨几乎全来自 librsvg 拖进来的 glib/gio/gobject/gdk-pixbuf/gmodule 闭包。

分支确实编进了代码——注意要 grep **实际业务符号**，不是探测符号：

```
openbox-openbox-screen.o:  U XineramaQueryScreens
openbox-openbox-event.o:   U XRRUpdateConfiguration
openbox-openbox-event.o:   U frame_adjust_shape_kind
openbox-openbox-event.o:   U obt_display_extension_shape / _sync / _xinerama
```

### 4. 静态库从哪来

**不是一份清单，是三层拼出来的。** 容器内 `/usr/lib` 有 117 个 `.a`，`/usr/local/lib` 只有 3 个。

| 来源 | 例子 | 判定方法 |
|---|---|---|
| **① Alpine `*-static` 包** | `libX11.a`(libx11-static-1.7.3.1)、`libpng.a`(libpng-static)、`bzip2-static`、`zlib-static`、`gettext-static`、`fribidi-static`、`graphite2-static`、`glib-static`、`fontconfig-static`、`cairo-static`、`harfbuzz-static`、`expat-static`、`brotli-static`、`pixman-static`、`nettle-static`、`libgcrypt-static`、`libgpg-error-static`、`libjpeg-turbo-static`、`libunistring-static` | `apk info --who <file>` 有归属 |
| **② Alpine `*-dev` 包自带 `.a`** | `libXext.a`(libxext-dev)、`libXrender.a`(libxrender-dev)、`libXinerama.a`(libxinerama-dev)、`libXau.a`、`libXdmcp.a`、`libSM.a`(libsm-dev)、`libxml2.a`、`libffi.a`、`liblzma.a`(xz-dev)、`libuuid.a`(util-linux-dev) | 同样有 apk 归属，但包名是 `-dev` |
| **③ 镜像构建期自编译** | `libXrandr.a` + `libXrandr.la`（**无 apk 归属**）、`libpango-1.0.a` / `libpangoft2-1.0.a` / `libpangoxft-1.0.a`、`libXdamage.a`、`libatk-1.0.a`、`libgdk_pixbuf-2.0.a` | `apk info --who` 报 `Could not find owner package`；**有 `.la` 是硬证据**（apk 不装 libtool 归档） |

回答"是不是镜像内现在就有的"：**主要是。** 绝大多数 `.a` 是构建基础镜像时 `apk add` 进去的（①②），少数是自编译产物（③）。当前会话没有新装过任何库。

**同一个生态里 `.a` 的归属完全不一致**，这是最该记的一点：

- `libx11-dev` **不带** `.a` → 必须另装 `libx11-static`
- `libxext-dev` / `libsm-dev` / `libxinerama-dev` / `libxrender-dev` **直接带** `.a`
- `libice-dev` 带 `.so` 却**不带** `.a` → 所以 session-management 半残（`-lSM` 有、`-lICE` 没有）

→ 判静态可行性只能 `ls *.a` + `apk info --who`，别信包名规律。

`libXrandr` 是混合体：`libXrandr.so.2.2.0`（2020-09-09，apk 1.5.2）+ `libXrandr.a` / `.la`（2023-12-23，自编译 1.5.3，`build.sh:144 libxrandr()`）**共存于 `/usr/lib`** —— 动态用 apk 的，静态用自编译的。

### 5. 4 个 pkg-config 特性为什么"开不起来"

不是编译失败，是**编译期就把那段代码删了**：`PKG_CHECK_MODULES` 找不到 `.pc` 文件 → 不 `AC_DEFINE` → 对应 `#ifdef` 分支不进编译单元 → 产物里没有那段代码，自然也不需要链接那库。

| 特性 | 容器内实况 | 想真开需要什么 |
|---|---|---|
| imlib2 | **一个文件都没有** | 仓内已有 `v-xlunch/build.sh:23-42 imlib2()`，`Dockerfile:229` 在 xlunch stage 已调过，但产物没进这个镜像 |
| librsvg | **一个文件都没有** | 仓内已有 `v-tint2/build.sh:63-80 librsvg()`（gitee `fk-librsvg`），同样未进这个镜像 |
| xcursor | 只有 `libXcursor.so.1.0.2`，**无 `.so` 软链、无 `.a`、无 dev 包**（`apk info` 里只有运行库 `libxcursor`） | 需源码编译，仓内无现成路径 |
| startup-notification | **一个文件都没有** | **仓内无任何静态构建路径，需新写** |

→ imlib2 / librsvg 只是"仓里有编译函数、这个镜像没跑过"；startup-notification / xcursor 是真正的空缺。

> 后续：`imlib2` / `xcursor` 其实**不需要源码编译**——Alpine `main` 仓库的 `imlib2-dev` / `libxcursor-dev` 直接带 `.a`，装上 + 补传递依赖即可，见四.7。`librsvg` 看起来最像硬阻塞（`librsvg-dev` 只有 `.so`、`libcroco` 无包），但仓内 `v-tint2/build.sh` 已有构建函数，两段都改成静态后跑通了，见四.8。真被卡死的只剩 `startup-notification`（Alpine 无包、仓内无路径），见四.8 末尾。

### 6. 本轮推翻 / 更正的旧结论

1. **~~"`X*_LIBS` 在静态构建里基本是摆设"~~ —— 错的。** 最终链接行里 `-lXinerama` 出现在 `--start-group` **之外**：

   ```
   ... -lXinerama -lxcb -lXdmcp -lXau -lXft /usr/lib/libXrandr.a -lXext -lX11 ... -Wl,--start-group ...
   ```

   来源是 `XINERAMA_LIBS = -lXext -lXinerama`（`Makefile:547`）经 `openbox_openbox_LDADD`（`Makefile:778`）注入；`build.sh:278-281` 的 OB_LIBS **没有** `-lXinerama`。→ 抹掉 LIBADD 那段，开 XINERAMA 会直接 unresolved `XineramaQueryScreens`。

   **准确说法**：`build.sh` 的 `--start-group OB_LIBS` 负责大头，configure 的 `X*_LIBS` 负责**补齐 OB_LIBS 漏掉的库**（Xinerama 是其中唯一一个）。它在 group 外、只扫描一次，顺序上属于侥幸安全（`.o` 全在它前面）。

2. **configure 的探测符号 ≠ openbox 代码里的符号。** `AC_CHECK_LIB` 探测用 `XRRSelectInput` / `XShapeCombineShape` / `XSyncInitialize` / `XkbBell`，这些**只在 configure 的临时测试程序里出现**，openbox 源码里一次都没用（`nm` 全是 0 refs）。真实调用是 `XRRUpdateConfiguration`、`XineramaQueryScreens`、`frame_adjust_shape_kind`、`obt_display_extension_shape/sync`。→ 想证明某个 `#ifdef` 分支编进了代码，grep `obt_display_extension_xxx`，别 grep 探测符号。

3. **`nm -u` 对 stripped 静态二进制无输出是正常的**（确实没有未解析符号），别误判成"没链上"。要查对象文件：`nm -A openbox/openbox_openbox-screen.o`。

4. **`xx-verify --static` 成功时打印 `err 0, pass`**（此前记的"静默无输出"不准确）。

5. **`sed -i "/pat/d"` 在 `docker exec sh -c '...'` 里会被引号转义搞坏**（`sed: unmatched '/'` / `unsupported command -`）→ 用 `grep -v -e pat1 -e pat2 file > new && mv new file` 最稳。

### 7. imlib2 / xcursor 已补上（8/10）

补库后重跑同一个沙箱（`/tmp/obox-test`），configure 两个都转 yes，静态链接通过。

**关键发现：Alpine `main` 仓库的 `-dev` 包是带 `.a` 的**

| 包 | 版本 | 提供的 `.a` |
|---|---|---|
| imlib2-dev | 1.7.4-r0 | `libImlib2.a` |
| libxcursor-dev | 1.2.0-r0 | `libXcursor.a` |
| tiff-dev | 4.4.0-r4 | `libtiff.a`、`libtiffxx.a` |
| libwebp-static | 1.2.2-r2 | `libwebp.a`、`libwebpdecoder.a`、`libwebpdemux.a`、`libwebpmux.a` |

→ 装上后 `/usr/lib/*.a` 117 → 123，新增 `imlib2.pc` / `xcursor.pc` / `libtiff-4.pc`。

**但光装包不够，第一轮就挂在传递依赖上**

```
undefined reference to `XFixesSetCursorName'       ← -lXfixes
undefined reference to `XGetXCBConnection'         ← -lX11-xcb
undefined reference to `xcb_shm_create_segment'    ← -lxcb-shm
```

根因：**`PKG_CHECK_MODULES` 取的是非 static 的 `Libs:` 字段，不是 `Libs.private:`**；而且 `imlib2.pc` 干脆连 `Requires:` 都没有。所以 `Makefile` 里只有 `XCURSOR_LIBS = -lXcursor`、`IMLIB2_LIBS = -lImlib2`，传递依赖全靠 OB_LIBS 手写补。

补到 `build.sh:286`（这些 `.a` 镜像里本来就有）：

```
-lXfixes -lX11-xcb -lxcb-shm -ljpeg -lturbojpeg -ltiff -lwebp -lwebpdecoder -lwebpdemux -lwebpmux -lXdamage
```

**结果**：

```
DEFS: -DUSE_XCURSOR=1 -DUSE_IMLIB2=1 -DHAVE_LIBX11=1 -DXKB=1 -DXRANDR=1 -DSHAPE=1 -DXINERAMA=1 -DSYNC=1 -DAUTH=1

configure:  X Cursor Library... yes
            Imlib2 Library...   yes
            SVG Support (librsvg)... no
            Startup Notification... no
            Session Management... no
```

产物 openbox 6.3M → **6.6M**，`file` = statically linked，`ldd` = Not a valid dynamic program，`xx-verify --static` rc=0。代码确实编进去了：

```
obrender/image.o: U imlib_load_image / imlib_context_set_image / imlib_free_image
                  U imlib_image_get_width / imlib_image_get_height / imlib_image_get_data_for_reading_only
```

四档对照：`6.3M`（baseline，xrandr/xshape/xsync）→ `6.3M`（再开 xkb/xinerama，代码量小）→ `6.6M`（再开 imlib2/xcursor，带图像解码链）→ **`10.0M`**（再开 librsvg，拖进 glib/gio/gmodule/gdk-pixbuf/pangocairo 整组静态归档，见四.8）。

### 8. librsvg 不是硬阻塞：打通了（最终 8 开 2 关）

四.1 里写的"硬阻塞"**是错的**，已推翻。Alpine `librsvg-dev` 不带 `.a` 是真的，但整条链都能源码出静态库。

**前置**：`intltool`（libcroco 的 autogen 要它），已加进 `openbox/build.sh:apkdeps()`。

**落地做法：不复制，直接跨脚本复用 `v-tint2/build.sh` 的构建函数**（仓内现成，套路照搬 `u-gtk/build.sh:186-193`、`v-feh/build.sh:54-57`）：

```sh
# openbox/build.sh 的 b_deps：STATIC=yes 只出 .a
STATIC=yes bash /src/v-tint2/build.sh libcroco &
wait
STATIC=yes bash /src/v-tint2/build.sh librsvg &
wait
```

为此给 `v-tint2/build.sh` 的 `libcroco()` / `librsvg()` 加了个 `STATIC=yes` 开关（默认行为完全不变，tint2 那条链路不受影响）：

```sh
test "yes" = "$STATIC" || export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
test "yes" = "$STATIC" && export DISABLE_SHARED=--disable-shared
...
./configure --enable-static $DISABLE_SHARED
...
make install
test "yes" = "$STATIC" && rm -f /usr/local/lib/librsvg-2.so*
```

**落地时踩到两个坑**，都在这层：

1. **对方脚本默认故意带 `.so`**——v-tint2 自己的注释里就写着 `attempted static link of dynamic object /usr/local/lib/libcroco-0.6.so`。直接调、不加 `--disable-shared`，openbox 链接报：
   ```
   /usr/bin/.../ld: attempted static link of dynamic object `/usr/local/lib/librsvg-2.so'
   ```
   `.so` 装进 `/usr/local/lib` 后，libtool 把 pc 里的 `-lrsvg-2` 展开成绝对路径 `.so` + `-Wl,-rpath`，`--static` 拦不住。

2. **只删 `.so`，别连 `.la` 一起删。** 删掉 `.la` 后 libtool 展开不了 `dependency_libs`，`pango_cairo_*` 8 个符号立刻 undefined。而 `librsvg-2.0.pc` 的 `Requires` 本来就只有 `glib-2.0 gio-2.0 gdk-pixbuf-2.0 cairo`，**没有 pangocairo**（与构建模式无关）→ 只能手工补 `-lpangocairo-1.0` 进 OB_LIBS。

产物：`libcroco-0.6.a` 447K / `librsvg-2.a` 432K。注意 `make install` 走 libtool hardlink，`.a` 的 mtime 可能还是上一次的时间戳，得 `md5sum` 对照才算准。

**openbox 侧只差 OB_LIBS 补库**，`configure` 立刻转 `checking for LIBRSVG... yes` / `SVG Support (librsvg)... yes`。但静态链接会一层层暴露传递依赖，实测按这个顺序逐个补：

```
rsvg_handle_*            ← -lrsvg-2 -lcroco-0.6   （obrender/image.c 的 SVG 分支）
g_module_open 等         ← -lgmodule-2.0          （gio 动态加载后端）
mnt_find_mount_point     ← -lmount -lblkid        （GUnixMountPoints）
pixman_image_create_bits ← -lpixman-1             （cairo region 实现）
pango_cairo_*            ← -lpangocairo-1.0       （librsvg 用 cairo 画文本）
```

最终 OB_LIBS 追加段（`build.sh:288-290`）：

```
-luuid -lXfixes -lX11-xcb -lxcb-shm -ljpeg -lturbojpeg -ltiff \
-lwebp -lwebpdecoder -lwebpdemux -lwebpmux -lXdamage \
-lrsvg-2 -lcroco-0.6 -lgmodule-2.0 -lmount -lblkid -lpixman-1 -lpangocairo-1.0
```

**代码确实编进去了**（不是探测符号，是业务符号）：

```
obrender/image.o: U rsvg_handle_new_from_file / rsvg_handle_render_cairo
                  U rsvg_handle_get_dimensions / rsvg_handle_close
obrender/image.o: T LoadWithRsvg / DestroyRsvgLoader
```

DEFS 拿到 `-DUSE_LIBRSVG=1`。产物 openbox **10.0M**（从 6.6M 涨上来），`file` = statically linked, stripped，`ldd` = Not a valid dynamic program，`xx-verify --static` rc=0，链接行里 `-lrsvg-2` 最终解析成 `/usr/local/lib/librsvg-2.a`。体积暴涨全在这条链：librsvg 把 glib / gobject / gio / gmodule / gdk-pixbuf / pixman / pangocairo 整组静态归档都拖进来了，而这些此前只在链接行里是"按需取"，`.a` 归档按符号拉取。

**教训**：判断某特性是否"硬阻塞"，别停在 `pkg-config` 找不到 `.pc`，也别停在镜像里有没有 `.a` —— 先查仓内有没有现成的 `v-*/build.sh` 构建函数（librsvg 就有），有的话把它的产物静态化接进来，成本就是补一层传递依赖。真正的硬阻塞只有 **startup-notification**：Alpine main + community 索引 grep 0 命中，仓内也无构建路径。

### 9. 调试技巧（本轮）

- **`apk update` 在本容器静默挂死**（90s 无输出），但 `curl` 完全正常（APKINDEX 0.26s 下完）→ 手工 `curl -L` 拉 index 和 `.apk`，再 `tar xzf` 解到 `/`，绕开 apk。
- **alpine `.apk` 本身就是 gzip 压缩的 tar**（文件类型是 gzip，不是 apk 专有格式），`tar tzf xxx.apk` 直接列内容。
- **`.apk` 文件名带版本**：`imlib2-dev.apk` 是 404，实际是 `imlib2-dev-1.7.4-r0.apk`，版本从 index 的 `V:` 字段取。
- **`curl` 必须带 `-L`**：tencent 镜像有重定向，不带 `-L` 会拿到 244 字节的跳转 HTML，`-o` 照样生成文件，看着像下载成功。
- **index 解压要分文件**：`for f in *.tar.gz; do zcat $f | tar -xOf -; done`，直接 `tar` 整个目录只读得到第一个归档。
- **判传递依赖用 `pkg-config --static --libs <pkg>`**，能看到完整闭包；`PKG_CHECK_MODULES` 不会给你这个。
- **`cairo.pc` 的 `Requires.private` 里明明白白写着 `pixman-1 >= 0.30.0`，但链接行里就是没有 `-lpixman-1`** —— 因为走的是交叉前缀 pkg-config + `--start-group OB_LIBS` 手工清单，pc 的 private 依赖不会自动展开。`pixman-static` 其实早已装好（`/usr/lib/libpixman-1.a`），只是没人把它写进 OB_LIBS。这类"库明明有、就是没链上"的问题，用 `pkg-config --static --libs cairo` 对照 `configure` 实际输出的 `LDADD` 就能定位。
- **librsvg 静态链路的前置是 `intltool`**（libcroco 的 autogen 要 intltoolize），容器默认没有 → 已加进 `openbox/build.sh:apkdeps()` 的 `apk --no-cache add`。
- **gitee 镜像可直接 git clone 拿 tag**：`git clone --depth=1 --branch=0.6.13 https://gitee.com/g-system/fk-libcroco`、`--branch=2.40.21 https://gitee.com/g-system/fk-librsvg`（注意镜像路径是 `g-system/fk-*`，不是 `fk-*`），比 wget tarball 稳，且 tag 名与版本一一对应。
- **静态链接报 undefined reference 要按轮次归类**，别一次补一堆。本轮顺序是 `rsvg_handle_*` → `g_module_*` → `mnt_*` → `pixman_*` → `pango_cairo_*`，每一轮的错误都在暴露下一层，补错了顺序反而掩盖问题。
- **glib/gio 的静态闭包特别深**：`g_module_open` 需要 `-lgmodule-2.0`，`mnt_find_mount_point` 需要 `-lmount -lblkid`，`pixman_*` 需要 `-lpixman-1`，`pango_cairo_*` 需要 `-lpangocairo-1.0`。这些库镜像里全都有 `.a`，纯粹是没人列进 OB_LIBS。

## 五、build.sh 落仓改动明细

沙箱（`/tmp/obox-test`）验证通过后落仓，commit `8d4c5be`。改 2 个脚本、不动 Dockerfile。最终 **8 开 2 关**，产物 openbox **10.0M** / obxprop 1.8M 纯静态。

### 1. 改动总览

| 文件:行 | 改动 | 目的 |
|---|---|---|
| `openbox/build.sh:339` | `apk --no-cache add` 加 `intltool` | libcroco 的 `autogen.sh` 要 `intltoolize` |
| `openbox/build.sh:369-373` | `xx-apk` 加 5 个包 | xcursor / imlib2 的 `.a` 来源 |
| `openbox/build.sh:376` | `apk add util-linux-dev` | `libmount.a` / `libblkid.a` |
| `openbox/build.sh:398-400` | b_deps 跨脚本调 libcroco / librsvg | librsvg 静态链路 |
| `openbox/build.sh:291-293` | OB_LIBS 追加段扩到 19 库 | 补 pc 拿不到的传递依赖 |
| `openbox/build.sh:296-304` | configure 去掉 4 个 `--disable-*` | 4 个开关转开 |
| `v-tint2/build.sh:14-15, 71-72` | `STATIC=yes` 开关 | 复用对方脚本但只出 `.a` |
| `v-tint2/build.sh:34, 87` | install 后清 `.so` | 防止 libtool 链上共享库 |

### 2. apkdeps：7 个新包按三个 apk 变体分位

```sh
apk --no-cache add \
    curl build-base clang meson pkgconfig patch glib-dev \
    intltool                                  # +  工具包

xx-apk --no-cache --no-scripts add \
    ...原 30 个...
    libxfixes-dev                             # +
    libxcursor-dev                            # +
    imlib2-dev                                # +
    tiff-dev                                  # +
    libwebp-static                            # +

apk add expat-static #fontconfig
apk add util-linux-dev                        # +
```

分位跟着既有惯例走：工具包进 `apk --no-cache add`，`-dev`/`-static` 进 `xx-apk --no-scripts add`，散装包用裸 `apk add`（沿用 `expat-static` 的写法）。

`.a` 归属实测（`apk info --who`）：

| 包 | 提供的 `.a` |
|---|---|
| imlib2-dev-1.7.4-r0 | `libImlib2.a` |
| libxcursor-dev-1.2.0-r0 | `libXcursor.a` |
| libxfixes-dev-6.0.0-r0 | `libXfixes.a` |
| tiff-dev-4.4.0-r4 | `libtiff.a` |
| libwebp-static-1.2.2-r2 | `libwebp.a` `libwebpdecoder.a` `libwebpdemux.a` `libwebpmux.a` |
| util-linux-dev-2.37.4-r0 | `libmount.a` `libblkid.a` |

`libX11-xcb.a` 不需要新包（`libx11-static` 已提供），`libuuid.a` 仍靠 `fontconfig-static` 的传递依赖（见 8.6）。

### 3. b_deps：跨脚本复用，不复制构建函数

```sh
b_deps)
    apkdeps
    apk add fontconfig-dev fontconfig-static
    # bash /src/openbox/build.sh fontconfig &
    bash /src/openbox/build.sh libxrandr &
    bash /src/openbox/build.sh pango &
    STATIC=yes bash /src/v-tint2/build.sh libcroco & #librsvg 前置，复用 v-tint2 脚本
    wait
    STATIC=yes bash /src/v-tint2/build.sh librsvg & #librsvg > libcroco；STATIC=yes 只出 .a
    wait
    # view libs
    find /usr/lib |egrep "libpango|libXrandr|libfontconfig" |grep "\.a$" |sort
    find /usr/local/lib |egrep "librsvg|libcroco" |grep "\.a$" |sort
    ;;
```

`oneBuild` 里 `$1` 不带引号，靠 shell 函数名查找执行 → `bash /src/v-tint2/build.sh librsvg` 跑的是对方脚本里定义的 `librsvg()` 函数，不是某个子目录。跨脚本调用的仓内惯例：`u-gtk/build.sh:186-193`、`v-feh/build.sh:54-57`、`v-tint2/build.sh` 的 `b_deps`。

**为什么 libcroco 与 librsvg 之间要夹一层 `wait`**：librsvg 的 configure 阶段就要 `libcroco-0.6.pc`，两者不能并行。libxrandr / pango / libcroco 互不依赖，`&` 并发跑（实测 3s / 10s / 37s），librsvg 必须单独排在最后一轮（41s）。

**两步式用法不变**（`Dockerfile:159-160`）：`bash build.sh b_deps`（deps 初始）→ `bash build.sh openbox`（程序编译）。依赖库构建全部落在 b_deps，`openbox()` 只消费产物。

### 4. configure：flag 13 → 9

```
原（13 个）                                  现（9 个）
--build=$(TARGETPLATFORM= xx-clang ...)      --build=...
--host=$(xx-clang --print-target-triple)     --host=...
--prefix=$INS_PREFIX                         --prefix=...
--datarootdir=$INS_PREFIX/share              --datarootdir=...
--disable-shared                             --disable-shared
--enable-static                              --enable-static
--disable-nls                                --disable-nls
--disable-xcursor        ✗ 去掉
--disable-librsvg       ✗ 去掉
--disable-session-management                 --disable-session-management
--disable-startup-notification               --disable-startup-notification
--disable-xkb           ✗ 去掉
--disable-xinerama      ✗ 去掉
```

4 个 `[default=enabled]` 的开关去掉 disable 后**不会自己转开**——`PKG_CHECK_MODULES` 找不到 `.pc` 会静默降级，configure 不报错、直接跳过对应 `#ifdef` 分支。必须配合 apkdeps 的包 + OB_LIBS 的传递依赖才真正生效（实测证据见四.3 的 DEFS 对照）。

### 5. OB_LIBS：base 30 + 追加 19 = 49

```sh
OB_LIBS="-lX11 -lxcb -lXdmcp -lXau -lXext -lXft -lXrandr -lfontconfig -lfreetype \
  -lpng -lXrender -lexpat -lxml2 -lz -lbz2 -llzma -lbrotlidec -lbrotlicommon \
  -lintl -lfribidi -lharfbuzz -lpangoxft-1.0 -lpangoft2-1.0 -lpango-1.0 \
  -lgio-2.0 -lgobject-2.0 -lglib-2.0 -lpcre -lgraphite2 -lffi"          # 30，未动

# librsvg/imlib2/xcursor 的传递依赖：PKG_CHECK_MODULES 只取非 static 的 Libs:
# （imlib2.pc 干脆没有 Requires，librsvg-2.0.pc 的 Requires 里没有 pangocairo），
# .a 镜像里都有，只能手工补进 group。
# 按 undefined reference 逐轮暴露的顺序：rsvg_handle_* → g_module_* →
# mnt_find_mount_point → pixman_region32_* → pango_cairo_*
OB_LIBS="$OB_LIBS -luuid -lXfixes -lX11-xcb -lxcb-shm \
  -ljpeg -lturbojpeg -ltiff -lwebp -lwebpdecoder -lwebpdemux -lwebpmux -lXdamage \
  -lrsvg-2 -lcroco-0.6 -lgmodule-2.0 -lmount -lblkid -lpixman-1 -lpangocairo-1.0"  # 19
```

追加段 19 个里 `-luuid` 是原有项（原来单独一行 `OB_LIBS="$OB_LIBS -luuid"`），所以**净增 18 个库**。按消费方分三组：

- **xcursor 组**：`-lXfixes -lX11-xcb -lxcb-shm`（`XFixesSetCursorName` / `XGetXCBConnection` / `xcb_shm_create_segment`）
- **imlib2 组**：`-ljpeg -lturbojpeg -ltiff -lwebp -lwebpdecoder -lwebpdemux -lwebpmux -lXdamage`
- **librsvg 组**：`-lrsvg-2 -lcroco-0.6`（obrender 的 SVG 分支）+ `-lgmodule-2.0`（gio 动态加载后端）+ `-lmount -lblkid`（`GUnixMountPoints`）+ `-lpixman-1`（cairo region）+ `-lpangocairo-1.0`（librsvg 用 cairo 画文本）

### 6. v-tint2：STATIC 开关（默认行为逐行不变）

```sh
function librsvg(){
  # openbox 等纯静态消费方传 STATIC=yes：--disable-shared 只出 .a
  # （默认连 .so 一起装，pc 里 -lrsvg-2 会优先链 .so，openbox 静态链接直接报 attempted static link）
  test "yes" = "$STATIC" || export LDFLAGS="-Wl,--as-needed -Wl,--strip-all"
  test "yes" = "$STATIC" && export DISABLE_SHARED=--disable-shared

  ...
  ./configure --enable-static $DISABLE_SHARED
  ...
  make install
  # STATIC 模式清掉 .so（保留 .la 供 libtool 展开 dependency_libs：pangocairo/cairo/gio…）
  test "yes" = "$STATIC" && rm -f /usr/local/lib/librsvg-2.so*
```

`libcroco()` 同构。`STATIC` 未设时四条判断的逐行行为：`test "yes" = ""` 为假 → `||` 分支照旧 export LDFLAGS；两条 `&&` 分支不执行；`./configure --enable-static $DISABLE_SHARED` 里 `$DISABLE_SHARED` 展开为空串，等价于原来的 `./configure --enable-static`；`rm -f` 不执行。**tint2 那条链路（默认带 `.so`）逐行等价，不受影响。**

只删 `.so` 不删 `.la` 是有讲究的：`.la` 里的 `dependency_libs` 是 libtool 展开 `-lrsvg-2` 的来源，删了它 `pango_cairo_*` 等符号立刻 undefined。

### 7. 落仓后验证（可复现）

```sh
# 容器内，b_deps ~2min，openbox ~34s
TARGETPATH=/usr/local/static/openbox-all bash /src/openbox/build.sh b_deps
TARGETPATH=/usr/local/static/openbox-all bash /src/openbox/build.sh openbox

ls -lh /usr/local/static/openbox-all/bin/openbox   # 10.0M
file  .../openbox      # ELF 64-bit ... statically linked, stripped
ldd   .../openbox      # Not a valid dynamic program
xx-verify --static .../openbox; echo $?   # 0
xx-verify --static .../obxprop;  echo $?   # 0
grep -c "undefined reference"   <log>      # 0
grep -c "attempted static link" <log>      # 0
```

configure 输出：

```
Startup Notification... no     X Cursor Library... yes
Session Management...   no     Imlib2 Library...    yes
SVG Support (librsvg)... yes
```

DEFS：`-DUSE_XCURSOR=1 -DUSE_IMLIB2=1 -DUSE_LIBRSVG=1 -DXKB=1 -DXRANDR=1 -DXINERAMA=1 -DSYNC=1`。

**别信 `oneBuild` 的 `err 0, pass`**（见 8.4）——deps 阶段没有质量门，上面这套校验是唯一的判据。

