# Kịch bản ghép API thật (hotel-management-plsp.onrender.com/api/v1)

## Context

Đã đối chiếu toàn bộ Swagger (`/api/docs-json`) với code hiện tại. Ba vấn đề:

1. **5 endpoint app đang gọi không tồn tại trên server** → luôn 404 → 4 màn hình admin luôn rơi vào nhánh fallback và hiển thị **dữ liệu cứng bịa ra**. Người dùng tưởng đang xem số liệu thật.
2. **Mock fallback che lỗi**: 8 màn hình có danh sách phòng/booking/hóa đơn hardcode. Cộng thêm 6 chỗ *báo thành công dù API lỗi* (check-in, check-out, duyệt booking, hủy booking, tạo booking, thanh toán hóa đơn) → thao tác thất bại vẫn hiện dấu tích xanh.
3. **~18 endpoint có sẵn chưa dùng**: `/rooms/available`, `/services`, `/bookings/{id}/services`, `/invoices/{id}`, `/users` CRUD, `/room-types` CRUD, `/upload/*`, luồng quên mật khẩu.

Mục tiêu: mọi màn hình chạy trên API thật, lỗi hiện đúng là lỗi, và khai thác hết các endpoint đã có.

---

## Bảng đối chiếu API

### A. Endpoint app gọi nhưng **không tồn tại** → thay bằng cách suy ra ở client

| App đang gọi (404) | Thay bằng | Nơi sửa |
|---|---|---|
| `GET /bookings/pending` | `GET /bookings?status=PENDING` | `pending_bookings_screen.dart` |
| `GET /bookings/today/check-ins` | `GET /bookings?status=CONFIRMED` + lọc `checkInDate` = hôm nay (client) | `today_check_ins_screen.dart` |
| `GET /bookings/today/check-outs` | `GET /bookings?status=CHECKED_IN` + lọc `checkOutDate` <= hôm nay | `today_check_outs_screen.dart` |
| `PUT /bookings/{id}/reject` | `POST /bookings/{id}/cancel` (body `{cancellationReason}`) | `pending_bookings_screen.dart` |
| `PUT /bookings/{id}/approve` | **Không có endpoint tương đương** — xem mục ⚠️ bên dưới | `pending_bookings_screen.dart` |
| `GET /analytics/occupancy/detail` | `GET /analytics/occupancy-by-type` (phần `byRoomType`) + `GET /rooms` (summary & danh sách phòng) | `occupancy_detail_screen.dart` |

⚠️ **Không có API xác nhận booking.** Server chỉ có `check-in`, `check-out`, `cancel`; không có đường nào đưa `PENDING → CONFIRMED`. Xử lý: đổi màn "Chờ duyệt" thành **"Chờ xác nhận"** với 2 hành động thật — **"Nhận phòng ngay"** (`POST /bookings/{id}/check-in`) và **"Từ chối"** (`POST /bookings/{id}/cancel`). Ghi mục này vào `API_SPEC_DASHBOARD_DETAILS.md` như yêu cầu gửi backend (`PATCH /bookings/{id}/confirm`). Không giả lập trạng thái CONFIRMED ở client.

### B. Sai chi tiết cần sửa

| Vấn đề | Sửa |
|---|---|
| `POST /bookings` thiếu `depositAmount` (DTO có, optional) | thêm vào payload modal đặt phòng |
| `POST /bookings/{id}/check-out` gửi body rỗng | gửi `CheckOutDto {paymentMethod, discount, taxRate}` — server trả về cả `booking` **và** `invoice`, đang bị bỏ |
| `analytics/revenue/daily?days=` | Swagger nhận cả `range` và `days`, `range` là enum `1\|7\|14\|30` → dùng `range` |
| `POST /invoices` chưa bao giờ được gọi (sheet "tạo hóa đơn thủ công" chỉ chèn object local) | nối vào API thật |

### C. Endpoint có sẵn chưa dùng → ghép theo mục "Tính năng mới" (GĐ 3)

`/rooms/available`, `/rooms/{id}`, `/room-types` POST/PATCH/DELETE, `/services`, `/bookings/{id}/services`, `/bookings/{id}` (chi tiết), `/invoices/{id}`, `/users` GET/PATCH/DELETE, `/analytics/revenue` (năm), `/upload/avatar|room|rooms|image|images`, `DELETE /upload`, `/auth/forgot-password|verify-reset-otp|reset-password`.

