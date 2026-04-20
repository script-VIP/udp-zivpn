#!/bin/bash

echo "[*] Menghentikan layanan ZIVPN sementara..."
systemctl stop udpzivpn zivpn-api 2>/dev/null

echo "[*] Mengunduh dan mengganti file binary ZIVPN..."

# 1. Engine Utama ZIVPN
wget -qO /usr/local/bin/zivpn https://github.com/script-VIP/UDP-ZIVPN/releases/download/Latest/udp-zivpn-linux-amd64
echo " -> zivpn berhasil diganti"

# 2. API ZIVPN
wget -qO /usr/local/bin/zivpn-api https://github.com/script-VIP/UDP-ZIVPN/releases/download/Latest/api-amd64
echo " -> zivpn-api berhasil diganti"

# 3. Bot Telegram ZIVPN
wget -qO /usr/local/bin/zivpn-bot https://github.com/script-VIP/UDP-ZIVPN/releases/download/Latest/bot-amd64
echo " -> zivpn-bot berhasil diganti"

# 4. Menu CLI ZIVPN
wget -qO /usr/local/bin/menuz https://github.com/script-VIP/UDP-ZIVPN/releases/download/Latest/menu-amd64-new
echo " -> menu berhasil diganti"

echo "[*] Memberikan izin eksekusi (chmod +x)..."
chmod +x /usr/local/bin/zivpn
chmod +x /usr/local/bin/zivpn-api
chmod +x /usr/local/bin/zivpn-bot
chmod +x /usr/local/bin/menuz

echo "[*] Memuat ulang systemd dan menyalakan layanan..."
systemctl daemon-reload
systemctl restart udpzivpn
systemctl restart zivpn-api
#systemctl restart zivpn-bot


echo ""
echo "[V] Selesai! Berikut adalah status layanan saat ini:"
systemctl is-active udpzivpn zivpn-api  sed 's/^/ - /'
echo "Silakan ketik 'menuz' untuk mencoba."
