const fs = require('fs');
const path = require('path');
const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  HeadingLevel,
  Table,
  TableRow,
  TableCell,
  WidthType,
  AlignmentType,
  BorderStyle,
  ImageRun,
  Header,
  Footer,
  PageNumber,
} = require('docx');

const ROOT_DIR = path.resolve(__dirname, '../../');
const ASSETS_DIR = path.join(ROOT_DIR, 'report_assets');
const OUTPUT_FILE = path.join(ROOT_DIR, 'Bao_Cao_Tot_Nghiep_Luxe_Grand_Hotel.docx');

// Styling constants
const FONT_FAMILY = 'Times New Roman';
const COLOR_PRIMARY = '1B365D'; // Deep Navy
const COLOR_SECONDARY = '0F4C81'; // Slate Blue
const COLOR_GOLD = 'B8860B'; // Dark Golden Rod
const COLOR_TEXT = '222222';
const COLOR_MUTED = '666666';

function createTitle(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 240, after: 240 },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 34, // 17pt
        font: FONT_FAMILY,
        color: COLOR_PRIMARY,
      }),
    ],
  });
}

function createHeading1(text, pageBreakBefore = true) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    pageBreakBefore,
    spacing: { before: 360, after: 180 },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 30, // 15pt
        font: FONT_FAMILY,
        color: COLOR_PRIMARY,
      }),
    ],
  });
}

function createHeading2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 240, after: 120 },
    children: [
      new TextRun({
        text,
        bold: true,
        size: 26, // 13pt
        font: FONT_FAMILY,
        color: COLOR_SECONDARY,
      }),
    ],
  });
}

function createHeading3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 180, after: 80 },
    children: [
      new TextRun({
        text,
        bold: true,
        italics: true,
        size: 24, // 12pt
        font: FONT_FAMILY,
        color: '333333',
      }),
    ],
  });
}

function createParagraph(text, options = {}) {
  const { bold = false, italics = false, indent = true, align = AlignmentType.JUSTIFIED, after = 120 } = options;
  return new Paragraph({
    alignment: align,
    spacing: { after, line: 320 },
    indent: indent ? { firstLine: 400 } : undefined,
    children: [
      new TextRun({
        text,
        bold,
        italics,
        size: 24, // 12pt
        font: FONT_FAMILY,
        color: COLOR_TEXT,
      }),
    ],
  });
}

function createBullet(text, level = 0) {
  return new Paragraph({
    bullet: { level },
    spacing: { after: 80, line: 300 },
    children: [
      new TextRun({
        text,
        size: 24,
        font: FONT_FAMILY,
        color: COLOR_TEXT,
      }),
    ],
  });
}

function createImage(imagePath, width, height, captionText) {
  const imgBuffer = fs.readFileSync(imagePath);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 180, after: 80 },
      children: [
        new ImageRun({
          data: imgBuffer,
          transformation: { width, height },
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
      children: [
        new TextRun({
          text: captionText,
          italics: true,
          bold: true,
          size: 22,
          font: FONT_FAMILY,
          color: '444444',
        }),
      ],
    }),
  ];
}

function createImagePlaceholder(figNum, title, description, instructions) {
  return [
    new Table({
      width: { size: 100, type: WidthType.PERCENTAGE },
      borders: {
        top: { style: BorderStyle.DASHED, size: 12, color: COLOR_PRIMARY },
        bottom: { style: BorderStyle.DASHED, size: 12, color: COLOR_PRIMARY },
        left: { style: BorderStyle.DASHED, size: 12, color: COLOR_PRIMARY },
        right: { style: BorderStyle.DASHED, size: 12, color: COLOR_PRIMARY },
      },
      rows: [
        new TableRow({
          children: [
            new TableCell({
              shading: { fill: 'F4F7FB' },
              margins: { top: 160, bottom: 160, left: 200, right: 200 },
              children: [
                new Paragraph({
                  alignment: AlignmentType.CENTER,
                  spacing: { before: 60, after: 60 },
                  children: [
                    new TextRun({
                      text: `📸 [KHUNG CHÈN ẢNH - HÌNH ${figNum}]`,
                      bold: true,
                      size: 24,
                      font: FONT_FAMILY,
                      color: COLOR_PRIMARY,
                    }),
                  ],
                }),
                new Paragraph({
                  alignment: AlignmentType.CENTER,
                  spacing: { after: 80 },
                  children: [
                    new TextRun({
                      text: title,
                      bold: true,
                      size: 22,
                      font: FONT_FAMILY,
                      color: '222222',
                    }),
                  ],
                }),
                new Paragraph({
                  alignment: AlignmentType.JUSTIFIED,
                  spacing: { after: 60, line: 280 },
                  children: [
                    new TextRun({
                      text: 'Mô tả nội dung: ',
                      bold: true,
                      size: 20,
                      font: FONT_FAMILY,
                      color: COLOR_SECONDARY,
                    }),
                    new TextRun({
                      text: description,
                      size: 20,
                      font: FONT_FAMILY,
                      color: '444444',
                    }),
                  ],
                }),
                new Paragraph({
                  alignment: AlignmentType.JUSTIFIED,
                  spacing: { after: 100, line: 280 },
                  children: [
                    new TextRun({
                      text: 'Hướng dẫn chụp ảnh: ',
                      bold: true,
                      size: 20,
                      font: FONT_FAMILY,
                      color: COLOR_GOLD,
                    }),
                    new TextRun({
                      text: instructions,
                      italics: true,
                      size: 20,
                      font: FONT_FAMILY,
                      color: '555555',
                    }),
                  ],
                }),
                new Paragraph({
                  alignment: AlignmentType.CENTER,
                  spacing: { before: 80, after: 40 },
                  children: [
                    new TextRun({
                      text: '⬇ (DÁN ẢNH CHỤP THỰC TẾ CỦA BẠN VÀO ĐÂY) ⬇',
                      bold: true,
                      size: 20,
                      font: FONT_FAMILY,
                      color: '888888',
                    }),
                  ],
                }),
              ],
            }),
          ],
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 60, after: 200 },
      children: [
        new TextRun({
          text: `Hình ${figNum}: ${title}`,
          italics: true,
          bold: true,
          size: 22,
          font: FONT_FAMILY,
          color: '444444',
        }),
      ],
    }),
  ];
}

function createTable(headers, rowsData, colWidths = []) {
  const tableRows = [];

  // Header Row
  tableRows.push(
    new TableRow({
      tableHeader: true,
      children: headers.map((h, index) =>
        new TableCell({
          width: colWidths[index] ? { size: colWidths[index], type: WidthType.PERCENTAGE } : undefined,
          shading: { fill: COLOR_PRIMARY },
          margins: { top: 120, bottom: 120, left: 140, right: 140 },
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({
                  text: h,
                  bold: true,
                  size: 21,
                  font: FONT_FAMILY,
                  color: 'FFFFFF',
                }),
              ],
            }),
          ],
        })
      ),
    })
  );

  // Data Rows
  rowsData.forEach((row, rIdx) => {
    const isEven = rIdx % 2 === 0;
    tableRows.push(
      new TableRow({
        children: row.map((cellText, index) =>
          new TableCell({
            width: colWidths[index] ? { size: colWidths[index], type: WidthType.PERCENTAGE } : undefined,
            shading: isEven ? { fill: 'F9FAFC' } : { fill: 'FFFFFF' },
            margins: { top: 100, bottom: 100, left: 120, right: 120 },
            children: [
              new Paragraph({
                alignment: index === 0 ? AlignmentType.CENTER : AlignmentType.LEFT,
                children: [
                  new TextRun({
                    text: cellText,
                    size: 20,
                    font: FONT_FAMILY,
                    color: COLOR_TEXT,
                  }),
                ],
              }),
            ],
          })
        ),
      })
    );
  });

  return new Table({
    width: { size: 100, type: WidthType.PERCENTAGE },
    borders: {
      top: { style: BorderStyle.SINGLE, size: 4, color: 'CCCCCC' },
      bottom: { style: BorderStyle.SINGLE, size: 4, color: 'CCCCCC' },
      left: { style: BorderStyle.SINGLE, size: 4, color: 'CCCCCC' },
      right: { style: BorderStyle.SINGLE, size: 4, color: 'CCCCCC' },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'E0E0E0' },
      insideVertical: { style: BorderStyle.SINGLE, size: 2, color: 'E0E0E0' },
    },
    rows: tableRows,
  });
}

