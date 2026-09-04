import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';

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
  final Set<String> _processingIds = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (_searchQuery.trim().isEmpty) return _users;
    final q = _searchQuery.toLowerCase().trim();
    return _users.where((u) {
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
      case UserRole.cashier:
        return const Color(0xFFF59E0B);
      case UserRole.customer:
        return const Color(0xFF3B82F6);
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên (ADMIN)';
      case UserRole.receptionist:
        return 'Lễ tân (RECEPTIONIST)';
      case UserRole.cashier:
        return 'Thu ngân (CASHIER)';
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
        await _userRepo.updateUser(user.id, {'role': selectedRole.value});
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
    final willDeactivate = user.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willDeactivate ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'),
        content: Text(
          willDeactivate
              ? 'Tài khoản ${user.fullName} (${user.email}) sẽ bị vô hiệu hóa và không thể đăng nhập hệ thống.'
              : 'Tài khoản ${user.fullName} (${user.email}) sẽ được kích hoạt lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willDeactivate ? AppColors.rose : AppColors.secondary,
            ),
            child: Text(
              willDeactivate ? 'Xác nhận khóa' : 'Kích hoạt',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _processingIds.add(user.id));
      try {
        if (willDeactivate) {
          await _userRepo.deactivate(user.id);
        } else {
          await _userRepo.updateUser(user.id, {'isActive': true});
        }
        await _fetchUsers(isSilent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willDeactivate ? 'Đã khóa tài khoản ${user.fullName}' : 'Đã mở khóa tài khoản ${user.fullName}'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thao tác thất bại: ${e.toString()}'),
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
        title: Text(
          'Quản Lý Nhân Sự & Người Dùng',
          style: TextStyle(
            color: palette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
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
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleFilterChip(label: 'Tất cả (${_users.length})', role: null),
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
                                    : 'Hiện chưa có tài khoản nào trong hệ thống.',
                                actionText: _searchQuery.isNotEmpty ? 'Xóa bộ lọc tìm kiếm' : 'Tải lại',
                                onAction: () {
                                  if (_searchQuery.isNotEmpty) {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
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

  Widget _buildUserCard(UserModel user) {
    final palette = context.palette;
    final isProcessing = _processingIds.contains(user.id);
    final roleColor = _getRoleColor(user.role);

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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isActive
                            ? palette.success.withValues(alpha: 0.12)
                            : palette.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        user.isActive ? 'Hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.isActive ? palette.success : palette.error,
                        ),
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
                    else
                      Row(
                        children: [
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
                            color: user.isActive ? palette.error : palette.success,
                            tooltip: user.isActive ? 'Khóa tài khoản' : 'Mở khóa',
                            onPressed: () => _toggleUserActiveStatus(user),
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
