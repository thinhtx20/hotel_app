# TÀI LIỆU THIẾT KẾ KIẾN TRÚC VÀ CHI TIẾT HỆ THỐNG (SAD - SOFTWARE ARCHITECTURE & DESIGN DOCUMENT)
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL

---

## 1. TỔNG QUAN KIẾN TRÚC HỆ THỐNG (SYSTEM ARCHITECTURE OVERVIEW)

### 1.1. Phong cách kiến trúc (Architectural Styles)
Hệ thống Luxe Grand Hotel được xây dựng theo phong cách kiến trúc **Client-Server phân tán**, kết hợp giữa:
1. **Modular Monolith (Backend):** Toàn bộ mã nguồn máy chủ được gom thành một đơn vị triển khai duy nhất (Single Deployable Unit) nhưng được chia thành các Module độc lập cao (High Cohesion, Low Coupling). Mô hình này giúp tối ưu hóa chi phí vận hành hạ tầng, đảm bảo tính nhất quán của các giao dịch cơ sở dữ liệu (ACID Transactions) mà không phải đối mặt với sự phức tạp của kiến trúc Microservices phân tán.
2. **Feature-First Clean Architecture (Mobile Client):** Mã nguồn ứng dụng Flutter được cấu trúc theo từng nhóm tính năng (Feature-driven), phân tách độc lập giữa tầng Dữ liệu (Data), tầng Nghiệp vụ/Trạng thái (Domain/BLoC) và tầng Giao diện (Presentation).
3. **RESTful API & JSON Protocol:** Chuẩn giao tiếp không trạng thái (Stateless) qua giao thức mạng bảo mật HTTPS.

```mermaid
graph TD
    subgraph ClientTier [TẦNG CLIENT - FLUTTER MOBILE]
        UI[Presentation: UI Screens & Custom Widgets]
        BLOC[Domain: BLoC State Management]
        REPO[Data: Repositories & Data Sources]
        DIO[Network: Dio HTTP Client + Interceptors]
        UI --> BLOC
        BLOC --> REPO
        REPO --> DIO
    end

    subgraph NetworkGateway [TẦNG MẠNG & AN TOÀN]
        DIO <-->|HTTPS / REST API / Bearer Token| SSL[SSL/TLS Termination & Reverse Proxy]
    end

    subgraph BackendTier [TẦNG MÁY CHỦ - NESTJS ENTERPRISE]
        SSL --> GUARDS[Guards: JWT Auth & RBAC Roles]
        GUARDS --> INTERCEPTORS[Interceptors: Logging & Transform]
        INTERCEPTORS --> CONTROLLERS[REST Controllers]
        CONTROLLERS --> SERVICES[Core Business Services]
        SERVICES --> CRON[Schedule Cron Services]
    end

    subgraph DataStorageTier [TẦNG DỮ LIỆU & DỊCH VỤ NGOÀI]
        SERVICES --> PRISMA[Prisma ORM Client]
        PRISMA --> PG[(PostgreSQL Database)]
        SERVICES --> REDIS[(Redis Cache)]
        SERVICES --> ES[(Elasticsearch Engine)]
        SERVICES --> FCM[Firebase Cloud Messaging]
        SERVICES --> SMTP[SMTP Mailer Service]
    end
```

---

## 2. THIẾT KẾ CHI TIẾT BACKEND (NESTJS ENTERPRISE ARCHITECTURE)

### 2.1. Cấu trúc Module Dependency Graph
Mỗi module trong NestJS chịu trách nhiệm trọn vẹn cho một miền nghiệp vụ, bao gồm: `Controller` (Tiếp nhận HTTP request), `Service` (Xử lý nghiệp vụ lõi), `DTO` (Định nghĩa và kiểm định dữ liệu đầu vào) và các `Entity/Event`.

```mermaid
graph TD
    AppModule --> AuthModule
    AppModule --> UsersModule
    AppModule --> RoomsModule
    AppModule --> RoomTypesModule
    AppModule --> BookingsModule
    AppModule --> InvoicesModule
    AppModule --> ShiftsModule
    AppModule --> ServicesModule
    AppModule --> AnalyticsModule
    AppModule --> NotificationsModule
    AppModule --> PrismaModule
    AppModule --> RedisModule
    AppModule --> ElasticsearchModule
    AppModule --> MailModule

    BookingsModule -.-> PrismaModule
    BookingsModule -.-> RoomsModule
    BookingsModule -.-> NotificationsModule
    InvoicesModule -.-> PrismaModule
    InvoicesModule -.-> ShiftsModule
    ShiftsModule -.-> PrismaModule
    AnalyticsModule -.-> PrismaModule
```

