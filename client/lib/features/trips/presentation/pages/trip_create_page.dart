import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  String? _errorMessage;

  final _tripTypes = const ['leisure', 'business', 'family', 'solo', 'group'];

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
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
      _errorMessage = null;
    });

    final dateFormat = DateFormat('yyyy-MM-dd');

    final result = await ref
        .read(tripListProvider.notifier)
        .createTrip(
          title: _titleController.text.trim(),
          destinationCountry: _destinationController.text.trim().isEmpty
              ? null
              : _destinationController.text.trim(),
          startDate: _startDate != null ? dateFormat.format(_startDate!) : null,
          endDate: _endDate != null ? dateFormat.format(_endDate!) : null,
          tripType: _selectedTripType,
          planningMode: _selectedMode,
          primaryTimezone: 'UTC',
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      context.pop();
    } else {
      setState(() {
        _errorMessage = 'Failed to create trip. Please check your connection.';
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
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination (optional)',
                  hintText: 'e.g. Tokyo, JP',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                textInputAction: TextInputAction.next,
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
              FilledButton(
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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
