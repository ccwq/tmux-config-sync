# tmux-pack / tmux-restore

把一台机器上的 **tmux 环境**(oh-my-tmux + 你的个性化配置 + 插件,**不含 tmux 本体**)打成一个离线即用的"懒人包",拷到任意另一台机器一键还原。跨 `$HOME`、跨用户名可移植。

> 纯 POSIX sh,零运行时依赖。**仅支持 Linux**(假设 GNU coreutils)。

---

## 安装

```sh
curl -fsSL https://raw.githubusercontent.com/OWNER/REPO/main/install.sh | sh
```

装到别处 / 用自建镜像:

```sh
curl -fsSL .../install.sh | sh -s -- --bindir /usr/local/bin
TMUX_TOOLS_RAW_BASE=https://你的镜像/tools curl -fsSL .../install.sh | sh
```

> 不想用 curl|sh?直接把 `tools/tmux-pack`、`tools/tmux-restore` 两个文件拷到 `~/bin` 并 `chmod +x` 即可,二者各自独立、无外部依赖。

---

## 用法

### 在源机:打包

```sh
tmux-pack .                       # 打包当前 tmux 配置到当前目录
tmux-pack ~/out                   # 指定输出目录
tmux-pack --upgrade               # 先 git 升级插件再打包(需联网)
tmux-pack --upgrade --proxy http://HOST:PORT   # 升级时显式走代理
```

> 升级时若已 `export https_proxy` / `http_proxy`,git 会自动继承,无需 `--proxy`。

### 在目标机:还原

```sh
tar xzf tmux-pack-*.tar.gz
cd tmux-pack-*/
./restore.sh                      # 一键还原本 bundle
# 等价于:tmux-restore <包路径>
tmux-restore <包> --dry-run       # 只预览不落盘
tmux-restore <包> --bindir /usr/local/bin
```

还原会:备份目标机已有 tmux 配置(改名 `*.bak-时间戳`)→ 铺配置 + oh-my-tmux + 插件 → 按目标机 `$HOME` 重建软链(同时建 XDG 和 legacy,**新老 tmux 双兼容**)→ 把命令装到 `~/bin`。

启动 tmux 后按 `prefix + r` 重载、`prefix + I` 确认插件。

---

## 前置条件

- **tmux 已安装**:工具**不打包 tmux 本体**。oh-my-tmux 需要 **tmux 3.1+** 才读取 XDG 配置路径。还原时会探测目标机 tmux,缺失或 `<3.1` 会**警告但仍继续**(配置就位,你自行装/升级 tmux)。
- **GNU coreutils**:依赖 `readlink -f`、`cp -a` 等。仅面向 Linux,见 [docs/adr/0001](docs/adr/0001-linux-only-gnu-coreutils.md)。
- 仅 `--upgrade` 需要联网(及可选代理);**还原阶段完全离线**。

---

## 命令速查

| | |
|---|---|
| `tmux-pack`(无参) | 显示帮助 |
| `tmux-pack .` | 打包到当前目录 |
| `tmux-pack -h` / `tmux-restore -h` | 完整选项 |
| `tmux-restore`(无参) | 显示帮助(避免误把当前目录当包) |

---

## 名词

- **bundle / 懒人包**:`tmux-pack` 产出的 `.tar.gz`,属于某台源机,各人自产自用。
- **install.sh**(本仓库根):安装这两个命令的脚本(curl|sh 目标)。
- **restore.sh**(bundle 内):还原那一个 bundle 的脚本。

更多术语见 [CONTEXT.md](CONTEXT.md);设计取舍见 [docs/adr/](docs/adr/)。
