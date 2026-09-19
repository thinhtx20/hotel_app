<!-- ticket99: sao từ Khuyenmai99/.claude/commands/vibe-coding.md (bản 26/06/2026) -->

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

# Vibe Coding — Quy trình tạo Feature mới

Hướng dẫn end-to-end để tạo một tính năng Flutter mới trong Mappa bằng cách phối hợp các skill agent theo đúng thứ tự.

---

## Tổng quan

```
Idea  →  /role-ba  →  /flutter-architecture  →  /code-agent  →  Đăng ký route
```

Hoặc dùng `/pipeline` để chạy toàn bộ flow trong một lệnh.

---

## Cách nhanh: /pipeline

```
/pipeline <mô tả tính năng>
```

**Ví dụ:**
```
/pipeline Quản lý khiếu nại cho người tiêu dùng — list + detail + form tạo mới
```

Pipeline tự động chạy tất cả phase bên dưới theo thứ tự. Dùng khi bạn muốn đi thẳng từ ý tưởng ra code.

---

## Cách chi tiết: Từng bước

### Bước 1 — Khảo sát dự án (tùy chọn)

```
/system-discovery
```

Khi nào dùng: Lần đầu làm việc với codebase, hoặc cần biết feature nào đã có để tránh trùng lặp.

Output: System Snapshot — danh sách feature hiện có, base class đang dùng, DataSource pattern.

---

### Bước 2 — Phân tích yêu cầu

```
/role-ba <mô tả tính năng>
```

**Ví dụ:**
```
/role-ba Tính năng quản lý phiếu kiểm tra hàng hóa
```

Agent sẽ hỏi tuần tự 7 câu hỏi:

| # | Câu hỏi | Mục đích |
|---|---------|---------|
| Q1 | Tên entity? | Đặt tên class, file, table |
| Q2 | Màn hình cần thiết? | Xác định scope (list/detail/edit) |
| Q3 | Dữ liệu từ đâu? | Chọn DataSource + schema |
| Q4 | List config? | Search, filter, pagination |
| Q5 | Detail config? | Layout, actions |
| Q6 | Form config? | Validation rules, special fields |
| Q7 | Phân quyền? | Role-based access |

**Output:** Feature Spec (Markdown) — review và xác nhận trước khi tiếp tục.

---

### Bước 3 — Thiết kế kiến trúc

```
/flutter-architecture
```

Paste Feature Spec từ bước 2 vào (hoặc để agent đọc từ context).

Agent sẽ:
- Map spec → file structure (list / detail / edit)
- Xác định BLoC constructors (service, dataSource, filters, rules)
- Thiết kế page layouts (SystemListScaffold / SystemDetailWidget / SystemFormScaffold)
- Liệt kê file plan đầy đủ

**Output:** File plan + code templates — xác nhận trước khi sinh code.

---

### Bước 4 — Sinh code

```
/code-agent
```

Agent tham chiếu feature mẫu thực tế (`complain/`, `bookmark/`) rồi sinh từng file:

```
Thứ tự sinh:
1. {entity}_list_bloc.dart
2. {entity}_list_page.dart
3. widgets/{entity}_item.dart
4. {entity}_detail_bloc.dart
5. {entity}_detail_page.dart
6. {entity}_edit_bloc.dart
7. {entity}_edit_page.dart
```

**Conventions bắt buộc:**
- Import: `import '../../import.dart'` (barrel)
- DataSource: `RestDataSource()`
- Dialog: `AppDialogs.delete` / `AppDialogs.showConfirmDialog`
- Navigation: `appNavigator.pop()` — không dùng `Navigator.pop`
- Folder form: `form/` (xem `docs/conventions.md` §4 — chốt mới, khác bản skill gốc)

---

### Bước 5 — Đăng ký route (Auto Gen Router)

Project dùng **auto-gen router** — KHÔNG cần tự viết route hay constant. Chỉ cần đặt file đúng convention rồi chạy generator.

#### Cách hoạt động

Generator scan `lib/pages/` tìm file `page.dart`, convert folder path → route:

