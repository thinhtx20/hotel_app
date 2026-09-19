<!-- ticket99: sao từ Khuyenmai99/.claude/commands/system-discovery.md (bản 26/06/2026) -->

> ⚠️ **Thứ tự ưu tiên khi lệch nhau:** `CLAUDE.md` → `docs/conventions.md`
> (27/08/2026) → skill này (26/06/2026). Skill này cũ hơn 2 tháng, còn giữ vài
> chốt đã bị thay:
>
> | Trong skill này | Chốt hiện hành (`docs/conventions.md`) |
> |---|---|
> | folder `edit/` | folder **`form/`** |
> | `{entity}_list_bloc.dart` / `{entity}_list_page.dart` | **`bloc.dart`** + **`page.dart`** (bắt buộc, router auto-gen dựa vào tên `page.dart`) |
> | `RestDataSource()` | `ApiService.X.apiPath(AppApi.X.path)` — đọc `lib/api/app_api.dart` |
> | `AppColors` / `AppTextStyles` | **`Palette.*`** (`lib/utils/palette.dart`) |
> | `FieldPassword` / `FieldDropdown` | **không tồn tại** trong AppCore đang pin → `FieldText(obscureText: true)` / `FieldSelect.dropdown` |
>
> Phần quy trình (hỏi gì, sinh file theo thứ tự nào, verify gì) vẫn dùng nguyên.

# System Discovery — Khảo sát kiến trúc & Pipeline tạo Feature

## Hai chế độ hoạt động

| Lệnh | Hành động |
|------|-----------|
| `/system-discovery` | Chỉ sinh **System Snapshot** — khảo sát toàn bộ codebase |
| `/system-discovery {tên tính năng}` | **Full Pipeline** — Snapshot → Intake → BA → Architecture → Code |

---

## Tài liệu tham chiếu (đã nhúng — KHÔNG cần đọc lại file)

### Workspace Structure

```
mappa_core/
             # App chính (Flutter)
  packages/
    core_data/          # Interface trừu tượng (DataSource, DataResult, QuerySpec) — thuần Dart
    core_rest/          # Adapter REST (Dio) cho core_data
    core_supabase/      # Adapter Supabase cho core_data
    shared_auth/        # Auth module (OAuth 2.0, token refresh, AuthSessionBloc)
    shared_core/        # Umbrella re-export — 10 sub-packages:
                        #   shared_config, shared_dio, shared_foundation,
                        #   shared_navigation, shared_state, shared_storage,
                        #   shared_utils, shared_widgets, translations
    shared_monitoring/  # Firebase Analytics, Crashlytics, FCM, local notifications
    shared_charts/      # Chart widgets (fl_chart, syncfusion)
  third_party/          # Vendored 3rd-party libs (customized forks)
```

### Architecture Pattern

```
DataSource (interface, core_data)
  -> Adapter (core_rest / core_supabase)
    -> BLoC/Cubit (state management — inject DataSource trực tiếp)
      -> UI (Widget)
```

> **KHÔNG dùng Clean Architecture** — không có domain/usecase/repository layer riêng.

### Bootstrap

`main.dart` → `bootstrap()` trong `app_config.dart`:
- `asyncCallbacks` — splash + FCM/Crashlytics/Analytics init
- `initializedCallbacks` — `SupabaseManager.initialize` + `BootstrapBloc` + deep-link setup

### Session Model

- **Account** — global, Hive-persisted. Source of truth duy nhất.
- **Logout**: `AuthSetup.instance.authSessionBloc.add(const LoggedOut())` — không gọi `auth.signOut()` trực tiếp.

### Routing (Auto-Gen Router)

GoRouter, auto-generated bởi `dart run tool/gen_router.dart`:
- Scan `lib/pages/` tìm file `page.dart`, convert folder path → route:
  ```
  lib/pages/market_surveillance/article/list/page.dart
    → Class: MarketSurveillanceArticleListPage
    → Path:  /MarketSurveillance/Article/List
    → Const: RouterConstants.marketSurveillanceArticleList
  ```
- `routes.dart` + `router_constants.dart` — auto-generated, **KHÔNG sửa tay**
- Navigation role-driven: `getRole()` → `UserRole.{manager, shop, consumer, leader}`
- **Folder `widgets/` bị skip** — không tạo route

