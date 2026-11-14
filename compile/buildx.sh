


source /etc/profile
export |grep DOCKER_REG |grep -Ev "PASS|PW"
repo=registry.cn-shenzhen.aliyuncs.com
echo "${DOCKER_REGISTRY_PW_infrastSubUser2}" |docker login --username=${DOCKER_REGISTRY_USER_infrastSubUser2} --password-stdin $repo
repoHub=docker.io
echo "${DOCKER_REGISTRY_PW_dockerhub}" |docker login --username=${DOCKER_REGISTRY_USER_dockerhub} --password-stdin $repoHub

# tarsrc 源码包仓库（gitee）：完整克隆（非 depth1，2026-11-14 用户拍板）到 compile/tarsrc/（=$(dirname $0)/tarsrc，与 down_catfile 默认 /src/../tarsrc 同址）。
# down_catfile（common.sh）会按需再 clone（幂等）；此处提前备好供容器 /src/../tarsrc 复用。
# 2026-11-14 优化：已有则 pull 非克隆（pull 同步 gitee 最新源码包 + _cache_repo/ 快照）；完整历史才能 ff-only pull，旧 shallow 先 unshallow 补全。
_TS=$(dirname "$0")/tarsrc
if test -d "$_TS/.git"; then
  test -f "$_TS/.git/shallow" && git -C "$_TS" fetch --unshallow 2>&1 | tail -1 || true
  git -C "$_TS" pull --ff-only 2>&1 | tail -1 || true
else
  git clone https://gitee.com/infrastlabs/x11base-tarsrc "$_TS" 2>&1 | tail -1 || true
fi

function build_rootfs(){
    dockerfile=/tmp/Dockefile.rootfs
    cat > $dockerfile<<EOF
FROM infrastlabs/x11-base:deb12-builder as compile
FROM alpine:3.15
COPY --link --from=compile /rootfs /rootfs
EOF
    repo=registry-1.docker.io
    img="x11-base:deb12-rootfs"
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    args="--provenance=false"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $plat $args --push -t $repo/$ns/$img -f $dockerfile . 
}

# cache_repo: 预下载 gitclone 依赖快照到 tarsrc/_cache_repo/——遍历 src/*/build.sh 的 gitclone 调用点，批量解析打 <comp>.<repo>-<ver>.tar.gz。
# comp=脚本目录名（如 w-tint2，按路径目录提前设置组件前缀，2026-11-14 用户拍板）。
# 解析：awk 提取 gitclone url/dir/branch 三参（合并 \ 续行、截断 || 尾随、去注释/引号）；VAR 用调用点前最后一次字面赋值 resolve（GITHUB 未定义默认 github.com）。
# 已有快照跳过；GITCACHE(tarsrc-git 含 .git) 优先 cp，否则网络 clone；产物只存不推（同 gitclone）。
cache_repo(){
  _TS=$(dirname "$0")/tarsrc
  _CR=$_TS/_cache_repo
  _GC=${GITCACHE:-$(dirname "$0")/tarsrc-git}
  _tmp=/tmp/cache_repo_tmp_$$
  _calls=/tmp/cache_repo_calls_$$
  mkdir -p "$_CR"
  _new=0; _skip=0; _fail=0
  for f in $(dirname "$0")/src/*/build.sh; do
    comp=$(basename "$(dirname "$f")")
    awk '
      /gitclone[ \t]/ {
        start=FNR; line=$0
        while (line ~ /\\$/) { line=substr(line,1,length(line)-1); if ((getline nl)>0) line=line nl }
        # 定位 gitclone（行首或 ; 后），取其后的 url/dir/branch 部分（兼容 rm -rf ...; gitclone 形态）
        if (match(line, /(^|[;])[[:space:]]*gitclone[[:space:]]+/)) {
          line=substr(line, RSTART+RLENGTH)
          sub(/[[:space:]]*\|\|.*$/, "", line)
          sub(/[[:space:]]*#.*$/, "", line)
          gsub(/["'"'"']/, "", line)
          n=split(line, a, /[[:space:]]+/)
          if (n>=1 && a[1]!="") print start "|" a[1] "|" (n>=2?a[2]:"") "|" (n>=3?a[3]:"")
        }
      }
    ' "$f" > "$_calls"
    while IFS='|' read -r _line _u _d _b; do
      test -n "$_u" || continue
      _url=$(cache_repo_resolve "$_u" "$f" "$_line") || { echo "  !! [$comp] url unresolved: $_u"; _fail=$((_fail+1)); continue; }
      _br=""
      test -n "$_b" && { _br=$(cache_repo_resolve "$_b" "$f" "$_line") || { echo "  !! [$comp] branch unresolved: $_b (ver=default)"; _br=""; }; }
      _repo=${_url##*/}
      _ver=${_br#--branch=}; test -n "$_ver" || _ver=default
      _gz=$_CR/$comp.$_repo-$_ver.tar.gz
      if test -s "$_gz"; then echo "  skip: $comp.$_repo-$_ver"; _skip=$((_skip+1)); continue; fi
      rm -rf "$_tmp"
      if test -d "$_GC/$_repo/.git"; then cp -a "$_GC/$_repo" "$_tmp"
      elif test -n "$_br"; then git clone --depth=1 "$_br" "$_url" "$_tmp" 2>&1 | tail -1
      else git clone --depth=1 "$_url" "$_tmp" 2>&1 | tail -1; fi
      if test -d "$_tmp/.git"; then
        tar czf "$_gz" -C "$_tmp" .git   # 2026-11-14 起仅 .git（docs 5.5）：包内顶层固定 .git，与临时目录名解耦；gitclone 解包后 checkout 恢复工作树
        echo "  new: $comp.$_repo-$_ver"; _new=$((_new+1))
      else echo "  !! [$comp] clone fail: $_url"; _fail=$((_fail+1)); fi
    done < "$_calls"
  done
  rm -rf "$_tmp" "$_calls"
  echo "cache_repo done: new=$_new skip=$_skip fail=$_fail  ($_CR)"
}