```
lib/pages/market_surveillance/article/list/page.dart
  → Class: MarketSurveillanceArticleListPage
  → Path:  /MarketSurveillance/Article/List
  → Const: RouterConstants.marketSurveillanceArticleList
```

**Quy tắc đặt tên:**
- Folder `snake_case` → PascalCase: `market_surveillance` → `MarketSurveillance`
- Acronym đặc biệt viết HOA: `lms` → `LMS`, `qr` → `QR`, `cms` → `CMS`, `rms` → `RMS`
- File PHẢI tên `page.dart` (hoặc `Page.dart`)
- Folder `widgets/` bị skip — không tạo route

#### Chạy generator

```bash

dart run tool/gen_router.dart
```

Output:
- `lib/routes.dart` — danh sách `GoRoute` (auto-generated, KHÔNG sửa tay)
- `lib/router_constants.dart` — path constants (auto-generated, KHÔNG sửa tay)

#### Convention cho Page class

**Page không có params:**
```dart
class MarketSurveillanceHomePage extends StatelessWidget {
  const MarketSurveillanceHomePage({super.key});
  // ...
}
```
→ Generated: `builder: (context, state) => const MarketSurveillanceHomePage()`

**Page có Map params (phổ biến nhất):**
```dart
class MarketSurveillanceArticleDetailPage extends StatelessWidget {
  final Map params;
  const MarketSurveillanceArticleDetailPage(this.params, {super.key});
  // ...
}
```
→ Generated:
```dart
GoRoute(
  path: '/MarketSurveillance/Article/Detail',
  builder: (context, state) => MarketSurveillanceArticleDetailPage(
    state.uri.queryParameters.isNotEmpty
      ? state.uri.queryParameters
      : state.extra as Map,
  ),
)
```

**Page có typed params:**
```dart
class SomePage extends StatelessWidget {
  final SomeModel data;
  const SomePage(this.data, {super.key});
}
```
→ Generated: `builder: (context, state) => SomePage(state.extra as SomeModel)`

#### Loại trừ page khỏi router

Thêm comment `// @ignoreRouter` vào file page.dart:
```dart
// @ignoreRouter
class MyInternalPage extends StatelessWidget { ... }
```

#### Custom router

Thêm annotation `@useCustomRouter` để dùng static `.router` của page thay vì auto-gen:
```dart
// @useCustomRouter
class SpecialPage extends StatelessWidget {
  static final GoRoute router = GoRoute(
    path: '/custom-path',
    builder: (context, state) => const SpecialPage(),
  );
  // ...
}
```

#### Redirect support

Định nghĩa static method `redirect` trong page class — generator tự detect và thêm:
```dart
class StartPage extends StatelessWidget {
  static String? redirect(BuildContext context, GoRouterState state) {
    // redirect logic
    return null;
  }
}
```

#### Config files (tùy chọn)

| File | Mô tả |
|------|--------|
| `lib/router_factory.json` | Rename folder segment: `{"merchant": "Shop"}` |
| `lib/routes_manual.json` | Route thủ công cho page không theo convention |
| `lib/ignore_router.dart` | Import lines cần skip |

#### Navigation

```dart
// Push (thêm vào stack)
appNavigator.pushNamed(
  RouterConstants.marketSurveillanceArticleDetail,
  arguments: item.toJson(),  // → state.extra
);

// Go (replace stack)
appNavigator.go(RouterConstants.marketSurveillanceArticleList);

// Push với query params
appNavigator.go('${RouterConstants.marketSurveillanceArticleList}?initialIndex=1');
```

#### Ví dụ end-to-end: Thêm feature Article

1. Tạo thư mục:
```
lib/pages/market_surveillance/article/
├── list/
│   ├── page.dart    ← MarketSurveillanceArticleListPage(this.params)
│   ├── bloc.dart
│   └── widgets/
│       └── item.dart
├── detail/
│   ├── page.dart    ← MarketSurveillanceArticleDetailPage(this.params)
│   └── bloc.dart
└── form/
    ├── page.dart    ← MarketSurveillanceArticleFormPage(this.params)
    └── bloc.dart
```

