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
# gitclone: 优先本地缓存 clone（tarsrc-git，宿主预克隆 gitee 仓库）；未命中回落网络 clone（不换源）。
# 命中时 cp 保留 .git（xcbutil 等需 git submodule update --init）；submodule 本身的本地缓存由调用方 sed 指向。
# 2026-11-13: 解决 CI gitee clone 抖动（Connection reset / 慢）致 b_deps 依赖未就位。
# 2026-11-13: ②tar.gz 快照缓存（TARSRC/_cache_repo/，针对 gh/gitee 网络抖动）——网络 clone 成功打 <repo>-<ver>.tar.gz（含.git，只存不推，用户手动推 tarsrc）；
#   克隆前检查快照已有则解压复用跳过 clone；ver=--branch 值（去 --branch=），无则 default。优先级 GITCACHE(含.git) > tar.gz 快照 > 网络 clone。
# safe.directory 全局 '*'（免仓库粒度逐个登记，容器内可信；git>=2.35.2 支持通配）。
# 调用: gitclone <url> <dir> [branch]   branch 为空="" 则默认分支。
gitclone() {
  _url=$1; _dir=$2; _br=${3:-}
  _repo=${_url##*/}
  _ver=${_br#--branch=}; test -n "$_ver" || _ver=default
  _gz=${TARSRC:-/src/../tarsrc}/_cache_repo/$_repo-$_ver.tar.gz
  _cache=${GITCACHE:-/src/../tarsrc-git}/$_repo
  if test -d "$_cache/.git"; then
    rm -rf "$_dir"; cp -a "$_cache" "$_dir"
    # 缓存 .git owner 是宿主 uid, 容器 root 跑 git 会报 dubious ownership (feh 曾中招) → 全局登记豁免
    git config --global --add safe.directory '*' 2>/dev/null || true
    log "gitclone cached: $_repo"
    return 0
  fi
  # ②tar.gz 快照复用（解压，含 .git；克隆前检查已有则跳过 clone）
  if test -s "$_gz"; then
    rm -rf "$_dir"; mkdir -p "$(dirname "$_dir")"
    tar xzf "$_gz" -C "$(dirname "$_dir")"
    git config --global --add safe.directory '*' 2>/dev/null || true
    log "gitclone tar.gz hit: $_repo-$_ver"
    return 0
  fi
  # ③网络 clone（未命中，不换源）
  if test -n "$_br"; then git clone --depth=1 "$_br" "$_url" "$_dir"
  else git clone --depth=1 "$_url" "$_dir"; fi
  # 克隆成功后打 tar.gz 快照（含.git；只存不推，用户手动推送 tarsrc）
  test -d "$_dir/.git" && {
    mkdir -p "$(dirname "$_gz")"
    tar czf "$_gz" -C "$(dirname "$_dir")" "$(basename "$_dir")"
  }
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
    echo -e "\nTARGETPATH=$TARGETPATH"; find $TARGETPATH -type f |sort
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
