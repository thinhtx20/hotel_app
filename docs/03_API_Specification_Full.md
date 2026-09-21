# TÀI LIỆU ĐẶC TẢ CHI TIẾT RESTFUL API (API SPECIFICATION DOCUMENT)
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL
### PHIÊN BẢN: 2.0.0 (CHUẨN HÓA TOÀN HỆ THỐNG)

---

## 1. QUY ƯỚC CHUNG VÀ CẤU TRÚC GIAO TIẾP (GENERAL CONVENTIONS)

### 1.1. Base URL và Môi trường
- **Production Server:** `https://hotel-management-plsp.onrender.com/api/v1`
- **Local Development:** `http://localhost:3000/api/v1`
- **Tiêu chuẩn dữ liệu:** Định dạng `application/json`, mã hóa ký tự `UTF-8`.

### 1.2. Cơ chế Xác thực (Authentication Scheme)
Tất cả các API yêu cầu xác thực người dùng bắt buộc phải gửi kèm Access Token dạng Bearer Token trong tiêu đề HTTP:
```http
Authorization: Bearer <access_token>
```
Nếu token thiếu, hết hạn hoặc không hợp lệ, hệ thống trả về HTTP `401 Unauthorized`.

### 1.3. Cấu trúc Phản hồi Chuẩn (Response Envelope)

#### 1. Khi xử lý thành công (HTTP 200, 201):
```json
{
  "statusCode": 200,
  "success": true,
  "message": "Thông báo thành công",
  "data": { ... } hoặc [ ... ],
  "timestamp": "2026-09-21T10:00:00.000Z"
}
```

#### 2. Khi xảy ra lỗi (HTTP 400, 401, 403, 404, 409, 500):
```json
{
  "statusCode": 409,
  "success": false,
  "message": "Phòng đã có khách đặt trong khoảng thời gian này.",
  "errorCode": "ERR_ROOM_OCCUPIED",
  "timestamp": "2026-09-21T10:00:00.000Z"
}
```

---

## 2. PHÂN HỆ 1: XÁC THỰC & NGƯỜI DÙNG (AUTHENTICATION & USERS)

### 2.1. Đăng ký tài khoản khách hàng mới
- **Endpoint:** `POST /auth/register`
- **Quyền hạn:** `Public`
- **Request Body:**
```json
{
  "email": "customer@example.com",
  "password": "Password123@",
  "fullName": "Nguyễn Văn An",
  "phone": "0912345678"
}
```
- **Response 201 Created:**
```json
{
  "statusCode": 201,
  "success": true,
  "message": "Đăng ký tài khoản thành công",
  "data": {
    "id": "usr_9981",
    "email": "customer@example.com",
    "fullName": "Nguyễn Văn An",
    "role": "CUSTOMER"
  }
}
```

### 2.2. Đăng nhập hệ thống
- **Endpoint:** `POST /auth/login`
- **Quyền hạn:** `Public`
- **Request Body:**
```json
{
  "email": "receptionist@luxegrand.com",
  "password": "Password123@"
}
```
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "usr_recept_01",
      "email": "receptionist@luxegrand.com",
      "fullName": "Trần Thị Lễ Tân",
      "role": "RECEPTIONIST"
    }
  }
}
```

### 2.3. Quên mật khẩu qua Email OTP
- **Endpoint:** `POST /auth/forgot-password`
- **Quyền hạn:** `Public`
- **Request Body:**
```json
{
  "email": "customer@example.com"
}
```
- **Response 200 OK:** Trả về thông báo đã gửi mã OTP 6 chữ số vào hộp thư email.

### 2.4. Xác thực mã OTP & Đặt lại mật khẩu mới
- **Endpoint:** `POST /auth/reset-password`
- **Quyền hạn:** `Public`
- **Request Body:**
```json
{
  "email": "customer@example.com",
  "otp": "839201",
  "newPassword": "NewSecurePassword123@"
}
```
- **Response 200 OK:** Mật khẩu được cập nhật thành công.

### 2.5. Lấy thông tin tài khoản hiện tại
- **Endpoint:** `GET /auth/me`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập (`Bearer Token`)
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "id": "usr_9981",
    "email": "customer@example.com",
    "fullName": "Nguyễn Văn An",
    "phone": "0912345678",
    "role": "CUSTOMER",
    "avatarUrl": "https://res.cloudinary.com/.../avatar.webp",
    "isActive": true
  }
}
```

