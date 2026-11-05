class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.locale = 'en',
    this.homeTimezone = 'UTC',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String locale;
  final String homeTimezone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName:
          (json['display_name'] as String?) ?? (json['name'] as String),
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      locale: (json['locale'] as String?) ?? 'en',
      homeTimezone: (json['home_timezone'] as String?) ?? 'UTC',
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
    'email': email,
    'avatar_url': avatarUrl,
    'locale': locale,
    'home_timezone': homeTimezone,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
