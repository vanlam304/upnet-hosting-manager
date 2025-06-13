#!/bin/bash

# === CẤU HÌNH ===
SITES_DIR="/var/www"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
PHPMYADMIN_PORT=8080
USER_SYS=$(whoami)

# === KIỂM TRA PHỤ THUỘC CƠ BẢN ===
function check_lamp_lemp() {
  echo "🔍 Kiểm tra và cài đặt LAMP hoặc LEMP nếu cần..."

  if ! command -v nginx >/dev/null 2>&1; then
    echo "🌐 Cài Nginx..."
    apt update && apt install -y nginx
    systemctl enable nginx && systemctl start nginx
  fi

  if ! command -v mysql >/dev/null 2>&1 && ! command -v mariadb >/dev/null 2>&1; then
    echo "🛢️  Cài MySQL..."
    apt install -y mysql-server
    systemctl enable mysql && systemctl start mysql
  fi

  if ! command -v php >/dev/null 2>&1; then
    echo "⚙️  Cài PHP..."
    apt install -y php php-fpm php-mysql
  fi

  echo "✅ Hệ thống đã sẵn sàng."
}

# === HÀM ===
function show_menu() {
  echo "=========== VPS Hosting Manager ==========="
  echo "1. Thêm Domain mới vào Nginx"
  echo "2. Cài SSL Let's Encrypt cho domain"
  echo "3. Cài đặt WordPress tự động"
  echo "4. Cài đặt nhiều phiên bản PHP (MultiPHP)"
  echo "5. Backup website + database"
  echo "6. Gia hạn SSL"
  echo "7. Cài phpMyAdmin"
  echo "8. Bật Firewall (ufw)"
  echo "9. Kiểm tra trạng thái dịch vụ"
  echo "0. Thoát"
  echo "==========================================="
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

function add_nginx_domain() {
  read -p "Nhập domain (không http/https): " domain
  [ -z "$domain" ] && return
  if [ -f "$NGINX_CONF_DIR/$domain.conf" ]; then echo "❌ Domain đã tồn tại."; return; fi

  mkdir -p $SITES_DIR/$domain/html
  chown -R $USER_SYS:$USER_SYS $SITES_DIR/$domain/html
  chmod -R 755 $SITES_DIR/$domain
  echo "<h1>Website $domain da cai dat!</h1>" > $SITES_DIR/$domain/html/index.html

  cat > $NGINX_CONF_DIR/$domain.conf <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    root $SITES_DIR/$domain/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

  ln -s $NGINX_CONF_DIR/$domain.conf $NGINX_ENABLED_DIR/
  nginx -t && systemctl reload nginx
  echo "✅ Domain $domain đã được thêm thành công!"
}

function install_ssl() {
  read -p "Nhập domain để cấp SSL: " domain
  [ -z "$domain" ] && return
  apt install -y certbot python3-certbot-nginx
  certbot --nginx -d $domain -d www.$domain --non-interactive --agree-tos -m admin@$domain
  echo "✅ Đã cấp SSL cho $domain"
}

function install_multiphp() {
  add-apt-repository ppa:ondrej/php -y && apt update
  apt install -y php7.4 php7.4-fpm php8.0 php8.0-fpm php8.1 php8.1-fpm
  systemctl enable php7.4-fpm php8.0-fpm php8.1-fpm
  echo "✅ Đã cài các bản PHP."
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
  systemctl reload nginx
  echo "✅ Truy cập phpMyAdmin tại: http://<IP>:$PHPMYADMIN_PORT/phpmyadmin"
}

function setup_firewall() {
  apt install ufw -y
  ufw allow OpenSSH
  ufw allow 'Nginx Full'
  ufw --force enable
  echo "✅ Đã bật firewall và mở port web"
}

function check_services() {
  for svc in nginx mysql php7.4-fpm php8.0-fpm php8.1-fpm; do
    if systemctl is-active --quiet $svc; then
      echo "$svc: OK"
    else
      echo "$svc: ❌"
    fi
  done
}

# === CHẠY CHECK TRƯỚC KHI VÀO MENU ===
check_lamp_lemp

# === VÒNG LẶP MENU ===
while true; do
  show_menu
  case $CHOICE in
    1) add_nginx_domain ;;
    2) install_ssl ;;
    3) install_wordpress ;;
    4) install_multiphp ;;
    5) backup_website ;;
    6) auto_renew_ssl ;;
    7) install_phpmyadmin ;;
    8) setup_firewall ;;
    9) check_services ;;
    0) clear; exit ;;
    *) echo "❌ Lựa chọn không hợp lệ!" ;;
  esac
  echo "Nhấn Enter để quay lại menu..."
  read
done
