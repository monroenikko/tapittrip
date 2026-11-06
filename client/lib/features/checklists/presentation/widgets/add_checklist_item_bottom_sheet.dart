import 'package:flutter/material.dart';

import '../../domain/models/checklist_item.dart';

class AddChecklistItemBottomSheet extends StatefulWidget {
  const AddChecklistItemBottomSheet({
    super.key,
    required this.checklistId,
    this.initialItem,
    required this.onSubmit,
  });

  final String checklistId;
  final ChecklistItem? initialItem;
  final Future<void> Function({
    required String title,
    required String category,
    required int quantity,
    String? notes,
  })
  onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String checklistId,
    ChecklistItem? initialItem,
    required Future<void> Function({
      required String title,
      required String category,
      required int quantity,
      String? notes,
    })
    onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddChecklistItemBottomSheet(
        checklistId: checklistId,
        initialItem: initialItem,
        onSubmit: onSubmit,
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

  late String _selectedCategory;
  late int _quantity;
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
    _selectedCategory = widget.initialItem?.category ?? 'other';
    _quantity = widget.initialItem?.quantity ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        quantity: _quantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
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