### 2.2. Vòng đời xử lý một HTTP Request (Request Lifecycle)
Mọi request gửi tới Backend đều trải qua một chuỗi các lớp lọc bảo mật và chuẩn hóa nghiêm ngặt:

```mermaid
sequenceDiagram
    autonumber
    actor Client as Flutter Client
    participant Guard as JwtAuthGuard & RolesGuard
    participant Interceptor as Transform & Logging Interceptor
    participant Pipe as ValidationPipe
    participant Controller as Controller Layer
    participant Service as Business Service Layer
    participant Prisma as Prisma ORM & Database

    Client->>Guard: Gửi HTTP Request kèm Bearer Token
    alt Token không hợp lệ hoặc thiếu quyền
        Guard-->>Client: 401 Unauthorized / 403 Forbidden
    else Hợp lệ
        Guard->>Interceptor: Cho phép đi tiếp
        Interceptor->>Pipe: Kiểm định DTO đầu vào
        alt Dữ liệu DTO sai quy cách
            Pipe-->>Client: 400 Bad Request (Chi tiết lỗi validation)
        else Hợp lệ
            Pipe->>Controller: Chuyển dữ liệu sạch vào Handler
            Controller->>Service: Gọi hàm xử lý logic
            Service->>Prisma: Thực thi truy vấn CSDL / Transaction
            Prisma-->>Service: Dữ liệu thực thể
            Service-->>Controller: Dữ liệu kết quả nghiệp vụ
            Controller-->>Interceptor: Trả về kết quả
            Interceptor-->>Client: Chuẩn hóa Response Envelope { success: true, data: ... }
        end
    end
```

### 2.3. Hiện thực hóa các thành phần cốt lõi phía Server

#### 1. Bộ lọc ngoại lệ toàn cục (Global Exception Filter)
Mọi lỗi phát sinh trong hệ thống (Validation error, Not found, Conflict, Internal server error) đều được bắt và định dạng theo quy chuẩn chung:
```typescript
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status = exception instanceof HttpException 
      ? exception.getStatus() 
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const message = exception instanceof HttpException
      ? (exception.getResponse() as any)?.message || exception.message
      : 'Đã xảy ra lỗi máy chủ nội bộ. Vui lòng thử lại sau.';

    response.status(status).json({
      statusCode: status,
      success: false,
      message: Array.isArray(message) ? message[0] : message,
      timestamp: new Date().toISOString(),
    });
  }
}
```

#### 2. Decorators phân quyền động (Role-Based Access Control)
```typescript
export const ROLES_KEY = 'roles';
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);

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
```

---

## 3. THIẾT KẾ CHI TIẾT FRONTEND (FLUTTER MOBILE ARCHITECTURE)

