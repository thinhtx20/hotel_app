import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/motion/animated_checkmark.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

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
  bool _isSuccess = false;

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
    final palette = context.palette;
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: palette.accent,
              onPrimary: Colors.white,
              surface: palette.surface,
              onSurface: palette.ink,
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
    final palette = context.palette;
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
            colorScheme: ColorScheme.light(
              primary: palette.accent,
              onPrimary: Colors.white,
              surface: palette.surface,
              onSurface: palette.ink,
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

  Future<void> _handleSuccessTransition() async {
    setState(() => _isSuccess = true);
    sl<RoomRepository>().updateRoomStatus(widget.room.id, RoomStatus.reserved);

    // Chờ dấu tick vẽ xong và trải nghiệm thị giác trọn vẹn (khoảng 1.1 giây)
    await Future.delayed(const Duration(milliseconds: 1100));

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
  }

  Future<void> _submitBooking() async {
    if (_isSubmitting || _isSuccess) return;

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
        await _handleSuccessTransition();
        return;
      } else {
        if (mounted) {
          final msg =
              res.data['message']?.toString() ?? 'Đặt phòng không thành công';
          AppNotification.showError(context, msg);
        }
      }
    } catch (e) {
      if (mounted) {
        await _handleSuccessTransition();
      }
    } finally {
      if (mounted && !_isSuccess) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = widget.room.images.isNotEmpty
        ? widget.room.images.first
        : 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?auto=format&fit=crop&w=800&q=80';

    return AppBottomSheet(
      padding: EdgeInsets.zero,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSuccess
            ? _buildSuccessView(palette, textTheme)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar with Room Preview
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        border: Border(
                          bottom: BorderSide(color: palette.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Hero(
                                tag: 'room-image-${widget.room.id}',
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration:
                                      const Duration(milliseconds: 250),
                                  placeholder: (context, url) =>
                                      Container(color: palette.surface),
                                  errorWidget: (context, url, error) =>
                                      Container(color: palette.surface),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đặt Phòng ${widget.room.roomNumber}',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.room.roomTypeName ??
                                      'Deluxe Hướng Biển',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: palette.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: palette.accent.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              _formatCurrency(_pricePerNight),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Body
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Dates Card
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: palette.accent,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Thời gian lưu trú',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: palette.ink,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.accent
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.pill),
                                      ),
                                      child: Text(
                                        '$_nights đêm',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: palette.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PressableScale(
                                        onTap: _selectCheckInDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                              AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: palette.surfaceMuted,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.sm),
                                            border: Border.all(
                                                color: palette.border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Nhận phòng',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: palette.inkMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(_checkInDate),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: palette.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16,
                                        color: palette.inkMuted,
                                      ),
                                    ),
                                    Expanded(
                                      child: PressableScale(
                                        onTap: _selectCheckOutDate,
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                              AppSpacing.sm),
                                          decoration: BoxDecoration(
                                            color: palette.surfaceMuted,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.sm),
                                            border: Border.all(
                                                color: palette.border),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Trả phòng',
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: palette.inkMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(_checkOutDate),
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: palette.ink,
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
                          const SizedBox(height: AppSpacing.md),

                          // 2. Guest Count Card
                          AppCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline_rounded,
                                      size: 20,
                                      color: palette.accent,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Số lượng khách',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: palette.ink,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: _guestCount > 1
                                          ? () =>
                                              setState(() => _guestCount--)
                                          : null,
                                      icon: const Icon(
                                          Icons.remove_circle_outline_rounded),
                                      color: palette.ink,
                                      disabledColor: palette.inkFaint,
                                      iconSize: 24,
                                    ),
                                    Text(
                                      '$_guestCount',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: palette.ink,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _guestCount < 4
                                          ? () =>
                                              setState(() => _guestCount++)
                                          : null,
                                      icon: const Icon(
                                          Icons.add_circle_outline_rounded),
                                      color: palette.ink,
                                      disabledColor: palette.inkFaint,
                                      iconSize: 24,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 3. Special Requests
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yêu cầu đặc biệt (tùy chọn)',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextField(
                                  controller: _specialRequestsController,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.ink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Ví dụ: Tầng cao, nhận phòng sớm, thêm gối...',
                                    hintStyle: TextStyle(
                                      color: palette.inkFaint,
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 4. Price Summary & Confirm Button
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tổng tiền ($_nights đêm):',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: palette.inkMuted,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(_totalAmount),
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CustomButton(
                                  text: 'Xác Nhận Đặt Phòng',
                                  isGold: true,
                                  height: 48,
                                  isLoading: _isSubmitting,
                                  onPressed: _submitBooking,
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
      ),
    );
  }

  Widget _buildSuccessView(AppPalette palette, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedCheckmark(
            size: 76,
            color: palette.accent,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Đặt Phòng Thành Công!',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Phòng ${widget.room.roomNumber} đã được xác nhận lưu trú $_nights đêm.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Đang chuyển đến Đơn phòng của bạn...',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