2. Chạy generator:
```bash
dart run tool/gen_router.dart
```

3. Generator tự sinh 3 routes + 3 constants:
```dart
// router_constants.dart (auto)
static String get marketSurveillanceArticleList => '/MarketSurveillance/Article/List';
static String get marketSurveillanceArticleDetail => '/MarketSurveillance/Article/Detail';
static String get marketSurveillanceArticleForm => '/MarketSurveillance/Article/Form';
```

4. Dùng trong code:
```dart
// Từ list → detail
appNavigator.pushNamed(
  RouterConstants.marketSurveillanceArticleDetail,
  arguments: item.toJson(),
);

// Từ list → form (create)
appNavigator.pushNamed(
  RouterConstants.marketSurveillanceArticleForm,
  arguments: {},
);

// Từ detail → form (edit)
appNavigator.pushNamed(
  RouterConstants.marketSurveillanceArticleForm,
  arguments: {'_id': articleId},
);
```

---

## Kiến trúc layer (nhắc lại nhanh)

```
Widget / Page
    ↓ dispatch event
BLoC (SystemListBloc / SystemDetailBloc / SystemFormBloc)
    ↓ call
DataSource (RestDataSource)
    ↓ HTTP request
Backend (REST API)
```

**Không được phép:** Widget → API trực tiếp, BLoC → Navigator trực tiếp, import `DioException` trong BLoC.

---

## Base classes chính

| Class | Dùng cho | Package |
|-------|---------|---------|
| `AppListBloc<T>` | Danh sách + pagination + search + filter | `shared_state` |
| `AppFormBloc<T>` | Form create/edit + validation + submit (wrapper) | `shared_state` |
| `SystemListBloc<S, T>` | Base class cho `AppListBloc` | `shared_state` |
| `SystemDetailBloc<S>` | Chi tiết 1 item + refresh (kế thừa trực tiếp) | `shared_state` |
| `SystemFormBloc<S>` | Base class cho `AppFormBloc` | `shared_state` |
| `SystemListScaffold<B, S, T>` | Scaffold cho list page | `shared_state` |
| `SystemDetailScaffold<B>` | Scaffold cho detail page | `shared_state` |
| `SystemFormScaffold<B, S>` | Scaffold cho form page | `shared_state` |

### Hierarchy

```
BaseBloc<Event, State>
    ├── SystemListBloc<SystemListState<T>, T>
    │       └── AppListBloc<T extends JsonModel<T>>       ← Dùng class này
    ├── SystemDetailBloc<SystemDetailState>              ← Dùng class này (kế thừa trực tiếp)
    └── SystemFormBloc<SystemFormState>
            └── AppFormBloc<T extends JsonModel<T>>       ← Hoặc extend SystemFormBloc trực tiếp
```

---

### AppListBloc<T> — Danh sách

**Khi nào dùng:** Mọi trang danh sách có pagination, search, filter.

**Constructor params:**

| Param | Type | Mô tả |
|-------|------|--------|
| `api` | `String` | Tên resource/table (vd: `'articles'`, `'complaints'`) |
| `empty` | `T` (required) | Instance rỗng để parse JSON: `const ArticleItem.empty()` |
| `dataSource` | `DataSource?` | `RestDataSource()` |
| `suggestTitle` | `String?` | Field name cho search suggest (vd: `'title'`) |
| `filters` | `Map?` | Filter ban đầu |
| `options` | `Map?` | Options: `{'suggestTitle': 'title'}`, `pageNo`, `itemsPerPage`, `orderBy` |
| `extraParams` | `Map?` | Params bổ sung gửi kèm API |
| `fixedFilters` | `Map?` | Filter cố định không bị user xóa |

**Ví dụ (Article):**
```dart
class ArticleListBloc extends AppListBloc<ArticleItem> {
  ArticleListBloc({Map<String, dynamic>? initialFilters})
      : super(
          api: 'articles',
          empty: const ArticleItem.empty(),
          dataSource: RestDataSource(),
          filters: initialFilters,
          options: {'suggestTitle': 'title'},
        );
}
```

