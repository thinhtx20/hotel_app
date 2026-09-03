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

# Màn hình 1/10 — MÀN HÌNH CHỜ (Splash)

Toàn màn phủ **gradient navy** `#0F172A → #1E293B` theo hướng chéo 135°. Cảm giác: bước vào sảnh khách sạn 5 sao lúc chạng vạng.

**Bố cục dọc, căn giữa:**

1. Phía sau, rất mờ (opacity ~6%): đường nét kiến trúc mảnh màu gold — hình bóng một tòa khách sạn hoặc hoa văn hình học tinh tế. Chỉ đủ thấy chiều sâu, tuyệt đối không nổi bật.
2. Chính giữa: một khối vuông bo góc 28px, kích thước 96×96, nền trắng trong suốt 10% (hiệu ứng kính mờ), viền gold mảnh 1px. Bên trong là **biểu tượng khách sạn** (tòa nhà hoặc chuông lễ tân) màu gold `#FBBF24`, cỡ 48px.
3. Cách 28px bên dưới: chữ **"Luxe Grand Hotel"** — trắng, 28px, đậm 700, giãn chữ 1.5px.
4. Cách 10px: một đường kẻ ngang gold dài 40px, dày 2px, bo tròn hai đầu.
5. Cách 10px: chữ **"Trải nghiệm nghỉ dưỡng đẳng cấp"** — trắng 60% opacity, 14px, giãn chữ 0.5px.
6. Cách 64px bên dưới: vòng tải mảnh (nét 2.5px) màu gold `#FBBF24`, đường kính 28px, đang quay dở một cung.
7. Sát đáy màn, cách lề dưới 40px: chữ **"Phiên bản 1.0.0"** — trắng 30% opacity, 11px.

**Điểm nhấn:** một quầng sáng gold rất nhẹ tỏa ra sau khối biểu tượng, như ánh đèn chùm. Đây là màn hình tĩnh nên phải toát lên sự tĩnh lặng và cao cấp.
