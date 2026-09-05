import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/repositories/upload_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_error_display.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

/// Modal sheet chỉnh sửa phòng dành riêng cho ADMIN (PUT /api/v1/rooms/:id)
class EditRoomModal extends StatefulWidget {
  final RoomModel room;
  final RoomRepository? roomRepository;
  final VoidCallback? onSuccess;

  const EditRoomModal({
    super.key,
    required this.room,
    this.roomRepository,
    this.onSuccess,
  });

  /// Phương thức tĩnh mở nhanh sheet chỉnh sửa phòng
  static Future<bool?> show({
    required BuildContext context,
    required RoomModel room,
    RoomRepository? roomRepository,
    VoidCallback? onSuccess,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      builder: (ctx) => EditRoomModal(
        room: room,
        roomRepository: roomRepository,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<EditRoomModal> createState() => _EditRoomModalState();
}

class _EditRoomModalState extends State<EditRoomModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _roomNumberController;
  late final TextEditingController _floorController;
  late final TextEditingController _priceController;
  late final TextEditingController _sizeController;
  late final TextEditingController _capacityAdultsController;
  late final TextEditingController _capacityChildrenController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  final TextEditingController _customAmenityController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  late final RoomRepository _roomRepo = widget.roomRepository ??
      (sl.isRegistered<RoomRepository>()
          ? sl<RoomRepository>()
          : RoomRepository());

  String? _selectedRoomTypeId;
  late RoomStatus _selectedStatus;
  late List<String> _selectedAmenities;
  late List<String> _images;

  bool _isLoadingTypes = false;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _defaultAmenities = const [
    'Wifi tốc độ cao',
    'Điều hòa 2 chiều',
    'Ban công ngắm cảnh',
    'Bồn tắm nằm',
    'Tủ lạnh minibar',
    'Tivi 4K Smart',
    'Ăn sáng buffet miễn phí',
    'Hồ bơi riêng',
    'Két sắt an toàn',
    'Máy sấy tóc',
    'Bàn làm việc',
    'Dịch vụ dọn phòng 24/7',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.room;
    _roomNumberController = TextEditingController(text: r.roomNumber);
    _floorController = TextEditingController(text: '${r.floor}');
    _priceController = TextEditingController(
      text: Formatters.formatNumber(r.pricePerNight.toInt()),
    );
    _sizeController = TextEditingController(
      text: r.sizeSqM != null ? '${r.sizeSqM}' : '',
    );
    _capacityAdultsController = TextEditingController(
      text: '${r.capacityAdults ?? 2}',
    );
    _capacityChildrenController = TextEditingController(
      text: '${r.capacityChildren ?? 1}',
    );
    _descriptionController = TextEditingController(text: r.description ?? '');
    _notesController = TextEditingController(text: r.notes ?? '');

    _selectedRoomTypeId = r.roomTypeId;
    _selectedStatus = r.status;
    _selectedAmenities = List<String>.from(r.amenities);
    _images = List<String>.from(r.images);

    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _isLoadingTypes = true);
    try {
      await _roomRepo.fetchRoomTypes();
      if (mounted) {
        setState(() {
          _isLoadingTypes = false;
          // Nếu roomTypeId chưa có nhưng có tên hoặc code thì khớp tự động
          if ((_selectedRoomTypeId == null || _selectedRoomTypeId!.isEmpty) &&
              _roomRepo.roomTypes.isNotEmpty) {
            final match = _roomRepo.roomTypes.firstWhere(
              (t) =>
                  t.id == widget.room.roomTypeId ||
                  t.name == widget.room.roomTypeName ||
                  t.code == widget.room.roomTypeCode,
              orElse: () => _roomRepo.roomTypes.first,
            );
            _selectedRoomTypeId = match.id;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _capacityAdultsController.dispose();
    _capacityChildrenController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _customAmenityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isEmpty) return;

      setState(() => _isUploadingImages = true);
      final paths = pickedFiles.map((x) => x.path).toList();

      UploadRepository? uploadRepo;
      if (sl.isRegistered<UploadRepository>()) {
        uploadRepo = sl<UploadRepository>();
      } else {
        uploadRepo = UploadRepository();
      }

      final urls = await uploadRepo.uploadRoomImages(
        paths,
        roomId: widget.room.id,
        roomTypeId: _selectedRoomTypeId,
      );

      if (mounted) {
        setState(() {
          _images.addAll(urls);
          _isUploadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImages = false);
        AppNotification.showError(context, e, title: 'Tải ảnh lên thất bại');
      }
    }
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      AppNotification.showWarning(context, 'Đường dẫn ảnh phải bắt đầu bằng http:// hoặc https://');
      return;
    }
    setState(() {
      if (!_images.contains(url)) {
        _images.add(url);
      }
      _imageUrlController.clear();
    });
  }

  void _addCustomAmenity() {
    final name = _customAmenityController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_selectedAmenities.contains(name)) {
        _selectedAmenities.add(name);
      }
      _customAmenityController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final rawPrice = Formatters.parseCurrency(_priceController.text) ??
        double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        widget.room.pricePerNight;

    final floor = int.tryParse(_floorController.text.trim()) ?? widget.room.floor;
    final size = double.tryParse(_sizeController.text.trim());
    final adults = int.tryParse(_capacityAdultsController.text.trim());
    final children = int.tryParse(_capacityChildrenController.text.trim());
    final desc = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    final payload = <String, dynamic>{
      'roomNumber': _roomNumberController.text.trim(),
      'floor': floor,
      if (_selectedRoomTypeId != null && _selectedRoomTypeId!.isNotEmpty)
        'roomTypeId': _selectedRoomTypeId,
      'status': _selectedStatus.code,
      'pricePerNight': rawPrice,
      if (size != null && size > 0) 'sizeSqM': size,
      if (adults != null && adults > 0) 'capacityAdults': adults,
      if (children != null && children >= 0) 'capacityChildren': children,
      if (desc.isNotEmpty) 'description': desc,
      if (notes.isNotEmpty) 'notes': notes,
      if (_selectedAmenities.isNotEmpty) 'amenities': _selectedAmenities,
      if (_images.isNotEmpty) ...{
        'image': _images.first,
        'images': _images,
      },
    };

    try {
      await _roomRepo.updateRoom(widget.room.id, payload);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      widget.onSuccess?.call();

      AppNotification.showSuccess(
        context,
        'Đã cập nhật phòng ${_roomNumberController.text.trim()} thành công!',
        title: 'Thành công (PUT /api/v1/rooms/:id)',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppNotification.showError(
        context,
        e,
        title: 'Cập nhật phòng thất bại',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return AppBottomSheet(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: palette.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.xs),
                              ),
                              child: Text(
                                'QUẢN TRỊ VIÊN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.accent,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'PUT /api/v1/rooms/:id',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.inkFaint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sửa Phòng ${widget.room.roomNumber}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: palette.inkMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: palette.divider, height: 1),
              const SizedBox(height: AppSpacing.lg),

              // 1. Số phòng & Tầng
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _roomNumberController,
                      label: 'Số phòng *',
                      hint: 'VD: 101, 202',
                      prefixIcon: Icons.meeting_room_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Số phòng là bắt buộc';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _floorController,
                      label: 'Tầng *',
                      hint: '1',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.layers_outlined,
                      validator: (val) {
                        final parsed = int.tryParse(val?.trim() ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Tầng >= 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Hạng phòng & Giá mỗi đêm
              if (_isLoadingTypes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(color: palette.accent),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạng loại phòng *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                        border: Border.all(color: palette.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoomTypeId,
                          isExpanded: true,
                          dropdownColor: palette.surface,
                          hint: const Text('Chọn hạng phòng'),
                          items: _roomRepo.roomTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type.id,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    type.name,
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(type.basePrice),
                                    style: TextStyle(
                                      color: palette.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId == null) return;
                            setState(() {
                              _selectedRoomTypeId = newId;
                              final match = _roomRepo.roomTypes.firstWhere(
                                (t) => t.id == newId,
                              );
                              _priceController.text =
                                  Formatters.formatNumber(match.basePrice.toInt());
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: AppSpacing.md),

              // 3. Giá phòng & Trạng thái hoạt động
              CustomTextField(
                controller: _priceController,
                label: 'Giá phòng mỗi đêm (VNĐ) *',
                hint: '1.200.000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                validator: (val) {
                  final numVal = Formatters.parseCurrency(val ?? '') ??
                      double.tryParse(val?.replaceAll(RegExp(r'[^0-9]'), '') ?? '');
                  if (numVal == null || numVal <= 0) {
                    return 'Vui lòng nhập giá hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Trạng thái phòng (Status selector)
              Text(
                'Trạng thái buồng phòng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  RoomStatus.available,
                  RoomStatus.occupied,
                  RoomStatus.reserved,
                  RoomStatus.cleaning,
                  RoomStatus.maintenance,
                  RoomStatus.pendingApproval,
                  RoomStatus.rejected,
                ].map((st) {
                  final isSelected = _selectedStatus == st;
                  return ChoiceChip(
                    label: Text(st.label),
                    selected: isSelected,
                    selectedColor: palette.accent.withValues(alpha: 0.2),
                    backgroundColor: palette.surfaceMuted,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? palette.accent : palette.ink,
                    ),
                    side: BorderSide(
                      color: isSelected ? palette.accent : palette.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedStatus = st);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Thông số chi tiết: Diện tích, Người lớn, Trẻ em
              Text(
                'Thông số & Sức chứa',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _sizeController,
                      label: 'Diện tích (m²)',
                      hint: '45',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.square_foot_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomTextField(
                      controller: _capacityAdultsController,
                      label: 'Người lớn',
                      hint: '2',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomTextField(
                      controller: _capacityChildrenController,
                      label: 'Trẻ em',
                      hint: '1',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.child_care_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Mô tả phòng & Ghi chú nội bộ
              Text(
                'Mô tả chi tiết phòng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: TextStyle(color: palette.ink, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Không gian ấm cúng, view biển, ban công thoáng mát...',
                  hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                  prefixIcon: Icon(Icons.description_outlined, color: palette.inkMuted),
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Ghi chú nội bộ (Chỉ nhân viên & Admin thấy)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(color: palette.ink, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Phòng cạnh thang máy, đã bảo dưỡng điều hòa tháng này...',
                  hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: palette.inkMuted),
                  filled: true,
                  fillColor: palette.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.field),
                    borderSide: BorderSide(color: palette.accent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6. Tiện ích phòng (Amenities)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiện nghi & Dịch vụ phòng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  Text(
                    '${_selectedAmenities.length} đã chọn',
                    style: TextStyle(fontSize: 12, color: palette.accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _defaultAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    label: Text(amenity),
                    selected: isSelected,
                    selectedColor: palette.accent.withValues(alpha: 0.18),
                    backgroundColor: palette.surfaceMuted,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? palette.accent : palette.ink,
                    ),
                    side: BorderSide(
                      color: isSelected ? palette.accent : palette.border,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedAmenities.add(amenity);
                        } else {
                          _selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),

              // Thêm tiện ích tùy chỉnh
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customAmenityController,
                      style: TextStyle(color: palette.ink, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Thêm tiện ích khác...',
                        hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                        prefixIcon: Icon(Icons.add_circle_outline_rounded, color: palette.inkMuted),
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomAmenity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Thêm'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 7. Quản lý Ảnh phòng (Images)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Album ảnh phòng (${_images.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.ink,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isUploadingImages ? null : _pickAndUploadImages,
                    icon: _isUploadingImages
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: Text(_isUploadingImages ? 'Đang tải ảnh...' : 'Tải ảnh máy lên'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Thêm ảnh qua URL
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      style: TextStyle(color: palette.ink, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nhập URL ảnh (https://...)',
                        hintStyle: TextStyle(color: palette.inkFaint, fontSize: 13),
                        prefixIcon: Icon(Icons.link_rounded, color: palette.inkMuted),
                        filled: true,
                        fillColor: palette.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.field),
                          borderSide: BorderSide(color: palette.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addImageUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.surfaceMuted,
                      foregroundColor: palette.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Gán'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_images.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final url = _images[idx];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (ctx, str) => Container(
                                width: 90,
                                height: 90,
                                color: palette.surfaceMuted,
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (ctx, str, err) => Container(
                                width: 90,
                                height: 90,
                                color: palette.surfaceMuted,
                                child: const Icon(Icons.broken_image_rounded, size: 28),
                              ),
                            ),
                          ),
                          if (idx == 0)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Ảnh chính',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _images.removeAt(idx));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.xxl),

              // Nút Submit Lưu thay đổi
              Row(
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
                      child: const Text('Hủy bỏ'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Lưu Thay Đổi (PUT)',
                      icon: Icons.save_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
