#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Current folder
cur_dir=$(pwd)
# Color
red='\033[0;31m'
green='\033[0;32m'
#yellow='\033[0;33m'
plain='\033[0m'
operation=(Install Update UpdateConfig logs restart delete)
# Make sure only root can run our script
[[ $EUID -ne 0 ]] && echo -e "[${red}Error${plain}] Chưa vào root kìa !, vui lòng xin phép ROOT trước!" && exit 1

#Check system
check_sys() {
  local checkType=$1
  local value=$2
  local release=''
  local systemPackage=''

  if [[ -f /etc/redhat-release ]]; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /etc/issue; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /etc/issue; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /etc/issue; then
    release="centos"
    systemPackage="yum"
  elif grep -Eqi "debian|raspbian" /proc/version; then
    release="debian"
    systemPackage="apt"
  elif grep -Eqi "ubuntu" /proc/version; then
    release="ubuntu"
    systemPackage="apt"
  elif grep -Eqi "centos|red hat|redhat" /proc/version; then
    release="centos"
    systemPackage="yum"
  fi

  if [[ "${checkType}" == "sysRelease" ]]; then
    if [ "${value}" == "${release}" ]; then
      return 0
    else
      return 1
    fi
  elif [[ "${checkType}" == "packageManager" ]]; then
    if [ "${value}" == "${systemPackage}" ]; then
      return 0
    else
      return 1
    fi
  fi
}

# Get version
getversion() {
  if [[ -s /etc/redhat-release ]]; then
    grep -oE "[0-9.]+" /etc/redhat-release
  else
    grep -oE "[0-9.]+" /etc/issue
  fi
}

# CentOS version
centosversion() {
  if check_sys sysRelease centos; then
    local code=$1
    local version="$(getversion)"
    local main_ver=${version%%.*}
    if [ "$main_ver" == "$code" ]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

get_char() {
  SAVEDSTTY=$(stty -g)
  stty -echo
  stty cbreak
  dd if=/dev/tty bs=1 count=1 2>/dev/null
  stty -raw
  stty echo
  stty $SAVEDSTTY
}
error_detect_depends() {
  local command=$1
  local depend=$(echo "${command}" | awk '{print $4}')
  echo -e "[${green}Info${plain}] Bắt đầu cài đặt các gói ${depend}"
  ${command} >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "[${red}Error${plain}] Cài đặt gói không thành công ${red}${depend}${plain}"
    exit 1
  fi
}

# Pre-installation settings
pre_install_docker_compose() {

echo "Chọn một tùy chọn:"
echo "[1] fast4g.me"
echo "[2] skypn.fun"
echo "[3] Tùy chọn"
read -p "Tùy chọn của bạn (1-3): " option

case $option in
    1)
        api_host="https://api-bimat188.fast4g.me/"
        api_key="adminhoang9810a@fast4g.net"
        ;;
    2)
        api_host="https://skypn.fun"
        api_key="adminskypn9810@skypn.fun"
        ;;
    3)
        read -p "Nhập API host: " api_host
        read -p "Nhập API key: " api_key
        ;;
    *)
        echo "Tùy chọn không hợp lệ"
        exit 1
        ;;
esac

echo "Chọn một giao thức:"
echo "[1] Trojan"
echo "[2] Vmess"
read -p "Tùy chọn của bạn (1-2): " protocol

if [ $protocol -eq 1 ]; then
    read -p "ID nút 443 (Node_ID): " node_id
    echo "Node ID 443 giao thức Trojan là: $node_id"
    node_type="Trojan"
    read -p "Nhập DNS CerDomain 443: " CertDomain
    echo " DNS CerDomain443 với giao thức Trojan là: $CertDomain"
    read -p "Nhập CertMode: " Cert_mode
    echo "CertMode cổng 443 với giao thức Trojan là: $Cert_mode"
    read -p "Nhập Cloudfare mail: " Cloudfare_mail
    echo "Cloudfare mail giao thức Trojan là: $Cloudfare_mail"
    read -p "Nhập Cloudfare Mail: " Cloudfare_key
    echo "Cloudfare mail giao thức Trojan là: $Cloudfare_key"