**Page conventions:**
```dart
// Không params
class SomePage extends StatelessWidget {
  const SomePage({super.key});
}

// Với Map params (phổ biến nhất)
class SomeDetailPage extends StatelessWidget {
  final Map params;
  const SomeDetailPage(this.params, {super.key});
}
```

**Navigation:**
```dart
appNavigator.pushNamed(RouterConstants.someDetail, arguments: item.toJson());
appNavigator.go(RouterConstants.someList);
```

### Base BLoC Classes & Scaffolds

```
BaseBloc<Event, State>
    ├── SystemListBloc<SystemListState<T>, T>
    │       └── AppListBloc<T extends JsonModel<T>>       ← Dùng class này
    ├── SystemDetailBloc<SystemDetailState>              ← Dùng class này (kế thừa trực tiếp)
    └── SystemFormBloc<SystemFormState>
            └── AppFormBloc<T extends JsonModel<T>>       ← Hoặc extend SystemFormBloc trực tiếp
```

| Class | Dùng cho |
|-------|---------|
| `AppListBloc<T>` | Danh sách + pagination + search + filter |
| `SystemDetailBloc<S>` | Chi tiết 1 item + refresh (kế thừa trực tiếp) |
| `AppFormBloc<T>` | Form create/edit + validation |
| `SystemListScaffold` | Scaffold wrapper cho list page |
| `SystemDetailScaffold` | Scaffold wrapper cho detail page |
| `SystemFormScaffold` | Scaffold wrapper cho form page |

### Cấu trúc thư mục Feature chuẩn

```
lib/pages/{feature}/
├── list/
│   ├── bloc.dart          # extends AppListBloc<T>
│   ├── page.dart          # BlocProvider + SystemListScaffold
│   └── widgets/
│       └── item.dart      # StatelessWidget cho 1 item
├── detail/
│   ├── bloc.dart          # extends SystemDetailBloc
│   └── page.dart          # BlocProvider + SystemDetailScaffold
└── form/
    ├── bloc.dart          # extends SystemFormBloc
    └── page.dart          # BlocProvider + SystemFormScaffold
```

> Dùng `form/` (KHÔNG phải `edit/`). File page bắt buộc tên `page.dart`.

### DataSource — REST (chuẩn duy nhất cho feature mới)

Mọi feature mới dùng `RestDataSource()` qua `ApiClient` + `ApiService` enum:
- Không tự tạo `Dio` instance
- Không dùng `SupabaseDataSource` cho feature mới (Supabase chỉ còn trong code legacy)

### Import Pattern & Globals

- `import '../../import.dart'` — barrel export (l10n + assets + globals)
- `lib/global.dart` — constants, enums, `getRole()`
- `context.l10n` / `L10n.of` — localization
- `AppColors`, `AppTextStyles`, `AppTheme` — design tokens
- `AppSnackbar` / `showMessage()` — thông báo lỗi/thành công
- `AppDialogs.delete` / `AppDialogs.showConfirmDialog` — dialogs chuẩn
- `debugPrint()` / `FirebaseCrashlytics` — logging (không dùng `print()`)

### Localization

Viết trong `lib/l10n/src/<name>_<locale>.arb` → `dart run lib/tool/merge.dart` → sinh `app_localizations.dart`.  
**Không sửa tay** `lib/l10n/app_*.arb`.

### Coding Rules A–F (tóm tắt)

| Rule | Nội dung |
|------|---------|
| A1 | Widget không gọi API trực tiếp |
| A2 | Không gọi API trong `build()` |
| A3 | Business logic đặt trong BLoC |
| A4 | DataSource chịu trách nhiệm gọi API |
| A6 | Không tự tạo `Dio` — dùng `ApiClient` với `ApiService` enum |
| B1 | Không navigate trong BLoC — emit state hoặc callback |
| B2 | State cần đủ: loading / success / error / empty |
| B3 | Kế thừa `AppListBloc`, `AppFormBloc`; detail kế thừa `SystemDetailBloc` trực tiếp |
| C1 | Controller / FocusNode / StreamSubscription phải `dispose()` |
| C2 | Không dùng `BuildContext` sau `await` chưa check `mounted` |
| C5 | Search/filter phải có debounce |
| C6 | Submit form phải chống double-tap |
| D1–3 | Không hardcode màu/text/spacing |
| D4 | Không hardcode chuỗi — dùng l10n |
| E1 | Không dùng `print()` |
| E2 | Không log token/password/OTP |

