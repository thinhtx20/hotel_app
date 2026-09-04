import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/booking_repository.dart';
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

  /// Quy tắc cọc: Giá đơn trên 5tr cọc 10%, dưới 5tr không cần cọc (0đ)
  static const num depositThreshold = 5000000;
  bool get _isDepositRequired => _totalAmount > depositThreshold;
  num get _depositAmount => _isDepositRequired ? (_totalAmount * 0.1).round() : 0;

  String get _qrContent => 'LUXE COC P${widget.room.roomNumber}';

  String get _qrUrl {
    final amount = _depositAmount.toInt();
    final addInfo = Uri.encodeComponent(_qrContent);
    return 'https://img.vietqr.io/image/970423-03609837701-compact2.png?amount=$amount&addInfo=$addInfo&accountName=LUXE%20GRAND%20HOTEL';
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
      _checkAvailability();
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
      _checkAvailability();
    }
  }

  bool _isCheckingAvailability = false;
  bool _isRoomAvailable = true;

  Future<void> _checkAvailability() async {
    setState(() => _isCheckingAvailability = true);
    try {
      final availableRooms = await sl<RoomRepository>().fetchAvailable(
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guestCount: _guestCount,
      );
      if (mounted) {
        final available = availableRooms.isEmpty ||
            availableRooms.any((r) => r.id == widget.room.id);
        setState(() {
          _isRoomAvailable = available;
          _isCheckingAvailability = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingAvailability = false);
      }
    }
  }

  Future<void> _handleSuccessTransition() async {
    setState(() => _isSuccess = true);

    // Trạng thái phòng do máy chủ quyết định: đơn khách tự đặt nằm ở PENDING nên
    // phòng vẫn AVAILABLE cho tới khi lễ tân xác nhận, còn đơn nhân viên tạo
    // thẳng CONFIRMED thì máy chủ tự đẩy phòng sang RESERVED. Ở đây chỉ tải lại
    // danh sách phòng (GET /rooms công khai); không tự ghi trạng thái vì
    // PATCH /rooms/:id/status chỉ mở cho ADMIN/RECEPTIONIST và trả 403 cho
    // tài khoản khách hàng.
    final refreshRooms =
        sl<RoomRepository>().fetchRooms(forceRefresh: true).catchError((_) {});

    // Chờ dấu tick vẽ xong và trải nghiệm thị giác trọn vẹn (khoảng 1.1 giây)
    await Future.delayed(const Duration(milliseconds: 1100));
    await refreshRooms;

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
      // Chỉ gửi đúng các trường CreateBookingDto chấp nhận: máy chủ tự tính
      // tiền phòng và tự chặn trùng lịch, còn phương thức / trạng thái thanh
      // toán cọc do lễ tân xác nhận ở bước duyệt đơn.
      final payload = {
        'roomId': widget.room.id,
        'checkInDate': _checkInDate.toIso8601String(),
        'checkOutDate': _checkOutDate.toIso8601String(),
        'guestCount': _guestCount,
        'depositAmount': _depositAmount,
        if (_specialRequestsController.text.trim().isNotEmpty)
          'specialRequests': _specialRequestsController.text.trim(),
      };

      await sl<BookingRepository>().create(payload);

      if (mounted) {
        await _handleSuccessTransition();
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          e,
          title: 'Đặt phòng không thành công',
        );
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

                          // 4. Bảng Tóm Tắt Chi Phí & Chính Sách Cọc
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: palette.surfaceMuted,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: palette.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Divider(color: palette.divider, height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Tiền cọc giữ phòng:',
                                          style: TextStyle(fontSize: 13, color: palette.inkMuted),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _isDepositRequired
                                                ? AppColors.secondary.withValues(alpha: 0.15)
                                                : AppColors.available.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            _isDepositRequired ? '10% (> 5tr)' : 'Miễn cọc (< 5tr)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: _isDepositRequired ? AppColors.secondaryDark : AppColors.availableInk,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _isDepositRequired ? _formatCurrency(_depositAmount) : '0 ₫',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _isDepositRequired ? AppColors.secondaryDark : AppColors.availableInk,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isDepositRequired) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Thanh toán tại quầy khi nhận phòng:',
                                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                                      ),
                                      Text(
                                        _formatCurrency(_totalAmount - _depositAmount),
                                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.ink),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // 5. Khối Hiển Thị Mã QR Cọc (Hoặc Banner Miễn Cọc)
                          _buildDepositSection(palette, textTheme),

                          const SizedBox(height: AppSpacing.md),

                          if (!_isRoomAvailable) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: palette.errorSurface,
                                borderRadius: BorderRadius.circular(
                                    AppRadius.md),
                                border: Border.all(
                                    color: palette.error
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: palette.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Phòng này không còn trống trong khoảng thời gian đã chọn.',
                                      style: TextStyle(
                                        color: palette.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 6. Nút Xác Nhận Đặt Phòng
                          CustomButton(
                            text: _isCheckingAvailability
                                ? 'Đang kiểm tra phòng trống...'
                                : (_isDepositRequired
                                    ? 'Tôi Đã Chuyển Cọc & Đặt Phòng'
                                    : 'Xác Nhận Đặt Phòng (Không Cần Cọc)'),
                            isGold: true,
                            height: 50,
                            isLoading: _isSubmitting,
                            onPressed: (!_isRoomAvailable ||
                                    _isCheckingAvailability)
                                ? null
                                : _submitBooking,
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

  /// Khối hiển thị VietQR cọc 10% nếu tổng tiền > 5.000.000đ, hoặc Banner miễn cọc nếu <= 5tr
  Widget _buildDepositSection(AppPalette palette, TextTheme textTheme) {
    if (_isDepositRequired) {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: palette.accent.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.accent.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Huy hiệu yêu cầu cọc
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 16, color: palette.accent),
                      const SizedBox(width: 5),
                      Text(
                        'YÊU CẦU ĐẶT CỌC 10% (> 5.000.000 ₫)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Quét Mã VietQR Chuyển Tiền Cọc',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Đơn phòng trên 5 triệu yêu cầu cọc 10% (${_formatCurrency(_depositAmount)}) để đảm bảo giữ phòng.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: palette.inkMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Mã QR VietQR chuẩn ngân hàng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: _qrUrl,
                      width: 185,
                      height: 185,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => SizedBox(
                        width: 185,
                        height: 185,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.accent,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 185,
                        height: 185,
                        color: palette.surfaceMuted,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, color: palette.inkMuted),
                            const SizedBox(height: 4),
                            Text('Không tải được QR', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 14, color: AppColors.secondaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'Tự động điền số tiền & nội dung CK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Khối Thông Tin Tài Khoản với Nút Copy 1-Chạm
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  _buildCopyRow(
                    label: 'Ngân hàng',
                    value: 'MB Bank (Quân Đội)',
                    palette: palette,
                  ),
                  Divider(color: palette.divider, height: 14),
                  _buildCopyRow(
                    label: 'Số tài khoản',
                    value: '03609837701',
                    isCopyable: true,
                    copyText: '03609837701',
                    palette: palette,
                  ),
                  Divider(color: palette.divider, height: 14),
                  _buildCopyRow(
                    label: 'Chủ tài khoản',
                    value: 'LUXE GRAND HOTEL',
                    palette: palette,
                  ),
                  Divider(color: palette.divider, height: 14),
                  _buildCopyRow(
                    label: 'Số tiền cọc (10%)',
                    value: _formatCurrency(_depositAmount),
                    isHighlight: true,
                    isCopyable: true,
                    copyText: '${_depositAmount.toInt()}',
                    palette: palette,
                  ),
                  Divider(color: palette.divider, height: 14),
                  _buildCopyRow(
                    label: 'Nội dung chuyển khoản',
                    value: _qrContent,
                    isHighlight: true,
                    isCopyable: true,
                    copyText: _qrContent,
                    palette: palette,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: palette.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Số tiền còn lại ${_formatCurrency(_totalAmount - _depositAmount)} sẽ thanh toán khi nhận phòng tại khách sạn.',
                    style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.available.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.available.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.available.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: AppColors.availableInk,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MIỄN PHÍ ĐẶT CỌC (0 ₫)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.availableInk,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Đơn đặt phòng dưới 5.000.000 ₫ (${_formatCurrency(_totalAmount)}) không yêu cầu đặt cọc trước. Quý khách thanh toán toàn bộ khi nhận phòng tại khách sạn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.ink,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCopyRow({
    required String label,
    required String value,
    bool isCopyable = false,
    String? copyText,
    bool isHighlight = false,
    required AppPalette palette,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: palette.inkMuted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                color: isHighlight ? palette.accent : palette.ink,
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: copyText ?? value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép $label!'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.copy_rounded, size: 14, color: palette.accent),
                ),
              ),
            ],
          ],
        ),
      ],
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
            _isDepositRequired
                ? 'Đã ghi nhận đơn đặt phòng ${widget.room.roomNumber} ($_nights đêm) và thông tin cọc ${_formatCurrency(_depositAmount)}. Lễ tân sẽ liên hệ duyệt đơn sớm nhất!'
                : 'Phòng ${widget.room.roomNumber} đã được đặt thành công ($_nights đêm, không cần cọc). Quý khách sẽ thanh toán khi nhận phòng!',
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
