# x-dropbear 静态版认证失败分析（ubt22/24，yescrypt 根因，2026-11-12）

## 章节表

- 一、dropbear 认证失败：根因分析、方案选择与落地验证（2026-11-12）
  - 1、静态 dropbear 在 ubuntu 22/24 密码认证失败根因与解决方案
  - 2、新老系统兼容 + Xshell 4 兼容 + 方案1 vs 方案3 对比（2026-11-12）
  - 3、方案1 实测与可行性确认（2026-11-12，builder-awe 容器）
  - 4、dropbear 静态链接 + 实跑验证（2026-11-12，builder-awe 容器）
  - 5、rootfs-dbg 镜像检查复现修复（2026-11-16，builder-g224 + hdmi容器ubt22验登录）
- 二、dropbear 版本升级评估与 musl 静态内存分配器（2026-11-16）
  - 0、musl-malloc（换 rpmalloc）链接解析与机制（原第1节，2026-11-12）
  - 1、dropbear 版本升级评估（2026-11-16，2024.86→2026.94）
  - 2、dropbear 2026.94 手动编译验证（2026-11-16，builder-g224 + hdmi）

## 一、dropbear 认证失败：根因分析、方案选择与落地验证（2026-11-12）

### 1、静态 dropbear 在 ubuntu 22/24 密码认证失败根因与解决方案

#### 1.1、现象与结论（一句话）

**静态 dropbear 在 ubuntu 22.04/24.04 下 SSH 密码登录 authFail（Windows/Xshell 客户端），apt（动态）版正常**；根因是**静态构建的 `crypt()` 无法验证 yescrypt 密码哈希**，非主机密钥算法问题，与 dropbear 版本无关。

#### 1.2、根因：静态 `crypt()` 不支持 yescrypt

- dropbear 密码认证用 **`crypt()`**（`svr-auth-passwd.c` 比较 `/etc/shadow` 哈希）；Xshell 默认**密码认证** → 走 `crypt()` → 触发问题。
- 项目是 **musl 静态链接**，musl 自带 `crypt()` **只实现 md5/sha256/sha512/DES，不支持 yescrypt**（yescrypt 是 libxcrypt ≥4.4.27 才有）。
- 发行版自 ubuntu 22.04 / Debian 11 / Fedora 35 起**默认 yescrypt**（`$y$`），此前 sha512（`$6$`）→ 静态 dropbear `crypt()` 对 yescrypt 返回失败 → 密码永不匹配 → authFail。
- **apt（动态）版正常**：链接系统 **libxcrypt.so.4**（ubuntu 22.04+ 的 libxcrypt 4.4.27+，支持 yescrypt）→ `crypt()` 正常。

#### 1.3、证据链（外部）

1. **Buildroot 2024-04**：glibc 2.39 移除 deprecated libcrypt → **dropbear 无法接受密码认证连接**；加 libxcrypt 依赖解决。Ubuntu **24.04=glibc 2.39**，吻合。
2. **dropbear issue #143**：glibc 2.31 起 `crypt()` 移出 libc → configure 报 *"crypt() not available, dropbear server will not have password authentication"*；需链 `-lcrypt`/libxcrypt。
3. **webos 静态 dropbear patch（2023）**：为解此问题，静态 dropbear 内 `dlopen("libcrypt.so.2")` 动态加载系统 libcrypt——印证"静态版链接跟动态认证"。

#### 1.4、dist-vers 哈希对照（仓库记录 `docs/core/dropbear.md`）

| 发行版 | 默认密码哈希 | 静态 dropbear（musl crypt） | 记录 |
|---|---|---|---|
| alpine-3.19 | sha512（`$6$`） | ✅ 支持 | ok |
| ubuntu 18.04/20.04 | sha512（`$6$`） | ✅ | ok |
| **ubuntu 22.04/24.04** | **yescrypt（`$y$`）** | ❌ **musl 不支持** | **authFail** |
| opensuse-15.6 | sha512 | ✅ | ok |
| **debian12 / fedora39 / busybox** | **yescrypt**（Debian 11+/Fedora 35+ 默认） | ❌ | **authFail** |

#### 1.5、解决方案

1. **构建时链 libxcrypt（≥4.4.27，支持 yescrypt）静态库**：builder 里编 libxcrypt（纯 C，可跨 musl 静态），dropbear `./configure LDFLAGS="-lcrypt"` 指向 libxcrypt → 静态 dropbear 内嵌 yescrypt 支持。**最彻底**。
2. **运行时 dlopen 系统 libcrypt（webos 验证方案）**：静态 dropbear patch `crypt()` 为 `dlopen("libcrypt.so.2")` → 用目标系统 libxcrypt（支持 yescrypt）。**最贴近"动态认证"**，无需静态 libxcrypt，但依赖目标系统有 libcrypt.so。
3. **临时规避**：把用户密码哈希改回 sha512（`chpasswd -c SHA512`）——仅测试用，非长久。

#### 1.6、新版本能否解决

**不能靠版本**：dropbear 2025.87+（默认禁 SHA-1）/2025.89（CVE-2025-14282 等修复）**不涉及 `crypt()`/yescrypt**——这是 libc/musl 层问题，与 dropbear 版本无关。需**构建层（链 libxcrypt）或运行层（dlopen 系统 libcrypt）**解决。

#### 1.7、仓库现状与建议落地

