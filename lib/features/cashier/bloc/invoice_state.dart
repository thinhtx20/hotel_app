import 'package:equatable/equatable.dart';
import '../../../shared/models/invoice_model.dart';

enum InvoiceStatus { initial, loading, success, failure }

class InvoiceState extends Equatable {
  static const int defaultPageSize = 20;

  final InvoiceStatus status;
  final List<InvoiceModel> invoices;
  final int selectedTabIndex;
  final String searchQuery;
  final String currentTimeFilterType;
  final int selectedYear;
  final int fromMonth;
  final int toMonth;
  final int weekOffset;
  final String timeFilterDisplayLabel;
  final num todayRevenue;
  final int displayedCount;
  final bool isLoadingMore;
  final String? errorMessage;

  InvoiceState({
    this.status = InvoiceStatus.initial,
    this.invoices = const [],
    this.selectedTabIndex = 0,
    this.searchQuery = '',
    this.currentTimeFilterType = 'week',
    int? selectedYear,
    this.fromMonth = 1,
    int? toMonth,
    this.weekOffset = 0,
    this.timeFilterDisplayLabel = 'Tuần này',
    this.todayRevenue = 0,
    this.displayedCount = defaultPageSize,
    this.isLoadingMore = false,
    this.errorMessage,
  })  : selectedYear = selectedYear ?? DateTime.now().year,
        toMonth = toMonth ?? DateTime.now().month;

  bool get isLoading => status == InvoiceStatus.loading;
  bool get isInitial => status == InvoiceStatus.initial;
  bool get isSuccess => status == InvoiceStatus.success;
  bool get isFailure => status == InvoiceStatus.failure;

  /// Danh sách hóa đơn sau khi áp dụng tab và từ khóa tìm kiếm
  List<InvoiceModel> get filteredInvoices {
    var list = invoices;
    switch (selectedTabIndex) {
      case 0: // Chưa thanh toán
        list = invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'UNPAID' ||
                (i.paidAmount <= 0 && i.remainingAmount > 0))
            .toList();
        break;
      case 1: // Thanh toán 1 phần
        list = invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PARTIAL' ||
                (i.paidAmount > 0 &&
                    i.remainingAmount > 0 &&
                    i.paymentStatus.toUpperCase() != 'UNPAID'))
            .toList();
        break;
      case 2: // Đã hoàn tất
        list = invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PAID' ||
                (i.remainingAmount <= 0 && i.finalAmount > 0))
            .toList();
        break;
      default:
        list = List.from(invoices);
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((inv) {
        final code = inv.displayCode.toLowerCase();
        final guest = (inv.customerName ?? '').toLowerCase();
        final room = (inv.roomNumber ?? '').toLowerCase();
        return code.contains(q) || guest.contains(q) || room.contains(q);
      }).toList();
    }

    return list;
  }

  /// Số lượng hóa đơn đang treo yêu cầu thanh toán qua app
  int get pendingRequestCount {
    return invoices.where((inv) => inv.hasPendingPaymentRequest).length;
  }

  InvoiceState copyWith({
    InvoiceStatus? status,
    List<InvoiceModel>? invoices,
    int? selectedTabIndex,
    String? searchQuery,
    String? currentTimeFilterType,
    int? selectedYear,
    int? fromMonth,
    int? toMonth,
    int? weekOffset,
    String? timeFilterDisplayLabel,
    num? todayRevenue,
    int? displayedCount,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return InvoiceState(
      status: status ?? this.status,
      invoices: invoices ?? this.invoices,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      currentTimeFilterType:
          currentTimeFilterType ?? this.currentTimeFilterType,
      selectedYear: selectedYear ?? this.selectedYear,
      fromMonth: fromMonth ?? this.fromMonth,
      toMonth: toMonth ?? this.toMonth,
      weekOffset: weekOffset ?? this.weekOffset,
      timeFilterDisplayLabel:
          timeFilterDisplayLabel ?? this.timeFilterDisplayLabel,
      todayRevenue: todayRevenue ?? this.todayRevenue,
      displayedCount: displayedCount ?? this.displayedCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        invoices,
        selectedTabIndex,
        searchQuery,
        currentTimeFilterType,
        selectedYear,
        fromMonth,
        toMonth,
        weekOffset,
        timeFilterDisplayLabel,
        todayRevenue,
        displayedCount,
        isLoadingMore,
        errorMessage,
      ];
}
