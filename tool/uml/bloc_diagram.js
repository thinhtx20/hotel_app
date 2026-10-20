// Luồng dữ liệu BLoC trong ứng dụng Flutter (ví dụ màn hình hóa đơn của thu ngân).
const { Diagram, S, STROKE } = require('./drawio');

const BOX = `rounded=1;arcSize=8;whiteSpace=wrap;html=1;fillColor=#FFFFFF;${STROKE}fontSize=12;verticalAlign=middle;`;
const FLOW = 'endArrow=block;endFill=1;endSize=8;edgeStyle=none;';

module.exports = function build() {
  const d = new Diagram('bloc_diagram');
  d.vertex('<b>Luồng dữ liệu BLoC</b> – ví dụ màn hình hóa đơn của lễ tân / thu ngân', `${S.text}fontSize=16;`, 40, 10, 900, 26);

  // Khoảng cách giữa các ô đủ rộng để nhãn mũi tên không đè lên ô
  const STEP = 440;
  const box = (label, i) => d.vertex(label, BOX, 40 + i * STEP, 120, 230, 120);
  const ui = box('<b>UI (Widget)</b><br>CashierInvoicesScreen<br><i>BlocBuilder / BlocListener</i>', 0);
  const bloc = box('<b>BLoC</b><br>InvoiceBloc<br><i>on&lt;Event&gt; → emit(State)</i>', 1);
  const repo = box('<b>Repository</b><br>InvoiceRepository<br><i>fetchInvoicesPage()</i>', 2);
  const net = box('<b>Network</b><br>DioClient<br><i>interceptor gắn JWT, chuẩn hóa lỗi</i>', 3);
  const api = d.vertex('<b>NestJS API</b><br>GET /api/v1/invoices<br>?page=&amp;limit=&amp;status=', `${BOX}dashed=1;`, 40 + 4 * STEP, 120, 230, 120);

  const req = (a, b, label) => d.edge(label, `${FLOW}exitX=1;exitY=0.3;entryX=0;entryY=0.3;`, { source: a, target: b });
  const res = (a, b, label) => d.edge(label, `${FLOW}dashed=1;exitX=0;exitY=0.7;entryX=1;entryY=0.7;`, { source: a, target: b });

  req(ui, bloc, '(1) add(<br>InvoiceFetchRequested)');
  req(bloc, repo, '(2) gọi Repository');
  req(repo, net, '(3) dio.get(...)');
  req(net, api, '(4) HTTPS<br>+ Bearer JWT');
  res(api, net, '(5) JSON<br>{success, data, meta}');
  res(net, repo, 'ApiResult');
  res(repo, bloc, '(6) List&lt;InvoiceModel&gt;');
  res(bloc, ui, '(7) emit(InvoiceState)');

  d.vertex(
    'Trạng thái màn hình nằm trong một <b>InvoiceState</b> bất biến (Equatable): danh sách, bộ lọc tab, từ khóa, trang hiện tại, cờ đang tải, lỗi.<br>' +
      'Các event khác: InvoiceRefreshRequested, InvoiceTabFilterChanged, InvoiceSearchChanged, InvoiceLoadMoreRequested, InvoicePaymentRecorded, InvoiceRefundRecorded.<br>' +
      'Các BLoC/Cubit được đăng ký tập trung trong <b>di/injection_container.dart</b> (GetIt).',
    S.note, 40, 290, 4 * STEP + 230, 70,
  );
  return d;
};
