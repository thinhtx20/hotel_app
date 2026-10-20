// Chương 6 của báo cáo kiến trúc: đối chiếu 4 nhóm / 9 kiểu kiến trúc (theo đề cương học phần)
// với cách hiện thực trong dự án, trả lời riêng cho Backend (NestJS) và Frontend (Flutter).
// Mọi minh chứng đều trỏ về mã nguồn thật của Hotel-Management/src và hotel_app/lib.

const BE = 'Backend – Hotel-Management (NestJS)';
const FE = 'Frontend – hotel_app (Flutter)';
const W3 = [2600, 6200, 6200];

module.exports = function buildArchitectureStylesChapter(h) {
  const { heading1, heading2, heading3, para, bullet, table, callout, image, caption } = h;
  const gap = () => new (h.Paragraph)({ spacing: { before: 120 } });
  // Bảng so sánh một kiểu kiến trúc ở hai phía BE / FE
  const compare = (rows) => table(['Khía cạnh', BE, FE], rows, W3);

  return [
    heading1('CHƯƠNG 6: CÁC KIỂU KIẾN TRÚC ÁP DỤNG TRONG HỆ THỐNG'),
    para('Theo cách phân loại của học phần, các kiểu kiến trúc phần mềm được chia thành bốn nhóm: giao tiếp, triển khai, miền và cấu trúc. Dự án gồm hai phần mã nguồn: Backend Hotel-Management (NestJS, TypeScript) và Frontend hotel_app (Flutter, Dart). Chương này trả lời lần lượt từng kiểu kiến trúc cho cả hai phần, kèm minh chứng từ mã nguồn và các biểu đồ UML ở Chương 1–5.'),

    // ------------------------------------------------------------------
    heading2('6.1. Bảng phân loại các kiểu kiến trúc'),
    table(
      ['Phân loại', 'Kiểu kiến trúc', 'Backend (NestJS)', 'Frontend (Flutter)'],
      [
        ['Giao tiếp', 'Kiến trúc hướng dịch vụ, kiến trúc bus thông điệp',
          'Cung cấp 11 nhóm dịch vụ REST /api/v1 (Swagger); bus sự kiện RxJS phát qua SSE; gửi push qua FCM.',
          'Tiêu thụ dịch vụ qua 9 Repository; nhận sự kiện qua SseClient và FCM; luồng Event → State của BLoC.'],
        ['Triển khai', 'Client/Server, N-tầng, 3-tầng',
          'Server tập trung nghiệp vụ; là tầng ứng dụng, nối tới tầng dữ liệu, cache, tìm kiếm, dịch vụ ngoài.',
          'Client cho ba vai trò; là tầng trình bày, chỉ giao tiếp với tầng ứng dụng, FCM và CDN ảnh.'],
        ['Miền', 'Thiết kế hướng miền',
          '9 module theo ngữ cảnh nghiệp vụ; aggregate Booking, Invoice; quy tắc miền trong Domain Service.',
          'Thư mục features theo vai trò nghiệp vụ; Model và enum Dart dùng chung thuật ngữ với Backend.'],
        ['Cấu trúc', 'Dựa vào thành phần, hướng đối tượng, kiến trúc theo tầng',
          '15 module + DI; lớp TypeScript; Controller → Service → Data Access.',
          'Widget, Repository, BLoC + GetIt; lớp Dart; Presentation → BLoC → Repository → Network.'],
      ],
      [1800, 3000, 5100, 5100],
    ),

    // ==================================================================
    heading2('6.2. Nhóm kiến trúc giao tiếp', { newPage: true }),
    heading3('6.2.1. Kiến trúc hướng dịch vụ (Service-Oriented Architecture)'),
    para('Kiến trúc hướng dịch vụ đóng gói chức năng thành các dịch vụ có giao diện (hợp đồng) rõ ràng. Bên cung cấp và bên sử dụng giao tiếp qua giao thức chuẩn, không phụ thuộc vào cách cài đặt bên trong của nhau. Trong dự án, Backend là bên cung cấp dịch vụ, Frontend là bên tiêu thụ dịch vụ.'),
    compare([
      ['Vai trò', 'Bên cung cấp: 11 controller công bố dịch vụ REST tại /api/v1; hợp đồng mô tả bằng Swagger / OpenAPI với 110 thao tác @ApiOperation, tra cứu tại /api/docs.', 'Bên tiêu thụ: mỗi Repository trong shared/repositories ứng với một nhóm dịch vụ (BookingRepository ↔ /bookings, InvoiceRepository ↔ /invoices, …).'],
      ['Hợp đồng dữ liệu', 'DTO + ValidationPipe kiểm tra đầu vào; TransformInterceptor bọc mọi phản hồi theo một định dạng chung.', 'ApiEndpoints gom mọi đường dẫn về một chỗ; ApiResult.unwrapMap / unwrapList đọc định dạng phản hồi chung; Model.fromJson() ánh xạ dữ liệu.'],
      ['Phi trạng thái và bảo mật', 'Mỗi request tự mang JWT; JwtAuthGuard và RolesGuard kiểm tra ở từng endpoint.', 'DioClient tự gắn Bearer token qua interceptor; gặp 401 thì làm mới token, dùng mutex để chỉ một request gọi refresh.'],
      ['Dịch vụ bên ngoài', 'Bọc trong adapter: NotificationsService (FCM), MailService (SMTP), UploadService (Cloudinary), ElasticsearchService.', 'Dùng trực tiếp Firebase Cloud Messaging (firebase_messaging) và tải ảnh phòng từ CDN Cloudinary (cached_network_image); tải ảnh lên đi qua dịch vụ /upload của Backend.'],
    ]),
    gap(),
    table(
      ['Nhóm dịch vụ', 'Endpoint (Backend)', 'Bên gọi (Frontend)', 'Vai trò sử dụng'],
      [
        ['Xác thực', '/api/v1/auth', 'AuthBloc (DioClient)', 'Khách hàng, nhân viên'],
        ['Đặt phòng', '/api/v1/bookings', 'BookingRepository', 'Khách hàng, lễ tân'],
        ['Phòng, loại phòng', '/api/v1/rooms, /api/v1/room-types, SSE /rooms/stream', 'RoomRepository', 'Mọi vai trò'],
        ['Hóa đơn, thanh toán', '/api/v1/invoices', 'InvoiceRepository, InvoiceBloc', 'Thu ngân, khách hàng'],
        ['Ca trực', '/api/v1/shifts', 'ShiftRepository', 'Lễ tân / thu ngân'],
        ['Dịch vụ khách sạn', '/api/v1/services', 'ServiceRepository', 'Khách hàng, lễ tân'],
        ['Người dùng', '/api/v1/users, SSE /users/stream', 'UserRepository, UserBloc', 'Quản trị viên'],
        ['Thống kê', '/api/v1/analytics', 'AnalyticsRepository', 'Quản trị viên'],
        ['Thông báo', '/api/v1/notifications', 'NotificationRepository', 'Mọi vai trò'],
        ['Tải tệp', '/api/v1/upload', 'UploadRepository', 'Quản trị viên, người dùng'],
      ],
      [2600, 5000, 4200, 3200],
    ),
    gap(),
    callout('Phạm vi áp dụng', 'Backend được triển khai thành một khối thống nhất (modular monolith), không tách thành nhiều dịch vụ chạy riêng (microservices). Kiến trúc hướng dịch vụ được áp dụng ở mức hợp đồng giao tiếp giữa Frontend – Backend và tích hợp dịch vụ ngoài; ranh giới module rõ ràng cho phép tách một module thành dịch vụ độc lập khi cần.'),

    // ------------------------------------------------------------------
    heading3('6.2.2. Kiến trúc bus thông điệp (Message Bus)', { newPage: true }),
    para('Trong kiến trúc bus thông điệp, các thành phần không gọi trực tiếp nhau mà trao đổi qua một kênh thông điệp chung theo cơ chế publish / subscribe: bên phát gửi sự kiện theo chủ đề, bên nhận đăng ký chủ đề mình quan tâm, hai bên không cần biết nhau. Backend là nơi phát sự kiện, Frontend là nơi nhận và hiển thị.'),
    image('message_bus_diagram', 900, 400),
    caption('Hình 6.1: Kiến trúc bus thông điệp – kênh sự kiện phòng, kênh sự kiện người dùng và kênh thông báo đẩy'),
    compare([
      ['Kênh thông điệp', 'RoomEventsService và UserEventsService dùng RxJS Subject; Firebase Cloud Messaging làm message broker bên ngoài.', 'SseClient dùng StreamController.broadcast nên nhiều màn hình cùng nghe một luồng; bên trong mỗi BLoC cũng là một luồng Event → State.'],
      ['Phát (publish)', 'BookingsService, RoomsService gọi emitStatusChanged(), emitCreated()…; AuthService, UsersService phát user.created / updated / deactivated; NotificationsService.sendToUser() gửi tới FCM.', 'Giao diện phát sự kiện vào BLoC bằng add(), ví dụ add(UserRoleFilterChanged(…)); BLoC xử lý và phát State mới.'],
      ['Nhận (subscribe)', 'RoomsController và UsersController đăng ký stream() rồi xuất thành luồng SSE GET /api/v1/rooms/stream và /users/stream.', 'RoomRepository mở SseClient tới /rooms/stream để cập nhật ma trận phòng; UserManagementScreen nghe /users/stream; PushNotificationService nghe FirebaseMessaging.onMessage, onMessageOpenedApp, onBackgroundMessage.'],
      ['Độ tin cậy', 'db-watcher quét CSDL (mặc định 15 giây, ROOM_EVENTS_POLL_MS) khi có subscriber để bắt cả thay đổi ngoài ứng dụng; lọc sự kiện trùng bằng 500 khóa gần nhất.', 'SseClient tự kết nối lại khi mất mạng (mặc định 5 giây hoặc theo trường retry của server) và công bố trạng thái kết nối qua connectionState.'],
    ]),
    para('Minh chứng trên biểu đồ tuần tự (Hình 5.1): thông điệp 32–35 và 49–51 là luồng Backend publish → SSE → Frontend cập nhật ô phòng; nhánh par cho thấy sự kiện được đẩy song song với phản hồi HTTP.'),

    // ==================================================================
    heading2('6.3. Nhóm kiến trúc triển khai', { newPage: true }),
    heading3('6.3.1. Kiến trúc Client/Server'),
    para('Kiến trúc Client/Server chia hệ thống thành bên yêu cầu dịch vụ (client) và bên cung cấp dịch vụ (server); dữ liệu và quy tắc nghiệp vụ được quản lý tập trung tại server. Trong dự án, Backend là server, Frontend là client.'),
    compare([
      ['Vai trò', 'Server duy nhất chạy trên Render (Docker, Node.js 20); nắm toàn bộ quy tắc nghiệp vụ, giao dịch và quyền truy cập dữ liệu.', 'Một ứng dụng Flutter phục vụ ba vai trò ADMIN, RECEPTIONIST, CUSTOMER với các phân hệ khách hàng, lễ tân, thu ngân, quản trị; chỉ hiển thị và gửi yêu cầu.'],
      ['Giao tiếp', 'Cung cấp REST (yêu cầu / phản hồi) và SSE (server chủ động đẩy) qua HTTPS.', 'DioClient gửi yêu cầu REST; SseClient giữ kết nối SSE để nhận dữ liệu đẩy.'],
      ['Phiên và phân quyền', 'Phát JWT, kiểm tra RolesGuard; tài khoản khách chỉ đăng nhập trên một thiết bị (activeSessionId).', 'Lưu token bằng flutter_secure_storage (TokenStorage); GoRouter redirect chặn màn hình theo vai trò (role_permissions.dart); quay về đăng nhập khi phiên bị thu hồi.'],
      ['Xử lý lỗi', 'AllExceptionsFilter trả lỗi theo một định dạng thống nhất.', 'ApiError.fromDioException() chuyển lỗi mạng / lỗi server thành thông báo cho người dùng.'],
    ]),
    para('Minh chứng: Hình 3.1 – communication path giữa node Điện thoại di động (Frontend) và Application Server (Backend) có bội số * – 1.'),

    heading3('6.3.2. Kiến trúc 3 tầng (3-tier)', { newPage: true }),
    para('Kiến trúc 3 tầng tách hệ thống thành tầng trình bày, tầng ứng dụng và tầng dữ liệu, mỗi tầng chạy trên một nút riêng. Frontend chính là tầng trình bày, Backend là tầng ứng dụng; Frontend không bao giờ truy cập cơ sở dữ liệu – dữ liệu cục bộ duy nhất của nó là token đăng nhập.'),
    image('layers_diagram', 900, 380),
    caption('Hình 6.2: Kiến trúc 3 tầng (tier) và các lớp (layer) bên trong Frontend và Backend'),
    table(
      ['Tầng', 'Phần dự án', 'Nút triển khai (Hình 3.1)', 'Trách nhiệm'],
      [
        ['Tầng trình bày', 'Frontend hotel_app (Flutter)', 'Điện thoại di động – Flutter Engine', 'Hiển thị giao diện, nhận thao tác người dùng, gọi API.'],
        ['Tầng ứng dụng', 'Backend Hotel-Management (NestJS)', 'Application Server – Docker, Node.js 20', 'Xác thực, phân quyền, quy tắc nghiệp vụ, giao dịch, phát sự kiện.'],
        ['Tầng dữ liệu', 'PostgreSQL 16 (hotel_db)', 'Database Server', 'Lưu trữ bền vững, bảo đảm tính toàn vẹn ACID.'],
      ],
      [2400, 3800, 4000, 4800],
    ),

    heading3('6.3.3. Kiến trúc N-tầng (N-tier)', { newPage: true }),
    para('Kiến trúc N-tầng mở rộng mô hình 3 tầng bằng các tầng hạ tầng chuyên biệt, mỗi tầng chạy trong container hoặc dịch vụ riêng (node:20-alpine, postgres:16-alpine, redis:7-alpine, elasticsearch:8.11.0) nên có thể nâng cấp, thay thế độc lập. Tổng cộng có sáu tầng: trình bày – ứng dụng – dữ liệu – bộ nhớ đệm – tìm kiếm – dịch vụ ngoài.'),
    compare([
      ['Tầng trực tiếp kết nối', 'Tầng dữ liệu (PostgreSQL :5432), tầng bộ nhớ đệm (Redis :6379), tầng tìm kiếm (Elasticsearch :9200), tầng dịch vụ ngoài (FCM, SMTP, Cloudinary).', 'Tầng ứng dụng (REST + SSE :443), FCM (nhận push trực tiếp) và Cloudinary CDN (tải ảnh phòng trực tiếp).'],
      ['Tầng bộ nhớ đệm', 'Redis lưu cache danh mục phòng (cache:rooms:*) và khóa phân tán lock:booking:room:{roomId} chống đặt trùng.', 'cached_network_image lưu ảnh đã tải trên máy; RoomRepository giữ danh sách loại phòng trong bộ nhớ.'],
      ['Tầng tìm kiếm', 'ElasticsearchService đánh chỉ mục lại phòng mỗi khi trạng thái thay đổi.', 'Gọi /api/v1/rooms/search; không truy cập Elasticsearch trực tiếp.'],
    ]),

    // ==================================================================
    heading2('6.4. Nhóm kiến trúc miền – Thiết kế hướng miền (Domain-Driven Design)', { newPage: true }),
    para('Thiết kế hướng miền tổ chức phần mềm xoay quanh mô hình nghiệp vụ: chia hệ thống thành các ngữ cảnh giới hạn (bounded context) và dùng một ngôn ngữ chung (ubiquitous language) giữa người làm nghiệp vụ và mã nguồn. Hai phía dự án dùng chung một bộ thuật ngữ nghiệp vụ khách sạn.'),
    compare([
      ['Ngữ cảnh giới hạn', '9 module nghiệp vụ: auth, users, room-types, rooms, bookings, invoices, shifts, services, analytics (Hình 1.1). Module chỉ công bố Service qua exports; BookingsModule nhập RoomsModule và InvoicesModule.', 'Thư mục features chia theo vai trò nghiệp vụ: customer, receptionist, cashier, admin, cùng auth, notifications, profile. Mỗi feature tự chứa screens, widgets và BLoC của mình.'],
      ['Ngôn ngữ chung', 'Prisma model và enum: Booking, Invoice, Payment, WorkShift, BookingStatus, RoomStatus, PaymentEntryType…', 'Model Dart cùng tên: BookingModel, InvoiceModel, PaymentTransactionModel, WorkShiftModel, RoomModel; enum RoomStatus, UserRole, ShiftType, ShiftStatus; hằng PaymentEntryType, PaymentEntryStatus cùng giá trị với Backend.'],
      ['Aggregate và quy tắc miền', 'Aggregate Booking (gồm Invoice, ExtraServiceOrder) và Invoice (gồm Payment) – hợp thành trong Hình 4.1; thay đổi chạy trong prisma.$transaction. Quy tắc deriveRoomStatus(), recalculateInvoiceTotals().', 'Không tự quyết định quy tắc nghiệp vụ, chỉ phản ánh trạng thái do Backend trả về (ví dụ màu ô phòng theo RoomStatus; danh sách khách chờ nhận phòng trong room_stay_actions.dart chỉ lấy đơn CONFIRMED). Quyền thao tác trên giao diện được khai báo tập trung trong role_permissions.dart (canCheckIn, …).'],
    ]),
    gap(),
    table(
      ['Thuật ngữ nghiệp vụ', 'Backend (Prisma)', 'Frontend (Dart)'],
      [
        ['Đơn đặt phòng và trạng thái đơn', 'Booking, BookingStatus', 'BookingModel'],
        ['Trạng thái phòng: trống, có khách, giữ chỗ, đang dọn, bảo trì', 'RoomStatus (AVAILABLE, OCCUPIED, RESERVED, CLEANING, MAINTENANCE, …)', 'enum RoomStatus'],
        ['Hóa đơn, tiền cọc, hoàn tiền', 'Invoice, Payment, PaymentEntryType (PAYMENT, DEPOSIT, REFUND)', 'InvoiceModel, PaymentTransactionModel, PaymentEntryType'],
        ['Thu ngân xác nhận / từ chối khoản thu', 'PaymentEntryStatus (PENDING, CONFIRMED, REJECTED)', 'PaymentEntryStatus'],
        ['Ca trực, bàn giao ca', 'WorkShift, ShiftType, ShiftStatus', 'WorkShiftModel, enum ShiftType, ShiftStatus'],
        ['Vai trò người dùng', 'Role (ADMIN, RECEPTIONIST, CUSTOMER)', 'enum UserRole'],
      ],
      [5000, 5400, 4600],
    ),
    gap(),
    callout('Phạm vi áp dụng', 'Ở Backend, các lớp thực thể là mô hình dữ liệu do Prisma sinh ra, quy tắc nghiệp vụ đặt ở Domain Service; ở Frontend, Model chỉ chứa dữ liệu và hàm fromJson. Dự án áp dụng DDD ở mức chiến lược (bounded context, ngôn ngữ chung, aggregate), chưa xây dựng mô hình miền giàu hành vi (rich domain model).'),

    // ==================================================================
    heading2('6.5. Nhóm kiến trúc cấu trúc', { newPage: true }),
    heading3('6.5.1. Kiến trúc dựa vào thành phần (Component-based)'),
    para('Kiến trúc dựa vào thành phần ghép hệ thống từ các thành phần độc lập, có giao diện rõ ràng, có thể thay thế và tái sử dụng; các thành phần được lắp ghép qua cơ chế tiêm phụ thuộc (Dependency Injection).'),
    compare([
      ['Đơn vị thành phần', '15 module tự xây dựng (9 nghiệp vụ, 6 hạ tầng) đăng ký trong AppModule; mỗi module khai báo controllers, providers, exports.', 'Widget dùng lại trong shared/widgets (AppCard, StatusBadge, CustomButton, RoomStatusUpdateSheet, ShiftKpiStrip, …), Repository và BLoC.'],
      ['Lắp ghép (DI)', 'NestJS tiêm phụ thuộc qua constructor; các module Prisma, Redis, Elasticsearch, Mail, Notifications đánh dấu @Global() để dùng chung.', 'GetIt (lib/di/injection_container.dart) đăng ký 15 thành phần: 11 lazySingleton (DioClient, TokenStorage, 9 Repository) và 4 factory BLoC (AuthBloc, InvoiceBloc, UserBloc, TodayCheckOutsBloc); BlocProvider đưa BLoC vào cây widget.'],
      ['Khả năng thay thế', 'Đổi nhà cung cấp email chỉ sửa MailService, đổi kho ảnh chỉ sửa UploadService; BookingsService không đổi.', 'Repository và BLoC nhận phụ thuộc qua constructor nên thay được bằng bản giả khi kiểm thử (ví dụ MyBookingsScreen nhận bookingRepository tùy chọn, AuthBloc nhận dioClient tùy chọn).'],
    ]),
    para('Minh chứng: Hình 2.1 – các «component» bên trong hai subsystem Hotel App (Flutter) và Hotel Management API (NestJS).'),

    heading3('6.5.2. Kiến trúc hướng đối tượng (Object-Oriented)', { newPage: true }),
    para('Backend viết bằng TypeScript, Frontend viết bằng Dart – cả hai đều là ngôn ngữ hướng đối tượng. Bốn nguyên lý của lập trình hướng đối tượng được áp dụng ở cả hai phía:'),
    table(
      ['Nguyên lý', BE, FE],
      [
        ['Đóng gói', 'RoomEventsService giữ kênh sự kiện ở private readonly events$ = new Subject<RoomEvent>(); bên ngoài chỉ dùng emitStatusChanged() và stream().', 'SseClient giữ _eventController, _reconnectTimer ở dạng private (tiền tố _), chỉ lộ events, connectionState, connect(), dispose(); TokenStorage là singleton với constructor riêng _internal().'],
        ['Kế thừa', 'PrismaService extends PrismaClient; JwtAuthGuard extends AuthGuard(\'jwt\'); JwtStrategy extends PassportStrategy.', 'UserBloc extends Bloc<UserEvent, UserState>; ThemeCubit extends Cubit<ThemeMode>; AppBlocObserver extends BlocObserver; AppPalette extends ThemeExtension.'],
        ['Đa hình', 'RolesGuard implements CanActivate, AllExceptionsFilter implements ExceptionFilter, TransformInterceptor implements NestInterceptor – framework gọi chúng qua giao diện chung.', 'Các lớp con UserFetchRequested, UserRoleFilterChanged… của abstract class UserEvent được BLoC xử lý bằng on<T>() riêng; CurrencyInputFormatter ghi đè formatEditUpdate() của TextInputFormatter.'],
        ['Trừu tượng', 'ElasticsearchService, MailService, NotificationsService che giấu SDK bên ngoài sau các phương thức nghiệp vụ.', 'Repository che giấu chi tiết HTTP và trả về Model; ApiError implements Exception gom mọi lỗi mạng về một kiểu với factory ApiError.fromDioException().'],
      ],
      W3,
    ),
    para('Minh chứng: Hình 4.1 – biểu đồ lớp với thuộc tính, thao tác, kiểu liệt kê và quan hệ giữa các lớp.'),

    heading3('6.5.3. Kiến trúc theo tầng (Layered Architecture)', { newPage: true }),
    para('Kiến trúc theo tầng tổ chức mã nguồn thành các lớp logic xếp chồng; lớp trên chỉ gọi lớp bên dưới, mỗi lớp có một trách nhiệm riêng. Khác với tầng triển khai (tier) là tách biệt về vật lý, lớp (layer) là tách biệt về logic trong cùng một ứng dụng – cả Backend và Frontend đều được phân lớp bên trong.'),
    table(
      ['Lớp', BE, FE],
      [
        ['Trình bày / API', 'Controller kèm Guard, Pipe, Interceptor (common/)', 'features/*/screens, shared/widgets'],
        ['Nghiệp vụ / trạng thái', 'Domain Service (BookingsService, InvoicesService, …)', 'BLoC / Cubit (AuthBloc, InvoiceBloc, UserBloc, …)'],
        ['Truy cập dữ liệu', 'PrismaService, RedisService, ElasticsearchService', 'Repository, Model (shared/)'],
        ['Hạ tầng', 'NotificationsService, MailService, UploadService', 'DioClient, SseClient, TokenStorage (core/)'],
        ['Quy tắc phụ thuộc', 'Không controller nào tiêm PrismaService – mọi truy cập dữ liệu đi qua Service.', 'Mũi tên «import» chỉ đi features → shared → core (Hình 1.1), không có chiều ngược lại.'],
      ],
      W3,
    ),
    gap(),
    callout('Phạm vi áp dụng', 'Frontend dùng phân tầng "mở" (relaxed layering): các feature auth, admin, cashier có lớp BLoC riêng, còn nhiều màn hình của customer và receptionist (ví dụ CreateBookingModal, RoomMatrixScreen) quản lý trạng thái bằng StatefulWidget và gọi thẳng Repository để giảm mã thừa.'),

    // ==================================================================
    heading2('6.6. Tổng hợp đối chiếu', { newPage: true }),
    table(
      ['Kiểu kiến trúc', 'Backend (NestJS)', 'Frontend (Flutter)', 'Minh chứng'],
      [
        ['Hướng dịch vụ', 'Cung cấp REST /api/v1, Swagger; adapter dịch vụ ngoài', 'Tiêu thụ qua Repository, ApiEndpoints, ApiResult', 'Hình 2.1'],
        ['Bus thông điệp', 'RoomEventsService, UserEventsService (RxJS) → SSE; FCM', 'SseClient (broadcast stream), PushNotificationService, BLoC', 'Hình 6.1, 5.1'],
        ['Client/Server', 'Server tập trung nghiệp vụ và dữ liệu', 'Client ba vai trò, DioClient + SseClient', 'Hình 3.1'],
        ['3-tầng', 'Tầng ứng dụng', 'Tầng trình bày', 'Hình 6.2, 3.1'],
        ['N-tầng', 'Nối tới PostgreSQL, Redis, Elasticsearch, FCM, SMTP, Cloudinary', 'Nối tới API, FCM, Cloudinary CDN', 'Hình 3.1, 6.2'],
        ['Thiết kế hướng miền', '9 module nghiệp vụ, aggregate Booking / Invoice', 'features theo vai trò, Model / enum cùng thuật ngữ', 'Hình 1.1, 4.1'],
        ['Dựa vào thành phần', 'Module NestJS + DI, @Global', 'Widget, GetIt, BlocProvider', 'Hình 2.1'],
        ['Hướng đối tượng', 'Lớp TypeScript', 'Lớp Dart', 'Hình 4.1'],
        ['Theo tầng', 'Controller → Service → Data Access', 'Screen → BLoC → Repository → Network', 'Hình 6.2, 1.1'],
      ],
      [2600, 5000, 5000, 2400],
    ),

    heading2('6.7. Đánh giá', { newPage: true }),
    heading3('Ưu điểm'),
    bullet('Backend và Frontend tách biệt qua hợp đồng REST / SSE nên phát triển, kiểm thử và triển khai song song được.'),
    bullet('Bus sự kiện ở Backend kết hợp SseClient tự kết nối lại ở Frontend giúp ma trận phòng đồng bộ giữa nhiều máy lễ tân mà không cần polling.'),
    bullet('Khóa phân tán Redis và giao dịch Prisma ở Backend bảo vệ toàn vẹn dữ liệu đặt phòng và thu tiền; Frontend chỉ hiển thị trạng thái nên không thể làm sai quy tắc.'),
    bullet('Cả hai phía đều module hóa theo nghiệp vụ và dùng DI, nên thêm chức năng mới ít ảnh hưởng phần còn lại.'),
    heading3('Hạn chế và hướng phát triển'),
    bullet('Backend: bus sự kiện RxJS chạy trong một tiến trình; khi chạy nhiều instance, đồng bộ giữa các instance dựa vào db-watcher quét định kỳ nên có độ trễ. Có thể thay bằng Redis Pub/Sub hoặc message broker chuyên dụng.'),
    bullet('Backend: là một khối triển khai duy nhất; khi tải tăng có thể tách bookings, invoices thành dịch vụ riêng.'),
    bullet('Backend và Frontend: mô hình miền còn "mỏng" (anemic) – quy tắc nằm ở Service, Model chỉ chứa dữ liệu.'),
    bullet('Frontend: quản lý trạng thái chưa đồng nhất (một phần dùng BLoC, một phần dùng StatefulWidget); có thể đưa dần các màn hình customer, receptionist sang BLoC.'),

    heading2('KẾT LUẬN'),
    para('Dự án Luxe Grand Hotel kết hợp đủ chín kiểu kiến trúc thuộc bốn nhóm trong đề cương ở cả hai phần mã nguồn. Về triển khai, Frontend Flutter (client, tầng trình bày) và Backend NestJS (server, tầng ứng dụng) tạo thành mô hình Client/Server nhiều tầng. Về cấu trúc, cả hai phía đều phân lớp, chia thành phần với DI và viết hướng đối tượng. Về miền, hai phía dùng chung ngôn ngữ nghiệp vụ khách sạn và tổ chức mã theo ngữ cảnh nghiệp vụ. Về giao tiếp, Backend cung cấp dịch vụ REST và phát sự kiện qua bus thông điệp, Frontend tiêu thụ dịch vụ và nhận sự kiện thời gian thực qua SSE và FCM.'),
  ];
};
