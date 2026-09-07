import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_error.dart';
import '../../../shared/repositories/invoice_repository.dart';
import 'invoice_event.dart';
import 'invoice_state.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final InvoiceRepository invoiceRepository;
  InvoiceRepository get _invoiceRepository => invoiceRepository;

  InvoiceBloc({required this.invoiceRepository})
      : super(InvoiceState()) {
    on<InvoiceFetchRequested>(_onFetchRequested);
    on<InvoiceRefreshRequested>(_onRefreshRequested);
    on<InvoiceTabFilterChanged>(_onTabFilterChanged);
    on<InvoiceSearchChanged>(_onSearchChanged);
    on<InvoiceLoadMoreRequested>(_onLoadMoreRequested);
    on<InvoiceCreated>(_onInvoiceCreated);
    on<InvoicePaymentRecorded>(_onPaymentRecorded);
    on<InvoiceRefundRecorded>(_onRefundRecorded);
  }

  Future<void> _onFetchRequested(
    InvoiceFetchRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    final isSilent = event.isSilent;
    if (!isSilent && state.invoices.isEmpty) {
      emit(state.copyWith(
        status: InvoiceStatus.loading,
        errorMessage: null,
      ));
    }

    final effectiveFilterType = event.filterType ?? state.currentTimeFilterType;
    final effectiveYear = event.year ?? state.selectedYear;
    final effectiveFromMonth = event.fromMonth ?? state.fromMonth;
    final effectiveToMonth = event.toMonth ?? state.toMonth;
    final effectiveWeekOffset = event.weekOffset ?? state.weekOffset;
    String effectiveDisplayLabel =
        event.timeFilterDisplayLabel ?? state.timeFilterDisplayLabel;

    try {
      String? filterType;
      int? year;
      int? fromMonth;
      int? toMonth;
      int? month = event.month;
      int? weekOffset;

      if (effectiveFilterType == 'week') {
        filterType = 'week';
        weekOffset = effectiveWeekOffset;
      } else if (effectiveFilterType == 'month_range') {
        filterType = 'month_range';
        year = effectiveYear;
        fromMonth = effectiveFromMonth;
        toMonth = effectiveToMonth;
      } else if (effectiveFilterType == 'year') {
        filterType = 'year';
        year = effectiveYear;
      }

      final invoices = await _invoiceRepository.fetchAll(
        filterType: filterType,
        year: year,
        fromMonth: fromMonth,
        toMonth: toMonth,
        month: month,
        weekOffset: weekOffset,
      );

      final metaLabel = _invoiceRepository.lastMeta?.timeFilterLabel;
      if (metaLabel != null && metaLabel.isNotEmpty) {
        effectiveDisplayLabel = metaLabel;
      }

      // Lấy todayRevenue từ backend summary hoặc fallback từ transactions
      num summaryTodayRevenue = 0;
      try {
        final sData = await _invoiceRepository.fetchSummary();
        if (sData['todayRevenue'] != null) {
          summaryTodayRevenue = (sData['todayRevenue'] as num?) ?? 0;
        }
      } catch (_) {}

      final now = DateTime.now();
      num localTodayPaid = 0;
      for (final inv in invoices) {
        for (final txn in inv.transactions) {
          if (txn.timestamp.year == now.year &&
              txn.timestamp.month == now.month &&
              txn.timestamp.day == now.day) {
            localTodayPaid += txn.signedAmount;
          }
        }
      }

      final calculatedRevenue = summaryTodayRevenue > 0
          ? summaryTodayRevenue
          : localTodayPaid;

      emit(state.copyWith(
        status: InvoiceStatus.success,
        invoices: invoices,
        todayRevenue: calculatedRevenue,
        currentTimeFilterType: effectiveFilterType,
        selectedYear: effectiveYear,
        fromMonth: effectiveFromMonth,
        toMonth: effectiveToMonth,
        weekOffset: effectiveWeekOffset,
        timeFilterDisplayLabel: effectiveDisplayLabel,
        displayedCount: InvoiceState.defaultPageSize,
        isLoadingMore: false,
        errorMessage: null,
      ));
    } catch (e) {
      final message = e is ApiError ? e.message : 'Không thể tải danh sách hóa đơn';
      emit(state.copyWith(
        status: InvoiceStatus.failure,
        isLoadingMore: false,
        errorMessage: message,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    InvoiceRefreshRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    add(InvoiceFetchRequested(
      filterType: state.currentTimeFilterType,
      year: state.selectedYear,
      fromMonth: state.fromMonth,
      toMonth: state.toMonth,
      weekOffset: state.weekOffset,
      timeFilterDisplayLabel: state.timeFilterDisplayLabel,
      isSilent: true,
    ));
  }

  void _onTabFilterChanged(
    InvoiceTabFilterChanged event,
    Emitter<InvoiceState> emit,
  ) {
    emit(state.copyWith(
      selectedTabIndex: event.tabIndex,
      displayedCount: InvoiceState.defaultPageSize,
      isLoadingMore: false,
    ));
  }

  void _onSearchChanged(
    InvoiceSearchChanged event,
    Emitter<InvoiceState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: event.searchQuery,
      displayedCount: InvoiceState.defaultPageSize,
      isLoadingMore: false,
    ));
  }

  Future<void> _onLoadMoreRequested(
    InvoiceLoadMoreRequested event,
    Emitter<InvoiceState> emit,
  ) async {
    final filtered = state.filteredInvoices;
    if (state.isLoadingMore || state.displayedCount >= filtered.length) return;

    emit(state.copyWith(isLoadingMore: true));
    await Future.delayed(const Duration(milliseconds: 200));
    final nextCount = (state.displayedCount + InvoiceState.defaultPageSize)
        .clamp(0, filtered.length);
    emit(state.copyWith(
      displayedCount: nextCount,
      isLoadingMore: false,
    ));
  }

  void _onInvoiceCreated(
    InvoiceCreated event,
    Emitter<InvoiceState> emit,
  ) {
    final updated = [event.invoice, ...state.invoices];
    emit(state.copyWith(
      invoices: updated,
      selectedTabIndex: 0,
      displayedCount: InvoiceState.defaultPageSize,
      isLoadingMore: false,
    ));
  }

  void _onPaymentRecorded(
    InvoicePaymentRecorded event,
    Emitter<InvoiceState> emit,
  ) {
    final updatedList = state.invoices.map((inv) {
      return inv.id == event.invoiceId ? event.updatedInvoice : inv;
    }).toList();

    emit(state.copyWith(
      invoices: updatedList,
      todayRevenue: state.todayRevenue + event.amount,
    ));
  }

  void _onRefundRecorded(
    InvoiceRefundRecorded event,
    Emitter<InvoiceState> emit,
  ) {
    final updatedList = state.invoices.map((inv) {
      return inv.id == event.updatedInvoice.id ? event.updatedInvoice : inv;
    }).toList();

    emit(state.copyWith(invoices: updatedList));
  }
}