### Platform Notes

- Firebase skipped trên Windows/Linux (`hasSupport == false`)
- Secrets (Supabase keys) committed in source — không expose ra log
- **Không sửa tay**: `lib/gen/`, `lib/l10n/app_localizations.dart`, `lib/routes.dart`, `lib/router_constants.dart`

### API Services

| Service | Swagger |
|---------|---------|
| identity | https://auth.api.suyxet.com/docs |
| geo | https://geo.api.suyxet.com/docs |
| iam | https://iam.api.suyxet.com/docs |
| catalog | https://catalog.api.suyxet.com/docs |
| org | https://org.api.suyxet.com/docs |
| merchant | https://merchant.api.suyxet.com/docs |
| lead | https://lead.api.suyxet.com/docs |
| complaint | https://complaint.api.suyxet.com/docs |
| inspection | https://inspection.api.suyxet.com/docs |
| file | https://file.api.suyxet.com/docs |
| map-poi | https://map.api.suyxet.com/docs |
| review | https://review.api.suyxet.com/docs |
| coupon | https://coupon.api.suyxet.com/docs |
| product-scan | https://scan.api.suyxet.com/docs |
| notification | https://notify.api.suyxet.com/docs |
| reporting | https://reporting.api.suyxet.com/docs |
| system-admin | https://system.api.suyxet.com/docs |
| consumer | https://consumer.api.suyxet.com/docs |
| bff (gateway) | https://bff.api.suyxet.com/docs |

---

## Chế độ 1: Snapshot (không có args)

Chạy khi user gọi `/system-discovery` không kèm tên tính năng.

### Bước 1: Feature Inventory

List tất cả feature folders trong `lib/pages/` (1 level). Với **mỗi folder**, chạy 5 kiểm tra:

| Cột | Cách kiểm tra |
|-----|--------------|
| **List** | Subfolder `list/` hoặc file khớp `*list*.dart` |
| **Detail** | Subfolder `detail/` hoặc file khớp `*detail*.dart` |
| **Form/Edit** | Subfolder `form/` hoặc `edit/` hoặc file khớp `*form*.dart`, `*edit*.dart` |
| **DataSource** | Grep: `AppListBloc\|SystemDetailBloc\|AppFormBloc` → `REST`; `SupabaseListBloc\|SupabaseDetailBloc\|SupabaseFormBloc` → `Supabase (legacy)`; không thấy → `—` |
| **Route** | Feature name xuất hiện trong path strings của `lib/routes.dart` → ✅/❌ |

### Bước 2: Reusable Assets

1. Glob `packages/shared_core/shared_widgets/lib/src/form/**/*.dart` → nhóm theo category
2. Glob `packages/shared_core/shared_state/lib/src/widgets/**/*.dart`
3. Glob `packages/shared_core/shared_state/lib/src/extensions/*.dart`

### Bước 3: Pattern Deviation

Grep trong `lib/pages/`:

| Rule | Pattern | Vi phạm |
|------|---------|---------|
| A1 | `\.repository\.\|dataSource\.` trong `*_page.dart\|*_widget.dart` | Widget gọi API |
| B1 | `context\.go\|GoRouter\.of\|context\.push` trong `*_bloc.dart\|*_cubit.dart` | Navigate trong BLoC |
| E1 | `print(` trong `.dart` | Dùng `print()` |

### Bước 4: Output System Snapshot

```markdown
# System Snapshot — {ngày giờ}

## Kiến trúc
- Layer: UI → BLoC → DataSource → Backend
- Base BLoC: `SystemListBloc`, `SystemDetailBloc`, `SystemFormBloc`
- App wrappers: `AppListBloc<T>`, `AppFormBloc` (detail dùng `SystemDetailBloc` trực tiếp)
- Scaffold widgets: `SystemListScaffold`, `SystemDetailScaffold`, `SystemFormScaffold`
- Form fields: **Fields V2** (`package:core_widgets/fields.dart` — `Field*` widget) cho feature mới; `form.dart` (`Form*`) legacy
- Import pattern: `import '../../import.dart'`
- Router: GoRouter — ~100+ flat named routes, role-driven shell

## Feature Inventory   ← từ Bước 1
| Feature | List | Detail | Form/Edit | DataSource | Route |
|---------|------|--------|-----------|------------|-------|

## Reusable Assets   ← từ Bước 2
[nhóm theo category]

## Pattern Deviations   ← từ Bước 3
[chỉ liệt kê vi phạm tìm thấy]
```

