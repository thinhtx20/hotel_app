import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_bloc.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_event.dart';
import 'package:hotel_app/features/admin/bloc/today_check_outs_state.dart';
import 'package:hotel_app/shared/models/booking_model.dart';
import 'package:hotel_app/shared/repositories/booking_repository.dart';

class _MockBookingRepository extends BookingRepository {
  final List<BookingModel> mockBookings;

  _MockBookingRepository(this.mockBookings);

  @override
  Future<List<BookingModel>> fetchTodayCheckOuts() async {
    return mockBookings;
  }
}

void main() {
  group('TodayCheckOutsBloc Tests', () {
    late _MockBookingRepository mockRepo;
    late TodayCheckOutsBloc bloc;

    final sampleBookings = [
      BookingModel(
        id: 'bk-1',
        roomId: 'r-101',
        bookingCode: 'BK-001',
        customerName: 'Nguyễn Văn A',
        customerPhone: '0901234567',
        roomNumber: '101',
        roomTypeName: 'Standard Room',
        checkInDate: DateTime.now().subtract(const Duration(days: 2)),
        checkOutDate: DateTime.now(),
        guestCount: 2,
        totalAmount: 1000000,
        status: 'CHECKED_IN',
      ),
      BookingModel(
        id: 'bk-2',
        roomId: 'r-102',
        bookingCode: 'BK-002',
        customerName: 'Trần Thị B',
        customerPhone: '0909876543',
        roomNumber: '102',
        roomTypeName: 'VIP Suite',
        checkInDate: DateTime.now().subtract(const Duration(days: 1)),
        checkOutDate: DateTime.now(),
        guestCount: 1,
        totalAmount: 2000000,
        status: 'CHECKED_OUT',
      ),
    ];

    setUp(() {
      mockRepo = _MockBookingRepository(List.from(sampleBookings));
      bloc = TodayCheckOutsBloc(bookingRepository: mockRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state has default values', () {
      expect(bloc.state.status, TodayCheckOutsStatus.initial);
      expect(bloc.state.bookings, isEmpty);
      expect(bloc.state.selectedTabIndex, 0);
      expect(bloc.state.searchQuery, '');
    });

    test('TodayCheckOutsFetchRequested fetches and computes counts', () async {
      bloc.add(const TodayCheckOutsFetchRequested());
      await bloc.stream.firstWhere((s) => s.status == TodayCheckOutsStatus.success);

      expect(bloc.state.bookings.length, 2);
      expect(bloc.state.totalCount, 2);
      expect(bloc.state.checkedOutCount, 1);
      expect(bloc.state.pendingCount, 1);
    });

    test('TodayCheckOutsTabChanged filters pending or checked out', () async {
      bloc.add(const TodayCheckOutsFetchRequested());
      await bloc.stream.firstWhere((s) => s.status == TodayCheckOutsStatus.success);

      // Tab 1: Chờ trả (status != CHECKED_OUT)
      bloc.add(const TodayCheckOutsTabChanged(1));
      await bloc.stream.firstWhere((s) => s.selectedTabIndex == 1);
      expect(bloc.state.filteredBookings.length, 1);
      expect(bloc.state.filteredBookings.first.id, 'bk-1');

      // Tab 2: Đã trả (status == CHECKED_OUT)
      bloc.add(const TodayCheckOutsTabChanged(2));
      await bloc.stream.firstWhere((s) => s.selectedTabIndex == 2);
      expect(bloc.state.filteredBookings.length, 1);
      expect(bloc.state.filteredBookings.first.id, 'bk-2');
    });

    test('TodayCheckOutsSearchChanged filters by guest name, phone, or room', () async {
      bloc.add(const TodayCheckOutsFetchRequested());
      await bloc.stream.firstWhere((s) => s.status == TodayCheckOutsStatus.success);

      bloc.add(const TodayCheckOutsSearchChanged('102'));
      await bloc.stream.firstWhere((s) => s.searchQuery == '102');
      expect(bloc.state.filteredBookings.length, 1);
      expect(bloc.state.filteredBookings.first.roomNumber, '102');
    });

    test('TodayCheckOutsBookingUpdated updates booking in list', () async {
      bloc.add(const TodayCheckOutsFetchRequested());
      await bloc.stream.firstWhere((s) => s.status == TodayCheckOutsStatus.success);

      final updated = sampleBookings[0].copyWith(status: 'CHECKED_OUT');
      bloc.add(TodayCheckOutsBookingUpdated(updated));

      await bloc.stream.firstWhere(
        (s) => s.bookings.firstWhere((b) => b.id == 'bk-1').status == 'CHECKED_OUT',
      );
      expect(bloc.state.checkedOutCount, 2);
      expect(bloc.state.pendingCount, 0);
    });
  });
}