elif [ $protocol -eq 2 ]; then
    read -p "Chọn giao thức Vmess cho cổng 80 hoặc 443 (nhập 80 hoặc 443): " vmess_port
    node_type="Vmess"

    if [[ $vmess_port == 443 ]]; then
        read -p "ID nút 443 (Node_ID) loại Vmess: " node_id
        echo "Node ID 443 giao thức Vmess là: $node_id"
        read -p "Nhập DNS CerDomain 443: " CertDomain
        echo "DNS CerDomain 443 giao thức Vmess là: \"$CertDomain\""
        read -p "Nhập CertMode: " Cert_mode
        echo "CertMode cổng 443 với giao thức Vmess là: $Cert_mode"
        read -p "Nhập Cloudfare Mail: " Cloudfare_mail
        echo "Cloudfare mail giao thức Vmess là: \"$Cloudfare_mail\""
        read -p "Nhập Cloudfare Key API: " Cloudfare_key
        echo "Cloudfare key API giao thức Vmess là: \"$Cloudfare_key\""
    elif [[ $vmess_port == 80 ]]; then
        read -p "ID nút 80 (Node_ID) loại Vmess: " node_id
        echo "Node ID 80 giao thức Vmess là: $node_id"
        read -p "Nhập DNS CerDomain 80: " CertDomain
        echo "DNS CerDomain 80 với giao thức Vmess là: \"$CertDomain\""
        read -p "Nhập CertMode: " Cert_mode
        echo "CertMode cổng 80 với giao thức Vmess là: $Cert_mode"
        Cloudfare_key="abc"
        Cloudfare_mail="abc"
    else
        echo "Lỗi: Giao thức Vmess chỉ hỗ trợ cổng 80 và 443"
        exit 1

}

# Config docker
config_docker() {
  cd ${cur_dir} || exit
  echo "Bắt đầu cài đặt các gói"
  install_dependencies
  echo "Tải tệp cấu hình DOCKER"
  cat >docker-compose.yml <<EOF
version: '3'
services: 
  xrayr: 
    image: aikocute/xrayr:v1.3.12
    volumes:
      - ./config.yml:/etc/XrayR/config.yml # thư mục cấu hình bản đồ
      - ./dns.json:/etc/XrayR/dns.json 
    restart: always
    network_mode: host
EOF
  cat >dns.json <<EOF
{
    "servers": [
        "1.1.1.1",
        "8.8.8.8",
        "localhost"
    ],
    "tag": "dns_inbound"
}
EOF
  cat >config.yml <<EOF
Log:
  Level: none 
  AccessPath: # /etc/XrayR/access.Log
  ErrorPath: # /etc/XrayR/error.log
DnsConfigPath: 
RouteConfigPath: 
OutboundConfigPath: 
ConnetionConfig:
  Handshake: 4 
  ConnIdle: 10 
  UplinkOnly: 2 
  DownlinkOnly: 4 
  BufferSize: 64 
Nodes:
  -
    PanelType: "V2board" 
    ApiConfig:
      ApiHost: "${api_host}"
      ApiKey: "${api_key}"
      NodeID: ${node_id}
      NodeType: ${node_type} 
      Timeout: 30 
      EnableVless: false 
      EnableXTLS: false 
      SpeedLimit: 0 
      DeviceLimit: 4 
      RuleListPath: 
    ControllerConfig:
      ListenIP: 0.0.0.0 
      SendIP: 0.0.0.0 
      UpdatePeriodic: 60 
      EnableDNS: false 
      DNSType: AsIs 
      DisableUploadTraffic: false 
      DisableGetRule: false 
      DisableIVCheck: false 
      DisableSniffing: true 
      EnableProxyProtocol: false 
      EnableFallback: false 
      FallBackConfigs:  
        -
          SNI: 
          Path: 
          Dest: 80 
          ProxyProtocolVer: 0 
      CertConfig:
        CertMode: ${Cert_mode}
        CertDomain: "${CertDomain}" 
        CertFile: /etc/cloud/ssl/crt.crt
        KeyFile: /etc/cloud/ssl/key.key
        Provider: cloudflare 
        Email: test@me.com
        DNSEnv: # DNS ENV option used by DNS provider
          CLOUDFLARE_EMAIL: ${Cloudfare_mail}
          CLOUDFLARE_API_KEY: ${Cloudfare_key}
EOF
}

