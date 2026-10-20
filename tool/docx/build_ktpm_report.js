// Sinh báo cáo bài tập lớn "Kiến trúc & Thiết kế phần mềm" (RESTful API) cho Luxe Grand Hotel.
// Chạy: node tool/docx/build_ktpm_report.js
// Ảnh sơ đồ lấy từ docs/uml_diagrams (sinh bởi tool/uml/build.js).
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
  ShadingType,
  ImageRun,
  Header,
  Footer,
  PageNumber,
  LevelFormat,
  TableOfContents,
  VerticalAlign,
  TableLayoutType,
  PageOrientation,
} = require('docx');
const { ENDPOINT_GROUPS } = require('./ktpm_endpoints');
const { TEST_GROUPS } = require('./ktpm_test_cases');

const ROOT_DIR = path.resolve(__dirname, '../../');
const DIAGRAMS_DIR = path.join(ROOT_DIR, 'docs/uml_diagrams');
const UIUX_DIR = path.join(ROOT_DIR, 'docs/bai_tap_lon_ktpm/hinh');
// Kết quả chạy thật của run_api_tests.js; thiếu file thì báo cáo vẫn sinh được với cột kết quả để trống
const TEST_RESULTS_FILE = path.join(ROOT_DIR, 'docs/bai_tap_lon_ktpm/ket_qua_kiem_thu_api.json');
const TEST_RUN = fs.existsSync(TEST_RESULTS_FILE) ? JSON.parse(fs.readFileSync(TEST_RESULTS_FILE, 'utf8')) : null;
const resultOf = (id) => TEST_RUN?.results.find((r) => r.id === id);

function formatRunTime(iso) {
  const d = new Date(new Date(iso).getTime() + 7 * 3600 * 1000); // giờ Việt Nam
  const p = (n) => String(n).padStart(2, '0');
  return `${p(d.getUTCHours())}:${p(d.getUTCMinutes())} ngày ${p(d.getUTCDate())}/${p(d.getUTCMonth() + 1)}/${d.getUTCFullYear()}`;
}

// Lấy một phần object theo danh sách khóa (khóa lồng dạng 'room.roomType.name')
function pick(obj, keys) {
  const out = {};
  for (const key of keys) {
    const parts = key.split('.');
    let src = obj;
    let dst = out;
    for (let i = 0; i < parts.length; i++) {
      if (src == null || !(parts[i] in src)) break;
      if (i === parts.length - 1) dst[parts[i]] = src[parts[i]];
      else {
        dst[parts[i]] = dst[parts[i]] || {};
        dst = dst[parts[i]];
        src = src[parts[i]];
      }
    }
  }
  return out;
}

function httpLine(status) {
  const text = { 200: 'OK', 201: 'Created', 400: 'Bad Request', 401: 'Unauthorized', 403: 'Forbidden', 404: 'Not Found', 409: 'Conflict' };
  return `HTTP/1.1 ${status} ${text[status] || ''}`.trim();
}
const OUTPUT_FILE = path.join(ROOT_DIR, 'Bao_Cao_BTL_KTTKPM_RESTful_API_Luxe_Grand_Hotel.docx');

const FONT = 'Times New Roman';
const MONO = 'Consolas';
const NAVY = '1B365D';
const GOLD = 'B8860B';
const BODY_SIZE = 26; // 13pt
// A4, lề trái 3 cm, phải 2 cm, trên/dưới 2 cm
const PAGE = { width: 11906, height: 16838 };
const MARGIN = { top: 1134, bottom: 1134, left: 1701, right: 1134 };
const CONTENT_WIDTH = PAGE.width - MARGIN.left - MARGIN.right; // 9071 DXA
const CONTENT_PX = 600;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Hỗ trợ **đậm** và `mã` trong một đoạn văn
function runs(text, base = {}) {
  return text
    .split(/(\*\*[^*]+\*\*|`[^`]+`)/)
    .filter(Boolean)
    .map((part) => {
      if (part.startsWith('**')) return new TextRun({ text: part.slice(2, -2), bold: true, font: FONT, size: BODY_SIZE, ...base });
      if (part.startsWith('`')) return new TextRun({ text: part.slice(1, -1), font: MONO, size: BODY_SIZE - 4, color: '8B1A1A', ...base });
      return new TextRun({ text: part, font: FONT, size: BODY_SIZE, ...base });
    });
}

function P(text, opts = {}) {
  return new Paragraph({
    alignment: opts.align || AlignmentType.JUSTIFIED,
    spacing: { after: opts.after ?? 100, line: 312 },
    indent: opts.noIndent ? undefined : { firstLine: 567 },
    children: runs(text, opts.run || {}),
  });
}

function B(text, level = 0) {
  return new Paragraph({
    numbering: { reference: 'bullets', level },
    alignment: AlignmentType.JUSTIFIED,
    spacing: { after: 60, line: 300 },
    children: runs(text),
  });
}

// Mỗi danh sách đánh số dùng một instance riêng để số thứ tự bắt đầu lại từ 1
let stepInstance = 0;
function steps(items) {
  stepInstance += 1;
  return items.map(
    (text) =>
      new Paragraph({
        numbering: { reference: 'steps', level: 0, instance: stepInstance },
        alignment: AlignmentType.JUSTIFIED,
        spacing: { after: 60, line: 300 },
        children: runs(text),
      }),
  );
}

function H1(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_1, pageBreakBefore: true, children: [new TextRun(text)] });
}
function H2(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(text)] });
}
function H3(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_3, children: [new TextRun(text)] });
}

function unnumberedTitle(text) {
  return new Paragraph({
    pageBreakBefore: true,
    alignment: AlignmentType.CENTER,
    spacing: { after: 240 },
    children: [new TextRun({ text, bold: true, font: FONT, size: 30, color: NAVY })],
  });
}

const cellBorders = {
  top: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  bottom: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  left: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
  right: { style: BorderStyle.SINGLE, size: 4, color: '9AA5B1' },
};

// widths: tỷ lệ tương đối, được quy đổi về CONTENT_WIDTH
function T(headers, rows, widths, opts = {}) {
  const total = widths.reduce((a, b) => a + b, 0);
  const cols = widths.map((w) => Math.floor((w / total) * CONTENT_WIDTH));
  cols[cols.length - 1] += CONTENT_WIDTH - cols.reduce((a, b) => a + b, 0);
  const size = opts.size || 22;

  const cell = (text, i, header, fill) =>
    new TableCell({
      width: { size: cols[i], type: WidthType.DXA },
      borders: cellBorders,
      verticalAlign: VerticalAlign.CENTER,
      shading: fill ? { type: ShadingType.CLEAR, color: 'auto', fill } : undefined,
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: String(text)
        .split('\n')
        .map(
          (line) =>
            new Paragraph({
              alignment: header || (opts.center || []).includes(i) ? AlignmentType.CENTER : AlignmentType.LEFT,
              spacing: { after: 0, line: 264 },
              children: header
                ? [new TextRun({ text: line, bold: true, color: 'FFFFFF', font: FONT, size })]
                : runs(line, { size, ...((opts.mono || []).includes(i) ? { font: MONO, size: size - 2 } : {}) }),
            }),
        ),
    });

  // Dòng nhóm: một ô trải hết bề ngang bảng
  const groupCell = (text) =>
    new TableCell({
      columnSpan: headers.length,
      width: { size: CONTENT_WIDTH, type: WidthType.DXA },
      borders: cellBorders,
      shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'E8EEF5' },
      margins: { top: 60, bottom: 60, left: 100, right: 100 },
      children: [new Paragraph({ keepNext: true, spacing: { after: 0 }, children: [new TextRun({ text, bold: true, font: FONT, size, color: NAVY })] })],
    });

  return new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: cols,
    layout: TableLayoutType.FIXED,
    rows: [
      new TableRow({ tableHeader: true, children: headers.map((h, i) => cell(h, i, true, NAVY)) }),
      ...rows.map(
        (r, ri) =>
          new TableRow({
            cantSplit: true,
            children: r.groupRow ? [groupCell(r[0])] : r.map((c, i) => cell(c, i, false, ri % 2 ? 'F7F9FB' : undefined)),
          }),
      ),
    ],
  });
}

const counters = { fig: {}, tab: {} };
function nextNo(kind, chapter) {
  counters[kind][chapter] = (counters[kind][chapter] || 0) + 1;
  return `${chapter}.${counters[kind][chapter]}`;
}
const figureList = [];
const tableList = [];

function caption(text) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { before: 60, after: 200 },
    children: [new TextRun({ text, italics: true, bold: true, font: FONT, size: 22, color: '333333' })],
  });
}

function tableWithCaption(chapter, title, ...args) {
  const no = nextNo('tab', chapter);
  tableList.push(`Bảng ${no}. ${title}`);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      keepNext: true,
      spacing: { before: 160, after: 80 },
      children: [new TextRun({ text: `Bảng ${no}. ${title}`, italics: true, bold: true, font: FONT, size: 22 })],
    }),
    T(...args),
    new Paragraph({ spacing: { after: 120 }, children: [] }),
  ];
}

function pngSize(file) {
  const buf = fs.readFileSync(file);
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20), buf };
}

// Dấu ngắt section: main() tách thân tài liệu thành các section dọc/ngang tại đây
const LANDSCAPE_START = { section: 'landscape' };
const LANDSCAPE_END = { section: 'portrait' };

function figure(chapter, file, title, maxHeight = 820) {
  return buildFigure(chapter, path.join(DIAGRAMS_DIR, file), title, CONTENT_PX, maxHeight);
}

// Sơ đồ khổ rộng, chỉ dùng bên trong khối trang ngang (LANDSCAPE_START … LANDSCAPE_END)
function wideFigure(chapter, file, title, maxHeight = 410) {
  return buildFigure(chapter, path.join(DIAGRAMS_DIR, file), title, 920, maxHeight);
}

// Hình lấy từ báo cáo UI/UX (User Flow, ảnh màn hình) – sinh bởi prepare_uiux_figures.ps1
function uiFigure(chapter, file, title, maxHeight = 820, maxWidth = CONTENT_PX) {
  return buildFigure(chapter, path.join(UIUX_DIR, file), title, maxWidth, maxHeight);
}

function buildFigure(chapter, filePath, title, maxWidth, maxHeight) {
  const { width, height, buf } = pngSize(filePath);
  let w = maxWidth;
  let h = Math.round((height / width) * w);
  if (h > maxHeight) {
    h = maxHeight;
    w = Math.round((width / height) * h);
  }
  const no = nextNo('fig', chapter);
  figureList.push(`Hình ${no}. ${title}`);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      keepNext: true,
      spacing: { before: 120, after: 40 },
      children: [new ImageRun({ type: 'png', data: buf, transformation: { width: w, height: h } })],
    }),
    caption(`Hình ${no}. ${title}`),
  ];
}

function placeholderFigure(chapter, title, hint) {
  const no = nextNo('fig', chapter);
  figureList.push(`Hình ${no}. ${title}`);
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 40 },
      border: {
        top: { style: BorderStyle.DASHED, size: 8, color: '9AA5B1', space: 40 },
        bottom: { style: BorderStyle.DASHED, size: 8, color: '9AA5B1', space: 40 },
        left: { style: BorderStyle.DASHED, size: 8, color: '9AA5B1', space: 40 },
        right: { style: BorderStyle.DASHED, size: 8, color: '9AA5B1', space: 40 },
      },
      children: [new TextRun({ text: hint, italics: true, color: '6B7280', font: FONT, size: 22 })],
    }),
    caption(`Hình ${no}. ${title}`),
  ];
}

function code(text, label) {
  const lines = text.replace(/\s+$/, '').split('\n');
  const out = [];
  if (label) {
    out.push(
      new Paragraph({
        keepNext: true,
        spacing: { before: 120, after: 40 },
        children: [new TextRun({ text: label, italics: true, font: FONT, size: 22, color: '555555' })],
      }),
    );
  }
  lines.forEach((line, i) => {
    out.push(
      new Paragraph({
        keepNext: i < lines.length - 1 && lines.length < 30,
        shading: { type: ShadingType.CLEAR, color: 'auto', fill: 'F4F6F8' },
        border: { left: { style: BorderStyle.SINGLE, size: 18, color: GOLD, space: 8 } },
        spacing: { after: 0, line: 240 },
        indent: { left: 170 },
        children: [new TextRun({ text: line.length ? line.replace(/\t/g, '  ') : ' ', font: MONO, size: 17, color: '1F2937' })],
      }),
    );
  });
  out.push(new Paragraph({ spacing: { after: 120 }, children: [] }));
  return out;
}

// ---------------------------------------------------------------------------
// Trang bìa
// ---------------------------------------------------------------------------
function coverPage() {
  const line = (text, size, opts = {}) =>
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: opts.before || 0, after: opts.after ?? 80 },
      children: [new TextRun({ text, size, font: FONT, bold: opts.bold, italics: opts.italics, color: opts.color || '000000' })],
    });
  const memberRow = (a, b) =>
    new TableRow({
      children: [a, b].map(
        (t, i) =>
          new TableCell({
            width: { size: i ? 3600 : 3000, type: WidthType.DXA },
            borders: {
              top: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
              bottom: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
              left: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
              right: { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' },
            },
            children: [new Paragraph({ spacing: { after: 60 }, children: [new TextRun({ text: t, font: FONT, size: 26, bold: i === 0 })] })],
          }),
      ),
    });

  return [
    line('[TÊN TRƯỜNG ĐẠI HỌC]', 28, { bold: true }),
    line('TRUNG TÂM ĐÀO TẠO TỪ XA', 28, { bold: true }),
    line('──────── ✦ ────────', 24, { color: GOLD, after: 600 }),
    line('BÁO CÁO BÀI TẬP LỚN', 40, { bold: true, color: NAVY, before: 600 }),
    line('Học phần: KIẾN TRÚC VÀ THIẾT KẾ PHẦN MỀM', 30, { bold: true, after: 500 }),
    line('Đề tài:', 28, { italics: true }),
    line('XÂY DỰNG HỆ THỐNG QUẢN LÝ KHÁCH SẠN', 34, { bold: true, color: NAVY }),
    line('“LUXE GRAND HOTEL”', 34, { bold: true, color: NAVY }),
    line('THEO KIẾN TRÚC RESTful API', 34, { bold: true, color: NAVY, after: 700 }),
    new Table({
      alignment: AlignmentType.CENTER,
      width: { size: 6600, type: WidthType.DXA },
      columnWidths: [3000, 3600],
      rows: [
        memberRow('Giảng viên hướng dẫn:', '[Họ tên giảng viên]'),
        memberRow('Nhóm thực hiện:', '[Tên / số nhóm]'),
        memberRow('Thành viên:', '[Họ tên SV 1] – [MSSV]'),
        memberRow('', '[Họ tên SV 2] – [MSSV]'),
        memberRow('', '[Họ tên SV 3] – [MSSV]'),
        memberRow('', '[Họ tên SV 4] – [MSSV]'),
        memberRow('Lớp:', '[Mã lớp]'),
      ],
    }),
    line('Hà Nội, 2026', 26, { bold: true, before: 1600 }),
  ];
}

