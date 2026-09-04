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

class AddServiceSheet extends StatefulWidget {
  final String bookingId;
  final String? roomNumber;
  final VoidCallback? onServiceAdded;

  const AddServiceSheet({
    super.key,
    required this.bookingId,
    this.roomNumber,
    this.onServiceAdded,
  });

  static Future<void> show({
    required BuildContext context,
    required String bookingId,
    String? roomNumber,
    VoidCallback? onServiceAdded,
  }) async {
    await AppBottomSheet.show(
      context: context,
      builder: (ctx) => AddServiceSheet(
        bookingId: bookingId,
        roomNumber: roomNumber,
        onServiceAdded: onServiceAdded,
      ),
    );
  }

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  List<ServiceModel> _services = [];
  bool _isLoadingServices = true;
  ServiceModel? _selectedService;
  final _customNameController = TextEditingController();
  final _priceController = TextEditingController();
  int _quantity = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final list = await sl<ServiceRepository>().fetchServices();
      if (mounted) {
        setState(() {
          _services = list;
          _isLoadingServices = false;
          if (_services.isNotEmpty) {
            _onServiceSelected(_services.first);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingServices = false);
      }
    }
  }

  void _onServiceSelected(ServiceModel service) {
    setState(() {
      _selectedService = service;
      _customNameController.text = service.name;
      _priceController.text = Formatters.formatCurrency(service.unitPrice);
    });
  }

  num get _unitPrice {
    return Formatters.parseCurrency(_priceController.text) ?? 0;
  }

  num get _totalPrice => _unitPrice * _quantity;

  Future<void> _submit() async {
    final name = _customNameController.text.trim();
    final price = _unitPrice;

    if (name.isEmpty) {
      AppNotification.showWarning(context, 'Vui lòng nhập tên dịch vụ');
      return;
    }
    if (price <= 0) {
      AppNotification.showWarning(context, 'Vui lòng nhập đơn giá hợp lệ');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await sl<BookingRepository>().addService(
        widget.bookingId,
        serviceName: name,
        unitPrice: price,
        quantity: _quantity,
      );

      if (mounted) {
        Navigator.pop(context);
        AppNotification.showSuccess(
          context,
          'Đã thêm dịch vụ "$name" (x$_quantity) thành công!',
        );
        widget.onServiceAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppNotification.showError(
          context,
          e,
          title: 'Thêm dịch vụ thất bại',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final roomInfo = widget.roomNumber != null ? ' (Phòng ${widget.roomNumber})' : '';

    return AppBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
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
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Quick Pick Services from BE (GET /services)
            if (_isLoadingServices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_services.isNotEmpty) ...[
              Text(
                'Danh mục có sẵn:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.inkMuted),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _services.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final s = _services[i];
                    final isSel = _selectedService?.id == s.id;
                    return GestureDetector(
                      onTap: () => _onServiceSelected(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? palette.accent : palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: isSel ? palette.accent : palette.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : palette.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Service Name Input
            Text(
              'Tên dịch vụ:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customNameController,
              style: TextStyle(color: palette.ink, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: palette.surfaceMuted,
                hintText: 'VD: Nước suối, Giặt ủi, Nước ngọt...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Price & Quantity Row
            Row(
              children: [
                // Price Input
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn giá (VND):',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: TextStyle(color: palette.accent, fontWeight: FontWeight.w700, fontSize: 15),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.surfaceMuted,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Quantity Stepper
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số lượng:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: palette.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          border: Border.all(color: palette.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text(
                              '$_quantity',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.ink),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Total banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thành tiền:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
                  ),
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
            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            PressableScale(
              onTap: _isSubmitting ? null : _submit,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  boxShadow: AppShadows.goldGlow,
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ghi Nhận Dịch Vụ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
