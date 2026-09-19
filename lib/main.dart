import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/role_enum.dart';
import 'core/errors/app_bloc_observer.dart';
import 'core/errors/global_error_handler.dart';
import 'core/network/dio_client.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'di/injection_container.dart' as di;
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'shared/widgets/app_error_display.dart';
import 'shared/widgets/in_app_notification_banner.dart';
import 'shared/widgets/keyboard_dismisser.dart';

void main() async {
  // 1. Kích hoạt bộ hứng lỗi toàn cục (Framework, Async Isolate, ErrorWidget)
  GlobalErrorHandler.initialize();

  WidgetsFlutterBinding.ensureInitialized();

  // 2. Kích hoạt BLoC Observer toàn cục
  Bloc.observer = AppBlocObserver();

  // Khởi tạo Firebase và Push Notification
  try {
    await Firebase.initializeApp();
    await PushNotificationService.initialize();
  } catch (e) {
    debugPrint('⚠️ [Firebase] Lỗi khởi tạo: $e');
  }

  await di.initDependencies();

  final authBloc = di.sl<AuthBloc>()..add(AuthCheckRequested());
  DioClient.onSessionExpired = (message) {
    di.clearUserScopedCaches();
    authBloc.add(AuthSessionRevoked(reason: message));
    AppNotification.showError(null, message, title: 'Phiên đăng nhập kết thúc');
  };
  final themeCubit = ThemeCubit();
  final router = AppRouter.createRouter(authBloc);

  // Đăng ký callback điều hướng thông báo khi người dùng nhấn vào thông báo
  PushNotificationService.onNotificationTap = (data) {
    // 1. Gỡ bỏ ngay banner thông báo đang hiển thị để tránh kẹt lớp mờ/chặn chạm
    InAppNotificationBanner.dismiss(immediately: true);

    // 2. Phân tích quyền vai trò tài khoản để điều hướng chính xác
    UserRole? role;
    final authState = authBloc.state;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final targetRoute =
        PushNotificationService.resolveTargetRoute(data, role: role);
    debugPrint('🔔 [FCM Tap] Người dùng bấm thông báo, chuyển tới: $targetRoute');
    try {
      router.go(targetRoute);
    } catch (e) {
      debugPrint('⚠️ [FCM Tap] Lỗi điều hướng router: $e');
    }
  };

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<ThemeCubit>.value(value: themeCubit),
      ],
      child: HotelApp(router: router, themeCubit: themeCubit),
    ),
  );
}

class HotelApp extends StatelessWidget {
  final dynamic router;
  final ThemeCubit? themeCubit;

  const HotelApp({super.key, required this.router, this.themeCubit});

  static ThemeCubit? _findThemeCubit(BuildContext context) {
    try {
      return context.read<ThemeCubit>();
    } catch (_) {
      return null;
    }
  }

  Widget _buildMaterialApp(BuildContext context, ThemeCubit cubit) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: cubit,
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          scaffoldMessengerKey: AppNotification.messengerKey,
          routerConfig: router,
          // Chạm ra ngoài ô nhập liệu (hoặc cuộn danh sách) là ẩn bàn phím —
          // áp dụng cho mọi màn hình, dialog và bottom sheet của app.
          builder: (context, child) =>
              KeyboardDismisser(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingCubit = _findThemeCubit(context);
    if (existingCubit != null) {
      return _buildMaterialApp(context, existingCubit);
    }
    return BlocProvider<ThemeCubit>(
      create: (_) => themeCubit ?? ThemeCubit(),
      child: Builder(
        builder: (ctx) => _buildMaterialApp(ctx, ctx.read<ThemeCubit>()),
      ),
    );
  }
}
