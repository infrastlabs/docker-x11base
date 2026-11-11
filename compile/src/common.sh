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
test -z "$TARGETPATH" && export TARGETPATH=/usr/local/static_temp1 #/opt/base
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
  #curl -# -L -f ; -f > -s
  test -s $CACHE/$file || curl -# -k -fSL $url > $CACHE/$file
  cat $CACHE/$file
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
    # 2026-11-11 修正吞错: 原 "$1 |tee $logfile" 管道退出码取 tee 的(0) 非 $1 的;
    # 且原 "$?" 取的是 find|sort 的(0), 恒报 "err 0, pass"。改用临时文件捕获 $1 真实退出码。
    # 子 shell 内 set +e 保 $1 失败继续(行为不变); rcfile 捕获 $1 真实退出码(非管道 tee 的 0)。
    # return $rc 让调用方 set -e 捕获; 管道 || true 防 find 无结果/tail 无内容时 set -e 误触发。
    local rcfile=$(mktemp $LOGS/.rc.XXXXXX)
    if [ "yes" = "$CONSOLE_LOG" ]; then
        ( set +e; $1; echo $? > $rcfile ) 2>&1 | tee $logfile || true
    else
        ( set +e; $1; echo $? > $rcfile ) > $logfile 2>&1 || true
    fi
    local rc=$(cat $rcfile 2>/dev/null); rm -f $rcfile
    [ -z "$rc" ] && rc=1
    echo -e "\nTARGETPATH=$TARGETPATH"; find $TARGETPATH -type f |sort
    if [ "$rc" != 0 ]; then
        echo "err $rc, fail"; tail -200 $logfile || true
    else
        echo "err 0, pass"
    fi
    print_time_cost "$1" $begin_time || true
    return $rc
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
