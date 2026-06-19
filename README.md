# Proxy VPS 一键脚本

这个仓库只保留 VPS 使用场景：用户在服务器 SSH 里执行一条命令，即可安装并生成各协议节点信息。

## 文件说明

- `proxy.sh`：VPS 主脚本。
- `index.html`：网页命令生成器，用来勾选协议并复制 SSH 命令。
- `LICENSE`：原项目许可证。

## 一键使用

默认主脚本：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

如果服务器没有 `curl`，使用：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

至少选择一个协议变量，例如：

```bash
sopt="" bash <(curl -Ls https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

多个协议组合示例：

```bash
vmpt="" vwpt="" sopt="" sspt="" bash <(curl -Ls https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

## 常用协议变量

| 协议 | 变量 | 说明 |
| --- | --- | --- |
| Vless TCP Reality | `vlpt` | 留空随机端口，或填指定端口 |
| Vless XHTTP Reality ENC | `xhpt` | 留空随机端口，或填指定端口 |
| Vless XHTTP ENC | `vxpt` | 留空随机端口，支持 CDN/回源配置 |
| Vless WS ENC | `vwpt` | 留空随机端口，支持 Argo/CDN |
| Vmess WS | `vmpt` | 留空随机端口，支持 Argo/CDN |
| Shadowsocks 2022 | `sspt` | 留空随机端口 |
| Socks5 | `sopt` | 留空随机端口，会输出分享链接和二维码 |
| Hysteria2 | `hypt` | 留空随机端口 |
| Tuic | `tupt` | 留空随机端口 |
| AnyTLS | `anpt` | 留空随机端口 |
| Any Reality | `arpt` | 留空随机端口 |

## 已安装后的命令

首次安装后重新连接 SSH，快捷命令才会生效。

```bash
proxy list   # 显示节点
proxy rep    # 按新变量重置/更新配置
proxy res    # 重启脚本服务
proxy upx    # 更新 Xray 内核
proxy ups    # 更新 Sing-box 内核
proxy del    # 卸载
```

## GitHub 部署注意事项

1. 仓库建议保持公开，否则 VPS 无法直接通过 `raw.githubusercontent.com` 拉取脚本。
2. 默认分支需要是 `main`；如果你改成其他分支，要同步改 `index.html` 和 README 里的 raw 地址。
3. `proxy.sh` 第一行必须保持 `#!/bin/sh`，上传时不要用会破坏换行或编码的编辑器。
4. Xray 会自动从 `XTLS/Xray-core` 官方 GitHub Release 下载最新版；Sing-box 会自动从 `SagerNet/sing-box` 官方 GitHub Release 下载最新版；Cloudflared 也使用官方最新版。
5. VPS 需要能访问 GitHub Release 下载地址，否则内核下载会失败。
6. 如果启用 CDN 优选相关功能，把 `YOUR_CDN_DOMAIN` 替换为你的优选域名后缀；不用 CDN 优选可忽略。
7. 修改后可以打开 `index.html`，确认网页生成的命令已经指向 `zhonglianidc/proxy`。

## Socks5 修改说明

Socks5 用户名和密码会单独生成，同一个 12 位字母数字随机值；节点输出时会显示 Socks5 分享链接，并尝试在终端显示二维码，方便用户直接扫码。