### 2.6. Đổi mật khẩu tài khoản đang đăng nhập
- **Endpoint:** `POST /auth/change-password`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập
- **Request Body:**
```json
{
  "oldPassword": "OldPassword123@",
  "newPassword": "NewSecurePassword456@"
}
```
- **Response 200 OK:** Cập nhật mật khẩu thành công.

### 2.7. Đăng xuất tài khoản
- **Endpoint:** `POST /auth/logout`
- **Quyền hạn:** Public / Đã đăng nhập (Thu hồi token và hủy phiên)
- **Response 200 OK:** Đăng xuất thành công.

### 2.8. Quản lý Danh sách Người dùng & Nhân sự
- **Endpoint:** `GET /users`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST` (Lễ tân chỉ xem danh sách khách hàng)
- **Query Parameters:** `role` (CUSTOMER|RECEPTIONIST|ADMIN), `search`, `page`, `limit`
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "items": [
      {
        "id": "usr_staff_01",
        "email": "recept01@luxegrand.com",
        "fullName": "Trần Thị Lễ Tân",
        "phone": "0988776655",
        "role": "RECEPTIONIST",
        "isActive": true,
        "createdAt": "2026-09-01T08:00:00Z"
      }
    ],
    "meta": { "total": 24, "page": 1, "limit": 20, "totalPages": 2 }
  }
}
```

### 2.9. Admin khởi tạo Tài khoản Nhân viên mới
- **Endpoint:** `POST /users`
- **Quyền hạn:** `ADMIN`
- **Request Body:**
```json
{
  "email": "cashier02@luxegrand.com",
  "password": "InitialPassword123@",
  "fullName": "Lê Văn Thu Ngân",
  "phone": "0911223344",
  "role": "RECEPTIONIST"
}
```
- **Response 201 Created:** Khởi tạo nhân viên mới thành công.

### 2.10. Admin cập nhật Phân quyền & Trạng thái Hoạt động
- **Endpoint:** `PATCH /users/{id}`
- **Quyền hạn:** `ADMIN`
- **Request Body:**
```json
{
  "role": "ADMIN",
  "isActive": false
}
```
- **Response 200 OK:** Cập nhật quyền hạn và khóa/mở khóa tài khoản thành công.

### 2.11. Admin đặt lại Mật khẩu Nhân sự trực tiếp
- **Endpoint:** `PATCH /users/{id}/password` (hoặc `POST /users/{id}/password`)
- **Quyền hạn:** `ADMIN`
- **Request Body:**
```json
{
  "newPassword": "ResetSecurePassword999@"
}
```
- **Response 200 OK:** Cấp lại mật khẩu nhân viên thành công.

### 2.12. Người dùng tự cập nhật Hồ sơ cá nhân
- **Endpoint:** `PATCH /users/me`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập
- **Request Body:**
```json
{
  "fullName": "Nguyễn Văn An (VIP)",
  "phone": "0909998877"
}
```
- **Response 200 OK:** Cập nhật thông tin cá nhân thành công.

### 2.13. Đăng ký & Cập nhật FCM Registration Token
- **Endpoint:** `PATCH /users/fcm-token`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập
- **Request Body:**
```json
{
  "fcmToken": "f7DkLm9_QeS8...xYz1029"
}
```
- **Response 200 OK:** Đồng bộ token nhận Push Notification thành công.

