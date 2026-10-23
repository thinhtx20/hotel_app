# Hướng dẫn trình bày và trả lời câu hỏi theo từng thành viên

Đề bài yêu cầu: *“chức năng của ai phụ trách sẽ do bạn đó trình bày, mỗi người tối thiểu 2 chức năng”*. Tài liệu này chia theo bảng phân công trong báo cáo KT&TKPM. Mỗi phần gồm:

1. Chức năng phụ trách và API
2. File code cần mở khi trình bày
3. Luồng xử lý – nói theo đúng thứ tự **Route → Controller → Service → Prisma → Database**
4. Kịch bản demo (mã ca kiểm thử trong Postman Collection)
5. Câu hỏi giáo viên hay hỏi và câu trả lời gợi ý
6. Điểm yếu nên chủ động nói trước (xem chi tiết trong `docs/DANH_SACH_LOI_CAN_SUA.md`)

> Đổi `[Họ tên SV x]` thành tên thật cho khớp bảng phân công trong báo cáo. Tất cả đường dẫn code tính từ thư mục backend `Hotel-Management/`.

---

## Phần chung – ai cũng phải trả lời được

**Hỏi: Hệ thống dùng kiến trúc gì? Vì sao không dùng Laravel?**
Đề bài cho phép “Laravel hoặc framework khác”. Nhóm dùng NestJS (Node.js/TypeScript) vì NestJS bắt buộc chia code theo Module – Controller – Service – DTO, có sẵn Dependency Injection, Guard, Pipe, Interceptor – tương đương Middleware, Request, Service Container của Laravel. Kiến trúc là **client – server 3 tầng**, phía máy chủ chia **phân tầng (Layered)** theo module.

**Hỏi: Luồng xử lý một request đi qua những đâu?**
Client gửi `POST /api/v1/bookings` → `JwtAuthGuard` kiểm tra token → `RolesGuard` kiểm tra vai trò → `ValidationPipe` kiểm tra body theo DTO → `BookingsController.create()` → `BookingsService.create()` (nghiệp vụ) → `PrismaService` (truy vấn PostgreSQL) → kết quả trả ngược về Controller → `TransformInterceptor` bọc thành `{ statusCode, success, message, data, timestamp }` → Client. Nếu có lỗi ở bất kỳ bước nào, `AllExceptionsFilter` trả JSON lỗi cùng cấu trúc.

**Hỏi: Tầng Repository ở đâu?**
Nhóm dùng `PrismaService` (kế thừa `PrismaClient`) được inject vào Service. Prisma Client đóng vai trò lớp truy cập dữ liệu có kiểu (`prisma.booking.findMany`, `prisma.room.update`…), Controller không bao giờ chạm vào CSDL. Nhóm **chưa tách lớp `*Repository` riêng** – đây là hạn chế đã nêu trong báo cáo; hướng sửa là tạo interface `BookingRepository` để Service không phụ thuộc trực tiếp Prisma và dễ viết unit test.

**Hỏi: Vì sao không xử lý nghiệp vụ trong Controller?**
Controller chỉ nhận dữ liệu đã kiểm tra và gọi đúng một hàm Service. Nghiệp vụ nằm ở Service để tái sử dụng (ví dụ `buildSettlement()` dùng chung cho xem trước và check-out), dễ test và không phụ thuộc HTTP.

**Hỏi: RESTful thể hiện ở đâu?**
Tài nguyên là danh từ số nhiều (`/rooms`, `/bookings`), đúng method (GET đọc, POST tạo, PUT thay toàn bộ, PATCH sửa một phần, DELETE xóa), trả JSON, mã HTTP đúng ngữ nghĩa (200, 201, 400, 401, 403, 404, 409), có version `/api/v1`. Hành động chuyển trạng thái đặt là tài nguyên con: `POST /bookings/{id}/check-in`.

**Hỏi: Validate dữ liệu ở đâu?**
Ở DTO bằng decorator `class-validator` (`@IsEmail`, `@MinLength(6)`, `@IsPositive`…). `ValidationPipe` toàn cục trong `src/main.ts` bật `whitelist` và `forbidNonWhitelisted` nên trường lạ bị từ chối 400.

**Hỏi: Phân trang làm thế nào?**
`src/common/utils/pagination.util.ts`: nhận `page`, `limit` (tối đa 100), tính `skip = (page - 1) * limit`, `take = limit`, trả về `{ data, meta: { total, page, limit, totalPages } }`. Mọi API danh sách dùng chung hàm này.

