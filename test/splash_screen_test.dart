import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/auth/bloc/auth_bloc.dart';
import 'package:hotel_app/features/auth/bloc/auth_state.dart';
import 'package:hotel_app/features/splash/splash_screen.dart';

class MockAuthBloc extends Fake implements AuthBloc {
  final AuthState _state;
  MockAuthBloc(this._state);

  @override
  AuthState get state => _state;

  @override
  Stream<AuthState> get stream => Stream.value(_state);
}

void main() {
  testWidgets('SplashScreen renders luxury brand and animations without crashing',
      (WidgetTester tester) async {
    final authBloc = MockAuthBloc(AuthUnauthenticated());

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const SplashScreen(),
        ),
      ),
    );

    // Initial frame
    expect(find.text('LUXE GRAND HOTEL'), findsOneWidget);
    expect(find.text('Trải nghiệm nghỉ dưỡng đẳng cấp'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance animation
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('LUXE GRAND HOTEL'), findsOneWidget);

    // Advance beyond splash minimum duration
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
