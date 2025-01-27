#!/bin/bash

# 自动化配置Nginx并设置HKDVB直播源

set -e

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用root用户或使用sudo执行此脚本。"
  exit 1
fi

echo "请获取您的HKDVB直播源token，通过Telegram联系@hkanime_bot获取。"
echo "请输入您的HKDVB直播源token（按回车跳过）："
read -r HKDVB_TOKEN
if [ -z "$HKDVB_TOKEN" ]; then
  echo "未提供HKDVB直播源token，跳过此步骤。"
fi

echo "请输入您的服务器IP地址（此项必须提供）："
read -r SERVER_IP
if [ -z "$SERVER_IP" ]; then
  echo "服务器IP地址未提供，脚本停止运行。"
  exit 1
fi

echo "如果您需要使用肥羊IP，请输入肥羊IP（直接按回车可跳过）："
read -r FEIYANG_IP

# 如果未提供肥羊IP，则默认使用SERVER_IP
if [ -z "$FEIYANG_IP" ]; then
  FEIYANG_IP="$SERVER_IP"
fi

# 输出确认
echo "HKDVB_TOKEN: $HKDVB_TOKEN"
echo "SERVER_IP: $SERVER_IP"
echo "FEIYANG_IP: $FEIYANG_IP"

# 更新并安装Nginx
echo "更新系统并安装Nginx..."
sudo apt update && sudo apt install -y nginx

# 下载新的Nginx配置文件
NGINX_CONF_URL="https://raw.githubusercontent.com/rad168/iptv/refs/heads/main/mytv/nginx.conf"
NGINX_CONF_PATH="/etc/nginx/nginx.conf"
echo "下载并替换Nginx配置文件..."
curl -o "$NGINX_CONF_PATH" "$NGINX_CONF_URL"

# 添加监听80端口的配置到http块内
echo "配置Nginx监听80端口..."
sed -i "/http {/a \\
    server { \\
        listen 80; \\
        server_name $SERVER_IP; \\
        location / { \\
            root /var/www/html; \\
            index index.html index.htm; \\
        } \\
        location /mytv.m3u { \\
            root /var/www/html; \\
            default_type application/octet-stream; \\
            allow all; \\
        } \\
    }" $NGINX_CONF_PATH

# 重启Nginx
echo "重启Nginx服务..."
sudo systemctl restart nginx

# 下载并修改M3U文件
M3U_URL="https://raw.githubusercontent.com/tmxk2021/CF-IPTV/refs/heads/main/mytv.m3u"
M3U_PATH="/var/www/html/mytv.m3u"
echo "下载M3U文件..."
curl -o "$M3U_PATH" "$M3U_URL"
echo "修改M3U文件中的服务器IP和token..."
sed -i "s/服务器ip/$SERVER_IP/g" "$M3U_PATH"
sed -i "s/你的token/$HKDVB_TOKEN/g" "$M3U_PATH"
sed -i "s/肥羊IP/$FEIYANG_IP/g" "$M3U_PATH"


# 处理IPv6情况下可能的403错误
HOSTS_FILE="/etc/hosts"
EDGE_IP="172.67.178.1"
EDGE_DOMAIN="edge3.hkdvb.com"
echo "检查并修改/etc/hosts文件..."
if ! grep -q "$EDGE_DOMAIN" "$HOSTS_FILE"; then
  echo "$EDGE_IP  $EDGE_DOMAIN" >> "$HOSTS_FILE"
  echo "已添加$EDGE_DOMAIN到/etc/hosts。"
else
  echo "$EDGE_DOMAIN已存在于/etc/hosts。"
fi

# 提供新的播放地址
echo "部署完成！您的M3U播放地址为: http://$SERVER_IP/mytv.m3u"
echo "您可以使用此地址观看直播。"
