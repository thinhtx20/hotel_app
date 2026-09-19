import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/receptionist/screens/room_matrix_screen.dart';
import 'package:hotel_app/features/receptionist/widgets/check_out_sheet.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';

class MockPaymentDioClient implements DioClient {
  final List<String> requestedPaths = [];
  @override
  late final Dio dio;
  dynamic lastRequestBody;

  MockPaymentDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);
            lastRequestBody = options.data;

            if (options.path.contains('/checkout-preview')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'bookingId': 'bk_102',
                      'bookingCode': 'BK-02372998',
                      'roomNumber': '102',
                      'customerName': 'Nguyễn Văn A',
                      'roomAmount': 7150000,
                      'servicesAmount': 0,
                      'discount': 0,
                      'taxRate': 0.1,
                      'tax': 715000,
                      'finalAmount': 7865000,
                      'alreadyPaidAmount': 7150000,
                      'depositAmount': 7150000,
                      'amountDue': 715000,
                      'refundDue': 0,
                      'isEarlyCheckOut': false,
                      'pendingPaymentRequests': [],
                    },
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.rooms) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'id': '102',
                        'roomNumber': '102',
                        'floor': 1,
                        'status': 'OCCUPIED',
                        'pricePerNight': 650000,
                        'roomTypeName': 'Standard Queen Double',
                        'roomTypeCode': 'STD-D',
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
                    'data': [
                      {
                        'id': 'bk_102',
                        'bookingCode': 'BK-02372998',
                        'roomId': '102',
                        'roomNumber': '102',
                        'customer': {
                          'fullName': 'Nguyễn Văn A',
                          'phone': '0912345678',
                        },
                        'checkInDate': '2026-09-03T17:00:00.000Z',
                        'checkOutDate': '2026-09-14T17:00:00.000Z',
                        'guestCount': 3,
                        'totalAmount': 7150000,
                        'status': 'CHECKED_IN',
                      },
                    ],
                  },
                ),
              );
            }

            if (options.path.contains('/check-out')) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      'booking': {
                        'id': 'bk_102',
                        'roomId': '102',
                        'roomNumber': '102',
                        'status': 'CHECKED_OUT',
                      },
                      'invoice': {
                        'id': 'inv_102',
                        'finalAmount': 7865000,
                        'paidAmount': 7865000,
                        'remainingAmount': 0,
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
                data: {'success': true, 'data': {}},
              ),
            );
          },
        ),
      );
  }

  @override
  void setBaseUrl(String newUrl) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Check-out and Room Status Payment Validation Tests', () {
    testWidgets(
      'CheckOutSheet blocks submission when collected amount is less than amountDue',
      (tester) async {
        final mockDioClient = MockPaymentDioClient();
        final repo = BookingRepository(dioClient: mockDioClient);

        final booking = BookingModel.fromJson({
          'id': 'bk_102',
          'bookingCode': 'BK-02372998',
          'roomId': '102',
          'roomNumber': '102',
          'customerName': 'Nguyễn Văn A',
          'customerPhone': '0912345678',
          'checkInDate': '2026-09-03T17:00:00.000Z',
          'checkOutDate': '2026-09-14T17:00:00.000Z',
          'guestCount': 3,
          'totalAmount': 7150000,
          'status': 'CHECKED_IN',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: ctx,
                      builder: (_) => CheckOutSheet(
                        booking: booking,
                        bookingRepository: repo,
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        // Mở sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Sheet đã hiển thị CÒN PHẢI THU
        expect(find.text('CÒN PHẢI THU'), findsOneWidget);

        // Nhập số tiền thu nhỏ hơn số còn phải thu (ví dụ 500.000 < 715.000)
        final amountField = find.widgetWithText(TextField, 'Nhập số tiền thu tại quầy');
        expect(amountField, findsOneWidget);
        await tester.enterText(amountField, '500000');
        await tester.pump();

        // Bấm nút Xác nhận Trả phòng & Xuất Hóa đơn
        await tester.tap(find.text('Xác nhận Trả phòng & Xuất Hóa đơn'));
        await tester.pump();

        // Phải hiển thị thông báo lỗi yêu cầu thu đủ
        expect(
          find.textContaining('Vui lòng thu đủ số tiền còn lại'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CheckOutSheet correctly maps alreadyPaidAmount and pre-fills exact amountDue (715.000đ)',
      (tester) async {
        final mockDioClient = MockPaymentDioClient();
        final repo = BookingRepository(dioClient: mockDioClient);

        final booking = BookingModel.fromJson({
          'id': 'bk_102',
          'bookingCode': 'BK-02372998',
          'roomId': '102',
          'roomNumber': '102',
          'customerName': 'Nguyễn Văn A',
          'customerPhone': '0912345678',
          'checkInDate': '2026-09-03T17:00:00.000Z',
          'checkOutDate': '2026-09-14T17:00:00.000Z',
          'guestCount': 3,
          'totalAmount': 7150000,
          'status': 'CHECKED_IN',
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: ctx,
                      builder: (_) => CheckOutSheet(
                        booking: booking,
                        bookingRepository: repo,
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Kiểm tra hiển thị đã thu (7.150.000đ) và còn phải thu (715.000đ)
        expect(find.text('Đã thu (gồm tiền cọc)'), findsOneWidget);
        expect(find.text('CÒN PHẢI THU'), findsOneWidget);

        // Ô thu tại quầy tự động điền đúng số còn lại 715.000đ (không bị 7.865.000đ)
        final amountField = find.widgetWithText(TextField, 'Nhập số tiền thu tại quầy');
        expect(amountField, findsOneWidget);
        final textFieldWidget = tester.widget<TextField>(amountField);
        expect(textFieldWidget.controller?.text, '715.000');

        // Bấm nút Xác nhận Trả phòng & Xuất Hóa đơn
        await tester.tap(find.text('Xác nhận Trả phòng & Xuất Hóa đơn'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Kiểm tra request gửi đi có đúng amountCollected = 715000
        expect(mockDioClient.requestedPaths, contains(ApiEndpoints.checkOut('bk_102')));
        expect(mockDioClient.lastRequestBody['amountCollected'], 715000);
      },
    );

    testWidgets(
      'RoomMatrixScreen blocks changing status to Sẵn sàng when room is occupied',
      (tester) async {
        final mockDioClient = MockPaymentDioClient();

        await tester.pumpWidget(
          MaterialApp(
            home: RoomMatrixScreen(dioClient: mockDioClient),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Bấm vào ô phòng 102 để mở bottom sheet chi tiết
        await tester.tap(find.text('102'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Đã mở sheet chi tiết phòng 102
        expect(find.text('Thao tác nhanh 1 chạm:'), findsOneWidget);

        // Bấm vào nút "Sẵn sàng"
        await tester.tap(find.text('Sẵn sàng'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Hệ thống chặn lại và hiển thị cảnh báo
        expect(
          find.textContaining('Phòng 102 đang có khách lưu trú. Vui lòng kiểm tra thanh toán'),
          findsOneWidget,
        );
      },
    );
  });
}
