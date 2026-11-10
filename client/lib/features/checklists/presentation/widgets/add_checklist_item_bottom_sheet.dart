import 'package:flutter/material.dart';

import '../../../circles/domain/models/circle_member.dart';
import '../../../circles/domain/models/trip_traveler.dart';
import '../../domain/models/checklist_item.dart';

typedef ChecklistItemSubmitCallback = Future<void> Function({
  required String title,
  required String category,
  required int quantity,
  String? notes,
  String? photoUrl,
});

typedef ChecklistItemAssignedSubmitCallback = Future<void> Function({
  required String title,
  required String category,
  required int quantity,
  String? notes,
  String? photoUrl,
  String? assignedUserId,
  String? assignedTravelerId,
  bool clearAssignee,
});

class AddChecklistItemBottomSheet extends StatefulWidget {
  const AddChecklistItemBottomSheet({
    super.key,
    required this.checklistId,
    this.initialItem,
    this.members = const [],
    this.travelers = const [],
    this.onSubmit,
    this.onSubmitWithAssignee,
  }) : assert(
         onSubmit != null || onSubmitWithAssignee != null,
         'Either onSubmit or onSubmitWithAssignee must be provided.',
       );

  final String checklistId;
  final ChecklistItem? initialItem;
  final List<CircleMember> members;
  final List<TripTraveler> travelers;
  final ChecklistItemSubmitCallback? onSubmit;
  final ChecklistItemAssignedSubmitCallback? onSubmitWithAssignee;

  static Future<void> show(
    BuildContext context, {
    required String checklistId,
    ChecklistItem? initialItem,
    List<CircleMember> members = const [],
    List<TripTraveler> travelers = const [],
    ChecklistItemSubmitCallback? onSubmit,
    ChecklistItemAssignedSubmitCallback? onSubmitWithAssignee,
  }) {
    assert(
      onSubmit != null || onSubmitWithAssignee != null,
      'Either onSubmit or onSubmitWithAssignee must be provided.',
    );
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddChecklistItemBottomSheet(
        checklistId: checklistId,
        initialItem: initialItem,
        members: members,
        travelers: travelers,
        onSubmit: onSubmit,
        onSubmitWithAssignee: onSubmitWithAssignee,
      ),
    );
  }

  @override
  State<AddChecklistItemBottomSheet> createState() =>
      _AddChecklistItemBottomSheetState();
}

class _AddChecklistItemBottomSheetState
    extends State<AddChecklistItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _photoUrlController;

  late String _selectedCategory;
  late int _quantity;
  String? _selectedAssigneeKey;
  bool _isSubmitting = false;

  static const List<Map<String, dynamic>> _categories = [
    {'key': 'documents', 'label': 'Documents'},
    {'key': 'clothing', 'label': 'Clothing'},
    {'key': 'electronics', 'label': 'Electronics'},
    {'key': 'toiletries', 'label': 'Toiletries'},
    {'key': 'health', 'label': 'Health'},
    {'key': 'gear', 'label': 'Gear'},
    {'key': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialItem?.title ?? '',
    );
    _notesController = TextEditingController(
      text: widget.initialItem?.notes ?? '',
    );
    _photoUrlController = TextEditingController(
      text: widget.initialItem?.photoUrl ?? '',
    );
    _selectedCategory = widget.initialItem?.category ?? 'other';
    _quantity = widget.initialItem?.quantity ?? 1;
    final assignedUserId = widget.initialItem?.assignedUserId;
    final assignedTravelerId = widget.initialItem?.assignedTravelerId;
    if (assignedUserId != null && assignedUserId.isNotEmpty) {
      _selectedAssigneeKey = 'member:$assignedUserId';
    } else if (assignedTravelerId != null && assignedTravelerId.isNotEmpty) {
      _selectedAssigneeKey = 'traveler:$assignedTravelerId';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final hadAssignee =
          (widget.initialItem?.assignedUserId?.isNotEmpty ?? false) ||
          (widget.initialItem?.assignedTravelerId?.isNotEmpty ?? false);
      String? assignedUserId;
      String? assignedTravelerId;
      var clearAssignee = false;
      if (_selectedAssigneeKey != null) {
        if (_selectedAssigneeKey!.startsWith('member:')) {
          assignedUserId = _selectedAssigneeKey!.substring('member:'.length);
        } else if (_selectedAssigneeKey!.startsWith('traveler:')) {
          assignedTravelerId = _selectedAssigneeKey!.substring(
            'traveler:'.length,
          );
        }
      } else if (hadAssignee) {
        clearAssignee = true;
      }

      final title = _titleController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      final photoUrl = _photoUrlController.text.trim().isEmpty
          ? null
          : _photoUrlController.text.trim();

      if (widget.onSubmitWithAssignee != null) {
        await widget.onSubmitWithAssignee!(
          title: title,
          category: _selectedCategory,
          quantity: _quantity,
          notes: notes,
          photoUrl: photoUrl,
          assignedUserId: assignedUserId,
          assignedTravelerId: assignedTravelerId,
          clearAssignee: clearAssignee,
        );
      } else {
        await widget.onSubmit!(
          title: title,
          category: _selectedCategory,
          quantity: _quantity,
          notes: notes,
          photoUrl: photoUrl,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildAssigneeDropdown() {
    final seenKeys = <String>{};
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Unassigned (Anyone)'),
      ),
    ];

    for (final member in widget.members) {
      if (member.invitationStatus != 'accepted' || member.userId.isEmpty) {
        continue;
      }
      final key = 'member:${member.userId}';
      if (seenKeys.add(key)) {
        items.add(
          DropdownMenuItem<String?>(
            value: key,
            child: Text(
              '${member.displayName} (${member.roleLabel})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    for (final traveler in widget.travelers) {
      if (traveler.id.isEmpty) continue;
      final key = 'traveler:${traveler.id}';
      if (seenKeys.add(key)) {
        items.add(
          DropdownMenuItem<String?>(
            value: key,
            child: Text(
              '${traveler.displayName} (${traveler.categoryLabel})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    if (_selectedAssigneeKey != null &&
        !seenKeys.contains(_selectedAssigneeKey)) {
      items.add(
        DropdownMenuItem<String?>(
          value: _selectedAssigneeKey,
          child: Text(
            widget.initialItem?.assigneeLabel ?? 'Assigned traveler',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: _selectedAssigneeKey,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Assign to (optional)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        prefixIcon: const Icon(Icons.person_outline_rounded),
      ),
      items: items,
      onChanged: _isSubmitting
          ? null
          : (value) => setState(() => _selectedAssigneeKey = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.initialItem != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Item' : 'Add Item to Pack',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Passport, Power Bank, Rain Jacket',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.check_box_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector Chips
              Text(
                'Category',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final key = cat['key'] as String;
                  final label = cat['label'] as String;
                  final isSelected = _selectedCategory == key;

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = key);
                    },
                    selectedColor: colorScheme.primary,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Quantity Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantity',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$_quantity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        onPressed: _quantity < 99
                            ? () => setState(() => _quantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g., Pack in personal carry-on item',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // Photo URL Field
              TextFormField(
                controller: _photoUrlController,
                decoration: InputDecoration(
                  labelText: 'Photo or Document URL (optional)',
                  hintText: 'https://... or sample receipt link',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: const Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
              if (widget.members.isNotEmpty ||
                  widget.travelers.isNotEmpty ||
                  _selectedAssigneeKey != null) ...[
                const SizedBox(height: 16),
                _buildAssigneeDropdown(),
              ],
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isEditing ? Icons.check_rounded : Icons.add_rounded,
                        ),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Add to List',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
