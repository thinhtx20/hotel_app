// UML Deployment Diagram – node «device», «executionEnvironment», «artifact» và communication path.
const { Diagram, S, STROKE } = require('./drawio');

const NODE = `shape=cube;size=12;direction=south;html=1;whiteSpace=wrap;verticalAlign=top;align=left;spacingTop=14;spacingLeft=10;fillColor=#FFFFFF;${STROKE}fontSize=12;`;

function node(d, { x, y, w, h, keyword, name, extra = '', parent }) {
  const kw = keyword ? `«${keyword}»<br>` : '';
  const ex = extra ? `<br><span style="font-size:11px">${extra}</span>` : '';
  const id = d.vertex(`${kw}<b>${name}</b>${ex}`, NODE, x, y, w, h, parent);
  return { id, x, y, w, h };
}

function artifact(d, { x, y, w, h = 56, name, extra = '', parent }) {
  const ex = extra ? `<br><span style="font-size:11px">${extra}</span>` : '';
  const id = d.vertex(
    `«artifact»<br><b>${name}</b>${ex}`,
    `rounded=0;html=1;whiteSpace=wrap;verticalAlign=top;align=left;spacingLeft=10;spacingTop=4;fillColor=#FFFFFF;${STROKE}fontSize=12;`,
    x, y, w, h, parent,
  );
  d.vertex('', `shape=note;size=5;html=1;fillColor=#FFFFFF;${STROKE}`, x + w - 22, y + 8, 12, 15, id);
  return { id, x, y, w, h };
}

// Communication path: đường liền không mũi tên, neo bằng tọa độ tuyệt đối trên mặt trước của node.
function path(d, sp, tp, label, opts = {}) {
  const style = S.line + (opts.points ? 'edgeStyle=orthogonalEdgeStyle;' : '');
  const e = d.edge(label, style, { sp, tp, points: opts.points });
  if (opts.aMult) d.edgeLabel(e, opts.aMult, -1, 10, -10, 'left');
  if (opts.bMult) d.edgeLabel(e, opts.bMult, 1, -10, -10, 'right');
  return e;
}

module.exports = function build() {
  const d = new Diagram('deployment_diagram');
  d.vertex('<b>deployment</b> Hạ tầng triển khai – Hệ thống quản lý khách sạn Luxe Grand Hotel', `${S.text}fontSize=16;`, 40, 10, 900, 26);

  // ---------- Thiết bị di động ----------
  const phone = node(d, {
    x: 40, y: 70, w: 440, h: 300, keyword: 'device', name: 'Điện thoại di động',
    extra: 'Android 10+ / iOS 15+',
  });
  const flutter = node(d, {
    x: 70, y: 160, w: 380, h: 180, keyword: 'executionEnvironment', name: 'Flutter Engine (Dart AOT)', parent: phone.id,
  });
  artifact(d, { x: 100, y: 240, w: 320, name: 'hotel_app.apk / hotel_app.ipa', extra: '{khách hàng, lễ tân, thu ngân, admin}', h: 70, parent: flutter.id });

  // ---------- Máy chủ ứng dụng ----------
  const server = node(d, {
    x: 620, y: 70, w: 620, h: 470, keyword: 'device', name: 'Application Server',
    extra: 'Render Web Service – region Singapore',
  });
  const docker = node(d, {
    x: 650, y: 160, w: 560, h: 350, keyword: 'executionEnvironment', name: 'Docker Container', extra: 'image: node:20-alpine {port = 3000}', parent: server.id,
  });
  const nodejs = node(d, {
    x: 680, y: 250, w: 500, h: 230, keyword: 'executionEnvironment', name: 'Node.js 20 Runtime', parent: docker.id,
  });
  artifact(d, { x: 710, y: 320, w: 210, name: 'dist/main.js', extra: 'NestJS (Modular Monolith)', h: 66, parent: nodejs.id });
  artifact(d, { x: 940, y: 320, w: 210, name: '@prisma/client', extra: 'sinh từ schema.prisma', h: 66, parent: nodejs.id });
  artifact(d, { x: 710, y: 400, w: 210, name: '.env', extra: 'DATABASE_URL, JWT_SECRET, …', h: 66, parent: nodejs.id });

  // ---------- Máy chủ dữ liệu ----------
  const data = node(d, {
    x: 1400, y: 70, w: 500, h: 560, keyword: 'device', name: 'Database Server',
    extra: 'Render PostgreSQL / Docker Compose',
  });
  const pg = node(d, {
    x: 1430, y: 160, w: 440, h: 140, keyword: 'executionEnvironment', name: 'PostgreSQL 16', extra: 'image: postgres:16-alpine {port = 5432}', parent: data.id,
  });
  artifact(d, { x: 1600, y: 246, w: 250, h: 48, name: 'hotel_db', extra: 'users, rooms, bookings, …', parent: pg.id });
  node(d, {
    x: 1430, y: 320, w: 440, h: 130, keyword: 'executionEnvironment', name: 'Redis 7', extra: 'image: redis:7-alpine {port = 6379}', parent: data.id,
  });
  node(d, {
    x: 1430, y: 470, w: 440, h: 130, keyword: 'executionEnvironment', name: 'Elasticsearch 8.11', extra: 'image: elasticsearch:8.11.0 {port = 9200}', parent: data.id,
  });

  // ---------- Dịch vụ đám mây bên ngoài ----------
  node(d, { x: 160, y: 680, w: 300, h: 100, keyword: 'device', name: 'Firebase Cloud Messaging', extra: 'Google Cloud' });
  node(d, { x: 620, y: 680, w: 280, h: 100, keyword: 'device', name: 'SMTP Server', extra: 'Gmail / SendGrid' });
  node(d,{ x: 960, y: 680, w: 280, h: 100, keyword: 'device', name: 'Cloudinary', extra: 'Media CDN' });

  // ---------- Communication paths ----------
  // Mặt trước của node (shape cube) lùi 12px ở cạnh phải và cạnh trên.
  path(d, [468, 150], [620, 150], '«HTTPS»<br>REST /api/v1 :443', { aMult: '*', bMult: '1' });
  path(d, [468, 300], [620, 300], '«HTTPS / SSE»<br>GET /rooms/stream', { aMult: '*', bMult: '1' });
  path(d, [1228, 236], [1430, 236], '«TCP/IP»<br>:5432');
  path(d, [1228, 391], [1430, 391], '«TCP/IP»<br>:6379');
  path(d, [1228, 515], [1430, 541], '«HTTP»<br>:9200', { points: [[1330, 515], [1330, 541]] });
  path(d, [700, 540], [330, 692], '«HTTPS»<br>FCM HTTP v1', { points: [[700, 620], [330, 620]] });
  path(d, [760, 540], [760, 692], '«SMTP/TLS»<br>:587');
  path(d, [1100, 540], [1100, 692], '«HTTPS»<br>Upload API');
  path(d, [230, 692], [230, 370], '«HTTPS»<br>push notification');

  return d;
};
