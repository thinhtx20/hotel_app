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

# Màn hình 7/10 — SƠ ĐỒ BUỒNG PHÒNG (dành cho Lễ tân)

Đây là màn hình **công cụ vận hành**, không phải màn hình bán hàng: mật độ thông tin cao hơn, nhưng vẫn giữ sự tinh tế. Người lễ tân phải liếc một cái là nắm được tình hình cả khách sạn.

**Bố cục từ trên xuống:**

1. **Đầu màn gradient navy** `#0F172A → #1E293B` cao 150px, bo góc dưới 28px:
   - Hàng trên, lề 20px: bên trái chữ **"Sơ Đồ Buồng Phòng"** trắng 20px đậm 700 và ngay dưới là **"Cập nhật lúc 09:42"** trắng 50% 12px. Bên phải là 2 nút tròn kính mờ 40px chứa biểu tượng làm mới và biểu tượng đăng xuất.
   - Phần dưới của dải: **3 ô thống kê nhanh** ngang hàng, nền trắng trong suốt 10%, bo 14px, mỗi ô có số lớn trắng 22px đậm 700 và nhãn nhỏ trắng 60% 11px:
     **"6"** / **"TRỐNG"** · **"11"** / **"CÓ KHÁCH"** · **"3"** / **"DỌN DẸP"**
2. **Thẻ chú thích màu** trắng bo 16px, lề 20px, chồng đè lên đáy dải navy 20px, bóng mềm, lề trong 12px: 5 mục xếp 2 hàng, mỗi mục gồm chấm tròn 8px + chữ 11px:
   **"Phòng trống"** `#10B981` · **"Đang có khách"** `#EF4444` · **"Đã đặt cọc"** `#F59E0B` · **"Đang dọn dẹp"** `#3B82F6` · **"Bảo trì"** `#6B7280`
3. Cách 24px, lề 20px: **tiêu đề tầng** — chữ **"TẦNG 1"** navy 13px đậm 700 giãn chữ 1px, bên cạnh là một đường kẻ mảnh `#E2E8F0` kéo dài hết chiều rộng, và ở mép phải là chữ **"4/6 trống"** xám 11px.
4. Cách 12px: **lưới 3 cột ô phòng**, cách nhau 10px, mỗi ô vuông bo 16px cao 88px, nền là màu trạng thái pha loãng 8%, viền màu trạng thái 1.5px, bóng rất nhẹ. Trong mỗi ô, căn giữa dọc:
   - Trên cùng bên phải trong ô: một biểu tượng nhỏ 14px màu trạng thái (giường / người / chìa khóa / chổi lau / cờ lê).
   - Chính giữa: **số phòng** màu trạng thái, 20px, đậm 700.
   - Dưới số phòng 4px: nhãn trạng thái màu trạng thái, 10px, đậm 600.
   - Tầng 1 gồm 6 ô: **"101"** Phòng trống · **"102"** Phòng trống · **"103"** Đang có khách · **"104"** Đang dọn dẹp · **"105"** Phòng trống · **"106"** Đã đặt cọc
5. Cách 24px: **"TẦNG 2"** cùng kiểu, chữ mép phải **"2/6 trống"**, lưới 6 ô:
   **"201"** Đang có khách · **"202"** Đang có khách · **"203"** Phòng trống · **"204"** Bảo trì · **"205"** Đã đặt cọc · **"206"** Phòng trống
6. Cách 24px: **"TẦNG 3"** hiện một phần rồi bị cắt ở mép dưới màn hình (thể hiện danh sách còn cuộn tiếp).

**Lưu ý:** các ô phòng phải trông như những phím bấm có chiều sâu và bấm được, không phải ô bảng tính phẳng.
