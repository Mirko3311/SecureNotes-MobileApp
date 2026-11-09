class RegisterResponse {
  final int id;
  final String email;
  final String status;
  final DateTime createdAt;

  const RegisterResponse({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
