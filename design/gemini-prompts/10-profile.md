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

# Màn hình 10/10 — HỒ SƠ CÁ NHÂN

**Bố cục từ trên xuống:**

1. **Đầu màn gradient navy** `#0F172A → #1E293B` cao 260px, **bo cong mềm ở đáy** (đường cong lồi xuống, bán kính lớn 40px), bên trong có hoa văn hình học gold rất mờ (opacity 5%):
   - Hàng trên, lề 20px: nút quay lại mũi tên trắng bên trái, chữ **"Hồ Sơ Cá Nhân"** trắng 17px đậm 600 căn giữa, biểu tượng bánh răng trắng bên phải.
   - Căn giữa, cách 24px: **ảnh đại diện** tròn 96px nền `#1E293B`, viền gold `#D97706` dày 3px, có quầng sáng gold rất nhẹ xung quanh. Bên trong là chữ cái **"N"** màu gold `#FBBF24` 40px đậm 700. Góc dưới bên phải vòng tròn: một chấm tròn nhỏ 24px nền gold viền trắng 2px chứa biểu tượng máy ảnh trắng.
   - Cách 14px: **"Nguyễn Văn A"** trắng 22px đậm 700, căn giữa.
   - Cách 4px: **"customer@hotel.com"** trắng 60% 13px, căn giữa.
   - Cách 10px: một **huy hiệu** bo tròn hoàn toàn, nền gold 18% opacity, viền gold 1px, lề trong 12×5px, chứa biểu tượng ngôi sao nhỏ gold và chữ **"Khách hàng"** gold `#FBBF24` 12px đậm 600.
2. **Thẻ thống kê** trắng bo 20px, lề 20px, chồng đè lên đáy đường cong navy 32px, bóng mềm, cao 84px: 3 cột chia đều, giữa các cột là đường kẻ dọc mảnh `#E2E8F0` cao 40px. Mỗi cột có số navy 20px đậm 700 và nhãn xám 11px bên dưới:
   **"12"** / **"Lượt đặt"** · **"3"** / **"Đang hoạt động"** · **"4.9"** / **"Đánh giá"** (riêng số 4.9 có ngôi sao gold nhỏ phía trước)
3. Cách 28px, lề 20px: nhãn mục **"TÀI KHOẢN"** xám `#94A3B8` 11px đậm 700 giãn chữ 1px.
4. Cách 12px: **thẻ nhóm menu** trắng bo 20px, bóng nhẹ, chứa 3 dòng cách nhau bởi đường kẻ mảnh chỉ kéo dài từ sau biểu tượng. Mỗi dòng cao 60px, lề trong 16px:
   - Bên trái: khối vuông bo 12px cỡ 40×40 nền màu pha loãng 10% chứa biểu tượng viền mảnh cùng màu.
   - Giữa: tiêu đề navy 15px đậm 600, và với dòng có giá trị thì thêm dòng phụ xám 12px bên dưới.
   - Bên phải: mũi tên nhỏ `>` màu `#94A3B8`.
   - Ba dòng: **"Số điện thoại"** / phụ **"0912345678"** (biểu tượng điện thoại, xanh dương) · **"Đổi mật khẩu"** (biểu tượng ổ khóa, gold) · **"Phương thức thanh toán"** / phụ **"Chưa liên kết"** (biểu tượng thẻ, tím)
5. Cách 24px, lề 20px: nhãn mục **"ỨNG DỤNG"** xám 11px đậm 700 giãn chữ 1px.
6. Cách 12px: **thẻ nhóm menu thứ hai** cùng kiểu, 2 dòng:
   - **"Thông báo"** (biểu tượng chuông, xanh lá) — bên phải là công tắc bật/tắt đang BẬT, nền gold, núm tròn trắng.
   - **"Ngôn ngữ"** / phụ **"Tiếng Việt"** (biểu tượng quả địa cầu, xám) — bên phải là mũi tên `>`.
7. Cách 28px, lề 20px: **nút đăng xuất** rộng hết lề, cao 52px, bo 12px, nền trắng, viền đỏ `#EF4444` 1.5px, chứa biểu tượng đăng xuất và chữ **"Đăng Xuất"** màu đỏ `#EF4444` 15px đậm 600.
8. Cách 16px, căn giữa: **"Luxe Grand Hotel • Phiên bản 1.0.0"** xám `#94A3B8` 11px.
