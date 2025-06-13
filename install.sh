#!/bin/bash

echo "🌐 Cài đặt UPNET Hosting Manager..."
apt update -y && apt install -y curl

curl -sSL https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/auto.sh -o /usr/local/bin/upnet
chmod +x /usr/local/bin/upnet

echo "✅ Cài đặt xong. Dùng lệnh 'upnet' để mở menu quản lý VPS."
