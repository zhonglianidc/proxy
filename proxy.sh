#!/bin/sh
if locale -a 2>/dev/null | grep -qi '^C\.UTF-8$'; then
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
else
export LANG=C
unset LC_ALL
fi
install_dependencies(){
[ "$1" = "del" ] && return
if [ "$(id -u 2>/dev/null)" != "0" ]; then
echo "当前环境非root用户权限，请先输入 sudo -i 命令"
exit 1
fi
required_deps="curl wget unzip tar gzip openssl awk sed grep find qrencode iptables crontab timeout base64 sha256sum tr head xargs readlink pgrep"
missing=""
for cmd in $required_deps; do
command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
[ -f "$HOME/agsbx/.deps_ok" ] && [ -z "$missing" ] && return
echo "正在检查并安装脚本运行依赖，请稍等..."
mkdir -p "$HOME/agsbx"
if command -v apt-get >/dev/null 2>&1; then
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1
printf 'iptables-persistent iptables-persistent/autosave_v4 boolean true\niptables-persistent iptables-persistent/autosave_v6 boolean true\n' | debconf-set-selections 2>/dev/null
apt-get install -y curl wget ca-certificates bash busybox coreutils util-linux procps iproute2 iptables iptables-persistent cron openssl unzip tar gzip qrencode findutils grep sed gawk xz-utils chrony >/dev/null 2>&1
elif command -v apk >/dev/null 2>&1; then
apk update >/dev/null 2>&1
apk add --no-cache curl wget ca-certificates bash busybox-extras gcompat libc6-compat coreutils util-linux procps iproute2 iptables ip6tables openrc dcron openssl unzip tar gzip qrencode findutils grep sed gawk xz chrony >/dev/null 2>&1
elif command -v dnf >/dev/null 2>&1; then
dnf install -y curl wget ca-certificates bash coreutils util-linux procps-ng iproute iptables iptables-services cronie openssl unzip tar gzip qrencode findutils grep sed gawk xz chrony >/dev/null 2>&1
elif command -v yum >/dev/null 2>&1; then
yum install -y curl wget ca-certificates bash coreutils util-linux procps-ng iproute iptables iptables-services cronie openssl unzip tar gzip qrencode findutils grep sed gawk xz chrony >/dev/null 2>&1
else
echo "未识别系统包管理器，请先手动安装 curl/wget/unzip/tar/openssl/iptables/qrencode 等依赖。"
exit 1
fi
missing=""
for cmd in $required_deps; do
command -v "$cmd" >/dev/null 2>&1 || missing="$missing $cmd"
done
if [ -n "$missing" ]; then
echo "依赖安装不完整，缺少命令:$missing"
echo "请检查系统软件源是否可用，然后重新运行脚本。"
exit 1
fi
touch "$HOME/agsbx/.deps_ok"
echo "依赖检查完成。"
}
sync_system_time(){
[ "$1" = "del" ] && return
if command -v timedatectl >/dev/null 2>&1; then
timedatectl set-ntp true >/dev/null 2>&1
fi
if command -v systemctl >/dev/null 2>&1; then
systemctl enable --now chrony >/dev/null 2>&1 || systemctl enable --now chronyd >/dev/null 2>&1 || systemctl enable --now systemd-timesyncd >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-update add chronyd default >/dev/null 2>&1
rc-service chronyd start >/dev/null 2>&1
fi
if command -v chronyc >/dev/null 2>&1; then
chronyc -a makestep >/dev/null 2>&1
fi
}
install_dependencies "$1"
sync_system_time "$1"
setup_time_sync_job(){
[ "$1" = "del" ] && return
mkdir -p "$HOME/agsbx"
cat > "$HOME/agsbx/sync_time.sh" <<'EOF'
#!/bin/sh
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl set-ntp true >/dev/null 2>&1
fi
if command -v chronyc >/dev/null 2>&1; then
  chronyc -a makestep >/dev/null 2>&1
fi
EOF
chmod +x "$HOME/agsbx/sync_time.sh"
crontab -l 2>/dev/null | sed '/agsbx\/sync_time\.sh/d' > /tmp/agsbx_cron_time.tmp
echo "*/30 * * * * /bin/sh $HOME/agsbx/sync_time.sh >/dev/null 2>&1" >> /tmp/agsbx_cron_time.tmp
crontab /tmp/agsbx_cron_time.tmp >/dev/null 2>&1
rm -f /tmp/agsbx_cron_time.tmp
}
disable_system_firewall(){
[ "$1" = "del" ] && return
if command -v ufw >/dev/null 2>&1; then
ufw disable >/dev/null 2>&1
fi
if command -v systemctl >/dev/null 2>&1; then
systemctl stop firewalld >/dev/null 2>&1
systemctl disable firewalld >/dev/null 2>&1
systemctl stop ufw >/dev/null 2>&1
systemctl disable ufw >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service firewalld stop >/dev/null 2>&1
rc-update del firewalld default >/dev/null 2>&1
rc-service ufw stop >/dev/null 2>&1
rc-update del ufw default >/dev/null 2>&1
fi
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
if command -v ip6tables >/dev/null 2>&1; then
ip6tables -P INPUT ACCEPT >/dev/null 2>&1
ip6tables -P FORWARD ACCEPT >/dev/null 2>&1
ip6tables -P OUTPUT ACCEPT >/dev/null 2>&1
fi
}
setup_time_sync_job "$1"
disable_system_firewall "$1"
[ -z "${vlpt+x}" ] || vlp=yes
[ -z "${vmpt+x}" ] || { vmp=yes; vmag=yes; }
[ -z "${vwpt+x}" ] || { vwp=yes; vmag=yes; }
[ -z "${hypt+x}" ] || hyp=yes
[ -z "${tupt+x}" ] || tup=yes
[ -z "${xhpt+x}" ] || xhp=yes
[ -z "${vxpt+x}" ] || vxp=yes
[ -z "${anpt+x}" ] || anp=yes
[ -z "${sspt+x}" ] || ssp=yes
[ -z "${arpt+x}" ] || arp=yes
[ -z "${sopt+x}" ] || sop=yes
[ -z "${warp+x}" ] || wap=yes
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' || pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1; then
if [ "$1" = "rep" ]; then
[ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：rep重置协议时，请在脚本前至少设置一个协议变量哦，再见！💣"; exit; }
fi
else
[ "$1" = "del" ] || [ "$vwp" = yes ] || [ "$sop" = yes ] || [ "$vxp" = yes ] || [ "$ssp" = yes ] || [ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || [ "$xhp" = yes ] || [ "$anp" = yes ] || [ "$arp" = yes ] || { echo "提示：未安装一键节点脚本，请在脚本前至少设置一个协议变量。"; exit; }
fi
export uuid=${uuid:-''}
export port_vl_re=${vlpt:-''}
export port_vm_ws=${vmpt:-''}
export port_vw=${vwpt:-''}
export port_hy2=${hypt:-''}
export port_tu=${tupt:-''}
export port_xh=${xhpt:-''}
export port_vx=${vxpt:-''}
export port_an=${anpt:-''}
export port_ar=${arpt:-''}
export port_ss=${sspt:-''}
export port_so=${sopt:-''}
export ym_vl_re=${reym:-''}
export cdnym=${cdnym:-''}
export argo=${argo:-''}
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}
export ippz=${ippz:-''}
export warp=${warp:-''}
export name=${name:-''}
export oap=${oap:-''}
SCRIPT_GITHUB_USER=${SCRIPT_GITHUB_USER:-zhonglianidc}
SCRIPT_GITHUB_REPO=${SCRIPT_GITHUB_REPO:-proxy}
SCRIPT_GITHUB_BRANCH=${SCRIPT_GITHUB_BRANCH:-main}
SCRIPT_RAW_BASE=${SCRIPT_RAW_BASE:-https://raw.githubusercontent.com/${SCRIPT_GITHUB_USER}/${SCRIPT_GITHUB_REPO}/${SCRIPT_GITHUB_BRANCH}}
v46url="https://icanhazip.com"
proxyurl="${SCRIPT_RAW_BASE}/proxy.sh"
showmode(){
echo "一键节点脚本生成"
echo "主脚本：bash <(curl -Ls ${proxyurl})"
echo "备用命令：bash <(wget -qO- ${proxyurl})"
echo ""
echo "快捷命令："
echo "  proxy list        显示节点信息"
echo "  proxy rep         重置并重新生成协议"
echo "  proxy upx         更新 Xray 内核"
echo "  proxy ups         更新 Sing-box 内核"
echo "  proxy res         重启节点服务"
echo "  proxy del         卸载脚本"
echo "  ippz=4 proxy list 只显示 IPv4 节点"
echo "  ippz=6 proxy list 只显示 IPv6 节点"
echo ""
echo "首次安装后如 proxy 快捷命令未生效，请重新连接 SSH。"
echo "---------------------------------------------------------"
echo
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "一键节点脚本生成"
echo "当前版本：V26.5.10"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d '"' -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
arm64|aarch64) cpu=arm64;;
amd64|x86_64) cpu=amd64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
if [ "$1" != "del" ]; then
mkdir -p "$HOME/agsbx"
[ -f sbx_update ] || touch sbx_update
fi
v4v6(){
v4=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- "$v46url" 2>/dev/null) )
v6=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- "$v46url" 2>/dev/null) )
v4dq=$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 --tries=2 -qO- https://myip.ipip.net/ | awk -F'来自于：' '{print $2}' 2>/dev/null) )
v6dq=$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k https://ip.fm | sed -n 's/.*Location: //p' 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 --tries=2 -qO- https://ip.fm | grep '<span class="has-text-grey-light">Location:' | tail -n1 | sed -E 's/.*>Location: <\/span>([^<]+)<.*/\1/' 2>/dev/null) )
}
warpsx(){
warpurl=$( (command -v curl >/dev/null 2>&1 && curl -sm5 -k https://warp.xijp.eu.org 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget --tries=2 -qO- https://warp.xijp.eu.org 2>/dev/null) )
if [ -z "$warpurl" ] || printf '%s' "$warpurl" | grep -q html; then
wpv6='2606:4700:110:8d8d:1845:c39f:2dd5:a03a'
pvk='52cuYFgCJXp0LAq7+nWJIbCXXgU9eGggOc+Hlfz5u6A='
res='[215, 69, 233]'
else
pvk=$(echo "$warpurl" | awk -F'：' '/Private_key/{print $2}' | xargs)
wpv6=$(echo "$warpurl" | awk -F'：' '/IPV6/{print $2}' | xargs)
res=$(echo "$warpurl" | awk -F'：' '/reserved/{print $2}' | xargs)
fi
if [ -n "$name" ]; then
sxname=$name-
echo "$sxname" > "$HOME/agsbx/name"
echo
echo "所有节点名称前缀：$name"
fi
v4v6
if echo "$v6" | grep -q '^2a09' || echo "$v4" | grep -q '^104.28'; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
echo; echo "请注意：你已安装了warp"
else
if [ "$wap" != yes ]; then
s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo
else
case "$warp" in
""|sx|xs) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s ) s1outtag=warp-out; s2outtag=warp-out; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6) s1outtag=warp-out; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
x ) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x4) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
x6) s1outtag=direct; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
s4x4|x4s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s4x6|x6s4) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
s6x4|x4s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
s6x6|x6s6) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0"'; wap=warp ;;
sx4|x4s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
sx6|x6s) s1outtag=warp-out; s2outtag=warp-out; x1outtag=warp-out; x2outtag=direct; xip='"::/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warp ;;
xs4|s4x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"0.0.0.0/0"'; wap=warp ;;
xs6|s6x) s1outtag=warp-out; s2outtag=direct; x1outtag=warp-out; x2outtag=warp-out; xip='"::/0", "0.0.0.0/0"'; sip='"::/0"'; wap=warp ;;
* ) s1outtag=direct; s2outtag=direct; x1outtag=direct; x2outtag=direct; xip='"::/0", "0.0.0.0/0"'; sip='"::/0", "0.0.0.0/0"'; wap=warpargo ;;
esac
fi
fi
case "$warp" in *x4*) wxryx='ForceIPv4' ;; *x6*) wxryx='ForceIPv6' ;; *) wxryx='ForceIPv6v4' ;; esac
if command -v curl >/dev/null 2>&1; then
curl -s4m5 -k "$v46url" >/dev/null 2>&1 && v4_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -4 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v4_ok=true
fi
if command -v curl >/dev/null 2>&1; then
curl -s6m5 -k "$v46url" >/dev/null 2>&1 && v6_ok=true
elif command -v wget >/dev/null 2>&1; then
timeout 3 wget -6 --tries=2 -qO- "$v46url" >/dev/null 2>&1 && v6_ok=true
fi
if [ "$v4_ok" = true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s4*) sbyx='prefer_ipv4' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4v6' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" = true ] && [ "$v6_ok" != true ]; then
case "$warp" in *s4*|x) sbyx='ipv4_only' ;; *) sbyx='prefer_ipv6' ;; esac
case "$warp" in *x4*) xryx='ForceIPv4' ;; *x*) xryx='ForceIPv6v4' ;; *) xryx='ForceIPv4v6' ;; esac
elif [ "$v4_ok" != true ] && [ "$v6_ok" = true ]; then
case "$warp" in *s6*|x) sbyx='ipv6_only' ;; *) sbyx='prefer_ipv4' ;; esac
case "$warp" in *x6*) xryx='ForceIPv6' ;; *x*) xryx='ForceIPv4v6' ;; *) xryx='ForceIPv6v4' ;; esac
fi
}
download_file(){
url="$1"
out="$2"
(command -v curl >/dev/null 2>&1 && curl -L -o "$out" -# --retry 2 "$url") || (command -v wget >/dev/null 2>&1 && timeout 120 wget -O "$out" --tries=2 "$url")
}
github_latest_tag(){
repo="$1"
api="https://api.github.com/repos/${repo}/releases/latest"
tag=""
if command -v curl >/dev/null 2>&1; then
tag=$(curl -fsSL "$api" 2>/dev/null | tr -d '\r\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
elif command -v wget >/dev/null 2>&1; then
tag=$(wget -qO- "$api" 2>/dev/null | tr -d '\r\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi
if [ -z "$tag" ] && command -v curl >/dev/null 2>&1; then
tag=$(curl -Ls -o /dev/null -w '%{url_effective}' "https://github.com/${repo}/releases/latest" | awk -F/ '{print $NF}')
fi
echo "$tag"
}
upxray(){
case "$cpu" in
amd64) xray_file='Xray-linux-64.zip' ;;
arm64) xray_file='Xray-linux-arm64-v8a.zip' ;;
*) echo "Xray does not support $(uname -m) architecture yet" && exit 1 ;;
esac
xray_tag=$(github_latest_tag "XTLS/Xray-core")
case "$xray_tag" in v*) ;; *) echo "Failed to get latest Xray release tag"; exit 1 ;; esac
url="https://github.com/XTLS/Xray-core/releases/download/${xray_tag}/${xray_file}"
tmpdir="$HOME/agsbx/xray_tmp"
rm -rf "$tmpdir" && mkdir -p "$tmpdir"
archive="$tmpdir/xray.zip"
echo "Downloading latest official Xray core: $url"
download_file "$url" "$archive" || { echo "Xray download failed"; exit 1; }
unzip -o -q "$archive" -d "$tmpdir" || { echo "Xray unzip failed"; exit 1; }
[ -f "$tmpdir/xray" ] || { echo "Xray binary was not found in archive"; exit 1; }
mv -f "$tmpdir/xray" "$HOME/agsbx/xray"
chmod +x "$HOME/agsbx/xray"
rm -rf "$tmpdir"
sbcore=$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}')
echo "Installed latest official Xray core: $sbcore"
}
upsingbox(){
case "$cpu" in
amd64|arm64)
if command -v apk >/dev/null 2>&1; then
singbox_suffix="linux-${cpu}-musl"
else
singbox_suffix="linux-${cpu}"
fi
;;
*) echo "Sing-box does not support $(uname -m) architecture yet" && exit 1 ;;
esac
singbox_tag=$(github_latest_tag "SagerNet/sing-box")
case "$singbox_tag" in v*) ;; *) echo "Failed to get latest Sing-box release tag"; exit 1 ;; esac
singbox_version=${singbox_tag#v}
url="https://github.com/SagerNet/sing-box/releases/download/${singbox_tag}/sing-box-${singbox_version}-${singbox_suffix}.tar.gz"
tmpdir="$HOME/agsbx/singbox_tmp"
rm -rf "$tmpdir" && mkdir -p "$tmpdir"
archive="$tmpdir/sing-box.tar.gz"
echo "Downloading latest official Sing-box core: $url"
download_file "$url" "$archive" || { echo "Sing-box download failed"; exit 1; }
tar -xzf "$archive" -C "$tmpdir" || { echo "Sing-box extract failed"; exit 1; }
bin=$(find "$tmpdir" -type f -name sing-box | head -n 1)
[ -n "$bin" ] || { echo "Sing-box binary was not found in archive"; exit 1; }
mv -f "$bin" "$HOME/agsbx/sing-box"
chmod +x "$HOME/agsbx/sing-box"
rm -rf "$tmpdir"
sbcore=$("$HOME/agsbx/sing-box" version 2>/dev/null | awk '/version/{print $NF}')
echo "Installed latest official Sing-box core: $sbcore"
}
insuuid(){
if [ -z "$uuid" ] && [ ! -e "$HOME/agsbx/uuid" ]; then
if [ -e "$HOME/agsbx/sing-box" ]; then
uuid=$("$HOME/agsbx/sing-box" generate uuid)
else
uuid=$("$HOME/agsbx/xray" uuid)
fi
echo "$uuid" > "$HOME/agsbx/uuid"
elif [ -n "$uuid" ]; then
echo "$uuid" > "$HOME/agsbx/uuid"
fi
uuid=$(cat "$HOME/agsbx/uuid")
echo "UUID密码：$uuid"
}
inssocks5auth(){
if [ ! -e "$HOME/agsbx/socks5_auth" ]; then
socks5_auth=$(tr -dc 'A-Za-z0-9' < /dev/urandom 2>/dev/null | head -c 12)
[ ${#socks5_auth} -lt 12 ] && socks5_auth=$(date +%s%N | sha256sum | tr -dc 'A-Za-z0-9' | head -c 12)
echo "$socks5_auth" > "$HOME/agsbx/socks5_auth"
fi
socks5_auth=$(cat "$HOME/agsbx/socks5_auth")
}
showqrcode(){
qrtext="$1"
if ! command -v qrencode >/dev/null 2>&1; then
if command -v apt-get >/dev/null 2>&1; then
apt-get update -y >/dev/null 2>&1 && apt-get install -y qrencode >/dev/null 2>&1
elif command -v apk >/dev/null 2>&1; then
apk add --no-cache qrencode >/dev/null 2>&1
elif command -v yum >/dev/null 2>&1; then
yum install -y qrencode >/dev/null 2>&1
elif command -v dnf >/dev/null 2>&1; then
dnf install -y qrencode >/dev/null 2>&1
fi
fi
if command -v qrencode >/dev/null 2>&1; then
qrencode -t UTF8 -m 0 -l L -v 10 "$qrtext" 2>/dev/null || qrencode -t UTF8 -m 0 -l L "$qrtext" 2>/dev/null || qrencode -t ANSIUTF8 -m 0 -l L "$qrtext" 2>/dev/null || qrencode -t UTF8 -m 0 "$qrtext"
else
echo "qrencode is not installed, QR code cannot be shown in terminal."
fi
}
print_section(){
printf '\n\033[1;36m%s\033[0m\n' "============================================================"
printf '\033[1;36m%s\033[0m\n' ">> $1"
printf '\033[1;36m%s\033[0m\n' "============================================================"
}
print_link(){
plink_title="$1"
plink_url="$2"
[ -z "$plink_url" ] && return
printf '\033[1;33m%s\033[0m\n' "$plink_title"
printf '\033[0;32m%s\033[0m\n' "$plink_url"
printf '\033[1;33m%s\033[0m\n' "二维码："
showqrcode "$plink_url"
echo
}
installxray(){
echo
echo "=========启用xray内核========="
mkdir -p "$HOME/agsbx/xrk"
if [ ! -e "$HOME/agsbx/xray" ]; then
upxray
fi
cat > "$HOME/agsbx/xr.json" <<EOF
{
  "log": {
  "loglevel": "none"
  },
  "inbounds": [
EOF
insuuid
if [ -n "$xhp" ] || [ -n "$vlp" ]; then
if [ -z "$ym_vl_re" ]; then
ym_vl_re=apple.com
fi
echo "$ym_vl_re" > "$HOME/agsbx/ym_vl_re"
echo "Reality域名：$ym_vl_re"
if [ ! -e "$HOME/agsbx/xrk/private_key" ]; then
key_pair=$("$HOME/agsbx/xray" x25519)
private_key=$(echo "$key_pair" | awk -F':' '/PrivateKey/ {print $2}' | xargs)
public_key=$(echo "$key_pair" | awk -F':' '/Password/ {print $2}' | xargs)
short_id=$(date +%s%N | sha256sum | cut -c 1-8)
echo "$private_key" > "$HOME/agsbx/xrk/private_key"
echo "$public_key" > "$HOME/agsbx/xrk/public_key"
echo "$short_id" > "$HOME/agsbx/xrk/short_id"
fi
private_key_x=$(cat "$HOME/agsbx/xrk/private_key")
public_key_x=$(cat "$HOME/agsbx/xrk/public_key")
short_id_x=$(cat "$HOME/agsbx/xrk/short_id")
fi
if [ -n "$xhp" ] || [ -n "$vxp" ] || [ -n "$vwp" ]; then
if [ ! -e "$HOME/agsbx/xrk/dekey" ]; then
vlkey=$("$HOME/agsbx/xray" vlessenc)
dekey=$(echo "$vlkey" | grep '"decryption":' | sed -n '2p' | cut -d' ' -f2- | tr -d '"')
enkey=$(echo "$vlkey" | grep '"encryption":' | sed -n '2p' | cut -d' ' -f2- | tr -d '"')
echo "$dekey" > "$HOME/agsbx/xrk/dekey"
echo "$enkey" > "$HOME/agsbx/xrk/enkey"
fi
dekey=$(cat "$HOME/agsbx/xrk/dekey")
enkey=$(cat "$HOME/agsbx/xrk/enkey")
fi

if [ -n "$xhp" ]; then
xhp=xhpt
if [ -z "$port_xh" ] && [ ! -e "$HOME/agsbx/port_xh" ]; then
port_xh=$(shuf -i 10000-65535 -n 1)
echo "$port_xh" > "$HOME/agsbx/port_xh"
elif [ -n "$port_xh" ]; then
echo "$port_xh" > "$HOME/agsbx/port_xh"
fi
port_xh=$(cat "$HOME/agsbx/port_xh")
echo "Vless-xhttp-reality-enc端口：$port_xh"
cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag":"xhttp-reality",
      "listen": "::",
      "port": ${port_xh},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "xhttp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "chrome",
          "target": "${ym_vl_re}:443",
          "serverNames": [
            "${ym_vl_re}"
          ],
          "privateKey": "$private_key_x",
          "shortIds": ["$short_id_x"]
        },
        "xhttpSettings": {
          "host": "",
          "path": "${uuid}-xh",
          "mode": "auto"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
xhp=xhptargo
fi
if [ -n "$vxp" ]; then
vxp=vxpt
if [ -z "$port_vx" ] && [ ! -e "$HOME/agsbx/port_vx" ]; then
port_vx=$(shuf -i 10000-65535 -n 1)
echo "$port_vx" > "$HOME/agsbx/port_vx"
elif [ -n "$port_vx" ]; then
echo "$port_vx" > "$HOME/agsbx/port_vx"
fi
port_vx=$(cat "$HOME/agsbx/port_vx")
echo "Vless-xhttp-enc端口：$port_vx"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/agsbx/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag":"vless-xhttp",
      "listen": "::",
      "port": ${port_vx},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "xhttp",
        "xhttpSettings": {
          "host": "",
          "path": "${uuid}-vx",
          "mode": "auto"
        }
      },
        "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
vxp=vxptargo
fi
if [ -n "$vwp" ]; then
vwp=vwpt
if [ -z "$port_vw" ] && [ ! -e "$HOME/agsbx/port_vw" ]; then
port_vw=$(shuf -i 10000-65535 -n 1)
echo "$port_vw" > "$HOME/agsbx/port_vw"
elif [ -n "$port_vw" ]; then
echo "$port_vw" > "$HOME/agsbx/port_vw"
fi
port_vw=$(cat "$HOME/agsbx/port_vw")
echo "Vless-ws-enc端口：$port_vw"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/agsbx/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
cat >> "$HOME/agsbx/xr.json" <<EOF
    {
      "tag":"vless-ws",
      "listen": "::",
      "port": ${port_vw},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "${dekey}"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${uuid}-vw"
        }
      },
        "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false
      }
    },
EOF
else
vwp=vwptargo
fi
if [ -n "$vlp" ]; then
vlp=vlpt
if [ -z "$port_vl_re" ] && [ ! -e "$HOME/agsbx/port_vl_re" ]; then
port_vl_re=$(shuf -i 10000-65535 -n 1)
echo "$port_vl_re" > "$HOME/agsbx/port_vl_re"
elif [ -n "$port_vl_re" ]; then
echo "$port_vl_re" > "$HOME/agsbx/port_vl_re"
fi
port_vl_re=$(cat "$HOME/agsbx/port_vl_re")
echo "Vless-tcp-reality-v端口：$port_vl_re"
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
            "tag":"reality-vision",
            "listen": "::",
            "port": $port_vl_re,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "fingerprint": "chrome",
                    "dest": "${ym_vl_re}:443",
                    "serverNames": [
                      "${ym_vl_re}"
                    ],
                    "privateKey": "$private_key_x",
                    "shortIds": ["$short_id_x"]
                }
            },
          "sniffing": {
          "enabled": true,
          "destOverride": ["http", "tls", "quic"],
          "metadataOnly": false
      }
    },  
