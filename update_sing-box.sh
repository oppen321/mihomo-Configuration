#!/bin/bash

# 提示用户输入订阅链接
read -p "请输入你的订阅链接: " SUBSCRIPTION_URL

# 配置文件路径
CONFIG_FILE="/etc/sing-box/config.json"

# 创建必要的目录
if [ ! -d "/etc/sing-box" ]; then
  mkdir -p "/etc/sing-box"
fi

# 生成订阅链接转换后的URL
CONVERTED_URL="https://sing-box-subscribe-xi-gules.vercel.app/config/${SUBSCRIPTION_URL}&file=https://github.com/Toperlock/sing-box-subscribe/raw/main/config_template/config_template_groups_rule_set_tun.json"

# 下载转换后的配置文件到临时文件，使用 -L 选项处理重定向
TEMP_FILE="/tmp/sing-box-config.json"
curl -L -s -o "$TEMP_FILE" "$CONVERTED_URL"

# 检查是否下载成功并且内容非空
if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
  echo "无法下载或下载的配置文件为空。"
  exit 1
fi

# 替换内容中的 IP 地址和端口
sed -i 's/127.0.0.1:9090/0.0.0.0:80/g' "$TEMP_FILE"

# 复制处理后的文件到配置文件路径
cp "$TEMP_FILE" "$CONFIG_FILE"

# 删除临时文件
rm -f "$TEMP_FILE"

echo "Config.json 已更新并保存到 $CONFIG_FILE"
