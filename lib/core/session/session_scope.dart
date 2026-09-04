import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';

/// Danh tính của phiên đăng nhập hiện tại: đổi tài khoản là đổi chuỗi này.
///
/// Gộp cả `id` lẫn vai trò để phòng khi API không trả `id` — lúc đó đổi vai
/// trò vẫn ra khóa khác nhau.
String sessionIdOf(AuthState state) {
  if (state is AuthAuthenticated) {
    return '${state.user.id}|${state.user.role.value}';
  }
  // Đổi tài khoản hỏng giữa chừng: phiên cũ chưa mất, đừng dựng lại màn hình.
  if (state is AuthFailure && state.previousUser != null) {
    final user = state.previousUser!;
    return '${user.id}|${user.role.value}';
  }
  return 'guest';
}

/// Bọc một màn hình để nó được **dựng lại từ đầu** mỗi khi đổi tài khoản.
///
/// Không có widget này thì `State` của màn hình cũ được giữ nguyên khi tài
/// khoản đổi giữa phiên (nút chuyển vai trò ở Hồ sơ, hoặc đăng nhập lại bằng
/// tài khoản khác): dữ liệu đã tải trong `initState` của người dùng trước vẫn
/// nằm nguyên trên màn hình. Đổi khóa của [KeyedSubtree] khiến Flutter hủy
/// `State` cũ và chạy lại `initState` — màn hình tự tải lại dữ liệu theo đúng
/// tài khoản mới.
class SessionScope extends StatelessWidget {
  final Widget child;

  const SessionScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    String sessionId;
    try {
      sessionId = sessionIdOf(context.watch<AuthBloc>().state);
    } catch (_) {
      // Cây widget không có AuthBloc (widget test dựng thẳng màn hình).
      sessionId = 'no-auth-bloc';
    }

    return KeyedSubtree(
      key: ValueKey<String>(sessionId),
      child: child,
    );
  }
}
