package org.unibl.etf.securenotes.entity;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "mfa_transactions")
public class MfaTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(
            fetch = FetchType.LAZY,
            optional = false
    )
    @JoinColumn(
            name = "user_id",
            nullable = false
    )
    private UserAccount userAccount;

    @Enumerated(EnumType.STRING)
    @Column(
            name = "purpose",
            nullable = false,
            length = 30
    )
    private MfaTransactionPurpose purpose;

    @Enumerated(EnumType.STRING)
    @Column(
            name = "status",
            nullable = false,
            length = 20
    )
    private MfaTransactionStatus status;

    @Column(
            name = "failed_attempts",
            nullable = false
    )
    private int failedAttempts;

    @Column(
            name = "max_attempts",
            nullable = false
    )
    private int maxAttempts;

    @Column(
            name = "expires_at",
            nullable = false
    )
    private Instant expiresAt;

    @Column(
            name = "created_at",
            nullable = false,
            updatable = false
    )
    private Instant createdAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Version
    @Column(name = "version", nullable = false)
    private Long version;
    protected MfaTransaction() {
    }

    public MfaTransaction(
            UserAccount userAccount,
            MfaTransactionPurpose purpose,
            Instant expiresAt,
            int maxAttempts
    ) {
        if (userAccount == null) {
            throw new IllegalArgumentException(
                    "Korisnički nalog je obavezan."
            );
        }

        if (purpose == null) {
            throw new IllegalArgumentException(
                    "Svrha MFA transakcije je obavezna."
            );
        }

        if (expiresAt == null || !expiresAt.isAfter(Instant.now())) {
            throw new IllegalArgumentException(
                    "Vrijeme isteka mora biti u budućnosti."
            );
        }

        if (maxAttempts <= 0) {
            throw new IllegalArgumentException(
                    "Maksimalan broj pokušaja mora biti veći od nule."
            );
        }

        this.userAccount = userAccount;
        this.purpose = purpose;
        this.expiresAt = expiresAt;
        this.maxAttempts = maxAttempts;
        this.failedAttempts = 0;
        this.status = MfaTransactionStatus.PENDING;
    }
    @PrePersist
    private void beforeInsert() {
        this.createdAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public UserAccount getUserAccount() {
        return userAccount;
    }

    public MfaTransactionPurpose getPurpose() {
        return purpose;
    }

    public MfaTransactionStatus getStatus() {
        return status;
    }

    public int getFailedAttempts() {
        return failedAttempts;
    }

    public int getMaxAttempts() {
        return maxAttempts;
    }

    public Instant getExpiresAt() {
        return expiresAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public boolean isExpired() {
        return !Instant.now().isBefore(expiresAt);
    }

    public boolean hasAttemptsRemaining() {
        return failedAttempts < maxAttempts;
    }

    private void ensurePendingAndNotExpired() {

        if (status != MfaTransactionStatus.PENDING) {
            throw new IllegalStateException(
                    "MFA transakcija više nije aktivna."
            );
        }

        if (isExpired()) {
            throw new IllegalStateException(
                    "MFA transakcija je istekla."
            );
        }
    }
    public void registerFailedAttempt() {

        ensurePendingAndNotExpired();

        failedAttempts++;

        if (failedAttempts >= maxAttempts) {
            status = MfaTransactionStatus.LOCKED;
        }
    }

    public void markExpired() {
        if (status == MfaTransactionStatus.PENDING  && isExpired()) {
            status = MfaTransactionStatus.EXPIRED;
        }
    }

    public void complete() {

        ensurePendingAndNotExpired();

        status = MfaTransactionStatus.COMPLETED;
        completedAt = Instant.now();
    }
}