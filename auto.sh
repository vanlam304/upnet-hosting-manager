#!/bin/bash

# ==== CẤU HÌNH ====
SITES_DIR="/var/www"
APACHE_CONF_DIR="/etc/apache2/sites-available"
APACHE_ENABLED_DIR="/etc/apache2/sites-enabled"
PHPMYADMIN_PORT=8080
USER_SYS=$(whoami)
BACKUP_DIR="/root/backups"
LOG_FILE="/var/log/upnet-hosting-manager.log"

# ==== HÀM LOG ====
log() {
  echo "$(date '+%F %T') - $1" | tee -a "$LOG_FILE"
}

# ==== HÀM KIỂM TRA QUYỀN ROOT ====
require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Script này cần chạy với quyền root. Dùng sudo bash $0"
    exit 1
  fi
}

# ==== KIỂM TRA KẾT NỐI MẠNG ====
check_network() {
  log "Kiểm tra kết nối mạng..."
  ping -c1 8.8.8.8 &>/dev/null || { echo "❌ Không có kết nối mạng."; exit 1; }
  ping -c1 google.com &>/dev/null || {
    echo "⚠️  DNS lỗi. Thêm nameserver tạm thời..."
    cp /etc/resolv.conf /etc/resolv.conf.bak
    echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
  }
}

# ==== KIỂM TRA & CÀI ĐẶT LAMP ====
check_lamp() {
  log "Kiểm tra/cài đặt LAMP..."
  if ! command -v apache2 >/dev/null; then
    log "Cài Apache..."
    apt update && apt install -y apache2
    systemctl enable apache2 && systemctl start apache2
  fi
  if ! command -v mysql >/dev/null && ! command -v mariadb >/dev/null; then
    log "Cài MySQL..."
    apt install -y mysql-server
    systemctl enable mysql && systemctl start mysql
  fi
  if ! command -v php >/dev/null; then
    log "Cài PHP..."
    apt install -y php libapache2-mod-php php-mysql
  fi
  log "Hệ thống LAMP đã sẵn sàng."
}

# ==== HÀM HỖ TRỢ ====
validate_domain() {
  [[ "$1" =~ ^[a-zA-Z0-9.-]+$ ]]
}

user_exists() {
  id "$1" &>/dev/null
}

db_exists() {
  mysql -e "use $1" 2>/dev/null
}

site_conf_exists() {
  [ -f "$APACHE_CONF_DIR/$1.conf" ]
}

site_dir_exists() {
  [ -d "$SITES_DIR/$1" ]
}

# ==== SHOW MENU ====
show_menu() {
  clear
  echo "=========== VPS Hosting Manager (Apache) ==========="
  echo "1. Thêm Domain mới vào Apache"
  echo "2. Cài SSL Let's Encrypt cho domain"
  echo "3. Cài đặt WordPress tự động"
  echo "4. Backup website + database"
  echo "5. Gia hạn SSL"
  echo "6. Cài phpMyAdmin"
  echo "7. Bật Firewall (ufw)"
  echo "8. Kiểm tra trạng thái dịch vụ"
  echo "9. Hiển thị trợ giúp (help)"
  echo "0. Thoát"
  echo "====================================================="
  read -p "Nhập lựa chọn: " CHOICE
}

