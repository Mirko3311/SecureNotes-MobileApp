package org.unibl.etf.securenotes.entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(
        name = "totp_credentials",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_totp_credentials_user_id",
                        columnNames = "user_id"
                )
        }
)
public class TotpCredential {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private UserAccount userAccount;

    @Column(name = "encrypted_secret", nullable = false, length = 512)
    private String encryptedSecret;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TotpCredentialStatus status;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "activated_at")
    private Instant activatedAt;

    @Column(name="last_used_time_step")
    private Long lastUsedTimeStep;

    @Version
    private Long version;

    protected TotpCredential() {
    }

    public TotpCredential(
            UserAccount userAccount,
            String encryptedSecret
    ) {
        this.userAccount = userAccount;
        this.encryptedSecret = encryptedSecret;
        this.status = TotpCredentialStatus.PENDING;
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

    public String getEncryptedSecret() {
        return encryptedSecret;
    }

    public TotpCredentialStatus getStatus() {
        return status;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getActivatedAt() {
        return activatedAt;
    }

    public Long getVersion() {
        return version;
    }

    public boolean isPending() {
        return status == TotpCredentialStatus.PENDING;
    }

    public boolean isActive() {
        return status == TotpCredentialStatus.ACTIVE;
    }

    public void activate() {
        if (status != TotpCredentialStatus.PENDING) {
            throw new IllegalStateException(
                    "Samo TOTP vjerodajnica u stanju PENDING može biti aktivirana."
            );
        }

        this.status = TotpCredentialStatus.ACTIVE;
        this.activatedAt = Instant.now();
    }

    public void disable() {
        if (status == TotpCredentialStatus.DISABLED) {
            return;
        }

        this.status = TotpCredentialStatus.DISABLED;
    }
    public Long getLastUsedTimeStep()
    {
        return lastUsedTimeStep;
    }
    public boolean isTimeStepAlreadyUsed(long timeStep)
    {
        return lastUsedTimeStep != null && lastUsedTimeStep >= timeStep;
    }
    public void markTimeStepUsed(long timeStep)
    {
        if(isTimeStepAlreadyUsed(timeStep))
        {
            throw new IllegalStateException("TOTP kod za ovaj vremenski korak je vec iskoristen.");
        }
        this.lastUsedTimeStep = timeStep;
    }
}