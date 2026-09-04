import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreeTerms = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToRoleDashboard(UserRole role) {
    // `POST /auth/register` luôn ép CUSTOMER ở server, nhưng vẫn điều hướng
    // theo role thật trả về thay vì cố định '/customer'.
    context.go(role.homeRoute);
  }

  void _onRegisterPressed() {
    if (!_agreeTerms) {
      AppNotification.showWarning(
        context,
        'Vui lòng đồng ý với Điều khoản dịch vụ',
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthRegisterSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim().isNotEmpty
                  ? _phoneController.text.trim()
                  : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.18;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            AppNotification.showError(context, state.message);
          } else if (state is AuthAuthenticated) {
            AppNotification.showSuccess(
              context,
              'Đăng ký thành công! Chào mừng ${state.user.fullName.isNotEmpty ? state.user.fullName : 'bạn'}',
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
                // Top Hero Strip with Navy Gradient
                Container(
                  height: heroHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.navy,
                  ),
                  child: Stack(
                    children: [
                      // Faint gold pattern
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.04,
                          child: CustomPaint(
                            painter: _RegisterPatternPainter(),
                          ),
                        ),
                      ),

                      // Back Button + Header Title
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white, size: 20),
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                ),
                              ),
                              Text(
                                'Đăng Ký Tài Khoản',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlapping Card with AppRadius.sheetR
                Transform.translate(
                  offset: const Offset(0, -24),
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

                          // Header Text with animation
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tạo tài khoản khách hàng',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: palette.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Trải nghiệm dịch vụ nghỉ dưỡng cao cấp tại Luxe Grand',
                                style: textTheme.bodySmall?.copyWith(
                                  color: palette.inkMuted,
                                ),
                              ),
                            ],
                          )
                              .animate()
                              .fadeIn(duration: const Duration(milliseconds: 250), curve: AppMotion.enter)
                              .slideY(begin: 0.08, end: 0, curve: AppMotion.enter),
                          const SizedBox(height: AppSpacing.xxl),

                          // Form inputs with staggered entrance
                          Column(
                            children: [
                              // 1. Full Name
                              CustomTextField(
                                controller: _nameController,
                                label: 'Họ và tên',
                                hint: 'Nguyễn Văn A',
                                prefixIcon: Icons.person_outline,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập họ và tên';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // 2. Email
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'khachhang@gmail.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập email';
                                  }
                                  if (!val.contains('@')) {
                                    return 'Email không hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // 3. Phone
                              CustomTextField(
                                controller: _phoneController,
                                label: 'Số điện thoại',
                                hint: '0912345678',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // 4. Password
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
                                  if (val == null || val.length < 6) {
                                    return 'Mật khẩu tối thiểu 6 ký tự';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Password Strength Indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: palette.warning,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: palette.warning,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: palette.border,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      'Trung bình',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: palette.warningInk,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Terms and Conditions Checkbox
                              GestureDetector(
                                onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _agreeTerms
                                            ? palette.accent
                                            : palette.surface,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _agreeTerms
                                              ? palette.accent
                                              : palette.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _agreeTerms
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: textTheme.bodySmall?.copyWith(
                                            color: palette.inkMuted,
                                          ),
                                          children: [
                                            const TextSpan(text: 'Tôi đồng ý với '),
                                            TextSpan(
                                              text: 'Điều khoản dịch vụ',
                                              style: TextStyle(
                                                color: palette.accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                              .animate(delay: const Duration(milliseconds: 150))
                              .fadeIn(duration: const Duration(milliseconds: 250), curve: AppMotion.enter)
                              .slideY(begin: 0.08, end: 0, curve: AppMotion.enter),
                          const SizedBox(height: AppSpacing.xxl),

                          // Submit Button & Navigation
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CustomButton(
                                text: 'Tạo Tài Khoản',
                                isLoading: isLoading,
                                onPressed: _onRegisterPressed,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Đã có tài khoản? ',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: palette.inkMuted,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/login');
                                      }
                                    },
                                    child: Text(
                                      'Đăng nhập ngay',
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
                              .animate(delay: const Duration(milliseconds: 250))
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
}

class _RegisterPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondaryLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double step = 50;
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
