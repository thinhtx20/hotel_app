import '../../../core/utils/vietnamese_search_helper.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/booking_model.dart';

enum TodayCheckOutsStatus { initial, loading, success, failure }

class TodayCheckOutsState extends Equatable {
  final TodayCheckOutsStatus status;
  final List<BookingModel> bookings;
  final int selectedTabIndex;
  final String searchQuery;
  final String? errorMessage;

  const TodayCheckOutsState({
    this.status = TodayCheckOutsStatus.initial,
    this.bookings = const [],
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.errorMessage,
  });

  bool get isLoading => status == TodayCheckOutsStatus.loading;
  bool get isSuccess => status == TodayCheckOutsStatus.success;
  bool get isFailure => status == TodayCheckOutsStatus.failure;

  int get totalCount => bookings.length;
  int get checkedOutCount =>
      bookings.where((b) => b.status == 'CHECKED_OUT').length;
  int get pendingCount => totalCount - checkedOutCount;

  List<BookingModel> get filteredBookings {
    return bookings.where((b) {
      if (selectedTabIndex == 1 && b.status == 'CHECKED_OUT') return false;
      if (selectedTabIndex == 2 && b.status != 'CHECKED_OUT') return false;

      if (searchQuery.isNotEmpty) {
        final matches = VietnameseSearchHelper.matchesAny([
          b.customerName,
          b.customerPhone,
          b.roomNumber,
          b.bookingCode,
        ], searchQuery);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  TodayCheckOutsState copyWith({
    TodayCheckOutsStatus? status,
    List<BookingModel>? bookings,
    int? selectedTabIndex,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TodayCheckOutsState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bookings,
        selectedTabIndex,
        searchQuery,
        errorMessage,
      ];
}
