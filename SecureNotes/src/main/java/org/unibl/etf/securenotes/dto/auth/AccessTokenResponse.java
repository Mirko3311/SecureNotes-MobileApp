package org.unibl.etf.securenotes.dto.auth;

import java.time.Instant;

public record AccessTokenResponse(String accessToken, String tokenType, Instant expiresAt)
{ }
