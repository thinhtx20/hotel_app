// UML Component Diagram – thành phần phần mềm của ứng dụng Flutter, API NestJS và các hệ thống ngoài.
// Ký hiệu: «component» + biểu tượng thành phần, port (ô vuông trên biên), assembly connector
// (ball-and-socket), delegation connector và phụ thuộc «use».
const { Diagram, S, STROKE } = require('./drawio');

function component(d, { x, y, w, h, name, body = '', keyword = 'component', parent }) {
  const id = d.vertex(
    `«${keyword}»<br><b>${name}</b>`,
    `rounded=0;html=1;whiteSpace=wrap;verticalAlign=top;align=center;fillColor=#FFFFFF;${STROKE}fontSize=12;spacingTop=2;`,
    x, y, w, h, parent,
  );
  d.vertex('', `shape=component;jettyWidth=8;jettyHeight=4;html=1;fillColor=#FFFFFF;${STROKE}`, x + w - 26, y + 8, 16, 20, id);
  if (body) {
    d.vertex(body, `${S.text}whiteSpace=wrap;fontSize=11;align=center;spacingLeft=6;spacingRight=6;`, x, y + 38, w, h - 40, id);
  }
  return { id, x, y, w, h };
}

function port(d, x, y) {
  return d.vertex('', `rounded=0;html=1;fillColor=#FFFFFF;${STROKE}`, x - 7, y - 7, 14, 14);
}

// Assembly connector nằm ngang: bên trái là phía "yêu cầu" (socket), bên phải là phía "cung cấp" (ball).
function assembly(d, x1, x2, y, label, labelAbove = false) {
  const mid = (x1 + x2) / 2;
  d.edge('', S.line, { sp: [x1, y], tp: [mid - 9, y] });
  d.edge('', S.line, { sp: [mid + 5, y], tp: [x2, y] });
  d.vertex('', `ellipse;html=1;fillColor=#FFFFFF;${STROKE}`, mid - 2, y - 7, 14, 14);
  d.vertex('', `shape=requiredInterface;html=1;fillColor=none;${STROKE}direction=west;`, mid - 9, y - 11, 9, 22);
  d.vertex(label, `${S.text}align=center;fontSize=11;`, mid - 80, labelAbove ? y - 44 : y + 12, 160, 30);
}

