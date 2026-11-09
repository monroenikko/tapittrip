import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tapittrip/core/network/api_exceptions.dart';
import 'package:tapittrip/features/itinerary/presentation/providers/itinerary_provider.dart';
import 'package:tapittrip/features/itinerary/presentation/widgets/place_autocomplete_field.dart';
import 'package:tapittrip/features/trips/domain/models/planning_mode.dart';
import 'package:tapittrip/features/trips/presentation/providers/trip_list_provider.dart';
import 'package:tapittrip/features/trips/presentation/widgets/planning_mode_selector.dart';

class TripCreatePage extends ConsumerStatefulWidget {
  const TripCreatePage({super.key});

  @override
  ConsumerState<TripCreatePage> createState() => _TripCreatePageState();
}

class _TripCreatePageState extends ConsumerState<TripCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();

  PlanningMode _selectedMode = PlanningMode.diy;
  String _selectedTripType = 'leisure';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  String _loadingStatus = '';
  String? _errorMessage;

  // Itinerary Setup options
  bool _autoGenerateItinerary = true;
  final Set<String> _selectedInterests = {'sightseeing', 'dining', 'culture'};
  bool _addManualStop = false;
  final _firstStopTitleController = TextEditingController();
  final _firstStopPlaceController = TextEditingController();
  String _firstStopKind = 'attraction';

  final _tripTypes = const ['leisure', 'business', 'family', 'solo', 'group'];

  final _availableInterests = const [
    {'id': 'sightseeing', 'label': 'Sightseeing', 'icon': '🏛️'},
    {'id': 'dining', 'label': 'Food & Dining', 'icon': '🍜'},
    {'id': 'culture', 'label': 'Culture & Arts', 'icon': '🎭'},
    {'id': 'nature', 'label': 'Nature & Parks', 'icon': '🌳'},
    {'id': 'shopping', 'label': 'Shopping', 'icon': '🛍️'},
    {'id': 'relaxation', 'label': 'Relaxation', 'icon': '☕'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _firstStopTitleController.dispose();
    _firstStopPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
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
      _loadingStatus = 'Creating your trip...';
      _errorMessage = null;
    });

    final dateFormat = DateFormat('yyyy-MM-dd');
    final dest = _destinationController.text.trim();

    try {
      final result = await ref
          .read(tripListProvider.notifier)
          .createTrip(
            title: _titleController.text.trim(),
            destinationCountry: dest.isEmpty ? null : dest,
            startDate: _startDate != null ? dateFormat.format(_startDate!) : null,
            endDate: _endDate != null ? dateFormat.format(_endDate!) : null,
            tripType: _selectedTripType,
            planningMode: _selectedMode,
            primaryTimezone: 'UTC',
          );

      if (!mounted) return;

      if (result != null) {
        // Auto-generate AI itinerary if requested
        if (_autoGenerateItinerary) {
          setState(() {
            _loadingStatus = 'Crafting your AI starter itinerary...';
          });

          try {
            final destinationQuery = dest.isNotEmpty
                ? dest
                : _titleController.text.trim();

            final duration = (_startDate != null && _endDate != null)
                ? (_endDate!.difference(_startDate!).inDays + 1).clamp(1, 7)
                : 3;

            final aiRepo = ref.read(aiItineraryRepositoryProvider);
            final plan = await aiRepo.generatePlan(
              result.id,
              destination: destinationQuery,
              durationDays: duration,
              interests: _selectedInterests.toList(),
              travelParty: _selectedTripType,
            );

            if (plan.days.isNotEmpty) {
              await aiRepo.applyPlan(result.id, plan.days);
            }
          } catch (aiErr) {
            debugPrint('Auto-itinerary generation non-fatal fallback: $aiErr');
          }
        } else if (_addManualStop && _firstStopTitleController.text.trim().isNotEmpty) {
          setState(() {
            _loadingStatus = 'Adding your first activity...';
          });

          try {
            final itinRepo = ref.read(itineraryRepositoryProvider);
            final placeName = _firstStopPlaceController.text.trim();
            await itinRepo.createItem(
              result.id,
              title: _firstStopTitleController.text.trim(),
              kind: _firstStopKind,
              inlinePlace: placeName.isNotEmpty ? {'name': placeName} : null,
            );
          } catch (itinErr) {
            debugPrint('Manual stop creation non-fatal fallback: $itinErr');
          }
        }

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Refresh itinerary and trip day caches for this trip
        ref.invalidate(itineraryListProvider(result.id));
        ref.invalidate(tripDaysProvider(result.id));

        // Navigate directly to the newly populated trip itinerary
        if (GoRouter.maybeOf(context) != null) {
          context.pushReplacement('/trips/${result.id}/itinerary', extra: result);
        } else {
          Navigator.of(context).maybePop();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        if (GoRouter.maybeOf(context) != null) {
          context.pop();
        } else {
          Navigator.of(context).maybePop();
        }
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
          final clean = e.toString()
              .replaceAll(RegExp(r'^ApiException\([^)]+\):\s*'), '')
              .replaceAll(RegExp(r'^Exception:\s*'), '');
          _errorMessage = clean.isNotEmpty
              ? clean
              : 'Unable to create trip. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                labelText: 'Destination (optional)',
                hintText: 'e.g. Tokyo, Japan',
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  _startDate != null && _endDate != null
                      ? '${dateFormat.format(_startDate!)} – ${dateFormat.format(_endDate!)}'
                      : 'Select trip dates (optional)',
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
              const SizedBox(height: 24),
              PlanningModeSelector(
                selectedMode: _selectedMode,
                onModeSelected: (mode) {
                  setState(() => _selectedMode = mode);
                },
              ),
              const SizedBox(height: 24),

              // Itinerary Setup Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _autoGenerateItinerary
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant,
                  ),
                ),
                color: _autoGenerateItinerary
                    ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                    : colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Itinerary Setup',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Choose how you want to start building your itinerary.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Auto-generate AI switch
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _autoGenerateItinerary,
                        onChanged: (val) {
                          setState(() {
                            _autoGenerateItinerary = val;
                            if (val) _addManualStop = false;
                          });
                        },
                        title: const Text(
                          '✨ Auto-generate starter itinerary with AI',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Creates day-by-day stops and activities for your destination.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),

                      // Interest tags
                      if (_autoGenerateItinerary) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Interests & Focus:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableInterests.map((interest) {
                            final isSelected = _selectedInterests.contains(interest['id']);
                            return FilterChip(
                              label: Text('${interest['icon']} ${interest['label']}'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedInterests.add(interest['id']!);
                                  } else {
                                    if (_selectedInterests.length > 1) {
                                      _selectedInterests.remove(interest['id']!);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],

                      const Divider(height: 24),

                      // Manual input checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _addManualStop,
                        onChanged: (val) {
                          setState(() {
                            _addManualStop = val ?? false;
                            if (_addManualStop) {
                              _autoGenerateItinerary = false;
                            }
                          });
                        },
                        title: const Text(
                          '✍️ Add your first stop manually instead',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Input your first planned activity or check-in now.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),

                      if (_addManualStop) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _firstStopTitleController,
                          decoration: const InputDecoration(
                            labelText: 'First stop title',
                            hintText: 'e.g. Check-in or Dinner near Hotel',
                            prefixIcon: Icon(Icons.add_location_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PlaceAutocompleteField(
                          controller: _firstStopPlaceController,
                          labelText: 'Location / Address (optional)',
                          hintText: 'e.g. Bonifacio High Street, Taguig',
                          prefixIcon: Icons.map_outlined,
                          onPlaceSelected: (p) {
                            setState(() {
                              _firstStopPlaceController.text = p.name.isNotEmpty
                                  ? p.name
                                  : (p.formattedAddress ?? '');
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _firstStopKind,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'attraction', child: Text('Sightseeing / Attraction')),
                            DropdownMenuItem(value: 'dining', child: Text('Dining / Restaurant')),
                            DropdownMenuItem(value: 'lodging', child: Text('Hotel / Lodging')),
                            DropdownMenuItem(value: 'transit', child: Text('Transit / Flight')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _firstStopKind = v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _loadingStatus.isNotEmpty ? _loadingStatus : 'Creating Trip...',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : const Text('Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
