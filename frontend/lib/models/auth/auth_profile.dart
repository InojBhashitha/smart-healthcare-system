class AuthProfile {
  final String name;
  final String email;
  final String role;

  AuthProfile({
    required this.name,
    required this.email,
    required this.role,
  });

  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    return AuthProfile(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }
}
