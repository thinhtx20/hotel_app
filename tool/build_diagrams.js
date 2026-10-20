const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const outDir = path.resolve(__dirname, '../docs/architecture_diagrams');
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

console.log('Generating 5 Architectural Diagrams for Luxe Grand Hotel (High Quality Canvas / SVG)...');

function createHtmlWrapper(title, width, height, svgContent) {
  return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=Fira+Code:wght@500;600;700&display=swap');
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      background-color: #FFFFFF;
      margin: 0;
      padding: 0;
      width: ${width}px;
      height: ${height}px;
      overflow: hidden;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      -webkit-font-smoothing: antialiased;
    }
    svg {
      display: block;
      width: ${width}px;
      height: ${height}px;
    }
  </style>
</head>
<body>
  ${svgContent}
</body>
</html>`;
}

// Common SVG Defs
const commonDefs = `
  <defs>
    <linearGradient id="headerGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#1B365D"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="fePackageGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#F0F7FF"/>
    </linearGradient>
    <linearGradient id="bePackageGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#F0FDF4"/>
    </linearGradient>
    <linearGradient id="extPackageGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#FFFBEB"/>
    </linearGradient>

    <!-- 3D Node Gradients -->
    <linearGradient id="nodeTopGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#F1F5F9"/>
      <stop offset="100%" stop-color="#E2E8F0"/>
    </linearGradient>
    <linearGradient id="nodeSideGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#CBD5E1"/>
      <stop offset="100%" stop-color="#94A3B8"/>
    </linearGradient>

    <!-- Activation Bar Gradient -->
    <linearGradient id="actGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#EFF6FF"/>
      <stop offset="100%" stop-color="#DBEAFE"/>
    </linearGradient>

    <filter id="shadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="4" stdDeviation="6" flood-color="#0F172A" flood-opacity="0.08"/>
    </filter>
    <filter id="cardShadow" x="-5%" y="-5%" width="110%" height="110%">
      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="#0F172A" flood-opacity="0.05"/>
    </filter>

    <!-- Component Icon Definition -->
    <g id="compIcon">
      <rect x="0" y="0" width="22" height="16" fill="#F8FAFC" stroke="#475569" stroke-width="1.5"/>
      <rect x="-4" y="2" width="8" height="4" fill="#E2E8F0" stroke="#475569" stroke-width="1.2"/>
      <rect x="-4" y="9" width="8" height="4" fill="#E2E8F0" stroke="#475569" stroke-width="1.2"/>
    </g>

    <!-- Artifact Corner Icon -->
    <g id="artifactIcon">
      <path d="M 0 0 L 16 0 L 22 6 L 22 26 L 0 26 Z" fill="#F1F5F9" stroke="#475569" stroke-width="1.5"/>
      <path d="M 16 0 L 16 6 L 22 6 Z" fill="#CBD5E1" stroke="#475569" stroke-width="1.2"/>
    </g>

    <marker id="depArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#D97706"/>
    </marker>
    <marker id="depArrowBlue" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#2563EB"/>
    </marker>
    <marker id="depArrowEmerald" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#059669"/>
    </marker>
    <marker id="assocArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#1E293B"/>
    </marker>
    <marker id="compDiamond" viewBox="0 0 16 10" refX="0" refY="5" markerWidth="14" markerHeight="9" orient="auto">
      <polygon points="0,5 7,0 14,5 7,10" fill="#1E293B"/>
    </marker>
    <marker id="syncArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <polygon points="0,1 10,5 0,9" fill="#1E293B"/>
    </marker>
    <marker id="asyncArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <polyline points="0,1 10,5 0,9" fill="none" stroke="#D97706" stroke-width="2"/>
    </marker>
    <marker id="replyArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <polyline points="0,1 10,5 0,9" fill="none" stroke="#64748B" stroke-width="1.8"/>
    </marker>
  </defs>
