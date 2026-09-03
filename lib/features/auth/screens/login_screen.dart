import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/dio_client.dart';
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
    switch (role) {
      case UserRole.admin:
        context.go('/admin');
        break;
      case UserRole.receptionist:
        context.go('/receptionist');
        break;
      case UserRole.cashier:
        context.go('/cashier');
        break;
      case UserRole.customer:
        context.go('/customer');
        break;
    }
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
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.38;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        right: 20,
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

                // Overlapping White Card
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 28),

                          // Navy rounded icon with gold hotel symbol
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: AppGradients.navy,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.apartment_rounded,
                                  color: AppColors.secondaryLight,
                                  size: 34,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Welcome back title
                          const Text(
                            'Chào mừng trở lại',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          const Text(
                            'Hệ thống Quản lý Khách sạn 5 Sao',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Email Field
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
                          const SizedBox(height: 16),

                          // Password Field
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
                                color: AppColors.textSecondary,
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
                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                AppNotification.showWarning(
                                  context,
                                  'Vui lòng liên hệ quản trị viên để cấp lại mật khẩu',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Primary Gold Gradient Button
                          CustomButton(
                            text: 'Đăng Nhập',
                            isLoading: isLoading,
                            onPressed: _onLoginPressed,
                          ),
                          const SizedBox(height: 28),

                          // Quick Accounts Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.border),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Tài khoản kiểm thử nhanh',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.border),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 4 Seed Chips in 2 rows
                          Row(
                            children: [
                              Expanded(
                                child: _buildSeedChip(
                                  label: 'Quản trị',
                                  dotColor: Colors.purple,
                                  email: 'admin@hotel.com',
                                  pass: 'Admin@123',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSeedChip(
                                  label: 'Lễ tân',
                                  dotColor: Colors.blue,
                                  email: 'reception@hotel.com',
                                  pass: 'Staff@123',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSeedChip(
                                  label: 'Thu ngân',
                                  dotColor: Colors.green,
                                  email: 'cashier@hotel.com',
                                  pass: 'Staff@123',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildSeedChip(
                                  label: 'Khách hàng',
                                  dotColor: AppColors.secondary,
                                  email: 'customer@hotel.com',
                                  pass: 'Cust@123',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Register Link
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push('/register'),
                                child: const Text(
                                  'Đăng ký ngay',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
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
  }) {
    return InkWell(
      onTap: () => _fillAccount(email, pass),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
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
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
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