- **现状**：`compile/src/x-dropbear/build.sh` 用 `DROPBEAR_2024.86`、`./configure --enable-static --prefix=$TARGETPATH`；`rootfs/src/xconf.sh` 只 `mkdir -p /etc/dropbear`（未生成主机密钥）；`rootfs/src/etc/perp/ssh/rc.main` 启动 `dropbear -EFRp 22`。
- **建议落地**（待拍板）：`x-dropbear/build.sh` 加 libxcrypt 静态依赖（方案1）或 webos dlopen patch（方案2），并实跑验证 ubt22/24 密码登录（builder-awe / hdmi-desktop 容器）。

### 2、新老系统兼容 + Xshell 4 兼容 + 方案1 vs 方案3 对比（2026-11-12）

#### 2.1、Xshell 4 硬约束

Xshell 4（约 2015）是**老客户端**，早于 rsa-sha2（OpenSSH 7.2 / 2016）普及：

- **主机密钥**：Xshell 4 只认 **`ssh-rsa`（SHA-1 签名）**，不认 rsa-sha2-256/512、ed25519。
- **KEX**：Xshell 4 用 **`diffie-hellman-group14-sha1`** 等 SHA-1 系。
- **HMAC**：Xshell 4 用 **`hmac-sha1`**。

**→ dropbear 2025.87+ 默认禁用 SHA-1（ssh-rsa/group14-sha1/hmac-sha1）会直接断 Xshell 4**（hostkey/KEX/HMAC 全不匹配）。

兼容 Xshell 4 两个选项：**留 dropbear 2024.86**（保留 SHA-1，Xshell 4 可连）；或**上 2025.89（含 CVE 修复）但 `localoptions.h` 显式保留** `DROPBEAR_RSA_SHA1 1` / `DROPBEAR_DH_GROUP14_SHA1 1` / `DROPBEAR_SHA1_HMAC 1`。

同时兼容新客户端（OpenSSH 9.x / 新 Xshell，拒 ssh-rsa）→ 需 **RSA 主机密钥（签 ssh-rsa 供 Xshell4 + rsa-sha2 供新客户端）+ ed25519 主机密钥（新客户端优先）** 双份 `-r`（dropbear 支持多 `-r` 同时 offer）。

#### 2.2、方案1 vs 方案3（新老系统 + Xshell 4）

| 维度 | **方案1：静态链 libxcrypt** | **方案3：yescrypt 移植进 dropbear** |
|---|---|---|
| 老系统密码（18/20.04 **sha512**） | ✅ libxcrypt 全套哈希（DES/md5/sha256/**sha512**/yescrypt/bcrypt） | ❌ **纯 yescrypt 会丢 sha512** → 老系统 fail |
| 新系统密码（22/24 **yescrypt**） | ✅ | ✅ |
| **新老系统兼容** | ✅ **全哈希** | ❌ **需双分派（yescrypt+crypt）否则断老** |
| Xshell 4（SHA-1） | ✅ dropbear 原样保留（留 2024.86 或 patch 保留 SHA-1），认证只换 crypt 来源 | ⚠️ 同左，但还需 patch 认证路径 |
| 跨发行版 | ✅ 内嵌 | ✅ 内嵌 |
| 改动量 | 中（builder 编 libxcrypt.a + configure） | 大（源码移植 + patch `svr-auth-passwd.c` 双分派） |
| 关键风险 | musl 内置 crypt 符号冲突（`--allow-multiple-definition`+链接序，需实测） | yescrypt 与 libtomcrypt 的 sha256/sha512 接口对接正确性 |

#### 2.3、结论：方案1 更靠谱

- **方案3 纯 yescrypt 移植是"单哈希"**——只解决新系统，**破坏老系统 sha512 密码**。要新老兼容必须做成**完整 crypt() 替代**（yescrypt + sha512 双分派），实质上就是方案1 的 libxcrypt 逻辑。
- **方案1（libxcrypt）天然全哈希**：sha512（老系统）+ yescrypt（新系统）+ bcrypt 等全支持，**一个库同时兼容新老**，dropbear 源码零改动（只换 crypt 来源），版本可选 2024.86（Xshell4 友好）或 2025.89+patch 保留 SHA-1（要安全修复）。
- 方案1 唯一风险是 **musl crypt 符号冲突**，可用 `--allow-multiple-definition` + 链接序（libxcrypt 在前）解决，**需 builder 实跑验证**。

#### 2.4、推荐落地组合（待拍板）

1. **方案1**：builder 编 libxcrypt ≥4.4.27 `.a`，dropbear `LDFLAGS` 前置链入 + `--allow-multiple-definition`，`nm` 确认 crypt 来自 libxcrypt。
2. **dropbear 版本**：默认 **2024.86**（保留 SHA-1，Xshell4 直接兼容）；若需 CVE-2025-14282 修复则 **2025.89 + localoptions.h 保留 SHA-1 三件套**。
3. **主机密钥**：生成 **ed25519 + RSA** 双份，`dropbear -r ed25519 -r rsa`（ed25519 新客户端、RSA 签 ssh-rsa 供 Xshell4）。
4. **实跑验证**：Xshell 4 + OpenSSH 9.x + 新老发行版（18.04/24.04）密码登录。

> 方案 1 可行的话，**一次解决新老系统 + Xshell 4 全部兼容**。

### 3、方案1 实测与可行性确认（2026-11-12，builder-awe 容器）

#### 3.1、libxcrypt musl 静态编译（成功）

- 源码：`besser82/libxcrypt` **v4.4.28 / v4.4.36**（宿主 github 下载，拷贝进 `builder-awe`，musl 编译）。
- `./configure --disable-shared --enable-static --disable-werror` + `make` → **`.libs/libcrypt.a` 1.3M**，含全哈希对象：`alg-yescrypt-common/opt.o`、`crypt-yescrypt.o`、`crypt-gost-yescrypt.o`、`crypt-md5/sha256/sha512/bcrypt/scrypt/des.o`。

