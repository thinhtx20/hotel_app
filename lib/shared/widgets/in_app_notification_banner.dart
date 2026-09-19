import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../di/injection_container.dart';
import '../../features/notifications/models/app_notification_model.dart';
import '../../features/notifications/repositories/notification_repository.dart';

/// Bộ điều khiển & hiển thị thông báo In-App đa phong cách (5 In-App Notification Styles).
/// Tự động thích ứng theo phong cách người dùng đã chọn hoặc kiểu tùy chỉnh khi gọi.
class InAppNotificationBanner {
  static OverlayEntry? _currentEntry;
  static _InAppBannerWidgetState? _currentState;

  /// Hiển thị thông báo nổi trên màn hình với kiểu dáng mong muốn
  static void show({
    BuildContext? context,
    required String title,
    required String body,
    AppNotificationStyle? style,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
    IconData? icon,
    String? category,
    AppNotificationCategory? notificationCategory,
    Duration duration = const Duration(milliseconds: 4500),
  }) {
    // 1. Phản hồi rung haptic sang trọng nếu được bật
    try {
      if (sl.isRegistered<NotificationRepository>()) {
        if (sl<NotificationRepository>().hapticEnabled) {
          HapticFeedback.lightImpact();
        }
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      HapticFeedback.lightImpact();
    }

    // 2. Tìm OverlayState từ AppRouter hoặc Context
    final overlayState = AppRouter.rootNavigatorKey.currentState?.overlay ??
        (context != null ? Overlay.of(context) : null);

    if (overlayState == null) {
      debugPrint('⚠️ [InAppNotificationBanner] Không tìm thấy OverlayState');
      return;
    }

    // 3. Xác định kiểu thông báo (nếu không chỉ định, lấy từ thiết lập người dùng)
    AppNotificationStyle effectiveStyle = style ?? AppNotificationStyle.luxuryBanner;
    if (style == null) {
      try {
        if (sl.isRegistered<NotificationRepository>()) {
          effectiveStyle = sl<NotificationRepository>().preferredStyle;
        }
      } catch (_) {}
    }

    // 4. Nếu đang có thông báo hiển thị, gỡ bỏ nhanh để thay thế
    dismiss(immediately: true);

    // 5. Tạo OverlayEntry mới
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _InAppBannerWidget(
        title: title,
        body: body,
        style: effectiveStyle,
        data: data,
        icon: icon,
        category: category,
        notificationCategory: notificationCategory,
        duration: duration,
        onTap: () {
          dismiss(immediately: true);
          onTap?.call();
        },
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          if (_currentEntry == entry) {
            _currentEntry = null;
            _currentState = null;
          }
        },
        onStateCreated: (state) {
          _currentState = state;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  /// Đóng thông báo đang hiển thị
  static void dismiss({bool immediately = false}) {
    if (immediately) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
      _currentState = null;
    } else {
      _currentState?.dismiss();
    }
  }
}

class _InAppBannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final AppNotificationStyle style;
  final Map<String, dynamic>? data;
  final IconData? icon;
  final String? category;
  final AppNotificationCategory? notificationCategory;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;
  final ValueChanged<_InAppBannerWidgetState> onStateCreated;

  const _InAppBannerWidget({
    required this.title,
    required this.body,
    required this.style,
    this.data,
    this.icon,
    this.category,
    this.notificationCategory,
    required this.duration,
    this.onTap,
    required this.onDismiss,
    required this.onStateCreated,
  });

  @override
  State<_InAppBannerWidget> createState() => _InAppBannerWidgetState();
}

class _InAppBannerWidgetState extends State<_InAppBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _autoDismissTimer;
  double _dragOffsetY = 0.0;
  bool _isExpandedDynamicIsland = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 260),
    );

    final isBottom = widget.style == AppNotificationStyle.bottomToast;

    _slideAnimation = Tween<Offset>(
      begin: isBottom ? const Offset(0.0, 1.2) : const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    // Bắt đầu hiệu ứng xuất hiện
    _animController.forward();

    // Hẹn giờ tự động đóng (trừ dạng dialogAlert cần người dùng chủ động tương tác)
    if (widget.style != AppNotificationStyle.dialogAlert) {
      _autoDismissTimer = Timer(widget.duration, () {
        if (mounted) dismiss();
      });
    }
  }

  bool _isDismissing = false;

  void dismiss({bool immediately = false}) {
    _autoDismissTimer?.cancel();
    if (immediately) {
      widget.onDismiss();
      return;
    }
    if (_isDismissing) return;
    _isDismissing = true;

    if (_animController.isAnimating || _animController.isCompleted) {
      _animController.reverse().then((_) {
        widget.onDismiss();
      }).catchError((_) {
        widget.onDismiss();
      });
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    widget.onDismiss();
    super.dispose();
  }

  Color _getCategoryColor() {
    if (widget.notificationCategory != null) {
      return widget.notificationCategory!.color;
    }
    final lower = '${widget.title} ${widget.category ?? ''}'.toLowerCase();
    if (lower.contains('trả phòng') || lower.contains('đặt phòng') || lower.contains('phòng')) {
      return const Color(0xFFD97706);
    }
    if (lower.contains('hóa đơn') || lower.contains('thanh toán') || lower.contains('tiền')) {
      return const Color(0xFF059669);
    }
    if (lower.contains('dịch vụ') || lower.contains('buồng phòng') || lower.contains('spa')) {
      return const Color(0xFF6366F1);
    }
    if (lower.contains('ưu đãi') || lower.contains('khuyến mãi') || lower.contains('voucher') || lower.contains('vip')) {
      return const Color(0xFFEC4899);
    }
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    // 1. Trường hợp Modal Dialog Alert (Pop-up giữa màn hình)
    if (widget.style == AppNotificationStyle.dialogAlert) {
      return IgnorePointer(
        ignoring: _isDismissing,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildDialogAlertOverlay(context),
          ),
        ),
      );
    }

    // 2. Trường hợp Floating Bottom Toast (Đáy màn hình)
    if (widget.style == AppNotificationStyle.bottomToast) {
      return Positioned(
        bottom: 84, // Phía trên bottom nav bar
        left: 14,
        right: 14,
        child: IgnorePointer(
          ignoring: _isDismissing,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                ),
              );
            },
            child: _buildBottomToast(context),
          ),
        ),
      );
    }

    // 3. Các kiểu thông báo đỉnh màn hình (Banner, Dynamic Island, Glass Card)
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        ignoring: _isDismissing,
        child: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final effectiveOffset = _slideAnimation.value +
                Offset(0.0, _dragOffsetY / (mediaQuery.size.height > 0 ? mediaQuery.size.height : 800));

            return SlideTransition(
              position: AlwaysStoppedAnimation(effectiveOffset),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: widget.style == AppNotificationStyle.dynamicIsland
                    ? ScaleTransition(scale: _scaleAnimation, child: child)
                    : child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < 0) {
                  setState(() {
                    _dragOffsetY += details.primaryDelta!;
                  });
                }
              },
              onVerticalDragEnd: (details) {
                if (_dragOffsetY < -20 ||
                    (details.primaryVelocity != null && details.primaryVelocity! < -100)) {
                  dismiss();
                } else {
                  setState(() {
                    _dragOffsetY = 0.0;
                  });
                }
              },
              child: Material(
                color: Colors.transparent,
                child: _buildNotificationContent(context),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildNotificationContent(BuildContext context) {
    switch (widget.style) {
      case AppNotificationStyle.luxuryBanner:
        return _buildLuxuryBanner(context);
      case AppNotificationStyle.dynamicIsland:
        return _buildDynamicIsland(context);
      case AppNotificationStyle.glassCard:
        return _buildGlassCard(context);
      case AppNotificationStyle.bottomToast:
        return _buildBottomToast(context);
      case AppNotificationStyle.dialogAlert:
        return const SizedBox.shrink();
    }
  }

  // ===========================================================================
  // KIỂU 1: MODERN LUXURY BANNER (Hoàng gia Midnight Navy + Viền vàng 24K)
  // ===========================================================================
  Widget _buildLuxuryBanner(BuildContext context) {
    final accentColor = _getCategoryColor();

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.navy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dòng nhãn nhận diện
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.auto_awesome, size: 10, color: AppColors.secondaryLight),
                            SizedBox(width: 4),
                            Text(
                              'LUXE CONCIERGE',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.category ?? 'Thông báo khách sạn',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Vừa xong',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: dismiss,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hàng nội dung chính & Icon chuông vàng
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppGradients.gold,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon ?? Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFCBD5E1),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Xem',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.secondaryLight,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ProgressCountdownBar(duration: widget.duration),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KIỂU 2: DYNAMIC ISLAND CAPSULE (Viên thuốc Dynamic Island iOS)
  // ===========================================================================
  Widget _buildDynamicIsland(BuildContext context) {
    final accentColor = _getCategoryColor();

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        constraints: BoxConstraints(
          maxWidth: _isExpandedDynamicIsland ? 380 : 340,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1120),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            // Chấm phát sáng pulsating dot phong cách iOS Capsule
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Icon(
                widget.icon ?? Icons.bolt_rounded,
                color: accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),

            // Tiêu đề & nội dung thu gọn
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.body,
                    maxLines: _isExpandedDynamicIsland ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Nút mở rộng hoặc tắt
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpandedDynamicIsland = !_isExpandedDynamicIsland;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isExpandedDynamicIsland
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: dismiss,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KIỂU 3: FROSTED GLASS CARD (Kính mờ pha lê xuyên thấu Glassmorphism)
  // ===========================================================================
  Widget _buildGlassCard(BuildContext context) {
    final accentColor = _getCategoryColor();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon ?? Icons.auto_awesome, size: 12, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.category ?? 'Thông báo',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Vừa xong',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.body,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.5,
                            color: Color(0xFFE2E8F0),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Chi tiết',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // KIỂU 4: FLOATING BOTTOM TOAST (Thanh nổi đáy màn hình)
  // ===========================================================================
  Widget _buildBottomToast(BuildContext context) {
    final accentColor = _getCategoryColor();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: accentColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thanh màu đứng nhận diện danh mục
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),

            // Icon biểu tượng
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon ?? Icons.notifications_active_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Tiêu đề & nội dung vắn tắt
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Nút Xem
            TextButton(
              onPressed: () {
                widget.onTap?.call();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Xem',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),

            GestureDetector(
              onTap: dismiss,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KIỂU 5: LUXURY MODAL DIALOG (Pop-up trung tâm làm mờ nền)
  // ===========================================================================
  Widget _buildDialogAlertOverlay(BuildContext context) {
    final accentColor = _getCategoryColor();

    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppGradients.navy,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon huy hiệu tỏa sáng
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon ?? Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),

                // Nhãn danh mục
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.category ?? 'Thông báo quan trọng',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tiêu đề
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Chi tiết
                Text(
                  widget.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.5,
                    color: Color(0xFFCBD5E1),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Nút hành động kép
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: dismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Để sau',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onTap?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Xem ngay',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dải thanh sáng đếm ngược thời gian tự đóng thông báo
class _ProgressCountdownBar extends StatefulWidget {
  final Duration duration;

  const _ProgressCountdownBar({required this.duration});

  @override
  State<_ProgressCountdownBar> createState() => _ProgressCountdownBarState();
}

class _ProgressCountdownBarState extends State<_ProgressCountdownBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LinearProgressIndicator(
          value: 1.0 - _controller.value,
          minHeight: 2.5,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryLight),
        );
      },
    );
  }
}
