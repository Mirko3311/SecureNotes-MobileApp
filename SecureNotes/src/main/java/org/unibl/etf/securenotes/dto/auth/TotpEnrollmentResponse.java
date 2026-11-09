package org.unibl.etf.securenotes.dto.auth;

import java.time.Instant;

public record TotpEnrollmentResponse(
    String otpauthUri,
    String manualEntryKey,
    String issuer,
    String accountName,
    Instant expiresAt
){}
