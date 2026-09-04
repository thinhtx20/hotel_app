# Kịch bản làm mới giao diện — Luxe Grand Hotel

> Tài liệu này là kế hoạch thi công. Nguồn chân lý về thiết kế vẫn là
> [`DESIGN-SYSTEM.md`](./DESIGN-SYSTEM.md) — kịch bản này chỉ nói **làm thế nào để code
> thực sự tuân theo nó**, cộng thêm dark mode và hệ hiệu ứng.

**Quyết định đã chốt**
- Dùng `flutter_animate` cho hiệu ứng.
- Dark mode nằm trong phạm vi, làm ngay ở Giai đoạn 0.
- Ước lượng tổng: **9–10 ngày công**.

---

## 1. Hiện trạng — vấn đề gốc

Dự án **đã có** một design system tốt và đầy đủ: bảng màu đã kiểm chứng mù màu +
tương phản, thang chữ 7 cấp, thang spacing bội số 4, 4 mức đổ bóng, 4 mức thời
lượng hoạt ảnh. Vấn đề không nằm ở thiết kế — nằm ở chỗ **code gần như không dùng nó**.

| Phát hiện | Số liệu đo được |
|---|---|
| `AppSpacing.` / `AppRadius.` / `AppShadows.` được dùng ở | **duy nhất `app_theme.dart`** — 0 lần trong 45 file còn lại |
| `TextStyle(...)` viết tay đè lên `textTheme` | **~380 lần**; riêng `cashier_invoices_screen.dart` 77 lần |
| `BoxShadow(...)` viết tay thay vì `AppShadows` | 51 lần trên 22 file |
| Trạng thái đang tải | `CircularProgressIndicator` ở **14 file**; shimmer skeleton chỉ có ở admin dashboard — trái nguyên tắc #6 của chính design system |
| Hiệu ứng | 9/46 file có animation; **không có page transition** (router dùng `builder` trơn), không Hero, không stagger |
| `_buildEmptyState()` | 5 bản copy-paste độc lập, mỗi bản một kiểu |
| Dark mode | chưa có (`darkTheme` / `ThemeMode` không tồn tại) |
| File quá lớn | cashier 2724 · my_bookings 1383 · profile 1340 · dashboard 1270 dòng |

Baseline sạch: `flutter analyze` chỉ 5 issue vặt (4 field `_isLoading` thừa,
1 `prefer_initializing_formals` trong test). 15 file test đang có.

**Kết luận: không thiết kế lại từ đầu.** Cần một tầng widget dùng chung, rồi ép mọi
màn hình đi qua nó. Đó là đòn bẩy lớn nhất — sửa 1 chỗ, đẹp toàn app.

---

## 2. Nguyên tắc xuyên suốt

1. **Không hằng số ma thuật.** Mọi khoảng cách, bo góc, bóng, cỡ chữ phải đến từ
   `AppSpacing` / `AppRadius` / `AppShadows` / `Theme.of(context).textTheme`.
   Một PR còn `SizedBox(height: 17)` là một PR bị trả lại.
2. **Không màu tĩnh trong màn hình.** Dark mode buộc mọi màu phải hỏi theme.
   `Colors.white` và `AppColors.primary` viết thẳng trong widget là lỗi.
3. **Ba trạng thái là bắt buộc.** Mỗi màn có dữ liệu phải xử lý đủ:
   skeleton → nội dung → rỗng/lỗi. Không màn nào được thiếu.
4. **Hiệu ứng phục vụ ý nghĩa.** Chuyển động để giải thích cái gì đến từ đâu,
   không phải để trang trí. Không có hiệu ứng nào dài quá 400ms.
5. **Mỗi màn một commit,** kèm sửa test của màn đó ngay trong commit.

---

## 3. Giai đoạn 0 — Củng cố nền + Dark mode (2 ngày)

Đây là giai đoạn thay đổi kiến trúc. Làm sai ở đây thì 8 ngày sau phải làm lại.

### 3.1 Tầng màu ngữ nghĩa (semantic colors)

