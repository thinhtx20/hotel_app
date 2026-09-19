import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/core/theme/app_theme.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_bloc.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_event.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_state.dart';
import 'package:hotel_app/features/receptionist/screens/room_matrix_screen.dart';
import 'package:hotel_app/features/receptionist/widgets/check_out_sheet.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/models/checkout_preview_model.dart';
import 'package:hotel_app/shared/models/invoice_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';

class _MockEarlyBookingRepository extends BookingRepository {
  final List<BookingModel> mockTodayCheckOuts;
  final List<BookingModel> mockActiveStays;
  final CheckoutPreviewModel? mockPreview;
  final (BookingModel, InvoiceModel)? mockCheckOutResult;

  bool checkOutCalled = false;
  bool? lastRecalculateRoomAmount;
  num? lastRefundAmount;
  String? lastRefundMethod;

  _MockEarlyBookingRepository({
    this.mockTodayCheckOuts = const [],
    this.mockActiveStays = const [],
    this.mockPreview,
    this.mockCheckOutResult,
  });

  @override
  Future<List<BookingModel>> fetchTodayCheckOuts() async => mockTodayCheckOuts;

  @override
  Future<List<BookingModel>> fetchActiveStays({int page = 1, int limit = 100, String? search}) async =>
      mockActiveStays;

  @override
  Future<CheckoutPreviewModel> fetchCheckOutPreview(String id) async {
    if (mockPreview != null) return mockPreview!;
    return super.fetchCheckOutPreview(id);
  }

  @override
  Future<(BookingModel, InvoiceModel)> checkOut(
    String id, {
    String paymentMethod = 'CASH',
    num? discount,
    num? taxRate,
    num? amountCollected,
    bool? recalculateRoomAmount,
    num? customRoomAmount,
    num? refundAmount,
    String? refundMethod,
    String? refundReason,
    String? note,
  }) async {
    checkOutCalled = true;
    lastRecalculateRoomAmount = recalculateRoomAmount;
    lastRefundAmount = refundAmount;
    lastRefundMethod = refundMethod;

    if (mockCheckOutResult != null) return mockCheckOutResult!;
    throw UnimplementedError();
  }
}

class _MockMatrixDioClient implements DioClient {
  @override
  late final Dio dio;

  @override
  void setBaseUrl(String newUrl) {}

  _MockMatrixDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == ApiEndpoints.rooms) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': 'room-101',
                        'roomNumber': '101',
                        'floor': 1,
                        'status': 'OCCUPIED',
                        'pricePerNight': 1000000,
                        'roomTypeName': 'Deluxe Double',
                      },
                    ],
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.bookings) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'data': [
                        {
                          'id': 'bk-early-01',
                          'bookingCode': 'BK-EARLY-01',
                          'roomId': 'room-101',
                          'roomNumber': '101',
                          'customerName': 'Nguyễn Văn A',
                          'customerPhone': '0901234567',
                          'checkInDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
                          'checkOutDate': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
                          'guestCount': 2,
                          'totalAmount': 4000000,
                          'depositAmount': 4000000,
                          'status': 'CHECKED_IN',
                        },
                      ],
                      'meta': {'total': 1, 'page': 1, 'limit': 20, 'totalPages': 1},
                    },
                  },
                ),
              );
            }

            if (options.path.contains('/checkout-preview') || options.path.contains('/check-out')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'booking': {
                        'id': 'bk-early-01',
                        'bookingCode': 'BK-EARLY-01',
                        'roomId': 'room-101',
                        'roomNumber': '101',
                        'status': 'CHECKED_OUT',
                      },
                      'invoice': {
                        'id': 'inv-01',
                        'invoiceCode': 'INV-01',
                        'roomAmount': 1000000,
                        'servicesAmount': 0,
                        'discount': 0,
                        'tax': 100000,
                        'finalAmount': 1100000,
                        'paidAmount': 4000000,
                        'paymentStatus': 'PAID',
                      },
                    },
                  },
                ),
              );
            }

            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'success': true},
              ),
            );
          },
        ),
      );
  }
}

