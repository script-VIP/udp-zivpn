# UDP-ZIVPN
## HANYA SUPPORT KVM LINUX 64Bit (Tidak Support ARM)

### REKOMENDASI INSTALL DI LXC VM

[install-lxd-debian12](https://github.com/ica4me/install-lxd-debian12)

### MAKE ROOT ACCESS

<pre><code>wget -qO set-root "https://github.com/xccvmee/vip/releases/latest/download/set-root" && chmod +x set-root && sudo ALLOW_ROOT_PASSWORD=1 SET_ROOT_PASSWORD=1 ./set-root</code></pre>

### INSTALL SCRIPT

Update System
```
apt update -y && apt install -y wget curl jq nano
```

```bash
cat << 'EOF' > /usr/local/bin/sysctl
#!/bin/bash
# Jika ada perintah yang mencoba mengubah net.core (buffer jaringan), abaikan dan anggap sukses
if [[ "$*" == *"net.core."* ]]; then
    echo "[Bypass] Mengabaikan perintah sysctl pada container..."
    exit 0
fi
# Jika perintah sysctl lainnya, jalankan sysctl yang asli
exec /sbin/sysctl "$@"
EOF
```
```bash
chmod +x /usr/local/bin/sysctl
hash -r
```

Add IP Licence UDPZI
```
bash -c "$(curl -sS https://raw.githubusercontent.com/script-VIP/izinudpzi/main/add-ip.sh)"
```

<pre><code>wget -q https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/setup.sh && chmod +x setup.sh && ./setup.sh
</code></pre>

<pre><code>bash -c "$(curl -sS https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/fix-service.sh)"
</code></pre>

<h1 align="center">
PREVIEW SCRIPT </h1>

<p align="center">
 <img src="https://raw.githubusercontent.com/script-VIP/udp-zivpn/main/SCRIPT.PNG" width="600"/>
</p>

## 📘 API Documentation

Lihat dokumentasi lengkap di sini 👉 [API Documentation](./zivpn_api.md)

### TESTED ON OS

- UBUNTU 24.10
- DEBIAN 12

### FITUR TAMBAHAN

- Pemasangan yang dinamis
- Notifikasi Backup To Email
- API Server
- Add Domain
- Auto delete expired
- Auto Backup
- Auto Clear LOG
- User Details Akun

### PORT INFO

```
- UDP-ZIVPN 1:65535
```
### SERVICE INFO
```
systemctl status udpzivpn.service
systemctl status zivpn-api.service
```

### SETTING CLOUDFLARE

```
- SSL/TLS : FULL
- SSL/TLS Recommender : OFF
```
