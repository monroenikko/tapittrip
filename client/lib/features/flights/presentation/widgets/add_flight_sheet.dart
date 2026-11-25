import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/flight.dart';
import '../../domain/services/flight_confirmation_parser.dart';
import '../providers/flight_provider.dart';

class AddFlightSheet extends ConsumerStatefulWidget {
  const AddFlightSheet({super.key, required this.tripId, this.existingFlight});

  final String tripId;
  final Flight? existingFlight;

  static Future<void> show(
    BuildContext context,
    String tripId, {
    Flight? existingFlight,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddFlightSheet(tripId: tripId, existingFlight: existingFlight),
    );
  }

  @override
  ConsumerState<AddFlightSheet> createState() => _AddFlightSheetState();
}

class _SegmentControllers {
  _SegmentControllers({
    String flightNumber = '',
    String originAirport = '',
    String destinationAirport = '',
    String departureIso = '',
    String arrivalIso = '',
    String originTimezone = 'Asia/Manila',
    String destinationTimezone = 'Asia/Manila',
    String terminal = '',
    String gate = '',
  }) : number = TextEditingController(text: flightNumber),
       origin = TextEditingController(text: originAirport),
       destination = TextEditingController(text: destinationAirport),
       departure = TextEditingController(text: departureIso),
       arrival = TextEditingController(text: arrivalIso),
       originZone = TextEditingController(text: originTimezone),
       destinationZone = TextEditingController(text: destinationTimezone),
       terminal = TextEditingController(text: terminal),
       gate = TextEditingController(text: gate);

  factory _SegmentControllers.fromSegment(FlightSegment segment) =>
      _SegmentControllers(
        flightNumber: segment.flightNumber,
        originAirport: segment.originAirport,
        destinationAirport: segment.destinationAirport,
        departureIso: segment.scheduledDepartureUtc.toUtc().toIso8601String(),
        arrivalIso: segment.scheduledArrivalUtc.toUtc().toIso8601String(),
        originTimezone: segment.originTimezone,
        destinationTimezone: segment.destinationTimezone,
        terminal: segment.terminal ?? '',
        gate: segment.gate ?? '',
      );

  final TextEditingController number;
  final TextEditingController origin;
  final TextEditingController destination;
  final TextEditingController departure;
  final TextEditingController arrival;
  final TextEditingController originZone;
  final TextEditingController destinationZone;
  final TextEditingController terminal;
  final TextEditingController gate;

  void dispose() {
    for (final controller in [
      number,
      origin,
      destination,
      departure,
      arrival,
      originZone,
      destinationZone,
      terminal,
      gate,
    ]) {
      controller.dispose();
    }
  }
}