### 3.1. Cấu trúc thư mục Feature-First
```
lib/
├── core/                  # Thành phần cốt lõi của ứng dụng
│   ├── constants/         # Màu sắc, font chữ, đường dẫn API
│   ├── network/           # Cấu hình Dio Client, PrettyLogger, AuthInterceptor
│   ├── theme/             # Theme sáng/tối chuẩn phong cách 5 sao
│   └── utils/             # Helper hàm xử lý định dạng tiền tệ VNĐ, ngày tháng
├── di/                    # Dependency Injection Container (GetIt setup)
├── shared/                # Widget dùng chung toàn app (Buttons, Textfields, Shimmer)
└── features/              # Chia theo từng module nghiệp vụ
    ├── auth/              # Đăng nhập, Đăng ký, Quên mật khẩu OTP
    │   ├── bloc/          # AuthBloc, AuthEvent, AuthState
    │   ├── screens/       # LoginScreen, RegisterScreen, ForgotPasswordScreen
    │   └── data/          # AuthRepository & RemoteDataSource
    ├── customer/          # Trải nghiệm khách hàng
    │   ├── screens/       # HomeScreen, SearchScreen, RoomDetailScreen, MyBookingsScreen
    │   └── widgets/       # CreateBookingModal, RoomCard
    ├── receptionist/      # Nghiệp vụ lễ tân & Quầy tiền sảnh
    │   ├── screens/       # RoomMatrixScreen, FrontDeskTodayScreen, ShiftCloseScreen, BookingApprovalScreen, PaymentRequestsScreen
    │   └── widgets/       # WalkInModal, ChangeRoomSheet, ShiftBanner, CheckOutSheet, AddServiceSheet
    ├── cashier/           # Nghiệp vụ thu ngân & Hóa đơn
    │   ├── bloc/          # InvoiceBloc, InvoiceEvent, InvoiceState
    │   └── screens/       # CashierInvoicesScreen, PaymentSheet, RefundSheet
    ├── admin/             # Trung tâm quản trị & Vận hành
    │   ├── bloc/          # UserBloc, TodayCheckOutsBloc
    │   ├── screens/       # AdminDashboardScreen, ReportsScreen, RoomOperationsScreen, UserManagementScreen, AdminShiftManagementScreen, ShiftDetailScreen, ServiceCatalogScreen, RoomTypeManagementScreen
    │   └── widgets/       # RevenueBarChart, OccupancyCard, EditRoomModal
    ├── profile/           # Quản lý thông tin tài khoản cá nhân
    │   └── screens/       # ProfileScreen (Hồ sơ, Đổi mật khẩu, Tải Avatar)
    └── notifications/     # Trung tâm thông báo & Cài đặt
        ├── models/        # AppNotificationModel
        ├── repositories/  # NotificationRepository
        └── screens/       # NotificationsScreen, NotificationSettingsScreen
```

### 3.2. Mô hình quản lý trạng thái BLoC (Business Logic Component)
- **Cơ chế hoạt động:** Giao diện UI chỉ phát sinh Sự kiện (Event). BLoC xử lý nghiệp vụ bất đồng bộ, phát ra Trạng thái (State). Giao diện lắng nghe bằng `BlocBuilder` để vẽ lại màn hình:

```mermaid
graph LR
    UserAction[Người dùng bấm nút] -->|Dispatch Event| Bloc[BLoC Handler]
    Bloc -->|Call Method| Repo[Repository Layer]
    Repo -->|Async HTTP| Remote[Remote API Service]
    Remote -->|JSON Data| Repo
    Repo -->|Data Model / Entity| Bloc
    Bloc -->|emit State Loading / Success / Failure| UI[BlocBuilder UI Re-render]
```

- **Xử lý trạng thái an toàn:** Toàn bộ State kế thừa `Equatable` để so sánh giá trị nông (Shallow Equality), ngăn ngừa việc vẽ lại giao diện thừa thãi khi dữ liệu không thay đổi.

---

## 4. SƠ ĐỒ TUẦN TỰ CÁC QUY TRÌNH NGHIỆP VỤ LÕI (SEQUENCE DIAGRAMS)

### 4.1. Quy trình Đặt phòng & Chống xung đột trùng lịch (Race Condition Handling)

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Khách hàng
    participant App as Flutter Mobile
    participant BE as BookingsService
    participant DB as PostgreSQL (Prisma)

    Customer->>App: Chọn ngày đến (checkIn), ngày đi (checkOut), chọn Phòng
    App->>BE: POST /api/v1/bookings { roomId, checkInDate, checkOutDate }
    BE->>DB: Bắt đầu giao dịch prisma.$transaction
    BE->>DB: Query kiểm tra lịch phòng: checkInDate < booked.checkOutDate AND checkOutDate > booked.checkInDate
    alt Đã tồn tại đơn CONFIRMED hoặc CHECKED_IN trong khoảng thời gian này
        DB-->>BE: Tồn tại Booking trùng
        BE-->>App: 409 Conflict ("Phòng đã được đặt trong khoảng thời gian này!")
        App-->>Customer: Cảnh báo phòng vừa có người đặt, mời chọn phòng khác
    else Phòng hoàn toàn trống
        DB-->>BE: Lịch trống hợp lệ
        BE->>DB: Tạo Booking mới (status = PENDING)
        BE->>DB: Tự động khởi tạo Invoice (finalAmount, paidAmount = 0, status = UNPAID)
        BE->>DB: Commit giao dịch $transaction
        DB-->>BE: Hoàn tất lưu dữ liệu
        BE-->>App: 201 Created kèm BookingCode (BK-2026-XXX)
        App-->>Customer: Hiển thị màn hình đặt phòng thành công, chờ khách sạn duyệt
    end
