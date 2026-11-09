package org.unibl.etf.securenotes.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.unibl.etf.securenotes.dto.auth.AccessTokenResponse;
import org.unibl.etf.securenotes.entity.*;
import org.unibl.etf.securenotes.exception.InvalidMfaTransactionException;
import org.unibl.etf.securenotes.exception.InvalidTotpCodeException;
import org.unibl.etf.securenotes.repository.MfaTransactionRepository;
import org.unibl.etf.securenotes.repository.TotpCredentialRepository;
import java.util.OptionalLong;
import java.util.Objects;

@Service
public class TotpEnrollmentVerificationService {

    private final MfaTransactionRepository
            mfaTransactionRepository;

    private final TotpCredentialRepository
            totpCredentialRepository;

    private final TotpSecretEncryptionService
            encryptionService;

    private final TotpService totpService;

    private final JwtTokenService jwtTokenService;

    public TotpEnrollmentVerificationService(
            MfaTransactionRepository
                    mfaTransactionRepository,
            TotpCredentialRepository
                    totpCredentialRepository,
            TotpSecretEncryptionService
                    encryptionService,
            TotpService totpService,
            JwtTokenService jwtTokenService
    ) {
        this.mfaTransactionRepository =
                mfaTransactionRepository;

        this.totpCredentialRepository =
                totpCredentialRepository;

        this.encryptionService =
                encryptionService;

        this.totpService =
                totpService;

        this.jwtTokenService =
                jwtTokenService;
    }

    @Transactional(
            noRollbackFor =
                    InvalidTotpCodeException.class
    )
    public AccessTokenResponse verifyEnrollment(
            Long userId,
            Long mfaTransactionId,
            String submittedCode
    ) {
        MfaTransaction mfaTransaction =
                mfaTransactionRepository
                        .findById(mfaTransactionId)
                        .orElseThrow(InvalidMfaTransactionException::new);
        validateEnrollmentTransaction(
                mfaTransaction,
                userId
        );

        UserAccount userAccount =
                mfaTransaction.getUserAccount();

        TotpCredential totpCredential =
                totpCredentialRepository
                        .findByUserAccountIdAndStatus(
                                userAccount.getId(),
                                TotpCredentialStatus.PENDING
                        )
                        .orElseThrow(
                                InvalidMfaTransactionException::new
                        );

        String plainSecret =
                encryptionService.decrypt(
                        totpCredential
                                .getEncryptedSecret()
                );

        OptionalLong matchedTimeStep =
                totpService.findMatchingTimeStep(
                        plainSecret,
                        submittedCode
                );
        if (matchedTimeStep.isEmpty()
                || totpCredential.isTimeStepAlreadyUsed(
                matchedTimeStep.getAsLong()
        )) {
            registerFailedAttempt(
                    mfaTransaction
            );
        }

        totpCredential.markTimeStepUsed(
                matchedTimeStep.getAsLong()
        );
        totpCredential.activate();
        userAccount.activate();
        mfaTransaction.complete();

        return jwtTokenService.createAccessToken(
                userAccount
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
                        == MfaTransactionPurpose
                        .TOTP_ENROLLMENT;

        boolean transactionPending =
                mfaTransaction.getStatus()
                        == MfaTransactionStatus.PENDING;

        boolean transactionExpired =
                mfaTransaction.isExpired();

        boolean attemptsRemaining =
                mfaTransaction
                        .hasAttemptsRemaining();

        boolean userPendingMfa =
                userAccount.getStatus()
                        == UserStatus.PENDING_MFA;

        if (!belongsToUser
                || !correctPurpose
                || !transactionPending
                || transactionExpired
                || !attemptsRemaining
                || !userPendingMfa) {

            throw new InvalidMfaTransactionException();
        }
    }

    private void registerFailedAttempt(
            MfaTransaction mfaTransaction
    ) {
        mfaTransaction.registerFailedAttempt();

        int remainingAttempts =
                Math.max(
                        0,
                        mfaTransaction.getMaxAttempts()
                                - mfaTransaction
                                .getFailedAttempts()
                );

        throw new InvalidTotpCodeException(remainingAttempts);

    }
}