**Hỏi: Tài liệu API ở đâu?**
Swagger tại `http://localhost:3000/api/docs` (khai báo trong `src/main.ts`), bấm Authorize dán JWT để gọi thử. Ngoài ra có Postman Collection `docs/bai_tap_lon_ktpm/Luxe_Grand_Hotel_API.postman_collection.json` (39 ca, kết quả thật 38/39 đạt).

---

## [Họ tên SV 1] – Xác thực, người dùng, phân quyền

### Chức năng phụ trách
1. Đăng ký, đăng nhập, làm mới token, đăng xuất, quên mật khẩu (OTP)
2. Quản lý người dùng và phân quyền (ADMIN, RECEPTIONIST, CUSTOMER)
3. Quản lý thông tin cá nhân, đổi mật khẩu

### API
| Method | Endpoint | Quyền |
| :-- | :-- | :-- |
| POST | `/auth/register`, `/auth/login`, `/auth/refresh-token` | Public |
| POST | `/auth/forgot-password`, `/auth/verify-reset-otp`, `/auth/reset-password` | Public |
| GET | `/auth/me` | Đăng nhập |
| POST | `/auth/change-password`, `/auth/logout` | Đăng nhập |
| PATCH | `/users/me` | Đăng nhập |
| GET, POST | `/users` | GET: A, R – POST: A |
| GET, PATCH, DELETE | `/users/{id}` | GET: A, R – PATCH, DELETE: A |
| PATCH | `/users/{id}/password` | A |

### File cần mở
- `src/auth/auth.controller.ts`, `src/auth/auth.service.ts`, `src/auth/jwt.strategy.ts`, `src/auth/session-policy.ts`, `src/auth/dto/*.ts`
- `src/common/guards/jwt-auth.guard.ts`, `src/common/guards/roles.guard.ts`, `src/common/decorators/roles.decorator.ts`, `public.decorator.ts`
- `src/users/users.controller.ts`, `src/users/users.service.ts`

### Luồng xử lý cần nói
- **Đăng ký:** `RegisterDto` kiểm tra email, mật khẩu ≥ 6 ký tự, họ tên → Service kiểm tra email trùng (409) → băm mật khẩu `bcrypt` salt 10 → tạo user với **role luôn là CUSTOMER** (bỏ qua `role` client gửi) → cấp token.
- **Đăng nhập:** tìm user theo email → kiểm tra `isActive` (khóa → 401) → `bcrypt.compare` → sinh `sessionId` lưu vào `users.activeSessionId` → ký **access token** (chứa `sub`, `email`, `role`, `sid`, hạn 1 ngày) và **refresh token** (7 ngày, lưu Redis key `auth:refresh:{userId}:{jti}`).
- **Mỗi request sau đó:** `JwtAuthGuard` → `JwtStrategy.validate()`: kiểm tra chữ ký, hạn, blacklist, tài khoản còn hoạt động, với khách hàng thì `sid` phải khớp `activeSessionId` (một thiết bị) → `RolesGuard` so vai trò với `@Roles(...)`.
- **Làm mới token:** kiểm tra refresh token còn trong Redis → xóa token cũ → cấp cặp mới (*token rotation*), nên refresh token cũ không dùng lại được.
- **Quên mật khẩu:** gửi OTP qua email (Nodemailer) hiệu lực 15 phút → xác thực OTP nhận `resetToken` → đặt mật khẩu mới.
- **Quản lý người dùng:** danh sách tìm theo họ tên, email, số điện thoại (không phân biệt hoa thường), lọc vai trò, phân trang; **xóa là xóa mềm** (`isActive = false`) để giữ lịch sử đơn và hóa đơn; thay đổi được đẩy realtime qua SSE `/users/stream`.

### Kịch bản demo (Postman)
TC01 đăng ký (gửi `role: ADMIN` nhưng nhận CUSTOMER) → TC02 trùng email 409 → TC03 sai dữ liệu 400 → TC04 đăng nhập admin → TC06 sai mật khẩu 401 → TC07 không token 401 → TC08 token giả 401 → TC10 refresh token → TC11 sửa hồ sơ → TC12 khách gọi `/users` bị 403 → TC15 admin tìm kiếm + phân trang → TC38 admin vô hiệu hóa tài khoản → TC39 tài khoản bị khóa không đăng nhập được.

