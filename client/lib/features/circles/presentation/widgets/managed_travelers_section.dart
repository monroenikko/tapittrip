import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/models/trip_traveler.dart';
import '../providers/trip_circle_provider.dart';

class ManagedTravelersSection extends ConsumerWidget {
  const ManagedTravelersSection({
    required this.tripId,
    required this.canManageTravelers,
    super.key,
  });

  final String tripId;
  final bool canManageTravelers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final travelersAsync = ref.watch(tripTravelersProvider(tripId));

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Managed Travelers',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canManageTravelers)
                  FilledButton.tonalIcon(
                    onPressed: () => _openTravelerSheet(context, ref),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Add'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Add dependents or children for packing assignments without creating an account. Location and document sharing remain disabled.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            travelersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load managed travelers.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => ref
                        .read(tripTravelersProvider(tripId).notifier)
                        .refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (travelers) {
                if (travelers.isEmpty) {
                  return Text(
                    'No managed travelers added yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  );
                }

                return Column(
                  children: travelers
                      .map(
                        (traveler) => _TravelerTile(
                          traveler: traveler,
                          onEdit: traveler.canEdit
                              ? () => _openTravelerSheet(
                                  context,
                                  ref,
                                  existing: traveler,
                                )
                              : null,
                          onDelete: traveler.canDelete
                              ? () => _confirmDelete(context, ref, traveler)
                              : null,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTravelerSheet(
    BuildContext context,
    WidgetRef ref, {
    TripTraveler? existing,
  }) async {
    final nameController = TextEditingController(
      text: existing?.displayName ?? '',
    );
    final notesController = TextEditingController(
      text: existing?.restrictedNotes ?? '',
    );
    var category = existing?.travelerCategory ?? 'child';
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null
                      ? 'Add Managed Traveler'
                      : 'Edit Managed Traveler',
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'First Name or Nickname *',
                    hintText: 'e.g. Leo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                    DropdownMenuItem(value: 'infant', child: Text('Infant')),
                    DropdownMenuItem(value: 'adult', child: Text('Adult')),
                    DropdownMenuItem(
                      value: 'companion',
                      child: Text('Companion'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (val) {
                          if (val != null) {
                            setSheetState(() => category = val);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Private Notes (visible only to you)',
                    hintText: 'Optional allergies or care notes; never shared with other members.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) return;

                            setSheetState(() => saving = true);
                            final rawNotes = notesController.text.trim();
                            try {
                              final notifier = ref.read(
                                tripTravelersProvider(tripId).notifier,
                              );
                              if (existing == null) {
                                await notifier.createTraveler(
                                  displayName: name,
                                  travelerCategory: category,
                                  restrictedNotes: rawNotes.isNotEmpty
                                      ? rawNotes
                                      : null,
                                );
                              } else {
                                await notifier.updateTraveler(
                                  existing.id,
                                  displayName: name,
                                  travelerCategory: category,
                                  restrictedNotes: rawNotes,
                                  baseVersion: existing.version,
                                );
                              }
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            } on ApiException catch (e) {
                              setSheetState(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(existing == null ? 'Save Traveler' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TripTraveler traveler,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Managed Traveler?'),
        content: Text(
          'Remove "${traveler.displayName}"? Assigned packing tasks will become unassigned.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref
          .read(tripTravelersProvider(tripId).notifier)
          .deleteTraveler(traveler.id);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _TravelerTile extends StatelessWidget {
  const _TravelerTile({required this.traveler, this.onEdit, this.onDelete});

  final TripTraveler traveler;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        traveler.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        traveler.categoryLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Managed by ${traveler.managingUserName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (traveler.restrictedNotes != null &&
                    traveler.restrictedNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Private note: ${traveler.restrictedNotes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit traveler',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Remove traveler',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}
