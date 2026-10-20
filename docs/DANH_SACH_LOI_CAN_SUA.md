# Danh sách lỗi cần sửa – Luxe Grand Hotel

Ngày rà soát: 20/10/2026. Nguồn: kiểm thử API trên máy chủ Render (`tool/docx/run_api_tests.js`) và đọc mã nguồn.

Trừ lỗi số 9 (ứng dụng Flutter `hotel_app`), mọi lỗi đều nằm ở backend `D:/duan/Hotel-Management`.

| # | Lỗi | Mức độ | Vị trí |
| :-: | :--- | :-: | :--- |
| 1 | Token vẫn dùng được sau khi đăng xuất (BUG-01) | Cao | `src/auth/auth.service.ts:716`, `src/auth/jwt.strategy.ts:80` |
| 2 | OTP khôi phục mật khẩu luôn là `123456` | Cao | `src/auth/auth.service.ts:441, 501, 548` |
| 3 | Tài khoản mặc định đăng nhập được bằng `123456` | Cao | `src/auth/auth.service.ts:90–200` |
| 4 | JWT secret dự phòng viết cứng trong code | Cao | `src/auth/auth.module.ts:14`, `jwt.strategy.ts:30`, `auth.service.ts:608, 619, 754, 756` |
| 5 | API gửi thông báo không giới hạn vai trò | Cao | `src/notifications/notifications.controller.ts:19, 61, 86` |
| 6 | Cron nhắc lịch chạy lúc 01:00 sáng | Trung bình | `src/notifications/checkin-reminder.service.ts:29` |
| 7 | Tiền lưu kiểu `Float` | Trung bình | `prisma/schema.prisma` (21 trường) |
| 8 | `POST /auth/login` trả 201 thay vì 200 | Thấp | `src/auth/auth.controller.ts:69` |
| 9 | Điều kiện dự phòng của nút “Hủy đơn” sai | Thấp | `hotel_app/lib/features/customer/screens/my_bookings_screen.dart:977–979, 1141–1142` |

---

## Ưu tiên cao – bảo mật

### 1. Token vẫn dùng được sau khi đăng xuất (BUG-01)

- **Phát hiện bởi:** ca kiểm thử TC37 (không đạt).
- **Tái hiện:** đăng nhập → `POST /auth/logout` (201) → gọi lại `GET /auth/me` bằng token cũ → vẫn trả **200** thay vì 401.
- **Nguyên nhân:**
  - `auth.service.ts:716`: `logout()` chỉ đưa access token vào blacklist khi `redisService.isReady`. Máy chủ Render không có Redis nên bước này bị bỏ qua.
  - `jwt.strategy.ts:80`: chỉ so `sid` khi `user.activeSessionId` khác null, mà đăng xuất lại xóa `activeSessionId` → token cũ vẫn hợp lệ.
- **Cách sửa:**
  1. Bỏ điều kiện `isReady` ở bước ghi blacklist (`RedisService.set()` đã tự lưu vào bộ nhớ khi chưa có Redis).
  2. Sửa điều kiện trong `jwt.strategy.ts`:
     ```ts
     if (
       isSingleDeviceRole(user.role) &&
       payload.sid &&
       payload.sid !== user.activeSessionId
     ) {
       throw sessionRevokedException(user.activeDevice);
     }
     ```
  3. Bổ sung dịch vụ Redis cho Render nếu chạy nhiều instance.

### 2. OTP khôi phục mật khẩu luôn là `123456`

- **Vị trí:** `auth.service.ts:441`, `:501`, `:548` – `process.env.DEFAULT_OTP || '123456'`.
- **Hậu quả:** ai biết email người khác cũng đặt lại được mật khẩu của họ.
- **Cách sửa:**
  ```ts
  import { randomInt } from 'crypto';

  const otp =
    process.env.NODE_ENV !== 'production' && process.env.DEFAULT_OTP
      ? process.env.DEFAULT_OTP
      : randomInt(100000, 1000000).toString();
  ```
  Ở bước xác thực (`:501`, `:548`) chỉ so với OTP đã lưu, không chấp nhận mã mặc định.

### 3. Tài khoản mặc định đăng nhập được bằng `123456`

- **Vị trí:** `auth.service.ts:90–200` – khối `SYSTEM_DEFAULT_ACCOUNTS`; dòng 174 `inputPassword === '123456'`.
- **Hậu quả:** đăng nhập được `admin@hotel.com` bằng mật khẩu `123456`; tài khoản admin bị khóa cũng tự mở lại.
- **Cách sửa:** xóa toàn bộ khối tự tạo/khôi phục tài khoản và so khớp mật khẩu mặc định trong `login()`. Chỉ tạo tài khoản mẫu bằng `prisma/seed.ts`.

### 4. JWT secret dự phòng viết cứng trong code

