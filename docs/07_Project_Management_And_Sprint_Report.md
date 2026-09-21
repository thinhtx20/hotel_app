# BÁO CÁO QUẢN LÝ DỰ ÁN VÀ TIẾN ĐỘ PHÁT TRIỂN AGILE/SCRUM
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL

---

## 1. MÔ HÌNH VÀ PHƯƠNG PHÁP QUẢN LÝ DỰ ÁN (PROJECT METHODOLOGY)

Dự án áp dụng mô hình phát triển phần mềm linh hoạt **Agile/Scrum**, chia quy trình triển khai thành 4 chu kỳ lặp (Sprints), mỗi Sprint kéo dài từ 2 đến 3 tuần với các nghi thức chuẩn:
- **Sprint Planning (Lập kế hoạch Sprint):** Phân rã Product Backlog thành các User Stories cụ thể, ước lượng điểm công việc (Story Points).
- **Daily Scrum (Họp tiến độ hàng ngày):** Cập nhật 3 câu hỏi: Đã làm gì hôm qua? Sẽ làm gì hôm nay? Đang gặp trở ngại gì (Blockers)?
- **Sprint Review (Đánh giá Sprint):** Demo tính năng phần mềm thực tế chạy được cho Giảng viên hướng dẫn / Stakeholders.
- **Sprint Retrospective (Cải tiến quy trình):** Rút kinh nghiệm về chất lượng mã nguồn và sự phối hợp giữa nhóm Backend và Mobile.

```mermaid
gantt
    title LỊCH TRÌNH PHÁT TRIỂN DỰ ÁN LUXE GRAND HOTEL (AGILE/SCRUM)
    dateFormat  YYYY-MM-DD
    section Giai đoạn 1: Khởi tạo
    Khảo sát & Lập tài liệu SRS       :done,    des1, 2026-07-01, 2026-07-15
    Thiết kế Kiến trúc SAD & ERD      :done,    des2, 2026-07-16, 2026-07-31
    section Giai đoạn 2: Sprints
    Sprint 1: Auth & Nền tảng Core    :done,    sp1, 2026-08-01, 2026-08-15
    Sprint 2: Room Matrix & Quản lý   :done,    sp2, 2026-08-16, 2026-08-31
    Sprint 3: Bookings & Tiền sảnh    :done,    sp3, 2026-09-01, 2026-09-12
    Sprint 4: Ca trực, Thu ngân & KPI :done,    sp4, 2026-09-13, 2026-09-20
    section Giai đoạn 3: Đóng gói
    Kiểm thử UAT & Viết tài liệu      :active,  pkg, 2026-09-21, 2026-09-30
```

---

## 2. CƠ CẤU PHÂN CHIA CÔNG VIỆC (WORK BREAKDOWN STRUCTURE - WBS)

### 2.1. Giai đoạn 1: Khởi tạo & Thiết kế hệ thống (Sprint 0)
- **1.1. Khảo sát nghiệp vụ:** Khảo sát quy trình vận hành khách sạn 4-5 sao thực tế (Check-in, Check-out, Minibar, Giao ca tiền mặt).
- **1.2. Thiết kế tài liệu SRS:** Định nghĩa 19 yêu cầu chức năng cốt lõi và các tiêu chuẩn phi chức năng.
- **1.3. Thiết kế kiến trúc:** Thiết kế Modular Monolith (NestJS), Clean Architecture (Flutter), sơ đồ tuần tự và đặc tả API.
- **1.4. Thiết kế CSDL:** Chuẩn hóa sơ đồ ERD mức 3NF với 10 bảng thực thể, thiết lập khóa ngoại và chỉ mục B-tree.

---

### 2.2. Giai đoạn 2: Phát triển các Sprint (Core Sprints)

#### Sprint 1: Nền tảng cốt lõi & Xác thực phân quyền (Authentication & Core Foundation)
- **Mục tiêu:** Xây dựng khung ứng dụng Backend và Frontend, hoàn thiện luồng đăng nhập/đăng ký.
- **Kết quả đạt được (Deliverables):**
  + Backend: Cấu hình NestJS, Prisma Client, Bcrypt, Passport JWT, Guard phân quyền Roles.
  + Module Auth: API Register, Login, Quên mật khẩu qua mã OTP gửi về Email bằng Nodemailer.
  + Mobile Client: Cấu hình Dio Client, PrettyLogger, AuthInterceptor, AuthBloc, màn hình Login, Register, ForgotPassword.

#### Sprint 2: Quản lý Danh mục Phòng & Ma trận phòng (Rooms & Room Matrix)
- **Mục tiêu:** Hiển thị trực quan toàn bộ sơ đồ phòng khách sạn trên ứng dụng di động.
- **Kết quả đạt được (Deliverables):**
  + Backend: Module Rooms, RoomTypes, API trả về Room Matrix nhóm theo tầng. Tích hợp Redis Caching cho danh mục phòng.
  + Mobile Client: Màn hình Room Matrix Screen chia tab theo tầng, hiển thị thẻ phòng kèm mã màu thời gian thực (Xanh lá, Đỏ, Vàng cam, Lam, Xám).

#### Sprint 3: Đặt phòng & Nghiệp vụ Quầy tiền sảnh (Bookings & Front-Desk)
- **Mục tiêu:** Khép kín chu trình đặt phòng trực tuyến và nghiệp vụ tiền sảnh.
- **Kết quả đạt được (Deliverables):**
  + Backend: Thuật toán kiểm tra lịch phòng trống không giao thoa ngày; API tạo đơn Booking, duyệt đơn, từ chối đơn; API Check-in (lưu số CCCD), Check-out và Đổi phòng (Change room).
  + Mobile Client: Luồng tìm kiếm phòng khách hàng (chọn khoảng ngày), màn hình Đặt phòng, màn hình Duyệt đơn cho lễ tân, modal Nhận phòng nhanh Walk-in.
  + Tích hợp Firebase Cloud Messaging (FCM) gửi thông báo tức thì khi đơn được duyệt.

