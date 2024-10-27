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
operation=(Install Update UpdateConfig Logs Restart Delete OpenPort Speedtest_Ubuntu Speedtest_Centos Block_Speedtest RemoveBlock_Speedtest Check_VPS Config_Key Config_Crt RestartXrayR ConfigXrayR UninstallXrayR Test_DowFile CSF_Chan_Port Nginx_Đa_Web Ssh_Root Install_Aapanel Delete_Cmd CopyFile)
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
echo "-------------- Tool XrayR + Docker By FAST4G --------------"
echo "Chọn một tùy chọn để cài đặt:"
echo "[1] Cài đặt Docker Fast4g.vn"
echo "[2] Cài đặt Docker Skypn.me"
echo "[3] Cài đặt Docker Tùy chọn"
echo "----------------------------"
echo "[4] Cài đặt XrayR với port 80 + 443 FAST4G.VN"
echo "[5] Cài đặt XrayR với port 80 + 443 SKYPN.ME"
echo "[6] Cài đặt XrayR với port 80 + 443 Web Tùy Chọn"
echo "----------------------------"
echo "[7] Cài đặt X-ui"
echo "[8] Cài đặt XrayR với port 80 + 443 4GMAXDATA"
echo "[9] Cài đặt Aiko Server V2 FAST4G.VN"
echo "----------------------------"
read -p "Tùy chọn của bạn (1-9): " option