# ==== THÊM DOMAIN APACHE ====
add_apache_domain() {
  read -p "Nhập domain (không http/https): " domain
  if ! validate_domain "$domain"; then echo "❌ Domain không hợp lệ!"; return; fi
  if site_conf_exists "$domain"; then echo "❌ Domain đã tồn tại."; return; fi
  if site_dir_exists "$domain"; then echo "❌ Thư mục domain đã tồn tại!"; return; fi

  siteuser=$(echo $domain | tr . _)_usr
  if user_exists "$siteuser"; then echo "❌ User $siteuser đã tồn tại!"; return; fi

  adduser --disabled-password --gecos "" "$siteuser"
  mkdir -p "$SITES_DIR/$domain/html"
  chown -R "$siteuser":"$siteuser" "$SITES_DIR/$domain/html"
  chmod 750 "$SITES_DIR/$domain"
  echo "<h1>Website $domain đã cài đặt!</h1>" > "$SITES_DIR/$domain/html/index.html"

  cat > "$APACHE_CONF_DIR/$domain.conf" <<EOF
<VirtualHost *:80>
    ServerAdmin admin@$domain
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $SITES_DIR/$domain/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    <Directory $SITES_DIR/$domain/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

  ln -s "$APACHE_CONF_DIR/$domain.conf" "$APACHE_ENABLED_DIR/"
  apache2ctl configtest && systemctl reload apache2
  log "Thêm domain $domain thành công."
  echo "✅ Domain $domain đã được thêm!"
}

