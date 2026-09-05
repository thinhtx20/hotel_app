import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_endpoints.dart';
import 'package:hotel_app/core/network/dio_client.dart';
import 'package:hotel_app/features/admin/screens/reports_screen.dart';
import 'package:hotel_app/shared/repositories/analytics_repository.dart';

class MockReportsDioClient implements DioClient {
  final List<String> requestedPaths = [];
  Map<String, dynamic>? revenueResponse;
  dynamic availableYearsResponse;
  bool throw404ForYears = false;

  @override
  late final Dio dio;

  MockReportsDioClient() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedPaths.add(options.path);

            if (options.path == ApiEndpoints.analyticsRevenue) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: revenueResponse ??
                      {
                        'success': true,
                        'data': {
                          'year': options.queryParameters['year'] ?? 2026,
                          'availableYears': [2024, 2025, 2026],
                          'summary': {
                            'totalYearRevenue': 52092000,
                            'totalRoomRevenue': 46600000,
                            'totalServicesRevenue': 3470000,
                            'totalInvoices': 9,
                          },
                          'monthly': List.generate(12, (index) {
                            final m = index + 1;
                            return {
                              'month': m,
                              'totalRevenue': m == 9 ? 50508000 : (m == 8 ? 1584000 : 0),
                              'roomRevenue': m == 9 ? 45250000 : 0,
                              'serviceRevenue': m == 9 ? 3330000 : 0,
                              'invoiceCount': m == 9 ? 8 : 0,
                            };
                          }),
                        },
                      },
                ),
              );
            }

            if (options.path == ApiEndpoints.analyticsRevenueYears) {
              if (throw404ForYears) {
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 404,
                      data: {'message': 'Not Found'},
                    ),
                  ),
                );
              }
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: availableYearsResponse ?? {
                    'success': true,
                    'data': [2023, 2024, 2025, 2026],
                  },
                ),
              );
            }

            if (options.path == ApiEndpoints.staffPerformance) {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': [
                      {
                        'staffName': 'Nguyễn Văn Test',
                        'confirmedBookings': 10,
                        'cancelledBookings': 1,
                        'invoicesIssued': 8,
                        'amountCollected': 45000000,
                      }
                    ],
                  },
                ),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Unhandled path: ${options.path}',
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
  group('AnalyticsRepository.revenueAvailableYears', () {
    test('trả về danh sách năm khi endpoint trả về [2023, 2024, 2025, 2026]', () async {
      final mock = MockReportsDioClient();
      final repo = AnalyticsRepository(dioClient: mock);

      final years = await repo.revenueAvailableYears();
      expect(years, [2023, 2024, 2025, 2026]);
      expect(mock.requestedPaths, contains(ApiEndpoints.analyticsRevenueYears));
    });

    test('trả về [] an toàn khi endpoint trả về 404 Not Found', () async {
      final mock = MockReportsDioClient()..throw404ForYears = true;
      final repo = AnalyticsRepository(dioClient: mock);

      final years = await repo.revenueAvailableYears();
      expect(years, isEmpty);
    });
  });

  group('ReportsScreen widget', () {
    testWidgets('hiển thị danh sách năm từ availableYears trong API và doanh thu thật', (tester) async {
      final mock = MockReportsDioClient();
      final repo = AnalyticsRepository(dioClient: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: ReportsScreen(analyticsRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và doanh thu thật (52.092.000)
      expect(find.text('Doanh Thu Năm 2026'), findsOneWidget);
      expect(find.textContaining('52.092.000'), findsOneWidget);

      // Kiểm tra Dropdown hiển thị Năm 2026
      expect(find.text('Năm 2026'), findsOneWidget);

      // Nhấn vào Dropdown
      await tester.tap(find.text('Năm 2026'));
      await tester.pumpAndSettle();

      // DropdownMenuItem hiển thị các năm do API trả về (2024, 2025, 2026)
      expect(find.text('Năm 2024'), findsWidgets);
      expect(find.text('Năm 2025'), findsWidgets);
    });

    testWidgets('fallback động an toàn khi API không trả availableYears', (tester) async {
      final mock = MockReportsDioClient()
        ..throw404ForYears = true
        ..revenueResponse = {
          'success': true,
          'data': {
            'year': 2026,
            // Không có availableYears
            'summary': {
              'totalYearRevenue': 10000000,
            },
            'monthly': [],
          },
        };

      final repo = AnalyticsRepository(dioClient: mock);

      await tester.pumpWidget(
        MaterialApp(
          home: ReportsScreen(analyticsRepository: repo),
        ),
      );

      await tester.pumpAndSettle();

      // Không bị lỗi, hiển thị năm 2026
      expect(find.text('Doanh Thu Năm 2026'), findsOneWidget);
      expect(find.textContaining('10.000.000'), findsOneWidget);

      // Mở dropdown kiểm tra fallback có các năm lân cận
      await tester.tap(find.text('Năm 2026'));
      await tester.pumpAndSettle();

      final currentYear = DateTime.now().year;
      expect(find.text('Năm $currentYear'), findsWidgets);
      expect(find.text('Năm ${currentYear - 1}'), findsWidgets);
    });
  });
}