# Install docker and docker compose
install_docker() {
  echo -e "Bắt đầu cài đặt DOCKER "
 sudo apt-get update
 sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
systemctl start docker
systemctl enable docker
  echo -e "Bắt đầu cài đặt Docker Compose "
curl -fsSL https://get.docker.com | bash -s docker
curl -L "https://github.com/docker/compose/releases/download/1.26.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
  cd /etc/cloud
  mkdir ssl
  cd /etc/cloud/ssl
  git clone https://github.com/chaomynhan/ssl.git
  cd
  echo "Khởi động Docker "
  service docker start
  echo "Khởi động Docker-Compose "
  docker-compose up -d
  echo
  echo -e "Đã hoàn tất cài đặt phụ trợ ！"
  echo -e "0 0 */3 * *  cd /root/${cur_dir} && /usr/local/bin/docker-compose pull && /usr/local/bin/docker-compose up -d" >>/etc/crontab
  echo -e "Cài đặt cập nhật thời gian kết thúc đã hoàn tất! hệ thống sẽ update sau [${green}24H${plain}] Từ lúc bạn cài đặt"
}

install_check() {
  if check_sys packageManager yum || check_sys packageManager apt; then
    if centosversion 5; then
      return 1
    fi
    return 0
  else
    return 1
  fi
}

install_dependencies() {
  if check_sys packageManager yum; then
    echo -e "[${green}Info${plain}] Kiểm tra kho EPEL ..."
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
      yum install -y epel-release >/dev/null 2>&1
    fi
    [ ! -f /etc/yum.repos.d/epel.repo ] && echo -e "[${red}Error${plain}] Không cài đặt được kho EPEL, vui lòng kiểm tra." && exit 1
    [ ! "$(command -v yum-config-manager)" ] && yum install -y yum-utils >/dev/null 2>&1
    [ x"$(yum-config-manager epel | grep -w enabled | awk '{print $3}')" != x"True" ] && yum-config-manager --enable epel >/dev/null 2>&1
    echo -e "[${green}Info${plain}] Kiểm tra xem kho lưu trữ EPEL đã hoàn tất chưa ..."

    yum_depends=(
      curl
    )
    for depend in ${yum_depends[@]}; do
      error_detect_depends "yum -y install ${depend}"
    done
  elif check_sys packageManager apt; then
    apt_depends=(
      curl
    )
    apt-get -y update
    for depend in ${apt_depends[@]}; do
      error_detect_depends "apt-get -y install ${depend}"
    done
  fi
  echo -e "[${green}Info${plain}] Đặt múi giờ thành phố Hà Nội GTM+7"
  ln -sf /usr/share/zoneinfo/Asia/Hanoi  /etc/localtime
  date -s "$(curl -sI g.cn | grep Date | cut -d' ' -f3-6)Z"

}

#update_image
Update_xrayr() {
  cd ${cur_dir}
  echo "Tải Plugin DOCKER"
  docker-compose pull
  echo "Bắt đầu chạy dịch vụ DOCKER"
  docker-compose up -d
}

#show last 100 line log

logs_xrayr() {
  echo "Nhật ký chạy sẽ được hiển thị"
  docker-compose logs --tail 100
}

# Update config
UpdateConfig_xrayr() {
  cd ${cur_dir}
  echo "Đóng dịch vụ hiện tại"
  docker-compose down
  pre_install_docker_compose
  config_docker
  echo "Bắt đầu chạy dịch vụ DOKCER"
  docker-compose up -d
}

restart_xrayr() {
  cd ${cur_dir}
  docker-compose down
  docker-compose up -d
  echo "Khởi động lại thành công!"
}
delete_xrayr() {
  cd ${cur_dir}
  docker-compose down
  cd ~
  rm -Rf ${cur_dir}
  echo "đã xóa thành công!"
}
# Install xrayr
Install_xrayr() {
  pre_install_docker_compose
  config_docker
  install_docker
}

# Initialization step
clear
while true; do
  echo "----- XrayR Docker FAST4G 80-443 -----"
  echo "Vui lòng nhập một số để Thực Hiện Câu Lệnh:"
  for ((i = 1; i <= ${#operation[@]}; i++)); do
    hint="${operation[$i - 1]}"
    echo -e "${green}${i}${plain}) ${hint}"
  done
  read -p "Vui lòng chọn một số và nhấn Enter (Enter theo mặc định ${operation[0]}):" selected
  [ -z "${selected}" ] && selected="1"
  case "${selected}" in
  1 | 2 | 3 | 4 | 5 | 6 | 7)
    echo
    echo "Bắt Đầu : ${operation[${selected} - 1]}"
    echo
    ${operation[${selected} - 1]}_xrayr
    break
    ;;
  *)
    echo -e "[${red}Error${plain}] Vui lòng nhập số chính xác [1-6]"
    ;;
  esac
done
