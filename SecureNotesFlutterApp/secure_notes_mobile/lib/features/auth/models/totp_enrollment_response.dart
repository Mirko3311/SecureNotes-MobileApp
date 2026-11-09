class TotpEnrollmentResponse {
  final String otpauthUri;
  final String manualEntryKey;
  final String issuer;
  final String accountName;
  final DateTime expiresAt;

  const TotpEnrollmentResponse({
    required this.otpauthUri,
    required this.manualEntryKey,
    required this.issuer,
    required this.accountName,
    required this.expiresAt,
  });

  factory TotpEnrollmentResponse.fromJson(Map<String, dynamic> json) {
    return TotpEnrollmentResponse(
      otpauthUri: json['otpauthUri'] as String,
      manualEntryKey: json['manualEntryKey'] as String,
      issuer: json['issuer'] as String,
      accountName: json['accountName'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