**Model yêu cầu:** `T` phải implement `JsonModel<T>`:
```dart
class ArticleItem implements JsonModel<ArticleItem> {
  @override
  String get idField => '_id';          // Field name ID trong DB

  @override
  ArticleItem fromJson(Map<String, dynamic> json) => ArticleItem.fromJson(json);

  @override
  Map<String, dynamic> toJson() => { ... };

  const ArticleItem.empty() : id = '', title = '';  // Bắt buộc có .empty()
}
```

**Events chính:**

| Event | Mô tả |
|-------|--------|
| `FetchItemsBaseList` | Fetch trang đầu |
| `LoadMoreBaseList` | Load thêm trang tiếp |
| `RefreshBaseList` | Refresh (pull-to-refresh) |
| `SearchBaseList(keyword)` | Remote search (debounce 2s) |
| `LocalSearchBaseList(keyword)` | Client-side search (debounce 200ms) |
| `FilterBaseList(filters, clearItems: true)` | Áp dụng filter mới |
| `ResetFilterBaseList` | Reset về fixedFilters |
| `OrderByBaseList(orderBy)` | Sắp xếp |
| `SelectItemBaseList(id)` | Chọn 1 item |
| `SelectAllBaseList` / `DeselectAllBaseList` | Chọn/bỏ chọn tất cả |
| `ActionBaseList(context, service, params, ...)` | Action 1 item (delete, approve) |
| `MultiActionBaseList(...)` | Batch action trên selected items |

**State: `SystemListState<T>`**

| Field | Type | Mô tả |
|-------|------|--------|
| `status` | `BaseListStateStatus` | `initial` / `loading` / `loaded` / `fail` |
| `items` | `List<T>` | Danh sách items hiện tại |
| `filters` | `Map` | Filter đang áp dụng |
| `totalItems` | `int?` | Tổng số items trên server |
| `keyword` | `String?` | Từ khóa search hiện tại |
| `selectedIds` | `Set<String>?` | IDs đang được chọn |
| `isRefreshing` | `bool` | Đang refresh |
| `isLoadingMore` | `bool` | Đang load thêm |
| `pageNo` | `int` | Trang hiện tại |
| `maxPage` | `int` | Tổng số trang |
| `hasMax` | `bool` | Đã hết data chưa |

**Scaffold: `SystemListScaffold<B, S, T>`**
```dart
SystemListScaffold<ArticleListBloc, SystemListState<ArticleItem>, ArticleItem>(
  header: Column(children: [
    SearchBarWidget<ArticleListBloc, SystemListState<ArticleItem>, ArticleItem>(...),
    // Custom filter tabs, buttons...
  ]),
  detailBuilder: (context, item, isSelected) => ArticleListItem(item),
  // Tự xử lý: pagination, pull-to-refresh, loading, empty state, error
)
```

---

### SystemDetailBloc — Chi tiết

**Khi nào dùng:** Trang xem chi tiết 1 item.

**Constructor params (đều named):**

| Param | Type | Mô tả |
|-------|------|--------|
| `dataSource` | `DataSource?` | DataSource adapter (REST/Supabase) — REST dùng `apiPath` để định tuyến |
| `query` | `DetailQuery?` | `{id, filters}` cho bản ghi cần fetch |
| `resource` | `String` | Tên resource/table (chỉ cần cho Supabase / luồng `apiCall` cũ) |
| `service` | `String` | **`@Deprecated`** — REST tự xử lý qua `dataSource`; sẽ bỏ |

**Ví dụ (Article — REST):**
```dart
class ArticleDetailBloc extends SystemDetailBloc {
  final Map item;

  ArticleDetailBloc(this.item)
      : super(
          dataSource: ApiService.catalog.apiPath(
            ApiAddress.catalog.articleById((item['_id'] ?? item['id']).toString()),
          ),
        );
}
```

> **Lưu ý:** Detail bloc kế thừa `SystemDetailBloc` trực tiếp. Với REST, endpoint đã nằm trong `dataSource` (`apiPath`) nên không cần `service`/`resource`.

**Events chính:**