EOF
else
vlp=vlptargo
fi
}

installsb(){
echo
echo "=========启用Sing-box内核========="
if [ ! -e "$HOME/agsbx/sing-box" ]; then
upsingbox
fi
cat > "$HOME/agsbx/sb.json" <<EOF
{
"log": {
    "disabled": false,
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
EOF
insuuid
if [ ! -f "$HOME/agsbx/SHA256.txt" ]; then
command -v openssl >/dev/null 2>&1 && openssl ecparam -genkey -name prime256v1 -out "$HOME/agsbx/private.key" >/dev/null 2>&1
command -v openssl >/dev/null 2>&1 && openssl req -new -x509 -days 36500 -key "$HOME/agsbx/private.key" -out "$HOME/agsbx/cert.crt" -subj "/CN=www.bing.com" >/dev/null 2>&1
#if [ ! -f "$HOME/agsbx/private.key" ]; then
#echo "fc6dca8cfc4081102aa9655d0d4805c27d7266f605541d242ad66ad00a284a35" > "$HOME/agsbx/SHA256.txt"
#else
SHA256=$(openssl x509 -in $HOME/agsbx/cert.crt -outform DER | sha256sum | awk '{print $1}')
echo "$SHA256" > "$HOME/agsbx/SHA256.txt"
#fi
fi
if [ -n "$hyp" ]; then
hyp=hypt
if [ -z "$port_hy2" ] && [ ! -e "$HOME/agsbx/port_hy2" ]; then
port_hy2=$(shuf -i 10000-65535 -n 1)
echo "$port_hy2" > "$HOME/agsbx/port_hy2"
elif [ -n "$port_hy2" ]; then
echo "$port_hy2" > "$HOME/agsbx/port_hy2"
fi
port_hy2=$(cat "$HOME/agsbx/port_hy2")
echo "Hysteria2端口：$port_hy2"
cat >> "$HOME/agsbx/sb.json" <<EOF
    {
        "type": "hysteria2",
        "tag": "hy2-sb",
        "listen": "::",
        "listen_port": ${port_hy2},
        "users": [
            {
                "password": "${uuid}"
            }
        ],
        "ignore_client_bandwidth":false,
        "tls": {
            "enabled": true,
            "alpn": [
                "h3"
            ],
            "certificate_path": "$HOME/agsbx/cert.crt",
            "key_path": "$HOME/agsbx/private.key"
        }
    },
EOF
else
hyp=hyptargo
fi
if [ -n "$tup" ]; then
tup=tupt
if [ -z "$port_tu" ] && [ ! -e "$HOME/agsbx/port_tu" ]; then
port_tu=$(shuf -i 10000-65535 -n 1)
echo "$port_tu" > "$HOME/agsbx/port_tu"
elif [ -n "$port_tu" ]; then
echo "$port_tu" > "$HOME/agsbx/port_tu"
fi
port_tu=$(cat "$HOME/agsbx/port_tu")
echo "Tuic端口：$port_tu"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"tuic",
            "tag": "tuic5-sb",
            "listen": "::",
            "listen_port": ${port_tu},
            "users": [
                {
                    "uuid": "${uuid}",
                    "password": "${uuid}"
                }
            ],
            "congestion_control": "bbr",
            "tls":{
                "enabled": true,
                "alpn": [
                    "h3"
                ],
                "certificate_path": "$HOME/agsbx/cert.crt",
                "key_path": "$HOME/agsbx/private.key"
            }
        },
EOF
else
tup=tuptargo
fi
if [ -n "$anp" ]; then
anp=anpt
if [ -z "$port_an" ] && [ ! -e "$HOME/agsbx/port_an" ]; then
port_an=$(shuf -i 10000-65535 -n 1)
echo "$port_an" > "$HOME/agsbx/port_an"
elif [ -n "$port_an" ]; then
echo "$port_an" > "$HOME/agsbx/port_an"
fi
port_an=$(cat "$HOME/agsbx/port_an")
echo "Anytls端口：$port_an"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anytls-sb",
            "listen":"::",
            "listen_port":${port_an},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls":{
                "enabled": true,
                "certificate_path": "$HOME/agsbx/cert.crt",
                "key_path": "$HOME/agsbx/private.key"
            }
        },
