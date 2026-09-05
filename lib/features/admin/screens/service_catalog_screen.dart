import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/service_model.dart';
import '../../../shared/repositories/service_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_display.dart';

/// Quản trị danh mục bảng giá dịch vụ khách sạn (A2 - Dành cho ADMIN)
class ServiceCatalogScreen extends StatefulWidget {
  final ServiceRepository? serviceRepository;
  const ServiceCatalogScreen({super.key, this.serviceRepository});

  @override
  State<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends State<ServiceCatalogScreen> {
  late final ServiceRepository _serviceRepo = widget.serviceRepository ?? sl<ServiceRepository>();

  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices({bool isSilent = false}) async {
    if (!isSilent && _services.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final list = await _serviceRepo.fetchServices(forceRefresh: true);
      if (mounted) {
        setState(() {
          _services = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showAddOrEditDialog([ServiceModel? existing]) {
    final palette = context.palette;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    AppBottomSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return AppBottomSheet(
            title: existing == null ? 'Thêm Dịch Vụ Mới' : 'Sửa Dịch Vụ',
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên dịch vụ (*)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Nhập tên dịch vụ' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Đơn giá (VNĐ) (*)',
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Đơn giá hợp lệ > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Mô tả chi tiết',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: imgCtrl,
                    decoration: InputDecoration(
                      labelText: 'Link ảnh đại diện (URL)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSaving = true);
                              try {
                                final payload = {
                                  'name': nameCtrl.text.trim(),
                                  'price': num.parse(priceCtrl.text),
                                  if (descCtrl.text.trim().isNotEmpty) 'description': descCtrl.text.trim(),
                                  if (imgCtrl.text.trim().isNotEmpty) 'imageUrl': imgCtrl.text.trim(),
                                };
                                if (existing == null) {
                                  final created = await _serviceRepo.createService(payload);
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      _services.insert(0, created);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Đã thêm dịch vụ thành công'),
                                        backgroundColor: palette.success,
                                      ),
                                    );
                                  }
                                } else {
                                  final updated = await _serviceRepo.updateService(existing.id, payload);
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                    setState(() {
                                      final idx = _services.indexWhere((s) => s.id == existing.id);
                                      if (idx != -1) {
                                        _services[idx] = updated;
                                      }
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Đã cập nhật dịch vụ'),
                                        backgroundColor: palette.success,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                setSheetState(() => isSaving = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Thao tác thất bại: ${e.toString()}'), backgroundColor: palette.error),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              existing == null ? 'Lưu Dịch Vụ Mới' : 'Cập Nhật Thay Đổi',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa dịch vụ "${service.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.palette.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _deletingIds.add(service.id));
      try {
        await _serviceRepo.deleteService(service.id);
        if (mounted) {
          setState(() {
            _deletingIds.remove(service.id);
            _services.removeWhere((s) => s.id == service.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa dịch vụ "${service.name}"'), backgroundColor: context.palette.success),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _deletingIds.remove(service.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xóa thất bại: ${e.toString()}'), backgroundColor: context.palette.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        backgroundColor: palette.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: AppErrorView(
                    error: _errorMessage!,
                    onRetry: _fetchServices,
                  ),
                )
              : _services.isEmpty
                  ? const AppEmptyState(
                      title: 'Chưa có dịch vụ nào',
                      description: 'Bấm nút (+) góc dưới để tạo mục dịch vụ mới.',
                    )
                  : RefreshIndicator(
                      color: palette.accent,
                      onRefresh: _fetchServices,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        itemCount: _services.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                                  child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: service.imageUrl!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 56,
                                            height: 56,
                                            color: palette.canvas,
                                            child: Icon(Icons.room_service_outlined, color: palette.inkMuted),
                                          ),
                                        )
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          color: palette.canvas,
                                          child: Icon(Icons.room_service_outlined, color: palette.inkMuted),
                                        ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: palette.ink),
                                      ),
                                      if (service.description != null && service.description!.isNotEmpty)
                                        Text(
                                          service.description!,
                                          style: TextStyle(fontSize: 12, color: palette.inkMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.formatCurrency(service.price),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.accent),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: palette.accent, size: 20),
                                  onPressed: () => _showAddOrEditDialog(service),
                                ),
                                _deletingIds.contains(service.id)
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.delete_outline, color: palette.error, size: 20),
                                        onPressed: () => _deleteService(service),
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
