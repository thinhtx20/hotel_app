// UML Sequence Diagram – Đặt phòng → Lễ tân phê duyệt → Check-in, đồng bộ trạng thái phòng qua SSE.
// Bám theo BookingsService.create / approve / checkIn (NestJS) và BookingRepository (Flutter).
const { Diagram, S } = require('./drawio');

const STEP = 31;
const LIFE_TOP = 116;

module.exports = function build() {
  const d = new Diagram('sequence_diagram');

  const P = [
    { name: 'Khách hàng', actor: true },
    { name: ':CreateBookingModal', stereo: 'boundary' },
    { name: ':BookingRepository' },
    { name: ':DioClient' },
    { name: ':BookingsController', stereo: 'control' },
    { name: ':BookingsService', stereo: 'control' },
    { name: ':RedisService' },
    { name: ':PrismaService' },
    { name: ':RoomEventsService' },
    { name: ':SseClient' },
    { name: ':RoomMatrixScreen', stereo: 'boundary' },
    { name: ':BookingApprovalScreen', stereo: 'boundary' },
    { name: 'Lễ tân', actor: true },
  ];
  const X0 = 90;
  const GAP = 178;
  const cx = P.map((_, i) => X0 + i * GAP);

  const frames = [];
  const bars = [];
  const msgs = [];
  const notes = [];
  const stack = P.map(() => []);
  let y = 150;
  let n = 0;

  const edgeX = (i, side) => {
    const L = stack[i].length;
    if (P[i].actor || L === 0) return cx[i];
    const left = cx[i] - 5 + (L - 1) * 6;
    return side > 0 ? left + 10 : left;
  };
  const push = (i, at) => {
    if (!P[i].actor) stack[i].push({ start: at, level: stack[i].length });
  };
  const pop = (i, at) => {
    const b = stack[i].pop();
    if (b) bars.push({ i, ...b, end: at });
  };
  const arrow = (style, label, x1, x2, yy) =>
    msgs.push({ style, label, sp: [x1, yy], tp: [x2, yy] });

  const CALL = 'endArrow=block;endFill=1;endSize=8;';
  const ASYNC = 'endArrow=open;endFill=0;endSize=9;';
  const RET = 'endArrow=open;endFill=0;endSize=9;dashed=1;dashPattern=6 4;';

  function send(style, f, t, label, activate) {
    y += STEP;
    const dir = t > f ? 1 : -1;
    const x1 = edgeX(f, dir);
    if (activate) push(t, y);
    const x2 = edgeX(t, -dir);
    arrow(style, `${++n}: ${label}`, x1, x2, y);
  }
  const call = (f, t, label) => send(CALL, f, t, label, true);
  const async = (f, t, label, activate = true) => send(ASYNC, f, t, label, activate);
  function ret(f, t, label, { keep = false } = {}) {
    y += STEP;
    const dir = t > f ? 1 : -1;
    const x1 = edgeX(f, dir);
    if (!keep) pop(f, y);
    arrow(RET, `${++n}: ${label}`, x1, edgeX(t, -dir), y);
  }
  // Thông điệp tự gọi; trả về hàm kết thúc activation lồng.
  function selfCall(i, label) {
    y += STEP;
    const x1 = edgeX(i, 1);
    push(i, y + 14);
    const x2 = edgeX(i, 1);
    msgs.push({
      style: `${CALL}align=left;verticalAlign=middle;spacingLeft=4;`,
      label: `${++n}: ${label}`,
      sp: [x1, y], tp: [x2, y + 14], points: [[x1 + 34, y], [x1 + 34, y + 14]], selfLabel: true,
    });
    y += 14;
    return () => pop(i, y + 12);
  }
  const deact = (i) => pop(i, y + 10);

  function frag(op, guard, i1, i2) {
    y += 14;
    const f = { op, i1, i2, top: y, guards: [{ y: y + 4, text: guard }], seps: [] };
    y += 16;
    frames.push(f);
    return {
      else(g) {
        y += 18;
        f.seps.push(y);
        f.guards.push({ y: y + 4, text: g });
        y += 10;
      },
      end() {
        y += 18;
        f.bottom = y;
      },
    };
  }
  function note(text, i1, i2, h) {
    y += 14;
    notes.push({ text, x: cx[i1] - 40, y, w: cx[i2] - cx[i1] + 80, h });
    y += h;
  }

  // ======================= 1. Khách hàng đặt phòng =======================
  note('<b>(1) Khách hàng đặt phòng trực tuyến</b><br>Redis distributed lock chống hai khách cùng đặt một phòng.', 8, 11, 40);
  y -= 50;
  call(0, 1, 'đặtPhòng(phòng, ngàyNhận, ngàyTrả)');
  call(1, 2, 'create(payload)');
  call(2, 3, 'post("/bookings", payload)');
  call(3, 4, 'POST /api/v1/bookings [JWT]');
  call(4, 5, 'create(dto, userId, role)');
  call(5, 6, 'acquireLock("lock:booking:room:{roomId}", 6000)');
  ret(6, 5, 'lockToken');
  const alt1 = frag('alt', '[lockToken ≠ null ∧ không có đơn trùng lịch]', 3, 7);
  call(5, 7, 'booking.findFirst(khoảng ngày giao nhau)');
  ret(7, 5, 'null');
  call(5, 7, 'booking.create(status = PENDING)');
  ret(7, 5, 'booking');
  selfCall(5, 'syncRoomStatus(roomId)')();
  call(5, 6, 'releaseLock(lockKey, lockToken)');
  ret(6, 5, 'OK');
  ret(5, 4, 'booking', { keep: true });
  ret(4, 3, '201 Created', { keep: true });
  alt1.else('[else: phòng đang bị khóa / trùng lịch]');
  ret(5, 4, 'throw ConflictException');
  ret(4, 3, '409 Conflict');
  alt1.end();
  ret(3, 2, 'Response');
  ret(2, 1, 'BookingModel | ApiError');
  ret(1, 0, 'hiển thị kết quả (đơn chờ duyệt)');

  // ======================= 2. Lễ tân phê duyệt =======================
  note('<b>(2) Lễ tân phê duyệt đơn và thu tiền cọc</b><br>Trạng thái phòng được đẩy realtime tới sơ đồ phòng.', 0, 3, 40);
  y -= 40;
  call(12, 11, 'duyệtĐơn(bookingId, tiềnCọc, phươngThức)');
  call(11, 2, 'approveBooking(id, deposit, method)');
  call(2, 3, 'patch("/bookings/{id}/approve")');
  call(3, 4, 'PATCH /api/v1/bookings/{id}/approve [JWT, RolesGuard]');
  call(4, 5, 'approve(id, dto, receptionistId)');
  call(5, 7, '$transaction(booking → CONFIRMED, upsert Invoice, Payment DEPOSIT)');
  ret(7, 5, '{ booking, invoice }');
  const endSync = selfCall(5, 'syncRoomStatus(roomId)');
  call(5, 7, 'room.update(status = RESERVED)');
  ret(7, 5, 'room');
  async(5, 8, 'emitStatusChanged(room)');
  endSync();
  const par1 = frag('par', '', 2, 12);
  async(8, 9, '«SSE» room.status_changed');
  async(9, 10, 'onRoomEvent(RESERVED)');
  selfCall(10, 'tô lại ô phòng')();
  deact(10);
  deact(9);
  deact(8);
  par1.else('');
  ret(5, 4, 'booking');
  ret(4, 3, '200 OK');
  ret(3, 2, 'Response');
  ret(2, 11, 'BookingModel');
  ret(11, 12, 'thông báo "Phê duyệt thành công"');
  par1.end();

  // ======================= 3. Check-in tại quầy =======================
  note('<b>(3) Làm thủ tục nhận phòng (check-in)</b><br>Phòng chuyển sang OCCUPIED trên mọi máy lễ tân.', 0, 3, 40);
  async(0, 12, 'xuất trình CCCD tại quầy', false);
  call(12, 10, 'chọnPhòng() và nhấn "Check-in"');
  call(10, 2, 'checkIn(id)');
  call(2, 3, 'post("/bookings/{id}/check-in")');
  call(3, 4, 'POST /api/v1/bookings/{id}/check-in [JWT, RolesGuard]');
  call(4, 5, 'checkIn(id)');
  const alt2 = frag('alt', '[booking.status = CONFIRMED]', 3, 10);
  call(5, 7, '$transaction(booking → CHECKED_IN, actualCheckIn = now(), room → OCCUPIED)');
  ret(7, 5, 'updatedBooking');
  async(5, 8, 'emitStatusChanged(room)');
  async(8, 9, '«SSE» room.status_changed');
  async(9, 10, 'onRoomEvent(OCCUPIED)');
  deact(10);
  deact(9);
  deact(8);
  ret(5, 4, 'updatedBooking', { keep: true });
  ret(4, 3, '200 OK', { keep: true });
  alt2.else('[else: PENDING / CANCELLED / đã CHECKED_IN]');
  ret(5, 4, 'throw BadRequestException');
  ret(4, 3, '400 Bad Request');
  alt2.end();
  ret(3, 2, 'Response');
  ret(2, 10, 'BookingModel | ApiError');
  ret(10, 12, 'ô phòng hiển thị OCCUPIED');
  async(12, 0, 'bàn giao thẻ phòng', false);

  const bottom = y + 40;

  // ---------- Vẽ: khung sd → lifeline → fragment → activation → thông điệp ----------
  d.vertex(
    'sd Đặt phòng, phê duyệt và check-in',
    'shape=umlFrame;whiteSpace=wrap;html=1;pointerEvents=0;width=290;height=26;fillColor=none;strokeColor=#000000;fontStyle=1;fontSize=13;align=left;spacingLeft=8;verticalAlign=top;',
    20, 20, cx[cx.length - 1] + 90 - 20, bottom + 20 - 20,
  );

  P.forEach((p, i) => {
    if (p.actor) {
      d.vertex(p.name, 'shape=umlActor;verticalLabelPosition=bottom;verticalAlign=top;html=1;outlineConnect=0;fillColor=#FFFFFF;strokeColor=#000000;fontStyle=1;fontSize=12;', cx[i] - 14, 52, 28, 46);
    } else {
      const w = Math.max(130, p.name.length * 7.6 + 18);
      const label = p.stereo ? `«${p.stereo}»<br><b>${p.name}</b>` : `<b>${p.name}</b>`;
      d.vertex(label, `rounded=0;whiteSpace=wrap;html=1;fillColor=#FFFFFF;strokeColor=#000000;fontSize=12;`, cx[i] - w / 2, 64, w, 44);
    }
    d.edge('', `${S.line}dashed=1;dashPattern=6 4;`, { sp: [cx[i], p.actor ? LIFE_TOP : 108], tp: [cx[i], bottom] });
  });

  for (const f of frames) {
    const x1 = cx[f.i1] - 70;
    const x2 = cx[f.i2] + 70;
    d.vertex(f.op, 'shape=umlFrame;whiteSpace=wrap;html=1;pointerEvents=0;width=44;height=22;fillColor=none;strokeColor=#000000;fontStyle=1;fontSize=12;align=left;spacingLeft=6;verticalAlign=top;',
      x1, f.top, x2 - x1, f.bottom - f.top);
    for (const sy of f.seps) {
      d.edge('', `${S.line}dashed=1;dashPattern=8 4;`, { sp: [x1, sy], tp: [x2, sy] });
    }
  }

  // activation bar còn mở (nếu có) đóng ở cuối
  stack.forEach((s, i) => { while (s.length) pop(i, y); });
  bars.sort((a, b) => a.level - b.level);
  for (const b of bars) {
    d.vertex('', 'rounded=0;html=1;fillColor=#FFFFFF;strokeColor=#000000;', cx[b.i] - 5 + b.level * 6, b.start, 10, Math.max(b.end - b.start, 12));
  }

  for (const m of msgs) {
    const base = m.selfLabel ? '' : 'verticalAlign=bottom;spacingBottom=1;';
    d.edge(m.label, `${base}${m.style}`, { sp: m.sp, tp: m.tp, points: m.points, labelBg: false });
  }
  // guard vẽ sau cùng để không bị lifeline / activation che
  for (const f of frames) {
    for (const g of f.guards) {
      if (g.text) d.vertex(g.text, `${S.text}fontSize=11;fontStyle=2;labelBackgroundColor=#FFFFFF;`, cx[f.i1] - 20, g.y - 3, 400, 18);
    }
  }
  for (const nt of notes) {
    d.vertex(nt.text, S.note, nt.x, nt.y, nt.w, nt.h);
  }

  return d;
};
