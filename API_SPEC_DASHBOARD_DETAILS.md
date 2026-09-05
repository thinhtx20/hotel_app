# ĐẶC TẢ YÊU CẦU API CHO BACKEND (DASHBOARD DETAIL MODULES)
**Dự án:** Luxe Grand Hotel Management App  
**Phiên bản tài liệu:** 1.0.0  
**Ngày phát hành:** 04/09/2026  
**Người lập:** Mobile Team  
**Người nhận:** Backend Team  

---

## 1. TỔNG QUAN HỆ THỐNG & QUY ƯỚC CHUNG

### 1.1. Base URL & Môi trường
- **Development / Staging:** `https://hotel-management-plsp.onrender.com/api/v1`
- **Tiêu chuẩn:** RESTful API, trao đổi dữ liệu định dạng `application/json`.
- **Mã hóa:** UTF-8.

### 1.2. Xác thực (Authentication)
Mọi request (ngoại trừ login/register) bắt buộc phải đính kèm JWT Bearer Token trong header:
```http
Authorization: Bearer <access_token>
```
Nếu token hết hạn hoặc không hợp lệ, BE trả về `401 Unauthorized`.

### 1.3. Cấu trúc phản hồi chuẩn (Standard Response Format)
Tất cả các API thành công phải tuân thủ format:
```json
{
  "success": true,
  "message": "Thông báo thành công (nếu có)",
  "data": { ... } hoặc [ ... ]
}
```

Nếu có lỗi xảy ra:
```json
{
  "success": false,
  "message": "Mô tả nguyên nhân lỗi cụ thể cho người dùng",
  "errorCode": "ERR_ROOM_NOT_AVAILABLE",
  "errors": []
}
```

---

## 2. CÁC API CHI TIẾT CẦN BỔ SUNG / CHUẨN HÓA

---

### 2.1. API Chi tiết Tỷ lệ Lấp đầy (Occupancy Details)

*Phục vụ màn hình: Chi tiết Tỷ lệ Lấp đầy khi người dùng nhấn vào thẻ "Tỷ lệ lấp đầy" trên Dashboard.*

- **Method:** `GET`
- **Endpoint:** `/analytics/occupancy/detail`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Mô tả:** Trả về dữ liệu phân tích chi tiết về tỷ lệ lấp đầy: tổng số phòng, số phòng đang có khách, tỷ lệ %, cơ cấu phòng theo trạng thái, tỷ lệ lấp đầy theo từng loại phòng, và danh sách các phòng kèm thông tin khách đang ở (nếu có).

#### Query Parameters:
| Tham số | Kiểu | Bắt buộc | Mặc định | Mô tả |
| :--- | :--- | :--- | :--- | :--- |
| `floor` | Integer | Không | Tất cả | Lọc theo số tầng (1, 2, 3...) |
| `roomTypeId` | String | Không | Tất cả | Lọc theo ID loại phòng |
| `status` | String | Không | Tất cả | `AVAILABLE`, `OCCUPIED`, `CLEANING`, `RESERVED`, `MAINTENANCE` |