Đây là việc quan trọng nhất của cả kịch bản. Hiện `AppColors` là các hằng số
tĩnh — không thể có hai giá trị cho hai chế độ sáng/tối. Cần chèn một tầng ở giữa.

Tạo `lib/core/theme/app_palette.dart`:

```dart
/// Bảng màu phân giải theo Brightness. Widget KHÔNG bao giờ đọc AppColors
/// trực tiếp nữa — luôn đi qua context.palette.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color canvas;        // nền scaffold
  final Color surface;       // nền thẻ
  final Color surfaceMuted;  // nền chip, ô nhập phụ
  final Color border;
  final Color ink;           // chữ chính
  final Color inkMuted;      // chữ phụ
  final Color inkFaint;      // placeholder
  final Color accent;        // gold
  final Color onAccent;
  // ... + nhóm trạng thái đã phân giải sẵn theo brightness
  const AppPalette({...});

  static const light = AppPalette(
    canvas: AppColors.background,   // #F8FAFC
    surface: AppColors.surface,     // #FFFFFF
    ink: AppColors.textPrimary,     // #0F172A
    accent: AppColors.secondary,    // #D97706
    ...
  );

  static const dark = AppPalette(
    canvas: Color(0xFF0B1120),      // sâu hơn navy 900 một bậc
    surface: AppColors.primary,     // #0F172A làm mặt thẻ
    surfaceMuted: AppColors.primaryLight, // #1E293B
    border: Color(0xFF1E293B),
    ink: Color(0xFFF1F5F9),
    inkMuted: AppColors.slate400,
    accent: AppColors.secondaryLight,  // #FBBF24 — gold sáng đọc tốt trên navy
    ...
  );

  @override AppPalette lerp(AppPalette? other, double t) { ... }
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
```

Nhóm màu trạng thái đã có sẵn hạ tầng: `AppColors` đã định nghĩa đủ ba bộ
`fill` / `ink` / `onDark`. `AppPalette` chỉ cần chọn `ink` cho chế độ sáng và
`onDark` cho chế độ tối — **không phát sinh màu mới, không phải kiểm chứng lại
tương phản.** Đây là lý do dark mode ở dự án này rẻ hơn bình thường.

Cập nhật `RoomStatusVisuals` trong `status_badge.dart` thành
`Color inkOn(BuildContext)` để tự chọn đúng bộ theo brightness.

### 3.2 Dark theme

- Tách `app_theme.dart` thành `_baseTheme(AppPalette)` dùng chung, rồi
  `lightTheme` / `darkTheme` cùng gọi vào đó. Tránh nhân đôi 250 dòng cấu hình.
- Đăng ký `extensions: [AppPalette.light]` / `[AppPalette.dark]`.
- `main.dart`: thêm `darkTheme` + `themeMode`, đọc từ `shared_preferences`
  (package đã có trong pubspec). Mặc định `ThemeMode.system`.
- Tạo `ThemeCubit` nhỏ trong `lib/core/theme/theme_cubit.dart` (flutter_bloc đã có)
  — công tắc đặt ở màn Hồ sơ, làm ở GĐ 2.

### 3.3 Chuyển cảnh giữa các màn

`app_router.dart` hiện dùng `builder:` nên mọi màn nhảy cụp không hiệu ứng.
Chuyển sang `pageBuilder:` với hai kiểu:

| Loại điều hướng | Hiệu ứng | Thời lượng |
|---|---|---|
| Chuyển tab (trong shell) | fade-through, không trượt | 200ms |
| Push màn chi tiết | trượt từ phải + fade nhẹ | 280ms, `easeOutCubic` |
| Splash → Login/Home | fade thuần | 400ms |

Viết một helper `AppPage.slide(...)` / `AppPage.fade(...)` bọc
`CustomTransitionPage` để không lặp lại ở 20 route.

### 3.4 Bổ sung token chuyển động

Thêm vào `app_dimens.dart`:

```dart
class AppMotion {
  static const Curve enter = Curves.easeOutCubic;   // vật thể đi vào
  static const Curve exit  = Curves.easeInCubic;    // vật thể đi ra
  static const Curve emphasis = Curves.easeOutBack; // nhấn mạnh, dùng dè dặt
  static const Duration stagger = Duration(milliseconds: 40); // lệch giữa các item
  static const int staggerMaxItems = 12; // quá số này thì hiện thẳng, tránh giật
}
```

