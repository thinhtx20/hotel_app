// Chạy bộ kịch bản kiểm thử trong ktpm_test_cases.js trên một máy chủ API thật,
// ghi kết quả (mã HTTP thực tế, thời gian phản hồi, thông điệp, Đạt/Không đạt) ra JSON
// để báo cáo dùng lại. Script pm.* của Postman được chạy qua một lớp mô phỏng nhỏ.
//
// node tool/docx/run_api_tests.js [baseUrl]
// Mặc định: https://hotel-management-plsp.onrender.com/api/v1
const fs = require('fs');
const path = require('path');
const { TEST_GROUPS } = require('./ktpm_test_cases');

const BASE_URL = process.argv[2] || 'https://hotel-management-plsp.onrender.com/api/v1';
const OUTPUT_FILE = path.resolve(__dirname, '../../docs/bai_tap_lon_ktpm/ket_qua_kiem_thu_api.json');
const TOKEN_VARS = { admin: 'adminToken', reception: 'receptionToken', customer: 'customerToken' };

const vars = {};

function substitute(value) {
  if (typeof value === 'string') return value.replace(/\{\{(\w+)\}\}/g, (_, k) => vars[k] ?? '');
  if (Array.isArray(value)) return value.map(substitute);
  if (value && typeof value === 'object') return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, substitute(v)]));
  return value;
}

// Mô phỏng các chuỗi assert chai mà kịch bản đang dùng
function expect(actual) {
  const fail = (msg) => {
    throw new Error(msg);
  };
  const property = (negate) => (name, value) => {
    const has = actual !== null && typeof actual === 'object' && name in actual;
    if (negate && has) fail(`không được có thuộc tính "${name}"`);
    if (!negate && !has) fail(`thiếu thuộc tính "${name}"`);
    if (!negate && value !== undefined && actual[name] !== value) fail(`"${name}" = ${JSON.stringify(actual[name])}, mong đợi ${JSON.stringify(value)}`);
  };
  const typeCheck = (type) => {
    const ok = type === 'array' ? Array.isArray(actual) : typeof actual === type;
    if (!ok) fail(`kiểu ${Array.isArray(actual) ? 'array' : typeof actual}, mong đợi ${type}`);
    return {
      that: {
        is: {
          not: {
            get empty() {
              if (!actual || actual.length === 0) fail('mảng rỗng');
              return true;
            },
          },
        },
      },
    };
  };
  return {
    to: {
      eql: (v) => {
        if (JSON.stringify(actual) !== JSON.stringify(v)) fail(`nhận ${JSON.stringify(actual)}, mong đợi ${JSON.stringify(v)}`);
      },
      be: { a: typeCheck, an: typeCheck },
      have: { property: property(false) },
      not: { have: { property: property(true) } },
    },
  };
}

// Rút gọn phản hồi để lưu làm mẫu: che JWT, cắt mảng còn 2 phần tử, cắt chuỗi dài
function sanitize(value, depth = 0) {
  if (typeof value === 'string') {
    if (/^eyJ[\w-]+\.[\w-]+\.[\w-]+$/.test(value)) return value.slice(0, 20) + '…';
    return value.length > 160 ? value.slice(0, 160) + '…' : value;
  }
  if (Array.isArray(value)) return value.slice(0, 2).map((v) => sanitize(v, depth + 1));
  if (value && typeof value === 'object') {
    if (depth > 5) return '{…}';
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, sanitize(v, depth + 1)]));
  }
  return value;
}

function makePm(response) {
  const failures = [];
  return {
    failures,
    pm: {
      collectionVariables: { set: (k, v) => (vars[k] = v), get: (k) => vars[k] },
      response: { code: response?.status },
      expect,
      test: (name, fn) => {
        try {
          fn();
        } catch (e) {
          failures.push(e.message);
        }
      },
    },
  };
}

function runScript(code, pm, json) {
  if (!code) return;
  new Function('pm', 'json', code)(pm, json);
}

async function runCase(tc) {
  if (tc.prerequest) runScript(tc.prerequest, makePm(null).pm, {});
  const url = BASE_URL + substitute(tc.path);
  const headers = { 'Content-Type': 'application/json', 'User-Agent': 'KTPM-API-Test-Runner' };
  const tokenVar = TOKEN_VARS[tc.auth];
  if (tokenVar) headers.Authorization = `Bearer ${vars[tokenVar] || ''}`;
  if (tc.auth === 'fake') headers.Authorization = 'Bearer abc.def.ghi';
  const body = tc.body !== undefined ? JSON.stringify(substitute(tc.body)) : undefined;

  const started = Date.now();
  const res = await fetch(url, { method: tc.method, headers, body });
  const timeMs = Date.now() - started;
  const text = await res.text();
  let json = {};
  try {
    json = JSON.parse(text);
  } catch {
    // phản hồi không phải JSON
  }

  const { pm, failures } = makePm(res);
  if (res.status !== tc.expect) failures.push(`HTTP ${res.status}, mong đợi ${tc.expect}`);
  if (json.success !== (tc.expect < 400)) failures.push(`success = ${json.success}`);
  if (res.status === tc.expect) {
    try {
      runScript(tc.tests ? `pm.test('nghiệp vụ', function () {\n${tc.tests}\n});` : '', pm, json);
      runScript(tc.save, pm, json);
    } catch (e) {
      failures.push(e.message);
    }
  }

  return {
    id: tc.id,
    name: tc.name,
    method: tc.method,
    path: tc.path,
    expected: tc.expect,
    actual: res.status,
    timeMs,
    message: typeof json.message === 'string' ? json.message : '',
    pass: failures.length === 0,
    failures,
    request: body ? sanitize(JSON.parse(body)) : undefined,
    response: sanitize(json),
  };
}

async function main() {
  // Đánh thức máy chủ (gói miễn phí của Render ngủ khi không có truy cập)
  const warm = Date.now();
  await fetch(`${BASE_URL}/room-types`).catch(() => null);
  console.log(`Máy chủ sẵn sàng sau ${Date.now() - warm} ms`);

  const results = [];
  for (const group of TEST_GROUPS) {
    for (const tc of group.cases) {
      const r = await runCase(tc);
      r.group = group.name;
      results.push(r);
      console.log(`${r.pass ? 'ĐẠT ' : 'LỖI '} ${r.id} ${r.method} ${r.path} -> ${r.actual} (${r.timeMs} ms) ${r.failures.join('; ')}`);
    }
  }

  const summary = {
    baseUrl: BASE_URL,
    runAt: new Date().toISOString(),
    total: results.length,
    passed: results.filter((r) => r.pass).length,
    avgTimeMs: Math.round(results.reduce((n, r) => n + r.timeMs, 0) / results.length),
    results,
  };
  fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(summary, null, 2), 'utf8');
  console.log(`\nĐạt ${summary.passed}/${summary.total}. Kết quả: ${OUTPUT_FILE}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
