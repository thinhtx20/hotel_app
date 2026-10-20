const fs = require('fs');
const path = require('path');
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  AlignmentType,
  Table,
  TableRow,
  TableCell,
  WidthType,
  BorderStyle,
  ImageRun,
  PageOrientation,
  Header,
  Footer,
  PageNumber,
  PageBreak,
} = require('./docx/node_modules/docx');
const buildArchitectureStylesChapter = require('./architecture_styles_chapter');

console.log('--- Generating Luxe Grand Hotel Architecture Word Document ---');

// Ảnh do tool/uml/build.js sinh ra (nguồn .drawio nằm cùng thư mục)
const diagramsDir = path.resolve(__dirname, '../docs/uml_diagrams');
const outputFile = path.resolve(__dirname, '../So_Do_Kien_Truc_Luxe_Grand_Hotel.docx');

// Colors
const COLOR_PRIMARY = '1B365D'; // Deep Navy
const COLOR_GOLD = 'D4AF37';    // Imperial Gold
const COLOR_DARK = '0F172A';    // Slate Dark
const COLOR_LIGHT_BG = 'F8FAFC';// Soft Slate
const COLOR_BORDER = 'CBD5E1';  // Light Border
const COLOR_HEADER_BG = '1E293B';

// Table Border Style
const tableBorders = {
  top: { style: BorderStyle.SINGLE, size: 4, color: COLOR_BORDER },
  bottom: { style: BorderStyle.SINGLE, size: 4, color: COLOR_BORDER },
  left: { style: BorderStyle.SINGLE, size: 4, color: COLOR_BORDER },
  right: { style: BorderStyle.SINGLE, size: 4, color: COLOR_BORDER },
  insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
  insideVertical: { style: BorderStyle.SINGLE, size: 2, color: 'E2E8F0' },
};

function createStyledTable(headers, rows, colWidths) {
  const tableRows = [];

  // Header Row
  const headerCells = headers.map((h, i) => new TableCell({
    width: { size: colWidths[i], type: WidthType.DXA },
    shading: { fill: COLOR_PRIMARY },
    margins: { top: 120, bottom: 120, left: 140, right: 140 },
    children: [
      new Paragraph({
        alignment: AlignmentType.CENTER,
        children: [
          new TextRun({ text: h, bold: true, color: 'FFFFFF', font: 'Times New Roman', size: 21 }),
        ],
      }),
    ],
  }));
  tableRows.push(new TableRow({ children: headerCells, tableHeader: true, cantSplit: true }));

  // Data Rows
  rows.forEach((row, rowIndex) => {
    const isAlt = rowIndex % 2 === 1;
    const cells = row.map((cellText, colIndex) => {
      // If cellText is array, handle multi-paragraph
      const lines = Array.isArray(cellText) ? cellText : [cellText];
      const paragraphs = lines.map(line => new Paragraph({
        spacing: { before: 40, after: 40 },
        children: [
          new TextRun({
            text: line,
            font: 'Times New Roman',
            size: 20, // 10pt
            color: '1E293B',
          }),
        ],
      }));

      return new TableCell({
        width: { size: colWidths[colIndex], type: WidthType.DXA },
        shading: { fill: isAlt ? COLOR_LIGHT_BG : 'FFFFFF' },
        margins: { top: 100, bottom: 100, left: 140, right: 140 },
        children: paragraphs,
      });
    });
    tableRows.push(new TableRow({ children: cells, cantSplit: true }));
  });

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: tableBorders,
    rows: tableRows,
  });
}

function createHeading1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 240, after: 120 },
    children: [
      new TextRun({
        text,
        bold: true,
        font: 'Times New Roman',
        size: 30, // 15pt
        color: COLOR_PRIMARY,
      }),
    ],
  });
}

function createHeading2(text, { newPage = false } = {}) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    pageBreakBefore: newPage,
    spacing: { before: 240, after: 120 },
    children: [
      new TextRun({
        text,
        bold: true,
        font: 'Times New Roman',
        size: 24, // 12pt
        color: '047857',
      }),
    ],
  });
}

function createHeading3(text, { newPage = false } = {}) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    pageBreakBefore: newPage,
    spacing: { before: 200, after: 100 },
    children: [
      new TextRun({ text, bold: true, italics: true, font: 'Times New Roman', size: 23, color: COLOR_PRIMARY }),
    ],
  });
}

