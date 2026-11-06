import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/luggage_profile.dart';
import '../../domain/services/booking_confirmation_parser.dart';
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
  final _phoneController = TextEditingController();

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
    _phoneController.dispose();
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

  Future<void> _openSmartImportDialog() async {
    final textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Auto-Fill from Booking'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your confirmation email text or receipt from Agoda, Booking.com, Airbnb, Expedia, or hotel.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: textController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'e.g.\nBooking Confirmation #KAYON-9921\nHotel: Kayon Resort Ubud\nCheck-in: May 12, 2026\nCheck-out: May 18, 2026',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final clipData = await Clipboard.getData(
                    Clipboard.kTextPlain,
                  );
                  if (clipData?.text != null) {
                    textController.text = clipData!.text!;
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Paste from Clipboard'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              const parser = BookingConfirmationParser();
              final extracted = parser.parse(text);

              setState(() {
                if (extracted.name != null) {
                  _nameController.text = extracted.name!;
                }
                if (extracted.address != null) {
                  _addressController.text = extracted.address!;
                }
                if (extracted.bookingReference != null) {
                  _bookingRefController.text = extracted.bookingReference!;
                }
                if (extracted.phone != null) {
                  _phoneController.text = extracted.phone!;
                }
                if (extracted.checkInAt != null) {
                  _checkInAt = extracted.checkInAt;
                }
                if (extracted.checkOutAt != null) {
                  _checkOutAt = extracted.checkOutAt;
                }
                if (extracted.stayType.isNotEmpty) {
                  _stayType = extracted.stayType;
                }
              });

              Navigator.of(ctx).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    extracted.hasContent
                        ? 'Details extracted! Review and adjust any field below.'
                        : 'No recognizable booking fields found. You can still type manually.',
                  ),
                ),
              );
            },
            child: const Text('Auto-Fill'),
          ),
        ],
      ),
    );
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
            address:
                _addressController.text.trim().isNotEmpty
                    ? _addressController.text.trim()
                    : null,
            checkInAt: _checkInAt,
            checkOutAt: _checkOutAt,
            phone:
                _phoneController.text.trim().isNotEmpty
                    ? _phoneController.text.trim()
                    : null,
            bookingReference:
                _bookingRefController.text.trim().isNotEmpty
                    ? _bookingRefController.text.trim()
                    : null,
            notes:
                _notesController.text.trim().isNotEmpty
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
                const SizedBox(height: 12),

                // Smart Auto-Fill Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Have a booking confirmation?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Paste email or receipt to auto-fill details',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openSmartImportDialog,
                        child: const Text('Auto-Fill'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stay Name (Manual Input)
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
                            color:
                                isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                          ),
                          label: Text(type.$2),
                          selected: isSelected,
                          selectedColor: colorScheme.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                            fontWeight:
                                isSelected
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

                // Address (Manual Input)
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

                // Dates: Check-in & Check-out (Manual Pickers)
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
                              color:
                                  _checkInAt != null
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
                              color:
                                  _checkOutAt != null
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

                // Luggage Profile Multi-Select with Others
                Text(
                  'Luggage Profile (Multi-select)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select all luggage types you are bringing:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                LuggagePresetSelector(
                  profile: _luggageProfile,
                  onProfileChanged: (profile) {
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
                    child:
                        _isLoading
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
