import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/constants/role_permissions.dart';
import '../../../core/network/api_error.dart';
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

class UserManagementScreen extends StatefulWidget {
  final UserRepository? userRepository;
  const UserManagementScreen({super.key, this.userRepository});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserRepository _userRepo = widget.userRepository ?? sl<UserRepository>();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  UserRole? _selectedRoleFilter;
  bool? _selectedStatusFilter;
  final Set<String> _processingIds = {};
  bool _initializedRole = false;

  final TextEditingController _searchController = TextEditingController();
  SseClient? _userSseClient;
  StreamSubscription? _userSseSubscription;
  StreamSubscription? _connectionSub;
  bool _isRealtimeConnected = false;

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
    _fetchUsers();
    _connectRealtimeStream();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedRole) {
      _initializedRole = true;
      if (!context.currentRole.canManageUsers) {
        // Lễ tân chỉ xem danh sách khách hàng (§3.2, §4.2)
        _selectedRoleFilter = UserRole.customer;
        _fetchUsers();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSseSubscription?.cancel();
    _connectionSub?.cancel();
    _userSseClient?.dispose();
    super.dispose();
  }

  void _connectRealtimeStream() {
    _userSseClient = _userRepo.createUsersSseClient();
    _connectionSub = _userSseClient!.connectionState.listen((st) {
      if (mounted) {
        setState(() {
          _isRealtimeConnected = st == SseConnectionState.connected;
        });
      }
    });

    _userSseSubscription = _userSseClient!.events.listen(
      (event) {
        _handleUserEvent(event);
      },
      onError: (_) {},
    );
    _userSseClient!.connect();
  }

  void _handleUserEvent(SseEvent event) {
    if (!mounted) return;
    switch (event.event) {
      case 'user.created':
        final data = event.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          try {
            final newUser = UserModel.fromJson(Map<String, dynamic>.from(userMap));
            setState(() {
              if (!_users.any((u) => u.id == newUser.id)) {
                _users.insert(0, newUser);
              }
            });
            AppNotification.showSuccess(
              context,
              'Tài khoản mới: ${newUser.fullName.isNotEmpty ? newUser.fullName : newUser.email}',
            );
          } catch (_) {}
        }
        break;

      case 'user.updated':
        final data = event.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          try {
            final updatedUser = UserModel.fromJson(Map<String, dynamic>.from(userMap));
            setState(() {
              final idx = _users.indexWhere((u) => u.id == updatedUser.id);
              if (idx != -1) {
                _users[idx] = updatedUser;
              }
            });
          } catch (_) {}
        }
        break;

      case 'user.deactivated':
        final data = event.data;
        if (data is Map) {
          final userMap = data['user'] is Map ? data['user'] as Map : data;
          final deactivatedId = userMap['id']?.toString() ?? data['id']?.toString();
          if (deactivatedId != null) {
            setState(() {
              final idx = _users.indexWhere((u) => u.id == deactivatedId);
              if (idx != -1) {
                _users[idx] = _users[idx].copyWith(isActive: false);
              }
            });
          }
        }
        break;

      default:
        // ready, ping
        break;
    }
  }

  Future<void> _fetchUsers({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final list = await _userRepo.fetchAll(
        role: _selectedRoleFilter?.value,
      );
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiError ? e.message : 'Không thể tải danh sách người dùng';
        });
      }
    }
  }

  List<UserModel> get _filteredUsers {
    var list = _users;
    if (_selectedStatusFilter != null) {
      list = list.where((u) => u.isActive == _selectedStatusFilter).toList();
    }
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((u) {
      final name = u.fullName.toLowerCase();
      final email = u.email.toLowerCase();
      final phone = (u.phone ?? '').toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
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
      setState(() => _processingIds.add(user.id));
      try {
        final updatedUser = await _userRepo.updateUser(user.id, {'role': selectedRole.value});
        if (mounted) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _users[idx] = updatedUser;
            }
          });
        }
        await _fetchUsers(isSilent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật vai trò của ${user.fullName} sang ${_getRoleName(selectedRole)}'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật: ${e.toString()}'),
              backgroundColor: context.palette.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingIds.remove(user.id));
        }
      }
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
      setState(() => _processingIds.add(user.id));
      try {
        // Gọi PATCH /users/:id body { isActive: false | true } (update-user.dto.ts:26-29)
        final updatedUser =
            await _userRepo.setActiveStatus(user.id, !willDeactivate);
        if (mounted) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _users[idx] = updatedUser;
            }
          });
        }
        await _fetchUsers(isSilent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willDeactivate
                  ? 'Đã khóa tài khoản ${user.fullName}'
                  : 'Đã mở khóa tài khoản ${user.fullName}'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Thao tác thất bại: ${e is ApiError ? e.message : e.toString()}'),
              backgroundColor: context.palette.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingIds.remove(user.id));
        }
      }
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
      setState(() => _processingIds.add(user.id));
      try {
        await _userRepo.deactivate(user.id);
        if (mounted) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _users[idx] = _users[idx].copyWith(isActive: false);
            }
          });
        }
        await _fetchUsers(isSilent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã vô hiệu hóa tài khoản ${user.fullName} (Soft-delete)'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Thao tác thất bại: ${e is ApiError ? e.message : e.toString()}'),
              backgroundColor: context.palette.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingIds.remove(user.id));
        }
      }
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
      try {
        final newUser = await _userRepo.createUser(
          email: emailCtrl.text.trim(),
          password: passCtrl.text.trim(),
          fullName: nameCtrl.text.trim(),
          role: newRole.value,
          phone: phoneCtrl.text.trim().isNotEmpty
              ? phoneCtrl.text.trim()
              : null,
        );
        if (mounted) {
          setState(() {
            if (!_users.any((u) => u.id == newUser.id)) {
              _users.insert(0, newUser);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã tạo thành công tài khoản cho ${nameCtrl.text.trim()}'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Lỗi tạo tài khoản: ${e is ApiError ? e.message : e.toString()}'),
              backgroundColor: context.palette.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: palette.ink, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
            if (_isRealtimeConnected)
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
            onPressed: () => _fetchUsers(),
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
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo họ tên, email, SĐT...',
                    hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: palette.inkMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: palette.inkMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilterChip(label: 'Tất cả vai trò (${_users.length})', role: null),
                        const SizedBox(width: AppSpacing.xs),
                        ...UserRole.values.map((r) {
                          final count = _users.where((u) => u.role == r).length;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: _buildRoleFilterChip(
                              label: '${r.label} ($count)',
                              role: r,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusFilterChip(
                          label: 'Tất cả trạng thái (${_users.length})',
                          status: null,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildStatusFilterChip(
                          label: 'Hoạt động (${_users.where((u) => u.isActive).length})',
                          status: true,
                          color: palette.success,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildStatusFilterChip(
                          label: 'Đã khóa (${_users.where((u) => !u.isActive).length})',
                          status: false,
                          color: palette.error,
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
              onRefresh: () => _fetchUsers(isSilent: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: AppErrorView(
                            error: _errorMessage!,
                            onRetry: () => _fetchUsers(),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: AppEmptyState(
                                title: 'Không tìm thấy người dùng',
                                description: _searchQuery.isNotEmpty
                                    ? 'Không có kết quả nào khớp với từ khóa "$_searchQuery".'
                                    : 'Hiện chưa có tài khoản nào phù hợp bộ lọc.',
                                actionText: (_searchQuery.isNotEmpty || _selectedStatusFilter != null)
                                    ? 'Xóa bộ lọc tìm kiếm'
                                    : 'Tải lại',
                                onAction: () {
                                  if (_searchQuery.isNotEmpty || _selectedStatusFilter != null) {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedStatusFilter = null;
                                    });
                                  } else {
                                    _fetchUsers();
                                  }
                                },
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.screen),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (ctx, i) {
                                return _buildUserCard(filtered[i]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip({required String label, required UserRole? role}) {
    final palette = context.palette;
    final isSelected = _selectedRoleFilter == role;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedRoleFilter = role);
        _fetchUsers();
      },
      backgroundColor: palette.surfaceMuted,
      selectedColor: palette.accent.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? palette.accent : palette.ink,
      ),
      side: BorderSide(
        color: isSelected ? palette.accent : palette.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool? status,
    Color? color,
  }) {
    final palette = context.palette;
    final isSelected = _selectedStatusFilter == status;
    final effectiveColor = color ?? palette.accent;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedStatusFilter = status);
      },
      backgroundColor: palette.surfaceMuted,
      selectedColor: effectiveColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? effectiveColor : palette.ink,
      ),
      side: BorderSide(
        color: isSelected ? effectiveColor : palette.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final palette = context.palette;
    final isProcessing = _processingIds.contains(user.id);
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
