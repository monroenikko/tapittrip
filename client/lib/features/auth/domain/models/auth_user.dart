class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.displayName,
    this.friendCode,
    this.acceptsDirectInvites = true,
    required this.email,
    this.avatarUrl,
    this.locale = 'en',
    this.homeTimezone = 'UTC',
    this.homeCountry,
    this.homeCurrency,
    this.permanentAddress,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String displayName;
  final String? friendCode;
  final bool acceptsDirectInvites;
  final String email;
  final String? avatarUrl;
  final String locale;
  final String homeTimezone;
  final String? homeCountry;
  final String? homeCurrency;
  final String? permanentAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthUser copyWith({
    String? id,
    String? name,
    String? displayName,
    String? friendCode,
    bool? acceptsDirectInvites,
    String? email,
    String? avatarUrl,
    String? locale,
    String? homeTimezone,
    String? homeCountry,
    String? homeCurrency,
    String? permanentAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      friendCode: friendCode ?? this.friendCode,
      acceptsDirectInvites: acceptsDirectInvites ?? this.acceptsDirectInvites,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale ?? this.locale,
      homeTimezone: homeTimezone ?? this.homeTimezone,
      homeCountry: homeCountry ?? this.homeCountry,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName:
          (json['display_name'] as String?) ?? (json['name'] as String),
      friendCode: json['friend_code'] as String?,
      acceptsDirectInvites: (json['accepts_direct_invites'] as bool?) ?? true,
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      locale: (json['locale'] as String?) ?? 'en',
      homeTimezone: (json['home_timezone'] as String?) ?? 'UTC',
      homeCountry: json['home_country'] as String?,
      homeCurrency: json['home_currency'] as String?,
      permanentAddress: json['permanent_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'display_name': displayName,
    'friend_code': friendCode,
    'accepts_direct_invites': acceptsDirectInvites,
    'email': email,
    'avatar_url': avatarUrl,
    'locale': locale,
    'home_timezone': homeTimezone,
    'home_country': homeCountry,
    'home_currency': homeCurrency,
    'permanent_address': permanentAddress,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