| Event | Mô tả |
|-------|--------|
| `FetchDataBaseDetail(clearResult: false)` | Fetch data (auto-trigger khi init) |
| `RefreshBaseDetail(completer)` | Refresh (pull-to-refresh) |
| `UpdateResultBaseDetail(key, value)` | Update 1 field trong result |
| `ChangeQueriesBaseDetail(queries, force)` | Đổi query params và refetch |
| `ActionBaseDetail(context, service, params, ...)` | Action trên item (delete, approve) |
| `UpdateExtraDataBaseDetail(data, force)` | Lưu metadata bổ sung |

**State: `SystemDetailState`**

| Field | Type | Mô tả |
|-------|------|--------|
| `status` | `SystemDetailStateStatus` | `initial` / `loading` / `loaded` / `error` |
| `result` | `Map` | Data chi tiết item |
| `error` | `String?` | Thông báo lỗi |
| `isRefreshing` | `bool` | Đang refresh |
| `extraData` | `Map` | Metadata bổ sung |
| `queries` | `Map?` | Query params hiện tại |

**Scaffold: `SystemDetailScaffold<B>`**
```dart
SystemDetailScaffold<ArticleDetailBloc>(
  appBar: BaseAppBar(context: context, title: const Text('Chi tiết')),
  builder: (context, state, params) {
    // params = state.result (Map)
    return SingleChildScrollView(
      child: Column(children: [
        Text(params['title']),
        HTMLViewer(params['content']),
      ]),
    );
  },
)
```

> Scaffold tự xử lý loading spinner, error message, và refresh.

---

### SystemFormBloc / AppFormBloc<T> — Form create/edit

**Khi nào dùng:** Trang tạo mới hoặc chỉnh sửa item.

**Constructor params (SystemFormBloc):**

| Param | Type | Mô tả |
|-------|------|--------|
| `dsResource` | `String?` | Tên resource/table cho DataSource |
| `dsParams` | `Map?` | Params: `{'_id': 'xxx'}` cho edit mode, `{}` cho create |
| `dataSource` | `DataSource?` | DataSource adapter |
| `submitService` | `String` | API endpoint cho submit ('' = dùng DataSource) |
| `selectService` | `String?` | API endpoint cho fetch data edit mode |
| `initFields` | `Map?` | Giá trị khởi tạo cho create mode |
| `rules` | `Map<String, Rules>?` | Validation rules theo field |

**Detect create vs edit mode:**
- Có `dsParams['id']` hoặc `selectService` != '' → **EDIT mode** (fetch data trước)
- Không có → **CREATE mode** (dùng `initFields`)

**Ví dụ (Article — extend SystemFormBloc trực tiếp):**
```dart
class ArticleFormBloc extends SystemFormBloc {
  ArticleFormBloc({Map<String, dynamic>? params})
      : super(
          dsResource: 'articles',
          dsParams: params,
          dataSource: RestDataSource(),
          submitService: '',
        );
}
```

**Ví dụ (dùng AppFormBloc wrapper):**
```dart
class ComplaintFormBloc extends AppFormBloc<ComplaintItem> {
  ComplaintFormBloc({Map<String, dynamic>? params})
      : super(
          resource: 'complaints',
          params: params,
          dataSource: RestDataSource(),
          rules: {
            'fields[title]': Rules(required: 'Vui lòng nhập tiêu đề'),
            'fields[content]': Rules(required: 'Vui lòng nhập nội dung'),
          },
        );
}
```

**Events chính:**

| Event | Mô tả |
|-------|--------|
| `FetchDataSystemForm` | Fetch data cho edit mode (auto khi init) |
| `UpdateFieldSystemForm(key, value)` | Update 1 field |
| `UpdateMultiFieldSystemForm(fields)` | Update nhiều field cùng lúc |
| `SubmitSystemForm` | Validate + submit |
| `ResetSystemForm` | Reset form |
| `ClearErrorsSystemForm` | Xóa lỗi validation |
| `NextStepSystemForm` / `BackStepSystemForm` | Multi-step form |

**Operator shorthand:**
```dart
bloc['title'] = 'New title';  // = bloc.add(UpdateFieldSystemForm('title', 'New title'))
```

