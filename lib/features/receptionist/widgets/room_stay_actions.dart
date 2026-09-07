import 'package:flutter/material.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/booking_repository.dart';

/// Khối "Thủ tục lễ tân" trong sheet chi tiết phòng của sơ đồ buồng phòng.
///
/// Tự tải các đơn đang gắn với phòng (`CONFIRMED` = chờ khách đến nhận phòng,
/// `CHECKED_IN` = khách đang ở) rồi mở đúng nút Check-in / Check-out cho lễ
/// tân, thay vì bắt họ sang tab "Hôm nay" tìm lại đơn.
class RoomStayActions extends StatefulWidget {
  final RoomModel room;
  final BookingRepository bookingRepository;

  /// `POST /bookings/:id/check-in` chỉ mở cho ADMIN và RECEPTIONIST (§3.5).
  final bool canCheckIn;

  /// `POST /bookings/:id/check-out` — cùng nhóm quyền nhân viên.
  final bool canCheckOut;

  final ValueChanged<BookingModel> onCheckIn;
  final ValueChanged<BookingModel> onCheckOut;

  /// Cho phép lễ tân mở modal nhận phòng trực tiếp cho khách vãng lai
  final VoidCallback? onWalkInCheckIn;

  const RoomStayActions({
    super.key,
    required this.room,
    required this.bookingRepository,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.onCheckIn,
    required this.onCheckOut,
    this.onWalkInCheckIn,
  });

  @override
  State<RoomStayActions> createState() => RoomStayActionsState();
}

class RoomStayActionsState extends State<RoomStayActions> {
  bool _isLoading = true;
  String? _errorMessage;

  /// Lượt khách đang ở phòng này (nếu có) — nguồn của nút Check-out.
  BookingModel? _currentStay;

  /// Đơn đã xác nhận, gần ngày nhận phòng nhất — nguồn của nút Check-in.
  BookingModel? _upcomingArrival;

  BookingModel? get currentStay => _currentStay;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> reload() => _loadBookings();

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookings = await widget.bookingRepository.fetchBookings(
        roomId: widget.room.id,
        statuses: const ['CONFIRMED', 'CHECKED_IN'],
        limit: 20,
      );
      if (!mounted) return;

      final stays = bookings.where((b) => b.status == 'CHECKED_IN').toList()
        ..sort((a, b) => a.checkOutDate.compareTo(b.checkOutDate));
      final arrivals = bookings.where((b) => b.status == 'CONFIRMED').toList()
        ..sort((a, b) => a.checkInDate.compareTo(b.checkInDate));

      setState(() {
        _currentStay = stays.isEmpty ? null : stays.first;
        _upcomingArrival = arrivals.isEmpty ? null : arrivals.first;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiError.fromDynamic(e).displayMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'Thủ tục lễ tân:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: palette.ink,
              ),
            ),
            const Spacer(),
            if (!_isLoading)
              TextButton.icon(
                onPressed: _loadBookings,
                icon: Icon(Icons.refresh_rounded, size: 15, color: palette.inkMuted),
                label: Text(
                  'Tải lại',
                  style: TextStyle(fontSize: 12, color: palette.inkMuted),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildBody(palette),
      ],
    );
  }

  Widget _buildBody(AppPalette palette) {
    if (_isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Đang tải lượt lưu trú của phòng...',
            style: TextStyle(fontSize: 13, color: palette.inkMuted),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return _buildNoticeBox(
        palette: palette,
        color: palette.error,
        ink: palette.errorInk,
        icon: Icons.cloud_off_rounded,
        message: _errorMessage!,
      );
    }

    // Vai trò thiếu quyền thì coi như không có đơn để thao tác.
    final stay = widget.canCheckOut ? _currentStay : null;
    final arrival = widget.canCheckIn ? _upcomingArrival : null;

    if (stay == null && arrival == null) {
      if (widget.canCheckIn &&
          widget.onWalkInCheckIn != null &&
          (widget.room.status == RoomStatus.available ||
              widget.room.status == RoomStatus.cleaning)) {
        return _buildWalkInCard(palette);
      }

      return _buildNoticeBox(
        palette: palette,
        color: palette.inkMuted,
        ink: palette.inkMuted,
        icon: Icons.event_busy_outlined,
        message:
            'Phòng này chưa có đơn nào cần làm thủ tục nhận / trả phòng.',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (arrival != null)
          _buildBookingCard(
            palette: palette,
            booking: arrival,
            color: palette.statusReserved,
            ink: palette.statusReservedInk,
            icon: Icons.login_rounded,
            heading: 'Chờ nhận phòng',
            detail:
                'Nhận: ${Formatters.formatDate(arrival.checkInDate)} • Trả: ${Formatters.formatDate(arrival.checkOutDate)} • ${arrival.guestCount} khách',
            actionLabel: 'Nhận phòng (Check-in)',
            onAction: () => widget.onCheckIn(arrival),
          ),
        if (arrival != null && stay != null)
          const SizedBox(height: AppSpacing.sm),
        if (stay != null)
          _buildBookingCard(
            palette: palette,
            booking: stay,
            color: palette.statusOccupied,
            ink: palette.statusOccupiedInk,
            icon: Icons.logout_rounded,
            heading: 'Khách đang lưu trú',
            detail:
                'Trả dự kiến: ${Formatters.formatDate(stay.checkOutDate)} • ${stay.nightsCount} đêm • ${Formatters.formatCurrency(stay.totalAmount)}',
            actionLabel: 'Trả phòng & Xuất hóa đơn',
            onAction: () => widget.onCheckOut(stay),
          ),
      ],
    );
  }

  Widget _buildNoticeBox({
    required AppPalette palette,
    required Color color,
    required Color ink,
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard({
    required AppPalette palette,
    required BookingModel booking,
    required Color color,
    required Color ink,
    required IconData icon,
    required String heading,
    required String detail,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ink),
              const SizedBox(width: 6),
              Text(
                heading,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const Spacer(),
              Text(
                booking.displayCode,
                style: TextStyle(fontSize: 11, color: palette.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${booking.displayCustomerName}'
            '${booking.displayCustomerPhone != null ? ' • ${booking.displayCustomerPhone}' : ''}',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(fontSize: 12, color: palette.inkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(icon, size: 17, color: Colors.white),
              label: Text(
                actionLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalkInCard(AppPalette palette) {
    final isAvailable = widget.room.status == RoomStatus.available;
    final statusColor = isAvailable ? palette.statusAvailable : palette.statusCleaning;
    final statusInk = isAvailable ? palette.statusAvailableInk : palette.statusCleaningInk;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAvailable
                      ? Icons.meeting_room_outlined
                      : Icons.cleaning_services_outlined,
                  size: 16,
                  color: statusInk,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAvailable
                          ? 'Phòng đang trống & sẵn sàng'
                          : 'Phòng đang trong trạng thái dọn dẹp',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: statusInk,
                      ),
                    ),
                    Text(
                      'Phòng này chưa có đơn nào cần làm thủ tục nhận / trả phòng.',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onWalkInCheckIn,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17, color: Colors.white),
              label: const Text(
                'Nhận phòng khách vãng lai (Walk-in)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.statusOccupied,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
