import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/role_enum.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _minDurationPassed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Giữ màn hình Splash tối thiểu 1.5 giây để người dùng trải nghiệm hiệu ứng mở đầu sang trọng
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _minDurationPassed = true;
      _checkAndNavigate(context.read<AuthBloc>().state);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkAndNavigate(AuthState state) {
    if (!_minDurationPassed || !mounted) return;

    try {
      if (state is AuthAuthenticated) {
        switch (state.user.role) {
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
      } else if (state is AuthUnauthenticated || state is AuthFailure) {
        context.go('/login');
      }
    } catch (_) {
      // Bỏ qua nếu ngữ cảnh test không gắn GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_minDurationPassed) {
          _checkAndNavigate(state);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0B192C)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Hoa văn kiến trúc chìm tinh tế
              Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: CustomPaint(
                    painter: _LuxuryPatternPainter(),
                  ),
                ),
              ),

              // Vầng sáng vàng kim trung tâm
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                        blurRadius: 90,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Nội dung chính
              SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Biểu tượng khách sạn hiệu ứng kính Frosted Glass
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: AppColors.secondaryLight.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.apartment_rounded,
                                size: 52,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Tên thương hiệu
                          const Text(
                            'LUXE GRAND HOTEL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3.0,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Dải trang trí vàng gold
                          Container(
                            width: 48,
                            height: 2.5,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.secondary, AppColors.secondaryLight],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Câu định vị thương hiệu
                          Text(
                            'Trải nghiệm nghỉ dưỡng đẳng cấp',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.8,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          const SizedBox(height: 54),

                          // Vòng xoay nạp dữ liệu phong cách tối giản
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.secondaryLight.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Phiên bản ứng dụng ở đáy
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Phiên bản 1.0.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoa văn hình học tinh tế cho nền sảnh khách sạn 5 sao
class _LuxuryPatternPainter extends CustomPainter {
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
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
