import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';
import 'package:hotel_app/shared/models/user_model.dart';

class FakeAuthBloc extends AuthBloc {
  FakeAuthBloc(UserModel user) : super() {
    emit(AuthAuthenticated(user));
  }
}

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      await initDependencies();
    }
  });

  testWidgets('CustomerTabScaffold renders 4 tabs correctly', (WidgetTester tester) async {
    final customerUser = UserModel(
      id: 'cust-1',
      email: 'customer@hotel.com',
      fullName: 'Nguyễn Văn A',
      role: UserRole.customer,
    );

    final authBloc = FakeAuthBloc(customerUser);
    final router = AppRouter.createRouter(authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: HotelApp(router: router),
      ),
    );

    // Navigate to customer shell
    router.go('/customer');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify 4 TabBar items (FE-ROLE-MATRIX §4.3)
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Dịch vụ'), findsOneWidget);
    expect(find.text('Chuyến đi'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });

  testWidgets('Receptionist StaffTabScaffold renders 5 tabs correctly', (WidgetTester tester) async {
    final receptionistUser = UserModel(
      id: 'rec-1',
      email: 'reception@hotel.com',
      fullName: 'Lễ tân',
      role: UserRole.receptionist,
    );

    final authBloc = FakeAuthBloc(receptionistUser);
    final router = AppRouter.createRouter(authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: HotelApp(router: router),
      ),
    );

    router.go('/receptionist');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify 5 Tab items (FE-ROLE-MATRIX §4.2)
    expect(find.text('Sơ đồ phòng'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(find.text('Duyệt đơn'), findsOneWidget);
    expect(find.text('Hóa đơn & Quỹ'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);
  });
}