---

## GĐ 0 — Nền tảng (làm trước, mọi giai đoạn sau phụ thuộc)

### 0.1 `lib/core/network/api_endpoints.dart`
- **Xóa**: `todayCheckIns`, `todayCheckOuts`, `pendingBookings`, `approveBooking`, `rejectBooking`, `analyticsOccupancyDetail`.
- **Thêm**: `uploadAvatar`, `uploadRoom`, `uploadRooms`, `uploadImage`, `uploadImages`, `uploadDelete` (`/upload/...`).
- Mỗi hằng số ghi doc comment `/// <METHOD> — role được phép (FE-ROLE-MATRIX §x.y)` như `invoicesMy` đang làm.

### 0.2 `lib/core/network/api_result.dart` (mới)
Helper bóc envelope NestJS `{success, message, data}` — hiện mỗi màn tự viết lại:
```dart
List<Map<String, dynamic>> unwrapList(Response res);   // ném ApiError nếu success != true
Map<String, dynamic> unwrapMap(Response res);
```
Ném `ApiError.fromDynamic` khi `success != true` để lỗi nghiệp vụ và lỗi mạng đi chung một đường.

### 0.3 Lớp repository theo domain — `lib/shared/repositories/`
Class thuần async (**không** `ChangeNotifier`), trả dữ liệu hoặc **ném `ApiError`**; nhận `DioClient? dioClient` để test inject. Đăng ký `registerLazySingleton` trong `lib/di/injection_container.dart`.

| File mới | Phương thức → endpoint |
|---|---|
| `booking_repository.dart` | `fetchBookings({status, customerId, roomId})`, `fetchTodayCheckIns()`, `fetchTodayCheckOuts()`, `fetchPending()`, `fetchDetail(id)`, `create(...)`, `checkIn(id)`, `checkOut(id, {paymentMethod, discount, taxRate})` → trả `(BookingModel, InvoiceModel)`, `cancel(id, reason)`, `addService(id, {serviceName, unitPrice, quantity})` |
| `invoice_repository.dart` | `fetchAll({status})`, `fetchMy({status})`, `fetchDetail(id)`, `fetchSummary({date})`, `create(...)`, `pay(id, {amount, paymentMethod, paymentStatus, notes})` |
| `analytics_repository.dart` | `dashboard()` → `DashboardStats` model, `revenueDaily({range})`, `revenueYearly({year})`, `occupancyByType()` |
| `user_repository.dart` | `fetchAll({role})`, `fetchDetail(id)`, `updateMe(...)`, `updateUser(id, ...)`, `deactivate(id)` |
| `service_repository.dart` | `fetchServices()` (public, cache trong bộ nhớ) |
| `upload_repository.dart` | `uploadAvatar(File)`, `uploadRoomImages(List<File>, {roomId, roomTypeId})`, `deleteUpload(path)` |

`RoomRepository` giữ nguyên `ChangeNotifier` (đang có consumer qua `addListener`), nhưng:
- Bỏ `return true` vô điều kiện ở `addRoom`/`approveRoom`/`rejectRoom`/`updateRoomStatus` → **ném `ApiError` và rollback trạng thái lạc quan**.
- Bỏ nhánh fallback `PATCH /rooms/{id}/status` khi approve/reject lỗi (endpoint approve/reject có thật, fallback chỉ che 403).
- Thêm `fetchAvailable({checkInDate, checkOutDate, guestCount, roomTypeId})`, `fetchDetail(id)`, `searchRooms({q, minPrice, maxPrice, amenities, sort, floor, status})`, và CRUD `room-types` cho admin.

### 0.4 Model
- `BookingModel`: thêm `copyWith` + `toJson`. Hiện các màn admin phải chép tay 20 field chỉ để đổi 1 `status`.
- `InvoiceModel`: **bỏ `_generateDefaultItems` / `_generateDefaultTransactions`** — dữ liệu thật với `items: []` đang bị thay bằng dòng bịa ("Thu ngân ca trực"). Danh sách rỗng thì hiển thị rỗng.
- Mới `lib/shared/models/dashboard_stats.dart`: parse `GET /analytics/dashboard` thành model có kiểu thay vì `Map` + chuỗi `??` dài trong `admin_dashboard_screen.dart`.
- Mới `lib/shared/models/service_model.dart`: `code, name, category, description, unitPrice, unit, icon, isAvailable`.
- Giữ nguyên phong cách `fromJson` viết tay (dự án không có build_runner).

