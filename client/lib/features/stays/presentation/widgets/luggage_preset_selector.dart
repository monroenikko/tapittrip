import 'package:flutter/material.dart';

import '../../domain/models/luggage_profile.dart';

class LuggagePresetSelector extends StatefulWidget {
  const LuggagePresetSelector({
    super.key,
    this.profile,
    this.selectedPreset,
    this.onPresetChanged,
    this.onProfileChanged,
  });

  final LuggageProfile? profile;
  final String? selectedPreset;
  final ValueChanged<LuggageProfile>? onPresetChanged;
  final ValueChanged<LuggageProfile>? onProfileChanged;

  @override
  State<LuggagePresetSelector> createState() => _LuggagePresetSelectorState();
}

class _LuggagePresetSelectorState extends State<LuggagePresetSelector> {
  late Set<String> _selectedCategories;
  late TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    final initialProfile =
        widget.profile ??
        (widget.selectedPreset != null
            ? LuggageProfile.fromPreset(widget.selectedPreset!)
            : LuggageProfile.fromPreset('standard'));

    _selectedCategories = Set.from(initialProfile.selectedCategories);
    _otherController = TextEditingController(
      text: initialProfile.otherDescription ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant LuggagePresetSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != null && widget.profile != oldWidget.profile) {
      setState(() {
        _selectedCategories = Set.from(widget.profile!.selectedCategories);
        if (_otherController.text != (widget.profile!.otherDescription ?? '')) {
          _otherController.text = widget.profile!.otherDescription ?? '';
        }
      });
    } else if (widget.selectedPreset != null &&
        widget.selectedPreset != oldWidget.selectedPreset) {
      final p = LuggageProfile.fromPreset(widget.selectedPreset!);
      setState(() {
        _selectedCategories = Set.from(p.selectedCategories);
      });
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final updatedProfile = LuggageProfile.fromCategories(
      _selectedCategories,
      partySize: widget.profile?.partySize ?? 1,
      otherDescription:
          _selectedCategories.contains('other') &&
              _otherController.text.trim().isNotEmpty
          ? _otherController.text.trim()
          : null,
    );

    widget.onProfileChanged?.call(updatedProfile);
    widget.onPresetChanged?.call(updatedProfile);
  }

  void _toggleCategory(String key, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedCategories.add(key);
      } else {
        _selectedCategories.remove(key);
      }
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categories = [
      (
        key: 'backpack',
        title: 'Backpack / Daypack',
        icon: Icons.backpack_rounded,
      ),
      (
        key: 'carry_on',
        title: 'Carry-on Suitcase',
        icon: Icons.luggage_rounded,
      ),
      (
        key: 'checked_bag',
        title: 'Checked Bag',
        icon: Icons.business_center_rounded,
      ),
      (
        key: 'stroller',
        title: 'Stroller / Baby Gear',
        icon: Icons.child_friendly_rounded,
      ),
      (
        key: 'oversized',
        title: 'Oversized / Sports',
        icon: Icons.sports_tennis_rounded,
      ),
      (key: 'other', title: 'Others', icon: Icons.more_horiz_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final isSelected = _selectedCategories.contains(c.key);
            return FilterChip(
              avatar: Icon(
                c.icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              label: Text(c.title),
              selected: isSelected,
              selectedColor: colorScheme.primary,
              checkmarkColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.surfaceContainerLow,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              onSelected: (selected) => _toggleCategory(c.key, selected),
            );
          }).toList(),
        ),

        // If "Others" is selected, show custom input
        if (_selectedCategories.contains('other')) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherController,
            decoration: InputDecoration(
              labelText: 'Specify Other Luggage',
              hintText: 'e.g. Pet carrier, musical instrument, camera hardcase',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ],
    );
  }
}
