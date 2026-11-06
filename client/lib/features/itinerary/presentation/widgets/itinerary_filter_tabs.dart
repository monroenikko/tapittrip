import 'package:flutter/material.dart';

class ItineraryFilterTabs extends StatelessWidget {
  const ItineraryFilterTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.tabs = const [
      'Itinerary',
      'Transport',
      'Stay',
      'Checklists',
      'Recommendations',
    ],
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tabs[index]),
              selected: isSelected,
              onSelected: (_) => onTabSelected(index),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }),
      ),
    );
  }
}
