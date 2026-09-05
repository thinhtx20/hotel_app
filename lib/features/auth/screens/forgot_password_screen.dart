import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_error.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

enum ForgotPasswordStep { enterEmail, verifyOtp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  final DioClient? dioClient;
  const ForgotPasswordScreen({super.key, this.dioClient});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final DioClient _dioClient = widget.dioClient ?? sl<DioClient>();

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterEmail;

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotice(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    final palette = context.palette;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? palette.error
            : (isSuccess ? palette.success : palette.accent),
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      final isSuccess = res.statusCode == 200 || res.statusCode == 201;
      if (isSuccess) {
        if (mounted) {
          _showNotice(
            'Mã xác thực OTP đã được gửi đến email của bạn!',
            isSuccess: true,
          );
          setState(() {
            _currentStep = ForgotPasswordStep.verifyOtp;
            _isLoading = false;
          });
        }
      } else {
        throw ApiError.fromDynamic(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e is ApiError
            ? e.message
            : (e is DioException
                ? ApiError.fromDioException(e).message
                : 'Không thể gửi mã xác thực');
        _showNotice(msg, isError: true);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      _showNotice('Vui lòng nhập đầy đủ mã OTP');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();

    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.verifyResetOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      final isSuccess = res.statusCode == 200 || res.statusCode == 201;
      if (isSuccess) {
        if (mounted) {
          _showNotice(
            'Mã OTP hợp lệ! Hãy thiết lập mật khẩu mới.',
            isSuccess: true,
          );
          setState(() {
            _currentStep = ForgotPasswordStep.newPassword;
            _isLoading = false;
          });
        }
      } else {
        throw ApiError.fromDynamic(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e is ApiError
            ? e.message
            : (e is DioException
                ? ApiError.fromDioException(e).message
                : 'Mã OTP không chính xác hoặc đã hết hạn');
        _showNotice(msg, isError: true);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      _showNotice('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    try {
      final res = await _dioClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPass,
        },
      );

      final isSuccess = res.statusCode == 200 || res.statusCode == 201;
      if (isSuccess) {
        if (mounted) {
          _showNotice(
            'Đổi mật khẩu thành công! Vui lòng đăng nhập lại.',
            isSuccess: true,
          );
          context.go('/login');
        }
      } else {
        throw ApiError.fromDynamic(res.data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final msg = e is ApiError
            ? e.message
            : (e is DioException
                ? ApiError.fromDioException(e).message
                : 'Không thể đặt lại mật khẩu');
        _showNotice(msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.ink, size: 20),
          onPressed: () {
            if (_currentStep == ForgotPasswordStep.newPassword) {
              setState(() => _currentStep = ForgotPasswordStep.verifyOtp);
            } else if (_currentStep == ForgotPasswordStep.verifyOtp) {
              setState(() => _currentStep = ForgotPasswordStep.enterEmail);
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            }
          },
        ),
        title: Text(
          'Khôi Phục Mật Khẩu',
          style: TextStyle(
            color: palette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Step Indicators
              Row(
                children: [
                  _buildStepIndicator(
                    stepNumber: 1,
                    title: 'Email',
                    isActive: _currentStep == ForgotPasswordStep.enterEmail,
                    isDone: _currentStep != ForgotPasswordStep.enterEmail,
                  ),
                  _buildStepDivider(isDone: _currentStep != ForgotPasswordStep.enterEmail),
                  _buildStepIndicator(
                    stepNumber: 2,
                    title: 'Xác thực OTP',
                    isActive: _currentStep == ForgotPasswordStep.verifyOtp,
                    isDone: _currentStep == ForgotPasswordStep.newPassword,
                  ),
                  _buildStepDivider(isDone: _currentStep == ForgotPasswordStep.newPassword),
                  _buildStepIndicator(
                    stepNumber: 3,
                    title: 'Mật khẩu mới',
                    isActive: _currentStep == ForgotPasswordStep.newPassword,
                    isDone: false,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Step 1: Enter Email
              if (_currentStep == ForgotPasswordStep.enterEmail) ...[
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quên mật khẩu?',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Nhập địa chỉ email tài khoản của bạn để nhận mã xác thực OTP.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Địa chỉ Email *',
                        hint: 'example@hotel.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
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
                      const SizedBox(height: AppSpacing.xl),
                      CustomButton(
                        text: 'Gửi mã xác thực',
                        isLoading: _isLoading,
                        onPressed: _sendOtp,
                      ),
                    ],
                  ),
                ),
              ],

              // Step 2: Verify OTP
              if (_currentStep == ForgotPasswordStep.verifyOtp) ...[
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác thực OTP',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Vui lòng nhập mã OTP đã được gửi đến ${_emailController.text}:',
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomTextField(
                        controller: _otpController,
                        label: 'Mã xác thực OTP *',
                        hint: 'VD: 123456',
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.pin_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          child: Text(
                            'Gửi lại mã OTP',
                            style: TextStyle(color: palette.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomButton(
                        text: 'Xác nhận mã OTP',
                        isLoading: _isLoading,
                        onPressed: _verifyOtp,
                      ),
                    ],
                  ),
                ),
              ],

              // Step 3: New Password
              if (_currentStep == ForgotPasswordStep.newPassword) ...[
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thiết lập mật khẩu mới',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Mật khẩu mới phải có ít nhất 6 ký tự.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.inkMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu mới *',
                        hint: 'Tối thiểu 6 ký tự',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: palette.inkMuted,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Mật khẩu phải từ 6 ký tự trở lên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Xác nhận mật khẩu mới *',
                        hint: 'Nhập lại mật khẩu mới',
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icons.lock_reset_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: palette.inkMuted,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomButton(
                        text: 'Cập nhật mật khẩu',
                        isLoading: _isLoading,
                        onPressed: _resetPassword,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isDone,
  }) {
    final palette = context.palette;
    final color = isDone
        ? palette.success
        : (isActive ? palette.accent : palette.inkFaint);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? palette.success
                : (isActive ? palette.accent.withValues(alpha: 0.15) : palette.surfaceMuted),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isActive ? palette.accent : palette.inkMuted,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool isDone}) {
    final palette = context.palette;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: isDone ? palette.success : palette.border,
      ),
    );
  }
}