function createBullet(text) {
  return new Paragraph({
    spacing: { before: 40, after: 60 },
    indent: { left: 400, hanging: 260 },
    children: [
      new TextRun({ text: '•\t', font: 'Times New Roman', size: 22, color: COLOR_PRIMARY }),
      new TextRun({ text, font: 'Times New Roman', size: 22, color: '1E293B' }),
    ],
  });
}

function createCaption(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 120 },
    children: [new TextRun({ text, italics: true, bold: true, size: 21, color: '475569' })],
  });
}

function createParagraph(text, isBold = false) {
  return new Paragraph({
    spacing: { before: 60, after: 80 },
    children: [
      new TextRun({
        text,
        bold: isBold,
        font: 'Times New Roman',
        size: 22, // 11pt
        color: '1E293B',
      }),
    ],
  });
}

function createCallout(title, text) {
  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      left: { style: BorderStyle.SINGLE, size: 24, color: COLOR_PRIMARY },
      top: { style: BorderStyle.NONE },
      right: { style: BorderStyle.NONE },
      bottom: { style: BorderStyle.NONE },
    },
    rows: [
      new TableRow({
        cantSplit: true,
        children: [
          new TableCell({
            shading: { fill: 'F0F7FF' },
            margins: { top: 120, bottom: 120, left: 180, right: 180 },
            children: [
              new Paragraph({
                children: [
                  new TextRun({ text: title + ': ', bold: true, color: COLOR_PRIMARY, font: 'Times New Roman', size: 22 }),
                  new TextRun({ text, font: 'Times New Roman', size: 22, color: '334155' }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}

// Co ảnh vừa khung maxWidth x maxHeight, giữ nguyên tỉ lệ gốc của PNG.
function createImageParagraph(imageName, maxWidth = 760, maxHeight = 490) {
  const imagePath = path.join(diagramsDir, `${imageName}.png`);
  if (!fs.existsSync(imagePath)) {
    console.error(`Image not found: ${imagePath}`);
    return new Paragraph({ children: [new TextRun(`[Hình ảnh ${imageName}.png chưa được tạo]`)] });
  }

  const imgData = fs.readFileSync(imagePath);
  const scale = Math.min(maxWidth / imgData.readUInt32BE(16), maxHeight / imgData.readUInt32BE(20));
  const widthPt = Math.round(imgData.readUInt32BE(16) * scale);
  const heightPt = Math.round(imgData.readUInt32BE(20) * scale);
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 80, after: 60 },
    children: [
      new ImageRun({
        data: imgData,
        transformation: {
          width: widthPt,
          height: heightPt,
        },
        type: 'png',
      }),
    ],
  });
}

// Build the document
const doc = new Document({
  styles: {
    default: {
      document: {
        run: {
          font: 'Times New Roman',
          size: 22,
          color: '1E293B',
        },
      },
    },
  },
  sections: [
    // -------------------------------------------------------------
    // SECTION 1: COVER PAGE & OVERVIEW (Landscape)
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              alignment: AlignmentType.RIGHT,
              children: [
                new TextRun({ text: 'Luxe Grand Hotel Management System - Hồ Sơ Thiết Kế Kiến Trúc Phần Mềm', italics: true, size: 18, color: '64748B' }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: 'Trang ' }),
                new TextRun({ children: [PageNumber.CURRENT] }),
                new TextRun({ text: ' / ' }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES] }),
              ],
            }),
          ],
        }),
      },
      children: [
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 160, after: 60 },
          children: [
            new TextRun({ text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO - TRƯỜNG ĐẠI HỌC CÔNG NGHỆ', bold: true, size: 24, color: '475569' }),
          ],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 200 },
          children: [
            new TextRun({ text: 'KHOA CÔNG NGHỆ THÔNG TIN & KỸ THUẬT PHẦN MỀM', bold: true, size: 22, color: '64748B' }),
          ],
        }),

        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 120, after: 100 },
          children: [
            new TextRun({ text: 'BÁO CÁO THIẾT KẾ ĐẶC TẢ KIẾN TRÚC HỆ THỐNG', bold: true, size: 34, color: COLOR_PRIMARY }),
          ],
        }),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 200 },
          children: [
            new TextRun({ text: 'ĐỀ TÀI: NGHIÊN CỨU VÀ XÂY DỰNG HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN\n"LUXE GRAND HOTEL" TRÊN NỀN TẢNG NESTJS VÀ FLUTTER', bold: true, size: 26, color: '047857' }),
          ],
        }),

        createCallout(
          'Mục tiêu tài liệu',
          'Tài liệu này chuẩn hóa và trực quan hóa toàn bộ kiến trúc hệ thống thông qua bộ 5 biểu đồ UML 2.5: (1) Package Diagram, (2) Component Diagram, (3) Deployment Diagram, (4) Class Diagram và (5) Sequence Diagram; Chương 6 đối chiếu các kiểu kiến trúc (giao tiếp, triển khai, miền, cấu trúc) được áp dụng trong hệ thống. Mọi chi tiết trong tài liệu đều bám sát mã nguồn thực tế của Backend NestJS và Frontend Flutter. Các biểu đồ được vẽ theo ký hiệu chuẩn UML 2.5 bằng draw.io (diagrams.net); tệp nguồn .drawio có thể mở và chỉnh sửa tại thư mục docs/uml_diagrams/.'
        ),

        new Paragraph({ spacing: { before: 200, after: 120 } }),

        // Summary table of 5 diagrams
        createStyledTable(
          ['STT', 'Tên Biểu Đồ (UML Diagram)', 'Phân Loại Kiến Trúc', 'Phạm Vi Minh Họa', 'Công Nghệ Nền Tảng'],
          [
            ['1', 'Package Diagram (Biểu đồ gói)', 'Cấu trúc & Miền (DDD)', 'Phân rã các Module BE và Feature FE, quan hệ phụ thuộc', 'NestJS Modules, Flutter Feature-First'],
            ['2', 'Component Diagram (Biểu đồ thành phần)', 'Cấu trúc (Component-based)', 'Các thành phần phần mềm, Interface/Port và cổng kết nối', 'BLoC, Dio, SSE, Prisma ORM, Redis'],
            ['3', 'Deployment Diagram (Biểu đồ triển khai)', 'Triển khai (Client/Server, N-tier)', 'Hạ tầng máy chủ Cloud, Container Docker, Nút thiết bị di động', 'Docker Compose, Render, PostgreSQL, FCM'],
            ['4', 'Class Diagram (Biểu đồ lớp thực thể)', 'Cấu trúc (Hướng đối tượng - OOP)', 'Mô hình 9 lớp nghiệp vụ, 9 kiểu liệt kê, thuộc tính, thao tác và quan hệ', 'Prisma Schema (PostgreSQL), TypeScript'],
            ['5', 'Sequence Diagram (Biểu đồ tuần tự)', 'Giao tiếp (Message Bus / Event-Driven)', 'Quy trình Đặt phòng trực tuyến, Phê duyệt, Check-in & Đồng bộ SSE', 'RxJS Subject, SSE Stream, FCM Push'],
          ],
          [800, 3600, 2600, 4800, 3200]
        ),
      ],
    },

    // -------------------------------------------------------------
    // SECTION 2: PACKAGE DIAGRAM
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading1('CHƯƠNG 1: BIỂU ĐỒ GÓI (UML PACKAGE DIAGRAM)'),
        createParagraph('Biểu đồ gói mô hình hóa cấu trúc phân cấp và tổ chức thư mục mã nguồn của hai hệ thống con trong dự án Luxe Grand Hotel: ứng dụng di động Frontend (hotel_app::lib – Flutter) và máy chủ API Backend (Hotel-Management::src – NestJS Modular Monolith). Gói chứa gói con được ghi tên trên tab; quan hệ phụ thuộc giữa các gói được biểu diễn bằng mũi tên nét đứt kèm từ khóa «import» (nhập nội dung gói) hoặc «use» (sử dụng qua giao thức REST / SSE).'),

        createImageParagraph('package_diagram', 770, 490),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [
            new TextRun({ text: 'Hình 1.1: Sơ đồ gói tổng thể hệ thống quản lý khách sạn Luxe Grand Hotel', italics: true, bold: true, size: 21, color: '475569' }),
          ],
        }),

        // Explicit page break before specification tables to guarantee 0 spillage
        new Paragraph({ children: [new PageBreak()] }),

        createHeading2('1.1. Chi tiết các Gói phía Frontend (hotel_app/lib)'),
        createStyledTable(
          ['Tên Gói (Package)', 'Đường Dẫn Thư Mục', 'Các File / Thành Phần Cốt Lõi', 'Trách Nhiệm Kiến Trúc'],
          [
            ['lib::core', 'lib/core/', 'constants/, errors/, network/ (dio_client, sse_client), router/, services/ (push_notification_service), session/, storage/ (token_storage), theme/, utils/', 'Cung cấp hạ tầng lõi: HTTP Client, SSE listener, lưu token, định tuyến GoRouter, nhận push FCM.'],
            ['lib::features', 'lib/features/', 'auth/, customer/, receptionist/, cashier/, admin/, notifications/, profile/, splash/', 'Tổ chức theo chuẩn Feature-First: mỗi phân hệ chứa Screens, BLoC và Widgets nghiệp vụ. «import» shared và core.'],
            ['lib::shared', 'lib/shared/', 'models/ (Booking, Room, Invoice, …), repositories/, widgets/', 'Tái sử dụng chung giữa các tính năng: Model miền, Repository truy cập dữ liệu, UI components. «import» core.'],
            ['lib::di', 'lib/di/', 'injection_container.dart (GetIt Service Locator)', 'Bộ tiêm phụ thuộc toàn cục: «import» features, shared, core để đăng ký BLoC, Repository, DioClient.'],
          ],
          [2000, 2600, 5200, 5200]
        ),

        new Paragraph({ spacing: { before: 160 } }),

        createHeading2('1.2. Chi tiết các Gói phía Backend (Hotel-Management/src)'),
        createStyledTable(
          ['Tên Gói (Package)', 'Đường Dẫn Thư Mục', 'Các File / Thành Phần Cốt Lõi', 'Trách Nhiệm Kiến Trúc'],
          [
            ['common', 'src/common/', 'decorators/ (roles, current-user, public), dto/, filters/, guards/ (jwt-auth, roles), interceptors/ (transform), utils/', 'Các bộ chặn bảo mật, phân quyền RBAC, lọc ngoại lệ, chuẩn hóa phản hồi và tiện ích dùng chung.'],
            ['Feature Modules', 'src/ (auth, users, room-types, rooms, bookings, shifts, services, analytics, invoices)', 'Controller, Service, DTO cho từng miền nghiệp vụ; bookings «import» rooms và invoices', 'Kiến trúc Modular Monolith: đóng gói logic nghiệp vụ theo từng Bounded Context. «import» common và Infrastructure Modules.'],
            ['Infrastructure Modules', 'src/ (prisma, redis, elasticsearch, notifications, mail, upload)', 'PrismaService, RedisService, ElasticsearchService, NotificationsService (Firebase Admin SDK, Cron), MailService, UploadService', 'Tầng hạ tầng kết nối PostgreSQL, Redis cache / lock, Elasticsearch, FCM Push, SMTP và Cloudinary.'],
          ],
          [2000, 2600, 5200, 5200]
        ),
      ],
    },

    // -------------------------------------------------------------
    // SECTION 3: COMPONENT DIAGRAM
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading1('CHƯƠNG 2: BIỂU ĐỒ THÀNH PHẦN (UML COMPONENT DIAGRAM)'),
        createParagraph('Biểu đồ thành phần thể hiện các khối chức năng phần mềm («component») bên trong hai hệ thống con («subsystem») và các hệ thống bên ngoài. Giao tiếp giữa các hệ thống đi qua port (ô vuông trên biên) và assembly connector dạng ball-and-socket: phía cung cấp giao diện vẽ hình tròn, phía yêu cầu vẽ nửa vòng cung. Delegation connector nối port với thành phần thực thi bên trong; quan hệ phụ thuộc nội bộ dùng mũi tên nét đứt «use».'),

        createImageParagraph('component_diagram', 760, 500),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [
            new TextRun({ text: 'Hình 2.1: Sơ đồ thành phần phần mềm hệ thống Luxe Grand Hotel', italics: true, bold: true, size: 21, color: '475569' }),
          ],
        }),

        // Explicit page break before specification tables
        new Paragraph({ children: [new PageBreak()] }),

        createHeading2('2.1. Bảng Đặc tả Các Thành phần Phía Client (Flutter Mobile)'),
        createStyledTable(
          ['Thành Phần (Component)', 'Giao Diện Cung Cấp (Provides)', 'Giao Diện Yêu Cầu (Requires)', 'Mô Tả Chức Năng'],
          [
            ['Presentation', '—', '«use» State Management, Repositories', 'features/*/screens và shared/widgets: RoomMatrixScreen, CreateBookingModal, CashierInvoicesScreen, …'],
            ['State Management (BLoC)', 'Luồng State cho Presentation', '«use» Repositories', 'AuthBloc, InvoiceBloc, UserBloc, TodayCheckOutsBloc, ThemeCubit: nhận Event từ UI, phát State mới.'],
            ['Repositories', 'API nghiệp vụ dạng Future<Model>', '«use» Network', 'BookingRepository, RoomRepository, InvoiceRepository, ShiftRepository, …: chuyển JSON thành Model.'],
            ['Network', '—', 'IRestApi, IRoomEventStream (qua port của subsystem); «use» TokenStorage', 'DioClient tự gắn Bearer JWT qua interceptor; SseClient lắng nghe sự kiện phòng và tự kết nối lại.'],
            ['TokenStorage', 'Đọc / ghi token', '—', 'Lưu access token và refresh token trên thiết bị.'],
            ['PushNotificationService', '—', 'IPushMessaging (Firebase Cloud Messaging)', 'Nhận thông báo đẩy FCM và hiển thị cho người dùng.'],
          ],
          [2800, 3600, 3600, 5000]
        ),

        new Paragraph({ spacing: { before: 160 } }),

        createHeading2('2.2. Bảng Đặc tả Các Thành phần Phía Server (NestJS Application)'),
        createStyledTable(
          ['Thành Phần (Component)', 'Giao Diện Cung Cấp (Provides)', 'Giao Diện Yêu Cầu (Requires)', 'Mô Tả Chức Năng'],
          [
            ['Security & Pipeline', '—', '—', 'JwtAuthGuard, RolesGuard, ValidationPipe, HttpExceptionFilter, TransformInterceptor: xác thực JWT, phân quyền RBAC, kiểm tra DTO.'],
            ['REST Controllers', 'IRestApi (/api/v1/...), IRoomEventStream (@Sse /rooms/stream) qua port', '«use» Security & Pipeline, Domain Services, Realtime Event Bus', 'Bookings, Rooms, Invoices, Shifts, Auth, Users, Analytics, Services, Upload: nhận request, gọi Service.'],
            ['Domain Services', '—', '«use» Realtime Event Bus và 6 thành phần hạ tầng', 'Xử lý nghiệp vụ: chống đặt trùng phòng, sổ thu tiền đa đợt, bàn giao ca trực, thống kê doanh thu.'],
            ['Realtime Event Bus', 'Luồng RoomEvent / UserEvent', '—', 'RoomEventsService, UserEventsService (RxJS Subject) phát sự kiện cho luồng SSE.'],
            ['Scheduler', '—', '«use» NotificationsService', "CheckinReminderService chạy @Cron('0 1 * * *') nhắc khách check-in."],
            ['PrismaService / RedisService / ElasticsearchService', 'Dịch vụ hạ tầng cho Domain Services', 'SQL / TCP 5432; RESP / TCP 6379; REST / HTTP 9200', 'Truy vấn PostgreSQL qua $transaction; cache và distributed lock; chỉ mục tìm kiếm phòng.'],
            ['NotificationsService / MailService / UploadService', 'Dịch vụ hạ tầng cho Domain Services', 'FCM HTTP v1; SMTP / TLS 587; Upload API / HTTPS', 'Gửi push qua Firebase Admin SDK; gửi email OTP / xác nhận; lưu ảnh lên Cloudinary.'],
          ],
          [2800, 3600, 3600, 5000]
        ),
      ],
    },

    // -------------------------------------------------------------
    // SECTION 4: DEPLOYMENT DIAGRAM
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading1('CHƯƠNG 3: BIỂU ĐỒ TRIỂN KHAI (UML DEPLOYMENT DIAGRAM)'),
        createParagraph('Biểu đồ triển khai thể hiện kiến trúc vật lý của hệ thống: các node phần cứng («device», vẽ dạng khối hộp 3D), môi trường thực thi lồng bên trong («executionEnvironment»), các «artifact» được triển khai và communication path (đường liền) ghi giao thức dạng «HTTPS», «TCP/IP», kèm bội số * – 1 giữa thiết bị di động và máy chủ ứng dụng.'),

        createImageParagraph('deployment_diagram', 760, 500),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [
            new TextRun({ text: 'Hình 3.1: Sơ đồ triển khai hạ tầng đám mây và thiết bị di động Luxe Grand Hotel', italics: true, bold: true, size: 21, color: '475569' }),
          ],
        }),

        // Explicit page break before specification tables
        new Paragraph({ children: [new PageBreak()] }),

        createHeading2('3.1. Bảng Đặc tả Các Nút Phần Cứng và Môi Trường Thực Thi'),
        createStyledTable(
          ['Nút (Node / Device)', 'Môi Trường Thực Thi', 'Artifacts Đóng Gói', 'Cấu Hình & Giao Thức Mạng'],
          [
            ['«device» Điện thoại di động (Android 10+ / iOS 15+)', 'Flutter Engine (Dart AOT)', 'hotel_app.apk / hotel_app.ipa', '«HTTPS» REST /api/v1 :443 và «HTTPS / SSE» GET /rooms/stream tới Application Server (bội số * – 1); nhận push từ FCM.'],
            ['«device» Application Server (Render Web Service, Singapore)', 'Docker Container (node:20-alpine, port 3000) → Node.js 20 Runtime', 'dist/main.js (NestJS), @prisma/client, .env', 'Kết nối Database Server qua «TCP/IP» :5432, :6379 và «HTTP» :9200; gọi FCM, SMTP, Cloudinary qua HTTPS / SMTP-TLS.'],
            ['«device» Database Server (Render PostgreSQL / Docker Compose)', 'PostgreSQL 16 (postgres:16-alpine)', 'hotel_db (users, rooms, bookings, …)', 'Port 5432 / TCP; lưu trữ dữ liệu nghiệp vụ, giao dịch ACID qua prisma.$transaction.'],
            ['', 'Redis 7 (redis:7-alpine)', '—', 'Port 6379 / TCP; cache danh mục phòng và distributed lock khi đặt phòng.'],
            ['', 'Elasticsearch 8.11 (elasticsearch:8.11.0)', '—', 'Port 9200 / HTTP; chỉ mục và tìm kiếm phòng.'],
            ['«device» Firebase Cloud Messaging, SMTP Server, Cloudinary', 'Dịch vụ đám mây bên ngoài', '—', 'FCM HTTP v1 (push notification), SMTP / TLS :587 (email OTP, xác nhận), HTTPS Upload API (ảnh phòng).'],
          ],
          [2800, 3600, 3800, 4800]
        ),
      ],
    },

    // -------------------------------------------------------------
    // SECTION 5: CLASS DIAGRAM
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading1('CHƯƠNG 4: BIỂU ĐỒ LỚP THỰC THỂ CỐT LÕI (UML CLASS DIAGRAM)'),
        createParagraph('Biểu đồ lớp mô hình hóa cấu trúc tĩnh của các thực thể nghiệp vụ, bám theo lược đồ prisma/schema.prisma. Mỗi lớp gồm 3 ngăn: tên, thuộc tính (ký hiệu - private, kiểu dữ liệu, bội số [0..1] / [*], giá trị mặc định, ràng buộc {id} / {unique}) và thao tác (+ public, ánh xạ từ các phương thức nghiệp vụ của tầng Service). Khóa ngoại không được liệt kê thành thuộc tính mà biểu diễn bằng quan hệ kết hợp có tên vai trò và bội số; quan hệ hợp thành (hình thoi đặc) ứng với ràng buộc xóa dây chuyền onDelete: Cascade.'),

        createImageParagraph('class_diagram', 740, 510),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [
            new TextRun({ text: 'Hình 4.1: Sơ đồ lớp thực thể nghiệp vụ cốt lõi (Core Domain Entities)', italics: true, bold: true, size: 21, color: '475569' }),
          ],
        }),

        // Explicit page break before specification tables
        new Paragraph({ children: [new PageBreak()] }),

        createHeading2('4.1. Bảng Đặc tả Các Lớp Thực thể và Phương thức Nghiệp vụ'),
        createStyledTable(
          ['Tên Lớp (Entity)', 'Thuộc Tính Chính (Attributes)', 'Phương Thức Chính (Methods)', 'Mối Quan Hệ (Multiplicity)'],
          [
            ['User', 'id {id}, email {unique}, password, fullName, role: Role, isActive, activeSessionId, fcmToken', 'login(), logout()', 'customer 1 — 0..* Booking; confirmedBy / cancelledBy 0..1 — 0..* Booking; staff 1 — 0..* WorkShift; handoverStaff 0..1 — 0..* WorkShift; 0..1 — 0..* Invoice, Payment, ExtraServiceOrder.'],
            ['RoomType', 'id {id}, name {unique}, code {unique}, basePrice: Real, capacityAdults, capacityChildren, sizeSqM, amenities [*], images [*]', '—', 'roomType 1 — 0..* Room (phân loại).'],
            ['Room', 'id {id}, roomNumber {unique}, floor, status: RoomStatus, notes', 'updateStatus()', 'room 1 — 0..* Booking (được đặt).'],
            ['Booking', 'id {id}, bookingCode {unique}, checkInDate, checkOutDate, actualCheckIn, actualCheckOut, guestCount, totalAmount, depositAmount, status: BookingStatus', 'approve(), reject(), checkIn(), checkOut(), cancel(), changeRoom(), addServiceOrder()', 'Hợp thành: 1 Booking ◆ 0..1 Invoice; 1 Booking ◆ 0..* ExtraServiceOrder.'],
            ['Invoice', 'id {id}, invoiceCode {unique}, roomAmount, servicesAmount, discount, tax, finalAmount, paidAmount, paymentMethod, paymentStatus', 'recalculateTotals()', 'Hợp thành: 1 Invoice ◆ 0..* Payment.'],
            ['Payment', 'id {id}, amount, method: PaymentMethod, type: PaymentEntryType, status: PaymentEntryStatus, reference, confirmedAt, rejectedReason', 'confirm(), reject()', '0..* Payment được ghi nhận trong 0..1 WorkShift.'],
            ['ExtraServiceOrder', 'id {id}, serviceName, unitPrice, quantity, totalPrice, status, note, createdAt', 'updateStatus()', 'Phụ thuộc «use» HotelService: sao chép tên và đơn giá tại thời điểm gọi, không có khóa ngoại.'],
            ['HotelService', 'id {id}, code {unique}, name, category, unitPrice, unit, isAvailable', '—', 'Danh mục dịch vụ độc lập.'],
            ['WorkShift', 'id {id}, shiftCode {unique}, shiftType: ShiftType, status: ShiftStatus, startTime, endTime, initialCash, expectedCash, actualCash, cashDifference', 'open(), close(), handover()', 'shift 0..1 — 0..* Payment.'],
          ],
          [2000, 4400, 4400, 4200]
        ),
      ],
    },

    // -------------------------------------------------------------
    // SECTION 6: SEQUENCE DIAGRAM (trang dọc để hình đủ lớn) & SUMMARY
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading1('CHƯƠNG 5: BIỂU ĐỒ TUẦN TỰ (UML SEQUENCE DIAGRAM)'),
        createParagraph('Biểu đồ tuần tự mô tả kịch bản trọng tâm: khách đặt phòng → lễ tân phê duyệt → đồng bộ trạng thái phòng qua SSE → check-in. Thông điệp đồng bộ dùng mũi tên đầu đặc, thông điệp bất đồng bộ dùng mũi tên đầu mở, thông điệp trả về dùng nét đứt; thanh kích hoạt (activation) thể hiện thời gian xử lý. Rẽ nhánh dùng combined fragment alt, xử lý song song dùng par.'),

        createImageParagraph('sequence_diagram', 700, 760),
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { after: 120 },
          children: [
            new TextRun({ text: 'Hình 5.1: Sơ đồ tuần tự quy trình đặt phòng, phê duyệt, check-in và đồng bộ thời gian thực', italics: true, bold: true, size: 21, color: '475569' }),
          ],
        }),

      ],
    },
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: [
        createHeading2('5.1. Bảng Phân tích 3 Giai đoạn Nghiệp vụ Chi tiết'),
        createStyledTable(
          ['Giai Đoạn', 'Các Bước Thực Hiện (số thứ tự thông điệp)', 'Lifeline Tham Gia', 'Cơ Chế Kỹ Thuật Đảm Bảo Toàn Vẹn'],
          [
            [
              'Giai đoạn 1: Khách hàng đặt phòng trực tuyến (1–21)',
              [
                '1–4. Khách chọn phòng và ngày; CreateBookingModal gọi BookingRepository.create(), DioClient gửi POST /api/v1/bookings kèm JWT.',
                '5–7. BookingsService.create() chiếm khóa Redis "lock:booking:room:{roomId}" (6 giây).',
                '8–16. alt [có khóa và không trùng lịch]: kiểm tra đơn giao nhau, tạo Booking PENDING, syncRoomStatus(), nhả khóa, trả 201 Created.',
                '17–18. [else]: ném ConflictException, trả 409 Conflict.',
                '19–21. Kết quả trả ngược về giao diện của khách.',
              ],
              'Khách hàng, :CreateBookingModal, :BookingRepository, :DioClient, :BookingsController, :BookingsService, :RedisService, :PrismaService',
              'Redis distributed lock chặn hai yêu cầu đồng thời trên cùng phòng; truy vấn khoảng ngày giao nhau loại trừ đặt trùng lịch.'
            ],
            [
              'Giai đoạn 2: Lễ tân phê duyệt và đồng bộ realtime (22–40)',
              [
                '22–26. Lễ tân nhập tiền cọc, BookingApprovalScreen gọi approveBooking(); PATCH /api/v1/bookings/{id}/approve qua JwtAuthGuard + RolesGuard.',
                '27–28. $transaction: Booking → CONFIRMED, upsert Invoice, ghi Payment loại DEPOSIT.',
                '29–32. syncRoomStatus(): Room → RESERVED, RoomEventsService.emitStatusChanged().',
                '33–40. par: (a) sự kiện SSE room.status_changed tới SseClient, RoomMatrixScreen tô lại ô phòng; (b) song song trả 200 OK về màn hình duyệt.',
              ],
              'Lễ tân, :BookingApprovalScreen, :BookingRepository, :DioClient, :BookingsController, :BookingsService, :PrismaService, :RoomEventsService, :SseClient, :RoomMatrixScreen',
              'Giao dịch Prisma bảo đảm đơn, hóa đơn và tiền cọc cập nhật cùng lúc; RxJS Subject + SSE đẩy trạng thái phòng tới mọi máy lễ tân mà không cần polling.'
            ],
            [
              'Giai đoạn 3: Check-in tại quầy (41–59)',
              [
                '41–46. Khách xuất trình CCCD; lễ tân nhấn Check-in trên RoomMatrixScreen, gọi POST /api/v1/bookings/{id}/check-in.',
                '47–53. alt [status = CONFIRMED]: $transaction Booking → CHECKED_IN, actualCheckIn = now(), Room → OCCUPIED; phát sự kiện SSE; trả 200 OK.',
                '54–55. [else: PENDING / CANCELLED / đã CHECKED_IN]: ném BadRequestException, trả 400 Bad Request.',
                '56–59. Ô phòng hiển thị OCCUPIED; lễ tân bàn giao thẻ phòng cho khách.',
              ],
              'Khách hàng, Lễ tân, :RoomMatrixScreen, :BookingRepository, :DioClient, :BookingsController, :BookingsService, :PrismaService, :RoomEventsService, :SseClient',
              'Chỉ đơn đã CONFIRMED mới được check-in; thời điểm actualCheckIn được ghi nhận làm căn cứ tính phụ phí khi trả phòng.'
            ],
          ],
          [2600, 5200, 3600, 3600]
        ),

      ],
    },

    // -------------------------------------------------------------
    // SECTION 7: CÁC KIỂU KIẾN TRÚC (tool/architecture_styles_chapter.js)
    // -------------------------------------------------------------
    {
      properties: {
        page: {
          size: { orientation: PageOrientation.LANDSCAPE },
          margin: { top: 800, bottom: 800, left: 800, right: 800 },
        },
      },
      children: buildArchitectureStylesChapter({
        heading1: createHeading1,
        heading2: createHeading2,
        heading3: createHeading3,
        para: createParagraph,
        bullet: createBullet,
        table: createStyledTable,
        callout: createCallout,
        image: createImageParagraph,
        caption: createCaption,
        Paragraph,
      }),
    },
  ],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(outputFile, buffer);
  console.log(`✓ Word document created successfully: ${outputFile} (${buffer.length} bytes)`);
});
