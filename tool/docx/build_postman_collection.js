// Sinh Postman Collection (v2.1) cho Hotel-Management API từ ktpm_test_cases.js và ktpm_endpoints.js.
// Chạy: node tool/docx/build_postman_collection.js
const fs = require('fs');
const path = require('path');
const { TEST_GROUPS } = require('./ktpm_test_cases');
const { ENDPOINT_GROUPS } = require('./ktpm_endpoints');

const OUTPUT_FILE = path.resolve(__dirname, '../../docs/bai_tap_lon_ktpm/Luxe_Grand_Hotel_API.postman_collection.json');

const TOKEN_VARS = {
  admin: '{{adminToken}}',
  reception: '{{receptionToken}}',
  customer: '{{customerToken}}',
  fake: 'abc.def.ghi',
};

function buildUrl(p) {
  const [pathname, query] = p.split('?');
  const url = {
    raw: `{{baseUrl}}${p}`,
    host: ['{{baseUrl}}'],
    path: pathname.split('/').filter(Boolean),
  };
  if (query) {
    url.query = query.split('&').map((kv) => {
      const [key, value] = kv.split('=');
      return { key, value };
    });
  }
  return url;
}

function buildRequest(method, p, auth, body) {
  const header = [{ key: 'Content-Type', value: 'application/json' }];
  const request = { method, header, url: buildUrl(p) };
  if (auth && TOKEN_VARS[auth]) {
    request.auth = { type: 'bearer', bearer: [{ key: 'token', value: TOKEN_VARS[auth], type: 'string' }] };
  } else {
    request.auth = { type: 'noauth' };
  }
  if (body !== undefined) {
    request.body = { mode: 'raw', raw: JSON.stringify(body, null, 2), options: { raw: { language: 'json' } } };
  }
  return request;
}

function testItem(tc) {
  const lines = [
    `pm.test('${tc.id} - HTTP ${tc.expect}', function () { pm.response.to.have.status(${tc.expect}); });`,
    'let json = {};',
    'try { json = pm.response.json(); } catch (e) {}',
    `pm.test('${tc.id} - Response JSON có trường success', function () { pm.expect(json).to.have.property('success', ${tc.expect < 400}); });`,
  ];
  if (tc.tests) {
    lines.push(`pm.test('${tc.id} - Kiểm tra nghiệp vụ', function () {`);
    lines.push(...tc.tests.split('\n').map((l) => '  ' + l));
    lines.push('});');
  }
  if (tc.save) {
    lines.push(`if (pm.response.code === ${tc.expect}) {`);
    lines.push(...tc.save.split('\n').map((l) => '  ' + l));
    lines.push('}');
  }
  const event = [{ listen: 'test', script: { type: 'text/javascript', exec: lines } }];
  if (tc.prerequest) {
    event.unshift({ listen: 'prerequest', script: { type: 'text/javascript', exec: tc.prerequest.split('\n') } });
  }
  return {
    name: `${tc.id} - ${tc.name}`,
    event,
    request: { ...buildRequest(tc.method, tc.path, tc.auth, tc.body), description: `Kết quả mong đợi: HTTP ${tc.expect}. ${tc.check}` },
  };
}

function referenceAuth(roles) {
  if (roles === 'Public') return null;
  if (roles === 'Đăng nhập') return 'customer';
  return roles.startsWith('A') ? 'admin' : roles.startsWith('R') ? 'reception' : 'customer';
}

function referenceItem([method, p, desc, roles]) {
  const firstMethod = method.split(',')[0].replace(' (SSE)', '').trim();
  const samplePath = p.replace(/\{(\w+)\}/g, ':$1');
  const req = buildRequest(firstMethod, samplePath, referenceAuth(roles), ['POST', 'PUT', 'PATCH'].includes(firstMethod) ? {} : undefined);
  return { name: `${method} ${p}`, request: { ...req, description: `${desc}. Quyền: ${roles}` } };
}

const collection = {
  info: {
    name: 'Luxe Grand Hotel – Hotel Management API',
    description:
      'Bộ request kiểm thử RESTful API (NestJS) cho bài tập lớn Kiến trúc & Thiết kế phần mềm.\n' +
      'Chạy thư mục "Kiểm thử" theo đúng thứ tự bằng Collection Runner: các request trước lưu token/ID cho request sau.\n' +
      'Đặt biến baseUrl = http://localhost:3000/api/v1 khi chạy cục bộ.',
    schema: 'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
  },
  variable: [
    { key: 'baseUrl', value: 'http://localhost:3000/api/v1' },
    { key: 'adminToken', value: '' },
    { key: 'receptionToken', value: '' },
    { key: 'customerToken', value: '' },
    { key: 'customerRefresh', value: '' },
    { key: 'customerId', value: '' },
    { key: 'testEmail', value: '' },
    { key: 'roomId', value: '' },
    { key: 'bookingId', value: '' },
    { key: 'serviceId', value: '' },
    { key: 'serviceCode', value: '' },
    { key: 'checkIn', value: '' },
    { key: 'checkOut', value: '' },
  ],
  item: [
    {
      name: 'Kiểm thử (chạy theo thứ tự)',
      item: TEST_GROUPS.map((g) => ({ name: g.name, item: g.cases.map(testItem) })),
    },
    {
      name: 'Tài liệu tham chiếu – toàn bộ endpoint',
      item: ENDPOINT_GROUPS.map((g) => ({ name: g.title, item: g.items.map(referenceItem) })),
    },
  ],
};

fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });
fs.writeFileSync(OUTPUT_FILE, JSON.stringify(collection, null, 2), 'utf8');
const total = TEST_GROUPS.reduce((n, g) => n + g.cases.length, 0);
console.log(`Đã ghi ${OUTPUT_FILE} (${total} ca kiểm thử).`);
