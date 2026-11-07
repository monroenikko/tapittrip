import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/checklist.dart';
import '../../domain/models/checklist_item.dart';
import '../providers/checklist_provider.dart';
import 'add_checklist_item_bottom_sheet.dart';
import 'checklist_category_tabs.dart';
import 'checklist_item_tile.dart';
import 'checklist_progress_card.dart';
import 'checklist_template_dialog.dart';

class ChecklistsView extends ConsumerStatefulWidget {
  const ChecklistsView({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<ChecklistsView> createState() => _ChecklistsViewState();
}

class _ChecklistsViewState extends ConsumerState<ChecklistsView> {
  String _selectedCategory = 'all';
  int _activeChecklistIndex = 0;

  void _showCreateChecklistDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Checklist'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Checklist Title',
            hintText: 'e.g., Carry-on Essentials, Documents',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref
                    .read(checklistListProvider(widget.tripId).notifier)
                    .createChecklist(title: text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openAddItemSheet(Checklist checklist) {
    AddChecklistItemBottomSheet.show(
      context,
      checklistId: checklist.id,
      onSubmit:
          ({
            required String title,
            required String category,
            required int quantity,
            String? notes,
            String? photoUrl,
          }) async {
            await ref
                .read(checklistListProvider(widget.tripId).notifier)
                .addItem(
                  checklistId: checklist.id,
                  title: title,
                  category: category,
                  quantity: quantity,
                  notes: notes,
                  photoUrl: photoUrl,
                );
          },
    );
  }

  void _openEditItemSheet(Checklist checklist, ChecklistItem item) {
    AddChecklistItemBottomSheet.show(
      context,
      checklistId: checklist.id,
      initialItem: item,
      onSubmit:
          ({
            required String title,
            required String category,
            required int quantity,
            String? notes,
            String? photoUrl,
          }) async {
            await ref
                .read(checklistListProvider(widget.tripId).notifier)
                .updateItem(
                  itemId: item.id,
                  title: title,
                  category: category,
                  quantity: quantity,
                  notes: notes,
                  photoUrl: photoUrl,
                );
          },
    );
  }

  void _openAttachPhotoDialog(ChecklistItem item) {
    final photoController = TextEditingController(text: item.photoUrl ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Attach Photo to "${item.title}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a photo or document URL for quick offline preview:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: photoController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Image / Document URL',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final url = photoController.text.trim();
              Navigator.of(ctx).pop();
              await ref
                  .read(checklistListProvider(widget.tripId).notifier)
                  .updateItem(
                    itemId: item.id,
                    photoUrl: url.isNotEmpty ? url : null,
                  );
            },
            child: const Text('Save Photo'),
          ),
        ],
      ),
    );
  }

  void _openTemplatesDialog() {
    ChecklistTemplateDialog.show(
      context,
      onSelectTemplate: (templateKey) async {
        await ref
            .read(checklistListProvider(widget.tripId).notifier)
            .applyTemplate(templateKey);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checklistsAsync = ref.watch(checklistListProvider(widget.tripId));

    return checklistsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Could not load checklists',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(checklistListProvider(widget.tripId).notifier)
                    .refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (checklists) {
        if (checklists.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: 36,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Packing Lists Yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start organized by applying a pre-built starter packing pack or create your own custom checklist.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openTemplatesDialog,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Browse Starter Packs'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showCreateChecklistDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Custom List'),
                  ),
                ),
              ],
            ),
          );
        }

        // Ensure active index is within range
        if (_activeChecklistIndex >= checklists.length) {
          _activeChecklistIndex = 0;
        }

        final activeChecklist = checklists[_activeChecklistIndex];

        // Compute counts per category
        final categoryCounts = <String, int>{
          'all': activeChecklist.items.length,
        };
        for (final item in activeChecklist.items) {
          categoryCounts[item.category] =
              (categoryCounts[item.category] ?? 0) + 1;
        }

        // Filter items
        final filteredItems = _selectedCategory == 'all'
            ? activeChecklist.items
            : activeChecklist.items
                  .where((i) => i.category == _selectedCategory)
                  .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Selector Tabs & Actions
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(checklists.length, (index) {
                        final list = checklists[index];
                        final isSelected = _activeChecklistIndex == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(list.title),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _activeChecklistIndex = index;
                                _selectedCategory = 'all';
                              });
                            },
                            selectedColor: colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Starter Packs',
                  icon: const Icon(Icons.auto_awesome_rounded),
                  onPressed: _openTemplatesDialog,
                ),
                IconButton(
                  tooltip: 'New List',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: _showCreateChecklistDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Card
            ChecklistProgressCard(
              totalItems: activeChecklist.totalItemsCount,
              packedItems: activeChecklist.packedItemsCount,
              progressPercentage: activeChecklist.progressPercentage,
              checklistTitle: activeChecklist.title,
            ),
            const SizedBox(height: 16),

            // Category Filter Tabs
            ChecklistCategoryTabs(
              selectedCategory: _selectedCategory,
              onCategorySelected: (cat) =>
                  setState(() => _selectedCategory = cat),
              categoryCounts: categoryCounts,
            ),
            const SizedBox(height: 12),

            // Add item quick button & list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredItems.length} ${_selectedCategory == 'all' ? 'total' : _selectedCategory} items',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openAddItemSheet(activeChecklist),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Item List
            if (filteredItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 32,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No items in this category',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (ctx, index) {
                  final item = filteredItems[index];
                  return ChecklistItemTile(
                    item: item,
                    onToggle: () {
                      ref
                          .read(checklistListProvider(widget.tripId).notifier)
                          .toggleItem(item.id);
                    },
                    onEdit: () => _openEditItemSheet(activeChecklist, item),
                    onAttachPhoto: () => _openAttachPhotoDialog(item),
                    onDelete: () {
                      ref
                          .read(checklistListProvider(widget.tripId).notifier)
                          .deleteItem(item.id);
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
