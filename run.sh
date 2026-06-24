#!/bin/sh
# run.sh — tmux-config-sync 的单一入口。可 curl|sh 一把梭,自动拉取所需脚本,零残留。
#          (取代旧 install.sh:安装功能并入 `--install`。)
#
# 用法:
#   # 一把梭(自动把 tmux-pack/tmux-restore 拉到临时目录,跑完即删):
#   curl -fsSL <RAW>/run.sh | sh -s -- pack    [OUTDIR] [更多参数...]   # 别名 p
#   curl -fsSL <RAW>/run.sh | sh -s -- restore <包>     [更多参数...]   # 别名 r
#   # 把命令装到 ~/bin 长期用(等价旧 install.sh):
#   curl -fsSL <RAW>/run.sh | sh -s -- --install [--bindir DIR]
#   # 在仓库内本地直跑(自动用同目录 tools/,不联网):
#   ./run.sh pack .
#
#   两个常用操作:
#     1) pack     打包当前 tmux 环境。不带 OUTDIR 默认当前目录;
#                 不带 --name 默认包名 tmux-config-sync-<时间戳>。
#     2) restore  还原一个 bundle(.tar.gz/.tgz 或解开的目录)。
#   附:--install  仅安装 tmux-pack/tmux-restore 到 ~/bin(--bindir 改目录)。
#
#   pack/restore 的完整参数见各自 `-h`:  ./run.sh pack -h   /   ./run.sh restore -h
#
# 换拉取源(自建/内网镜像):
#   TMUX_TOOLS_RAW_BASE=https://你的镜像/tools  curl -fsSL .../run.sh | sh -s -- pack .
#
# 仅支持 Linux(GNU coreutils)。联网拉取需要 curl 或 wget;本地 tools/ 模式无需联网。
set -eu

PROG=run.sh
RAW_BASE=${TMUX_TOOLS_RAW_BASE:-https://raw.githubusercontent.com/ccwq/tmux-config-sync/master/tools}

usage() { sed -n '2,/^set -eu/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }
die()   { printf '%s: 错误: %s\n' "$PROG" "$*" >&2; exit 1; }

# 下载器:curl 优先,其次 wget;都没有则调用时报错(本地模式不会触发)。
dl() { die "需要 curl 或 wget(用于自动拉取脚本)"; }
if command -v curl >/dev/null 2>&1; then
  dl() { curl -fsSL -o "$2" -- "$1"; }
elif command -v wget >/dev/null 2>&1; then
  dl() { wget -q -O "$2" -- "$1"; }
fi

# 脚本来源:优先本地同目录 tools/(仓库内直跑);否则后面按需远程拉到临时目录。
SELFDIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || echo "")
TOOLS=""
TMPDL=""
if [ -n "$SELFDIR" ] && [ -f "$SELFDIR/tools/tmux-pack" ] && [ -f "$SELFDIR/tools/tmux-restore" ]; then
  TOOLS="$SELFDIR/tools"
fi

# 确保 $TOOLS 可用;本地缺失时拉到临时目录(两个脚本都拉,使 pack 产出的 bundle 自带 restore)。
ensure_tools() {
  [ -n "$TOOLS" ] && return 0
  case "$RAW_BASE" in
    *OWNER/REPO*) die "RAW_BASE 是占位符,请设 TMUX_TOOLS_RAW_BASE 环境变量。" ;;
  esac
  TMPDL=$(mktemp -d "${TMPDIR:-/tmp}/tmuxrun.XXXXXX") || die "mktemp 失败"
  trap 'rm -rf "$TMPDL"' EXIT INT TERM
  for c in tmux-pack tmux-restore; do
    printf '拉取 %s ...\n' "$c" >&2
    dl "$RAW_BASE/$c" "$TMPDL/$c" || die "下载失败: $RAW_BASE/$c"
    chmod +x "$TMPDL/$c"
  done
  TOOLS="$TMPDL"
}

# 跑某个工具,参数原样透传。
#   本地模式:exec 直接替换进程。
#   临时下载模式:必须以子进程运行(跑完要靠 trap 清理临时目录,exec 会让 trap 失效)。
run_tool() {
  tool=$1; shift
  ensure_tools
  [ -f "$TOOLS/$tool" ] || die "未找到 $TOOLS/$tool"
  if [ -z "$TMPDL" ]; then
    if [ -x "$TOOLS/$tool" ]; then exec "$TOOLS/$tool" "$@"; else exec sh "$TOOLS/$tool" "$@"; fi
  else
    if [ -x "$TOOLS/$tool" ]; then "$TOOLS/$tool" "$@"; else sh "$TOOLS/$tool" "$@"; fi
  fi
}

# --install:把两个命令装到 bindir(默认 ~/bin)。
do_install() {
  bindir="$HOME/bin"
  while [ $# -gt 0 ]; do
    case $1 in
      --bindir) bindir=${2:?--bindir 需要一个目录}; shift ;;
      --bindir=*) bindir=${1#--bindir=} ;;
      -*) die "--install: 未知参数: $1" ;;
      *) die "--install: 多余参数: $1" ;;
    esac
    shift
  done
  ensure_tools
  mkdir -p -- "$bindir"
  for c in tmux-pack tmux-restore; do
    cp -- "$TOOLS/$c" "$bindir/$c"
    chmod +x -- "$bindir/$c"
    printf '已安装 %s\n' "$bindir/$c"
  done
  case ":$PATH:" in
    *":$bindir:"*) : ;;
    *) printf '\n注意: %s 不在 PATH,请加:\n  export PATH="%s:$PATH"\n' "$bindir" "$bindir" ;;
  esac
  printf '\n下一步: 源机跑  tmux-pack .  打包;目标机解压后  ./restore.sh  还原。\n'
}

[ $# -eq 0 ] && { usage; exit 0; }

cmd=$1; shift
case "$cmd" in
  -h|--help)  usage; exit 0 ;;
  --install)  do_install "$@" ;;
  pack|p)     run_tool tmux-pack "$@" ;;
  restore|r)  run_tool tmux-restore "$@" ;;
  -*) printf '%s: 未知参数: %s\n' "$PROG" "$cmd" >&2; usage; exit 2 ;;
  *)  printf '%s: 未知子命令: %s\n' "$PROG" "$cmd" >&2; usage; exit 2 ;;
esac