#### 3.2、关键坑：`INCLUDE_*` 宏源码无默认（需手动生成 crypt-hashes.h）

- libxcrypt 的 `crypt-hashes.h` **是生成文件**（`build-aux/scripts/gen-crypt-hashes-h`），git 源码树**缺它**；且 `INCLUDE_yescrypt`/`INCLUDE_gost_yescrypt`/`INCLUDE_scrypt` 宏**源码无默认值**（configure 不检测 yescrypt，`--help` 无开关）→ 默认 yescrypt 被禁用（`crypt("$y$")` 返回 `*0`）。
- **修复**：手动 `perl build-aux/scripts/expand-selected-hashes lib/hashes.conf`（或直接构造 enabled 列表）→ `perl build-aux/scripts/gen-crypt-hashes-h lib/hashes.conf "<enabled>" > lib/crypt-hashes.h`，生成含 `INCLUDE_yescrypt 1` + `hash_algorithms[]` 注册 `"$y$"` 项的头。

#### 3.3、决定性：yescrypt 在 musl 下**完全工作**（非硬伤）

- **假阳性根因**：最初 `crypt("testpass","$y$9$saltsaltsaltsaltsalt$")` 返回 `*0`（errno=EINVAL），一度误判"musl 硬伤"。实为**测试盐格式错**——libxcrypt 的 yescrypt 格式是 `$y$<flags>$<salt>$`（`yescrypt_encode_params_r` 多参数编码），非 `$y$9$salt$` 单参数。
- **正确验证**（`crypt_gensalt_rn("$y$",0,salt24,24,...)` 生成 setting → `crypt("testpass",setting)` 生成哈希 → 再验证）：
  - `gensalt=$y$j9T$k2XAnEHBqQ1Ct2aMXFKNaR4OddqOgpaP`
  - `crypt-gen hash=$y$j9T$k2XAnEHBqQ1Ct2aMXFKNaR4OddqOgpaP$`
  - **`verify match=1 (OK)`**
- **sha512 老系统**：`crypt("testpass","$6$salt")` → OK（`errno=0`）。
- **结论**：**方案1 可行**——libxcrypt 4.4.28 静态 + musl 下 yescrypt 与 sha512 都工作（全哈希新老兼容），之前失败是测试格式错，**非 musl 硬伤**。

#### 3.4、当前进度（继续）

- 已验证：libxcrypt musl 静态 `.a`（含 yescrypt）+ `crypt()` 支持 yescrypt/sha512（match=1）。
- **待续**：dropbear 静态构建**链 libcrypt.a**（musl 内置 crypt 符号冲突 → 链接序/`--allow-multiple-definition`，`nm` 确认 crypt 来源）+ 实跑 yescrypt 密码登录。
- dropbear 2024.86 源码已 `gitee.com/g-system/fk-dropbear` clone 进容器 `/tmp/dropbear`，待 configure+make。

### 4、dropbear 静态链接 + 实跑验证（2026-11-12，builder-awe 容器）

#### 4.1、链接序坑：libcrypt.a 必须放 LIBS（对象后），放 LDFLAGS（对象前）不生效

- **现象**：`make LDFLAGS="/tmp/lx428/.libs/libcrypt.a ..."` 后 `nm dropbear | grep _crypt_yescrypt` = **0**，且出现 `__crypt_sha512`/`__crypt_md5`/`__crypt_des` 等 **musl 符号** → 实际链的是 **musl libc.a 的 crypt**，libcrypt.a 被完全忽略。
- **根因**：dropbear 链接行 `$(CC) $(LDFLAGS) -o $@ $(objs) $(LIBS) -lcrypt`。**LDFLAGS 在对象之前**，此时无未定义符号，ar 不会拉入 libcrypt.a 任何成员；对象产生 `crypt` 未定义引用后，由末尾 musl libc.a（**musl 1.2.x 的 libc.a 自带 crypt/`__crypt_sha512`**，实测 `nm /usr/lib/libc.a | grep " T crypt"` 有）满足。
- **修复**：libcrypt.a 改放 **LIBS（对象之后）**：`make LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition" LIBS="-lz /tmp/lx428/.libs/libcrypt.a"`。链接行 `... $(objs) -lz /tmp/lx428/.libs/libcrypt.a -lcrypt`，libcrypt.a 在对象后拉入，`_crypt_yescrypt`=15、`crypt`=T、musl `__crypt_sha512`=0。
- **musl 符号冲突**：musl libc.a 自带 crypt → `-Wl,--allow-multiple-definition` 必须（否则多重定义报错）；libcrypt.a 在对象后优先，crypt 用 libxcrypt 实现。

#### 4.2、crypt.o 须用生成的 crypt-hashes.h 重编（否则 hash_algorithms 表空）

- **现象**：`crypt_gensalt_rn("$y$",...)` 返回 `*0`（errno=EINVAL），且 `crypt()` 对 `$6$`/`$y$` 都返回 `*0`。
- **根因**：`crypt.c` 的 `hash_algorithms[] = { HASH_ALGORITHM_TABLE_ENTRIES }`，宏来自 `crypt-hashes.h`（经 `crypt-port.h` include）。若 `crypt.o` 编译于手动生成 `crypt-hashes.h` **之前**（make 依赖未正确触发重编），表为空 → `get_hashfn()` 永远返回 NULL → `crypt()/crypt_gensalt_rn()` 返回 `*0`。
- **修复**：`touch lib/crypt.c && make` 重编 `crypt.o`。验证：`objdump -s -j .rodata crypt.o` 应含 `$y$`/`$6$`/`$5$`/`$1$`（**注意：`strings` 默认 min 4 字符查不到 3 字符前缀，会误判为 0**，用 `objdump` 或 `strings -n 3`）。

