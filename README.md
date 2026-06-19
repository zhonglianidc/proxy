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
| Shadowsocks | `sspt` | 留空随机端口 |
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
