class AccessTokenResponse {
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;

  const AccessTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresAt,
  });

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return AccessTokenResponse(
      accessToken: json['accessToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
