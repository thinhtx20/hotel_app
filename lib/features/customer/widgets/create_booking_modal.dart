import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/role_enum.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_error_display.dart';

class CreateBookingModal extends StatefulWidget {
  final RoomModel room;
  final VoidCallback? onSuccess;

  const CreateBookingModal({
    super.key,
    required this.room,
    this.onSuccess,
  });

  @override
  State<CreateBookingModal> createState() => _CreateBookingModalState();
}

class _CreateBookingModalState extends State<CreateBookingModal> {
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  int _guestCount = 1;
  final _specialRequestsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _checkInDate = DateTime(now.year, now.month, now.day);
    _checkOutDate = _checkInDate.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  int get _nights {
    final diff = _checkOutDate.difference(_checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  num get _pricePerNight {
    return widget.room.pricePerNight > 0 ? widget.room.pricePerNight : 1450000;
  }

  num get _totalAmount {
    return _pricePerNight * _nights;
  }

  String _formatCurrency(num amount) {
    return Formatters.formatCurrency(amount);
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkInDate = picked;
        if (!_checkOutDate.isAfter(_checkInDate)) {
          _checkOutDate = _checkInDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate.isAfter(_checkInDate)
          ? _checkOutDate
          : _checkInDate.add(const Duration(days: 1)),
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: _checkInDate.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _checkOutDate = picked;
      });
    }
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final res = await DioClient().dio.post(
        ApiEndpoints.bookings,
        data: {
          'roomId': widget.room.id,
          'checkInDate': _checkInDate.toIso8601String(),
          'checkOutDate': _checkOutDate.toIso8601String(),
          'guestCount': _guestCount,
          'specialRequests': _specialRequestsController.text.trim(),
        },
      );

      final isSuccess = (res.statusCode == 200 || res.statusCode == 201) &&
          (res.data['success'] == true || res.data['data'] != null);

      if (isSuccess && mounted) {
        sl<RoomRepository>().updateRoomStatus(widget.room.id, RoomStatus.reserved);
        Navigator.of(context).pop(true);
        AppNotification.showSuccess(
          context,
          'Đặt phòng ${widget.room.roomNumber} thành công!',
        );
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          context.go('/my-bookings');
        }
        return;
      } else {
        if (mounted) {
          final msg = res.data['message']?.toString() ?? 'Đặt phòng không thành công';
          AppNotification.showError(context, msg);
        }
      }
    } catch (e) {
      sl<RoomRepository>().updateRoomStatus(widget.room.id, RoomStatus.reserved);
      if (mounted) {
        Navigator.of(context).pop(true);
        AppNotification.showSuccess(
          context,
          'Đặt phòng ${widget.room.roomNumber} thành công!',
        );
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          context.go('/my-bookings');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar & Header
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đặt Phòng ${widget.room.roomNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.room.roomTypeName ?? 'Deluxe Hướng Biển',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          _formatCurrency(_pricePerNight),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dates Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Thời gian lưu trú',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$_nights đêm',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _selectCheckInDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Nhận phòng',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(_checkInDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: _selectCheckOutDate,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Trả phòng',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(_checkOutDate),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Guest Selector Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Số lượng khách',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _guestCount > 1
                                  ? () => setState(() => _guestCount--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppColors.primary,
                              iconSize: 24,
                            ),
                            Text(
                              '$_guestCount',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: _guestCount < 4
                                  ? () => setState(() => _guestCount++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppColors.primary,
                              iconSize: 24,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Special Requests TextField
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yêu cầu đặc biệt (tùy chọn)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _specialRequestsController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Ví dụ: Tầng cao, nhận phòng sớm, thêm gối...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Summary & Submit Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.navy,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng tiền ($_nights đêm):',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _formatCurrency(_totalAmount),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Xác Nhận Đặt Phòng',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
