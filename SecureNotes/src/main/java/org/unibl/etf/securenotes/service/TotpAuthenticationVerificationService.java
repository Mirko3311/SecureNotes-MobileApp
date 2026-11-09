package org.unibl.etf.securenotes.service;

/*ovo radi sa vec aktivnim korisnikom*/
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.unibl.etf.securenotes.dto.auth.AccessTokenResponse;
import org.unibl.etf.securenotes.entity.MfaTransaction;
import org.unibl.etf.securenotes.entity.MfaTransactionPurpose;
import org.unibl.etf.securenotes.entity.MfaTransactionStatus;
import org.unibl.etf.securenotes.entity.TotpCredential;
import org.unibl.etf.securenotes.entity.TotpCredentialStatus;
import org.unibl.etf.securenotes.entity.UserAccount;
import org.unibl.etf.securenotes.entity.UserStatus;
import org.unibl.etf.securenotes.exception.InvalidMfaTransactionException;
import org.unibl.etf.securenotes.exception.InvalidTotpCodeException;
import org.unibl.etf.securenotes.repository.MfaTransactionRepository;
import org.unibl.etf.securenotes.repository.TotpCredentialRepository;
import java.util.OptionalLong;
import java.util.Objects;

@Service
public class TotpAuthenticationVerificationService {

    private final MfaTransactionRepository
            mfaTransactionRepository;

    private final TotpCredentialRepository
            totpCredentialRepository;

    private final TotpSecretEncryptionService
            encryptionService;

    private final TotpService
            totpService;

    private final JwtTokenService
            jwtTokenService;

    public TotpAuthenticationVerificationService(
            MfaTransactionRepository mfaTransactionRepository,
            TotpCredentialRepository totpCredentialRepository,
            TotpSecretEncryptionService encryptionService,
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
            noRollbackFor = InvalidTotpCodeException.class
    )
    public AccessTokenResponse verifyAuthentication(
            Long userId,
            Long mfaTransactionId,
            String submittedCode
    ) {
        MfaTransaction mfaTransaction =
                mfaTransactionRepository
                        .findById(mfaTransactionId)
                        .orElseThrow(
                                InvalidMfaTransactionException::new
                        );

        validateAuthenticationTransaction(
                mfaTransaction,
                userId
        );

        UserAccount userAccount =
                mfaTransaction.getUserAccount();

        TotpCredential totpCredential =
                totpCredentialRepository
                        .findByUserAccountIdAndStatus(
                                userAccount.getId(),
                                TotpCredentialStatus.ACTIVE
                        )
                        .orElseThrow(
                                InvalidMfaTransactionException::new
                        );

        String plainSecret =
                encryptionService.decrypt(
                        totpCredential.getEncryptedSecret()
                );

      /*  boolean codeValid =
                totpService.verifyCode(
                        plainSecret,
                        submittedCode
                );

        if (!codeValid) {
            registerFailedAttempt(
                    mfaTransaction
            );
        }*/
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
        mfaTransaction.complete();

        return jwtTokenService.createAccessToken(
                userAccount
        );
    }

    private void validateAuthenticationTransaction(
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
                        .TOTP_AUTHENTICATION;

        boolean transactionPending =
                mfaTransaction.getStatus()
                        == MfaTransactionStatus.PENDING;

        boolean transactionExpired =
                mfaTransaction.isExpired();

        boolean attemptsRemaining =
                mfaTransaction.hasAttemptsRemaining();

        boolean userActive =
                userAccount.getStatus()
                        == UserStatus.ACTIVE;

        if (!belongsToUser
                || !correctPurpose
                || !transactionPending
                || transactionExpired
                || !attemptsRemaining
                || !userActive) {

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

        throw new InvalidTotpCodeException(
                remainingAttempts
        );
    }
}