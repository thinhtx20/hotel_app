// Utility hỗ trợ tìm kiếm tiếng Việt không phân biệt hoa/thường và có dấu/không dấu.
class VietnameseSearchHelper {
  VietnameseSearchHelper._();

  static final RegExp _vietnameseRegexA = RegExp(r'[àáảãạăằắẳẵặâầấẩẫậäåāą]');
  static final RegExp _vietnameseRegexE = RegExp(r'[èéẻẽẹêềếểễệëēę]');
  static final RegExp _vietnameseRegexI = RegExp(r'[ìíỉĩịïī]');
  static final RegExp _vietnameseRegexO = RegExp(r'[òóỏõọôồốổỗộơờớởỡợöō]');
  static final RegExp _vietnameseRegexU = RegExp(r'[ùúủũụưừứửữựüūų]');
  static final RegExp _vietnameseRegexY = RegExp(r'[ỳýỷỹỵÿ]');
  static final RegExp _vietnameseRegexD = RegExp(r'[đĐ]');

  // Combining diacritical marks (Unicode block U+0300 - U+036F)
  // Xử lý trường hợp chuỗi ở dạng NFD (ký tự phân rã)
  static final RegExp _combiningMarksRegex = RegExp(r'[\u0300-\u036f]');

  /// Chuyển đổi chuỗi thành chuỗi không dấu, chữ thường và chuẩn hóa khoảng trắng.
  static String toUnaccented(String? text) {
    if (text == null || text.isEmpty) return '';

    var result = text.toLowerCase();

    // Thay thế đ/Đ trước
    result = result.replaceAll(_vietnameseRegexD, 'd');

    // Thay thế các nguyên âm tiếng Việt dạng NFC (precomposed)
    result = result.replaceAll(_vietnameseRegexA, 'a');
    result = result.replaceAll(_vietnameseRegexE, 'e');
    result = result.replaceAll(_vietnameseRegexI, 'i');
    result = result.replaceAll(_vietnameseRegexO, 'o');
    result = result.replaceAll(_vietnameseRegexU, 'u');
    result = result.replaceAll(_vietnameseRegexY, 'y');

    // Loại bỏ dấu tổ hợp NFD nếu có
    result = result.replaceAll(_combiningMarksRegex, '');

    return result.trim();
  }

  /// Kiểm tra [source] có khớp với [query] hay không:
  /// - Không phân biệt chữ hoa, chữ thường
  /// - Không phân biệt có dấu hay không dấu (người dùng gõ có dấu hay không dấu đều khớp)
  /// - Khớp chuỗi con trực tiếp hoặc khớp tất cả các từ trong cụm tìm kiếm (multi-word)
  static bool matches(String? source, String? query) {
    if (query == null || query.trim().isEmpty) return true;
    if (source == null || source.trim().isEmpty) return false;

    final normQuery = toUnaccented(query);
    if (normQuery.isEmpty) return true;

    final normSource = toUnaccented(source);

    // Khớp nguyên chuỗi tìm kiếm
    if (normSource.contains(normQuery)) return true;

    // Hỗ trợ tìm kiếm theo nhiều từ (ví dụ: "văn bình" khớp với "Nguyễn Văn Bình")
    final words = normQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length > 1 && words.every((w) => normSource.contains(w))) {
      return true;
    }

    return false;
  }

  /// Kiểm tra xem query có khớp với BẤT KỲ trường nào trong danh sách [fields]
  static bool matchesAny(List<String?> fields, String? query) {
    if (query == null || query.trim().isEmpty) return true;
    return fields.any((field) => matches(field, query));
  }
}
