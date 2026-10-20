// UML Class Diagram – mô hình miền (domain model) bám theo prisma/schema.prisma của backend.
// Khóa ngoại (…Id) không vẽ thành thuộc tính mà thể hiện bằng quan hệ kết hợp (association).
const { Diagram, S, classBox, link } = require('./drawio');

module.exports = function build() {
  const d = new Diagram('class_diagram');

  d.vertex(
    '<b>class</b> Mô hình miền – Hệ thống quản lý khách sạn Luxe Grand Hotel',
    `${S.text}fontSize=16;`, 40, 10, 900, 26,
  );

  const roomType = classBox(d, {
    x: 40, y: 60, w: 300, name: 'RoomType',
    attrs: [
      '- id: String {id}',
      '- name: String {unique}',
      '- code: String {unique}',
      '- description: String [0..1]',
      '- basePrice: Real',
      '- capacityAdults: Integer = 2',
      '- capacityChildren: Integer = 1',
      '- sizeSqM: Real [0..1]',
      '- amenities: String [*]',
      '- images: String [*]',
    ],
    ops: [],
  });

  const user = classBox(d, {
    x: 560, y: 60, w: 340, name: 'User',
    attrs: [
      '- id: String {id}',
      '- email: String {unique}',
      '- password: String',
      '- fullName: String',
      '- phone: String [0..1]',
      '- avatar: String [0..1]',
      '- role: Role = CUSTOMER',
      '- isActive: Boolean = true',
      '- activeSessionId: String [0..1]',
      '- activeDevice: String [0..1]',
      '- fcmToken: String [0..1]',
      '- lastLoginAt: DateTime [0..1]',
    ],
    ops: [
      '+ login(email: String, password: String): String',
      '+ logout()',
    ],
  });

  const shift = classBox(d, {
    x: 1500, y: 60, w: 340, name: 'WorkShift',
    attrs: [
      '- id: String {id}',
      '- shiftCode: String {unique}',
      '- shiftType: ShiftType = MORNING',
      '- deskName: String [0..1]',
      '- status: ShiftStatus = OPEN',
      '- startTime: DateTime',
      '- endTime: DateTime [0..1]',
      '- initialCash: Real = 0',
      '- expectedCash: Real [0..1]',
      '- actualCash: Real [0..1]',
      '- cashDifference: Real [0..1]',
      '- creditCardAmount: Real = 0',
      '- bankTransferAmount: Real = 0',
      '- totalRevenue: Real = 0',
      '- differenceReason: String [0..1]',
    ],
    ops: [
      '+ open(initialCash: Real)',
      '+ close(actualCash: Real, note: String)',
      '+ handover(staff: User)',
    ],
  });

  const row2 = 520;
  const room = classBox(d, {
    x: 40, y: row2, w: 300, name: 'Room',
    attrs: [
      '- id: String {id}',
      '- roomNumber: String {unique}',
      '- floor: Integer',
      '- status: RoomStatus = AVAILABLE',
      '- notes: String [0..1]',
    ],
    ops: ['+ updateStatus(status: RoomStatus)'],
  });

  const booking = classBox(d, {
    x: 560, y: row2, w: 340, name: 'Booking',
    attrs: [
      '- id: String {id}',
      '- bookingCode: String {unique}',
      '- checkInDate: DateTime',
      '- checkOutDate: DateTime',
      '- actualCheckIn: DateTime [0..1]',
      '- actualCheckOut: DateTime [0..1]',
      '- guestCount: Integer = 1',
      '- totalAmount: Real',
      '- depositAmount: Real = 0',
      '- status: BookingStatus = PENDING',
      '- specialRequests: String [0..1]',
      '- confirmedAt: DateTime [0..1]',
      '- confirmationNote: String [0..1]',
      '- cancellationReason: String [0..1]',
      '- cancelledAt: DateTime [0..1]',
    ],
    ops: [
      '+ approve(deposit: Real, method: PaymentMethod)',
      '+ reject(reason: String)',
      '+ checkIn()',
      '+ checkOut(cashier: User)',
      '+ cancel(reason: String)',
      '+ changeRoom(newRoom: Room)',
      '+ addServiceOrder(order: ExtraServiceOrder)',
    ],
  });

  const invoice = classBox(d, {
    x: 1040, y: row2, w: 300, name: 'Invoice',
    attrs: [
      '- id: String {id}',
      '- invoiceCode: String {unique}',
      '- roomAmount: Real',
      '- servicesAmount: Real = 0',
      '- discount: Real = 0',
      '- tax: Real = 0',
      '- finalAmount: Real',
      '- paidAmount: Real = 0',
      '- paymentMethod: PaymentMethod = CASH',
      '- paymentStatus: PaymentStatus = UNPAID',
      '- notes: String [0..1]',
      '- paidAt: DateTime [0..1]',
    ],
    ops: ['+ recalculateTotals()'],
  });

  const payment = classBox(d, {
    x: 1500, y: row2, w: 340, name: 'Payment',
    attrs: [
      '- id: String {id}',
      '- amount: Real',
      '- method: PaymentMethod = CASH',
      '- type: PaymentEntryType = PAYMENT',
      '- status: PaymentEntryStatus = CONFIRMED',
      '- reference: String [0..1]',
      '- note: String [0..1]',
      '- confirmedAt: DateTime [0..1]',
      '- rejectedReason: String [0..1]',
    ],
    ops: [
      '+ confirm(cashier: User)',
      '+ reject(reason: String)',
    ],
  });

  const row3 = 1010;
  const order = classBox(d, {
    x: 560, y: row3, w: 340, name: 'ExtraServiceOrder',
    attrs: [
      '- id: String {id}',
      '- serviceName: String',
      '- unitPrice: Real',
      '- quantity: Integer = 1',
      '- totalPrice: Real',
      '- status: String = "CONFIRMED"',
      '- note: String [0..1]',
      '- createdAt: DateTime',
    ],
    ops: ['+ updateStatus(status: String)'],
  });

  const service = classBox(d, {
    x: 40, y: row3, w: 300, name: 'HotelService',
    attrs: [
      '- id: String {id}',
      '- code: String {unique}',
      '- name: String',
      '- category: String',
      '- description: String [0..1]',
      '- unitPrice: Real',
      '- unit: String = "lần"',
      '- icon: String [0..1]',
      '- isAvailable: Boolean = true',
    ],
    ops: [],
  });

  // ---------- Quan hệ ----------
  const ux = (f) => user.x + user.w * f;
  const uy = (px) => user.y + px;
  const bottomU = user.y + user.h;

  // User — Booking (ba vai trò khác nhau)
  link(d, user, booking, {
    from: [ux(0.15), bottomU], to: [ux(0.15), booking.y], style: S.association,
    name: 'đặt ▾', aMult: '1', aRole: 'customer', bMult: '0..*', bRole: 'bookings',
  });
  link(d, user, booking, {
    from: [ux(0.5), bottomU], to: [ux(0.5), booking.y], style: S.association,
    name: 'xác nhận ▾', aMult: '0..1', aRole: 'confirmedBy', bMult: '0..*', bRole: '',
  });
  link(d, user, booking, {
    from: [ux(0.85), bottomU], to: [ux(0.85), booking.y], style: S.association,
    name: 'hủy ▾', aMult: '0..1', aRole: 'cancelledBy', bMult: '0..*', bRole: '',
  });

  // User — WorkShift
  link(d, user, shift, {
    from: [user.x + user.w, uy(40)], to: [shift.x, uy(40)], style: S.association,
    name: 'trực ca ▸', aMult: '1', aRole: 'staff', bMult: '0..*', bRole: 'shifts',
  });
  link(d, user, shift, {
    from: [user.x + user.w, uy(100)], to: [shift.x, uy(100)], style: S.association,
    name: 'nhận bàn giao ▸', aMult: '0..1', aRole: 'handoverStaff', bMult: '0..*', bRole: 'receivedShifts',
  });

  // User — Payment (tạo / xác nhận)
  const corridor1 = 1440;
  const corridor2 = 1400;
  link(d, user, payment, {
    from: [user.x + user.w, uy(160)], to: [payment.x + 200, payment.y], style: S.association,
    points: [[corridor1, uy(160)], [corridor1, payment.y - 50], [payment.x + 200, payment.y - 50]],
    name: 'tạo ▸', aMult: '0..1', aRole: 'createdBy', bMult: '0..*', bRole: '',
  });
  link(d, user, payment, {
    from: [user.x + user.w, uy(215)], to: [payment.x + 70, payment.y], style: S.association,
    points: [[corridor2, uy(215)], [corridor2, payment.y - 25], [payment.x + 70, payment.y - 25]],
    name: 'xác nhận ▸', aMult: '0..1', aRole: 'confirmedBy', bMult: '0..*', bRole: '',
  });

  // User — Invoice
  link(d, user, invoice, {
    from: [user.x + user.w, uy(270)], to: [invoice.x + 150, invoice.y], style: S.association,
    points: [[invoice.x + 150, uy(270)]],
    name: 'lập ▾', aMult: '0..1', aRole: 'issuedBy', bMult: '0..*', bRole: '',
  });

  // User — ExtraServiceOrder
  link(d, user, order, {
    from: [user.x, uy(250)], to: [order.x, order.y + 40], style: S.association,
    points: [[470, uy(250)], [470, order.y + 40]],
    name: 'yêu cầu ▾', aMult: '0..1', aRole: 'requestedBy', bMult: '0..*', bRole: '',
  });

  // RoomType — Room
  link(d, roomType, room, {
    from: [roomType.x + 150, roomType.y + roomType.h], to: [room.x + 150, room.y], style: S.association,
    name: 'phân loại ▾', aMult: '1', aRole: 'roomType', bMult: '0..*', bRole: 'rooms',
  });

  // Room — Booking
  const rb = room.y + 70;
  link(d, room, booking, {
    from: [room.x + room.w, rb], to: [booking.x, rb], style: S.association,
    name: 'được đặt ▸', aMult: '1', aRole: 'room', bMult: '0..*', bRole: 'bookings',
  });

  // Booking ◆— Invoice, Booking ◆— ExtraServiceOrder, Invoice ◆— Payment (xóa dây chuyền)
  const bi = booking.y + 90;
  link(d, booking, invoice, {
    from: [booking.x + booking.w, bi], to: [invoice.x, bi], style: S.composition,
    aMult: '1', aRole: 'booking', bMult: '0..1', bRole: 'invoice',
  });
  link(d, invoice, payment, {
    from: [invoice.x + invoice.w, bi], to: [payment.x, bi], style: S.composition,
    aMult: '1', aRole: 'invoice', bMult: '0..*', bRole: 'payments',
  });
  link(d, booking, order, {
    from: [booking.x + 170, booking.y + booking.h], to: [order.x + 170, order.y], style: S.composition,
    aMult: '1', aRole: 'booking', bMult: '0..*', bRole: 'serviceOrders',
  });

  // WorkShift — Payment
  link(d, shift, payment, {
    from: [shift.x + 290, shift.y + shift.h], to: [payment.x + 290, payment.y], style: S.association,
    name: 'ghi nhận ▾', aMult: '0..1', aRole: 'shift', bMult: '0..*', bRole: 'payments',
  });

  // ExtraServiceOrder ⇢ HotelService: chỉ sao chép tên & đơn giá khi gọi dịch vụ
  const dep = d.edge('«use»', S.dependency + 'edgeStyle=orthogonalEdgeStyle;', {
    source: order.id, target: service.id,
  });
  void dep;

  // ---------- Kiểu liệt kê ----------
  const enums = [
    ['Role', ['ADMIN', 'RECEPTIONIST', 'CUSTOMER']],
    ['RoomStatus', ['AVAILABLE', 'OCCUPIED', 'RESERVED', 'CLEANING', 'MAINTENANCE', 'PENDING_APPROVAL', 'REJECTED']],
    ['BookingStatus', ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED']],
    ['PaymentMethod', ['CASH', 'CREDIT_CARD', 'BANK_TRANSFER']],
    ['PaymentStatus', ['UNPAID', 'PARTIAL', 'PAID', 'REFUNDED']],
    ['PaymentEntryType', ['PAYMENT', 'DEPOSIT', 'REFUND']],
    ['PaymentEntryStatus', ['PENDING', 'CONFIRMED', 'REJECTED']],
    ['ShiftType', ['MORNING', 'AFTERNOON', 'NIGHT', 'CUSTOM']],
    ['ShiftStatus', ['OPEN', 'CLOSED']],
  ];
  const enumY = 1270;
  let ex = 40;
  for (const [name, lits] of enums) {
    const w = Math.max(150, name.length * 9 + 30, Math.max(...lits.map((l) => l.length)) * 8 + 24);
    classBox(d, { x: ex, y: enumY, w, name, stereotype: 'enumeration', attrs: lits, showOps: false });
    ex += w + 22;
  }

  d.vertex(
    'Ghi chú:<br>• Thuộc tính kiểm vết createdAt / updatedAt của các lớp được lược bỏ cho gọn.<br>' +
      '• Khóa ngoại (customerId, roomId, invoiceId, …) được biểu diễn bằng quan hệ kết hợp.<br>' +
      '• ExtraServiceOrder lưu bản sao serviceName / unitPrice của HotelService tại thời điểm gọi.',
    S.note, 1000, row3 + 10, 560, 76,
  );

  return d;
};
