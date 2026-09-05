import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../../../shared/widgets/sticky_header.dart';
import '../../receptionist/widgets/add_service_sheet.dart';
import '../../receptionist/widgets/check_out_sheet.dart';
import '../bloc/today_check_outs_bloc.dart';
import '../bloc/today_check_outs_event.dart';
import '../bloc/today_check_outs_state.dart';

/// Màn hình Chi tiết Lượt trả phòng hôm nay (Today Check-Outs Screen)
/// Phục vụ khi nhấn vào thẻ "Lượt trả phòng" trên Admin Dashboard
class TodayCheckOutsScreen extends StatefulWidget {
  final DioClient? dioClient;
  final BookingRepository? bookingRepository;
  final TodayCheckOutsBloc? bloc;

  const TodayCheckOutsScreen({
    super.key,
    this.dioClient,
    this.bookingRepository,
    this.bloc,
  });

  @override
  State<TodayCheckOutsScreen> createState() => _TodayCheckOutsScreenState();
}

class _TodayCheckOutsScreenState extends State<TodayCheckOutsScreen> {
  late final BookingRepository _bookingRepository;
  late final TodayCheckOutsBloc _bloc;
  bool _shouldDisposeBloc = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.bookingRepository != null) {
      _bookingRepository = widget.bookingRepository!;
    } else if (widget.dioClient != null) {
      _bookingRepository = BookingRepository(dioClient: widget.dioClient);
    } else if (sl.isRegistered<BookingRepository>()) {
      _bookingRepository = sl<BookingRepository>();
    } else {
      _bookingRepository = BookingRepository();
    }

    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else if (sl.isRegistered<TodayCheckOutsBloc>()) {
      _bloc = sl<TodayCheckOutsBloc>();
    } else {
      _bloc = TodayCheckOutsBloc(bookingRepository: _bookingRepository);
      _shouldDisposeBloc = true;
    }

    _searchController.addListener(() {
      _bloc.add(TodayCheckOutsSearchChanged(_searchController.text.trim()));
    });
    _bloc.add(const TodayCheckOutsFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_shouldDisposeBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  /// Mở sheet thanh toán & trả phòng.
  ///
  /// [CheckOutSheet] tự gọi API, hiện vòng quay chờ và hộp thoại hóa đơn; ở đây
  /// chỉ cần thay đơn đã trả phòng vào danh sách.
  Future<void> _openCheckOutSheet(BookingModel booking) async {
    final result = await CheckOutSheet.show(
      context: context,
      booking: booking,
      bookingRepository: _bookingRepository,
    );
    if (result == null || !mounted) return;

    _bloc.add(TodayCheckOutsBookingUpdated(result.$1));
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
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<TodayCheckOutsBloc, TodayCheckOutsState>(
        builder: (context, state) {
          final palette = context.palette;
          final textTheme = Theme.of(context).textTheme;

          final totalCount = state.totalCount;
          final checkedOutCount = state.checkedOutCount;
          final pendingCount = state.pendingCount;
          final filteredBookings = state.filteredBookings;

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
                          'Trả Phòng Hôm Nay',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Dự kiến: $totalCount  •  Đã trả: $checkedOutCount  •  Chờ: $pendingCount',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.navy,
                      ),
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
                        _buildSearchBar(state),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTabs(
                          state,
                          totalCount,
                          pendingCount,
                          checkedOutCount,
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Nội dung danh sách / Trạng thái
                if (state.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.errorMessage != null && state.bookings.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Không thể tải danh sách',
                        description:
                            state.errorMessage ?? 'Đã xảy ra lỗi kết nối.',
                        actionText: 'Tải lại',
                        onAction: () =>
                            _bloc.add(const TodayCheckOutsFetchRequested()),
                      ),
                    ),
                  )
                else if (filteredBookings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.no_meeting_room_outlined,
                        title: 'Không có lượt trả phòng',
                        description:
                            'Không tìm thấy phòng nào cần trả hôm nay.',
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
                        final booking = filteredBookings[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildCheckOutCard(booking),
                        );
                      }, childCount: filteredBookings.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Thanh lọc phải cao cố định để sliver ghim biết trước kích thước.
  static const double _searchHeight = 46;
  static const double _tabsHeight = 38;
  static const double _filterHeight =
      _searchHeight + AppSpacing.sm + _tabsHeight;

  Widget _buildSearchBar(TodayCheckOutsState state) {
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
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _bloc.add(const TodayCheckOutsSearchChanged(''));
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }

  Widget _buildTabs(
    TodayCheckOutsState state,
    int total,
    int pending,
    int checkedOut,
  ) {
    return SizedBox(
      height: _tabsHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildTabItem('Tất cả ($total)', 0, state.selectedTabIndex),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildTabItem(
              'Chờ trả ($pending)',
              1,
              state.selectedTabIndex,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _buildTabItem(
              'Đã trả ($checkedOut)',
              2,
              state.selectedTabIndex,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index, int selectedIndex) {
    final palette = context.palette;
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _bloc.add(TodayCheckOutsTabChanged(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
              : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF3B82F6) : palette.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckOutCard(BookingModel booking) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final isCheckedOut = booking.status == 'CHECKED_OUT';

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
                      color: const Color(0xFF3B82F6),
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
                  color: isCheckedOut
                      ? palette.success.withValues(alpha: 0.12)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isCheckedOut ? 'ĐÃ TRẢ PHÒNG' : 'CHỜ TRẢ PHÒNG',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCheckedOut
                        ? palette.success
                        : const Color(0xFF3B82F6),
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

          // Ngày nhận & Trả phòng
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: palette.inkFaint,
              ),
              const SizedBox(width: 6),
              Text(
                'Nhận: ${Formatters.formatDate(booking.checkInDate)}  •  ${booking.nightsCount} đêm',
                style: TextStyle(fontSize: 12, color: palette.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: AppSpacing.sm),

          // Tiền phòng & Nút Check-out
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng tiền dự tính:',
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
              // Check-out mở cho ADMIN, RECEPTIONIST, CASHIER
              if (!isCheckedOut && context.currentRole.canCheckOut)
                Row(
                  children: [
                    // POST /bookings/:id/services chỉ mở cho ADMIN và RECEPTIONIST (§3.5, §4.3, §5)
                    if (context.currentRole.canAddBookingServices) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          AddServiceSheet.show(
                            context: context,
                            bookingId: booking.id,
                            roomNumber: booking.roomNumber,
                            onServiceAdded: () => _bloc.add(
                              const TodayCheckOutsRefreshRequested(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.room_service_outlined, size: 14),
                        label: const Text(
                          'Dịch vụ',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.accent,
                          side: BorderSide(
                            color: palette.accent.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    PressableScale(
                      onTap: () => _openCheckOutSheet(booking),
                      child: ElevatedButton(
                        onPressed: () => _openCheckOutSheet(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Trả phòng & Xuất HĐ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (isCheckedOut)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: palette.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đã hoàn tất trả phòng',
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
