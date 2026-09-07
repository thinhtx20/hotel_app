import '../../../core/utils/vietnamese_search_helper.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/service_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/service_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/motion/pressable_scale.dart';

/// Lớp đại diện cho một dịch vụ được chọn ghi nhận vào hóa đơn
class _SelectedServiceItem {
  final String? serviceId;
  final String name;
  num unitPrice;
  int quantity;
  final bool isCustom;

  _SelectedServiceItem({
    this.serviceId,
    required this.name,
    required this.unitPrice,
    this.quantity = 1,
    this.isCustom = false,
  });

  num get subtotal => unitPrice * quantity;
}

class AddServiceSheet extends StatefulWidget {
  final String bookingId;
  final String? roomNumber;
  final VoidCallback? onServiceAdded;
  final ServiceRepository? serviceRepository;
  final BookingRepository? bookingRepository;

  const AddServiceSheet({
    super.key,
    required this.bookingId,
    this.roomNumber,
    this.onServiceAdded,
    this.serviceRepository,
    this.bookingRepository,
  });

  static Future<void> show({
    required BuildContext context,
    required String bookingId,
    String? roomNumber,
    VoidCallback? onServiceAdded,
    ServiceRepository? serviceRepository,
    BookingRepository? bookingRepository,
  }) async {
    await AppBottomSheet.show(
      context: context,
      builder: (ctx) => AddServiceSheet(
        bookingId: bookingId,
        roomNumber: roomNumber,
        onServiceAdded: onServiceAdded,
        serviceRepository: serviceRepository,
        bookingRepository: bookingRepository,
      ),
    );
  }

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  ServiceRepository get _serviceRepo => widget.serviceRepository ?? sl<ServiceRepository>();
  BookingRepository get _bookingRepo => widget.bookingRepository ?? sl<BookingRepository>();

  List<ServiceModel> _services = [];
  bool _isLoadingServices = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<_SelectedServiceItem> _selectedItems = [];

  // Form thêm dịch vụ ngoài danh mục
  bool _showCustomForm = false;
  final _customNameController = TextEditingController();
  final _customPriceController = TextEditingController();
  int _customQuantity = 1;

