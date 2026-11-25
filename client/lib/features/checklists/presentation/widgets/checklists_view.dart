import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../circles/domain/models/circle_member.dart';
import '../../../circles/domain/models/trip_traveler.dart';
import '../../../circles/presentation/providers/trip_circle_provider.dart';
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
  String _selectedAssigneeFilter = 'all';
  int _activeChecklistIndex = 0;

  Future<void> _runChecklistAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException
          ? e.message
          : 'Unable to update checklist right now.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  bool _matchesAssigneeFilter(ChecklistItem item, String? currentUserId) {
    switch (_selectedAssigneeFilter) {
      case 'all':
        return true;
      case 'mine':
        return currentUserId != null && item.assignedUserId == currentUserId;
      case 'unassigned':
        return (item.assignedUserId == null || item.assignedUserId!.isEmpty) &&
            (item.assignedTravelerId == null ||
                item.assignedTravelerId!.isEmpty);
      default:
        if (_selectedAssigneeFilter.startsWith('member:')) {
          final targetId = _selectedAssigneeFilter.substring('member:'.length);
          return item.assignedUserId == targetId;
        }
        if (_selectedAssigneeFilter.startsWith('traveler:')) {
          final targetId = _selectedAssigneeFilter.substring(
            'traveler:'.length,
          );
          return item.assignedTravelerId == targetId;
        }
        return true;
    }
  }

  List<({String key, String label})> _buildAssigneeFilters(
    String? currentUserId,
    List<CircleMember> members,
    List<TripTraveler> travelers,
    List<ChecklistItem> items,
  ) {
    final filters = <({String key, String label})>[
      (key: 'all', label: 'All assignees'),
      if (currentUserId != null) (key: 'mine', label: 'Assigned to me'),
      (key: 'unassigned', label: 'Unassigned'),
    ];
    final seen = <String>{for (final f in filters) f.key};

    for (final m in members) {
      if (m.invitationStatus != 'accepted' ||
          m.userId.isEmpty ||
          m.userId == currentUserId) {
        continue;
      }
      final key = 'member:${m.userId}';
      if (seen.add(key)) {
        filters.add((key: key, label: m.displayName));
      }
    }

    for (final t in travelers) {
      if (t.id.isEmpty) continue;
      final key = 'traveler:${t.id}';
      if (seen.add(key)) {
        filters.add((key: key, label: t.displayName));
      }
    }

    for (final item in items) {
      if (item.assignedUserId != null &&
          item.assignedUserId!.isNotEmpty &&
          item.assignedUserId != currentUserId) {
        final key = 'member:${item.assignedUserId}';
        if (seen.add(key)) {
          filters.add((key: key, label: item.assigneeLabel ?? 'Member'));
        }
      } else if (item.assignedTravelerId != null &&
          item.assignedTravelerId!.isNotEmpty) {
        final key = 'traveler:${item.assignedTravelerId}';
        if (seen.add(key)) {
          filters.add((key: key, label: item.assigneeLabel ?? 'Traveler'));
        }
      }
    }

    return filters;
  }

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

  void _openAddItemSheet(
    Checklist checklist, {
    List<CircleMember> members = const [],
    List<TripTraveler> travelers = const [],
  }) {
    AddChecklistItemBottomSheet.show(
      context,
      checklistId: checklist.id,
      members: members,
      travelers: travelers,
      onSubmitWithAssignee:
          ({
            required String title,
            required String category,
            required int quantity,
            String? notes,
            String? photoUrl,
            String? assignedUserId,
            String? assignedTravelerId,
            bool clearAssignee = false,
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
                  assignedUserId: assignedUserId,
                  assignedTravelerId: assignedTravelerId,
                );
          },
    );
  }

  void _openEditItemSheet(
    Checklist checklist,
    ChecklistItem item, {
    List<CircleMember> members = const [],
    List<TripTraveler> travelers = const [],
  }) {
    AddChecklistItemBottomSheet.show(
      context,
      checklistId: checklist.id,
      initialItem: item,
      members: members,
      travelers: travelers,
      onSubmitWithAssignee:
          ({
            required String title,
            required String category,
            required int quantity,
            String? notes,
            String? photoUrl,
            String? assignedUserId,
            String? assignedTravelerId,
            bool clearAssignee = false,
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
                  assignedUserId: assignedUserId,
                  assignedTravelerId: assignedTravelerId,
                  clearAssignee: clearAssignee,
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
    final authState = ref.watch(authProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final members = currentUserId != null
        ? ref.watch(circleMembersProvider(widget.tripId)).asData?.value ??
              const <CircleMember>[]
        : const <CircleMember>[];
    final travelers = currentUserId != null
        ? ref.watch(tripTravelersProvider(widget.tripId)).asData?.value ??
              const <TripTraveler>[]
        : const <TripTraveler>[];

    CircleMember? selfMember;
    if (currentUserId != null) {
      for (final member in members) {
        if (member.userId == currentUserId) {
          selfMember = member;
          break;
        }
      }
    }
    final isViewerOnly = selfMember != null && selfMember.isViewer;
    final canManageChecklists = !isViewerOnly;

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
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant, width: 1),
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
                  canManageChecklists
                      ? 'Start organized by applying a pre-built starter packing pack or create your own custom checklist.'
                      : 'No packing lists have been shared for this trip yet. Organizers and editors can add lists and assign items to you.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (canManageChecklists) ...[
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
        final showAssigneeFilters =
            activeChecklist.items.any(
              (i) => i.assignedUserId != null || i.assignedTravelerId != null,
            ) ||
            members.length > 1 ||
            travelers.isNotEmpty;
        final assigneeFilters = showAssigneeFilters
            ? _buildAssigneeFilters(
                currentUserId,
                members,
                travelers,
                activeChecklist.items,
              )
            : const <({String key, String label})>[];
        final filteredItems = activeChecklist.items
            .where(
              (i) =>
                  (_selectedCategory == 'all' ||
                      i.category == _selectedCategory) &&
                  _matchesAssigneeFilter(i, currentUserId),
            )
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
                                _selectedAssigneeFilter = 'all';
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
                if (canManageChecklists) ...[
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
              ],
            ),
            const SizedBox(height: 12),

            if (isViewerOnly) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View-only access: you can check off items assigned to you.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

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
            if (showAssigneeFilters) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: assigneeFilters.map((filter) {
                    final selected = _selectedAssigneeFilter == filter.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.label),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _selectedAssigneeFilter = filter.key);
                        },
                        selectedColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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
                if (canManageChecklists)
                  TextButton.icon(
                    onPressed: () => _openAddItemSheet(
                      activeChecklist,
                      members: members,
                      travelers: travelers,
                    ),
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
                  final canToggle =
                      canManageChecklists ||
                      (currentUserId != null &&
                          item.assignedUserId == currentUserId);
                  return ChecklistItemTile(
                    item: item,
                    canToggle: canToggle,
                    canEdit: canManageChecklists,
                    onToggle: () => _runChecklistAction(
                      () => ref
                          .read(checklistListProvider(widget.tripId).notifier)
                          .toggleItem(item.id),
                    ),
                    onEdit: () => _openEditItemSheet(
                      activeChecklist,
                      item,
                      members: members,
                      travelers: travelers,
                    ),
                    onAttachPhoto: () => _openAttachPhotoDialog(item),
                    onDelete: () => _runChecklistAction(
                      () => ref
                          .read(checklistListProvider(widget.tripId).notifier)
                          .deleteItem(item.id),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
