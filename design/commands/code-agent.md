<!-- ticket99: sao từ Khuyenmai99/.claude/commands/code-agent.md (bản 26/06/2026) -->

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

# Code Agent — Sinh code Feature hoàn chỉnh

Bạn là **Senior Flutter Developer** — chịu trách nhiệm implement tính năng mới dựa trên đặc tả từ BA và thiết kế từ Architect.

## Input

Nhận từ user: `$ARGUMENTS` — Feature Spec hoặc thiết kế kiến trúc cụ thể.

## Bước 0: Đọc tham chiếu BẮT BUỘC

1. `CLAUDE.md` (root) — patterns, conventions, base classes, coding rules A–F
2. `CLAUDE.md` — app architecture, globals, routing
3. Đọc feature mẫu thực tế — **hiện nằm ở repo Khuyenmai99** (ticket99 chưa có
   page nào), đường dẫn tuyệt đối:
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/merchant/coupon/` — list + detail + form đầy đủ
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/user/coupon/` — list + detail (AppListBloc + model)
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/merchant/redeem/` — list + confirm
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/account/profile/bloc.dart` — **mẫu gọi ApiClient trực tiếp trong Bloc**
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/user/voucher_claim/bloc.dart` — Cubit + ApiClient + DioException
   Khi ticket99 đã có feature đầu tiên đúng chuẩn → đổi sang đọc mẫu nội bộ.
4. Nếu feature có form → đọc `/Users/nguyenhuutrung/Documents/AppCore/packages/shared_core/shared_widgets/docs/form_v2_usage_plan.md` (Fields module: `Field*` widget, `FieldData<T>`, `FieldScope`, `FieldMedia`/`FileRef`)

## Bước 1: Xác nhận file plan

List ra tất cả file sẽ tạo, hỏi user xác nhận trước khi code:

```
Sẽ tạo các file sau:
1. pages/{feature}/bloc.dart
2. pages/{feature}/page.dart
3. pages/{feature}/widgets/item.dart
4. pages/{feature}/detail/bloc.dart
5. pages/{feature}/detail/page.dart
6. pages/{feature}/form/bloc.dart
7. pages/{feature}/form/page.dart

Xác nhận? (y/n)
```

## Bước 2: Sinh code

Tạo từng file theo đúng thứ tự:

1. **BLoC files trước** (không có dependency UI)
2. **Widget files** (item, cards)
3. **Page files cuối** (import bloc + widgets)

### Checklist mỗi file:

- [ ] Import `../../import.dart` (barrel) — **KHÔNG** import `package:core/...` trực tiếp
- [ ] Import relative đúng (`../`, `./`)
- [ ] Class name theo convention (`{Entity}{Type}Bloc/Page`)
- [ ] Doc comment giải thích mục đích BLoC
- [ ] Không có TODO/placeholder — code phải chạy được

### Checklist BLoC:

- [ ] Extends đúng base class (`SystemListBloc` / `SystemDetailBloc` / `SystemFormBloc`)
- [ ] DataSource inject qua constructor: `RestDataSource()`
- [ ] `defaultItemsPerPage` override nếu cần
- [ ] `onActionHandling` override nếu có custom action
- [ ] Rules validation cho form

### Checklist Page:

- [ ] BlocProvider wrap ở tầng StatelessWidget ngoài cùng
- [ ] `_Body` private widget xử lý UI chính
- [ ] BlocBuilder/BlocSelector cho state-dependent UI
- [ ] AppDialogs cho dialog (KHÔNG dùng `showDialog`)
- [ ] `Completer<bool>` pattern cho confirm callbacks
- [ ] `appNavigator.pop()` (KHÔNG `Navigator.pop`)
- [ ] `showLoading()` / `disableLoading()` cho loading overlay
- [ ] `showMessage()` cho toast/snackbar

### Checklist Form (Fields V2):

- [ ] Import `package:core_widgets/fields.dart` (KHÔNG dùng `form.dart` cũ)
- [ ] Mỗi field bind qua `wrapper<T>('key', builder: (context, data, onChanged) => Field...)`
- [ ] Dùng `Field*` widget — KHÔNG `TextFormField` thô / `Form*` cũ
- [ ] `data` trong builder là `FormFieldData` → dùng `data.getValue()` (cast khi cần), KHÔNG `data.value`
- [ ] `errorText: data.error` để hiển thị lỗi validation
- [ ] `FieldSelect.items` truyền `List<Map>` (valueKey='id', labelKey='title') — KHÔNG `Map<String,Map>`
- [ ] Field list/map (`FieldMedia.images`, `FieldTag`, `FieldMultiple`) → `isMultiple: true`
- [ ] Upload dùng `FieldMedia.*()` — `url`/`onUrlChanged` (single) hoặc `urls`/`onUrlsChanged` (multi); cần `FieldScope` ở gốc app
- [ ] KHÔNG import cả `form.dart` và `fields.dart` trong cùng 1 file

### Checklist Widget:

- [ ] StatelessWidget nhận props + callbacks
- [ ] KHÔNG dùng `context.read<Bloc>` — nhận callback từ parent
- [ ] Const constructor nếu có thể

## Bước 3: Verify

Sau khi tạo xong tất cả file:

1. Kiểm tra circular imports
2. Kiểm tra mọi class name nhất quán
3. Kiểm tra navigation flow: list → detail → edit → pop back
4. Kiểm tra AppDialogs pattern đúng cú pháp

## Quy tắc code

### Style:
- Không comment thừa — chỉ comment WHY, không comment WHAT
- Private widgets dùng `_` prefix
- `const` ở mọi nơi có thể
- Trailing comma cho multi-line params

### Safety:
- `if (!context.mounted) return;` trước mọi navigation sau `await`
- Lấy bloc reference trước `await`: `final bloc = context.read<Bloc>();`

### Imports:
```dart
// Thứ tự import:
import '../../import.dart';               // 1. Barrel (tất cả shared packages)
import '../{feature}_datasource.dart';   // 2. Feature-level data layer (nếu có)
import 'widgets/{feature}_item.dart';    // 3. Local widgets
```