### Câu hỏi và trả lời gợi ý
**Hỏi: JWT là gì, khác session thế nào?**
JWT là chuỗi `header.payload.signature` ký bằng secret của máy chủ. Máy chủ không cần lưu phiên, chỉ cần kiểm tra chữ ký → phù hợp REST phi trạng thái và nhiều instance. Nhược điểm là token đã cấp khó thu hồi, nên nhóm thêm blacklist khi đăng xuất và refresh token lưu Redis.

**Hỏi: Vì sao có cả access token và refresh token?**
Access token hạn ngắn để giảm rủi ro khi lộ; refresh token hạn dài dùng để xin access token mới mà không bắt đăng nhập lại. Mỗi lần refresh thì refresh token cũ bị hủy.

**Hỏi: Làm sao biết người dùng có quyền gọi API?**
Decorator `@Roles(Role.ADMIN)` gắn metadata lên route; `RolesGuard` dùng `Reflector` đọc metadata, so với `user.role` lấy từ token; không khớp thì ném `ForbiddenException` → 403. Route `@Public()` thì `JwtAuthGuard` cho qua không cần token.

**Hỏi: 401 và 403 khác nhau thế nào?**
401: chưa xác thực (thiếu token, token sai/hết hạn). 403: đã xác thực nhưng không đủ quyền.

**Hỏi: Mật khẩu lưu thế nào? Có giải mã được không?**
Băm một chiều bằng bcrypt có salt, không giải mã được. Khi đăng nhập dùng `bcrypt.compare`. API không bao giờ trả trường `password` (TC09).

**Hỏi: Người dùng tự gửi `role: ADMIN` khi đăng ký thì sao?**
Server bỏ qua, luôn gán CUSTOMER (TC01). Chỉ ADMIN mới tạo hoặc đổi vai trò qua `POST /users`, `PATCH /users/{id}`.

**Hỏi: Một tài khoản đăng nhập 2 máy thì sao?**
Với khách hàng: đăng nhập máy mới thì máy cũ nhận 401 `SESSION_REVOKED` vì `sid` không còn khớp. Nhân viên được đăng nhập nhiều máy vì quầy có nhiều máy trực.

### Điểm yếu nên chủ động nói
- Lỗi BUG-01: token cũ vẫn dùng được sau đăng xuất khi máy chủ không có Redis (TC37 không đạt) – đã phân tích nguyên nhân và cách sửa.
- OTP đang cố định `123456` và còn tài khoản mặc định chấp nhận mật khẩu `123456` – phục vụ demo, khi triển khai thật phải tắt.

---

## [Họ tên SV 2] – Loại phòng, phòng, tìm kiếm

### Chức năng phụ trách
1. Quản lý loại phòng (CRUD)
2. Quản lý phòng và trạng thái phòng (duyệt phòng, cập nhật trạng thái, sơ đồ phòng realtime)
3. Tìm phòng trống theo ngày và tìm kiếm toàn văn

### API
| Method | Endpoint | Quyền |
| :-- | :-- | :-- |
| GET | `/room-types`, `/room-types/{id}` | Public |
| POST, PATCH, DELETE | `/room-types`, `/room-types/{id}` | A |
| GET | `/rooms`, `/rooms/{id}`, `/rooms/available`, `/rooms/search`, `/rooms/stream` (SSE) | Public |
| POST | `/rooms` | A, R, C |
| PATCH | `/rooms/{id}/approve`, `/rooms/{id}/reject`, `/rooms/{id}/status` | A, R |
| POST | `/rooms/sync-status` | A, R |
| PUT, PATCH, DELETE | `/rooms/{id}` | A |

### File cần mở
- `src/room-types/room-types.controller.ts`, `room-types.service.ts`, `dto/create-room-type.dto.ts`
- `src/rooms/rooms.controller.ts`, `rooms.service.ts`, `room-events.service.ts`, `dto/query-rooms.dto.ts`, `dto/query-available-rooms.dto.ts`
- `src/common/utils/room-status.util.ts` (hàm `deriveRoomStatus`)
- `src/elasticsearch/elasticsearch.service.ts`, `src/redis/redis.service.ts`

