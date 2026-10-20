// Đo hiệu năng thật của Hotel-Management API và kiểm thử đặt phòng đồng thời (chống double-booking).
// Kết quả ghi ra docs/bai_tap_lon_ktpm/ket_qua_hieu_nang.json để báo cáo dùng lại.
//
// node tool/docx/run_load_test.js [baseUrl] [soRequestMoiApi] [doDongThoi]
// Bộ test tự dọn dữ liệu: hủy đơn thử, vô hiệu hóa tài khoản thử.
const fs = require('fs');
const path = require('path');

const BASE_URL = process.argv[2] || 'https://hotel-management-plsp.onrender.com/api/v1';
const REQUESTS = Number(process.argv[3] || 200);
const CONCURRENCY = Number(process.argv[4] || 10);
const PARALLEL_BOOKINGS = 10;
const OUTPUT_FILE = path.resolve(__dirname, '../../docs/bai_tap_lon_ktpm/ket_qua_hieu_nang.json');

async function call(method, url, { token, body } = {}) {
  const headers = { 'Content-Type': 'application/json', 'User-Agent': 'KTPM-Load-Test' };
  if (token) headers.Authorization = `Bearer ${token}`;
  const started = performance.now();
  const res = await fetch(BASE_URL + url, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, ms: performance.now() - started, json };
}

function percentile(sorted, p) {
  return sorted[Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1)];
}

// Gửi `total` request với tối đa `concurrency` request đang bay cùng lúc
async function loadEndpoint(name, url) {
  const latencies = [];
  let errors = 0;
  let sent = 0;
  const started = performance.now();
  async function worker() {
    while (sent < REQUESTS) {
      sent++;
      try {
        const r = await call('GET', url);
        latencies.push(r.ms);
        if (r.status >= 400) errors++;
      } catch {
        errors++;
      }
    }
  }
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  const seconds = (performance.now() - started) / 1000;
  latencies.sort((a, b) => a - b);
  const round = (n) => Math.round(n);
  return {
    name,
    url,
    requests: latencies.length,
    errors,
    throughputPerSec: +(latencies.length / seconds).toFixed(1),
    avgMs: round(latencies.reduce((a, b) => a + b, 0) / latencies.length),
    p50Ms: round(percentile(latencies, 50)),
    p95Ms: round(percentile(latencies, 95)),
    maxMs: round(latencies[latencies.length - 1]),
  };
}

async function concurrentBookingTest() {
  const email = `sv.loadtest${Date.now()}@mail.com`;
  const reg = await call('POST', '/auth/register', { body: { email, password: 'Test@123', fullName: 'Kiểm Thử Đồng Thời' } });
  const customer = reg.json.data;
  const admin = (await call('POST', '/auth/login', { body: { email: 'admin@hotel.com', password: 'Admin@123' } })).json.data.accessToken;
  const reception = (await call('POST', '/auth/login', { body: { email: 'reception@hotel.com', password: 'Staff@123' } })).json.data.accessToken;

  const offset = 300 + Math.floor(Math.random() * 300);
  const checkIn = new Date(Date.now() + offset * 86400000).toISOString().slice(0, 10);
  const checkOut = new Date(Date.now() + (offset + 2) * 86400000).toISOString().slice(0, 10);
  const available = await call('GET', `/rooms/available?checkInDate=${checkIn}&checkOutDate=${checkOut}&guestCount=1`);
  const room = available.json.data[0];

  // Gửi đồng loạt N yêu cầu đặt cùng một phòng, cùng khoảng ngày
  const results = await Promise.all(
    Array.from({ length: PARALLEL_BOOKINGS }, () =>
      call('POST', '/bookings', { token: customer.accessToken, body: { roomId: room.id, checkInDate: checkIn, checkOutDate: checkOut } }),
    ),
  );
  const created = results.filter((r) => r.status === 201);
  const statusCount = results.reduce((acc, r) => ({ ...acc, [r.status]: (acc[r.status] || 0) + 1 }), {});
  const messages = [...new Set(results.filter((r) => r.status !== 201).map((r) => r.json.message))];

  // Đối chiếu trong CSDL: số đơn còn hiệu lực của phòng trong khoảng ngày này
  const list = await call('GET', `/bookings?roomId=${room.id}&checkInFrom=${checkIn}&checkInTo=${checkIn}&page=1&limit=50`, { token: reception });
  const activeInDb = list.json.data.data.filter((b) => b.status !== 'CANCELLED').length;

  // Dọn dữ liệu
  for (const c of created) {
    await call('PATCH', `/bookings/${c.json.data.id}/cancel`, { token: reception, body: { cancellationReason: 'Kiểm thử đồng thời – dọn dữ liệu' } });
  }
  await call('DELETE', `/users/${customer.user.id}`, { token: admin });

  return {
    roomNumber: room.roomNumber,
    checkIn,
    checkOut,
    parallelRequests: PARALLEL_BOOKINGS,
    statusCount,
    created: created.length,
    activeBookingsInDb: activeInDb,
    rejectMessages: messages,
  };
}

async function main() {
  const warm = performance.now();
  await call('GET', '/room-types');
  console.log(`Máy chủ sẵn sàng sau ${Math.round(performance.now() - warm)} ms`);

  const d = new Date(Date.now() + 120 * 86400000).toISOString().slice(0, 10);
  const d2 = new Date(Date.now() + 122 * 86400000).toISOString().slice(0, 10);
  const endpoints = [
    ['Danh sách loại phòng', '/room-types'],
    ['Danh sách phòng (phân trang)', '/rooms?page=1&limit=20'],
    ['Tìm phòng trống theo ngày', `/rooms/available?checkInDate=${d}&checkOutDate=${d2}&guestCount=1`],
    ['Danh mục dịch vụ', '/services'],
  ];
  const load = [];
  for (const [name, url] of endpoints) {
    const r = await loadEndpoint(name, url);
    load.push(r);
    console.log(`${name}: ${r.requests} req, lỗi ${r.errors}, ${r.throughputPerSec} req/s, avg ${r.avgMs} ms, p95 ${r.p95Ms} ms`);
  }

  const booking = await concurrentBookingTest();
  console.log('Đặt phòng đồng thời:', JSON.stringify(booking));

  const out = { baseUrl: BASE_URL, runAt: new Date().toISOString(), requestsPerEndpoint: REQUESTS, concurrency: CONCURRENCY, load, booking };
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(out, null, 2), 'utf8');
  console.log(`Đã ghi ${OUTPUT_FILE}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
