import 'package:flutter/material.dart';

import '../../domain/models/planning_mode.dart';

class PlanningModeSelector extends StatelessWidget {
  const PlanningModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  final PlanningMode selectedMode;
  final ValueChanged<PlanningMode> onModeSelected;

  IconData _iconForMode(PlanningMode mode) {
    return switch (mode) {
      PlanningMode.diy => Icons.explore_outlined,
      PlanningMode.existing => Icons.airplane_ticket_outlined,
      PlanningMode.guided => Icons.tour_outlined,
      PlanningMode.simple => Icons.backpack_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RadioGroup<PlanningMode>(
      groupValue: selectedMode,
      onChanged: (val) {
        if (val != null) onModeSelected(val);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your planning style',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...PlanningMode.values.map((mode) {
            final isSelected = mode == selectedMode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => onModeSelected(mode),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                        : colorScheme.surface,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForMode(mode),
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mode.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              mode.subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<PlanningMode>(
                        value: mode,
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