**State: `SystemFormState`**

| Field | Type | Mô tả |
|-------|------|--------|
| `status` | `SystemFormStateStatus` | `initial` / `loading` / `loaded` / `submitting` / `success` / `fail` / `validFail` |
| `fields` | `Map<String, dynamic>` | Giá trị các field hiện tại |
| `errors` | `Map<String, String>` | Lỗi validation theo field |
| `data` | `Map` | Data gốc từ server (edit mode) |
| `message` | `String?` | Thông báo chung |
| `response` | `Map` | Response từ submit |
| `stepIndex` | `int` | Step hiện tại (multi-step form) |

**Validation rules:**
```dart
rules: {
  'fields[title]': Rules(required: 'Tiêu đề bắt buộc'),
  'fields[email]': Rules(required: 'Email bắt buộc', email: 'Email không hợp lệ'),
  'fields[phone]': Rules(phoneVN: 'SĐT không hợp lệ'),
  'fields[password]': Rules(
    required: 'Mật khẩu bắt buộc',
    minLength: Rule(8, 'Tối thiểu 8 ký tự'),
  ),
  'fields[confirm]': Rules(
    equalTo: Rule('fields[password]', 'Mật khẩu không khớp'),
  ),
}
```

**Scaffold: `SystemFormScaffold<B, S>`** — dùng kèm **Fields module** (xem mục riêng bên dưới).

> ⚠️ **KHÔNG dùng `TextFormField` / `Form*` widget cũ trong form.** Dùng `Field*` widget từ
> `package:core_widgets/fields.dart`. Mỗi field bind qua `wrapper<T>('key', builder: ...)`.

```dart
import 'package:core_widgets/fields.dart';   // BẮT BUỘC cho Field* widgets

SystemFormScaffold<ArticleFormBloc, SystemFormState>(
  appBarBuilder: (context, state) => BaseAppBar(
    context: context,
    title: Text(empty(params['id']) ? 'Tạo mới' : 'Chỉnh sửa'),
  ),
  builder: (context, state, wrapper) {
    return ListView(
      padding: basePadding,
      children: [
        wrapper<String>('title', builder: (context, data, onChanged) {
          return FieldText(
            labelText: 'Tiêu đề',
            required: true,
            value: data.getValue(),     // giá trị field
            errorText: data.error,      // tự hiển thị lỗi validation
            onChanged: onChanged,
          );
        }),
        h16,
        wrapper<String>('content', builder: (context, data, onChanged) {
          return FieldText(
            labelText: 'Nội dung',
            value: data.getValue(),
            maxLines: 10,
            minLines: 3,
            onChanged: onChanged,
          );
        }),
      ],
    );
  },
  // Bottom bar với nút Save tự động — auto enable/disable theo validation
)
```

**Wrapper pattern giải thích:**
- `wrapper<T>('fieldName', builder: ...)` — bind 1 field vào `Field*` widget
- `data.getValue()` — giá trị hiện tại của field (`dynamic` → cast khi cần; KHÔNG dùng `data.value`)
- `data.error` — lỗi validation (null nếu valid) → truyền vào `errorText`
- `data.enabled` — field có enabled không (via `checkEnable`)
- `onChanged` — truyền thẳng vào `Field*.onChanged` (dispatch `UpdateFieldSystemForm`)
- Với field list/map (media nhiều file, tag, multiple) truyền `isMultiple: true`
- Field cần giá trị mặc định khác null để enable nút Save → truyền `hasValue: true`
- Wrapper dùng `BlocSelector` bên trong → chỉ rebuild khi field đó thay đổi

---

## Fields module — Form Fields V2 (`package:core_widgets/fields.dart`)

> 🚫 **Module `form.dart` cũ (`Form*` widget) đã deprecated cho feature mới.** Toàn bộ form
> mới PHẢI dùng `Field*` widget. KHÔNG import cả `form.dart` và `fields.dart` trong 1 file.

### Nguyên tắc

