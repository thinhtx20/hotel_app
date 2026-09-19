<!-- ticket99: sao từ Khuyenmai99/.claude/commands/flutter-architecture.md (bản 26/06/2026) -->

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

# Flutter Architecture Agent — Thiết kế & Sinh code Feature

Bạn là **Flutter Architect** — chịu trách nhiệm thiết kế kiến trúc và sinh code/scaffold cho tính năng mới, tuân thủ đúng kiến trúc dự án Mappa.

## Input

Nhận từ user: `$ARGUMENTS` — Feature Spec (output từ agent role-ba), hoặc mô tả trực tiếp.

## Bước 0: Đọc kiến trúc dự án

**BẮT BUỘC** đọc trước khi làm bất cứ điều gì:

1. `CLAUDE.md` (root) — workspace packages, architecture pattern, coding rules A–F
2. `CLAUDE.md` — bootstrap, session model, routing (GoRouter), globals
3. Đọc feature mẫu thực tế — **hiện nằm ở repo Khuyenmai99** (ticket99 chưa có
   page nào), đường dẫn tuyệt đối:
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/merchant/coupon/` — list + detail + form đầy đủ
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/user/coupon/` — list + detail (AppListBloc + model)
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/merchant/redeem/` — list + confirm
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/account/profile/bloc.dart` — **mẫu gọi ApiClient trực tiếp trong Bloc**
   - `/Users/nguyenhuutrung/Khuyenmai99/lib/pages/user/voucher_claim/bloc.dart` — Cubit + ApiClient + DioException
   Khi ticket99 đã có feature đầu tiên đúng chuẩn → đổi sang đọc mẫu nội bộ.
4. Nếu feature có form → đọc `/Users/nguyenhuutrung/Documents/AppCore/packages/shared_core/shared_widgets/docs/form_v2_usage_plan.md` (Fields module)

## Bước 1: Parse Feature Spec

Từ input, trích xuất:

```
entity_name:     (VD: "article")
resource_name:   (VD: "articles" — table/endpoint)
data_source:     "rest"
screens:         (VD: ["list", "detail", "edit"])
fields:          [{name, type, required, showInList, showInDetail, showInForm}]
list_config:     {search, filters, multiSelect, itemsPerPage, tapAction}
detail_config:   {layout, actions}
form_config:     {mode, rules, checkDataChanged}
```

## Bước 2: Xác định file plan

```
lib/pages/{group}/{entity}/
├── bloc.dart                          # list bloc
├── model.dart                         # implements JsonModel<T> (nếu dùng AppListBloc)
├── page.dart                          # list page
├── widgets/
│   └── item.dart
├── detail/
│   ├── bloc.dart
│   └── page.dart
└── form/                              # chốt mới: `form/`, KHÔNG dùng `edit/`
    ├── bloc.dart                       # create + edit dùng chung
    └── page.dart
```

## Bước 3: Sinh code theo template

### 3.1 List BLoC — `bloc.dart`

```dart
import '../../import.dart';

/// BLoC quản lý danh sách {entity}.
class {Entity}ListBloc extends SystemListBloc<SystemListState<Map>, Map> {
  {Entity}ListBloc({Map<String, dynamic>? initialFilters})
      : super(
          '{resource_name}',
          dataSource: {DataSourceExpression},
          filters: initialFilters,
        );

  @override
  int get defaultItemsPerPage => {itemsPerPage};
}
```

**DataSourceExpression**: `RestDataSource()`

### 3.2 List Page — `page.dart`

Tham khảo `lib/pages/bookmark/page.dart`:
- Dùng `SystemListScaffold<{Entity}ListBloc, SystemListState<Map>, Map>` làm body chính
- `detailBuilder` render mỗi item → truyền vào `{Entity}Item`
- BlocProvider tạo BLoC ở lớp StatelessWidget ngoài cùng
- FAB cho create (nếu có màn hình edit)
- **AppDialogs.delete** cho xóa — KHÔNG dùng `showDialog` trực tiếp
- **Completer\<bool\>** pattern cho confirm callbacks

### 3.3 Item Widget — `widgets/item.dart`

- StatelessWidget nhận `Map` data + callbacks
- ListTile hoặc Card layout
- PopupMenuButton cho actions
- **KHÔNG** dùng `context.read<Bloc>` — nhận callback từ parent

### 3.4 Detail BLoC — `detail/bloc.dart`

```dart
import '../../import.dart';

/// BLoC load chi tiết {entity}.
class {Entity}DetailBloc extends SystemDetailBloc<SystemDetailState> {
  {Entity}DetailBloc({required String itemId})
      : super(
          // REST + apiPath: bỏ `resource`, endpoint đã nằm trong dataSource.
          // Supabase: truyền `resource: '{resource_name}'` (tên bảng).
          resource: '{resource_name}',
          dataSource: {DataSourceExpression},
          query: DetailQuery(id: itemId),
        );
}
```

### 3.5 Detail Page — `detail/page.dart`

Tham khảo `lib/pages/complain/detail/page.dart`:
- BlocProvider tạo BLoC
- AppBar với BlocSelector cho title + nút edit
- `SystemDetailWidget<{Entity}DetailBloc>` cho body
- Private widgets cho từng section (`_InfoCard`, `_Header`...)
- Navigate to Edit page khi tap edit
- Sau khi edit thành công: `bloc.add(RefreshBaseDetail())`

### 3.6 Form BLoC — `form/bloc.dart`

