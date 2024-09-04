#!/bin/bash

# 提示用户输入订阅链接
read -p "请输入你的订阅链接: " SUBSCRIPTION_URL

# 配置文件路径
CONFIG_FILE="/etc/mihimo/config.yaml"

# 使用订阅链接转换为Clash的YAML文件
CONVERTED_URL="https://id9.cc/sub?target=clash&url=${SUBSCRIPTION_URL}&insert=false&emoji=false&list=false&udp=true&tfo=false&scv=false&fdn=false&sort=false&new_name=true"
curl -s "$CONVERTED_URL" -o "/tmp/clash.yaml"

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
    geoip-code: CN"

# 找到proxies:所在的行号
PROXIES_LINE=$(grep -n '^proxies:' /tmp/clash.yaml | cut -d: -f1)

# 提取proxies:及其后面的内容
tail -n +"$PROXIES_LINE" /tmp/clash.yaml > /tmp/clash_proxies.yaml

# 生成最终的配置文件
echo "$PRESET_CONFIG" > "$CONFIG_FILE"
cat /tmp/clash_proxies.yaml >> "$CONFIG_FILE"

# 清理临时文件
rm -f /tmp/clash.yaml /tmp/clash_proxies.yaml

echo "Config.yaml 已更新并保存到 $CONFIG_FILE"