#### 4.3、dropbear 静态链接成功 + 运行时 yescrypt/sha512 登录成功

- **产物**（common.sh LDFLAGS 含 `--strip-all`）：`file` = `ELF 64-bit LSB executable, statically linked, stripped`。
- **未 strip 中间产物 nm**：`_crypt_yescrypt`=15、`crypt`=T、musl `__crypt_sha512`=0、`_crypt_gensalt_yescrypt_rn`/`_crypt_crypt_yescrypt_rn` 均 T → **crypt 来自 libxcrypt**。
- **实跑（关键）**：`builder-awe` 内 shadow 设 root 密码哈希，`dropbear -p 10022 -r ed25519hostkey` 起服，`dbclient -y -p 10022 root@127.0.0.1 "echo LOGIN_OK_uid\$(id)"` 连入（python `pty.fork` 发密码）：
  - **yescrypt `$y$j9T$...` 密码 → `LOGIN_OK_uiduid=0(root)...` 登录成功**（新发行版兼容）
  - **sha512 `$6$testsalt$...` 密码 → 登录成功**（旧发行版 18/20.04 兼容）
- **stripped 二进制**同样 yescrypt 登录成功（`--strip-all` 只剥符号表，yescrypt 代码/`$y$` 表在 rodata 保留）。

#### 4.4、build.sh 集成（compile/src/x-dropbear/build.sh）

- 新增 `libxcrypt()`：clone v4.4.28 → `gen-crypt-hashes-h lib/hashes.conf "<全哈希>" > lib/crypt-hashes.h` → `./configure --disable-werror --disable-shared --enable-static` → `make` → `touch lib/crypt.c && make` → 产出 `.libs/libcrypt.a`。
- `dropbear()`：`./configure --enable-static`（LDFLAGS 前置 `libcrypt.a` 使 `crypt in -lcrypt... yes` 检测通过）→ `make LDFLAGS="$LDFLAGS -Wl,--allow-multiple-definition" LIBS="-lz $LIBXCRYPT_DIR/.libs/libcrypt.a"`。
- 验证：`xx-verify --static dropbear` + **`strings -n 3 dropbear | grep -qx '\$y\$'`**（产物 stripped 后 `nm` 失效，`$y$` 表项在 rodata 可查）。

#### 4.5、遗留 / 待办

- **网络**：构建容器 DNS 污染（`gitee.com` 被 114.114.114.114 解析成 `*.baiduads.com`），github 出站 https 不通 → **`full` 完整实测（clone+全量 build）待网络恢复**。已用容器内既有源码 `/tmp/lx428`+`/tmp/dropbear` 复现 build.sh 全部命令（configure/make/xx-verify/strings）通过。
- **crypt_gensalt_rn 的 EINVAL**：musl 静态下 `crypt_gensalt_rn("$y$",...)` 仍返回 `*0/EINVAL`（`get_hashfn` 表项在但 gensalt 未走通），**不影响 dropbear**（dropbear 只用 `crypt()` verify 方向，实测 match=1）；待后续查 gensalt 在 musl 静态的细节。
- **主机密钥**：本测试用单 ed25519；最终需 **ed25519 + RSA 双份** `-r`（RSA 供 Xshell4 签 ssh-rsa）。

### 5、rootfs-dbg 镜像检查复现修复（2026-11-16，builder-g224 + hdmi容器ubt22验登录）

#### 5.1、代码改动与验证状态（含排除的误判）

> **✅ 实测闭环（2026-11-16）**：hdmi 容器端口 51023 用 `dropbear-fix2`（527400B 静态，libxcrypt 前置 whole-archive 绑定）ssh 登录 test 用户（`$y$j9T$` yescrypt shadow）→ `Password auth succeeded` + `LOGIN_OK`；同法阴性对照 `dropbear-test2`（187840B 旧版无 libxcrypt）→ `Bad password attempt`×3 + `Permission denied`。**修复确认生效**。

**背景**：rootfs-dbg 新镜像（registry 最新）undock 二次检查——dropbear stage **未重跑**（`oneBuild-dropbear.log` 仍 2024-12-12、无 libxcrypt 段；buildkit 缓存/未触发），二进制 187840B 同旧（无 yescrypt）；openbox 已更新（2.8M→4.4M）。实测新镜像 dropbear 登录仍 authFail（复现 1.2 根因）。

**代码改动（4 个 commit，均已推送）**：

| commit | 改动 |
|---|---|
| `72c8d6e` | `x-dropbear/build.sh` case 加 **`b_deps` 分支**（libxcrypt 前置另放；Dockerfile stage 先 b_deps 再 dropbear——原只调 dropbear 未建 libcrypt.a） |
| `9c78a86` | `compile/src/Dockerfile` dropbear stage：先 `build.sh b_deps` 再 `build.sh dropbear` |
| `03fcbf0` | libxcrypt() 补 **`./autogen.sh`**（gitclone 源码树无 configure，直接 ./configure No such file）；dropbear LIBS 用 `--whole-archive` 包 libcrypt.a |
| `3dd0a95` | dropbear() make **libcrypt.a 前置 whole-archive 到 LDFLAGS**（crypt 在对象前先定义 → 绑定 libxcrypt 非 musl）；LIBS 只留 `-lz` |

**验证状态**：

