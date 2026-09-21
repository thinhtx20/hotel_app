# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS - SOFTWARE REQUIREMENTS SPECIFICATION)
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL
### TIÊU CHUẨN THIẾT KẾ: IEEE 830-1998

---

## BẢNG THEO DÕI THAY ĐỔI TÀI LIỆU (DOCUMENT REVISION HISTORY)

| Phiên bản | Ngày | Tác giả | Mô tả thay đổi |
| :--- | :--- | :--- | :--- |
| **1.0.0** | 04/09/2026 | BA & Tech Lead | Khởi tạo tài liệu đặc tả yêu cầu cho toàn hệ thống |
| **1.1.0** | 10/09/2026 | Solution Architect | Bổ sung đặc tả phân hệ Quản lý Ca trực (WorkShift) & Sổ thu tiền đa đợt (Payments) |
| **1.2.0** | 21/09/2026 | Project Manager | Hoàn thiện toàn diện đặc tả chức năng BE NestJS & FE Flutter, đồng bộ CSDL chuẩn 3NF |
| **2.0.0** | 21/09/2026 | Lead Architect | Bổ sung trọn vẹn 8 chức năng còn thiếu (FR-20 đến FR-27), nâng cấp Ma trận truy vết yêu cầu đạt 27 tính năng toàn diện |

---

## 1. GIỚI THIỆU (INTRODUCTION)

### 1.1. Mục đích tài liệu (Purpose)
Tài liệu Đặc tả Yêu cầu Phần mềm (SRS) này mô tả toàn diện và chi tiết các yêu cầu chức năng (Functional Requirements), yêu cầu phi chức năng (Non-functional Requirements), giao diện hệ thống và các ràng buộc nghiệp vụ cho hệ sinh thái phần mềm **Luxe Grand Hotel Management System**. Tài liệu là căn cứ pháp lý và kỹ thuật phục vụ:
- Đội ngũ phát triển Backend (NestJS) và Frontend (Flutter Mobile).
- Đội ngũ đảm bảo chất lượng (QA/QC) xây dựng Kịch bản kiểm thử (Test Plan & Test Cases).
- Giảng viên hướng dẫn và Hội đồng thẩm định đánh giá nghiệm thu đồ án tốt nghiệp.

### 1.2. Phạm vi sản phẩm (Product Scope)
Hệ thống **Luxe Grand Hotel** là giải pháp số hóa toàn diện quy trình quản trị và vận hành khách sạn tiêu chuẩn 4-5 sao, bao gồm:
1. **Dịch vụ Khách hàng số (Customer Digital Experience):** Cho phép khách tra cứu tình trạng phòng theo thời gian thực, đặt phòng trực tuyến, theo dõi tiến độ đơn, gọi dịch vụ phòng (minibar, ẩm thực, spa), quản lý hóa đơn và gửi yêu cầu thanh toán chuyển khoản ngân hàng.
2. **Nghiệp vụ Tiền sảnh & Buồng phòng (Front-Desk & Housekeeping Operations):** Trực quan hóa toàn bộ sơ đồ phòng thông qua Ma trận phòng (Room Matrix) theo tầng, tiếp nhận khách vãng lai (Walk-in), Check-in, Check-out, xử lý đổi phòng linh hoạt.
3. **Kỷ luật Tài chính & Quản lý Ca trực Thu ngân (Cashier & Shift Reconciliation):** Quản lý đóng/mở ca trực, bàn giao quỹ tiền mặt đầu ca, kiểm đếm tiền két thực tế, đối soát chênh lệch tự động, ghi nhận sổ thu tiền đa đợt (đặt cọc, trả từng phần, hoàn tiền).
4. **Trung tâm Điều hành & Báo cáo Quản trị (Executive Analytics Dashboard):** Thẻ chỉ số vận hành thời gian thực (KPI Cards), phân tích tỷ lệ lấp đầy phòng (Occupancy Rate) và biểu đồ doanh thu 12 tháng tương tác cao.

### 1.3. Định nghĩa, Từ viết tắt (Definitions and Acronyms)
- **PMS (Property Management System):** Hệ thống quản lý cơ sở lưu trú khách sạn.
- **Walk-in Guest:** Khách vãng lai đến thuê phòng trực tiếp tại quầy mà không đặt trước.
- **Room Matrix:** Ma trận phân bố phòng theo tầng và mã màu trạng thái thời gian thực.
- **Overbooking / Double-booking:** Sự cố trùng lịch khi cùng một phòng bị đặt bởi nhiều khách trong cùng khoảng thời gian.
- **RBAC (Role-Based Access Control):** Cơ chế kiểm soát truy cập dựa trên vai trò.
- **Shift Reconciliation:** Quy trình đối soát tiền mặt và doanh thu bàn giao ca trực.

---

## 2. TỔNG QUAN HỆ THỐNG (OVERALL DESCRIPTION)