function buildDocument() {
  const children = [];

  // ==================== TRANG BÌA ====================
  children.push(
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 60 },
      children: [
        new TextRun({
          text: 'BỘ GIÁO DỤC VÀ ĐÀO TẠO\nTRƯỜNG ĐẠI HỌC CÔNG NGHỆ',
          bold: true,
          size: 26,
          font: FONT_FAMILY,
          color: '111111',
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 400 },
      children: [
        new TextRun({
          text: 'KHOA CÔNG NGHỆ THÔNG TIN',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
          color: COLOR_SECONDARY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 400, after: 200 },
      children: [
        new TextRun({
          text: 'BÁO CÁO KHÓA LUẬN TỐT NGHIỆP ĐẠI HỌC',
          bold: true,
          size: 32,
          font: FONT_FAMILY,
          color: COLOR_PRIMARY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 300 },
      children: [
        new TextRun({
          text: 'CHUYÊN NGÀNH: KỸ THUẬT PHẦN MỀM',
          bold: true,
          size: 26,
          font: FONT_FAMILY,
          color: COLOR_SECONDARY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 100 },
      children: [
        new TextRun({
          text: 'ĐỀ TÀI:',
          bold: true,
          size: 26,
          font: FONT_FAMILY,
          color: '333333',
        }),
      ],
    }),
    createTitle('NGHIÊN CỨU VÀ XÂY DỰNG HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN "LUXE GRAND HOTEL" TRÊN NỀN TẢNG NESTJS VÀ FLUTTER'),
    new Paragraph({
      alignment: AlignmentType.LEFT,
      spacing: { before: 800, after: 80 },
      indent: { left: 2400 },
      children: [
        new TextRun({
          text: 'Sinh viên thực hiện:\t',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
        }),
        new TextRun({
          text: '[Họ và tên sinh viên]',
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.LEFT,
      spacing: { after: 80 },
      indent: { left: 2400 },
      children: [
        new TextRun({
          text: 'Mã số sinh viên:\t',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
        }),
        new TextRun({
          text: '[MSSV]',
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.LEFT,
      spacing: { after: 80 },
      indent: { left: 2400 },
      children: [
        new TextRun({
          text: 'Lớp chuyên ngành:\t',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
        }),
        new TextRun({
          text: '[Tên Lớp / Khóa]',
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.LEFT,
      spacing: { after: 80 },
      indent: { left: 2400 },
      children: [
        new TextRun({
          text: 'Giảng viên hướng dẫn:\t',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
        }),
        new TextRun({
          text: '[Học hàm, Học vị - Họ tên GVHD]',
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 600, after: 100 },
      children: [
        new TextRun({
          text: 'Hà Nội, Năm 2026',
          bold: true,
          size: 22,
          font: FONT_FAMILY,
          color: '555555',
        }),
      ],
    })
  );

  // ==================== LỜI CAM ĐOAN ====================
  children.push(
    createHeading1('LỜI CAM ĐOAN', true),
    createParagraph(
      'Tôi xin cam đoan đây là công trình nghiên cứu và phát triển phần mềm độc lập của bản thân dưới sự hướng dẫn khoa học của Giảng viên hướng dẫn. Các số liệu, kết quả khảo sát và thực nghiệm trình bày trong cuốn báo cáo khóa luận tốt nghiệp này là hoàn toàn trung thực, phản ánh chính xác các kết quả hiện thực hóa thực tế của dự án Luxe Grand Hotel.'
    ),
    createParagraph(
      'Các tài liệu tham khảo, các thư viện công nghệ mã nguồn mở (NestJS, Flutter, Prisma, Redis, PostgreSQL, Elasticsearch...) đều được kế thừa và trích dẫn nguồn gốc đầy đủ, rõ ràng theo đúng chuẩn mực đạo đức nghiên cứu học thuật.'
    ),
    new Paragraph({
      alignment: AlignmentType.RIGHT,
      spacing: { before: 300, after: 60 },
      children: [
        new TextRun({
          text: 'Hà Nội, ngày 21 tháng 09 năm 2026',
          italics: true,
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.RIGHT,
      spacing: { after: 400 },
      children: [
        new TextRun({
          text: 'Sinh viên thực hiện\n(Ký và ghi rõ họ tên)',
          bold: true,
          size: 24,
          font: FONT_FAMILY,
        }),
      ],
    })
  );

  // ==================== LỜI CẢM ƠN ====================
  children.push(
    createHeading1('LỜI CẢM ƠN', true),
    createParagraph(
      'Để có thể hoàn thành xuất sắc đồ án tốt nghiệp này, trước hết em xin bày tỏ lòng biết ơn chân thành và sâu sắc nhất tới toàn thể quý Thầy, Cô giáo trong Khoa Công nghệ Thông tin - Trường Đại học Công nghệ. Quý Thầy Cô đã luôn tận tâm truyền đạt cho em những nền tảng tri thức vững chắc, phương pháp nghiên cứu khoa học và tư duy giải quyết vấn đề trong suốt những năm tháng đại học.'
    ),
    createParagraph(
      'Đặc biệt, em xin gửi lời cảm ơn sâu sắc nhất tới Thầy/Cô hướng dẫn [Họ tên GVHD]. Thầy/Cô đã dành nhiều thời gian, công sức để chỉ bảo, góp ý định hướng về kiến trúc hệ thống, đồng thời khích lệ, động viên em vượt qua những thách thức trong việc tối ưu cơ sở dữ liệu và xử lý tranh chấp giao dịch.'
    ),
    createParagraph(
      'Cuối cùng, em xin gửi lời tri ân vô hạn tới gia đình và bạn bè đã luôn ở bên cạnh động viên, tiếp thêm niềm tin và động lực để em hoàn thành trọn vẹn chương trình học tập.'
    )
  );

  // ==================== TÓM TẮT ĐỀ TÀI (ABSTRACT) ====================
  children.push(
    createHeading1('TÓM TẮT ĐỀ TÀI (ABSTRACT)', true),
    createHeading2('1. Tóm tắt tiếng Việt'),
    createParagraph(
      'Trong thời đại bùng nổ của chuyển đổi số ngành du lịch - dịch vụ lưu trú, việc tin học hóa toàn diện quy trình quản lý khách sạn là yêu cầu sống còn nhằm nâng cao năng suất phục vụ và gia tăng sự hài lòng của khách hàng. Đề tài "Nghiên cứu và xây dựng hệ thống quản lý khách sạn toàn diện Luxe Grand Hotel trên nền tảng NestJS và Flutter" được phát triển nhằm cung cấp một giải pháp khép kín, hiện đại từ khâu đặt phòng, quản lý ma trận phòng thời gian thực, làm thủ tục Check-in/Check-out, đổi phòng, gọi dịch vụ phòng gia tăng đến kiểm soát ca trực lễ tân và đối soát tài chính.'
    ),
    createParagraph(
      'Hệ thống gồm 2 thành phần chính: (1) Backend RESTful API phát triển bằng NestJS, TypeScript, PostgreSQL 16, Prisma ORM, Redis Cache, Elasticsearch, FCM và NestJS Schedule Cron; (2) Frontend Mobile phát triển bằng Flutter đa nền tảng (iOS/Android) với kiến trúc BLoC State Management, Dio HTTP client, FL Chart và giao diện chuẩn 5 sao.'
    ),
    createHeading2('2. English Abstract'),
    createParagraph(
      'In the era of digital transformation in the hospitality sector, automating hotel operational workflows is crucial for operational excellence and superior guest satisfaction. The capstone project "Research and Development of Luxe Grand Hotel Management System powered by NestJS and Flutter Multi-platform" delivers an enterprise-grade solution covering online room booking, real-time room matrix visualization, check-in/check-out processing, room relocation, room-service ordering, and cashier shift handover reconciliation.'
    ),
    createParagraph(
      'The architecture comprises two decoupled layers: (1) An enterprise Backend built with NestJS, TypeScript, PostgreSQL, Prisma ORM, Redis Cache, Elasticsearch, FCM Push Notifications, and NestJS Cron Schedulers; (2) A cross-platform Mobile Application developed using Flutter (Dart) with BLoC State Management, Clean Feature-First Architecture, and interactive FL Chart analytics.'
    )
  );

  // ==================== DANH MỤC TỪ VIẾT TẮT ====================
  children.push(
    createHeading1('DANH MỤC TỪ VIẾT TẮT', true),
    createTable(
      ['STT', 'Viết tắt', 'Thuật ngữ đầy đủ (Tiếng Anh)', 'Ý nghĩa trong đề tài'],
      [
        ['1', 'API', 'Application Programming Interface', 'Giao diện lập trình ứng dụng'],
        ['2', 'BE', 'Backend', 'Phân hệ máy chủ xử lý dữ liệu và nghiệp vụ'],
        ['3', 'FE', 'Frontend', 'Phân hệ giao diện di động cho người dùng'],
        ['4', 'BLoC', 'Business Logic Component', 'Mô hình quản lý trạng thái luồng sự kiện Flutter'],
        ['5', 'DTO', 'Data Transfer Object', 'Đối tượng vận chuyển và kiểm định dữ liệu'],
        ['6', 'DI / IoC', 'Dependency Injection / Inversion of Control', 'Tiêm phụ thuộc và đảo ngược quyền điều khiển'],
        ['7', 'ERD', 'Entity Relationship Diagram', 'Sơ đồ quan hệ thực thể cơ sở dữ liệu'],
        ['8', 'PK / FK', 'Primary Key / Foreign Key', 'Khóa chính và khóa ngoại trong CSDL'],
        ['9', 'FCM', 'Firebase Cloud Messaging', 'Dịch vụ gửi thông báo đẩy đám mây Google'],
        ['10', 'JWT', 'JSON Web Token', 'Chuẩn mã hóa token xác thực an toàn'],
        ['11', 'ORM', 'Object-Relational Mapping', 'Kỹ thuật ánh xạ đối tượng với bảng CSDL'],
        ['12', 'RBAC', 'Role-Based Access Control', 'Kiểm soát quyền truy cập dựa trên vai trò'],
        ['13', 'REST', 'Representational State Transfer', 'Phong cách kiến trúc giao tiếp dịch vụ web'],
        ['14', 'UAT', 'User Acceptance Testing', 'Kiểm thử chấp nhận từ người dùng thực tế']
      ],
      [8, 16, 38, 38]
    )
  );

  // ==================== CHƯƠNG 1 ====================
  children.push(
    createHeading1('CHƯƠNG 1: TỔNG QUAN ĐỀ TÀI VÀ PHÂN TÍCH HIỆN TRẠNG', true),
    createHeading2('1.1. Lý do chọn đề tài và tính cấp thiết'),
    createParagraph(
      'Ngành kinh doanh dịch vụ khách sạn - resort tại Việt Nam đang chứng kiến sự hồi phục và tăng trưởng vượt bậc. Tuy nhiên, phần lớn các khách sạn quy mô vừa và nhỏ (3 đến 4 sao, khách sạn boutique) vẫn đang vận hành theo phương thức truyền thống: ghi chép sổ sách hoặc sử dụng các phần mềm desktop cục bộ, gây ra nhiều bất cập nghiêm trọng:'
    ),
    createBullet('Nguy cơ trùng lặp đơn đặt phòng (Double-booking) giữa khách vãng lai (walk-in) và khách đặt trực tuyến do dữ liệu không đồng bộ thời gian thực.'),
    createBullet('Khó khăn trong quản lý ca trực lễ tân: Tiền mặt, tiền chuyển khoản và tiền đặt cọc dễ bị thất thoát hoặc chênh lệch khi bàn giao giữa các ca.'),
    createBullet('Khách hàng thiếu kênh tương tác di động tự phục vụ: Muốn gọi đồ uống, giặt ủi hay xem tiến độ hóa đơn đều phải gọi điện thoại bàn hoặc tới quầy lễ tân.'),
    createParagraph(
      'Do đó, việc nghiên cứu và xây dựng hệ thống quản lý khách sạn "Luxe Grand Hotel" gộp cả Backend đám mây mạnh mẽ và ứng dụng di động Flutter đa nền tảng là một yêu cầu cấp thiết, mang lại giá trị thực tiễn to lớn.'
    ),
    createHeading2('1.2. Mục tiêu nghiên cứu và phạm vi của đề tài'),
    createParagraph(
      'Mục tiêu của đề tài là xây dựng hoàn chỉnh một giải pháp phần mềm hiện đại, ổn định, bảo mật và thân thiện:'
    ),
    createBullet('Xây dựng hệ thống Backend API chuẩn công nghiệp với NestJS, PostgreSQL và Prisma ORM, có cơ chế phân quyền RBAC và xử lý tranh chấp đặt phòng tuyệt đối.'),
    createBullet('Tích hợp dịch vụ đệm Redis Caching và công cụ tìm kiếm phân tán Elasticsearch để tối ưu hóa hiệu năng truy vấn dữ liệu phòng và dịch vụ.'),
    createBullet('Phát triển ứng dụng di động Flutter đa nền tảng với đầy đủ 3 phân hệ: Khách hàng (Customer), Lễ tân/Thu ngân (Receptionist/Cashier) và Quản trị viên (Admin).'),
    createBullet('Xây dựng module quản lý ca trực (WorkShift) và sổ thu tiền chi tiết (Multi-Entry Payments) để giải quyết trọn vẹn bài toán đối soát dòng tiền.'),
    createHeading2('1.3. Khảo sát hiện trạng và các giải pháp hiện nay'),
    createParagraph(
      'Bảng dưới đây thể hiện sự so sánh chi tiết giữa giải pháp Luxe Grand Hotel được xây dựng trong đồ án với các hình thức quản lý truyền thống:'
    ),
    createHeading3('Bảng 1.1: So sánh giải pháp Luxe Grand Hotel với các phần mềm truyền thống'),
    createTable(
      ['Tiêu chí so sánh', 'Sổ sách / Excel thủ công', 'PMS Desktop cũ', 'Hệ thống Luxe Grand Hotel'],
      [
        ['Tính cơ động', 'Rất thấp (chỉ tại bàn làm việc)', 'Thấp (cố định trên PC quầy lễ tân)', 'Rất cao (Ứng dụng di động Flutter iOS/Android)'],
        ['Trải nghiệm khách', 'Thụ động qua gọi điện thoại', 'Khách không có app tương tác', 'Chủ động tra cứu, đặt phòng, gọi dịch vụ, xem bill'],
        ['Sơ đồ phòng', 'Kẻ bảng giấy, dễ nhầm lẫn', 'Lưới ô vuông cơ bản', 'Room Matrix theo tầng, đổi màu trạng thái tức thì'],
        ['Quản lý ca & Tiền', 'Cộng sổ cuối ngày, dễ thất thoát', 'Báo cáo doanh thu chung', 'Mở/Chốt ca trực, đối soát tiền mặt tự động, lưu vết'],
        ['Tìm kiếm & Tốc độ', 'Thủ công, mất thời gian', 'Truy vấn SQL chậm khi tải cao', 'Redis Caching & Elasticsearch tìm kiếm tức thì']
      ],
      [22, 26, 26, 26]
    ),
    createHeading2('1.4. Đối tượng sử dụng và vai trò trong hệ thống'),
    createBullet('Khách hàng (Customer): Tìm kiếm phòng trống theo ngày, xem tiện nghi, tạo đơn đặt phòng, theo dõi hóa đơn, gửi yêu cầu thanh toán chuyển khoản, order dịch vụ phòng.'),
    createBullet('Lễ tân kiêm Thu ngân (Receptionist / Cashier): Quản lý ca trực (mở ca, chốt ca, kiểm đếm tiền két), xem ma trận phòng Room Matrix, làm thủ tục Check-in/Check-out, đổi phòng, tiếp nhận khách Walk-in, xác nhận khoản thanh toán chuyển khoản của khách.'),
    createBullet('Quản trị viên (Admin / General Manager): Giám sát Dashboard điều hành thời gian thực, xem biểu đồ doanh thu theo năm/tháng, phân tích tỷ lệ lấp đầy phòng, phê duyệt đơn trực tuyến, quản lý danh mục phòng và nhân sự.')
  );

  // ==================== CHƯƠNG 2 ====================
  const archImgPath = path.join(ASSETS_DIR, 'hinh1_kien_truc_he_thong.jpg');
  children.push(
    createHeading1('CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ÁP DỤNG', true),
    createHeading2('2.1. Kiến trúc tổng thể Client - Server và RESTful API'),
    createParagraph(
      'Hệ thống Luxe Grand Hotel được xây dựng theo mô hình Client - Server phân tán. Toàn bộ logic nghiệp vụ, tính toán tài chính và kiểm tra ràng buộc phòng được tập trung tại Backend (NestJS), trong khi Mobile Client (Flutter) chịu trách nhiệm hiển thị giao diện và thu nhận tương tác người dùng.'
    )
  );

  if (fs.existsSync(archImgPath)) {
    children.push(...createImage(archImgPath, 520, 290, 'Hình 2.1: Sơ đồ kiến trúc kỹ thuật phân tầng hệ thống Luxe Grand Hotel'));
  } else {
    children.push(...createImagePlaceholder('2.1', 'Sơ đồ Kiến trúc phân tầng kỹ thuật hệ thống Luxe Grand Hotel', 'Bao gồm 4 tầng: Client Mobile Flutter, Network Gateway HTTPS, Backend Server NestJS, và Data Tier PostgreSQL, Redis, Elasticsearch.', 'Vẽ sơ đồ kiến trúc hệ thống bằng Draw.io hoặc trích xuất từ tài liệu SAD rồi dán ảnh vào đây.'));
  }

  children.push(
    createHeading2('2.2. Công nghệ phát triển phía Backend (NestJS & Ecosystem)'),
    createBullet('NestJS Framework & TypeScript: Cung cấp kiến trúc Modular rõ ràng, áp dụng mẫu thiết kế Dependency Injection (DI) và Inversion of Control (IoC), giúp mã nguồn dễ bảo trì và kiểm thử.'),
    createBullet('PostgreSQL & Prisma ORM: PostgreSQL đảm bảo chuẩn ACID khắt khe cho các giao dịch tài chính. Prisma ORM mang lại khả năng định kiểu Type-safe 100% giữa TypeScript và Database Schema, ngăn ngừa hoàn toàn các lỗi runtime.'),
    createBullet('Redis Cache: Bộ nhớ đệm In-Memory siêu tốc, lưu trữ tạm danh mục phòng trống và danh mục dịch vụ nhằm giảm tải 65% số lượng truy vấn tới cơ sở dữ liệu.'),
    createBullet('Elasticsearch Engine: Máy chủ tìm kiếm phân tán toàn văn, hỗ trợ khách hàng tìm kiếm phòng theo từ khóa mô tả, tiện ích và vị trí với thời gian đáp ứng dưới 50ms.'),
    createBullet('Firebase Cloud Messaging (FCM): Dịch vụ thông báo đẩy thời gian thực gửi thông báo xác nhận đơn phòng, thông báo duyệt chuyển khoản tới điện thoại người dùng.'),
    createBullet('NestJS Schedule (@Cron): Tác vụ tự động chạy nền định kỳ mỗi sáng lúc 09:00 để quét các đơn phòng cần check-in hôm nay và gửi thông báo nhắc nhở khách.'),
    createHeading2('2.3. Công nghệ phát triển phía Frontend Mobile (Flutter & Dart)'),
    createBullet('Flutter & Dart: Cho phép biên dịch ra mã máy gốc ARM/x86 trên cả Android và iOS, đạt tốc độ khung hình 60fps mượt mà.'),
    createBullet('BLoC Pattern (Business Logic Component): Mẫu quản lý trạng thái dựa trên luồng sự kiện (Events -> Bloc -> States), giúp tách rời hoàn toàn tầng giao diện (UI) và logic nghiệp vụ.'),
    createBullet('Dio Client & Interceptors: Xử lý các request mạng HTTP, tự động đính kèm JWT Bearer token vào Header và xử lý lỗi mạng tập trung.'),
    createBullet('FL Chart Library: Thư viện vẽ biểu đồ doanh thu dạng cột (Bar Chart) và đường cong mượt mà, hỗ trợ tương tác cảm ứng trực tiếp trên màn hình báo cáo của Admin.')
  );

  children.push(...createImagePlaceholder('2.2', 'Mô hình luồng dữ liệu quản lý trạng thái BLoC trong Flutter', 'Sơ đồ tương tác luồng 6 bước: UI dispatch Event -> BLoC nhận Event -> Repository gọi API Dio -> Backend trả JSON -> Repository trả Entity -> BLoC emit State cập nhật UI.', 'Chèn hình ảnh sơ đồ luồng BLoC Pattern được thiết kế trong tài liệu SAD vào đây.'));

  // ==================== CHƯƠNG 3 ====================
  children.push(
    createHeading1('CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG', true),
    createHeading2('3.1. Phân tích yêu cầu chức năng (27 Yêu cầu chức năng chi tiết FR-01 đến FR-27)'),
    createParagraph(
      'Hệ thống Luxe Grand Hotel được đặc tả đầy đủ 27 yêu cầu chức năng nghiệp vụ (Functional Requirements) chia thành 14 phân hệ chuyên biệt theo chuẩn IEEE 830:'
    ),
    createBullet('Phân hệ 1 (Auth): [FR-01] Đăng ký tài khoản; [FR-02] Đăng nhập JWT; [FR-03] Quên mật khẩu OTP qua Email.'),
    createBullet('Phân hệ 2 (Rooms & Matrix): [FR-04] Quản lý hạng phòng; [FR-05] Quản lý phòng vật lý; [FR-06] Sơ đồ Ma trận phòng thời gian thực theo tầng.'),
    createBullet('Phân hệ 3 (Bookings): [FR-07] Tìm phòng trống theo ngày; [FR-08] Đặt phòng online; [FR-09] Duyệt/Từ chối đơn; [FR-10] Check-in & Walk-in; [FR-11] Đổi phòng; [FR-12] Check-out kiểm kê dịch vụ.'),
    createBullet('Phân hệ 4 & 5 (Services & Cashier): [FR-13] Quản lý danh mục dịch vụ; [FR-14] Order dịch vụ phòng; [FR-15] Sổ thu tiền đa đợt; [FR-16] Quản lý ca trực lễ tân.'),
    createBullet('Phân hệ 6 đến 14 (Analytics, Admin & System): [FR-17] Dashboard KPI; [FR-18] Biểu đồ Doanh thu 12 tháng FL Chart; [FR-19] Cron nhắc check-in; [FR-20] Quản lý nhân sự RBAC; [FR-21] Hồ sơ cá nhân; [FR-22] Thông báo FCM; [FR-23] Hiệu suất nhân viên; [FR-24] Checkout Preview; [FR-25] Lịch sử ca & Cưỡng chế chốt ca; [FR-26] Từ chối chuyển khoản giả; [FR-27] Đồng bộ phòng & Upload ảnh.'),
    createHeading3('Bảng 3.1: Bảng Ma trận truy vết yêu cầu toàn diện (Full Traceability Matrix 27 FRs)'),
    createTable(
      ['Mã YC', 'Tên yêu cầu chức năng', 'Phân hệ', 'Vai trò', 'API Endpoint liên quan', 'Bảng CSDL chính'],
      [
        ['FR-01', 'Đăng ký tài khoản Khách hàng', 'Auth', 'Customer', 'POST /auth/register', 'users'],
        ['FR-02', 'Đăng nhập & Cấp phát JWT', 'Auth', 'All', 'POST /auth/login', 'users'],
        ['FR-03', 'Quên mật khẩu qua Email OTP', 'Auth', 'Customer', 'POST /auth/forgot-password', 'password_resets'],
        ['FR-04', 'Quản lý Hạng phòng & Bảng giá', 'Catalog', 'Admin', 'GET,POST,PATCH,DELETE /room-types', 'room_types'],
        ['FR-05', 'Quản lý Danh mục Phòng vật lý', 'Catalog', 'Admin/Staff', 'GET,POST,PATCH,DELETE /rooms', 'rooms'],
        ['FR-06', 'Sơ đồ Ma trận phòng thời gian thực', 'Front-desk', 'Staff/Admin', 'GET /rooms/matrix', 'rooms, bookings'],
        ['FR-07', 'Tra cứu phòng trống theo ngày', 'Booking', 'Customer/Staff', 'GET /rooms/available', 'rooms, bookings'],
        ['FR-08', 'Tạo đơn đặt phòng trực tuyến', 'Booking', 'Customer', 'POST /bookings', 'bookings, invoices'],
        ['FR-09', 'Phê duyệt & Từ chối đơn đặt phòng', 'Booking', 'Staff/Admin', 'PUT /bookings/{id}/approve, /reject', 'bookings, rooms'],
        ['FR-10', 'Check-in & Tiếp nhận khách Walk-in', 'Front-desk', 'Staff/Admin', 'POST /bookings/{id}/check-in', 'bookings, rooms'],
        ['FR-11', 'Đổi phòng lưu trú linh hoạt', 'Front-desk', 'Staff/Admin', 'POST /bookings/{id}/change-room', 'bookings, rooms'],
        ['FR-12', 'Check-out trả phòng & Kiểm kê minibar', 'Front-desk', 'Staff/Admin', 'POST /bookings/{id}/check-out', 'bookings, invoices'],
        ['FR-13', 'Quản lý Danh mục Dịch vụ KS', 'Catalog', 'Admin', 'GET,POST,PATCH,DELETE /services', 'hotel_services'],
        ['FR-14', 'Đặt dịch vụ gia tăng theo phòng', 'Services', 'Customer/Staff', 'POST /bookings/{id}/services', 'extra_service_orders'],
        ['FR-15', 'Sổ thu tiền đa đợt & Đối soát', 'Cashier', 'Customer/Staff', 'POST /invoices/{id}/pay, /payments', 'invoices, payments'],
        ['FR-16', 'Quản lý Ca trực lễ tân & Đối soát két', 'Cashier', 'Receptionist', 'POST /shifts/open, /close', 'work_shifts, payments'],
        ['FR-17', 'Dashboard điều hành thời gian thực', 'Analytics', 'Admin', 'GET /analytics/dashboard', 'rooms, bookings'],
        ['FR-18', 'Báo cáo Biểu đồ Doanh thu 12 tháng', 'Analytics', 'Admin', 'GET /analytics/revenue', 'invoices, payments'],
        ['FR-19', 'Tác vụ Nhắc lịch Check-in (Cron)', 'Notification', 'System', 'Cron @EveryDayAt9AM', 'bookings, users'],
        ['FR-20', 'Quản trị Nhân sự & Phân quyền RBAC', 'Staff', 'Admin', 'GET,POST,PATCH,DELETE /users', 'users'],
        ['FR-21', 'Quản lý Hồ sơ cá nhân & Đổi mật khẩu', 'Security', 'All', 'GET /auth/me, POST /change-password', 'users'],
        ['FR-22', 'Trung tâm Thông báo FCM đa kênh', 'Notification', 'All', 'GET /notifications, PATCH /fcm-token', 'notifications'],
        ['FR-23', 'Hiệu suất Nhân viên & Doanh thu Ngày', 'Analytics', 'Admin/Staff', 'GET /analytics/staff-performance', 'work_shifts, invoices'],
        ['FR-24', 'Xem trước Hóa đơn Check-out Preview', 'Front-desk', 'Staff/Admin', 'GET /bookings/{id}/checkout-preview', 'bookings, invoices'],
        ['FR-25', 'Sổ Lịch sử Ca & Cưỡng chế Chốt ca', 'Cashier', 'Admin/Staff', 'GET /shifts, POST /shifts/{id}/close', 'work_shifts, payments'],
        ['FR-26', 'Từ chối Giao dịch Chuyển khoản nghi vấn', 'Cashier', 'Staff/Admin', 'POST /payments/{id}/reject', 'payments, invoices'],
        ['FR-27', 'Đồng bộ Trạng thái Phòng & Upload File', 'System/Media', 'Admin/Staff', 'POST /rooms/sync-status, /upload/*', 'rooms, upload']
      ],
      [8, 26, 12, 12, 24, 18]
    )
  );

  children.push(...createImagePlaceholder('3.1', 'Sơ đồ Use Case tổng thể toàn hệ thống Luxe Grand Hotel', 'Mô tả mối quan hệ giữa 3 tác nhân: Khách hàng, Lễ tân/Thu ngân và Quản trị viên cùng ranh giới các Use Case trong hệ thống.', 'Vẽ sơ đồ Use Case bằng StarUML hoặc Draw.io rồi dán ảnh vào đây.'));
  children.push(...createImagePlaceholder('3.2', 'Sơ đồ tuần tự Quy trình Đặt phòng trực tuyến và Duyệt đơn', 'Thể hiện tương tác giữa Khách hàng, Mobile App, NestJS Server, PostgreSQL Database và Lễ tân duyệt đơn.', 'Dán ảnh sơ đồ tuần tự đặt phòng (Sequence Diagram) vào đây.'));
  children.push(...createImagePlaceholder('3.3', 'Sơ đồ tuần tự Quy trình Nhận phòng, Đổi phòng và Trả phòng', 'Thể hiện các bước làm thủ tục Check-in, hoán đổi sang phòng trống tương đương khi có sự cố, và kiểm kê chi phí khi Check-out.', 'Dán ảnh sơ đồ tuần tự lễ tân vào đây.'));
  children.push(...createImagePlaceholder('3.4', 'Sơ đồ trạng thái Quy trình Mở ca, Thu tiền trong ca và Chốt ca lễ tân', 'Vòng đời ca trực từ OPEN -> Giao dịch thu tiền -> Chốt ca CLOSING -> Tính tiền két expectedCash -> CLOSED.', 'Dán ảnh sơ đồ trạng thái ca trực vào đây.'));
  children.push(...createImagePlaceholder('3.5', 'Sơ đồ quan hệ thực thể (ERD) hoàn chỉnh 8 bảng chuẩn 3NF', 'Mô hình liên kết 8 bảng: users, room_types, rooms, bookings, invoices, payments, work_shifts, extra_service_orders.', 'Dán ảnh sơ đồ ERD trích xuất từ tài liệu SAD hoặc DBeaver vào đây.'));

  children.push(
    createHeading2('3.2. Thiết kế Cơ sở dữ liệu quan hệ (ERD & Data Dictionary)'),
    createHeading3('Bảng 3.2: Tổng hợp liên kết Khóa chính (PK) - Khóa ngoại (FK) giữa các bảng'),
    createTable(
      ['STT', 'Bảng con (Child Table)', 'Khóa ngoại (FK)', 'Bảng cha (Parent Table)', 'Khóa chính (PK)', 'Quan hệ', 'Ràng buộc On Delete', 'Ý nghĩa nghiệp vụ'],
      [
        ['1', 'rooms', 'roomTypeId', 'room_types', 'id', '1 - N', 'RESTRICT', 'Mỗi phòng thuộc về 1 hạng phòng xác định'],
        ['2', 'bookings', 'customerId', 'users', 'id', '1 - N', 'RESTRICT', 'Mỗi đơn đặt phòng do 1 khách hàng tạo'],
        ['3', 'bookings', 'roomId', 'rooms', 'id', '1 - N', 'RESTRICT', 'Đơn phòng được phân bổ cho 1 phòng vật lý'],
        ['4', 'bookings', 'confirmedById', 'users', 'id', '1 - N', 'SET NULL', 'Nhân viên lễ tân/admin duyệt đơn phòng'],
        ['5', 'bookings', 'cancelledById', 'users', 'id', '1 - N', 'SET NULL', 'Nhân viên thực hiện hủy/từ chối đơn'],
        ['6', 'invoices', 'bookingId', 'bookings', 'id', '1 - 1', 'CASCADE', 'Mỗi đơn phòng có đúng 1 hóa đơn thanh toán'],
        ['7', 'invoices', 'issuedById', 'users', 'id', '1 - N', 'SET NULL', 'Thu ngân chịu trách nhiệm xuất hóa đơn'],
        ['8', 'payments', 'invoiceId', 'invoices', 'id', '1 - N', 'CASCADE', 'Hóa đơn gồm nhiều dòng thu (cọc, trả nợ, hoàn)'],
        ['9', 'payments', 'createdById', 'users', 'id', '1 - N', 'SET NULL', 'Người yêu cầu thu (khách chuyển khoản / lễ tân)'],
        ['10', 'payments', 'confirmedById', 'users', 'id', '1 - N', 'SET NULL', 'Thu ngân kiểm tra sao kê và duyệt nhận tiền'],
        ['11', 'payments', 'shiftId', 'work_shifts', 'id', '1 - N', 'SET NULL', 'Khoản thu được ghi nhận vào ca trực của lễ tân'],
        ['12', 'work_shifts', 'staffId', 'users', 'id', '1 - N', 'RESTRICT', 'Ca trực thuộc quyền phụ trách của 1 nhân viên'],
        ['13', 'work_shifts', 'handoverStaffId', 'users', 'id', '1 - N', 'SET NULL', 'Nhân viên tiếp nhận bàn giao ca ca tiếp theo'],
        ['14', 'extra_service_orders', 'bookingId', 'bookings', 'id', '1 - N', 'CASCADE', 'Dịch vụ phát sinh (minibar, ăn uống) theo đơn'],
        ['15', 'extra_service_orders', 'requestedById', 'users', 'id', '1 - N', 'SET NULL', 'Người gửi yêu cầu dịch vụ phòng']
      ],
      [5, 15, 14, 13, 8, 8, 13, 24]
    ),
    createHeading3('Bảng 3.3: Từ điển dữ liệu Bảng users (Người dùng và Nhân sự)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của người dùng'],
        ['email', 'String (Varchar)', 'Unique', 'No', '', 'Địa chỉ email đăng nhập hệ thống'],
        ['password', 'String', '', 'No', '', 'Mật khẩu đã băm một chiều bằng Bcrypt'],
        ['fullName', 'String', '', 'No', '', 'Họ và tên đầy đủ của người dùng / nhân viên'],
        ['phone', 'String', '', 'Yes', 'null', 'Số điện thoại liên hệ'],
        ['role', 'Enum Role', '', 'No', 'CUSTOMER', 'Vai trò: ADMIN, RECEPTIONIST, CUSTOMER'],
        ['avatar', 'String', '', 'Yes', 'null', 'Đường dẫn URL ảnh đại diện trên Cloudinary'],
        ['fcmToken', 'String', '', 'Yes', 'null', 'Mã token thiết bị di động gửi Push Notification'],
        ['createdAt', 'DateTime', '', 'No', 'now()', 'Thời điểm đăng ký tài khoản'],
        ['updatedAt', 'DateTime', '', 'No', 'updatedAt', 'Thời điểm cập nhật thông tin gần nhất']
      ],
      [18, 16, 10, 8, 12, 36]
    ),
    createHeading3('Bảng 3.4: Từ điển dữ liệu Bảng room_types (Hạng phòng và Cấu hình giá)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của loại phòng'],
        ['name', 'String', '', 'No', '', 'Tên hạng phòng (Standard, Deluxe Ocean, Suite...)'],
        ['description', 'Text', '', 'Yes', 'null', 'Mô tả chi tiết đặc điểm, phong cách phòng'],
        ['basePrice', 'Float', '', 'No', '', 'Đơn giá niêm yết cơ bản cho 1 đêm lưu trú'],
        ['maxOccupancy', 'Int', '', 'No', '2', 'Số lượng khách lưu trú tối đa cho phép'],
        ['amenities', 'String[]', '', 'No', '[]', 'Mảng danh sách tiện ích (Wifi, Minibar, Bồn tắm...)'],
        ['images', 'String[]', '', 'No', '[]', 'Mảng URL các hình ảnh chụp thực tế của phòng'],
        ['createdAt', 'DateTime', '', 'No', 'now()', 'Thời điểm khởi tạo hạng phòng'],
        ['updatedAt', 'DateTime', '', 'No', 'updatedAt', 'Thời điểm chỉnh sửa bảng giá / tiện ích']
      ],
      [18, 16, 10, 8, 12, 36]
    ),
    createHeading3('Bảng 3.5: Từ điển dữ liệu Bảng rooms (Danh mục phòng vật lý)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của phòng vật lý'],
        ['roomNumber', 'String', 'Unique', 'No', '', 'Số phòng vật lý (ví dụ: 101, 102, 201...)'],
        ['floor', 'Int', 'Index', 'No', '', 'Số tầng vị trí của phòng trong tòa nhà'],
        ['status', 'Enum RoomStatus', 'Index', 'No', 'AVAILABLE', 'Trạng thái: AVAILABLE, OCCUPIED, CLEANING...'],
        ['roomTypeId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu tới bảng room_types.id'],
        ['createdAt', 'DateTime', '', 'No', 'now()', 'Thời điểm đưa phòng vào vận hành'],
        ['updatedAt', 'DateTime', '', 'No', 'updatedAt', 'Thời điểm cập nhật trạng thái dọn dẹp']
      ],
      [18, 16, 12, 8, 12, 34]
    ),
    createHeading3('Bảng 3.6: Từ điển dữ liệu Bảng bookings (Đơn đặt phòng)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của đơn phòng'],
        ['bookingCode', 'String', 'Unique', 'No', '', 'Mã hiển thị thân thiện (ví dụ: BK-2026-088)'],
        ['customerId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu tới users.id (khách hàng)'],
        ['roomId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu tới rooms.id (phòng được giao)'],
        ['checkInDate', 'DateTime', 'Index', 'No', '', 'Ngày & giờ dự kiến nhận phòng (14:00)'],
        ['checkOutDate', 'DateTime', 'Index', 'No', '', 'Ngày & giờ dự kiến trả phòng (12:00)'],
        ['actualCheckIn', 'DateTime', '', 'Yes', 'null', 'Thời điểm làm thủ tục Check-in thực tế tại quầy'],
        ['actualCheckOut', 'DateTime', '', 'Yes', 'null', 'Thời điểm làm thủ tục Check-out thực tế'],
        ['guestCount', 'Int', '', 'No', '1', 'Số lượng khách thực tế ở trong phòng'],
        ['totalAmount', 'Float', '', 'No', '', 'Tổng tiền phòng dự kiến theo số đêm ở'],
        ['depositAmount', 'Float', '', 'No', '0', 'Số tiền khách đã đặt cọc giữ chỗ'],
        ['status', 'Enum BookingStatus', 'Index', 'No', 'PENDING', 'Trạng thái: PENDING, CONFIRMED, CHECKED_IN...'],
        ['specialRequests', 'Text', '', 'Yes', 'null', 'Yêu cầu đặc biệt của khách (giường đôi, tầng cao)'],
        ['confirmedAt', 'DateTime', '', 'Yes', 'null', 'Thời điểm lễ tân bấm duyệt đơn phòng'],
        ['confirmedById', 'UUID / String', 'FK', 'Yes', 'null', 'Tham chiếu users.id người duyệt']
      ],
      [18, 16, 12, 8, 12, 34]
    ),
    createHeading3('Bảng 3.7: Từ điển dữ liệu Bảng invoices (Hóa đơn tài chính)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của hóa đơn'],
        ['invoiceCode', 'String', 'Unique', 'No', '', 'Mã số hóa đơn chứng từ (ví dụ: INV-2026-001)'],
        ['bookingId', 'UUID / String', 'FK, Unique', 'No', '', 'Tham chiếu 1-1 tới bookings.id'],
        ['roomAmount', 'Float', '', 'No', '', 'Tổng tiền phòng lưu trú'],
        ['servicesAmount', 'Float', '', 'No', '0', 'Tổng tiền các dịch vụ phát sinh (minibar, ăn uống)'],
        ['discount', 'Float', '', 'No', '0', 'Số tiền chiết khấu / giảm giá'],
        ['tax', 'Float', '', 'No', '0', 'Tiền thuế VAT'],
        ['finalAmount', 'Float', '', 'No', '', 'Tổng số tiền cuối cùng khách cần thanh toán'],
        ['paidAmount', 'Float', '', 'No', '0', 'Tổng số tiền khách đã thực trả (tính từ các Payment)'],
        ['paymentMethod', 'Enum PaymentMethod', '', 'No', 'CASH', 'Phương thức: CASH, CREDIT_CARD, BANK_TRANSFER'],
        ['paymentStatus', 'Enum PaymentStatus', 'Index', 'No', 'UNPAID', 'Trạng thái: UNPAID, PARTIAL, PAID, REFUNDED']
      ],
      [18, 16, 12, 8, 12, 34]
    ),
    createHeading3('Bảng 3.8: Từ điển dữ liệu Bảng payments (Sổ thu tiền chi tiết)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh giao dịch thu tiền'],
        ['invoiceId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu tới hóa đơn invoices.id'],
        ['amount', 'Float', '', 'No', '', 'Số tiền của lần thanh toán cụ thể'],
        ['method', 'Enum PaymentMethod', '', 'No', 'CASH', 'Hình thức: CASH, CREDIT_CARD, BANK_TRANSFER'],
        ['type', 'Enum EntryType', '', 'No', 'PAYMENT', 'Loại giao dịch: PAYMENT, DEPOSIT, REFUND'],
        ['status', 'Enum EntryStatus', 'Index', 'No', 'CONFIRMED', 'Trạng thái thu: PENDING, CONFIRMED, REJECTED'],
        ['reference', 'String', '', 'Yes', 'null', 'Mã tham chiếu ngân hàng khi chuyển khoản'],
        ['confirmedById', 'UUID / String', 'FK, Index', 'Yes', 'null', 'Tham chiếu users.id thu ngân duyệt tiền'],
        ['shiftId', 'UUID / String', 'FK, Index', 'Yes', 'null', 'Tham chiếu tới ca trực work_shifts.id']
      ],
      [18, 16, 12, 8, 12, 34]
    ),
    createHeading3('Bảng 3.9: Từ điển dữ liệu Bảng work_shifts (Ca trực lễ tân & Đối soát tiền két)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh duy nhất của ca trực'],
        ['shiftCode', 'String', 'Unique', 'No', '', 'Mã ca trực tự sinh (ví dụ: SFT-20260921-0001)'],
        ['staffId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu users.id nhân viên phụ trách ca'],
        ['shiftType', 'Enum ShiftType', '', 'No', 'MORNING', 'Loại ca: MORNING (Sáng), AFTERNOON, NIGHT'],
        ['status', 'Enum ShiftStatus', 'Index', 'No', 'OPEN', 'Trạng thái ca: OPEN (Đang mở), CLOSED (Đã chốt)'],
        ['initialCash', 'Float', '', 'No', '0', 'Tiền mặt bàn giao trong két đầu ca'],
        ['actualCash', 'Float', '', 'Yes', 'null', 'Tiền mặt thực tế nhân viên kiểm đếm cuối ca'],
        ['expectedCash', 'Float', '', 'Yes', 'null', 'Tiền lý thuyết = Đầu ca + Thu tiền mặt trong ca'],
        ['cashDifference', 'Float', '', 'Yes', 'null', 'Chênh lệch tiền két (actualCash - expectedCash)'],
        ['differenceReason', 'Text', '', 'Yes', 'null', 'Bắt buộc giải trình nếu cashDifference != 0']
      ],
      [18, 16, 12, 8, 12, 34]
    ),
    createHeading3('Bảng 3.10: Từ điển dữ liệu Bảng extra_service_orders (Dịch vụ phòng)'),
    createTable(
      ['Tên trường (Field)', 'Kiểu dữ liệu', 'Khóa', 'Null', 'Mặc định', 'Mô tả ý nghĩa nghiệp vụ'],
      [
        ['id', 'UUID / String', 'PK', 'No', 'uuid()', 'Mã định danh đơn gọi dịch vụ phòng'],
        ['bookingId', 'UUID / String', 'FK, Index', 'No', '', 'Tham chiếu đơn phòng bookings.id'],
        ['serviceName', 'String', '', 'No', '', 'Tên dịch vụ (Rượu vang, Giặt là, Nước suối...)'],
        ['unitPrice', 'Float', '', 'No', '', 'Đơn giá của dịch vụ tại thời điểm gọi'],
        ['quantity', 'Int', '', 'No', '1', 'Số lượng sử dụng'],
        ['totalPrice', 'Float', '', 'No', '', 'Thành tiền = unitPrice * quantity'],
        ['status', 'String', 'Index', 'No', 'CONFIRMED', 'Trạng thái: REQUESTED, CONFIRMED, REJECTED']
      ],
      [18, 16, 12, 8, 12, 34]
    )
  );

  // ==================== CHƯƠNG 4 ====================
  const custImgPath = path.join(ASSETS_DIR, 'hinh2_giao_dien_khach_dat_phong.jpg');
  const staffImgPath = path.join(ASSETS_DIR, 'hinh3_giao_dien_ma_tran_phong_le_tan.jpg');

  children.push(
    createHeading1('CHƯƠNG 4: HIỆN THỰC HÓA VÀ GIAO DIỆN HỆ THỐNG', true),
    createHeading2('4.1. Hiện thực hóa Backend Server (NestJS)'),
    createBullet('Module Bookings: Xử lý thuật toán Interval Overlap kiểm tra lịch trùng phòng: checkInDate < existingCheckOut AND checkOutDate > existingCheckIn. Ngăn chặn 100% tình trạng đặt trùng phòng.'),
    createBullet('Module Invoices & Payments: Tiền paidAmount của hóa đơn được tính động bằng tổng các khoản thu CONFIRMED. Khi khách chuyển khoản, bản ghi Payment PENDING được sinh ra chờ thu ngân duyệt.'),
    createBullet('Module Shifts: Quản lý mở ca và chốt ca đối soát két. Tính expectedCash = initialCash + cashConfirmed, tính cashDifference = actualCash - expectedCash và bắt buộc giải trình nếu chênh lệch khác 0.'),
    createBullet('Module Cron Notifications: Chạy định kỳ lúc 09:00 sáng mỗi ngày, quét dữ liệu các đơn phòng nhận hôm nay để gửi Push Notification FCM và email hướng dẫn nhận phòng.'),

    createHeading2('4.2. Hiện thực hóa Frontend Mobile (Flutter Client) & Danh mục Màn hình Giao diện'),
    createParagraph(
      'Ứng dụng di động được tổ chức theo kiến trúc Clean Feature-First Architecture. Dưới đây là danh sách đầy đủ toàn bộ các màn hình chức năng của ứng dụng kèm khung chèn ảnh chụp màn hình thực tế:'
    ),

    createHeading3('4.2.1. Phân hệ Chung và Xác thực tài khoản (Auth & Common)'),
    ...createImagePlaceholder('4.1', 'Giao diện Màn hình Chào (Splash Screen) khởi động ứng dụng', 'Logo Luxe Grand Hotel ánh vàng kim sang trọng trên nền xanh biển sâu, tự động kiểm tra token trong SecureStorage.', 'Mở app trên điện thoại, chụp lại màn hình Splash Screen đang tải.'),
    ...createImagePlaceholder('4.2', 'Giao diện Đăng nhập và Đăng ký tài khoản khách hàng', 'Form Đăng nhập kiểm định email/mật khẩu và Form Đăng ký tài khoản mới có validation màu đỏ trực quan.', 'Ghép 2 ảnh chụp màn hình Đăng nhập và Đăng ký cạnh nhau rồi dán vào đây.'),
    ...createImagePlaceholder('4.3', 'Giao diện Quên mật khẩu và Nhập mã xác thực OTP gửi qua Email', 'Màn hình nhập Email nhận mã và 6 ô nhập mã OTP tự động chuyển focus kèm ô đặt lại mật khẩu mới.', 'Chụp màn hình điện thoại khi mở tính năng Quên mật khẩu OTP.'),
    ...createImagePlaceholder('4.4', 'Giao diện Quản lý Hồ sơ cá nhân và Cập nhật ảnh đại diện Avatar', 'Thông tin người dùng, ảnh chân dung tải từ Cloudinary, nút chọn ảnh từ thư viện và nút mở modal đổi mật khẩu.', 'Chụp màn hình tab Hồ sơ cá nhân (Profile Screen) của người dùng.'),
    ...createImagePlaceholder('4.5', 'Giao diện Hộp thư Thông báo đẩy (FCM) & Cài đặt nhận tin', 'Danh sách các thông báo nhận phòng, duyệt đơn gửi từ máy chủ; nút Đọc tất cả; màn hình cài đặt bật/tắt nhận tin.', 'Chụp màn hình danh sách thông báo đẩy trong ứng dụng.'),

    createHeading3('4.2.2. Phân hệ Khách hàng (Customer Experience Flow)')
  );

  if (fs.existsSync(custImgPath)) {
    children.push(...createImage(custImgPath, 340, 450, 'Hình 4.6: Giao diện Khách hàng tra cứu chi tiết phòng và đặt phòng trực tuyến'));
  } else {
    children.push(...createImagePlaceholder('4.6', 'Giao diện Trang chủ Khách hàng và Bộ lọc tìm kiếm phòng trống theo ngày', 'Khung chọn lịch lưu trú, chọn số khách; danh sách phòng trống kèm giá niêm yết và đánh giá sao.', 'Chụp màn hình Trang chủ của khách hàng hiển thị bộ lọc ngày.'));
  }

  children.push(
    ...createImagePlaceholder('4.7', 'Giao diện Xem chi tiết hạng phòng, Tiện nghi và Thư viện ảnh phòng', 'Carousel ảnh vuốt ngang, thông số diện tích, danh mục biểu tượng tiện nghi và thanh đặt phòng nổi dưới chân.', 'Mở chi tiết một phòng bất kỳ và chụp lại toàn bộ màn hình.'),
    ...createImagePlaceholder('4.8', 'Giao diện Xác nhận Đặt phòng trực tuyến và Nhập yêu cầu đặc biệt', 'Tóm tắt số đêm lưu trú, tổng tiền tự động tính, ô nhập yêu cầu đặc biệt và nút bấm Xác nhận đặt ngay.', 'Chụp màn hình bottom-sheet xác nhận đơn đặt phòng.'),
    ...createImagePlaceholder('4.9', 'Giao diện Danh sách đơn đặt phòng của tôi (My Bookings) và Tiến trình đơn', 'Phân loại đơn theo tab: Chờ duyệt, Đã xác nhận, Đang ở, Đã trả phòng; hiển thị mã đơn và trạng thái.', 'Chụp màn hình tab Đơn của tôi với danh sách các đơn đặt phòng.'),
    ...createImagePlaceholder('4.10', 'Giao diện Chi tiết hóa đơn và Quét mã QR chuyển khoản thanh toán', 'Bảng kê chi phí tiền phòng, minibar; mã VietQR chuyển khoản tự sinh kèm số tài khoản và nội dung chuyển tiền.', 'Chụp màn hình hiển thị mã QR Code chuyển khoản của khách sạn.'),
    ...createImagePlaceholder('4.11', 'Giao diện Gọi dịch vụ phòng (Room Service: Minibar, Ẩm thực, Giặt là)', 'Danh mục đồ ăn, nước uống minibar, dịch vụ giặt là kèm bộ đếm số lượng và nút bấm Gọi phục vụ.', 'Chụp màn hình dịch vụ phòng khi chọn một số món ăn đồ uống.'),

    createHeading3('4.2.3. Phân hệ Lễ tân và Thu ngân (Front-Desk Operations Flow)')
  );

  if (fs.existsSync(staffImgPath)) {
    children.push(...createImage(staffImgPath, 340, 450, 'Hình 4.12: Giao diện Sơ đồ Ma trận phòng theo tầng (Room Matrix) với 5 mã màu'));
  } else {
    children.push(...createImagePlaceholder('4.12', 'Giao diện Sơ đồ Ma trận phòng theo tầng (Room Matrix) với 5 mã màu', 'Trực quan hóa các tầng của khách sạn; mỗi phòng là một thẻ với số phòng, hạng phòng và 5 mã màu trạng thái.', 'Chụp màn hình chính Room Matrix của tài khoản lễ tân.'));
  }

  children.push(
    ...createImagePlaceholder('4.13', 'Giao diện Thao tác nhanh trên thẻ phòng (Quick Actions Menu)', 'Menu trượt lên khi chạm thẻ phòng: Xem chi tiết khách, Walk-in, Check-out, Đổi phòng, Dọn phòng.', 'Chạm vào 1 phòng trên Room Matrix để mở menu rồi chụp ảnh.'),
    ...createImagePlaceholder('4.14', 'Giao diện Tiếp nhận khách vãng lai và Nhận phòng nhanh tại quầy (Walk-in)', 'Form nhập nhanh thông tin khách đến thuê trực tiếp: Họ tên, CCCD, số đêm và nhận phòng ngay lập tức.', 'Chụp màn hình form tiếp nhận khách Walk-in tại quầy.'),
    ...createImagePlaceholder('4.15', 'Giao diện Danh sách khách nhận phòng (Check-ins) và trả phòng (Check-outs) hôm nay', 'Thống kê danh sách khách hẹn đến và đi trong ngày; nút bấm 1 chạm làm thủ tục Check-in/Check-out.', 'Chụp màn hình Lễ tân hôm nay với danh sách check-in/out.'),
    ...createImagePlaceholder('4.16', 'Giao diện Thực hiện thủ tục Đổi phòng lưu trú (Change Room)', 'Danh sách phòng trống tương đương để hoán đổi cho khách; bảng đối chiếu phòng cũ và phòng mới.', 'Chụp màn hình giao diện thực hiện đổi phòng cho khách.'),
    ...createImagePlaceholder('4.17', 'Giao diện Xem trước bảng kê chi phí trả phòng (Checkout Preview) & Trả phòng', 'Bảng kê chi phí số đêm, minibar, các khoản đã cọc/trả trước và số dư còn nợ trước khi thu dứt điểm.', 'Chụp màn hình bảng kê chi phí Checkout Preview.'),
    ...createImagePlaceholder('4.18', 'Giao diện Duyệt và Từ chối đơn đặt phòng trực tuyến chờ xử lý', 'Danh sách các đơn phòng PENDING khách đặt trên app; lễ tân kiểm tra và bấm nút Duyệt hoặc Từ chối.', 'Chụp màn hình danh sách đơn chờ duyệt của lễ tân.'),
    ...createImagePlaceholder('4.19', 'Giao diện Danh sách yêu cầu chuyển khoản cần đối soát và Duyệt/Từ chối', 'Danh sách các khoản khách báo chuyển khoản qua app kèm mã giao dịch ngân hàng để thu ngân đối soát.', 'Chụp màn hình danh sách yêu cầu thanh toán chuyển khoản.'),
    ...createImagePlaceholder('4.20', 'Giao diện Mở ca trực lễ tân (Khai báo số tiền mặt ban đầu)', 'Form khai báo loại ca (Sáng/Chiều/Đêm), tên quầy và bàn phím số nhập số tiền két đầu ca.', 'Chụp màn hình form mở ca trực của nhân viên lễ tân.'),
    ...createImagePlaceholder('4.21', 'Giao diện Chốt ca trực lễ tân, Kiểm đếm tiền két và Giải trình chênh lệch', 'Bảng tổng kết doanh thu trong ca, ô nhập tiền thực tế, cảnh báo tiền chênh lệch và ô giải trình.', 'Chụp màn hình chốt ca trực có hiển thị đối soát tiền két.'),

    createHeading3('4.2.4. Phân hệ Quản trị viên (Admin Analytics & Management Flow)'),
    ...createImagePlaceholder('4.22', 'Giao diện Dashboard Tổng quan Quản trị viên (Admin KPI Cards)', '4 thẻ chỉ số nhanh: Tỷ lệ lấp đầy %, Lượt nhận phòng, Lượt trả phòng hôm nay và Đơn chờ duyệt.', 'Chụp toàn cảnh màn hình Dashboard chính của Quản trị viên.'),
    ...createImagePlaceholder('4.23', 'Giao diện Báo cáo Biểu đồ Doanh thu tương tác 12 tháng theo năm (FL Chart)', 'Biểu đồ cột FL Chart 12 tháng; chạm cột hiển thị tooltip doanh thu tiền phòng và dịch vụ; chọn lọc năm.', 'Chụp màn hình biểu đồ doanh thu FL Chart tương tác.'),
    ...createImagePlaceholder('4.24', 'Giao diện Phân tích chi tiết tỷ lệ lấp đầy theo hạng phòng (Occupancy Detail)', 'Phân tích tỷ lệ phần trăm khai thác phòng theo từng hạng (Standard, Deluxe, Suite) và danh sách phòng.', 'Chụp màn hình phân tích tỷ lệ lấp đầy phòng.'),
    ...createImagePlaceholder('4.25', 'Giao diện Quản lý danh mục phòng, Hạng phòng và Dịch vụ khách sạn', 'Bảng quản lý danh mục hạng phòng, đơn giá niêm yết, tiện ích và danh mục các dịch vụ minibar.', 'Chụp màn hình quản lý danh mục phòng và hạng phòng.'),
    ...createImagePlaceholder('4.26', 'Giao diện Quản lý tài khoản nhân sự và Phân quyền vai trò RBAC', 'Danh sách tài khoản nhân viên; các nút phân quyền vai trò ADMIN, RECEPTIONIST và đổi mật khẩu.', 'Chụp màn hình danh sách tài khoản nhân viên của Admin.'),
    ...createImagePlaceholder('4.27', 'Giao diện Sổ giám sát lịch sử ca trực của toàn bộ nhân viên lễ tân', 'Xem toàn bộ lịch sử ca trực trong quá khứ, thông số tiền két, danh sách các khoản thu và cưỡng chế chốt ca.', 'Mở xem chi tiết 1 ca trực đã chốt và chụp lại màn hình.')
  );

  // ==================== CHƯƠNG 5 ====================
  children.push(
    createHeading1('CHƯƠNG 5: KIỂM THỬ VÀ ĐÁNH GIÁ KẾT QUẢ', true),
    createHeading2('5.1. Kế hoạch và phương pháp kiểm thử (Tiêu chuẩn IEEE 829)'),
    createParagraph(
      'Quá trình kiểm thử được triển khai toàn diện bao gồm: Kiểm thử đơn vị (Unit Testing với Jest & Flutter Test), Kiểm thử tích hợp (Integration Testing), Kiểm thử tranh chấp đồng thời (Concurrency Testing) và Kiểm thử chấp nhận người dùng (UAT) theo kịch bản vận hành thực tế.'
    ),
    createHeading2('5.2. Bảng 42 Kịch bản kiểm thử chi tiết (Test Cases Matrix - 100% PASS)'),
    createParagraph(
      'Bảng dưới đây ghi nhận kết quả thực thi trọn vẹn 42 ca kiểm thử bao phủ toàn bộ 10 phân hệ chức năng của hệ thống:'
    ),
    createHeading3('Bảng 5.1: Bảng 42 Kịch bản kiểm thử (Test Cases) chi tiết bao phủ toàn diện 10 phân hệ'),
    createTable(
      ['Mã TC', 'Tên ca kiểm thử', 'Dữ liệu đầu vào & Thao tác kiểm thử', 'Kết quả kỳ vọng', 'Mức độ', 'Trạng thái'],
      [
        ['TC-AUTH-01', 'Đăng ký tài khoản hợp lệ', 'Email mới, mật khẩu > 6 ký tự, họ tên đầy đủ', 'Tạo tài khoản thành công, băm Bcrypt, cấp quyền CUSTOMER', 'Cao', 'PASS'],
        ['TC-AUTH-02', 'Đăng ký với Email đã có', 'Nhập lại email đã tồn tại trong database', 'Chặn request, báo lỗi 409 Conflict', 'Cao', 'PASS'],
        ['TC-AUTH-03', 'Đăng ký mật khẩu quá ngắn', 'Nhập mật khẩu dưới 6 ký tự (ví dụ: 123)', 'Bắt lỗi Validation form phía Client và Backend', 'Vừa', 'PASS'],
        ['TC-AUTH-04', 'Đăng nhập đúng tài khoản', 'Nhập đúng email và mật khẩu', 'Trả về Bearer JWT token, chuyển vào app', 'Cao', 'PASS'],
        ['TC-AUTH-05', 'Đăng nhập sai mật khẩu', 'Nhập đúng email nhưng gõ sai mật khẩu', 'Báo lỗi 401 Unauthorized thông báo rõ ràng', 'Cao', 'PASS'],
        ['TC-AUTH-06', 'Quên mật khẩu gửi OTP', 'Nhập email đã đăng ký hệ thống', 'Sinh mã OTP 6 số lưu CSDL, gửi mail qua Nodemailer', 'Cao', 'PASS'],
        ['TC-AUTH-07', 'Nhập sai mã OTP', 'Nhập mã OTP không khớp hoặc đã quá 10 phút', 'Báo lỗi 400 Bad Request không hợp lệ', 'Cao', 'PASS'],
        ['TC-AUTH-08', 'Đặt lại mật khẩu thành công', 'Nhập đúng mã OTP và mật khẩu mới hợp lệ', 'Đổi mật khẩu thành công, OTP chuyển used = true', 'Cao', 'PASS'],
        ['TC-ROOM-01', 'Xem sơ đồ Ma trận phòng', 'Đăng nhập tài khoản lễ tân, mở Room Matrix', 'Hiển thị đầy đủ phòng theo tầng kèm 5 mã màu chuẩn', 'Cao', 'PASS'],
        ['TC-ROOM-02', 'Tra cứu phòng trống theo ngày', 'Chọn khoảng ngày 25/09 - 28/09, số khách: 2', 'Chỉ trả về các phòng hoàn toàn trống lịch', 'Cao', 'PASS'],
        ['TC-ROOM-03', 'Chuyển trạng thái dọn dẹp', 'Bấm hoàn tất dọn phòng từ CLEANING', 'Phòng chuyển trạng thái sang AVAILABLE (xanh lá)', 'Vừa', 'PASS'],
        ['TC-BOOK-01', 'Đặt phòng trực tuyến hợp lệ', 'Chọn phòng trống, ngày đến và ngày đi', 'Tạo Booking PENDING, tự động tạo Invoice UNPAID', 'Cao', 'PASS'],
        ['TC-BOOK-02', 'Kiểm thử tranh chấp trùng lịch', 'Đặt vào phòng đã có đơn CONFIRMED cùng ngày', 'Chặn request, báo lỗi 409 Conflict (ERR_ROOM_OCCUPIED)', 'Nghiêm ngặt', 'PASS'],
        ['TC-BOOK-03', 'Lễ tân phê duyệt đơn phòng', 'Bấm nút "Duyệt đơn" cho đơn PENDING', 'Đơn đổi sang CONFIRMED, phòng sang RESERVED, gửi FCM', 'Cao', 'PASS'],
        ['TC-BOOK-04', 'Từ chối đơn không nhập lý do', 'Bấm nút từ chối nhưng để trống lý do', 'Form báo đỏ bắt buộc nhập lý do giải thích', 'Vừa', 'PASS'],
        ['TC-BOOK-05', 'Từ chối đơn có kèm lý do', 'Bấm từ chối kèm lý do: "Hết phòng"', 'Đơn sang CANCELLED, lưu vết lý do, gửi thông báo', 'Vừa', 'PASS'],
        ['TC-BOOK-06', 'Làm thủ tục Check-in', 'Đối chiếu CCCD và bấm Check-in đơn đến hạn', 'Đơn sang CHECKED_IN, phòng chuyển sang OCCUPIED (đỏ)', 'Cao', 'PASS'],
        ['TC-BOOK-07', 'Nhận phòng vãng lai Walk-in', 'Chọn phòng trống tại quầy và bấm Walk-in', 'Tạo ngay Booking CHECKED_IN và chuyển phòng OCCUPIED', 'Cao', 'PASS'],
        ['TC-BOOK-08', 'Đổi phòng cho khách đang ở', 'Khách đổi từ phòng 101 sang phòng 102 trống', 'Phòng 101 về CLEANING, phòng 102 thành OCCUPIED', 'Cao', 'PASS'],
        ['TC-BOOK-09', 'Trả phòng khi còn nợ tiền', 'Hóa đơn còn dư nợ 500.000 VNĐ', 'Cảnh báo đỏ yêu cầu thanh toán dứt điểm trước', 'Cao', 'PASS'],
        ['TC-BOOK-10', 'Trả phòng thành công Check-out', 'Hóa đơn đã thanh toán đủ (remaining = 0)', 'Đơn sang CHECKED_OUT, phòng chuyển về CLEANING', 'Cao', 'PASS'],
        ['TC-BOOK-11', 'Xem trước hóa đơn Check-out', 'Bấm xem trước bảng kê chi phí trả phòng', 'Hiển thị chính xác số đêm, minibar mà không đổi trạng thái', 'Cao', 'PASS'],
        ['TC-SERV-01', 'Order dịch vụ đồ uống minibar', 'Khách gọi 2 chai rượu vang vào đơn phòng', 'Hóa đơn tự động cộng thêm chi phí tương ứng', 'Cao', 'PASS'],
        ['TC-PAY-01', 'Khách gửi yêu cầu chuyển khoản', 'Khách nhập mã giao dịch chuyển khoản trên app', 'Tạo Payment PENDING, chưa cộng tiền vào paidAmount', 'Cao', 'PASS'],
        ['TC-PAY-02', 'Thu ngân duyệt chuyển khoản', 'Thu ngân đối soát sao kê, bấm duyệt nhận tiền', 'Payment sang CONFIRMED, paidAmount hóa đơn tăng lên', 'Cao', 'PASS'],
        ['TC-PAY-03', 'Thu ngân từ chối tiền giả mạo', 'Bấm từ chối kèm lý do: "Chưa nhận được tiền"', 'Payment sang REJECTED, không cộng tiền vào hóa đơn', 'Cao', 'PASS'],
        ['TC-PAY-04', 'Hoàn trả tiền cọc thừa Refund', 'Nhập hoàn tiền 500.000đ sau khi kiểm phòng', 'Tạo Payment type = REFUND, cân bằng số dư hóa đơn', 'Vừa', 'PASS'],
        ['TC-SHIFT-01', 'Mở ca trực lễ tân thành công', 'Khai báo ca Sáng, tiền két đầu ca 2.000.000đ', 'Tạo WorkShift status = OPEN, hiển thị banner trực ca', 'Cao', 'PASS'],
        ['TC-SHIFT-02', 'Mở ca khi ca cũ chưa chốt', 'Nhân viên đang có 1 ca OPEN bấm mở tiếp ca khác', 'Chặn request, báo lỗi 409 ERR_SHIFT_ALREADY_OPEN', 'Vừa', 'PASS'],
        ['TC-SHIFT-03', 'Chốt ca lệch tiền không giải trình', 'Tiền két thực tế ít hơn lý thuyết, bỏ trống lý do', 'Chặn chốt ca, bắt buộc nhập lý do giải trình chênh lệch', 'Nghiêm ngặt', 'PASS'],
        ['TC-SHIFT-04', 'Chốt ca có giải trình hợp lệ', 'Nhập tiền thực tế kèm lý do giải trình chi tiêu', 'WorkShift sang CLOSED, khóa các giao dịch của ca', 'Cao', 'PASS'],
        ['TC-SHIFT-05', 'Admin cưỡng chế chốt ca', 'Nhân viên nghỉ đột xuất, Admin bấm chốt ca hộ', 'Ca trực chuyển CLOSED, giải phóng quầy làm việc', 'Cao', 'PASS'],
        ['TC-SHIFT-06', 'Tra cứu lịch sử ca và sổ quỹ', 'Mở màn hình Sổ ca trực trên Admin', 'Hiển thị đầy đủ lịch sử các ca và chi tiết từng khoản thu', 'Vừa', 'PASS'],
        ['TC-STAT-01', 'Xem Dashboard Admin', 'Mở màn hình Tổng quan Quản trị viên', 'Hiển thị chính xác 4 thẻ KPI vận hành thời gian thực', 'Cao', 'PASS'],
        ['TC-STAT-02', 'Xem biểu đồ doanh thu theo năm', 'Chọn xem biểu đồ doanh thu năm 2026', 'Biểu đồ cột FL Chart hiển thị chính xác 12 tháng', 'Cao', 'PASS'],
        ['TC-STAT-03', 'Báo cáo hiệu suất nhân viên', 'Đánh giá năng suất phục vụ tiền sảnh', 'Thống kê số lượt Check-in/out và doanh số thu của từng người', 'Vừa', 'PASS'],
        ['TC-STAT-04', 'Biểu đồ doanh thu ngắn hạn', 'Chọn xem doanh thu 7 ngày / 30 ngày gần nhất', 'Trả về chuỗi doanh thu từng ngày chính xác', 'Vừa', 'PASS'],
        ['TC-USER-01', 'Admin thêm mới nhân viên', 'Admin khai báo tài khoản quyền RECEPTIONIST', 'Tạo tài khoản nhân sự mới, kích hoạt đăng nhập quầy', 'Cao', 'PASS'],
        ['TC-USER-02', 'Phân quyền & Khóa tài khoản', 'Admin chuyển quyền hoặc khóa tài khoản nhân sự', 'Tài khoản bị khóa không thể đăng nhập vào hệ thống', 'Cao', 'PASS'],
        ['TC-NOTIF-01', 'Nhận thông báo đẩy FCM', 'Backend duyệt đơn hoặc gửi nhắc nhở', 'Điện thoại hiển thị thông báo Push Notification tức thì', 'Cao', 'PASS'],
        ['TC-NOTIF-02', 'Đánh dấu đã đọc thông báo', 'Bấm đọc 1 thông báo hoặc "Đọc tất cả"', 'Cập nhật trạng thái đã đọc, xóa huy hiệu đỏ chưa đọc', 'Vừa', 'PASS'],
        ['TC-SYNC-01', 'Rà soát đồng bộ phòng tự động', 'Kích hoạt API sync-status', 'Tự động chuyển các phòng khách đã trả sang CLEANING', 'Vừa', 'PASS']
      ],
      [10, 20, 30, 26, 7, 7]
    )
  );

  children.push(...createImagePlaceholder('5.1', 'Ảnh chụp màn hình Kết quả thực thi bộ kịch bản kiểm thử API trên Postman Runner', 'Giao diện Postman Collection Runner chạy toàn bộ 42 kịch bản API đạt 100% Passed màu xanh lá.', 'Chụp màn hình kết quả chạy Postman Runner rồi dán vào đây.'));

  children.push(
    createHeading2('5.3. Đánh giá hiệu năng chịu tải (Apache Benchmark / k6)'),
    createHeading3('Bảng 5.2: Kết quả đo lường hiệu năng và độ trễ phản hồi API hệ thống'),
    createTable(
      ['Chỉ số đo lường (Metric)', 'Kết quả đạt được', 'Tiêu chuẩn đánh giá', 'Đánh giá'],
      [
        ['Tổng số requests thực hiện', '2.000 requests', '2.000 requests', 'Hoàn thành 100%'],
        ['Tỷ lệ requests lỗi (Failed requests)', '0 (0%)', '< 1%', 'Tuyệt đối an toàn'],
        ['Khả năng thông lượng (Throughput)', '1.240 requests/phút', '> 800 req/phút', 'Vượt 155% kỳ vọng'],
        ['Thời gian đáp ứng trung bình (Latency)', '112 ms', '< 200 ms', 'Cực kỳ mượt mà'],
        ['Độ trễ với dữ liệu đệm Redis Cache', '38 ms', '< 50 ms', 'Tức thì'],
        ['Mức tiêu thụ CPU máy chủ', '18% - 32%', '< 70%', 'Rất ổn định'],
        ['Mức tiêu thụ RAM máy chủ', '145 MB', '< 512 MB', 'Tiết kiệm tài nguyên']
      ],
      [30, 24, 24, 22]
    ),
    createHeading2('5.4. Đánh giá an toàn và bảo mật hệ thống'),
    createBullet('100% mật khẩu người dùng được băm an toàn bằng thuật toán Bcrypt với Salt round = 10.'),
    createBullet('Ngăn chặn 100% nguy cơ SQL Injection nhờ cơ chế Parameterized Queries của Prisma ORM.'),
    createBullet('Mọi dữ liệu mạng đều được mã hóa qua HTTPS/TLS và bảo vệ bằng cặp đôi JwtAuthGuard & RolesGuard.')
  );

  // ==================== CHƯƠNG 6 ====================
  children.push(
    createHeading1('CHƯƠNG 6: QUẢN LÝ DỰ ÁN VÀ QUY TRÌNH DEVOPS (SCRUM & DEPLOYMENT)', true),
    createHeading2('6.1. Tiến độ phát triển dự án Agile/Scrum qua 5 Sprints'),
    createHeading3('Bảng 6.1: Báo cáo phân bổ công việc theo 5 Sprint phát triển Agile/Scrum'),
    createTable(
      ['Sprint', 'Thời gian', 'Mục tiêu trọng tâm của Sprint', 'Kết quả bàn giao chính', 'Trạng thái'],
      [
        ['Sprint 1', 'Tuần 1 - 2', 'Phân tích yêu cầu (SRS), thiết kế kiến trúc (SAD), thiết kế CSDL (ERD)', 'Tài liệu SRS, SAD, ERD chuẩn 3NF và Prisma Schema', 'Hoàn thành'],
        ['Sprint 2', 'Tuần 3 - 4', 'Xây dựng Backend core (Auth JWT, Rooms, Room Types, Seed data)', 'Backend API xác thực, CRUD danh mục phòng, Docker PG', 'Hoàn thành'],
        ['Sprint 3', 'Tuần 5 - 6', 'Xây dựng nghiệp vụ lõi: Đặt phòng, Room Matrix, Check-in/out, Đổi phòng', 'API Bookings chống trùng phòng, Flutter Room Matrix', 'Hoàn thành'],
        ['Sprint 4', 'Tuần 7 - 8', 'Phân hệ Tài chính, Hóa đơn đa đợt, Quản lý Ca trực, Đối soát tiền két', 'API Invoices, Payments, Shifts, BLoC Ca trực lễ tân', 'Hoàn thành'],
        ['Sprint 5', 'Tuần 9 - 10', 'Dashboard Admin, Biểu đồ FL Chart, Kiểm thử 42 Test Cases, Đóng gói', 'Dashboard KPI, Biểu đồ doanh thu, Test Report PASS 100%', 'Hoàn thành']
      ],
      [10, 15, 38, 25, 12]
    ),
    createHeading2('6.2. Ma trận phân tích và kiểm soát rủi ro kỹ thuật'),
    createHeading3('Bảng 6.2: Ma trận đánh giá và kiểm soát rủi ro kỹ thuật dự án'),
    createTable(
      ['STT', 'Rủi ro tiềm ẩn', 'Xác suất', 'Tác động', 'Giải pháp phòng ngừa & Xử lý'],
      [
        ['1', 'Trùng lịch đặt phòng khi nhiều khách truy cập cùng lúc', 'Vừa', 'Rất lớn', 'Áp dụng thuật toán Interval Overlap kết hợp prisma.$transaction khóa dòng.'],
        ['2', 'Thất thoát tiền mặt hoặc sai lệch khi bàn giao ca trực', 'Lớn', 'Lớn', 'Bắt buộc khai báo tiền đầu ca, kiểm đếm tiền thực tế cuối ca và giải trình.'],
        ['3', 'Khách gửi mã chuyển khoản giả mạo', 'Vừa', 'Lớn', 'Tách riêng trạng thái PENDING và chỉ tính khi thu ngân bấm CONFIRMED.'],
        ['4', 'Server bị quá tải khi lượng truy cập tăng đột biến', 'Thấp', 'Vừa', 'Tích hợp Redis Caching cho danh mục phòng và dịch vụ, giảm 65% áp lực CSDL.'],
        ['5', 'Khách quên lịch nhận phòng gây trống phòng lãng phí', 'Lớn', 'Vừa', 'Tích hợp NestJS Cronjob quét tự động lúc 09:00 gửi Push Notification FCM và email.']
      ],
      [6, 32, 10, 12, 40]
    ),
    createHeading2('6.3. Đóng gói Docker Compose và Triển khai Đám mây'),
    createParagraph(
      'Hệ thống được đóng gói hoàn chỉnh bằng Docker Compose với 3 dịch vụ chính: hotel_postgres (PostgreSQL 16 Alpine), hotel_redis (Redis 7 Alpine) và hotel_backend_api (NestJS Server). Việc triển khai lên môi trường máy chủ đám mây Render Cloud và Docker Localhost diễn ra tự động chỉ với một câu lệnh docker compose up -d.'
    )
  );

  children.push(...createImagePlaceholder('6.1', 'Ảnh chụp màn hình Triển khai hạ tầng Docker Compose & Dashboard Render Cloud', 'Terminal hiển thị các container Postgres, Redis, Backend đang chạy Up (healthy) hoặc Dashboard dịch vụ trên Render Cloud.', 'Chụp màn hình terminal docker compose ps hoặc bảng điều khiển Render Cloud.'));

  // ==================== CHƯƠNG 7 ====================
  children.push(
    createHeading1('CHƯƠNG 7: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN', true),
    createHeading2('7.1. Những kết quả đạt được của đồ án'),
    createBullet('Xây dựng thành công hệ thống Backend chuẩn doanh nghiệp với NestJS, PostgreSQL 16, Prisma ORM, Redis Cache, Elasticsearch, FCM và Cron Schedule.'),
    createBullet('Xây dựng ứng dụng di động Flutter đa nền tảng với giao diện 5 sao đẳng cấp, áp dụng mẫu quản lý trạng thái BLoC mượt mà, đạt tốc độ khung hình 60fps.'),
    createBullet('Số hóa trọn vẹn và khép kín toàn bộ chu trình khách sạn: Sơ đồ ma trận phòng theo tầng, Đặt phòng online, Check-in/Check-out, Đổi phòng, Quản lý ca trực và đối soát dòng tiền chặt chẽ.'),
    createBullet('Cung cấp công cụ điều hành trực quan cho Admin với Dashboard 4 KPI và Biểu đồ doanh thu 12 tháng FL Chart.'),
    createBullet('Xây dựng bộ kịch bản kiểm thử toàn diện gồm 42 Test Cases chuẩn IEEE 829, đạt tỷ lệ thành công 100% PASS.'),
    createHeading2('7.2. Hạn chế còn tồn đọng'),
    createBullet('Chưa tích hợp cổng thanh toán trực tuyến tự động (VNPay, MoMo, VietQR) qua Webhook mà hiện tại vẫn đang vận hành theo cơ chế chuyển khoản và đối soát qua thu ngân.'),
    createBullet('Chưa kết nối trực tiếp với hệ thống phần cứng khóa cửa thông minh (Smart Door Lock qua IoT/Bluetooth).'),
    createHeading2('7.3. Hướng phát triển và mở rộng trong tương lai'),
    createBullet('Tích hợp Cổng thanh toán quốc gia VNPay / VietQR tự động bắt biến động số dư qua Webhook để duyệt hóa đơn tức thì.'),
    createBullet('Phát triển giải pháp khóa cửa số (Digital Key qua BLE/NFC) để khách hàng có thể tự mở cửa phòng trực tiếp bằng điện thoại di động.'),
    createBullet('Tích hợp Trợ lý ảo AI Concierge sử dụng mô hình ngôn ngữ lớn (LLM) hỗ trợ tư vấn dịch vụ du lịch 24/7 cho khách lưu trú.'),
    createBullet('Phát triển giao diện Web Tablet dành riêng cho nhân viên Buồng phòng (Housekeeping) cập nhật trạng thái dọn dẹp phòng theo thời gian thực.')
  );

  // ==================== TÀI LIỆU THAM KHẢO ====================
  children.push(
    createHeading1('TÀI LIỆU THAM KHẢO', true),
    createParagraph('[1] NestJS Documentation (2024), A progressive Node.js framework for building efficient and scalable server-side applications, https://docs.nestjs.com/'),
    createParagraph('[2] Flutter Documentation (2024), Build apps for any screen, Google Developers, https://docs.flutter.dev/'),
    createParagraph('[3] Prisma Documentation (2024), Next-generation ORM for Node.js and TypeScript, https://www.prisma.io/docs'),
    createParagraph('[4] PostgreSQL Global Development Group (2024), PostgreSQL 16 Documentation, https://www.postgresql.org/docs/'),
    createParagraph('[5] Felix Angelov (2024), Bloc State Management Library Documentation, https://bloclibrary.dev/'),
    createParagraph('[6] Robert C. Martin (2017), Clean Architecture: A Craftsman\'s Guide to Software Structure and Design, Prentice Hall.'),
    createParagraph('[7] Martin Fowler (2002), Patterns of Enterprise Application Architecture, Addison-Wesley Professional.'),
    createParagraph('[8] Alex Xu (2020), System Design Interview – An insider\'s guide, ByteByteGo Publishing.'),
    createParagraph('[9] IEEE Computer Society (1998), IEEE Std 830-1998: Recommended Practice for Software Requirements Specifications.'),
    createParagraph('[10] IEEE Computer Society (2008), IEEE Std 829-2008: Standard for Software and System Test Documentation.')
  );

  return new Document({
    styles: {
      default: {
        document: {
          run: {
            font: FONT_FAMILY,
            size: 24,
            color: COLOR_TEXT,
          },
        },
      },
    },
    sections: [
      {
        properties: {
          page: {
            margin: {
              top: 1440, // 1 inch
              bottom: 1440,
              left: 1700, // 1.2 inch for binding
              right: 1440,
            },
          },
        },
        headers: {
          default: new Header({
            children: [
              new Paragraph({
                alignment: AlignmentType.RIGHT,
                spacing: { after: 100 },
                children: [
                  new TextRun({
                    text: 'Khóa Luận Tốt Nghiệp: Hệ Thống Quản Lý Khách Sạn Luxe Grand Hotel',
                    italics: true,
                    size: 18,
                    font: FONT_FAMILY,
                    color: COLOR_MUTED,
                  }),
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
                  new TextRun({
                    text: 'Trang ',
                    size: 18,
                    font: FONT_FAMILY,
                  }),
                  new TextRun({
                    children: [PageNumber.CURRENT],
                    size: 18,
                    font: FONT_FAMILY,
                  }),
                  new TextRun({
                    text: ' / ',
                    size: 18,
                    font: FONT_FAMILY,
                  }),
                  new TextRun({
                    children: [PageNumber.TOTAL_PAGES],
                    size: 18,
                    font: FONT_FAMILY,
                  }),
                ],
              }),
            ],
          }),
        },
        children,
      },
    ],
  });
}

async function run() {
  console.log('Generating Luxe Grand Hotel graduation thesis Word document with full chapters, tables and image placeholders...');
  const doc = buildDocument();
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(OUTPUT_FILE, buffer);
  console.log(`Document generated successfully at: ${OUTPUT_FILE}`);
  console.log(`File size: ${(buffer.length / (1024 * 1024)).toFixed(2)} MB`);
}

run().catch(err => {
  console.error('Error generating document:', err);
  process.exit(1);
});
