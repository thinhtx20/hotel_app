import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
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
import '../widgets/invoice_card.dart';
import '../widgets/invoice_detail_sheet.dart';
import '../widgets/invoice_filter_bar.dart';
import '../widgets/payment_sheet.dart';

class CashierInvoicesScreen extends StatefulWidget {
  const CashierInvoicesScreen({super.key});

  @override
  State<CashierInvoicesScreen> createState() => _CashierInvoicesScreenState();
}

class _CashierInvoicesScreenState extends State<CashierInvoicesScreen> {
  int _selectedTabIndex = 0; // 0: Chưa thanh toán, 1: Thanh toán 1 phần, 2: Đã hoàn tất, 3: Tất cả
  List<InvoiceModel> _invoices = [];
  num _todayRevenue = 0;
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = [
    'Chưa thanh toán',
    'Thanh toán 1 phần',
    'Đã hoàn tất',
    'Tất cả',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    try {
      final invoiceRepo = sl<InvoiceRepository>();
      final invoices = await invoiceRepo.fetchAll();

      // Lấy todayRevenue chính xác từ endpoint summary của backend
      num summaryTodayRevenue = 0;
      try {
        final sData = await invoiceRepo.fetchSummary();
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
            localTodayPaid += txn.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          _invoices = invoices;
          _todayRevenue = summaryTodayRevenue > 0
              ? summaryTodayRevenue
              : localTodayPaid;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotification.showError(
          context,
          e,
          title: 'Tải danh sách hóa đơn thất bại',
        );
      }
    }
  }

