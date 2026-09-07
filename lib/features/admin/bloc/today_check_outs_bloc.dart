import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import 'today_check_outs_event.dart';
import 'today_check_outs_state.dart';

class TodayCheckOutsBloc
    extends Bloc<TodayCheckOutsEvent, TodayCheckOutsState> {
  final BookingRepository bookingRepository;
  BookingRepository get _bookingRepository => bookingRepository;

  TodayCheckOutsBloc({required this.bookingRepository})
      : super(const TodayCheckOutsState()) {
    on<TodayCheckOutsFetchRequested>(_onFetchRequested);
    on<TodayCheckOutsRefreshRequested>(_onRefreshRequested);
    on<TodayCheckOutsTabChanged>(_onTabChanged);
    on<TodayCheckOutsSearchChanged>(_onSearchChanged);
    on<TodayCheckOutsBookingUpdated>(_onBookingUpdated);
  }

  Future<void> _onFetchRequested(
    TodayCheckOutsFetchRequested event,
    Emitter<TodayCheckOutsState> emit,
  ) async {
    if (!event.isSilent && state.bookings.isEmpty) {
      emit(state.copyWith(
        status: TodayCheckOutsStatus.loading,
        errorMessage: null,
      ));
    }

    try {
      final list = await _bookingRepository.fetchTodayCheckOuts();
      emit(state.copyWith(
        status: TodayCheckOutsStatus.success,
        bookings: list,
        errorMessage: null,
      ));
    } catch (e) {
      final apiErr = ApiError.fromDynamic(e);
      emit(state.copyWith(
        status: TodayCheckOutsStatus.failure,
        errorMessage: apiErr.displayMessage,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    TodayCheckOutsRefreshRequested event,
    Emitter<TodayCheckOutsState> emit,
  ) async {
    add(const TodayCheckOutsFetchRequested(isSilent: true));
  }

  void _onTabChanged(
    TodayCheckOutsTabChanged event,
    Emitter<TodayCheckOutsState> emit,
  ) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }

  void _onSearchChanged(
    TodayCheckOutsSearchChanged event,
    Emitter<TodayCheckOutsState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onBookingUpdated(
    TodayCheckOutsBookingUpdated event,
    Emitter<TodayCheckOutsState> emit,
  ) {
    final idx = state.bookings.indexWhere((b) => b.id == event.booking.id);
    if (idx != -1) {
      final list = List<BookingModel>.from(state.bookings);
      list[idx] = event.booking;
      emit(state.copyWith(bookings: list));
    }
  }
}