| 项 | 结果 |
|---|---|
| libxcrypt 构建 | ✅ autogen + gen-crypt-hashes-h（`$y$` 表 2 处/INCLUDE_yescrypt=1）+ touch crypt.c 重编 |
| libxcrypt **功能** | ✅ `xx-clang -static t3v.c libcrypt.a` → `crypt("test123","$y$j9T$...")` **MATCH=YES** |
| dropbear 构建 | ✅ `err 0, pass`，527K `statically linked, stripped`，strings `$y$`=1（表编入） |
| dropbear 绑定 | ✅ **nm 实锤**：`T _crypt_yescrypt`/`_crypt_crypt_yescrypt_rn` 等 libxcrypt 符号全在（前置 whole-archive 生效）；链接命令 `... -Wl,--whole-archive libcrypt.a -Wl,--no-whole-archive ... -lz -lcrypt` |
| **hdmi 实测登录** | ✅ **成功**（2026-11-16，`dropbear-fix2` 527400B 静态版，端口 51023，test 用户 `$y$j9T$` shadow）——`Password auth succeeded for 'test'` + `LOGIN_OK`（ssh_rc=0）；**阴性对照**旧版（187840B 无 libxcrypt）同端口流程 `Bad password attempt`×3 → `Permission denied`，证修复生效 |

**排除的误判（本轮）**：
- **crypt.o 表空**：`objdump -s -j .rodata` 查不到 `$y$` 是**段名误判**（实际在别的段）；`strings -n 3`/全段查 = 有。库没坏。
- **crypt_gensalt_rn NULL**：文档 4.5 已知（musl 静态 gensalt 不走通），**不影响 dropbear**（只用 crypt verify）。
- **cvo `*0`**：测试代码 `<<'C'` heredoc 使 `$OLD` 未展开（字面）→ 误报；argv 版 `t3v` 复测 MATCH。

> **✅ 闭环（2026-11-16）**：hdmi 实测登录成功（上表）。修复链 `libcrypt.a`（libxcrypt yescrypt）前置 whole-archive 到 LDFLAGS 使静态 dropbear `crypt()` 能验 `$y$` 哈希；无需 `-D` debug 定位（直接 A/B 对照：修复版成功 / 旧版 Bad password）。

#### 5.2、主线验证总结：静态 dropbear yescrypt 登录修复（已完成并验证，2026-11-16）

> **一句话结论**：静态 dropbear 在 ubuntu 22/24（默认 **yescrypt `$y$`**）密码认证失败，根因是 musl 静态 `crypt()` 不支持 yescrypt；**修复 = 构建时前置链入静态 libxcrypt（`libcrypt.a`）**，hdmi 实测登录成功。

##### 5.2.1、修复落地（4 个 commit，已推送）

| commit | 改动 |
|---|---|
| `72c8d6e` | `x-dropbear/build.sh` case 加 **`b_deps` 分支**（libxcrypt 前置） |
| `9c78a86` | `Dockerfile` dropbear stage：先 `build.sh b_deps` 再 `build.sh dropbear` |
| `03fcbf0` | libxcrypt() 补 **`./autogen.sh`**；dropbear LIBS `--whole-archive` 包 libcrypt.a |
| `3dd0a95` | dropbear() make **libcrypt.a 前置 whole-archive 到 LDFLAGS**（`crypt` 在对象前先定义 → 绑定 libxcrypt 非 musl）；LIBS 只留 `-lz` |

**关键点**：后置 `-lcrypt` 时 dropbear 的 `crypt()` 仍解析到 musl 内置实现 → 还是 Bad password；**前置 whole-archive** 才真正绑定 libxcrypt。

##### 5.2.2、验证链逐项结果

| 项 | 结果 |
|---|---|
| libxcrypt 构建 | ✅ autogen + `$y$` 表编入 + touch crypt.c 重编 |
| libxcrypt 功能 | ✅ `crypt("test123","$y$j9T$...")` = **MATCH=YES** |
| dropbear 构建 | ✅ 527K `statically linked, stripped`，strings `$y$`=1 |
| dropbear 绑定 | ✅ **nm 实锤** `T _crypt_yescrypt`/`_crypt_crypt_yescrypt_rn` 等 libxcrypt 符号全在 |

##### 5.2.3、hdmi 实跑 A/B 对照（决定成败）

- **修复版** `dropbear-fix2`（527400B）端口 51023，ssh 登录 test 用户（`$y$j9T$` shadow）→ **`Password auth succeeded for 'test'` + `LOGIN_OK`**（ssh_rc=0）
- **旧版** `dropbear-test2`（187840B，无 libxcrypt）同流程 → **`Bad password attempt`×3 → `Permission denied`**（ssh_rc=255）
- **对照结论**：登录成功源于 libxcrypt 前置绑定，非环境/偶然。

> 注：测试用容器内 `/usr/bin/ssh` + SSH_ASKPASS（密码 test123）；dropbear 启动 `-F -E -p <端口> -r /etc/dropbear/dropbear_ed25519_host_key`（hostkey 用容器既有 ed25519）。

##### 5.2.4、文档/记录落仓

- `docs/2026/11121650-x-dropbear-auth.md` 5.1 实测闭环（章节表补 5 节）— commit `d9417e1`
- `docs/2026/README.md` 真机验证表补 dropbear 行 `✅ 正常` — commit `0f440cf`
- 均已 push，工作区干净

**附带发现（操作注意）**：本环境 `docker exec` 输出被 tcp 沙箱 daemon（`127.0.0.1:2375`）吞掉（rc=0 无输出），真实 daemon 在 `/_ext/docker.sock`，需 **`sudo docker exec`** 才有输出（本次全程用它）。