// ---------------------------------------------------------------------------
// Phần mở đầu
// ---------------------------------------------------------------------------
function frontMatter() {
  return [
    unnumberedTitle('LỜI MỞ ĐẦU'),
    P('Trong ngành dịch vụ lưu trú, tốc độ phục vụ và độ chính xác của dữ liệu là hai yếu tố quyết định trải nghiệm của khách hàng và hiệu quả vận hành. Tại nhiều khách sạn quy mô vừa, dữ liệu phòng, đơn đặt phòng, hóa đơn và ca trực vẫn được ghi nhận rời rạc, khiến lễ tân phải tra cứu nhiều bước, quản lý phải tổng hợp số liệu thủ công và khách hàng không tự theo dõi được đơn của mình.'),
    P('Học phần **Kiến trúc và Thiết kế phần mềm** yêu cầu sinh viên xây dựng một hệ thống web theo kiến trúc **RESTful API**, tổ chức mã nguồn theo mô hình phân tầng, có xác thực – phân quyền và tài liệu hóa API đầy đủ. Nhóm lựa chọn đề tài **“Xây dựng hệ thống quản lý khách sạn Luxe Grand Hotel”**, tiếp nối kết quả nghiên cứu người dùng và thiết kế giao diện đã thực hiện ở học phần Thiết kế UI/UX, và tập trung trong báo cáo này vào phần **máy chủ API** (backend) – nơi chứa toàn bộ nghiệp vụ.'),
    P('Hệ thống được xây dựng bằng **NestJS (Node.js/TypeScript)** – một framework tổ chức theo module, Controller, Service, DTO và Guard tương đương với các tầng mà đề bài đề xuất cho Laravel/Express – kết hợp **Prisma ORM** và **PostgreSQL 16**, xác thực bằng **JWT**, tài liệu hóa bằng **Swagger/OpenAPI**, đóng gói bằng **Docker**. API phục vụ đồng thời ứng dụng di động Flutter dành cho khách hàng, lễ tân và quản trị viên.'),
    P('Báo cáo gồm 5 chương theo đúng yêu cầu của học phần:'),
    B('**Chương 1** – Khảo sát và phân tích yêu cầu: mô tả bài toán, yêu cầu chức năng, ba luồng nghiệp vụ (User Flow) và yêu cầu phi chức năng.'),
    B('**Chương 2** – Thiết kế hệ thống: kiến trúc tổng thể, biểu đồ gói, thành phần, triển khai, biểu đồ lớp, biểu đồ tuần tự và thiết kế cơ sở dữ liệu.'),
    B('**Chương 3** – Thiết kế RESTful API: nguyên tắc thiết kế, danh sách API, HTTP method, request/response mẫu, cơ chế xác thực và phân quyền.'),
    B('**Chương 4** – Cài đặt hệ thống: cấu trúc mã nguồn, giải thích các module, minh họa xử lý nghiệp vụ và giao diện ứng dụng tiêu thụ API.'),
    B('**Chương 5** – Kiểm thử và đánh giá: kịch bản và kết quả chạy kiểm thử API trên máy chủ thật, lỗi phát hiện, hạn chế và hướng phát triển.'),
    P('Nhóm xin chân thành cảm ơn giảng viên hướng dẫn đã định hướng và góp ý trong quá trình thực hiện. Do thời gian và kinh nghiệm còn hạn chế, báo cáo khó tránh khỏi thiếu sót; nhóm rất mong nhận được ý kiến đóng góp để hoàn thiện hệ thống.'),

    unnumberedTitle('BẢNG PHÂN CÔNG CÔNG VIỆC'),
    P('Theo yêu cầu của học phần, mỗi thành viên phụ trách tối thiểu hai chức năng và trực tiếp trình bày phần việc của mình khi bảo vệ. Bảng dưới đây là phân công theo module của mã nguồn backend.', { noIndent: false }),
    T(
      ['Thành viên', 'Chức năng phụ trách', 'Module / API chính'],
      [
        ['[Họ tên SV 1]', '1. Đăng ký, đăng nhập, quên mật khẩu, JWT\n2. Quản lý người dùng & phân quyền\n3. Quản lý thông tin cá nhân', 'auth, users, common/guards\n/auth/*, /users/*'],
        ['[Họ tên SV 2]', '1. Quản lý loại phòng (CRUD)\n2. Quản lý phòng, trạng thái phòng\n3. Tìm kiếm phòng trống, tìm kiếm full-text', 'room-types, rooms, elasticsearch\n/room-types/*, /rooms/*'],
        ['[Họ tên SV 3]', '1. Đặt phòng, duyệt / từ chối / hủy đơn\n2. Check-in, đổi phòng, dịch vụ phát sinh, check-out', 'bookings, services\n/bookings/*, /services/*'],
        ['[Họ tên SV 4]', '1. Hóa đơn, thanh toán, hoàn tiền\n2. Mở / chốt ca trực\n3. Thống kê doanh thu, công suất phòng', 'invoices, shifts, analytics\n/invoices/*, /shifts/*, /analytics/*'],
      ],
      [2, 4, 3.2],
    ),
    new Paragraph({ spacing: { after: 120 }, children: [] }),
    P('Ghi chú: nhóm điều chỉnh tên thành viên và phân công cho khớp thực tế trước khi nộp.', { run: { italics: true } }),

    unnumberedTitle('MỤC LỤC'),
    new TableOfContents('Mục lục', { hyperlink: true, headingStyleRange: '1-3' }),
  ];
}

