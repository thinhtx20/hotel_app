// UML Package Diagram – kiến trúc 3 tầng (tier) và phân lớp (layer) bên trong mỗi tầng.
// Mỗi tầng vật lý là một gói «tier», mỗi lớp logic là một gói «layer»; phụ thuộc chỉ đi từ trên xuống.
const { Diagram, S, STROKE } = require('./drawio');

function pkg(d, { x, y, w, h, keyword, name, parent }) {
  const label = keyword ? `«${keyword}» ${name}` : name;
  const tab = Math.max(90, label.length * 7.2 + 24);
  const id = d.vertex(
    `<b>${label}</b>`,
    `shape=folder;tabWidth=${tab};tabHeight=22;tabPosition=left;html=1;whiteSpace=wrap;verticalAlign=top;align=left;spacingLeft=8;spacingTop=2;fillColor=#FFFFFF;${STROKE}fontSize=12;`,
    x, y, w, h, parent,
  );
  return { id, x, y, w, h };
}

function layer(d, { x, y, w, h = 92, name, body, parent, keyword = 'layer' }) {
  const id = d.vertex(
    `${keyword ? `«${keyword}»<br>` : ''}<b>${name}</b><br><span style="font-size:11px">${body}</span>`,
    `shape=folder;tabWidth=40;tabHeight=12;tabPosition=left;html=1;whiteSpace=wrap;verticalAlign=middle;align=center;spacingTop=12;spacingLeft=6;spacingRight=6;fillColor=#FFFFFF;${STROKE}fontSize=12;`,
    x, y, w, h, parent,
  );
  return { id, x, y, w, h };
}

module.exports = function build() {
  const d = new Diagram('layers_diagram');
  d.vertex('<b>pkg</b> Kiến trúc 3 tầng và phân lớp N-tầng – Luxe Grand Hotel', `${S.text}fontSize=16;`, 30, 10, 900, 26);

  const dep = (a, b, label, style = '') =>
    d.edge(label, `${S.dependency}${style}`, { source: a.id, target: b.id });
  const down = (a, b) => dep(a, b, '«use»', 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;');

  // ---------- Tầng trình bày ----------
  const t1 = pkg(d, { x: 30, y: 60, w: 460, h: 640, keyword: 'tier', name: 'Presentation Tier – hotel_app (Flutter)' });
  const lx = 60;
  const lw = 400;
  const cPres = layer(d, { x: lx, y: 110, w: lw, name: 'Presentation', body: 'features/*/screens, shared/widgets', parent: t1.id });
  const cState = layer(d, { x: lx, y: 255, w: lw, name: 'State Management', body: 'BLoC / Cubit (AuthBloc, InvoiceBloc, …)', parent: t1.id });
  const cData = layer(d, { x: lx, y: 400, w: lw, name: 'Data Access', body: 'shared/repositories, shared/models', parent: t1.id });
  const cInfra = layer(d, { x: lx, y: 545, w: lw, name: 'Infrastructure', body: 'core/network (DioClient, SseClient), core/storage', parent: t1.id });
  down(cPres, cState);
  down(cState, cData);
  down(cData, cInfra);

  // ---------- Tầng ứng dụng ----------
  const t2 = pkg(d, { x: 600, y: 60, w: 520, h: 640, keyword: 'tier', name: 'Application Tier – Hotel-Management (NestJS)' });
  const sx = 630;
  const sw = 460;
  const sApi = layer(d, { x: sx, y: 110, w: sw, name: 'API (Controller)', body: '11 controller /api/v1/*, JwtAuthGuard, RolesGuard, ValidationPipe', parent: t2.id });
  const sBiz = layer(d, { x: sx, y: 255, w: sw, name: 'Business (Domain Service)', body: 'BookingsService, InvoicesService, ShiftsService, …; RoomEventsService', parent: t2.id });
  const sData = layer(d, { x: sx, y: 400, w: sw, name: 'Data Access', body: 'PrismaService, RedisService, ElasticsearchService', parent: t2.id });
  const sInteg = layer(d, { x: sx, y: 545, w: sw, name: 'Integration', body: 'NotificationsService, MailService, UploadService', parent: t2.id });
  down(sApi, sBiz);
  down(sBiz, sData);
  dep(sBiz, sInteg, '«use»', 'exitX=0;exitY=0.8;entryX=0;entryY=0.3;edgeStyle=orthogonalEdgeStyle;');

  // ---------- Tầng dữ liệu & dịch vụ ngoài ----------
  const t3 = pkg(d, { x: 1230, y: 60, w: 380, h: 440, keyword: 'tier', name: 'Data Tier' });
  const db = layer(d, { x: 1260, y: 110, w: 320, h: 80, keyword: '', name: 'PostgreSQL 16', body: 'dữ liệu nghiệp vụ (ACID)', parent: t3.id });
  const cache = layer(d, { x: 1260, y: 225, w: 320, h: 80, keyword: '', name: 'Redis 7', body: 'cache, distributed lock', parent: t3.id });
  const search = layer(d, { x: 1260, y: 340, w: 320, h: 80, keyword: '', name: 'Elasticsearch 8.11', body: 'chỉ mục tìm kiếm phòng', parent: t3.id });
  void db; void cache; void search;
  const t4 = pkg(d, { x: 1230, y: 540, w: 380, h: 160, keyword: 'tier', name: 'External Services' });
  d.vertex('<b>Firebase Cloud Messaging</b><br>SMTP Server<br>Cloudinary CDN',
    `${S.text}align=center;verticalAlign=middle;fontSize=12;`, 1260, 590, 320, 90, t4.id);

  // ---------- Phụ thuộc giữa các tầng ----------
  dep(cInfra, sApi, '«use»<br>REST + SSE / HTTPS', 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;');
  dep(sData, t3, '«use»<br>TCP / HTTP', 'exitX=1;exitY=0.5;entryX=0;entryY=0.77;');
  dep(sInteg, t4, '«use»<br>HTTPS / SMTP', 'exitX=1;exitY=0.5;entryX=0;entryY=0.55;');

  return d;
};
