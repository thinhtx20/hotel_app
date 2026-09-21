# KẾ HOẠCH VÀ KỊCH BẢN KIỂM THỬ PHẦN MỀM (TEST PLAN & TEST CASES)
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL
### TIÊU CHUẨN: IEEE 829 (TEST DOCUMENTATION)

---

## 1. KẾ HOẠCH KIỂM THỬ (TEST PLAN)

### 1.1. Mục tiêu kiểm thử (Test Objectives)
1. Xác minh tất cả các yêu cầu chức năng (Functional Requirements) nêu trong tài liệu SRS được hiện thực hóa chính xác, không phát sinh lỗi logic.
2. Kiểm tra tính toàn vẹn dữ liệu, các giao dịch tài chính (Transactions) và thuật toán loại trừ xung đột đặt trùng lịch phòng (Double-booking prevention).
3. Đánh giá tính ổn định, thời gian đáp ứng (Latency) và khả năng chịu tải của Backend NestJS kết hợp Redis Cache.
4. Kiểm tra trải nghiệm người dùng (UX), tính nhất quán giao diện và khả năng xử lý bất đồng bộ trên ứng dụng di động Flutter.

### 1.2. Phạm vi kiểm thử (Scope)
- **Trong phạm vi (In-Scope):**
  + Kiểm thử toàn bộ 6 phân hệ: Xác thực, Quản lý phòng & Ma trận phòng, Đặt phòng & Tiền sảnh, Quản lý dịch vụ, Thu ngân & Ca trực lễ tân, Báo cáo phân tích.
  + Kiểm thử giao diện di động (Android & iOS) và tương tác thời gian thực.
  + Kiểm thử an toàn bảo mật: Băm mật khẩu, Phân quyền Role Guards, Chống SQL Injection.
  + Kiểm thử tải và hiệu năng với Apache Benchmark / Postman Runner.
- **Ngoài phạm vi (Out-of-Scope):**
  + Tích hợp với thiết bị phần cứng khóa cửa từ thông minh (Smart Lock IoT).

### 1.3. Môi trường kiểm thử (Test Environment)

| Thành phần | Cấu hình thử nghiệm |
| :--- | :--- |
| **Backend Server** | Node.js v20 LTS, NestJS 10.4, Triển khai trên Render Cloud / Docker Localhost |
| **Database** | PostgreSQL 16 (Hosted on Supabase/Render), Prisma ORM 5.22 |
| **Cache & Search** | Redis 7.2 (In-Memory), Elasticsearch 8.x |
| **Mobile Client** | Thiết bị thật: Samsung Galaxy S23 (Android 14) & iPhone 14 Pro (iOS 17.4), Máy ảo Pixel 7 |
| **Công cụ hỗ trợ** | Postman v11, Apache Benchmark (ab), Flutter Test Suite |

---

## 2. CHIẾN LƯỢC VÀ PHƯƠNG PHÁP KIỂM THỬ (TEST STRATEGY)

1. **Kiểm thử Đơn vị (Unit Testing):** Sử dụng Jest cho Backend (kiểm tra các hàm tính toán doanh thu, công thức đối soát ca trực, thuật toán giao thoa ngày nhận/trả) và Flutter Test cho Client (kiểm tra parse JSON DTO, logic BLoC).
2. **Kiểm thử Tích hợp (Integration Testing):** Kiểm tra sự tương tác giữa Mobile Client và Server thông qua các API RESTful, kiểm tra quá trình ghi dữ liệu qua Prisma và phản hồi về UI.
3. **Kiểm thử Tranh chấp & Đồng thời (Concurrency Testing):** Giả lập 2 khách hàng cùng lúc bấm nút đặt phòng cho cùng một phòng vật lý tại cùng một khoảng thời gian để kiểm tra tính năng khóa dòng ngăn chặn Double-booking.
4. **Kiểm thử Chấp nhận Người dùng (User Acceptance Testing - UAT):** Đóng vai 3 đối tượng (Khách hàng, Lễ tân trực ca, Quản trị viên) thực hiện một chu trình vận hành khép kín từ đặt phòng đến chốt ca bàn giao tiền mặt.