### Luồng xử lý cần nói
- **CRUD loại phòng:** tên và mã là duy nhất; giá ≥ 0; tiện nghi và ảnh là mảng. Xem danh sách là Public để khách vãng lai xem được.
- **Tạo phòng:** số phòng duy nhất (trùng → 409). Admin tạo thì phòng hoạt động ngay; lễ tân tạo thì phòng ở `PENDING_APPROVAL` chờ duyệt (`/approve` hoặc `/reject`).
- **Danh sách phòng:** lọc theo `status`, `floor`, `roomTypeId`, phân trang; `status` sai giá trị enum → 400 (TC18).
- **Tìm phòng trống:** nhận `checkInDate`, `checkOutDate`, `guestCount`, `roomTypeId` → loại các phòng có đơn `PENDING`, `CONFIRMED`, `CHECKED_IN` giao với khoảng ngày (điều kiện `checkIn < C_out` và `checkOut > C_in`) → kết quả được **cache Redis 60 giây** theo khóa `cache:rooms:available:{ngày}:{ngày}:{số khách}:{loại}`. Khi có đặt/hủy/check-in, cache `cache:rooms:*` bị xóa để không trả dữ liệu cũ.
- **Tìm kiếm toàn văn:** gọi Elasticsearch (so khớp gần đúng tên, tiện nghi, khoảng giá); nếu Elasticsearch chưa chạy hoặc không có kết quả thì **tự chuyển sang tìm trong PostgreSQL** bằng `contains` không phân biệt hoa thường.
- **Trạng thái phòng:** 7 giá trị `AVAILABLE`, `RESERVED`, `OCCUPIED`, `CLEANING`, `MAINTENANCE`, `PENDING_APPROVAL`, `REJECTED`. `deriveRoomStatus()` là nguồn sự thật: có khách `CHECKED_IN` → `OCCUPIED`; các trạng thái thủ công (dọn dẹp, bảo trì) được giữ nguyên; có đơn `CONFIRMED` nhận phòng hôm nay → `RESERVED`; còn lại `AVAILABLE`.
- **Realtime:** mỗi khi đổi trạng thái, `RoomEventsService` (RxJS Subject) phát sự kiện, endpoint SSE `/rooms/stream` đẩy tới mọi máy lễ tân → sơ đồ phòng đổi màu ngay không cần tải lại.

### Kịch bản demo (Postman)
TC16 xem loại phòng không cần token → TC17 danh sách phòng có lọc + phân trang (chỉ `meta`) → TC18 lọc sai trạng thái 400 → TC19 tìm phòng trống theo ngày → TC14 khách tạo loại phòng bị 403. Mở thêm Swagger gọi `PATCH /rooms/{id}/status` đổi phòng sang `CLEANING` rồi `AVAILABLE`, đồng thời mở app ở màn sơ đồ phòng để thấy đổi màu realtime.

### Câu hỏi và trả lời gợi ý
**Hỏi: Xóa loại phòng đang có phòng sử dụng thì sao?**
Bảng `rooms` có khóa ngoại `roomTypeId` (RESTRICT). Prisma báo lỗi `P2003`, `AllExceptionsFilter` chuyển thành 400 “Dữ liệu liên quan không hợp lệ hoặc đang được sử dụng ở bảng khác”, nên không mất dữ liệu.

**Hỏi: Tại sao dùng PUT và PATCH cho phòng?**
`PUT /rooms/{id}` thay toàn bộ thông tin phòng; `PATCH /rooms/{id}` chỉ sửa trường gửi lên; `PATCH /rooms/{id}/status` là thao tác nhanh của lễ tân chỉ đổi trạng thái.

**Hỏi: Cache có làm dữ liệu sai không?**
Cache chỉ sống 60 giây và bị xóa ngay khi có thao tác đặt, hủy, check-in, check-out. Khi không có Redis, `RedisService` tự dùng bộ nhớ trong tiến trình.

**Hỏi: SSE khác WebSocket thế nào? Vì sao chọn SSE?**
SSE là kết nối HTTP một chiều máy chủ → client, đủ cho nhu cầu “máy chủ báo phòng đổi trạng thái”, tự kết nối lại, không cần giao thức riêng. WebSocket hai chiều, phức tạp hơn mức cần thiết.

**Hỏi: Đặt trạng thái `AVAILABLE` cho phòng đang có khách được không?**
Không. `updateStatus()` kiểm tra nếu phòng còn đơn `CHECKED_IN` mà đổi sang trạng thái khác `OCCUPIED` thì trả 400.

