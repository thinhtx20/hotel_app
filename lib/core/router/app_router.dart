import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/role_enum.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/room_approval_screen.dart';
import '../../features/admin/widgets/admin_tab_scaffold.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/cashier/screens/cashier_invoices_screen.dart';
import '../../features/customer/screens/home_screen.dart';
import '../../features/customer/screens/my_bookings_screen.dart';
import '../../features/customer/screens/room_search_screen.dart';
import '../../features/customer/widgets/customer_tab_scaffold.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/receptionist/screens/room_matrix_screen.dart';
import '../../features/splash/splash_screen.dart';

class AppRouter {
  static GoRouter createRouter(AuthBloc authBloc) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (context, state) {
        final authState = authBloc.state;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';
        final isSplash = state.matchedLocation == '/';

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
          if (isLoggingIn || isRegistering || isSplash) {
            switch (authState.user.role) {
              case UserRole.admin:
                return '/admin';
              case UserRole.receptionist:
                return '/receptionist';
              case UserRole.cashier:
                return '/cashier';
              case UserRole.customer:
                return '/customer';
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
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
                  builder: (context, state) => const CustomerHomeScreen(),
                ),
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const CustomerHomeScreen(),
                ),
              ],
            ),
            // Tab 1: Tìm kiếm
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) => const RoomSearchScreen(),
                ),
              ],
            ),
            // Tab 2: Đơn phòng
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my-bookings',
                  builder: (context, state) => const MyBookingsScreen(),
                ),
              ],
            ),
            // Tab 3: Tài khoản
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        // ShellRoute chứa Bottom Navigation Bar chia 4 Tab cho Quản trị viên (Admin)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdminTabScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Tab 0: Tổng quan (Dashboard)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin',
                  builder: (context, state) => const AdminDashboardScreen(),
                ),
              ],
            ),
            // Tab 1: Duyệt phòng (Room Approval)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/approval',
                  builder: (context, state) => const RoomApprovalScreen(),
                ),
              ],
            ),
            // Tab 2: Sơ đồ buồng phòng (Room Matrix)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/rooms',
                  builder: (context, state) => const RoomMatrixScreen(),
                ),
              ],
            ),
            // Tab 3: Thu ngân & Hóa đơn (Cashier)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/cashier',
                  builder: (context, state) => const CashierInvoicesScreen(),
                ),
              ],
            ),
          ],
        ),
        // Các route độc lập của nhân viên / quản lý
        GoRoute(
          path: '/receptionist',
          builder: (context, state) => const RoomMatrixScreen(),
        ),
        GoRoute(
          path: '/cashier',
          builder: (context, state) => const CashierInvoicesScreen(),
        ),
        GoRoute(
          path: '/room-approval',
          builder: (context, state) => const RoomApprovalScreen(),
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