---

## Chế độ 2: Full Pipeline (có feature name trong args)

Chạy khi user gọi `/system-discovery {tên tính năng}`.

### Phase 0 — Quick Discovery

Chạy **Bước 1** (Feature Inventory scan) để biết feature nào đã có, tránh trùng lặp.  
Bỏ qua Bước 2 và 3 để tiết kiệm thời gian.

Hiển thị nhanh Feature Inventory cho user tham khảo.

---

### Phase 1 — Intake (hỏi 1 lần, user trả lời bằng gạch đầu dòng)

Hỏi **tất cả cùng một lúc**, user trả lời trong 1 message duy nhất:

---

Để bắt đầu tính năng **"{args}"**, hãy trả lời 3 câu hỏi sau (mỗi câu 1 gạch đầu dòng):

**1. Mô tả ngắn:** Tính năng này làm gì? (1–2 câu)

**2. Backend:** Dữ liệu từ REST API nào? Service nào? Endpoint cụ thể?
_(Tham khảo bảng API Services ở trên nếu cần)_

**3. Yêu cầu đặc biệt:** Có điểm nào đặc biệt không?
_(upload file/ảnh, realtime, phân quyền phức tạp, multi-step form, map, v.v. — ghi "không" nếu không có)_

---

Đợi user trả lời đủ 3 ý rồi mới chuyển Phase 2.

---

### Phase 2 — BA Analysis (role-ba)

Dựa vào `{args}` + câu trả lời I1–I3, hỏi user **tuần tự** Q1–Q7:

**Q1. Entity/Resource**
> Tên entity là gì? (VD: `article`, `inspection`, `license`)  
> Đây sẽ là tên class, file, và endpoint resource.

**Q2. Màn hình cần thiết**
> Cần những màn hình nào?
> - [ ] Danh sách (List)
> - [ ] Chi tiết (Detail)
> - [ ] Form tạo mới (Create)
> - [ ] Form chỉnh sửa (Edit)
> - [ ] Create + Edit dùng chung 1 form

**Q3. Data Schema**
> Các field chính:
> - Tên field, kiểu dữ liệu, required?
> - Field nào hiển thị trên list item?
> - Field nào hiển thị trên detail?
> - Field nào cần nhập trong form?

**Q4. Tính năng List**
> - Có search không? Search theo field nào?
> - Có filter không? Filter theo field nào?
> - Có multi-select + batch action không?
> - Bao nhiêu items/page? (mặc định 20)
> - Tap item → đi đâu? (detail page / bottom sheet)

**Q5. Tính năng Detail**
> - Layout: đơn giản (scroll) hay có tabs?
> - Có nút Edit không?
> - Có nút Delete không?
> - Có action khác? (toggle status, archive, approve...)

**Q6. Tính năng Form**
> - Validation rules cho từng field?
> - Field đặc biệt? (date picker, image picker, dropdown, rich text...)
> - Cảnh báo thoát khi có thay đổi chưa lưu?
> - Sau submit thành công: làm gì? (pop + refresh / navigate đến detail)

**Q7. Vai trò & Quyền**
> - Ai được xem? (consumer / shop / manager / leader)
> - Ai được tạo/sửa/xóa?
> - Feature nằm trong shell tab nào? (Home / MerchantHome / MarketSurveillance / Leader)

Sau khi có đủ Q1–Q7, sinh **Feature Spec**:

