import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection_container.dart' as di;
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

import 'shared/widgets/app_error_display.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();

  final authBloc = di.sl<AuthBloc>()..add(AuthCheckRequested());
  final router = AppRouter.createRouter(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: HotelApp(router: router),
    ),
  );
}

class HotelApp extends StatelessWidget {
  final dynamic router;

  const HotelApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: AppNotification.messengerKey,
      routerConfig: router,
    );
  }
}
