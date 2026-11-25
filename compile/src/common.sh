#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
# set -u # Treat unset variables as an error.
# set -u; #err if not exist

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--as-needed --static -static -Wl,--strip-all"
# 
export CC=xx-clang
export CXX=xx-clang++

# params
test -z "$TARGETPATH" && export TARGETPATH=/usr/local/static/temp1 #/opt/base
test -z "$CONSOLE_LOG" && export CONSOLE_LOG=yes
# export GITHUB=https://hub.njuu.cf # nuaa, yzuu, njuu
test -z "$GITHUB" && export GITHUB=https://github.com 
# https://blog.csdn.net/Zxiuping/article/details/120764834
# git config --global http.sslVerify false ##关闭SSL验证
# 幂等+容错: 多组件并发 source 时并发写 /root/.gitconfig 会锁(could not lock config file)致失败; 已设则跳过, 写失败容错。
git config --global --get http.sslVerify >/dev/null 2>&1 || git config --global http.sslVerify false 2>/dev/null || true


# rm -rf $LOGS; #avoid deleted @batch-mode
function down_catfile(){
  CACHE=${TARGETPATH:+$TARGETPATH/../.cache}; test -n "$CACHE" || CACHE=/tmp/.cache; mkdir -p $CACHE #移到func内; gitac/syncer.sh调用时vm内执行 会权限故障; TARGETPATH 空(如 u-gtkmm)兜底 /tmp/.cache
  _t0=$(_now_ms)
  url=$1
  file=${url##*/}
  comp=$(echo "$0" | sed -n 's#.*/\([^/]*\)/build\.sh$#\1#p'); test -n "$comp" || comp=${TARGETPATH:+$(basename "$TARGETPATH")}; test -n "$comp" || comp=default # 2026-11-15: 脚本路径组件名优先(如 u-gtkmm 走 /src/u-gtkmm/build.sh, common 默认 TARGETPATH=temp1 无意义); 非 build.sh 调用者(syncer/gitac)回落 TARGETPATH basename
  ver=${file#v}; ver=${ver%.tar.*}
  # tarsrc 优先（gitee x11base-tarsrc 源码包缓存，2026-11-13）：任何步骤失败/未命中回退 curl 下载，不阻塞。
  # ① 仓库不存在 → depth1 克隆（幂等）② 组件目录映射（comp=TARGETPATH basename 或脚本路径 xxx → *xxx/；例外走映射表）③ 目录内取包（精确名→版本模糊）
  # ④ 全局包名兜底（find -name 唯一命中，最后防线）。2026-11-15: 门放宽——TARGETPATH 空但脚本路径可推导组件名（如 u-gtkmm）也查 tarsrc。
  TARSRC=${TARSRC:-/src/../tarsrc}
  if test "$comp" != "default"; then
    (
      # tarsrc 仓库标识用 README.md（2026-11-16：原 .git 判断，改为 README.md——允许 compile/.dockerignore 排除 tarsrc/.git 省 ~112M 镜像层，仍能识别仓库）
      test -s "$TARSRC/README.md" || git clone --depth=1 https://gitee.com/infrastlabs/x11base-tarsrc "$TARSRC" >/dev/null 2>&1
      test -s "$TARSRC/README.md" || exit 0
      # 组件目录映射表（basename 与 tarsrc 目录名不一致的例外；其余走 2a *xxx/；xxx 唯一不跨前缀多命中）
      case "$comp" in
        gsm)       TARSRC_COMP="$TARSRC/v-sysmonitor" ;;  # sysmonitor TARGETPATH=/usr/local/static/gsm
        dbus-glib) TARSRC_COMP="$TARSRC/x-dbus" ;;         # dbus-glib 包在 x-dbus/ 下
        *)         TARSRC_COMP=$(ls -d "$TARSRC"/*"$comp"/ 2>/dev/null | head -1) ;;
      esac
      _ms=$(( $(_now_ms)-_t0 ))
      if test -n "$TARSRC_COMP" && test -s "$TARSRC_COMP/$file"; then
        cp "$TARSRC_COMP/$file" "$CACHE/$file"
        cachesrc_log downcatfile "$comp" "$file" "$(stat -c%s "$CACHE/$file")B" tarsrc "$ver" "$url" "$_ms" "$TARSRC_COMP/$file"
        exit 0
      elif test -n "$TARSRC_COMP"; then
        hit=$(ls "$TARSRC_COMP"/*"$ver"* 2>/dev/null | head -1)
        test -n "$hit" && { cp "$hit" "$CACHE/$file"; cachesrc_log downcatfile "$comp" "$file" "$(stat -c%s "$CACHE/$file")B" tarsrc "$ver" "$url" "$_ms" "$hit"; exit 0; }
      fi
      hit=$(find "$TARSRC" -name "$file" -type f 2>/dev/null | head -1)
      test -n "$hit" && { cp "$hit" "$CACHE/$file"; cachesrc_log downcatfile "$comp" "$file" "$(stat -c%s "$CACHE/$file")B" tarsrc "$ver" "$url" "$_ms" "$hit"; }
    ) >/dev/null 2>&1 || true
  fi
  # ② 无则源头下载（tarsrc 命中后 CACHE 已有则不 curl；_curl_ran 区分真 curl 以记日志）
  _curl_ran=0
  test -s $CACHE/$file || { curl -# -k -fSL $url > $CACHE/$file; _curl_ran=1; }
  _ms=$(( $(_now_ms)-_t0 ))
  if test $_curl_ran -eq 1; then
    if test -s "$CACHE/$file"; then
      cachesrc_log downcatfile "$comp" "$file" "$(stat -c%s "$CACHE/$file")B" net "$ver" "$url" "$_ms" "$CACHE/$file"
    else
      cachesrc_log downcatfile "$comp" "$file" 0B net-fail "$ver" "$url" "$_ms" "$CACHE/$file"
    fi
  fi
  cat $CACHE/$file
}
# cachesrc_log: gitclone/down_catfile 缓存与下载明细日志（用户 2026-11-14）——增量追加 /usr/local/static/.logs/cachesrc/<文件名>.log，每次调用一行。
# 格式（2026-11-14 用户：加表头每列标注、第5列 CACHE/MISS/FAIL、耗时第6列 xxxms）:
#   时间|组件|包|大小|缓存命中|耗时|来源|ver|url|路径
#   缓存命中: CACHE(命中,gitcache/tarsrc) | MISS(网络下载 net) | FAIL(网络失败 net-fail)；来源=原标识 gitcache|tarsrc|net|net-fail（保留细节）
#   耗时=真实毫秒(带 ms 后缀)；字段由调用方传 8 参：组件|包|大小|hit|ver|url|耗时ms|路径（内部重排+转换）。
# 调用: cachesrc_log <文件名> <组件> <包> <大小> <hit> <ver> <url> <耗时ms> <路径>  增量>>追加不清空；首行写表头；同目录不同文件（gitclone / downcatfile 各一）。
cachesrc_log(){
  _clog=/usr/local/static/.logs/cachesrc/$1.log
  shift
  _ts=$(date '+%Y-%m-%d %H:%M:%S')
  _c=$1; _p=$2; _s=$3; _h=$4; _v=$5; _u=$6; _m=$7; _d=$8
  mkdir -p "$(dirname "$_clog")" 2>/dev/null || true
  # 表头（首行，2026-11-15 加强：顶行非表头即补——原"文件为空才写"遇 CI 烘焙层已含旧格式数据行且无表头时不生效）
  _hd='时间|组件|包|ver|大小|缓存命中|耗时|来源|url|路径'
  if test -s "$_clog"; then
    test "$(head -1 "$_clog")" = "$_hd" || { { echo "$_hd"; cat "$_clog"; } > "$_clog.tmp" && mv "$_clog.tmp" "$_clog"; }
  else
    echo "$_hd" > "$_clog"
  fi
  # 缓存命中列：统一 CACHE/MISS/FAIL 直观状态；来源列保留原标识细节
  case "$_h" in
    gitcache|tarsrc) _st=CACHE ;;
    net)             _st=MISS ;;
    net-fail)        _st=FAIL ;;
    *)               _st="$_h" ;;
  esac
  echo "$_ts|$_c|$_p|$_v|$_s|$_st|${_m}ms|$_h|$_u|$_d" >> "$_clog"
}
# _now_ms: 单调时钟毫秒（/proc/uptime 秒.小数*1000；busybox date 无 %N 故不用 date，保证快速命中耗时也真实记录）
_now_ms(){ awk '{printf "%d",$1*1000}' /proc/uptime 2>/dev/null || echo 0; }
# gitclone: 优先本地缓存 clone（tarsrc-git，宿主预克隆 gitee 仓库）；未命中回落网络 clone（不换源）。
# 命中时 cp 保留 .git（xcbutil 等需 git submodule update --init）；submodule 本身的本地缓存由调用方 sed 指向。
# 2026-11-13: 解决 CI gitee clone 抖动（Connection reset / 慢）致 b_deps 依赖未就位。
# 2026-11-13: ②tar.gz 快照缓存（TARSRC/_cache_repo/，针对 gh/gitee 网络抖动）——网络 clone 成功打 <comp>-<repo>-<ver>.tar.gz（只存不推，用户手动推 tarsrc）；
#   克隆前检查快照已有则解压复用跳过 clone；ver=--branch 值（去 --branch=），无则 default。优先级 GITCACHE(含.git) > tar.gz 快照 > 网络 clone。
# 2026-11-14: 快照只打 .git（docs 5.5）——shallow clone 的 .git 已是 zlib 压缩对象、工作树是未压缩原始文件，整目录打包≈存两份；
#   只打 .git 省 ~50%。解包后 .git 直接落 $_dir（与包内目录名解耦，修掉 5.2 的解包路径错配），再 git checkout -f 恢复工作树。
# 2026-11-14: 包名加组件前缀 _comp（归类标识）——按 TARGETPATH basename 匹配 /src 下 *xxx/ 组件目录（参考 down_catfile TARSRC 匹配），
#   case 映射处理 basename 与目录名不一致（gsm→v-sysmonitor、dbus-glib→x-dbus）；TARGETPATH 空则 default。
# safe.directory 全局 '*'（免仓库粒度逐个登记，容器内可信；git>=2.35.2 支持通配）。
# 调用: gitclone <url> <dir> [branch]   branch 为空="" 则默认分支。
gitclone() {
  _url=$1; _dir=$2; _br=${3:-}
  _t0=$(_now_ms)
  _repo=${_url##*/}
  _ver=${_br#--branch=}; test -n "$_ver" || _ver=default
  # 组件前缀（2026-11-14）：TARGETPATH basename → /src 下 *xxx/ 目录（如 tint2→w-tint2）；case 映射复用 down_catfile；TARGETPATH 空→default
  # 2026-11-15: 脚本路径组件名优先（同 down_catfile——TARGETPATH 常为 common 默认 temp1 无意义）；非 build.sh 调用者回落 TARGETPATH basename+find。
  # 包名 <comp>.<repo>-<ver>.tar.gz（comp 与 repo 用点连接，repo-ver 用 -，边界清晰）
  _comp=""
  _comp=$(echo "$0" | sed -n 's#.*/\([^/]*\)/build\.sh$#\1#p')
  test -n "$_comp" && {
    case "$_comp" in
      gsm)       _comp=v-sysmonitor ;;
      dbus-glib) _comp=x-dbus ;;
    esac
  }
  test -n "$_comp" || {
    test -n "$TARGETPATH" && {
      _comp=$(basename "$TARGETPATH")
      case "$_comp" in
        gsm)       _comp=v-sysmonitor ;;
        dbus-glib) _comp=x-dbus ;;
        *)         _comp=$(find "$(readlink -f /src 2>/dev/null)" -maxdepth 1 -type d -name "*$_comp" 2>/dev/null | head -1 | sed 's|.*/||') ;;
      esac
    }
  }
  test -n "$_comp" || _comp=default
  _gz=${TARSRC:-/src/../tarsrc}/_cache_repo/$_comp.$_repo-$_ver.tar.gz
  _cache=${GITCACHE:-/src/../tarsrc-git}/$_repo
  if test -d "$_cache/.git"; then
    rm -rf "$_dir"; cp -a "$_cache" "$_dir"
    # 缓存 .git owner 是宿主 uid, 容器 root 跑 git 会报 dubious ownership (feh 曾中招) → 全局登记豁免
    git config --global --add safe.directory '*' 2>/dev/null || true
    _ms=$(( $(_now_ms)-_t0 )); _size=$(du -sk "$_dir" 2>/dev/null | cut -f1)K
    cachesrc_log gitclone "$_comp" "$_comp.$_repo-$_ver.tar.gz" "$_size" gitcache "$_ver" "$_url" "$_ms" "$_dir"
    log "gitclone cached: $_repo"
    return 0
  fi
  # ②tar.gz 快照复用（2026-11-14 起包内仅 .git；解包到 $_dir 后 checkout 恢复工作树）
  if test -s "$_gz"; then
    rm -rf "$_dir"; mkdir -p "$_dir"
    tar xzf "$_gz" -C "$_dir" 2>/dev/null || { log "gitclone snapshot extract fail: $_gz"; return 1; }
    # 包内顶层必须是 .git（旧整目录快照顶层是 cache_repo_tmp_$$，解包错配 → 显式失败不吞）
    test -d "$_dir/.git" || { log "gitclone snapshot not .git-only (legacy?): $_gz"; return 1; }
    git config --global --add safe.directory '*' 2>/dev/null || true
    git -C "$_dir" checkout -f >/dev/null 2>&1 || { log "gitclone snapshot checkout fail: $_gz"; return 1; }
    _ms=$(( $(_now_ms)-_t0 )); _size=$(stat -c%s "$_gz" 2>/dev/null)B
    cachesrc_log gitclone "$_comp" "$_comp.$_repo-$_ver.tar.gz" "$_size" tarsrc "$_ver" "$_url" "$_ms" "$_dir"
    log "gitclone tar.gz hit: $_comp.$_repo-$_ver"
    return 0
  fi
  # ③网络 clone（未命中，不换源）
  _clone_rc=0
  if test -n "$_br"; then git clone --depth=1 "$_br" "$_url" "$_dir" || _clone_rc=$?
  else git clone --depth=1 "$_url" "$_dir" || _clone_rc=$?; fi
  _ms=$(( $(_now_ms)-_t0 ))
  # 克隆成功后打 tar.gz 快照（2026-11-14 起仅 .git，docs 5.5；只存不推，用户手动推送 tarsrc）
  if test -d "$_dir/.git"; then
    mkdir -p "$(dirname "$_gz")"
    tar czf "$_gz" -C "$_dir" .git
    _size=$(stat -c%s "$_gz" 2>/dev/null)B
    cachesrc_log gitclone "$_comp" "$_comp.$_repo-$_ver.tar.gz" "$_size" net "$_ver" "$_url" "$_ms" "$_dir"
  else
    cachesrc_log gitclone "$_comp" "$_comp.$_repo-$_ver.tar.gz" 0B net-fail "$_ver" "$_url" "$_ms" "$_dir"
  fi
  test $_clone_rc -eq 0 || return $_clone_rc
}
function print_time_cost(){
    local item_name=$1
    local begin_time=$2
	gawk 'BEGIN{
		print "['$item_name']本操作从" strftime("%Y年%m月%d日%H:%M:%S",'$begin_time'),"开始 ,",
		strftime("到%Y年%m月%d日%H:%M:%S",systime()) ,"结束,",
		" 共历时" systime()-'$begin_time' "秒";
	}' 2>&1 | tee -a $logfile
}
function log {
    echo -e "\n\n>>> $*"
}


