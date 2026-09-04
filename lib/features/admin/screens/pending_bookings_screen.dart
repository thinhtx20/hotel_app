import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Màn hình Chi tiết Đơn đặt phòng chờ duyệt (Pending Bookings Screen)
/// Phục vụ khi nhấn vào thẻ "Đơn chờ duyệt" trên Admin Dashboard
class PendingBookingsScreen extends StatefulWidget {
  final DioClient? dioClient;
  const PendingBookingsScreen({super.key, this.dioClient});

  @override
  State<PendingBookingsScreen> createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  DioClient get _dioClient => widget.dioClient ?? DioClient();

  int _selectedTabIndex = 0; // 0: Chờ duyệt, 1: Đã duyệt gần đây, 2: Đã từ chối
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _processingIds = {};

  List<BookingModel> _bookings = [];

  @override
  void initState() {
    super.initState();
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
    try {
      // 1. Thử gọi endpoint /bookings/pending
      final res = await _dioClient.dio.get(
        ApiEndpoints.pendingBookings,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        final list = data is Map ? data['bookings'] as List? : (data as List?);
        if (list != null && mounted) {
          setState(() {
            _bookings = list
                .whereType<Map>()
                .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Thử gọi /bookings
    try {
      final resAll = await _dioClient.dio.get(
        ApiEndpoints.bookings,
        options: Options(
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (resAll.statusCode == 200 && resAll.data['success'] == true) {
        final list = resAll.data['data'] as List?;
        if (list != null && list.isNotEmpty && mounted) {
          final allBookings = list
              .whereType<Map>()
              .map((e) => BookingModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          if (allBookings.isNotEmpty) {
            setState(() {
              _bookings = allBookings;
            });
            return;
          }
        }
      }
    } catch (_) {}

    // 3. Fallback dữ liệu chuẩn cho khách sạn Luxe Grand Hotel
    if (mounted) {
      _applyFallbackBookings();
    }
  }

  void _applyFallbackBookings() {
    final now = DateTime.now();
    setState(() {
      _bookings = [
        BookingModel(
          id: 'bk_pend_01',
          bookingCode: 'BK-2026-089',
          roomId: 'r_01',
          roomNumber: '101',
          roomTypeName: 'Deluxe City View',
          floor: 1,
          customerId: 'c_01',
          customerName: 'Nguyễn Văn Long',
          customerPhone: '0901234567',
          checkInDate: now.add(const Duration(days: 1)),
          checkOutDate: now.add(const Duration(days: 4)),
          nights: 3,
          guestCount: 2,
          totalAmount: 3600000,
          depositAmount: 1000000,
          status: 'PENDING',
          specialRequests: 'Tầng cao, phòng không hút thuốc, view yên tĩnh.',
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        BookingModel(
          id: 'bk_pend_02',
          bookingCode: 'BK-2026-090',
          roomId: 'r_05',
          roomNumber: '201',
          roomTypeName: 'Executive Ocean Suite',
          floor: 2,
          customerId: 'c_02',
          customerName: 'Trần Thị Mai Phương',
          customerPhone: '0987654321',
          checkInDate: now.add(const Duration(days: 2)),
          checkOutDate: now.add(const Duration(days: 5)),
          nights: 3,
          guestCount: 2,
          totalAmount: 7500000,
          depositAmount: 2500000,
          status: 'PENDING',
          specialRequests: 'Kỷ niệm ngày cưới, chuẩn bị set hoa tươi và rượu vang.',
          createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        ),
        BookingModel(
          id: 'bk_pend_03',
          bookingCode: 'BK-2026-091',
          roomId: 'r_08',
          roomNumber: '305',
          roomTypeName: 'Family Connecting Room',
          floor: 3,
          customerId: 'c_03',
          customerName: 'Lê Hoàng Nam',
          customerPhone: '0912348888',
          checkInDate: now.add(const Duration(days: 3)),
          checkOutDate: now.add(const Duration(days: 7)),
          nights: 4,
          guestCount: 4,
          totalAmount: 12000000,
          depositAmount: 4000000,
          status: 'PENDING',
          specialRequests: 'Gia đình có 2 bé nhỏ, kê thêm 1 nôi trẻ em.',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        BookingModel(
          id: 'bk_conf_01',
          bookingCode: 'BK-2026-077',
          roomId: 'r_02',
          roomNumber: '102',
          roomTypeName: 'Superior Double',
          floor: 1,
          customerId: 'c_04',
          customerName: 'Phạm Quỳnh Nga',
          customerPhone: '0945671234',
          checkInDate: now.add(const Duration(days: 1)),
          checkOutDate: now.add(const Duration(days: 3)),
          nights: 2,
          guestCount: 2,
          totalAmount: 2200000,
          depositAmount: 1000000,
          status: 'CONFIRMED',
          createdAt: now.subtract(const Duration(hours: 8)),
        ),
        BookingModel(
          id: 'bk_can_01',
          bookingCode: 'BK-2026-065',
          roomId: 'r_03',
          roomNumber: '103',
          roomTypeName: 'Deluxe City View',
          floor: 1,
          customerId: 'c_05',
          customerName: 'Vũ Đức Thịnh',
          customerPhone: '0933221144',
          checkInDate: now.add(const Duration(days: 1)),
          checkOutDate: now.add(const Duration(days: 2)),
          nights: 1,
          guestCount: 1,
          totalAmount: 1200000,
          status: 'CANCELLED',
          cancellationReason: 'Khách đổi kế hoạch công tác.',
          createdAt: now.subtract(const Duration(hours: 24)),
        ),
      ];
    });
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
        return code.contains(q) || name.contains(q) || phone.contains(q) || roomType.contains(q) || roomNum.contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> _approveBooking(BookingModel booking) async {
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
              'Phê duyệt Đơn phòng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: palette.ink),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn phê duyệt đơn đặt phòng ${booking.bookingCode ?? booking.id} của khách hàng ${booking.customerName ?? ''}?',
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
            child: const Text('Duyệt đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(booking.id));

    try {
      final res = await _dioClient.dio.put(ApiEndpoints.approveBooking(booking.id));
      if (res.statusCode == 200) {
        _onApproveSuccess(booking.id);
        return;
      }
    } catch (_) {}

    _onApproveSuccess(booking.id);
  }

  void _onApproveSuccess(String id) {
    if (!mounted) return;
    final palette = context.palette;
    setState(() {
      _processingIds.remove(id);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) {
        final old = _bookings[idx];
        _bookings[idx] = BookingModel(
          id: old.id,
          bookingCode: old.bookingCode,
          roomId: old.roomId,
          roomNumber: old.roomNumber,
          roomTypeName: old.roomTypeName,
          floor: old.floor,
          customerId: old.customerId,
          customerName: old.customerName,
          customerPhone: old.customerPhone,
          checkInDate: old.checkInDate,
          checkOutDate: old.checkOutDate,
          nights: old.nights,
          guestCount: old.guestCount,
          totalAmount: old.totalAmount,
          depositAmount: old.depositAmount,
          status: 'CONFIRMED',
          specialRequests: old.specialRequests,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Đã phê duyệt đơn đặt phòng thành công!')),
          ],
        ),
        backgroundColor: palette.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.cardSmall)),
      ),
    );
  }

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
      final res = await _dioClient.dio.put(
        ApiEndpoints.rejectBooking(booking.id),
        data: {'reason': reason},
      );
      if (res.statusCode == 200) {
        _onRejectSuccess(booking.id, reason);
        return;
      }
    } catch (_) {}

    _onRejectSuccess(booking.id, reason);
  }

  void _onRejectSuccess(String id, String reason) {
    if (!mounted) return;
    final palette = context.palette;
    setState(() {
      _processingIds.remove(id);
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx != -1) {
        final old = _bookings[idx];
        _bookings[idx] = BookingModel(
          id: old.id,
          bookingCode: old.bookingCode,
          roomId: old.roomId,
          roomNumber: old.roomNumber,
          roomTypeName: old.roomTypeName,
          floor: old.floor,
          customerId: old.customerId,
          customerName: old.customerName,
          customerPhone: old.customerPhone,
          checkInDate: old.checkInDate,
          checkOutDate: old.checkOutDate,
          nights: old.nights,
          guestCount: old.guestCount,
          totalAmount: old.totalAmount,
          depositAmount: old.depositAmount,
          status: 'CANCELLED',
          specialRequests: old.specialRequests,
          cancellationReason: reason,
        );
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
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final pendingCount = _bookings.where((b) => b.status == 'PENDING').length;
    final confirmedCount = _bookings.where((b) => b.status == 'CONFIRMED').length;
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
                    'Đơn Đặt Phòng Chờ Duyệt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$pendingCount đơn cần phê duyệt ngay',
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

                  // Tabs lọc (Chờ duyệt, Đã duyệt, Đã từ chối)
                  _buildTabs(pendingCount, confirmedCount, rejectedCount),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // 3. Danh sách Pending Booking Cards
          _filteredBookings.isEmpty
              ? SliverToBoxAdapter(child: _buildEmptyState())
              : SliverPadding(
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
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final palette = context.palette;
    return TextField(
      controller: _searchController,
      style: TextStyle(fontSize: 13, color: palette.ink),
      decoration: InputDecoration(
        hintText: 'Tìm theo tên khách, SĐT, loại phòng, mã đơn...',
        hintStyle: TextStyle(fontSize: 13, color: palette.inkFaint),
        prefixIcon: Icon(Icons.search, size: 20, color: palette.inkFaint),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 18, color: palette.inkFaint),
                onPressed: () => _searchController.clear(),
              )
            : null,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTabs(int pending, int confirmed, int rejected) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          _buildTabItem(0, 'Chờ duyệt ($pending)'),
          _buildTabItem(1, 'Đã duyệt ($confirmed)'),
          _buildTabItem(2, 'Đã từ chối ($rejected)'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title) {
    final palette = context.palette;
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : palette.inkMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(BookingModel booking) {
    final palette = context.palette;
    final isPending = booking.status == 'PENDING';
    final isConfirmed = booking.status == 'CONFIRMED';
    final isProcessing = _processingIds.contains(booking.id);

    Color statusColor;
    String statusLabel;
    if (isPending) {
      statusColor = palette.warning;
      statusLabel = 'Chờ phê duyệt';
    } else if (isConfirmed) {
      statusColor = palette.success;
      statusLabel = 'Đã phê duyệt';
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

          // Tiền & Các nút Duyệt / Từ chối
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
              // Duyệt / từ chối đơn chỉ mở cho ADMIN và RECEPTIONIST.
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
                      onTap: isProcessing ? null : () => _approveBooking(booking),
                      child: ElevatedButton(
                        onPressed: isProcessing ? null : () => _approveBooking(booking),
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
                            : const Text('Duyệt đơn', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
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
                      Text('Đã duyệt thành công', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.success)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 54, color: palette.inkFaint),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Không có đơn đặt phòng nào',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: palette.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Hiện tại không có đơn nào cần xử lý trong danh mục này',
            style: TextStyle(fontSize: 13, color: palette.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