---

## 3. PHÂN HỆ 2: QUẢN LÝ PHÒNG & MA TRẬN PHÒNG (ROOMS & MATRIX)

### 3.1. Lấy Ma trận Phòng thời gian thực (Room Matrix)
- **Endpoint:** `GET /rooms/matrix`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Mô tả:** Trả về sơ đồ toàn bộ các phòng phân chia theo tầng kèm trạng thái thời gian thực.
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": [
    {
      "floor": 1,
      "totalRooms": 6,
      "rooms": [
        {
          "id": "room_101",
          "roomNumber": "101",
          "roomTypeName": "Standard Queen Double",
          "pricePerNight": 1200000,
          "status": "AVAILABLE",
          "currentBooking": null
        },
        {
          "id": "room_102",
          "roomNumber": "102",
          "roomTypeName": "Standard Queen Double",
          "pricePerNight": 1200000,
          "status": "OCCUPIED",
          "currentBooking": {
            "bookingCode": "BK-2026-088",
            "customerName": "Nguyễn Văn An",
            "checkInDate": "2026-09-20T14:00:00Z",
            "checkOutDate": "2026-09-23T12:00:00Z"
          }
        }
      ]
    }
  ]
}
```

### 3.2. Tìm kiếm phòng trống theo ngày (Check Available Rooms)
- **Endpoint:** `GET /rooms/available`
- **Quyền hạn:** `Public`, `All`
- **Query Parameters:** `checkInDate`, `checkOutDate`, `guestCount`, `roomTypeId`
- **Response 200 OK:** Trả về danh sách các phòng hoàn toàn trống lịch.

---

## 4. PHÂN HỆ 3: ĐẶT PHÒNG & QUẦY TIỀN SẢNH (BOOKINGS LIFECYCLE)

### 4.1. Tạo đơn đặt phòng mới
- **Endpoint:** `POST /bookings`
- **Quyền hạn:** `CUSTOMER`, `RECEPTIONIST`, `ADMIN`
- **Request Body:**
```json
{
  "roomId": "room_201",
  "checkInDate": "2026-09-25T14:00:00Z",
  "checkOutDate": "2026-09-28T12:00:00Z",
  "guestCount": 2,
  "specialRequests": "Yêu cầu phòng tầng cao, giường đôi lớn"
}
```
- **Response 201 Created:**
```json
{
  "statusCode": 201,
  "success": true,
  "message": "Tạo đơn đặt phòng thành công",
  "data": {
    "id": "bk_2026_099",
    "bookingCode": "BK-2026-099",
    "status": "PENDING",
    "totalAmount": 6000000,
    "invoice": {
      "id": "inv_099",
      "invoiceCode": "INV-2026-099",
      "finalAmount": 6000000,
      "paidAmount": 0,
      "paymentStatus": "UNPAID"
    }
  }
}
```

### 4.2. Lấy danh sách đơn đặt phòng chờ duyệt
- **Endpoint:** `GET /bookings/pending`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Query Parameters:** `page`, `limit`, `search`
- **Response 200 OK:** Trả về danh sách các đơn trực tuyến có `status = PENDING`.

### 4.3. Phê duyệt đơn đặt phòng
- **Endpoint:** `PUT /bookings/{id}/approve`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Body (Optional):** `{ "note": "Đã xếp phòng theo yêu cầu" }`
- **Response 200 OK:** Cập nhật `booking.status = CONFIRMED`, `room.status = RESERVED`.

### 4.4. Từ chối đơn đặt phòng
- **Endpoint:** `PUT /bookings/{id}/reject`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Body (Bắt buộc):**
```json
{
  "reason": "Khách sạn kín phòng do khách đoàn bao trọn tầng."
}
```
- **Response 200 OK:** Đơn chuyển sang `CANCELLED`.

### 4.5. Thủ tục Nhận phòng (Check-In)
- **Endpoint:** `POST /bookings/{id}/check-in`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Body:**
```json
{
  "identificationNumber": "001201009988",
  "note": "Khách đã giao đủ CCCD"
}
```
- **Response 200 OK:** Đơn sang `CHECKED_IN`, phòng chuyển sang màu đỏ `OCCUPIED`.

### 4.6. Đổi phòng lưu trú (Change Room)
- **Endpoint:** `POST /bookings/{id}/change-room`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Body:**
```json
{
  "newRoomId": "room_205",
  "reason": "Điều hòa phòng cũ có tiếng ồn"
}
```
- **Response 200 OK:** Phòng cũ chuyển về `CLEANING`, phòng mới chuyển sang `OCCUPIED`, đơn cập nhật sang `newRoomId`.

### 4.7. Thủ tục Trả phòng (Check-Out)
- **Endpoint:** `POST /bookings/{id}/check-out`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`, `CASHIER`
- **Request Body:**
```json
{
  "keyReturned": true,
  "minibarCharges": 150000,
  "note": "Đã kiểm phòng đầy đủ"
}
```
- **Response 200 OK:** Đơn sang `CHECKED_OUT`, phòng chuyển về `CLEANING`.