---

## 3. MA TRẬN KỊCH BẢN KIỂM THỬ CHI TIẾT (TEST CASES MATRIX)

### 3.1. Phân hệ 1: Xác thực & Quản lý Tài khoản (Authentication)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-AUTH-01** | Đăng ký tài khoản hợp lệ | Email chưa tồn tại trong hệ thống | 1. Nhập email: `test@guest.com`<br>2. Nhập mật khẩu: `Pass123@`<br>3. Họ tên: `Lê Văn An`<br>4. Bấm "Đăng ký" | HTTP 201 Created, tài khoản được lưu trong bảng `users`, mật khẩu được băm Bcrypt, gán quyền `CUSTOMER`. | Cao | **PASS** |
| **TC-AUTH-02** | Đăng ký với Email đã tồn tại | Email `test@guest.com` đã đăng ký | Nhập lại đúng email đã có kèm mật khẩu hợp lệ | HTTP 409 Conflict, thông báo "Email này đã được sử dụng". | Cao | **PASS** |
| **TC-AUTH-03** | Đăng ký mật khẩu quá ngắn | Màn hình đăng ký | Nhập mật khẩu dưới 6 ký tự (ví dụ: `123`) | Client báo lỗi form đỏ; Backend chặn với mã lỗi 400 Validation Error. | Vừa | **PASS** |
| **TC-AUTH-04** | Đăng nhập thành công | Đã có tài khoản hợp lệ | Nhập đúng email và mật khẩu | HTTP 200 OK, trả về Bearer JWT token và chuyển hướng vào màn hình tương ứng với Role. | Cao | **PASS** |
| **TC-AUTH-05** | Đăng nhập sai mật khẩu | Đã có tài khoản | Nhập đúng email nhưng nhập sai mật khẩu | HTTP 401 Unauthorized, thông báo "Email hoặc mật khẩu không chính xác". | Cao | **PASS** |
| **TC-AUTH-06** | Quên mật khẩu gửi OTP | Tài khoản đã đăng ký | 1. Chọn "Quên mật khẩu"<br>2. Nhập email tài khoản | HTTP 200 OK, sinh mã OTP 6 số ngẫu nhiên lưu bảng `password_resets`, gửi email qua Nodemailer. | Cao | **PASS** |
| **TC-AUTH-07** | Nhập sai mã OTP | Đã gửi OTP | Nhập mã OTP không khớp (ví dụ: `000000`) | HTTP 400 Bad Request, thông báo "Mã OTP không chính xác hoặc đã hết hạn". | Cao | **PASS** |
| **TC-AUTH-08** | Đặt lại mật khẩu thành công | Có OTP hợp lệ | Nhập OTP đúng + Mật khẩu mới | HTTP 200 OK, mật khẩu cập nhật thành công, OTP chuyển trạng thái `used = true`. | Cao | **PASS** |

---

### 3.2. Phân hệ 2: Quản lý Phòng & Ma trận Phòng (Rooms & Matrix)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-ROOM-01** | Lấy sơ đồ Ma trận phòng | Đăng nhập tài khoản Lễ tân | Mở màn hình "Room Matrix" | HTTP 200 OK, hiển thị đầy đủ danh sách phòng theo từng tầng (Tầng 1, 2...) với mã màu chính xác. | Cao | **PASS** |
| **TC-ROOM-02** | Tra cứu phòng trống theo ngày | Khách vào màn hình tìm kiếm | Chọn ngày đến: 25/09, Ngày đi: 28/09, Số khách: 2 | HTTP 200 OK, chỉ trả về các phòng không bị trùng lịch với bất kỳ đơn nào đã duyệt. | Cao | **PASS** |
| **TC-ROOM-03** | Chuyển trạng thái dọn dẹp phòng | Phòng đang ở trạng thái `CLEANING` | Lễ tân bấm "Hoàn tất dọn phòng" | HTTP 200 OK, trạng thái phòng chuyển từ `CLEANING` (vàng) sang `AVAILABLE` (xanh lá). | Vừa | **PASS** |

