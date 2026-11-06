import 'package:flutter/material.dart';

import '../../domain/models/luggage_profile.dart';

class LuggagePresetSelector extends StatelessWidget {
  const LuggagePresetSelector({
    super.key,
    required this.selectedPreset,
    required this.onPresetChanged,
    this.showDetails = false,
  });

  final String selectedPreset;
  final ValueChanged<LuggageProfile> onPresetChanged;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final presets = [
      (
        key: 'light',
        title: 'Travel Light',
        subtitle: '1 backpack',
        icon: Icons.backpack_rounded,
      ),
      (
        key: 'standard',
        title: '1–2 Suitcases',
        subtitle: 'Standard luggage',
        icon: Icons.luggage_rounded,
      ),
      (
        key: 'heavy',
        title: 'Heavy / Stroller',
        subtitle: '3+ bags or stroller',
        icon: Icons.child_friendly_rounded,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((p) {
            final isSelected =
                selectedPreset.toLowerCase() == p.key.toLowerCase();
            return ChoiceChip(
              avatar: Icon(
                p.icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(p.title),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerLow,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
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
              onSelected: (selected) {
                if (selected) {
                  onPresetChanged(LuggageProfile.fromPreset(p.key));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
