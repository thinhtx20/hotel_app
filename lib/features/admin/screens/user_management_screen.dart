import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/sse_client.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

import '../../../features/admin/bloc/user_bloc.dart';
import '../../../features/admin/bloc/user_event.dart';
import '../../../features/admin/bloc/user_state.dart';

class UserManagementScreen extends StatefulWidget {
  final UserRepository? userRepository;
  final UserBloc? userBloc;
  final bool isEmbedded;
  const UserManagementScreen({
    super.key,
    this.userRepository,
    this.userBloc,
    this.isEmbedded = false,
  });

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserRepository _userRepo = widget.userRepository ??
      (sl.isRegistered<UserRepository>() ? sl<UserRepository>() : UserRepository());
  late final UserBloc _userBloc;
  bool _shouldDisposeBloc = false;

  bool _initializedRole = false;

  final TextEditingController _searchController = TextEditingController();
  SseClient? _userSseClient;
  StreamSubscription? _userSseSubscription;
  StreamSubscription? _connectionSub;

  int? _cachedTotalUsers;
  final Map<UserRole, int> _cachedRoleCounts = {};

  void _updateCountCache(UserState state) {
    if (state.selectedRoleFilter == null && state.users.isNotEmpty) {
      _cachedTotalUsers = state.users.length;
      for (final r in UserRole.values) {
        _cachedRoleCounts[r] = state.users.where((u) => u.role == r).length;
      }
    } else if (state.selectedRoleFilter != null) {
      _cachedRoleCounts[state.selectedRoleFilter!] = state.users.length;
    }
  }

  String _getRoleShortLabel(UserRole? role) {
    if (role == null) return 'Tất cả';
    switch (role) {
      case UserRole.customer:
        return 'Khách hàng';
      case UserRole.receptionist:
        return 'Lễ tân';
      case UserRole.admin:
        return 'Quản trị viên';
    }
  }

