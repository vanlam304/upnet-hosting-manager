#!/bin/bash

# Dừng lại ngay nếu có lỗi
set -e

# =================================================================
# CẢNH BÁO - HÀNH ĐỘNG KHÔNG THỂ HOÀN TÁC
# =================================================================
echo "=================================================================="
echo "⚠️  CẢNH BÁO CỰC KỲ QUAN TRỌNG ⚠️"
echo "=================================================================="
echo "Bạn sắp chạy một kịch bản sẽ XÓA SẠCH MỌI THỨ mà Upnet Hosting Manager đã cài đặt."
echo "Hành động này bao gồm:"
echo "  - Toàn bộ website trong /var/www/"
echo "  - Toàn bộ database và user MySQL của các website đó."
echo "  - Toàn bộ user hệ thống được tạo cho mỗi website."
echo "  - Toàn bộ file cấu hình Apache và PHP-FPM Pool của từng site."
echo "  - Toàn bộ file backup, chứng chỉ SSL, và các cài đặt khác."
echo "  - Gỡ bỏ hoàn toàn Apache, MySQL, PHP, phpMyAdmin và các gói liên quan."
echo ""
echo "Hành động này KHÔNG THỂ HOÀN TÁC. Toàn bộ dữ liệu sẽ bị mất."
echo "------------------------------------------------------------------"

read -p "Để xác nhận, vui lòng gõ chính xác câu sau 'YES, DELETE EVERYTHING': " CONFIRM

if [[ "$CONFIRM" != "YES, DELETE EVERYTHING" ]]; then
  echo "❌ Xác nhận không hợp lệ. Đã hủy thao tác."
  exit 1
fi

echo "🚀 Xác nhận thành công. Bắt đầu quá trình dọn dẹp hệ thống..."

# === 1. DỪNG TẤT CẢ CÁC DỊCH VỤ LIÊN QUAN ===
echo "[1/5] 🛑 Đang dừng các dịch vụ..."
systemctl stop apache2 || true
systemctl stop mysql || true
# Dừng tất cả các phiên bản php-fpm
systemctl list-units --type=service --state=running | grep 'php.*-fpm.service' | awk '{print $1}' | xargs -r systemctl stop || true
# Dừng pm2 (cho n8n)
if command -v pm2 &>/dev/null; then
  pm2 delete all || true
  pm2 kill || true
fi

# === 2. XÓA TỪNG WEBSITE VÀ CÁC THÀNH PHẦN LIÊN QUAN ===
echo "[2/5] 🗑️  Đang xóa các website và dữ liệu liên quan..."
SITES_DIR="/var/www"
APACHE_CONF_DIR="/etc/apache2/sites-available"

if [ -d "$APACHE_CONF_DIR" ]; then
    # Lấy danh sách các file cấu hình, loại trừ các file mặc định
    CONFIG_FILES=$(find "$APACHE_CONF_DIR" -type f -name "*.conf" ! -name "000-default.conf" ! -name "default-ssl.conf")

    for conf_file in $CONFIG_FILES; do
        domain=$(basename "$conf_file" .conf | sed 's/-le-ssl$//') # Lấy tên domain gốc
        
        echo "  - Đang xóa $domain..."
        
        a2dissite "$domain.conf" &>/dev/null || true
        a2dissite "$domain-le-ssl.conf" &>/dev/null || true
        
        DOMAIN_USER=$(echo "$domain" | tr '.' '_' )_usr
        if id "$DOMAIN_USER" &>/dev/null; then userdel -r -f "$DOMAIN_USER" || true; fi

        DB_NAME="wp_$(echo "$domain" | tr '.' '_' )_db"
        DB_USER="wp_$(echo "$domain" | tr '.' '_')_user"
        mysql -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;" || true
        mysql -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" || true
    done
fi
mysql -e "FLUSH PRIVILEGES;" || true

# === 3. XÓA SẠCH CÁC FILE CẤU HÌNH VÀ DỮ LIỆU CHUNG ===
echo "[3/5] 📁 Đang xóa các file cấu hình và thư mục còn lại..."
rm -rf /etc/apache2/sites-available/*
rm -rf /etc/apache2/sites-enabled/*
rm -rf /etc/php/*/fpm/pool.d/*
rm -rf /var/www/*
rm -rf /root/upnet_backups
rm -rf /etc/letsencrypt
rm -rf /etc/cron.d/upnet-monitor
rm -f /usr/local/bin/upnet
rm -f /usr/local/bin/monitor.sh

# Xóa user n8n và phpadmin
if id "n8n" &>/dev/null; then userdel -r -f "n8n" || true; fi
mysql -e "DROP USER IF EXISTS 'phpadmin'@'localhost';" || true

# === 4. GỠ BỎ TOÀN BỘ CÁC GÓI PHẦN MỀM ĐÃ CÀI ===
echo "[4/5] 📦 Đang gỡ bỏ toàn bộ các gói phần mềm đã cài..."
# Loại bỏ PPA
if [ -d /etc/apt/sources.list.d ]; then
    add-apt-repository --remove ppa:ondrej/php -y || true
fi

# Tạo danh sách các gói cần purge
PACKAGES_TO_PURGE="apache2 apache2-data apache2-suexec-custom mysql-server mysql-client php-common phpmyadmin certbot python3-certbot-apache nodejs npm pm2 ssmtp ufw"

# Thêm tất cả các gói php* vào danh sách
PACKAGES_TO_PURGE+=" $(dpkg -l | grep 'php[0-9]\.' | awk '{print $2}')"

apt-get autoremove --purge -y $PACKAGES_TO_PURGE
apt-get autoremove -y --purge
apt-get clean

# === 5. KẾT THÚC ===
echo "[5/5] ✅ Quá trình dọn dẹp đã hoàn tất!"
echo "-------------------------------------------------"
echo "Server của bạn đã được đưa về trạng thái gần như ban đầu."
echo "Để đảm bảo mọi thứ sạch sẽ, bạn nên khởi động lại server:"
echo "   sudo reboot"
echo "-------------------------------------------------"
