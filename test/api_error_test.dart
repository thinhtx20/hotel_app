import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/network/api_error.dart';

void main() {
  group('ApiError Backend Parsing Tests', () {
    test('Parse NestJS business error correctly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
          data: {
            'statusCode': 401,
            'success': false,
            'message': 'Email hoặc mật khẩu không chính xác',
            'error': 'Unauthorized',
          },
        ),
      );

      final error = ApiError.fromDioException(dioException);

      expect(error.statusCode, 401);
      expect(error.displayMessage, 'Email hoặc mật khẩu không chính xác');
      expect(error.isNetworkError, false);
      expect(error.hasDetailedErrors, false);
    });

    test('Parse NestJS Validation errors with errors array', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'success': false,
            'message': 'email phải đúng định dạng. mật khẩu tối thiểu 6 ký tự',
            'errors': [
              'email phải đúng định dạng',
              'mật khẩu tối thiểu 6 ký tự',
            ],
            'error': 'Bad Request',
          },
        ),
      );

      final error = ApiError.fromDioException(dioException);

      expect(error.statusCode, 400);
      expect(error.displayMessage, 'email phải đúng định dạng. mật khẩu tối thiểu 6 ký tự');
      expect(error.errors.length, 2);
      expect(error.errors[0], 'email phải đúng định dạng');
      expect(error.errors[1], 'mật khẩu tối thiểu 6 ký tự');
      expect(error.hasDetailedErrors, true);
    });

    test('Parse NestJS Validation error when message is an array of strings', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 400,
          data: {
            'statusCode': 400,
            'success': false,
            'message': [
              'Tên không được để trống',
              'Số điện thoại không hợp lệ',
            ],
          },
        ),
      );

      final error = ApiError.fromDioException(dioException);

      expect(error.statusCode, 400);
      expect(error.displayMessage, 'Tên không được để trống\nSố điện thoại không hợp lệ');
      expect(error.errors.length, 2);
    });

    test('Parse Prisma duplicate record conflict error (409)', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/auth/register'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register'),
          statusCode: 409,
          data: {
            'statusCode': 409,
            'success': false,
            'message': 'Dữ liệu \'email\' đã tồn tại trong hệ thống, vui lòng kiểm tra lại.',
          },
        ),
      );

      final error = ApiError.fromDioException(dioException);

      expect(error.statusCode, 409);
      expect(
        error.displayMessage,
        'Dữ liệu \'email\' đã tồn tại trong hệ thống, vui lòng kiểm tra lại.',
      );
    });

    test('Parse Connection Timeout when BE is not reachable', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/rooms'),
        type: DioExceptionType.connectionTimeout,
      );

      final error = ApiError.fromDioException(dioException);

      expect(error.isNetworkError, true);
      expect(error.displayMessage, contains('quá thời gian'));
    });

    test('ApiError.fromDynamic handles String, Exception and ApiError', () {
      final strErr = ApiError.fromDynamic('Lỗi từ chuỗi');
      expect(strErr.displayMessage, 'Lỗi từ chuỗi');

      final exErr = ApiError.fromDynamic(Exception('Lỗi ngoại lệ'));
      expect(exErr.displayMessage, 'Lỗi ngoại lệ');

      final copyErr = ApiError.fromDynamic(strErr);
      expect(copyErr, strErr);
    });
  });
}