```

### 4.2. Quy trình Quản lý Ca trực Lễ tân & Đối soát Tiền két (Shift Reconciliation)

```mermaid
sequenceDiagram
    autonumber
    actor Staff as Lễ tân trực ca
    participant App as Flutter Front-desk
    participant BE as ShiftsService
    participant DB as PostgreSQL (Prisma)

    Staff->>App: Mở ca trực đầu ngày
    App->>BE: POST /api/v1/shifts/open { shiftType: MORNING, initialCash: 2,000,000 }
    BE->>DB: Tạo bản ghi WorkShift (status: OPEN, startTime: now())
    DB-->>BE: Trả về WorkShift
    BE-->>App: 200 OK (Ca trực đang hoạt động)

    Note over Staff, DB: Trong ca trực: Thu tiền mặt phòng 101 (1,200,000đ), phòng 102 (2,000,000đ)

    Staff->>App: Cuối ca, bấm "Chốt ca trực"
    Staff->>App: Kiểm đếm tiền mặt thực tế trong két và nhập actualCash = 5,100,000đ
    App->>BE: POST /api/v1/shifts/close { actualCash: 5100000, differenceReason: "..." }
    BE->>DB: Tính tổng tiền mặt thu được trong ca: sum(Payment where shiftId & method = CASH) -> 3,200,000đ
    BE->>BE: Tính expectedCash = initialCash (2M) + 3.2M = 5,200,000đ
    BE->>BE: Tính chênh lệch: cashDifference = actualCash (5.1M) - expectedCash (5.2M) = -100,000đ
    alt cashDifference != 0 VÀ không có differenceReason
        BE-->>App: 400 Bad Request ("Bắt buộc giải trình khi két có chênh lệch!")
        App-->>Staff: Yêu cầu nhập lý do chênh lệch 100.000 VNĐ
    else Hợp lệ
        BE->>DB: Cập nhật WorkShift: status = CLOSED, endTime = now(), cashDifference = -100,000
        DB-->>BE: Lưu hoàn tất
        BE-->>App: 200 OK (Chốt ca thành công, xuất phiếu bàn giao ca)
        App-->>Staff: Hiển thị biên bản chốt ca và bàn giao cho ca tiếp theo
    end
```

### 4.3. Quy trình Xem trước Hóa đơn & Quyết toán Trả phòng (Checkout Preview & Settlement)

```mermaid
sequenceDiagram
    autonumber
    actor Staff as Lễ tân / Thu ngân
    participant App as Flutter Front-desk
    participant BE as BookingsService
    participant DB as PostgreSQL (Prisma)

    Staff->>App: Chạm thẻ phòng đang ở (OCCUPIED) -> Bấm "Trả phòng"
    App->>BE: GET /api/v1/bookings/:id/checkout-preview
    BE->>DB: Query thông tin Booking, RoomType, Invoice, Payments, ExtraServiceOrders
    BE->>BE: Tính toán số đêm thực tế, tiền phòng, phụ thu, tổng tiền minibar/dịch vụ
    BE->>BE: Tính amountDue = finalAmount - sum(CONFIRMED payments)
    BE-->>App: 200 OK kèm Bảng kê chi phí minh bạch
    App-->>Staff: Hiển thị bảng kê chi phí Xem trước (Checkout Preview)
    alt amountDue > 0 (Khách còn thiếu tiền)
        Staff->>App: Bấm "Thu tiền dứt điểm" -> Thu tiền mặt / Chuyển khoản
        App->>BE: POST /api/v1/invoices/:id/pay
        BE->>DB: Ghi nhận Payment CONFIRMED -> cập nhật paidAmount
        BE-->>App: 200 OK (Hóa đơn đã thanh toán đủ)
    end
    Staff->>App: Bấm "Hoàn tất trả phòng"
    App->>BE: POST /api/v1/bookings/:id/check-out { keyReturned: true }
    BE->>DB: Cập nhật booking.status = CHECKED_OUT, room.status = CLEANING
    BE-->>App: 200 OK
    App-->>Staff: Phòng chuyển sang màu vàng CLEANING (chờ buồng phòng dọn dẹp)
