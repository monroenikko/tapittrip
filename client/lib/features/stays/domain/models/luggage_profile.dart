class LuggageProfile {
  const LuggageProfile({
    this.preset = 'standard',
    this.partySize = 1,
    this.backpacks = 1,
    this.carryOns = 1,
    this.checkedBags = 0,
    this.oversized = 0,
    this.stroller = false,
    this.selectedCategories = const {'carry_on', 'backpack'},
    this.otherDescription,
  });

  final String preset;
  final int partySize;
  final int backpacks;
  final int carryOns;
  final int checkedBags;
  final int oversized;
  final bool stroller;
  final Set<String> selectedCategories;
  final String? otherDescription;

  bool hasCategory(String category) => selectedCategories.contains(category);

  factory LuggageProfile.fromPreset(String preset, {int partySize = 1}) {
    switch (preset.toLowerCase()) {
      case 'light':
        return LuggageProfile(
          preset: 'light',
          partySize: partySize,
          backpacks: 1,
          carryOns: 0,
          checkedBags: 0,
          oversized: 0,
          stroller: false,
          selectedCategories: const {'backpack'},
        );
      case 'heavy':
        return LuggageProfile(
          preset: 'heavy',
          partySize: partySize,
          backpacks: 2,
          carryOns: 2,
          checkedBags: 3,
          oversized: 1,
          stroller: true,
          selectedCategories: const {
            'backpack',
            'carry_on',
            'checked_bag',
            'stroller',
          },
        );
      case 'standard':
      default:
        return LuggageProfile(
          preset: 'standard',
          partySize: partySize,
          backpacks: 1,
          carryOns: 1,
          checkedBags: 1,
          oversized: 0,
          stroller: false,
          selectedCategories: const {'backpack', 'carry_on', 'checked_bag'},
        );
    }
  }

  factory LuggageProfile.fromCategories(
    Set<String> categories, {
    int partySize = 1,
    String? otherDescription,
  }) {
    final hasBackpack = categories.contains('backpack');
    final hasCarryOn = categories.contains('carry_on');
    final hasChecked = categories.contains('checked_bag');
    final hasStroller = categories.contains('stroller');
    final hasOversized = categories.contains('oversized');

    String calculatedPreset = 'standard';
    if (hasStroller || hasChecked || hasOversized) {
      calculatedPreset = 'heavy';
    } else if (hasCarryOn) {
      calculatedPreset = 'standard';
    } else if (hasBackpack) {
      calculatedPreset = 'light';
    }

    return LuggageProfile(
      preset: calculatedPreset,
      partySize: partySize,
      backpacks: hasBackpack ? 1 : 0,
      carryOns: hasCarryOn ? 1 : 0,
      checkedBags: hasChecked ? 2 : 0,
      oversized: hasOversized ? 1 : 0,
      stroller: hasStroller,
      selectedCategories: categories,
      otherDescription: otherDescription,
    );
  }

  factory LuggageProfile.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['selected_categories'];
    Set<String> categories = const {'backpack', 'carry_on'};
    if (rawCategories is List) {
      categories = rawCategories.map((e) => e.toString()).toSet();
    } else {
      // Deduce from counts if not present
      final set = <String>{};
      if (((json['backpacks'] as num?)?.toInt() ?? 0) > 0) {
        set.add('backpack');
      }
      if (((json['carry_ons'] as num?)?.toInt() ?? 0) > 0) {
        set.add('carry_on');
      }
      if (((json['checked_bags'] as num?)?.toInt() ?? 0) > 0) {
        set.add('checked_bag');
      }
      if (json['stroller'] == true) set.add('stroller');
      if (((json['oversized'] as num?)?.toInt() ?? 0) > 0) {
        set.add('oversized');
      }
      if (json['other_description'] != null) set.add('other');
      if (set.isNotEmpty) categories = set;
    }

    return LuggageProfile(
      preset: json['preset'] as String? ?? 'standard',
      partySize: (json['party_size'] as num?)?.toInt() ?? 1,
      backpacks: (json['backpacks'] as num?)?.toInt() ?? 1,
      carryOns: (json['carry_ons'] as num?)?.toInt() ?? 1,
      checkedBags: (json['checked_bags'] as num?)?.toInt() ?? 0,
      oversized: (json['oversized'] as num?)?.toInt() ?? 0,
      stroller: json['stroller'] as bool? ?? false,
      selectedCategories: categories,
      otherDescription: json['other_description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset,
      'party_size': partySize,
      'backpacks': backpacks,
      'carry_ons': carryOns,
      'checked_bags': checkedBags,
      'oversized': oversized,
      'stroller': stroller,
      'selected_categories': selectedCategories.toList(),
      if (otherDescription != null) 'other_description': otherDescription,
    };
  }

  LuggageProfile copyWith({
    String? preset,
    int? partySize,
    int? backpacks,
    int? carryOns,
    int? checkedBags,
    int? oversized,
    bool? stroller,
    Set<String>? selectedCategories,
    String? otherDescription,
  }) {
    return LuggageProfile(
      preset: preset ?? this.preset,
      partySize: partySize ?? this.partySize,
      backpacks: backpacks ?? this.backpacks,
      carryOns: carryOns ?? this.carryOns,
      checkedBags: checkedBags ?? this.checkedBags,
      oversized: oversized ?? this.oversized,
      stroller: stroller ?? this.stroller,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      otherDescription: otherDescription ?? this.otherDescription,
    );
  }
}
