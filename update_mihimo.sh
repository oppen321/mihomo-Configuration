#!/bin/bash' >${GITHUB_ENV}
sudo chmod +x ${GITHUB_ENV}

# 提示用户输入订阅链接
read -p "请输入你的订阅链接: " SUBSCRIPTION_URL

# 配置文件路径
CONFIG_FILE="/etc/mihomo/config.yaml"

# 创建必要的目录
if [ ! -d "/etc/mihomo" ]; then
  mkdir -p "/etc/mihomo"
fi

# 生成订阅链接转换后的URL
CONVERTED_URL="https://id9.cc/sub?target=clash&url=${SUBSCRIPTION_URL}&insert=false&emoji=false&list=false&udp=true&tfo=false&scv=false&fdn=false&sort=false&new_name=true"

# 下载转换后的配置文件到临时文件
TEMP_FILE="/tmp/clash.yaml"
curl -s -o "$TEMP_FILE" "$CONVERTED_URL"

# 检查是否下载成功
if [ ! -f "$TEMP_FILE" ]; then
  echo "无法下载订阅链接转换后的配置文件。"
  exit 1
fi

# 提取 'proxies:' 之后的内容
PROXIES_CONTENT=$(awk '/^proxies:/ {flag=1; next} flag' "$TEMP_FILE")

# 预设配置
PRESET_CONFIG="allow-lan: true
mode: rule
log-level: info
ipv6: false
external-controller: '0.0.0.0:80'
external-ui: ui
secret: \"password\"
geodata-mode: true
geodata-loader: standard
geo-auto-update: true
geo-update-interval: 24
geox-url:
  geoip: \"https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat\"
  geosite: \"https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat\"
  mmdb: \"https://fastly.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.metadb\"
tun:
  enable: true
  stack: system
  auto-route: true
  auto-detect-interface: true
dns:
  enable: true
  listen: 0.0.0.0:5555
  ipv6: false
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  fake-ip-filter:
    - '*'
    - '+.lan'
    - \"*.msftncsi.com\"
    - \"*.msftconnecttest.com\"
  default-nameserver:
    - 223.5.5.5
    - 119.29.29.29
  nameserver:
    - tls://dns.alidns.com
    - https://dns.alidns.com/dns-query
    - tls://dot.pub
    - https://doh.pub/dns-query
  proxy-server-nameserver:
    - tls://1.0.0.1:853
    - https://cloudflare-dns.com/dns-query
    - tls://dns.google:853
    - https://dns.google/dns-query
  fallback:
    - tls://1.0.0.1:853
    - https://cloudflare-dns.com/dns-query
    - tls://dns.google:853
    - https://dns.google/dns-query
  fallback-filter:
    geoip: true
    geoip-code: CN
proxies:"

# 生成最终的配置文件，将预设配置写入
echo "$PRESET_CONFIG" > "$CONFIG_FILE"
# 将 'proxies:' 之后的内容追加到配置文件中
echo "$PROXIES_CONTENT" >> "$CONFIG_FILE"

# 删除临时文件
rm -f "$TEMP_FILE"

echo "Config.yaml 已更新并保存到 $CONFIG_FILE"
