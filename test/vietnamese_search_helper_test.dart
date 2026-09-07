import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/utils/vietnamese_search_helper.dart';

void main() {
  group('VietnameseSearchHelper Tests', () {
    test('toUnaccented converts accents to basic lowercase latin', () {
      expect(VietnameseSearchHelper.toUnaccented('Nguyễn Văn Bình'), 'nguyen van binh');
      expect(VietnameseSearchHelper.toUnaccented('ĐỖ NAM TRUNG'), 'do nam trung');
      expect(VietnameseSearchHelper.toUnaccented('Trần Thị Đào'), 'tran thi dao');
      expect(VietnameseSearchHelper.toUnaccented('Phòng Deluxe 101'), 'phong deluxe 101');
    });

    test('matches: case-insensitive and accent-insensitive matching', () {
      const source = 'Nguyễn Văn Bình';

      // Không dấu thường
      expect(VietnameseSearchHelper.matches(source, 'nguyen'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'binh'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'van binh'), isTrue);

      // Không dấu hoa
      expect(VietnameseSearchHelper.matches(source, 'NGUYEN'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'BINH'), isTrue);

      // Có dấu thường
      expect(VietnameseSearchHelper.matches(source, 'nguyễn'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'bình'), isTrue);

      // Có dấu hoa
      expect(VietnameseSearchHelper.matches(source, 'NGUYỄN'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'BÌNH'), isTrue);

      // Gõ đảo thứ tự từ
      expect(VietnameseSearchHelper.matches(source, 'bình nguyễn'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'binh nguyen'), isTrue);

      // Không khớp
      expect(VietnameseSearchHelper.matches(source, 'hoang'), isFalse);
    });

    test('matches: đ and d interchangeably', () {
      const source = 'Trần Thị Đào';
      expect(VietnameseSearchHelper.matches(source, 'dao'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'đào'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'ĐÀO'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'DAO'), isTrue);
    });

    test('matches: reversed search (source unaccented, query accented)', () {
      const source = 'Nguyen Van Binh';
      expect(VietnameseSearchHelper.matches(source, 'nguyễn'), isTrue);
      expect(VietnameseSearchHelper.matches(source, 'Bình'), isTrue);
    });

    test('matchesAny: checks multiple fields', () {
      const name = 'Nguyễn Văn Bình';
      const email = 'binh.nv@hotel.com';
      const phone = '0912345678';

      expect(VietnameseSearchHelper.matchesAny([name, email, phone], 'binh'), isTrue);
      expect(VietnameseSearchHelper.matchesAny([name, email, phone], 'BÌNH'), isTrue);
      expect(VietnameseSearchHelper.matchesAny([name, email, phone], '0912'), isTrue);
      expect(VietnameseSearchHelper.matchesAny([name, email, phone], 'hotel.com'), isTrue);
      expect(VietnameseSearchHelper.matchesAny([name, email, phone], 'xyz'), isFalse);
    });
  });
}