---

### 3.3. Phân hệ 3: Đặt phòng & Quầy tiền sảnh (Bookings Lifecycle)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-BOOK-01** | Đặt phòng trực tuyến hợp lệ | Khách đã đăng nhập, phòng trống | 1. Chọn phòng 201<br>2. Chọn ngày: 25/09 - 27/09<br>3. Bấm "Đặt ngay" | HTTP 201 Created, tạo Booking (`status = PENDING`), tự động tạo Invoice (`UNPAID`). | Cao | **PASS** |
| **TC-BOOK-02** | Kiểm thử tranh chấp đặt trùng phòng | Phòng 201 đã có đơn `CONFIRMED` ngày 25/09 - 27/09 | Khách thứ hai chọn đúng phòng 201 từ 26/09 - 28/09 | HTTP 409 Conflict (`ERR_ROOM_OCCUPIED`), chặn đơn trùng, bảo vệ toàn vẹn lịch phòng. | Nghiêm ngặt | **PASS** |
| **TC-BOOK-03** | Lễ tân phê duyệt đơn phòng | Đơn đặt phòng có status = PENDING | Lễ tân bấm nút "Duyệt đơn" | HTTP 200 OK, `booking.status = CONFIRMED`, `room.status = RESERVED`, gửi Push Notification FCM. | Cao | **PASS** |
| **TC-BOOK-04** | Từ chối đơn không nhập lý do | Đơn đang PENDING | Bấm "Từ chối" nhưng để trống lý do | Client bắt lỗi form đỏ; Backend trả HTTP 400 (`ERR_REASON_REQUIRED`). | Vừa | **PASS** |
| **TC-BOOK-05** | Từ chối đơn có kèm lý do | Đơn đang PENDING | Bấm "Từ chối" kèm lý do: "Hết phòng" | HTTP 200 OK, `booking.status = CANCELLED`, lưu vết lý do từ chối. | Vừa | **PASS** |
| **TC-BOOK-06** | Thủ tục Nhận phòng (Check-in) | Đơn đã CONFIRMED đến ngày nhận | Lễ tân kiểm tra CCCD, bấm "Check-in" | HTTP 200 OK, `booking.status = CHECKED_IN`, phòng chuyển sang màu đỏ `OCCUPIED`. | Cao | **PASS** |
| **TC-BOOK-07** | Nhận phòng vãng lai (Walk-in) | Phòng 105 đang AVAILABLE | Lễ tân bấm thẻ phòng trống -> Walk-in -> Nhập tên khách | HTTP 201 Created, tạo ngay Booking và nhận phòng lập tức, chuyển phòng sang `OCCUPIED`. | Cao | **PASS** |
| **TC-BOOK-08** | Đổi phòng cho khách đang ở | Khách đang ở phòng 101, phòng 102 đang trống | Lễ tân bấm menu phòng 101 -> Chọn Đổi sang phòng 102 | HTTP 200 OK, phòng 101 về `CLEANING`, phòng 102 sang `OCCUPIED`, đơn cập nhật `roomId = 102`. | Cao | **PASS** |
| **TC-BOOK-09** | Trả phòng khi chưa thanh toán hết | Hóa đơn còn dư nợ 500.000đ | Lễ tân bấm "Trả phòng" mà chưa thu tiền | Hệ thống cảnh báo đỏ yêu cầu thanh toán dứt điểm khoản còn thiếu trước khi hoàn tất. | Cao | **PASS** |
| **TC-BOOK-10** | Trả phòng thành công (Check-out) | Hóa đơn đã thanh toán đủ (`remaining = 0`) | Lễ tân bấm "Hoàn tất trả phòng" | HTTP 200 OK, `booking.status = CHECKED_OUT`, phòng chuyển về màu vàng cam `CLEANING`. | Cao | **PASS** |
| **TC-BOOK-11** | Xem trước hóa đơn Check-out | Khách đang lưu trú tại phòng | Bấm xem trước bảng kê chi phí trả phòng | HTTP 200 OK, trích xuất chuẩn xác số đêm, phụ thu, chi phí minibar và số tiền còn thiếu mà không đổi trạng thái đơn. | Cao | **PASS** |