`;

// =============================================================
// DIAGRAM 1: PACKAGE DIAGRAM
// =============================================================
function generatePackageDiagram() {
  const width = 2200;
  const height = 1400;

  const svg = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  ${commonDefs}

  <!-- Header Banner -->
  <rect x="0" y="0" width="${width}" height="90" rx="8" fill="url(#headerGrad)"/>
  <text x="40" y="42" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#FFFFFF" letter-spacing="0.5">
    UML PACKAGE DIAGRAM: HỆ THỐNG QUẢN LÝ KHÁCH SẠN LUXE GRAND HOTEL
  </text>
  <text x="40" y="72" font-family="'Inter', sans-serif" font-size="15" font-weight="500" fill="#D4AF37">
    Mô hình hóa kiến trúc phân rã các gói Backend (NestJS Modular Monolith) và Frontend (Flutter Feature-First) cùng các quan hệ phụ thuộc
  </text>

  <!-- FRONTEND ROOT PACKAGE -->
  <g transform="translate(40, 120)">
    <path d="M 0 0 L 320 0 L 350 35 L 0 35 Z" fill="#2563EB"/>
    <text x="20" y="24" font-family="'Inter', sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">
      &lt;&lt;subsystem&gt;&gt; hotel_app (Flutter FE)
    </text>
    <rect x="0" y="35" width="1020" height="930" rx="8" fill="url(#fePackageGrad)" stroke="#2563EB" stroke-width="2" filter="url(#shadow)"/>

    <!-- lib/core -->
    <g transform="translate(25, 65)">
      <path d="M 0 0 L 170 0 L 190 28 L 0 28 Z" fill="#3B82F6"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; lib::core
      </text>
      <rect x="0" y="28" width="465" height="235" rx="6" fill="#FFFFFF" stroke="#93C5FD" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(15, 45)" font-family="'Fira Code', monospace" font-size="12" fill="#1E293B">
        <rect x="0" y="0" width="205" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="10" y="26" font-weight="600">constants (AppColors)</text>
        <rect x="225" y="0" width="210" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="235" y="26" font-weight="600">network (Dio, SSE)</text>
        <rect x="0" y="55" width="205" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="10" y="81" font-weight="600">router (GoRouter)</text>
        <rect x="225" y="55" width="210" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="235" y="81" font-weight="600">storage (TokenStorage)</text>
        <rect x="0" y="110" width="205" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="10" y="136" font-weight="600">services (FCM Push)</text>
        <rect x="225" y="110" width="210" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="235" y="136" font-weight="600">theme (ThemeCubit)</text>
      </g>
    </g>

    <!-- lib/shared -->
    <g transform="translate(520, 65)">
      <path d="M 0 0 L 180 0 L 200 28 L 0 28 Z" fill="#3B82F6"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; lib::shared
      </text>
      <rect x="0" y="28" width="475" height="235" rx="6" fill="#FFFFFF" stroke="#93C5FD" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(15, 45)" font-family="'Fira Code', monospace" font-size="12" fill="#1E293B">
        <rect x="0" y="0" width="445" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="26" font-weight="600">models (Booking, Room, Invoice, User)</text>
        <rect x="0" y="55" width="445" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="81" font-weight="600">repositories (BookingRepo, RoomRepo...)</text>
        <rect x="0" y="110" width="445" height="42" rx="4" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="136" font-weight="600">widgets (AppCard, StatusBadge, Skeletons)</text>
      </g>
    </g>

    <!-- lib/features -->
    <g transform="translate(25, 395)">
      <path d="M 0 0 L 230 0 L 255 28 L 0 28 Z" fill="#1D4ED8"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; lib::features
      </text>
      <rect x="0" y="28" width="970" height="415" rx="6" fill="#FFFFFF" stroke="#60A5FA" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(20, 50)" font-family="'Inter', sans-serif">
        <rect x="0" y="0" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="26" font-size="14" font-weight="700" fill="#1E293B">features::auth</text>
        <text x="15" y="52" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• AuthBloc, AuthState</text>
        <text x="15" y="74" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• LoginScreen, RegisterScreen</text>
        <text x="15" y="96" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• ForgotPasswordScreen</text>
        <text x="15" y="120" font-size="11" font-weight="600" fill="#2563EB">Bảo mật Token &amp; Đăng nhập</text>

        <rect x="320" y="0" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="335" y="26" font-size="14" font-weight="700" fill="#1E293B">features::customer</text>
        <text x="335" y="52" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• HomeScreen, RoomSearch</text>
        <text x="335" y="74" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RoomDetailScreen</text>
        <text x="335" y="96" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• MyBookings, ServiceOrder</text>
        <text x="335" y="120" font-size="11" font-weight="600" fill="#2563EB">Tra cứu &amp; Đặt phòng Online</text>

        <rect x="640" y="0" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="655" y="26" font-size="14" font-weight="700" fill="#1E293B">features::receptionist</text>
        <text x="655" y="52" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RoomMatrixScreen (5 màu)</text>
        <text x="655" y="74" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• CheckinModal, ChangeRoom</text>
        <text x="655" y="96" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• BookingApprovalModal</text>
        <text x="655" y="120" font-size="11" font-weight="600" fill="#2563EB">Sơ đồ ma trận &amp; Nhận phòng</text>

        <rect x="0" y="175" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="201" font-size="14" font-weight="700" fill="#1E293B">features::cashier</text>
        <text x="15" y="227" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InvoicesScreen, PaymentModal</text>
        <text x="15" y="249" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Deposit &amp; Refund Flow</text>
        <text x="15" y="271" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• ShiftHandoverScreen</text>
        <text x="15" y="295" font-size="11" font-weight="600" fill="#2563EB">Thu ngân &amp; Bàn giao ca trực</text>

        <rect x="320" y="175" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="335" y="201" font-size="14" font-weight="700" fill="#1E293B">features::admin</text>
        <text x="335" y="227" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• AdminDashboardScreen</text>
        <text x="335" y="249" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• FL Chart Revenue (12 Tháng)</text>
        <text x="335" y="271" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• User &amp; RoomType Management</text>
        <text x="335" y="295" font-size="11" font-weight="600" fill="#2563EB">Quản trị &amp; Báo cáo doanh thu</text>

        <rect x="640" y="175" width="290" height="150" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="655" y="201" font-size="14" font-weight="700" fill="#1E293B">features::notifications</text>
        <text x="655" y="227" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• NotificationBloc</text>
        <text x="655" y="249" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• NotificationHistoryScreen</text>
        <text x="655" y="271" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InAppNotificationBanner</text>
        <text x="655" y="295" font-size="11" font-weight="600" fill="#2563EB">Trung tâm thông báo đẩy</text>
      </g>
    </g>

    <!-- lib/di -->
    <g transform="translate(25, 850)">
      <path d="M 0 0 L 150 0 L 170 25 L 0 25 Z" fill="#6366F1"/>
      <text x="12" y="17" font-family="'Inter', sans-serif" font-size="12" font-weight="700" fill="#FFFFFF">lib::di</text>
      <rect x="0" y="25" width="970" height="50" rx="4" fill="#FFFFFF" stroke="#A5B4FC" stroke-width="1.5"/>
      <text x="20" y="55" font-family="'Fira Code', monospace" font-size="13" font-weight="600" fill="#4338CA">
        injection_container.dart (GetIt Service Locator - Registers Blocs, Repositories, DioClient, Services)
      </text>
    </g>

    <!-- Connectors inside FE (Features -> Core, Features -> Shared) - ZERO COLLISION -->
    <path d="M 255 395 L 255 335" fill="none" stroke="#2563EB" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#depArrowBlue)"/>
    <rect x="155" y="348" width="200" height="26" rx="4" fill="#EFF6FF" stroke="#93C5FD"/>
    <text x="255" y="365" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#1D4ED8" text-anchor="middle">&lt;&lt;use core, router, network&gt;&gt;</text>

    <path d="M 755 395 L 755 335" fill="none" stroke="#2563EB" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#depArrowBlue)"/>
    <rect x="665" y="348" width="180" height="26" rx="4" fill="#EFF6FF" stroke="#93C5FD"/>
    <text x="755" y="365" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#1D4ED8" text-anchor="middle">&lt;&lt;import models &amp; repos&gt;&gt;</text>
  </g>

  <!-- BACKEND ROOT PACKAGE -->
  <g transform="translate(1140, 120)">
    <path d="M 0 0 L 340 0 L 370 35 L 0 35 Z" fill="#059669"/>
    <text x="20" y="24" font-family="'Inter', sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">
      &lt;&lt;subsystem&gt;&gt; Hotel-Management (NestJS BE)
    </text>
    <rect x="0" y="35" width="1020" height="930" rx="8" fill="url(#bePackageGrad)" stroke="#059669" stroke-width="2" filter="url(#shadow)"/>

    <!-- src/common -->
    <g transform="translate(25, 65)">
      <path d="M 0 0 L 190 0 L 210 28 L 0 28 Z" fill="#10B981"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; src::common
      </text>
      <rect x="0" y="28" width="970" height="95" rx="6" fill="#FFFFFF" stroke="#6EE7B7" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(15, 48)" font-family="'Fira Code', monospace" font-size="12" fill="#065F46">
        <rect x="0" y="0" width="220" height="42" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
        <text x="15" y="26" font-weight="600">guards (Jwt, Roles)</text>
        <rect x="240" y="0" width="225" height="42" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
        <text x="255" y="26" font-weight="600">decorators (Roles, User)</text>
        <rect x="485" y="0" width="225" height="42" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
        <text x="500" y="26" font-weight="600">filters (Exceptions)</text>
        <rect x="730" y="0" width="210" height="42" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
        <text x="745" y="26" font-weight="600">pipes (Validation)</text>
      </g>
    </g>

    <!-- src/domain_modules -->
    <g transform="translate(25, 205)">
      <path d="M 0 0 L 270 0 L 295 28 L 0 28 Z" fill="#047857"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; src::domain_modules
      </text>
      <rect x="0" y="28" width="970" height="420" rx="6" fill="#FFFFFF" stroke="#34D399" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(20, 50)" font-family="'Inter', sans-serif">
        <rect x="0" y="0" width="295" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="26" font-size="13" font-weight="700" fill="#1E293B">modules::auth</text>
        <text x="15" y="50" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• AuthController, AuthService</text>
        <text x="15" y="72" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• JwtStrategy, SessionGuard</text>

        <rect x="320" y="0" width="310" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="335" y="26" font-size="13" font-weight="700" fill="#1E293B">modules::bookings</text>
        <text x="335" y="50" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• BookingsController &amp; Service</text>
        <text x="335" y="72" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• Interval Overlap Check, DTOs</text>

        <rect x="650" y="0" width="280" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="665" y="26" font-size="13" font-weight="700" fill="#1E293B">modules::rooms &amp; types</text>
        <text x="665" y="50" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• RoomsController, Service</text>
        <text x="665" y="72" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• RoomEventsService (SSE Bus)</text>

        <rect x="0" y="130" width="295" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="156" font-size="13" font-weight="700" fill="#1E293B">modules::invoices</text>
        <text x="15" y="180" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• InvoicesController, Service</text>
        <text x="15" y="202" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• Deposit, Multi-entry Payment</text>

        <rect x="320" y="130" width="310" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="335" y="156" font-size="13" font-weight="700" fill="#1E293B">modules::shifts</text>
        <text x="335" y="180" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• ShiftsController, Service</text>
        <text x="335" y="202" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• Cash Drawer Reconciliation</text>

        <rect x="650" y="130" width="280" height="105" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="665" y="156" font-size="13" font-weight="700" fill="#1E293B">modules::users &amp; analytics</text>
        <text x="665" y="180" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• UsersController, Service</text>
        <text x="665" y="202" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• AnalyticsService (KPI, Charts)</text>

        <rect x="0" y="260" width="930" height="70" rx="6" fill="#F8FAFC" stroke="#CBD5E1"/>
        <text x="15" y="286" font-size="13" font-weight="700" fill="#1E293B">modules::services &amp; upload</text>
        <text x="15" y="308" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">• Hotel Extra Services (F&amp;B, Minibar, Spa) &amp; Cloudinary Image Upload Module</text>
      </g>
    </g>

    <!-- src/infrastructure -->
    <g transform="translate(25, 680)">
      <path d="M 0 0 L 260 0 L 285 28 L 0 28 Z" fill="#065F46"/>
      <text x="15" y="19" font-family="'Inter', sans-serif" font-size="13" font-weight="700" fill="#FFFFFF">
        &lt;&lt;package&gt;&gt; src::infrastructure
      </text>
      <rect x="0" y="28" width="970" height="180" rx="6" fill="#FFFFFF" stroke="#059669" stroke-width="1.5" filter="url(#cardShadow)"/>
      <g transform="translate(20, 50)" font-family="'Fira Code', monospace" font-size="12">
        <rect x="0" y="0" width="295" height="60" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
        <text x="15" y="25" font-weight="700" fill="#065F46">prisma (PrismaService)</text>
        <text x="15" y="45" font-size="10" fill="#047857">PostgreSQL 16 Client &amp; Migrations</text>

        <rect x="320" y="0" width="310" height="60" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
        <text x="335" y="25" font-weight="700" fill="#065F46">redis (RedisService)</text>
        <text x="335" y="45" font-size="10" fill="#047857">In-Memory Cache (Rooms, Minibar)</text>

        <rect x="650" y="0" width="280" height="60" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
        <text x="665" y="25" font-weight="700" fill="#065F46">elasticsearch</text>
        <text x="665" y="45" font-size="10" fill="#047857">Full-text Search Cluster Client</text>

        <rect x="0" y="75" width="460" height="55" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
        <text x="15" y="100" font-weight="700" fill="#065F46">notifications (Firebase Admin SDK &amp; Cron)</text>
        <text x="15" y="120" font-size="10" fill="#047857">Push Notification Broadcast &amp; 09:00 AM Cronjob</text>

        <rect x="490" y="75" width="440" height="55" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
        <text x="505" y="100" font-weight="700" fill="#065F46">mail (Nodemailer) &amp; upload (Cloudinary)</text>
        <text x="505" y="120" font-size="10" fill="#047857">Email Welcome/OTP &amp; Media Asset Storage</text>
      </g>
    </g>

    <!-- Connectors inside BE -->
    <path d="M 500 205 L 500 170" fill="none" stroke="#059669" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#depArrowEmerald)"/>
    <rect x="400" y="174" width="200" height="24" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="500" y="190" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#047857" text-anchor="middle">&lt;&lt;apply guards, filters&gt;&gt;</text>

    <path d="M 500 655 L 500 695" fill="none" stroke="#059669" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#depArrowEmerald)"/>
    <rect x="410" y="662" width="180" height="24" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="500" y="678" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#047857" text-anchor="middle">&lt;&lt;query DB &amp; Cache&gt;&gt;</text>
  </g>

  <!-- MIDDLE REST API & SSE CHANNEL (FE <-> BE) -->
  <g transform="translate(1060, 520)">
    <path d="M 5 30 L 75 30" fill="none" stroke="#D97706" stroke-width="3" stroke-dasharray="6,4" marker-end="url(#depArrow)"/>
    <rect x="-10" y="0" width="100" height="24" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
    <text x="40" y="16" font-family="'Inter', sans-serif" font-size="12" font-weight="800" fill="#D97706" text-anchor="middle">REST API</text>

    <path d="M 75 80 L 5 80" fill="none" stroke="#2563EB" stroke-width="3" stroke-dasharray="6,4" marker-end="url(#depArrowBlue)"/>
    <rect x="-10" y="90" width="100" height="24" rx="4" fill="#EFF6FF" stroke="#93C5FD"/>
    <text x="40" y="106" font-family="'Inter', sans-serif" font-size="12" font-weight="800" fill="#2563EB" text-anchor="middle">SSE Stream</text>
  </g>

  <!-- PERSISTENCE / EXTERNAL SERVICES -->
  <g transform="translate(40, 1090)">
    <!-- WIDER TAB SO TEXT NEVER CUTS OFF -->
    <path d="M 0 0 L 460 0 L 490 35 L 0 35 Z" fill="#D97706"/>
    <text x="20" y="24" font-family="'Inter', sans-serif" font-size="14" font-weight="700" fill="#FFFFFF">
      &lt;&lt;environment&gt;&gt; Persistence &amp; External Services
    </text>
    <rect x="0" y="35" width="2120" height="160" rx="8" fill="url(#extPackageGrad)" stroke="#D97706" stroke-width="2" filter="url(#shadow)"/>
    <g transform="translate(25, 60)" font-family="'Inter', sans-serif">
      <rect x="0" y="0" width="390" height="105" rx="6" fill="#FFFFFF" stroke="#FDE68A" filter="url(#cardShadow)"/>
      <text x="20" y="32" font-size="14" font-weight="700" fill="#92400E">PostgreSQL 16 Database</text>
      <text x="20" y="58" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">users, rooms, room_types, bookings,</text>
      <text x="20" y="78" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">invoices, payments, work_shifts...</text>

      <rect x="420" y="0" width="390" height="105" rx="6" fill="#FFFFFF" stroke="#FDE68A" filter="url(#cardShadow)"/>
      <text x="440" y="32" font-size="14" font-weight="700" fill="#92400E">Redis 7 In-Memory Server</text>
      <text x="440" y="58" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Key-Value Caching, Active Sessions,</text>
      <text x="440" y="78" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">TTL Expiration, Query Offloading</text>

      <rect x="840" y="0" width="390" height="105" rx="6" fill="#FFFFFF" stroke="#FDE68A" filter="url(#cardShadow)"/>
      <text x="860" y="32" font-size="14" font-weight="700" fill="#92400E">Elasticsearch 8 Engine</text>
      <text x="860" y="58" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Multi-field Lucene Indices, Fuzzy</text>
      <text x="860" y="78" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Room Search &amp; Amenities Matching</text>

      <rect x="1260" y="0" width="390" height="105" rx="6" fill="#FFFFFF" stroke="#FDE68A" filter="url(#cardShadow)"/>
      <text x="1280" y="32" font-size="14" font-weight="700" fill="#92400E">Firebase Cloud Messaging</text>
      <text x="1280" y="58" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Google Cloud Gateway, Realtime Push,</text>
      <text x="1280" y="78" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Broadcast to Staff / Customer Devices</text>

      <rect x="1680" y="0" width="390" height="105" rx="6" fill="#FFFFFF" stroke="#FDE68A" filter="url(#cardShadow)"/>
      <text x="1700" y="32" font-size="14" font-weight="700" fill="#92400E">Third-Party SaaS Services</text>
      <text x="1700" y="58" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Nodemailer SMTP (Gmail / SendGrid)</text>
      <text x="1700" y="78" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Cloudinary Media CDN Storage</text>
    </g>
  </g>

  <!-- Connectors: Infrastructure to External Services -->
  <path d="M 1650 1050 L 1650 1115" fill="none" stroke="#D97706" stroke-width="2.5" stroke-dasharray="6,4" marker-end="url(#depArrow)"/>
  <rect x="1520" y="1065" width="260" height="26" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
  <text x="1650" y="1083" font-family="'Inter', sans-serif" font-size="12" font-weight="800" fill="#D97706" text-anchor="middle">&lt;&lt;TCP / Socket / HTTPS Drivers&gt;&gt;</text>

  <!-- Connector: FE Push Message Subscription -->
  <path d="M 520 1050 L 520 1070 L 1480 1070 L 1480 1115" fill="none" stroke="#D97706" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#depArrow)"/>
  <rect x="870" y="1057" width="260" height="26" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
  <text x="1000" y="1075" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">&lt;&lt;FCM Push Message Subscription&gt;&gt;</text>
</svg>`;

  return createHtmlWrapper('Package Diagram - Luxe Grand Hotel', width, height, svg);
}

