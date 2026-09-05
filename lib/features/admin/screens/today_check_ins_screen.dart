import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/sticky_header.dart';
import '../../receptionist/widgets/check_in_confirm_dialog.dart';

/// Màn hình Chi tiết Lượt nhận phòng hôm nay (Today Check-Ins Screen)
/// Phục vụ khi nhấn vào thẻ "Lượt nhận phòng" trên Admin Dashboard
class TodayCheckInsScreen extends StatefulWidget {
  final DioClient? dioClient;
  const TodayCheckInsScreen({super.key, this.dioClient});

  @override
  State<TodayCheckInsScreen> createState() => _TodayCheckInsScreenState();
}

class _TodayCheckInsScreenState extends State<TodayCheckInsScreen> {
  late final BookingRepository _bookingRepository;

  int _selectedTabIndex = 0; // 0: Tất cả, 1: Chờ nhận, 2: Đã nhận
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _processingIds = {};

  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
    _bookingRepository = widget.dioClient != null
        ? BookingRepository(dioClient: widget.dioClient)
        : sl<BookingRepository>();

    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
    _fetchCheckIns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCheckIns({bool isSilent = false}) async {
    if (!isSilent && _bookings.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _bookingRepository.fetchTodayCheckIns();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiError.fromDynamic(e);
      setState(() {
        if (_bookings.isEmpty) {
          _errorMessage = apiErr.displayMessage;
        }
        _isLoading = false;
      });
      if (isSilent || _bookings.isNotEmpty) {
        AppNotification.showError(
          context,
          e,
          title: 'Làm mới danh sách thất bại',
        );
      }
    }
  }

  List<BookingModel> get _filteredBookings {
    return _bookings.where((b) {
      if (_selectedTabIndex == 1 && b.status == 'CHECKED_IN') return false;
      if (_selectedTabIndex == 2 && b.status != 'CHECKED_IN') return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = (b.customerName ?? '').toLowerCase().contains(q);
        final matchPhone = (b.customerPhone ?? '').toLowerCase().contains(q);
        final matchRoom = (b.roomNumber ?? '').toLowerCase().contains(q);
        final matchCode = (b.bookingCode ?? '').toLowerCase().contains(q);
        if (!matchName && !matchPhone && !matchRoom && !matchCode) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _performCheckIn(BookingModel booking) async {
    final palette = context.palette;

    final confirmed = await CheckInConfirmDialog.show(
      context: context,
      booking: booking,
    );
    if (!confirmed || !mounted) return;

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Đã nhận phòng thành công cho đơn ${booking.bookingCode ?? booking.id}!',
                ),
              ),
            ],
          ),
          backgroundColor: palette.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processingIds.remove(booking.id));
      final apiErr = ApiError.fromDynamic(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${apiErr.displayMessage}'),
          backgroundColor: palette.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final totalCount = _bookings.length;
    final checkedInCount = _bookings
        .where((b) => b.status == 'CHECKED_IN')
        .length;
    final pendingCount = totalCount - checkedInCount;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: CustomScrollView(
        slivers: [
          // 1. Navy App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhận Phòng Hôm Nay',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Dự kiến: $totalCount  •  Đã nhận: $checkedInCount  •  Chờ: $pendingCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(gradient: AppGradients.navy),
              ),
            ),
          ),

          // 2. Search & Tabs — ghim ngay dưới app bar khi cuộn danh sách.
          SliverStickyHeader(
            contentHeight: _filterHeight,
            topGap: AppSpacing.screen,
            bottomGap: AppSpacing.screen,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTabs(totalCount, pendingCount, checkedInCount),
                ],
              ),
            ),
          ),

          // 3. Nội dung danh sách / Trạng thái
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Không thể tải danh sách',
                  description: _errorMessage ?? 'Đã xảy ra lỗi kết nối.',
                  actionText: 'Tải lại',
                  onAction: _fetchCheckIns,
                ),
              ),
            )
          else if (_filteredBookings.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.hotel_outlined,
                  title: 'Không có lượt nhận phòng',
                  description: 'Không tìm thấy đặt phòng nào phù hợp.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screen,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final booking = _filteredBookings[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _buildCheckInCard(booking),
                  );
                }, childCount: _filteredBookings.length),
              ),
            ),
        ],
      ),
    );
  }

  // Thanh lọc phải cao cố định để sliver ghim biết trước kích thước.
  static const double _searchHeight = 46;
  static const double _tabsHeight = 38;
  static const double _filterHeight =
      _searchHeight + AppSpacing.sm + _tabsHeight;

  Widget _buildSearchBar() {
    final palette = context.palette;
    return Container(
      height: _searchHeight,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: palette.border),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13.5, color: palette.ink),
        decoration: InputDecoration(
          hintText: 'Tìm theo mã, tên khách, số phòng...',
          hintStyle: TextStyle(fontSize: 13, color: palette.inkFaint),
          prefixIcon: Icon(Icons.search, size: 20, color: palette.inkMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  Widget _buildTabs(int total, int pending, int checkedIn) {
    return SizedBox(
      height: _tabsHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildTabItem('Tất cả ($total)', 0)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _buildTabItem('Chờ nhận ($pending)', 1)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: _buildTabItem('Đã nhận ($checkedIn)', 2)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index) {
    final palette = context.palette;
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.12)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? palette.accent : palette.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInCard(BookingModel booking) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final isCheckedIn = booking.status == 'CHECKED_IN';
    final isProcessing = _processingIds.contains(booking.id);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mã booking & Trạng thái badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      booking.bookingCode ?? booking.id,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Phòng ${booking.roomNumber ?? '---'}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? palette.success.withValues(alpha: 0.12)
                      : palette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isCheckedIn ? 'ĐÃ NHẬN PHÒNG' : 'CHỜ CHECK-IN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCheckedIn ? palette.success : palette.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Tên hạng phòng
          Text(
            booking.roomTypeName ?? 'Phòng Tiêu chuẩn',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Khách hàng & Số điện thoại
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: palette.inkMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${booking.customerName ?? 'Khách vãng lai'} (${booking.guestCount} khách)',
                style: textTheme.bodyMedium?.copyWith(color: palette.inkMuted),
              ),
              const Spacer(),
              if (booking.customerPhone != null) ...[
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: booking.customerPhone!),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã sao chép SĐT: ${booking.customerPhone}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: palette.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.customerPhone!,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Thời gian lưu trú
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: palette.inkFaint,
              ),
              const SizedBox(width: 6),
              Text(
                'Trả phòng: ${Formatters.formatDate(booking.checkOutDate)} (${booking.nightsCount} đêm)',
                style: TextStyle(fontSize: 12, color: palette.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: AppSpacing.sm),

          // Tiền phòng & Nút Check-in
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng tiền:',
                    style: TextStyle(fontSize: 11, color: palette.inkFaint),
                  ),
                  Text(
                    Formatters.formatCurrency(booking.totalAmount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: palette.accent,
                    ),
                  ),
                ],
              ),
              // Check-in chỉ mở cho ADMIN và RECEPTIONIST
              if (!isCheckedIn && context.currentRole.canCheckIn)
                PressableScale(
                  onTap: isProcessing ? null : () => _performCheckIn(booking),
                  child: ElevatedButton(
                    onPressed: isProcessing
                        ? null
                        : () => _performCheckIn(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Check-in ngay',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                )
              else if (isCheckedIn)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: palette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã hoàn tất thủ tục',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.success,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