// ---------------------------------------------------------------------------
// Chương 1
// ---------------------------------------------------------------------------
function chapter1() {
  return [
    H1('CHƯƠNG 1. KHẢO SÁT VÀ PHÂN TÍCH YÊU CẦU'),
    H2('1.1. Mô tả bài toán'),
    H3('1.1.1. Hiện trạng'),
    P('Luxe Grand Hotel vận hành nhiều nghiệp vụ liên quan chặt chẽ với nhau: đặt phòng, nhận phòng (check-in), trả phòng (check-out), đổi phòng, gọi dịch vụ, thu tiền và quản lý ca trực. Kết quả khảo sát (phỏng vấn bán cấu trúc khách hàng, lễ tân/thu ngân và quản lý ở học phần Thiết kế UI/UX) cho thấy dữ liệu về phòng, booking, khách và thanh toán chưa được quản lý tập trung nên thường thiếu đồng bộ và dễ sai lệch:'),
    B('**Khách hàng** không tự xem được phòng trống, đặt phòng và theo dõi đơn mà phải liên hệ và chờ phản hồi; khi check-in phải cung cấp lại thông tin đã khai báo lúc đặt phòng.'),
    B('**Lễ tân/Thu ngân** phải tra cứu qua nhiều bước; trạng thái phòng được báo qua bộ đàm nên thường cập nhật trễ; dịch vụ phát sinh dễ bị tính thiếu vào hóa đơn; khi chốt ca phải đối chiếu tiền mặt, giao dịch và số liệu sổ sách thủ công.'),
    B('**Quản lý** phải tổng hợp thủ công công suất phòng, doanh thu theo ngày/tháng/loại phòng nên không nắm được tình hình kịp thời; doanh thu đôi khi bị lệch phải rà soát lại.'),
    ...uiFigure(1, 'khach_san_luxe_grand.png', 'Khách sạn Luxe Grand Hotel – đối tượng khảo sát', 300),
    H3('1.1.2. Mục tiêu của hệ thống'),
    P('Xây dựng một **máy chủ RESTful API** làm nguồn dữ liệu duy nhất (single source of truth) cho toàn bộ nghiệp vụ khách sạn, phục vụ ứng dụng di động/web của ba nhóm người dùng. Hệ thống phải:'),
    B('Cho phép khách hàng tự tìm phòng trống, đặt phòng, theo dõi đơn, xem hóa đơn và gửi yêu cầu thanh toán.'),
    B('Giúp lễ tân xử lý nhanh vòng đời lưu trú: duyệt đơn, check-in, đổi phòng, ghi nhận dịch vụ, check-out có quyết toán tự động, thu tiền và chốt ca có đối chiếu chênh lệch.'),
    B('Cung cấp cho quản lý số liệu thống kê tổng hợp tự động: công suất phòng, doanh thu theo ngày/năm, hiệu suất nhân viên; quản lý danh mục phòng, loại phòng, dịch vụ, tài khoản.'),
    B('Đảm bảo tính nhất quán dữ liệu khi nhiều người thao tác đồng thời (chống đặt trùng phòng) và đồng bộ trạng thái phòng theo thời gian thực.'),
    H3('1.1.3. Phạm vi'),
    P('Báo cáo tập trung vào phần máy chủ API `Hotel-Management` (NestJS). Ứng dụng di động Flutter `hotel_app` đóng vai trò client tiêu thụ API, chỉ được đề cập ở mức kiến trúc tổng thể. Thanh toán trực tuyến qua cổng thanh toán và tích hợp kênh bán phòng (OTA) nằm ngoài phạm vi.'),

    H2('1.2. Tác nhân của hệ thống'),
    ...tableWithCaption(
      1,
      'Các tác nhân và vai trò',
      ['Tác nhân', 'Vai trò trong hệ thống (enum Role)', 'Mục tiêu chính'],
      [
        ['Khách vãng lai', 'Chưa đăng nhập', 'Xem loại phòng, tìm phòng trống, xem dịch vụ, đăng ký tài khoản'],
        ['Khách hàng', 'CUSTOMER', 'Đặt / hủy phòng, theo dõi đơn, gọi dịch vụ, xem hóa đơn, gửi yêu cầu thanh toán, quản lý hồ sơ cá nhân'],
        ['Lễ tân – Thu ngân', 'RECEPTIONIST', 'Duyệt đơn, check-in/out, đổi phòng, ghi dịch vụ, thu tiền, hoàn tiền, mở/chốt ca, cập nhật trạng thái phòng'],
        ['Quản trị viên', 'ADMIN', 'Toàn quyền: quản lý tài khoản, loại phòng, phòng, dịch vụ; xem báo cáo doanh thu, hiệu suất nhân viên'],
        ['Hệ thống định kỳ', 'Cron job', 'Gửi nhắc nhận phòng cho khách hằng ngày (CheckinReminderService)'],
      ],
      [2, 2.2, 5],
    ),

    H2('1.3. Yêu cầu chức năng'),
    P('Yêu cầu chức năng được chia thành hai nhóm theo đề bài: nhóm chức năng người dùng bắt buộc và nhóm chức năng nghiệp vụ do nhóm tự phân tích theo đề tài khách sạn.'),
    H3('1.3.1. Chức năng người dùng'),
    ...tableWithCaption(
      1,
      'Yêu cầu chức năng người dùng',
      ['Mã', 'Chức năng', 'Mô tả', 'Tác nhân'],
      [
        ['FR01', 'Đăng ký', 'Tạo tài khoản bằng email, mật khẩu (≥ 6 ký tự), họ tên, số điện thoại. Vai trò luôn là CUSTOMER, không cho client tự gán.', 'Khách vãng lai'],
        ['FR02', 'Đăng nhập / đăng xuất', 'Đăng nhập bằng email + mật khẩu, nhận access token và refresh token; làm mới token; đăng xuất thu hồi token. Tài khoản khách hàng chỉ đăng nhập trên 1 thiết bị.', 'Tất cả'],
        ['FR03', 'Quên mật khẩu', 'Gửi OTP qua email (hiệu lực 15 phút), xác thực OTP và đặt lại mật khẩu.', 'Tất cả'],
        ['FR04', 'Quản lý thông tin cá nhân', 'Xem hồ sơ, cập nhật họ tên, số điện thoại, ảnh đại diện; đổi mật khẩu.', 'Đã đăng nhập'],
        ['FR05', 'Phân quyền người dùng', 'Ba vai trò ADMIN, RECEPTIONIST, CUSTOMER; mỗi API khai báo vai trò được phép. Admin tạo tài khoản nhân viên, đổi vai trò, đặt lại mật khẩu, vô hiệu hóa tài khoản.', 'Admin'],
      ],
      [1, 2, 5, 1.6],
      { center: [0] },
    ),
    H3('1.3.2. Chức năng nghiệp vụ'),
    ...tableWithCaption(
      1,
      'Yêu cầu chức năng nghiệp vụ',
      ['Mã', 'Chức năng', 'Mô tả', 'Tác nhân'],
      [
        ['FR06', 'Quản lý loại phòng', 'CRUD loại phòng: tên, mã, giá/đêm, sức chứa, diện tích, tiện nghi, ảnh.', 'Admin'],
        ['FR07', 'Quản lý phòng', 'CRUD phòng (số phòng, tầng, loại); phòng do lễ tân tạo phải chờ duyệt; cập nhật nhanh trạng thái (trống, đang ở, đã đặt, dọn dẹp, bảo trì).', 'Admin, Lễ tân'],
        ['FR08', 'Tìm kiếm phòng', 'Tìm phòng trống theo khoảng ngày, số khách, loại phòng; tìm kiếm full-text theo tên/tiện nghi/khoảng giá; lọc theo tầng, trạng thái; phân trang.', 'Tất cả'],
        ['FR09', 'Đặt phòng', 'Khách đặt phòng → đơn PENDING; hệ thống chống trùng lịch, tự tính số đêm và tổng tiền; lễ tân đặt hộ có thể tạo thẳng đơn CONFIRMED.', 'Khách hàng, Lễ tân'],
        ['FR10', 'Duyệt / từ chối / hủy đơn', 'Lễ tân duyệt đơn kèm ghi nhận tiền cọc, hoặc từ chối có lý do; khách được tự hủy khi đơn còn PENDING.', 'Lễ tân, Khách hàng'],
        ['FR11', 'Check-in / đổi phòng', 'Nhận phòng cho đơn đã duyệt; đổi phòng cho khách đang lưu trú; trạng thái phòng cập nhật realtime.', 'Lễ tân'],
        ['FR12', 'Dịch vụ phát sinh', 'Quản lý danh mục dịch vụ (CRUD); khách gọi dịch vụ tại phòng, lễ tân duyệt; lễ tân ghi nhận dịch vụ trực tiếp.', 'Admin, Lễ tân, Khách hàng'],
        ['FR13', 'Check-out & hóa đơn', 'Xem trước bảng quyết toán (tiền phòng, dịch vụ, cọc, còn phải thu); chốt trả phòng, lập hóa đơn, thu tiền hoặc hoàn tiền khi trả phòng trước hạn.', 'Lễ tân'],
        ['FR14', 'Thanh toán', 'Thu tiền tại quầy; khách gửi yêu cầu thanh toán chuyển khoản, lễ tân xác nhận/từ chối; hoàn tiền; sổ thu tiền chi tiết.', 'Lễ tân, Khách hàng'],
        ['FR15', 'Quản lý ca trực', 'Mở ca với tiền đầu ca; chốt ca: hệ thống tính tiền mặt sổ sách, so với tiền thực tế, bắt buộc giải trình nếu lệch; lịch sử ca.', 'Lễ tân, Admin'],
        ['FR16', 'Thống kê', 'Dashboard KPI, doanh thu theo ngày/năm, xuất CSV, công suất theo loại phòng, hiệu suất nhân viên.', 'Admin, Lễ tân'],
        ['FR17', 'Thông báo', 'Thông báo trong ứng dụng và push notification (FCM) khi đơn được duyệt, nhắc nhận/trả phòng.', 'Tất cả'],
      ],
      [1, 2, 5, 1.6],
      { center: [0] },
    ),
    P('Các thao tác dữ liệu chung mà đề bài yêu cầu đều có mặt: **CRUD** (loại phòng, phòng, dịch vụ, người dùng), **tìm kiếm** (người dùng, phòng, đơn, hóa đơn), **phân trang** (tham số `page`, `limit` trên mọi API danh sách), **thống kê** (module analytics) và **quản lý trạng thái** (vòng đời đơn đặt phòng, trạng thái phòng, trạng thái thanh toán, trạng thái ca).'),

    H2('1.4. Phân tích luồng nghiệp vụ (User Flow)'),
    P('Từ kết quả nghiên cứu người dùng ở học phần Thiết kế UI/UX, nhóm xác định ba luồng nghiệp vụ chính. Mỗi bước trong luồng được ánh xạ sang lời gọi API tương ứng; đây là căn cứ để thiết kế danh sách API ở Chương 3 và các kịch bản kiểm thử ở Chương 5.'),
    H3('1.4.1. Luồng 1 – Khách hàng đặt phòng'),
    ...uiFigure(1, 'userflow_1_dat_phong.png', 'User Flow 1 – Khách hàng tìm và đặt phòng', 560),
    ...tableWithCaption(
      1,
      'Ánh xạ User Flow 1 sang API',
      ['Bước trong luồng', 'API được gọi', 'Kết quả / Nhánh lỗi'],
      [
        ['Chọn ngày, số khách → Xem danh sách phòng', '`GET /rooms/available?checkInDate&checkOutDate&guestCount`', 'Danh sách phòng không trùng lịch (cache Redis 60 giây)'],
        ['Còn phòng phù hợp? – Không', '(cùng API, kết quả rỗng)', 'Hiện trạng thái hết phòng, khách đổi ngày / bộ lọc'],
        ['Chọn phòng → Xem chi tiết', '`GET /rooms/{id}`', 'Ảnh, tiện nghi, giá/đêm, chính sách'],
        ['Kiểm tra thông tin → Xác nhận đặt phòng', '`POST /bookings`', '201: đơn PENDING; 409: phòng vừa bị người khác đặt; 400: ngày không hợp lệ'],
        ['Nhận trạng thái → Theo dõi booking', '`GET /bookings`, `GET /bookings/{id}`, thông báo FCM', 'Khách thấy đơn chuyển PENDING → CONFIRMED khi lễ tân duyệt'],
      ],
      [3, 3.6, 3.6],
    ),
    H3('1.4.2. Luồng 2 – Lễ tân: check-in, đổi phòng, check-out'),
    ...uiFigure(1, 'userflow_2_luu_tru.png', 'User Flow 2 – Check-in, đổi phòng và check-out', 760),
    ...tableWithCaption(
      1,
      'Ánh xạ User Flow 2 sang API',
      ['Bước trong luồng', 'API được gọi', 'Ràng buộc nghiệp vụ phía máy chủ'],
      [
        ['Mở Room Matrix / tìm booking', '`GET /rooms` + SSE `GET /rooms/stream`; `GET /bookings?search=`', 'Trạng thái phòng đẩy realtime tới mọi máy lễ tân'],
        ['Không thấy booking → tạo booking walk-in', '`POST /bookings` (lễ tân tạo thẳng CONFIRMED)', 'Vẫn kiểm tra trùng lịch như đơn online'],
        ['Phòng sẵn sàng? → Check-in', '`PATCH /bookings/{id}/approve`, `POST /bookings/{id}/check-in`', 'Chỉ check-in đơn CONFIRMED; phòng → OCCUPIED'],
        ['Yêu cầu đổi phòng → chọn phòng trống mới', '`POST /bookings/{id}/change-room`', 'Phòng mới không được đang bảo trì / dọn dẹp / có khách; phòng cũ → CLEANING'],
        ['Kiểm tra dịch vụ / bill → Bill chính xác?', '`POST /bookings/{id}/services`, `GET /bookings/{id}/checkout-preview`', 'Bảng quyết toán dùng chung công thức với check-out'],
        ['Thanh toán → Check-out → cập nhật trạng thái phòng', '`POST /bookings/{id}/check-out`', 'Thu đủ số còn phải thu mới cho trả phòng; phòng → CLEANING'],
      ],
      [3, 3.8, 3.4],
    ),
    H3('1.4.3. Luồng 3 – Ca trực của lễ tân'),
    ...uiFigure(1, 'userflow_3_ca_truc.png', 'User Flow 3 – Mở ca, thu tiền trong ca và chốt ca', 480),
    P('Sơ đồ chia vòng đời ca trực thành bốn giai đoạn: OPEN → giao dịch thu tiền → CLOSING → CLOSED. Ở máy chủ, ca trực chỉ lưu hai trạng thái bền vững **OPEN** và **CLOSED**; giai đoạn “giao dịch thu tiền” tương ứng các dòng `Payment` được gắn `shiftId` của ca đang mở, còn giai đoạn “CLOSING” là bước đối chiếu trên giao diện trước khi gọi API chốt ca:'),
    B('Mở ca: `POST /shifts/open` với tiền mặt nhận bàn giao; mỗi nhân viên chỉ có tối đa một ca OPEN.'),
    B('Trong ca: mọi khoản thu/hoàn (`/invoices/{id}/pay`, check-out, xác nhận yêu cầu thanh toán) tự gắn vào ca đang mở.'),
    B('Đối chiếu: `GET /shifts/current` trả về số liệu ca, trong đó `expectedCash` = tiền đầu ca + thu tiền mặt − hoàn tiền mặt.'),
    B('Chốt ca: `POST /shifts/close` với `actualCash`; nếu chênh lệch khác 0 thì bắt buộc nhập `differenceReason`, ca chuyển CLOSED.'),

    H2('1.5. Yêu cầu phi chức năng'),
    ...tableWithCaption(
      1,
      'Yêu cầu phi chức năng',
      ['Nhóm', 'Yêu cầu', 'Giải pháp đáp ứng'],
      [
        ['Bảo mật', 'Xác thực mọi API nghiệp vụ; phân quyền theo vai trò; không lộ mật khẩu; chống truy cập trái phép', 'JWT Bearer, JwtAuthGuard, RolesGuard, bcrypt (salt 10), blacklist token khi đăng xuất, ValidationPipe whitelist'],
        ['Toàn vẹn dữ liệu', 'Không đặt trùng phòng; các thao tác nhiều bảng phải nguyên tử', 'Khóa phân tán Redis theo phòng, kiểm tra giao lịch; Prisma $transaction cho check-in/out, duyệt đơn, chốt ca'],
        ['Hiệu năng', 'Phản hồi nhanh cho danh sách và tìm kiếm', 'Index CSDL trên cột lọc, cache Redis (phòng trống 60s, user 30s), Elasticsearch, nén gzip, phân trang tối đa 100 bản ghi/trang'],
        ['Thời gian thực', 'Sơ đồ phòng và danh sách tài khoản cập nhật ngay trên mọi thiết bị', 'Server-Sent Events: /rooms/stream, /users/stream'],
        ['Khả năng mở rộng', 'Dễ thêm module, có thể tách dịch vụ', 'Kiến trúc module của NestJS, Dependency Injection, stateless JWT, Docker'],
        ['Khả năng bảo trì', 'Mã nguồn rõ ràng, chuẩn hóa', 'TypeScript, phân tầng Controller–Service–Data Access, DTO, xử lý lỗi tập trung'],
        ['Tính dễ dùng của API', 'Định dạng nhất quán, thông báo lỗi dễ hiểu', 'Phong bì JSON chung { statusCode, success, message, data }, thông điệp lỗi tiếng Việt'],
        ['Tài liệu hóa', 'Có tài liệu API để client tích hợp', 'Swagger/OpenAPI tại /api/docs, Postman Collection'],
        ['Triển khai', 'Dễ cài đặt và triển khai', 'Dockerfile, docker-compose (PostgreSQL, Redis, Elasticsearch), Render'],
      ],
      [1.8, 3.4, 4.6],
    ),

    H2('1.6. Công nghệ sử dụng và đối chiếu yêu cầu đề bài'),
    P('Đề bài cho phép sử dụng Laravel hoặc framework khác, kèm phần ánh xạ các tầng cho Node.js. Nhóm chọn **NestJS** vì framework này áp đặt sẵn cấu trúc phân tầng (Module – Controller – Service – Provider) và hỗ trợ Dependency Injection, Guard, Pipe, Interceptor tương đương Middleware/Request/Service Container của Laravel.'),
    ...tableWithCaption(
      1,
      'Đối chiếu công nghệ với yêu cầu',
      ['Yêu cầu đề bài', 'Lựa chọn của nhóm', 'Phiên bản'],
      [
        ['PHP 8.x + Laravel ≥ 10 (hoặc framework khác)', 'Node.js + NestJS (TypeScript)', 'Node 20, NestJS 10.4, TypeScript 5.7'],
        ['MySQL / PostgreSQL', 'PostgreSQL + Prisma ORM', 'PostgreSQL 16, Prisma 5.22'],
        ['RESTful API, JSON Response', 'REST, prefix /api/v1, JSON envelope chuẩn hóa', '—'],
        ['Git / GitHub', 'github.com/thinhtx20/Hotel-Management', '51 commit'],
        ['Khuyến khích: JWT / Sanctum', 'JWT (passport-jwt) + refresh token rotation', '@nestjs/jwt 10.2'],
        ['Khuyến khích: Docker', 'Dockerfile + docker-compose', 'node:20-alpine'],
        ['Khuyến khích: Postman', `Postman Collection (${TEST_GROUPS.reduce((n, g) => n + g.cases.length, 0)} ca kiểm thử)`, 'Collection v2.1'],
        ['Khuyến khích: Swagger / OpenAPI', '@nestjs/swagger, giao diện /api/docs', '7.4'],
        ['Bổ sung', 'Redis (cache, khóa phân tán), Elasticsearch (tìm kiếm), Firebase (push), Nodemailer (OTP), Cloudinary (ảnh)', 'Redis 7, ES 8.11'],
      ],
      [3.2, 4, 2.4],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Chương 2
// ---------------------------------------------------------------------------
function chapter2() {
  return [
    // Mục 2.1 – 2.5 chứa các sơ đồ khổ rộng nên được dàn trang ngang
    LANDSCAPE_START,
    H1('CHƯƠNG 2. THIẾT KẾ HỆ THỐNG'),
    H2('2.1. Kiến trúc tổng thể'),
    P('Hệ thống áp dụng kiến trúc **client – server ba tầng (3-tier)**. Ở tầng ứng dụng, máy chủ được tổ chức theo **kiến trúc phân lớp (Layered Architecture)** dạng **modular monolith**: mỗi nghiệp vụ là một module NestJS độc lập (auth, rooms, bookings…), bên trong chia thành các lớp có trách nhiệm tách biệt.'),
    B('**Presentation Tier** – ứng dụng Flutter `hotel_app` (Presentation → BLoC → Repository → Network). Client chỉ giao tiếp với máy chủ qua HTTPS (REST) và SSE.'),
    B('**Application Tier** – máy chủ NestJS gồm 4 lớp: **API** (Controller + Guard + Pipe), **Business** (Service chứa nghiệp vụ), **Data Access** (PrismaService, RedisService, ElasticsearchService) và **Integration** (Mail, Upload, Notifications).'),
    B('**Data Tier** – PostgreSQL lưu dữ liệu nghiệp vụ (ACID), Redis làm cache và khóa phân tán, Elasticsearch làm chỉ mục tìm kiếm phòng.'),
    P('Luồng xử lý một request tuân thủ đúng yêu cầu đề bài: **Client → Route → Controller → Service → Data Access (Prisma) → Database**, kết quả trả ngược lại qua Service, Controller, được Interceptor đóng gói thành JSON chuẩn rồi gửi về Client. Controller không chứa nghiệp vụ, Service không biết đến HTTP.'),
    ...wideFigure(2, 'layers_diagram.png', 'Kiến trúc 3 tầng và phân lớp N-tầng'),

    H2('2.2. Biểu đồ gói'),
    P('Phía máy chủ `Hotel-Management::src` gồm ba nhóm gói, phụ thuộc theo một chiều từ trên xuống:'),
    B('**common** – thành phần dùng chung: `decorators` (@Public, @Roles, @CurrentUser, @SkipTransform), `dto` (PaginationQueryDto), `filters` (AllExceptionsFilter), `guards` (JwtAuthGuard, RolesGuard), `interceptors` (TransformInterceptor), `utils` (phân trang, tính doanh thu, suy diễn trạng thái phòng).'),
    B('**Feature Modules** – 9 module nghiệp vụ: auth, users, room-types, rooms, bookings, invoices, services, shifts, analytics. Module bookings phụ thuộc rooms (đồng bộ trạng thái phòng) và invoices (lập hóa đơn khi trả phòng).'),
    B('**Infrastructure Modules** – prisma, redis, elasticsearch, notifications, mail, upload: bao bọc hạ tầng và dịch vụ bên ngoài, được inject vào các module nghiệp vụ.'),
    P('Phía client `hotel_app::lib` tổ chức theo feature (auth, customer, receptionist, admin…), dùng chung `shared` (models, repositories, widgets) và `core` (network, router, theme…). Hai hệ thống phụ thuộc nhau duy nhất qua giao diện REST/SSE.'),
    ...wideFigure(2, 'package_diagram.png', 'Biểu đồ gói của hệ thống'),

    H2('2.3. Biểu đồ thành phần'),
    P('Hệ con **Hotel Management API** cung cấp hai giao diện cho client: `IRestApi` (REST/JSON) và `IRoomEventStream` (SSE). Bên trong, thành phần **Security & Pipeline** (JwtAuthGuard, RolesGuard, ValidationPipe, Exception Filter, TransformInterceptor) bao quanh **REST Controllers**; Controller sử dụng **Domain Services**; Domain Services dùng các thành phần hạ tầng (PrismaService, RedisService, ElasticsearchService, NotificationsService, MailService, UploadService) và phát sự kiện qua **Realtime Event Bus** (RoomEventsService, UserEventsService dựa trên RxJS Subject). Thành phần **Scheduler** chạy cron gửi nhắc nhận phòng. Mỗi thành phần hạ tầng kết nối tới một hệ thống ngoài qua cổng giao thức riêng (SQL/TCP 5432, RESP/TCP 6379, HTTP 9200, FCM HTTP v1, SMTP 587, Cloudinary HTTPS).'),
    ...wideFigure(2, 'component_diagram.png', 'Biểu đồ thành phần'),

    H2('2.4. Biểu đồ triển khai'),
    P('Ứng dụng di động (Android 10+/iOS 15+) gọi API qua HTTPS cổng 443. Máy chủ ứng dụng chạy trên **Render Web Service** (region Singapore) trong **Docker container** `node:20-alpine`, thực thi `dist/main.js` (bản build NestJS) cùng `@prisma/client` sinh từ `schema.prisma`; cấu hình bí mật (DATABASE_URL, JWT_SECRET…) nạp từ biến môi trường. Máy chủ CSDL gồm PostgreSQL 16 (cơ sở dữ liệu `hotel_db`), Redis 7 và Elasticsearch 8.11 – khi phát triển cục bộ cả ba được khởi chạy bằng `docker-compose.yml`. Các dịch vụ ngoài gồm Firebase Cloud Messaging, máy chủ SMTP và Cloudinary.'),
    ...wideFigure(2, 'deployment_diagram.png', 'Biểu đồ triển khai'),

    H2('2.5. Biểu đồ lớp'),
    P('Mô hình miền gồm 9 lớp thực thể và 9 kiểu liệt kê, ánh xạ 1–1 với các model trong `prisma/schema.prisma`:'),
    ...tableWithCaption(
      2,
      'Mô tả các lớp thực thể',
      ['Lớp', 'Ý nghĩa', 'Quan hệ chính'],
      [
        ['User', 'Tài khoản (khách hàng, lễ tân, admin); lưu activeSessionId cho chính sách 1 thiết bị', '1 – n Booking (đặt), 1 – n WorkShift (trực ca), 1 – n Payment (tạo / xác nhận)'],
        ['RoomType', 'Hạng phòng: giá cơ bản, sức chứa, tiện nghi, ảnh', '1 – n Room'],
        ['Room', 'Phòng vật lý: số phòng, tầng, trạng thái', 'n – 1 RoomType, 1 – n Booking'],
        ['Booking', 'Đơn đặt phòng: mã đơn, ngày nhận/trả, tiền, cọc, trạng thái, dấu vết duyệt/hủy', 'n – 1 User, n – 1 Room, 1 – 0..1 Invoice, 1 – n ExtraServiceOrder (hợp thành)'],
        ['Invoice', 'Hóa đơn: tiền phòng, dịch vụ, giảm giá, thuế, tổng, đã trả, trạng thái thanh toán', '1 – 1 Booking, 1 – n Payment (hợp thành)'],
        ['Payment', 'Một dòng trên sổ thu tiền: thu, cọc hoặc hoàn; trạng thái PENDING/CONFIRMED/REJECTED', 'n – 1 Invoice, n – 0..1 WorkShift'],
        ['ExtraServiceOrder', 'Dịch vụ phát sinh của một đơn, lưu bản sao tên và đơn giá tại thời điểm gọi', 'n – 1 Booking; «use» HotelService'],
        ['HotelService', 'Danh mục dịch vụ khách sạn', '—'],
        ['WorkShift', 'Ca trực: tiền đầu ca, tiền thực tế, tiền sổ sách, chênh lệch, doanh thu phi tiền mặt', 'n – 1 User (nhân viên), n – 0..1 User (nhận bàn giao)'],
      ],
      [2, 4.2, 4],
    ),
    P('Điểm thiết kế đáng chú ý: `Invoice.paidAmount` **không được cộng trừ trực tiếp** mà luôn được tính lại bằng tổng các dòng `Payment` ở trạng thái CONFIRMED (thu cộng, hoàn trừ) qua phương thức `recalculateInvoiceTotals()`. Nhờ đó số “còn phải thu” khi check-out luôn khớp với tiền thực tế đã vào két – giải quyết đúng pain point “doanh thu bị lệch” thu được khi khảo sát.'),
    ...wideFigure(2, 'class_diagram.png', 'Biểu đồ lớp mô hình miền', 560),
    LANDSCAPE_END,

    H3('Máy trạng thái của đơn đặt phòng, phòng và ca trực'),
    ...tableWithCaption(
      2,
      'Chuyển trạng thái đơn đặt phòng (BookingStatus)',
      ['Từ', 'Sang', 'Sự kiện / API', 'Tác động lên phòng'],
      [
        ['—', 'PENDING', 'Khách hàng POST /bookings', 'Không chiếm phòng'],
        ['—', 'CONFIRMED', 'Lễ tân đặt hộ POST /bookings', 'RESERVED'],
        ['PENDING', 'CONFIRMED', 'PATCH /bookings/{id}/approve | confirm', 'RESERVED'],
        ['PENDING / CONFIRMED', 'CANCELLED', 'PATCH /bookings/{id}/reject | cancel', 'Suy diễn lại (thường AVAILABLE)'],
        ['CONFIRMED', 'CHECKED_IN', 'POST /bookings/{id}/check-in', 'OCCUPIED'],
        ['CHECKED_IN', 'CHECKED_OUT', 'POST /bookings/{id}/check-out', 'CLEANING (chờ buồng phòng)'],
      ],
      [2.4, 2, 3.8, 2.6],
    ),
    P('Mọi thao tác trái quy tắc (ví dụ check-in đơn PENDING, check-out đơn chưa CHECKED_IN, khách hủy đơn đã CONFIRMED) đều bị Service từ chối với mã **400 Bad Request** và thông điệp giải thích.'),
    ...tableWithCaption(
      2,
      'Chuyển trạng thái phòng (RoomStatus)',
      ['Từ', 'Sang', 'Sự kiện / API', 'Ràng buộc'],
      [
        ['PENDING_APPROVAL', 'AVAILABLE / REJECTED', 'PATCH /rooms/{id}/approve | reject', 'Phòng do lễ tân tạo phải được duyệt'],
        ['AVAILABLE', 'RESERVED', 'Duyệt đơn / lễ tân đặt hộ (syncRoomStatus)', 'Chỉ khi có đơn CONFIRMED nhận phòng trong hôm nay'],
        ['AVAILABLE / RESERVED', 'OCCUPIED', 'POST /bookings/{id}/check-in', 'Đơn phải ở CONFIRMED'],
        ['OCCUPIED', 'CLEANING', 'POST /bookings/{id}/check-out; phòng cũ khi đổi phòng', 'Thu đủ tiền trước khi trả phòng'],
        ['CLEANING', 'AVAILABLE', 'PATCH /rooms/{id}/status', 'Buồng phòng xác nhận dọn xong; không tự nhảy sang RESERVED'],
        ['Bất kỳ', 'MAINTENANCE', 'PATCH /rooms/{id}/status', 'Không đặt được phòng đang bảo trì; không đổi trạng thái khi còn khách CHECKED_IN'],
      ],
      [2.4, 2.2, 3.4, 3.4],
    ),
    ...tableWithCaption(
      2,
      'Chuyển trạng thái ca trực (ShiftStatus)',
      ['Từ', 'Sang', 'Sự kiện / API', 'Ràng buộc'],
      [
        ['(chưa có ca)', 'OPEN', 'POST /shifts/open', 'Mỗi nhân viên tối đa một ca OPEN; ghi tiền mặt đầu ca'],
        ['OPEN', 'OPEN', 'Thu / hoàn tiền trong ca', 'Dòng Payment được gắn shiftId của ca đang mở'],
        ['OPEN', 'CLOSED', 'POST /shifts/close', 'Lệch tiền (actualCash ≠ expectedCash) phải có differenceReason'],
        ['OPEN', 'CLOSED', 'POST /shifts/{id}/close', 'Quản trị viên chốt hộ ca của nhân viên'],
      ],
      [2, 1.6, 3, 5],
    ),

    H2('2.6. Biểu đồ tuần tự'),
    P('Biểu đồ tuần tự dưới đây mô tả kịch bản nghiệp vụ quan trọng nhất: **khách hàng đặt phòng → lễ tân phê duyệt và thu cọc → làm thủ tục nhận phòng**, đi xuyên qua tất cả các lớp của hệ thống.'),
    ...figure(2, 'sequence_diagram.png', 'Biểu đồ tuần tự: đặt phòng, phê duyệt và check-in', 760),
    H3('Giai đoạn 1 – Khách hàng đặt phòng trực tuyến (bước 1–21)'),
    ...steps([
      'Khách chọn phòng và ngày trên `CreateBookingModal`; `BookingRepository` gọi `DioClient` gửi `POST /api/v1/bookings` kèm JWT.',
      '`BookingsController.create()` chỉ lấy DTO đã được validate và thông tin người dùng hiện tại rồi chuyển cho `BookingsService.create()`.',
      'Service xin **khóa phân tán** `lock:booking:room:{roomId}` trên Redis (TTL 6 giây). Nếu không lấy được khóa (có request khác đang đặt cùng phòng) → `409 Conflict`.',
      'Trong vùng khóa, Service truy vấn đơn giao lịch (PENDING/CONFIRMED/CHECKED_IN có khoảng ngày giao nhau). Nếu có → `409 Conflict`; nếu không, tính số đêm × giá và tạo đơn trạng thái **PENDING**.',
      'Service đồng bộ trạng thái phòng, xóa cache phòng trống, giải phóng khóa và trả về `201 Created`.',
    ]),
    H3('Giai đoạn 2 – Lễ tân phê duyệt và thu cọc (bước 22–40)'),
    ...steps([
      'Lễ tân gọi `PATCH /bookings/{id}/approve`; request đi qua `JwtAuthGuard` và `RolesGuard` (chỉ ADMIN, RECEPTIONIST).',
      'Trong **một transaction**: đơn chuyển CONFIRMED, tạo/cập nhật hóa đơn, ghi dòng `Payment` loại DEPOSIT.',
      'Phòng chuyển RESERVED; `RoomEventsService` phát sự kiện, SSE đẩy `room.status_changed` tới `RoomMatrixScreen` của mọi máy lễ tân (song song với việc trả `200 OK`).',
    ]),
    H3('Giai đoạn 3 – Nhận phòng (bước 41–59)'),
    ...steps([
      'Khách xuất trình giấy tờ; lễ tân chọn phòng và bấm Check-in → `POST /bookings/{id}/check-in`.',
      'Nếu đơn ở CONFIRMED: transaction cập nhật đơn sang CHECKED_IN (ghi `actualCheckIn`) và phòng sang OCCUPIED, phát sự kiện realtime, trả `200`/`201`.',
      'Ngược lại (PENDING, CANCELLED hoặc đã CHECKED_IN) → `400 Bad Request` với thông điệp cụ thể.',
    ]),

    H2('2.7. Thiết kế cơ sở dữ liệu'),
    P('Cơ sở dữ liệu PostgreSQL gồm **10 bảng**, được Prisma sinh từ schema; khóa chính dạng UUID, khóa ngoại có ràng buộc toàn vẹn và **index** trên các cột thường dùng để lọc (trạng thái, ngày nhận/trả, roomId, customerId…). Script DDL đầy đủ nộp kèm trong tệp `hotel_db_schema.sql`.'),
    ...tableWithCaption(
      2,
      'Danh sách bảng dữ liệu',
      ['Bảng', 'Cột chính', 'Ràng buộc / Index'],
      [
        ['users', 'id, email, password (bcrypt), fullName, phone, avatar, role, isActive, activeSessionId, fcmToken', 'UNIQUE(email); INDEX(role), INDEX(isActive)'],
        ['room_types', 'id, name, code, basePrice, capacityAdults, capacityChildren, sizeSqM, amenities[], images[]', 'UNIQUE(name), UNIQUE(code)'],
        ['rooms', 'id, roomNumber, floor, roomTypeId, status, notes', 'UNIQUE(roomNumber); FK roomTypeId; INDEX(status, floor, roomTypeId)'],
        ['bookings', 'id, bookingCode, customerId, roomId, checkInDate, checkOutDate, actualCheckIn/Out, guestCount, totalAmount, depositAmount, status, confirmedById, cancelledById…', 'UNIQUE(bookingCode); FK customer, room; 8 index gồm (roomId, status), (customerId, status)'],
        ['invoices', 'id, invoiceCode, bookingId, roomAmount, servicesAmount, discount, tax, finalAmount, paidAmount, paymentMethod, paymentStatus', 'UNIQUE(invoiceCode), UNIQUE(bookingId); ON DELETE CASCADE'],
        ['payments', 'id, invoiceId, amount, method, type, status, reference, createdById, confirmedById, shiftId', 'FK invoice (CASCADE), shift (SET NULL); INDEX(confirmedById, status, confirmedAt)'],
        ['extra_service_orders', 'id, bookingId, serviceName, unitPrice, quantity, totalPrice, status, requestedById', 'FK booking (CASCADE)'],
        ['hotel_services', 'id, code, name, category, unitPrice, unit, isAvailable', 'UNIQUE(code)'],
        ['work_shifts', 'id, shiftCode, staffId, shiftType, status, startTime, endTime, initialCash, actualCash, expectedCash, cashDifference…', 'UNIQUE(shiftCode); INDEX(staffId, status, startTime)'],
        ['password_resets', 'id, email, otp, token, expiresAt, used', 'UNIQUE(token); INDEX(email)'],
      ],
      [2, 5, 3.4],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Chương 3
// ---------------------------------------------------------------------------

const AUTH_LABEL = { admin: 'ADMIN', reception: 'RECEPTIONIST', customer: 'CUSTOMER', fake: 'giả mạo' };

// Request + response thật của một ca kiểm thử (đã che token, rút gọn theo `pickKeys`)
function realExchange(id, { pickKeys, label } = {}) {
  const r = resultOf(id);
  const tc = TEST_GROUPS.flatMap((g) => g.cases).find((c) => c.id === id);
  if (!r || !tc) return [P(`(Chưa có kết quả chạy cho ${id})`, { noIndent: true })];
  const reqLines = [`${tc.method} /api/v1${tc.path.replace(/\{\{\w*Id\}\}/g, '{id}')}`];
  if (tc.auth) reqLines.push(`Authorization: Bearer <access token ${AUTH_LABEL[tc.auth]}>`);
  if (r.request !== undefined) reqLines.push('Content-Type: application/json', '', JSON.stringify(r.request, null, 2));
  const body = pickKeys ? pick(r.response, pickKeys) : r.response;
  return [
    ...code(reqLines.join('\n'), `Request (${id}${label ? ' – ' + label : ''}):`),
    ...code(`${httpLine(r.actual)}   (${r.timeMs} ms)\n${JSON.stringify(body, null, 2)}`, 'Response:'),
  ];
}

function sampleSection() {
  const runNote = TEST_RUN
    ? `Các ví dụ dưới đây là request/response **thật**, ghi lại khi chạy bộ kiểm thử lúc ${formatRunTime(TEST_RUN.runAt)} trên máy chủ \`${TEST_RUN.baseUrl}\`. Token JWT được rút gọn, một số trường dài được lược bớt để dễ đọc.`
    : 'Các ví dụ dưới đây minh họa cấu trúc request/response của hệ thống.';

  const roomsList = resultOf('TC17');
  const roomsBody = roomsList
    ? {
        statusCode: roomsList.response.statusCode,
        success: roomsList.response.success,
        message: roomsList.response.message,
        data: {
          data: roomsList.response.data.data
            .slice(0, 1)
            .map((room) => pick(room, ['id', 'roomNumber', 'floor', 'status', 'roomTypeName', 'roomTypeCode', 'pricePerNight', 'capacity', 'amenities'])),
          meta: roomsList.response.data.meta,
        },
      }
    : null;

  return [
    H2('3.6. Request / Response mẫu'),
    P(runNote),
    H3('3.6.1. Đăng nhập – POST /api/v1/auth/login'),
    ...realExchange('TC04', {
      pickKeys: ['statusCode', 'success', 'message', 'data.user.id', 'data.user.email', 'data.user.fullName', 'data.user.role', 'data.accessToken', 'data.refreshToken', 'data.tokenType', 'data.expiresIn', 'timestamp'],
    }),
    ...realExchange('TC06', { label: 'sai mật khẩu' }),

    H3('3.6.2. Validate dữ liệu đầu vào – POST /api/v1/auth/register'),
    ...realExchange('TC03', { label: 'thiếu họ tên, email sai, mật khẩu ngắn' }),

    H3('3.6.3. Danh sách phòng có lọc và phân trang – GET /api/v1/rooms'),
    ...code(`GET /api/v1/rooms?status=AVAILABLE&page=1&limit=5`, 'Request (TC17):'),
    ...(roomsBody
      ? code(`${httpLine(roomsList.actual)}   (${roomsList.timeMs} ms)\n${JSON.stringify(roomsBody, null, 2)}`, `Response (chỉ in phần tử đầu tiên của trang; meta cho biết có ${roomsList.response.data.meta.total} phòng trống, ${roomsList.response.data.meta.totalPages} trang):`)
      : []),

    H3('3.6.4. Đặt phòng – POST /api/v1/bookings'),
    ...realExchange('TC26', {
      pickKeys: ['statusCode', 'success', 'data.id', 'data.bookingCode', 'data.status', 'data.checkInDate', 'data.checkOutDate', 'data.nights', 'data.guestCount', 'data.totalAmount', 'data.depositAmount', 'data.paymentStatus', 'data.canCancel', 'data.room.roomNumber', 'data.room.roomType.name', 'data.room.roomType.basePrice'],
    }),
    P('Giờ nhận phòng được máy chủ chuẩn hóa về 14:00 và giờ trả về 12:00; `totalAmount` = 2 đêm × `basePrice`.'),
    ...realExchange('TC27', { label: 'đặt trùng lịch' }),

    H3('3.6.5. Phê duyệt đơn – PATCH /api/v1/bookings/{id}/approve'),
    ...realExchange('TC29', {
      pickKeys: ['statusCode', 'success', 'message', 'data.depositAmount', 'data.booking.bookingCode', 'data.booking.status', 'data.booking.confirmedAt', 'data.booking.confirmationNote'],
    }),

    H3('3.6.6. Trả phòng – POST /api/v1/bookings/{id}/check-out (minh họa)'),
    P('Bộ kiểm thử tự động không chạy check-out trên máy chủ thật để tránh phát sinh giao dịch tiền vào sổ quỹ; ví dụ dưới đây minh họa theo hợp đồng API và mã nguồn của `BookingsService.checkOut()`.'),
    ...code(
      `POST /api/v1/bookings/{id}/check-out
Authorization: Bearer <access token RECEPTIONIST>
Content-Type: application/json

{ "amountCollected": 2700000, "paymentMethod": "CASH", "note": "Thu tại quầy" }`,
      'Request (số tiền lấy từ GET /bookings/{id}/checkout-preview):',
    ),
    ...code(
      `HTTP/1.1 201 Created
{
  "success": true,
  "message": "Check-out và thanh toán hóa đơn thành công",
  "data": {
    "invoiceId": "f02c…",
    "amountCollected": 2700000,
    "refundAmount": 0,
    "isEarlyCheckOut": false,
    "remainingAmount": 0,
    "settlement": { "roomAmount": 3000000, "servicesAmount": 200000,
                    "finalAmount": 3200000, "amountDue": 2700000 },
    "booking": { "status": "CHECKED_OUT", "room": { "status": "CLEANING" } }
  }
}`,
      'Response:',
    ),

    H3('3.6.7. Truy cập trái phép'),
    ...realExchange('TC12', { label: 'khách hàng gọi API của nhân viên' }),
    ...realExchange('TC07', { label: 'không gửi token' }),
  ];
}
function chapter3() {
  const totalRows = ENDPOINT_GROUPS.reduce((n, g) => n + g.items.length, 0);
  const endpointRows = [];
  ENDPOINT_GROUPS.forEach((g) => {
    const header = [g.title, '', '', ''];
    header.groupRow = true;
    endpointRows.push(header);
    g.items.forEach(([m, p, d, r]) => endpointRows.push([m, `\`${p}\``, d, r]));
  });

  return [
    H1('CHƯƠNG 3. THIẾT KẾ RESTful API'),
    H2('3.1. Nguyên tắc thiết kế'),
    B('**Base URL:** `https://<host>/api/v1` – tiền tố phiên bản `v1` cho phép nâng cấp API mà không phá vỡ client cũ.'),
    B('**Tài nguyên là danh từ số nhiều, kebab-case:** `/rooms`, `/room-types`, `/bookings`, `/invoices`. Tài nguyên con biểu diễn bằng đường dẫn lồng: `/bookings/{id}/services/{orderId}`, `/invoices/{id}/payment-requests`.'),
    B('**Hành động nghiệp vụ không thuần CRUD** (chuyển trạng thái) được mô hình hóa thành tài nguyên con dạng động từ: `/bookings/{id}/check-in`, `/bookings/{id}/check-out`, `/shifts/open`, `/shifts/close` – cách làm phổ biến cho các state transition.'),
    B('**Lọc, tìm kiếm, phân trang qua query string:** `?status=PENDING,CONFIRMED&checkInFrom=2026-09-04&search=BK-12&page=1&limit=20`.'),
    B('**Dữ liệu vào/ra là JSON** (trừ tải ảnh dùng `multipart/form-data` và luồng SSE dùng `text/event-stream`).'),
    B('**Không xử lý nghiệp vụ trong Controller:** Controller chỉ nhận DTO đã validate, gọi một phương thức Service và trả kết quả.'),

    H2('3.2. HTTP Method và mã trạng thái'),
    ...tableWithCaption(
      3,
      'Quy ước sử dụng HTTP Method',
      ['Method', 'Ngữ nghĩa', 'Ví dụ trong hệ thống', 'Mã thành công'],
      [
        ['GET', 'Đọc tài nguyên, không thay đổi dữ liệu (an toàn, idempotent)', 'GET /rooms, GET /bookings/{id}', '200 OK'],
        ['POST', 'Tạo tài nguyên mới hoặc thực thi hành động', 'POST /bookings, POST /bookings/{id}/check-in', '201 Created'],
        ['PUT', 'Thay thế toàn bộ tài nguyên', 'PUT /rooms/{id}', '200 OK'],
        ['PATCH', 'Cập nhật một phần tài nguyên / chuyển trạng thái', 'PATCH /users/me, PATCH /rooms/{id}/status', '200 OK'],
        ['DELETE', 'Xóa (hoặc vô hiệu hóa) tài nguyên', 'DELETE /services/{id}, DELETE /users/{id}', '200 OK'],
      ],
      [1.2, 3.6, 3.6, 1.6],
      { center: [0, 3] },
    ),
    ...tableWithCaption(
      3,
      'Mã trạng thái HTTP được sử dụng',
      ['Mã', 'Ý nghĩa', 'Khi nào xảy ra'],
      [
        ['200 OK', 'Thành công', 'Đọc / cập nhật / xóa thành công'],
        ['201 Created', 'Đã tạo', 'Tạo đơn, tạo dịch vụ, đăng ký, các hành động POST'],
        ['400 Bad Request', 'Dữ liệu không hợp lệ hoặc vi phạm quy tắc nghiệp vụ', 'ValidationPipe báo lỗi DTO; check-in đơn chưa duyệt; ngày nhận ≥ ngày trả'],
        ['401 Unauthorized', 'Chưa xác thực', 'Thiếu / sai / hết hạn token; token đã đăng xuất; phiên bị thay thế (SESSION_REVOKED)'],
        ['403 Forbidden', 'Không đủ quyền', 'RolesGuard: vai trò không nằm trong @Roles(...)'],
        ['404 Not Found', 'Không tìm thấy', 'ID không tồn tại; Prisma P2025'],
        ['409 Conflict', 'Xung đột dữ liệu', 'Email đã đăng ký; đặt trùng lịch phòng; vi phạm UNIQUE (Prisma P2002)'],
        ['500 Internal Server Error', 'Lỗi máy chủ', 'Lỗi ngoài dự kiến, được log đầy đủ stack trace'],
      ],
      [2.2, 3, 5],
    ),

    H2('3.3. Định dạng phản hồi JSON'),
    P('Mọi phản hồi đều có cùng một “phong bì” (envelope). `TransformInterceptor` bọc dữ liệu trả về từ Controller khi thành công; `AllExceptionsFilter` chuẩn hóa mọi lỗi (HttpException, lỗi Prisma, lỗi bất ngờ) theo cùng cấu trúc, nên client chỉ cần một bộ phân tích phản hồi duy nhất.'),
    ...code(
      `{
  "statusCode": 200,
  "success": true,
  "message": "Thành công",
  "data": { ... },
  "timestamp": "2026-10-20T08:00:00.000Z"
}`,
      'Phản hồi thành công:',
    ),
    ...code(
      `{
  "statusCode": 400,
  "success": false,
  "message": "Email không đúng định dạng. Mật khẩu phải có tối thiểu 6 ký tự",
  "error": "Bad Request",
  "errors": ["Email không đúng định dạng", "Mật khẩu phải có tối thiểu 6 ký tự"],
  "timestamp": "2026-10-20T08:00:00.000Z",
  "path": "/api/v1/auth/register"
}`,
      'Phản hồi lỗi (ví dụ lỗi validate):',
    ),
    P('Các API danh sách trả `data` dạng `{ data: [...], meta: { total, page, limit, totalPages } }`. Tham số `limit` tối đa 100; nếu client không gửi `page`/`limit`, API trả toàn bộ kết quả (giữ tương thích với màn hình không phân trang).'),

    H2('3.4. Authentication và Authorization'),
    H3('3.4.1. Xác thực bằng JWT'),
    ...steps([
      'Client gọi `POST /auth/login` với email và mật khẩu. Service so khớp mật khẩu bằng `bcrypt.compare`, sinh mã phiên `sessionId` và ký hai token: **access token** (thời hạn theo `JWT_EXPIRES_IN`, trên máy chủ triển khai là 86.400 giây = 1 ngày) và **refresh token** (7 ngày).',
      'Client gửi access token trong header `Authorization: Bearer <token>` ở mọi request cần đăng nhập.',
      '`JwtAuthGuard` → `JwtStrategy.validate()`: kiểm tra chữ ký và hạn token, kiểm tra token có trong **blacklist Redis** (đã đăng xuất) không, nạp người dùng (cache Redis 30 giây), từ chối tài khoản bị khóa và kiểm tra `sid` trong token khớp `activeSessionId` (chính sách một thiết bị cho khách hàng).',
      'Khi access token hết hạn, client gọi `POST /auth/refresh-token`; server thu hồi refresh token cũ và cấp **cặp token mới** (token rotation).',
      '`POST /auth/logout` đưa access token vào blacklist, thu hồi refresh token và xóa `activeSessionId`.',
    ]),
    H3('3.4.2. Phân quyền theo vai trò (RBAC)'),
    P('Quyền truy cập được khai báo ngay trên từng route bằng decorator, tách hoàn toàn khỏi nghiệp vụ:'),
    ...code(
      `@ApiTags('Bookings (Đặt phòng & Lưu trú)')
@UseGuards(JwtAuthGuard, RolesGuard)          // áp dụng cho cả controller
@Controller('bookings')
export class BookingsController {
  @Roles(Role.ADMIN, Role.RECEPTIONIST)        // chỉ nhân viên được check-in
  @Post(':id/check-in')
  checkIn(@Param('id') id: string) {
    return this.bookingsService.checkIn(id);
  }
}`,
      'Khai báo quyền trên route:',
    ),
    B('`@Public()` – route công khai (xem phòng, loại phòng, dịch vụ, đăng ký, đăng nhập). Nếu client vẫn gửi token, guard sẽ xác thực để trả dữ liệu phù hợp vai trò.'),
    B('Không gắn `@Roles` – mọi người dùng đã đăng nhập đều gọi được; Service tự giới hạn dữ liệu theo chủ sở hữu (ví dụ khách chỉ xem đơn và hóa đơn của chính mình).'),
    B('`@Roles(...)` – `RolesGuard` đọc metadata, so với `user.role` trong token; không khớp → **403 Forbidden**.'),

    H2('3.5. Danh sách API'),
    P(`Hệ thống có **11 controller** với **${totalRows} đường dẫn API** (100 route handler, trong đó 5 cặp là bí danh POST/PATCH dành cho tương thích client). Cột “Quyền”: **A** = ADMIN, **R** = RECEPTIONIST, **C** = CUSTOMER; “Đăng nhập” = mọi vai trò đã xác thực; “Public” = không cần token. Tất cả đường dẫn có tiền tố \`/api/v1\`.`),
    ...tableWithCaption(3, 'Danh sách API của hệ thống', ['Method', 'Endpoint', 'Mô tả', 'Quyền'], endpointRows, [1.2, 3.7, 4.3, 1.1], { size: 19, center: [0, 3] }),

    ...sampleSection(),

    H2('3.7. Tài liệu hóa API với Swagger'),
    P('Toàn bộ API được mô tả bằng decorator của `@nestjs/swagger` (`@ApiTags`, `@ApiOperation`, `@ApiQuery`, `@ApiBearerAuth`, decorator tự viết `@ApiSuccessResponse`/`@ApiErrorResponse` kèm ví dụ dữ liệu). Khi chạy máy chủ, tài liệu OpenAPI tương tác có tại `http://localhost:3000/api/docs`; người kiểm thử bấm **Authorize**, dán JWT và gọi thử trực tiếp từng API. Truy cập `/` hoặc `/api/v1` sẽ tự chuyển hướng tới trang tài liệu.'),
    ...placeholderFigure(3, 'Giao diện Swagger UI của Hotel Management API', '[Chèn ảnh chụp màn hình trang http://localhost:3000/api/docs]'),
  ];
}

// ---------------------------------------------------------------------------
// Chương 4
// ---------------------------------------------------------------------------
function chapter4() {
  return [
    H1('CHƯƠNG 4. CÀI ĐẶT HỆ THỐNG'),
    H2('4.1. Môi trường phát triển'),
    ...tableWithCaption(
      4,
      'Môi trường và công cụ',
      ['Thành phần', 'Công cụ'],
      [
        ['Ngôn ngữ / Runtime', 'TypeScript 5.7, Node.js 20'],
        ['Framework', 'NestJS 10.4 (@nestjs/core, platform-express, jwt, passport, swagger, schedule, config)'],
        ['ORM / CSDL', 'Prisma 5.22, PostgreSQL 16'],
        ['Cache / Tìm kiếm', 'Redis 7 (ioredis), Elasticsearch 8.11'],
        ['Validate', 'class-validator, class-transformer'],
        ['Tích hợp', 'Nodemailer (OTP), firebase-admin (FCM), Cloudinary / Supabase (ảnh)'],
        ['Công cụ', 'VS Code, Git/GitHub, Docker Compose, Postman, Swagger UI, Prisma Studio, pgAdmin'],
        ['Triển khai', 'Render (Docker Web Service + PostgreSQL), region Singapore'],
      ],
      [3, 7],
    ),

    H2('4.2. Cấu trúc source code'),
    ...code(
      `Hotel-Management/
├── prisma/
│   ├── schema.prisma          # Model: định nghĩa 10 bảng, enum, quan hệ, index
│   ├── migrations/            # Lịch sử thay đổi cấu trúc CSDL
│   └── seed.ts                # Dữ liệu mẫu (tài khoản, loại phòng, phòng, dịch vụ)
├── src/
│   ├── main.ts                # Khởi động: prefix /api/v1, CORS, ValidationPipe, Swagger
│   ├── app.module.ts          # Module gốc, đăng ký các module con
│   ├── common/                # Thành phần dùng chung (≈ Middleware/Helpers)
│   │   ├── decorators/        # @Public, @Roles, @CurrentUser, @ApiSuccessResponse
│   │   ├── dto/               # PaginationQueryDto
│   │   ├── filters/           # AllExceptionsFilter (≈ Exceptions/Handler)
│   │   ├── guards/            # JwtAuthGuard, RolesGuard (≈ Middleware phân quyền)
│   │   ├── interceptors/      # TransformInterceptor (chuẩn hóa JSON)
│   │   └── utils/             # pagination, revenue, room-status
│   ├── auth/                  # Module xác thực
│   │   ├── auth.controller.ts # Controller
│   │   ├── auth.service.ts    # Service (business logic)
│   │   ├── jwt.strategy.ts    # Xác minh JWT
│   │   └── dto/               # Request: LoginDto, RegisterDto, ...
│   ├── users/  room-types/  rooms/  bookings/  invoices/
│   ├── services/  shifts/  analytics/       # Các module nghiệp vụ cùng cấu trúc
│   ├── prisma/                # PrismaService – tầng truy cập dữ liệu
│   ├── redis/  elasticsearch/ # Hạ tầng cache, tìm kiếm
│   └── mail/  upload/  notifications/       # Integrations (dịch vụ bên thứ 3)
├── Dockerfile  docker-compose.yml  render.yaml
└── .env.example`,
      'Cây thư mục backend (rút gọn):',
    ),
    P('Quy mô mã nguồn: khoảng **16.400 dòng TypeScript** trong `src/`, 11 controller, 18 service, 45 lớp DTO.'),

    H3('Ánh xạ với cấu trúc phân tầng đề bài yêu cầu'),
    ...tableWithCaption(
      4,
      'Ánh xạ tầng theo đề bài sang NestJS',
      ['Tầng đề bài (Laravel / Express)', 'Hiện thực trong dự án', 'Vai trò'],
      [
        ['routes/api.php, Routes', 'Decorator @Controller(\'bookings\') + @Get/@Post/@Patch… trên phương thức; prefix toàn cục api/v1', 'Định nghĩa endpoint, ánh xạ tới Controller'],
        ['Http/Controllers/API', '*.controller.ts (11 file)', 'Nhận request, gọi Service, trả response'],
        ['Http/Requests, Validation', 'dto/*.dto.ts + ValidationPipe toàn cục', 'Validate dữ liệu đầu vào, loại bỏ trường lạ'],
        ['Http/Middleware', 'Guards (JwtAuthGuard, RolesGuard), Interceptor, compression, CORS', 'Xác thực, phân quyền, chuẩn hóa phản hồi'],
        ['Services', '*.service.ts', 'Business logic, transaction, quy tắc trạng thái'],
        ['Repositories, Interfaces', 'PrismaService (Prisma Client – Data Mapper có kiểu)', 'Truy vấn CSDL, tách khỏi Controller'],
        ['Models', 'prisma/schema.prisma → kiểu sinh tự động trong @prisma/client', 'Đại diện bảng, ánh xạ CSDL'],
        ['Exceptions', 'common/filters/http-exception.filter.ts', 'Chuyển mọi lỗi thành JSON chuẩn và mã HTTP phù hợp'],
        ['Helpers', 'common/utils, common/decorators', 'Hàm tiện ích dùng chung'],
        ['Integrations', 'mail, upload, notifications, elasticsearch, redis', 'Gọi dịch vụ bên thứ ba'],
        ['database/migrations, seeders', 'prisma/migrations, prisma/seed.ts', 'Quản lý cấu trúc và dữ liệu mẫu'],
      ],
      [3, 4, 3.2],
    ),
    P('Về tầng Repository: dự án dùng **PrismaService** (kế thừa `PrismaClient`) được inject vào Service qua Dependency Injection. Prisma Client đã đóng vai trò lớp truy cập dữ liệu có kiểu tĩnh (mỗi bảng là một đối tượng `prisma.booking`, `prisma.room`… với các phương thức `findMany`, `create`, `update`), nên Controller không bao giờ chạm tới CSDL. Nhóm chưa tách thêm lớp `*Repository` riêng cho từng module; đây là một hướng cải tiến được nêu ở Chương 5.'),

    H2('4.3. Giải thích các module'),
    ...tableWithCaption(
      4,
      'Chức năng các module',
      ['Module', 'Thành phần', 'Trách nhiệm'],
      [
        ['auth', 'AuthController, AuthService, JwtStrategy, session-policy', 'Đăng ký, đăng nhập, refresh token, quên mật khẩu (OTP), đổi mật khẩu, đăng xuất, chính sách 1 thiết bị'],
        ['users', 'UsersController, UsersService, UserEventsService', 'CRUD tài khoản, hồ sơ cá nhân, FCM token, SSE danh sách tài khoản'],
        ['room-types', 'RoomTypesController, RoomTypesService', 'CRUD loại phòng'],
        ['rooms', 'RoomsController, RoomsService, RoomEventsService', 'CRUD phòng, duyệt phòng, tìm phòng trống (cache), tìm kiếm Elasticsearch, cập nhật trạng thái, SSE trạng thái phòng'],
        ['bookings', 'BookingsController, BookingsService', 'Đặt phòng (khóa phân tán), duyệt/từ chối/hủy, check-in, đổi phòng, dịch vụ phát sinh, quyết toán & check-out'],
        ['invoices', 'InvoicesController, InvoicesService', 'Hóa đơn, sổ thu tiền, yêu cầu thanh toán, xác nhận/từ chối, hoàn tiền, tổng quan doanh thu'],
        ['services', 'ServicesController, ServicesService', 'Danh mục dịch vụ khách sạn'],
        ['shifts', 'ShiftsController, ShiftsService', 'Mở ca, tính số liệu ca, chốt ca có đối chiếu chênh lệch, lịch sử ca'],
        ['analytics', 'AnalyticsController, AnalyticsService', 'Dashboard KPI, doanh thu ngày/năm, xuất CSV, công suất theo loại phòng, hiệu suất nhân viên'],
        ['notifications', 'NotificationsService, CheckinReminderService', 'Thông báo trong app, push FCM, cron nhắc nhận phòng'],
        ['prisma / redis / elasticsearch', 'PrismaService, RedisService, ElasticsearchService', 'Kết nối CSDL, cache + khóa phân tán (Lua script), chỉ mục tìm kiếm'],
        ['mail / upload', 'MailService, UploadService', 'Gửi email OTP; tải ảnh lên Cloudinary/Supabase, dự phòng lưu cục bộ'],
      ],
      [2, 3.6, 4.6],
    ),

    H2('4.4. Minh họa xử lý nghiệp vụ'),
    H3('4.4.1. Tầng Request – validate dữ liệu đầu vào'),
    P('DTO khai báo ràng buộc bằng decorator. `ValidationPipe` toàn cục với `whitelist` và `forbidNonWhitelisted` tự loại bỏ / từ chối trường không khai báo, nên dữ liệu đến được Service luôn hợp lệ.'),
    ...code(
      `export class LoginDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  @IsNotEmpty({ message: 'Email không được để trống' })
  @Transform(({ value }) => (value ? String(value).trim().toLowerCase() : value))
  email: string;

  @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
  @MinLength(6, { message: 'Mật khẩu phải có ít nhất 6 ký tự' })
  password: string;
}

// main.ts
app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));`,
      'src/auth/dto/login.dto.ts và main.ts:',
    ),

    H3('4.4.2. Tầng Controller – mỏng, chỉ điều phối'),
    ...code(
      `@Post()
create(
  @Body() createBookingDto: CreateBookingDto,   // đã validate
  @CurrentUser('id') userId: string,            // lấy từ JWT
  @CurrentUser('role') userRole: Role,
) {
  return this.bookingsService.create(createBookingDto, userId, userRole);
}

@Get()
findAll(@CurrentUser('id') userId: string, @CurrentUser('role') userRole: Role,
        @Query() query: QueryBookingsDto) {
  // Khách hàng luôn bị khóa về đơn của chính mình, bất kể customerId gửi lên.
  return this.bookingsService.findAll(
    { ...query, ...(userRole === Role.CUSTOMER ? { customerId: userId } : {}) }, userRole);
}`,
      'src/bookings/bookings.controller.ts:',
    ),

    H3('4.4.3. Tầng Service – đặt phòng chống trùng lịch'),
    P('Đây là nghiệp vụ có rủi ro cạnh tranh cao nhất: hai khách có thể bấm đặt cùng một phòng trong cùng thời điểm. Service kết hợp **khóa phân tán Redis** (chỉ một request được xử lý cho một phòng tại một thời điểm) với **kiểm tra giao khoảng ngày** trong CSDL.'),
    ...code(
      `async create(dto: CreateBookingDto, currentUserId: string, currentUserRole: Role) {
  if (new Date(dto.checkInDate) >= new Date(dto.checkOutDate))
    throw new BadRequestException('Ngày nhận phòng phải trước ngày trả phòng');
  // Chuẩn hóa giờ nhận 14:00 và giờ trả 12:00
  const checkIn = ...; const checkOut = ...;

  // 1. Chiếm khóa phân tán trên phòng
  const lockKey = \`lock:booking:room:\${dto.roomId}\`;
  const lockToken = await this.redis.acquireLock(lockKey, 6000);
  if (!lockToken) throw new ConflictException('Phòng này đang được khách khác giữ chỗ...');

  try {
    const room = await this.prisma.room.findUnique({ where: { id: dto.roomId },
                                                     include: { roomType: true } });
    if (!room) throw new NotFoundException(\`Không tìm thấy phòng với ID: \${dto.roomId}\`);

    // 2. Kiểm tra giao lịch: [checkIn, checkOut) giao với đơn còn hiệu lực
    const conflict = await this.prisma.booking.findFirst({ where: {
      roomId: dto.roomId,
      status: { in: [PENDING, CONFIRMED, CHECKED_IN] },
      AND: [{ checkInDate: { lt: checkOut } }, { checkOutDate: { gt: checkIn } }],
    }});
    if (conflict) throw new ConflictException('Phòng này đã có khách đặt ...');

    // 3. Tính tiền và tạo đơn
    const nights = Math.max(1, Math.ceil((checkOut - checkIn) / 86_400_000));
    const booking = await this.prisma.booking.create({ data: {
      bookingCode, customerId, roomId: dto.roomId, checkInDate: checkIn,
      checkOutDate: checkOut, totalAmount: nights * room.roomType.basePrice,
      status: currentUserRole === Role.CUSTOMER ? PENDING : CONFIRMED, ... } });

    await this.syncRoomStatus(dto.roomId);             // đồng bộ trạng thái phòng
    await this.redis.delByPattern('cache:rooms:*');     // xóa cache phòng trống
    return this.toBookingResponse(booking, currentUserRole);
  } finally {
    await this.redis.releaseLock(lockKey, lockToken);   // luôn nhả khóa (Lua script)
  }
}`,
      'src/bookings/bookings.service.ts (rút gọn):',
    ),

    H3('4.4.4. Transaction – check-in và check-out'),
    P('Các thao tác thay đổi đồng thời nhiều bảng được gói trong `prisma.$transaction` để đảm bảo tính nguyên tử: hoặc tất cả thành công, hoặc không có gì thay đổi.'),
    ...code(
      `async checkIn(id: string) {
  const booking = await this.findOne(id);
  if (booking.status === BookingStatus.PENDING)
    throw new BadRequestException('Đơn đặt phòng đang ở trạng thái chờ duyệt...');
  // ... kiểm tra CANCELLED, CHECKED_IN, CHECKED_OUT

  const [updated] = await this.prisma.$transaction([
    this.prisma.booking.update({ where: { id },
      data: { status: BookingStatus.CHECKED_IN, actualCheckIn: new Date() } }),
    this.prisma.room.update({ where: { id: booking.roomId },
      data: { status: RoomStatus.OCCUPIED } }),
  ]);
  this.roomEvents.emitStatusChanged({ ...updated.room, status: RoomStatus.OCCUPIED }); // SSE
  return this.toBookingResponse(updated);
}`,
      'Check-in:',
    ),
    P('Khi check-out, Service dùng chung hàm `buildSettlement()` với API xem trước để hai con số không bao giờ lệch: tính số đêm thực tế, phát hiện trả phòng trước hạn, cộng dịch vụ đã xác nhận, trừ tiền đã thu. Nếu số tiền thu nhỏ hơn số còn phải thu → 400; nếu hợp lệ, trong một transaction: đơn → CHECKED_OUT, phòng → CLEANING, upsert hóa đơn, ghi dòng thu tiền (gắn ca trực đang mở), ghi dòng hoàn tiền nếu trả phòng sớm, rồi tính lại `paidAmount` từ sổ thu tiền.'),

    H3('4.4.5. Chốt ca – đối chiếu tiền mặt'),
    ...code(
      `const stats = await this.calculateShiftStats(shift);   // tổng thu/hoàn theo phương thức
const actualCash = roundMoney(dto.actualCash);
const cashDifference = roundMoney(actualCash - stats.expectedCash);

// Nếu tiền lệch, bắt buộc giải trình lý do
if (cashDifference !== 0 && !dto.differenceReason?.trim()) {
  throw new BadRequestException(
    \`Số tiền thực tế kiểm đếm lệch so với sổ sách (\${cashDifference}đ). \` +
    'Vui lòng nhập lý do giải trình chênh lệch quỹ (differenceReason).');
}
await this.prisma.$transaction(async (tx) => {
  await tx.payment.updateMany({ where: { shiftId: null, confirmedById: shift.staffId,
    confirmedAt: { gte: shift.startTime, lte: endTime } }, data: { shiftId: shift.id } });
  return tx.workShift.update({ where: { id: shift.id }, data: {
    status: ShiftStatus.CLOSED, endTime, actualCash, expectedCash, cashDifference, ... } });
});`,
      'src/shifts/shifts.service.ts – closeShift (rút gọn):',
    ),

    H3('4.4.6. Phân quyền và chuẩn hóa phản hồi'),
    ...code(
      `@Injectable()
export class RolesGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY,
      [context.getHandler(), context.getClass()]);
    if (!requiredRoles || requiredRoles.length === 0) return true;
    const { user } = context.switchToHttp().getRequest();
    if (!requiredRoles.some((role) => user?.role === role))
      throw new ForbiddenException(
        \`Quyền truy cập bị từ chối: Yêu cầu vai trò [\${requiredRoles.join(', ')}]\`);
    return true;
  }
}`,
      'src/common/guards/roles.guard.ts:',
    ),
    ...code(
      `export function calculatePagination(query: { page?: number; limit?: number }) {
  const isPaginated = query.page !== undefined || query.limit !== undefined;
  const page = Math.max(1, query.page ?? 1);
  const limit = Math.min(100, Math.max(1, query.limit ?? 20));
  return { isPaginated, page, limit,
           skip: isPaginated ? (page - 1) * limit : undefined,
           take: isPaginated ? limit : undefined };
}`,
      'src/common/utils/pagination.util.ts – phân trang dùng chung:',
    ),

    H2('4.5. Coding convention'),
    B('**Đặt tên:** file kebab-case theo vai trò (`bookings.service.ts`, `create-booking.dto.ts`); lớp PascalCase có hậu tố vai trò (`BookingsController`, `RolesGuard`); phương thức camelCase theo động từ nghiệp vụ (`checkIn`, `closeShift`, `recalculateInvoiceTotals`).'),
    B('**Tách module:** mỗi nghiệp vụ một thư mục gồm module, controller, service, dto; thành phần dùng chung đặt ở `common`.'),
    B('**Không trùng lặp:** phân trang (`pagination.util`), quy tắc tính doanh thu (`revenue.util`), suy diễn trạng thái phòng (`room-status.util`), bảng quyết toán (`buildSettlement`) được viết một lần và tái sử dụng.'),
    B('**Không viết logic trong Controller:** toàn bộ kiểm tra trạng thái, tính tiền, transaction nằm trong Service.'),
    B('**Comment:** các đoạn xử lý quan trọng (khóa phân tán, quy tắc tính tiền, chính sách phiên, sổ thu tiền) đều có chú thích tiếng Việt giải thích lý do.'),

    H2('4.6. Giao diện ứng dụng tiêu thụ API'),
    P('Ứng dụng Flutter `hotel_app` (thiết kế ở học phần UI/UX) là client chính của API. Mỗi màn hình chỉ hiển thị dữ liệu và gửi thao tác người dùng tới API; toàn bộ quy tắc nghiệp vụ (tính tiền, chống trùng lịch, kiểm tra trạng thái) nằm ở máy chủ như đã trình bày ở mục 4.4. Các hình dưới đây ghi rõ API mà từng màn hình gọi.'),
    ...uiFigure(4, 'man_hinh_khach_hang.png', 'Màn hình khách hàng: tìm phòng, chi tiết, đặt phòng, theo dõi đơn'),
    P('a) `GET /rooms`, `GET /room-types`; b) `GET /rooms/{id}`; c) `POST /bookings` – giao diện hiển thị lại tổng tiền và quy định đặt cọc trước khi gửi; d) `GET /bookings?page=&limit=` với bộ lọc trạng thái, nút “Hủy đơn” gọi `PATCH /bookings/{id}/cancel`.', { noIndent: true }),
    ...uiFigure(4, 'man_hinh_le_tan.png', 'Màn hình lễ tân: sơ đồ phòng, nhận phòng, đổi phòng, trả phòng'),
    P('a) `GET /rooms` + luồng SSE `GET /rooms/stream` để ô phòng đổi màu ngay khi máy khác check-in/check-out; b) `GET /bookings?status=CONFIRMED&checkInFrom=&checkInTo=` và `POST /bookings/{id}/check-in`; c) `POST /bookings/{id}/change-room`; d) `GET /bookings/{id}/checkout-preview` và `POST /bookings/{id}/check-out`.', { noIndent: true }),
    ...uiFigure(4, 'man_hinh_thu_ngan_ca_truc.png', 'Màn hình thu ngân và ca trực'),
    P('a) `GET /invoices/{id}` – bảng kê tiền phòng, dịch vụ, thuế, đã thanh toán, còn thiếu; b) `POST /invoices/{id}/pay` với phương thức tiền mặt / chuyển khoản (VietQR) / thẻ; c) `POST /shifts/open`; d) `GET /shifts/current` và `POST /shifts/close` – giao diện so sánh tiền thực tế với số liệu sổ sách do API tính.', { noIndent: true }),
    ...uiFigure(4, 'man_hinh_hoa_don_quan_tri.png', 'Hóa đơn của khách hàng và màn hình báo cáo quản trị'),
    P('a) `GET /invoices/my` và `POST /invoices/{id}/payment-requests`; b), c) `GET /analytics/dashboard`, `GET /analytics/revenue/daily?range=7`, `GET /shifts/active`.', { noIndent: true }),

    H2('4.7. Cài đặt và triển khai'),
    ...code(
      `# 1. Lấy mã nguồn
git clone https://github.com/thinhtx20/Hotel-Management.git && cd Hotel-Management
cp .env.example .env                       # điền DATABASE_URL, JWT_SECRET, SMTP...

# 2. Khởi động hạ tầng
docker compose up -d postgres redis elasticsearch

# 3. Cài đặt, tạo bảng, nạp dữ liệu mẫu
npm install
npx prisma db push                          # hoặc: psql -f hotel_db_schema.sql
npm run prisma:seed

# 4. Chạy máy chủ
npm run start:dev
# API:     http://localhost:3000/api/v1
# Swagger: http://localhost:3000/api/docs`,
      'Các bước chạy hệ thống cục bộ:',
    ),
    P('Môi trường production được triển khai trên Render theo `render.yaml`: dịch vụ web chạy bằng Dockerfile, cơ sở dữ liệu PostgreSQL được Render cấp và tự nạp `DATABASE_URL`, khóa `JWT_SECRET` được sinh ngẫu nhiên, múi giờ báo cáo đặt `Asia/Ho_Chi_Minh`.'),
    ...tableWithCaption(
      4,
      'Tài khoản mẫu sau khi seed',
      ['Vai trò', 'Email', 'Mật khẩu'],
      [
        ['ADMIN', 'admin@hotel.com', 'Admin@123'],
        ['RECEPTIONIST', 'reception@hotel.com', 'Staff@123'],
        ['RECEPTIONIST', 'cashier@hotel.com', 'Staff@123'],
        ['CUSTOMER', 'customer@hotel.com', 'Cust@123'],
      ],
      [3, 4, 3],
      { mono: [1, 2] },
    ),
  ];
}

// ---------------------------------------------------------------------------
// Chương 5
// ---------------------------------------------------------------------------
function chapter5() {
  const allCases = TEST_GROUPS.flatMap((g) => g.cases);
  const totalCases = allCases.length;
  const successCases = allCases.filter((tc) => tc.expect < 400).length;
  const errorCodes = [...new Set(allCases.filter((tc) => tc.expect >= 400).map((tc) => tc.expect))].sort().join(', ');
  const passed = TEST_RUN ? TEST_RUN.results.filter((r) => r.pass).length : 0;
  const failedResults = TEST_RUN ? TEST_RUN.results.filter((r) => !r.pass) : [];

  const testRows = [];
  TEST_GROUPS.forEach((g) => {
    const header = [g.name, '', '', '', ''];
    header.groupRow = true;
    testRows.push(header);
    g.cases.forEach((tc) => {
      const auth = tc.auth ? `Token: ${AUTH_LABEL[tc.auth]}` : 'Không token';
      // Mỗi trường body một dòng để ô bảng xuống dòng được
      const body = tc.body
        ? '\n' + (Object.keys(tc.body).length ? Object.entries(tc.body).map(([k, v]) => `${k}: ${JSON.stringify(v)}`).join('\n') : '{}')
        : '';
      const r = resultOf(tc.id);
      const actual = r ? `${r.actual} · ${r.timeMs} ms\n**${r.pass ? 'Đạt' : 'KHÔNG ĐẠT'}**` : '—';
      testRows.push([tc.id, `**${tc.name}**\n${tc.method} ${tc.path}`, `${auth}${body}`, `**${tc.expect}** – ${tc.check}`, actual]);
    });
  });

  const groupRows = TEST_GROUPS.map((g) => {
    const rs = g.cases.map((c) => resultOf(c.id)).filter(Boolean);
    const ok = rs.filter((r) => r.pass).length;
    return [g.name, String(g.cases.length), String(ok), String(rs.length - ok)];
  });
  groupRows.push(['**Tổng cộng**', `**${totalCases}**`, `**${passed}**`, `**${totalCases - passed}**`]);

  const runInfo = TEST_RUN
    ? [
        ...tableWithCaption(
          5,
          'Môi trường chạy kiểm thử API',
          ['Thông số', 'Giá trị'],
          [
            ['Máy chủ', `${TEST_RUN.baseUrl} (Render, Docker, region Singapore)`],
            ['Thời điểm chạy', formatRunTime(TEST_RUN.runAt)],
            ['Công cụ', '`tool/docx/run_api_tests.js` (Node.js fetch) – chạy đúng các kịch bản và script kiểm tra của Postman Collection'],
            ['Dữ liệu', 'Tài khoản seed (admin, lễ tân) + tài khoản khách hàng tạo mới trong lần chạy; bộ test tự dọn dữ liệu sau khi chạy'],
            ['Kết quả lưu tại', '`docs/bai_tap_lon_ktpm/ket_qua_kiem_thu_api.json` (mã HTTP, thời gian, phản hồi đã che token)'],
          ],
          [2.2, 7.8],
        ),
      ]
    : [];

  return [
    H1('CHƯƠNG 5. KIỂM THỬ VÀ ĐÁNH GIÁ'),
    H2('5.1. Phương pháp và công cụ kiểm thử'),
    B(`**Kiểm thử API hộp đen trên máy chủ thật:** ${totalCases} ca kiểm thử chia 5 nhóm, đóng gói thành Postman Collection \`Luxe_Grand_Hotel_API.postman_collection.json\`. Mỗi request có script \`pm.test\` kiểm tra mã HTTP, trường \`success\` và điều kiện nghiệp vụ; request trước lưu token/ID vào biến collection cho request sau nên có thể chạy cả bộ bằng **Collection Runner**.`),
    B('**Chạy tự động bằng script:** `run_api_tests.js` đọc cùng bộ kịch bản, gọi lần lượt từng API trên máy chủ triển khai và ghi kết quả thực tế (mã HTTP, thời gian phản hồi, thông điệp) – đây là nguồn số liệu của các bảng trong chương này.'),
    B('**Kiểm thử thủ công qua Swagger UI** cho các API tải ảnh (multipart) và luồng SSE.'),
    B('**Kiểm tra tĩnh và kiểm thử client:** biên dịch TypeScript (`tsc --noEmit`) và bộ test Flutter kiểm tra ánh xạ hợp đồng API ở ứng dụng tiêu thụ API.'),
    P('Kỹ thuật thiết kế ca kiểm thử: **phân vùng tương đương** (dữ liệu hợp lệ / không hợp lệ), **giá trị biên** (mật khẩu < 6 ký tự, đơn giá âm, ngày nhận ≥ ngày trả), **bảng quyết định cho phân quyền** (cùng một API với các vai trò khác nhau) và **kiểm thử chuyển trạng thái** (check-in đơn chưa duyệt, khách tự hủy đơn đã xác nhận, đăng nhập tài khoản đã bị khóa).'),
    P('Để không làm bẩn dữ liệu vận hành, bộ kiểm thử đặt phòng ở một ngày xa trong tương lai (không ảnh hưởng trạng thái phòng hôm nay), duyệt đơn với tiền cọc 0 đ (không phát sinh doanh thu), sau đó tự hủy đơn, xóa dịch vụ thử và vô hiệu hóa tài khoản thử.'),
    ...runInfo,

    H2('5.2. Kịch bản và kết quả kiểm thử API'),
    P('Cột “Mong đợi” được xác định từ mã nguồn (DTO, Guard, Service) trước khi chạy; cột “Thực tế” là mã HTTP và thời gian phản hồi đo được trên máy chủ.'),
    ...tableWithCaption(5, 'Kịch bản và kết quả kiểm thử API', ['Mã', 'Ca kiểm thử / Request', 'Dữ liệu vào', 'Mong đợi', 'Thực tế'], testRows, [0.8, 2.9, 2.5, 2.7, 1.3], { size: 17, center: [0, 4] }),

    H2('5.3. Tổng hợp kết quả'),
    ...tableWithCaption(5, 'Tổng hợp kết quả kiểm thử API theo nhóm', ['Nhóm chức năng', 'Số ca', 'Đạt', 'Không đạt'], groupRows, [5, 1.6, 1.6, 1.8], { center: [1, 2, 3] }),
    P(
      TEST_RUN
        ? `Kết quả: **${passed}/${totalCases} ca đạt (${Math.round((passed / totalCases) * 100)}%)**, thời gian phản hồi trung bình **${TEST_RUN.avgTimeMs} ms**/request. Bộ ca gồm ${successCases} ca luồng thành công (2xx) và ${totalCases - successCases} ca luồng lỗi (${errorCodes}) – tỷ lệ ca lỗi cao nhằm kiểm chứng các yêu cầu “chống truy cập trái phép API” và “validate dữ liệu đầu vào”.`
        : `Bộ ca gồm ${successCases} ca luồng thành công và ${totalCases - successCases} ca luồng lỗi (${errorCodes}).`,
    ),
    P('Ở lần chạy đầu, ca phê duyệt đơn báo sai do kịch bản đọc nhầm vị trí trường trạng thái (API trả về `data.booking.status`); nhóm đã sửa kịch bản và chạy lại toàn bộ. Ca không đạt còn lại là lỗi thật của hệ thống, được phân tích ở mục 5.4.'),
    ...tableWithCaption(
      5,
      'Kết quả các kiểm tra tự động khác',
      ['Hạng mục', 'Lệnh', 'Kết quả'],
      [
        ['Biên dịch backend (type-check toàn bộ src)', 'npx tsc --noEmit', '0 lỗi'],
        ['Sinh DDL từ Prisma schema', 'prisma migrate diff --from-empty', '10 bảng, 384 dòng SQL'],
        ['Test tự động ứng dụng client (49 file test)', 'flutter test', '275 / 275 test đạt (≈ 12 giây)'],
      ],
      [3.6, 3.4, 3],
      { mono: [1] },
    ),

    H2('5.4. Lỗi phát hiện qua kiểm thử'),
    ...(failedResults.some((r) => r.id === 'TC37')
      ? [
          ...tableWithCaption(
            5,
            'Báo cáo lỗi BUG-01',
            ['Mục', 'Nội dung'],
            [
              ['Ca kiểm thử', 'TC37 – Dùng lại access token sau khi đăng xuất'],
              ['Bước tái hiện', '1. Khách hàng đăng nhập, nhận access token\n2. Gọi `POST /auth/logout` với token đó → 201\n3. Gọi lại `GET /auth/me` với chính token đó'],
              ['Mong đợi', '401 Unauthorized – “Phiên làm việc đã kết thúc do đăng xuất. Vui lòng đăng nhập lại”'],
              ['Thực tế', `${resultOf('TC37').actual} OK – vẫn trả hồ sơ người dùng; token còn dùng được đến khi hết hạn (tối đa 1 ngày)`],
              ['Nguyên nhân', 'Trong `AuthService.logout()`, việc đưa token vào blacklist chỉ chạy khi `redisService.isReady` (có Redis thật). Bản triển khai trên Render không có Redis nên `RedisService` chạy ở chế độ bộ nhớ dự phòng, `isReady = false` → bước blacklist bị bỏ qua. `JwtStrategy` chỉ so khớp `sid` khi `activeSessionId` khác null, mà đăng xuất lại xóa `activeSessionId`, nên token cũ vẫn hợp lệ.'],
              ['Mức độ', 'Trung bình – ảnh hưởng yêu cầu “chống truy cập trái phép API” khi token bị lộ sau đăng xuất'],
              ['Đề xuất sửa', '1. Bỏ điều kiện `isReady` khi ghi blacklist – `RedisService.set()` đã tự lưu vào bộ nhớ khi chưa có Redis.\n2. Trong `JwtStrategy`, từ chối token có `sid` khi `activeSessionId` đã bị xóa.\n3. Bổ sung dịch vụ Redis cho môi trường Render để blacklist dùng chung giữa các instance.'],
            ],
            [2, 8],
          ),
        ]
      : [P('Không phát hiện lỗi nào trong lần chạy kiểm thử.')]),

    H2('5.5. Kết quả đạt được'),
    ...tableWithCaption(
      5,
      'Đối chiếu kết quả với tiêu chí đánh giá',
      ['Tiêu chí (trọng số)', 'Kết quả của nhóm'],
      [
        ['Chức năng hệ thống (30%)', 'Đủ nhóm chức năng người dùng (đăng ký, đăng nhập, hồ sơ, phân quyền 3 vai trò) và 12 nhóm chức năng nghiệp vụ: CRUD, tìm kiếm (SQL + Elasticsearch), phân trang, thống kê, quản lý trạng thái đơn/phòng/thanh toán/ca'],
        ['Kiến trúc RESTful API (20%)', '95 endpoint, đúng HTTP method, JSON envelope thống nhất, mã trạng thái phù hợp, version /api/v1, tài liệu Swagger'],
        ['Tổ chức source code (20%)', 'Modular monolith, phân tầng Controller – Service – Data Access, DTO validate, Guard, Filter, Interceptor; Dependency Injection'],
        ['Báo cáo và tài liệu (15%)', 'Báo cáo 5 chương; 7 sơ đồ UML; 3 sơ đồ User Flow; Swagger; Postman Collection; script SQL'],
        ['Kiểm thử', TEST_RUN ? `${passed}/${totalCases} ca kiểm thử API đạt trên máy chủ thật; 275/275 test client đạt` : '—'],
        ['Bảo mật', 'JWT + refresh rotation, RBAC, bcrypt, validate whitelist, một thiết bị/khách hàng, khóa tài khoản'],
        ['Chất lượng dữ liệu', 'Khóa phân tán chống đặt trùng, transaction cho thao tác nhiều bảng, sổ thu tiền là nguồn sự thật duy nhất'],
      ],
      [3, 7],
    ),

    H2('5.6. Hạn chế'),
    P('Qua kiểm thử và rà soát mã nguồn, nhóm nhận thấy một số điểm chưa hoàn thiện:'),
    B('**BUG-01:** access token chưa bị thu hồi sau đăng xuất khi máy chủ chạy không có Redis (mục 5.4).'),
    B('Ứng dụng client hiển thị nút “Hủy đơn” cho cả đơn CONFIRMED, trong khi API chỉ cho khách tự hủy đơn PENDING (TC31 trả 403) – cần đồng bộ quy tắc hiển thị với trường `canCancel` mà API đã trả về.'),
    B('Chưa tách lớp **Repository** riêng: Service gọi trực tiếp `PrismaService`, nên khó thay thế ORM và khó viết unit test cô lập cho Service.'),
    B('Chưa có **unit test / e2e test tự động cho backend** (Jest + Supertest); kiểm thử API hiện chạy ở mức hộp đen qua Postman và script.'),
    B('Một số điểm chưa thuần REST: `POST /auth/login` trả `201` (mặc định của NestJS cho POST) thay vì `200`; một số hành động có bí danh cả POST và PATCH (approve, confirm, reject, cancel) để tương thích client cũ.'),
    B('`POST /notifications/send` và `/notifications/broadcast` chưa giới hạn vai trò bằng `@Roles` – cần chỉ cho ADMIN.'),
    B('Cơ chế tự tạo/khôi phục **tài khoản mặc định** khi đăng nhập và giá trị `JWT_SECRET` dự phòng phục vụ môi trường demo; phải tắt khi triển khai thật.'),
    B('Số tiền đang lưu kiểu `Float`; với nghiệp vụ tài chính nên dùng kiểu `Decimal` để tránh sai số làm tròn.'),
    B('Một số Service lớn (`bookings.service.ts` khoảng 1.400 dòng, `invoices.service.ts` khoảng 1.250 dòng) nên tách nhỏ theo nghiệp vụ.'),

    H2('5.7. Hướng phát triển'),
    B('Sửa BUG-01 và bổ sung Redis cho môi trường triển khai.'),
    B('Tách tầng Repository với interface cho từng aggregate (BookingRepository, RoomRepository…) và viết unit test cho Service bằng repository giả lập; đưa bộ kiểm thử API (`run_api_tests.js`) vào CI trên GitHub Actions.'),
    B('Tích hợp cổng thanh toán trực tuyến (VNPay, MoMo, VietQR) thay cho yêu cầu chuyển khoản xác nhận thủ công.'),
    B('Tăng cường bảo mật: giới hạn tần suất (`@nestjs/throttler`), `helmet`, ghi nhật ký kiểm toán (audit log) cho thao tác tiền.'),
    B('Self check-in bằng mã QR và thông báo realtime cho bộ phận buồng phòng khi khách trả phòng (định hướng từ nghiên cứu UI/UX).'),
    B('Khi quy mô tăng, tách các module có tải lớn (bookings, invoices, notifications) thành microservice giao tiếp qua message bus như định hướng trong tài liệu kiến trúc của dự án.'),

    unnumberedTitle('KẾT LUẬN'),
    P('Bài tập lớn đã xây dựng hoàn chỉnh máy chủ RESTful API cho hệ thống quản lý khách sạn Luxe Grand Hotel, đáp ứng các yêu cầu của học phần: kiến trúc phân tầng, tổ chức mã nguồn theo module, API đúng chuẩn REST trả JSON với mã trạng thái phù hợp, xác thực JWT và phân quyền theo vai trò, validate dữ liệu đầu vào và tài liệu hóa bằng Swagger/Postman. Bên cạnh các chức năng CRUD cơ bản, hệ thống giải quyết các bài toán thực tế thu được từ khảo sát người dùng: chống đặt trùng phòng khi có truy cập đồng thời, đồng bộ trạng thái phòng thời gian thực, quyết toán tự động khi trả phòng và đối chiếu tiền mặt khi chốt ca.'),
    P('Qua đề tài, nhóm đã vận dụng được các nguyên lý thiết kế phần mềm – tách biệt trách nhiệm, Dependency Injection, nguyên tử hóa giao dịch – và các mô hình UML để mô tả kiến trúc. Những hạn chế đã nêu là cơ sở để nhóm tiếp tục hoàn thiện hệ thống.'),

    unnumberedTitle('TÀI LIỆU THAM KHẢO'),
    ...[
      'NestJS Documentation, https://docs.nestjs.com',
      'Prisma ORM Documentation, https://www.prisma.io/docs',
      'Roy T. Fielding (2000), Architectural Styles and the Design of Network-based Software Architectures, Doctoral dissertation, University of California, Irvine.',
      'RFC 9110 – HTTP Semantics, IETF, 2022.',
      'RFC 7519 – JSON Web Token (JWT), IETF, 2015.',
      'OpenAPI Specification v3, https://spec.openapis.org/oas/latest.html',
      'Martin Fowler (2002), Patterns of Enterprise Application Architecture, Addison-Wesley.',
      'Redis Documentation – Distributed Locks with Redis, https://redis.io/docs',
      'Nhóm thực hiện (2026), Báo cáo Thiết kế UI/UX – Hệ thống quản lý khách sạn toàn diện Luxe Grand Hotel.',
    ].map((t, i) => P(`[${i + 1}] ${t}`, { noIndent: true })),

    unnumberedTitle('PHỤ LỤC – DANH MỤC SẢN PHẨM NỘP'),
    ...tableWithCaption(
      'PL',
      'Danh mục sản phẩm nộp kèm báo cáo',
      ['Sản phẩm', 'Vị trí'],
      [
        ['Source code backend', 'https://github.com/thinhtx20/Hotel-Management'],
        ['Source code ứng dụng client (Flutter)', 'Thư mục hotel_app'],
        ['File database (DDL PostgreSQL)', 'docs/bai_tap_lon_ktpm/hotel_db_schema.sql (+ prisma/seed.ts để nạp dữ liệu mẫu)'],
        ['Postman Collection', 'docs/bai_tap_lon_ktpm/Luxe_Grand_Hotel_API.postman_collection.json'],
        ['Kết quả chạy kiểm thử API', 'docs/bai_tap_lon_ktpm/ket_qua_kiem_thu_api.json (chạy lại: node tool/docx/run_api_tests.js)'],
        ['Sơ đồ User Flow, ảnh giao diện', 'docs/bai_tap_lon_ktpm/hinh/'],
        ['Sơ đồ UML (nguồn draw.io + PNG)', 'docs/uml_diagrams/'],
        ['Tài liệu API trực tuyến', 'http://<host>/api/docs (Swagger UI)'],
        ['Video demo hệ thống', '[Dán link video]'],
      ],
      [3.6, 6.4],
    ),
  ];
}

function figureAndTableLists() {
  return [
    unnumberedTitle('DANH MỤC HÌNH VẼ'),
    ...figureList.map((t) => P(t, { noIndent: true, after: 60 })),
    unnumberedTitle('DANH MỤC BẢNG'),
    ...tableList.map((t) => P(t, { noIndent: true, after: 60 })),
    unnumberedTitle('DANH MỤC TỪ VIẾT TẮT'),
    T(
      ['Viết tắt', 'Ý nghĩa'],
      [
        ['API', 'Application Programming Interface – giao diện lập trình ứng dụng'],
        ['REST', 'Representational State Transfer'],
        ['JWT', 'JSON Web Token'],
        ['RBAC', 'Role-Based Access Control – phân quyền theo vai trò'],
        ['DTO', 'Data Transfer Object – đối tượng truyền dữ liệu'],
        ['ORM', 'Object-Relational Mapping'],
        ['SSE', 'Server-Sent Events – đẩy sự kiện từ máy chủ'],
        ['CRUD', 'Create, Read, Update, Delete'],
        ['OTP', 'One-Time Password – mật khẩu dùng một lần'],
        ['FCM', 'Firebase Cloud Messaging'],
        ['KPI', 'Key Performance Indicator – chỉ số hiệu suất'],
      ],
      [2, 8],
    ),
  ];
}

// ---------------------------------------------------------------------------
// Lắp ráp tài liệu
// ---------------------------------------------------------------------------
async function main() {
  // Dựng thân trước phần danh mục để thu thập đủ tên hình/bảng
  const front = frontMatter();
  const body = [...chapter1(), ...chapter2(), ...chapter3(), ...chapter4(), ...chapter5()];
  const lists = figureAndTableLists();

  const makeHeader = () =>
    new Header({
      children: [
        new Paragraph({
          alignment: AlignmentType.RIGHT,
          border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: 'C0C7D0', space: 4 } },
          children: [new TextRun({ text: 'BTL Kiến trúc và Thiết kế phần mềm – Luxe Grand Hotel RESTful API', italics: true, size: 18, font: FONT, color: '6B7280' })],
        }),
      ],
    });
  const makeFooter = () =>
    new Footer({
      children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], size: 22, font: FONT })] })],
    });

  // Tách thân tài liệu thành các section dọc / ngang tại các dấu LANDSCAPE_START / LANDSCAPE_END
  const contentSections = [];
  let current = { landscape: false, children: [] };
  for (const item of [...front, ...lists, ...body]) {
    if (item === LANDSCAPE_START || item === LANDSCAPE_END) {
      if (current.children.length) contentSections.push(current);
      current = { landscape: item === LANDSCAPE_START, children: [] };
    } else {
      current.children.push(item);
    }
  }
  if (current.children.length) contentSections.push(current);

  const headingRun = (size, color, extra = {}) => ({ font: FONT, size, bold: true, color, ...extra });
  const doc = new Document({
    creator: 'Nhóm BTL KT&TKPM',
    title: 'Báo cáo BTL Kiến trúc và Thiết kế phần mềm – Luxe Grand Hotel RESTful API',
    features: { updateFields: true },
    styles: {
      default: { document: { run: { font: FONT, size: BODY_SIZE } } },
      paragraphStyles: [
        {
          id: 'Heading1',
          name: 'Heading 1',
          basedOn: 'Normal',
          next: 'Normal',
          quickFormat: true,
          run: headingRun(30, NAVY),
          paragraph: { alignment: AlignmentType.CENTER, spacing: { before: 0, after: 300 }, outlineLevel: 0 },
        },
        {
          id: 'Heading2',
          name: 'Heading 2',
          basedOn: 'Normal',
          next: 'Normal',
          quickFormat: true,
          run: headingRun(28, NAVY),
          paragraph: { spacing: { before: 280, after: 120 }, keepNext: true, outlineLevel: 1 },
        },
        {
          id: 'Heading3',
          name: 'Heading 3',
          basedOn: 'Normal',
          next: 'Normal',
          quickFormat: true,
          run: headingRun(26, '1F2937', { italics: true }),
          paragraph: { spacing: { before: 200, after: 80 }, keepNext: true, outlineLevel: 2 },
        },
      ],
    },
    numbering: {
      config: [
        {
          reference: 'bullets',
          levels: [
            { level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } },
            { level: 1, format: LevelFormat.BULLET, text: '–', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 1080, hanging: 360 } } } },
          ],
        },
        {
          reference: 'steps',
          levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }],
        },
      ],
    },
    sections: [
      {
        properties: {
          page: {
            size: PAGE,
            margin: MARGIN,
            borders: {
              pageBorderTop: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderBottom: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderLeft: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
              pageBorderRight: { style: BorderStyle.DOUBLE, size: 6, color: NAVY, space: 24 },
            },
          },
        },
        children: coverPage(),
      },
      ...contentSections.map((sec, i) => ({
        properties: {
          page: {
            size: sec.landscape ? { ...PAGE, orientation: PageOrientation.LANDSCAPE } : PAGE,
            margin: MARGIN,
            ...(i === 0 ? { pageNumbers: { start: 1 } } : {}),
          },
        },
        headers: { default: makeHeader() },
        footers: { default: makeFooter() },
        children: sec.children,
      })),
    ],
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(OUTPUT_FILE, buffer);
  console.log(`Đã ghi ${OUTPUT_FILE}`);
  console.log(`Hình: ${figureList.length}, Bảng: ${tableList.length}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
