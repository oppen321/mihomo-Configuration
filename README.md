# 个人自用mihomo、sing-box自动更新订阅脚本
- 自用下载对应内核的mihomo、sing-box
- 自动更新etc/mihomo/config.yaml(etc/sing-box/config.json)文件

下载mihomo脚本
```sh
curl -fsSL  https://raw.githubusercontent.com/oppen321/mihomo-Configuration/main/install.sh -o install.sh
```

- 安装mihomo
```sh
bash install.sh
```

- 下载sing-box脚本
```sh
curl -fsSL  https://raw.githubusercontent.com/oppen321/mihomo-Configuration/main/sing-box.sh -o sing-box.sh
```

- 下载订阅转换脚本
```sh
curl -fsSL  https://raw.githubusercontent.com/oppen321/mihomo-Configuration/main/update_mihimo.sh -o update_mihimo.sh
```

- 启动订阅转换脚本
```sh
bash update_mihimo.sh
```