# export CC=clang
# export CXX=clang++
# 通过$1, 调用各xx/build.sh内对应的: imlib2, xlunch等方法块;
function oneBuild(){
    LOGS=$TARGETPATH/../.logs; mkdir -p $LOGS
    # $1 |tee $LOGS/$1.log
    # env |sort #view
    echo -e "\n$1, start building.."
    begin_time="`gawk 'BEGIN{print systime()}'`"; export logfile=$LOGS/oneBuild-$1.log
    test "yes" == "$CONSOLE_LOG" && echo CONSOLE_LOG=yes || echo CONSOLE_LOG=no
    # 2026-11-12 方案A: 复用 doExec 拿精确 rc + 白名单实时回显 + 分层日志($LOGS/doExec/<caller>/)。
    # doExec 内部 ( set +e; $1; ... ) 保方法块失败继续跑完(行为与旧版一致, 非 set -e 即停);
    # 保留 oneBuild 的产物清单(find TARGETPATH) + err/pass 判定 + 耗时; 失败 tail doExec 实际日志。
    doExec "$1"
    local rc=$?
    echo -e "\nTARGETPATH=$TARGETPATH"; find ${TARGETPATH} -type f |grep -E "/bin|/sbin" |sort |head -3;
    if [ "$rc" != 0 ]; then
        echo "err $rc, fail"; tail -200 "${DOEXEC_LOG:-$logfile}" || true
    else
        echo "err 0, pass"
    fi
    print_time_cost "$1" $begin_time || true
    return $rc
}

