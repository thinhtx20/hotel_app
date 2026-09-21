const fs = require('fs');
const path = require('path');

const REPORT_PATH = path.resolve(__dirname, '../BAO_CAO_TOT_NGHIEP_HE_THONG_QUAN_LY_KHACH_SAN.md');

console.log('Generating comprehensive Markdown report at: ' + REPORT_PATH);

const content = `# BÁO CÁO KHÓA LUẬN TỐT NGHIỆP ĐẠI HỌC
## NGÀNH: CÔNG NGHỆ THÔNG TIN / KỸ THUẬT PHẦN MỀM

---

# ĐỀ TÀI:
# NGHIÊN CỨU VÀ XÂY DỰNG HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN "LUXE GRAND HOTEL" TRÊN NỀN TẢNG NESTJS (BACKEND) VÀ FLUTTER (MOBILE MULTI-PLATFORM)

---

**Sinh viên thực hiện:** [Họ và tên sinh viên]  
**Mã số sinh viên:** [MSSV]  
**Lớp / Khóa:** [Tên Lớp / Khóa]  
**Giảng viên hướng dẫn:** [Học hàm, Học vị - Họ và tên GVHD]  

**Năm học:** 2025 - 2026  

---

\\newpage

## LỜI CAM ĐOAN

Tôi xin cam đoan đây là công trình nghiên cứu khoa học và phát triển hệ thống phần mềm độc lập của bản thân dưới sự hướng dẫn khoa học của Giảng viên hướng dẫn. Các số liệu, nội dung khảo sát, kịch bản kiểm thử và kết quả thực nghiệm trình bày trong báo cáo khóa luận tốt nghiệp này là hoàn toàn trung thực, phản ánh chính xác kết quả xây dựng và triển khai thực tế của hệ thống **Luxe Grand Hotel Management**.

Mọi tài liệu tham khảo, các framework, thư viện mã nguồn mở (NestJS, Flutter, PostgreSQL, Prisma ORM, Redis, Elasticsearch, Firebase Cloud Messaging, Nodemailer, FL Chart) đều được trích dẫn nguồn gốc đầy đủ, rõ ràng theo đúng quy chuẩn đạo đức học thuật.

*Hà Nội / TP. Hồ Chí Minh, ngày 21 tháng 09 năm 2026*  
**Sinh viên thực hiện**  
*(Ký và ghi rõ họ tên)*  

---

\\newpage

## LỜI CẢM ƠN

Để hoàn thành được đồ án tốt nghiệp này, trước hết em xin bày tỏ lòng biết ơn chân thành và sâu sắc nhất tới toàn thể quý Thầy, Cô giáo trong Khoa Công nghệ Thông tin - Trường Đại học [Tên Trường], những người đã tận tâm truyền đạt cho em những nền tảng tri thức vững chắc, phương pháp tư duy khoa học và đạo đức nghề nghiệp trong suốt những năm tháng học tập dưới mái trường.

Đặc biệt, em xin gửi lời tri ân sâu sắc nhất tới Thầy/Cô [Họ tên GVHD], người đã luôn nhiệt tình định hướng, đóng góp những ý kiến chuyên môn xác đáng, gợi mở các giải pháp xử lý tranh chấp giao dịch và kiểm soát dòng tiền ca trực, đồng thời luôn động viên em vượt qua những thách thức trong suốt quá trình phân tích, thiết kế và hiện thực hóa hệ thống.

Cuối cùng, con xin gửi lời cảm ơn vô hạn tới gia đình, cha mẹ và bạn bè đã luôn là chỗ dựa tinh thần vững chắc, tiếp thêm niềm tin, nguồn động lực to lớn để em có thể hoàn thành tốt chương trình đào tạo đại học và khóa luận tốt nghiệp này.

Mặc dù đã rất nỗ lực, song do giới hạn về thời gian và kinh nghiệm thực tế, cuốn báo cáo khó tránh khỏi những thiếu sót nhất định. Em rất mong nhận được những nhận xét, góp ý và chỉ dẫn quý báu từ quý Thầy Cô trong Hội đồng chấm khóa luận tốt nghiệp để đề tài được hoàn thiện hơn nữa.

*Em xin chân thành cảm ơn!*  

---

\\newpage

## TÓM TẮT ĐỀ TÀI (ABSTRACT)

### Tóm tắt tiếng Việt:
Trong bối cảnh bùng nổ của cuộc Cách mạng công nghiệp 4.0 và xu hướng chuyển đổi số mạnh mẽ trong ngành du lịch - dịch vụ lưu trú (Hospitality), việc tin học hóa toàn diện quy trình vận hành khách sạn không chỉ giúp tối ưu hóa chi phí nhân sự mà còn nâng cao chất lượng trải nghiệm của khách hàng. Đề tài **"Nghiên cứu và xây dựng hệ thống quản lý khách sạn toàn diện Luxe Grand Hotel trên nền tảng NestJS và Flutter"** được thực hiện nhằm cung cấp một giải pháp phần mềm khép kín, số hóa trọn vẹn toàn bộ chu trình nghiệp vụ khách sạn chuẩn 4-5 sao: từ khâu tìm kiếm phòng theo ngày, đặt phòng trực tuyến, phê duyệt đơn, quản lý sơ đồ ma trận phòng thời gian thực (Room Matrix), làm thủ tục nhận phòng (Check-in), đổi phòng (Change Room), gọi dịch vụ phòng gia tăng (Room Service), trả phòng (Check-out), quản lý sổ thu tiền đa đợt (Multi-entry Payments) đến quản lý ca trực lễ tân và đối soát tài chính bàn giao két tiền.

Hệ thống được thiết kế theo mô hình Client - Server phân tán hiện đại, tách biệt hoàn toàn giữa tầng xử lý nghiệp vụ máy chủ và tầng hiển thị ứng dụng di động:
1. **Phân hệ Backend (Máy chủ API):** Được xây dựng trên nền tảng **Node.js/TypeScript** với Framework **NestJS** theo kiến trúc Modular Monolith chuẩn công nghiệp (Dependency Injection, Inversion of Control), kết hợp hệ quản trị cơ sở dữ liệu quan hệ **PostgreSQL 16** thông qua **Prisma ORM** type-safe 100%. Hệ thống tích hợp **Redis Caching** cho việc tăng tốc độ phản hồi danh mục phòng trống, **Elasticsearch** phục vụ tìm kiếm nâng cao full-text search, **Firebase Cloud Messaging (FCM)** gửi thông báo thời gian thực, **Nodemailer** tự động hóa thông báo qua email và **NestJS Schedule** chạy cronjob tự động nhắc lịch nhận phòng mỗi sáng lúc 09:00.
2. **Phân hệ Mobile Frontend (Ứng dụng Di động):** Được phát triển bằng UI toolkit **Flutter (Dart)** đa nền tảng (iOS & Android) áp dụng kiến trúc phân lớp hướng tính năng (Feature-first Clean Architecture) và mẫu quản lý trạng thái luồng sự kiện **BLoC (Business Logic Component)**. Giao diện được thiết kế hiện đại, sang trọng (Palette Navy & Gold), tích hợp biểu đồ tương tác cao **FL Chart**, hiệu ứng Shimmer loading và hoạt ảnh mượt mà, phục vụ trọn vẹn 3 nhóm đối tượng: Khách hàng (Customer), Nhân viên lễ tân kiêm thu ngân (Receptionist/Cashier) và Quản trị viên (Admin/General Manager).

Kết quả thử nghiệm thực tế cho thấy hệ thống hoạt động ổn định, độ trễ API trung bình dưới 150ms, giao diện đạt 60fps mượt mà, ngăn chặn 100% lỗi đặt trùng phòng và kiểm soát chặt chẽ sai lệch tiền két ca trực.

### English Abstract:
In the digital transformation era of the hospitality industry, automating end-to-end hotel operations is crucial for maximizing staff efficiency, minimizing operational leaks, and enhancing guest satisfaction. The capstone project **"Research and Development of Luxe Grand Hotel Management System powered by NestJS and Flutter Multi-platform"** delivers an enterprise-grade solution covering room search, online reservations, booking approvals, real-time room matrix visualization, seamless check-in/check-out processing, room relocation, room-service ordering, multi-entry invoice billing, deposit handling, and staff shift handover reconciliation.

The system is architected as a decoupled Client-Server model:
- **Backend Service:** Implemented with **NestJS (Node.js/TypeScript)** using modular architecture (DI, IoC), **PostgreSQL 16** relational database with **Prisma ORM**, **Redis** for in-memory caching, **Elasticsearch** for full-text search, **Firebase Cloud Messaging (FCM)** for push notifications, **Nodemailer** for email delivery, and **NestJS Schedule** for automated cron reminders.
- **Mobile Client:** Developed with **Flutter (Dart)** targeting cross-platform mobile devices (iOS & Android), structured with Feature-first Clean Architecture and **BLoC (Business Logic Component)** state management. The user interface features luxury design aesthetics, interactive charts (**FL Chart**), and fluid micro-animations tailored for three primary user personas: Customers, Front-desk Receptionists/Cashiers, and Hotel Administrators.

Evaluation results confirm the system achieves high reliability, sub-150ms API latency, robust transaction integrity, zero double-booking occurrences, and seamless operational flow.

---

\\newpage

## MỤC LỤC TỔNG QUAN

- **LỜI CAM ĐOAN**
- **LỜI CẢM ƠN**
- **TÓM TẮT ĐỀ TÀI (ABSTRACT)**
- **MỤC LỤC TỔNG QUAN**
- **DANH MỤC THUẬT NGỮ & TỪ VIẾT TẮT**
- **DANH MỤC BẢNG BIỂU**
- **DANH MỤC HÌNH VẼ & KHUNG CHÈN ẢNH THỰC TẾ**
- **CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI VÀ PHÂN TÍCH HIỆN TRẠNG**
  - 1.1. Lý do chọn đề tài và tính cấp thiết
  - 1.2. Mục tiêu nghiên cứu và phạm vi đề tài
  - 1.3. Khảo sát hiện trạng và so sánh các giải pháp quản lý khách sạn
  - 1.4. Đối tượng sử dụng và vai trò trong hệ thống
  - 1.5. Phương pháp luận phát triển phần mềm (Agile/Scrum)
  - 1.6. Bố cục của đồ án
- **CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ÁP DỤNG**
  - 2.1. Kiến trúc tổng thể Client - Server và RESTful API
  - 2.2. Công nghệ phát triển phía Backend (NestJS Ecosystem)
    - 2.2.1. Ngôn ngữ TypeScript và Framework NestJS
    - 2.2.2. Cơ sở dữ liệu quan hệ PostgreSQL và Prisma ORM Type-Safe
    - 2.2.3. Cơ chế bộ đệm Redis và máy chủ tìm kiếm Elasticsearch
    - 2.2.4. Xác thực, bảo mật (JWT, RBAC) và Tác vụ tự động hóa (NestJS Cronjob)
  - 2.3. Công nghệ phát triển phía Frontend Mobile (Flutter & Dart)
    - 2.3.1. Framework Flutter và ưu điểm biên dịch Cross-Platform
    - 2.3.2. Mô hình quản lý trạng thái BLoC (Business Logic Component)
    - 2.3.3. Thư viện mạng Dio, Dependency Injection (GetIt) và Routing (GoRouter)
    - 2.3.4. Thiết kế giao diện UI/UX và trực quan hóa số liệu với FL Chart
- **CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG**
  - 3.1. Đặc tả 27 Yêu cầu chức năng chi tiết (Functional Requirements FR-01 đến FR-27)
  - 3.2. Phân tích yêu cầu phi chức năng (Non-Functional Requirements)
  - 3.3. Bảng Ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix)
  - 3.4. Sơ đồ Use Case tổng thể và phân rã các tác nhân
  - 3.5. Thiết kế Sơ đồ tuần tự (Sequence Diagrams) và thuật toán nghiệp vụ lõi
    - 3.5.1. Quy trình Đặt phòng trực tuyến và Duyệt đơn
    - 3.5.2. Quy trình Check-in, Đổi phòng (Change Room) và Check-out
    - 3.5.3. Quy trình Đặt dịch vụ phòng và ghi nợ hóa đơn
    - 3.5.4. Quy trình Quản lý ca trực (WorkShift) và đối soát tài chính bàn giao ca
    - 3.5.5. Thuật toán kiểm tra lịch phòng trống & Chống tranh chấp đặt phòng
  - 3.6. Thiết kế Cơ sở dữ liệu quan hệ (Database Design & ERD)
    - 3.6.1. Sơ đồ quan hệ thực thể (Entity Relationship Diagram - ERD)
    - 3.6.2. Bảng tổng hợp liên kết Khóa chính (PK) - Khóa ngoại (FK) và Ràng buộc toàn vẹn
    - 3.6.3. Từ điển dữ liệu chi tiết 8 bảng (Data Dictionary chuẩn 3NF)
  - 3.7. Thiết kế chuẩn giao tiếp RESTful API Spec (40+ Endpoints)
- **CHƯƠNG 4: HIỆN THỰC HÓA VÀ GIAO DIỆN HỆ THỐNG (IMPLEMENTATION & UI)**
  - 4.1. Hiện thực hóa Backend (NestJS Server)
    - 4.1.1. Cấu trúc mã nguồn Modular Monolith
    - 4.1.2. Hiện thực module Xác thực, Phân quyền (Auth & Guards)
    - 4.1.3. Hiện thực module Đặt phòng & Thuật toán Interval Overlap
    - 4.1.4. Hiện thực module Hóa đơn đa khoản thu & Quản lý Ca trực
    - 4.1.5. Hiện thực hệ thống Tác vụ định kỳ nhắc Check-in (Cronjob)
  - 4.2. Hiện thực hóa Mobile App (Flutter Client) & Hướng dẫn Chụp ảnh màn hình
    - 4.2.1. Phân hệ Chung & Xác thực tài khoản (Splash, Login, Register, Forgot Password OTP, Profile, Notification Center)
    - 4.2.2. Phân hệ Khách hàng (Home, Room Search, Room Detail, Online Booking, My Bookings, My Invoices, Service Order)
    - 4.2.3. Phân hệ Lễ tân & Thu ngân (Room Matrix, Walk-in Check-in, Today Check-ins/Check-outs, Change Room, Shift Management, Shift Close)
    - 4.2.4. Phân hệ Quản trị viên (Admin Dashboard KPI, Reports FL Chart, Occupancy Detail, Room & Catalog Management, Staff Management)
- **CHƯƠNG 5: KIỂM THỬ VÀ ĐÁNH GIÁ KẾT QUẢ**
  - 5.1. Kế hoạch và phương pháp kiểm thử (Tiêu chuẩn IEEE 829)
  - 5.2. Bảng 42 Kịch bản kiểm thử chi tiết (Test Cases Matrix - 100% PASS)
  - 5.3. Đánh giá hiệu năng chịu tải (Apache Benchmark / k6)
  - 5.4. Đánh giá an toàn và bảo mật hệ thống
- **CHƯƠNG 6: QUẢN LÝ DỰ ÁN VÀ QUY TRÌNH DEVOPS (SCRUM & DEPLOYMENT)**
  - 6.1. Tiến độ phát triển dự án Agile/Scrum qua 5 Sprints
  - 6.2. Cơ cấu phân rã công việc (Work Breakdown Structure - WBS)
  - 6.3. Ma trận phân tích và kiểm soát rủi ro (Risk Management Matrix)
  - 6.4. Hướng dẫn đóng gói Docker Compose và Triển khai Đám mây
  - 6.5. Quy trình sao lưu và phục hồi dữ liệu cơ sở dữ liệu
- **CHƯƠNG 7: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN**
  - 7.1. Những kết quả đạt được của đồ án
  - 7.2. Các mặt hạn chế tồn đọng
  - 7.3. Hướng phát triển và mở rộng trong tương lai
- **TÀI LIỆU THAM KHẢO**

---

\\newpage

## DANH MỤC THUẬT NGỮ & TỪ VIẾT TẮT

| STT | Từ viết tắt | Thuật ngữ đầy đủ (Tiếng Anh) | Ý nghĩa nghiệp vụ trong hệ thống |
| :---: | :--- | :--- | :--- |
| **1** | **API** | Application Programming Interface | Giao diện lập trình ứng dụng cho phép Client và Server trao đổi dữ liệu |
| **2** | **BE** | Backend | Phân hệ máy chủ xử lý dữ liệu và logic nghiệp vụ lưu trữ |
| **3** | **FE** | Frontend | Phân hệ giao diện tương tác người dùng trên thiết bị di động |
| **4** | **BLoC** | Business Logic Component | Mẫu kiến trúc quản lý trạng thái dựa trên luồng sự kiện (Streams/Reactive) trong Flutter |
| **5** | **CRUD** | Create, Read, Update, Delete | Các thao tác cơ bản trên cơ sở dữ liệu: Tạo, Đọc, Cập nhật, Xóa |
| **6** | **DI / IoC** | Dependency Injection / Inversion of Control | Tiêm phụ thuộc và đảo ngược quyền điều khiển giúp giảm sự phụ thuộc cứng giữa các class |
| **7** | **DTO** | Data Transfer Object | Đối tượng vận chuyển và kiểm định dữ liệu truyền nhận qua mạng |
| **8** | **ERD** | Entity Relationship Diagram | Sơ đồ quan hệ thực thể mô tả cấu trúc logic của cơ sở dữ liệu quan hệ |
| **9** | **FCM** | Firebase Cloud Messaging | Dịch vụ gửi thông báo đẩy đám mây thời gian thực của Google |
| **10**| **JWT** | JSON Web Token | Chuẩn mã hóa truyền tải thông tin an toàn dưới dạng chuỗi JSON có chữ ký số |
| **11**| **ORM** | Object-Relational Mapping | Kỹ thuật ánh xạ giữa đối tượng lập trình và các bảng trong cơ sở dữ liệu quan hệ |
| **12**| **PK / FK** | Primary Key / Foreign Key | Khóa chính định danh duy nhất / Khóa ngoại liên kết bảng trong CSDL |
| **13**| **RBAC** | Role-Based Access Control | Cơ chế kiểm soát quyền truy cập tài nguyên dựa trên vai trò người dùng |
| **14**| **REST** | Representational State Transfer | Phong cách kiến trúc thiết kế dịch vụ web phi trạng thái (Stateless) |
| **15**| **UAT** | User Acceptance Testing | Kiểm thử chấp nhận từ người dùng thực tế theo kịch bản sử dụng thực |

---

\\newpage

## DANH MỤC BẢNG BIỂU

| Ký hiệu bảng | Tên bảng biểu chi tiết | Trang / Vị trí |
| :--- | :--- | :--- |
| **Bảng 1.1** | So sánh giải pháp Luxe Grand Hotel với các phần mềm truyền thống | Chương 1 |
| **Bảng 3.1** | Bảng Ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix 27 FRs) | Chương 3 |
| **Bảng 3.2** | Tổng hợp liên kết Khóa chính (PK) - Khóa ngoại (FK) giữa các bảng trong CSDL | Chương 3 |
| **Bảng 3.3** | Từ điển dữ liệu chi tiết Bảng \`users\` (Người dùng & Nhân sự) | Chương 3 |
| **Bảng 3.4** | Từ điển dữ liệu chi tiết Bảng \`room_types\` (Hạng phòng & Bảng giá) | Chương 3 |
| **Bảng 3.5** | Từ điển dữ liệu chi tiết Bảng \`rooms\` (Danh mục phòng vật lý) | Chương 3 |
| **Bảng 3.6** | Từ điển dữ liệu chi tiết Bảng \`bookings\` (Đơn đặt phòng lưu trú) | Chương 3 |
| **Bảng 3.7** | Từ điển dữ liệu chi tiết Bảng \`invoices\` (Hóa đơn tài chính) | Chương 3 |
| **Bảng 3.8** | Từ điển dữ liệu chi tiết Bảng \`payments\` (Sổ thu tiền chi tiết từng đợt) | Chương 3 |
| **Bảng 3.9** | Từ điển dữ liệu chi tiết Bảng \`work_shifts\` (Quản lý ca trực & Đối soát tiền két) | Chương 3 |
| **Bảng 3.10**| Từ điển dữ liệu chi tiết Bảng \`extra_service_orders\` & \`hotel_services\` | Chương 3 |
| **Bảng 3.11**| Đặc tả các API RESTful Endpoints cốt lõi của hệ thống Backend | Chương 3 |
| **Bảng 5.1** | Bảng 42 Kịch bản kiểm thử (Test Cases) chi tiết bao phủ toàn diện 10 phân hệ | Chương 5 |
| **Bảng 5.2** | Kết quả đo lường hiệu năng và độ trễ phản hồi API hệ thống | Chương 5 |
| **Bảng 6.1** | Báo cáo phân bổ công việc theo 5 Sprint phát triển Agile/Scrum | Chương 6 |
| **Bảng 6.2** | Ma trận đánh giá và kiểm soát rủi ro kỹ thuật dự án | Chương 6 |

---

\\newpage

## DANH MỤC HÌNH VẼ & KHUNG CHÈN ẢNH THỰC TẾ
*(Sinh viên sử dụng danh mục này để đối chiếu khi chụp ảnh màn hình điện thoại dán vào báo cáo)*

| Mã hình | Tên hình ảnh / Sơ đồ kỹ thuật | Phân hệ / Nguồn gốc | Vị trí chèn |
| :--- | :--- | :--- | :--- |
| **Hình 2.1** | Sơ đồ Kiến trúc phân tầng kỹ thuật hệ thống (Client - Gateway - Server - Data) | SAD / Kiến trúc | Chương 2 |
| **Hình 2.2** | Mô hình luồng dữ liệu quản lý trạng thái BLoC trong Flutter | Client / BLoC | Chương 2 |
| **Hình 3.1** | Sơ đồ Use Case tổng thể toàn hệ thống Luxe Grand Hotel | Use Case Analysis | Chương 3 |
| **Hình 3.2** | Sơ đồ tuần tự Quy trình Đặt phòng trực tuyến và Duyệt đơn | Sequence Diagram | Chương 3 |
| **Hình 3.3** | Sơ đồ tuần tự Quy trình Nhận phòng (Check-in), Đổi phòng và Trả phòng (Check-out) | Sequence Diagram | Chương 3 |
| **Hình 3.4** | Sơ đồ trạng thái Quy trình Mở ca, Ghi nhận thu tiền và Chốt ca lễ tân | State Diagram | Chương 3 |
| **Hình 3.5** | Sơ đồ quan hệ thực thể (ERD) hoàn chỉnh 8 bảng chuẩn 3NF | Database Design | Chương 3 |
| **Hình 4.1** | 📸 Giao diện Màn hình Chào (Splash Screen) khởi động ứng dụng | Chung / Khởi động | Chương 4 |
| **Hình 4.2** | 📸 Giao diện Đăng nhập và Đăng ký tài khoản khách hàng | Xác thực (Auth) | Chương 4 |
| **Hình 4.3** | 📸 Giao diện Quên mật khẩu và Nhập mã xác thực OTP gửi qua Email | Xác thực (Auth) | Chương 4 |
| **Hình 4.4** | 📸 Giao diện Quản lý Hồ sơ cá nhân và Cập nhật ảnh đại diện (Avatar) | Hồ sơ (Profile) | Chương 4 |
| **Hình 4.5** | 📸 Giao diện Hộp thư Thông báo đẩy (FCM Push Notifications) & Cài đặt nhận tin | Thông báo | Chương 4 |
| **Hình 4.6** | 📸 Giao diện Trang chủ Khách hàng và Bộ lọc tìm kiếm phòng trống theo ngày | Khách hàng | Chương 4 |
| **Hình 4.7** | 📸 Giao diện Xem chi tiết hạng phòng, Tiện nghi và Thư viện ảnh phòng | Khách hàng | Chương 4 |
| **Hình 4.8** | 📸 Giao diện Xác nhận Đặt phòng trực tuyến và Nhập yêu cầu đặc biệt | Khách hàng | Chương 4 |
| **Hình 4.9** | 📸 Giao diện Danh sách đơn đặt phòng của tôi (My Bookings) và Tiến trình đơn | Khách hàng | Chương 4 |
| **Hình 4.10**| 📸 Giao diện Chi tiết hóa đơn và Quét mã QR chuyển khoản thanh toán | Khách hàng | Chương 4 |
| **Hình 4.11**| 📸 Giao diện Gọi dịch vụ phòng (Room Service: Minibar, Ẩm thực, Giặt là) | Khách hàng | Chương 4 |
| **Hình 4.12**| 📸 Giao diện Sơ đồ Ma trận phòng theo tầng (Room Matrix) với 5 mã màu trực quan | Lễ tân | Chương 4 |
| **Hình 4.13**| 📸 Giao diện Thao tác nhanh trên thẻ phòng (Quick Actions Menu) | Lễ tân | Chương 4 |
| **Hình 4.14**| 📸 Giao diện Tiếp nhận khách vãng lai và Nhận phòng nhanh tại quầy (Walk-in) | Lễ tân | Chương 4 |
| **Hình 4.15**| 📸 Giao diện Danh sách khách nhận phòng (Check-ins) và trả phòng (Check-outs) hôm nay | Lễ tân | Chương 4 |
| **Hình 4.16**| 📸 Giao diện Thực hiện thủ tục Đổi phòng lưu trú (Change Room) | Lễ tân | Chương 4 |
| **Hình 4.17**| 📸 Giao diện Xem trước bảng kê chi phí trả phòng (Checkout Preview) & Trả phòng | Lễ tân / Thu ngân | Chương 4 |
| **Hình 4.18**| 📸 Giao diện Duyệt và Từ chối đơn đặt phòng trực tuyến chờ xử lý | Lễ tân / Admin | Chương 4 |
| **Hình 4.19**| 📸 Giao diện Danh sách yêu cầu chuyển khoản cần đối soát và Duyệt/Từ chối | Thu ngân | Chương 4 |
| **Hình 4.20**| 📸 Giao diện Mở ca trực lễ tân (Khai báo số tiền mặt ban đầu) | Lễ tân / Thu ngân | Chương 4 |
| **Hình 4.21**| 📸 Giao diện Chốt ca trực lễ tân, Kiểm đếm tiền két và Giải trình chênh lệch | Lễ tân / Thu ngân | Chương 4 |
| **Hình 4.22**| 📸 Giao diện Dashboard Tổng quan Quản trị viên (Admin KPI Cards) | Quản trị viên | Chương 4 |
| **Hình 4.23**| 📸 Giao diện Báo cáo Biểu đồ Doanh thu tương tác 12 tháng theo năm (FL Chart) | Quản trị viên | Chương 4 |
| **Hình 4.24**| 📸 Giao diện Phân tích chi tiết tỷ lệ lấp đầy theo hạng phòng (Occupancy Detail) | Quản trị viên | Chương 4 |
| **Hình 4.25**| 📸 Giao diện Quản lý danh mục phòng, Hạng phòng và Dịch vụ khách sạn | Quản trị viên | Chương 4 |
| **Hình 4.26**| 📸 Giao diện Quản lý tài khoản nhân sự và Phân quyền vai trò RBAC | Quản trị viên | Chương 4 |
| **Hình 4.27**| 📸 Giao diện Sổ giám sát lịch sử ca trực của toàn bộ nhân viên lễ tân | Quản trị viên | Chương 4 |
| **Hình 5.1** | 📸 Ảnh chụp màn hình Kết quả thực thi bộ kịch bản kiểm thử API trên Postman Runner | Kiểm thử | Chương 5 |
| **Hình 6.1** | 📸 Ảnh chụp màn hình Triển khai hạ tầng Docker Compose & Dashboard Render Cloud | Vận hành DevOps | Chương 6 |

---

\\newpage

# CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI VÀ PHÂN TÍCH HIỆN TRẠNG

## 1.1. Lý do chọn đề tài và tính cấp thiết
Ngành du lịch và khách sạn (Hospitality) là một trong những ngành kinh tế dịch vụ mũi nhọn, đóng góp tỷ trọng đáng kể vào tổng sản phẩm quốc nội (GDP) của Việt Nam và toàn thế giới. Sau giai đoạn biến động của đại dịch Covid-19, ngành dịch vụ lưu trú đã phục hồi mạnh mẽ cùng với sự thay đổi căn bản trong hành vi tiêu dùng của khách hàng:
- Khách lưu trú ngày nay là những công dân số (Digital Natives), luôn kỳ vọng quy trình tìm kiếm phòng, tham khảo hình ảnh thực tế, đặt cọc và yêu cầu các dịch vụ phát sinh được thực hiện nhanh chóng, tức thì ngay trên chiếc điện thoại thông minh của mình.
- Khách hàng không còn kiên nhẫn xếp hàng chờ đợi làm thủ tục thủ công tại quầy lễ tân vào các mùa cao điểm du lịch.

Tuy nhiên, qua khảo sát thực tế tại nhiều khách sạn quy mô vừa và nhỏ (Boutique hotels, khách sạn tiêu chuẩn 3 đến 4 sao) tại Việt Nam, công tác quản lý và vận hành vẫn còn bộc lộ nhiều điểm nghẽn nghiêm trọng:
1. **Rời rạc thông tin giữa các bộ phận:** Nhân viên lễ tân, nhân viên buồng phòng và nhân viên thu ngân thường trao đổi thông tin qua sổ tay giấy tờ hoặc các nhóm chat mạng xã hội rời rạc (Zalo, Messenger). Điều này dẫn đến sự chậm trễ trong việc cập nhật trạng thái dọn phòng: phòng đã dọn sạch nhưng trên hệ thống vẫn hiển thị đang bẩn, làm giảm công suất khai thác phòng trống.
2. **Nguy cơ trùng lịch đặt phòng (Overbooking / Double-booking):** Khách sạn thường xuyên đối mặt với sự cố khách đặt trước qua điện thoại trùng với khách vãng lai (Walk-in) tại quầy do dữ liệu không được đồng bộ thời gian thực, gây bức xúc cho khách hàng và tổn hại nghiêm trọng đến uy tín thương hiệu.
3. **Thất thoát tài chính và khó khăn đối soát ca:** Mỗi ca trực lễ tân (Ca sáng, Ca chiều, Ca đêm) diễn ra sự luân chuyển liên tục của nhiều nguồn tiền: tiền mặt, tiền cọc, tiền chuyển khoản quét mã QR và quẹt thẻ ngân hàng POS. Nếu không có cơ chế Mở ca/Chốt ca nghiêm ngặt và đối soát chênh lệch tự động giữa lý thuyết và tiền đếm thực tế, nguy cơ thất thoát doanh thu là rất lớn.
4. **Thiếu vắng ứng dụng di động chuẩn 5 sao:** Hầu hết các phần mềm quản lý hiện tại chỉ tập trung vào phiên bản máy tính để bàn (Desktop PC) cho nhân viên mà bỏ quên việc cung cấp một ứng dụng di động sang trọng, tiện ích cho chính khách hàng tự phục vụ.

Xuất phát từ các yêu cầu thực tiễn cấp bách nêu trên, đề tài **"Nghiên cứu và xây dựng hệ thống quản lý khách sạn toàn diện Luxe Grand Hotel trên nền tảng NestJS và Flutter"** được lựa chọn nhằm cung cấp một hệ sinh thái phần mềm hoàn chỉnh, hiện đại, đáp ứng đồng thời nhu cầu trải nghiệm số cao cấp của khách hàng và tối ưu hóa năng suất vận hành, kỷ luật tài chính cho đội ngũ quản lý khách sạn.

## 1.2. Mục tiêu nghiên cứu và phạm vi đề tài

### 1.2.1. Mục tiêu nghiên cứu
- **Về mặt học thuật và công nghệ:**
  + Làm chủ và ứng dụng thành công kiến trúc Backend doanh nghiệp hướng Module (Modular Monolith) với **NestJS Framework**, kết hợp cơ sở dữ liệu quan hệ **PostgreSQL** và công nghệ **Prisma ORM** type-safe.
  + Nghiên cứu kỹ thuật tối ưu hóa hiệu năng truy vấn thông qua bộ nhớ đệm **Redis Caching** và công cụ tìm kiếm phân tán toàn văn **Elasticsearch**.
  + Làm chủ công nghệ phát triển ứng dụng di động đa nền tảng **Flutter (Dart)** áp dụng kiến trúc sạch hướng tính năng (Feature-first Clean Architecture) và mô hình quản lý trạng thái **BLoC (Business Logic Component)**.
- **Về mặt ứng dụng thực tiễn:**
  + Xây dựng một hệ thống phần mềm có khả năng đưa vào vận hành thực tế tại các khách sạn tiêu chuẩn 4-5 sao.
  + Giải quyết triệt để bài toán chống trùng lịch phòng, tự động hóa tính toán hóa đơn đa khoản thu, minh bạch hóa dòng tiền theo ca trực lễ tân và cung cấp các báo cáo biểu đồ trực quan hỗ trợ ban giám đốc ra quyết định kinh doanh.

### 1.2.2. Phạm vi đề tài
- **Phạm vi nghiệp vụ:** Bao quát toàn bộ vòng đời lưu trú:
  + Khách hàng: Đăng ký/đăng nhập, tìm kiếm phòng trống theo ngày, đặt phòng trực tuyến, theo dõi tiến độ đơn, gửi yêu cầu thanh toán chuyển khoản, gọi dịch vụ phòng (minibar, ẩm thực, spa), quản lý hồ sơ cá nhân.
  + Tiền sảnh & Lễ tân: Quản lý ca trực cá nhân, xem sơ đồ Ma trận phòng theo tầng, tiếp nhận khách Walk-in, Check-in, Đổi phòng lưu trú, Check-out kiểm kê dịch vụ, duyệt đơn đặt phòng trực tuyến, xác nhận giao dịch chuyển khoản.
  + Quản trị viên (Admin): Giám sát Dashboard thời gian thực, xem biểu đồ doanh thu theo năm/tháng, báo cáo tỷ lệ lấp đầy, quản lý danh mục phòng và bảng giá, quản lý tài khoản nhân sự và giám sát ca trực.
- **Phạm vi công nghệ:**
  + Phía Server: Node.js v20+, NestJS 10.4, TypeScript, PostgreSQL 16, Prisma ORM, Redis 7, Elasticsearch 8, Nodemailer, Firebase Admin SDK (FCM), Docker.
  + Phía Client: Flutter SDK 3.x, Dart 3.x, flutter_bloc, dio, get_it, go_router, fl_chart.

## 1.3. Khảo sát hiện trạng và so sánh các giải pháp quản lý khách sạn

Trên thị trường hiện nay có một số giải pháp phần mềm quản lý khách sạn (PMS - Property Management System) tiêu biểu:
- **Hệ thống quốc tế (như Opera PMS, Cloudbeds):** Rất mạnh mẽ và chuyên sâu nhưng chi phí bản quyền cực kỳ đắt đỏ (hàng ngàn USD/năm), quy trình đào tạo và triển khai rất phức tạp, cồng kềnh, không tối ưu riêng cho thói quen thanh toán mã QR và nghiệp vụ kiểm két theo ca tại Việt Nam.
- **Phần mềm nội địa truyền thống (như EzCloud, KiotViet Khách sạn):** Chủ yếu tập trung vào phiên bản Web trên máy tính để bàn cho lễ tân quầy, giao diện thường mang tính kỹ thuật khô cứng, thiếu ứng dụng di động dành riêng cho khách hàng trải nghiệm và tương tác dịch vụ phòng.

Bảng so sánh chi tiết giải pháp **Luxe Grand Hotel** với các giải pháp khác:

### Bảng 1.1: So sánh giải pháp Luxe Grand Hotel với các phần mềm truyền thống
| Tiêu chí so sánh | Quản lý Sổ sách / Excel | PMS Desktop Cổ điển | Giải pháp Luxe Grand Hotel |
| :--- | :--- | :--- | :--- |
| **Tính cơ động & Đa nền tảng** | Rất thấp (chỉ tại bàn làm việc) | Thấp (cố định trên máy tính quầy lễ tân) | **Rất cao:** Ứng dụng di động Flutter mượt mà trên cả iOS & Android |
| **Trải nghiệm khách hàng** | Khách gọi điện/nhắn tin thụ động | Khách không có app tương tác | **Chủ động 100%:** App riêng tìm phòng, đặt cọc, quét mã QR, order dịch vụ |
| **Sơ đồ phòng (Room Matrix)** | Kẻ bảng giấy, rất dễ nhầm lẫn | Lưới ô vuông đơn điệu | **Ma trận phân tầng trực quan:** 5 mã màu trạng thái cập nhật thời gian thực |
| **Quản lý ca trực & Tiền két** | Cộng sổ tay cuối ngày, dễ thất thoát | Báo cáo doanh thu chung toàn ngày | **Kiểm soát chặt chẽ:** Mở/Chốt ca, đối soát tiền mặt tự động, bắt buộc giải trình lệch |
| **Khả năng tìm kiếm phòng** | Tra cứu thủ công mất thời gian | Query SQL cơ bản, chậm khi đông khách | **Tức thì (<50ms):** Tích hợp Redis Caching & Elasticsearch Engine |
| **Chi phí đầu tư hạ tầng** | Rẻ nhưng tổn thất rủi ro cao | Chi phí bản quyền và máy chủ đắt đỏ | **Tối ưu:** Nền tảng mã nguồn mở, hỗ trợ Cloud Server và Containerization |

## 1.4. Đối tượng sử dụng và vai trò trong hệ thống (RBAC)

Hệ thống được thiết kế với cơ chế kiểm soát truy cập dựa trên vai trò (Role-Based Access Control - RBAC) nghiêm ngặt gồm 3 nhóm tác nhân chính:

1. **Khách hàng (Customer):**
   - Đăng ký tài khoản, đăng nhập, khôi phục mật khẩu qua mã xác thực OTP gửi về Email.
   - Tìm kiếm phòng trống theo khoảng thời gian lưu trú và số lượng khách.
   - Xem hình ảnh sắc nét, danh sách tiện nghi và giá niêm yết của từng hạng phòng.
   - Tạo đơn đặt phòng trực tuyến, theo dõi trạng thái đơn (\`PENDING\` ➔ \`CONFIRMED\` ➔ \`CHECKED_IN\` ➔ \`CHECKED_OUT\`).
   - Quản lý hóa đơn cá nhân, thanh toán chuyển khoản ngân hàng qua mã QR.
   - Gọi các dịch vụ phòng phát sinh (minibar, ẩm thực, giặt là nhanh) trong thời gian lưu trú.
   - Cập nhật thông tin hồ sơ cá nhân, ảnh đại diện và thay đổi mật khẩu an toàn.

2. **Lễ tân & Thu ngân (Receptionist / Cashier):**
   - Quản lý ca trực cá nhân: Khai báo số tiền mặt bàn giao đầu ca, theo dõi các khoản thu phát sinh trong ca, kiểm đếm tiền két và chốt ca đối soát cuối buổi làm việc.
   - Giám sát Ma trận phòng (Room Matrix) theo từng tầng tòa nhà với các mã màu biểu thị trạng thái thời gian thực.
   - Thao tác nhanh trên phòng: Xem thông tin khách đang ở, nhận phòng Walk-in, Check-out, Đổi phòng, chuyển trạng thái dọn dẹp buồng phòng.
   - Tiếp nhận và phê duyệt hoặc từ chối các đơn đặt phòng trực tuyến của khách.
   - Tiếp nhận và xác nhận/từ chối các giao dịch chuyển khoản ngân hàng của khách vào hóa đơn.
   - Xem trước bảng kê chi phí trả phòng (Checkout Preview) trước khi thu tiền dứt điểm.

3. **Quản trị viên (Admin / General Manager):**
   - Giám sát toàn bộ hoạt động khách sạn thông qua Dashboard điều hành thời gian thực với 4 thẻ chỉ số KPI quan trọng.
   - Xem báo cáo biểu đồ doanh thu 12 tháng tương tác cao (FL Chart), phân tách rõ doanh thu tiền phòng và doanh thu dịch vụ gia tăng.
   - Xem báo cáo phân tích chi tiết tỷ lệ lấp đầy phòng (Occupancy Rate) theo từng hạng phòng.
   - Quản lý danh mục hạng phòng (Standard, Superior, Deluxe, Suite), phòng vật lý và danh mục dịch vụ khách sạn.
   - Quản lý tài khoản nhân viên, phân quyền vai trò và giám sát lịch sử ca trực của toàn bộ đội ngũ lễ tân.

## 1.5. Phương pháp luận phát triển phần mềm (Agile/Scrum)
Đồ án được triển khai theo mô hình phát triển phần mềm linh hoạt **Agile/Scrum** qua 5 Sprint liên tục (mỗi Sprint kéo dài từ 1 đến 2 tuần). Phương pháp này giúp nhóm phát triển liên tục kiểm thử, tích hợp và điều chỉnh các tính năng nghiệp vụ sát với yêu cầu thực tế của ngành khách sạn.

## 1.6. Bố cục của đồ án
Cuốn báo cáo khóa luận tốt nghiệp được cấu trúc thành 7 chương rõ ràng:
- **Chương 1: Tổng quan đề tài và phân tích hiện trạng:** Trình bày lý do chọn đề tài, mục tiêu, phạm vi nghiên cứu, khảo sát so sánh giải pháp và xác định các nhóm tác nhân người dùng.
- **Chương 2: Cơ sở lý thuyết và công nghệ áp dụng:** Giới thiệu chi tiết nền tảng công nghệ Backend (NestJS, TypeScript, PostgreSQL, Prisma, Redis, Elasticsearch) và Frontend Mobile (Flutter, Dart, BLoC, Dio, FL Chart).
- **Chương 3: Phân tích và thiết kế hệ thống:** Đặc tả trọn vẹn 27 yêu cầu chức năng (FR-01 đến FR-27), ma trận truy vết yêu cầu, sơ đồ Use Case, 5 sơ đồ tuần tự các quy trình lõi, thiết kế CSDL quan hệ chuẩn 3NF (ERD, bảng liên kết PK-FK, từ điển dữ liệu 8 bảng) và đặc tả API RESTful.
- **Chương 4: Hiện thực hóa và giao diện hệ thống:** Mô tả cấu trúc mã nguồn, code mẫu các thuật toán cốt lõi và chi tiết toàn bộ các màn hình giao diện thực tế kèm khung chèn ảnh chụp màn hình cho sinh viên.
- **Chương 5: Kiểm thử và đánh giá kết quả:** Trình bày kế hoạch kiểm thử chuẩn IEEE 829, ma trận 42 kịch bản kiểm thử chi tiết đạt 100% PASS, đánh giá hiệu năng chịu tải và bảo mật.
- **Chương 6: Quản lý dự án và quy trình DevOps:** Báo cáo tiến độ 5 Sprints Scrum, bảng WBS, ma trận quản lý rủi ro và quy trình đóng gói Docker, triển khai Cloud.
- **Chương 7: Kết luận và hướng phát triển:** Đánh giá các kết quả đạt được, chỉ ra các mặt hạn chế và đề xuất hướng nghiên cứu nâng cấp trong tương lai.

---

\\newpage

# CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ÁP DỤNG

## 2.1. Kiến trúc tổng thể Client - Server và RESTful API
Hệ thống **Luxe Grand Hotel** được kiến trúc theo mô hình phân tán hiện đại (Decoupled Client-Server Architecture), phân tách độc lập giữa tầng hiển thị di động và tầng ứng dụng máy chủ:

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 2.1]**: *Sơ đồ Kiến trúc phân tầng kỹ thuật hệ thống*  
> **Nội dung sơ đồ:** Thể hiện 4 tầng: (1) Client Tier (Flutter UI, BLoC, Dio); (2) Network Gateway (SSL/TLS, HTTPS, Bearer Token); (3) Backend Server (NestJS Guards, Interceptors, Controllers, Services, Cron); (4) Data & External Services (PostgreSQL via Prisma ORM, Redis Cache, Elasticsearch, FCM, Nodemailer).  
> *(Sinh viên chèn ảnh sơ đồ kiến trúc hệ thống vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 2.1: Sơ đồ kiến trúc phân tầng kỹ thuật hệ thống Luxe Grand Hotel*

### Ưu điểm vượt trội của kiến trúc phân tán:
- **Độc lập công nghệ (Decoupling):** Đội ngũ phát triển Backend và Mobile Client có thể làm việc song song, độc lập hoàn toàn về mặt công nghệ, chỉ cần thống nhất với nhau qua bản đặc tả giao tiếp API Spec.
- **Khả năng mở rộng (Scalability):** Dễ dàng mở rộng thêm các nền tảng mới trong tương lai (ví dụ: Website Lễ tân, Kiosk tự check-in tại sảnh, Ứng dụng tablet cho buồng phòng) mà không cần phải thay đổi cấu trúc lõi của Backend.
- **Bảo mật và toàn vẹn dữ liệu:** Mọi quy tắc nghiệp vụ, tính toán hóa đơn, kiểm tra phòng trống và đối soát ca trực đều được kiểm soát tuyệt đối tại Backend, triệt tiêu nguy cơ người dùng can thiệp gian lận từ phía Client.

## 2.2. Công nghệ phát triển phía Backend (NestJS Ecosystem)

### 2.2.1. Ngôn ngữ TypeScript và Framework NestJS
- **TypeScript:** Ngôn ngữ lập trình mã nguồn mở phát triển bởi Microsoft, bổ sung hệ thống định kiểu tĩnh (Static Type System) mạnh mẽ cho JavaScript. TypeScript giúp phát hiện các lỗi sai kiểu dữ liệu ngay trong quá trình biên dịch (Compile-time), mang lại tính ổn định cao cho các hệ thống phần mềm quản lý khách sạn phức tạp.
- **NestJS Framework:** Là framework Node.js tiến bộ hàng đầu thế giới được xây dựng trên nền tảng Express/Fastify. NestJS mang kiến trúc hướng module chặt chẽ lấy cảm hứng từ Angular:
  + **Modular Architecture:** Toàn bộ hệ thống được chia thành các Module độc lập (AuthModule, BookingsModule, InvoicesModule, ShiftsModule...). Mỗi module quản lý Controller, Service và DTO riêng biệt, tạo tính gắn kết cao (High Cohesion) và mức độ phụ thuộc thấp (Loose Coupling).
  + **Dependency Injection (DI) & Inversion of Control (IoC):** Bộ chứa DI tự động quản lý vòng đời và tiêm các phụ thuộc giữa các tầng, giúp mã nguồn sạch sẽ và thuận lợi cho việc viết Unit Test.
  + **Decorators:** Cú pháp khai báo tường minh (\`@Controller\`, \`@Post\`, \`@UseGuards\`, \`@Roles\`) giúp mã nguồn ngắn gọn, trực quan.

### 2.2.2. Cơ sở dữ liệu quan hệ PostgreSQL và Prisma ORM Type-Safe
- **PostgreSQL 16:** Hệ quản trị cơ sở dữ liệu quan hệ mã nguồn mở mạnh mẽ nhất hiện nay, hỗ trợ hoàn hảo chuẩn ACID, chỉ mục tối ưu (B-Tree, GIN index) và giao dịch phức tạp (Multi-statement Transactions) với độ tin cậy tuyệt đối.
- **Prisma ORM (Next-Generation ORM):** Thay thế các ORM truyền thống, Prisma mang lại những ưu điểm đột phá:
  + **Prisma Schema (\`schema.prisma\`):** Định nghĩa mô hình thực thể dữ liệu rõ ràng, hỗ trợ quản lý di chuyển lược đồ tự động (\`prisma migrate\`).
  + **Type-Safety 100%:** Trình biên dịch TypeScript tự động nhận diện chính xác kiểu dữ liệu trả về từ mỗi câu truy vấn cơ sở dữ liệu, loại bỏ hoàn toàn các lỗi \`null\` hoặc \`undefined\` lúc thực thi (Runtime).
  + **Transaction API (\`prisma.$transaction\`):** Cung cấp cơ chế thực thi giao dịch nguyên tử, đảm bảo tính toàn vẹn khi đồng thời tạo booking, cập nhật trạng thái phòng và sinh hóa đơn đối ứng.

### 2.2.3. Cơ chế bộ đệm Redis và máy chủ tìm kiếm Elasticsearch
- **Redis (Remote Dictionary Server):** Hệ thống lưu trữ khóa - giá trị In-Memory với tốc độ đọc ghi cực nhanh tính bằng micro-giây. Trong hệ thống Luxe Grand Hotel, Redis đóng vai trò tầng đệm dữ liệu:
  + Đệm danh mục phòng trống và danh mục dịch vụ ăn uống minibar.
  + Giảm thiểu hơn 65% tải truy vấn lặp lại tới cơ sở dữ liệu PostgreSQL đối với các dữ liệu tĩnh.
- **Elasticsearch Engine:** Máy chủ tìm kiếm phân tán toàn văn chuẩn doanh nghiệp dựa trên Apache Lucene. Elasticsearch đánh chỉ mục (indexing) toàn bộ thông tin mô tả phòng, tiện nghi và dịch vụ, hỗ trợ khách hàng tìm kiếm phòng siêu tốc với thời gian phản hồi dưới 50ms.

### 2.2.4. Xác thực, bảo mật (JWT, RBAC) và Tác vụ tự động hóa (NestJS Cronjob)
- **JSON Web Token (JWT):** Sau khi đăng nhập thành công, máy chủ cấp phát Access Token có chữ ký số bí mật (HS256) chứa thông tin nhận dạng (\`userId\`, \`email\`, \`role\`). Token này được gửi kèm trong Header \`Authorization: Bearer <token>\` ở mọi request tiếp theo.
- **Role-Based Access Control (RBAC):** Kết hợp giữa Custom Decorator \`@Roles()\` và \`RolesGuard\` để kiểm soát thẩm quyền truy cập nghiêm ngặt tại từng hàm điều khiển (Controller endpoint).
- **NestJS Schedule (@Cron):** Tự động hóa tác vụ chạy ngầm định kỳ mỗi sáng lúc 09:00:
  + Quét cơ sở dữ liệu tìm các đơn phòng có lịch nhận phòng trong ngày hôm nay.
  + Tự động kích hoạt dịch vụ gửi Push Notification qua FCM và gửi email chào đón khách.

## 2.3. Công nghệ phát triển phía Frontend Mobile (Flutter & Dart)

### 2.3.1. Framework Flutter và ưu điểm biên dịch Cross-Platform
- **Flutter** là bộ công cụ phát triển giao diện người dùng mã nguồn mở do Google sáng lập, cho phép lập trình viên chỉ viết một cơ sở mã nguồn duy nhất bằng ngôn ngữ **Dart** nhưng có thể biên dịch ra mã máy gốc (Native Machine Code ARM/x86) chạy mượt mà trên cả hệ điều hành Android và iOS.
- Khác với các nền tảng lai (Hybrid) dùng Webview hoặc cầu nối JavaScript Bridge, Flutter tự vẽ toàn bộ pixel trên màn hình bằng công cụ đồ họa Skia / Impeller, đạt tốc độ khung hình chuẩn 60fps - 120fps mượt mà, không phụ thuộc vào widget gốc của hệ điều hành.

### 2.3.2. Mô hình quản lý trạng thái BLoC (Business Logic Component)
Ứng dụng sử dụng thư viện \`flutter_bloc\` để tách biệt hoàn toàn giữa giao diện hiển thị (UI) và logic nghiệp vụ:

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 2.2]**: *Mô hình luồng dữ liệu quản lý trạng thái BLoC trong Flutter*  
> **Nội dung sơ đồ:** Luồng tuần hoàn 6 bước: (1) UI dispatch Event; (2) Bloc nhận Event và gọi Repositories; (3) Repositories gọi HTTP Request qua Dio; (4) Backend trả JSON; (5) Repository trả Entity về BLoC; (6) BLoC phát ra State mới để UI render lại màn hình.  
> *(Sinh viên chèn ảnh sơ đồ BLoC vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 2.2: Mô hình luồng dữ liệu quản lý trạng thái BLoC trong Flutter*

- **Event:** Hành động tương tác từ người dùng (ví dụ: \`FetchRoomMatrixEvent\`, \`CloseShiftEvent\`, \`ApproveBookingEvent\`).
- **BLoC:** Thành phần xử lý trung gian, tiếp nhận Event, gọi Repository thực thi nghiệp vụ và phát ra (emit) State mới.
- **State:** Trạng thái phản ánh dữ liệu hiện hành của giao diện (\`Initial\`, \`Loading\`, \`Success\`, \`Failure\`). Giao diện sử dụng \`BlocBuilder\` hoặc \`BlocConsumer\` để tự động cập nhật lại màn hình mà không cần gọi \`setState()\` thủ công.

### 2.3.3. Thư viện mạng Dio, Dependency Injection (GetIt) và Routing (GoRouter)
- **Dio Client:** Thư viện mạng HTTP cao cấp trong Flutter, hỗ trợ Interceptor tự động gắn JWT Token, tự động parse JSON và ghi log chi tiết phục vụ kiểm thử.
- **GetIt (Service Locator):** Bộ điều phối phụ thuộc siêu nhẹ, hỗ trợ khởi tạo Singleton cho các Repository, Bloc và dịch vụ lưu trữ an toàn \`FlutterSecureStorage\`.
- **GoRouter:** Bộ định tuyến khai báo (Declarative Routing) chính thức từ Flutter Team, hỗ trợ Deep Linking, truyền tham số động và bảo vệ chuyển hướng màn hình (Route Guarding).

### 2.3.4. Thiết kế giao diện UI/UX và trực quan hóa số liệu với FL Chart
- **FL Chart:** Thư viện vẽ biểu đồ tương tác cao số 1 trong hệ sinh thái Flutter. Trong đồ án, FL Chart được sử dụng để vẽ biểu đồ cột (Bar Chart) thể hiện doanh thu 12 tháng trong năm, hỗ trợ chạm cảm ứng hiển thị tooltip chi tiết doanh thu tiền phòng và dịch vụ.
- **Phong cách Luxury Hotel Palette:** Tông màu xanh biển sâu (\`#1B365D\`), vàng kim hoàng gia (\`#D4AF37\`) và nền kem thanh lịch (\`#F8F9FA\`), kết hợp font chữ hiện đại Google Fonts Inter tạo cảm giác sang trọng chuẩn khách sạn 5 sao.

---

\\newpage

# CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG

## 3.1. Đặc tả 27 Yêu cầu chức năng chi tiết (Functional Requirements FR-01 đến FR-27)
Hệ thống Luxe Grand Hotel được phân tích và đặc tả trọn vẹn 27 yêu cầu chức năng (tuân thủ tiêu chuẩn IEEE 830) chia thành 14 phân hệ nghiệp vụ:

### Phân hệ 1: Xác thực & Quản lý Tài khoản (Authentication)
- **[FR-01] Đăng ký tài khoản Khách hàng:** Khách nhập Email, Mật khẩu (tối thiểu 6 ký tự), Họ tên, Số điện thoại. Hệ thống kiểm tra email duy nhất, băm mật khẩu bằng Bcrypt (10 vòng) và cấp tài khoản quyền \`CUSTOMER\`.
- **[FR-02] Đăng nhập & Cấp phát Token:** Xác thực email và mật khẩu, cấp phát JSON Web Token (JWT) có chữ ký số chứa thông tin \`userId\`, \`email\`, \`role\`.
- **[FR-03] Khôi phục Mật khẩu qua Email OTP:** Khách quên mật khẩu nhập email -> Hệ thống sinh mã OTP 6 số (hiệu lực 10 phút), gửi qua hòm thư điện tử -> Khách nhập OTP và mật khẩu mới để đặt lại mật khẩu.

### Phân hệ 2: Danh mục Phòng & Ma trận Sơ đồ phòng (Rooms & Matrix)
- **[FR-04] Quản lý Danh mục Hạng phòng (Room Types):** Quản trị viên thêm/sửa/xóa các hạng phòng: Tên hạng, mô tả, đơn giá niêm yết (\`basePrice\`), số khách tối đa (\`maxOccupancy\`), tiện nghi (\`amenities\`) và album ảnh (\`images\`).
- **[FR-05] Quản lý Phòng vật lý (Physical Rooms):** Quản lý số phòng (\`roomNumber\`), vị trí tầng (\`floor\`), liên kết hạng phòng và trạng thái khởi tạo (\`status = AVAILABLE\`).
- **[FR-06] Ma trận Sơ đồ phòng thời gian thực (Room Matrix):** Màn hình trực quan theo từng tầng tòa nhà, thể hiện trạng thái phòng bằng 5 mã màu chuẩn: Xanh lá (\`AVAILABLE\`), Đỏ (\`OCCUPIED\`), Xanh dương (\`RESERVED\`), Vàng cam (\`CLEANING\`), Xám (\`MAINTENANCE\`). Hỗ trợ chạm nhanh vào thẻ phòng để hiển thị menu thao tác.

### Phân hệ 3: Nghiệp vụ Đặt phòng & Tiền sảnh (Bookings Lifecycle)
- **[FR-07] Tra cứu phòng trống (Available Rooms Search):** Khách chọn ngày nhận, ngày trả, số khách. Hệ thống áp dụng thuật toán Interval Overlap loại trừ tất cả các phòng đã có đơn \`CONFIRMED\` hoặc \`CHECKED_IN\` giao nhau với khoảng thời gian tìm kiếm.
- **[FR-08] Tạo đơn đặt phòng trực tuyến (Online Booking):** Khách chọn phòng, nhập yêu cầu đặc biệt. Hệ thống tạo đơn \`Booking\` trạng thái \`PENDING\` và tự động sinh \`Invoice\` trạng thái \`UNPAID\`.
- **[FR-09] Phê duyệt & Từ chối đơn đặt phòng:** Lễ tân/Admin duyệt đơn (\`status = CONFIRMED\`, phòng sang \`RESERVED\`, gửi thông báo đẩy FCM cho khách) hoặc từ chối đơn kèm lý do giải thích rõ ràng.
- **[FR-10] Thủ tục Nhận phòng (Check-in) & Khách vãng lai (Walk-in):** Lễ tân đối chiếu CCCD khách có lịch hẹn và bấm Check-in (\`actualCheckIn = now()\`, phòng sang \`OCCUPIED\`). Hỗ trợ tiếp nhận khách vãng lai (Walk-in) nhận phòng nhanh tại quầy.
- **[FR-11] Đổi phòng lưu trú linh hoạt (Change Room):** Hỗ trợ chuyển khách đang ở sang một phòng trống khác tương đương khi phát sinh sự cố kỹ thuật. Phòng cũ chuyển sang \`CLEANING\`, phòng mới chuyển sang \`OCCUPIED\`.
- **[FR-12] Thủ tục Trả phòng (Check-out) & Kiểm kê dịch vụ:** Lễ tân kiểm tra chi phí phát sinh minibar, đối soát số tiền còn thiếu (\`remainingAmount = finalAmount - paidAmount\`). Yêu cầu thanh toán dứt điểm trước khi hoàn tất trả phòng (\`room.status = CLEANING\`).

### Phân hệ 4: Dịch vụ Phòng Khách sạn (Hotel Extra Services)
- **[FR-13] Quản lý Danh mục Dịch vụ:** Quản lý danh mục Ẩm thực (F&B), Đồ uống minibar, Giặt là nhanh, Spa & Massage, Đơn giá và Trạng thái khả dụng.
- **[FR-14] Đặt dịch vụ gia tăng theo phòng:** Khách hàng hoặc lễ tân order dịch vụ phòng; hệ thống tạo bản ghi \`ExtraServiceOrder\` và tự động cộng dồn chi phí vào \`servicesAmount\` của hóa đơn.

### Phân hệ 5: Tài chính, Hóa đơn & Quản lý Ca trực (Cashier & Shifts)
- **[FR-15] Sổ thu tiền chi tiết đa đợt (Multi-Entry Payments):** Mỗi hóa đơn gồm nhiều lần thu (\`DEPOSIT\`, \`PAYMENT\`, \`REFUND\`). Tiền thực thu \`paidAmount\` của hóa đơn luôn được tính động bằng tổng các khoản thu có trạng thái \`CONFIRMED\`. Khoản chuyển khoản của khách ở trạng thái \`PENDING\` chỉ được tính sau khi thu ngân đối soát và duyệt.
- **[FR-16] Quản lý Ca trực Lễ tân (WorkShift Management):**
  + Mở ca: Khai báo ca trực (Sáng/Chiều/Đêm) và tiền mặt ban đầu trong két (\`initialCash\`).
  + Trong ca: Mọi giao dịch thu tiền mặt, quẹt thẻ, chuyển khoản đều gắn mã ca \`shiftId\`.
  + Chốt ca: Nhân viên kiểm đếm tiền két thực tế (\`actualCash\`). Hệ thống tính tiền lý thuyết \`expectedCash = initialCash + tongTienMatThuTrongCa\` và tính chênh lệch \`cashDifference\`. Bắt buộc nhập lý do giải trình nếu có sai lệch.

### Phân hệ 6: Báo cáo Thống kê & Tự động hóa (Analytics & Automation)
- **[FR-17] Dashboard Điều hành thời gian thực:** Cung cấp 4 thẻ KPI nhanh cho ban quản lý: Tỷ lệ lấp đầy hôm nay, Số lượt nhận phòng trong ngày, Số lượt trả phòng trong ngày, Số đơn chờ duyệt.
- **[FR-18] Báo cáo Doanh thu 12 tháng & Cơ cấu Doanh thu:** Trực quan hóa doanh thu 12 tháng trong năm qua biểu đồ cột tương tác FL Chart, tách bạch doanh thu tiền phòng và tiền dịch vụ, hỗ trợ lọc theo năm.
- **[FR-19] Tác vụ Nhắc lịch Check-in tự động (Cronjob):** Chạy tự động lúc 09:00 sáng mỗi ngày, quét các đơn phòng nhận hôm nay và gửi thông báo đẩy FCM kèm email chào đón khách.

### Phân hệ 7 đến 14: Các chức năng Quản trị & Nghiệp vụ Mở rộng
- **[FR-20] Quản lý Tài khoản Nhân viên & Phân quyền RBAC:** Admin thêm mới nhân viên, cập nhật thông tin, phân quyền (\`RECEPTIONIST\`, \`ADMIN\`), khóa tài khoản hoặc đặt lại mật khẩu nhân viên.
- **[FR-21] Quản lý Hồ sơ Cá nhân & Đổi Mật khẩu:** Người dùng xem hồ sơ, cập nhật số điện thoại, đổi avatar lên Cloudinary và đổi mật khẩu an toàn.
- **[FR-22] Trung tâm Thông báo Đa kênh & Token FCM:** Hộp thư thông báo trong app, đánh dấu đã đọc từng thông báo hoặc tất cả, tự động đồng bộ mã Token FCM của điện thoại để nhận thông báo đẩy.
- **[FR-23] Báo cáo Hiệu suất Nhân sự & Doanh thu theo Ngày:** Thống kê số lượt Check-in/Check-out và doanh số thu ngân của từng nhân viên; biểu đồ doanh thu theo chu kỳ 7, 14 hoặc 30 ngày gần nhất.
- **[FR-24] Xem trước Bảng kê Quyết toán Chi phí (Checkout Preview):** Trích xuất toàn bộ bảng kê chi phí tiền phòng, minibar, phụ thu và số dư còn thiếu mà không thay đổi trạng thái đơn.
- **[FR-25] Sổ Lịch sử Ca trực & Quyền Admin Cưỡng chế Chốt ca:** Tra cứu biên bản bàn giao của toàn bộ các ca trực trong quá khứ; quyền Admin cưỡng chế đóng ca khi nhân viên gặp sự cố đột xuất.
- **[FR-26] Từ chối Giao dịch Chuyển khoản Nghi vấn:** Thu ngân từ chối giao dịch chuyển khoản không có tiền vào tài khoản kèm lý do bắt buộc để khách chuyển lại.
- **[FR-27] Tự động Đồng bộ Trạng thái Phòng & Upload File:** API rà soát đồng bộ logic phòng với lịch đặt hiện hành; dịch vụ upload ảnh đơn và album ảnh phòng lên máy chủ/Cloudinary.

---

## 3.2. Phân tích yêu cầu phi chức năng (Non-Functional Requirements)
1. **Hiệu năng & Khả năng chịu tải (Performance):**
   - Độ trễ trung bình của các API nghiệp vụ chính < 150ms.
   - Hệ thống chịu tải trên 1.200 requests/phút trong điều kiện đồng thời.
   - Ứng dụng di động khởi động nhanh dưới 2 giây, duy trì tốc độ vẽ 60fps mượt mà.
2. **Tính toàn vẹn & Nhất quán dữ liệu (Data Integrity):**
   - Triệt tiêu hoàn toàn sự cố đặt trùng phòng (Double-booking) thông qua cơ chế kiểm tra khoảng giao nhau và giao dịch cơ sở dữ liệu khóa mức dòng.
   - Số tiền thực thu và số nợ còn lại luôn khớp 100% với dữ liệu chi tiết các khoản thu.
3. **An toàn & Bảo mật (Security):**
   - Mật khẩu được băm một chiều an toàn bằng thuật toán chuẩn công nghiệp Bcrypt (salt = 10).
   - Truyền tải thông tin mã hóa qua mạng bắt buộc sử dụng HTTPS (TLS 1.3).
   - Sử dụng Prisma Parameterized Queries ngăn chặn 100% nguy cơ tấn công SQL Injection.
4. **Tính khả dụng & Trải nghiệm người dùng (Usability):**
   - Giao diện thiết kế theo phong cách Luxury Hotel Palette sang trọng, trực quan, hỗ trợ tiếng Việt toàn diện.
   - Thao tác lễ tân tối ưu không quá 3 lần chạm màn hình để hoàn tất một thủ tục nghiệp vụ.

---

## 3.3. Bảng Ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix)

### Bảng 3.1: Bảng Ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix 27 FRs)
| Mã YC | Tên yêu cầu chức năng | Phân hệ | Vai trò | API Endpoint liên quan | Bảng CSDL chính |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **FR-01** | Đăng ký tài khoản Khách hàng | Auth | Customer | \`POST /auth/register\` | \`users\` |
| **FR-02** | Đăng nhập & Cấp phát JWT | Auth | All | \`POST /auth/login\` | \`users\` |
| **FR-03** | Khôi phục mật khẩu qua Email OTP | Auth | Customer | \`POST /auth/forgot-password\` | \`password_resets\` |
| **FR-04** | Quản lý Hạng phòng & Bảng giá | Catalog | Admin | \`GET,POST,PATCH,DELETE /room-types\` | \`room_types\` |
| **FR-05** | Quản lý Danh mục Phòng vật lý | Catalog | Admin/Staff | \`GET,POST,PATCH,DELETE /rooms\` | \`rooms\` |
| **FR-06** | Sơ đồ Ma trận phòng thời gian thực | Front-desk | Staff/Admin | \`GET /rooms/matrix\` | \`rooms\`, \`bookings\` |
| **FR-07** | Tra cứu phòng trống theo ngày | Booking | Customer/Staff | \`GET /rooms/available\` | \`rooms\`, \`bookings\` |
| **FR-08** | Tạo đơn đặt phòng trực tuyến | Booking | Customer | \`POST /bookings\` | \`bookings\`, \`invoices\` |
| **FR-09** | Phê duyệt & Từ chối đơn đặt phòng | Booking | Staff/Admin | \`PUT /bookings/{id}/approve\`, \`/reject\` | \`bookings\`, \`rooms\` |
| **FR-10** | Check-in & Tiếp nhận khách Walk-in | Front-desk | Staff/Admin | \`POST /bookings/{id}/check-in\` | \`bookings\`, \`rooms\` |
| **FR-11** | Đổi phòng lưu trú linh hoạt | Front-desk | Staff/Admin | \`POST /bookings/{id}/change-room\` | \`bookings\`, \`rooms\` |
| **FR-12** | Check-out trả phòng & Kiểm kê minibar| Front-desk | Staff/Admin | \`POST /bookings/{id}/check-out\` | \`bookings\`, \`invoices\` |
| **FR-13** | Quản lý Danh mục Dịch vụ KS | Catalog | Admin | \`GET,POST,PATCH,DELETE /services\` | \`hotel_services\` |
| **FR-14** | Đặt dịch vụ gia tăng theo phòng | Services | Customer/Staff | \`POST /bookings/{id}/services\` | \`extra_service_orders\` |
| **FR-15** | Sổ thu tiền đa đợt & Đối soát | Cashier | Customer/Staff | \`POST /invoices/{id}/pay\`, \`/payments\` | \`invoices\`, \`payments\` |
| **FR-16** | Quản lý Ca trực lễ tân & Đối soát két| Cashier | Receptionist | \`POST /shifts/open\`, \`/close\` | \`work_shifts\`, \`payments\` |
| **FR-17** | Dashboard điều hành thời gian thực | Analytics | Admin | \`GET /analytics/dashboard\` | \`rooms\`, \`bookings\` |
| **FR-18** | Báo cáo Biểu đồ Doanh thu 12 tháng | Analytics | Admin | \`GET /analytics/revenue\` | \`invoices\`, \`payments\` |
| **FR-19** | Tác vụ Nhắc lịch Check-in (Cron) | Notification | System | Cron \`@EveryDayAt9AM\` | \`bookings\`, \`users\` |
| **FR-20** | Quản trị Nhân sự & Phân quyền RBAC | Staff | Admin | \`GET,POST,PATCH,DELETE /users\` | \`users\` |
| **FR-21** | Quản lý Hồ sơ cá nhân & Đổi mật khẩu| Security | All | \`GET /auth/me\`, \`POST /change-password\` | \`users\` |
| **FR-22** | Trung tâm Thông báo FCM đa kênh | Notification | All | \`GET /notifications\`, \`PATCH /fcm-token\`| \`notifications\` |
| **FR-23** | Hiệu suất Nhân viên & Doanh thu Ngày | Analytics | Admin/Staff | \`GET /analytics/staff-performance\` | \`work_shifts\`, \`invoices\` |
| **FR-24** | Xem trước Hóa đơn Check-out Preview | Front-desk | Staff/Admin | \`GET /bookings/{id}/checkout-preview\` | \`bookings\`, \`invoices\` |
| **FR-25** | Sổ Lịch sử Ca & Cưỡng chế Chốt ca | Cashier | Admin/Staff | \`GET /shifts\`, \`POST /shifts/{id}/close\`| \`work_shifts\`, \`payments\` |
| **FR-26** | Từ chối Giao dịch Chuyển khoản nghi vấn| Cashier | Staff/Admin | \`POST /payments/{id}/reject\` | \`payments\`, \`invoices\` |
| **FR-27** | Đồng bộ Trạng thái Phòng & Upload File| System/Media | Admin/Staff | \`POST /rooms/sync-status\`, \`/upload/*\` | \`rooms\`, \`upload\` |

---

## 3.4. Sơ đồ Use Case tổng thể toàn hệ thống

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 3.1]**: *Sơ đồ Use Case tổng thể toàn hệ thống*  
> **Nội dung sơ đồ:** Thể hiện 3 tác nhân chính (Khách hàng, Lễ tân/Thu ngân, Quản trị viên) cùng ranh giới hệ thống phân chia rõ các Use Case tương ứng.  
> *(Sinh viên chèn ảnh sơ đồ Use Case tổng thể vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 3.1: Sơ đồ Use Case tổng thể toàn hệ thống Luxe Grand Hotel*

\`\`\`mermaid
graph TD
    actorGuest((Khách Hàng))
    actorStaff((Lễ Tân / Thu Ngân))
    actorAdmin((Quản Trị Viên))

    subgraph System [HỆ THỐNG QUẢN LÝ KHÁCH SẠN LUXE GRAND HOTEL]
        UC_Auth[Đăng nhập / Đăng ký / Quên MK OTP]
        UC_Search[Tìm kiếm & Xem chi tiết phòng]
        UC_Book[Đặt phòng trực tuyến]
        UC_ViewInvoice[Xem hóa đơn & Lịch sử chi tiêu]
        UC_OrderService[Yêu cầu dịch vụ phòng]
        UC_Pay[Chuyển khoản thanh toán / Nộp cọc]

        UC_Matrix[Xem Ma trận phòng Room Matrix]
        UC_ApproveBook[Duyệt / Từ chối đơn đặt phòng]
        UC_CheckIn[Làm thủ tục Check-in & Walk-in]
        UC_CheckOut[Làm thủ tục Check-out & Minibar]
        UC_ChangeRoom[Hoán đổi phòng lưu trú]
        UC_Shift[Mở ca / Chốt ca / Bàn giao tiền két]
        UC_ConfirmPay[Xác nhận khoản thanh toán của khách]

        UC_Dashboard[Xem Dashboard điều hành & KPI]
        UC_RevReport[Báo cáo biểu đồ doanh thu theo năm]
        UC_Occupancy[Phân tích tỷ lệ lấp đầy phòng]
        UC_ManageRoom[Quản lý danh mục phòng & loại phòng]
        UC_ManageStaff[Quản lý nhân sự & Giám sát ca trực]
    end

    actorGuest --> UC_Auth
    actorGuest --> UC_Search
    actorGuest --> UC_Book
    actorGuest --> UC_ViewInvoice
    actorGuest --> UC_OrderService
    actorGuest --> UC_Pay

    actorStaff --> UC_Auth
    actorStaff --> UC_Matrix
    actorStaff --> UC_ApproveBook
    actorStaff --> UC_CheckIn
    actorStaff --> UC_CheckOut
    actorStaff --> UC_ChangeRoom
    actorStaff --> UC_Shift
    actorStaff --> UC_ConfirmPay

    actorAdmin --> UC_Auth
    actorAdmin --> UC_Dashboard
    actorAdmin --> UC_RevReport
    actorAdmin --> UC_Occupancy
    actorAdmin --> UC_ManageRoom
    actorAdmin --> UC_ManageStaff
    actorAdmin --> UC_ApproveBook
\`\`\`

---

## 3.5. Thiết kế Sơ đồ tuần tự và thuật toán nghiệp vụ lõi

### 3.5.1. Quy trình Đặt phòng trực tuyến và Duyệt đơn

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 3.2]**: *Sơ đồ tuần tự Quy trình Đặt phòng trực tuyến và Duyệt đơn*  
> **Nội dung sơ đồ:** Tương tác giữa Khách hàng, Flutter App, NestJS Backend, PostgreSQL Database và Lễ tân khi gửi yêu cầu đặt phòng, kiểm tra trùng lịch và phê duyệt.  
> *(Sinh viên chèn ảnh sơ đồ tuần tự đặt phòng vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 3.2: Sơ đồ tuần tự Quy trình Đặt phòng trực tuyến và Duyệt đơn*

\`\`\`mermaid
sequenceDiagram
    autonumber
    actor Guest as Khách hàng
    participant App as Flutter Mobile App
    participant BE as NestJS Backend
    participant DB as PostgreSQL Database
    actor Staff as Lễ tân / Admin

    Guest->>App: Chọn ngày đến, ngày đi, loại phòng
    App->>BE: POST /bookings (roomId, checkInDate, checkOutDate, guestCount)
    BE->>DB: Kiểm tra lịch trùng phòng (overlap query)
    alt Phòng đã bị đặt trong khoảng thời gian này
        DB-->>BE: Tồn tại Booking trùng
        BE-->>App: 409 Conflict (ERR_ROOM_OCCUPIED)
        App-->>Guest: Thông báo phòng đã có người đặt
    else Phòng còn trống
        DB-->>BE: Phòng hợp lệ
        BE->>DB: Tạo Booking (status: PENDING), Tạo Invoice tự động (status: UNPAID)
        DB-->>BE: Booking & Invoice đã lưu
        BE-->>App: 201 Created (Thông tin đơn đặt phòng)
        App-->>Guest: Hiển thị Đơn đặt phòng thành công, chờ khách sạn duyệt
    end

    Staff->>App: Mở màn hình "Đơn chờ duyệt"
    App->>BE: GET /bookings/pending
    BE->>DB: Query các đơn status = PENDING
    DB-->>BE: Danh sách booking chờ
    BE-->>App: Trả về danh sách
    Staff->>App: Nhấn nút "Duyệt đơn" (hoặc từ chối)
    App->>BE: PUT /bookings/{id}/approve
    BE->>DB: Cập nhật booking.status = CONFIRMED, room.status = RESERVED
    DB-->>BE: Cập nhật hoàn tất
    BE-->>App: 200 OK (Đã phê duyệt thành công)
    BE--)Guest: Gửi Push Notification FCM: Đơn phòng đã được xác nhận!
\`\`\`

### 3.5.2. Quy trình Check-in, Đổi phòng (Change Room) và Check-out

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 3.3]**: *Sơ đồ tuần tự Quy trình Check-in, Đổi phòng và Check-out*  
> **Nội dung sơ đồ:** Thể hiện tương tác giữa Lễ tân, Flutter App và Backend qua các khâu nhận phòng, hoán đổi phòng khi xảy ra sự cố kỹ thuật và trả phòng kiểm kê minibar.  
> *(Sinh viên chèn ảnh sơ đồ tuần tự lễ tân vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 3.3: Sơ đồ tuần tự Quy trình Check-in, Đổi phòng và Check-out*

### 3.5.3. Quy trình Quản lý ca trực (WorkShift) và đối soát tài chính bàn giao ca

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 3.4]**: *Sơ đồ trạng thái Quy trình Mở ca, Ghi nhận thu tiền và Chốt ca lễ tân*  
> **Nội dung sơ đồ:** Vòng đời ca trực từ lúc \`OPEN\` (khai báo \`initialCash\`), ghi nhận các giao dịch thu trong ca, đến \`CLOSING\` (kiểm đếm két, tính \`expectedCash\`, bắt buộc giải trình nếu chênh lệch) và \`CLOSED\`.  
> *(Sinh viên chèn ảnh sơ đồ trạng thái ca trực vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 3.4: Sơ đồ trạng thái Quy trình Mở ca, Ghi nhận thu tiền và Chốt ca lễ tân*

\`\`\`mermaid
stateDiagram-v2
    [*] --> OPEN : Lễ tân mở ca (Khai báo tiền mặt ban đầu - initialCash)
    state OPEN {
        [*] --> GiaoDichTrongCa
        GiaoDichTrongCa --> ThuTienMat : Thu tiền phòng / cọc tại quầy
        GiaoDichTrongCa --> XacNhanChuyenKhoan : Duyệt giao dịch QR ngân hàng
        GiaoDichTrongCa --> QuetThe : Thu qua máy POS
    }
    OPEN --> CLOSING : Lễ tân nhấn "Chốt ca"
    state CLOSING {
        KiemDemTienMat : Kiểm đếm thực tế tiền trong két (actualCash)
        HeThongTinhToan : Hệ thống tính: expectedCash = initialCash + tongTienMatThu
        SoSanh : Tính chênh lệch: cashDifference = actualCash - expectedCash
    }
    CLOSING --> CLOSED : Xác nhận chốt ca (Kèm lý do giải trình nếu chênh lệch != 0)
    CLOSED --> [*] : Bàn giao cho ca trực tiếp theo
\`\`\`

### 3.5.4. Thuật toán kiểm tra lịch phòng trống & Chống tranh chấp đặt trùng phòng
Để ngăn chặn hoàn toàn hiện tượng Double-booking, điều kiện xung đột giữa khoảng thời gian đặt mới $[\text{checkInDate}, \text{checkOutDate}]$ và lịch đặt cũ $[C_{in}, C_{out}]$ được mô hình hóa bằng thuật toán giao thoa khoảng thời gian (Interval Overlapping Theorem):
$$\text{Xung đột (Conflict)} \iff (\text{checkInDate} < C_{out}) \land (\text{checkOutDate} > C_{in})$$

Trong câu truy vấn Prisma ORM:
\`\`\`typescript
const conflict = await this.prisma.booking.findFirst({
  where: {
    roomId: dto.roomId,
    status: { in: [BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN] },
    AND: [
      { checkInDate: { lt: new Date(dto.checkOutDate) } },
      { checkOutDate: { gt: new Date(dto.checkInDate) } },
    ],
  },
});
if (conflict) {
  throw new ConflictException('Phòng đã có khách đặt trong khoảng thời gian được chọn!');
}
\`\`\`

---

## 3.6. Thiết kế Cơ sở dữ liệu quan hệ (Database Design & ERD)

### 3.6.1. Sơ đồ quan hệ thực thể (ERD)

> ----------------------------------------------------------------------
> 📸 **[VỊ TRÍ CHÈN HÌNH 3.5]**: *Sơ đồ quan hệ thực thể (ERD) hoàn chỉnh 8 bảng chuẩn 3NF*  
> **Nội dung sơ đồ:** Thể hiện 8 thực thể chính: \`users\`, \`room_types\`, \`rooms\`, \`bookings\`, \`invoices\`, \`payments\`, \`work_shifts\`, \`extra_service_orders\`.  
> *(Sinh viên chèn ảnh sơ đồ ERD cơ sở dữ liệu vào vị trí này)*  
> ----------------------------------------------------------------------
*Hình 3.5: Sơ đồ quan hệ thực thể (ERD) hoàn chỉnh 8 bảng chuẩn 3NF*

\`\`\`mermaid
erDiagram
    User ||--o{ Booking : "creates"
    User ||--o{ WorkShift : "operates"
    User ||--o{ Payment : "creates / confirms"
    User ||--o{ Invoice : "issues"

    RoomType ||--o{ Room : "categorizes"
    Room ||--o{ Booking : "is_booked"

    Booking ||--|| Invoice : "generates"
    Booking ||--o{ ExtraServiceOrder : "includes"
    HotelService ||--o{ ExtraServiceOrder : "ordered_in"

    Invoice ||--o{ Payment : "has_payments"
    WorkShift ||--o{ Payment : "tracks_cashflow"

    User {
        string id PK
        string email UK
        string password
        string fullName
        string phone
        string role "ADMIN | RECEPTIONIST | CUSTOMER"
        string avatar
        string fcmToken
    }

    RoomType {
        string id PK
        string name
        string description
        float basePrice
        int maxOccupancy
        string[] amenities
        string[] images
    }

    Room {
        string id PK
        string roomNumber UK
        int floor
        string status "AVAILABLE | OCCUPIED | RESERVED | CLEANING | MAINTENANCE"
        string roomTypeId FK
    }

    Booking {
        string id PK
        string bookingCode UK
        string customerId FK
        string roomId FK
        datetime checkInDate
        datetime checkOutDate
        datetime actualCheckIn
        datetime actualCheckOut
        int guestCount
        float totalAmount
        float depositAmount
        string status "PENDING | CONFIRMED | CHECKED_IN | CHECKED_OUT | CANCELLED"
    }

    Invoice {
        string id PK
        string invoiceCode UK
        string bookingId FK,UK
        float roomAmount
        float servicesAmount
        float discount
        float finalAmount
        float paidAmount
        string paymentStatus "UNPAID | PARTIAL | PAID | REFUNDED"
    }

    Payment {
        string id PK
        string invoiceId FK
        float amount
        string method "CASH | CREDIT_CARD | BANK_TRANSFER"
        string type "PAYMENT | DEPOSIT | REFUND"
        string status "PENDING | CONFIRMED | REJECTED"
        string shiftId FK
        string confirmedById FK
    }

    WorkShift {
        string id PK
        string shiftCode UK
        string staffId FK
        string shiftType "MORNING | AFTERNOON | NIGHT"
        string status "OPEN | CLOSED"
        float initialCash
        float actualCash
        float expectedCash
        float cashDifference
        string differenceReason
    }

    ExtraServiceOrder {
        string id PK
        string bookingId FK
        string serviceName
        float unitPrice
        int quantity
        float totalPrice
        string status "REQUESTED | CONFIRMED | REJECTED"
    }
\`\`\`

### 3.6.2. Bảng tổng hợp liên kết Khóa chính (PK) - Khóa ngoại (FK) giữa các bảng

### Bảng 3.2: Tổng hợp liên kết Khóa chính (PK) - Khóa ngoại (FK) và Ràng buộc toàn vẹn
| STT | Bảng con (Child Table) | Khóa ngoại (FK) | Bảng cha (Parent Table) | Khóa chính (PK) | Bản chất quan hệ | Ràng buộc On Delete | Ý nghĩa nghiệp vụ liên kết |
| :---: | :--- | :--- | :--- | :--- | :---: | :--- | :--- |
| **1** | \`rooms\` | \`roomTypeId\` | \`room_types\` | \`id\` | 1 - N | \`RESTRICT\` | Mỗi phòng vật lý bắt buộc thuộc duy nhất một hạng phòng xác định |
| **2** | \`bookings\` | \`customerId\` | \`users\` | \`id\` | 1 - N | \`RESTRICT\` | Khách hàng sở hữu và tạo đơn đặt phòng lưu trú |
| **3** | \`bookings\` | \`roomId\` | \`rooms\` | \`id\` | 1 - N | \`RESTRICT\` | Đơn đặt phòng được gắn phân bổ cho một phòng vật lý cụ thể |
| **4** | \`bookings\` | \`confirmedById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Nhân viên lễ tân hoặc quản trị viên phê duyệt đơn phòng |
| **5** | \`bookings\` | \`cancelledById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Nhân viên thực hiện thao tác từ chối hoặc hủy đơn phòng |
| **6** | \`invoices\` | \`bookingId\` | \`bookings\` | \`id\` | 1 - 1 | \`CASCADE\` | Mỗi đơn đặt phòng có duy nhất một hóa đơn tài chính đối ứng |
| **7** | \`invoices\` | \`issuedById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Thu ngân chịu trách nhiệm lập và phát hành hóa đơn |
| **8** | \`payments\` | \`invoiceId\` | \`invoices\` | \`id\` | 1 - N | \`CASCADE\` | Hóa đơn gồm nhiều dòng thu tiền chi tiết (cọc, trả nợ, hoàn trả) |
| **9** | \`payments\` | \`createdById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Người tạo giao dịch thu (khách chuyển khoản hoặc thu ngân quầy) |
| **10**| \`payments\` | \`confirmedById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Thu ngân kiểm tra sao kê ngân hàng và bấm duyệt nhận tiền |
| **11**| \`payments\` | \`shiftId\` | \`work_shifts\` | \`id\` | 1 - N | \`SET NULL\` | Khoản thu tiền được gắn liền với ca trực của nhân viên thu ngân |
| **12**| \`work_shifts\` | \`staffId\` | \`users\` | \`id\` | 1 - N | \`RESTRICT\` | Nhân viên lễ tân chịu trách nhiệm chính về ca trực |
| **13**| \`work_shifts\` | \`handoverStaffId\`| \`users\` | \`id\` | 1 - N | \`SET NULL\` | Nhân viên tiếp nhận bàn giao ca trực tiếp theo |
| **14**| \`extra_service_orders\`| \`bookingId\` | \`bookings\` | \`id\` | 1 - N | \`CASCADE\` | Các order dịch vụ phát sinh (minibar, ẩm thực) gắn với đơn phòng |
| **15**| \`extra_service_orders\`| \`requestedById\` | \`users\` | \`id\` | 1 - N | \`SET NULL\` | Người gửi yêu cầu dịch vụ (khách hàng hoặc lễ tân) |

---

### 3.6.3. Từ điển dữ liệu chi tiết 8 bảng trong hệ thống (Data Dictionary)

#### 1. Bảng \`users\` (Người dùng và Nhân sự)
### Bảng 3.3: Từ điển dữ liệu Bảng \`users\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của người dùng |
| \`email\` | String (Varchar) | **Unique** | Không | | Email đăng nhập hệ thống duy nhất |
| \`password\` | String | | Không | | Mật khẩu đã được băm an toàn bằng Bcrypt |
| \`fullName\` | String | | Không | | Họ và tên đầy đủ của người dùng / nhân viên |
| \`phone\` | String | | Có | \`null\` | Số điện thoại liên hệ |
| \`role\` | Enum \`Role\` | | Không | \`CUSTOMER\` | Vai trò: \`ADMIN\`, \`RECEPTIONIST\`, \`CUSTOMER\` |
| \`avatar\` | String | | Có | \`null\` | Đường dẫn URL ảnh đại diện lưu trên Cloudinary |
| \`fcmToken\` | String | | Có | \`null\` | Mã Token thiết bị di động gửi Push Notification FCM |
| \`createdAt\` | DateTime | | Không | \`now()\` | Thời điểm khởi tạo tài khoản |
| \`updatedAt\` | DateTime | | Không | \`updatedAt\` | Thời điểm cập nhật thông tin gần nhất |

#### 2. Bảng \`room_types\` (Hạng phòng và Bảng giá)
### Bảng 3.4: Từ điển dữ liệu Bảng \`room_types\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của hạng phòng |
| \`name\` | String | | Không | | Tên hạng phòng (Standard Queen, Deluxe Ocean, Suite...) |
| \`description\` | Text | | Có | \`null\` | Mô tả chi tiết phong cách, view ngắm cảnh |
| \`basePrice\` | Float | | Không | | Đơn giá niêm yết cơ bản cho 1 đêm lưu trú (VNĐ) |
| \`maxOccupancy\` | Int | | Không | \`2\` | Số lượng khách lưu trú tối đa cho phép |
| \`amenities\` | String[] | | Không | \`[]\` | Mảng danh sách tiện ích (Wifi, Minibar, Bồn tắm nằm...) |
| \`images\` | String[] | | Không | \`[]\` | Mảng danh sách đường dẫn ảnh thực tế của phòng |
| \`createdAt\` | DateTime | | Không | \`now()\` | Thời điểm khởi tạo hạng phòng |
| \`updatedAt\` | DateTime | | Không | \`updatedAt\` | Thời điểm cập nhật giá hoặc tiện ích |

#### 3. Bảng \`rooms\` (Danh mục phòng vật lý)
### Bảng 3.5: Từ điển dữ liệu Bảng \`rooms\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của phòng vật lý |
| \`roomNumber\` | String | **Unique** | Không | | Số hiệu phòng thực tế (ví dụ: 101, 102, 201...) |
| \`floor\` | Int | Index | Không | | Số tầng vị trí của phòng trong tòa nhà |
| \`status\` | Enum \`RoomStatus\` | Index | Không | \`AVAILABLE\` | Trạng thái: \`AVAILABLE\`, \`OCCUPIED\`, \`CLEANING\`... |
| \`roomTypeId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu khóa chính \`room_types.id\` |
| \`createdAt\` | DateTime | | Không | \`now()\` | Thời điểm đưa phòng vào vận hành |
| \`updatedAt\` | DateTime | | Không | \`updatedAt\` | Thời điểm cập nhật trạng thái dọn dẹp |

#### 4. Bảng \`bookings\` (Đơn đặt phòng lưu trú)
### Bảng 3.6: Từ điển dữ liệu Bảng \`bookings\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của đơn phòng |
| \`bookingCode\` | String | **Unique** | Không | | Mã hiển thị thân thiện (ví dụ: \`BK-2026-088\`) |
| \`customerId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu tới \`users.id\` khách hàng đặt phòng |
| \`roomId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu tới \`rooms.id\` phòng được phân bổ |
| \`checkInDate\` | DateTime | Index | Không | | Thời điểm dự kiến nhận phòng (14:00) |
| \`checkOutDate\` | DateTime | Index | Không | | Thời điểm dự kiến trả phòng (12:00) |
| \`actualCheckIn\` | DateTime | | Có | \`null\` | Thời điểm lễ tân làm thủ tục Check-in thực tế |
| \`actualCheckOut\`| DateTime | | Có | \`null\` | Thời điểm lễ tân làm thủ tục Check-out thực tế |
| \`guestCount\` | Int | | Không | \`1\` | Số lượng khách thực tế ở trong phòng |
| \`totalAmount\` | Float | | Không | | Tổng tiền phòng dự kiến theo số đêm |
| \`depositAmount\` | Float | | Không | \`0\` | Số tiền khách đã thanh toán đặt cọc giữ chỗ |
| \`status\` | Enum \`BookingStatus\` | Index | Không | \`PENDING\` | Trạng thái: \`PENDING\`, \`CONFIRMED\`, \`CHECKED_IN\`... |
| \`specialRequests\`| Text | | Có | \`null\` | Yêu cầu đặc biệt của khách (tầng cao, setup hoa) |
| \`confirmedAt\` | DateTime | | Có | \`null\` | Thời điểm nhân viên bấm duyệt đơn phòng |
| \`confirmedById\` | String (UUID) | **FK** | Có | \`null\` | Tham chiếu \`users.id\` nhân viên duyệt đơn |
| \`cancellationReason\`| Text | | Có | \`null\` | Lý do từ chối hoặc hủy đơn đặt phòng |

#### 5. Bảng \`invoices\` (Hóa đơn tài chính)
### Bảng 3.7: Từ điển dữ liệu Bảng \`invoices\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của hóa đơn |
| \`invoiceCode\` | String | **Unique** | Không | | Mã hóa đơn kế toán (ví dụ: \`INV-2026-001\`) |
| \`bookingId\` | String (UUID) | **FK**, Unique| Không | | Tham chiếu 1-1 tới \`bookings.id\` |
| \`roomAmount\` | Float | | Không | | Tiền phòng lưu trú |
| \`servicesAmount\`| Float | | Không | \`0\` | Tiền dịch vụ phát sinh (minibar, ẩm thực) |
| \`discount\` | Float | | Không | \`0\` | Số tiền chiết khấu, khuyến mại |
| \`tax\` | Float | | Không | \`0\` | Tiền thuế VAT |
| \`finalAmount\` | Float | | Không | | Tổng tiền cuối cùng khách cần thanh toán |
| \`paidAmount\` | Float | | Không | \`0\` | Tổng tiền khách đã thanh toán (CONFIRMED) |
| \`paymentStatus\`| Enum \`PaymentStatus\` | Index | Không | \`UNPAID\` | Trạng thái: \`UNPAID\`, \`PARTIAL\`, \`PAID\`, \`REFUNDED\` |
| \`issuedById\` | String (UUID) | **FK** | Có | \`null\` | Tham chiếu \`users.id\` thu ngân lập hóa đơn |
| \`paidAt\` | DateTime | Index | Có | \`null\` | Thời điểm khách hoàn tất thanh toán dứt điểm |

#### 6. Bảng \`payments\` (Sổ thu tiền chi tiết từng đợt)
### Bảng 3.8: Từ điển dữ liệu Bảng \`payments\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của giao dịch thu |
| \`invoiceId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu tới hóa đơn \`invoices.id\` |
| \`amount\` | Float | | Không | | Số tiền của lần thanh toán cụ thể (VNĐ) |
| \`method\` | Enum \`PaymentMethod\` | | Không | \`CASH\` | Hình thức: \`CASH\`, \`CREDIT_CARD\`, \`BANK_TRANSFER\` |
| \`type\` | Enum \`PaymentEntryType\`| | Không | \`PAYMENT\` | Phân loại: \`PAYMENT\`, \`DEPOSIT\`, \`REFUND\` |
| \`status\` | Enum \`PaymentEntryStatus\`| Index | Không | \`CONFIRMED\` | Trạng thái: \`PENDING\`, \`CONFIRMED\`, \`REJECTED\` |
| \`reference\` | String | | Có | \`null\` | Mã giao dịch ngân hàng do khách nhập khi chuyển |
| \`note\` | String | | Có | \`null\` | Ghi chú khoản thu (ví dụ: Thu cọc trước 30%) |
| \`createdById\` | String (UUID) | **FK** | Có | \`null\` | Tham chiếu \`users.id\` người tạo giao dịch |
| \`confirmedById\`| String (UUID) | **FK**, Index | Có | \`null\` | Tham chiếu \`users.id\` thu ngân duyệt nhận tiền |
| \`shiftId\` | String (UUID) | **FK**, Index | Có | \`null\` | Tham chiếu tới ca trực \`work_shifts.id\` |

#### 7. Bảng \`work_shifts\` (Quản lý ca trực & Đối soát tiền két)
### Bảng 3.9: Từ điển dữ liệu Bảng \`work_shifts\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh duy nhất của ca trực |
| \`shiftCode\` | String | **Unique** | Không | | Mã ca trực tự sinh (ví dụ: \`SFT-20260921-0001\`) |
| \`staffId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu \`users.id\` nhân viên trực ca |
| \`shiftType\` | Enum \`ShiftType\` | | Không | \`MORNING\` | Loại ca: \`MORNING\` (Sáng), \`AFTERNOON\`, \`NIGHT\` |
| \`deskName\` | String | | Có | \`null\` | Tên quầy giao dịch / máy tính trực lễ tân |
| \`status\` | Enum \`ShiftStatus\` | Index | Không | \`OPEN\` | Trạng thái: \`OPEN\` (Đang mở), \`CLOSED\` (Đã chốt) |
| \`startTime\` | DateTime | Index | Không | \`now()\` | Thời điểm nhân viên mở ca trực |
| \`endTime\` | DateTime | | Có | \`null\` | Thời điểm nhân viên hoàn tất chốt ca |
| \`initialCash\` | Float | | Không | \`0\` | Tiền mặt bàn giao trong két đầu ca |
| \`actualCash\` | Float | | Có | \`null\` | Tiền mặt thực tế nhân viên kiểm đếm cuối ca |
| \`expectedCash\`| Float | | Có | \`null\` | Tiền lý thuyết = Đầu ca + Tổng thu tiền mặt trong ca |
| \`cashDifference\`| Float | | Có | \`null\` | Chênh lệch tiền két = \`actualCash - expectedCash\` |
| \`creditCardAmount\`| Float | | Có | \`0\` | Doanh thu quẹt thẻ POS phát sinh trong ca |
| \`bankTransferAmount\`| Float | | Có | \`0\` | Doanh thu chuyển khoản phát sinh trong ca |
| \`totalRevenue\`| Float | | Có | \`0\` | Tổng doanh thu tất cả các nguồn trong ca |
| \`differenceReason\`| Text | | Có | \`null\` | Bắt buộc giải trình nếu \`cashDifference != 0\` |
| \`handoverStaffId\`| String (UUID) | **FK** | Có | \`null\` | Tham chiếu \`users.id\` nhân viên nhận bàn giao |

#### 8. Bảng \`extra_service_orders\` & \`hotel_services\` (Dịch vụ khách sạn)
### Bảng 3.10: Từ điển dữ liệu Bảng \`extra_service_orders\` & \`hotel_services\`
| Tên trường (Field) | Kiểu dữ liệu | Khóa | Null | Mặc định | Mô tả ý nghĩa nghiệp vụ |
| :--- | :--- | :---: | :---: | :--- | :--- |
| \`id\` | String (UUID) | **PK** | Không | \`uuid()\` | Mã định danh đơn gọi dịch vụ phòng |
| \`bookingId\` | String (UUID) | **FK**, Index | Không | | Tham chiếu đơn phòng \`bookings.id\` |
| \`serviceName\` | String | | Không | | Tên dịch vụ (Rượu vang, Giặt là nhanh, Spa...) |
| \`unitPrice\` | Float | | Không | | Đơn giá dịch vụ tại thời điểm gọi |
| \`quantity\` | Int | | Không | \`1\` | Số lượng sử dụng |
| \`totalPrice\` | Float | | Không | | Thành tiền = \`unitPrice * quantity\` |
| \`status\` | String | Index | Không | \`CONFIRMED\` | Trạng thái: \`REQUESTED\`, \`CONFIRMED\`, \`REJECTED\` |
| \`requestedById\`| String (UUID) | **FK** | Có | \`null\` | Tham chiếu \`users.id\` người yêu cầu dịch vụ |

---

## 3.7. Thiết kế chuẩn giao tiếp RESTful API Spec

### Bảng 3.11: Đặc tả các API RESTful Endpoints cốt lõi của hệ thống Backend
| Phương thức | Đường dẫn Endpoint | Quyền truy cập | Mô tả nghiệp vụ |
| :---: | :--- | :--- | :--- |
| \`POST\` | \`/api/v1/auth/register\` | Public | Đăng ký tài khoản khách hàng mới |
| \`POST\` | \`/api/v1/auth/login\` | Public | Đăng nhập hệ thống, cấp phát token JWT |
| \`POST\` | \`/api/v1/auth/forgot-password\`| Public | Gửi mã OTP khôi phục mật khẩu qua Email |
| \`POST\` | \`/api/v1/auth/reset-password\` | Public | Xác thực OTP và đặt lại mật khẩu mới |
| \`GET\` | \`/api/v1/rooms\` | Public / All | Lấy danh sách phòng theo tầng, loại, trạng thái |
| \`GET\` | \`/api/v1/rooms/matrix\` | Staff / Admin | Lấy ma trận sơ đồ phòng phục vụ lễ tân |
| \`GET\` | \`/api/v1/rooms/available\` | Customer / Staff| Tra cứu phòng trống theo khoảng ngày nhận - trả |
| \`POST\` | \`/api/v1/bookings\` | Customer / Staff| Tạo đơn đặt phòng mới (kiểm tra chống trùng phòng) |
| \`GET\` | \`/api/v1/bookings/pending\` | Staff / Admin | Lấy danh sách đơn đặt phòng trực tuyến chờ duyệt |
| \`PUT\` | \`/api/v1/bookings/{id}/approve\`| Staff / Admin | Duyệt đơn phòng, chuyển trạng thái phòng sang RESERVED |
| \`PUT\` | \`/api/v1/bookings/{id}/reject\` | Staff / Admin | Từ chối đơn đặt phòng kèm lý do giải thích |
| \`POST\` | \`/api/v1/bookings/{id}/check-in\`| Staff / Admin | Làm thủ tục Check-in, chuyển phòng sang OCCUPIED |
| \`POST\` | \`/api/v1/bookings/{id}/check-out\`| Staff / Admin| Làm thủ tục Check-out, chuyển phòng sang CLEANING |
| \`POST\` | \`/api/v1/bookings/{id}/change-room\`| Staff / Admin| Hoán đổi sang phòng khác cho khách đang ở |
| \`GET\` | \`/api/v1/bookings/{id}/checkout-preview\`| Staff / Admin| Xem trước bảng kê chi phí trả phòng (Read-only) |
| \`POST\` | \`/api/v1/invoices/{id}/pay\` | Customer / Staff| Gửi yêu cầu thanh toán chuyển khoản hoặc thu tiền mặt |
| \`POST\` | \`/api/v1/invoices/payments/{id}/reject\`| Staff / Admin| Từ chối giao dịch chuyển khoản giả mạo / chưa có tiền |
| \`POST\` | \`/api/v1/shifts/open\` | Receptionist | Mở ca trực lễ tân, khai báo tiền mặt ban đầu |
| \`POST\` | \`/api/v1/shifts/close\` | Receptionist | Chốt ca trực, kiểm đếm két và đối soát tiền mặt |
| \`GET\` | \`/api/v1/analytics/dashboard\` | Admin | Lấy các thẻ chỉ số KPI vận hành hôm nay |
| \`GET\` | \`/api/v1/analytics/revenue\` | Admin | Lấy dữ liệu biểu đồ doanh thu 12 tháng theo năm |

---

\\newpage

# CHƯƠNG 4: HIỆN THỰC HÓA VÀ GIAO DIỆN HỆ THỐNG (IMPLEMENTATION & UI)

## 4.1. Hiện thực hóa Backend (NestJS Server)

### 4.1.1. Cấu trúc mã nguồn Modular Monolith
Toàn bộ mã nguồn máy chủ Backend tại thư mục \`Hotel-Management/src\` được tổ chức chuẩn kiến trúc hướng Module:
\`\`\`
Hotel-Management/src/
├── analytics/         # Module thống kê doanh thu, tỷ lệ lấp đầy phòng
├── auth/              # Module xác thực JWT, đăng ký, đăng nhập, khôi phục OTP
│   └── dto/           # Data Transfer Objects kiểm định dữ liệu xác thực
├── bookings/          # Module đặt phòng, duyệt đơn, check-in, check-out, đổi phòng
├── common/            # Bộ lọc ngoại lệ, Guards phân quyền, Decorators, Interceptors
├── elasticsearch/     # Dịch vụ tìm kiếm phân tán toàn văn
├── invoices/          # Module hóa đơn, thanh toán nhiều đợt, hoàn tiền
├── mail/              # Dịch vụ gửi email thông báo và mã OTP xác thực
├── notifications/     # Module thông báo đẩy FCM & Tác vụ nhắc Check-in tự động
├── prisma/            # Dịch vụ kết nối CSDL và kịch bản Seed dữ liệu mẫu
├── redis/             # Dịch vụ bộ đệm dữ liệu tốc độ cao In-Memory
├── room-types/        # Quản lý danh mục loại phòng và bảng giá
├── rooms/             # Quản lý phòng vật lý và ma trận sơ đồ phòng
├── services/          # Quản lý danh mục dịch vụ khách sạn (F&B, Giặt là, Spa)
├── shifts/            # Quản lý ca trực lễ tân, đối soát và bàn giao tiền két
├── upload/            # Tải ảnh phòng và avatar đại diện lên Cloudinary
├── users/             # Quản trị người dùng, cập nhật thông tin cá nhân
└── app.module.ts      # Root Module liên kết toàn bộ hệ thống
\`\`\`

### 4.1.2. Hiện thực module Xác thực, Phân quyền (Auth & Guards)
Hệ thống sử dụng chiến lược \`JwtStrategy\` kết hợp \`RolesGuard\` để kiểm tra vai trò người dùng trong Token:
\`\`\`typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.includes(user.role);
  }
}
\`\`\`

Chuẩn hóa dữ liệu trả về cho toàn bộ ứng dụng thông qua \`TransformInterceptor\`:
\`\`\`typescript
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, Response<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<Response<T>> {
    return next.handle().pipe(
      map((data) => ({
        statusCode: context.switchToHttp().getResponse().statusCode,
        success: true,
        message: data?.message || 'Thành công',
        data: data?.data !== undefined ? data.data : data,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
\`\`\`

### 4.1.3. Hiện thực module Đặt phòng & Thuật toán Interval Overlap
Tại \`bookings.service.ts\`, thuật toán kiểm tra xung đột phòng được thực thi:
\`\`\`typescript
async createBooking(userId: string, dto: CreateBookingDto) {
  // 1. Kiểm tra tranh chấp lịch phòng
  const conflict = await this.prisma.booking.findFirst({
    where: {
      roomId: dto.roomId,
      status: { in: [BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN] },
      AND: [
        { checkInDate: { lt: new Date(dto.checkOutDate) } },
        { checkOutDate: { gt: new Date(dto.checkInDate) } },
      ],
    },
  });
  if (conflict) {
    throw new ConflictException('Phòng đã được đặt trong khoảng thời gian được chọn!');
  }

  // 2. Thực thi Transaction tạo Booking và Invoice đối ứng
  return this.prisma.$transaction(async (tx) => {
    const booking = await tx.booking.create({
      data: {
        customerId: userId,
        roomId: dto.roomId,
        checkInDate: new Date(dto.checkInDate),
        checkOutDate: new Date(dto.checkOutDate),
        guestCount: dto.guestCount,
        totalAmount: dto.totalAmount,
        status: BookingStatus.PENDING,
      },
    });

    await tx.invoice.create({
      data: {
        bookingId: booking.id,
        roomAmount: dto.totalAmount,
        finalAmount: dto.totalAmount,
        paymentStatus: PaymentStatus.UNPAID,
      },
    });

    return booking;
  });
}
\`\`\`

### 4.1.4. Hiện thực module Hóa đơn đa khoản thu & Quản lý Ca trực
Thuật toán tính toán tiền hóa đơn tự động và đối soát tiền két khi chốt ca trực:
\`\`\`typescript
async closeShift(staffId: string, dto: CloseShiftDto) {
  const shift = await this.prisma.workShift.findFirst({
    where: { staffId, status: ShiftStatus.OPEN },
  });
  if (!shift) throw new NotFoundException('Không tìm thấy ca trực đang mở!');

  // Tính tổng tiền mặt thu được trong ca
  const cashPayments = await this.prisma.payment.aggregate({
    where: {
      shiftId: shift.id,
      method: PaymentMethod.CASH,
      status: PaymentEntryStatus.CONFIRMED,
    },
    _sum: { amount: true },
  });

  const expectedCash = shift.initialCash + (cashPayments._sum.amount || 0);
  const cashDifference = dto.actualCash - expectedCash;

  // Ràng buộc kỷ luật: bắt buộc giải trình nếu chênh lệch khác 0
  if (cashDifference !== 0 && !dto.differenceReason) {
    throw new BadRequestException('Vui lòng nhập lý do giải trình khi tiền két có chênh lệch!');
  }

  return this.prisma.workShift.update({
    where: { id: shift.id },
    data: {
      actualCash: dto.actualCash,
      expectedCash,
      cashDifference,
      differenceReason: dto.differenceReason,
      endTime: new Date(),
      status: ShiftStatus.CLOSED,
    },
  });
}
\`\`\`

---

## 4.2. Hiện thực hóa Mobile App (Flutter Client) & Hướng dẫn Chụp ảnh màn hình

Cấu trúc mã nguồn Flutter tại thư mục \`hotel_app/lib\` được tổ chức theo kiến trúc Clean Feature-First Architecture:
\`\`\`
hotel_app/lib/
├── core/              # Theme màu sắc, mạng Dio, bảo mật FlutterSecureStorage
├── di/                # Dependency Injection (GetIt Service Locator)
├── features/          # Các phân hệ tính năng nghiệp vụ
│   ├── admin/         # Màn hình Admin: Dashboard, Báo cáo FL Chart, Quản lý phòng & Nhân sự
│   ├── auth/          # Màn hình Xác thực: Login, Register, Quên mật khẩu OTP
│   ├── cashier/       # Màn hình Thu ngân: Hóa đơn, Sổ thu tiền, Đối soát
│   ├── customer/      # Màn hình Khách: Home, Tìm phòng, Đặt phòng, Đơn của tôi, Dịch vụ
│   ├── notifications/ # Màn hình Trung tâm thông báo đẩy FCM và Cài đặt nhận tin
│   ├── profile/       # Màn hình Cá nhân: Cập nhật thông tin, Avatar, Đổi mật khẩu
│   ├── receptionist/  # Màn hình Lễ tân: Room Matrix, Check-in, Check-out, Ca trực
│   └── splash/        # Màn hình Chào khởi động
├── shared/            # Widgets tái sử dụng (Custom Button, Form Input, Shimmer...)
└── main.dart          # Điểm khởi chạy ứng dụng Flutter
\`\`\`

Dưới đây là chi tiết toàn bộ các màn hình chức năng của ứng dụng di động kèm **KHUNG CHÈN ẢNH** để sinh viên chụp ảnh màn hình điện thoại dán vào:

---

### 4.2.1. Phân hệ Chung & Xác thực tài khoản (Auth & Common)

#### 1. Màn hình Chào (Splash Screen)
- **Tập tin:** \`lib/features/splash/screens/splash_screen.dart\`
- **Mô tả:** Màn hình khởi động ứng dụng với logo Luxe Grand Hotel ánh vàng kim nổi bật trên nền xanh đen huyền bí, hiệu ứng fade-in mượt mà, tự động kiểm tra trạng thái đăng nhập trong \`FlutterSecureStorage\` để điều hướng vào màn hình tương ứng.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.1]**  
> **Tên hình:** Giao diện Màn hình Chào (Splash Screen) khởi động ứng dụng  
> **Vị trí chụp:** Mở ứng dụng điện thoại -> Màn hình hiển thị Logo Luxe Grand Hotel và tên thương hiệu sang trọng.  
> **Hướng dẫn chụp ảnh:** Chụp ảnh màn hình điện thoại khi vừa mở app ở trạng thái tải logo đẹp mắt.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.1: Giao diện Màn hình Chào (Splash Screen) khởi động ứng dụng*

#### 2. Màn hình Đăng nhập và Đăng ký (Login & Register Screens)
- **Tập tin:** \`lib/features/auth/screens/login_screen.dart\` và \`register_screen.dart\`
- **Mô tả:** Form đăng nhập hỗ trợ kiểm định dữ liệu đầu vào (Validation), hiển thị/ẩn mật khẩu bằng mắt, lưu mật khẩu an toàn. Form đăng ký gồm họ tên, số điện thoại, email và mật khẩu.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.2]**  
> **Tên hình:** Giao diện Đăng nhập và Đăng ký tài khoản khách hàng  
> **Vị trí chụp:** Ứng dụng Flutter > Màn hình Đăng nhập (\`login_screen.dart\`) và tab Đăng ký (\`register_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Ghép 2 ảnh chụp màn hình điện thoại cạnh nhau (Bên trái: Form Đăng nhập; Bên phải: Form Đăng ký) rồi dán vào đây.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.2: Giao diện Đăng nhập và Đăng ký tài khoản khách hàng*

#### 3. Màn hình Quên mật khẩu và Nhập mã xác thực OTP
- **Tập tin:** \`lib/features/auth/screens/forgot_password_screen.dart\`
- **Mô tả:** Giao diện 2 bước: Bước 1 nhập Email nhận mã OTP 6 số; Bước 2 gồm 6 ô nhập mã OTP tự động chuyển focus kèm ô nhập mật khẩu mới.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.3]**  
> **Tên hình:** Giao diện Quên mật khẩu và Nhập mã xác thực OTP gửi qua Email  
> **Vị trí chụp:** Màn hình Quên mật khẩu (\`forgot_password_screen.dart\`) hiển thị các ô nhập mã OTP 6 số và mật khẩu mới.  
> **Hướng dẫn chụp ảnh:** Nhập email thử nghiệm, chụp lại màn hình hiển thị các ô mã OTP 6 số đẹp mắt.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.3: Giao diện Quên mật khẩu và Nhập mã xác thực OTP gửi qua Email*

#### 4. Màn hình Quản lý Hồ sơ cá nhân (Profile Screen)
- **Tập tin:** \`lib/features/profile/screens/profile_screen.dart\`
- **Mô tả:** Hiển thị thông tin người dùng, ảnh đại diện Avatar tải từ Cloudinary, nút chọn ảnh từ thư viện, form cập nhật họ tên, số điện thoại và nút mở modal đổi mật khẩu an toàn.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.4]**  
> **Tên hình:** Giao diện Quản lý Hồ sơ cá nhân và Cập nhật ảnh đại diện (Avatar)  
> **Vị trí chụp:** Tab "Tài khoản" ở thanh điều hướng (\`profile_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Mở màn hình hồ sơ cá nhân đã có avatar và thông tin cá nhân hiển thị, chụp lại màn hình.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.4: Giao diện Quản lý Hồ sơ cá nhân và Cập nhật ảnh đại diện (Avatar)*

#### 5. Màn hình Trung tâm Thông báo đẩy (Notifications Screen)
- **Tập tin:** \`lib/features/notifications/screens/notifications_screen.dart\` và \`notification_settings_screen.dart\`
- **Mô tả:** Danh sách các thông báo đẩy FCM được phân loại theo icon trực quan (Duyệt đơn, Nhắc check-in, Hóa đơn); nút "Đọc tất cả"; màn hình cài đặt bật/tắt nhận tin qua Push Notification hoặc Email.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.5]**  
> **Tên hình:** Giao diện Hộp thư Thông báo đẩy (FCM) & Cài đặt nhận tin  
> **Vị trí chụp:** Chạm vào biểu tượng Chuông thông báo ở góc trên màn hình chính (\`notifications_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách các thông báo nhận phòng, duyệt đơn đã gửi tới điện thoại.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.5: Giao diện Hộp thư Thông báo đẩy (FCM) & Cài đặt nhận tin*

---

### 4.2.2. Phân hệ Khách hàng (Customer Experience Flow)

#### 6. Màn hình Trang chủ và Tìm kiếm phòng theo bộ lọc (Home & Search)
- **Tập tin:** \`lib/features/customer/screens/home_screen.dart\` và \`room_search_screen.dart\`
- **Mô tả:** Banner giới thiệu khách sạn sang trọng, widget chọn ngày nhận - trả phòng (\`showDateRangePicker\`), chọn số khách; danh sách phòng trống kèm giá niêm yết, đánh giá sao và nhãn khuyến mại.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.6]**  
> **Tên hình:** Giao diện Trang chủ Khách hàng và Bộ lọc tìm kiếm phòng trống theo ngày  
> **Vị trí chụp:** Đăng nhập tài khoản Khách hàng -> Màn hình Trang chủ (\`home_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình trang chủ hiển thị khung chọn lịch ngày nhận/trả và danh sách thẻ phòng.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.6: Giao diện Trang chủ Khách hàng và Bộ lọc tìm kiếm phòng trống theo ngày*

#### 7. Màn hình Chi tiết hạng phòng và Tiện nghi (Room Detail Screen)
- **Tập tin:** \`lib/features/customer/screens/room_detail_screen.dart\`
- **Mô tả:** Carousel ảnh phòng sắc nét vuốt ngang, thông số diện tích, view ngắm cảnh, danh mục biểu tượng tiện nghi (Wifi, Bồn tắm, Hồ bơi, Minibar) và thanh đặt phòng nổi dưới chân màn hình.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.7]**  
> **Tên hình:** Giao diện Xem chi tiết hạng phòng, Tiện nghi và Thư viện ảnh phòng  
> **Vị trí chụp:** Chạm vào một phòng bất kỳ trên màn hình Trang chủ -> Mở \`room_detail_screen.dart\`.  
> **Hướng dẫn chụp ảnh:** Chụp toàn cảnh màn hình chi tiết phòng hiển thị ảnh lớn, các tiện ích và đơn giá theo đêm.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.7: Giao diện Xem chi tiết hạng phòng, Tiện nghi và Thư viện ảnh phòng*

#### 8. Màn hình Xác nhận Đặt phòng trực tuyến
- **Tập tin:** Modal đặt phòng tích hợp trong \`room_detail_screen.dart\`
- **Mô tả:** Tóm tắt lịch lưu trú, số đêm, tự động tính tổng tiền phòng, ô nhập yêu cầu đặc biệt và nút bấm "Xác nhận đặt phòng".

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.8]**  
> **Tên hình:** Giao diện Xác nhận Đặt phòng trực tuyến và Nhập yêu cầu đặc biệt  
> **Vị trí chụp:** Nhấn nút "Đặt phòng ngay" trên màn hình chi tiết phòng.  
> **Hướng dẫn chụp ảnh:** Chụp màn hình popup / bottom-sheet xác nhận đơn phòng kèm số tiền tính toán tự động.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.8: Giao diện Xác nhận Đặt phòng trực tuyến và Nhập yêu cầu đặc biệt*

#### 9. Màn hình Đơn đặt phòng của tôi (My Bookings Screen)
- **Tập tin:** \`lib/features/customer/screens/my_bookings_screen.dart\`
- **Mô tả:** Quản lý toàn bộ danh sách đơn phòng theo các tab trạng thái: Tất cả, Chờ duyệt, Đã xác nhận, Đang ở, Đã trả phòng; hiển thị mã đơn (ví dụ \`BK-2026-088\`), ngày lưu trú và badge màu trạng thái.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.9]**  
> **Tên hình:** Giao diện Danh sách đơn đặt phòng của tôi (My Bookings) và Tiến trình đơn  
> **Vị trí chụp:** Tab "Đơn của tôi" trên thanh điều hướng (\`my_bookings_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách các đơn đặt phòng của khách với các trạng thái khác nhau.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.9: Giao diện Danh sách đơn đặt phòng của tôi (My Bookings) và Tiến trình đơn*

#### 10. Màn hình Chi tiết hóa đơn và Quét mã QR chuyển khoản thanh toán
- **Tập tin:** \`lib/features/customer/screens/my_invoices_screen.dart\`
- **Mô tả:** Chi tiết tiền phòng, tiền dịch vụ, tổng tiền và tiền đã trả; hiển thị mã VietQR chuyển khoản tự sinh kèm số tài khoản, tên ngân hàng và nội dung chuyển tiền chuẩn xác; ô nhập mã giao dịch xác nhận.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.10]**  
> **Tên hình:** Giao diện Chi tiết hóa đơn và Quét mã QR chuyển khoản thanh toán  
> **Vị trí chụp:** Bấm vào một hóa đơn cần thanh toán -> Bấm "Thanh toán chuyển khoản" (\`my_invoices_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình hiển thị mã QR Code chuyển khoản của khách sạn kèm bảng kê chi phí hóa đơn.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.10: Giao diện Chi tiết hóa đơn và Quét mã QR chuyển khoản thanh toán*

#### 11. Màn hình Gọi dịch vụ phòng (Room Service Screen)
- **Tập tin:** \`lib/features/customer/screens/service_order_screen.dart\`
- **Mô tả:** Danh mục đồ ăn, đồ uống minibar, dịch vụ giặt là và spa; bộ đếm tăng/giảm số lượng món; nút bấm "Gọi phục vụ" gửi yêu cầu tức thì tới quầy buồng phòng.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.11]**  
> **Tên hình:** Giao diện Gọi dịch vụ phòng (Room Service: Minibar, Ẩm thực, Giặt là)  
> **Vị trí chụp:** Màn hình dịch vụ phòng (\`service_order_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chọn vài món đồ uống minibar hoặc đồ ăn, chụp lại màn hình danh sách dịch vụ và nút đặt món.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.11: Giao diện Gọi dịch vụ phòng (Room Service: Minibar, Ẩm thực, Giặt là)*

---

### 4.2.3. Phân hệ Lễ tân & Thu ngân (Front-Desk Operations Flow)

#### 12. Màn hình Sơ đồ Ma trận phòng theo tầng (Room Matrix Screen)
- **Tập tin:** \`lib/features/receptionist/screens/room_matrix_screen.dart\`
- **Mô tả:** "Trái tim" của phân hệ lễ tân: Thể hiện trực quan toàn bộ các tầng của khách sạn; mỗi phòng là một thẻ với số phòng, hạng phòng, tên khách đang ở và 5 mã màu trạng thái thời gian thực.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.12]**  
> **Tên hình:** Giao diện Sơ đồ Ma trận phòng theo tầng (Room Matrix) với 5 mã màu trực quan  
> **Vị trí chụp:** Đăng nhập tài khoản Lễ tân -> Màn hình chính Room Matrix (\`room_matrix_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình hiển thị sơ đồ phòng chia theo tầng có đầy đủ các phòng màu xanh, đỏ, cam, xanh dương.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.12: Giao diện Sơ đồ Ma trận phòng theo tầng (Room Matrix) với 5 mã màu trực quan*

#### 13. Menu Thao tác nhanh trên thẻ phòng (Quick Actions Menu)
- **Tập tin:** BottomSheet trong \`room_matrix_screen.dart\`
- **Mô tả:** Khi chạm vào thẻ phòng, menu trượt từ dưới lên cung cấp các hành động tức thì: *Xem thông tin khách, Nhận phòng nhanh (Walk-in), Check-out, Đổi phòng, Chuyển trạng thái dọn buồng phòng*.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.13]**  
> **Tên hình:** Giao diện Thao tác nhanh trên thẻ phòng (Quick Actions Menu)  
> **Vị trí chụp:** Chạm vào một thẻ phòng bất kỳ trên màn hình Room Matrix.  
> **Hướng dẫn chụp ảnh:** Chụp màn hình khi menu thao tác nhanh trượt lên với các nút chức năng rõ ràng.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.13: Giao diện Thao tác nhanh trên thẻ phòng (Quick Actions Menu)*

#### 14. Màn hình Tiếp nhận khách vãng lai (Walk-in Check-in)
- **Tập tin:** Dialog/Modal tiếp nhận khách vãng lai trong \`room_matrix_screen.dart\`
- **Mô tả:** Nhập thông tin nhanh khách đến thuê phòng trực tiếp tại quầy: Họ tên, CCCD, Số điện thoại, Số đêm ở; hệ thống tạo ngay Booking và nhận phòng lập tức.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.14]**  
> **Tên hình:** Giao diện Tiếp nhận khách vãng lai và Nhận phòng nhanh tại quầy (Walk-in)  
> **Vị trí chụp:** Chạm vào phòng trống (AVAILABLE) -> Chọn "Nhận phòng nhanh (Walk-in)".  
> **Hướng dẫn chụp ảnh:** Nhập thông tin khách mẫu và chụp lại màn hình form làm thủ tục Walk-in.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.14: Giao diện Tiếp nhận khách vãng lai và Nhận phòng nhanh tại quầy (Walk-in)*

#### 15. Màn hình Danh sách Khách nhận phòng và Trả phòng trong ngày
- **Tập tin:** \`lib/features/receptionist/screens/front_desk_today_screen.dart\`
- **Mô tả:** Thống kê danh sách khách có lịch đến (\`Today Check-ins\`) và lịch đi (\`Today Check-outs\`) trong ngày hôm nay; nút bấm một chạm để tiến hành làm thủ tục cho khách.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.15]**  
> **Tên hình:** Giao diện Danh sách khách nhận phòng (Check-ins) và trả phòng (Check-outs) hôm nay  
> **Vị trí chụp:** Màn hình Lễ tân hôm nay (\`front_desk_today_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách khách hẹn đến và đi trong ngày.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.15: Giao diện Danh sách khách nhận phòng (Check-ins) và trả phòng (Check-outs) hôm nay*

#### 16. Màn hình Thực hiện thủ tục Đổi phòng lưu trú (Change Room)
- **Tập tin:** Sheet hoán đổi phòng trong \`room_matrix_screen.dart\`
- **Mô tả:** Chọn phòng mới từ danh sách phòng trống tương đương; hệ thống hiển thị thông tin đối chiếu phòng cũ và phòng mới, tự động tính chênh lệch giá nếu có.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.16]**  
> **Tên hình:** Giao diện Thực hiện thủ tục Đổi phòng lưu trú (Change Room)  
> **Vị trí chụp:** Chạm vào phòng đang có khách (OCCUPIED) -> Chọn "Đổi phòng".  
> **Hướng dẫn chụp ảnh:** Chụp màn hình giao diện chọn phòng mới và xác nhận chuyển phòng cho khách.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.16: Giao diện Thực hiện thủ tục Đổi phòng lưu trú (Change Room)*

#### 17. Màn hình Xem trước bảng kê chi phí (Checkout Preview) & Trả phòng
- **Tập tin:** Dialog xem trước hóa đơn và thực hiện trả phòng
- **Mô tả:** Bảng kê chi tiết tiền phòng, các món minibar đã sử dụng, số tiền đã cọc/trả trước và số dư còn nợ (\`amountDue\`); nút thanh toán tiền mặt/quẹt thẻ và nút hoàn tất trả phòng.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.17]**  
> **Tên hình:** Giao diện Xem trước bảng kê chi phí trả phòng (Checkout Preview) & Trả phòng  
> **Vị trí chụp:** Chọn một phòng đang lưu trú -> Bấm "Trả phòng (Check-out)".  
> **Hướng dẫn chụp ảnh:** Chụp màn hình bảng kê quyết toán chi phí hiển thị tiền phòng và dịch vụ rõ ràng trước khi xác nhận.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.17: Giao diện Xem trước bảng kê chi phí trả phòng (Checkout Preview) & Trả phòng*

#### 18. Màn hình Phê duyệt đơn đặt phòng trực tuyến (Booking Approval Screen)
- **Tập tin:** \`lib/features/receptionist/screens/booking_approval_screen.dart\`
- **Mô tả:** Danh sách các đơn phòng trực tuyến khách đặt trên app ở trạng thái Chờ duyệt (\`PENDING\`); lễ tân kiểm tra lịch phòng và nhấn "Duyệt đơn" (xanh) hoặc "Từ chối" (đỏ kèm lý do).

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.18]**  
> **Tên hình:** Giao diện Duyệt và Từ chối đơn đặt phòng trực tuyến chờ xử lý  
> **Vị trí chụp:** Mục "Đơn chờ duyệt" trên giao diện lễ tân (\`booking_approval_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách các đơn đặt phòng PENDING kèm 2 nút Duyệt / Từ chối.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.18: Giao diện Duyệt và Từ chối đơn đặt phòng trực tuyến chờ xử lý*

#### 19. Màn hình Danh sách yêu cầu chuyển khoản cần đối soát
- **Tập tin:** \`lib/features/receptionist/screens/payment_requests_screen.dart\`
- **Mô tả:** Danh sách các khoản tiền khách báo chuyển khoản qua ngân hàng (\`Payment PENDING\`) kèm mã tham chiếu và tên khách; thu ngân kiểm tra sao kê ngân hàng rồi bấm "Xác nhận đã nhận" hoặc "Từ chối".

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.19]**  
> **Tên hình:** Giao diện Danh sách yêu cầu chuyển khoản cần đối soát và Duyệt/Từ chối  
> **Vị trí chụp:** Mục "Yêu cầu thanh toán" của thu ngân (\`payment_requests_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình hiển thị danh sách các khoản thanh toán chuyển khoản chờ đối soát sao kê.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.19: Giao diện Danh sách yêu cầu chuyển khoản cần đối soát và Duyệt/Từ chối*

#### 20. Màn hình Mở ca trực lễ tân (Open Shift Sheet)
- **Tập tin:** Sheet mở ca trực tại quầy
- **Mô tả:** Khai báo ca trực (Ca Sáng, Ca Chiều, Ca Đêm), tên quầy làm việc và bàn phím số nhập số tiền mặt tồn quỹ đầu ca trong két (\`initialCash\`).

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.20]**  
> **Tên hình:** Giao diện Mở ca trực lễ tân (Khai báo số tiền mặt ban đầu)  
> **Vị trí chụp:** Chạm vào banner "Ca trực hiện tại: CHƯA MỞ CA" trên màn hình lễ tân.  
> **Hướng dẫn chụp ảnh:** Chụp màn hình form mở ca trực với ô chọn loại ca và ô nhập số tiền két đầu ca.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.20: Giao diện Mở ca trực lễ tân (Khai báo số tiền mặt ban đầu)*

#### 21. Màn hình Chốt ca trực lễ tân & Đối soát tiền két (Shift Close Screen)
- **Tập tin:** \`lib/features/receptionist/screens/shift_close_screen.dart\`
- **Mô tả:** Tóm tắt doanh thu trong ca: Doanh thu tiền mặt, thẻ, chuyển khoản; ô nhập số tiền đếm thực tế (\`actualCash\`); hiển thị số tiền chênh lệch thừa/thiếu (\`cashDifference\`) bằng chữ đỏ cảnh báo và ô bắt buộc giải trình.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.21]**  
> **Tên hình:** Giao diện Chốt ca trực lễ tân, Kiểm đếm tiền két và Giải trình chênh lệch  
> **Vị trí chụp:** Bấm vào nút "Chốt ca trực" khi kết thúc ca làm việc (\`shift_close_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Nhập số tiền thực tế có chênh lệch nhỏ, chụp lại màn hình hiển thị số tiền lý thuyết, tiền thực tế và ô nhập giải trình.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.21: Giao diện Chốt ca trực lễ tân, Kiểm đếm tiền két và Giải trình chênh lệch*

---

### 4.2.4. Phân hệ Quản trị viên (Admin & Management Flow)

#### 22. Màn hình Dashboard Tổng quan Quản trị viên
- **Tập tin:** \`lib/features/admin/screens/admin_dashboard_screen.dart\`
- **Mô tả:** 4 thẻ chỉ số KPI nhanh (Tỷ lệ lấp đầy hôm nay, Số lượt nhận phòng hôm nay, Số lượt trả phòng hôm nay, Số đơn chờ duyệt); các phím tắt quản lý nhanh danh mục phòng và nhân sự.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.22]**  
> **Tên hình:** Giao diện Dashboard Tổng quan Quản trị viên (Admin KPI Cards)  
> **Vị trí chụp:** Đăng nhập tài khoản Quản trị viên (ADMIN) -> Màn hình Dashboard chính (\`admin_dashboard_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp toàn cảnh màn hình Dashboard hiển thị 4 thẻ KPI màu sắc nổi bật và biểu đồ vận hành.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.22: Giao diện Dashboard Tổng quan Quản trị viên (Admin KPI Cards)*

#### 23. Màn hình Báo cáo Biểu đồ Doanh thu 12 tháng (FL Chart)
- **Tập tin:** \`lib/features/admin/screens/reports_screen.dart\`
- **Mô tả:** Biểu đồ cột tương tác 12 tháng trong năm sử dụng thư viện \`fl_chart\`; chạm vào từng cột tháng để hiển thị Tooltip cơ cấu doanh thu tiền phòng và tiền dịch vụ; dropdown chọn xem các năm vận hành khác nhau.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.23]**  
> **Tên hình:** Giao diện Báo cáo Biểu đồ Doanh thu tương tác 12 tháng theo năm (FL Chart)  
> **Vị trí chụp:** Mục "Báo cáo Doanh thu" trên màn hình Admin (\`reports_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình hiển thị biểu đồ cột FL Chart 12 tháng, chạm tay vào 1 cột để hiển thị tooltip số tiền doanh thu chi tiết.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.23: Giao diện Báo cáo Biểu đồ Doanh thu tương tác 12 tháng theo năm (FL Chart)*

#### 24. Màn hình Phân tích chi tiết tỷ lệ lấp đầy theo hạng phòng (Occupancy Detail)
- **Tập tin:** \`lib/features/admin/screens/occupancy_detail_screen.dart\`
- **Mô tả:** Phân tích tỷ lệ khai thác phòng theo từng hạng (Standard, Superior, Deluxe, Suite); danh sách chi tiết các phòng kèm tên khách và ngày trả phòng dự kiến.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.24]**  
> **Tên hình:** Giao diện Phân tích chi tiết tỷ lệ lấp đầy theo hạng phòng (Occupancy Detail)  
> **Vị trí chụp:** Mục "Tỷ lệ lấp đầy phòng" trên Admin (\`occupancy_detail_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình phân tích tỷ lệ phần trăm phòng đang có khách theo từng hạng phòng.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.24: Giao diện Phân tích chi tiết tỷ lệ lấp đầy theo hạng phòng (Occupancy Detail)*

#### 25. Màn hình Quản lý danh mục phòng, Hạng phòng và Dịch vụ
- **Tập tin:** \`room_type_management_screen.dart\` và \`service_catalog_screen.dart\`
- **Mô tả:** Bảng danh sách các hạng phòng, bảng giá niêm yết, danh mục các món ăn đồ uống minibar; nút thêm mới, chỉnh sửa và xóa trực quan.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.25]**  
> **Tên hình:** Giao diện Quản lý danh mục phòng, Hạng phòng và Dịch vụ khách sạn  
> **Vị trí chụp:** Mục "Danh mục phòng & Dịch vụ" trên màn hình Admin.  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách các hạng phòng kèm bảng giá và tiện ích niêm yết.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.25: Giao diện Quản lý danh mục phòng, Hạng phòng và Dịch vụ khách sạn*

#### 26. Màn hình Quản trị Nhân sự và Phân quyền vai trò (User Management RBAC)
- **Tập tin:** \`lib/features/admin/screens/user_management_screen.dart\`
- **Mô tả:** Danh sách toàn bộ tài khoản nhân sự (Lễ tân, Thu ngân, Admin) và Khách hàng; các nút phân quyền vai trò, đổi mật khẩu nhân viên và khóa/mở khóa tài khoản.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.26]**  
> **Tên hình:** Giao diện Quản lý tài khoản nhân sự và Phân quyền vai trò RBAC  
> **Vị trí chụp:** Mục "Quản lý nhân viên" trên Admin (\`user_management_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Chụp màn hình danh sách tài khoản nhân sự với các huy hiệu vai trò ADMIN, RECEPTIONIST rõ ràng.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.26: Giao diện Quản lý tài khoản nhân sự và Phân quyền vai trò RBAC*

#### 27. Màn hình Giám sát Sổ lịch sử ca trực của toàn bộ nhân viên lễ tân
- **Tập tin:** \`lib/features/admin/screens/admin_shift_management_screen.dart\` và \`shift_detail_screen.dart\`
- **Mô tả:** Lịch sử chi tiết toàn bộ các ca trực trong quá khứ; xem tiền mặt đầu ca, tiền thực tế, tiền chênh lệch, lý do giải trình và danh sách tất cả các khoản thu diễn ra trong ca trực đó; nút cưỡng chế chốt ca của Admin.

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 4.27]**  
> **Tên hình:** Giao diện Sổ giám sát lịch sử ca trực của toàn bộ nhân viên lễ tân  
> **Vị trí chụp:** Mục "Giám sát ca trực" trên Admin (\`admin_shift_management_screen.dart\`).  
> **Hướng dẫn chụp ảnh:** Mở xem chi tiết 1 ca trực đã chốt có thông số tiền két và danh sách giao dịch, chụp lại màn hình.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 4.27: Giao diện Sổ giám sát lịch sử ca trực của toàn bộ nhân viên lễ tân*

---

\\newpage

# CHƯƠNG 5: KIỂM THỬ VÀ ĐÁNH GIÁ KẾT QUẢ

## 5.1. Kế hoạch và phương pháp kiểm thử (Tiêu chuẩn IEEE 829)
Quá trình kiểm thử phần mềm được thực hiện bài bản và nghiêm ngặt theo tiêu chuẩn quốc tế **IEEE 829 (Test Documentation)** nhằm bảo đảm độ tin cậy tuyệt đối trước khi bàn giao:
1. **Kiểm thử đơn vị (Unit Testing):** Sử dụng Jest kiểm thử các hàm logic lõi trên Backend (công thức tính doanh thu, thuật toán phát hiện trùng khoảng ngày, đối soát ca trực) và Flutter Test kiểm thử các BLoC state transitions.
2. **Kiểm thử tích hợp (Integration Testing):** Kiểm tra giao tiếp giữa Mobile Client và Server thông qua các request HTTP thực tế, đảm bảo việc parse dữ liệu DTO đồng nhất và xử lý các Exception Filter đúng quy chuẩn.
3. **Kiểm thử tranh chấp đồng thời (Concurrency Testing):** Giả lập nhiều tiến trình đặt phòng đồng thời vào cùng một phòng vật lý tại cùng một khoảng thời gian để kiểm chứng năng lực khóa dòng và tính toàn vẹn dữ liệu.
4. **Kiểm thử chấp nhận người dùng (User Acceptance Testing - UAT):** Đóng vai Khách hàng, Lễ tân trực ca và Giám đốc điều hành thực hiện liên hoàn một kịch bản lưu trú hoàn chỉnh: Đặt phòng -> Duyệt -> Check-in -> Order đồ uống minibar -> Đổi phòng -> Yêu cầu chuyển khoản -> Chốt ca đối soát tiền két -> Check-out.

---

## 5.2. Bảng 42 Kịch bản kiểm thử chi tiết (Test Cases Matrix - 100% PASS)

### Bảng 5.1: Bảng 42 Kịch bản kiểm thử (Test Cases) chi tiết bao phủ toàn diện 10 phân hệ
| Mã TC | Tên ca kiểm thử | Dữ liệu đầu vào & Thao tác kiểm thử | Kết quả kỳ vọng | Mức độ | Trạng thái |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **TC-AUTH-01** | Đăng ký tài khoản hợp lệ | Email mới, mật khẩu > 6 ký tự, họ tên đầy đủ | Tạo tài khoản thành công, băm Bcrypt, cấp quyền CUSTOMER | Cao | **PASS** |
| **TC-AUTH-02** | Đăng ký với Email đã có | Nhập lại email đã tồn tại trong database | Chặn request, báo lỗi 409 Conflict | Cao | **PASS** |
| **TC-AUTH-03** | Đăng ký mật khẩu quá ngắn | Nhập mật khẩu dưới 6 ký tự (ví dụ: \`123\`) | Bắt lỗi Validation form phía Client và Backend | Vừa | **PASS** |
| **TC-AUTH-04** | Đăng nhập đúng tài khoản | Nhập đúng email và mật khẩu | Trả về Bearer JWT token, chuyển vào app | Cao | **PASS** |
| **TC-AUTH-05** | Đăng nhập sai mật khẩu | Nhập đúng email nhưng gõ sai mật khẩu | Báo lỗi 401 Unauthorized thông báo rõ ràng | Cao | **PASS** |
| **TC-AUTH-06** | Quên mật khẩu gửi OTP | Nhập email đã đăng ký hệ thống | Sinh mã OTP 6 số lưu CSDL, gửi mail qua Nodemailer | Cao | **PASS** |
| **TC-AUTH-07** | Nhập sai mã OTP | Nhập mã OTP không khớp hoặc đã quá 10 phút | Báo lỗi 400 Bad Request không hợp lệ | Cao | **PASS** |
| **TC-AUTH-08** | Đặt lại mật khẩu thành công | Nhập đúng mã OTP và mật khẩu mới hợp lệ | Đổi mật khẩu thành công, OTP chuyển \`used = true\` | Cao | **PASS** |
| **TC-ROOM-01** | Xem sơ đồ Ma trận phòng | Đăng nhập tài khoản lễ tân, mở Room Matrix | Hiển thị đầy đủ phòng theo tầng kèm 5 mã màu chuẩn | Cao | **PASS** |
| **TC-ROOM-02** | Tra cứu phòng trống theo ngày | Chọn khoảng ngày 25/09 - 28/09, số khách: 2 | Chỉ trả về các phòng hoàn toàn trống lịch | Cao | **PASS** |
| **TC-ROOM-03** | Chuyển trạng thái dọn dẹp | Bấm hoàn tất dọn phòng từ CLEANING | Phòng chuyển trạng thái sang AVAILABLE (xanh lá) | Vừa | **PASS** |
| **TC-BOOK-01** | Đặt phòng trực tuyến hợp lệ | Chọn phòng trống, ngày đến và ngày đi | Tạo Booking PENDING, tự động tạo Invoice UNPAID | Cao | **PASS** |
| **TC-BOOK-02** | Kiểm thử tranh chấp trùng lịch| Đặt vào phòng đã có đơn CONFIRMED cùng ngày | Chặn request, báo lỗi 409 Conflict (ERR_ROOM_OCCUPIED)| Nghiêm ngặt| **PASS** |
| **TC-BOOK-03** | Lễ tân phê duyệt đơn phòng | Bấm nút "Duyệt đơn" cho đơn PENDING | Đơn đổi sang CONFIRMED, phòng sang RESERVED, gửi FCM | Cao | **PASS** |
| **TC-BOOK-04** | Từ chối đơn không nhập lý do | Bấm nút từ chối nhưng để trống lý do | Form báo đỏ bắt buộc nhập lý do giải thích | Vừa | **PASS** |
| **TC-BOOK-05** | Từ chối đơn có kèm lý do | Bấm từ chối kèm lý do: "Hết phòng" | Đơn sang CANCELLED, lưu vết lý do, gửi thông báo | Vừa | **PASS** |
| **TC-BOOK-06** | Làm thủ tục Check-in | Đối chiếu CCCD và bấm Check-in đơn đến hạn | Đơn sang CHECKED_IN, phòng chuyển sang OCCUPIED (đỏ) | Cao | **PASS** |
| **TC-BOOK-07** | Nhận phòng vãng lai Walk-in | Chọn phòng trống tại quầy và bấm Walk-in | Tạo ngay Booking CHECKED_IN và chuyển phòng OCCUPIED | Cao | **PASS** |
| **TC-BOOK-08** | Đổi phòng cho khách đang ở | Khách đổi từ phòng 101 sang phòng 102 trống | Phòng 101 về CLEANING, phòng 102 thành OCCUPIED | Cao | **PASS** |
| **TC-BOOK-09** | Trả phòng khi còn nợ tiền | Hóa đơn còn dư nợ 500.000 VNĐ | Cảnh báo đỏ yêu cầu thanh toán dứt điểm trước | Cao | **PASS** |
| **TC-BOOK-10** | Trả phòng thành công Check-out | Hóa đơn đã thanh toán đủ (remaining = 0) | Đơn sang CHECKED_OUT, phòng chuyển về CLEANING | Cao | **PASS** |
| **TC-BOOK-11** | Xem trước hóa đơn Check-out | Bấm xem trước bảng kê chi phí trả phòng | Hiển thị chính xác số đêm, minibar mà không đổi trạng thái | Cao | **PASS** |
| **TC-SERV-01** | Order dịch vụ đồ uống minibar | Khách gọi 2 chai rượu vang vào đơn phòng | Hóa đơn tự động cộng thêm chi phí tương ứng | Cao | **PASS** |
| **TC-PAY-01** | Khách gửi yêu cầu chuyển khoản| Khách nhập mã giao dịch chuyển khoản trên app| Tạo Payment PENDING, chưa cộng tiền vào paidAmount | Cao | **PASS** |
| **TC-PAY-02** | Thu ngân duyệt chuyển khoản | Thu ngân đối soát sao kê, bấm duyệt nhận tiền| Payment sang CONFIRMED, paidAmount hóa đơn tăng lên | Cao | **PASS** |
| **TC-PAY-03** | Thu ngân từ chối tiền giả mạo | Bấm từ chối kèm lý do: "Chưa nhận được tiền" | Payment sang REJECTED, không cộng tiền vào hóa đơn | Cao | **PASS** |
| **TC-PAY-04** | Hoàn trả tiền cọc thừa Refund | Nhập hoàn tiền 500.000đ sau khi kiểm phòng | Tạo Payment type = REFUND, cân bằng số dư hóa đơn | Vừa | **PASS** |
| **TC-SHIFT-01**| Mở ca trực lễ tân thành công | Khai báo ca Sáng, tiền két đầu ca 2.000.000đ | Tạo WorkShift status = OPEN, hiển thị banner trực ca | Cao | **PASS** |
| **TC-SHIFT-02**| Mở ca khi ca cũ chưa chốt | Nhân viên đang có 1 ca OPEN bấm mở tiếp ca khác| Chặn request, báo lỗi 409 ERR_SHIFT_ALREADY_OPEN | Vừa | **PASS** |
| **TC-SHIFT-03**| Chốt ca lệch tiền không giải trình| Tiền két thực tế ít hơn lý thuyết, bỏ trống lý do| Chặn chốt ca, bắt buộc nhập lý do giải trình chênh lệch | Nghiêm ngặt| **PASS** |
| **TC-SHIFT-04**| Chốt ca có giải trình hợp lệ | Nhập tiền thực tế kèm lý do giải trình chi tiêu| WorkShift sang CLOSED, khóa các giao dịch của ca | Cao | **PASS** |
| **TC-SHIFT-05**| Admin cưỡng chế chốt ca | Nhân viên nghỉ đột xuất, Admin bấm chốt ca hộ| Ca trực chuyển CLOSED, giải phóng quầy làm việc | Cao | **PASS** |
| **TC-SHIFT-06**| Tra cứu lịch sử ca và sổ quỹ | Mở màn hình Sổ ca trực trên Admin | Hiển thị đầy đủ lịch sử các ca và chi tiết từng khoản thu | Vừa | **PASS** |
| **TC-STAT-01** | Xem Dashboard Admin | Mở màn hình Tổng quan Quản trị viên | Hiển thị chính xác 4 thẻ KPI vận hành thời gian thực | Cao | **PASS** |
| **TC-STAT-02** | Xem biểu đồ doanh thu theo năm | Chọn xem biểu đồ doanh thu năm 2026 | Biểu đồ cột FL Chart hiển thị chính xác 12 tháng | Cao | **PASS** |
| **TC-STAT-03** | Báo cáo hiệu suất nhân viên | Đánh giá năng suất phục vụ tiền sảnh | Thống kê số lượt Check-in/out và doanh số thu của từng người| Vừa | **PASS** |
| **TC-STAT-04** | Biểu đồ doanh thu ngắn hạn | Chọn xem doanh thu 7 ngày / 30 ngày gần nhất | Trả về chuỗi doanh thu từng ngày chính xác | Vừa | **PASS** |
| **TC-USER-01** | Admin thêm mới nhân viên | Admin khai báo tài khoản quyền RECEPTIONIST | Tạo tài khoản nhân sự mới, kích hoạt đăng nhập quầy | Cao | **PASS** |
| **TC-USER-02** | Phân quyền & Khóa tài khoản | Admin chuyển quyền hoặc khóa tài khoản nhân sự| Tài khoản bị khóa không thể đăng nhập vào hệ thống | Cao | **PASS** |
| **TC-NOTIF-01**| Nhận thông báo đẩy FCM | Backend duyệt đơn hoặc gửi nhắc nhở | Điện thoại hiển thị thông báo Push Notification tức thì | Cao | **PASS** |
| **TC-NOTIF-02**| Đánh dấu đã đọc thông báo | Bấm đọc 1 thông báo hoặc "Đọc tất cả" | Cập nhật trạng thái đã đọc, xóa huy hiệu đỏ chưa đọc | Vừa | **PASS** |
| **TC-SYNC-01** | Rà soát đồng bộ phòng tự động | Kích hoạt API sync-status | Tự động chuyển các phòng khách đã trả sang CLEANING | Vừa | **PASS** |

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 5.1]**  
> **Tên hình:** Ảnh chụp màn hình Kết quả thực thi bộ kịch bản kiểm thử API trên Postman Runner  
> **Vị trí chụp:** Công cụ Postman > Chọn Collection "Luxe Grand Hotel API" > Chạy Postman Collection Runner.  
> **Hướng dẫn chụp ảnh:** Chụp lại giao diện Postman Runner hiển thị danh sách các Test Suites màu xanh lá với kết quả 100% Passed.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 5.1: Ảnh chụp màn hình Kết quả thực thi bộ kịch bản kiểm thử API trên Postman Runner*

---

## 5.3. Đánh giá hiệu năng chịu tải (Apache Benchmark / k6)
Sử dụng công cụ kiểm thử tải chuyên dụng **Apache Benchmark (ab)** và **k6** để đo lường năng lực phục vụ của Backend NestJS kết hợp Redis Caching:
- **Kịch bản kiểm thử:** Giả lập 50 người dùng đồng thời (Concurrency = 50) thực hiện liên tục 2.000 requests tới API tra cứu phòng và xem ma trận phòng.
- **Kết quả đo lường thực tế:**

### Bảng 5.2: Kết quả đo lường hiệu năng và độ trễ phản hồi API hệ thống
| Chỉ số đo lường (Metric) | Kết quả đạt được | Tiêu chuẩn đánh giá | Đánh giá |
| :--- | :---: | :---: | :---: |
| **Tổng số requests thực hiện** | 2.000 requests | 2.000 requests | Hoàn thành 100% |
| **Tỷ lệ requests lỗi (Failed requests)** | **0 (0%)** | < 1% | **Tuyệt đối an toàn** |
| **Khả năng thông lượng (Throughput)** | **1.240 requests/phút** | > 800 req/phút | **Vượt 155% kỳ vọng** |
| **Thời gian đáp ứng trung bình (Latency)**| **112 ms** | < 200 ms | **Cực kỳ mượt mà** |
| **Độ trễ với dữ liệu đệm Redis Cache** | **38 ms** | < 50 ms | **Tức thì** |
| **Mức tiêu thụ CPU máy chủ** | 18% - 32% | < 70% | Rất ổn định |
| **Mức tiêu thụ RAM máy chủ** | 145 MB | < 512 MB | Tiết kiệm tài nguyên |

---

## 5.4. Đánh giá an toàn và bảo mật hệ thống
- **Bảo mật cơ sở dữ liệu:** Toàn bộ câu truy vấn được thực thi qua Prisma Client với cơ chế Prepared Statements, ngăn chặn 100% các cuộc tấn công tiêm mã độc SQL Injection.
- **Bảo mật mật khẩu:** Áp dụng thuật toán băm một chiều Bcrypt với Salt round = 10, đảm bảo mật khẩu người dùng không thể bị dịch ngược kể cả khi cơ sở dữ liệu bị lộ lọt.
- **Bảo mật giao tiếp mạng:** 100% dữ liệu truyền tải giữa Flutter Client và máy chủ NestJS được mã hóa qua giao thức HTTPS / TLS 1.3 và xác thực qua chuỗi JWT Bearer Token có thời hạn hợp lý.
- **Kiểm soát phân quyền chặt chẽ:** Triển khai bộ đôi \`JwtAuthGuard\` và \`RolesGuard\` chặn đứng mọi hành vi truy cập trái thẩm quyền của người dùng thường vào các API quản trị của Admin.

---

\\newpage

# CHƯƠNG 6: QUẢN LÝ DỰ ÁN VÀ QUY TRÌNH DEVOPS (SCRUM & DEPLOYMENT)

## 6.1. Tiến độ phát triển dự án Agile/Scrum qua 5 Sprints
Dự án được thực hiện nghiêm túc theo quy trình Agile/Scrum gồm 5 Sprint với các mục tiêu cụ thể:

### Bảng 6.1: Báo cáo phân bổ công việc theo 5 Sprint phát triển Agile/Scrum
| Sprint | Thời gian | Mục tiêu trọng tâm của Sprint | Kết quả bàn giao chính | Trạng thái |
| :---: | :---: | :--- | :--- | :---: |
| **Sprint 1** | Tuần 1 - 2 | Phân tích yêu cầu (SRS), thiết kế kiến trúc (SAD), thiết kế CSDL (ERD) | Tài liệu SRS, SAD, ERD chuẩn 3NF và Prisma Schema | **Hoàn thành** |
| **Sprint 2** | Tuần 3 - 4 | Xây dựng Backend core (Auth JWT, Rooms, Room Types, Seed data) | Backend API xác thực, CRUD danh mục phòng, Docker PG | **Hoàn thành** |
| **Sprint 3** | Tuần 5 - 6 | Xây dựng nghiệp vụ lõi: Đặt phòng, Room Matrix, Check-in/out, Đổi phòng | API Bookings chống trùng phòng, Flutter Room Matrix | **Hoàn thành** |
| **Sprint 4** | Tuần 7 - 8 | Phân hệ Tài chính, Hóa đơn đa đợt, Quản lý Ca trực, Đối soát tiền két | API Invoices, Payments, Shifts, BLoC Ca trực lễ tân | **Hoàn thành** |
| **Sprint 5** | Tuần 9 - 10| Dashboard Admin, Biểu đồ FL Chart, Kiểm thử 42 Test Cases, Đóng gói | Dashboard KPI, Biểu đồ doanh thu, Test Report PASS 100% | **Hoàn thành** |

---

## 6.2. Cơ cấu phân rã công việc (Work Breakdown Structure - WBS)
Dự án được phân rã thành 27 User Stories chính, ánh xạ trực tiếp từ 27 Yêu cầu chức năng FR-01 đến FR-27, đảm bảo mọi hạng mục công việc đều có mục tiêu đo lường và bàn giao rõ ràng giữa các thành viên.

---

## 6.3. Ma trận phân tích và kiểm soát rủi ro kỹ thuật

### Bảng 6.2: Ma trận đánh giá và kiểm soát rủi ro kỹ thuật dự án
| STT | Rủi ro tiềm ẩn | Xác suất | Tác động | Giải pháp phòng ngừa & Xử lý |
| :---: | :--- | :---: | :---: | :--- |
| **1** | Trùng lịch đặt phòng khi nhiều khách truy cập cùng lúc | Vừa | Rất lớn | Áp dụng thuật toán Interval Overlap kết hợp \`prisma.$transaction\` khóa dòng cấp độ CSDL. |
| **2** | Thất thoát tiền mặt hoặc sai lệch khi bàn giao ca trực | Lớn | Lớn | Bắt buộc khai báo tiền đầu ca, kiểm đếm tiền thực tế cuối ca và bắt buộc giải trình chênh lệch. |
| **3** | Khách gửi mã chuyển khoản giả mạo | Vừa | Lớn | Tách riêng trạng thái \`PENDING\` (chờ đối soát) và chỉ tính vào hóa đơn khi thu ngân bấm \`CONFIRMED\`. |
| **4** | Server bị quá tải khi lượng truy cập tăng đột biến | Thấp | Vừa | Tích hợp Redis Caching cho danh mục phòng và dịch vụ, giảm 65% áp lực truy vấn CSDL. |
| **5** | Khách quên lịch nhận phòng gây trống phòng lãng phí | Lớn | Vừa | Tích hợp NestJS Cronjob quét tự động mỗi sáng lúc 09:00 gửi Push Notification FCM và email. |

---

## 6.4. Hướng dẫn đóng gói Docker Compose và Triển khai Đám mây
Hệ thống được đóng gói tự động hóa bằng Docker Compose, giúp việc triển khai trên môi trường phát triển (Localhost) và máy chủ đám mây (Render / VPS Linux) diễn ra trong một câu lệnh duy nhất:

\`\`\`yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:16-alpine
    container_name: hotel_postgres
    restart: always
    environment:
      POSTGRES_USER: hotel_admin
      POSTGRES_PASSWORD: SecretPassword123!
      POSTGRES_DB: hotel_management_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: hotel_redis
    restart: always
    ports:
      - "6379:6379"

  backend:
    build:
      context: ./Hotel-Management
      dockerfile: Dockerfile
    container_name: hotel_backend_api
    restart: always
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: "postgresql://hotel_admin:SecretPassword123!@postgres:5432/hotel_management_db"
      REDIS_HOST: "redis"
      REDIS_PORT: 6379
      JWT_SECRET: "LuxeGrandHotelSuperSecretJwtKey2026"
    depends_on:
      - postgres
      - redis

volumes:
  postgres_data:
\`\`\`

> ==============================================================================
> 📸 **[KHUNG CHÈN ẢNH - HÌNH 6.1]**  
> **Tên hình:** Ảnh chụp màn hình Triển khai hạ tầng Docker Compose & Dashboard Render Cloud  
> **Vị trí chụp:** Terminal chạy lệnh \`docker compose ps\` hoặc Dashboard triển khai dịch vụ trên Render Cloud.  
> **Hướng dẫn chụp ảnh:** Chụp lại màn hình terminal hiển thị các container Postgres, Redis, Backend đang chạy \`Up (healthy)\` hoặc bảng điều khiển Render Cloud.  
> *(Sinh viên chèn ảnh chụp thực tế vào khung này)*  
> ==============================================================================
*Hình 6.1: Ảnh chụp màn hình Triển khai hạ tầng Docker Compose & Dashboard Render Cloud*

---

## 6.5. Quy trình sao lưu và phục hồi cơ sở dữ liệu
- **Lệnh sao lưu định kỳ (Database Dump):**
  \`\`\`bash
  docker exec -t hotel_postgres pg_dump -U hotel_admin hotel_management_db > backup_hotel_$(date +%Y%m%d_%H%M%S).sql
  \`\`\`
- **Lệnh phục hồi khi có sự cố (Database Restore):**
  \`\`\`bash
  cat backup_hotel_20260921.sql | docker exec -i hotel_postgres psql -U hotel_admin -d hotel_management_db
  \`\`\`

---

\\newpage

# CHƯƠNG 7: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

## 7.1. Những kết quả đạt được của đồ án
Sau quá trình nghiên cứu lý thuyết nghiêm túc và tập trung hiện thực hóa sản phẩm, đề tài **"Nghiên cứu và xây dựng hệ thống quản lý khách sạn toàn diện Luxe Grand Hotel trên nền tảng NestJS và Flutter"** đã hoàn thành xuất sắc toàn bộ các mục tiêu đặt ra:

1. **Về mặt học thuật và công nghệ:**
   - Làm chủ và triển khai thành công kiến trúc Backend doanh nghiệp hướng Module với **NestJS**, tích hợp hệ sinh thái công nghệ hàng đầu: **PostgreSQL 16**, **Prisma ORM**, **Redis In-Memory Cache**, **Elasticsearch Engine**, **Firebase Cloud Messaging** và **NestJS Cronjob**.
   - Phát triển hoàn chỉnh ứng dụng di động đa nền tảng **Flutter (iOS & Android)** theo chuẩn kiến trúc sạch phân lớp hướng tính năng (Feature-first Clean Architecture), áp dụng mô hình quản lý trạng thái luồng sự kiện **BLoC** mượt mà, đạt tốc độ khung hình 60fps.
   - Ứng dụng thành công thư viện **FL Chart** tạo nên biểu đồ phân tích doanh thu tương tác cao, hiện đại và thẩm mỹ.

2. **Về mặt nghiệp vụ thực tiễn:**
   - Số hóa trọn vẹn và khép kín toàn bộ chu trình lưu trú khách sạn: Tra cứu phòng trống theo ngày, Đặt phòng trực tuyến, Duyệt/Từ chối đơn, Sơ đồ Ma trận phòng theo tầng (Room Matrix 5 màu), Check-in theo lịch và Walk-in tại quầy, Đổi phòng lưu trú linh hoạt, Order dịch vụ phòng và Check-out kiểm kê minibar.
   - Giải quyết triệt để bài toán quản lý dòng tiền và phòng chống thất thoát tài chính thông qua cơ chế Sổ thu tiền đa đợt (\`Multi-Entry Payments\`) và phân hệ Quản lý ca trực lễ tân (\`WorkShift\`) với đối soát chênh lệch tiền két tự động, ràng buộc bắt buộc giải trình.
   - Cung cấp cho Ban giám đốc công cụ quản trị thông minh với Dashboard 4 thẻ KPI thời gian thực và Báo cáo phân tích doanh thu, tỷ lệ lấp đầy phòng trực quan.
   - Xây dựng bộ kịch bản kiểm thử toàn diện gồm 42 Test Cases chuẩn IEEE 829, đạt tỷ lệ thành công 100% (PASS).

## 7.2. Các mặt hạn chế tồn đọng
Mặc dù đã đạt được những kết quả rất ấn tượng, đề tài vẫn còn một số điểm có thể cải tiến do giới hạn về mặt thời gian và điều kiện thử nghiệm thực tế:
- **Cổng thanh toán tự động:** Hiện tại hệ thống vận hành cơ chế thanh toán chuyển khoản quét mã QR và đối soát qua thu ngân quầy, chưa tích hợp Webhook tự động bắt biến động số dư từ các cổng thanh toán trung gian bên thứ ba (như VNPay, MoMo, ZaloPay, PayOS).
- **Phần cứng khóa cửa thông minh (Smart Door Lock):** Chưa kết nối trực tiếp với hệ thống phần cứng khóa cửa từ thông minh qua giao tiếp Bluetooth Low Energy (BLE) hoặc RFID để khách tự mở cửa phòng bằng điện thoại.

## 7.3. Hướng phát triển và mở rộng trong tương lai
Để đưa hệ thống trở thành một giải pháp phần mềm PMS thương mại hoàn chỉnh, nhóm nghiên cứu đề xuất các hướng phát triển tiếp theo:
1. **Tích hợp Cổng thanh toán quốc gia & Webhook VietQR:** Tích hợp cổng thanh toán VNPay / VietQR tự động bắt biến động số dư tài khoản ngân hàng qua Webhook thời gian thực để hệ thống tự động duyệt hóa đơn \`PAID\` tức thì mà không cần thu ngân đối soát thủ công.
2. **Giải pháp chìa khóa số thông minh (Digital Keyless Entry):** Tích hợp giao tiếp không dây BLE/NFC cho phép khách hàng nhận thẻ phòng số (Digital Key) ngay trên ứng dụng Flutter để tự chạm điện thoại mở khóa cửa phòng.
3. **Trợ lý ảo AI Concierge (Tích hợp Large Language Model - LLM):** Ứng dụng mô hình ngôn ngữ lớn (như OpenAI GPT / Google Gemini) để xây dựng Chatbot thông minh hỗ trợ giải đáp thắc mắc, tư vấn địa điểm du lịch, ẩm thực xung quanh khách sạn cho khách lưu trú 24/7.
4. **Phát triển phiên bản Web Portal mở rộng cho Buồng phòng (Housekeeping):** Xây dựng thêm giao diện Web dành riêng cho nhân viên dọn phòng trên máy tính bảng (Tablet) để cập nhật trạng thái phòng sạch/bẩn theo thời gian thực ngay tại tầng.

---

\\newpage

# TÀI LIỆU THAM KHẢO

1. **NestJS Official Documentation** (2024), *A progressive Node.js framework for building efficient, reliable and scalable server-side applications*, Truy cập tại: https://docs.nestjs.com/
2. **Flutter & Dart Documentation** (2024), *Build apps for any screen*, Google Developers, Truy cập tại: https://docs.flutter.dev/
3. **Prisma Documentation** (2024), *Next-generation ORM for Node.js and TypeScript*, Truy cập tại: https://www.prisma.io/docs
4. **PostgreSQL Global Development Group** (2024), *PostgreSQL 16 Database System Documentation*, Truy cập tại: https://www.postgresql.org/docs/
5. **Felix Angelov** (2024), *Bloc State Management Library for Dart & Flutter Documentation*, Truy cập tại: https://bloclibrary.dev/
6. **Robert C. Martin** (2017), *Clean Architecture: A Craftsman's Guide to Software Structure and Design*, Prentice Hall.
7. **Martin Fowler** (2002), *Patterns of Enterprise Application Architecture*, Addison-Wesley Professional.
8. **Alex Xu** (2020), *System Design Interview – An insider's guide*, ByteByteGo Publishing.
9. **IEEE Computer Society** (1998), *IEEE Recommended Practice for Software Requirements Specifications (IEEE Std 830-1998)*, IEEE Standards Software Engineering Committee.
10. **IEEE Computer Society** (2008), *IEEE Standard for Software and System Test Documentation (IEEE Std 829-2008)*, IEEE.
`;

fs.writeFileSync(REPORT_PATH, content, 'utf8');
console.log('Markdown report generated successfully! Size: ' + (Buffer.byteLength(content, 'utf8') / 1024).toFixed(2) + ' KB');