- Prefix `Field` thay `Form` (tránh conflict với Flutter `Form`)
- Binding qua `wrapper<T>('field', builder: (context, data, onChanged) => ...)`. Trong builder, `data` là
  **`FormFieldData`** → dùng `data.getValue()` (trả `dynamic`, **cast khi cần**) và `data.error`.
  (`FieldData<T>` là holder typed độc lập, **chưa** wire vào wrapper — đừng dùng `data.value` trong builder.)
  - String field: `value: data.getValue()`
  - bool field: `value: data.getValue() ?? false`
  - List field: `urls: (data.getValue() as List?)?.cast<String>()`
- `FieldScope` — InheritedWidget cung cấp `FileUploadService` + `DataSource` (set 1 lần ở gốc app), KHÔNG dùng `getIt`.
  **`FieldMedia` bắt buộc có `FieldScope` ở gốc app** (lấy `uploadService`); `FieldSelect` remote lấy `DataSource` từ đây.
- `FieldSelect.items` nhận **`List<Map>`** (mỗi map có `valueKey`='id', `labelKey`='title'), KHÔNG phải `Map<String,Map>`.
- `FieldMedia`: bind URL string qua `url`/`onUrlChanged` (single) · `urls`/`onUrlsChanged` (multi) — hoặc `FileRef` qua `value`/`listValue`.

### Bảng widget (V1 `Form*` → V2 `Field*`)

| Nhu cầu | Field widget | Data type | Form* cũ (KHÔNG dùng) |
|---------|-------------|-----------|------------------------|
| Text 1/nhiều dòng | `FieldText` | `String` | `FormTextField`, `FormTextArea` |
| Số / tiền tệ | `FieldNumber` (`isCurrency`, `decimalPlaces`) | `String` | `FormNumber` |
| Rich text | `FieldRichText` | `String` | `FormTextArea` |
| Search debounce | `FieldSearch` | `String` | `FormSearch` |
| Checkbox | `FieldCheckbox` | `bool` | `FormCheckbox` |
| Radio group | `FieldRadio` | `String` | `FormRadio` |
| Toggle on/off | `FieldSwitch` | `bool` | `FormOnOff`, `FormTrueFalse` |
| Rating sao | `FieldRating` | `double` | `FormRating` |
| Counter +/− | `FieldCounter` | `int` | `FormUpDown` |
| Tag input | `FieldTag` | `List<String>` | `FormTag` |
| Điều khoản | `FieldTerm` | `bool` | `FormTerm` |
| Select (9 variant) | `FieldSelect` | `String` | `FormSelect` |
| Ngày | `FieldDate` | `String` | `FormDatePicker` |
| Giờ | `FieldTime` | `String` | `FormTimePicker` |
| Ngày + giờ | `FieldDateTime` | `String` | `FormDateTime` |
| Khoảng ngày | `FieldDateRange` | `String` | `FormDateRangePicker` |
| Upload ảnh/file/video | `FieldMedia` (8 named ctor) | `String` url / `List<String>` urls | 12 widget upload cũ |
| Nhóm label + child | `FieldGroup` | — | `FormGroup` |
| List động thêm/xoá | `FieldMultiple` | `Map` | `FormMultiple` |
| Hiện child theo checkbox | `FieldShowChecked` | `bool` | `FormShowChecked` |
| Năm sinh | `FieldBirthYear` | `String` | `FormBirthYear` |

### Select — chọn variant qua named constructor

| Constructor | Layout | Khi nào dùng |
|-------------|--------|--------------|
| `.picker()` | Bottom sheet + search | Danh sách dài, cần search/remote |
| `.dropdown()` | Dropdown inline | Danh sách ngắn (< 10) |
| `.chips()` | ChoiceChip wrap | Chọn nhanh inline |
| `.segmented()` | InkWell + leading/trailing | Có icon/avatar |
| `.checkboxGroup()` / `.radioGroup()` | Column hiển thị hết | Multi / single hiện tất cả |
| `.listTile()` | ListTile column | List có action |
| `.builder()` / `.custom()` | Tuỳ chỉnh | Layout custom |

