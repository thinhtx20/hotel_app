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

# Màn hình 4/10 — TRANG CHỦ KHÁCH HÀNG

Đây là màn hình quan trọng nhất — nó định nghĩa toàn bộ ngôn ngữ thiết kế phía khách hàng. **Ảnh phòng là nhân vật chính.**

**Bố cục từ trên xuống:**

1. **Đầu màn có ảnh nền** cao 26% màn hình: ảnh phòng suite sang trọng nhìn ra biển, phủ gradient navy 80% từ dưới lên. Trên nền ảnh:
   - Hàng trên cùng: bên trái là dòng nhỏ **"Xin chào,"** trắng 60% 13px và ngay dưới là **"Nguyễn Văn A"** trắng 20px đậm 700. Bên phải là 2 nút tròn kính mờ 40px: một chứa biểu tượng chuông thông báo (có chấm gold nhỏ góc trên phải), một chứa ảnh đại diện.
   - Dưới cùng dải ảnh: **thanh tìm kiếm** trắng bo tròn hoàn toàn, cao 52px, có biểu tượng kính lúp xám bên trái và chữ mờ **"Bạn muốn nghỉ ở phòng nào?"**, bên phải là nút vuông bo 12px nền gold chứa biểu tượng bộ lọc màu trắng. Thanh này đè lên mép dưới của ảnh.
2. **Hàng danh mục** cách 24px: 4 mục ngang hàng, mỗi mục là một khối vuông bo 16px cỡ 64×64 nền `#F1F5F9` chứa biểu tượng viền mảnh, bên dưới là chữ 12px:
   **"Tiêu chuẩn"** (giường) · **"Cao cấp"** (ngôi sao) · **"Suite"** (vương miện) · **"Hướng biển"** (sóng biển)
   Mục **"Cao cấp"** đang được chọn: nền gradient gold, biểu tượng trắng, chữ gold đậm.
3. Cách 28px: **tiêu đề mục** — bên trái **"Phòng nổi bật"** navy 18px đậm 700, bên phải **"Xem tất cả"** gold 13px đậm 600 kèm mũi tên nhỏ.
4. Cách 14px: **2 thẻ phòng** xếp dọc, cách nhau 14px, thẻ trắng bo 20px, bóng mềm, mỗi thẻ:
   - Ảnh phòng bo 16px chiếm toàn bộ chiều rộng thẻ, cao 160px, nằm sát mép trên trong thẻ (có lề 8px quanh ảnh).
   - Góc trên phải ảnh: **huy hiệu trạng thái** kính mờ bo tròn — chấm màu + chữ. Thẻ 1: **"Phòng trống"** màu `#10B981`. Thẻ 2: **"Đã đặt cọc"** màu `#F59E0B`.
   - Góc trên trái ảnh: nút tròn kính mờ chứa biểu tượng trái tim viền mảnh.
   - Dưới ảnh, lề 16px: hàng đầu là tên phòng navy 17px đậm 700 và bên phải là ngôi sao gold + điểm đánh giá.
     - Thẻ 1: **"Phòng 101 — Deluxe Hướng Biển"**, điểm **"4.9"**
     - Thẻ 2: **"Phòng 205 — Suite Tổng Thống"**, điểm **"5.0"**
   - Cách 6px: dòng phụ xám 13px có biểu tượng vị trí nhỏ:
     - Thẻ 1: **"Tầng 1 • 2 khách • 35m²"**
     - Thẻ 2: **"Tầng 2 • 4 khách • 72m²"**
   - Cách 10px: 3 chip tiện ích nhỏ nền `#F1F5F9` bo tròn, chữ 11px: **"Wifi miễn phí"** · **"Bể bơi"** · **"Ăn sáng"**
   - Cách 14px, hàng cuối: bên trái là giá — số tiền gold `#D97706` 18px đậm 700 rồi chữ **" / đêm"** xám 12px thường:
     - Thẻ 1: **"1.450.000 ₫"** · Thẻ 2: **"4.200.000 ₫"**
   - Bên phải cùng hàng: nút bo 12px cao 40px nền gradient gold, chữ **"Đặt Phòng"** trắng 14px đậm 600.
5. **Thanh điều hướng dưới cùng** nền trắng, bo góc trên 24px, bóng đổ hướng lên, cao 72px, 4 mục:
   **"Khám phá"** (la bàn — đang chọn: biểu tượng gold, chữ gold đậm, có gạch nhỏ gold bên dưới) · **"Tìm kiếm"** (kính lúp) · **"Đơn phòng"** (lịch, có huy hiệu tròn đỏ ghi số **"2"**) · **"Tài khoản"** (người)
   Ba mục không được chọn có biểu tượng và chữ màu xám `#94A3B8`.