## 二、dropbear 版本升级评估与 musl 静态内存分配器（2026-11-16）

### 0、musl-malloc（换 rpmalloc）链接解析与机制（原第1节，2026-11-12）

> **来源与背景（2026-11-12）**：本节内容源自 **`TODO.md` 第 26-34 行** `# musl-malloc` 小板块（先前记录的 7 个链接，原文见下引用）。作者指令为「**解析 TODO.md 内 musl-malloc 板块的链接，及网上相关资料，结合现有项目环境，可如何应用优化？只分析回复**」。2026-11-12 对上述链接逐一点击解析，结合项目环境（builder-awe / alpine 3.15.10 / musl 1.2.x 静态链）形成本节可行性分析。**仅分析，未落地**。

> `TODO.md` 第 26-34 行原文：
>
> ```text
> # musl-malloc
> https://www.zhihu.com/question/550951106/answer/3199732385 #mimalloc,rpmalloc
> https://www.forrestthewoods.com/blog/benchmarking-malloc-with-doom3/
> https://github.com/12101111/musl-malloc #malloc换成了rpmalloc
> https://github.com/GrapheneOS/hardened_malloc
> https://github.com/mjansson/rpmalloc/graphs/contributors
> https://github.com/microsoft/mimalloc/graphs/contributors
> https://blog.51cto.com/u_16099164/6693747 #go.tidb; glibc提供的ptmalloc2,谷歌提供的tcmalloc,脸书提供的jemalloc
> ```

#### 0.1、板块链接逐一解析

| 链接 | 状态 | 要点 |
|---|---|---|
| zhihu（mimalloc/rpmalloc） | ⚠️ 403 | 主题：两者皆高性能分配器；rpmalloc 更轻量、mimalloc 更成熟通用 |
| doom3 malloc benchmark | ✅ | malloc 性能 min~5ns / median~25ns / worst 1-50μs / 绝对 ~500μs；结论：**malloc 很少是瓶颈，不重点推荐换分配器** |
| musl-malloc | ✅ | 完整 **musl 1.2.3 fork**，`MALLOC_DIR=rpmalloc` 切换，glue.h alias 适配（见 0.2） |
| hardened_malloc | ✅ | **安全加固型**（防堆溢出），README 明言追求长期性能/内存占用**而非微基准**；支持 musl；多独立 arena |
| rpmalloc | ✅ | per-thread heap，轻量快速 |
| mimalloc | ✅ | 微软，通用高性能 |
| 51cto | ✅ | ptmalloc2=glibc 默认多 arena；tcmalloc=TLS 快但内存高（弃维护）；jemalloc=多 arena 低碎片 |

#### 0.2、musl-malloc 换 rpmalloc 的具体机制

##### 0.2.1、Makefile 切换

`MALLOC_DIR = mallocng`（默认）→ 改 `rpmalloc`；`SRC_DIRS` 自动含 `src/malloc/$(MALLOC_DIR)`。

##### 0.2.2、glue.h alias 适配

- 核心 commit `39d7b74717 "Add rpmalloc for musl"`（2022-04-13），后 `a865c83d0b "use optimized memcpy & memset"`。
- `src/malloc/rpmalloc/{glue.h,rpmalloc.c,rpmalloc.h}`。
- glue.h 用 GCC alias：`__libc_malloc_impl`→`rpmalloc`、`__libc_realloc`→`rprealloc`、`__libc_free`→`rpfree`；`aligned_alloc`/`malloc_usable_size` 亦 alias。
- `__malloc_process_init` 调 `rpmalloc_initialize`+`set_main_thread`；`__malloc_thread_init/finalize` 接 rpmalloc 线程钩子。

#### 0.3、风险点：fork 语义

`__malloc_donate` 与 `__malloc_atfork` 均 **no-op** → fork 后子进程不回收父堆、fork 并发 malloc 无锁保护（影响 dropbear/xrdp/daemon 类 fork 应用）。基线旧：musl 1.2.3 + rpmalloc 2022 版，2022-04 后未更新。

#### 0.4、项目环境结合（builder-awe 实测）

- 容器：alpine 3.15.10，musl 1.2.x（默认 **mallocng**）；`/usr/lib/libc.a` 含 malloc/free/realloc/calloc。
- 静态产物：awesome/awm/dbus/ibus/gtop/gsm/gtkmm 栈等——X11/桌面/DBus，多为单线程/低分配率事件循环，malloc 非瓶颈。
- 可能受益场景：**高并发静态服务**（xrdp 多会话、dropbear 多连接）多线程高分配。

#### 0.5、落地决策分析

1. **不建议全局换 rpmalloc**：成本=重编 musl（CI 三架构）+全静态链重编+验证；收益=桌面应用 malloc 非瓶颈趋近 0；风险=fork 语义。
2. **hardened_malloc 不适合**：安全导向非性能导向，与本项目"静态性能优化"目标不符。
3. **若评估**：仅多线程高分配静态服务做 A/B 实测（doom3 journal 回放法）；与 gtkmm 并行教训一致（2 核收益可能为负）。
4. 项目核心瓶颈在**编译时间/CI 三架构**（并行化已解决），不在运行时 malloc。

#### 0.6、小结

维持现状（musl mallocng）；如后续落地仅对高并发静态服务选择性 A/B，先解决 fork 语义适配。

### 1、dropbear 版本升级评估（2026-11-16，2024.86→2026.94）

> **问题**：当前静态 dropbear 版本、官方 GH 最新版本、新功能/CVE、不兼容点、升级收益？

#### 1.1、版本对比

