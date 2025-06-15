# 等待1秒, 避免curl下载脚本的打印与脚本本身的显示冲突, 吃掉了提示用户按回车继续的信息
sleep 1

echo -e "                     _ ___                   \n ___ ___ __ __ ___ _| |  _|___ __ __   _ ___ \n|-_ |_  |  |  |-_ | _ |   |- _|  |  |_| |_  |\n|___|___|  _  |___|___|_|_|___|  _  |___|___|\n        |_____|               |_____|        "
red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

error() {
    echo -e "\n${red} 输入错误! ${none}\n"
}

warn() {
    echo -e "\n$yellow $1 $none\n"
}

pause() {
    read -rsp "$(echo -e "按 ${green} Enter 回车键 ${none} 继续....或按 ${red} Ctrl + C ${none} 取消.")" -d $'\n'
    echo
}

# 说明
echo
echo -e "${yellow}此脚本仅兼容于Debian 10+系统. 如果你的系统不符合,请Ctrl+C退出脚本${none}"
echo -e "可以去 ${cyan}https://github.com/crazypeace/hy2${none} 查看脚本整体思路和关键命令, 以便针对你自己的系统做出调整."
echo -e "有问题加群 ${cyan}https://t.me/+ISuvkzFGZPBhMzE1${none}"
echo -e "本脚本支持带参数执行, 省略交互过程, 详见GitHub."
echo "----------------------------------------------------------------"

# 本机 IP
InFaces=($(ls /sys/class/net/ | grep -E '^(eth|ens|eno|esp|enp|venet|vif)'))  #找所有的网口