### 2.1. Bối cảnh sản phẩm (Product Perspective)
Hệ thống được thiết kế theo mô hình kiến trúc phân tán Client - Server:
- **Tầng Client (Mobile):** Ứng dụng di động Flutter đa nền tảng (iOS, Android).
- **Tầng Server (Backend API):** NestJS RESTful API, triển khai trên nền tảng đám mây Render/Docker.
- **Tầng Dữ liệu & Tích hợp:** PostgreSQL (Database chính), Redis (Caching layer), Elasticsearch (Search Engine), Firebase Cloud Messaging (Push Notifications), SMTP Server (Email Service).

```mermaid
graph TD
    Client[Flutter Mobile App (iOS / Android)] -->|HTTPS / REST API / Bearer JWT| Server[NestJS Backend Application]
    Server --> PG[(PostgreSQL Database)]
    Server --> Redis[(Redis In-Memory Cache)]
    Server --> ES[(Elasticsearch Search Engine)]
    Server --> FCM[Firebase Cloud Messaging]
    Server --> SMTP[SMTP Mail Server]
```

### 2.2. Nhóm tác nhân người dùng (User Personas)

| Vai trò (Role) | Mô tả nhóm người dùng | Quyền hạn chính |
| :--- | :--- | :--- |
| **CUSTOMER (Khách hàng)** | Khách lưu trú, khách du lịch tải app trên kho ứng dụng | Tra cứu phòng, đặt phòng, xem đơn & hóa đơn cá nhân, gọi dịch vụ phòng, yêu cầu thanh toán chuyển khoản |
| **RECEPTIONIST (Lễ tân / Thu ngân)** | Nhân viên tiền sảnh, trực quầy lễ tân khách sạn | Mở/chốt ca trực, xem Room Matrix, duyệt/từ chối đơn, Check-in, Check-out, Đổi phòng, tiếp nhận Walk-in, duyệt chuyển khoản |
| **ADMIN (Quản trị viên / GM)** | Giám đốc điều hành, Trưởng bộ phận quản lý | Toàn quyền hệ thống: Xem Dashboard KPI, Báo cáo biểu đồ doanh thu, Quản lý danh mục phòng & bảng giá, Quản lý tài khoản nhân sự |

### 2.3. Môi trường vận hành (Operating Environment)
- **Thiết bị di động:** Hệ điều hành Android 8.0 (API 26) trở lên hoặc iOS 13.0 trở lên; màn hình cảm ứng độ phân giải từ HD trở lên; kết nối Internet (Wifi / 4G / 5G).
- **Máy chủ Backend:** Node.js v18+ LTS / v20+, hệ điều hành Linux (Ubuntu 22.04 LTS / Alpine Docker), RAM tối thiểu 2GB, CPU 2 Cores.
- **Cơ sở dữ liệu:** PostgreSQL 15+, Redis 7+, Elasticsearch 8.x+.

### 2.4. Các ràng buộc thiết kế & hiện thực (Design Constraints)
- **Ngôn ngữ & Framework:** Phía máy chủ bắt buộc sử dụng TypeScript với NestJS; phía ứng dụng bắt buộc sử dụng Dart với Flutter.
- **Chuẩn giao diện:** Tuân thủ Material 3 và phong cách thiết kế Luxury Hotel Palette (Navy `#1B365D`, Gold `#D4AF37`, Cream `#F8F9FA`).
- **Xác thực:** Bắt buộc áp dụng JSON Web Token (JWT) trong Authorization Header cho tất cả các API nghiệp vụ nội bộ.

---

## 3. YÊU CẦU CHỨC NĂNG CHI TIẾT (SYSTEM FEATURES)

### 3.1. Phân hệ 1: Xác thực & Quản lý Tài khoản (Authentication & Security)

#### [FR-01] Đăng ký tài khoản Khách hàng
- **Mô tả:** Cho phép người dùng mới tạo tài khoản khách hàng trên ứng dụng di động.
- **Đầu vào:** Email, Mật khẩu (tối thiểu 6 ký tự), Họ tên, Số điện thoại.
- **Xử lý:** Kiểm tra email duy nhất (`unique`), băm mật khẩu bằng thuật toán Bcrypt với Salt round = 10, gán mặc định quyền `Role = CUSTOMER`.
- **Đầu ra:** Tạo bản ghi `User`, trả về thông báo đăng ký thành công kèm mã HTTP 201 Created.

#### [FR-02] Đăng nhập & Cấp phát Token
- **Mô tả:** Xác thực danh tính người dùng và cấp quyền truy cập các tính năng tương ứng.
- **Đầu vào:** Email, Mật khẩu.
- **Xử lý:** Kiểm tra đối sánh mật khẩu băm, nếu khớp sẽ tạo JWT Access Token chứa payload: `{ sub: userId, email, role }` với hạn sử dụng xác định (ví dụ: 7 ngày).
- **Đầu ra:** Mã HTTP 200 OK kèm Access Token, Role và thông tin cá nhân.

#### [FR-03] Khôi phục Mật khẩu qua Email OTP
- **Mô tả:** Cho phép người dùng đặt lại mật khẩu khi bị quên mà không cần can thiệp thủ công từ admin.
- **Xử lý:**
  1. Khách nhập email -> Backend tạo mã OTP ngẫu nhiên 6 chữ số có hiệu lực trong 10 phút, lưu vào bảng `password_resets`.
  2. Gửi mã OTP qua dịch vụ Nodemailer tới hòm thư của khách.
  3. Khách nhập OTP và mật khẩu mới -> Backend kiểm tra tính hợp lệ -> Cập nhật mật khẩu mới -> Đánh dấu OTP đã sử dụng (`used = true`).

