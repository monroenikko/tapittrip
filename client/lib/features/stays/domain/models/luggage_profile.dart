class LuggageProfile {
  const LuggageProfile({
    this.preset = 'standard',
    this.partySize = 1,
    this.backpacks = 1,
    this.carryOns = 1,
    this.checkedBags = 0,
    this.oversized = 0,
    this.stroller = false,
  });

  final String preset;
  final int partySize;
  final int backpacks;
  final int carryOns;
  final int checkedBags;
  final int oversized;
  final bool stroller;

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
        );
    }
  }

  factory LuggageProfile.fromJson(Map<String, dynamic> json) {
    return LuggageProfile(
      preset: json['preset'] as String? ?? 'standard',
      partySize: (json['party_size'] as num?)?.toInt() ?? 1,
      backpacks: (json['backpacks'] as num?)?.toInt() ?? 1,
      carryOns: (json['carry_ons'] as num?)?.toInt() ?? 1,
      checkedBags: (json['checked_bags'] as num?)?.toInt() ?? 0,
      oversized: (json['oversized'] as num?)?.toInt() ?? 0,
      stroller: json['stroller'] as bool? ?? false,
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
  }) {
    return LuggageProfile(
      preset: preset ?? this.preset,
      partySize: partySize ?? this.partySize,
      backpacks: backpacks ?? this.backpacks,
      carryOns: carryOns ?? this.carryOns,
      checkedBags: checkedBags ?? this.checkedBags,
      oversized: oversized ?? this.oversized,
      stroller: stroller ?? this.stroller,
    );
  }
}
