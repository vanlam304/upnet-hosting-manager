# Upnet Hosting Manager

![version](https://img.shields.io/badge/version-4.0%20(Pro)-blue)
![platform](https://img.shields.io/badge/platform-Ubuntu%2020.04%2B-orange)
![security](https://img.shields.io/badge/security-FPM%20Pool%20Isolation-brightgreen)
![license](https://img.shields.io/badge/license-Proprietary-red)

Một kịch bản quản lý VPS chuyên nghiệp, được thiết kế với triết lý **Bảo mật là Ưu tiên số 1** (Security-First). Tự động hóa việc triển khai và vận hành các website trên một nền tảng được cách ly an toàn tuyệt đối, giúp bạn tập trung vào việc phát triển thay vì lo lắng về hạ tầng.

## ✨ Tính năng Nổi bật

-   🛡️ **Cách ly User tuyệt đối (PHP-FPM Pools):** Tính năng bảo mật cấp cao nhất. Mỗi website chạy dưới một user và một PHP pool riêng biệt, ngăn chặn hoàn toàn việc lây nhiễm chéo mã độc giữa các website trên cùng một server.
-   ⚙️ **Quản lý Đa phiên bản PHP:** Cài đặt, xóa và chuyển đổi giữa nhiều phiên bản PHP (7.4, 8.x...) cho từng website một cách độc lập.
-   🚀 **Cài đặt WordPress tự động:** Cài đặt phiên bản WordPress mới nhất chỉ trong vài giây. Tự động tạo database, user, và khắc phục triệt để các lỗi về quyền ghi file (FTP/Upgrade).
-   🤖 **Hỗ trợ n8n:** Tự động cài đặt và cấu hình n8n (Workflow Automation) với PM2 và Apache Reverse Proxy.[**Đang thử nghiệm, chưa tung ra**]
-   🔒 **SSL Miễn phí & Tự động:** Tự động cài đặt và gia hạn chứng chỉ SSL Let's Encrypt cho mọi domain, bao gồm cả chuyển hướng HTTPS.
-   📦 **Backup & Restore:** Sao lưu và phục hồi toàn bộ mã nguồn và database của website chỉ với một lệnh.
-   🔔 **Giám sát Chủ động:** Tùy chọn cài đặt hệ thống giám sát CPU, RAM, Disk và nhận cảnh báo tức thời qua email.[**Đang thử nghiệm, chưa tung ra**]
-   🧰 **Bộ công cụ Quản trị:** Tích hợp cài đặt phpMyAdmin bảo mật, quản lý Firewall (UFW) và kiểm tra trạng thái các dịch vụ.

## 🛡️ Kiến trúc Bảo mật

Điểm khác biệt cốt lõi của Upnet Hosting Manager so với các script thông thường là mô hình **FPM Pool per User**.

Thay vì để tất cả các website chạy chung dưới một user `www-data` (kém an toàn), script này sẽ tự động:
1.  Tạo một user hệ thống riêng cho mỗi website (ví dụ: `domain_com_usr`).
2.  Tạo một PHP-FPM Pool riêng, chạy dưới quyền của chính user đó.
3.  Cấu hình Apache để giao tiếp với FPM Pool riêng biệt này.

Kết quả: Mỗi website là một "ốc đảo" được cô lập hoàn toàn. Nếu một website bị tấn công, thiệt hại sẽ không thể lan sang các website khác.

## ⚙️ Yêu cầu
-   Hệ điều hành: **Ubuntu 20.04 LTS hoặc mới hơn**.
-   Quyền truy cập: `root` hoặc user có quyền `sudo`.
-   Đã mở port `80` và `443` trên Firewall của nhà cung cấp VPS.

## 🚀 Cài đặt Nhanh

### Bước 1: Cài sẵn các công cụ cần thiết
Lệnh này đảm bảo server có đủ các công cụ cơ bản để tải và chạy script.
```bash
sudo apt update && sudo apt install -y bash wget curl
```

### Bước 2: Tải và chạy script cài đặt
Chỉ cần một dòng lệnh duy nhất để cài đặt toàn bộ chương trình:
```bash
wget https://raw.githubusercontent.com/vanlam304/upnet-hosting-manager/main/install.sh -O install.sh && sudo bash install.sh
```

## 🛠️ Sử dụng
Sau khi cài đặt thành công, bạn có thể gọi chương trình quản lý từ bất kỳ đâu trên hệ thống bằng lệnh:

```bash
sudo upnet
```
Một menu tương tác sẽ hiện ra để bạn bắt đầu quản lý server của mình.

---

Mọi góp ý và hỗ trợ, vui lòng liên hệ:
- **Zalo:** 0964159587
- **Mail:** truongvanlam304@gmail.com
