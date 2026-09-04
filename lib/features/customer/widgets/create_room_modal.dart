import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class CreateRoomModal extends StatefulWidget {
  final VoidCallback? onSuccess;

  const CreateRoomModal({super.key, this.onSuccess});

  @override
  State<CreateRoomModal> createState() => _CreateRoomModalState();
}

class _CreateRoomModalState extends State<CreateRoomModal> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _floorController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _notesController = TextEditingController();

  final RoomRepository _roomRepo = sl<RoomRepository>();
  RoomTypeModel? _selectedRoomType;
  bool _isLoadingTypes = false;

  bool _isSubmitting = false;
  final List<String> _selectedAmenities = ['Wifi', 'Điều hòa'];

  final List<String> _availableAmenities = const [
    'Wifi',
    'Điều hòa',
    'Ban công',
    'Bồn tắm',
    'Tủ lạnh mini',
    'Tivi 4K',
    'Ăn sáng miễn phí',
    'Hồ bơi riêng',
  ];

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _isLoadingTypes = true);
    await _roomRepo.fetchRoomTypes();
    if (mounted) {
      setState(() {
        _isLoadingTypes = false;
        if (_roomRepo.roomTypes.isNotEmpty) {
          _selectedRoomType = _roomRepo.roomTypes.first;
          _priceController.text = '${_selectedRoomType!.basePrice.toInt()}';
          if (_selectedRoomType!.images.isNotEmpty) {
            _imageUrlController.text = _selectedRoomType!.images.first;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _floorController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRoomType == null || _selectedRoomType!.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn hạng phòng hợp lệ trước khi tạo'),
          backgroundColor: AppColors.rose,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final roomNumber = _roomNumberController.text.trim();
    final floor = int.tryParse(_floorController.text.trim()) ?? 1;
    final price = Formatters.parseCurrency(_priceController.text) ??
        (_selectedRoomType?.basePrice ?? 1500000);
    final imageUrl = _imageUrlController.text.trim();
    final notes = _notesController.text.trim();

    final newRoom = RoomModel(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      roomNumber: roomNumber,
      floor: floor,
      status: RoomStatus.pendingApproval,
      pricePerNight: price,
      roomTypeId: _selectedRoomType!.id,
      roomTypeName: _selectedRoomType?.name ?? 'Phòng Tiêu Chuẩn',
      images: imageUrl.isNotEmpty
          ? [imageUrl]
          : (_selectedRoomType?.images.isNotEmpty == true
              ? _selectedRoomType!.images
              : [
                  'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=800&q=80'
                ]),
      amenities: List.from(_selectedAmenities),
    );

    await _roomRepo.addRoom(newRoom, notes: notes.isNotEmpty ? notes : null);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Đã tạo phòng $roomNumber! Đang chờ Admin phê duyệt.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      );

      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return AppBottomSheet(
      title: 'Tạo Phòng Mới',
      trailing: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.close_rounded, color: palette.inkMuted),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phòng sẽ chờ Admin duyệt trước khi hiển thị đón khách',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.inkMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Row: Số phòng & Tầng
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _roomNumberController,
                      label: 'Số phòng *',
                      hint: 'VD: 402',
                      prefixIcon: Icons.door_front_door_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nhập số phòng';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomTextField(
                      controller: _floorController,
                      label: 'Tầng *',
                      hint: 'VD: 4',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.stairs_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nhập tầng';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Loại phòng dropdown
              Text(
                'LOẠI PHÒNG',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  border: Border.all(color: palette.border),
                ),
                child: _isLoadingTypes
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: palette.accent,
                            ),
                          ),
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<RoomTypeModel>(
                          value: _selectedRoomType,
                          isExpanded: true,
                          dropdownColor: palette.surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: palette.ink,
                          ),
                          hint: Text(
                            'Chọn loại phòng từ hệ thống',
                            style: TextStyle(color: palette.inkFaint),
                          ),
                          items: _roomRepo.roomTypes.map((type) {
                            return DropdownMenuItem<RoomTypeModel>(
                              value: type,
                              child: Text(
                                '${type.name} • ${Formatters.formatCurrency(type.basePrice)}/đêm',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: palette.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRoomType = val;
                                _priceController.text =
                                    Formatters.formatNumber(
                                        val.basePrice.toInt());
                                if (val.images.isNotEmpty &&
                                    _imageUrlController.text.isEmpty) {
                                  _imageUrlController.text = val.images.first;
                                }
                              });
                            }
                          },
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Giá phòng/đêm
              CustomTextField(
                controller: _priceController,
                label: 'Giá phòng (VNĐ/đêm) *',
                hint: 'VD: 1.500.000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập giá phòng';
                  }
                  if (Formatters.parseCurrency(val) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // URL Hình ảnh
              CustomTextField(
                controller: _imageUrlController,
                label: 'Đường dẫn ảnh phòng (URL)',
                hint: 'https://...',
                prefixIcon: Icons.image_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Ghi chú (Notes)
              CustomTextField(
                controller: _notesController,
                label: 'Ghi chú thêm (Tùy chọn)',
                hint: 'VD: Cạnh thang máy, view ban công ngắm bình minh...',
                prefixIcon: Icons.edit_note_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tiện nghi
              Text(
                'TIỆN NGHI KÈM THEO',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _availableAmenities.map((amenity) {
                  final isSelected = _selectedAmenities.contains(amenity);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(amenity),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : palette.ink,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    selectedColor: palette.accent,
                    backgroundColor: palette.surfaceMuted,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      side: BorderSide(
                        color: isSelected ? palette.accent : palette.border,
                      ),
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
              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              CustomButton(
                text: 'Tạo Phòng & Gửi Duyệt',
                isGold: true,
                isLoading: _isSubmitting,
                onPressed: _submit,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
