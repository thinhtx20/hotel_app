# Bộ tài liệu thiết kế lại giao diện — Luxe Grand Hotel

## Quy trình

1. Mở từng file trong `gemini-prompts/`, copy toàn bộ nội dung (Ctrl+A, Ctrl+C).
2. Dán vào Gemini trong **Antigravity IDE**, yêu cầu tạo ảnh (image generation).
3. Lưu ảnh nhận được vào `design/mockups/` theo đúng tên file, ví dụ `01-splash.png`.
4. Báo lại cho Claude — Claude sẽ đọc ảnh và hiện thực hóa bằng Flutter.

## Danh sách 10 màn hình

| File prompt | Màn hình | Ảnh cần lưu |
|---|---|---|
| `01-splash.md` | Màn hình chờ | `mockups/01-splash.png` |
| `02-login.md` | Đăng nhập | `mockups/02-login.png` |
| `03-register.md` | Đăng ký | `mockups/03-register.png` |
| `04-home.md` | Trang chủ khách hàng | `mockups/04-home.png` |
| `05-search.md` | Tìm kiếm phòng | `mockups/05-search.png` |
| `06-bookings.md` | Đơn đặt phòng của tôi | `mockups/06-bookings.png` |
| `07-room-matrix.md` | Sơ đồ buồng phòng (Lễ tân) | `mockups/07-room-matrix.png` |
| `08-cashier.md` | Thu ngân & Hóa đơn | `mockups/08-cashier.png` |
| `09-admin.md` | Dashboard quản trị | `mockups/09-admin.png` |
| `10-profile.md` | Hồ sơ cá nhân | `mockups/10-profile.png` |

## Lưu ý khi tạo ảnh

- **Chữ tiếng Việt có dấu là điểm yếu của mọi model tạo ảnh.** Nếu ảnh trả về sai dấu hoặc chữ méo, cứ giữ nguyên — Claude chỉ cần bố cục, màu sắc và tinh thần thị giác; phần chữ sẽ lấy từ code thật.
- Nếu Gemini trả ảnh có khung điện thoại / tay người / hậu cảnh, yêu cầu nó vẽ lại: *"chỉ hiển thị nội dung màn hình, không khung điện thoại"*.
- Muốn nhiều phương án: yêu cầu Gemini tạo 2–3 biến thể rồi chọn cái ưng nhất.
- Không có thời gian làm cả 10? Ưu tiên `02-login.md`, `04-home.md`, `09-admin.md` — ba màn này quyết định toàn bộ ngôn ngữ thiết kế, các màn còn lại Claude suy ra được.

## Nếu bỏ qua bước Gemini

Cứ nói với Claude — Claude sẽ tự thiết kế theo `DESIGN-SYSTEM.md` và code luôn 10 màn.
