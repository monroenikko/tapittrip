import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/place_autocomplete_field.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/domain/models/trip.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/trips/presentation/widgets/planning_mode_selector.dart';

class EditTripBottomSheet extends ConsumerStatefulWidget {
  const EditTripBottomSheet({super.key, required this.trip});

  final Trip trip;

  static Future<Trip?> show(BuildContext context, Trip trip) {
    return showModalBottomSheet<Trip>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTripBottomSheet(trip: trip),
    );
  }

  @override
  ConsumerState<EditTripBottomSheet> createState() =>
      _EditTripBottomSheetState();
}

class _EditTripBottomSheetState extends ConsumerState<EditTripBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _timezoneController;

  late PlanningMode _selectedMode;
  late String _selectedTripType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String? _errorMessage;

  final _tripTypes = const ['leisure', 'business', 'family', 'solo', 'group'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.trip.title);
    _destinationController = TextEditingController(
      text: widget.trip.destinationCountry ?? '',
    );
    _timezoneController = TextEditingController(
      text: widget.trip.primaryTimezone,
    );
    _selectedMode = widget.trip.planningMode;
    _selectedTripType = _tripTypes.contains(widget.trip.tripType)
        ? widget.trip.tripType
        : 'leisure';

    if (widget.trip.startDate != null) {
      _startDate = DateTime.tryParse(widget.trip.startDate!);
    }
    if (widget.trip.endDate != null) {
      _endDate = DateTime.tryParse(widget.trip.endDate!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final dateFormat = DateFormat('yyyy-MM-dd');

    try {
      final updated = await ref
          .read(tripListProvider.notifier)
          .updateTrip(
            widget.trip.id,
            title: _titleController.text.trim(),
            destinationCountry: _destinationController.text.trim().isEmpty
                ? null
                : _destinationController.text.trim(),
            startDate: _startDate != null ? dateFormat.format(_startDate!) : null,
            endDate: _endDate != null ? dateFormat.format(_endDate!) : null,
            primaryTimezone: _timezoneController.text.trim().isEmpty
                ? 'UTC'
                : _timezoneController.text.trim(),
            tripType: _selectedTripType,
            planningMode: _selectedMode,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (updated != null) {
        Navigator.of(context).pop(updated);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is ValidationException) {
          final fields = e.details['fields'];
          if (fields is Map && fields.isNotEmpty) {
            final firstError = fields.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              _errorMessage = firstError.first.toString();
            } else {
              _errorMessage = firstError.toString();
            }
          } else {
            _errorMessage = e.message;
          }
        } else if (e is ApiException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Failed to update trip. Please check your connection.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Trip',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Trip title *',
                  hintText: 'e.g. Japan Spring Adventure',
                  prefixIcon: Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for your trip';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PlaceAutocompleteField(
                controller: _destinationController,
                labelText: 'Destination (City / Country)',
                hintText: 'Search destination e.g. Tokyo, Japan',
                prefixIcon: Icons.place_outlined,
                onPlaceSelected: (place) {
                  setState(() {
                    _destinationController.text = place.name.isNotEmpty
                        ? place.name
                        : (place.formattedAddress ?? '');
                  });
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.date_range_outlined),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${dateFormat.format(_startDate!)} – ${dateFormat.format(_endDate!)}'
                            : 'Select trip dates (optional)',
                        style: TextStyle(
                          color: _startDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedTripType,
                decoration: const InputDecoration(
                  labelText: 'Trip style',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _tripTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTripType = val);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timezoneController,
                decoration: const InputDecoration(
                  labelText: 'Primary Timezone',
                  hintText: 'e.g. Asia/Tokyo or UTC',
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 20),
              PlanningModeSelector(
                selectedMode: _selectedMode,
                onModeSelected: (mode) {
                  setState(() => _selectedMode = mode);
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