# doExec: 通用命令执行包装——全量落日志 + 白名单实时回显 + 错误码记录(供并发 wait 后检查)。
# 与旧版差异: ① 去 bash 专属 >(tee|grep) 进程替换, 改标准管道保实时回显(POSIX);
#   ② rc 用临时文件精确捕获(原 "$?" 取进程替换/管道尾部, 吞错); ③ 过滤改正向白名单(原 warn|error 被重复编译器警告淹没)。
# 调用: doExec <cmd> [args...]   返回: 命令退出码(非并发调用方 set -e 自动捕获失败).
# 结果记录: $LOGS/doExec/<caller>/_exec_result.txt 每行 "rc|cmd args" (只增不清->留痕; doExec_mark 写组边界, wait 后 doExec_check 只读本组).
# caller=脚本调入口名(${DOEXEC_CALLER:-default}, 继承不覆盖): u-gtk 调 openbox 时 openbox 内 doExec 也落 $LOGS/doExec/u-gtk/.
# 2026-11-11 从 u-gtk/build.sh 上移 common.sh（公共执行包装，u-gtk/u-gtkmm 等并发/构建脚本共用）。
function doExec(){
  local cmd=$1; shift
  local args=$@
  local caller=${DOEXEC_CALLER:-default}
  # 2026-11-13: 日志从 /tmp/doExec 并入 .logs(=TARGETPATH/../.logs)，构建后仍保留(否则失败组件日志丢失，见文档五章1.6)
  : ${TARGETPATH:=/tmp}
  LOGS=${LOGS:-$TARGETPATH/../.logs}; mkdir -p $LOGS
  local elog=$LOGS/doExec/$caller; mkdir -p $elog
  [ -f "$cmd" ] && cmd="bash $cmd"
  local lf=$elog/$(printf '%s' "$cmd $args" | sed 's/[^A-Za-z0-9_.-]/_/g; s/__*/_/g; s/^_//; s/_$//' | cut -c1-120).log
  export DOEXEC_LOG=$lf   # 供 oneBuild 失败 tail 到本 doExec 实际日志
  local rcfile=$(mktemp $elog/.rc.XXXXXX)
  # 实时: 子 shell 输出流经 tee(全量落日志) + 白名单 grep(高信号行回显); rcfile 捕获 $cmd 真实退出码.
  ( set +e; $cmd $args; echo $? > $rcfile ) 2>&1 | tee -a "$lf" \
    | grep -E "ERROR:|fatal|error:|Error ?[0-9]|undefined reference|No such file|No rule|can't stat|MISSING|FAILED|>>> |start building|err [0-9]+, (pass|fail)|本操作|OK: [0-9]+ MiB|TARGETPATH=" \
    | grep -vE "perl-error|fail_on_|--add-missing|-Werror|pixbuf-fail|\[[0-9]+/[0-9]+\] (Compiling|Generating|Linking)" || true
  local rc=$(cat $rcfile 2>/dev/null); rm -f $rcfile
  [ -z "$rc" ] && rc=1   # $cmd 内显式 exit 时 rcfile 未写 -> 视为失败
  echo "$rc|$cmd $args" >> "$elog/_exec_result.txt"
  [ "$rc" != 0 ] && echo "== doExec FAIL: $cmd $args (rc=$rc) =="
  return $rc
}

