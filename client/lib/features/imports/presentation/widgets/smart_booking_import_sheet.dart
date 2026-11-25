import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/booking_import_provider.dart';
import 'review_extracted_booking_dialog.dart';

class SmartBookingImportSheet extends ConsumerStatefulWidget {
  const SmartBookingImportSheet({super.key, required this.tripId});

  final String tripId;

  static Future<void> show(BuildContext context, String tripId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SmartBookingImportSheet(tripId: tripId),
    );
  }

  @override
  ConsumerState<SmartBookingImportSheet> createState() =>
      _SmartBookingImportSheetState();
}

class _SmartBookingImportSheetState
    extends ConsumerState<SmartBookingImportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String _selectedHint = 'auto';
  bool _isExtracting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleParse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isExtracting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(bookingImportRepositoryProvider);
      final bookingImport = await repo.createImport(
        widget.tripId,
        rawText: _textController.text.trim(),
        bookingType: _selectedHint == 'auto' ? null : _selectedHint,
        source: 'paste_text',
      );

      ref.invalidate(tripBookingImportsProvider(widget.tripId));

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss bottom sheet
        // Open review dialog immediately
        await ReviewExtractedBookingDialog.show(
          context,
          tripId: widget.tripId,
          bookingImport: bookingImport,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExtracting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart Booking Import',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Paste confirmation email or ticket details',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: theme.colorScheme.onErrorContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Booking Type',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'auto',
                    label: Text('Auto'),
                    icon: Icon(Icons.auto_awesome),
                  ),
                  ButtonSegment(
                    value: 'flight',
                    label: Text('Flight'),
                    icon: Icon(Icons.flight),
                  ),
                  ButtonSegment(
                    value: 'stay',
                    label: Text('Stay'),
                    icon: Icon(Icons.hotel),
                  ),
                  ButtonSegment(
                    value: 'activity',
                    label: Text('Activity'),
                    icon: Icon(Icons.local_activity),
                  ),
                ],
                selected: {_selectedHint},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedHint = set.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _textController,
                maxLines: 6,
                minLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste confirmation email, flight itinerary, hotel reservation, or tour ticket text here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please paste booking confirmation text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isExtracting ? null : _handleParse,
                icon: _isExtracting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(
                  _isExtracting ? 'Analyzing with AI...' : 'Parse with AI',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