# cache_repo_resolve <str> <file> <line>：展开 str 内 $VAR（调用点 line 前最后一次字面赋值；GITHUB 未定义默认 github.com）；迭代直到无 $VAR。
cache_repo_resolve(){
  _s=$1; _file=$2; _line=$3
  for _i in 1 2 3 4 5; do
    _vars=$(printf '%s' "$_s" | grep -o '\$[A-Za-z_][A-Za-z0-9_]*' | sort -u)
    test -n "$_vars" || break
    for _v in $_vars; do
      _vn=${_v#\$}
      _vval=$(sed -n "1,${_line}p" "$_file" | grep -E "^[[:space:]]*(export[[:space:]]+)?${_vn}=" | tail -1 | sed "s/^[[:space:]]*//; s/^export[[:space:]]*//; s/^${_vn}=//; s/[[:space:]]*#.*\$//; s/^\"//; s/\"\$//; s/^'//; s/'\$//; s/^\${[A-Za-z_][A-Za-z0-9_]*:-\(.*\)}\$/\1/")
      test -n "$_vval" || { test "$_vn" = "GITHUB" && _vval=https://github.com; }
      test -n "$_vval" || _vval=$(printenv "$_vn" 2>/dev/null)
      test -n "$_vval" || { echo "__UNRESOLVED__$_vn__"; return 1; }
      _esc=$(printf '%s' "$_vval" | sed 's/[&|\\]/\\&/g')
      _s=$(printf '%s' "$_s" | sed "s|\$${_vn}|$_esc|g")
    done
  done
  test -n "$(printf '%s' "$_s" | grep '\$[A-Za-z_]')" && return 1
  echo "$_s"
}

ns=infrastlabs
ver=v51 #base-v5 base-v5-slim
case "$1" in
ubt-builder)
    repo=registry-1.docker.io
    img="x11-base:ubt-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/ubt/Dockerfile.builder . 
    ;;
deb12-builder)
    repo=registry-1.docker.io
    img="x11-base:deb12-builder"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm" #
    # plat="--platform linux/amd64"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    docker buildx build $cache $plat --push -t $repo/$ns/$img -f src/../builder/ubt/Dockerfile.deb12 . 
    test "0" == "$?" && build_rootfs || exit $err
    ;;
builder)
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-builder"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm"
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder . 
    ;;
gtk224)
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac REPO_TEN
    # repo=$REPO_TEN
    img="x11-base:alpine-builder-gtk224-2"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    plat="--platform linux/amd64" #dbg
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder.gtk224 . 
    ;;
gtkmm224) #gtk/gtkmm全串一起: 超过gitac.max:6h而fail!
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-builder-gtkmm224-2"
    args="""
    --provenance=false --sbom=false
    --build-arg REPO=$repo/
    """

    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    plat="--platform linux/amd64" #dbg
    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/../builder/Dockerfile.builder.gtkmm224 . 
    ;;
cache_repo) # 预下载 gitclone 依赖快照（遍历 src/*/build.sh 批量解析打包 _cache_repo/）
    cache_repo
    ;;
cache_tarsrc) # 预留：tarsrc 源码包仓库按需克隆/更新（暂未实现）
    echo "cache_tarsrc: 预留，暂未实现"
    ;;
