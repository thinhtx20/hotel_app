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

# Màn hình 9/10 — BÁO CÁO QUẢN TRỊ (Dashboard)

Màn hình dành cho giám đốc. **Số liệu là nhân vật chính**, không phải ảnh. Biểu đồ phải mảnh, thanh thoát, lưới kẻ rất nhạt — tuyệt đối không đậm màu, không hiệu ứng 3D, không bóng đổ trên biểu đồ.

**Bố cục từ trên xuống:**

1. **Đầu màn gradient navy** `#0F172A → #1E293B` cao 190px, bo góc dưới 28px, có hoa văn hình học gold mờ 5%:
   - Hàng trên, lề 20px: bên trái **"Tổng quan"** trắng 50% 13px, ngay dưới là **"Báo Cáo Quản Trị"** trắng 22px đậm 700. Bên phải là 2 nút tròn kính mờ 40px (biểu tượng làm mới, biểu tượng đăng xuất).
   - Cách 20px: nhãn trắng 50% 11px giãn chữ 1px **"DOANH THU HÔM NAY"**.
   - Cách 6px: **con số chủ đạo** — **"128.500.000 ₫"** màu gold `#FBBF24`, cỡ rất lớn 32px, đậm 700, cùng font Outfit (không dùng font có chân).
   - Cách 8px, cùng hàng: một huy hiệu nhỏ bo tròn nền xanh lá 20% chứa mũi tên chéo lên và chữ **"+12,4%"** màu `#10B981` 12px đậm 600; ngay bên cạnh là chữ **"so với hôm qua"** trắng 45% 12px.
2. **Thẻ tỷ lệ lấp đầy** trắng bo 20px, lề 20px, chồng đè lên đáy dải navy 28px, bóng mềm, lề trong 18px, cao 112px:
   - Bên trái: nhãn xám 12px **"Tỷ lệ lấp đầy"**, ngay dưới là **"78%"** navy 28px đậm 700, dưới nữa là **"14 / 20 phòng đang có khách"** xám 12px.
   - Bên phải: một **vòng cung đo** (không phải biểu đồ tròn chia lát) đường kính 76px — vòng nền là gold pha loãng 15% dày 9px bo tròn hai đầu, vòng giá trị là gradient gold `#D97706 → #FBBF24` dày 9px lấp 78% cung, bo tròn hai đầu. Giữa vòng trống, không có chữ.
3. Cách 24px, lề 20px: nhãn mục **"HÔM NAY"** xám `#94A3B8` 11px đậm 700 giãn chữ 1px.
4. Cách 12px: **3 ô thống kê nhỏ** ngang hàng, cách nhau 10px, thẻ trắng bo 16px, bóng nhẹ, lề trong 14px, cao 96px. Mỗi ô xếp dọc:
   - Trên cùng: khối vuông bo 10px cỡ 32×32 nền màu pha loãng 12% chứa biểu tượng viền mảnh cùng màu.
   - Cách 10px: số navy 22px đậm 700.
   - Cách 2px: nhãn xám 11px.
   - Ba ô: **"12"** / **"Lượt nhận phòng"** (biểu tượng chìa khóa, gold) · **"8"** / **"Lượt trả phòng"** (biểu tượng cửa ra, xanh dương) · **"4"** / **"Đơn chờ duyệt"** (biểu tượng đồng hồ, đỏ)
5. Cách 24px: **thẻ biểu đồ doanh thu** trắng bo 20px, lề 20px, bóng mềm, lề trong 18px, cao 240px:
   - Hàng tiêu đề: bên trái **"Doanh thu 7 ngày"** navy 16px đậm 600; bên phải một chip nhỏ nền `#F1F5F9` bo tròn chữ **"7 ngày"** xám 11px kèm mũi tên xuống.
   - Bên dưới, một **biểu đồ đường có tô nền** (area chart) **một đường duy nhất**:
     - Đường màu gold `#D97706`, dày đúng 2px, bo mềm ở các khúc gấp, KHÔNG có chấm tròn ở mọi điểm.
     - Vùng tô dưới đường là gradient gold từ 22% opacity ở đỉnh xuống 0% ở đáy.
     - Chỉ **điểm cuối cùng** có chấm tròn 9px màu gold với viền trắng 2px, và ngay trên nó là một nhãn nhỏ nền navy bo 8px chữ trắng 11px ghi **"128,5 tr"**.
     - Lưới ngang: 4 đường kẻ **liền nét** màu `#F1F5F9` dày 1px. Không có lưới dọc. Không có đường đứt nét.
     - Nhãn trục ngang màu xám `#94A3B8` 11px: **"T2"**, **"T3"**, **"T4"**, **"T5"**, **"T6"**, **"T7"**, **"CN"**.
     - Nhãn trục dọc màu xám `#94A3B8` 10px: **"0"**, **"50tr"**, **"100tr"**, **"150tr"**.
     - Không có chú thích màu (chỉ một đường nên tiêu đề đã đủ định danh).
6. Cách 20px: **thẻ cơ cấu phòng** trắng bo 20px, lề 20px, lề trong 18px:
   - Tiêu đề **"Cơ cấu buồng phòng"** navy 16px đậm 600.
   - Cách 14px: **một thanh ngang duy nhất chia đoạn** (stacked bar), cao 14px, bo tròn hai đầu, chiều rộng hết thẻ. Các đoạn cách nhau đúng 2px khe hở màu trắng (không dùng viền):
     đoạn `#EF4444` chiếm 55% · `#10B981` chiếm 25% · `#3B82F6` chiếm 10% · `#F59E0B` chiếm 5% · `#6B7280` chiếm 5%.
   - Cách 14px: **chú thích** xếp 2 hàng, mỗi mục gồm chấm tròn 8px màu tương ứng + nhãn xám 12px + số navy 12px đậm 700:
     **"Đang có khách 11"** · **"Phòng trống 5"** · **"Đang dọn dẹp 2"** · **"Đã đặt cọc 1"** · **"Bảo trì 1"**
7. Cách 24px, lề 20px: nhãn mục **"TRUY CẬP NHANH"** xám 11px đậm 700 giãn chữ 1px.
8. Cách 12px: **2 thẻ module** ngang hàng, cách nhau 12px, thẻ trắng bo 20px, bóng nhẹ, lề trong 16px, cao 120px, xếp dọc bên trong:
   - Khối vuông bo 14px cỡ 44×44 chứa biểu tượng trắng — thẻ 1 nền gradient navy (biểu tượng lưới ô vuông), thẻ 2 nền gradient gold (biểu tượng hóa đơn).
   - Cách 12px: tiêu đề navy 14px đậm 700 — **"Sơ đồ Buồng phòng"** và **"Thu ngân & Hóa đơn"**.
   - Cách 4px: dòng phụ xám 11px — **"Xem trạng thái phòng"** và **"4 hóa đơn chờ thu"**.

**Tuyệt đối tránh:** biểu đồ hai trục tung, biểu đồ tròn chia lát cho tỷ lệ lấp đầy, ghi số trên mọi điểm của đường, lưới kẻ đứt nét hoặc đậm màu, khối màu bão hòa lớn.