### 3.5 Thêm package & dọn dẹp

```bash
flutter pub add flutter_animate
```
(dùng `pub add` để lấy phiên bản tương thích SDK 3.12.2, đừng ghi tay số version)

Xoá 4 field `_isLoading` không dùng ở các màn admin, sửa
`prefer_initializing_formals` trong `test/auth_logout_test.dart`
→ `flutter analyze` về 0 issue trước khi bước sang GĐ 1.

---

## 4. Giai đoạn 1 — Thư viện widget dùng chung (2 ngày)

Trọng tâm của cả kế hoạch. Làm xong phần này thì GĐ 2 chỉ còn là lắp ghép.
Tất cả đặt trong `lib/shared/widgets/`.

### 4.1 Bố cục & nội dung

| Widget | Vai trò |
|---|---|
| `AppCard` | Thẻ chuẩn: radius 20, `AppShadows.soft`, nền `context.palette.surface`, tự thu 0.98 khi nhấn |
| `AppSectionHeader` | Tiêu đề mục 18/600 + nút "Xem tất cả" tuỳ chọn |
| `AppEmptyState` | Minh họa + một câu giải thích + một nút hành động — thay 5 bản copy-paste |
| `AppErrorState` | Gộp vào `app_error_display.dart` sẵn có, đồng bộ hình thức với `AppEmptyState` |
| `AppBottomSheet` | Vỏ chung: drag handle, radius 28 chỉ trên, nền mờ phía sau |
| `AppSearchField` | Ô tìm kiếm dùng lại ở home + search + cashier |

### 4.2 Skeleton — thay toàn bộ spinner

14 file đang dùng `CircularProgressIndicator`. Design system nói rõ:
*"Mọi trạng thái đang tải phải là skeleton shimmer, không phải vòng xoay giữa màn hình."*

- `SkeletonBox`, `SkeletonText` — nguyên thủy shimmer, tự đổi màu theo palette
  (shimmer trên nền tối phải sáng lên, không tối đi)
- Skeleton chuyên biệt khớp đúng khung xương màn thật:
  `RoomCardSkeleton` · `BookingCardSkeleton` · `InvoiceRowSkeleton` ·
  `StatCardSkeleton` · `RoomMatrixSkeleton`

Spinner chỉ còn được phép tồn tại **bên trong nút đang xử lý**, không bao giờ
chiếm cả màn hình.

### 4.3 Nguyên thủy hiệu ứng

Dùng `flutter_animate` cho hiệu ứng xuất hiện, tự viết cho tương tác chạm:

```dart
// Vào màn — dùng trực tiếp cú pháp flutter_animate
Widget.animate().fadeIn(duration: 250.ms).slideY(begin: .06, curve: AppMotion.enter)

// Danh sách so le — bọc sẵn để thống nhất, có chặn số lượng
class StaggeredList extends StatelessWidget { ... }   // delay = index * AppMotion.stagger,
                                                       // quá staggerMaxItems thì hiện thẳng

// Chạm — tự viết vì cần haptic, flutter_animate không lo phần này
class PressableScale extends StatefulWidget { ... }   // scale 0.97 + HapticFeedback.selectionClick()

// Số liệu dashboard đếm lên từ 0
class AnimatedCounter extends StatelessWidget { ... } // TweenAnimationBuilder + Formatters
```

**Quy ước dùng `flutter_animate`:** chỉ dùng cho *hiệu ứng xuất hiện một lần*
(`fadeIn`, `slideY`, `scale`, `shimmer`). Trạng thái thay đổi liên tục
(đổi màu ô phòng, indicator tab trượt) vẫn dùng `AnimatedContainer` /
`AnimatedAlign` của Flutter — dùng flutter_animate ở đó sẽ chạy lại animation
mỗi lần rebuild, gây nháy.

### 4.4 Sửa widget sẵn có

