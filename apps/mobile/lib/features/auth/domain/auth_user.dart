class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.emailVerified,
    required this.hasYandex,
    required this.hasPasskey,
    required this.isGuest,
  });

  final String id;
  final String displayName;
  final String email;
  final bool emailVerified;
  final bool hasYandex;
  final bool hasPasskey;
  final bool isGuest;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Участник',
      email: json['email'] as String? ?? '',
      emailVerified: json['email_verified'] as bool? ?? false,
      hasYandex: json['has_yandex'] as bool? ?? false,
      hasPasskey: json['has_passkey'] as bool? ?? false,
      isGuest: json['is_guest'] as bool? ?? true,
    );
  }
}
