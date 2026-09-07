import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/role_enum.dart';
import '../constants/role_permissions.dart';
import '../session/session_scope.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_shift_management_screen.dart';
import '../../features/admin/screens/occupancy_detail_screen.dart';
import '../../features/admin/screens/reports_screen.dart';
import '../../features/admin/screens/room_approval_screen.dart';
import '../../features/admin/screens/room_operations_screen.dart';
import '../../features/admin/screens/room_type_management_screen.dart';
import '../../features/admin/screens/service_catalog_screen.dart';
import '../../features/admin/screens/shift_detail_screen.dart';
import '../../features/admin/screens/staff_and_services_screen.dart';
import '../../features/admin/screens/today_check_ins_screen.dart';
import '../../features/admin/screens/today_check_outs_screen.dart';
import '../../features/admin/screens/user_management_screen.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cashier/screens/cashier_invoices_screen.dart';
import '../../features/customer/screens/home_screen.dart';
import '../../features/customer/screens/my_bookings_screen.dart';
import '../../features/customer/screens/my_invoices_screen.dart';
import '../../features/customer/screens/room_detail_screen.dart';
import '../../features/customer/screens/room_search_screen.dart';
import '../../features/customer/screens/service_order_screen.dart';
import '../../features/customer/widgets/customer_tab_scaffold.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/receptionist/screens/booking_approval_screen.dart';
import '../../features/receptionist/screens/front_desk_today_screen.dart';
import '../../features/receptionist/screens/room_matrix_screen.dart';
import '../../features/receptionist/screens/payment_requests_screen.dart';
import '../../features/receptionist/screens/shift_close_screen.dart';
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
      child: SessionScope(child: child),
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
      child: SessionScope(child: child),
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
/// Phần 3 & 4 sang tầng điều hướng.
const Set<UserRole> _staffRoles = {
  UserRole.admin,
  UserRole.receptionist,
};

/// Bảng chuyển tiếp URL cũ của Thu ngân sang Lễ tân – Thu ngân (FE-ROLE-MATRIX §3.1)
const Map<String, String> _legacyCashierRedirects = {
  '/cashier': '/receptionist/invoices',
  '/cashier/dashboard': '/receptionist',
  '/cashier/check-outs': '/receptionist/today',
  '/cashier/invoices': '/receptionist/invoices',
  '/cashier/profile': '/receptionist/profile',
  '/admin/dashboard': '/admin',
  '/receptionist/rooms': '/receptionist',
  '/receptionist/dashboard': '/receptionist',
};

const Map<String, Set<UserRole>> _sharedRouteAccess = {
  // Duyệt phòng: PATCH /rooms/:id/approve|reject
  '/room-approval': _staffRoles,
  // GET /analytics/occupancy/detail
  '/staff/occupancy-detail': _staffRoles,
  // POST /bookings/:id/check-in
  '/staff/today-check-ins': _staffRoles,
  // POST /bookings/:id/check-out
  '/staff/today-check-outs': _staffRoles,
  // Duyệt đơn đặt phòng
  '/staff/pending-bookings': _staffRoles,
  // GET /users — ADMIN (toàn quyền) + RECEPTIONIST (read-only) (§3.2 & §4.2)
  '/staff/users': _staffRoles,
  '/admin/invoices': {UserRole.admin},
  '/admin/approval': {UserRole.admin},
  '/admin/reports': {UserRole.admin},
  '/admin/rooms': {UserRole.admin},
  '/admin/staff': {UserRole.admin},
  '/admin/services': {UserRole.admin},
  '/admin/room-types': {UserRole.admin},
  '/admin/users': {UserRole.admin},
  '/admin/shifts': {UserRole.admin},
  '/admin/shifts/:id': _staffRoles,
  '/receptionist/today': _staffRoles,
  '/receptionist/approval': _staffRoles,
  '/receptionist/invoices': _staffRoles,
  '/receptionist/profile': _staffRoles,
  '/receptionist/dashboard': _staffRoles,
  '/receptionist/shift-close': _staffRoles,
};