EOF
else
anp=anptargo
fi
if [ -n "$arp" ]; then
arp=arpt
if [ -z "$ym_vl_re" ]; then
ym_vl_re=apple.com
fi
echo "$ym_vl_re" > "$HOME/agsbx/ym_vl_re"
echo "Reality域名：$ym_vl_re"
mkdir -p "$HOME/agsbx/sbk"
if [ ! -e "$HOME/agsbx/sbk/private_key" ]; then
key_pair=$("$HOME/agsbx/sing-box" generate reality-keypair)
private_key=$(echo "$key_pair" | awk '/PrivateKey/ {print $2}' | tr -d '"')
public_key=$(echo "$key_pair" | awk '/PublicKey/ {print $2}' | tr -d '"')
short_id=$("$HOME/agsbx/sing-box" generate rand --hex 4)
echo "$private_key" > "$HOME/agsbx/sbk/private_key"
echo "$public_key" > "$HOME/agsbx/sbk/public_key"
echo "$short_id" > "$HOME/agsbx/sbk/short_id"
fi
private_key_s=$(cat "$HOME/agsbx/sbk/private_key")
public_key_s=$(cat "$HOME/agsbx/sbk/public_key")
short_id_s=$(cat "$HOME/agsbx/sbk/short_id")
if [ -z "$port_ar" ] && [ ! -e "$HOME/agsbx/port_ar" ]; then
port_ar=$(shuf -i 10000-65535 -n 1)
echo "$port_ar" > "$HOME/agsbx/port_ar"
elif [ -n "$port_ar" ]; then
echo "$port_ar" > "$HOME/agsbx/port_ar"
fi
port_ar=$(cat "$HOME/agsbx/port_ar")
echo "Any-Reality端口：$port_ar"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type":"anytls",
            "tag":"anyreality-sb",
            "listen":"::",
            "listen_port":${port_ar},
            "users":[
                {
                  "password":"${uuid}"
                }
            ],
            "padding_scheme":[],
            "tls": {
            "enabled": true,
            "server_name": "${ym_vl_re}",
             "reality": {
              "enabled": true,
              "handshake": {
              "server": "${ym_vl_re}",
              "server_port": 443
             },
             "private_key": "$private_key_s",
             "short_id": ["$short_id_s"]
            }
          }
        },
EOF
else
arp=arptargo
fi
if [ -n "$ssp" ]; then
ssp=sspt
if [ ! -e "$HOME/agsbx/sskey" ]; then
sskey=$("$HOME/agsbx/sing-box" generate rand 16 --base64)
echo "$sskey" > "$HOME/agsbx/sskey"
fi
if [ -z "$port_ss" ] && [ ! -e "$HOME/agsbx/port_ss" ]; then
port_ss=$(shuf -i 10000-65535 -n 1)
echo "$port_ss" > "$HOME/agsbx/port_ss"
elif [ -n "$port_ss" ]; then
echo "$port_ss" > "$HOME/agsbx/port_ss"
fi
sskey=$(cat "$HOME/agsbx/sskey")
port_ss=$(cat "$HOME/agsbx/port_ss")
echo "Shadowsocks-2022端口：$port_ss"
cat >> "$HOME/agsbx/sb.json" <<EOF
        {
            "type": "shadowsocks",
            "tag":"ss-2022",
            "listen": "::",
            "listen_port": $port_ss,
            "method": "2022-blake3-aes-128-gcm",
            "password": "$sskey"
    },  