  bool _isSubmitting = false;
  String _submittingProgressText = '';

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final list = await _serviceRepo.fetchServices();
      if (mounted) {
        setState(() {
          _services = list;
          _isLoadingServices = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  bool _isServiceSelected(String serviceId) {
    return _selectedItems.any((item) => item.serviceId == serviceId);
  }

  int _getServiceQuantity(String serviceId) {
    final found = _selectedItems.where((item) => item.serviceId == serviceId);
    return found.isEmpty ? 0 : found.first.quantity;
  }

  void _toggleCatalogService(ServiceModel service) {
    setState(() {
      final idx = _selectedItems.indexWhere((item) => item.serviceId == service.id);
      if (idx != -1) {
        // Đã có -> Gỡ bỏ khỏi danh sách đã chọn
        _selectedItems.removeAt(idx);
      } else {
        // Chưa có -> Thêm với số lượng 1
        _selectedItems.add(
          _SelectedServiceItem(
            serviceId: service.id,
            name: service.name,
            unitPrice: service.unitPrice,
            quantity: 1,
            isCustom: false,
          ),
        );
      }
    });
  }

  void _updateItemQuantity(_SelectedServiceItem item, int delta) {
    setState(() {
      final next = item.quantity + delta;
      if (next <= 0) {
        _selectedItems.remove(item);
      } else {
        item.quantity = next;
      }
    });
  }

  void _removeItem(_SelectedServiceItem item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  void _addCustomItem() {
    final name = _customNameController.text.trim();
    final price = Formatters.parseCurrency(_customPriceController.text) ?? 0;

    if (name.isEmpty) {
      AppNotification.showWarning(context, 'Vui lòng nhập tên dịch vụ tùy chỉnh');
      return;
    }
    if (price <= 0) {
      AppNotification.showWarning(context, 'Vui lòng nhập đơn giá hợp lệ');
      return;
    }

    setState(() {
      _selectedItems.add(
        _SelectedServiceItem(
          name: name,
          unitPrice: price,
          quantity: _customQuantity,
          isCustom: true,
        ),
      );
      _customNameController.clear();
      _customPriceController.clear();
      _customQuantity = 1;
      _showCustomForm = false;
    });

    FocusScope.of(context).unfocus();
  }

  num get _totalPrice {
    return _selectedItems.fold<num>(0, (sum, item) => sum + item.subtotal);
  }

  int get _totalProductQuantity {
    return _selectedItems.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<void> _submit() async {
    // Tự động thêm dịch vụ ngoài danh mục nếu người dùng đã nhập tên & giá hợp lệ
    final customName = _customNameController.text.trim();
    final customPrice = Formatters.parseCurrency(_customPriceController.text) ?? 0;
    if (customName.isNotEmpty && customPrice > 0) {
      _selectedItems.add(
        _SelectedServiceItem(
          name: customName,
          unitPrice: customPrice,
          quantity: _customQuantity,
          isCustom: true,
        ),
      );
      _customNameController.clear();
      _customPriceController.clear();
      _customQuantity = 1;
      _showCustomForm = false;
    }

    if (_selectedItems.isEmpty) {
      AppNotification.showWarning(context, 'Vui lòng chọn hoặc thêm ít nhất một dịch vụ');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingProgressText = 'Đang khởi tạo...';
    });

    try {
      final itemsToSubmit = _selectedItems
          .map((item) => (
                serviceName: item.name,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
              ))
          .toList();

      await _bookingRepo.addMultipleServices(
        widget.bookingId,
        itemsToSubmit,
        onProgress: (current, total, serviceName) {
          if (mounted) {
            setState(() {
              _submittingProgressText = 'Đang lưu ($current/$total): $serviceName...';
            });
          }
        },
      );

      if (mounted) {
        Navigator.pop(context);
        final totalItems = _selectedItems.length;
        final totalQty = _totalProductQuantity;
        AppNotification.showSuccess(
          context,
          'Đã thêm $totalItems dịch vụ ($totalQty món) vào đơn thành công!',
        );
        widget.onServiceAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppNotification.showError(
          context,
          e,
          title: 'Ghi nhận dịch vụ thất bại',
        );
      }
    }
  }

  IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('giặt') || lower.contains('ủi') || lower.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    }
    if (lower.contains('nước') ||
        lower.contains('bar') ||
        lower.contains('uống') ||
        lower.contains('bia') ||
        lower.contains('rượu')) {
      return Icons.local_bar_rounded;
    }
    if (lower.contains('ăn') ||
        lower.contains('sáng') ||
        lower.contains('buffet') ||
        lower.contains('mì') ||
        lower.contains('cơm')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('xe') || lower.contains('đưa đón') || lower.contains('tiễn')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('spa') || lower.contains('massage')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('dọn') || lower.contains('vệ sinh')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.room_service_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(palette),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPresetServicesSection(palette),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSelectedItemsSection(palette),
                    const SizedBox(height: AppSpacing.md),
                    _buildCustomServiceSection(palette),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildBottomStickyFooter(palette),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    final roomInfo = widget.roomNumber != null ? ' (Phòng ${widget.roomNumber})' : '';

    return Row(
      children: [
        Container(
          width: 40,
          height: 44,
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.room_service_rounded, color: palette.accent, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm Dịch Vụ Phát Sinh',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              Text(
                'Ghi nhận chi phí vào đơn đặt$roomInfo',
                style: TextStyle(fontSize: 12, color: palette.inkMuted),
              ),
            ],
          ),
        ),
        if (_selectedItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_selectedItems.length} dịch vụ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: palette.accent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPresetServicesSection(AppPalette palette) {
    if (_isLoadingServices) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: palette.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hệ thống chưa có dịch vụ mẫu. Hãy nhập dịch vụ tùy chỉnh bên dưới.',
                style: TextStyle(fontSize: 12, color: palette.inkMuted),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? _services
        : _services
            .where((s) => VietnameseSearchHelper.matches(s.name, _searchQuery))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Danh mục có sẵn (chọn nhiều):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Chạm để chọn / bỏ',
              style: TextStyle(fontSize: 11, color: palette.inkMuted),
            ),
          ],
        ),
        if (_services.length > 4) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(fontSize: 12, color: palette.ink),
              decoration: InputDecoration(
                filled: true,
                fillColor: palette.surfaceMuted,
                hintText: 'Tìm nhanh dịch vụ...',
                prefixIcon: Icon(Icons.search, size: 16, color: palette.inkMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  borderSide: BorderSide(color: palette.border),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'Không tìm thấy dịch vụ phù hợp',
                    style: TextStyle(fontSize: 12, color: palette.inkMuted),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final s = filtered[i];
                    final isSel = _isServiceSelected(s.id);
                    final qty = _getServiceQuantity(s.id);

                    return GestureDetector(
                      onTap: () => _toggleCatalogService(s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? palette.accent : palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isSel ? palette.accent : palette.border,
                            width: isSel ? 1.5 : 1,
                          ),
                          boxShadow: isSel ? AppShadows.goldGlow : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSel ? Icons.check_circle_rounded : _getServiceIcon(s.name),
                              size: 15,
                              color: isSel ? Colors.white : palette.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isSel && qty > 1 ? '${s.name} (x$qty)' : s.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : palette.ink,
                              ),
                            ),
                            if (!isSel) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• ${Formatters.formatCurrency(s.unitPrice)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: palette.inkMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsSection(AppPalette palette) {
    if (_selectedItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: palette.surfaceMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: palette.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.touch_app_outlined, size: 28, color: palette.accent.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(
              'Chưa có dịch vụ nào được chọn',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Chạm vào danh mục ở trên hoặc tự thêm dịch vụ bên dưới',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: palette.inkMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Dịch vụ đã chọn (${_selectedItems.length}):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedItems.clear()),
              child: Text(
                'Xóa tất cả',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: palette.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final item = _selectedItems[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dòng 1: Tên dịch vụ, huy hiệu tùy chỉnh, nút xóa
                  Row(
                    children: [
                      Icon(_getServiceIcon(item.name), size: 16, color: palette.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.isCustom) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: palette.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ngoài danh mục',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: palette.accent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeItem(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close_rounded, size: 16, color: palette.inkMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Dòng 2: Đơn giá, bộ tăng giảm số lượng, thành tiền
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatCurrency(item.unitPrice),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.inkMuted,
                        ),
                      ),
                      // Stepper [-] qty [+]
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 13),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                              onPressed: () => _updateItemQuantity(item, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${item.quantity}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 13),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 32),
                              onPressed: () => _updateItemQuantity(item, 1),
                            ),
                          ],
                        ),
                      ),
                      // Thành tiền
                      Text(
                        Formatters.formatCurrency(item.subtotal),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomServiceSection(AppPalette palette) {
    if (!_showCustomForm) {
      return Center(
        child: TextButton.icon(
          onPressed: () => setState(() => _showCustomForm = true),
          icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: palette.accent),
          label: Text(
            'Thêm dịch vụ ngoài danh mục / tùy chỉnh',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.accent,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: palette.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Dịch vụ ngoài danh mục:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: palette.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _showCustomForm = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customNameController,
            style: TextStyle(color: palette.ink, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.surface,
              hintText: 'VD: Nước ngọt, Đền bù vỡ ly, Phụ thu check-in sớm...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _customPriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [CurrencyInputFormatter()],
                  style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: palette.surface,
                    hintText: 'Đơn giá (VND)',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: palette.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 40),
                      onPressed: _customQuantity > 1 ? () => setState(() => _customQuantity--) : null,
                    ),
                    Text(
                      '$_customQuantity',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 14),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 40),
                      onPressed: () => setState(() => _customQuantity++),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
                child: const Text('+ Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStickyFooter(AppPalette palette) {
    final hasItems = _selectedItems.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Khối tổng kết thành tiền
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: palette.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng thanh toán:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
                    ),
                    Text(
                      hasItems
                          ? '${_selectedItems.length} dịch vụ • $_totalProductQuantity sản phẩm'
                          : 'Chưa có dịch vụ nào',
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.formatCurrency(_totalPrice),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Nút Ghi nhận dịch vụ
        PressableScale(
          onTap: (_isSubmitting || !hasItems) ? null : _submit,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: hasItems ? AppGradients.gold : null,
              color: hasItems ? null : palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: hasItems ? AppShadows.goldGlow : null,
              border: hasItems ? null : Border.all(color: palette.border),
            ),
            alignment: Alignment.center,
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _submittingProgressText.isNotEmpty
                              ? _submittingProgressText
                              : 'Đang lưu dịch vụ...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_shopping_cart_rounded,
                        color: hasItems ? Colors.white : palette.inkMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasItems
                            ? 'Ghi Nhận ${_selectedItems.length} Dịch Vụ (${Formatters.formatCurrency(_totalPrice)})'
                            : 'Vui lòng chọn dịch vụ',
                        style: TextStyle(
                          color: hasItems ? Colors.white : palette.inkMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
