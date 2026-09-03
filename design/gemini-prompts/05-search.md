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

# Màn hình 5/10 — TÌM KIẾM PHÒNG

**Bố cục từ trên xuống:**

1. **Đầu màn** nền trắng, có lề 20px, cao 100px: hàng trên là nút quay lại mũi tên navy bên trái và chữ **"Tìm Kiếm Phòng"** navy 20px đậm 700; bên phải là nút vuông bo 12px viền `#E2E8F0` chứa biểu tượng bộ lọc navy có chấm gold nhỏ ở góc.
2. **Thanh tìm kiếm** lề 20px, cao 54px, nền `#F1F5F9`, bo 16px, không viền: biểu tượng kính lúp xám bên trái, chữ đang gõ **"view biển"** màu navy, bên phải là nút tròn xám nhạt chứa dấu X nhỏ.
3. Cách 16px: **hàng chip lọc** cuộn ngang, cao 36px, bo tròn hoàn toàn, cách nhau 8px:
   - **"Còn trống"** — đang chọn: nền gradient gold, chữ trắng đậm 600, có dấu tích nhỏ phía trước.
   - **"Giá thấp nhất"** · **"Tầng cao"** · **"Có ban công"** · **"Bể bơi riêng"** — nền trắng, viền `#E2E8F0`, chữ xám `#64748B` 13px.
4. Cách 20px, lề 20px: dòng kết quả — bên trái **"Tìm thấy 8 phòng"** navy 14px đậm 600, bên phải **"Sắp xếp"** xám 13px kèm biểu tượng hai mũi tên lên xuống.
5. Cách 14px: **danh sách 3 thẻ kết quả** kiểu ngang, cách nhau 12px, thẻ trắng bo 20px, bóng nhẹ, cao 116px, lề trong 10px:
   - Bên trái: ảnh phòng vuông 96×96 bo 14px.
   - Bên phải ảnh, cách 12px, xếp dọc:
     - Hàng 1: tên phòng navy 16px đậm 700, và ở mép phải là huy hiệu trạng thái nhỏ (chấm + chữ 11px).
     - Hàng 2 (cách 4px): loại phòng xám 13px.
     - Hàng 3 (cách 6px): 2 chip tiện ích siêu nhỏ nền `#F1F5F9` chữ 10px.
     - Hàng 4 (cách 8px): giá gold 16px đậm 700 + **" /đêm"** xám 11px; mép phải là nút tròn 36px nền navy chứa mũi tên chéo màu gold.
   - Nội dung 3 thẻ:
     - **"Phòng 102"** · **"Deluxe Hướng Biển"** · chip **"Ban công"**, **"Wifi"** · **"1.650.000 ₫"** · trạng thái **"Phòng trống"** `#10B981`
     - **"Phòng 205"** · **"Suite Tổng Thống"** · chip **"Bể bơi riêng"**, **"Bồn tắm"** · **"4.200.000 ₫"** · trạng thái **"Phòng trống"** `#10B981`
     - **"Phòng 308"** · **"Phòng Gia Đình"** · chip **"2 giường"**, **"Bếp nhỏ"** · **"2.100.000 ₫"** · trạng thái **"Đã đặt cọc"** `#F59E0B`