case $option in
    1)
        api_host="https://api-bimat188.fast4g.vn/"
        api_key="adminhoang9810a@fast4g.net"
        ;;
    2)
        api_host="https://api-khongaibiet.skypn.me/"
        api_key="adminskypn9810@skypn.me"
        ;;
    3)
        read -p "Nhập API host: " api_host
        read -p "Nhập API key: " api_key
        ;;
    4)  bash <(curl -Ls https://speed4g.me/XrayR/FAST4G/fast4g.sh)
        exit
        ;;
    5)  bash <(curl -Ls https://raw.githubusercontent.com/fast4gvpn/xrayr/main/skypn.sh)
        exit
        ;;
    6)  bash <(curl -Ls https://raw.githubusercontent.com/fast4gvpn/xrayr/main/xrayr80-443.sh)
        exit
        ;;
    7)  bash <(curl -Ls https://raw.githubusercontent.com/fast4gvpn/xrayr/main/x-ui.sh)
        exit
        ;;
    8)  bash <(curl -Ls https://raw.githubusercontent.com/fast4gvpn/xrayr/main/4gmaxdata.sh)
        exit
        ;;
    9)  bash <(curl -Ls https://raw.githubusercontent.com/fast4gvpn/docker/main/aiko.sh)
        exit
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
    read -p "Nhập Cloudfare Mail: " Cloudfare_mail
    echo "Cloudfare Mail giao thức Trojan là: $Cloudfare_mail"
    read -p "Nhập Cloudfare Key: " Cloudfare_key
    echo "Cloudfare Key giao thức Trojan là: $Cloudfare_key"
elif [ $protocol -eq 2 ]; then
    read -p "Chọn giao thức Vmess cho cổng 80 hoặc 443 (nhập 80 hoặc 443): " vmess_port
    node_type="V2ray"

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
    fi
fi
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
        CertFile: $PWD/crt.crt
        KeyFile: $PWD/key.key
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
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw allow 80
  sudo ufw allow 443
  sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
  sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
  touch crt.crt key.key
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

Logs_xrayr() {
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

Restart_xrayr() {
  cd ${cur_dir}
  docker-compose down
  docker-compose up -d
  echo "Khởi động lại thành công!"
}
Delete_xrayr() {
  cd ${cur_dir}
  docker-compose down
  cd ~
  rm -Rf ${cur_dir}
  echo "Đã xóa thành công!"
}
# Install xrayr
Install_xrayr() {
  pre_install_docker_compose
  config_docker
  install_docker
}
# Open Port 
OpenPort_xrayr() {
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 80
        sudo ufw allow 443
        sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
        sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
        XrayR restart
        Aiko-Server restart
}

#Install Speedtest_Ubuntu
Speedtest_Ubuntu_xrayr() {
        sudo apt update
        sudo apt-get install curl
        curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
        sudo apt-get install speedtest
        speedtest
}

#Install Speedtest_Centos
Speedtest_Centos_xrayr() {
        yum update -y
        curl -s https://install.speedtest.net/app/cli/install.rpm.sh | sudo bash
        sudo yum install speedtest
        speedtest
}

#Block_Speedtest
Block_Speedtest_xrayr() {
          clear
          echo "Đang chạy chặn speedtest"
          echo -e ""
          sleep 5
          
          # Cài đặt iptables-persistent và netfilter-persistent
          sudo apt install -y iptables-persistent netfilter-persistent
          
          # Chặn các địa chỉ IP của Fast.com và Speedtest.net
          iptables -I INPUT -s 23.198.103.141 -j DROP
          iptables -I INPUT -s 23.41.68.21 -j DROP
          iptables -I INPUT -s 23.199.140.37 -j DROP
          iptables -I INPUT -s 151.101.66.219 -j DROP
          iptables -I INPUT -s 151.101.194.219 -j DROP
          iptables -I INPUT -s 151.101.2.219 -j DROP
          iptables -I INPUT -s 151.101.130.219 -j DROP
          iptables -I INPUT -s 203.119.73.32 -j DROP  # Speedtest.vn
          
          # Mở các cổng cần thiết
          iptables -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT
          iptables -I INPUT -p tcp -m tcp --dport 2223 -j ACCEPT
          iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
          iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
          
          # Lưu các quy tắc iptables
          iptables-save > /etc/iptables/rules.v4
          
          # Khởi động và bật netfilter-persistent
          systemctl start netfilter-persistent
          systemctl restart netfilter-persistent
          systemctl enable netfilter-persistent
          
          # Kiểm tra trạng thái
          systemctl status netfilter-persistent
          
          clear
          echo "Đã chặn speedtest thành công!"
          echo -e ""
          sleep 3
          clear
}

RemoveBlock_Speedtest_xrayr() {
      #!/bin/bash
      clear
      echo "Đang khôi phục iptables và chặn tất cả các cổng trừ SSH, HTTP, và HTTPS"
      echo -e ""
      sleep 5
      
      # Xóa toàn bộ các quy tắc iptables
      sudo iptables -F   # Xóa tất cả các quy tắc trong bảng INPUT
      sudo iptables -X   # Xóa tất cả các chuỗi tùy chỉnh (nếu có)
      sudo iptables -Z   # Đặt lại số liệu thống kê
      
      # Mở các cổng cần thiết (SSH, HTTP, HTTPS)
      sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT  # SSH
      sudo iptables -I INPUT -p tcp --dport 2223 -j ACCEPT  # SSH
      sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT  # HTTP
      sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT # HTTPS
      
      # Cho phép các kết nối nội bộ (loopback)
      sudo iptables -I INPUT -i lo -j ACCEPT
      
      # Chặn tất cả các cổng còn lại
      sudo iptables -P INPUT DROP  # Chính sách mặc định là DROP tất cả các kết nối vào
      
      # Lưu lại các quy tắc để áp dụng sau khi khởi động lại
      sudo iptables-save > /etc/iptables/rules.v4
      
      # Khởi động lại dịch vụ netfilter-persistent để áp dụng các thay đổi
      sudo systemctl restart netfilter-persistent
      
      clear
      echo "Đã hoàn tất việc chặn tất cả các cổng ngoại trừ SSH, HTTP, và HTTPS"
      sleep 3
      clear
}

#Check VPS
Check_VPS_xrayr() {
  curl -Lso- bench.sh | bash
}

# Config Key.key
Config_Key_xrayr() {
  nano /etc/XrayR/ssl/key.key
}

# Config crt.crt
Config_Crt_xrayr() {
  nano /etc/XrayR/ssl/crt.crt
}

#Restart XrayR
RestartXrayR_xrayr() {
  XrayR restart
}

#ConfigXrayR
ConfigXrayR_xrayr() {
  nano /etc/XrayR/config.yml
}

#UninstallXrayR
UninstallXrayR_xrayr() {
  XrayR uninstall
}

#Install_Aapanel
Install_Aapanel_xrayr() {
    yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh
}

#Test_DowFile
Test_DowFile_xrayr() {
  wget --no-dns-cache --no-cache --delete-after http://speedtest-vdc.vinahost.vn/files/1000MBvnh.bin
}

Ssh_Root_xrayr() {
    echo "Tool Bật SSH Root tự động"
    if sudo grep -q "^PermitRootLogin yes$" /etc/ssh/sshd_config; then
      echo "SSH đăng nhập root đã được bật"
    else
      echo "SSH đăng nhập root chưa được bật"
    fi
    read -p "Bạn có muốn bật SSH đăng nhập root không? (y/n)" choice
    if [ ${choice} == y ] || [ ${choice} == Y ]; then
      if grep -qi "centos" /etc/*release; then
        sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
        sudo systemctl restart sshd.service
      elif grep -qi "ubuntu" /etc/*release; then
        sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        sudo systemctl restart ssh
      elif grep -qi "debian" /etc/*release; then
        sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
        sudo systemctl restart ssh
      else
        echo "Phân phối Linux không được hỗ trợ"
      fi
      sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
      echo "Vui lòng đặt mật khẩu cho người dùng root:"
      sudo passwd root
      sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
      sudo sed -i 's/PubkeyAuthentication yes/PubkeyAuthentication no/g' /etc/ssh/sshd_config
      sudo systemctl restart sshd.service
    
    else
      echo "Đã hủy việc bật SSH đăng nhập root."
    fi
}

#CSF_Chan_Port
CSF_Chan_Port_xrayr() {
  cd /usr/src/
  wget 'https://download.configserver.com/csf.tgz'
  tar -xvf csf.tgz
  cd csf
  sh install.sh
  cd /etc/csf/
  /usr/sbin/csf -tf && /usr/sbin/csf -df && /usr/sbin/csf -r && /usr/sbin/csf -q && service lfd restart
}

#Nginx_Đa_Web
Nginx_Đa_Web_xrayr() {
  bash <(curl -Ls https://raw.githubusercontent.com/chaomynhan06/nginx/main/run.sh)
}

#Delete_Cmd
Delete_Cmd_xrayr() {
    # Nhập số lượng lệnh cần xóa
    read -p "Nhập số lệnh cần xóa: " number_delete
  
    # Xóa lệnh theo số lượng người dùng đã nhập
    for ((i=1; i<=number_delete; i++)); do
      history -d $(history 1)
    done
  
    # Lưu lại thay đổi vào file .bash_history
    history -w
  
    echo "Đã xóa $number_delete lệnh gần nhất khỏi lịch sử lệnh."
}

#CopyFile
CopyFile_xrayr() {
      # Nhập địa chỉ IP của VPS đích
      read -p "Nhập IP của VPS đích: " remote_ip
      
      # Nhập đường dẫn hiện tại của tệp
      read -p "Nhập đường dẫn của tệp hiện tại: " source_path
      
      # Nhập đường dẫn đích trên VPS đích
      read -p "Nhập đường dẫn trên VPS đích: " destination_path
      
      # Sử dụng lệnh scp để truyền tệp từ VPS này sang VPS khác
      scp $source_path root@$remote_ip:$destination_path
      
      # Kiểm tra xem truyền tệp thành công hay không
      if [ $? -eq 0 ]; then
          echo "Truyền tệp thành công!"
      else
          echo "Lỗi trong quá trình truyền tệp."
      fi

}

# Initialization step
clear
while true; do
  echo "----- Tool Full XrayR + Docker FAST4G 80-443 -----"
  echo "Vui lòng nhập một số để Thực Hiện Câu Lệnh:"
  for ((i = 1; i <= ${#operation[@]}; i++)); do
    hint="${operation[$i - 1]}"
    echo -e "${green}${i}${plain}) ${hint}"
  done
  read -p "Vui lòng chọn một số và nhấn Enter (Enter theo mặc định ${operation[0]}): " selected
  [ -z "${selected}" ] && selected="1"
  case "${selected}" in
   1 |  2 |  3 |  4 |  5 |  6 |  7 |  8 |  9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25)
    echo
    echo "Bắt Đầu : ${operation[${selected} - 1]}"
    echo
    ${operation[${selected} - 1]}_xrayr
    break
    ;;
  *)
    echo -e "[${red}Error${plain}] Vui lòng nhập số chính xác [1-25]"
    ;;
  esac
done