```

### 4.4. Quy trình Đối soát & Từ chối Giao dịch Chuyển khoản Nghi vấn (Payment Rejection)

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Khách hàng
    actor Cashier as Thu ngân
    participant App as Mobile App
    participant BE as InvoicesService
    participant DB as PostgreSQL (Prisma)

    Customer->>App: Nhập mã giao dịch FT26... -> Bấm "Tôi đã chuyển tiền"
    App->>BE: POST /api/v1/invoices/:id/payments { method: BANK_TRANSFER, status: PENDING }
    BE->>DB: Tạo Payment (status: PENDING)
    BE-->>App: 201 Created (Khoản thu ở trạng thái Chờ đối soát)

    Cashier->>App: Mở màn hình "Yêu cầu thanh toán" (Payment Requests)
    App->>BE: GET /api/v1/invoices/payment-requests
    BE-->>App: Danh sách các giao dịch PENDING
    Cashier->>Cashier: Kiểm tra sao kê tài khoản ngân hàng thực tế
    alt Tiền chưa vào tài khoản hoặc mã tham chiếu giả mạo
        Cashier->>App: Bấm nút "Từ chối" kèm lý do: "Chưa nhận được tiền vào tài khoản"
        App->>BE: POST /api/v1/invoices/payments/:paymentId/reject { reason: "..." }
        BE->>DB: Cập nhật Payment: status = REJECTED, rejectReason = "..." (paidAmount KHÔNG đổi)
        BE-->>App: 200 OK
        App-->>Customer: Hiển thị thông báo yêu cầu chuyển khoản bị từ chối kèm lý do
    else Tiền đã vào tài khoản đầy đủ
        Cashier->>App: Bấm "Xác nhận đã nhận tiền"
        App->>BE: POST /api/v1/invoices/payments/:paymentId/confirm
        BE->>DB: Cập nhật Payment: status = CONFIRMED, cộng tiền vào Invoice.paidAmount
        BE-->>App: 200 OK (Hóa đơn cập nhật số dư đã thanh toán)
    end
```

### 4.5. Cơ chế Đồng bộ Dữ liệu Thời gian thực (Realtime SSE & Push Notification)

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Quản trị viên
    actor Staff as Lễ tân / Buồng phòng
    participant AppStaff as App Lễ tân
    participant AppAdmin as App Admin
    participant SseService as SSE Gateway (/rooms/stream, /users/stream)
    participant FCM as Firebase Cloud Messaging

    Staff->>AppStaff: Đổi trạng thái phòng 101 từ CLEANING sang AVAILABLE
    AppStaff->>SseService: PATCH /api/v1/rooms/101/status { status: AVAILABLE }
    SseService->>SseService: Phát sự kiện Broadcast "room.status_changed"
    par Phát realtime qua SSE
        SseService-->>AppStaff: Cập nhật Room 101 -> Xanh lá (AVAILABLE)
        SseService-->>AppAdmin: Cập nhật Room 101 trên Dashboard & Sơ đồ phòng tức thì
    and Gửi thông báo đẩy nền qua FCM
        SseService->>FCM: Gửi push notification tới các máy có đăng ký fcmToken
        FCM-->>AppStaff: Hiển thị In-App Notification Banner "Phòng 101 sẵn sàng đón khách"
    end
