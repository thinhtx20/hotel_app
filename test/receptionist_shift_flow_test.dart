import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_result.dart';
import 'package:hotel_app/core/theme/app_theme.dart';
import 'package:hotel_app/core/utils/formatters.dart';
import 'package:hotel_app/di/injection_container.dart' as di;
import 'package:hotel_app/features/receptionist/widgets/close_shift_sheet.dart';
import 'package:hotel_app/features/receptionist/widgets/open_shift_sheet.dart';
import 'package:hotel_app/features/receptionist/widgets/receptionist_shift_banner.dart';
import 'package:hotel_app/shared/models/user_model.dart';
import 'package:hotel_app/shared/models/work_shift_model.dart';
import 'package:hotel_app/shared/repositories/shift_repository.dart';
import 'package:hotel_app/shared/repositories/user_repository.dart';

class FakeEmptyShiftRepository extends ShiftRepository {
  @override
  Future<WorkShiftModel?> getCurrentShift() async => null;
}

class FakeActiveShiftRepository extends ShiftRepository {
  final WorkShiftModel shift;
  FakeActiveShiftRepository(this.shift);

  @override
  Future<WorkShiftModel?> getCurrentShift() async => shift;
}

class FakeUserRepository extends UserRepository {
  @override
  Future<PaginatedResult<UserModel>> fetchUsersPage({
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    return const PaginatedResult<UserModel>(
      items: [],
      meta: PageMeta(
        total: 0,
        page: 1,
        limit: 50,
        totalPages: 1,
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!di.sl.isRegistered<ShiftRepository>()) {
      await di.initDependencies();
    }
  });

  final sampleActiveShift = WorkShiftModel(
    id: 'sft-test-1',
    shiftCode: 'SFT-20260907-001',
    staffId: 'staff-1',
    staffName: 'Lê Tân Lan',
    shiftType: ShiftType.morning,
    deskName: 'Quầy Lễ Tân 1',
    status: ShiftStatus.open,
    startTime: DateTime(2026, 9, 7, 7, 0),
    initialCash: 2000000,
    stats: const ShiftStatsModel(
      initialCash: 2000000,
      cashCollected: 850000,
      cashRefunded: 0,
      netCashChange: 850000,
      expectedCash: 2850000,
      creditCardAmount: 500000,
      bankTransferAmount: 1200000,
      totalRevenue: 2550000,
      paymentCount: 3,
    ),
  );

  group('ReceptionistShiftBanner Widget Tests', () {
    testWidgets('Renders empty/unopened banner when no shift is open', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ReceptionistShiftBanner(
              shiftRepository: FakeEmptyShiftRepository(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bạn chưa vào ca trực quầy hôm nay'), findsOneWidget);
      expect(find.text('Nhận Ca'), findsOneWidget);
    });

    testWidgets('Renders active shift banner with realtime cash drawer info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ReceptionistShiftBanner(
              shiftRepository: FakeActiveShiftRepository(sampleActiveShift),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('ĐANG TRỰC: CA SÁNG'), findsOneWidget);
      expect(find.text('Quầy Lễ Tân 1'), findsOneWidget);
      expect(find.text('Chốt ca & Giao két'), findsOneWidget);
      expect(find.text('SFT-20260907-001'), findsOneWidget);
      expect(find.text(Formatters.formatCurrency(2850000)), findsOneWidget);
    });
  });

  group('OpenShiftSheet & CloseShiftSheet Widget Tests', () {
    testWidgets('Renders OpenShiftSheet with shift options and quick cash chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: OpenShiftSheet(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Nhận Ca Trực & Bàn Giao Két'), findsOneWidget);
      expect(find.text('Loại ca trực (*)'), findsOneWidget);
      expect(find.text('Tiền mặt nhận bàn giao két (*)'), findsOneWidget);
      expect(find.text('2.000.000 đ'), findsOneWidget);
      expect(find.text('3.000.000 đ'), findsOneWidget);
      expect(find.text('5.000.000 đ'), findsOneWidget);
      expect(find.text('Xác Nhận Bắt Đầu Ca Trực'), findsOneWidget);
    });

    testWidgets('Renders CloseShiftSheet with realtime balancing card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CloseShiftSheet(
              currentShift: sampleActiveShift,
              userRepository: FakeUserRepository(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chốt Ca & Bàn Giao Két'), findsOneWidget);
      expect(find.text('Mã ca: SFT-20260907-001 • Quầy Lễ Tân 1'), findsOneWidget);
      expect(find.text('Tiền két lý thuyết (Sổ sách):'), findsOneWidget);
      expect(find.text('Khớp với sổ sách'), findsOneWidget);
      expect(find.text('Số tiền thực tế khớp 100% với sổ sách két!'), findsOneWidget);
      expect(find.text('Xác Nhận Chốt Ca & Bàn Giao'), findsOneWidget);
    });
  });
}
