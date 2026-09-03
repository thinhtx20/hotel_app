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

# Màn hình 3/10 — ĐĂNG KÝ TÀI KHOẢN

Cùng ngôn ngữ thị giác với màn Đăng nhập nhưng ảnh hero thấp hơn, nhường chỗ cho biểu mẫu dài.

**Bố cục từ trên xuống:**

1. **Dải hero** chiếm 20% chiều cao trên cùng: gradient navy `#0F172A → #1E293B`, bên trong có hoa văn hình học gold rất mờ. Góc trên bên trái: nút quay lại hình mũi tên màu trắng. Căn giữa dải: chữ **"Đăng Ký Tài Khoản"** trắng 18px đậm 600.
2. **Thẻ trắng** bo góc trên 28px chồng đè lên đáy dải hero 24px, kéo xuống hết màn.
3. Trong thẻ, lề 24px, cách mép trên 28px:
   - **"Tạo tài khoản khách hàng"** — navy, 22px, đậm 700.
   - Cách 6px: **"Trải nghiệm dịch vụ nghỉ dưỡng cao cấp tại Luxe Grand"** — xám `#64748B`, 13px.
4. Cách 28px, **4 ô nhập** cách nhau 16px, cao 56px, bo 12px, viền `#E2E8F0`:
   - Nhãn **"Họ và tên"**, nội dung mờ **"Nguyễn Văn A"**, biểu tượng người viền mảnh.
   - Nhãn **"Email"**, nội dung mờ **"khachhang@gmail.com"**, biểu tượng phong bì.
   - Nhãn **"Số điện thoại"**, nội dung mờ **"0912345678"**, biểu tượng điện thoại.
   - Nhãn **"Mật khẩu"**, nội dung 8 chấm tròn, biểu tượng ổ khóa, biểu tượng con mắt bên phải. Ô này đang được chọn nên viền gold 2px.
5. Ngay dưới ô mật khẩu, cách 10px: **chỉ báo độ mạnh mật khẩu** — 3 thanh ngang bằng nhau, bo tròn, dày 4px, cách nhau 6px. Thanh 1 và 2 màu gold `#F59E0B`, thanh 3 màu `#E2E8F0`. Bên phải chỉ báo là chữ **"Trung bình"** màu `#F59E0B`, 12px.
6. Cách 20px: một dòng có ô đánh dấu vuông bo 4px (đã tích, nền gold) rồi đến chữ **"Tôi đồng ý với Điều khoản dịch vụ"** — xám `#64748B` 13px, riêng cụm **"Điều khoản dịch vụ"** màu gold đậm 600.
7. Cách 28px: **nút chính** rộng hết lề, cao 54px, gradient gold, bo 12px, chữ **"Tạo Tài Khoản"** trắng 16px đậm 600, có quầng bóng gold.
8. Cách 20px, căn giữa: **"Đã có tài khoản? "** xám, liền sau **"Đăng nhập ngay"** gold đậm 700.
