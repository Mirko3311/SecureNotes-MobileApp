package org.unibl.etf.securenotes.service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;
import org.unibl.etf.securenotes.dto.auth.AccessTokenResponse;
import org.unibl.etf.securenotes.entity.MfaTransaction;
import org.unibl.etf.securenotes.entity.UserAccount;
import org.unibl.etf.securenotes.entity.UserStatus;

import java.time.Instant;
import java.util.UUID;


@Service
public class JwtTokenService {

    private static final String PRE_MFA_TOKEN_TYPE = "PRE_MFA";
    private static final String ACCESS_TOKEN_TYPE = "ACCESS_TOKEN";
    private final JwtEncoder jwtEncoder;
    private final String issuer;
    private final long accessTokenTtlSeconds;

    public JwtTokenService(
            JwtEncoder jwtEncoder,
            @Value("${security.jwt.issuer}") String issuer,
            @Value("${security.jwt.access-token-ttl-seconds}") long accessTokenTtlSeconds)
    {
        this.jwtEncoder = jwtEncoder;
        this.issuer = issuer;
        this.accessTokenTtlSeconds = accessTokenTtlSeconds;
    }

    public String createPreMfaToken(
            UserAccount userAccount,
            MfaTransaction mfaTransaction
    ) {
        Instant issuedAt = Instant.now();

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(userAccount.getId().toString())
                .issuedAt(issuedAt)
                .expiresAt(mfaTransaction.getExpiresAt())
                .id(UUID.randomUUID().toString())
                .claim("token_type", PRE_MFA_TOKEN_TYPE)
                .claim(
                        "mfa_transaction_id",
                        mfaTransaction.getId()
                )
                .claim(
                        "purpose",
                        mfaTransaction.getPurpose().name()
                )
                .build();

        JwsHeader header = JwsHeader
                .with(MacAlgorithm.HS256)
                .type("JWT")
                .build();

        return jwtEncoder
                .encode(
                        JwtEncoderParameters.from(header, claims)
                )
                .getTokenValue();
    }

    public AccessTokenResponse createAccessToken(UserAccount userAccount)
    {
        if (userAccount.getStatus() != UserStatus.ACTIVE)
        {
            throw new IllegalStateException("Access token se može izdati samo aktivnom korisniku.");
        }

        Instant issuedAt = Instant.now();

        Instant expiresAt = issuedAt.plusSeconds(accessTokenTtlSeconds);

        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(userAccount.getId().toString())
                .issuedAt(issuedAt)
                .expiresAt(expiresAt)
                .id(UUID.randomUUID().toString())
                .claim(
                        "token_type",
                        ACCESS_TOKEN_TYPE
                )
                .claim(
                        "mfa_verified",
                        true
                )
                .build();

        JwsHeader header = JwsHeader
                .with(MacAlgorithm.HS256)
                .type("JWT")
                .build();

        String accessToken = jwtEncoder
                .encode(
                        JwtEncoderParameters.from(
                                header,
                                claims
                        )
                )
                .getTokenValue();

        return new AccessTokenResponse(
                accessToken,
                "Bearer",
                expiresAt
        );
    }
}