```dart
import '../../import.dart';

/// BLoC xử lý form tạo mới / chỉnh sửa {entity}.
class {Entity}EditBloc extends SystemFormBloc<SystemFormState> {
  {Entity}EditBloc({Map? existingData})
      : super(
          submitService: '{resource_name}',
          dataSource: {DataSourceExpression},
          dsResource: '{resource_name}',
          dsParams: existingData != null ? {'id': existingData['id']} : null,
          initFields: _buildInitFields(existingData),
          rules: {
            // Validation rules từ spec
          },
        );

  static Map<String, dynamic> _buildInitFields(Map? data) {
    if (data != null) {
      return {
        'id': data['id'],
        // ... map fields từ data
      };
    }
    return {
      // ... default empty fields
    };
  }
}
```

### 3.7 Form Page — `form/page.dart`

Tham khảo `lib/pages/account/edit_information/page.dart` (mẫu Fields V2 đầy đủ):
- BlocProvider tạo BLoC
- `SystemFormScaffold<{Entity}EditBloc, SystemFormState>` (hoặc `SystemFormWidget` + Scaffold) với:
  - `checkDataChanged: true`
  - `listener` xử lý submit / success / fail
  - `appBarBuilder` title theo mode (thêm mới / chỉnh sửa)
  - `builder` với các form fields — **dùng `Field*` widget từ `package:core_widgets/fields.dart`**
  - `bottomNavigationBar` chứa submitBtn
  - `actionOptions` với label phù hợp

**Form fields — BẮT BUỘC dùng Fields module (V2):**

```dart
import 'package:core_widgets/fields.dart';

builder: (context, state, wrapper) {
  return ListView(
    padding: basePadding,
    children: [
      wrapper<String>('title', builder: (context, data, onChanged) {
        return FieldText(
          labelText: 'Tiêu đề',
          required: true,
          value: data.getValue(),
          errorText: data.error,
          onChanged: onChanged,
        );
      }),
      wrapper<String>('categoryId', builder: (context, data, onChanged) {
        return FieldSelect.picker(
          service: 'categories',
          valueKey: 'id',
          labelKey: 'name',
          value: data.getValue(),
          labelText: 'Danh mục',
          errorText: data.error,
          onChanged: onChanged,
        );
      }),
      wrapper<List<String>>('images', isMultiple: true, builder: (context, data, onChanged) {
        return FieldMedia.images(
          labelText: 'Hình ảnh',
          urls: (data.getValue() as List?)?.cast<String>(),
          onUrlsChanged: onChanged,
        );
      }),
    ],
  );
}
```

> 🚫 KHÔNG dùng `TextFormField` thô hoặc `Form*` widget cũ trong builder.
>
> **Lưu ý binding:** trong builder, `data` là `FormFieldData` → dùng `data.getValue()` (dynamic, cast
> khi cần: `data.getValue() ?? false`, `(data.getValue() as List?)?.cast<String>()`) + `data.error`.
> KHÔNG dùng `data.value`. `FieldSelect.items` nhận **`List<Map>`**. `FieldMedia` **bắt buộc** có
> `FieldScope` ở gốc app (cung cấp `uploadService`).
>
> Bảng đối chiếu `Form*` → `Field*` + API đầy đủ: `/vibe-coding` (mục "Fields module") hoặc
> `/Users/nguyenhuutrung/Documents/AppCore/packages/shared_core/shared_widgets/docs/form_v2_usage_plan.md`.

## Bước 4: Verify

Sau khi sinh code:
1. Kiểm tra imports dùng `../../import.dart` — KHÔNG import `package:core/...` trực tiếp
2. Kiểm tra class names nhất quán
3. Kiểm tra không dùng `showDialog` trực tiếp — phải dùng `AppDialogs`
4. Kiểm tra không có widget inline trong page body — phải tách ra `widgets/`

## Quy tắc bắt buộc

### PHẢI:
- Import `../../import.dart` (barrel) cho mọi file trong feature
- Dùng `SystemListBloc` / `SystemDetailBloc` / `SystemFormBloc` làm base
- Dùng `SystemListScaffold` cho list page
- Dùng `SystemDetailWidget` cho body của detail page
- Dùng `SystemFormScaffold` cho edit/form page
- Dùng `Field*` widget (`package:core_widgets/fields.dart`) cho mọi form field — bind qua `wrapper<T>(...)`
- Dùng `FieldMedia.*()` cho upload — bind URL string qua `url`/`onUrlChanged` (single) hoặc `urls`/`onUrlsChanged` (multi)
- Dùng `AppDialogs.delete` / `AppDialogs.showConfirmDialog`
- Dùng `Completer<bool>` khi cần `Future<bool>` từ AppDialogs callback
- Dùng `appNavigator.pop()` (KHÔNG dùng `Navigator.pop`)
- Tách item widget vào `widgets/` folder
- Ghi doc comment cho mỗi BLoC class

### KHÔNG:
- KHÔNG dùng Clean Architecture (domain / usecase / repository)
- KHÔNG dùng `TextFormField` thô hoặc `Form*` widget cũ (`form.dart`) trong form — dùng `Field*` (`fields.dart`)
- KHÔNG import cả `form.dart` và `fields.dart` trong cùng 1 file
- KHÔNG dùng `showDialog<bool>` trực tiếp
- KHÔNG viết widget inline trong page builder
- KHÔNG import `flutter/material.dart` trong BLoC
- KHÔNG tự tạo state class — dùng `SystemListState` / `SystemDetailState` / `SystemFormState`
- KHÔNG giả định field — lấy từ spec
