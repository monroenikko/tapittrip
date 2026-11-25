import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/booking_import.dart';
import '../providers/booking_import_provider.dart';

class ReviewExtractedBookingDialog extends ConsumerStatefulWidget {
  const ReviewExtractedBookingDialog({
    super.key,
    required this.tripId,
    required this.bookingImport,
  });

  final String tripId;
  final BookingImport bookingImport;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required BookingImport bookingImport,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReviewExtractedBookingDialog(
        tripId: tripId,
        bookingImport: bookingImport,
      ),
    );
  }

  @override
  ConsumerState<ReviewExtractedBookingDialog> createState() =>
      _ReviewExtractedBookingDialogState();
}

class _ReviewExtractedBookingDialogState
    extends ConsumerState<ReviewExtractedBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _primaryFieldController;
  late final TextEditingController _referenceController;
  late final TextEditingController _extraFieldController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final item = widget.bookingImport;
    if (item.bookingType == 'flight') {
      final flight = item.extractedFlight ?? const {};
      _primaryFieldController = TextEditingController(
        text: flight['airline'] as String? ?? 'Philippine Airlines',
      );
      _referenceController = TextEditingController(
        text: flight['booking_reference'] as String? ?? '',
      );
      final segments = flight['segments'] as List?;
      final firstSeg = (segments != null && segments.isNotEmpty)
          ? segments[0] as Map
          : {};
      _extraFieldController = TextEditingController(
        text: firstSeg['flight_number'] as String? ?? 'PR 101',
      );
    } else if (item.bookingType == 'stay') {
      final stay = item.extractedStay ?? const {};
      _primaryFieldController = TextEditingController(
        text: stay['name'] as String? ?? 'Hotel Stay',
      );
      _referenceController = TextEditingController(
        text: stay['booking_reference'] as String? ?? '',
      );
      _extraFieldController = TextEditingController(
        text: stay['address'] as String? ?? '',
      );
    } else {
      final activity = item.extractedActivity ?? const {};
      _primaryFieldController = TextEditingController(
        text: activity['title'] as String? ?? 'Activity',
      );
      _referenceController = TextEditingController(
        text: activity['place_name'] as String? ?? '',
      );
      _extraFieldController = TextEditingController(
        text: activity['notes'] as String? ?? '',
      );
    }
  }

  @override
  void dispose() {
    _primaryFieldController.dispose();
    _referenceController.dispose();
    _extraFieldController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(bookingImportRepositoryProvider);
      final item = widget.bookingImport;

      Map<String, dynamic>? flightPayload;
      Map<String, dynamic>? stayPayload;
      Map<String, dynamic>? activityPayload;

      if (item.bookingType == 'flight') {
        final currentFlight = Map<String, dynamic>.from(
          item.extractedFlight ?? const {},
        );
        currentFlight['airline'] = _primaryFieldController.text.trim();
        currentFlight['booking_reference'] = _referenceController.text.trim();
        final segList =
            (currentFlight['segments'] as List?)
                ?.map((s) => Map<String, dynamic>.from(s as Map))
                .toList() ??
            [];
        if (segList.isNotEmpty) {
          segList[0]['flight_number'] = _extraFieldController.text.trim();
          currentFlight['segments'] = segList;
        }
        flightPayload = currentFlight;
      } else if (item.bookingType == 'stay') {
        final currentStay = Map<String, dynamic>.from(
          item.extractedStay ?? const {},
        );
        currentStay['name'] = _primaryFieldController.text.trim();
        currentStay['booking_reference'] = _referenceController.text.trim();
        currentStay['address'] = _extraFieldController.text.trim();
        stayPayload = currentStay;
      } else {
        final currentAct = Map<String, dynamic>.from(
          item.extractedActivity ?? const {},
        );
        currentAct['title'] = _primaryFieldController.text.trim();
        currentAct['place_name'] = _referenceController.text.trim();
        currentAct['notes'] = _extraFieldController.text.trim();
        activityPayload = currentAct;
      }

      await repo.confirmImport(
        item.id,
        baseVersion: item.version,
        bookingType: item.bookingType,
        flight: flightPayload,
        stay: stayPayload,
        activity: activityPayload,
      );

      ref.invalidate(tripBookingImportsProvider(widget.tripId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${item.typeLabel} confirmed and added to your trip!',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.bookingImport;
    final theme = Theme.of(context);
    final score = item.confidenceScore ?? 0.8;
    final confidenceColor = score >= 0.85
        ? Colors.green.shade700
        : score >= 0.60
        ? Colors.orange.shade800
        : Colors.red.shade700;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Review ${item.typeLabel}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: confidenceColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${item.confidencePercentText} confidence',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: confidenceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _primaryFieldController,
                decoration: InputDecoration(
                  labelText: item.bookingType == 'flight'
                      ? 'Airline'
                      : item.bookingType == 'stay'
                      ? 'Accommodation Name'
                      : 'Activity Title',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    item.bookingType == 'flight'
                        ? Icons.flight
                        : item.bookingType == 'stay'
                        ? Icons.hotel
                        : Icons.local_activity,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: item.bookingType == 'activity'
                      ? 'Place / Venue'
                      : 'Booking Reference / PNR',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _extraFieldController,
                decoration: InputDecoration(
                  labelText: item.bookingType == 'flight'
                      ? 'Flight Number'
                      : item.bookingType == 'stay'
                      ? 'Address'
                      : 'Notes',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _handleConfirm,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline, size: 18),
          label: Text(_isSaving ? 'Adding...' : 'Confirm & Add to Trip'),
        ),
      ],
    );
  }
}
