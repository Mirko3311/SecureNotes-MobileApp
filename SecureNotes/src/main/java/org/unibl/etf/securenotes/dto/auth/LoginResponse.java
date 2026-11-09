package org.unibl.etf.securenotes.dto.auth;

import org.unibl.etf.securenotes.entity.MfaTransactionPurpose;

import java.time.Instant;

public record LoginResponse(
        String preMfaToken,
        String tokenType,
        MfaTransactionPurpose purpose,
        Instant expiresAt
){}
