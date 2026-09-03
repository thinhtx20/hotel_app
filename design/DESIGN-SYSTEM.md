# Hệ thống thiết kế — Luxe Grand Hotel (Modern Luxury)

Đây là nguồn chân lý duy nhất cho cả prompt Gemini lẫn code Flutter.

## Màu

| Vai trò | Mã | Ghi chú |
|---|---|---|
| Navy chính | `#0F172A` | AppBar, tiêu đề, nền tối |
| Navy nhạt | `#1E293B` | Điểm cuối gradient |
| Gold nhấn | `#D97706` | Nút chính, giá tiền, chỉ báo |
| Gold sáng | `#FBBF24` | Điểm cuối gradient gold, viền ánh kim |
| Nền | `#F8FAFC` | Nền scaffold |
| Thẻ | `#FFFFFF` | Nền card |
| Viền | `#E2E8F0` | Đường kẻ 1px |
| Chữ chính | `#0F172A` | |
| Chữ phụ | `#64748B` | |
| Chữ mờ | `#94A3B8` | Placeholder |

### Trạng thái phòng
`Phòng trống #10B981` · `Đang có khách #EF4444` · `Đã đặt cọc #F59E0B` · `Đang dọn dẹp #3B82F6` · `Bảo trì #6B7280`

### Gradient
- **Navy:** `#0F172A → #1E293B`, 135°
- **Gold:** `#D97706 → #FBBF24`, 135°
- **Phủ ảnh:** trong suốt → `#0F172A` ở 85% opacity, từ trên xuống

## Chữ — font Outfit

| Cấp | Cỡ | Đậm |
|---|---|---|
| Display | 32 | 700 |
| Tiêu đề màn | 24 | 700 |
| Tiêu đề mục | 18 | 600 |
| Tiêu đề thẻ | 16 | 600 |
| Nội dung | 14 | 400 |
| Phụ | 13 | 400 |
| Nhãn nhỏ | 11 | 600, giãn chữ 0.5 |

## Khoảng cách
Thang 4: `4 · 8 · 12 · 16 · 24 · 32 · 48`. Lề màn hình mặc định 20px. Khoảng cách giữa các thẻ 12px, giữa các mục 24px.

## Bo góc
Thẻ lớn `20` · Thẻ nhỏ `16` · Nút `12` · Ô nhập `12` · Chip/pill `999` · Ảnh `16` · Bottom sheet `28` (chỉ trên)

## Đổ bóng
- **Nhẹ:** `0 1px 3px rgba(15,23,42,0.04)` — thẻ thường
- **Vừa:** `0 4px 16px rgba(15,23,42,0.08)` — thẻ nổi
- **Nhấn:** `0 8px 24px rgba(217,119,6,0.25)` — nút gold

## Nguyên tắc thị giác
1. Khoảng trắng rộng — sang trọng đến từ chỗ trống, không phải chỗ nhồi thêm.
2. Ảnh phòng là nhân vật chính ở phía khách hàng; số liệu là nhân vật chính ở phía quản trị.
3. Gold dùng dè dặt — chỉ cho hành động chính và giá tiền. Dùng tràn lan là mất sang.
4. Bóng khuếch tán, không viền cứng. Ưu tiên bóng mềm hơn đường kẻ.
5. Mọi trạng thái rỗng phải có minh họa + một câu giải thích + một nút hành động.
6. Mọi trạng thái đang tải phải là skeleton shimmer, không phải vòng xoay giữa màn hình.

## Quy tắc màu trạng thái — đã kiểm chứng bằng công cụ

Chạy validator bảng màu (kiểm tra mù màu + tương phản) trên 5 màu trạng thái hiện tại, kết quả:

- **Tách biệt mù màu: ĐẠT** (cặp sát nhau khó nhất `#EF4444` ↔ `#10B981`, ΔE 8.1 deutan) — dùng làm màu tô được.
- **Tương phản chữ: KHÔNG ĐẠT** — `#10B981` chỉ đạt 2.47:1 và `#F59E0B` chỉ 2.09:1 trên nền sáng. **Đây là lỗi thật đang có trong `RoomStatusBadge`**: chữ vàng cam trên nền trắng pha gần như không đọc được.

### Quy tắc rút ra

| Dùng cho | Bảng màu | Lý do |
|---|---|---|
| **Màu tô** (ô phòng, đoạn biểu đồ, chấm chú thích) | `#10B981` `#EF4444` `#F59E0B` `#3B82F6` `#6B7280` | Đạt kiểm tra mù màu |
| **Màu chữ trên nền sáng** | `#047857` `#DC2626` `#B45309` `#1D4ED8` `#4B5563` | Đạt tương phản ≥ 3:1 |
| **Màu trên nền tối** | `#34D399` `#F87171` `#FBBF24` `#60A5FA` `#9CA3AF` | Đạt tương phản trên nền navy |

**Ràng buộc bắt buộc:** trạng thái không bao giờ chỉ được thể hiện bằng màu — luôn phải kèm nhãn chữ (và nên có thêm biểu tượng). Bộ màu chữ đậm ở trên KHÔNG được dùng làm màu tô cạnh nhau: cặp `#B45309` ↔ `#DC2626` chỉ đạt ΔE 2.8 dưới mắt mù màu deutan, gần như không phân biệt được.

## Quy tắc biểu đồ (màn Quản trị)

- Tỷ lệ lấp đầy là **vòng cung đo có rãnh nền**, không phải biểu đồ tròn 2 lát.
- Doanh thu 7 ngày là **một đường duy nhất** dày 2px + vùng tô gradient; chỉ ghi nhãn ở điểm cuối, không ghi số trên mọi điểm.
- Cơ cấu phòng là **một thanh ngang chia đoạn**, khe hở 2px màu nền giữa các đoạn (không dùng viền), kèm chú thích đầy đủ chữ.
- Lưới kẻ: liền nét, 1px, màu `#F1F5F9`. Không lưới dọc, không đường đứt nét.
- Không bao giờ dùng biểu đồ hai trục tung.
