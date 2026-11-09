package org.unibl.etf.securenotes.service;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.unibl.etf.securenotes.dto.auth.LoginRequest;
import org.unibl.etf.securenotes.dto.auth.LoginResponse;
import org.unibl.etf.securenotes.dto.auth.RegisterRequest;
import org.unibl.etf.securenotes.dto.auth.RegisterResponse;
import org.unibl.etf.securenotes.entity.*;
import org.unibl.etf.securenotes.exception.EmailAlreadyRegisteredException;
import org.unibl.etf.securenotes.exception.InvalidCredentialsException;
import org.unibl.etf.securenotes.exception.LoginTemporarilyLockedException;
import org.unibl.etf.securenotes.repository.MfaTransactionRepository;
import org.unibl.etf.securenotes.repository.TotpCredentialRepository;
import org.unibl.etf.securenotes.repository.UserAccountRepository;

import java.time.Duration;
import java.time.Instant;
import java.util.Locale;

@Service
public class AuthService {

    private final UserAccountRepository userAccountRepository;
    private final PasswordEncoder passwordEncoder;
    private final MfaTransactionRepository mfaTransactionRepository;
    private final JwtTokenService jwtTokenService;
    private final TotpCredentialRepository totpCredentialRepository;
    private static final int MAX_FAILED_LOGIN_ATTEMPTS = 5;
    private static final Duration LOGIN_LOCK_DURATION = Duration.ofMinutes(15);
    public AuthService(
            UserAccountRepository userAccountRepository,
            PasswordEncoder passwordEncoder, MfaTransactionRepository mfaTransactionRepository, JwtTokenService jwtTokenService, TotpCredentialRepository totpCredentialRepository
    ) {
        this.userAccountRepository = userAccountRepository;
        this.passwordEncoder = passwordEncoder;
        this.mfaTransactionRepository = mfaTransactionRepository;
        this.jwtTokenService = jwtTokenService;
        this.totpCredentialRepository = totpCredentialRepository;
    }

    @Transactional
    public RegisterResponse register(RegisterRequest request) {

        String normalizedEmail = request.email()
                .trim()
                .toLowerCase(Locale.ROOT);

        if (userAccountRepository.existsByEmail(normalizedEmail)) {
            throw new EmailAlreadyRegisteredException();
        }

        String passwordHash =
                passwordEncoder.encode(request.password());

        UserAccount userAccount = new UserAccount(
                normalizedEmail,
                passwordHash,
                UserStatus.PENDING_MFA
        );

        UserAccount savedUser;
        try {
            savedUser =
                    userAccountRepository.saveAndFlush(userAccount);
        } catch(DataIntegrityViolationException exception)
        {
            throw new EmailAlreadyRegisteredException();
        }
        return new RegisterResponse(
                savedUser.getId(),
                savedUser.getEmail(),
                savedUser.getStatus(),
                savedUser.getCreatedAt()
        );
    }

    @Transactional(noRollbackFor = InvalidCredentialsException.class)
    public LoginResponse login(LoginRequest request)
    {
        String normalizedEmail = request.email().trim().toLowerCase(Locale.ROOT);
        UserAccount userAccount = userAccountRepository.findByEmail(normalizedEmail).orElseThrow(InvalidCredentialsException::new);
        Instant now = Instant.now();
        if(userAccount.isLoginLocked(now))
        {
            throw new LoginTemporarilyLockedException();
        }
        boolean passwordMatches = passwordEncoder.matches(request.password(),userAccount.getPasswordHash());
        if(!passwordMatches)
        {
            userAccount.registerFailedLogin(now,MAX_FAILED_LOGIN_ATTEMPTS, LOGIN_LOCK_DURATION);
            throw new InvalidCredentialsException();
        }
        userAccount.resetFailedLogins();
        if(userAccount.getStatus() == UserStatus.DISABLED)
        {
            throw new InvalidCredentialsException();
        }

        MfaTransactionPurpose purpose;
        if(userAccount.getStatus() == UserStatus.PENDING_MFA)
        {
            purpose = MfaTransactionPurpose.TOTP_ENROLLMENT;
        } else if(userAccount.getStatus() == UserStatus.ACTIVE)
        {
            boolean hasActiveTotp = totpCredentialRepository.existsByUserAccountIdAndStatus(userAccount.getId(), TotpCredentialStatus.ACTIVE);

            if(!hasActiveTotp)
            {
                throw new IllegalStateException("Aktivan korisnik nema aktivan TOTP autentifikacioni zapis.");
            }

           purpose =  MfaTransactionPurpose.TOTP_AUTHENTICATION;
        } else
        {
            throw new InvalidCredentialsException();
        }

        Instant expiresAt = Instant.now().plusSeconds(300);

        MfaTransaction mfaTransaction = new MfaTransaction(userAccount,purpose,expiresAt,5);

        MfaTransaction savedTransaction = mfaTransactionRepository.saveAndFlush(mfaTransaction);
        String preMfaToken = jwtTokenService.createPreMfaToken(userAccount,savedTransaction);
        return new LoginResponse(
                preMfaToken,
                "Bearer",
                savedTransaction.getPurpose(),
                savedTransaction.getExpiresAt()
        );
    }
}