```markdown
# Feature Spec: {Feature Name}

## 1. Tổng quan
- Entity: {name}
- Resource: {endpoint} — Service: {service name + Swagger URL}
- DataSource: REST
- Screens: list, detail, form
- Shell tab: {tab name}
- Roles: view={...}, edit={...}

## 2. Data Schema
| Field | Type | Required | List | Detail | Form |
|-------|------|----------|------|--------|------|

## 3. List Screen
- Items/page: {N}
- Search: {field}
- Filters: {fields}
- Item display: {name + subtitle + trailing}
- Tap action: → Detail

## 4. Detail Screen
- Layout: {simple / tabs}
- Actions: {edit, delete, ...}

## 5. Form Screen
- Mode: create + edit (shared)
- Fields:
  | Field | Widget | Rules |
  |-------|--------|-------|
- After success: pop(true) + refresh caller

## 6. Navigation Flow
List ──tap──▶ Detail ──edit──▶ Form(edit) ──success──▶ pop → refresh Detail
List ──FAB──▶ Form(create) ──success──▶ pop → refresh List
Detail ──delete──▶ AppDialogs.delete → pop to List

## 7. File Plan
pages/{feature}/
├── list/
│   ├── bloc.dart
│   ├── page.dart
│   └── widgets/item.dart
├── detail/
│   ├── bloc.dart
│   └── page.dart
└── form/
    ├── bloc.dart
    └── page.dart
```

**Hiển thị Feature Spec cho user xác nhận trước khi tiếp tục.**

---

### Phase 3 — Architecture Design (flutter-architecture)

Từ Feature Spec đã xác nhận, xác định:

1. **BLoC constructors** — api name, filters, rules, options
2. **Page layouts** — appBar, body widget, FAB, bottom bar
3. **Widget decomposition** — list item fields, detail sections, form fields + widgets
4. **DataSource** — `RestDataSource()` qua `ApiClient` + `ApiService` enum
5. **Model class** — fields, `JsonModel<T>` implementation, `.empty()` constructor

Hiển thị **File Plan chi tiết** (tên class, constructor params, key widgets) cho user xác nhận.

---

### Phase 4 — Code Generation (code-agent)

Tạo từng file theo thứ tự. Với **mỗi file**, đọc file mẫu tương ứng trong `lib/pages/complain/` hoặc `lib/pages/bookmark/` rồi thay thế entity name, fields, rules:

```
Thứ tự tạo:
1. list/bloc.dart        ← mẫu: complain/list/bloc.dart
2. list/page.dart        ← mẫu: complain/list/page.dart
3. list/widgets/item.dart
4. detail/bloc.dart      ← mẫu: complain/detail/bloc.dart
5. detail/page.dart      ← mẫu: complain/detail/page.dart
6. form/bloc.dart        ← mẫu: complain/edit/bloc.dart
7. form/page.dart        ← mẫu: complain/edit/page.dart
```

**Conventions bắt buộc khi sinh code:**
- Import: `import '../../import.dart'` (điều chỉnh depth theo vị trí file)
- DataSource: `RestDataSource()` — không dùng SupabaseDataSource
- Dialog: `AppDialogs.delete` / `AppDialogs.showConfirmDialog`
- Navigation: `appNavigator.pushNamed(...)` / `appNavigator.pop()`
- Tên file page: `page.dart`
- Folder form: `form/`
- Không hardcode màu/text/spacing — dùng design tokens
- Không hardcode chuỗi — dùng `context.l10n`

---

### Phase 5 — Verification & Summary

Sau khi tạo xong tất cả file:

1. Kiểm tra tất cả file tồn tại (Glob)
2. Grep import paths — không có depth sai
3. Grep `showDialog(` — phải dùng `AppDialogs`
4. Grep `Navigator.pop\|Navigator.push` — phải dùng `appNavigator`
5. Grep `print(` — phải dùng `debugPrint()`

Output final:
```
✅ Created: {N} files
✅ BLoCs: list, detail, form
✅ Pages: list, detail, form
✅ Widgets: item

⚠️  TODO (bắt buộc):
    dart run tool/gen_router.dart

⚠️  TODO (nếu cần):
    - Thêm menu/tab entry trong shell_router.dart
    - Thêm l10n keys: dart run lib/tool/merge.dart
    - dart format -l 100 . && dart analyze
```

---

## Quy tắc chung

- KHÔNG đọc file CLAUDE.md — tài liệu đã nhúng đầy đủ ở trên
- KHÔNG code trước khi user xác nhận Feature Spec (Phase 2)
- KHÔNG code trước khi user xác nhận File Plan (Phase 3)
- KHÔNG dùng Clean Architecture (domain/usecase/repository)
- KHÔNG dùng `SupabaseDataSource` cho feature mới
- LUÔN tham chiếu `complain/` hoặc `bookmark/` khi sinh code
- LUÔN verify sau khi tạo xong
- Output bằng tiếng Việt
