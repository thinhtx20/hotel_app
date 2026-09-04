import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/role_enum.dart';
import '../constants/role_permissions.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/occupancy_detail_screen.dart';
import '../../features/admin/screens/pending_bookings_screen.dart';
import '../../features/admin/screens/room_approval_screen.dart';
import '../../features/admin/screens/today_check_ins_screen.dart';
import '../../features/admin/screens/today_check_outs_screen.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cashier/screens/cashier_invoices_screen.dart';
import '../../features/customer/screens/home_screen.dart';
import '../../features/customer/screens/my_bookings_screen.dart';
import '../../features/customer/screens/my_invoices_screen.dart';
import '../../features/customer/screens/room_search_screen.dart';
import '../../features/customer/widgets/customer_tab_scaffold.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/receptionist/screens/room_matrix_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../shared/widgets/staff_tab_scaffold.dart';

/// Helper tạo chuyển cảnh trang chuẩn hóa — xem `design/UI-REVAMP-PLAN.md` mục 3.3.
class AppPage {
  /// Push màn chi tiết: trượt từ phải + fade nhẹ (280ms, easeOutCubic)
  static CustomTransitionPage<void> slide({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 280),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
        );
      },
    );
  }

  /// Splash -> Login/Home: fade thuần (400ms)
  static CustomTransitionPage<void> fade({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: child,
        );
      },
    );
  }

  /// Chuyển tab (trong shell): fade-through, không trượt (200ms)
  static CustomTransitionPage<void> fadeThrough({
    required LocalKey key,
    required Widget child,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

/// Vai trò nào được vào route nào — bản dịch của `design/FE-ROLE-MATRIX.md`
/// Phần 4 sang tầng điều hướng.
///
/// Mỗi vai trò có một nhánh route riêng nên chủ sở hữu suy ra được từ tiền tố;
/// chỉ các màn dùng chung mới phải liệt kê tường minh.
const Set<UserRole> _staffRoles = {
  UserRole.admin,
  UserRole.receptionist,
  UserRole.cashier,
};

const Map<String, Set<UserRole>> _sharedRouteAccess = {
  // Duyệt phòng: PATCH /rooms/:id/approve|reject
  '/room-approval': {UserRole.admin, UserRole.receptionist},
  // GET /analytics/occupancy/detail — thu ngân bị 403
  '/staff/occupancy-detail': {UserRole.admin, UserRole.receptionist},
  // POST /bookings/:id/check-in — thu ngân xem được, không bấm được
  '/staff/today-check-ins': _staffRoles,
  // POST /bookings/:id/check-out — cả ba vai trò nhân viên
  '/staff/today-check-outs': _staffRoles,
  // Duyệt đơn đặt phòng
  '/staff/pending-bookings': {UserRole.admin, UserRole.receptionist},
};

/// Route công khai / không gắn với vai trò nào.
const Set<String> _publicRoutes = {'/', '/login', '/register'};

/// Trả về `true` nếu [role] được phép mở [location].
bool _canAccess(UserRole role, String location) {
  if (_publicRoutes.contains(location)) return true;

  for (final entry in _sharedRouteAccess.entries) {
    if (location == entry.key || location.startsWith('${entry.key}/')) {
      return entry.value.contains(role);
    }
  }

  // Nhánh riêng của từng vai trò: '/admin…', '/receptionist…', '/cashier…'
  for (final owner in UserRole.values) {
    if (owner == UserRole.customer) continue;
    final prefix = owner.homeRoute; // '/admin' | '/receptionist' | '/cashier'
    if (location == prefix || location.startsWith('$prefix/')) {
      return role == owner;
    }
  }

  // Còn lại là app khách hàng: '/customer', '/home', '/search',
  // '/my-bookings', '/my-invoices', '/profile'.
  return role == UserRole.customer;
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.matchedLocation;
        final isLoggingIn = location == '/login';
        final isRegistering = location == '/register';
        final isSplash = location == '/';

        if (isSplash) {
          return null;
        }

        if (authState is AuthInitial) {
          return '/';
        }

        if (authState is AuthUnauthenticated || authState is AuthFailure) {
          if (isLoggingIn || isRegistering) return null;
          return '/login';
        }

        if (authState is AuthAuthenticated) {
          final role = authState.user.role;

          // Đã đăng nhập thì không quay lại được màn đăng nhập/đăng ký.
          if (isLoggingIn || isRegistering) {
            return role.homeRoute;
          }

          // Chặn truy cập chéo: gõ tay '/admin' bằng tài khoản khách sẽ bị
          // đẩy về màn chính của chính vai trò đó thay vì nhận 403 hàng loạt.
          if (!_canAccess(role, location)) {
            return role.homeRoute;
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => AppPage.fade(
            key: state.pageKey,
            child: const SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => AppPage.fade(
            key: state.pageKey,
            child: const LoginScreen(),
            duration: const Duration(milliseconds: 350),
          ),
        ),
        GoRoute(
          path: '/register',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const RegisterScreen(),
          ),
        ),
        // ShellRoute chứa Bottom Navigation Bar chia 4 Tab cho khách hàng
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return CustomerTabScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Khám phá (Home)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/customer',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const CustomerHomeScreen(),
                  ),
                ),
                GoRoute(
                  path: '/home',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const CustomerHomeScreen(),
                  ),
                ),
              ],
            ),
            // Tab 1: Tìm kiếm
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomSearchScreen(),
                  ),
                ),
              ],
            ),
            // Tab 2: Đơn phòng
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-bookings',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const MyBookingsScreen(),
                  ),
                ),
              ],
            ),
            // Tab 3: Hóa đơn của tôi — GET /invoices/my (§4.4)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-invoices',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const MyInvoicesScreen(),
                  ),
                ),
              ],
            ),
            // Tab 4: Tài khoản
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // ShellRoute cho Quản trị viên (ADMIN) — toàn quyền, xem §4.1
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StaffTabScaffold(
              navigationShell: navigationShell,
              tabs: const [
                StaffTab(
                  label: 'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                ),
                StaffTab(
                  label: 'Duyệt phòng',
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  showsPendingRoomsBadge: true,
                ),
                StaffTab(
                  label: 'Sơ đồ phòng',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                ),
                StaffTab(
                  label: 'Thu ngân',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                ),
                StaffTab(
                  label: 'Hồ sơ',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            );
          },
          branches: [
            // Tab 0: Tổng quan (Dashboard)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const AdminDashboardScreen(),
                  ),
                ),
              ],
            ),
            // Tab 1: Duyệt phòng (Room Approval)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/approval',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomApprovalScreen(),
                  ),
                ),
              ],
            ),
            // Tab 2: Sơ đồ buồng phòng (Room Matrix)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/rooms',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomMatrixScreen(),
                  ),
                ),
              ],
            ),
            // Tab 3: Thu ngân & Hóa đơn
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/invoices',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const CashierInvoicesScreen(),
                  ),
                ),
              ],
            ),
            // Tab 4: Hồ sơ
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/profile',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // ShellRoute cho Lễ tân (RECEPTIONIST) — vào thẳng Sơ đồ phòng, §4.2.
        // Không có tab Doanh thu năm; nút "Tạo hóa đơn" bị ẩn trong màn Hóa đơn.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StaffTabScaffold(
              navigationShell: navigationShell,
              tabs: const [
                StaffTab(
                  label: 'Sơ đồ phòng',
                  icon: Icons.grid_view_outlined,
                  activeIcon: Icons.grid_view_rounded,
                ),
                StaffTab(
                  label: 'Duyệt phòng',
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  showsPendingRoomsBadge: true,
                ),
                StaffTab(
                  label: 'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                ),
                StaffTab(
                  label: 'Hóa đơn',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                ),
                StaffTab(
                  label: 'Hồ sơ',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomMatrixScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/approval',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomApprovalScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/dashboard',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const AdminDashboardScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/invoices',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const CashierInvoicesScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/profile',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // ShellRoute cho Thu ngân (CASHIER) — vào thẳng Hóa đơn, §4.3.
        // Không có Sơ đồ phòng, không có Duyệt phòng, không có Nhận phòng.
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return StaffTabScaffold(
              navigationShell: navigationShell,
              tabs: const [
                StaffTab(
                  label: 'Hóa đơn',
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                ),
                StaffTab(
                  label: 'Tổng quan',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                ),
                StaffTab(
                  label: 'Trả phòng',
                  icon: Icons.logout_outlined,
                  activeIcon: Icons.logout_rounded,
                ),
                StaffTab(
                  label: 'Hồ sơ',
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                ),
              ],
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cashier',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const CashierInvoicesScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cashier/dashboard',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const AdminDashboardScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cashier/check-outs',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const TodayCheckOutsScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cashier/profile',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Màn chi tiết dùng chung của nhân viên — quyền khai báo ở
        // [_sharedRouteAccess]; nút bên trong còn được lọc thêm theo vai trò.
        GoRoute(
          path: '/room-approval',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const RoomApprovalScreen(),
          ),
        ),
        GoRoute(
          path: '/staff/occupancy-detail',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const OccupancyDetailScreen(),
          ),
        ),
        GoRoute(
          path: '/staff/today-check-ins',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const TodayCheckInsScreen(),
          ),
        ),
        GoRoute(
          path: '/staff/today-check-outs',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const TodayCheckOutsScreen(),
          ),
        ),
        GoRoute(
          path: '/staff/pending-bookings',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const PendingBookingsScreen(),
          ),
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen(
      (dynamic _) => notifyListeners(),
      cancelOnError: false,
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
