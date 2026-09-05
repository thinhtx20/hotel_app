import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/invoice_repository.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../cashier/widgets/invoice_detail_sheet.dart';
import 'my_invoices_screen.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/skeletons/booking_card_skeleton.dart';

class MyBookingsScreen extends StatefulWidget {
  final BookingRepository? bookingRepository;
  const MyBookingsScreen({super.key, this.bookingRepository});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _mainSegment = 0; // 0: Đơn đặt phòng, 1: Hóa đơn của tôi (FE-ROLE-MATRIX §4.3)
  int _selectedTabIndex = 0;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  dynamic _error;
  final Set<String> _cancellingBookingIds = {};
  late final BookingRepository _bookingRepository = widget.bookingRepository ??
      (sl.isRegistered<BookingRepository>()
          ? sl<BookingRepository>()
          : BookingRepository());

  final List<String> _tabs = const [
    'Tất cả',
    'Chờ duyệt',
    'Đã xác nhận',
    'Đang ở',
    'Đã hoàn tất',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchBookings();
    });
  }

  Future<void> _fetchBookings({bool isRefresh = false}) async {
    if (!isRefresh && _bookings.isEmpty) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Màn này tự chia tab theo trạng thái nên phải gom đủ mọi trang.
      final list = await _bookingRepository.fetchAllBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_bookings.isEmpty) {
            _error = e;
          }
        });
        if (isRefresh) {
          AppNotification.showError(
            context,
            e,
            title: 'Làm mới thất bại',
          );
        }
      }
    }
  }

  int _getTabCount(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _bookings.length;
      case 1:
        return _bookings.where((b) => b.status == 'PENDING').length;
      case 2:
        return _bookings.where((b) => b.status == 'CONFIRMED').length;
      case 3:
        return _bookings.where((b) => b.status == 'CHECKED_IN').length;
      case 4:
        return _bookings
            .where((b) => b.status == 'CHECKED_OUT' || b.status == 'COMPLETED')
            .length;
      case 5:
        return _bookings.where((b) => b.status == 'CANCELLED').length;
      default:
        return 0;
    }
  }

  List<BookingModel> _getFilteredBookings() {
    switch (_selectedTabIndex) {
      case 1:
        return _bookings.where((b) => b.status == 'PENDING').toList();
      case 2:
        return _bookings.where((b) => b.status == 'CONFIRMED').toList();
      case 3:
        return _bookings.where((b) => b.status == 'CHECKED_IN').toList();
      case 4:
        return _bookings
            .where((b) => b.status == 'CHECKED_OUT' || b.status == 'COMPLETED')
            .toList();
      case 5:
        return _bookings.where((b) => b.status == 'CANCELLED').toList();
      default:
        return _bookings;
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final reasonController = TextEditingController();
    String selectedReason = 'Thay đổi lịch trình chuyến đi';
    final predefinedReasons = const [
      'Thay đổi lịch trình chuyến đi',
      'Bận việc đột xuất',
      'Tìm thấy lựa chọn phòng tốt hơn',
      'Lý do sức khỏe',
      'Khác',
    ];

    final cancelReason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: palette.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: palette.isDark ? const Color(0xFFEF4444) : AppColors.error,
                  size: 26),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Xác nhận hủy đơn',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn có chắc chắn muốn hủy đơn đặt phòng ${booking.bookingCode ?? booking.id} không?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Lý do hủy phòng:',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: predefinedReasons.map((r) {
                    final isSel = selectedReason == r;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = r;
                          if (r != 'Khác') {
                            reasonController.text = r;
                          } else {
                            reasonController.clear();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? palette.accent : palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                            color: isSel ? Colors.white : palette.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: TextStyle(fontSize: 13, color: palette.ink),
                  decoration: InputDecoration(
                    hintText: 'Nhập hoặc chỉnh sửa lý do hủy...',
                    hintStyle: TextStyle(fontSize: 13, color: palette.inkFaint),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(
                'Đóng',
                style: TextStyle(color: palette.inkMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
              ),
              onPressed: () {
                final text = reasonController.text.trim().isNotEmpty
                    ? reasonController.text.trim()
                    : selectedReason;
                Navigator.pop(ctx, text);
              },
              child: const Text('Hủy đơn phòng'),
            ),
          ],
        ),
      ),
    );

    if (cancelReason == null || !mounted) return;

    setState(() => _cancellingBookingIds.add(booking.id));

    try {
      final updated = await _bookingRepository.cancel(booking.id, reason: cancelReason);
      if (mounted) {
        // Máy chủ đã tự trả phòng về đúng trạng thái theo các đơn còn hiệu lực
        // khi hủy đơn, nên ở đây chỉ tải lại danh sách phòng. Gọi
        // PATCH /rooms/:id/status sẽ bị 403 vì endpoint đó chỉ mở cho
        // ADMIN/RECEPTIONIST.
        sl<RoomRepository>().fetchRooms(forceRefresh: true).catchError((_) {});
        setState(() {
          _cancellingBookingIds.remove(booking.id);
          final idx = _bookings.indexWhere((b) => b.id == booking.id);
          if (idx != -1) {
            _bookings[idx] = updated;
          }
        });
        AppNotification.showSuccess(
          context,
          'Đã hủy đơn phòng ${booking.bookingCode ?? booking.id} thành công',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cancellingBookingIds.remove(booking.id));
        AppNotification.showError(
          context,
          e,
          title: 'Hủy đơn phòng thất bại',
        );
      }
    }
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingDetailsModal(
        booking: booking,
        onCancel: () {
          Navigator.pop(ctx);
          _cancelBooking(booking);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final filtered = _getFilteredBookings();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  PressableScale(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/customer');
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: palette.ink,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyến Đi Của Tôi',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lịch sử đặt phòng & hóa đơn của bạn',
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PressableScale(
                    onTap: () => _fetchBookings(isRefresh: true),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: palette.border),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: palette.ink,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segment switcher: Đơn đặt phòng vs Hóa đơn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PressableScale(
                        onTap: () => setState(() => _mainSegment = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _mainSegment == 0 ? palette.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đơn đặt phòng',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _mainSegment == 0 ? FontWeight.w700 : FontWeight.w500,
                              color: _mainSegment == 0 ? Colors.white : palette.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PressableScale(
                        onTap: () => setState(() => _mainSegment = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _mainSegment == 1 ? palette.accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Hóa đơn của tôi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _mainSegment == 1 ? FontWeight.w700 : FontWeight.w500,
                              color: _mainSegment == 1 ? Colors.white : palette.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_mainSegment == 1)
              const Expanded(child: MyInvoicesScreen())
            else ...[
            // 2. Pill Tabs
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, idx) {
                  final title = _tabs[idx];
                  final isSelected = idx == _selectedTabIndex;
                  final count = _getTabCount(idx);

                  return PressableScale(
                    onTap: () => setState(() => _selectedTabIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.gold : null,
                        color: isSelected ? null : palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: palette.border,
                                width: 1,
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : palette.inkMuted,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : palette.surfaceMuted,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : palette.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Bookings Content
            Expanded(
              child: RefreshIndicator(
                color: palette.accent,
                backgroundColor: palette.surface,
                onRefresh: () => _fetchBookings(isRefresh: true),
                child: _isLoading
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screen,
                        ),
                        child: Column(
                          children: const [
                            BookingCardSkeleton(),
                            SizedBox(height: AppSpacing.md),
                            BookingCardSkeleton(),
                          ],
                        ),
                      )
                    : _error != null && _bookings.isEmpty
                        ? AppErrorView(
                            error: _error,
                            onRetry: () => _fetchBookings(),
                          )
                        : filtered.isEmpty
                            ? AppEmptyState(
                                icon: Icons.book_online_outlined,
                                title: 'Không có đơn phòng nào',
                                description:
                                    'Hiện tại bạn không có đơn phòng nào trong trạng thái này.',
                                actionText: 'Khám phá & Đặt phòng',
                                onAction: () => context.go('/search'),
                              )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screen,
                              0,
                              AppSpacing.screen,
                              AppSpacing.xxl,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              return _buildBookingCard(filtered[index]);
                            },
                          ),
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final statusUpper = booking.status.toUpperCase();
    final isCancelled = statusUpper == 'CANCELLED';
    final isCompleted =
        statusUpper == 'CHECKED_OUT' || statusUpper == 'COMPLETED';

    Color stripeColor;
    String statusLabel;
    Color statusInk;

    switch (statusUpper) {
      case 'CONFIRMED':
        stripeColor = AppColors.available;
        statusLabel = 'Đã xác nhận';
        statusInk = palette.successInk;
        break;
      case 'PENDING':
        stripeColor = AppColors.reserved;
        statusLabel = 'Chờ duyệt';
        statusInk = palette.warningInk;
        break;
      case 'CHECKED_IN':
        stripeColor = AppColors.occupied;
        statusLabel = 'Đang ở';
        statusInk = palette.infoInk;
        break;
      case 'CANCELLED':
        stripeColor = AppColors.error;
        statusLabel = 'Đã hủy';
        statusInk = palette.errorInk;
        break;
      case 'CHECKED_OUT':
      case 'COMPLETED':
      default:
        stripeColor = AppColors.maintenance;
        statusLabel = 'Đã hoàn tất';
        statusInk = palette.inkMuted;
        break;
    }

    final code = booking.bookingCode?.isNotEmpty == true
        ? booking.bookingCode!
        : 'BK-${booking.displayCode}';
    final checkIn = booking.checkInDate;
    final checkOut = booking.checkOutDate;
    final nights = booking.nightsCount;

    final cardContent = AppCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(
              decoration: BoxDecoration(
                color: stripeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.card),
                  bottomLeft: Radius.circular(AppRadius.card),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Booking Code + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MÃ ĐƠN PHÒNG',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: palette.inkMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          code,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: stripeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: stripeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Dashed separator
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(color: palette.border),
                ),
                const SizedBox(height: AppSpacing.md),

                // Room info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        Icons.hotel_rounded,
                        color: palette.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phòng ${booking.roomNumber ?? booking.roomId}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.roomTypeName ?? 'Tiêu chuẩn cao cấp',
                            style: textTheme.bodySmall?.copyWith(
                              color: palette.inkMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '$nights đêm',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Dates card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NHẬN PHÒNG',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: palette.inkMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${checkIn.day.toString().padLeft(2, '0')}/${checkIn.month.toString().padLeft(2, '0')}/${checkIn.year}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.border),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: palette.accent,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TRẢ PHÒNG',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: palette.inkMuted,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${checkOut.day.toString().padLeft(2, '0')}/${checkOut.month.toString().padLeft(2, '0')}/${checkOut.year}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCancelled &&
                    (booking.cancellationReason?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Lý do hủy: ${booking.cancellationReason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Bottom Actions & Deposit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.depositAmount > 0 ? 'Đã cọc:' : 'Tổng tiền:',
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          booking.depositAmount > 0
                              ? '${_formatCurrency(booking.depositAmount)} ₫'
                              : '${_formatCurrency(booking.totalAmount)} ₫',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (statusUpper == 'PENDING' ||
                            statusUpper == 'CONFIRMED') ...[
                          OutlinedButton(
                            onPressed: () => _cancelBooking(booking),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text(
                              'Hủy đơn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        PressableScale(
                          onTap: () => _showBookingDetails(booking),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppGradients.gold,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Chi tiết',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isCancelled || isCompleted) {
      return Opacity(
        opacity: isCancelled ? 0.75 : 0.88,
        child: cardContent,
      );
    }
    return cardContent;
  }

  String _formatCurrency(num amount) {
    return Formatters.formatNumber(amount);
  }
}

// ---------------------------------------------------------------------------
// High-Performance Dashed Line Painter (Canvas O(1) rendering)
// ---------------------------------------------------------------------------
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ---------------------------------------------------------------------------
// Booking Details Modal Sheet
// ---------------------------------------------------------------------------
class _BookingDetailsModal extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onCancel;

  const _BookingDetailsModal({
    required this.booking,
    required this.onCancel,
  });

  String _formatCurrency(num amount) {
    return Formatters.formatNumber(amount);
  }

  Future<void> _viewInvoice(BuildContext context) async {
    final invoiceId = booking.invoiceId;
    if (invoiceId == null || invoiceId.isEmpty) return;

    try {
      final repo = sl.isRegistered<InvoiceRepository>()
          ? sl<InvoiceRepository>()
          : InvoiceRepository();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final inv = await repo.fetchDetail(invoiceId);

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        InvoiceDetailSheet.show(
          context: context,
          invoice: inv,
          onPrintReceipt: () => Navigator.of(context).maybePop(),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        AppNotification.showError(
          context,
          e,
          title: 'Không thể tải thông tin hóa đơn',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final statusUpper = booking.status.toUpperCase();
    final canCancel = statusUpper == 'PENDING' || statusUpper == 'CONFIRMED';
    final remaining = (booking.totalAmount - booking.depositAmount);

    return AppBottomSheet(
      title: 'Chi tiết đơn đặt phòng',
      trailing: IconButton(
        icon: Icon(Icons.close_rounded, color: palette.inkMuted),
        onPressed: () => Navigator.pop(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              booking.bookingCode?.isNotEmpty == true
                  ? booking.bookingCode!
                  : 'BK-${booking.displayCode}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Room Details Row
            _buildInfoRow(
              context,
              'Phòng',
              'Phòng ${booking.roomNumber ?? booking.roomId} (Tầng ${booking.floor ?? 1})',
            ),
            _buildInfoRow(
              context,
              'Hạng phòng',
              booking.roomTypeName ?? 'Tiêu chuẩn',
            ),
            _buildInfoRow(
              context,
              'Số khách',
              '${booking.guestCount} khách',
            ),
            _buildInfoRow(
              context,
              'Thời gian nhận phòng',
              '${booking.checkInDate.day}/${booking.checkInDate.month}/${booking.checkInDate.year} (14:00)',
            ),
            _buildInfoRow(
              context,
              'Thời gian trả phòng',
              '${booking.checkOutDate.day}/${booking.checkOutDate.month}/${booking.checkOutDate.year} (12:00)',
            ),
            _buildInfoRow(
              context,
              'Thời lượng',
              '${booking.nightsCount} đêm',
            ),

            if (booking.specialRequests != null &&
                booking.specialRequests!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                'Yêu cầu đặc biệt',
                booking.specialRequests!,
              ),
            ],
            if (booking.cancellationReason != null &&
                booking.cancellationReason!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                'Lý do hủy',
                booking.cancellationReason!,
                isBold: true,
                color: AppColors.error,
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: palette.divider),
            const SizedBox(height: AppSpacing.md),

            // Payment Summary
            _buildInfoRow(
              context,
              'Tổng tiền phòng',
              '${_formatCurrency(booking.totalAmount)} ₫',
              isBold: true,
            ),
            _buildInfoRow(
              context,
              'Đã đặt cọc',
              '${_formatCurrency(booking.depositAmount)} ₫',
              color: AppColors.available,
            ),
            if (remaining > 0)
              _buildInfoRow(
                context,
                'Còn lại cần thanh toán',
                '${_formatCurrency(remaining)} ₫',
                isBold: true,
                color: palette.accent,
              ),

            const SizedBox(height: AppSpacing.xl),

            // Actions
            if (booking.invoiceId != null && booking.invoiceId!.isNotEmpty) ...[
              OutlinedButton.icon(
                onPressed: () => _viewInvoice(context),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('Xem hóa đơn thanh toán'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.accent,
                  side: BorderSide(color: palette.accent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            if (canCancel) ...[
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Hủy đơn đặt phòng này'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            CustomButton(
              text: 'Đóng',
              onPressed: () => Navigator.pop(context),
              height: 48,
              isGold: false,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: palette.inkMuted,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? palette.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
