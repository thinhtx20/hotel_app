import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/repositories/user_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_error_display.dart';

/// Modal thủ tục Nhận phòng trực tiếp tại quầy cho khách vãng lai (Walk-in Check-in)
class WalkInCheckInModal extends StatefulWidget {
  final RoomModel? preselectedRoom;
  final VoidCallback? onSuccess;

  const WalkInCheckInModal({
    super.key,
    this.preselectedRoom,
    this.onSuccess,
  });

  static Future<BookingModel?> show({
    required BuildContext context,
    RoomModel? preselectedRoom,
    VoidCallback? onSuccess,
  }) {
    return AppBottomSheet.show<BookingModel>(
      context: context,
      builder: (ctx) => WalkInCheckInModal(
        preselectedRoom: preselectedRoom,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<WalkInCheckInModal> createState() => _WalkInCheckInModalState();
}

class _WalkInCheckInModalState extends State<WalkInCheckInModal> {
  final _formKey = GlobalKey<FormState>();

  // Room
  RoomModel? _selectedRoom;
  List<RoomModel> _availableRooms = [];
  bool _isLoadingRooms = false;

  // Customer Mode: 0 = Khách vãng lai mới, 1 = Tìm khách trong hệ thống
  int _customerMode = 0;
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();

  // Existing Customer Search
  final _customerSearchController = TextEditingController();
  List<UserModel> _searchResults = [];
  UserModel? _selectedCustomer;
  bool _isSearchingCustomers = false;
  Timer? _searchDebounce;

  // Stay Dates
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  int _guestCount = 1;

  // Payment & Deposit
  final _depositController = TextEditingController(text: '0');
  String _paymentMethod = 'CASH';
  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.preselectedRoom;

    final now = DateTime.now();
    _checkInDate = now;
    _checkOutDate = DateTime(now.year, now.month, now.day + 1, 12, 0);

    if (_selectedRoom == null) {
      _loadAvailableRooms();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _customerSearchController.dispose();
    _depositController.dispose();
    _notesController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailableRooms() async {
    setState(() => _isLoadingRooms = true);
    try {
      final roomRepo = sl<RoomRepository>();
      final rooms = await roomRepo.fetchAllRooms(status: RoomStatus.available);
      if (!mounted) return;
      final available = rooms.toList()
        ..sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
      setState(() {
        _availableRooms = available;
        if (_availableRooms.isNotEmpty && _selectedRoom == null) {
          _selectedRoom = _availableRooms.first;
        }
        _isLoadingRooms = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  void _onCustomerSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearchingCustomers = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _isSearchingCustomers = true);
      try {
        final userRepo = sl<UserRepository>();
        final res = await userRepo.fetchAllUsers(role: 'CUSTOMER', search: trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = res;
          _isSearchingCustomers = false;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _isSearchingCustomers = false);
        }
      }
    });
  }

  int get _nightsCount {
    final diff = _checkOutDate.difference(_checkInDate).inDays;
    return diff > 0 ? diff : 1;
  }

  num get _estimatedRoomTotal {
    final pricePerNight = _selectedRoom?.pricePerNight ?? 0;
    return pricePerNight * _nightsCount;
  }

  Future<void> _pickCheckOutDate() async {
    final now = DateTime.now();
    final minDate = _checkInDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate.isAfter(minDate) ? _checkOutDate : minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'CHỌN NGÀY TRẢ PHÒNG DỰ KIẾN',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );
    if (picked != null && mounted) {
      setState(() {
        _checkOutDate = DateTime(picked.year, picked.month, picked.day, 12, 0);
      });
    }
  }

  void _addNights(int count) {
    setState(() {
      _checkOutDate = _checkInDate.add(Duration(days: count));
      _checkOutDate = DateTime(_checkOutDate.year, _checkOutDate.month, _checkOutDate.day, 12, 0);
    });
  }

  Future<void> _submitWalkIn() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoom == null) {
      AppNotification.showError(
        context,
        'Vui lòng chọn phòng trống để làm thủ tục nhận phòng',
        title: 'Chưa chọn phòng',
      );
      return;
    }

    if (_customerMode == 1 && _selectedCustomer == null) {
      AppNotification.showError(
        context,
        'Vui lòng chọn khách hàng từ danh sách tìm kiếm hoặc chuyển sang tab "Khách mới"',
        title: 'Chưa chọn khách hàng',
      );
      return;
    }

    final rawDeposit = _depositController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final deposit = num.tryParse(rawDeposit) ?? 0;

    setState(() => _isSubmitting = true);

    try {
      final bookingRepo = sl<BookingRepository>();

      final String? customerId = _customerMode == 1 ? _selectedCustomer?.id : null;
      final String customerName = _customerMode == 1
          ? (_selectedCustomer?.fullName ?? 'Khách vãng lai')
          : _fullNameController.text.trim();
      final String customerPhone = _customerMode == 1
          ? (_selectedCustomer?.phone ?? '')
          : _phoneController.text.trim();
      final String customerIdentity = _idCardController.text.trim();

      final booking = await bookingRepo.walkInCheckIn(
        roomId: _selectedRoom!.id,
        checkInDate: _checkInDate,
        checkOutDate: _checkOutDate,
        guestCount: _guestCount,
        depositAmount: deposit,
        paymentMethod: _paymentMethod,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerIdentity: customerIdentity,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      Navigator.of(context).pop(booking);

      AppNotification.showSuccess(
        context,
        'Đã nhận phòng ${_selectedRoom!.roomNumber} cho khách $customerName thành công!',
        title: 'Check-in thành công',
      );

      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotification.showError(
        context,
        ApiError.fromDynamic(e).displayMessage,
        title: 'Nhận phòng thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppBottomSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Form(
          key: _formKey,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRoomSection(palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildCustomerSection(palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildStayDurationSection(palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildPricingAndDepositSection(palette),
                      const SizedBox(height: AppSpacing.md),
                      _buildNotesField(palette),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(palette),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: palette.statusOccupied.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
          child: Icon(
            Icons.person_add_alt_1_rounded,
            color: palette.statusOccupied,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nhận Phòng Trực Tiếp',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Khách vãng lai (Walk-in) chưa đặt trước trên hệ thống',
                style: TextStyle(
                  fontSize: 12,
                  color: palette.inkMuted,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded, color: palette.inkMuted),
          tooltip: 'Đóng',
        ),
      ],
    );
  }

  Widget _buildRoomSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room_outlined, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Phòng lưu trú:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: palette.ink,
                ),
              ),
              const Spacer(),
              if (_selectedRoom != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.statusAvailable.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'Phòng trống',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.statusAvailableInk,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLoadingRooms)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent),
                ),
              ),
            )
          else if (widget.preselectedRoom != null)
            _buildSelectedRoomCard(widget.preselectedRoom!, palette)
          else if (_availableRooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: palette.error, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Hiện tại không có phòng nào ở trạng thái Sẵn sàng để nhận phòng.',
                      style: TextStyle(fontSize: 12, color: palette.errorInk),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<RoomModel>(
              initialValue: _selectedRoom,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  borderSide: BorderSide(color: palette.divider),
                ),
              ),
              items: _availableRooms.map((r) {
                return DropdownMenuItem<RoomModel>(
                  value: r,
                  child: Text(
                    'Phòng ${r.roomNumber} (Tầng ${r.floor} • ${r.roomTypeName ?? "Tiêu Chuẩn"} • ${Formatters.formatCurrency(r.pricePerNight)}/đêm)',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRoom = val);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedRoomCard(RoomModel room, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.statusAvailable.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Text(
              room.roomNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: palette.statusAvailableInk,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tầng ${room.floor} • Hạng ${room.roomTypeName ?? "Tiêu Chuẩn"}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                Text(
                  '${Formatters.formatCurrency(room.pricePerNight)}/đêm',
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Thông tin khách hàng:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Segmented Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: palette.canvas,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: palette.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCustomerSegment(
                    index: 0,
                    label: 'Khách mới / Vãng lai',
                    icon: Icons.person_add_rounded,
                    palette: palette,
                  ),
                ),
                Expanded(
                  child: _buildCustomerSegment(
                    index: 1,
                    label: 'Khách quen (Hệ thống)',
                    icon: Icons.search_rounded,
                    palette: palette,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_customerMode == 0) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên khách *',
                hintText: 'VD: Nguyễn Văn Tuấn',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên khách' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại',
                      hintText: 'VD: 0912345678',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: _idCardController,
                    decoration: InputDecoration(
                      labelText: 'CCCD / Hộ chiếu',
                      hintText: 'VD: 001200000000',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_selectedCustomer != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: palette.accent,
                      child: Text(
                        _selectedCustomer!.fullName.isNotEmpty
                            ? _selectedCustomer!.fullName[0].toUpperCase()
                            : 'K',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCustomer!.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: palette.ink,
                            ),
                          ),
                          Text(
                            _selectedCustomer!.phone?.isNotEmpty == true
                                ? _selectedCustomer!.phone!
                                : _selectedCustomer!.email,
                            style: TextStyle(fontSize: 11, color: palette.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selectedCustomer = null),
                      tooltip: 'Bỏ chọn',
                    ),
                  ],
                ),
              )
            else ...[
              TextFormField(
                controller: _customerSearchController,
                decoration: InputDecoration(
                  labelText: 'Tìm khách hàng',
                  hintText: 'Nhập tên, số điện thoại hoặc email...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _isSearchingCustomers
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  ),
                ),
                onChanged: _onCustomerSearchChanged,
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: palette.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    border: Border.all(color: palette.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: palette.divider),
                    itemBuilder: (ctx, idx) {
                      final c = _searchResults[idx];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          c.phone ?? c.email,
                          style: TextStyle(fontSize: 11, color: palette.inkMuted),
                        ),
                        trailing: const Icon(Icons.check_circle_outline, size: 18),
                        onTap: () {
                          setState(() {
                            _selectedCustomer = c;
                            _searchResults = [];
                            _customerSearchController.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerSegment({
    required int index,
    required String label,
    required IconData icon,
    required AppPalette palette,
  }) {
    final isSelected = _customerMode == index;
    return GestureDetector(
      onTap: () => setState(() => _customerMode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? palette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? palette.accent : palette.inkMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? palette.accent : palette.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStayDurationSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Thời gian lưu trú & Số khách:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: palette.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    border: Border.all(color: palette.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhận phòng (Check-in)', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatDate(_checkInDate),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                      ),
                      Text(
                        'Hôm nay (Hiện tại)',
                        style: TextStyle(fontSize: 11, color: palette.success, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: _pickCheckOutDate,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: palette.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                      border: Border.all(color: palette.accent.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Trả phòng (Check-out)', style: TextStyle(fontSize: 11, color: palette.inkMuted)),
                            const Spacer(),
                            Icon(Icons.edit_calendar_rounded, size: 14, color: palette.accent),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatDate(_checkOutDate),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.ink),
                        ),
                        Text(
                          '$_nightsCount đêm lưu trú',
                          style: TextStyle(fontSize: 11, color: palette.accent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Quick nights chips
          Wrap(
            spacing: 6,
            children: [
              _buildQuickNightChip(1, '1 đêm', palette),
              _buildQuickNightChip(2, '2 đêm', palette),
              _buildQuickNightChip(3, '3 đêm', palette),
              _buildQuickNightChip(7, '1 tuần', palette),
            ],
          ),
          Divider(height: 24, color: palette.divider),
          // Guest count stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số lượng khách ở:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
              ),
              Container(
                decoration: BoxDecoration(
                  color: palette.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: palette.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: _guestCount > 1
                          ? () => setState(() => _guestCount--)
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$_guestCount khách',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: palette.ink),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: _guestCount < 10
                          ? () => setState(() => _guestCount++)
                          : null,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNightChip(int nights, String label, AppPalette palette) {
    final isSelected = _nightsCount == nights;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => _addNights(nights),
      visualDensity: VisualDensity.compact,
      selectedColor: palette.accent.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? palette.accent : palette.ink,
      ),
    );
  }

  Widget _buildPricingAndDepositSection(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, size: 18, color: palette.accent),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Tiền phòng & Đặt cọc / Thu trước:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: palette.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.canvas,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng tiền phòng dự kiến ($_nightsCount đêm):',
                  style: TextStyle(fontSize: 12, color: palette.inkMuted),
                ),
                Text(
                  Formatters.formatCurrency(_estimatedRoomTotal),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _depositController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Tiền cọc / thanh toán trước (VND)',
              hintText: '0',
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
              suffixText: 'đ',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Quick deposit buttons
          Wrap(
            spacing: 6,
            children: [
              ActionChip(
                label: const Text('0 đ', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(() => _depositController.text = '0'),
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                label: const Text('50% tiền phòng', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(
                  () => _depositController.text = (_estimatedRoomTotal * 0.5).toInt().toString(),
                ),
                visualDensity: VisualDensity.compact,
              ),
              ActionChip(
                label: const Text('Thu đủ 100%', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(
                  () => _depositController.text = _estimatedRoomTotal.toInt().toString(),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Payment method selector
          Row(
            children: [
              Text(
                'Hình thức:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.ink),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CASH', label: Text('Tiền mặt', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'TRANSFER', label: Text('Chuyển khoản', style: TextStyle(fontSize: 11))),
                    ButtonSegment(value: 'CARD', label: Text('Thẻ', style: TextStyle(fontSize: 11))),
                  ],
                  selected: {_paymentMethod},
                  onSelectionChanged: (s) => setState(() => _paymentMethod = s.first),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField(AppPalette palette) {
    return TextFormField(
      controller: _notesController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Ghi chú thêm (Tùy chọn)',
        hintText: 'VD: Nhận phòng sớm, khách cần thêm gối...',
        prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        ),
      ),
    );
  }

  Widget _buildBottomAction(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitWalkIn,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                _isSubmitting ? 'Đang Xử Lý...' : 'Xác Nhận & Nhận Phòng',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
