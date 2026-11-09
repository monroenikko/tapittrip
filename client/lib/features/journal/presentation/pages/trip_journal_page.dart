import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trips/presentation/providers/trip_list_provider.dart';
import '../../domain/models/journal_entry.dart';
import '../providers/journal_provider.dart';
import '../widgets/add_journal_entry_sheet.dart';
import '../widgets/journal_entry_card.dart';

class TripJournalPage extends ConsumerStatefulWidget {
  const TripJournalPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripJournalPage> createState() => _TripJournalPageState();
}

class _TripJournalPageState extends ConsumerState<TripJournalPage> {
  String _activeFilter = 'all'; // 'all', 'private', 'shared'

  void _openAddEntrySheet({JournalEntry? existingEntry}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddJournalEntrySheet(
        tripId: widget.tripId,
        existingEntry: existingEntry,
        onSave:
            ({
              required String title,
              required String content,
              required String entryDate,
              String? locationName,
              String? weather,
              String? mood,
              required bool isShared,
              List<String>? photos,
            }) async {
              final notifier = ref.read(
                tripJournalProvider(widget.tripId).notifier,
              );
              if (existingEntry != null) {
                await notifier.updateEntry(
                  existingEntry.id,
                  title: title,
                  content: content,
                  entryDate: entryDate,
                  locationName: locationName,
                  weather: weather,
                  mood: mood,
                  isShared: isShared,
                  photos: photos,
                );
              } else {
                await notifier.createEntry(
                  title: title,
                  content: content,
                  entryDate: entryDate,
                  locationName: locationName,
                  weather: weather,
                  mood: mood,
                  isShared: isShared,
                  photos: photos,
                );
              }
            },
      ),
    );
  }

  void _confirmDeleteEntry(JournalEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reflection?'),
        content: Text(
          'Are you sure you want to delete "${entry.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(tripJournalProvider(widget.tripId).notifier)
                  .deleteEntry(entry.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPhotoDialog(JournalEntry entry) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Photo to Memory'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Photo URL or Path',
            hintText: 'https://example.com/photo.jpg',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.of(context).pop();
                final updatedPhotos = [...entry.photos, url];
                await ref
                    .read(tripJournalProvider(widget.tripId).notifier)
                    .updateEntry(entry.id, photos: updatedPhotos);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final trips = ref.watch(tripListProvider).asData?.value;
    final trip = trips?.where((t) => t.id == widget.tripId).firstOrNull;
    final tripTitle = trip?.title ?? 'Trip Journal';

    final journalAsync = ref.watch(tripJournalProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Travel Memories & Journal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              tripTitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Journal',
            onPressed: () =>
                ref.read(tripJournalProvider(widget.tripId).notifier).refresh(),
          ),
        ],
      ),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load memories: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref
                    .read(tripJournalProvider(widget.tripId).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (entries) {
          final totalCount = entries.length;
          final sharedCount = entries.where((e) => e.isShared).length;
          final privateCount = totalCount - sharedCount;

          final filteredEntries = entries.where((e) {
            if (_activeFilter == 'private') return !e.isShared;
            if (_activeFilter == 'shared') return e.isShared;
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(tripJournalProvider(widget.tripId).notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                // Top Stats Summary
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📖', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip Travel Log',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Personal reflections & shared circle moments',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              context,
                              label: 'Total Moments',
                              count: totalCount,
                              icon: Icons.auto_stories_rounded,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              context,
                              label: 'Shared Circle',
                              count: sharedCount,
                              icon: Icons.group_rounded,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 8),
                            _buildStatCard(
                              context,
                              label: 'Only You',
                              count: privateCount,
                              icon: Icons.lock_outline_rounded,
                              color: Colors.amber.shade800,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All ($totalCount)'),
                          selected: _activeFilter == 'all',
                          onSelected: (_) =>
                              setState(() => _activeFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(Icons.group_rounded, size: 16),
                          label: Text('Shared ($sharedCount)'),
                          selected: _activeFilter == 'shared',
                          onSelected: (_) =>
                              setState(() => _activeFilter = 'shared'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          avatar: const Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                          ),
                          label: Text('Only You ($privateCount)'),
                          selected: _activeFilter == 'private',
                          onSelected: (_) =>
                              setState(() => _activeFilter = 'private'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Empty State or List of Cards
                if (filteredEntries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              entries.isEmpty
                                  ? 'No memories captured yet'
                                  : 'No $_activeFilter reflections found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entries.isEmpty
                                  ? 'Capture your thoughts, mood, weather, and photos from this journey. Private by default.'
                                  : 'Try changing your filter to see other travel reflections.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (entries.isEmpty) ...[
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => _openAddEntrySheet(),
                                icon: const Icon(Icons.add),
                                label: const Text('Capture First Reflection'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = filteredEntries[index];
                      return JournalEntryCard(
                        entry: entry,
                        onToggleShare: () => ref
                            .read(tripJournalProvider(widget.tripId).notifier)
                            .toggleShare(entry),
                        onEdit: () => _openAddEntrySheet(existingEntry: entry),
                        onDelete: () => _confirmDeleteEntry(entry),
                        onAddPhoto: () => _showAddPhotoDialog(entry),
                      );
                    }, childCount: filteredEntries.length),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntrySheet(),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New Memory'),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