### 4.8. Bảng kê Xem trước Chi phí trước khi Trả phòng (Checkout Preview)
- **Endpoint:** `GET /bookings/{id}/checkout-preview`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`, `CASHIER`
- **Mô tả:** Trích xuất toàn bộ bảng kê chi phí (tiền phòng theo đêm thực tế, dịch vụ phát sinh, phụ thu, số tiền đã cọc) và số tiền còn thiếu trước khi chốt hóa đơn. API này chỉ đọc, không làm thay đổi trạng thái đơn hay phòng.
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "bookingId": "bk_2026_099",
    "roomNumber": "201",
    "customerName": "Nguyễn Văn An",
    "actualNights": 3,
    "roomTotal": 3600000,
    "servicesTotal": 450000,
    "lateSurcharge": 0,
    "finalAmount": 4050000,
    "paidAmount": 2000000,
    "amountDue": 2050000,
    "isFullyPaid": false,
    "services": [
      { "name": "Nước suối khoáng Lavie", "quantity": 2, "price": 40000 },
      { "name": "Giặt là nhanh 4h", "quantity": 1, "price": 120000 }
    ]
  }
}
```

---

## 5. PHÂN HỆ 4: HÓA ĐƠN & SỔ THU TIỀN ĐA ĐỢT (INVOICES & PAYMENTS)

### 5.1. Tạo bản ghi thu tiền (Thanh toán / Đặt cọc)
- **Endpoint:** `POST /invoices/{id}/payments` (hoặc `POST /invoices/{id}/pay`)
- **Quyền hạn:** `CUSTOMER`, `RECEPTIONIST`, `CASHIER`
- **Request Body:**
```json
{
  "amount": 2000000,
  "method": "BANK_TRANSFER",
  "type": "DEPOSIT",
  "reference": "FT260921008892",
  "note": "Khách chuyển cọc trước 2 triệu"
}
```
- **Response 201 Created:**
  + Nếu là `CASH`: Thu ngân tạo trực tiếp -> `status = CONFIRMED`, cộng ngay vào `paidAmount`.
  + Nếu là `CUSTOMER` tự chuyển khoản -> `status = PENDING`, chờ thu ngân đối soát.

### 5.2. Thu ngân Phê duyệt Giao dịch Chuyển khoản
- **Endpoint:** `POST /invoices/payments/{paymentId}/confirm` (hoặc `PUT`)
- **Quyền hạn:** `RECEPTIONIST`, `CASHIER`, `ADMIN`
- **Response 200 OK:** Chuyển trạng thái giao dịch sang `CONFIRMED`, tự động cộng dồn số tiền vào `Invoice.paidAmount`.

