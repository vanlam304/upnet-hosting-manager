#!/bin/bash

# === CẤU HÌNH ===
SITES_DIR="/var/www"
APACHE_CONF_DIR="/etc/apache2/sites-available"
APACHE_ENABLED_DIR="/etc/apache2/sites-enabled"
PHPMYADMIN_PORT=8080
USER_SYS=$(whoami)

# === KIỂM TRA KẾT NỐI MẠNG ===
ping -c1 8.8.8.8 &>/dev/null
if [ $? -ne 0 ]; then
  echo "❌ Không có kết nối mạng. Vui lòng kiểm tra lại kết nối internet."
  exit 1
fi

ping -c1 google.com &>/dev/null
if [ $? -ne 0 ]; then
  echo "⚠️  Có vẻ DNS bị lỗi. Đang sửa tạm thời bằng cách thêm nameserver..."
  echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" > /etc/resolv.conf
fi

# === KIỂM TRA PHỤ THUỘC CƠ BẢN ===
function check_lamp() {
  echo "🔍 Kiểm tra và cài đặt LAMP nếu cần..."

  if ! command -v apache2 >/dev/null 2>&1; then
    echo "🌐 Cài Apache..."
    apt update && apt install -y apache2
    systemctl enable apache2 && systemctl start apache2
  fi

  if ! command -v mysql >/dev/null 2>&1 && ! command -v mariadb >/dev/null 2>&1; then
    echo "🛢️  Cài MySQL..."
    apt install -y mysql-server
    systemctl enable mysql && systemctl start mysql
  fi

  if ! command -v php >/dev/null 2>&1; then
    echo "⚙️  Cài PHP..."
    apt install -y php libapache2-mod-php php-mysql
  fi

  echo "✅ Hệ thống đã sẵn sàng."
}

# === HÀM ===
function show_menu() {
  echo "=========== VPS Hosting Manager (Apache) ==========="
  echo "1. Thêm Domain mới vào Apache"
  echo "2. Cài SSL Let's Encrypt cho domain"
  echo "3. Cài đặt WordPress tự động"
  echo "4. Backup website + database"
  echo "5. Gia hạn SSL"
  echo "6. Cài phpMyAdmin"
  echo "7. Bật Firewall (ufw)"
  echo "8. Kiểm tra trạng thái dịch vụ"
  echo "0. Thoát"
  echo "====================================================="
  read -p "Nhập lựa chọn: " CHOICE
}

function install_wordpress() {
  read -p "Nhập domain cần cài WordPress: " domain
  [ -z "$domain" ] && return
  dbname=$(echo $domain | tr . _)_db
  dbuser=$(echo $domain | tr . _)_user
  dbpass=$(openssl rand -base64 12)

  mysql -e "CREATE DATABASE $dbname;"
  mysql -e "CREATE USER '$dbuser'@'localhost' IDENTIFIED BY '$dbpass';"
  mysql -e "GRANT ALL PRIVILEGES ON $dbname.* TO '$dbuser'@'localhost';"

  wget https://wordpress.org/latest.tar.gz -O /tmp/wp.tar.gz
  tar -xzf /tmp/wp.tar.gz -C /tmp/
  mkdir -p $SITES_DIR/$domain/html
  cp -r /tmp/wordpress/* $SITES_DIR/$domain/html/
  cp $SITES_DIR/$domain/html/wp-config-sample.php $SITES_DIR/$domain/html/wp-config.php

  sed -i "s/database_name_here/$dbname/" $SITES_DIR/$domain/html/wp-config.php
  sed -i "s/username_here/$dbuser/" $SITES_DIR/$domain/html/wp-config.php
  sed -i "s/password_here/$dbpass/" $SITES_DIR/$domain/html/wp-config.php
  chown -R www-data:www-data $SITES_DIR/$domain/html

  echo "✅ WordPress đã cài xong tại http://$domain"
}

function add_apache_domain() {
  read -p "Nhập domain (không http/https): " domain
  [ -z "$domain" ] && return
  if [ -f "$APACHE_CONF_DIR/$domain.conf" ]; then echo "❌ Domain đã tồn tại."; return; fi

  mkdir -p $SITES_DIR/$domain/html
  chown -R $USER_SYS:$USER_SYS $SITES_DIR/$domain/html
  chmod -R 755 $SITES_DIR/$domain
  echo "<h1>Website $domain da cai dat!</h1>" > $SITES_DIR/$domain/html/index.html

  cat > $APACHE_CONF_DIR/$domain.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@$domain
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $SITES_DIR/$domain/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

  ln -s $APACHE_CONF_DIR/$domain.conf $APACHE_ENABLED_DIR/
  apache2ctl configtest && systemctl reload apache2
  echo "✅ Domain $domain đã được thêm thành công!"
}

function install_ssl() {
  read -p "Nhập domain để cấp SSL: " domain
  [ -z "$domain" ] && return
  apt install -y certbot python3-certbot-apache
  certbot --apache -d $domain -d www.$domain --non-interactive --agree-tos -m admin@$domain
  echo "✅ Đã cấp SSL cho $domain"
}

function backup_website() {
  read -p "Nhập domain cần backup: " domain
  [ -z "$domain" ] && return
  mkdir -p /root/backups/$domain
  tar czf /root/backups/$domain/website.tar.gz $SITES_DIR/$domain/html
  mysqldump $(echo $domain | tr . _)_db > /root/backups/$domain/db.sql
  echo "✅ Đã backup xong vào /root/backups/$domain"
}

function auto_renew_ssl() {
  certbot renew --quiet
  echo "✅ Đã kiểm tra & gia hạn SSL nếu cần."
}

function install_phpmyadmin() {
  apt install phpmyadmin -y
  ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
  systemctl reload apache2
  echo "✅ Truy cập phpMyAdmin tại: http://<IP>:$PHPMYADMIN_PORT/phpmyadmin"
}

function setup_firewall() {
  apt install ufw -y
  ufw allow OpenSSH
  ufw allow 'Apache Full'
  ufw --force enable
  echo "✅ Đã bật firewall và mở port web"
}

function check_services() {
  for svc in apache2 mysql; do
    if systemctl is-active --quiet $svc; then
      echo "$svc: OK"
    else
      echo "$svc: ❌"
    fi
  done
}

# === CHẠY CHECK TRƯỚC KHI VÀO MENU ===
check_lamp

# === VÒNG LẶP MENU ===
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
    0) clear; exit ;;
    *) echo "❌ Lựa chọn không hợp lệ!" ;;
  esac
  echo "Nhấn Enter để quay lại menu..."
  read