- **`custom_button.dart`** — thay hex cứng `Color(0x40D97706)` bằng
  `AppShadows.goldGlow`; thêm press-scale + haptic; loading morph (nút co lại
  thành hình tròn thay vì đổi nội dung tại chỗ); màu chữ/nền theo palette.
- **`custom_text_field.dart`** — viền focus chuyển màu mượt, icon đổi màu theo
  trạng thái focus, thông báo lỗi trượt xuống thay vì nhảy ra.
- **`status_badge.dart`** — logic màu đã đúng chuẩn, chỉ chuyển sang
  `AppSpacing`/`AppRadius` và cho `inkOn(context)` chọn bộ màu theo brightness.
- **`logout_confirmation_dialog.dart`** — nâng thành `AppConfirmDialog` dùng chung
  cho mọi xác nhận (huỷ đơn, từ chối phòng, thanh toán).

---

## 5. Giai đoạn 2 — Áp dụng theo màn (4 ngày)

Thứ tự theo mức ấn tượng giảm dần. **Mỗi màn một commit, kèm sửa test ngay.**
Mỗi màn đều phải: bỏ hết TextStyle inline → dùng token → thêm 3 trạng thái →
thêm hiệu ứng vào → kiểm tra ở cả hai chế độ sáng/tối.

**1. Auth — ấn tượng đầu tiên** (`splash` → `login` → `register`)
Logo scale-in từ 0.8, form trượt lên so le 3 nhóm, splash chuyển sang login
bằng fade thay vì nhảy. Nút đăng nhập morph thành vòng xoay khi gửi request.

**2. Khách hàng — Khám phá & Tìm kiếm** (`home_screen`, `room_search_screen`)
Hero ảnh phòng bay từ card sang modal đặt phòng. Chip danh mục có indicator
trượt. Ảnh `CachedNetworkImage` fade-in khi tải xong thay vì đổi cụp.
Header hero mờ dần khi cuộn xuống.

**3. Modal đặt phòng** (`create_booking_modal`, `create_room_modal`)
Chuyển sang `AppBottomSheet`. Sau khi đặt thành công: hiệu ứng dấu tick vẽ dần
rồi tự chuyển sang màn Đơn phòng.

**4. Đơn phòng** (`my_bookings_screen`)
Indicator tab trượt mượt, card vào theo stagger.
**Sửa lỗi thật:** badge trên tab đang hardcode chuỗi `'2'` tại
`customer_tab_scaffold.dart:70` — phải lấy số đơn thật từ repository.

**5. Quản trị — Dashboard + 4 màn chi tiết**
(`admin_dashboard`, `occupancy_detail`, `today_check_ins`, `today_check_outs`,
`pending_bookings`)
Số liệu đếm lên từ 0. Biểu đồ `fl_chart` vẽ dần khi vào màn. Vòng cung tỷ lệ
lấp đầy chạy từ 0 đến giá trị thật. Thẻ chỉ số vào theo stagger.
Tuân thủ mục "Quy tắc biểu đồ" trong `DESIGN-SYSTEM.md` — kiểm tra lại vì đây là
nơi dễ lệch chuẩn nhất.

**6. Sơ đồ buồng phòng** (`room_matrix_screen`)
Ô phòng đổi trạng thái bằng `AnimatedContainer` (màu + nhãn cùng đổi).
Lưới xuất hiện theo từng tầng. Chú thích màu đặt cố định dưới đáy.

**7. Thu ngân** (`cashier_invoices_screen` — 2724 dòng)
**Bắt buộc tách file trước khi restyle**, nếu không sẽ sửa mù:
`widgets/invoice_card.dart` · `widgets/invoice_filter_bar.dart` ·
`widgets/payment_sheet.dart` · `widgets/invoice_detail_sheet.dart`.
Tách xong chạy test `cashier_invoices_test.dart` để chắc chưa vỡ gì, **rồi mới**
đổi giao diện trong commit sau.

**8. Hồ sơ** (`profile_screen` — 1340 dòng)
Avatar Hero. Gom menu rời rạc thành các nhóm `AppCard`.
**Đặt công tắc dark mode ở đây** (`ThemeCubit` từ GĐ 0) — có hiệu ứng chuyển
mượt nhờ `AppPalette.lerp`.