**Hỏi: Index CSDL dùng để làm gì?**
`rooms` có index trên `status`, `floor`, `roomTypeId` – đúng các cột mà màn sơ đồ phòng lọc, giúp truy vấn không phải quét toàn bảng.

### Điểm yếu nên chủ động nói
- Đo trên gói miễn phí Render: API danh sách phòng và tìm phòng trống trung bình khoảng 1 giây (gồm độ trễ mạng, không có Redis thật); API loại phòng khoảng 0,35 giây.

---

## [Họ tên SV 3] – Đặt phòng, lưu trú, dịch vụ

### Chức năng phụ trách
1. Đặt phòng, duyệt / từ chối / hủy đơn
2. Check-in, đổi phòng, dịch vụ phát sinh, check-out (quyết toán)
3. Danh mục dịch vụ khách sạn (CRUD)

### API
| Method | Endpoint | Quyền |
| :-- | :-- | :-- |
| POST, GET | `/bookings` | Đăng nhập |
| GET | `/bookings/{id}` | Đăng nhập |
| PATCH | `/bookings/{id}/approve`, `/bookings/{id}/reject` | A, R |
| PATCH | `/bookings/{id}/cancel` | Đăng nhập |
| POST | `/bookings/{id}/check-in`, `/bookings/{id}/change-room`, `/bookings/{id}/check-out` | A, R |
| GET | `/bookings/{id}/checkout-preview` | A, R |
| POST | `/bookings/{id}/services` (lễ tân ghi) / `/bookings/{id}/service-requests` (khách gọi) | A, R / C |
| PATCH | `/bookings/{id}/services/{orderId}` | A, R |
| GET | `/services`, `/services/{id}` | Public |
| POST, PATCH, DELETE | `/services`, `/services/{id}` | A |

### File cần mở
- `src/bookings/bookings.controller.ts`, `bookings.service.ts` (hàm `create`, `approve`, `cancel`, `checkIn`, `changeRoom`, `buildSettlement`, `checkOut`), `dto/create-booking.dto.ts`
- `src/redis/redis.service.ts` (`acquireLock`, `releaseLock`)
- `src/services/services.controller.ts`, `services.service.ts`, `dto/create-hotel-service.dto.ts`

### Luồng xử lý cần nói
- **Đặt phòng (quan trọng nhất):**
  1. Kiểm tra ngày nhận < ngày trả (sai → 400).
  2. Chuẩn hóa giờ nhận 14:00, giờ trả 12:00 để khách trả sáng và khách nhận chiều cùng ngày không bị coi là trùng.
  3. Giữ **khóa phân tán Redis** `lock:booking:room:{roomId}` (lệnh `SET NX PX 6000`) – không giữ được → 409.
  4. Kiểm tra phòng tồn tại, không bảo trì.
  5. Tìm đơn còn hiệu lực (`PENDING`, `CONFIRMED`, `CHECKED_IN`) giao lịch → có thì 409.
  6. Tính `số đêm × giá loại phòng`, tạo đơn: khách đặt → `PENDING`; lễ tân đặt hộ → `CONFIRMED`.
  7. Đồng bộ trạng thái phòng, xóa cache, **luôn nhả khóa** trong `finally` (Lua script chỉ xóa khóa đúng token của mình).
- **Duyệt đơn:** `PENDING → CONFIRMED`, ghi người duyệt; có thể xếp sang phòng khác (`assignedRoomId`, vẫn kiểm tra trùng lịch); nếu có tiền cọc thì trong **một transaction** tạo hóa đơn và dòng thu loại `DEPOSIT`.
- **Hủy đơn:** khách chỉ tự hủy đơn `PENDING` (đơn đã xác nhận → 403); lễ tân hủy được cả đơn `CONFIRMED`; đơn đã check-in/check-out không hủy được. Lưu lý do, người hủy, thời điểm.
- **Check-in:** chỉ đơn `CONFIRMED` (đơn `PENDING` → 400). Transaction: đơn → `CHECKED_IN` + ghi `actualCheckIn`, phòng → `OCCUPIED`; phát sự kiện SSE.
- **Đổi phòng:** chỉ đơn đang ở; phòng mới không bảo trì, không đang dọn, không chờ duyệt, không trùng lịch. Phòng cũ → `CLEANING`, phòng mới → `OCCUPIED`.
- **Check-out:** `buildSettlement()` (dùng chung với `checkout-preview`) tính số đêm thực tế, phát hiện trả phòng sớm, cộng dịch vụ đã xác nhận, trừ số đã thu → số còn phải thu. Thu chưa đủ → 400. Một transaction: đơn → `CHECKED_OUT`, phòng → `CLEANING`, tạo/cập nhật hóa đơn, ghi dòng thu (gắn ca trực), ghi dòng hoàn tiền nếu trả sớm, tính lại `paidAmount`.
- **Danh mục dịch vụ:** mã duy nhất, đơn giá > 0 (`@IsPositive`), nhóm, đơn vị, trạng thái khả dụng. Đơn dịch vụ lưu **bản sao tên và đơn giá tại thời điểm gọi**, nên sửa giá sau đó không làm sai hóa đơn cũ.

