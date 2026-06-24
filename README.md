# tmux-config-sync

把一台机器上的 **tmux 环境**(oh-my-tmux + 你的个性化配置 + 插件,**不含 tmux 本体**)打成一个离线即用的"懒人包",拷到任意另一台机器一键还原。跨 `$HOME`、跨用户名可移植。

> 纯 POSIX sh,零运行时依赖。**仅支持 Linux**(假设 GNU coreutils)。

---

## 快速上手(curl | sh 一把梭)

不用安装、不用手动下载,一行命令直接跑。脚本会自动把所需工具拉到临时目录,**跑完即删,零残留**。

```sh
# 1) 源机:打包当前 tmux 配置到当前目录
curl -fsSL https://raw.githubusercontent.com/ccwq/tmux-config-sync/main/run.sh | sh -s -- pack .

# 2) 目标机:把产物拷过来,还原
curl -fsSL https://raw.githubusercontent.com/ccwq/tmux-config-sync/main/run.sh | sh -s -- restore tmux-config-sync-*.tar.gz
```

> `pack` 不带名字时,产物默认叫 `tmux-config-sync-<时间戳>.tar.gz`。
> 想先看不落盘的预览:`... | sh -s -- restore <包> --dry-run`。

就这两步。下面是细节、参数和其它入口。

---

## 其它入口

### 想长期反复用?把命令装到 `~/bin`

```sh
curl -fsSL https://raw.githubusercontent.com/ccwq/tmux-config-sync/main/run.sh | sh -s -- --install
# 装到别处:
curl -fsSL .../run.sh | sh -s -- --install --bindir /usr/local/bin
```

装好后就有了 `tmux-pack` / `tmux-restore` 两个独立命令,之后直接 `tmux-pack .` / `tmux-restore <包>`,无需再联网。

### 在本仓库里(已 clone)

`run.sh` 会自动发现同目录的 `tools/`,**完全离线**、不联网:

```sh
./run.sh pack .                 # 别名: ./run.sh p .
./run.sh restore <包>           # 别名: ./run.sh r <包>
```

### 不想用 curl|sh?

直接把 `tools/tmux-pack`、`tools/tmux-restore` 两个文件拷到 `~/bin` 并 `chmod +x` 即可,二者各自独立、无外部依赖。

### 换拉取源(自建 / 内网镜像)

```sh
TMUX_TOOLS_RAW_BASE=https://你的镜像/tools  curl -fsSL .../run.sh | sh -s -- pack .
```

---

## 用法详解

### 打包(源机)

```sh
pack .                        # 打包到当前目录
pack ~/out                    # 指定输出目录
pack . --name my-tmux         # 自定义包名(默认 tmux-config-sync-<时间戳>)
pack . --upgrade              # 先 git 升级插件再打包(需联网)
pack . --upgrade --proxy http://HOST:PORT   # 升级时显式走代理
pack . --no-tgz               # 只产目录,不压成 .tar.gz
```

> 升级时若已 `export https_proxy` / `http_proxy`,git 会自动继承,无需 `--proxy`。
> 上面的 `pack` 在 curl|sh 形态写作 `... | sh -s -- pack .`,在仓库内写作 `./run.sh pack .`,装好命令后写作 `tmux-pack .`。

### 还原(目标机)

```sh
restore <包>                  # 一键还原(.tar.gz/.tgz 或解开的目录)
restore <包> --dry-run        # 只预览不落盘
restore <包> --bindir /usr/local/bin
restore <包> --no-bin         # 不顺带安装命令
restore <包> --force          # 覆盖时不额外确认
```

bundle 解开后目录里也带了一个 `./restore.sh`,等价于 `restore <该目录>`。

还原会:备份目标机已有 tmux 配置(改名 `*.bak-时间戳`)→ 铺配置 + oh-my-tmux + 插件 → 按目标机 `$HOME` 重建软链(同时建 XDG 和 legacy,**新老 tmux 双兼容**)→ 把命令装到 `~/bin`。

启动 tmux 后按 `prefix + r` 重载、`prefix + I` 确认插件。

---

## 前置条件

- **tmux 已安装**:工具**不打包 tmux 本体**。oh-my-tmux 需要 **tmux 3.1+** 才读取 XDG 配置路径。还原时会探测目标机 tmux,缺失或 `<3.1` 会**警告但仍继续**(配置就位,你自行装/升级 tmux)。
- **GNU coreutils**:依赖 `readlink -f`、`cp -a` 等。仅面向 Linux,见 [docs/adr/0001](docs/adr/0001-linux-only-gnu-coreutils.md)。
- **curl 或 wget**:仅 curl|sh 一把梭 / `--install` 自动拉取脚本时需要;仓库内 `./run.sh`(本地 tools/)和 `--upgrade` 之外的还原阶段**完全离线**。

---

## 命令速查

| | |
|---|---|
| `run.sh`(无参) | 显示帮助 |
| `run.sh pack .` / `p .` | 打包到当前目录 |
| `run.sh restore <包>` / `r <包>` | 还原一个 bundle |
| `run.sh --install [--bindir DIR]` | 把 `tmux-pack`/`tmux-restore` 装到 `~/bin` |
| `run.sh pack -h` / `restore -h` | 透传查看各工具完整选项 |

---

## 名词

- **bundle / 懒人包**:`pack` 产出的 `.tar.gz`(默认 `tmux-config-sync-<时间戳>`),属于某台源机,各人自产自用。
- **run.sh**(本仓库根):唯一入口。curl|sh 一把梭跑 pack/restore,或 `--install` 装命令。
- **tmux-pack / tmux-restore**(`tools/`):真正干活的两个独立脚本,可单独拷用。
- **restore.sh**(bundle 内):还原那一个 bundle 的脚本(转发给 tmux-restore)。

更多术语见 [CONTEXT.md](CONTEXT.md);设计取舍见 [docs/adr/](docs/adr/)。
