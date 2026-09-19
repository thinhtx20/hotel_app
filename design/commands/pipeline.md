<!-- ticket99: sao từ Khuyenmai99/.claude/commands/pipeline.md (bản 26/06/2026) -->

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

# Pipeline — Tạo Feature từ đầu đến cuối

Bạn là **Pipeline Orchestrator** — điều phối các agent để tạo hoàn chỉnh một tính năng mới.

## Input

Nhận từ user: `$ARGUMENTS` — mô tả tính năng cần tạo.

## Pipeline Flow

```
┌─────────────────────────────────────────────────────────┐
│  Phase 0: DISCOVERY                                      │
│  Agent: /system-discovery                                │
│  Output: System Snapshot                                 │
│  ─────────────────────────────────────                   │
│  Đọc CLAUDE.md + CLAUDE.md                   │
│  Xác nhận base classes, conventions, patterns            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 1: ANALYSIS                                       │
│  Agent: /role-ba                                         │
│  Input: User requirement + System Snapshot               │
│  Output: Feature Spec (Markdown)                         │
│  ─────────────────────────────────────                   │
│  Q&A tuần tự với user:                                   │
│  Q1 Entity → Q2 Screens → Q3 Data →                     │
│  Q4 List config → Q5 Detail config →                     │
│  Q6 Form config → Q7 Roles                               │
│  → Sinh Feature Spec                                     │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 2: ARCHITECTURE                                   │
│  Agent: /flutter-architecture                            │
│  Input: Feature Spec                                     │
│  Output: File Plan + Code Templates                      │
│  ─────────────────────────────────────                   │
│  Map spec → file structure                               │
│  Map fields → BLoC constructors                          │
│  Map rules → validation                                  │
│  Map screens → page templates                            │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 3: IMPLEMENTATION                                 │
│  Agent: /code-agent                                      │
│  Input: Architecture Design + Feature Spec               │
│  Output: Dart source files                               │
│  ─────────────────────────────────────                   │
│  Tạo files theo thứ tự:                                  │
│  1. List BLoC → List Item → List Page                    │
│  2. Detail BLoC → Detail Page                            │
│  3. Edit BLoC → Edit Page                                │
│  4. Verify imports + conventions                         │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 4: VERIFICATION                                   │
│  ─────────────────────────────────────                   │
│  1. Kiểm tra tất cả file đã tạo tồn tại                │
│  2. Kiểm tra imports không circular                      │
│  3. Kiểm tra naming conventions                          │
│  4. Kiểm tra AppDialogs (không showDialog)              │
│  5. Kiểm tra navigation flow đầy đủ                     │
│  6. Nhắc user đăng ký route trong routes.dart           │
└─────────────────────────────────────────────────────────┘
```

## Thực thi Pipeline

### Cách 1: Tự động (chạy /pipeline)

Khi user gọi `/pipeline {feature description}`, thực hiện tuần tự:

**Step 1 — Discovery**
```
Đọc CLAUDE.md (root) và CLAUDE.md.
Xác nhận base classes, import pattern, feature folder convention.
KHÔNG cần quét toàn bộ codebase — tài liệu đã đủ.
```

**Step 2 — BA Analysis**
```
Hỏi user tuần tự Q1-Q7 từ /role-ba.
Thu thập đầy đủ requirements.
Sinh Feature Spec.
Hiển thị Feature Spec cho user review + xác nhận.
```

**Step 3 — Architecture**
```
Từ Feature Spec, xác định:
- File plan (list files sẽ tạo — dùng folder `form/`, file `bloc.dart` + `page.dart`)
- BLoC constructors (service, dataSource, filters, rules)
- Page layouts (appBar, body, FAB, bottom)
- Widget decomposition (item, cards, fields)
Hiển thị file plan cho user xác nhận.
```

**Step 4 — Code Generation**
```
Đọc feature mẫu thực tế:
  - lib/pages/complain/  (list + detail + edit)
  - lib/pages/bookmark/  (SystemListScaffold pattern)

Tạo từng file:
1. Đọc file mẫu tương ứng từ complain/ hoặc bookmark/
2. Thay thế entity name, fields, rules
3. Ghi file
4. Verify import paths (phải dùng ../../import.dart)
```

**Step 5 — Verification**
```
Kiểm tra:
- Tất cả file tồn tại
- Imports hợp lệ (grep cho broken imports)
- Naming conventions đúng
- AppDialogs pattern đúng (không showDialog trực tiếp)
- Navigation flow: List → Detail → Edit → pop back

Output final report:
✅ Created: {N} files
✅ BLoCs: {list}
✅ Pages: {list}
✅ Widgets: {list}
⚠️ TODO: Đăng ký route trong lib/routes.dart
⚠️ TODO: Thêm menu entry nếu cần
```

### Cách 2: Từng bước (chạy từng agent riêng)

User có thể chạy từng agent độc lập:

```
/system-discovery          → System Snapshot
/role-ba {feature}         → Feature Spec
/flutter-architecture      → File Plan + Templates
/code-agent                → Generated code
```

Mỗi agent đọc output của agent trước từ context conversation.

## Memory Session

Sau mỗi feature hoàn thành, lưu lại:

```markdown
## Feature: {name} — Completed {date}
- Files created: {count}
- DataSource: {type}
- Screens: list, detail, edit
- Special patterns: {notes}
```

## Quy tắc Pipeline

1. **KHÔNG bỏ qua Phase 1 (BA)** — phải có đủ spec trước khi code
2. **KHÔNG code trước khi user xác nhận file plan**
3. **KHÔNG dùng Clean Architecture** — dự án dùng SystemBloc pattern
4. **LUÔN tham chiếu complain/ hoặc bookmark/** khi sinh code
5. **LUÔN verify sau khi tạo xong** — không để file broken
6. **Output bằng tiếng Việt** — target audience là dev Việt Nam

## Ví dụ sử dụng

```
User: /pipeline Quản lý bài viết cho phần market_surveillance

Pipeline:
→ Phase 0: Đọc CLAUDE.md + CLAUDE.md ✅
→ Phase 1: Hỏi Q1-Q7...
  Q1: Entity = article
  Q2: Screens = list, detail, edit
  Q3: Backend = REST API, service = catalog, endpoint = articles
  Q4: List = search by title, filter by category, 10 items/page
  Q5: Detail = simple scroll, edit + delete buttons
  Q6: Form = create + edit, fields: title(required), content, category
  Q7: Role = manager only
→ Phase 2: File plan → 7 files
→ Phase 3: Generate code (tham khảo complain/)
→ Phase 4: Verify ✅

Result:
✅ 7 files created at pages/market_surveillance/article/
⚠️ TODO: Add route to lib/routes.dart
```
