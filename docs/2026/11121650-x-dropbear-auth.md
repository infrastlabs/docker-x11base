# x-dropbear 静态版认证失败分析（ubt22/24，yescrypt 根因，2026-11-12）

## 章节表

- 一、dropbear 认证失败：根因分析、方案选择与落地验证（2026-11-12）
  - 1、静态 dropbear 在 ubuntu 22/24 密码认证失败根因与解决方案
  - 2、新老系统兼容 + Xshell 4 兼容 + 方案1 vs 方案3 对比（2026-11-12）
  - 3、方案1 实测与可行性确认（2026-11-12，builder-awe 容器）
  - 4、dropbear 静态链接 + 实跑验证（2026-11-12，builder-awe 容器）
- 二、musl 静态内存分配器：TODO musl-malloc 板块解析与可行性分析（2026-11-12）
  - 1、musl-malloc（换 rpmalloc）链接解析与机制

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

## 二、musl 静态内存分配器：TODO musl-malloc 板块解析与可行性分析（2026-11-12）

### 1、musl-malloc（换 rpmalloc）链接解析与机制

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

#### 1.1、板块链接逐一解析

| 链接 | 状态 | 要点 |
|---|---|---|
| zhihu（mimalloc/rpmalloc） | ⚠️ 403 | 主题：两者皆高性能分配器；rpmalloc 更轻量、mimalloc 更成熟通用 |
| doom3 malloc benchmark | ✅ | malloc 性能 min~5ns / median~25ns / worst 1-50μs / 绝对 ~500μs；结论：**malloc 很少是瓶颈，不重点推荐换分配器** |
| musl-malloc | ✅ | 完整 **musl 1.2.3 fork**，`MALLOC_DIR=rpmalloc` 切换，glue.h alias 适配（见 1.2） |
| hardened_malloc | ✅ | **安全加固型**（防堆溢出），README 明言追求长期性能/内存占用**而非微基准**；支持 musl；多独立 arena |
| rpmalloc | ✅ | per-thread heap，轻量快速 |
| mimalloc | ✅ | 微软，通用高性能 |
| 51cto | ✅ | ptmalloc2=glibc 默认多 arena；tcmalloc=TLS 快但内存高（弃维护）；jemalloc=多 arena 低碎片 |

#### 1.2、musl-malloc 换 rpmalloc 的具体机制

##### 1.2.1、Makefile 切换

`MALLOC_DIR = mallocng`（默认）→ 改 `rpmalloc`；`SRC_DIRS` 自动含 `src/malloc/$(MALLOC_DIR)`。

##### 1.2.2、glue.h alias 适配

- 核心 commit `39d7b74717 "Add rpmalloc for musl"`（2022-04-13），后 `a865c83d0b "use optimized memcpy & memset"`。
- `src/malloc/rpmalloc/{glue.h,rpmalloc.c,rpmalloc.h}`。
- glue.h 用 GCC alias：`__libc_malloc_impl`→`rpmalloc`、`__libc_realloc`→`rprealloc`、`__libc_free`→`rpfree`；`aligned_alloc`/`malloc_usable_size` 亦 alias。
- `__malloc_process_init` 调 `rpmalloc_initialize`+`set_main_thread`；`__malloc_thread_init/finalize` 接 rpmalloc 线程钩子。

#### 1.3、风险点：fork 语义

`__malloc_donate` 与 `__malloc_atfork` 均 **no-op** → fork 后子进程不回收父堆、fork 并发 malloc 无锁保护（影响 dropbear/xrdp/daemon 类 fork 应用）。基线旧：musl 1.2.3 + rpmalloc 2022 版，2022-04 后未更新。

#### 1.4、项目环境结合（builder-awe 实测）

- 容器：alpine 3.15.10，musl 1.2.x（默认 **mallocng**）；`/usr/lib/libc.a` 含 malloc/free/realloc/calloc。
- 静态产物：awesome/awm/dbus/ibus/gtop/gsm/gtkmm 栈等——X11/桌面/DBus，多为单线程/低分配率事件循环，malloc 非瓶颈。
- 可能受益场景：**高并发静态服务**（xrdp 多会话、dropbear 多连接）多线程高分配。

#### 1.5、落地决策分析

1. **不建议全局换 rpmalloc**：成本=重编 musl（CI 三架构）+全静态链重编+验证；收益=桌面应用 malloc 非瓶颈趋近 0；风险=fork 语义。
2. **hardened_malloc 不适合**：安全导向非性能导向，与本项目"静态性能优化"目标不符。
3. **若评估**：仅多线程高分配静态服务做 A/B 实测（doom3 journal 回放法）；与 gtkmm 并行教训一致（2 核收益可能为负）。
4. 项目核心瓶颈在**编译时间/CI 三架构**（并行化已解决），不在运行时 malloc。

#### 1.6、小结

维持现状（musl mallocng）；如后续落地仅对高并发静态服务选择性 A/B，先解决 fork 语义适配。
