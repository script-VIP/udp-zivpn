#!/bin/bash
# Zivpn UDP Module installer - Auto-detect AMD64/ARM64
# Creator Deki_niswara (Modified)

# Fungsi untuk menampilkan peringatan
show_warning() {
    clear
    echo -e "\033[1;31m============================================\033[0m"
    echo -e "      ⚠️  PERINGATAN PENTING! ⚠️"
    echo -e "\033[1;31m============================================\033[0m"
    echo -e "\033[1;33mInstalasi ini akan:\033[0m"

    echo -e "  • Mengubah konfigurasi iptables"
    echo -e "  • Membuka port UDP 6000-19999 dan 5667"
    echo -e "  • Menginstal beberapa package tambahan"
    echo -e "\033[1;31m  • SSH UDP HC akan MATI/OFFLINE selama setelah selesai instalasi\033[0m"
    echo -e "\033[1;33m  • Akan restart service setelah selesai\033[0m"
    echo -e "\033[1;31m============================================\033[0m"
    echo -e ""
    read -p "Apakah Anda yakin ingin melanjutkan instalasi? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "\033[1;31mInstalasi dibatalkan.\033[0m"
        exit 1
    fi
}

# Deteksi arsitektur
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo -e "\033[1;31mArsitektur tidak dikenal: $ARCH\033[0m"
            echo "Instalasi dibatalkan."
            exit 1
            ;;
    esac
}

# Tampilkan peringatan sebelum instalasi
show_warning

# Deteksi arsitektur
ARCH=$(detect_arch)
echo -e "\033[1;32mMendeteksi arsitektur VPS: $ARCH\033[0m"
sleep 2

# Fix for sudo: unable to resolve host
HOSTNAME=$(hostname)
if ! grep -q "127.0.0.1 $HOSTNAME" /etc/hosts; then
    echo "Adding $HOSTNAME to /etc/hosts"
    sudo bash -c "echo '127.0.0.1 $HOSTNAME' >> /etc/hosts"
fi

echo -e "Updating server"
sudo apt-get update && sudo apt-get upgrade -y

# Install dependencies
if ! command -v ufw &> /dev/null; then
    echo "ufw could not be found, installing it now..."
    sudo apt-get install ufw -y
fi
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, installing it now..."
    sudo apt-get install jq -y
fi
if ! command -v curl &> /dev/null; then
    echo "curl could not be found, installing it now..."
    sudo apt-get install curl -y
fi

# Meminta domain dari pengguna
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${YELLOW}┌──────────────────────────────────────────┐${NC}"
echo -e "${YELLOW}│   Silakan masukkan domain Anda           │${NC}"
echo -e "${YELLOW}└──────────────────────────────────────────┘${NC}"
echo -n -e "${WHITE}└──> ${NC}"
read user_domain
if [ -z "$user_domain" ]; then
    echo -e "${RED}Nama domain tidak boleh kosong. Menggunakan hostname sebagai fallback.${NC}"
    user_domain=$(hostname)
fi
echo "Domain Anda akan disimpan sebagai: $user_domain"
sleep 2

if ! command -v figlet &> /dev/null; then
    echo "figlet not found, installing..."
    sudo apt-get install -y figlet
fi

if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found, installing..."
    sudo apt-get install -y ruby-full
    sudo gem install lolcat
fi

# Stop service kalau ada
sudo systemctl stop zivpn.service > /dev/null 2>&1

echo -e "Downloading UDP Service for $ARCH"

# Pilih binary berdasarkan arsitektur
if [ "$ARCH" = "amd64" ]; then
    sudo wget https://github.com/script-VIP/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64 -O /usr/local/bin/zivpn-bin
    MENU_URL="https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/zivpn-menu.sh"
elif [ "$ARCH" = "arm64" ]; then
    sudo wget https://github.com/huutvpn/script-VIP/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64 -O /usr/local/bin/zivpn-bin
    MENU_URL="https://raw.githubusercontent.com/huutvpn/script-VIP/main/zivpn-menu.sh"
fi

sudo chmod +x /usr/local/bin/zivpn-bin
sudo mkdir -p /etc/zivpn
sudo wget https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/config.json -O /etc/zivpn/config.json

echo "Generating cert files:"
sudo openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" -keyout "/etc/zivpn/zivpn.key" -out "/etc/zivpn/zivpn.crt"
sudo sysctl -w net.core.rmem_max=16777216 > /dev/null
sudo sysctl -w net.core.wmem_max=16777216 > /dev/null

sudo bash -c 'cat <<EOF > /etc/systemd/system/zivpn.service
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/zivpn
ExecStart=/usr/local/bin/zivpn-bin server -c /etc/zivpn/config.json
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF'

# Buat file database pengguna awal, file tema, dan file domain
sudo bash -c 'echo "[]" > /etc/zivpn/users.db.json'
sudo bash -c 'echo "rainbow" > /etc/zivpn/theme.conf'
sudo bash -c "echo \"$user_domain\" > /etc/zivpn/domain.conf"

# Bersihin iptables rules yang lama
INTERFACE=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
while sudo iptables -t nat -D PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667 2>/dev/null; do :; done
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p udp --dport 6000:19999 -j DNAT --to-destination :5667
sudo iptables -A FORWARD -p udp -d 127.0.0.1 --dport 5667 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 127.0.0.1/32 -o $INTERFACE -j MASQUERADE
sudo apt install iptables-persistent -y -qq
sudo netfilter-persistent save > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable zivpn.service
sudo systemctl start zivpn.service
sudo ufw allow 6000:19999/udp > /dev/null
sudo ufw allow 5667/udp > /dev/null

sudo wget -O /usr/local/bin/zivpn $MENU_URL
sudo chmod +x /usr/local/bin/zivpn

# Unduh skrip uninstall dan letakkan di path yang dapat diakses
sudo wget -O /usr/local/bin/uninstall.sh https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/uninstall.sh
sudo chmod +x /usr/local/bin/uninstall.sh

# Pasang skrip pembersihan otomatis dan jadwalkan
sudo wget -O /usr/local/bin/zivpn-cleanup.sh https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/zivpn-cleanup.sh
sudo chmod +x /usr/local/bin/zivpn-cleanup.sh
sudo wget -O /usr/local/bin/zivpn-autobackup.sh https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/zivpn-autobackup.sh
sudo chmod +x /usr/local/bin/zivpn-autobackup.sh
# Pasang skrip pemantauan server
sudo wget -O /usr/local/bin/zivpn-monitor.sh https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/zivpn-monitor.sh
sudo chmod +x /usr/local/bin/zivpn-monitor.sh

# Jalankan setiap menit untuk penghapusan yang mendekati real-time
sudo bash -c 'echo "* * * * * root /usr/local/bin/zivpn-cleanup.sh" > /etc/cron.d/zivpn-cleanup'
# Jalankan pemantauan server setiap 5 menit
sudo bash -c 'echo "*/5 * * * * root /usr/local/bin/zivpn-monitor.sh" > /etc/cron.d/zivpn-monitor'

# Pesan Selesai Instalasi
clear
echo -e "\n${GREEN}============================================${NC}"
echo -e "      ✅ ${WHITE}Instalasi ZIVPN Selesai!${NC} ✅"
echo -e "${GREEN}============================================${NC}"
echo -e "${WHITE}Arsitektur yang terinstall: ${YELLOW}$ARCH${NC}"
echo -e "${WHITE}Untuk membuka menu, ketik:${NC} ${YELLOW}zivpn${NC}"
echo -e "${WHITE}Pesan selamat datang akan muncul setiap kali Anda login.${NC}\n"

# Cleanup
rm -f zi.sh* zi-fixed.sh* zi2.sh* > /dev/null 2>&1
