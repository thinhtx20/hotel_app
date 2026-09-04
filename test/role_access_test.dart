import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/constants/role_permissions.dart';
import 'package:hotel_app/core/router/app_router.dart';
import 'package:hotel_app/di/injection_container.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/main.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/repositories/room_repository.dart';

class FakeAuthBloc extends AuthBloc {
  FakeAuthBloc(UserModel user) : super() {
    emit(AuthAuthenticated(user));
  }
}

UserModel _userFor(UserRole role) => UserModel(
      id: '${role.value}-1',
      email: '${role.value.toLowerCase()}@hotel.com',
      fullName: role.label,
      role: role,
    );

void main() {
  setUpAll(() async {
    if (!sl.isRegistered<RoomRepository>()) {
      await initDependencies();
    }
  });

  /// Điều hướng tới [target] với tài khoản [role] rồi trả về địa chỉ thực tế
  /// sau khi guard trong [AppRouter] chạy xong.
  Future<String> locationAfterGo(
    WidgetTester tester,
    UserRole role,
    String target,
  ) async {
    final authBloc = FakeAuthBloc(_userFor(role));
    final router = AppRouter.createRouter(authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<AuthBloc>.value(value: authBloc)],
        child: HotelApp(router: router),
      ),
    );

    router.go(target);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    return router.routerDelegate.currentConfiguration.uri.path;
  }

  group('Guard phân quyền route', () {
    testWidgets('mỗi vai trò vào được màn chính của chính mình', (tester) async {
      for (final role in UserRole.values) {
        expect(
          await locationAfterGo(tester, role, role.homeRoute),
          role.homeRoute,
          reason: '${role.value} phải vào được ${role.homeRoute}',
        );
      }
    });

    testWidgets('khách hàng không vào được khu vực nhân viên', (tester) async {
      for (final blocked in [
        '/admin',
        '/receptionist',
        '/cashier',
        '/room-approval',
        '/staff/today-check-ins',
      ]) {
        expect(
          await locationAfterGo(tester, UserRole.customer, blocked),
          '/customer',
          reason: 'CUSTOMER gõ $blocked phải bị đẩy về /customer',
        );
      }
    });

    testWidgets('nhân viên không vào được app khách hàng', (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/my-bookings'),
        '/receptionist',
      );
      expect(
        await locationAfterGo(tester, UserRole.cashier, '/my-invoices'),
        '/cashier',
      );
    });

    testWidgets('không vai trò nhân viên nào lấn sân nhau', (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.cashier, '/admin'),
        '/cashier',
      );
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/admin/invoices'),
        '/receptionist',
      );
      expect(
        await locationAfterGo(tester, UserRole.admin, '/cashier/dashboard'),
        '/admin',
      );
    });

    testWidgets(
        'thu ngân bị chặn ở màn lấp đầy và duyệt đơn, vẫn vào được trả phòng',
        (tester) async {
      // GET /analytics/occupancy/detail — [ADMIN, RECEPTIONIST]
      expect(
        await locationAfterGo(
            tester, UserRole.cashier, '/staff/occupancy-detail'),
        '/cashier',
      );
      expect(
        await locationAfterGo(
            tester, UserRole.cashier, '/staff/pending-bookings'),
        '/cashier',
      );
      // POST /bookings/:id/check-out — cả ba vai trò nhân viên
      expect(
        await locationAfterGo(
            tester, UserRole.cashier, '/staff/today-check-outs'),
        '/staff/today-check-outs',
      );
    });

    testWidgets('lễ tân vào được duyệt phòng, thu ngân thì không',
        (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/room-approval'),
        '/room-approval',
      );
      expect(
        await locationAfterGo(tester, UserRole.cashier, '/room-approval'),
        '/cashier',
      );
    });

    testWidgets('đã đăng nhập thì không quay lại màn đăng nhập được',
        (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.customer, '/login'),
        '/customer',
      );
      expect(
        await locationAfterGo(tester, UserRole.admin, '/register'),
        '/admin',
      );
    });
  });

  group('Bảng quyền theo vai trò', () {
    test('POST /invoices — lễ tân bị 403, admin và thu ngân thì không', () {
      expect(UserRole.receptionist.canCreateInvoice, isFalse);
      expect(UserRole.admin.canCreateInvoice, isTrue);
      expect(UserRole.cashier.canCreateInvoice, isTrue);
      expect(UserRole.customer.canCreateInvoice, isFalse);
    });

    test('POST /invoices/:id/pay — cả ba vai trò nhân viên đều được', () {
      expect(UserRole.receptionist.canPayInvoice, isTrue);
      expect(UserRole.cashier.canPayInvoice, isTrue);
      expect(UserRole.admin.canPayInvoice, isTrue);
      expect(UserRole.customer.canPayInvoice, isFalse);
    });

    test('check-in chỉ ADMIN + RECEPTIONIST, check-out thì cả thu ngân', () {
      expect(UserRole.cashier.canCheckIn, isFalse);
      expect(UserRole.cashier.canCheckOut, isTrue);
      expect(UserRole.receptionist.canCheckIn, isTrue);
      expect(UserRole.customer.canCheckOut, isFalse);
    });

    test('doanh thu năm chỉ ADMIN, tổng quan thì cả ba vai trò nhân viên', () {
      expect(UserRole.admin.canViewYearlyRevenue, isTrue);
      expect(UserRole.receptionist.canViewYearlyRevenue, isFalse);
      expect(UserRole.cashier.canViewYearlyRevenue, isFalse);

      expect(UserRole.cashier.canViewDashboard, isTrue);
      expect(UserRole.customer.canViewDashboard, isFalse);
    });

    test('sửa phòng chỉ ADMIN, đổi trạng thái thì thêm lễ tân', () {
      expect(UserRole.receptionist.canEditRoom, isFalse);
      expect(UserRole.receptionist.canChangeRoomStatus, isTrue);
      expect(UserRole.cashier.canChangeRoomStatus, isFalse);
    });

    test('sửa tài khoản chỉ ADMIN, lễ tân chỉ xem', () {
      expect(UserRole.receptionist.canViewUsers, isTrue);
      expect(UserRole.receptionist.canManageUsers, isFalse);
      expect(UserRole.cashier.canViewUsers, isFalse);
    });
  });
}
