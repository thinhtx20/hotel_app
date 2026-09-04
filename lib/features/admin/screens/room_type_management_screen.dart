import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_text_field.dart';

class RoomTypeManagementScreen extends StatefulWidget {
  final RoomRepository? roomRepository;
  const RoomTypeManagementScreen({super.key, this.roomRepository});

  @override
  State<RoomTypeManagementScreen> createState() => _RoomTypeManagementScreenState();
}

class _RoomTypeManagementScreenState extends State<RoomTypeManagementScreen> {
  late final RoomRepository _roomRepo = widget.roomRepository ?? sl<RoomRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final Set<String> _deletingIds = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRoomTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoomTypes({bool isSilent = false}) async {
    if (!isSilent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _roomRepo.fetchRoomTypes();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiError ? e.message : 'Không thể tải danh sách hạng phòng';
        });
      }
    }
  }

  List<RoomTypeModel> get _filteredTypes {
    final list = _roomRepo.roomTypes;
    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((t) {
      final name = t.name.toLowerCase();
      final code = t.code.toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  void _openCreateOrEditModal({RoomTypeModel? existingType}) {
    final isEditing = existingType != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: existingType?.name ?? '');
    final codeController = TextEditingController(text: existingType?.code ?? '');
    final priceController = TextEditingController(
      text: existingType != null ? Formatters.formatNumber(existingType.basePrice.toInt()) : '',
    );
    final descController = TextEditingController(text: existingType?.description ?? '');
    final adultsController = TextEditingController(
      text: existingType != null ? '${existingType.capacityAdults}' : '2',
    );
    final childrenController = TextEditingController(
      text: existingType != null ? '${existingType.capacityChildren}' : '0',
    );
    final sizeController = TextEditingController(
      text: existingType != null ? '${existingType.sizeSqM}' : '30',
    );
    final imageController = TextEditingController(
      text: existingType != null && existingType.images.isNotEmpty ? existingType.images.first : '',
    );

    bool isSubmitting = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final palette = context.palette;

          return AppBottomSheet(
            title: isEditing ? 'Chỉnh sửa Hạng phòng' : 'Thêm Hạng phòng mới',
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: nameController,
                      label: 'Tên hạng phòng *',
                      hint: 'VD: Deluxe Ocean View',
                      prefixIcon: Icons.king_bed_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên hạng phòng' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: codeController,
                            label: 'Mã hạng phòng *',
                            hint: 'VD: DLX_OCN',
                            prefixIcon: Icons.tag_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập mã' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: CustomTextField(
                            controller: priceController,
                            label: 'Giá gốc (VNĐ/đêm) *',
                            hint: 'VD: 1.500.000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.payments_outlined,
                            inputFormatters: [CurrencyInputFormatter()],
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập giá' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: adultsController,
                            label: 'Người lớn *',
                            hint: '2',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: CustomTextField(
                            controller: childrenController,
                            label: 'Trẻ em',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.child_care_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: CustomTextField(
                            controller: sizeController,
                            label: 'Diện tích (m²)',
                            hint: '30',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.square_foot_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    CustomTextField(
                      controller: imageController,
                      label: 'URL Ảnh bìa',
                      hint: 'https://...',
                      prefixIcon: Icons.image_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Mô tả chi tiết',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Mô tả không gian, góc nhìn, dịch vụ...',
                        hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);

                                final payload = {
                                  'name': nameController.text.trim(),
                                  'code': codeController.text.trim().toUpperCase(),
                                  'basePrice': Formatters.parseCurrency(priceController.text) ?? 1000000,
                                  'capacityAdults': int.tryParse(adultsController.text.trim()) ?? 2,
                                  'capacityChildren': int.tryParse(childrenController.text.trim()) ?? 0,
                                  'sizeSqM': num.tryParse(sizeController.text.trim()) ?? 30,
                                  if (descController.text.trim().isNotEmpty)
                                    'description': descController.text.trim(),
                                  if (imageController.text.trim().isNotEmpty)
                                    'images': [imageController.text.trim()],
                                };

                                try {
                                  if (isEditing) {
                                    await _roomRepo.updateRoomType(existingType.id, payload);
                                  } else {
                                    await _roomRepo.createRoomType(payload);
                                  }

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isEditing
                                              ? 'Đã cập nhật hạng phòng ${nameController.text}'
                                              : 'Đã tạo hạng phòng mới thành công!',
                                        ),
                                        backgroundColor: context.palette.success,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Lỗi: ${e.toString()}'),
                                        backgroundColor: context.palette.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Lưu thay đổi' : 'Tạo hạng phòng',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteRoomType(RoomTypeModel type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa hạng phòng?'),
        content: Text(
          'Bạn có chắc muốn xóa hạng phòng "${type.name}" (${type.code})? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _deletingIds.add(type.id));
      try {
        await _roomRepo.deleteRoomType(type.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa hạng phòng ${type.name} thành công'),
              backgroundColor: context.palette.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể xóa hạng phòng: ${e.toString()}'),
              backgroundColor: context.palette.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _deletingIds.remove(type.id));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final types = _filteredTypes;

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
          'Quản Lý Hạng Phòng',
          style: TextStyle(
            color: palette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: palette.ink),
            onPressed: () => _fetchRoomTypes(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateOrEditModal(),
        backgroundColor: palette.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm hạng phòng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
            color: palette.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã hạng phòng...',
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
          ),
          Divider(height: 1, color: palette.divider),

          // List
          Expanded(
            child: RefreshIndicator(
              color: palette.accent,
              onRefresh: () => _fetchRoomTypes(isSilent: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxxl),
                          child: AppErrorView(
                            error: _errorMessage!,
                            onRetry: () => _fetchRoomTypes(),
                          ),
                        )
                      : types.isEmpty
                          ? Center(
                              child: AppEmptyState(
                                title: 'Không có hạng phòng nào',
                                description: _searchQuery.isNotEmpty
                                    ? 'Không tìm thấy kết quả phù hợp.'
                                    : 'Chưa có hạng phòng nào được tạo trên hệ thống.',
                                actionText: 'Tạo hạng phòng',
                                onAction: () => _openCreateOrEditModal(),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screen,
                                AppSpacing.screen,
                                AppSpacing.screen,
                                80, // bottom padding for FAB
                              ),
                              itemCount: types.length,
                              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (ctx, i) {
                                return _buildRoomTypeCard(types[i]);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeCard(RoomTypeModel type) {
    final palette = context.palette;
    final isDeleting = _deletingIds.contains(type.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image (if any)
          if (type.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: type.images.first,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(
                    color: palette.surfaceMuted,
                    child: Icon(Icons.broken_image_outlined, color: palette.inkMuted),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Name + Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        type.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        type.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Price
                Text(
                  '${Formatters.formatCurrency(type.basePrice)} / đêm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Specs: Capacity, Size, Rooms count
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: palette.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${type.capacityAdults} Lớn, ${type.capacityChildren} Nhỏ',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.square_foot_outlined, size: 14, color: palette.inkMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${type.sizeSqM.toInt()} m²',
                      style: TextStyle(fontSize: 12, color: palette.inkMuted),
                    ),
                    if (type.roomsCount != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      Icon(Icons.door_front_door_outlined, size: 14, color: palette.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${type.roomsCount} phòng',
                        style: TextStyle(fontSize: 12, color: palette.inkMuted),
                      ),
                    ],
                  ],
                ),
                if (type.description != null && type.description!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    type.description!,
                    style: TextStyle(fontSize: 12, color: palette.inkFaint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: palette.divider),
                const SizedBox(height: AppSpacing.sm),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isDeleting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      TextButton.icon(
                        onPressed: () => _openCreateOrEditModal(existingType: type),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Chỉnh sửa', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: palette.accent),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextButton.icon(
                        onPressed: () => _deleteRoomType(type),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: palette.error),
                      ),
                    ],
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