// =============================================================
// DIAGRAM 2: COMPONENT DIAGRAM
// =============================================================
function generateComponentDiagram() {
  const width = 2200;
  const height = 1450;

  const svg = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  ${commonDefs}

  <!-- Header Banner -->
  <rect x="0" y="0" width="${width}" height="90" rx="8" fill="url(#headerGrad)"/>
  <text x="40" y="42" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#FFFFFF" letter-spacing="0.5">
    UML COMPONENT DIAGRAM: HỆ THỐNG QUẢN LÝ KHÁCH SẠN LUXE GRAND HOTEL
  </text>
  <text x="40" y="72" font-family="'Inter', sans-serif" font-size="15" font-weight="500" fill="#38BDF8">
    Mô hình hóa các thành phần phần mềm (Components), giao diện kết nối (Interfaces / Ports) và luồng liên lạc giữa Client - Server - Data
  </text>

  <!-- ==================== CLIENT SUBSYSTEM ==================== -->
  <g transform="translate(40, 120)">
    <rect x="0" y="0" width="600" height="1280" rx="8" fill="#F8FAFC" stroke="#0284C7" stroke-width="2.5" filter="url(#shadow)"/>
    <text x="30" y="38" font-family="'Inter', sans-serif" font-size="17" font-weight="800" fill="#0369A1">
      &lt;&lt;subsystem&gt;&gt; Mobile Client (Flutter Application)
    </text>

    <!-- Component 1: UI View -->
    <g transform="translate(25, 60)">
      <rect x="0" y="0" width="550" height="175" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; UI Presentation Components</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Screens: RoomMatrixScreen (5 màu sắc), BookingWizard</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InvoicesScreen, ShiftHandoverModal, AdminDashboard</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Reusable: AppCard, ShiftKpiStrip, FL Chart Bar Chart</text>
      <text x="20" y="140" font-size="12" font-weight="600" fill="#0284C7">Cung cấp: View rendering, nhận tương tác người dùng</text>
    </g>

    <!-- Component 2: BLoC State Management -->
    <g transform="translate(25, 255)">
      <rect x="0" y="0" width="550" height="195" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; State Management (BLoC / Cubit)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• AuthBloc: Kiểm soát phiên đăng nhập, JWT expiry</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RoomBloc: Quản lý ma trận phòng, tiếp nhận sự kiện SSE</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• BookingBloc, InvoiceBloc, ShiftBloc, ThemeCubit</text>
      <text x="20" y="138" font-size="12" font-weight="600" fill="#0284C7">Cổng tiếp nhận: UI Events (Streams)</text>
      <text x="20" y="162" font-size="12" font-weight="600" fill="#0284C7">Cổng phát ra: UI States (Loading, Loaded, Error)</text>
    </g>

    <!-- Component 3: Service Locator (GetIt) -->
    <g transform="translate(25, 470)">
      <rect x="0" y="0" width="550" height="120" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; Service Locator (GetIt Container)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Singleton &amp; Factory Dependency Injection</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Tiêm phụ thuộc Repositories, Blocs, DioClient, SSE</text>
      <text x="20" y="102" font-size="12" font-weight="600" fill="#0284C7">Khởi tạo và định vị tài nguyên toàn cục</text>
    </g>

    <!-- Component 4: Repository Layer -->
    <g transform="translate(25, 610)">
      <rect x="0" y="0" width="550" height="190" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; Repository Layer (Domain Gateways)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• BookingRepository, RoomRepository, InvoiceRepository</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• ShiftRepository, UserRepository, ServiceRepository</text>
      <text x="20" y="116" font-size="12" font-weight="600" fill="#0284C7">Trừu tượng hóa nguồn dữ liệu API, parse JSON sang Entity</text>
      <text x="20" y="140" font-size="12" font-weight="600" fill="#0284C7">Quản lý định dạng lỗi ApiResult&lt;T&gt; (Success / Failure)</text>
    </g>

    <!-- Component 5: Network Adapters -->
    <g transform="translate(25, 820)">
      <rect x="0" y="0" width="550" height="210" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; Network Adapters (Dio &amp; SSE)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• DioClient: HTTP REST client, Bearer JWT Interceptor</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• SseClient: Server-Sent Events subscriber, Auto-reconnect</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• TokenStorage: Quản lý access_token trong KeyStore</text>
      <text x="20" y="138" font-size="12" font-weight="600" fill="#0284C7">Giao diện cung cấp: IHttpClient, ISseStreamSubscriber</text>
      <text x="20" y="162" font-size="12" font-weight="600" fill="#0284C7">Giao diện yêu cầu: OS Network Socket, SSL/TLS Handshake</text>
    </g>

    <!-- Component 6: Push Listener -->
    <g transform="translate(25, 1050)">
      <rect x="0" y="0" width="550" height="190" rx="6" fill="#FFFFFF" stroke="#BAE6FD" stroke-width="1.8"/>
      <use href="#compIcon" x="510" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#0C4A6E">&lt;&lt;component&gt;&gt; FCM Notification Receiver</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• firebaseMessagingBackgroundHandler (Killed App state)</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InAppNotificationBanner &amp; Local Notification Bridge</text>
      <text x="20" y="116" font-size="12" font-weight="600" fill="#0284C7">Lắng nghe Push Token và hiển thị Heads-up notification</text>
    </g>
  </g>

  <!-- ==================== MIDDLE NETWORK CHANNELS (LOLLIPOP & SOCKET) ==================== -->
  <g transform="translate(640, 120)">
    <!-- REST API Channel -->
    <g transform="translate(0, 360)">
      <path d="M 0 0 L 50 0" stroke="#0284C7" stroke-width="3"/>
      <path d="M 50 -16 A 16 16 0 0 1 50 16" fill="none" stroke="#0284C7" stroke-width="3"/>
      <circle cx="70" cy="0" r="10" fill="#FFFFFF" stroke="#D97706" stroke-width="3"/>
      <path d="M 80 0 L 120 0" stroke="#D97706" stroke-width="3" marker-end="url(#depArrow)"/>
      <rect x="10" y="-36" width="100" height="22" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
      <text x="60" y="-21" font-size="11" font-weight="800" fill="#D97706" text-anchor="middle">I_REST_API</text>
      <text x="60" y="32" font-size="10" fill="#B45309" text-anchor="middle" font-family="'Fira Code', monospace">JSON/HTTPS (Port 443)</text>
    </g>

    <!-- SSE Stream Channel -->
    <g transform="translate(0, 540)">
      <path d="M 0 0 L 50 0" stroke="#0284C7" stroke-width="3"/>
      <circle cx="50" cy="0" r="10" fill="#FFFFFF" stroke="#059669" stroke-width="3"/>
      <path d="M 70 -16 A 16 16 0 0 0 70 16" fill="none" stroke="#059669" stroke-width="3"/>
      <path d="M 70 0 L 120 0" stroke="#059669" stroke-width="3"/>
      <rect x="5" y="-36" width="110" height="22" rx="4" fill="#F0FDF4" stroke="#A7F3D0"/>
      <text x="60" y="-21" font-size="11" font-weight="800" fill="#047857" text-anchor="middle">I_SSE_STREAM</text>
      <text x="60" y="32" font-size="10" fill="#065F46" text-anchor="middle" font-family="'Fira Code', monospace">Realtime Push (HTTP/2)</text>
    </g>

    <!-- FCM Push Channel -->
    <g transform="translate(0, 1140)">
      <path d="M 0 0 L 50 0" stroke="#0284C7" stroke-width="3"/>
      <path d="M 50 -16 A 16 16 0 0 1 50 16" fill="none" stroke="#0284C7" stroke-width="3"/>
      <circle cx="70" cy="0" r="10" fill="#FFFFFF" stroke="#D97706" stroke-width="3"/>
      <path d="M 80 0 L 120 0" stroke="#D97706" stroke-width="3" marker-end="url(#depArrow)"/>
      <rect x="5" y="-36" width="110" height="22" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
      <text x="60" y="-21" font-size="11" font-weight="800" fill="#D97706" text-anchor="middle">I_FCM_PUSH</text>
      <text x="60" y="32" font-size="10" fill="#B45309" text-anchor="middle" font-family="'Fira Code', monospace">OTA Push Notifications</text>
    </g>
  </g>

  <!-- ==================== BACKEND SUBSYSTEM ==================== -->
  <g transform="translate(760, 120)">
    <rect x="0" y="0" width="720" height="1280" rx="8" fill="#F8FAFC" stroke="#059669" stroke-width="2.5" filter="url(#shadow)"/>
    <text x="30" y="38" font-family="'Inter', sans-serif" font-size="17" font-weight="800" fill="#047857">
      &lt;&lt;subsystem&gt;&gt; API Server (NestJS Application)
    </text>

    <!-- Component: API Gateway & Guards -->
    <g transform="translate(25, 60)">
      <rect x="0" y="0" width="670" height="135" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; Gateway, Pipeline &amp; Security Guards</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Global ValidationPipe (class-validator), AllExceptionsFilter</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• JwtAuthGuard: Giải mã Bearer Token, kiểm tra activeSessionId</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RolesGuard: Kiểm soát quyền hạn (RBAC) trên từng Endpoint</text>
    </g>

    <!-- Component: Controllers -->
    <g transform="translate(25, 215)">
      <rect x="0" y="0" width="670" height="155" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; REST API Controllers Layer</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• BookingsController (/api/v1/bookings): CRUD, Approve, Checkin</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RoomsController (/api/v1/rooms): Matrix, Stream, ChangeRoom</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InvoicesController, ShiftsController, AuthController, Users</text>
      <text x="20" y="132" font-size="12" font-weight="600" fill="#059669">Tiếp nhận HTTP Request, giải nén DTO, chuyển giao Service</text>
    </g>

    <!-- Component: Domain Services -->
    <g transform="translate(25, 390)">
      <rect x="0" y="0" width="670" height="290" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; Domain Business Logic Services</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• BookingsService: Thuật toán Interval Overlap kiểm tra trùng phòng</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• InvoicesService: Quản lý sổ thu tiền đa đợt (Payment &amp; Deposit)</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• ShiftsService: Quản lý ca trực lễ tân, kiểm soát sai lệch két tiền</text>
      <text x="20" y="124" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RoomTypesService, ServicesService, UsersService, AnalyticsService</text>
      
      <!-- Sub-box: Event Bus -->
      <rect x="20" y="150" width="630" height="90" rx="6" fill="#F0FDF4" stroke="#86EFAC"/>
      <text x="35" y="175" font-size="13" font-weight="700" fill="#047857">RoomEventsService &amp; UserEventsService (In-process Event Bus)</text>
      <text x="35" y="198" font-size="11" fill="#065F46" font-family="'Fira Code', monospace">• RxJS Subject&lt;RoomEvent&gt; phát sự kiện 'room.status_changed'</text>
      <text x="35" y="220" font-size="11" fill="#065F46" font-family="'Fira Code', monospace">• SSE Stream Handler: Phát luồng thông điệp thời gian thực về Client</text>
      
      <text x="20" y="268" font-size="12" font-weight="600" fill="#059669">Bảo vệ toàn vẹn quy tắc nghiệp vụ khách sạn (ACID / Domain Rules)</text>
    </g>

    <!-- Component: Cron Scheduler -->
    <g transform="translate(25, 700)">
      <rect x="0" y="0" width="670" height="95" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; Automated Task Scheduler (Cron Engine)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• CheckinReminderService: @Cron('0 9 * * *') chạy mỗi sáng 09:00</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Tự động quét đơn nhận phòng hôm nay &amp; kích hoạt gửi FCM / Email</text>
    </g>

    <!-- Component: Prisma ORM -->
    <g transform="translate(25, 815)">
      <rect x="0" y="0" width="670" height="155" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; Data Access Layer (Prisma ORM Client)</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• PrismaService (Type-Safe Query Builder, Connection Pooling)</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• prisma.$transaction: Thực thi giao dịch nguyên tử (Atomic commit)</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Tự động tạo TypeScript Types 100% không null pointer lúc runtime</text>
      <text x="20" y="132" font-size="12" font-weight="600" fill="#059669">Cung cấp interface: I_PrismaClient, TransactionManager</text>
    </g>

    <!-- Component: Infra Adapters -->
    <g transform="translate(25, 990)">
      <rect x="0" y="0" width="670" height="165" rx="6" fill="#FFFFFF" stroke="#A7F3D0" stroke-width="1.8"/>
      <use href="#compIcon" x="630" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#065F46">&lt;&lt;component&gt;&gt; External Integration Adapters</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• RedisService (ioredis): Đệm danh mục phòng, giảm 65% tải CSDL</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• ElasticsearchService: Đánh chỉ mục Lucene, tìm kiếm nâng cao &lt; 50ms</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• NotificationsService: Firebase Admin SDK (FCM Broadcast)</text>
      <text x="20" y="124" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• MailService (Nodemailer) &amp; UploadModule (Cloudinary SDK)</text>
    </g>
  </g>

  <!-- ==================== MIDDLE-RIGHT PROTOCOL BUS (BE -> DATA) ==================== -->
  <g transform="translate(1480, 120)">
    <!-- Bus line 1: PostgreSQL Port 5432 -->
    <path d="M 0 890 L 120 170" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="510" width="90" height="22" rx="4" fill="#F0FDF4" stroke="#86EFAC"/>
    <text x="60" y="525" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 5432 / TCP</text>

    <!-- Bus line 2: Redis Port 6379 -->
    <path d="M 0 1020 L 120 390" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="685" width="90" height="22" rx="4" fill="#F0FDF4" stroke="#86EFAC"/>
    <text x="60" y="700" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 6379 / TCP</text>

    <!-- Bus line 3: Elasticsearch Port 9200 -->
    <path d="M 0 1050 L 120 590" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="800" width="90" height="22" rx="4" fill="#F0FDF4" stroke="#86EFAC"/>
    <text x="60" y="815" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 9200 / HTTP</text>

    <!-- Bus line 4: FCM Push -->
    <path d="M 0 1080 L 120 780" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="915" width="90" height="22" rx="4" fill="#F0FDF4" stroke="#86EFAC"/>
    <text x="60" y="930" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">FCM Admin SDK</text>

    <!-- Bus line 5: Cloudinary & SMTP -->
    <path d="M 0 1110 L 120 970" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="1030" width="90" height="22" rx="4" fill="#F0FDF4" stroke="#86EFAC"/>
    <text x="60" y="1045" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 587 &amp; HTTPS</text>
  </g>

  <!-- ==================== PERSISTENCE & DATA SUBSYSTEM ==================== -->
  <g transform="translate(1600, 120)">
    <rect x="0" y="0" width="560" height="1280" rx="8" fill="#F8FAFC" stroke="#D97706" stroke-width="2.5" filter="url(#shadow)"/>
    <text x="30" y="38" font-family="'Inter', sans-serif" font-size="17" font-weight="800" fill="#B45309">
      &lt;&lt;subsystem&gt;&gt; Persistence &amp; Cloud Platform
    </text>

    <!-- PostgreSQL -->
    <g transform="translate(25, 60)">
      <rect x="0" y="0" width="510" height="205" rx="6" fill="#FFFFFF" stroke="#FDE68A" stroke-width="1.8"/>
      <use href="#compIcon" x="470" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#92400E">&lt;&lt;component&gt;&gt; PostgreSQL 16 DB Server</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Relational Storage with ACID Compliance</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• B-Tree Indexes &amp; Multi-statement Locking</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Tables: users, rooms, room_types, bookings,</text>
      <text x="20" y="124" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">  invoices, payments, work_shifts, services...</text>
      <text x="20" y="162" font-size="12" font-weight="600" fill="#D97706">Port kết nối: 5432 / TCP (Prisma Pool)</text>
    </g>

    <!-- Redis Cache -->
    <g transform="translate(25, 285)">
      <rect x="0" y="0" width="510" height="180" rx="6" fill="#FFFFFF" stroke="#FDE68A" stroke-width="1.8"/>
      <use href="#compIcon" x="470" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#92400E">&lt;&lt;component&gt;&gt; Redis 7 In-Memory Engine</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• High-throughput In-Memory Caching (LRU)</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Cache danh mục phòng trống &amp; Minibar</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Tự động đồng bộ / xóa cache khi cập nhật</text>
      <text x="20" y="140" font-size="12" font-weight="600" fill="#D97706">Port kết nối: 6379 / TCP (ioredis)</text>
    </g>

    <!-- Elasticsearch -->
    <g transform="translate(25, 485)">
      <rect x="0" y="0" width="510" height="180" rx="6" fill="#FFFFFF" stroke="#FDE68A" stroke-width="1.8"/>
      <use href="#compIcon" x="470" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#92400E">&lt;&lt;component&gt;&gt; Elasticsearch 8 Cluster</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Lucene Distributed Full-text Search Engine</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Index: 'hotel_rooms', 'hotel_services'</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Fuzzy search, lọc tiện nghi (WiFi, Bể bơi...)</text>
      <text x="20" y="140" font-size="12" font-weight="600" fill="#D97706">Port kết nối: 9200 / HTTP REST API</text>
    </g>

    <!-- Firebase FCM -->
    <g transform="translate(25, 685)">
      <rect x="0" y="0" width="510" height="165" rx="6" fill="#FFFFFF" stroke="#FDE68A" stroke-width="1.8"/>
      <use href="#compIcon" x="470" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#92400E">&lt;&lt;component&gt;&gt; Firebase Cloud Messaging</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Google Cloud Push Notification Gateway</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Quản lý FCM Registration Tokens người dùng</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Chuyển phát tin ngầm (Data-only) &amp; Display Alerts</text>
    </g>

    <!-- Cloudinary & SMTP -->
    <g transform="translate(25, 870)">
      <rect x="0" y="0" width="510" height="165" rx="6" fill="#FFFFFF" stroke="#FDE68A" stroke-width="1.8"/>
      <use href="#compIcon" x="470" y="15"/>
      <text x="20" y="32" font-size="15" font-weight="700" fill="#92400E">&lt;&lt;component&gt;&gt; Cloudinary &amp; SMTP Mailer</text>
      <text x="20" y="58" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Cloudinary CDN: Lưu trữ tối ưu ảnh phòng HD</text>
      <text x="20" y="80" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• SMTP Server: Gửi thư xác thực OTP, thư chào đón</text>
      <text x="20" y="102" font-size="12" fill="#64748B" font-family="'Fira Code', monospace">• Giao thức: HTTPS Multi-part upload &amp; SMTP TLS</text>
    </g>
  </g>
</svg>`;

  return createHtmlWrapper('Component Diagram - Luxe Grand Hotel', width, height, svg);
}

// =============================================================
// DIAGRAM 3: DEPLOYMENT DIAGRAM
// =============================================================
function generateDeploymentDiagram() {
  const width = 2200;
  const height = 1450;

  const svg = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  ${commonDefs}

  <!-- Header Banner -->
  <rect x="0" y="0" width="${width}" height="90" rx="8" fill="url(#headerGrad)"/>
  <text x="40" y="42" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#FFFFFF" letter-spacing="0.5">
    UML DEPLOYMENT DIAGRAM: HẠ TẦNG VẬN HÀNH HỆ THỐNG LUXE GRAND HOTEL
  </text>
  <text x="40" y="72" font-family="'Inter', sans-serif" font-size="15" font-weight="500" fill="#FBBF24">
    Mô hình hóa kiến trúc phần cứng, môi trường thực thi (Execution Environments), Container Docker và giao thức truyền thông mạng
  </text>

  <!-- ==================== NODE 1: CLIENT MOBILE DEVICE ==================== -->
  <g transform="translate(40, 130)">
    <!-- 3D Cube: Top & Side -->
    <polygon points="20,-20 540,-20 520,0 0,0" fill="url(#nodeTopGrad)" stroke="#475569" stroke-width="1.5"/>
    <polygon points="520,0 540,-20 540,1230 520,1250" fill="url(#nodeSideGrad)" stroke="#475569" stroke-width="1.5"/>
    <!-- 3D Cube: Front -->
    <rect x="0" y="0" width="520" height="1250" rx="4" fill="#F8FAFC" stroke="#334155" stroke-width="2" filter="url(#shadow)"/>

    <g transform="translate(25, 30)">
      <text x="0" y="10" font-size="13" font-weight="700" fill="#64748B">&lt;&lt;device&gt;&gt;</text>
      <text x="0" y="32" font-size="18" font-weight="800" fill="#0F172A">Mobile Client Device (Android / iOS)</text>
      <text x="0" y="55" font-size="12" fill="#475569" font-family="'Fira Code', monospace">OS: Android 10+ / iOS 15+ (ARM64 / x86_64)</text>

      <!-- Execution Environment: Flutter Runtime -->
      <g transform="translate(0, 80)">
        <polygon points="15,-15 470,-15 455,0 0,0" fill="#E0F2FE" stroke="#0284C7" stroke-width="1"/>
        <polygon points="455,0 470,-15 470,1050 455,1065" fill="#BAE6FD" stroke="#0284C7" stroke-width="1"/>
        <rect x="0" y="0" width="455" height="1065" rx="4" fill="#F0F9FF" stroke="#0284C7" stroke-width="1.5"/>

        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#0369A1">&lt;&lt;execution environment&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#0C4A6E">Flutter Framework Runtime (Impeller Engine)</text>
          <text x="0" y="55" font-size="11" fill="#0284C7" font-family="'Fira Code', monospace">Dart VM (AOT Native Machine Code ARM64)</text>

          <!-- Artifact: Mobile Application -->
          <g transform="translate(0, 80)">
            <rect x="0" y="0" width="415" height="520" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.5"/>
            <use href="#artifactIcon" x="380" y="15"/>

            <g transform="translate(20, 30)">
              <text x="0" y="10" font-size="12" font-weight="700" fill="#0369A1">&lt;&lt;artifact&gt;&gt;</text>
              <text x="0" y="32" font-size="15" font-weight="800" fill="#0F172A">hotel_app.apk / hotel_app.ipa</text>
              
              <rect x="0" y="55" width="375" height="75" rx="4" fill="#F8FAFC" stroke="#E2E8F0"/>
              <text x="15" y="78" font-size="12" font-weight="700" fill="#1E293B">UI Presentation Components</text>
              <text x="15" y="98" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">RoomMatrix, BookingModal, ShiftKPI, FLChart</text>

              <rect x="0" y="145" width="375" height="75" rx="4" fill="#F8FAFC" stroke="#E2E8F0"/>
              <text x="15" y="168" font-size="12" font-weight="700" fill="#1E293B">BLoC State Management Layer</text>
              <text x="15" y="188" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">AuthBloc, RoomBloc, BookingBloc, ShiftBloc</text>

              <rect x="0" y="235" width="375" height="75" rx="4" fill="#F8FAFC" stroke="#E2E8F0"/>
              <text x="15" y="258" font-size="12" font-weight="700" fill="#1E293B">Network &amp; Realtime Stream Clients</text>
              <text x="15" y="278" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">DioClient (Bearer JWT), SseClient (Auto-retry)</text>

              <rect x="0" y="325" width="375" height="75" rx="4" fill="#F8FAFC" stroke="#E2E8F0"/>
              <text x="15" y="348" font-size="12" font-weight="700" fill="#1E293B">FCM Notification &amp; Service Locator</text>
              <text x="15" y="368" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">GetIt DI, PushNotificationService, Background</text>
            </g>
          </g>

          <!-- Artifact: Secure KeyStore / Keychain -->
          <g transform="translate(0, 640)">
            <rect x="0" y="0" width="415" height="160" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.5"/>
            <use href="#artifactIcon" x="380" y="15"/>

            <g transform="translate(20, 30)">
              <text x="0" y="10" font-size="12" font-weight="700" fill="#0369A1">&lt;&lt;artifact&gt;&gt;</text>
              <text x="0" y="32" font-size="15" font-weight="800" fill="#0F172A">Secure KeyStore / iOS Keychain</text>
              <text x="0" y="60" font-size="11" fill="#475569" font-family="'Fira Code', monospace">• access_token (AES-256 Encrypted JWT)</text>
              <text x="0" y="80" font-size="11" fill="#475569" font-family="'Fira Code', monospace">• activeSessionId (Single Device Login lock)</text>
              <text x="0" y="100" font-size="11" fill="#475569" font-family="'Fira Code', monospace">• user_credentials &amp; app_preferences</text>
            </g>
          </g>
        </g>
      </g>
    </g>
  </g>

  <!-- ==================== NETWORK CONNECTORS (CLIENT <-> CLOUD) ==================== -->
  <g transform="translate(580, 130)">
    <!-- HTTPS Port 443 -->
    <path d="M 0 450 L 140 450" fill="none" stroke="#D97706" stroke-width="3" marker-end="url(#depArrow)"/>
    <rect x="15" y="420" width="110" height="26" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
    <text x="70" y="437" font-size="11" font-weight="800" fill="#D97706" text-anchor="middle">HTTPS / TLS 1.3</text>
    <text x="70" y="468" font-size="10" fill="#B45309" text-anchor="middle" font-family="'Fira Code', monospace">Port 443 / REST</text>

    <!-- SSE Stream Port 443 -->
    <path d="M 140 600 L 0 600" fill="none" stroke="#059669" stroke-width="3" stroke-dasharray="6,4" marker-end="url(#depArrowEmerald)"/>
    <rect x="15" y="570" width="110" height="26" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="70" y="587" font-size="11" font-weight="800" fill="#047857" text-anchor="middle">HTTP/2 SSE</text>
    <text x="70" y="618" font-size="10" fill="#065F46" text-anchor="middle" font-family="'Fira Code', monospace">Port 443 / Stream</text>

    <!-- OTA Push Notification -->
    <path d="M 140 1050 L 0 1050" fill="none" stroke="#D97706" stroke-width="2.5" stroke-dasharray="6,4" marker-end="url(#depArrow)"/>
    <rect x="10" y="1020" width="120" height="26" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
    <text x="70" y="1037" font-size="11" font-weight="800" fill="#D97706" text-anchor="middle">Google Play / APNs</text>
    <text x="70" y="1068" font-size="10" fill="#B45309" text-anchor="middle" font-family="'Fira Code', monospace">OTA Push Bus</text>
  </g>

  <!-- ==================== NODE 2: CLOUD APPLICATION SERVER ==================== -->
  <g transform="translate(730, 130)">
    <polygon points="20,-20 670,-20 650,0 0,0" fill="url(#nodeTopGrad)" stroke="#475569" stroke-width="1.5"/>
    <polygon points="650,0 670,-20 670,1230 650,1250" fill="url(#nodeSideGrad)" stroke="#475569" stroke-width="1.5"/>
    <rect x="0" y="0" width="650" height="1250" rx="4" fill="#F8FAFC" stroke="#334155" stroke-width="2" filter="url(#shadow)"/>

    <g transform="translate(25, 30)">
      <text x="0" y="10" font-size="13" font-weight="700" fill="#64748B">&lt;&lt;device&gt;&gt;</text>
      <text x="0" y="32" font-size="18" font-weight="800" fill="#0F172A">Cloud Application Server (Docker Host)</text>
      <text x="0" y="55" font-size="12" fill="#475569" font-family="'Fira Code', monospace">Platform: Render.com Cloud / Ubuntu 22.04 LTS (4 vCPU, 8GB RAM)</text>

      <!-- Execution Environment: Docker Container -->
      <g transform="translate(0, 80)">
        <polygon points="15,-15 595,-15 580,0 0,0" fill="#D1FAE5" stroke="#059669" stroke-width="1"/>
        <polygon points="580,0 595,-15 595,1050 580,1065" fill="#A7F3D0" stroke="#059669" stroke-width="1"/>
        <rect x="0" y="0" width="580" height="1065" rx="4" fill="#F0FDF4" stroke="#059669" stroke-width="1.5"/>

        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#047857">&lt;&lt;container&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#065F46">Container: hotel-management-backend</text>
          <text x="0" y="55" font-size="11" fill="#047857" font-family="'Fira Code', monospace">Base Image: node:20-alpine (Port 3000)</text>

          <!-- Nested Execution Env: Node.js Engine -->
          <g transform="translate(0, 80)">
            <rect x="0" y="0" width="540" height="740" rx="6" fill="#FFFFFF" stroke="#10B981" stroke-width="1.5"/>
            <text x="20" y="30" font-size="12" font-weight="700" fill="#047857">&lt;&lt;execution environment&gt;&gt;</text>
            <text x="20" y="52" font-size="15" font-weight="800" fill="#065F46">Node.js 20+ LTS Runtime Engine</text>

            <!-- Artifact: main.js Monolith -->
            <g transform="translate(20, 80)">
              <rect x="0" y="0" width="500" height="520" rx="6" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
              <use href="#artifactIcon" x="465" y="15"/>

              <g transform="translate(20, 30)">
                <text x="0" y="10" font-size="12" font-weight="700" fill="#047857">&lt;&lt;artifact&gt;&gt;</text>
                <text x="0" y="32" font-size="15" font-weight="800" fill="#0F172A">dist/src/main.js (NestJS Monolith)</text>

                <rect x="0" y="55" width="460" height="90" rx="4" fill="#FFFFFF" stroke="#E2E8F0"/>
                <text x="15" y="78" font-size="12" font-weight="700" fill="#1E293B">API Gateway &amp; Middleware</text>
                <text x="15" y="98" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">CORS, Compression, Global Prefix /api/v1</text>
                <text x="15" y="118" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">ValidationPipe, AllExceptionsFilter</text>

                <rect x="0" y="160" width="460" height="85" rx="4" fill="#FFFFFF" stroke="#E2E8F0"/>
                <text x="15" y="183" font-size="12" font-weight="700" fill="#1E293B">Security &amp; Authorization Layer</text>
                <text x="15" y="203" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">JwtAuthGuard, RolesGuard (RBAC)</text>
                <text x="15" y="223" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">ActiveSessionId Single Device Validator</text>

                <rect x="0" y="260" width="460" height="100" rx="4" fill="#FFFFFF" stroke="#E2E8F0"/>
                <text x="15" y="283" font-size="12" font-weight="700" fill="#1E293B">Domain Services &amp; Event Bus</text>
                <text x="15" y="303" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">BookingsService (Overlap check), Invoices</text>
                <text x="15" y="323" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">ShiftsService (Cash handover reconciliation)</text>
                <text x="15" y="343" font-size="11" font-weight="600" fill="#059669" font-family="'Fira Code', monospace">RoomEventsService: RxJS Subject / SSE Bus</text>

                <rect x="0" y="375" width="460" height="85" rx="4" fill="#FFFFFF" stroke="#E2E8F0"/>
                <text x="15" y="398" font-size="12" font-weight="700" fill="#1E293B">Task Automation &amp; Prisma ORM</text>
                <text x="15" y="418" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">CheckinReminderService (@Cron 09:00 AM)</text>
                <text x="15" y="438" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">PrismaService (Type-Safe Query / $transaction)</text>
              </g>
            </g>

            <!-- Artifact: .env Config -->
            <g transform="translate(20, 840)">
              <rect x="0" y="0" width="500" height="90" rx="6" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
              <use href="#artifactIcon" x="465" y="15"/>
              <text x="20" y="30" font-size="12" font-weight="700" fill="#047857">&lt;&lt;artifact&gt;&gt;</text>
              <text x="20" y="52" font-size="15" font-weight="800" fill="#0F172A">.env (Configuration &amp; Secrets)</text>
              <text x="20" y="74" font-size="11" fill="#64748B" font-family="'Fira Code', monospace">DATABASE_URL, REDIS_URL, ELASTICSEARCH_NODE, JWT_SECRET</text>
            </g>
          </g>
        </g>
      </g>
    </g>
  </g>

  <!-- ==================== CONNECTORS (SERVER <-> DATA & SAAS) ==================== -->
  <g transform="translate(1400, 130)">
    <!-- PostgreSQL Port 5432 -->
    <path d="M 0 350 L 170 350" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="25" y="325" width="120" height="22" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="85" y="340" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 5432 / TCP</text>

    <!-- Redis Port 6379 -->
    <path d="M 0 540 L 170 540" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="25" y="515" width="120" height="22" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="85" y="530" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 6379 / TCP</text>

    <!-- Elasticsearch Port 9200 -->
    <path d="M 0 730 L 170 730" fill="none" stroke="#059669" stroke-width="2.5" marker-end="url(#depArrowEmerald)"/>
    <rect x="25" y="705" width="120" height="22" rx="4" fill="#ECFDF5" stroke="#A7F3D0"/>
    <text x="85" y="720" font-size="10" font-weight="700" fill="#047857" text-anchor="middle">Port 9200 / HTTP</text>

    <!-- Third-Party SaaS Outbound Calls -->
    <path d="M 0 980 L 170 980" fill="none" stroke="#D97706" stroke-width="2.5" stroke-dasharray="6,4" marker-end="url(#depArrow)"/>
    <rect x="25" y="955" width="120" height="22" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
    <text x="85" y="970" font-size="10" font-weight="700" fill="#D97706" text-anchor="middle">HTTPS / Port 587</text>
  </g>

  <!-- ==================== NODE 3: DATABASE & SAAS INFRASTRUCTURE ==================== -->
  <g transform="translate(1570, 130)">
    <polygon points="20,-20 590,-20 570,0 0,0" fill="url(#nodeTopGrad)" stroke="#475569" stroke-width="1.5"/>
    <polygon points="570,0 590,-20 590,1230 570,1250" fill="url(#nodeSideGrad)" stroke="#475569" stroke-width="1.5"/>
    <rect x="0" y="0" width="570" height="1250" rx="4" fill="#F8FAFC" stroke="#334155" stroke-width="2" filter="url(#shadow)"/>

    <g transform="translate(25, 30)">
      <text x="0" y="10" font-size="13" font-weight="700" fill="#64748B">&lt;&lt;device&gt;&gt;</text>
      <text x="0" y="32" font-size="18" font-weight="800" fill="#0F172A">Database &amp; Acceleration Infrastructure</text>
      <text x="0" y="55" font-size="12" fill="#475569" font-family="'Fira Code', monospace">Dedicated Managed Nodes / High-speed Private VPC</text>

      <!-- Container: PostgreSQL -->
      <g transform="translate(0, 80)">
        <rect x="0" y="0" width="520" height="175" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="1.8"/>
        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#B45309">&lt;&lt;container&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#92400E">Container: postgres-db (PostgreSQL 16)</text>
          <text x="0" y="55" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Port: 5432 / TCP (Private Network)</text>

          <rect x="0" y="70" width="480" height="65" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="92" font-size="12" font-weight="700" fill="#92400E">Data Volume: /var/lib/postgresql/data (NVMe SSD)</text>
          <text x="15" y="112" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Tuân thủ nghiêm ngặt tính chất ACID &amp; Transaction Isolation</text>
        </g>
      </g>

      <!-- Container: Redis -->
      <g transform="translate(0, 275)">
        <rect x="0" y="0" width="520" height="170" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="1.8"/>
        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#B45309">&lt;&lt;container&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#92400E">Container: redis-cache (Redis 7.0 In-Memory)</text>
          <text x="0" y="55" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Port: 6379 / TCP (Private Network)</text>

          <rect x="0" y="70" width="480" height="60" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="92" font-size="12" font-weight="700" fill="#92400E">In-Memory Key-Value Caching Layer</text>
          <text x="15" y="112" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Cache phòng trống &amp; minibar, lưu trữ blacklist token TTL</text>
        </g>
      </g>

      <!-- Container: Elasticsearch -->
      <g transform="translate(0, 465)">
        <rect x="0" y="0" width="520" height="170" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="1.8"/>
        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#B45309">&lt;&lt;container&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#92400E">Container: elasticsearch-node (Elasticsearch 8.13)</text>
          <text x="0" y="55" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Port: 9200 / HTTP REST API</text>

          <rect x="0" y="70" width="480" height="60" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="92" font-size="12" font-weight="700" fill="#92400E">Distributed Full-Text Search Engine</text>
          <text x="15" y="112" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Indices: rooms, room_types; Tìm kiếm siêu tốc &lt; 50ms</text>
        </g>
      </g>

      <!-- Cloud System: Third-Party SaaS Services -->
      <g transform="translate(0, 655)">
        <rect x="0" y="0" width="520" height="385" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="1.8"/>
        <g transform="translate(20, 25)">
          <text x="0" y="10" font-size="12" font-weight="700" fill="#B45309">&lt;&lt;cloud system&gt;&gt;</text>
          <text x="0" y="32" font-size="16" font-weight="800" fill="#92400E">Third-Party SaaS Services (Đám mây ngoại vi)</text>

          <rect x="0" y="55" width="480" height="90" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="78" font-size="13" font-weight="700" fill="#92400E">Google Firebase Cloud Messaging (FCM)</text>
          <text x="15" y="100" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Push Notification Gateway qua HTTPS Google Cloud API</text>
          <text x="15" y="122" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Đồng bộ tin thông báo đơn đặt và trạng thái ca trực</text>

          <rect x="0" y="160" width="480" height="90" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="183" font-size="13" font-weight="700" fill="#92400E">SMTP Email Gateway (Google / SendGrid)</text>
          <text x="15" y="205" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Port 587 (TLS): Gửi OTP đặt lại mật khẩu &amp; Thư chào đón</text>
          <text x="15" y="227" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Xác thực SPF, DKIM đảm bảo uy tín hộp thư đến</text>

          <rect x="0" y="265" width="480" height="85" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
          <text x="15" y="288" font-size="13" font-weight="700" fill="#92400E">Cloudinary Media CDN Storage</text>
          <text x="15" y="310" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">HTTPS API: Lưu trữ và phân phối ảnh phòng khách sạn HD</text>
          <text x="15" y="332" font-size="11" fill="#B45309" font-family="'Fira Code', monospace">Tự động nén ảnh WebP và tối ưu phân giải di động</text>
        </g>
      </g>
    </g>
  </g>
</svg>`;

  return createHtmlWrapper('Deployment Diagram - Luxe Grand Hotel', width, height, svg);
}

