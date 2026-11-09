package org.unibl.etf.securenotes.dto.auth;

import org.unibl.etf.securenotes.entity.UserStatus;

import java.time.Instant;

public record RegisterResponse(
        Long id,
        String email,
        UserStatus status,
        Instant createdAt
) {
}