### Kịch bản demo (Postman)
TC20 thêm dịch vụ → TC21 đơn giá âm 400 → TC22 sửa → TC23 xóa → TC24 xem lại 404 → TC25 đặt phòng sai ngày 400 → TC26 đặt phòng hợp lệ (PENDING, 2 đêm × 450.000 = 900.000) → TC27 đặt trùng 409 → TC28 check-in đơn chưa duyệt 400 → TC29 lễ tân duyệt → TC30 khách chỉ thấy đơn của mình → TC31 khách tự hủy đơn đã xác nhận 403 → TC32 lễ tân hủy có lý do → TC33 đơn không tồn tại 404.
Check-in / check-out nên demo trên app hoặc Swagger (bộ kiểm thử tự động không chạy check-out để không ghi tiền vào sổ quỹ).

### Câu hỏi và trả lời gợi ý
**Hỏi: Hai người bấm đặt cùng một phòng cùng lúc thì sao?**
Chỉ yêu cầu giữ được khóa Redis mới được xử lý; yêu cầu còn lại nhận 409. Nhóm đã kiểm thử thật: gửi đồng thời 10 yêu cầu đặt phòng 101 → 1 yêu cầu được tạo (201), 9 yêu cầu bị từ chối (409), CSDL chỉ có 1 đơn.

**Hỏi: Chỉ kiểm tra trùng lịch trong CSDL chưa đủ sao?**
Chưa đủ: hai request có thể cùng đọc “chưa có đơn” rồi cùng tạo đơn (race condition). Khóa phân tán biến đoạn “kiểm tra rồi tạo” thành vùng chỉ một request được chạy tại một thời điểm.

**Hỏi: Transaction dùng để làm gì?**
Check-in phải đổi cả đơn và phòng; check-out đổi đơn, phòng, hóa đơn và sổ thu tiền. `prisma.$transaction` bảo đảm hoặc tất cả thành công, hoặc không có gì thay đổi – không xảy ra trường hợp đơn đã trả phòng mà phòng vẫn “đang ở”.

**Hỏi: Sao check-in lại là `POST /bookings/{id}/check-in` mà không phải `PATCH /bookings/{id}`?**
Check-in là một hành động nghiệp vụ có nhiều tác động (đổi trạng thái đơn, phòng, phát sự kiện), không đơn thuần sửa một trường. Mô hình hóa thành tài nguyên con giúp API rõ nghĩa và phân quyền riêng được.

**Hỏi: Tại sao `GET /bookings` của khách không xem được đơn người khác?**
Trong Controller, nếu vai trò là CUSTOMER thì `customerId` bị ép bằng id người đang đăng nhập, bất kể client gửi gì (TC30).

**Hỏi: Khách trả phòng sớm tính tiền thế nào?**
`buildSettlement()` so số đêm thực tế với số đêm đã đặt; tiền phòng tính theo số đêm thực tế (tối thiểu 1 đêm), phần đã trả thừa được ghi thành dòng `REFUND`, đơn ghi chú “trả phòng trước hạn”.

### Điểm yếu nên chủ động nói
- `bookings.service.ts` dài khoảng 1.400 dòng, nên tách nhỏ (ví dụ `CheckoutService`, `BookingApprovalService`).
- Một số hành động có cả POST và PATCH (approve, confirm, reject, cancel) để tương thích ứng dụng cũ – chưa thuần REST.

---

