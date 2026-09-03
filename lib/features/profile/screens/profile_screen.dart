import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _selectedPaymentMethod = 'Ví MoMo';
  String? _customPhone;
  String _selectedLanguage = 'Tiếng Việt';

  void _showChangePasswordModal(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool hideCurrent = true;
    bool hideNew = true;
    bool hideConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.lock_reset_rounded,
                        color: AppColors.secondary, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Đổi Mật Khẩu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentPassController,
                  obscureText: hideCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => hideCurrent = !hideCurrent),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: hideNew,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => hideNew = !hideNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: hideConfirm,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setModalState(() => hideConfirm = !hideConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final current = currentPassController.text;
                      final newP = newPassController.text;
                      final confirmP = confirmPassController.text;

                      if (current.isEmpty || newP.isEmpty || confirmP.isEmpty) {
                        AppNotification.showWarning(
                          context,
                          'Vui lòng nhập đầy đủ thông tin mật khẩu',
                        );
                        return;
                      }
                      if (newP.length < 6) {
                        AppNotification.showWarning(
                          context,
                          'Mật khẩu mới phải có ít nhất 6 ký tự',
                        );
                        return;
                      }
                      if (newP != confirmP) {
                        AppNotification.showWarning(
                          context,
                          'Mật khẩu xác nhận không trùng khớp',
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      AppNotification.showSuccess(
                        context,
                        'Đã đổi mật khẩu thành công!',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Cập nhật mật khẩu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPhoneModal(BuildContext context, String currentPhone) {
    final phoneController = TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.phone_android_rounded,
                    color: Color(0xFF3B82F6), size: 24),
                SizedBox(width: 10),
                Text(
                  'Cập Nhật Số Điện Thoại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại liên hệ',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final phone = phoneController.text.trim();
                  if (phone.isEmpty || phone.length < 9) {
                    AppNotification.showWarning(
                      context,
                      'Vui lòng nhập số điện thoại hợp lệ',
                    );
                    return;
                  }
                  setState(() {
                    _customPhone = phone;
                  });
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(
                    context,
                    'Đã cập nhật số điện thoại: $phone',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Lưu thay đổi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Phương Thức Thanh Toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn phương thức ưu tiên khi thanh toán đặt phòng',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFFA50064),
                title: 'Ví MoMo',
                subtitle: 'Thanh toán trực tiếp qua MoMo QR',
                isSelected: _selectedPaymentMethod == 'Ví MoMo',
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'Ví MoMo';
                  });
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(
                      context, 'Đã chọn phương thức thanh toán: Ví MoMo');
                },
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF005BAA),
                title: 'VNPAY-QR / Chuyển khoản',
                subtitle: 'Quét mã ngân hàng VietQR',
                isSelected: _selectedPaymentMethod == 'VNPAY-QR / Chuyển khoản',
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'VNPAY-QR / Chuyển khoản';
                  });
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(
                      context, 'Đã chọn phương thức thanh toán: VNPAY-QR');
                },
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                icon: Icons.payments_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'Thanh toán tại khách sạn',
                subtitle: 'Thanh toán khi làm thủ tục Check-in',
                isSelected: _selectedPaymentMethod == 'Thanh toán tại khách sạn',
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'Thanh toán tại khách sạn';
                  });
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(
                      context, 'Đã chọn thanh toán trực tiếp tại sảnh');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn Ngôn Ngữ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                title: 'Tiếng Việt',
                subtitle: 'Giao diện hiển thị Tiếng Việt',
                isSelected: _selectedLanguage == 'Tiếng Việt',
                onTap: () {
                  setState(() => _selectedLanguage = 'Tiếng Việt');
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(context, 'Đã chuyển sang Tiếng Việt');
                },
              ),
              const SizedBox(height: 10),
              _buildLanguageOption(
                title: 'English',
                subtitle: 'English Interface',
                isSelected: _selectedLanguage == 'English',
                onTap: () {
                  setState(() => _selectedLanguage = 'English');
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(context, 'Switched to English');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAvatarOptionsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showSuccess(
                    context, 'Mở máy ảnh chụp ảnh đại diện');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.secondary),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                AppNotification.showSuccess(
                    context, 'Mở thư viện ảnh');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final fullName = user?.fullName ?? 'Nguyễn Văn A';
          final email = user?.email ?? 'customer@hotel.com';
          final roleLabel = user?.role.label ?? 'Khách hàng';
          final phone = _customPhone ?? user?.phone ?? '0912345678';
          final initialChar =
              fullName.isNotEmpty ? fullName[0].toUpperCase() : 'N';

          final topPadding = MediaQuery.of(context).padding.top;
          final canPop = context.canPop();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dải Navy đầu màn bo cong mềm ở đáy (chiều cao 335 + topPadding giúp thẻ role badge thoáng đẹp, không bị đè)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: _ConvexCurveClipper(),
                      child: Container(
                        width: double.infinity,
                        height: 335 + topPadding,
                        decoration: const BoxDecoration(
                          gradient: AppGradients.navy,
                        ),
                        child: Stack(
                          children: [
                            // Hoa văn gold mờ
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.04,
                                child: CustomPaint(
                                  painter: _ProfilePatternPainter(),
                                ),
                              ),
                            ),

                            SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 4),
                                child: Column(
                                  children: [
                                    // Top Bar
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (canPop)
                                          IconButton(
                                            icon: const Icon(Icons.arrow_back,
                                                color: Colors.white),
                                            onPressed: () => context.pop(),
                                          )
                                        else
                                          const SizedBox(width: 48),
                                        const Text(
                                          'Hồ Sơ Cá Nhân',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.settings,
                                              color: Colors.white),
                                          onPressed: () {
                                            AppNotification.showSuccess(
                                              context,
                                              'Cài đặt tài khoản Luxe Grand',
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Avatar tròn 88px viền gold 3px
                                    GestureDetector(
                                      onTap: () =>
                                          _showAvatarOptionsModal(context),
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.secondary,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.secondaryLight
                                                      .withValues(alpha: 0.25),
                                                  blurRadius: 20,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                initialChar,
                                                style: const TextStyle(
                                                  color: AppColors.secondaryLight,
                                                  fontSize: 38,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Camera Icon
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Full Name
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 21,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),

                                    // Email
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.65),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Role Pill Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary
                                            .withValues(alpha: 0.22),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: AppColors.secondaryLight
                                              .withValues(alpha: 0.85),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.secondaryLight,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            roleLabel,
                                            style: const TextStyle(
                                              color: AppColors.secondaryLight,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
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

                    // 2. Thẻ Thống Kê (đè lên đáy dải cong 32px, cao 84px)
                    Positioned(
                      bottom: -32,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCol('12', 'Lượt đặt'),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _buildStatCol('3', 'Đang hoạt động'),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _buildStatCol(
                                '4.9',
                                'Đánh giá',
                                hasStar: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 52),

                // 3. Section Label: TÀI KHOẢN
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'TÀI KHOẢN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Menu Card 1 (Tài khoản)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Số điện thoại',
                          subtitle: phone,
                          onTap: () => _showEditPhoneModal(context, phone),
                        ),
                        const Divider(
                            height: 1, indent: 68, color: AppColors.divider),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.secondary,
                          title: 'Đổi mật khẩu',
                          onTap: () => _showChangePasswordModal(context),
                        ),
                        const Divider(
                            height: 1, indent: 68, color: AppColors.divider),
                        _buildMenuItem(
                          icon: Icons.credit_card_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          title: 'Phương thức thanh toán',
                          subtitle: _selectedPaymentMethod,
                          onTap: () => _showPaymentMethodsModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Section Label: ỨNG DỤNG
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'ỨNG DỤNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 6. Menu Card 2 (Ứng dụng)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'Thông báo',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.secondary,
                            onChanged: (val) {
                              setState(() => _notificationsEnabled = val);
                              AppNotification.showSuccess(
                                context,
                                val
                                    ? 'Đã bật thông báo ứng dụng'
                                    : 'Đã tắt thông báo ứng dụng',
                              );
                            },
                          ),
                        ),
                        const Divider(
                            height: 1, indent: 68, color: AppColors.divider),
                        _buildMenuItem(
                          icon: Icons.language_rounded,
                          iconColor: AppColors.textSecondary,
                          title: 'Ngôn ngữ',
                          subtitle: _selectedLanguage,
                          onTap: () => _showLanguageModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 7. Nút Đăng Xuất (viền đỏ #EF4444 1.5px)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                            color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Đăng Xuất',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 8. Footer
                const Center(
                  child: Text(
                    'Luxe Grand Hotel • Phiên bản 1.0.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCol(String value, String label, {bool hasStar = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasStar) ...[
              const Icon(
                Icons.star_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
          ],
        ),
      ),
    );
  }
}

/// Đường cong lồi mềm ở đáy dải navy
class _ConvexCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ProfilePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double step = 60;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
