import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../models/app_notification_model.dart';
import '../repositories/notification_repository.dart';

/// Màn hình Cài đặt & Tùy chọn kiểu thông báo phong cách Modern Luxury.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late final NotificationRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = sl<NotificationRepository>();
    _repo.addListener(_onRepoChange);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChange);
    super.dispose();
  }

  void _onRepoChange() {
    if (mounted) setState(() {});
  }

  void _testTriggerStyle(AppNotificationStyle style) {
    switch (style) {
      case AppNotificationStyle.luxuryBanner:
        AppNotification.showLuxuryBanner(
          context: context,
          title: 'Nhắc nhở hạn trả phòng',
          body: 'Phòng Deluxe 302 của Quý khách sẽ đến hạn trả phòng lúc 12:00 hôm nay.',
          category: 'Nhắc nhở trả phòng',
          icon: Icons.hourglass_top_rounded,
          notificationCategory: AppNotificationCategory.booking,
          onTap: () => context.go('/my-bookings'),
        );
        break;

      case AppNotificationStyle.dynamicIsland:
        AppNotification.showDynamicIsland(
          context: context,
          title: 'Hóa đơn dịch vụ mới',
          body: 'Dịch vụ Room Service ẩm thực đêm trị giá 350.000đ đã được tạo.',
          category: 'Thanh toán & Hóa đơn',
          icon: Icons.receipt_long_rounded,
          notificationCategory: AppNotificationCategory.payment,
          onTap: () => context.go('/my-bookings'),
        );
        break;

      case AppNotificationStyle.glassCard:
        AppNotification.showGlassCard(
          context: context,
          title: 'Dịch vụ buồng phòng hoàn tất',
          body: 'Đội ngũ dọn phòng đã bổ sung khăn tắm cao cấp và hoa tươi.',
          category: 'Dịch vụ phòng',
          icon: Icons.room_service_rounded,
          notificationCategory: AppNotificationCategory.service,
          onTap: () => context.go('/services'),
        );
        break;

      case AppNotificationStyle.bottomToast:
        AppNotification.showBottomToast(
          context: context,
          title: 'Voucher ẩm thực VIP 20%',
          body: 'Ưu đãi Buffet tối Hoàng Gia tại Rooftop Paradise.',
          category: 'Ưu đãi & Đặc quyền',
          icon: Icons.card_giftcard_rounded,
          notificationCategory: AppNotificationCategory.promotion,
          onTap: () => context.go('/services'),
        );
        break;

      case AppNotificationStyle.dialogAlert:
        AppNotification.showDialogAlert(
          context: context,
          title: 'Đặc quyền nâng cấp phòng VIP',
          body: 'Chào mừng Quý khách! Khách sạn xin gửi tặng đặc quyền nâng cấp phòng Executive Suite miễn phí trong kỳ nghỉ này.',
          category: 'Đặc quyền thành viên',
          icon: Icons.stars_rounded,
          notificationCategory: AppNotificationCategory.system,
          onTap: () => context.go('/my-bookings'),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: palette.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cài đặt thông báo',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: palette.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Mục chọn Kiểu hiển thị thông báo In-App
          Text(
            'KIỂU HIỂN THỊ THÔNG BÁO IN-APP',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn phong cách giao diện ưa thích khi nhận thông báo trong ứng dụng. Bạn có thể bấm "Xem thử" để chiêm ngưỡng hiệu ứng.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              color: palette.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          ...AppNotificationStyle.values.map((style) {
            final isSelected = _repo.preferredStyle == style;
            return _buildStyleCard(
              context: context,
              style: style,
              isSelected: isSelected,
              onSelect: () {
                _repo.setPreferredStyle(style);
                AppNotification.showSuccess(
                  context,
                  'Đã chọn ${style.displayName} làm kiểu thông báo mặc định',
                );
              },
              onPreview: () => _testTriggerStyle(style),
            );
          }),

          const SizedBox(height: 28),

          // 2. Phân loại thông báo
          Text(
            'PHÂN LOẠI THÔNG BÁO',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Đặt phòng & Nhắc hạn',
                  subtitle: 'Xác nhận phòng, thẻ phòng, nhắc giờ trả phòng',
                  icon: Icons.meeting_room_outlined,
                  iconColor: const Color(0xFFD97706),
                  value: _repo.bookingEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(booking: val),
                ),
                Divider(height: 1, indent: 56, color: palette.divider),
                _buildSwitchTile(
                  title: 'Thanh toán & Hóa đơn',
                  subtitle: 'Hóa đơn dịch vụ mới, đối chiếu và hoàn cọc',
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFF059669),
                  value: _repo.paymentEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(payment: val),
                ),
                Divider(height: 1, indent: 56, color: palette.divider),
                _buildSwitchTile(
                  title: 'Dịch vụ phòng & Tiện ích',
                  subtitle: 'Dọn buồng phòng, đồ uống minibar, spa & gym',
                  icon: Icons.room_service_outlined,
                  iconColor: const Color(0xFF6366F1),
                  value: _repo.serviceEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(service: val),
                ),
                Divider(height: 1, indent: 56, color: palette.divider),
                _buildSwitchTile(
                  title: 'Ưu đãi & Đặc quyền VIP',
                  subtitle: 'Voucher ẩm thực, giảm giá phòng, điểm thưởng',
                  icon: Icons.card_giftcard_outlined,
                  iconColor: const Color(0xFFEC4899),
                  value: _repo.promoEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(promo: val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 3. Hiệu ứng phản hồi
          Text(
            'HIỆU ỨNG & ÂM THANH',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border, width: 1),
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: 'Rung phản hồi sang trọng (Haptic)',
                  subtitle: 'Rung nhẹ tinh tế khi có thông báo mới xuất hiện',
                  icon: Icons.vibration_rounded,
                  iconColor: palette.accent,
                  value: _repo.hapticEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(haptic: val),
                ),
                Divider(height: 1, indent: 56, color: palette.divider),
                _buildSwitchTile(
                  title: 'Âm thanh thông báo',
                  subtitle: 'Chuông báo khi nhận được thông báo từ khách sạn',
                  icon: Icons.volume_up_outlined,
                  iconColor: palette.accent,
                  value: _repo.soundEnabled,
                  onChanged: (val) => _repo.updateCategorySettings(sound: val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStyleCard({
    required BuildContext context,
    required AppNotificationStyle style,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onPreview,
  }) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? (palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB))
                : palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary
                  : palette.border,
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Icon đại diện
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppGradients.gold : null,
                  color: isSelected ? null : (palette.isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  style.icon,
                  color: isSelected ? Colors.white : palette.ink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Tên & mô tả
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          style.displayName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ĐANG DÙNG',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      style.description,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: palette.inkMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Nút xem thử
              PressableScale(
                onTap: onPreview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow_rounded, size: 14, color: AppColors.secondary),
                      SizedBox(width: 2),
                      Text(
                        'Xem thử',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: palette.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
