// UML Use Case Diagram – tác nhân, ranh giới hệ thống, use case và quan hệ tổng quát hóa.
const { Diagram, S, STROKE } = require('./drawio');

const ACTOR = `shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#FFFFFF;${STROKE}fontSize=12;fontStyle=1;`;
const USECASE = `ellipse;whiteSpace=wrap;html=1;fillColor=#FFFFFF;${STROKE}fontSize=12;`;
const ROW_H = 66;
const TOP = 110;

module.exports = function build() {
  const d = new Diagram('usecase_diagram');
  d.vertex('<b>uc</b> Use Case tổng thể – Hệ thống quản lý khách sạn Luxe Grand Hotel', `${S.text}fontSize=16;`, 40, 10, 900, 26);

  const left = [
    'Đăng ký tài khoản',
    'Tìm phòng trống theo ngày',
    'Xem chi tiết phòng',
    'Đăng nhập / Quên mật khẩu (OTP)',
    'Quản lý hồ sơ cá nhân',
    'Đặt phòng',
    'Hủy đơn đang chờ duyệt',
    'Theo dõi đơn đặt phòng',
    'Gọi dịch vụ tại phòng',
    'Xem hóa đơn, gửi yêu cầu thanh toán',
    'Nhận thông báo',
    'Nhắc lịch nhận phòng',
  ];
  const right = [
    'Duyệt / từ chối đơn đặt phòng',
    'Xem sơ đồ phòng realtime',
    'Check-in / nhận khách walk-in',
    'Đổi phòng',
    'Ghi nhận dịch vụ phát sinh',
    'Check-out và quyết toán',
    'Xác nhận / từ chối thanh toán, hoàn tiền',
    'Mở ca / chốt ca trực',
    'Cập nhật trạng thái phòng',
    'Quản lý loại phòng, phòng',
    'Quản lý danh mục dịch vụ',
    'Quản lý tài khoản, phân quyền',
    'Xem báo cáo doanh thu, thống kê',
    'Chốt hộ ca trực của nhân viên',
  ];

  const rows = Math.max(left.length, right.length);
  d.vertex('Hệ thống Luxe Grand Hotel', `rounded=0;whiteSpace=wrap;html=1;fillColor=none;${STROKE}verticalAlign=top;align=center;fontStyle=1;fontSize=13;spacingTop=6;`, 230, 60, 880, rows * ROW_H + 80);

  const uc = (label, x, i) => d.vertex(label, USECASE, x, TOP + i * ROW_H, 320, 50);
  const L = left.map((t, i) => uc(t, 270, i));
  const R = right.map((t, i) => uc(t, 750, i));

  // Tác nhân
  const actor = (name, x, y) => d.vertex(name, ACTOR, x, y, 36, 72);
  const guest = actor('Khách vãng lai', 82, TOP + 1 * ROW_H - 20);
  const customer = actor('Khách hàng', 82, TOP + 6 * ROW_H);
  const cron = actor('Bộ lập lịch (Cron)', 82, TOP + 11 * ROW_H - 30);
  const staff = actor('Lễ tân – Thu ngân', 1222, TOP + 4 * ROW_H - 10);
  const admin = actor('Quản trị viên', 1222, TOP + 11 * ROW_H - 10);

  // Nối vào mép ellipse phía tác nhân để đường không cắt qua các use case khác
  const assocL = (a, u) => d.edge('', `${S.line}entryX=0;entryY=0.5;`, { source: a, target: u });
  const assocR = (a, u) => d.edge('', `${S.line}entryX=1;entryY=0.5;`, { source: a, target: u });
  [0, 1, 2].forEach((i) => assocL(guest, L[i]));
  [3, 4, 5, 6, 7, 8, 9, 10].forEach((i) => assocL(customer, L[i]));
  assocL(cron, L[11]);
  [0, 1, 2, 3, 4, 5, 6, 7, 8].forEach((i) => assocR(staff, R[i]));
  [9, 10, 11, 12, 13].forEach((i) => assocR(admin, R[i]));

  // Tổng quát hóa: khách hàng kế thừa quyền của khách vãng lai, quản trị viên kế thừa quyền lễ tân
  // Đi vòng ra ngoài tác nhân để mũi tên không đè lên tên tác nhân
  const gy = TOP + 1 * ROW_H + 16;
  const cy = TOP + 6 * ROW_H + 26;
  d.edge('', `${S.generalization}exitX=0;exitY=0.35;entryX=0;entryY=0.5;`, { source: customer, target: guest, points: [[50, cy], [50, gy]] });
  const sy = TOP + 4 * ROW_H + 26;
  const ay = TOP + 11 * ROW_H + 16;
  d.edge('', `${S.generalization}exitX=1;exitY=0.35;entryX=1;entryY=0.5;`, { source: admin, target: staff, points: [[1290, ay], [1290, sy]] });
  // Chừa chỗ cho tên tác nhân (nhãn nằm ngoài khung hình học của shape)
  d.track(1170, TOP, 170, 10);

  d.vertex(
    'Ghi chú:<br>• Mọi use case trừ “Đăng ký”, “Tìm phòng trống”, “Xem chi tiết phòng” đều yêu cầu đăng nhập (JWT).<br>• Quản trị viên kế thừa toàn bộ use case của Lễ tân – Thu ngân.',
    S.note, 230, 60 + rows * ROW_H + 100, 880, 62,
  );
  // Lề dưới/phải để ảnh chụp không cắt mép khung ghi chú
  d.track(230, 60 + rows * ROW_H + 100, 940, 110);
  return d;
};
