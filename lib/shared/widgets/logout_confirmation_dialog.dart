import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import 'app_confirm_dialog.dart';
import 'app_error_display.dart';

/// Hộp thoại Modal Bottom Sheet xác nhận đăng xuất phong cách Modern Luxury.
/// Tương thích ngược và sử dụng [AppConfirmDialog] bên dưới.
class LogoutConfirmationDialog {
  static Future<void> show(BuildContext context) async {
    await AppConfirmDialog.show(
      context,
      title: 'Xác Nhận Đăng Xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng? Phiên làm việc sẽ được thu hồi trên máy chủ và thiết bị.',
      confirmLabel: 'Đăng Xuất',
      cancelLabel: 'Hủy',
      icon: Icons.logout_rounded,
      isDanger: true,
      onConfirm: () {
        context.read<AuthBloc>().add(AuthLogoutRequested());
        AppNotification.showSuccess(
          context,
          'Đã đăng xuất tài khoản',
        );
      },
    );
  }
}
