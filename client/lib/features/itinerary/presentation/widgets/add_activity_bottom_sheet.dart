import 'package:flutter/material.dart';

import '../../domain/models/trip_day.dart';

class AddActivityBottomSheet extends StatefulWidget {
  const AddActivityBottomSheet({
    super.key,
    required this.tripId,
    this.days = const [],
    this.selectedDayId,
    required this.onSubmit,
  });

  final String tripId;
  final List<TripDay> days;
  final String? selectedDayId;
  final Future<void> Function({
    required String title,
    required String kind,
    String? tripDayId,
    Map<String, dynamic>? inlinePlace,
    String? notes,
  })
  onSubmit;

  @override
  State<AddActivityBottomSheet> createState() => _AddActivityBottomSheetState();
}

class _AddActivityBottomSheetState extends State<AddActivityBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeNameController = TextEditingController();
  final _placeAddressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedKind = 'attraction';
  String? _chosenDayId;
  bool _isSubmitting = false;

  final _kinds = const [
    ('attraction', 'Attraction', Icons.explore_rounded),
    ('meal', 'Food & Dining', Icons.restaurant_rounded),
    ('transport', 'Transit', Icons.directions_bus_rounded),
    ('hotel', 'Stay', Icons.hotel_rounded),
    ('custom', 'Custom', Icons.place_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _chosenDayId =
        widget.selectedDayId ??
        (widget.days.isNotEmpty ? widget.days.first.id : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeNameController.dispose();
    _placeAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic>? inlinePlace;
      if (_placeNameController.text.trim().isNotEmpty) {
        inlinePlace = {
          'name': _placeNameController.text.trim(),
          if (_placeAddressController.text.trim().isNotEmpty)
            'formatted_address': _placeAddressController.text.trim(),
          'provider': 'manual',
          'attribution': 'TapItTrip',
        };
      }

      await widget.onSubmit(
        title: _titleController.text.trim(),
        kind: _selectedKind,
        tripDayId: _chosenDayId,
        inlinePlace: inlinePlace,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error adding activity: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                'Add Activity or Stop',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Activity Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity title *',
                  hintText: 'e.g., Uluwatu Temple Sunset',
                  prefixIcon: Icon(Icons.edit_calendar_rounded),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for this activity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Category / Kind Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kinds.map((k) {
                    final isSelected = _selectedKind == k.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: Icon(
                          k.$3,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : colorScheme.primary,
                        ),
                        label: Text(k.$2),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedKind = k.$1),
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              // Place Name & Address
              TextFormField(
                controller: _placeNameController,
                decoration: const InputDecoration(
                  labelText: 'Location / Place name',
                  hintText: 'e.g., Uluwatu Temple',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _placeAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address or landmark (for map directions)',
                  hintText: 'e.g., Pecatu, South Kuta, Badung',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 12),
              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes or highlights',
                  hintText: 'e.g., Buy tickets online, sunset starts at 6pm',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              // Submit button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(
                  _isSubmitting ? 'Adding...' : 'Add Activity',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
