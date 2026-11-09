package org.unibl.etf.securenotes.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.unibl.etf.securenotes.dto.auth.TotpEnrollmentResponse;
import org.unibl.etf.securenotes.entity.MfaTransaction;
import org.unibl.etf.securenotes.entity.MfaTransactionPurpose;
import org.unibl.etf.securenotes.entity.MfaTransactionStatus;
import org.unibl.etf.securenotes.entity.TotpCredential;
import org.unibl.etf.securenotes.entity.UserAccount;
import org.unibl.etf.securenotes.entity.UserStatus;
import org.unibl.etf.securenotes.exception.InvalidMfaTransactionException;
import org.unibl.etf.securenotes.exception.MfaTransactionExpiredException;
import org.unibl.etf.securenotes.repository.MfaTransactionRepository;
import org.unibl.etf.securenotes.repository.TotpCredentialRepository;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Objects;
import java.util.Optional;

@Service
public class TotpEnrollmentService {

    private final MfaTransactionRepository mfaTransactionRepository;
    private final TotpCredentialRepository totpCredentialRepository;
    private final TotpService totpService;
    private final TotpSecretEncryptionService encryptionService;
    private final String issuer;

    public TotpEnrollmentService(
            MfaTransactionRepository mfaTransactionRepository,
            TotpCredentialRepository totpCredentialRepository,
            TotpService totpService,
            TotpSecretEncryptionService encryptionService,
            @Value("${security.totp.issuer}") String issuer
    ) {
        this.mfaTransactionRepository =
                mfaTransactionRepository;

        this.totpCredentialRepository =
                totpCredentialRepository;

        this.totpService =
                totpService;

        this.encryptionService =
                encryptionService;

        this.issuer =
                issuer;
    }

    @Transactional
    public TotpEnrollmentResponse startEnrollment(
            Long userId,
            Long mfaTransactionId
    ) {

        MfaTransaction mfaTransaction =
                mfaTransactionRepository
                        .findById(mfaTransactionId)
                        .orElseThrow(
                                InvalidMfaTransactionException::new
                        );
        validateEnrollmentTransaction(
                mfaTransaction,
                userId
        );

        UserAccount userAccount =
                mfaTransaction.getUserAccount();

        String plainSecret =
                obtainPendingSecret(userAccount);

        String otpauthUri =
                buildOtpAuthUri(
                        userAccount.getEmail(),
                        plainSecret
                );

        return new TotpEnrollmentResponse(
                otpauthUri,
                plainSecret,
                issuer,
                userAccount.getEmail(),
                mfaTransaction.getExpiresAt()
        );
    }

    private void validateEnrollmentTransaction(
            MfaTransaction mfaTransaction,
            Long userId
    ) {
        UserAccount userAccount =
                mfaTransaction.getUserAccount();

        boolean belongsToUser =
                Objects.equals(
                        userAccount.getId(),
                        userId
                );

        boolean correctPurpose =
                mfaTransaction.getPurpose()
                        == MfaTransactionPurpose.TOTP_ENROLLMENT;

        boolean transactionPending =
                mfaTransaction.getStatus()
                        == MfaTransactionStatus.PENDING;


        boolean userPendingMfa =
                userAccount.getStatus()
                        == UserStatus.PENDING_MFA;

        if(mfaTransaction.isExpired())
        {
            throw new MfaTransactionExpiredException();
        }
        if (!belongsToUser
                || !correctPurpose
                || !transactionPending
                || !userPendingMfa) {

            throw new InvalidMfaTransactionException();
        }
    }

    private String obtainPendingSecret(
            UserAccount userAccount
    ) {
        Optional<TotpCredential> existingCredential =
                totpCredentialRepository
                        .findByUserAccountId(
                                userAccount.getId()
                        );

        if (existingCredential.isEmpty()) {

            String plainSecret =
                    totpService.generateSecret();

            String encryptedSecret =
                    encryptionService.encrypt(
                            plainSecret
                    );

            TotpCredential newCredential =
                    new TotpCredential(
                            userAccount,
                            encryptedSecret
                    );

            totpCredentialRepository.saveAndFlush(
                    newCredential
            );

            return plainSecret;
        }

        TotpCredential credential =
                existingCredential.get();

        if (!credential.isPending()) {
            throw new IllegalStateException(
                    "Korisnik već ima TOTP kredencijal koji nije u stanju PENDING."
            );
        }

        return encryptionService.decrypt(
                credential.getEncryptedSecret()
        );
    }

    private String buildOtpAuthUri(
            String accountName,
            String secret
    ) {
        String label =
                issuer + ":" + accountName;

        return "otpauth://totp/"
                + urlEncode(label)
                + "?secret=" + urlEncode(secret)
                + "&issuer=" + urlEncode(issuer)
                + "&algorithm=SHA1"
                + "&digits=" + TotpService.CODE_DIGITS
                + "&period=" + TotpService.TIME_PERIOD_SECONDS;
    }

    private String urlEncode(String value) {
        return URLEncoder
                .encode(
                        value,
                        StandardCharsets.UTF_8
                )
                .replace("+", "%20");
    }
}