## [Họ tên SV 4] – Hóa đơn, thanh toán, ca trực, thống kê

### Chức năng phụ trách
1. Hóa đơn, thu tiền, yêu cầu thanh toán, hoàn tiền
2. Mở ca / chốt ca trực có đối chiếu tiền mặt
3. Thống kê: dashboard, doanh thu, công suất phòng, hiệu suất nhân viên

### API
| Method | Endpoint | Quyền |
| :-- | :-- | :-- |
| GET | `/invoices`, `/invoices/summary`, `/invoices/payment-requests` | A, R |
| GET | `/invoices/my` | Đăng nhập |
| GET | `/invoices/{id}` | A, R, C (khách chỉ xem của mình) |
| POST | `/invoices`, `/invoices/{id}/pay`, `/invoices/{id}/refund` | A, R |
| POST | `/invoices/{id}/payment-requests` | A, R, C |
| POST | `/invoices/payments/{id}/confirm`, `/invoices/payments/{id}/reject` | A, R |
| POST | `/shifts/open`, `/shifts/close` – GET `/shifts/current`, `/shifts/active`, `/shifts`, `/shifts/{id}` | A, R |
| POST | `/shifts/{id}/close` | A |
| GET | `/analytics/dashboard`, `/analytics/revenue/daily`, `/analytics/occupancy-by-type` | A, R |
| GET | `/analytics/revenue`, `/analytics/revenue/years`, `/analytics/revenue/export`, `/analytics/staff-performance` | A |

### File cần mở
- `src/invoices/invoices.controller.ts`, `invoices.service.ts` (`recalculateInvoiceTotals`, `recordPayment`, `createPaymentRequest`, `confirmPayment`, `rejectPayment`, `refund`)
- `src/shifts/shifts.service.ts` (`openShift`, `calculateShiftStats`, `closeShift`)
- `src/analytics/analytics.service.ts`, `src/common/utils/revenue.util.ts`
- `prisma/schema.prisma` – model `Invoice`, `Payment`, `WorkShift`

### Luồng xử lý cần nói
- **Sổ thu tiền (ý tưởng thiết kế chính):** mỗi hóa đơn có nhiều dòng `Payment` loại `PAYMENT`, `DEPOSIT`, `REFUND`. `paidAmount` **không cộng trừ tay** mà luôn tính lại bằng `recalculateInvoiceTotals()`: tổng các dòng `CONFIRMED` (thu cộng, hoàn trừ). Trạng thái: chưa thu → `UNPAID`; thu một phần → `PARTIAL`; đủ → `PAID`; thu rồi hoàn hết → `REFUNDED`. Nhờ vậy số “còn phải thu” luôn khớp tiền thực vào két – giải quyết đúng vấn đề “doanh thu bị lệch” khảo sát được.
- **Thu tiền tại quầy:** số tiền > 0, hóa đơn chưa thu đủ, không thu vượt số còn lại; dòng thu được gắn `shiftId` của ca đang mở.
- **Khách thanh toán chuyển khoản:** khách gửi yêu cầu kèm mã giao dịch → dòng `PENDING` (chưa tính tiền) → lễ tân đối chiếu sao kê → xác nhận (`CONFIRMED`, tính lại hóa đơn, gắn ca) hoặc từ chối kèm lý do (`REJECTED`, không bao giờ tính tiền).
- **Hoàn tiền:** chỉ hoàn khi hóa đơn đã có tiền thu, không hoàn vượt số đã thu; ghi dòng `REFUND`.
- **Mở ca:** chỉ lễ tân/admin; mỗi người tối đa một ca `OPEN`; khai báo loại ca, quầy, tiền mặt đầu ca.
- **Chốt ca:** `calculateShiftStats()` tính `expectedCash = tiền đầu ca + tiền mặt thu − tiền mặt hoàn` và doanh thu thẻ, chuyển khoản; so với `actualCash` nhân viên đếm. **Lệch tiền mà không nhập lý do → 400.** Transaction: gắn các khoản thu trong ca chưa có `shiftId`, chuyển ca sang `CLOSED` và lưu ảnh chụp số liệu.
- **Thống kê:** quy tắc doanh thu dùng chung (`revenue.util.ts`): doanh thu là **tiền thực thu** (`paidAmount`) theo **ngày thanh toán** (`paidAt`), tính hóa đơn `PAID` và `PARTIAL`. Doanh thu theo ngày có các khoảng 1, 7, 14, 30 ngày; doanh thu năm có 12 tháng tách tiền phòng và tiền dịch vụ, xuất CSV. Dashboard được cache trong Redis.

