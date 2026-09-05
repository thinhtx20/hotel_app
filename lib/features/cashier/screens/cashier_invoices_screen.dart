import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/invoice_bloc.dart';
import '../bloc/invoice_event.dart';
import '../bloc/invoice_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/invoice_row_skeleton.dart';
import '../../../shared/widgets/sticky_header.dart';
import '../../receptionist/screens/payment_requests_screen.dart';
import '../../receptionist/screens/shift_close_screen.dart';
import '../widgets/invoice_card.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/invoice_filter_bar.dart';
import '../widgets/payment_sheet.dart';

class CashierInvoicesScreen extends StatefulWidget {
  final InvoiceBloc? invoiceBloc;
  final InvoiceRepository? invoiceRepository;
  const CashierInvoicesScreen({
    super.key,
    this.invoiceBloc,
    this.invoiceRepository,
  });

  static String formatCurrentWeekRange([DateTime? refDate]) {
    final date = refDate ?? DateTime.now();
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final start =
        '${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}';
    final end =
        '${sunday.day.toString().padLeft(2, '0')}/${sunday.month.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  @override
  State<CashierInvoicesScreen> createState() => _CashierInvoicesScreenState();
}

class _CashierInvoicesScreenState extends State<CashierInvoicesScreen> {
  static const int _pageSize = 20;

  late final InvoiceBloc _invoiceBloc;
  bool _ownsBloc = false;
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  @visibleForTesting
  int get displayedCount => _invoiceBloc.state.displayedCount;

  @visibleForTesting
  void loadMoreForTesting() => _loadMore();

  final List<String> _tabs = [
    'Chưa thanh toán',
    'Thanh toán 1 phần',
    'Đã hoàn tất',
    'Tất cả',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.invoiceBloc != null) {
      _invoiceBloc = widget.invoiceBloc!;
      _ownsBloc = false;
    } else if (widget.invoiceRepository != null) {
      _invoiceBloc = InvoiceBloc(invoiceRepository: widget.invoiceRepository!);
      _ownsBloc = true;
    } else if (sl.isRegistered<InvoiceBloc>()) {
      _invoiceBloc = sl<InvoiceBloc>();
      _ownsBloc = true;
    } else {
      final repo = sl.isRegistered<InvoiceRepository>()
          ? sl<InvoiceRepository>()
          : InvoiceRepository();
      _invoiceBloc = InvoiceBloc(invoiceRepository: repo);
      _ownsBloc = true;
    }
    _scrollController = ScrollController()..addListener(_onScroll);
    _fetchInvoices();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    if (_ownsBloc) {
      _invoiceBloc.close();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 300) {
      _loadMore();
    }
  }

  void _loadMore() {
    _invoiceBloc.add(const InvoiceLoadMoreRequested());
  }

  Future<void> _fetchInvoices({bool isSilent = false}) async {
    final isAdmin = mounted && context.readRole == UserRole.admin;
    _invoiceBloc.add(InvoiceFetchRequested(
      isSilent: isSilent,
      filterType: isAdmin ? _invoiceBloc.state.currentTimeFilterType : 'week',
      weekOffset: isAdmin ? _invoiceBloc.state.weekOffset : 0,
      timeFilterDisplayLabel: !isAdmin
          ? 'Tuần này (${CashierInvoicesScreen.formatCurrentWeekRange()})'
          : null,
    ));
  }

  int _getTabCount(int tabIndex) {
    final invoices = _invoiceBloc.state.invoices;
    switch (tabIndex) {
      case 0:
        return invoices
            .where(
              (i) =>
                  i.paymentStatus.toUpperCase() == 'UNPAID' ||
                  (i.paidAmount == 0 && i.remainingAmount > 0),
            )
            .length;
      case 1:
        return invoices
            .where(
              (i) =>
                  i.paymentStatus.toUpperCase() == 'PARTIAL' ||
                  (i.paidAmount > 0 &&
                      i.remainingAmount > 0 &&
                      i.paymentStatus.toUpperCase() != 'UNPAID'),
            )
            .length;
      case 2:
        return invoices
            .where(
              (i) =>
                  i.paymentStatus.toUpperCase() == 'PAID' ||
                  (i.remainingAmount <= 0 && i.finalAmount > 0),
            )
            .length;
      case 3:
        return invoices.length;
      default:
        return 0;
    }
  }