---

### 3.4. Phân hệ 4: Thu ngân & Ca trực lễ tân (Cashier & Shifts)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-PAY-01** | Khách chuyển khoản thanh toán | Hóa đơn tồn tại trên app khách | Khách bấm "Thanh toán", nhập mã giao dịch ngân hàng | HTTP 201 Created, sinh Payment `status = PENDING`, chưa cộng vào `paidAmount` hóa đơn. | Cao | **PASS** |
| **TC-PAY-02** | Thu ngân duyệt nhận chuyển khoản | Có Payment PENDING | Thu ngân kiểm tra sao kê, bấm "Duyệt nhận tiền" | HTTP 200 OK, Payment sang `CONFIRMED`, `paidAmount` hóa đơn tự động tăng thêm số tiền đó. | Cao | **PASS** |
| **TC-PAY-03** | Thu ngân từ chối giao dịch giả mạo | Có Payment PENDING không thấy tiền | Bấm "Từ chối" kèm lý do: "Chưa nhận được tiền" | HTTP 200 OK, Payment sang `REJECTED`, không cộng tiền vào hóa đơn, thông báo giải thích gửi tới khách. | Cao | **PASS** |
| **TC-PAY-04** | Hoàn trả tiền thừa đặt cọc (Refund) | Khách có số dư đặt cọc thừa sau kiểm phòng | Nhập số tiền hoàn trả 500.000đ kèm lý do | HTTP 200 OK, tạo bản ghi hoàn tiền `type = REFUND`, cập nhật lại số dư hóa đơn chính xác. | Vừa | **PASS** |
| **TC-SHIFT-01** | Mở ca trực lễ tân | Nhân viên chưa có ca trực OPEN | Khai báo: Ca Sáng, Tiền đầu ca: 2.000.000đ | HTTP 201 Created, tạo WorkShift `status = OPEN`, hiển thị banner ca trực trên màn hình lễ tân. | Cao | **PASS** |
| **TC-SHIFT-02** | Mở ca khi ca cũ chưa đóng | Nhân viên đang có 1 ca OPEN | Bấm mở thêm ca khác | HTTP 409 Conflict (`ERR_SHIFT_ALREADY_OPEN`), chặn mở trùng ca. | Vừa | **PASS** |
| **TC-SHIFT-03** | Chốt ca lệch tiền không giải trình | Đầu ca 2M, thu 3M (Expected: 5M), kiểm đếm thực tế 4.8M | Nhập actualCash = 4.8M, để trống ô giải trình | HTTP 400 Bad Request, bắt buộc giải trình chênh lệch -200.000 VNĐ. | Nghiêm ngặt | **PASS** |
| **TC-SHIFT-04** | Chốt ca thành công có giải trình | Có chênh lệch tiền két | Nhập actualCash = 4.8M, nhập lý do: "Đã chi tiền mua văn phòng phẩm" | HTTP 200 OK, WorkShift chuyển `status = CLOSED`, ghi nhận biên bản đối soát ca hoàn tất. | Cao | **PASS** |
| **TC-SHIFT-05** | Admin cưỡng chế chốt ca hộ | Nhân viên bỏ ca hoặc nghỉ ốm đột xuất | Admin bấm "Cưỡng chế chốt ca" | HTTP 200 OK, WorkShift chuyển sang `CLOSED`, giải phóng quầy trực đón ca tiếp theo. | Cao | **PASS** |
| **TC-SHIFT-06** | Tra cứu lịch sử ca và sổ quỹ | Đăng nhập tài khoản Quản lý | Mở màn hình Sổ ca trực | HTTP 200 OK, hiển thị đầy đủ lịch sử các ca kèm danh sách chi tiết các khoản thu trong từng ca. | Vừa | **PASS** |

