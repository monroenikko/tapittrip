import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/booking_import.dart';
import '../providers/booking_import_provider.dart';
import '../widgets/review_extracted_booking_dialog.dart';
import '../widgets/smart_booking_import_sheet.dart';

class TripInboxPage extends ConsumerWidget {
  const TripInboxPage({super.key, required this.tripId});

  final String tripId;

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'flight':
        return Icons.flight;
      case 'stay':
        return Icons.hotel;
      case 'activity':
        return Icons.local_activity;
      default:
        return Icons.confirmation_number_outlined;
    }
  }

  Color _colorForType(String type, BuildContext context) {
    final theme = Theme.of(context);
    switch (type.toLowerCase()) {
      case 'flight':
        return Colors.blue.shade700;
      case 'stay':
        return Colors.indigo.shade700;
      case 'activity':
        return Colors.teal.shade700;
      default:
        return theme.colorScheme.primary;
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    BookingImport item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dismiss Import?'),
        content: const Text(
          'Are you sure you want to dismiss this booking confirmation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(bookingImportRepositoryProvider).deleteImport(item.id);
      ref.invalidate(tripBookingImportsProvider(tripId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking import removed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importsAsync = ref.watch(tripBookingImportsProvider(tripId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Inbox',
            onPressed: () => ref.invalidate(tripBookingImportsProvider(tripId)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => SmartBookingImportSheet.show(context, tripId),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Import Booking'),
      ),
      body: importsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load trip inbox',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(tripBookingImportsProvider(tripId)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (imports) {
          if (imports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.move_to_inbox,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Trip Inbox is Empty',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste any flight confirmation email, hotel booking, or tour ticket to automatically extract and add it to your trip itinerary.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () =>
                          SmartBookingImportSheet.show(context, tripId),
                      icon: const Icon(Icons.paste),
                      label: const Text('Paste Booking Text'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pending = imports.where((i) => !i.isConfirmed).toList();
          final confirmed = imports.where((i) => i.isConfirmed).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.pending_actions, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ready to Review (${pending.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...pending.map((item) {
                  final typeColor = _colorForType(item.bookingType, context);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: typeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _iconForType(item.bookingType),
                                  color: typeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.typeLabel,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: typeColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      item.summary,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                tooltip: 'Dismiss',
                                onPressed: () =>
                                    _handleDelete(context, ref, item),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.confidencePercentText} confidence',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    ReviewExtractedBookingDialog.show(
                                      context,
                                      tripId: tripId,
                                      bookingImport: item,
                                    ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Review & Add'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              if (confirmed.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Imported to Trip (${confirmed.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...confirmed.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 14,
                        child: Icon(Icons.check, size: 16, color: Colors.white),
                      ),
                      title: Text(
                        item.summary,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Added to ${item.typeLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 80), // Space for FAB
            ],
          );
        },
      ),
    );
  }
}