  List<InvoiceModel> _getFilteredInvoices() =>
      _invoiceBloc.state.filteredInvoices;

  String _getCurrentShift() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 14) return 'Ca sáng';
    if (hour >= 14 && hour < 22) return 'Ca chiều';
    return 'Ca đêm';
  }

  void _showInvoiceDetailSheet(InvoiceModel invoice) {
    InvoiceDetailSheet.show(
      context: context,
      invoice: invoice,
      onPrintReceipt: () => _showReceiptSheet(invoice),
      onCollectPayment: () => _showPaymentModal(invoice),
      onRefund: (updated) {
        if (!mounted) return;
        _invoiceBloc.add(InvoiceRefundRecorded(updated));
      },
    );
  }

  void _showPaymentModal(InvoiceModel invoice) {
    PaymentSheet.show(
      context: context,
      invoice: invoice,
      onConfirmPayment:
          ({
            required num amount,
            required String paymentMethod,
            required String notes,
          }) async {
            try {
              final updated = await sl<InvoiceRepository>().pay(
                invoice.id,
                amount: amount,
                paymentMethod: paymentMethod,
                paymentStatus: amount >= invoice.remainingAmount
                    ? 'PAID'
                    : 'PARTIAL',
                notes: notes.isNotEmpty ? notes : null,
              );
              if (!mounted) return;
              _invoiceBloc.add(InvoicePaymentRecorded(
                invoiceId: invoice.id,
                updatedInvoice: updated,
                amount: amount,
              ));
              AppNotification.showSuccess(
                context,
                'Ghi nhận thu ${Formatters.formatCurrency(amount)} thành công!',
              );
              _showReceiptSheet(
                updated,
                lastTxn: updated.transactions.isNotEmpty
                    ? updated.transactions.last
                    : null,
              );
            } catch (e) {
              if (!mounted) return;
              AppNotification.showError(
                context,
                e,
                title: 'Thanh toán thất bại',
              );
            }
          },
    );
  }

  void _showReceiptSheet(
    InvoiceModel invoice, {
    PaymentTransactionModel? lastTxn,
  }) {
    final palette = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.screen),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      // Luxury Logo Brand
                      Icon(
                        Icons.hotel_class_rounded,
                        color: palette.accent,
                        size: 36,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'LUXE GRAND HOTEL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: palette.accent,
                        ),
                      ),
                      Text(
                        'PHIẾU XÁC NHẬN THANH TOÁN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.inkMuted,
                        ),
                      ),
                      Divider(height: 24, thickness: 1, color: palette.border),

                      // Receipt Meta
                      _buildReceiptRow(
                        'Số biên lai',
                        lastTxn?.id ?? 'REC-${invoice.displayCode}',
                      ),
                      _buildReceiptRow('Mã hóa đơn', '#${invoice.displayCode}'),
                      _buildReceiptRow(
                        'Thời gian',
                        Formatters.formatDateTime(
                          lastTxn?.timestamp ?? DateTime.now(),
                        ),
                      ),
                      _buildReceiptRow(
                        'Thu ngân',
                        lastTxn?.cashierName ??
                            'Thu ngân ${_getCurrentShift()}',
                      ),
                      Divider(height: 20, color: palette.divider),

                      _buildReceiptRow(
                        'Khách hàng',
                        invoice.customerName ?? 'Khách vãng lai',
                        isBold: true,
                      ),
                      _buildReceiptRow(
                        'Số phòng',
                        'Phòng ${invoice.roomNumber ?? "N/A"}',
                      ),
                      Divider(height: 20, color: palette.divider),

                      // Financial summary
                      _buildReceiptRow(
                        'Tổng cộng hóa đơn',
                        Formatters.formatCurrency(invoice.finalAmount),
                      ),
                      _buildReceiptRow(
                        'Đã thanh toán',
                        Formatters.formatCurrency(invoice.paidAmount),
                        color: palette.statusAvailable,
                        isBold: true,
                      ),
                      if (lastTxn != null)
                        _buildReceiptRow(
                          'Số tiền vừa thu',
                          Formatters.formatCurrency(lastTxn.amount),
                          color: palette.accent,
                          isBold: true,
                        ),
                      _buildReceiptRow(
                        'Phương thức',
                        _getMethodLabel(
                          lastTxn?.paymentMethod ??
                              invoice.paymentMethod ??
                              'TIỀN MẶT',
                        ),
                      ),
                      if (invoice.remainingAmount > 0)
                        _buildReceiptRow(
                          'Số dư còn thiếu',
                          Formatters.formatCurrency(invoice.remainingAmount),
                          color: palette.error,
                          isBold: true,
                        )
                      else
                        _buildReceiptRow(
                          'Trạng thái',
                          'ĐÃ HOÀN TẤT (100%)',
                          color: palette.statusAvailable,
                          isBold: true,
                        ),

                      const SizedBox(height: AppSpacing.lg),
                      // Mini QR verification
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: palette.statusAvailable,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hóa đơn điện tử hợp lệ của Luxe Grand Hotel',
                              style: TextStyle(
                                fontSize: 11,
                                color: palette.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Actions
            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    onTap: () => Navigator.pop(ctx),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                      label: const Text('Đóng'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.inkMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: PressableScale(
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đang gửi lệnh in biên lai tới máy in POS...',
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đang gửi lệnh in biên lai tới máy in POS...',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('In phiếu thu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String title,
    String val, {
    bool isBold = false,
    Color? color,
  }) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: palette.inkMuted)),
          Text(
            val,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateInvoiceModal() {
    final palette = context.palette;
    String selectedRoom = '203';
    final customerController = TextEditingController(text: 'Khách lưu trú');
    final itemTitleController = TextEditingController(
      text: 'Phụ phí dịch vụ phát sinh',
    );
    final amountController = TextEditingController(text: '500.000');
    String selectedCategory = 'MINIBAR';

    final categories = [
      {'id': 'ROOM', 'name': 'Tiền phòng lưu trú'},
      {'id': 'MINIBAR', 'name': 'Minibar / Đồ uống phòng'},
      {'id': 'DINING', 'name': 'Ăn uống tại phòng (Room Service)'},
      {'id': 'LAUNDRY', 'name': 'Dịch vụ giặt là cao cấp'},
      {'id': 'LATE_CHECKOUT', 'name': 'Phụ thu check-out muộn'},
      {'id': 'DAMAGE', 'name': 'Bồi thường tài sản / hỏng hóc'},
      {'id': 'OTHER', 'name': 'Khoản thu khác'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tạo Hóa Đơn / Thêm Phụ Phí',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: palette.inkMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.divider),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chọn phòng
                      Text(
                        'Phòng áp dụng:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRoom,
                        dropdownColor: palette.surface,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '101',
                            child: Text('Phòng 101 (Tầng 1)'),
                          ),
                          DropdownMenuItem(
                            value: '108',
                            child: Text('Phòng 108 (Lê Văn Cường)'),
                          ),
                          DropdownMenuItem(
                            value: '203',
                            child: Text('Phòng 203 (Nguyễn Văn A)'),
                          ),
                          DropdownMenuItem(
                            value: '205',
                            child: Text('Phòng 205 (Hoàng Minh Tuấn)'),
                          ),
                          DropdownMenuItem(
                            value: '301',
                            child: Text('Phòng 301 (Nguyễn Văn A)'),
                          ),
                          DropdownMenuItem(
                            value: '402',
                            child: Text('Phòng 402 (Trần Thị Bích)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setModalState(() => selectedRoom = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Tên khách hàng
                      Text(
                        'Tên khách hàng:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customerController,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Danh mục phụ phí
                      Text(
                        'Danh mục khoản thu:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: palette.surface,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                        items: categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c['id'],
                                child: Text(c['name']!),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                              final cat = categories.firstWhere(
                                (c) => c['id'] == val,
                              );
                              itemTitleController.text = cat['name']!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Diễn giải khoản mục
                      Text(
                        'Tên chi tiết khoản thu:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: itemTitleController,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Số tiền
                      Text(
                        'Số tiền (VND):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: TextStyle(
                          color: palette.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: palette.accent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.field,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nút tạo hóa đơn
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: PressableScale(
                  onTap: () async {
                    final amt =
                        Formatters.parseCurrency(amountController.text) ?? 0;
                    if (amt <= 0) {
                      AppNotification.showWarning(
                        context,
                        'Vui lòng nhập số tiền hợp lệ',
                      );
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      final payload = {
                        'roomNumber': selectedRoom,
                        'customerName':
                            customerController.text.trim().isNotEmpty
                            ? customerController.text.trim()
                            : 'Khách phòng $selectedRoom',
                        'finalAmount': amt,
                        'roomAmount': selectedCategory == 'ROOM' ? amt : 0,
                        'servicesAmount': selectedCategory != 'ROOM' ? amt : 0,
                        'items': [
                          {
                            'title': itemTitleController.text.trim().isNotEmpty
                                ? itemTitleController.text.trim()
                                : 'Phụ phí',
                            'quantity': 1,
                            'unitPrice': amt,
                            'category': selectedCategory,
                          },
                        ],
                      };
                      final created = await sl<InvoiceRepository>().create(
                        payload,
                      );
                      if (mounted) {
                        _invoiceBloc.add(InvoiceCreated(created));
                        AppNotification.showSuccess(
                          context,
                          'Đã tạo hóa đơn ${created.displayCode} thành công!',
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        AppNotification.showError(
                          context,
                          e,
                          title: 'Tạo hóa đơn thất bại',
                        );
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: AppShadows.goldGlow,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Lưu & Tạo Hóa Đơn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMethodLabel(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return 'Tiền mặt';
      case 'BANK_TRANSFER':
        return 'VietQR / Chuyển khoản';
      case 'CREDIT_CARD':
        return 'Thẻ POS ngân hàng';
      default:
        return method;
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      final role = context.currentRole;
      if (role == UserRole.admin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/receptionist/rooms');
      }
    } catch (_) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      bloc: _invoiceBloc,
      listener: (context, state) {
        if (state.isFailure && state.errorMessage != null) {
          AppNotification.showError(
            context,
            state.errorMessage!,
            title: 'Tải danh sách hóa đơn thất bại',
          );
        }
      },
      builder: (context, state) {
        final palette = context.palette;
        final invoices = state.invoices;
        final filtered = state.filteredInvoices;
        final displayed = filtered.take(state.displayedCount).toList();
        final totalPaid = invoices.fold<num>(
          0,
          (sum, inv) => sum + inv.paidAmount,
        );
        final totalRemaining = invoices.fold<num>(
          0,
          (sum, inv) => sum + inv.remainingAmount,
        );
        final pendingCount =
            invoices.where((i) => i.remainingAmount > 0).length;
        // Hóa đơn khách đã bấm trả qua app nhưng chưa ai dò sao kê.
        final pendingRequests =
            invoices.where((i) => i.hasPendingPaymentRequest).toList();
        final pendingRequestCount = pendingRequests.length;
        final pendingRequestAmount = pendingRequests.fold<num>(
          0,
          (sum, i) => sum + i.pendingRequestedAmount,
        );

        String emptyTitle = 'Không có hóa đơn nào';
        String emptySubtitle = 'Hiện tại không tìm thấy hóa đơn phù hợp.';
        if (state.searchQuery.isNotEmpty) {
          emptyTitle = 'Không tìm thấy kết quả';
          emptySubtitle =
              'Không có hóa đơn nào khớp với từ khóa "${state.searchQuery}".';
        } else if (state.selectedTabIndex == 0) {
          emptyTitle = 'Không còn hóa đơn nợ';
          emptySubtitle =
              'Tất cả hóa đơn đã được thanh toán hoặc không có khoản nợ nào.';
        } else if (state.selectedTabIndex == 1) {
          emptyTitle = 'Chưa có hóa đơn thanh toán 1 phần';
          emptySubtitle =
              'Không có hóa đơn nào đang trong quá trình thanh toán dở dang.';
        } else if (state.selectedTabIndex == 2) {
          emptyTitle = 'Chưa có hóa đơn hoàn tất';
          emptySubtitle = 'Các hóa đơn thu đủ tiền sẽ xuất hiện tại đây.';
        }

        // `POST /invoices` chỉ mở cho ADMIN và CASHIER — lễ tân bị 403, hóa đơn
        // của lễ tân sinh tự động khi check-out (§3.6).
        final canCreateInvoice = context.currentRole.canCreateInvoice;

        return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: canCreateInvoice
          ? FloatingActionButton(
              onPressed: _showCreateInvoiceModal,
              backgroundColor: AppColors.primary,
              elevation: 6,
              child: const Icon(
                Icons.add,
                color: AppColors.secondaryLight,
                size: 28,
              ),
            )
          : null,
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: _fetchInvoices,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Dải Navy đầu màn (165px+)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppGradients.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.sheet),
                    bottomRight: Radius.circular(AppRadius.sheet),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (context.currentRole == UserRole.admin)
                                  _buildGlassCircleBtn(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () => _handleBack(context),
                                  ),
                                if (context.currentRole == UserRole.admin)
                                  const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hóa Đơn & Thu Quỹ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_getCurrentShift()} • ${Formatters.formatDate(DateTime.now())}',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.60,
                                          ),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Row(
                            children: [
                              // Đối chiếu tiền khách trả qua app — huy hiệu là
                              // số hóa đơn đang treo một yêu cầu PENDING.
                              if (context
                                  .currentRole
                                  .canConfirmPaymentRequest) ...[
                                _buildGlassCircleBtn(
                                  icon: Icons.fact_check_outlined,
                                  badgeCount: pendingRequestCount,
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const PaymentRequestsScreen(),
                                      ),
                                    );
                                    if (mounted) {
                                      await _fetchInvoices(isSilent: true);
                                    }
                                  },
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              if (context.currentRole.canCloseShift) ...[
                                _buildGlassCircleBtn(
                                  icon: Icons.account_balance_wallet_outlined,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ShiftCloseScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              _buildGlassCircleBtn(
                                icon: Icons.refresh,
                                onTap: _fetchInvoices,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Revenue Card with Mini 6-Bar Chart
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppRadius.cardSmall,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ĐÃ THU HÔM NAY',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.70,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          Formatters.formatCurrency(
                                            state.todayRevenue,
                                          ),
                                          style: const TextStyle(
                                            color: AppColors.secondaryLight,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                // Mini 6-bar gold chart
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildMiniBar(14),
                                    const SizedBox(width: 4),
                                    _buildMiniBar(20),
                                    const SizedBox(width: 4),
                                    _buildMiniBar(16),
                                    const SizedBox(width: 4),
                                    _buildMiniBar(28),
                                    const SizedBox(width: 4),
                                    _buildMiniBar(24),
                                    const SizedBox(width: 4),
                                    _buildMiniBar(36),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Sub-stats banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.pending_actions_rounded,
                                        size: 14,
                                        color: AppColors.secondaryLight,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Chờ thu: ${Formatters.formatCurrency(totalRemaining)} ($pendingCount HĐ)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Tổng thu: ${Formatters.formatCurrency(totalPaid)}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tiền khách đã bấm trả qua app nhưng chưa vào két.
                            if (pendingRequestCount > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.secondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Chờ đối chiếu: ${Formatters.formatCurrency(pendingRequestAmount)} ($pendingRequestCount HĐ)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // 2. Ô tìm kiếm + chip lọc — ghim lên đỉnh khi cuộn qua dải navy.
            SliverStickyHeader(
              contentHeight: InvoiceFilterBar.height,
              topInset: MediaQuery.paddingOf(context).top,
              child: InvoiceFilterBar(
                searchController: _searchController,
                searchQuery: state.searchQuery,
                onSearchChanged: (val) =>
                    _invoiceBloc.add(InvoiceSearchChanged(val)),
                onSearchClear: () {
                  _searchController.clear();
                  _invoiceBloc.add(const InvoiceSearchChanged(''));
                },
                tabs: _tabs,
                selectedTabIndex: state.selectedTabIndex,
                onTabSelected: (idx) =>
                    _invoiceBloc.add(InvoiceTabFilterChanged(idx)),
                getTabCount: _getTabCount,
                timeFilterLabel: context.currentRole == UserRole.admin
                    ? state.timeFilterDisplayLabel
                    : 'Tuần này (${CashierInvoicesScreen.formatCurrentWeekRange()})',
                canChangeTimeFilter: context.currentRole == UserRole.admin,
                onTimeFilterTap: context.currentRole == UserRole.admin
                    ? _showTimeFilterModal
                    : null,
              ),
            ),

            // 3. Invoice Cards / Skeletons / Empty State
            if (state.isLoading && invoices.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: InvoiceRowSkeleton(),
                    ),
                    childCount: 4,
                  ),
                ),
              )
            else if (!state.isLoading && filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: emptyTitle,
                    description: emptySubtitle,
                    actionText: 'Tải lại danh sách',
                    onAction: _fetchInvoices,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final inv = displayed[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: InvoiceCard(
                        invoice: inv,
                        onTap: () => _showInvoiceDetailSheet(inv),
                        onCollectPayment: () => _showPaymentModal(inv),
                        onViewReceipt: () => _showReceiptSheet(inv),
                      ),
                    );
                  }, childCount: displayed.length),
                ),
              ),

              // Footer: Load more / pagination indicator
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                  ),
                  child: _buildPaginationFooter(palette, filtered.length),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
      },
    );
  }

  Widget _buildPaginationFooter(AppPalette palette, int totalCount) {
    final isLoadingMore = _invoiceBloc.state.isLoadingMore;
    final displayedCount = _invoiceBloc.state.displayedCount;
    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Đang tải thêm... (Đã hiện ${displayedCount.clamp(0, totalCount)}/$totalCount)',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.inkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (displayedCount < totalCount) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label: Text(
              'Xem thêm 20 hóa đơn (Đã hiện ${displayedCount.clamp(0, totalCount)}/$totalCount)',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.accent,
              side: BorderSide(color: palette.accent.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
      );
    }

    if (totalCount > _pageSize) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 15,
                color: palette.inkMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Đã hiển thị tất cả $totalCount hóa đơn',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.inkMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMiniBar(double height) {
    return Container(
      width: 6,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildGlassCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    final button = PressableScale(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );

    if (badgeCount <= 0) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTimeFilterModal() {
    final palette = context.palette;
    final now = DateTime.now();
    final currentState = _invoiceBloc.state;
    int tempYear = currentState.selectedYear;
    int tempFromMonth = currentState.fromMonth;
    int tempToMonth = currentState.toMonth;
    String tempFilterType = currentState.currentTimeFilterType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            boxShadow: AppShadows.medium,
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: palette.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bộ Lọc Thời Gian Hóa Đơn',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: palette.inkMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Chọn mốc thời gian hiển thị hóa đơn (Quyền Quản trị viên):',
                  style: TextStyle(fontSize: 13, color: palette.inkMuted),
                ),
                const SizedBox(height: 16),

                _buildFilterOptionCard(
                  palette: palette,
                  isSelected: tempFilterType == 'week',
                  title: 'Tuần này (Mặc định)',
                  subtitle:
                      'Thứ 2 đến Chủ nhật của tuần hiện tại (${CashierInvoicesScreen.formatCurrentWeekRange()})',
                  icon: Icons.view_week_rounded,
                  onTap: () => setModalState(() => tempFilterType = 'week'),
                ),
                const SizedBox(height: 10),

                _buildFilterOptionCard(
                  palette: palette,
                  isSelected: tempFilterType == 'month_range',
                  title: 'Theo khoảng tháng',
                  subtitle:
                      'Tra cứu hóa đơn từ tháng này đến tháng khác và năm',
                  icon: Icons.date_range_rounded,
                  onTap: () =>
                      setModalState(() => tempFilterType = 'month_range'),
                  child: tempFilterType == 'month_range'
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Từ tháng:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: palette.inkMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButtonFormField<int>(
                                          initialValue: tempFromMonth,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.field,
                                                  ),
                                            ),
                                          ),
                                          items: List.generate(12, (i) => i + 1)
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(
                                                    'Tháng $m',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v != null) {
                                              setModalState(() {
                                                tempFromMonth = v;
                                                if (tempToMonth <
                                                    tempFromMonth) {
                                                  tempToMonth = tempFromMonth;
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Đến tháng:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: palette.inkMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        DropdownButtonFormField<int>(
                                          initialValue: tempToMonth,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 10,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.field,
                                                  ),
                                            ),
                                          ),
                                          items: List.generate(12, (i) => i + 1)
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(
                                                    'Tháng $m',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v != null) {
                                              setModalState(() {
                                                tempToMonth = v;
                                                if (tempFromMonth >
                                                    tempToMonth) {
                                                  tempFromMonth = tempToMonth;
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Năm áp dụng:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: palette.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 130,
                                    child: DropdownButtonFormField<int>(
                                      initialValue: tempYear,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.field,
                                          ),
                                        ),
                                      ),
                                      items:
                                          [
                                                now.year - 2,
                                                now.year - 1,
                                                now.year,
                                                now.year + 1,
                                              ]
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text(
                                                    'Năm $y',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) {
                                        if (v != null)
                                          setModalState(() => tempYear = v);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),

                _buildFilterOptionCard(
                  palette: palette,
                  isSelected: tempFilterType == 'year',
                  title: 'Theo năm',
                  subtitle: 'Chọn năm (ví dụ: ${now.year}, ${now.year - 1})',
                  icon: Icons.calendar_today_rounded,
                  onTap: () => setModalState(() => tempFilterType = 'year'),
                  child: tempFilterType == 'year'
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Text(
                                'Chọn năm:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.inkMuted,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 130,
                                child: DropdownButtonFormField<int>(
                                  initialValue: tempYear,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.field,
                                      ),
                                    ),
                                  ),
                                  items:
                                      [
                                            now.year - 2,
                                            now.year - 1,
                                            now.year,
                                            now.year + 1,
                                          ]
                                          .map(
                                            (y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(
                                                'Năm $y',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) {
                                    if (v != null)
                                      setModalState(() => tempYear = v);
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: PressableScale(
                    onTap: () {
                      Navigator.pop(ctx);
                      final String label;
                      if (tempFilterType == 'week') {
                        label = 'Tuần này';
                      } else if (tempFilterType == 'year') {
                        label = 'Năm $tempYear';
                      } else {
                        label = tempFromMonth == tempToMonth
                            ? 'Tháng $tempFromMonth/$tempYear'
                            : 'T$tempFromMonth - T$tempToMonth/$tempYear';
                      }
                      _invoiceBloc.add(InvoiceFetchRequested(
                        filterType: tempFilterType,
                        year: tempYear,
                        fromMonth: tempFromMonth,
                        toMonth: tempToMonth,
                        weekOffset: 0,
                        timeFilterDisplayLabel: label,
                      ));
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        boxShadow: AppShadows.goldGlow,
                      ),
                      child: const Text(
                        'Áp Dụng Bộ Lọc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptionCard({
    required AppPalette palette,
    required bool isSelected,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? child,
  }) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.08)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? palette.accent : palette.inkMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected ? palette.accent : palette.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? palette.accent : palette.inkMuted,
                  size: 20,
                ),
              ],
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}
