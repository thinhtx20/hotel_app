// UML Component Diagram – kiến trúc bus thông điệp (publish / subscribe).
// Kênh nội bộ: RoomEventsService / UserEventsService (RxJS Subject) → SSE.
// Kênh ngoài: NotificationsService → Firebase Cloud Messaging (message broker) → ứng dụng khách.
const { Diagram, S, STROKE } = require('./drawio');

function comp(d, { x, y, w, h, name, keyword = 'component', body = '' }) {
  const id = d.vertex(
    `«${keyword}»<br><b>${name}</b>${body ? `<br><span style="font-size:11px">${body}</span>` : ''}`,
    `rounded=0;html=1;whiteSpace=wrap;verticalAlign=top;align=center;fillColor=#FFFFFF;${STROKE}fontSize=12;spacingTop=4;`,
    x, y, w, h,
  );
  d.vertex('', `shape=component;jettyWidth=8;jettyHeight=4;html=1;fillColor=#FFFFFF;${STROKE}`, x + w - 24, y + 8, 14, 18, id);
  return { id, x, y, w, h };
}

// Giao diện được cung cấp dạng lollipop ở cạnh phải của thành phần
function lollipop(d, box, cy, name) {
  const bx = box.x + box.w + 40;
  d.edge('', S.line, { sp: [box.x + box.w, cy], tp: [bx, cy] });
  const ball = d.vertex('', `ellipse;html=1;fillColor=#FFFFFF;${STROKE}`, bx, cy - 8, 16, 16);
  d.vertex(name, `${S.text}align=center;fontSize=11;`, bx - 60, cy + 12, 136, 18);
  return { id: ball, x: bx, y: cy - 8, w: 16, h: 16 };
}

module.exports = function build() {
  const d = new Diagram('message_bus_diagram');
  d.vertex('<b>cmp</b> Kiến trúc bus thông điệp (publish / subscribe) – Luxe Grand Hotel', `${S.text}fontSize=16;`, 30, 10, 900, 26);

  const pub = (a, b, label, style = '') =>
    d.edge(label, `${S.dependency}${style}`, { source: a.id, target: b.id });

  // ---------- Kênh sự kiện phòng ----------
  const pBook = comp(d, { x: 40, y: 80, w: 230, h: 64, name: 'BookingsService', body: 'duyệt, check-in, check-out, đổi phòng' });
  const pRoom = comp(d, { x: 40, y: 180, w: 230, h: 64, name: 'RoomsService', body: 'tạo / sửa / xóa, đổi trạng thái' });
  const roomBus = comp(d, {
    x: 380, y: 80, w: 330, h: 164, keyword: 'message bus', name: 'RoomEventsService',
    body: 'RxJS Subject&lt;RoomEvent&gt;<br>chủ đề: room.status_changed, room.created,<br>room.updated, room.deleted<br>+ db-watcher: quét CSDL khi có subscriber',
  });
  const roomCtl = comp(d, { x: 820, y: 112, w: 230, h: 100, name: 'RoomsController', body: "@Sse('stream')<br>GET /api/v1/rooms/stream" });
  pub(pBook, roomBus, '«publish»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.2;');
  pub(pRoom, roomBus, '«publish»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.8;');
  pub(roomCtl, roomBus, '«subscribe»<br>stream()', 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;');
  const roomSse = lollipop(d, roomCtl, 162, 'IRoomEventStream (SSE)');
  const clients = [
    ['SseClient', 'RoomMatrixScreen – máy lễ tân 1'],
    ['SseClient', 'RoomMatrixScreen – máy lễ tân 2'],
    ['SseClient', 'màn hình quản trị phòng (Admin)'],
  ].map(([n, b], i) => comp(d, { x: 1240, y: 60 + i * 76, w: 260, h: 62, name: `:${n}`, body: b }));
  for (const c of clients) {
    d.edge('', `${S.dependency}exitX=0;exitY=0.5;`, { source: c.id, target: roomSse.id });
  }

  // ---------- Kênh sự kiện người dùng ----------
  const pAuth = comp(d, { x: 40, y: 320, w: 230, h: 56, name: 'AuthService', body: 'đăng ký tài khoản' });
  const pUser = comp(d, { x: 40, y: 400, w: 230, h: 56, name: 'UsersService', body: 'tạo, cập nhật, khóa tài khoản' });
  const userBus = comp(d, {
    x: 380, y: 320, w: 330, h: 136, keyword: 'message bus', name: 'UserEventsService',
    body: 'RxJS Subject&lt;UserEvent&gt;<br>user.created, user.updated, user.deactivated',
  });
  const userCtl = comp(d, { x: 820, y: 338, w: 230, h: 100, name: 'UsersController', body: "@Sse('stream')<br>GET /api/v1/users/stream" });
  pub(pAuth, userBus, '«publish»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.25;');
  pub(pUser, userBus, '«publish»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.75;');
  pub(userCtl, userBus, '«subscribe»', 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;');
  const userSse = lollipop(d, userCtl, 388, 'IUserEventStream (SSE)');
  const admin = comp(d, { x: 1240, y: 357, w: 260, h: 62, name: ':SseClient', body: 'UserManagementScreen (Admin)' });
  d.edge('', `${S.dependency}exitX=0;exitY=0.5;`, { source: admin.id, target: userSse.id });

  // ---------- Kênh thông báo đẩy qua broker ngoài ----------
  const pNotify = comp(d, {
    x: 40, y: 520, w: 230, h: 80, name: 'BookingsService<br>InvoicesService', body: 'CheckinReminderService (@Cron)',
  });
  const notify = comp(d, { x: 380, y: 528, w: 330, h: 64, name: 'NotificationsService', body: 'sendToUser(userId, payload) – Firebase Admin SDK' });
  const fcm = comp(d, { x: 820, y: 520, w: 230, h: 80, keyword: 'message broker', name: 'Firebase Cloud Messaging', body: 'hệ thống bên ngoài' });
  const app = comp(d, { x: 1240, y: 528, w: 260, h: 64, name: ':PushNotificationService', body: 'ứng dụng của khách hàng' });
  pub(pNotify, notify, '«use»', 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;');
  pub(notify, fcm, '«send»<br>FCM HTTP v1', 'exitX=1;exitY=0.5;entryX=0;entryY=0.5;');
  pub(app, fcm, '«subscribe»<br>fcmToken', 'exitX=0;exitY=0.5;entryX=1;entryY=0.5;');

  d.vertex(
    'Bên phát (publisher) không biết bên nhận (subscriber): mỗi máy lễ tân mở một kết nối SSE và nhận mọi sự kiện cùng chủ đề. ' +
      'db-watcher bắt cả thay đổi ghi thẳng vào CSDL; sự kiện trùng được lọc bằng 500 khóa gần nhất.',
    S.note, 40, 640, 1460, 46,
  );

  return d;
};
