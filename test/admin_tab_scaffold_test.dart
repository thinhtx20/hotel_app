import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/shared/models/room_model.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';

class FakeAuthBloc extends AuthBloc {
  FakeAuthBloc(UserModel user) : super() {
    emit(AuthAuthenticated(user));
  }
}

class MockRoomRepository extends RoomRepository {
  final List<RoomModel> _mockPendingRooms;
  MockRoomRepository(this._mockPendingRooms);

  @override
  List<RoomModel> get pendingRooms => _mockPendingRooms;

  @override
  Future<void> fetchRooms({
    bool forceRefresh = false,
    RoomStatus? status,
    int? floor,
    String? roomTypeId,
  }) async {}
}

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      await initDependencies();
    }
  });

  testWidgets('AdminTabScaffold renders 5 tabs and navigates correctly', (WidgetTester tester) async {
    final adminUser = UserModel(
      id: 'admin-1',
      email: 'admin@hotel.com',
      fullName: 'Quản trị viên',
      role: UserRole.admin,
    );

    final authBloc = FakeAuthBloc(adminUser);
    final router = AppRouter.createRouter(authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: HotelApp(router: router),
      ),
    );

    router.go('/admin');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify 5 tabs exist (FE-ROLE-MATRIX §4.1)
    expect(find.text('Tổng quan'), findsWidgets);
    expect(find.text('Báo cáo'), findsOneWidget);
    expect(find.text('Vận hành phòng'), findsOneWidget);
    expect(find.text('Nhân sự & DV'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    // Tap on 'Báo cáo' tab
    await tester.tap(find.text('Báo cáo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Báo Cáo'), findsWidgets);

    // Tap on 'Vận hành phòng' tab
    await tester.tap(find.text('Vận hành phòng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Vận Hành Phòng'), findsWidgets);

    // Tap on 'Nhân sự & DV' tab
    await tester.tap(find.text('Nhân sự & DV'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Nhân Sự & Dịch Vụ'), findsWidgets);
  });

  testWidgets('AdminTabScaffold displays badge when pending rooms exist on Vận hành phòng', (WidgetTester tester) async {
    if (sl.isRegistered<RoomRepository>()) {
      await sl.unregister<RoomRepository>();
    }
    sl.registerSingleton<RoomRepository>(MockRoomRepository([
      RoomModel(
        id: 'test-pending-1',
        roomNumber: '999',
        floor: 9,
        status: RoomStatus.pendingApproval,
        pricePerNight: 1500000,
      ),
      RoomModel(
        id: 'test-pending-2',
        roomNumber: '998',
        floor: 9,
        status: RoomStatus.pendingApproval,
        pricePerNight: 1500000,
      ),
    ]));

    final adminUser = UserModel(
      id: 'admin-1',
      email: 'admin@hotel.com',
      fullName: 'Quản trị viên',
      role: UserRole.admin,
    );

    final authBloc = FakeAuthBloc(adminUser);
    final router = AppRouter.createRouter(authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: HotelApp(router: router),
      ),
    );

    router.go('/admin');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify pending badge count '2' shows on 'Vận hành phòng' tab
    expect(find.text('2'), findsWidgets);
  });
}
