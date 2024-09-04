#!/bin/bash

# 1. 检测设备架构
ARCH=$(dpkg --print-architecture)
echo "检测到设备架构为: $ARCH"

# 2. 获取最新的发行版，并根据架构下载对应的deb文件
LATEST_RELEASE=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | grep "tag_name" | awk '{print $2}' | tr -d '",')

# 检查是否成功获取版本号
if [ -z "$LATEST_RELEASE" ]; then
  echo "无法获取最新发行版信息。"
  exit 1
fi

echo "最新版本为: $LATEST_RELEASE"

# 根据架构选择对应的deb文件
case "$ARCH" in
  amd64)
    DEB_URL="https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo_${LATEST_RELEASE}_amd64.deb"
    ;;
  arm64)
    DEB_URL="https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo_${LATEST_RELEASE}_arm64.deb"
    ;;
  armhf)
    DEB_URL="https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo_${LATEST_RELEASE}_armhf.deb"
    ;;
  i386)
    DEB_URL="https://github.com/MetaCubeX/mihomo/releases/download/$LATEST_RELEASE/mihomo_${LATEST_RELEASE}_i386.deb"
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

# 3. 安装deb文件
echo "正在安装 $DEB_FILE..."
sudo dpkg -i "$DEB_FILE"

# 清理临时文件
cd /
rm -rf "$TEMP_DIR"

# 确保安装后文件的权限设置
echo "正在设置权限..."
sudo chmod 755 /usr/bin/mihomo

echo "安装完成！"
