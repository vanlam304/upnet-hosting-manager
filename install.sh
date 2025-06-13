#!/bin/bash

# === Kiểm tra quyền root ===
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Vui lòng chạy script với quyền root (sudo hoặc root user)."
  exit 1
fi

# === Cài curl & wget nếu chưa có ===
echo "🔍 Đang kiểm tra curl và wget..."
apt update -y >/dev/null 2>&1
apt install -y curl wget >/dev/null 2>&1

# === Tạo thư mục chứa script chính ===
INSTALL_DIR="/usr/local/upnet"
mkdir -p "$INSTALL_DIR"

# === Tải script auto.sh từ GitHub ===
echo "⬇️  Đang tải script quản lý chính..."
wget -qO "$INSTALL_DIR/auto.sh" https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/auto.sh

# === Cấp quyền chạy ===
chmod +x "$INSTALL_DIR/auto.sh"

# === Tạo alias hệ thống 'upnet' ===
echo "🔧 Tạo lệnh 'upnet'..."
ln -sf "$INSTALL_DIR/auto.sh" /usr/local/bin/upnet

# === Xong ===
echo "✅ Đã cài đặt thành công!"
echo "👉 Gõ lệnh: upnet"
echo "📁 Vị trí script: $INSTALL_DIR/auto.sh"
