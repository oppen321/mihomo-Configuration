#!/bin/bash

# 1. 检测设备架构
ARCH=$(dpkg --print-architecture)
echo "检测到设备架构为: $ARCH"

# 2. 获取Sing-Box官方GitHub Releases的最新发行版
RELEASE_API="https://api.github.com/repos/SagerNet/sing-box/releases/latest"
LATEST_RELEASE=$(curl -s $RELEASE_API | grep -Po '"tag_name": "\K.*?(?=")')

# 检查是否成功获取版本号
if [ -z "$LATEST_RELEASE" ]; then
  echo "无法获取最新发行版信息。"
  exit 1
fi

echo "最新版本为: $LATEST_RELEASE"

# 根据架构选择对应的deb文件下载链接
case "$ARCH" in
  amd64)
    DEB_URL="https://github.com/SagerNet/sing-box/releases/download/$LATEST_RELEASE/sing-box_${LATEST_RELEASE}_linux_amd64.deb"
    ;;
  arm64)
    DEB_URL="https://github.com/SagerNet/sing-box/releases/download/$LATEST_RELEASE/sing-box_${LATEST_RELEASE}_linux_arm64.deb"
    ;;
  *)
    echo "未支持的架构: $ARCH"
    exit 1
    ;;
esac

# 3. 创建临时目录并下载deb文件
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

echo "正在下载 $ARCH 架构的deb文件..."
curl -LO "$DEB_URL"

# 检查下载是否成功
DEB_FILE=$(basename "$DEB_URL")
if [ ! -f "$DEB_FILE" ]; then
  echo "下载失败，文件未找到。"
  exit 1
fi

# 重命名deb文件
RENAMED_DEB_FILE="sing-box.deb"
mv "$DEB_FILE" "$RENAMED_DEB_FILE"

# 4. 安装deb文件
echo "正在安装 $RENAMED_DEB_FILE..."
sudo dpkg -i "$RENAMED_DEB_FILE"

# 如果安装出现问题，尝试修复依赖关系
if [ $? -ne 0 ]; then
    echo "安装过程中出现问题，尝试修复依赖关系..."
    sudo apt-get install -f
fi

# 设置权限
sudo chmod 755 /usr/bin/sing-box

# 清理临时文件
cd /
rm -rf "$TEMP_DIR"

echo "安装完成！"
