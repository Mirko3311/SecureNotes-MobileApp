class LoginResponse {
  final String preMfaToken;
  final String tokenType;
  final String purpose;
  final DateTime expiresAt;

  const LoginResponse({
    required this.preMfaToken,
    required this.tokenType,
    required this.purpose,
    required this.expiresAt,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      preMfaToken: json['preMfaToken'] as String,
      tokenType: json['tokenType'] as String,
      purpose: json['purpose'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}