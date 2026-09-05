import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/invoice_model.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/skeletons/invoice_row_skeleton.dart';
import '../../cashier/widgets/invoice_card.dart';
import '../../cashier/widgets/invoice_detail_sheet.dart';

/// Tab "Hóa đơn của tôi" của app khách hàng.
///
/// Khách chỉ đọc `GET /invoices/my` và tự gửi yêu cầu trả tiền qua
/// `POST /invoices/:id/payment-requests` — endpoint duy nhất ở nhóm hóa đơn mà
/// CUSTOMER được ghi (`design/FE-ROLE-MATRIX.md` §3.6). Tuyệt đối không gọi
/// `GET /invoices` (danh sách toàn khách sạn) hay `POST /invoices/:id/pay`:
/// cả hai đều trả `403` cho khách.
///
/// Số còn phải trả đọc thẳng `remainingAmount` của máy chủ; nút thanh toán bám
/// theo cờ `canRequestPayment`.
class MyInvoicesScreen extends StatefulWidget {
  final DioClient? dioClient;
  final InvoiceRepository? invoiceRepository;

  const MyInvoicesScreen({
    super.key,
    this.dioClient,
    this.invoiceRepository,
  });

  @override
  State<MyInvoicesScreen> createState() => _MyInvoicesScreenState();
}

class _MyInvoicesScreenState extends State<MyInvoicesScreen> {
  DioClient get _dioClient => widget.dioClient ?? DioClient();

  late final InvoiceRepository _invoiceRepo =
      widget.invoiceRepository ?? InvoiceRepository(dioClient: _dioClient);

  List<InvoiceModel> _invoices = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _selectedTabIndex = 0; // 0: Chưa thanh toán, 1: Đã hoàn tất, 2: Tất cả

  /// Id hóa đơn đang gửi yêu cầu thanh toán — khóa nút để không gửi hai lần.
  String? _requestingInvoiceId;

  static const List<String> _tabs = ['Chưa thanh toán', 'Đã hoàn tất', 'Tất cả'];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices({bool isSilent = false}) async {
    if (mounted && !isSilent && _invoices.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await _dioClient.dio.get(ApiEndpoints.invoicesMy);
      final list = ApiResult.unwrapList(res);
      if (mounted) {
        setState(() {
          _invoices = list
              .map((e) => InvoiceModel.fromJson(e))
              .toList();
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    } catch (_) {
      // Rơi xuống nhánh lỗi bên dưới.
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = _invoices.isEmpty;
      });
    }
  }

  List<InvoiceModel> get _visibleInvoices {
    switch (_selectedTabIndex) {
      case 0:
        return _invoices.where((i) => i.remainingAmount > 0).toList();
      case 1:
        return _invoices.where((i) => i.remainingAmount <= 0).toList();
      default:
        return _invoices;
    }
  }

  num get _totalOutstanding => _invoices.fold<num>(
        0,
        (sum, i) => sum + i.remainingAmount,
      );

  /// Xem chi tiết `GET /invoices/:id` — khách mở được nhưng chỉ hóa đơn thuộc
  /// đơn của mình, nên luôn điều hướng từ danh sách này thay vì nhập id.
  void _showDetail(InvoiceModel invoice) {
    InvoiceDetailSheet.show(
      context: context,
      invoice: invoice,
      onPrintReceipt: () => Navigator.of(context).maybePop(),
      // onCollectPayment bỏ trống: khách không được ghi nhận thanh toán.
      onRequestPayment: () {
        Navigator.of(context).maybePop();
        _requestFullPayment(invoice);
      },
    );
  }

  /// Khách bấm "Thanh toán toàn bộ": `POST /invoices/:id/payment-requests` với
  /// `amount` bỏ trống — máy chủ tự lấy đúng số còn lại nên không bao giờ lệch
  /// với `remainingAmount` đang hiển thị.
  ///
  /// Tiền chưa vào két ngay: máy chủ tạo một dòng `PENDING`, lễ tân đối chiếu
  /// sao kê rồi xác nhận thì `paidAmount` mới tăng.
  Future<void> _requestFullPayment(InvoiceModel invoice) async {
    if (_requestingInvoiceId != null) return;
    setState(() => _requestingInvoiceId = invoice.id);

    try {
      await _invoiceRepo.createPaymentRequest(
        invoice.id,
        paymentMethod: 'BANK_TRANSFER',
      );
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        'Đã gửi yêu cầu thanh toán ${Formatters.formatCurrency(invoice.remainingAmount)}. '
        'Lễ tân sẽ đối chiếu và xác nhận.',
      );
      // Nạp lại để lấy dòng PENDING và cờ canRequestPayment mới từ máy chủ.
      await _fetchInvoices(isSilent: true);
    } catch (e) {
      if (!mounted) return;
      AppNotification.showError(
        context,
        e,
        title: 'Gửi yêu cầu thanh toán thất bại',
      );
    } finally {
      if (mounted) setState(() => _requestingInvoiceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final visible = _visibleInvoices;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: _fetchInvoices,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(palette)),
            SliverToBoxAdapter(child: _buildFilterBar(palette)),
            if (_isLoading && _invoices.isEmpty)
              SliverList.builder(
                itemCount: 4,
                itemBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.sm,
                  ),
                  child: InvoiceRowSkeleton(),
                ),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _hasError
                        ? 'Không tải được hóa đơn'
                        : 'Chưa có hóa đơn nào',
                    description: _hasError
                        ? 'Kiểm tra kết nối mạng rồi thử lại.'
                        : 'Hóa đơn sẽ xuất hiện sau khi bạn trả phòng.',
                    actionText: 'Tải lại',
                    onAction: _fetchInvoices,
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screen,
                    vertical: AppSpacing.sm,
                  ),
                  child: InvoiceCard(
                    invoice: visible[i],
                    onTap: () => _showDetail(visible[i]),
                    // Không truyền onCollectPayment — ẩn nút thu tiền của quầy.
                    onRequestPayment: () => _requestFullPayment(visible[i]),
                    isRequestingPayment:
                        _requestingInvoiceId == visible[i].id,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Hóa Đơn Của Tôi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_invoices.length} hóa đơn',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÒN PHẢI THANH TOÁN',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.60),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Formatters.formatCurrency(_totalOutstanding),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(AppPalette palette) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _buildFilterChip(palette, i),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(AppPalette palette, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent : palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
          ),
        ),
        child: Text(
          _tabs[index],
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : palette.inkMuted,
          ),
        ),
      ),
    );
  }
}
