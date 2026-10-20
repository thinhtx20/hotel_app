// UML Package Diagram – cấu trúc gói của ứng dụng Flutter (lib/) và backend NestJS (src/).
// Gói có nội dung: tên nằm trên tab; gói lá: tên nằm giữa thân. Phụ thuộc «import» / «use».
const { Diagram, S, STROKE } = require('./drawio');

function pkg(d, { x, y, w, h, name, parent }) {
  const tab = Math.max(80, name.replace(/<[^>]+>/g, '').length * 7.4 + 20);
  const id = d.vertex(
    `<b>${name}</b>`,
    `shape=folder;tabWidth=${tab};tabHeight=22;tabPosition=left;html=1;whiteSpace=wrap;verticalAlign=top;align=left;spacingLeft=8;spacingTop=2;fillColor=#FFFFFF;${STROKE}fontSize=12;`,
    x, y, w, h, parent,
  );
  return { id, x, y, w, h };
}

function leaf(d, { x, y, w, h = 66, name, extra = '', parent }) {
  const ex = extra ? `<br><span style="font-size:10px">${extra}</span>` : '';
  const id = d.vertex(
    `<b>${name}</b>${ex}`,
    `shape=folder;tabWidth=36;tabHeight=12;tabPosition=left;html=1;whiteSpace=wrap;verticalAlign=middle;align=center;spacingTop=12;fillColor=#FFFFFF;${STROKE}fontSize=12;`,
    x, y, w, h, parent,
  );
  return { id, x, y, w, h };
}

module.exports = function build() {
  const d = new Diagram('package_diagram');
  d.vertex('<b>pkg</b> Kiến trúc gói – Hệ thống quản lý khách sạn Luxe Grand Hotel', `${S.text}fontSize=16;`, 30, 10, 900, 26);

  const dep = (a, b, label, style = '', points) =>
    d.edge(label, `${S.dependency}${style}`, { source: a.id, target: b.id, points });

  // ================= Flutter =================
  const app = pkg(d, { x: 30, y: 60, w: 900, h: 790, name: 'hotel_app::lib (Flutter)' });

  const features = pkg(d, { x: 70, y: 110, w: 830, h: 260, name: 'features', parent: app.id });
  ['auth', 'customer', 'receptionist', 'cashier', 'admin', 'notifications', 'profile', 'splash'].forEach((n, i) => {
    leaf(d, { x: 100 + (i % 4) * 200, y: 160 + Math.floor(i / 4) * 100, w: 175, name: n, parent: features.id });
  });

  const shared = pkg(d, { x: 70, y: 440, w: 380, h: 150, name: 'shared', parent: app.id });
  ['models', 'repositories', 'widgets'].forEach((n, i) => {
    leaf(d, { x: 90 + i * 120, y: 495, w: 108, name: n, parent: shared.id });
  });

  const core = pkg(d, { x: 520, y: 440, w: 380, h: 340, name: 'core', parent: app.id });
  ['constants', 'errors', 'network', 'router', 'services', 'session', 'storage', 'theme', 'utils'].forEach((n, i) => {
    leaf(d, { x: 540 + (i % 3) * 120, y: 495 + Math.floor(i / 3) * 92, w: 108, name: n, parent: core.id });
  });

  const di = leaf(d, { x: 160, y: 690, w: 200, h: 80, name: 'di', extra: 'injection_container.dart (GetIt)', parent: app.id });

  dep(features, shared, '«import»', 'exitX=0.23;exitY=1;entryX=0.5;entryY=0;');
  dep(features, core, '«import»', 'exitX=0.78;exitY=1;entryX=0.5;entryY=0;');
  dep(shared, core, '«import»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.24;');
  dep(di, shared, '«import»', 'exitX=0.5;exitY=0;entryX=0.4;entryY=1;');
  dep(di, core, '«import»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.86;');
  dep(di, features, '«import»', 'exitX=0;exitY=0.5;entryX=0;entryY=0.5;edgeStyle=orthogonalEdgeStyle;', [[50, 730], [50, 240]]);

  // ================= NestJS =================
  const be = pkg(d, { x: 1080, y: 60, w: 880, h: 790, name: 'Hotel-Management::src (NestJS)' });

  const common = pkg(d, { x: 1110, y: 110, w: 820, h: 150, name: 'common', parent: be.id });
  ['decorators', 'dto', 'filters', 'guards', 'interceptors', 'utils'].forEach((n, i) => {
    leaf(d, { x: 1130 + i * 132, y: 165, w: 118, name: n, parent: common.id });
  });

  const modules = pkg(d, { x: 1110, y: 330, w: 820, h: 260, name: 'Feature Modules', parent: be.id });
  const mod = {};
  const row1 = ['auth', 'users', 'room-types', 'rooms', 'bookings'];
  const row2 = [null, 'shifts', 'services', 'analytics', 'invoices'];
  row1.forEach((n, i) => {
    mod[n] = leaf(d, { x: 1130 + i * 158, y: 385, w: 140, name: n, parent: modules.id });
  });
  row2.forEach((n, i) => {
    if (n) mod[n] = leaf(d, { x: 1130 + i * 158, y: 495, w: 140, name: n, parent: modules.id });
  });
  dep(mod.bookings, mod.rooms, '«import»', 'exitX=0;exitY=0.6;entryX=1;entryY=0.6;');
  dep(mod.bookings, mod.invoices, '«import»', 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;');

  const infra = pkg(d, { x: 1110, y: 660, w: 820, h: 160, name: 'Infrastructure Modules', parent: be.id });
  ['prisma', 'redis', 'elasticsearch', 'notifications', 'mail', 'upload'].forEach((n, i) => {
    leaf(d, { x: 1130 + i * 132, y: 720, w: 118, name: n, parent: infra.id });
  });

  dep(modules, common, '«import»', 'exitX=0.5;exitY=0;entryX=0.5;entryY=1;');
  dep(modules, infra, '«import»', 'exitX=0.5;exitY=1;entryX=0.5;entryY=0;');

  // Phụ thuộc giữa hai hệ thống: tầng network gọi REST / SSE của các module nghiệp vụ
  dep(core, modules, '«use»<br>REST / SSE (HTTPS)', 'exitX=1;exitY=0.25;entryX=0;entryY=0.5;edgeStyle=orthogonalEdgeStyle;');

  return d;
};
