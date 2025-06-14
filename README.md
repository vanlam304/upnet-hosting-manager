
# Upnet Hosting Manager (Apache Version)

Một script hỗ trợ quản lý VPS đơn giản, nhẹ, dễ dùng, phù hợp cho người mới bắt đầu làm web hosting bằng Apache + WordPress + SSL miễn phí.

## ✅ Tính năng chính
- Thêm domain vào Apache dễ dàng
- Cài WordPress tự động (tạo database, cấu hình sẵn)
- Cấp SSL Let's Encrypt
- Tự động gia hạn SSL
- Backup website + database
- Cài phpMyAdmin và mở firewall
- Kiểm tra tình trạng dịch vụ web

## ⚙️ Yêu cầu hệ thống
- Ubuntu 20.04/22.04/24.04
- Đã mở port 80 và 443
- Có kết nối internet

## 🚀 Cài đặt nhanh

### Bước 1: Cài sẵn công cụ cần thiết

```bash
sudo apt update && sudo apt install -y bash wget curl
````

### Bước 2: Tải và chạy script

```bash
wget https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/install.sh -O install.sh
bash install.sh
```

## 🧩 Giao diện Menu

```text
1. Thêm Domain mới vào Apache
2. Cài SSL Let's Encrypt cho domain
3. Cài đặt WordPress tự động
4. Backup website + database
5. Gia hạn SSL
6. Cài phpMyAdmin
7. Bật Firewall (ufw)
8. Kiểm tra trạng thái dịch vụ
0. Thoát
```

## 📁 Cấu trúc thư mục web

Mỗi domain sẽ được tạo ở:
`/var/www/<domain>/html`

## 🔐 SSL miễn phí

Script dùng Certbot để cấp và tự động gia hạn SSL cho mọi domain bạn thêm.

## 📦 Backup

Backup website + MySQL lưu vào:
`/root/backups/<domain>/`

## 📌 Lưu ý

* Script này dùng Apache, không hỗ trợ Nginx.
* Không thích hợp dùng đồng thời DirectAdmin, CyberPanel hoặc các hệ thống khác.
* Sử dụng trên máy ảo hoặc VPS thật để đảm bảo chạy mượt.

---

Mọi góp ý xin gửi về: ZALO: 0964159587
                      mail: lam.truongvan@upnet.vn