---

### 3.2. Phân hệ 2: Quản lý Phòng & Ma trận Phòng (Rooms & Room Matrix)

#### [FR-04] Quản lý Danh mục Hạng phòng (Room Types)
- **Quyền hạn:** `ADMIN`.
- **Chức năng:** Thêm, sửa, xóa các hạng phòng (Standard, Superior, Deluxe, Suite, Penthouse).
- **Thuộc tính:** Tên hạng, mô tả chi tiết, đơn giá cơ bản một đêm (`basePrice`), sức chứa tối đa (`maxOccupancy`), mảng tiện nghi (`amenities`), mảng ảnh (`images`).

#### [FR-05] Quản lý Phòng vật lý (Physical Rooms)
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`.
- **Chức năng:** Khởi tạo danh sách phòng theo số phòng (`roomNumber`), vị trí tầng (`floor`), liên kết hạng phòng (`roomTypeId`) và trạng thái ban đầu (`status = AVAILABLE`).

#### [FR-06] Ma trận Sơ đồ phòng thời gian thực (Room Matrix)
- **Quyền hạn:** `ADMIN`, `RECEPTIONIST`.
- **Mô tả:** Màn hình trực quan chia theo các tầng (Tầng 1, Tầng 2...). Mỗi phòng là một thẻ hiển thị thông tin: Số phòng, Hạng phòng, Đơn giá và màu sắc biểu thị trạng thái:
  + **Xanh lá (`AVAILABLE`):** Phòng trống sạch sẽ, sẵn sàng đón khách.
  + **Đỏ (`OCCUPIED`):** Phòng đang có khách lưu trú, hiển thị tên khách và ngày trả phòng.
  + **Xanh dương (`RESERVED`):** Phòng đã được khách đặt trước và đã được duyệt.
  + **Vàng cam (`CLEANING`):** Phòng khách vừa trả, đang chờ buồng phòng dọn dẹp.
  + **Xám (`MAINTENANCE`):** Phòng hỏng hóc thiết bị, đang bảo trì.
- **Thao tác nhanh:** Chạm vào thẻ phòng để hiển thị menu tương ứng: *Xem chi tiết, Nhận phòng Walk-in, Check-out, Đổi phòng, Chuyển trạng thái dọn dẹp*.

---

### 3.3. Phân hệ 3: Nghiệp vụ Đặt phòng & Lưu trú (Bookings Lifecycle)

#### [FR-07] Tra cứu phòng trống (Available Rooms Search)
- **Tác nhân:** `CUSTOMER`, `RECEPTIONIST`.
- **Đầu vào:** Ngày nhận phòng (`checkInDate`), Ngày trả phòng (`checkOutDate`), Số lượng khách (`guestCount`), Loại phòng (tùy chọn).
- **Thuật toán chống trùng lịch:** Loại trừ tất cả các phòng có đơn đặt ở trạng thái `CONFIRMED` hoặc `CHECKED_IN` giao nhau với khoảng thời gian tìm kiếm:
  $$\text{Overlap} \iff (\text{checkInDate} < \text{booking.checkOutDate}) \land (\text{checkOutDate} > \text{booking.checkInDate})$$
- **Đầu ra:** Danh sách các phòng hoàn toàn trống lịch trong toàn bộ khoảng thời gian yêu cầu.

#### [FR-08] Tạo đơn đặt phòng trực tuyến (Online Booking)
- **Tác nhân:** `CUSTOMER`.
- **Đầu vào:** `roomId`, `checkInDate`, `checkOutDate`, `guestCount`, `specialRequests`.
- **Xử lý:** Kiểm tra lại tính hợp lệ phòng trống -> Tạo bản ghi `Booking` với `status = PENDING` -> Tự động khởi tạo bản ghi `Invoice` tương ứng với `paymentStatus = UNPAID`.
- **Đầu ra:** Mã đơn đặt phòng (ví dụ `BK-2026-102`), thông báo gửi yêu cầu thành công.

#### [FR-09] Phê duyệt & Từ chối đơn đặt phòng
- **Tác nhân:** `ADMIN`, `RECEPTIONIST`.
- **Duyệt đơn (`PUT /bookings/{id}/approve`):** Cập nhật `booking.status = CONFIRMED`, `room.status = RESERVED`, lưu vết `confirmedById` và `confirmedAt`. Gửi thông báo đẩy FCM tới điện thoại khách thông báo đơn đã được duyệt.
- **Từ chối đơn (`PUT /bookings/{id}/reject`):** Bắt buộc nhập lý do từ chối (`cancellationReason`). Cập nhật `booking.status = CANCELLED`, lưu vết `cancelledById`. Gửi thông báo giải thích cho khách.

#### [FR-10] Thủ tục Nhận phòng (Check-in) & Khách vãng lai (Walk-in)
- **Tác nhân:** `RECEPTIONIST`.
- **Check-in đơn có sẵn:** Lễ tân kiểm tra CCCD/Hộ chiếu của khách -> Bấm Check-in -> Cập nhật `actualCheckIn = now()`, `booking.status = CHECKED_IN`, `room.status = OCCUPIED`.
- **Walk-in Check-in:** Dành cho khách đến quầy chưa đặt trước -> Lễ tân chọn phòng trống trên Room Matrix -> Nhập thông tin khách, số đêm -> Hệ thống tạo ngay Booking và Invoice ở trạng thái `CHECKED_IN` và `OCCUPIED`.

#### [FR-11] Đổi phòng lưu trú (Change Room)
- **Tác nhân:** `RECEPTIONIST`.
- **Nghiệp vụ:** Khách đang lưu trú gặp sự cố phòng (máy lạnh hỏng, yêu cầu nâng hạng) -> Lễ tân chọn phòng mới trống tương ứng -> Hệ thống hoán đổi:
  + Chuyển phòng cũ sang trạng thái `CLEANING`.
  + Gán `booking.roomId` sang phòng mới.
  + Chuyển phòng mới sang trạng thái `OCCUPIED`.
  + Tự động tính toán lại tiền chênh lệch phòng (nếu khác hạng giá) vào hóa đơn.

#### [FR-12] Thủ tục Trả phòng (Check-out) & Kiểm kê Dịch vụ
- **Tác nhân:** `RECEPTIONIST`, `CASHIER`.
- **Xử lý:**
  1. Kiểm tra các dịch vụ minibar, đồ uống phát sinh -> Ghi nhận vào hóa đơn.
  2. Hệ thống kiểm tra số dư còn thiếu: `remainingAmount = finalAmount - paidAmount`.
  3. Nếu `remainingAmount > 0`: Yêu cầu thu đủ tiền trước khi hoàn tất.
  4. Cập nhật `actualCheckOut = now()`, `booking.status = CHECKED_OUT`, `room.status = CLEANING`.

---

### 3.4. Phân hệ 4: Quản lý Dịch vụ Phòng (Hotel Extra Services)

#### [FR-13] Danh mục Dịch vụ khách sạn
- Quản lý các nhóm dịch vụ: Ẩm thực (F&B), Đồ uống minibar, Giặt là nhanh, Spa & Massage, Thuê xe đưa đón sân bay.
- Mỗi dịch vụ có mã (`code`), tên (`name`), đơn vị tính (`unit`), đơn giá (`unitPrice`) và trạng thái khả dụng (`isAvailable`).

#### [FR-14] Đặt dịch vụ gia tăng theo phòng
- Khách hàng đang ở (hoặc lễ tân trực quầy) có thể order dịch vụ trực tiếp vào phòng đang lưu trú.
- Hệ thống tạo bản ghi `ExtraServiceOrder` liên kết với `bookingId`.
- Tiền dịch vụ được tự động cộng dồn vào trường `servicesAmount` của hóa đơn `Invoice`.

---

### 3.5. Phân hệ 5: Tài chính, Hóa đơn & Quản lý Ca trực (Cashier & Shifts)

#### [FR-15] Cấu trúc Sổ thu tiền đa đợt (Multi-Entry Payments)
- Giải quyết triệt để bài toán khách đặt cọc trước, thanh toán từng đợt và phát sinh tiền minibar lúc về:
  + Mỗi hóa đơn gồm một hoặc nhiều bản ghi `Payment`.
  + Phân loại giao dịch (`type`): `PAYMENT` (Thanh toán), `DEPOSIT` (Đặt cọc), `REFUND` (Hoàn trả tiền thừa).
  + Vòng đời trạng thái khoản thu:
    * `PENDING`: Khách thao tác chuyển khoản trên App và nhập mã giao dịch ngân hàng. Tiền chưa vào tài khoản/két, CHƯA được cộng vào tiền thực thu của hóa đơn.
    * `CONFIRMED`: Thu ngân kiểm tra sao kê/két tiền, xác nhận đã nhận đủ -> Hệ thống chính thức cộng vào `Invoice.paidAmount`.
    * `REJECTED`: Thu ngân không tìm thấy tiền, từ chối giao dịch kèm lý do.
  + Công thức tính tiền tự động:
    $$\text{paidAmount} = \sum \text{amount of CONFIRMED payments}$$
    $$\text{remainingAmount} = \text{finalAmount} - \text{paidAmount}$$

#### [FR-16] Quản lý Ca trực Lễ tân (WorkShift Management)
- **Mở ca (Open Shift):** Nhân viên lễ tân đăng nhập quầy -> Bấm "Mở ca trực" -> Khai báo loại ca (Sáng/Chiều/Đêm), tên quầy và số tiền mặt bàn giao trong két đầu ca (`initialCash`).
- **Ghi nhận giao dịch trong ca:** Toàn bộ các khoản thu tiền mặt (`CASH`), quẹt thẻ (`CREDIT_CARD`), chuyển khoản (`BANK_TRANSFER`) do nhân viên thực hiện trong ca đều tự động được gắn mã `shiftId`.
- **Chốt ca (Close Shift):**
  1. Nhân viên kiểm đếm tiền mặt thực tế trong két và nhập `actualCash`.
  2. Hệ thống tính toán tiền mặt lý thuyết:
     $$\text{expectedCash} = \text{initialCash} + \sum \text{Tiền mặt CONFIRMED trong ca}$$
  3. Hệ thống tính chênh lệch:
     $$\text{cashDifference} = \text{actualCash} - \text{expectedCash}$$
  4. **Ràng buộc kỷ luật tài chính:** Nếu `cashDifference \neq 0`, hệ thống bắt buộc nhân viên phải nhập lý do giải trình (`differenceReason`) mới cho phép chốt ca.
  5. Ca trực chuyển sang `status = CLOSED`, bàn giao mã ca cho nhân viên ca sau (`handoverStaffId`).

---

### 3.6. Phân hệ 6: Báo cáo Thống kê & Tự động hóa (Analytics & Automation)

#### [FR-17] Dashboard Điều hành thời gian thực
- Cung cấp 4 thẻ chỉ số KPI quan trọng cho ban quản lý:
  + Tỷ lệ lấp đầy phòng hôm nay (`Occupancy Rate %`).
  + Số lượt khách dự kiến và đã hoàn tất Check-in hôm nay.
  + Số lượt khách dự kiến và đã hoàn tất Check-out hôm nay.
  + Số đơn đặt phòng trực tuyến mới đang chờ phê duyệt.

#### [FR-18] Báo cáo Doanh thu 12 tháng & Cơ cấu Doanh thu
- Trực quan hóa doanh thu theo từng tháng bằng biểu đồ cột tương tác (FL Chart).
- Phân tách rõ ràng cơ cấu: Doanh thu tiền phòng (`roomRevenue`) và Doanh thu dịch vụ gia tăng (`serviceRevenue`).
- Hỗ trợ bộ lọc xem số liệu linh hoạt theo từng năm vận hành.

#### [FR-19] Tác vụ Nhắc lịch Check-in tự động (Cron Schedule)
- Cronjob chạy tự động lúc 09:00 sáng mỗi ngày trên server Backend.
- Tự động lọc tất cả các đơn đặt phòng có lịch Check-in trong ngày hiện tại.
- Kích hoạt gửi Push Notification qua FCM và gửi Email chào đón, thông báo giờ nhận phòng chuẩn và hướng dẫn đường đi tới khách sạn.

---

### 3.7. Phân hệ 7: Quản lý Nhân sự & Phân quyền Vai trò (Staff & User Management - RBAC)

#### [FR-20] Quản lý Tài khoản Nhân viên & Phân quyền Hệ thống
- **Tác nhân:** `ADMIN`.
- **Mô tả:** Cung cấp trung tâm quản trị toàn diện danh sách nhân sự khách sạn (Lễ tân, Thu ngân, Quản lý) và khách hàng.
- **Xử lý:**
  1. **Khởi tạo nhân sự mới (`POST /users`):** Admin khai báo họ tên, email, số điện thoại, mật khẩu khởi tạo và vai trò (`role`: `RECEPTIONIST`, `ADMIN`). Hệ thống mã hóa mật khẩu bằng Bcrypt và kích hoạt tài khoản.
  2. **Phân quyền và Cập nhật trạng thái (`PATCH /users/{id}`):** Admin có thể thăng cấp/hạ cấp vai trò, hoặc thực hiện khóa tài khoản (`isActive = false`) / mở khóa tài khoản tức thì.
  3. **Đặt lại mật khẩu nhân sự (`PATCH /users/{id}/password`):** Admin có thẩm quyền cấp lại mật khẩu mới cho nhân viên trong trường hợp quên hoặc có yêu cầu bảo mật đột xuất mà không cần qua email OTP.
  4. **Cập nhật dữ liệu thời gian thực:** Kết nối Server-Sent Events (`GET /users/stream`) tự động đẩy biến động nhân sự xuống màn hình Admin mà không cần tải lại trang.

---

### 3.8. Phân hệ 8: Quản lý Hồ sơ Cá nhân & Bảo mật (Profile & Security)

#### [FR-21] Quản lý Thông tin Cá nhân & Đổi Mật khẩu
- **Tác nhân:** Mọi người dùng đã xác thực (`CUSTOMER`, `RECEPTIONIST`, `ADMIN`).
- **Mô tả:** Cho phép người dùng chủ động quản lý thông tin nhận diện cá nhân và duy trì an toàn tài khoản.
- **Xử lý:**
  1. **Xem thông tin chi tiết (`GET /auth/me`):** Trích xuất thông tin người dùng từ JWT Token kèm trạng thái hoạt động và vai trò.
  2. **Cập nhật hồ sơ (`PATCH /users/me`):** Chỉnh sửa họ tên, số điện thoại liên lạc.
  3. **Cập nhật ảnh đại diện (`POST /upload/avatar`):** Tải lên ảnh chân dung, tự động nén định dạng WebP/JPEG, lưu trữ đám mây Cloudinary và đồng bộ trường `avatarUrl`.
  4. **Đổi mật khẩu trực tiếp (`POST /auth/change-password`):** Yêu cầu nhập mật khẩu hiện tại (`oldPassword`), mật khẩu mới (`newPassword`) tối thiểu 6 ký tự; hệ thống đối soát mật khẩu cũ trước khi băm và lưu mật khẩu mới.

---

### 3.9. Phân hệ 9: Trung tâm Thông báo Đa kênh (Notification Center & Messaging)

#### [FR-22] Hộp thư Thông báo & Quản lý Thiết bị Nhận tin
- **Tác nhân:** Mọi người dùng (`CUSTOMER`, `RECEPTIONIST`, `ADMIN`).
- **Mô tả:** Hệ thống lưu trữ và quản lý tập trung toàn bộ các thông báo quan trọng phát sinh trong quá trình vận hành (duyệt đơn, check-in, hủy phòng, bàn giao ca, nhắc lịch).
- **Xử lý:**
  1. **Hộp thư thông báo (`GET /notifications`):** Hiển thị danh sách thông báo phân loại theo biểu tượng và nhãn thời gian, lọc trạng thái đã đọc / chưa đọc.
  2. **Đánh dấu trạng thái đã đọc:** Hỗ trợ đọc từng thông báo (`PATCH /notifications/{id}/read`) hoặc đánh dấu đọc toàn bộ (`PATCH /notifications/read-all`).
  3. **Đăng ký thiết bị nhận tin (`PATCH /users/fcm-token`):** Ứng dụng di động tự động lấy FCM Registration Token từ Google Firebase và đồng bộ lên Backend để sẵn sàng nhận Push Notification khi ứng dụng chạy ngầm (Background) hoặc tắt hoàn toàn (Terminated).
  4. **Cấu hình tùy chọn thông báo:** Cho phép người dùng bật/tắt nhận tin qua Email, Push Notification hoặc Thông báo khuyến mại.

---

### 3.10. Phân hệ 10: Phân tích Hiệu suất & Doanh thu Chu kỳ Ngắn hạn (Advanced Analytics)

#### [FR-23] Báo cáo Hiệu suất Nhân sự & Doanh thu theo Ngày
- **Tác nhân:** `ADMIN`, `RECEPTIONIST`.
- **Mô tả:** Mở rộng năng lực phân tích tài chính và giám sát năng suất lao động của đội ngũ tiền sảnh.
- **Xử lý:**
  1. **Hiệu suất phục vụ nhân viên (`GET /analytics/staff-performance`):** Thống kê theo từng nhân viên lễ tân: Tổng số lượt Check-in đã thực hiện, Tổng số lượt Check-out đã xử lý, Doanh số tiền mặt & chuyển khoản thu ngân ghi nhận trong ca.
  2. **Doanh thu ngắn hạn theo ngày (`GET /analytics/revenue/daily?range=7|14|30`):** Cung cấp chuỗi số liệu doanh thu từng ngày trong 7 ngày, 14 ngày hoặc 30 ngày gần nhất, phục vụ vẽ biểu đồ xu hướng doanh thu ngắn hạn và so sánh giữa các tuần.

---

### 3.11. Phân hệ 11: Xem trước Hóa đơn Trả phòng & Bảng kê Chi phí (Checkout Preview & Settlement)

#### [FR-24] Xem trước Bảng kê Quyết toán Chi phí (Checkout Preview)
- **Tác nhân:** `RECEPTIONIST`, `CASHIER`, `ADMIN`.
- **Mô tả:** Cung cấp giao diện trích xuất dữ liệu chỉ đọc (Read-only Preview) hiển thị toàn bộ bảng kê chi phí trước khi bấm nút xác nhận Check-out chính thức.
- **Xử lý (`GET /bookings/{id}/checkout-preview`):**
  1. Tính toán số đêm lưu trú thực tế và tiền phòng tương ứng.
  2. Tổng hợp toàn bộ các đơn dịch vụ minibar, đồ uống, giặt là, spa đã gọi vào phòng.
  3. Phụ thu trả phòng muộn (nếu vượt quá khung giờ quy định 12:00 trưa).
  4. Liệt kê toàn bộ các khoản đã đặt cọc hoặc đã thanh toán trước (`paidAmount`).
  5. Tính toán chính xác số dư còn thiếu (`amountDue = finalAmount - paidAmount`). Không làm thay đổi trạng thái đơn hoặc phòng, đảm bảo tính minh bạch trước khi thu tiền dứt điểm.

---

### 3.12. Phân hệ 12: Quản lý Lịch sử Ca trực & Cưỡng chế Chốt ca (Shift Audit History & Force Close)

#### [FR-25] Sổ Lịch sử Ca trực & Quyền Quản trị Ca Khẩn cấp
- **Tác nhân:** `ADMIN`, `RECEPTIONIST`.
- **Mô tả:** Lưu trữ toàn bộ biên bản bàn giao ca trực phục vụ công tác thanh tra tài chính nội bộ.
- **Xử lý:**
  1. **Tra cứu lịch sử ca trực (`GET /shifts`):** Hỗ trợ lọc theo ngày, theo nhân viên trực, theo quầy và theo trạng thái (`OPEN`, `CLOSED`).
  2. **Xem chi tiết ca trực (`GET /shifts/{id}`):** Hiển thị toàn bộ thông số quỹ: Tiền mặt đầu ca, Tiền mặt thực tế, Tiền lý thuyết, Chênh lệch tiền két, Lý do giải trình kèm **danh sách toàn bộ các giao dịch thanh toán (Cash, Card, Transfer) phát sinh trong suốt thời gian diễn ra ca trực**.
  3. **Admin Cưỡng chế Chốt ca (`POST /shifts/{id}/close`):** Dành riêng cho `ADMIN` xử lý trường hợp nhân viên ca trước quên chốt ca, bỏ ca hoặc sự cố đột xuất để giải phóng quầy cho nhân viên ca sau mở ca làm việc bình thường.

---

### 3.13. Phân hệ 13: Quy trình Từ chối Thanh toán Nghi vấn (Payment Rejection)

#### [FR-26] Từ chối Giao dịch Chuyển khoản Không hợp lệ
- **Tác nhân:** `RECEPTIONIST`, `CASHIER`, `ADMIN`.
- **Mô tả:** Xử lý các yêu cầu thanh toán chuyển khoản do khách gửi lên từ ứng dụng nhưng sao kê ngân hàng không ghi nhận tiền hoặc mã giao dịch giả mạo.
- **Xử lý (`POST /invoices/payments/{paymentId}/reject`):**
  1. Thu ngân kiểm tra sao kê, nếu tiền chưa vào hoặc phát hiện sai lệch, bấm nút **"Từ chối"**.
  2. Bắt buộc nhập lý do từ chối cụ thể (ví dụ: *Chưa nhận được tiền vào tài khoản Techcombank*, *Sai mã tham chiếu*).
  3. Khoản thu chuyển sang trạng thái `REJECTED`, tuyệt đối KHÔNG cộng dồn vào `paidAmount` của hóa đơn.
  4. Hệ thống phát thông báo giải thích đến màn hình khách hàng để thực hiện chuyển khoản lại.

---

### 3.14. Phân hệ 14: Tự động Đồng bộ Trạng thái & Tải lên Tệp tin (System Maintenance & Media Upload)

#### [FR-27] Tự động Đồng bộ Trạng thái Phòng & Upload Đa phương tiện
- **Tác nhân:** `SYSTEM`, `ADMIN`, `RECEPTIONIST`.
- **Xử lý:**
  1. **Rà soát & Đồng bộ Trạng thái Phòng (`POST /rooms/sync-status`):** Hệ thống quét toàn bộ cơ sở dữ liệu để đối soát trạng thái phòng vật lý với các lịch đặt hiện hành; tự động chuyển các phòng khách đã rời đi sang `CLEANING` hoặc phòng đến hạn nhận sang `RESERVED`/`OCCUPIED` nếu phát sinh sai lệch logic.
  2. **Dịch vụ Tải ảnh Đa năng (`POST /upload/*`):** Upload ảnh đơn (`/upload/image`), ảnh album (`/upload/rooms`, `/upload/images`), kiểm định dung lượng tối đa 10MB, hỗ trợ định dạng JPG, PNG, WEBP và tích hợp lưu trữ an toàn trên máy chủ / Cloudinary.

---

## 4. YÊU CẦU PHI CHỨC NĂNG (NON-FUNCTIONAL REQUIREMENTS)

### 4.1. Hiệu năng & Khả năng đáp ứng (Performance Requirements)
- **API Latency:** Thời gian phản hồi trung bình của 95% các API truy vấn (GET) đạt dưới 150ms; các API ghi dữ liệu (POST/PUT) đạt dưới 250ms trong điều kiện mạng bình thường.
- **Throughput:** Máy chủ chịu tải tối thiểu 1.200 requests/phút mà không bị tràn bộ nhớ hoặc rớt kết nối.
- **Client Performance:** Ứng dụng Flutter đạt tốc độ khung hình 60fps mượt mà, thời gian cold-start dưới 2 giây.

### 4.2. An toàn & Bảo mật (Security Requirements)
- Mọi mật khẩu người dùng phải được băm một chiều bằng thuật toán `Bcrypt` (muối tối thiểu 10 vòng lặp).
- Mọi giao tiếp mạng giữa Mobile Client và Backend bắt buộc mã hóa qua giao thức HTTPS (TLS 1.3).
- Triển khai xác thực JWT Bearer Token, thời gian hết hạn hợp lý và cơ chế kiểm soát phân quyền chặt chẽ bằng Role Guards.
- 100% câu truy vấn cơ sở dữ liệu phải sử dụng cơ chế Parameterized Queries qua Prisma ORM để loại trừ hoàn toàn nguy cơ SQL Injection.

### 4.3. Tính sẵn sàng & Toàn vẹn dữ liệu (Availability & Data Integrity)
- Hệ thống duy trì tính sẵn sàng (Availability) tối thiểu 99.5%.
- Cơ chế giao dịch cơ sở dữ liệu (Database Transactions) áp dụng mức cô lập thích hợp để ngăn chặn hoàn toàn hiện tượng tranh chấp đặt phòng (Race conditions) và sai lệch số dư tiền két.

### 4.4. Tính khả dụng & Trải nghiệm người dùng (Usability)
- Giao diện trực quan, ngôn ngữ hiển thị tiếng Việt chuẩn mực, thông báo lỗi thân thiện và dễ hiểu.
- Các quy trình cốt lõi của lễ tân (Check-in, Check-out, Mở/Chốt ca) được tối ưu hóa với số lần chạm màn hình tối thiểu (không quá 3 thao tác chạm).

---

## 5. BẢNG MA TRẬN TRUY VẾT YÊU CẦU TOÀN DIỆN (FULL TRACEABILITY MATRIX)

| Mã YC | Tên yêu cầu chức năng | Phân hệ | Vai trò | API Endpoint liên quan | Bảng dữ liệu chính |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FR-01** | Đăng ký tài khoản | Auth | Customer | `POST /auth/register` | `users` |
| **FR-02** | Đăng nhập hệ thống | Auth | All | `POST /auth/login` | `users` |
| **FR-03** | Quên mật khẩu OTP | Auth | Customer | `POST /auth/forgot-password` | `password_resets` |
| **FR-04** | Quản lý Hạng phòng | Catalog | Admin | `GET,POST,PATCH,DELETE /room-types` | `room_types` |
| **FR-05** | Quản lý Phòng vật lý | Catalog | Admin/Staff | `GET,POST,PATCH,DELETE /rooms` | `rooms` |
| **FR-06** | Ma trận phòng Room Matrix | Front-desk | Staff/Admin | `GET /rooms`, `GET /rooms/matrix` | `rooms`, `bookings` |
| **FR-07** | Tìm kiếm phòng trống | Booking | Customer | `GET /rooms/available` | `rooms`, `bookings` |
| **FR-08** | Tạo đơn đặt phòng | Booking | Customer | `POST /bookings` | `bookings`, `invoices` |
| **FR-09** | Phê duyệt / Từ chối đơn | Booking | Staff/Admin | `PUT,POST /bookings/{id}/approve`, `/reject` | `bookings`, `rooms` |
| **FR-10** | Check-in & Walk-in | Front-desk | Staff/Admin | `POST /bookings/{id}/check-in` | `bookings`, `rooms` |
| **FR-11** | Đổi phòng lưu trú | Front-desk | Staff/Admin | `POST /bookings/{id}/change-room` | `bookings`, `rooms` |
| **FR-12** | Check-out trả phòng | Front-desk | Staff/Admin | `POST /bookings/{id}/check-out` | `bookings`, `invoices` |
| **FR-13** | Quản lý Dịch vụ KS | Catalog | Admin | `GET,POST,PATCH,DELETE /services` | `hotel_services` |
| **FR-14** | Gọi dịch vụ phòng | Services | Customer/Staff | `POST /bookings/{id}/services` | `extra_service_orders` |
| **FR-15** | Sổ thu tiền đa đợt | Cashier | Customer/Staff | `POST /invoices/{id}/pay`, `/payments` | `invoices`, `payments` |
| **FR-16** | Quản lý Ca trực lễ tân | Cashier | Receptionist | `POST /shifts/open`, `/close` | `work_shifts`, `payments` |
| **FR-17** | Dashboard điều hành | Analytics | Admin | `GET /analytics/dashboard` | `rooms`, `bookings` |
| **FR-18** | Báo cáo doanh thu 12 tháng | Analytics | Admin | `GET /analytics/revenue` | `invoices`, `payments` |
| **FR-19** | Nhắc lịch Check-in | Notification | System | Cron `@EveryDayAt9AM` | `bookings`, `users` |
| **FR-20** | Quản trị Nhân sự & Phân quyền | Staff | Admin | `GET,POST,PATCH,DELETE /users`, `/users/stream` | `users` |
| **FR-21** | Hồ sơ Cá nhân & Đổi Mật khẩu | Security | All | `GET /auth/me`, `PATCH /users/me`, `POST /auth/change-password` | `users` |
| **FR-22** | Trung tâm Thông báo FCM | Notification | All | `GET /notifications`, `PATCH /read`, `PATCH /users/fcm-token` | `notifications`, `users` |
| **FR-23** | Hiệu suất Nhân viên & Doanh thu Ngày | Analytics | Admin/Staff | `GET /analytics/staff-performance`, `/revenue/daily` | `work_shifts`, `invoices` |
| **FR-24** | Xem trước Hóa đơn Check-out | Front-desk | Staff/Admin | `GET /bookings/{id}/checkout-preview` | `bookings`, `invoices` |
| **FR-25** | Lịch sử Ca & Cưỡng chế Chốt ca | Cashier | Admin/Staff | `GET /shifts`, `GET /shifts/{id}`, `POST /shifts/{id}/close` | `work_shifts`, `payments` |
| **FR-26** | Từ chối Yêu cầu Chuyển khoản | Cashier | Staff/Admin | `POST /invoices/payments/{paymentId}/reject` | `payments`, `invoices` |
| **FR-27** | Đồng bộ Trạng thái & Tải File | System/Media | Admin/Staff | `POST /rooms/sync-status`, `POST /upload/*` | `rooms`, `upload` |
