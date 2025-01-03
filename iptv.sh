#!/bin/bash

# 设置默认端口
YOUTUBE_PORT=52055
_4GTV_PORT=52056
AKTV_PORT=52057

# 获取公网 IP
get_public_ip() {
    curl -s ifconfig.me || echo "{公网IP}"
}

# 安装 YouTube 代理
install_youtube() {
    echo "正在安装 YouTube 代理..."
    docker run -d --name youtube-proxy -p ${YOUTUBE_PORT}:80 youtube/proxy:latest
    echo "YouTube 代理已安装并运行，访问: http://$(get_public_ip):${YOUTUBE_PORT}"
}

# 卸载 YouTube 代理
uninstall_youtube() {
    echo "正在卸载 YouTube 代理..."
    docker rm -f youtube-proxy
    echo "YouTube 代理已卸载。"
}

# 安装 4GTV 代理
install_4gtv() {
    echo "正在安装 4GTV 代理..."
    docker run -d --name 4gtv-proxy -p ${_4GTV_PORT}:80 4gtv/proxy:latest
    echo "4GTV 代理已安装并运行，访问: http://$(get_public_ip):${_4GTV_PORT}"
}

# 卸载 4GTV 代理
uninstall_4gtv() {
    echo "正在卸载 4GTV 代理..."
    docker rm -f 4gtv-proxy
    echo "4GTV 代理已卸载。"
}

# 安装 AKTV 代理
install_aktv() {
    echo "正在安装 AKTV 代理..."
    docker run -d --name aktv-proxy -p ${AKTV_PORT}:80 aktv/proxy:latest
    echo "AKTV 代理已安装并运行，访问: http://$(get_public_ip):${AKTV_PORT}"
}

# 卸载 AKTV 代理
uninstall_aktv() {
    echo "正在卸载 AKTV 代理..."
    docker rm -f aktv-proxy
    echo "AKTV 代理已卸载。"
}

# 显示菜单
show_menu() {
    echo "-------------------"
    echo "  代理管理工具     "
    echo "-------------------"
    echo "1) 安装 YouTube 代理"
    echo "2) 卸载 YouTube 代理"
    echo "3) 安装 4GTV 代理"
    echo "4) 卸载 4GTV 代理"
    echo "5) 安装 AKTV 代理"
    echo "6) 卸载 AKTV 代理"
    echo "0) 退出"
    echo "-------------------"
}

# 主程序逻辑
while true; do
    show_menu
    read -p "请选择操作: " choice
    case "$choice" in
        1) install_youtube ;;
        2) uninstall_youtube ;;
        3) install_4gtv ;;
        4) uninstall_4gtv ;;
        5) install_aktv ;;
        6) uninstall_aktv ;;
        0) echo "退出脚本。" ; exit 0 ;;
        *) echo "无效的选项，请输入 0-6。" ;;
    esac
done
