import 'package:flutter/material.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/booking_repository.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';

/// Bottom sheet đổi phòng cho khách đang lưu trú (FE-ROLE-MATRIX §5.3)
class ChangeRoomSheet extends StatefulWidget {
  final String bookingId;
  final RoomModel currentRoom;
  final VoidCallback onSuccess;

  const ChangeRoomSheet({
    super.key,
    required this.bookingId,
    required this.currentRoom,
    required this.onSuccess,
  });

  static Future<void> show({
    required BuildContext context,
    required String bookingId,
    required RoomModel currentRoom,
    required VoidCallback onSuccess,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => ChangeRoomSheet(
        bookingId: bookingId,
        currentRoom: currentRoom,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ChangeRoomSheet> createState() => _ChangeRoomSheetState();
}

class _ChangeRoomSheetState extends State<ChangeRoomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedNewRoomId;
  bool _keepPrice = true;
  bool _isSubmitting = false;

  List<RoomModel> _availableRooms = [];
  bool _isLoadingRooms = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableRooms();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableRooms() async {
    try {
      final roomRepo = sl<RoomRepository>();
      if (!roomRepo.isInitialized) {
        await roomRepo.fetchRooms();
      }
      final avail = roomRepo.rooms
          .where((r) => r.status.code == 'AVAILABLE' && r.id != widget.currentRoom.id)
          .toList();
      if (mounted) {
        setState(() {
          _availableRooms = avail;
          _isLoadingRooms = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRooms = false);
      }
    }
  }

  Future<void> _submitChangeRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNewRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng chọn phòng trống mới để chuyển khách sang'),
          backgroundColor: context.palette.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final bookingRepo = sl<BookingRepository>();
      await bookingRepo.changeRoom(
        widget.bookingId,
        newRoomId: _selectedNewRoomId!,
        reason: _reasonController.text.trim(),
        keepPrice: _keepPrice,
      );

      if (!mounted) return;
      final newRoom = _availableRooms.firstWhere(
        (r) => r.id == _selectedNewRoomId,
        orElse: () => widget.currentRoom,
      );

      Navigator.of(context).pop();
      widget.onSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển khách sang phòng ${newRoom.roomNumber} thành công'),
          backgroundColor: context.palette.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi đổi phòng: ${e.toString()}'),
          backgroundColor: context.palette.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AppBottomSheet(
      title: 'Đổi Phòng Cho Khách',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thông tin phòng hiện tại
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.canvas,
                borderRadius: BorderRadius.circular(AppRadius.field),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.statusOccupied.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.meeting_room, color: palette.statusOccupiedInk, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng hiện tại: ${widget.currentRoom.roomNumber}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: palette.ink),
                        ),
                        Text(
                          'Hạng: ${widget.currentRoom.roomTypeName ?? "Tiêu chuẩn"} • Tầng ${widget.currentRoom.floor}',
                          style: TextStyle(fontSize: 12, color: palette.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Dropdown chọn phòng mới
            Text(
              'Chọn phòng mới (*)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
            ),
            const SizedBox(height: 6),
            if (_isLoadingRooms)
              const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
            else if (_availableRooms.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.statusReserved.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Text(
                  'Không có phòng trống nào sẵn sàng để đổi.',
                  style: TextStyle(color: palette.statusReservedInk, fontSize: 13),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedNewRoomId,
                hint: Text('Chọn phòng trống...', style: TextStyle(color: palette.inkMuted, fontSize: 13)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
                ),
                items: _availableRooms.map((room) {
                  return DropdownMenuItem<String>(
                    value: room.id,
                    child: Text(
                      'Phòng ${room.roomNumber} - Hạng ${room.roomTypeName ?? "Tiêu chuẩn"} (Tầng ${room.floor})',
                      style: TextStyle(fontSize: 13, color: palette.ink),
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedNewRoomId = val),
              ),
            const SizedBox(height: AppSpacing.lg),

            // Lý do đổi phòng
            Text(
              'Lý do đổi phòng (*)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Điều hòa phòng cũ gặp trục trặc tiếng ồn',
                hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Vui lòng nhập lý do đổi phòng';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Switch giữ nguyên giá
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Giữ nguyên đơn giá phòng cũ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.ink),
              ),
              subtitle: Text(
                _keepPrice
                    ? 'Khách không phải bù thêm tiền chênh lệch hạng phòng mới'
                    : 'Hệ thống tự động tính lại tiền theo giá hạng phòng mới',
                style: TextStyle(fontSize: 11, color: palette.inkMuted),
              ),
              value: _keepPrice,
              activeThumbColor: palette.accent,
              onChanged: (val) => setState(() => _keepPrice = val),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Nút Lưu & Đổi phòng
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitChangeRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Xác Nhận Đổi Phòng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
