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
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Màn hình Đơn đặt phòng chờ xác nhận (Pending Bookings Screen)
/// Phục vụ khi nhấn vào thẻ "Đơn chờ duyệt" trên Admin Dashboard
class PendingBookingsScreen extends StatefulWidget {
  final DioClient? dioClient;
  const PendingBookingsScreen({super.key, this.dioClient});

  @override
  State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  late final BookingRepository _bookingRepository;

  int _selectedTabIndex = 0; // 0: Chờ xác nhận, 1: Đã nhận phòng / Đã duyệt, 2: Đã từ chối
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
    _fetchPendingBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Màn này tự chia tab theo trạng thái nên phải gom đủ mọi trang.
      final list = await _bookingRepository.fetchAllBookings();
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final apiErr = ApiError.fromDynamic(e);
      setState(() {
        _errorMessage = apiErr.displayMessage;
        _isLoading = false;
      });
    }
  }

  List<BookingModel> get _filteredBookings {
    var list = _bookings;
    if (_selectedTabIndex == 0) {
      list = list.where((b) => b.status == 'PENDING').toList();
    } else if (_selectedTabIndex == 1) {
      list = list.where((b) => b.status == 'CONFIRMED' || b.status == 'CHECKED_IN').toList();
    } else if (_selectedTabIndex == 2) {
      list = list.where((b) => b.status == 'CANCELLED').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) {
        final code = (b.bookingCode ?? '').toLowerCase();
        final name = (b.customerName ?? '').toLowerCase();
        final phone = (b.customerPhone ?? '').toLowerCase();
        final roomType = (b.roomTypeName ?? '').toLowerCase();
        final roomNum = (b.roomNumber ?? '').toLowerCase();
        return code.contains(q) ||
            name.contains(q) ||
            phone.contains(q) ||
            roomType.contains(q) ||
            roomNum.contains(q);
      }).toList();
    }

    return list;
  }

  /// Nhận phòng ngay (check-in) cho booking
  Future<void> _checkInBooking(BookingModel booking) async {
    final palette = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: palette.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(Icons.check_circle_outline_rounded, color: palette.success, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Nhận phòng ngay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận nhận phòng ngay cho đơn ${booking.bookingCode ?? booking.id} của khách hàng ${booking.customerName ?? ''}?',
              style: TextStyle(fontSize: 14, color: palette.inkMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hạng phòng:', style: TextStyle(fontSize: 12, color: palette.inkFaint)),
                      Text(booking.roomTypeName ?? 'Tiêu chuẩn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thời gian lưu trú:', style: TextStyle(fontSize: 12, color: palette.inkFaint)),
                      Text('${Formatters.formatDate(booking.checkInDate)} - ${Formatters.formatDate(booking.checkOutDate)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tổng tiền thanh toán:', style: TextStyle(fontSize: 12, color: palette.inkFaint)),
                      Text(Formatters.formatCurrency(booking.totalAmount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.accent)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Xem lại', style: TextStyle(color: palette.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            ),
            child: const Text('Nhận phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Khách đã nhận phòng thành công!')),
            ],
          ),
          backgroundColor: palette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
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

  /// Từ chối đơn đặt phòng
  Future<void> _rejectBooking(BookingModel booking) async {
    final palette = context.palette;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        title: Row(
          children: [
            Icon(Icons.cancel_outlined, color: palette.error, size: 26),
            const SizedBox(width: AppSpacing.sm),
            Text('Từ chối Đơn đặt phòng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhập lý do từ chối đơn ${booking.bookingCode ?? booking.id} để thông báo cho khách hàng:',
              style: TextStyle(fontSize: 14, color: palette.inkMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: palette.ink, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'VD: Khách sạn đã kín phòng trong thời gian yêu cầu...',
                hintStyle: TextStyle(fontSize: 12.5, color: palette.inkFaint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                filled: true,
                fillColor: palette.surfaceMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Hủy', style: TextStyle(color: palette.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = reasonController.text.trim();
              Navigator.of(ctx).pop(text.isEmpty ? 'Khách sạn đã hết phòng phù hợp.' : text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            ),
            child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (reason == null) return;

    setState(() => _processingIds.add(booking.id));

    try {
      final updated = await _bookingRepository.cancel(booking.id, reason: reason);
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
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text('Đã từ chối đơn đặt phòng.')),
            ],
          ),
          backgroundColor: palette.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
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

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pendingCount = _bookings.where((b) => b.status == 'PENDING').length;
    final confirmedCount = _bookings.where((b) => b.status == 'CONFIRMED' || b.status == 'CHECKED_IN').length;
    final rejectedCount = _bookings.where((b) => b.status == 'CANCELLED').length;

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
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _fetchPendingBookings,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đơn Phòng Chờ Xác Nhận',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$pendingCount đơn cần xác nhận',
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

          // 2. Nội dung bộ lọc
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Thanh tìm kiếm
                  _buildSearchBar(),
                  const SizedBox(height: AppSpacing.sm),

                  // Tabs lọc (Chờ xác nhận, Đã nhận/duyệt, Đã từ chối)
                  _buildTabs(pendingCount, confirmedCount, rejectedCount),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // 3. Trạng thái Loading / Error / Empty / Danh sách
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
                  onAction: _fetchPendingBookings,
                ),
              ),
            )
          else if (_filteredBookings.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Không có đơn đặt phòng nào',
                  description: 'Hiện tại không có đơn nào cần xử lý trong mục này.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final booking = _filteredBookings[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildPendingCard(booking),
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
          hintText: 'Tìm theo mã đơn, tên khách, số phòng, SĐT...',
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

  Widget _buildTabs(int pending, int confirmed, int rejected) {
    return Row(
      children: [
        Expanded(child: _buildTabItem('Chờ xác nhận', 0, pending, context.palette.warning)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildTabItem('Đã duyệt', 1, confirmed, context.palette.success)),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: _buildTabItem('Đã từ chối', 2, rejected, context.palette.error)),
      ],
    );
  }

  Widget _buildTabItem(String label, int index, int count, Color activeColor) {
    final palette = context.palette;
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? activeColor : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : palette.inkMuted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : palette.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : palette.inkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(BookingModel booking) {
    final palette = context.palette;
    final isProcessing = _processingIds.contains(booking.id);
    final isPending = booking.status == 'PENDING';
    final isConfirmed = booking.status == 'CONFIRMED' || booking.status == 'CHECKED_IN';

    final Color statusColor;
    final String statusLabel;
    if (isPending) {
      statusColor = palette.warning;
      statusLabel = 'Chờ xác nhận';
    } else if (booking.status == 'CHECKED_IN') {
      statusColor = palette.accent;
      statusLabel = 'Đã nhận phòng';
    } else if (isConfirmed) {
      statusColor = palette.success;
      statusLabel = 'Đã duyệt';
    } else {
      statusColor = palette.error;
      statusLabel = 'Đã từ chối';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      border: Border.all(
        color: isPending ? palette.warning.withValues(alpha: 0.3) : palette.border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Mã đơn + Badge trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      booking.bookingCode ?? booking.id,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  if (booking.createdAt != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Formatters.formatDateTime(booking.createdAt!),
                      style: TextStyle(fontSize: 11, color: palette.inkFaint),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
          const SizedBox(height: AppSpacing.md),

          // Loại phòng & Số phòng
          Row(
            children: [
              Icon(Icons.hotel_outlined, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  booking.roomTypeName ?? 'Phòng Tiêu chuẩn',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink),
                ),
              ),
              if (booking.roomNumber != null && booking.roomNumber!.isNotEmpty)
                Text(
                  'Phòng ${booking.roomNumber}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.accent),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ngày lưu trú
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 15, color: palette.inkMuted),
              const SizedBox(width: 6),
              Text(
                '${Formatters.formatDate(booking.checkInDate)} - ${Formatters.formatDate(booking.checkOutDate)}',
                style: TextStyle(fontSize: 12.5, color: palette.ink, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '${booking.nightsCount} đêm',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.inkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Khách hàng & Số khách
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 15, color: palette.inkMuted),
              const SizedBox(width: 6),
              Text(
                '${booking.customerName ?? 'Khách vãng lai'} (${booking.guestCount} khách)',
                style: TextStyle(fontSize: 12.5, color: palette.ink),
              ),
              const Spacer(),
              if (booking.customerPhone != null) ...[
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: booking.customerPhone!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã sao chép SĐT: ${booking.customerPhone}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: palette.accent),
                      const SizedBox(width: 4),
                      Text(
                        booking.customerPhone!,
                        style: TextStyle(fontSize: 12, color: palette.accent, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Yêu cầu đặc biệt
          if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star_outline_rounded, size: 16, color: palette.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Yêu cầu đặc biệt: ${booking.specialRequests}',
                      style: TextStyle(fontSize: 11.5, color: palette.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Lý do từ chối nếu có
          if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: palette.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Lý do từ chối: ${booking.cancellationReason}',
                style: TextStyle(fontSize: 11.5, color: palette.error),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: AppSpacing.sm),

          // Tiền & Các nút Nhận phòng ngay / Từ chối
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng thanh toán:', style: TextStyle(fontSize: 11, color: palette.inkFaint)),
                  Text(
                    Formatters.formatCurrency(booking.totalAmount),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.accent),
                  ),
                ],
              ),
              // Nhận phòng / từ chối đơn chỉ mở cho ADMIN và RECEPTIONIST.
              if (isPending && context.currentRole.canApproveBooking)
                Row(
                  children: [
                    PressableScale(
                      onTap: isProcessing ? null : () => _rejectBooking(booking),
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : () => _rejectBooking(booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.error,
                          side: BorderSide(color: palette.error),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                        ),
                        child: const Text('Từ chối', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PressableScale(
                      onTap: isProcessing ? null : () => _checkInBooking(booking),
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : () => _checkInBooking(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.success,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                        ),
                        child: isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Nhận phòng', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                )
              else if (isConfirmed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 15, color: palette.success),
                      const SizedBox(width: 4),
                      Text(
                        booking.status == 'CHECKED_IN' ? 'Đang lưu trú' : 'Đã xác nhận',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
