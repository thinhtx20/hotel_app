import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/role_enum.dart';
import '../../../core/utils/formatters.dart';
import '../../../di/injection_container.dart';
import '../../../shared/models/room_model.dart';
import '../../../shared/repositories/room_repository.dart';
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

  final List<String> _availableAmenities = [
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
      roomTypeId: _selectedRoomType?.id,
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
              const SizedBox(width: 10),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: AppGradients.navy,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_business_rounded, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TẠO PHÒNG MỚI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Phòng sẽ chờ Admin duyệt trước khi hiển thị đón khách',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 16),

                    // Loại phòng dropdown
                    const Text(
                      'LOẠI PHÒNG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: _isLoadingTypes
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<RoomTypeModel>(
                                value: _selectedRoomType,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
                                hint: const Text('Chọn loại phòng từ hệ thống'),
                                items: _roomRepo.roomTypes.map((type) {
                                  return DropdownMenuItem<RoomTypeModel>(
                                    value: type,
                                    child: Text(
                                      '${type.name} • ${Formatters.formatCurrency(type.basePrice)}/đêm',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.slate900,
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
                                      _priceController.text = Formatters.formatNumber(val.basePrice.toInt());
                                      if (val.images.isNotEmpty && _imageUrlController.text.isEmpty) {
                                        _imageUrlController.text = val.images.first;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

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
                    const SizedBox(height: 16),

                    // URL Hình ảnh
                    CustomTextField(
                      controller: _imageUrlController,
                      label: 'Đường dẫn ảnh phòng (URL)',
                      hint: 'https://...',
                      prefixIcon: Icons.image_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú (Notes)
                    CustomTextField(
                      controller: _notesController,
                      label: 'Ghi chú thêm (Tùy chọn)',
                      hint: 'VD: Cạnh thang máy, view ban công ngắm bình minh...',
                      prefixIcon: Icons.edit_note_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Tiện nghi
                    const Text(
                      'TIỆN NGHI KÈM THEO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableAmenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(amenity),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppColors.slate700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.slate100,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.slate200,
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
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: 'Tạo Phòng & Gửi Duyệt',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                      icon: Icons.send_rounded,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
