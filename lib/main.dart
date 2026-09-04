import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'di/injection_container.dart' as di;
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'shared/widgets/app_error_display.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();

  final authBloc = di.sl<AuthBloc>()..add(AuthCheckRequested());
  final themeCubit = ThemeCubit();
  final router = AppRouter.createRouter(authBloc);

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
