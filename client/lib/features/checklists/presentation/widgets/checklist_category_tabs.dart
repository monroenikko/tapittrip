import 'package:flutter/material.dart';

class ChecklistCategoryTabs extends StatelessWidget {
  const ChecklistCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts = const {},
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final Map<String, int> categoryCounts;

  static const List<Map<String, dynamic>> categories = [
    {'key': 'all', 'label': 'All', 'icon': Icons.grid_view_rounded},
    {
      'key': 'documents',
      'label': 'Documents',
      'icon': Icons.description_outlined,
    },
    {'key': 'clothing', 'label': 'Clothing', 'icon': Icons.checkroom_outlined},
    {
      'key': 'electronics',
      'label': 'Electronics',
      'icon': Icons.devices_other_outlined,
    },
    {
      'key': 'toiletries',
      'label': 'Toiletries',
      'icon': Icons.sanitizer_outlined,
    },
    {
      'key': 'health',
      'label': 'Health',
      'icon': Icons.medical_services_outlined,
    },
    {'key': 'gear', 'label': 'Gear', 'icon': Icons.hiking_outlined},
    {'key': 'other', 'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final key = cat['key'] as String;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = selectedCategory == key;
          final count = categoryCounts[key];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              label: Text(
                count != null && count > 0 ? '$label ($count)' : label,
              ),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(key),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          );
        }).toList(),
      ),
    );
  }
}