- **Vị trí:** `auth.module.ts:14`, `jwt.strategy.ts:30`, `auth.service.ts:608, 619, 754, 756` – chuỗi `'super-secret-hotel-jwt-key-2026-…'`.
- **Hậu quả:** nếu quên khai báo biến môi trường, ai đọc được mã nguồn đều tự ký được token admin.
- **Cách sửa:** đọc secret một chỗ và dừng khởi động khi thiếu:
  ```ts
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('Thiếu biến môi trường JWT_SECRET');
  ```
  Làm tương tự với `JWT_REFRESH_SECRET`.

### 5. API gửi thông báo không giới hạn vai trò

- **Vị trí:** `notifications.controller.ts:19` (`@UseGuards(JwtAuthGuard)`), route `send` (`:61`) và `broadcast` (`:86`).
- **Hậu quả:** khách hàng gửi được thông báo tới bất kỳ người dùng nào hoặc toàn hệ thống.
- **Cách sửa:**
  ```ts
  @UseGuards(JwtAuthGuard, RolesGuard)
  export class NotificationsController {
    @Roles(Role.ADMIN)
    @Post('send')
    // ...

    @Roles(Role.ADMIN)
    @Post('broadcast')
    // ...
  }
  ```

---

## Ưu tiên trung bình – nghiệp vụ

### 6. Cron nhắc lịch nhận phòng chạy lúc 01:00 sáng

- **Vị trí:** `checkin-reminder.service.ts:29` – `@Cron('0 1 * * *', { timeZone: 'Asia/Ho_Chi_Minh' })`.
- **Nguyên nhân:** chú thích ghi “08:00 (01:00 UTC)” nhưng đã khai báo múi giờ Việt Nam nên chạy lúc 01:00 giờ Việt Nam.
- **Cách sửa:** đổi thành `'0 8 * * *'`.

### 7. Tiền lưu kiểu `Float`

- **Vị trí:** `prisma/schema.prisma` – `basePrice`, `totalAmount`, `depositAmount`, `roomAmount`, `finalAmount`, `paidAmount`, `amount`, `initialCash`, `actualCash`, `expectedCash`… (21 trường).
- **Hậu quả:** sai số làm tròn khi cộng trừ nhiều khoản (hiện đang vá bằng `roundMoney`).
- **Cách sửa:** đổi sang `Decimal @db.Decimal(14, 2)`, chạy `prisma migrate`, sửa các chỗ tính toán vì Prisma trả `Prisma.Decimal` thay vì `number`. Khối lượng lớn – có thể để sau.

---

## Ưu tiên thấp

### 8. `POST /auth/login` trả 201 thay vì 200

- **Vị trí:** `auth.controller.ts:69`; tương tự `refresh-token`, `logout`, `verify-reset-otp`.
- **Nguyên nhân:** NestJS mặc định trả 201 cho mọi `@Post`, nhưng các API này không tạo tài nguyên mới.
- **Cách sửa:** thêm `@HttpCode(HttpStatus.OK)` cho các route trên. Nhớ sửa mã mong đợi của TC04, TC05, TC10, TC36 trong `tool/docx/ktpm_test_cases.js` từ 201 thành 200.

### 9. Điều kiện dự phòng của nút “Hủy đơn” sai (app Flutter)

- **Vị trí:** `my_bookings_screen.dart:977–979` và `:1141–1142`.
- **Nguyên nhân:** app dùng `booking.canCancel` do API trả về (đúng), nhưng khi thiếu trường này thì mặc định cho hủy cả đơn `CONFIRMED`, trong khi API chỉ cho khách hủy đơn `PENDING` (trả 403 – ca TC31).
- **Cách sửa:**
  ```dart
  final canCancel = booking.canCancel ?? (statusUpper == 'PENDING');
  ```

---

## Sau khi sửa

1. Deploy lại backend lên Render.
2. Chạy lại kiểm thử: `node tool/docx/run_api_tests.js` (TC37 sẽ đạt → 39/39).
3. Cập nhật báo cáo:
   - Báo cáo KT&TKPM: `node tool/docx/build_ktpm_report.js` (số liệu tự cập nhật).
   - Báo cáo tốt nghiệp: sửa tay mục 5.2 (BUG-01), 5.6 và 7.2 trong `BAO_CAO_TOT_NGHIEP_HE_THONG_QUAN_LY_KHACH_SAN.md`, rồi chạy `node tool/docx/md_to_docx.js BAO_CAO_TOT_NGHIEP_HE_THONG_QUAN_LY_KHACH_SAN.md Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel_v2.docx`.

> **Đính chính:** hai báo cáo hiện có câu “ứng dụng hiển thị nút Hủy đơn cho cả đơn đã xác nhận”. Thực tế app dùng `canCancel` từ API nên hiển thị đúng; chỉ phần dự phòng (lỗi 9) là sai. Cần sửa lại câu này trong mục Hạn chế của cả hai báo cáo.