  int _getTabCount(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'UNPAID' ||
                (i.paidAmount == 0 && i.remainingAmount > 0))
            .length;
      case 1:
        return _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PARTIAL' ||
                (i.paidAmount > 0 &&
                    i.remainingAmount > 0 &&
                    i.paymentStatus.toUpperCase() != 'UNPAID'))
            .length;
      case 2:
        return _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PAID' ||
                (i.remainingAmount <= 0 && i.finalAmount > 0))
            .length;
      case 3:
        return _invoices.length;
      default:
        return 0;
    }
  }

  List<InvoiceModel> _getFilteredInvoices() {
    List<InvoiceModel> list;
    switch (_selectedTabIndex) {
      case 0:
        list = _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'UNPAID' ||
                (i.paidAmount == 0 && i.remainingAmount > 0))
            .toList();
        break;
      case 1:
        list = _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PARTIAL' ||
                (i.paidAmount > 0 &&
                    i.remainingAmount > 0 &&
                    i.paymentStatus.toUpperCase() != 'UNPAID'))
            .toList();
        break;
      case 2:
        list = _invoices
            .where((i) =>
                i.paymentStatus.toUpperCase() == 'PAID' ||
                (i.remainingAmount <= 0 && i.finalAmount > 0))
            .toList();
        break;
      default:
        list = List.from(_invoices);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((inv) {
        final code = inv.displayCode.toLowerCase();
        final guest = (inv.customerName ?? '').toLowerCase();
        final room = (inv.roomNumber ?? '').toLowerCase();
        return code.contains(q) || guest.contains(q) || room.contains(q);
      }).toList();
    }

    return list;
  }

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
    );
  }

  void _showPaymentModal(InvoiceModel invoice) {
    PaymentSheet.show(
      context: context,
      invoice: invoice,
      onConfirmPayment: ({
        required num amount,
        required String paymentMethod,
        required String notes,
      }) async {
        try {
          final updated = await sl<InvoiceRepository>().pay(
            invoice.id,
            amount: amount,
            paymentMethod: paymentMethod,
            paymentStatus:
                amount >= invoice.remainingAmount ? 'PAID' : 'PARTIAL',
            notes: notes.isNotEmpty ? notes : null,
          );
          if (!mounted) return;
          setState(() {
            final idx = _invoices.indexWhere((i) => i.id == invoice.id);
            if (idx != -1) {
              _invoices[idx] = updated;
            }
            _todayRevenue += amount;
          });
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

  void _showReceiptSheet(InvoiceModel invoice, {PaymentTransactionModel? lastTxn}) {
    final palette = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                      Icon(Icons.hotel_class_rounded, color: palette.accent, size: 36),
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
                      _buildReceiptRow('Số biên lai', lastTxn?.id ?? 'REC-${invoice.displayCode}'),
                      _buildReceiptRow('Mã hóa đơn', '#${invoice.displayCode}'),
                      _buildReceiptRow('Thời gian', Formatters.formatDateTime(lastTxn?.timestamp ?? DateTime.now())),
                      _buildReceiptRow('Thu ngân', lastTxn?.cashierName ?? 'Thu ngân ${_getCurrentShift()}'),
                      Divider(height: 20, color: palette.divider),

                      _buildReceiptRow('Khách hàng', invoice.customerName ?? 'Khách vãng lai', isBold: true),
                      _buildReceiptRow('Số phòng', 'Phòng ${invoice.roomNumber ?? "N/A"}'),
                      Divider(height: 20, color: palette.divider),

                      // Financial summary
                      _buildReceiptRow('Tổng cộng hóa đơn', Formatters.formatCurrency(invoice.finalAmount)),
                      _buildReceiptRow('Đã thanh toán', Formatters.formatCurrency(invoice.paidAmount), color: palette.statusAvailable, isBold: true),
                      if (lastTxn != null)
                        _buildReceiptRow('Số tiền vừa thu', Formatters.formatCurrency(lastTxn.amount), color: palette.accent, isBold: true),
                      _buildReceiptRow('Phương thức', _getMethodLabel(lastTxn?.paymentMethod ?? invoice.paymentMethod ?? 'TIỀN MẶT')),
                      if (invoice.remainingAmount > 0)
                        _buildReceiptRow('Số dư còn thiếu', Formatters.formatCurrency(invoice.remainingAmount), color: palette.error, isBold: true)
                      else
                        _buildReceiptRow('Trạng thái', 'ĐÃ HOÀN TẤT (100%)', color: palette.statusAvailable, isBold: true),

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
                            Icon(Icons.verified_rounded, size: 16, color: palette.statusAvailable),
                            const SizedBox(width: 6),
                            Text(
                              'Hóa đơn điện tử hợp lệ của Luxe Grand Hotel',
                              style: TextStyle(fontSize: 11, color: palette.inkMuted),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
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
                          content: Text('Đang gửi lệnh in biên lai tới máy in POS...'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang gửi lệnh in biên lai tới máy in POS...'),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
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

  Widget _buildReceiptRow(String title, String val, {bool isBold = false, Color? color}) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: palette.inkMuted),
          ),
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
    final itemTitleController = TextEditingController(text: 'Phụ phí dịch vụ phát sinh');
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRoom,
                        dropdownColor: palette.surface,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                        items: const [
                          DropdownMenuItem(value: '101', child: Text('Phòng 101 (Tầng 1)')),
                          DropdownMenuItem(value: '108', child: Text('Phòng 108 (Lê Văn Cường)')),
                          DropdownMenuItem(value: '203', child: Text('Phòng 203 (Nguyễn Văn A)')),
                          DropdownMenuItem(value: '205', child: Text('Phòng 205 (Hoàng Minh Tuấn)')),
                          DropdownMenuItem(value: '301', child: Text('Phòng 301 (Nguyễn Văn A)')),
                          DropdownMenuItem(value: '402', child: Text('Phòng 402 (Trần Thị Bích)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedRoom = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Tên khách hàng
                      Text(
                        'Tên khách hàng:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customerController,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Danh mục phụ phí
                      Text(
                        'Danh mục khoản thu:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        dropdownColor: palette.surface,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                        items: categories
                            .map((c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['name']!),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedCategory = val;
                              final cat = categories.firstWhere((c) => c['id'] == val);
                              itemTitleController.text = cat['name']!;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Diễn giải khoản mục
                      Text(
                        'Tên chi tiết khoản thu:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: itemTitleController,
                        style: TextStyle(color: palette.ink, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Số tiền
                      Text(
                        'Số tiền (VND):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          prefixIcon: Icon(Icons.attach_money, color: palette.accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Nút tạo hóa đơn
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: PressableScale(
                  onTap: () async {
                    final amt = Formatters.parseCurrency(amountController.text) ?? 0;
                    if (amt <= 0) {
                      AppNotification.showWarning(context, 'Vui lòng nhập số tiền hợp lệ');
                      return;
                    }

                    Navigator.pop(ctx);

                    try {
                      final payload = {
                        'roomNumber': selectedRoom,
                        'customerName': customerController.text.trim().isNotEmpty
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
                          }
                        ],
                      };
                      final created = await sl<InvoiceRepository>().create(payload);
                      if (mounted) {
                        setState(() {
                          _invoices.insert(0, created);
                          _selectedTabIndex = 0;
                        });
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filtered = _getFilteredInvoices();
    final totalPaid = _invoices.fold<num>(
      0,
      (sum, inv) => sum + inv.paidAmount,
    );
    final totalRemaining = _invoices.fold<num>(
      0,
      (sum, inv) => sum + inv.remainingAmount,
    );
    final pendingCount = _invoices.where((i) => i.remainingAmount > 0).length;

    String emptyTitle = 'Không có hóa đơn nào';
    String emptySubtitle = 'Hiện tại không tìm thấy hóa đơn phù hợp.';
    if (_searchQuery.isNotEmpty) {
      emptyTitle = 'Không tìm thấy kết quả';
      emptySubtitle = 'Không có hóa đơn nào khớp với từ khóa "$_searchQuery".';
    } else if (_selectedTabIndex == 0) {
      emptyTitle = 'Không còn hóa đơn nợ';
      emptySubtitle = 'Tất cả hóa đơn đã được thanh toán hoặc không có khoản nợ nào.';
    } else if (_selectedTabIndex == 1) {
      emptyTitle = 'Chưa có hóa đơn thanh toán 1 phần';
      emptySubtitle = 'Không có hóa đơn nào đang trong quá trình thanh toán dở dang.';
    } else if (_selectedTabIndex == 2) {
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dải Navy đầu màn (165px+)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppGradients.navy,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.sheet),
                    bottomRight: Radius.circular(AppRadius.sheet),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Top Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thu Ngân',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_getCurrentShift()} • ${Formatters.formatDate(DateTime.now())}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.60),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildGlassCircleBtn(
                                icon: Icons.refresh,
                                onTap: _fetchInvoices,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _buildGlassCircleBtn(
                                icon: Icons.logout,
                                onTap: () => LogoutConfirmationDialog.show(context),
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
                          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ĐÃ THU HÔM NAY',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.70),
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
                                          Formatters.formatCurrency(_todayRevenue),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.pending_actions_rounded, size: 14, color: AppColors.secondaryLight),
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
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Search & Filter Bar
              InvoiceFilterBar(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                onSearchClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                tabs: _tabs,
                selectedTabIndex: _selectedTabIndex,
                onTabSelected: (idx) => setState(() => _selectedTabIndex = idx),
                getTabCount: _getTabCount,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Invoice Cards / Skeletons / Empty State
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: _isLoading && _invoices.isEmpty
                    ? Column(
                        children: List.generate(
                          4,
                          (index) => const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.md),
                            child: InvoiceRowSkeleton(),
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? AppEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: emptyTitle,
                            description: emptySubtitle,
                            actionText: 'Tải lại danh sách',
                            onAction: _fetchInvoices,
                          )
                        : Column(
                            children: filtered.map((inv) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: InvoiceCard(
                                  invoice: inv,
                                  onTap: () => _showInvoiceDetailSheet(inv),
                                  onCollectPayment: () => _showPaymentModal(inv),
                                  onViewReceipt: () => _showReceiptSheet(inv),
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
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
  }) {
    return PressableScale(
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
  }
}
