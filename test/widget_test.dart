import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    final authBloc = AuthBloc();
    final router = AppRouter.createRouter(authBloc);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: HotelApp(router: router),
      ),
    );
    expect(find.byType(HotelApp), findsOneWidget);
  });
}
