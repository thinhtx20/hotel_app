import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../di/injection_container.dart';
import '../../../shared/repositories/upload_repository.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/logout_confirmation_dialog.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';
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

  void _quickSwitchRole(BuildContext context, String email, String password, String roleName) {
    AppNotification.showSuccess(
      context,
      'Đang chuyển sang vai trò: $roleName...',
    );
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: email,
        password: password,
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final palette = context.palette;
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool hideCurrent = true;
    bool hideNew = true;
    bool hideConfirm = true;
    bool isChanging = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppBottomSheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, color: palette.accent, size: 24),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Đổi Mật Khẩu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: currentPassController,
                  obscureText: hideCurrent,
                  style: TextStyle(color: palette.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                    labelStyle: TextStyle(color: palette.inkMuted),
                    prefixIcon: Icon(Icons.lock_outline, size: 20, color: palette.inkMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: palette.inkMuted,
                      ),
                      onPressed: () => setModalState(() => hideCurrent = !hideCurrent),
                    ),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: newPassController,
                  obscureText: hideNew,
                  style: TextStyle(color: palette.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                    labelStyle: TextStyle(color: palette.inkMuted),
                    prefixIcon: Icon(Icons.lock_reset, size: 20, color: palette.inkMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: palette.inkMuted,
                      ),
                      onPressed: () => setModalState(() => hideNew = !hideNew),
                    ),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: confirmPassController,
                  obscureText: hideConfirm,
                  style: TextStyle(color: palette.ink, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu mới',
                    labelStyle: TextStyle(color: palette.inkMuted),
                    prefixIcon: Icon(Icons.check_circle_outline, size: 20, color: palette.inkMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: palette.inkMuted,
                      ),
                      onPressed: () => setModalState(() => hideConfirm = !hideConfirm),
                    ),
                    filled: true,
                    fillColor: palette.surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: PressableScale(
                    onTap: isChanging
                        ? null
                        : () async {
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

                            setModalState(() => isChanging = true);
                            try {
                              final res = await DioClient().dio.post(
                                ApiEndpoints.changePassword,
                                data: {
                                  'oldPassword': current,
                                  'newPassword': newP,
                                },
                              );
                              if (mounted &&
                                  ctx.mounted &&
                                  (res.statusCode == 200 || res.statusCode == 201) &&
                                  res.data['success'] == true) {
                                Navigator.pop(ctx);
                                if (context.mounted) {
                                  AppNotification.showSuccess(
                                    context,
                                    'Đổi mật khẩu thành công!',
                                  );
                                }
                                return;
                              }
                            } on DioException catch (e) {
                              final err = ApiError.fromDioException(e);
                              if (context.mounted) {
                                AppNotification.showError(context, err.displayMessage);
                              }
                            } catch (_) {
                              if (context.mounted) {
                                AppNotification.showError(
                                  context,
                                  'Không thể đổi mật khẩu. Vui lòng kiểm tra lại.',
                                );
                              }
                            } finally {
                              if (mounted) {
                                setModalState(() => isChanging = false);
                              }
                            }
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                        boxShadow: AppShadows.goldGlow,
                      ),
                      alignment: Alignment.center,
                      child: isChanging
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cập nhật mật khẩu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditPhoneModal(BuildContext context, String currentPhone) {
    final palette = context.palette;
    final phoneController = TextEditingController(text: currentPhone);
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_android_rounded, color: palette.accent, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Cập Nhật Số Điện Thoại',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: palette.ink, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Số điện thoại liên hệ',
                  labelStyle: TextStyle(color: palette.inkMuted),
                  prefixIcon: Icon(Icons.phone_outlined, size: 20, color: palette.inkMuted),
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: PressableScale(
                  onTap: isSaving
                      ? null
                      : () async {
                          final phone = phoneController.text.trim();
                          if (phone.isEmpty || phone.length < 9) {
                            AppNotification.showWarning(
                              context,
                              'Vui lòng nhập số điện thoại hợp lệ',
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            final updatedUser =
                                await sl<UserRepository>().updateMe({'phone': phone});
                            await TokenStorage().saveUser(updatedUser);

                            if (mounted) {
                              setState(() {
                                _customPhone = phone;
                              });
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                              if (context.mounted) {
                                AppNotification.showSuccess(
                                  context,
                                  'Đã cập nhật số điện thoại: $phone',
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              AppNotification.showError(
                                context,
                                e,
                                title: 'Cập nhật thất bại',
                              );
                            }
                          } finally {
                            if (mounted) {
                              setModalState(() => isSaving = false);
                            }
                          }
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: AppShadows.goldGlow,
                    ),
                    alignment: Alignment.center,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu thay đổi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodsModal(BuildContext context) {
    final palette = context.palette;
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phương Thức Thanh Toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn phương thức ưu tiên khi thanh toán đặt phòng',
                style: TextStyle(fontSize: 13, color: palette.inkMuted),
              ),
              const SizedBox(height: AppSpacing.md),
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
                  AppNotification.showSuccess(context, 'Đã chọn phương thức thanh toán: Ví MoMo');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
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
                  AppNotification.showSuccess(context, 'Đã chọn phương thức thanh toán: VNPAY-QR');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPaymentOption(
                icon: Icons.payments_outlined,
                iconColor: palette.statusAvailable,
                title: 'Thanh toán tại khách sạn',
                subtitle: 'Thanh toán khi làm thủ tục Check-in',
                isSelected: _selectedPaymentMethod == 'Thanh toán tại khách sạn',
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = 'Thanh toán tại khách sạn';
                  });
                  setModalState(() {});
                  Navigator.pop(ctx);
                  AppNotification.showSuccess(context, 'Đã chọn thanh toán trực tiếp tại sảnh');
                },
              ),
              const SizedBox(height: AppSpacing.sm),
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
    final palette = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent.withValues(alpha: 0.12) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.image),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: palette.accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    final palette = context.palette;
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AppBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn Ngôn Ngữ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.sm),
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
    final palette = context.palette;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? palette.accent.withValues(alpha: 0.12) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.image),
          border: Border.all(
            color: isSelected ? palette.accent : palette.border,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: palette.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final uploadRepo = sl<UploadRepository>();
      final updatedUser =
          await uploadRepo.uploadAvatar(pickedFile.path, updateProfile: true);
      await TokenStorage().saveUser(updatedUser);

      if (mounted) {
        setState(() {});
        AppNotification.showSuccess(
          context,
          'Cập nhật ảnh đại diện thành công!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          e,
          title: 'Tải ảnh đại diện thất bại',
        );
      }
    }
  }

  void _showAvatarOptionsModal(BuildContext context) {
    final palette = context.palette;
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => AppBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: palette.accent),
              title: Text('Chụp ảnh mới',
                  style: TextStyle(
                      color: palette.ink, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library_outlined, color: palette.accent),
              title: Text('Chọn từ thư viện',
                  style: TextStyle(
                      color: palette.ink, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          // Guard trong AppRouter đã lo điều hướng khi đổi tài khoản; ở đây chỉ
          // xử lý khi màn hình còn gắn trên cây (đổi tài khoản làm màn hình bị
          // dựng lại — xem [SessionScope]).
          if (!context.mounted) return;
          if (state is AuthUnauthenticated) {
            context.go('/login');
          } else if (state is AuthFailure) {
            AppNotification.showError(
              context,
              state.message,
              title: 'Đổi tài khoản không thành công',
            );
          } else if (state is AuthAuthenticated) {
            context.go(state.user.role.homeRoute);
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
                // 1. Dải Navy đầu màn bo cong mềm ở đáy
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

                                    // Avatar tròn 88px Hero
                                    GestureDetector(
                                      onTap: () =>
                                          _showAvatarOptionsModal(context),
                                      child: Hero(
                                        tag: 'profile-avatar',
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
                                              child: ClipOval(
                                                child: user?.avatar != null &&
                                                        user!.avatar!.isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl: user.avatar!,
                                                        fit: BoxFit.cover,
                                                        placeholder: (_, _) =>
                                                            const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors
                                                                .secondaryLight,
                                                          ),
                                                        ),
                                                        errorWidget:
                                                            (_, _, _) => Center(
                                                          child: Text(
                                                            initialChar,
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .secondaryLight,
                                                              fontSize: 38,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Center(
                                                        child: Text(
                                                          initialChar,
                                                          style:
                                                              const TextStyle(
                                                            color: AppColors
                                                                .secondaryLight,
                                                            fontSize: 38,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
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

                    // 2. Thẻ Thống Kê (AppCard đè lên đáy dải cong 32px, cao 84px)
                    Positioned(
                      bottom: -32,
                      left: AppSpacing.screen,
                      right: AppSpacing.screen,
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        borderRadius: AppRadius.card,
                        child: SizedBox(
                          height: 84,
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCol(
                                  user?.role == UserRole.admin
                                      ? '100%'
                                      : user?.role == UserRole.receptionist
                                          ? 'Ca trực'
                                          : user?.role == UserRole.cashier
                                              ? 'Quầy thu'
                                              : '12',
                                  user?.role == UserRole.admin
                                      ? 'Toàn quyền'
                                      : user?.role == UserRole.receptionist
                                          ? 'Đang mở'
                                          : user?.role == UserRole.cashier
                                              ? 'Sẵn sàng'
                                              : 'Lượt đặt',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: palette.divider,
                              ),
                              Expanded(
                                child: _buildStatCol(
                                  user?.role == UserRole.admin
                                      ? '24'
                                      : user?.role == UserRole.receptionist
                                          ? 'Sơ đồ'
                                          : user?.role == UserRole.cashier
                                              ? 'Hóa đơn'
                                              : '3',
                                  user?.role == UserRole.admin
                                      ? 'Phòng KS'
                                      : user?.role == UserRole.receptionist
                                          ? 'Buồng phòng'
                                          : user?.role == UserRole.cashier
                                              ? 'Báo cáo ngày'
                                              : 'Đang hoạt động',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: palette.divider,
                              ),
                              Expanded(
                                child: _buildStatCol(
                                  user?.role == UserRole.admin
                                      ? '4.95'
                                      : user?.role == UserRole.receptionist
                                          ? '5.0'
                                          : user?.role == UserRole.cashier
                                              ? '100%'
                                              : '4.9',
                                  user?.role == UserRole.admin
                                      ? 'Đánh giá KS'
                                      : user?.role == UserRole.receptionist
                                          ? 'Tiêu chuẩn'
                                          : user?.role == UserRole.cashier
                                              ? 'Chính xác'
                                              : 'Đánh giá',
                                  hasStar: user?.role != UserRole.cashier,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 52),

                // 3. Section Label: TÀI KHOẢN
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Text(
                    'TÀI KHOẢN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.inkFaint,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Menu Card 1 (Tài khoản) gom bằng AppCard
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Số điện thoại',
                          subtitle: phone,
                          onTap: () => _showEditPhoneModal(context, phone),
                        ),
                        Divider(height: 1, indent: 68, color: palette.divider),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          iconColor: palette.accent,
                          title: 'Đổi mật khẩu',
                          onTap: () => _showChangePasswordModal(context),
                        ),
                        Divider(height: 1, indent: 68, color: palette.divider),
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
                const SizedBox(height: AppSpacing.xl),

                // 5. Section Label: ỨNG DỤNG
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Text(
                    'ỨNG DỤNG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.inkFaint,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 6. Menu Card 2 (Ứng dụng) gom bằng AppCard kèm Dark Mode Switch
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Công tắc Dark Mode mượt mà kết nối ThemeCubit
                        _buildMenuItem(
                          icon: palette.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          iconColor: palette.accent,
                          title: 'Giao diện tối (Dark Mode)',
                          subtitle: palette.isDark ? 'Đang bật nền tối' : 'Đang bật nền sáng',
                          trailing: Switch(
                            value: palette.isDark,
                            activeThumbColor: Colors.white,
                            activeTrackColor: palette.accent,
                            onChanged: (_) {
                              context.read<ThemeCubit>().toggleDarkMode(context);
                            },
                          ),
                        ),
                        Divider(height: 1, indent: 68, color: palette.divider),
                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          iconColor: palette.statusAvailable,
                          title: 'Thông báo',
                          trailing: Switch(
                            value: _notificationsEnabled,
                            activeThumbColor: Colors.white,
                            activeTrackColor: palette.accent,
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
                        Divider(height: 1, indent: 68, color: palette.divider),
                        _buildMenuItem(
                          icon: Icons.language_rounded,
                          iconColor: palette.inkMuted,
                          title: 'Ngôn ngữ',
                          subtitle: _selectedLanguage,
                          onTap: () => _showLanguageModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
                // Section: CHUYỂN VAI TRÒ KIỂM THỬ (DEMO ROLE SWITCHER)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: Text(
                    'CHUYỂN VAI TRÒ KIỂM THỬ (DEMO SWITCHER)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: palette.inkFaint,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.switch_account_rounded, size: 20, color: palette.accent),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Đổi vai trò 1-chạm để trải nghiệm giao diện khác biệt:',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.ink),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleSwitchButton(
                                label: 'Quản trị viên',
                                role: UserRole.admin,
                                color: Colors.purple,
                                isCurrent: user?.role == UserRole.admin,
                                onTap: () => _quickSwitchRole(context, 'admin@hotel.com', 'Admin@123', 'Quản trị viên'),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _buildRoleSwitchButton(
                                label: 'Lễ tân sảnh',
                                role: UserRole.receptionist,
                                color: Colors.blue,
                                isCurrent: user?.role == UserRole.receptionist,
                                onTap: () => _quickSwitchRole(context, 'reception@hotel.com', 'Staff@123', 'Lễ tân'),
                                palette: palette,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleSwitchButton(
                                label: 'Thu ngân',
                                role: UserRole.cashier,
                                color: Colors.green,
                                isCurrent: user?.role == UserRole.cashier,
                                onTap: () => _quickSwitchRole(context, 'cashier@hotel.com', 'Staff@123', 'Thu ngân'),
                                palette: palette,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _buildRoleSwitchButton(
                                label: 'Khách hàng',
                                role: UserRole.customer,
                                color: palette.accent,
                                isCurrent: user?.role == UserRole.customer,
                                onTap: () => _quickSwitchRole(context, 'customer@hotel.com', 'Cust@123', 'Khách hàng'),
                                palette: palette,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 7. Nút Đăng Xuất (viền đỏ với PressableScale)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                  child: PressableScale(
                    onTap: () => LogoutConfirmationDialog.show(context),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => LogoutConfirmationDialog.show(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.error,
                          side: BorderSide(color: palette.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
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
                ),
                const SizedBox(height: AppSpacing.lg),

                // 8. Footer
                Center(
                  child: Text(
                    'Luxe Grand Hotel • Phiên bản 1.0.0',
                    style: TextStyle(
                      color: palette.inkFaint,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: AppDurations.normal)
          .slideY(begin: 0.04, curve: AppMotion.enter);
        },
      ),
    );
  }

  Widget _buildStatCol(String value, String label, {bool hasStar = false}) {
    final palette = context.palette;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasStar) ...[
              Icon(
                Icons.star_rounded,
                color: palette.accent,
                size: 18,
              ),
              const SizedBox(width: 2),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
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
          style: TextStyle(
            fontSize: 11,
            color: palette.inkMuted,
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
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.inkMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: palette.inkFaint,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSwitchButton({
    required String label,
    required UserRole role,
    required Color color,
    required bool isCurrent,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: isCurrent ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.15) : palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: isCurrent ? color : palette.border,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrent ? color : palette.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrent) ...[
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: color),
            ],
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