void main() {
  group('Early Check-Out Feature Tests', () {
    test('TodayCheckOutsBloc fetches active stays when scope changes to allActiveStays', () async {
      final sampleActiveStay = BookingModel(
        id: 'bk-act-1',
        roomId: 'r-101',
        bookingCode: 'BK-ACT-1',
        customerName: 'Hoàng Long',
        roomNumber: '101',
        checkInDate: DateTime.now().subtract(const Duration(days: 1)),
        checkOutDate: DateTime.now().add(const Duration(days: 3)),
        guestCount: 2,
        totalAmount: 4000000,
        status: 'CHECKED_IN',
      );

      final repo = _MockEarlyBookingRepository(
        mockTodayCheckOuts: [],
        mockActiveStays: [sampleActiveStay],
      );
      final bloc = TodayCheckOutsBloc(bookingRepository: repo);

      bloc.add(const TodayCheckOutsScopeChanged(TodayCheckOutScope.allActiveStays));
      await bloc.stream.firstWhere((s) => s.status == TodayCheckOutsStatus.success);

      expect(bloc.state.scope, TodayCheckOutScope.allActiveStays);
      expect(bloc.state.bookings.length, 1);
      expect(bloc.state.bookings.first.bookingCode, 'BK-ACT-1');
      await bloc.close();
    });

    testWidgets('CheckOutSheet renders early check-out banner, recalculation toggle, and refund flow', (tester) async {
      final now = DateTime.now();
      final checkInDate = now.subtract(const Duration(days: 1));
      final checkOutDate = now.add(const Duration(days: 3)); // Đặt 4 đêm, đã ở 1 đêm

      final earlyBooking = BookingModel(
        id: 'bk-early-101',
        roomId: 'r-101',
        roomNumber: '101',
        bookingCode: 'BK-EARLY-101',
        customerName: 'Trịnh Thăng Bình',
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        guestCount: 2,
        totalAmount: 4000000,
        depositAmount: 4400000,
        status: 'CHECKED_IN',
      );

      final preview = CheckoutPreviewModel(
        bookingId: 'bk-early-101',
        bookingCode: 'BK-EARLY-101',
        roomNumber: '101',
        customerName: 'Trịnh Thăng Bình',
        roomAmount: 4000000,
        servicesAmount: 0,
        discount: 0,
        tax: 110000,
        finalAmount: 1210000, // Tiền phòng 1 đêm + VAT
        paidAmount: 4400000,  // Đã trả đủ 4 đêm ban đầu
        amountDue: 0,
        refundDue: 3190000,   // Hoàn trả số dư
        isEarlyCheckOut: true,
        bookedNights: 4,
        actualNights: 1,
        basePrice: 1000000,
        originalRoomAmount: 4000000,
        recalculatedRoomAmount: 1000000,
        pendingPaymentRequests: const [],
      );

      final mockInvoice = InvoiceModel(
        id: 'inv-early-101',
        bookingId: 'bk-early-101',
        invoiceCode: 'INV-EARLY-101',
        roomAmount: 1000000,
        servicesAmount: 0,
        discount: 0,
        tax: 110000,
        finalAmount: 1210000,
        paidAmount: 4400000,
        paymentStatus: 'PAID',
      );

      final repo = _MockEarlyBookingRepository(
        mockPreview: preview,
        mockCheckOutResult: (earlyBooking, mockInvoice),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => CheckOutSheet.show(
                  context: ctx,
                  booking: earlyBooking,
                  bookingRepository: repo,
                ),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Mở Sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Kiểm tra banner Trả phòng trước hạn
      expect(find.text('TRẢ PHÒNG TRƯỚC HẠN'), findsOneWidget);
      expect(find.text('Lưu trú: 1 / 4 đêm'), findsOneWidget);
      expect(find.text('Tính lại tiền phòng theo số đêm thực tế'), findsOneWidget);

      // Kiểm tra mục Hoàn trả khách (do đã thu 4.4M > 1.21M)
      expect(find.text('CẦN HOÀN TRẢ KHÁCH'), findsOneWidget);
      expect(find.text('Hình thức hoàn tiền:'), findsOneWidget);
      expect(find.text('Xác nhận Trả phòng & Hoàn tiền'), findsOneWidget);

      // Nhấn nút Trả phòng & Hoàn tiền
      await tester.tap(find.text('Xác nhận Trả phòng & Hoàn tiền'));
      await tester.pumpAndSettle();

      expect(repo.checkOutCalled, isTrue);
      expect(repo.lastRecalculateRoomAmount, isTrue);
      expect(repo.lastRefundAmount, greaterThan(0));

      // Hộp thoại xuất hóa đơn thành công và hiện dòng đã hoàn trả khách
      expect(find.text('Hóa đơn đã xuất thành công'), findsOneWidget);
      expect(find.textContaining('Đã hoàn trả khách:'), findsOneWidget);
    });

    testWidgets('RoomMatrixScreen warning SnackBar offers "Trả phòng ngay" on occupied room', (tester) async {
      final mockDioClient = _MockMatrixDioClient();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RoomMatrixScreen(
            dioClient: mockDioClient,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở bottom sheet của phòng 101 (đang OCCUPIED)
      await tester.tap(find.text('101'));
      await tester.pumpAndSettle();

      expect(find.text('Khách đang lưu trú'), findsOneWidget);
      // Badge trả phòng sớm nếu ngày trả phòng ở tương lai
      expect(find.text('Trả phòng sớm'), findsOneWidget);

      // Thử bấm đổi trạng thái sang "Sẵn sàng"
      await tester.tap(find.text('Sẵn sàng'));
      await tester.pumpAndSettle();

      // Hiện SnackBar cảnh báo có nút Trả phòng ngay
      expect(find.textContaining('đang có khách lưu trú'), findsOneWidget);
      expect(find.text('Trả phòng ngay'), findsOneWidget);

      // Bấm nút "Trả phòng ngay" trên SnackBar
      await tester.tap(find.text('Trả phòng ngay'));
      await tester.pumpAndSettle();

      // Sheet trả phòng mở ra
      expect(find.text('Thủ tục Trả phòng & Xuất Hóa đơn'), findsOneWidget);
    });
  });
}