### 5.3. Thu ngân Từ chối Giao dịch Chuyển khoản Nghi vấn
- **Endpoint:** `POST /invoices/payments/{paymentId}/reject`
- **Quyền hạn:** `RECEPTIONIST`, `CASHIER`, `ADMIN`
- **Request Body (Bắt buộc):**
```json
{
  "reason": "Chưa nhận được tiền vào tài khoản ngân hàng, vui lòng kiểm tra lại giao dịch"
}
```
- **Response 200 OK:** Giao dịch chuyển sang `REJECTED`, không cộng tiền vào hóa đơn và gửi thông báo giải thích cho khách hàng.

### 5.4. Hoàn tiền Hóa đơn (Refund)
- **Endpoint:** `POST /invoices/{id}/refund`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Body:**
```json
{
  "amount": 500000,
  "reason": "Hoàn trả tiền thừa đặt cọc minibar sau khi kiểm phòng"
}
```
- **Response 200 OK:** Ghi nhận bản ghi hoàn tiền (`type = REFUND`) và giảm trừ số dư hóa đơn tương ứng.

---

## 6. PHÂN HỆ 5: QUẢN LÝ CA TRỰC LỄ TÂN (WORKSHIFTS)

### 6.1. Mở ca trực đầu ngày
- **Endpoint:** `POST /shifts/open`
- **Quyền hạn:** `RECEPTIONIST`
- **Request Body:**
```json
{
  "shiftType": "MORNING",
  "deskName": "Quầy Lễ Tân 01",
  "initialCash": 2000000,
  "openNote": "Nhận bàn giao 2 triệu tiền mặt lẻ từ ca đêm"
}
```
- **Response 201 Created:** Khởi tạo ca trực mới ở trạng thái `OPEN`.

### 6.2. Chốt ca trực & Đối soát tiền két
- **Endpoint:** `POST /shifts/close`
- **Quyền hạn:** `RECEPTIONIST`
- **Request Body:**
```json
{
  "actualCash": 5100000,
  "differenceReason": "Thừa 100.000đ do khách tip nhưng nhập chung két"
}
```
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "message": "Chốt ca trực thành công",
  "data": {
    "shiftCode": "SFT-20260921-0001",
    "status": "CLOSED",
    "initialCash": 2000000,
    "actualCash": 5100000,
    "expectedCash": 5000000,
    "cashDifference": 100000,
    "differenceReason": "Thừa 100.000đ do khách tip nhưng nhập chung két",
    "totalRevenue": 8500000
  }
}
```

### 6.3. Lấy thông tin Ca trực hiện tại của User
- **Endpoint:** `GET /shifts/current`
- **Quyền hạn:** `RECEPTIONIST`, `ADMIN`
- **Response 200 OK:** Trả về ca trực đang `OPEN` của tài khoản đăng nhập (hoặc `null` nếu chưa mở ca).

### 6.4. Tra cứu Sổ Lịch sử Ca trực toàn khách sạn
- **Endpoint:** `GET /shifts`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Query Parameters:** `status` (OPEN|CLOSED), `date`, `staffId`, `page`, `limit`
- **Response 200 OK:** Danh sách lịch sử các ca trực đã mở/đóng kèm phân trang.

### 6.5. Xem Chi tiết Ca trực & Sổ Giao dịch trong ca
- **Endpoint:** `GET /shifts/{id}`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Response 200 OK:** Toàn bộ biên bản bàn giao quỹ ca trực, thông tin nhân viên mở/đóng ca và danh sách tất cả các khoản thu tiền mặt, chuyển khoản, quẹt thẻ phát sinh trong ca.

### 6.6. Admin Cưỡng chế Chốt ca trực
- **Endpoint:** `POST /shifts/{id}/close`
- **Quyền hạn:** `ADMIN`
- **Request Body:**
```json
{
  "actualCash": 2000000,
  "notes": "Admin cưỡng chế chốt ca do nhân viên nghỉ ốm đột xuất"
}
```
- **Response 200 OK:** Đóng ca trực khẩn cấp, giải phóng quầy để ca tiếp theo làm việc.

---

## 7. PHÂN HỆ 6: BÁO CÁO & THỐNG KÊ QUẢN TRỊ (ANALYTICS)

### 7.1. Báo cáo Doanh thu theo năm & Cơ cấu 12 tháng
- **Endpoint:** `GET /analytics/revenue`
- **Quyền hạn:** `ADMIN`
- **Query Parameter:** `year=2026`
- **Response 200 OK:** Trả về tổng doanh thu năm, phân tách tiền phòng và dịch vụ, chuỗi doanh thu 12 tháng.

### 7.2. Phân tích chi tiết Tỷ lệ Lấp đầy phòng (Occupancy Details)
- **Endpoint:** `GET /analytics/occupancy/detail`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Response 200 OK:** Tỷ lệ lấp đầy hôm nay và chi tiết theo từng hạng phòng.

### 7.3. Báo cáo Doanh thu Ngắn hạn theo Ngày
- **Endpoint:** `GET /analytics/revenue/daily`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Query Parameter:** `range=7` (hoặc `14`, `30`)
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": [
    { "date": "2026-09-15", "revenue": 14500000, "invoicesCount": 4 },
    { "date": "2026-09-16", "revenue": 18200000, "invoicesCount": 6 },
    { "date": "2026-09-17", "revenue": 22000000, "invoicesCount": 7 }
  ]
}
```

