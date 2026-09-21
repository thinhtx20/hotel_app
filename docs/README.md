# BỘ TÀI LIỆU DỰ ÁN HOÀN CHỈNH (COMPLETE PROJECT DOCUMENTATION SUITE)
## HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL
### BACKEND: NESTJS & PRISMA | FRONTEND: FLUTTER MOBILE (IOS / ANDROID)

---

## TỔNG QUAN HỆ THỐNG TÀI LIỆU

Thư mục `docs/` chứa trọn vẹn bộ tài liệu chuẩn kỹ thuật phần mềm (Software Engineering Standards) phục vụ công tác nghiên cứu, nghiệm thu khóa luận tốt nghiệp và bàn giao vận hành hệ thống phần mềm **Luxe Grand Hotel**:

```
d:\duan\hotel_app\
├── docs/                                                 # BỘ TÀI LIỆU DỰ ÁN TOÀN DIỆN
│   ├── README.md                                         # Mục lục điều hướng tổng quan (Tài liệu này)
│   ├── 01_SRS_Software_Requirements_Specification.md     # Đặc tả yêu cầu phần mềm (Chuẩn IEEE 830)
│   ├── 02_SAD_Software_Architecture_Design.md            # Thiết kế kiến trúc & chi tiết hệ thống (SAD/SDD)
│   ├── 03_API_Specification_Full.md                     # Đặc tả toàn bộ RESTful API & JSON Schemas
│   ├── 04_Test_Plan_And_Test_Cases.md                    # Kế hoạch kiểm thử & 27 kịch bản Test Cases (IEEE 829)
│   ├── 05_User_Manual_Guide.md                           # Cẩm nang hướng dẫn sử dụng (Customer, Staff, Admin)
│   ├── 06_Deployment_And_DevOps_Guide.md                 # Hướng dẫn cài đặt, cấu hình môi trường & DevOps
│   └── 07_Project_Management_And_Sprint_Report.md        # Báo cáo quản lý dự án Agile/Scrum & Quản lý rủi ro
│
├── BAO_CAO_TOT_NGHIEP_HE_THONG_QUAN_LY_KHACH_SAN.md      # Báo cáo Khóa luận tốt nghiệp (Bản Markdown đầy đủ)
├── Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx              # Báo cáo Khóa luận tốt nghiệp (Bản Microsoft Word chuẩn in ấn)
└── report_assets/                                        # Thư mục hình ảnh sơ đồ & giao diện ứng dụng nhúng trong báo cáo
```

---

## DANH MỤC CHI TIẾT CÁC TẬP TÀI LIỆU

| STT | Mã tài liệu | Tên tài liệu chi tiết | Đối tượng sử dụng | Mô tả nội dung cốt lõi |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **SRS** | [01_SRS_Software_Requirements_Specification.md](file:///d:/duan/hotel_app/docs/01_SRS_Software_Requirements_Specification.md) | BA, Dev, QA, GVHD | Đặc tả trọn vẹn 27 yêu cầu chức năng (FR-01 đến FR-27), yêu cầu phi chức năng, tiêu chuẩn bảo mật và ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix). |
| **2** | **SAD** | [02_SAD_Software_Architecture_Design.md](file:///d:/duan/hotel_app/docs/02_SAD_Software_Architecture_Design.md) | Solution Architect, Dev | Thiết kế kiến trúc phân tầng Modular Monolith (NestJS) & Feature-First (Flutter), 5 Sơ đồ tuần tự nghiệp vụ lõi (Đặt phòng, Ca trực, Checkout Preview, Từ chối chuyển khoản, Realtime SSE & FCM). |
| **3** | **API** | [03_API_Specification_Full.md](file:///d:/duan/hotel_app/docs/03_API_Specification_Full.md) | Backend, Mobile Dev | Đặc tả chi tiết 40+ Endpoints RESTful của 10 phân hệ (Auth, Users RBAC, Rooms, Bookings, Checkout Preview, Payments, Shifts, Analytics, Notifications, Media Upload), DTO và mã lỗi nghiệp vụ. |
| **4** | **TEST** | [04_Test_Plan_And_Test_Cases.md](file:///d:/duan/hotel_app/docs/04_Test_Plan_And_Test_Cases.md) | QA/QC, Tester, Hội đồng | Kế hoạch kiểm thử chuẩn IEEE 829, ma trận 42 kịch bản kiểm thử chi tiết bao phủ 100% các phân hệ nghiệp vụ, đạt tỷ lệ 100% PASS. |
| **5** | **MANUAL**| [05_User_Manual_Guide.md](file:///d:/duan/hotel_app/docs/05_User_Manual_Guide.md) | Người dùng cuối, Lễ tân, Quản lý | Cẩm nang hướng dẫn thao tác từng bước trực quan cho Khách hàng (Đặt phòng, QR chuyển khoản, Hồ sơ, FCM), Lễ tân (Room Matrix, Walk-in, Checkout Preview, Sổ ca) và Admin (Dashboard, Nhân sự, Cưỡng chế chốt ca). |
| **6** | **DEVOPS**| [06_Deployment_And_DevOps_Guide.md](file:///d:/duan/hotel_app/docs/06_Deployment_And_DevOps_Guide.md) | DevOps, System Admin | Hướng dẫn cấu hình file `.env`, lệnh Prisma migration, Docker Compose tự động hóa, quy trình build APK Android/iOS và quy trình sao lưu CSDL. |
| **7** | **SCRUM** | [07_Project_Management_And_Sprint_Report.md](file:///d:/duan/hotel_app/docs/07_Project_Management_And_Sprint_Report.md) | Project Manager, Agile Team | Báo cáo tiến độ phát triển theo 5 Sprints, cơ cấu phân rã công việc (WBS 27 User Stories), ma trận xử lý rủi ro và đánh giá nghiệm thu sản phẩm đạt 100% cam kết. |
| **8** | **THESIS**| [Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx](file:///d:/duan/hotel_app/Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx) | Hội đồng chấm Khóa luận | Cuốn Báo cáo Khóa luận tốt nghiệp hoàn chỉnh định dạng Word (.docx), chuẩn in ấn A4, có sẵn trang bìa, lời cảm ơn, mục lục, bảng biểu và hình ảnh nhúng. |

---

## HƯỚNG DẪN TRÌNH CHIẾU & BẢO VỆ ĐỒ ÁN
- Sử dụng cuốn báo cáo Word **[Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx](file:///d:/duan/hotel_app/Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx)** để in ấn đóng quyển nộp hội đồng khoa học.
- Sử dụng tài liệu **[01_SRS](file:///d:/duan/hotel_app/docs/01_SRS_Software_Requirements_Specification.md)** và **[02_SAD](file:///d:/duan/hotel_app/docs/02_SAD_Software_Architecture_Design.md)** để trả lời các câu hỏi phản biện về kiến trúc phần mềm, cơ sở dữ liệu và xử lý tranh chấp giao dịch.
- Sử dụng tài liệu **[04_TEST](file:///d:/duan/hotel_app/docs/04_Test_Plan_And_Test_Cases.md)** để chứng minh chất lượng kiểm thử của phần mềm.
- Sử dụng tài liệu **[05_MANUAL](file:///d:/duan/hotel_app/docs/05_User_Manual_Guide.md)** và **[06_DEVOPS](file:///d:/duan/hotel_app/docs/06_Deployment_And_DevOps_Guide.md)** để thực hiện phần demo trực tiếp trên thiết bị di động trước hội đồng.
