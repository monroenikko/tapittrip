import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/luggage_profile.dart';
import '../providers/stay_provider.dart';
import 'luggage_preset_selector.dart';

class AddStayBottomSheet extends ConsumerStatefulWidget {
  const AddStayBottomSheet({super.key, required this.tripId});

  final String tripId;

  static Future<void> show(BuildContext context, String tripId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStayBottomSheet(tripId: tripId),
    );
  }

  @override
  ConsumerState<AddStayBottomSheet> createState() => _AddStayBottomSheetState();
}

class _AddStayBottomSheetState extends ConsumerState<AddStayBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _bookingRefController = TextEditingController();
  final _notesController = TextEditingController();

  String _stayType = 'hotel';
  DateTime? _checkInAt;
  DateTime? _checkOutAt;
  LuggageProfile _luggageProfile = LuggageProfile.fromPreset('standard');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _bookingRefController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickCheckInDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInAt ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _checkInAt = picked;
        if (_checkOutAt != null && _checkOutAt!.isBefore(picked)) {
          _checkOutAt = picked.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickCheckOutDate() async {
    final start = _checkInAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutAt ?? start.add(const Duration(days: 1)),
      firstDate: start,
      lastDate: start.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _checkOutAt = picked;
      });
    }
  }

  Future<void> _saveStay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(stayListProvider(widget.tripId).notifier)
          .addStay(
            name: _nameController.text.trim(),
            stayType: _stayType,
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            checkInAt: _checkInAt,
            checkOutAt: _checkOutAt,
            bookingReference: _bookingRefController.text.trim().isNotEmpty
                ? _bookingRefController.text.trim()
                : null,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
            luggageProfile: _luggageProfile,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accommodation added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to add stay. Please check your connection.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Accommodation',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stay Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Hotel / Stay Name *',
                    hintText: 'e.g. Kayon Resort Ubud',
                    prefixIcon: const Icon(Icons.hotel_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter accommodation name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stay Type Chips
                Text(
                  'Accommodation Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        ('hotel', 'Hotel', Icons.hotel_rounded),
                        ('hostel', 'Hostel', Icons.holiday_village_rounded),
                        ('rental', 'Rental', Icons.home_work_rounded),
                        (
                          'friends_family',
                          'Friends & Family',
                          Icons.people_outline_rounded,
                        ),
                      ].map((type) {
                        final isSelected = _stayType == type.$1;
                        return ChoiceChip(
                          avatar: Icon(
                            type.$3,
                            size: 16,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                          label: Text(type.$2),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _stayType = type.$1);
                          },
                        );
                      }).toList(),
                ),
                const SizedBox(height: 16),

                // Address
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    hintText:
                        'e.g. Banjar Bresela, Desa Bresela, Payangan, Ubud',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dates: Check-in & Check-out
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickCheckInDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Check-in',
                            prefixIcon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _checkInAt != null
                                ? '${_checkInAt!.month}/${_checkInAt!.day}/${_checkInAt!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _checkInAt != null
                                  ? colorScheme.onSurface
                                  : colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickCheckOutDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Check-out',
                            prefixIcon: const Icon(
                              Icons.event_available_rounded,
                              size: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            _checkOutAt != null
                                ? '${_checkOutAt!.month}/${_checkOutAt!.day}/${_checkOutAt!.year}'
                                : 'Select date',
                            style: TextStyle(
                              color: _checkOutAt != null
                                  ? colorScheme.onSurface
                                  : colorScheme.outline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Booking Reference (optional)
                TextFormField(
                  controller: _bookingRefController,
                  decoration: InputDecoration(
                    labelText: 'Booking Reference / Confirmation Code',
                    hintText: 'e.g. #HTL-98214',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Luggage Preset
                Text(
                  'Arrival Luggage Profile',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                LuggagePresetSelector(
                  selectedPreset: _luggageProfile.preset,
                  onPresetChanged: (profile) {
                    setState(() => _luggageProfile = profile);
                  },
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveStay,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Accommodation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