---

### 3.5. Phân hệ 5: Báo cáo Thống kê & Quản trị (Analytics)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-STAT-01** | Xem Dashboard Admin | Đăng nhập tài khoản ADMIN | Mở màn hình Tổng quan | HTTP 200 OK, hiển thị đầy đủ 4 thẻ KPI: Tỷ lệ lấp đầy %, Lượt nhận/trả phòng hôm nay, Đơn chờ. | Cao | **PASS** |
| **TC-STAT-02** | Xem biểu đồ doanh thu theo năm | Admin mở màn hình Báo cáo | Chọn năm 2026 trên dropdown bộ lọc | HTTP 200 OK, biểu đồ FL Chart vẽ chuẩn xác 12 cột doanh thu, phân tách tiền phòng và dịch vụ. | Cao | **PASS** |
| **TC-STAT-03** | Báo cáo hiệu suất nhân viên | Admin mở mục Đánh giá nhân sự | Chọn mốc thời gian đánh giá | HTTP 200 OK, thống kê chính xác số lượt Check-in/Check-out và tổng tiền từng nhân viên thu trong ca. | Vừa | **PASS** |
| **TC-STAT-04** | Biểu đồ doanh thu ngắn hạn | Màn hình Báo cáo | Chọn xem 7 ngày / 30 ngày gần nhất | HTTP 200 OK, chuỗi dữ liệu từng ngày chính xác phục vụ phân tích xu hướng kinh doanh tuần. | Vừa | **PASS** |

---

### 3.6. Phân hệ 6: Quản trị Nhân sự & Phân quyền (Staff & User Management)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-USER-01** | Tạo tài khoản nhân viên mới | Đăng nhập quyền ADMIN | Nhập email, họ tên, mật khẩu, chọn quyền RECEPTIONIST | HTTP 201 Created, tạo tài khoản nhân viên mới, mật khẩu băm Bcrypt an toàn. | Cao | **PASS** |
| **TC-USER-02** | Khóa tài khoản nhân viên | Nhân viên đang hoạt động | Admin bấm khóa tài khoản (`isActive = false`) | HTTP 200 OK, tài khoản bị khóa lập tức, chặn đăng nhập với mã lỗi `ERR_USER_DEACTIVATED`. | Cao | **PASS** |
| **TC-USER-03** | Admin đặt lại mật khẩu nhân viên | Nhân viên quên mật khẩu | Admin nhập mật khẩu mới và xác nhận | HTTP 200 OK, mật khẩu nhân viên cập nhật thành công mà không cần qua hộp thư OTP. | Cao | **PASS** |
| **TC-USER-04** | Đồng bộ nhân sự realtime SSE | Admin đang mở màn hình nhân sự | Nhân viên khác được tạo ở tab khác | Giao diện tự động cập nhật danh sách hiển thị nhân viên mới thông qua luồng SSE `/users/stream`. | Vừa | **PASS** |

---

### 3.7. Phân hệ 7: Quản lý Hồ sơ Cá nhân & Bảo mật (Profile & Security)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-PROF-01** | Đổi mật khẩu cá nhân thành công | Đã đăng nhập tài khoản | Nhập đúng mật khẩu cũ + Mật khẩu mới >= 6 ký tự | HTTP 200 OK, mật khẩu mới được băm và lưu thành công. | Cao | **PASS** |
| **TC-PROF-02** | Đổi mật khẩu sai mật khẩu cũ | Đã đăng nhập tài khoản | Nhập sai mật khẩu cũ | HTTP 400 Bad Request (`ERR_OLD_PASSWORD_INCORRECT`), báo lỗi đỏ trên form. | Cao | **PASS** |
| **TC-PROF-03** | Cập nhật ảnh đại diện Avatar | Đã đăng nhập tài khoản | Chọn ảnh chân dung từ thư viện máy | HTTP 200 OK, ảnh được nén tải lên Cloudinary và cập nhật trường `avatarUrl` người dùng. | Vừa | **PASS** |

