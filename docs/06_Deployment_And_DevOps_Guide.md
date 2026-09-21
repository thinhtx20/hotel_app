# TÀI LIỆU HƯỚNG DẪN CÀI ĐẶT, CẤU HÌNH VÀ TRIỂN KHAI HỆ THỐNG (DEPLOYMENT & DEVOPS MANUAL)
## DỰ ÁN: HỆ THỐNG QUẢN LÝ KHÁCH SẠN TOÀN DIỆN LUXE GRAND HOTEL

---

## 1. YÊU CẦU TIÊN QUYẾT HỆ THỐNG (SYSTEM PREREQUISITES)

### 1.1. Môi trường phát triển & Phần mềm cần cài đặt
- **Node.js:** Phiên bản `v20.x LTS` hoặc `v22.x` (kèm npm v10+).
- **Flutter SDK:** Phiên bản `3.19.x` đến `3.24.x` (Dart SDK `^3.3.0` hoặc `^3.12.2`).
- **Cơ sở dữ liệu:** PostgreSQL 15+ hoặc 16+.
- **Bộ nhớ đệm:** Redis server 7.x+.
- **Máy chủ tìm kiếm:** Elasticsearch 8.x+ (tùy chọn trong môi trường production).
- **Môi trường di động:**
  + Android Studio với Android SDK Command-line Tools, Android SDK Build-Tools 34, JDK 17.
  + Xcode 15+ và CocoaPods (nếu build trên macOS cho thiết bị iOS).
- **Docker & Docker Compose:** Hỗ trợ ảo hóa container trên máy chủ Linux/Windows.

---

## 2. HƯỚNG DẪN CÀI ĐẶT & VẬN HÀNH BACKEND (NESTJS)

### 2.1. Cấu hình biến môi trường (`.env`)
Tại thư mục gốc của Backend (`Hotel-Management/`), tạo tệp tin `.env` với đầy đủ các tham số bảo mật sau:

```env
# ==========================================
# 1. CẤU HÌNH SERVER & CỔNG LẮNG NGHE
# ==========================================
NODE_ENV=production
PORT=3000
API_PREFIX=/api/v1

# ==========================================
# 2. CƠ SỞ DỮ LIỆU POSTGRESQL & PRISMA
# ==========================================
DATABASE_URL="postgresql://postgres:YourSecurePassword123@localhost:5432/hotel_management_db?schema=public&sslmode=prefer"

# ==========================================
# 3. BẢO MẬT XÁC THỰC JSON WEB TOKEN (JWT)
# ==========================================
JWT_SECRET="LuxeGrandHotel_Secret_Key_Super_Secure_2026!#%"
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET="LuxeGrandHotel_Refresh_Secret_Key_2026!#%"
JWT_REFRESH_EXPIRES_IN=30d

# ==========================================
# 4. BỘ NHỚ ĐỆM REDIS CACHE
# ==========================================
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_TTL=600

# ==========================================
# 5. MÁY CHỦ TÌM KIẾM ELASTICSEARCH
# ==========================================
ELASTICSEARCH_NODE="http://localhost:9200"
ELASTICSEARCH_USERNAME=elastic
ELASTICSEARCH_PASSWORD=YourElasticPassword123

# ==========================================
# 6. DỊCH VỤ EMAIL NODEMAILER (GỬI OTP)
# ==========================================
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_SECURE=false
MAIL_USER=luxegrandhotel.official@gmail.com
MAIL_PASSWORD=your_app_specific_password_here
MAIL_FROM="Luxe Grand Hotel <no-reply@luxegrand.com>"

# ==========================================
# 7. LƯU TRỮ HÌNH ẢNH ĐÁM MÂY CLOUDINARY
# ==========================================
CLOUDINARY_CLOUD_NAME=luxegrand
CLOUDINARY_API_KEY=123456789012345
CLOUDINARY_API_SECRET=abcdefghijklmnopqrstuvwxyz12345

# ==========================================
# 8. THÔNG BÁO ĐẨY FIREBASE ADMIN (FCM)
# ==========================================
FIREBASE_PROJECT_ID=luxe-grand-hotel
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@luxe-grand-hotel.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"
```

---

### 2.2. Các bước cài đặt và khởi chạy Backend cục bộ

```bash
# 1. Di chuyển vào thư mục backend
cd Hotel-Management

# 2. Cài đặt toàn bộ thư viện phụ thuộc
npm install

# 3. Tạo mã Prisma Client từ schema
npx prisma generate

# 4. Đồng bộ cấu trúc bảng vào cơ sở dữ liệu PostgreSQL
npx prisma db push

# 5. Nạp dữ liệu mẫu ban đầu (Hạng phòng, Phòng, Tài khoản Admin, Lễ tân)
npx prisma db seed

# 6. Khởi chạy máy chủ ở chế độ phát triển (Hot-reload)
npm run start:dev
```
Máy chủ sẽ khởi động thành công tại: `http://localhost:3000/api/v1`.

---

## 3. TRIỂN KHAI BẰNG DOCKER & DOCKER COMPOSE

