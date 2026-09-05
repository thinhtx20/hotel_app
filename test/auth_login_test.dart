import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/core/constants/role_enum.dart';
import 'package:hotel_app/shared/models/user_model.dart';

void main() {
  group('Auth Login & UserModel parsing tests', () {
    test('UserModel parses NestJS customer login data correctly', () {
      final json = {
        'id': '37d2189e-41e4-4e6d-8aa1-72b025c14c8d',
        'email': 'customer@hotel.com',
        'fullName': 'Nguyễn Văn A',
        'phone': '0912345678',
        'avatar': null,
        'role': 'CUSTOMER',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '37d2189e-41e4-4e6d-8aa1-72b025c14c8d');
      expect(user.email, 'customer@hotel.com');
      expect(user.fullName, 'Nguyễn Văn A');
      expect(user.role, UserRole.customer);
    });

    test('UserRole matches role strings correctly', () {
      expect(UserRole.fromString('CUSTOMER'), UserRole.customer);
      expect(UserRole.fromString('ADMIN'), UserRole.admin);
      expect(UserRole.fromString('RECEPTIONIST'), UserRole.receptionist);
      expect(UserRole.fromString('CASHIER'), UserRole.receptionist);
    });
  });
}
