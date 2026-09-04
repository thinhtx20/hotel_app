# Ma trận phân quyền cho Frontend — Luxe Grand Hotel

> Tài liệu dành cho team FE (Flutter). Trả lời đúng một câu hỏi: **role nào gọi được endpoint nào, và vẽ màn hình gì.**
> Payload chi tiết xem [API-CONTRACT.md](../API-CONTRACT.md).
>
> Ma trận dưới đây **chép đúng code backend đang chạy** (`src/**/*.controller.ts`), không phải thiết kế mong muốn. Các hành vi vừa thay đổi trong đợt rà soát này được liệt kê ở [Phần 6](#6-những-gì-vừa-siết-lại-ở-backend).
>
> Base URL: `https://<host>/api/v1` · Swagger: `/api/docs`

---

## 1. Bốn vai trò & tài khoản demo

| Role | Vai trò nghiệp vụ | Tài khoản demo | Mật khẩu |
|---|---|---|---|
| `ADMIN` | Quản trị viên — toàn quyền: nhân sự, phòng, hạng phòng, báo cáo doanh thu năm | `admin@hotel.com` | `Admin@123` |
| `RECEPTIONIST` | Lễ tân — nhận/trả phòng, sơ đồ phòng, ghi dịch vụ, xem khách hàng | `reception@hotel.com` | `Staff@123` |
| `CASHIER` | Thu ngân — hóa đơn, ghi nhận thanh toán, doanh thu theo ngày | `cashier@hotel.com` | `Staff@123` |
| `CUSTOMER` | Khách hàng — tìm phòng, đặt phòng, xem đơn của mình | `customer@hotel.com` | `Cust@123` |

Bốn tài khoản này được backend tự tạo/đồng bộ khi khởi động ([`prisma.service.ts`](../src/prisma/prisma.service.ts), [`auth.service.ts`](../src/auth/auth.service.ts)) — luôn đăng nhập được trên mọi môi trường.

**Về việc cấp quyền:**
- `POST /auth/register` **luôn ép `CUSTOMER`** ở server. Client có gửi `role` lên cũng bị bỏ qua.
- Chỉ `PATCH /api/v1/users/:id` (ADMIN) mới đổi được role của một tài khoản.
- Role nằm trong payload JWT và trong `GET /auth/me` → FE lấy từ đó để dựng menu.

---

## 2. Backend chặn bằng cách nào

Có ba tầng, FE cần phân biệt để xử lý lỗi đúng:

| Tầng | Ý nghĩa | Ký hiệu trong bảng |
|---|---|---|
| `@Public()` hoặc không gắn guard | Không cần token, khách vãng lai gọi được | 🔓 |
| `JwtAuthGuard` | Chỉ cần đăng nhập, **không phân biệt role** | ✅ cho cả 4 role |
| `JwtAuthGuard` + `RolesGuard` + `@Roles(...)` | Phải đúng role, sai thì `403` | ✅ / ❌ theo từng cột |

**Xử lý lỗi ở FE:**

| Mã | Nghĩa | FE làm gì |
|---|---|---|
| `401` | Chưa đăng nhập / access token hết hạn | Gọi `POST /auth/refresh-token` rồi retry đúng 1 lần; thất bại thì về màn đăng nhập |
| `403` | Đúng token nhưng **sai role** | **Không retry.** Đây là lỗi thiết kế UI — role đó lẽ ra không được thấy nút/màn hình đó |

Message `403` do backend trả về có dạng:
`Quyền truy cập bị từ chối: Yêu cầu vai trò [ADMIN, RECEPTIONIST]` — đừng hiển thị nguyên văn cho khách, chỉ log lại.

**Ký hiệu bảng:** ✅ gọi được · ❌ bị `403` · 🔓 công khai (không cần token) · ⚠️ gọi được nhưng có lưu ý, đọc cột ghi chú.

---

## 3. Ma trận endpoint × role

### 3.1 Auth — `/api/v1/auth`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `POST /auth/register` | Đăng ký (luôn ra `CUSTOMER`) | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/login` | Đăng nhập | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/refresh-token` | Xoay vòng cặp token | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/forgot-password` | Gửi OTP qua email | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/verify-reset-otp` | Xác thực OTP | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/reset-password` | Đặt lại mật khẩu | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /auth/logout` | Thu hồi token | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `GET /auth/me` | Hồ sơ + role hiện tại | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `POST /auth/change-password` | Đổi mật khẩu | ✅ | ✅ | ✅ | ✅ | ❌ 401 |

> `logout` gắn `@Public()` có chủ đích: khi access token đã hết hạn khách vẫn đăng xuất dọn phiên được, chỉ cần gửi `refreshToken` trong body.

### 3.2 Users — `/api/v1/users`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `PATCH /users/me` | Sửa hồ sơ của chính mình | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `GET /users?role=` | Danh sách người dùng / nhân sự | ✅ | ✅ | ❌ | ❌ | ❌ |
| `GET /users/:id` | Chi tiết một người dùng | ✅ | ✅ | ❌ | ❌ | ❌ |
| `PATCH /users/:id` | Sửa thông tin **và role** | ✅ | ❌ | ❌ | ❌ | ❌ |
| `DELETE /users/:id` | Vô hiệu hóa tài khoản (`isActive=false`) | ✅ | ❌ | ❌ | ❌ | ❌ |

> Lễ tân **xem** được danh sách khách nhưng **không sửa** được — màn "Khách hàng" của lễ tân phải là read-only.

### 3.3 Room Types — `/api/v1/room-types`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `GET /room-types` | Danh sách hạng phòng | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `GET /room-types/:id` | Chi tiết hạng phòng | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /room-types` | Tạo hạng phòng | ✅ | ❌ | ❌ | ❌ | ❌ |
| `PATCH /room-types/:id` | Sửa hạng phòng (gồm album ảnh) | ✅ | ❌ | ❌ | ❌ | ❌ |
| `DELETE /room-types/:id` | Xóa hạng phòng | ✅ | ❌ | ❌ | ❌ | ❌ |

### 3.4 Rooms — `/api/v1/rooms`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `GET /rooms` | Sơ đồ phòng / danh sách + lọc | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 ⚠️ |
| `GET /rooms/:id` | Chi tiết phòng | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `GET /rooms/search` | Tìm kiếm full-text (Elasticsearch) | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `GET /rooms/available` | Phòng trống theo khoảng ngày | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |
| `POST /rooms` | Tạo phòng mới | ✅ | ⚠️ | ❌ | ❌ | ❌ |
| `PATCH /rooms/:id/approve` | Duyệt phòng chờ → `AVAILABLE` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `PATCH /rooms/:id/reject` | Từ chối phòng chờ → `REJECTED` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `PATCH /rooms/:id/status` | Đổi nhanh trạng thái phòng | ✅ | ✅ | ❌ | ❌ | ❌ |
| `PATCH /rooms/:id` | Sửa thông tin phòng | ✅ | ❌ | ❌ | ❌ | ❌ |
| `DELETE /rooms/:id` | Xóa phòng | ✅ | ❌ | ❌ | ❌ | ❌ |

Ghi chú các ⚠️:
- **`GET /rooms`** — bốn endpoint `GET` của nhóm này dùng **xác thực tùy chọn**: không token vẫn gọi được, nhưng **có gửi Bearer token thì backend nhận diện nhân viên**. Khách hàng và khách vãng lai chỉ nhận về phòng đang vận hành; phòng `PENDING_APPROVAL` / `REJECTED` chỉ hiện với ADMIN và RECEPTIONIST. ⇒ **App nhân viên phải luôn đính token vào cả các endpoint công khai này**, nếu không sẽ không thấy phòng chờ duyệt và không nhận được trường `notes` (ghi chú nội bộ).
- **`POST /rooms`** — RECEPTIONIST tạo được nhưng phòng bị ép `status = PENDING_APPROVAL`, phải qua `PATCH /rooms/:id/approve` mới vào hoạt động. ADMIN tạo là dùng ngay.

### 3.5 Bookings — `/api/v1/bookings`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `POST /bookings` | Tạo đơn đặt phòng | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `GET /bookings` | Danh sách đơn (lọc `status`/`customerId`/`roomId`) | ✅ | ✅ | ✅ | ⚠️ | ❌ 401 |
| `GET /bookings/:id` | Chi tiết đơn | ✅ | ✅ | ✅ | ⚠️ | ❌ 401 |
| `POST /bookings/:id/check-in` | Nhận phòng → `OCCUPIED` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `POST /bookings/:id/check-out` | Trả phòng + xuất hóa đơn | ✅ | ✅ | ✅ | ❌ | ❌ |
| `POST /bookings/:id/cancel` | Hủy đơn | ✅ | ✅ | ✅ | ⚠️ | ❌ 401 |
| `PATCH /bookings/:id/cancel` | Hủy đơn (alias cho client Flutter) | ✅ | ✅ | ✅ | ⚠️ | ❌ 401 |
| `POST /bookings/:id/services` | Ghi dịch vụ phát sinh (minibar, giặt là…) | ✅ | ✅ | ❌ | ❌ | ❌ |

Ghi chú các ⚠️ (đều liên quan tới `CUSTOMER`):
- **`GET /bookings`** — backend tự ép `customerId = id của chính khách`, nên khách chỉ thấy đơn của mình. Query `customerId` khách gửi lên bị bỏ qua. Đây là màn "Đơn của tôi".
- **`POST /bookings`** — tương tự, `customerId` trong body bị ghi đè bằng id người đang đăng nhập. Nhân viên đặt hộ thì `customerId` mới có tác dụng.
- **`GET /bookings/:id` và hủy đơn** — backend **kiểm tra chủ sở hữu**: khách gọi vào đơn của người khác nhận `403` kèm message `Bạn chỉ có thể xem và thao tác trên đơn đặt phòng của chính mình`. Nhân viên không bị chặn. FE vẫn nên điều hướng từ danh sách "Đơn của tôi" thay vì cho nhập `id` tùy ý.
- `POST` và `PATCH` `/:id/cancel` là **cùng một hành vi**, chọn một cái mà dùng.

### 3.6 Invoices — `/api/v1/invoices`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `GET /invoices/summary?date=` | Doanh thu + số hóa đơn trong ngày | ✅ | ✅ | ✅ | ❌ | ❌ |
| `GET /invoices/my?status=` | **Hóa đơn của chính tôi** | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `GET /invoices?status=` | Danh sách hóa đơn toàn khách sạn | ✅ | ✅ | ✅ | ❌ | ❌ |
| `GET /invoices/:id` | Chi tiết hóa đơn + bảng kê dịch vụ | ✅ | ✅ | ✅ | ⚠️ | ❌ |
| `POST /invoices/:id/pay` | Ghi nhận thanh toán | ✅ | ✅ | ✅ | ❌ | ❌ |
| `POST /invoices` | Tạo hóa đơn **thủ công** | ✅ | ❌ | ✅ | ❌ | ❌ |

> Ba điểm cần nhớ:
> 1. **Lễ tân bị `403` ở `POST /invoices`** nhưng lại **được** `POST /invoices/:id/pay`. Ẩn nút "Tạo hóa đơn", giữ nút "Ghi nhận thanh toán".
> 2. **`GET /invoices/my` là endpoint dành riêng cho app khách hàng** — chỉ trả hóa đơn gắn với đơn đặt phòng của tài khoản đang đăng nhập, không cần truyền tham số nào. Nhân viên gọi cũng chỉ thấy hóa đơn của chính họ; muốn xem toàn khách sạn thì dùng `GET /invoices`.
> 3. **`GET /invoices/:id`** khách hàng mở được, nhưng **chỉ hóa đơn thuộc đơn của mình** — sai chủ sở hữu trả `403` kèm message `Bạn chỉ có thể xem hóa đơn thuộc đơn đặt phòng của chính mình`. Luôn điều hướng từ `GET /invoices/my` hoặc từ `invoiceId` trong `GET /bookings/:id`.

### 3.7 Analytics — `/api/v1/analytics`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `GET /analytics/dashboard` | Tổng quan 10 chỉ số + chuỗi 7 ngày | ✅ | ✅ | ✅ | ❌ | ❌ |
| `GET /analytics/revenue/daily?range=` | Doanh thu ngày, 4 khoảng 1/7/14/30 | ✅ | ✅ | ✅ | ❌ | ❌ |
| `GET /analytics/occupancy-by-type` | Tỷ lệ lấp đầy theo hạng phòng | ✅ | ✅ | ❌ | ❌ | ❌ |
| `GET /analytics/revenue?year=` | Báo cáo doanh thu theo năm, 12 tháng | ✅ | ❌ | ❌ | ❌ | ❌ |

> `GET /analytics/dashboard` dùng chung được cho **cả ba vai trò nhân viên** — thu ngân cũng lấy được khối doanh thu và số hóa đơn chưa thu trong đúng một lần gọi. Chỉ hai endpoint sâu hơn còn phân biệt: `occupancy-by-type` (không dành cho thu ngân) và `revenue` theo năm (chỉ ADMIN).

### 3.8 Services — `/api/v1/services`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `GET /services` | Danh mục dịch vụ gia tăng | 🔓 | 🔓 | 🔓 | 🔓 | 🔓 |

### 3.9 Upload — `/api/v1/upload`

| Endpoint | Mục đích | ADMIN | LỄ TÂN | THU NGÂN | KHÁCH | Vãng lai |
|---|---|:--:|:--:|:--:|:--:|:--:|
| `POST /upload/avatar` | Ảnh đại diện (tự cập nhật hồ sơ) | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `POST /upload/image` | 1 ảnh đa năng (chọn `folder`) | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `POST /upload/images` | Nhiều ảnh đa năng (tối đa 10) | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `DELETE /upload?path=` | Xóa ảnh khỏi kho | ✅ | ✅ | ✅ | ✅ | ❌ 401 |
| `POST /upload/room` | 1 ảnh phòng, tự gắn vào `roomId`/`roomTypeId` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `POST /upload/rooms` | Album ảnh phòng, tự gắn vào phòng | ✅ | ✅ | ❌ | ❌ | ❌ |

> Chỉ hai endpoint `/upload/room` và `/upload/rooms` (loại có gắn ảnh vào phòng) mới chặn theo role. Muốn upload ảnh phòng ở màn của ADMIN mà không gắn tự động, dùng `/upload/images?folder=rooms` rồi tự gán mảng URL vào DTO `room-types`.

---

## 4. Điều hướng & màn hình theo role

### 4.1 `ADMIN` — vào thẳng Dashboard

| Tab / Màn hình | API nuôi màn hình |
|---|---|
| Tổng quan | `GET /analytics/dashboard`, `GET /analytics/occupancy-by-type` |
| Doanh thu | `GET /analytics/revenue?year=`, `GET /analytics/revenue/daily?range=` |
| Sơ đồ phòng | `GET /rooms`, `PATCH /rooms/:id/status`, `PATCH /rooms/:id/approve\|reject` |
| Quản lý phòng & hạng phòng | `POST|PATCH|DELETE /rooms`, `POST|PATCH|DELETE /room-types`, `POST /upload/rooms` |
| Đặt phòng | toàn bộ `/bookings` |
| Hóa đơn | toàn bộ `/invoices` |
| Nhân sự & khách hàng | `GET /users`, `PATCH /users/:id`, `DELETE /users/:id` |
| Hồ sơ | `GET /auth/me`, `PATCH /users/me`, `POST /auth/change-password`, `POST /upload/avatar` |

### 4.2 `RECEPTIONIST` — vào thẳng Sơ đồ phòng

| Tab / Màn hình | API nuôi màn hình |
|---|---|
| Tổng quan | `GET /analytics/dashboard`, `GET /analytics/occupancy-by-type` |
| Sơ đồ phòng | `GET /rooms`, `PATCH /rooms/:id/status`, `PATCH /rooms/:id/approve\|reject` |
| Nhận / trả phòng | `POST /bookings/:id/check-in`, `POST /bookings/:id/check-out`, `POST /bookings/:id/services` |
| Đặt phòng | `POST /bookings`, `GET /bookings`, `POST|PATCH /bookings/:id/cancel` |
| Hóa đơn (chỉ xem + thu tiền) | `GET /invoices`, `GET /invoices/:id`, `POST /invoices/:id/pay` |
| Khách hàng (read-only) | `GET /users?role=CUSTOMER`, `GET /users/:id` |
| Hồ sơ | như ADMIN |

**Phải ẩn ở màn lễ tân:** nút "Tạo hóa đơn thủ công" (`POST /invoices` → 403), toàn bộ tab Doanh thu năm (`GET /analytics/revenue` → 403), nút sửa/xóa phòng và hạng phòng (`PATCH|DELETE /rooms/:id`, `/room-types/:id` → 403), nút sửa/khóa tài khoản (`PATCH|DELETE /users/:id` → 403).

### 4.3 `CASHIER` — vào thẳng Hóa đơn

| Tab / Màn hình | API nuôi màn hình |
|---|---|
| Tổng quan thu ngân | `GET /analytics/dashboard` + `GET /invoices/summary?date=today` + `GET /analytics/revenue/daily?range=7` |
| Danh sách hóa đơn | `GET /invoices?status=UNPAID\|PARTIAL\|PAID` |
| Chi tiết & thanh toán | `GET /invoices/:id`, `POST /invoices/:id/pay` |
| Tạo hóa đơn thủ công | `POST /invoices` |
| Trả phòng (khi kiêm quầy) | `POST /bookings/:id/check-out` → dùng `invoiceId` ở response để mở thẳng màn thanh toán |
| Hồ sơ | như ADMIN |

**Phải ẩn/không gọi ở màn thu ngân:** `GET /analytics/occupancy-by-type` và `GET /analytics/revenue` (→ 403), nút đổi trạng thái phòng `PATCH /rooms/:id/status` (→ 403), `POST /bookings/:id/check-in` (→ 403), `POST /bookings/:id/services` (→ 403), toàn bộ tab Nhân sự.

### 4.4 `CUSTOMER` — vào thẳng Trang chủ

| Tab / Màn hình | API nuôi màn hình |
|---|---|
| Trang chủ / Tìm phòng | `GET /room-types`, `GET /rooms/search`, `GET /rooms/available`, `GET /services` |
| Chi tiết phòng | `GET /rooms/:id` |
| Đặt phòng | `POST /bookings` |
| Đơn của tôi | `GET /bookings` (backend tự lọc), `GET /bookings/:id`, `PATCH /bookings/:id/cancel` |
| **Hóa đơn của tôi** | `GET /invoices/my`, `GET /invoices/:id` (chỉ hóa đơn của mình) |
| Hồ sơ | `GET /auth/me`, `PATCH /users/me`, `POST /auth/change-password`, `POST /upload/avatar` |

**Phải ẩn hoàn toàn ở app khách:** tab Thống kê/Doanh thu, tab Nhân sự, toàn bộ chức năng quản lý phòng và hạng phòng, danh sách hóa đơn toàn khách sạn (`GET /invoices` — dùng `GET /invoices/my`).

Luồng xem hóa đơn của khách: `GET /bookings/:id` trả sẵn `invoiceId` và `paymentStatus` ở cấp ngoài → bấm vào mở `GET /invoices/:id`. Hoặc vào thẳng tab "Hóa đơn của tôi" bằng `GET /invoices/my`.

Ba màn đầu (`Trang chủ`, `Tìm phòng`, `Chi tiết phòng`) đều là API công khai → cho phép duyệt trước khi đăng nhập, chỉ chặn ở bước "Đặt phòng".

---

## 5. Bảng tra `403` thường gặp

| Role | Endpoint | Backend trả | FE xử lý đúng |
|---|---|---|---|
| `CASHIER` | `GET /analytics/occupancy-by-type` | `Yêu cầu vai trò [ADMIN, RECEPTIONIST]` | Ẩn biểu đồ lấp đầy theo hạng phòng ở app thu ngân |
| `CASHIER` | `PATCH /rooms/:id/status` | `[ADMIN, RECEPTIONIST]` | Thu ngân không đổi trạng thái phòng |
| `CASHIER` | `POST /bookings/:id/check-in` | `[ADMIN, RECEPTIONIST]` | Ẩn nút nhận phòng ở app thu ngân |
| `CASHIER` | `POST /bookings/:id/services` | `[ADMIN, RECEPTIONIST]` | Dịch vụ do lễ tân ghi, thu ngân chỉ đọc lại trong hóa đơn |
| `RECEPTIONIST` | `POST /invoices` | `[ADMIN, CASHIER]` | Ẩn nút "Tạo hóa đơn"; hóa đơn sinh tự động khi check-out |
| `RECEPTIONIST` | `GET /analytics/revenue` | `[ADMIN]` | Ẩn tab doanh thu năm, chỉ để `revenue/daily` |
| `RECEPTIONIST` | `PATCH /rooms/:id`, `DELETE /rooms/:id` | `[ADMIN]` | Sơ đồ phòng của lễ tân chỉ đổi trạng thái, không sửa thông tin phòng |
| `RECEPTIONIST` | `PATCH /users/:id` | `[ADMIN]` | Màn khách hàng để read-only |
| `CUSTOMER` | `GET /invoices/:id` của người khác | `Bạn chỉ có thể xem hóa đơn thuộc đơn đặt phòng của chính mình` | Điều hướng từ `GET /invoices/my`, không deep-link `id` tùy ý |
| `CUSTOMER` | `GET /bookings/:id`, `cancel` của người khác | `Bạn chỉ có thể xem và thao tác trên đơn đặt phòng của chính mình` | Điều hướng từ danh sách "Đơn của tôi" |
| `CUSTOMER` | `GET /invoices`, `POST /invoices`, `POST /invoices/:id/pay` | `[ADMIN, RECEPTIONIST, CASHIER]` | Khách chỉ dùng `GET /invoices/my` và `GET /invoices/:id` |
| `CUSTOMER` | mọi `/analytics/*` | `[ADMIN, RECEPTIONIST(, CASHIER)]` | Không có tab Thống kê |
| `CUSTOMER` | `GET /users`, `GET /users/:id` | `[ADMIN, RECEPTIONIST]` | Khách chỉ dùng `GET /auth/me` và `PATCH /users/me` |
| `CUSTOMER` | `POST /rooms`, `PATCH /rooms/:id/status` | `[ADMIN, RECEPTIONIST]` | App khách không có chức năng quản lý phòng |
| `CUSTOMER` | `POST /upload/room`, `/upload/rooms` | `[ADMIN, RECEPTIONIST]` | Khách chỉ upload avatar |
| Mọi role | bất kỳ endpoint có 🔓 | không bao giờ `403` | Gọi được cả khi chưa đăng nhập |

---

## 6. Những gì vừa siết lại ở backend

Bản rà soát đầu tiên phát hiện 7 chỗ phân quyền lệch. Tất cả đã được sửa trong cùng đợt với tài liệu này — ma trận ở Phần 3 phản ánh trạng thái **sau khi sửa**. Ghi lại ở đây để FE biết hành vi nào vừa đổi:

| # | Vị trí | Trước | Sau |
|---|---|---|---|
| 1 | `PATCH /rooms/:id/status` | **Không có guard nào** — người chưa đăng nhập cũng đổi được trạng thái phòng | `ADMIN` + `RECEPTIONIST` |
| 2 | `POST /rooms` | Mở cho cả `CUSTOMER` | `ADMIN` + `RECEPTIONIST` |
| 3 | `GET /bookings/:id` | Không kiểm tra chủ sở hữu — lộ tên, SĐT, email khách khác | Khách chỉ xem đơn của mình, sai chủ ⇒ `403` |
| 4 | `POST\|PATCH /bookings/:id/cancel` | Không kiểm tra chủ sở hữu — hủy phá được đơn người khác | Khách chỉ hủy đơn của mình, sai chủ ⇒ `403` |
| 5 | `GET /rooms` | Trả cả phòng `PENDING_APPROVAL` / `REJECTED` cho khách vãng lai | Lọc ở backend, chỉ nhân viên thấy phòng nội bộ |
| 6 | 4 endpoint `GET` của `/rooms` | `@Public()` không kèm `JwtAuthGuard` ⇒ `req.user` luôn rỗng ⇒ trường `notes` **không bao giờ trả về, kể cả cho ADMIN** | Xác thực tùy chọn: có token thì nhận diện được nhân viên |
| 7 | Khối `approve` trong `rooms.controller.ts` | `@UseGuards`/`@Roles` khai báo lặp 2 lần | Đã gỡ bản lặp |

**Chức năng mới bổ sung cho FE trong cùng đợt:**

| Thay đổi | Lý do |
|---|---|
| `GET /invoices/my` (mới) | Khách hàng trước đây **không có bất kỳ quyền nào** ở nhóm hóa đơn, không xem nổi hóa đơn của chính mình |
| `GET /invoices/:id` mở cho `CUSTOMER` (kèm kiểm tra chủ sở hữu) | Để bấm từ `invoiceId` trong đơn đặt phòng sang xem chi tiết hóa đơn |
| `GET /analytics/dashboard` mở cho `CASHIER` | Trước đây thu ngân bị `403`, phải ghép 2-3 lời gọi mới dựng nổi màn tổng quan |

### Còn tồn, chưa xử lý

- `POST /bookings/:id/cancel` và `PATCH /bookings/:id/cancel` là hai đường dẫn cho **cùng một hành vi** (alias cho client Flutter cũ). Nên bỏ bớt một khi FE thống nhất.
- `CASHIER` vẫn tạo được đơn đặt phòng qua `POST /bookings`. Nếu nghiệp vụ không cho phép thì cần siết thêm.

---

## 7. Đối chiếu nhanh khi backend đổi

Ma trận này sinh ra từ decorator trong controller. Cách kiểm tra doc còn khớp code:

```bash
grep -rn "@Roles\|@Public\|@UseGuards\|@Get(\|@Post(\|@Patch(\|@Delete(" src --include="*.controller.ts"
```

Hoặc mở Swagger `/api/docs`: endpoint nào có biểu tượng ổ khóa là cần token, phần `summary` ghi rõ role được phép.