module.exports = function build() {
  const d = new Diagram('component_diagram');
  d.vertex('<b>cmp</b> Kiến trúc thành phần – Hệ thống quản lý khách sạn Luxe Grand Hotel', `${S.text}fontSize=16;`, 40, 10, 900, 26);

  // ================= Subsystem: Ứng dụng di động =================
  const app = component(d, { x: 40, y: 60, w: 540, h: 820, name: 'Hotel App (Flutter)', keyword: 'subsystem' });
  const cx = 100;
  const cw = 420;
  const pres = component(d, {
    x: cx, y: 130, w: cw, h: 100, name: 'Presentation',
    body: 'features/*/screens, shared/widgets<br>RoomMatrixScreen, CreateBookingModal, CashierInvoicesScreen, …',
  });
  const state = component(d, {
    x: cx, y: 290, w: cw, h: 90, name: 'State Management (BLoC)',
    body: 'AuthBloc, InvoiceBloc, UserBloc, TodayCheckOutsBloc, ThemeCubit',
  });
  const repo = component(d, {
    x: cx, y: 440, w: cw, h: 90, name: 'Repositories',
    body: 'BookingRepository, RoomRepository, InvoiceRepository, ShiftRepository, UserRepository, …',
  });
  const net = component(d, {
    x: cx, y: 590, w: cw, h: 90, name: 'Network',
    body: 'DioClient (JWT interceptor), SseClient (tự kết nối lại), ApiEndpoints',
  });
  const storage = component(d, {
    x: cx, y: 750, w: 200, h: 90, name: 'TokenStorage', body: 'lưu access / refresh token',
  });
  const push = component(d, {
    x: cx + 220, y: 750, w: 200, h: 90, name: 'PushNotificationService', body: 'nhận thông báo FCM',
  });

  const use = (from, to, opts = {}) => d.edge('«use»', `${S.dependency}${opts.style || ''}`, {
    source: from.id, target: to.id, points: opts.points,
  });
  use(pres, state);
  use(state, repo);
  use(repo, net);
  use(net, storage, { style: 'exitX=0.25;exitY=1;entryX=0.5;entryY=0;edgeStyle=orthogonalEdgeStyle;' });
  // Một số màn hình gọi thẳng Repository (ví dụ CreateBookingModal)
  d.edge('«use»', `${S.dependency}exitX=0;exitY=0.7;entryX=0;entryY=0.4;`, {
    source: pres.id, target: repo.id, points: [[70, 200], [70, 476]],
  });

  // Port của ứng dụng và delegation tới Network / Push
  const appRight = app.x + app.w;
  const pRest = port(d, appRight, 615);
  const pSse = port(d, appRight, 660);
  const pPush = port(d, appRight, 800);
  void pRest; void pSse; void pPush;
  const DELEG = 'endArrow=open;endFill=0;endSize=9;';
  d.edge('', DELEG, { sp: [net.x + net.w, 615], tp: [appRight - 7, 615] });
  d.edge('', DELEG, { sp: [net.x + net.w, 660], tp: [appRight - 7, 660] });
  d.edge('', DELEG, { sp: [push.x + push.w, 800], tp: [appRight - 7, 800] });

  // ================= Subsystem: API Server =================
  const api = component(d, { x: 720, y: 60, w: 920, h: 820, name: 'Hotel Management API (NestJS)', keyword: 'subsystem' });
  const c1 = 800;
  const w1 = 360;
  const guards = component(d, {
    x: c1, y: 130, w: w1, h: 90, name: 'Security & Pipeline',
    body: 'JwtAuthGuard, RolesGuard, ValidationPipe, HttpExceptionFilter, TransformInterceptor',
  });
  const ctrl = component(d, {
    x: c1, y: 280, w: w1, h: 110, name: 'REST Controllers',
    body: 'Bookings, Rooms (@Sse stream), Invoices, Shifts, Auth, Users, Analytics, Services, Upload',
  });
  const svc = component(d, {
    x: c1, y: 450, w: w1, h: 110, name: 'Domain Services',
    body: 'BookingsService, RoomsService, InvoicesService, ShiftsService, AuthService, UsersService, AnalyticsService',
  });
  const bus = component(d, {
    x: c1, y: 620, w: w1, h: 90, name: 'Realtime Event Bus',
    body: 'RoomEventsService, UserEventsService (RxJS Subject)',
  });
  const cron = component(d, {
    x: c1, y: 760, w: w1, h: 90, name: 'Scheduler',
    body: "CheckinReminderService @Cron('0 1 * * *')",
  });

  const c2 = 1270;
  const w2 = 320;
  const adapters = [
    ['PrismaService', 'Prisma ORM, $transaction', 'PostgreSQL 16', 'SQL / TCP 5432', 'database'],
    ['RedisService', 'cache, distributed lock', 'Redis 7', 'RESP / TCP 6379', 'component'],
    ['ElasticsearchService', 'chỉ mục & tìm kiếm phòng', 'Elasticsearch 8.11', 'REST / HTTP 9200', 'component'],
    ['NotificationsService', 'Firebase Admin SDK', 'Firebase Cloud Messaging', 'FCM HTTP v1', 'component'],
    ['MailService', 'Nodemailer (OTP, xác nhận)', 'SMTP Server', 'SMTP / TLS 587', 'component'],
    ['UploadService', 'Cloudinary SDK', 'Cloudinary', 'Upload API / HTTPS', 'component'],
  ];
  const apiRight = api.x + api.w;
  const ext = 1800;
  const adapterBoxes = adapters.map(([name, body, extName, iface, kw], i) => {
    const y = 110 + i * 125;
    const a = component(d, { x: c2, y, w: w2, h: 90, name, body });
    const e = component(d, { x: ext, y, w: 250, h: 90, name: extName, keyword: kw, body: 'hệ thống bên ngoài' });
    const py = y + 45;
    port(d, apiRight, py);
    d.edge('', DELEG, { sp: [a.x + a.w, py], tp: [apiRight - 7, py] });
    assembly(d, apiRight + 7, e.x, py, iface, true);
    return { a, e };
  });

  use(ctrl, guards);
  use(ctrl, svc);
  use(svc, bus);
  d.edge('«use»', `${S.dependency}exitX=0;exitY=0.8;entryX=0;entryY=0.5;`, {
    source: ctrl.id, target: bus.id, points: [[775, 368], [775, 665]],
  });
  for (const { a } of adapterBoxes) {
    d.edge('', `${S.dependency}exitX=1;exitY=0.5;entryX=0;entryY=0.5;`, { source: svc.id, target: a.id });
  }
  d.edge('«use»', `${S.dependency}exitX=1;exitY=0.5;entryX=0;entryY=0.7;`, { source: cron.id, target: adapterBoxes[3].a.id });

  // Port API phía trái + delegation tới Controllers
  const pApiRest = port(d, api.x, 615);
  const pApiSse = port(d, api.x, 660);
  void pApiRest; void pApiSse;
  d.edge('', `${DELEG}edgeStyle=orthogonalEdgeStyle;`, { sp: [api.x + 7, 615], tp: [ctrl.x, 310], points: [[745, 615], [745, 310]] });
  d.edge('', `${DELEG}edgeStyle=orthogonalEdgeStyle;`, { sp: [api.x + 7, 660], tp: [ctrl.x, 340], points: [[760, 660], [760, 340]] });

  // Assembly giữa app và API
  assembly(d, appRight + 7, api.x - 7, 615, 'IRestApi', true);
  assembly(d, appRight + 7, api.x - 7, 660, 'IRoomEventStream<br>(SSE)');

  // Ứng dụng nhận push từ Firebase: đi vòng dưới subsystem API
  const fcm = adapterBoxes[3].e;
  const yb = 930;
  d.edge('', `${S.line}edgeStyle=orthogonalEdgeStyle;`, {
    sp: [appRight + 7, 800], tp: [1130, yb], points: [[640, 800], [640, yb]],
  });
  d.vertex('', `ellipse;html=1;fillColor=#FFFFFF;${STROKE}`, 1136, yb - 7, 14, 14);
  d.vertex('', `shape=requiredInterface;html=1;fillColor=none;${STROKE}direction=west;`, 1130, yb - 11, 9, 22);
  d.edge('', `${S.line}edgeStyle=orthogonalEdgeStyle;`, {
    sp: [1150, yb], tp: [fcm.x + fcm.w, fcm.y + 45], points: [[2100, yb], [2100, fcm.y + 45]],
  });
  d.vertex('IPushMessaging (FCM)', `${S.text}align=center;fontSize=11;`, 1060, yb + 10, 160, 20);

  return d;
};
