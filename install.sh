#!/bin/sh
# install.sh — 一行安装 tmux-pack / tmux-restore 两个命令到本机。
#              这是「仓库级安装器」(curl|sh 目标),与 bundle 内部的 restore.sh 无关。
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install.sh | sh
#   # 装到别处:
#   curl -fsSL .../install.sh | sh -s -- --bindir /usr/local/bin
#   # 临时换拉取源(自建/内网镜像):
#   TMUX_TOOLS_RAW_BASE=https://你的镜像/tools curl -fsSL .../install.sh | sh
#
# 仅支持 Linux(假设 GNU coreutils)。需要 curl 或 wget。
set -eu

PROG=install.sh

# 两个脚本所在的 raw 根地址;默认拉公开仓库 main 分支的 tools/ 目录。
# !!! 发布前把 OWNER/REPO 换成你的 GitHub 用户名/仓库名 !!!
RAW_BASE=${TMUX_TOOLS_RAW_BASE:-https://raw.githubusercontent.com/OWNER/REPO/main/tools}

BINDIR="$HOME/bin"

usage() { sed -n '2,/^set -eu/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case $1 in
    --bindir) BINDIR=${2:?--bindir 需要一个目录}; shift ;;
    --bindir=*) BINDIR=${1#--bindir=} ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -*) printf '%s: 未知参数: %s\n' "$PROG" "$1" >&2; exit 2 ;;
    *) printf '%s: 多余参数: %s\n' "$PROG" "$1" >&2; exit 2 ;;
  esac
  shift
done

die() { printf '%s: 错误: %s\n' "$PROG" "$*" >&2; exit 1; }

# 选择下载器(curl 优先,其次 wget)
if command -v curl >/dev/null 2>&1; then
  dl() { curl -fsSL -- "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  dl() { wget -q -O "$2" -- "$1"; }
else
  die "需要 curl 或 wget"
fi

case "$RAW_BASE" in
  *OWNER/REPO*) die "RAW_BASE 仍是占位符,请改 install.sh 里的 OWNER/REPO,或设 TMUX_TOOLS_RAW_BASE 环境变量。" ;;
esac

mkdir -p -- "$BINDIR"
for c in tmux-pack tmux-restore; do
  printf '拉取 %s ...\n' "$c"
  dl "$RAW_BASE/$c" "$BINDIR/$c" || die "下载失败: $RAW_BASE/$c"
  chmod +x -- "$BINDIR/$c"
done

printf '\n已安装到 %s:\n  tmux-pack\n  tmux-restore\n' "$BINDIR"
case ":$PATH:" in
  *":$BINDIR:"*) : ;;
  *) printf '\n注意: %s 不在 PATH,请加:\n  export PATH="%s:$PATH"\n' "$BINDIR" "$BINDIR" ;;
esac
printf '\n下一步: 在源机跑  tmux-pack .  打包;到目标机解压后  ./restore.sh  还原。\n详见  tmux-pack -h  /  tmux-restore -h\n'
