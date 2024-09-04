#!/bin/bash

# 检查是否安装了mihomo
if command -v mihomo > /dev/null; then
  echo "mihomo 已安装。请选择操作："
  echo "1. 启动"
  echo "2. 停止"
  echo "3. 设置自启动"
  echo "4. 删除"

  read -p "请输入选项 (1-4): " OPTION

  case "$OPTION" in
    1)
      echo "正在启动 mihomo..."
      sudo systemctl start mihomo
      ;;
    2)
      echo "正在停止 mihomo..."
      sudo systemctl stop mihomo
      ;;
    3)
      echo "设置 mihomo 为自启动..."
      sudo systemctl enable mihomo
      ;;
    4)
      echo "正在删除 mihomo..."
      sudo systemctl stop mihomo
      sudo systemctl disable mihomo
      sudo rm -rf /etc/mihomo
      rm -f /usr/bin/mihomo
      sudo rm -f /etc/systemd/system/mihomo.service
      ;;
    *)
      echo "无效选项。"
      exit 1
      ;;
  esac

  exit 0
fi

# 检测设备架构
ARCH=$(dpkg --print-architecture)
echo "检测到设备架构为: $ARCH"

# 获取最新的发行版，并根据架构下载对应的deb文件
LATEST_RELEASE=$(curl -s https://mirror.ghproxy.com/https://raw.githubusercontent.com/oppen321/mihomo-Configuration/main/mihomo.api | grep "tag_name" | awk '{print $2}' | tr -d '",')

# 检查是否成功获取版本号
if [ -z "$LATEST_RELEASE" ]; then
  echo "无法获取最新发行版信息。"
  exit 1
fi

echo "最新版本为: $LATEST_RELEASE"

# 根据架构选择对应的deb文件
case "$ARCH" in
  amd64)
    DEB_URL="https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo-linux-amd64-${LATEST_RELEASE}.deb"
    ;;
  arm64)
    DEB_URL="https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo-linux-arm64-${LATEST_RELEASE}.deb"
    ;;
  *)
    echo "未支持的架构: $ARCH"
    exit 1
    ;;
esac

# 创建临时目录用于下载
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# 下载deb文件
echo "正在下载 $ARCH 架构的deb文件..."
curl -LO "$DEB_URL"

# 检查下载是否成功
DEB_FILE=$(basename "$DEB_URL")
if [ ! -f "$DEB_FILE" ]; then
  echo "下载失败，文件未找到。"
  exit 1
fi

# 安装deb文件
echo "正在安装 $DEB_FILE..."
sudo dpkg -i "$DEB_FILE"

# 确保安装后文件的权限设置
echo "正在设置权限..."
sudo chmod 755 /usr/bin/mihomo

# 清理临时文件
cd /
rm -rf "$TEMP_DIR"

# 确保IPv4转发开启
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p

# 提示用户输入订阅链接
read -p "请输入你的订阅链接: " SUBSCRIPTION_URL

# 配置文件路径
CONFIG_FILE="/etc/mihomo/config.yaml"

# 创建必要的目录
if [ ! -d "/etc/mihomo" ]; then
  mkdir -p "/etc/mihomo"
fi

# 生成订阅链接转换后的URL
CONVERTED_URL="https://id9.cc/sub?target=clash&url=${SUBSCRIPTION_URL}&insert=false&emoji=true&list=false&udp=true&tfo=false&scv=true&fdn=false&sort=false&new_name=true"

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

# 6. 下载 Yacd-meta 仪表盘并解压到 /etc/mihomo/ui
UI_URL="https://mirror.ghproxy.com/https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip"
UI_DIR="/etc/mihomo/ui"

echo "正在下载 Yacd-meta 仪表盘..."
curl -L -o /tmp/yacd-meta.zip "$UI_URL"

echo "解压仪表盘..."
unzip -o /tmp/yacd-meta.zip -d /tmp/

# 移动到 /etc/mihomo/ui 并赋予权限
sudo mv /tmp/Yacd-meta-gh-pages "$UI_DIR"
sudo chmod -R 755 "$UI_DIR"

# 删除临时文件
rm -f /tmp/yacd-meta.zip

echo "Yacd-meta 仪表盘已安装至 $UI_DIR。"

# 提示用户完成
echo "安装和配置已完成！您可以通过访问 http://<设备IP> 来访问 Web 面板。"