#### Response 200 OK:
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalRooms": 20,
      "occupiedRooms": 4,
      "availableRooms": 10,
      "cleaningRooms": 2,
      "reservedRooms": 3,
      "maintenanceRooms": 1,
      "occupancyRate": 20.0
    },
    "byRoomType": [
      {
        "roomTypeId": "rt_standard",
        "roomTypeName": "Standard Queen Double",
        "totalRooms": 6,
        "occupiedRooms": 1,
        "occupancyRate": 16.7,
        "basePrice": 1200000
      },
      {
        "roomTypeId": "rt_deluxe",
        "roomTypeName": "Deluxe Ocean Panorama",
        "totalRooms": 8,
        "occupiedRooms": 2,
        "occupancyRate": 25.0,
        "basePrice": 2000000
      },
      {
        "roomTypeId": "rt_suite",
        "roomTypeName": "Presidential Penthouse",
        "totalRooms": 6,
        "occupiedRooms": 1,
        "occupancyRate": 16.7,
        "basePrice": 4500000
      }
    ],
    "rooms": [
      {
        "id": "room_103",
        "roomNumber": "103",
        "floor": 1,
        "roomTypeId": "rt_standard",
        "roomTypeName": "Standard Queen Double",
        "pricePerNight": 1200000,
        "status": "OCCUPIED",
        "currentBooking": {
          "id": "bk_001",
          "bookingCode": "BK-2026-001",
          "customerName": "Nguyễn Văn An",
          "customerPhone": "0912345678",
          "checkInDate": "2026-09-03T14:00:00Z",
          "checkOutDate": "2026-09-06T12:00:00Z"
        }
      },
      {
        "id": "room_101",
        "roomNumber": "101",
        "floor": 1,
        "roomTypeId": "rt_standard",
        "roomTypeName": "Standard Queen Double",
        "pricePerNight": 1200000,
        "status": "AVAILABLE",
        "currentBooking": null
      }
    ]
  }
}
```

---

### 2.2. API Lượt Nhận Phòng Hôm Nay (Today Check-Ins)

*Phục vụ màn hình: Danh sách khách nhận phòng trong ngày khi người dùng bấm vào thẻ "Lượt nhận phòng".*

- **Method:** `GET`
- **Endpoint:** `/bookings/today/check-ins`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Mô tả:** Lấy toàn bộ danh sách đơn đặt phòng có lịch nhận phòng trong ngày hôm nay (từ 00:00:00 đến 23:59:59 của ngày hiện tại).

#### Query Parameters:
| Tham số | Kiểu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `status` | String | Không | `CONFIRMED` (chờ nhận phòng), `CHECKED_IN` (đã nhận phòng). Nếu bỏ trống sẽ lấy tất cả. |
| `search` | String | Không | Tìm theo tên khách, số điện thoại, mã đơn, số phòng. |

#### Response 200 OK:
```json
{
  "success": true,
  "data": {
    "totalExpected": 4,
    "checkedInCount": 1,
    "pendingCheckInCount": 3,
    "bookings": [
      {
        "id": "bk_checkin_01",
        "bookingCode": "BK-2026-088",
        "roomId": "room_201",
        "roomNumber": "201",
        "roomTypeName": "Deluxe Ocean View",
        "floor": 2,
        "customerId": "user_456",
        "customerName": "Trần Thị Mai",
        "customerPhone": "0987654321",
        "checkInDate": "2026-09-04T14:00:00Z",
        "checkOutDate": "2026-09-07T12:00:00Z",
        "actualCheckIn": null,
        "guestCount": 2,
        "totalAmount": 5400000,
        "depositAmount": 2000000,
        "remainingAmount": 3400000,
        "status": "CONFIRMED",
        "specialRequests": "Yêu cầu phòng tầng cao, giường đôi lớn"
      },
      {
        "id": "bk_checkin_02",
        "bookingCode": "BK-2026-082",
        "roomId": "room_105",
        "roomNumber": "105",
        "roomTypeName": "Standard Queen",
        "floor": 1,
        "customerId": "user_789",
        "customerName": "Lê Hoàng Long",
        "customerPhone": "0901234567",
        "checkInDate": "2026-09-04T12:30:00Z",
        "checkOutDate": "2026-09-05T12:00:00Z",
        "actualCheckIn": "2026-09-04T12:35:10Z",
        "guestCount": 1,
        "totalAmount": 1200000,
        "depositAmount": 1200000,
        "remainingAmount": 0,
        "status": "CHECKED_IN",
        "specialRequests": null
      }
    ]
  }
}
```

---

### 2.3. API Lượt Trả Phòng Hôm Nay (Today Check-Outs)

*Phục vụ màn hình: Danh sách khách trả phòng trong ngày khi người dùng bấm vào thẻ "Lượt trả phòng".*

- **Method:** `GET`
- **Endpoint:** `/bookings/today/check-outs`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`, `CASHIER`
- **Mô tả:** Lấy danh sách các đơn phòng dự kiến trả phòng hôm nay hoặc đã hoàn tất trả phòng hôm nay.