### 7.4. Báo cáo Hiệu suất Phục vụ của Nhân viên
- **Endpoint:** `GET /analytics/staff-performance`
- **Quyền hạn:** `ADMIN`
- **Query Parameter:** `date=2026-09-21` (hoặc `from`, `to`)
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": [
    {
      "staffId": "usr_recept_01",
      "staffName": "Trần Thị Lễ Tân",
      "checkInsCount": 8,
      "checkOutsCount": 5,
      "totalCollected": 32500000,
      "shiftsCompleted": 18
    }
  ]
}
```

---

## 8. PHÂN HỆ 7: TRUNG TÂM THÔNG BÁO (NOTIFICATIONS)

### 8.1. Lấy danh sách Thông báo của người dùng
- **Endpoint:** `GET /notifications`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập
- **Query Parameters:** `page`, `limit`
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "data": {
    "unreadCount": 3,
    "items": [
      {
        "id": "notif_001",
        "title": "Đơn đặt phòng đã được xác nhận!",
        "message": "Đơn BK-2026-099 của quý khách tại phòng 201 đã được khách sạn phê duyệt.",
        "type": "BOOKING_CONFIRMED",
        "isRead": false,
        "createdAt": "2026-09-21T09:15:00Z"
      }
    ]
  }
}
```

### 8.2. Đánh dấu Đã đọc một Thông báo
- **Endpoint:** `PATCH /notifications/{id}/read`
- **Quyền hạn:** Tài khoản sở hữu thông báo
- **Response 200 OK:** Cập nhật `isRead = true`.

### 8.3. Đánh dấu Đã đọc Tất cả Thông báo
- **Endpoint:** `PATCH /notifications/read-all`
- **Quyền hạn:** Tài khoản sở hữu thông báo
- **Response 200 OK:** Tất cả thông báo chuyển `isRead = true`.

### 8.4. Bắn Thông báo Thử nghiệm (Test Notification)
- **Endpoint:** `POST /notifications/test`
- **Quyền hạn:** `ADMIN`
- **Request Body:** `{ "title": "Kiểm tra FCM", "body": "Nội dung tin nhắn test" }`
- **Response 200 OK:** Thông báo được gửi đến thiết bị.

---

## 9. PHÂN HỆ 8: LƯU TRỮ & TẢI LÊN TỆP TIN (FILE UPLOAD)