for i in "${InFaces[@]}"; do  # 从网口循环获取IP
    # 增加超时时间, 以免在某些网络环境下请求IPv6等待太久
    Public_IPv4=$(curl -4s --interface "$i" -m 2 https://www.cloudflare.com/cdn-cgi/trace | grep -oP "ip=\K.*$")
    Public_IPv6=$(curl -6s --interface "$i" -m 2 https://www.cloudflare.com/cdn-cgi/trace | grep -oP "ip=\K.*$")

    if [[ -n "$Public_IPv4" ]]; then  # 检查是否获取到IP地址
        IPv4="$Public_IPv4"
    fi
    if [[ -n "$Public_IPv6" ]]; then  # 检查是否获取到IP地址            
        IPv6="$Public_IPv6"
    fi
done

# 通过IP, host, 时区, 生成UUID. 重装脚本不改变, 不改变节点信息, 方便个人使用
uuidSeed=${IPv4}${IPv6}$(cat /proc/sys/kernel/hostname)$(cat /etc/timezone)
default_uuid=$(curl -sL https://www.uuidtools.com/api/generate/v3/namespace/ns:dns/name/${uuidSeed} | grep -oP '[^-]{8}-[^-]{4}-[^-]{4}-[^-]{4}-[^-]{12}')

# 如果你想使用纯随机的UUID
# default_uuid=$(cat /proc/sys/kernel/random/uuid)

# 默认端口2096
default_port=2096
# 如果你想使用随机的端口
# default_port=$(shuf -i20001-65535 -n1)

# 执行脚本带参数
if [ $# -ge 1 ]; then
    # 第1个参数是搭在ipv4还是ipv6上
    case ${1} in
    4)
        netstack=4
        ip=${IPv4}
        ;;
    6)
        netstack=6
        ip=${IPv6}
        ;;
    *) # initial
        if [[ -n "$IPv4" ]]; then  # 检查是否获取到IP地址
            netstack=4
            ip=${IPv4}
        elif [[ -n "$IPv6" ]]; then  # 检查是否获取到IP地址            
            netstack=6
            ip=${IPv6}
        else
            warn "没有获取到公共IP"
        fi
        ;;
    esac

    # 第2个参数是port
    port=${2}
    if [[ -z $port ]]; then
      port=${default_port}
    fi

    # 第3个参数是域名
    domain=${3}
    if [[ -z $domain ]]; then
      domain="learn.microsoft.com"
    fi

    # 第4个参数是密码
    pwd=${4}
    if [[ -z $pwd ]]; then
        pwd=${default_uuid}
    fi

    echo -e "$yellow netstack = ${cyan}${netstack}${none}"
    echo -e "$yellow 本机IP = ${cyan}${ip}${none}"
    echo -e "${yellow} 端口 (Port) = ${cyan}${port}${none}"
    echo -e "${yellow} 密码 (Password) = ${cyan}${pwd}${none}"
    echo -e "${yellow} 自签证书所用域名 (Certificate Domain) = ${cyan}${domain}${none}"
    echo "----------------------------------------------------------------"
fi

pause

# 准备工作
apt update
apt install -y curl openssl qrencode net-tools lsof

# Hy2官方脚本 安装最新版本
echo
echo -e "${yellow}Hy2官方脚本 安装最新版本${none}"
echo "----------------------------------------------------------------"
bash <(curl -fsSL https://get.hy2.sh/)

systemctl start hysteria-server.service
systemctl enable hysteria-server.service

# 配置 Hy2, 使用自签证书, 需要:端口, 密码, 证书所用域名(不必拥有该域名)
echo
echo -e "${yellow}配置 Hy2, 使用自签证书${none}"
echo "----------------------------------------------------------------"

# 网络栈
if [[ -z $netstack ]]; then
  echo
  echo -e "如果你的小鸡是${magenta}双栈(同时有IPv4和IPv6的IP)${none}，请选择你把Hy2搭在哪个'网口'上"
  echo "如果你不懂这段话是什么意思, 请直接回车"
  read -p "$(echo -e "Input ${cyan}4${none} for IPv4, ${cyan}6${none} for IPv6:") " netstack

  if [[ $netstack == "4" ]]; then
    ip=${IPv4}
  elif [[ $netstack == "6" ]]; then
    ip=${IPv6}
  else
    if [[ -n "$IPv4" ]]; then  # 检查是否获取到IP地址
        netstack=4
        ip=${IPv4}
    elif [[ -n "$IPv6" ]]; then  # 检查是否获取到IP地址            
        netstack=6
        ip=${IPv6}
    else
        warn "没有获取到公共IP"
    fi    
  fi
fi

# 端口
if [[ -z $port ]]; then
  while :; do
    read -p "$(echo -e "请输入端口 [${magenta}1-65535${none}] Input port (默认Default ${cyan}${default_port}$none):")" port
    [ -z "$port" ] && port=$default_port
    case $port in
    [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
      echo
      echo
      echo -e "${yellow} 端口 (Port) = ${cyan}${port}${none}"
      echo "----------------------------------------------------------------"
      echo
      break
      ;;
    *)
      error
      ;;
    esac
  done
fi

# 域名
if [[ -z $domain ]]; then
    echo
    echo -e "请输入自签证书使用的 ${magenta}域名${none} Input certificate domain"
    read -p "(默认: learn.microsoft.com): " domain
    [ -z "$domain" ] && domain="learn.microsoft.com"
    echo
    echo
    echo -e "${yellow} 证书域名 Certificate Domain = ${cyan}${domain}${none}"
    echo "----------------------------------------------------------------"
    echo
fi

# 密码
if [[ -z $pwd ]]; then
    echo -e "请输入 ${yellow}密码${none}"
    read -p "$(echo -e "(默认ID: ${cyan}${default_uuid}$none):")" pwd
    [ -z "$pwd" ] && pwd=${default_uuid}
    echo
    echo
    echo -e "${yellow} 密码 (Password) = ${cyan}${pwd}${none}"
    echo "----------------------------------------------------------------"
    echo
fi

# 生成证书
echo -e "${yellow}生成证书 ${cert_dir}/ ${none}"
echo "----------------------------------------------------------------"
cert_dir="/etc/ssl/private"
mkdir -p ${cert_dir}
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "${cert_dir}/${domain}.key" -out "${cert_dir}/${domain}.crt" -subj "/CN=${domain}" -days 36500
chmod -R 777 ${cert_dir}

# 配置 /etc/hysteria/config.yaml
echo
echo -e "${yellow}配置 /etc/hysteria/config.yaml${none}"
echo "----------------------------------------------------------------"
cat >/etc/hysteria/config.yaml <<-EOF
listen: :${port}     # 工作端口

tls:
  cert: ${cert_dir}/${domain}.crt    # 证书路径
  key: ${cert_dir}/${domain}.key     # 证书路径
auth:
  type: password
  password: ${pwd}    # 密码

ignoreClientBandwidth: true

acl:
  inline:
    # 如果你想利用 *ray 的分流规则, 那么在hy2自己的分流规则里面设置全部走socks5出去, 将下面一行的注释取消
    # - s5_outbound(all)

outbounds:
  # 没有分流规则, 默认生效第一个出站 直接出站
  - name: direct_outbound
    type: direct
  # 如果你想利用 *ray 的分流规则, 那么在hy2自己的分流规则里面设置全部走socks5出去
  - name: s5_outbound
    type: socks5
    socks5:
      addr: 127.0.0.1:1080

EOF

# 重启 Hy2
echo
echo -e "${yellow}重启 Hy2${none}"
echo "----------------------------------------------------------------"
service hysteria-server restart

echo
echo
echo "---------- Hy2 客户端配置信息 ----------"
echo -e "$yellow 地址 (Address) = $cyan${ip}$none"
echo -e "$yellow 端口 (Port) = ${cyan}${port}${none}"
echo -e "$yellow 密码 (Password) = ${cyan}${pwd}${none}"
echo -e "$yellow 传输层安全 (TLS) = ${cyan}tls${none}"
echo -e "$yellow 应用层协议协商 (Alpn) = ${cyan}h3${none}"
echo -e "$yellow 跳过证书验证 (allowInsecure) = ${cyan}true${none}"
echo

# 如果是 IPv6 那么在生成节点分享链接时, 要用[]把IP包起来
if [[ $netstack == "6" ]]; then
    ip="[${ip}]"
fi
echo "---------- 链接 URL ----------"
hy2_url="hysteria2://${pwd}@${ip}:${port}?alpn=h3&insecure=1#HY2_${ip}"
echo -e "${cyan}${hy2_url}${none}"
echo
sleep 3
echo "以下两个二维码完全一样的内容"
qrencode -t UTF8 $hy2_url
qrencode -t ANSI $hy2_url
echo
echo "---------- END -------------"
echo "以上节点信息保存在 ~/_hy2_url_ 中"

# 节点信息保存到文件中
echo $hy2_url > ~/_hy2_url_
echo "以下两个二维码完全一样的内容" >> ~/_hy2_url_
qrencode -t UTF8 $hy2_url >> ~/_hy2_url_
qrencode -t ANSI $hy2_url >> ~/_hy2_url_