---

## 6. Giai đoạn 3 — Dễ dùng (1 ngày)

Phần này không đẹp hơn nhưng dùng dễ hơn — đừng bỏ.

- **Rà lại đủ 3 trạng thái** trên mọi màn có dữ liệu; hiện nhiều màn thiếu
  trạng thái rỗng hoặc lỗi.
- **Vùng chạm tối thiểu 48×48** — một số icon button đang 24px, khó bấm trúng.
- **Pull-to-refresh** dùng chỉ báo màu gold thay màu mặc định của Material.
- **Snackbar phân loại rõ** success / warning / error. Hiện đang trộn
  `AppColors.amber`, `amberDark`, `rose` tuỳ chỗ, không theo quy luật nào.
- **Dialog xác nhận** đồng bộ qua `AppConfirmDialog`.
- **Trợ năng:** `Semantics` label cho nút chỉ có icon; kiểm tra bố cục ở
  text scale 1.3× (chữ Việt có dấu dễ tràn dòng hơn tiếng Anh).

---

## 7. Giai đoạn 4 — Kiểm chứng

- `flutter analyze` = **0 issue**.
- **15 file test phải xanh trở lại.** Đây là rủi ro lớn nhất, xem mục 8.
- Chạy app thật, chụp màn trước/sau từng màn ở **cả hai chế độ sáng và tối**.
- Kiểm tra hiệu năng cuộn ở màn hoá đơn và sơ đồ phòng — hai màn có danh sách dài nhất.

---

## 8. Rủi ro đã lường trước

| Rủi ro | Mức | Cách xử lý |
|---|---|---|
| **Test vỡ hàng loạt** — test hiện tìm widget theo cấu trúc cây (`find.byType`), đổi giao diện là sai | Cao | Mỗi màn một commit, sửa test của màn đó **ngay trong commit đó**. Tuyệt đối không dồn việc sửa test đến cuối. |
| **4 file khổng lồ** (2724/1383/1340/1270 dòng) | Cao | Tách file thành commit riêng **trước** commit đổi giao diện. Tách và restyle cùng lúc sẽ không review được. |
| **Dark mode bỏ sót chỗ hardcode** — `Colors.white` rải rác ~380 chỗ | Trung bình | Sau mỗi màn, mở chế độ tối kiểm tra bằng mắt. Cân nhắc thêm lint rule cấm `Colors.white`/`Colors.black` ngoài thư mục `core/theme/`. |
| **Stagger gây giật** trên danh sách dài | Trung bình | `AppMotion.staggerMaxItems = 12` — quá số này thì hiện thẳng, không animate. |
| **flutter_animate chạy lại khi rebuild** gây nháy | Trung bình | Quy ước ở mục 4.3: flutter_animate chỉ cho hiệu ứng xuất hiện một lần; trạng thái đổi liên tục dùng `Animated*` của Flutter. |
| Hero animation kèm `CachedNetworkImage` nháy khi bay | Thấp | Dùng chung `imageUrl` làm Hero tag để ảnh đã cache được tái dùng. |

---

## 9. Thứ tự thực thi tóm tắt

```
GĐ 0  (2 ngày)  AppPalette → darkTheme → page transition → AppMotion → pub add → analyze về 0
GĐ 1  (2 ngày)  AppCard/EmptyState/Skeleton/PressableScale/StaggeredList + sửa 4 widget cũ
GĐ 2  (4 ngày)  Auth → Home/Search → Modal → Đơn phòng → Dashboard+4 màn → Ma trận → Thu ngân → Hồ sơ
GĐ 3  (1 ngày)  3 trạng thái · vùng chạm · snackbar · dialog · trợ năng
GĐ 4  (0.5 ngày) analyze + 15 test + chụp màn sáng/tối
```

**Điểm dừng để duyệt:** sau GĐ 1 + màn Auth. Lúc đó phong cách đã lộ rõ trên một
màn hoàn chỉnh, duyệt ở đó rẻ hơn nhiều so với duyệt sau khi đã làm cả 8 màn.