# doExec_mark: 写并发组边界标记（结果文件只增不清 -> 留痕；MARK 之后为本组记录）。
function doExec_mark(){
  : ${TARGETPATH:=/tmp}
  LOGS=${LOGS:-$TARGETPATH/../.logs}; mkdir -p $LOGS/doExec/${DOEXEC_CALLER:-default}
  echo "# MARK $*" >> $LOGS/doExec/${DOEXEC_CALLER:-default}/_exec_result.txt
}

# doExec_check: 并发组 wait 后检查 $LOGS/doExec/_exec_result.txt, 任一 rc!=0 则报错返回 1(调用方 || exit 1).
# 精准识别: 只读最后一个 # MARK 行之后的记录（前组留痕不清、不误判当前组）。
function doExec_check(){
  : ${TARGETPATH:=/tmp}
  LOGS=${LOGS:-$TARGETPATH/../.logs}; mkdir -p $LOGS
  local f=$LOGS/doExec/${DOEXEC_CALLER:-default}/_exec_result.txt
  [ -f "$f" ] || return 0
  local start=$(grep -n '^# MARK ' "$f" | tail -1 | cut -d: -f1)
  [ -z "$start" ] && start=0
  local fail=0 rc cmd idx=0
  while IFS='|' read -r rc cmd; do
    idx=$((idx+1))
    [ $idx -le $start ] && continue
    [ -z "$rc" ] && continue
    if [ "$rc" != 0 ]; then
      echo "== doExec FAILED: $cmd (rc=$rc) =="
      fail=1
    fi
  done < "$f"
  return $fail
}

