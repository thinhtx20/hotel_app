import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
import '../models/app_notification_model.dart';
import '../repositories/notification_repository.dart';

/// Màn hình Trung tâm thông báo (Notification Center) chuẩn Modern Luxury.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationRepository _repo;
  AppNotificationCategory? _selectedCategory;

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

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  void _showNotificationDetailSheet(BuildContext context, AppNotificationModel item) {
    final palette = context.palette;
    final catColor = item.category.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: palette.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(item.category.icon, color: catColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatRelativeTime(item.createdAt),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: palette.inkMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: palette.divider),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: palette.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.body,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: palette.ink.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.ink,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                if (item.actionRoute != null && item.actionRoute!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final target = PushNotificationService.resolveTargetRoute({
                          'route': item.actionRoute,
                        });
                        context.go(target);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        item.actionLabel ?? 'Xem chi tiết',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: catColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTestStylesBottomSheet(BuildContext context) {
    final palette = context.palette;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: palette.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trải nghiệm 5 kiểu thông báo',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        'Chạm vào kiểu bất kỳ để kích hoạt hiển thị tức thì',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5,
                          color: palette.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: palette.divider),
            const SizedBox(height: 10),

            _buildStyleTestTile(
              context: ctx,
              title: '1. Modern Luxury Banner',
              subtitle: 'Midnight Navy + Viền vàng 24K + Vạch đếm ngược thời gian',
              icon: Icons.view_headline_rounded,
              color: const Color(0xFFD97706),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showLuxuryBanner(
                  context: context,
                  title: 'Nhắc nhở hạn trả phòng',
                  body: 'Phòng Deluxe 302 của Quý khách sẽ đến hạn trả phòng lúc 12:00 hôm nay.',
                  category: 'Nhắc nhở trả phòng',
                  icon: Icons.hourglass_top_rounded,
                  notificationCategory: AppNotificationCategory.booking,
                  onTap: () => context.go('/my-bookings'),
                );
              },
            ),

            _buildStyleTestTile(
              context: ctx,
              title: '2. Dynamic Island Capsule',
              subtitle: 'Viên thuốc đen bóng bo tròn iOS, hỗ trợ chạm mở rộng',
              icon: Icons.lens_blur_rounded,
              color: const Color(0xFF059669),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showDynamicIsland(
                  context: context,
                  title: 'Hóa đơn dịch vụ mới',
                  body: 'Dịch vụ Room Service #INV-8821 trị giá 350.000đ đã được lập.',
                  category: 'Thanh toán & Hóa đơn',
                  icon: Icons.receipt_long_rounded,
                  notificationCategory: AppNotificationCategory.payment,
                  onTap: () => context.go('/my-bookings'),
                );
              },
            ),

            _buildStyleTestTile(
              context: ctx,
              title: '3. Frosted Glass Card',
              subtitle: 'Kính mờ pha lê xuyên thấu Glassmorphism với viền phát sáng',
              icon: Icons.auto_awesome_mosaic_rounded,
              color: const Color(0xFF6366F1),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showGlassCard(
                  context: context,
                  title: 'Dịch vụ buồng phòng hoàn tất',
                  body: 'Đội ngũ dọn phòng đã bổ sung khăn tắm cao cấp và hoa tươi.',
                  category: 'Dịch vụ phòng',
                  icon: Icons.room_service_rounded,
                  notificationCategory: AppNotificationCategory.service,
                  onTap: () => context.go('/services'),
                );
              },
            ),

            _buildStyleTestTile(
              context: ctx,
              title: '4. Floating Bottom Toast',
              subtitle: 'Thanh thông báo nổi thanh lịch phía trên Bottom Navigation',
              icon: Icons.call_to_action_rounded,
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showBottomToast(
                  context: context,
                  title: 'Voucher ẩm thực VIP 20%',
                  body: 'Ưu đãi Buffet tối Hoàng Gia tại Rooftop Paradise.',
                  category: 'Ưu đãi & Đặc quyền',
                  icon: Icons.card_giftcard_rounded,
                  notificationCategory: AppNotificationCategory.promotion,
                  onTap: () => context.go('/services'),
                );
              },
            ),

            _buildStyleTestTile(
              context: ctx,
              title: '5. Luxury Modal Dialog',
              subtitle: 'Hộp thoại Pop-up trung tâm làm mờ toàn màn hình',
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showDialogAlert(
                  context: context,
                  title: 'Đặc quyền nâng cấp phòng VIP',
                  body: 'Chào mừng Quý khách đến với kỳ nghỉ! Khách sạn xin gửi tặng Quý khách đặc quyền nâng cấp phòng Executive Suite miễn phí.',
                  category: 'Đặc quyền thành viên',
                  icon: Icons.stars_rounded,
                  notificationCategory: AppNotificationCategory.system,
                  onTap: () => context.go('/my-bookings'),
                );
              },
            ),

            const SizedBox(height: 8),
            _buildStyleTestTile(
              context: ctx,
              title: '⚡ Bắn thông báo trực tiếp từ Server Backend',
              subtitle: 'Gửi yêu cầu lên API Backend để kích hoạt Push FCM & lưu Database',
              icon: Icons.cloud_upload_rounded,
              color: const Color(0xFF10B981),
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await _repo.sendBackendTestNotification();
                if (!context.mounted) return;
                if (ok) {
                  AppNotification.showSuccess(context, 'Server BE đã phát thông báo thành công!');
                } else {
                  AppNotification.showWarning(context, 'Đã lưu thông báo In-App trên máy.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleTestTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
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
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5,
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Thử',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final allNotifications = _repo.notifications;
    final unreadCount = _repo.unreadCount;

    final filteredList = _selectedCategory == null
        ? allNotifications
        : allNotifications.where((n) => n.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: palette.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            Text(
              'Thông báo',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount mới',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Thử nghiệm 5 kiểu thông báo',
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary),
            onPressed: () => _showTestStylesBottomSheet(context),
          ),
          IconButton(
            tooltip: 'Cài đặt thông báo',
            icon: Icon(Icons.tune_rounded, color: palette.ink),
            onPressed: () => context.push('/notification-settings'),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: palette.ink),
            color: palette.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'mark_all') {
                _repo.markAllAsRead();
                AppNotification.showSuccess(context, 'Đã đánh dấu tất cả là đã đọc');
              } else if (val == 'clear_all') {
                _repo.clearAll();
                AppNotification.showSuccess(context, 'Đã xóa toàn bộ lịch sử thông báo');
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'mark_all',
                child: Row(
                  children: const [
                    Icon(Icons.done_all_rounded, size: 18, color: AppColors.availableInk),
                    SizedBox(width: 10),
                    Text('Đánh dấu tất cả đã đọc'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: const [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.errorInk),
                    SizedBox(width: 10),
                    Text('Xóa toàn bộ thông báo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Thanh thông tin kiểu đang kích hoạt (Banner nhỏ hướng dẫn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(bottom: BorderSide(color: palette.divider, width: 0.8)),
            ),
            child: Row(
              children: [
                Icon(_repo.preferredStyle.icon, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: palette.inkMuted,
                      ),
                      children: [
                        const TextSpan(text: 'Kiểu hiển thị: '),
                        TextSpan(
                          text: _repo.preferredStyle.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/notification-settings'),
                  child: const Text(
                    'Đổi kiểu',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Bộ lọc danh mục thông báo (Filter Chips)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildFilterChip(
                  label: 'Tất cả (${allNotifications.length})',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...AppNotificationCategory.values.map((cat) {
                  final count = allNotifications.where((n) => n.category == cat).length;
                  return _buildFilterChip(
                    label: '${cat.label} ($count)',
                    icon: cat.icon,
                    accentColor: cat.color,
                    isSelected: _selectedCategory == cat,
                    onTap: () => setState(() => _selectedCategory = cat),
                  );
                }),
              ],
            ),
          ),

          // 3. Danh sách thông báo
          Expanded(
            child: RefreshIndicator(
              color: palette.accent,
              backgroundColor: palette.surface,
              onRefresh: () => _repo.fetchFromBackend(),
              child: filteredList.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: AppEmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'Không có thông báo nào',
                          description: _selectedCategory == null
                              ? 'Quý khách chưa có thông báo nào vào lúc này.'
                              : 'Không tìm thấy thông báo thuộc danh mục ${_selectedCategory!.label}.',
                          actionText: 'Tạo thông báo mẫu để thử',
                          onAction: () {
                            _repo.init();
                            _showTestStylesBottomSheet(context);
                          },
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filteredList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return _buildNotificationCard(context, item);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    Color? accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (accentColor ?? AppColors.secondary)
                : palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : palette.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : (accentColor ?? palette.inkMuted),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotificationModel item) {
    final palette = context.palette;
    final category = item.category;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        _repo.deleteNotification(item.id);
        AppNotification.showSuccess(context, 'Đã xóa thông báo');
      },
      child: PressableScale(
        onTap: () {
          _repo.markAsRead(item.id);
          _showNotificationDetailSheet(context, item);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? palette.surface
                : (palette.isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? palette.border
                  : category.color.withValues(alpha: 0.4),
              width: item.isRead ? 1 : 1.3,
            ),
            boxShadow: item.isRead
                ? null
                : [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon danh mục
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.icon, color: category.color, size: 20),
              ),
              const SizedBox(width: 12),

              // Nội dung chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.label,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: category.color,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatRelativeTime(item.createdAt),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: palette.inkMuted,
                          ),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: category.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5,
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5,
                        color: palette.inkMuted,
                        height: 1.4,
                      ),
                    ),
                    if (item.actionLabel != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: category.color.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.actionLabel!,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: category.color,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: category.color,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