| 项 | 值 |
|---|---|
| **项目当前** | **DROPBEAR_2024.86**（2024-10-22 发布，`build.sh:42` `branch="--branch=DROPBEAR_2024.86"`） |
| **官方 GH 最新** | **DROPBEAR_2026.94**（2026-07-23，Latest tag） |
| 中间版本 | 2025.87(3/5)、2025.88(5/7)、2025.89(12/16)、2026.90(5/3)、2026.91(5/10)、2026.92(7/6)、2026.93(7/21) |

#### 1.2、新功能与安全项（2024.86 → 2026.94）

**安全 CVE 修复（重点）**：

| CVE / 安全问题 | 修复版本 | 影响 |
|---|---|---|
| **CVE-2025-14282** unix stream fwd **root 特权提升**（SO_PEERCRED） | 2025.89 | **影响 2024.84-2025.88 → 本项目 2024.86 受影响** |
| CVE-2025-47203 dbclient hostname 命令注入 | 2025.88 | 老版 |
| CVE-2019-6111 scp 恶意服务器覆盖本地文件 | 2025.89/2026.90 | 老版 |
| CVE-2026-35385 scp 保留 setuid/setgid | 2026.90 | 老版 |
| authorized_keys `forced_command` 绕过（`-t` 时） | 2026.90 | 老版 |
| X11 forwarding use-after-free（内存破坏） | 2026.93 | 需 X11 fwd 启用（**默认不构建**，本项目无碍） |
| authorized_keys 长行绕过 `command=`、空密码+两因素、symlink 写攻击、rekey 内存、fd 越界读等 | 2026.90-92 | 老版 |

**功能/稳定性**：
- **后量子 KEX**（2025.87）：sntrup761 + ML-KEM（libcrux），抗量子——**代码增大**
- **默认禁 SHA-1**（2025.87）：hmac-sha1/ssh-rsa/group14-sha1
- **服务端禁解压**（2025.87）：省内存、减 zlib 攻击面
- fail2ban 支持（2025.87/2024.86）；`-D` authorized_keys 目录；`-M` 会话时长；permitlisten；unix stream `-R` listener（2026.90）；`-Q` 查询算法（2026.91）
- **RSA 指数盲化**（2026.90，侧信道）；公钥查询限 15（防扫描）；MAX_HOSTKEYS 6
- 修 500MB 窗口限制、auth delay、SIGBUS/SIGTRAP、TCP remote listener 关闭、2025.87/2026.90/2026.93 多个回归

#### 1.3、换新版本不兼容点（本项目静态构建关键）

1. **Xshell 4 断连（最大风险）**：2025.87+ 默认禁 SHA-1 → 文档 2.1 已确认 **Xshell 4 只认 `ssh-rsa`(SHA-1)/`group14-sha1`/`hmac-sha1`，会直接断**。必须 `localoptions.h` 保留 `DROPBEAR_RSA_SHA1 1`/`DROPBEAR_DH_GROUP14_SHA1 1`/`DROPBEAR_SHA1_HMAC 1`，或接受弃 Xshell 4。
2. **认证后降权（2025.89+）**：需 `setresgid()`（musl 支持）；但 perp 启动 `dropbear -EFRp 22` 的 root 行为/转发需实测；远程 TCP 转发改用 OS 特权端口限制（替代固定 ≥1024）。
3. **后量子体积/依赖**：sntrup761 增体积；**ML-KEM 用 libcrux（外部库）**，静态链可能需额外处理或禁用（2026.92 修过 sntrup/mlkem 旧平台构建）。
4. **scp 行为变化**：2026.90 `-r` 目标目录存在即禁用；2026.92 禁写输出跟随 symlink——本项目 scp 次要，需知晓。
5. **构建回归需实测**：2025.89 修 RSA/DSS 未构建崩溃（须确认构建含 RSA）；2026.90-94 多次构建修复（ascii_isdigit/reallocarray），**alpine/musl 静态链需实跑**。
6. 2026.94 ipv6 地址打印加方括号（影响 fail2ban 日志解析）；2026.92 authorized_keys 限 300 行（本项目少，无碍）。

#### 1.4、收益评估

- **安全收益最大**：本项目 2024.86 **受 CVE-2025-14282（已认证用户 → root 提权）影响**，升级到 ≥2025.89 即修；另获 dbclient 注入、scp CVE、X11 UAF、authorized_keys 绕过等多个安全修复。
- **功能收益**：后量子抗量子（sntrup761/ML-KEM）、默认禁 SHA-1（安全默认）、服务端禁解压（省内存/减攻击面）、fail2ban、`-M`/`-Q`/permitlisten/`-D`、RSA 盲化、公钥查询限 15（防扫描）。
- **稳定收益**：多个回归/崩溃/窗口/延迟修复。

#### 1.5、建议

- **升级到最新 2026.94**（最低 2025.89 已含 CVE-2025-14282）。
- **必须**：`localoptions.h` 保留 SHA-1 三件套（Xshell 4 兼容）或接受弃 Xshell 4；建议 **ed25519 + RSA 双主机密钥**（文档 2.1 已定）。
- **需实测**：musl 静态链（sntrup/ML-KEM/libcrux、ascii_isdigit）、认证后降权、体积（527K → 可能 600K+）。
- **决策点**：后量子保留与否（体积 vs 抗量子）——建议**保留 sntrup761、评估 ML-KEM（libcrux 静态链成本）**。

### 2、dropbear 2026.94 手动编译验证（2026-11-16，builder-g224 + hdmi）

#### 2.1、验证过程与结果（完整）

> **验证目标**：新版本 **2026.94** 手动编译（**不动 `build.sh`**），保留 SHA-1 三件套（Xshell 4 兼容）+ yescrypt 认证（同现有方案），验证环境兼容旧版本编译 + 登录。