#### Query Parameters:
| Tham số | Kiểu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `status` | String | Không | `CHECKED_IN` (đang ở, chờ trả phòng), `CHECKED_OUT` (đã trả phòng xong). |
| `search` | String | Không | Tìm theo tên khách, số điện thoại, mã đơn, số phòng. |

#### Response 200 OK:
```json
{
  "success": true,
  "data": {
    "totalExpected": 3,
    "checkedOutCount": 1,
    "pendingCheckOutCount": 2,
    "bookings": [
      {
        "id": "bk_checkout_01",
        "bookingCode": "BK-2026-075",
        "roomId": "room_302",
        "roomNumber": "302",
        "roomTypeName": "Deluxe Ocean Panorama",
        "floor": 3,
        "customerId": "user_112",
        "customerName": "Vũ Minh Tuấn",
        "customerPhone": "0933445566",
        "checkInDate": "2026-09-02T14:00:00Z",
        "checkOutDate": "2026-09-04T12:00:00Z",
        "actualCheckOut": null,
        "guestCount": 2,
        "totalAmount": 4000000,
        "paymentStatus": "PARTIALLY_PAID",
        "invoiceId": "inv_9981",
        "status": "CHECKED_IN",
        "unpaidServicesAmount": 350000
      },
      {
        "id": "bk_checkout_02",
        "bookingCode": "BK-2026-071",
        "roomId": "room_104",
        "roomNumber": "104",
        "roomTypeName": "Standard Queen",
        "floor": 1,
        "customerId": "user_334",
        "customerName": "Phạm Thị Hương",
        "customerPhone": "0944556677",
        "checkInDate": "2026-09-01T14:00:00Z",
        "checkOutDate": "2026-09-04T11:00:00Z",
        "actualCheckOut": "2026-09-04T10:45:00Z",
        "guestCount": 2,
        "totalAmount": 3600000,
        "paymentStatus": "PAID",
        "invoiceId": "inv_9975",
        "status": "CHECKED_OUT",
        "unpaidServicesAmount": 0
      }
    ]
  }
}
```

---

### 2.4. API Danh Sách Đơn Đặt Phòng Chờ Duyệt (Pending Bookings)

*Phục vụ màn hình: Quản lý và duyệt đơn đặt phòng khi người dùng bấm vào thẻ "Đơn chờ duyệt".*

- **Method:** `GET`
- **Endpoint:** `/bookings/pending`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Mô tả:** Lấy danh sách các đơn đặt phòng do khách tạo trực tuyến đang ở trạng thái `PENDING` (chờ xác nhận/duyệt từ khách sạn).

#### Query Parameters:
| Tham số | Kiểu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `status` | String | Không | Mặc định là `PENDING`. Có thể truyền thêm `CONFIRMED`, `CANCELLED` để xem lịch sử đã duyệt/từ chối. |
| `search` | String | Không | Tìm theo tên khách, sđt, mã booking. |
| `page` | Integer | Không | Phân trang (mặc định 1) |
| `limit` | Integer | Không | Số bản ghi / trang (mặc định 20) |