/// Route công khai / không gắn với vai trò nào.
const Set<String> _publicRoutes = {'/', '/login', '/register', '/forgot-password'};

/// Trả về `true` nếu [role] được phép mở [location].
bool _canAccess(UserRole role, String location) {
  if (_publicRoutes.contains(location)) return true;
  if (location.startsWith('/rooms/') || location.startsWith('/room-detail/')) return true;

  for (final entry in _sharedRouteAccess.entries) {
    if (location == entry.key || location.startsWith('${entry.key}/')) {
      return entry.value.contains(role);
    }
  }

  // Nhánh riêng của từng vai trò: '/admin…', '/receptionist…'
  for (final owner in UserRole.values) {
    if (owner == UserRole.customer) continue;
    final prefix = owner.homeRoute; // '/admin' | '/receptionist'
    if (location == prefix || location.startsWith('$prefix/')) {
      return role == owner;
    }
  }

  // Còn lại là app khách hàng: '/customer', '/home', '/search',
  // '/services', '/my-bookings', '/my-invoices', '/profile'.
  return role == UserRole.customer;
}

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    // Tài khoản của lần chạy guard gần nhất. Đổi tài khoản giữa phiên (nút
    // chuyển vai trò ở Hồ sơ, hoặc đăng nhập lại) phải nhảy về màn chính của
    // vai trò mới, kể cả khi màn đang mở vẫn hợp lệ với cả hai vai trò —
    // nếu không, người dùng ở nguyên màn cũ và tưởng app không đổi gì.
    String? lastUserId;

    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.matchedLocation;
        final isLoggingIn = location == '/login';
        final isRegistering = location == '/register';
        final isForgotPassword = location == '/forgot-password';
        final isSplash = location == '/';

        if (isSplash) {
          return null;
        }

        // Chuyển hướng các URL cũ của Thu ngân (FE-ROLE-MATRIX §3.1)
        if (_legacyCashierRedirects.containsKey(location)) {
          return _legacyCashierRedirects[location];
        }
        for (final entry in _legacyCashierRedirects.entries) {
          if (location.startsWith('${entry.key}/')) {
            return entry.value;
          }
        }

        if (authState is AuthInitial) {
          return '/';
        }

        // Đổi tài khoản thất bại nhưng phiên cũ vẫn còn: ở lại đúng chỗ với
        // quyền của tài khoản cũ thay vì bị đá ra màn đăng nhập.
        if (authState is AuthFailure && authState.previousUser != null) {
          final role = authState.previousUser!.role;
          if (isLoggingIn || isRegistering || isForgotPassword) {
            return role.homeRoute;
          }
          return _canAccess(role, location) ? null : role.homeRoute;
        }

        if (authState is AuthUnauthenticated || authState is AuthFailure) {
          lastUserId = null;
          if (isLoggingIn || isRegistering || isForgotPassword) return null;
          return '/login';
        }

        if (authState is AuthAuthenticated) {
          final role = authState.user.role;
          final userId = '${authState.user.id}|${role.value}';
          final switchedAccount = lastUserId != null && lastUserId != userId;
          lastUserId = userId;

          // Đổi tài khoản giữa phiên: về thẳng màn chính của vai trò mới.
          if (switchedAccount && location != role.homeRoute) {
            return role.homeRoute;
          }

          // Đã đăng nhập thì không quay lại được màn đăng nhập/đăng ký/quên mk.
          if (isLoggingIn || isRegistering || isForgotPassword) {
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

        // ShellRoute chứa Bottom Navigation Bar chia 4 Tab cho khách hàng (§4.3)
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
            // Tab 1: Dịch vụ (ServiceOrderScreen)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/services',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ServiceOrderScreen(),
                  ),
                ),
              ],
            ),
            // Tab 2: Chuyến đi (MyBookingsScreen - chứa 2 segment Đơn đặt phòng & Hóa đơn)
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
            // Tab 3: Tài khoản (ProfileScreen)
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

        // ShellRoute cho Quản trị viên (ADMIN) — 5 tab (§4.1)
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
                  label: 'Báo cáo',
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                ),
                StaffTab(
                  label: 'Vận hành phòng',
                  icon: Icons.meeting_room_outlined,
                  activeIcon: Icons.meeting_room_rounded,
                  showsPendingRoomsBadge: true,
                ),
                StaffTab(
                  label: 'Nhân sự & DV',
                  icon: Icons.people_outline,
                  activeIcon: Icons.people_rounded,
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
            // Tab 1: Báo cáo (ReportsScreen)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/reports',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const ReportsScreen(),
                  ),
                ),
              ],
            ),
            // Tab 2: Vận hành phòng (RoomOperationsScreen: Sơ đồ, Hạng phòng, Chờ duyệt)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/rooms',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const RoomOperationsScreen(),
                  ),
                ),
              ],
            ),
            // Tab 3: Nhân sự & Dịch vụ (StaffAndServicesScreen: Nhân sự, Bảng giá DV)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/staff',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const StaffAndServicesScreen(),
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

        // ShellRoute cho Lễ tân – Thu ngân (RECEPTIONIST) — 5 tab (§4.2)
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
                  label: 'Hôm nay',
                  icon: Icons.today_outlined,
                  activeIcon: Icons.today_rounded,
                ),
                StaffTab(
                  label: 'Duyệt đơn',
                  icon: Icons.fact_check_outlined,
                  activeIcon: Icons.fact_check_rounded,
                  showsPendingBookingsBadge: true,
                ),
                StaffTab(
                  label: 'Hóa đơn & Quỹ',
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
            // Tab 0: Sơ đồ phòng (RoomMatrixScreen + ShiftKpiStrip)
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
            // Tab 1: Hôm nay (FrontDeskTodayScreen: Check-in & Check-out)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/today',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const FrontDeskTodayScreen(),
                  ),
                ),
              ],
            ),
            // Tab 2: Duyệt đơn (BookingApprovalScreen)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/receptionist/approval',
                  pageBuilder: (context, state) => AppPage.fadeThrough(
                    key: state.pageKey,
                    child: const BookingApprovalScreen(),
                  ),
                ),
              ],
            ),
            // Tab 3: Hóa đơn & Thu quỹ (CashierInvoicesScreen)
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
            // Tab 4: Hồ sơ (ProfileScreen)
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

        // Màn chi tiết và màn phụ
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const RoomSearchScreen(),
          ),
        ),
        GoRoute(
          path: '/my-invoices',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const MyInvoicesScreen(),
          ),
        ),
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
            child: const BookingApprovalScreen(),
          ),
        ),
        GoRoute(
          path: '/rooms/:id',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: RoomDetailScreen(
              roomId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/room-detail/:id',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: RoomDetailScreen(
              roomId: state.pathParameters['id']!,
            ),
          ),
        ),
        GoRoute(
          path: '/forgot-password',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const UserManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/staff/users',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const UserManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/room-types',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const RoomTypeManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/services',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const ServiceCatalogScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/approval',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const RoomApprovalScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/invoices',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const CashierInvoicesScreen(),
          ),
        ),
        GoRoute(
          path: '/receptionist/dashboard',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const AdminDashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/receptionist/shift-close',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const ShiftCloseScreen(),
          ),
        ),
        // Đối chiếu tiền khách trả qua app trước khi ghi vào sổ thu tiền.
        GoRoute(
          path: '/receptionist/payment-requests',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const PaymentRequestsScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/shifts',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: const AdminShiftManagementScreen(),
          ),
        ),
        GoRoute(
          path: '/admin/shifts/:id',
          pageBuilder: (context, state) => AppPage.slide(
            key: state.pageKey,
            child: ShiftDetailScreen(
              shiftId: state.pathParameters['id']!,
            ),
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
