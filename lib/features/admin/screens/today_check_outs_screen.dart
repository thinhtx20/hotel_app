import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
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
import '../../receptionist/widgets/add_service_sheet.dart';
import '../../receptionist/widgets/check_out_sheet.dart';

/// Màn hình Chi tiết Lượt trả phòng hôm nay (Today Check-Outs Screen)
/// Phục vụ khi nhấn vào thẻ "Lượt trả phòng" trên Admin Dashboard
class TodayCheckOutsScreen extends StatefulWidget {
  final DioClient? dioClient;
  const TodayCheckOutsScreen({super.key, this.dioClient});

  @override
  State<TodayCheckOutsScreen> createState() => _TodayCheckOutsScreenState();
}

class _TodayCheckOutsScreenState extends State<TodayCheckOutsScreen> {
  late final BookingRepository _bookingRepository;

  int _selectedTabIndex = 0; // 0: Tất cả, 1: Chờ trả phòng, 2: Đã trả phòng
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    _fetchCheckOuts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCheckOuts({bool isSilent = false}) async {
    if (!isSilent && _bookings.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _bookingRepository.fetchTodayCheckOuts();
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
        AppNotification.showError(context, e, title: 'Làm mới danh sách thất bại');
      }
    }
  }

  List<BookingModel> get _filteredBookings {
    return _bookings.where((b) {
      if (_selectedTabIndex == 1 && b.status == 'CHECKED_OUT') return false;
      if (_selectedTabIndex == 2 && b.status != 'CHECKED_OUT') return false;

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

    setState(() {
      final idx = _bookings.indexWhere((b) => b.id == booking.id);
      if (idx != -1) {
        _bookings[idx] = result.$1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final totalCount = _bookings.length;
    final checkedOutCount =
        _bookings.where((b) => b.status == 'CHECKED_OUT').length;
    final pendingCount = totalCount - checkedOutCount;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: CustomScrollView(
        slivers: [
          // 1. Navy App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetchCheckOuts,
              ),
            ],
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

          // 2. Search & Tabs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTabs(totalCount, pendingCount, checkedOutCount),
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
                  onAction: _fetchCheckOuts,
                ),
              ),
            )
          else if (_filteredBookings.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.no_meeting_room_outlined,
                  title: 'Không có lượt trả phòng',
                  description: 'Không tìm thấy phòng nào cần trả hôm nay.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = _filteredBookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildCheckOutCard(booking),
                    );
                  },
                  childCount: _filteredBookings.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final palette = context.palette;
    return Container(
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

  Widget _buildTabs(int total, int pending, int checkedOut) {
    return Row(
      children: [
        Expanded(
          child: _buildTabItem('Tất cả ($total)', 0),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildTabItem('Chờ trả ($pending)', 1),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildTabItem('Đã trả ($checkedOut)', 2),
        ),
      ],
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
                        horizontal: AppSpacing.sm, vertical: 2),
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
                    horizontal: AppSpacing.sm, vertical: 4),
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
              Icon(Icons.person_outline_rounded,
                  size: 16, color: palette.inkMuted),
              const SizedBox(width: 4),
              Text(
                '${booking.customerName ?? 'Khách vãng lai'} (${booking.guestCount} khách)',
                style: textTheme.bodyMedium?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              const Spacer(),
              if (booking.customerPhone != null) ...[
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: booking.customerPhone!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Đã sao chép SĐT: ${booking.customerPhone}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 14, color: palette.accent),
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
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: palette.inkFaint),
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
                            onServiceAdded: () => _fetchCheckOuts(),
                          );
                        },
                        icon: const Icon(Icons.room_service_outlined, size: 14),
                        label: const Text('Dịch vụ', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.accent,
                          side: BorderSide(color: palette.accent.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
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
                            borderRadius:
                                BorderRadius.circular(AppRadius.button),
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
                    Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: palette.success),
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
