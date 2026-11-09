import 'package:flutter/material.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/itinerary_item.dart';
import '../../domain/models/trip_day.dart';
import 'place_autocomplete_field.dart';

class AddActivityBottomSheet extends StatefulWidget {
  const AddActivityBottomSheet({
    super.key,
    required this.tripId,
    this.days = const [],
    this.selectedDayId,
    this.initialItem,
    required this.onSubmit,
  });

  final String tripId;
  final List<TripDay> days;
  final String? selectedDayId;
  final ItineraryItem? initialItem;
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

  late final TextEditingController _titleController;
  late final TextEditingController _placeNameController;
  late final TextEditingController _placeAddressController;
  late final TextEditingController _notesController;

  late String _selectedKind;
  String? _chosenDayId;
  double? _latitude;
  double? _longitude;
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
    final item = widget.initialItem;
    _titleController = TextEditingController(text: item?.title ?? '');
    _placeNameController = TextEditingController(text: item?.place?.name ?? '');
    _placeAddressController = TextEditingController(
      text: item?.place?.formattedAddress ?? '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');

    _selectedKind = item?.kind ?? 'attraction';
    _latitude = item?.place?.latitude;
    _longitude = item?.place?.longitude;
    _chosenDayId =
        item?.tripDayId ??
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
        final address = _placeAddressController.text.trim();
        inlinePlace = {
          'name': _placeNameController.text.trim(),
          if (address.isNotEmpty) ...{
            'formatted_address': address,
            'address': address,
          },
          if (_latitude != null) 'latitude': _latitude,
          if (_longitude != null) 'longitude': _longitude,
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
        String displayError;
        if (e is ValidationException) {
          displayError = e.fieldErrors.isNotEmpty
              ? e.fieldErrors.join(', ')
              : e.message;
        } else if (e is ApiException) {
          displayError = e.message;
        } else {
          displayError = e.toString()
              .replaceAll(RegExp(r'^ApiException\([^)]+\):\s*'), '')
              .replaceAll(RegExp(r'^Exception:\s*'), '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.initialItem != null
                  ? 'Error updating activity: $displayError'
                  : 'Error adding activity: $displayError',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
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
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        key: const ValueKey('activity-sheet-surface'),
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                      widget.initialItem != null
                          ? 'Edit Activity or Stop'
                          : 'Add Activity or Stop',
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
                    const SizedBox(height: 16),
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
                              onSelected: (_) =>
                                  setState(() => _selectedKind = k.$1),
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
                    const SizedBox(height: 16),
                    // Place Name & Address (with Real-Time Autocomplete)
                    PlaceAutocompleteField(
                      controller: _placeNameController,
                      labelText: 'Location / Place name',
                      hintText: 'e.g., Uluwatu Temple, Shibuya Crossing',
                      prefixIcon: Icons.place_rounded,
                      onPlaceSelected: (place) {
                        setState(() {
                          _placeNameController.text = place.name;
                          if (place.formattedAddress != null &&
                              place.formattedAddress!.isNotEmpty) {
                            _placeAddressController.text =
                                place.formattedAddress!;
                          }
                          _latitude = place.latitude;
                          _longitude = place.longitude;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    PlaceAutocompleteField(
                      controller: _placeAddressController,
                      labelText: 'Address or landmark (for map directions)',
                      hintText: 'e.g., Pecatu, South Kuta, Badung',
                      prefixIcon: Icons.map_outlined,
                      isAddressField: true,
                      onPlaceSelected: (place) {
                        setState(() {
                          _placeAddressController.text =
                              place.formattedAddress ?? place.name;
                          _latitude = place.latitude ?? _latitude;
                          _longitude = place.longitude ?? _longitude;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes or highlights',
                        hintText:
                            'e.g., Buy tickets online, sunset starts at 6pm',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          : Icon(
                              widget.initialItem != null
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                            ),
                      label: Text(
                        _isSubmitting
                            ? (widget.initialItem != null
                                  ? 'Saving...'
                                  : 'Adding...')
                            : (widget.initialItem != null
                                  ? 'Save Changes'
                                  : 'Add Activity'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