*) #compile
    # TigerVNC 1.12.0 |10 Nov 2021
    # old=$(pwd); cd src/..
    #     # xrdp
    #     ver="0.9.16"
    #     file=xrdp-${ver}.tar.gz; test -s $file || curl -k -O -fSL https://github.com/neutrinolabs/xrdp/releases/download/v${ver}/$file
    #     # tiger
    #     file=xorg-server-1.20.7.tar.bz2; test -s $file || curl -k -O -fSL https://www.x.org/pub/individual/xserver/$file #6.1M
    #     file=tigervnc-1.12.0.tar.gz; test -s $file || curl -k -O -fSL https://github.com/TigerVNC/tigervnc/archive/v1.12.0/$file #1.5M
    #     # curl -O -fsSL https://www.linuxfromscratch.org/patches/blfs/svn/tigervnc-1.12.0-configuration_fixes-1.patch
    # cd $old;
    #  
    repo=registry-1.docker.io
    # repo=registry.cn-shenzhen.aliyuncs.com
    test ! -z "$REPO" && repo=$REPO #@gitac
    img="x11-base:alpine-compile-2"
    # cache
    ali="registry.cn-shenzhen.aliyuncs.com"
    cimg="$img-cache"
    
    plat="--platform linux/amd64,linux/arm64,linux/arm" #,linux/arm
    # plat="--platform linux/arm64" #pulse-arm-dbg
    plat="--platform linux/amd64" #dbg
    
    compile="alpine-compile-2"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && compile="${compile}-dbg"
    compile="alpine-compile" ########V2 TEST, AVOID DBG
    args="--provenance=false"
    # full yes x9: 5h,9min,44s
    # 11-04 后新增/调整项 CI 开关（默认不启用，需显式 --build-arg COMPILE_*=no/yes 才建）
    args="""
    --provenance=false 
    --build-arg REPO=$repo/
    --build-arg COMPILE_IMG=$compile
    --build-arg COMPILE_TIGER=no
    --build-arg COMPILE_XRDP=no
    --build-arg COMPILE_X11VNC=no
    --build-arg COMPILE_SSH=no
    --build-arg COMPILE_FLUX=no
    --build-arg COMPILE_OPENBOX=no
    --build-arg COMPILE_SUCKLESS=no
    --build-arg COMPILE_XCOMPMGR=no
    --build-arg COMPILE_PERP=no
    --build-arg COMPILE_MISC=no

    --build-arg COMPILE_HSETROOT=yes
    --build-arg COMPILE_SCROT=yes
    --build-arg COMPILE_TINT2=yes
    --build-arg COMPILE_FEH=yes
    --build-arg COMPILE_XLUNCH=yes

    --build-arg COMPILE_XBINDKEYS=no
    --build-arg COMPILE_XRANDR=yes
    --build-arg COMPILE_DUNST=yes
    --build-arg COMPILE_ROFI=no
    --build-arg COMPILE_PULSE=no
    --build-arg COMPILE_PASYSTRAY=no
    --build-arg COMPILE_PAVUCONTROL=no
    --build-arg COMPILE_SYSMONITOR=no
    
    --build-arg COMPILE_LXDE=yes
    --build-arg COMPILE_PCMANFM=no
    --build-arg COMPILE_XFCE4=no
    --build-arg COMPILE_GEANY=yes
    --build-arg COMPILE_ENGRAMPA=no
    --build-arg COMPILE_GPICVIEW=yes
    --build-arg COMPILE_DBUS=no
    --build-arg COMPILE_IBUS=no
    --build-arg BUILDDATE=$(date +%Y-%m-%d_%H:%M:%S)
    """
    # --network=host: docker buildx create --use --name mybuilder2 --buildkitd-flags '--allow-insecure-entitlement network.host'
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && img="${img}-dbg"
    test "$plat" != "--platform linux/amd64,linux/arm64,linux/arm" && cimg="${cimg}-dbg"
    # cache="--cache-from type=registry,ref=$ali/$ns/$cimg --cache-to type=registry,ref=$ali/$ns/$cimg"
    ali2=$REPO_TEN_HK
    cache="--cache-from type=registry,ref=$ali2/$ns/$cimg"
    cache="$cache --cache-to type=registry,ref=$ali2/$ns/$cimg,mode=max"

    output="--output type=image,name=$repo/$ns/$img,push=true,oci-mediatypes=true,annotation.author=sam"
    docker buildx build $cache $plat $args $output -f src/Dockerfile . 
    # err=$?
    # test "0" == "$err" && build_rootfs || exit $err
    ;;          
esac