**步骤/结果**：

| 项 | 结果 |
|---|---|
| 源码 | `git clone --depth 1 --branch DROPBEAR_2026.94 https://github.com/mkj/dropbear`（gitee `g-system/fk-dropbear` 无 2026.94 tag；GitHub 可达 `28216cd`）；源码树自带 `configure`（无需 bootstrap） |
| SHA-1 保留 | 写 `localoptions.h`：`DROPBEAR_SHA1_HMAC 1`/`DROPBEAR_RSA_SHA1 1`/`DROPBEAR_DH_GROUP14_SHA1 1`（`default_options.h` 三宏默认 0，2025.87+ 默认禁） |
| configure | 仿 build.sh：`LDFLAGS="... --static -static -Wl,--strip-all -Wl,--allow-multiple-definition /tmp/libxcrypt/.libs/libcrypt.a" ./configure --enable-static --prefix=/tmp/db94inst`（bundled libtomcrypt/libtommath），**rc=0** |
| make | `make LDFLAGS="... -Wl,--whole-archive libcrypt.a -Wl,--no-whole-archive" LIBS="-lz"`，**rc=0**；产物 **572K `statically linked, stripped`**（vs 旧 2024.86 527K，+~58K 后量子/新功能） |
| xx-verify | ✅ **0**（musl 静态通过；builder 默认 gcc = alpine musl 目标，**环境兼容旧版本编译**） |
| yescrypt | ✅ `strings` `$y$` 135 处（libxcrypt 编入，方案同现有） |
| SHA-1 算法 | ✅ `-Q` 确认 **`diffie-hellman-group14-sha1`/`ssh-rsa`/`hmac-sha1` 全在列**（Xshell 4 兼容） |
| 后量子 | ✅ `sntrup761x25519-sha512`/`mlkem768x25519-sha256` 在列（默认构建） |
| **hdmi 登录** | ✅ 端口 51025 `Password auth succeeded for 'test'` + `LOGIN_OK`（ssh_rc=0，yescrypt `$y$j9T$` shadow）——**yescrypt 认证方案在新版本同样有效** |

**结论**：
- 2026.94 可在现有 builder 环境**手动编译通过**（无需改环境，兼容旧版本编译）。
- 保留 SHA-1 三件套后 **Xshell 4 算法齐**（`-Q` 确认 group14-sha1/ssh-rsa/hmac-sha1 在列）。
- **yescrypt 认证（libxcrypt 前置 whole-archive）在新版本同样有效**（hdmi 登录成功）。
- `build.sh` 未动（手动 configure/make）；后续支持多版本出包可参考本验证（含 SHA-1 localoptions + libxcrypt 前置 + 体积/算法核对）。

#### 2.2、build.sh 多版本支持（2026-11-16，commit `1e18d14` + Dockerfile `d186063`）

> **需求**：脚本考虑多版本支持——两版本**独立方法块**（按名字_版本号，互不干扰）；Dockerfile 调新版本方法块作为默认入口。

**改动**（`compile/src/x-dropbear/build.sh` + Dockerfile）：
- **两个独立方法块（无复用、互不干扰）**：
  - `dropbear_2024_86()`：gitee `fk-dropbear` 源；SHA-1 默认开（Xshell 4 直接兼容）。
  - `dropbear_2026_94()`：官方 GitHub 源；写 `localoptions.h` 保留 SHA-1 三件套；含后量子 KEX + 各 CVE 修复。
  - 两块各自完整逻辑：libcrypt.a 前置 whole-archive + `--allow-multiple-definition` + configure/make + xx-verify/strings 验证。
- **case**：不显式列版本分支——`build.sh dropbear_2024_86`/`dropbear_2026_94` 走 **`*)` oneBuild `$1` 按名调函数**；保留 `dropbear)→oneBuild dropbear_2026_94` 默认入口（`build.sh dropbear` 兼容）；`full`/`b_deps` 同步。
- **Dockerfile**：dropbear stage `sh /src/x-dropbear/build.sh dropbear_2026_94`（新版本方法块默认入口）。

> **⚠️ 坑（POSIX 函数名）**：busybox ash 函数名**不能含 `.`**（`dropbear_2026.94()` → `syntax error: bad function name`）→ 方法块名用**下划线**（`dropbear_2024_86`/`dropbear_2026_94`），**入口参数即方法块名**（走 `*)` 兜底，无需显式分支）。

**实跑验证**（builder-g224，两块都跑）：

| 项 | `dropbear_2024_86` | `dropbear_2026_94` |
|---|---|---|
| 构建 | `err 0, pass`，81s | `err 0, pass`，87s（走 `*)` 兜底，gitclone tar.gz 快照命中） |
| 产物 | `sbin/dropbear` **564K `statically linked, stripped`**，**xx-verify=0** | 同左 |
| yescrypt | `$y$` 69 处（libxcrypt 编入） | 同左 |
| SHA-1 | `-Q` 确认 `group14-sha1`/`ssh-rsa`/`hmac-sha1` 全在列（Xshell 4 兼容） | 同左 |
| 日志 | undefined/static link = **0** | 同左 |

**tarsrc 快照**：实跑 gitclone 自动生成 `tarsrc/_cache_repo/x-dropbear.dropbear-DROPBEAR_2026.94.tar.gz`（3.2M，包内仅 `.git`，解包+checkout 复用；common.sh 注释"只存不推，用户手动推送 tarsrc"；已推 prs 远端）。

**后续**：多版本出包（新旧共存/独立安装路径）待定。
