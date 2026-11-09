package org.unibl.etf.securenotes.controller;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.unibl.etf.securenotes.dto.auth.AccessTokenResponse;
import org.unibl.etf.securenotes.dto.auth.TotpCodeRequest;
import org.unibl.etf.securenotes.dto.auth.TotpEnrollmentResponse;
import org.unibl.etf.securenotes.exception.InvalidPreMfaTokenException;
import org.unibl.etf.securenotes.service.TotpAuthenticationVerificationService;
import org.unibl.etf.securenotes.service.TotpEnrollmentService;
import org.unibl.etf.securenotes.service.TotpEnrollmentVerificationService;

@RestController
@RequestMapping("/api/auth/totp")
public class TotpController {

    private final TotpEnrollmentService totpEnrollmentService;
    private final TotpEnrollmentVerificationService totpEnrollmentVerificationService;
    private final TotpAuthenticationVerificationService totpAuthenticationVerificationService;
    public TotpController(
            TotpEnrollmentService totpEnrollmentService, TotpEnrollmentVerificationService totpEnrollmentVerificationService, TotpAuthenticationVerificationService totpAuthenticationVerificationService
    ) {
        this.totpEnrollmentService =
                totpEnrollmentService;

        this.totpEnrollmentVerificationService = totpEnrollmentVerificationService;
        this.totpAuthenticationVerificationService = totpAuthenticationVerificationService;
    }

    @PostMapping("/enrollment")
    public ResponseEntity<TotpEnrollmentResponse>
    startEnrollment(
            @AuthenticationPrincipal Jwt jwt
    ) {
        Long userId =
                extractUserId(jwt);

        Long mfaTransactionId =
                extractMfaTransactionId(jwt);

        TotpEnrollmentResponse response =
                totpEnrollmentService.startEnrollment(
                        userId,
                        mfaTransactionId
                );

        return ResponseEntity.ok(response);
    }

    @PostMapping("/authentication/verify")
    public ResponseEntity<AccessTokenResponse>
    verifyAuthentication(
            @AuthenticationPrincipal Jwt jwt,
            @Valid
            @RequestBody
            TotpCodeRequest request
    ) {
        Long userId =
                extractUserId(jwt);

        Long mfaTransactionId =
                extractMfaTransactionId(jwt);

        AccessTokenResponse response =
                totpAuthenticationVerificationService
                        .verifyAuthentication(
                                userId,
                                mfaTransactionId,
                                request.code()
                        );

        return ResponseEntity.ok(response);
    }
    @PostMapping("/enrollment/verify")
    public ResponseEntity<AccessTokenResponse>
    verifyEnrollment(
            @AuthenticationPrincipal Jwt jwt,
            @Valid
            @RequestBody
            TotpCodeRequest request
    ) {
        Long userId =
                extractUserId(jwt);

        Long mfaTransactionId =
                extractMfaTransactionId(jwt);

        AccessTokenResponse response =
                totpEnrollmentVerificationService
                        .verifyEnrollment(
                                userId,
                                mfaTransactionId,
                                request.code()
                        );

        return ResponseEntity.ok(response);
    }
    private Long extractUserId(Jwt jwt) {

        if (jwt == null) {
            throw new InvalidPreMfaTokenException();
        }

        String subject = jwt.getSubject();

        if (subject == null || subject.isBlank()) {
            throw new InvalidPreMfaTokenException();
        }

        try {
            long userId =
                    Long.parseLong(subject);

            if (userId <= 0) {
                throw new InvalidPreMfaTokenException();
            }

            return userId;

        } catch (NumberFormatException exception) {
            throw new InvalidPreMfaTokenException();
        }
    }

    private Long extractMfaTransactionId(Jwt jwt) {

        Object claimValue =
                jwt.getClaim(
                        "mfa_transaction_id"
                );

        if (!(claimValue instanceof Number number)) {
            throw new InvalidPreMfaTokenException();
        }

        long transactionId =
                number.longValue();

        if (transactionId <= 0) {
            throw new InvalidPreMfaTokenException();
        }

        return transactionId;
    }
}