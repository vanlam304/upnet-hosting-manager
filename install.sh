#!/bin/bash

# Kiểm tra root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Vui lòng chạy script với quyền root."
  exit 1
fi

# Kiểm tra curl và wget
if ! command -v curl >/dev/null 2>&1; then
  apt update && apt install curl -y
fi
if ! command -v wget >/dev/null 2>&1; then
  apt update && apt install wget -y
fi

# Tạo thư mục chứa script
INSTALL_DIR="/usr/local/upnet"
mkdir -p "$INSTALL_DIR"

# Tải script chính từ GitHub
echo "⬇️  Đang tải script chính..."
wget -O "$INSTALL_DIR/auto.sh" https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/auto.sh

# Cấp quyền thực thi
chmod +x "$INSTALL_DIR/auto.sh"

# Tạo alias 'upnet' trong /usr/local/bin
echo "🔧 Tạo alias 'upnet'..."
ln -sf "$INSTALL_DIR/auto.sh" /usr/local/bin/upnet

echo "✅ Cài đặt hoàn tất! Gõ lệnh 'upnet' để bắt đầu sử dụng."
