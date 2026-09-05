import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/service_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/service_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_empty_state.dart';

/// Tab Dịch Vụ Khách Sạn & Đặt dịch vụ phòng (FE-ROLE-MATRIX §5.5)
class ServiceOrderScreen extends StatefulWidget {
  const ServiceOrderScreen({super.key});

  @override
  State<ServiceOrderScreen> createState() => _ServiceOrderScreenState();
}

class _ServiceOrderScreenState extends State<ServiceOrderScreen> {
  List<ServiceModel> _services = [];
  BookingModel? _activeBooking;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Giỏ dịch vụ: Map<serviceId, quantity>
  final Map<String, int> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final serviceRepo = sl<ServiceRepository>();
      final bookingRepo = sl<BookingRepository>();

      final servicesFuture = serviceRepo.fetchServices(forceRefresh: true);
      final bookingsFuture = bookingRepo.fetchAllBookings();

      final results = await Future.wait([servicesFuture, bookingsFuture]);
      final servicesList = results[0] as List<ServiceModel>;
      final myBookings = results[1] as List<BookingModel>;

      // Tìm lượt lưu trú đang hoạt động
      BookingModel? checkedIn;
      try {
        checkedIn = myBookings.firstWhere(
          (b) => b.status.toUpperCase() == 'CHECKED_IN',
        );
      } catch (_) {
        checkedIn = null;
      }

      if (mounted) {
        setState(() {
          _services = servicesList;
          _activeBooking = checkedIn;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateQuantity(String serviceId, int delta) {
    setState(() {
      final current = _cart[serviceId] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _cart.remove(serviceId);
      } else {
        _cart[serviceId] = next;
      }
    });
  }

  num get _totalCartPrice {
    num total = 0;
    for (final entry in _cart.entries) {
      final s = _services.firstWhere((element) => element.id == entry.key);
      total += s.price * entry.value;
    }
    return total;
  }

  int get _totalCartItems {
    return _cart.values.fold(0, (sum, q) => sum + q);
  }

  Future<void> _submitOrder() async {
    if (_activeBooking == null || _cart.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final bookingRepo = sl<BookingRepository>();
      final items = _cart.entries.map((e) {
        final s = _services.firstWhere((elem) => elem.id == e.key);
        return {
          'serviceId': s.id,
          'name': s.name,
          'quantity': e.value,
          'price': s.price,
        };
      }).toList();

      await bookingRepo.requestService(_activeBooking!.id, items: items);

      if (!mounted) return;
      setState(() {
        _cart.clear();
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yêu cầu dịch vụ đã được gửi lên lễ tân! Tiền sẽ được tính khi trả phòng.',
          ),
          backgroundColor: context.palette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi yêu cầu: ${e.toString()}'),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Dịch Vụ Khách Sạn'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: palette.accent,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner trạng thái lưu trú
                    if (_activeBooking != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              palette.accent.withValues(alpha: 0.15),
                              palette.accent.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bạn đang ở Phòng ${_activeBooking!.roomNumber ?? ""}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: palette.ink,
                                    ),
                                  ),
                                  Text(
                                    'Chọn dịch vụ dưới đây để nhân viên mang lên tận phòng.',
                                    style: TextStyle(fontSize: 12, color: palette.inkMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: palette.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: palette.accent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Tham khảo dịch vụ khách sạn',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: palette.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Đặt phòng ngay để tận hưởng ẩm thực, minibar, giặt là cao cấp phục vụ tận phòng.',
                              style: TextStyle(fontSize: 12, color: palette.inkMuted),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => context.go('/customer'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: palette.accent),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                                ),
                                child: Text('Khám phá & Đặt phòng ngay', style: TextStyle(color: palette.accent, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Text(
                      'Danh Mục Dịch Vụ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.ink),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_services.isEmpty)
                      const AppEmptyState(
                        title: 'Chưa có dịch vụ',
                        description: 'Hiện tại khách sạn chưa đăng ký danh mục dịch vụ.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _services.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          final qty = _cart[service.id] ?? 0;

                          return AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ảnh dịch vụ
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                                  child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: service.imageUrl!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorWidget: (context, url, error) => Container(
                                            width: 72,
                                            height: 72,
                                            color: palette.canvas,
                                            child: Icon(Icons.room_service_outlined, color: palette.inkMuted),
                                          ),
                                        )
                                      : Container(
                                          width: 72,
                                          height: 72,
                                          color: palette.canvas,
                                          child: Icon(Icons.room_service_outlined, color: palette.inkMuted),
                                        ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                // Chi tiết
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: palette.ink,
                                        ),
                                      ),
                                      if (service.description != null && service.description!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          service.description!,
                                          style: TextStyle(fontSize: 12, color: palette.inkMuted),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        Formatters.formatCurrency(service.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: palette.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Bộ chọn số lượng (nếu đang ở)
                                if (_activeBooking != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (qty > 0) ...[
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 22),
                                          color: palette.inkMuted,
                                          onPressed: () => _updateQuantity(service.id, -1),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            '$qty',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: palette.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                      IconButton(
                                        icon: const Icon(Icons.add_circle, size: 24),
                                        color: palette.accent,
                                        onPressed: () => _updateQuantity(service.id, 1),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      bottomSheet: _activeBooking != null && _totalCartItems > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface,
                border: Border(top: BorderSide(color: palette.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_totalCartItems món đã chọn', style: TextStyle(fontSize: 12, color: palette.inkMuted)),
                        Text(
                          Formatters.formatCurrency(_totalCartPrice),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      label: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              'Gọi lên phòng ${_activeBooking!.roomNumber ?? ""}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
