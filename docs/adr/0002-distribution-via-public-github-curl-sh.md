# 分发模型:公开 GitHub 仓库 + curl|sh 拉 main

工具对外分发的单位是两个脚本本身(bundle 各人自产自用、不分发)。获取主路径定为 `curl | sh` 一行安装,安装器(仓库根 `install.sh`)从公开 GitHub 仓库的 raw URL 拉取,且固定拉 `main` 最新版。考虑过"拷两个文件"和"git clone",选 curl|sh 是为了上手最丝滑;选 main-latest 是为了零维护(不做 release/tag 流程)。

## Considered Options

- 拷两个文件 + chmod:零依赖零服务,但发现/上手靠用户自己。
- git clone:便于版本跟踪,但依赖网络且多一步。
- 钉 tag/release:可复现、可回滚,但要维护版本号与发布流程。

## Consequences

- 需要建一个公开 GitHub 仓库;仓库**只放**脚本 + `install.sh` + 与设备无关的工具 README。个人 bundle、config-snapshots、本机手册、代理 IP 等一律不上传。
- 拉 main-latest **不可复现**:URL 已在外流传后,main 一旦损坏或被改会直接影响所有新装机。这是为零维护付出的代价;若日后需要稳定性,见可改为钉 tag(届时另立 ADR 取代本条)。
