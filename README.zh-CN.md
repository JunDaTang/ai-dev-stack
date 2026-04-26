# ai-dev-stack

[English](README.md) | 简体中文

用于 Ubuntu / WSL 的可复现 AI 编码工作站引导仓库。

ai-dev-stack 的目标是把一台干净的机器尽快整理成可用的开发环境，当前覆盖：
- shell PATH 安全配置
- Claude Code
- Codex
- cc-switch
- 可选 Mihomo 安装
- 可选 CLIProxyAPI 接线（基于已存在的本地 checkout）
- doctor 自检

## 这个仓库现在能做什么

已自动化的能力：
- shell PATH 配置
- Claude Code 安装/检查
- Codex 安装/检查
- cc-switch 安装/检查
- Mihomo 安装器，支持自定义 binary/config/service 路径
- CLIProxyAPI 安装路径，但前提是你本地已经有现成 checkout
- doctor / healthcheck 自检
- dry-run 预演
- 修改前自动备份文件

还没完全自动化的部分：
- Hermes 的可移植 installer

## 快速开始

```sh
git clone https://github.com/JedTang/ai-dev-stack.git
cd ai-dev-stack
cp examples/config.example.env .env
# 编辑 .env，把真实密钥/URL 只放本地
./install.sh --profile wsl --dry-run
./install.sh --profile wsl
./install.sh doctor
```

## 常用命令

只预演、不改机器：

```sh
./install.sh --profile minimal --dry-run
./install.sh doctor --dry-run
```

WSL 环境：

```sh
./install.sh --profile wsl
./install.sh doctor
```

Ubuntu 服务器环境：

```sh
./install.sh --profile ubuntu-server
./install.sh doctor
```

## Profiles 说明

- `minimal`
  - shell PATH
  - Claude Code
  - Codex
  - cc-switch

- `wsl`
  - 包含 `minimal` 全部能力
  - 设置 `INSTALL_MIHOMO=1` 后可选安装 Mihomo
  - 设置 `INSTALL_CLIPROXYAPI=1` 后可选接线 CLIProxyAPI

- `ubuntu-server`
  - 面向服务器的 shell 和 CLI 引导
  - Mihomo 默认不启用
  - CLIProxyAPI 默认不启用，且要求机器上已有本地 checkout

- `china-server`
  - 面向服务器，并默认 `USE_GITHUB_MIRROR=1`
  - Mihomo 复用同一套 installer 参数
  - CLIProxyAPI 也复用同一套“现有 checkout 接线”路径

## 本地配置

先复制：

```sh
cp examples/config.example.env .env
```

重要规则：
- secrets 只放 `.env`
- 不要提交 `.env`
- 文档和示例里只保留 `[REDACTED]` 这类占位

可以参考：
- `examples/config.example.env`
- `examples/wsl.example.env`
- `profiles/minimal.env`
- `profiles/wsl.env`
- `profiles/ubuntu-server.env`
- `profiles/china-server.env`

## Mihomo 安装参数

如果你想让 ai-dev-stack 安装 Mihomo，请在本地 `.env` 里设置这些项，并启用 `INSTALL_MIHOMO=1`：

- `CLASH_SUBSCRIPTION_URL`：真实的 Mihomo/Clash 订阅地址
- `MIHOMO_VERSION`：版本号，默认 `v1.19.24`
- `MIHOMO_BINARY_PATH`：安装目标，默认 `/usr/local/bin/mihomo`
- `MIHOMO_CONFIG_DIR`：运行目录，默认 `$HOME/clashd`
- `MIHOMO_CONFIG_PATH`：配置文件路径，默认 `$HOME/clashd/config.yaml`
- `MIHOMO_SERVICE_NAME`：systemd service 名称，默认 `clash.service`
- `USE_GITHUB_MIRROR=1`：可选，GitHub 镜像下载模式

预演：

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl --dry-run
```

实际执行：

```sh
INSTALL_MIHOMO=1 ./install.sh --profile wsl
systemctl status clash.service
mihomo -v
```

## CLIProxyAPI 安装参数

如果你想让 ai-dev-stack 接线一个已经存在的 CLIProxyAPI 本地 checkout，请在 `.env` 里设置这些项，并启用 `INSTALL_CLIPROXYAPI=1`：

- `CLIPROXY_WORKDIR`：checkout 路径，默认 `$HOME/cliproxyapi`
- `CLIPROXY_CONFIG_PATH`：配置文件路径，默认 `$HOME/cliproxyapi/config.yaml`
- `CLIPROXY_BINARY_PATH`：可执行文件路径，默认 `$HOME/cliproxyapi/cli-proxy-api`
- `CLIPROXY_SERVICE_NAME`：user-level systemd service 名称，默认 `cliproxyapi.service`
- `CLIPROXY_PROXY_URL`：写入配置的 proxy 地址，默认 `http://127.0.0.1:7890`
- `CLIPROXY_PORT`：写入配置的端口，默认 `8317`
- `CLIPROXY_BASE_URL`：健康检查地址，默认 `http://127.0.0.1:8317`

预演：

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl --dry-run
```

实际执行：

```sh
INSTALL_CLIPROXYAPI=1 ./install.sh --profile wsl
systemctl --user status cliproxyapi.service
curl -v http://127.0.0.1:8317
```

## 安全性

- secrets 只保留在 `.env`
- 改动前会把原文件备份到 `~/.ai-dev-stack/backups/`
- 安装脚本尽量按幂等方式设计
- 在新机器上建议先跑 `--dry-run`

## 验证

本地检查命令：

```sh
bash tests/smoke-test.sh
bash tests/shellcheck.sh
./install.sh doctor --dry-run
```

## CI

正式跟踪的 GitHub Actions workflow：
- `.github/workflows/ci.yml`

可复用模板：
- `templates/github/ci.yml.example`

## 故障排查

参考：
- `docs/troubleshooting.md`
- `docs/secrets.md`

## 当前状态

已经落地：
- shell PATH 修复
- Claude Code / Codex / cc-switch 安装路径
- doctor 自检
- 可配置 Mihomo installer
- 基于现有本地 checkout 的 CLIProxyAPI 接线

尚未落地：
- Hermes 可移植 installer
