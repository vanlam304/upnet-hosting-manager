#!/bin/bash

echo "📦 Cài đặt curl, nếu chưa có..."
apt update -y && apt install -y curl

echo "⬇️  Đang tải UPNET Hosting Manager..."
curl -sSL https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/Vps%20Hosting%20Manager -o /usr/local/bin/upnet
chmod +x /usr/local/bin/upnet

echo "✅ Hoàn tất! Gõ 'upnet' để mở trình quản lý."