### Kịch bản demo
Postman: TC34 dashboard, TC35 danh sách hóa đơn có phân trang, TC13 lễ tân xem báo cáo doanh thu năm bị 403.
Bộ kiểm thử tự động không chạy các API ghi tiền (để không làm sai sổ quỹ), nên demo trực tiếp trên app hoặc Swagger theo thứ tự: lễ tân mở ca → khách gửi yêu cầu thanh toán → lễ tân xác nhận → xem `GET /shifts/current` thấy tiền tăng → chốt ca nhập số tiền lệch nhưng bỏ trống lý do (400) → nhập lý do → chốt thành công.

### Câu hỏi và trả lời gợi ý
**Hỏi: Sao không lưu thẳng `paidAmount` rồi cộng dồn?**
Cộng dồn ở nhiều chỗ (đặt cọc, thu tại quầy, khách chuyển khoản, hoàn tiền) rất dễ lệch hoặc cộng hai lần. Lưu từng dòng thu và tính lại từ sổ giúp truy vết được từng đồng và số liệu luôn nhất quán.

**Hỏi: Khách báo chuyển khoản nhưng thực ra chưa chuyển thì sao?**
Dòng thu ở trạng thái `PENDING`, chưa được tính vào hóa đơn; chỉ khi lễ tân kiểm tra sao kê và bấm xác nhận mới cộng. Nếu không thấy tiền thì từ chối kèm lý do.

**Hỏi: Doanh thu tính theo ngày lập hóa đơn hay ngày thu tiền?**
Theo ngày thu tiền (`paidAt`) và theo tiền thực thu. Trước đây mỗi API lọc một kiểu nên dashboard, báo cáo ngày và sổ quỹ ra ba con số khác nhau; nhóm gom về một hàm dùng chung `collectedRevenueWhere()`.

**Hỏi: Chốt ca bị lệch tiền thì hệ thống làm gì?**
Hiển thị số lệch (thừa/thiếu); bắt buộc nhập lý do giải trình thì mới chốt được; số liệu ca được lưu lại để quản trị viên xem lịch sử. Nếu nhân viên nghỉ đột xuất, admin chốt hộ qua `POST /shifts/{id}/close`.

**Hỏi: Tiền lưu kiểu gì? Có sai số không?**
Đang lưu `Float`; mọi phép tính đi qua `roundMoney()` làm tròn về đồng (VND không có phần lẻ) để tránh sai số cộng dồn. Đây là hạn chế đã nêu – hướng sửa là đổi sang `Decimal`.

**Hỏi: Thống kê có chậm khi dữ liệu lớn không?**
Các cột lọc có index (`paidAt`, `paymentStatus`, `confirmedAt`, `status`…), dashboard được cache, truy vấn tổng hợp dùng `aggregate` của Prisma thay vì kéo hết bản ghi về.

### Điểm yếu nên chủ động nói
- Chưa tích hợp cổng thanh toán tự động (VNPay, VietQR webhook) – lễ tân vẫn phải đối chiếu sao kê thủ công.
- Tiền lưu `Float` (đã làm tròn nhưng nên chuyển sang `Decimal`).

---

## Mẹo khi bảo vệ

- **Mở sẵn:** Swagger `/api/docs`, Postman Collection, file code của phần mình. Gọi trước một request tới máy chủ Render để “đánh thức” (lần đầu mất khoảng 40 giây).
- **Khi trình bày:** đi theo thứ tự *chức năng → API → Controller → Service → bảng CSDL → demo*. Chỉ thẳng vào dòng code xử lý ràng buộc chính (ví dụ dòng ném `ConflictException` khi trùng lịch).
- **Khi bị hỏi điểm chưa làm được:** nói rõ “đây là hạn chế đã nêu trong báo cáo, nguyên nhân…, hướng sửa…” – trung thực được đánh giá cao hơn nói tránh.
- **Số liệu nên thuộc:** 11 controller, 95 đường dẫn API, 10 bảng, 3 vai trò; kiểm thử 38/39 ca đạt; đặt đồng thời 10 yêu cầu → 1 đơn; 275/275 test ứng dụng đạt.