#### Response 200 OK:
```json
{
  "success": true,
  "data": {
    "totalPending": 2,
    "bookings": [
      {
        "id": "bk_pen_01",
        "bookingCode": "BK-2026-102",
        "createdAt": "2026-09-04T08:15:00Z",
        "roomId": "room_501",
        "roomNumber": "501",
        "roomTypeName": "Presidential Penthouse",
        "floor": 5,
        "customerId": "cust_882",
        "customerName": "Đặng Quốc Hưng",
        "customerPhone": "0918889999",
        "checkInDate": "2026-09-10T14:00:00Z",
        "checkOutDate": "2026-09-14T12:00:00Z",
        "nights": 4,
        "guestCount": 3,
        "totalAmount": 18000000,
        "depositAmount": 5000000,
        "status": "PENDING",
        "specialRequests": "Yêu cầu setup bánh sinh nhật và rượu vang lúc nhận phòng."
      },
      {
        "id": "bk_pen_02",
        "bookingCode": "BK-2026-103",
        "createdAt": "2026-09-04T08:30:00Z",
        "roomId": "room_203",
        "roomNumber": "203",
        "roomTypeName": "Superior City View",
        "floor": 2,
        "customerId": "cust_901",
        "customerName": "Ngô Thị Bích",
        "customerPhone": "0977665544",
        "checkInDate": "2026-09-05T14:00:00Z",
        "checkOutDate": "2026-09-07T12:00:00Z",
        "nights": 2,
        "guestCount": 2,
        "totalAmount": 3200000,
        "depositAmount": 0,
        "status": "PENDING",
        "specialRequests": "Nhận phòng sớm khoảng 11h sáng nếu có phòng trống."
      }
    ]
  }
}
```

---

### 2.5. API Phê Duyệt Đơn Đặt Phòng (Approve Booking)

*Thực thi khi quản trị viên bấm nút "Duyệt đơn".*

- **Method:** `PUT`
- **Endpoint:** `/bookings/{id}/approve`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Path Variable:** `id` (ID của booking cần duyệt)
- **Request Body (Optional):**
```json
{
  "assignedRoomId": "room_501",
  "note": "Đã xác nhận phòng và chuẩn bị rượu vang cho khách"
}
```

#### Response 200 OK:
```json
{
  "success": true,
  "message": "Đã phê duyệt đơn đặt phòng BK-2026-102 thành công",
  "data": {
    "id": "bk_pen_01",
    "bookingCode": "BK-2026-102",
    "status": "CONFIRMED",
    "confirmedAt": "2026-09-04T08:45:00Z"
  }
}
```

---

### 2.6. API Từ Chối Đơn Đặt Phòng (Reject Booking)

*Thực thi khi quản trị viên bấm nút "Từ chối".*

- **Method:** `PUT` (hoặc `POST /bookings/{id}/reject`)
- **Endpoint:** `/bookings/{id}/reject`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Path Variable:** `id`
- **Request Body:**
```json
{
  "reason": "Khách sạn đã hết phòng trong thời gian yêu cầu do khách đoàn đặt trước."
}
```

#### Response 200 OK:
```json
{
  "success": true,
  "message": "Đã từ chối đơn đặt phòng thành công",
  "data": {
    "id": "bk_pen_02",
    "bookingCode": "BK-2026-103",
    "status": "CANCELLED",
    "cancellationReason": "Khách sạn đã hết phòng trong thời gian yêu cầu do khách đoàn đặt trước."
  }
}
```

---

### 2.7. API Nhận Phòng Nhanh (Check-In)

- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/check-in`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`
- **Path Variable:** `id`
- **Request Body (Optional):**
```json
{
  "identificationNumber": "001201012345",
  "note": "Khách đã giao đủ CMND/CCCD"
}
```
#### Response 200 OK:
```json
{
  "success": true,
  "message": "Nhận phòng thành công cho khách hàng",
  "data": {
    "bookingId": "bk_checkin_01",
    "actualCheckIn": "2026-09-04T13:45:00Z",
    "status": "CHECKED_IN",
    "room": {
      "id": "room_201",
      "roomNumber": "201",
      "status": "OCCUPIED"
    }
  }
}
```

---

### 2.8. API Trả Phòng Nhanh (Check-Out)

