import '../../../core/utils/vietnamese_search_helper.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/skeleton_primitives.dart';
import '../widgets/walk_in_check_in_modal.dart';

class BookingApprovalScreen extends StatefulWidget {
  const BookingApprovalScreen({super.key});

  @override
  State<BookingApprovalScreen> createState() => _BookingApprovalScreenState();
}

class _BookingApprovalScreenState extends State<BookingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late final BookingRepository _bookingRepository;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _refreshIconController;

  int _selectedTabIndex = 0; // 0: Chờ duyệt, 1: Đã duyệt / Giữ chỗ, 2: Đang lưu trú, 3: Đã hủy
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSlowResponse = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  final Set<String> _processingIds = {};
  Timer? _searchDebounce;
  Timer? _slowResponseTimer;
  int _fetchToken = 0;

  final List<String> _tabs = const [
    'Chờ duyệt',
    'Đã duyệt',
    'Đang ở',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _bookingRepository = sl<BookingRepository>();
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _searchController.addListener(_onSearchChanged);

    // Vẽ ngay danh sách của lần tải trước trong phiên này rồi mới làm mới ngầm,
    // nhờ vậy mở lại tab "Duyệt đơn" không phải chờ mạng thêm lần nữa.
    _bookings = _bookingRepository.cachedBookings.toList();
    _fetchBookings();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _slowResponseTimer?.cancel();
    _searchController.dispose();
    _refreshIconController.dispose();
    super.dispose();
  }

  /// Hoãn việc lọc lại danh sách tới khi người dùng ngừng gõ; nút xóa trong ô
  /// tìm kiếm tự cập nhật riêng qua [ValueListenableBuilder] nên vẫn nhạy.
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      if (!mounted || query == _searchQuery) return;
      setState(() => _searchQuery = query);
    });
  }

  Future<void> _fetchBookings({bool isSilent = false}) async {
    final token = ++_fetchToken;
    final showSkeleton = !isSilent && _bookings.isEmpty;
    if (showSkeleton) {
      setState(() {
        _isLoading = true;
        _isSlowResponse = false;
        _errorMessage = null;
      });
      // Máy chủ trên Render ngủ sau một lúc không ai gọi, request đánh thức
      // đầu tiên mất hàng chục giây — báo cho lễ tân biết thay vì để họ đoán.
      _slowResponseTimer?.cancel();
      _slowResponseTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted || !_isLoading) return;
        setState(() => _isSlowResponse = true);
      });
    }
    _refreshIconController.repeat();

    try {
      // Màn này tự chia tab theo trạng thái nên phải gom đủ mọi trang.
      final list = await _bookingRepository.fetchAllBookings();
      if (!mounted || token != _fetchToken) return;
      setState(() {
        _bookings = list;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted || token != _fetchToken) return;
      final apiErr = ApiError.fromDynamic(e);
      setState(() {
        if (_bookings.isEmpty) {
          _errorMessage = apiErr.displayMessage;
        }
        _isLoading = false;
      });
      if (isSilent || _bookings.isNotEmpty) {
        AppNotification.showError(context, e, title: 'Làm mới danh sách thất bại');
      }
    } finally {
      if (mounted && token == _fetchToken) {
        _slowResponseTimer?.cancel();
        _isSlowResponse = false;
        _refreshIconController.stop();
        _refreshIconController.reset();
      }
    }
  }

  List<BookingModel> get _filteredBookings {
    var list = _bookings;
    if (_selectedTabIndex == 0) {
      list = list.where((b) => b.status == 'PENDING').toList();
    } else if (_selectedTabIndex == 1) {
      list = list.where((b) => b.status == 'CONFIRMED').toList();
    } else if (_selectedTabIndex == 2) {
      list = list.where((b) => b.status == 'CHECKED_IN').toList();
    } else if (_selectedTabIndex == 3) {
      list = list.where((b) => b.status == 'CANCELLED').toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((b) {
        return VietnameseSearchHelper.matchesAny([
          b.bookingCode,
          b.customerName,
          b.customerPhone,
          b.roomNumber,
          b.roomTypeName,
        ], _searchQuery);
      }).toList();
    }

    return list;
  }

  void _showApproveDialog(BookingModel booking) {
    final palette = context.palette;
    final totalAmount = booking.totalAmount;
    final isOver5Mil = totalAmount > 5000000;
    final suggestedDeposit = isOver5Mil ? (totalAmount * 0.1).round() : 0;
    final depositController = TextEditingController(
      text: booking.depositAmount > 0
          ? '${booking.depositAmount.toInt()}'
          : (suggestedDeposit > 0 ? '$suggestedDeposit' : '0'),
    );
    final notesController = TextEditingController(
      text: isOver5Mil
          ? 'Lễ tân xác nhận đã nhận cọc 10% qua QR'
          : 'Đơn dưới 5tr miễn cọc - thanh toán khi nhận phòng',
    );
    String selectedMethod = 'BANK_TRANSFER';
    bool isSubmitting = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AppBottomSheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.secondaryDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phê Duyệt Đơn Đặt Phòng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            'Mã đơn: #${booking.displayCode}',
                            style: TextStyle(fontSize: 12, color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Thông tin tóm tắt đơn
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      _buildModalSummaryRow('Khách hàng:', booking.customerName ?? 'Khách vãng lai', palette),
                      const SizedBox(height: 6),
                      _buildModalSummaryRow('Phòng:', 'Phòng ${booking.roomNumber ?? "---"} • ${booking.roomTypeName ?? "Tiêu chuẩn"}', palette),
                      const SizedBox(height: 6),
                      _buildModalSummaryRow('Thời gian:', '${Formatters.formatDate(booking.checkInDate)} - ${Formatters.formatDate(booking.checkOutDate)}', palette),
                      const SizedBox(height: 6),
                      _buildModalSummaryRow('Tổng tiền phòng:', Formatters.formatCurrency(totalAmount), palette, isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Ô nhập tiền cọc
                Text(
                  'SỐ TIỀN CỌC XÁC NHẬN (VNĐ)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.inkFaint, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: depositController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.accent),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.payments_outlined, color: palette.accent),
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(fontWeight: FontWeight.w700, color: palette.inkMuted),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
                const SizedBox(height: 8),

                // Chip chọn nhanh phần trăm tiền cọc
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildDepositChip(
                      isOver5Mil ? 'Chuẩn 10% (>5tr)' : 'Miễn cọc (<5tr)',
                      () {
                        setModalState(() => depositController.text = '$suggestedDeposit');
                      },
                      palette,
                    ),
                    _buildDepositChip('Không cọc (0đ)', () {
                      setModalState(() => depositController.text = '0');
                    }, palette),
                    _buildDepositChip('Cọc 10%', () {
                      setModalState(() => depositController.text = '${(totalAmount * 0.1).round()}');
                    }, palette),
                    _buildDepositChip('Cọc 30%', () {
                      setModalState(() => depositController.text = '${(totalAmount * 0.3).round()}');
                    }, palette),
                    _buildDepositChip('Toàn bộ (100%)', () {
                      setModalState(() => depositController.text = '${totalAmount.round()}');
                    }, palette),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Phương thức thanh toán cọc
                Text(
                  'PHƯƠNG THỨC THANH TOÁN TIỀN CỌC',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.inkFaint, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodRadio('Chuyển khoản', 'BANK_TRANSFER', Icons.account_balance_outlined, selectedMethod, (val) {
                        setModalState(() => selectedMethod = val);
                      }, palette),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMethodRadio('Tiền mặt', 'CASH', Icons.money_rounded, selectedMethod, (val) {
                        setModalState(() => selectedMethod = val);
                      }, palette),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMethodRadio('Thẻ', 'CREDIT_CARD', Icons.credit_card_rounded, selectedMethod, (val) {
                        setModalState(() => selectedMethod = val);
                      }, palette),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Ghi chú duyệt đơn
                Text(
                  'GHI CHÚ PHÊ DUYỆT (TÙY CHỌN)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.inkFaint, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, color: palette.ink),
                  decoration: InputDecoration(
                    hintText: 'VD: Khách đã chuyển khoản cọc VietQR thành công...',
                    hintStyle: TextStyle(fontSize: 12, color: palette.inkMuted),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Nút bấm duyệt đơn
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: PressableScale(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final depAmount = num.tryParse(depositController.text.trim()) ?? 0;
                            setModalState(() => isSubmitting = true);

                            try {
                              final updated = await _bookingRepository.approveBooking(
                                booking.id,
                                depositAmount: depAmount,
                                paymentMethod: selectedMethod,
                                notes: notesController.text.trim(),
                              );

                              if (!mounted) return;
                              setState(() {
                                final idx = _bookings.indexWhere((b) => b.id == booking.id);
                                if (idx != -1) {
                                  _bookings[idx] = updated;
                                }
                              });

                              if (ctx.mounted) Navigator.pop(ctx);

                              if (mounted) {
                                AppNotification.showSuccess(
                                  context,
                                  'Đã phê duyệt đơn #${booking.displayCode} thành công! Phòng đã chuyển sang trạng thái ĐÃ CỌC (RESERVED).',
                                  title: 'Duyệt đơn thành công',
                                );
                              }
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                AppNotification.showError(context, e, title: 'Duyệt đơn thất bại');
                              }
                            }
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        boxShadow: AppShadows.goldGlow,
                      ),
                      alignment: Alignment.center,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Xác Nhận Phê Duyệt & Nhận Cọc',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectDialog(BookingModel booking) {
    final palette = context.palette;
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    final quickReasons = const [
      'Khách sạn đã hết phòng trong thời gian này',
      'Không liên lạc được với khách để xác nhận cọc',
      'Khách hàng chủ động gọi yêu cầu hủy đơn',
      'Thông tin đặt phòng không chính xác',
    ];

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.cancel_outlined, color: palette.error, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Từ Chối Đơn Đặt Phòng',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink),
                        ),
                        Text(
                          'Khách hàng: ${booking.customerName ?? ""} • Đơn: #${booking.displayCode}',
                          style: TextStyle(fontSize: 12, color: palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Chọn lý do từ chối nhanh:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.inkMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: quickReasons.map((qr) {
                  return ActionChip(
                    label: Text(qr, style: const TextStyle(fontSize: 11)),
                    backgroundColor: palette.surfaceMuted,
                    side: BorderSide(color: palette.border),
                    onPressed: () {
                      setModalState(() => reasonController.text = qr);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: reasonController,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: palette.ink),
                decoration: InputDecoration(
                  labelText: 'Lý do từ chối cụ thể',
                  hintText: 'Nhập lý do gửi thông báo cho khách hàng...',
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: PressableScale(
                  onTap: isSubmitting
                      ? null
                      : () async {
                          final reason = reasonController.text.trim().isEmpty
                              ? 'Khách sạn đã hết phòng phù hợp trong thời gian yêu cầu.'
                              : reasonController.text.trim();

                          setModalState(() => isSubmitting = true);
                          try {
                            final updated = await _bookingRepository.rejectBooking(booking.id, reason: reason);
                            if (!mounted) return;
                            setState(() {
                              final idx = _bookings.indexWhere((b) => b.id == booking.id);
                              if (idx != -1) {
                                _bookings[idx] = updated;
                              }
                            });

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              AppNotification.showSuccess(
                                context,
                                'Đã từ chối đơn đặt phòng. Phòng được giải phóng về trạng thái trống (AVAILABLE).',
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                            if (mounted) {
                              AppNotification.showError(context, e, title: 'Từ chối đơn thất bại');
                            }
                          }
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.error,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    alignment: Alignment.center,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Xác Nhận Từ Chối Đơn',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkInBooking(BookingModel booking) async {
    final palette = context.palette;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: const Text('Xác nhận nhận phòng'),
        content: Text('Xác nhận khách hàng ${booking.customerName ?? ""} đã tới sảnh và nhận Phòng ${booking.roomNumber ?? ""} ngay bây giờ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: palette.statusAvailable),
            child: const Text('Nhận phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processingIds.add(booking.id));
    try {
      final updated = await _bookingRepository.checkIn(booking.id);
      if (!mounted) return;
      setState(() {
        _processingIds.remove(booking.id);
        final idx = _bookings.indexWhere((b) => b.id == booking.id);
        if (idx != -1) {
          _bookings[idx] = updated;
        }
      });
      AppNotification.showSuccess(context, 'Khách hàng đã nhận phòng thành công!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(booking.id));
      AppNotification.showError(context, e, title: 'Nhận phòng thất bại');
    }
  }

  Widget _buildModalSummaryRow(String label, String value, AppPalette palette, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: palette.inkFaint)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? palette.accent : palette.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildDepositChip(String text, VoidCallback onTap, AppPalette palette) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: palette.border),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.inkMuted)),
      ),
    );
  }

  Widget _buildMethodRadio(
    String label,
    String value,
    IconData icon,
    String selectedValue,
    Function(String) onSelect,
    AppPalette palette,
  ) {
    final isSelected = selectedValue == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent.withValues(alpha: 0.12) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? palette.accent : palette.inkMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? palette.accent : palette.inkMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filteredBookings;

    // Đếm 4 trạng thái trong một lượt duyệt thay vì bốn lượt `where` riêng.
    var pendingCount = 0;
    var confirmedCount = 0;
    var checkedInCount = 0;
    var cancelledCount = 0;
    for (final booking in _bookings) {
      switch (booking.status) {
        case 'PENDING':
          pendingCount++;
        case 'CONFIRMED':
          confirmedCount++;
        case 'CHECKED_IN':
          checkedInCount++;
        case 'CANCELLED':
          cancelledCount++;
      }
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await WalkInCheckInModal.show(
            context: context,
            onSuccess: () => _fetchBookings(isSilent: true),
          );
          if (result != null && mounted) {
            _fetchBookings(isSilent: true);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Đặt phòng tại quầy (Walk-in)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Dải Header Navy phong cách Lễ tân
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.secondaryLight, width: 1),
                            ),
                            child: const Text(
                              'LỄ TÂN & QUẢN TRỊ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryDark,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: palette.error,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '$pendingCount đơn mới',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phê Duyệt Đặt Phòng',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: RotationTransition(
                          turns: _refreshIconController,
                          child: Icon(Icons.refresh_rounded, color: palette.ink),
                        ),
                        onPressed: _fetchBookings,
                      ),
                      if (context.canPop())
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: palette.ink),
                          onPressed: () => context.pop(),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Ô Tìm Kiếm
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: TextField(
                controller: _searchController,
                style: TextStyle(fontSize: 13, color: palette.ink),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên khách, SĐT, mã đặt phòng...',
                  hintStyle: TextStyle(fontSize: 12.5, color: palette.inkMuted),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: palette.inkMuted),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (_, value, _) => value.text.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          ),
                  ),
                  filled: true,
                  fillColor: palette.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Thanh 4 Tabs Phân Loại
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final isSelected = idx == _selectedTabIndex;
                  int count = 0;
                  if (idx == 0) count = pendingCount;
                  if (idx == 1) count = confirmedCount;
                  if (idx == 2) count = checkedInCount;
                  if (idx == 3) count = cancelledCount;

                  return PressableScale(
                    onTap: () => setState(() => _selectedTabIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.gold : null,
                        color: isSelected ? null : palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected ? null : Border.all(color: palette.border),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tabs[idx],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : palette.inkMuted,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.3) : palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : palette.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Danh Sách Đơn Đặt Phòng
            Expanded(
              child: _isLoading
                  ? Column(
                      children: [
                        if (_isSlowResponse)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.screen,
                              right: AppSpacing.screen,
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Máy chủ đang khởi động lại, lần tải đầu có thể mất tới 1 phút...',
                                    style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                            itemCount: 4,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (_, _) => const SkeletonBox(width: double.infinity, height: 160, borderRadius: 16),
                          ),
                        ),
                      ],
                    )
                  : _errorMessage != null && _bookings.isEmpty
                      ? AppEmptyState(
                          icon: Icons.cloud_off_rounded,
                          title: 'Không thể tải danh sách đơn',
                          description: _errorMessage!,
                          actionText: 'Tải lại',
                          onAction: _fetchBookings,
                        )
                      : filtered.isEmpty
                          ? AppEmptyState(
                              icon: Icons.fact_check_outlined,
                              title: 'Không có đơn nào',
                              description: _selectedTabIndex == 0
                                  ? 'Hiện tại không có đơn khách đặt trước nào cần duyệt!'
                                  : 'Không tìm thấy đơn nào trong mục "${_tabs[_selectedTabIndex]}".',
                              actionText: 'Làm mới',
                              onAction: _fetchBookings,
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchBookings,
                              color: palette.accent,
                              child: ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.screen,
                                  vertical: AppSpacing.xs,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final booking = filtered[index];
                                  return _buildBookingCard(booking, palette);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, AppPalette palette) {
    final isPending = booking.status == 'PENDING';
    final isConfirmed = booking.status == 'CONFIRMED';
    final isProcessing = _processingIds.contains(booking.id);

    final nights = booking.checkOutDate.difference(booking.checkInDate).inDays;
    final nightsStr = nights > 0 ? '$nights đêm' : '1 đêm';

    Color statusColor = palette.statusAvailable;
    String statusLabel = 'Đang chờ duyệt';

    if (booking.status == 'PENDING') {
      statusColor = AppColors.amberDark;
      statusLabel = 'Chờ duyệt cọc';
    } else if (booking.status == 'CONFIRMED') {
      statusColor = AppColors.secondary;
      statusLabel = 'Đã duyệt / Giữ chỗ';
    } else if (booking.status == 'CHECKED_IN') {
      statusColor = palette.statusAvailable;
      statusLabel = 'Đang lưu trú';
    } else if (booking.status == 'CANCELLED') {
      statusColor = palette.error;
      statusLabel = 'Đã hủy / Từ chối';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Mã đơn + Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(color: palette.border),
                    ),
                    child: Text(
                      '#${booking.displayCode}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    booking.createdAt != null
                        ? Formatters.formatDateTime(booking.createdAt!)
                        : '',
                    style: TextStyle(fontSize: 11, color: palette.inkFaint),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: palette.divider, height: 20),

          // Row 2: Khách hàng
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  booking.customerName != null && booking.customerName!.isNotEmpty
                      ? booking.customerName![0].toUpperCase()
                      : 'K',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? 'Khách đặt trước',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    Text(
                      booking.customerPhone ?? 'Chưa có SĐT',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
              // Thông tin phòng
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Phòng ${booking.roomNumber ?? "---"}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.accent,
                    ),
                  ),
                  Text(
                    booking.roomTypeName ?? 'Hạng phòng tiêu chuẩn',
                    style: TextStyle(fontSize: 11, color: palette.inkMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Row 3: Thời gian & Tiền bạc
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 16, color: palette.accent),
                    const SizedBox(width: 6),
                    Text(
                      '${Formatters.formatDate(booking.checkInDate)} → ${Formatters.formatDate(booking.checkOutDate)} ($nightsStr)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
                    ),
                  ],
                ),
                Text(
                  Formatters.formatCurrency(booking.totalAmount),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: palette.ink),
                ),
              ],
            ),
          ),

          // Tiền cọc hoặc trạng thái cọc theo quy tắc
          if (booking.depositAmount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.secondaryDark),
                const SizedBox(width: 4),
                Text(
                  'Đã cọc: ${Formatters.formatCurrency(booking.depositAmount)} (${booking.paymentStatus ?? "ĐÃ CỌC"})',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondaryDark),
                ),
              ],
            ),
          ] else if (booking.totalAmount <= 5000000) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: AppColors.availableInk),
                const SizedBox(width: 4),
                Text(
                  'Miễn cọc (Đơn dưới 5tr) • Thanh toán khi check-in',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.availableInk),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.secondaryDark),
                const SizedBox(width: 4),
                Text(
                  'Yêu cầu cọc 10%: ${Formatters.formatCurrency((booking.totalAmount * 0.1).round())} (Đơn trên 5tr)',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.secondaryDark),
                ),
              ],
            ),
          ],

          // Ghi chú lý do từ chối (nếu có)
          if (booking.status == 'CANCELLED' && booking.cancellationReason != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: palette.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Lý do: ${booking.cancellationReason!}',
                    style: TextStyle(fontSize: 11.5, color: palette.error),
                  ),
                ),
              ],
            ),
          ],

          // Row 4: Các nút tác vụ cho Lễ tân
          if (isPending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(booking),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.error,
                      side: BorderSide(color: palette.error.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: PressableScale(
                    onTap: isProcessing ? null : () => _showApproveDialog(booking),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        boxShadow: AppShadows.goldGlow,
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Duyệt Đơn & Nhận Cọc',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isConfirmed) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : () => _checkInBooking(booking),
                    icon: const Icon(Icons.key_rounded, size: 16, color: Colors.white),
                    label: const Text('Nhận Phòng Ngay (Check-in)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.statusAvailable,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
