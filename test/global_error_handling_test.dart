import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/errors/app_bloc_observer.dart';
import 'package:hotel_app/core/errors/global_error_handler.dart';
import 'package:hotel_app/shared/widgets/app_global_error_widget.dart';

// Sample Cubit to test AppBlocObserver
class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void triggerError() {
    addError(Exception('Test Cubit Error'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GlobalErrorHandler & Core Error Shield Tests', () {
    setUp(() {
      GlobalErrorHandler.initialize();
    });

    test('GlobalErrorHandler.initialize configures error hooks properly', () {
      expect(FlutterError.onError, isNotNull);
      expect(PlatformDispatcher.instance.onError, isNotNull);
      expect(ErrorWidget.builder, isNotNull);
    });

    test('PlatformDispatcher.instance.onError catches async errors and returns true', () {
      final handled = PlatformDispatcher.instance.onError!(
        Exception('Uncaught async exception in test isolate'),
        StackTrace.current,
      );
      // Returns true to prevent isolate crash
      expect(handled, isTrue);
    });

    test('AppBlocObserver catches and processes Bloc errors without crashing', () {
      final observer = AppBlocObserver();
      final cubit = _TestCubit();

      expect(
        () => observer.onError(cubit, Exception('Bloc Failure'), StackTrace.current),
        returnsNormally,
      );

      cubit.close();
    });

    testWidgets('AppGlobalErrorFallbackWidget renders compact error view when space is constrained',
        (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('Render card error'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 150,
                height: 80,
                child: AppGlobalErrorFallbackWidget(details: details),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Lỗi kết xuất thành phần'), findsOneWidget);
    });

    testWidgets('AppGlobalErrorFallbackWidget renders full screen Luxury Fallback on large screen',
        (tester) async {
      final details = FlutterErrorDetails(
        exception: Exception('Full screen render crash'),
        stack: StackTrace.current,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 800,
              child: AppGlobalErrorFallbackWidget(details: details),
            ),
          ),
        ),
      );

      expect(find.text('Đã xảy ra sự cố hiển thị'), findsOneWidget);
      expect(find.text('Về trang chủ'), findsOneWidget);
      expect(
        find.textContaining('Ứng dụng gặp lỗi trong quá trình kết xuất giao diện'),
        findsOneWidget,
      );
    });

    testWidgets('ErrorWidget.builder creates AppGlobalErrorFallbackWidget on widget build exception',
        (tester) async {
      final widget = ErrorWidget.builder(
        FlutterErrorDetails(
          exception: Exception('Widget build exploded'),
        ),
      );

      expect(widget, isA<AppGlobalErrorFallbackWidget>());
    });
  });
}