EOF
else
ssp=ssptargo
fi
}

xrsbvm(){
if [ -n "$vmp" ]; then
vmp=vmpt
if [ -z "$port_vm_ws" ] && [ ! -e "$HOME/agsbx/port_vm_ws" ]; then
port_vm_ws=$(shuf -i 10000-65535 -n 1)
echo "$port_vm_ws" > "$HOME/agsbx/port_vm_ws"
elif [ -n "$port_vm_ws" ]; then
echo "$port_vm_ws" > "$HOME/agsbx/port_vm_ws"
fi
port_vm_ws=$(cat "$HOME/agsbx/port_vm_ws")
echo "Vmess-ws端口：$port_vm_ws"
if [ -n "$cdnym" ]; then
echo "$cdnym" > "$HOME/agsbx/cdnym"
echo "80系CDN或者回源CDN的host域名 (确保IP已解析在CF域名)：$cdnym"
fi
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
            "tag": "vmess-xr",
            "listen": "::",
            "port": ${port_vm_ws},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${uuid}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                  "path": "${uuid}-vm"
            }
        },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/agsbx/sb.json" <<EOF
{
        "type": "vmess",
        "tag": "vmess-sb",
        "listen": "::",
        "listen_port": ${port_vm_ws},
        "users": [
            {
                "uuid": "${uuid}",
                "alterId": 0
            }
        ],
        "transport": {
            "type": "ws",
            "path": "${uuid}-vm",
            "max_early_data":2048,
            "early_data_header_name": "Sec-WebSocket-Protocol"
        }
    },
EOF
fi
else
vmp=vmptargo
fi
}

xrsbso(){
if [ -n "$sop" ]; then
sop=sopt
if [ -z "$port_so" ] && [ ! -e "$HOME/agsbx/port_so" ]; then
port_so=$(shuf -i 10000-65535 -n 1)
echo "$port_so" > "$HOME/agsbx/port_so"
elif [ -n "$port_so" ]; then
echo "$port_so" > "$HOME/agsbx/port_so"
fi
port_so=$(cat "$HOME/agsbx/port_so")
inssocks5auth
echo "Socks5端口：$port_so"
if [ -e "$HOME/agsbx/xr.json" ]; then
cat >> "$HOME/agsbx/xr.json" <<EOF
        {
         "tag": "socks5-xr",
         "port": ${port_so},
         "listen": "::",
         "protocol": "socks",
         "settings": {
            "auth": "password",
             "accounts": [
               {
               "user": "${socks5_auth}",
               "pass": "${socks5_auth}"
               }
            ],
            "udp": true
          },
            "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls", "quic"],
            "metadataOnly": false
            }
         }, 
EOF
else
cat >> "$HOME/agsbx/sb.json" <<EOF
    {
      "tag": "socks5-sb",
      "type": "socks",
      "listen": "::",
      "listen_port": ${port_so},
      "users": [
      {
      "username": "${socks5_auth}",
      "password": "${socks5_auth}"
      }
     ]
    },
EOF
fi
else
sop=soptargo
fi
}