// =============================================================
// DIAGRAM 4: CLASS DIAGRAM
// =============================================================
function generateClassDiagram() {
  const width = 2250;
  const height = 1550;

  const svg = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  ${commonDefs}

  <!-- Header Banner -->
  <rect x="0" y="0" width="${width}" height="90" rx="8" fill="url(#headerGrad)"/>
  <text x="40" y="42" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#FFFFFF" letter-spacing="0.5">
    UML CLASS DIAGRAM: MÔ HÌNH LỚP THỰC THỂ CỐT LÕI (CORE DOMAIN ENTITIES)
  </text>
  <text x="40" y="72" font-family="'Inter', sans-serif" font-size="15" font-weight="500" fill="#6EE7B7">
    Bám sát chính xác Lược đồ Cơ sở dữ liệu Prisma (PostgreSQL) và các Thực thể miền (Domain Models) trong ứng dụng Flutter
  </text>

  <!-- ==================== LEFT COLUMN: SYSTEM ENUMS ==================== -->
  <g transform="translate(40, 115)">
    <rect x="0" y="0" width="280" height="1410" rx="8" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="2" filter="url(#shadow)"/>
    <text x="20" y="35" font-family="'Inter', sans-serif" font-size="16" font-weight="800" fill="#1E293B">HỆ THỐNG ENUMS</text>

    <!-- Role Enum -->
    <g transform="translate(15, 55)">
      <rect x="0" y="0" width="250" height="110" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; Role</text>
      <text x="15" y="48" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ ADMIN (Quản trị viên)</text>
      <text x="15" y="70" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ RECEPTIONIST (Lễ tân)</text>
      <text x="15" y="92" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ CUSTOMER (Khách hàng)</text>
    </g>

    <!-- RoomStatus Enum -->
    <g transform="translate(15, 180)">
      <rect x="0" y="0" width="250" height="150" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; RoomStatus</text>
      <text x="15" y="48" font-size="11" fill="#059669" font-family="'Fira Code', monospace; font-weight:700">+ AVAILABLE (Xanh lá)</text>
      <text x="15" y="70" font-size="11" fill="#DC2626" font-family="'Fira Code', monospace; font-weight:700">+ OCCUPIED (Đỏ)</text>
      <text x="15" y="92" font-size="11" fill="#2563EB" font-family="'Fira Code', monospace; font-weight:700">+ RESERVED (Xanh dương)</text>
      <text x="15" y="114" font-size="11" fill="#D97706" font-family="'Fira Code', monospace; font-weight:700">+ CLEANING (Vàng cam)</text>
      <text x="15" y="136" font-size="11" fill="#64748B" font-family="'Fira Code', monospace; font-weight:700">+ MAINTENANCE (Xám)</text>
    </g>

    <!-- BookingStatus Enum -->
    <g transform="translate(15, 345)">
      <rect x="0" y="0" width="250" height="150" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; BookingStatus</text>
      <text x="15" y="48" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ PENDING (Chờ duyệt)</text>
      <text x="15" y="70" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ CONFIRMED (Đã duyệt)</text>
      <text x="15" y="92" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ CHECKED_IN (Đang ở)</text>
      <text x="15" y="114" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ CHECKED_OUT (Đã trả)</text>
      <text x="15" y="136" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ CANCELLED (Đã hủy)</text>
    </g>

    <!-- PaymentStatus Enum -->
    <g transform="translate(15, 510)">
      <rect x="0" y="0" width="250" height="130" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; PaymentStatus</text>
      <text x="15" y="48" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ UNPAID (Chưa thanh toán)</text>
      <text x="15" y="70" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ PARTIAL (Đã cọc 1 phần)</text>
      <text x="15" y="92" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ PAID (Đã thanh toán đủ)</text>
      <text x="15" y="114" font-size="11" fill="#475569" font-family="'Fira Code', monospace">+ REFUNDED (Đã hoàn tiền)</text>
    </g>

    <!-- PaymentEntryType & Status -->
    <g transform="translate(15, 655)">
      <rect x="0" y="0" width="250" height="160" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; EntryType / Status</text>
      <text x="15" y="48" font-size="11" fill="#475569" font-family="'Fira Code', monospace">Entry: PAYMENT | DEPOSIT |</text>
      <text x="15" y="66" font-size="11" fill="#475569" font-family="'Fira Code', monospace">       REFUND</text>
      <text x="15" y="92" font-size="11" fill="#475569" font-family="'Fira Code', monospace">Status: PENDING | CONFIRMED |</text>
      <text x="15" y="110" font-size="11" fill="#475569" font-family="'Fira Code', monospace">        REJECTED</text>
      <text x="15" y="136" font-size="11" fill="#475569" font-family="'Fira Code', monospace">Method: CASH | CREDIT_CARD |</text>
      <text x="15" y="152" font-size="11" fill="#475569" font-family="'Fira Code', monospace">        BANK_TRANSFER</text>
    </g>

    <!-- ShiftStatus Enum -->
    <g transform="translate(15, 830)">
      <rect x="0" y="0" width="250" height="140" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
      <rect x="0" y="0" width="250" height="28" fill="#F1F5F9"/>
      <text x="125" y="19" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">&lt;&lt;enumeration&gt;&gt; ShiftType / Status</text>
      <text x="15" y="48" font-size="11" fill="#475569" font-family="'Fira Code', monospace">ShiftType: MORNING | AFTERNOON |</text>
      <text x="15" y="66" font-size="11" fill="#475569" font-family="'Fira Code', monospace">           NIGHT | CUSTOM</text>
      <text x="15" y="100" font-size="11" fill="#475569" font-family="'Fira Code', monospace">ShiftStatus: OPEN | CLOSED</text>
      <text x="15" y="122" font-size="11" fill="#475569" font-family="'Fira Code', monospace">Handover: PENDING | COMPLETED</text>
    </g>
  </g>

  <!-- ==================== CORE CLASSES (CENTER & RIGHT) ==================== -->

  <!-- Class 1: User -->
  <g transform="translate(360, 160)">
    <rect x="0" y="0" width="380" height="340" rx="6" fill="#FFFFFF" stroke="#2563EB" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="380" height="42" fill="#EFF6FF"/>
    <text x="190" y="26" font-size="16" font-weight="800" fill="#1D4ED8" text-anchor="middle">User</text>
    <line x1="0" y1="42" x2="380" y2="42" stroke="#2563EB" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ email: String (Unique)</text>
      <text x="0" y="36">- password: String (Bcrypt Hash)</text>
      <text x="0" y="54">+ fullName: String</text>
      <text x="0" y="72">+ phone: String?</text>
      <text x="0" y="90">+ avatar: String?</text>
      <text x="0" y="108">+ role: Role = CUSTOMER</text>
      <text x="0" y="126">+ isActive: Boolean = true</text>
      <text x="0" y="144">+ activeSessionId: String? (Single device)</text>
      <text x="0" y="162">+ fcmToken: String?</text>
      <text x="0" y="180">+ createdAt: DateTime</text>
    </g>
    <line x1="0" y1="260" x2="380" y2="260" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 280)" font-family="'Fira Code', monospace" font-size="11" fill="#2563EB">
      <text x="0" y="0">+ validatePassword(raw: String): Boolean</text>
      <text x="0" y="18">+ generateJwtToken(): String</text>
      <text x="0" y="36">+ hasPermission(role: Role): Boolean</text>
    </g>
  </g>

  <!-- Class 2: RoomType -->
  <g transform="translate(800, 160)">
    <rect x="0" y="0" width="380" height="340" rx="6" fill="#FFFFFF" stroke="#059669" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="380" height="42" fill="#ECFDF5"/>
    <text x="190" y="26" font-size="16" font-weight="800" fill="#047857" text-anchor="middle">RoomType</text>
    <line x1="0" y1="42" x2="380" y2="42" stroke="#059669" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ name: String (Unique)</text>
      <text x="0" y="36">+ code: String (STD, DLX, SUI)</text>
      <text x="0" y="54">+ description: String?</text>
      <text x="0" y="72">+ basePrice: Decimal (Giá niêm yết/đêm)</text>
      <text x="0" y="90">+ capacityAdults: Int = 2</text>
      <text x="0" y="108">+ capacityChildren: Int = 1</text>
      <text x="0" y="126">+ sizeSqM: Decimal?</text>
      <text x="0" y="144">+ amenities: List&lt;String&gt;</text>
      <text x="0" y="162">+ images: List&lt;String&gt; (Cloudinary URLs)</text>
      <text x="0" y="180">+ createdAt: DateTime</text>
    </g>
    <line x1="0" y1="260" x2="380" y2="260" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 280)" font-family="'Fira Code', monospace" font-size="11" fill="#047857">
      <text x="0" y="0">+ calculateStayPrice(nights: Int): Decimal</text>
      <text x="0" y="18">+ getAvailableRooms(): List&lt;Room&gt;</text>
      <text x="0" y="36">+ updateAmenities(list: String[]): void</text>
    </g>
  </g>

  <!-- Class 3: Room -->
  <g transform="translate(1240, 160)">
    <rect x="0" y="0" width="380" height="340" rx="6" fill="#FFFFFF" stroke="#059669" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="380" height="42" fill="#ECFDF5"/>
    <text x="190" y="26" font-size="16" font-weight="800" fill="#047857" text-anchor="middle">Room</text>
    <line x1="0" y1="42" x2="380" y2="42" stroke="#059669" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ roomNumber: String (Unique, e.g. 101, 202)</text>
      <text x="0" y="36">+ floor: Int (Tầng của phòng)</text>
      <text x="0" y="54">+ status: RoomStatus = AVAILABLE</text>
      <text x="0" y="72">+ notes: String?</text>
      <text x="0" y="90">+ roomTypeId: String [FK]</text>
      <text x="0" y="108">+ createdAt: DateTime</text>
      <text x="0" y="126">+ updatedAt: DateTime</text>
    </g>
    <line x1="0" y1="210" x2="380" y2="210" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 230)" font-family="'Fira Code', monospace" font-size="11" fill="#047857">
      <text x="0" y="0">+ changeStatus(status: RoomStatus): void</text>
      <text x="0" y="18">+ isAvailable(start: Date, end: Date): Boolean</text>
      <text x="0" y="36">+ assignToBooking(bookingId: String): void</text>
      <text x="0" y="54">+ markCleaningCompleted(): void</text>
    </g>
  </g>

  <!-- Class 4: WorkShift -->
  <g transform="translate(1680, 160)">
    <rect x="0" y="0" width="410" height="340" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="410" height="42" fill="#FEF3C7"/>
    <text x="205" y="26" font-size="16" font-weight="800" fill="#B45309" text-anchor="middle">WorkShift (Ca trực lễ tân)</text>
    <line x1="0" y1="42" x2="410" y2="42" stroke="#D97706" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ shiftType: ShiftType = MORNING</text>
      <text x="0" y="36">+ startTime: DateTime</text>
      <text x="0" y="54">+ endTime: DateTime?</text>
      <text x="0" y="72">+ openingCash: Decimal (Tiền đầu ca)</text>
      <text x="0" y="90">+ expectedCash: Decimal (Hệ thống tính)</text>
      <text x="0" y="108">+ actualClosingCash: Decimal? (Đếm thực tế)</text>
      <text x="0" y="126">+ discrepancy: Decimal = 0 (Sai lệch két)</text>
      <text x="0" y="144">+ status: ShiftStatus = OPEN</text>
      <text x="0" y="162">+ staffId: String [FK] (Lễ tân ca này)</text>
      <text x="0" y="180">+ handoverStaffId: String? [FK] (Lễ tân nhận)</text>
    </g>
    <line x1="0" y1="260" x2="410" y2="260" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 280)" font-family="'Fira Code', monospace" font-size="11" fill="#B45309">
      <text x="0" y="0">+ openShift(initialCash: Decimal): void</text>
      <text x="0" y="18">+ recordCashTransaction(amount: Decimal): void</text>
      <text x="0" y="36">+ closeAndHandover(actualCash: Decimal): void</text>
    </g>
  </g>

  <!-- Class 5: Booking -->
  <g transform="translate(800, 590)">
    <rect x="0" y="0" width="410" height="390" rx="6" fill="#FFFFFF" stroke="#2563EB" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="410" height="42" fill="#EFF6FF"/>
    <text x="205" y="26" font-size="16" font-weight="800" fill="#1D4ED8" text-anchor="middle">Booking (Đơn đặt phòng)</text>
    <line x1="0" y1="42" x2="410" y2="42" stroke="#2563EB" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ bookingCode: String (Unique, e.g. BK-2026-001)</text>
      <text x="0" y="36">+ checkInDate: DateTime</text>
      <text x="0" y="54">+ checkOutDate: DateTime</text>
      <text x="0" y="72">+ totalPrice: Decimal</text>
      <text x="0" y="90">+ status: BookingStatus = PENDING</text>
      <text x="0" y="108">+ specialRequests: String?</text>
      <text x="0" y="126">+ actualCheckIn: DateTime?</text>
      <text x="0" y="144">+ actualCheckOut: DateTime?</text>
      <text x="0" y="162">+ cancellationReason: String?</text>
      <text x="0" y="180">+ userId: String [FK] (Khách hàng đặt)</text>
      <text x="0" y="198">+ roomId: String [FK] (Phòng chỉ định)</text>
      <text x="0" y="216">+ confirmedById: String? [FK] (Lễ tân duyệt)</text>
    </g>
    <line x1="0" y1="285" x2="410" y2="285" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 305)" font-family="'Fira Code', monospace" font-size="11" fill="#1D4ED8">
      <text x="0" y="0">+ confirmBooking(staffId: String): void</text>
      <text x="0" y="18">+ checkInCustomer(): void</text>
      <text x="0" y="36">+ changeRoom(newRoomId: String): void</text>
      <text x="0" y="54">+ checkOutCustomer(): void</text>
      <text x="0" y="72">+ cancelBooking(reason: String): void</text>
    </g>
  </g>

  <!-- Class 6: Invoice -->
  <g transform="translate(360, 590)">
    <rect x="0" y="0" width="380" height="390" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="380" height="42" fill="#FEF3C7"/>
    <text x="190" y="26" font-size="16" font-weight="800" fill="#B45309" text-anchor="middle">Invoice (Hóa đơn lưu trú)</text>
    <line x1="0" y1="42" x2="380" y2="42" stroke="#D97706" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ invoiceNumber: String (Unique, INV-001)</text>
      <text x="0" y="36">+ roomAmount: Decimal (Tiền phòng)</text>
      <text x="0" y="54">+ servicesAmount: Decimal = 0 (Minibar/F&amp;B)</text>
      <text x="0" y="72">+ discountAmount: Decimal = 0</text>
      <text x="0" y="90">+ finalAmount: Decimal (Tổng sau giảm)</text>
      <text x="0" y="108">+ paidAmount: Decimal = 0 (Đã thanh toán)</text>
      <text x="0" y="126">+ remainingAmount: Decimal (Còn nợ)</text>
      <text x="0" y="144">+ status: PaymentStatus = UNPAID</text>
      <text x="0" y="162">+ bookingId: String [FK] (1-1 với Booking)</text>
      <text x="0" y="180">+ issuedById: String? [FK] (Thu ngân xuất)</text>
    </g>
    <line x1="0" y1="285" x2="380" y2="285" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 305)" font-family="'Fira Code', monospace" font-size="11" fill="#B45309">
      <text x="0" y="0">+ recalculateBalances(): void</text>
      <text x="0" y="18">+ addPaymentEntry(p: Payment): void</text>
      <text x="0" y="36">+ isFullySettled(): Boolean</text>
      <text x="0" y="54">+ issueReceipt(): void</text>
    </g>
  </g>

  <!-- Class 7: Payment -->
  <g transform="translate(360, 1070)">
    <rect x="0" y="0" width="380" height="340" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="380" height="42" fill="#FEF3C7"/>
    <text x="190" y="26" font-size="16" font-weight="800" fill="#B45309" text-anchor="middle">Payment (Dòng thu tiền đa đợt)</text>
    <line x1="0" y1="42" x2="380" y2="42" stroke="#D97706" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ amount: Decimal (Số tiền giao dịch)</text>
      <text x="0" y="36">+ method: PaymentMethod</text>
      <text x="0" y="54">+ entryType: PaymentEntryType = PAYMENT</text>
      <text x="0" y="72">+ status: PaymentEntryStatus = PENDING</text>
      <text x="0" y="90">+ transactionRef: String? (Mã chuyển khoản)</text>
      <text x="0" y="108">+ invoiceId: String [FK]</text>
      <text x="0" y="126">+ createdById: String [FK]</text>
      <text x="0" y="144">+ confirmedById: String? [FK] (Thu ngân duyệt)</text>
    </g>
    <line x1="0" y1="240" x2="380" y2="240" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 260)" font-family="'Fira Code', monospace" font-size="11" fill="#B45309">
      <text x="0" y="0">+ confirmReceipt(cashierId: String): void</text>
      <text x="0" y="18">+ rejectReceipt(reason: String): void</text>
    </g>
  </g>

  <!-- Class 8: ExtraServiceOrder & HotelService -->
  <g transform="translate(1330, 590)">
    <!-- ExtraServiceOrder -->
    <rect x="0" y="0" width="410" height="260" rx="6" fill="#FFFFFF" stroke="#6366F1" stroke-width="2" filter="url(#shadow)"/>
    <rect x="0" y="0" width="410" height="42" fill="#EEF2FF"/>
    <text x="205" y="26" font-size="16" font-weight="800" fill="#4338CA" text-anchor="middle">ExtraServiceOrder (Order dịch vụ)</text>
    <line x1="0" y1="42" x2="410" y2="42" stroke="#6366F1" stroke-width="1.5"/>
    <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
      <text x="0" y="0">+ id: String [PK] (UUID)</text>
      <text x="0" y="18">+ quantity: Int = 1</text>
      <text x="0" y="36">+ unitPrice: Decimal</text>
      <text x="0" y="54">+ totalCost: Decimal (quantity * unitPrice)</text>
      <text x="0" y="72">+ status: String (DELIVERED, PENDING)</text>
      <text x="0" y="90">+ bookingId: String [FK]</text>
      <text x="0" y="108">+ serviceId: String [FK]</text>
    </g>
    <line x1="0" y1="180" x2="410" y2="180" stroke="#E2E8F0" stroke-width="1.5"/>
    <g transform="translate(15, 200)" font-family="'Fira Code', monospace" font-size="11" fill="#4338CA">
      <text x="0" y="0">+ calculateCost(): Decimal</text>
      <text x="0" y="18">+ updateDeliveryStatus(s: String): void</text>
    </g>

    <!-- HotelService -->
    <g transform="translate(0, 330)">
      <rect x="0" y="0" width="410" height="250" rx="6" fill="#FFFFFF" stroke="#6366F1" stroke-width="2" filter="url(#shadow)"/>
      <rect x="0" y="0" width="410" height="42" fill="#EEF2FF"/>
      <text x="205" y="26" font-size="16" font-weight="800" fill="#4338CA" text-anchor="middle">HotelService (Danh mục dịch vụ)</text>
      <line x1="0" y1="42" x2="410" y2="42" stroke="#6366F1" stroke-width="1.5"/>
      <g transform="translate(15, 60)" font-family="'Fira Code', monospace" font-size="11" fill="#1E293B">
        <text x="0" y="0">+ id: String [PK] (UUID)</text>
        <text x="0" y="18">+ name: String (Minibar Snack, Giặt ủi...)</text>
        <text x="0" y="36">+ code: String (Unique)</text>
        <text x="0" y="54">+ price: Decimal</text>
        <text x="0" y="72">+ category: String (F&amp;B, LAUNDRY, SPA)</text>
        <text x="0" y="90">+ isAvailable: Boolean = true</text>
      </g>
    </g>
  </g>

  <!-- ==================== RELATIONSHIPS & CONNECTORS ==================== -->
  
  <!-- CRITICAL FIX: User 1 -> 0..* WorkShift (ROUTED CLEANLY WITH AMPLE HEADROOM) -->
  <path d="M 550 160 L 550 128 L 1885 128 L 1885 160" fill="none" stroke="#1E293B" stroke-width="2" marker-end="url(#assocArrow)"/>
  <rect x="535" y="138" width="22" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="546" y="151" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="1875" y="138" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1889" y="151" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">0..*</text>
  <rect x="1000" y="115" width="280" height="24" rx="4" fill="#FFFFFF" stroke="#94A3B8"/>
  <text x="1140" y="131" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">operates shift (lễ tân vận hành ca trực)</text>

  <!-- User 1 -> 0..* Booking -->
  <path d="M 550 500 L 550 545 L 950 545 L 950 590" fill="none" stroke="#1E293B" stroke-width="2" marker-end="url(#assocArrow)"/>
  <rect x="540" y="505" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="550" y="518" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="960" y="565" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="974" y="578" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">0..*</text>
  <rect x="680" y="533" width="140" height="24" rx="4" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="750" y="549" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">places (đặt phòng)</text>

  <!-- RoomType 1 ◆-> 1..* Room (Composition) -->
  <path d="M 1180 330 L 1240 330" fill="none" stroke="#1E293B" stroke-width="2" marker-start="url(#compDiamond)"/>
  <rect x="1195" y="305" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1205" y="318" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="1225" y="305" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1239" y="318" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1..*</text>
  <rect x="1185" y="340" width="50" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1210" y="354" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">defines</text>

  <!-- Room 1 -> 0..* Booking -->
  <path d="M 1430 500 L 1430 545 L 1050 545 L 1050 590" fill="none" stroke="#1E293B" stroke-width="2" marker-end="url(#assocArrow)"/>
  <rect x="1440" y="505" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1450" y="518" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="1060" y="565" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1074" y="578" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">0..*</text>
  <rect x="1200" y="533" width="100" height="24" rx="4" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1250" y="549" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">assigned to</text>

  <!-- Booking 1 ◆- 1 Invoice (Composition) -->
  <path d="M 800 780 L 740 780" fill="none" stroke="#1E293B" stroke-width="2" marker-start="url(#compDiamond)"/>
  <rect x="780" y="755" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="790" y="768" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="740" y="755" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="750" y="768" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="750" y="790" width="40" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="770" y="804" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">bills</text>

  <!-- Invoice 1 ◆-> 1..* Payment (Composition) -->
  <path d="M 550 980 L 550 1070" fill="none" stroke="#1E293B" stroke-width="2" marker-start="url(#compDiamond)"/>
  <rect x="560" y="990" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="570" y="1003" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="560" y="1045" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="574" y="1058" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1..*</text>
  <rect x="560" y="1018" width="60" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="590" y="1032" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">records</text>

  <!-- Booking 1 -> 0..* ExtraServiceOrder -->
  <path d="M 1210 780 L 1330 780" fill="none" stroke="#1E293B" stroke-width="2" marker-end="url(#assocArrow)"/>
  <rect x="1220" y="755" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1230" y="768" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="1305" y="755" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1319" y="768" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">0..*</text>
  <rect x="1250" y="790" width="50" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1275" y="804" font-family="'Inter', sans-serif" font-size="11" font-weight="700" fill="#64748B" text-anchor="middle">orders</text>

  <!-- HotelService 1 -> 0..* ExtraServiceOrder -->
  <path d="M 1530 920 L 1530 850" fill="none" stroke="#1E293B" stroke-width="2" marker-end="url(#assocArrow)"/>
  <rect x="1540" y="895" width="20" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1550" y="908" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">1</text>
  <rect x="1540" y="860" width="28" height="18" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1554" y="873" font-size="11" font-weight="800" fill="#1E293B" text-anchor="middle">0..*</text>