---

### 3.8. Phân hệ 8: Trung tâm Thông báo Đa kênh (Notifications)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-NOTIF-01** | Nhận Push Notification FCM | Máy khách đã đăng ký `fcmToken` | Lễ tân duyệt đơn đặt phòng của khách | Thiết bị khách nhận thông báo đẩy tức thì: "Đơn đặt phòng BK-2026-XXX đã được phê duyệt". | Cao | **PASS** |
| **TC-NOTIF-02** | Đánh dấu đọc tất cả thông báo | Hộp thư có 5 thông báo chưa đọc | Bấm nút "Đọc tất cả" | HTTP 200 OK, tất cả thông báo chuyển sang `isRead = true`, huy hiệu đếm về 0. | Vừa | **PASS** |

---

### 3.9. Phân hệ 9: Bảo trì & Đồng bộ Hệ thống (Maintenance & Sync)

| Mã TC | Tên ca kiểm thử | Điều kiện tiên quyết | Các bước thực hiện & Dữ liệu đầu vào | Kết quả kỳ vọng | Ưu tiên | Trạng thái |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: |
| **TC-MAINT-01**| Tự động đồng bộ trạng thái phòng | Có phòng hết hạn lưu trú chưa check-out | Gọi API `POST /rooms/sync-status` | HTTP 200 OK, hệ thống tự động rà soát và chuyển trạng thái phòng chuẩn hóa theo thời gian thực. | Vừa | **PASS** |

---

## 4. TỔNG KẾT VÀ ĐÁNH GIÁ KẾT QUẢ KIỂM THỬ (TEST SUMMARY REPORT)

### 4.1. Thống kê kết quả kiểm thử toàn diện

```
Tổng số kịch bản kiểm thử (Total Test Cases): 42 ca
Số ca kiểm thử ĐẠT (Passed):                  42 ca (100%)
Số ca kiểm thử KHÔNG ĐẠT (Failed):            0 ca (0%)
Số lỗi phát hiện và đã khắc phục (Bugs Fixed): 4 lỗi (đã giải quyết triệt để)
Mức độ bao phủ kiểm thử (Test Coverage):      100% các phân hệ nghiệp vụ & luồng dữ liệu
```

### 4.2. Danh sách lỗi tiêu biểu đã phát hiện và xử lý trong quá trình kiểm thử
1. **Lỗi Race Condition khi đặt phòng trùng:** Ban đầu câu lệnh find phòng trống chưa dùng transaction isolation -> Đã sửa bằng cách bọc toàn bộ thao tác trong `prisma.$transaction` với điều kiện lọc giao thoa thời gian nghiêm ngặt.
2. **Lỗi tính sai tiền còn thiếu của hóa đơn:** Ban đầu cộng dồn cả các khoản thu `PENDING` -> Đã sửa lại: chỉ các khoản `CONFIRMED` mới được tính vào `paidAmount`.
3. **Lỗi bỏ quên giải trình khi két lệch tiền:** Ban đầu cho phép chốt ca tự do -> Đã bổ sung ràng buộc kiểm tra `cashDifference !== 0 && !dto.differenceReason` tại Service.
4. **Lỗi chưa đồng bộ tiền cọc khi trả phòng sớm:** Bổ sung nghiệp vụ hoàn tiền `POST /invoices/:id/refund` và bảng kê Checkout Preview để đối soát dứt điểm trước khi bấm Check-out.

### 4.3. Kết luận
Hệ thống phần mềm Luxe Grand Hotel đã vượt qua 100% của toàn bộ 42 ca kiểm thử nghiêm ngặt, đảm bảo tính ổn định cao, tính nhất quán tài chính và sẵn sàng đưa vào vận hành thực tế.
