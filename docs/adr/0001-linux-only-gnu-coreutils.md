# 工具只支持 Linux(假设 GNU coreutils)

`tmux-pack`/`tmux-restore` 明确只面向 Linux 发行版,依赖 GNU coreutils 行为(如 `readlink -f`、`cp -a`)。我们考虑过为 BSD/macOS 兼容去掉这些 GNU 专有用法,但那会显著增加脚本复杂度和测试面;受众主要在 Linux,因此选择"明确只管 Linux、遇到 BSD 干净报错"而非"勉强跨平台"。

## Consequences

- 脚本可保留 `readlink -f`、`cp -a` 等简洁写法,并在缺 GNU 行为时早早 `die`。
- macOS/BSD 用户不受支持;若未来需要,需专门重做可移植性,而非临时打补丁。