class _AddFlightSheetState extends ConsumerState<AddFlightSheet> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationController = TextEditingController();
  late final TextEditingController _airline;
  late final TextEditingController _bookingReference;
  late final List<_SegmentControllers> _segments;
  bool _saving = false;

  bool get _isEditing => widget.existingFlight != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFlight;
    _airline = TextEditingController(text: existing?.airline ?? '');
    _bookingReference = TextEditingController(
      text: existing?.bookingReference ?? '',
    );
    if (existing != null && existing.segments.isNotEmpty) {
      _segments = existing.segments
          .map(_SegmentControllers.fromSegment)
          .toList();
    } else {
      _segments = [_SegmentControllers()];
    }
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    _airline.dispose();
    _bookingReference.dispose();
    for (final segment in _segments) {
      segment.dispose();
    }
    super.dispose();
  }

  void _addConnectingSegment() {
    if (_segments.length >= 8) return;
    final previous = _segments.last;
    final nextOrigin = previous.destination.text.trim().toUpperCase();
    final nextOriginZone = previous.destinationZone.text.trim().isNotEmpty
        ? previous.destinationZone.text.trim()
        : 'Asia/Manila';
    setState(() {
      _segments.add(
        _SegmentControllers(
          originAirport: nextOrigin,
          originTimezone: nextOriginZone,
          destinationTimezone: nextOriginZone,
        ),
      );
    });
  }

  void _removeSegment(int index) {
    if (_segments.length <= 1) return;
    setState(() {
      final removed = _segments.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final serializedSegments = <Map<String, dynamic>>[];

    for (var i = 0; i < _segments.length; i++) {
      final seg = _segments[i];
      final originCode = seg.origin.text.trim().toUpperCase();
      final destCode = seg.destination.text.trim().toUpperCase();
      if (originCode == destCode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Segment ${i + 1}: destination airport must differ from origin.',
            ),
          ),
        );
        return;
      }
      final departure = DateTime.tryParse(seg.departure.text.trim());
      final arrival = DateTime.tryParse(seg.arrival.text.trim());
      if (departure == null || arrival == null || !arrival.isAfter(departure)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arrival must be after departure.')),
        );
        return;
      }
      serializedSegments.add({
        'flight_number': seg.number.text.trim(),
        'origin_airport': originCode,
        'destination_airport': destCode,
        'scheduled_departure_utc': departure.toUtc().toIso8601String(),
        'scheduled_arrival_utc': arrival.toUtc().toIso8601String(),
        'origin_timezone': seg.originZone.text.trim(),
        'destination_timezone': seg.destinationZone.text.trim(),
        if (seg.terminal.text.trim().isNotEmpty)
          'terminal': seg.terminal.text.trim(),
        if (seg.gate.text.trim().isNotEmpty) 'gate': seg.gate.text.trim(),
      });
    }

    setState(() => _saving = true);
    try {
      await ref.read(flightListProvider(widget.tripId).notifier).save({
        'airline': _airline.text.trim().isEmpty ? null : _airline.text.trim(),
        if (_bookingReference.text.trim().isNotEmpty || _isEditing)
          'booking_reference': _bookingReference.text.trim().isEmpty
              ? null
              : _bookingReference.text.trim(),
        'segments': serializedSegments,
      }, existing: widget.existingFlight);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight could not be saved.')),
        );
      }
    }
  }

  Future<void> _deleteFlight() async {
    final existing = widget.existingFlight;
    if (existing == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(flightListProvider(widget.tripId).notifier)
          .remove(existing);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).maybePop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flight could not be deleted.')),
        );
      }
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
  String? _iata(String? value) =>
      RegExp(r'^[A-Za-z]{3}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Use a 3-letter airport code';

  Future<void> _importConfirmation() async {
    _confirmationController.clear();
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Paste flight confirmation'),
        content: TextField(
          key: const Key('flight_confirmation_input'),
          controller: _confirmationController,
          maxLines: 7,
          decoration: const InputDecoration(
            hintText: 'Paste your airline or booking confirmation text.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
              _confirmationController.text =
                  clipboard?.text ?? _confirmationController.text;
            },
            child: const Text('Paste'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final details = const FlightConfirmationParser().parse(
                _confirmationController.text,
              );
              final firstSegment = _segments.first;
              if (details.airline != null) {
                _airline.text = details.airline!;
              }
              if (details.bookingReference != null) {
                _bookingReference.text = details.bookingReference!;
              }
              if (details.flightNumber != null) {
                firstSegment.number.text = details.flightNumber!;
              }
              if (details.originAirport != null) {
                firstSegment.origin.text = details.originAirport!;
              }
              if (details.destinationAirport != null) {
                firstSegment.destination.text = details.destinationAirport!;
              }
              Navigator.of(dialogContext, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    details.hasContent
                        ? 'Details added. Review every field before saving.'
                        : 'No flight fields found. You can enter them manually.',
                  ),
                ),
              );
            },
            child: const Text('Review details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
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
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'Review or edit scheduled flight'
                            : 'Add scheduled flight',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        tooltip: 'Delete flight',
                        onPressed: _saving ? null : _deleteFlight,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colorScheme.error,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  'Enter confirmed booking details. Flight status is not live.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _importConfirmation,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Paste confirmation to fill details'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _airline,
                  decoration: const InputDecoration(labelText: 'Airline'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bookingReference,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Booking reference (private)',
                    helperText: 'Only the trip owner can view this reference.',
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _segments.length; i++) ...[
                  if (_segments.length > 1 || i > 0) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Segment ${i + 1}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_segments.length > 1)
                          TextButton.icon(
                            onPressed: () => _removeSegment(i),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                            label: Text('Remove segment ${i + 1}'),
                          ),
                      ],
                    ),
                  ],
                  TextFormField(
                    key: ValueKey('segment_${i}_flight_number'),
                    controller: _segments[i].number,
                    decoration: const InputDecoration(
                      labelText: 'Flight number',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('segment_${i}_origin'),
                          controller: _segments[i].origin,
                          decoration: const InputDecoration(
                            labelText: 'Origin IATA',
                          ),
                          validator: _iata,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('segment_${i}_destination'),
                          controller: _segments[i].destination,
                          decoration: const InputDecoration(
                            labelText: 'Destination IATA',
                          ),
                          validator: _iata,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('segment_${i}_departure'),
                    controller: _segments[i].departure,
                    decoration: const InputDecoration(
                      labelText: 'Departure (ISO 8601)',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('segment_${i}_arrival'),
                    controller: _segments[i].arrival,
                    decoration: const InputDecoration(
                      labelText: 'Arrival (ISO 8601)',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('segment_${i}_origin_zone'),
                    controller: _segments[i].originZone,
                    decoration: const InputDecoration(
                      labelText: 'Origin time zone',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: ValueKey('segment_${i}_destination_zone'),
                    controller: _segments[i].destinationZone,
                    decoration: const InputDecoration(
                      labelText: 'Destination time zone',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('segment_${i}_terminal'),
                          controller: _segments[i].terminal,
                          decoration: const InputDecoration(
                            labelText: 'Terminal (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('segment_${i}_gate'),
                          controller: _segments[i].gate,
                          decoration: const InputDecoration(
                            labelText: 'Gate (optional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_segments.length < 8) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _addConnectingSegment,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add connecting segment'),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.flight_takeoff_rounded),
                    label: Text(
                      _saving
                          ? 'Saving…'
                          : (_isEditing ? 'Update flight' : 'Save flight'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
