# docs/2026/11130827-ci-builder-tarsrc.md（六章拆出）

> **来源（2026-11-14）**：本文档为 `docs/2026/11110827-ci-builder-gtk-app.md` 之**第六章拆出**，保留章节序号与层级（`## 六、` 起，含 `### 1~5`、`#### 4.x/5.x`）。

## 六、xfce4 源码包收集与下载源（2026-11-13）

### 1、源码包清单与来源（`/_ext/x11base_tar_src/xfce4`）

**背景**：CI 跑 xfce4 stage 失败——`TARBALL EXTRACT FAILED: Thunar-1.6.3` / `libexif-0.6.23`（`.cache` 无 tarball、下载源不可达）。翻本地缓存确认：解压源码**有编译污染**（`/tmp/xfce-build` 262 个 `.o` + 已生成 Makefile），不能当干净源码；**干净源码包 = 原始 tarball**。

**命名规范**：`名字-版本.tar.gz|bz2`（参考 `Thunar-1.6.3.tar.bz2`）。本地两个只有版本号的包已改名：`0.8.2.tar.gz`→**`pasystray-0.8.2.tar.gz`**、`v3.0.tar.gz`→**`pavucontrol-3.0.tar.gz`**。

**下载源（实测可达）**：
- **archive.xfce.org**：需带浏览器 UA（`Mozilla/5.0`），否则可能下到空文件（官方默认拒无 UA 的 curl/wget）。
- **github.com/libexif/libexif/releases/download/v0.6.23/**：直连 200 可达。

**清单（12 个干净源码包，`/_ext/x11base_tar_src/xfce4`）**：

| 包 | 大小 | 来源 |
|---|---|---|
| `Thunar-1.6.3.tar.bz2` | 1.98M | builder-awe `.cache`（已有） |
| `ristretto-0.8.5.tar.bz2` | 584K | archive.xfce.org 下载 |
| `xfce4-settings-4.12.4.tar.bz2` | 1.04M | archive.xfce.org 下载 |
| `exo-0.10.6.tar.bz2` | 1.28M | archive.xfce.org 下载 |
| `libxfce4ui-4.12.1.tar.bz2` | 666K | archive.xfce.org 下载 |
| `libxfce4util-4.12.1.tar.bz2` | 455K | builder-pav `.cache`（已有） |
| `garcon-0.4.0.tar.bz2` | 466K | archive.xfce.org 下载 |
| `xfconf-4.12.1.tar.bz2` | 564K | builder-pav `.cache`（已有） |
| `dbus-glib-0.112.tar.gz` | 715K | builder-pav `.cache`（已有） |
| `libexif-0.6.23.tar.bz2` | 1.46M | github libexif releases |
| `pasystray-0.8.2.tar.gz` | 60K | builder-pav `.cache`（改名） |
| `pavucontrol-3.0.tar.gz` | 133K | builder-pav `.cache`（改名） |

**关键结论**：宿主机环境能下载（archive.xfce.org 带 UA / github 直连 200），**CI 容器/受限环境不能**（CI 之前失败、用户下到空文件，均是容器网络到 archive/github 不通）。要让 CI 用，需把这 12 个 `COPY` 进镜像 `.cache/`（=`$TARGETPATH/../.cache`）或容器，供 `fetch_src` 的 `test -s $TARBALL` 命中、免下载。

### 2、全仓下载/克隆源统计（`compile/` 下，2026-11-13，gitee=已处理）

**规则**：gitee（`g-system`/`infrastlabs`）= 已处理过的源；非 gitee = 潜在问题源（CI 网络到 github/官方不可达）。`$GITHUB` 默认 `https://github.com`（common.sh:20，可环境覆盖）。统计：git clone 55 处 + tarball 下载 26 个字面 URL。

**① 克隆（git clone，含 branch 版本）**

**✅ 已处理（gitee）**：

| 组件 | 源（gitee.com） | 版本 |
|---|---|---|
| u-gtk atk / gdk-pixbuf / gtk / murrine | `g-system/fk-atk` / `fk-gdk-pixbuf` / `fk-gtk` / `fk-murrine` | ATK_2_36_0 / 2.42.8 / 2.24.33 / — |
| w-tint2 libcroco / librsvg / xcb-util / libxi / tint2 | `g-system/fk-libcroco` / `fk-librsvg` / `fk-xcb__util` / `fk-libxi` / `fk-tint2` | 0.6.13 / 2.40.21 / — / — / 16.1 |
| w-feh / w-xlunch / w-hsetroot | `g-system/fk-feh` / `fk-xlunch` / `fk-hsetroot` | master / 0.8.4 / 1.0.5 |
| x-pulseaudio pulseaudio | `g-system/fk-pulseaudio` | br-v13-99-3 |
| v-geany | `g-system/fk-geany` | 1.34.0 |
| x-dropbear dropbear | `g-system/fk-dropbear` | DROPBEAR_2024.86 |
| v-pcmanfm libfm / menu-cache | `g-system/fk-libfm` / `fk-menu-cache` | — |
| x-x11vnc libvnc / libxtst / x11vnc | `g-system/fk-libvnc-libvncserver` / `fk-xorg-libxtst` / `fk-libvnc-x11vnc` | LibVNCServer-0.9.13 / libXtst-1.2.3 / fix-152 |
| xcompmgr / fluxbox | `g-system/fk-xcompmgr` / `fk-fluxbox` | master |
| x-xrdp / xperp | `g-system/fk-xrdp` / `infrastlabs/fk-perp` | sam-custom / master-cust |
| u-misc su-exec / lrzsz / n2n / tinc | `g-system/fk-su-exec` / `fk-lrzsz` / `fk-lucktu-n2n` / `fk-tinc` | master / lucktu-new2 / master-v1.0 |
| suckless st | `g-system/fk-suckless-st` | br-luke-st |

**⚠️ 非 gitee（`$GITHUB`=github 或硬编码代理）**：

| 组件 | 源 | 版本 |
|---|---|---|
| v-engrampa | `github.com/mate-desktop/engrampa` | v1.14.1 |
| v-lxde lxappearance / lxtask | `github.com/lxde/lxappearance` / `lxde/lxtask` | master |
| v-ibus glog / leveldb / yaml-cpp / marisa-trie / OpenCC / librime / ibus / ibus-rime | `github.com/google/glog` / `google/leveldb` / `jbeder/yaml-cpp` / `s-yata/marisa-trie` / `BYVoid/OpenCC` / `rime/librime` / `ibus/ibus` / `rime/ibus-rime` | v0.6.0 / v1.20 / 0.8.0 / v0.2.6 / ver.1.1.9 / 1.9.0 / 1.5.35 / 1.6.1 |
| x-dropbear libxcrypt | `github.com/besser82/libxcrypt` | v4.4.28 |
| x-pulseaudio ogg / flac / vorbis / opus / libsndfile | `github.com/xiph/ogg` / `xiph/flac` / `xiph/vorbis` / `xiph/opus` / `libsndfile/libsndfile` | v1.3.5 / 1.3.4 / v1.3.7 / v1.3.1 / 1.0.31 |
| v-pcmanfm pcmanfm | `github.com/lxde/pcmanfm` | 1.3.1 |
| suckless dwm / dmenu | `git://git.suckless.org/dwm` / `dmenu` | 6.2 / 5.0 |
| w-scrot | `ghfast.top/https://github.com/resurrecting-open-source-projects/scrot` | 1.12.1 |
| dropbear（vers.txt） | `github.com/mkj/dropbear` | master |
| geany / lxde / tint2 / pcmanfm（vers.txt） | `$GITHUB/...`（脚本内已改 gitee，vers.txt 未同步） | 见上 |

**② 源码包下载（tarball，26 个字面 URL，全部非 gitee）**：

| 组件 | 完整 URL | 域名 |
|---|---|---|
| xfce4-settings 4.12.4 | `archive.xfce.org/src/xfce/xfce4-settings/4.12/xfce4-settings-4.12.4.tar.bz2` | xfce |
| Thunar 1.6.3 | `archive.xfce.org/src/xfce/thunar/1.6/Thunar-1.6.3.tar.bz2` | xfce |
| ristretto 0.8.5 | `archive.xfce.org/src/apps/ristretto/0.8/ristretto-0.8.5.tar.bz2` | xfce |
| exo 0.10.6 | `archive.xfce.org/src/xfce/exo/0.10/exo-0.10.6.tar.bz2` | xfce |
| libxfce4ui 4.12.1 | `archive.xfce.org/src/xfce/libxfce4ui/4.12/libxfce4ui-4.12.1.tar.bz2` | xfce |
| libxfce4util 4.12.1 | `archive.xfce.org/src/xfce/libxfce4util/4.12/libxfce4util-4.12.1.tar.bz2` | xfce |
| garcon 0.4.0 | `archive.xfce.org/src/xfce/garcon/0.4/garcon-0.4.0.tar.bz2` | xfce |
| xfconf 4.12.1 | `archive.xfce.org/src/xfce/xfconf/4.12/xfconf-4.12.1.tar.bz2` | xfce |
| libexif 0.6.23 | `github.com/libexif/libexif/releases/download/v0.6.23/libexif-0.6.23.tar.bz2` | github |
| dbus 1.12.26 | `dbus.freedesktop.org/releases/dbus/dbus-1.12.26.tar.gz` | dbus |
| dbus-glib 0.112 | `dbus.freedesktop.org/releases/dbus-glib/dbus-glib-0.112.tar.gz` | dbus |
| gnome-system-monitor 2.28.2 | `download.gnome.org/sources/gnome-system-monitor/2.28/gnome-system-monitor-2.28.2.tar.bz2` | gnome |
| xbindkeys 1.8.7 | `www.nongnu.org/xbindkeys/xbindkeys-1.8.7.tar.gz` | nongnu |
| xrandr 1.5.4 | `www.x.org/releases/individual/app/xrandr-1.5.4.tar.gz` | x.org |
| openbox 3.6.1 | `openbox.org/dist/openbox/openbox-3.6.1.tar.xz` | openbox |
| tigervnc | `github.com/TigerVNC/tigervnc/archive/v1.13.1-1.20.14.tar.gz` | github |
| pasystray 0.8.2 | `github.com/christophgysin/pasystray/archive/refs/tags/0.8.2.tar.gz` | github |
| gpicview 0.2.5 | `codeload.github.com/lxde/gpicview/tar.gz/refs/tags/0.2.5` | github |
| dunst 1.13.2 | `github.com/dunst-project/dunst/archive/refs/tags/v1.13.2.tar.gz` | github |
| rofi 2.0.0 | `github.com/davatorium/rofi/archive/refs/tags/2.0.0.tar.gz` | github |
| xcb-util-xrm 1.0 | `github.com/Airblader/xcb-util-xrm/releases/download/v1.0/xcb-util-xrm-1.0.tar.gz` | github |
| libgwater / libnkutils | `github.com/sardemff7/libgwater` / `libnkutils`（master） | github |
| imlib2 1.7.4 / loaders | `master.dl.sourceforge.net/project/enlightenment/imlib2-src/1.7.4/imlib2-1.7.4.tar.gz`（`_loaders`） | sf |
| imlib2 1.12.2 / loaders | `nchc.dl.sourceforge.net/project/enlightenment/imlib2-src/1.12.2/imlib2-1.12.2.tar.xz`（`_loaders`） | sf |
| librsvg 2.5.0 | `sourceforge.net/projects/librsvg/files/librsvg/2.5.0/librsvg-2.5.0.tar.gz` | sf |
| libcroco 0.6.13 | `mirror.ossplanet.net/gnome/sources/libcroco/0.6/libcroco-0.6.13.tar.xz` | ossplanet |
| startup-notification 0.12 | `www.freedesktop.org/software/startup-notification/releases/startup-notification-0.12.tar.gz` | freedesktop |
| xcb-util-cursor 0.1.6 / image 0.4.1 / keysyms 0.4.1 / renderutil 0.3.10 / wm 0.4.2 | `xorg.freedesktop.org/archive/individual/lib/xcb-util-{cursor,image,keysyms,renderutil,wm}-<ver>.tar.gz` | x.org |
| st 0.8.4 / fluxbox 0.8.4 | `dl.suckless.org/st/st-0.8.4.tar.gz` / `dl.suckless.org/fluxbox/fluxbox-0.8.4.tar.gz` | suckless |

**③ 结论**：tarball 下载源**几乎全部非 gitee 官方**（xfce/gnome/x.org/sourceforge/github/dbus），CI 网络不通时全挂；克隆源大部分已 gitee，但仍有 ~20 处 `$GITHUB`（默认 github）+ 硬编码代理（hub.*、git.suckless.org）。修复方向：换源（gitee/ghfast）或**本地缓存 COPY 进镜像 `.cache/`**（如 1 节 xfce4 12 包做法）。

**清单修正（2026-11-13 下载核对）**：`tigervnc`（实际 `gitee.com/g-system/fk-tigervnc/releases/download/v1.13.1/tigervnc-1.13.1.tar.gz`）、`st`（fk-suckless-st）、`fluxbox`（fk-fluxbox）、`libcroco`（fk-libcroco）均为 **gitee 源（已处理）**，非 tarball 下载，从 ② 非 gitee 清单移除。

### 3、源码包下载落地清单（`/_ext/x11base_tar_src/<组件>/`，2026-11-13）

> **订正（2026-11-13 归位后）**：`/_ext/x11base_tar_src` 源码包缓存已按 `compile/src/` 组件目录名**重新组织**——库包全部归到**下载/构建它的组件**下（不再按库名/混合 `xfce4/` 收集目录），最终 **13 组件目录 31 个源码包**（`openbox`(1)/`suckless`(1)/`v-xfce4`(9)/`x-rofi`(10)/`x-dbus`(2)/`w-xlunch`(1)/`v-sysmonitor`(1)/`v-gpicview`(1)/`v-pasystray`(1)/`v-pavucontrol`(1)/`x-dunst`(1)/`x-xbindkeys`(1)/`x-xrandr`(1)）；并**已推送到独立 git 仓库** `http://sam-dev.local:3000/g-dev1/x11base-tarsrc`（分支 `main`，HEAD `15b3979`，工作区干净）。新结构清单见该仓库 `README.md`。下方旧表（30 组件目录 + `xfce4/` 混合）已过时，仅供历史参考。

**下载方法**：curl 直连（archive.xfce.org / github 直连 200 / dbus / gnome / x.org / openbox / suckless / freedesktop）+ github 用 `ghfast.top` 前缀代理（`curl -k`）。**包名统一 `名字-版本.tar.gz|bz2|xz`**——本地原先仅版本号的已按此调整：`0.8.2.tar.gz`→`pasystray-0.8.2.tar.gz`、`v3.0.tar.gz`→`pavucontrol-3.0.tar.gz`；现全库无「只有版本号」的包名。

**按组件汇总（30 组件目录 ≈ 23.8M + xfce4/ 混合 9.2M = 总计 33M）**：

| 组件 | 包 | 大小 |
|---|---|---|
| dbus | dbus-1.12.26.tar.gz | 2071K |
| dbus-glib | dbus-glib-0.112.tar.gz | 699K |
| dunst | dunst-1.13.2.tar.gz | 4576K |
| exo | exo-0.10.6.tar.bz2 | 1246K |
| garcon | garcon-0.4.0.tar.bz2 | 455K |
| gnome-system-monitor | gnome-system-monitor-2.28.2.tar.bz2 | 2375K |
| gpicview | gpicview-0.2.5.tar.gz | 161K |
| imlib2 | imlib2-1.7.4.tar.gz | 1018K |
| libexif | libexif-0.6.23.tar.bz2 | 1919K |
| libgwater | libgwater-master.tar.gz | 11K |
| libnkutils | libnkutils-master.tar.gz | 65K |
| libxfce4ui | libxfce4ui-4.12.1.tar.bz2 | 650K |
| libxfce4util | libxfce4util-4.12.1.tar.bz2 | 445K |
| openbox | openbox-3.6.1.tar.xz | 644K |
| pasystray | pasystray-0.8.2.tar.gz | 58K |
| ristretto | ristretto-0.8.5.tar.bz2 | 570K |
| rofi | rofi-2.0.0.tar.gz | 696K |
| st | st-0.8.4.tar.gz | 46K |
| startup-notification | startup-notification-0.12.tar.gz | 347K |
| thunar | Thunar-1.6.3.tar.bz2 | 1937K |
| xbindkeys | xbindkeys-1.8.7.tar.gz | 173K |
| xcb-util-cursor | xcb-util-cursor-0.1.6.tar.gz | 397K |
| xcb-util-image | xcb-util-image-0.4.1.tar.gz | 418K |
| xcb-util-keysyms | xcb-util-keysyms-0.4.1.tar.gz | 376K |
| xcb-util-renderutil | xcb-util-renderutil-0.3.10.tar.gz | 378K |
| xcb-util-wm | xcb-util-wm-0.4.2.tar.gz | 416K |
| xcb-util-xrm | xcb-util-xrm-1.0.tar.gz | 393K |
| xfce4-settings | xfce4-settings-4.12.4.tar.bz2 | 1013K |
| xfconf | xfconf-4.12.1.tar.bz2 | 551K |
| xrandr | xrandr-1.5.4.tar.gz | 234K |
| xfce4（混合收集目录） | 12 包（含已复制到组件目录的副本） | 9177K |

**imlib2 缺口已解决（2026-11-13）**：`imlib2-1.7.4.tar.gz`（1018K）从**本地 aliyun 镜像 `alpine-compile-2-dbg`（ID 5de6c26bab43）的 `/rootfs/usr/local/static/.cache/`** 提取（该镜像曾跑 w-xlunch imlib2 构建，`down_catfile` 缓存保留 tarball），已落 `/_ext/x11base_tar_src/imlib2/`。

**`imlib2_loaders-1.7.4.tar.gz` 不需要额外包（2026-11-13 复核确认）**，依据：
- **新旧 build.sh 都只下载 imlib2 本体**：当前 `w-xlunch/build.sh:35` `down_catfile ${IMLIB2_URL}`（IMLIB2_URL 仅 `imlib2-1.7.4.tar.gz`）；旧版 `v-xlunch/build.sh:30` 同。`imlib2_loaders` URL 在 `w-xlunch/build.sh:15/:18/:26`、旧版 `:11/:14/:21` **全是注释**，从未真正下载。
- **实际 loader 来自 imlib2 源码自带模块**：`imlib2-1.7.4.tar.gz` 内含 `src/modules/loaders/loader_png.c`、`loader_jpeg.c`（及 gif/tiff/bmp/webp 等）；**svg 上游无**（包内无 `loader_svg.c`）。
- **svg loader 靠 patch 手写**：`w-xlunch/loader_svg.c`（librsvg→cairo ARGB32，87 行）+ `build.sh:55-119` python 幂等补 `src/lib/loaders.c` 注入内置块（跳过 dlopen）→ `build.sh:120-139` 编译 png/jpeg/svg `.o` 进**私有** `libImlib2.a`。
- **`imlib2_loaders` 独立包无 svg**：`docs/2026/11051001-xlunch.md:12` ——"imlib2 1.7.4 的 imlib2_loaders 只有 ani/eet/xcf，**无 svg loader** → 必须手写"。下载它无助于图标（xlunch 用 png/svg/jpeg），反而没有 svg。

> **注**：sourceforge 直连仍被拦（master.dl/nchc.dl 等 0-2 字节）、github `enlightenment/imlib2` tag 404——本包靠镜像缓存绕过，后续重建镜像/换机需留意该缓存源。


### 4、tarsrc 仓库接入方案（gitee `infrastlabs/x11base-tarsrc` 源码包，2026-11-13 分析；4.2 起已实施）

#### 4.1、接入点与实现思路

##### 4.1.1、现状调用链（接入点为什么选 down_catfile）

- `common.sh:28` **`down_catfile`**：全局下载函数——`CACHE=$TARGETPATH/../.cache`；`test -s $CACHE/$file || curl ... > $CACHE/$file`。
- `v-xfce4/build.sh:39` **`fetch_src`**：局部函数，缓存规范化名 `$name.tar.bz2` 到 `.cache`，**底层调 `down_catfile`**（:46）。
- 其余所有组件（gpicview/pavucontrol/dbus…）直接调 `down_catfile`。
- **结论：改 `down_catfile` 一处即可覆盖 xfce4 + 全项目；xfce4 的 `fetch_src` 无需单独改**（它透传 down_catfile）。

##### 4.1.2、实现逻辑（要求 1+2+3）

```sh
function down_catfile(){
  CACHE=$TARGETPATH/../.cache; mkdir -p $CACHE
  url=$1; fname=$(basename ${url%%\?*})                # 去 query 取文件名
  comp=$(basename $TARGETPATH)                          # xxx（如 xfce4/gpicview）
  TARSRC=${TARSRC:-/src/../tarsrc}                      # 宿主项目根/tarsrc（/src 软链透传，见 4.1.4）
  # ① 要求1：仓库不存在 → depth1 克隆（gitee 容器可达，lxtask 先例）
  test -d $TARSRC/.git || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc $TARSRC
  TARSRC_COMP=$(ls -d $TARSRC/*${comp}/ 2>/dev/null | head -1)   # 方案2a 组件目录（见 4.1.3）
  test -n "$TARSRC_COMP" || TARSRC_COMP=$TARSRC
  # ② 要求2：tarsrc 有包优先（精确名 → 版本模糊兜底）
  if test -s $TARSRC_COMP/$fname; then
    cp $TARSRC_COMP/$fname $CACHE/$fname
  else
    ver=${fname#v}; ver=${ver%.tar.*}                    # github archive 版本号名兜底
    hit=$(ls $TARSRC_COMP/*$ver* 2>/dev/null | head -1)
    test -n "$hit" && cp "$hit" $CACHE/$fname
  fi
  # ② 无则源头下载
  test -s $CACHE/$fname || curl -# -k -fSL $url > $CACHE/$fname
  cat $CACHE/$fname
}
```

##### 4.1.3、组件名映射（方案 2a：TARGETPATH basename → ls -d *xxx/）

- **不可行**：`basename $TARGETPATH` 直接当 tarsrc 目录名——`/usr/local/static/xfce4`（无前缀）vs tarsrc `v-xfce4`（带 `v-/w-/x-`）不一致。
- **方案 2a（用户拍板）**：先读 `TARGETPATH=/usr/local/static/xxx`，再在 tarsrc 根目录 `ls -F | grep "*xxx/"` 匹配——**xxx 唯一，不会跨前缀存在多个**（`v-xfce4`/`v-gpicview`/`v-pavucontrol`…均以 xxx 结尾，ls -F 目录带尾 `/`）：
  ```sh
  comp=$(basename $TARGETPATH)                            # xfce4 / gpicview / pavucontrol
  # 用户表述 `ls -F | grep "*xxx/"`；grep 的 * 是正则（非 glob），按目录名 xxx/ 结尾匹配更稳（=ls -d $TARSRC/*${comp}/）
  TARSRC_COMP=$(ls -F $TARSRC | grep "${comp}/$" | tr -d '/' | head -1)
  test -n "$TARSRC_COMP" || TARSRC_COMP=$TARSRC           # 未命中回退（无 tarsrc 时原逻辑）
  ```
- **唯一性依据**：tarsrc 目录名=`v-/w-/x-` + 组件名，**xxx（xfce4/gpicview/…）在各前缀下唯一**，`*xxx/` 不会跨前缀多命中（tarsrc 无 `libxfce4`/`xfce4settings` 等干扰目录；库包已按组件归位）。
- **验证**：xfce4 → `*xfce4/` 命中 `v-xfce4/`；gpicview → `v-gpicview/`；pavucontrol → `v-pavucontrol/`。

> **订正（2026-11-13）**：gsm/dbus-glib 两组件 **basename 与 tarsrc 目录名不一致**，2a 通配会 miss → 在 `common.sh` 内维护 **case 映射表**单独映射，其余组件仍走 2a：
> ```sh
> case "$comp" in
>   gsm)       TARSRC_COMP="$TARSRC/v-sysmonitor" ;;  # sysmonitor TARGETPATH=/usr/local/static/gsm
>   dbus-glib) TARSRC_COMP="$TARSRC/x-dbus" ;;         # dbus-glib 包在 x-dbus/ 下
>   *)         TARSRC_COMP=$(ls -d "$TARSRC"/*"$comp"/ 2>/dev/null | head -1) ;;
> esac
> ```
> 另加**全局包名兜底**（最后防线）：`find "$TARSRC" -name "$file" -type f | head -1`（tarsrc 31 包 13 目录无重名，唯一命中）。已实测：gsm→`gnome-system-monitor-2.28.2.tar.bz2`、dbus-glib→`dbus-glib-0.112.tar.gz` 均与 tarsrc 文件字节一致（cmp MATCH）。

##### 4.1.4、TARSRC 位置与 buildx.sh 提前克隆（要求 1）

- **TARSRC=/src/../tarsrc**：构建容器 `/src` 软链宿主 `compile/src`，`/src/../tarsrc` = **宿主项目根 `/tarsrc`**（`/src` 软链透传）→ 容器内可访问，跨容器/跨镜像复用。
- **buildx.sh 内提前克隆**（`compile/buildx.sh`）：clone 到**项目相对目录** `tarsrc/`（项目根）：
  ```sh
  # compile/buildx.sh 顶部（compile 分支前）
  test -d tarsrc/.git || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc tarsrc
  ```
  （buildx.sh 在 `compile/` 下，`tarsrc/` = `compile/../tarsrc` = 项目根/tarsrc；可加 echo 提示。）
- **外部克隆亦可**：`git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc /_ext/.../docker-x11base/tarsrc`（宿主侧，等价）。

> **订正（2026-11-13）**：`TARSRC=/src/../tarsrc` 经 `/src` 软链（→`compile/src`）透传，实际解析为 **宿主 `compile/tarsrc`**（非项目根 `/tarsrc`）。`compile/buildx.sh` 相应改 `_TS=$(dirname "$0")/tarsrc`（= `compile/tarsrc`，与 down_catfile 默认同址），否则两处各克隆一份。实测容器内 `/src/../tarsrc` = host `compile/tarsrc`（13 目录 31 包）。

##### 4.1.5、xfce4 覆盖确认（要求 3 优先 xfce4）

- xfce4 `fetch_src` 包名=**规范化**（`Thunar-1.6.3.tar.bz2`…），与 tarsrc `v-xfce4/` **完全一致** → 精确匹配，无需模糊兜底；其 URL 尾文件名也=规范名。
- 9 个 xfce4 包（exo/garcon/libexif/libxfce4ui/libxfce4util/ristretto/Thunar/xfce4-settings/xfconf）全命中。

##### 4.1.6、风险与边界

- **URL 文件名≠tarsrc 规范名**：github archive（`v3.0.tar.gz`/`0.8.2.tar.gz`）→ 版本模糊兜底；tarsrc 每组件包少、冲突低。
- **CI/buildx 多阶段不持久**：每次镜像重建 depth1 clone 一次（gitee 快、可达）；落宿主项目根 → 跨容器复用。
- **改全局函数副作用**：影响所有组件 + `gitac/syncer.sh`（common.sh:29 注释提到）。**建议默认门控**：`TARSRC` 为空则不启用（`test -n "$TARSRC" || <原逻辑>`），CI 显式传 `--build-arg TARSRC=/src/../tarsrc` 才开 → 低风险易回退。
- **验证**：`docker exec builder-awe sh /src/v-xfce4/build.sh b_deps` 实跑，确认 tarsrc 命中、无网络下载。

##### 4.1.7、结论（要不要两处改）

- **不用两处（xfce4 fetch_src 单独改）**：只改 `common.sh` 的 `down_catfile`（接入）+ `compile/buildx.sh`（clone 提示）两文件；xfce4 `fetch_src` 自动受益。
- 前提：组件名映射用 **4.1.3 方案 2a**（`ls -d *xxx/`）。

#### 4.2、实施落地与验证（2026-11-13，已推送 `feat/ai-260925`）

##### 4.2.1、落仓改动（commit 清单）

| commit | 文件 | 说明 |
|---|---|---|
| `cbd0596` | docs/.../11110827-ci-builder-gtk-app.md | 六章 4.1 订正：case 映射表 + TARSRC=compile/tarsrc |
| `8277f76` | compile/src/common.sh | down_catfile 接 tarsrc（case 表 + 2a 通配 + find 兜底） |
| `7706c55` | compile/buildx.sh | 克隆路径修正 `$(dirname $0)/tarsrc` |
| `33dd9dd` | .gitignore | 忽略 `/compile/tarsrc/` |

- **范围**：只改 `common.sh` 的 `down_catfile` 一处 + `buildx.sh` 提前克隆 + `.gitignore`；xfce4 `fetch_src` 底层透传 `down_catfile`，自动受益，无需单独改。

##### 4.2.2、down_catfile 最终实现（compile/src/common.sh:28-61）

```sh
function down_catfile(){
  CACHE=$TARGETPATH/../.cache; mkdir -p $CACHE #移到func内; gitac/syncer.sh调用时vm内执行 会权限故障;
  url=$1
  file=${url##*/}
  # tarsrc 优先（gitee x11base-tarsrc 源码包缓存，2026-11-13）：任何步骤失败/未命中回退 curl 下载，不阻塞。
  # ① 仓库不存在 → depth1 克隆（幂等）② 组件目录映射（TARGETPATH=xxx → *xxx/；例外走映射表）③ 目录内取包（精确名→版本模糊）
  # ④ 全局包名兜底（find -name 唯一命中，最后防线）
  TARSRC=${TARSRC:-/src/../tarsrc}
  if test -n "$TARGETPATH"; then
    (
      test -d "$TARSRC/.git" || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc "$TARSRC" >/dev/null 2>&1
      test -d "$TARSRC/.git" || exit 0
      comp=$(basename "$TARGETPATH")
      # 组件目录映射表（basename 与 tarsrc 目录名不一致的例外；其余走 2a *xxx/；xxx 唯一不跨前缀多命中）
      case "$comp" in
        gsm)       TARSRC_COMP="$TARSRC/v-sysmonitor" ;;  # sysmonitor TARGETPATH=/usr/local/static/gsm
        dbus-glib) TARSRC_COMP="$TARSRC/x-dbus" ;;         # dbus-glib 包在 x-dbus/ 下
        *)         TARSRC_COMP=$(ls -d "$TARSRC"/*"$comp"/ 2>/dev/null | head -1) ;;
      esac
      if test -n "$TARSRC_COMP" && test -s "$TARSRC_COMP/$file"; then
        cp "$TARSRC_COMP/$file" "$CACHE/$file"; exit 0
      elif test -n "$TARSRC_COMP"; then
        ver=${file#v}; ver=${ver%.tar.*}
        hit=$(ls "$TARSRC_COMP"/*"$ver"* 2>/dev/null | head -1)
        test -n "$hit" && cp "$hit" "$CACHE/$file" && exit 0
      fi
      hit=$(find "$TARSRC" -name "$file" -type f 2>/dev/null | head -1)
      test -n "$hit" && cp "$hit" "$CACHE/$file"
    ) >/dev/null 2>&1 || true
  fi
  # ② 无则源头下载
  test -s $CACHE/$file || curl -# -k -fSL $url > $CACHE/$file
  cat $CACHE/$file
}
```

- **容错**：tarsrc 整段包在 `( ... ) >/dev/null 2>&1 || true` 子 shell 内，任何步骤失败（clone 失败/目录未命中/find 未命中）都回退末尾 `curl` 下载，不阻塞；`test -n "$TARGETPATH"` 守卫（TARGETPATH 空时跳过 tarsrc）。
- **映射表**：case 里 `gsm→v-sysmonitor`、`dbus-glib→x-dbus`（二者 basename 与 tarsrc 目录名不一致）；其余走 `*)` 2a 通配 `ls -d *xxx/`（xxx 唯一）。

##### 4.2.3、TARSRC 路径澄清（关键坑，2026-11-13 实测）

- `TARSRC=${TARSRC:-/src/../tarsrc}`：容器内 `/src` 是**软链** → 宿主 `compile/src`，故 `/src/../tarsrc` **透传解析为宿主 `compile/tarsrc`**（**不是**项目根 `/tarsrc`）。
- `buildx.sh` 原写 `$(dirname $0)/../tarsrc` = 项目根/tarsrc → 与 down_catfile 默认**不一致**，会各克隆一份。已改 `_TS=$(dirname "$0")/tarsrc`（= `compile/tarsrc`），两处同址。
- 宿主 `compile/tarsrc/`（gitee 克隆产物）已加 `.gitignore` 忽略，勿入仓。

##### 4.2.4、验证（builder-pav 实测，`/src/../tarsrc` → 宿主 `compile/tarsrc`）

| 组件 | TARGETPATH | tarsrc 目录 | 包 | 结果 |
|---|---|---|---|---|
| gsm | `/usr/local/static/gsm` | `v-sysmonitor/` | gnome-system-monitor-2.28.2.tar.bz2 | `cmp` 字节一致（2432252B）✅ |
| dbus-glib | `/usr/local/static/dbus-glib` | `x-dbus/` | dbus-glib-0.112.tar.gz | `cmp` 字节一致（715340B）✅ |
| xfce4 | `/usr/local/static/xfce4` | `v-xfce4/` | Thunar-1.6.3.tar.bz2 | 精确名 `cmp` MATCH ✅ |
| gpicview | `/usr/local/static/gpicview` | `v-gpicview/` | gpicview-0.2.5.tar.gz | 版本模糊 `cmp` MATCH ✅ |

- **判据**：`down_catfile` 写入 `$CACHE/$file`（`$TARGETPATH/../.cache`）后，与 tarsrc 内对应包 `cmp` 逐字节比对；gsm/dbus-glib 走 **case 映射表**命中，xfce4/gpicview 走 `*)` 2a 通配命中。tarsrc 31 包 13 目录**无重名**（find 兜底唯一命中安全）。
- 命令替换取二进制会剥尾部换行致 `wc -c` 偏小，**判据以 `cmp` 为准**（勿用 `wc -c` 对包大小）。

### 5、gitclone 网络抖动与源码快照缓存（2026-11-13）

#### 5.1、xcbutil m4 submodule 修复：CI 无 tarsrc-git 缓存（已推送 `18d9ee6`→`8231040`）

> 详版见五章 3.3.4；本节为六章"源码获取/网络"专题衔接，记录 gitclone 机制在 **CI 无缓存**场景的坑与修复。

**根因**：CI 构建上下文**不带 `compile/tarsrc-git`**（`.gitignore` 排除 + Dockerfile 只 `COPY ./src /src`）→ 容器内 `/src/../tarsrc-git` 不存在。`gitclone` 缓存未命中回落网络（common.sh:77-78，安全），**但** `w-tint2/build.sh` xcbutil 的 m4 submodule 处理原**无条件 `sed` `.gitmodules` 指向 `/src/../tarsrc-git/util-common-m4`** → CI 下 `git submodule update --init` 从不存在路径拉取失败 → fallback `cp -a` 也因源不存在报 `cp: can't stat '/src/../tarsrc-git/util-common-m4'` → `./autogen.sh` 无 m4 宏/无 configure → `make` 无 install 目标 → feh stage `doExec FAIL`。

**修复（w-tint2/build.sh xcbutil，2026-11-13 最终版）**：
> **订正（2026-11-13）**：进一步改为 m4 子模块用 `gitclone` 预热（用户拍板"5.1子模块也可用gitclone命令先给预热目标目录"），不再 sed+submodule update+cp fallback——gitclone 享受缓存链（GITCACHE>tar.gz>网络）且不依赖 `git://` 协议。
```sh
# m4 子模块: gitclone 预热(享受缓存链 GITCACHE>tar.gz>网络)
rm -rf m4; gitclone https://gitee.com/g-system/util-common-m4 m4
# autogen.sh 检查 `git submodule status|grep ^-`: 父仓库 gitlink 与 gitclone 的 m4 独立克隆 HEAD 不一致→uninitialized→exit 1
# → 移除父仓库对 m4 的 submodule 跟踪(.gitmodules 删段+git rm --cached+.git/config), autogen 检查即过(实测生成 Makefile)
sed -i '/\[submodule "m4"\]/,/^$/d' .gitmodules 2>/dev/null || true
git rm --cached m4 >/dev/null 2>&1 || true
git config --remove-section submodule.m4 2>/dev/null || true
test -f m4/xcb_util_common.m4 || { echo "!! m4 gitclone 未就位(autogen 将失败)"; }
```
- gitee `g-system/util-common-m4` 与宿主缓存 `tarsrc-git/util-common-m4` 同名（`_repo=util-common-m4`）→ **GITCACHE 命中**；CI 无缓存回落 tar.gz 快照/网络 gitee 克隆。
- **原方案（sed+cp，见五章 3.3.4）已废弃**：sed 指向缓存路径 + submodule update + cp fallback——但 submodule update 走 `git://`（CI 常被禁）且 xcb-util `autogen.sh` 会因 m4 uninitialized 再 exit 1，故改 gitclone 预热 + 移除 submodule 跟踪更可控。

**验证（builder-awe，2026-11-13，照 Dockerfile 调用：`bash /src/w-tint2/build.sh xcbutil`）**：

| 验证路径 | 命令/前置 | 结果 |
|---|---|---|
| ① 缓存路径（GITCACHE 命中） | `bash /src/w-tint2/build.sh xcbutil` | ✅ `m4` gitclone 缓存命中（origin gitee g-system）；`./autogen.sh` 生成 Makefile/config.status/configure；CCLD 链接 `libxcb-util.la`；libtool install `libxcb-util.a` → `/usr/local/lib`（RC=0） |
| ② tar.gz 复用路径 | `GITCACHE=/nonexistent` + 预置 `<repo>-default.tar.gz` | ✅ `gitclone tar.gz hit` → 解压还原 `.git` + `configure.ac`（含 `.git` 快照） |
| ③ 网络 clone→打 tar.gz | `GITCACHE=/nonexistent` + 空 `_cache_repo` | ⚠️ **未实测**（builder-awe 到 gitee 当前抖动卡 `Cloning into...`，环境问题非代码）；逻辑已代码确认（`test -d .git`→`tar czf`），留待 CI 复现 |

**产物确认**：`/usr/local/lib/libxcb-util.a`（静态链）＋ `/usr/local/lib/pkgconfig/xcb-{atom,aux,event,util}.pc`。
**坑（首跑踩到）**：`./autogen.sh` 因 m4 gitlink 与独立克隆 HEAD 不一致报 `uninitialized` exit 1（`make` 报 `No targets specified and no makefile found`）——须先移除父仓库 m4 submodule 跟踪（见上）。

**结论**：`grep tarsrc-git compile/src/` 仅剩 w-tint2 一处（已修）；其余 `gitclone` 用法均已回落网络。**CI 下 feh/libcroco/librsvg/libxi/libfm/menu-cache/pcmanfm 主仓库 clone 走 gitee 网络**——gitee 波动是剩余唯一网络风险。

#### 5.2、gitclone 打 tar.gz 快照缓存方案（2026-11-13 已实施，用户拍板）

**问题**：5.1 修复后，CI 无 `tarsrc-git` → 各组件 gitclone 回落网络（gitee/github）；gitee 间歇 `Connection reset by peer` / 慢（fk-libfm 338s）仍致 b_deps 依赖未就位。需让 CI 也能"免网络"命中源码缓存。

**方案（已实施，gitclone 方法内，common.sh）**：
1. **克隆成功之后**：把代码目录打一个压缩包 `<repo>-<ver>.tar.gz` 放 `$TARSRC/_cache_repo/`（**含 `.git`**，即完整 git 仓库快照）；
2. **克隆之前**：检查对应包已有则**直接复用之（解压），跳过克隆**。

**细化（用户拍板 2026-11-13）**：
- **命名**：`<comp>.<repo>-<ver>.tar.gz`（**comp 与 repo 用点连接**，repo-ver 用 `-`，边界清晰，用户 2026-11-14 拍板）；**`comp`**=组件前缀（归类标识，2026-11-14）；**`ver` = `--branch` 值去 `--branch=` 前缀，无则 `default`**（用户拍板）；`repo`=URL 末段 `_repo`（如 `w-tint2.fk-tint2-16.1.tar.gz`、`w-feh.fk-feh-default.tar.gz`）。
- **comp 确定规则（2026-11-14）**：按 `TARGETPATH` basename 匹配 `/src` 下 `*xxx/` 组件目录——`find "$(readlink -f /src)" -maxdepth 1 -name "*$comp"`（`readlink` 解析软链，兼容 builder 软链 / CI 真实目录；**busybox ash 对变量内通配符不重新 glob，故不用 `ls -d *"$comp"/`**）；case 映射处理 basename 与目录名不一致（**`gsm→v-sysmonitor`、`dbus-glib→x-dbus`**，复用 down_catfile）；`TARGETPATH` 空 → `default`。
- **路径**：`$TARSRC/_cache_repo/`（`TARSRC=${TARSRC:-/src/../tarsrc}`，gitee `infrastlabs/x11base-tarsrc` 源码包仓库克隆，common.sh:35）。
- **①只存不推（用户拍板）**：gitclone 只**本地打包**，**不自动推送**；`_cache_repo/` 由用户**手动管理推送**（何时推 tarsrc、推哪些，用户定）。
- **②safe.directory 全局 `*`（用户拍板）**：`git config --global --add safe.directory '*'`（git≥2.35.2 支持通配；容器内可信环境，**免仓库粒度逐个登记**——实测 root 跑宿主 uid=1000 的仓库不再报 dubious ownership，git status 正常）。
- **优先级**：`GITCACHE` 缓存（含 `.git`，本地）> tar.gz 快照（`_cache_repo/`，含 `.git`）> 网络 clone（未命中，不换源）。
- **③边界（解释，用户未看懂处）**：`down_catfile`（六章 4.x）管 **tarball 源码包**（如 `Thunar-1.6.3.tar.bz2`，下载缓存到 `$TARGETPATH/../.cache`）；`gitclone`（本节 5.2）管 **git 仓库源码**（如 `fk-tint2`，快照到 `$TARSRC/_cache_repo/`）。二者是**两种不同形态的源码缓存**——tarball（解压即用，无 git）与 git 仓库（含 `.git`，可 git 操作/后续 submodule）——**用途不同、目录不同（`$TARSRC/<组件>/` vs `$TARSRC/_cache_repo/`）、互不干扰、无重叠**。简单说：down_catfile 是"压缩源码包"、gitclone 是"git 仓库快照"，各管各的，不冲突。

**落地 commit（2026-11-14 推送 `5af7464..8231040`）**：

| commit | 文件 | 内容 |
|---|---|---|
| `6338b3f` | docs/.../11110827-ci-builder-gtk-app.md | 六章 5 订正（m4 gitclone 预热 + tar.gz 快照方案 + 拍板） |
| `18d7905` | compile/src/common.sh | gitclone 打 tar.gz 快照（ver=br值无则default、含.git、只存不推、safe.dir 全局*） |
| `8231040` | compile/src/w-tint2/build.sh | xcbutil m4 改 gitclone 预热 + submodule 跟踪移除 |

**验证总结（2026-11-14 复核）**：
- 5.1 缓存路径：xcbutil 全过（autogen→configure→make→install，`libxcb-util.a` 落 `/usr/local/lib`）；
- 5.2 tar.gz 复用路径：`gitclone tar.gz hit` → 解压还原 `.git`+源码（含 `.git` 快照，git status 正常）；
- 5.2 网络 clone→打 tar.gz：**待 CI 实测**（builder-awe 到 gitee 抖动未跑通，逻辑已代码确认）。

**待办**：① 网络 clone→打 tar.gz 路径实测（gitee 通时 / CI 复现）；② `_cache_repo/` 手动推送时机由用户定（只存不推）；③ 用最新代码（含 `8231040`）重跑 CI 验证四空组件真正构建通过。

#### 5.3、预下载脚本入口 `cache_repo`（buildx.sh，2026-11-14 用户拍板）

**需求**：构建前预下载 gitclone 依赖快照——遍历 `compile/src/` 下 build.sh 的 gitclone 调用点，批量解析、批量打包到 `tarsrc/_cache_repo/`；按脚本路径目录提前设置组件前缀（comp=目录名，如 `w-tint2`）。

**入口（buildx.sh case 新增，`cache_repo` / `cache_tarsrc`）**：
- `bash buildx.sh cache_repo`：预下载（实跑，2026-11-14 验证 `new=52 skip=0 fail=0`，52 个快照生成）；
- `bash buildx.sh cache_tarsrc`：**预留，暂未实现**（后续：tarsrc 源码包仓库按需克隆/更新）。

**cache_repo 实现要点（buildx.sh，函数 `cache_repo` + `cache_repo_resolve`）**：
1. **遍历**：`$(dirname "$0")/src/*/build.sh`（33 个），`comp`=目录名（如 `w-tint2`）——**按路径目录提前设置组件前缀**，无需 TARGETPATH。
2. **解析 gitclone 调用（awk）**：合并 `\` 续行；`match(line, /(^|[;])[[:space:]]*gitclone[[:space:]]+/)` 定位（**兼容 `rm -rf ...; gitclone` 同前缀形态**，w-tint2/u-gtk 曾因此漏解析——行首 `sub` 只认 `gitclone` 开头，前导空白致 awk `split` 产生空 `a[1]`）；`FNR` 记行号（单文件）；截断 `||` 尾随（w-hsetroot 续行后接 `|| { ... }`）、去行内注释/引号；输出 `start|url|dir|branch` 三字段。
3. **变量 resolve（`cache_repo_resolve`）**：`$VAR` 用**调用点前最后一次字面赋值**（`sed -n "1,line" | grep -E "^[[:space:]]*(export[[:space:]]+)?VAR=" | tail -1`）——**关键**：u-gtk/x-pulseaudio 同一变量被多次赋值（`branch=`/`repo=` 多段），必须取调用点前最近一次，否则错位（x-pulseaudio 曾解析到 libsndfile）。处理：去行内注释 ` #...`（x-pulseaudio `repo=...#$GITHUB/...`）、`${VAR:-default}` 参数展开（u-gtk `MURRINE_GIT`）、`$GITHUB` 未定义默认 `https://github.com`、迭代展开（`--branch=$LXTASK_VER`→`--branch=master`）；`branch` 未定义 → `default`（与 gitclone 实际一致）。
4. **打包**：`<comp>.<repo>-<ver>.tar.gz`（点分隔规则同 5.2）；`GITCACHE`(tarsrc-git 含 `.git`) 优先 `cp -a`，否则网络 `git clone --depth=1`；`tar czf` 含 `.git`（同 gitclone 快照）；已有快照 skip；产物只存不推。
5. **验证**（2026-11-14 实跑，模拟 `$0` 树 + `GITCACHE=tarsrc-git`）：52 快照全生成，0 fail；含 `w-tint2.fk-tint2-16.1.tar.gz`（GITCACHE 命中）、`w-tint2.fk-xcb__util-2.40.21.tar.gz`（repo 名含 `__`）、`u-gtk.fk-murrine-default.tar.gz`（`${VAR:-default}` 展开）、`x-pulseaudio.fk-xiph-ogg-v1.3.5.tar.gz`（`repo=`/`branch=` 多段错位修复后正确）、`x-dropbear.fk-libxcrypt-v4.4.28.tar.gz`（`--branch=v$LIBXCRYPT_VER`）。

**TARSRC 克隆优化（buildx.sh 顶部，2026-11-14 用户拍板）**：
- **完整克隆（非 depth1）**：用户明确"TARSRC 不要深度1 完整克隆"——完整历史才能 `ff-only` pull；
- **已有则 pull 非克隆**：`test -d "$_TS/.git"` → 旧 shallow 先 `git fetch --unshallow` 补全，再 `git pull --ff-only`（同步 gitee 最新源码包 + `_cache_repo/` 快照）；无则 `git clone` 完整克隆。

#### 5.4、gitclone / down_catfile 增量缓存日志（cachesrc_log，2026-11-14 用户拍板）

**需求**：gitclone 入口 + down_catfile 入口各做增量日志，记录到 `/usr/local/static/.logs/cachesrc/`（同目录、**不同文件**），每次调用一行，标记 `时间|组件|包|大小|缓存命中|...` 详细明细。

**实现（common.sh `cachesrc_log`）**：
- **通用函数**：`cachesrc_log <文件名> <组件> <包> <大小> <hit> <ver> <url> <耗时ms> <路径>` —— 追加 `/usr/local/static/.logs/cachesrc/<文件名>.log`；**首行写表头**（用户 2026-11-14：每列标注含义，免看不懂）；增量 `>>` 追加不清空。
- **输出格式（10 列，用户拍板：表头 + 第5列 CACHE/MISS/FAIL + 耗时第6列 xxxms + ver 放包后）**：
  `时间|组件|包|ver|大小|缓存命中|耗时|来源|url|路径`
  - **缓存命中**：`CACHE`（gitcache/tarsrc 命中）`|MISS`（net 网络下载）`|FAIL`（net-fail 网络失败）；
  - **耗时**：真实毫秒带 `ms` 后缀（第6列）；
  - **来源**：原标识 `gitcache|tarsrc|net|net-fail`（保留细节，独立一列）。
- **调用点**：
  - `gitclone`（common.sh）：写 `gitclone.log`，**包=快照名 `<comp>.<repo>-<ver>.tar.gz`（带后缀，用户 2026-11-14）**、大小=tar.gz 字节(B)/GITCACHE 目录 du(KB)；
  - `down_catfile`（common.sh）：写 `downcatfile.log`，**包=源码包文件名**、大小=字节(B)；`tarsrc-fuzzy/tarsrc-find` 合并为 tarsrc。
- **关键细节**：
  - 耗时：`_t0=$(_now_ms)` 起（**`/proc/uptime` 单调时钟毫秒**——busybox `date` 无 `%N`/`%3N`，秒级精度致快速命中耗时恒 0，用户 2026-11-14 要求记录真实耗时），各分支结束 `_ms=$(( $(_now_ms)-_t0 ))`；
  - **down_catfile 防重复**：tarsrc 命中在**子 shell `( )` 内**记录并 `exit 0`；父 shell 末尾用 `_curl_ran` 区分"真 curl 下载"才写 net/net-fail 行（tarsrc 命中后 CACHE 已有文件不 curl，不重复记）；
  - 网络失败语义保留：gitclone 网络 clone 失败 `_clone_rc` 非零 → 记 `net-fail` 并 `return $_clone_rc`（原 `&&` 假返回非零行为不变）；
  - comp 列：gitclone 用 `_comp`（`*xxx/` 匹配带前缀，如 `w-tint2`）；down_catfile 用 `$TARGETPATH` basename（`default` 兜底）。
- **验证**（2026-11-14）：宿主模拟 + `builder-awe` 容器真实路径——`/usr/local/static/.logs/cachesrc/gitclone.log` 首行表头 `时间|组件|包|ver|大小|缓存命中|耗时|来源|url|路径`，数据行（`...|16.1|4652K|CACHE|50ms|gitcache|...`，ver 放包后），net→MISS / net-fail→FAIL / tarsrc→CACHE 各映射正确，大小/耗时明细齐全。

#### 5.5、快照只打 `.git`（2026-11-14 用户拍板，取代 5.2 的整目录打包）

**背景**：5.2 的 tar.gz 快照当前把**整个克隆目录**（工作树 + `.git`）一起打包（`common.sh` `tar czf "$_gz" -C "$(dirname "$_dir")" "$(basename "$_dir")"`）。用户 2026-11-14 提出：**工作目录之后可以再检出，只打 `.git` 包不是更小吗？** → 实测确认，并作为 5.2 快照格式的取代方案。

##### 5.5.1、体积收益：实测省约一半

`gitclone` 用 `git clone --depth=1`（shallow）——仓库只有 1 个 commit，`.git` 里的 blob 对象**已是 zlib 压缩**的，而工作树文件是**未压缩原始文件**；两者内容几乎相同（shallow 仅一份版本）→ 整目录打包 ≈ **存了两份**。

实测（3 个代表快照，`tar czf` 整目录 vs `tar czf -C <dir> .git`）：

| 快照 | 工作树 | 整目录 tgz | 仅 `.git` tgz | 差异 |
|---|---|---|---|---|
| v-ibus.ibus-1.5.35 | 15.1MB | 3.68MB | 1.78MB | **-51.5%** |
| w-tint2.fk-tint2-16.1 | 4.6MB | 1.07MB | 0.54MB | **-49.3%** |
| x-x11vnc.fk-libvnc-x11vnc-fix-152 | 8.8MB | 3.44MB | 1.75MB | **-48.9%** |

52 个快照全量重打预计省 20~30MB。

##### 5.5.2、解包侧必须配套改（否则工作树为空）

只打 `.git` 后，解包出的 `$_dir` 里**只有 `.git`，没有源码文件**。必须在 `gitclone` 解包后自动恢复工作树，保持对外契约"`$_dir` 解包即可用"：

```sh
mkdir -p "$_dir"; tar xzf "$_gz" -C "$_dir"
git -C "$_dir" checkout -f      # 按 HEAD 恢复工作树
```

**submodule 无影响**：`git clone --depth=1` 不带 `--recurse-submodules`，快照里 submodule 目录本就是空的，只打 `.git` 不丢东西。

##### 5.5.3、顺带修掉解包路径错配 bug（5.2 引入的现存问题）

**现状 bug**：`cache_repo` 预下载用临时目录 `_tmp=/tmp/cache_repo_tmp_$$`（`buildx.sh:45`）打包 → **包内第一层目录名 = 该临时名**（如 `cache_repo_tmp_1028876`）。而 `gitclone` 解包 `tar xzf "$_gz" -C "$(dirname "$_dir")"` **假设包内顶层名 == `$_dir` 名**；实际调用方 `_dir` 是固定路径（`/tmp/ibus`、`/tmp/libogg` 等，`v-ibus/build.sh:146`、`x-pulseaudio/build.sh:55`），与 `cache_repo_tmp_*` 完全不同 →

- 源码全落到 `/tmp/cache_repo_tmp_1028876/`（残留无用）；
- `$_dir`（`/tmp/ibus`）**不存在**；
- 但 `gitclone` 照样 `return 0`、日志打 `gitclone tar.gz hit` → **错误被吞**，下游 `cd /tmp/ibus` 失败却查不到根因。

即：**当前 52 个整目录快照一旦在 gitclone 命中，实际是坏的**。

**为何只打 `.git` 顺带修好**：打包改 `tar czf "$_gz" -C "$_dir" .git` → 包内第一层固定为 `.git`（**不再含临时目录名这个变量**）；解包 `tar xzf "$_gz" -C "$_dir"` 直接落到 `$_dir/.git`，与包内目录名彻底解耦 → 放错目录的可能性消失。

##### 5.5.4、落仓改动明细（2026-11-14 已实施，已推送 `feat/ai-260925`）

| 文件 | 改动 | commit |
|---|---|---|
| `compile/src/common.sh` | `gitclone` 快照打包 `tar czf "$_gz" -C "$_dir" .git`（原 `-C "$(dirname "$_dir")" "$(basename "$_dir")"`）；解包 `rm -rf "$_dir"; mkdir -p "$_dir"; tar xzf "$_gz" -C "$_dir"` + `git -C "$_dir" checkout -f` 恢复工作树；**旧整目录格式显式 `return 1`**（`snapshot not .git-only (legacy?)`，不再吞错） | `fcb04cf` |
| `compile/buildx.sh` | `cache_repo` 打包 `tar czf "$_gz" -C "$_tmp" .git`（原 `-C /tmp "$(basename "$_tmp")"`） | `b0dba12` |

**52 快照转换结果**（`_cache_repo/`，直接从原包 `.git` 目录重打，无损）：

| 项 | 转换前（整目录） | 转换后（仅 `.git`） |
|---|---|---|
| 总大小 | 127784 KB | **63808 KB**（**-50.1%**）|
| 包数 | 52 | 52 |
| 包内顶层 | `cache_repo_tmp_$$`（临时名） | `.git`（固定） |

**原整目录格式备份**（用户 2026-11-14 要求保留）：`/_ext/x11base_tar_src/_cache_repo_legacy/`，52 个包、127768 KB，顶层仍为 `cache_repo_tmp_1028876`；与 `_cache_repo/` 名称集合一致（`diff` 空）。

**验证（2026-11-14，受控实测，`fk-feh` + `file://` shallow clone）**：

| 场景 | 结果 |
|---|---|
| 新格式快照命中 → 解包 + checkout | ✅ `$_dir/.git` 存在，工作树恢复 7 个顶层源码文件（AUTHORS / ChangeLog / config.mk / COPYING / examples…）|
| `gitclone` 网络 clone 成功后打包 | ✅ 包内顶层**唯一**为 `.git` |
| 旧整目录格式快照命中 | ✅ 显式报 `gitclone snapshot not .git-only (legacy?)` + `return 1`（错误不再被吞）|
| 52 快照抽样无损核对 | ✅ `.git/objects` pack 文件数 新=2 / 原=2（fluxbox、v-ibus）|

> 注：宿主直跑时 `/usr/local/static/.logs/cachesrc/` 无创建权限致 `cachesrc_log` 重定向报错（`common.sh:89`）——容器内该目录存在，`mkdir -p`（`common.sh:87`）正常，非代码问题。
