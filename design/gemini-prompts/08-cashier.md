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

# Màn hình 8/10 — THU NGÂN & HÓA ĐƠN

Màn hình vận hành cho nhân viên thu ngân. Trọng tâm thị giác là **số tiền còn thiếu** và **nút thu tiền**.

**Bố cục từ trên xuống:**

1. **Đầu màn gradient navy** cao 165px, bo góc dưới 28px:
   - Hàng trên, lề 20px: bên trái **"Thu Ngân"** trắng 20px đậm 700 và ngay dưới **"Ca sáng • 03/09/2026"** trắng 50% 12px. Bên phải là 2 nút tròn kính mờ (làm mới, đăng xuất).
   - Cách 16px: **thẻ doanh thu** nền trắng trong suốt 12%, bo 16px, lề trong 14px: nhãn trắng 60% 11px **"ĐÃ THU HÔM NAY"**, ngay dưới là số tiền gold `#FBBF24` 26px đậm 700 **"42.350.000 ₫"**, và ở mép phải là một biểu đồ cột mini 6 cột màu gold thể hiện xu hướng tăng.
2. Cách 20px: **hàng tab dạng viên thuốc** cuộn ngang, cao 38px:
   - **"Chưa thanh toán"** — đang chọn: nền gradient gold, chữ trắng đậm 600, kèm huy hiệu tròn trắng ghi **"4"**.
   - **"Thanh toán 1 phần"** · **"Đã hoàn tất"** · **"Tất cả"** — nền `#F1F5F9`, chữ xám 13px.
3. Cách 20px: **2 thẻ hóa đơn** cách nhau 14px, thẻ trắng bo 20px, bóng mềm, lề trong 16px. Mỗi thẻ:
   - Hàng 1: bên trái khối vuông bo 12px cỡ 44×44 nền `#F1F5F9` chứa biểu tượng hóa đơn navy; cách 12px là hai dòng — mã hóa đơn navy 16px đậm 700, dưới là tên khách xám 12px. Bên phải là huy hiệu trạng thái bo tròn.
   - Cách 14px: **thanh tiến độ thanh toán** — nền `#E2E8F0` bo tròn dày 8px, phần đã thu tô gradient gold. Ngay trên thanh, hai đầu là hai nhãn 11px: bên trái xám **"Đã thu"**, bên phải xám **"Tổng"**.
   - Cách 8px: hàng số tiền — bên trái số đã thu màu `#10B981` 14px đậm 600, bên phải tổng tiền navy 14px đậm 600.
   - Cách 14px: một dải nền `#FEF3C7` bo 12px, lề trong 12px, chứa: bên trái nhãn xám đậm 12px **"Còn thiếu"**, bên phải số tiền đỏ `#EF4444` 18px đậm 700.
   - Cách 14px: **nút rộng hết thẻ** cao 48px bo 12px nền gradient gold, có biểu tượng thẻ tín dụng màu trắng và chữ **"Ghi nhận Thu tiền"** trắng 15px đậm 600, kèm quầng bóng gold.
   - Nội dung 2 thẻ:
     - **"#INV-0241"** · **"Trần Thị Bích • Phòng 402"** · trạng thái **"Chưa thanh toán"** `#EF4444` · thanh tiến độ lấp 35% · đã thu **"3.000.000 ₫"** · tổng **"8.750.000 ₫"** · còn thiếu **"5.750.000 ₫"**
     - **"#INV-0238"** · **"Lê Văn Cường • Phòng 108"** · trạng thái **"Thanh toán 1 phần"** `#F59E0B` · thanh tiến độ lấp 70% · đã thu **"2.100.000 ₫"** · tổng **"3.000.000 ₫"** · còn thiếu **"900.000 ₫"**
4. Góc dưới bên phải, cách lề 20px: **nút hành động nổi** tròn 56px nền navy, bóng đậm, chứa biểu tượng dấu cộng màu gold.