xrsbout(){
if [ -e "$HOME/agsbx/xr.json" ]; then
sed -i '${s/,\s*$//}' "$HOME/agsbx/xr.json"
cat >> "$HOME/agsbx/xr.json" <<EOF
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct",
      "settings": {
      "domainStrategy":"${xryx}"
     }
    },
    {
      "tag": "x-warp-out",
      "protocol": "wireguard",
      "settings": {
        "secretKey": "${pvk}",
        "address": [
          "172.16.0.2/32",
          "${wpv6}/128"
        ],
        "peers": [
          {
            "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
            "allowedIPs": [
              "0.0.0.0/0",
              "::/0"
            ],
            "endpoint": "${xendip}:2408"
          }
        ],
        "reserved": ${res}
        }
    },
    {
      "tag":"warp-out",
      "protocol":"freedom",
        "settings":{
        "domainStrategy":"${wxryx}"
       },
       "proxySettings":{
       "tag":"x-warp-out"
     }
}
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": [ ${xip} ],
        "network": "tcp,udp",
        "outboundTag": "${x1outtag}"
      },
      {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "${x2outtag}"
      }
    ]
  }
}
EOF
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/xr.service <<EOF
[Unit]
Description=xr service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/agsbx/xray run -c /root/agsbx/xr.json
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable xr >/dev/null 2>&1
systemctl start xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/xray <<EOF
#!/sbin/openrc-run
description="xr service"
command="/root/agsbx/xray"
command_args="run -c /root/agsbx/xr.json"
command_background=yes
pidfile="/run/xray.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/xray >/dev/null 2>&1
rc-update add xray default >/dev/null 2>&1
rc-service xray start >/dev/null 2>&1
else
nohup "$HOME/agsbx/xray" run -c "$HOME/agsbx/xr.json" >/dev/null 2>&1 &
fi
fi
if [ -e "$HOME/agsbx/sb.json" ]; then
sed -i '${s/,\s*$//}' "$HOME/agsbx/sb.json"
cat >> "$HOME/agsbx/sb.json" <<EOF
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "endpoints": [
    {
      "type": "wireguard",
      "tag": "warp-out",
      "address": [
        "172.16.0.2/32",
        "${wpv6}/128"
      ],
      "private_key": "${pvk}",
      "peers": [
        {
          "address": "${sendip}",
          "port": 2408,
          "public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
          "allowed_ips": [
            "0.0.0.0/0",
            "::/0"
          ],
          "reserved": $res
        }
      ]
    }
  ],
  "route": {
    "rules": [
       {
          "action": "sniff"
        },
       {
        "action": "resolve",
         "strategy": "${sbyx}"
       },
      {
        "ip_cidr": [ ${sip} ],         
        "outbound": "${s1outtag}"
      }
    ],
    "final": "${s2outtag}"
  }
}
EOF
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/sb.service <<EOF
[Unit]
Description=sb service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/agsbx/sing-box run -c /root/agsbx/sb.json
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable sb >/dev/null 2>&1
systemctl start sb >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/sing-box <<EOF
#!/sbin/openrc-run
description="sb service"
command="/root/agsbx/sing-box"
command_args="run -c /root/agsbx/sb.json"
command_background=yes
pidfile="/run/sing-box.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/sing-box >/dev/null 2>&1
rc-update add sing-box default >/dev/null 2>&1
rc-service sing-box start >/dev/null 2>&1
else
nohup "$HOME/agsbx/sing-box" run -c "$HOME/agsbx/sb.json" >/dev/null 2>&1 &
fi
fi
}
ins(){
if [ "$hyp" != yes ] && [ "$tup" != yes ] && [ "$anp" != yes ] && [ "$arp" != yes ] && [ "$ssp" != yes ]; then
installxray
xrsbvm
xrsbso
warpsx
xrsbout
hyp="hyptargo"; tup="tuptargo"; anp="anptargo"; arp="arptargo"; ssp="ssptargo"
elif [ "$xhp" != yes ] && [ "$vlp" != yes ] && [ "$vxp" != yes ] && [ "$vwp" != yes ]; then
installsb
xrsbvm
xrsbso
warpsx
xrsbout
xhp="xhptargo"; vlp="vlptargo"; vxp="vxptargo"; vwp="vwptargo"
else
installsb
installxray
xrsbvm
xrsbso
warpsx
xrsbout
fi
if [ -n "$argo" ] && [ -n "$vmag" ]; then
echo
echo "=========启用Cloudflared-argo内核========="
if [ ! -e "$HOME/agsbx/cloudflared" ]; then
argocore=$({ command -v curl >/dev/null 2>&1 && curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared || wget -qO- https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared; } | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载Cloudflared-argo最新正式版内核：$argocore"
url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cpu"; out="$HOME/agsbx/cloudflared"; (command -v curl>/dev/null 2>&1 && curl -Lo "$out" -# --retry 2 "$url") || (command -v wget>/dev/null 2>&1 && timeout 3 wget -O "$out" --tries=2 "$url")
chmod +x "$HOME/agsbx/cloudflared"
fi
if [ "$argo" = "vmpt" ]; then argoport=$(cat "$HOME/agsbx/port_vm_ws" 2>/dev/null); echo "Vmess" > "$HOME/agsbx/vlvm"; elif [ "$argo" = "vwpt" ]; then argoport=$(cat "$HOME/agsbx/port_vw" 2>/dev/null); echo "Vless" > "$HOME/agsbx/vlvm"; fi; echo "$argoport" > "$HOME/agsbx/argoport.log"
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argoname='固定'
if pidof systemd >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/systemd/system/argo.service <<EOF
[Unit]
Description=argo service
After=network.target
[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/root/agsbx/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${ARGO_AUTH}"
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable argo >/dev/null 2>&1
systemctl start argo >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1 && [ "$EUID" -eq 0 ]; then
cat > /etc/init.d/argo <<EOF
#!/sbin/openrc-run
description="argo service"
command="/root/agsbx/cloudflared tunnel"
command_args="--no-autoupdate --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH}"
pidfile="/run/argo.pid"
command_background="yes"
depend() {
need net
}
EOF
chmod +x /etc/init.d/argo >/dev/null 2>&1
rc-update add argo default >/dev/null 2>&1
rc-service argo start >/dev/null 2>&1
else
nohup "$HOME/agsbx/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${ARGO_AUTH}" >/dev/null 2>&1 &
fi
echo "${ARGO_DOMAIN}" > "$HOME/agsbx/sbargoym.log"
echo "${ARGO_AUTH}" > "$HOME/agsbx/sbargotoken.log"
else
argoname='临时'
nohup "$HOME/agsbx/cloudflared" tunnel --url http://localhost:$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/agsbx/argo.log 2>&1 &
fi
echo "申请Argo$argoname隧道中……请稍等"
sleep 15
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argodomain=$(cat "$HOME/agsbx/sbargoym.log" 2>/dev/null)
else
argodomain=$(grep -a trycloudflare.com "$HOME/agsbx/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [ -n "${argodomain}" ]; then
echo "Argo$argoname隧道申请成功"
else
echo "Argo$argoname隧道申请失败，请稍后再试"
fi
fi
sleep 5
echo
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' || pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1 ; then
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/agsbx/d' ~/.bashrc
sed -i '/proxy/d' ~/.bashrc
SCRIPT_PATH="$HOME/bin/proxy"
mkdir -p "$HOME/bin"
(command -v curl >/dev/null 2>&1 && curl -sL "$proxyurl" -o "$SCRIPT_PATH") || (command -v wget >/dev/null 2>&1 && wget -qO "$SCRIPT_PATH" "$proxyurl")
chmod +x "$SCRIPT_PATH"
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo "if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' && ! pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1; then echo '检测到系统可能中断过，或者变量格式错误？建议在SSH对话框输入 reboot 重启下服务器。现在自动执行一键节点脚本的节点恢复操作，请稍等……'; sleep 6; export cfip="${cfip}" hyjpt="${hyjpt}" cdnym="${cdnym}" name="${name}" ippz="${ippz}" argo="${argo}" uuid="${uuid}" $wap="${warp}" $xhp="${port_xh}" $vxp="${port_vx}" $ssp="${port_ss}" $sop="${port_so}" $anp="${port_an}" $arp="${port_ar}" $vlp="${port_vl_re}" $vwp="${port_vw}" $vmp="${port_vm_ws}" $hyp="${port_hy2}" $tup="${port_tu}" reym="${ym_vl_re}" agn="${ARGO_DOMAIN}" agk="${ARGO_AUTH}"; bash "$HOME/bin/proxy"; fi" >> ~/.bashrc
fi
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
grep -qxF 'source ~/.bashrc' ~/.bash_profile 2>/dev/null || echo 'source ~/.bashrc' >> ~/.bash_profile
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
sed -i '/agsbx\/sing-box/d' /tmp/crontab.tmp
sed -i '/agsbx\/xray/d' /tmp/crontab.tmp
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsbx/s' || pgrep -f 'agsbx/s' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/sing-box run -c $HOME/agsbx/sb.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
if find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsbx/x' || pgrep -f 'agsbx/x' >/dev/null 2>&1 ; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/xray run -c $HOME/agsbx/xr.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
fi
sed -i '/agsbx\/cloudflared/d' /tmp/crontab.tmp
if [ -n "$argo" ] && [ -n "$vmag" ]; then
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
if ! pidof systemd >/dev/null 2>&1 && ! command -v rc-service >/dev/null 2>&1; then
echo '@reboot sleep 10 && /bin/sh -c "nohup $HOME/agsbx/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat $HOME/agsbx/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
fi
else
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpineargosbx.start <<EOF
#!/bin/bash
sleep 10
nohup $HOME/agsbx/cloudflared tunnel --url http://localhost:\$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/agsbx/argo.log 2>&1 &
sleep 10
HOME="$HOME" $HOME/bin/proxy list >/dev/null 2>&1
EOF
chmod +x /etc/local.d/alpineargosbx.start
rc-update add local default >/dev/null 2>&1
else
echo '@reboot sleep 10 && /bin/bash -c "nohup $HOME/agsbx/cloudflared tunnel --url http://localhost:$(cat $HOME/agsbx/argoport.log) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/agsbx/argo.log 2>&1 & sleep 10 && bash $HOME/bin/proxy list >/dev/null 2>&1"' >> /tmp/crontab.tmp
fi
fi
fi
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
echo "一键节点脚本生成" && sleep 2
else
echo "一键节点脚本生成" && exit
fi
if [ -n "$cfip" ]; then
set -- $cfip
cdnip1="$1"
cdnip2="$2"
echo "$cdnip1" > "$HOME/agsbx/cdnip1"
echo "$cdnip2" > "$HOME/agsbx/cdnip2"
else
if [ -s "$HOME/agsbx/cdnip1" ] && [ -s "$HOME/agsbx/cdnip2" ]; then
cdnip1=$(cat "$HOME/agsbx/cdnip1")
cdnip2=$(cat "$HOME/agsbx/cdnip2")
else
cdnip1="cdn1.YOUR_CDN_DOMAIN"
cdnip2="cdn6.YOUR_CDN_DOMAIN"
fi
fi
}
argosbxstatus(){
echo "=========当前三大内核运行状态========="
procs=$(find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null)
if echo "$procs" | grep -Eq 'agsbx/s' || pgrep -f 'agsbx/s' >/dev/null 2>&1; then
echo "Sing-box (版本V$("$HOME/agsbx/sing-box" version 2>/dev/null | awk '/version/{print $NF}'))：运行中"
else
echo "Sing-box：未启用"
fi
if echo "$procs" | grep -Eq 'agsbx/x' || pgrep -f 'agsbx/x' >/dev/null 2>&1; then
echo "Xray (版本V$("$HOME/agsbx/xray" version 2>/dev/null | awk '/^Xray/{print $2}'))：运行中"
else
echo "Xray：未启用"
fi
if echo "$procs" | grep -Eq 'agsbx/c' || pgrep -f 'agsbx/c' >/dev/null 2>&1; then
echo "Argo (版本V$("$HOME/agsbx/cloudflared" version 2>/dev/null | awk '{print $3}'))：运行中"
else
echo "Argo：未启用"
fi
}
cip(){
ipbest(){
serip=$( (command -v curl >/dev/null 2>&1 && (curl -s4m5 -k "$v46url" 2>/dev/null || curl -s6m5 -k "$v46url" 2>/dev/null) ) || (command -v wget >/dev/null 2>&1 && (timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null || timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) ) )
if echo "$serip" | grep -q ':'; then
server_ip="[$serip]"
echo "$server_ip" > "$HOME/agsbx/server_ip.log"
else
server_ip="$serip"
echo "$server_ip" > "$HOME/agsbx/server_ip.log"
fi
}
set_node_hostname(){
node_ip="$server_ip"
node_ip=${node_ip#\[}
node_ip=${node_ip%\]}
node_country=""
if command -v curl >/dev/null 2>&1; then
node_country=$(curl -s --max-time 5 "http://ip-api.com/json/${node_ip}?fields=country&lang=zh-CN" 2>/dev/null | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
elif command -v wget >/dev/null 2>&1; then
node_country=$(timeout 5 wget -qO- "http://ip-api.com/json/${node_ip}?fields=country&lang=zh-CN" 2>/dev/null | sed -n 's/.*"country"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi
[ -z "$node_country" ] && node_country=$(printf '%s' "$location" | awk '{print $1}')
[ -z "$node_country" ] && node_country="未知"
node_country=$(printf '%s' "$node_country" | sed 's/[[:space:]]//g')
hostname="${node_country}-${node_ip}"
echo "$hostname" > "$HOME/agsbx/node_name"
}
ipchange(){
v4v6
if [ -z "$v4" ]; then
vps_ipv4='无IPV4'
vps_ipv6="$v6"
location="$v6dq"
elif [ -n "$v4" ] && [ -n "$v6" ]; then
vps_ipv4="$v4"
vps_ipv6="$v6"
location="$v4dq"
else
vps_ipv4="$v4"
vps_ipv6='无IPV6'
location="$v4dq"
fi
if echo "$v6" | grep -q '^2a09'; then
w6="【WARP】"
fi
if echo "$v4" | grep -q '^104.28'; then
w4="【WARP】"
fi
echo
argosbxstatus
echo
echo "=========当前服务器本地IP情况========="
echo "本地IPV4地址：$vps_ipv4 $w4"
echo "本地IPV6地址：$vps_ipv6 $w6"
echo "服务器地区：$location"
echo
sleep 2
if [ "$ippz" = "4" ]; then
if [ -z "$v4" ]; then
ipbest
else
server_ip="$v4"
echo "$server_ip" > "$HOME/agsbx/server_ip.log"
fi
elif [ "$ippz" = "6" ]; then
if [ -z "$v6" ]; then
ipbest
else
server_ip="[$v6]"
echo "$server_ip" > "$HOME/agsbx/server_ip.log"
fi
else
ipbest
fi
}
ipchange
rm -rf "$HOME/agsbx/jhsub.txt"
uuid=$(cat "$HOME/agsbx/uuid")
server_ip=$(cat "$HOME/agsbx/server_ip.log")
set_node_hostname
sxname=$(cat "$HOME/agsbx/name" 2>/dev/null)
xvvmcdnym=$(cat "$HOME/agsbx/cdnym" 2>/dev/null)
echo "*********************************************************"
echo "*********************************************************"
echo "一键节点脚本生成"
echo
case "$server_ip" in
104.28*|\[2a09*) echo "检测到有WARP的IP作为客户端地址 (104.28或者2a09开头的IP)，请把客户端地址上的WARP的IP手动更换为VPS本地IPV4或者IPV6地址" && sleep 3 ;;
esac
echo
ym_vl_re=$(cat "$HOME/agsbx/ym_vl_re" 2>/dev/null)
cfipsj() { echo $((RANDOM % 13 + 1)); }
if [ -e "$HOME/agsbx/xray" ]; then
private_key_x=$(cat "$HOME/agsbx/xrk/private_key" 2>/dev/null)
public_key_x=$(cat "$HOME/agsbx/xrk/public_key" 2>/dev/null)
short_id_x=$(cat "$HOME/agsbx/xrk/short_id" 2>/dev/null)
enkey=$(cat "$HOME/agsbx/xrk/enkey" 2>/dev/null)
fi
if [ -e "$HOME/agsbx/sing-box" ]; then
private_key_s=$(cat "$HOME/agsbx/sbk/private_key" 2>/dev/null)
public_key_s=$(cat "$HOME/agsbx/sbk/public_key" 2>/dev/null)
short_id_s=$(cat "$HOME/agsbx/sbk/short_id" 2>/dev/null)
sskey=$(cat "$HOME/agsbx/sskey" 2>/dev/null)
fi
if grep xhttp-reality "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
print_section "Vless XHTTP Reality ENC"
port_xh=$(cat "$HOME/agsbx/port_xh")
vl_xh_link="vless://$uuid@$server_ip:$port_xh?encryption=$enkey&flow=xtls-rprx-vision&security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=xhttp&path=$uuid-xh&mode=auto#$hostname"
echo "$vl_xh_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_xh_link"
fi
if grep vless-xhttp "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
print_section "Vless XHTTP ENC"
port_vx=$(cat "$HOME/agsbx/port_vx")
vl_vx_link="vless://$uuid@$server_ip:$port_vx?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&path=$uuid-vx&mode=auto#$hostname"
echo "$vl_vx_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_vx_link"
if [ -f "$HOME/agsbx/cdnym" ]; then
print_section "Vless XHTTP ENC CDN"
echo "Tip: replace cdn*.YOUR_CDN_DOMAIN with your CDN domain if needed."
vl_vx_cdn_link="vless://$uuid@cdn$(cfipsj).YOUR_CDN_DOMAIN:$port_vx?encryption=$enkey&flow=xtls-rprx-vision&type=xhttp&host=$xvvmcdnym&path=$uuid-vx&mode=auto#$hostname"
echo "$vl_vx_cdn_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_vx_cdn_link"
fi
fi
if grep vless-ws "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
print_section "Vless WS ENC"
port_vw=$(cat "$HOME/agsbx/port_vw")
vl_vw_link="vless://$uuid@$server_ip:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&path=$uuid-vw#$hostname"
echo "$vl_vw_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_vw_link"
if [ -f "$HOME/agsbx/cdnym" ]; then
print_section "Vless WS ENC CDN"
echo "Tip: replace cdn*.YOUR_CDN_DOMAIN with your CDN domain if needed."
vl_vw_cdn_link="vless://$uuid@cdn$(cfipsj).YOUR_CDN_DOMAIN:$port_vw?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$xvvmcdnym&path=$uuid-vw#$hostname"
echo "$vl_vw_cdn_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_vw_cdn_link"
fi
fi
if grep reality-vision "$HOME/agsbx/xr.json" >/dev/null 2>&1; then
print_section "Vless TCP Reality Vision"
port_vl_re=$(cat "$HOME/agsbx/port_vl_re")
vl_link="vless://$uuid@$server_ip:$port_vl_re?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_x&sid=$short_id_x&type=tcp&headerType=none#$hostname"
echo "$vl_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vl_link"
sbvlpt(){
cat <<EOF
    {
      "type": "vless",
      "tag": "$hostname",
      "server": "$server_ip",
      "server_port": $port_vl_re,
      "uuid": "$uuid",
      "flow": "xtls-rprx-vision",
      "tls": {
        "enabled": true,
        "server_name": "$ym_vl_re",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key_x",
          "short_id": "$short_id_x"
        }
      }
    },
EOF
}
sbvlpt1(){
echo ""$hostname","
}
clvlpt(){
cat <<EOF
- name: $hostname               
  type: vless
  server: $server_ip                          
  port: $port_vl_re                                
  uuid: $uuid   
  network: tcp
  udp: true
  tls: true
  flow: xtls-rprx-vision
  servername: $ym_vl_re                 
  reality-opts: 
    public-key: $public_key_x    
    short-id: $short_id_x                      
  client-fingerprint: chrome
EOF
}
clvlpt1(){
echo "- $hostname"
}
fi
if grep ss-2022 "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "Shadowsocks 2022"
port_ss=$(cat "$HOME/agsbx/port_ss")
ss_userinfo=$(printf '%s' "2022-blake3-aes-128-gcm:$sskey" | base64 | tr -d '\n' | tr '+/' '-_' | tr -d '=')
ss_link="ss://${ss_userinfo}@${server_ip}:${port_ss}#$hostname"
echo "$ss_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$ss_link"
sbsspt(){
cat <<EOF
{
       "type": "shadowsocks",
       "tag": "$hostname",
       "server": "$server_ip",
       "server_port": $port_ss,
       "method": "2022-blake3-aes-128-gcm",
       "password": "$sskey",
       "udp_over_tcp": {
        "enabled": true,
        "version": 2
      }
     },
EOF
}
sbsspt1(){
echo ""$hostname","
}
clsspt(){
cat <<EOF
- name: "$hostname"
  type: ss
  server: $server_ip
  port: $port_ss
  cipher: 2022-blake3-aes-128-gcm
  password: "$sskey"
  udp: true
  udp-over-tcp: true
  udp-over-tcp-version: 2
EOF
}
clsspt1(){
echo "- $hostname"
}
fi
if grep vmess-xr "$HOME/agsbx/xr.json" >/dev/null 2>&1 || grep vmess-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "Vmess WS"
port_vm_ws=$(cat "$HOME/agsbx/port_vm_ws")
vm_link="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "$server_ip", "port": "$port_vm_ws", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "www.bing.com", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vm_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vm_link"
sbvmpt(){
cat <<EOF
{
            "server": "$server_ip",
            "server_port": $port_vm_ws,
            "tag": "$hostname",
            "tls": {
                "enabled": false,
                "server_name": "www.bing.com",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "www.bing.com"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF
}
sbvmpt1(){
echo ""$hostname","
}
clvmpt(){
cat <<EOF
- name: $hostname                         
  type: vmess
  server: $server_ip                        
  port: $port_vm_ws                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: www.bing.com                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: www.bing.com
EOF
}
clvmpt1(){
echo "- $hostname"
}
if [ -f "$HOME/agsbx/cdnym" ]; then
print_section "Vmess WS CDN"
echo "Tip: replace cdn*.YOUR_CDN_DOMAIN with your CDN domain if needed."
vm_cdn_link="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn$(cfipsj).YOUR_CDN_DOMAIN", "port": "$port_vm_ws", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$xvvmcdnym", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vm_cdn_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$vm_cdn_link"
fi
fi
if grep anytls-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "AnyTLS"
port_an=$(cat "$HOME/agsbx/port_an")
an_link="anytls://$uuid@$server_ip:$port_an?insecure=1&allowInsecure=1#$hostname"
echo "$an_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$an_link"
sbanpt(){
cat <<EOF
         {
            "type": "anytls",
            "tag": "$hostname",
            "server": "$server_ip",
            "server_port": $port_an,
            "password": "$uuid",
            "idle_session_check_interval": "30s",
            "idle_session_timeout": "30s",
            "min_idle_session": 5,
            "tls": {
                "enabled": true,
                "insecure": true,
                "server_name": "www.bing.com"
            }
         },
EOF
}
sbanpt1(){
echo ""$hostname","
}
clanpt(){
cat <<EOF
- name: $hostname
  type: anytls
  server: $server_ip
  port: $port_an
  password: $uuid
  client-fingerprint: chrome
  udp: true
  idle-session-check-interval: 30
  idle-session-timeout: 30
  sni: www.bing.com
  skip-cert-verify: true
EOF
}
clanpt1(){
echo "- $hostname"
}
fi
if grep anyreality-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "AnyTLS Reality"
port_ar=$(cat "$HOME/agsbx/port_ar")
ar_link="anytls://$uuid@$server_ip:$port_ar?security=reality&sni=$ym_vl_re&fp=chrome&pbk=$public_key_s&sid=$short_id_s&type=tcp&headerType=none#$hostname"
echo "$ar_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$ar_link"
sbarpt(){
cat <<EOF
    {
        "type": "anytls",
        "tag": "$hostname",
        "server": "$server_ip",
        "server_port": $port_ar,
        "password": "$uuid",
        "idle_session_check_interval": "30s",
        "idle_session_timeout": "30s",
        "min_idle_session": 5,
        "tls": {
        "enabled": true,
        "server_name": "$ym_vl_re",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
      "reality": {
          "enabled": true,
          "public_key": "$public_key_s",
          "short_id": "$short_id_s"
        }
      }
         },
EOF
}
sbarpt1(){
echo ""$hostname","
}
fi
if grep hy2-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "Hysteria2"
SHA256=$(cat "$HOME/agsbx/SHA256.txt")
port_hy2=$(cat "$HOME/agsbx/port_hy2")
hy2_ports=$(iptables -t nat -nL --line 2>/dev/null | grep -w "$port_hy2" | awk '{print $8}' | sed 's/dpts://; s/dpt://' | tr '\n' ',' | sed 's/,$//')
if [ -n "$hy2_ports" ] || [ -n "$hyjpt" ]; then
echo "Hysteria2跳跃端口已开启：$hy2_ports"
cmhy2pt=$(echo $hy2_ports | tr ':' '-')
hyps="&mport=$cmhy2pt"
sbhy2pt=$(echo "$hy2_ports" | grep -o '[0-9]\+:[0-9]\+' | sed 's/.*/"&"/' | paste -sd,)
sbhy2ports(){
    cat <<EOF
  "server_ports": [ $sbhy2pt ],
EOF
}
else
hyps=
fi
#hy2_link="hysteria2://$uuid@$server_ip:$port_hy2?security=tls&alpn=h3&insecure=1&allowInsecure=1$hyps&sni=www.bing.com#$hostname"
hy2_link="hysteria2://$uuid@$server_ip:$port_hy2?security=tls&alpn=h3&insecure=0&allowInsecure=0$hyps&sni=www.bing.com&pinSHA256=$SHA256#$hostname"
echo "$hy2_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$hy2_link"
sbhypt(){
cat <<EOF
    {
        "type": "hysteria2",
        "tag": "$hostname",
        "server": "$server_ip",
        "server_port": $port_hy2,
$(sbhy2ports 2>/dev/null)
        "password": "$uuid",
        "tls": {
            "enabled": true,
            "server_name": "www.bing.com",
            "insecure": true,
            "alpn": [
                "h3"
            ]
        }
    },
EOF
}
sbhypt1(){
echo ""$hostname","
}
clhypt(){
cat <<EOF
- name: $hostname                            
  type: hysteria2                                      
  server: $server_ip                              
  port: $port_hy2
  ports: $cmhy2pt
  password: $uuid                          
  alpn:
    - h3
  sni: www.bing.com                               
  skip-cert-verify: true
  fast-open: true
EOF
}
clhypt1(){
echo "- $hostname"
}
fi
if grep tuic5-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "Tuic"
port_tu=$(cat "$HOME/agsbx/port_tu")
tuic5_link="tuic://$uuid:$uuid@$server_ip:$port_tu?congestion_control=bbr&udp_relay_mode=native&alpn=h3&sni=www.bing.com&insecure=1&allowInsecure=1&allow_insecure=1#$hostname"
echo "$tuic5_link" >> "$HOME/agsbx/jhsub.txt"
print_link "节点分享链接：" "$tuic5_link"
sbtupt(){
cat <<EOF
        {
            "type":"tuic",
            "tag": "$hostname",
            "server": "$server_ip",
            "server_port": $port_tu,
            "uuid": "$uuid",
            "password": "$uuid",
            "congestion_control": "bbr",
            "udp_relay_mode": "native",
            "udp_over_stream": false,
            "zero_rtt_handshake": false,
            "heartbeat": "10s",
            "tls":{
                "enabled": true,
                "server_name": "www.bing.com",
                "insecure": true,
                "alpn": [
                    "h3"
                ]
            }
        },
EOF
}
sbtupt1(){
echo ""$hostname","
}
cltupt(){
cat <<EOF
- name: $hostname                            
  server: $server_ip                      
  port: $port_tu                                    
  type: tuic
  uuid: $uuid       
  password: $uuid   
  alpn: [h3]
  disable-sni: true
  reduce-rtt: true
  udp-relay-mode: native
  congestion-controller: bbr
  sni: www.bing.com                                
  skip-cert-verify: true
EOF
}
cltupt1(){
echo "- $hostname"
}
fi
if grep socks5-xr "$HOME/agsbx/xr.json" >/dev/null 2>&1 || grep socks5-sb "$HOME/agsbx/sb.json" >/dev/null 2>&1; then
print_section "Socks5"
port_so=$(cat "$HOME/agsbx/port_so")
inssocks5auth
socks5_link="socks://$(printf '%s' "${socks5_auth}:${socks5_auth}" | base64 | tr -d '\n=')@${server_ip}:${port_so}#$hostname"
echo "$socks5_link" >> "$HOME/agsbx/jhsub.txt"
printf '\033[1;33m%s\033[0m\n' "客户端IP：$server_ip"
printf '\033[1;33m%s\033[0m\n' "端口号：$port_so"
printf '\033[1;33m%s\033[0m\n' "用户名：$socks5_auth"
printf '\033[1;33m%s\033[0m\n' "密码：$socks5_auth"
echo "温馨提示：socks5使用一般需要海外环境。"
print_link "节点分享链接：" "$socks5_link"
fi
argodomain=$(cat "$HOME/agsbx/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/agsbx/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -n "$argodomain" ]; then
vlvm=$(cat $HOME/agsbx/vlvm 2>/dev/null)
if [ "$vlvm" = "Vmess" ]; then
vmatls_link1="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "$cdnip1", "port": "443", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link1" >> "$HOME/agsbx/jhsub.txt"
vmatls_link2="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn2.YOUR_CDN_DOMAIN", "port": "8443", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link2" >> "$HOME/agsbx/jhsub.txt"
vmatls_link3="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn3.YOUR_CDN_DOMAIN", "port": "2053", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link3" >> "$HOME/agsbx/jhsub.txt"
vmatls_link4="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn4.YOUR_CDN_DOMAIN", "port": "2083", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link4" >> "$HOME/agsbx/jhsub.txt"
vmatls_link5="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn5.YOUR_CDN_DOMAIN", "port": "2087", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link5" >> "$HOME/agsbx/jhsub.txt"
vmatls_link6="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "[2606:4700::0]", "port": "2096", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": "tls", "sni": "$argodomain", "alpn": "", "fp": "chrome"}" | base64 -w0)"
echo "$vmatls_link6" >> "$HOME/agsbx/jhsub.txt"
vma_link7="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "$cdnip2", "port": "80", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link7" >> "$HOME/agsbx/jhsub.txt"
vma_link8="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn7.YOUR_CDN_DOMAIN", "port": "8080", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link8" >> "$HOME/agsbx/jhsub.txt"
vma_link9="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn8.YOUR_CDN_DOMAIN", "port": "8880", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link9" >> "$HOME/agsbx/jhsub.txt"
vma_link10="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn9.YOUR_CDN_DOMAIN", "port": "2052", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link10" >> "$HOME/agsbx/jhsub.txt"
vma_link11="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn10.YOUR_CDN_DOMAIN", "port": "2082", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link11" >> "$HOME/agsbx/jhsub.txt"
vma_link12="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "cdn11.YOUR_CDN_DOMAIN", "port": "2086", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link12" >> "$HOME/agsbx/jhsub.txt"
vma_link13="vmess://$(echo "{ "v": "2", "ps": "$hostname", "add": "[2400:cb00:2049::0]", "port": "2095", "id": "$uuid", "aid": "0", "scy": "auto", "net": "ws", "type": "none", "host": "$argodomain", "path": "/$uuid-vm", "tls": ""}" | base64 -w0)"
echo "$vma_link13" >> "$HOME/agsbx/jhsub.txt"
sbvmargopt(){
cat <<EOF
{
            "server": "$cdnip1",
            "server_port": 443,
            "tag": "$hostname",
            "tls": {
                "enabled": true,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
{
            "server": "$cdnip2",
            "server_port": 80,
            "tag": "$hostname",
            "tls": {
                "enabled": false,
                "server_name": "$argodomain",
                "insecure": false,
                "utls": {
                    "enabled": true,
                    "fingerprint": "chrome"
                }
            },
            "packet_encoding": "packetaddr",
            "transport": {
                "headers": {
                    "Host": [
                        "$argodomain"
                    ]
                },
                "path": "$uuid-vm",
                "type": "ws"
            },
            "type": "vmess",
            "security": "auto",
            "uuid": "$uuid"
        },
EOF
}
sbvmargopt1(){
echo ""$hostname","
echo ""$hostname","
}
clvmargopt(){
cat <<EOF
- name: $hostname                         
  type: vmess
  server: "$cdnip1"                       
  port: 443                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: true
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: $argodomain
- name: $hostname                         
  type: vmess
  server: "$cdnip2"                        
  port: 80                                     
  uuid: $uuid       
  alterId: 0
  cipher: auto
  udp: true
  tls: false
  network: ws
  servername: $argodomain                    
  ws-opts:
    path: "$uuid-vm"                             
    headers:
      Host: $argodomain
EOF
}
clvmargopt1(){
echo "- $hostname"
echo "- $hostname"
}
elif [ "$vlvm" = "Vless" ]; then
vwatls_link1="vless://$uuid@$cdnip1:443?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=tls&sni=$argodomain&fp=chrome&insecure=0&allowInsecure=0#$hostname"
echo "$vwatls_link1" >> "$HOME/agsbx/jhsub.txt"
vwa_link2="vless://$uuid@$cdnip2:80?encryption=$enkey&flow=xtls-rprx-vision&type=ws&host=$argodomain&path=$uuid-vw&security=none#$hostname"
echo "$vwa_link2" >> "$HOME/agsbx/jhsub.txt"
fi
sbtk=$(cat "$HOME/agsbx/sbargotoken.log" 2>/dev/null)
if [ -n "$sbtk" ]; then
nametn="Argo固定隧道token：$sbtk"
fi
argoshow=$(
echo "Argo隧道端口正在使用$vlvm-ws主协议端口：$(cat $HOME/agsbx/argoport.log 2>/dev/null)
Argo域名：$argodomain
$nametn

1、💣443端口的$vlvm-ws-tls-argo节点(优选IP与443系端口随便换)
${vmatls_link1}${vwatls_link1}

2、💣80端口的$vlvm-ws-argo节点(优选IP与80系端口随便换)
${vma_link7}${vwa_link2}
"
)
fi

get_func() {
local f=$1
if type "$f" >/dev/null 2>&1; then
local out
out=$($f)
[ -n "$out" ] && printf "%s\n" "$out"
fi
}
sbxy="$(get_func sbvlpt; get_func sbsspt; get_func sbanpt; get_func sbarpt; get_func sbvmpt; get_func sbhypt; get_func sbtupt; get_func sbvmargopt)"
clxy="$(get_func clvlpt; get_func clsspt; get_func clanpt; get_func clvmpt; get_func clhypt; get_func cltupt; get_func clvmargopt)"
sbgz="$(get_func sbvlpt1; get_func sbsspt1; get_func sbanpt1; get_func sbarpt1; get_func sbvmpt1; get_func sbhypt1; get_func sbtupt1; get_func sbvmargopt1)"
clgz="$({ get_func clvlpt1; get_func clsspt1; get_func clanpt1; get_func clvmpt1; get_func clhypt1; get_func cltupt1; get_func clvmargopt1; } | sed '2,$s/^/    /')"
sbgz=$(printf "%s\n" "$sbgz" | sed '$ s/,$//')
cat > $HOME/agsbx/sbox.json <<EOF
{
    "log": {
        "disabled": false,
        "level": "info",
        "timestamp": true
    },
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "./cache.db",
            "store_fakeip": true
        },
        "clash_api": {
            "external_controller": "127.0.0.1:9090",
            "external_ui": "ui",
            "default_mode": "Rule"
        }
    },
    "dns": {
        "servers": [
            {
                "tag": "aliDns",
                "type": "https",
                "server": "dns.alidns.com",
                "path": "/dns-query",
                "domain_resolver": "local"
            },
            {
                "tag": "local",
                "type": "udp",
                "server": "223.5.5.5"
            },
            {
                "tag": "proxyDns",
                "type": "https",
                "server": "dns.google",
                "path": "/dns-query",
	              "domain_resolver": "aliDns",
                "detour": "proxy"
            },
           {
        "type": "fakeip",
        "tag": "fakeip",
        "inet4_range": "198.18.0.0/15",
        "inet6_range": "fc00::/18"
      }
        ],
        "rules": [
            {
                "rule_set": "geosite-cn",
                "clash_mode": "Rule",
                "server": "aliDns"
            },
            {
                "clash_mode": "Direct",
                "server": "local"
            },
            {
                "clash_mode": "Global",
                "server": "proxyDns"
            },
            {
        "query_type": [
          "A",
          "AAAA"
        ],
        "server": "fakeip"
      }
        ],
        "final": "proxyDns",
        "strategy": "prefer_ipv4"
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "address": [
                "172.19.0.1/30",
                "fd00::1/126"
            ],
            "auto_route": true,
            "strict_route": true
        }
    ],
    "route": {
        "rules": [
            {
	 "inbound": "tun-in",
                "action": "sniff"
            },
            {
                "type": "logical",
                "mode": "or",
                "rules": [
                    {
                        "port": 53
                    },
                    {
                        "protocol": "dns"
                    }
                ],
                "action": "hijack-dns"
            },
         {
          "clash_mode": "Global",
          "outbound": "proxy"
         },
        {
        "rule_set": "geosite-cn",
        "clash_mode": "Rule",
        "outbound": "direct"
       },
     {
    "rule_set": "geoip-cn",
    "clash_mode": "Rule",
    "outbound": "direct"
      },
     {
    "ip_is_private": true,
    "clash_mode": "Rule",
    "outbound": "direct"
    },
     {
      "clash_mode": "Direct",
      "outbound": "direct"
     }		
        ],
        "rule_set": [
            {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/geolocation-cn.srs",
                "download_detour": "direct"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geoip/cn.srs",
                "download_detour": "direct"
            }
        ],
        "final": "proxy",
        "auto_detect_interface": true,
        "default_domain_resolver": {
        "server": "aliDns"
        }
    },
  "outbounds": [
   $sbxy
        {
            "tag": "proxy",
            "type": "selector",
            "default": "auto",
            "outbounds": [
        "auto",
        $sbgz
            ]
        },
        {
            "tag": "auto",
            "type": "urltest",
            "outbounds": [
            $sbgz
            ],
            "url": "http://www.gstatic.com/generate_204",
            "interval": "10m",
            "tolerance": 50
        },
        {
            "type": "direct",
            "tag": "direct"
        }
    ]
}
EOF

cat > $HOME/agsbx/clmi.yaml <<EOF
port: 7890
allow-lan: true
mode: rule
log-level: info
unified-delay: true
dns:
  enable: true 
  listen: "0.0.0.0:1053"
  ipv6: true
  prefer-h3: false
  respect-rules: true
  use-system-hosts: false
  cache-algorithm: "arc"
  enhanced-mode: "fake-ip"
  fake-ip-range: "198.18.0.1/16"
  fake-ip-filter:
    - "+.lan"
    - "+.local"
    - "+.msftconnecttest.com"
    - "+.msftncsi.com"
    - "localhost.ptlogin2.qq.com"
    - "localhost.sec.qq.com"
    - "+.in-addr.arpa"
    - "+.ip6.arpa"
    - "time.*.com"
    - "time.*.gov"
    - "pool.ntp.org"
    - "localhost.work.weixin.qq.com"
  default-nameserver: ["223.5.5.5", "119.29.29.29"]
  nameserver:
    - "https://1.1.1.1/dns-query"
    - "https://8.8.8.8/dns-query"
  proxy-server-nameserver:
    - "https://223.5.5.5/dns-query"
    - "https://doh.pub/dns-query"

proxies:
$clxy

proxy-groups:
- name: 负载均衡
  type: load-balance
  url: https://www.gstatic.com/generate_204
  interval: 300
  strategy: round-robin
  proxies:
    $clgz
- name: 自动选择
  type: url-test
  url: https://www.gstatic.com/generate_204
  interval: 300
  tolerance: 50
  proxies:
    $clgz 
- name: 🌍选择代理节点
  type: select
  proxies:
    - 负载均衡                                         
    - 自动选择
    - DIRECT
    $clgz
rules:
  - GEOIP,LAN,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,🌍选择代理节点
EOF
echo "---------------------------------------------------------"
echo "$argoshow"
[ -n "$vmatls_link1" ] && print_link "Argo TLS 443 节点分享链接：" "$vmatls_link1"
[ -n "$vwatls_link1" ] && print_link "Argo TLS 443 节点分享链接：" "$vwatls_link1"
[ -n "$vma_link7" ] && print_link "Argo 80 节点分享链接：" "$vma_link7"
[ -n "$vwa_link2" ] && print_link "Argo 80 节点分享链接：" "$vwa_link2"
echo
if [ -s $HOME/agsbx/subport.log ]; then
showsubport=$(cat $HOME/agsbx/subport.log)
if ps -ef 2>/dev/null | grep "$showsubport" | grep -v grep >/dev/null; then
showsubtoken=$(cat $HOME/agsbx/subtoken.log 2>/dev/null)
subip=$(cat $HOME/agsbx/server_ip.log 2>/dev/null)
suburl="$subip:$showsubport/$showsubtoken"
echo "**********************************************************"
echo "Clash/Mihomo本地IP订阅地址：http://$suburl/clmi.yaml"
echo "Sing-box本地IP订阅地址：http://$suburl/sbox.json"
echo "聚合协议本地IP订阅地址：http://$suburl/jhsub.txt"
echo "**********************************************************"
fi
fi
echo
echo "---------------------------------------------------------"
echo "聚合节点文件：$HOME/agsbx/jhsub.txt"
echo "查看节点命令：cat $HOME/agsbx/jhsub.txt"
echo "========================================================="
echo "快捷命令如下："
showmode
}
cleandel(){
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/agsbx/c|/agsbx/s|/agsbx/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null; fi; fi; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) $(pgrep -f 'agsbx/c' 2>/dev/null) $(pgrep -f 'agsbx/x' 2>/dev/null) $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
sed -i '/agsbx/d' ~/.bashrc
sed -i '/proxy/d' ~/.bashrc
sed -i '/export PATH="\$HOME\/bin:\$PATH"/d' ~/.bashrc
. ~/.bashrc 2>/dev/null
crontab -l > /tmp/crontab.tmp 2>/dev/null
sed -i '/agsbx\/sing-box/d' /tmp/crontab.tmp
sed -i '/agsbx\/xray/d' /tmp/crontab.tmp
sed -i '/agsbx\/cloudflared/d' /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
rm -rf "$HOME/bin/proxy" "$HOME/bin/agsbx"
if pidof systemd >/dev/null 2>&1; then
for svc in xr sb argo; do
systemctl stop "$svc" >/dev/null 2>&1
systemctl disable "$svc" >/dev/null 2>&1
done
rm -rf /etc/systemd/system/{xr.service,sb.service,argo.service}
elif command -v rc-service >/dev/null 2>&1; then
for svc in sing-box xray argo; do
rc-service "$svc" stop >/dev/null 2>&1
rc-update del "$svc" default >/dev/null 2>&1
done
rm -rf /etc/init.d/{sing-box,xray,argo} /etc/local.d/alpineargosbx.start /etc/local.d/alpinesubsbx.start
iptables -t nat -F PREROUTING >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
}
xrestart(){
kill -15 $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart xr >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service xray restart >/dev/null 2>&1
else
nohup $HOME/agsbx/xray run -c $HOME/agsbx/xr.json >/dev/null 2>&1 &
fi
}
sbrestart(){
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) >/dev/null 2>&1
if pidof systemd >/dev/null 2>&1; then
systemctl restart sb >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service sing-box restart >/dev/null 2>&1
else
nohup $HOME/agsbx/sing-box run -c $HOME/agsbx/sb.json >/dev/null 2>&1 &
fi
}
if [ "$1" = "del" ]; then
cleandel
rm -rf sbx_update "$HOME/agsbx" "$HOME/websbx"
echo "卸载完成"
echo "欢迎继续使用一键节点脚本生成" && sleep 2
echo
showmode
exit
elif [ "$1" = "rep" ]; then
cleandel
rm -rf "$HOME/agsbx"/{sb.json,xr.json,sbargoym.log,sbargotoken.log,argo.log,argoport.log,cdnym,name}
echo "一键节点脚本生成" && sleep 2
echo
elif [ "$1" = "list" ]; then
cip
exit
elif [ "$1" = "upx" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/agsbx/x"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
upxray && xrestart && echo "Xray内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "ups" ]; then
for P in /proc/[0-9]*; do [ -L "$P/exe" ] || continue; TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue; case "$TARGET" in *"/agsbx/s"*) kill "$(basename "$P")" 2>/dev/null ;; esac; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) >/dev/null 2>&1
upsingbox && sbrestart && echo "Sing-box内核更新完成" && sleep 2 && cip
exit
elif [ "$1" = "res" ]; then
for P in /proc/[0-9]*; do
[ -L "$P/exe" ] || continue
TARGET=$(readlink -f "$P/exe" 2>/dev/null) || continue
case "$TARGET" in
*"/agsbx/s"*)
kill "$(basename "$P")" 2>/dev/null
sbrestart
;;
*"/agsbx/x"*)
kill "$(basename "$P")" 2>/dev/null
xrestart
;;
*"/agsbx/c"*)
kill "$(basename "$P")" 2>/dev/null
kill -15 $(pgrep -f 'agsbx/c' 2>/dev/null) >/dev/null 2>&1
if [ -e "$HOME/agsbx/sbargotoken.log" ]; then
if pidof systemd >/dev/null 2>&1; then
systemctl restart argo >/dev/null 2>&1
elif command -v rc-service >/dev/null 2>&1; then
rc-service argo restart >/dev/null 2>&1
else
nohup $HOME/agsbx/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat $HOME/agsbx/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &
fi
else
nohup $HOME/agsbx/cloudflared tunnel --url http://localhost:$(cat $HOME/agsbx/argoport.log 2>/dev/null) --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/agsbx/argo.log 2>&1 &
fi
;;
esac
done
sleep 5 && echo "重启完成" && sleep 3 && cip
exit
fi
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -Eq 'agsbx/(s|x)' && ! pgrep -f 'agsbx/(s|x)' >/dev/null 2>&1; then
for P in /proc/[0-9]*; do if [ -L "$P/exe" ]; then TARGET=$(readlink -f "$P/exe" 2>/dev/null); if echo "$TARGET" | grep -qE '/agsbx/c|/agsbx/s|/agsbx/x'; then PID=$(basename "$P"); kill "$PID" 2>/dev/null && echo "Killed $PID ($TARGET)" || echo "Could not kill $PID ($TARGET)"; fi; fi; done
kill -15 $(pgrep -f 'agsbx/s' 2>/dev/null) $(pgrep -f 'agsbx/c' 2>/dev/null) $(pgrep -f 'agsbx/x' 2>/dev/null) >/dev/null 2>&1
if [ -z "$( (command -v curl >/dev/null 2>&1 && curl -s4m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -4 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1" > /etc/resolv.conf
fi
if [ -n "$( (command -v curl >/dev/null 2>&1 && curl -s6m5 -k "$v46url" 2>/dev/null) || (command -v wget >/dev/null 2>&1 && timeout 3 wget -6 -qO- --tries=2 "$v46url" 2>/dev/null) )" ]; then
sendip="2606:4700:d0::a29f:c001"
xendip="[2606:4700:d0::a29f:c001]"
else
sendip="162.159.192.1"
xendip="162.159.192.1"
fi
echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "一键节点脚本生成" && sleep 1
if [ -n "$oap" ]; then
setenforce 0 >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -F >/dev/null 2>&1
netfilter-persistent save >/dev/null 2>&1
echo
echo "iptables执行开放所有端口"
fi
ins
if [ -n "$sub" ]; then
subtokenipsub(){
if [ -z "$subid" ]; then
subtoken="$(cat "$HOME/agsbx/uuid")"
else
subtoken="$subid"
fi
rm -rf $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"
echo $subtoken > $HOME/agsbx/subtoken.log
}
subportipsub(){
if [ -z "$subpt" ]; then
if [ -n "$(cat "$HOME/agsbx/subport.log" 2>/dev/null)" ]; then
subport=$(cat $HOME/agsbx/subport.log)
else
subport=$(shuf -i 10000-65535 -n 1)
fi
else
subport="$subpt"
fi
echo $subport > $HOME/agsbx/subport.log
}
subtokenipsub && subportipsub
echo "请稍后…………"
kill -15 $(pgrep -f 'websbx' 2>/dev/null) >/dev/null 2>&1
mkdir -p $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"
ln -sf $HOME/agsbx/clmi.yaml $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/clmi.yaml
ln -sf $HOME/agsbx/sbox.json $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/sbox.json
ln -sf $HOME/agsbx/jhsub.txt $HOME/websbx/"$(cat $HOME/agsbx/subtoken.log 2>/dev/null)"/jhsub.txt
if command -v apk >/dev/null 2>&1; then
busybox-extras httpd -f -p "$(cat $HOME/agsbx/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
else
busybox httpd -f -p "$(cat $HOME/agsbx/subport.log 2>/dev/null)" -h $HOME/websbx > /dev/null 2>&1 &
fi
sleep 5
if command -v apk >/dev/null 2>&1; then
cat > /etc/local.d/alpinesubsbx.start <<EOF
#!/bin/bash
sleep 10
busybox-extras httpd -f -p \$(cat $HOME/agsbx/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &
EOF
chmod +x /etc/local.d/alpinesubsbx.start
rc-update add local default >/dev/null 2>&1
else
crontab -l 2>/dev/null > /tmp/crontab.tmp
sed -i '/websbx/d' /tmp/crontab.tmp
echo '@reboot sleep 10 && /bin/bash -c "busybox httpd -f -p $(cat $HOME/agsbx/subport.log 2>/dev/null) -h $HOME/websbx > /dev/null 2>&1 &"' >> /tmp/crontab.tmp
crontab /tmp/crontab.tmp >/dev/null 2>&1
rm /tmp/crontab.tmp
fi
echo "本地IP订阅链接已更新完成"
fi
if [ -n "$hyjpt" ] && [ -n "$hyp" ]; then
echo
echo "设置Hysteria2协议的跳跃端口：$hyjpt"
iptables -t nat -F PREROUTING >/dev/null 2>&1
ip6tables -t nat -F PREROUTING >/dev/null 2>&1
hyport=$(cat "$HOME/agsbx/port_hy2")
for port in $hyjpt; do
iptables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
ip6tables -t nat -A PREROUTING -p udp --dport "$port" -j DNAT --to-destination :$hyport
done
netfilter-persistent save >/dev/null 2>&1
if command -v rc-service >/dev/null 2>&1 && command -v rc-update >/dev/null 2>&1; then
rc-update show default 2>/dev/null | grep -q 'iptables' || rc-update add iptables >/dev/null 2>&1
rc-update show default 2>/dev/null | grep -q 'ip6tables' || rc-update add ip6tables >/dev/null 2>&1
rc-service iptables save >/dev/null 2>&1
rc-service ip6tables save >/dev/null 2>&1
fi
fi
cip
echo
else
echo "一键节点脚本生成"
echo
argosbxstatus
echo
echo "快捷命令如下："
showmode
exit
fi
