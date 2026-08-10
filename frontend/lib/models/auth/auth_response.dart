class AuthResponse {
  final String token;
  final String message;
  final String name;
  final String email;

  AuthResponse({
    required this.token,
    required this.message,
    required this.name,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      message: json['message'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