### 9.1. Tải lên Ảnh Đại diện Cá nhân (Avatar)
- **Endpoint:** `POST /upload/avatar`
- **Quyền hạn:** Tất cả vai trò đã đăng nhập
- **Request Type:** `multipart/form-data` (Trường `file`)
- **Response 200 OK:** Trả về đường dẫn ảnh `avatarUrl` trên CDN đám mây.

### 9.2. Tải lên Ảnh Phòng & Album Phòng
- **Endpoint:** `POST /upload/room` (ảnh đơn), `POST /upload/rooms` (album ảnh)
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Request Type:** `multipart/form-data`
- **Response 200 OK:** Trả về danh sách URL ảnh đã tải lên và liên kết với mã phòng.

### 9.3. Xóa Ảnh khỏi Hệ thống
- **Endpoint:** `DELETE /upload`
- **Quyền hạn:** `ADMIN`
- **Query Parameter:** `path=rooms/room_201_view.jpg`
- **Response 200 OK:** Xóa ảnh thành công khỏi kho lưu trữ.

---

## 10. PHÂN HỆ 9: ĐỒNG BỘ TRẠNG THÁI & REALTIME STREAMING

### 10.1. Rà soát & Đồng bộ Trạng thái Phòng theo Lịch
- **Endpoint:** `POST /rooms/sync-status`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "message": "Đồng bộ trạng thái phòng thành công",
  "data": { "updatedRoomsCount": 2 }
}
```

### 10.2. Server-Sent Events (SSE) Realtime Stream Trạng thái Phòng
- **Endpoint:** `GET /rooms/stream`
- **Quyền hạn:** Public / Bearer Token
- **Protocol:** Server-Sent Events (`text/event-stream`)
- **Event Types:**
  + `room.status_changed`: Phát ra khi phòng đổi trạng thái (`AVAILABLE`, `OCCUPIED`, `CLEANING`...)
  + `room.created`: Phát ra khi có phòng mới được tạo
  + `room.updated`: Phát ra khi cập nhật thông tin phòng

---

## 11. BẢNG TỔNG HỢP MÃ LỖI NGHIỆP VỤ (BUSINESS ERROR CODES)

| Mã lỗi (Error Code) | HTTP Status | Diễn giải nguyên nhân |
| :--- | :--- | :--- |
| `ERR_UNAUTHORIZED` | 401 | Token xác thực không hợp lệ hoặc đã hết hạn |
| `ERR_FORBIDDEN_ROLE` | 403 | Tài khoản không đủ quyền hạn thực hiện hành động này |
| `ERR_ROOM_OCCUPIED` | 409 | Phòng đã có khách đặt trong khoảng thời gian được chọn |
| `ERR_BOOKING_NOT_FOUND` | 404 | Không tìm thấy mã đơn đặt phòng trong hệ thống |
| `ERR_INVALID_STATUS` | 400 | Trạng thái của đơn không phù hợp để thực hiện thao tác |
| `ERR_REASON_REQUIRED` | 400 | Bắt buộc phải nhập lý do khi từ chối đơn hoặc chốt ca lệch tiền |
| `ERR_SHIFT_ALREADY_OPEN` | 409 | Nhân viên đã có một ca trực đang mở, không thể mở thêm |
| `ERR_INSUFFICIENT_PAYMENT`| 400 | Chưa thể check-out do hóa đơn còn dư nợ chưa thanh toán |
| `ERR_OLD_PASSWORD_INCORRECT`| 400 | Mật khẩu cũ không chính xác khi thực hiện đổi mật khẩu |
| `ERR_USER_DEACTIVATED` | 403 | Tài khoản nhân sự đã bị Quản trị viên vô hiệu hóa |
| `ERR_PAYMENT_REJECTED` | 400 | Yêu cầu chuyển khoản đã bị thu ngân từ chối do không nhận được tiền |

