import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/utils/formatters.dart';

void main() {
  group('Formatters Currency & Number Tests', () {
    test('formatCurrency formats with dot separator and currency symbol', () {
      final formatted = Formatters.formatCurrency(1450000);
      expect(formatted.contains('1.450.000'), isTrue);
      expect(formatted.contains('₫'), isTrue);
    });

    test('formatNumber formats with dot separator without symbol', () {
      final formatted = Formatters.formatNumber(1450000);
      expect(formatted, equals('1.450.000'));
    });

    test('parseCurrency parses clean and formatted strings', () {
      expect(Formatters.parseCurrency('1.450.000 ₫'), equals(1450000));
      expect(Formatters.parseCurrency('1,450,000'), equals(1450000));
      expect(Formatters.parseCurrency('1.450.000'), equals(1450000));
      expect(Formatters.parseCurrency('1450000'), equals(1450000));
      expect(Formatters.parseCurrency(''), isNull);
      expect(Formatters.parseCurrency(null), isNull);
    });

    test('CurrencyInputFormatter formats input as user types', () {
      final formatter = CurrencyInputFormatter();
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(text: '1500000');
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('1.500.000'));
    });
  });
}