---

## GĐ 1 — Sửa 4 màn hình đang 404

Mỗi màn: bỏ 3 tầng fallback (`endpoint riêng → /bookings → hardcode`) còn **một** lời gọi qua repository.

- [pending_bookings_screen.dart](../lib/features/admin/screens/pending_bookings_screen.dart) — `fetchPending()`; hành động "Nhận phòng ngay" / "Từ chối" (xem ⚠️ ở trên); đổi tiêu đề thành "Chờ xác nhận".
- [today_check_ins_screen.dart](../lib/features/admin/screens/today_check_ins_screen.dart) — `fetchTodayCheckIns()`; sau `checkIn(id)` thành công mới cập nhật UI, thất bại thì snackbar lỗi + giữ nguyên item.
- [today_check_outs_screen.dart](../lib/features/admin/screens/today_check_outs_screen.dart) — `fetchTodayCheckOuts()`; mở sheet nhập `paymentMethod / discount / taxRate` trước khi `checkOut`, rồi hiển thị hóa đơn server trả về.
- [occupancy_detail_screen.dart](../lib/features/admin/screens/occupancy_detail_screen.dart) — ghép `occupancyByType()` + `RoomRepository.fetchRooms()`; giữ `_buildTypeStatsFromRooms` làm bộ tính summary chính (không còn là fallback), xóa `_applyFallbackData`.

---

## GĐ 2 — Xóa mock & sửa lỗi "thành công giả"

**Chuẩn 3 trạng thái** cho mọi màn: skeleton → dữ liệu → `AppEmptyState` (rỗng) / `AppEmptyState` + nút "Tải lại" (lỗi). Mẫu chuẩn đã có sẵn: [my_invoices_screen.dart](../lib/features/customer/screens/my_invoices_screen.dart).

Xóa hàm mock cứng ở: `room_search_screen.dart` (4 phòng), `my_bookings_screen.dart` (`_getFallbackBookings`, 6 booking), `room_matrix_screen.dart` (16 phòng), `cashier_invoices_screen.dart` (4 hóa đơn) và 3 màn ở GĐ 1.

Sửa các chỗ báo thành công dù lỗi:
- `create_booking_modal.dart` — `catch` đang gọi `_handleSuccessTransition()`; đổi thành hiện lỗi.
- `my_bookings_screen.dart` — hủy booking thất bại vẫn snackbar xanh + xóa item local.
- `cashier_invoices_screen.dart` — thanh toán lỗi vẫn bịa transaction và cộng `_todayRevenue`; đồng thời nối sheet "tạo hóa đơn thủ công" vào `POST /invoices` thật (gate bằng `canCreateInvoice` — lễ tân bị 403).
- `profile_screen.dart` — `PATCH /users/me` đang nuốt lỗi âm thầm.

**Quy tắc lỗi** theo `FE-ROLE-MATRIX.md` §2: 401 → interceptor tự refresh 1 lần (đã có); **403 → không retry, không fallback**, hiện thông báo "Bạn không có quyền" — 403 nghĩa là UI đang lộ nút không nên hiện, cần bọc lại bằng getter trong `role_permissions.dart`.

Cải thiện `dio_client.dart` kèm theo: thêm mutex cho refresh (N request 401 đồng thời hiện đang gọi refresh N lần) và cờ chặn retry lặp; dùng `ApiEndpoints.refreshToken` thay chuỗi hardcode.

---

## GĐ 3 — Tính năng mới từ endpoint có sẵn

### 3.1 Đặt phòng theo ngày trống — `GET /rooms/available`
`checkInDate` + `checkOutDate` bắt buộc (ISO date-time), `guestCount` / `roomTypeId` tùy chọn.
- `create_booking_modal.dart`: chọn ngày trước → gọi `fetchAvailable` → chỉ hiện phòng thật sự trống; chặn nút xác nhận khi phòng đang chọn không nằm trong danh sách trả về.
- `room_search_screen.dart`: thêm bộ lọc ngày; có ngày thì dùng `/rooms/available`, không thì `/rooms/search` (map đủ `minPrice/maxPrice/amenities/sort/floor/status` — hiện chỉ gửi `q`).

