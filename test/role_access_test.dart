import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/core/constants/role_permissions.dart';
import 'package:hotel_app/core/network/api_error.dart';
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

  group('Guard phân quyền route (3 vai trò sau gộp)', () {
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
        await locationAfterGo(tester, UserRole.admin, '/my-invoices'),
        '/admin',
      );
    });

    testWidgets('lễ tân không lấn sang route riêng của admin', (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/admin/invoices'),
        '/receptionist',
      );
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/admin/reports'),
        '/receptionist',
      );
      expect(
        await locationAfterGo(tester, UserRole.admin, '/receptionist'),
        '/admin',
      );
    });

    testWidgets('Legacy cashier URLs tự động redirect sang receptionist', (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/cashier'),
        '/receptionist/invoices',
      );
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/cashier/check-outs'),
        '/receptionist/today',
      );
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/cashier/invoices'),
        '/receptionist/invoices',
      );
      expect(
        await locationAfterGo(tester, UserRole.admin, '/cashier/dashboard'),
        '/admin',
      );
    });

    testWidgets(
        'lễ tân và admin đều vào được các route vận hành chung',
        (tester) async {
      expect(
        await locationAfterGo(
            tester, UserRole.receptionist, '/staff/occupancy-detail'),
        '/staff/occupancy-detail',
      );
      expect(
        await locationAfterGo(
            tester, UserRole.receptionist, '/staff/pending-bookings'),
        '/staff/pending-bookings',
      );
      expect(
        await locationAfterGo(
            tester, UserRole.receptionist, '/staff/today-check-outs'),
        '/staff/today-check-outs',
      );
      expect(
        await locationAfterGo(
            tester, UserRole.admin, '/room-approval'),
        '/room-approval',
      );
      expect(
        await locationAfterGo(
            tester, UserRole.receptionist, '/room-approval'),
        '/room-approval',
      );
    });

    testWidgets(
        'lễ tân và admin vào được /staff/users, khách thì không',
        (tester) async {
      expect(
        await locationAfterGo(tester, UserRole.admin, '/staff/users'),
        '/staff/users',
      );
      expect(
        await locationAfterGo(tester, UserRole.receptionist, '/staff/users'),
        '/staff/users',
      );
      expect(
        await locationAfterGo(tester, UserRole.customer, '/staff/users'),
        '/customer',
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

  group('Bảng quyền theo vai trò (FE-ROLE-MATRIX §2.2)', () {
    test('POST /invoices — mở cho cả nhân viên lễ tân-thu ngân và admin', () {
      expect(UserRole.receptionist.canCreateInvoice, isTrue);
      expect(UserRole.admin.canCreateInvoice, isTrue);
      expect(UserRole.customer.canCreateInvoice, isFalse);
    });

    test('POST /invoices/:id/pay — cả hai vai trò nhân viên đều được', () {
      expect(UserRole.receptionist.canPayInvoice, isTrue);
      expect(UserRole.admin.canPayInvoice, isTrue);
      expect(UserRole.customer.canPayInvoice, isFalse);
    });

    test('check-in và check-out — nhân viên đều được phép', () {
      expect(UserRole.receptionist.canCheckIn, isTrue);
      expect(UserRole.receptionist.canCheckOut, isTrue);
      expect(UserRole.admin.canCheckIn, isTrue);
      expect(UserRole.admin.canCheckOut, isTrue);
      expect(UserRole.customer.canCheckIn, isFalse);
      expect(UserRole.customer.canCheckOut, isFalse);
    });

    test('doanh thu năm và dashboard phân theo vai trò', () {
      expect(UserRole.admin.canViewYearlyRevenue, isTrue);
      expect(UserRole.receptionist.canViewYearlyRevenue, isFalse);
      expect(UserRole.customer.canViewYearlyRevenue, isFalse);

      expect(UserRole.admin.canViewDashboard, isTrue);
      expect(UserRole.customer.canViewDashboard, isFalse);
    });

    test('sửa phòng chỉ ADMIN, đổi trạng thái thì thêm lễ tân', () {
      expect(UserRole.admin.canEditRoom, isTrue);
      expect(UserRole.receptionist.canEditRoom, isFalse);
      expect(UserRole.receptionist.canChangeRoomStatus, isTrue);
    });

    test('sửa tài khoản chỉ ADMIN, lễ tân chỉ xem', () {
      expect(UserRole.admin.canManageUsers, isTrue);
      expect(UserRole.receptionist.canViewUsers, isTrue);
      expect(UserRole.receptionist.canManageUsers, isFalse);
    });

    test('ghi dịch vụ mở cho nhân viên', () {
      expect(UserRole.admin.canAddBookingServices, isTrue);
      expect(UserRole.receptionist.canAddBookingServices, isTrue);
      expect(UserRole.customer.canAddBookingServices, isFalse);
    });

    test('quản lý hạng phòng chỉ dành riêng cho ADMIN', () {
      expect(UserRole.admin.canManageRoomTypes, isTrue);
      expect(UserRole.receptionist.canManageRoomTypes, isFalse);
      expect(UserRole.customer.canManageRoomTypes, isFalse);
    });

    test('xem công suất occupancy mở cho nhân viên', () {
      expect(UserRole.admin.canViewOccupancy, isTrue);
      expect(UserRole.receptionist.canViewOccupancy, isTrue);
      expect(UserRole.customer.canViewOccupancy, isFalse);
    });

    test('quyền tính năng mới P1 (S1, S2, S4, A1, A2, C1)', () {
      expect(UserRole.receptionist.canRefundInvoice, isTrue);
      expect(UserRole.admin.canRefundInvoice, isTrue);
      expect(UserRole.customer.canRefundInvoice, isFalse);

      expect(UserRole.receptionist.canChangeRoom, isTrue);
      expect(UserRole.admin.canChangeRoom, isTrue);
      expect(UserRole.customer.canChangeRoom, isFalse);

      expect(UserRole.receptionist.canCloseShift, isTrue);
      expect(UserRole.admin.canCloseShift, isTrue);
      expect(UserRole.customer.canCloseShift, isFalse);

      expect(UserRole.admin.canManageServiceCatalog, isTrue);
      expect(UserRole.receptionist.canManageServiceCatalog, isFalse);

      expect(UserRole.admin.canViewStaffPerformance, isTrue);
      expect(UserRole.receptionist.canViewStaffPerformance, isFalse);

      expect(UserRole.customer.canRequestService, isTrue);
      expect(UserRole.receptionist.canRequestService, isFalse);
    });
  });

  group('ApiError xử lý 403 thân thiện theo FE-ROLE-MATRIX §2', () {
    test('che giấu thông tin vai trò nội bộ từ backend', () {
      final err = ApiError(
        statusCode: 403,
        message: 'Quyền truy cập bị từ chối: Yêu cầu vai trò [ADMIN, RECEPTIONIST]',
      );
      expect(err.displayMessage, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('giữ nguyên thông báo kiểm tra chủ sở hữu đơn đặt phòng / hóa đơn', () {
      final errBooking = ApiError(
        statusCode: 403,
        message: 'Bạn chỉ có thể xem và thao tác trên đơn đặt phòng của chính mình',
      );
      expect(errBooking.displayMessage,
          'Bạn chỉ có thể xem và thao tác trên đơn đặt phòng của chính mình');

      final errInvoice = ApiError(
        statusCode: 403,
        message: 'Bạn chỉ có thể xem hóa đơn của chính mình',
      );
      expect(errInvoice.displayMessage, 'Bạn chỉ có thể xem hóa đơn của chính mình');
    });
  });
}
