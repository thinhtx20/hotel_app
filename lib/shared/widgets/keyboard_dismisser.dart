import 'package:flutter/material.dart';

/// Tự động ẩn bàn phím khi người dùng chạm ra ngoài ô nhập liệu.
///
/// Được gắn một lần duy nhất tại `MaterialApp.router(builder: ...)` nên có hiệu
/// lực cho **toàn bộ** ứng dụng: mọi màn hình, `showDialog`, `showModalBottomSheet`
/// đều nằm bên trong Navigator mà builder bọc, và mọi `TextField` /
/// `TextFormField` đều được tính đến mà không cần sửa từng chỗ.
///
/// Ba lớp xử lý bổ trợ nhau:
/// 1. [TextFieldTapRegion] rộng 0px, cùng nhóm với mọi ô nhập liệu của Flutter.
///    Flutter chỉ gọi `onTapOutside` của nó khi cú chạm nằm ngoài **tất cả** ô
///    nhập liệu đang hiển thị — nên chạm vào nút bấm, thẻ, tab, AppBar… đều ẩn
///    bàn phím, còn chạm vào chính ô nhập liệu (kể cả icon xoá trong ô, thanh
///    công cụ copy/paste) thì không.
/// 2. [GestureDetector] trong suốt để bắt cú chạm rơi vào vùng hoàn toàn trống,
///    nơi không có widget nào nhận sự kiện.
/// 3. Lắng nghe cuộn: kéo tay để cuộn danh sách cũng ẩn bàn phím.
class KeyboardDismisser extends StatelessWidget {
  const KeyboardDismisser({
    super.key,
    required this.child,
    this.dismissOnScroll = true,
  });

  final Widget child;

  /// Ẩn bàn phím khi người dùng kéo tay để cuộn danh sách.
  final bool dismissOnScroll;

  /// Đóng bàn phím từ bất kỳ đâu (dùng được cả trong callback không có context).
  static void dismiss() {
    final focus = FocusManager.instance.primaryFocus;
    // Khi không còn ô nhập liệu nào giữ focus, primaryFocus lùi về FocusScopeNode.
    // Bỏ qua trường hợp này để tránh gọi unfocus lặp lại (nhất là lúc đang cuộn)
    // và tránh làm hỏng focus scope của route đang hiển thị.
    if (focus == null || focus is FocusScopeNode) return;
    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (dismissOnScroll) {
      content = NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          // Chỉ đóng khi người dùng chủ động kéo, không đóng khi danh sách tự
          // cuộn do bàn phím bung ra làm đổi layout.
          if (notification.dragDetails != null) dismiss();
          return false;
        },
        child: content,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: dismiss,
      child: Stack(
        children: [
          content,
          TextFieldTapRegion(
            onTapOutside: (_) => dismiss(),
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