# ensure_gtk_libs: 判 gtk2 静态库（u-gtk 产物）是否最新，非最新则调 u-gtk 重编 .a。
# 最新判据：/src/u-gtk/*.patch 内容 hash 组合 vs 记录 /usr/local/static/.gtk-state/gtk.sha。
# base 镜像（builder-gtk224）若已含最新 u-gtk 库+记录则跳过；否则（patch 变更/记录缺失/库缺失）重编。
# 用途：各 GTK2 应用 b_deps 先调用，确保静态链到最新 gtk2 库（2026-11-08，user 拍板）。
function ensure_gtk_libs(){
  local ST=/usr/local/static/.gtk-state
  local P=/src/u-gtk
  local CUR PREV
  CUR=$(sha256sum $P/*.patch 2>/dev/null | sha256sum | cut -d' ' -f1)
  [ -n "$CUR" ] || { log "ensure_gtk_libs: no patches in $P, skip"; return 0; }
  PREV=$(cat $ST/gtk.sha 2>/dev/null || true)
  if [ "$PREV" = "$CUR" ] && [ -f /usr/lib/libgtk-x11-2.0.a ]; then
    log "ensure_gtk_libs: gtk2 libs latest, skip"
    return 0
  fi
  log "ensure_gtk_libs: gtk2 libs NOT latest -> rebuild via u-gtk"
  sh /src/u-gtk/build.sh gtk || { log "ensure_gtk_libs: u-gtk rebuild FAILED"; exit 1; }
  mkdir -p $ST; echo "$CUR" > $ST/gtk.sha
  log "ensure_gtk_libs: gtk2 rebuilt, marker updated"
}

# XX_X11_PKGS: X11 静态库/头的公共最小集（2026-11-25，方案二交叉共享清单）。
# 背景：xx-cross 下交叉 sysroot 由 xx-apk 现建，只含显式装的包；native amd64 靠 gtk224 镜像烘焙的 X11，
#   交叉 sysroot 无 → 凡链 X11 的组件都需先补装（xdpyprobe CI 首踩：X11/Xlib.h file not found）。
# 用法：xx-apk add $XX_X11_PKGS [<本组件额外包>]；native 已装 → 幂等零影响。
#   libx11 的 .a 在 libx11-static；xcb/xau/xdmcp 的 .a 在各自 -dev（无 -static 变体）；xorgproto 作依赖自动拉。
#   需额外扩展（xext/xrender/xcomposite/xfixes/xrandr/xdamage…）的组件在此基线后追加。
export XX_X11_PKGS="libx11-dev libx11-static libxcb-dev libxcb-static libxau-dev libxdmcp-dev"

# xx_cross_init: 交叉编译初始化（2026-11-24，方案二）。
# is-cross=true（编译 stage 在 build 平台跑、TARGETPLATFORM 指 target）时：生成 meson cross-file +
#   导出 XX_SYSROOT/XX_CROSS_FILE/XX_TRIPLE/XX_MARCH，供 build.sh 交叉（meson --cross-file、.a 落 sysroot）。
# is-cross=false（native/qemu/未设 TARGETPLATFORM）：变量留空 → build.sh 走原路径（旧构建模式不变）。
# 兼容：xx-info 不存在 或 is-cross 非 0 → 直接 return（native 原路径，零影响）。
# 判据=执行 arch(uname -m) vs target arch（xx-info is-cross）——非 BUILDPLATFORM!=TARGETPLATFORM（qemu 下后者恒真会误判）。
# cross-file 要点：pkgconfig key 无连字符；cpu_family 用 march(aarch64 非 arm64)；sys_root 使 meson 设 PKG_CONFIG_SYSROOT_DIR。
xx_cross_init(){
  command -v xx-info >/dev/null 2>&1 || return 0
  xx-info is-cross >/dev/null 2>&1 || return 0
  export XX_SYSROOT=$(xx-info sysroot)
  export XX_TRIPLE=$(xx-info triple)
  export XX_MARCH=$(xx-info march)
  export XX_CROSS_FILE=/tmp/xx-cross-${XX_MARCH}.ini
  cat > "$XX_CROSS_FILE" <<EOF
[binaries]
c = '/usr/bin/xx-clang'
cpp = '/usr/bin/xx-clang++'
ar = 'ar'
pkgconfig = '/usr/bin/pkg-config'

[properties]
needs_exe_wrapper = true
sys_root = '$XX_SYSROOT'
pkg_config_libdir = '$XX_SYSROOT/usr/lib/pkgconfig:$XX_SYSROOT/usr/local/lib/pkgconfig:$XX_SYSROOT/usr/share/pkgconfig'

[host_machine]
system = 'linux'
cpu_family = '$XX_MARCH'
cpu = '$XX_MARCH'
endian = 'little'
EOF
  log "xx_cross_init: CROSS -> $XX_TRIPLE (sysroot=$XX_SYSROOT cross-file=$XX_CROSS_FILE)"
}

# xx_meson_crossfix: meson 交叉 native 依赖头泄漏修复（2026-11-24，方案二 armv7 gdk_pixbuf 阻塞根因）。
# meson 0.59 交叉会把 BUILD 机(native pkg-config) 与 HOST 机(sysroot) 的依赖 cflags 合并进 host 目标编译命令，
# native -I/usr/include(glibconfig.h 等 LP64 头) 在前 → ILP32(armv7) 下 sizeof 断言失败；LP64(arm64) 掩盖。
# 交叉构建所有目标本就该用 sysroot 头 → meson 后把 build.ninja 的 native /usr(/usr/local) -I/-L 重映射到 sysroot。
# 用法: xx_meson_crossfix <builddir>（仅 is-cross 时生效；native 原路径不处理零影响）。
xx_meson_crossfix(){
  [ -n "$XX_CROSS_FILE" ] || return 0
  local bd="$1" f="$1/build.ninja" S="${XX_SYSROOT%/}"
  test -f "$f" || { log "xx_meson_crossfix: no $f"; return 0; }
  sed -i "s|-I/usr/local/|-I$S/usr/local/|g; s|-I/usr/|-I$S/usr/|g; s|-L/usr/local/|-L$S/usr/local/|g; s|-L/usr/|-L$S/usr/|g" "$f"
  log "xx_meson_crossfix: remapped native /usr -> $S in $f"
}

# xx_la_fix: 交叉 .la libdir/dependency_libs 修复（2026-11-24 方案二 pangomm 交叉阻塞根因；
# 2026-11-25 补 dependency_libs——gdkmm/gtkmm generate_extra_defs 找不到 /usr/lib/libglibmm-2.4.la 根因）。
# `make install DESTDIR=$XX_SYSROOT` 会把 .la 的 libdir 写成目标绝对路径(/usr/lib)，
# 下游按名 -lfoo 时 libtool 读到 libdir=/usr/lib → 解析到 native(错架构) 的 .a → "file in wrong format"。
# 修复①：把 sysroot 里 .la 的 libdir 改为 sysroot 相对路径（$XX_SYSROOT/usr/lib、/usr/local/lib）。
# 修复②（2026-11-25）：dependency_libs 里对兄弟 .la 的引用可能仍是 native 绝对路径
#   （实测 libgiomm-2.4.la 带 /usr/lib/libglibmm-2.4.la、librsvg-2.la 带 /usr/local/lib/libcroco-0.6.la）。
#   libtool 对 dependency_libs 的裸 .la 绝对路径按字面解析（不走 -L），找不到即
#   "cannot find the library '/usr/lib/xxx.la'" → 重写成 sysroot 前缀。已 sysroot 化的先保护防重复加前缀。
# 用法: xx_la_fix（仅 is-cross 时生效；native 零影响）。每次 make install 后调用。
xx_la_fix(){
  [ -n "$XX_CROSS_FILE" ] || return 0
  local S="${XX_SYSROOT%/}"
  local n=0
  for f in "$S"/usr/lib/*.la "$S"/usr/local/lib/*.la; do
    [ -f "$f" ] || continue
    local d="$S/usr/lib"; case "$f" in *"/usr/local/"*) d="$S/usr/local/lib";; esac
    sed -i "s|^libdir=.*|libdir='$d'|" "$f"
    # 修复②: 裸 /usr(/lib|/local/lib) -> sysroot 前缀; 先保护已 sysroot 的 $S/usr 防双前缀
    sed -i "s|$S/usr|@XX_SYSROOT_USR@|g; s|/usr|$S/usr|g; s|@XX_SYSROOT_USR@|$S/usr|g" "$f"
    n=$((n+1))
  done
  log "xx_la_fix: $n .la libdir/dependency_libs -> sysroot 相对"
}
xx_cross_init
