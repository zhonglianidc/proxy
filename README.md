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

如果服务器已经存在脚本生成的节点配置，再次输入安装命令时不会直接覆盖。脚本会让用户选择“重新搭建”或“输出原节点信息”；直接回车默认查看原节点。显式执行 `proxy rep` 时仍会按用户命令重新搭建。

## 常用协议变量

| 协议 | 变量 | 说明 |
| --- | --- | --- |
| Vless TCP Reality | `vlpt` | 留空随机端口，或填指定端口 |
| Vless XHTTP Reality ENC | `xhpt` | 留空随机端口，或填指定端口 |
| Vless XHTTP ENC | `vxpt` | 留空随机端口，支持 CDN/回源配置 |
| Vless WS ENC | `vwpt` | 留空随机端口，支持 Argo/CDN |
| Vmess WS | `vmpt` | 留空随机端口，支持 Argo/CDN |
| Shadowsocks | `sspt` | 留空随机端口 |
| Socks5 | `sopt` | 留空随机端口，输出账号信息、分享链接和指纹浏览器格式，不生成二维码 |
| Hysteria2 | `hypt` | 留空随机端口 |
| Tuic | `tupt` | 留空随机端口 |
| AnyTLS | `anpt` | 留空随机端口 |
| Any Reality | `arpt` | 留空随机端口 |

## VLESS Reality Vision 开关

`vlpt` 默认生成 VLESS TCP Reality Vision，原有命令保持不变：

```bash
sopt="" vlpt="" hypt="" sspt="" sub="y" bash <(curl -Ls https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

如需生成不带 `xtls-rprx-vision` flow 的 VLESS TCP Reality，增加 `vision="n"`：

```bash
sopt="" vlpt="" hypt="" sspt="" sub="y" vision="n" bash <(curl -Ls https://raw.githubusercontent.com/zhonglianidc/proxy/main/proxy.sh)
```

脚本会同时调整 Xray 服务端、节点分享链接、Clash 和 Sing-box 配置，并保存该模式供后续查看节点或修改端口时继续使用。

## 已安装后的命令

首次安装后重新连接 SSH，快捷命令才会生效。

```bash
proxy list   # 显示节点
proxy rep    # 按新变量重置/更新配置
proxy res    # 重启脚本服务
proxy upx    # 更新 Xray 内核到脚本固定版本
proxy ups    # 更新 Sing-box 内核到脚本固定版本
proxy del    # 卸载
```

## 输出说明

- 终端会直接显示节点分享链接。
- 终端会保留各协议节点分享链接，用户不打开网页也可以直接复制使用。
- 所有节点信息会汇总到最后输出的节点信息网页地址里，用户可用网页浏览器打开查看、复制和扫码导入。
- Socks5 只显示客户端 IP、端口号、用户名、密码、分享链接和指纹浏览器格式。
- Reality 域名留空时，脚本会自动从候选域名里测速选择延迟最低的目标，候选列表包含 `xp.apple.com`。
- 公网 IP 会优先通过 `ipinfo.io` 探测，并自动回退到多个备用接口；空响应、网页内容或无效地址不会覆盖已有 IP。全部接口失败且没有历史有效 IP 时，脚本会停止生成节点信息，避免产生缺少服务器地址的失效链接。
- Hysteria2 使用自签证书时，分享链接和 Clash 配置已默认开启跳过证书校验，避免部分客户端导入后证书验证失败。
- Xray 默认固定为脚本内置版本，避免最新版频繁变化造成兼容问题；如需临时指定版本，可在命令前加 `XRAY_VERSION=v26.3.27`。
- Sing-box 默认固定为 `v1.13.16`；如需临时指定，可在命令前加 `SINGBOX_VERSION=v1.13.16`。
- XHTTP、WebSocket 不添加 `xtls-rprx-vision`；Vision 开关只影响 VLESS TCP Reality。
- 内核更新会先下载、校验和检查配置，重启失败时自动恢复旧内核。
- HY2 端口跳跃使用独立 `PROXY_HY2` 规则链，不会清空服务器其他 NAT 转发规则。
