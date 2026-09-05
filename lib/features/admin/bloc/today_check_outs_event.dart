import 'package:equatable/equatable.dart';
import '../../../shared/models/booking_model.dart';

abstract class TodayCheckOutsEvent extends Equatable {
  const TodayCheckOutsEvent();

  @override
  List<Object?> get props => [];
}

class TodayCheckOutsFetchRequested extends TodayCheckOutsEvent {
  final bool isSilent;

  const TodayCheckOutsFetchRequested({this.isSilent = false});

  @override
  List<Object?> get props => [isSilent];
}

class TodayCheckOutsRefreshRequested extends TodayCheckOutsEvent {
  const TodayCheckOutsRefreshRequested();
}

class TodayCheckOutsTabChanged extends TodayCheckOutsEvent {
  final int tabIndex;

  const TodayCheckOutsTabChanged(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class TodayCheckOutsSearchChanged extends TodayCheckOutsEvent {
  final String query;

  const TodayCheckOutsSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class TodayCheckOutsBookingUpdated extends TodayCheckOutsEvent {
  final BookingModel booking;

  const TodayCheckOutsBookingUpdated(this.booking);

  @override
  List<Object?> get props => [booking];
}