  UserModel? get _currentUser {
    try {
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) return state.user;
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.userBloc != null) {
      _userBloc = widget.userBloc!;
    } else if (widget.userRepository != null) {
      _userBloc = UserBloc(userRepository: _userRepo);
      _shouldDisposeBloc = true;
    } else if (sl.isRegistered<UserBloc>()) {
      _userBloc = sl<UserBloc>();
    } else {
      _userBloc = UserBloc(userRepository: _userRepo);
      _shouldDisposeBloc = true;
    }
    _userBloc.add(const UserFetchRequested());
    _connectRealtimeStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedRole) {
      _initializedRole = true;
      if (!context.currentRole.canManageUsers) {
        // Lễ tân chỉ xem danh sách khách hàng (§3.2, §4.2)
        _userBloc.add(const UserRoleFilterChanged(UserRole.customer));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSseSubscription?.cancel();
    _connectionSub?.cancel();
    _userSseClient?.dispose();
    if (_shouldDisposeBloc) {
      _userBloc.close();
    }
    super.dispose();
  }

  void _connectRealtimeStream() {
    _userSseClient = _userRepo.createUsersSseClient();
    _connectionSub = _userSseClient!.connectionState.listen((st) {
      _userBloc.add(UserRealtimeConnectionChanged(st == SseConnectionState.connected));
    });

    _userSseSubscription = _userSseClient!.events.listen(
      (event) {
        _userBloc.add(UserRealtimeEventReceived(event));
      },
      onError: (_) {},
    );
    _userSseClient!.connect();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFEF4444);
      case UserRole.receptionist:
        return const Color(0xFF0D9488);
      case UserRole.customer:
        return const Color(0xFF3B82F6);
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên (ADMIN)';
      case UserRole.receptionist:
        return 'Lễ tân – Thu ngân (RECEPTIONIST)';
      case UserRole.customer:
        return 'Khách hàng (CUSTOMER)';
    }
  }

  Future<void> _changeUserRole(UserModel user) async {
    UserRole selectedRole = user.role;

    final confirmed = await AppBottomSheet.show<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final palette = context.palette;
          return AppBottomSheet(
            title: 'Phân quyền người dùng',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thay đổi vai trò cho ${user.fullName} (${user.email}):',
                  style: TextStyle(color: palette.inkMuted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...UserRole.values.map((r) {
                  final isSelected = selectedRole == r;
                  final color = _getRoleColor(r);
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.12) : palette.surface,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      border: Border.all(
                        color: isSelected ? color : palette.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => setSheetState(() => selectedRole = r),
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? color : palette.inkMuted,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _getRoleName(r),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? color : palette.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text(
                      'Lưu thay đổi vai trò',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true && selectedRole != user.role) {
      _userBloc.add(UserRoleUpdateRequested(userId: user.id, role: selectedRole));
    }
  }

  Future<void> _changeUserPassword(UserModel user) async {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? validationError;

    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final palette = context.palette;
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Icon(
                    Icons.key_rounded,
                    color: Color(0xFFD97706),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.15),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: _getRoleColor(user.role),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName.isNotEmpty ? user.fullName : 'Chưa đặt tên',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email,
                                style: TextStyle(color: palette.inkMuted, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới *',
                      hintText: 'Tối thiểu 6 ký tự',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới *',
                      hintText: 'Nhập lại mật khẩu mới',
                      prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('Mặc định (Hotel@123)', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        const randomPass = 'Hotel@123';
                        newPassCtrl.text = randomPass;
                        confirmPassCtrl.text = randomPass;
                        setDialogState(() {
                          obscureNew = false;
                          obscureConfirm = false;
                          validationError = null;
                        });
                      },
                    ),
                  ),
                  if (validationError != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: palette.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        border: Border.all(color: palette.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: palette.error, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              validationError!,
                              style: TextStyle(color: palette.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  final newPass = newPassCtrl.text.trim();
                  final confirmPass = confirmPassCtrl.text.trim();
                  if (newPass.isEmpty) {
                    setDialogState(() => validationError = 'Vui lòng nhập mật khẩu mới');
                    return;
                  }
                  if (newPass.length < 6) {
                    setDialogState(() => validationError = 'Mật khẩu phải có ít nhất 6 ký tự');
                    return;
                  }
                  if (newPass != confirmPass) {
                    setDialogState(() => validationError = 'Mật khẩu xác nhận không khớp');
                    return;
                  }
                  Navigator.pop(ctx, newPass);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                ),
                child: const Text(
                  'Lưu mật khẩu',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );

    newPassCtrl.dispose();
    confirmPassCtrl.dispose();

    if (confirmed != null && confirmed.isNotEmpty) {
      _userBloc.add(UserPasswordChangeRequested(
        userId: user.id,
        newPassword: confirmed,
      ));
    }
  }

  Future<void> _toggleUserActiveStatus(UserModel user) async {
    final me = _currentUser;
    final isSelf = me != null &&
        (me.id == user.id ||
            me.email.toLowerCase() == user.email.toLowerCase());
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Bạn không thể tự khóa tài khoản của chính mình.'),
          backgroundColor: context.palette.warning,
        ),
      );
      return;
    }

    final willDeactivate = user.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              willDeactivate
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              color: willDeactivate ? AppColors.rose : AppColors.secondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(willDeactivate ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willDeactivate
                  ? 'Bạn có chắc muốn vô hiệu hóa tài khoản của ${user.fullName} (${user.email})?'
                  : 'Bạn có chắc muốn kích hoạt lại tài khoản của ${user.fullName} (${user.email})?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: willDeactivate
                    ? AppColors.rose.withValues(alpha: 0.08)
                    : AppColors.secondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(
                  color: willDeactivate
                      ? AppColors.rose.withValues(alpha: 0.2)
                      : AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    willDeactivate
                        ? 'Hệ quả khi khóa tài khoản:'
                        : 'Sau khi mở khóa:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color:
                          willDeactivate ? AppColors.rose : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    willDeactivate
                        ? '• Token hiện tại bị thu hồi ngay lập tức trên hệ thống\n• Chặn đăng nhập (báo "Tài khoản của bạn đã bị khóa")\n• Chặn cấp lại token (refresh token) & quên mật khẩu'
                        : '• Người dùng có thể đăng nhập bình thường và thao tác trên ứng dụng.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  willDeactivate ? AppColors.rose : AppColors.secondary,
            ),
            child: Text(
              willDeactivate ? 'Xác nhận khóa' : 'Kích hoạt',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _userBloc.add(UserStatusToggleRequested(
        userId: user.id,
        isActive: !willDeactivate,
      ));
    }
  }

  Future<void> _softDeleteUser(UserModel user) async {
    final me = _currentUser;
    final isSelf = me != null &&
        (me.id == user.id ||
            me.email.toLowerCase() == user.email.toLowerCase());
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Bạn không thể tự xóa tài khoản của chính mình.'),
          backgroundColor: context.palette.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.rose, size: 24),
            SizedBox(width: 8),
            Text('Xóa tài khoản (Soft-delete)?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Bạn có chắc chắn muốn đưa tài khoản ${user.fullName} (${user.email}) vào trạng thái vô hiệu hóa vĩnh viễn?'),
            const SizedBox(height: 8),
            const Text(
              'Thao tác này sẽ gọi DELETE /users/:id (users.service.ts:146-152) để soft-delete tài khoản (isActive=false).',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Xác nhận xóa',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _userBloc.add(UserDeactivateRequested(user.id));
    }
  }

  Future<void> _showCreateUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    UserRole newRole = UserRole.receptionist;
    bool obscure = true;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final palette = context.palette;
          return AlertDialog(
            title: const Text('Tạo tài khoản mới'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email đăng nhập *'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu khởi tạo *',
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            size: 20),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<UserRole>(
                    initialValue: newRole,
                    decoration:
                        const InputDecoration(labelText: 'Vai trò tài khoản'),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(_getRoleName(r)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => newRole = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty ||
                      emailCtrl.text.trim().isEmpty ||
                      passCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Vui lòng điền đầy đủ họ tên, email và mật khẩu'),
                        backgroundColor: palette.error,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Tạo tài khoản'),
              ),
            ],
          );
        },
      ),
    );

    if (created == true) {
      _userBloc.add(UserCreateRequested(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        fullName: nameCtrl.text.trim(),
        role: newRole.value,
        phone: phoneCtrl.text.trim().isNotEmpty
            ? phoneCtrl.text.trim()
            : null,
      ));
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      if (context.canPop()) {
        context.pop();
        return;
      }
      final role = context.currentRole;
      if (role == UserRole.admin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/receptionist/rooms');
      }
    } catch (_) {
      final role = context.currentRole;
      if (role == UserRole.admin) {
        context.go('/admin/dashboard');
      } else {
        context.go('/receptionist/rooms');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _userBloc,
      child: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: context.palette.error,
              ),
            );
          } else if (state.actionMessage != null) {
            AppNotification.showSuccess(
              context,
              state.actionMessage!,
            );
          }
        },
        builder: (context, state) {
          final palette = context.palette;
          _updateCountCache(state);
          final filtered = state.filteredUsers;
          final totalCount = _cachedTotalUsers ?? state.users.length;

          return Scaffold(
            backgroundColor: palette.canvas,
            appBar: AppBar(
              backgroundColor: palette.surface,
              elevation: 0,
              automaticallyImplyLeading: !widget.isEmbedded,
              leading: widget.isEmbedded
                  ? null
                  : IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.ink, size: 20),
                      onPressed: () => _handleBack(context),
                    ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.currentRole.canManageUsers
                          ? 'Quản Lý Nhân Sự & Người Dùng'
                          : 'Danh Sách Khách Hàng',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (state.isRealtimeConnected)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                if (context.currentRole.canManageUsers)
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    tooltip: 'Tạo tài khoản',
                    onPressed: _showCreateUserDialog,
                  ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: palette.ink),
                  onPressed: () => _userBloc.add(const UserFetchRequested()),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
                  color: palette.surface,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => _userBloc.add(UserSearchChanged(val)),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo họ tên, email, SĐT...',
                          hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                          prefixIcon: Icon(Icons.search_rounded, color: palette.inkMuted, size: 20),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, color: palette.inkMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _userBloc.add(const UserSearchChanged(''));
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.field),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (context.currentRole.canManageUsers) ...[
                        const SizedBox(height: AppSpacing.sm),
                        // Hàng 1: Bộ lọc Vai trò (Role Filter)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildRolePill(
                                label: 'Tất cả',
                                count: totalCount,
                                isSelected: state.selectedRoleFilter == null,
                                onTap: () => _userBloc.add(const UserRoleFilterChanged(null)),
                                palette: palette,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              ...UserRole.values.map((r) {
                                final count = state.selectedRoleFilter == r
                                    ? state.users.length
                                    : (_cachedRoleCounts[r] ?? state.users.where((u) => u.role == r).length);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                                  child: _buildRolePill(
                                    label: _getRoleShortLabel(r),
                                    count: count,
                                    isSelected: state.selectedRoleFilter == r,
                                    onTap: () => _userBloc.add(UserRoleFilterChanged(r)),
                                    palette: palette,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        // Hàng 2: Bộ lọc Trạng thái (Status Filter)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildStatusPill(
                                label: 'Tất cả',
                                count: state.users.length,
                                isSelected: state.selectedStatusFilter == null,
                                onTap: () => _userBloc.add(const UserStatusFilterChanged(null)),
                                palette: palette,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _buildStatusPill(
                                label: 'Hoạt động',
                                count: state.users.where((u) => u.isActive).length,
                                isSelected: state.selectedStatusFilter == true,
                                onTap: () => _userBloc.add(const UserStatusFilterChanged(true)),
                                palette: palette,
                                dotColor: palette.success,
                                activeBgColor: palette.successSurface,
                                activeTextColor: palette.successInk,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              _buildStatusPill(
                                label: 'Đã khóa',
                                count: state.users.where((u) => !u.isActive).length,
                                isSelected: state.selectedStatusFilter == false,
                                onTap: () => _userBloc.add(const UserStatusFilterChanged(false)),
                                palette: palette,
                                dotColor: palette.error,
                                activeBgColor: palette.errorSurface,
                                activeTextColor: palette.errorInk,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: palette.divider),
                Expanded(
                  child: RefreshIndicator(
                    color: palette.accent,
                    onRefresh: () async {
                      _userBloc.add(const UserRefreshRequested());
                    },
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.errorMessage != null && state.users.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(AppSpacing.xxxl),
                                child: AppErrorView(
                                  error: state.errorMessage!,
                                  onRetry: () => _userBloc.add(const UserFetchRequested()),
                                ),
                              )
                            : filtered.isEmpty
                                ? Center(
                                    child: AppEmptyState(
                                      title: 'Không tìm thấy người dùng',
                                      description: state.searchQuery.isNotEmpty
                                          ? 'Không có kết quả nào khớp với từ khóa "${state.searchQuery}".'
                                          : 'Hiện chưa có tài khoản nào phù hợp bộ lọc.',
                                      actionText: (state.searchQuery.isNotEmpty || state.selectedStatusFilter != null)
                                          ? 'Xóa bộ lọc tìm kiếm'
                                          : 'Tải lại',
                                      onAction: () {
                                        if (state.searchQuery.isNotEmpty || state.selectedStatusFilter != null) {
                                          _searchController.clear();
                                          _userBloc.add(const UserSearchChanged(''));
                                          _userBloc.add(const UserStatusFilterChanged(null));
                                        } else {
                                          _userBloc.add(const UserFetchRequested());
                                        }
                                      },
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(AppSpacing.screen),
                                    itemCount: filtered.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                                    itemBuilder: (ctx, i) {
                                      return _buildUserCard(filtered[i], state.processingIds);
                                    },
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

  Widget _buildRolePill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? palette.accent : palette.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? palette.accent : palette.border,
              width: isSelected ? 1.2 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: palette.accent.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? palette.onAccent : palette.ink,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? palette.onAccent.withValues(alpha: 0.22)
                      : palette.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? null
                      : Border.all(color: palette.border.withValues(alpha: 0.6), width: 0.8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? palette.onAccent : palette.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required AppPalette palette,
    Color? dotColor,
    Color? activeBgColor,
    Color? activeTextColor,
  }) {
    final effectiveActiveBg = activeBgColor ?? palette.accent.withValues(alpha: 0.12);
    final effectiveActiveText = activeTextColor ?? palette.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? effectiveActiveBg : palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? effectiveActiveText.withValues(alpha: 0.45)
                  : palette.border,
              width: isSelected ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(
                  width: 6.5,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? effectiveActiveText : palette.inkMuted,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveActiveText.withValues(alpha: 0.12)
                      : palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? effectiveActiveText : palette.inkFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, Set<String> processingIds) {
    final palette = context.palette;
    final isProcessing = processingIds.contains(user.id);
    final roleColor = _getRoleColor(user.role);
    final me = _currentUser;
    final isSelf = me != null &&
        (me.id == user.id || me.email.toLowerCase() == user.email.toLowerCase());

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.15),
              border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: ClipOval(
              child: user.avatar != null && user.avatar!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.avatar!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                          style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName : 'Chưa đặt tên',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'Chính bạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? palette.success.withValues(alpha: 0.12)
                            : palette.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user.isActive ? Icons.check_circle_outline : Icons.lock_outline,
                            size: 12,
                            color: user.isActive ? palette.success : palette.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.isActive ? 'Hoạt động' : 'Đã khóa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: user.isActive ? palette.success : palette.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 13, color: palette.inkMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: palette.inkFaint),
                      const SizedBox(width: 4),
                      Text(
                        user.phone!,
                        style: TextStyle(fontSize: 12, color: palette.inkFaint),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user.role.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ),
                    if (isProcessing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (context.currentRole.canManageUsers)
                      Row(
                        children: [
                          if (!isSelf)
                            IconButton(
                              icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                              color: palette.accent,
                              tooltip: 'Phân quyền vai trò',
                              onPressed: () => _changeUserRole(user),
                            ),
                          if (!isSelf)
                            IconButton(
                              icon: const Icon(Icons.key_rounded, size: 20),
                              color: const Color(0xFFD97706),
                              tooltip: 'Đổi mật khẩu tài khoản',
                              onPressed: () => _changeUserPassword(user),
                            ),
                          IconButton(
                            icon: Icon(
                              user.isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                              size: 20,
                            ),
                            color: isSelf
                                ? palette.inkFaint
                                : (user.isActive ? palette.error : palette.success),
                            tooltip: isSelf
                                ? 'Không thể tự khóa tài khoản của chính mình'
                                : (user.isActive ? 'Khóa tài khoản (Thủ công)' : 'Mở khóa tài khoản'),
                            onPressed: () => _toggleUserActiveStatus(user),
                          ),
                          if (!isSelf)
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, size: 20, color: palette.inkMuted),
                              tooltip: 'Xóa tài khoản (Soft-delete)',
                              onPressed: () => _softDeleteUser(user),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
