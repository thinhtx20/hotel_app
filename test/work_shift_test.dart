import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/theme/app_theme.dart';
import 'package:hotel_app/di/injection_container.dart' as di;
import 'package:hotel_app/features/admin/screens/shift_detail_screen.dart';
import 'package:hotel_app/shared/models/work_shift_model.dart';
import 'package:hotel_app/shared/repositories/shift_repository.dart';

void main() {
  setUpAll(() async {
    // Đảm bảo GetIt được khởi tạo nếu chưa
    if (!di.sl.isRegistered<ShiftRepository>()) {
      await di.initDependencies();
    }
  });

  group('WorkShiftModel & Enums Tests', () {
    test('ShiftType & ShiftStatus string parsing', () {
      expect(ShiftType.fromString('MORNING'), ShiftType.morning);
      expect(ShiftType.fromString('AFTERNOON'), ShiftType.afternoon);
      expect(ShiftType.fromString('NIGHT'), ShiftType.night);
      expect(ShiftType.fromString('CUSTOM'), ShiftType.custom);
      expect(ShiftType.fromString('unknown'), ShiftType.morning);

      expect(ShiftStatus.fromString('OPEN'), ShiftStatus.open);
      expect(ShiftStatus.fromString('CLOSED'), ShiftStatus.closed);
      expect(ShiftStatus.fromString(null), ShiftStatus.open);
    });

    test('WorkShiftModel json serialization and calculations', () {
      final json = {
        'id': 'shift-123',
        'shiftCode': 'SFT-20260907-001',
        'staffId': 'user-1',
        'staffName': 'Nguyễn Văn A',
        'staffPhone': '0901234567',
        'shiftType': 'MORNING',
        'deskName': 'Quầy 1',
        'status': 'OPEN',
        'startTime': '2026-09-07T07:00:00.000Z',
        'initialCash': 2000000,
        'stats': {
          'initialCash': 2000000,
          'cashCollected': 1500000,
          'cashRefunded': 200000,
          'netCashChange': 1300000,
          'expectedCash': 3300000,
          'creditCardAmount': 500000,
          'bankTransferAmount': 800000,
          'totalRevenue': 2600000,
          'paymentCount': 3,
          'refundCount': 1,
        },
        'payments': [
          {
            'id': 'pay-1',
            'amount': 1500000,
            'method': 'CASH',
            'type': 'PAYMENT',
            'status': 'CONFIRMED',
            'invoice': {
              'invoiceCode': 'INV-001',
              'booking': {
                'bookingCode': 'BK-001',
                'room': {'roomNumber': '101'},
                'customer': {'fullName': 'Trần Thị B'},
              },
            },
          },
        ],
      };

      final shift = WorkShiftModel.fromJson(json);

      expect(shift.id, 'shift-123');
      expect(shift.shiftCode, 'SFT-20260907-001');
      expect(shift.staffName, 'Nguyễn Văn A');
      expect(shift.isOpen, isTrue);
      expect(shift.isClosed, isFalse);
      expect(shift.initialCash, 2000000);
      expect(shift.currentExpectedCash, 3300000);
      expect(shift.effectiveRevenue, 2600000);
      expect(shift.hasDifference, isFalse);
      expect(shift.payments.length, 1);
      expect(shift.payments.first.invoiceCode, 'INV-001');
      expect(shift.payments.first.roomNumber, '101');
      expect(shift.payments.first.customerName, 'Trần Thị B');
    });

    test('WorkShiftModel cash difference detection', () {
      final balancedShift = WorkShiftModel(
        id: 's-1',
        shiftCode: 'SFT-001',
        staffId: 'u-1',
        staffName: 'Staff',
        shiftType: ShiftType.morning,
        deskName: 'Quầy 1',
        status: ShiftStatus.closed,
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        endTime: DateTime.now(),
        initialCash: 1000000,
        expectedCash: 3000000,
        actualCash: 3000000,
        cashDifference: 0,
      );
      expect(balancedShift.hasDifference, isFalse);
      expect(balancedShift.isOverCash, isFalse);
      expect(balancedShift.isShortCash, isFalse);

      final overShift = WorkShiftModel(
        id: 's-2',
        shiftCode: 'SFT-002',
        staffId: 'u-1',
        staffName: 'Staff',
        shiftType: ShiftType.afternoon,
        deskName: 'Quầy 2',
        status: ShiftStatus.closed,
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        endTime: DateTime.now(),
        initialCash: 1000000,
        expectedCash: 3000000,
        actualCash: 3050000,
        cashDifference: 50000,
        differenceReason: 'Khách tip không lấy thối',
      );
      expect(overShift.hasDifference, isTrue);
      expect(overShift.isOverCash, isTrue);
      expect(overShift.isShortCash, isFalse);

      final shortShift = WorkShiftModel(
        id: 's-3',
        shiftCode: 'SFT-003',
        staffId: 'u-1',
        staffName: 'Staff',
        shiftType: ShiftType.night,
        deskName: 'Quầy 1',
        status: ShiftStatus.closed,
        startTime: DateTime.now().subtract(const Duration(hours: 8)),
        endTime: DateTime.now(),
        initialCash: 1000000,
        expectedCash: 3000000,
        actualCash: 2900000,
        cashDifference: -100000,
        differenceReason: 'Thối nhầm tiền khách lẻ',
      );
      expect(shortShift.hasDifference, isTrue);
      expect(shortShift.isOverCash, isFalse);
      expect(shortShift.isShortCash, isTrue);
    });

    test('ApiEndpoints constants for shifts are defined correctly', () {
      expect(ApiEndpoints.shiftsOpen, '/shifts/open');
      expect(ApiEndpoints.shiftsCurrent, '/shifts/current');
      expect(ApiEndpoints.shiftsActive, '/shifts/active');
      expect(ApiEndpoints.shiftsClose, '/shifts/close');
      expect(ApiEndpoints.adminCloseShift('123'), '/shifts/123/close');
      expect(ApiEndpoints.shifts, '/shifts');
      expect(ApiEndpoints.shiftDetail('456'), '/shifts/456');
    });
  });

  group('ShiftDetailScreen Widget Tests', () {
    testWidgets('Renders ShiftDetailScreen with shift data and cash balancing', (tester) async {
      final sampleShift = WorkShiftModel(
        id: 'shift-999',
        shiftCode: 'SFT-20260907-999',
        staffId: 'u-1',
        staffName: 'Lê Văn C',
        staffPhone: '0988777666',
        shiftType: ShiftType.morning,
        deskName: 'Quầy Tiếp Tân 1',
        status: ShiftStatus.closed,
        startTime: DateTime(2026, 9, 7, 7, 0),
        endTime: DateTime(2026, 9, 7, 15, 0),
        initialCash: 2000000,
        expectedCash: 5000000,
        actualCash: 5000000,
        cashDifference: 0,
        creditCardAmount: 1200000,
        bankTransferAmount: 1500000,
        totalRevenue: 5700000,
        closeNote: 'Bàn giao ca đầy đủ biên lai',
        handoverStaffName: 'Phạm Thị D',
        stats: const ShiftStatsModel(
          initialCash: 2000000,
          cashCollected: 3000000,
          cashRefunded: 0,
          netCashChange: 3000000,
          expectedCash: 5000000,
          creditCardAmount: 1200000,
          bankTransferAmount: 1500000,
          totalRevenue: 5700000,
          paymentCount: 5,
        ),
        payments: const [
          ShiftPaymentItemModel(
            id: 'pay-1',
            amount: 2500000,
            method: 'CASH',
            type: 'PAYMENT',
            status: 'CONFIRMED',
            invoiceCode: 'HD-20260907-001',
            roomNumber: '202',
            customerName: 'Hoàng Minh',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ShiftDetailScreen(
            shiftId: 'shift-999',
            initialShift: sampleShift,
          ),
        ),
      );

      await tester.pump();

      // Verify Header
      expect(find.text('SFT-20260907-999'), findsOneWidget);
      expect(find.text('Lê Văn C'), findsOneWidget);
      expect(find.text('ĐÃ CHỐT CA'), findsOneWidget);
      expect(find.textContaining('Bàn giao ca cho:'), findsOneWidget);
      expect(find.text('Phạm Thị D'), findsOneWidget);

      // Verify Cash balancing
      expect(find.text('Đối Soát Tiền Mặt Trong Két'), findsOneWidget);
      expect(find.text('Khớp tiền chính xác 100% (Không có sai lệch)'), findsOneWidget);

      // Verify Payments
      expect(find.text('HD-20260907-001'), findsOneWidget);
      expect(find.text('P.202'), findsOneWidget);
      expect(find.textContaining('Hoàng Minh'), findsOneWidget);
    });
  });
}