### 3.2 Dịch vụ phòng — `GET /services`, `POST /bookings/{id}/services`
- Màn/sheet mới `lib/features/receptionist/widgets/add_service_sheet.dart`: danh mục từ `/services` (lọc `isAvailable`), chọn số lượng → `POST /bookings/{id}/services` với `{serviceName, unitPrice, quantity}`.
- Điểm vào: chi tiết booking `CHECKED_IN` ở room matrix & today-check-outs. Gate bằng `canAddBookingServices` (admin + lễ tân).
- Tiền dịch vụ chảy vào `servicesAmount` của hóa đơn khi check-out.

### 3.3 Upload ảnh — `/upload/avatar`, `/upload/rooms`
- Thêm `image_picker` vào `pubspec.yaml`; quyền camera/photo cho Android + iOS.
- `profile_screen.dart`: bấm avatar → chọn ảnh → `POST /upload/avatar?updateProfile=true` → server trả user đã cập nhật → `TokenStorage.saveUser` + emit lại `AuthAuthenticated`.
- `create_room_modal.dart`: chọn nhiều ảnh → tạo phòng trước, lấy `roomId` → `POST /upload/rooms?roomId=...` (tối đa 10 ảnh, 5MB/ảnh — validate ở client trước khi gửi). Gate `canUploadRoomImages`.

### 3.4 Quản trị: người dùng, loại phòng, quên mật khẩu
- **Người dùng** — màn mới `lib/features/admin/screens/user_management_screen.dart`: `GET /users?role=`, `GET /users/{id}`, `PATCH /users/{id}` (đổi role/khóa), `DELETE /users/{id}` (soft-delete `isActive=false`). Thêm tab vào shell admin trong `app_router.dart` + entry `_sharedRouteAccess`. Gate `canManageUsers`.
- **Loại phòng** — màn mới `lib/features/admin/screens/room_type_management_screen.dart`: CRUD `/room-types` (`name, code, description, basePrice, capacityAdults, capacityChildren, sizeSqM, amenities, images`). Gate `canManageRoomTypes`.
- **Quên mật khẩu** — màn mới `lib/features/auth/screens/forgot_password_screen.dart`, 3 bước: `POST /auth/forgot-password` → `POST /auth/verify-reset-otp` (nhận `resetToken`) → `POST /auth/reset-password`. Route `/forgot-password` thêm vào `_publicRoutes`; link từ `login_screen.dart`.
- **Doanh thu năm** — `GET /analytics/revenue?year=` cho biểu đồ theo tháng trong `admin_dashboard_screen.dart` (fl_chart đã có). Gate `canViewYearlyRevenue` (chỉ admin).

---

## Thứ tự thực thi

GĐ 0 → GĐ 1 → GĐ 2 → GĐ 3 (3.1 → 3.2 → 3.3 → 3.4). Mỗi màn hình một commit kèm test, theo quy tắc §2 của `UI-REVAMP-PLAN.md`.

---

## Kiểm chứng

1. `flutter analyze` — 0 issue (chuẩn hiện tại của dự án).
2. `flutter test` — 16 file test hiện có phải xanh; thêm test repository dùng seam `DioClient?` (fake Dio) cho `BookingRepository.fetchTodayCheckIns` (lọc theo ngày), `checkOut` (parse cả booking lẫn invoice), và `RoomRepository.approveRoom` (ném lỗi + rollback thay vì `return true`).
3. **Kiểm tra thật với 4 tài khoản seed** (`FE-ROLE-MATRIX.md` §1) — `admin@hotel.com/Admin@123`, `reception@hotel.com/Staff@123`, `cashier@hotel.com/Staff@123`, `customer@hotel.com/Cust@123`:
   - Admin: dashboard có số liệu thật, occupancy detail có dữ liệu, quản lý user + loại phòng chạy.
   - Lễ tân: room matrix đổi trạng thái, thêm dịch vụ, check-in; `POST /invoices` phải hiện "không có quyền" (403) chứ không phải crash hay thành công giả.
   - Thu ngân: danh sách hóa đơn + thanh toán + check-out sinh hóa đơn.
   - Khách: tìm phòng theo ngày, đặt phòng, xem `/invoices/my`, đổi avatar, quên mật khẩu.
4. **Test đường lỗi**: bật máy bay giữa chừng → mọi màn phải hiện `AppEmptyState` + "Tải lại", **không** hiện dữ liệu mẫu và **không** hiện dấu tích thành công.
5. Chụp màn hình light + dark cho các màn mới (§9 `UI-REVAMP-PLAN.md`).
