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

# Màn hình 6/10 — ĐƠN ĐẶT PHÒNG CỦA TÔI

**Bố cục từ trên xuống:**

1. **Đầu màn** nền trắng, lề 20px: nút quay lại navy bên trái, chữ **"Đơn Đặt Phòng"** navy 20px đậm 700, bên phải là biểu tượng lịch viền mảnh.
2. Cách 16px: **hàng tab dạng viên thuốc** cuộn ngang, cao 38px, bo tròn hoàn toàn, cách nhau 8px:
   - **"Tất cả"** — đang chọn: nền navy `#0F172A`, chữ trắng đậm 600, kèm huy hiệu tròn gold nhỏ ghi **"5"**.
   - **"Chờ duyệt"** · **"Đã xác nhận"** · **"Đang ở"** · **"Đã hoàn tất"** — nền `#F1F5F9`, chữ xám 13px.
3. Cách 20px: **3 thẻ đơn phòng** xếp dọc, cách nhau 14px, thẻ trắng bo 20px, bóng mềm, lề trong 16px. Mỗi thẻ:
   - **Dải màu dọc 4px** bo tròn ở mép trái trong thẻ, màu theo trạng thái.
   - Hàng 1: bên trái nhãn nhỏ xám 11px **"MÃ ĐƠN"** rồi ngay dưới là mã navy 16px đậm 700; bên phải là huy hiệu trạng thái bo tròn (nền màu 12% + chữ màu, 11px đậm 600).
   - Cách 14px: một đường kẻ đứt nét mảnh `#E2E8F0` ngang thẻ.
   - Cách 14px: **khối ngày** — hai cột chia đều, giữa hai cột là biểu tượng mũi tên sang phải trong vòng tròn `#F1F5F9`:
     - Cột trái: nhãn xám 11px **"NHẬN PHÒNG"**, dưới là ngày navy 15px đậm 700, dưới nữa là giờ xám 12px.
     - Cột phải: nhãn xám 11px **"TRẢ PHÒNG"**, dưới là ngày navy 15px đậm 700, dưới nữa là giờ xám 12px.
   - Cách 14px: hàng thông tin phòng — biểu tượng giường nhỏ + chữ navy 14px đậm 600.
   - Cách 12px: hàng cuối — bên trái nhãn xám 12px **"Tiền cọc"** rồi số tiền gold 16px đậm 700; bên phải là nút viền navy bo 10px cao 36px chữ **"Chi tiết"** navy 13px đậm 600.
   - Nội dung 3 thẻ:
     - Mã **"BK-240915"** · trạng thái **"Đã xác nhận"** `#10B981` · **"15/09/2026"** / **"14:00"** → **"18/09/2026"** / **"12:00"** · **"Phòng 305 — Deluxe Hướng Biển"** · **"1.500.000 ₫"**
     - Mã **"BK-240921"** · trạng thái **"Chờ duyệt"** `#F59E0B` · **"21/09/2026"** / **"14:00"** → **"23/09/2026"** / **"12:00"** · **"Phòng 102 — Phòng Tiêu Chuẩn"** · **"800.000 ₫"**
     - Mã **"BK-240830"** · trạng thái **"Đã hoàn tất"** `#6B7280` · **"30/08/2026"** / **"14:00"** → **"02/09/2026"** / **"12:00"** · **"Phòng 205 — Suite Tổng Thống"** · **"4.000.000 ₫"**
     Thẻ thứ ba hiển thị mờ hơn một chút (opacity 70%) để thể hiện đơn đã kết thúc.
4. Thanh điều hướng dưới cùng giống màn Trang chủ, nhưng mục **"Đơn phòng"** đang được chọn (biểu tượng và chữ màu gold).