</svg>`;

  return createHtmlWrapper('Class Diagram - Luxe Grand Hotel', width, height, svg);
}

// =============================================================
// DIAGRAM 5: SEQUENCE DIAGRAM
// =============================================================
function generateSequenceDiagram() {
  const width = 2250;
  const height = 1650;

  const svg = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">
  ${commonDefs}

  <!-- Header Banner -->
  <rect x="0" y="0" width="${width}" height="90" rx="8" fill="url(#headerGrad)"/>
  <text x="40" y="42" font-family="'Inter', sans-serif" font-size="26" font-weight="800" fill="#FFFFFF" letter-spacing="0.5">
    UML SEQUENCE DIAGRAM: QUY TRÌNH ĐẶT PHÒNG, PHÊ DUYỆT, CHECK-IN &amp; ĐỒNG BỘ REALTIME
  </text>
  <text x="40" y="72" font-family="'Inter', sans-serif" font-size="15" font-weight="500" fill="#FDE047">
    Mô hình hóa tương tác theo trục thời gian giữa Khách hàng, Lễ tân, Flutter BLoC, NestJS API, PostgreSQL và Realtime Event Bus
  </text>

  <!-- ==================== PARTICIPANTS (LIFELINES) ==================== -->
  <!-- Lifeline dashed lines -->
  <g stroke="#94A3B8" stroke-width="1.5" stroke-dasharray="6,6">
    <line x1="100" y1="180" x2="100" y2="1590"/>
    <line x1="300" y1="180" x2="300" y2="1590"/>
    <line x1="500" y1="180" x2="500" y2="1590"/>
    <line x1="700" y1="180" x2="700" y2="1590"/>
    <line x1="900" y1="180" x2="900" y2="1590"/>
    <line x1="1130" y1="180" x2="1130" y2="1590"/>
    <line x1="1360" y1="180" x2="1360" y2="1590"/>
    <line x1="1580" y1="180" x2="1580" y2="1590"/>
    <line x1="1780" y1="180" x2="1780" y2="1590"/>
    <line x1="1980" y1="180" x2="1980" y2="1590"/>
    <line x1="2140" y1="180" x2="2140" y2="1590"/>
  </g>

  <!-- P1: Customer Actor -->
  <g transform="translate(60, 115)">
    <circle cx="40" cy="12" r="10" fill="#EFF6FF" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="22" x2="40" y2="35" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="30" y1="27" x2="50" y2="27" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="35" x2="32" y2="48" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="35" x2="48" y2="48" stroke="#2563EB" stroke-width="1.5"/>
    <text x="40" y="62" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">Customer</text>
  </g>

  <!-- P2: Flutter UI Customer -->
  <g transform="translate(225, 120)">
    <rect x="0" y="0" width="150" height="50" rx="4" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
    <text x="75" y="22" font-size="11" font-weight="600" fill="#1D4ED8" text-anchor="middle">&lt;&lt;boundary&gt;&gt;</text>
    <text x="75" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">Customer App UI</text>
  </g>

  <!-- P3: BLoC -->
  <g transform="translate(425, 120)">
    <rect x="0" y="0" width="150" height="50" rx="4" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
    <text x="75" y="22" font-size="11" font-weight="600" fill="#1D4ED8" text-anchor="middle">&lt;&lt;control&gt;&gt;</text>
    <text x="75" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">BookingBloc</text>
  </g>

  <!-- P4: DioClient -->
  <g transform="translate(630, 120)">
    <rect x="0" y="0" width="140" height="50" rx="4" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
    <text x="70" y="22" font-size="11" font-weight="600" fill="#1D4ED8" text-anchor="middle">&lt;&lt;adapter&gt;&gt;</text>
    <text x="70" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">DioClient</text>
  </g>

  <!-- P5: Gateway / Guards -->
  <g transform="translate(825, 120)">
    <rect x="0" y="0" width="150" height="50" rx="4" fill="#ECFDF5" stroke="#059669" stroke-width="2"/>
    <text x="75" y="22" font-size="11" font-weight="600" fill="#047857" text-anchor="middle">&lt;&lt;security&gt;&gt;</text>
    <text x="75" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">NestJS Gateway</text>
  </g>

  <!-- P6: Controller & Service -->
  <g transform="translate(1045, 120)">
    <rect x="0" y="0" width="170" height="50" rx="4" fill="#ECFDF5" stroke="#059669" stroke-width="2"/>
    <text x="85" y="22" font-size="11" font-weight="600" fill="#047857" text-anchor="middle">&lt;&lt;service&gt;&gt;</text>
    <text x="85" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">BookingsService</text>
  </g>

  <!-- P7: Prisma & DB -->
  <g transform="translate(1280, 120)">
    <rect x="0" y="0" width="160" height="50" rx="4" fill="#FEF3C7" stroke="#D97706" stroke-width="2"/>
    <text x="80" y="22" font-size="11" font-weight="600" fill="#B45309" text-anchor="middle">&lt;&lt;database&gt;&gt;</text>
    <text x="80" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">Prisma / Postgres</text>
  </g>

  <!-- P8: RoomEventsService -->
  <g transform="translate(1500, 120)">
    <rect x="0" y="0" width="160" height="50" rx="4" fill="#ECFDF5" stroke="#059669" stroke-width="2"/>
    <text x="80" y="22" font-size="11" font-weight="600" fill="#047857" text-anchor="middle">&lt;&lt;event bus&gt;&gt;</text>
    <text x="80" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">RoomEventsService</text>
  </g>

  <!-- P9: SSE Client & FCM -->
  <g transform="translate(1700, 120)">
    <rect x="0" y="0" width="160" height="50" rx="4" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
    <text x="80" y="22" font-size="11" font-weight="600" fill="#1D4ED8" text-anchor="middle">&lt;&lt;realtime&gt;&gt;</text>
    <text x="80" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">SseClient &amp; FCM</text>
  </g>

  <!-- P10: Receptionist App UI -->
  <g transform="translate(1910, 120)">
    <rect x="0" y="0" width="140" height="50" rx="4" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
    <text x="70" y="22" font-size="11" font-weight="600" fill="#1D4ED8" text-anchor="middle">&lt;&lt;boundary&gt;&gt;</text>
    <text x="70" y="38" font-size="13" font-weight="800" fill="#1E293B" text-anchor="middle">Staff Matrix UI</text>
  </g>

  <!-- P11: Receptionist Actor -->
  <g transform="translate(2100, 115)">
    <circle cx="40" cy="12" r="10" fill="#EFF6FF" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="22" x2="40" y2="35" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="30" y1="27" x2="50" y2="27" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="35" x2="32" y2="48" stroke="#2563EB" stroke-width="1.5"/>
    <line x1="40" y1="35" x2="48" y2="48" stroke="#2563EB" stroke-width="1.5"/>
    <text x="40" y="62" font-size="12" font-weight="700" fill="#1E293B" text-anchor="middle">Receptionist</text>
  </g>

  <!-- ==================== PHASE 1: TẠO ĐƠN ĐẶT PHÒNG (ONLINE BOOKING) ==================== -->
  <g transform="translate(30, 210)">
    <rect x="0" y="0" width="2190" height="32" rx="4" fill="#EFF6FF" stroke="#93C5FD"/>
    <text x="20" y="21" font-size="13" font-weight="800" fill="#1D4ED8">
      GIAI ĐOẠN 1: KHÁCH HÀNG TÌM KIẾM &amp; TẠO ĐƠN ĐẶT PHÒNG TRỰC TUYẾN (ONLINE BOOKING CREATION)
    </text>
  </g>

  <!-- Step 1: Customer clicks booking -->
  <line x1="100" y1="275" x2="300" y2="275" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="110" y="260" width="180" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="200" y="274" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">1: Chọn phòng 101, nhấn Đặt</text>
  <rect x="295" y="275" width="10" height="255" fill="url(#actGrad)" stroke="#2563EB"/>

  <!-- Step 2: UI dispatches CreateBookingEvent -->
  <line x1="305" y1="305" x2="500" y2="305" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="320" y="290" width="165" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="400" y="304" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">2: dispatch(CreateBookingEvent)</text>
  <rect x="495" y="305" width="10" height="215" fill="url(#actGrad)" stroke="#2563EB"/>

  <!-- Step 3: BLoC calls Dio -->
  <line x1="505" y1="335" x2="700" y2="335" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="525" y="320" width="150" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="600" y="334" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">3: createBooking(dto)</text>
  <rect x="695" y="335" width="10" height="175" fill="url(#actGrad)" stroke="#2563EB"/>

  <!-- Step 4: Dio -> Gateway (HTTP POST) -->
  <line x1="705" y1="365" x2="900" y2="365" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="715" y="350" width="170" height="20" rx="3" fill="#FFFFFF" stroke="#93C5FD"/>
  <text x="800" y="364" font-size="11" font-weight="700" fill="#2563EB" text-anchor="middle">4: POST /bookings (Bearer JWT)</text>
  <rect x="895" y="365" width="10" height="135" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Step 5: Gateway -> Controller/Service -->
  <line x1="905" y1="395" x2="1130" y2="395" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="920" y="380" width="195" height="20" rx="3" fill="#FFFFFF" stroke="#A7F3D0"/>
  <text x="1015" y="394" font-size="11" font-weight="700" fill="#047857" text-anchor="middle">5: JwtGuard passed, chuyển Service</text>
  <rect x="1125" y="395" width="10" height="135" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Step 6: Service checks Overlap in DB -->
  <line x1="1135" y1="425" x2="1360" y2="425" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="1145" y="410" width="200" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1245" y="424" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">6: Interval Overlap Check (findFirst)</text>
  <rect x="1355" y="425" width="10" height="60" fill="url(#actGrad)" stroke="#D97706"/>

  <!-- Step 7: DB returns null (phòng trống) & atomic transaction -->
  <line x1="1355" y1="465" x2="1135" y2="465" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="1145" y="450" width="410" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1350" y="464" font-size="11" fill="#475569" text-anchor="middle">7: Phòng 101 trống, commit prisma.$transaction(Booking + Invoice UNPAID)</text>

  <!-- Step 8: Return response to Client -->
  <line x1="1125" y1="495" x2="705" y2="495" stroke="#059669" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="730" y="480" width="370" height="20" rx="3" fill="#FFFFFF" stroke="#A7F3D0"/>
  <text x="915" y="494" font-size="11" font-weight="700" fill="#059669" text-anchor="middle">8: HTTP 201 Created (Booking BK-101 status PENDING)</text>

  <line x1="695" y1="515" x2="505" y2="515" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="520" y="500" width="160" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="600" y="514" font-size="11" fill="#475569" text-anchor="middle">9: emit(BookingSuccess)</text>

  <line x1="495" y1="535" x2="305" y2="535" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="320" y="520" width="160" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="400" y="534" font-size="11" fill="#475569" text-anchor="middle">UI updates State</text>

  <line x1="295" y1="555" x2="100" y2="555" stroke="#2563EB" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="110" y="540" width="180" height="20" rx="3" fill="#FFFFFF" stroke="#93C5FD"/>
  <text x="200" y="554" font-size="11" font-weight="700" fill="#2563EB" text-anchor="middle">10: Modal thông báo thành công</text>


  <!-- ==================== PHASE 2: LỄ TÂN DUYỆT ĐƠN & REALTIME SYNC ==================== -->
  <g transform="translate(30, 610)">
    <rect x="0" y="0" width="2190" height="32" rx="4" fill="#ECFDF5" stroke="#6EE7B7"/>
    <text x="20" y="21" font-size="13" font-weight="800" fill="#065F46">
      GIAI ĐOẠN 2: LỄ TÂN PHÊ DUYỆT ĐƠN &amp; ĐỒNG BỘ REALTIME TỨC THÌ (APPROVAL &amp; REALTIME SYNC)
    </text>
  </g>

  <!-- Step 11: Receptionist clicks approve -->
  <line x1="2140" y1="675" x2="1980" y2="675" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="2000" y="660" width="130" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="2060" y="674" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">11: Bấm Phê duyệt #BK-101</text>
  <rect x="1975" y="675" width="10" height="255" fill="url(#actGrad)" stroke="#2563EB"/>

  <!-- Step 12: Staff App calls PATCH -->
  <line x1="1975" y1="705" x2="1135" y2="705" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="1400" y="690" width="310" height="20" rx="3" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1555" y="704" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">12: PATCH /api/v1/bookings/BK-101/approve (RolesGuard)</text>
  <rect x="1125" y="705" width="10" height="215" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Step 13: Service updates DB -->
  <line x1="1135" y1="735" x2="1360" y2="735" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="1145" y="720" width="210" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1250" y="734" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">13: Update CONFIRMED &amp; RESERVED</text>
  <rect x="1355" y="735" width="10" height="45" fill="url(#actGrad)" stroke="#D97706"/>

  <line x1="1355" y1="770" x2="1135" y2="770" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="1190" y="755" width="120" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1250" y="769" font-size="11" fill="#475569" text-anchor="middle">14: DB updated OK</text>

  <!-- Step 15: Service emits Event to RoomEventsService -->
  <line x1="1135" y1="800" x2="1580" y2="800" stroke="#D97706" stroke-width="2.5" marker-end="url(#asyncArrow)"/>
  <rect x="1190" y="785" width="340" height="20" rx="3" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1360" y="799" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">15: emitStatusChanged(room101, RESERVED) -&gt; Bus Publish</text>
  <rect x="1575" y="800" width="10" height="145" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Fan-out 1: Push Notification to Customer via FCM -->
  <line x1="1585" y1="835" x2="1780" y2="835" stroke="#D97706" stroke-width="2" stroke-dasharray="4,2" marker-end="url(#asyncArrow)"/>
  <rect x="1605" y="820" width="150" height="20" rx="3" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1680" y="834" font-size="11" font-weight="700" fill="#B45309" text-anchor="middle">16a: FCM Broadcast &amp; Push</text>

  <line x1="1780" y1="865" x2="300" y2="865" stroke="#D97706" stroke-width="2" stroke-dasharray="6,4" marker-end="url(#asyncArrow)"/>
  <rect x="850" y="850" width="380" height="22" rx="4" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1040" y="866" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">16b: Push Notification máy khách: "Đơn #BK-101 đã xác nhận!"</text>

  <!-- Fan-out 2: SSE Stream Push to Receptionist Screen -->
  <line x1="1585" y1="895" x2="1980" y2="895" stroke="#059669" stroke-width="2.5" stroke-dasharray="6,4" marker-end="url(#asyncArrow)"/>
  <rect x="1630" y="880" width="310" height="22" rx="4" fill="#FFFFFF" stroke="#A7F3D0"/>
  <text x="1785" y="896" font-size="11" font-weight="700" fill="#047857" text-anchor="middle">17: SSE Stream: room 101 status = RESERVED</text>

  <!-- Step 18: Matrix UI updates dynamically -->
  <line x1="1980" y1="925" x2="2140" y2="925" stroke="#059669" stroke-width="2" marker-end="url(#replyArrow)"/>
  <rect x="2000" y="910" width="130" height="20" rx="3" fill="#FFFFFF" stroke="#A7F3D0"/>
  <text x="2060" y="924" font-size="11" font-weight="700" fill="#059669" text-anchor="middle">18: Ô 101 đổi XANH DƯƠNG</text>


  <!-- ==================== PHASE 3: CHECK-IN & NHẬN PHÒNG ==================== -->
  <g transform="translate(30, 990)">
    <rect x="0" y="0" width="2190" height="32" rx="4" fill="#FFFBEB" stroke="#FDE68A"/>
    <text x="20" y="21" font-size="13" font-weight="800" fill="#92400E">
      GIAI ĐOẠN 3: LÀM THỦ TỤC NHẬN PHÒNG (CHECK-IN) &amp; CHUYỂN PHÒNG SANG ĐANG Ở (OCCUPIED)
    </text>
  </g>

  <!-- Step 19: Customer arrives at desk -->
  <line x1="100" y1="1055" x2="2140" y2="1055" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="940" y="1040" width="310" height="22" rx="4" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1095" y="1056" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">19: Khách đến quầy lễ tân, xuất trình CCCD nhận phòng</text>

  <!-- Step 20: Receptionist clicks Check-in -->
  <line x1="2140" y1="1090" x2="1980" y2="1090" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="2005" y="1075" width="120" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="2060" y="1089" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">20: Bấm Check-in 101</text>
  <rect x="1975" y="1090" width="10" height="260" fill="url(#actGrad)" stroke="#2563EB"/>

  <!-- Step 21: Staff App calls PATCH /checkin -->
  <line x1="1975" y1="1120" x2="1135" y2="1120" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="1450" y="1105" width="200" height="20" rx="3" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1550" y="1119" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">21: PATCH /bookings/BK-101/checkin</text>
  <rect x="1125" y="1120" width="10" height="230" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Step 22: Update DB with actualCheckIn -->
  <line x1="1135" y1="1150" x2="1360" y2="1150" stroke="#1E293B" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="1150" y="1135" width="200" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1250" y="1149" font-size="11" font-weight="700" fill="#1E293B" text-anchor="middle">22: actualCheckIn = now(), OCCUPIED</text>
  <rect x="1355" y="1150" width="10" height="45" fill="url(#actGrad)" stroke="#D97706"/>

  <line x1="1355" y1="1185" x2="1135" y2="1185" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4,4" marker-end="url(#replyArrow)"/>
  <rect x="1175" y="1170" width="150" height="20" rx="3" fill="#FFFFFF" stroke="#CBD5E1"/>
  <text x="1250" y="1184" font-size="11" fill="#475569" text-anchor="middle">23: Transaction committed</text>

  <!-- Step 24: Emit event bus -->
  <line x1="1135" y1="1215" x2="1580" y2="1215" stroke="#D97706" stroke-width="2.5" marker-end="url(#asyncArrow)"/>
  <rect x="1230" y="1200" width="260" height="20" rx="3" fill="#FFFFFF" stroke="#FDE68A"/>
  <text x="1360" y="1214" font-size="11" font-weight="700" fill="#D97706" text-anchor="middle">24: emitStatusChanged(room101, OCCUPIED)</text>
  <rect x="1575" y="1215" width="10" height="100" fill="url(#actGrad)" stroke="#059669"/>

  <!-- Step 25: SSE broadcast -->
  <line x1="1585" y1="1250" x2="1980" y2="1250" stroke="#DC2626" stroke-width="2.5" stroke-dasharray="6,4" marker-end="url(#asyncArrow)"/>
  <rect x="1640" y="1235" width="290" height="22" rx="4" fill="#FFFFFF" stroke="#FCA5A5"/>
  <text x="1785" y="1251" font-size="11" font-weight="800" fill="#DC2626" text-anchor="middle">25: SSE Event: room 101 status = OCCUPIED</text>

  <!-- Step 26: Room Matrix turned RED -->
  <line x1="1980" y1="1285" x2="2140" y2="1285" stroke="#DC2626" stroke-width="2" marker-end="url(#replyArrow)"/>
  <rect x="2000" y="1270" width="130" height="20" rx="3" fill="#FFFFFF" stroke="#FCA5A5"/>
  <text x="2065" y="1284" font-size="11" font-weight="700" fill="#DC2626" text-anchor="middle">26: Ô 101 đổi sang ĐỎ</text>

  <!-- Step 27: Staff gives room key to guest -->
  <line x1="2140" y1="1330" x2="100" y2="1330" stroke="#059669" stroke-width="2" marker-end="url(#syncArrow)"/>
  <rect x="910" y="1315" width="370" height="24" rx="4" fill="#FFFFFF" stroke="#86EFAC"/>
  <text x="1095" y="1332" font-size="12" font-weight="700" fill="#047857" text-anchor="middle">27: Bàn giao thẻ từ phòng 101 &amp; Hướng dẫn khách lên nhận phòng</text>
</svg>`;

  return createHtmlWrapper('Sequence Diagram - Luxe Grand Hotel', width, height, svg);
}