```dart
// Remote (DataSource)
wrapper<String>('city', builder: (context, data, onChanged) {
  return FieldSelect.picker(
    service: 'api/geo/provinces',
    valueKey: '_id',
    labelKey: 'name',
    value: data.getValue(),
    labelText: 'Tỉnh/Thành phố',
    menuTitle: 'Chọn tỉnh/thành phố',
    errorText: data.error,
    onChanged: onChanged,
  );
}),

// Local items
wrapper<String>('gender', builder: (context, data, onChanged) {
  return FieldGroup(
    labelText: 'Giới tính',
    errorText: data.error,
    child: FieldSelect.chips(
      items: const [
        {'id': 'male', 'title': 'Nam'},
        {'id': 'female', 'title': 'Nữ'},
      ],
      value: data.getValue(),
      onChanged: onChanged,
    ),
  );
}),
```

### Media — `FieldMedia` (8 named constructor)

`.image()` · `.images()` · `.file()` · `.files()` · `.video()` · `.videos()` · `.avatar()` · `.multiPicker()`

```dart
// Avatar (single) — String URL
wrapper<String>('avatarUrl', builder: (context, data, onChanged) {
  return FieldMedia.avatar(
    url: data.getValue() as String?,
    onUrlChanged: onChanged,
  );
}),

// Nhiều ảnh (multi) — List<String>
wrapper<List<String>>('images', isMultiple: true, builder: (context, data, onChanged) {
  return FieldMedia.images(
    labelText: 'Hình ảnh',
    extensions: const ['jpg', 'jpeg', 'png', 'webp'],
    urls: (data.getValue() as List?)?.cast<String>(),
    onUrlsChanged: onChanged,
  );
}),
```

> `image`/`images` dùng gallery (image_picker) — KHÔNG lọc theo `extensions` lúc chọn (validate sau).
> `file`/`files` dùng FilePicker — `extensions` LỌC ngay lúc chọn.

**Reference example đầy đủ (đọc trước khi code form):**
`lib/pages/account/edit_information/page.dart` — demo mọi Field widget với `SystemFormWidget` + wrapper.

---

## Cấu trúc thư mục feature chuẩn

```
lib/pages/{feature}/
├── list/
│   ├── bloc.dart                     # extends AppListBloc<T>
│   ├── page.dart                     # BlocProvider + SystemListScaffold
│   └── widgets/
│       └── item.dart                 # StatelessWidget cho 1 item
├── detail/
│   ├── bloc.dart                     # extends SystemDetailBloc
│   └── page.dart                     # BlocProvider + SystemDetailScaffold
└── form/
    ├── bloc.dart                     # extends SystemFormBloc
    └── page.dart                     # BlocProvider + SystemFormScaffold
```

---

## Checklist trước khi PR

- [ ] `dart format -l 100 .` pass
- [ ] `dart analyze` pass (zero warnings)
- [ ] Route đã sinh bằng `dart run tool/gen_router.dart`
- [ ] Không có `print()` — dùng `debugPrint()` hoặc Crashlytics
- [ ] Không hardcode màu/text style — dùng `AppColors`, `AppTextStyles`
- [ ] Không hardcode chuỗi — dùng l10n (`context.l10n`)
- [ ] Controller / FocusNode / StreamSubscription đã `dispose()`
- [ ] Không dùng `BuildContext` sau `await` mà không check `mounted`

---

## Tài liệu tham khảo

| Tài liệu | Nội dung |
|---------|---------|
| `CLAUDE.md` (root) | Workspace structure, commands, architecture pattern, coding rules A–F |
| `CLAUDE.md` | Bootstrap, session model, routing, globals |
| `lib/pages/complain/` | Mẫu feature đầy đủ: list + detail + edit |
| `lib/pages/bookmark/` | Mẫu SystemListScaffold đơn giản |
| `lib/pages/account/edit_information/page.dart` | **Mẫu form Fields V2** — demo mọi `Field*` widget |
| `/Users/nguyenhuutrung/Documents/AppCore/packages/shared_core/shared_widgets/docs/form_v2_usage_plan.md` | Tài liệu đầy đủ Fields module (API reference 22 widget + migration V1→V2) |
