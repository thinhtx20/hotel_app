Hãy tạo một ảnh **mockup giao diện di động độ trung thực cao** (high-fidelity mobile UI mockup), khổ dọc tỉ lệ 9:19.5, độ phân giải lớn.
CHỈ vẽ nội dung bên trong màn hình — không khung điện thoại, không tay người, không hậu cảnh, không bóng đổ ngoài màn hình.

## Bộ nhận diện — ứng dụng khách sạn 5 sao "Luxe Grand Hotel" (Flutter, giao diện tiếng Việt)

Phong cách: **Modern Luxury** — sang trọng, tiết chế, khoảng trắng rộng, bo góc mềm, bóng đổ rất nhẹ và khuếch tán. Không rườm rà, không hoa văn cổ điển.

- Navy chính `#0F172A`, navy nhạt `#1E293B`
- Gold nhấn `#D97706`, gold sáng `#FBBF24` (chỉ dùng cho nút chính, giá tiền và chi tiết ánh kim — dùng dè dặt)
- Nền `#F8FAFC`, thẻ trắng `#FFFFFF`, viền `#E2E8F0`
- Chữ chính `#0F172A`, chữ phụ `#64748B`, placeholder `#94A3B8`
- Font **Outfit** (geometric sans-serif): tiêu đề đậm 600–700, nội dung mảnh 400
- Bo góc: thẻ lớn 20px, thẻ nhỏ 16px, nút 12px, ô nhập 12px, chip bo tròn hoàn toàn, ảnh 16px
- Bóng: `0 4px 16px rgba(15,23,42,0.08)` cho thẻ nổi; nút gold có quầng `0 8px 24px rgba(217,119,6,0.25)`
- Màu trạng thái phòng: Phòng trống `#10B981` · Đang có khách `#EF4444` · Đã đặt cọc `#F59E0B` · Đang dọn dẹp `#3B82F6` · Bảo trì `#6B7280`

## Yêu cầu bắt buộc về chữ

Toàn bộ chữ trong ảnh phải là **tiếng Việt có dấu**, chép **đúng nguyên văn** các chuỗi tôi liệt kê bên dưới. Không bịa thêm chữ, không dùng lorem ipsum, không dịch sang tiếng Anh trừ chỗ tôi ghi rõ.

---

# Màn hình 2/10 — ĐĂNG NHẬP

**Bố cục từ trên xuống:**

1. **Ảnh hero** chiếm 38% chiều cao trên cùng: ảnh chụp thật một sảnh khách sạn 5 sao hoặc hồ bơi vô cực lúc hoàng hôn, tông ấm. Phủ lên trên một lớp gradient từ trong suốt (đỉnh) xuống navy `#0F172A` 85% (đáy) để chữ đọc rõ.
2. Góc trên bên phải ảnh: một nút tròn kính mờ 40px chứa **biểu tượng bánh răng** màu trắng (dùng để cấu hình địa chỉ máy chủ).
3. **Thẻ trắng lớn** bo góc trên 32px, chồng đè lên đáy ảnh hero khoảng 32px, kéo dài xuống hết màn hình. Bóng đổ mềm hướng lên trên.
4. Trong thẻ, cách mép trên 28px, căn giữa: khối vuông bo góc 20px cỡ 64×64, nền gradient navy, chứa **biểu tượng khách sạn** màu gold. Khối này có quầng bóng navy nhẹ.
5. Cách 16px: **"Chào mừng trở lại"** — navy `#0F172A`, 24px, đậm 700, căn giữa.
6. Cách 6px: **"Hệ thống Quản lý Khách sạn 5 Sao"** — xám `#64748B`, 14px, căn giữa.
7. Cách 28px, hai ô nhập liệu cách nhau 16px, lề trái phải 24px:
   - Ô 1: nhãn nổi **"Email đăng nhập"**, nội dung **"admin@hotel.com"**, biểu tượng phong bì viền mảnh bên trái.
   - Ô 2: nhãn nổi **"Mật khẩu"**, nội dung hiển thị dạng 8 chấm tròn, biểu tượng ổ khóa bên trái, biểu tượng con mắt gạch chéo bên phải.
   - Ô nhập nền trắng, viền `#E2E8F0` 1px, bo 12px, cao 56px. Ô đang được chọn có viền gold 2px.
8. Cách 8px, căn phải: **"Quên mật khẩu?"** — gold `#D97706`, 13px, đậm 600.
9. Cách 24px: **nút chính** rộng hết lề, cao 54px, bo 12px, nền gradient gold `#D97706 → #FBBF24`, chữ **"Đăng Nhập"** trắng 16px đậm 600, có quầng bóng gold bên dưới.
10. Cách 28px: một đường kẻ mảnh với chữ ở giữa **"Tài khoản kiểm thử nhanh"** — xám `#94A3B8`, 12px.
11. Cách 14px: **4 chip** xếp thành 2 hàng, bo tròn hoàn toàn, nền `#F1F5F9`, viền `#E2E8F0`, cao 36px, mỗi chip có một chấm tròn màu ở đầu rồi đến chữ:
    - **"Quản trị"** (chấm tím) · **"Lễ tân"** (chấm xanh dương) · **"Thu ngân"** (chấm xanh lá) · **"Khách hàng"** (chấm gold)
12. Sát đáy, cách 24px: một dòng căn giữa — **"Chưa có tài khoản? "** xám `#64748B` 14px, liền sau là **"Đăng ký ngay"** gold `#D97706` 14px đậm 700.
