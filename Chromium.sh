#!/bin/bash

curl -s https://raw.githubusercontent.com/fidezo/Airdrop-Tools/main/logo.sh | bash
sleep 5

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Skrip ini harus dijalankan sebagai root. Keluar..."
        exit 1
    fi
}

install_docker() {
    echo "Menginstal Docker..."
    sudo apt update -y && sudo apt upgrade -y || { echo "Gagal memperbarui paket. Keluar..."; exit 1; }

    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || echo "Gagal menghapus $pkg, mungkin tidak terinstal."
    done

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Gagal menginstal dependensi. Keluar..."; exit 1; }

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || { echo "Gagal menambahkan kunci GPG Docker. Keluar..."; exit 1; }

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || { echo "Gagal menambahkan repositori Docker. Keluar..."; exit 1; }

    sudo apt update -y && sudo apt install -y docker-ce || { echo "Gagal menginstal Docker. Keluar..."; exit 1; }

    sudo systemctl start docker || { echo "Gagal memulai layanan Docker. Keluar..."; exit 1; }
    sudo systemctl enable docker || { echo "Gagal mengaktifkan layanan Docker. Keluar..."; exit 1; }

    echo "Docker berhasil diinstal."
}

install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { echo "Gagal mengunduh Docker Compose. Keluar..."; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose berhasil diinstal."
    else
        echo "Docker Compose sudah terinstal."
    fi
}

check_root

if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker sudah terinstal."
fi

install_docker_compose

TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    read -p "Masukkan zona waktu Anda (default: Asia/Jakarta): " user_timezone
    TIMEZONE=${user_timezone:-Asia/Jakarta}
fi
echo "Zona waktu server terdeteksi: $TIMEZONE"

CUSTOM_USER=$(openssl rand -hex 4)
PASSWORD=$(openssl rand -hex 12)
echo "Nama pengguna yang dihasilkan: $CUSTOM_USER"
echo "Kata sandi yang dihasilkan: $PASSWORD"

echo "Menyiapkan Chromium dengan Docker Compose..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

if [ ! -f "docker-compose.yaml" ]; then
    echo "Gagal membuat docker-compose.yaml. Keluar..."
    exit 1
fi

echo "Menjalankan kontainer Chromium..."
docker-compose up -d || { echo "Gagal menjalankan kontainer Docker. Keluar..."; exit 1; }

IPVPS=$(curl -s ifconfig.me)

echo "Akses Chromium di browser Anda di: http://$IPVPS:3010/ atau https://$IPVPS:3011/"
echo "Nama pengguna: $CUSTOM_USER"
echo "Kata sandi: $PASSWORD"
echo "Harap simpan data Anda, atau Anda akan kehilangan akses!"

# Bersihkan sumber daya Docker yang tidak terpakai
docker system prune -f
echo "Sistem Docker dibersihkan."
echo -e "\n🎉 **Done Wak😹! ** 🎉"
echo -e "\n👉 **[Join My Channel](https://t.me/AbsoluteChain)** 👈"