// Generate all 5 HTML diagrams
console.log('Writing HTML files...');
fs.writeFileSync(path.join(outDir, 'package_diagram.html'), generatePackageDiagram(), 'utf8');
fs.writeFileSync(path.join(outDir, 'component_diagram.html'), generateComponentDiagram(), 'utf8');
fs.writeFileSync(path.join(outDir, 'deployment_diagram.html'), generateDeploymentDiagram(), 'utf8');
fs.writeFileSync(path.join(outDir, 'class_diagram.html'), generateClassDiagram(), 'utf8');
fs.writeFileSync(path.join(outDir, 'sequence_diagram.html'), generateSequenceDiagram(), 'utf8');
console.log('All 5 HTML diagrams written successfully!');

// Render all 5 to PNG using Chrome headless
console.log('Rendering 5 PNG images via Chrome Headless...');
const chromePath = 'C:\\\\Program Files\\\\Google\\\\Chrome\\\\Application\\\\chrome.exe';

const diagrams = [
  { name: 'package_diagram', width: 2200, height: 1400 },
  { name: 'component_diagram', width: 2200, height: 1450 },
  { name: 'deployment_diagram', width: 2200, height: 1450 },
  { name: 'class_diagram', width: 2250, height: 1550 },
  { name: 'sequence_diagram', width: 2250, height: 1650 },
];

for (const d of diagrams) {
  const htmlPath = path.join(outDir, `${d.name}.html`);
  const pngPath = path.join(outDir, `${d.name}.png`);
  const fileUrl = `file:///${htmlPath.replace(/\\/g, '/')}`;

  console.log(`Rendering ${d.name}.png (${d.width}x${d.height})...`);
  const cmd = `"${chromePath}" --headless=new --disable-gpu --force-device-scale-factor=2 --screenshot="${pngPath}" --window-size=${d.width},${d.height} "${fileUrl}"`;
  
  try {
    execSync(cmd, { stdio: 'inherit' });
    console.log(`✓ ${d.name}.png rendered successfully`);
  } catch (err) {
    console.error(`Error rendering ${d.name}:`, err.message);
  }
}

console.log('--- ALL DIAGRAMS GENERATION COMPLETED ---');
