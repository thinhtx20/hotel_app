import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/role_enum.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.20;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                // Top Hero Strip (20% height) with Navy Gradient
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
                              horizontal: 16, vertical: 8),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                ),
                              ),
                              const Text(
                                'Đăng Ký Tài Khoản',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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

                // Overlapping White Card (28px radius top)
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
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

                          // Header Text
                          const Text(
                            'Tạo tài khoản khách hàng',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Trải nghiệm dịch vụ nghỉ dưỡng cao cấp tại Luxe Grand',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),

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
                          const SizedBox(height: 16),

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
                          const SizedBox(height: 16),

                          // 3. Phone
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Số điện thoại',
                            hint: '0912345678',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),

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
                                color: AppColors.textSecondary,
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
                          const SizedBox(height: 10),

                          // Password Strength Indicator (3 bars, 2 gold, 1 gray)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Trung bình',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF59E0B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Terms and Conditions Checkbox
                          GestureDetector(
                            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _agreeTerms
                                        ? AppColors.secondary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _agreeTerms
                                          ? AppColors.secondary
                                          : AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _agreeTerms
                                      ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: const TextSpan(
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(text: 'Tôi đồng ý với '),
                                        TextSpan(
                                          text: 'Điều khoản dịch vụ',
                                          style: TextStyle(
                                            color: AppColors.secondary,
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
                          const SizedBox(height: 28),

                          // Primary Gold Gradient Button
                          CustomButton(
                            text: 'Tạo Tài Khoản',
                            isLoading: isLoading,
                            onPressed: _onRegisterPressed,
                          ),
                          const SizedBox(height: 20),

                          // Login Navigation
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Đã có tài khoản? ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
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
                                child: const Text(
                                  'Đăng nhập ngay',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
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