Để triển khai toàn bộ hệ thống (NestJS + PostgreSQL + Redis) một cách tự động, sử dụng tệp tin `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # 1. Cơ sở dữ liệu PostgreSQL
  postgres-db:
    image: postgres:16-alpine
    container_name: hotel_postgres
    restart: always
    environment:
      POSTGRES_USER: hotel_admin
      POSTGRES_PASSWORD: HotelPassword2026@
      POSTGRES_DB: hotel_management_db
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  # 2. Bộ đệm Redis
  redis-cache:
    image: redis:7-alpine
    container_name: hotel_redis
    restart: always
    ports:
      - "6379:6379"
    volumes:
      - redisdata:/data

  # 3. Backend API Application (NestJS)
  backend-api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: hotel_backend_api
    restart: always
    depends_on:
      - postgres-db
      - redis-cache
    environment:
      - DATABASE_URL=postgresql://hotel_admin:HotelPassword2026@postgres-db:5432/hotel_management_db?schema=public
      - REDIS_HOST=redis-cache
      - REDIS_PORT=6379
      - PORT=3000
    ports:
      - "3000:3000"

volumes:
  pgdata:
  redisdata:
```

### Lệnh khởi chạy Docker:
```bash
# Khởi động toàn bộ container chạy nền
docker compose up -d --build

# Xem log hoạt động của Backend
docker logs -f hotel_backend_api

# Dừng hệ thống khi cần bảo trì
docker compose down
```

---

## 4. HƯỚNG DẪN TRIỂN KHAI LÊN ĐÁM MÂY (RENDER CLOUD & SUPABASE)

Hệ thống hiện tại đang được triển khai thực tế trên **Render Cloud**:
- **Cơ sở dữ liệu:** PostgreSQL lưu trữ trên Supabase / Render Managed Postgres.
- **Web Service:** Render Node.js Native Environment.
- **Cấu hình trên Render Dashboard:**
  + **Environment:** `Node`
  + **Build Command:** `npm install && npx prisma generate && npm run build`
  + **Start Command:** `npm run start:prod`
  + **Auto Deploy:** Bật tính năng kích hoạt triển khai tự động mỗi khi có commit mới trên nhánh `main` của GitHub.

---

## 5. HƯỚNG DẪN CÀI ĐẶT & BUILD ỨNG DỤNG DI ĐỘNG (FLUTTER CLIENT)

### 5.1. Cấu hình tệp tin kết nối API (`api_constants.dart`)
Tại thư mục `hotel_app/lib/core/constants/api_constants.dart`, kiểm tra đường dẫn Base URL:
```dart
class ApiConstants {
  // Đường dẫn Production Render Cloud
  static const String baseUrl = 'https://hotel-management-plsp.onrender.com/api/v1';

  // Đường dẫn chạy máy ảo Android Emulator
  // static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // Đường dẫn chạy thiết bị thật cùng mạng Wifi
  // static const String baseUrl = 'http://192.168.1.15:3000/api/v1';
}
```

---

### 5.2. Cài đặt thư viện và chạy ứng dụng

```bash
# 1. Di chuyển vào thư mục ứng dụng Flutter
cd hotel_app

# 2. Tải toàn bộ packages dependencies
flutter pub get

# 3. Kiểm tra tính tương thích của thiết bị
flutter doctor -v

# 4. Chạy ứng dụng trên máy ảo hoặc thiết bị cắm dây
flutter run
```

---

### 5.3. Quy trình Đóng gói phát hành (Build Release)

#### 1. Đóng gói cho nền tảng Android (APK & AppBundle):
```bash
# Tạo file APK cài đặt độc lập (Sử dụng để cài trực tiếp trên máy chấm hội đồng)
flutter build apk --release

# Tệp tin APK sinh ra tại:
# build/app/outputs/flutter-apk/app-release.apk

# Tạo gói phát hành Google Play Store (AAB)
flutter build appbundle --release
```

#### 2. Đóng gói cho nền tảng iOS (Chạy trên macOS):
```bash
# Di chuyển vào thư mục ios và cài pods
cd ios && pod install && cd ..

# Đóng gói bản quyền IPA
flutter build ipa --release
```

---

## 6. QUY TRÌNH SAO LƯU & KHÔI PHỤC DỮ LIỆU (BACKUP & DISASTER RECOVERY)

### 6.1. Sao lưu Cơ sở dữ liệu định kỳ (Database Backup)
Chạy lệnh sau trên máy chủ vào 00:00 hàng ngày để xuất tệp tin SQL nén:
```bash
pg_dump -U hotel_admin -h localhost -d hotel_management_db | gzip > /backups/hotel_db_$(date +\%Y\%m\%d).sql.gz
```

### 6.2. Khôi phục dữ liệu khi gặp sự cố (Restore)
```bash
gunzip < /backups/hotel_db_20260921.sql.gz | psql -U hotel_admin -h localhost -d hotel_management_db
```

---

## 7. QUY TRÌNH KIỂM TRA SỨC KHỎE HỆ THỐNG (HEALTH CHECK & MONITORING)
- **Endpoint kiểm tra sống còn:** `GET /api/v1/health`
- **Kết quả trả về chuẩn:**
```json
{
  "status": "ok",
  "database": "connected",
  "redis": "connected",
  "uptime": 86400,
  "timestamp": "2026-09-21T12:00:00.000Z"
}
```
Nếu bất kỳ thành phần nào mất kết nối, hệ thống sẽ trả về HTTP 503 Service Unavailable để các công cụ cảnh báo (UptimeRobot / Sentry) thông báo cho đội ngũ kỹ thuật.
