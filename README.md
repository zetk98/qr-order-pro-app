# ☕ Coffee QR-Order Pro

Hệ thống gọi món qua mã QR chuyên nghiệp dành cho quán cà phê. Ứng dụng được phát triển với tốc độ cực nhanh nhờ sự hỗ trợ của AI và các công nghệ Cloud hiện đại nhất.

## 🛠️ Công nghệ & Công cụ sử dụng

Dự án này là sự kết hợp của nhiều công nghệ mạnh mẽ:

- **Sáng tạo & Lập trình:** - **Cursor AI & VS Code:** Sử dụng trình soạn thảo thế hệ mới tích hợp AI để tối ưu hóa code và sửa lỗi nhanh chóng.
  - **Flutter (Web):** Framework mạnh mẽ giúp xây dựng giao diện mượt mà và đồng bộ.

- **Backend & Lưu trữ (Cloud):**
  - **Firebase Firestore:** Cơ sở dữ liệu NoSQL lưu trữ thực đơn và đơn hàng theo thời gian thực (Real-time).
  - **Firebase Hosting:** Triển khai ứng dụng lên internet với tốc độ cao và bảo mật SSL.
  - **ImgBB API:** Giải pháp lưu trữ hình ảnh sản phẩm tối ưu, giúp giảm tải cho server và tăng tốc độ tải trang.

- **Quản lý dự án:**
  - **Git:** Quản lý phiên bản code chặt chẽ.
  - **GitHub:** Lưu trữ kho mã nguồn và triển khai quy trình làm việc chuyên nghiệp.

## ✨ Chức năng chính

### 1. Đối với khách hàng (Customer)
- **Quét mã QR thông minh:** Tự động nhận diện số bàn từ URL (ví dụ: bàn 01, bàn 05).
- **Trải nghiệm Welcome:** Giao diện chào mừng ấm cúng, nhập tên để quán dễ xưng hô.
- **Thực đơn số (Digital Menu):** Xem danh sách món ăn kèm ảnh minh họa và nguyên liệu chi tiết.
- **Ghi chú cá nhân hóa:** Khách có thể nhắn gửi "ít đường", "không đá" cho từng món.
- **Giỏ hàng & Đặt món:** Tính toán tổng tiền ngay lập tức và gửi đơn về quầy chỉ với 1 chạm.

### 2. Đối với chủ quán (Admin)
- **Dashboard Quản trị:** Tông màu nâu gỗ chuyên nghiệp, phân tách rõ ràng giữa Đơn hàng và Sản phẩm.
- **Theo dõi đơn hàng Real-time:** Nhận thông báo đơn hàng mới ngay lập tức mà không cần tải lại trang.
- **Quản lý danh mục:** Thêm món mới, cập nhật giá hoặc thay đổi ảnh sản phẩm linh hoạt.

## 🎨 Giao diện & Trải nghiệm (UI/UX)
- **Phong cách:** Cafe Cozy (Ấm cúng).
- **Tông màu chủ đạo:** Nâu Cà Phê (#6F4E37), Nâu Đậm (#4E342E) và Be Gỗ.
- **Hiệu ứng:** Chuyển tab mượt mà, hiệu ứng Fade-in khi vào trang, thiết kế bo góc hiện đại.

## 🚀 Hướng dẫn triển khai (Deployment)

```bash
# 1. Build bản Web sạch
flutter build web --release

# 2. Đẩy lên Hosting
firebase deploy

# 3. Lưu trữ mã nguồn
git add .
git commit -m ""
git push origin main