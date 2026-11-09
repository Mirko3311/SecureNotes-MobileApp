package org.unibl.etf.securenotes.service;


import dev.samstevens.totp.code.CodeGenerator;
// import dev.samstevens.totp.code.CodeVerifier;
import dev.samstevens.totp.code.DefaultCodeGenerator;
// import dev.samstevens.totp.code.DefaultCodeVerifier;
import dev.samstevens.totp.code.HashingAlgorithm;
import dev.samstevens.totp.exceptions.CodeGenerationException;
import dev.samstevens.totp.secret.DefaultSecretGenerator;
import dev.samstevens.totp.secret.SecretGenerator;
import dev.samstevens.totp.time.SystemTimeProvider;
import dev.samstevens.totp.time.TimeProvider;
import org.springframework.stereotype.Service;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.OptionalLong;
import java.util.regex.Pattern;

@Service
public class TotpService {

    public static final int SECRET_LENGTH = 32;

    public static final int CODE_DIGITS = 6;

    public static final int TIME_PERIOD_SECONDS = 30;

    public static final int ALLOWED_TIME_PERIOD_DISCREPANCY = 1;

    private static final Pattern CODE_PATTERN =
            Pattern.compile("[0-9]{6}");
    private final SecretGenerator secretGenerator;
    private final CodeGenerator codeGenerator;
    private final TimeProvider timeProvider;
    //private final CodeVerifier codeVerifier;

    public TotpService() {

        this.secretGenerator =
                new DefaultSecretGenerator(SECRET_LENGTH);
        this.codeGenerator =
                new DefaultCodeGenerator(
                        HashingAlgorithm.SHA1,
                        CODE_DIGITS
                );

        this.timeProvider =
                new SystemTimeProvider();
       /* DefaultCodeVerifier verifier =
                new DefaultCodeVerifier(
                        codeGenerator,
                        timeProvider
                );
        verifier.setTimePeriod(
                TIME_PERIOD_SECONDS
        );

        verifier.setAllowedTimePeriodDiscrepancy(
                ALLOWED_TIME_PERIOD_DISCREPANCY
        );

        this.codeVerifier = verifier;*/

    }

    public String generateSecret() {
        return secretGenerator.generate();
    }
/*
    public boolean verifyCode(
            String secret,
            String submittedCode
    ) {
        validateSecret(secret);

        if (submittedCode == null) {
            return false;
        }

        String normalizedCode =
                submittedCode.trim();

        if (!CODE_PATTERN.matcher(normalizedCode).matches()) {
            return false;
        }

        return codeVerifier.isValidCode(
                secret,
                normalizedCode
        );
    }
    public String generateCurrentCode(String secret) {

        validateSecret(secret);

        long currentTimeSeconds =
                timeProvider.getTime();

        long currentTimeCounter =
                Math.floorDiv(
                        currentTimeSeconds,
                        TIME_PERIOD_SECONDS
                );

        try {
            return codeGenerator.generate(
                    secret,
                    currentTimeCounter
            );
        } catch (CodeGenerationException exception) {
            throw new IllegalStateException(
                    "Generisanje TOTP koda nije uspjelo.",
                    exception
            );
        }
    }

    */

    /*
     * Provjerava TOTP kod i vraća vremenski korak (T) kojem kod odgovara.
     * Provjeravaju se T-1, T i T+1. Ako kod nije ispravan, vraća prazno.
     */
    public OptionalLong findMatchingTimeStep(
            String secret,
            String submittedCode
    ) {
        validateSecret(secret);

        if (submittedCode == null) {
            return OptionalLong.empty();
        }

        String normalizedCode = submittedCode.trim();

        if (!CODE_PATTERN.matcher(normalizedCode).matches()) {
            return OptionalLong.empty();
        }

        byte[] submittedBytes =
                normalizedCode.getBytes(StandardCharsets.US_ASCII);

        long currentTimeStep = getCurrentTimeStep();
        OptionalLong matchedTimeStep = OptionalLong.empty();

        for (int offset = -ALLOWED_TIME_PERIOD_DISCREPANCY;
             offset <= ALLOWED_TIME_PERIOD_DISCREPANCY;
             offset++) {

            long candidateTimeStep = currentTimeStep + offset;

            byte[] expectedBytes =
                    generateCode(secret, candidateTimeStep)
                            .getBytes(StandardCharsets.US_ASCII);

            // Poređenje u konstantnom vremenu.
            if (MessageDigest.isEqual(expectedBytes, submittedBytes)
                    && matchedTimeStep.isEmpty()) {
                matchedTimeStep = OptionalLong.of(candidateTimeStep);
            }
        }

        return matchedTimeStep;
    }

    public boolean verifyCode(String secret, String submittedCode) {
        return findMatchingTimeStep(secret, submittedCode).isPresent();
    }

    public String generateCurrentCode(String secret) {
        validateSecret(secret);
        return generateCode(secret, getCurrentTimeStep());
    }

    private long getCurrentTimeStep() {
        return Math.floorDiv(
                timeProvider.getTime(),
                TIME_PERIOD_SECONDS
        );
    }

    private String generateCode(String secret, long timeStep) {
        try {
            return codeGenerator.generate(secret, timeStep);
        } catch (CodeGenerationException exception) {
            throw new IllegalStateException(
                    "Generisanje TOTP koda nije uspjelo.",
                    exception
            );
        }
    }

    private void validateSecret(String secret) {

        if (secret == null || secret.isBlank()) {
            throw new IllegalArgumentException(
                    "TOTP tajna ne smije biti prazna."
            );
        }
    }
}