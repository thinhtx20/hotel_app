import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _numberFormat = NumberFormat.decimalPattern('vi_VN');

  /// Định dạng số tiền có ký hiệu ₫: 1450000 -> "1.450.000 ₫"
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Định dạng số có dấu chấm phân cách hàng nghìn: 1450000 -> "1.450.000"
  static String formatNumber(num amount) {
    return _numberFormat.format(amount);
  }

  /// Phân tích chuỗi số có dấu chấm/phẩy/ký hiệu thành số: "1.450.000 ₫", "1,450,000" -> 1450000
  static num? parseCurrency(String? text) {
    if (text == null) return null;
    final clean = text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('₫', '')
        .replaceAll('đ', '')
        .replaceAll('VND', '')
        .replaceAll('VNĐ', '')
        .replaceAll(' ', '')
        .trim();
    return num.tryParse(clean);
  }

  /// Ví dụ: DateTime -> "14:00 - 15/09/2026"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime.toLocal());
  }

  /// Ví dụ: DateTime -> "15/09/2026"
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
  }
}

/// Formatter tự động định dạng số tiền theo hàng nghìn (VD: 1.500.000) khi người dùng nhập liệu
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = Formatters.formatNumber(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
