import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@hotel.com');
  final _passwordController = TextEditingController(text: 'Admin@123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleDashboard(UserRole role) {
    // Màn chính của từng vai trò khai báo ở [RolePermissions.homeRoute].
    context.go(role.homeRoute);
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  void _fillAccount(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  void _showConfigServerDialog() {
    final controller =
        TextEditingController(text: DioClient().dio.options.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấu hình Base URL API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn hoặc nhập URL kết nối Backend NestJS:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://10.0.2.2:3000/api/v1',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Render Cloud'),
                    avatar: const Icon(Icons.cloud_done, size: 16),
                    onPressed: () =>
                        controller.text = AppConstants.productionApiUrl,
                  ),
                  ActionChip(
                    label: const Text('Emulator (10.0.2.2)'),
                    onPressed: () =>
                        controller.text = AppConstants.defaultAndroidEmulatorUrl,
                  ),
                  ActionChip(
                    label: const Text('Localhost:3000'),
                    onPressed: () =>
                        controller.text = AppConstants.defaultLocalhostUrl,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              DioClient().setBaseUrl(controller.text.trim());
              Navigator.pop(ctx);
              AppNotification.showSuccess(
                context,
                'Đã đổi API sang: ${controller.text.trim()}',
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.38;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            AppNotification.showError(context, state.message);
          } else if (state is AuthAuthenticated) {
            AppNotification.showSuccess(
              context,
              'Chào mừng ${state.user.fullName.isNotEmpty ? state.user.fullName : 'bạn'} quay trở lại!',
            );
            _navigateToRoleDashboard(state.user.role);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                // Hero Image + Overlays (38% height)
                SizedBox(
                  height: heroHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Luxury Hotel Lobby Background Image
                      CachedNetworkImage(
                        imageUrl:
                            'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=1200&q=80',
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 300),
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Gradient Scrim: Transparent at top -> Navy 85% at bottom
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.4),
                              AppColors.primary.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),

                      // Top Settings Gear (Frosted Glass Button)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: AppSpacing.screen,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showConfigServerDialog,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlapping Card with AppRadius.sheetR
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: AppRadius.sheetR,
                      boxShadow: palette.isDark ? null : AppShadows.medium,
                      border: palette.isDark ? Border.all(color: palette.border, width: 1) : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.xxl),

                          // 1. Nhóm Logo & Tiêu đề — Hoạt ảnh Scale-in từ 0.8
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppGradients.navy,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: AppShadows.navyGlow,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.secondaryLight,
                                  size: 34,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                duration: const Duration(milliseconds: 350),
                                curve: AppMotion.enter,
                              )
                              .fadeIn(duration: const Duration(milliseconds: 300)),
                          const SizedBox(height: AppSpacing.lg),

                          Column(
                            children: [
                              Text(
                                'Chào mừng trở lại',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Hệ thống Quản lý Khách sạn 5 Sao',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ],
                          )
                              .animate(delay: const Duration(milliseconds: 100))
                              .fadeIn(duration: const Duration(milliseconds: 250), curve: AppMotion.enter)
                              .slideY(begin: 0.08, end: 0, curve: AppMotion.enter),
                          const SizedBox(height: AppSpacing.xxl),

                          // 2. Nhóm Ô nhập liệu — Trượt lên so le
                          Column(
                            children: [
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email đăng nhập',
                                hint: 'admin@hotel.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập email đăng nhập';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Mật khẩu',
                                obscureText: _obscurePassword,
                                prefixIcon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: palette.inkMuted,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Quên mật khẩu?',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: palette.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                              .animate(delay: const Duration(milliseconds: 200))
                              .fadeIn(duration: const Duration(milliseconds: 250), curve: AppMotion.enter)
                              .slideY(begin: 0.08, end: 0, curve: AppMotion.enter),
                          const SizedBox(height: AppSpacing.xl),

                          // 3. Nhóm Nút bấm & Tài khoản mẫu — Trượt lên nhóm 3
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomButton(
                                text: 'Đăng Nhập',
                                isLoading: isLoading,
                                onPressed: _onLoginPressed,
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: palette.divider),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                    child: Text(
                                      'Tài khoản kiểm thử nhanh',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: palette.inkFaint,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: palette.divider),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSeedChip(
                                      label: 'Quản trị',
                                      dotColor: Colors.purple,
                                      email: 'admin@hotel.com',
                                      pass: 'Admin@123',
                                      palette: palette,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _buildSeedChip(
                                      label: 'Lễ tân – Thu ngân',
                                      dotColor: Colors.blue,
                                      email: 'reception@hotel.com',
                                      pass: 'Staff@123',
                                      palette: palette,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _buildSeedChip(
                                label: 'Khách hàng',
                                dotColor: palette.accent,
                                email: 'customer@hotel.com',
                                pass: 'Cust@123',
                                palette: palette,
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Chưa có tài khoản? ',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: palette.inkMuted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.push('/register'),
                                    child: Text(
                                      'Đăng ký ngay',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: palette.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxxl),
                            ],
                          )
                              .animate(delay: const Duration(milliseconds: 300))
                              .fadeIn(duration: const Duration(milliseconds: 250), curve: AppMotion.enter)
                              .slideY(begin: 0.08, end: 0, curve: AppMotion.enter),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeedChip({
    required String label,
    required Color dotColor,
    required String email,
    required String pass,
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: () => _fillAccount(email, pass),
      borderRadius: AppRadius.pillR,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: AppRadius.pillR,
          border: Border.all(color: palette.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