- **Method:** `POST`
- **Endpoint:** `/bookings/{id}/check-out`
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`, `CASHIER`
- **Path Variable:** `id`
- **Request Body (Optional):**
```json
{
  "keyReturned": true,
  "minibarCharges": 150000,
  "note": "Phòng nguyên vẹn, đã kiểm tra minibar"
}
```
#### Response 200 OK:
```json
{
  "success": true,
  "message": "Trả phòng thành công",
  "data": {
    "bookingId": "bk_checkout_01",
    "actualCheckOut": "2026-09-04T11:45:00Z",
    "status": "CHECKED_OUT",
    "room": {
      "id": "room_302",
      "roomNumber": "302",
      "status": "CLEANING"
    }
  }
}
```

---

### 2.9. API / Trường Dữ Liệu Danh Sách Năm Báo Cáo Doanh Thu (Available Revenue Years)

*Phục vụ màn hình: Dropdown bộ lọc chọn năm trong Báo Cáo Doanh Thu & Hiệu Suất (`ReportsScreen` của ADMIN).*

- **Bối cảnh hiện tại:** Mobile App cần danh sách các năm khách sạn có phát sinh doanh thu / hóa đơn để người dùng có thể chọn xem biểu đồ doanh thu theo từng năm. Hiện tại API `GET /analytics/revenue?year=...` chỉ trả về dữ liệu của một năm được yêu cầu (`year`, `summary`, `monthly`) mà không kèm danh sách các năm có sẵn trong hệ thống.
- **Yêu cầu từ Mobile Team:** Backend hỗ trợ một trong hai phương án sau (ưu tiên Phương án 1 để tối ưu số lượng request):

#### Phương án 1 (Khuyến nghị - Gộp vào response `GET /analytics/revenue`):
Bổ sung trường `availableYears: number[]` trực tiếp vào object `data` của API `GET /analytics/revenue`:

```json
{
  "statusCode": 200,
  "success": true,
  "message": "Thành công",
  "data": {
    "year": 2026,
    "availableYears": [2024, 2025, 2026],
    "summary": {
      "totalYearRevenue": 52092000,
      "totalRoomRevenue": 46600000,
      "totalServicesRevenue": 3470000,
      "totalInvoices": 9
    },
    "monthly": [
      {
        "month": 1,
        "totalRevenue": 0,
        "roomRevenue": 0,
        "serviceRevenue": 0,
        "invoiceCount": 0
      }
    ]
  },
  "timestamp": "2026-09-05T06:51:14.990Z"
}
```

#### Phương án 2 (Cung cấp Endpoint độc lập):
Nếu BE muốn tách riêng danh mục các năm có dữ liệu:
- **Method:** `GET`
- **Endpoint:** `/analytics/revenue/years`
- **Quyền hạn:** `ADMIN`
- **Mô tả:** Trả về mảng các năm (số nguyên, sắp xếp tăng dần hoặc giảm dần) mà hệ thống có ghi nhận hóa đơn / đơn đặt phòng / doanh thu.

**Response 200 OK:**
```json
{
  "statusCode": 200,
  "success": true,
  "message": "Thành công",
  "data": [2024, 2025, 2026],
  "timestamp": "2026-09-05T06:51:14.990Z"
}
```

---

## 3. BẢNG MÃ LỖI (ERROR CODES) CHO BE

| HTTP Status | Error Code | Ý nghĩa |
| :--- | :--- | :--- |
| `400 Bad Request` | `ERR_INVALID_STATUS` | Đơn phòng không ở trạng thái hợp lệ để thực hiện hành động này. |
| `400 Bad Request` | `ERR_REASON_REQUIRED` | Bắt buộc phải cung cấp lý do khi từ chối đơn đặt phòng. |
| `404 Not Found` | `ERR_BOOKING_NOT_FOUND`| Không tìm thấy đơn đặt phòng với ID tương ứng. |
| `409 Conflict` | `ERR_ROOM_OCCUPIED` | Phòng đã có khách khác đang ở hoặc bị trùng lịch. |
| `403 Forbidden` | `ERR_FORBIDDEN_ROLE` | Vai trò người dùng không có quyền duyệt đơn hoặc thay đổi trạng thái. |

---

*Tài liệu này đã được đồng bộ với cấu trúc Model của ứng dụng di động Flutter Luxe Grand Hotel.*
