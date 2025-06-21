#!/bin/bash

# Dừng lại ngay nếu có lỗi
set -e

# === CẤU HÌNH ===
# URL trỏ đến file auto.sh ĐÃ ĐƯỢC gzexe BẢO VỆ
PROTECTED_SCRIPT_URL="https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/auto.sh"
COMMAND_NAME="upnet"
INSTALL_PATH="/usr/local/bin/$COMMAND_NAME"

# --- Bắt đầu cài đặt ---
echo "================================================="
echo "   Đang cài đặt Upnet Hosting Manager...         "
echo "================================================="

# 1. Kiểm tra quyền root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Lỗi: Vui lòng chạy script này với quyền root hoặc sudo."
  exit 1
fi

# 2. Cài các gói phụ thuộc tối thiểu
echo "🔍 Đang kiểm tra các gói phụ thuộc (curl, wget)..."
apt-get update -y >/dev/null 2>&1
apt-get install -y curl wget >/dev/null 2>&1

# 3. Tải file chương trình chính đã được bảo vệ
echo "⬇️  Đang tải file chương trình chính (đã được bảo vệ)..."
wget -q "$PROTECTED_SCRIPT_URL" -O "$INSTALL_PATH"

# 4. Kiểm tra tải về thành công
if [ ! -f "$INSTALL_PATH" ]; then
    echo "❌ LỖI: Tải file thất bại. Vui lòng kiểm tra lại URL hoặc kết nối mạng."
    exit 1
fi

# 5. Cấp quyền thực thi
echo "🔧 Đang cấp quyền thực thi..."
chmod +x "$INSTALL_PATH"

echo "-------------------------------------------------"
echo "✅ Cài đặt thành công!"
echo "Bạn có thể chạy chương trình ở bất kỳ đâu bằng lệnh:"
echo
echo "   sudo $COMMAND_NAME"
echo
echo "-------------------------------------------------"