# ==== CÀI WORDPRESS ====
install_wordpress() {
  read -p "Nhập domain cần cài WordPress: " domain
  if ! validate_domain "$domain"; then echo "❌ Domain không hợp lệ!"; return; fi
  if ! site_conf_exists "$domain" || ! site_dir_exists "$domain"; then
    echo "❌ Domain chưa tồn tại, vui lòng thêm domain trước."; return
  fi

  dbname=$(echo $domain | tr . _)_db
  dbuser=$(echo $domain | tr . _)_user
  dbpass=$(openssl rand -base64 12)
  siteuser=$(echo $domain | tr . _)_usr

  if db_exists "$dbname"; then echo "❌ Database $dbname đã tồn tại!"; return; fi
  mysql -e "CREATE DATABASE $dbname;"
  mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
  mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"
  mysql -e "FLUSH PRIVILEGES;"

  wget https://wordpress.org/latest.tar.gz -O /tmp/wp.tar.gz
  tar -xzf /tmp/wp.tar.gz -C /tmp/
  rm /tmp/wp.tar.gz

  cp -r /tmp/wordpress/* "$SITES_DIR/$domain/html/"
  cp "$SITES_DIR/$domain/html/wp-config-sample.php" "$SITES_DIR/$domain/html/wp-config.php"

  sed -i "s/database_name_here/$dbname/" "$SITES_DIR/$domain/html/wp-config.php"
  sed -i "s/username_here/$dbuser/" "$SITES_DIR/$domain/html/wp-config.php"
  sed -i "s/password_here/$dbpass/" "$SITES_DIR/$domain/html/wp-config.php"

  chown -R "$siteuser":"$siteuser" "$SITES_DIR/$domain/html"
  rm -rf /tmp/wordpress

  log "Cài WordPress cho $domain thành công. DB: $dbname, User: $dbuser"
  echo "✅ WordPress đã cài xong tại http://$domain"
  # Lưu thông tin DB (chỉ root đọc)
  echo "DB: $dbname, USER: $dbuser, PASS: $dbpass" >> "$BACKUP_DIR/wp_dbinfo_$domain.txt"
  chmod 600 "$BACKUP_DIR/wp_dbinfo_$domain.txt"
}

# ==== CÀI SSL ====
install_ssl() {
  read -p "Nhập domain để cấp SSL: " domain
  if ! validate_domain "$domain"; then echo "❌ Domain không hợp lệ!"; return; fi
  if ! site_conf_exists "$domain"; then echo "❌ Domain chưa tồn tại!"; return; fi
  apt install -y certbot python3-certbot-apache
  certbot --apache -d "$domain" -d "www.$domain" --non-interactive --agree-tos -m "admin@$domain" || {
    echo "❌ Cấp SSL thất bại!"; return;
  }
  log "Cấp SSL cho $domain thành công."
  echo "✅ Đã cấp SSL cho $domain"
}

# ==== BACKUP WEBSITE + DATABASE ====
backup_website() {
  read -p "Nhập domain cần backup: " domain
  if ! validate_domain "$domain"; then echo "❌ Domain không hợp lệ!"; return; fi
  mkdir -p "$BACKUP_DIR/$domain"
  tar czf "$BACKUP_DIR/$domain/website_$(date +%F).tar.gz" "$SITES_DIR/$domain/html" 2>/dev/null || { echo "❌ Backup web lỗi!"; return; }
  dbname=$(echo $domain | tr . _)_db
  if db_exists "$dbname"; then
    mysqldump "$dbname" > "$BACKUP_DIR/$domain/db_$(date +%F).sql"
  fi
  log "Backup $domain xong."
  echo "✅ Đã backup tại $BACKUP_DIR/$domain"
}

# ==== GIA HẠN SSL ====
auto_renew_ssl() {
  certbot renew --quiet
  log "Đã gia hạn SSL nếu cần."
  echo "✅ Đã kiểm tra & gia hạn SSL nếu cần."
}

# ==== CÀI PHPMYADMIN ====
install_phpmyadmin() {
  apt install phpmyadmin -y
  # Tạo cấu hình Alias và port riêng cho phpMyAdmin
  cat > "$APACHE_CONF_DIR/phpmyadmin.conf" <<EOF
Listen $PHPMYADMIN_PORT
<VirtualHost *:$PHPMYADMIN_PORT>
    ServerName phpmyadmin.local
    DocumentRoot /usr/share/phpmyadmin
    <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/phpmyadmin_error.log
    CustomLog \${APACHE_LOG_DIR}/phpmyadmin_access.log combined
</VirtualHost>
EOF

  ln -sf "$APACHE_CONF_DIR/phpmyadmin.conf" "$APACHE_ENABLED_DIR/"
  apache2ctl configtest && systemctl reload apache2
  log "Cài phpMyAdmin thành công."
  echo "✅ Truy cập phpMyAdmin tại: http://<IP>:$PHPMYADMIN_PORT/"
}

# ==== BẬT FIREWALL ====
setup_firewall() {
  apt install ufw -y
  ufw allow OpenSSH
  ufw allow 'Apache Full'
  ufw allow $PHPMYADMIN_PORT/tcp
  ufw --force enable
  log "Đã bật firewall."
  echo "✅ Đã bật firewall và mở port web"
}

# ==== KIỂM TRA DỊCH VỤ ====
check_services() {
  for svc in apache2 mysql; do
    if systemctl is-active --quiet "$svc"; then
      echo "$svc: OK"
    else
      echo "$svc: ❌"
    fi
  done
}

# ==== HELP ====
show_help() {
  echo "Hướng dẫn sử dụng Upnet Hosting Manager:"
  echo "- Hãy đảm bảo chạy script với quyền root (sudo)."
  echo "- Thêm domain trước khi cài WordPress hoặc SSL."
  echo "- Backup sẽ lưu ở $BACKUP_DIR."
  echo "- Log hoạt động lưu ở $LOG_FILE."
  echo "- Đổi port phpMyAdmin sửa biến PHPMYADMIN_PORT ở đầu file."
  echo "- Nếu có lỗi, xem log hoặc kiểm tra trạng thái dịch vụ!"
}

# ==== KIỂM TRA TRƯỚC KHI VÀO MENU ====
require_root
check_network
check_lamp

# ==== VÒNG LẶP MENU ====
while true; do
  show_menu
  case $CHOICE in
    1) add_apache_domain ;;
    2) install_ssl ;;
    3) install_wordpress ;;
    4) backup_website ;;
    5) auto_renew_ssl ;;
    6) install_phpmyadmin ;;
    7) setup_firewall ;;
    8) check_services ;;
    9) show_help ;;
    0) clear; exit ;;
    *) echo "❌ Lựa chọn không hợp lệ!" ;;
  esac
  echo "Nhấn Enter để quay lại menu..."
  read
done
