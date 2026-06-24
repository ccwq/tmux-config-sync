# 术语表 (CONTEXT.md)

> 本文件是**词汇表**,不是规格说明、不是设计记录。只定义这个项目里反复出现、且含义需要固定的词。

---

## 工具 (the tools)

指 `tmux-pack` 与 `tmux-restore` 两个 POSIX sh 脚本。**这是本项目对外分发的唯一单位**——别人拿走脚本,在自己机器上打包、还原自己的配置。脚本本身与设备无关。

## 懒人包 / bundle

由 `tmux-pack` 在**某一台源机**上生成的 `.tar.gz`(或目录)产物,内含那台机的配置 + oh-my-tmux + 插件 + manifest。**bundle 天然属于某台源机,不是通用物,不由本项目对外分发**。每个使用者自产自用。

## 配置快照 (config-snapshot)

`config-snapshots/` 下的纯配置备份(只有 `tmux.conf.local` 等,不含插件)。供"只想恢复个性化配置"的手动还原场景,与 bundle 区分开。

## 入口 (run.sh) —— 仓库级

公开仓库根部的 `run.sh`,是 `curl | sh` 的拉取目标,也是本项目唯一对外入口(取代了原 `install.sh`)。三种用法:
- `pack`/`restore`:**一把梭**——自动把 [工具](#工具-the-tools)拉到临时目录跑一次,**用完即删、零残留**;
- `--install`:把 `tmux-pack`/`tmux-restore` 两个命令装到目标机的 `~/bin`(或 `--bindir`),供长期反复使用;
- 仓库内 `./run.sh`:自动发现同目录 `tools/`,**离线**直跑,不联网。

`pack`/`restore` 只是把参数透传给同名工具,**run.sh 本身与"还原某个 bundle"的逻辑无关**——那是 `tmux-restore` 的职责。

## bundle 内的还原脚本 (restore.sh)

`tmux-pack` 生成在 bundle 里的一键还原脚本,职责是**还原这一个 bundle**(转发给 `tmux-restore`)。它生在 bundle 内、只管自己这一个包,与仓库级[入口](#入口-runsh--仓库级)无关。

## 源机 / 目标机

源机 = 运行 `tmux-pack` 产出 bundle 的机器;目标机 = 运行 `tmux-restore` 落地 bundle 的机器。脚本通过 manifest 里的 `@TOKEN@` 令牌做两机之间的路径重映射。