```

---

## 5. THIẾT KẾ TẦNG DỮ LIỆU & TỐI ƯU HÓA (DATABASE DESIGN & OPTIMIZATION)

### 5.1. Chiến lược đánh chỉ mục (Database Indexing Strategy)
Để đảm bảo thời gian truy vấn dưới 50ms khi dữ liệu khách sạn tăng trưởng lớn, các chỉ mục (B-Tree Indexes) sau đây được thiết lập:
- **Bảng `rooms`:** `@@index([status])`, `@@index([floor])`, `@@index([roomTypeId])`.
- **Bảng `bookings`:** `@@index([status])`, `@@index([checkInDate])`, `@@index([checkOutDate])`, `@@index([roomId, status])`, `@@index([customerId, status])`.
- **Bảng `invoices`:** `@@index([paymentStatus])`, `@@index([paidAt])`, `@@index([issuedById])`.
- **Bảng `payments`:** `@@index([invoiceId])`, `@@index([status])`, `@@index([shiftId])`, `@@index([confirmedById, status, confirmedAt])`.
- **Bảng `work_shifts`:** `@@index([staffId])`, `@@index([status])`, `@@index([startTime])`.

### 5.2. Toàn vẹn tham chiếu (Referential Integrity Constraints)
- Khi một `Booking` bị xóa, toàn bộ `Invoice`, `Payment` và `ExtraServiceOrder` liên quan sẽ bị xóa theo cơ chế **CASCADE** để tránh dữ liệu rác mồ côi.
- Không cho phép xóa một `RoomType` nếu vẫn còn `Room` đang tham chiếu (Ràng buộc **RESTRICT**).
- Không cho phép xóa một `User` nếu người đó đang là chủ thể của một đơn đặt phòng hoặc ca trực đang hoạt động (Ràng buộc **RESTRICT**).

---

## 6. THIẾT KẾ TÍCH HỢP HỆ THỐNG NGOÀI (EXTERNAL INTEGRATIONS)

### 6.1. Tầng đệm Redis Cache (In-Memory Caching Strategy)
- **Chiến lược:** Áp dụng mô hình **Cache-Aside Pattern**.
- **Dữ liệu đệm:** Danh mục loại phòng (`room_types`), Danh mục dịch vụ khách sạn (`hotel_services`), Thống kê doanh thu tháng (`revenue_summary`).
- **Thời gian hết hạn (TTL):** Thiết lập TTL 600 giây (10 phút) đối với dữ liệu thống kê, 3.600 giây đối với danh mục tiện ích.
- **Xóa đệm chủ động (Cache Invalidation):** Khi Admin cập nhật giá phòng hoặc thêm dịch vụ mới, sự kiện `RoomUpdatedEvent` sẽ tự động xóa các khóa Cache tương ứng trên Redis.

### 6.2. Máy chủ tìm kiếm Elasticsearch
- Dữ liệu phòng và loại phòng được đồng bộ tự động sang Elasticsearch Index `hotel_rooms`.
- Truy vấn hỗ trợ phân tích từ khóa mờ (Fuzzy matching), tìm kiếm đa tiêu chí (giá, tiện nghi, số người) mà không làm tăng tải tính toán trên máy chủ cơ sở dữ liệu chính PostgreSQL.

### 6.3. Thông báo đẩy Firebase Cloud Messaging (FCM)
- Mỗi thiết bị người dùng sau khi đăng nhập thành công sẽ gửi mã `fcmToken` lên Backend lưu vào bảng `users`.
- Khi trạng thái đơn phòng thay đổi (`CONFIRMED`, `CHECKED_IN`, `CHECKED_OUT`), Service thông báo sẽ gửi payload qua `firebase-admin` tới đúng token của thiết bị đó.

---

## 7. KIẾN TRÚC AN TOÀN VÀ BẢO MẬT (SECURITY ARCHITECTURE)

1. **Mã hóa truyền thông:** Bắt buộc chứng chỉ SSL/TLS 1.3 cho toàn bộ kết nối mạng giữa Mobile App và Server.
2. **Mã hóa dữ liệu lưu trữ:** Mật khẩu người dùng được băm qua Bcrypt với 10 vòng lặp muối (Salt Rounds). Mã bí mật JWT (`JWT_SECRET`) được lưu trong biến môi trường bảo mật, không đưa lên kho mã nguồn.
3. **Phòng chống các cuộc tấn công phổ biến:**
   - **SQL Injection:** Triệt tiêu hoàn toàn nhờ Prisma ORM Parameterized Query.
   - **XSS (Cross-Site Scripting):** Sử dụng thư viện `class-validator` và `class-transformer` để lọc sạch (Sanitize) mọi chuỗi ký tự đầu vào.
   - **Rate Limiting:** Sử dụng `@nestjs/throttler` giới hạn tối đa 100 requests/phút cho mỗi địa chỉ IP để chống tấn công từ chối dịch vụ (DoS/Brute Force) vào các cổng đăng nhập/quên mật khẩu.