#### Sprint 4: Tài chính, Quản lý Ca trực & Báo cáo Quản trị (Cashier, Shifts & Analytics)
- **Mục tiêu:** Quản lý dòng tiền chống thất thoát và cung cấp báo cáo doanh thu điều hành.
- **Kết quả đạt được (Deliverables):**
  + Backend: Module Invoices & Multi-Entry Payments (Hỗ trợ cọc, trả nợ từng đợt, hoàn tiền); Module Shifts (Mở ca, công thức tính tiền mặt lý thuyết `expectedCash`, chốt ca bắt buộc giải trình chênh lệch); Module Analytics (Tổng hợp doanh thu 12 tháng, tỷ lệ lấp đầy).
  + Mobile Client: Màn hình Quản lý ca trực (Sheet mở/chốt ca), màn hình Hóa đơn thu ngân, màn hình Báo cáo Admin tích hợp biểu đồ tương tác FL Chart.

#### Sprint 5: Mở rộng Quản trị Nhân sự, Thông báo Đa kênh & Tối ưu hóa Toàn diện (Scale & Polish)
- **Mục tiêu:** Hoàn thiện các phân hệ quản lý nhân sự, trung tâm thông báo, bảo mật tài khoản và quyết toán trả phòng minh bạch.
- **Kết quả đạt được (Deliverables):**
  + Backend & Mobile: Phân hệ Quản trị Nhân sự RBAC (tạo tài khoản, phân quyền, khóa tài khoản, đổi mật khẩu nhân viên, stream SSE danh sách người dùng).
  + Nghiệp vụ Checkout Preview: Trích xuất bảng kê chi phí chi tiết trước khi chốt trả phòng và quy trình từ chối yêu cầu chuyển khoản giả mạo.
  + Trung tâm thông báo FCM Push Notification, phân hệ Hồ sơ cá nhân (đổi mật khẩu, upload avatar Cloudinary), báo cáo hiệu suất nhân viên và doanh thu theo ngày.

---

## 3. BẢNG QUẢN LÝ VÀ XỬ LÝ RỦI RO (RISK MANAGEMENT MATRIX)

| Mã Rủi ro | Mô tả rủi ro tiềm ẩn | Khả năng | Tác động | Chiến lược giảm thiểu và xử lý thực tế |
| :---: | :--- | :---: | :---: | :--- |
| **RSK-01** | Tranh chấp đặt trùng phòng khi nhiều người cùng đặt 1 phòng (Race condition) | Cao | Nghiêm trọng | Bọc logic kiểm tra và tạo đơn phòng trong một `prisma.$transaction` với khóa dòng cấp CSDL. |
| **RSK-02** | Thất thoát tiền mặt hoặc sai lệch sổ sách khi đổi ca lễ tân | Cao | Cao | Bắt buộc khai báo ca trực, khóa giao dịch theo mã `shiftId`, tự động tính chênh lệch tiền két và ép buộc giải trình. |
| **RSK-03** | Khách chuyển khoản ảo (giả mạo mã giao dịch) để nhận phòng | Vừa | Nghiêm trọng | Phân tách trạng thái khoản thu `PENDING` và `CONFIRMED`. Tiền hóa đơn chỉ được trừ khi thu ngân bấm xác nhận sau khi kiểm tra sao kê; hỗ trợ quy trình từ chối giao dịch giả mạo. |
| **RSK-04** | Tải cao vào mùa cao điểm gây chậm thời gian phản hồi tra cứu phòng | Vừa | Vừa | Áp dụng Redis Cache đệm danh mục phòng trống và đánh chỉ mục B-tree trên các cột tìm kiếm `checkInDate`, `checkOutDate`. |

---

## 4. TỔNG KẾT NGHIỆM THU VÀ ĐÁNH GIÁ DỰ ÁN (PROJECT RETROSPECTIVE)

### 4.1. Mức độ hoàn thành mục tiêu (KPI Deliverables)
- **Chức năng:** Hoàn thành 100% các tính năng trong Product Backlog (27/27 User Stories cam kết).
- **Tiến độ:** Hoàn thành đúng hạn 5/5 Sprints theo kế hoạch đã cam kết với Giảng viên hướng dẫn.
- **Chất lượng mã nguồn:**
  + Tuân thủ nghiêm ngặt chuẩn kiến trúc Modular Monolith trên NestJS và Feature-first trên Flutter.
  + Vượt qua 42/42 kịch bản kiểm thử tự động và thủ công đạt tỷ lệ đạt 100%.
  + Không tồn tại lỗi nghiêm trọng (Critical/Blocker bugs) trong phiên bản nghiệm thu.
  + Giao diện đạt chuẩn trải nghiệm người dùng cao cấp, tương thích tốt trên cả Android và iOS.

### 4.2. Bài học kinh nghiệm (Lessons Learned)
1. **Tầm quan trọng của việc chuẩn hóa API Spec sớm:** Việc thống nhất đặc tả API ngay từ Sprint 0 giúp đội ngũ Backend và Mobile có thể làm việc song song hiệu quả mà không bị tắc nghẽn phụ thuộc (Mock data).
2. **Kỷ luật dữ liệu giao dịch tài chính:** Tuyệt đối không tính toán thủ công các con số tài chính ở phía Client; toàn bộ logic tính tiền, cộng dồn hóa đơn phải được kiểm soát tập trung tại máy chủ thông qua các bản ghi giao dịch có dấu vết rõ ràng.

